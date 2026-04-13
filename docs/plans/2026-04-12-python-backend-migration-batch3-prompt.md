# 批次 3 任务提示词

> 发给 Claude Code 直接执行。  
> 只做这一批，不要提前碰家庭、药品、AI 等后续模块。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。
> 本批完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入下一批。

## 任务目标

把账号体系和登录闭环做出来，确保 Web 登录页还能继续使用。

## 任务边界

- 只做注册、登录、当前用户信息、JWT
- 不要实现家庭业务
- 不要实现药品业务
- 不要改前端页面结构

## 必须保持的约束

- 响应字段要兼容现有 Web 登录页
- token 方式要简单清楚，便于参赛讲解
- 仍然保持 `/api/v1`

## 建议的文件范围

优先创建或修改这些文件：

- `packages/backend/app/core/security.py`
- `packages/backend/app/schemas/auth.py`
- `packages/backend/app/services/auth_service.py`
- `packages/backend/app/api/routes/auth.py`
- `packages/backend/app/api/router.py`
- `packages/backend/app/models/user.py`
- `packages/backend/tests/test_auth.py`
- `packages/backend/alembic/versions/0001_user_auth.py`

## 实施要求

1. 先写注册、登录、当前用户的失败测试
2. 再实现密码哈希、JWT、用户查询
3. 再跑测试确认通过
4. 最后说明和现有前端的兼容点

## 验收标准

- 新用户可注册
- 注册后可登录
- 登录后可获取 token
- 当前用户接口可用

## 执行完后必须给出的内容

- 密码加密方式
- token 内容
- 哪些字段兼容前端
- Codex 审查结果
