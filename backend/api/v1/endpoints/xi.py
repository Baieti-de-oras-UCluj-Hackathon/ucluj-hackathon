from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, Optional

from core.dependencies import get_xi_service
from services.xi_service import XiService

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
