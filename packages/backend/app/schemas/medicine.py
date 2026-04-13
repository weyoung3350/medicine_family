"""药品、库存、OCR 的请求/响应模型，对齐前端 api/medicine.ts。"""
import uuid
from datetime import date

from pydantic import BaseModel, Field


# ---------- 库存 ----------

class AddInventoryRequest(BaseModel):
    totalQuantity: int
    batchNumber: str | None = None
    expiryDate: date | None = None
    lowThreshold: int = 5


class InventoryOut(BaseModel):
    id: uuid.UUID
    batchNumber: str | None = None
    expiryDate: date | None = None
    totalQuantity: int
    remainingQty: int
    lowThreshold: int
    status: int          # 1正常 2临期 3过期 4用完
    isLowStock: bool     # remainingQty > 0 且 <= lowThreshold


# ---------- 药品 ----------

class CreateMedicineRequest(BaseModel):
    name: str
    brandName: str | None = None
    specification: str | None = None
    unit: str = "粒"
    dosageForm: str | None = None
    category: str | None = None
    manufacturer: str | None = None
    approvalNumber: str | None = None
    indications: str | None = None
    contraindications: str | None = None
    sideEffects: str | None = None
    interactions: str | None = None
    usageGuide: str | None = None
    imageUrl: str | None = None
    ocrRawData: dict | None = None


class MedicineOut(BaseModel):
    id: uuid.UUID
    name: str
    brandName: str | None = None
    specification: str | None = None
    unit: str
    dosageForm: str | None = None
    category: str | None = None
    manufacturer: str | None = None
    approvalNumber: str | None = None
    indications: str | None = None
    contraindications: str | None = None
    sideEffects: str | None = None
    interactions: str | None = None
    usageGuide: str | None = None
    imageUrl: str | None = None
    inventories: list[InventoryOut] = Field(default_factory=list)


# ---------- OCR ----------

class OcrRequest(BaseModel):
    imageUrl: str


class OcrResult(BaseModel):
    name: str | None = None
    brandName: str | None = None
    specification: str | None = None
    dosageForm: str | None = None
    manufacturer: str | None = None
    approvalNumber: str | None = None
    batchNumber: str | None = None
    expiryDate: str | None = None
    indications: str | None = None
    contraindications: str | None = None
    usageGuide: str | None = None
    confidence: float = 0.0
    needsReview: bool = True


# ---------- 上传 ----------

class UploadResult(BaseModel):
    url: str
