// audio/transcription/remote_provider.rs
//
// RemoteProvider: sends VAD speech segments (16 kHz mono f32) to the OpenMeeting
// server as PCM16LE via `POST /meetings/{id}/segments`. The server transcribes
// the segment with its active STT engine AND stores it as a transcript row, so
// live transcripts are persisted server-side as they arrive.
//
// Reliability: each segment is retried with exponential backoff; if it still
// fails it is parked in an in-memory pending queue (never silently dropped)
// and re-sent by `flush_pending` when the recording stops. Segment uploads are
// idempotent on (meeting_id, seq) server-side, so retries never duplicate rows.

use async_trait::async_trait;
use log::{info, warn};
use once_cell::sync::Lazy;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Duration;

use super::provider::{TranscriptResult, TranscriptionError, TranscriptionProvider};
use crate::server::types::{SegmentResult, ServerMeetingMetadata};
use crate::server::{ServerClient, ServerError};

/// Retries after the first attempt (total attempts = 1 + RETRIES).
const RETRIES: u32 = 3;
const BASE_BACKOFF_MS: u64 = 500;

/// Convert f32 samples in [-1, 1] to 16-bit little-endian PCM bytes.
pub fn f32_to_pcm16le(samples: &[f32]) -> Vec<u8> {
    let mut out = Vec::with_capacity(samples.len() * 2);
    for &s in samples {
        let s = if s.is_finite() { s.clamp(-1.0, 1.0) } else { 0.0 };
        let v = (s * i16::MAX as f32).round() as i16;
        out.extend_from_slice(&v.to_le_bytes());
    }
    out
}

/// Map the UI language preference to the server `language` query parameter.
/// "auto" / "auto-translate" / empty → None (server auto-detects).
pub fn normalize_language(pref: Option<String>) -> Option<String> {
    pref.map(|l| l.trim().to_string())
        .filter(|l| !l.is_empty() && l != "auto" && l != "auto-translate")
}

#[derive(Debug, Clone)]
pub struct PendingSegment {
    pub seq: u64,
    pub start: f64,
    pub end: f64,
    pub language: Option<String>,
    pub pcm: Vec<u8>,
}

pub struct RemoteProvider {
    meeting_id: String,
    model_name: Option<String>,
    next_seq: AtomicU64,
    pending: Mutex<Vec<PendingSegment>>,
}

impl RemoteProvider {
    pub fn new(meeting_id: String, model_name: Option<String>) -> Self {
        Self {
            meeting_id,
            model_name,
            next_seq: AtomicU64::new(0),
            pending: Mutex::new(Vec::new()),
        }
    }

    pub fn meeting_id(&self) -> &str {
        &self.meeting_id
    }

    pub fn pending_count(&self) -> usize {
        self.pending.lock().map(|p| p.len()).unwrap_or(0)
    }

    async fn send_with_retry(&self, seg: &PendingSegment) -> Result<SegmentResult, ServerError> {
        let client = ServerClient::current()?;
        let mut attempt = 0;
        loop {
            match client
                .post_segment(
                    &self.meeting_id,
                    seg.seq,
                    seg.start,
                    seg.end,
                    seg.language.as_deref(),
                    seg.pcm.clone(),
                )
                .await
            {
                Ok(r) => return Ok(r),
                Err(e) if e.is_retryable() && attempt < RETRIES => {
                    let backoff = BASE_BACKOFF_MS * (1u64 << attempt);
                    warn!(
                        "Segment seq={} upload failed ({}), retry {}/{} in {}ms",
                        seg.seq, e, attempt + 1, RETRIES, backoff
                    );
                    tokio::time::sleep(Duration::from_millis(backoff)).await;
                    attempt += 1;
                }
                Err(e) => return Err(e),
            }
        }
    }

    /// Re-send all parked segments (in order). Returns the successful results;
    /// segments that still fail stay in the queue.
    pub async fn flush_pending(&self) -> Vec<(PendingSegment, SegmentResult)> {
        let parked: Vec<PendingSegment> = {
            let mut guard = self.pending.lock().unwrap_or_else(|e| e.into_inner());
            std::mem::take(&mut *guard)
        };
        if parked.is_empty() {
            return Vec::new();
        }
        info!("Flushing {} pending segment(s) for meeting {}", parked.len(), self.meeting_id);

        let mut done = Vec::new();
        let mut still_failed = Vec::new();
        for seg in parked {
            match self.send_with_retry(&seg).await {
                Ok(result) => done.push((seg, result)),
                Err(e) => {
                    warn!("Pending segment seq={} still failing: {}", seg.seq, e);
                    still_failed.push(seg);
                }
            }
        }
        if !still_failed.is_empty() {
            let mut guard = self.pending.lock().unwrap_or_else(|e| e.into_inner());
            still_failed.extend(guard.drain(..));
            *guard = still_failed;
        }
        done
    }
}

#[async_trait]
impl TranscriptionProvider for RemoteProvider {
    async fn transcribe(
        &self,
        audio: Vec<f32>,
        language: Option<String>,
    ) -> Result<TranscriptResult, TranscriptionError> {
        let duration = audio.len() as f64 / 16000.0;
        self.transcribe_segment(audio, language, 0.0, duration).await
    }

    async fn transcribe_segment(
        &self,
        audio: Vec<f32>,
        language: Option<String>,
        start: f64,
        end: f64,
    ) -> Result<TranscriptResult, TranscriptionError> {
        if audio.is_empty() {
            return Err(TranscriptionError::AudioTooShort {
                samples: 0,
                minimum: 1600,
            });
        }
        let seg = PendingSegment {
            seq: self.next_seq.fetch_add(1, Ordering::SeqCst),
            start,
            end,
            language: normalize_language(language),
            pcm: f32_to_pcm16le(&audio),
        };

        match self.send_with_retry(&seg).await {
            Ok(result) => Ok(TranscriptResult {
                text: result.text,
                confidence: result.confidence,
                is_partial: false,
            }),
            Err(e) => {
                let recoverable = e.is_retryable()
                    || e.is_auth()
                    || matches!(e, ServerError::NotConfigured);
                if recoverable {
                    let mut guard = self.pending.lock().unwrap_or_else(|p| p.into_inner());
                    guard.push(seg);
                    Err(TranscriptionError::EngineFailed(format!(
                        "{}（语音段已暂存，停止录音时将自动补传，待补传 {} 段）",
                        e,
                        guard.len()
                    )))
                } else {
                    Err(TranscriptionError::EngineFailed(e.to_string()))
                }
            }
        }
    }

    async fn is_model_loaded(&self) -> bool {
        // The server owns the model; segments are queued if it is unavailable.
        true
    }

    async fn get_current_model(&self) -> Option<String> {
        self.model_name.clone()
    }

    fn provider_name(&self) -> &'static str {
        "Server"
    }
}

// ============================================================================
// RECORDING SESSION STATE
// ============================================================================

/// Server meeting of the most recent recording (kept after stop so that
/// `api_save_transcript` can attach to it instead of creating a duplicate).
#[derive(Debug, Clone)]
pub struct RecordingSessionInfo {
    pub meeting_id: String,
    pub title: String,
}

static ACTIVE_PROVIDER: Lazy<Mutex<Option<Arc<RemoteProvider>>>> = Lazy::new(|| Mutex::new(None));
static LAST_SESSION: Lazy<Mutex<Option<RecordingSessionInfo>>> = Lazy::new(|| Mutex::new(None));

/// Create the server meeting for a new recording and install its provider.
pub async fn begin_session(title: &str) -> Result<Arc<RemoteProvider>, String> {
    let client = ServerClient::current().map_err(String::from)?;
    let meeting: ServerMeetingMetadata = client
        .post("/meetings", &serde_json::json!({ "title": title }))
        .await
        .map_err(|e| format!("创建服务器会议失败: {}", e))?;
    info!("Created server meeting {} for recording '{}'", meeting.id, title);

    let model = crate::server::heartbeat::cached_status()
        .and_then(|s| s.capabilities)
        .and_then(|c| c.stt.model);
    let provider = Arc::new(RemoteProvider::new(meeting.id.clone(), model));
    *ACTIVE_PROVIDER.lock().unwrap_or_else(|e| e.into_inner()) = Some(provider.clone());
    *LAST_SESSION.lock().unwrap_or_else(|e| e.into_inner()) = Some(RecordingSessionInfo {
        meeting_id: meeting.id,
        title: title.to_string(),
    });
    Ok(provider)
}

/// Undo `begin_session` after a failed recording start (best-effort delete).
pub async fn abort_session() {
    let provider = ACTIVE_PROVIDER.lock().unwrap_or_else(|e| e.into_inner()).take();
    LAST_SESSION.lock().unwrap_or_else(|e| e.into_inner()).take();
    if let Some(p) = provider {
        if let Ok(client) = ServerClient::current() {
            if let Err(e) = client.delete(&format!("/meetings/{}", p.meeting_id())).await {
                warn!("Failed to delete orphan server meeting {}: {}", p.meeting_id(), e);
            }
        }
    }
}

pub fn active_provider() -> Option<Arc<RemoteProvider>> {
    ACTIVE_PROVIDER.lock().unwrap_or_else(|e| e.into_inner()).clone()
}

/// Detach the provider of the recording that just stopped.
pub fn end_session() -> Option<Arc<RemoteProvider>> {
    ACTIVE_PROVIDER.lock().unwrap_or_else(|e| e.into_inner()).take()
}

pub fn active_meeting_id() -> Option<String> {
    active_provider().map(|p| p.meeting_id().to_string())
}

pub fn last_session() -> Option<RecordingSessionInfo> {
    LAST_SESSION.lock().unwrap_or_else(|e| e.into_inner()).clone()
}

/// Forget the last session once its meeting has been saved by the UI.
pub fn clear_last_session(meeting_id: &str) {
    let mut guard = LAST_SESSION.lock().unwrap_or_else(|e| e.into_inner());
    if guard.as_ref().is_some_and(|s| s.meeting_id == meeting_id) {
        *guard = None;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pcm16_conversion_is_little_endian_and_clamped() {
        let bytes = f32_to_pcm16le(&[0.0, 1.0, -1.0, 0.5, 2.0, -3.0, f32::NAN]);
        let samples: Vec<i16> = bytes
            .chunks_exact(2)
            .map(|c| i16::from_le_bytes([c[0], c[1]]))
            .collect();
        assert_eq!(bytes.len(), 14);
        assert_eq!(samples, vec![0, 32767, -32767, 16384, 32767, -32767, 0]);
        // explicit byte order check: 32767 = 0x7FFF → [0xFF, 0x7F]
        assert_eq!(&bytes[2..4], &[0xFF, 0x7F]);
    }

    #[test]
    fn language_normalisation() {
        assert_eq!(normalize_language(None), None);
        assert_eq!(normalize_language(Some("auto".into())), None);
        assert_eq!(normalize_language(Some("auto-translate".into())), None);
        assert_eq!(normalize_language(Some(" zh ".into())), Some("zh".into()));
    }
}
