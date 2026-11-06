// server/types.rs
//
// Wire types for the OpenMeeting server client API (see server/API.md section 1).
// Shapes that the UI also consumes (meetings, transcripts, summaries) live in
// `crate::api::api` / `crate::summary::commands` and are deserialized directly.

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SttCapability {
    #[serde(default)]
    pub engine: Option<String>,
    #[serde(default)]
    pub model: Option<String>,
    #[serde(default)]
    pub ready: bool,
    #[serde(default)]
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct LlmCapability {
    #[serde(default)]
    pub name: Option<String>,
    #[serde(default)]
    pub model: Option<String>,
    #[serde(default)]
    pub ready: bool,
    #[serde(default)]
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Capabilities {
    #[serde(default)]
    pub server_version: Option<String>,
    #[serde(default)]
    pub user: Option<serde_json::Value>,
    #[serde(default)]
    pub stt: SttCapability,
    #[serde(default)]
    pub llm: LlmCapability,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HeartbeatRequest {
    pub client_id: String,
    pub hostname: String,
    pub os: String,
    pub app_version: String,
    pub recording: bool,
    pub meeting_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HeartbeatResponse {
    #[serde(default)]
    pub server_time: Option<String>,
    #[serde(default)]
    pub server_version: Option<String>,
}

/// `User` — the account that owns the session (API.md §1.0).
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq)]
pub struct User {
    pub id: String,
    #[serde(default)]
    pub phone: String,
    #[serde(default)]
    pub name: String,
    #[serde(default)]
    pub created_at: Option<String>,
    #[serde(default)]
    pub last_login_at: Option<String>,
    /// False for accounts created before passwords existed (SMS-code login only).
    #[serde(default)]
    pub has_password: bool,
}

/// Response of the public `GET /api/v1/auth/config`.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct AuthConfig {
    #[serde(default)]
    pub registration_open: bool,
    #[serde(default)]
    pub sms_ready: bool,
    #[serde(default = "default_code_length")]
    pub code_length: u32,
    #[serde(default = "default_resend_interval")]
    pub resend_interval_sec: u32,
    #[serde(default = "default_password_min_length")]
    pub password_min_length: u32,
    #[serde(default = "default_password_max_length")]
    pub password_max_length: u32,
    #[serde(default)]
    pub server_version: Option<String>,
}

fn default_password_min_length() -> u32 {
    8
}

fn default_password_max_length() -> u32 {
    64
}

fn default_code_length() -> u32 {
    6
}

fn default_resend_interval() -> u32 {
    60
}

/// Device description sent with login/registration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClientInfo {
    pub client_id: String,
    pub hostname: String,
    pub os: String,
    pub app_version: String,
}

/// `AuthResult` — response of register/login.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthResult {
    pub token: String,
    #[serde(default)]
    pub expires_at: Option<String>,
    pub user: User,
}

/// Response of `POST /api/v1/auth/sms/send` (also returned by `auth_send_code`).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SendCodeResult {
    #[serde(default)]
    pub sent: bool,
    #[serde(default = "default_resend_interval")]
    pub resend_after_sec: u32,
    #[serde(default)]
    pub expires_in_sec: Option<u32>,
    /// Only returned by a server in dev mode without SMS configuration.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub dev_code: Option<String>,
}

/// `ServerStatus` — payload of `server_get_status` and the `server-status` event.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct ServerStatus {
    /// A server URL is set (always true: it is built in).
    pub configured: bool,
    /// The server is reachable.
    pub connected: bool,
    /// A session token is stored locally.
    #[serde(default)]
    pub logged_in: bool,
    /// The server accepted the stored session.
    pub authenticated: bool,
    #[serde(default)]
    pub user: Option<User>,
    #[serde(default)]
    pub auth_config: Option<AuthConfig>,
    pub capabilities: Option<Capabilities>,
    pub error: Option<String>,
    pub last_check: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SegmentResult {
    #[serde(default)]
    pub id: Option<String>,
    #[serde(default)]
    pub text: String,
    #[serde(default)]
    pub confidence: Option<f32>,
    #[serde(default)]
    pub seq: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AudioUploadResult {
    #[serde(default)]
    pub size: i64,
    #[serde(default)]
    pub duration: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Job {
    pub id: String,
    #[serde(default)]
    pub kind: String,
    pub status: String,
    #[serde(default)]
    pub progress: f64,
    #[serde(default)]
    pub message: Option<String>,
    #[serde(default)]
    pub meeting_id: Option<String>,
    #[serde(default)]
    pub error: Option<String>,
    #[serde(default)]
    pub segments: Option<i64>,
    #[serde(default)]
    pub created_at: Option<String>,
    #[serde(default)]
    pub updated_at: Option<String>,
}

impl Job {
    pub fn is_terminal(&self) -> bool {
        matches!(self.status.as_str(), "completed" | "failed" | "cancelled")
    }
}

/// Server-side `MeetingMetadata` (superset of the UI-facing struct).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerMeetingMetadata {
    #[serde(default)]
    pub can_manage: Option<bool>,
    pub id: String,
    pub title: String,
    #[serde(default)]
    pub created_at: String,
    #[serde(default)]
    pub updated_at: String,
    #[serde(default)]
    pub folder_path: Option<String>,
    #[serde(default)]
    pub has_audio: bool,
    #[serde(default)]
    pub audio_duration: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SummaryLanguageInfo {
    #[serde(default)]
    pub language: Option<String>,
    #[serde(default)]
    pub detected_language: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn capabilities_deserialize_with_nulls() {
        let caps: Capabilities = serde_json::from_str(
            r#"{"server_version":"1.0.0","user":{"id":"u1","name":"alice"},
                "stt":{"engine":null,"model":null,"ready":false,"error":null},
                "llm":{"name":"百炼","model":"qwen-plus","ready":true,"error":null}}"#,
        )
        .unwrap();
        assert!(!caps.stt.ready);
        assert_eq!(caps.llm.model.as_deref(), Some("qwen-plus"));
    }

    #[test]
    fn server_status_serializes_camel_case() {
        let v = serde_json::to_value(ServerStatus {
            configured: true,
            last_check: Some("t".into()),
            ..Default::default()
        })
        .unwrap();
        assert!(v.get("serverUrl").is_none(), "the server URL is never sent to the UI");
        assert_eq!(v["lastCheck"], "t");
        assert!(v.get("capabilities").is_some());
    }

    #[test]
    fn server_status_serializes_auth_fields() {
        let status = ServerStatus {
            configured: true,
            connected: true,
            logged_in: true,
            authenticated: true,
            user: Some(User {
                id: "u1".into(),
                phone: "13800138000".into(),
                name: "张三".into(),
                created_at: Some("2026-10-07T03:59:35Z".into()),
                last_login_at: None,
                has_password: true,
            }),
            auth_config: Some(AuthConfig {
                registration_open: true,
                sms_ready: false,
                code_length: 6,
                resend_interval_sec: 60,
                password_min_length: 8,
                password_max_length: 64,
                server_version: Some("1.0.0".into()),
            }),
            ..Default::default()
        };
        let v = serde_json::to_value(&status).unwrap();
        assert_eq!(v["loggedIn"], true);
        assert_eq!(v["authenticated"], true);
        // Nested server shapes keep the server's snake_case keys.
        assert_eq!(v["user"]["phone"], "13800138000");
        assert_eq!(v["user"]["created_at"], "2026-10-07T03:59:35Z");
        assert_eq!(v["authConfig"]["registration_open"], true);
        assert_eq!(v["authConfig"]["resend_interval_sec"], 60);
        assert_eq!(v["user"]["has_password"], true);
        assert_eq!(v["authConfig"]["password_min_length"], 8);

        // Logged-out status: user/authConfig serialize as null.
        let v = serde_json::to_value(ServerStatus::default()).unwrap();
        assert_eq!(v["loggedIn"], false);
        assert!(v["user"].is_null());
        assert!(v["authConfig"].is_null());

        // Round trip, and tolerate payloads from older builds without the new fields.
        let back: ServerStatus = serde_json::from_value(serde_json::to_value(&status).unwrap()).unwrap();
        assert_eq!(back.user, status.user);
        let old: ServerStatus = serde_json::from_str(
            r#"{"configured":true,"connected":true,"authenticated":false,"serverUrl":null,
                "capabilities":null,"error":null,"lastCheck":null}"#,
        )
        .unwrap();
        assert!(!old.logged_in);
        assert!(old.user.is_none());
    }

    #[test]
    fn auth_payloads_deserialize() {
        let r: AuthResult = serde_json::from_str(
            r#"{"token":"ms_x","expires_at":"2026-11-06T00:00:00Z",
                "user":{"id":"u1","phone":"13800138000","name":"A","created_at":"t","last_login_at":"t"}}"#,
        )
        .unwrap();
        assert_eq!(r.user.name, "A");
        assert!(!r.user.has_password, "older servers omit has_password");
        let s: SendCodeResult =
            serde_json::from_str(r#"{"sent":true,"resend_after_sec":60,"expires_in_sec":300,"dev_code":"123456"}"#)
                .unwrap();
        assert_eq!(s.dev_code.as_deref(), Some("123456"));
        let v = serde_json::to_value(SendCodeResult { dev_code: None, ..s }).unwrap();
        assert!(v.get("dev_code").is_none());
        let c: AuthConfig = serde_json::from_str(r#"{"registration_open":false,"sms_ready":true}"#).unwrap();
        assert_eq!(c.code_length, 6);
        assert_eq!(c.resend_interval_sec, 60);
        assert!(c.sms_ready);
    }

    #[test]
    fn job_and_segment_deserialize() {
        let job: Job = serde_json::from_str(
            r#"{"id":"job-1","kind":"import","status":"running","progress":42,"message":"x",
                "meeting_id":"meeting-1","error":null,"segments":null,
                "created_at":"2026-10-07T03:59:35Z","updated_at":"2026-10-07T03:59:35Z"}"#,
        )
        .unwrap();
        assert_eq!(job.progress, 42.0);
        assert!(!job.is_terminal());
        let seg: SegmentResult =
            serde_json::from_str(r#"{"id":null,"text":"","confidence":null,"seq":7}"#).unwrap();
        assert_eq!(seg.seq, 7);
        assert!(seg.id.is_none());
    }
}
