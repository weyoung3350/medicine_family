import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'Login',
      component: () => import('@/views/auth/LoginView.vue'),
    },
    {
      path: '/',
      component: () => import('@/components/layout/MainLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          name: 'Dashboard',
          component: () => import('@/views/dashboard/DashboardView.vue'),
        },
        {
          path: 'family',
          name: 'Family',
          component: () => import('@/views/family/FamilyView.vue'),
        },
        {
          path: 'medicine',
          name: 'Medicine',
          component: () => import('@/views/medicine/MedicineView.vue'),
        },
        {
          path: 'medication',
          name: 'Medication',
          component: () => import('@/views/medication/MedicationView.vue'),
        },
        {
          path: 'medical-records',
          name: 'MedicalRecords',
          component: () => import('@/views/medical-record/MedicalRecordView.vue'),
        },
        {
          path: 'pharmacy',
          name: 'Pharmacy',
          component: () => import('@/views/pharmacy/PharmacyView.vue'),
        },
        {
          path: 'ai',
          name: 'AI',
          component: () => import('@/views/ai/AiView.vue'),
        },
        {
          path: 'settings',
          name: 'Settings',
          component: () => import('@/views/settings/SettingsView.vue'),
        },
      ],
    },
  ],
})

router.beforeEach((to, _from, next) => {
  const token = localStorage.getItem('token')
  if (to.meta.requiresAuth && !token) {
    next('/login')
  } else {
    next()
  }
})

export default router
