import client from './client'

export const aiApi = {
  chat: (data: { familyId: string; memberId: string; message: string; images?: string[] }) =>
    client.post('/ai/chat', data),
  analyzeImage: (data: { familyId: string; memberId: string; imageUrls: string[]; question?: string }) =>
    client.post('/ai/analyze-image', data),
  medicationCheck: (data: { familyId: string; memberId: string; drugNames: string[] }) =>
    client.post('/ai/medication-check', data),
  getMedicationGuide: (data: { medicineId: string; memberId: string; familyId: string }) =>
    client.post('/ai/medication-guide', data),
  listConsultations: (familyId: string) =>
    client.get('/ai/consultations', { params: { familyId } }),
}
