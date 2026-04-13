"""病历 CRUD 业务逻辑。"""
import uuid

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.medical_record import MedicalRecord
from app.schemas.medical_record import (
    CreateMedicalRecordRequest,
    MedicalRecordOut,
    UpdateMedicalRecordRequest,
)


def _out(r: MedicalRecord) -> MedicalRecordOut:
    return MedicalRecordOut(
        id=r.id,
        memberId=r.member_id,
        hospital=r.hospital,
        department=r.department,
        doctor=r.doctor,
        visitDate=r.visit_date,
        diagnosis=r.diagnosis,
        chiefComplaint=r.chief_complaint,
        presentIllness=r.present_illness,
        prescriptions=r.prescriptions,
        examinations=r.examinations,
        doctorAdvice=r.doctor_advice,
        imageUrl=r.image_url,
        confidence=float(r.confidence) if r.confidence is not None else None,
        needsReview=r.needs_review,
    )


async def create(
    family_id: uuid.UUID, data: CreateMedicalRecordRequest,
    user_id: uuid.UUID, db: AsyncSession,
) -> MedicalRecordOut:
    rec = MedicalRecord(
        family_id=family_id,
        member_id=data.memberId,
        hospital=data.hospital,
        department=data.department,
        doctor=data.doctor,
        visit_date=data.visitDate,
        diagnosis=data.diagnosis,
        chief_complaint=data.chiefComplaint,
        present_illness=data.presentIllness,
        prescriptions=data.prescriptions,
        examinations=data.examinations,
        doctor_advice=data.doctorAdvice,
        image_url=data.imageUrl,
        ocr_raw_data=data.ocrRawData,
        confidence=data.confidence,
        needs_review=data.confidence is not None and data.confidence < 0.85,
        created_by=user_id,
    )
    db.add(rec)
    await db.commit()
    await db.refresh(rec)
    return _out(rec)


async def list_records(
    family_id: uuid.UUID, db: AsyncSession,
    member_id: uuid.UUID | None = None, keyword: str | None = None,
) -> list[MedicalRecordOut]:
    stmt = select(MedicalRecord).where(MedicalRecord.family_id == family_id)
    if member_id:
        stmt = stmt.where(MedicalRecord.member_id == member_id)
    if keyword:
        stmt = stmt.where(MedicalRecord.diagnosis.ilike(f"%{keyword}%"))
    stmt = stmt.order_by(MedicalRecord.created_at.desc())
    result = await db.scalars(stmt)
    return [_out(r) for r in result]


async def get_one(
    family_id: uuid.UUID, record_id: uuid.UUID, db: AsyncSession,
) -> MedicalRecordOut:
    rec = await db.scalar(
        select(MedicalRecord).where(
            MedicalRecord.id == record_id, MedicalRecord.family_id == family_id,
        )
    )
    if not rec:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="病历不存在")
    return _out(rec)


async def update(
    family_id: uuid.UUID, record_id: uuid.UUID,
    data: UpdateMedicalRecordRequest, db: AsyncSession,
) -> MedicalRecordOut:
    rec = await db.scalar(
        select(MedicalRecord).where(
            MedicalRecord.id == record_id, MedicalRecord.family_id == family_id,
        )
    )
    if not rec:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="病历不存在")

    for field, value in data.model_dump(exclude_unset=True).items():
        col = {
            "hospital": "hospital", "department": "department",
            "doctor": "doctor", "visitDate": "visit_date",
            "diagnosis": "diagnosis", "chiefComplaint": "chief_complaint",
            "presentIllness": "present_illness", "prescriptions": "prescriptions",
            "examinations": "examinations", "doctorAdvice": "doctor_advice",
        }.get(field)
        if col:
            setattr(rec, col, value)

    await db.commit()
    await db.refresh(rec)
    return _out(rec)


async def delete(
    family_id: uuid.UUID, record_id: uuid.UUID, db: AsyncSession,
) -> None:
    rec = await db.scalar(
        select(MedicalRecord).where(
            MedicalRecord.id == record_id, MedicalRecord.family_id == family_id,
        )
    )
    if not rec:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="病历不存在")
    await db.delete(rec)
    await db.commit()
