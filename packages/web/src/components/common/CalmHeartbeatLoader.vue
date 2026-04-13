<template>
  <span class="calm-loader" :style="{ width: `${size}px`, height: `${size}px` }" :aria-label="label" role="status">
    <span ref="containerRef" class="calm-loader__animation"></span>
  </span>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import lottie from 'lottie-web/build/player/lottie_light'
import type { AnimationItem } from 'lottie-web'
import heartbeatAnimation from '@/assets/lottie/calm-heartbeat.json'

withDefaults(defineProps<{
  size?: number
  label?: string
}>(), {
  size: 28,
  label: '加载中',
})

const containerRef = ref<HTMLElement>()
let animation: AnimationItem | undefined

onMounted(() => {
  if (!containerRef.value) return
  animation = lottie.loadAnimation({
    container: containerRef.value,
    renderer: 'svg',
    loop: true,
    autoplay: true,
    animationData: heartbeatAnimation,
  })
  animation.setSpeed(0.72)
})

onBeforeUnmount(() => {
  animation?.destroy()
})
</script>

<style scoped>
.calm-loader {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
  overflow: hidden;
  vertical-align: middle;
}

.calm-loader__animation {
  display: block;
  width: 100%;
  height: 100%;
}
</style>
