"""病历 CRUD + OCR 路由。"""
import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.medical_record import (
    CreateMedicalRecordRequest,
    MedicalOcrRequest,
    MedicalOcrResult,
    MedicalRecordOut,
    UpdateMedicalRecordRequest,
)
from app.services import medical_record_service, medical_record_ocr_service
from app.services.family_service import _check_family_access

router = APIRouter(prefix="/families/{family_id}/medical-records", tags=["病历"])


@router.post("/ocr", response_model=MedicalOcrResult)
async def ocr(
    family_id: uuid.UUID, data: MedicalOcrRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    return await medical_record_ocr_service.recognize(data.imageUrl)


@router.post("", response_model=MedicalRecordOut)
async def create(
    family_id: uuid.UUID, data: CreateMedicalRecordRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    return await medical_record_service.create(family_id, data, user.id, db)


@router.get("", response_model=list[MedicalRecordOut])
async def list_records(
    family_id: uuid.UUID,
    memberId: uuid.UUID | None = Query(None),
    keyword: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    return await medical_record_service.list_records(family_id, db, memberId, keyword)


@router.get("/{record_id}", response_model=MedicalRecordOut)
async def get_one(
    family_id: uuid.UUID, record_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    return await medical_record_service.get_one(family_id, record_id, db)


@router.put("/{record_id}", response_model=MedicalRecordOut)
async def update(
    family_id: uuid.UUID, record_id: uuid.UUID,
    data: UpdateMedicalRecordRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    return await medical_record_service.update(family_id, record_id, data, db)


@router.delete("/{record_id}")
async def delete(
    family_id: uuid.UUID, record_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    await medical_record_service.delete(family_id, record_id, db)
    return {"ok": True}
