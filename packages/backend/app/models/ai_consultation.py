import uuid

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import ARRAY, JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class AiConsultation(Base):
    __tablename__ = "ai_consultation"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("user.id"))
    family_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("family.id"))
    member_id: Mapped[uuid.UUID | None] = mapped_column()
    type: Mapped[str] = mapped_column(String(30))
    input_text: Mapped[str | None] = mapped_column(Text)
    input_images: Mapped[list[str] | None] = mapped_column(ARRAY(String(500)))
    ai_model: Mapped[str] = mapped_column(String(50), default="qwen-max")
    messages_json: Mapped[dict | None] = mapped_column(JSONB)
    function_calls: Mapped[dict | None] = mapped_column(JSONB)
    result_summary: Mapped[str | None] = mapped_column(Text)
    result_detail: Mapped[dict | None] = mapped_column(JSONB)
