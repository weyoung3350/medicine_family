import random
import string
import uuid

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


def _generate_invite_code(length: int = 8) -> str:
    chars = string.ascii_uppercase + string.digits
    chars = chars.translate(str.maketrans("", "", "IO10"))
    return "".join(random.choices(chars, k=length))


class Family(Base):
    __tablename__ = "family"

    name: Mapped[str] = mapped_column(String(100))
    invite_code: Mapped[str] = mapped_column(
        String(8), unique=True, index=True, default=_generate_invite_code,
    )
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("user.id"))

    # 关系
    members: Mapped[list["FamilyMember"]] = relationship(
        back_populates="family", cascade="all, delete-orphan",
    )


from app.models.family_member import FamilyMember  # noqa: E402, F811
