from __future__ import annotations

from fastapi import APIRouter, HTTPException

from clients.sportradar_client import SportradarClient
from sportradar.services.competition_sync import CompetitionSyncService
from sportradar.services.fixture_sync import FixtureSyncService
from sportradar.services.standings_sync import StandingsSyncService

router = APIRouter(prefix="/admin/sync", tags=["admin-sync"])


def _client() -> SportradarClient:
    return SportradarClient()


@router.post("/competitions")
async def sync_competitions():
    svc = CompetitionSyncService(_client())
    comp = await svc.discover_superliga()
    if not comp:
        raise HTTPException(404, "Romania Superliga not found in Sportradar")
    return {"competition": comp.model_dump()}


@router.post("/seasons")
async def sync_seasons():
    svc = CompetitionSyncService(_client())
    seasons = await svc.list_seasons()
    return {
        "count": len(seasons),
        "seasons": [s.model_dump() for s in seasons],
    }


@router.post("/seasons/{season_id}/coverage")
async def sync_season_coverage(season_id: str):
    svc = CompetitionSyncService(_client())
    cov = await svc.season_coverage(season_id)
    if not cov:
        raise HTTPException(404, f"Coverage info not available for {season_id}")
    return {"coverage": cov.model_dump()}


@router.post("/seasons/{season_id}/teams")
async def sync_season_teams(season_id: str):
    svc = FixtureSyncService(_client())
    teams = await svc.extract_teams_from_season(season_id)
    return {
        "count": len(teams),
        "teams": [t.model_dump() for t in teams],
    }


@router.post("/seasons/{season_id}/fixtures")
async def sync_season_fixtures(season_id: str):
    svc = FixtureSyncService(_client())
    fixtures = await svc.sync_season_schedule(season_id)
    return {
        "count": len(fixtures),
        "fixtures": [f.model_dump() for f in fixtures],
    }


@router.post("/seasons/{season_id}/standings")
async def sync_season_standings(season_id: str):
    svc = StandingsSyncService(_client())
    rows = await svc.sync_standings(season_id)
    return {
        "count": len(rows),
        "standings": [r.model_dump() for r in rows],
    }


@router.get("/status")
async def sync_status():
    return {
        "status": "ok",
        "message": "Sportradar sync layer active. Use POST endpoints to trigger syncs.",
        "endpoints": [
            "POST /competitions",
            "POST /seasons",
            "POST /seasons/{season_id}/coverage",
            "POST /seasons/{season_id}/teams",
            "POST /seasons/{season_id}/fixtures",
            "POST /seasons/{season_id}/standings",
        ],
    }
