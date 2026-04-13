import uuid

from sqlalchemy import Date, ForeignKey, Integer, SmallInteger, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class MedicineInventory(Base):
    __tablename__ = "medicine_inventory"

    medicine_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("medicine.id"))
    batch_number: Mapped[str | None] = mapped_column(String(100))
    expiry_date: Mapped[str | None] = mapped_column(Date)
    total_quantity: Mapped[int] = mapped_column(Integer)
    remaining_qty: Mapped[int] = mapped_column(Integer)
    low_threshold: Mapped[int] = mapped_column(Integer, default=5)
    status: Mapped[int] = mapped_column(SmallInteger, default=1)  # 1正常 2临期 3过期 4用完
    purchased_at: Mapped[str | None] = mapped_column(Date)

    # 关系
    medicine: Mapped["Medicine"] = relationship(back_populates="inventories")


from app.models.medicine import Medicine  # noqa: E402, F811
