# 批次 2 任务提示词

> 发给 Claude Code 直接执行。  
> 只做这一批，不要提前碰认证、家庭、药品等后续模块。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。
> 本批完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入下一批。

## 任务目标

把数据库底座固定下来：SQLAlchemy、会话、迁移、最小用户模型。

## 任务边界

- 只做数据库连接、ORM、迁移、用户模型
- 不要实现登录接口
- 不要实现家庭或药品业务
- 不要改 Web / Flutter 前端

## 必须保持的约束

- 数据库仍然使用 PostgreSQL
- 项目仍然放在 `packages/backend`
- 先保证开发环境可运行，再考虑扩展

## 建议的文件范围

优先创建或修改这些文件：

- `packages/backend/alembic.ini`
- `packages/backend/alembic/env.py`
- `packages/backend/alembic/script.py.mako`
- `packages/backend/alembic/versions/.gitkeep`
- `packages/backend/app/db/base.py`
- `packages/backend/app/db/session.py`
- `packages/backend/app/models/__init__.py`
- `packages/backend/app/models/user.py`
- `packages/backend/app/core/config.py`
- `packages/backend/app/core/database.py`
- `packages/backend/tests/test_db_schema.py`

## 实施要求

1. 先写会失败的数据库测试
2. 再实现最小 ORM 和迁移配置
3. 再跑测试确认通过
4. 最后汇报迁移入口和模型入口

## 验收标准

- 可以创建 `user` 表
- 可以完成最小查询
- Alembic 可用
- 测试可运行并通过

## 执行完后必须给出的内容

- 数据库配置从哪里读取
- ORM 和迁移怎么连接
- 当前缺了哪些业务表
- Codex 审查结果
