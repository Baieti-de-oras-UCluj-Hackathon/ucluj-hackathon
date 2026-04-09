from __future__ import annotations

import logging

from clients.sportradar_client import SportradarClient
from sportradar.schemas import NormalizedStandingsRow

logger = logging.getLogger(__name__)

GROUP_REGULAR = "Superliga"
GROUP_CHAMPIONSHIP = "Championship Round"
GROUP_RELEGATION = "Relegation Round"

KNOWN_GROUPS = {
    GROUP_REGULAR: "regular",
    GROUP_CHAMPIONSHIP: "groups",
    GROUP_RELEGATION: "groups",
}


class StandingsSyncService:

    def __init__(self, client: SportradarClient):
        self._client = client

    async def sync_all_standings(self, season_id: str) -> dict[str, list[NormalizedStandingsRow]]:
        data = await self._client.season_standings(season_id)
        if not data:
            return {}

        result: dict[str, list[NormalizedStandingsRow]] = {}

        for standing in data.get("standings", []):
            stype = standing.get("type", "")
            if stype != "total":
                continue

            for group in standing.get("groups", []):
                gname = group.get("name", "")
                gid = group.get("id", "")

                rows: list[NormalizedStandingsRow] = []
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
                        group_name=gname,
                        group_id=gid,
                    ))

                rows.sort(key=lambda r: r.rank or 99)
                result[gname] = rows
                logger.info("Standings group '%s': %d teams", gname, len(rows))

        return result

    async def sync_standings(self, season_id: str) -> list[NormalizedStandingsRow]:
        """Backward compat: return only the main Superliga group."""
        all_groups = await self.sync_all_standings(season_id)
        return all_groups.get(GROUP_REGULAR, [])
