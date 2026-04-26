from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Request
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from clients.sportradar_client import SportradarClient
from core.dependencies import get_feature_service
from core.security import get_current_user
from db.engine import async_session as session_factory
from services.explanation_service import ExplanationService
from services.feature_service import FeatureService
from services.model_service import ModelService
from sportradar.db_models import SrFixture

router = APIRouter()

TRACKED_TEAM_ID = "sr:competitor:7734"
SUPERLIGA_COMPETITION_ID = "sr:competition:152"


def _ucluj_is_home(home_team: str, away_team: str) -> bool:
    home = str(home_team or "").strip().lower()
    return ("u cluj" in home) or ("universitatea cluj" in home)


def _to_ucluj_win_prob(home_win_prob: float, home_team: str, away_team: str) -> float:
    """Convert P(Home Win) → P(U Cluj Win) for this fixture."""
    if _ucluj_is_home(home_team, away_team):
        return home_win_prob
    return 1.0 - home_win_prob


def _dampen_probability(prob: float, weight: float = 0.55) -> float:
    """Reduce overconfident extremes toward 50% for UI trust/readability."""
    p = max(0.0, min(1.0, float(prob)))
    damped = 0.5 + (p - 0.5) * weight
    return max(0.10, min(0.90, damped))


async def _get_db():
    async with session_factory() as session:
        yield session


@router.get("/week-fixtures")
async def week_fixtures(
    request: Request,
    _user=Depends(get_current_user),
    feature_svc: FeatureService = Depends(get_feature_service),
    db: AsyncSession = Depends(_get_db),
):
    """Return Liga 1 fixtures for the current week with U Cluj-centric ML predictions.

    home_win_probability in each response item is P(U Cluj Win), not P(Home Win).
    key_drivers and top_risks are from U Cluj's perspective regardless of home/away.
    """
    now = datetime.now(timezone.utc)
    monday = (now - timedelta(days=now.weekday())).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    sunday = monday + timedelta(days=7)

    # 1) Try live Sportradar daily schedule for tracked team this week
    fixtures = await _live_tracked_week_fixtures(monday, sunday)

    # 2) Fall back to synced sr_fixtures DB rows
    if not fixtures:
        sr_rows = (
            await db.execute(
                select(SrFixture)
                .where(
                    SrFixture.scheduled >= monday.isoformat(),
                    SrFixture.scheduled < sunday.isoformat(),
                    ((SrFixture.home_team_id == TRACKED_TEAM_ID) | (SrFixture.away_team_id == TRACKED_TEAM_ID)),
                )
                .order_by(SrFixture.scheduled)
            )
        ).scalars().all()
        fixtures = [_sr_fixture_to_fixture(r) for r in sr_rows]

    # 3) Fall back to nearest historical fixture around this week
    if not fixtures:
        fixtures = await _nearest_live_tracked_fixtures(monday, sunday)

    model_svc = ModelService(getattr(request.app.state, "bundle", None))
    expl_svc = ExplanationService(model_svc)

    result = []
    for f in fixtures:
        item = dict(f)
        try:
            if model_svc.is_ready:
                feat = feature_svc.build_feature_vector(
                    f["home_team"], f["away_team"], model_svc.feature_cols
                )
                raw_home_prob = float(model_svc.predict_proba(feat))
                ucl_prob = _to_ucluj_win_prob(raw_home_prob, f["home_team"], f["away_team"])
                ui_prob = _dampen_probability(ucl_prob)
                ucl_is_home = _ucluj_is_home(f["home_team"], f["away_team"])

                # explain() now handles label orientation + SHAP sign based on ucl_is_home
                expl = expl_svc.explain(feat, ui_prob, ucl_is_home=ucl_is_home)

                item["home_win_probability"] = round(ui_prob, 4)
                item["key_drivers"] = expl["top_drivers"][:3]
                item["top_risks"] = expl["top_risks"][:2]
                item["narrative"] = expl["narrative"]
            else:
                item["home_win_probability"] = None
                item["key_drivers"] = []
                item["top_risks"] = []
                item["narrative"] = (
                    "Predictive model is temporarily unavailable. "
                    "XI recommendation and tactical form metrics remain active."
                )
        except Exception:
            item["home_win_probability"] = None
            item["key_drivers"] = []
            item["top_risks"] = []
            item["narrative"] = ""
        result.append(item)

    return result


def _parse_dt(val) -> datetime:
    if isinstance(val, datetime):
        return val if val.tzinfo else val.replace(tzinfo=timezone.utc)
    try:
        s = str(val)
        dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    except Exception:
        return datetime(1970, 1, 1, tzinfo=timezone.utc)


async def _live_tracked_week_fixtures(monday: datetime, sunday: datetime) -> list[dict]:
    if not settings.sportradar_api_key:
        return []

    client = SportradarClient()
    fixtures: list[dict] = []
    cursor = monday
    while cursor < sunday:
        date_iso = cursor.date().isoformat()
        try:
            data = await asyncio.wait_for(client.daily_schedules(date_iso), timeout=3.0)
        except Exception:
            data = None
        for raw_evt in (data or {}).get("schedules", []):
            se = raw_evt.get("sport_event", {})
            status = raw_evt.get("sport_event_status", {})
            ctx = se.get("sport_event_context", {})
            comp = ctx.get("competition", {})
            if comp.get("id") != SUPERLIGA_COMPETITION_ID:
                continue

            competitors = se.get("competitors", [])
            home = _find_qualifier(competitors, "home")
            away = _find_qualifier(competitors, "away")
            if not home or not away:
                continue
            if home.get("id") != TRACKED_TEAM_ID and away.get("id") != TRACKED_TEAM_ID:
                continue

            fixtures.append({
                "match_id": se.get("id", ""),
                "season": (ctx.get("season", {}) or {}).get("id", ""),
                "match_date": _event_kickoff(se),
                "home_team": home.get("name", ""),
                "away_team": away.get("name", ""),
                "home_score": status.get("home_score"),
                "away_score": status.get("away_score"),
                "venue": (se.get("venue", {}) or {}).get("name", ""),
            })
        cursor += timedelta(days=1)

    fixtures.sort(key=lambda f: f.get("match_date", ""))
    return fixtures


async def _nearest_live_tracked_fixtures(monday: datetime, sunday: datetime) -> list[dict]:
    if not settings.sportradar_api_key:
        return []

    client = SportradarClient()
    data = await client.competitor_schedules(TRACKED_TEAM_ID)
    events: list[tuple[datetime, dict]] = []

    for raw_evt in (data or {}).get("schedules", []):
        se = raw_evt.get("sport_event", {})
        status = raw_evt.get("sport_event_status", {})
        ctx = se.get("sport_event_context", {})
        comp = ctx.get("competition", {})
        if comp.get("id") != SUPERLIGA_COMPETITION_ID:
            continue

        dt = _parse_dt(_event_kickoff(se))
        if dt.year < 2025:
            continue

        competitors = se.get("competitors", [])
        home = _find_qualifier(competitors, "home")
        away = _find_qualifier(competitors, "away")
        if not home or not away:
            continue

        events.append((
            dt,
            {
                "match_id": se.get("id", ""),
                "season": (ctx.get("season", {}) or {}).get("id", ""),
                "match_date": _event_kickoff(se),
                "home_team": home.get("name", ""),
                "away_team": away.get("name", ""),
                "home_score": status.get("home_score"),
                "away_score": status.get("away_score"),
                "venue": (se.get("venue", {}) or {}).get("name", ""),
            },
        ))

    if not events:
        return []

    events.sort(key=lambda t: t[0])
    prev_events = [e for d, e in events if d < monday]
    next_events = [e for d, e in events if d >= sunday]

    out: list[dict] = []
    if prev_events:
        out.append(prev_events[-1])
    if next_events:
        out.append(next_events[0])
    return out


def _sr_fixture_to_fixture(f: SrFixture) -> dict:
    return {
        "match_id": f.id,
        "season": f.season_id,
        "match_date": f.scheduled,
        "home_team": f.home_team_name,
        "away_team": f.away_team_name,
        "home_score": f.home_score,
        "away_score": f.away_score,
        "venue": f.venue_name,
    }


def _find_qualifier(competitors: list[dict], qualifier: str) -> dict | None:
    for c in competitors:
        if c.get("qualifier") == qualifier:
            return c
    return None


def _event_kickoff(sport_event: dict) -> str:
    return (
        sport_event.get("scheduled")
        or sport_event.get("start_time")
        or ""
    )
