// server/commands.rs
//
// Tauri commands for server connection management (API.md §3.1).

use once_cell::sync::Lazy;
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tauri::{AppHandle, Emitter, Manager, Runtime};

use super::client::{extension_for_content_type, ServerClient};
use super::config::{self, PublicServerConfig};
use super::heartbeat;
use super::types::{ServerMeetingMetadata, ServerStatus};

#[tauri::command]
pub async fn server_get_config<R: Runtime>(app: AppHandle<R>) -> Result<PublicServerConfig, String> {
    let cfg = config::load(&app)?;
    Ok(PublicServerConfig::from(&cfg))
}

/// Cached status from the last heartbeat (forces a check if never checked).
#[tauri::command]
pub async fn server_get_status<R: Runtime>(app: AppHandle<R>) -> Result<ServerStatus, String> {
    match heartbeat::cached_status() {
        Some(status) => Ok(status),
        None => Ok(heartbeat::check_now(&app).await),
    }
}

/// Per-meeting locks so concurrent calls (e.g. the player remounting) don't
/// download the same recording twice.
static AUDIO_FETCH_LOCKS: Lazy<std::sync::Mutex<HashMap<String, Arc<tokio::sync::Mutex<()>>>>> =
    Lazy::new(Default::default);

/// Local path of a meeting's audio, for the webview player.
///
/// 1. The recording folder from the local index (this client recorded or
///    previously downloaded it).
/// 2. A file in the legacy `<app cache>/audio-cache/`, moved into a recordings folder.
/// 3. Otherwise download `GET /meetings/{id}/audio` (redirected to OSS by the
///    server) into a recordings folder, emitting `audio-download-progress`.
///
/// Files in the recordings folder (`~/Movies/openmeeting-recordings` on macOS,
/// `~/Music/...` on Windows, `~/Documents/...` on Linux) are outside the static
/// asset scope, so each returned file is allowed explicitly. Returns None if the
/// server has no audio for the meeting.
#[tauri::command]
pub async fn server_fetch_meeting_audio<R: Runtime>(
    app: AppHandle<R>,
    meeting_id: String,
) -> Result<Option<String>, String> {
    if meeting_id.is_empty() || meeting_id.contains(['/', '\\']) || meeting_id.contains("..") {
        return Err("Invalid meeting id".to_string());
    }
    let lock = AUDIO_FETCH_LOCKS
        .lock()
        .unwrap_or_else(|e| e.into_inner())
        .entry(meeting_id.clone())
        .or_default()
        .clone();
    let _guard = lock.lock().await;

    // 1. Local recording
    let indexed = super::local_index::get_folder(&app, &meeting_id).map(PathBuf::from);
    if let Some(folder) = &indexed {
        if let Ok(path) = crate::audio::common::find_audio_file(folder) {
            return allow_for_playback(&app, path).map(Some);
        }
    }

    // 2. Legacy download cache: move it next to the other recordings.
    let cache_dir = app
        .path()
        .app_cache_dir()
        .map_err(|e| format!("Failed to resolve cache dir: {}", e))?
        .join("audio-cache");
    if let Some(cached) = find_cached_audio(&cache_dir, &meeting_id) {
        let ext = cached.extension().and_then(|e| e.to_str()).unwrap_or("mp4").to_string();
        match recording_folder_for(&meeting_id, indexed.clone()).await {
            Ok((folder, created)) => {
                let dest = folder.join(format!("audio.{}", ext));
                if move_file(&cached, &dest).is_ok() {
                    super::local_index::set_folder(&app, &meeting_id, &folder.to_string_lossy());
                    log::info!("Moved cached audio for {} into {}", meeting_id, folder.display());
                    return allow_for_playback(&app, dest).map(Some);
                }
                if created {
                    let _ = std::fs::remove_dir_all(&folder);
                }
            }
            Err(e) => log::warn!("Keeping cached audio for {} in place: {}", meeting_id, e),
        }
        return Ok(Some(cached.to_string_lossy().to_string()));
    }

    // 3. Download from the server into the recordings folder.
    let client = ServerClient::current().map_err(String::from)?;
    let (folder, created) = recording_folder_for(&meeting_id, indexed).await?;
    let tmp_dest = folder.join(".audio.download");
    let progress_app = app.clone();
    let progress_id = meeting_id.clone();
    let downloaded = client
        .download_meeting_audio(&meeting_id, &tmp_dest, move |p| {
            emit_download_progress(&progress_app, &progress_id, p);
        })
        .await;
    let content_type = match downloaded {
        Ok(Some(ct)) => ct,
        Ok(None) | Err(_) => {
            if created {
                let _ = std::fs::remove_dir_all(&folder);
            }
            return downloaded.map(|_| None).map_err(String::from);
        }
    };
    let final_path = folder.join(format!("audio.{}", extension_for_content_type(&content_type)));
    if let Err(e) = std::fs::rename(&tmp_dest, &final_path) {
        let _ = std::fs::remove_file(&tmp_dest);
        return Err(format!("保存录音文件失败: {}", e));
    }
    super::local_index::set_folder(&app, &meeting_id, &folder.to_string_lossy());
    log::info!("Downloaded audio for {} to {}", meeting_id, final_path.display());
    allow_for_playback(&app, final_path).map(Some)
}

fn allow_for_playback<R: Runtime>(app: &AppHandle<R>, path: PathBuf) -> Result<String, String> {
    app.asset_protocol_scope()
        .allow_file(&path)
        .map_err(|e| format!("Failed to allow recording file for playback: {}", e))?;
    Ok(path.to_string_lossy().to_string())
}

fn find_cached_audio(cache_dir: &Path, meeting_id: &str) -> Option<PathBuf> {
    std::fs::read_dir(cache_dir).ok()?.flatten().map(|e| e.path()).find(|path| {
        path.file_stem().and_then(|s| s.to_str()) == Some(meeting_id)
            && !matches!(
                path.extension().and_then(|e| e.to_str()),
                Some("part") | Some("download")
            )
            && path.metadata().map(|m| m.len() > 0).unwrap_or(false)
    })
}

/// Rename, falling back to copy + delete across filesystems.
fn move_file(from: &Path, to: &Path) -> std::io::Result<()> {
    if std::fs::rename(from, to).is_ok() {
        return Ok(());
    }
    std::fs::copy(from, to)?;
    std::fs::remove_file(from)
}

/// The meeting's recordings folder: the indexed one if it still exists, else a new
/// `<title>_<YYYY-MM-DD_HH-MM>` folder (same naming as recordings, from the
/// meeting's creation time). Returns `(folder, newly_created)`.
async fn recording_folder_for(
    meeting_id: &str,
    indexed: Option<PathBuf>,
) -> Result<(PathBuf, bool), String> {
    if let Some(folder) = indexed {
        return Ok((folder, false));
    }
    let client = ServerClient::current().map_err(String::from)?;
    let meta: ServerMeetingMetadata = client
        .get(&format!("/meetings/{}/metadata", meeting_id))
        .await
        .map_err(String::from)?;
    let base = crate::audio::recording_preferences::get_default_recordings_folder();
    let created_at = chrono::DateTime::parse_from_rfc3339(&meta.created_at)
        .map(|d| d.with_timezone(&chrono::Utc))
        .unwrap_or_else(|_| chrono::Utc::now());
    let mut name: String = crate::audio::audio_processing::sanitize_filename(&meta.title)
        .chars()
        .take(80)
        .collect();
    if name.is_empty() {
        name = "meeting".to_string();
    }
    let stem = format!("{}_{}", name, created_at.format("%Y-%m-%d_%H-%M"));
    let mut folder = base.join(&stem);
    let mut n = 2;
    while folder.exists() {
        folder = base.join(format!("{}_{}", stem, n));
        n += 1;
    }
    std::fs::create_dir_all(&folder).map_err(|e| format!("创建录音文件夹失败: {}", e))?;
    Ok((folder, true))
}

fn emit_download_progress<R: Runtime>(app: &AppHandle<R>, meeting_id: &str, progress: f64) {
    let _ = app.emit(
        "audio-download-progress",
        serde_json::json!({
            "meetingId": meeting_id,
            "progress": (progress * 100.0).clamp(0.0, 100.0).round(),
        }),
    );
}

/// Initialise the global client from the persisted config and start the heartbeat.
pub fn init_at_startup<R: Runtime>(app: &AppHandle<R>) {
    match config::load(app) {
        Ok(cfg) => {
            ServerClient::install(ServerClient::from_config(&cfg));
            if cfg.is_configured() {
                log::info!(
                    "Server client initialised for {} ({})",
                    cfg.server_url.as_deref().unwrap_or(""),
                    if cfg.has_session() { "logged in" } else { "not logged in" }
                );
            } else {
                log::info!("Server not configured yet");
            }
        }
        Err(e) => log::error!("Failed to load server config: {}", e),
    }
    let handle = app.clone();
    super::client::set_unauthorized_handler(move |token| {
        super::auth::handle_unauthorized(&handle, token);
    });
    heartbeat::spawn(app.clone());
}

/// Emit an audio upload progress event (`audio-upload-progress`).
pub fn emit_upload_progress<R: Runtime>(
    app: &AppHandle<R>,
    meeting_id: &str,
    progress: f64,
    done: bool,
    error: Option<String>,
) {
    let _ = app.emit(
        "audio-upload-progress",
        serde_json::json!({
            "meetingId": meeting_id,
            "progress": (progress * 100.0).clamp(0.0, 100.0).round(),
            "done": done,
            "error": error,
        }),
    );
}
