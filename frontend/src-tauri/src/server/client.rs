// server/client.rs
//
// ServerClient: thin reqwest wrapper around the OpenMeeting server client API
// (`/api/v1`, Bearer session token from phone login). A process-wide instance
// is kept in `CURRENT` and replaced whenever the configuration or session changes.
//
// Any 401 on a request that carried a session token invokes the handler set
// with `set_unauthorized_handler` (clears the session and notifies the UI).

use once_cell::sync::{Lazy, OnceCell};
use reqwest::{Method, RequestBuilder, Response, StatusCode};
use serde::de::DeserializeOwned;
use serde::Serialize;
use std::path::Path;
use std::sync::RwLock;
use std::time::Duration;

use super::config::ServerConfig;

const API_PREFIX: &str = "/api/v1";
const CONNECT_TIMEOUT: Duration = Duration::from_secs(10);
const DEFAULT_TIMEOUT: Duration = Duration::from_secs(60);
/// Long transfers (audio upload/download, file import) get a generous ceiling.
const TRANSFER_TIMEOUT: Duration = Duration::from_secs(4 * 3600);

// ============================================================================
// ERRORS
// ============================================================================

#[derive(Debug, Clone)]
pub enum ServerError {
    /// No server URL configured.
    NotConfigured,
    /// Server URL configured but no login session stored.
    NotLoggedIn,
    /// 401 on an authenticated request – missing/invalid/expired/revoked session.
    Unauthorized(String),
    /// 403 – user disabled / registration closed (server `detail`).
    Forbidden(String),
    /// Network-level failure (DNS, refused, TLS, timeout).
    Connect(String),
    /// 404
    NotFound(String),
    /// Any other non-2xx response.
    Http { status: u16, detail: String },
    /// Client-side problem (I/O, decode, ...).
    Other(String),
}

impl ServerError {
    /// True when the request never reached the server.
    pub fn is_connect(&self) -> bool {
        matches!(self, ServerError::Connect(_))
    }

    pub fn is_auth(&self) -> bool {
        matches!(
            self,
            ServerError::Unauthorized(_) | ServerError::Forbidden(_) | ServerError::NotLoggedIn
        )
    }

    /// Worth retrying (network hiccup, 5xx incl. 503 "STT not ready", 408/429).
    pub fn is_retryable(&self) -> bool {
        match self {
            ServerError::Connect(_) => true,
            ServerError::Http { status, .. } => *status >= 500 || *status == 408 || *status == 429,
            _ => false,
        }
    }

    pub fn status(&self) -> Option<u16> {
        match self {
            ServerError::Unauthorized(_) => Some(401),
            ServerError::Forbidden(_) => Some(403),
            ServerError::NotFound(_) => Some(404),
            ServerError::Http { status, .. } => Some(*status),
            _ => None,
        }
    }
}

impl std::fmt::Display for ServerError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ServerError::NotConfigured => write!(f, "未配置服务器"),
            ServerError::NotLoggedIn => write!(f, "未登录，请先使用手机号登录"),
            ServerError::Unauthorized(_) => write!(f, "登录已失效，请重新登录"),
            ServerError::Forbidden(detail) => {
                if detail.is_empty() {
                    write!(f, "账户已被禁用")
                } else {
                    write!(f, "{}", detail)
                }
            }
            // The reqwest detail names the (hidden) server URL: log it, never show it.
            ServerError::Connect(_) => write!(f, "无法连接服务器，请检查网络连接"),
            // 4xx details (and Chinese 5xx details such as SMS gateway failures) are
            // user-facing messages from the server: pass them through.
            ServerError::NotFound(detail) => write!(f, "{}", detail),
            ServerError::Http { status, detail } if *status < 500 || !detail.is_ascii() => {
                write!(f, "{}", detail)
            }
            ServerError::Http { detail, .. } => write!(f, "服务器错误: {}", detail),
            ServerError::Other(detail) => write!(f, "{}", detail),
        }
    }
}

impl std::error::Error for ServerError {}

impl From<ServerError> for String {
    fn from(e: ServerError) -> Self {
        e.to_string()
    }
}

/// Shown for 422 validation errors whose detail is a list.
pub const INVALID_INPUT_MESSAGE: &str = "输入格式不正确";

fn map_reqwest_error(e: reqwest::Error) -> ServerError {
    if e.is_connect() || e.is_timeout() || e.is_request() {
        ServerError::Connect(e.to_string())
    } else if e.is_decode() {
        ServerError::Other(format!("服务器响应解析失败: {}", e))
    } else {
        ServerError::Connect(e.to_string())
    }
}

/// Extract a human readable `detail` from an error body (`{"detail": ...}`).
pub(crate) fn extract_detail(body: &str, status: StatusCode) -> String {
    if let Ok(value) = serde_json::from_str::<serde_json::Value>(body) {
        match value.get("detail") {
            Some(serde_json::Value::String(s)) => return s.clone(),
            // FastAPI validation errors (422): [{"loc": [...], "msg": "...", ...}] — the
            // English pydantic messages are not user-facing, show a generic one.
            Some(serde_json::Value::Array(items)) => {
                let msgs: Vec<&str> = items
                    .iter()
                    .filter_map(|i| i.get("msg").and_then(|m| m.as_str()))
                    .collect();
                log::debug!("Server validation error: {:?}", msgs);
                return INVALID_INPUT_MESSAGE.to_string();
            }
            Some(other) if !other.is_null() => return other.to_string(),
            _ => {}
        }
    }
    let trimmed = body.trim();
    if trimmed.is_empty() {
        format!("HTTP {}", status.as_u16())
    } else {
        format!("HTTP {}: {}", status.as_u16(), trimmed.chars().take(300).collect::<String>())
    }
}

async fn check_response(resp: Response) -> Result<Response, ServerError> {
    let status = resp.status();
    if status.is_success() {
        return Ok(resp);
    }
    let body = resp.text().await.unwrap_or_default();
    let detail = extract_detail(&body, status);
    Err(match status {
        StatusCode::UNAUTHORIZED => ServerError::Unauthorized(detail),
        StatusCode::FORBIDDEN => ServerError::Forbidden(detail),
        StatusCode::NOT_FOUND => ServerError::NotFound(detail),
        _ => ServerError::Http {
            status: status.as_u16(),
            detail,
        },
    })
}

// ============================================================================
// CLIENT
// ============================================================================

#[derive(Clone)]
pub struct ServerClient {
    http: reqwest::Client,
    base_url: String,
    /// Session token (None = unauthenticated client, only for public auth endpoints).
    token: Option<String>,
}

impl std::fmt::Debug for ServerClient {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("ServerClient")
            .field("base_url", &self.base_url)
            .finish_non_exhaustive()
    }
}

static CURRENT: Lazy<RwLock<Option<ServerClient>>> = Lazy::new(|| RwLock::new(None));

type UnauthorizedHandler = Box<dyn Fn(&str) + Send + Sync>;
static ON_UNAUTHORIZED: OnceCell<UnauthorizedHandler> = OnceCell::new();

/// Register the callback invoked with the rejected session token whenever an
/// authenticated request gets a 401. Only the first registration wins.
pub fn set_unauthorized_handler<F>(handler: F)
where
    F: Fn(&str) + Send + Sync + 'static,
{
    let _ = ON_UNAUTHORIZED.set(Box::new(handler));
}

impl ServerClient {
    pub fn new(base_url: &str, token: Option<&str>) -> Result<Self, ServerError> {
        let http = reqwest::Client::builder()
            .connect_timeout(CONNECT_TIMEOUT)
            .user_agent(concat!("openmeeting-client/", env!("CARGO_PKG_VERSION")))
            .build()
            .map_err(|e| ServerError::Other(format!("Failed to build HTTP client: {}", e)))?;
        Ok(Self {
            http,
            base_url: base_url.trim_end_matches('/').to_string(),
            token: token
                .map(|t| t.trim().to_string())
                .filter(|t| !t.is_empty()),
        })
    }

    /// Client for the configured server (carrying the session token if one is
    /// stored), or None when no server URL is saved.
    pub fn from_config(config: &ServerConfig) -> Option<Self> {
        if !config.is_configured() {
            return None;
        }
        Self::new(
            config.server_url.as_deref().unwrap_or_default(),
            config.session_token.as_deref(),
        )
        .ok()
    }

    /// Replace the process-wide client (None = not configured).
    pub fn install(client: Option<ServerClient>) {
        let mut guard = CURRENT.write().unwrap_or_else(|e| e.into_inner());
        *guard = client;
    }

    /// The process-wide **authenticated** client: `NotConfigured` without a
    /// server URL, `NotLoggedIn` without a session.
    pub fn current() -> Result<ServerClient, ServerError> {
        // Read the installed client directly: `current_public()` strips the token.
        let client = CURRENT
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .clone()
            .ok_or(ServerError::NotConfigured)?;
        if client.token.is_none() {
            return Err(ServerError::NotLoggedIn);
        }
        Ok(client)
    }

    /// The process-wide client without the session token, for the public
    /// auth endpoints. `NotConfigured` without a server URL.
    pub fn current_public() -> Result<ServerClient, ServerError> {
        CURRENT
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .clone()
            .map(|c| c.without_token())
            .ok_or(ServerError::NotConfigured)
    }

    /// Same server, no Authorization header.
    pub fn without_token(&self) -> ServerClient {
        ServerClient {
            http: self.http.clone(),
            base_url: self.base_url.clone(),
            token: None,
        }
    }

    pub fn has_token(&self) -> bool {
        self.token.is_some()
    }

    pub(crate) fn session_token(&self) -> Option<&str> {
        self.token.as_deref()
    }

    /// Share the normal session-expiry path with live-meeting HTTP and WS calls.
    pub(crate) fn notify_unauthorized(&self) {
        if let (Some(handler), Some(token)) = (ON_UNAUTHORIZED.get(), self.token.as_deref()) {
            handler(token);
        }
    }

    pub fn base_url(&self) -> &str {
        &self.base_url
    }

    fn url(&self, path: &str) -> String {
        format!("{}{}{}", self.base_url, API_PREFIX, path)
    }

    pub(crate) fn request(&self, method: Method, path: &str) -> RequestBuilder {
        let req = self.http.request(method, self.url(path)).timeout(DEFAULT_TIMEOUT);
        match &self.token {
            Some(token) => req.bearer_auth(token),
            None => req,
        }
    }

    pub(crate) fn transfer_request(&self, method: Method, path: &str) -> RequestBuilder {
        self.request(method, path).timeout(TRANSFER_TIMEOUT)
    }

    pub(crate) async fn send(&self, req: RequestBuilder) -> Result<Response, ServerError> {
        let resp = req.send().await.map_err(map_reqwest_error)?;
        match check_response(resp).await {
            Err(ServerError::Unauthorized(detail)) => match &self.token {
                Some(token) => {
                    log::warn!("Server rejected the login session (401): {}", detail);
                    if let Some(handler) = ON_UNAUTHORIZED.get() {
                        handler(token);
                    }
                    Err(ServerError::Unauthorized(detail))
                }
                // Public endpoint: a 401 is just an error with a server message.
                None => Err(ServerError::Http { status: 401, detail }),
            },
            other => other,
        }
    }

    async fn send_json<T: DeserializeOwned>(&self, req: RequestBuilder) -> Result<T, ServerError> {
        let resp = self.send(req).await?;
        let text = resp.text().await.map_err(map_reqwest_error)?;
        serde_json::from_str(&text)
            .map_err(|e| ServerError::Other(format!("服务器响应解析失败: {} ({})", e, text.chars().take(200).collect::<String>())))
    }

    // ---- JSON helpers ------------------------------------------------------

    pub async fn get<T: DeserializeOwned>(&self, path: &str) -> Result<T, ServerError> {
        // GETs are idempotent: retry once on a transient failure.
        match self.send_json(self.request(Method::GET, path)).await {
            Err(e) if e.is_retryable() => {
                tokio::time::sleep(Duration::from_millis(500)).await;
                self.send_json(self.request(Method::GET, path)).await
            }
            other => other,
        }
    }

    pub async fn get_query<T: DeserializeOwned, Q: Serialize + ?Sized>(
        &self,
        path: &str,
        query: &Q,
    ) -> Result<T, ServerError> {
        self.send_json(self.request(Method::GET, path).query(query)).await
    }

    pub async fn post<B: Serialize + ?Sized, T: DeserializeOwned>(
        &self,
        path: &str,
        body: &B,
    ) -> Result<T, ServerError> {
        self.send_json(self.request(Method::POST, path).json(body)).await
    }

    pub async fn put<B: Serialize + ?Sized, T: DeserializeOwned>(
        &self,
        path: &str,
        body: &B,
    ) -> Result<T, ServerError> {
        self.send_json(self.request(Method::PUT, path).json(body)).await
    }

    /// PUT that expects no response body (e.g. 204).
    pub async fn put_no_content<B: Serialize + ?Sized>(
        &self,
        path: &str,
        body: &B,
    ) -> Result<(), ServerError> {
        self.send(self.request(Method::PUT, path).json(body)).await.map(|_| ())
    }

    pub async fn patch<B: Serialize + ?Sized, T: DeserializeOwned>(
        &self,
        path: &str,
        body: &B,
    ) -> Result<T, ServerError> {
        self.send_json(self.request(Method::PATCH, path).json(body)).await
    }

    pub async fn delete(&self, path: &str) -> Result<(), ServerError> {
        self.send(self.request(Method::DELETE, path)).await.map(|_| ())
    }

    pub async fn delete_json<T: DeserializeOwned>(&self, path: &str) -> Result<T, ServerError> {
        self.send_json(self.request(Method::DELETE, path)).await
    }

    // ---- Binary helpers ----------------------------------------------------

    /// POST a raw live speech segment (16 kHz mono PCM16LE).
    pub async fn post_segment(
        &self,
        meeting_id: &str,
        seq: u64,
        start: f64,
        end: f64,
        language: Option<&str>,
        pcm16le: Vec<u8>,
    ) -> Result<super::types::SegmentResult, ServerError> {
        let mut query: Vec<(&str, String)> = vec![
            ("seq", seq.to_string()),
            ("start", format!("{:.3}", start)),
            ("end", format!("{:.3}", end)),
        ];
        if let Some(lang) = language {
            query.push(("language", lang.to_string()));
        }
        let req = self
            .request(Method::POST, &format!("/meetings/{}/segments", meeting_id))
            .query(&query)
            .header(reqwest::header::CONTENT_TYPE, "application/octet-stream")
            .body(pcm16le);
        self.send_json(req).await
    }

    /// Stream a local file to `PUT /meetings/{id}/audio`, reporting progress (0.0..=1.0).
    pub async fn upload_meeting_audio<F>(
        &self,
        meeting_id: &str,
        file_path: &Path,
        duration: Option<f64>,
        on_progress: F,
    ) -> Result<super::types::AudioUploadResult, ServerError>
    where
        F: Fn(f64) + Send + Sync + 'static,
    {
        let progress = std::sync::Arc::new(on_progress);
        if let Some(result) = super::direct_upload::upload(self, file_path,
            &format!("/meetings/{}/audio", meeting_id), serde_json::json!({"duration": duration}), progress.clone(), None).await? {
            return Ok(result);
        }
        let on_progress = move |p| progress(p);
        let (body, len, filename) = file_body(file_path, on_progress, None).await?;
        let req = self
            .transfer_request(Method::PUT, &format!("/meetings/{}/audio", meeting_id))
            .query(&[("filename", filename.as_str())])
            .header(reqwest::header::CONTENT_TYPE, content_type_for(file_path))
            .header(reqwest::header::CONTENT_LENGTH, len)
            .body(body);
        self.send_json(req).await
    }

    /// Multipart `POST /jobs/import`.
    pub async fn submit_import_job<F>(
        &self,
        file_path: &Path,
        title: &str,
        language: Option<&str>,
        on_progress: F,
        cancel: Option<std::sync::Arc<std::sync::atomic::AtomicBool>>,
    ) -> Result<super::types::Job, ServerError>
    where
        F: Fn(f64) + Send + Sync + 'static,
    {
        let progress = std::sync::Arc::new(on_progress);
        if let Some(result) = super::direct_upload::upload(self, file_path, "/jobs/import",
            serde_json::json!({"title":title,"language":language}), progress.clone(), cancel.clone()).await? {
            return Ok(result);
        }
        let on_progress = move |p| progress(p);
        let (body, len, filename) = file_body(file_path, on_progress, cancel).await?;
        let part = reqwest::multipart::Part::stream_with_length(body, len)
            .file_name(filename)
            .mime_str(content_type_for(file_path))
            .map_err(|e| ServerError::Other(e.to_string()))?;
        let mut form = reqwest::multipart::Form::new()
            .part("file", part)
            .text("title", title.to_string());
        if let Some(lang) = language {
            form = form.text("language", lang.to_string());
        }
        let req = self
            .transfer_request(Method::POST, "/jobs/import")
            .multipart(form);
        self.send_json(req).await
    }

    /// Download `GET /meetings/{id}/audio` into `dest`, reporting progress (0.0..=1.0)
    /// when the size is known. Follows the server's redirect to an OSS signed URL
    /// (reqwest drops the Authorization header on cross-host redirects).
    /// Returns the response Content-Type, or Ok(None) on 404.
    pub async fn download_meeting_audio<F>(
        &self,
        meeting_id: &str,
        dest: &Path,
        on_progress: F,
    ) -> Result<Option<String>, ServerError>
    where
        F: Fn(f64) + Send + Sync + 'static,
    {
        use futures_util::StreamExt;
        use tokio::io::AsyncWriteExt;

        let req = self.transfer_request(Method::GET, &format!("/meetings/{}/audio", meeting_id));
        let resp = match self.send(req).await {
            Ok(r) => r,
            Err(ServerError::NotFound(_)) => return Ok(None),
            Err(e) => return Err(e),
        };
        let content_type = resp
            .headers()
            .get(reqwest::header::CONTENT_TYPE)
            .and_then(|v| v.to_str().ok())
            .map(|s| s.to_string());
        let len = resp.content_length().unwrap_or(0);

        if let Some(parent) = dest.parent() {
            tokio::fs::create_dir_all(parent)
                .await
                .map_err(|e| ServerError::Other(format!("创建下载目录失败: {}", e)))?;
        }
        let tmp = dest.with_extension("part");
        let mut file = tokio::fs::File::create(&tmp)
            .await
            .map_err(|e| ServerError::Other(format!("创建下载文件失败: {}", e)))?;
        let mut received = 0u64;
        let mut last_pct = 0u64;
        let mut stream = resp.bytes_stream();
        let result: Result<(), ServerError> = async {
            while let Some(chunk) = stream.next().await {
                let chunk = chunk.map_err(map_reqwest_error)?;
                file.write_all(&chunk)
                    .await
                    .map_err(|e| ServerError::Other(format!("写入下载文件失败: {}", e)))?;
                received += chunk.len() as u64;
                // Report at most every ~1% to avoid flooding the UI with events.
                if let Some(pct) = (received * 100).checked_div(len) {
                    if pct > last_pct {
                        last_pct = pct;
                        on_progress((received as f64 / len as f64).min(1.0));
                    }
                }
            }
            file.flush()
                .await
                .map_err(|e| ServerError::Other(format!("写入下载文件失败: {}", e)))
        }
        .await;
        drop(file);
        if let Err(e) = result {
            let _ = tokio::fs::remove_file(&tmp).await;
            return Err(e);
        }
        tokio::fs::rename(&tmp, dest)
            .await
            .map_err(|e| ServerError::Other(format!("保存下载文件失败: {}", e)))?;
        Ok(Some(content_type.unwrap_or_default()))
    }
}

/// Build a streaming request body from a file, reporting progress as bytes are read.
pub(super) async fn file_body<F>(
    path: &Path,
    on_progress: F,
    cancel: Option<std::sync::Arc<std::sync::atomic::AtomicBool>>,
) -> Result<(reqwest::Body, u64, String), ServerError>
where
    F: Fn(f64) + Send + Sync + 'static,
{
    use futures_util::StreamExt;
    use std::sync::atomic::{AtomicU64, Ordering};
    use std::sync::Arc;

    let file = tokio::fs::File::open(path)
        .await
        .map_err(|e| ServerError::Other(format!("无法打开音频文件 {}: {}", path.display(), e)))?;
    let len = file
        .metadata()
        .await
        .map_err(|e| ServerError::Other(format!("无法读取音频文件信息: {}", e)))?
        .len();
    let filename = path
        .file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_else(|| "audio.mp4".to_string());

    let sent = Arc::new(AtomicU64::new(0));
    let last_reported = Arc::new(AtomicU64::new(0));
    let stream = tokio_util::io::ReaderStream::with_capacity(file, 256 * 1024).map(move |chunk| {
        if let Some(flag) = &cancel {
            if flag.load(Ordering::SeqCst) {
                return Err(std::io::Error::new(std::io::ErrorKind::Interrupted, "cancelled"));
            }
        }
        if let Ok(bytes) = &chunk {
            let total = sent.fetch_add(bytes.len() as u64, Ordering::SeqCst) + bytes.len() as u64;
            // Report at most every ~1% to avoid flooding the UI with events.
            let pct = (total * 100).checked_div(len).unwrap_or(100);
            if pct > last_reported.load(Ordering::SeqCst) || total == len {
                last_reported.store(pct, Ordering::SeqCst);
                on_progress(if len == 0 { 1.0 } else { total as f64 / len as f64 });
            }
        }
        chunk
    });
    Ok((reqwest::Body::wrap_stream(stream), len, filename))
}

pub(crate) fn content_type_for(path: &Path) -> &'static str {
    match path
        .extension()
        .and_then(|e| e.to_str())
        .map(|e| e.to_ascii_lowercase())
        .as_deref()
    {
        Some("mp4") | Some("m4a") => "audio/mp4",
        Some("wav") => "audio/wav",
        Some("mp3") => "audio/mpeg",
        Some("flac") => "audio/flac",
        Some("ogg") => "audio/ogg",
        Some("webm") => "audio/webm",
        Some("mkv") => "audio/x-matroska",
        Some("aac") => "audio/aac",
        Some("wma") => "audio/x-ms-wma",
        _ => "application/octet-stream",
    }
}

/// File extension to use for a cached download, from the response Content-Type.
pub(crate) fn extension_for_content_type(content_type: &str) -> &'static str {
    let ct = content_type.split(';').next().unwrap_or("").trim().to_ascii_lowercase();
    match ct.as_str() {
        "audio/wav" | "audio/x-wav" | "audio/wave" => "wav",
        "audio/mpeg" | "audio/mp3" => "mp3",
        "audio/flac" | "audio/x-flac" => "flac",
        "audio/ogg" => "ogg",
        "audio/webm" => "webm",
        "audio/aac" => "aac",
        "audio/x-matroska" => "mkv",
        _ => "mp4",
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn error_messages_are_user_friendly() {
        assert_eq!(ServerError::NotConfigured.to_string(), "未配置服务器");
        assert_eq!(ServerError::NotLoggedIn.to_string(), "未登录，请先使用手机号登录");
        assert_eq!(ServerError::Unauthorized(String::new()).to_string(), "登录已失效，请重新登录");
        // Client errors pass the server's Chinese detail through unchanged.
        assert_eq!(
            ServerError::Http { status: 429, detail: "发送过于频繁，请稍后再试".into() }.to_string(),
            "发送过于频繁，请稍后再试"
        );
        assert_eq!(ServerError::NotFound("该手机号未注册".into()).to_string(), "该手机号未注册");
        assert_eq!(ServerError::Forbidden("注册已关闭".into()).to_string(), "注册已关闭");
        assert_eq!(
            ServerError::Http { status: 400, detail: "验证码错误，还可尝试 4 次".into() }.to_string(),
            "验证码错误，还可尝试 4 次"
        );
        assert_eq!(
            ServerError::Http { status: 503, detail: "短信服务未配置".into() }.to_string(),
            "短信服务未配置"
        );
        assert!(ServerError::Connect("x".into()).to_string().starts_with("无法连接服务器"));
        assert_eq!(
            ServerError::Http { status: 500, detail: "boom".into() }.to_string(),
            "服务器错误: boom"
        );
    }

    #[test]
    fn extracts_fastapi_detail() {
        assert_eq!(extract_detail(r#"{"detail":"nope"}"#, StatusCode::BAD_REQUEST), "nope");
        assert_eq!(extract_detail("", StatusCode::BAD_GATEWAY), "HTTP 502");
        assert_eq!(
            extract_detail(r#"{"detail":[{"msg":"x"},{"msg":"y"}]}"#, StatusCode::UNPROCESSABLE_ENTITY),
            INVALID_INPUT_MESSAGE
        );
    }

    #[test]
    fn current_keeps_the_session_token() {
        // The only test touching the process-wide client.
        ServerClient::install(None);
        assert!(matches!(ServerClient::current(), Err(ServerError::NotConfigured)));

        ServerClient::install(Some(ServerClient::new("https://x.test", None).unwrap()));
        assert!(matches!(ServerClient::current(), Err(ServerError::NotLoggedIn)));

        ServerClient::install(Some(ServerClient::new("https://x.test", Some("ms_token")).unwrap()));
        let client = ServerClient::current().expect("logged-in client");
        assert!(client.has_token(), "authenticated calls must carry the session token");
        assert!(!ServerClient::current_public().unwrap().has_token());

        ServerClient::install(None);
    }

    #[test]
    fn retryability() {
        assert!(ServerError::Connect("x".into()).is_retryable());
        assert!(ServerError::Http { status: 503, detail: String::new() }.is_retryable());
        assert!(!ServerError::Unauthorized(String::new()).is_retryable());
        assert!(ServerError::NotLoggedIn.is_auth());
        assert!(!ServerError::Http { status: 400, detail: String::new() }.is_retryable());
    }
}
