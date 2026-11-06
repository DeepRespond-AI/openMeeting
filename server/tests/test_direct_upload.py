"""Direct-upload integrity, authorization and retry contracts without any external services."""
import base64
import hashlib
import time
from types import SimpleNamespace
from urllib.parse import parse_qs, urlsplit

import jwt
import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from service_net.direct_upload import UploadProof, create_offer, read_ticket, confirm_object, cleanup_pending

SECRET = "isolated-direct-upload-test-secret"


def proof(payload=b"audio-fixture"):
    return UploadProof(file_name="audio.m4a", size=len(payload), sha256=hashlib.sha256(payload).hexdigest(),
                       md5=base64.b64encode(hashlib.md5(payload).digest()).decode())


class MemoryStore:
    backend = "oss"

    def __init__(self):
        self.objects = {}
        self.copies = 0
        self.fail_copy = False

    def key(self, *parts):
        return "test/" + "/".join(parts)

    def presign_put(self, key, spec, content_type, expires):
        return {"url": "https://storage.example/" + key, "headers": {"Content-MD5": spec.md5}}

    async def stat_object(self, key):
        return self.objects.get(key)

    async def copy_object(self, source, target, etag):
        if self.fail_copy:
            raise RuntimeError("copy outage")
        assert self.objects[source]["etag"] == etag
        self.objects[target] = dict(self.objects[source])
        self.copies += 1

    async def delete_object(self, key):
        self.objects.pop(key, None)


def prepare(store, spec=None):
    spec = spec or proof()
    offer = create_offer(store, SECRET, "u1", "meeting-audio", "m1", spec, ["audio", "u1", "m1"], "audio/mp4")
    claims = read_ticket(offer["ticket"], SECRET, "u1", "meeting-audio", "m1")
    return offer, claims


def uploaded(store, claims):
    store.objects[claims["source"]] = {"size": claims["size"], "etag": "etag-verified",
        "metadata": {"sha256": claims["sha256"], "content-md5": claims["md5"]}}


@pytest.mark.parametrize("field,value", [("size", 0), ("size", 2*1024**3+1), ("sha256", "bad"), ("md5", "not-base64")])
def test_invalid_proof_is_rejected(field, value):
    data = proof().model_dump(); data[field] = value
    with pytest.raises(ValidationError):
        UploadProof(**data)


@pytest.mark.parametrize("owner,kind,resource", [("u2", "meeting-audio", "m1"), ("u1", "release-artifact", "m1"),
                                               ("u1", "meeting-audio", "m2")])
def test_upload_ticket_is_scoped(owner, kind, resource):
    offer, _ = prepare(MemoryStore())
    with pytest.raises(HTTPException) as error:
        read_ticket(offer["ticket"], SECRET, owner, kind, resource)
    assert error.value.status_code == 403


def test_expired_and_tampered_tickets():
    offer, claims = prepare(MemoryStore())
    claims["exp"] = int(time.time())-1
    with pytest.raises(HTTPException) as expired:
        read_ticket(jwt.encode(claims, SECRET, algorithm="HS256"), SECRET, "u1", "meeting-audio", "m1")
    assert expired.value.status_code == 410
    with pytest.raises(HTTPException) as tampered:
        read_ticket(offer["ticket"] + "x", SECRET, "u1", "meeting-audio", "m1")
    assert tampered.value.status_code == 403


async def test_object_must_exist_before_completion():
    store = MemoryStore(); _, claims = prepare(store)
    with pytest.raises(HTTPException) as error:
        await confirm_object(store, claims)
    assert error.value.status_code == 409 and store.copies == 0


@pytest.mark.parametrize("field", ["size", "sha256", "content-md5"])
async def test_mismatched_object_cannot_be_published(field):
    store = MemoryStore(); _, claims = prepare(store); uploaded(store, claims)
    target = store.objects[claims["source"]]
    if field == "size": target[field] += 1
    else: target["metadata"][field] = "wrong"
    with pytest.raises(HTTPException) as error:
        await confirm_object(store, claims)
    assert error.value.status_code == 422 and store.copies == 0


async def test_completion_is_immutable_idempotent_and_cleans_pending():
    store = MemoryStore(); _, claims = prepare(store); uploaded(store, claims)
    await confirm_object(store, claims)
    await cleanup_pending(store, claims)
    assert claims["source"] not in store.objects
    assert claims["key"] in store.objects
    # Reusing an unexpired public PUT URL cannot overwrite the published object.
    store.objects[claims["source"]] = {"size": 1, "etag": "other", "metadata": {}}
    await confirm_object(store, claims)
    assert store.copies == 1 and store.objects[claims["key"]]["size"] == claims["size"]


async def test_copy_failure_and_backend_mismatch_do_not_publish():
    store = MemoryStore(); _, claims = prepare(store); uploaded(store, claims)
    store.fail_copy = True
    with pytest.raises(HTTPException) as error:
        await confirm_object(store, claims)
    assert error.value.status_code == 502 and claims["key"] not in store.objects
    store.backend = "minio"
    with pytest.raises(HTTPException) as error:
        await confirm_object(store, claims)
    assert error.value.status_code == 503


def test_real_oss_sdk_signs_integrity_headers_without_network(monkeypatch, tmp_path):
    from user_ms.storage import oss
    from user_ms.config import Settings
    import oss2
    settings = Settings(_env_file=None, env="test", data_dir=tmp_path, egress_proxy_url="",
                        oss_download_domain="https://download.example.com")
    monkeypatch.setattr(oss, "get_settings", lambda: settings)
    monkeypatch.setattr(oss2.Session, "do_request", lambda *a, **k: pytest.fail("Signing used network"))
    store = oss.OssStore(oss.OssConfig("oss-cn-shenzhen.aliyuncs.com", "cn-shenzhen", "test-bucket", "id", "secret", ""))
    target = store.presign_put("pending/file.apk", proof(), "application/vnd.android.package-archive", 3600)
    parsed = urlsplit(target["url"])
    assert parsed.hostname == "download.example.com"
    assert "x-oss-signature" in parse_qs(parsed.query)
    assert target["headers"]["Content-MD5"] == proof().md5
    assert target["headers"]["x-oss-meta-sha256"] == proof().sha256


def test_real_minio_sdk_uses_public_upload_host():
    from service_net.minio_store import MinioStore
    config = SimpleNamespace(endpoint="http://minio:9000", public_endpoint="https://storage.example.com",
                             region="us-east-1", access_key_id="test-user", access_key_secret="test-password",
                             bucket="test-bucket", prefix="")
    store = MinioStore(config, SimpleNamespace(egress_proxy_url="", is_dev=True))
    target = store.presign_put("pending/file.apk", proof(), "application/octet-stream", 3600)
    assert urlsplit(target["url"]).netloc == "storage.example.com"
    assert target["headers"]["Authorization"].startswith("AWS4-HMAC-SHA256 ")
    assert "x-amz-meta-sha256" in target["headers"]["Authorization"]
    assert target["headers"]["Content-MD5"] == proof().md5


async def test_oss_head_without_xml_body_is_missing_not_storage_failure():
    import oss2
    from service_net.oss_direct_upload import OssDirectUpload
    store = OssDirectUpload()
    store._oss2 = oss2
    def missing(*args):
        raise oss2.exceptions.NotFound(404, {}, b"", {})
    store.bucket = SimpleNamespace(head_object=missing)
    assert await store.stat_object("missing") is None


@pytest.mark.parametrize("duration", [-1, float("inf"), float("nan")])
def test_audio_duration_must_be_nonnegative_and_finite(duration):
    from meeting_ms.api.v1.audio import AudioUploadProof
    with pytest.raises(ValidationError):
        AudioUploadProof(**proof().model_dump(), duration=duration)
