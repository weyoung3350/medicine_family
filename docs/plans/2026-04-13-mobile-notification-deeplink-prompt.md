# 站内消息来源跳转任务提示词

> 发给 Claude Code 直接执行。  
> 只做移动端消息中心的“来源跳转”，不要顺手扩展到别的 UI 重构。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。  
> 本任务完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入其他任务。

## 任务目标

让移动端消息中心里的提醒消息可以直接跳到对应页面，而不是只能查看列表和标记已读。

## 当前问题

当前消息中心只支持：
- 列表展示
- 未读数
- 标记已读

但点击消息后没有业务跳转。  
这会导致“服药提醒”“低库存提醒”“临期提醒”只能看，不能直接处理。

## 目标行为

实现以下跳转规则：

1. 服药提醒  
- 点击后跳到“今日服药”页

2. 低库存提醒  
- 点击后跳到“药箱”页  
- 如果已有足够上下文，可以进一步打开药品详情；如果当前后端字段不够，就先跳药箱页

3. 临期提醒  
- 点击后跳到“药箱”页  
- 同样优先保证有稳定跳转，不强求直接打开具体批次

4. 其他普通消息  
- 保持当前行为，至少标记已读

## 任务边界

- 只改 Flutter 移动端
- 不改 Web
- 后端仅在确有必要时做最小字段补充
- 不引入新的通知类型体系

## 优先方案

优先使用现有字段完成跳转：
- `type`
- `title`
- `body`

如果现有字段不足以稳定判断，再最小补充后端消息响应，例如：
- `relatedId`
- `targetType`

但补充字段必须克制，不能把通知系统改成一套复杂路由协议。

## 建议修改文件

移动端优先：
- `packages/mobile/lib/features/notifications/notification_screen.dart`
- `packages/mobile/lib/core/providers/notification_provider.dart`
- `packages/mobile/lib/features/home/home_screen.dart`
- `packages/mobile/lib/features/medication/medication_screen.dart`
- `packages/mobile/lib/features/medicine/cabinet_screen.dart`

如确有必要，后端最小补充：
- `packages/backend/app/schemas/notification.py`
- `packages/backend/app/services/notification_service.py`

## 实施要求

1. 先梳理当前消息数据能否支持跳转
2. 尽量只用现有字段实现
3. 如果必须补字段，只做最小补充
4. 点击消息后，先标记已读，再跳转
5. 保持 iPad 布局稳定，不破坏消息列表当前样式

## 验收标准

- 点击服药提醒可以进入“今日服药”
- 点击低库存提醒可以进入“药箱”
- 点击临期提醒可以进入“药箱”
- 未读消息点击后会变已读
- 普通消息不会报错

## 执行完后必须给出的内容

- 改了哪些文件
- 跳转规则是什么
- 是否补了后端字段
- 哪些消息类型还不能精确跳转
- Codex 审查结果

