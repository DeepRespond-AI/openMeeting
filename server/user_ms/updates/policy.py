"""Per-platform update policy (system_settings `client_update_policy`): minimum supported
version and store links (`appstore` for iOS, Android store channels such as `huawei`)."""
from __future__ import annotations

from dataclasses import dataclass, field

from user_ms.db.settings_store import get_setting, set_setting

POLICY_KEY = "client_update_policy"

PLATFORMS = ("windows", "macos", "linux", "android", "ios")
DESKTOP_PLATFORMS = ("windows", "macos", "linux")

# Architectures an installer can be uploaded for, per platform (`any` = one package for all).
PLATFORM_ARCHES: dict[str, tuple[str, ...]] = {
    "windows": ("x86_64", "aarch64"),
    "macos": ("aarch64", "x86_64", "universal"),
    "linux": ("x86_64", "aarch64"),
    "android": ("any",),
    "ios": (),
}

# Android build without a store: the app downloads and installs the APK itself.
DIRECT_CHANNEL = "direct"
APPSTORE_CHANNEL = "appstore"


@dataclass
class PlatformPolicy:
    min_version: str = ""
    store_urls: dict[str, str] = field(default_factory=dict)

    def as_dict(self) -> dict:
        return {"min_version": self.min_version, "store_urls": dict(self.store_urls)}


async def load_policy() -> dict[str, PlatformPolicy]:
    raw = await get_setting(POLICY_KEY, None)
    raw = raw if isinstance(raw, dict) else {}
    out: dict[str, PlatformPolicy] = {}
    for platform in PLATFORMS:
        item = raw.get(platform) if isinstance(raw.get(platform), dict) else {}
        urls = item.get("store_urls") if isinstance(item.get("store_urls"), dict) else {}
        out[platform] = PlatformPolicy(
            min_version=str(item.get("min_version") or ""),
            store_urls={str(k): str(v) for k, v in urls.items() if v},
        )
    return out


async def save_policy(policy: dict[str, PlatformPolicy]) -> None:
    await set_setting(POLICY_KEY, {p: policy[p].as_dict() for p in PLATFORMS if p in policy})
