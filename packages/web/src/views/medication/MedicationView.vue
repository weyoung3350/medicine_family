<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px">
      <h2 style="margin:0">服药管理</h2>
      <div>
        <el-select v-model="selectedMemberId" placeholder="选择成员" style="width:160px;margin-right:12px" @change="onMemberChange">
          <el-option v-for="m in familyStore.members" :key="m.id" :label="m.displayName" :value="m.id" />
        </el-select>
        <el-button type="primary" @click="showPlanDialog = true">新建服药计划</el-button>
      </div>
    </div>

    <el-tabs v-model="activeTab">
      <!-- 今日服药 -->
      <el-tab-pane label="今日服药" name="today">
        <el-empty v-if="!todayItems.length" description="今日暂无服药计划" />
        <div v-for="item in todayItems" :key="item.schedule?.id" style="padding:16px;margin-bottom:12px;border:1px solid #e4e7ed;border-radius:8px;display:flex;justify-content:space-between;align-items:center">
          <div>
            <div style="font-size:18px;font-weight:bold;color:#303133">
              {{ item.schedule?.timeOfDay }} {{ item.schedule?.label || '' }}
            </div>
            <div style="font-size:16px;margin-top:4px">
              {{ item.medicine?.name }}
              <span style="color:#666;margin-left:8px">{{ item.plan?.dosageAmount }}{{ item.plan?.dosageUnit }}</span>
              <el-tag v-if="item.plan?.mealRelation" size="small" style="margin-left:8px">{{ getMealLabel(item.plan?.mealRelation) }}</el-tag>
            </div>
          </div>
          <div>
            <el-tag v-if="item.log?.status === 'taken'" type="success" size="large" style="font-size:14px">已服用</el-tag>
            <el-tag v-else-if="item.log?.status === 'skipped'" type="info" size="large" style="font-size:14px">已跳过</el-tag>
            <el-tag v-else-if="item.log?.status === 'missed'" type="danger" size="large" style="font-size:14px">漏服</el-tag>
            <div v-else>
              <el-button
                type="success"
                size="large"
                class="check-in-button"
                :disabled="checkingInKey === getCheckInKey(item)"
                @click="doCheckIn(item, false)"
              >
                <CalmHeartbeatLoader v-if="checkingInKey === getCheckInKey(item)" :size="30" label="确认服药中" />
                <span v-else>已服药</span>
              </el-button>
              <el-button size="large" :disabled="checkingInKey === getCheckInKey(item)" @click="doCheckIn(item, true)">跳过</el-button>
            </div>
          </div>
        </div>
      </el-tab-pane>

      <!-- 服药计划 -->
      <el-tab-pane label="服药计划" name="plans">
        <el-empty v-if="!plans.length" description="暂无服药计划" />
        <el-table v-else :data="plans" border>
          <el-table-column label="药品" width="150">
            <template #default="{ row }">{{ row.medicine?.name }}</template>
          </el-table-column>
          <el-table-column label="剂量">
            <template #default="{ row }">{{ row.dosageAmount }}{{ row.dosageUnit }} / 次</template>
          </el-table-column>
          <el-table-column label="频次">
            <template #default="{ row }">{{ getFreqLabel(row) }}</template>
          </el-table-column>
          <el-table-column label="时间">
            <template #default="{ row }">
              <el-tag v-for="s in row.schedules" :key="s.id" size="small" style="margin:2px">
                {{ s.timeOfDay }} {{ s.label || '' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="用餐关系" width="80">
            <template #default="{ row }">{{ getMealLabel(row.mealRelation) }}</template>
          </el-table-column>
          <el-table-column label="起止日期">
            <template #default="{ row }">{{ row.startDate }} ~ {{ row.endDate || '长期' }}</template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <!-- 依从性统计 -->
      <el-tab-pane label="依从性统计" name="stats">
        <el-radio-group v-model="statsRange" style="margin-bottom:16px" @change="loadAdherence">
          <el-radio-button value="week">本周</el-radio-button>
          <el-radio-button value="month">本月</el-radio-button>
        </el-radio-group>

        <el-row :gutter="20" v-if="adherenceData">
          <el-col :span="6">
            <el-card shadow="hover">
              <el-statistic title="依从率" :value="adherenceData.adherenceRate" suffix="%" />
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card shadow="hover">
              <el-statistic title="总计划次数" :value="adherenceData.total" />
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card shadow="hover" style="color:#67c23a">
              <el-statistic title="已服用" :value="adherenceData.taken" />
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card shadow="hover">
              <el-statistic title="漏服" :value="adherenceData.missed" />
            </el-card>
          </el-col>
        </el-row>

        <el-card style="margin-top:20px">
          <template #header>每日服药情况</template>
          <div ref="chartRef" style="height:300px"></div>
        </el-card>
      </el-tab-pane>
    </el-tabs>

    <!-- 新建计划对话框 -->
    <el-dialog v-model="showPlanDialog" title="新建服药计划" width="550px">
      <el-form :model="planForm" label-width="80px">
        <el-form-item label="药品" required>
          <el-select v-model="planForm.medicineId" filterable style="width:100%" placeholder="选择药品">
            <el-option v-for="m in allMedicines" :key="m.id" :label="m.name" :value="m.id" />
          </el-select>
        </el-form-item>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="每次剂量">
              <el-input-number v-model="planForm.dosageAmount" :min="0.5" :step="0.5" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="单位">
              <el-input v-model="planForm.dosageUnit" placeholder="粒/片/ml" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="频次">
          <el-select v-model="planForm.frequencyType" style="width:100%">
            <el-option label="每天" value="daily" />
            <el-option label="隔天" value="every_other_day" />
            <el-option label="每周指定" value="weekly" />
            <el-option label="自定义间隔" value="custom" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="planForm.frequencyType === 'weekly'" label="选择周几">
          <el-checkbox-group v-model="planForm.frequencyDays">
            <el-checkbox :value="1">周一</el-checkbox>
            <el-checkbox :value="2">周二</el-checkbox>
            <el-checkbox :value="3">周三</el-checkbox>
            <el-checkbox :value="4">周四</el-checkbox>
            <el-checkbox :value="5">周五</el-checkbox>
            <el-checkbox :value="6">周六</el-checkbox>
            <el-checkbox :value="0">周日</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item v-if="planForm.frequencyType === 'custom'" label="间隔天数">
          <el-input-number v-model="planForm.customInterval" :min="2" />
        </el-form-item>
        <el-form-item label="用餐关系">
          <el-select v-model="planForm.mealRelation" style="width:100%">
            <el-option label="饭后" value="after_meal" />
            <el-option label="饭前" value="before_meal" />
            <el-option label="随餐" value="with_meal" />
            <el-option label="空腹" value="empty_stomach" />
            <el-option label="不限" value="anytime" />
          </el-select>
        </el-form-item>
        <el-form-item label="服药时间" required>
          <div v-for="(s, idx) in planForm.schedules" :key="idx" style="display:flex;gap:8px;margin-bottom:8px">
            <el-time-picker v-model="s.timeOfDay" format="HH:mm" value-format="HH:mm" placeholder="时间" />
            <el-input v-model="s.label" placeholder="标签(如：早餐后)" style="width:140px" />
            <el-button v-if="planForm.schedules.length > 1" text type="danger" @click="planForm.schedules.splice(idx, 1)">删除</el-button>
          </div>
          <el-button text type="primary" @click="planForm.schedules.push({timeOfDay:'',label:''})">+ 添加时间点</el-button>
        </el-form-item>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="开始日期">
              <el-date-picker v-model="planForm.startDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="结束日期">
              <el-date-picker v-model="planForm.endDate" type="date" value-format="YYYY-MM-DD" style="width:100%" placeholder="留空为长期" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="告警宽限">
          <el-input-number v-model="planForm.gracePeriodMinutes" :min="5" :max="60" :step="5" />
          <span style="margin-left:8px;color:#999">分钟（超时未打卡将震动告警）</span>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showPlanDialog = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="savePlan">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, watch, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import { useFamilyStore } from '@/stores/family'
import { medicationApi } from '@/api/medication'
import { medicineApi } from '@/api/medicine'
import CalmHeartbeatLoader from '@/components/common/CalmHeartbeatLoader.vue'
import * as echarts from 'echarts'

const familyStore = useFamilyStore()
const selectedMemberId = ref('')
const activeTab = ref('today')
const showPlanDialog = ref(false)
const saving = ref(false)
const checkingInKey = ref('')

const todayItems = ref<any[]>([])
const plans = ref<any[]>([])
const allMedicines = ref<any[]>([])
const adherenceData = ref<any>(null)
const statsRange = ref('week')
const chartRef = ref<HTMLElement>()

const planForm = reactive({
  medicineId: '', dosageAmount: 1, dosageUnit: '粒',
  frequencyType: 'daily', frequencyDays: [] as number[], customInterval: 2,
  mealRelation: 'after_meal',
  schedules: [{ timeOfDay: '08:00', label: '早餐后' }],
  startDate: new Date().toISOString().split('T')[0],
  endDate: '',
  gracePeriodMinutes: 15,
})

async function loadToday() {
  if (!familyStore.currentFamilyId || !selectedMemberId.value) return
  try {
    todayItems.value = (await medicationApi.getToday(familyStore.currentFamilyId, selectedMemberId.value)) as any
  } catch { todayItems.value = [] }
}

async function loadPlans() {
  if (!familyStore.currentFamilyId || !selectedMemberId.value) return
  try {
    plans.value = (await medicationApi.listPlans(familyStore.currentFamilyId, selectedMemberId.value)) as any
  } catch { plans.value = [] }
}

async function loadAdherence() {
  if (!familyStore.currentFamilyId || !selectedMemberId.value) return
  try {
    adherenceData.value = (await medicationApi.getAdherence(familyStore.currentFamilyId, selectedMemberId.value, statsRange.value)) as any
    await nextTick()
    renderChart()
  } catch { adherenceData.value = null }
}

function renderChart() {
  if (!chartRef.value || !adherenceData.value?.dailyBreakdown) return
  const chart = echarts.init(chartRef.value)
  const breakdown = adherenceData.value.dailyBreakdown
  const dates = Object.keys(breakdown).sort()
  chart.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['已服用', '漏服'] },
    xAxis: { type: 'category', data: dates },
    yAxis: { type: 'value', name: '次数' },
    series: [
      { name: '已服用', type: 'bar', stack: 'total', data: dates.map(d => breakdown[d].taken), color: '#67c23a' },
      { name: '漏服', type: 'bar', stack: 'total', data: dates.map(d => breakdown[d].missed), color: '#f56c6c' },
    ],
  })
}

async function doCheckIn(item: any, skip: boolean) {
  const itemKey = getCheckInKey(item)
  checkingInKey.value = itemKey
  try {
    await medicationApi.checkIn(
      familyStore.currentFamilyId, selectedMemberId.value,
      item.plan?.id, item.schedule?.id,
      { skip, quantityTaken: item.plan?.dosageAmount }
    )
    if (!skip) triggerCompletionHaptic()
    ElMessage.success(skip ? '已跳过' : '打卡成功')
    await loadToday()
  } catch (e: any) {
    ElMessage.error(e.message || '操作失败')
  } finally {
    if (checkingInKey.value === itemKey) checkingInKey.value = ''
  }
}

async function savePlan() {
  if (!planForm.medicineId) { ElMessage.warning('请选择药品'); return }
  if (!planForm.schedules.some(s => s.timeOfDay)) { ElMessage.warning('请设置服药时间'); return }
  saving.value = true
  try {
    await medicationApi.createPlan(familyStore.currentFamilyId, selectedMemberId.value, planForm)
    ElMessage.success('计划创建成功')
    showPlanDialog.value = false
    await loadPlans()
    await loadToday()
  } catch (e: any) {
    ElMessage.error(e.message || '创建失败')
  } finally {
    saving.value = false
  }
}

function onMemberChange() {
  loadToday()
  loadPlans()
  if (activeTab.value === 'stats') loadAdherence()
}

function getMealLabel(r: string) {
  const m: Record<string, string> = { before_meal: '饭前', after_meal: '饭后', with_meal: '随餐', empty_stomach: '空腹', anytime: '不限' }
  return m[r] || ''
}
function getFreqLabel(plan: any) {
  const m: Record<string, string> = { daily: '每天', every_other_day: '隔天', weekly: '每周', custom: `每${plan.customInterval}天` }
  return m[plan.frequencyType] || ''
}

function getCheckInKey(item: any) {
  return `${item.plan?.id || 'plan'}-${item.schedule?.id || 'schedule'}`
}

function triggerCompletionHaptic() {
  if ('vibrate' in navigator) navigator.vibrate(18)
}

watch(activeTab, (val) => {
  if (val === 'stats') loadAdherence()
})

onMounted(async () => {
  if (!familyStore.families.length) await familyStore.loadFamilies()
  if (!familyStore.members.length) await familyStore.loadMembers()
  if (familyStore.members.length) {
    selectedMemberId.value = familyStore.members[0].id
    onMemberChange()
  }
  if (familyStore.currentFamilyId) {
    try { allMedicines.value = (await medicineApi.list(familyStore.currentFamilyId)) as any } catch {}
  }
})
</script>

<style scoped>
.check-in-button {
  min-width: 92px;
  background: linear-gradient(135deg, #4CAF50, #2F9E8F) !important;
  border: none !important;
  border-radius: 14px;
  box-shadow: 0 10px 24px rgba(76, 175, 80, 0.24);
}

.check-in-button :deep(.el-button > span),
.check-in-button span {
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
</style>
