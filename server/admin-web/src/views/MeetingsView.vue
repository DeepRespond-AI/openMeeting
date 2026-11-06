<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h2>会议记录</h2>
        <div class="sub">只读浏览，用于排查问题。</div>
      </div>
      <div class="toolbar">
        <el-select
          v-model="userId"
          placeholder="全部用户（可搜手机号/昵称）"
          clearable
          filterable
          remote
          :remote-method="searchUsers"
          :loading="usersLoading"
          style="width: 220px"
          @change="search"
        >
          <el-option v-for="u in users" :key="u.id" :label="userLabel(u)" :value="u.id" />
        </el-select>
        <el-input v-model="q" placeholder="搜索标题 / 内容" clearable :prefix-icon="Search" style="width: 220px" @keyup.enter="search" @clear="search" />
        <el-button type="primary" @click="search">搜索</el-button>
      </div>
    </div>

    <el-card shadow="never">
      <el-table :data="items" stripe v-loading="loading" empty-text="暂无会议" @row-click="openDetail" class="clickable">
        <el-table-column prop="title" label="标题" min-width="220" show-overflow-tooltip />
        <el-table-column prop="user_name" label="用户" width="110" />
        <el-table-column label="创建时间" width="170">
          <template #default="{ row }">{{ formatDateTime(row.created_at) }}</template>
        </el-table-column>
        <el-table-column label="转写条数" width="90" prop="transcript_count" align="center" />
        <el-table-column label="录音" width="70" align="center">
          <template #default="{ row }">
            <el-icon v-if="row.has_audio" color="#67c23a"><Check /></el-icon><span v-else class="muted">-</span>
          </template>
        </el-table-column>
        <el-table-column label="总结" width="70" align="center">
          <template #default="{ row }">
            <el-icon v-if="row.has_summary" color="#67c23a"><Check /></el-icon><span v-else class="muted">-</span>
          </template>
        </el-table-column>
        <el-table-column label="ID" min-width="160">
          <template #default="{ row }"><span class="mono muted">{{ row.id }}</span></template>
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

    <el-drawer v-model="drawer" :title="detail?.title || '会议详情'" size="min(760px, 100%)" destroy-on-close>
      <div v-loading="detailLoading" class="drawer-body">
        <template v-if="detail">
          <el-descriptions :column="2" border size="small" class="mb">
            <el-descriptions-item label="用户">{{ detail.user_name }}</el-descriptions-item>
            <el-descriptions-item label="转写条数">{{ detail.transcripts.length }}</el-descriptions-item>
            <el-descriptions-item label="创建时间">{{ formatDateTime(detail.created_at) }}</el-descriptions-item>
            <el-descriptions-item label="更新时间">{{ formatDateTime(detail.updated_at) }}</el-descriptions-item>
            <el-descriptions-item label="ID" :span="2"><span class="mono">{{ detail.id }}</span></el-descriptions-item>
          </el-descriptions>

          <el-tabs v-model="detailTab">
            <el-tab-pane label="总结" name="summary">
              <template v-if="detail.summary">
                <div class="summary-meta">
                  <el-tag size="small" :type="summaryTag(detail.summary.status)">{{ summaryLabel(detail.summary.status) }}</el-tag>
                  <span v-if="detail.summary.end" class="muted small">完成于 {{ formatDateTime(detail.summary.end) }}</span>
                  <el-tag v-if="summaryTemplateName" size="small" effect="plain" type="info">模板：{{ summaryTemplateName }}</el-tag>
                  <el-tag v-if="summaryFormat !== 'markdown'" size="small" effect="plain">{{ summaryFormat === 'html' ? 'HTML' : '混合' }}</el-tag>
                </div>
                <el-alert v-if="detail.summary.error" :title="detail.summary.error" type="error" :closable="false" show-icon class="mb" />
                <div v-if="summaryHtml" class="markdown-body" v-html="summaryHtml" />
                <el-empty v-else description="暂无总结内容" :image-size="64" />
              </template>
              <el-empty v-else description="暂无总结" :image-size="64" />
            </el-tab-pane>
            <el-tab-pane :label="`转写 (${detail.transcripts.length})`" name="transcripts">
              <el-input v-model="tq" placeholder="筛选转写内容" clearable size="small" class="mb" :prefix-icon="Search" />
              <div v-if="filteredTranscripts.length" class="transcripts">
                <div v-for="t in filteredTranscripts" :key="t.id" class="seg">
                  <span class="ts mono">{{ segTime(t) }}</span>
                  <span class="text">{{ t.text }}</span>
                </div>
              </div>
              <el-empty v-else description="暂无转写" :image-size="64" />
            </el-tab-pane>
          </el-tabs>
        </template>
      </div>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { Search } from '@element-plus/icons-vue'
import { marked } from 'marked'
import DOMPurify from 'dompurify'
import { api } from '@/api'
import type {
  AdminMeetingDetails,
  MeetingListItem,
  MeetingTranscript,
  SummaryOutputFormat,
  SummaryStatus,
  AdminUser,
} from '@/api/types'
import { formatDateTime, maskPhone } from '@/utils'

const items = ref<MeetingListItem[]>([])
const total = ref(0)
const page = ref(1)
const pageSize = ref(20)
const q = ref('')
const userId = ref<string>('')
const users = ref<AdminUser[]>([])
const userLabel = (u: AdminUser) => (u.name ? `${u.name}（${maskPhone(u.phone)}）` : maskPhone(u.phone))
const loading = ref(false)

async function load() {
  loading.value = true
  try {
    const res = await api.meetings({
      user_id: userId.value || undefined,
      q: q.value.trim() || undefined,
      limit: pageSize.value,
      offset: (page.value - 1) * pageSize.value,
    })
    items.value = res.items ?? []
    total.value = res.total ?? 0
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

// ---- Detail ----
const drawer = ref(false)
const detail = ref<AdminMeetingDetails | null>(null)
const detailLoading = ref(false)
const detailTab = ref('summary')
const tq = ref('')

async function openDetail(row: MeetingListItem) {
  drawer.value = true
  detail.value = null
  tq.value = ''
  detailTab.value = row.has_summary ? 'summary' : 'transcripts'
  detailLoading.value = true
  try {
    detail.value = await api.meeting(row.id)
  } catch {
    drawer.value = false
  } finally {
    detailLoading.value = false
  }
}

function extractMarkdown(data: unknown): string {
  if (!data) return ''
  if (typeof data === 'string') {
    try {
      return extractMarkdown(JSON.parse(data))
    } catch {
      return data
    }
  }
  if (typeof data === 'object') {
    const o = data as Record<string, unknown>
    for (const k of ['markdown', 'text', 'content']) {
      if (typeof o[k] === 'string' && (o[k] as string).trim()) return o[k] as string
    }
    // Legacy structured summary: { SectionName: { title, blocks: [{content}] } }
    const parts: string[] = []
    for (const v of Object.values(o)) {
      if (v && typeof v === 'object' && 'blocks' in (v as object)) {
        const sec = v as { title?: string; blocks?: { content?: string }[] }
        if (sec.title) parts.push(`## ${sec.title}`)
        for (const b of sec.blocks ?? []) if (b?.content) parts.push(`- ${b.content}`)
      }
    }
    if (parts.length) return parts.join('\n')
    return '```json\n' + JSON.stringify(data, null, 2) + '\n```'
  }
  return String(data)
}

function summaryObject(): Record<string, unknown> | null {
  const data = detail.value?.summary?.data
  return data && typeof data === 'object' ? (data as Record<string, unknown>) : null
}

const summaryFormat = computed<SummaryOutputFormat>(() => {
  const f = summaryObject()?.format
  return f === 'html' || f === 'mixed' ? f : 'markdown'
})

const summaryTemplateName = computed(() => {
  const t = summaryObject()?.template as { name?: string } | undefined
  return t?.name ?? ''
})

const summaryHtml = computed(() => {
  const content = extractMarkdown(detail.value?.summary?.data)
  if (!content.trim()) return ''
  // HTML summaries are already HTML; Markdown and mixed (Markdown + raw HTML) go through marked.
  const html = summaryFormat.value === 'html' ? content : (marked.parse(content, { async: false }) as string)
  return DOMPurify.sanitize(html, { FORBID_TAGS: ['style', 'form', 'input', 'button'] })
})

const filteredTranscripts = computed(() => {
  const list = detail.value?.transcripts ?? []
  const k = tq.value.trim().toLowerCase()
  return k ? list.filter((t) => t.text.toLowerCase().includes(k)) : list
})

function segTime(t: MeetingTranscript) {
  if (typeof t.audio_start_time === 'number') {
    const s = Math.floor(t.audio_start_time)
    const h = Math.floor(s / 3600)
    const m = Math.floor((s % 3600) / 60)
    const sec = s % 60
    const p = (n: number) => String(n).padStart(2, '0')
    return h ? `${p(h)}:${p(m)}:${p(sec)}` : `${p(m)}:${p(sec)}`
  }
  const d = new Date(t.timestamp)
  return isNaN(d.getTime()) ? t.timestamp : d.toLocaleTimeString('zh-CN', { hour12: false })
}

const SUMMARY_LABEL: Record<SummaryStatus, string> = {
  idle: '未生成',
  processing: '生成中',
  completed: '已完成',
  failed: '失败',
  cancelled: '已取消',
  error: '错误',
}
function summaryLabel(s: SummaryStatus) {
  return SUMMARY_LABEL[s] ?? s
}
function summaryTag(s: SummaryStatus) {
  return s === 'completed' ? 'success' : s === 'processing' ? 'primary' : s === 'idle' ? 'info' : 'danger'
}

const usersLoading = ref(false)
async function searchUsers(query = '') {
  usersLoading.value = true
  try {
    users.value = (await api.users({ q: query.trim() || undefined, limit: 50 }))?.items ?? []
  } catch {
    /* shown */
  } finally {
    usersLoading.value = false
  }
}

onMounted(() => {
  load()
  searchUsers()
})
</script>

<style scoped>
.pager {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
  overflow-x: auto;
}
.clickable :deep(.el-table__row) {
  cursor: pointer;
}
.mb {
  margin-bottom: 12px;
}
.small {
  font-size: 12px;
}
.drawer-body {
  min-height: 200px;
}
.summary-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
}
.transcripts {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.seg {
  display: flex;
  gap: 10px;
  line-height: 1.6;
  font-size: 14px;
}
.ts {
  color: #409eff;
  flex-shrink: 0;
  width: 64px;
  padding-top: 2px;
}
.text {
  flex: 1;
  word-break: break-word;
}
</style>
