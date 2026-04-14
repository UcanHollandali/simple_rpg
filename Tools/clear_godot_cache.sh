#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cache_dir="$project_root/.godot"

if pgrep -if "godot" >/dev/null 2>&1; then
  echo "Godot appears to be running. Close all Godot processes before clearing cache." >&2
  exit 1
fi

if [[ ! -d "$cache_dir" ]]; then
  echo "No .godot cache directory found at: $cache_dir"
  exit 0
fi

rm -rf "$cache_dir"
echo "Cleared Godot cache: $cache_dir"
