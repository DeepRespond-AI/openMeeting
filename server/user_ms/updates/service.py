"""Which release a client should be offered (staged rollout, minimum version, store channels)."""
from __future__ import annotations

import hashlib
from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from user_ms.db.models import ClientRelease, ClientReleaseArtifact
from user_ms.updates.policy import (
    APPSTORE_CHANNEL,
    DESKTOP_PLATFORMS,
    DIRECT_CHANNEL,
    PlatformPolicy,
    load_policy,
)
from user_ms.updates.versions import Version, release_version, try_parse_version

PUBLISHED = "published"


@dataclass(frozen=True)
class Offer:
    release: ClientRelease
    # Package to download (desktop, Android direct); None when the update goes through a store.
    artifact: ClientReleaseArtifact | None
    store_url: str | None
    force: bool


@dataclass(frozen=True)
class UpdateDecision:
    offer: Offer | None
    min_version: str | None


def rollout_bucket(release_id: str, client_id: str) -> int:
    """Stable 0..99 bucket of a device for one release (raising the percentage only adds devices)."""
    digest = hashlib.sha256(f"{release_id}:{client_id}".encode()).hexdigest()
    return int(digest[:8], 16) % 100


def in_rollout(release: ClientRelease, client_id: str | None, user_id: str | None) -> bool:
    if user_id and user_id in (release.rollout_users or []):
        return True
    percent = max(0, min(100, release.rollout_percent))
    if percent >= 100:
        return True
    if not client_id or percent <= 0:
        return False
    return rollout_bucket(release.id, client_id) < percent


def _matching_artifact(artifacts: list[ClientReleaseArtifact], arch: str | None) -> ClientReleaseArtifact | None:
    wanted = (arch or "").lower()
    by_arch = {a.arch: a for a in artifacts}
    return by_arch.get(wanted) or by_arch.get("universal") or by_arch.get("any")


def _delivery(
    platform: str,
    channel: str,
    policy: PlatformPolicy,
    artifacts: list[ClientReleaseArtifact],
    arch: str | None,
) -> tuple[ClientReleaseArtifact | None, str | None] | None:
    """(artifact, store_url) for this client, or None when the release cannot reach it."""
    if platform == "ios":
        url = policy.store_urls.get(APPSTORE_CHANNEL)
        return (None, url) if url else None
    if platform == "android" and channel != DIRECT_CHANNEL:
        url = policy.store_urls.get(channel)
        return (None, url) if url else None
    artifact = _matching_artifact(artifacts, arch)
    if artifact is None:
        return None
    if platform in DESKTOP_PLATFORMS and not artifact.signature:
        return None
    return artifact, None


async def resolve_update(
    session: AsyncSession,
    *,
    platform: str,
    current: Version,
    arch: str | None = None,
    channel: str | None = None,
    client_id: str | None = None,
    user_id: str | None = None,
) -> UpdateDecision:
    """The newest published release above `current` this client is in the rollout of.

    Below the policy's minimum version the rollout is ignored: the client gets a release at or
    above the minimum and must install it. `force` is also set when any release the client
    skips over (and is in the rollout of) is marked as forced.
    """
    channel = (channel or DIRECT_CHANNEL).lower()
    policy = (await load_policy())[platform]
    min_version = try_parse_version(policy.min_version) if policy.min_version else None
    below_min = min_version is not None and current < min_version

    releases = (
        await session.execute(
            select(ClientRelease).where(ClientRelease.platform == platform, ClientRelease.status == PUBLISHED)
        )
    ).scalars().all()
    newer = [r for r in releases if (v := _key(r)) is not None and v > current]
    newer.sort(key=lambda r: _key(r), reverse=True)  # type: ignore[arg-type, return-value]
    if not newer:
        return UpdateDecision(None, policy.min_version or None)

    artifacts: dict[str, list[ClientReleaseArtifact]] = {}
    rows = (
        await session.execute(
            select(ClientReleaseArtifact).where(ClientReleaseArtifact.release_id.in_([r.id for r in newer]))
        )
    ).scalars().all()
    for a in rows:
        artifacts.setdefault(a.release_id, []).append(a)

    deliverable: list[tuple[ClientRelease, ClientReleaseArtifact | None, str | None]] = []
    for r in newer:
        delivery = _delivery(platform, channel, policy, artifacts.get(r.id, []), arch)
        if delivery is not None:
            deliverable.append((r, *delivery))

    eligible = [d for d in deliverable if in_rollout(d[0], client_id, user_id)]
    chosen = eligible[0] if eligible else None
    if below_min and (chosen is None or _key(chosen[0]) < min_version):  # type: ignore[operator]
        chosen = next((d for d in deliverable if _key(d[0]) >= min_version), chosen)  # type: ignore[operator]
    if chosen is None:
        return UpdateDecision(None, policy.min_version or None)

    release, artifact, store_url = chosen
    chosen_key = _key(release)
    force = below_min or any(r.force for r, _, _ in eligible if _key(r) <= chosen_key)  # type: ignore[operator]
    return UpdateDecision(Offer(release, artifact, store_url, force), policy.min_version or None)


def _key(release: ClientRelease) -> Version | None:
    try:
        return release_version(release.version, release.build)
    except ValueError:
        return None
