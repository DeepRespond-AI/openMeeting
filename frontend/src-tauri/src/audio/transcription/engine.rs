// audio/transcription/engine.rs
//
// TranscriptionEngine wrapper and readiness validation. Speech recognition is
// performed by the remote OpenMeeting server; the only engine is the RemoteProvider
// bound to the current recording's server meeting.

use super::provider::TranscriptionProvider;
use log::info;
use std::sync::Arc;
use tauri::{AppHandle, Runtime};

// ============================================================================
// TRANSCRIPTION ENGINE
// ============================================================================

pub enum TranscriptionEngine {
    Provider(Arc<dyn TranscriptionProvider>),
}

impl Clone for TranscriptionEngine {
    fn clone(&self) -> Self {
        match self {
            Self::Provider(p) => Self::Provider(p.clone()),
        }
    }
}

impl TranscriptionEngine {
    pub async fn is_model_loaded(&self) -> bool {
        match self {
            Self::Provider(provider) => provider.is_model_loaded().await,
        }
    }

    pub async fn get_current_model(&self) -> Option<String> {
        match self {
            Self::Provider(provider) => provider.get_current_model().await,
        }
    }

    pub fn provider_name(&self) -> &str {
        match self {
            Self::Provider(provider) => provider.provider_name(),
        }
    }
}

// ============================================================================
// VALIDATION AND INITIALIZATION
// ============================================================================

/// Validate that the server is reachable, the user is logged in and the server's
/// STT engine is ready before starting a recording.
pub async fn validate_transcription_model_ready<R: Runtime>(app: &AppHandle<R>) -> Result<(), String> {
    let status = crate::server::heartbeat::check_now(app).await;

    if !status.configured {
        return Err("未配置服务器，请先在设置中填写服务器地址".to_string());
    }
    if !status.logged_in {
        return Err(crate::server::ServerError::NotLoggedIn.to_string());
    }
    if !status.connected || !status.authenticated {
        return Err(status
            .error
            .unwrap_or_else(|| "无法连接服务器".to_string()));
    }
    let stt = status.capabilities.map(|c| c.stt).unwrap_or_default();
    if !stt.ready {
        return Err(match stt.error {
            Some(err) if !err.is_empty() => format!("服务器语音识别模型未就绪: {}", err),
            _ => "服务器语音识别模型未就绪，请联系管理员在管理端加载 STT 模型".to_string(),
        });
    }

    info!(
        "✅ Server STT ready: engine={:?}, model={:?}",
        stt.engine, stt.model
    );
    Ok(())
}

/// Get the transcription engine for the active recording session.
pub async fn get_or_init_transcription_engine<R: Runtime>(
    _app: &AppHandle<R>,
) -> Result<TranscriptionEngine, String> {
    match super::remote_provider::active_provider() {
        Some(provider) => {
            info!("🌐 Using server transcription for meeting {}", provider.meeting_id());
            Ok(TranscriptionEngine::Provider(provider))
        }
        None => Err("没有进行中的服务器会议，无法开始转写".to_string()),
    }
}
