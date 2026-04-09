from __future__ import annotations

import logging

from clients.sportradar_client import SportradarClient
from sportradar.schemas import (
    NormalizedFixture,
    NormalizedTeam,
    SRCompetitorRef,
    SRVenue,
)

logger = logging.getLogger(__name__)


class FixtureSyncService:

    def __init__(self, client: SportradarClient):
        self._client = client

    async def sync_season_schedule(self, season_id: str) -> list[NormalizedFixture]:
        data = await self._client.season_schedules(season_id)
        if not data:
            return []

        fixtures: list[NormalizedFixture] = []
        for raw_evt in data.get("schedules", []):
            se = raw_evt.get("sport_event", {})
            status_block = raw_evt.get("sport_event_status", {})
            competitors = se.get("competitors", [])

            home = _find_qualifier(competitors, "home")
            away = _find_qualifier(competitors, "away")
            venue = se.get("venue", {})
            context = se.get("sport_event_context", {})
            round_info = context.get("round", {})
            rnd = round_info.get("number")
            if rnd is None and isinstance(round_info.get("cup_round_order"), int):
                rnd = round_info.get("cup_round_order")
            rnd_int: int | None = None
            if isinstance(rnd, (int, float)):
                rnd_int = int(rnd)

            fixtures.append(NormalizedFixture(
                sr_id=se.get("id", ""),
                season_id=season_id,
                scheduled=se.get("scheduled", ""),
                status=status_block.get("status", se.get("status", "")),
                home_team_id=home.get("id", "") if home else "",
                home_team_name=home.get("name", "") if home else "",
                away_team_id=away.get("id", "") if away else "",
                away_team_name=away.get("name", "") if away else "",
                home_score=status_block.get("home_score"),
                away_score=status_block.get("away_score"),
                venue_name=venue.get("name", ""),
                round_number=rnd_int,
                matchday=rnd_int,
            ))

        fixtures.sort(key=lambda f: f.scheduled)
        logger.info("Synced %d fixtures for season %s", len(fixtures), season_id)
        return fixtures

    async def extract_teams_from_season(self, season_id: str) -> list[NormalizedTeam]:
        data = await self._client.season_competitors(season_id)
        if not data:
            return []

        teams: list[NormalizedTeam] = []
        for raw in data.get("season_competitors", []):
            venue = raw.get("venue", {})
            manager = raw.get("manager", {})
            teams.append(NormalizedTeam(
                sr_id=raw.get("id", ""),
                name=raw.get("name", ""),
                short_name=raw.get("short_name", ""),
                abbreviation=raw.get("abbreviation", ""),
                country=raw.get("country", ""),
                country_code=raw.get("country_code", ""),
                venue_id=venue.get("id", ""),
                venue_name=venue.get("name", ""),
                manager_name=manager.get("name", ""),
                logo_url=_logo_href(raw.get("logo")),
            ))

        logger.info("Extracted %d teams for season %s", len(teams), season_id)
        return teams


def _find_qualifier(competitors: list[dict], qualifier: str) -> dict | None:
    for c in competitors:
        if c.get("qualifier") == qualifier:
            return c
    return None


def _logo_href(logo: object) -> str:
    if isinstance(logo, str):
        return logo
    if isinstance(logo, dict):
        return str(logo.get("href") or logo.get("url") or "")
    return ""
