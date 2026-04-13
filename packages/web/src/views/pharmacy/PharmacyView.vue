<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px">
      <h2 style="margin:0">附近药店</h2>
      <div style="display:flex;align-items:center;gap:12px">
        <el-input v-model="searchKeyword" placeholder="搜索关键词" style="width:160px" clearable @keyup.enter="searchPharmacies" />
        <el-select v-model="searchRadius" style="width:120px" @change="searchPharmacies">
          <el-option label="1公里内" :value="1000" />
          <el-option label="3公里内" :value="3000" />
          <el-option label="5公里内" :value="5000" />
          <el-option label="10公里内" :value="10000" />
        </el-select>
        <el-button type="primary" :loading="locating" @click="getLocation">
          <el-icon><Location /></el-icon> 重新定位
        </el-button>
      </div>
    </div>

    <el-row :gutter="16">
      <!-- 地图区域 -->
      <el-col :span="16">
        <el-card shadow="never" style="height:600px">
          <div ref="mapContainer" style="width:100%;height:100%"></div>
        </el-card>
      </el-col>

      <!-- 药店列表 -->
      <el-col :span="8">
        <el-card shadow="never" style="height:600px;overflow:auto">
          <template #header>
            <div style="display:flex;justify-content:space-between;align-items:center">
              <strong>搜索结果</strong>
              <el-tag size="small">{{ pharmacies.length }} 家</el-tag>
            </div>
          </template>

          <div v-if="loading" style="text-align:center;padding:40px">
            <el-icon class="is-loading" :size="24"><Loading /></el-icon>
            <p style="color:#999;margin-top:8px">搜索中...</p>
          </div>

          <div v-else-if="!pharmacies.length" style="text-align:center;padding:40px;color:#999">
            {{ locationError || '暂无结果，请先定位' }}
          </div>

          <div v-else>
            <div
              v-for="(p, i) in pharmacies" :key="p.id"
              class="pharmacy-item"
              :class="{ active: selectedId === p.id }"
              @click="selectPharmacy(p)"
            >
              <div style="display:flex;align-items:flex-start;gap:10px">
                <div class="pharmacy-index">{{ i + 1 }}</div>
                <div style="flex:1;min-width:0">
                  <div style="font-weight:600;margin-bottom:4px">{{ p.name }}</div>
                  <div style="color:#666;font-size:13px;margin-bottom:2px">{{ p.address }}</div>
                  <div v-if="p.tel" style="color:#409eff;font-size:13px">{{ p.tel }}</div>
                </div>
                <el-tag size="small" type="info">{{ formatDistance(p.distance) }}</el-tag>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import { Location, Loading } from '@element-plus/icons-vue'
import { pharmacyApi } from '@/api/pharmacy'

const mapContainer = ref<HTMLElement>()
const pharmacies = ref<any[]>([])
const loading = ref(false)
const locating = ref(false)
const selectedId = ref('')
const searchKeyword = ref('药店')
const searchRadius = ref(3000)
const locationError = ref('')

let map: any = null
let markers: any[] = []
let currentLng = 0
let currentLat = 0

function formatDistance(d: number) {
  return d >= 1000 ? `${(d / 1000).toFixed(1)}km` : `${Math.round(d)}m`
}

async function loadAmapScript(): Promise<void> {
  if ((window as any).AMap) return

  // 设置安全密钥
  const securityKey = import.meta.env.VITE_AMAP_JS_SECRET || ''
  if (securityKey) {
    (window as any)._AMapSecurityConfig = { securityJsCode: securityKey }
  }

  return new Promise((resolve, reject) => {
    const script = document.createElement('script')
    script.src = `https://webapi.amap.com/maps?v=2.0&key=${import.meta.env.VITE_AMAP_JS_KEY || ''}`
    script.onload = () => resolve()
    script.onerror = () => reject(new Error('高德地图加载失败'))
    document.head.appendChild(script)
  })
}

async function initMap(lng: number, lat: number) {
  await loadAmapScript()
  const AMap = (window as any).AMap
  await nextTick()

  if (map) {
    map.setCenter([lng, lat])
    return
  }

  map = new AMap.Map(mapContainer.value, {
    zoom: 14,
    center: [lng, lat],
  })

  // 添加当前位置标记
  new AMap.Marker({
    position: [lng, lat],
    map,
    icon: new AMap.Icon({
      size: new AMap.Size(24, 24),
      image: 'https://webapi.amap.com/theme/v1.3/markers/n/mark_bs.png',
      imageSize: new AMap.Size(24, 24),
    }),
    title: '我的位置',
  })
}

function addMarkers(list: any[]) {
  const AMap = (window as any).AMap
  // 清除旧标记
  markers.forEach(m => map.remove(m))
  markers = []

  list.forEach((p, i) => {
    const marker = new AMap.Marker({
      position: [p.location.lng, p.location.lat],
      map,
      label: {
        content: `<div style="background:#409eff;color:#fff;padding:2px 6px;border-radius:4px;font-size:12px;white-space:nowrap">${i + 1}. ${p.name}</div>`,
        direction: 'top',
      },
    })
    marker.on('click', () => selectPharmacy(p))
    markers.push(marker)
  })

  if (list.length) {
    map.setFitView(markers, false, [60, 60, 60, 60])
  }
}

function selectPharmacy(p: any) {
  selectedId.value = p.id
  if (map) {
    map.setCenter([p.location.lng, p.location.lat])
    map.setZoom(16)
  }
}

async function getLocation() {
  locating.value = true
  locationError.value = ''
  try {
    const pos = await new Promise<GeolocationPosition>((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(resolve, reject, {
        enableHighAccuracy: true,
        timeout: 10000,
      })
    })
    currentLng = pos.coords.longitude
    currentLat = pos.coords.latitude
    await initMap(currentLng, currentLat)
    await searchPharmacies()
  } catch (e: any) {
    locationError.value = '定位失败，请检查定位权限'
    ElMessage.error('定位失败，请允许浏览器获取位置权限')
  } finally {
    locating.value = false
  }
}

async function searchPharmacies() {
  if (!currentLng || !currentLat) {
    ElMessage.warning('请先完成定位')
    return
  }
  loading.value = true
  try {
    const result = (await pharmacyApi.searchNearby({
      lng: currentLng,
      lat: currentLat,
      radius: searchRadius.value,
      keyword: searchKeyword.value || '药店',
    })) as any
    pharmacies.value = result
    addMarkers(result)
    if (!result.length) {
      ElMessage.info('附近没有找到药店')
    }
  } catch (e: any) {
    ElMessage.error('搜索失败: ' + (e.message || '请重试'))
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  getLocation()
})

onUnmounted(() => {
  if (map) {
    map.destroy()
    map = null
  }
})
</script>

<style scoped>
.pharmacy-item {
  padding: 12px;
  border-bottom: 1px solid #f0f0f0;
  cursor: pointer;
  transition: background 0.2s;
  border-radius: 8px;
  margin-bottom: 4px;
}
.pharmacy-item:hover,
.pharmacy-item.active {
  background: #ecf5ff;
}
.pharmacy-index {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #409eff;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  flex-shrink: 0;
  margin-top: 2px;
}
</style>
