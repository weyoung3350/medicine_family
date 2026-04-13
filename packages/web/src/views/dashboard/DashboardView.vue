<template>
  <div class="dashboard-page">
    <section class="hero-card">
      <div class="hero-content">
        <p class="eyebrow">MEDICINE FAMILY</p>
        <h1>今天的家庭用药状态</h1>
        <p class="hero-copy">快速查看成员、药箱库存、待服药提醒和本周依从率，减少遗漏和临期风险。</p>
        <div class="hero-actions">
          <el-tag effect="dark" round>安全提醒</el-tag>
          <el-tag type="success" effect="plain" round>{{ todayPending }} 项待处理</el-tag>
        </div>
      </div>
      <div class="hero-control">
        <span class="control-label">当前家庭</span>
        <el-select
          v-if="familyStore.families.length"
          v-model="familyStore.currentFamilyId"
          placeholder="选择家庭"
          class="family-select"
          @change="onFamilyChange"
        >
          <el-option v-for="f in familyStore.families" :key="f.id" :label="f.name" :value="f.id" />
        </el-select>
        <div v-else class="empty-family">暂无家庭数据</div>
      </div>
    </section>

    <el-row :gutter="20" class="stat-grid">
      <el-col :xs="24" :sm="12" :lg="6">
        <el-card shadow="hover" class="stat-card stat-blue">
          <div class="stat-icon-wrap blue"><el-icon class="stat-icon"><User /></el-icon></div>
          <div class="stat-meta">
            <el-statistic title="家庭成员" :value="familyStore.members.length" />
            <span>已纳入健康档案</span>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="6">
        <el-card shadow="hover" class="stat-card stat-green">
          <div class="stat-icon-wrap green"><el-icon class="stat-icon"><Box /></el-icon></div>
          <div class="stat-meta">
            <el-statistic title="药箱药品" :value="medicineCount" />
            <span>库存批次持续追踪</span>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="6">
        <el-card shadow="hover" class="stat-card stat-orange">
          <div class="stat-icon-wrap orange"><el-icon class="stat-icon pulse"><Clock /></el-icon></div>
          <div class="stat-meta">
            <el-statistic title="今日待服药" :value="todayPending" />
            <span>按时完成更安心</span>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="6">
        <el-card shadow="hover" class="stat-card stat-cyan">
          <div class="stat-icon-wrap cyan"><el-icon class="stat-icon"><TrendCharts /></el-icon></div>
          <div class="stat-meta">
            <el-statistic title="本周依从率" :value="adherenceRate" suffix="%" />
            <span>根据服药记录估算</span>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" class="content-grid">
      <el-col :xs="24" :lg="12">
        <el-card class="alert-card">
          <template #header>
            <span class="card-title danger">
              <el-icon class="blink"><WarningFilled /></el-icon> 临期药品预警
            </span>
          </template>
          <el-empty v-if="!expiringMeds.length" description="暂无临期药品" />
          <div v-for="med in expiringMeds" :key="med.id" class="alert-item">
            <el-tag type="danger">{{ med.medicine?.name }}</el-tag>
            <span>有效期至 {{ med.expiryDate }}</span>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :lg="12">
        <el-card class="alert-card">
          <template #header>
            <span class="card-title warning">
              <el-icon class="blink"><WarningFilled /></el-icon> 库存不足提醒
            </span>
          </template>
          <el-empty v-if="!lowStockMeds.length" description="库存充足" />
          <div v-for="med in lowStockMeds" :key="med.id" class="alert-item">
            <el-tag type="warning">{{ med.medicine?.name }}</el-tag>
            <span>仅剩 {{ med.remainingQty }}{{ med.medicine?.unit }}</span>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" class="content-grid">
      <el-col :span="24">
        <el-card class="timeline-card">
          <template #header>
            <span class="card-title">今日服药时间轴</span>
          </template>
          <el-empty v-if="!todaySchedule.length" description="今日暂无服药安排">
            <template #image>
              <el-icon class="empty-icon float"><CircleCheckFilled /></el-icon>
            </template>
          </el-empty>
          <el-timeline v-else class="medicine-timeline">
            <el-timeline-item
              v-for="item in todaySchedule"
              :key="item.schedule?.id"
              :timestamp="item.schedule?.timeOfDay + ' ' + (item.schedule?.label || '')"
              :type="getTimelineType(item.log?.status)"
              placement="top"
            >
              <el-card shadow="never" class="timeline-dose">
                <div class="dose-row">
                  <div>
                    <strong>{{ item.medicine?.name }}</strong>
                    <span>
                      {{ item.plan?.dosageAmount }}{{ item.plan?.dosageUnit }}
                      {{ getMealLabel(item.plan?.mealRelation) }}
                    </span>
                  </div>
                  <el-tag :type="getStatusTagType(item.log?.status)">
                    {{ getStatusLabel(item.log?.status) }}
                  </el-tag>
                </div>
              </el-card>
            </el-timeline-item>
          </el-timeline>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { User, Box, Clock, TrendCharts, WarningFilled, CircleCheckFilled } from '@element-plus/icons-vue'
import { useFamilyStore } from '@/stores/family'
import { medicineApi } from '@/api/medicine'
import { medicationApi } from '@/api/medication'

const familyStore = useFamilyStore()

const medicineCount = ref(0)
const todayPending = ref(0)
const adherenceRate = ref(0)
const expiringMeds = ref<any[]>([])
const lowStockMeds = ref<any[]>([])
const todaySchedule = ref<any[]>([])

async function loadDashboard() {
  if (!familyStore.currentFamilyId) return
  const fid = familyStore.currentFamilyId

  try {
    const meds = await medicineApi.list(fid) as any
    medicineCount.value = Array.isArray(meds) ? meds.length : 0
  } catch { medicineCount.value = 0 }

  try { expiringMeds.value = (await medicineApi.getExpiring(fid)) as any } catch { expiringMeds.value = [] }
  try { lowStockMeds.value = (await medicineApi.getLowStock(fid)) as any } catch { lowStockMeds.value = [] }

  // 加载每个成员的今日计划
  todaySchedule.value = []
  for (const member of familyStore.members) {
    try {
      const items = (await medicationApi.getToday(fid, member.id)) as unknown as any[]
      todaySchedule.value.push(...(items || []))
    } catch {}
  }
  todayPending.value = todaySchedule.value.filter((i: any) => i.log?.status === 'pending').length

  // 加载依从性
  if (familyStore.members.length) {
    try {
      const adh = (await medicationApi.getAdherence(fid, familyStore.members[0].id, 'week')) as any
      adherenceRate.value = adh?.adherenceRate || 0
    } catch { adherenceRate.value = 0 }
  }
}

function onFamilyChange(id: string) {
  familyStore.setCurrentFamily(id)
  loadDashboard()
}

function getTimelineType(status: string) {
  if (status === 'taken') return 'success'
  if (status === 'missed') return 'danger'
  if (status === 'skipped') return 'info'
  return 'warning'
}
function getStatusTagType(status: string) {
  if (status === 'taken') return 'success'
  if (status === 'missed') return 'danger'
  if (status === 'skipped') return 'info'
  return 'warning'
}
function getStatusLabel(status: string) {
  const map: Record<string, string> = { pending: '待服用', taken: '已服用', missed: '漏服', skipped: '已跳过', late: '迟服' }
  return map[status] || '待服用'
}
function getMealLabel(relation: string) {
  const map: Record<string, string> = { before_meal: '饭前', after_meal: '饭后', with_meal: '随餐', empty_stomach: '空腹', anytime: '' }
  return map[relation] || ''
}

onMounted(async () => {
  await familyStore.loadFamilies()
  await familyStore.loadMembers()
  await loadDashboard()
})
</script>

<style scoped>
.dashboard-page {
  animation: page-in 0.45s ease both;
}

.hero-card {
  position: relative;
  display: flex;
  justify-content: space-between;
  gap: 24px;
  min-height: 220px;
  margin-bottom: 22px;
  padding: 32px;
  overflow: hidden;
  border: 1px solid rgba(15, 124, 154, 0.12);
  border-radius: 28px;
  background:
    radial-gradient(circle at 82% 24%, rgba(88, 214, 200, 0.38), transparent 17rem),
    linear-gradient(135deg, rgba(255, 255, 255, 0.92), rgba(222, 246, 241, 0.76));
  box-shadow: 0 24px 80px rgba(24, 72, 83, 0.16);
}

.hero-card::after {
  content: '';
  position: absolute;
  right: 32px;
  bottom: -54px;
  width: 230px;
  height: 230px;
  border-radius: 50%;
  background:
    linear-gradient(90deg, transparent 45%, rgba(15, 124, 154, 0.22) 45% 55%, transparent 55%),
    linear-gradient(0deg, transparent 45%, rgba(15, 124, 154, 0.22) 45% 55%, transparent 55%),
    rgba(88, 214, 200, 0.1);
  transform: rotate(-12deg);
}

.hero-content,
.hero-control {
  position: relative;
  z-index: 1;
}

.eyebrow {
  margin: 0 0 10px;
  color: var(--primary);
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.18em;
}

.hero-card h1 {
  max-width: 540px;
  margin: 0;
  color: var(--text-primary);
  font-size: clamp(30px, 5vw, 48px);
  line-height: 1.08;
  letter-spacing: -1px;
}

.hero-copy {
  max-width: 560px;
  margin: 16px 0 0;
  color: var(--text-secondary);
  font-size: 15px;
  line-height: 1.8;
}

.hero-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 22px;
}

.hero-control {
  align-self: flex-start;
  min-width: 230px;
  padding: 18px;
  border: 1px solid rgba(15, 124, 154, 0.12);
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.68);
  box-shadow: 0 16px 40px rgba(24, 72, 83, 0.12);
}

.control-label {
  display: block;
  margin-bottom: 10px;
  color: var(--text-secondary);
  font-size: 12px;
  font-weight: 700;
}

.family-select {
  width: 100%;
}

.empty-family {
  color: var(--text-hint);
  font-size: 13px;
}

.stat-grid,
.content-grid {
  margin-top: 20px;
}

.stat-card {
  position: relative;
  overflow: hidden;
  min-height: 148px;
}
.stat-card :deep(.el-card__body) {
  display: flex;
  align-items: center;
  gap: 16px;
  min-height: 148px;
}
.stat-card::before {
  content: '';
  position: absolute;
  inset: 0 auto 0 0;
  width: 5px;
}
.stat-blue::before { background: #0F7C9A; }
.stat-green::before { background: #4CAF50; }
.stat-orange::before { background: #FF9500; }
.stat-cyan::before { background: #58D6C8; }

.stat-icon-wrap {
  width: 58px;
  height: 58px;
  border-radius: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
}
.stat-icon-wrap.blue { background: rgba(15, 124, 154, 0.12); color: #0F7C9A; }
.stat-icon-wrap.green { background: rgba(76, 175, 80, 0.1); color: #4CAF50; }
.stat-icon-wrap.orange { background: rgba(255, 149, 0, 0.1); color: #FF9500; }
.stat-icon-wrap.cyan { background: rgba(88, 214, 200, 0.16); color: #0F7C9A; }

.stat-icon {
  font-size: 28px;
}

.stat-meta {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.stat-meta span {
  color: var(--text-hint);
  font-size: 12px;
}

.card-title {
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--text-primary);
  font-weight: 800;
}

.card-title.danger {
  color: #D94A4A;
}

.card-title.warning {
  color: #D98222;
}

.alert-card {
  min-height: 260px;
}

.alert-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 12px 0;
  border-bottom: 1px solid rgba(16, 73, 87, 0.08);
  color: var(--text-secondary);
}

.alert-item:last-child {
  border-bottom: none;
}

.timeline-card {
  margin-bottom: 20px;
}

.medicine-timeline {
  padding-top: 8px;
}

.timeline-dose {
  box-shadow: none !important;
}

.timeline-dose :deep(.el-card__body) {
  padding: 14px 16px;
}

.dose-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}

.dose-row strong {
  display: inline-block;
  min-width: 110px;
  color: var(--text-primary);
}

.dose-row span {
  margin-left: 12px;
  color: var(--text-secondary);
}

.empty-icon {
  color: #4CAF50;
  font-size: 54px;
}

/* 脉冲动画 - 待服药图标 */
.pulse {
  animation: pulse 2s ease-in-out infinite;
}
@keyframes pulse {
  0%, 100% { transform: scale(1); opacity: 1; }
  50% { transform: scale(1.15); opacity: 0.7; }
}

/* 闪烁动画 - 预警图标 */
.blink {
  animation: blink 1.5s ease-in-out infinite;
}
@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}

/* 浮动动画 - 空状态图标 */
.float {
  animation: float 3s ease-in-out infinite;
}
@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-6px); }
}

@keyframes page-in {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@media (max-width: 900px) {
  .hero-card {
    flex-direction: column;
    padding: 24px;
  }

  .hero-control {
    width: 100%;
  }

  .dose-row {
    align-items: flex-start;
    flex-direction: column;
  }

  .dose-row span {
    display: block;
    margin: 8px 0 0;
  }
}
</style>
