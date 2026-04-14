from __future__ import annotations

import re
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
GAME_ROOT = PROJECT_ROOT / "Game"
UI_ROOT = GAME_ROOT / "UI"
SCENES_ROOT = PROJECT_ROOT / "scenes"
TESTS_ROOT = PROJECT_ROOT / "Tests"

DISPATCH_ALLOWED_FILE = PROJECT_ROOT / "Game" / "Application" / "game_flow_manager.gd"
CURRENT_NODE_INDEX_ALLOWED_FILES = {
    PROJECT_ROOT / "Game" / "Infrastructure" / "save_service.gd",
    PROJECT_ROOT / "Game" / "RuntimeState" / "map_runtime_state.gd",
    PROJECT_ROOT / "Game" / "RuntimeState" / "reward_state.gd",
    PROJECT_ROOT / "Game" / "RuntimeState" / "run_state.gd",
}
GET_RUN_STATE_CALL_FRAGMENT = r"(?:\b[a-zA-Z_][a-zA-Z0-9_]*\.)?_?get_run_state\s*\(\)"
RUNTIME_RUNSTATE_COMPATIBILITY_PATTERNS = [
    re.compile(
        r"\b[a-zA-Z_][a-zA-Z0-9_]*run_state[a-zA-Z0-9_]*\.(current_node_index|weapon_instance|consumable_slots|passive_slots|armor_instance|belt_instance)\b"
    ),
    re.compile(
        rf"{GET_RUN_STATE_CALL_FRAGMENT}\.(current_node_index|weapon_instance|consumable_slots|passive_slots|armor_instance|belt_instance)\b"
    ),
]
TEST_RUNSTATE_INVENTORY_COMPATIBILITY_PATTERNS = [
    re.compile(
        r"\b[a-zA-Z_][a-zA-Z0-9_]*run_state[a-zA-Z0-9_]*\.(weapon_instance|consumable_slots|passive_slots|armor_instance|belt_instance)\b"
    ),
    re.compile(
        rf"{GET_RUN_STATE_CALL_FRAGMENT}\.(weapon_instance|consumable_slots|passive_slots|armor_instance|belt_instance)\b"
    ),
]
SCENE_UI_RUNSTATE_TRUTH_WRITE_PATTERNS = [
    re.compile(
        r"\b[a-zA-Z_][a-zA-Z0-9_]*run_state[a-zA-Z0-9_]*\.(player_hp|hunger|gold|xp|current_level|stage_index)\s*="
    ),
    re.compile(
        rf"{GET_RUN_STATE_CALL_FRAGMENT}\.(player_hp|hunger|gold|xp|current_level|stage_index)\s*="
    ),
]
SCENE_UI_MAP_TRUTH_MUTATION_PATTERNS = [
    re.compile(
        r"\b[a-zA-Z_][a-zA-Z0-9_]*run_state[a-zA-Z0-9_]*\.map_runtime_state\.(move_to_node|mark_node_resolved|resolve_stage_key|save_support_node_runtime_state|set_pending_node)\s*\("
    ),
    re.compile(
        rf"{GET_RUN_STATE_CALL_FRAGMENT}\.map_runtime_state\.(move_to_node|mark_node_resolved|resolve_stage_key|save_support_node_runtime_state|set_pending_node)\s*\("
    ),
    re.compile(
        r"\b[a-zA-Z_][a-zA-Z0-9_]*map_runtime_state[a-zA-Z0-9_]*\.(move_to_node|mark_node_resolved|resolve_stage_key|save_support_node_runtime_state|set_pending_node)\s*\("
    ),
]
DISPATCH_CALL_PATTERN = re.compile(r"\bdispatch\s*\(")
CURRENT_NODE_INDEX_PATTERN = re.compile(r'"current_node_index"|current_node_index')


def iter_gd_files(*roots: Path) -> list[Path]:
    files: list[Path] = []
    for root in roots:
        if not root.is_dir():
            continue
        files.extend(sorted(root.rglob("*.gd")))
    return files


def validate_dispatch_usage() -> list[str]:
    errors: list[str] = []
    for path in iter_gd_files(GAME_ROOT, SCENES_ROOT, TESTS_ROOT):
        if path == DISPATCH_ALLOWED_FILE:
            continue

        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            if DISPATCH_CALL_PATTERN.search(line):
                rel_path = path.relative_to(PROJECT_ROOT).as_posix()
                errors.append(
                    f"{rel_path}:{line_number}: deprecated GameFlowManager.dispatch() should not gain new in-repo callers"
                )
    return errors


def validate_runstate_compatibility_usage() -> list[str]:
    errors: list[str] = []
    for path in iter_gd_files(GAME_ROOT, SCENES_ROOT):
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            for pattern in RUNTIME_RUNSTATE_COMPATIBILITY_PATTERNS:
                match = pattern.search(line)
                if match is None:
                    continue

                rel_path = path.relative_to(PROJECT_ROOT).as_posix()
                accessor_name = match.group(1)
                errors.append(
                    f"{rel_path}:{line_number}: runtime code should prefer the real owner over RunState.{accessor_name}"
                )
                break
    return errors


def validate_test_runstate_inventory_compatibility_usage() -> list[str]:
    errors: list[str] = []
    for path in iter_gd_files(TESTS_ROOT):
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            for pattern in TEST_RUNSTATE_INVENTORY_COMPATIBILITY_PATTERNS:
                match = pattern.search(line)
                if match is None:
                    continue

                rel_path = path.relative_to(PROJECT_ROOT).as_posix()
                accessor_name = match.group(1)
                errors.append(
                    f"{rel_path}:{line_number}: test code should prefer RunState.inventory_state over compatibility RunState.{accessor_name}"
                )
                break
    return errors


def validate_current_node_index_runtime_creep() -> list[str]:
    errors: list[str] = []
    for path in iter_gd_files(GAME_ROOT, SCENES_ROOT):
        if path in CURRENT_NODE_INDEX_ALLOWED_FILES:
            continue

        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            if not CURRENT_NODE_INDEX_PATTERN.search(line):
                continue

            rel_path = path.relative_to(PROJECT_ROOT).as_posix()
            errors.append(
                f"{rel_path}:{line_number}: runtime code should not reintroduce current_node_index outside explicit compatibility lanes"
            )
    return errors


def validate_scene_ui_truth_mutation_creep() -> list[str]:
    errors: list[str] = []
    for path in iter_gd_files(UI_ROOT, SCENES_ROOT):
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            for pattern in SCENE_UI_RUNSTATE_TRUTH_WRITE_PATTERNS:
                match = pattern.search(line)
                if match is None:
                    continue

                rel_path = path.relative_to(PROJECT_ROOT).as_posix()
                field_name = match.group(1)
                errors.append(
                    f"{rel_path}:{line_number}: scene/UI code should not write RunState.{field_name} directly; route gameplay truth through an Application-owned surface"
                )
                break

            for pattern in SCENE_UI_MAP_TRUTH_MUTATION_PATTERNS:
                match = pattern.search(line)
                if match is None:
                    continue

                rel_path = path.relative_to(PROJECT_ROOT).as_posix()
                method_name = match.group(1)
                errors.append(
                    f"{rel_path}:{line_number}: scene/UI code should not call MapRuntimeState.{method_name} directly; route gameplay truth through an Application-owned surface"
                )
                break
    return errors


def main() -> int:
    errors = []
    errors.extend(validate_dispatch_usage())
    errors.extend(validate_runstate_compatibility_usage())
    errors.extend(validate_test_runstate_inventory_compatibility_usage())
    errors.extend(validate_current_node_index_runtime_creep())
    errors.extend(validate_scene_ui_truth_mutation_creep())

    if errors:
        print("Architecture guard validation failed.", file=sys.stderr)
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Architecture guard validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
