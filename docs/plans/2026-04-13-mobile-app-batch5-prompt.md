# 批次 5 任务提示词

> 发给 Claude Code 直接执行。  
> 这是收尾批次，只在前面批次稳定后再做。

> 如果 Claude Code 支持 teams 模式，就在开始前直接启用。  
> 本批完成后，必须通过 plugin 调用 Codex 审查；Codex 通过前不要进入下一批。

> 验证优先级：iPad 优先，Android 仅做兼容约束，不要求实机验收。

## 任务目标

收口移动端的药箱和家庭体验，减少切换混乱和空状态问题。

## 任务边界

- 只改 Flutter 移动端
- 不要改 Web
- 不要加微信小程序
- 不要改后端接口

## 必须保持的约束

- 家庭切换、成员切换要稳定
- 药箱信息要更集中
- 空状态和错误状态要统一

## 建议的文件范围

优先创建或修改这些文件：

- `packages/mobile/lib/features/medicine/medicine_detail_screen.dart`
- `packages/mobile/lib/features/family/family_screen.dart`
- `packages/mobile/lib/features/family/health_profile_screen.dart`
- `packages/mobile/lib/features/dashboard/dashboard_screen.dart`
- `packages/mobile/lib/core/providers/family_provider.dart`
- `packages/mobile/lib/core/providers/medicine_provider.dart`

## 实施要求

1. 先优化药箱详情和库存展示
2. 再优化家庭和成员切换
3. 再统一空状态和错误状态
4. 最后跑最小验证

## 验收标准

- 药箱信息更清楚
- 切换家庭和成员不混乱
- 页面状态一致

## 执行完后必须给出的内容

- 改了哪些文件
- 主要体验变化
- 还有哪些未完成项
- Codex 审查结果
