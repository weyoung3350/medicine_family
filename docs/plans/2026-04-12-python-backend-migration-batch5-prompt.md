# 批次 5 任务提示词

> 发给 Claude Code 直接执行。  
> 只做这一批，不要提前碰服药计划、消息中心、AI 等后续模块。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。
> 本批完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入下一批。

## 任务目标

完成药箱管理主干：药品、库存、OCR、上传。

## 任务边界

- 只做药品 CRUD、库存、OCR、文件上传
- 不要做服药计划
- 不要做站内消息
- 不要做 AI

## 必须保持的约束

- 结果要便于前端直接渲染
- OCR 结果必须允许人工确认
- 库存状态计算要明确

## 建议的文件范围

优先创建或修改这些文件：

- `packages/backend/app/models/medicine.py`
- `packages/backend/app/models/medicine_inventory.py`
- `packages/backend/app/services/medicine_service.py`
- `packages/backend/app/services/inventory_service.py`
- `packages/backend/app/services/ocr_service.py`
- `packages/backend/app/services/upload_service.py`
- `packages/backend/app/api/routes/medicine.py`
- `packages/backend/app/api/routes/upload.py`
- `packages/backend/app/schemas/medicine.py`
- `packages/backend/app/api/router.py`
- `packages/backend/tests/test_medicine.py`
- `packages/backend/alembic/versions/0003_medicine_and_inventory.py`

## 实施要求

1. 先写药品和库存相关失败测试
2. 再实现最小 CRUD、OCR、上传
3. 再跑测试确认通过
4. 最后说明库存状态和 OCR 结构

## 验收标准

- 能录入和查询药品
- 能维护库存
- 能判断低库存和临期
- OCR 可返回结构化结果

## 执行完后必须给出的内容

- OCR 输出格式
- 人工确认入口
- 库存状态如何计算
- Codex 审查结果
