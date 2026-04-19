from __future__ import annotations

import re
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
GAME_ROOT = PROJECT_ROOT / "Game"
UI_ROOT = GAME_ROOT / "UI"
APPLICATION_ROOT = GAME_ROOT / "Application"
INFRASTRUCTURE_ROOT = GAME_ROOT / "Infrastructure"
SCENES_ROOT = PROJECT_ROOT / "scenes"
TESTS_ROOT = PROJECT_ROOT / "Tests"
APP_BOOTSTRAP_FILE = APPLICATION_ROOT / "app_bootstrap.gd"
APP_BOOTSTRAP_PUBLIC_METHOD_LIMIT = 35
RUN_SESSION_COORDINATOR_FILE = APPLICATION_ROOT / "run_session_coordinator.gd"
RUN_SESSION_COORDINATOR_PUBLIC_METHOD_LIMIT = 21
COMBAT_INVENTORY_SLOT_BRIDGE_ALLOWED_FILES = {
    PROJECT_ROOT / "Game" / "RuntimeState" / "combat_state.gd",
    PROJECT_ROOT / "Game" / "UI" / "inventory_presenter.gd",
}
RUN_SUMMARY_CLEANUP_ALLOWED_FILES = {
    PROJECT_ROOT / "Game" / "UI" / "run_summary_cleanup_helper.gd",
}
HOTSPOT_FILE_LINE_LIMITS = {
    PROJECT_ROOT / "Game" / "RuntimeState" / "map_runtime_state.gd": 2397,
    PROJECT_ROOT / "scenes" / "combat.gd": 1200,
    PROJECT_ROOT / "scenes" / "map_explore.gd": 1967,
    PROJECT_ROOT / "Game" / "UI" / "map_board_composer_v2.gd": 1258,
    PROJECT_ROOT / "Game" / "Infrastructure" / "save_service.gd": 700,
    PROJECT_ROOT / "Game" / "Infrastructure" / "save_service_legacy_loader.gd": 500,
    PROJECT_ROOT / "Game" / "Application" / "inventory_actions.gd": 1087,
    PROJECT_ROOT / "Game" / "Application" / "run_session_coordinator.gd": 1018,
    PROJECT_ROOT / "Game" / "RuntimeState" / "inventory_state.gd": 1060,
    PROJECT_ROOT / "Game" / "RuntimeState" / "support_interaction_state.gd": 976,
    PROJECT_ROOT / "Game" / "UI" / "combat_presenter.gd": 845,
    PROJECT_ROOT / "Game" / "UI" / "safe_menu_overlay.gd": 645,
    PROJECT_ROOT / "Game" / "Application" / "combat_flow.gd": 764,
    PROJECT_ROOT / "Game" / "UI" / "inventory_presenter.gd": 753,
}

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
COMBAT_STATE_ACTIVE_SLOT_WRITE_PATTERNS = [
    re.compile(
        r"\b[a-zA-Z_][a-zA-Z0-9_]*combat_state[a-zA-Z0-9_]*\.(active_weapon_slot_id|active_left_hand_slot_id|active_armor_slot_id|active_belt_slot_id)\s*="
    ),
]
RUN_SUMMARY_CARD_WORKAROUND_PATTERNS = [
    re.compile(r'\bfind_children\s*\(\s*"RunSummaryCard"'),
]
DISPATCH_CALL_PATTERN = re.compile(r"\bdispatch\s*\(")
CURRENT_NODE_INDEX_PATTERN = re.compile(r'"current_node_index"|current_node_index')
PUBLIC_FUNC_PATTERN = re.compile(r"^func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(")
APPLICATION_INFRASTRUCTURE_PRESENTATION_NODE_PATTERN = re.compile(
    r'"[^"\n]*(RunSummaryCard|ActionContextLabel|EventOverlay|SupportOverlay|RewardOverlay|LevelUpOverlay|HpStatusLabel|HungerStatusLabel|DurabilityStatusLabel|GoldStatusValueLabel|XpProgressBar|XpLabel)[^"\n]*"'
)


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
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            if DISPATCH_CALL_PATTERN.search(line):
                rel_path = path.relative_to(PROJECT_ROOT).as_posix()
                errors.append(
                    f"{rel_path}:{line_number}: deprecated GameFlowManager.dispatch() should not exist or regain in-repo usage"
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


def validate_combat_inventory_slot_bridge_creep() -> list[str]:
    errors: list[str] = []
    for path in iter_gd_files(GAME_ROOT, SCENES_ROOT):
        if path in COMBAT_INVENTORY_SLOT_BRIDGE_ALLOWED_FILES:
            continue

        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            for pattern in COMBAT_STATE_ACTIVE_SLOT_WRITE_PATTERNS:
                match = pattern.search(line)
                if match is None:
                    continue

                rel_path = path.relative_to(PROJECT_ROOT).as_posix()
                slot_name = match.group(1)
                errors.append(
                    f"{rel_path}:{line_number}: combat inventory slot-id compatibility writes like CombatState.{slot_name} should stay inside explicit compatibility lanes"
                )
                break
    return errors


def validate_run_summary_cleanup_workaround_creep() -> list[str]:
    errors: list[str] = []
    for path in iter_gd_files(GAME_ROOT, SCENES_ROOT):
        if path in RUN_SUMMARY_CLEANUP_ALLOWED_FILES:
            continue

        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            for pattern in RUN_SUMMARY_CARD_WORKAROUND_PATTERNS:
                if pattern.search(line) is None:
                    continue

                rel_path = path.relative_to(PROJECT_ROOT).as_posix()
                errors.append(
                    f"{rel_path}:{line_number}: stale RunSummaryCard tree-scan workarounds should stay trapped inside the explicit cleanup helper"
                )
                break
    return errors


def validate_application_infrastructure_presentation_coupling() -> list[str]:
    errors: list[str] = []
    for path in iter_gd_files(APPLICATION_ROOT, INFRASTRUCTURE_ROOT):
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            match = APPLICATION_INFRASTRUCTURE_PRESENTATION_NODE_PATTERN.search(line)
            if match is None:
                continue

            rel_path = path.relative_to(PROJECT_ROOT).as_posix()
            token_name = match.group(1)
            errors.append(
                f"{rel_path}:{line_number}: Application/Infrastructure code should not target presentation node identifiers like {token_name}; keep scene-shell details inside scene/UI owners"
            )
    return errors


def public_method_names(path: Path) -> list[str]:
    method_names: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        match = PUBLIC_FUNC_PATTERN.search(line)
        if match is None:
            continue
        method_name = match.group(1)
        if method_name.startswith("_"):
            continue
        method_names.append(method_name)
    return method_names


def validate_public_method_budget(path: Path, public_method_limit: int, owner_name: str) -> list[str]:
    errors: list[str] = []
    method_names = public_method_names(path)
    public_method_count = len(method_names)
    if public_method_count <= public_method_limit:
        return errors

    try:
        display_path = path.relative_to(PROJECT_ROOT).as_posix()
    except ValueError:
        display_path = str(path)

    errors.append(
        f"{display_path}: "
        f"{owner_name} public method count grew to {public_method_count} "
        f"(limit {public_method_limit}). "
        f"{owner_name} is a facade; extract or escalate instead of widening its convenience gameplay surface."
    )
    return errors


def validate_hotspot_file_growth() -> list[str]:
    errors: list[str] = []
    for path, line_limit in HOTSPOT_FILE_LINE_LIMITS.items():
        if not path.is_file():
            continue

        line_count = len(path.read_text(encoding="utf-8").splitlines())
        if line_count <= line_limit:
            continue

        try:
            display_path = path.relative_to(PROJECT_ROOT).as_posix()
        except ValueError:
            display_path = str(path)

        errors.append(
            f"{display_path}: "
            f"hotspot file grew to {line_count} lines "
            f"(limit {line_limit}). "
            f"This slice is extraction-first; shrink or explicitly escalate instead of widening the hotspot."
        )
    return errors


def validate_app_bootstrap_public_surface() -> list[str]:
    return validate_public_method_budget(
        APP_BOOTSTRAP_FILE,
        APP_BOOTSTRAP_PUBLIC_METHOD_LIMIT,
        "AppBootstrap",
    )


def validate_run_session_coordinator_public_surface() -> list[str]:
    return validate_public_method_budget(
        RUN_SESSION_COORDINATOR_FILE,
        RUN_SESSION_COORDINATOR_PUBLIC_METHOD_LIMIT,
        "RunSessionCoordinator",
    )


def main() -> int:
    errors = []
    errors.extend(validate_dispatch_usage())
    errors.extend(validate_runstate_compatibility_usage())
    errors.extend(validate_test_runstate_inventory_compatibility_usage())
    errors.extend(validate_current_node_index_runtime_creep())
    errors.extend(validate_scene_ui_truth_mutation_creep())
    errors.extend(validate_combat_inventory_slot_bridge_creep())
    errors.extend(validate_run_summary_cleanup_workaround_creep())
    errors.extend(validate_application_infrastructure_presentation_coupling())
    errors.extend(validate_app_bootstrap_public_surface())
    errors.extend(validate_run_session_coordinator_public_surface())
    errors.extend(validate_hotspot_file_growth())

    if errors:
        print("Architecture guard validation failed.", file=sys.stderr)
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Architecture guard validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
