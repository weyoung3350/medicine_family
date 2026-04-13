<template>
  <div style="display:flex;height:calc(100vh - 120px)">
    <!-- 左侧：对话区 -->
    <div style="flex:1;display:flex;flex-direction:column;border-right:1px solid #e4e7ed">
      <div style="padding:16px;border-bottom:1px solid #e4e7ed;display:flex;align-items:center;gap:12px">
        <h3 style="margin:0">AI 药品助手</h3>
        <el-select v-model="selectedMemberId" placeholder="选择成员" size="small" style="width:140px">
          <el-option v-for="m in familyStore.members" :key="m.id" :label="m.displayName" :value="m.id" />
        </el-select>
      </div>

      <!-- 消息列表 -->
      <div ref="msgContainer" style="flex:1;overflow-y:auto;padding:16px">
        <div v-for="(msg, idx) in messages" :key="idx"
          :style="{
            display:'flex',
            justifyContent: msg.role === 'user' ? 'flex-end' : 'flex-start',
            marginBottom: '16px'
          }">
          <div :style="{
            maxWidth: '70%',
            padding: '12px 16px',
            borderRadius: '12px',
            background: msg.role === 'user' ? '#007AFF' : '#E3F2FD',
            color: msg.role === 'user' ? '#fff' : '#2C3E50',
            whiteSpace: 'pre-wrap',
            lineHeight: '1.6'
          }">
            {{ msg.content }}
          </div>
        </div>
        <div v-if="loading" style="display:flex;margin-bottom:16px">
          <div style="padding:12px 16px;border-radius:12px;background:#f4f4f5;color:#999">
            AI 正在思考中...
          </div>
        </div>
      </div>

      <!-- 输入区 -->
      <div style="padding:16px;border-top:1px solid #e4e7ed">
        <div style="display:flex;gap:8px;margin-bottom:8px">
          <el-button size="small" round style="border-color:#007AFF;color:#007AFF" @click="quickAction('check')">查药物相互作用</el-button>
          <el-button size="small" round style="border-color:#4CAF50;color:#4CAF50" @click="quickAction('guide')">服药指南</el-button>
          <el-button size="small" round style="border-color:#FF9500;color:#FF9500" @click="quickAction('stock')">查药箱库存</el-button>
        </div>
        <div style="display:flex;gap:8px">
          <el-input
            v-model="inputText"
            type="textarea"
            :rows="2"
            placeholder="输入你的问题，如：布洛芬能和阿莫西林一起吃吗？"
            @keydown.enter.ctrl="sendMessage"
          />
          <div style="display:flex;flex-direction:column;gap:4px">
            <el-button type="primary" :loading="loading" @click="sendMessage" style="height:50%">发送</el-button>
            <el-button @click="showImageDialog = true" style="height:50%">上传图片</el-button>
          </div>
        </div>
      </div>
    </div>

    <!-- 右侧：历史记录 -->
    <div style="width:280px;overflow-y:auto;padding:16px">
      <h4 style="margin-top:0">问诊历史</h4>
      <div v-for="c in consultations" :key="c.id"
        style="padding:10px;margin-bottom:8px;border:1px solid #e4e7ed;border-radius:6px;cursor:pointer;font-size:13px"
        @click="viewConsultation(c)">
        <div style="color:#409eff;margin-bottom:4px">{{ getTypeLabel(c.type) }}</div>
        <div style="color:#666;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
          {{ c.inputText || '图片分析' }}
        </div>
        <div style="color:#999;font-size:12px;margin-top:4px">
          {{ new Date(c.createdAt).toLocaleString() }}
        </div>
      </div>
      <el-empty v-if="!consultations.length" description="暂无历史" />
    </div>

    <!-- 图片上传对话框 -->
    <el-dialog v-model="showImageDialog" title="上传诊疗单/化验单" width="450px">
      <el-input v-model="imageUrl" placeholder="输入图片URL" style="margin-bottom:12px" />
      <el-input v-model="imageQuestion" type="textarea" :rows="2" placeholder="补充说明(可选)" />
      <template #footer>
        <el-button @click="showImageDialog = false">取消</el-button>
        <el-button type="primary" :loading="loading" @click="analyzeImage">AI分析</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import { useFamilyStore } from '@/stores/family'
import { aiApi } from '@/api/ai'

const familyStore = useFamilyStore()
const selectedMemberId = ref('')
const messages = ref<{ role: string; content: string }[]>([
  { role: 'assistant', content: '你好！我是你的AI药品助手。你可以：\n\n1. 问我药物相互作用（如"布洛芬能和阿莫西林一起吃吗？"）\n2. 上传诊疗单/化验单让我分析\n3. 查询你家药箱的库存情况\n4. 获取药品的服药指南\n\n请问有什么可以帮你的？' },
])
const inputText = ref('')
const loading = ref(false)
const consultations = ref<any[]>([])
const showImageDialog = ref(false)
const imageUrl = ref('')
const imageQuestion = ref('')
const msgContainer = ref<HTMLElement>()

async function sendMessage() {
  if (!inputText.value.trim() || loading.value) return
  if (!selectedMemberId.value) { ElMessage.warning('请先选择家庭成员'); return }

  const text = inputText.value.trim()
  messages.value.push({ role: 'user', content: text })
  inputText.value = ''
  loading.value = true
  scrollToBottom()

  try {
    const res = (await aiApi.chat({
      familyId: familyStore.currentFamilyId,
      memberId: selectedMemberId.value,
      message: text,
    })) as any
    messages.value.push({ role: 'assistant', content: res.reply || '抱歉，暂时无法回答。' })
    loadConsultations()
  } catch (e: any) {
    messages.value.push({ role: 'assistant', content: '出错了: ' + (e.message || '请重试') })
  } finally {
    loading.value = false
    scrollToBottom()
  }
}

async function analyzeImage() {
  if (!imageUrl.value) { ElMessage.warning('请输入图片URL'); return }
  if (!selectedMemberId.value) { ElMessage.warning('请先选择家庭成员'); return }

  messages.value.push({ role: 'user', content: `[上传图片] ${imageQuestion.value || '请分析这张诊疗单'}` })
  showImageDialog.value = false
  loading.value = true
  scrollToBottom()

  try {
    const res = (await aiApi.analyzeImage({
      familyId: familyStore.currentFamilyId,
      memberId: selectedMemberId.value,
      imageUrls: [imageUrl.value],
      question: imageQuestion.value,
    })) as any
    messages.value.push({ role: 'assistant', content: res.reply || '抱歉，无法识别。' })
    loadConsultations()
  } catch (e: any) {
    messages.value.push({ role: 'assistant', content: '分析失败: ' + (e.message || '请重试') })
  } finally {
    loading.value = false
    imageUrl.value = ''
    imageQuestion.value = ''
    scrollToBottom()
  }
}

function quickAction(type: string) {
  switch (type) {
    case 'check':
      inputText.value = '请检查我当前正在服用的所有药物之间是否有相互作用或禁忌。'
      break
    case 'guide':
      inputText.value = '请告诉我当前正在服用的药物的服药指南和注意事项。'
      break
    case 'stock':
      inputText.value = '请查看我家药箱的库存情况，哪些药快用完了？哪些快过期了？'
      break
  }
}

async function loadConsultations() {
  if (!familyStore.currentFamilyId) return
  try {
    consultations.value = (await aiApi.listConsultations(familyStore.currentFamilyId)) as any
  } catch { consultations.value = [] }
}

function viewConsultation(c: any) {
  if (c.resultSummary) {
    messages.value.push({ role: 'user', content: c.inputText || '[图片分析]' })
    messages.value.push({ role: 'assistant', content: c.resultSummary })
    scrollToBottom()
  }
}

function getTypeLabel(type: string) {
  const m: Record<string, string> = {
    prescription_ocr: '单据分析', general_qa: '问答', medication_check: '用药检查', interaction_check: '相互作用',
  }
  return m[type] || '咨询'
}

function scrollToBottom() {
  nextTick(() => {
    if (msgContainer.value) {
      msgContainer.value.scrollTop = msgContainer.value.scrollHeight
    }
  })
}

onMounted(async () => {
  if (!familyStore.families.length) await familyStore.loadFamilies()
  if (!familyStore.members.length) await familyStore.loadMembers()
  if (familyStore.members.length) {
    selectedMemberId.value = familyStore.members[0].id
  }
  await loadConsultations()
})
</script>
