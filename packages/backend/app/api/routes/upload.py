"""文件上传路由。"""
from fastapi import APIRouter, Depends, UploadFile

from app.core.deps import get_current_user
from app.models.user import User
from app.schemas.medicine import UploadResult
from app.services import upload_service

router = APIRouter(prefix="/upload", tags=["上传"])


@router.post("/image", response_model=UploadResult)
async def upload_image(
    file: UploadFile,
    user: User = Depends(get_current_user),
):
    url = await upload_service.save_image(file)
    return UploadResult(url=url)
