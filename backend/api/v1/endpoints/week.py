from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends

from core.dependencies import get_feature_service, get_model_service, get_stadium_map
from core.security import get_current_user
from services.explanation_service import ExplanationService
from services.feature_service import FeatureService
from services.fixture_service import FixtureService
from services.model_service import ModelService

router = APIRouter()

TRACKED_TEAM = "Universitatea Cluj"


def _get_fixture_service(
    feature_svc: FeatureService = Depends(get_feature_service),
    stadium_map: dict = Depends(get_stadium_map),
) -> FixtureService:
    return FixtureService(feature_svc._df, stadium_map)


@router.get("/week-fixtures")
def week_fixtures(
    _user=Depends(get_current_user),
    feature_svc: FeatureService = Depends(get_feature_service),
    model_svc: ModelService = Depends(get_model_service),
    fixture_svc: FixtureService = Depends(_get_fixture_service),
):
    """Return all Liga 1 fixtures for the current week (Mon–Sun).
    
    Because the dataset covers historical matches (up to 2024-2025 season),
    we also fall back to the most recent 5 real fixtures of the tracked team
    plus generate a predictive upcoming block so the UI always has content.
    """
    now = datetime.now(timezone.utc)
    # Monday of current week
    monday = (now - timedelta(days=now.weekday())).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    sunday = monday + timedelta(days=7)

    df = fixture_svc._df.copy()
    df["match_date_parsed"] = df["match_date"].apply(_parse_dt)

    mask = (df["match_date_parsed"] >= monday) & (df["match_date_parsed"] < sunday)
    week_df = df[mask].sort_values("match_date_parsed")

    fixtures = [fixture_svc._row_to_fixture(r) for _, r in week_df.iterrows()]

    # Fall back: if the dataset has no matches this week (historical data),
    # show the last 5 completed fixtures of the tracked team + 2 upcoming mocks.
    if not fixtures:
        recent = fixture_svc.recent_fixtures(TRACKED_TEAM, n=5)
        upcoming = fixture_svc.upcoming_fixtures(TRACKED_TEAM, n=2)
        fixtures = recent + upcoming

    # Attach ML probability + key drivers to each fixture
    result = []
    for f in fixtures:
        item = dict(f)
        try:
            if model_svc.is_ready:
                feat = feature_svc.build_feature_vector(
                    f["home_team"], f["away_team"], model_svc.feature_cols
                )
                prob = round(model_svc.predict_proba(feat), 4)
                expl = ExplanationService(model_svc).explain(feat, prob)
                item["home_win_probability"] = prob
                item["key_drivers"] = expl["top_drivers"][:3]
                item["top_risks"] = expl["top_risks"][:2]
                item["narrative"] = expl["narrative"]
            else:
                item["home_win_probability"] = None
                item["key_drivers"] = []
                item["top_risks"] = []
                item["narrative"] = "Model not ready."
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
