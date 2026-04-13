# 批次 8 任务提示词

> 发给 Claude Code 直接执行。  
> 这是收尾批次，只在前面所有功能都稳定后再做。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。
> 本批完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入下一批。

## 任务目标

完成收尾：附近药店、种子、文档、旧后端清理。

## 任务边界

- 只做药店查询、种子脚本、文档、旧代码清理
- 不再新增新的业务模块
- 不再改前端交互

## 必须保持的约束

- 种子脚本要能跑出可演示账号和家庭数据
- 清理旧代码前必须保证 Python 后端已稳定
- 文档要更新到新的启动方式

## 建议的文件范围

优先创建或修改这些文件：

- `packages/backend/app/services/pharmacy_service.py`
- `packages/backend/app/api/routes/pharmacy.py`
- `packages/backend/scripts/seed.py`
- `scripts/seed.sh`
- `packages/backend/package.json`
- `packages/backend/README.md` 或 `README.md`
- `docs/架构改进清单.md`
- `packages/backend/src/**`
- `packages/backend/nest-cli.json`
- `packages/backend/tsconfig.json`

## 实施要求

1. 先写药店和种子相关失败测试
2. 再实现最小药店查询和 Python 种子
3. 再跑测试和种子脚本确认通过
4. 最后再清理旧 NestJS 代码

## 验收标准

- 附近药店可查询
- 种子脚本可运行
- 演示账号可登录
- 清理旧代码后项目仍可启动

## 执行完后必须给出的内容

- 种子入口
- 演示账号
- 清理了哪些旧文件
- Codex 审查结果
