from __future__ import annotations

import logging

from clients.sportradar_client import SportradarClient, SportradarError
from sportradar.schemas import CoverageReport, FeedProbeResult, SRSeasonCoverage
from sportradar.services.competition_sync import CompetitionSyncService

logger = logging.getLogger(__name__)


class CoverageValidationService:

    def __init__(self, client: SportradarClient):
        self._client = client

    async def validate_season(self, season_id: str) -> CoverageReport:
        comp_svc = CompetitionSyncService(self._client)

        coverage = await comp_svc.season_coverage(season_id)

        probes: list[FeedProbeResult] = []
        summary: dict[str, bool] = {}

        probe_targets = [
            ("season_info", f"seasons/{_enc(season_id)}/info.json", "season"),
            ("season_competitors", f"seasons/{_enc(season_id)}/competitors.json", "season_competitors"),
            ("season_schedules", f"seasons/{_enc(season_id)}/schedules.json", "schedules"),
            ("season_standings", f"seasons/{_enc(season_id)}/standings.json", "standings"),
            ("season_summaries", f"seasons/{_enc(season_id)}/summaries.json", "summaries"),
            ("season_lineups", f"seasons/{_enc(season_id)}/lineups.json", "lineups"),
            ("season_leaders", f"seasons/{_enc(season_id)}/leaders.json", "lists"),
        ]

        for feed_name, path, data_key in probe_targets:
            result = await self._probe_feed(path, data_key)
            result.feed_name = feed_name
            probes.append(result)
            summary[feed_name] = result.available

        # Probe one competitor profile if we have teams
        teams_probe = next((p for p in probes if p.feed_name == "season_competitors"), None)
        if teams_probe and teams_probe.available and teams_probe.record_count and teams_probe.record_count > 0:
            comp_data = await self._client.season_competitors(season_id)
            if comp_data:
                first_team = (comp_data.get("season_competitors", []) or [{}])[0]
                team_id = first_team.get("id", "")
                if team_id:
                    profile_result = await self._probe_feed(
                        f"competitors/{_enc(team_id)}/profile.json",
                        "competitor",
                    )
                    profile_result.feed_name = f"competitor_profile ({team_id})"
                    probes.append(profile_result)
                    summary["competitor_profile"] = profile_result.available

                    schedule_result = await self._probe_feed(
                        f"competitors/{_enc(team_id)}/schedules.json",
                        "schedules",
                    )
                    schedule_result.feed_name = f"competitor_schedule ({team_id})"
                    probes.append(schedule_result)
                    summary["competitor_schedule"] = schedule_result.available

        # Probe one match detail if we have fixtures
        schedules_probe = next((p for p in probes if p.feed_name == "season_schedules"), None)
        if schedules_probe and schedules_probe.available and schedules_probe.record_count and schedules_probe.record_count > 0:
            sched_data = await self._client.season_schedules(season_id)
            if sched_data:
                closed_events = [
                    e for e in sched_data.get("schedules", [])
                    if e.get("sport_event_status", {}).get("status") == "closed"
                ]
                if closed_events:
                    event_id = closed_events[0].get("sport_event", {}).get("id", "")
                    if event_id:
                        summary_result = await self._probe_feed(
                            f"sport_events/{_enc(event_id)}/summary.json",
                            "sport_event_status",
                        )
                        summary_result.feed_name = f"sport_event_summary ({event_id})"
                        probes.append(summary_result)
                        summary["sport_event_summary"] = summary_result.available

                        lineup_result = await self._probe_feed(
                            f"sport_events/{_enc(event_id)}/lineups.json",
                            "lineups",
                        )
                        lineup_result.feed_name = f"sport_event_lineups ({event_id})"
                        probes.append(lineup_result)
                        summary["sport_event_lineups"] = lineup_result.available

        season_name = ""
        if coverage:
            season_name = coverage.season_id

        report = CoverageReport(
            season_id=season_id,
            season_name=season_name,
            competition_id=SportradarClient.ROMANIA_SUPERLIGA_ID,
            coverage_info=coverage,
            feed_probes=probes,
            summary=summary,
        )

        available_count = sum(1 for v in summary.values() if v)
        total_count = len(summary)
        logger.info(
            "Coverage validation for %s: %d/%d feeds available",
            season_id, available_count, total_count,
        )

        return report

    async def _probe_feed(self, path: str, data_key: str) -> FeedProbeResult:
        try:
            import httpx
            url = f"{self._client._base}/{path}"
            headers = {"x-api-key": self._client._key}

            await self._client._throttle()

            async with httpx.AsyncClient(timeout=15.0) as http:
                resp = await http.get(url, headers=headers)

            if resp.status_code == 200:
                body = resp.json()
                count = None
                if isinstance(body.get(data_key), list):
                    count = len(body[data_key])
                elif isinstance(body.get(data_key), dict):
                    count = 1

                return FeedProbeResult(
                    feed_name="",
                    endpoint=path,
                    available=True,
                    status_code=resp.status_code,
                    record_count=count,
                )

            return FeedProbeResult(
                feed_name="",
                endpoint=path,
                available=False,
                status_code=resp.status_code,
                error=resp.text[:200] if resp.status_code != 404 else "Not found",
            )

        except Exception as exc:
            return FeedProbeResult(
                feed_name="",
                endpoint=path,
                available=False,
                error=str(exc)[:200],
            )


def _enc(sr_id: str) -> str:
    return sr_id.replace(":", "%3A")
