# 项目记忆

## 项目名称
- 对外名称：家庭健康管家
- 仓库名：medicine_family

## 项目定位
- 高一学生参赛作品，不按生产系统标准设计
- 目标是面向家庭的健康助手
- 重点是可演示、可讲解、可验证

## 当前架构结论
- 后端已迁移为 Python + FastAPI
- 保持模块化单体，不拆微服务
- Web / Mobile 继续走同一套 API
- 现阶段不再扩展微信小程序

## 需求优先级
- 核心需求包含适老化大字界面
- 通知改为站内信优先，第三方推送降优先级
- OCR 支持服药计划草稿生成

## 已完成状态
- 后端关键测试已通过
- Web 可用
- 移动端 5 个批次已完成并过 Codex 审查
- 消息中心支持 reminder / alert / info 的前端跳转收口

## 移动端现状
- Flutter 端已做名称统一
- iPad 优先验证，Android 仅保留兼容约束
- 当前主要页面覆盖：
  - 登录
  - 首页
  - 今日服药
  - 药箱
  - 病历
  - AI
  - 消息中心
  - 家庭管理

## iPad 真机验证现状
- 已连接实体 iPad
- 已能识别设备：
  - iPad Pro M1 12.9（无线，需开发者模式）
  - iPad Pro 11（USB 已连接，iOS 26.3.1）
- iOS 构建已通过（模拟器 + 真机均成功）

## 已解决的阻塞（2026-04-13）
- 根因：项目原在 `/Users/dna/Documents/` 下，该目录被 iCloud FileProvider 管理
- macOS FileProvider 持续给文件添加 `com.apple.FinderInfo` 扩展属性
- 导致 codesign 报错 "resource fork, Finder information, or similar detritus not allowed"
- 解决方案：项目迁移到 `/Users/dna/Develop/claude_prj/medicine_family/`（非 iCloud 目录）
- 迁移后模拟器和真机构建均通过

## 重要文件
- `docs/需求梳理.md`
- `docs/技术架构评估.md`
- `docs/架构改进清单.md`
- `docs/plans/2026-04-13-mobile-app-requirements-plan.md`
- `docs/plans/2026-04-13-ipad-verification-checklist.md`

## 下一步建议
- iPad 真机验收（参照 docs/plans/2026-04-13-ipad-verification-checklist.md）
- 不再扩展新功能，优先保证能演示
