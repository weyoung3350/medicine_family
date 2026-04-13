"""服药计划、打卡、依从性路由。"""
import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.medication import (
    AdherenceStats,
    CheckInRequest,
    CheckInResult,
    CreatePlanRequest,
    PlanOut,
    TodayItem,
)
from app.services import medication_service
from app.services.family_service import _check_family_access, _check_member_in_family

router = APIRouter(
    prefix="/families/{family_id}/members/{member_id}/plans",
    tags=["服药"],
)


@router.post("", response_model=PlanOut)
async def create_plan(
    family_id: uuid.UUID, member_id: uuid.UUID,
    data: CreatePlanRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    await _check_member_in_family(family_id, member_id, db)
    return await medication_service.create_plan(member_id, data, user.id, db)


@router.get("", response_model=list[PlanOut])
async def list_plans(
    family_id: uuid.UUID, member_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    await _check_member_in_family(family_id, member_id, db)
    return await medication_service.list_plans(member_id, db)


@router.get("/today", response_model=list[TodayItem])
async def today_schedule(
    family_id: uuid.UUID, member_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    await _check_member_in_family(family_id, member_id, db)
    return await medication_service.get_today(member_id, db)


@router.post("/{plan_id}/schedules/{schedule_id}/check-in", response_model=CheckInResult)
async def check_in(
    family_id: uuid.UUID, member_id: uuid.UUID,
    plan_id: uuid.UUID, schedule_id: uuid.UUID,
    data: CheckInRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    await _check_member_in_family(family_id, member_id, db)
    return await medication_service.check_in(schedule_id, data, user.id, db)


@router.get("/adherence", response_model=AdherenceStats)
async def adherence(
    family_id: uuid.UUID, member_id: uuid.UUID,
    range: str = Query("week"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    await _check_member_in_family(family_id, member_id, db)
    return await medication_service.get_adherence(member_id, range, db)
