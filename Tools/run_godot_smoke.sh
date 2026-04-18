#!/usr/bin/env bash
set -euo pipefail

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
    echo "Godot appears to already be running. Close all Godot editor/headless processes before using smoke helpers." >&2
    echo "Concurrent Godot instances can fail saving editor settings and crash on Windows." >&2
    echo "$running" >&2
    exit 1
  fi
}

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
assert_no_running_godot
godot_exe="$(get_godot_executable)"

echo "Using Godot executable: $godot_exe"
echo "Running project import smoke check..."
"$godot_exe" --headless --path "$project_root" --import

while IFS= read -r -d '' script_file; do
  relative_path="${script_file#$project_root/}"
  resource_path="res://${relative_path//\\//}"
  echo "Parsing $resource_path"
  "$godot_exe" --headless --path "$project_root" --script "$resource_path" --check-only
done < <(find "$project_root" -type f -name "*.gd" ! -path "$project_root/.godot/*" ! -path "$project_root/_godot_profile/*" -print0 | sort -z)

echo "Godot smoke check passed."
