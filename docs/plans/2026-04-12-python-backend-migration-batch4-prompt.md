# 批次 4 任务提示词

> 发给 Claude Code 直接执行。  
> 只做这一批，不要提前碰药品、计划、AI 等后续模块。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。
> 本批完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入下一批。

## 任务目标

把家庭主线跑通：家庭、成员、健康档案。

## 任务边界

- 只做家庭创建、加入、列表、成员、健康档案
- 必须包含 `relationship`
- 不要碰药品或服药计划
- 不要碰 AI

## 必须保持的约束

- 家庭相关接口要和当前 Web 端思路一致
- 健康档案结构要清楚，适合讲解
- 默认种子行为如要保留，需说明

## 建议的文件范围

优先创建或修改这些文件：

- `packages/backend/app/models/family.py`
- `packages/backend/app/models/family_member.py`
- `packages/backend/app/models/health_profile.py`
- `packages/backend/app/services/family_service.py`
- `packages/backend/app/api/routes/family.py`
- `packages/backend/app/api/routes/members.py`
- `packages/backend/app/schemas/family.py`
- `packages/backend/app/api/router.py`
- `packages/backend/tests/test_family.py`
- `packages/backend/alembic/versions/0002_family_and_health.py`

## 实施要求

1. 先写家庭与健康档案的失败测试
2. 再实现最小家庭服务
3. 再跑测试确认通过
4. 再说明 `relationship` 的处理方式

## 验收标准

- 能创建家庭
- 能加入家庭
- 能新增成员
- 能读写健康档案
- `relationship` 有落库和返回

## 执行完后必须给出的内容

- 家庭和成员如何关联
- 健康档案有哪些字段
- 当前还缺什么展示能力
- Codex 审查结果
