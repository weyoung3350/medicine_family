import client from './client'

export const familyApi = {
  create: (data: { name: string }) => client.post('/families', data),
  list: () => client.get('/families'),
  getOne: (id: string) => client.get(`/families/${id}`),
  join: (inviteCode: string) => client.post('/families/join', { inviteCode }),
  listMembers: (familyId: string) => client.get(`/families/${familyId}/members`),
  addDependent: (familyId: string, data: any) =>
    client.post(`/families/${familyId}/members`, data),
  getHealth: (familyId: string, memberId: string) =>
    client.get(`/families/${familyId}/members/${memberId}/health`),
  updateHealth: (familyId: string, memberId: string, data: any) =>
    client.put(`/families/${familyId}/members/${memberId}/health`, data),
}
