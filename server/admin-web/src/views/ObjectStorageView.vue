<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h2>对象存储</h2>
        <div class="sub">统一管理会议录音和版本安装包的对象存储，支持 Docker MinIO 与阿里云 OSS；通过环境变量切换。</div>
      </div>
      <el-button :icon="Refresh" :loading="loading" @click="loadSettings">刷新</el-button>
    </div>

    <el-row :gutter="16">
      <el-col :xs="24" :lg="14" class="col">
        <el-card shadow="never" v-loading="loading && !settings">
          <template #header>
            <div class="card-title">
              <span>{{ providerName }} 配置</span>
              <el-tag v-if="settings" :type="settings.oss_ready ? 'success' : 'warning'" effect="dark">
                {{ settings.oss_ready ? `${providerName} 已配置` : settings.provider === 'local' ? '使用本地存储' : '对象存储未配置完整' }}
              </el-tag>
            </div>
          </template>
          <el-alert
            v-if="settings?.env_overrides.length"
            class="env-alert"
            type="info"
            show-icon
            :closable="false"
            :title="`以下字段由环境变量指定，在此处修改不会生效：${settings.env_overrides.map((f) => FIELD_LABEL[f]).join('、')}`"
          />
          <el-form ref="formRef" :model="form" :rules="rules" label-width="130px" @submit.prevent="save">
            <el-form-item label="Endpoint" prop="endpoint">
              <el-input v-model="form.endpoint" :disabled="locked('endpoint')" :placeholder="settings?.provider === 'minio' ? 'http://minio:9000' : 'oss-cn-hangzhou.aliyuncs.com'" />
            </el-form-item>
            <el-form-item label="Region" prop="region">
              <el-input
                v-model="form.region"
                :disabled="locked('region')"
                :placeholder="derivedRegion ? `留空自动识别：${derivedRegion}` : settings?.provider === 'minio' ? 'us-east-1' : '如 cn-hangzhou'"
              />
            </el-form-item>
            <el-form-item label="Bucket" prop="bucket">
              <el-input v-model="form.bucket" :disabled="locked('bucket')" placeholder="Bucket 名称" />
            </el-form-item>
            <el-form-item label="AccessKey ID" prop="access_key_id">
              <el-input v-model="form.access_key_id" :disabled="locked('access_key_id')" placeholder="LTAI..." autocomplete="off" />
            </el-form-item>
            <el-form-item label="AccessKey Secret" prop="access_key_secret">
              <el-input
                v-model="form.access_key_secret"
                type="password"
                show-password
                autocomplete="new-password"
                :disabled="locked('access_key_secret')"
                :placeholder="settings?.oss.access_key_secret_set ? '已设置（留空保持不变）' : '请输入 AccessKey Secret'"
              />
            </el-form-item>
            <el-form-item label="路径前缀" prop="prefix">
              <el-input v-model="form.prefix" :disabled="locked('prefix')" placeholder="可选，如 openmeeting">
                <template #append>/业务目录/…</template>
              </el-input>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="saving" :disabled="settings?.provider !== 'oss'" @click="save">保存配置</el-button>
              <el-button @click="resetForm">重置</el-button>
              <el-button
                v-if="settings?.oss.access_key_secret_set && !locked('access_key_secret')"
                type="danger"
                plain
                @click="clearSecret"
              >
                停用 OSS
              </el-button>
            </el-form-item>
          </el-form>

          <el-alert v-if="settings?.provider === 'minio'" class="env-alert" type="info" :closable="false" show-icon
            :title="`客户端下载地址：${settings.public_endpoint || '未配置'}。手机需要能访问此地址；不能使用容器名或手机自身的 localhost。`" />
          <el-divider content-position="left">连接测试</el-divider>
          <div class="test-row">
            <el-button type="primary" plain :icon="Connection" :loading="testing" :disabled="!settings?.oss_ready" @click="runTest">
              测试连接
            </el-button>
            <span class="muted small">
              {{ settings?.oss_ready ? '写入、读取并删除一个测试对象' : '请先完成对象存储配置' }}
            </span>
          </div>
          <el-alert
            v-if="testResult"
            class="test-result"
            :type="testResult.ok ? 'success' : 'error'"
            show-icon
            :closable="false"
            :title="testResult.ok ? '连接成功，读写正常' : '连接失败'"
          >
            <div v-if="testResult.error" class="small err-text">{{ testResult.error }}</div>
          </el-alert>
        </el-card>

        <el-card shadow="never">
          <template #header>
            <div class="card-title"><span>使用范围</span></div>
          </template>
          <el-descriptions :column="1" border size="small">
            <el-descriptions-item label="会议录音">{{ settings?.oss.prefix ?? '' }}audio/…</el-descriptions-item>
            <el-descriptions-item label="版本安装包">{{ settings?.oss.prefix ?? '' }}releases/…</el-descriptions-item>
          </el-descriptions>
          <p class="muted small">各业务共用 Bucket 和访问凭据，文件按业务目录存放。修改 Bucket 或凭据前，请确保原有文件仍可访问。修改配置不会自动迁移已有文件。</p>
        </el-card>

      </el-col>

      <el-col :xs="24" :lg="10" class="col">
        <el-card shadow="never" class="help">
          <template #header><div class="card-title"><span>存储切换说明</span></div></template>
          <el-alert class="env-alert" type="info" :closable="false" title="OPENMEETING_STORAGE_PROVIDER=minio 使用本地 MinIO，改为 oss 后使用阿里云配置。修改 .env 后重新创建应用容器。旧文件仍按原存储读取，请保留两套配置和数据。" />
          <p v-if="settings?.provider === 'minio'" class="muted small">MinIO 的 Bucket 由 Docker 初始化任务创建，默认保持私有；访问密钥和 Endpoint 在 server/.env 中管理。阿里云就绪后再填写以下配置。</p>
          <ol class="steps">
            <li>在 OSS 控制台<b>创建 Bucket</b>，读写权限选择<b>私有</b>，建议开启服务端加密。</li>
            <li>
              在 Bucket 概览中找到 <b>Endpoint</b>（如 <code>oss-cn-hangzhou.aliyuncs.com</code>）。服务器部署在同地域阿里云 ECS
              时可使用内网 Endpoint（<code>-internal</code>），但客户端下载录音和安装包需要外网访问，因此通常填外网 Endpoint。
            </li>
            <li>
              在「访问控制 RAM」中<b>创建 RAM 用户</b>并生成 AccessKey，授予仅限该 Bucket 的读写权限（PutObject、GetObject、
              DeleteObject、ListObjects 等），然后填入 AccessKey ID / Secret。
            </li>
            <li>保存后点击「测试连接」，确认读写正常。</li>
            <li>如需降低成本，可在 Bucket 中配置<b>生命周期规则</b>，按业务目录设置文件保留与存储类型。</li>
          </ol>
          <div class="muted small">
            客户端通过有效期 1 小时的签名链接从当前对象存储下载。MinIO 使用所部署服务器的磁盘和网络；切换阿里云后由 OSS 提供文件下载。
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { Connection, Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { api } from '@/api'
import type { OssConfigInput, OssField, ObjectStorageSettings, StorageTestResult } from '@/api/types'

const FIELD_LABEL: Record<OssField, string> = {
  endpoint: 'Endpoint',
  region: 'Region',
  bucket: 'Bucket',
  access_key_id: 'AccessKey ID',
  access_key_secret: 'AccessKey Secret',
  prefix: '路径前缀',
}

const settings = ref<ObjectStorageSettings | null>(null)
const providerName = computed(() => settings.value?.provider === 'minio' ? 'MinIO' : settings.value?.provider === 'local' ? '本地存储' : '阿里云 OSS')
const loading = ref(false)

const formRef = ref<FormInstance>()
const form = reactive({ endpoint: '', region: '', bucket: '', access_key_id: '', access_key_secret: '', prefix: '' })
const rules: FormRules = {
  endpoint: [{ pattern: /^(https?:\/\/)?[A-Za-z0-9.-]+\/?$/, message: '请输入域名，如 oss-cn-hangzhou.aliyuncs.com', trigger: 'blur' }],
  region: [{ pattern: /^[a-z0-9-]*$/, message: '地域 ID 形如 cn-hangzhou', trigger: 'blur' }],
  bucket: [{ pattern: /^[a-z0-9-]*$/, message: 'Bucket 名称只能包含小写字母、数字和短横线', trigger: 'blur' }],
}

function cleanEndpoint(v: string) {
  return v.trim().replace(/^https?:\/\//, '').replace(/\/+$/, '')
}

const derivedRegion = computed(() => /oss-([a-z0-9-]+?)(?:-internal)?\.aliyuncs\.com$/.exec(cleanEndpoint(form.endpoint))?.[1] ?? '')

function locked(field: OssField) {
  return settings.value?.env_overrides.includes(field) ?? false
}

function resetForm() {
  const oss = settings.value?.oss
  form.endpoint = oss?.endpoint ?? ''
  // Show an explicit region only when it differs from the one derived from the endpoint.
  const derived = /oss-([a-z0-9-]+?)(?:-internal)?\.aliyuncs\.com$/.exec(oss?.endpoint ?? '')?.[1]
  form.region = oss?.region && oss.region !== derived ? oss.region : ''
  form.bucket = oss?.bucket ?? ''
  form.access_key_id = oss?.access_key_id ?? ''
  form.access_key_secret = ''
  form.prefix = (oss?.prefix ?? '').replace(/\/+$/, '')
  formRef.value?.clearValidate()
}

async function loadSettings() {
  loading.value = true
  try {
    settings.value = await api.objectStorage()
    resetForm()
  } catch {
    /* shown */
  } finally {
    loading.value = false
  }
}

const saving = ref(false)
async function save() {
  if (!formRef.value) return
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  const input: OssConfigInput = {}
  if (!locked('endpoint')) input.endpoint = cleanEndpoint(form.endpoint)
  if (!locked('region')) input.region = form.region.trim()
  if (!locked('bucket')) input.bucket = form.bucket.trim()
  if (!locked('access_key_id')) input.access_key_id = form.access_key_id.trim()
  if (!locked('prefix')) input.prefix = form.prefix.trim()
  const secret = form.access_key_secret.trim()
  if (secret && !locked('access_key_secret')) input.access_key_secret = secret
  saving.value = true
  try {
    settings.value = await api.saveObjectStorage(input)
    resetForm()
    testResult.value = null
    ElMessage.success(settings.value?.oss_ready ? '已保存，对象存储已配置' : '已保存，配置尚不完整')
  } catch {
    /* shown */
  } finally {
    saving.value = false
  }
}

async function clearSecret() {
  try {
    await ElMessageBox.confirm(
      '清除 AccessKey Secret 后 OSS 将停用：新录音和新安装包改为保存在服务器本地，已存入 OSS 的文件将无法访问，直到重新配置。确定停用？',
      '停用 OSS',
      { type: 'warning' },
    )
  } catch {
    return
  }
  try {
    settings.value = await api.saveObjectStorage({ access_key_secret: '' })
    resetForm()
    testResult.value = null
    ElMessage.success('已停用 OSS')
  } catch {
    /* shown */
  }
}

const testing = ref(false)
const testResult = ref<StorageTestResult | null>(null)
async function runTest() {
  testing.value = true
  testResult.value = null
  try {
    testResult.value = await api.objectStorageTest()
  } catch {
    /* shown */
  } finally {
    testing.value = false
  }
}

onMounted(loadSettings)
</script>

<style scoped>
@media (max-width: 600px) {
  :deep(.el-form-item) { display: block; }
  :deep(.el-form-item__label) { display: block; width: auto !important; text-align: left; margin-bottom: 4px; }
  :deep(.el-form-item__content) { margin-left: 0 !important; }
  .env-alert { overflow-wrap: anywhere; }
}
.col {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-bottom: 0;
}
@media (max-width: 1199px) {
  .col + .col {
    margin-top: 16px;
  }
}
.small {
  font-size: 12px;
}
.env-alert {
  margin-bottom: 16px;
}
.test-row {
  display: flex;
  gap: 8px;
  align-items: center;
  flex-wrap: wrap;
}
.test-result {
  margin-top: 12px;
}
.err-text {
  color: #f56c6c;
}
.steps {
  margin: 0 0 12px;
  padding-left: 20px;
  line-height: 1.8;
  font-size: 13px;
}
.steps li {
  margin-bottom: 6px;
}
code {
  background: #f5f7fa;
  padding: 1px 4px;
  border-radius: 3px;
}
</style>
