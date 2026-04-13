import { defineStore } from 'pinia'
import { ref } from 'vue'
import { authApi } from '@/api/auth'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<any>(null)
  const token = ref(localStorage.getItem('token') || '')

  async function login(account: string, password: string) {
    const res: any = await authApi.login({ account, password })
    token.value = res.access_token
    user.value = res.user
    localStorage.setItem('token', res.access_token)
    return res
  }

  async function register(data: { phone: string; nickname: string; password: string }) {
    const res: any = await authApi.register(data)
    token.value = res.access_token
    user.value = res.user
    localStorage.setItem('token', res.access_token)
    return res
  }

  async function fetchProfile() {
    user.value = await authApi.getProfile()
  }

  function logout() {
    token.value = ''
    user.value = null
    localStorage.removeItem('token')
  }

  return { user, token, login, register, fetchProfile, logout }
})
