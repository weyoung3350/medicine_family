import uuid
from datetime import date

from sqlalchemy import Boolean, Date, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class MedicationPlan(Base):
    __tablename__ = "medication_plan"

    member_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("family_member.id"))
    medicine_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("medicine.id"))
    inventory_id: Mapped[uuid.UUID | None] = mapped_column()
    dosage_amount: Mapped[float] = mapped_column(Numeric(5, 1))
    dosage_unit: Mapped[str] = mapped_column(String(20))
    frequency_type: Mapped[str] = mapped_column(String(30))
    frequency_days: Mapped[list[int] | None] = mapped_column(ARRAY(Integer))
    custom_interval: Mapped[int | None] = mapped_column(Integer)
    meal_relation: Mapped[str | None] = mapped_column(String(20))
    start_date: Mapped[date] = mapped_column(Date)
    end_date: Mapped[date | None] = mapped_column(Date)
    grace_period_minutes: Mapped[int] = mapped_column(Integer, default=15)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    prescribed_by: Mapped[str | None] = mapped_column(String(100))
    notes: Mapped[str | None] = mapped_column(Text)
    created_by: Mapped[uuid.UUID | None] = mapped_column()

    # 关系
    schedules: Mapped[list["MedicationSchedule"]] = relationship(
        back_populates="plan", cascade="all, delete-orphan",
    )
    medicine: Mapped["Medicine"] = relationship()
    member: Mapped["FamilyMember"] = relationship()


from app.models.medication_schedule import MedicationSchedule  # noqa: E402, F811
from app.models.medicine import Medicine  # noqa: E402, F811
from app.models.family_member import FamilyMember  # noqa: E402, F811
