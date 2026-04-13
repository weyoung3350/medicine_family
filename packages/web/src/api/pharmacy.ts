import client from './client'

export const pharmacyApi = {
  searchNearby: (params: { lng: number; lat: number; radius?: number; keyword?: string }) =>
    client.get('/pharmacy/nearby', { params }),
}
