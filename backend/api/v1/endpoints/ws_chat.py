import os
import uuid
import shutil
from collections import defaultdict
from typing import Dict, List
from datetime import datetime, timezone

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query, HTTPException, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from db.engine import async_session as session_factory
from db.models import Message, User
from core.security import decode_token

router = APIRouter(prefix="/chat", tags=["chat"])

async def _get_db():
    async with session_factory() as session:
        yield session

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = defaultdict(list)

    async def connect(self, websocket: WebSocket, team_name: str):
        await websocket.accept()
        self.active_connections[team_name].append(websocket)

    def disconnect(self, websocket: WebSocket, team_name: str):
        if team_name in self.active_connections:
            if websocket in self.active_connections[team_name]:
                self.active_connections[team_name].remove(websocket)

    async def broadcast_to_team(self, message: dict, team_name: str):
        if team_name in self.active_connections:
            for connection in self.active_connections[team_name]:
                await connection.send_json(message)

manager = ConnectionManager()

async def get_current_user_ws(token: str, session: AsyncSession) -> User | None:
    try:
        payload = decode_token(token)
        user_id = payload.get("sub")
        if not user_id:
            return None
        result = await session.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if user and user.is_active:
            return user
    except Exception:
        return None
    return None

async def enforce_message_limit(session: AsyncSession, team_name: str, limit: int = 25):
    # Fetch all message IDs ordered by newest first
    stmt = select(Message).where(Message.team_name == team_name).order_by(desc(Message.created_at))
    result = await session.execute(stmt)
    all_msgs = result.scalars().all()
    
    # If we have more than limit, delete the older ones
    if len(all_msgs) > limit:
        msgs_to_delete = all_msgs[limit:]
        for msg in msgs_to_delete:
            await session.delete(msg)
        await session.commit()

@router.websocket("/ws")
async def websocket_chat(websocket: WebSocket, token: str = Query(...)):
    # Create an independent session for the WebSocket
    async with session_factory() as session:
        user = await get_current_user_ws(token, session)
        if not user or not user.team_name:
            await websocket.close(code=1008)
            return
        
        team_name = user.team_name
    
    await manager.connect(websocket, team_name)
    
    # Fetch history inside its own transaction
    async with session_factory() as session:
        stmt = select(Message).where(Message.team_name == team_name).order_by(Message.created_at)
        result = await session.execute(stmt)
        history = result.scalars().all()
        
        for msg in history:
            await websocket.send_json({
                "id": msg.id,
                "author_id": msg.author_id,
                "author_name": msg.author_name,
                "content": msg.content,
                "file_url": msg.file_url,
                "file_type": msg.file_type,
                "created_at": msg.created_at.isoformat() if msg.created_at else None
            })

    try:
        while True:
            data = await websocket.receive_json()
            
            # Save message to DB and broadcast
            async with session_factory() as session:
                new_msg = Message(
                    team_name=team_name,
                    author_id=user.id,
                    author_name=(user.full_name.strip() if user.full_name and user.full_name.strip() else None) or user.email.split('@')[0],
                    content=data.get("content"),
                    file_url=data.get("file_url"),
                    file_type=data.get("file_type")
                )
                session.add(new_msg)
                await session.commit()
                await session.refresh(new_msg)
                
                await enforce_message_limit(session, team_name, 25)
                
                await manager.broadcast_to_team({
                    "id": new_msg.id,
                    "author_id": new_msg.author_id,
                    "author_name": new_msg.author_name,
                    "content": new_msg.content,
                    "file_url": new_msg.file_url,
                    "file_type": new_msg.file_type,
                    "created_at": new_msg.created_at.isoformat() if new_msg.created_at else None
                }, team_name)
            
    except WebSocketDisconnect:
        manager.disconnect(websocket, team_name)

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    file_id = str(uuid.uuid4())
    ext = os.path.splitext(file.filename)[1]
    filename = f"{file_id}{ext}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    return {"url": f"/uploads/{filename}", "type": file.content_type}
