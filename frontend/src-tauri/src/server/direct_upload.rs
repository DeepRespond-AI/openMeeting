//! Scoped PUT uploads without forwarding business credentials to object storage.
use super::client::{ServerClient, ServerError};
use base64::Engine;
use serde::{de::DeserializeOwned, Deserialize};
use sha2::{Digest, Sha256};
use std::{
    collections::HashMap,
    path::Path,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
    time::Duration,
};
use tokio::io::AsyncReadExt;

#[derive(Deserialize)]
struct Offer {
    mode: String,
    ticket: Option<String>,
    url: Option<String>,
    headers: Option<HashMap<String, String>>,
}

pub(super) async fn proof(
    path: &Path,
    cancel: Option<&Arc<AtomicBool>>,
) -> Result<serde_json::Value, ServerError> {
    let mut file = tokio::fs::File::open(path)
        .await
        .map_err(|e| ServerError::Other(e.to_string()))?;
    let mut buffer = vec![0u8; 1024 * 1024];
    let mut sha = Sha256::new();
    let mut md5 = md5::Md5::new();
    let mut size = 0u64;
    loop {
        check_cancel(cancel)?;
        let n = file
            .read(&mut buffer)
            .await
            .map_err(|e| ServerError::Other(e.to_string()))?;
        if n == 0 {
            break;
        }
        sha.update(&buffer[..n]);
        md5.update(&buffer[..n]);
        size += n as u64;
    }
    Ok(
        serde_json::json!({"file_name":path.file_name().unwrap_or_default().to_string_lossy(),"size":size,
        "sha256":format!("{:x}",sha.finalize()),"md5":base64::engine::general_purpose::STANDARD.encode(md5.finalize())}),
    )
}

fn check_cancel(cancel: Option<&Arc<AtomicBool>>) -> Result<(), ServerError> {
    if cancel
        .map(|flag| flag.load(Ordering::SeqCst))
        .unwrap_or(false)
    {
        return Err(ServerError::Other("上传已取消".into()));
    }
    Ok(())
}

pub(super) async fn upload<T, F>(
    client: &ServerClient,
    path: &Path,
    endpoint: &str,
    extra: serde_json::Value,
    progress: Arc<F>,
    cancel: Option<Arc<AtomicBool>>,
) -> Result<Option<T>, ServerError>
where
    T: DeserializeOwned,
    F: Fn(f64) + Send + Sync + 'static,
{
    let mut body = proof(path, cancel.as_ref()).await?;
    if let Some(extra) = extra.as_object() {
        body.as_object_mut().unwrap().extend(extra.clone());
    }
    let offer: Offer = match client.post(&format!("{endpoint}/uploads"), &body).await {
        Ok(offer) => offer,
        Err(error) if matches!(error.status(), Some(404 | 405)) => return Ok(None),
        Err(error) => return Err(error),
    };
    if offer.mode == "proxy" {
        return Ok(None);
    }
    if offer.mode != "direct" {
        return Err(ServerError::Other("上传授权格式无效".into()));
    }
    let ticket = offer
        .ticket
        .ok_or_else(|| ServerError::Other("缺少上传授权".into()))?;
    let url = reqwest::Url::parse(offer.url.as_deref().unwrap_or_default())
        .map_err(|_| ServerError::Other("上传地址无效".into()))?;
    if !matches!(url.scheme(), "http" | "https")
        || !url.username().is_empty()
        || url.password().is_some()
        || url.fragment().is_some()
    {
        return Err(ServerError::Other("上传地址无效".into()));
    }
    check_cancel(cancel.as_ref())?;
    let report = progress.clone();
    let (stream, len, _) =
        super::client::file_body(path, move |p| report(p.min(0.95)), cancel.clone()).await?;
    let external = reqwest::Client::builder()
        .redirect(reqwest::redirect::Policy::none())
        .connect_timeout(Duration::from_secs(10))
        .timeout(Duration::from_secs(4 * 3600))
        .build()
        .map_err(|_| ServerError::Other("无法初始化上传连接".into()))?;
    let mut request = external
        .put(url)
        .header(reqwest::header::CONTENT_LENGTH, len);
    for (key, value) in offer.headers.unwrap_or_default() {
        if matches!(key.to_ascii_lowercase().as_str(), "cookie" | "host")
            || (key.eq_ignore_ascii_case("authorization")
                && !value.starts_with("AWS4-HMAC-SHA256 "))
        {
            return Err(ServerError::Other("上传请求头无效".into()));
        }
        request = request.header(key, value);
    }
    let response = request.body(stream).send().await.map_err(|_| {
        if cancel
            .as_ref()
            .map(|flag| flag.load(Ordering::SeqCst))
            .unwrap_or(false)
        {
            ServerError::Other("上传已取消".into())
        } else {
            ServerError::Connect("对象存储上传连接失败".into())
        }
    })?;
    if !response.status().is_success() {
        return Err(ServerError::Http {
            status: response.status().as_u16(),
            detail: format!(
                "对象存储上传失败（HTTP {}），请重试",
                response.status().as_u16()
            ),
        });
    }
    check_cancel(cancel.as_ref())?;
    let result = client
        .post(
            &format!("{endpoint}/uploads/complete"),
            &serde_json::json!({"ticket":ticket}),
        )
        .await?;
    progress(1.0);
    Ok(Some(result))
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::{json, Value};
    use tokio::{
        io::{AsyncReadExt, AsyncWriteExt},
        net::TcpListener,
    };

    async fn run_case(put_status: u16, complete_status: u16, legacy_status: Option<u16>) {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = format!("http://{}", listener.local_addr().unwrap());
        let url = address.clone();
        let payload = b"streamed recording test bytes";
        let requests = if legacy_status.is_some() {
            1
        } else if put_status != 200 {
            2
        } else {
            3
        };
        let server = tokio::spawn(async move {
            for index in 0..requests {
                let (mut socket, _) = listener.accept().await.unwrap();
                let mut bytes = Vec::new();
                let mut buffer = [0u8; 4096];
                let header_end;
                loop {
                    let count = socket.read(&mut buffer).await.unwrap();
                    assert!(count > 0);
                    bytes.extend_from_slice(&buffer[..count]);
                    if let Some(offset) = bytes.windows(4).position(|b| b == b"\r\n\r\n") {
                        header_end = offset + 4;
                        break;
                    }
                }
                let header = String::from_utf8_lossy(&bytes[..header_end]).to_ascii_lowercase();
                let size: usize = header
                    .lines()
                    .find_map(|line| line.strip_prefix("content-length: "))
                    .unwrap()
                    .parse()
                    .unwrap();
                while bytes.len() < header_end + size {
                    let n = socket.read(&mut buffer).await.unwrap();
                    assert!(n > 0);
                    bytes.extend_from_slice(&buffer[..n]);
                }
                let body = &bytes[header_end..header_end + size];
                let (status, result) = match index {
                    0 => {
                        assert!(header.contains("authorization: bearer test-business-session"));
                        let proof: Value = serde_json::from_slice(body).unwrap();
                        assert_eq!(proof["sha256"], format!("{:x}", Sha256::digest(payload)));
                        assert_eq!(proof["size"], payload.len());
                        assert_eq!(
                            proof["md5"],
                            base64::engine::general_purpose::STANDARD
                                .encode(md5::Md5::digest(payload))
                        );
                        (
                            legacy_status.unwrap_or(200),
                            if legacy_status.is_some() {
                                json!({"mode":"proxy"})
                            } else {
                                json!({"mode":"direct","url":format!("{url}/object"),"ticket":"scoped-ticket","headers":{"Authorization":"AWS4-HMAC-SHA256 scoped-signature","Content-Type":"audio/wav"}})
                            },
                        )
                    }
                    1 => {
                        assert!(header.starts_with("put /object "));
                        assert!(!header.contains("bearer"));
                        assert!(!header.contains("cookie:"));
                        assert!(header.contains("authorization: aws4-hmac-sha256 scoped-signature"));
                        assert_eq!(body, payload);
                        (put_status, json!({}))
                    }
                    _ => {
                        assert!(header.contains("authorization: bearer test-business-session"));
                        assert_eq!(
                            serde_json::from_slice::<Value>(body).unwrap()["ticket"],
                            "scoped-ticket"
                        );
                        (complete_status, json!({"size":payload.len()}))
                    }
                };
                let body = result.to_string();
                socket.write_all(format!("HTTP/1.1 {status} Test\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}", body.len()).as_bytes()).await.unwrap();
            }
        });
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("recording.wav");
        tokio::fs::write(&path, payload).await.unwrap();
        let progress = Arc::new(std::sync::Mutex::new(Vec::new()));
        let seen = progress.clone();
        let result = upload::<Value, _>(
            &ServerClient::new(&address, Some("test-business-session")).unwrap(),
            &path,
            "/audio",
            json!({}),
            Arc::new(move |fraction| seen.lock().unwrap().push(fraction)),
            None,
        )
        .await;
        if legacy_status.is_some() {
            assert!(result.unwrap().is_none());
        } else if put_status == 200 && complete_status == 200 {
            assert_eq!(result.unwrap().unwrap()["size"], payload.len());
            assert_eq!(progress.lock().unwrap().last(), Some(&1.0));
        } else {
            assert!(result.is_err());
            if put_status == 503 {
                assert!(result.as_ref().unwrap_err().is_retryable());
            }
            assert!(!progress.lock().unwrap().contains(&1.0));
        }
        assert!(path.exists());
        tokio::time::timeout(Duration::from_secs(5), server)
            .await
            .unwrap()
            .unwrap();
    }

    #[tokio::test]
    async fn streams_directly_then_confirms_with_separate_credentials() {
        run_case(200, 200, None).await;
    }
    #[tokio::test]
    async fn storage_failure_keeps_source_without_confirm_or_fallback() {
        run_case(503, 200, None).await;
    }
    #[tokio::test]
    async fn confirm_failure_does_not_report_success() {
        run_case(200, 502, None).await;
    }
    #[tokio::test]
    async fn local_storage_uses_legacy_path() {
        run_case(200, 200, Some(200)).await;
    }
    #[tokio::test]
    async fn older_server_uses_legacy_path() {
        run_case(200, 200, Some(404)).await;
    }
    #[tokio::test]
    async fn cancellation_prevents_hash_and_network() {
        let file = tempfile::NamedTempFile::new().unwrap();
        assert!(proof(file.path(), Some(&Arc::new(AtomicBool::new(true))))
            .await
            .is_err());
    }
}
