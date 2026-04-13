<template>
  <el-container class="layout-container">
    <el-aside width="248px" class="aside">
      <div class="glass-overlay"></div>
      <div class="aside-content">
        <div class="logo">
          <img src="/logo.svg" alt="Logo" class="logo-img" />
          <div>
            <h2>药品管家</h2>
            <p class="logo-subtitle">家庭用药协同中心</p>
          </div>
        </div>
        <div class="sidebar-status">
          <span class="status-dot"></span>
          <span>今日提醒已同步</span>
        </div>
        <el-menu
          :default-active="route.path"
          router
          class="sidebar-menu"
          background-color="transparent"
          text-color="#B9CCD0"
          active-text-color="#FFFFFF"
        >
          <el-menu-item index="/">
            <el-icon><House /></el-icon>
            <span>首页概览</span>
          </el-menu-item>
          <el-menu-item index="/family">
            <el-icon><User /></el-icon>
            <span>家庭管理</span>
          </el-menu-item>
          <el-menu-item index="/medicine">
            <el-icon><Box /></el-icon>
            <span>药箱管理</span>
          </el-menu-item>
          <el-menu-item index="/medication">
            <el-icon><Clock /></el-icon>
            <span>服药管理</span>
          </el-menu-item>
          <el-menu-item index="/medical-records">
            <el-icon><Document /></el-icon>
            <span>病历管理</span>
          </el-menu-item>
          <el-menu-item index="/pharmacy">
            <el-icon><MapLocation /></el-icon>
            <span>附近药店</span>
          </el-menu-item>
          <el-menu-item index="/ai">
            <el-icon><ChatDotRound /></el-icon>
            <span>AI 助手</span>
          </el-menu-item>
          <el-menu-item index="/settings">
            <el-icon><Setting /></el-icon>
            <span>设置</span>
          </el-menu-item>
        </el-menu>

        <div class="sidebar-footer">
          <div class="user-info">
            <el-avatar :size="40" class="user-avatar">
              {{ authStore.user?.nickname?.charAt(0) || 'U' }}
            </el-avatar>
            <div class="user-detail">
              <span class="user-name">{{ authStore.user?.nickname || '家庭成员' }}</span>
              <span class="user-phone">{{ authStore.user?.phone || '未绑定手机号' }}</span>
            </div>
          </div>
        </div>
      </div>
    </el-aside>

    <el-container>
      <el-header class="header">
        <div class="header-left">
          <h3 class="page-title">{{ pageTitle }}</h3>
          <p class="page-subtitle">用药、库存、家庭成员状态集中管理</p>
        </div>
        <div class="header-right">
          <el-dropdown @command="handleCommand">
            <span class="user-dropdown">
              {{ authStore.user?.nickname }}
              <el-icon><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="settings">设置</el-dropdown-item>
                <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>
      <el-main class="main-content">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { House, User, Box, Clock, Document, MapLocation, ChatDotRound, Setting, ArrowDown } from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const pageTitle = computed(() => {
  const map: Record<string, string> = {
    '/': '首页概览', '/family': '家庭管理', '/medicine': '药箱管理',
    '/medication': '服药管理', '/medical-records': '病历管理',
    '/pharmacy': '附近药店', '/ai': 'AI 助手', '/settings': '设置',
  }
  return map[route.path] || ''
})

function handleCommand(cmd: string) {
  if (cmd === 'logout') {
    authStore.logout()
    router.push('/login')
  } else if (cmd === 'settings') {
    router.push('/settings')
  }
}

onMounted(() => {
  if (authStore.token && !authStore.user) {
    authStore.fetchProfile()
  }
})
</script>

<style scoped>
.layout-container {
  height: 100vh;
  background: transparent;
}

/* 侧边栏 - 毛玻璃 + 深蓝背景 */
.aside {
  position: relative;
  overflow: hidden;
  box-shadow: 18px 0 50px rgba(9, 38, 49, 0.16);
}

/* 底层渐变背景 */
.aside::before {
  content: '';
  position: absolute;
  inset: 0;
  background: var(--sidebar-bg);
  z-index: 0;
}

/* 装饰光斑 */
.aside::after {
  content: '';
  position: absolute;
  top: -70px;
  right: -80px;
  width: 220px;
  height: 220px;
  background: radial-gradient(circle, rgba(88, 214, 200, 0.26) 0%, transparent 68%);
  z-index: 0;
}

/* 毛玻璃覆盖层 */
.glass-overlay {
  position: absolute;
  inset: 0;
  background:
    linear-gradient(140deg, rgba(255, 255, 255, 0.08), transparent 42%),
    rgba(255, 255, 255, 0.03);
  backdrop-filter: blur(20px) saturate(1.2);
  -webkit-backdrop-filter: blur(20px) saturate(1.2);
  z-index: 1;
}

/* 内容层 */
.aside-content {
  position: relative;
  z-index: 2;
  display: flex;
  flex-direction: column;
  height: 100%;
}

.logo {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 26px 22px 18px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}
.logo-img {
  width: 50px;
  height: 50px;
  filter: drop-shadow(0 10px 22px rgba(88, 214, 200, 0.3));
  transition: transform 0.3s;
}
.logo-img:hover {
  transform: scale(1.1) rotate(5deg);
}
.logo h2 {
  color: #FFFFFF;
  margin: 0;
  font-size: 21px;
  letter-spacing: 1px;
}
.logo-subtitle {
  color: rgba(217, 238, 238, 0.72);
  font-size: 12px;
  margin: 5px 0 0;
}

.sidebar-status {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 16px 16px 8px;
  padding: 12px 14px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 16px;
  color: rgba(235, 250, 248, 0.84);
  font-size: 13px;
  background: rgba(255, 255, 255, 0.07);
}

.status-dot {
  width: 9px;
  height: 9px;
  border-radius: 50%;
  background: #58D6C8;
  box-shadow: 0 0 0 6px rgba(88, 214, 200, 0.12);
}

/* 菜单 */
.sidebar-menu {
  border-right: none !important;
  flex: 1;
  padding: 8px 10px;
}
.sidebar-menu .el-menu-item {
  height: 50px;
  line-height: 50px;
  margin: 5px 0;
  border-radius: 16px;
  font-size: 14px;
  transition: all 0.25s ease;
}
.sidebar-menu .el-menu-item:hover {
  background: rgba(255, 255, 255, 0.1) !important;
  color: #FFFFFF !important;
  transform: translateX(2px);
}
.sidebar-menu .el-menu-item.is-active {
  background: linear-gradient(135deg, rgba(88, 214, 200, 0.26), rgba(255, 255, 255, 0.08)) !important;
  color: #FFFFFF !important;
  font-weight: 600;
  box-shadow: 0 12px 24px rgba(0, 0, 0, 0.16);
}

/* 底部用户信息 */
.sidebar-footer {
  padding: 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.06);
  background: rgba(0, 0, 0, 0.1);
  backdrop-filter: blur(10px);
}
.user-avatar {
  background: linear-gradient(135deg, #58D6C8, #0F7C9A);
  color: #FFFFFF;
  font-weight: 700;
}
.user-info {
  display: flex;
  align-items: center;
  gap: 10px;
}
.user-detail {
  display: flex;
  flex-direction: column;
}
.user-name {
  color: #ECEFF1;
  font-size: 14px;
  font-weight: 500;
}
.user-phone {
  color: rgba(176, 190, 197, 0.6);
  font-size: 12px;
}

/* 顶栏 - 毛玻璃 */
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: rgba(249, 253, 251, 0.78);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
  border-bottom: 1px solid rgba(16, 73, 87, 0.08);
  padding: 0 30px;
  height: 72px;
}
.header-left {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.page-title {
  margin: 0;
  font-size: 20px;
  color: var(--text-primary);
  font-weight: 700;
}
.page-subtitle {
  margin: 0;
  color: var(--text-secondary);
  font-size: 12px;
}
.header-right {
  display: flex;
  align-items: center;
  gap: 16px;
}
.user-dropdown {
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  color: var(--text-secondary);
  font-size: 14px;
  transition: color 0.2s;
}
.user-dropdown:hover {
  color: var(--primary);
}

/* 主内容区 */
.main-content {
  position: relative;
  background: transparent;
  padding: 28px 30px;
  overflow: auto;
}

@media (max-width: 900px) {
  .aside {
    display: none;
  }

  .header {
    padding: 0 18px;
  }

  .page-subtitle {
    display: none;
  }

  .main-content {
    padding: 18px;
  }
}
</style>
