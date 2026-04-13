"""家庭、成员、健康档案路由。"""
import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.family import (
    AddDependentRequest,
    CreateFamilyRequest,
    FamilyOut,
    HealthProfileIn,
    HealthProfileOut,
    JoinFamilyRequest,
    MemberOut,
)
from app.services import family_service

router = APIRouter(prefix="/families", tags=["家庭"])


@router.post("", response_model=FamilyOut)
async def create_family(
    data: CreateFamilyRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await family_service.create_family(data, user.id, db)


@router.get("", response_model=list[FamilyOut])
async def list_families(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await family_service.list_families(user.id, db)


@router.post("/join", response_model=FamilyOut)
async def join_family(
    data: JoinFamilyRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await family_service.join_family(data.inviteCode, user.id, db)


@router.get("/{family_id}/members", response_model=list[MemberOut])
async def list_members(
    family_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await family_service.list_members(family_id, db)


@router.post("/{family_id}/members", response_model=MemberOut)
async def add_dependent(
    family_id: uuid.UUID,
    data: AddDependentRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await family_service.add_dependent(family_id, data, user.id, db)


@router.get("/{family_id}/members/{member_id}/health", response_model=HealthProfileOut)
async def get_health(
    family_id: uuid.UUID,
    member_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await family_service.get_health_profile(family_id, member_id, user.id, db)


@router.put("/{family_id}/members/{member_id}/health", response_model=HealthProfileOut)
async def update_health(
    family_id: uuid.UUID,
    member_id: uuid.UUID,
    data: HealthProfileIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await family_service.update_health_profile(family_id, member_id, user.id, data, db)
