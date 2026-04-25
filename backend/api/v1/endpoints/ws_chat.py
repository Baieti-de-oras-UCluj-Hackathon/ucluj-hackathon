import os
import json
import uuid
import shutil
from collections import defaultdict
from typing import Dict, List
from datetime import datetime, timezone
from pydantic import BaseModel

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query, HTTPException, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from db.engine import async_session as session_factory
from db.models import Message, User, ChatGroup
from core.security import decode_token, get_current_user

router = APIRouter(prefix="/chat", tags=["chat"])

async def _get_db():
    async with session_factory() as session:
        yield session

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = defaultdict(list)

    async def connect(self, websocket: WebSocket, channel_id: str):
        await websocket.accept()
        self.active_connections[channel_id].append(websocket)

    def disconnect(self, websocket: WebSocket, channel_id: str):
        if channel_id in self.active_connections:
            if websocket in self.active_connections[channel_id]:
                self.active_connections[channel_id].remove(websocket)

    async def broadcast_to_channel(self, message: dict, channel_id: str):
        if channel_id in self.active_connections:
            for connection in self.active_connections[channel_id]:
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

async def enforce_message_limit(session: AsyncSession, channel_id: str, limit: int = 50):
    # Fetch all message IDs ordered by newest first
    stmt = select(Message).where(Message.channel_id == channel_id).order_by(desc(Message.created_at))
    result = await session.execute(stmt)
    all_msgs = result.scalars().all()
    
    # If we have more than limit, delete the older ones
    if len(all_msgs) > limit:
        msgs_to_delete = all_msgs[limit:]
        for msg in msgs_to_delete:
            await session.delete(msg)
        await session.commit()

@router.websocket("/ws/{channel_id}")
async def websocket_chat(websocket: WebSocket, channel_id: str, token: str = Query(...)):
    # Create an independent session for the WebSocket
    async with session_factory() as session:
        user = await get_current_user_ws(token, session)
        if not user or not user.team_name:
            await websocket.close(code=1008)
            return
        
        team_name = user.team_name
        
        # Security: If joining a group channel, verify membership
        if channel_id.startswith("group_"):
            group_uuid = channel_id.replace("group_", "")
            stmt = select(ChatGroup).where(ChatGroup.id == group_uuid)
            res = await session.execute(stmt)
            group = res.scalar_one_or_none()
            
            if not group:
                await websocket.close(code=1008)
                return
            
            try:
                members = json.loads(group.member_ids)
                if user.id not in members:
                    await websocket.close(code=1008)
                    return
            except:
                await websocket.close(code=1008)
                return
    await manager.connect(websocket, channel_id)
    
    # Fetch history inside its own transaction
    async with session_factory() as session:
        stmt = select(Message).where(Message.channel_id == channel_id).order_by(Message.created_at)
        result = await session.execute(stmt)
        history = result.scalars().all()
        
        for msg in history:
            await websocket.send_json({
                "id": msg.id,
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
                    channel_id=channel_id,
                    author_name=user.full_name or user.email,
                    content=data.get("content"),
                    file_url=data.get("file_url"),
                    file_type=data.get("file_type")
                )
                session.add(new_msg)
                await session.commit()
                await session.refresh(new_msg)
                
                await enforce_message_limit(session, channel_id, 50)
                
                await manager.broadcast_to_channel({
                    "id": new_msg.id,
                    "author_name": new_msg.author_name,
                    "content": new_msg.content,
                    "file_url": new_msg.file_url,
                    "file_type": new_msg.file_type,
                    "created_at": new_msg.created_at.isoformat() if new_msg.created_at else None
                }, channel_id)
            
    except WebSocketDisconnect:
        manager.disconnect(websocket, channel_id)

@router.get("/users")
async def get_team_users(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(_get_db)
):
    if not current_user.team_name:
        return []
    
    stmt = select(User).where(
        User.team_name == current_user.team_name,
        User.id != current_user.id
    )
    result = await session.execute(stmt)
    users = result.scalars().all()
    
    return [
        {
            "id": u.id,
            "email": u.email,
            "full_name": u.full_name,
            "role": u.role
        } for u in users
    ]

class CreateGroupRequest(BaseModel):
    name: str
    member_ids: List[str]

@router.post("/groups")
async def create_chat_group(
    req: CreateGroupRequest,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(_get_db)
):
    if not current_user.team_name:
        raise HTTPException(status_code=400, detail="User must belong to a team")
    
    members = set(req.member_ids)
    members.add(current_user.id)
    
    member_ids_str = json.dumps(list(members))
    
    new_group = ChatGroup(
        team_name=current_user.team_name,
        name=req.name,
        member_ids=member_ids_str
    )
    session.add(new_group)
    await session.commit()
    await session.refresh(new_group)
    return {"id": new_group.id, "name": new_group.name, "member_ids": list(members)}

@router.get("/groups")
async def get_chat_groups(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(_get_db)
):
    if not current_user.team_name:
        return []
    
    stmt = select(ChatGroup).where(ChatGroup.team_name == current_user.team_name)
    result = await session.execute(stmt)
    all_groups = result.scalars().all()
    
    user_groups = []
    for g in all_groups:
        try:
            members = json.loads(g.member_ids)
            if current_user.id in members:
                user_groups.append({
                    "id": g.id,
                    "name": g.name,
                    "member_ids": members
                })
        except:
            pass
    return user_groups

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
