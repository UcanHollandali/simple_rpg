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
DOCS_ROOT = PROJECT_ROOT / "Docs"
DOCS_ARCHIVE_ROOT = DOCS_ROOT / "Archive"
HANDOFF_FILE = DOCS_ROOT / "HANDOFF.md"
ROADMAP_FILE = DOCS_ROOT / "ROADMAP.md"
APP_BOOTSTRAP_FILE = APPLICATION_ROOT / "app_bootstrap.gd"
APP_BOOTSTRAP_PUBLIC_METHOD_LIMIT = 35
APP_BOOTSTRAP_ALLOWED_PUBLIC_METHODS = {
    "get_flow_manager",
    "get_run_state",
    "get_map_runtime_state",
    "get_reward_state",
    "get_level_up_state",
    "get_event_state",
    "get_support_interaction_state",
    "build_combat_setup_data",
    "save_game",
    "load_game",
    "build_save_snapshot",
    "restore_from_snapshot",
    "apply_fullscreen_mode",
    "apply_ui_scale_to_active_scene",
    "apply_resolution_by_index",
    "has_save_game",
    "delete_save_game",
    "reset_run_state_for_new_run",
    "ensure_run_state_initialized",
    "get_last_run_result",
    "choose_move_to_node",
    "toggle_inventory_equipment",
    "move_inventory_slot",
    "use_inventory_consumable",
    "resolve_pending_node",
    "choose_reward_option",
    "choose_event_option",
    "resolve_combat_result",
    "choose_level_up_option",
    "choose_support_action",
    "finish_boot_to_main_menu",
}
APP_BOOTSTRAP_LOOKUP_ALLOWED_FILES = {
    PROJECT_ROOT / "Game" / "Infrastructure" / "scene_router.gd",
    PROJECT_ROOT / "Game" / "UI" / "map_overlay_director.gd",
    PROJECT_ROOT / "scenes" / "combat.gd",
    PROJECT_ROOT / "scenes" / "event.gd",
    PROJECT_ROOT / "scenes" / "level_up.gd",
    PROJECT_ROOT / "scenes" / "main.gd",
    PROJECT_ROOT / "scenes" / "main_menu.gd",
    PROJECT_ROOT / "scenes" / "map_explore.gd",
    PROJECT_ROOT / "scenes" / "node_resolve.gd",
    PROJECT_ROOT / "scenes" / "reward.gd",
    PROJECT_ROOT / "scenes" / "run_end.gd",
    PROJECT_ROOT / "scenes" / "stage_transition.gd",
    PROJECT_ROOT / "scenes" / "support_interaction.gd",
}
RUN_SESSION_COORDINATOR_FILE = APPLICATION_ROOT / "run_session_coordinator.gd"
RUN_SESSION_COORDINATOR_PUBLIC_METHOD_LIMIT = 21
COMMAND_EVENT_CATALOG_FILE = DOCS_ROOT / "COMMAND_EVENT_CATALOG.md"
GAME_FLOW_STATE_MACHINE_FILE = DOCS_ROOT / "GAME_FLOW_STATE_MACHINE.md"
MAP_CONTRACT_FILE = DOCS_ROOT / "MAP_CONTRACT.md"
COMBAT_INVENTORY_SLOT_BRIDGE_ALLOWED_FILES = {PROJECT_ROOT / "Game" / "RuntimeState" / "combat_state.gd"}
RUN_SUMMARY_CLEANUP_ALLOWED_FILES = {PROJECT_ROOT / "Game" / "UI" / "run_summary_cleanup_helper.gd"}
HOTSPOT_FILE_LINE_LIMITS = {
    PROJECT_ROOT / "Game" / "RuntimeState" / "map_runtime_state.gd": 2350,
    PROJECT_ROOT / "scenes" / "combat.gd": 1200,
    PROJECT_ROOT / "scenes" / "map_explore.gd": 1200,
    PROJECT_ROOT / "scenes" / "event.gd": 640,
    PROJECT_ROOT / "scenes" / "reward.gd": 575,
    PROJECT_ROOT / "scenes" / "support_interaction.gd": 575,
    PROJECT_ROOT / "Game" / "UI" / "map_board_composer_v2.gd": 1000,
    PROJECT_ROOT / "Game" / "UI" / "temp_screen_theme.gd": 1000,
    PROJECT_ROOT / "Game" / "UI" / "map_explore_scene_ui.gd": 850,
    PROJECT_ROOT / "Game" / "UI" / "combat_scene_ui.gd": 575,
    PROJECT_ROOT / "Game" / "UI" / "map_board_style.gd": 725,
    PROJECT_ROOT / "Game" / "UI" / "map_board_canvas.gd": 620,
    PROJECT_ROOT / "Game" / "Infrastructure" / "save_service.gd": 700,
    PROJECT_ROOT / "Game" / "Infrastructure" / "save_service_legacy_loader.gd": 500,
    PROJECT_ROOT / "Game" / "Application" / "inventory_actions.gd": 320,
    PROJECT_ROOT / "Game" / "Application" / "run_session_coordinator.gd": 800,
    PROJECT_ROOT / "Game" / "RuntimeState" / "inventory_state.gd": 1060,
    PROJECT_ROOT / "Game" / "RuntimeState" / "support_interaction_state.gd": 976,
    PROJECT_ROOT / "Game" / "UI" / "map_route_binding.gd": 980,
    PROJECT_ROOT / "Game" / "UI" / "combat_presenter.gd": 845,
    PROJECT_ROOT / "Game" / "UI" / "safe_menu_overlay.gd": 645,
    PROJECT_ROOT / "Game" / "Application" / "combat_flow.gd": 764,
    PROJECT_ROOT / "Game" / "UI" / "inventory_presenter.gd": 753,
    PROJECT_ROOT / "Tests" / "test_map_runtime_state.gd": 2450,
    PROJECT_ROOT / "Tests" / "test_phase2_loop.gd": 1200,
    PROJECT_ROOT / "Tests" / "test_map_board_composer_v2.gd": 1175,
    PROJECT_ROOT / "Tests" / "test_map_explore_presenter.gd": 975,
    PROJECT_ROOT / "Tools" / "validate_content.py": 3000,
    PROJECT_ROOT / "Tools" / "validate_architecture_guards.py": 800,
    PROJECT_ROOT / "Tools" / "godot_windows_common.ps1": 380,
}
ACTIVE_DOC_LINE_LIMITS = {HANDOFF_FILE: 360, ROADMAP_FILE: 240}

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
RUN_SUMMARY_CARD_WORKAROUND_PATTERNS = [re.compile(r'\bfind_children\s*\(\s*"RunSummaryCard"')]
DISPATCH_CALL_PATTERN = re.compile(r"\bdispatch\s*\(")
CURRENT_NODE_INDEX_PATTERN = re.compile(r'"current_node_index"|current_node_index')
PUBLIC_FUNC_PATTERN = re.compile(r"^func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(")
APP_BOOTSTRAP_LOOKUP_PATTERN = re.compile(r'["\']/root/AppBootstrap["\']')
APPLICATION_INFRASTRUCTURE_PRESENTATION_NODE_PATTERN = re.compile(
    r'"[^"\n]*(RunSummaryCard|ActionContextLabel|EventOverlay|SupportOverlay|RewardOverlay|LevelUpOverlay|HpStatusLabel|HungerStatusLabel|DurabilityStatusLabel|GoldStatusValueLabel|XpProgressBar|XpLabel)[^"\n]*"'
)
STALE_WRAPPER_DEFINITIONS = {
    GAME_ROOT / "Application" / "game_flow_manager.gd": "transition_to",
    GAME_ROOT / "Infrastructure" / "save_service.gd": "is_supported_save_state_now",
}
REQUIRED_COMMAND_EVENT_CATALOG_ENTRIES = (
    "CombatFlow.turn_phase_resolved", "BossPhaseChanged", "TechniqueUsed", "SwapHand",
    "AppBootstrap.toggle_inventory_equipment", "AppBootstrap.move_inventory_slot",
    "AppBootstrap.use_inventory_consumable", "AppBootstrap.has_save_game", "AppBootstrap.delete_save_game",
)
NODE_RESOLVE_CONTRACT_REQUIRED_FRAGMENTS = {
    GAME_FLOW_STATE_MACHINE_FILE: (
        "generic pending-node fallback can still route `MapExplore -> NodeResolve`",
        "behavior-changing removal of that fallback requires a dedicated flow audit",
    ),
    MAP_CONTRACT_FILE: (
        "generic pending-node fallback and legacy-compatible pending-node restore can still route into it",
        "behavior-changing removal of that live fallback still requires a dedicated flow audit",
    ),
    RUN_SESSION_COORDINATOR_FILE: (
        "map_runtime_state.set_pending_node(target_node_id)",
        "_request_transition(FlowStateScript.Type.NODE_RESOLVE)",
        "return FlowStateScript.Type.NODE_RESOLVE",
    ),
}
RETIRED_GATE_WARDEN_TOKEN = "gate_warden"
RETIRED_GATE_WARDEN_ALLOWED_FILES = {
    DOCS_ROOT / "ROADMAP.md",
    DOCS_ROOT / "Promts" / "01_foundation_fastlane.md",
}
RETIRED_GATE_WARDEN_SCAN_ROOTS = (
    DOCS_ROOT,
    GAME_ROOT,
    PROJECT_ROOT / "scenes",
    TESTS_ROOT,
    PROJECT_ROOT / "ContentDefinitions",
    PROJECT_ROOT / "AssetManifest",
    PROJECT_ROOT / "Assets",
    PROJECT_ROOT / "SourceArt",
)
RETIRED_GATE_WARDEN_TEXT_SUFFIXES = {
    ".csv",
    ".gd",
    ".import",
    ".json",
    ".md",
    ".tscn",
    ".txt",
    ".uid",
}
TYPED_REFLECTION_REGRESSION_FRAGMENTS = {
    PROJECT_ROOT / "Game" / "Core" / "combat_resolver.gd": (
        'has_method("refresh_boss_phase_from_enemy_hp")',
    ),
    PROJECT_ROOT / "Game" / "UI" / "map_explore_presenter.gd": (
        'has_method("get_hamlet_personality")',
        '.call("get_hamlet_personality"',
        'has_method("build_side_quest_highlight_snapshot")',
        '.call("build_side_quest_highlight_snapshot"',
    ),
    PROJECT_ROOT / "Game" / "UI" / "map_route_binding.gd": (
        '_board_composer.call(',
        '.call("set_composition"',
        '.call("set_board_offset"',
        '.call("set_interaction_state"',
    ),
    PROJECT_ROOT / "Game" / "UI" / "support_interaction_presenter.gd": (
        '.call("is_blacksmith_target_selection_active")',
    ),
    PROJECT_ROOT / "scenes" / "support_interaction.gd": (
        '.call("is_blacksmith_target_selection_active")',
    ),
    PROJECT_ROOT / "Game" / "Infrastructure" / "scene_router.gd": (
        'has_method("apply_ui_scale_to_active_scene")',
    ),
}
LEGACY_OVERLAY_WRAPPER_PATTERN = re.compile(
    r"\b(?:open|close)_(?:event|support|reward|level_up)_overlay\b"
)
LEGACY_OVERLAY_CONTRACT_FRAGMENTS = {
    PROJECT_ROOT / "Game" / "Infrastructure" / "scene_router.gd": (
        "OVERLAY_OPEN_METHODS",
        "OVERLAY_CLOSE_METHODS",
    ),
}
PRIVATE_OWNER_CALL_REGRESSION_FRAGMENTS = {
    PROJECT_ROOT / "Game" / "UI" / "map_route_binding.gd": (
        "_board_composer._clearing_radius_for(",
    ),
    PROJECT_ROOT / "Tests" / "test_map_board_composer_v2.gd": (
        "MapBoardEdgeRoutingScript._outer_reconnect_candidate_score(",
        'composer.call("_clearing_radius_for"',
    ),
}
PRIVATE_OWNER_CALL_SPREAD_ALLOWED_FILES = {
    "._build_stream_seed(": {
        PROJECT_ROOT / "scenes" / "map_explore.gd",
    },
    'call("_move_to_node"': {
        PROJECT_ROOT / "Tests" / "test_button_tour.gd",
        PROJECT_ROOT / "Tests" / "test_combat_safe_menu.gd",
        PROJECT_ROOT / "Tests" / "test_phase2_loop.gd",
        PROJECT_ROOT / "Tests" / "test_reward_node.gd",
        PROJECT_ROOT / "Tests" / "test_save_file_roundtrip.gd",
        PROJECT_ROOT / "Tests" / "test_save_support_interaction.gd",
        PROJECT_ROOT / "Tests" / "test_support_interaction.gd",
    },
    'call("_refresh_ui"': {
        PROJECT_ROOT / "Tests" / "test_button_tour.gd",
        PROJECT_ROOT / "Tests" / "test_combat_safe_menu.gd",
        PROJECT_ROOT / "Tests" / "test_event_node.gd",
        PROJECT_ROOT / "Tests" / "test_first_run_hint_scene_hooks.gd",
        PROJECT_ROOT / "Tests" / "test_phase2_loop.gd",
        PROJECT_ROOT / "Tests" / "test_reward_node.gd",
        PROJECT_ROOT / "Tests" / "test_save_file_roundtrip.gd",
        PROJECT_ROOT / "Tests" / "test_save_support_interaction.gd",
        PROJECT_ROOT / "Tests" / "test_support_interaction.gd",
    },
    'call("_sync_overlays_with_flow_state"': {
        PROJECT_ROOT / "Tests" / "test_scene_router.gd",
    },
    'call("_filter_template_ids_for_source_context"': set(),
    'call("_build_combat_inventory_hint_text"': set(),
    'call("_build_combat_pack_summary_card"': set(),
    'call("_on_card_gui_input"': set(),
    'call("_find_inventory_card_from_control"': set(),
}


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


def validate_stale_wrapper_regressions() -> list[str]:
    errors: list[str] = []
    for path, method_name in STALE_WRAPPER_DEFINITIONS.items():
        if not path.is_file():
            continue

        pattern = re.compile(rf"^func\s+{re.escape(method_name)}\s*\(", re.MULTILINE)
        if pattern.search(path.read_text(encoding="utf-8")) is None:
            continue

        rel_path = path.relative_to(PROJECT_ROOT).as_posix()
        errors.append(
            f"{rel_path}: stale wrapper {method_name}() should stay removed instead of regaining compatibility surface"
        )
    return errors


def validate_command_event_catalog_alignment() -> list[str]:
    errors: list[str] = []
    if not COMMAND_EVENT_CATALOG_FILE.is_file():
        return errors

    catalog_text = COMMAND_EVENT_CATALOG_FILE.read_text(encoding="utf-8")
    for entry_name in REQUIRED_COMMAND_EVENT_CATALOG_ENTRIES:
        if entry_name in catalog_text:
            continue
        rel_path = COMMAND_EVENT_CATALOG_FILE.relative_to(PROJECT_ROOT).as_posix()
        errors.append(
            f"{rel_path}: missing implemented command/event catalog entry for {entry_name}"
        )
    precedence_text = (DOCS_ROOT / "DOC_PRECEDENCE.md").read_text(encoding="utf-8") if (DOCS_ROOT / "DOC_PRECEDENCE.md").is_file() else ""
    errors.extend(f"{path.relative_to(PROJECT_ROOT).as_posix()}: active Docs root markdown is not routed in Docs/DOC_PRECEDENCE.md" for path in sorted(DOCS_ROOT.glob("*.md")) if path.name != "DOC_PRECEDENCE.md" and path.name not in precedence_text)
    return errors


def validate_node_resolve_contract_alignment() -> list[str]:
    errors: list[str] = []
    for path, required_fragments in NODE_RESOLVE_CONTRACT_REQUIRED_FRAGMENTS.items():
        if not path.is_file():
            errors.append(f"{path.relative_to(PROJECT_ROOT).as_posix()}: missing required NodeResolve contract file")
            continue

        text = path.read_text(encoding="utf-8")
        for fragment in required_fragments:
            if fragment in text:
                continue
            rel_path = path.relative_to(PROJECT_ROOT).as_posix()
            errors.append(
                f"{rel_path}: missing live NodeResolve contract fragment {fragment!r}; keep the generic fallback explicit in docs and coordinator wiring until an approved flow audit changes it"
            )
    return errors


def validate_app_bootstrap_public_surface() -> list[str]:
    errors = validate_public_method_budget(
        APP_BOOTSTRAP_FILE,
        APP_BOOTSTRAP_PUBLIC_METHOD_LIMIT,
        "AppBootstrap",
    )
    actual_public_methods = set(public_method_names(APP_BOOTSTRAP_FILE))
    unexpected_methods = sorted(actual_public_methods - APP_BOOTSTRAP_ALLOWED_PUBLIC_METHODS)
    if unexpected_methods:
        rel_path = APP_BOOTSTRAP_FILE.relative_to(PROJECT_ROOT).as_posix()
        errors.append(
            f"{rel_path}: AppBootstrap public surface added unexpected method(s) {', '.join(unexpected_methods)}; freeze the facade or explicitly escalate before widening it"
        )
    return errors


def validate_app_bootstrap_lookup_spread() -> list[str]:
    errors: list[str] = []
    for path in iter_gd_files(GAME_ROOT, SCENES_ROOT):
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            if APP_BOOTSTRAP_LOOKUP_PATTERN.search(line) is None:
                continue
            if path in APP_BOOTSTRAP_LOOKUP_ALLOWED_FILES:
                continue
            rel_path = path.relative_to(PROJECT_ROOT).as_posix()
            errors.append(
                f"{rel_path}:{line_number}: new /root/AppBootstrap lookup widens the scene/bootstrap dependency surface; reuse an existing allowed shell or explicitly escalate"
            )
    return errors


def validate_retired_gate_warden_surface() -> list[str]:
    errors: list[str] = []
    for root in RETIRED_GATE_WARDEN_SCAN_ROOTS:
        if not root.exists():
            continue

        for path in sorted(root.rglob("*")):
            if not path.is_file():
                continue

            if path in RETIRED_GATE_WARDEN_ALLOWED_FILES:
                continue

            try:
                path.relative_to(DOCS_ARCHIVE_ROOT)
                continue
            except ValueError:
                pass

            rel_path = path.relative_to(PROJECT_ROOT).as_posix()
            if RETIRED_GATE_WARDEN_TOKEN in rel_path:
                errors.append(
                    f"{rel_path}: retired gate_warden surface should stay removed from live repo paths"
                )
                continue

            if path.suffix.lower() not in RETIRED_GATE_WARDEN_TEXT_SUFFIXES:
                continue

            if RETIRED_GATE_WARDEN_TOKEN not in path.read_text(encoding="utf-8", errors="ignore"):
                continue

            errors.append(
                f"{rel_path}: retired gate_warden identifier should stay trapped in archive/history docs or explicit active planning notes"
            )
    return errors


def validate_typed_reflection_regressions() -> list[str]:
    errors: list[str] = []
    for path, forbidden_fragments in TYPED_REFLECTION_REGRESSION_FRAGMENTS.items():
        if not path.is_file():
            continue

        lines = path.read_text(encoding="utf-8").splitlines()
        for line_number, line in enumerate(lines, start=1):
            for fragment in forbidden_fragments:
                if fragment not in line:
                    continue

                rel_path = path.relative_to(PROJECT_ROOT).as_posix()
                errors.append(
                    f"{rel_path}:{line_number}: typed owner reflection fragment {fragment!r} should stay removed; prefer direct typed calls over string-based call()/has_method()"
                )
    return errors


def validate_overlay_contract_regressions() -> list[str]:
    errors: list[str] = []
    for path in iter_gd_files(GAME_ROOT, SCENES_ROOT, TESTS_ROOT):
        lines = path.read_text(encoding="utf-8").splitlines()
        for line_number, line in enumerate(lines, start=1):
            match = LEGACY_OVERLAY_WRAPPER_PATTERN.search(line)
            if match is None:
                continue

            rel_path = path.relative_to(PROJECT_ROOT).as_posix()
            errors.append(
                f"{rel_path}:{line_number}: legacy overlay wrapper {match.group(0)!r} should stay removed; route overlay opening/closing through the shared state-driven contract surface instead"
            )

    for path, forbidden_fragments in LEGACY_OVERLAY_CONTRACT_FRAGMENTS.items():
        if not path.is_file():
            continue

        lines = path.read_text(encoding="utf-8").splitlines()
        for line_number, line in enumerate(lines, start=1):
            for fragment in forbidden_fragments:
                if fragment not in line:
                    continue

                rel_path = path.relative_to(PROJECT_ROOT).as_posix()
                errors.append(
                    f"{rel_path}:{line_number}: legacy overlay dictionary fragment {fragment!r} should stay removed; keep SceneRouter on the shared overlay contract surface"
                )
    return errors


def validate_private_owner_call_regressions() -> list[str]:
    errors: list[str] = []
    for path, forbidden_fragments in PRIVATE_OWNER_CALL_REGRESSION_FRAGMENTS.items():
        if not path.is_file():
            continue

        lines = path.read_text(encoding="utf-8").splitlines()
        for line_number, line in enumerate(lines, start=1):
            for fragment in forbidden_fragments:
                if fragment not in line:
                    continue

                rel_path = path.relative_to(PROJECT_ROOT).as_posix()
                errors.append(
                    f"{rel_path}:{line_number}: private owner call fragment {fragment!r} should stay removed; use an explicit owner-backed helper instead of reaching into another class's private method"
                )
    return errors


def validate_private_owner_call_spread() -> list[str]:
    errors: list[str] = []
    for fragment, allowed_files in PRIVATE_OWNER_CALL_SPREAD_ALLOWED_FILES.items():
        for path in iter_gd_files(GAME_ROOT, SCENES_ROOT, TESTS_ROOT):
            if path in allowed_files:
                continue

            lines = path.read_text(encoding="utf-8").splitlines()
            for line_number, line in enumerate(lines, start=1):
                if fragment not in line:
                    continue

                rel_path = path.relative_to(PROJECT_ROOT).as_posix()
                errors.append(
                    f"{rel_path}:{line_number}: private owner call fragment {fragment!r} should not spread beyond its explicit grandfathered lane; extract a public owner-backed helper instead"
                )
    return errors


def validate_run_session_coordinator_public_surface() -> list[str]:
    return validate_public_method_budget(
        RUN_SESSION_COORDINATOR_FILE,
        RUN_SESSION_COORDINATOR_PUBLIC_METHOD_LIMIT,
        "RunSessionCoordinator",
    )


def validate_active_doc_ballast() -> list[str]:
    errors: list[str] = []
    for path, line_limit in ACTIVE_DOC_LINE_LIMITS.items():
        if not path.is_file():
            continue

        line_count = len(path.read_text(encoding="utf-8").splitlines())
        if line_count <= line_limit:
            continue

        rel_path = path.relative_to(PROJECT_ROOT).as_posix()
        errors.append(
            f"{rel_path}: active doc grew to {line_count} lines (limit {line_limit}). "
            "Rewrite the snapshot/queue doc instead of letting continuation ballast accumulate."
        )
    return errors


def main() -> int:
    findings = {"error": [], "warning": []}
    for check in (
        validate_dispatch_usage,
        validate_runstate_compatibility_usage,
        validate_test_runstate_inventory_compatibility_usage,
        validate_current_node_index_runtime_creep,
        validate_scene_ui_truth_mutation_creep,
        validate_combat_inventory_slot_bridge_creep,
        validate_run_summary_cleanup_workaround_creep,
        validate_application_infrastructure_presentation_coupling,
        validate_app_bootstrap_public_surface,
        validate_app_bootstrap_lookup_spread,
        validate_retired_gate_warden_surface,
        validate_typed_reflection_regressions,
        validate_overlay_contract_regressions,
        validate_private_owner_call_regressions,
        validate_private_owner_call_spread,
        validate_run_session_coordinator_public_surface,
        validate_stale_wrapper_regressions,
        validate_command_event_catalog_alignment,
        validate_node_resolve_contract_alignment,
    ):
        findings["error"].extend(check())
    for check in (validate_hotspot_file_growth, validate_active_doc_ballast):
        findings["warning"].extend(check())

    errors = findings["error"]
    warnings = findings["warning"]

    if errors:
        print("Architecture guard validation failed.", file=sys.stderr)
        print("Errors:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        if warnings:
            print("\nWarnings:", file=sys.stderr)
            for warning in warnings:
                print(f"- {warning}", file=sys.stderr)
        return 1

    if warnings:
        print("Architecture guard validation passed with warnings.")
        print("Warnings:")
        for warning in warnings:
            print(f"- {warning}")
        return 0

    print("Architecture guard validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
