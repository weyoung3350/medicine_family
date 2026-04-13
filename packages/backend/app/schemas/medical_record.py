"""病历请求/响应模型。"""
import uuid
from datetime import date

from pydantic import BaseModel


class CreateMedicalRecordRequest(BaseModel):
    memberId: uuid.UUID | None = None
    hospital: str | None = None
    department: str | None = None
    doctor: str | None = None
    visitDate: date | None = None
    diagnosis: str | None = None
    chiefComplaint: str | None = None
    presentIllness: str | None = None
    prescriptions: dict | list | None = None
    examinations: str | None = None
    doctorAdvice: str | None = None
    imageUrl: str | None = None
    ocrRawData: dict | None = None
    confidence: float | None = None


class UpdateMedicalRecordRequest(BaseModel):
    hospital: str | None = None
    department: str | None = None
    doctor: str | None = None
    visitDate: date | None = None
    diagnosis: str | None = None
    chiefComplaint: str | None = None
    presentIllness: str | None = None
    prescriptions: dict | list | None = None
    examinations: str | None = None
    doctorAdvice: str | None = None


class MedicalRecordOut(BaseModel):
    id: uuid.UUID
    memberId: uuid.UUID | None = None
    hospital: str | None = None
    department: str | None = None
    doctor: str | None = None
    visitDate: date | None = None
    diagnosis: str | None = None
    chiefComplaint: str | None = None
    presentIllness: str | None = None
    prescriptions: dict | list | None = None
    examinations: str | None = None
    doctorAdvice: str | None = None
    imageUrl: str | None = None
    confidence: float | None = None
    needsReview: bool = False


class MedicalOcrRequest(BaseModel):
    imageUrl: str


class MedicalOcrResult(BaseModel):
    hospital: str | None = None
    department: str | None = None
    doctor: str | None = None
    visitDate: str | None = None
    diagnosis: str | None = None
    chiefComplaint: str | None = None
    presentIllness: str | None = None
    prescriptions: list | None = None
    examinations: str | None = None
    doctorAdvice: str | None = None
    confidence: float = 0.0
    needsReview: bool = True
