// server/heartbeat.rs
//
// Connection status tracking. A background task checks the server every 15 s:
// - no server URL      → `configured=false`
// - URL, no session    → public `GET /auth/config` (reachability + registration info)
// - URL + session      → `POST /client/heartbeat` + `GET /client/capabilities`
//                        (+ `GET /auth/me` when the cached user is missing/stale)
// The resulting ServerStatus is cached and emitted as the `server-status` event.

use once_cell::sync::Lazy;
use std::sync::RwLock;
use std::time::Duration;
use tauri::{AppHandle, Emitter, Runtime};

use super::client::{ServerClient, ServerError};
use super::types::{
    AuthConfig, Capabilities, ClientInfo, HeartbeatRequest, HeartbeatResponse, ServerStatus, User,
};

pub const HEARTBEAT_INTERVAL: Duration = Duration::from_secs(15);
pub const STATUS_EVENT: &str = "server-status";
/// Shown when the server rejects the stored session.
pub const SESSION_EXPIRED_MESSAGE: &str = "登录已过期，请重新登录";

#[derive(Default)]
struct StatusCache {
    status: Option<ServerStatus>,
    revision: u64,
}

impl StatusCache {
    fn replace(&mut self, status: ServerStatus) {
        self.status = Some(status);
        self.revision = self.revision.wrapping_add(1);
    }

    /// A login/logout/profile publication supersedes any probe already in flight.
    fn apply_probe(&mut self, revision: u64, status: ServerStatus) -> bool {
        if revision != self.revision {
            return false;
        }
        self.replace(status);
        true
    }
}

static STATUS: Lazy<RwLock<StatusCache>> = Lazy::new(|| RwLock::new(StatusCache::default()));
static HOSTNAME: Lazy<String> = Lazy::new(resolve_hostname);
/// Serialises status checks so results are stored/emitted in order.
static CHECK_LOCK: Lazy<tokio::sync::Mutex<()>> = Lazy::new(|| tokio::sync::Mutex::new(()));

/// Last known status (None if never checked).
pub fn cached_status() -> Option<ServerStatus> {
    STATUS
        .read()
        .unwrap_or_else(|e| e.into_inner())
        .status
        .clone()
}

/// Logged-in user from the last check (None when logged out).
pub fn cached_user() -> Option<User> {
    cached_status().and_then(|s| s.user)
}

fn emit_status<R: Runtime>(app: &AppHandle<R>, status: &ServerStatus) {
    if let Err(e) = app.emit(STATUS_EVENT, status) {
        log::warn!("Failed to emit server-status: {}", e);
    }
}

/// Cache + emit a status built outside the regular check (login, logout, 401).
fn update_status<R: Runtime>(app: &AppHandle<R>, update: impl FnOnce(&mut ServerStatus)) {
    let mut cache = STATUS.write().unwrap_or_else(|e| e.into_inner());
    let mut status = cache.status.clone().unwrap_or_default();
    update(&mut status);
    cache.replace(status.clone());
    // Keep publication ordered with the cache write, including concurrent probes.
    emit_status(app, &status);
}

pub fn publish_status<R: Runtime>(app: &AppHandle<R>, status: ServerStatus) {
    update_status(app, |current| *current = status);
}

/// Update the cached user (e.g. after a profile change) and notify the UI.
pub fn publish_user<R: Runtime>(app: &AppHandle<R>, user: User) {
    update_status(app, |status| status.user = Some(user));
}

/// Mark the cached status as logged in as `user` (right after login) and notify the UI.
pub fn publish_logged_in<R: Runtime>(app: &AppHandle<R>, user: User) {
    update_status(app, |status| {
        status.logged_in = true;
        status.authenticated = true;
        status.user = Some(user);
        status.error = None;
    });
}

/// Mark the cached status as logged out (session cleared locally) and notify the UI.
pub fn publish_logged_out<R: Runtime>(app: &AppHandle<R>, error: Option<String>) {
    update_status(app, |status| {
        status.logged_in = false;
        status.authenticated = false;
        status.user = None;
        status.capabilities = None;
        status.error = error;
        status.last_check = Some(chrono::Utc::now().to_rfc3339());
    });
}

fn resolve_hostname() -> String {
    for var in ["COMPUTERNAME", "HOSTNAME"] {
        if let Ok(v) = std::env::var(var) {
            if !v.trim().is_empty() {
                return v.trim().to_string();
            }
        }
    }
    if let Ok(v) = std::fs::read_to_string("/etc/hostname") {
        if !v.trim().is_empty() {
            return v.trim().to_string();
        }
    }
    std::process::Command::new("hostname")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "unknown".to_string())
}

/// Device description sent with login/registration.
pub fn client_info<R: Runtime>(app: &AppHandle<R>, client_id: &str) -> ClientInfo {
    ClientInfo {
        client_id: client_id.to_string(),
        hostname: HOSTNAME.clone(),
        os: std::env::consts::OS.to_string(),
        app_version: app.package_info().version.to_string(),
    }
}

/// Heartbeat payload describing this client right now.
pub async fn build_heartbeat<R: Runtime>(app: &AppHandle<R>, client_id: &str) -> HeartbeatRequest {
    let recording = crate::audio::recording_commands::is_recording().await;
    let meeting_id = if recording {
        crate::audio::transcription::remote_provider::active_meeting_id()
    } else {
        None
    };
    let info = client_info(app, client_id);
    HeartbeatRequest {
        client_id: info.client_id,
        hostname: info.hostname,
        os: info.os,
        app_version: info.app_version,
        recording,
        meeting_id,
    }
}

/// Public `GET /auth/config` (works without a session).
pub async fn fetch_auth_config(client: &ServerClient) -> Result<AuthConfig, ServerError> {
    client
        .without_token()
        .get::<AuthConfig>("/auth/config")
        .await
}

/// Capabilities may contain a gateway-cached identity for up to 30 seconds.
/// On a conflict, only `/auth/me` can decide whether this device's recent write
/// or a change on another device is current. Matching summaries need no extra GET.
async fn resolve_user(
    client: &ServerClient,
    caps: &Capabilities,
    previous: Option<User>,
) -> Result<Option<User>, ServerError> {
    let caps_user = caps.user.as_ref();
    let caps_id = caps_user.and_then(|u| u.get("id")).and_then(|v| v.as_str());
    match previous {
        Some(user)
            if (caps_id.is_none() || caps_id == Some(user.id.as_str()))
                && caps_user
                    .and_then(|u| u.get("name"))
                    .and_then(|v| v.as_str())
                    .map_or(true, |name| name == user.name)
                && caps_user
                    .and_then(|u| u.get("phone"))
                    .and_then(|v| v.as_str())
                    .map_or(true, |phone| phone == user.phone) =>
        {
            Ok(Some(user))
        }
        _ => client.get::<User>("/auth/me").await.map(Some),
    }
}

/// Probe the server. Never fails: errors are folded into the returned status.
/// `previous` supplies the cached user / auth config to avoid refetching them.
pub async fn probe(
    client: &ServerClient,
    heartbeat: &HeartbeatRequest,
    previous: Option<&ServerStatus>,
) -> ServerStatus {
    let mut status = ServerStatus {
        configured: true,
        logged_in: client.has_token(),
        last_check: Some(chrono::Utc::now().to_rfc3339()),
        ..Default::default()
    };

    if !client.has_token() {
        match fetch_auth_config(client).await {
            Ok(cfg) => {
                status.connected = true;
                status.auth_config = Some(cfg);
            }
            Err(e) => {
                status.connected = !e.is_connect();
                status.error = Some(e.to_string());
            }
        }
        return status;
    }

    let result: Result<(Capabilities, Option<User>), ServerError> = async {
        let _: HeartbeatResponse = client.post("/client/heartbeat", heartbeat).await?;
        let caps = client.get::<Capabilities>("/client/capabilities").await?;
        let user = resolve_user(client, &caps, previous.and_then(|p| p.user.clone())).await?;
        Ok((caps, user))
    }
    .await;

    match result {
        Ok((caps, user)) => {
            status.connected = true;
            status.authenticated = true;
            status.capabilities = Some(caps);
            status.user = user;
            status.auth_config = match previous.and_then(|p| p.auth_config.clone()) {
                Some(cfg) => Some(cfg),
                None => fetch_auth_config(client).await.ok(),
            };
        }
        Err(ServerError::Unauthorized(_)) => {
            // The 401 handler already cleared the stored session.
            status.connected = true;
            status.logged_in = false;
            status.authenticated = false;
            status.error = Some(SESSION_EXPIRED_MESSAGE.to_string());
            status.auth_config = fetch_auth_config(client).await.ok();
        }
        Err(e) => {
            status.connected = !e.is_connect();
            // The session is still stored (`logged_in` stays true), so a network
            // hiccup does not bounce the UI to the login screen; keep showing the
            // last known user meanwhile.
            status.authenticated = !(e.is_connect() || e.is_auth());
            status.user = previous.and_then(|p| p.user.clone());
            if e.is_connect() {
                status.capabilities = previous.and_then(|p| p.capabilities.clone());
            }
            status.auth_config = previous.and_then(|p| p.auth_config.clone());
            status.error = Some(e.to_string());
        }
    }
    status
}

/// Check the configured server now, cache and emit the result.
pub async fn check_now<R: Runtime>(app: &AppHandle<R>) -> ServerStatus {
    let _guard = CHECK_LOCK.lock().await;
    let (revision, previous) = {
        let cache = STATUS.read().unwrap_or_else(|e| e.into_inner());
        (cache.revision, cache.status.clone())
    };

    let config = match super::config::load(app) {
        Ok(c) => c,
        Err(e) => {
            log::warn!("Failed to load server config: {}", e);
            Default::default()
        }
    };

    let status = match ServerClient::from_config(&config) {
        Some(client) => {
            let hb = build_heartbeat(app, &config.client_id).await;
            probe(&client, &hb, previous.as_ref()).await
        }
        None => ServerStatus {
            configured: false,
            error: Some(ServerError::NotConfigured.to_string()),
            last_check: Some(chrono::Utc::now().to_rfc3339()),
            ..Default::default()
        },
    };

    let mut cache = STATUS.write().unwrap_or_else(|e| e.into_inner());
    if cache.apply_probe(revision, status.clone()) {
        emit_status(app, &status);
        status
    } else {
        // Return the current account as well: a caller of check_now must not
        // receive a stale snapshot that was deliberately not sent to the UI.
        cache.status.clone().unwrap_or(status)
    }
}

/// Spawn the periodic heartbeat task (runs for the lifetime of the app).
pub fn spawn<R: Runtime>(app: AppHandle<R>) {
    tauri::async_runtime::spawn(async move {
        loop {
            let status = check_now(&app).await;
            if status.configured && !status.connected {
                log::debug!("Server heartbeat failed: {:?}", status.error);
            }
            tokio::time::sleep(HEARTBEAT_INTERVAL).await;
        }
    });
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::io::{AsyncReadExt, AsyncWriteExt};

    fn user(name: &str) -> User {
        User {
            id: "account-1".into(),
            name: name.into(),
            phone: "13500003139".into(),
            has_password: true,
            ..Default::default()
        }
    }

    fn signed_in(user: User) -> ServerStatus {
        ServerStatus {
            configured: true,
            connected: true,
            logged_in: true,
            authenticated: true,
            user: Some(user),
            ..Default::default()
        }
    }

    #[test]
    fn a_profile_save_supersedes_in_flight_success_and_failure() {
        for disconnected in [false, true] {
            let mut cache = StatusCache::default();
            let mut old_probe = signed_in(user("旧昵称"));
            cache.replace(old_probe.clone());
            let revision = cache.revision;
            cache.replace(signed_in(user("新昵称")));
            if disconnected {
                old_probe.connected = false;
                old_probe.authenticated = false;
                old_probe.error = Some("timeout".into());
            }
            assert!(!cache.apply_probe(revision, old_probe));
            let current = cache.status.unwrap();
            assert_eq!(current.user.unwrap().name, "新昵称");
            assert!(current.connected);
        }
    }

    #[test]
    fn stale_probes_cannot_undo_logout_or_switch_accounts() {
        let old_probe = signed_in(user("旧账号"));
        for replacement in [
            ServerStatus::default(),
            signed_in(User {
                id: "account-2".into(),
                name: "新账号".into(),
                ..user("新账号")
            }),
        ] {
            let expected = replacement.user.clone();
            let mut cache = StatusCache::default();
            cache.replace(old_probe.clone());
            let revision = cache.revision;
            cache.replace(replacement);
            assert!(!cache.apply_probe(revision, old_probe.clone()));
            assert_eq!(cache.status.unwrap().user, expected);
        }
    }

    #[test]
    fn current_probes_still_refresh_connection_and_account_state() {
        let mut cache = StatusCache::default();
        let revision = cache.revision;
        assert!(cache.apply_probe(revision, signed_in(user("新昵称"))));
        let revision = cache.revision;
        let mut offline = cache.status.clone().unwrap();
        offline.connected = false;
        assert!(cache.apply_probe(revision, offline));
        assert!(!cache.status.unwrap().connected);
    }

    async fn account_endpoint(account: &User) -> (ServerClient, tokio::task::JoinHandle<()>) {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let url = format!("http://{}", listener.local_addr().unwrap());
        let body = serde_json::to_string(account).unwrap();
        let server = tokio::spawn(async move {
            let (mut stream, _) = listener.accept().await.unwrap();
            let mut request = Vec::new();
            loop {
                let mut buffer = [0; 1024];
                let read = stream.read(&mut buffer).await.unwrap();
                assert!(read > 0);
                request.extend_from_slice(&buffer[..read]);
                if request.windows(4).any(|part| part == b"\r\n\r\n") {
                    break;
                }
            }
            let request = String::from_utf8(request).unwrap();
            assert!(request.starts_with("GET /api/v1/auth/me HTTP/1.1\r\n"));
            assert!(request
                .to_lowercase()
                .contains("authorization: bearer fixture-session"));
            let response = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
                body.len(), body
            );
            stream.write_all(response.as_bytes()).await.unwrap();
        });
        (
            ServerClient::new(&url, Some("fixture-session")).unwrap(),
            server,
        )
    }

    #[tokio::test]
    async fn stale_gateway_name_does_not_roll_back_a_saved_profile() {
        let current = user("新昵称");
        let (client, server) = account_endpoint(&current).await;
        let caps = Capabilities {
            user: Some(serde_json::json!({"id":current.id,"name":"旧昵称"})),
            ..Default::default()
        };
        let resolved = resolve_user(&client, &caps, Some(current.clone()))
            .await
            .unwrap();
        assert_eq!(resolved, Some(current));
        tokio::time::timeout(Duration::from_secs(3), server)
            .await
            .unwrap()
            .unwrap();
    }

    #[tokio::test]
    async fn changes_from_another_device_are_not_frozen_out() {
        let current = user("另一设备修改的昵称");
        let (client, server) = account_endpoint(&current).await;
        let caps = Capabilities {
            user: Some(serde_json::json!({"id":current.id,"name":current.name})),
            ..Default::default()
        };
        assert_eq!(
            resolve_user(&client, &caps, Some(user("旧昵称")))
                .await
                .unwrap(),
            Some(current)
        );
        tokio::time::timeout(Duration::from_secs(3), server)
            .await
            .unwrap()
            .unwrap();
    }

    #[tokio::test]
    async fn missing_or_different_account_fetches_the_full_profile() {
        for previous in [
            None,
            Some(User {
                id: "account-2".into(),
                ..user("同名")
            }),
        ] {
            let current = user("同名");
            let (client, server) = account_endpoint(&current).await;
            let caps = Capabilities {
                user: Some(serde_json::json!({"id":current.id,"name":current.name})),
                ..Default::default()
            };
            assert_eq!(
                resolve_user(&client, &caps, previous).await.unwrap(),
                Some(current)
            );
            tokio::time::timeout(Duration::from_secs(3), server)
                .await
                .unwrap()
                .unwrap();
        }
    }

    #[tokio::test]
    async fn matching_or_absent_summary_keeps_full_cached_user_without_network() {
        let client = ServerClient::new("http://127.0.0.1:1", Some("fixture-session")).unwrap();
        for summary in [
            None,
            Some(serde_json::json!({"id":"account-1","name":"新昵称"})),
        ] {
            let caps = Capabilities {
                user: summary,
                ..Default::default()
            };
            let current = user("新昵称");
            assert_eq!(
                resolve_user(&client, &caps, Some(current.clone()))
                    .await
                    .unwrap(),
                Some(current)
            );
        }
    }
}
