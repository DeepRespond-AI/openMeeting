"""Short-lived, scoped direct uploads. File bytes never pass through this module."""
from __future__ import annotations

import base64
import logging
import re
import time
import uuid

import jwt
from fastapi import HTTPException
from pydantic import BaseModel, Field, field_validator

logger = logging.getLogger(__name__)
UPLOAD_TTL = 3600


class UploadProof(BaseModel):
    file_name: str = Field(min_length=1, max_length=255)
    size: int = Field(gt=0, le=2 * 1024**3)
    sha256: str = Field(pattern=r"^[a-f0-9]{64}$")
    md5: str = Field(min_length=24, max_length=24)

    @field_validator("md5")
    @classmethod
    def valid_md5(cls, value: str) -> str:
        try:
            if len(base64.b64decode(value, validate=True)) == 16:
                return value
        except ValueError:
            pass
        raise ValueError("md5 must be a Base64-encoded 16-byte digest")


class UploadComplete(BaseModel):
    ticket: str = Field(min_length=1, max_length=20000)


def safe_name(value: str) -> str:
    name = value.replace("\\", "/").rsplit("/", 1)[-1]
    return re.sub(r"[^A-Za-z0-9._+-]+", "_", name).strip("._")[:200] or "file"


def create_offer(store, secret: str, owner: str, kind: str, resource: str,
                 proof: UploadProof, prefix: list[str], content_type: str, **extra) -> dict:
    upload_id = uuid.uuid4().hex
    name = safe_name(proof.file_name)
    claims = {"aud": "object-upload", "owner": owner, "kind": kind, "resource": resource,
              "backend": store.backend, "upload_id": upload_id, "file_name": name,
              "size": proof.size, "sha256": proof.sha256, "md5": proof.md5,
              "content_type": content_type, "source": store.key(".pending-uploads", upload_id, name),
              "key": store.key(*prefix, upload_id, name), "extra": extra,
              "exp": int(time.time()) + UPLOAD_TTL}
    target = store.presign_put(claims["source"], proof, content_type, UPLOAD_TTL)
    return {"mode": "direct", "ticket": jwt.encode(claims, secret, algorithm="HS256"),
            "expires_in": UPLOAD_TTL, **target}


def read_ticket(ticket: str, secret: str, owner: str, kind: str, resource: str | None = None) -> dict:
    try:
        data = jwt.decode(ticket, secret, algorithms=["HS256"], audience="object-upload",
                          options={"require": ["exp", "owner", "kind", "resource", "backend", "key", "source"]})
    except jwt.ExpiredSignatureError as exc:
        raise HTTPException(410, "上传授权已过期，请重新上传") from exc
    except jwt.PyJWTError as exc:
        raise HTTPException(403, "上传授权无效") from exc
    if data["owner"] != owner or data["kind"] != kind or (resource is not None and data["resource"] != resource):
        raise HTTPException(403, "上传授权不属于当前操作")
    return data


def _verify(stat: dict, claims: dict) -> None:
    metadata = stat.get("metadata", {})
    if (stat["size"] != claims["size"] or metadata.get("sha256") != claims["sha256"]
            or metadata.get("content-md5") != claims["md5"]):
        raise HTTPException(422, "上传对象的大小或摘要不匹配，请重新上传")


async def confirm_object(store, claims: dict) -> None:
    if store is None or store.backend != claims["backend"]:
        raise HTTPException(503, "上传对应的对象存储不可用")
    try:
        final = await store.stat_object(claims["key"])
        if final is not None:
            _verify(final, claims)
            return  # Idempotent completion; the public PUT never targets the final object.
        pending = await store.stat_object(claims["source"])
        if pending is None:
            raise HTTPException(409, "文件尚未上传完成，请重试确认")
        _verify(pending, claims)
        # Conditional storage-side copy freezes the verified bytes without server I/O.
        await store.copy_object(claims["source"], claims["key"], pending["etag"])
        final = await store.stat_object(claims["key"])
        if final is None:
            raise HTTPException(502, "对象存储未确认文件，请重试")
        _verify(final, claims)
    except HTTPException:
        raise
    except Exception as exc:
        logger.warning("Direct upload confirmation failed", exc_info=True)
        raise HTTPException(502, "对象存储确认失败，请重试") from exc


async def cleanup_pending(store, claims: dict) -> None:
    try:
        await store.delete_object(claims["source"])
    except Exception:
        logger.warning("Pending upload cleanup deferred", exc_info=True)
