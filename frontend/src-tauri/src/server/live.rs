//! Phase 1 live-meeting REST commands and authenticated, reconnecting signaling.
use super::client::{extract_detail, ServerClient, ServerError};
use futures_util::{SinkExt, StreamExt};
use reqwest::{Method, RequestBuilder};
use serde::Serialize;
use serde_json::{json, Value};
use std::{sync::Arc, time::Duration};
use tauri::{AppHandle, Emitter, Runtime, State};
use tokio::sync::Mutex;
use tokio_tungstenite::{
    connect_async,
    tungstenite::{client::IntoClientRequest, Message},
};
use tokio_util::sync::CancellationToken;

#[derive(Debug, Serialize)]
pub struct LiveError {
    status: u16,
    detail: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    code: Option<String>,
}
impl From<ServerError> for LiveError {
    fn from(error: ServerError) -> Self {
        Self {
            status: error.status().unwrap_or(0),
            detail: error.to_string(),
            code: None,
        }
    }
}
type Reply = Result<Value, LiveError>;

fn client() -> Result<ServerClient, LiveError> {
    ServerClient::current().map_err(Into::into)
}
fn id(value: &str) -> Result<&str, LiveError> {
    if !value.is_empty()
        && value
            .bytes()
            .all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'_')
    {
        Ok(value)
    } else {
        Err(LiveError {
            status: 422,
            detail: "输入格式不正确".into(),
            code: None,
        })
    }
}
fn body(mut value: Value) -> Value {
    // Optional Tauri args arrive as None; omit them so server defaults apply.
    // In particular, never send null booleans to Pydantic or overwrite patch fields.
    if let Some(map) = value.as_object_mut() {
        map.retain(|_, v| !v.is_null());
    }
    value
}
async fn send(c: &ServerClient, request: RequestBuilder) -> Reply {
    let response = request
        .send()
        .await
        .map_err(|e| LiveError::from(ServerError::Connect(e.to_string())))?;
    let status = response.status();
    if status.as_u16() == 401 {
        c.notify_unauthorized();
    }
    let text = response
        .text()
        .await
        .map_err(|e| LiveError::from(ServerError::Other(e.to_string())))?;
    if !status.is_success() {
        let code = serde_json::from_str::<Value>(&text)
            .ok()
            .and_then(|v| v.get("code").and_then(Value::as_str).map(str::to_owned));
        return Err(LiveError {
            status: status.as_u16(),
            detail: extract_detail(&text, status),
            code,
        });
    }
    if text.trim().is_empty() {
        return Ok(Value::Null);
    }
    serde_json::from_str(&text)
        .map_err(|_| LiveError::from(ServerError::Other("服务器响应解析失败".into())))
}
async fn call(method: Method, path: &str, payload: Option<Value>) -> Reply {
    let c = client()?;
    let mut request = c.request(method, path);
    if let Some(payload) = payload {
        request = request.json(&body(payload));
    }
    send(&c, request).await
}

#[tauri::command]
pub async fn sched_list(from: Option<String>, to: Option<String>) -> Reply {
    let c = client()?;
    let mut query = Vec::new();
    if let Some(from) = from {
        query.push(("from", from));
    }
    if let Some(to) = to {
        query.push(("to", to));
    }
    send(
        &c,
        c.request(Method::GET, "/scheduled-meetings").query(&query),
    )
    .await
}
#[tauri::command]
pub async fn sched_create(
    start_at: String,
    duration_min: i64,
    title: Option<String>,
    pwd_enabled: Option<bool>,
    pwd: Option<String>,
    remind: Option<bool>,
    wait_room: Option<bool>,
) -> Reply {
    call(Method::POST, "/scheduled-meetings", Some(json!({"title":title,"startAt":start_at,"durationMin":duration_min,"pwdEnabled":pwd_enabled,"pwd":pwd,"remind":remind,"waitRoom":wait_room}))).await
}
#[tauri::command]
pub async fn sched_get(id: String) -> Reply {
    call(
        Method::GET,
        &format!("/scheduled-meetings/{}", self::id(&id)?),
        None,
    )
    .await
}
#[tauri::command]
pub async fn sched_update(
    id: String,
    start_at: String,
    duration_min: i64,
    title: Option<String>,
    pwd_enabled: Option<bool>,
    pwd: Option<String>,
    remind: Option<bool>,
    wait_room: Option<bool>,
) -> Reply {
    call(
        Method::PATCH,
        &format!("/scheduled-meetings/{}", self::id(&id)?),
        Some(
            json!({"title":title,"startAt":start_at,"durationMin":duration_min,
        "pwdEnabled":pwd_enabled,"pwd":pwd,"remind":remind,"waitRoom":wait_room}),
        ),
    )
    .await
}

#[tauri::command]
pub async fn room_recording_control(room_id: String, action: String, epoch: u64, participant_id: Option<String>, request_id: Option<String>) -> Reply {
    call(Method::POST, &format!("/rooms/{}/recording/control", id(&room_id)?),
        Some(json!({"action":action,"epoch":epoch,"participantId":participant_id,"requestId":request_id}))).await
}

#[tauri::command]
pub async fn room_recording_chunk(room_id: String, chunk: Value) -> Reply {
    call(
        Method::POST,
        &format!("/rooms/{}/recording/chunks", id(&room_id)?),
        Some(chunk),
    )
    .await
}

#[tauri::command]
pub async fn room_recording_status(meeting_id: String) -> Reply {
    call(
        Method::GET,
        &format!("/meetings/{}/recording", id(&meeting_id)?),
        None,
    )
    .await
}

#[tauri::command]
pub async fn room_recording_retry(meeting_id: String) -> Reply {
    call(
        Method::POST,
        &format!("/meetings/{}/recording/retry", id(&meeting_id)?),
        None,
    )
    .await
}
#[tauri::command]
pub async fn sched_delete(id: String) -> Reply {
    call(
        Method::DELETE,
        &format!("/scheduled-meetings/{}", self::id(&id)?),
        None,
    )
    .await
}
#[tauri::command]
pub async fn room_create(title: Option<String>, scheduled_meeting_id: Option<String>) -> Reply {
    call(
        Method::POST,
        "/rooms",
        Some(json!({"title":title,"scheduledMeetingId":scheduled_meeting_id})),
    )
    .await
}
#[tauri::command]
pub async fn room_get(room_id: String) -> Reply {
    call(Method::GET, &format!("/rooms/{}", id(&room_id)?), None).await
}
#[tauri::command]
pub async fn room_get_code(code: String) -> Reply {
    let c = client()?;
    send(
        &c,
        c.request(Method::GET, "/rooms").query(&[("code", code)]),
    )
    .await
}
#[tauri::command]
pub async fn room_patch(
    room_id: String,
    title: Option<String>,
    pwd_enabled: Option<bool>,
    pwd: Option<String>,
    wait_room: Option<bool>,
) -> Reply {
    call(
        Method::PATCH,
        &format!("/rooms/{}", id(&room_id)?),
        Some(json!({"title":title,"pwdEnabled":pwd_enabled,"pwd":pwd,"waitRoom":wait_room})),
    )
    .await
}
#[tauri::command]
pub async fn room_update_self(
    room_id: String,
    mic_on: Option<bool>,
    cam_on: Option<bool>,
    hand_raised: Option<bool>,
    screen_sharing: Option<bool>,
) -> Reply {
    call(Method::POST, &format!("/rooms/{}/participants/me", id(&room_id)?), Some(json!({"micOn":mic_on,"camOn":cam_on,"handRaised":hand_raised,"screenSharing":screen_sharing}))).await
}
#[tauri::command]
pub async fn room_admit(room_id: String, participant_id: String) -> Reply {
    call(
        Method::POST,
        &format!("/rooms/{}/admit", id(&room_id)?),
        Some(json!({"participantId":participant_id})),
    )
    .await
}
#[tauri::command]
pub async fn room_deny(room_id: String, participant_id: String) -> Reply {
    call(
        Method::POST,
        &format!("/rooms/{}/deny", id(&room_id)?),
        Some(json!({"participantId":participant_id})),
    )
    .await
}
#[tauri::command]
pub async fn room_mute_participant(room_id: String, participant_id: String, muted: bool) -> Reply {
    call(
        Method::POST,
        &format!(
            "/rooms/{}/participants/{}/mute",
            id(&room_id)?,
            id(&participant_id)?
        ),
        Some(json!({"muted":muted})),
    )
    .await
}
#[tauri::command]
pub async fn room_approve_hand(room_id: String, participant_id: String) -> Reply {
    call(
        Method::POST,
        &format!(
            "/rooms/{}/participants/{}/approve-hand",
            id(&room_id)?,
            id(&participant_id)?
        ),
        None,
    )
    .await
}
#[tauri::command]
pub async fn room_remove_participant(room_id: String, participant_id: String) -> Reply {
    call(
        Method::POST,
        &format!(
            "/rooms/{}/participants/{}/remove",
            id(&room_id)?,
            id(&participant_id)?
        ),
        None,
    )
    .await
}
#[tauri::command]
pub async fn room_transfer_host(room_id: String, participant_id: String) -> Reply {
    call(
        Method::POST,
        &format!(
            "/rooms/{}/participants/{}/transfer-host",
            id(&room_id)?,
            id(&participant_id)?
        ),
        None,
    )
    .await
}
#[tauri::command]
pub async fn room_mute_all(room_id: String) -> Reply {
    call(
        Method::POST,
        &format!("/rooms/{}/mute-all", id(&room_id)?),
        None,
    )
    .await
}
#[tauri::command]
pub async fn room_chat_session(room_id: String) -> Reply {
    call(
        Method::POST,
        &format!("/rooms/{}/chat-session", id(&room_id)?),
        None,
    )
    .await
}

#[tauri::command]
pub async fn room_media_recover(room_id: String, session_id: String) -> Reply {
    call(
        Method::POST,
        &format!("/rooms/{}/media/recover", id(&room_id)?),
        Some(json!({"sessionId": id(&session_id)?})),
    )
    .await
}

#[tauri::command]
pub async fn room_media_ticket(room_id: String) -> Reply {
    call(
        Method::POST,
        &format!("/rooms/{}/media", id(&room_id)?),
        None,
    )
    .await
}

#[tauri::command]
pub async fn room_screen_config(room_id: String) -> Reply {
    call(
        Method::GET,
        &format!("/rooms/{}/screen-share", id(&room_id)?),
        None,
    )
    .await
}
#[tauri::command]
pub async fn room_screen_start(room_id: String) -> Reply {
    call(
        Method::POST,
        &format!("/rooms/{}/screen-share/start", id(&room_id)?),
        None,
    )
    .await
}
#[tauri::command]
pub async fn room_screen_stop(room_id: String, session_id: String) -> Reply {
    call(
        Method::POST,
        &format!("/rooms/{}/screen-share/stop", id(&room_id)?),
        Some(json!({"sessionId":session_id})),
    )
    .await
}
#[tauri::command]
pub async fn room_screen_signal(
    room_id: String,
    target_id: String,
    session_id: String,
    kind: String,
    payload: String,
) -> Reply {
    if payload.len() > 65536 {
        return Err(LiveError {
            status: 422,
            detail: "共享信令过大".into(),
            code: None,
        });
    }
    call(
        Method::POST,
        &format!("/rooms/{}/screen-share/signal", id(&room_id)?),
        Some(json!({"targetId":target_id,"sessionId":session_id,"kind":kind,"payload":payload})),
    )
    .await
}

struct Signal {
    room_id: String,
    session_token: Option<String>,
    cancel: CancellationToken,
}
impl Signal {
    fn matches(&self, room_id: &str, session_token: Option<&str>) -> bool {
        self.room_id == room_id
            && self.session_token.as_deref() == session_token
            && !self.cancel.is_cancelled()
    }
}
#[derive(Default)]
pub struct LiveSignalState {
    active: Mutex<Option<Signal>>,
}
impl LiveSignalState {
    async fn stop(&self, room_id: &str) {
        let mut active = self.active.lock().await;
        if active.as_ref().is_some_and(|s| s.room_id == room_id) {
            if let Some(signal) = active.take() {
                signal.cancel.cancel();
            }
        }
    }
}
fn connection<R: Runtime>(app: &AppHandle<R>, room_id: &str, state: &str) {
    let _ = app.emit("room-connection", json!({"roomId":room_id,"state":state}));
}
async fn connect<R: Runtime>(
    app: AppHandle<R>,
    state: &LiveSignalState,
    c: ServerClient,
    room_id: String,
) -> Result<(), LiveError> {
    id(&room_id)?;
    let mut url =
        url::Url::parse(c.base_url()).map_err(|_| LiveError::from(ServerError::NotConfigured))?;
    url.set_scheme(if url.scheme() == "https" { "wss" } else { "ws" })
        .map_err(|_| LiveError::from(ServerError::NotConfigured))?;
    url.set_path(&format!(
        "{}/api/v1/rooms/{}/ws",
        url.path().trim_end_matches('/'),
        room_id
    ));
    let cancel = CancellationToken::new();
    let mut active = state.active.lock().await;
    if active
        .as_ref()
        .is_some_and(|s| s.matches(&room_id, c.session_token()))
    {
        return Ok(());
    }
    if let Some(old) = active.take() {
        old.cancel.cancel();
    }
    *active = Some(Signal {
        room_id: room_id.clone(),
        session_token: c.session_token().map(str::to_owned),
        cancel: cancel.clone(),
    });
    drop(active);
    tauri::async_runtime::spawn(async move {
        let mut attempt = 0u32;
        let mut unavailable_since = Some(tokio::time::Instant::now());
        loop {
            if cancel.is_cancelled() {
                break;
            }
            if unavailable_since.is_some_and(|since| since.elapsed() >= Duration::from_secs(90)) {
                connection(&app, &room_id, "failed");
                break;
            }
            // A logout/account change must never keep the previous user's socket alive.
            if !ServerClient::current()
                .is_ok_and(|current| current.session_token() == c.session_token())
            {
                break;
            }
            connection(
                &app,
                &room_id,
                if attempt == 0 {
                    "connecting"
                } else {
                    "reconnecting"
                },
            );
            let mut request = match url.as_str().into_client_request() {
                Ok(r) => r,
                Err(_) => break,
            };
            let auth = format!("Bearer {}", c.session_token().unwrap_or_default());
            match auth.parse() {
                Ok(value) => {
                    request.headers_mut().insert("Authorization", value);
                }
                Err(_) => break,
            }
            let result = tokio::select! {
                _ = cancel.cancelled() => break,
                value = tokio::time::timeout(Duration::from_secs(10), connect_async(request)) => value,
            };
            if let Ok(Ok((mut socket, _))) = result {
                attempt = 0;
                connection(&app, &room_id, "connected");
                let mut session_check = tokio::time::interval(Duration::from_secs(2));
                let mut heartbeat = tokio::time::interval(Duration::from_secs(15));
                let mut last_received = tokio::time::Instant::now();
                let mut terminal = false;
                loop {
                    tokio::select! {
                        _ = cancel.cancelled() => { let _ = socket.close(None).await; terminal = true; break; }
                        _ = session_check.tick() => {
                            if !ServerClient::current().is_ok_and(|current| current.session_token() == c.session_token()) {
                                let _ = socket.close(None).await; terminal = true; break;
                            }
                            if last_received.elapsed() > Duration::from_secs(45) {
                                let _ = socket.close(None).await; break;
                            }
                        }
                        _ = heartbeat.tick() => {
                            if !matches!(tokio::time::timeout(Duration::from_secs(5), socket.send(Message::Text("{\"type\":\"ping\"}".into())))
                                .await, Ok(Ok(()))) { break; }
                        }
                        message = socket.next() => match message {
                            Some(Ok(Message::Text(text))) => {
                                last_received = tokio::time::Instant::now();
                                if let Ok(mut event) = serde_json::from_str::<Value>(&text) {
                                    if event.get("type").and_then(Value::as_str) == Some("pong") { continue; }
                                    if event.get("type").and_then(Value::as_str) == Some("room_state") { unavailable_since = None; }
                                    let ended = event.get("type").and_then(Value::as_str) == Some("room_ended");
                                    event["roomId"] = json!(room_id);
                                    let _ = app.emit("room-event", event);
                                    if ended { terminal = true; break; }
                                }
                            }
                            Some(Ok(Message::Ping(bytes))) => {
                                last_received = tokio::time::Instant::now();
                                if !matches!(tokio::time::timeout(Duration::from_secs(5), socket.send(Message::Pong(bytes)))
                                    .await, Ok(Ok(()))) { break; }
                            }
                            Some(Ok(Message::Close(frame))) => {
                                if let Some(frame) = frame {
                                    let code: u16 = frame.code.into();
                                    if code == 4401 { c.notify_unauthorized(); terminal = true; }
                                    if code == 4403 { connection(&app, &room_id, "removed"); terminal = true; }
                                }
                                break;
                            }
                            Some(Err(_)) | None => break,
                            _ => {}
                        }
                    }
                }
                if terminal {
                    break;
                }
            }
            unavailable_since.get_or_insert_with(tokio::time::Instant::now);
            attempt = attempt.saturating_add(1);
            connection(&app, &room_id, "reconnecting");
            let jitter = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| u64::from(d.subsec_millis()))
                .unwrap_or(0);
            tokio::select! {
                _ = cancel.cancelled() => break,
                _ = tokio::time::sleep(Duration::from_millis((1u64 << attempt.min(4)) * 1000 + jitter)) => {}
            }
        }
        cancel.cancel();
    });
    Ok(())
}
#[tauri::command]
pub async fn room_join<R: Runtime>(
    app: AppHandle<R>,
    state: State<'_, Arc<LiveSignalState>>,
    code: String,
    name: Option<String>,
    mic_on: bool,
    cam_on: bool,
    pwd: Option<String>,
) -> Reply {
    let result = call(
        Method::POST,
        "/rooms/join",
        Some(json!({"code":code,"name":name,"micOn":mic_on,"camOn":cam_on,"pwd":pwd})),
    )
    .await?;
    if let Some(room_id) = result
        .pointer("/room/id")
        .and_then(Value::as_str)
        .filter(|_| result.get("state").and_then(Value::as_str) == Some("joined"))
    {
        connect(app, &state, client()?, room_id.to_owned()).await?;
    }
    Ok(result)
}
#[tauri::command]
pub async fn room_signal_connect<R: Runtime>(
    app: AppHandle<R>,
    state: State<'_, Arc<LiveSignalState>>,
    room_id: String,
) -> Result<(), LiveError> {
    connect(app, &state, client()?, room_id).await
}
#[tauri::command]
pub async fn room_signal_disconnect(
    state: State<'_, Arc<LiveSignalState>>,
    room_id: String,
) -> Result<(), LiveError> {
    state.stop(&room_id).await;
    Ok(())
}
#[tauri::command]
pub async fn room_leave(state: State<'_, Arc<LiveSignalState>>, room_id: String) -> Reply {
    let result = call(
        Method::POST,
        &format!("/rooms/{}/leave", id(&room_id)?),
        None,
    )
    .await?;
    state.stop(&room_id).await;
    Ok(result)
}
#[tauri::command]
pub async fn room_end(state: State<'_, Arc<LiveSignalState>>, room_id: String) -> Reply {
    let result = call(Method::POST, &format!("/rooms/{}/end", id(&room_id)?), None).await?;
    state.stop(&room_id).await;
    Ok(result)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn optional_patches_preserve_false_and_omit_null() {
        assert_eq!(
            body(json!({"micOn":false,"camOn":null})),
            json!({"micOn":false})
        );
        assert!(id("../../auth/me").is_err());
    }
    #[test]
    fn same_room_with_a_different_session_must_replace_the_socket() {
        let signal = Signal {
            room_id: "room-unit".into(),
            session_token: Some("old-session".into()),
            cancel: CancellationToken::new(),
        };
        assert!(signal.matches("room-unit", Some("old-session")));
        assert!(!signal.matches("room-unit", Some("new-session")));
        signal.cancel.cancel();
        assert!(!signal.matches("room-unit", Some("old-session")));
    }
}
