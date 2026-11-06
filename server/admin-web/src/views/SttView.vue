<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h2>语音模型</h2>
        <div class="sub">
          当前：
          <template v-if="current">
            <el-tag size="small" type="success">{{ current.display_name || current.name }}</el-tag>
            <span class="muted"> ({{ engineLabel(current.engine) }})</span>
          </template>
          <span v-else class="muted">未设置</span>
        </div>
      </div>
      <div class="toolbar">
        <el-button :icon="VideoPlay" type="primary" plain @click="openTest()">测试转写</el-button>
        <el-button :icon="Refresh" :loading="loading" @click="loadAll">刷新</el-button>
      </div>
    </div>

    <el-alert
      v-if="activateError"
      type="error"
      :title="`切换模型失败：${activateError}`"
      description="已保留原模型继续服务。"
      show-icon
      @close="activateError = ''"
    />

    <el-card shadow="never">
      <el-tabs v-model="tab">
        <el-tab-pane v-for="e in engineTabs" :key="e.value" :name="e.value">
          <template #label>
            <span class="tab-label">
              {{ e.label }}
              <el-icon v-if="engineInfo(e.value) && !engineInfo(e.value)!.available" color="#e6a23c"><WarningFilled /></el-icon>
            </span>
          </template>

          <el-alert
            v-if="engineInfo(e.value) && !engineInfo(e.value)!.available"
            type="warning"
            show-icon
            :closable="false"
            class="mb"
            :title="`${e.label} 引擎不可用`"
            :description="engineInfo(e.value)!.reason || '服务器缺少该引擎的 Python 依赖，请安装对应 extras 后重启服务。'"
          />

          <!-- Cloud config -->
          <el-card v-if="e.value === 'cloud'" shadow="never" class="mb cloud-card">
            <template #header>
              <div class="card-title">
                <span>云端转写配置</span>
                <el-tag v-if="cloud" :type="cloud.api_key_set ? 'success' : 'info'" size="small">
                  {{ cloud.api_key_set ? 'API Key 已设置' : 'API Key 未设置' }}
                </el-tag>
              </div>
            </template>
            <el-form ref="cloudFormRef" :model="cloudForm" :rules="cloudRules" label-width="100px" class="cloud-form" v-loading="cloudLoading">
              <el-form-item label="接口模式" prop="mode">
                <el-radio-group v-model="cloudForm.mode" @change="onCloudModeChange">
                  <el-radio-button value="openai">OpenAI 兼容</el-radio-button>
                  <el-radio-button value="dashscope">阿里云 DashScope</el-radio-button>
                </el-radio-group>
              </el-form-item>
              <el-form-item label="Base URL" prop="base_url">
                <el-input v-model="cloudForm.base_url" :placeholder="cloudForm.mode === 'dashscope' ? 'https://dashscope.aliyuncs.com/api/v1' : 'https://api.openai.com/v1'" />
              </el-form-item>
              <el-form-item label="模型" prop="model">
                <el-input v-model="cloudForm.model" :placeholder="cloudForm.mode === 'dashscope' ? 'paraformer-realtime-v2 / sensevoice-v1' : 'whisper-1'" />
              </el-form-item>
              <el-form-item label="API Key">
                <el-input
                  v-model="cloudForm.api_key"
                  type="password"
                  show-password
                  autocomplete="new-password"
                  :placeholder="cloud?.api_key_set ? '已设置（留空则保持不变）' : '请输入 API Key'"
                />
              </el-form-item>
              <el-form-item>
                <el-button type="primary" :loading="cloudSaving" @click="saveCloud">保存配置</el-button>
              </el-form-item>
            </el-form>
          </el-card>

          <el-table :data="modelsOf(e.value)" v-loading="loading" stripe empty-text="暂无模型">
            <el-table-column label="模型" min-width="200">
              <template #default="{ row }">
                <div class="model-name">
                  <span>{{ row.display_name || row.name }}</span>
                  <el-tag v-if="row.active" type="success" size="small" effect="dark">当前</el-tag>
                </div>
                <div class="mono muted">{{ row.id }}</div>
              </template>
            </el-table-column>
            <el-table-column label="大小" width="100">
              <template #default="{ row }">{{ row.remote ? '云端' : formatSizeMb(row.size_mb) }}</template>
            </el-table-column>
            <el-table-column label="语言" width="120">
              <template #default="{ row }">{{ languageLabel(row.languages) }}</template>
            </el-table-column>
            <el-table-column label="状态" min-width="200">
              <template #default="{ row }">
                <template v-if="row.status === 'downloading'">
                  <el-progress :percentage="Math.round(row.progress || 0)" :stroke-width="14" text-inside striped striped-flow :duration="20" />
                </template>
                <template v-else-if="row.status === 'error'">
                  <el-tooltip :content="row.error || '未知错误'" placement="top">
                    <el-tag type="danger">错误</el-tag>
                  </el-tooltip>
                  <span class="err-text">{{ row.error }}</span>
                </template>
                <el-tag v-else-if="row.status === 'ready'" type="success" effect="plain">{{ row.remote ? '可用' : '已下载' }}</el-tag>
                <el-tag v-else type="info" effect="plain">{{ row.remote ? '未配置' : '未下载' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="260" fixed="right">
              <template #default="{ row }">
                <el-button
                  v-if="!row.remote && (row.status === 'not_downloaded' || row.status === 'error')"
                  size="small"
                  type="primary"
                  plain
                  :icon="Download"
                  :disabled="!engineAvailable(row.engine)"
                  :loading="busy[row.id] === 'download'"
                  @click="download(row as SttModel)"
                >{{ row.status === 'error' ? '重新下载' : '下载' }}</el-button>
                <el-button
                  v-if="row.status === 'ready' && !row.active"
                  size="small"
                  type="success"
                  :disabled="!engineAvailable(row.engine) || !!activating"
                  :loading="activating === row.id"
                  @click="activate(row as SttModel)"
                >设为当前</el-button>
                <el-button v-if="row.active" size="small" plain :icon="VideoPlay" @click="openTest()">测试</el-button>
                <el-button
                  v-if="!row.remote && row.status === 'ready' && !row.active"
                  size="small"
                  type="danger"
                  plain
                  :icon="Delete"
                  :loading="busy[row.id] === 'delete'"
                  @click="remove(row as SttModel)"
                >删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- Hot-swap overlay -->
    <el-dialog :model-value="!!activating" title="正在切换模型" width="380px" :show-close="false" :close-on-click-modal="false" :close-on-press-escape="false" align-center>
      <div class="swap">
        <el-icon class="is-loading" :size="32" color="#409eff"><Loading /></el-icon>
        <div>正在加载 <b>{{ activatingName }}</b>，加载完成后将替换当前模型……</div>
        <div class="muted small">大模型首次加载可能需要几十秒，期间原模型继续服务。</div>
      </div>
    </el-dialog>

    <!-- Test dialog -->
    <el-dialog v-model="testVisible" title="测试转写" width="560px" destroy-on-close>
      <el-form label-width="80px">
        <el-form-item label="当前模型">
          <span v-if="current">{{ current.display_name || current.name }} <span class="muted">({{ engineLabel(current.engine) }})</span></span>
          <el-tag v-else type="danger">未设置当前模型</el-tag>
        </el-form-item>
        <el-form-item label="音频文件">
          <el-upload
            drag
            :auto-upload="false"
            :limit="1"
            :on-change="onFileChange"
            :on-remove="() => (testFile = null)"
            :on-exceed="onExceed"
            ref="uploadRef"
            accept="audio/*,video/*,.wav,.mp3,.m4a,.mp4,.flac,.ogg,.webm,.aac"
            class="upload"
          >
            <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
            <div class="el-upload__text">拖拽音频到此处，或<em>点击选择</em></div>
            <template #tip><div class="el-upload__tip">支持 wav / mp3 / m4a / mp4 / flac 等常见格式，建议 1 分钟以内</div></template>
          </el-upload>
        </el-form-item>
        <el-form-item label="语言">
          <el-select v-model="testLang" style="width: 200px">
            <el-option v-for="l in LANGUAGE_OPTIONS" :key="l.value" :value="l.value" :label="l.label" />
          </el-select>
        </el-form-item>
      </el-form>
      <div v-if="testResult" class="test-result">
        <div class="result-meta">
          <el-tag type="success" size="small">耗时 {{ testResult.elapsed_ms }} ms</el-tag>
          <span class="muted small">{{ testResult.engine }} / {{ testResult.model }}</span>
        </div>
        <el-input type="textarea" :model-value="testResult.text || '（无识别结果）'" :autosize="{ minRows: 3, maxRows: 12 }" readonly />
      </div>
      <template #footer>
        <el-button @click="testVisible = false">关闭</el-button>
        <el-button type="primary" :loading="testing" :disabled="!testFile" @click="runTest">开始转写</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { Delete, Download, Refresh, VideoPlay } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules, type UploadFile, type UploadInstance } from 'element-plus'
import { api } from '@/api'
import { ApiError } from '@/api/http'
import type { CloudConfig, CloudMode, SttEngine, SttEngineInfo, SttModel, SttTestResult } from '@/api/types'
import { useAdminEvents } from '@/composables/useEvents'
import { formatSizeMb, LANGUAGE_OPTIONS } from '@/utils'

const engineTabs: { value: SttEngine; label: string }[] = [
  { value: 'faster-whisper', label: 'faster-whisper' },
  { value: 'funasr', label: 'FunASR' },
  { value: 'cloud', label: '云端' },
]

const tab = ref<SttEngine>('faster-whisper')
const models = ref<SttModel[]>([])
const engines = ref<SttEngineInfo[]>([])
const loading = ref(false)
const busy = reactive<Record<string, 'download' | 'delete' | undefined>>({})
const activating = ref<string | null>(null)
const activateError = ref('')

const current = computed(() => models.value.find((m) => m.active) ?? null)
const activatingName = computed(() => {
  const m = models.value.find((x) => x.id === activating.value)
  return m ? m.display_name || m.name : activating.value
})

function engineLabel(e: string) {
  return engineTabs.find((t) => t.value === e)?.label ?? e
}
function engineInfo(e: SttEngine) {
  return engines.value.find((x) => x.engine === e)
}
function engineAvailable(e: SttEngine) {
  const info = engineInfo(e)
  return !info || info.available
}
function modelsOf(e: SttEngine) {
  return models.value.filter((m) => m.engine === e)
}
function languageLabel(l: string) {
  const map: Record<string, string> = { multilingual: '多语言', zh: '中文', en: '英语', ja: '日语' }
  return l
    .split(/[,|/]/)
    .map((x) => map[x.trim()] ?? x.trim())
    .join(' / ')
}

async function loadModels() {
  models.value = await api.sttModels()
}

async function loadAll() {
  loading.value = true
  try {
    const [m, e] = await Promise.all([api.sttModels(), api.sttEngines()])
    models.value = m
    engines.value = e
  } catch {
    /* shown */
  } finally {
    loading.value = false
  }
  loadCloud()
}

// ---- Download / delete / activate ----
async function download(row: SttModel) {
  busy[row.id] = 'download'
  try {
    const updated = await api.sttDownload(row.id)
    upsertModel(updated)
    ElMessage.success(`开始下载 ${row.display_name || row.name}`)
  } catch {
    /* shown */
  } finally {
    busy[row.id] = undefined
  }
}

async function remove(row: SttModel) {
  try {
    await ElMessageBox.confirm(`确定删除模型「${row.display_name || row.name}」的本地文件？`, '删除模型', {
      type: 'warning',
      confirmButtonText: '删除',
      confirmButtonClass: 'el-button--danger',
    })
  } catch {
    return
  }
  busy[row.id] = 'delete'
  try {
    await api.sttDelete(row.id)
    ElMessage.success('已删除')
    await loadModels()
  } catch {
    /* shown */
  } finally {
    busy[row.id] = undefined
  }
}

async function activate(row: SttModel) {
  const cur = current.value
  try {
    await ElMessageBox.confirm(
      `将当前语音模型${cur ? `从「${cur.display_name || cur.name}」` : ''}切换为「${row.display_name || row.name}」？切换过程中会先加载新模型，成功后再释放旧模型。`,
      '设为当前模型',
      { type: 'info', confirmButtonText: '切换' },
    )
  } catch {
    return
  }
  activating.value = row.id
  activateError.value = ''
  try {
    const cap = await api.sttActivate(row.id)
    if (cap && !cap.ready && cap.error) {
      activateError.value = cap.error
    } else {
      ElMessage.success(`已切换为 ${row.display_name || row.name}`)
    }
  } catch (e) {
    activateError.value = e instanceof ApiError ? e.detail : String(e)
  } finally {
    activating.value = null
    loadModels().catch(() => undefined)
  }
}

function upsertModel(m: SttModel) {
  const i = models.value.findIndex((x) => x.id === m.id)
  if (i >= 0) models.value[i] = { ...models.value[i], ...m }
  else models.value.push(m)
}

// ---- Live updates ----
let reloadTimer: number | null = null
function scheduleReload() {
  if (reloadTimer !== null) return
  reloadTimer = window.setTimeout(() => {
    reloadTimer = null
    loadModels().catch(() => undefined)
  }, 500)
}

useAdminEvents({
  'model-download': (data) => {
    // Payload not strictly specified: accept a full SttModel, or {model_id|id, progress, status, error}
    const list = Array.isArray(data) ? data : [data]
    for (const item of list) {
      if (!item || typeof item !== 'object') continue
      const d = item as Partial<SttModel> & { model_id?: string }
      const id = d.id ?? d.model_id
      const existing = id ? models.value.find((m) => m.id === id) : undefined
      if (!existing) {
        scheduleReload()
        continue
      }
      if (typeof d.progress === 'number') existing.progress = d.progress
      if (d.status) existing.status = d.status
      if (d.error !== undefined) existing.error = d.error
      if (d.status === 'ready' || d.status === 'error') scheduleReload()
    }
  },
  stt: () => scheduleReload(),
})

// ---- Cloud config ----
const cloud = ref<CloudConfig | null>(null)
const cloudLoading = ref(false)
const cloudSaving = ref(false)
const cloudFormRef = ref<FormInstance[] | FormInstance>()
const cloudForm = reactive({ mode: 'openai' as CloudMode, base_url: '', model: '', api_key: '' })
const cloudRules: FormRules = {
  base_url: [{ required: true, message: '请输入 Base URL', trigger: 'blur' }],
  model: [{ required: true, message: '请输入模型名', trigger: 'blur' }],
}

async function loadCloud() {
  cloudLoading.value = true
  try {
    const c = await api.cloudConfig()
    cloud.value = c
    cloudForm.mode = c.mode || 'openai'
    cloudForm.base_url = c.base_url || ''
    cloudForm.model = c.model || ''
    cloudForm.api_key = ''
  } catch {
    /* shown */
  } finally {
    cloudLoading.value = false
  }
}

function onCloudModeChange(mode: string | number | boolean | undefined) {
  if (mode === 'dashscope' && !cloudForm.base_url) cloudForm.base_url = 'https://dashscope.aliyuncs.com/api/v1'
  if (mode === 'openai' && !cloudForm.base_url) cloudForm.base_url = 'https://api.openai.com/v1'
}

async function saveCloud() {
  const form = Array.isArray(cloudFormRef.value) ? cloudFormRef.value[0] : cloudFormRef.value
  if (form) {
    const ok = await form.validate().catch(() => false)
    if (!ok) return
  }
  cloudSaving.value = true
  try {
    const payload: { mode: CloudMode; base_url: string; model: string; api_key?: string } = {
      mode: cloudForm.mode,
      base_url: cloudForm.base_url.trim(),
      model: cloudForm.model.trim(),
    }
    if (cloudForm.api_key) payload.api_key = cloudForm.api_key
    cloud.value = await api.saveCloudConfig(payload)
    cloudForm.api_key = ''
    ElMessage.success('云端配置已保存')
    loadModels().catch(() => undefined)
  } catch {
    /* shown */
  } finally {
    cloudSaving.value = false
  }
}

// ---- Test transcription ----
const testVisible = ref(false)
const testFile = ref<File | null>(null)
const testLang = ref('auto')
const testing = ref(false)
const testResult = ref<SttTestResult | null>(null)
const uploadRef = ref<UploadInstance>()

function openTest() {
  testResult.value = null
  testFile.value = null
  testVisible.value = true
}
function onFileChange(f: UploadFile) {
  testFile.value = f.raw ?? null
  testResult.value = null
}
function onExceed(files: File[]) {
  uploadRef.value?.clearFiles()
  const f = files[0]
  if (f) {
    uploadRef.value?.handleStart(f as Parameters<UploadInstance['handleStart']>[0])
    testFile.value = f
  }
}
async function runTest() {
  if (!testFile.value) return
  testing.value = true
  testResult.value = null
  try {
    testResult.value = await api.sttTest(testFile.value, testLang.value)
  } catch {
    /* shown */
  } finally {
    testing.value = false
  }
}

onMounted(loadAll)
</script>

<style scoped>
.mb {
  margin-bottom: 16px;
}
.tab-label {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}
.model-name {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 500;
}
.err-text {
  color: #f56c6c;
  font-size: 12px;
  margin-left: 6px;
}
.cloud-form {
  max-width: 640px;
}
.swap {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  text-align: center;
  padding: 8px 0;
}
.small {
  font-size: 12px;
}
.upload {
  width: 100%;
}
.test-result {
  margin-top: 8px;
}
.result-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}
</style>
