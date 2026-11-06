// server/local_index.rs
//
// Small local index mapping server meeting ids to the local recording folder
// (where recording_saver wrote audio.mp4 / transcripts.json). The server does
// not know about client paths, but the UI uses `folder_path` for playback,
// "open folder" and recovery, so we merge it back into meeting metadata.

use std::path::PathBuf;
use tauri::{AppHandle, Runtime};
use tauri_plugin_store::StoreExt;

const STORE_FILE: &str = "local-meetings.json";
const KEY_FOLDERS: &str = "folders";

pub fn set_folder<R: Runtime>(app: &AppHandle<R>, meeting_id: &str, folder: &str) {
    let Ok(store) = app.store(STORE_FILE) else {
        log::warn!("Failed to open local meeting index");
        return;
    };
    let mut map = store
        .get(KEY_FOLDERS)
        .and_then(|v| v.as_object().cloned())
        .unwrap_or_default();
    map.insert(meeting_id.to_string(), serde_json::Value::String(folder.to_string()));
    store.set(KEY_FOLDERS, serde_json::Value::Object(map));
    if let Err(e) = store.save() {
        log::warn!("Failed to persist local meeting index: {}", e);
    }
}

/// Local folder for a meeting, only if it still exists on disk.
pub fn get_folder<R: Runtime>(app: &AppHandle<R>, meeting_id: &str) -> Option<String> {
    let store = app.store(STORE_FILE).ok()?;
    let folder = store
        .get(KEY_FOLDERS)?
        .get(meeting_id)?
        .as_str()?
        .to_string();
    if PathBuf::from(&folder).exists() {
        Some(folder)
    } else {
        None
    }
}

pub fn remove<R: Runtime>(app: &AppHandle<R>, meeting_id: &str) {
    let Ok(store) = app.store(STORE_FILE) else {
        return;
    };
    if let Some(mut map) = store.get(KEY_FOLDERS).and_then(|v| v.as_object().cloned()) {
        if map.remove(meeting_id).is_some() {
            store.set(KEY_FOLDERS, serde_json::Value::Object(map));
            let _ = store.save();
        }
    }
}
