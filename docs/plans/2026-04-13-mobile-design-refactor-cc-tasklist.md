# 移动端设计收敛任务清单

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 根据 `DESIGN.md` 把移动端从“功能能用”推进到“视觉语言统一、交互层级清晰、点击感明确”的状态，优先收敛主题、卡片、排版和高频页面的表达方式。

**Architecture:** 先改全局设计令牌和共享组件，再改首页、服药、药箱等高频页面，最后补空状态、加载态和 iPad 视图验收。保留现有业务逻辑和 API 契约，只调整呈现层与交互层，不新增无必要的视觉分支。

**Tech Stack:** Flutter, Material 3, Provider, 现有 `AppTheme` / `AppColors`, 现有页面组件。

---

## 1. 评估结论

根据 `DESIGN.md`，目标风格是：
- 低噪声、低边框、强层级
- 以蓝色作为唯一主交互色
- 使用大留白和明确的 section 节奏
- 卡片/按钮要像“有明确目的的产品部件”，而不是默认 UI 套件拼装

当前移动端的主要偏差是：
- 颜色过多，除了主蓝色外，还有橙色、绿色、红色、紫色在多个页面里同时承担“视觉强调”
- 卡片和表单边框感偏重，页面更像功能列表而不是统一的产品界面
- 首页、服药页、药箱页的卡片层级不一致，缺少统一的点击提示
- 排版层级偏平均，标题、副标题、正文之间的节奏还不够清楚

结论：
- 这次不做功能扩展，优先做“设计收敛”
- 交互下钻可以保留，但要跟统一视觉一起做

---

## 2. 改造原则

- 不改 Web
- 不改后端
- 不新增业务语义，只统一展示
- 保留红/绿/橙等状态色，但只用于健康状态或风险状态，不用于装饰
- 除了主蓝色外，其他颜色尽量不承担“可点击”的识别职责
- 先统一主题，再统一页面

---

### Task 1: 收敛全局主题和设计令牌

**目标**
- 把全局颜色、卡片、按钮、输入框的样式收敛成一套更一致的设计令牌。
- 为后续页面统一提供基础。

**Files:**
- Modify: `packages/mobile/lib/app/theme.dart`
- Review: `packages/mobile/lib/main.dart`

**Step 1: 重新梳理颜色角色**

- 主色继续使用蓝色
- 统一背景、表面、正文、次正文的色值
- 让警告色、成功色、危险色只承担状态表达，不再做装饰强调

**Step 2: 收敛卡片和按钮风格**

- 卡片圆角保持统一，不要不同页面出现太多半径差异
- 按钮视觉偏向更轻、更干净，减少重阴影
- 输入框、下拉框、筛选项统一边框和高亮样式

**Step 3: 准备后续复用 token**

- 把页面里常用的表面、分割线、文字样式先整理成可复用的 theme 级配置
- 让后续页面修改尽量只改一个入口

**验收标准**
- 全局看上去是一套系统，不是各页各写各的样式
- 主蓝色是最明确的交互色
- 页面上的边框和阴影明显减少

---

### Task 2: 抽出共享的视觉组件

**目标**
- 把首页、服药页、药箱页中重复的卡片、标题、空状态统一成共享组件。

**Files:**
- Modify: `packages/mobile/lib/core/widgets/empty_state.dart`
- Modify: `packages/mobile/lib/core/widgets/adaptive_split.dart`
- Create: `packages/mobile/lib/core/widgets/app_section_header.dart`
- Create: `packages/mobile/lib/core/widgets/app_surface_card.dart`
- Create: `packages/mobile/lib/core/widgets/app_drilldown_tile.dart`

**Step 1: 提炼 section header**

- 统一 section title、图标、右侧动作入口的样式
- 让首页和服药页的区块标题看起来一致

**Step 2: 提炼 surface card**

- 把高频卡片的背景、圆角、内边距、阴影统一
- 卡片保持轻量，不要层层叠加边框

**Step 3: 提炼 drilldown tile**

- 可点击条目统一有 tap affordance
- 右侧箭头、点击波纹、标题层级保持一致

**Step 4: 统一空状态**

- 空状态文案、图标、主按钮统一
- 不同页面的空态不要风格冲突

**验收标准**
- 后续页面尽量复用共享组件，不再复制大段样式
- 可点击区域和静态区域一眼可分

---

### Task 3: 重做首页概览的视觉层级

**目标**
- 让首页从“功能大杂烩”变成“先看重点，再下钻”的首页。

**Files:**
- Modify: `packages/mobile/lib/features/dashboard/dashboard_screen.dart`
- Modify: `packages/mobile/lib/features/home/home_screen.dart`

**Step 1: 调整首页顶部结构**

- 顶部保留家庭切换和刷新，但降低噪声
- 让关键指标区成为首页第一层视觉锚点

**Step 2: 统一四个指标卡**

- 取消每张卡都使用不同强调色的做法
- 只保留少量状态色或主蓝强调
- 增加统一的点击提示和内容层级

**Step 3: 收敛临期 / 库存 / 时间轴区块**

- 把预警区块和时间轴区块做成明确的 section
- 卡片保持更轻的视觉风格，减少边框感
- 点击提示统一，不要每个模块都写一套

**Step 4: 清理首页视觉噪声**

- 统一间距
- 统一标题字号和副标题字号
- 减少“按钮像卡片、卡片像按钮”的混乱感

**验收标准**
- 首页一眼能看到主任务，而不是同时看到太多彩色块
- 区块之间有明确节奏
- 可点击项识别更清晰

---

### Task 4: 收敛服药模块的页面表达

**目标**
- 让今日服药、计划、统计三个 tab 使用同一套视觉语言。

**Files:**
- Modify: `packages/mobile/lib/features/medication/today_screen.dart`
- Modify: `packages/mobile/lib/features/medication/plans_tab.dart`
- Modify: `packages/mobile/lib/features/medication/stats_tab.dart`
- Modify: `packages/mobile/lib/features/medication/medication_event_detail_sheet.dart`

**Step 1: 统一今日页卡片样式**

- 今日页保留主按钮，但减少多余视觉装饰
- 状态 badge、时间、药品名称、剂量层级统一

**Step 2: 统一计划卡片样式**

- 计划卡片减少边框和颜色堆叠
- 计划信息按“药品 - 规则 - 时间点 - 起止日期”分层展示

**Step 3: 统一统计页样式**

- 指标卡和图表说明使用同一套文字层级
- 图表下方的说明和入口保持简洁

**Step 4: 事件详情页跟全局风格对齐**

- 服药事件详情页减少额外视觉噪声
- 操作按钮和说明文字遵循全局按钮/卡片风格

**验收标准**
- 服药模块三个 tab 像同一个产品的一部分
- 状态、按钮、信息层级统一

---

### Task 5: 收敛药箱和详情页的视觉风格

**目标**
- 让药箱列表、药品详情、OCR 确认这条链路更像一条连续的主流程。

**Files:**
- Modify: `packages/mobile/lib/features/medicine/cabinet_screen.dart`
- Modify: `packages/mobile/lib/features/medicine/medicine_detail_screen.dart`
- Modify: `packages/mobile/lib/features/medicine/ocr_confirm_screen.dart`

**Step 1: 调整药箱列表卡片**

- 保留列表信息密度，但减少重边框和多余颜色
- 点击态和普通态保持统一

**Step 2: 调整药品详情页**

- 把详情页结构收敛成更清楚的 section
- 库存、效期、基础信息、用法用量的优先级分明

**Step 3: 调整 OCR 确认页**

- OCR 结果确认页减少“表单堆叠感”
- 让用户先看重点，再逐项修正

**验收标准**
- 药箱链路的三个页面在视觉上连续
- 详情页有明显的重点层级

---

### Task 6: 收口通知、更多页和空状态

**目标**
- 把消息中心、更多页、设置页和空状态统一到同一套设计语言。

**Files:**
- Modify: `packages/mobile/lib/features/notifications/notification_screen.dart`
- Modify: `packages/mobile/lib/features/more/more_screen.dart`
- Modify: `packages/mobile/lib/features/settings/settings_screen.dart`
- Modify: `packages/mobile/lib/core/widgets/empty_state.dart`

**Step 1: 统一列表型页面样式**

- 通知中心、更多页、设置页的列表行样式统一
- 行间距、图标、箭头、次级说明统一

**Step 2: 统一空状态**

- 所有空态风格保持一致
- 空态里的主按钮样式统一

**Step 3: 统一跳转提示**

- 点击后跳转的页面和入口文案统一
- 不同页面不要出现太多不同风格的行动提示

**验收标准**
- 列表页和空态页都是同一套系统
- 跳转提示和按钮样式不再碎片化

---

### Task 7: iPad 与模拟器验收

**目标**
- 在 iPad 和模拟器上确认设计收敛后没有破坏可用性。

**Files:**
- Modify: `packages/mobile/test/widget_test.dart`

**Step 1: 补最小 smoke test**

- 保证主页面能启动
- 保证共享组件不会因为样式调整导致崩溃

**Step 2: 跑基础验证**

- `cd packages/mobile && flutter analyze`
- `cd packages/mobile && flutter test`

**Step 3: 设备验收**

- iPad 优先验证
- 模拟器验证首页、服药、药箱、消息中心

**验收标准**
- 设计改造不影响启动
- 页面在 iPad 上不溢出、不乱跳

---

## 3. 推荐执行顺序

1. Task 1: 全局主题和设计令牌
2. Task 2: 共享组件
3. Task 3: 首页概览
4. Task 4: 服药模块
5. Task 5: 药箱和详情页
6. Task 6: 通知、更多页、空状态
7. Task 7: 验收

---

## 4. 给 cc 的执行要求

- 只改移动端
- 先改 theme 和共享组件，再改页面
- 不改业务接口
- 不做大重构，只做视觉和交互收敛
- 每个任务完成后输出：
  - 改了哪些文件
  - 视觉上收敛了什么
  - 还有哪些页面没覆盖

