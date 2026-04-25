from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Dict, Any, Optional

from core.dependencies import get_xi_service, get_feature_service
from services.xi_service import XiService
from services.feature_service import FeatureService

router = APIRouter()

class XiRequest(BaseModel):
    opponent_team_id: Optional[int] = None
    formation: str = "4-3-3"


class OpponentTeam(BaseModel):
    id: int
    name: str

@router.post("/predict", response_model=Dict[str, Any])
def predict_xi(
    body: XiRequest,
    xi_svc: XiService = Depends(get_xi_service)
):
    try:
        result = xi_svc.predict_xi(formation=body.formation, opponent_team_id=body.opponent_team_id)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/opponents", response_model=list[OpponentTeam])
def list_opponents(
    xi_svc: XiService = Depends(get_xi_service),
):
    try:
        return xi_svc.list_opponents()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/match-preview", response_model=Dict[str, Any])
def match_preview(
    opponent_name: str = Query(..., description="Opponent team name as it appears in fixtures"),
    formation: str = Query("4-3-3"),
    xi_svc: XiService = Depends(get_xi_service),
    feature_svc: FeatureService = Depends(get_feature_service),
):
    try:
        return xi_svc.match_preview(
            opponent_name=opponent_name,
            formation=formation,
            main_df=feature_svc._df,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
