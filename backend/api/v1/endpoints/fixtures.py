from fastapi import APIRouter, Depends, HTTPException, Query

from core.models import FixtureDetail
from core.dependencies import get_feature_service, get_stadium_map
from core.security import get_current_user
from services.fixture_service import FixtureService
from services.feature_service import FeatureService

router = APIRouter()


def _get_fixture_service(
    feature_svc: FeatureService = Depends(get_feature_service),
    stadium_map: dict = Depends(get_stadium_map),
) -> FixtureService:
    return FixtureService(feature_svc._df, stadium_map)


@router.get("/fixtures", response_model=list[FixtureDetail])
def list_fixtures(
    team: str | None = Query(None),
    season: str | None = Query(None),
    limit: int = Query(20, ge=1, le=100),
    _user=Depends(get_current_user),
    svc: FixtureService = Depends(_get_fixture_service),
):
    return svc.list_fixtures(team=team, season=season, limit=limit)


@router.get("/fixtures/{match_id}", response_model=FixtureDetail)
def fixture_detail(
    match_id: str,
    _user=Depends(get_current_user),
    svc: FixtureService = Depends(_get_fixture_service),
):
    result = svc.fixture_detail(match_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Fixture not found")
    return result
