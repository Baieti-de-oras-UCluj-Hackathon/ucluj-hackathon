from fastapi import Request

from services.model_service import ModelService
from services.feature_service import FeatureService
from core.exceptions import ModelNotLoadedError


def get_model_service(request: Request) -> ModelService:
    svc = ModelService(request.app.state.bundle)
    if not svc.is_ready:
        raise ModelNotLoadedError()
    return svc


def get_feature_service(request: Request) -> FeatureService:
    return FeatureService(request.app.state.df)


def get_stadium_map(request: Request) -> dict[str, str]:
    return request.app.state.stadium_map
