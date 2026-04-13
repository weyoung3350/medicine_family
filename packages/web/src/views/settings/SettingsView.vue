<template>
  <div>
    <h2>设置</h2>
    <el-card style="max-width:600px">
      <template #header>账号信息</template>
      <el-descriptions :column="1" border>
        <el-descriptions-item label="昵称">{{ authStore.user?.nickname }}</el-descriptions-item>
        <el-descriptions-item label="手机号">{{ authStore.user?.phone || '-' }}</el-descriptions-item>
        <el-descriptions-item label="邮箱">{{ authStore.user?.email || '-' }}</el-descriptions-item>
        <el-descriptions-item label="注册时间">{{ authStore.user?.createdAt ? new Date(authStore.user.createdAt).toLocaleDateString() : '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card style="max-width:600px;margin-top:20px">
      <template #header>系统信息</template>
      <el-descriptions :column="1" border>
        <el-descriptions-item label="后端地址">http://localhost:3000</el-descriptions-item>
        <el-descriptions-item label="API文档">
          <a href="/api/docs" target="_blank">Swagger UI</a>
        </el-descriptions-item>
        <el-descriptions-item label="AI模型">千问 Qwen (Vision + Function Calling)</el-descriptions-item>
        <el-descriptions-item label="版本">1.0.0</el-descriptions-item>
      </el-descriptions>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
const authStore = useAuthStore()
</script>
