from __future__ import annotations

import logging

from clients.sportradar_client import SportradarClient
from sportradar.schemas import NormalizedStandingsRow

logger = logging.getLogger(__name__)

TARGET_TYPE = "total"
TARGET_GROUP = "Superliga"


class StandingsSyncService:

    def __init__(self, client: SportradarClient):
        self._client = client

    async def sync_standings(self, season_id: str) -> list[NormalizedStandingsRow]:
        data = await self._client.season_standings(season_id)
        if not data:
            return []

        rows: list[NormalizedStandingsRow] = []

        for standing in data.get("standings", []):
            stype = standing.get("type", "")
            if stype != TARGET_TYPE:
                continue

            for group in standing.get("groups", []):
                gname = group.get("name", "")
                if TARGET_GROUP.lower() not in gname.lower():
                    continue

                for row in group.get("standings", []):
                    competitor = row.get("competitor", {})
                    gf = row.get("goals_for") or 0
                    ga = row.get("goals_against") or 0
                    gd = row.get("goal_diff")
                    if gd is None:
                        gd = gf - ga

                    rows.append(NormalizedStandingsRow(
                        team_id=competitor.get("id", ""),
                        team_name=competitor.get("name", ""),
                        rank=row.get("rank"),
                        played=row.get("played"),
                        wins=row.get("win"),
                        draws=row.get("draw"),
                        losses=row.get("loss"),
                        goals_for=gf,
                        goals_against=ga,
                        goal_diff=gd,
                        points=row.get("points"),
                        form=row.get("form", ""),
                    ))

        rows.sort(key=lambda r: r.rank or 99)
        logger.info("Synced %d standings rows (type=%s, group=%s) for season %s",
                     len(rows), TARGET_TYPE, TARGET_GROUP, season_id)
        return rows
