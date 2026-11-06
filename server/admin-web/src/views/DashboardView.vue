<template>
  <div class="page" v-loading="!data && loading">
    <div class="page-header">
      <div>
        <h2>仪表盘</h2>
        <div class="sub" v-if="data">
          服务版本 {{ data.server_version }} · 已运行 {{ formatDuration(data.uptime_sec) }} · 最后刷新
          {{ lastRefresh }}
        </div>
      </div>
      <div class="toolbar">
        <el-switch v-model="autoRefresh" active-text="自动刷新" />
        <el-button :icon="Refresh" :loading="loading" @click="load">刷新</el-button>
      </div>
    </div>

    <template v-if="data">
      <!-- Stat tiles -->
      <el-row :gutter="16">
        <el-col v-for="t in tiles" :key="t.label" :xs="12" :sm="8" :md="8" :lg="8" :xl="8" class="col">
          <StatTile :label="t.label" :value="t.value" :icon="t.icon" :color="t.color" />
        </el-col>
      </el-row>

      <el-row :gutter="16">
        <!-- Resources -->
        <el-col :xs="24" :lg="14" class="col">
          <el-card shadow="never" class="full">
            <template #header>
              <div class="card-title">
                <span>系统资源</span>
                <el-tag :type="data.device === 'cuda' ? 'success' : 'info'" effect="dark">
                  {{ data.device === 'cuda' ? 'CUDA 加速' : 'CPU 推理' }}
                </el-tag>
              </div>
            </template>
            <div class="gauges">
              <ResourceGauge label="CPU" :percent="data.system.cpu_percent" />
              <ResourceGauge
                label="内存"
                :percent="percent(data.system.mem_used, data.system.mem_total)"
                :detail="`${formatBytes(data.system.mem_used)} / ${formatBytes(data.system.mem_total)}`"
              />
              <ResourceGauge
                label="磁盘"
                :percent="percent(data.system.disk_used, data.system.disk_total)"
                :detail="`${formatBytes(data.system.disk_used)} / ${formatBytes(data.system.disk_total)}`"
              />
            </div>
            <el-divider v-if="data.system.gpus.length" content-position="left">GPU</el-divider>
            <div v-for="g in data.system.gpus" :key="g.index" class="gpu">
              <div class="gpu-name">
                <el-icon><Cpu /></el-icon> GPU {{ g.index }} · {{ g.name }}
              </div>
              <div class="gpu-bars">
                <div class="bar">
                  <span class="bar-label">利用率</span>
                  <el-progress :percentage="Math.round(g.util_percent)" :color="progressColor(g.util_percent)" :stroke-width="12" />
                </div>
                <div class="bar">
                  <span class="bar-label">显存</span>
                  <el-progress
                    :percentage="percent(g.mem_used, g.mem_total)"
                    :color="progressColor(percent(g.mem_used, g.mem_total))"
                    :stroke-width="12"
                    :format="() => `${formatBytes(g.mem_used)} / ${formatBytes(g.mem_total)}`"
                  />
                </div>
              </div>
            </div>
            <div v-if="!data.system.gpus.length" class="muted no-gpu">未检测到 GPU</div>
          </el-card>
        </el-col>

        <!-- Models -->
        <el-col :xs="24" :lg="10" class="col">
          <div class="model-cards">
            <el-card shadow="never">
              <template #header>
                <div class="card-title">
                  <span><el-icon><Microphone /></el-icon> 当前语音模型</span>
                  <el-tag :type="data.stt.ready ? 'success' : 'danger'">{{ data.stt.ready ? '就绪' : '未就绪' }}</el-tag>
                </div>
              </template>
              <div class="model-main">{{ data.stt.model ?? '未配置' }}</div>
              <div class="muted">引擎：{{ engineLabel(data.stt.engine) }}</div>
              <el-alert v-if="data.stt.error" :title="data.stt.error" type="error" :closable="false" show-icon class="mt" />
              <el-button class="mt" link type="primary" @click="router.push({ name: 'stt' })">管理语音模型 →</el-button>
            </el-card>
            <el-card shadow="never">
              <template #header>
                <div class="card-title">
                  <span><el-icon><MagicStick /></el-icon> 当前大模型</span>
                  <el-tag :type="data.llm.ready ? 'success' : 'danger'">{{ data.llm.ready ? '就绪' : '未就绪' }}</el-tag>
                </div>
              </template>
              <div class="model-main">{{ data.llm.model ?? '未配置' }}</div>
              <div class="muted">提供方：{{ data.llm.name ?? '-' }}</div>
              <el-alert v-if="data.llm.error" :title="data.llm.error" type="error" :closable="false" show-icon class="mt" />
              <el-button class="mt" link type="primary" @click="router.push({ name: 'llm' })">管理大模型 →</el-button>
            </el-card>
          </div>
        </el-col>
      </el-row>

      <!-- Timeseries -->
      <el-card shadow="never">
        <template #header>
          <div class="card-title">
            <span>近 24 小时趋势</span>
          </div>
        </template>
        <v-chart v-if="series.length" class="chart" :option="chartOption" autoresize />
        <el-empty v-else description="暂无数据" :image-size="80" />
      </el-card>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Refresh } from '@element-plus/icons-vue'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart, BarChart } from 'echarts/charts'
import { GridComponent, TooltipComponent, LegendComponent } from 'echarts/components'
import { api } from '@/api'
import type { Dashboard, TimeseriesPoint } from '@/api/types'
import StatTile from '@/components/StatTile.vue'
import ResourceGauge from '@/components/ResourceGauge.vue'
import { useAdminEvents, useInterval } from '@/composables/useEvents'
import { formatBytes, formatDuration, percent, progressColor } from '@/utils'

use([CanvasRenderer, LineChart, BarChart, GridComponent, TooltipComponent, LegendComponent])

const router = useRouter()
const data = ref<Dashboard | null>(null)
const series = ref<TimeseriesPoint[]>([])
const loading = ref(false)
const autoRefresh = ref(true)
const lastRefresh = ref('')
const userTotal = ref<number | null>(null)

function engineLabel(e: string | null) {
  return e === 'faster-whisper' ? 'faster-whisper' : e === 'funasr' ? 'FunASR' : e === 'cloud' ? '云端' : '-'
}

async function load() {
  if (loading.value) return
  loading.value = true
  try {
    const [d, ts, users] = await Promise.all([
      api.dashboard(),
      api.timeseries(24),
      // registered-user count comes from the paginated users list total
      api.users({ limit: 1 }, true).catch(() => null),
    ])
    data.value = d
    if (users) userTotal.value = users.total
    series.value = ts ?? []
    lastRefresh.value = new Date().toLocaleTimeString('zh-CN', { hour12: false })
  } catch {
    /* shown by http layer */
  } finally {
    loading.value = false
  }
}

const tiles = computed(() => {
  const s = data.value?.stats
  if (!s) return []
  return [
    { label: '注册用户', value: userTotal.value ?? '-', icon: 'User', color: '#409eff' },
    { label: '在线客户端', value: s.online_clients, icon: 'Connection', color: '#409eff' },
    { label: '录音中', value: s.recording_clients, icon: 'Microphone', color: '#f56c6c' },
    { label: '运行任务', value: s.running_jobs, icon: 'Loading', color: '#e6a23c' },
    { label: '今日请求', value: s.today_requests, icon: 'DataLine', color: '#67c23a' },
    { label: '今日转写时长', value: formatDuration(s.today_audio_sec), icon: 'Timer', color: '#8e44ad' },
    { label: '今日错误', value: s.today_errors, icon: 'Warning', color: '#f56c6c' },
    {
      label: '错误率',
      value: s.today_requests ? `${((s.today_errors / s.today_requests) * 100).toFixed(1)}%` : '0%',
      icon: 'PieChart',
      color: '#e6a23c',
    },
    {
      label: '平均延迟',
      value: s.avg_latency_ms == null ? '-' : `${Math.round(s.avg_latency_ms)} ms`,
      icon: 'Stopwatch',
      color: '#00a6a6',
    },
  ]
})

const chartOption = computed(() => {
  const pts = series.value
  const x = pts.map((p) => {
    const d = new Date(p.ts)
    return isNaN(d.getTime()) ? p.ts : `${String(d.getHours()).padStart(2, '0')}:00`
  })
  return {
    tooltip: { trigger: 'axis' },
    legend: { top: 0 },
    grid: { left: 48, right: 56, top: 40, bottom: 28 },
    xAxis: { type: 'category', data: x, boundaryGap: false },
    yAxis: [
      { type: 'value', name: '次数', minInterval: 1 },
      { type: 'value', name: '分钟 / ms', splitLine: { show: false } },
    ],
    series: [
      { name: '转写请求', type: 'line', smooth: true, data: pts.map((p) => p.transcribe_requests), areaStyle: { opacity: 0.08 } },
      { name: '总结请求', type: 'line', smooth: true, data: pts.map((p) => p.summary_requests) },
      { name: '错误', type: 'bar', data: pts.map((p) => p.errors), itemStyle: { color: '#f56c6c' }, barMaxWidth: 12 },
      {
        name: '音频时长(分钟)',
        type: 'line',
        smooth: true,
        yAxisIndex: 1,
        data: pts.map((p) => Math.round((p.audio_sec / 60) * 10) / 10),
      },
      {
        name: '平均延迟(ms)',
        type: 'line',
        smooth: true,
        yAxisIndex: 1,
        lineStyle: { type: 'dashed' },
        data: pts.map((p) => (p.avg_latency_ms == null ? null : Math.round(p.avg_latency_ms))),
      },
    ],
  }
})

useInterval(() => {
  if (autoRefresh.value && !document.hidden) load()
}, 10000)

// Refresh model cards / counters immediately on relevant pushes
let pending: number | null = null
function debouncedLoad() {
  if (pending !== null) return
  pending = window.setTimeout(() => {
    pending = null
    load()
  }, 800)
}
useAdminEvents({ stt: debouncedLoad, llm: debouncedLoad, connections: debouncedLoad, jobs: debouncedLoad })

onMounted(load)
</script>

<style scoped>
.col {
  margin-bottom: 16px;
}
.full {
  height: 100%;
}
.gauges {
  display: flex;
  justify-content: space-around;
  flex-wrap: wrap;
  gap: 16px;
}
.gpu {
  margin-bottom: 12px;
}
.gpu-name {
  font-weight: 500;
  margin-bottom: 6px;
  display: flex;
  align-items: center;
  gap: 6px;
}
.gpu-bars {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
@media (max-width: 700px) {
  .gpu-bars {
    grid-template-columns: 1fr;
  }
}
.bar {
  display: flex;
  align-items: center;
  gap: 8px;
}
.bar .el-progress {
  flex: 1;
}
.bar-label {
  font-size: 12px;
  color: #909399;
  width: 40px;
  flex-shrink: 0;
}
.no-gpu {
  text-align: center;
  margin-top: 16px;
  font-size: 13px;
}
.model-cards {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.model-main {
  font-size: 20px;
  font-weight: 600;
  margin-bottom: 4px;
  word-break: break-all;
}
.mt {
  margin-top: 10px;
}
.chart {
  height: 320px;
  width: 100%;
}
</style>
