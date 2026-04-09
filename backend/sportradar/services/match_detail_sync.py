from __future__ import annotations

import logging

from clients.sportradar_client import SportradarClient
from sportradar.schemas import (
    NormalizedLineup,
    NormalizedLineupPlayer,
    NormalizedMatchDetail,
    NormalizedMatchStats,
)

logger = logging.getLogger(__name__)


class MatchDetailSyncService:

    def __init__(self, client: SportradarClient):
        self._client = client

    async def sync_match_summary(self, fixture_id: str) -> NormalizedMatchDetail | None:
        data = await self._client.sport_event_summary(fixture_id)
        if not data:
            return None

        status_block = data.get("sport_event_status", {})
        stats_raw = data.get("statistics", {})

        team_stats: list[NormalizedMatchStats] = []
        for team_block in stats_raw.get("totals", {}).get("competitors", []):
            stats = team_block.get("statistics", {})
            team_stats.append(NormalizedMatchStats(
                fixture_id=fixture_id,
                team_id=team_block.get("id", ""),
                team_name=team_block.get("name", ""),
                ball_possession=stats.get("ball_possession"),
                shots_total=stats.get("shots_total"),
                shots_on_target=stats.get("shots_on_target"),
                corner_kicks=stats.get("corner_kicks"),
                fouls=stats.get("fouls"),
                yellow_cards=stats.get("yellow_cards"),
                red_cards=stats.get("red_cards"),
                offsides=stats.get("offsides"),
                free_kicks=stats.get("free_kicks"),
                goal_kicks=stats.get("goal_kicks"),
                throw_ins=stats.get("throw_ins"),
            ))

        detail = NormalizedMatchDetail(
            fixture_id=fixture_id,
            status=status_block.get("status", ""),
            home_score=status_block.get("home_score"),
            away_score=status_block.get("away_score"),
            stats=team_stats,
        )

        logger.info(
            "Match summary synced: %s — %d team stat blocks",
            fixture_id, len(team_stats),
        )
        return detail

    async def sync_match_lineups(self, fixture_id: str) -> list[NormalizedLineup]:
        data = await self._client.sport_event_lineups(fixture_id)
        if not data:
            return []

        lineups: list[NormalizedLineup] = []
        for team_block in data.get("lineups", []):
            team_id = team_block.get("id", "")
            team_name = team_block.get("name", "")
            formation = team_block.get("formation", "")

            players: list[NormalizedLineupPlayer] = []

            for p in team_block.get("starting_lineup", []):
                players.append(NormalizedLineupPlayer(
                    player_id=p.get("id", ""),
                    name=p.get("name", ""),
                    jersey_number=p.get("jersey_number"),
                    position=p.get("type", ""),
                    starter=True,
                    order=p.get("order"),
                ))

            for p in team_block.get("substitutes", []):
                players.append(NormalizedLineupPlayer(
                    player_id=p.get("id", ""),
                    name=p.get("name", ""),
                    jersey_number=p.get("jersey_number"),
                    position=p.get("type", ""),
                    starter=False,
                    order=p.get("order"),
                ))

            lineups.append(NormalizedLineup(
                fixture_id=fixture_id,
                team_id=team_id,
                team_name=team_name,
                formation=formation,
                players=players,
            ))

        logger.info("Lineups synced: %s — %d teams", fixture_id, len(lineups))
        return lineups

    async def sync_full_match_detail(self, fixture_id: str) -> NormalizedMatchDetail | None:
        detail = await self.sync_match_summary(fixture_id)
        if not detail:
            return None

        lineups = await self.sync_match_lineups(fixture_id)
        detail.lineups = lineups
        return detail

    async def sync_season_match_details(
        self,
        season_id: str,
        fixture_ids: list[str],
        closed_only: bool = True,
    ) -> list[NormalizedMatchDetail]:
        results: list[NormalizedMatchDetail] = []
        for fid in fixture_ids:
            detail = await self.sync_full_match_detail(fid)
            if detail:
                results.append(detail)

        logger.info(
            "Bulk match detail sync: %d/%d matches processed for season %s",
            len(results), len(fixture_ids), season_id,
        )
        return results
