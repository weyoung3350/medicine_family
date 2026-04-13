"""药品、库存、OCR 路由。"""
import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.medicine import (
    AddInventoryRequest,
    CreateMedicineRequest,
    InventoryOut,
    MedicineOut,
    OcrRequest,
    OcrResult,
)
from app.services import medicine_service, ocr_service
from app.services.family_service import _check_family_access

router = APIRouter(prefix="/families/{family_id}/medicines", tags=["药品"])


@router.post("/ocr", response_model=OcrResult)
async def ocr_medicine(
    family_id: uuid.UUID,
    data: OcrRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    return await ocr_service.recognize(data.imageUrl)


@router.post("", response_model=MedicineOut)
async def create_medicine(
    family_id: uuid.UUID,
    data: CreateMedicineRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    return await medicine_service.create_medicine(family_id, data, user.id, db)


@router.get("", response_model=list[MedicineOut])
async def list_medicines(
    family_id: uuid.UUID,
    keyword: str | None = Query(None),
    category: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    return await medicine_service.list_medicines(family_id, db, keyword, category)


@router.get("/expiring", response_model=list[MedicineOut])
async def expiring_medicines(
    family_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    return await medicine_service.find_expiring(family_id, db)


@router.get("/low-stock", response_model=list[MedicineOut])
async def low_stock_medicines(
    family_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    return await medicine_service.find_low_stock(family_id, db)


@router.get("/{medicine_id}", response_model=MedicineOut)
async def get_medicine(
    family_id: uuid.UUID,
    medicine_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    return await medicine_service.get_medicine(family_id, medicine_id, db)


@router.post("/{medicine_id}/inventory", response_model=InventoryOut)
async def add_inventory(
    family_id: uuid.UUID,
    medicine_id: uuid.UUID,
    data: AddInventoryRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _check_family_access(family_id, user.id, db)
    return await medicine_service.add_inventory(family_id, medicine_id, data, db)
