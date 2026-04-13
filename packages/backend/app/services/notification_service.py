"""站内消息服务。"""
import uuid

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification
from app.schemas.notification import NotificationOut, UnreadCount


async def create(
    user_id: uuid.UUID, title: str, body: str,
    msg_type: str, db: AsyncSession,
    related_id: uuid.UUID | None = None,
) -> None:
    """写入一条站内消息。"""
    n = Notification(
        user_id=user_id, title=title, body=body,
        type=msg_type, related_id=related_id,
    )
    db.add(n)
    await db.commit()


async def list_messages(user_id: uuid.UUID, db: AsyncSession) -> list[NotificationOut]:
    result = await db.scalars(
        select(Notification)
        .where(Notification.user_id == user_id)
        .order_by(Notification.created_at.desc())
        .limit(50)
    )
    return [
        NotificationOut(
            id=n.id, title=n.title, body=n.body,
            type=n.type, isRead=n.is_read, createdAt=n.created_at,
        )
        for n in result
    ]


async def unread_count(user_id: uuid.UUID, db: AsyncSession) -> UnreadCount:
    count = await db.scalar(
        select(func.count()).select_from(Notification).where(
            Notification.user_id == user_id,
            Notification.is_read.is_(False),
        )
    )
    return UnreadCount(count=count or 0)


async def mark_read(notification_id: uuid.UUID, user_id: uuid.UUID, db: AsyncSession) -> None:
    await db.execute(
        update(Notification)
        .where(Notification.id == notification_id, Notification.user_id == user_id)
        .values(is_read=True)
    )
    await db.commit()


async def mark_all_read(user_id: uuid.UUID, db: AsyncSession) -> None:
    await db.execute(
        update(Notification)
        .where(Notification.user_id == user_id, Notification.is_read.is_(False))
        .values(is_read=True)
    )
    await db.commit()
