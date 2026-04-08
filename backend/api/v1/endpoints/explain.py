from fastapi import APIRouter, Depends

from core.models import FixtureRequest, ExplanationResponse, DriverItem
from core.dependencies import get_model_service, get_feature_service
from core.exceptions import TeamNotFoundError
from services.model_service import ModelService
from services.feature_service import FeatureService
from services.explanation_service import ExplanationService

router = APIRouter()


@router.post("/explain", response_model=ExplanationResponse)
def explain(
    body: FixtureRequest,
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
    explanation_svc = ExplanationService(model_svc)
    result = explanation_svc.explain(features, prob)

    return ExplanationResponse(
        home_team=body.home_team,
        away_team=body.away_team,
        probability=round(prob, 4),
        top_drivers=[DriverItem(**d) for d in result["top_drivers"]],
        top_risks=[DriverItem(**r) for r in result["top_risks"]],
        narrative=result["narrative"],
    )
