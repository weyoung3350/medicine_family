"""站内消息测试。"""
import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text

from app.core.config import settings
from app.main import app

client = TestClient(app)
_SUFFIX = uuid.uuid4().hex[:6]


def _phone(n: int) -> str:
    return f"1394{_SUFFIX}{n:02d}"


def _register(n: int) -> str:
    resp = client.post("/api/v1/auth/register", json={
        "phone": _phone(n), "nickname": f"消息用户{n}", "password": "abc123",
    })
    return resp.json()["access_token"]


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def _user_id_from_token(token: str) -> str:
    resp = client.get("/api/v1/auth/profile", headers=_auth(token))
    return resp.json()["id"]


def _insert_notification(user_id: str, title: str) -> str:
    """直接写入一条通知并返回 ID。"""
    engine = create_engine(settings.DATABASE_URL_SYNC)
    nid = str(uuid.uuid4())
    with engine.begin() as conn:
        conn.execute(text("""
            INSERT INTO notification (id, user_id, title, body, type, is_read)
            VALUES (:id, :uid, :title, '测试内容', 'reminder', false)
        """), {"id": nid, "uid": user_id, "title": title})
    engine.dispose()
    return nid


@pytest.fixture(autouse=True, scope="module")
def cleanup():
    yield
    engine = create_engine(settings.DATABASE_URL_SYNC)
    with engine.begin() as conn:
        conn.execute(text("""
            DELETE FROM notification WHERE user_id IN (
                SELECT id FROM "user" WHERE phone LIKE :pat)
        """), {"pat": f"1394{_SUFFIX}%"})
        conn.execute(text("DELETE FROM \"user\" WHERE phone LIKE :pat"),
                     {"pat": f"1394{_SUFFIX}%"})
    engine.dispose()


def test_list_notifications_empty():
    token = _register(1)
    resp = client.get("/api/v1/notifications", headers=_auth(token))
    assert resp.status_code == 200
    assert resp.json() == []


def test_unread_count():
    token = _register(2)
    resp = client.get("/api/v1/notifications/unread-count", headers=_auth(token))
    assert resp.status_code == 200
    assert resp.json()["count"] == 0


def test_list_with_messages():
    token = _register(3)
    uid = _user_id_from_token(token)
    _insert_notification(uid, "服药提醒")
    resp = client.get("/api/v1/notifications", headers=_auth(token))
    assert resp.status_code == 200
    msgs = resp.json()
    assert len(msgs) == 1
    assert msgs[0]["title"] == "服药提醒"
    assert msgs[0]["isRead"] is False


def test_mark_single_read():
    token = _register(4)
    uid = _user_id_from_token(token)
    nid = _insert_notification(uid, "临期提醒")
    # 标记已读
    resp = client.post(f"/api/v1/notifications/{nid}/read", headers=_auth(token))
    assert resp.status_code == 200
    # 验证已读
    count = client.get("/api/v1/notifications/unread-count", headers=_auth(token))
    assert count.json()["count"] == 0


def test_mark_all_read():
    token = _register(5)
    uid = _user_id_from_token(token)
    _insert_notification(uid, "消息1")
    _insert_notification(uid, "消息2")
    # 全部标记已读
    resp = client.post("/api/v1/notifications/read-all", headers=_auth(token))
    assert resp.status_code == 200
    count = client.get("/api/v1/notifications/unread-count", headers=_auth(token))
    assert count.json()["count"] == 0
