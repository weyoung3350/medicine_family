"""AI 问诊路由。"""
import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.ai import ChatRequest, ChatResponse, ConsultationOut
from app.services import ai_service

router = APIRouter(prefix="/ai", tags=["AI问诊"])


@router.post("/chat", response_model=ChatResponse)
async def chat(
    data: ChatRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await ai_service.chat(data, user.id, db)


@router.get("/consultations", response_model=list[ConsultationOut])
async def list_consultations(
    familyId: uuid.UUID = Query(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await ai_service.list_consultations(familyId, user.id, db)
