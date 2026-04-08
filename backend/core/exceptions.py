from fastapi import HTTPException, status


class ModelNotLoadedError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Model bundle not loaded. Prediction unavailable.",
        )


class TeamNotFoundError(HTTPException):
    def __init__(self, team: str):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Team '{team}' not found in dataset.",
        )
