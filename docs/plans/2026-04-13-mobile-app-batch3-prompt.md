# 批次 3 任务提示词

> 发给 Claude Code 直接执行。  
> 只做这一批，不要提前碰 AI 展示、药箱体验收口等后续模块。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。  
> 本批完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入下一批。

> 验证优先级：iPad 优先，Android 仅做兼容约束，不要求实机验收。

## 任务目标

让 OCR 结果可以辅助生成服药计划草稿。

## 任务边界

- 只做 Flutter 端的 OCR 后计划流程
- 不要改后端接口
- 不要改 Web
- 不要加入新的 OCR 模型

## 必须保持的约束

- 仍然沿用现有 OCR 接口
- 用户要能手动修改识别结果
- 生成计划前必须有确认步骤

## 建议的文件范围

优先创建或修改这些文件：

- `packages/mobile/lib/features/medication/create_plan_screen.dart`
- `packages/mobile/lib/features/medicine/cabinet_screen.dart`
- `packages/mobile/lib/core/providers/medication_provider.dart`
- `packages/mobile/lib/core/providers/medicine_provider.dart`

## 实施要求

1. 先增加 OCR 结果确认页
2. 再增加计划草稿生成入口
3. 再跑最小验证
4. 最后说明如何从 OCR 进入计划创建

## 验收标准

- OCR 结果可以被编辑
- 可以生成计划草稿
- 可以再确认后提交

## 执行完后必须给出的内容

- 改了哪些文件
- 计划草稿如何生成
- 用户确认步骤在哪里
- Codex 审查结果
