from fastapi import APIRouter, Request

router = APIRouter()


@router.get("/health")
def health_check(request: Request):
    bundle = getattr(request.app.state, "bundle", None)
    df = getattr(request.app.state, "df", None)
    return {
        "status": "ok",
        "model_loaded": bundle is not None,
        "data_loaded": df is not None,
        "data_rows": len(df) if df is not None else 0,
    }
