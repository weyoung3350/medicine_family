"""附近药店查询路由。"""
from fastapi import APIRouter, Depends, Query

from app.core.deps import get_current_user
from app.models.user import User
from app.services import pharmacy_service

router = APIRouter(prefix="/pharmacy", tags=["药店"])


@router.get("/nearby")
async def nearby(
    lng: float = Query(...),
    lat: float = Query(...),
    radius: int = Query(3000),
    keyword: str | None = Query(None),
    user: User = Depends(get_current_user),
):
    return await pharmacy_service.search_nearby(lng, lat, radius, keyword)
