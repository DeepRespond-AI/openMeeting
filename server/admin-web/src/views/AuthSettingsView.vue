<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h2>短信与注册</h2>
        <div class="sub">桌面客户端使用手机号 + 短信验证码登录，验证码通过阿里云短信服务发送。</div>
      </div>
      <el-button :icon="Refresh" :loading="loading" @click="loadSettings">刷新</el-button>
    </div>

    <el-row :gutter="16">
      <el-col :xs="24" :lg="14" class="col">
        <!-- Registration -->
        <el-card shadow="never" v-loading="loading && !settings">
          <template #header>
            <div class="card-title"><span>注册设置</span></div>
          </template>
          <div class="reg-row">
            <el-switch
              :model-value="settings?.registration_open ?? false"
              :loading="savingReg"
              :disabled="!settings"
              active-text="开放注册"
              @change="(v: string | number | boolean) => toggleRegistration(Boolean(v))"
            />
          </div>
          <div class="muted small help-line">
            开放注册：任何收到验证码的手机号都可注册使用。关闭后，仅管理员在「用户管理」中预先创建的手机号可以登录。
          </div>
        </el-card>

        <!-- Aliyun SMS -->
        <el-card shadow="never" v-loading="loading && !settings">
          <template #header>
            <div class="card-title">
              <span>阿里云短信配置</span>
              <el-tag v-if="settings" :type="settings.sms_ready ? 'success' : 'warning'" effect="dark">
                {{ settings.sms_ready ? '短信已就绪' : '未配置' }}
              </el-tag>
            </div>
          </template>
          <el-form ref="formRef" :model="form" :rules="rules" label-width="120px" @submit.prevent="saveSms">
            <el-form-item label="AccessKey ID" prop="access_key_id">
              <el-input v-model="form.access_key_id" placeholder="LTAI..." autocomplete="off" />
            </el-form-item>
            <el-form-item label="AccessKey Secret" prop="access_key_secret">
              <el-input
                v-model="form.access_key_secret"
                type="password"
                show-password
                autocomplete="new-password"
                :placeholder="settings?.sms.access_key_secret_set ? '已设置（留空保持不变）' : '请输入 AccessKey Secret'"
              />
            </el-form-item>
            <el-form-item label="短信签名" prop="sign_name">
              <el-input v-model="form.sign_name" placeholder="SignName，如：深应会议" />
            </el-form-item>
            <el-form-item label="模板 CODE" prop="template_code">
              <el-input v-model="form.template_code" placeholder="TemplateCode，如：SMS_123456789" />
            </el-form-item>
            <el-form-item label="模板变量名" prop="template_param">
              <el-input v-model="form.template_param" placeholder="code">
                <template #append>{{ '${' + (form.template_param || 'code') + '}' }}</template>
              </el-input>
            </el-form-item>
            <el-form-item label="Endpoint" prop="endpoint">
              <el-input v-model="form.endpoint" placeholder="dysmsapi.aliyuncs.com" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="savingSms" @click="saveSms">保存配置</el-button>
              <el-button @click="resetForm">重置</el-button>
            </el-form-item>
          </el-form>

          <el-divider content-position="left">发送测试短信</el-divider>
          <div class="test-row">
            <el-input v-model="testPhone" placeholder="接收测试短信的手机号" maxlength="16" style="max-width: 240px" @keyup.enter="sendTest" />
            <el-button type="primary" plain :icon="Promotion" :loading="testing" :disabled="!settings?.sms_ready" @click="sendTest">
              发送测试短信
            </el-button>
            <span v-if="settings && !settings.sms_ready" class="muted small">请先完成并保存短信配置</span>
          </div>
          <el-alert
            v-if="testResult"
            class="test-result"
            :type="testResult.ok ? 'success' : 'error'"
            show-icon
            :closable="false"
            :title="testResult.ok ? '发送成功，请查收短信' : '发送失败'"
          >
            <div v-if="testResult.request_id" class="small">RequestId：<span class="mono">{{ testResult.request_id }}</span></div>
            <div v-if="testResult.error" class="small err-text">{{ testResult.error }}</div>
          </el-alert>
        </el-card>
      </el-col>

      <el-col :xs="24" :lg="10" class="col">
        <el-card shadow="never" class="help">
          <template #header>
            <div class="card-title"><span>阿里云控制台配置步骤</span></div>
          </template>
          <ol class="steps">
            <li>登录阿里云控制台，<b>开通短信服务</b>（Dysms）。</li>
            <li>在「国内消息 → 签名管理」中<b>申请签名</b>，审核通过后填入「短信签名」。</li>
            <li>
              在「模板管理」中<b>申请验证码模板</b>，内容须包含 <code>${code}</code>，例如：
              <div class="example">您的验证码为：${code}，5 分钟内有效，请勿泄露。</div>
              审核通过后将模板 CODE（如 SMS_123456789）填入「模板 CODE」；若变量名不是 code，请同步修改「模板变量名」。
            </li>
            <li>
              在「访问控制 RAM」中<b>创建 RAM 用户</b>并生成 <b>AccessKey</b>，为其<b>授权 AliyunDysmsFullAccess</b>
              权限，然后填入 AccessKey ID / Secret。
            </li>
            <li>保存配置后，使用「发送测试短信」验证是否能正常收到验证码。</li>
          </ol>
          <div class="muted small">
            提示：建议使用仅授予短信权限的 RAM 子账号 AccessKey，不要使用主账号 AccessKey。
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- SMS logs -->
    <el-card shadow="never">
      <template #header>
        <div class="card-title">
          <span>短信发送记录</span>
          <div class="toolbar">
            <el-input
              v-model="logPhone"
              placeholder="按手机号筛选"
              clearable
              :prefix-icon="Search"
              size="small"
              style="width: 180px"
              @keyup.enter="searchLogs"
              @clear="searchLogs"
            />
            <el-button size="small" type="primary" @click="searchLogs">查询</el-button>
            <el-button size="small" :icon="Refresh" :loading="logsLoading" @click="loadLogs" />
          </div>
        </div>
      </template>
      <el-table :data="logs" stripe size="small" v-loading="logsLoading" empty-text="暂无发送记录">
        <el-table-column label="时间" width="170">
          <template #default="{ row }">{{ formatDateTime(row.created_at) }}</template>
        </el-table-column>
        <el-table-column label="手机号" width="160">
          <template #default="{ row }"><PhoneText :phone="row.phone" /></template>
        </el-table-column>
        <el-table-column label="用途" width="90">
          <template #default="{ row }">
            <el-tag size="small" effect="plain" :type="purposeType(row.purpose)">{{ PURPOSE_LABEL[row.purpose] ?? row.purpose }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="IP" min-width="120">
          <template #default="{ row }"><span class="mono">{{ row.ip || '-' }}</span></template>
        </el-table-column>
        <el-table-column label="结果" width="80">
          <template #default="{ row }">
            <el-tag size="small" :type="row.ok ? 'success' : 'danger'">{{ row.ok ? '成功' : '失败' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="错误信息" min-width="200" show-overflow-tooltip>
          <template #default="{ row }"><span :class="row.error ? 'err-text' : 'muted'">{{ row.error || '-' }}</span></template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination
          v-model:current-page="logPage"
          v-model:page-size="logPageSize"
          :total="logTotal"
          :page-sizes="[20, 50, 100]"
          layout="total, sizes, prev, pager, next"
          background
          small
          @current-change="loadLogs"
          @size-change="searchLogs"
        />
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { Promotion, Refresh, Search } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { api } from '@/api'
import type { AuthSettings, SmsConfigInput, SmsLog, SmsTestResult } from '@/api/types'
import PhoneText from '@/components/PhoneText.vue'
import { formatDateTime, normalizePhone, PHONE_RE } from '@/utils'

const DEFAULT_ENDPOINT = 'dysmsapi.aliyuncs.com'
const DEFAULT_PARAM = 'code'

const PURPOSE_LABEL: Record<string, string> = { register: '注册', login: '登录', test: '测试' }
function purposeType(p: string) {
  return p === 'register' ? 'success' : p === 'login' ? 'primary' : 'info'
}

const settings = ref<AuthSettings | null>(null)
const loading = ref(false)

const formRef = ref<FormInstance>()
const form = reactive({
  access_key_id: '',
  access_key_secret: '',
  sign_name: '',
  template_code: '',
  template_param: DEFAULT_PARAM,
  endpoint: DEFAULT_ENDPOINT,
})
const rules: FormRules = {
  template_param: [{ pattern: /^[A-Za-z_][A-Za-z0-9_]*$/, message: '变量名只能包含字母、数字和下划线', trigger: 'blur' }],
  endpoint: [{ pattern: /^[A-Za-z0-9.-]+$/, message: '请输入域名，如 dysmsapi.aliyuncs.com（不含 https://）', trigger: 'blur' }],
}

function resetForm() {
  const sms = settings.value?.sms
  form.access_key_id = sms?.access_key_id ?? ''
  form.access_key_secret = ''
  form.sign_name = sms?.sign_name ?? ''
  form.template_code = sms?.template_code ?? ''
  form.template_param = sms?.template_param || DEFAULT_PARAM
  form.endpoint = sms?.endpoint || DEFAULT_ENDPOINT
  formRef.value?.clearValidate()
}

async function loadSettings() {
  loading.value = true
  try {
    settings.value = await api.authSettings()
    resetForm()
  } catch {
    /* shown */
  } finally {
    loading.value = false
  }
}

// ---- Registration toggle ----
const savingReg = ref(false)
async function toggleRegistration(open: boolean) {
  if (!open) {
    try {
      await ElMessageBox.confirm('关闭开放注册后，新手机号将无法自助注册，仅已存在的用户可以登录。确定关闭？', '关闭开放注册', {
        type: 'warning',
      })
    } catch {
      return
    }
  }
  savingReg.value = true
  try {
    settings.value = await api.saveAuthSettings({ registration_open: open })
    ElMessage.success(open ? '已开放注册' : '已关闭开放注册')
  } catch {
    /* shown */
  } finally {
    savingReg.value = false
  }
}

// ---- SMS config ----
const savingSms = ref(false)
async function saveSms() {
  if (!formRef.value) return
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  const sms: SmsConfigInput = {
    access_key_id: form.access_key_id.trim(),
    sign_name: form.sign_name.trim(),
    template_code: form.template_code.trim(),
    template_param: form.template_param.trim() || DEFAULT_PARAM,
    endpoint: form.endpoint.trim().replace(/^https?:\/\//, '').replace(/\/+$/, '') || DEFAULT_ENDPOINT,
  }
  const secret = form.access_key_secret.trim()
  if (secret) sms.access_key_secret = secret
  savingSms.value = true
  try {
    settings.value = await api.saveAuthSettings({ sms })
    resetForm()
    ElMessage.success(settings.value?.sms_ready ? '已保存，短信已就绪' : '已保存（配置尚不完整）')
  } catch {
    /* shown */
  } finally {
    savingSms.value = false
  }
}

// ---- Test SMS ----
const testPhone = ref('')
const testing = ref(false)
const testResult = ref<SmsTestResult | null>(null)
async function sendTest() {
  const phone = normalizePhone(testPhone.value)
  if (!PHONE_RE.test(phone)) {
    ElMessage.warning('请输入有效的 11 位手机号')
    return
  }
  testing.value = true
  testResult.value = null
  try {
    testResult.value = await api.smsTest(phone)
    loadLogs()
  } catch {
    /* shown */
  } finally {
    testing.value = false
  }
}

// ---- Logs ----
const logs = ref<SmsLog[]>([])
const logTotal = ref(0)
const logPage = ref(1)
const logPageSize = ref(20)
const logPhone = ref('')
const logsLoading = ref(false)

async function loadLogs() {
  logsLoading.value = true
  try {
    const res = await api.smsLogs({
      phone: normalizePhone(logPhone.value) || undefined,
      limit: logPageSize.value,
      offset: (logPage.value - 1) * logPageSize.value,
    })
    logs.value = res?.items ?? []
    logTotal.value = res?.total ?? 0
  } catch {
    /* shown */
  } finally {
    logsLoading.value = false
  }
}
function searchLogs() {
  logPage.value = 1
  loadLogs()
}

onMounted(() => {
  loadSettings()
  loadLogs()
})
</script>

<style scoped>
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
.help-line {
  margin-top: 10px;
  line-height: 1.6;
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
.steps code {
  background: #f5f7fa;
  padding: 1px 4px;
  border-radius: 3px;
}
.example {
  background: #f5f7fa;
  border-left: 3px solid #409eff;
  padding: 4px 8px;
  margin: 4px 0;
  color: #606266;
}
.pager {
  display: flex;
  justify-content: flex-end;
  margin-top: 12px;
}
</style>
