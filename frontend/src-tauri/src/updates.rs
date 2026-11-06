// updates.rs
//
// Client upgrades from our own server (server/API.md §1.8, §3): the Tauri updater plugin asks
// `/api/v1/updates/tauri/{target}/{arch}/{current_version}` on the built-in server, verifies
// the package against the public key in tauri.conf.json, installs it and restarts the app.

use once_cell::sync::Lazy;
use serde::Serialize;
use std::sync::Mutex;
use std::time::Duration;
use tauri::{AppHandle, Emitter, Runtime};
use tauri_plugin_updater::{Update, UpdaterExt};

/// The update found by the last `update_check`, installed by `update_install`.
static PENDING: Lazy<Mutex<Option<Update>>> = Lazy::new(|| Mutex::new(None));

const CHECK_TIMEOUT: Duration = Duration::from_secs(20);

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdateCheckResult {
    pub available: bool,
    pub current_version: String,
    pub version: Option<String>,
    pub notes: Option<String>,
    pub pub_date: Option<String>,
    /// The user must install it before using the app (forced release or below the minimum version).
    pub force: bool,
    pub min_version: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct DownloadProgress {
    downloaded: u64,
    total: Option<u64>,
}

/// Why an install has to wait (shown to the user), or None when it can start now.
async fn install_blocker() -> Option<&'static str> {
    if crate::audio::recording_commands::is_recording().await {
        return Some("正在录音，请结束录音后再更新");
    }
    if crate::audio::recording_commands::has_syncing_meetings() {
        return Some("会议仍在后台同步，请稍后再更新");
    }
    None
}

fn endpoint<R: Runtime>(app: &AppHandle<R>) -> Result<(url::Url, Option<String>), String> {
    let config = crate::server::config::load(app)?;
    let base = config
        .server_url
        .clone()
        .ok_or_else(|| "未配置服务器".to_string())?;
    let mut url = url::Url::parse(&format!(
        "{}/api/v1/updates/tauri/{{{{target}}}}/{{{{arch}}}}/{{{{current_version}}}}",
        base.trim_end_matches('/')
    ))
    .map_err(|e| format!("无效的更新地址: {}", e))?;
    url.query_pairs_mut().append_pair("client_id", &config.client_id);
    Ok((url, config.session_token.filter(|t| !t.is_empty())))
}

/// Ask the server whether a newer version is available for this machine.
#[tauri::command]
pub async fn update_check<R: Runtime>(app: AppHandle<R>) -> Result<UpdateCheckResult, String> {
    let current_version = app.package_info().version.to_string();
    let (url, token) = endpoint(&app)?;
    let mut builder = app
        .updater_builder()
        .endpoints(vec![url])
        .map_err(|e| e.to_string())?
        .timeout(CHECK_TIMEOUT);
    if let Some(token) = token {
        // Identifies the user for the rollout allow-list; the download itself is public.
        builder = builder
            .header("Authorization", format!("Bearer {}", token))
            .map_err(|e| e.to_string())?;
    }
    let update = builder
        .build()
        .map_err(|e| e.to_string())?
        .check()
        .await
        .map_err(|e| {
            log::warn!("Update check failed: {}", e);
            format!("检查更新失败：{}", e)
        })?;

    let mut pending = PENDING.lock().unwrap_or_else(|e| e.into_inner());
    let Some(mut update) = update else {
        *pending = None;
        return Ok(UpdateCheckResult {
            available: false,
            current_version,
            version: None,
            notes: None,
            pub_date: None,
            force: false,
            min_version: None,
        });
    };
    // Never send the session token to the package host (OSS signed URLs).
    update.headers.clear();
    let force = update.raw_json.get("force").and_then(|v| v.as_bool()).unwrap_or(false);
    let min_version = update
        .raw_json
        .get("min_version")
        .and_then(|v| v.as_str())
        .map(str::to_string);
    let result = UpdateCheckResult {
        available: true,
        current_version,
        version: Some(update.version.clone()),
        notes: update.body.clone().filter(|b| !b.trim().is_empty()),
        pub_date: update.date.map(|d| d.to_string()),
        force,
        min_version,
    };
    log::info!(
        "Update available: {} → {} (force: {})",
        result.current_version,
        update.version,
        force
    );
    *pending = Some(update);
    Ok(result)
}

/// Download, verify and install the update found by `update_check`, then restart.
/// Emits `update-download-progress {downloaded, total}`. Refused while recording or while a
/// meeting is still syncing in the background.
#[tauri::command]
pub async fn update_install<R: Runtime>(app: AppHandle<R>) -> Result<(), String> {
    if let Some(reason) = install_blocker().await {
        return Err(reason.to_string());
    }
    let update = PENDING
        .lock()
        .unwrap_or_else(|e| e.into_inner())
        .clone()
        .ok_or_else(|| "没有可安装的更新，请重新检查更新".to_string())?;

    log::info!("Installing update {}", update.version);
    let mut downloaded: u64 = 0;
    let progress_app = app.clone();
    update
        .download_and_install(
            move |chunk, total| {
                downloaded += chunk as u64;
                let _ = progress_app.emit("update-download-progress", DownloadProgress { downloaded, total });
            },
            || log::info!("Update downloaded, installing"),
        )
        .await
        .map_err(|e| {
            log::error!("Update install failed: {}", e);
            format!("更新失败：{}", e)
        })?;

    log::info!("Update installed, restarting");
    app.restart();
}

/// Whether `update_install` would be refused right now (and why), for the UI.
#[tauri::command]
pub async fn update_install_blocker() -> Option<String> {
    install_blocker().await.map(str::to_string)
}
