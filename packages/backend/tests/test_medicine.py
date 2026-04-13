"""药品、库存、OCR 接口测试。"""
import uuid
from datetime import date, timedelta

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text

from app.core.config import settings
from app.main import app

client = TestClient(app)
_SUFFIX = uuid.uuid4().hex[:6]


def _phone(n: int) -> str:
    return f"1392{_SUFFIX}{n:02d}"


def _register(n: int) -> str:
    resp = client.post("/api/v1/auth/register", json={
        "phone": _phone(n), "nickname": f"药品用户{n}", "password": "abc123",
    })
    return resp.json()["access_token"]


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def _create_family(token: str) -> str:
    resp = client.post("/api/v1/families", json={"name": f"药品家庭{_SUFFIX}"},
                       headers=_auth(token))
    return resp.json()["id"]


@pytest.fixture(autouse=True, scope="module")
def cleanup():
    yield
    engine = create_engine(settings.DATABASE_URL_SYNC)
    with engine.begin() as conn:
        conn.execute(text("""
            DELETE FROM medicine_inventory WHERE medicine_id IN (
                SELECT id FROM medicine WHERE family_id IN (
                    SELECT id FROM family WHERE name LIKE :pat))
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("""
            DELETE FROM medicine WHERE family_id IN (
                SELECT id FROM family WHERE name LIKE :pat)
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("""
            DELETE FROM family_member WHERE family_id IN (
                SELECT id FROM family WHERE name LIKE :pat)
        """), {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("DELETE FROM family WHERE name LIKE :pat"),
                     {"pat": f"%{_SUFFIX}%"})
        conn.execute(text("DELETE FROM \"user\" WHERE phone LIKE :pat"),
                     {"pat": f"1392{_SUFFIX}%"})
    engine.dispose()


# ---------- 药品 CRUD ----------

def test_create_medicine():
    token = _register(1)
    fid = _create_family(token)
    resp = client.post(f"/api/v1/families/{fid}/medicines", json={
        "name": "布洛芬",
        "brandName": "芬必得",
        "unit": "粒",
        "category": "OTC",
        "specification": "0.3g*24粒",
        "dosageForm": "胶囊",
        "manufacturer": "中美天津史克",
        "indications": "用于缓解轻至中度疼痛",
    }, headers=_auth(token))
    assert resp.status_code == 200
    body = resp.json()
    assert body["name"] == "布洛芬"
    assert body["brandName"] == "芬必得"
    assert body["unit"] == "粒"


def test_list_medicines():
    token = _register(2)
    fid = _create_family(token)
    client.post(f"/api/v1/families/{fid}/medicines", json={
        "name": "阿莫西林", "unit": "粒", "category": "处方药",
    }, headers=_auth(token))
    client.post(f"/api/v1/families/{fid}/medicines", json={
        "name": "维生素C", "unit": "片", "category": "保健品",
    }, headers=_auth(token))
    resp = client.get(f"/api/v1/families/{fid}/medicines", headers=_auth(token))
    assert resp.status_code == 200
    assert len(resp.json()) >= 2


def test_search_medicines_by_keyword():
    token = _register(3)
    fid = _create_family(token)
    client.post(f"/api/v1/families/{fid}/medicines", json={
        "name": "对乙酰氨基酚", "unit": "片",
    }, headers=_auth(token))
    resp = client.get(f"/api/v1/families/{fid}/medicines",
                      params={"keyword": "氨基酚"}, headers=_auth(token))
    assert resp.status_code == 200
    assert any("氨基酚" in m["name"] for m in resp.json())


def test_get_medicine_detail():
    token = _register(4)
    fid = _create_family(token)
    create = client.post(f"/api/v1/families/{fid}/medicines", json={
        "name": "复方甘草片", "unit": "片",
    }, headers=_auth(token))
    mid = create.json()["id"]
    resp = client.get(f"/api/v1/families/{fid}/medicines/{mid}",
                      headers=_auth(token))
    assert resp.status_code == 200
    assert resp.json()["name"] == "复方甘草片"


# ---------- 库存 ----------

def test_add_inventory():
    token = _register(10)
    fid = _create_family(token)
    create = client.post(f"/api/v1/families/{fid}/medicines", json={
        "name": "头孢克肟", "unit": "粒",
    }, headers=_auth(token))
    mid = create.json()["id"]
    resp = client.post(f"/api/v1/families/{fid}/medicines/{mid}/inventory", json={
        "totalQuantity": 30,
        "batchNumber": "BN202601",
        "expiryDate": "2027-06-01",
        "lowThreshold": 5,
    }, headers=_auth(token))
    assert resp.status_code == 200
    inv = resp.json()
    assert inv["totalQuantity"] == 30
    assert inv["remainingQty"] == 30
    assert inv["status"] == 1


def test_low_stock():
    token = _register(11)
    fid = _create_family(token)
    create = client.post(f"/api/v1/families/{fid}/medicines", json={
        "name": "低库存药", "unit": "粒",
    }, headers=_auth(token))
    mid = create.json()["id"]
    # 添加库存，总量=3，阈值=5 → 低库存
    client.post(f"/api/v1/families/{fid}/medicines/{mid}/inventory", json={
        "totalQuantity": 3, "lowThreshold": 5,
    }, headers=_auth(token))
    resp = client.get(f"/api/v1/families/{fid}/medicines/low-stock",
                      headers=_auth(token))
    assert resp.status_code == 200
    assert any(m["name"] == "低库存药" for m in resp.json())


def test_expiring():
    token = _register(12)
    fid = _create_family(token)
    create = client.post(f"/api/v1/families/{fid}/medicines", json={
        "name": "临期药品", "unit": "片",
    }, headers=_auth(token))
    mid = create.json()["id"]
    soon = (date.today() + timedelta(days=15)).isoformat()
    client.post(f"/api/v1/families/{fid}/medicines/{mid}/inventory", json={
        "totalQuantity": 10, "expiryDate": soon, "lowThreshold": 3,
    }, headers=_auth(token))
    resp = client.get(f"/api/v1/families/{fid}/medicines/expiring",
                      headers=_auth(token))
    assert resp.status_code == 200
    assert any(m["name"] == "临期药品" for m in resp.json())


# ---------- 文件上传 ----------

def test_upload_image():
    token = _register(20)
    # 构造一个最小 PNG (1x1 像素)
    import io
    png = (b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01"
           b"\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00"
           b"\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00"
           b"\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82")
    resp = client.post("/api/v1/upload/image",
                       files={"file": ("test.png", io.BytesIO(png), "image/png")},
                       headers=_auth(token))
    assert resp.status_code == 200
    assert "url" in resp.json()


# ---------- OCR ----------

def test_ocr_returns_structure():
    """OCR 端点应返回结构化结果（实际 AI 调用被 mock，这里测路由可达）。"""
    token = _register(21)
    fid = _create_family(token)
    resp = client.post(f"/api/v1/families/{fid}/medicines/ocr", json={
        "imageUrl": "https://example.com/fake.jpg",
    }, headers=_auth(token))
    # OCR 依赖外部 AI，可能返回 200（mock）或 502（真实调不通）
    assert resp.status_code in (200, 502)
    if resp.status_code == 200:
        body = resp.json()
        assert "name" in body
        assert "confidence" in body
