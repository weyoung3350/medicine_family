import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from sqlalchemy.orm import DeclarativeBase
from app.db.base import Base


class Notification(Base):
    """站内消息。新建表，无 updated_at 列。"""
    __tablename__ = "notification"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("user.id"), index=True)
    title: Mapped[str] = mapped_column(String(200))
    body: Mapped[str] = mapped_column(Text)
    type: Mapped[str] = mapped_column(String(50), default="info")
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)
    related_id: Mapped[uuid.UUID | None] = mapped_column()
