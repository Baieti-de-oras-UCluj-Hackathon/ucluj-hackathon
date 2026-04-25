from __future__ import annotations

import secrets

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from db.models import User
from core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from services.reference_service import get_supported_teams


class AuthService:

    def __init__(self, session: AsyncSession):
        self._session = session

    async def register(self, email: str, password: str, team_name: str) -> User:
        result = await self._session.execute(select(User).where(User.email == email))
        if result.scalar_one_or_none() is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

        clean_team_name = team_name.strip()
        supported_teams = get_supported_teams()
        if supported_teams and clean_team_name not in supported_teams:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid team selection")

        user = User(email=email, password_hash=hash_password(password), team_name=clean_team_name)
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

    def _tokens_for(self, user: User) -> dict:
        if not user.is_active:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is deactivated")
        return {
            "access_token": create_access_token(user.id, user.email, user.role),
            "refresh_token": create_refresh_token(user.id),
            "token_type": "bearer",
        }

    async def exchange_firebase_id_token(self, id_token: str) -> dict:
        from services.firebase_id_token import verify_id_token

        try:
            claims = verify_id_token(id_token)
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Firebase token"
            ) from exc

        uid = claims.get("uid")
        email = (claims.get("email") or "").strip().lower()
        if not uid or not email:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Token missing uid or email")

        r = await self._session.execute(select(User).where(User.firebase_uid == uid))
        user = r.scalar_one_or_none()
        if user is not None:
            return self._tokens_for(user)

        r = await self._session.execute(select(User).where(func.lower(User.email) == email))
        user = r.scalar_one_or_none()
        if user is not None:
            if user.firebase_uid and user.firebase_uid != uid:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="This account is already linked to a different Firebase sign-in",
                )
            user.firebase_uid = uid
            await self._session.commit()
            await self._session.refresh(user)
            return self._tokens_for(user)

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "code": "NEEDS_REGISTRATION",
                "message": "No UmbraRo account for this sign-in yet.",
            },
        )

    async def register_with_firebase(self, id_token: str, team_name: str) -> dict:
        from services.firebase_id_token import verify_id_token

        try:
            claims = verify_id_token(id_token)
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Firebase token"
            ) from exc

        uid = claims.get("uid")
        email = (claims.get("email") or "").strip()
        if not uid or not email:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Token missing uid or email")

        r = await self._session.execute(select(User).where(User.firebase_uid == uid))
        if r.scalar_one_or_none() is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Sign-in already registered")

        r = await self._session.execute(select(User).where(func.lower(User.email) == email.lower()))
        if r.scalar_one_or_none() is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

        clean_team_name = team_name.strip()
        supported_teams = get_supported_teams()
        if supported_teams and clean_team_name not in supported_teams:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid team selection")

        user = User(
            email=email,
            password_hash=hash_password(secrets.token_urlsafe(48)),
            team_name=clean_team_name,
            firebase_uid=uid,
        )
        self._session.add(user)
        await self._session.commit()
        await self._session.refresh(user)
        return self._tokens_for(user)
