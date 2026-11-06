<template>
  <el-container class="layout">
    <el-aside :width="collapsed ? '64px' : '208px'" class="aside">
      <div class="brand" @click="router.push({ name: 'dashboard' })">
        <el-icon :size="22"><Microphone /></el-icon>
        <span v-show="!collapsed">OpenMeeting 管理端</span>
      </div>
      <el-menu
        :default-active="String(route.name)"
        :collapse="collapsed"
        background-color="#001529"
        text-color="#c0c4cc"
        active-text-color="#ffffff"
        router
        class="menu"
      >
        <el-menu-item v-for="m in menus" :key="m.name" :index="m.name" :route="{ name: m.name }">
          <el-icon><component :is="m.icon" /></el-icon>
          <template #title><span>{{ m.title }}</span></template>
        </el-menu-item>
      </el-menu>
    </el-aside>
    <el-container>
      <el-header class="header">
        <div class="header-left">
          <el-button text @click="collapsed = !collapsed">
            <el-icon :size="18"><component :is="collapsed ? 'Expand' : 'Fold'" /></el-icon>
          </el-button>
          <span class="crumb">{{ route.meta.title }}</span>
        </div>
        <div class="header-right">
          <el-tooltip :content="sseConnected ? '实时推送已连接' : '实时推送未连接（使用轮询）'">
            <span class="sse"><span class="dot" :class="sseConnected ? 'on' : 'off'" />实时</span>
          </el-tooltip>
          <el-button text type="danger" @click="logout">
            <el-icon><SwitchButton /></el-icon>
            <span>退出登录</span>
          </el-button>
        </div>
      </el-header>
      <el-main class="main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessageBox } from 'element-plus'
import { api } from '@/api'
import { setAuthed } from '@/router'
import { sseConnected } from '@/composables/useEvents'

const route = useRoute()
const router = useRouter()
const collapsed = ref(window.innerWidth < 900)

const menus = [
  { name: 'dashboard', title: '仪表盘', icon: 'Odometer' },
  { name: 'stt', title: '语音模型', icon: 'Microphone' },
  { name: 'llm', title: '大模型', icon: 'MagicStick' },
  { name: 'templates', title: '总结模板', icon: 'Tickets' },
  { name: 'releases', title: '版本发布', icon: 'Promotion' },
  { name: 'monitor', title: '连接监控', icon: 'Monitor' },
  { name: 'users', title: '用户管理', icon: 'User' },
  { name: 'auth-settings', title: '短信与注册', icon: 'Message' },
  { name: 'object-storage', title: '对象存储', icon: 'Box' },
  { name: 'storage', title: '音频存储', icon: 'Files' },
  { name: 'meetings', title: '会议记录', icon: 'Document' },
]

function onResize() {
  if (window.innerWidth < 900) collapsed.value = true
}
onMounted(() => window.addEventListener('resize', onResize))
onBeforeUnmount(() => window.removeEventListener('resize', onResize))

async function logout() {
  try {
    await ElMessageBox.confirm('确定退出登录？', '提示', { type: 'warning' })
  } catch {
    return
  }
  try {
    await api.logout()
  } catch {
    /* ignore */
  }
  setAuthed(false)
  router.replace({ name: 'login' })
}
</script>

<style scoped>
.layout {
  height: 100vh;
}
.aside {
  background: #001529;
  transition: width 0.2s;
  overflow-x: hidden;
  display: flex;
  flex-direction: column;
}
.brand {
  height: 56px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  color: #fff;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  white-space: nowrap;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}
.menu {
  border-right: none;
  flex: 1;
}
.menu:not(.el-menu--collapse) {
  width: 208px;
}
.header {
  height: 56px;
  background: #fff;
  border-bottom: 1px solid #ebeef5;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 12px;
}
.header-left,
.header-right {
  display: flex;
  align-items: center;
  gap: 8px;
}
.crumb {
  font-weight: 600;
}
.sse {
  font-size: 12px;
  color: #909399;
  margin-right: 8px;
}
.main {
  padding: 20px;
  overflow-y: auto;
}
@media (max-width: 600px) {
  .main {
    padding: 12px;
  }
}
</style>
