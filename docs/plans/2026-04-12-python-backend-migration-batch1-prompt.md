# 批次 1 任务提示词

> 发给 Claude Code 直接执行。  
> 只做这一批，不要提前碰数据库、认证、家庭、药品等后续模块。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。
> 本批完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入下一批。

## 任务目标

把 Python 后端骨架搭起来，保证它能在 `packages/backend` 下启动，并提供健康检查接口。

## 任务边界

- 只做 FastAPI 骨架、配置、路由、健康检查
- 不要实现数据库模型
- 不要实现认证
- 不要改 Web / Flutter 前端
- 不要删除旧 NestJS 代码

## 必须保持的约束

- API 前缀仍然是 `/api/v1`
- 端口仍然兼容当前前端代理到 `3000`
- 项目仍然放在 `packages/backend`
- 输出要便于学生参赛讲解，结构要简单

## 建议的文件范围

优先创建或修改这些文件：

- `packages/backend/pyproject.toml`
- `packages/backend/requirements.txt`
- `packages/backend/requirements-dev.txt`
- `packages/backend/pytest.ini`
- `packages/backend/app/__init__.py`
- `packages/backend/app/main.py`
- `packages/backend/app/core/__init__.py`
- `packages/backend/app/core/config.py`
- `packages/backend/app/api/__init__.py`
- `packages/backend/app/api/router.py`
- `packages/backend/app/api/health.py`
- `packages/backend/tests/test_health.py`
- `packages/backend/package.json`

## 实施要求

1. 先写一个会失败的测试
2. 再实现最小可运行代码
3. 再跑测试确认通过
4. 最后汇报改了哪些文件

## 健康检查要求

`GET /api/v1/health` 返回：

```json
{ "status": "ok" }
```

## 结构建议

- 用 FastAPI 做主应用
- 用一个总路由文件统一挂载 `/api/v1`
- 健康检查单独成一个最小路由
- 配置单独放在 `app/core/config.py`

## 验收标准

- 后端可启动
- 健康检查可访问
- 测试可运行并通过
- 返回结构稳定

## 执行完后必须给出的内容

- 新增了哪些文件
- 修改了哪些文件
- 用什么命令验证
- 当前还有哪些未做内容
- Codex 审查结果
