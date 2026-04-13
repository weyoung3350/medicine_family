import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

from app.db.base import Base


class FamilyMember(Base):
    """家庭成员。对应现有 family_member 表（TypeORM 创建）。"""
    __tablename__ = "family_member"

    family_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("family.id"))
    user_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("user.id"))
    managed_by: Mapped[uuid.UUID | None] = mapped_column()
    role: Mapped[str] = mapped_column(String(20), default="member")
    display_name: Mapped[str] = mapped_column(String(50))
    # 数据库列名是 "relationship"，但 Python 中不能用这个名字
    relationship_label: Mapped[str | None] = mapped_column(
        "relationship", String(30),
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    joined_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(),
    )

    # 关系
    family: Mapped["Family"] = relationship(back_populates="members")
    user: Mapped["User | None"] = relationship(foreign_keys=[user_id])
    health_profile: Mapped["HealthProfile | None"] = relationship(
        back_populates="member", uselist=False, cascade="all, delete-orphan",
    )


from app.models.family import Family  # noqa: E402, F811
from app.models.user import User  # noqa: E402, F811
from app.models.health_profile import HealthProfile  # noqa: E402, F811
