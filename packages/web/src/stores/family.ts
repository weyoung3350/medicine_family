import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { familyApi } from '@/api/family'

export const useFamilyStore = defineStore('family', () => {
  const families = ref<any[]>([])
  const currentFamilyId = ref(localStorage.getItem('currentFamilyId') || '')
  const members = ref<any[]>([])

  const currentFamily = computed(() =>
    families.value.find((f: any) => f.id === currentFamilyId.value)
  )

  async function loadFamilies() {
    families.value = (await familyApi.list()) as any
    if (families.value.length && !currentFamilyId.value) {
      setCurrentFamily(families.value[0].id)
    }
  }

  function setCurrentFamily(id: string) {
    currentFamilyId.value = id
    localStorage.setItem('currentFamilyId', id)
    loadMembers()
  }

  async function loadMembers() {
    if (!currentFamilyId.value) return
    members.value = (await familyApi.listMembers(currentFamilyId.value)) as any
  }

  return { families, currentFamilyId, currentFamily, members, loadFamilies, setCurrentFamily, loadMembers }
})
