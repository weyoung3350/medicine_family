import uuid
from datetime import time

from sqlalchemy import ForeignKey, SmallInteger, String, Time
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class MedicationSchedule(Base):
    __tablename__ = "medication_schedule"

    plan_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("medication_plan.id", ondelete="CASCADE"))
    time_of_day: Mapped[time] = mapped_column(Time)
    label: Mapped[str | None] = mapped_column(String(50))
    sort_order: Mapped[int] = mapped_column(SmallInteger, default=0)

    # 关系
    plan: Mapped["MedicationPlan"] = relationship(back_populates="schedules")


from app.models.medication_plan import MedicationPlan  # noqa: E402, F811
