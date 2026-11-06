"""Release OSS signing contracts; real SDK, fake credentials, no network or database."""
from urllib.parse import parse_qs, unquote, urlsplit

import oss2
import pytest
from pydantic import ValidationError

from user_ms.config import Settings
from user_ms.storage import oss


@pytest.mark.parametrize("value", [None, "", "  "])
def test_empty_domain_keeps_default(value):
    assert Settings(_env_file=None, oss_download_domain=value).oss_download_domain is None


def test_normalize_domain():
    settings = Settings(_env_file=None, oss_download_domain=" https://DOWNLOAD.example.com/ ")
    assert settings.oss_download_domain == "https://download.example.com"


@pytest.mark.parametrize("value", [
    "download.example.com", "http://download.example.com", "https://download.example.com/files",
    "https://download.example.com/?token=x", "https://download.example.com/#fragment",
    "https://user:secret@download.example.com", "https://download.example.com:99999",
])
def test_invalid_domain_fails_configuration(value):
    with pytest.raises(ValidationError):
        Settings(_env_file=None, oss_download_domain=value)


@pytest.fixture
def store_factory(monkeypatch, tmp_path):
    def no_network(*args, **kwargs):
        pytest.fail("Signing must not perform network requests")

    monkeypatch.setattr(oss2.Session, "do_request", no_network)

    def create(domain=None):
        settings = Settings(_env_file=None, env="test", egress_proxy_url="", data_dir=tmp_path,
                            oss_download_domain=domain)
        monkeypatch.setattr(oss, "get_settings", lambda: settings)
        return oss.OssStore(oss.OssConfig("oss-cn-shenzhen.aliyuncs.com", "cn-shenzhen", "test-bucket",
                                         "test-id", "test-secret", "releases/"))
    return create


def test_unconfigured_domain_keeps_original_download_url(store_factory):
    store = store_factory()
    url = urlsplit(store.presign_get("releases/app.apk"))
    assert url.netloc == "test-bucket.oss-cn-shenzhen.aliyuncs.com"
    assert store.download_bucket is store.bucket
    assert "x-oss-signature" in parse_qs(url.query)


@pytest.mark.parametrize("filename", ["安装 包.apk", "update.exe"])
def test_cname_signed_download_uses_same_bucket_and_key(store_factory, filename):
    store = store_factory("https://download.example.com")
    key = "releases/" + filename
    url = urlsplit(store.presign_get(key, expires=123))
    query = parse_qs(url.query)
    assert url.netloc == "download.example.com"
    assert unquote(url.path) == "/" + key
    assert query["x-oss-expires"] == ["123"]
    assert query["x-oss-signature-version"] == ["OSS4-HMAC-SHA256"]
    assert "x-oss-signature" in query
    assert "/cn-shenzhen/oss/aliyun_v4_request" in query["x-oss-credential"][0]
    assert store.download_bucket.bucket_name == store.bucket.bucket_name == "test-bucket"
    assert store.download_bucket.endpoint == "https://download.example.com"
    assert store.bucket.endpoint == "https://oss-cn-shenzhen.aliyuncs.com"


async def test_upload_still_uses_original_endpoint(store_factory, monkeypatch, tmp_path):
    store = store_factory("https://download.example.com")
    source = tmp_path / "app.apk"
    source.write_bytes(b"package-fixture")
    calls = []

    def upload(bucket, key, path, **kwargs):
        calls.append((bucket, key, path, kwargs["headers"]["Content-Type"]))

    monkeypatch.setattr(oss2, "resumable_upload", upload)
    await store.upload(source, "releases/app.apk", "application/vnd.android.package-archive")
    assert calls == [(store.bucket, "releases/app.apk", str(source), "application/vnd.android.package-archive")]
