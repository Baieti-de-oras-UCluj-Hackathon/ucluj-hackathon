from fastapi import APIRouter, Depends

from core.models import FixtureRequest, PredictionResponse
from core.dependencies import get_model_service, get_feature_service
from core.exceptions import TeamNotFoundError
from core.security import get_current_user
from services.model_service import ModelService
from services.feature_service import FeatureService

router = APIRouter()


@router.post("/predict", response_model=PredictionResponse)
def predict(
    body: FixtureRequest,
    _user=Depends(get_current_user),
    model_svc: ModelService = Depends(get_model_service),
    feature_svc: FeatureService = Depends(get_feature_service),
):
    teams = feature_svc.available_teams()
    if body.home_team not in teams:
        raise TeamNotFoundError(body.home_team)
    if body.away_team not in teams:
        raise TeamNotFoundError(body.away_team)

    features = feature_svc.build_feature_vector(
        body.home_team, body.away_team, model_svc.feature_cols,
    )
    prob = model_svc.predict_proba(features)

    return PredictionResponse(
        home_team=body.home_team,
        away_team=body.away_team,
        baseline_probability=round(prob, 4),
    )
