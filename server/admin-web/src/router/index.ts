import { createRouter, createWebHistory } from 'vue-router'
import { api } from '@/api'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/login', name: 'login', component: () => import('@/views/LoginView.vue'), meta: { public: true, title: '登录' } },
    {
      path: '/',
      component: () => import('@/layouts/AdminLayout.vue'),
      children: [
        { path: '', redirect: { name: 'dashboard' } },
        { path: 'dashboard', name: 'dashboard', component: () => import('@/views/DashboardView.vue'), meta: { title: '仪表盘' } },
        { path: 'stt', name: 'stt', component: () => import('@/views/SttView.vue'), meta: { title: '语音模型' } },
        { path: 'llm', name: 'llm', component: () => import('@/views/LlmView.vue'), meta: { title: '大模型' } },
        { path: 'templates', name: 'templates', component: () => import('@/views/TemplatesView.vue'), meta: { title: '总结模板' } },
        { path: 'releases', name: 'releases', component: () => import('@/views/ReleasesView.vue'), meta: { title: '版本发布' } },
        { path: 'monitor', name: 'monitor', component: () => import('@/views/MonitorView.vue'), meta: { title: '连接监控' } },
        { path: 'users', name: 'users', component: () => import('@/views/UsersView.vue'), meta: { title: '用户管理' } },
        { path: 'auth-settings', name: 'auth-settings', component: () => import('@/views/AuthSettingsView.vue'), meta: { title: '短信与注册' } },
        { path: 'object-storage', name: 'object-storage', component: () => import('@/views/ObjectStorageView.vue'), meta: { title: '对象存储' } },
        { path: 'storage', name: 'storage', component: () => import('@/views/StorageView.vue'), meta: { title: '音频存储' } },
        { path: 'meetings', name: 'meetings', component: () => import('@/views/MeetingsView.vue'), meta: { title: '会议记录' } },
      ],
    },
    { path: '/:pathMatch(.*)*', redirect: { name: 'dashboard' } },
  ],
})

// Session check is cached once per page load; 401 responses later redirect via the HTTP layer.
let authed: boolean | null = null
export function setAuthed(v: boolean) {
  authed = v
}

router.beforeEach(async (to) => {
  if (to.meta.public) return true
  if (authed === null) {
    try {
      await api.me()
      authed = true
    } catch {
      authed = false
    }
  }
  if (!authed) {
    authed = null
    return { name: 'login', query: to.fullPath !== '/' ? { redirect: to.fullPath } : {} }
  }
  return true
})

router.afterEach((to) => {
  const t = to.meta.title as string | undefined
  document.title = t ? `${t} - OpenMeeting 管理端` : 'OpenMeeting 管理端'
})

export default router
