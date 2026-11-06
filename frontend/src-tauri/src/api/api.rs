// api/api.rs
//
// Meeting / transcript data commands. All data lives on the OpenMeeting server;
// these commands keep their original names, arguments and return shapes and
// forward to the server client API (`/api/v1`). See server/API.md §3.2.

use log::{debug as log_debug, error as log_error, info as log_info, warn as log_warn};
use serde::{Deserialize, Serialize};
use tauri::{AppHandle, Runtime};

use crate::audio::transcription::remote_provider;
use crate::server::local_index;
use crate::server::types::ServerMeetingMetadata;
use crate::server::ServerClient;

#[derive(Debug, Serialize, Deserialize)]
pub struct Meeting {
    #[serde(default)]
    pub can_manage: Option<bool>,
    pub id: String,
    pub title: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TranscriptSearchResult {
    pub id: String,
    pub title: String,
    #[serde(rename = "matchContext")]
    pub match_context: String,
    pub timestamp: String,
}

/// Compatibility shim shape for `api_get_model_config`.
#[derive(Debug, Serialize, Deserialize)]
pub struct ModelConfig {
    pub provider: String,
    pub model: String,
    #[serde(rename = "whisperModel")]
    pub whisper_model: String,
    #[serde(rename = "apiKey")]
    pub api_key: Option<String>,
    #[serde(rename = "ollamaEndpoint")]
    pub ollama_endpoint: Option<String>,
}

/// Compatibility shim shape for `api_get_transcript_config`.
#[derive(Debug, Serialize, Deserialize)]
pub struct TranscriptConfig {
    pub provider: String,
    pub model: String,
    #[serde(rename = "apiKey")]
    pub api_key: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MeetingDetails {
    pub id: String,
    pub title: String,
    pub created_at: String,
    pub updated_at: String,
    pub transcripts: Vec<MeetingTranscript>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MeetingTranscript {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub speaker: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub confidence: Option<f64>,
    pub id: String,
    pub text: String,
    pub timestamp: String,
    // Recording-relative timestamps for audio-transcript synchronization
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub audio_start_time: Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub audio_end_time: Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub duration: Option<f64>,
}

/// Meeting metadata without transcripts (for pagination).
/// `has_audio` / `audio_duration` come from the server; `folder_path` is the
/// local recording folder when this client recorded the meeting.
#[derive(Debug, Serialize, Deserialize)]
pub struct MeetingMetadata {
    #[serde(default)]
    pub can_manage: Option<bool>,
    pub id: String,
    pub title: String,
    pub created_at: String,
    pub updated_at: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub folder_path: Option<String>,
    #[serde(default)]
    pub has_audio: bool,
    #[serde(default)]
    pub audio_duration: Option<f64>,
}

/// Paginated transcripts response with total count
#[derive(Debug, Serialize, Deserialize)]
pub struct PaginatedTranscriptsResponse {
    pub transcripts: Vec<MeetingTranscript>,
    pub total_count: i64,
    pub has_more: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TranscriptSegment {
    pub id: String,
    pub text: String,
    pub timestamp: String,
    // Recording-relative timestamps for playback synchronization
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub audio_start_time: Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub audio_end_time: Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub duration: Option<f64>,
}

fn client() -> Result<ServerClient, String> {
    ServerClient::current().map_err(String::from)
}

fn encode(s: &str) -> String {
    url::form_urlencoded::byte_serialize(s.as_bytes()).collect()
}

// ============================================================================
// MEETINGS
// ============================================================================

#[tauri::command]
pub async fn api_get_meetings<R: Runtime>(
    _app: AppHandle<R>,
    auth_token: Option<String>,
) -> Result<Vec<Meeting>, String> {
    log_info!("api_get_meetings called (auth_token: {})", auth_token.is_some());
    client()?.get("/meetings").await.map_err(String::from)
}

#[tauri::command]
pub async fn api_search_transcripts<R: Runtime>(
    _app: AppHandle<R>,
    query: String,
    auth_token: Option<String>,
) -> Result<Vec<TranscriptSearchResult>, String> {
    log_info!(
        "api_search_transcripts called with query: '{}', auth_token: {}",
        query,
        auth_token.is_some()
    );
    client()?
        .get_query("/transcripts/search", &[("q", query.as_str())])
        .await
        .map_err(|e| format!("Failed to search transcripts: {}", e))
}

#[tauri::command]
pub async fn api_delete_meeting<R: Runtime>(
    app: AppHandle<R>,
    meeting_id: String,
    auth_token: Option<String>,
) -> Result<serde_json::Value, String> {
    log_info!(
        "api_delete_meeting called for meeting_id: {}, auth_token: {}",
        meeting_id,
        auth_token.is_some()
    );
    client()?
        .delete(&format!("/meetings/{}", encode(&meeting_id)))
        .await
        .map_err(|e| format!("Failed to delete meeting: {}", e))?;

    local_index::remove(&app, &meeting_id);
    remove_cached_audio(&app, &meeting_id);

    Ok(serde_json::json!({
        "status": "success",
        "message": "Meeting deleted successfully"
    }))
}

fn remove_cached_audio<R: Runtime>(app: &AppHandle<R>, meeting_id: &str) {
    use tauri::Manager;
    let Ok(cache) = app.path().app_cache_dir() else {
        return;
    };
    if let Ok(entries) = std::fs::read_dir(cache.join("audio-cache")) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.file_stem().and_then(|s| s.to_str()) == Some(meeting_id) {
                let _ = std::fs::remove_file(path);
            }
        }
    }
}

#[tauri::command]
pub async fn api_get_meeting<R: Runtime>(
    _app: AppHandle<R>,
    meeting_id: String,
    auth_token: Option<String>,
) -> Result<MeetingDetails, String> {
    log_info!(
        "api_get_meeting called for meeting_id: {}, auth_token: {}",
        meeting_id,
        auth_token.is_some()
    );
    client()?
        .get(&format!("/meetings/{}", encode(&meeting_id)))
        .await
        .map_err(|e| format!("Failed to retrieve meeting: {}", e))
}

/// Get meeting metadata without transcripts (for pagination)
#[tauri::command]
pub async fn api_get_meeting_metadata<R: Runtime>(
    app: AppHandle<R>,
    meeting_id: String,
) -> Result<MeetingMetadata, String> {
    log_info!("api_get_meeting_metadata called for meeting_id: {}", meeting_id);
    let meta: ServerMeetingMetadata = client()?
        .get(&format!("/meetings/{}/metadata", encode(&meeting_id)))
        .await
        .map_err(|e| format!("Failed to retrieve meeting metadata: {}", e))?;

    Ok(MeetingMetadata {
        can_manage: meta.can_manage,
        folder_path: local_index::get_folder(&app, &meta.id).or(meta.folder_path),
        id: meta.id,
        title: meta.title,
        created_at: meta.created_at,
        updated_at: meta.updated_at,
        has_audio: meta.has_audio,
        audio_duration: meta.audio_duration,
    })
}

/// Get paginated transcripts for a meeting
#[tauri::command]
pub async fn api_get_meeting_transcripts<R: Runtime>(
    _app: AppHandle<R>,
    meeting_id: String,
    limit: i64,
    offset: i64,
) -> Result<PaginatedTranscriptsResponse, String> {
    log_info!(
        "api_get_meeting_transcripts called for meeting_id: {}, limit: {}, offset: {}",
        meeting_id,
        limit,
        offset
    );
    fetch_transcripts_page(&client()?, &meeting_id, limit, offset)
        .await
        .map_err(|e| format!("Failed to retrieve transcripts: {}", e))
}

async fn fetch_transcripts_page(
    client: &ServerClient,
    meeting_id: &str,
    limit: i64,
    offset: i64,
) -> Result<PaginatedTranscriptsResponse, crate::server::ServerError> {
    client
        .get_query(
            &format!("/meetings/{}/transcripts", encode(meeting_id)),
            &[("limit", limit), ("offset", offset)],
        )
        .await
}

#[tauri::command]
pub async fn api_save_meeting_title<R: Runtime>(
    _app: AppHandle<R>,
    meeting_id: String,
    title: String,
    auth_token: Option<String>,
) -> Result<serde_json::Value, String> {
    log_info!(
        "api_save_meeting_title called for meeting_id: {}, auth_token: {}",
        meeting_id,
        auth_token.is_some()
    );
    let _: ServerMeetingMetadata = client()?
        .patch(
            &format!("/meetings/{}", encode(&meeting_id)),
            &serde_json::json!({ "title": title }),
        )
        .await
        .map_err(|e| format!("Failed to update meeting: {}", e))?;
    Ok(serde_json::json!({"message": "Meeting title saved successfully"}))
}

/// Called by the UI after a recording stops (and by other "save transcript" flows).
///
/// Transcript id reconciliation: during a live recording every segment is
/// already stored server-side by `POST /meetings/{id}/segments`, but the UI
/// generates its own transcript ids, so ids cannot be used to de-duplicate.
/// Instead, when this call belongs to the recording that just finished (the
/// server meeting created at recording start), we:
///   1. rename that meeting to `meeting_title`,
///   2. fetch the server's transcripts and only insert UI transcripts whose
///      recording-relative `audio_start_time` has no server counterpart
///      (normally none — this only fills gaps, e.g. segments that could not be
///      uploaded), using fresh ids.
/// Otherwise a new server meeting is created and all transcripts are inserted.
/// Returns the server meeting id.
#[tauri::command]
pub async fn api_save_transcript<R: Runtime>(
    app: AppHandle<R>,
    meeting_title: String,
    transcripts: Vec<serde_json::Value>,
    folder_path: Option<String>,
    auth_token: Option<String>,
) -> Result<serde_json::Value, String> {
    log_info!(
        "api_save_transcript called for meeting: {}, transcripts: {}, folder_path: {:?}, auth_token: {}",
        meeting_title,
        transcripts.len(),
        folder_path,
        auth_token.is_some()
    );

    let segments: Vec<TranscriptSegment> = transcripts
        .into_iter()
        .map(serde_json::from_value)
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| {
            log_error!("Failed to parse transcript segments: {}", e);
            format!("Invalid transcript data format: {}. Please check the data structure.", e)
        })?;

    let client = client()?;
    let folder_path = folder_path.filter(|p| !p.trim().is_empty());

    let session = remote_provider::last_session().filter(|s| {
        // Make sure the save really belongs to that recording.
        match (folder_path.as_deref(), local_index::get_folder(&app, &s.meeting_id)) {
            (Some(requested), Some(known)) => requested == known,
            _ => true,
        }
    });

    let meeting_id = match session {
        Some(session) => {
            let meeting_id = session.meeting_id.clone();
            log_info!("Attaching transcript save to recording meeting {}", meeting_id);
            let _: ServerMeetingMetadata = client
                .patch(
                    &format!("/meetings/{}", encode(&meeting_id)),
                    &serde_json::json!({ "title": meeting_title }),
                )
                .await
                .map_err(|e| format!("Failed to save transcript: {}", e))?;

            let existing = fetch_all_transcripts(&client, &meeting_id)
                .await
                .map_err(|e| format!("Failed to save transcript: {}", e))?;
            let missing = missing_segments(&segments, &existing);
            if !missing.is_empty() {
                log_warn!(
                    "{} transcript(s) not found on server for meeting {}, inserting",
                    missing.len(),
                    meeting_id
                );
                insert_transcripts(&client, &meeting_id, missing).await?;
            }
            remote_provider::clear_last_session(&meeting_id);
            meeting_id
        }
        None => {
            let meta: ServerMeetingMetadata = client
                .post("/meetings", &serde_json::json!({ "title": meeting_title }))
                .await
                .map_err(|e| format!("Failed to save transcript: {}", e))?;
            insert_transcripts(&client, &meta.id, segments).await?;
            meta.id
        }
    };

    if let Some(folder) = folder_path.as_deref() {
        local_index::set_folder(&app, &meeting_id, folder);
    }

    log_info!("Transcript saved for server meeting {}", meeting_id);
    Ok(serde_json::json!({
        "status": "success",
        "message": "Transcript saved successfully",
        "meeting_id": meeting_id
    }))
}

async fn fetch_all_transcripts(
    client: &ServerClient,
    meeting_id: &str,
) -> Result<Vec<MeetingTranscript>, crate::server::ServerError> {
    const PAGE: i64 = 1000;
    let mut all = Vec::new();
    let mut offset = 0;
    loop {
        let page = fetch_transcripts_page(client, meeting_id, PAGE, offset).await?;
        let n = page.transcripts.len() as i64;
        all.extend(page.transcripts);
        if !page.has_more || n == 0 {
            break;
        }
        offset += n;
    }
    Ok(all)
}

/// Segments with no server transcript at the same recording position
/// (or, for segments without timestamps, the same text).
fn missing_segments(
    segments: &[TranscriptSegment],
    existing: &[MeetingTranscript],
) -> Vec<TranscriptSegment> {
    const TOLERANCE: f64 = 0.05;
    segments
        .iter()
        .filter(|seg| !seg.text.trim().is_empty())
        .filter(|seg| match seg.audio_start_time {
            Some(start) => !existing.iter().any(|t| {
                t.audio_start_time
                    .is_some_and(|s| (s - start).abs() <= TOLERANCE)
            }),
            None => !existing.iter().any(|t| t.text.trim() == seg.text.trim()),
        })
        .cloned()
        .collect()
}

async fn insert_transcripts(
    client: &ServerClient,
    meeting_id: &str,
    segments: Vec<TranscriptSegment>,
) -> Result<(), String> {
    if segments.is_empty() {
        return Ok(());
    }
    let segments: Vec<TranscriptSegment> = segments
        .into_iter()
        .map(|mut s| {
            s.id = uuid::Uuid::new_v4().to_string();
            s
        })
        .collect();
    let resp: serde_json::Value = client
        .post(
            &format!("/meetings/{}/transcripts", encode(meeting_id)),
            &serde_json::json!({ "transcripts": segments }),
        )
        .await
        .map_err(|e| format!("Failed to save transcript: {}", e))?;
    log_debug!("Bulk transcript insert result: {}", resp);
    Ok(())
}

/// Opens the meeting's local recording folder in the system file explorer
#[tauri::command]
pub async fn open_meeting_folder<R: Runtime>(
    app: AppHandle<R>,
    meeting_id: String,
) -> Result<(), String> {
    log_info!("open_meeting_folder called for meeting_id: {}", meeting_id);

    let folder_path = local_index::get_folder(&app, &meeting_id)
        .ok_or_else(|| "Recording folder path not available for this meeting".to_string())?;

    #[cfg(target_os = "macos")]
    let mut cmd = std::process::Command::new("open");
    #[cfg(target_os = "windows")]
    let mut cmd = std::process::Command::new("explorer");
    #[cfg(not(any(target_os = "macos", target_os = "windows")))]
    let mut cmd = std::process::Command::new("xdg-open");

    cmd.arg(&folder_path)
        .spawn()
        .map_err(|e| format!("Failed to open folder: {}", e))?;
    Ok(())
}

#[tauri::command]
pub async fn open_external_url(url: String) -> Result<(), String> {
    use std::process::Command;

    let result = if cfg!(target_os = "windows") {
        Command::new("cmd").args(["/C", "start", &url]).output()
    } else if cfg!(target_os = "macos") {
        Command::new("open").arg(&url).output()
    } else {
        // Linux and other Unix-like systems
        Command::new("xdg-open").arg(&url).output()
    };

    match result {
        Ok(_) => Ok(()),
        Err(e) => Err(format!("Failed to open URL: {}", e)),
    }
}

// ============================================================================
// READ-ONLY COMPATIBILITY SHIMS (models are chosen by the server)
// ============================================================================

#[tauri::command]
pub async fn api_get_model_config<R: Runtime>(
    app: AppHandle<R>,
    _auth_token: Option<String>,
) -> Result<Option<ModelConfig>, String> {
    let caps = server_capabilities(&app).await;
    Ok(Some(ModelConfig {
        provider: "server".to_string(),
        model: caps.as_ref().and_then(|c| c.llm.model.clone()).unwrap_or_default(),
        whisper_model: caps.as_ref().and_then(|c| c.stt.model.clone()).unwrap_or_default(),
        api_key: None,
        ollama_endpoint: None,
    }))
}

#[tauri::command]
pub async fn api_get_transcript_config<R: Runtime>(
    app: AppHandle<R>,
    _auth_token: Option<String>,
) -> Result<Option<TranscriptConfig>, String> {
    let caps = server_capabilities(&app).await;
    Ok(Some(TranscriptConfig {
        provider: "server".to_string(),
        model: caps.and_then(|c| c.stt.model).unwrap_or_default(),
        api_key: None,
    }))
}

async fn server_capabilities<R: Runtime>(
    app: &AppHandle<R>,
) -> Option<crate::server::types::Capabilities> {
    match crate::server::heartbeat::cached_status() {
        Some(s) => s.capabilities,
        None => crate::server::heartbeat::check_now(app).await.capabilities,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn meeting_details_deserialize_from_server_json() {
        let details: MeetingDetails = serde_json::from_str(
            r#"{"id":"meeting-1","title":"周会","created_at":"2026-10-07T03:59:35Z",
                "updated_at":"2026-10-07T04:00:00Z",
                "transcripts":[{"id":"t1","text":"你好","timestamp":"2026-10-07T03:59:40Z",
                                "audio_start_time":1.5,"audio_end_time":3.0,"duration":1.5},
                               {"id":"t2","text":"x","timestamp":"2026-10-07T03:59:41Z"}]}"#,
        )
        .unwrap();
        assert_eq!(details.transcripts.len(), 2);
        assert_eq!(details.transcripts[0].audio_start_time, Some(1.5));
        // Optional timing fields stay omitted when absent (same JSON as before)
        let v = serde_json::to_value(&details.transcripts[1]).unwrap();
        assert!(v.get("audio_start_time").is_none());
    }

    #[test]
    fn meeting_list_and_metadata_deserialize() {
        let list: Vec<Meeting> =
            serde_json::from_str(r#"[{"id":"meeting-1","title":"a"},{"id":"meeting-2","title":"b"}]"#)
                .unwrap();
        assert_eq!(list[1].id, "meeting-2");

        let meta: ServerMeetingMetadata = serde_json::from_str(
            r#"{"id":"meeting-1","title":"a","created_at":"c","updated_at":"u",
                "folder_path":null,"has_audio":true,"audio_duration":12.5}"#,
        )
        .unwrap();
        assert!(meta.has_audio);
        assert_eq!(meta.audio_duration, Some(12.5));

        let page: PaginatedTranscriptsResponse = serde_json::from_str(
            r#"{"transcripts":[],"total_count":0,"has_more":false}"#,
        )
        .unwrap();
        assert!(!page.has_more);
    }

    #[test]
    fn missing_segments_matches_by_audio_start() {
        let seg = |id: &str, text: &str, start: Option<f64>| TranscriptSegment {
            id: id.into(),
            text: text.into(),
            timestamp: "t".into(),
            audio_start_time: start,
            audio_end_time: None,
            duration: None,
        };
        let existing = vec![MeetingTranscript {
            speaker: None,
            confidence: None,
            id: "srv".into(),
            text: "hello".into(),
            timestamp: "t".into(),
            audio_start_time: Some(1.234),
            audio_end_time: Some(2.0),
            duration: Some(0.766),
        }];
        let ui = vec![
            seg("ui-1", "hello", Some(1.2341)),
            seg("ui-2", "world", Some(5.0)),
            seg("ui-3", "hello", None),
            seg("ui-4", "  ", Some(9.0)),
        ];
        let missing = missing_segments(&ui, &existing);
        assert_eq!(missing.len(), 1);
        assert_eq!(missing[0].id, "ui-2");
    }
}
