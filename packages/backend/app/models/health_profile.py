import uuid
from datetime import datetime

from sqlalchemy import Date, DateTime, ForeignKey, Numeric, SmallInteger, String, Text, func
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class HealthProfile(Base):
    """健康档案。对应现有 health_profile 表（TypeORM 创建）。"""
    __tablename__ = "health_profile"

    member_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("family_member.id"), unique=True,
    )
    birth_date: Mapped[str | None] = mapped_column(Date)
    gender: Mapped[int | None] = mapped_column(SmallInteger)     # 1=男, 2=女
    height_cm: Mapped[float | None] = mapped_column(Numeric(5, 1))
    weight_kg: Mapped[float | None] = mapped_column(Numeric(5, 1))
    blood_type: Mapped[str | None] = mapped_column(String(10))
    medical_history: Mapped[list[str] | None] = mapped_column(ARRAY(Text), default=list)
    allergy_list: Mapped[list[str] | None] = mapped_column(ARRAY(Text), default=list)
    chronic_meds: Mapped[list[str] | None] = mapped_column(ARRAY(Text), default=list)
    notes: Mapped[str | None] = mapped_column(Text)

    # 关系
    member: Mapped["FamilyMember"] = relationship(back_populates="health_profile")


from app.models.family_member import FamilyMember  # noqa: E402, F811
