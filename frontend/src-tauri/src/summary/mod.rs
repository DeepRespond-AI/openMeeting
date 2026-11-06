/// Summary module - meeting summary commands.
///
/// Summary generation, storage and the LLM choice now live on the OpenMeeting
/// server. This module keeps:
/// - Tauri commands that forward to the server (`commands`)
/// - Local, pure-text helpers (language detection, reasoning-marker cleanup)
///
/// Summary templates are managed and auto-selected on the server; the client never sees them.

pub mod commands;
pub(crate) mod language_detection;
pub(crate) mod text_utils;

// Re-export Tauri commands (with their generated __cmd__ variants)
pub use commands::{
    __cmd__api_cancel_summary, __cmd__api_detect_transcript_summary_language,
    __cmd__api_get_meeting_detected_summary_language, __cmd__api_get_meeting_summary_language,
    __cmd__api_get_summary, __cmd__api_process_transcript,
    __cmd__api_save_meeting_detected_summary_language, __cmd__api_save_meeting_summary,
    __cmd__api_save_meeting_summary_language, __tauri_command_name_api_cancel_summary,
    __tauri_command_name_api_detect_transcript_summary_language,
    __tauri_command_name_api_get_meeting_detected_summary_language,
    __tauri_command_name_api_get_meeting_summary_language,
    __tauri_command_name_api_get_summary, __tauri_command_name_api_process_transcript,
    __tauri_command_name_api_save_meeting_detected_summary_language,
    __tauri_command_name_api_save_meeting_summary,
    __tauri_command_name_api_save_meeting_summary_language, api_cancel_summary,
    api_detect_transcript_summary_language, api_get_meeting_detected_summary_language,
    api_get_meeting_summary_language, api_get_summary, api_process_transcript,
    api_save_meeting_detected_summary_language, api_save_meeting_summary,
    api_save_meeting_summary_language,
};

