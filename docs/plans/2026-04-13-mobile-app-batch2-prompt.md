# 批次 2 任务提示词

> 发给 Claude Code 直接执行。  
> 只做这一批，不要提前碰 OCR 辅助计划、AI 展示等后续模块。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。  
> 本批完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入下一批。

> 验证优先级：iPad 优先，Android 仅做兼容约束，不要求实机验收。

## 任务目标

做移动端的站内消息中心，承接服药、临期、低库存提醒。

## 任务边界

- 只做 Flutter 消息中心
- 不要改 Web
- 不要做第三方推送
- 不要引入短信/邮件

## 必须保持的约束

- 消息要来自现有后端接口
- 页面要能清楚区分未读和已读
- 不要破坏现有首页布局

## 建议的文件范围

优先创建或修改这些文件：

- `packages/mobile/lib/features/more/more_screen.dart`
- `packages/mobile/lib/features/settings/settings_screen.dart`
- `packages/mobile/lib/features/notifications/notification_screen.dart`
- `packages/mobile/lib/core/providers/notification_provider.dart`
- `packages/mobile/lib/main.dart`

## 实施要求

1. 先把消息列表和未读数跑起来
2. 再补已读/全部已读
3. 再跑最小验证
4. 最后说明消息来源和交互入口

## 验收标准

- 能看到消息列表
- 能标记已读
- 能看到未读数

## 执行完后必须给出的内容

- 改了哪些文件
- 消息入口在哪里
- 未读/已读如何区分
- Codex 审查结果
