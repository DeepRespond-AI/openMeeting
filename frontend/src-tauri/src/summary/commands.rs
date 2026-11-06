// summary/commands.rs
//
// Summary commands. Summaries are generated, stored and cancelled on the
// OpenMeeting server (which also chooses the LLM); these commands keep their
// original names / arguments / return shapes and forward to `/api/v1`.

use crate::server::types::SummaryLanguageInfo;
use crate::server::{ServerClient, ServerError};
use crate::summary::language_detection::{detect_summary_language, SummaryLanguageDetection};
use crate::summary::text_utils::{clean_llm_markdown_detailed, contains_reasoning_marker};
use log::{info as log_info, warn as log_warn};
use serde::{Deserialize, Serialize};
use tauri::{AppHandle, Runtime};

#[derive(Debug, Serialize, Deserialize)]
pub struct SummaryResponse {
    pub status: String,
    #[serde(rename = "meetingName")]
    pub meeting_name: Option<String>,
    pub meeting_id: String,
    pub start: Option<String>,
    pub end: Option<String>,
    pub data: Option<serde_json::Value>,
    pub error: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ProcessTranscriptResponse {
    pub message: String,
    pub process_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum SummaryLanguageStorage {
    Metadata,
    LocalFallback,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct MeetingSummaryLanguagePreference {
    pub language: Option<String>,
    pub storage: SummaryLanguageStorage,
}

impl MeetingSummaryLanguagePreference {
    /// Server-persisted per-meeting value (reported as "metadata" storage so the
    /// UI treats it as durable, exactly like the old metadata.json storage).
    fn metadata(language: Option<String>) -> Self {
        Self {
            language,
            storage: SummaryLanguageStorage::Metadata,
        }
    }
}

fn client() -> Result<ServerClient, String> {
    ServerClient::current().map_err(String::from)
}

fn summary_path(meeting_id: &str) -> String {
    format!(
        "/meetings/{}/summary",
        url::form_urlencoded::byte_serialize(meeting_id.as_bytes()).collect::<String>()
    )
}

fn summary_language_path(meeting_id: &str) -> String {
    format!("{}-language", summary_path(meeting_id))
}

fn non_empty(value: Option<String>) -> Option<String> {
    value.and_then(|s| {
        let t = s.trim();
        if t.is_empty() {
            None
        } else {
            Some(t.to_string())
        }
    })
}

/// Saves a manually edited meeting summary.
///
/// Expected format: { "markdown": "...", "summary_json": [...BlockNote blocks...] }
#[tauri::command]
pub async fn api_save_meeting_summary<R: Runtime>(
    _app: AppHandle<R>,
    meeting_id: String,
    summary: serde_json::Value,
    _auth_token: Option<String>,
) -> Result<serde_json::Value, String> {
    log_info!("api_save_meeting_summary called for meeting_id: {}", meeting_id);
    if !summary_is_renderable(&summary) {
        return Err("Summary contains no visible content or model reasoning markers and was not saved.".into());
    }
    client()?
        .put_no_content(&summary_path(&meeting_id), &serde_json::json!({ "summary": summary }))
        .await
        .map_err(String::from)?;
    Ok(serde_json::json!({
        "message": "Meeting summary saved successfully"
    }))
}

async fn get_summary_language(meeting_id: &str) -> Result<SummaryLanguageInfo, String> {
    client()?
        .get(&summary_language_path(meeting_id))
        .await
        .map_err(String::from)
}

async fn put_summary_language(
    meeting_id: &str,
    body: serde_json::Value,
) -> Result<SummaryLanguageInfo, String> {
    client()?
        .put(&summary_language_path(meeting_id), &body)
        .await
        .map_err(String::from)
}

/// Gets the per-meeting summary language override.
#[tauri::command]
pub async fn api_get_meeting_summary_language<R: Runtime>(
    _app: AppHandle<R>,
    meeting_id: String,
) -> Result<MeetingSummaryLanguagePreference, String> {
    log_info!("api_get_meeting_summary_language called for meeting_id: {}", meeting_id);
    let info = get_summary_language(&meeting_id).await?;
    Ok(MeetingSummaryLanguagePreference::metadata(info.language))
}

/// Saves or clears the per-meeting summary language override.
#[tauri::command]
pub async fn api_save_meeting_summary_language<R: Runtime>(
    _app: AppHandle<R>,
    meeting_id: String,
    summary_language: Option<String>,
) -> Result<MeetingSummaryLanguagePreference, String> {
    log_info!(
        "api_save_meeting_summary_language called for meeting_id: {}, language: {:?}",
        meeting_id,
        summary_language
    );
    let info = put_summary_language(
        &meeting_id,
        serde_json::json!({ "language": non_empty(summary_language) }),
    )
    .await?;
    Ok(MeetingSummaryLanguagePreference::metadata(info.language))
}

/// Gets the cached Auto-detected summary language.
#[tauri::command]
pub async fn api_get_meeting_detected_summary_language<R: Runtime>(
    _app: AppHandle<R>,
    meeting_id: String,
) -> Result<MeetingSummaryLanguagePreference, String> {
    log_info!(
        "api_get_meeting_detected_summary_language called for meeting_id: {}",
        meeting_id
    );
    let info = get_summary_language(&meeting_id).await?;
    Ok(MeetingSummaryLanguagePreference::metadata(info.detected_language))
}

/// Saves or clears the cached Auto-detected summary language.
#[tauri::command]
pub async fn api_save_meeting_detected_summary_language<R: Runtime>(
    _app: AppHandle<R>,
    meeting_id: String,
    detected_summary_language: Option<String>,
) -> Result<MeetingSummaryLanguagePreference, String> {
    log_info!(
        "api_save_meeting_detected_summary_language called for meeting_id: {}, language: {:?}",
        meeting_id,
        detected_summary_language
    );
    let info = put_summary_language(
        &meeting_id,
        serde_json::json!({ "detected_language": non_empty(detected_summary_language) }),
    )
    .await?;
    Ok(MeetingSummaryLanguagePreference::metadata(info.detected_language))
}

/// Detects the dominant supported summary language from transcript segments
/// (pure local text analysis).
#[tauri::command]
pub async fn api_detect_transcript_summary_language(
    transcript_texts: Vec<String>,
) -> Result<SummaryLanguageDetection, String> {
    Ok(detect_summary_language(&transcript_texts))
}

fn blocknote_has_visible_text(value: &serde_json::Value) -> bool {
    match value {
        serde_json::Value::Array(items) => items.iter().any(blocknote_has_visible_text),
        serde_json::Value::Object(object) => {
            object
                .get("text")
                .and_then(serde_json::Value::as_str)
                .is_some_and(|text| !text.trim().is_empty())
                || object
                    .get("content")
                    .is_some_and(blocknote_has_visible_text)
                || object
                    .get("children")
                    .is_some_and(blocknote_has_visible_text)
        }
        _ => false,
    }
}

fn legacy_section_has_visible_text(value: &serde_json::Value) -> bool {
    value
        .get("blocks")
        .and_then(serde_json::Value::as_array)
        .is_some_and(|blocks| {
            blocks.iter().any(|block| {
                block
                    .get("content")
                    .and_then(serde_json::Value::as_str)
                    .is_some_and(|content| !content.trim().is_empty())
            })
        })
}

fn summary_contains_reasoning_marker(value: &serde_json::Value) -> bool {
    match value {
        serde_json::Value::Array(items) => items.iter().any(summary_contains_reasoning_marker),
        serde_json::Value::Object(object) => object.iter().any(|(key, value)| match key.as_str() {
            "markdown" | "text" | "content" => value
                .as_str()
                .is_some_and(contains_reasoning_marker)
                || value.is_array() && summary_contains_reasoning_marker(value),
            "summary_json" | "children" => summary_contains_reasoning_marker(value),
            _ => false,
        }),
        _ => false,
    }
}

fn summary_is_renderable(value: &serde_json::Value) -> bool {
    let Some(object) = value.as_object() else {
        return false;
    };
    if summary_contains_reasoning_marker(value) {
        return false;
    }
    if let Some(markdown) = object.get("markdown") {
        return markdown
            .as_str()
            .is_some_and(|markdown| !clean_llm_markdown_detailed(markdown).markdown.is_empty());
    }
    if let Some(blocks) = object.get("summary_json") {
        return blocknote_has_visible_text(blocks);
    }
    object
        .iter()
        .filter(|(key, _)| !matches!(key.as_str(), "MeetingName" | "_section_order"))
        .any(|(_, value)| legacy_section_has_visible_text(value))
}

fn sanitize_markdown_value(value: Option<&mut serde_json::Value>) -> bool {
    let Some(serde_json::Value::String(markdown)) = value else {
        return false;
    };
    let cleaned = clean_llm_markdown_detailed(markdown);
    let reasoning_stripped = cleaned.reasoning_stripped;
    *markdown = cleaned.markdown;
    reasoning_stripped
}

fn redact_flagged_reasoning(mut result: serde_json::Value) -> serde_json::Value {
    let Some(object) = result.as_object_mut() else {
        return result;
    };
    let mut reasoning_stripped = object
        .get("reasoning_stripped")
        .and_then(serde_json::Value::as_bool)
        == Some(true);
    if reasoning_stripped {
        object.remove("reasoning");
    }
    reasoning_stripped |= sanitize_markdown_value(object.get_mut("markdown"));
    if let Some(cache) = object
        .get_mut("english_cache")
        .and_then(serde_json::Value::as_object_mut)
    {
        reasoning_stripped |= sanitize_markdown_value(cache.get_mut("markdown"));
    }
    if reasoning_stripped {
        object.insert("reasoning_stripped".to_string(), serde_json::Value::Bool(true));
    }
    result
}

/// Gets summary status and data from the server.
#[tauri::command]
pub async fn api_get_summary<R: Runtime>(
    _app: AppHandle<R>,
    meeting_id: String,
    _auth_token: Option<String>,
) -> Result<SummaryResponse, String> {
    log_info!("api_get_summary called for meeting_id: {}", meeting_id);
    let mut response: SummaryResponse = client()?
        .get(&summary_path(&meeting_id))
        .await
        .map_err(|e| format!("Failed to retrieve summary: {}", e))?;
    // Defensive: never surface flagged model reasoning (idempotent if the server already did).
    response.data = response.data.map(redact_flagged_reasoning);
    Ok(response)
}

/// Starts server-side summary generation. `model` / `model_name` / chunking
/// arguments are accepted for compatibility and ignored: the server picks the LLM.
#[tauri::command]
#[allow(clippy::too_many_arguments)]
pub async fn api_process_transcript<R: Runtime>(
    _app: AppHandle<R>,
    text: String,
    model: String,
    model_name: String,
    meeting_id: Option<String>,
    _chunk_size: Option<i32>,
    _overlap: Option<i32>,
    custom_prompt: Option<String>,
    summary_language: Option<String>,
    _auth_token: Option<String>,
) -> Result<ProcessTranscriptResponse, String> {
    let meeting_id = meeting_id
        .filter(|m| !m.trim().is_empty())
        .ok_or_else(|| "缺少会议ID，无法生成总结".to_string())?;
    log_info!(
        "api_process_transcript called for meeting_id: {} (client model '{}'/'{}' ignored)",
        meeting_id,
        model,
        model_name
    );

    let text = if text.trim().is_empty() { None } else { Some(text) };
    client()?
        .post(
            &summary_path(&meeting_id),
            &serde_json::json!({
                "custom_prompt": non_empty(custom_prompt),
                "language": non_empty(summary_language),
                "text": text,
            }),
        )
        .await
        .map_err(String::from)
}

/// Cancels an ongoing summary generation on the server.
#[tauri::command]
pub async fn api_cancel_summary<R: Runtime>(
    _app: AppHandle<R>,
    meeting_id: String,
    process_id: String,
) -> Result<serde_json::Value, String> {
    log_info!(
        "api_cancel_summary called for meeting_id: {} (process {})",
        meeting_id,
        process_id
    );
    let cancelled = match client()?.delete(&summary_path(&meeting_id)).await {
        Ok(()) => true,
        Err(ServerError::NotFound(_)) | Err(ServerError::Http { status: 409, .. }) => false,
        Err(e) => {
            log_warn!("Failed to cancel summary for {}: {}", meeting_id, e);
            return Err(format!("Failed to update cancellation status: {}", e));
        }
    };

    Ok(serde_json::json!({
        "cancelled": cancelled,
        "message": if cancelled {
            "Summary generation cancelled successfully"
        } else {
            "No active summary generation to cancel"
        },
        "meeting_id": meeting_id,
    }))
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn redacts_only_flagged_historical_reasoning() {
        assert_eq!(
            redact_flagged_reasoning(json!({
                "reasoning_stripped": true,

                "reasoning": "private",
                "markdown": "visible",
            })),
            json!({"reasoning_stripped": true, "markdown": "visible"})
        );
        assert_eq!(
            redact_flagged_reasoning(json!({"reasoning": "custom", "markdown": "visible"})),
            json!({"reasoning": "custom", "markdown": "visible"})
        );
    }

    #[test]
    fn summary_validation_rejects_blank_and_reasoning_content() {
        assert!(!summary_is_renderable(&json!({"markdown": "   "})));
        assert!(!summary_is_renderable(&json!({"markdown": "```\r\n```"})));
        assert!(!summary_is_renderable(&json!({
            "summary_json": [{"content": [{"type": "text", "text": "<think>private</think>"}]}]
        })));
        assert!(summary_is_renderable(&json!({
            "summary_json": [{"content": [{"type": "text", "text": "Visible"}]}]
        })));
    }

    #[test]
    fn response_redaction_strips_closed_markdown_envelopes() {
        let redacted = redact_flagged_reasoning(json!({
            "markdown": "Visible\n<think>private</think>\nTail"
        }));
        assert_eq!(redacted["markdown"], "Visible\n\nTail");
        assert_eq!(redacted["reasoning_stripped"], true);
    }

    #[test]
    fn summary_response_deserializes_from_server_json() {
        let resp: SummaryResponse = serde_json::from_str(
            r##"{"status":"completed","meetingName":"周会","meeting_id":"meeting-1",
                "start":"2026-10-07T03:59:35.000000000Z","end":"2026-10-07T04:00:35+00:00",
                "data":{"markdown":"# 纪要"},"error":null}"##,
        )
        .unwrap();
        assert_eq!(resp.status, "completed");
        assert_eq!(resp.meeting_name.as_deref(), Some("周会"));
        let v = serde_json::to_value(&resp).unwrap();
        assert_eq!(v["meetingName"], "周会");
        assert_eq!(v["data"]["markdown"], "# 纪要");
        assert!(v.get("error").unwrap().is_null());

        let idle: SummaryResponse = serde_json::from_str(
            r#"{"status":"idle","meetingName":null,"meeting_id":"m","start":null,"end":null,"data":null,"error":null}"#,
        )
        .unwrap();
        assert!(idle.data.is_none());
    }

    #[test]
    fn summary_language_preference_shape() {
        let v = serde_json::to_value(MeetingSummaryLanguagePreference::metadata(Some("zh".into()))).unwrap();
        assert_eq!(v, json!({"language": "zh", "storage": "metadata"}));
    }
}
