#!/bin/bash

# Exit on error
set -e
cd -- "$(dirname -- "$0")"

# Update packages must be signed (fails early without the key).
source "scripts/require-signing-key.sh"

echo "Installing dependencies..."
pnpm install --frozen-lockfile

echo "Building Tauri app..."
pnpm tauri build

target_dir="$(cargo metadata --no-deps --format-version 1 | node -e 'let s="";process.stdin.on("data",c=>s+=c);process.stdin.on("end",()=>process.stdout.write(JSON.parse(s).target_directory));')"
bundle_dir="$target_dir/release/bundle"
echo "App packaging complete! Check $bundle_dir for the packaged app."
echo "Upload the update package and its .sig in the admin console (版本发布):"
ls "$bundle_dir"/*/*.sig 2>/dev/null || true
