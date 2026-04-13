"""药品 CRUD 业务逻辑。"""
import uuid
from datetime import date, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.medicine import Medicine
from app.models.medicine_inventory import MedicineInventory
from app.schemas.medicine import (
    AddInventoryRequest,
    CreateMedicineRequest,
    InventoryOut,
    MedicineOut,
)


def _inv_out(inv: MedicineInventory) -> InventoryOut:
    return InventoryOut(
        id=inv.id,
        batchNumber=inv.batch_number,
        expiryDate=inv.expiry_date,
        totalQuantity=inv.total_quantity,
        remainingQty=inv.remaining_qty,
        lowThreshold=inv.low_threshold,
        status=inv.status,
        isLowStock=0 < inv.remaining_qty <= inv.low_threshold,
    )


def _med_out(med: Medicine) -> MedicineOut:
    return MedicineOut(
        id=med.id,
        name=med.name,
        brandName=med.brand_name,
        specification=med.specification,
        unit=med.unit,
        dosageForm=med.dosage_form,
        category=med.category,
        manufacturer=med.manufacturer,
        approvalNumber=med.approval_number,
        indications=med.indications,
        contraindications=med.contraindications,
        sideEffects=med.side_effects,
        interactions=med.interactions,
        usageGuide=med.usage_guide,
        imageUrl=med.image_url,
        inventories=[_inv_out(i) for i in (med.inventories or [])],
    )


async def create_medicine(
    family_id: uuid.UUID, data: CreateMedicineRequest,
    user_id: uuid.UUID, db: AsyncSession,
) -> MedicineOut:
    med = Medicine(
        family_id=family_id,
        name=data.name,
        brand_name=data.brandName,
        specification=data.specification,
        unit=data.unit,
        dosage_form=data.dosageForm,
        category=data.category,
        manufacturer=data.manufacturer,
        approval_number=data.approvalNumber,
        indications=data.indications,
        contraindications=data.contraindications,
        side_effects=data.sideEffects,
        interactions=data.interactions,
        usage_guide=data.usageGuide,
        image_url=data.imageUrl,
        ocr_raw_data=data.ocrRawData,
        created_by=user_id,
    )
    db.add(med)
    await db.commit()
    return await get_medicine(family_id, med.id, db)


async def list_medicines(
    family_id: uuid.UUID, db: AsyncSession,
    keyword: str | None = None, category: str | None = None,
) -> list[MedicineOut]:
    stmt = (
        select(Medicine)
        .where(Medicine.family_id == family_id)
        .options(selectinload(Medicine.inventories))
    )
    if keyword:
        stmt = stmt.where(Medicine.name.ilike(f"%{keyword}%"))
    if category:
        stmt = stmt.where(Medicine.category == category)
    result = await db.scalars(stmt)
    return [_med_out(m) for m in result]


async def get_medicine(
    family_id: uuid.UUID, medicine_id: uuid.UUID, db: AsyncSession,
) -> MedicineOut:
    med = await db.scalar(
        select(Medicine)
        .where(Medicine.id == medicine_id, Medicine.family_id == family_id)
        .options(selectinload(Medicine.inventories))
    )
    if not med:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="药品不存在")
    return _med_out(med)


async def add_inventory(
    family_id: uuid.UUID, medicine_id: uuid.UUID,
    data: AddInventoryRequest, db: AsyncSession,
) -> InventoryOut:
    med = await db.scalar(
        select(Medicine).where(Medicine.id == medicine_id, Medicine.family_id == family_id)
    )
    if not med:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="药品不存在")

    inv_status = _calc_status(data.expiryDate, data.totalQuantity, data.totalQuantity, data.lowThreshold)
    inv = MedicineInventory(
        medicine_id=medicine_id,
        batch_number=data.batchNumber,
        expiry_date=data.expiryDate,
        total_quantity=data.totalQuantity,
        remaining_qty=data.totalQuantity,
        low_threshold=data.lowThreshold,
        status=inv_status,
    )
    db.add(inv)
    await db.commit()
    await db.refresh(inv)
    return _inv_out(inv)


def _calc_status(
    expiry_date: date | None, remaining: int, total: int, threshold: int,
) -> int:
    """计算库存状态：1正常 2临期 3过期 4用完。"""
    if remaining <= 0:
        return 4  # 用完
    if expiry_date:
        today = date.today()
        if expiry_date <= today:
            return 3  # 过期
        if expiry_date <= today + timedelta(days=30):
            return 2  # 临期
    return 1  # 正常


async def find_expiring(family_id: uuid.UUID, db: AsyncSession) -> list[MedicineOut]:
    """查找有临期库存的药品（30 天内到期）。"""
    today = date.today()
    cutoff = today + timedelta(days=30)
    stmt = (
        select(Medicine)
        .where(Medicine.family_id == family_id)
        .options(selectinload(Medicine.inventories))
        .join(Medicine.inventories)
        .where(
            MedicineInventory.expiry_date.isnot(None),
            MedicineInventory.expiry_date <= cutoff,
            MedicineInventory.expiry_date > today,
            MedicineInventory.remaining_qty > 0,
        )
    )
    result = await db.scalars(stmt)
    return [_med_out(m) for m in result.unique()]


async def find_low_stock(family_id: uuid.UUID, db: AsyncSession) -> list[MedicineOut]:
    """查找有低库存的药品。"""
    stmt = (
        select(Medicine)
        .where(Medicine.family_id == family_id)
        .options(selectinload(Medicine.inventories))
        .join(Medicine.inventories)
        .where(
            MedicineInventory.remaining_qty <= MedicineInventory.low_threshold,
            MedicineInventory.remaining_qty > 0,
        )
    )
    result = await db.scalars(stmt)
    return [_med_out(m) for m in result.unique()]
