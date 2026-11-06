#!/usr/bin/env bash
# Runs a flutter/dart command while holding a project-wide lock, so parallel
# work never runs two builds (shared build/, .dart_tool/) at the same time.
# Usage: tool/locked_build.sh flutter build apk --debug
set -euo pipefail
cd "$(dirname "$0")/.."
LOCK="${TMPDIR:-/tmp}/meeting-mobile-build.lock"
until mkdir "$LOCK" 2>/dev/null; do
  echo "waiting for build lock ($LOCK)..." >&2
  sleep 5
done
trap 'rmdir "$LOCK"' EXIT
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
"$@"
