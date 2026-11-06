// Types mirroring server/API.md (section 1 shared shapes + section 2 Admin API).
// Keep in sync with the contract — JSON keys are exact.

export type SttEngine = 'faster-whisper' | 'funasr' | 'cloud'

export interface SttCapability {
  engine: SttEngine | null
  model: string | null
  ready: boolean
  error: string | null
}

export interface LlmCapability {
  name: string | null
  model: string | null
  ready: boolean
  error: string | null
}

export interface GpuInfo {
  index: number
  name: string
  util_percent: number
  mem_used: number
  mem_total: number
}

export interface SystemInfo {
  cpu_percent: number
  mem_used: number
  mem_total: number
  disk_used: number
  disk_total: number
  gpus: GpuInfo[]
}

export interface DashboardStats {
  online_clients: number
  recording_clients: number
  running_jobs: number
  today_requests: number
  today_audio_sec: number
  today_errors: number
  avg_latency_ms: number | null
}

export interface Dashboard {
  server_version: string
  uptime_sec: number
  system: SystemInfo
  device: 'cuda' | 'cpu'
  stt: SttCapability
  llm: LlmCapability
  stats: DashboardStats
}

export interface TimeseriesPoint {
  ts: string
  transcribe_requests: number
  audio_sec: number
  summary_requests: number
  errors: number
  avg_latency_ms: number | null
}

export interface SttEngineInfo {
  engine: SttEngine
  available: boolean
  reason: string | null
}

export type SttModelStatus = 'not_downloaded' | 'downloading' | 'ready' | 'error'

export interface SttModel {
  id: string
  engine: SttEngine
  name: string
  display_name: string
  size_mb: number
  languages: string
  status: SttModelStatus
  progress: number
  error: string | null
  active: boolean
  remote: boolean
}

export interface SttTestResult {
  text: string
  elapsed_ms: number
  engine: string
  model: string
}

export type CloudMode = 'openai' | 'dashscope'

export interface CloudConfig {
  mode: CloudMode
  base_url: string
  model: string
  api_key_set: boolean
}

export interface CloudConfigInput {
  mode: CloudMode
  base_url: string
  model: string
  api_key?: string
}

export interface LlmProvider {
  id: string
  name: string
  base_url: string
  model: string
  api_key_set: boolean
  max_tokens: number | null
  temperature: number | null
  top_p: number | null
  context_tokens: number
  active: boolean
  created_at: string
}

export interface LlmProviderInput {
  name: string
  base_url: string
  model: string
  api_key?: string
  max_tokens?: number | null
  temperature?: number | null
  top_p?: number | null
  context_tokens?: number
}

export type SummaryOutputFormat = 'markdown' | 'html' | 'mixed'

export interface SummaryTemplate {
  id: string
  name: string
  description: string
  prompt: string
  output_format: SummaryOutputFormat
  enabled: boolean
  is_default: boolean
  created_at: string
  updated_at: string
}

export interface SummaryTemplateInput {
  name: string
  description: string
  prompt: string
  output_format: SummaryOutputFormat
  enabled: boolean
  is_default: boolean
}

export interface LlmTestResult {
  ok: boolean
  elapsed_ms: number
  reply: string | null
  error: string | null
}

export interface Connection {
  client_id: string
  user_id: string | null
  user_name: string | null
  user_phone: string | null
  hostname: string
  os: string
  app_version: string
  ip: string
  recording: boolean
  meeting_id: string | null
  last_seen: string
  online: boolean
  inflight_requests: number
}

export type JobKind = 'import' | 'retranscribe' | 'summary'
export type JobStatus = 'queued' | 'running' | 'completed' | 'failed' | 'cancelled'

export interface Job {
  id: string
  kind: JobKind
  status: JobStatus
  progress: number
  message: string | null
  meeting_id: string | null
  error: string | null
  segments: number | null
  created_at: string
  updated_at: string
}

export interface AdminJob extends Job {
  user_name: string
}

/** AdminUser from GET /admin/api/users */
export interface AdminUser {
  id: string
  phone: string
  name: string
  disabled: boolean
  created_at: string
  last_login_at: string | null
  /** false = legacy user who can only log in with SMS codes until a password is set */
  has_password: boolean
  meeting_count: number
  session_count: number
  online: boolean
}

export interface AdminUserList {
  items: AdminUser[]
  total: number
}

export type UserStatusFilter = 'active' | 'disabled'

export interface UserSession {
  id: string
  client_id: string | null
  hostname: string | null
  os: string | null
  app_version: string | null
  ip: string | null
  created_at: string
  last_used_at: string | null
  expires_at: string
  revoked: boolean
}

export interface AdminUserDetail extends AdminUser {
  sessions: UserSession[]
}

export interface AdminUserPatch {
  name?: string
  phone?: string
  disabled?: boolean
}

export interface SmsConfig {
  access_key_id: string | null
  access_key_secret_set: boolean
  sign_name: string | null
  template_code: string | null
  template_param: string
  endpoint: string
}

export interface AuthSettings {
  registration_open: boolean
  sms: SmsConfig
  sms_ready: boolean
}

export interface SmsConfigInput {
  access_key_id?: string
  /** omit = keep stored secret */
  access_key_secret?: string
  sign_name?: string
  template_code?: string
  template_param?: string
  endpoint?: string
}

export interface AuthSettingsInput {
  registration_open?: boolean
  sms?: SmsConfigInput
}

export interface SmsTestResult {
  ok: boolean
  request_id: string | null
  error: string | null
}

export interface SmsLog {
  id: string | number
  phone: string
  purpose: string
  ip: string | null
  ok: boolean
  error: string | null
  created_at: string
}

export interface SmsLogList {
  items: SmsLog[]
  total: number
}

export interface MeetingListItem {
  id: string
  title: string
  user_name: string
  created_at: string
  transcript_count: number
  has_audio: boolean
  has_summary: boolean
}

export interface MeetingList {
  items: MeetingListItem[]
  total: number
}

export interface MeetingTranscript {
  id: string
  text: string
  timestamp: string
  audio_start_time?: number | null
  audio_end_time?: number | null
  duration?: number | null
}

export type SummaryStatus = 'idle' | 'processing' | 'completed' | 'failed' | 'cancelled' | 'error'

export interface SummaryResponse {
  status: SummaryStatus
  meetingName: string | null
  meeting_id: string
  start: string | null
  end: string | null
  // Expected shape: { markdown: string, summary_json?: [...] } — may be other legacy shapes
  data: unknown
  error: string | null
}

export interface MeetingDetails {
  id: string
  title: string
  created_at: string
  updated_at: string
  transcripts: MeetingTranscript[]
}

export interface AdminMeetingDetails extends MeetingDetails {
  user_name: string
  summary: SummaryResponse | null
}

/** SSE event names on /admin/api/events */
export type AdminEventName = 'connections' | 'jobs' | 'stt' | 'llm' | 'model-download' | 'ping'

// ---- global object storage and meeting audio statistics ----
export type OssField = 'endpoint' | 'region' | 'bucket' | 'access_key_id' | 'access_key_secret' | 'prefix'

export interface OssConfig {
  endpoint: string | null
  region: string | null
  bucket: string | null
  access_key_id: string | null
  access_key_secret_set: boolean
  prefix: string
}

export interface StorageBackendStats {
  meetings: number
  bytes: number
}

export interface ObjectStorageSettings {
  provider: 'local' | 'oss' | 'minio'
  public_endpoint: string | null
  oss: OssConfig
  oss_ready: boolean
  /** fields pinned by OPENMEETING_OSS_* env vars */
  env_overrides: OssField[]
}

export interface AudioStorageSettings {
  provider: 'local' | 'oss' | 'minio'
  oss_ready: boolean
  stats: { local: StorageBackendStats; oss: StorageBackendStats; minio: StorageBackendStats }
}

/** Compatibility response for older admin clients. */
export interface StorageSettings extends ObjectStorageSettings, AudioStorageSettings {}

export interface OssConfigInput {
  endpoint?: string
  region?: string
  bucket?: string
  access_key_id?: string
  /** omit = keep stored secret, "" = clear */
  access_key_secret?: string
  prefix?: string
}

export interface StorageTestResult {
  ok: boolean
  error: string | null
}

// ---- Client releases (upgrades) ----

export type ClientPlatform = 'windows' | 'macos' | 'linux' | 'android' | 'ios'
export type ReleaseStatus = 'draft' | 'published' | 'paused' | 'archived'

export interface ReleaseArtifact {
  id: string
  arch: string
  file_name: string
  size: number
  sha256: string
  /** Desktop packages carry the Tauri updater signature */
  signed: boolean
  storage: 'local' | 'oss' | 'minio'
  download_count: number
  created_at: string
}

export interface ReleaseUserRef {
  id: string
  name: string | null
  phone: string | null
}

export interface ClientRelease {
  id: string
  platform: ClientPlatform
  version: string
  /** 0 = none (desktop); Android versionCode / iOS build number */
  build: number
  full_version: string
  notes: string
  force: boolean
  status: ReleaseStatus
  rollout_percent: number
  rollout_users: ReleaseUserRef[]
  artifacts: ReleaseArtifact[]
  published_at: string | null
  created_at: string
  updated_at: string
}

export interface ClientReleaseInput {
  version: string
  build: number
  notes: string
  force: boolean
  rollout_percent: number
  /** user ids */
  rollout_users: string[]
}

export interface PlatformUpdatePolicy {
  /** '' = no minimum */
  min_version: string
  /** channel → store link (`appstore` for iOS; Android store channels such as `huawei`) */
  store_urls: Record<string, string>
}

export type UpdatePolicy = Record<ClientPlatform, PlatformUpdatePolicy>

export type ReleaseStats = Record<ClientPlatform, { version: string; count: number }[]>
