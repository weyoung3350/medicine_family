import uuid

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Medicine(Base):
    __tablename__ = "medicine"

    family_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("family.id"))
    name: Mapped[str] = mapped_column(String(200))
    brand_name: Mapped[str | None] = mapped_column(String(200))
    dosage_form: Mapped[str | None] = mapped_column(String(50))
    specification: Mapped[str | None] = mapped_column(String(100))
    unit: Mapped[str] = mapped_column(String(20))
    manufacturer: Mapped[str | None] = mapped_column(String(200))
    approval_number: Mapped[str | None] = mapped_column(String(100))
    category: Mapped[str | None] = mapped_column(String(50))
    indications: Mapped[str | None] = mapped_column(Text)
    contraindications: Mapped[str | None] = mapped_column(Text)
    side_effects: Mapped[str | None] = mapped_column(Text)
    interactions: Mapped[str | None] = mapped_column(Text)
    usage_guide: Mapped[str | None] = mapped_column(Text)
    image_url: Mapped[str | None] = mapped_column(String(500))
    ocr_raw_data: Mapped[dict | None] = mapped_column(JSONB)
    created_by: Mapped[uuid.UUID | None] = mapped_column()

    # 关系
    inventories: Mapped[list["MedicineInventory"]] = relationship(
        back_populates="medicine", cascade="all, delete-orphan",
    )


from app.models.medicine_inventory import MedicineInventory  # noqa: E402, F811
