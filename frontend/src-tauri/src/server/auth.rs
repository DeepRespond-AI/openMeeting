// server/auth.rs
//
// Phone-number login/registration (server/API.md §1.0 and §3.1): Tauri
// commands, session storage and the 401 handler that drops an expired session.

use serde::Serialize;
use tauri::{AppHandle, Runtime};

use super::client::{ServerClient, ServerError};
use super::config;
use super::heartbeat;
use super::types::{AuthResult, SendCodeResult, User};

const INVALID_PHONE: &str = "请输入正确的 11 位手机号";

/// Normalise a mainland China mobile number to 11 digits (`^1[3-9]\d{9}$`),
/// accepting a leading `+86`/`86` and spaces/dashes like the server does.
pub fn normalize_phone(raw: &str) -> Result<String, String> {
    let compact: String = raw
        .chars()
        .filter(|c| !c.is_whitespace() && *c != '-')
        .collect();
    let digits = compact
        .strip_prefix("+86")
        .or_else(|| (compact.len() == 13).then(|| compact.strip_prefix("86")).flatten())
        .unwrap_or(&compact);
    let bytes = digits.as_bytes();
    let valid = bytes.len() == 11
        && bytes.iter().all(u8::is_ascii_digit)
        && bytes[0] == b'1'
        && (b'3'..=b'9').contains(&bytes[1]);
    if valid {
        Ok(digits.to_string())
    } else {
        Err(INVALID_PHONE.to_string())
    }
}

fn normalize_code(raw: &str) -> Result<String, String> {
    let code: String = raw.chars().filter(|c| !c.is_whitespace()).collect();
    if code.is_empty() || !code.chars().all(|c| c.is_ascii_digit()) {
        return Err("请输入短信验证码".to_string());
    }
    Ok(code)
}

/// Passwords are sent as typed (never trimmed); the server enforces the strength rules.
fn require_password(raw: &str) -> Result<String, String> {
    if raw.is_empty() {
        return Err("请输入密码".to_string());
    }
    Ok(raw.to_string())
}

fn normalize_name(raw: &str) -> Result<String, String> {
    let name = raw.trim();
    if name.is_empty() {
        return Err("请输入昵称".to_string());
    }
    if name.chars().count() > 32 {
        return Err("昵称不能超过 32 个字符".to_string());
    }
    Ok(name.to_string())
}

fn public_client() -> Result<ServerClient, String> {
    ServerClient::current_public().map_err(|e| match e {
        ServerError::NotConfigured => "请先设置服务器地址".to_string(),
        other => other.to_string(),
    })
}

/// Persist the session from a successful login/registration, switch the
/// global client to it and refresh the status (emits `server-status`).
async fn finish_login<R: Runtime>(app: &AppHandle<R>, result: AuthResult) -> Result<User, String> {
    if result.token.trim().is_empty() {
        return Err("服务器未返回登录凭证".to_string());
    }
    let cfg = config::set_session(app, &result.token)?;
    ServerClient::install(ServerClient::from_config(&cfg));
    // Publish the logged-in state right away (the UI leaves the login screen)
    // and seed the cached user so the check below need not refetch /auth/me.
    heartbeat::publish_logged_in(app, result.user.clone());
    log::info!("Logged in to the server as user {}", result.user.id);
    let status = heartbeat::check_now(app).await;
    Ok(status.user.unwrap_or(result.user))
}

#[derive(Serialize)]
struct SendCodeBody<'a> {
    phone: &'a str,
    purpose: &'a str,
}

/// `POST /auth/sms/send` using the saved server URL.
#[tauri::command]
pub async fn auth_send_code(phone: String, purpose: String) -> Result<SendCodeResult, String> {
    let phone = normalize_phone(&phone)?;
    if !matches!(purpose.as_str(), "register" | "login" | "reset_password") {
        return Err(format!("Invalid purpose: {}", purpose));
    }
    let client = public_client()?;
    client
        .post::<_, SendCodeResult>("/auth/sms/send", &SendCodeBody { phone: &phone, purpose: &purpose })
        .await
        .map_err(String::from)
}

#[tauri::command]
pub async fn auth_register<R: Runtime>(
    app: AppHandle<R>,
    phone: String,
    code: String,
    name: String,
    password: String,
) -> Result<User, String> {
    let phone = normalize_phone(&phone)?;
    let code = normalize_code(&code)?;
    let name = normalize_name(&name)?;
    let password = require_password(&password)?;
    let client = public_client()?;
    let client_id = config::load(&app)?.client_id;
    let body = serde_json::json!({
        "phone": phone,
        "code": code,
        "name": name,
        "password": password,
        "client": heartbeat::client_info(&app, &client_id),
    });
    let result: AuthResult = client.post("/auth/register", &body).await.map_err(String::from)?;
    finish_login(&app, result).await
}

/// Login with either an SMS `code` or the account `password` (exactly one).
#[tauri::command]
pub async fn auth_login<R: Runtime>(
    app: AppHandle<R>,
    phone: String,
    code: Option<String>,
    password: Option<String>,
) -> Result<User, String> {
    let phone = normalize_phone(&phone)?;
    let credential = match (code, password) {
        (Some(code), None) => ("code", normalize_code(&code)?),
        (None, Some(password)) => ("password", require_password(&password)?),
        _ => return Err("请填写验证码或密码".to_string()),
    };
    let client = public_client()?;
    let client_id = config::load(&app)?.client_id;
    let mut body = serde_json::json!({
        "phone": phone,
        "client": heartbeat::client_info(&app, &client_id),
    });
    body[credential.0] = serde_json::Value::String(credential.1);
    let result: AuthResult = client.post("/auth/login", &body).await.map_err(String::from)?;
    finish_login(&app, result).await
}

/// Forgot password: set a new one with a `reset_password` SMS code, then sign in
/// (the server signs out every other device).
#[tauri::command]
pub async fn auth_reset_password<R: Runtime>(
    app: AppHandle<R>,
    phone: String,
    code: String,
    password: String,
) -> Result<User, String> {
    let phone = normalize_phone(&phone)?;
    let code = normalize_code(&code)?;
    let password = require_password(&password)?;
    let client = public_client()?;
    let client_id = config::load(&app)?.client_id;
    let body = serde_json::json!({
        "phone": phone,
        "code": code,
        "password": password,
        "client": heartbeat::client_info(&app, &client_id),
    });
    let result: AuthResult = client.post("/auth/password/reset", &body).await.map_err(String::from)?;
    finish_login(&app, result).await
}

/// Set the first password or change it (`old_password` required once one is set).
#[tauri::command]
pub async fn auth_change_password<R: Runtime>(
    app: AppHandle<R>,
    old_password: Option<String>,
    password: String,
) -> Result<User, String> {
    let password = require_password(&password)?;
    let client = ServerClient::current().map_err(String::from)?;
    let user: User = client
        .put("/auth/me/password", &serde_json::json!({ "old_password": old_password, "password": password }))
        .await
        .map_err(String::from)?;
    heartbeat::publish_user(&app, user.clone());
    Ok(user)
}

/// Revoke the session on the server (best effort), clear it locally and emit
/// the logged-out status.
#[tauri::command]
pub async fn auth_logout<R: Runtime>(app: AppHandle<R>) -> Result<(), String> {
    if let Ok(client) = ServerClient::current() {
        let req = client
            .request(reqwest::Method::POST, "/auth/logout")
            .timeout(std::time::Duration::from_secs(8));
        if let Err(e) = client.send(req).await {
            log::warn!("Server logout failed (session cleared locally anyway): {}", e);
        }
    }
    let cfg = config::clear_session(&app)?;
    ServerClient::install(ServerClient::from_config(&cfg));
    heartbeat::publish_logged_out(&app, None);
    log::info!("Logged out");
    // Refresh reachability / auth config for the login screen.
    heartbeat::check_now(&app).await;
    Ok(())
}

/// Cached user from the last check (None when logged out).
#[tauri::command]
pub async fn auth_get_user() -> Result<Option<User>, String> {
    Ok(heartbeat::cached_user())
}

#[tauri::command]
pub async fn auth_update_profile<R: Runtime>(app: AppHandle<R>, name: String) -> Result<User, String> {
    let name = normalize_name(&name)?;
    let client = ServerClient::current().map_err(String::from)?;
    let user: User = client
        .patch("/auth/me", &serde_json::json!({ "name": name }))
        .await
        .map_err(String::from)?;
    heartbeat::publish_user(&app, user.clone());
    Ok(user)
}

/// Called by the HTTP client on a 401 for `token`: drop the stored session
/// (if it is still that token) and tell the UI to show the login screen.
pub fn handle_unauthorized<R: Runtime>(app: &AppHandle<R>, token: &str) {
    match config::clear_session_if(app, token) {
        Ok(Some(cfg)) => {
            ServerClient::install(ServerClient::from_config(&cfg));
            log::warn!("Login session expired or revoked; cleared it locally");
            heartbeat::publish_logged_out(app, Some(heartbeat::SESSION_EXPIRED_MESSAGE.to_string()));
        }
        Ok(None) => {} // already replaced or cleared
        Err(e) => log::error!("Failed to clear the expired session: {}", e),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn phone_normalization() {
        assert_eq!(normalize_phone("13800138000").unwrap(), "13800138000");
        assert_eq!(normalize_phone("+86 138-0013-8000").unwrap(), "13800138000");
        assert_eq!(normalize_phone("8613800138000").unwrap(), "13800138000");
        assert!(normalize_phone("12800138000").is_err());
        assert!(normalize_phone("1380013800").is_err());
        assert!(normalize_phone("1380013800a").is_err());
        assert!(normalize_phone("").is_err());
    }

    #[test]
    fn code_and_name_validation() {
        assert_eq!(normalize_code(" 123456 ").unwrap(), "123456");
        assert!(normalize_code("12a456").is_err());
        assert_eq!(normalize_name("  张三 ").unwrap(), "张三");
        assert!(normalize_name("   ").is_err());
        assert!(normalize_name(&"a".repeat(33)).is_err());
        assert_eq!(require_password(" pass word1 ").unwrap(), " pass word1 ");
        assert!(require_password("").is_err());
    }
}
