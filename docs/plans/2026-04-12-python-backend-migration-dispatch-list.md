# Python 后端迁移派发清单

> 这是给你实际派发 Claude Code 的顺序清单。  
> 原则：一次只发一个批次，确认通过后再发下一批。

> 每批实现完后，先让 Claude Code 通过 plugin 调用 Codex 审查；Codex 通过前不派发下一批。

## 派发顺序

1. [批次 1：Python 后端骨架](./2026-04-12-python-backend-migration-batch1-prompt.md)
2. [批次 2：数据库底座](./2026-04-12-python-backend-migration-batch2-prompt.md)
3. [批次 3：账号与登录](./2026-04-12-python-backend-migration-batch3-prompt.md)
4. [批次 4：家庭与健康档案](./2026-04-12-python-backend-migration-batch4-prompt.md)
5. [批次 5：药品、库存、OCR、上传](./2026-04-12-python-backend-migration-batch5-prompt.md)
6. [批次 6：服药计划与站内消息](./2026-04-12-python-backend-migration-batch6-prompt.md)
7. [批次 7：病历与 AI](./2026-04-12-python-backend-migration-batch7-prompt.md)
8. [批次 8：药店、种子、清理](./2026-04-12-python-backend-migration-batch8-prompt.md)

## 每批停止点

每批执行完后，先停下来确认这四项：

- 相关测试通过
- 启动方式明确
- 接口返回结构稳定
- 没有越界修改下一批内容

## 派发原则

- 不并行发多个批次
- 不要求 Claude Code 自行扩展任务范围
- 不让它跳过测试直接做下一步
- 不让它一次性清理旧后端，必须等第 8 批

## 建议的派发方式

1. 先发第 1 批
2. 等它返回结果
3. 你确认没问题后，再发下一批
4. 全部完成后再进入旧后端清理
