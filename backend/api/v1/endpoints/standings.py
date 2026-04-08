from fastapi import APIRouter, Depends, Query

from core.models import StandingsRow
from core.dependencies import get_feature_service, get_stadium_map
from services.fixture_service import FixtureService
from services.feature_service import FeatureService

router = APIRouter()


def _get_fixture_service(
    feature_svc: FeatureService = Depends(get_feature_service),
    stadium_map: dict = Depends(get_stadium_map),
) -> FixtureService:
    return FixtureService(feature_svc._df, stadium_map)


@router.get("/standings", response_model=list[StandingsRow])
def standings(
    season: str | None = Query(None),
    svc: FixtureService = Depends(_get_fixture_service),
):
    return svc.standings(season=season)
