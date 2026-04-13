# 批次 6 任务提示词

> 发给 Claude Code 直接执行。  
> 只做这一批，不要提前碰病历、AI、药店等后续模块。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。
> 本批完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入下一批。

## 任务目标

把服药闭环做出来：计划、打卡、提醒、站内消息。

## 任务边界

- 只做服药计划、时间点、打卡、统计、站内消息
- 不接第三方推送
- 不碰病历或 AI
- 不碰药店查询

## 必须保持的约束

- 通知先做站内信，不做短信/邮件/三方推送
- 适老化体验要能在后续页面承接
- 逻辑要简单，便于参赛讲解

## 建议的文件范围

优先创建或修改这些文件：

- `packages/backend/app/models/medication_plan.py`
- `packages/backend/app/models/medication_schedule.py`
- `packages/backend/app/models/medication_log.py`
- `packages/backend/app/models/notification_message.py`
- `packages/backend/app/services/medication_service.py`
- `packages/backend/app/services/scheduler_service.py`
- `packages/backend/app/services/notification_service.py`
- `packages/backend/app/api/routes/medication.py`
- `packages/backend/app/api/routes/notifications.py`
- `packages/backend/app/schemas/medication.py`
- `packages/backend/app/api/router.py`
- `packages/backend/tests/test_medication.py`
- `packages/backend/tests/test_notifications.py`
- `packages/backend/alembic/versions/0004_medication_and_notifications.py`

## 实施要求

1. 先写计划、打卡、站内消息的失败测试
2. 再实现最小计划生成和消息中心
3. 再跑测试确认通过
4. 最后说明为何只做站内信

## 验收标准

- 能生成当天计划
- 能打卡、跳过、漏服
- 能看到站内提醒消息
- 有基础依从性统计

## 执行完后必须给出的内容

- 消息结构
- 提醒入口
- 当前不做哪些推送能力
- Codex 审查结果
