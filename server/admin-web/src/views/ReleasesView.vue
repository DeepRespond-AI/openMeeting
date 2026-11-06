<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h2>版本发布</h2>
        <div class="sub">
          发布桌面端与 APP 的新版本：客户端启动后和使用中会定期检查更新。可以先只推送给白名单用户，再按比例逐步放量；勾选「强制」或调高「最低支持版本」后，旧版本必须升级才能继续使用。
        </div>
      </div>
      <div class="toolbar">
        <el-button type="primary" :icon="Plus" @click="openCreate">新建版本</el-button>
        <el-button :icon="Refresh" :loading="loading" @click="loadAll">刷新</el-button>
      </div>
    </div>

    <el-tabs v-model="platform" class="platform-tabs">
      <el-tab-pane v-for="(p, key) in PLATFORMS" :key="key" :name="key" :label="p.label" />
    </el-tabs>

    <div class="grid">
      <el-card shadow="never" class="policy">
        <template #header>
          <div class="card-header">
            <span>升级策略</span>
            <el-button size="small" type="primary" :loading="savingPolicy" @click="savePolicy">保存</el-button>
          </div>
        </template>
        <el-form label-width="104px" @submit.prevent>
          <el-form-item label="最低支持版本">
            <el-input v-model="policyForm.min_version" :placeholder="PLATFORMS[platform].versionHint" clearable />
            <div class="muted hint">低于此版本的客户端会被强制升级（不受灰度比例限制），留空表示不限制。</div>
          </el-form-item>
          <el-form-item v-if="platform === 'ios'" label="App Store">
            <el-input v-model="appStoreUrl" placeholder="https://apps.apple.com/cn/app/id..." clearable />
            <div class="muted hint">iOS 只能跳转 App Store 更新，未填写时不会提示升级。</div>
          </el-form-item>
          <el-form-item v-if="platform === 'android'" label="商店渠道">
            <div class="channels">
              <div v-for="(row, i) in storeRows" :key="i" class="channel-row">
                <el-select v-model="row.channel" filterable allow-create placeholder="渠道" class="channel-key">
                  <el-option v-for="(label, key) in ANDROID_STORES" :key="key" :value="key" :label="`${label}（${key}）`" />
                </el-select>
                <el-input v-model="row.url" placeholder="商店页面链接，如 appmarket://details?id=..." />
                <el-button :icon="Delete" text @click="storeRows.splice(i, 1)" />
              </div>
              <el-button size="small" :icon="Plus" class="add-channel" @click="storeRows.push({ channel: '', url: '' })">
                添加渠道
              </el-button>
              <div class="muted hint">
                商店渠道包（打包时 APP_CHANNEL 不是 direct）有新版本时跳转到对应商店；自建渠道（direct）直接下载上传的 APK 安装。
              </div>
            </div>
          </el-form-item>
        </el-form>
      </el-card>

      <el-card shadow="never" class="stats">
        <template #header><span>当前版本分布（近 30 天活跃）</span></template>
        <div v-if="statsRows.length" class="stat-list">
          <div v-for="s in statsRows" :key="s.version" class="stat-row">
            <span class="mono">{{ s.version }}</span>
            <el-progress :percentage="statsPercent(s.count)" :stroke-width="8" :show-text="false" class="stat-bar" />
            <span class="muted">{{ s.count }}</span>
          </div>
        </div>
        <el-empty v-else :image-size="60" description="暂无数据" />
      </el-card>
    </div>

    <el-card shadow="never">
      <el-table :data="releases" v-loading="loading" stripe empty-text="尚未发布版本">
        <el-table-column label="版本" min-width="180">
          <template #default="{ row }">
            <div class="name">
              <span class="mono">{{ row.full_version }}</span>
              <el-tag v-if="row.force" type="danger" size="small" effect="dark">强制</el-tag>
            </div>
            <div v-if="row.notes" class="notes muted">{{ row.notes }}</div>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <el-tag size="small" :type="STATUS[row.status as ReleaseStatus].tag">{{ STATUS[row.status as ReleaseStatus].label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="推送范围" width="150">
          <template #default="{ row }">
            <div>{{ row.rollout_percent === 100 ? '全部用户' : `${row.rollout_percent}% 设备` }}</div>
            <el-tooltip v-if="row.rollout_users.length" :content="userList(row as ClientRelease)">
              <div class="muted small">+ 白名单 {{ row.rollout_users.length }} 人</div>
            </el-tooltip>
          </template>
        </el-table-column>
        <el-table-column v-if="platform !== 'ios'" label="安装包" min-width="360">
          <template #default="{ row }">
            <div v-for="a in row.artifacts" :key="a.id" class="artifact">
              <el-tag size="small" effect="plain">{{ ARCH_LABELS[a.arch] ?? a.arch }}</el-tag>
              <span class="file" :title="`${a.file_name}\nSHA-256: ${a.sha256}`">{{ a.file_name }}</span>
              <span class="muted small">{{ formatBytes(a.size) }} · 下载 {{ a.download_count }}</span>
              <el-button
                tag="a"
                :href="`/api/v1/updates/download/${encodeURIComponent(a.id)}`"
                :download="a.file_name"
                target="_blank"
                rel="noopener noreferrer"
                size="small"
                text
                type="primary"
                :icon="Download"
                :aria-label="`下载 ${a.file_name}`"
              >下载</el-button>
              <el-button
                size="small"
                text
                type="danger"
                :icon="Delete"
                @click="removeArtifact(row as ClientRelease, a as ReleaseArtifact)"
              />
            </div>
            <span v-if="!row.artifacts.length" class="muted small">未上传</span>
          </template>
        </el-table-column>
        <el-table-column label="发布时间" width="170">
          <template #default="{ row }">{{ formatDateTime(row.published_at) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="300">
          <template #default="{ row }">
            <el-button size="small" :icon="Edit" @click="openEdit(row as ClientRelease)">编辑</el-button>
            <el-button v-if="platform !== 'ios'" size="small" :icon="Upload" @click="openUpload(row as ClientRelease)">
              上传
            </el-button>
            <el-button
              v-if="row.status === 'draft' || row.status === 'paused'"
              size="small"
              type="success"
              plain
              @click="act(row as ClientRelease, 'publish')"
            >
              {{ row.status === 'paused' ? '继续' : '发布' }}
            </el-button>
            <el-button v-if="row.status === 'published'" size="small" type="warning" plain @click="act(row as ClientRelease, 'pause')">
              暂停
            </el-button>
            <el-dropdown trigger="click" @command="(c: string) => onMore(row as ClientRelease, c)">
              <el-button size="small" :icon="MoreFilled" class="more" />
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="archive" :disabled="row.status === 'archived'">归档</el-dropdown-item>
                  <el-dropdown-item command="delete" :disabled="row.status !== 'draft' && row.status !== 'archived'">
                    删除
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- Create / edit -->
    <el-dialog
      v-model="formVisible"
      :title="editing ? `编辑版本 ${editing.full_version}` : `新建${PLATFORMS[platform].label}版本`"
      width="min(640px, calc(100vw - 32px))"
      destroy-on-close
      :close-on-click-modal="false"
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-width="96px">
        <el-form-item label="版本号" prop="version">
          <el-input v-model="form.version" placeholder="如 1.2.0" :disabled="!!editing && editing.status !== 'draft'" />
          <div class="muted hint">{{ PLATFORMS[platform].versionNote }}</div>
        </el-form-item>
        <el-form-item v-if="isMobile" label="构建号" prop="build">
          <el-input-number v-model="form.build" :min="0" :disabled="!!editing && editing.status !== 'draft'" />
          <div class="muted hint">与打包时的 build number 一致（pubspec 中 + 后面的数字，Android 即 versionCode）。</div>
        </el-form-item>
        <el-form-item label="更新说明">
          <el-input v-model="form.notes" type="textarea" :autosize="{ minRows: 4, maxRows: 10 }" placeholder="展示在客户端的升级提示里，每行一条" />
        </el-form-item>
        <el-form-item label="强制升级">
          <el-switch v-model="form.force" />
          <span class="muted hint inline">开启后，收到此版本的客户端必须升级才能继续使用。</span>
        </el-form-item>
        <el-form-item label="灰度比例">
          <div class="rollout">
            <el-slider v-model="form.rollout_percent" :step="5" show-stops class="rollout-slider" />
            <el-input-number v-model="form.rollout_percent" :min="0" :max="100" size="small" />
            <span>%</span>
          </div>
          <div class="muted hint">按设备随机抽取，比例调高时已推送的设备保持不变；100% 为全部用户。</div>
        </el-form-item>
        <el-form-item label="白名单用户">
          <el-select
            v-model="form.rollout_users"
            multiple
            filterable
            remote
            :remote-method="searchUsers"
            :loading="searchingUsers"
            placeholder="按手机号或姓名搜索，白名单用户始终会收到此版本"
            class="full"
          >
            <el-option v-for="u in userOptions" :key="u.id" :value="u.id" :label="userLabel(u)" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="formVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-dialog>

    <!-- Upload -->
    <el-dialog v-model="uploadVisible" :title="`上传安装包 · ${uploadTarget?.full_version ?? ''}`" width="min(560px, calc(100vw - 32px))" destroy-on-close :close-on-click-modal="false" :close-on-press-escape="!uploading" :show-close="!uploading">
      <el-form label-width="96px">
        <el-form-item label="架构">
          <el-radio-group v-model="uploadArch" :disabled="uploading">
            <el-radio-button v-for="a in PLATFORMS[platform].arches" :key="a" :value="a">{{ ARCH_LABELS[a] }}</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="安装包">
          <el-upload
            drag
            :auto-upload="false"
            :limit="1"
            :disabled="uploading"
            :on-change="(f: UploadFile) => (uploadFile = f.raw ?? null)"
            :on-remove="() => (uploadFile = null)"
            :accept="PLATFORMS[platform].accept"
            class="full"
          >
            <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
            <div class="el-upload__text">拖拽到此处，或<em>点击选择</em></div>
            <template #tip><div class="el-upload__tip">{{ PLATFORMS[platform].packageHint }}</div></template>
          </el-upload>
        </el-form-item>
        <el-form-item v-if="isDesktop" label="签名文件">
          <el-upload
            :auto-upload="false"
            :limit="1"
            :disabled="uploading"
            :on-change="(f: UploadFile) => (signatureFile = f.raw ?? null)"
            :on-remove="() => (signatureFile = null)"
            accept=".sig"
          >
            <el-button :icon="Document">选择 .sig 文件</el-button>
            <template #tip><div class="el-upload__tip">打包时与更新包一同生成的同名 .sig 文件，客户端用它校验更新包。</div></template>
          </el-upload>
        </el-form-item>
        <el-form-item v-if="uploading || uploadProgress > 0" label="进度">
          <el-progress :percentage="uploadProgress" :indeterminate="uploading && uploadProgress <= 5" class="full" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button :disabled="uploading" @click="uploadVisible = false">取消</el-button>
        <el-button type="primary" :loading="uploading" :disabled="!canUpload" @click="doUpload">上传</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { Delete, Document, Download, Edit, MoreFilled, Plus, Refresh, Upload, UploadFilled } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules, type UploadFile } from 'element-plus'
import { api } from '@/api'
import type {
  AdminUser,
  ClientPlatform,
  ClientRelease,
  ClientReleaseInput,
  ReleaseArtifact,
  ReleaseStats,
  ReleaseStatus,
  ReleaseUserRef,
  UpdatePolicy,
} from '@/api/types'
import { formatBytes, formatDateTime } from '@/utils'

interface PlatformInfo {
  label: string
  arches: string[]
  accept: string
  packageHint: string
  versionHint: string
  versionNote: string
}

const DESKTOP_NOTE = '与 tauri.conf.json 中的 version 一致，格式 1.2.3。'
const MOBILE_NOTE = '与 pubspec.yaml 中 version 的 + 前面部分一致，格式 1.2.3。'
const PLATFORMS: Record<ClientPlatform, PlatformInfo> = {
  windows: {
    label: 'Windows',
    arches: ['x86_64', 'aarch64'],
    accept: '.exe,.msi',
    packageHint: '上传 NSIS 安装包（*-setup.exe），与 .sig 签名文件一起上传。',
    versionHint: '如 0.4.1',
    versionNote: DESKTOP_NOTE,
  },
  macos: {
    label: 'macOS',
    arches: ['aarch64', 'x86_64', 'universal'],
    accept: '.gz',
    packageHint: '上传更新包 *.app.tar.gz（不是 dmg），与 .sig 签名文件一起上传。',
    versionHint: '如 0.4.1',
    versionNote: DESKTOP_NOTE,
  },
  linux: {
    label: 'Linux',
    arches: ['x86_64', 'aarch64'],
    accept: '.AppImage,.appimage,.gz',
    packageHint: '上传 *.AppImage 更新包，与 .sig 签名文件一起上传。',
    versionHint: '如 0.4.1',
    versionNote: DESKTOP_NOTE,
  },
  android: {
    label: 'Android',
    arches: ['any'],
    accept: '.apk',
    packageHint: '上传 direct 渠道的 release APK（需使用正式证书签名）。',
    versionHint: '如 1.0.0 或 1.0.0+3',
    versionNote: MOBILE_NOTE,
  },
  ios: {
    label: 'iOS',
    arches: [],
    accept: '',
    packageHint: '',
    versionHint: '如 1.0.0 或 1.0.0+3',
    versionNote: MOBILE_NOTE + '请在 App Store 审核通过并上架后再发布。',
  },
}

const ARCH_LABELS: Record<string, string> = {
  x86_64: 'x86_64',
  aarch64: 'ARM64',
  universal: '通用',
  any: 'APK',
}

const ANDROID_STORES: Record<string, string> = {
  huawei: '华为',
  honor: '荣耀',
  xiaomi: '小米',
  oppo: 'OPPO',
  vivo: 'vivo',
  tencent: '应用宝',
}

const STATUS: Record<ReleaseStatus, { label: string; tag: 'info' | 'success' | 'warning' | 'primary' }> = {
  draft: { label: '草稿', tag: 'info' },
  published: { label: '已发布', tag: 'success' },
  paused: { label: '已暂停', tag: 'warning' },
  archived: { label: '已归档', tag: 'info' },
}

const platform = ref<ClientPlatform>('windows')
const isDesktop = computed(() => ['windows', 'macos', 'linux'].includes(platform.value))
const isMobile = computed(() => !isDesktop.value)

const releases = ref<ClientRelease[]>([])
const loading = ref(false)
const policy = ref<UpdatePolicy | null>(null)
const stats = ref<ReleaseStats | null>(null)

async function loadReleases() {
  loading.value = true
  try {
    releases.value = await api.releases(platform.value)
  } catch {
    /* shown */
  } finally {
    loading.value = false
  }
}

async function loadAll() {
  await Promise.all([
    loadReleases(),
    api.updatePolicy().then((p) => (policy.value = p)).catch(() => {}),
    api.releaseStats().then((s) => (stats.value = s)).catch(() => {}),
  ])
}

// ---- Policy ----
const policyForm = reactive({ min_version: '' })
const appStoreUrl = ref('')
const storeRows = ref<{ channel: string; url: string }[]>([])
const savingPolicy = ref(false)

function fillPolicyForm() {
  const p = policy.value?.[platform.value]
  policyForm.min_version = p?.min_version ?? ''
  const urls = p?.store_urls ?? {}
  appStoreUrl.value = urls.appstore ?? ''
  storeRows.value = Object.entries(urls)
    .filter(([k]) => k !== 'appstore')
    .map(([channel, url]) => ({ channel, url }))
}

async function savePolicy() {
  const store_urls: Record<string, string> = {}
  if (platform.value === 'ios' && appStoreUrl.value.trim()) store_urls.appstore = appStoreUrl.value.trim()
  if (platform.value === 'android') {
    for (const row of storeRows.value) {
      if (row.channel.trim() && row.url.trim()) store_urls[row.channel.trim()] = row.url.trim()
    }
  }
  savingPolicy.value = true
  try {
    policy.value = await api.updatePolicySave({
      [platform.value]: { min_version: policyForm.min_version.trim(), store_urls },
    })
    fillPolicyForm()
    ElMessage.success('升级策略已保存')
  } catch {
    /* shown */
  } finally {
    savingPolicy.value = false
  }
}

// ---- Stats ----
const statsRows = computed(() => stats.value?.[platform.value] ?? [])
const statsPercent = (count: number) => {
  const total = statsRows.value.reduce((sum, s) => sum + s.count, 0)
  return total ? Math.round((count / total) * 100) : 0
}

watch(platform, () => {
  fillPolicyForm()
  void loadReleases()
})
watch(policy, fillPolicyForm)

// ---- Actions ----
const userLabel = (u: ReleaseUserRef | AdminUser) => `${u.name ?? '已删除用户'}${u.phone ? `（${u.phone}）` : ''}`
const userList = (r: ClientRelease) => r.rollout_users.map(userLabel).join('、')

async function act(row: ClientRelease, action: 'publish' | 'pause' | 'archive') {
  try {
    if (action === 'publish') {
      const scope = row.rollout_percent === 100 ? '全部用户' : `${row.rollout_percent}% 的设备`
      const extra = row.rollout_users.length ? `及 ${row.rollout_users.length} 位白名单用户` : ''
      await ElMessageBox.confirm(`发布后将向 ${scope}${extra} 推送 ${row.full_version}${row.force ? '（强制升级）' : ''}，确定发布？`, '发布版本', {
        type: row.force ? 'warning' : 'info',
        confirmButtonText: '发布',
      })
    }
  } catch {
    return
  }
  try {
    if (action === 'publish') await api.releasePublish(row.id)
    else if (action === 'pause') await api.releasePause(row.id)
    else await api.releaseArchive(row.id)
    ElMessage.success({ publish: '已发布', pause: '已暂停推送', archive: '已归档' }[action])
    await loadReleases()
  } catch {
    /* shown */
  }
}

async function onMore(row: ClientRelease, command: string) {
  if (command === 'archive') {
    await act(row, 'archive')
    return
  }
  try {
    await ElMessageBox.confirm(`确定删除版本 ${row.full_version} 及其安装包？`, '删除版本', {
      type: 'warning',
      confirmButtonText: '删除',
      confirmButtonClass: 'el-button--danger',
    })
  } catch {
    return
  }
  try {
    await api.releaseDelete(row.id)
    ElMessage.success('已删除')
    await loadReleases()
  } catch {
    /* shown */
  }
}

async function removeArtifact(row: ClientRelease, a: ReleaseArtifact) {
  try {
    await ElMessageBox.confirm(`确定删除安装包 ${a.file_name}？`, '删除安装包', {
      type: 'warning',
      confirmButtonText: '删除',
      confirmButtonClass: 'el-button--danger',
    })
  } catch {
    return
  }
  try {
    await api.releaseArtifactDelete(row.id, a.id)
    ElMessage.success('已删除')
    await loadReleases()
  } catch {
    /* shown */
  }
}

// ---- Form ----
const formVisible = ref(false)
const formRef = ref<FormInstance>()
const editing = ref<ClientRelease | null>(null)
const saving = ref(false)
const userOptions = ref<(ReleaseUserRef | AdminUser)[]>([])
const searchingUsers = ref(false)

const emptyForm = (): ClientReleaseInput => ({
  version: '',
  build: 0,
  notes: '',
  force: false,
  rollout_percent: 100,
  rollout_users: [],
})
const form = reactive<ClientReleaseInput>(emptyForm())
const rules: FormRules = {
  version: [
    {
      validator: (_: unknown, v: string, cb: (e?: Error) => void) =>
        /^\d+\.\d+\.\d+$/.test(v?.trim() ?? '') ? cb() : cb(new Error('版本号格式应为 1.2.3')),
      trigger: 'blur',
    },
  ],
}

async function searchUsers(q: string) {
  if (!q.trim()) return
  searchingUsers.value = true
  try {
    const found = (await api.users({ q: q.trim(), limit: 20 }, true)).items
    const selected = userOptions.value.filter((u) => form.rollout_users.includes(u.id))
    userOptions.value = [...selected, ...found.filter((u) => !form.rollout_users.includes(u.id))]
  } catch {
    /* ignore */
  } finally {
    searchingUsers.value = false
  }
}

function openCreate() {
  Object.assign(form, emptyForm())
  editing.value = null
  userOptions.value = []
  formVisible.value = true
}

function openEdit(row: ClientRelease) {
  Object.assign(form, {
    version: row.version,
    build: row.build,
    notes: row.notes,
    force: row.force,
    rollout_percent: row.rollout_percent,
    rollout_users: row.rollout_users.map((u) => u.id),
  })
  editing.value = row
  userOptions.value = [...row.rollout_users]
  formVisible.value = true
}

async function save() {
  const ok = await formRef.value?.validate().catch(() => false)
  if (!ok) return
  const input: ClientReleaseInput = { ...form, version: form.version.trim(), notes: form.notes.trim() }
  saving.value = true
  try {
    if (editing.value) {
      await api.releaseUpdate(editing.value.id, input)
      ElMessage.success('已保存')
    } else {
      await api.releaseCreate(platform.value, input)
      ElMessage.success('已创建草稿，请上传安装包后发布')
    }
    formVisible.value = false
    await loadReleases()
  } catch {
    /* shown */
  } finally {
    saving.value = false
  }
}

// ---- Upload ----
const uploadVisible = ref(false)
const uploadTarget = ref<ClientRelease | null>(null)
const uploadArch = ref('')
const uploadFile = ref<File | null>(null)
const signatureFile = ref<File | null>(null)
const uploading = ref(false)
const uploadProgress = ref(0)
const canUpload = computed(() => !!uploadFile.value && !!uploadArch.value && (!isDesktop.value || !!signatureFile.value))

function openUpload(row: ClientRelease) {
  uploadTarget.value = row
  uploadArch.value = PLATFORMS[platform.value].arches[0] ?? ''
  uploadFile.value = null
  signatureFile.value = null
  uploadProgress.value = 0
  uploadVisible.value = true
}

async function doUpload() {
  const target = uploadTarget.value
  if (!target || !uploadFile.value) return
  uploading.value = true
  uploadProgress.value = 0
  try {
    await api.releaseUpload(target.id, uploadArch.value, uploadFile.value, signatureFile.value, (f) => {
      uploadProgress.value = Math.round(f * 100)
    })
    ElMessage.success('安装包已上传')
    uploadVisible.value = false
    await loadReleases()
  } catch {
    /* shown */
  } finally {
    uploading.value = false
  }
}

onMounted(loadAll)
</script>

<style scoped>
.platform-tabs {
  margin-bottom: 4px;
}
.grid {
  display: grid;
  grid-template-columns: minmax(0, 3fr) minmax(0, 2fr);
  gap: 16px;
  margin-bottom: 16px;
}
@media (max-width: 1100px) {
  .grid {
    grid-template-columns: 1fr;
  }
}
.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.hint {
  font-size: 12px;
  line-height: 1.5;
}
.hint.inline {
  margin-left: 12px;
}
.channels {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;
}
.add-channel {
  align-self: flex-start;
}
.channel-row {
  display: flex;
  gap: 8px;
}
.channel-key {
  width: 180px;
  flex-shrink: 0;
}
.stat-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.stat-row {
  display: grid;
  grid-template-columns: 110px 1fr 40px;
  align-items: center;
  gap: 8px;
}
.mono {
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
}
.name {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 500;
}
.notes {
  font-size: 12px;
  margin-top: 2px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  white-space: pre-line;
}
.small {
  font-size: 12px;
}
.artifact {
  display: flex;
  align-items: center;
  gap: 6px;
  min-width: 0;
}
.artifact + .artifact {
  margin-top: 4px;
}
.artifact .el-button {
  flex-shrink: 0;
  margin-left: 0;
}
.file {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  min-width: 0;
  flex: 1;
}
.more {
  margin-left: 12px;
}
.rollout {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
}
.rollout-slider {
  flex: 1;
}
.full {
  width: 100%;
}
</style>
