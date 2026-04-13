"""认证接口测试：注册、登录、获取当前用户。"""
import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text

from app.core.config import settings
from app.main import app

client = TestClient(app)

# 每次测试用唯一后缀，避免与真实数据或其它测试冲突
_SUFFIX = uuid.uuid4().hex[:6]


def _phone(n: int) -> str:
    return f"1390{_SUFFIX}{n:02d}"


@pytest.fixture(autouse=True, scope="module")
def cleanup():
    """测试结束后清理本轮插入的用户。"""
    yield
    engine = create_engine(settings.DATABASE_URL_SYNC)
    with engine.begin() as conn:
        conn.execute(text("DELETE FROM \"user\" WHERE phone LIKE :pat"), {"pat": f"1390{_SUFFIX}%"})
    engine.dispose()


# ---------- 注册 ----------

def test_register_success():
    resp = client.post("/api/v1/auth/register", json={
        "phone": _phone(1),
        "nickname": "测试用户",
        "password": "abc123",
    })
    assert resp.status_code == 200
    body = resp.json()
    assert "access_token" in body
    assert body["user"]["phone"] == _phone(1)
    assert body["user"]["nickname"] == "测试用户"
    assert "password_hash" not in body["user"]


def test_register_duplicate_phone():
    phone = _phone(2)
    client.post("/api/v1/auth/register", json={
        "phone": phone, "nickname": "先注册", "password": "abc123",
    })
    resp = client.post("/api/v1/auth/register", json={
        "phone": phone, "nickname": "重复", "password": "abc123",
    })
    assert resp.status_code == 400


def test_register_missing_fields():
    resp = client.post("/api/v1/auth/register", json={
        "phone": _phone(3),
    })
    assert resp.status_code == 422


# ---------- 登录 ----------

def test_login_with_phone():
    phone = _phone(10)
    client.post("/api/v1/auth/register", json={
        "phone": phone, "nickname": "登录测试", "password": "mypass",
    })
    resp = client.post("/api/v1/auth/login", json={
        "account": phone, "password": "mypass",
    })
    assert resp.status_code == 200
    body = resp.json()
    assert "access_token" in body
    assert body["user"]["phone"] == phone


def test_login_with_email():
    phone = _phone(12)
    email = f"test_{_SUFFIX}@example.com"
    client.post("/api/v1/auth/register", json={
        "phone": phone, "nickname": "邮箱登录测试", "password": "mypass", "email": email,
    })
    resp = client.post("/api/v1/auth/login", json={
        "account": email, "password": "mypass",
    })
    assert resp.status_code == 200
    assert resp.json()["user"]["email"] == email


def test_login_wrong_password():
    phone = _phone(11)
    client.post("/api/v1/auth/register", json={
        "phone": phone, "nickname": "密码错误测试", "password": "right",
    })
    resp = client.post("/api/v1/auth/login", json={
        "account": phone, "password": "wrong",
    })
    assert resp.status_code == 401


def test_login_nonexistent_user():
    resp = client.post("/api/v1/auth/login", json={
        "account": "19999999999", "password": "whatever",
    })
    assert resp.status_code == 401


# ---------- 当前用户 ----------

def test_profile_with_valid_token():
    phone = _phone(20)
    reg = client.post("/api/v1/auth/register", json={
        "phone": phone, "nickname": "查询测试", "password": "abc123",
    })
    token = reg.json()["access_token"]
    resp = client.get("/api/v1/auth/profile", headers={
        "Authorization": f"Bearer {token}",
    })
    assert resp.status_code == 200
    assert resp.json()["phone"] == phone


def test_profile_without_token():
    resp = client.get("/api/v1/auth/profile")
    assert resp.status_code == 401


def test_profile_with_invalid_token():
    resp = client.get("/api/v1/auth/profile", headers={
        "Authorization": "Bearer invalid.token.here",
    })
    assert resp.status_code == 401
