from fastapi import APIRouter, Depends

from core.models import FixtureRequest, BlueprintResponse, TacticalTarget
from core.dependencies import get_model_service, get_feature_service
from core.exceptions import TeamNotFoundError
from services.model_service import ModelService
from services.feature_service import FeatureService
from services.optimizer_service import OptimizerService

router = APIRouter()


@router.post("/optimize", response_model=BlueprintResponse)
def optimize(
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
    optimizer = OptimizerService(model_svc)
    result = optimizer.optimize(features)

    return BlueprintResponse(
        home_team=body.home_team,
        away_team=body.away_team,
        baseline_probability=result["baseline_probability"],
        optimized_probability=result["optimized_probability"],
        uplift=result["uplift"],
        targets=[TacticalTarget(**t) for t in result["targets"]],
        diagnosis=result["diagnosis"],
    )
