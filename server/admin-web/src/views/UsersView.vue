<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h2>用户管理</h2>
        <div class="sub">用户通过手机号 + 短信验证码登录桌面客户端，数据按用户隔离。</div>
      </div>
      <div class="toolbar">
        <el-input
          v-model="q"
          placeholder="搜索手机号 / 昵称"
          clearable
          :prefix-icon="Search"
          style="width: 200px"
          @keyup.enter="search"
          @clear="search"
        />
        <el-select v-model="status" placeholder="全部状态" clearable style="width: 120px" @change="search">
          <el-option label="启用" value="active" />
          <el-option label="禁用" value="disabled" />
        </el-select>
        <el-button type="primary" @click="search">搜索</el-button>
        <el-button :icon="Refresh" :loading="loading" @click="load">刷新</el-button>
        <el-button type="primary" plain :icon="Plus" @click="openCreate">新增用户</el-button>
      </div>
    </div>

    <el-card shadow="never">
      <el-table :data="items" stripe v-loading="loading" empty-text="暂无用户" :row-key="(r: AdminUser) => r.id">
        <el-table-column label="手机号" min-width="150">
          <template #default="{ row }">
            <PhoneText :phone="row.phone" />
          </template>
        </el-table-column>
        <el-table-column prop="name" label="昵称" min-width="110" show-overflow-tooltip />
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-switch
              :model-value="!row.disabled"
              :loading="togglingId === row.id"
              inline-prompt
              active-text="启用"
              inactive-text="禁用"
              @change="(v: string | number | boolean) => toggleUser(row as AdminUser, !v)"
            />
          </template>
        </el-table-column>
        <el-table-column label="在线" width="70" align="center">
          <template #default="{ row }">
            <el-tooltip :content="row.online ? '在线' : '离线'">
              <span class="dot" :class="row.online ? 'on' : 'off'" />
            </el-tooltip>
          </template>
        </el-table-column>
        <el-table-column label="注册时间" width="165">
          <template #default="{ row }">{{ formatDateTime(row.created_at) }}</template>
        </el-table-column>
        <el-table-column label="最近登录" width="110">
          <template #default="{ row }">
            <el-tooltip :content="formatDateTime(row.last_login_at)" :disabled="!row.last_login_at">
              <span :class="{ muted: !row.last_login_at }">{{ relativeTime(row.last_login_at) }}</span>
            </el-tooltip>
          </template>
        </el-table-column>
        <el-table-column label="会议数" width="80" prop="meeting_count" align="center" />
        <el-table-column label="登录设备数" width="96" prop="session_count" align="center" />
        <el-table-column label="操作" width="230" fixed="right">
          <template #default="{ row }">
            <el-button size="small" :icon="Edit" @click="openEdit(row as AdminUser)">编辑</el-button>
            <el-button size="small" type="primary" plain :icon="View" @click="openDetail(row as AdminUser)">详情</el-button>
            <el-button size="small" type="danger" plain :icon="Delete" @click="removeUser(row as AdminUser)" />
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="pageSize"
          :total="total"
          :page-sizes="[20, 50, 100]"
          layout="total, sizes, prev, pager, next"
          background
          @current-change="load"
          @size-change="search"
        />
      </div>
    </el-card>

    <!-- Create / edit dialog -->
    <el-dialog v-model="formVisible" :title="editing ? '编辑用户' : '新增用户'" width="440px" destroy-on-close>
      <el-alert
        v-if="!editing"
        type="info"
        :closable="false"
        show-icon
        title="预先创建账号后，用户可直接使用该手机号通过短信验证码登录（不受「开放注册」开关限制）。"
        class="mb"
      />
      <el-form ref="formRef" :model="form" :rules="rules" label-width="72px" @submit.prevent="saveUser">
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="form.phone" placeholder="11 位手机号" maxlength="16" />
        </el-form-item>
        <el-form-item label="昵称" prop="name">
          <el-input v-model="form.name" placeholder="如：张三" maxlength="64" @input="form.name = Array.from(form.name).slice(0, 32).join('')">
            <template #suffix>{{ Array.from(form.name).length }}/32</template>
          </el-input>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="formVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveUser">保存</el-button>
      </template>
    </el-dialog>

    <!-- Detail drawer -->
    <el-drawer v-model="detailVisible" title="用户详情" size="760px" destroy-on-close>
      <div v-loading="detailLoading">
        <template v-if="detail">
          <el-descriptions :column="2" border size="small">
            <el-descriptions-item label="手机号"><PhoneText :phone="detail.phone" /></el-descriptions-item>
            <el-descriptions-item label="昵称">{{ detail.name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="状态">
              <el-tag :type="detail.disabled ? 'danger' : 'success'" size="small">{{ detail.disabled ? '已禁用' : '启用' }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="在线">
              <span class="dot" :class="detail.online ? 'on' : 'off'" />{{ detail.online ? '在线' : '离线' }}
            </el-descriptions-item>
            <el-descriptions-item label="注册时间">{{ formatDateTime(detail.created_at) }}</el-descriptions-item>
            <el-descriptions-item label="最近登录">{{ formatDateTime(detail.last_login_at) }}</el-descriptions-item>
            <el-descriptions-item label="登录密码">
              <el-tag size="small" effect="plain" :type="detail.has_password ? 'success' : 'info'">
                {{ detail.has_password ? '已设置' : '未设置（仅验证码登录）' }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="会议数">{{ detail.meeting_count }}</el-descriptions-item>
            <el-descriptions-item label="用户 ID"><span class="mono">{{ detail.id }}</span></el-descriptions-item>
          </el-descriptions>

          <div class="card-title sessions-title">
            <span>登录设备（{{ activeSessions.length }}）</span>
            <div class="toolbar">
              <el-switch v-model="showRevoked" active-text="显示已失效" size="small" />
              <el-button
                size="small"
                type="danger"
                plain
                :disabled="!activeSessions.length"
                :loading="revokingAll"
                @click="revokeAll"
              >全部下线</el-button>
            </div>
          </div>
          <el-table :data="visibleSessions" stripe size="small" empty-text="暂无登录设备">
            <el-table-column label="设备" min-width="150">
              <template #default="{ row }">
                <div>{{ row.hostname || '-' }}</div>
                <div class="small muted">{{ row.os || '-' }} · v{{ row.app_version || '-' }}</div>
              </template>
            </el-table-column>
            <el-table-column label="IP" min-width="110">
              <template #default="{ row }"><span class="mono">{{ row.ip || '-' }}</span></template>
            </el-table-column>
            <el-table-column label="最近使用" width="100">
              <template #default="{ row }">
                <el-tooltip :content="formatDateTime(row.last_used_at)" :disabled="!row.last_used_at">
                  <span>{{ relativeTime(row.last_used_at) }}</span>
                </el-tooltip>
              </template>
            </el-table-column>
            <el-table-column label="过期时间" width="150">
              <template #default="{ row }">
                <span class="small">{{ formatDateTime(row.expires_at) }}</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="96" fixed="right">
              <template #default="{ row }">
                <el-tag v-if="!isActive(row as UserSession)" size="small" type="info">{{ row.revoked ? '已下线' : '已过期' }}</el-tag>
                <el-button
                  v-else
                  size="small"
                  type="danger"
                  plain
                  :loading="revokingId === row.id"
                  @click="revokeOne(row as UserSession)"
                >强制下线</el-button>
              </template>
            </el-table-column>
          </el-table>
        </template>
      </div>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { Delete, Edit, Plus, Refresh, Search, View } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { api } from '@/api'
import type { AdminUser, AdminUserDetail, UserSession, UserStatusFilter } from '@/api/types'
import PhoneText from '@/components/PhoneText.vue'
import { formatDateTime, maskPhone, normalizePhone, PHONE_RE, relativeTime } from '@/utils'

const items = ref<AdminUser[]>([])
const total = ref(0)
const page = ref(1)
const pageSize = ref(20)
const q = ref('')
const status = ref<UserStatusFilter | ''>('')
const loading = ref(false)
const togglingId = ref<string | null>(null)

async function load() {
  loading.value = true
  try {
    const res = await api.users({
      q: q.value.trim() || undefined,
      status: status.value || undefined,
      limit: pageSize.value,
      offset: (page.value - 1) * pageSize.value,
    })
    items.value = res?.items ?? []
    total.value = res?.total ?? 0
  } catch {
    /* shown */
  } finally {
    loading.value = false
  }
}

function search() {
  page.value = 1
  load()
}

function label(u: { name: string; phone: string }) {
  return u.name ? `${u.name}（${maskPhone(u.phone)}）` : maskPhone(u.phone)
}

// ---- Create / edit ----
const formVisible = ref(false)
const editing = ref<AdminUser | null>(null)
const saving = ref(false)
const formRef = ref<FormInstance>()
const form = reactive({ phone: '', name: '' })
const rules: FormRules = {
  phone: [
    { required: true, message: '请输入手机号', trigger: 'blur' },
    {
      validator: (_r, v: string, cb) => (PHONE_RE.test(normalizePhone(v)) ? cb() : cb(new Error('请输入有效的 11 位手机号'))),
      trigger: 'blur',
    },
  ],
  name: [{
    validator: (_r, value: string, cb) => {
      const count = Array.from(value.trim()).length
      cb(count === 0 ? new Error('请输入昵称') : count > 32 ? new Error('昵称不能超过 32 个字符') : undefined)
    },
    trigger: 'blur',
  }],
}

function openCreate() {
  editing.value = null
  form.phone = ''
  form.name = ''
  formVisible.value = true
}

function openEdit(u: AdminUser) {
  editing.value = u
  form.phone = u.phone
  form.name = u.name
  formVisible.value = true
}

async function saveUser() {
  if (!formRef.value) return
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  const phone = normalizePhone(form.phone)
  const name = form.name.trim()
  saving.value = true
  try {
    if (editing.value) {
      const patch: { name?: string; phone?: string } = {}
      if (name !== editing.value.name) patch.name = name
      if (phone !== editing.value.phone) patch.phone = phone
      if (Object.keys(patch).length) await api.updateUser(editing.value.id, patch)
    } else {
      await api.createUser(phone, name)
    }
    ElMessage.success('已保存')
    formVisible.value = false
    await load()
  } catch {
    /* shown */
  } finally {
    saving.value = false
  }
}

async function toggleUser(u: AdminUser, disabled: boolean) {
  if (disabled) {
    try {
      await ElMessageBox.confirm(
        `禁用用户「${label(u)}」后，其所有登录设备将被强制下线，且无法再次登录。确定禁用？`,
        '禁用用户',
        { type: 'warning', confirmButtonText: '禁用', confirmButtonClass: 'el-button--danger' },
      )
    } catch {
      return
    }
  }
  togglingId.value = u.id
  try {
    const updated = await api.updateUser(u.id, { disabled })
    Object.assign(u, updated ?? { disabled })
    if (disabled && !updated) Object.assign(u, { online: false, session_count: 0 })
    ElMessage.success(disabled ? '已禁用并强制下线' : '已启用')
  } catch {
    /* shown */
  } finally {
    togglingId.value = null
  }
}

async function removeUser(u: AdminUser) {
  try {
    await ElMessageBox.confirm(
      `<p>将永久删除用户「${escapeHtml(label(u))}」及其全部数据：</p>
       <ul style="margin:6px 0 6px 18px;padding:0">
         <li>${u.meeting_count} 个会议（含转写、总结、笔记）</li>
         <li>全部会议录音文件</li>
         <li>${u.session_count} 个登录设备（立即下线）</li>
       </ul>
       <p style="color:#f56c6c">此操作不可恢复。</p>`,
      '删除用户',
      {
        type: 'error',
        dangerouslyUseHTMLString: true,
        confirmButtonText: '永久删除',
        confirmButtonClass: 'el-button--danger',
      },
    )
    await ElMessageBox.prompt(`请输入该用户的完整手机号以确认删除`, '再次确认', {
      type: 'error',
      confirmButtonText: '确认删除',
      confirmButtonClass: 'el-button--danger',
      inputPlaceholder: '手机号',
      inputValidator: (v: string) => normalizePhone(v) === u.phone || '手机号不匹配',
    })
  } catch {
    return
  }
  try {
    await api.deleteUser(u.id)
    ElMessage.success('已删除')
    if (items.value.length === 1 && page.value > 1) page.value--
    await load()
  } catch {
    /* shown */
  }
}

function escapeHtml(s: string) {
  return s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!)
}

// ---- Detail drawer ----
const detailVisible = ref(false)
const detailLoading = ref(false)
const detail = ref<AdminUserDetail | null>(null)
const showRevoked = ref(false)
const revokingId = ref<string | null>(null)
const revokingAll = ref(false)

function isActive(s: UserSession) {
  return !s.revoked && new Date(s.expires_at).getTime() > Date.now()
}
const activeSessions = computed(() => (detail.value?.sessions ?? []).filter(isActive))
const visibleSessions = computed(() => {
  const all = detail.value?.sessions ?? []
  const list = showRevoked.value ? all : all.filter(isActive)
  return [...list].sort((a, b) => ((b.last_used_at ?? b.created_at) > (a.last_used_at ?? a.created_at) ? 1 : -1))
})

async function loadDetail(id: string) {
  detailLoading.value = true
  try {
    detail.value = await api.user(id)
  } catch {
    /* shown */
  } finally {
    detailLoading.value = false
  }
}

function openDetail(u: AdminUser) {
  detail.value = null
  showRevoked.value = false
  detailVisible.value = true
  loadDetail(u.id)
}

async function revokeOne(s: UserSession) {
  if (!detail.value) return
  try {
    await ElMessageBox.confirm(`确定将设备「${s.hostname || s.client_id || s.id}」强制下线？该设备需重新验证手机号登录。`, '强制下线', {
      type: 'warning',
    })
  } catch {
    return
  }
  revokingId.value = s.id
  try {
    await api.revokeSession(detail.value.id, s.id)
    ElMessage.success('已强制下线')
    await Promise.all([loadDetail(detail.value.id), load()])
  } catch {
    /* shown */
  } finally {
    revokingId.value = null
  }
}

async function revokeAll() {
  if (!detail.value) return
  try {
    await ElMessageBox.confirm(`确定将「${label(detail.value)}」的全部 ${activeSessions.value.length} 个设备强制下线？`, '全部下线', {
      type: 'warning',
      confirmButtonText: '全部下线',
      confirmButtonClass: 'el-button--danger',
    })
  } catch {
    return
  }
  revokingAll.value = true
  try {
    await api.revokeAllSessions(detail.value.id)
    ElMessage.success('已全部下线')
    await Promise.all([loadDetail(detail.value.id), load()])
  } catch {
    /* shown */
  } finally {
    revokingAll.value = false
  }
}

onMounted(load)
</script>

<style scoped>
.mb {
  margin-bottom: 16px;
}
.small {
  font-size: 12px;
}
.pager {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}
.sessions-title {
  margin: 20px 0 10px;
}
</style>
