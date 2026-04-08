from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import (
    RegisterRequest,
    LoginRequest,
    RefreshRequest,
    TokenResponse,
    UserResponse,
)
from core.security import get_current_user
from db.engine import async_session as session_factory
from db.models import User
from services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


async def _get_db():
    async with session_factory() as session:
        yield session


@router.post("/register", response_model=UserResponse, status_code=201)
async def register(body: RegisterRequest, db: AsyncSession = Depends(_get_db)):
    svc = AuthService(db)
    user = await svc.register(body.email, body.password)
    return UserResponse(id=user.id, email=user.email, role=user.role, is_active=user.is_active)


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(_get_db)):
    svc = AuthService(db)
    tokens = await svc.login(body.email, body.password)
    return TokenResponse(**tokens)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(body: RefreshRequest, db: AsyncSession = Depends(_get_db)):
    svc = AuthService(db)
    tokens = await svc.refresh(body.refresh_token)
    return TokenResponse(**tokens)


@router.get("/me", response_model=UserResponse)
async def me(user: User = Depends(get_current_user)):
    return UserResponse(id=user.id, email=user.email, role=user.role, is_active=user.is_active)
