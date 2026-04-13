"""病历 OCR 识别服务（调用千问 Vision）。"""
import json
import logging

from fastapi import HTTPException, status
from openai import AsyncOpenAI

from app.core.config import settings
from app.schemas.medical_record import MedicalOcrResult

logger = logging.getLogger(__name__)

_SYSTEM_PROMPT = """你是病历信息提取助手。从医院诊疗单/病历图片中提取以下字段，返回 JSON：
{
  "hospital": "医院名称",
  "department": "科室",
  "doctor": "医生姓名",
  "visitDate": "就诊日期(YYYY-MM-DD)",
  "diagnosis": "诊断",
  "chiefComplaint": "主诉",
  "presentIllness": "现病史",
  "prescriptions": [{"name":"药名","dosage":"用量","usage":"用法"}],
  "examinations": "检查项目",
  "doctorAdvice": "医嘱",
  "confidence": 0.0-1.0
}
只返回 JSON，不要其他文字。无法识别的字段填 null。"""


async def recognize(image_url: str) -> MedicalOcrResult:
    if not settings.QWEN_API_KEY or settings.QWEN_API_KEY.startswith("your-"):
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, detail="千问 API Key 未配置")

    client = AsyncOpenAI(api_key=settings.QWEN_API_KEY, base_url=settings.QWEN_BASE_URL)
    try:
        response = await client.chat.completions.create(
            model="qwen-vl-max",
            messages=[
                {"role": "system", "content": _SYSTEM_PROMPT},
                {"role": "user", "content": [
                    {"type": "image_url", "image_url": {"url": image_url}},
                    {"type": "text", "text": "请提取这张病历图片中的信息"},
                ]},
            ],
            temperature=0.1,
        )
        raw = response.choices[0].message.content or "{}"
        raw = raw.strip().removeprefix("```json").removesuffix("```").strip()
        data = json.loads(raw)
    except Exception as e:
        logger.error("病历 OCR 失败: %s", e)
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, detail=f"OCR 识别失败: {e}")

    confidence = float(data.get("confidence", 0))
    return MedicalOcrResult(
        hospital=data.get("hospital"),
        department=data.get("department"),
        doctor=data.get("doctor"),
        visitDate=data.get("visitDate"),
        diagnosis=data.get("diagnosis"),
        chiefComplaint=data.get("chiefComplaint"),
        presentIllness=data.get("presentIllness"),
        prescriptions=data.get("prescriptions"),
        examinations=data.get("examinations"),
        doctorAdvice=data.get("doctorAdvice"),
        confidence=confidence,
        needsReview=confidence < 0.85,
    )
