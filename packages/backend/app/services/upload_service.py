"""文件上传服务。"""
import os
import uuid

import aiofiles
from fastapi import HTTPException, UploadFile, status

from app.core.config import settings

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_SIZE = 10 * 1024 * 1024  # 10 MB


async def save_image(file: UploadFile) -> str:
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="仅支持 jpg/png/webp 图片")

    ext = os.path.splitext(file.filename or "file.png")[1] or ".png"
    filename = f"{uuid.uuid4().hex}{ext}"

    upload_dir = settings.UPLOAD_DIR
    os.makedirs(upload_dir, exist_ok=True)
    filepath = os.path.join(upload_dir, filename)

    content = await file.read()
    if len(content) > MAX_SIZE:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="文件大小超过 10MB 限制")

    async with aiofiles.open(filepath, "wb") as f:
        await f.write(content)

    return f"/uploads/{filename}"
