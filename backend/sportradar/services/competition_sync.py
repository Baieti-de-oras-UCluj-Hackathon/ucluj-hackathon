from __future__ import annotations

import logging

from clients.sportradar_client import SportradarClient
from sportradar.schemas import SRCompetition, SRCategory, SRSeason, SRSeasonCoverage

logger = logging.getLogger(__name__)

_ROMANIA_KEYWORDS = {"romania", "superliga", "liga 1", "liga i"}
_ROMANIA_COUNTRY_CODES = {"ROU", "ROM"}

_discovered_competition_id: str | None = None


def get_discovered_id() -> str | None:
    return _discovered_competition_id


class CompetitionSyncService:

    def __init__(self, client: SportradarClient):
        self._client = client

    async def discover_superliga(self) -> SRCompetition | None:
        global _discovered_competition_id

        data = await self._client.competitions()
        if not data:
            return None

        candidates: list[SRCompetition] = []

        for raw in data.get("competitions", []):
            cat = raw.get("category", {})
            country = cat.get("country_code", "").upper()
            name_lower = raw.get("name", "").lower()
            cat_name_lower = cat.get("name", "").lower()

            is_romania = country in _ROMANIA_COUNTRY_CODES or "romania" in cat_name_lower
            is_superliga = any(kw in name_lower for kw in _ROMANIA_KEYWORDS)

            if is_romania and is_superliga:
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
                candidates.append(comp)

        if not candidates:
            logger.warning("Romania Superliga not found via discovery in competitions list")
            return None

        chosen = candidates[0]
        _discovered_competition_id = chosen.id
        logger.info(
            "Discovered Romania Superliga: name=%s, id=%s, category=%s, country=%s",
            chosen.name, chosen.id, chosen.category.name, chosen.category.country_code,
        )
        return chosen

    async def list_seasons(self, competition_id: str | None = None) -> list[SRSeason]:
        cid = competition_id or _discovered_competition_id
        if not cid:
            logger.error("No competition ID available. Run discover_superliga first.")
            return []

        data = await self._client.competition_seasons(cid)
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
                competition_id=raw.get("competition_id", cid),
            ))

        seasons.sort(key=lambda s: s.start_date, reverse=True)
        logger.info("Found %d seasons for competition %s", len(seasons), cid)
        return seasons

    async def season_coverage(self, season_id: str) -> SRSeasonCoverage | None:
        data = await self._client.season_info(season_id)
        return self.parse_season_info(data, season_id)

    @staticmethod
    def parse_season_info(data: dict | None, season_id: str) -> SRSeasonCoverage | None:
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
