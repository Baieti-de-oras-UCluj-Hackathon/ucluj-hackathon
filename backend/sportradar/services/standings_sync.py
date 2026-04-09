from __future__ import annotations

import logging

from clients.sportradar_client import SportradarClient
from sportradar.schemas import NormalizedStandingsRow

logger = logging.getLogger(__name__)


class StandingsSyncService:

    def __init__(self, client: SportradarClient):
        self._client = client

    async def sync_standings(self, season_id: str) -> list[NormalizedStandingsRow]:
        data = await self._client.season_standings(season_id)
        if not data:
            return []

        rows: list[NormalizedStandingsRow] = []

        for group in data.get("standings", []):
            for raw_group in group.get("groups", []):
                for row in raw_group.get("standings", []):
                    competitor = row.get("competitor", {})
                    rows.append(NormalizedStandingsRow(
                        team_id=competitor.get("id", ""),
                        team_name=competitor.get("name", ""),
                        rank=row.get("rank"),
                        played=row.get("played"),
                        wins=row.get("win"),
                        draws=row.get("draw"),
                        losses=row.get("loss"),
                        goals_for=row.get("goals_for"),
                        goals_against=row.get("goals_against"),
                        goal_diff=row.get("goal_diff"),
                        points=row.get("points"),
                        form=row.get("form", ""),
                    ))

        rows.sort(key=lambda r: r.rank or 99)
        logger.info("Synced %d standings rows for season %s", len(rows), season_id)
        return rows
