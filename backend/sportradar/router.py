from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from clients.sportradar_client import SportradarClient, SportradarError
from db.engine import async_session
from sportradar import repository as repo
from sportradar.db_models import (
    SrFixture, SrLineup, SrMatchStats, SrPlayer, SrStanding, SrSyncLog, SrTeam,
)
from sportradar.services.competition_sync import CompetitionSyncService
from sportradar.services.coverage_validation import CoverageValidationService
from sportradar.services.fixture_sync import FixtureSyncService
from sportradar.services.match_detail_sync import MatchDetailSyncService
from sportradar.services.standings_sync import StandingsSyncService
from sportradar.services.team_sync import TeamSyncService

router = APIRouter(prefix="/admin/sync", tags=["admin-sync"])


def _client() -> SportradarClient:
    if not settings.sportradar_api_key:
        raise HTTPException(503, "SPORTRADAR_API_KEY is not configured. Add it to backend/.env")
    return SportradarClient()


def _http_err(exc: SportradarError) -> HTTPException:
    if exc.status == 403:
        return HTTPException(403, f"Sportradar access denied: {exc.detail}")
    return HTTPException(502, f"Sportradar error ({exc.status}): {exc.detail}")


async def _db():
    async with async_session() as session:
        yield session


# =============================================================================
# SYNC ENDPOINTS (write)
# =============================================================================

@router.post("/competitions")
async def sync_competitions(db: AsyncSession = Depends(_db)):
    try:
        svc = CompetitionSyncService(_client())
        comp = await svc.discover_superliga()
    except SportradarError as exc:
        raise _http_err(exc)
    if not comp:
        raise HTTPException(404, "Romania Superliga not found via discovery")
    await repo.upsert_competition(db, comp)
    await db.commit()
    return {
        "confirmed": True,
        "competition_id": comp.id,
        "competition_name": comp.name,
        "category_name": comp.category.name,
        "country_code": comp.category.country_code,
        "persisted": True,
    }


@router.post("/seasons")
async def sync_seasons(db: AsyncSession = Depends(_db)):
    try:
        svc = CompetitionSyncService(_client())
        comp = await svc.discover_superliga()
        if not comp:
            raise HTTPException(404, "Could not discover Superliga")
        seasons = await svc.list_seasons(comp.id)
    except SportradarError as exc:
        raise _http_err(exc)
    await repo.upsert_competition(db, comp)
    await repo.upsert_seasons(db, seasons)
    await db.commit()
    return {
        "competition_id": comp.id,
        "count": len(seasons),
        "persisted": True,
        "seasons": [s.model_dump() for s in seasons],
    }


@router.post("/seasons/{season_id}/teams")
async def sync_season_teams(season_id: str, db: AsyncSession = Depends(_db)):
    try:
        svc = FixtureSyncService(_client())
        teams = await svc.extract_teams_from_season(season_id)
    except SportradarError as exc:
        raise _http_err(exc)
    await repo.upsert_teams(db, teams)
    await db.commit()
    return {"count": len(teams), "persisted": True}


@router.post("/seasons/{season_id}/profiles")
async def sync_season_profiles(season_id: str, db: AsyncSession = Depends(_db)):
    try:
        svc = TeamSyncService(_client())
        profiles = await svc.sync_all_profiles(season_id)
    except SportradarError as exc:
        raise _http_err(exc)
    total_players = 0
    for p in profiles:
        await repo.upsert_profile(db, p)
        total_players += len(p.players)
    await db.commit()
    return {
        "teams": len(profiles),
        "players": total_players,
        "persisted": True,
        "summary": [
            {"name": p.name, "squad": len(p.players), "venue": p.venue.name if p.venue else ""}
            for p in profiles
        ],
    }


@router.post("/seasons/{season_id}/fixtures")
async def sync_season_fixtures(season_id: str, db: AsyncSession = Depends(_db)):
    try:
        svc = FixtureSyncService(_client())
        fixtures = await svc.sync_season_schedule(season_id)
    except SportradarError as exc:
        raise _http_err(exc)
    await repo.upsert_fixtures(db, fixtures)
    await db.commit()
    closed = sum(1 for f in fixtures if f.status == "closed")
    return {
        "total": len(fixtures),
        "closed": closed,
        "not_started": len(fixtures) - closed,
        "persisted": True,
    }


@router.post("/seasons/{season_id}/standings")
async def sync_season_standings(season_id: str, db: AsyncSession = Depends(_db)):
    try:
        svc = StandingsSyncService(_client())
        rows = await svc.sync_standings(season_id)
    except SportradarError as exc:
        raise _http_err(exc)
    await repo.upsert_standings(db, season_id, rows)
    await db.commit()
    return {"count": len(rows), "persisted": True}


@router.post("/seasons/{season_id}/match-details")
async def sync_season_match_details(
    season_id: str,
    limit: int = Query(default=10, ge=1, le=200),
    db: AsyncSession = Depends(_db),
):
    client = _client()
    try:
        fixture_svc = FixtureSyncService(client)
        detail_svc = MatchDetailSyncService(client)
        fixtures = await fixture_svc.sync_season_schedule(season_id)
        closed_ids = [f.sr_id for f in fixtures if f.status == "closed"][:limit]
        results = await detail_svc.sync_season_match_details(season_id, closed_ids)
    except SportradarError as exc:
        raise _http_err(exc)

    stats_count = 0
    lineups_count = 0
    for d in results:
        if d.stats:
            await repo.upsert_match_stats(db, d.fixture_id, d.stats)
            stats_count += len(d.stats)
        if d.lineups:
            await repo.upsert_lineups(db, d.fixture_id, d.lineups)
            lineups_count += len(d.lineups)
    await db.commit()
    return {
        "matches_processed": len(results),
        "stats_rows": stats_count,
        "lineup_rows": lineups_count,
        "persisted": True,
    }


@router.post("/fixtures/{fixture_id}/detail")
async def sync_fixture_detail(fixture_id: str, db: AsyncSession = Depends(_db)):
    try:
        svc = MatchDetailSyncService(_client())
        detail = await svc.sync_full_match_detail(fixture_id)
    except SportradarError as exc:
        raise _http_err(exc)
    if not detail:
        raise HTTPException(404, f"Match detail not available for {fixture_id}")
    if detail.stats:
        await repo.upsert_match_stats(db, fixture_id, detail.stats)
    if detail.lineups:
        await repo.upsert_lineups(db, fixture_id, detail.lineups)
    await db.commit()
    return {
        "fixture_id": fixture_id,
        "stats": len(detail.stats),
        "lineups": len(detail.lineups),
        "persisted": True,
    }


# ── COVERAGE / VALIDATION ───────────────────────────────────────────────────

@router.post("/seasons/{season_id}/coverage")
async def sync_season_coverage(season_id: str):
    try:
        svc = CompetitionSyncService(_client())
        cov = await svc.season_coverage(season_id)
    except SportradarError as exc:
        raise _http_err(exc)
    if not cov:
        raise HTTPException(404, f"Coverage not available for {season_id}")
    return {"coverage": cov.model_dump()}


@router.post("/seasons/{season_id}/validate")
async def validate_season_coverage(season_id: str):
    try:
        svc = CoverageValidationService(_client())
        report = await svc.validate_season(season_id)
    except SportradarError as exc:
        raise _http_err(exc)
    return {"report": report.model_dump()}


# =============================================================================
# READ ENDPOINTS (inspect synced data)
# =============================================================================

@router.get("/data/teams")
async def read_teams(db: AsyncSession = Depends(_db)):
    result = await db.execute(select(SrTeam).order_by(SrTeam.name))
    teams = result.scalars().all()
    return {
        "count": len(teams),
        "teams": [
            {"id": t.id, "name": t.name, "short_name": t.short_name,
             "venue": t.venue_name, "manager": t.manager_name, "squad": t.squad_size}
            for t in teams
        ],
    }


@router.get("/data/fixtures")
async def read_fixtures(
    season_id: str = Query(default=""),
    status: str = Query(default=""),
    limit: int = Query(default=50, ge=1, le=500),
    db: AsyncSession = Depends(_db),
):
    q = select(SrFixture).order_by(SrFixture.scheduled)
    if season_id:
        q = q.where(SrFixture.season_id == season_id)
    if status:
        q = q.where(SrFixture.status == status)
    q = q.limit(limit)
    result = await db.execute(q)
    fixtures = result.scalars().all()
    return {
        "count": len(fixtures),
        "fixtures": [
            {"id": f.id, "scheduled": f.scheduled, "status": f.status,
             "home": f.home_team_name, "away": f.away_team_name,
             "score": f"{f.home_score}-{f.away_score}" if f.home_score is not None else None,
             "venue": f.venue_name, "round": f.round_number}
            for f in fixtures
        ],
    }


@router.get("/data/standings")
async def read_standings(
    season_id: str = Query(...),
    db: AsyncSession = Depends(_db),
):
    result = await db.execute(
        select(SrStanding).where(SrStanding.season_id == season_id).order_by(SrStanding.rank)
    )
    rows = result.scalars().all()
    return {
        "count": len(rows),
        "standings": [
            {"rank": r.rank, "team": r.team_name, "played": r.played,
             "w": r.wins, "d": r.draws, "l": r.losses,
             "gf": r.goals_for, "ga": r.goals_against, "gd": r.goal_diff,
             "pts": r.points, "form": r.form}
            for r in rows
        ],
    }


@router.get("/data/match/{fixture_id}")
async def read_match_detail(fixture_id: str, db: AsyncSession = Depends(_db)):
    stats_result = await db.execute(
        select(SrMatchStats).where(SrMatchStats.fixture_id == fixture_id)
    )
    stats = stats_result.scalars().all()

    lineup_result = await db.execute(
        select(SrLineup).where(SrLineup.fixture_id == fixture_id)
    )
    lineups = lineup_result.scalars().all()

    return {
        "fixture_id": fixture_id,
        "stats": [
            {"team": s.team_name, "possession": s.ball_possession,
             "shots": s.shots_total, "on_target": s.shots_on_target,
             "corners": s.corner_kicks, "fouls": s.fouls,
             "yellows": s.yellow_cards, "reds": s.red_cards}
            for s in stats
        ],
        "lineups": [
            {"team": lu.team_name, "formation": lu.formation,
             "players": lu.players_json}
            for lu in lineups
        ],
    }


@router.get("/data/players")
async def read_players(
    team_id: str = Query(default=""),
    db: AsyncSession = Depends(_db),
):
    q = select(SrPlayer).order_by(SrPlayer.name)
    if team_id:
        q = q.where(SrPlayer.team_id == team_id)
    result = await db.execute(q)
    players = result.scalars().all()
    return {
        "count": len(players),
        "players": [
            {"id": p.id, "name": p.name, "pos": p.position,
             "nationality": p.nationality, "jersey": p.jersey_number}
            for p in players
        ],
    }


@router.get("/data/sync-log")
async def read_sync_log(
    limit: int = Query(default=30, ge=1, le=200),
    db: AsyncSession = Depends(_db),
):
    result = await db.execute(
        select(SrSyncLog).order_by(SrSyncLog.synced_at.desc()).limit(limit)
    )
    logs = result.scalars().all()
    return {
        "count": len(logs),
        "logs": [
            {"entity": l.entity_type, "id": l.entity_id, "op": l.operation,
             "records": l.record_count, "status": l.status,
             "error": l.error_message, "at": str(l.synced_at)}
            for l in logs
        ],
    }


# ── STATUS ───────────────────────────────────────────────────────────────────

@router.get("/status")
async def sync_status(db: AsyncSession = Depends(_db)):
    counts = {}
    for table, model in [
        ("teams", SrTeam), ("fixtures", SrFixture), ("standings", SrStanding),
        ("match_stats", SrMatchStats), ("lineups", SrLineup), ("players", SrPlayer),
    ]:
        result = await db.execute(select(func.count()).select_from(model))
        counts[table] = result.scalar() or 0

    return {
        "status": "ok",
        "stored_records": counts,
        "sync_endpoints": [
            "POST /competitions",
            "POST /seasons",
            "POST /seasons/{id}/teams",
            "POST /seasons/{id}/profiles",
            "POST /seasons/{id}/fixtures",
            "POST /seasons/{id}/standings",
            "POST /seasons/{id}/match-details?limit=N",
            "POST /fixtures/{id}/detail",
        ],
        "read_endpoints": [
            "GET /data/teams",
            "GET /data/fixtures?season_id=...&status=closed",
            "GET /data/standings?season_id=...",
            "GET /data/match/{fixture_id}",
            "GET /data/players?team_id=...",
            "GET /data/sync-log",
        ],
    }
