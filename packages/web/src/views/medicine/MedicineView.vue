<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px">
      <h2 style="margin:0">药箱管理</h2>
      <div>
        <el-input v-model="keyword" placeholder="搜索药品" style="width:200px;margin-right:12px" clearable @clear="loadMedicines" @keyup.enter="loadMedicines" />
        <el-button type="primary" @click="showAddDialog = true">添加药品</el-button>
      </div>
    </div>

    <el-empty v-if="!medicines.length" description="药箱空空如也，快来添加药品吧" />

    <el-row :gutter="16">
      <el-col :span="8" v-for="med in medicines" :key="med.id" style="margin-bottom:16px">
        <el-card shadow="hover">
          <template #header>
            <div style="display:flex;justify-content:space-between;align-items:center">
              <strong>{{ med.name }}</strong>
              <el-tag v-if="med.category" size="small">{{ med.category }}</el-tag>
            </div>
          </template>
          <div v-if="med.brandName" style="color:#666;margin-bottom:4px">品牌: {{ med.brandName }}</div>
          <div v-if="med.specification" style="color:#666;margin-bottom:4px">规格: {{ med.specification }}</div>
          <div v-if="med.dosageForm" style="color:#666;margin-bottom:4px">剂型: {{ med.dosageForm }}</div>
          <div v-if="med.indications" style="color:#666;margin-bottom:8px;font-size:13px">
            功效: {{ med.indications?.substring(0, 50) }}{{ med.indications?.length > 50 ? '...' : '' }}
          </div>
          <el-divider style="margin:8px 0" />
          <div v-for="inv in med.inventories" :key="inv.id" style="display:flex;justify-content:space-between;padding:4px 0">
            <span>
              剩余 <strong :style="{color: inv.remainingQty <= inv.lowThreshold ? '#f56c6c' : '#67c23a'}">{{ inv.remainingQty }}</strong>{{ med.unit }}
            </span>
            <span style="color:#999;font-size:12px">
              有效期至 {{ inv.expiryDate || '未知' }}
            </span>
          </div>
          <div v-if="!med.inventories?.length" style="color:#999">暂无库存记录</div>
          <div style="margin-top:12px;text-align:right">
            <el-button size="small" @click="openInventoryDialog(med)">入库</el-button>
            <el-button size="small" type="primary" @click="openDetail(med)">详情</el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 添加药品对话框 -->
    <el-dialog v-model="showAddDialog" title="添加药品" width="600px" @close="resetForm">
      <el-tabs v-model="addMode">
        <el-tab-pane label="手动录入" name="manual" />
        <el-tab-pane label="AI识别(拍照)" name="ocr" />
      </el-tabs>

      <div v-if="addMode === 'ocr'" style="margin-bottom:20px">
        <el-input v-model="ocrImageUrl" placeholder="输入药品图片URL" style="margin-bottom:12px" />
        <el-button type="warning" :loading="ocrLoading" @click="doOcr">AI识别</el-button>
        <el-alert v-if="ocrResult" title="识别完成，请校对以下信息" type="success" style="margin-top:12px" :closable="false" />
      </div>

      <el-form :model="medForm" label-width="80px">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="药品名" required>
              <el-input v-model="medForm.name" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="品牌名">
              <el-input v-model="medForm.brandName" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="规格">
              <el-input v-model="medForm.specification" placeholder="如 0.25g*60粒/瓶" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="单位" required>
              <el-select v-model="medForm.unit" style="width:100%">
                <el-option label="粒" value="粒" />
                <el-option label="片" value="片" />
                <el-option label="ml" value="ml" />
                <el-option label="支" value="支" />
                <el-option label="袋" value="袋" />
                <el-option label="贴" value="贴" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="剂型">
              <el-select v-model="medForm.dosageForm" style="width:100%" clearable>
                <el-option label="片剂" value="片剂" />
                <el-option label="胶囊" value="胶囊" />
                <el-option label="口服液" value="口服液" />
                <el-option label="颗粒" value="颗粒" />
                <el-option label="软膏" value="软膏" />
                <el-option label="注射剂" value="注射剂" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="分类">
              <el-select v-model="medForm.category" style="width:100%" clearable>
                <el-option label="OTC" value="OTC" />
                <el-option label="处方药" value="处方药" />
                <el-option label="保健品" value="保健品" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="生产厂家">
          <el-input v-model="medForm.manufacturer" />
        </el-form-item>
        <el-form-item label="适应症">
          <el-input v-model="medForm.indications" type="textarea" :rows="2" />
        </el-form-item>
        <el-form-item label="禁忌">
          <el-input v-model="medForm.contraindications" type="textarea" :rows="2" />
        </el-form-item>
        <el-form-item label="用法用量">
          <el-input v-model="medForm.usageGuide" type="textarea" :rows="2" placeholder="如：每次2粒，每日3次，饭后温水送服" />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="showAddDialog = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveMedicine">保存</el-button>
      </template>
    </el-dialog>

    <!-- 入库对话框 -->
    <el-dialog v-model="showInventoryDialog" title="药品入库" width="400px">
      <p>药品: <strong>{{ currentMedicine?.name }}</strong></p>
      <el-form label-width="80px">
        <el-form-item label="数量" required>
          <el-input-number v-model="invForm.totalQuantity" :min="1" />
        </el-form-item>
        <el-form-item label="批号">
          <el-input v-model="invForm.batchNumber" />
        </el-form-item>
        <el-form-item label="有效期至">
          <el-date-picker v-model="invForm.expiryDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
        <el-form-item label="预警阈值">
          <el-input-number v-model="invForm.lowThreshold" :min="1" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showInventoryDialog = false">取消</el-button>
        <el-button type="primary" @click="saveInventory">入库</el-button>
      </template>
    </el-dialog>

    <!-- 药品详情 -->
    <el-drawer
      v-model="showDetail"
      :title="currentMedicine?.name"
      size="450px"
      class="medicine-detail-drawer"
      modal-class="medicine-detail-glass-modal"
    >
      <template v-if="currentMedicine">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="品牌名">{{ currentMedicine.brandName || '-' }}</el-descriptions-item>
          <el-descriptions-item label="规格">{{ currentMedicine.specification || '-' }}</el-descriptions-item>
          <el-descriptions-item label="剂型">{{ currentMedicine.dosageForm || '-' }}</el-descriptions-item>
          <el-descriptions-item label="分类">{{ currentMedicine.category || '-' }}</el-descriptions-item>
          <el-descriptions-item label="生产厂家">{{ currentMedicine.manufacturer || '-' }}</el-descriptions-item>
          <el-descriptions-item label="批准文号">{{ currentMedicine.approvalNumber || '-' }}</el-descriptions-item>
          <el-descriptions-item label="适应症">{{ currentMedicine.indications || '-' }}</el-descriptions-item>
          <el-descriptions-item label="禁忌">{{ currentMedicine.contraindications || '-' }}</el-descriptions-item>
          <el-descriptions-item label="用法用量">{{ currentMedicine.usageGuide || '-' }}</el-descriptions-item>
        </el-descriptions>
        <h4 style="margin-top:20px">库存记录</h4>
        <el-table :data="currentMedicine.inventories" border size="small">
          <el-table-column prop="batchNumber" label="批号" />
          <el-table-column prop="remainingQty" label="剩余" width="70" />
          <el-table-column prop="totalQuantity" label="总量" width="70" />
          <el-table-column prop="expiryDate" label="有效期" width="110" />
          <el-table-column label="状态" width="80">
            <template #default="{ row }">
              <el-tag :type="[,'success','warning','danger','info'][row.status]" size="small">
                {{ ['','正常','临期','过期','用完'][row.status] }}
              </el-tag>
            </template>
          </el-table-column>
        </el-table>
      </template>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { useFamilyStore } from '@/stores/family'
import { medicineApi } from '@/api/medicine'

const familyStore = useFamilyStore()

const medicines = ref<any[]>([])
const keyword = ref('')
const showAddDialog = ref(false)
const showInventoryDialog = ref(false)
const showDetail = ref(false)
const addMode = ref('manual')
const ocrImageUrl = ref('')
const ocrLoading = ref(false)
const ocrResult = ref<any>(null)
const saving = ref(false)
const currentMedicine = ref<any>(null)

const medForm = reactive({
  name: '', brandName: '', specification: '', unit: '粒',
  dosageForm: '', category: '', manufacturer: '',
  indications: '', contraindications: '', usageGuide: '',
})

const invForm = reactive({
  totalQuantity: 30, batchNumber: '', expiryDate: '', lowThreshold: 5,
})

async function loadMedicines() {
  if (!familyStore.currentFamilyId) return
  try {
    medicines.value = (await medicineApi.list(familyStore.currentFamilyId, { keyword: keyword.value || undefined })) as any
  } catch { medicines.value = [] }
}

async function doOcr() {
  if (!ocrImageUrl.value) { ElMessage.warning('请输入图片URL'); return }
  ocrLoading.value = true
  try {
    const result = (await medicineApi.ocr(familyStore.currentFamilyId, ocrImageUrl.value)) as any
    ocrResult.value = result
    Object.assign(medForm, {
      name: result.name || '',
      brandName: result.brandName || '',
      specification: result.specification || '',
      dosageForm: result.dosageForm || '',
      manufacturer: result.manufacturer || '',
      indications: result.indications || '',
      contraindications: result.contraindications || '',
      usageGuide: result.usageGuide || '',
    })
    ElMessage.success('识别完成，请校对信息')
  } catch (e: any) {
    ElMessage.error('识别失败: ' + (e.message || '请重试'))
  } finally {
    ocrLoading.value = false
  }
}

async function saveMedicine() {
  if (!medForm.name) { ElMessage.warning('请填写药品名'); return }
  saving.value = true
  try {
    await medicineApi.create(familyStore.currentFamilyId, { ...medForm })
    ElMessage.success('添加成功')
    showAddDialog.value = false
    await loadMedicines()
  } catch (e: any) {
    ElMessage.error(e.message || '添加失败')
  } finally {
    saving.value = false
  }
}

function resetForm() {
  Object.assign(medForm, {
    name: '', brandName: '', specification: '', unit: '粒',
    dosageForm: '', category: '', manufacturer: '',
    indications: '', contraindications: '', usageGuide: '',
  })
  ocrResult.value = null
  ocrImageUrl.value = ''
  addMode.value = 'manual'
}

function openInventoryDialog(med: any) {
  currentMedicine.value = med
  Object.assign(invForm, { totalQuantity: 30, batchNumber: '', expiryDate: '', lowThreshold: 5 })
  showInventoryDialog.value = true
}

async function saveInventory() {
  if (!currentMedicine.value) return
  try {
    await medicineApi.addInventory(familyStore.currentFamilyId, currentMedicine.value.id, invForm)
    ElMessage.success('入库成功')
    showInventoryDialog.value = false
    await loadMedicines()
  } catch (e: any) {
    ElMessage.error(e.message || '入库失败')
  }
}

function openDetail(med: any) {
  currentMedicine.value = med
  showDetail.value = true
}

onMounted(async () => {
  if (!familyStore.families.length) await familyStore.loadFamilies()
  await loadMedicines()
})
</script>

<style scoped>
:global(.medicine-detail-glass-modal) {
  background:
    radial-gradient(circle at 24% 18%, rgba(88, 214, 200, 0.18), transparent 24rem),
    rgba(14, 43, 54, 0.22) !important;
  backdrop-filter: blur(16px) saturate(1.12);
  -webkit-backdrop-filter: blur(16px) saturate(1.12);
}

:global(.medicine-detail-drawer.el-drawer) {
  border-radius: 28px 0 0 28px;
  background:
    linear-gradient(155deg, rgba(255, 255, 255, 0.94), rgba(235, 248, 245, 0.86)),
    rgba(255, 255, 255, 0.78);
  box-shadow: -28px 0 70px rgba(13, 51, 63, 0.22);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
}

:global(.medicine-detail-drawer .el-drawer__header) {
  margin-bottom: 8px;
  padding: 24px 26px 14px;
  color: var(--text-primary);
  font-weight: 800;
}

:global(.medicine-detail-drawer .el-drawer__body) {
  padding: 12px 26px 28px;
}

@media (max-width: 700px) {
  :global(.medicine-detail-drawer.el-drawer) {
    width: 92% !important;
    border-radius: 24px 0 0 24px;
  }
}
</style>
