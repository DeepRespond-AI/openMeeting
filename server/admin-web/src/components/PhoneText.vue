<template>
  <span v-if="!phone" class="muted">-</span>
  <span v-else class="phone">
    <el-tooltip :content="phone" placement="top">
      <span class="mono">{{ revealed ? phone : maskPhone(phone) }}</span>
    </el-tooltip>
    <el-icon class="eye" :title="revealed ? '隐藏' : '显示完整号码'" @click.stop="revealed = !revealed">
      <component :is="revealed ? 'Hide' : 'View'" />
    </el-icon>
  </span>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { maskPhone } from '@/utils'

defineProps<{ phone: string | null | undefined }>()
const revealed = ref(false)
</script>

<style scoped>
.phone {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}
.phone .mono {
  font-size: 13px;
}
.eye {
  cursor: pointer;
  color: #909399;
}
.eye:hover {
  color: #409eff;
}
</style>
