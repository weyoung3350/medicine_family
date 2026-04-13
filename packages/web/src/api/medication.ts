import client from './client'

export const medicationApi = {
  createPlan: (familyId: string, memberId: string, data: any) =>
    client.post(`/families/${familyId}/members/${memberId}/plans`, data),
  listPlans: (familyId: string, memberId: string) =>
    client.get(`/families/${familyId}/members/${memberId}/plans`),
  getToday: (familyId: string, memberId: string) =>
    client.get(`/families/${familyId}/members/${memberId}/plans/today`),
  checkIn: (familyId: string, memberId: string, planId: string, scheduleId: string, data?: any) =>
    client.post(`/families/${familyId}/members/${memberId}/plans/${planId}/schedules/${scheduleId}/check-in`, data),
  getAdherence: (familyId: string, memberId: string, range?: string) =>
    client.get(`/families/${familyId}/members/${memberId}/plans/adherence`, { params: { range } }),
}
