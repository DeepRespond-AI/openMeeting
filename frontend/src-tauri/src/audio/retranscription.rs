// Retranscription module - re-process a meeting's stored audio on the server.
//
// Submits `POST /api/v1/jobs/retranscribe` (the server replaces all transcripts
// of the meeting using its stored audio), polls the job and translates it into
// the existing `retranscription-*` events. If the server has no audio for the
// meeting yet but a local recording exists, it is uploaded first.

use crate::server::jobs::{poll_job, JobOutcome};
use crate::server::types::{Job, ServerMeetingMetadata};
use crate::server::ServerClient;
use anyhow::{anyhow, Result};
use log::{debug, error, info};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use tauri::{AppHandle, Emitter, Runtime};

/// Global flag to track if retranscription is in progress
static RETRANSCRIPTION_IN_PROGRESS: AtomicBool = AtomicBool::new(false);

/// Global flag to signal cancellation
static RETRANSCRIPTION_CANCELLED: AtomicBool = AtomicBool::new(false);

/// Share of the progress bar used by an (optional) audio upload.
const UPLOAD_PROGRESS_SHARE: f64 = 20.0;

/// RAII guard for RETRANSCRIPTION_IN_PROGRESS flag
/// Ensures flag is cleared even if retranscription panics or returns early
struct RetranscriptionGuard;

impl RetranscriptionGuard {
    /// Create guard and set flag atomically
    fn acquire() -> Result<Self, String> {
        if RETRANSCRIPTION_IN_PROGRESS
            .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
            .is_err()
        {
            return Err("Retranscription already in progress".to_string());
        }
        Ok(RetranscriptionGuard)
    }
}

impl Drop for RetranscriptionGuard {
    fn drop(&mut self) {
        RETRANSCRIPTION_IN_PROGRESS.store(false, Ordering::SeqCst);
    }
}

/// Progress update emitted during retranscription
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RetranscriptionProgress {
    pub meeting_id: String,
    pub stage: String, // "uploading", "queued", "transcribing", "saving", "complete"
    pub progress_percentage: u32,
    pub message: String,
}

/// Result of retranscription
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RetranscriptionResult {
    pub meeting_id: String,
    pub segments_count: usize,
    pub duration_seconds: f64,
    pub language: Option<String>,
}

/// Error during retranscription
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RetranscriptionError {
    pub meeting_id: String,
    pub error: String,
}

/// Check if retranscription is currently in progress
pub fn is_retranscription_in_progress() -> bool {
    RETRANSCRIPTION_IN_PROGRESS.load(Ordering::SeqCst)
}

/// Cancel ongoing retranscription
pub fn cancel_retranscription() {
    RETRANSCRIPTION_CANCELLED.store(true, Ordering::SeqCst);
}

/// Start retranscription of a meeting's audio (runs to completion, emitting events)
pub async fn start_retranscription<R: Runtime>(
    app: AppHandle<R>,
    meeting_id: String,
    meeting_folder_path: String,
    language: Option<String>,
) -> Result<RetranscriptionResult> {
    // Acquire guard - ensures flag is cleared even on panic/early return
    let _guard = RetranscriptionGuard::acquire().map_err(|e| anyhow!(e))?;

    // Reset cancellation flag
    RETRANSCRIPTION_CANCELLED.store(false, Ordering::SeqCst);

    let result =
        run_retranscription(app.clone(), meeting_id.clone(), meeting_folder_path, language).await;

    match &result {
        Ok(res) => {
            let _ = app.emit(
                "retranscription-complete",
                serde_json::json!({
                    "meeting_id": res.meeting_id,
                    "segments_count": res.segments_count,
                    "duration_seconds": res.duration_seconds,
                    "language": res.language
                }),
            );
        }
        Err(e) => {
            let _ = app.emit(
                "retranscription-error",
                RetranscriptionError {
                    meeting_id: meeting_id.clone(),
                    error: e.to_string(),
                },
            );
        }
    }

    result
}

/// Upload the local recording if the server does not have audio for the meeting.
async fn ensure_server_audio<R: Runtime>(
    app: &AppHandle<R>,
    client: &ServerClient,
    meeting_id: &str,
    meeting_folder_path: &str,
    metadata: &ServerMeetingMetadata,
) -> Result<()> {
    if metadata.has_audio {
        return Ok(());
    }

    let folder = if meeting_folder_path.trim().is_empty() {
        crate::server::local_index::get_folder(app, meeting_id)
    } else {
        Some(meeting_folder_path.to_string())
    };
    let audio_path = folder
        .map(PathBuf::from)
        .and_then(|f| super::common::find_audio_file(&f).ok())
        .ok_or_else(|| anyhow!("服务器上没有该会议的音频，且本地未找到录音文件，无法重新转写"))?;

    info!(
        "Server has no audio for {}, uploading local recording {}",
        meeting_id,
        audio_path.display()
    );
    emit_progress(app, meeting_id, "uploading", 0, "正在上传本地录音...");
    let progress_app = app.clone();
    let progress_id = meeting_id.to_string();
    client
        .upload_meeting_audio(meeting_id, &audio_path, metadata.audio_duration, move |p| {
            emit_progress(
                &progress_app,
                &progress_id,
                "uploading",
                (p * UPLOAD_PROGRESS_SHARE).round() as u32,
                &format!("正在上传本地录音... {:.0}%", p * 100.0),
            );
        })
        .await
        .map_err(|e| anyhow!(e.to_string()))?;
    Ok(())
}

/// Internal function to run retranscription as a server job
async fn run_retranscription<R: Runtime>(
    app: AppHandle<R>,
    meeting_id: String,
    meeting_folder_path: String,
    language: Option<String>,
) -> Result<RetranscriptionResult> {
    let client = ServerClient::current().map_err(|e| anyhow!(e.to_string()))?;
    let language = crate::audio::transcription::remote_provider::normalize_language(language);

    let metadata: ServerMeetingMetadata = client
        .get(&format!("/meetings/{}/metadata", meeting_id))
        .await
        .map_err(|e| anyhow!(e.to_string()))?;

    ensure_server_audio(&app, &client, &meeting_id, &meeting_folder_path, &metadata).await?;

    if RETRANSCRIPTION_CANCELLED.load(Ordering::SeqCst) {
        return Err(anyhow!("Retranscription cancelled"));
    }

    emit_progress(&app, &meeting_id, "queued", UPLOAD_PROGRESS_SHARE as u32, "正在提交重新转写任务...");
    let job: Job = client
        .post(
            "/jobs/retranscribe",
            &serde_json::json!({ "meeting_id": meeting_id, "language": language }),
        )
        .await
        .map_err(|e| anyhow!(e.to_string()))?;
    info!("Retranscription job {} submitted for meeting {}", job.id, meeting_id);

    let outcome = poll_job(&client, &job.id, &RETRANSCRIPTION_CANCELLED, |job| {
        let pct = UPLOAD_PROGRESS_SHARE
            + job.progress.clamp(0.0, 100.0) * (100.0 - UPLOAD_PROGRESS_SHARE) / 100.0;
        let stage = match job.status.as_str() {
            "queued" => "queued",
            "completed" => "saving",
            _ => "transcribing",
        };
        let message = job
            .message
            .clone()
            .unwrap_or_else(|| "服务器正在重新转写...".to_string());
        emit_progress(&app, &meeting_id, stage, pct.round() as u32, &message);
    })
    .await
    .map_err(|e| anyhow!(e))?;

    let job = match outcome {
        JobOutcome::Cancelled => return Err(anyhow!("Retranscription cancelled")),
        JobOutcome::Finished(job) => *job,
    };
    if job.status != "completed" {
        return Err(anyhow!(job
            .error
            .unwrap_or_else(|| "服务器重新转写任务失败".to_string())));
    }

    // Refresh duration (the server computes it via ffprobe when audio is stored)
    let duration_seconds = match client
        .get::<ServerMeetingMetadata>(&format!("/meetings/{}/metadata", meeting_id))
        .await
    {
        Ok(m) => m.audio_duration.unwrap_or(0.0),
        Err(_) => metadata.audio_duration.unwrap_or(0.0),
    };

    emit_progress(&app, &meeting_id, "complete", 100, "重新转写完成");

    Ok(RetranscriptionResult {
        meeting_id,
        segments_count: job.segments.unwrap_or(0).max(0) as usize,
        duration_seconds,
        language,
    })
}

fn emit_progress<R: Runtime>(
    app: &AppHandle<R>,
    meeting_id: &str,
    stage: &str,
    progress: u32,
    message: &str,
) {
    let _ = app.emit(
        "retranscription-progress",
        RetranscriptionProgress {
            meeting_id: meeting_id.to_string(),
            stage: stage.to_string(),
            progress_percentage: progress.min(100),
            message: message.to_string(),
        },
    );
}

// Tauri commands

/// Response when retranscription is started
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RetranscriptionStarted {
    pub meeting_id: String,
    pub message: String,
}

/// Start retranscription. `meeting_folder_path` may be empty for server-only
/// meetings. `model` / `provider` are accepted for compatibility and ignored:
/// the server's active STT engine is used.
#[tauri::command]
pub async fn start_retranscription_command<R: Runtime>(
    app: AppHandle<R>,
    meeting_id: String,
    meeting_folder_path: Option<String>,
    language: Option<String>,
    model: Option<String>,
    provider: Option<String>,
) -> Result<RetranscriptionStarted, String> {
    // Check if retranscription is already in progress (guard will be acquired in start_retranscription)
    if RETRANSCRIPTION_IN_PROGRESS.load(Ordering::SeqCst) {
        return Err("Retranscription already in progress".to_string());
    }
    if model.is_some() || provider.is_some() {
        debug!("Ignoring client model/provider for retranscription ({:?}/{:?})", provider, model);
    }

    let meeting_id_clone = meeting_id.clone();
    tauri::async_runtime::spawn(async move {
        let result = start_retranscription(
            app,
            meeting_id_clone,
            meeting_folder_path.unwrap_or_default(),
            language,
        )
        .await;

        // Errors are already emitted as events in start_retranscription
        if let Err(e) = result {
            error!("Retranscription failed: {}", e);
        }
    });

    Ok(RetranscriptionStarted {
        meeting_id,
        message: "Retranscription started".to_string(),
    })
}

#[tauri::command]
pub async fn cancel_retranscription_command() -> Result<(), String> {
    if !is_retranscription_in_progress() {
        return Err("No retranscription in progress".to_string());
    }
    cancel_retranscription();
    Ok(())
}

#[tauri::command]
pub async fn is_retranscription_in_progress_command() -> bool {
    is_retranscription_in_progress()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_retranscription_cancel_flag() {
        RETRANSCRIPTION_CANCELLED.store(false, Ordering::SeqCst);
        cancel_retranscription();
        assert!(RETRANSCRIPTION_CANCELLED.load(Ordering::SeqCst));
        RETRANSCRIPTION_CANCELLED.store(false, Ordering::SeqCst);
    }

    #[test]
    fn progress_payload_shape() {
        let v = serde_json::to_value(RetranscriptionProgress {
            meeting_id: "m".into(),
            stage: "transcribing".into(),
            progress_percentage: 50,
            message: "x".into(),
        })
        .unwrap();
        assert_eq!(v["meeting_id"], "m");
        assert_eq!(v["progress_percentage"], 50);
    }
}
