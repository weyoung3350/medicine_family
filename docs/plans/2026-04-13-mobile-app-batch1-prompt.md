# 批次 1 任务提示词

> 发给 Claude Code 直接执行。  
> 只做这一批，不要提前碰消息中心、OCR 辅助计划、AI 展示等后续模块。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。  
> 本批完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入下一批。

> 验证优先级：iPad 优先，Android 仅做兼容约束，不要求实机验收。

## 任务目标

做一个独立的适老化模式入口，重点承接老人日常服药打卡。

## 任务边界

- 只改 Flutter 移动端
- 不要改 Web
- 不要碰微信小程序
- 不要提前做消息中心或 AI 卡片化

## 必须保持的约束

- 保持现有登录和首页流程不破坏
- 保持现有接口契约不变
- 老人模式要简单直白，减少操作步骤
- 页面布局优先按 iPad 验证，Android 只需保证不破版

## 建议的文件范围

优先创建或修改这些文件：

- `packages/mobile/lib/features/home/home_screen.dart`
- `packages/mobile/lib/features/medication/today_screen.dart`
- `packages/mobile/lib/features/dashboard/dashboard_screen.dart`
- `packages/mobile/lib/app/theme.dart`
- `packages/mobile/lib/main.dart`

## 实施要求

1. 先写最小可用的老人模式入口
2. 再优化字号、按钮、间距和对比度
3. 再跑最小验证
4. 最后说明怎样进入、怎样退出、怎样回到普通模式

## 验收标准

- 老人模式能直接看到今日服药
- 打卡按钮更明显
- 页面在小屏上不溢出

## 执行完后必须给出的内容

- 改了哪些文件
- 老人模式入口在哪里
- 与普通模式的差异
- Codex 审查结果
