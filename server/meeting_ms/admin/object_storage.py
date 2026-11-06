"""Admin: global object storage configuration and connectivity test."""
from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel

from meeting_ms.storage import oss
from meeting_ms.utils import secret_box

router = APIRouter(tags=["admin-object-storage"])


class OssSettingsIn(BaseModel):
    endpoint: str | None = None
    region: str | None = None  # empty = derive from the endpoint
    bucket: str | None = None
    access_key_id: str | None = None
    access_key_secret: str | None = None  # omitted / null = keep, "" = clear
    prefix: str | None = None


async def settings_dict() -> dict:
    cfg = await oss.load_oss_config()
    return {
        "provider": cfg.provider,
        "public_endpoint": cfg.public_endpoint,
        "oss": {
            "endpoint": cfg.endpoint,
            "region": cfg.region,
            "bucket": cfg.bucket,
            "access_key_id": cfg.access_key_id,
            "access_key_secret_set": bool(cfg.access_key_secret),
            "prefix": cfg.prefix,
        },
        "oss_ready": cfg.ready,
        "env_overrides": sorted(oss.env_overrides()),
    }


@router.get("/object-storage")
async def get_object_storage() -> dict:
    return await settings_dict()


@router.put("/object-storage")
async def put_object_storage(body: OssSettingsIn) -> dict:
    stored = await oss.load_stored_oss_config()
    given = body.model_fields_set
    if "endpoint" in given:
        stored["endpoint"] = oss.normalize_endpoint(body.endpoint)
    for key in ("region", "bucket", "access_key_id"):
        if key in given:
            stored[key] = (getattr(body, key) or "").strip() or None
    if "prefix" in given:
        stored["prefix"] = oss.normalize_prefix(body.prefix)
    if body.access_key_secret is not None:
        secret = body.access_key_secret.strip()
        stored["access_key_secret_enc"] = secret_box().encrypt(secret) if secret else None
    await oss.save_stored_oss_config(stored)
    return await settings_dict()


@router.post("/object-storage/test")
async def storage_test() -> dict:
    cfg = await oss.load_oss_config()
    if not cfg.ready:
        return {"ok": False, "error": "对象存储配置不完整：请检查存储类型、Endpoint、地域、Bucket 和访问密钥；MinIO 还需配置客户端可访问的下载地址"}
    try:
        await oss._store_for(cfg).test()
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "error": oss.describe_error(exc)}
    return {"ok": True, "error": None}
