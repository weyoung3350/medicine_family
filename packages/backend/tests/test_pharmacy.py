"""附近药店查询测试。"""
import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text

from app.core.config import settings
from app.main import app

client = TestClient(app)
_SUFFIX = uuid.uuid4().hex[:6]


def _register() -> str:
    resp = client.post("/api/v1/auth/register", json={
        "phone": f"1396{_SUFFIX}01", "nickname": "药店用户", "password": "abc123",
    })
    return resp.json()["access_token"]


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture(autouse=True, scope="module")
def cleanup():
    yield
    engine = create_engine(settings.DATABASE_URL_SYNC)
    with engine.begin() as conn:
        conn.execute(text("DELETE FROM \"user\" WHERE phone LIKE :pat"),
                     {"pat": f"1396{_SUFFIX}%"})
    engine.dispose()


def test_nearby_pharmacy():
    token = _register()
    resp = client.get("/api/v1/pharmacy/nearby", params={
        "lng": 120.15, "lat": 30.28,
    }, headers=_auth(token))
    # 高德 API key 可能无效，接受 200 或 502
    assert resp.status_code in (200, 502)
    if resp.status_code == 200:
        assert isinstance(resp.json(), list)


def test_nearby_pharmacy_without_auth():
    resp = client.get("/api/v1/pharmacy/nearby", params={
        "lng": 120.15, "lat": 30.28,
    })
    assert resp.status_code == 401
