<template>
  <div class="login-container">
    <div class="login-card glass-card">
      <img src="/logo.svg" alt="Logo" style="width:56px;height:56px;margin:0 auto 12px;display:block" />
      <h2 class="title">药品管家</h2>
      <p style="text-align:center;color:#607D8B;margin:-4px 0 20px;font-size:13px">智能家庭用药管理系统</p>
      <el-tabs v-model="activeTab">
        <el-tab-pane label="登录" name="login">
          <el-form :model="loginForm" @submit.prevent="handleLogin">
            <el-form-item>
              <el-input v-model="loginForm.account" placeholder="手机号或邮箱" size="large" />
            </el-form-item>
            <el-form-item>
              <el-input v-model="loginForm.password" type="password" placeholder="密码" size="large" show-password />
            </el-form-item>
            <el-button type="primary" size="large" style="width: 100%" :loading="loading" @click="handleLogin">
              登录
            </el-button>
          </el-form>
        </el-tab-pane>

        <el-tab-pane label="注册" name="register">
          <el-form :model="registerForm" @submit.prevent="handleRegister">
            <el-form-item>
              <el-input v-model="registerForm.phone" placeholder="手机号" size="large" />
            </el-form-item>
            <el-form-item>
              <el-input v-model="registerForm.nickname" placeholder="昵称" size="large" />
            </el-form-item>
            <el-form-item>
              <el-input v-model="registerForm.password" type="password" placeholder="密码(至少6位)" size="large" show-password />
            </el-form-item>
            <el-button type="primary" size="large" style="width: 100%" :loading="loading" @click="handleRegister">
              注册
            </el-button>
          </el-form>
        </el-tab-pane>
      </el-tabs>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const loading = ref(false)
const activeTab = ref('login')

const loginForm = reactive({ account: '', password: '' })
const registerForm = reactive({ phone: '', nickname: '', password: '' })

async function handleLogin() {
  if (!loginForm.account || !loginForm.password) {
    ElMessage.warning('请填写完整信息')
    return
  }
  loading.value = true
  try {
    await authStore.login(loginForm.account, loginForm.password)
    ElMessage.success('登录成功')
    router.push('/')
  } catch (e: any) {
    ElMessage.error(e.message || '登录失败')
  } finally {
    loading.value = false
  }
}

async function handleRegister() {
  if (!registerForm.phone || !registerForm.nickname || !registerForm.password) {
    ElMessage.warning('请填写完整信息')
    return
  }
  loading.value = true
  try {
    await authStore.register(registerForm)
    ElMessage.success('注册成功')
    router.push('/')
  } catch (e: any) {
    ElMessage.error(e.message || '注册失败')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-container {
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #0D1B2A 0%, #1B2A4A 40%, #1a3a5c 100%);
  position: relative;
  overflow: hidden;
}
/* 装饰光斑 */
.login-container::before {
  content: '';
  position: absolute;
  width: 500px;
  height: 500px;
  top: -100px;
  right: -100px;
  background: radial-gradient(circle, rgba(0, 122, 255, 0.25) 0%, transparent 70%);
  animation: drift 8s ease-in-out infinite alternate;
}
.login-container::after {
  content: '';
  position: absolute;
  width: 400px;
  height: 400px;
  bottom: -80px;
  left: -80px;
  background: radial-gradient(circle, rgba(76, 175, 80, 0.15) 0%, transparent 70%);
  animation: drift 10s ease-in-out infinite alternate-reverse;
}
@keyframes drift {
  0% { transform: translate(0, 0); }
  100% { transform: translate(30px, -20px); }
}

/* 毛玻璃登录卡片 */
.glass-card {
  width: 420px;
  padding: 36px 32px;
  border-radius: 20px;
  position: relative;
  z-index: 1;
  background: rgba(255, 255, 255, 0.12);
  backdrop-filter: blur(24px) saturate(1.4);
  -webkit-backdrop-filter: blur(24px) saturate(1.4);
  border: 1px solid rgba(255, 255, 255, 0.15);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}
.title {
  text-align: center;
  margin-bottom: 8px;
  color: #FFFFFF;
  font-size: 24px;
  font-weight: 600;
  letter-spacing: 2px;
}
/* 覆盖 Element Plus 在毛玻璃上的输入框样式 */
.glass-card :deep(.el-input__wrapper) {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: none;
}
.glass-card :deep(.el-input__inner) {
  color: #FFFFFF;
}
.glass-card :deep(.el-input__inner::placeholder) {
  color: rgba(255, 255, 255, 0.5);
}
.glass-card :deep(.el-tabs__item) {
  color: rgba(255, 255, 255, 0.6);
}
.glass-card :deep(.el-tabs__item.is-active) {
  color: #FFFFFF;
}
.glass-card :deep(.el-tabs__active-bar) {
  background: #007AFF;
}
.glass-card :deep(.el-tabs__nav-wrap::after) {
  background: rgba(255, 255, 255, 0.1);
}
.glass-card :deep(.el-button--primary) {
  background: #007AFF;
  border-color: #007AFF;
  font-size: 16px;
  height: 44px;
  border-radius: 10px;
}
.glass-card :deep(.el-button--primary:hover) {
  background: #0056CC;
}
</style>
