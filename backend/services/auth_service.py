from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from db.models import User
from core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
)


class AuthService:

    def __init__(self, session: AsyncSession):
        self._session = session

    async def register(self, email: str, password: str) -> User:
        result = await self._session.execute(select(User).where(User.email == email))
        if result.scalar_one_or_none() is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

        user = User(email=email, password_hash=hash_password(password))
        self._session.add(user)
        await self._session.commit()
        await self._session.refresh(user)
        return user

    async def login(self, email: str, password: str) -> dict:
        result = await self._session.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()

        if user is None or not verify_password(password, user.password_hash):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

        if not user.is_active:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is deactivated")

        return {
            "access_token": create_access_token(user.id, user.email, user.role),
            "refresh_token": create_refresh_token(user.id),
            "token_type": "bearer",
        }

    async def refresh(self, refresh_token: str) -> dict:
        payload = decode_token(refresh_token, expected_type="refresh")
        user_id = payload.get("sub")

        result = await self._session.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()

        if user is None or not user.is_active:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or inactive")

        return {
            "access_token": create_access_token(user.id, user.email, user.role),
            "refresh_token": create_refresh_token(user.id),
            "token_type": "bearer",
        }
