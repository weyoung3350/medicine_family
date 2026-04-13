<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px">
      <h2 style="margin:0">家庭管理</h2>
      <div>
        <el-button type="primary" @click="showCreateDialog = true">创建家庭</el-button>
        <el-button @click="showJoinDialog = true">加入家庭</el-button>
      </div>
    </div>

    <el-row :gutter="16">
      <el-col :span="8" v-for="family in familyStore.families" :key="family.id" style="margin-bottom:16px">
        <el-card shadow="hover" :class="{ 'is-active': family.id === familyStore.currentFamilyId }" @click="selectFamily(family.id)">
          <template #header>
            <div style="display:flex;justify-content:space-between;align-items:center">
              <strong style="font-size:18px">{{ family.name }}</strong>
              <el-tag v-if="family.id === familyStore.currentFamilyId" type="success" size="small">当前</el-tag>
            </div>
          </template>
          <div style="margin-bottom:8px">
            邀请码: <el-tag>{{ family.inviteCode }}</el-tag>
            <el-button text size="small" @click.stop="copyCode(family.inviteCode)">复制</el-button>
          </div>
          <div style="color:#666">角色: {{ getRoleLabel(family.myRole) }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 当前家庭成员 -->
    <div v-if="familyStore.currentFamilyId" style="margin-top:24px">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px">
        <h3 style="margin:0">家庭成员 - {{ familyStore.currentFamily?.name }}</h3>
        <el-button type="primary" size="small" @click="showAddMemberDialog = true">添加被代管成员</el-button>
      </div>

      <el-table :data="familyStore.members" border>
        <el-table-column prop="displayName" label="姓名" width="120" />
        <el-table-column label="角色" width="100">
          <template #default="{ row }">
            <el-tag :type="row.role === 'owner' ? 'danger' : row.role === 'dependent' ? 'warning' : ''">
              {{ getRoleLabel(row.role) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="relationship" label="关系" width="100" />
        <el-table-column label="健康档案">
          <template #default="{ row }">
            <template v-if="row.healthProfile">
              <el-tag size="small" v-for="d in (row.healthProfile?.medicalHistory || [])" :key="d" style="margin:2px" type="danger">{{ d }}</el-tag>
              <el-tag size="small" v-for="a in (row.healthProfile?.allergyList || [])" :key="a" style="margin:2px" type="warning">过敏: {{ a }}</el-tag>
              <span v-if="!row.healthProfile?.medicalHistory?.length && !row.healthProfile?.allergyList?.length" style="color:#999">无特殊</span>
            </template>
            <span v-else style="color:#999">未填写</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120">
          <template #default="{ row }">
            <el-button text size="small" type="primary" @click="editHealth(row)">编辑档案</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 创建家庭 -->
    <el-dialog v-model="showCreateDialog" title="创建家庭" width="400px">
      <el-input v-model="newFamilyName" placeholder="家庭名称，如：王家" size="large" />
      <template #footer>
        <el-button @click="showCreateDialog = false">取消</el-button>
        <el-button type="primary" @click="createFamily">创建</el-button>
      </template>
    </el-dialog>

    <!-- 加入家庭 -->
    <el-dialog v-model="showJoinDialog" title="加入家庭" width="400px">
      <el-input v-model="joinCode" placeholder="输入8位邀请码" size="large" maxlength="8" />
      <template #footer>
        <el-button @click="showJoinDialog = false">取消</el-button>
        <el-button type="primary" @click="joinFamily">加入</el-button>
      </template>
    </el-dialog>

    <!-- 添加被代管成员 -->
    <el-dialog v-model="showAddMemberDialog" title="添加被代管成员(如长辈)" width="500px">
      <el-form :model="memberForm" label-width="80px">
        <el-form-item label="称呼" required>
          <el-input v-model="memberForm.displayName" placeholder="如：爷爷、外婆" />
        </el-form-item>
        <el-form-item label="关系">
          <el-input v-model="memberForm.relationship" placeholder="如：祖父、母亲" />
        </el-form-item>
        <el-divider>健康档案(可选)</el-divider>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="出生日期">
              <el-date-picker v-model="memberForm.healthProfile.birthDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="性别">
              <el-radio-group v-model="memberForm.healthProfile.gender">
                <el-radio :value="1">男</el-radio>
                <el-radio :value="2">女</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="既往病史">
          <el-select v-model="memberForm.healthProfile.medicalHistory" multiple filterable allow-create style="width:100%" placeholder="输入后回车添加">
            <el-option label="高血压" value="高血压" />
            <el-option label="糖尿病" value="糖尿病" />
            <el-option label="冠心病" value="冠心病" />
            <el-option label="高血脂" value="高血脂" />
            <el-option label="哮喘" value="哮喘" />
          </el-select>
        </el-form-item>
        <el-form-item label="过敏史">
          <el-select v-model="memberForm.healthProfile.allergyList" multiple filterable allow-create style="width:100%" placeholder="输入后回车添加">
            <el-option label="青霉素" value="青霉素" />
            <el-option label="头孢" value="头孢" />
            <el-option label="磺胺类" value="磺胺类" />
            <el-option label="花粉" value="花粉" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAddMemberDialog = false">取消</el-button>
        <el-button type="primary" @click="addMember">添加</el-button>
      </template>
    </el-dialog>

    <!-- 编辑健康档案 -->
    <el-dialog v-model="showHealthDialog" title="编辑健康档案" width="500px">
      <el-form :model="healthForm" label-width="80px">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="出生日期">
              <el-date-picker v-model="healthForm.birthDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="性别">
              <el-radio-group v-model="healthForm.gender">
                <el-radio :value="1">男</el-radio>
                <el-radio :value="2">女</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="身高(cm)">
              <el-input-number v-model="healthForm.heightCm" :min="50" :max="250" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="体重(kg)">
              <el-input-number v-model="healthForm.weightKg" :min="10" :max="300" style="width:100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="血型">
          <el-select v-model="healthForm.bloodType" style="width:100%" clearable>
            <el-option v-for="t in ['A','B','AB','O']" :key="t" :label="t+'型'" :value="t" />
          </el-select>
        </el-form-item>
        <el-form-item label="既往病史">
          <el-select v-model="healthForm.medicalHistory" multiple filterable allow-create style="width:100%" />
        </el-form-item>
        <el-form-item label="过敏史">
          <el-select v-model="healthForm.allergyList" multiple filterable allow-create style="width:100%" />
        </el-form-item>
        <el-form-item label="长期用药">
          <el-select v-model="healthForm.chronicMeds" multiple filterable allow-create style="width:100%" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="healthForm.notes" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showHealthDialog = false">取消</el-button>
        <el-button type="primary" @click="saveHealth">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { useFamilyStore } from '@/stores/family'
import { familyApi } from '@/api/family'

const familyStore = useFamilyStore()

const showCreateDialog = ref(false)
const showJoinDialog = ref(false)
const showAddMemberDialog = ref(false)
const showHealthDialog = ref(false)
const newFamilyName = ref('')
const joinCode = ref('')
const editingMemberId = ref('')

const memberForm = reactive({
  displayName: '', relationship: '',
  healthProfile: { birthDate: '', gender: 1, medicalHistory: [] as string[], allergyList: [] as string[] },
})

const healthForm = reactive({
  birthDate: '', gender: 1, heightCm: 170, weightKg: 60,
  bloodType: '', medicalHistory: [] as string[], allergyList: [] as string[],
  chronicMeds: [] as string[], notes: '',
})

async function createFamily() {
  if (!newFamilyName.value) return
  await familyApi.create({ name: newFamilyName.value })
  ElMessage.success('创建成功')
  showCreateDialog.value = false
  newFamilyName.value = ''
  await familyStore.loadFamilies()
}

async function joinFamily() {
  if (!joinCode.value) return
  await familyApi.join(joinCode.value)
  ElMessage.success('加入成功')
  showJoinDialog.value = false
  joinCode.value = ''
  await familyStore.loadFamilies()
}

async function addMember() {
  if (!memberForm.displayName) { ElMessage.warning('请填写称呼'); return }
  await familyApi.addDependent(familyStore.currentFamilyId, memberForm)
  ElMessage.success('添加成功')
  showAddMemberDialog.value = false
  Object.assign(memberForm, { displayName: '', relationship: '', healthProfile: { birthDate: '', gender: 1, medicalHistory: [], allergyList: [] } })
  await familyStore.loadMembers()
}

function editHealth(member: any) {
  editingMemberId.value = member.id
  const hp = member.healthProfile || {}
  Object.assign(healthForm, {
    birthDate: hp.birthDate || '', gender: hp.gender || 1,
    heightCm: hp.heightCm || 170, weightKg: hp.weightKg || 60,
    bloodType: hp.bloodType || '', medicalHistory: hp.medicalHistory || [],
    allergyList: hp.allergyList || [], chronicMeds: hp.chronicMeds || [],
    notes: hp.notes || '',
  })
  showHealthDialog.value = true
}

async function saveHealth() {
  await familyApi.updateHealth(familyStore.currentFamilyId, editingMemberId.value, healthForm)
  ElMessage.success('保存成功')
  showHealthDialog.value = false
  await familyStore.loadMembers()
}

function selectFamily(id: string) {
  familyStore.setCurrentFamily(id)
}

function copyCode(code: string) {
  navigator.clipboard.writeText(code)
  ElMessage.success('邀请码已复制')
}

function getRoleLabel(role: string) {
  const m: Record<string, string> = { owner: '创建者', admin: '管理员', member: '成员', dependent: '被代管' }
  return m[role] || role
}

onMounted(async () => {
  await familyStore.loadFamilies()
  await familyStore.loadMembers()
})
</script>

<style scoped>
.is-active {
  border-color: #409eff;
}
</style>
