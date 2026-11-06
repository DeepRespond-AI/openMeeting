// server/config.rs
//
// Client-side connection settings. The server URL is fixed at build time
// ([`SERVER_URL`]) and never shown to or editable by the user; the phone-login
// session token and the client id are stored with tauri-plugin-store in
// `server-config.json`.
//
// Session tokens are obtained only through phone-number login/registration
// (server/API.md §1.0); there is no admin-issued API token any more.

use serde::{Deserialize, Serialize};
use tauri::{AppHandle, Runtime};
use tauri_plugin_store::StoreExt;

/// The OpenMeeting server this build talks to. Override for development builds with
/// `OPENMEETING_SERVER_URL=http://127.0.0.1:39110 pnpm run tauri:dev` (read at compile time).
/// The fallback is a placeholder; deployed builds must set their actual gateway.
pub const SERVER_URL: &str = match option_env!("OPENMEETING_SERVER_URL") {
    Some(url) => url,
    None => "https://meeting.example.com",
};

const STORE_FILE: &str = "server-config.json";
/// User-entered server URL of older builds; dropped on load (with its session
/// when it pointed at another server).
const KEY_LEGACY_SERVER_URL: &str = "serverUrl";
const KEY_SESSION_TOKEN: &str = "sessionToken";
const KEY_CLIENT_ID: &str = "clientId";
/// Admin-issued API token from the pre-phone-login era; removed on load.
const KEY_LEGACY_TOKEN: &str = "token";

#[derive(Debug, Clone, Default)]
pub struct ServerConfig {
    pub server_url: Option<String>,
    pub session_token: Option<String>,
    pub client_id: String,
}

impl ServerConfig {
    /// A server URL is set (always true for real builds: it is built in).
    pub fn is_configured(&self) -> bool {
        self.server_url.as_deref().is_some_and(|u| !u.is_empty())
    }

    /// A session token is stored locally (the user logged in on this device).
    pub fn has_session(&self) -> bool {
        self.session_token.as_deref().is_some_and(|t| !t.is_empty())
    }
}

/// Public (secret-free) view returned by `server_get_config`. The server URL is
/// deliberately not part of it: the UI never shows it.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PublicServerConfig {
    pub logged_in: bool,
    pub client_id: String,
}

impl From<&ServerConfig> for PublicServerConfig {
    fn from(c: &ServerConfig) -> Self {
        Self {
            logged_in: c.is_configured() && c.has_session(),
            client_id: c.client_id.clone(),
        }
    }
}

/// The built-in server URL without trailing slashes.
pub fn server_url() -> String {
    SERVER_URL.trim().trim_end_matches('/').to_string()
}

fn get_string<R: Runtime>(
    store: &tauri_plugin_store::Store<R>,
    key: &str,
) -> Option<String> {
    store
        .get(key)
        .and_then(|v| v.as_str().map(|s| s.to_string()))
        .filter(|s| !s.is_empty())
}

fn open_store<R: Runtime>(
    app: &AppHandle<R>,
) -> Result<std::sync::Arc<tauri_plugin_store::Store<R>>, String> {
    app.store(STORE_FILE)
        .map_err(|e| format!("Failed to open server config store: {}", e))
}

fn persist<R: Runtime>(store: &tauri_plugin_store::Store<R>) -> Result<(), String> {
    store
        .save()
        .map_err(|e| format!("Failed to save server config: {}", e))
}

/// Load the config, generating and persisting a client id on first use.
pub fn load<R: Runtime>(app: &AppHandle<R>) -> Result<ServerConfig, String> {
    let store = open_store(app)?;
    let mut dirty = false;

    let client_id = match get_string(&store, KEY_CLIENT_ID) {
        Some(id) => id,
        None => {
            let id = uuid::Uuid::new_v4().to_string();
            store.set(KEY_CLIENT_ID, serde_json::Value::String(id.clone()));
            dirty = true;
            id
        }
    };

    if store.has(KEY_LEGACY_TOKEN) {
        store.delete(KEY_LEGACY_TOKEN);
        dirty = true;
        log::info!("Removed legacy server API token from config (phone login replaces it)");
    }

    let server_url = server_url();
    if let Some(legacy) = get_string(&store, KEY_LEGACY_SERVER_URL) {
        // Sessions belong to the server that issued them.
        if legacy.trim_end_matches('/') != server_url {
            store.delete(KEY_SESSION_TOKEN);
            log::info!("Dropped the session of a previously configured server");
        }
        store.delete(KEY_LEGACY_SERVER_URL);
        dirty = true;
    }

    if dirty {
        if let Err(e) = store.save() {
            log::warn!("Failed to persist server config: {}", e);
        }
    }

    Ok(ServerConfig {
        server_url: Some(server_url).filter(|u| !u.is_empty()),
        session_token: get_string(&store, KEY_SESSION_TOKEN),
        client_id,
    })
}

/// Store a new session token (after login/registration).
pub fn set_session<R: Runtime>(app: &AppHandle<R>, token: &str) -> Result<ServerConfig, String> {
    let store = open_store(app)?;
    store.set(KEY_SESSION_TOKEN, serde_json::Value::String(token.trim().to_string()));
    persist(&store)?;
    load(app)
}

/// Remove the stored session token.
pub fn clear_session<R: Runtime>(app: &AppHandle<R>) -> Result<ServerConfig, String> {
    let store = open_store(app)?;
    store.delete(KEY_SESSION_TOKEN);
    persist(&store)?;
    load(app)
}

/// Remove the stored session only if it is still `token` (a 401 for an older
/// token must not log out a session created in the meantime). Returns the new
/// config when something was cleared.
pub fn clear_session_if<R: Runtime>(app: &AppHandle<R>, token: &str) -> Result<Option<ServerConfig>, String> {
    let store = open_store(app)?;
    if get_string(&store, KEY_SESSION_TOKEN).as_deref() != Some(token) {
        return Ok(None);
    }
    store.delete(KEY_SESSION_TOKEN);
    persist(&store)?;
    load(app).map(Some)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn public_config_reports_login_state() {
        let mut cfg = ServerConfig {
            server_url: Some("https://x".into()),
            session_token: None,
            client_id: "c1".into(),
        };
        let v = serde_json::to_value(PublicServerConfig::from(&cfg)).unwrap();
        assert_eq!(v["loggedIn"], false);
        assert!(v.get("serverUrl").is_none(), "the server URL is never sent to the UI");
        assert_eq!(v["clientId"], "c1");
        assert!(v.get("tokenSet").is_none());

        cfg.session_token = Some("ms_abc".into());
        assert!(cfg.has_session());
        let v = serde_json::to_value(PublicServerConfig::from(&cfg)).unwrap();
        assert_eq!(v["loggedIn"], true);
    }

    #[test]
    fn built_in_server_url_is_absolute() {
        let url = server_url();
        assert!(url.starts_with("http://") || url.starts_with("https://"), "{url}");
        assert!(!url.ends_with('/'));
    }
}
