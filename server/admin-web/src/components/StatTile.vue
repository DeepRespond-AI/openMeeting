<template>
  <el-card shadow="never" class="tile">
    <div class="tile-inner">
      <div class="icon" :style="{ background: color + '1a', color }">
        <el-icon :size="22"><component :is="icon" /></el-icon>
      </div>
      <div class="body">
        <div class="label">{{ label }}</div>
        <div class="value">{{ value }}</div>
      </div>
    </div>
  </el-card>
</template>

<script setup lang="ts">
withDefaults(defineProps<{ label: string; value: string | number; icon: string; color?: string }>(), {
  color: '#409eff',
})
</script>

<style scoped>
.tile :deep(.el-card__body) {
  padding: 16px;
}
.tile-inner {
  display: flex;
  align-items: center;
  gap: 14px;
}
.icon {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.label {
  font-size: 13px;
  color: #909399;
}
.value {
  font-size: 22px;
  font-weight: 600;
  margin-top: 2px;
  white-space: nowrap;
}
</style>
