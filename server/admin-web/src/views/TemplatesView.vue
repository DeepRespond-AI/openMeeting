<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h2>总结模板</h2>
        <div class="sub">
          客户端不能选择模板：每次生成总结时，大模型会根据各模板的「适用场景」从已启用的模板中自动挑选一个，挑选失败时使用默认模板。模板对用户不可见。
        </div>
      </div>
      <div class="toolbar">
        <el-button type="primary" :icon="Plus" @click="openCreate">添加模板</el-button>
        <el-button :icon="Refresh" :loading="loading" @click="load">刷新</el-button>
      </div>
    </div>

    <el-card shadow="never">
      <el-table :data="templates" v-loading="loading" stripe empty-text="尚未添加总结模板">
        <el-table-column label="名称" min-width="180">
          <template #default="{ row }">
            <div class="name">
              <span>{{ row.name }}</span>
              <el-tag v-if="row.is_default" type="success" size="small" effect="dark">默认</el-tag>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="适用场景" min-width="260">
          <template #default="{ row }"><span class="desc">{{ row.description }}</span></template>
        </el-table-column>
        <el-table-column label="输出模式" width="110">
          <template #default="{ row }">
            <el-tag size="small" effect="plain" :type="FORMATS[row.output_format as SummaryOutputFormat].tag">
              {{ FORMATS[row.output_format as SummaryOutputFormat].label }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="启用" width="80">
          <template #default="{ row }">
            <el-switch
              :model-value="row.enabled"
              :loading="togglingId === row.id"
              @change="(v: string | number | boolean) => toggle(row as SummaryTemplate, Boolean(v))"
            />
          </template>
        </el-table-column>
        <el-table-column label="更新时间" width="170">
          <template #default="{ row }">{{ formatDateTime(row.updated_at) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="250" fixed="right">
          <template #default="{ row }">
            <el-button size="small" type="success" plain :disabled="row.is_default || !row.enabled" @click="makeDefault(row as SummaryTemplate)">
              设为默认
            </el-button>
            <el-button size="small" :icon="Edit" @click="openEdit(row as SummaryTemplate)">编辑</el-button>
            <el-button size="small" type="danger" plain :icon="Delete" @click="remove(row as SummaryTemplate)" />
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog
      v-model="formVisible"
      :title="editingId ? '编辑模板' : '添加模板'"
      width="760px"
      destroy-on-close
      :close-on-click-modal="false"
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-width="96px">
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" maxlength="200" placeholder="如：周例会纪要" />
        </el-form-item>
        <el-form-item label="适用场景" prop="description">
          <el-input
            v-model="form.description"
            type="textarea"
            :autosize="{ minRows: 2, maxRows: 4 }"
            placeholder="描述这个模板适合什么会议。大模型据此自动挑选模板，请写清楚会议类型、参与方、典型内容"
          />
        </el-form-item>
        <el-form-item label="输出模式" prop="output_format">
          <div class="format-field">
            <el-radio-group v-model="form.output_format">
              <el-radio-button v-for="(f, key) in FORMATS" :key="key" :value="key">{{ f.label }}</el-radio-button>
            </el-radio-group>
            <div class="muted hint">{{ FORMATS[form.output_format].hint }}</div>
          </div>
        </el-form-item>
        <el-form-item label="提示词" prop="prompt">
          <el-input
            v-model="form.prompt"
            type="textarea"
            class="prompt"
            :autosize="{ minRows: 10, maxRows: 24 }"
            placeholder="完整描述报告要求，例如输出语言、需要哪些章节、每个章节写什么、列表/表格的格式等"
          />
          <div class="muted hint">
            提示词会原样作为系统提示词发给大模型，服务器不附加任何规则（不限定语言、格式、标题，也不做翻译），所有要求都要写在这里，包括输出语言和与「输出模式」一致的格式。报告若以一级标题开头（Markdown 的 # 或 HTML 的 &lt;h1&gt;），该标题会成为会议名称。
          </div>
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.enabled" active-text="启用" />
          <el-checkbox v-model="form.is_default" :disabled="!form.enabled" class="default-check">设为默认模板</el-checkbox>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="formVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref, watch } from 'vue'
import { Delete, Edit, Plus, Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { api } from '@/api'
import type { SummaryOutputFormat, SummaryTemplate, SummaryTemplateInput } from '@/api/types'
import { formatDateTime } from '@/utils'

const FORMATS: Record<SummaryOutputFormat, { label: string; tag: 'info' | 'warning' | 'primary'; hint: string }> = {
  markdown: { label: 'Markdown', tag: 'info', hint: '客户端按 Markdown 渲染（标题、列表、表格等），可直接编辑。请在提示词中要求输出 Markdown。' },
  html: {
    label: 'HTML',
    tag: 'warning',
    hint: '客户端按 HTML 只读展示：完整 HTML 文档会被裁成 <body> 内容；<style> 只有桌面端生效，需要各端一致请在提示词中要求使用内联 style；脚本、外部资源会被过滤。',
  },
  mixed: {
    label: '混合',
    tag: 'primary',
    hint: '客户端按 Markdown 渲染并支持内嵌 HTML（如彩色文字、<mark>、<details> 折叠、合并单元格的表格），只读展示。',
  },
}

const templates = ref<SummaryTemplate[]>([])
const loading = ref(false)
const togglingId = ref<string | null>(null)

async function load() {
  loading.value = true
  try {
    templates.value = await api.summaryTemplates()
  } catch {
    /* shown */
  } finally {
    loading.value = false
  }
}

function toInput(t: SummaryTemplate): SummaryTemplateInput {
  return {
    name: t.name,
    description: t.description,
    prompt: t.prompt,
    output_format: t.output_format,
    enabled: t.enabled,
    is_default: t.is_default,
  }
}

async function toggle(row: SummaryTemplate, enabled: boolean) {
  togglingId.value = row.id
  try {
    await api.summaryTemplateUpdate(row.id, { ...toInput(row), enabled })
    ElMessage.success(enabled ? '已启用' : '已停用')
    await load()
  } catch {
    /* shown */
  } finally {
    togglingId.value = null
  }
}

async function makeDefault(row: SummaryTemplate) {
  try {
    await api.summaryTemplateUpdate(row.id, { ...toInput(row), is_default: true })
    ElMessage.success('已设为默认模板')
    await load()
  } catch {
    /* shown */
  }
}

async function remove(row: SummaryTemplate) {
  try {
    await ElMessageBox.confirm(`确定删除模板「${row.name}」？已生成的总结不受影响。`, '删除模板', {
      type: 'warning',
      confirmButtonText: '删除',
      confirmButtonClass: 'el-button--danger',
    })
  } catch {
    return
  }
  try {
    await api.summaryTemplateDelete(row.id)
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
const saving = ref(false)

const emptyForm = (): SummaryTemplateInput => ({
  name: '',
  description: '',
  prompt: '',
  output_format: 'markdown',
  enabled: true,
  is_default: false,
})
const form = reactive<SummaryTemplateInput>(emptyForm())
const notBlank = (message: string) => ({
  validator: (_: unknown, v: string, cb: (e?: Error) => void) => (v?.trim() ? cb() : cb(new Error(message))),
  trigger: 'blur',
})
const rules: FormRules = {
  name: [notBlank('请输入名称')],
  description: [notBlank('请描述适用场景，大模型据此挑选模板')],
  prompt: [notBlank('请输入提示词')],
}

watch(
  () => form.enabled,
  (enabled) => {
    if (!enabled) form.is_default = false
  },
)

function openCreate() {
  Object.assign(form, emptyForm())
  editingId.value = null
  formVisible.value = true
}

function openEdit(row: SummaryTemplate) {
  Object.assign(form, toInput(row))
  editingId.value = row.id
  formVisible.value = true
}

async function save() {
  const ok = await formRef.value?.validate().catch(() => false)
  if (!ok) return
  const input: SummaryTemplateInput = {
    ...form,
    name: form.name.trim(),
    description: form.description.trim(),
    prompt: form.prompt.trim(),
  }
  saving.value = true
  try {
    if (editingId.value) {
      await api.summaryTemplateUpdate(editingId.value, input)
      ElMessage.success('已保存')
    } else {
      await api.summaryTemplateCreate(input)
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

onMounted(load)
</script>

<style scoped>
.name {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 500;
}
.desc {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.format-field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.hint {
  font-size: 12px;
  line-height: 1.5;
}
.prompt :deep(textarea) {
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 13px;
}
.default-check {
  margin-left: 16px;
}
</style>
