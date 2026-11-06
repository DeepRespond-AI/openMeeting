<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h2>大模型</h2>
        <div class="sub">用于会议总结的 OpenAI 兼容接口提供方。客户端不再保存任何 API Key，由服务器统一调用当前提供方。</div>
      </div>
      <div class="toolbar">
        <el-button type="primary" :icon="Plus" @click="openCreate">添加提供方</el-button>
        <el-button :icon="Refresh" :loading="loading" @click="load">刷新</el-button>
      </div>
    </div>

    <el-card shadow="never">
      <el-table :data="providers" v-loading="loading" stripe empty-text="尚未添加大模型提供方">
        <el-table-column label="名称" min-width="160">
          <template #default="{ row }">
            <div class="name">
              <span>{{ row.name }}</span>
              <el-tag v-if="row.active" type="success" size="small" effect="dark">当前</el-tag>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="Base URL" min-width="260">
          <template #default="{ row }"><span class="mono">{{ row.base_url }}</span></template>
        </el-table-column>
        <el-table-column prop="model" label="模型" min-width="140" />
        <el-table-column label="API Key" width="96">
          <template #default="{ row }">
            <el-tag :type="row.api_key_set ? 'success' : 'info'" size="small" effect="plain">{{ row.api_key_set ? '已设置' : '无' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="上下文" width="96">
          <template #default="{ row }">{{ row.context_tokens?.toLocaleString() }}</template>
        </el-table-column>
        <el-table-column label="操作" width="330" fixed="right">
          <template #default="{ row }">
            <el-button size="small" plain :loading="testingId === row.id" @click="test(row as LlmProvider)">测试连接</el-button>
            <el-button size="small" type="success" :disabled="row.active" :loading="activatingId === row.id" @click="activate(row as LlmProvider)">
              设为当前
            </el-button>
            <el-button size="small" :icon="Edit" @click="openEdit(row as LlmProvider)">编辑</el-button>
            <el-button size="small" type="danger" plain :icon="Delete" @click="remove(row as LlmProvider)" />
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- Test result -->
    <el-dialog v-model="testVisible" title="连接测试结果" width="520px">
      <template v-if="testResult">
        <el-result
          :icon="testResult.ok ? 'success' : 'error'"
          :title="testResult.ok ? '连接成功' : '连接失败'"
          :sub-title="`耗时 ${testResult.elapsed_ms} ms`"
        />
        <el-input
          v-if="testResult.reply || testResult.error"
          type="textarea"
          readonly
          :autosize="{ minRows: 2, maxRows: 10 }"
          :model-value="testResult.ok ? testResult.reply ?? '' : testResult.error ?? ''"
        />
      </template>
      <template #footer>
        <el-button type="primary" @click="testVisible = false">确定</el-button>
      </template>
    </el-dialog>

    <!-- Create/Edit dialog -->
    <el-dialog v-model="formVisible" :title="editingId ? '编辑提供方' : '添加提供方'" width="600px" destroy-on-close :close-on-click-modal="false">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="110px">
        <el-form-item v-if="!editingId" label="预设">
          <el-select v-model="preset" placeholder="选择预设快速填充" @change="applyPreset" style="width: 100%">
            <el-option v-for="p in PRESETS" :key="p.key" :label="p.label" :value="p.key" />
          </el-select>
        </el-form-item>
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" placeholder="如：阿里云百炼" />
        </el-form-item>
        <el-form-item label="Base URL" prop="base_url">
          <el-input v-model="form.base_url" placeholder="https://.../v1" />
        </el-form-item>
        <el-form-item label="API Key">
          <el-input
            v-model="form.api_key"
            type="password"
            show-password
            autocomplete="new-password"
            :placeholder="editingKeySet ? '已设置（留空则保持不变）' : '请输入 API Key'"
          />
        </el-form-item>
        <el-form-item label="模型" prop="model">
          <div class="model-row">
            <el-select
              v-model="form.model"
              filterable
              allow-create
              default-first-option
              :reserve-keyword="false"
              placeholder="选择或直接输入模型名"
              class="model-select"
              no-data-text="点击右侧按钮获取模型列表，或直接输入"
            >
              <el-option v-for="m in modelOptions" :key="m" :label="m" :value="m" />
            </el-select>
            <el-tooltip content="通过服务器请求 {base_url}/models（API Key 留空时使用已保存的配置）">
              <el-button :loading="fetchingModels" :disabled="!form.base_url.trim()" @click="fetchModels">获取模型列表</el-button>
            </el-tooltip>
          </div>
        </el-form-item>
        <el-collapse class="adv">
          <el-collapse-item title="高级参数" name="adv">
            <el-form-item label="上下文 tokens">
              <el-input-number v-model="form.context_tokens" :min="1024" :step="1024" controls-position="right" />
              <span class="muted hint">决定总结时的分块大小，默认 32000</span>
            </el-form-item>
            <el-form-item label="max_tokens">
              <el-input-number v-model="form.max_tokens" :min="1" :step="256" controls-position="right" placeholder="默认" />
            </el-form-item>
            <el-form-item label="temperature">
              <el-input-number v-model="form.temperature" :min="0" :max="2" :step="0.1" :precision="2" controls-position="right" placeholder="默认" />
            </el-form-item>
            <el-form-item label="top_p">
              <el-input-number v-model="form.top_p" :min="0" :max="1" :step="0.05" :precision="2" controls-position="right" placeholder="默认" />
            </el-form-item>
          </el-collapse-item>
        </el-collapse>
      </el-form>
      <template #footer>
        <el-button @click="formVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { Delete, Edit, Plus, Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { api } from '@/api'
import type { LlmProvider, LlmProviderInput, LlmTestResult } from '@/api/types'
import { useAdminEvents } from '@/composables/useEvents'

const PRESETS = [
  { key: 'bailian', label: '阿里云百炼', name: '阿里云百炼', base_url: 'https://dashscope.aliyuncs.com/compatible-mode/v1', model: 'qwen-plus', context_tokens: 128000 },
  { key: 'deepseek', label: 'DeepSeek', name: 'DeepSeek', base_url: 'https://api.deepseek.com/v1', model: 'deepseek-chat', context_tokens: 64000 },
  { key: 'custom', label: 'OpenAI 兼容中转（自定义）', name: '', base_url: '', model: '', context_tokens: 32000 },
]

const providers = ref<LlmProvider[]>([])
const loading = ref(false)
const testingId = ref<string | null>(null)
const activatingId = ref<string | null>(null)
const testVisible = ref(false)
const testResult = ref<LlmTestResult | null>(null)

async function load() {
  loading.value = true
  try {
    providers.value = await api.llmProviders()
  } catch {
    /* shown */
  } finally {
    loading.value = false
  }
}

async function test(row: LlmProvider) {
  testingId.value = row.id
  try {
    testResult.value = await api.llmTest(row.id)
    testVisible.value = true
  } catch {
    /* shown */
  } finally {
    testingId.value = null
  }
}

async function activate(row: LlmProvider) {
  try {
    await ElMessageBox.confirm(`将「${row.name} / ${row.model}」设为当前大模型？之后所有客户端的总结都将使用它。`, '设为当前', {
      type: 'info',
    })
  } catch {
    return
  }
  activatingId.value = row.id
  try {
    const cap = await api.llmActivate(row.id)
    if (cap && !cap.ready && cap.error) ElMessage.warning(`已切换，但模型未就绪：${cap.error}`)
    else ElMessage.success('已设为当前')
    await load()
  } catch {
    /* shown */
  } finally {
    activatingId.value = null
  }
}

async function remove(row: LlmProvider) {
  try {
    await ElMessageBox.confirm(
      `确定删除提供方「${row.name}」？${row.active ? '它是当前使用的提供方，删除后总结功能将不可用。' : ''}`,
      '删除提供方',
      { type: 'warning', confirmButtonText: '删除', confirmButtonClass: 'el-button--danger' },
    )
  } catch {
    return
  }
  try {
    await api.llmDelete(row.id)
    ElMessage.success('已删除')
    await load()
  } catch {
    /* shown */
  }
}

// ---- Form ----
const formVisible = ref(false)
const formRef = ref<FormInstance>()
const editingId = ref<string | null>(null)
const editingKeySet = ref(false)
const preset = ref<string>('')
const saving = ref(false)
const fetchingModels = ref(false)
const modelOptions = ref<string[]>([])

interface FormState {
  name: string
  base_url: string
  model: string
  api_key: string
  max_tokens: number | null | undefined
  temperature: number | null | undefined
  top_p: number | null | undefined
  context_tokens: number
}
const form = reactive<FormState>({
  name: '',
  base_url: '',
  model: '',
  api_key: '',
  max_tokens: undefined,
  temperature: undefined,
  top_p: undefined,
  context_tokens: 32000,
})
const rules: FormRules = {
  name: [{ required: true, message: '请输入名称', trigger: 'blur' }],
  base_url: [
    { required: true, message: '请输入 Base URL', trigger: 'blur' },
    { pattern: /^https?:\/\//, message: '需以 http:// 或 https:// 开头', trigger: 'blur' },
  ],
  model: [{ required: true, message: '请选择或输入模型', trigger: 'change' }],
}

function resetForm() {
  Object.assign(form, {
    name: '',
    base_url: '',
    model: '',
    api_key: '',
    max_tokens: undefined,
    temperature: undefined,
    top_p: undefined,
    context_tokens: 32000,
  })
  modelOptions.value = []
  preset.value = ''
}

function openCreate() {
  resetForm()
  editingId.value = null
  editingKeySet.value = false
  formVisible.value = true
}

function openEdit(row: LlmProvider) {
  resetForm()
  editingId.value = row.id
  editingKeySet.value = row.api_key_set
  Object.assign(form, {
    name: row.name,
    base_url: row.base_url,
    model: row.model,
    api_key: '',
    max_tokens: row.max_tokens ?? undefined,
    temperature: row.temperature ?? undefined,
    top_p: row.top_p ?? undefined,
    context_tokens: row.context_tokens || 32000,
  })
  modelOptions.value = row.model ? [row.model] : []
  formVisible.value = true
}

function applyPreset(key: string) {
  const p = PRESETS.find((x) => x.key === key)
  if (!p) return
  form.name = p.name
  form.base_url = p.base_url
  form.model = p.model
  form.context_tokens = p.context_tokens
  modelOptions.value = p.model ? [p.model] : []
}

async function fetchModels() {
  const baseUrl = form.base_url.trim().replace(/\/+$/, '')
  if (!baseUrl) return
  fetchingModels.value = true
  try {
    const list = await api.llmModelsProbe({
      base_url: baseUrl,
      api_key: form.api_key || null,
      provider_id: editingId.value,
    })
    if (!list?.length) {
      ElMessage.warning('未获取到模型列表（接口可能不支持 /models），请直接输入模型名')
    } else {
      modelOptions.value = Array.from(new Set([...list, form.model].filter(Boolean)))
      ElMessage.success(`获取到 ${list.length} 个模型`)
    }
  } catch {
    /* shown */
  } finally {
    fetchingModels.value = false
  }
}

function numOrNull(v: number | null | undefined): number | null {
  return typeof v === 'number' && !isNaN(v) ? v : null
}

async function save() {
  const ok = await formRef.value?.validate().catch(() => false)
  if (!ok) return
  const input: LlmProviderInput = {
    name: form.name.trim(),
    base_url: form.base_url.trim().replace(/\/+$/, ''),
    model: String(form.model).trim(),
    max_tokens: numOrNull(form.max_tokens),
    temperature: numOrNull(form.temperature),
    top_p: numOrNull(form.top_p),
    context_tokens: form.context_tokens || 32000,
  }
  if (form.api_key) input.api_key = form.api_key
  saving.value = true
  try {
    if (editingId.value) {
      await api.llmUpdate(editingId.value, input)
      ElMessage.success('已保存')
    } else {
      await api.llmCreate(input)
      ElMessage.success('已添加')
    }
    formVisible.value = false
    await load()
  } catch {
    /* shown */
  } finally {
    saving.value = false
  }
}

useAdminEvents({ llm: () => load() })
onMounted(load)
</script>

<style scoped>
.name {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 500;
}
.model-row {
  display: flex;
  gap: 8px;
  width: 100%;
}
.model-select {
  flex: 1;
}
.hint {
  margin-left: 8px;
  font-size: 12px;
}
.adv {
  border-top: none;
  margin-left: 30px;
}
</style>
