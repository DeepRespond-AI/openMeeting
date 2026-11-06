//! Dynamic IM bootstrap. Tickets remain one-use and are never persisted or logged.
use crate::server::client::ServerClient;
use serde::{Deserialize, Serialize};
use tauri::{AppHandle, Runtime};

#[derive(Deserialize, Serialize)]
pub struct ImTicket {
    pub ticket: String,
    #[serde(rename(serialize = "apiUrl", deserialize = "api_url"))]
    pub api_url: String,
    #[serde(rename(serialize = "appKey", deserialize = "app_key"))]
    pub app_key: String,
}

fn explicit_dev_ticket() -> Option<ImTicket> {
    if !cfg!(debug_assertions) && !matches!(option_env!("OPENMEETING_ENV"), Some("dev")) {
        return None;
    }
    // No fabricated demo credentials. A developer must configure all three explicitly.
    let ticket = std::env::var("OPENMEETING_IM_DEV_TICKET")
        .ok()
        .filter(|v| !v.is_empty())?;
    let api_url = std::env::var("OPENMEETING_IM_API_URL")
        .ok()
        .filter(|v| !v.is_empty())?;
    let app_key = std::env::var("OPENMEETING_IM_APP_KEY")
        .ok()
        .filter(|v| !v.is_empty())?;
    Some(ImTicket {
        ticket,
        api_url,
        app_key,
    })
}

#[tauri::command]
pub async fn im_get_ticket<R: Runtime>(_app: AppHandle<R>) -> Result<ImTicket, String> {
    let result: Result<ImTicket, String> = async {
        let client = ServerClient::current().map_err(String::from)?;
        let response = client
            .send(client.request(reqwest::Method::POST, "/im/ticket"))
            .await
            .map_err(String::from)?;
        let text = response
            .text()
            .await
            .map_err(|_| "IM 响应读取失败".to_string())?;
        serde_json::from_str(&text).map_err(|_| "IM 响应格式无效".to_string())
    }
    .await;
    match result {
        Ok(ticket) => Ok(ticket),
        Err(error) => explicit_dev_ticket().ok_or(error),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn server_bootstrap_fields_reach_the_ui_in_camel_case() {
        let ticket:ImTicket=serde_json::from_value(serde_json::json!({"ticket":"fixture","api_url":"https://im.example","app_key":"org#app","expires_in":300})).unwrap();
        let value = serde_json::to_value(ticket).unwrap();
        assert_eq!(value["apiUrl"], "https://im.example");
        assert_eq!(value["appKey"], "org#app");
    }
}
