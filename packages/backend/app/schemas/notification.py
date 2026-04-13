"""站内消息的请求/响应模型。"""
import uuid
from datetime import datetime

from pydantic import BaseModel


class NotificationOut(BaseModel):
    id: uuid.UUID
    title: str
    body: str
    type: str
    isRead: bool
    createdAt: datetime


class UnreadCount(BaseModel):
    count: int
