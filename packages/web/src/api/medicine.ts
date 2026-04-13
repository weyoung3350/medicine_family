import client from './client'

export const medicineApi = {
  ocr: (familyId: string, imageUrl: string) =>
    client.post(`/families/${familyId}/medicines/ocr`, { imageUrl }),
  create: (familyId: string, data: any) =>
    client.post(`/families/${familyId}/medicines`, data),
  list: (familyId: string, params?: { keyword?: string; category?: string }) =>
    client.get(`/families/${familyId}/medicines`, { params }),
  getOne: (familyId: string, id: string) =>
    client.get(`/families/${familyId}/medicines/${id}`),
  addInventory: (familyId: string, medicineId: string, data: any) =>
    client.post(`/families/${familyId}/medicines/${medicineId}/inventory`, data),
  getExpiring: (familyId: string) =>
    client.get(`/families/${familyId}/medicines/expiring`),
  getLowStock: (familyId: string) =>
    client.get(`/families/${familyId}/medicines/low-stock`),
}
