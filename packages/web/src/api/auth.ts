import client from './client'

export const authApi = {
  login: (data: { account: string; password: string }) =>
    client.post('/auth/login', data),

  register: (data: { phone: string; nickname: string; password: string; email?: string }) =>
    client.post('/auth/register', data),

  getProfile: () => client.get('/auth/profile'),
}
