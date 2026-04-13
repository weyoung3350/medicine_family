import client from './client'

export const medicalRecordApi = {
  ocr: (familyId: string, imageUrl: string) =>
    client.post(`/families/${familyId}/medical-records/ocr`, { imageUrl }),
  create: (familyId: string, data: any) =>
    client.post(`/families/${familyId}/medical-records`, data),
  list: (familyId: string, params?: { memberId?: string; keyword?: string }) =>
    client.get(`/families/${familyId}/medical-records`, { params }),
  getOne: (familyId: string, id: string) =>
    client.get(`/families/${familyId}/medical-records/${id}`),
  update: (familyId: string, id: string, data: any) =>
    client.put(`/families/${familyId}/medical-records/${id}`, data),
  remove: (familyId: string, id: string) =>
    client.delete(`/families/${familyId}/medical-records/${id}`),
}
