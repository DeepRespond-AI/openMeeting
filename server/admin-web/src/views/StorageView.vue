<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h2>音频存储</h2>
        <div class="sub">会议录音使用全局对象存储配置；未配置时保存在服务器本地。</div>
      </div>
      <el-button :icon="Refresh" :loading="loading" @click="loadSettings">刷新</el-button>
    </div>
    <el-card shadow="never" class="status-card">
      <div class="card-title">
        <span>录音存储方式</span>
        <el-tag v-if="settings" :type="settings.oss_ready ? 'success' : 'warning'">
          {{ settings.oss_ready ? `${settings.provider === 'minio' ? 'MinIO' : '阿里云 OSS'} 已配置` : settings.provider === 'local' ? '使用本地存储' : '对象存储未配置完整' }}
        </el-tag>
        <el-button type="primary" plain @click="$router.push({ name: 'object-storage' })">管理全局对象存储</el-button>
      </div>
      <p class="muted small">新上传、导入和多人会议合成录音使用全局存储配置；转存成功后删除本地副本。切换存储不自动搬迁已有文件。</p>
    </el-card>
    <el-card shadow="never" v-loading="loading && !settings">
      <template #header>
        <div class="card-title"><span>存储统计</span></div>
      </template>
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="OSS 中的会议">{{ settings?.stats.oss.meetings ?? '-' }}</el-descriptions-item>
        <el-descriptions-item label="OSS 占用">{{ formatBytes(settings?.stats.oss.bytes) }}</el-descriptions-item>
        <el-descriptions-item label="MinIO 中的会议">{{ settings?.stats.minio.meetings ?? '-' }}</el-descriptions-item>
        <el-descriptions-item label="MinIO 占用">{{ formatBytes(settings?.stats.minio.bytes) }}</el-descriptions-item>
        <el-descriptions-item label="本地的会议">{{ settings?.stats.local.meetings ?? '-' }}</el-descriptions-item>
        <el-descriptions-item label="本地占用">{{ formatBytes(settings?.stats.local.bytes) }}</el-descriptions-item>
      </el-descriptions>
      <div v-if="settings?.oss_ready && settings.stats.local.meetings > 0" class="muted small help-line">
        还有 {{ settings.stats.local.meetings }} 个会议的录音在服务器本地。以下命令可迁移到当前对象存储：
        <div class="example mono">uv run python -m meeting_ms.scripts.migrate_audio_to_oss --dry-run</div>
        确认列表无误后去掉 <code>--dry-run</code> 正式执行（Docker 部署：<code>docker compose exec meeting_ms python -m meeting_ms.scripts.migrate_audio_to_oss</code>）。
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import { api } from '@/api'
import type { AudioStorageSettings } from '@/api/types'
import { formatBytes } from '@/utils'

const settings = ref<AudioStorageSettings | null>(null)
const loading = ref(false)
async function loadSettings() {
  loading.value = true
  try {
    settings.value = await api.audioStorage()
  } catch {
    /* shown */
  } finally {
    loading.value = false
  }
}
onMounted(loadSettings)
</script>

<style scoped>
.status-card { margin-bottom: 16px; }
.status-card .card-title { flex-wrap: wrap; gap: 8px; }
.status-card .card-title > span { flex-shrink: 0; }
.small { font-size: 12px; }
.help-line { margin-top: 12px; line-height: 1.8; }
.example { background: #f5f7fa; padding: 4px 8px; margin: 4px 0; }
</style>
