from __future__ import annotations

import threading

import firebase_admin
from firebase_admin import auth, credentials

from app.config import settings

_lock = threading.Lock()
_initialized: bool = False


def _ensure_firebase() -> None:
    global _initialized
    with _lock:
        if _initialized:
            return
        if not settings.firebase_project_id:
            raise RuntimeError("FIREBASE_PROJECT_ID is not configured for Firebase sign-in")
        if settings.firebase_credentials_path:
            cred = credentials.Certificate(settings.firebase_credentials_path)
        else:
            cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred, {"projectId": settings.firebase_project_id})
        _initialized = True


def verify_id_token(id_token: str) -> dict:
    _ensure_firebase()
    return auth.verify_id_token(id_token)
