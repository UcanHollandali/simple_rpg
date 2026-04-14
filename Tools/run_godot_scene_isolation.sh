#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $(basename "$0") <scene_path> [quit_after_seconds]" >&2
  exit 1
fi

scene_input="$1"
quit_after="${2:-2}"

get_godot_executable() {
  local candidate

  for candidate in "${GODOT_EXECUTABLE:-}" "${GODOT_BIN:-}" "${GODOT:-}"; do
    if [[ -n "${candidate}" && -x "${candidate}" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  for candidate in godot godot4; do
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return 0
    fi
  done

  for candidate in \
    "/Applications/Godot.app/Contents/MacOS/Godot" \
    "/Applications/Godot_mono.app/Contents/MacOS/Godot" \
    "/opt/homebrew/bin/godot" \
    "/usr/local/bin/godot"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  echo "Godot executable not found. Set GODOT_EXECUTABLE or install Godot." >&2
  return 1
}

assert_no_running_godot() {
  local running=""

  if command -v pgrep >/dev/null 2>&1; then
    running="$(pgrep -ifl godot || true)"
  else
    running="$(ps aux | grep -i '[g]odot' || true)"
  fi

  if [[ -n "$running" ]]; then
    echo "Godot appears to already be running. Close all Godot editor/headless processes before using scene isolation." >&2
    echo "Concurrent Godot instances can fail saving editor settings and crash on Windows." >&2
    echo "$running" >&2
    exit 1
  fi
}

resolve_scene_resource() {
  local project_root="$1"
  local input_path="$2"
  local file_path=""
  local relative_path=""

  if [[ "$input_path" == res://* ]]; then
    relative_path="${input_path#res://}"
    file_path="$project_root/$relative_path"
  else
    if [[ "$input_path" = /* ]]; then
      file_path="$input_path"
    else
      file_path="$project_root/$input_path"
    fi

    file_path="$(cd "$(dirname "$file_path")" && pwd)/$(basename "$file_path")"
    if [[ "$file_path" != "$project_root/"* ]]; then
      echo "Scene path must be inside the project root: $file_path" >&2
      return 1
    fi
    relative_path="${file_path#$project_root/}"
  fi

  if [[ ! -f "$file_path" ]]; then
    echo "Scene not found: $input_path" >&2
    return 1
  fi

  printf 'res://%s\n' "${relative_path//\\//}"
}

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
assert_no_running_godot
godot_exe="$(get_godot_executable)"
scene_resource="$(resolve_scene_resource "$project_root" "$scene_input")"

echo "Using Godot executable: $godot_exe"
echo "Running import step before isolated scene smoke check..."
"$godot_exe" --headless --path "$project_root" --import

echo "Running isolated scene smoke check for $scene_resource"
"$godot_exe" --headless --path "$project_root" --quit-after "$quit_after" "$scene_resource"

echo "Isolated scene smoke check passed for $scene_resource"
