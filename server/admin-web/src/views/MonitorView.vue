<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h2>连接监控</h2>
        <div class="sub">
          <span class="dot" :class="connected ? 'on' : 'off'" />
          {{ connected ? '实时推送中' : '实时推送未连接，每 5 秒轮询' }}
        </div>
      </div>
      <div class="toolbar">
        <el-switch v-model="onlyOnline" active-text="仅显示在线" />
        <el-button :icon="Refresh" :loading="loading" @click="loadAll">刷新</el-button>
      </div>
    </div>

    <el-card shadow="never">
      <template #header>
        <div class="card-title">
          <span>客户端（在线 {{ onlineCount }} / 录音中 {{ recordingCount }}）</span>
        </div>
      </template>
      <el-table :data="visibleConnections" stripe v-loading="loading && !connections.length" empty-text="暂无客户端连接" :row-key="(r: Connection) => r.client_id">
        <el-table-column label="状态" width="80">
          <template #default="{ row }">
            <span class="dot" :class="row.online ? 'on' : 'off'" />{{ row.online ? '在线' : '离线' }}
          </template>
        </el-table-column>
        <el-table-column label="用户" min-width="150">
          <template #default="{ row }">
            <div class="ellipsis" :title="row.user_name ?? ''">{{ row.user_name || '-' }}</div>
            <PhoneText v-if="row.user_phone" :phone="row.user_phone" class="small muted" />
          </template>
        </el-table-column>
        <el-table-column prop="hostname" label="主机名" min-width="130" show-overflow-tooltip />
        <el-table-column prop="os" label="系统" min-width="100" show-overflow-tooltip />
        <el-table-column prop="app_version" label="版本" width="90" />
        <el-table-column label="IP" min-width="120">
          <template #default="{ row }"><span class="mono">{{ row.ip }}</span></template>
        </el-table-column>
        <el-table-column label="录音" min-width="150">
          <template #default="{ row }">
            <template v-if="row.recording">
              <el-tag type="danger" effect="dark" size="small" class="rec">● 录音中</el-tag>
              <div v-if="row.meeting_id" class="mono muted ellipsis" :title="row.meeting_id">{{ row.meeting_id }}</div>
            </template>
            <span v-else class="muted">-</span>
          </template>
        </el-table-column>
        <el-table-column label="最后心跳" width="110">
          <template #default="{ row }">
            <el-tooltip :content="formatDateTime(row.last_seen)">
              <span>{{ relativeTime(row.last_seen, now) }}</span>
            </el-tooltip>
          </template>
        </el-table-column>
        <el-table-column label="进行中请求" width="100" align="center">
          <template #default="{ row }">
            <el-badge v-if="row.inflight_requests > 0" :value="row.inflight_requests" type="primary" />
            <span v-else class="muted">0</span>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card shadow="never">
      <template #header>
        <div class="card-title">
          <span>后台任务</span>
          <el-radio-group v-model="jobFilter" size="small" @change="loadJobs">
            <el-radio-button value="active">进行中</el-radio-button>
            <el-radio-button value="">全部</el-radio-button>
            <el-radio-button value="failed">失败</el-radio-button>
          </el-radio-group>
        </div>
      </template>
      <el-table :data="visibleJobs" stripe empty-text="暂无任务" :row-key="(r: AdminJob) => r.id">
        <el-table-column label="类型" width="90">
          <template #default="{ row }"><el-tag size="small" effect="plain">{{ JOB_KIND_LABEL[row.kind] ?? row.kind }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="user_name" label="用户" width="100" show-overflow-tooltip />
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <el-tag size="small" :type="JOB_STATUS[row.status]?.type">{{ JOB_STATUS[row.status]?.label ?? row.status }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="进度" min-width="180">
          <template #default="{ row }">
            <el-progress
              :percentage="Math.round(row.progress || 0)"
              :status="row.status === 'completed' ? 'success' : row.status === 'failed' ? 'exception' : undefined"
              :stroke-width="10"
            />
            <div v-if="row.message || row.error" class="small" :class="row.error ? 'err' : 'muted'">{{ row.error || row.message }}</div>
          </template>
        </el-table-column>
        <el-table-column label="会议" min-width="140">
          <template #default="{ row }"><span class="mono muted ellipsis" :title="row.meeting_id">{{ row.meeting_id ?? '-' }}</span></template>
        </el-table-column>
        <el-table-column label="片段" width="70" align="center">
          <template #default="{ row }">{{ row.segments ?? '-' }}</template>
        </el-table-column>
        <el-table-column label="创建 / 更新" width="130">
          <template #default="{ row }">
            <div class="small">{{ relativeTime(row.created_at, now) }}</div>
            <div class="small muted">{{ relativeTime(row.updated_at, now) }}</div>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="90" fixed="right">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 'queued' || row.status === 'running'"
              size="small"
              type="danger"
              plain
              :loading="cancelling === row.id"
              @click="cancel(row as AdminJob)"
            >取消</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { api } from '@/api'
import type { AdminJob, Connection } from '@/api/types'
import PhoneText from '@/components/PhoneText.vue'
import { useAdminEvents, useInterval } from '@/composables/useEvents'
import { formatDateTime, JOB_KIND_LABEL, JOB_STATUS, relativeTime } from '@/utils'

const connections = ref<Connection[]>([])
const jobs = ref<AdminJob[]>([])
const loading = ref(false)
const onlyOnline = ref(true)
const jobFilter = ref<'active' | '' | 'failed'>('active')
const cancelling = ref<string | null>(null)
const now = ref(Date.now())

const onlineCount = computed(() => connections.value.filter((c) => c.online).length)
const recordingCount = computed(() => connections.value.filter((c) => c.online && c.recording).length)
const visibleConnections = computed(() => {
  const list = onlyOnline.value ? connections.value.filter((c) => c.online) : connections.value
  return [...list].sort((a, b) => Number(b.online) - Number(a.online) || Number(b.recording) - Number(a.recording) || (b.last_seen > a.last_seen ? 1 : -1))
})
const visibleJobs = computed(() => {
  let list = jobs.value
  if (jobFilter.value === 'active') list = list.filter((j) => j.status === 'queued' || j.status === 'running')
  else if (jobFilter.value === 'failed') list = list.filter((j) => j.status === 'failed')
  return [...list].sort((a, b) => (b.created_at > a.created_at ? 1 : -1))
})

async function loadConnections() {
  try {
    connections.value = (await api.connections()) ?? []
  } catch {
    /* silent */
  }
}
async function loadJobs() {
  try {
    // 'active' is filtered client-side (two statuses); others pass through to the server
    jobs.value = (await api.jobs(jobFilter.value === 'active' ? undefined : jobFilter.value || undefined)) ?? []
  } catch {
    /* silent */
  }
}
async function loadAll() {
  loading.value = true
  await Promise.all([loadConnections(), loadJobs()])
  loading.value = false
}

async function cancel(row: AdminJob) {
  try {
    await ElMessageBox.confirm(`确定取消该${JOB_KIND_LABEL[row.kind] ?? ''}任务？`, '取消任务', { type: 'warning' })
  } catch {
    return
  }
  cancelling.value = row.id
  try {
    const updated = await api.cancelJob(row.id)
    upsertJob({ ...row, ...updated })
    ElMessage.success('已取消')
  } catch {
    /* shown */
  } finally {
    cancelling.value = null
  }
}

function upsertJob(j: Partial<AdminJob> & { id: string }) {
  const i = jobs.value.findIndex((x) => x.id === j.id)
  if (i >= 0) jobs.value[i] = { ...jobs.value[i], ...j }
  else jobs.value.unshift(j as AdminJob)
}

// SSE payloads: a full list replaces local state; a single object is upserted; anything else triggers a refetch.
const { connected } = useAdminEvents({
  connections: (data) => {
    if (Array.isArray(data)) connections.value = data as Connection[]
    else if (data && typeof data === 'object' && 'client_id' in data) {
      const c = data as Connection
      const i = connections.value.findIndex((x) => x.client_id === c.client_id)
      if (i >= 0) connections.value[i] = { ...connections.value[i], ...c }
      else connections.value.push(c)
    } else loadConnections()
  },
  jobs: (data) => {
    if (Array.isArray(data)) {
      if (jobFilter.value === 'failed') loadJobs()
      else jobs.value = data as AdminJob[]
    } else if (data && typeof data === 'object' && 'id' in data) upsertJob(data as AdminJob)
    else loadJobs()
  },
})

// Polling fallback when SSE is down; also periodic full resync every 30 s.
let tick = 0
useInterval(() => {
  now.value = Date.now()
  tick++
  if (document.hidden) return
  if (!connected.value || tick % 6 === 0) {
    loadConnections()
    loadJobs()
  }
}, 5000)

onMounted(loadAll)
</script>

<style scoped>
.small {
  font-size: 12px;
}
.err {
  color: #f56c6c;
}
.ellipsis {
  display: inline-block;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.rec {
  animation: pulse 1.6s infinite;
}
@keyframes pulse {
  50% {
    opacity: 0.6;
  }
}
</style>
