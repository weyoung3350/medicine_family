# 批次 4 任务提示词

> 发给 Claude Code 直接执行。  
> 只做这一批，不要提前碰药箱和家庭体验收口等后续模块。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。  
> 本批完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入下一批。

> 验证优先级：iPad 优先，Android 仅做兼容约束，不要求实机验收。

## 任务目标

把 AI 结果从聊天记录收敛成更清楚的结构化展示。

## 任务边界

- 只改 Flutter AI 展示
- 不要改后端 AI 接口
- 不要改 Web
- 不要把展示改成纯图表

## 必须保持的约束

- 结构化结果要兼容现有回复
- 仍然保留聊天式交互
- 结果必须清楚表达风险和建议

## 建议的文件范围

优先创建或修改这些文件：

- `packages/mobile/lib/features/ai/ai_chat_screen.dart`
- `packages/mobile/lib/features/ai/consultation_history_screen.dart`
- `packages/mobile/lib/core/providers/ai_provider.dart`

## 实施要求

1. 先把 AI 回复拆成结构化卡片
2. 再补风险提示和建议摘要
3. 再跑最小验证
4. 最后说明和现有聊天记录如何共存

## 验收标准

- AI 结果能分段展示
- 风险和建议能快速识别
- 历史记录仍可查看

## 执行完后必须给出的内容

- 改了哪些文件
- 结构化结果怎么展示
- 聊天和卡片如何共存
- Codex 审查结果
