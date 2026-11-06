// ui_locale.rs
//
// UI language for native surfaces (window title, tray menu). The webview owns the
// locale choice and pushes it here through `set_ui_locale`.

use std::sync::RwLock;
use tauri::{AppHandle, Manager, Runtime};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UiLocale {
    ZhCn,
    En,
}

static LOCALE: RwLock<UiLocale> = RwLock::new(UiLocale::ZhCn);

pub fn current() -> UiLocale {
    *LOCALE.read().unwrap_or_else(|e| e.into_inner())
}

/// Native UI strings. Keep in sync with the product name in `src/i18n/messages/common.ts`.
pub struct Labels {
    pub app_name: &'static str,
    pub server_not_ready: &'static str,
    pub start_recording: &'static str,
    pub starting_recording: &'static str,
    pub pause_recording: &'static str,
    pub pausing: &'static str,
    pub resume_recording: &'static str,
    pub resuming: &'static str,
    pub stop_recording: &'static str,
    pub stopping: &'static str,
    pub open_main_window: &'static str,
    pub settings: &'static str,
    pub quit: &'static str,
}

const ZH_CN: Labels = Labels {
    app_name: "深应会议",
    server_not_ready: "⚠ 服务器未就绪",
    start_recording: "开始录音",
    starting_recording: "🔄 正在开始录音…",
    pause_recording: "⏸ 暂停录音",
    pausing: "⏸ 正在暂停…",
    resume_recording: "▶ 继续录音",
    resuming: "▶ 正在继续…",
    stop_recording: "⏹ 停止录音",
    stopping: "⏹ 正在停止…",
    open_main_window: "打开主窗口",
    settings: "设置",
    quit: "退出",
};

const EN: Labels = Labels {
    app_name: "DR Meeting",
    server_not_ready: "⚠ Server not ready",
    start_recording: "Start Recording",
    starting_recording: "🔄 Starting Recording...",
    pause_recording: "⏸ Pause Recording",
    pausing: "⏸ Pausing...",
    resume_recording: "▶ Resume Recording",
    resuming: "▶ Resuming...",
    stop_recording: "⏹ Stop Recording",
    stopping: "⏹ Stopping...",
    open_main_window: "Open Main Window",
    settings: "Settings",
    quit: "Quit",
};

pub fn labels() -> &'static Labels {
    match current() {
        UiLocale::ZhCn => &ZH_CN,
        UiLocale::En => &EN,
    }
}

/// Called by the webview on startup and whenever the user switches language.
#[tauri::command]
pub fn set_ui_locale<R: Runtime>(app: AppHandle<R>, locale: String) -> Result<(), String> {
    let next = if locale.to_lowercase().starts_with("zh") { UiLocale::ZhCn } else { UiLocale::En };
    *LOCALE.write().unwrap_or_else(|e| e.into_inner()) = next;

    let l = labels();
    if let Some(window) = app.get_webview_window("main") {
        let title = l.app_name.to_string();
        // Preserve the multi-client development suffix when applying the locale.
        #[cfg(debug_assertions)]
        let title = app.config().app.windows.iter()
            .find(|config| config.label == "main")
            .and_then(|config| config.title.split_once(" · DEV "))
            .map(|(_, suffix)| format!("{} · DEV {}", l.app_name, suffix))
            .unwrap_or(title);
        if let Err(e) = window.set_title(&title) {
            log::warn!("ui_locale: failed to set window title: {}", e);
        }
    }
    if let Some(tray) = app.tray_by_id("main-tray") {
        if let Err(e) = tray.set_tooltip(Some(l.app_name)) {
            log::warn!("ui_locale: failed to set tray tooltip: {}", e);
        }
    }
    crate::tray::update_tray_menu(&app);
    Ok(())
}
