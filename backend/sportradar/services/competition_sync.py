from __future__ import annotations

import logging

from clients.sportradar_client import SportradarClient
from sportradar.schemas import SRCompetition, SRCategory, SRSeason, SRSeasonCoverage

logger = logging.getLogger(__name__)

SUPERLIGA_ID = SportradarClient.ROMANIA_SUPERLIGA_ID


class CompetitionSyncService:

    def __init__(self, client: SportradarClient):
        self._client = client

    async def discover_superliga(self) -> SRCompetition | None:
        data = await self._client.competitions()
        if not data:
            return None

        for raw in data.get("competitions", []):
            if raw.get("id") == SUPERLIGA_ID:
                cat = raw.get("category", {})
                comp = SRCompetition(
                    id=raw.get("id", ""),
                    name=raw.get("name", ""),
                    gender=raw.get("gender", ""),
                    category=SRCategory(
                        id=cat.get("id", ""),
                        name=cat.get("name", ""),
                        country_code=cat.get("country_code", ""),
                    ),
                )
                logger.info("Found Romania Superliga: %s (%s)", comp.name, comp.id)
                return comp

        logger.warning("Romania Superliga (%s) not found in competitions list", SUPERLIGA_ID)
        return None

    async def list_seasons(self) -> list[SRSeason]:
        data = await self._client.competition_seasons(SUPERLIGA_ID)
        if not data:
            return []

        seasons: list[SRSeason] = []
        for raw in data.get("seasons", []):
            seasons.append(SRSeason(
                id=raw.get("id", ""),
                name=raw.get("name", ""),
                start_date=raw.get("start_date", ""),
                end_date=raw.get("end_date", ""),
                year=raw.get("year", ""),
                competition_id=raw.get("competition_id", SUPERLIGA_ID),
            ))

        seasons.sort(key=lambda s: s.start_date, reverse=True)
        logger.info("Found %d seasons for Superliga", len(seasons))
        return seasons

    async def season_coverage(self, season_id: str) -> SRSeasonCoverage | None:
        data = await self._client.season_info(season_id)
        if not data:
            return None

        info = data.get("season", {})
        cov = data.get("coverage_info", data.get("coverage", {}))

        return SRSeasonCoverage(
            season_id=info.get("id", season_id),
            competition_id=info.get("competition_id", ""),
            max_coverage_level=cov.get("max_coverage_level", "unknown"),
            max_covered_matches=cov.get("max_covered", None),
            scheduled_matches=cov.get("scheduled", None),
            players_statistics=cov.get("players_statistics", False),
            team_statistics=cov.get("team_statistics", False),
            lineups=cov.get("lineups", False),
            squads=cov.get("squads", False),
            transfers=cov.get("transfers", False),
            missing_players=cov.get("missing_players", False),
        )
