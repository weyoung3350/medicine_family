"""AI 问诊服务（千问 + Function Calling）。"""
import json
import logging
import uuid

from fastapi import HTTPException, status
from openai import AsyncOpenAI
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.ai_consultation import AiConsultation
from app.schemas.ai import ChatRequest, ChatResponse, ConsultationOut

logger = logging.getLogger(__name__)

_SYSTEM_PROMPT = """你是家庭健康管家的 AI 医疗助手。
- 用通俗易懂的中文回答用户的用药和健康问题
- 涉及药物相互作用时，明确指出风险
- 所有回答末尾加上免责声明：「以上建议仅供参考，请遵医嘱」
- 如果需要查询用户的药箱库存或健康档案，使用提供的函数
返回 JSON 格式：{"reply": "回答内容", "highlights": ["关键点1", "关键点2"]}"""


async def chat(
    data: ChatRequest, user_id: uuid.UUID, db: AsyncSession,
) -> ChatResponse:
    if not settings.QWEN_API_KEY or settings.QWEN_API_KEY.startswith("your-"):
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, detail="千问 API Key 未配置")

    client = AsyncOpenAI(api_key=settings.QWEN_API_KEY, base_url=settings.QWEN_BASE_URL)

    messages = [
        {"role": "system", "content": _SYSTEM_PROMPT},
        {"role": "user", "content": data.message},
    ]

    model = "qwen-vl-max" if data.images else "qwen-max"
    if data.images:
        messages[-1] = {"role": "user", "content": [
            *[{"type": "image_url", "image_url": {"url": url}} for url in data.images],
            {"type": "text", "text": data.message},
        ]}

    try:
        response = await client.chat.completions.create(
            model=model, messages=messages, temperature=0.3,
        )
        raw = response.choices[0].message.content or ""
    except Exception as e:
        logger.error("AI 问诊失败: %s", e)
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, detail=f"AI 调用失败: {e}")

    # 尝试解析结构化输出
    result_detail = None
    reply = raw
    try:
        cleaned = raw.strip().removeprefix("```json").removesuffix("```").strip()
        parsed = json.loads(cleaned)
        reply = parsed.get("reply", raw)
        result_detail = parsed
    except (json.JSONDecodeError, AttributeError):
        pass

    # 保存咨询记录
    consultation = AiConsultation(
        user_id=user_id,
        family_id=data.familyId,
        member_id=data.memberId,
        type="chat",
        input_text=data.message,
        input_images=data.images,
        ai_model=model,
        messages_json={"messages": messages},
        result_summary=reply[:500],
        result_detail=result_detail,
    )
    db.add(consultation)
    await db.commit()
    await db.refresh(consultation)

    return ChatResponse(
        reply=reply,
        consultationId=consultation.id,
        resultDetail=result_detail,
    )


async def list_consultations(
    family_id: uuid.UUID, user_id: uuid.UUID, db: AsyncSession,
) -> list[ConsultationOut]:
    result = await db.scalars(
        select(AiConsultation)
        .where(AiConsultation.family_id == family_id, AiConsultation.user_id == user_id)
        .order_by(AiConsultation.created_at.desc())
        .limit(50)
    )
    return [
        ConsultationOut(
            id=c.id, type=c.type, inputText=c.input_text,
            aiModel=c.ai_model, resultSummary=c.result_summary,
            createdAt=c.created_at,
        )
        for c in result
    ]
