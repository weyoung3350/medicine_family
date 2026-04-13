# 批次 7 任务提示词

> 发给 Claude Code 直接执行。  
> 只做这一批，不要提前碰药店、种子、清理等后续模块。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。
> 本批完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入下一批。

## 任务目标

把病历和 AI 做成可展示、可解释、可追溯的模块。

## 任务边界

- 只做病历 CRUD、病历 OCR、AI 问诊、图片分析、历史记录
- 结果要结构化
- 不碰药店
- 不碰种子脚本

## 必须保持的约束

- AI 输出不能只是一段纯文本
- 要能保存咨询历史
- 外部模型调用要能被 mock

## 建议的文件范围

优先创建或修改这些文件：

- `packages/backend/app/models/medical_record.py`
- `packages/backend/app/models/ai_consultation.py`
- `packages/backend/app/services/medical_record_service.py`
- `packages/backend/app/services/medical_record_ocr_service.py`
- `packages/backend/app/services/ai_service.py`
- `packages/backend/app/api/routes/medical_records.py`
- `packages/backend/app/api/routes/ai.py`
- `packages/backend/app/schemas/medical_record.py`
- `packages/backend/app/schemas/ai.py`
- `packages/backend/app/api/router.py`
- `packages/backend/tests/test_medical_record_ai.py`
- `packages/backend/alembic/versions/0005_medical_records_and_ai.py`

## 实施要求

1. 先写病历和 AI 的失败测试
2. 再实现最小 CRUD、OCR、AI 返回结构
3. 再跑测试确认通过
4. 最后说明结构化输出如何给前端渲染

## 验收标准

- 病历可增删改查
- OCR 可返回结构化结果
- AI 会话可保存
- AI 结果可稳定渲染

## 执行完后必须给出的内容

- AI 响应结构
- 历史记录保存方式
- 哪些外部调用可 mock
- Codex 审查结果
