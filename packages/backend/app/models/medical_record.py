import uuid
from datetime import date

from sqlalchemy import Boolean, Date, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class MedicalRecord(Base):
    __tablename__ = "medical_record"

    family_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("family.id"))
    member_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("family_member.id"))
    hospital: Mapped[str | None] = mapped_column(String(200))
    department: Mapped[str | None] = mapped_column(String(100))
    doctor: Mapped[str | None] = mapped_column(String(100))
    visit_date: Mapped[date | None] = mapped_column(Date)
    diagnosis: Mapped[str | None] = mapped_column(Text)
    chief_complaint: Mapped[str | None] = mapped_column(Text)
    present_illness: Mapped[str | None] = mapped_column(Text)
    prescriptions: Mapped[dict | None] = mapped_column(JSONB)
    examinations: Mapped[str | None] = mapped_column(Text)
    doctor_advice: Mapped[str | None] = mapped_column(Text)
    image_url: Mapped[str | None] = mapped_column(String(500))
    ocr_raw_data: Mapped[dict | None] = mapped_column(JSONB)
    confidence: Mapped[float | None] = mapped_column(Numeric(3, 2))
    needs_review: Mapped[bool] = mapped_column(Boolean, default=False)
    created_by: Mapped[uuid.UUID | None] = mapped_column()
