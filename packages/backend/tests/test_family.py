"""家庭、成员、健康档案接口测试。"""
import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text

from app.core.config import settings
from app.main import app

client = TestClient(app)
_SUFFIX = uuid.uuid4().hex[:6]


def _phone(n: int) -> str:
    return f"1391{_SUFFIX}{n:02d}"


def _register(n: int) -> str:
    """注册用户并返回 token。"""
    resp = client.post("/api/v1/auth/register", json={
        "phone": _phone(n), "nickname": f"用户{n}", "password": "abc123",
    })
    return resp.json()["access_token"]


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture(autouse=True, scope="module")
def cleanup():
    yield
    engine = create_engine(settings.DATABASE_URL_SYNC)
    with engine.begin() as conn:
        # 先删依赖表再删主表
        conn.execute(text("""
            DELETE FROM health_profile WHERE member_id IN (
                SELECT id FROM family_member WHERE family_id IN (
                    SELECT id FROM family WHERE name LIKE :pat
                )
            )
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("""
            DELETE FROM family_member WHERE family_id IN (
                SELECT id FROM family WHERE name LIKE :pat
            )
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("DELETE FROM family WHERE name LIKE :pat"), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("DELETE FROM \"user\" WHERE phone LIKE :pat"), {"pat": f"1391{_SUFFIX}%"})
    engine.dispose()


# ---------- 创建家庭 ----------

def test_create_family():
    token = _register(1)
    resp = client.post("/api/v1/families", json={"name": f"王家{_SUFFIX}"},
                       headers=_auth(token))
    assert resp.status_code == 200
    body = resp.json()
    assert body["name"] == f"王家{_SUFFIX}"
    assert len(body["inviteCode"]) == 8
    assert body["myRole"] == "owner"


def test_create_family_without_auth():
    resp = client.post("/api/v1/families", json={"name": "无权限"})
    assert resp.status_code == 401


# ---------- 列表 ----------

def test_list_families():
    token = _register(2)
    client.post("/api/v1/families", json={"name": f"李家{_SUFFIX}"},
                headers=_auth(token))
    resp = client.get("/api/v1/families", headers=_auth(token))
    assert resp.status_code == 200
    families = resp.json()
    assert any(f["name"] == f"李家{_SUFFIX}" for f in families)


# ---------- 加入家庭 ----------

def test_join_family():
    token_owner = _register(10)
    token_joiner = _register(11)
    # 创建家庭
    create_resp = client.post("/api/v1/families", json={"name": f"张家{_SUFFIX}"},
                              headers=_auth(token_owner))
    invite_code = create_resp.json()["inviteCode"]
    # 加入
    resp = client.post("/api/v1/families/join", json={"inviteCode": invite_code},
                       headers=_auth(token_joiner))
    assert resp.status_code == 200
    assert resp.json()["name"] == f"张家{_SUFFIX}"


def test_join_family_duplicate():
    token_owner = _register(12)
    token_joiner = _register(13)
    create_resp = client.post("/api/v1/families", json={"name": f"赵家{_SUFFIX}"},
                              headers=_auth(token_owner))
    invite_code = create_resp.json()["inviteCode"]
    client.post("/api/v1/families/join", json={"inviteCode": invite_code},
                headers=_auth(token_joiner))
    resp = client.post("/api/v1/families/join", json={"inviteCode": invite_code},
                       headers=_auth(token_joiner))
    assert resp.status_code == 400


# ---------- 成员 ----------

def test_list_members():
    token = _register(20)
    create_resp = client.post("/api/v1/families", json={"name": f"刘家{_SUFFIX}"},
                              headers=_auth(token))
    family_id = create_resp.json()["id"]
    resp = client.get(f"/api/v1/families/{family_id}/members", headers=_auth(token))
    assert resp.status_code == 200
    members = resp.json()
    # 创建者自己应该是一个成员
    assert len(members) >= 1
    assert members[0]["role"] == "owner"


def test_add_dependent():
    token = _register(21)
    create_resp = client.post("/api/v1/families", json={"name": f"陈家{_SUFFIX}"},
                              headers=_auth(token))
    family_id = create_resp.json()["id"]
    resp = client.post(f"/api/v1/families/{family_id}/members", json={
        "displayName": "奶奶",
        "relationship": "祖母",
        "healthProfile": {
            "birthDate": "1945-03-15",
            "gender": 2,
            "medicalHistory": ["高血压", "糖尿病"],
            "allergyList": ["青霉素"],
        },
    }, headers=_auth(token))
    assert resp.status_code == 200
    body = resp.json()
    assert body["displayName"] == "奶奶"
    assert body["relationship"] == "祖母"
    assert body["role"] == "dependent"


# ---------- 健康档案 ----------

def test_get_health_profile():
    token = _register(30)
    create_resp = client.post("/api/v1/families", json={"name": f"吴家{_SUFFIX}"},
                              headers=_auth(token))
    family_id = create_resp.json()["id"]
    # 添加受抚养人
    member_resp = client.post(f"/api/v1/families/{family_id}/members", json={
        "displayName": "爷爷",
        "relationship": "祖父",
        "healthProfile": {
            "birthDate": "1940-01-01",
            "gender": 1,
            "medicalHistory": ["冠心病"],
            "allergyList": [],
        },
    }, headers=_auth(token))
    member_id = member_resp.json()["id"]
    # 获取健康档案
    resp = client.get(f"/api/v1/families/{family_id}/members/{member_id}/health",
                      headers=_auth(token))
    assert resp.status_code == 200
    hp = resp.json()
    assert hp["birthDate"] == "1940-01-01"
    assert hp["gender"] == 1
    assert "冠心病" in hp["medicalHistory"]


def test_update_health_profile():
    token = _register(31)
    create_resp = client.post("/api/v1/families", json={"name": f"周家{_SUFFIX}"},
                              headers=_auth(token))
    family_id = create_resp.json()["id"]
    member_resp = client.post(f"/api/v1/families/{family_id}/members", json={
        "displayName": "外婆",
        "relationship": "外祖母",
    }, headers=_auth(token))
    member_id = member_resp.json()["id"]
    # 更新健康档案
    resp = client.put(f"/api/v1/families/{family_id}/members/{member_id}/health",
                      json={
                          "birthDate": "1948-06-20",
                          "gender": 2,
                          "heightCm": 155,
                          "weightKg": 58.5,
                          "bloodType": "A",
                          "medicalHistory": ["高血脂"],
                          "allergyList": ["磺胺类"],
                          "chronicMeds": ["阿托伐他汀"],
                          "notes": "需定期复查血脂",
                      }, headers=_auth(token))
    assert resp.status_code == 200
    hp = resp.json()
    assert hp["heightCm"] == 155
    assert hp["weightKg"] == 58.5
    assert hp["bloodType"] == "A"
    assert "阿托伐他汀" in hp["chronicMeds"]
