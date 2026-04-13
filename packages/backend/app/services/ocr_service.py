"""药品 OCR 识别服务（调用千问 Vision）。"""
import json
import logging

from fastapi import HTTPException, status
from openai import AsyncOpenAI

from app.core.config import settings
from app.schemas.medicine import OcrResult

logger = logging.getLogger(__name__)

_SYSTEM_PROMPT = """你是药品信息提取助手。从药品包装图片中提取以下字段，返回 JSON：
{
  "name": "药品通用名",
  "brandName": "品牌名",
  "specification": "规格",
  "dosageForm": "剂型",
  "manufacturer": "生产企业",
  "approvalNumber": "批准文号",
  "batchNumber": "批号",
  "expiryDate": "有效期(YYYY-MM-DD)",
  "indications": "适应症/功能主治",
  "contraindications": "禁忌",
  "usageGuide": "用法用量",
  "confidence": 0.0-1.0
}
只返回 JSON，不要其他文字。无法识别的字段填 null。"""


async def recognize(image_url: str) -> OcrResult:
    """调用千问 Vision 识别药品图片。"""
    if not settings.QWEN_API_KEY or settings.QWEN_API_KEY.startswith("your-"):
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            detail="千问 API Key 未配置",
        )

    client = AsyncOpenAI(
        api_key=settings.QWEN_API_KEY,
        base_url=settings.QWEN_BASE_URL,
    )

    try:
        response = await client.chat.completions.create(
            model="qwen-vl-max",
            messages=[
                {"role": "system", "content": _SYSTEM_PROMPT},
                {"role": "user", "content": [
                    {"type": "image_url", "image_url": {"url": image_url}},
                    {"type": "text", "text": "请提取这张药品图片中的信息"},
                ]},
            ],
            temperature=0.1,
        )
        raw = response.choices[0].message.content or "{}"
        # 去掉可能的 markdown 代码块标记
        raw = raw.strip().removeprefix("```json").removesuffix("```").strip()
        data = json.loads(raw)
    except Exception as e:
        logger.error("OCR 调用失败: %s", e)
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, detail=f"OCR 识别失败: {e}")

    confidence = float(data.get("confidence", 0))
    return OcrResult(
        name=data.get("name"),
        brandName=data.get("brandName"),
        specification=data.get("specification"),
        dosageForm=data.get("dosageForm"),
        manufacturer=data.get("manufacturer"),
        approvalNumber=data.get("approvalNumber"),
        batchNumber=data.get("batchNumber"),
        expiryDate=data.get("expiryDate"),
        indications=data.get("indications"),
        contraindications=data.get("contraindications"),
        usageGuide=data.get("usageGuide"),
        confidence=confidence,
        needsReview=confidence < 0.85,
    )
