#!/bin/bash
# Sourced by the packaging scripts. Update packages (*.app.tar.gz, *-setup.exe, *.AppImage + .sig)
# must be signed with the private key matching `plugins.updater.pubkey` in src-tauri/tauri.conf.json,
# otherwise installed clients reject them. Reads TAURI_SIGNING_PRIVATE_KEY(_PASSWORD) from the
# environment or from frontend/.env (never committed).

if [ -z "$TAURI_SIGNING_PRIVATE_KEY" ] && [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
fi

if [ -z "$TAURI_SIGNING_PRIVATE_KEY" ]; then
    echo "❌ TAURI_SIGNING_PRIVATE_KEY is not set."
    echo "   Put the updater signing key (file path or key content) and its password into frontend/.env:"
    echo "     TAURI_SIGNING_PRIVATE_KEY=~/.tauri/dr-meeting.key"
    echo "     TAURI_SIGNING_PRIVATE_KEY_PASSWORD=..."
    echo "   (generate once with: pnpm tauri signer generate -w ~/.tauri/dr-meeting.key)"
    exit 1
fi
