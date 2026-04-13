# 移动端交互下钻优化 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把移动端里“能看但不能点”的摘要卡补成可下钻、可操作的入口，优先解决临期药品预警、服药时间轴、今日服药列表、服药计划列表这几处高频体验问题。

**Architecture:** 复用现有药品详情页作为药品级下钻入口；新增一个轻量的服药事件详情承载页，用来展示某一条打卡事件、计划实例和当前状态。手机端优先用底部弹层，平板或宽屏场景保持现有双栏思路，不引入新的后端字段，只有在现有 `todayItems` / `plans` 结构无法支撑时才考虑最小补充。

**Tech Stack:** Flutter, Provider, 现有 `MedicineProvider` / `MedicationProvider`, 现有 `MedicineDetailSheet`, `showModalBottomSheet`, `Navigator`.

---

## 任务拆分原则

- 只改 Flutter 移动端
- 不改 Web
- 不改后端，除非某个详情入口真的缺少必要主键
- 先补“可点”，再补“点进去看什么”
- 每个任务完成后都做一次最小验证，再继续下一项

---

### Task 1: 补齐通用下钻承载页

**目标**
- 新增一个“服药事件详情”承载页，统一给首页时间轴、今日服药卡、计划卡复用。
- 详情页能展示：药品、剂量、时间、成员、计划状态、打卡状态。
- 详情页里保留“查看药品详情”跳转，避免用户在事件页和药品页之间断层。

**Files:**
- Create: `packages/mobile/lib/features/medication/medication_event_detail_sheet.dart`
- Modify: `packages/mobile/lib/features/medicine/medicine_detail_screen.dart`

**Step 1: 梳理事件详情需要的字段**

- 直接基于现有 `todayItems` / `plan` / `schedule` / `medicine` / `log` 结构设计字段映射
- 明确哪些字段来自事件，哪些字段来自药品详情
- 如果缺少字段，优先做兜底文案，不先改后端

**Step 2: 实现最小详情页**

- 事件页至少展示：
  - 药品名称
  - 剂量
  - 服药时间
  - 成员名称
  - 当前状态
  - 计划日期或计划周期
- pending 状态保留“我已服药”“跳过本次”
- taken / missed / skipped 状态只展示结果和记录信息

**Step 3: 加上查看药品详情入口**

- 在事件页中提供一个明确按钮：
  - `查看药品详情`
- 通过现有 `MedicineDetailSheet.show(...)` 复用药品详情页

**Step 4: 适配移动端与宽屏**

- 移动端用 bottom sheet
- 宽屏场景先保持 bottom sheet，不在这一批里引入新的双栏容器

**Step 5: 最小验证**

- `flutter analyze`
- `flutter test test/widget_test.dart`
- 手动打开一个 mock 事件页，确认字段渲染正常

**验收标准**
- 一个服药事件能完整看到“是什么药、哪一餐、什么时间、什么状态”
- 页面里能继续跳到药品详情
- pending 事件保留操作按钮

---

### Task 2: 让首页临期预警和库存预警可点击

**目标**
- 首页里的临期药品预警、库存不足提醒都能点击进入药品详情。
- 卡片需要明确表达“这是可操作入口”，不能再是纯展示。

**Files:**
- Modify: `packages/mobile/lib/features/dashboard/dashboard_screen.dart`
- Modify: `packages/mobile/lib/features/medicine/medicine_detail_screen.dart` 作为必要时的展示增强

**Step 1: 给警告卡补点击手势**

- 给 `_alertCard` 增加 `onTap`
- 卡片外层使用 `InkWell`
- 在视觉上加一个轻量可点击提示：
  - 右侧 chevron
  - 或“查看详情”文字

**Step 2: 点击后打开对应药品详情**

- 复用 `MedicineProvider.getMedicineDetail(...)`
- 用药品 `id` 拉取详情后打开 `MedicineDetailSheet.show(...)`
- 失败时只提示 toast，不阻断页面滚动

**Step 3: 保持首页数据加载逻辑不变**

- 不改现有 `loadExpiring` / `loadLowStock` 接口
- 不新增首页专用 DTO

**Step 4: 最小验证**

- 在模拟器里点临期药品卡，确认能进入详情
- 点库存不足卡，确认同样能进入详情
- 刷新首页后不丢状态、不重复加载出错

**验收标准**
- 临期预警卡可点
- 库存不足卡可点
- 点击后都进入同一个药品详情页

---

### Task 3: 让首页今日服药时间轴可下钻

**目标**
- 首页时间轴不再只是“流水展示”，而是可点开查看某条服药事件的详情。

**Files:**
- Modify: `packages/mobile/lib/features/dashboard/dashboard_screen.dart`
- Modify: `packages/mobile/lib/features/medication/medication_event_detail_sheet.dart`

**Step 1: 给时间轴卡片增加 tap**

- 给 `_timelineCard` 包一层 `InkWell`
- 卡片里增加轻量提示：
  - 右侧箭头
  - 或状态文字旁加“详情”

**Step 2: 事件页优先展示事件信息**

- 点击时间轴条目后，打开 `MedicationEventDetailSheet`
- 事件页默认展示该条对应的：
  - 时间点
  - 成员
  - 药品
  - 剂量
  - 状态

**Step 3: 保留“直接执行动作”**

- pending 时保留打卡和跳过
- taken / missed / skipped 只读展示

**Step 4: 最小验证**

- 点一条待服用时间轴，能看到详情和操作按钮
- 点一条已完成时间轴，能看到只读详情
- 列表滚动、刷新不受影响

**验收标准**
- 时间轴每一条都能点开
- 时间轴详情不再只停留在首页摘要层

---

### Task 4: 让今日服药页和计划页有同一套下钻逻辑

**目标**
- 今日服药页和服药计划页也补齐“点卡片看详情”的能力。
- 今日页继续保留主动作按钮，但卡片本身要可点。

**Files:**
- Modify: `packages/mobile/lib/features/medication/today_screen.dart`
- Modify: `packages/mobile/lib/features/medication/plans_tab.dart`
- Modify: `packages/mobile/lib/features/medication/medication_event_detail_sheet.dart`
- Create: `packages/mobile/lib/features/medication/medication_plan_detail_sheet.dart`（如果事件页和计划页的展示差异太大就拆开）

**Step 1: 今日服药卡片补下钻**

- 给 `_buildMedCard` 增加点击入口
- 点击后打开事件详情页
- 继续保留卡片内的“我已服药 / 跳过本次”按钮

**Step 2: 计划卡片补下钻**

- 给 `_buildPlanCard` 增加点击入口
- 点击后打开计划详情页
- 计划详情页展示：
  - 关联药品
  - 起止日期
  - 频次
  - 饭前饭后
  - 时间点标签
  - 当前启用状态

**Step 3: 计划详情页保留轻操作**

- 如果计划是进行中，提供“查看今日服药”“查看药品详情”入口
- 如果计划已结束，提供“复制计划”或“重新创建”占位入口，若当前实现成本高则先不做按钮，只保留文案提示

**Step 4: 最小验证**

- 今日页卡片可点
- 计划页卡片可点
- 内部按钮不会被外层点击误触拦截

**验收标准**
- 今日服药页不是只有按钮，卡片本身也能下钻
- 计划页不是只有摘要，能进入详细规则页

---

### Task 5: 让统计页从“只看结果”变成“可定位问题”

**目标**
- 统计页的关键指标和图表可以点，点完能定位到某个趋势或某天的明细。

**Files:**
- Modify: `packages/mobile/lib/features/medication/stats_tab.dart`
- Modify: `packages/mobile/lib/features/medication/medication_event_detail_sheet.dart`
- Create: `packages/mobile/lib/features/medication/medication_day_summary_sheet.dart`（如果仅靠已有数据不够，就用这个轻量汇总页）

**Step 1: 先把指标卡做成可点击**

- 依从率、总计划、已服用、漏服这四个卡片都加 tap
- 点击后优先展示对应解释和定位入口

**Step 2: 图表点击展示当天汇总**

- 如果 `dailyBreakdown` 只有聚合数据，不强行改后端
- 点击某一天后，展示当天的：
  - 日期
  - 已服用数
  - 漏服数
  - 对应“跳到今日页”的入口

**Step 3: 数据不够时不要扩后端**

- 本批优先用现有统计接口
- 不为了图表下钻额外加复杂接口

**Step 4: 最小验证**

- 统计卡片可点
- 图表点击有反馈
- 如果当天没有明细，也要给清晰空态，不要静默无响应

**验收标准**
- 统计页不是纯展示页
- 用户能从“数值”回到“具体问题位置”

---

### Task 6: 统一交互样式和验收

**目标**
- 把可点击卡片和不可点击卡片区分开，避免用户误判。

**Files:**
- Modify: `packages/mobile/lib/features/dashboard/dashboard_screen.dart`
- Modify: `packages/mobile/lib/features/medication/today_screen.dart`
- Modify: `packages/mobile/lib/features/medication/plans_tab.dart`
- Modify: `packages/mobile/lib/features/medication/stats_tab.dart`
- Modify: `packages/mobile/lib/features/medicine/medicine_detail_screen.dart`
- Modify: `packages/mobile/test/widget_test.dart`

**Step 1: 统一可点击提示**

- 可点击卡片统一使用：
  - `InkWell`
  - 波纹反馈
  - 右箭头或“查看详情”
- 不可点击卡片不要伪装成按钮

**Step 2: 补最少的 widget test**

- 先保留一个能跑的 smoke test
- 再补 1-2 个纯 widget 级测试，验证新详情页能正常渲染
- 不强求做完整导航集成测试

**Step 3: 跑最终验证**

- `cd packages/mobile && flutter analyze`
- `cd packages/mobile && flutter test`
- 模拟器人工检查首页、今日页、计划页、统计页四个入口

**验收标准**
- 点击区域统一
- 页面反馈统一
- 验证命令能跑完

---

## 推荐执行顺序

1. Task 1: 先做事件详情承载页
2. Task 2: 首页临期/库存预警可点击
3. Task 3: 首页时间轴可下钻
4. Task 4: 今日页和计划页补入口
5. Task 5: 统计页补定位
6. Task 6: 统一样式和测试

---

## 执行要求

- 一次只做一个任务
- 每个任务结束后立刻验证
- 不要顺手做 UI 大改
- 不要扩后端接口，除非当前数据结构真的缺主键
- 每做完一项，输出：
  - 改了哪些文件
  - 新增了哪些交互
  - 还有哪些未完成项

