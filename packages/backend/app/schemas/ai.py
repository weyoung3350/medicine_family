"""AI 问诊请求/响应模型。"""
import uuid
from datetime import datetime

from pydantic import BaseModel


class ChatRequest(BaseModel):
    familyId: uuid.UUID
    memberId: uuid.UUID
    message: str
    images: list[str] | None = None


class ChatResponse(BaseModel):
    reply: str
    consultationId: uuid.UUID
    resultDetail: dict | None = None


class AnalyzeImageRequest(BaseModel):
    familyId: uuid.UUID
    memberId: uuid.UUID
    imageUrls: list[str]
    question: str | None = None


class MedicationCheckRequest(BaseModel):
    familyId: uuid.UUID
    memberId: uuid.UUID
    drugNames: list[str]


class MedicationGuideRequest(BaseModel):
    familyId: uuid.UUID
    memberId: uuid.UUID
    medicineId: uuid.UUID


class ConsultationOut(BaseModel):
    id: uuid.UUID
    type: str
    inputText: str | None = None
    aiModel: str
    resultSummary: str | None = None
    createdAt: datetime
