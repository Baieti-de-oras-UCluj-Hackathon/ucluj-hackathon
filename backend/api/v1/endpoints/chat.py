from fastapi import APIRouter, Depends

from core.models import ChatRequest, ChatResponse
from core.dependencies import get_model_service, get_feature_service
from services.model_service import ModelService
from services.feature_service import FeatureService
from services.chat_service import ChatService

router = APIRouter()


@router.post("/chat", response_model=ChatResponse)
def chat(
    body: ChatRequest,
    model_svc: ModelService = Depends(get_model_service),
    feature_svc: FeatureService = Depends(get_feature_service),
):
    svc = ChatService(model_svc, feature_svc)
    result = svc.handle(body.query, body.home_team, body.away_team)
    return ChatResponse(answer=result["answer"], context=result.get("context"))
