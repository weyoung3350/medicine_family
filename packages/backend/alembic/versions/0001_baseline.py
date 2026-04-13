"""baseline

Revision ID: 0001
Revises: 
Create Date: 2026-04-12 23:07:17.289687

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0001'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """基线版本：user 表已由 TypeORM 创建，此处仅作标记。"""


def downgrade() -> None:
    pass
