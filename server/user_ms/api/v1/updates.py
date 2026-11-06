"""Client upgrade checks (public: a forced upgrade must also block the login screen).

- `GET /updates/check` — the app and the desktop UI.
- `GET /updates/tauri/{target}/{arch}/{current_version}` — Tauri updater dynamic-server format.
- `GET /updates/download/{artifact_id}` — the package (302 to OSS or the file).
"""
from __future__ import annotations

from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import FileResponse, JSONResponse, RedirectResponse, Response
from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from user_ms.api.deps import optional_user_id
from user_ms.db.models import ClientReleaseArtifact
from user_ms.db.session import get_session
from user_ms.storage import oss
from user_ms.updates.policy import PLATFORMS
from user_ms.updates.service import Offer, resolve_update
from user_ms.updates.storage import OSS
from service_net.minio_store import OBJECT_BACKENDS
from user_ms.updates.versions import format_version, try_parse_version
from user_ms.utils import iso, rfc3339

public_router = APIRouter(prefix="/updates", tags=["updates"])

# Tauri `{{target}}` → our platform names.
_TAURI_TARGETS = {"darwin": "macos", "macos": "macos", "windows": "windows", "linux": "linux"}


def _download_url(request: Request, artifact: ClientReleaseArtifact | None) -> str | None:
    if artifact is None:
        return None
    return str(request.url_for("download_release_artifact", artifact_id=artifact.id))


def _offer_dict(request: Request, offer: Offer) -> dict:
    r, a = offer.release, offer.artifact
    return {
        "id": r.id,
        "version": r.version,
        "build": r.build,
        "full_version": format_version(r.version, r.build),
        "notes": r.notes,
        "pub_date": iso(r.published_at),
        "force": offer.force,
        "size": a.size if a else None,
        "sha256": a.sha256 if a else None,
        "download_url": _download_url(request, a),
        "store_url": offer.store_url,
    }


@public_router.get("/check")
async def check_update(
    request: Request,
    platform: str = Query(...),
    version: str = Query(...),
    arch: str | None = None,
    channel: str | None = None,
    client_id: str | None = None,
    session: AsyncSession = Depends(get_session),
) -> dict:
    platform = platform.lower()
    if platform not in PLATFORMS:
        raise HTTPException(422, f"不支持的平台：{platform}")
    current = try_parse_version(version)
    if current is None:
        raise HTTPException(422, f"无效的版本号：{version}")
    decision = await resolve_update(
        session, platform=platform, current=current, arch=arch, channel=channel, client_id=client_id,
        user_id=optional_user_id(request),
    )
    return {
        "update": _offer_dict(request, decision.offer) if decision.offer else None,
        "min_version": decision.min_version,
    }


@public_router.get("/tauri/{target}/{arch}/{current_version}")
async def tauri_update(
    target: str,
    arch: str,
    current_version: str,
    request: Request,
    client_id: str | None = None,
    session: AsyncSession = Depends(get_session),
) -> Response:
    platform = _TAURI_TARGETS.get(target.lower())
    current = try_parse_version(current_version)
    if platform is None or current is None:
        raise HTTPException(422, "无效的平台或版本号")
    decision = await resolve_update(
        session, platform=platform, current=current, arch=arch, client_id=client_id,
        user_id=optional_user_id(request),
    )
    offer = decision.offer
    if offer is None or offer.artifact is None:
        return Response(status_code=204)
    return _tauri_json(request, offer, decision.min_version)


def _tauri_json(request: Request, offer: Offer, min_version: str | None) -> Response:
    r, a = offer.release, offer.artifact
    assert a is not None
    return JSONResponse({
        "version": r.version,
        "notes": r.notes,
        "pub_date": rfc3339(r.published_at),
        "url": _download_url(request, a),
        "signature": a.signature,
        # Extra fields (read from `Update.raw_json` by the desktop client).
        "force": offer.force,
        "min_version": min_version,
    })


@public_router.get("/download/{artifact_id}", name="download_release_artifact")
async def download_artifact(artifact_id: str, session: AsyncSession = Depends(get_session)) -> Response:
    artifact = await session.get(ClientReleaseArtifact, artifact_id)
    if artifact is None:
        raise HTTPException(404, "安装包不存在")
    await session.execute(
        update(ClientReleaseArtifact)
        .where(ClientReleaseArtifact.id == artifact_id)
        .values(download_count=ClientReleaseArtifact.download_count + 1)
    )
    await session.commit()
    if artifact.storage in OBJECT_BACKENDS:
        store = await oss.get_audio_store(artifact.storage)
        if store is None:
            raise HTTPException(503, f"安装包存放在 {artifact.storage}，但对应对象存储未配置")
        return RedirectResponse(store.presign_get(artifact.storage_key), 302, headers={"Cache-Control": "no-store"})
    path = Path(artifact.storage_key)
    if not path.is_file():
        raise HTTPException(404, "安装包文件不存在")
    return FileResponse(path, media_type=artifact.content_type or "application/octet-stream",
                        filename=artifact.file_name)
