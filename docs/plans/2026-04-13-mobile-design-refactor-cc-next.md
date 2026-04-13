# 移动端设计收敛后续任务清单

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于上一轮设计收敛结果，修掉当前剩余的高风险逻辑问题，并继续把移动端的列表入口、主按钮和长辈模式页面统一到 `DESIGN.md` 的视觉语言。

**Architecture:** 先修正确性问题，再统一共享组件落地，最后微调主要页面的颜色和层级。只改移动端，不动后端，不做额外功能扩展。

**Tech Stack:** Flutter, Provider, 现有 `AppTheme` / `AppColors`, 现有共享组件 `AppSurfaceCard` / `AppDrilldownTile` / `AppSectionHeader`.

---

## 先验结论

上一轮已经完成：
- 全局 theme 收敛
- 共享组件抽取
- 首页、服药页、药箱页、统计页的基础接入
- 事件详情页和 widget test

当前还需要继续做的，是把“逻辑正确性”和“设计一致性”补齐。

---

### Task 1: 修复服药事件详情的成员回退问题

**目标**
- 不再依赖 `firstOrNull` 去猜成员。
- 点击任意成员的时间轴或今日服药项，都应把打卡落到正确成员。

**Files:**
- Modify: `packages/mobile/lib/features/medication/medication_event_detail_sheet.dart`
- Modify: `packages/mobile/lib/features/dashboard/dashboard_screen.dart`
- Review: `packages/mobile/lib/features/medication/today_screen.dart`
- Review: `packages/mobile/lib/features/medication/elder_today_screen.dart`

**Step 1: 统一成员来源**

- 优先使用传入的 `memberId`
- 没有传入时，优先使用事件里的 `_memberId`
- 最后再考虑极端兜底，但不要回退到 `family.members.firstOrNull`

**Step 2: 修复打卡路径**

- `_doCheckIn` 里只接受明确成员 ID
- 如果 memberId 缺失，直接提示“无法确定服药人”，不要误打卡

**Step 3: 补足概览页事件映射**

- 确保 dashboard 汇总项始终携带 `_memberId`
- 今日服药页、长辈模式页的事件对象也尽量带上 memberId

**验收标准**
- 多成员家庭下不会把打卡写到错误成员
- 没有成员信息时，系统宁可拒绝操作，也不误操作

---

### Task 2: 收口“查看药品详情”的数据链路

**目标**
- 事件详情页打开药品详情时，不再优先靠药名模糊匹配。
- 能拿到 `medicineId` 就直接用 `medicineId`。

**Files:**
- Modify: `packages/mobile/lib/features/medication/medication_event_detail_sheet.dart`
- Review: `packages/mobile/lib/features/medication/today_screen.dart`
- Review: `packages/mobile/lib/features/dashboard/dashboard_screen.dart`

**Step 1: 以 medicineId 为主**

- `MedicationEventDetailSheet` 优先使用 `event['medicineId']`
- 如果事件里没有 `medicineId`，再回退到 `event['medicine']?['id']`

**Step 2: 去掉过强的名称依赖**

- 名称匹配只作为最后兜底
- 如果名称匹配失败，直接提示“无法加载药品详情”

**Step 3: 保持药品详情页复用**

- 仍然复用现有 `MedicineDetailSheet`
- 不新建第二套药品详情页

**验收标准**
- 从今日服药 / 首页时间轴 / 计划页进入的事件详情，都能稳定打开对应药品

---

### Task 3: 把主操作色统一回蓝色

**目标**
- 让“可点击”的视觉主调回到蓝色。
- 绿色只保留给“完成/成功状态”，不再承担主按钮角色。

**Files:**
- Modify: `packages/mobile/lib/features/medication/today_screen.dart`
- Modify: `packages/mobile/lib/features/medication/elder_today_screen.dart`
- Review: `packages/mobile/lib/features/medication/medication_event_detail_sheet.dart`

**Step 1: 调整今日页主按钮**

- “我已服药”按钮改为蓝色主按钮
- 绿色只用于服药成功后的结果态

**Step 2: 调整长辈模式主按钮**

- 长辈模式里的主打卡按钮也改为蓝色
- 保留大字号和高对比，但不要让绿色成为按钮主色

**Step 3: 统一事件详情页按钮层级**

- 事件详情页里的主动作也统一使用蓝色
- 跳过/取消保持灰色或次要样式

**验收标准**
- 页面里“最该点的按钮”都用蓝色
- 成功态与操作态不会混淆

---

### Task 4: 把列表型入口统一接到共享组件

**目标**
- 让更多页、消息中心、设置页等列表入口视觉一致。
- 不要继续保留各页各写的 `Card + ListTile` 组合。

**Files:**
- Modify: `packages/mobile/lib/features/more/more_screen.dart`
- Modify: `packages/mobile/lib/features/notifications/notification_screen.dart`
- Modify: `packages/mobile/lib/features/settings/settings_screen.dart`
- Modify: `packages/mobile/lib/core/widgets/app_drilldown_tile.dart`
- Modify: `packages/mobile/lib/core/widgets/app_surface_card.dart`

**Step 1: 接入 AppDrilldownTile**

- 消息中心列表项改用 `AppDrilldownTile`
- 更多页的“病历管理 / 附近药店 / 家庭管理 / 设置”改用 `AppDrilldownTile`
- 设置页中可点击条目也尽量改用同一组件

**Step 2: 保留 badge 能力**

- `AppDrilldownTile` 需要支持 badge 或 trailing badge
- 避免消息中心因为换组件丢失未读角标

**Step 3: 统一卡片语义**

- 只有可点击的列表项才保留 chevron
- 纯说明卡不要伪装成入口

**验收标准**
- 所有列表入口看起来像一个系统，而不是多个页面临时拼出来的

---

### Task 5: 收紧长辈模式和详情页的视觉噪声

**目标**
- 保留长辈模式“大字、大按钮、低干扰”的方向，但让它和全局视觉一致。
- 详情页也要回到简洁、克制的表达方式。

**Files:**
- Modify: `packages/mobile/lib/features/medication/elder_today_screen.dart`
- Modify: `packages/mobile/lib/features/medicine/medicine_detail_screen.dart`
- Modify: `packages/mobile/lib/features/medicine/ocr_confirm_screen.dart`

**Step 1: 长辈模式减噪**

- 降低不必要的阴影和边框
- 保留大字号，但减少多余装饰

**Step 2: 药品详情页收敛**

- 详情页 section 标题、信息行、库存卡片统一到 theme 风格
- 少用大块彩色强调，只保留必要状态色

**Step 3: OCR 确认页收敛**

- 让 OCR 确认页更像“修正表单”，不是“信息墙”
- 输入项、按钮、说明统一风格

**验收标准**
- 长辈模式依然易读，但不突兀
- 详情页看起来和首页、药箱页属于同一系统

---

### Task 6: 最小验证

**目标**
- 确保上述修改没有引入回归。

**Files:**
- Modify: `packages/mobile/test/widget_test.dart`

**Step 1: 补一个成员回退 bug 的测试**

- 至少验证事件详情页不会在缺 memberId 时乱打卡

**Step 2: 复跑验证**

- `cd packages/mobile && flutter analyze`
- `cd packages/mobile && flutter test`

**验收标准**
- 没有新增编译错误
- 核心测试通过

---

## 推荐执行顺序

1. Task 1: 修成员回退问题
2. Task 2: 收口药品详情链路
3. Task 3: 蓝化主 CTA
4. Task 4: 列表入口统一组件
5. Task 5: 长辈模式和详情页减噪
6. Task 6: 验证

---

## 给 cc 的执行要求

- 一次只做一个 Task
- 不要扩后端
- 不要做大重构
- 每个 Task 完成后说明：
  - 改了哪些文件
  - 修了什么问题
  - 还剩哪些视觉收口没做

