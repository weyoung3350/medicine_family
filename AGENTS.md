# 家庭健康管家 (Medicine Family)

## 项目概述
一个面向家庭的智能药品管理系统，支持药品OCR录入、库存追踪、服药提醒打卡、AI问诊分析等功能。

## 技术栈
- **后端**: Node.js + NestJS + TypeORM + PostgreSQL + Redis
- **Web前端**: Vue 3 + Vite + Pinia + Element Plus + ECharts
- **移动端**: Flutter (Android/iOS)
- **AI**: 阿里千问 Qwen API (Vision + Function Calling)
- **包管理**: pnpm monorepo

## 目录结构
```
med-family/
├── packages/
│   ├── backend/     # NestJS 后端 API
│   ├── web/         # Vue 3 Web 前端
│   └── mobile/      # Flutter 移动端
├── docker/          # Docker Compose (PG + Redis)
└── AGENTS.md        # 本文件
```

## 后端模块
- `auth` — JWT认证、注册登录
- `family` — 家庭组、成员管理、健康档案
- `medicine` — 药品CRUD、库存管理、OCR识别
- `medication` — 服药计划、打卡、依从性统计
- `medical-record` — 病历管理、病历OCR识别（千问Vision）
- `pharmacy` — 附近药店搜索（高德地图API）
- `ai` — 千问API调用、Function Calling、问诊记录
- `notification` — 推送通知 (FCM/极光)
- `scheduler` — 定时任务 (服药提醒/临期检查/漏服检测)

## API规范
- 所有API前缀: `/api/v1/`
- 认证: Bearer JWT Token
- 响应格式: JSON
- API文档: http://localhost:3000/api/docs (Swagger)

## 数据库
PostgreSQL 16，核心表:
user, family, family_member, health_profile, medicine, medicine_inventory,
medication_plan, medication_schedule, medication_log, medical_record, ai_consultation

## 开发环境启动
```bash
# 启动数据库
cd docker && docker-compose up -d

# 安装依赖
pnpm install

# 启动后端 (端口3000)
pnpm dev:backend

# 启动Web前端 (端口5173)
pnpm dev:web
```

## 代码规范
- TypeScript strict mode
- NestJS 模块化架构，每个功能一个module
- Vue 3 Composition API + `<script setup>`
- 数据库字段命名: snake_case
- TypeScript属性命名: camelCase
- API路径: kebab-case
