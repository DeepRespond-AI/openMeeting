import { http, request, upload } from './http'
import { directUpload } from './direct-upload'
import type {
  AdminJob,
  AdminMeetingDetails,
  AdminUser,
  AdminUserDetail,
  AdminUserList,
  AdminUserPatch,
  AuthSettings,
  AuthSettingsInput,
  ClientPlatform,
  ClientRelease,
  ClientReleaseInput,
  CloudConfig,
  CloudConfigInput,
  Connection,
  Dashboard,
  Job,
  LlmCapability,
  LlmProvider,
  LlmProviderInput,
  LlmTestResult,
  SummaryTemplate,
  SummaryTemplateInput,
  MeetingList,
  OssConfigInput,
  SmsLogList,
  SmsTestResult,
  StorageSettings,
  ObjectStorageSettings,
  AudioStorageSettings,
  StorageTestResult,
  SttCapability,
  SttEngineInfo,
  SttModel,
  SttTestResult,
  TimeseriesPoint,
  UpdatePolicy,
  ReleaseStats,
  UserStatusFilter,
} from './types'

const enc = encodeURIComponent

export const api = {
  // auth
  login: (password: string) => http.post<{ token: string }>('/login', { password }),
  logout: () => http.post<void>('/logout', undefined, true),
  me: () => http.get<{ ok: boolean }>('/me', undefined, true),

  // dashboard
  dashboard: () => http.get<Dashboard>('/dashboard'),
  timeseries: (hours = 24) => http.get<TimeseriesPoint[]>('/stats/timeseries', { hours }),

  // STT
  sttEngines: () => http.get<SttEngineInfo[]>('/stt/engines'),
  sttModels: () => http.get<SttModel[]>('/stt/models'),
  sttDownload: (id: string) => http.post<SttModel>(`/stt/models/${enc(id)}/download`),
  sttDelete: (id: string) => http.del(`/stt/models/${enc(id)}`),
  sttActivate: (model_id: string) => http.post<SttCapability>('/stt/activate', { model_id }),
  sttTest: (file: File, language?: string) => {
    const fd = new FormData()
    fd.append('file', file)
    if (language && language !== 'auto') fd.append('language', language)
    return request<SttTestResult>('/stt/test', { method: 'POST', body: fd })
  },
  cloudConfig: () => http.get<CloudConfig>('/stt/cloud-config'),
  saveCloudConfig: (cfg: CloudConfigInput) => http.put<CloudConfig>('/stt/cloud-config', cfg),

  // LLM
  llmProviders: () => http.get<LlmProvider[]>('/llm/providers'),
  llmCreate: (input: LlmProviderInput) => http.post<LlmProvider>('/llm/providers', input),
  llmUpdate: (id: string, input: LlmProviderInput) =>
    http.put<LlmProvider>(`/llm/providers/${enc(id)}`, input),
  llmDelete: (id: string) => http.del(`/llm/providers/${enc(id)}`),
  llmTest: (id: string) => http.post<LlmTestResult>(`/llm/providers/${enc(id)}/test`),
  llmActivate: (id: string) => http.post<LlmCapability>(`/llm/providers/${enc(id)}/activate`),
  llmModels: (id: string) => http.get<string[]>(`/llm/providers/${enc(id)}/models`),
  llmModelsProbe: (body: { base_url: string; api_key: string | null; provider_id: string | null }) =>
    http.post<string[]>('/llm/models-probe', body),

  // Summary templates
  summaryTemplates: () => http.get<SummaryTemplate[]>('/summary-templates'),
  summaryTemplateCreate: (input: SummaryTemplateInput) => http.post<SummaryTemplate>('/summary-templates', input),
  summaryTemplateUpdate: (id: string, input: SummaryTemplateInput) =>
    http.put<SummaryTemplate>(`/summary-templates/${enc(id)}`, input),
  summaryTemplateDelete: (id: string) => http.del(`/summary-templates/${enc(id)}`),

  // client releases (upgrades)
  releases: (platform?: ClientPlatform) => http.get<ClientRelease[]>('/releases', { platform }),
  releaseCreate: (platform: ClientPlatform, input: ClientReleaseInput) =>
    http.post<ClientRelease>('/releases', { platform, ...input }),
  releaseUpdate: (id: string, input: ClientReleaseInput) => http.put<ClientRelease>(`/releases/${enc(id)}`, input),
  releaseDelete: (id: string) => http.del(`/releases/${enc(id)}`),
  releasePublish: (id: string) => http.post<ClientRelease>(`/releases/${enc(id)}/publish`),
  releasePause: (id: string) => http.post<ClientRelease>(`/releases/${enc(id)}/pause`),
  releaseArchive: (id: string) => http.post<ClientRelease>(`/releases/${enc(id)}/archive`),
  releaseUpload: async (id: string, arch: string, file: File, signature: File | null, onProgress?: (f: number) => void) => {
    const fd = new FormData()
    fd.append('arch', arch)
    fd.append('file', file)
    if (signature) fd.append('signature', signature)
    return directUpload<ClientRelease>(`/releases/${enc(id)}/artifacts`, file,
      { arch, signature: signature ? await signature.text() : null },
      () => upload<ClientRelease>(`/releases/${enc(id)}/artifacts`, fd, onProgress), onProgress)
  },
  releaseArtifactDelete: (id: string, artifactId: string) =>
    http.del<ClientRelease>(`/releases/${enc(id)}/artifacts/${enc(artifactId)}`),
  releaseStats: () => http.get<ReleaseStats>('/releases/stats'),
  updatePolicy: () => http.get<UpdatePolicy>('/update-policy'),
  updatePolicySave: (policy: Partial<UpdatePolicy>) => http.put<UpdatePolicy>('/update-policy', policy),

  // monitoring
  connections: () => http.get<Connection[]>('/connections', undefined, true),
  jobs: (status?: string) => http.get<AdminJob[]>('/jobs', { status }, true),
  cancelJob: (id: string) => http.del<Job>(`/jobs/${enc(id)}`),

  // users (phone accounts)
  users: (
    params: { q?: string; status?: UserStatusFilter | ''; limit?: number; offset?: number } = {},
    silent = false,
  ) => http.get<AdminUserList>('/users', params, silent),
  user: (id: string) => http.get<AdminUserDetail>(`/users/${enc(id)}`),
  createUser: (phone: string, name: string) => http.post<AdminUser>('/users', { phone, name }),
  updateUser: (id: string, patch: AdminUserPatch) => http.patch<AdminUser>(`/users/${enc(id)}`, patch),
  deleteUser: (id: string) => http.del(`/users/${enc(id)}`),
  revokeSession: (userId: string, sessionId: string) =>
    http.del(`/users/${enc(userId)}/sessions/${enc(sessionId)}`),
  revokeAllSessions: (userId: string) => http.del(`/users/${enc(userId)}/sessions`),

  // auth settings & SMS
  authSettings: () => http.get<AuthSettings>('/auth-settings'),
  saveAuthSettings: (input: AuthSettingsInput) => http.put<AuthSettings>('/auth-settings', input),
  smsTest: (phone: string) => http.post<SmsTestResult>('/auth-settings/sms-test', { phone }),
  smsLogs: (params: { phone?: string; limit?: number; offset?: number } = {}) =>
    http.get<SmsLogList>('/sms-logs', params),

  // Global OSS configuration, shared by audio and release packages.
  objectStorage: () => http.get<ObjectStorageSettings>('/object-storage'),
  saveObjectStorage: (input: OssConfigInput) => http.put<ObjectStorageSettings>('/object-storage', input),
  objectStorageTest: () => http.post<StorageTestResult>('/object-storage/test'),
  audioStorage: () => http.get<AudioStorageSettings>('/storage/audio'),

  // Legacy storage API
  storage: () => http.get<StorageSettings>('/storage'),
  saveStorage: (input: OssConfigInput) => http.put<StorageSettings>('/storage', input),
  storageTest: () => http.post<StorageTestResult>('/storage/test'),

  // meetings
  meetings: (params: { user_id?: string; q?: string; limit?: number; offset?: number }) =>
    http.get<MeetingList>('/meetings', params),
  meeting: (id: string) => http.get<AdminMeetingDetails>(`/meetings/${enc(id)}`),
}

export const EVENTS_URL = '/admin/api/events'
