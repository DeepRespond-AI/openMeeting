"""Client version strings: `x.y.z` with an optional `+build` (Flutter `1.2.0+12`)."""
from __future__ import annotations

import re

_VERSION = re.compile(r"^v?(\d{1,6})\.(\d{1,6})\.(\d{1,6})(?:\+(\d{1,9}))?$")

Version = tuple[int, int, int, int]


def parse_version(raw: str | None) -> Version:
    """`"1.2.3"` → (1, 2, 3, 0), `"1.2.3+45"` → (1, 2, 3, 45); ValueError when malformed."""
    m = _VERSION.match((raw or "").strip())
    if m is None:
        raise ValueError(f"无效的版本号：{raw!r}（格式应为 1.2.3 或 1.2.3+45）")
    major, minor, patch, build = m.groups()
    return int(major), int(minor), int(patch), int(build or 0)


def try_parse_version(raw: str | None) -> Version | None:
    try:
        return parse_version(raw)
    except ValueError:
        return None


def is_plain_version(raw: str) -> bool:
    """`x.y.z` without a build number (the release's build is a separate field)."""
    v = try_parse_version(raw)
    return v is not None and "+" not in raw


def release_version(version: str, build: int) -> Version:
    major, minor, patch, _ = parse_version(version)
    return major, minor, patch, build


def format_version(version: str, build: int) -> str:
    return f"{version}+{build}" if build else version
