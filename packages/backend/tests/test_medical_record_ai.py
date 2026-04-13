"""病历 CRUD、OCR、AI 问诊测试。"""
import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text

from app.core.config import settings
from app.main import app

client = TestClient(app)
_SUFFIX = uuid.uuid4().hex[:6]


def _phone(n: int) -> str:
    return f"1395{_SUFFIX}{n:02d}"


def _register(n: int) -> str:
    resp = client.post("/api/v1/auth/register", json={
        "phone": _phone(n), "nickname": f"AI用户{n}", "password": "abc123",
    })
    return resp.json()["access_token"]


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def _setup(token: str) -> tuple[str, str]:
    """创建家庭 + 成员，返回 (family_id, member_id)。"""
    fam = client.post("/api/v1/families", json={"name": f"AI家庭{_SUFFIX}"},
                      headers=_auth(token))
    fid = fam.json()["id"]
    mem = client.post(f"/api/v1/families/{fid}/members", json={
        "displayName": "本人", "relationship": "自己",
    }, headers=_auth(token))
    mid = mem.json()["id"]
    return fid, mid


@pytest.fixture(autouse=True, scope="module")
def cleanup():
    yield
    engine = create_engine(settings.DATABASE_URL_SYNC)
    with engine.begin() as conn:
        conn.execute(text("""
            DELETE FROM ai_consultation WHERE family_id IN (
                SELECT id FROM family WHERE name LIKE :pat)
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("""
            DELETE FROM medical_record WHERE family_id IN (
                SELECT id FROM family WHERE name LIKE :pat)
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("""
            DELETE FROM family_member WHERE family_id IN (
                SELECT id FROM family WHERE name LIKE :pat)
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("DELETE FROM family WHERE name LIKE :pat"),
                     {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("DELETE FROM \"user\" WHERE phone LIKE :pat"),
                     {"pat": f"1395{_SUFFIX}%"})
    engine.dispose()


# ---------- 病历 CRUD ----------

def test_create_medical_record():
    token = _register(1)
    fid, mid = _setup(token)
    resp = client.post(f"/api/v1/families/{fid}/medical-records", json={
        "memberId": mid,
        "hospital": "北京协和医院",
        "department": "内科",
        "doctor": "张医生",
        "visitDate": "2026-04-01",
        "diagnosis": "上呼吸道感染",
        "chiefComplaint": "咳嗽发热三天",
    }, headers=_auth(token))
    assert resp.status_code == 200
    body = resp.json()
    assert body["hospital"] == "北京协和医院"
    assert body["diagnosis"] == "上呼吸道感染"


def test_list_medical_records():
    token = _register(2)
    fid, mid = _setup(token)
    client.post(f"/api/v1/families/{fid}/medical-records", json={
        "memberId": mid, "hospital": "测试医院", "diagnosis": "感冒",
    }, headers=_auth(token))
    resp = client.get(f"/api/v1/families/{fid}/medical-records",
                      headers=_auth(token))
    assert resp.status_code == 200
    assert len(resp.json()) >= 1


def test_update_medical_record():
    token = _register(3)
    fid, mid = _setup(token)
    create = client.post(f"/api/v1/families/{fid}/medical-records", json={
        "memberId": mid, "hospital": "原医院", "diagnosis": "待修改",
    }, headers=_auth(token))
    rid = create.json()["id"]
    resp = client.put(f"/api/v1/families/{fid}/medical-records/{rid}", json={
        "diagnosis": "已修改为肺炎",
        "doctorAdvice": "多休息",
    }, headers=_auth(token))
    assert resp.status_code == 200
    assert resp.json()["diagnosis"] == "已修改为肺炎"


def test_delete_medical_record():
    token = _register(4)
    fid, mid = _setup(token)
    create = client.post(f"/api/v1/families/{fid}/medical-records", json={
        "memberId": mid, "hospital": "待删医院",
    }, headers=_auth(token))
    rid = create.json()["id"]
    resp = client.delete(f"/api/v1/families/{fid}/medical-records/{rid}",
                         headers=_auth(token))
    assert resp.status_code == 200


# ---------- 病历 OCR ----------

def test_medical_record_ocr():
    token = _register(5)
    fid, _ = _setup(token)
    resp = client.post(f"/api/v1/families/{fid}/medical-records/ocr", json={
        "imageUrl": "https://example.com/fake-record.jpg",
    }, headers=_auth(token))
    assert resp.status_code in (200, 502)
    if resp.status_code == 200:
        body = resp.json()
        assert "hospital" in body
        assert "confidence" in body


# ---------- AI 问诊 ----------

def test_ai_chat():
    token = _register(10)
    fid, mid = _setup(token)
    resp = client.post("/api/v1/ai/chat", json={
        "familyId": fid,
        "memberId": mid,
        "message": "布洛芬和对乙酰氨基酚能一起吃吗？",
    }, headers=_auth(token))
    assert resp.status_code in (200, 502)
    if resp.status_code == 200:
        body = resp.json()
        assert "reply" in body
        assert "consultationId" in body


def test_ai_list_consultations():
    token = _register(11)
    fid, _ = _setup(token)
    resp = client.get("/api/v1/ai/consultations",
                      params={"familyId": fid}, headers=_auth(token))
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)
