from fastapi import APIRouter, Depends, Query

from app.config import settings
from core.models import DashboardResponse, DriverItem, FixtureDetail, StandingsRow
from core.dependencies import get_model_service, get_feature_service, get_stadium_map
from services.model_service import ModelService
from services.feature_service import FeatureService
from services.fixture_service import FixtureService
from services.explanation_service import ExplanationService

router = APIRouter()


def _get_fixture_service(
    feature_svc: FeatureService = Depends(get_feature_service),
    stadium_map: dict = Depends(get_stadium_map),
) -> FixtureService:
    return FixtureService(feature_svc._df, stadium_map)


@router.get("/dashboard", response_model=DashboardResponse)
def dashboard(
    team: str = Query(default=None),
    model_svc: ModelService = Depends(get_model_service),
    feature_svc: FeatureService = Depends(get_feature_service),
    fixture_svc: FixtureService = Depends(_get_fixture_service),
):
    tracked = team or settings.tracked_team
    recent = fixture_svc.recent_fixtures(tracked, n=5)
    upcoming = fixture_svc.upcoming_fixtures(tracked, n=3)

    next_fixture = upcoming[0] if upcoming else (recent[0] if recent else None)

    prob = None
    drivers: list[dict] = []

    if next_fixture and model_svc.is_ready:
        features = feature_svc.build_feature_vector(
            next_fixture["home_team"],
            next_fixture["away_team"],
            model_svc.feature_cols,
        )
        prob = round(model_svc.predict_proba(features), 4)
        explanation_svc = ExplanationService(model_svc)
        result = explanation_svc.explain(features, prob)
        drivers = result["top_drivers"][:3]

    standings_snapshot = fixture_svc.standings()[:5]

    return DashboardResponse(
        next_fixture=FixtureDetail(**next_fixture) if next_fixture else None,
        win_probability=prob,
        key_drivers=[DriverItem(**d) for d in drivers],
        recent_fixtures=[FixtureDetail(**f) for f in recent],
        upcoming_fixtures=[FixtureDetail(**f) for f in upcoming],
        standings_snapshot=[StandingsRow(**s) for s in standings_snapshot],
    )
