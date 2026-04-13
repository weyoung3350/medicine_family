import uuid
from datetime import date, datetime, time

from sqlalchemy import Date, DateTime, ForeignKey, Numeric, String, Text, Time
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class MedicationLog(Base):
    __tablename__ = "medication_log"

    schedule_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("medication_schedule.id"))
    plan_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("medication_plan.id"))
    member_id: Mapped[uuid.UUID] = mapped_column()
    scheduled_date: Mapped[date] = mapped_column(Date)
    scheduled_time: Mapped[time] = mapped_column(Time)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    taken_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    quantity_taken: Mapped[float | None] = mapped_column(Numeric(5, 1))
    recorded_by: Mapped[uuid.UUID | None] = mapped_column()
    skip_reason: Mapped[str | None] = mapped_column(String(200))
    notes: Mapped[str | None] = mapped_column(Text)
