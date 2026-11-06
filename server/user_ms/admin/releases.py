"""Client release management: versions, installer uploads, publishing with staged rollout,
the per-platform update policy and the version distribution of active clients."""
from __future__ import annotations

from datetime import timedelta
from typing import Literal

from fastapi import APIRouter, Depends, File, Form, HTTPException, Response, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from user_ms.db.models import ClientRelease, ClientReleaseArtifact, User, UserSession
from user_ms.db.session import get_session
from user_ms.updates import storage
from service_net.minio_store import OBJECT_BACKENDS
from service_net.direct_upload import UploadProof, UploadComplete, create_offer, read_ticket, confirm_object, cleanup_pending
from user_ms.config import get_settings
from user_ms.storage import oss
from user_ms.updates.policy import (
    DESKTOP_PLATFORMS,
    PLATFORM_ARCHES,
    PLATFORMS,
    PlatformPolicy,
    load_policy,
    save_policy,
)
from user_ms.updates.versions import format_version, is_plain_version, try_parse_version
from user_ms.utils import iso, new_uuid, utcnow

router = APIRouter(tags=["admin-releases"])

Platform = Literal["windows", "macos", "linux", "android", "ios"]
STATS_WINDOW = timedelta(days=30)
# Store links may be web pages or store deep links (market://, itms-apps://).
_URL_SCHEMES = ("https://", "http://", "market://", "itms-apps://", "appmarket://")


class ReleaseIn(BaseModel):
    platform: Platform
    version: str = Field(min_length=1, max_length=32)
    build: int = Field(0, ge=0)
    notes: str = ""
    force: bool = False
    rollout_percent: int = Field(100, ge=0, le=100)
    rollout_users: list[str] = Field(default_factory=list)


class ReleaseUpdate(BaseModel):
    version: str = Field(min_length=1, max_length=32)
    build: int = Field(0, ge=0)
    notes: str = ""
    force: bool = False
    rollout_percent: int = Field(100, ge=0, le=100)
    rollout_users: list[str] = Field(default_factory=list)


class PlatformPolicyIn(BaseModel):
    min_version: str = ""
    store_urls: dict[str, str] = Field(default_factory=dict)


def _artifact_dict(a: ClientReleaseArtifact) -> dict:
    return {
        "id": a.id,
        "arch": a.arch,
        "file_name": a.file_name,
        "size": a.size,
        "sha256": a.sha256,
        "signed": bool(a.signature),
        "storage": a.storage,
        "download_count": a.download_count,
        "created_at": iso(a.created_at),
    }


async def _release_dicts(session: AsyncSession, releases: list[ClientRelease]) -> list[dict]:
    ids = [r.id for r in releases]
    artifacts: dict[str, list[ClientReleaseArtifact]] = {}
    if ids:
        rows = (
            await session.execute(
                select(ClientReleaseArtifact)
                .where(ClientReleaseArtifact.release_id.in_(ids))
                .order_by(ClientReleaseArtifact.arch)
            )
        ).scalars().all()
        for a in rows:
            artifacts.setdefault(a.release_id, []).append(a)
    user_ids = {uid for r in releases for uid in (r.rollout_users or [])}
    users: dict[str, User] = {}
    if user_ids:
        users = {u.id: u for u in (await session.execute(select(User).where(User.id.in_(user_ids)))).scalars()}
    return [
        {
            "id": r.id,
            "platform": r.platform,
            "version": r.version,
            "build": r.build,
            "full_version": format_version(r.version, r.build),
            "notes": r.notes,
            "force": r.force,
            "status": r.status,
            "rollout_percent": r.rollout_percent,
            "rollout_users": [
                {"id": uid, "name": users[uid].name if uid in users else None,
                 "phone": users[uid].phone if uid in users else None}
                for uid in (r.rollout_users or [])
            ],
            "artifacts": [_artifact_dict(a) for a in artifacts.get(r.id, [])],
            "published_at": iso(r.published_at),
            "created_at": iso(r.created_at),
            "updated_at": iso(r.updated_at),
        }
        for r in releases
    ]


async def _release_dict(session: AsyncSession, r: ClientRelease) -> dict:
    return (await _release_dicts(session, [r]))[0]


async def _get(session: AsyncSession, release_id: str) -> ClientRelease:
    r = await session.get(ClientRelease, release_id)
    if r is None:
        raise HTTPException(404, "版本不存在")
    return r


def _check_version(version: str) -> str:
    version = version.strip()
    if not is_plain_version(version):
        raise HTTPException(422, "版本号格式应为 1.2.3（构建号单独填写）")
    return version


async def _clean_users(session: AsyncSession, user_ids: list[str]) -> list[str]:
    wanted = list(dict.fromkeys(u for u in user_ids if u))
    if not wanted:
        return []
    found = set((await session.execute(select(User.id).where(User.id.in_(wanted)))).scalars())
    return [u for u in wanted if u in found]


async def _commit_unique(session: AsyncSession) -> None:
    try:
        await session.commit()
    except IntegrityError as exc:
        await session.rollback()
        raise HTTPException(409, "该平台已存在相同的版本号和构建号") from exc


@router.get("/releases")
async def list_releases(platform: Platform | None = None, session: AsyncSession = Depends(get_session)) -> list[dict]:
    stmt = select(ClientRelease)
    if platform:
        stmt = stmt.where(ClientRelease.platform == platform)
    releases = list((await session.execute(stmt)).scalars().all())
    releases.sort(key=lambda r: (try_parse_version(r.version) or (0, 0, 0, 0), r.build), reverse=True)
    return await _release_dicts(session, releases)


@router.post("/releases", status_code=201)
async def create_release(body: ReleaseIn, session: AsyncSession = Depends(get_session)) -> dict:
    now = utcnow()
    r = ClientRelease(
        id=new_uuid(),
        platform=body.platform,
        version=_check_version(body.version),
        build=0 if body.platform in DESKTOP_PLATFORMS else body.build,
        notes=body.notes.strip(),
        force=body.force,
        status="draft",
        rollout_percent=body.rollout_percent,
        rollout_users=await _clean_users(session, body.rollout_users),
        created_at=now,
        updated_at=now,
    )
    session.add(r)
    await _commit_unique(session)
    return await _release_dict(session, r)


@router.put("/releases/{release_id}")
async def update_release(release_id: str, body: ReleaseUpdate, session: AsyncSession = Depends(get_session)) -> dict:
    r = await _get(session, release_id)
    version = _check_version(body.version)
    build = 0 if r.platform in DESKTOP_PLATFORMS else body.build
    if (version, build) != (r.version, r.build) and r.status != "draft":
        raise HTTPException(400, "已发布的版本不能修改版本号，请新建版本")
    r.version, r.build = version, build
    r.notes = body.notes.strip()
    r.force = body.force
    r.rollout_percent = body.rollout_percent
    r.rollout_users = await _clean_users(session, body.rollout_users)
    r.updated_at = utcnow()
    await _commit_unique(session)
    return await _release_dict(session, r)


@router.delete("/releases/{release_id}", status_code=204)
async def delete_release(release_id: str, session: AsyncSession = Depends(get_session)) -> Response:
    r = await _get(session, release_id)
    if r.status not in ("draft", "archived"):
        raise HTTPException(400, "只能删除草稿或已归档的版本")
    artifacts = (
        await session.execute(select(ClientReleaseArtifact).where(ClientReleaseArtifact.release_id == r.id))
    ).scalars().all()
    await session.delete(r)
    await session.commit()
    for a in artifacts:
        await storage.delete_package(a.storage, a.storage_key)
    await storage.delete_release_dir(release_id)
    return Response(status_code=204)


class DirectArtifactIn(UploadProof):
    arch: str = Field(min_length=1, max_length=32)
    signature: str | None = Field(default=None, max_length=8192)


def _check_artifact(release: ClientRelease, arch: str, signature: str | None) -> None:
    if not PLATFORM_ARCHES[release.platform]:
        raise HTTPException(400, "iOS 版本通过 App Store 分发，无需上传安装包")
    if arch not in PLATFORM_ARCHES[release.platform]:
        raise HTTPException(422, "该平台不支持此架构")
    if release.platform in DESKTOP_PLATFORMS and not (signature or "").strip():
        raise HTTPException(422, "桌面端更新包必须同时上传签名文件（.sig）")


@router.post("/releases/{release_id}/artifacts/uploads")
async def prepare_artifact_upload(release_id: str, body: DirectArtifactIn,
                                  session: AsyncSession = Depends(get_session)):
    release = await _get(session, release_id)
    _check_artifact(release, body.arch, body.signature)
    store = await oss.get_audio_store()
    if store is None:
        return {"mode": "proxy"}
    name = storage.safe_filename(body.file_name)
    return create_offer(store, get_settings().resolved_secret_key(), "admin", "release-artifact", release.id,
                        body, ["releases", release.id, body.arch], storage.content_type_for(name),
                        arch=body.arch, signature=(body.signature or "").strip() or None)


@router.post("/releases/{release_id}/artifacts/uploads/complete", status_code=201)
async def complete_artifact_upload(release_id: str, body: UploadComplete,
                                   session: AsyncSession = Depends(get_session)):
    claims = read_ticket(body.ticket, get_settings().resolved_secret_key(), "admin", "release-artifact", release_id)
    release = await _get(session, release_id)
    await session.refresh(release, with_for_update=True)
    _check_artifact(release, claims["extra"]["arch"], claims["extra"].get("signature"))
    existing = await session.get(ClientReleaseArtifact, claims["upload_id"])
    if existing is not None:
        return await _release_dict(session, release)
    store = await oss.get_audio_store(claims["backend"])
    await confirm_object(store, claims)
    old = (await session.execute(select(ClientReleaseArtifact).where(
        ClientReleaseArtifact.release_id == release_id, ClientReleaseArtifact.arch == claims["extra"]["arch"]
    ))).scalar_one_or_none()
    old_object = (old.storage, old.storage_key) if old else None
    if old:
        await session.delete(old)
        await session.flush()
    artifact = ClientReleaseArtifact(id=claims["upload_id"], release_id=release_id, arch=claims["extra"]["arch"],
        file_name=claims["file_name"], content_type=claims["content_type"], size=claims["size"], sha256=claims["sha256"],
        signature=claims["extra"].get("signature"), storage=store.backend, storage_key=claims["key"], created_at=utcnow())
    session.add(artifact)
    release.updated_at = utcnow()
    await session.commit()
    await cleanup_pending(store, claims)
    if old_object:
        await storage.delete_package(*old_object)
    return await _release_dict(session, release)


@router.post("/releases/{release_id}/artifacts", status_code=201)
async def upload_artifact(
    release_id: str,
    arch: str = Form(...),
    file: UploadFile = File(...),
    signature: UploadFile | None = File(None),
    session: AsyncSession = Depends(get_session),
) -> dict:
    r = await _get(session, release_id)
    allowed = PLATFORM_ARCHES[r.platform]
    if not allowed:
        raise HTTPException(400, "iOS 版本通过 App Store 分发，无需上传安装包")
    if arch not in allowed:
        raise HTTPException(422, f"该平台支持的架构：{', '.join(allowed)}")
    sig_text: str | None = None
    if r.platform in DESKTOP_PLATFORMS:
        raw = (await signature.read()).decode("utf-8", "replace").strip() if signature else ""
        if not raw:
            raise HTTPException(422, "桌面端更新包必须同时上传签名文件（.sig）")
        sig_text = raw

    async def chunks():
        while chunk := await file.read(1024 * 1024):
            yield chunk

    stored = await storage.store_package(r.id, arch, file.filename or "package", chunks())
    old = (
        await session.execute(
            select(ClientReleaseArtifact).where(
                ClientReleaseArtifact.release_id == r.id, ClientReleaseArtifact.arch == arch
            )
        )
    ).scalar_one_or_none()
    if old is not None:
        if old.storage in OBJECT_BACKENDS and (old.storage != stored.storage or old.storage_key != stored.key):
            await storage.delete_package(old.storage, old.storage_key)
        await session.delete(old)
        await session.flush()
    a = ClientReleaseArtifact(
        id=new_uuid(),
        release_id=r.id,
        arch=arch,
        file_name=stored.file_name,
        content_type=stored.content_type,
        size=stored.size,
        sha256=stored.sha256,
        signature=sig_text,
        storage=stored.storage,
        storage_key=stored.key,
        created_at=utcnow(),
    )
    session.add(a)
    r.updated_at = utcnow()
    await session.commit()
    return await _release_dict(session, r)


@router.delete("/releases/{release_id}/artifacts/{artifact_id}")
async def delete_artifact(release_id: str, artifact_id: str, session: AsyncSession = Depends(get_session)) -> dict:
    r = await _get(session, release_id)
    a = await session.get(ClientReleaseArtifact, artifact_id)
    if a is None or a.release_id != r.id:
        raise HTTPException(404, "安装包不存在")
    await session.delete(a)
    r.updated_at = utcnow()
    await session.commit()
    await storage.delete_package(a.storage, a.storage_key)
    return await _release_dict(session, r)


async def _set_status(session: AsyncSession, r: ClientRelease, status: str) -> dict:
    r.status = status
    r.updated_at = utcnow()
    if status == "published" and r.published_at is None:
        r.published_at = r.updated_at
    await session.commit()
    return await _release_dict(session, r)


@router.post("/releases/{release_id}/publish")
async def publish_release(release_id: str, session: AsyncSession = Depends(get_session)) -> dict:
    r = await _get(session, release_id)
    if r.status == "archived":
        raise HTTPException(400, "已归档的版本不能再发布")
    if r.platform in DESKTOP_PLATFORMS:
        count = (
            await session.execute(
                select(func.count()).where(ClientReleaseArtifact.release_id == r.id)
            )
        ).scalar_one()
        if count == 0:
            raise HTTPException(400, "请先上传安装包和签名文件再发布")
    return await _set_status(session, r, "published")


@router.post("/releases/{release_id}/pause")
async def pause_release(release_id: str, session: AsyncSession = Depends(get_session)) -> dict:
    r = await _get(session, release_id)
    if r.status != "published":
        raise HTTPException(400, "只有已发布的版本可以暂停")
    return await _set_status(session, r, "paused")


@router.post("/releases/{release_id}/archive")
async def archive_release(release_id: str, session: AsyncSession = Depends(get_session)) -> dict:
    r = await _get(session, release_id)
    return await _set_status(session, r, "archived")


@router.get("/releases/stats")
async def release_stats(session: AsyncSession = Depends(get_session)) -> dict:
    """Versions of sessions used within the last 30 days, per platform."""
    since = utcnow() - STATS_WINDOW
    rows = (
        await session.execute(
            select(UserSession.os, UserSession.app_version, func.count())
            .where(
                UserSession.revoked.is_(False),
                UserSession.last_used_at >= since,
                UserSession.app_version.is_not(None),
            )
            .group_by(UserSession.os, UserSession.app_version)
        )
    ).all()
    out: dict[str, list[dict]] = {p: [] for p in PLATFORMS}
    for os_name, version, count in rows:
        if os_name in out:
            out[os_name].append({"version": version, "count": count})
    for items in out.values():
        items.sort(key=lambda i: try_parse_version(i["version"]) or (0, 0, 0, 0), reverse=True)
    return out


@router.get("/update-policy")
async def get_update_policy() -> dict:
    policy = await load_policy()
    return {p: policy[p].as_dict() for p in PLATFORMS}


@router.put("/update-policy")
async def put_update_policy(body: dict[Platform, PlatformPolicyIn]) -> dict:
    policy = await load_policy()
    for platform, item in body.items():
        min_version = item.min_version.strip()
        if min_version and try_parse_version(min_version) is None:
            raise HTTPException(422, f"{platform} 的最低支持版本格式应为 1.2.3 或 1.2.3+45")
        urls: dict[str, str] = {}
        for channel, url in item.store_urls.items():
            channel, url = channel.strip().lower(), url.strip()
            if not channel or not url:
                continue
            if not url.startswith(_URL_SCHEMES):
                raise HTTPException(422, f"商店链接无效：{url}")
            urls[channel] = url
        policy[platform] = PlatformPolicy(min_version=min_version, store_urls=urls)
    await save_policy(policy)
    return {p: policy[p].as_dict() for p in PLATFORMS}
