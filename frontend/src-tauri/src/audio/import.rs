// Audio file import module - imports external audio files as new meetings.
//
// The file is validated locally, then uploaded to the OpenMeeting server as an
// import job (`POST /api/v1/jobs/import`). The server creates the meeting,
// stores the audio, VAD-splits and transcribes it. Only the upload is shown in
// the import dialog; the transcription is followed in the background.

use crate::audio::decoder::decode_audio_file;
use crate::server::jobs::{poll_job, JobOutcome};
use crate::server::ServerClient;
use anyhow::{anyhow, Result};
use log::{debug, error, info, warn};
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tauri::{AppHandle, Emitter, Runtime};
use tauri_plugin_dialog::DialogExt;

use super::constants::AUDIO_EXTENSIONS;

/// Global flag to track if import is in progress
static IMPORT_IN_PROGRESS: AtomicBool = AtomicBool::new(false);

/// Global flag to signal cancellation (shared with the upload stream)
static IMPORT_CANCELLED: once_cell::sync::Lazy<Arc<AtomicBool>> =
    once_cell::sync::Lazy::new(|| Arc::new(AtomicBool::new(false)));

/// RAII guard for IMPORT_IN_PROGRESS flag
/// Ensures flag is cleared even if import panics or returns early
struct ImportGuard;

impl ImportGuard {
    /// Create guard and set flag atomically
    fn acquire() -> Result<Self, String> {
        if IMPORT_IN_PROGRESS
            .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
            .is_err()
        {
            return Err("Import already in progress".to_string());
        }
        Ok(ImportGuard)
    }
}

impl Drop for ImportGuard {
    fn drop(&mut self) {
        IMPORT_IN_PROGRESS.store(false, Ordering::SeqCst);
    }
}

/// Maximum file size: 20GB (prevents OOM and excessive processing time)
const MAX_FILE_SIZE_BYTES: u64 = 20 * 1024 * 1024 * 1024; // 20GB

/// Information about a selected audio file
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AudioFileInfo {
    pub path: String,
    pub filename: String,
    pub duration_seconds: f64,
    pub size_bytes: u64,
    pub format: String,
}

/// Progress update emitted during import
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportProgress {
    pub stage: String, // "uploading"
    pub progress_percentage: u32,
    pub message: String,
}

/// Result of import
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportResult {
    pub meeting_id: String,
    pub title: String,
    pub segments_count: usize,
    pub duration_seconds: f64,
}

/// Error during import
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportError {
    pub error: String,
}

/// Warning emitted during import (non-fatal)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportWarning {
    pub warning: String,
    pub details: Option<String>,
}

/// Response when import is started
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportStarted {
    pub message: String,
}

/// Check if import is currently in progress
pub fn is_import_in_progress() -> bool {
    IMPORT_IN_PROGRESS.load(Ordering::SeqCst)
}

/// Cancel ongoing import
pub fn cancel_import() {
    IMPORT_CANCELLED.store(true, Ordering::SeqCst);
}

/// Validate an audio file and return its info using metadata-only approach
/// Falls back to full decode if metadata is unavailable
pub fn validate_audio_file(path: &Path) -> Result<AudioFileInfo> {
    // Check file exists
    if !path.exists() {
        return Err(anyhow!("File does not exist: {}", path.display()));
    }

    // Check extension
    let extension = path
        .extension()
        .and_then(|e| e.to_str())
        .map(|e| e.to_lowercase())
        .unwrap_or_default();

    if !AUDIO_EXTENSIONS.contains(&extension.as_str()) {
        return Err(anyhow!(
            "Unsupported format: .{}. Supported: {}",
            extension,
            AUDIO_EXTENSIONS.join(", ")
        ));
    }

    // Get file size
    let metadata = std::fs::metadata(path)
        .map_err(|e| anyhow!("Cannot read file: {}", e))?;
    let size_bytes = metadata.len();

    // Check file size limit
    if size_bytes > MAX_FILE_SIZE_BYTES {
        return Err(anyhow!(
            "File too large: {:.2}GB. Maximum supported size is {}GB",
            size_bytes as f64 / (1024.0 * 1024.0 * 1024.0),
            MAX_FILE_SIZE_BYTES / (1024 * 1024 * 1024)
        ));
    }

    // Get filename without extension for title
    let filename = path
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("Imported Audio")
        .to_string();

    // Try fast metadata-only validation first
    let duration_seconds = match extract_duration_from_metadata(path) {
        Ok(duration) => {
            debug!(
                "Got duration from metadata: {:.2}s (fast path)",
                duration
            );
            duration
        }
        Err(e) => {
            // Fallback to full decode if metadata unavailable
            warn!(
                "Metadata extraction failed: {}, falling back to full decode",
                e
            );
            let decoded = decode_audio_file(path)?;
            decoded.duration_seconds
        }
    };

    Ok(AudioFileInfo {
        path: path.to_string_lossy().to_string(),
        filename,
        duration_seconds,
        size_bytes,
        format: extension.to_uppercase(),
    })
}

/// Extract duration from audio file metadata without full decode
/// Returns error if metadata is unavailable, triggering fallback to full decode
fn extract_duration_from_metadata(path: &Path) -> Result<f64> {
    use symphonia::core::formats::FormatOptions;
    use symphonia::core::io::MediaSourceStream;
    use symphonia::core::meta::MetadataOptions;
    use symphonia::core::probe::Hint;

    // Open the file
    let file = std::fs::File::open(path)
        .map_err(|e| anyhow!("Failed to open audio file: {}", e))?;

    let mss = MediaSourceStream::new(Box::new(file), Default::default());

    // Set up format hint based on file extension
    let mut hint = Hint::new();
    if let Some(ext) = path.extension().and_then(|e| e.to_str()) {
        hint.with_extension(ext);
    }

    // Probe the file format (lightweight operation)
    let probed = symphonia::default::get_probe()
        .format(
            &hint,
            mss,
            &FormatOptions::default(),
            &MetadataOptions::default(),
        )
        .map_err(|e| anyhow!("Failed to probe audio format: {}", e))?;

    let format = probed.format;

    // Find the first audio track
    use symphonia::core::codecs::CODEC_TYPE_NULL;
    let track = format
        .tracks()
        .iter()
        .find(|t| t.codec_params.codec != CODEC_TYPE_NULL)
        .ok_or_else(|| anyhow!("No audio track found in file"))?;

    // Extract duration from metadata
    let sample_rate = track
        .codec_params
        .sample_rate
        .ok_or_else(|| anyhow!("Unknown sample rate"))?;

    let n_frames = track
        .codec_params
        .n_frames
        .ok_or_else(|| anyhow!("Frame count not available in metadata"))?;

    let duration_seconds = n_frames as f64 / sample_rate as f64;

    debug!(
        "Extracted metadata: {}Hz, {} frames, {:.2}s",
        sample_rate, n_frames, duration_seconds
    );

    Ok(duration_seconds)
}

/// An import whose upload finished: the server job that transcribes it.
struct UploadedImport {
    client: ServerClient,
    job_id: String,
    meeting_id: String,
    duration_seconds: f64,
}

/// Import an audio file. Only the upload blocks the import dialog: once the server has
/// the file it emits `import-uploaded {meeting_id, title}` and releases the import lock
/// (another file can be imported), then follows the server's transcription in the
/// background and emits `import-complete` or `import-failed`, plus
/// `meeting-sync-finished {meetingId}` for the meeting page.
pub async fn start_import<R: Runtime>(
    app: AppHandle<R>,
    source_path: String,
    title: String,
    language: Option<String>,
) -> Result<ImportResult> {
    let uploaded = {
        // Guard covers the upload only - ensures the flag is cleared even on panic/early return
        let _guard = ImportGuard::acquire().map_err(|e| anyhow!(e))?;
        IMPORT_CANCELLED.store(false, Ordering::SeqCst);
        upload_import(&app, &source_path, &title, language).await
    };
    let uploaded = match uploaded {
        Ok(uploaded) => uploaded,
        Err(e) => {
            let _ = app.emit("import-error", ImportError { error: e.to_string() });
            return Err(e);
        }
    };

    let meeting_id = uploaded.meeting_id.clone();
    crate::audio::recording_commands::mark_meeting_syncing(&meeting_id);
    let _ = app.emit(
        "import-uploaded",
        serde_json::json!({ "meeting_id": meeting_id, "title": title }),
    );

    let result = follow_import_job(&app, &uploaded).await;
    crate::audio::recording_commands::finish_meeting_syncing(&app, &meeting_id);

    match result {
        Ok(segments_count) => {
            info!("Import complete: meeting {} with {} segments", meeting_id, segments_count);
            let result = ImportResult {
                meeting_id,
                title,
                segments_count,
                duration_seconds: uploaded.duration_seconds,
            };
            let _ = app.emit("import-complete", &result);
            Ok(result)
        }
        Err(e) => {
            // The server removes the meeting of a failed import.
            let _ = app.emit(
                "import-failed",
                serde_json::json!({ "meeting_id": meeting_id, "title": title, "error": e.to_string() }),
            );
            Err(e)
        }
    }
}

/// Validate and upload the file as a server import job (`import-progress` 0..100).
async fn upload_import<R: Runtime>(
    app: &AppHandle<R>,
    source_path: &str,
    title: &str,
    language: Option<String>,
) -> Result<UploadedImport> {
    let source = PathBuf::from(source_path);
    // The dialog validated the file when it was picked; only re-check it cheaply here (a full
    // decode for files without duration metadata would delay the upload by seconds).
    let size_bytes = std::fs::metadata(&source)
        .map_err(|e| anyhow!("Cannot read file: {}", e))?
        .len();
    let duration_seconds = extract_duration_from_metadata(&source).unwrap_or(0.0);
    let client = ServerClient::current().map_err(|e| anyhow!(e.to_string()))?;
    let language = crate::audio::transcription::remote_provider::normalize_language(language);

    info!(
        "Uploading '{}' ({} bytes, {:.1}s) to server as import job",
        source.display(),
        size_bytes,
        duration_seconds
    );
    emit_progress(app, "uploading", 0, "正在上传音频文件...");

    let progress_app = app.clone();
    let job = client
        .submit_import_job(
            &source,
            title,
            language.as_deref(),
            move |p| {
                let pct = (p * 100.0).round() as u32;
                emit_progress(&progress_app, "uploading", pct, &format!("正在上传音频文件... {}%", pct));
            },
            Some(IMPORT_CANCELLED.clone()),
        )
        .await
        .map_err(|e| {
            if IMPORT_CANCELLED.load(Ordering::SeqCst) {
                anyhow!("Import cancelled")
            } else {
                anyhow!(e.to_string())
            }
        })?;
    info!("Import job {} submitted (meeting {:?})", job.id, job.meeting_id);

    let meeting_id = job
        .meeting_id
        .clone()
        .ok_or_else(|| anyhow!("服务器未返回会议ID"))?;
    Ok(UploadedImport {
        client,
        job_id: job.id,
        meeting_id,
        duration_seconds,
    })
}

/// Poll the import job until the server has transcribed the file; returns the segment count.
async fn follow_import_job<R: Runtime>(app: &AppHandle<R>, uploaded: &UploadedImport) -> Result<usize> {
    // Once uploaded, the import is no longer cancellable from the client.
    let never_cancelled = AtomicBool::new(false);
    let outcome = poll_job(&uploaded.client, &uploaded.job_id, &never_cancelled, |job| {
        debug!(
            "Import job {}: {} {:.0}% {:?}",
            job.id, job.status, job.progress, job.message
        );
    })
    .await
    .map_err(|e| anyhow!(e))?;

    let job = match outcome {
        JobOutcome::Cancelled => return Err(anyhow!("Import cancelled")),
        JobOutcome::Finished(job) => *job,
    };
    if job.status != "completed" {
        return Err(anyhow!(job
            .error
            .unwrap_or_else(|| "服务器导入任务失败".to_string())));
    }

    let segments_count = job.segments.unwrap_or(0).max(0) as usize;
    if segments_count == 0 {
        let _ = app.emit(
            "import-warning",
            ImportWarning {
                warning: "No speech detected in audio file".to_string(),
                details: Some(
                    "The file was imported successfully, but no speech was transcribed. \
                     The meeting was created but contains no transcripts."
                        .to_string(),
                ),
            },
        );
    }
    Ok(segments_count)
}

fn emit_progress<R: Runtime>(app: &AppHandle<R>, stage: &str, progress: u32, message: &str) {
    let _ = app.emit(
        "import-progress",
        ImportProgress {
            stage: stage.to_string(),
            progress_percentage: progress.min(100),
            message: message.to_string(),
        },
    );
}

// ============================================================================
// Tauri Commands
// ============================================================================

/// Select an audio file and validate it
#[tauri::command]
pub async fn select_and_validate_audio_command<R: Runtime>(
    app: AppHandle<R>,
) -> Result<Option<AudioFileInfo>, String> {
    info!("Opening file dialog for audio import");

    // Use spawn_blocking to avoid blocking async runtime
    let app_clone = app.clone();
    let file_path = tokio::task::spawn_blocking(move || {
        app_clone
            .dialog()
            .file()
            .add_filter("Audio Files", AUDIO_EXTENSIONS)
            .blocking_pick_file()
    })
    .await
    .map_err(|e| format!("File dialog task failed: {}", e))?;

    match file_path {
        Some(path) => {
            let path_str = path.to_string();
            info!("User selected: {}", path_str);

            match validate_audio_file(Path::new(&path_str)) {
                Ok(info) => Ok(Some(info)),
                Err(e) => {
                    error!("Validation failed: {}", e);
                    Err(e.to_string())
                }
            }
        }
        None => {
            info!("User cancelled file selection");
            Ok(None)
        }
    }
}

/// Validate an audio file from a given path (for drag-drop)
#[tauri::command]
pub async fn validate_audio_file_command(path: String) -> Result<AudioFileInfo, String> {
    info!("Validating audio file: {}", path);
    validate_audio_file(Path::new(&path)).map_err(|e| e.to_string())
}

/// Start importing an audio file. `model` / `provider` are accepted for
/// compatibility and ignored: the server's active STT engine is used.
#[tauri::command]
pub async fn start_import_audio_command<R: Runtime>(
    app: AppHandle<R>,
    source_path: String,
    title: String,
    language: Option<String>,
    model: Option<String>,
    provider: Option<String>,
) -> Result<ImportStarted, String> {
    // Check if import is already in progress (guard will be acquired in start_import)
    if IMPORT_IN_PROGRESS.load(Ordering::SeqCst) {
        return Err("Import already in progress".to_string());
    }
    if model.is_some() || provider.is_some() {
        debug!("Ignoring client model/provider for import ({:?}/{:?})", provider, model);
    }

    // Spawn import in background
    tauri::async_runtime::spawn(async move {
        let result = start_import(app, source_path, title, language).await;

        if let Err(e) = result {
            error!("Import failed: {}", e);
        }
    });

    Ok(ImportStarted {
        message: "Import started".to_string(),
    })
}

/// Cancel ongoing import
#[tauri::command]
pub async fn cancel_import_command() -> Result<(), String> {
    if !is_import_in_progress() {
        return Err("No import in progress".to_string());
    }
    cancel_import();
    Ok(())
}

/// Check if import is in progress
#[tauri::command]
pub async fn is_import_in_progress_command() -> bool {
    is_import_in_progress()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_audio_extensions() {
        assert!(AUDIO_EXTENSIONS.contains(&"mp4"));
        assert!(AUDIO_EXTENSIONS.contains(&"wav"));
        assert!(AUDIO_EXTENSIONS.contains(&"mp3"));
        assert!(!AUDIO_EXTENSIONS.contains(&"txt"));
    }

    #[test]
    fn test_cancellation_flag() {
        IMPORT_CANCELLED.store(false, Ordering::SeqCst);
        IMPORT_IN_PROGRESS.store(false, Ordering::SeqCst);

        assert!(!is_import_in_progress());

        cancel_import();
        assert!(IMPORT_CANCELLED.load(Ordering::SeqCst));

        // Reset
        IMPORT_CANCELLED.store(false, Ordering::SeqCst);
    }

    #[test]
    fn test_extract_duration_from_metadata_wav() {
        // Test with sample WAV file if available
        let test_path = Path::new("../../backend/whisper.cpp/samples/jfk.wav");
        if test_path.exists() {
            let result = extract_duration_from_metadata(test_path);
            // Should succeed and return a reasonable duration
            assert!(result.is_ok());
            let duration = result.unwrap();
            assert!(duration > 0.0 && duration < 60.0, "Duration {} seems unreasonable", duration);
        }
    }

    #[test]
    fn test_extract_duration_from_metadata_mp3() {
        // Test with sample MP3 file if available
        let test_path = Path::new("../../backend/whisper.cpp/samples/jfk.mp3");
        if test_path.exists() {
            let result = extract_duration_from_metadata(test_path);
            // MP3 files may not have n_frames metadata, so fallback is expected
            // We just verify it doesn't panic
            let _ = result;
        }
    }

    #[test]
    fn test_validate_audio_file_with_metadata() {
        // Test validation with actual audio file
        let test_path = Path::new("../../backend/whisper.cpp/samples/jfk.wav");
        if test_path.exists() {
            let result = validate_audio_file(test_path);
            assert!(result.is_ok());
            let info = result.unwrap();
            assert_eq!(info.format, "WAV");
            assert!(info.duration_seconds > 0.0);
            assert!(info.size_bytes > 0);
        }
    }

    #[test]
    fn test_validate_audio_file_nonexistent() {
        let result = validate_audio_file(Path::new("/nonexistent/file.mp4"));
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("does not exist"));
    }

    #[test]
    fn test_validate_audio_file_wrong_extension() {
        // Create a temporary file with wrong extension
        let temp_dir = std::env::temp_dir();
        let temp_file = temp_dir.join("test_audio.txt");
        let _ = std::fs::write(&temp_file, b"dummy content");

        let result = validate_audio_file(&temp_file);
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Unsupported format"));

        // Cleanup
        let _ = std::fs::remove_file(temp_file);
    }
}
