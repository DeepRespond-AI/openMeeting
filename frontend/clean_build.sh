#!/bin/bash

# Exit on error
set -e
cd -- "$(dirname -- "$0")"

# Add log level selector with default to INFO
LOG_LEVEL=${1:-info}

case $LOG_LEVEL in
    info|debug|trace)
        export RUST_LOG=$LOG_LEVEL
        ;;
    *)
        echo "Invalid log level: $LOG_LEVEL. Valid options: info, debug, trace"
        exit 1
        ;;
esac

# Update packages must be signed (fails early without the key).
source "scripts/require-signing-key.sh"

echo "Installing dependencies..."
pnpm install --frozen-lockfile

# Set environment variables for the build

echo "Building Tauri app..."
pnpm run tauri build

