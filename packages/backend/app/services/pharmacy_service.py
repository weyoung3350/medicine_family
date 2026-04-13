"""附近药店搜索服务（高德地图 API）。"""
import logging

import httpx
from fastapi import HTTPException, status

from app.core.config import settings

logger = logging.getLogger(__name__)
AMAP_SEARCH_URL = "https://restapi.amap.com/v3/place/around"
PHARMACY_TYPES = "090601|090602|090603"


async def search_nearby(
    lng: float, lat: float,
    radius: int = 3000, keyword: str | None = None,
) -> list[dict]:
    if not settings.AMAP_API_KEY:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, detail="高德地图 API Key 未配置")

    params = {
        "key": settings.AMAP_API_KEY,
        "location": f"{lng},{lat}",
        "radius": str(radius),
        "types": PHARMACY_TYPES,
        "output": "json",
        "offset": "20",
    }
    if keyword:
        params["keywords"] = keyword

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(AMAP_SEARCH_URL, params=params)
            data = resp.json()
    except Exception as e:
        logger.error("高德 API 调用失败: %s", e)
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, detail=f"药店查询失败: {e}")

    if data.get("status") != "1":
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, detail=data.get("info", "查询失败"))

    return [
        {
            "name": poi.get("name"),
            "address": poi.get("address"),
            "tel": poi.get("tel"),
            "distance": poi.get("distance"),
            "location": poi.get("location"),
        }
        for poi in data.get("pois", [])
    ]
