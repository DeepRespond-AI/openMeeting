<template>
  <div class="gauge">
    <el-progress type="dashboard" :percentage="pct" :color="progressColor(pct)" :width="120">
      <template #default>
        <div class="pct">{{ pct.toFixed(pct >= 10 ? 0 : 1) }}%</div>
        <div class="name">{{ label }}</div>
      </template>
    </el-progress>
    <div class="detail muted">{{ detail }}</div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { progressColor } from '@/utils'

const props = defineProps<{ label: string; percent: number; detail?: string }>()
const pct = computed(() => Math.max(0, Math.min(100, Number(props.percent) || 0)))
</script>

<style scoped>
.gauge {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 130px;
}
.pct {
  font-size: 20px;
  font-weight: 600;
}
.name {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
}
.detail {
  font-size: 12px;
  margin-top: 4px;
  text-align: center;
}
</style>
