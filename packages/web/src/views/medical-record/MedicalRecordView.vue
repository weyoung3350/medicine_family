<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px">
      <h2 style="margin:0">病历管理</h2>
      <div>
        <el-select v-model="filterMemberId" placeholder="按成员筛选" clearable style="width:140px;margin-right:12px" @change="loadRecords">
          <el-option v-for="m in familyStore.members" :key="m.id" :label="m.displayName" :value="m.id" />
        </el-select>
        <el-input v-model="keyword" placeholder="搜索病历" style="width:180px;margin-right:12px" clearable @clear="loadRecords" @keyup.enter="loadRecords" />
        <el-button type="primary" @click="showAddDialog = true">添加病历</el-button>
      </div>
    </div>

    <el-empty v-if="!records.length" description="暂无病历记录" />

    <el-row :gutter="16">
      <el-col :span="8" v-for="rec in records" :key="rec.id" style="margin-bottom:16px">
        <el-card shadow="hover" class="record-card">
          <template #header>
            <div style="display:flex;justify-content:space-between;align-items:center">
              <strong>{{ rec.diagnosis || '未填写诊断' }}</strong>
              <el-tag size="small" type="info">{{ rec.visitDate || '日期未知' }}</el-tag>
            </div>
          </template>
          <div v-if="rec.hospital" style="color:#666;margin-bottom:4px">
            <el-icon><OfficeBuilding /></el-icon> {{ rec.hospital }}
            <span v-if="rec.department"> - {{ rec.department }}</span>
          </div>
          <div v-if="rec.doctor" style="color:#666;margin-bottom:4px">
            <el-icon><UserFilled /></el-icon> {{ rec.doctor }}
          </div>
          <div v-if="rec.member" style="color:#999;margin-bottom:4px;font-size:13px">
            就诊人: {{ rec.member.displayName }}
          </div>
          <div v-if="rec.chiefComplaint" style="color:#666;margin-bottom:4px;font-size:13px">
            主诉: {{ rec.chiefComplaint?.substring(0, 60) }}{{ (rec.chiefComplaint?.length || 0) > 60 ? '...' : '' }}
          </div>
          <div v-if="rec.prescriptions?.length" style="margin-top:8px">
            <el-tag v-for="(p, i) in rec.prescriptions.slice(0, 3)" :key="i" size="small" style="margin-right:4px;margin-bottom:4px">
              {{ p.name }}
            </el-tag>
            <el-tag v-if="rec.prescriptions.length > 3" size="small" type="info">+{{ rec.prescriptions.length - 3 }}</el-tag>
          </div>
          <div style="margin-top:12px;text-align:right">
            <el-button size="small" type="primary" @click="openDetail(rec)">详情</el-button>
            <el-button size="small" type="danger" @click="handleDelete(rec)">删除</el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 添加病历对话框 -->
    <el-dialog v-model="showAddDialog" title="添加病历" width="650px" @close="resetForm">
      <el-tabs v-model="addMode">
        <el-tab-pane label="手动录入" name="manual" />
        <el-tab-pane label="AI识别(拍照)" name="ocr" />
      </el-tabs>

      <div v-if="addMode === 'ocr'" style="margin-bottom:20px">
        <div style="display:flex;gap:12px;margin-bottom:12px;flex-wrap:wrap">
          <el-upload
            :auto-upload="false"
            :show-file-list="false"
            accept="image/*"
            @change="handleFileSelect"
          >
            <el-button type="primary">选择图片</el-button>
          </el-upload>
          <el-upload
            :auto-upload="false"
            :show-file-list="false"
            accept="image/*"
            :http-request="() => {}"
            @change="handleFileSelect"
          >
            <el-button type="success">
              <input ref="cameraInput" type="file" accept="image/*" capture="environment" style="display:none" @change="handleCameraCapture" />
              <span @click.stop="triggerCamera">拍照识别</span>
            </el-button>
          </el-upload>
        </div>
        <div v-if="previewUrl" style="margin-bottom:12px">
          <img :src="previewUrl" style="max-width:100%;max-height:200px;border-radius:8px;border:1px solid #eee" />
        </div>
        <el-input v-model="ocrImageUrl" placeholder="或直接输入图片URL" style="margin-bottom:12px" />
        <el-button type="warning" :loading="ocrLoading" @click="doOcr" :disabled="!ocrImageUrl && !selectedFile">AI识别</el-button>
        <el-alert v-if="uploadingFile" title="正在上传图片..." type="info" style="margin-top:12px" :closable="false" />
        <el-alert v-if="ocrResult" title="识别完成，请校对以下信息" type="success" style="margin-top:12px" :closable="false" />
        <el-alert v-if="ocrResult?.needsReview" title="识别置信度较低，请仔细核对" type="warning" style="margin-top:8px" :closable="false" />
      </div>

      <el-form :model="recordForm" label-width="80px">
        <el-form-item label="就诊人">
          <el-select v-model="recordForm.memberId" placeholder="选择家庭成员" clearable style="width:100%">
            <el-option v-for="m in familyStore.members" :key="m.id" :label="m.displayName" :value="m.id" />
          </el-select>
        </el-form-item>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="医院">
              <el-input v-model="recordForm.hospital" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="科室">
              <el-input v-model="recordForm.department" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="医生">
              <el-input v-model="recordForm.doctor" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="就诊日期">
              <el-date-picker v-model="recordForm.visitDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="诊断">
          <el-input v-model="recordForm.diagnosis" />
        </el-form-item>
        <el-form-item label="主诉">
          <el-input v-model="recordForm.chiefComplaint" type="textarea" :rows="2" placeholder="患者描述的主要症状" />
        </el-form-item>
        <el-form-item label="现病史">
          <el-input v-model="recordForm.presentIllness" type="textarea" :rows="2" />
        </el-form-item>

        <!-- 处方药品列表 -->
        <el-form-item label="处方">
          <div style="width:100%">
            <div v-for="(p, i) in recordForm.prescriptions" :key="i" style="display:flex;gap:8px;margin-bottom:8px;align-items:center">
              <el-input v-model="p.name" placeholder="药品名" style="flex:2" />
              <el-input v-model="p.dosage" placeholder="用量" style="flex:1" />
              <el-input v-model="p.frequency" placeholder="频次" style="flex:1" />
              <el-input v-model="p.duration" placeholder="疗程" style="flex:1" />
              <el-button type="danger" :icon="Delete" circle size="small" @click="recordForm.prescriptions.splice(i, 1)" />
            </div>
            <el-button size="small" @click="recordForm.prescriptions.push({ name: '', dosage: '', frequency: '', duration: '' })">
              + 添加药品
            </el-button>
          </div>
        </el-form-item>

        <el-form-item label="检查结果">
          <el-input v-model="recordForm.examinations" type="textarea" :rows="2" />
        </el-form-item>
        <el-form-item label="医嘱">
          <el-input v-model="recordForm.doctorAdvice" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="showAddDialog = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveRecord">保存</el-button>
      </template>
    </el-dialog>

    <!-- 病历详情 -->
    <el-drawer
      v-model="showDetail"
      :title="currentRecord?.diagnosis || '病历详情'"
      size="500px"
      class="record-detail-drawer"
      modal-class="record-detail-glass-modal"
    >
      <template v-if="currentRecord">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="就诊人">{{ currentRecord.member?.displayName || '-' }}</el-descriptions-item>
          <el-descriptions-item label="医院">{{ currentRecord.hospital || '-' }}</el-descriptions-item>
          <el-descriptions-item label="科室">{{ currentRecord.department || '-' }}</el-descriptions-item>
          <el-descriptions-item label="医生">{{ currentRecord.doctor || '-' }}</el-descriptions-item>
          <el-descriptions-item label="就诊日期">{{ currentRecord.visitDate || '-' }}</el-descriptions-item>
          <el-descriptions-item label="诊断">{{ currentRecord.diagnosis || '-' }}</el-descriptions-item>
          <el-descriptions-item label="主诉">{{ currentRecord.chiefComplaint || '-' }}</el-descriptions-item>
          <el-descriptions-item label="现病史">{{ currentRecord.presentIllness || '-' }}</el-descriptions-item>
          <el-descriptions-item label="检查结果">{{ currentRecord.examinations || '-' }}</el-descriptions-item>
          <el-descriptions-item label="医嘱">{{ currentRecord.doctorAdvice || '-' }}</el-descriptions-item>
        </el-descriptions>

        <h4 style="margin-top:20px">处方药品</h4>
        <el-table v-if="currentRecord.prescriptions?.length" :data="currentRecord.prescriptions" border size="small">
          <el-table-column prop="name" label="药品名" />
          <el-table-column prop="dosage" label="用量" width="100" />
          <el-table-column prop="frequency" label="频次" width="100" />
          <el-table-column prop="duration" label="疗程" width="80" />
        </el-table>
        <div v-else style="color:#999">无处方记录</div>
      </template>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Delete, OfficeBuilding, UserFilled } from '@element-plus/icons-vue'
import { useFamilyStore } from '@/stores/family'
import { medicalRecordApi } from '@/api/medical-record'
import client from '@/api/client'

const familyStore = useFamilyStore()

const records = ref<any[]>([])
const keyword = ref('')
const filterMemberId = ref('')
const showAddDialog = ref(false)
const showDetail = ref(false)
const addMode = ref('manual')
const ocrImageUrl = ref('')
const ocrLoading = ref(false)
const ocrResult = ref<any>(null)
const saving = ref(false)
const currentRecord = ref<any>(null)
const selectedFile = ref<File | null>(null)
const previewUrl = ref('')
const uploadingFile = ref(false)
const cameraInput = ref<HTMLInputElement>()

const recordForm = reactive({
  memberId: '',
  hospital: '',
  department: '',
  doctor: '',
  visitDate: '',
  diagnosis: '',
  chiefComplaint: '',
  presentIllness: '',
  prescriptions: [] as Array<{ name: string; dosage: string; frequency: string; duration: string }>,
  examinations: '',
  doctorAdvice: '',
})

async function loadRecords() {
  if (!familyStore.currentFamilyId) return
  try {
    records.value = (await medicalRecordApi.list(familyStore.currentFamilyId, {
      memberId: filterMemberId.value || undefined,
      keyword: keyword.value || undefined,
    })) as any
  } catch { records.value = [] }
}

function handleFileSelect(uploadFile: any) {
  const file = uploadFile.raw || uploadFile
  if (!file) return
  selectedFile.value = file
  previewUrl.value = URL.createObjectURL(file)
  ocrImageUrl.value = ''
}

function triggerCamera() {
  cameraInput.value?.click()
}

function handleCameraCapture(e: Event) {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  selectedFile.value = file
  previewUrl.value = URL.createObjectURL(file)
  ocrImageUrl.value = ''
}

async function uploadFile(): Promise<string> {
  if (!selectedFile.value) return ocrImageUrl.value
  uploadingFile.value = true
  try {
    const formData = new FormData()
    formData.append('file', selectedFile.value)
    const res = (await client.post('/upload/image', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })) as any
    ocrImageUrl.value = res.url
    return res.url
  } finally {
    uploadingFile.value = false
  }
}

async function doOcr() {
  if (!ocrImageUrl.value && !selectedFile.value) { ElMessage.warning('请选择图片或输入URL'); return }
  ocrLoading.value = true
  try {
    if (selectedFile.value) await uploadFile()
    if (!ocrImageUrl.value) { ElMessage.warning('上传失败'); ocrLoading.value = false; return }
    const result = (await medicalRecordApi.ocr(familyStore.currentFamilyId, ocrImageUrl.value)) as any
    ocrResult.value = result
    Object.assign(recordForm, {
      hospital: result.hospital || '',
      department: result.department || '',
      doctor: result.doctor || '',
      visitDate: result.visitDate || '',
      diagnosis: result.diagnosis || '',
      chiefComplaint: result.chiefComplaint || '',
      presentIllness: result.presentIllness || '',
      prescriptions: result.prescriptions?.length ? result.prescriptions : [],
      examinations: result.examinations || '',
      doctorAdvice: result.doctorAdvice || '',
    })
    ElMessage.success('识别完成，请校对信息')
  } catch (e: any) {
    ElMessage.error('识别失败: ' + (e.message || '请重试'))
  } finally {
    ocrLoading.value = false
  }
}

async function saveRecord() {
  saving.value = true
  try {
    await medicalRecordApi.create(familyStore.currentFamilyId, {
      ...recordForm,
      memberId: recordForm.memberId || null,
      imageUrl: ocrImageUrl.value || null,
      ocrRawData: ocrResult.value || null,
    })
    ElMessage.success('保存成功')
    showAddDialog.value = false
    await loadRecords()
  } catch (e: any) {
    ElMessage.error(e.message || '保存失败')
  } finally {
    saving.value = false
  }
}

function resetForm() {
  Object.assign(recordForm, {
    memberId: '', hospital: '', department: '', doctor: '',
    visitDate: '', diagnosis: '', chiefComplaint: '', presentIllness: '',
    prescriptions: [], examinations: '', doctorAdvice: '',
  })
  ocrResult.value = null
  ocrImageUrl.value = ''
  selectedFile.value = null
  previewUrl.value = ''
  addMode.value = 'manual'
}

function openDetail(rec: any) {
  currentRecord.value = rec
  showDetail.value = true
}

async function handleDelete(rec: any) {
  try {
    await ElMessageBox.confirm('确定删除这条病历？', '提示', { type: 'warning' })
    await medicalRecordApi.remove(familyStore.currentFamilyId, rec.id)
    ElMessage.success('已删除')
    await loadRecords()
  } catch {}
}

onMounted(async () => {
  if (!familyStore.families.length) await familyStore.loadFamilies()
  if (!familyStore.members.length) await familyStore.loadMembers()
  await loadRecords()
})
</script>

<style scoped>
.record-card :deep(.el-card__header) {
  padding: 14px 16px;
}

:global(.record-detail-glass-modal) {
  background:
    radial-gradient(circle at 24% 18%, rgba(88, 214, 200, 0.18), transparent 24rem),
    rgba(14, 43, 54, 0.22) !important;
  backdrop-filter: blur(16px) saturate(1.12);
  -webkit-backdrop-filter: blur(16px) saturate(1.12);
}

:global(.record-detail-drawer.el-drawer) {
  border-radius: 28px 0 0 28px;
  background:
    linear-gradient(155deg, rgba(255, 255, 255, 0.94), rgba(235, 248, 245, 0.86)),
    rgba(255, 255, 255, 0.78);
  box-shadow: -28px 0 70px rgba(13, 51, 63, 0.22);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
}

:global(.record-detail-drawer .el-drawer__header) {
  margin-bottom: 8px;
  padding: 24px 26px 14px;
  color: var(--text-primary);
  font-weight: 800;
}

:global(.record-detail-drawer .el-drawer__body) {
  padding: 12px 26px 28px;
}
</style>
