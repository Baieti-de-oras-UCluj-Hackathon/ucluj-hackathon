from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from app.config import settings
from clients.sportradar_client import SportradarClient, SportradarError
from sportradar.services.competition_sync import CompetitionSyncService
from sportradar.services.coverage_validation import CoverageValidationService
from sportradar.services.fixture_sync import FixtureSyncService
from sportradar.services.match_detail_sync import MatchDetailSyncService
from sportradar.services.standings_sync import StandingsSyncService
from sportradar.services.team_sync import TeamSyncService

router = APIRouter(prefix="/admin/sync", tags=["admin-sync"])


def _client() -> SportradarClient:
    if not settings.sportradar_api_key:
        raise HTTPException(
            status_code=503,
            detail="SPORTRADAR_API_KEY is not configured. Add it to backend/.env",
        )
    return SportradarClient()


def _handle_sr_error(exc: SportradarError) -> HTTPException:
    if exc.status == 403:
        return HTTPException(403, f"Sportradar access denied: {exc.detail}. Check your API key.")
    return HTTPException(502, f"Sportradar error ({exc.status}): {exc.detail}")


# ── COMPETITION + SEASON DISCOVERY ────────────────────────────────────────────

@router.post("/competitions")
async def sync_competitions():
    try:
        svc = CompetitionSyncService(_client())
        comp = await svc.discover_superliga()
    except SportradarError as exc:
        raise _handle_sr_error(exc)
    if not comp:
        raise HTTPException(404, "Romania Superliga not found via discovery in Sportradar competitions list")
    return {
        "confirmed": True,
        "competition_id": comp.id,
        "competition_name": comp.name,
        "category_name": comp.category.name,
        "country_code": comp.category.country_code,
        "gender": comp.gender,
        "note": "This ID was discovered from the live API, not hardcoded. Use it for all subsequent season/fixture calls.",
    }


@router.post("/seasons")
async def sync_seasons():
    try:
        svc = CompetitionSyncService(_client())
        comp = await svc.discover_superliga()
        if not comp:
            raise HTTPException(404, "Run /competitions first — could not discover Superliga")
        seasons = await svc.list_seasons(comp.id)
    except SportradarError as exc:
        raise _handle_sr_error(exc)
    return {
        "competition_id": comp.id,
        "competition_name": comp.name,
        "count": len(seasons),
        "seasons": [s.model_dump() for s in seasons],
    }


@router.post("/seasons/{season_id}/coverage")
async def sync_season_coverage(season_id: str):
    try:
        svc = CompetitionSyncService(_client())
        cov = await svc.season_coverage(season_id)
    except SportradarError as exc:
        raise _handle_sr_error(exc)
    if not cov:
        raise HTTPException(404, f"Coverage info not available for {season_id}")
    return {"coverage": cov.model_dump()}


# ── TEAMS + PROFILES ─────────────────────────────────────────────────────────

@router.post("/seasons/{season_id}/teams")
async def sync_season_teams(season_id: str):
    svc = FixtureSyncService(_client())
    teams = await svc.extract_teams_from_season(season_id)
    return {"count": len(teams), "teams": [t.model_dump() for t in teams]}


@router.post("/seasons/{season_id}/profiles")
async def sync_season_profiles(season_id: str):
    svc = TeamSyncService(_client())
    profiles = await svc.sync_all_profiles(season_id)
    return {
        "count": len(profiles),
        "profiles": [
            {
                "sr_id": p.sr_id,
                "name": p.name,
                "short_name": p.short_name,
                "abbreviation": p.abbreviation,
                "country": p.country,
                "venue": p.venue.name if p.venue else None,
                "manager": p.manager.name if p.manager else None,
                "squad_size": len(p.players),
            }
            for p in profiles
        ],
    }


@router.post("/competitors/{competitor_id}/profile")
async def sync_competitor_profile(competitor_id: str):
    svc = TeamSyncService(_client())
    profile = await svc.sync_competitor_profile(competitor_id)
    if not profile:
        raise HTTPException(404, f"Profile not found for {competitor_id}")
    return {"profile": profile.model_dump()}


@router.post("/competitors/{competitor_id}/schedule")
async def sync_competitor_schedule(competitor_id: str):
    svc = TeamSyncService(_client())
    events = await svc.sync_competitor_schedule(competitor_id)
    return {"count": len(events), "schedule": events}


# ── FIXTURES ─────────────────────────────────────────────────────────────────

@router.post("/seasons/{season_id}/fixtures")
async def sync_season_fixtures(season_id: str):
    svc = FixtureSyncService(_client())
    fixtures = await svc.sync_season_schedule(season_id)
    return {"count": len(fixtures), "fixtures": [f.model_dump() for f in fixtures]}


# ── STANDINGS ────────────────────────────────────────────────────────────────

@router.post("/seasons/{season_id}/standings")
async def sync_season_standings(season_id: str):
    svc = StandingsSyncService(_client())
    rows = await svc.sync_standings(season_id)
    return {"count": len(rows), "standings": [r.model_dump() for r in rows]}


# ── MATCH DETAIL (SUMMARY + LINEUPS) ────────────────────────────────────────

@router.post("/fixtures/{fixture_id}/detail")
async def sync_fixture_detail(fixture_id: str):
    svc = MatchDetailSyncService(_client())
    detail = await svc.sync_full_match_detail(fixture_id)
    if not detail:
        raise HTTPException(404, f"Match detail not available for {fixture_id}")
    return {"detail": detail.model_dump()}


@router.post("/fixtures/{fixture_id}/lineups")
async def sync_fixture_lineups(fixture_id: str):
    svc = MatchDetailSyncService(_client())
    lineups = await svc.sync_match_lineups(fixture_id)
    return {"count": len(lineups), "lineups": [l.model_dump() for l in lineups]}


@router.post("/seasons/{season_id}/match-details")
async def sync_season_match_details(
    season_id: str,
    limit: int = Query(default=5, ge=1, le=200, description="Max matches to process (trial rate limit safe)"),
):
    client = _client()
    fixture_svc = FixtureSyncService(client)
    detail_svc = MatchDetailSyncService(client)

    fixtures = await fixture_svc.sync_season_schedule(season_id)
    closed_ids = [f.sr_id for f in fixtures if f.status == "closed"][:limit]

    results = await detail_svc.sync_season_match_details(season_id, closed_ids)
    return {
        "total_closed": len([f for f in fixtures if f.status == "closed"]),
        "processed": len(results),
        "details": [d.model_dump() for d in results],
    }


# ── COVERAGE VALIDATION ──────────────────────────────────────────────────────

@router.post("/seasons/{season_id}/validate")
async def validate_season_coverage(season_id: str):
    try:
        svc = CoverageValidationService(_client())
        report = await svc.validate_season(season_id)
    except SportradarError as exc:
        raise _handle_sr_error(exc)
    return {"report": report.model_dump()}


# ── STATUS ───────────────────────────────────────────────────────────────────

@router.get("/status")
async def sync_status():
    return {
        "status": "ok",
        "message": "Sportradar sync layer active (Phase 3). Use POST endpoints to trigger syncs.",
        "endpoints": {
            "discovery": [
                "POST /competitions",
                "POST /seasons",
                "POST /seasons/{season_id}/coverage",
            ],
            "teams": [
                "POST /seasons/{season_id}/teams",
                "POST /seasons/{season_id}/profiles",
                "POST /competitors/{competitor_id}/profile",
                "POST /competitors/{competitor_id}/schedule",
            ],
            "fixtures": [
                "POST /seasons/{season_id}/fixtures",
            ],
            "standings": [
                "POST /seasons/{season_id}/standings  (season standings sync, not guaranteed live)",
            ],
            "match_detail": [
                "POST /fixtures/{fixture_id}/detail",
                "POST /fixtures/{fixture_id}/lineups",
                "POST /seasons/{season_id}/match-details?limit=5",
            ],
            "validation": [
                "POST /seasons/{season_id}/validate",
            ],
        },
    }
