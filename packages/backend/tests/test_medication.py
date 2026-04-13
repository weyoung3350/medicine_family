"""服药计划、打卡、依从性统计测试。"""
import uuid
from datetime import date

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text

from app.core.config import settings
from app.main import app

client = TestClient(app)
_SUFFIX = uuid.uuid4().hex[:6]


def _phone(n: int) -> str:
    return f"1393{_SUFFIX}{n:02d}"


def _register(n: int) -> str:
    resp = client.post("/api/v1/auth/register", json={
        "phone": _phone(n), "nickname": f"服药用户{n}", "password": "abc123",
    })
    return resp.json()["access_token"]


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def _setup_family_and_medicine(token: str) -> tuple[str, str, str]:
    """创建家庭 + 受抚养成员 + 药品，返回 (family_id, member_id, medicine_id)。"""
    fam = client.post("/api/v1/families", json={"name": f"服药家庭{_SUFFIX}"},
                      headers=_auth(token))
    fid = fam.json()["id"]
    mem = client.post(f"/api/v1/families/{fid}/members", json={
        "displayName": "爷爷", "relationship": "祖父",
    }, headers=_auth(token))
    mid = mem.json()["id"]
    med = client.post(f"/api/v1/families/{fid}/medicines", json={
        "name": "硝苯地平", "unit": "片", "category": "处方药",
    }, headers=_auth(token))
    medid = med.json()["id"]
    return fid, mid, medid


@pytest.fixture(autouse=True, scope="module")
def cleanup():
    yield
    engine = create_engine(settings.DATABASE_URL_SYNC)
    with engine.begin() as conn:
        conn.execute(text("""
            DELETE FROM medication_log WHERE plan_id IN (
                SELECT id FROM medication_plan WHERE member_id IN (
                    SELECT id FROM family_member WHERE family_id IN (
                        SELECT id FROM family WHERE name LIKE :pat)))
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("""
            DELETE FROM medication_schedule WHERE plan_id IN (
                SELECT id FROM medication_plan WHERE member_id IN (
                    SELECT id FROM family_member WHERE family_id IN (
                        SELECT id FROM family WHERE name LIKE :pat)))
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("""
            DELETE FROM medication_plan WHERE member_id IN (
                SELECT id FROM family_member WHERE family_id IN (
                    SELECT id FROM family WHERE name LIKE :pat))
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("""
            DELETE FROM notification WHERE user_id IN (
                SELECT id FROM "user" WHERE phone LIKE :pat)
        """), {"pat": f"1393{_SUFFIX}%"})
        conn.execute(text("""
            DELETE FROM medicine WHERE family_id IN (
                SELECT id FROM family WHERE name LIKE :pat)
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("""
            DELETE FROM health_profile WHERE member_id IN (
                SELECT id FROM family_member WHERE family_id IN (
                    SELECT id FROM family WHERE name LIKE :pat))
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("""
            DELETE FROM family_member WHERE family_id IN (
                SELECT id FROM family WHERE name LIKE :pat)
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("DELETE FROM family WHERE name LIKE :pat"),
                     {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("DELETE FROM \"user\" WHERE phone LIKE :pat"),
                     {"pat": f"1393{_SUFFIX}%"})
    engine.dispose()


# ---------- 创建计划 ----------

def test_create_plan():
    token = _register(1)
    fid, mid, medid = _setup_family_and_medicine(token)
    resp = client.post(f"/api/v1/families/{fid}/members/{mid}/plans", json={
        "medicineId": medid,
        "dosageAmount": 1,
        "dosageUnit": "片",
        "frequencyType": "daily",
        "mealRelation": "after_meal",
        "startDate": date.today().isoformat(),
        "gracePeriodMinutes": 15,
        "schedules": [
            {"timeOfDay": "08:00", "label": "早餐后"},
            {"timeOfDay": "20:00", "label": "晚餐后"},
        ],
    }, headers=_auth(token))
    assert resp.status_code == 200
    body = resp.json()
    assert body["frequencyType"] == "daily"
    assert len(body["schedules"]) == 2


def test_list_plans():
    token = _register(2)
    fid, mid, medid = _setup_family_and_medicine(token)
    client.post(f"/api/v1/families/{fid}/members/{mid}/plans", json={
        "medicineId": medid,
        "dosageAmount": 2,
        "dosageUnit": "粒",
        "frequencyType": "daily",
        "startDate": date.today().isoformat(),
        "schedules": [{"timeOfDay": "09:00", "label": "上午"}],
    }, headers=_auth(token))
    resp = client.get(f"/api/v1/families/{fid}/members/{mid}/plans",
                      headers=_auth(token))
    assert resp.status_code == 200
    assert len(resp.json()) >= 1


# ---------- 今日计划 ----------

def test_today_schedule():
    token = _register(3)
    fid, mid, medid = _setup_family_and_medicine(token)
    client.post(f"/api/v1/families/{fid}/members/{mid}/plans", json={
        "medicineId": medid,
        "dosageAmount": 1,
        "dosageUnit": "片",
        "frequencyType": "daily",
        "startDate": date.today().isoformat(),
        "schedules": [{"timeOfDay": "07:30", "label": "早上"}],
    }, headers=_auth(token))
    resp = client.get(f"/api/v1/families/{fid}/members/{mid}/plans/today",
                      headers=_auth(token))
    assert resp.status_code == 200
    items = resp.json()
    assert len(items) >= 1
    assert items[0]["status"] == "pending"
    assert items[0]["medicineName"] is not None


# ---------- 打卡 ----------

def test_check_in_taken():
    token = _register(4)
    fid, mid, medid = _setup_family_and_medicine(token)
    client.post(f"/api/v1/families/{fid}/members/{mid}/plans", json={
        "medicineId": medid,
        "dosageAmount": 1,
        "dosageUnit": "片",
        "frequencyType": "daily",
        "startDate": date.today().isoformat(),
        "schedules": [{"timeOfDay": "08:00", "label": "早餐后"}],
    }, headers=_auth(token))
    today = client.get(f"/api/v1/families/{fid}/members/{mid}/plans/today",
                       headers=_auth(token))
    item = today.json()[0]
    resp = client.post(
        f"/api/v1/families/{fid}/members/{mid}/plans/{item['planId']}"
        f"/schedules/{item['scheduleId']}/check-in",
        json={"status": "taken"},
        headers=_auth(token),
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "taken"


def test_check_in_skipped():
    token = _register(5)
    fid, mid, medid = _setup_family_and_medicine(token)
    client.post(f"/api/v1/families/{fid}/members/{mid}/plans", json={
        "medicineId": medid,
        "dosageAmount": 1,
        "dosageUnit": "片",
        "frequencyType": "daily",
        "startDate": date.today().isoformat(),
        "schedules": [{"timeOfDay": "08:00", "label": "早上"}],
    }, headers=_auth(token))
    today = client.get(f"/api/v1/families/{fid}/members/{mid}/plans/today",
                       headers=_auth(token))
    item = today.json()[0]
    resp = client.post(
        f"/api/v1/families/{fid}/members/{mid}/plans/{item['planId']}"
        f"/schedules/{item['scheduleId']}/check-in",
        json={"status": "skipped", "skipReason": "不舒服"},
        headers=_auth(token),
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "skipped"
    assert resp.json()["skipReason"] == "不舒服"


# ---------- 依从性统计 ----------

def test_adherence_stats():
    token = _register(6)
    fid, mid, medid = _setup_family_and_medicine(token)
    # 创建计划并打卡
    client.post(f"/api/v1/families/{fid}/members/{mid}/plans", json={
        "medicineId": medid,
        "dosageAmount": 1,
        "dosageUnit": "片",
        "frequencyType": "daily",
        "startDate": date.today().isoformat(),
        "schedules": [{"timeOfDay": "10:00", "label": "上午"}],
    }, headers=_auth(token))
    today = client.get(f"/api/v1/families/{fid}/members/{mid}/plans/today",
                       headers=_auth(token))
    item = today.json()[0]
    client.post(
        f"/api/v1/families/{fid}/members/{mid}/plans/{item['planId']}"
        f"/schedules/{item['scheduleId']}/check-in",
        json={"status": "taken"},
        headers=_auth(token),
    )
    resp = client.get(f"/api/v1/families/{fid}/members/{mid}/plans/adherence",
                      params={"range": "week"}, headers=_auth(token))
    assert resp.status_code == 200
    stats = resp.json()
    assert "total" in stats
    assert "taken" in stats
    assert "adherenceRate" in stats
