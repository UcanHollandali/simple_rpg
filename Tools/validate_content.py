# Usage (Windows): py -3 Tools/validate_content.py
# Usage (macOS/Linux): python3 Tools/validate_content.py

from __future__ import annotations

import json
import re
import sys
from collections import deque
from pathlib import Path


REQUIRED_TOP_LEVEL_FIELDS = (
    "schema_version",
    "definition_id",
    "family",
    "tags",
    "display",
    "rules",
)

SUPPORTED_FAMILIES = {
    "Weapons",
    "Armors",
    "Belts",
    "Consumables",
    "PassiveItems",
    "Enemies",
    "Statuses",
    "Effects",
    "Rewards",
    "RouteConditions",
    "EventTemplates",
    "RunLoadouts",
    "MerchantStocks",
    "MapTemplates",
    "SideMissions",
}

ENEMY_ENCOUNTER_TIERS = {"minor", "elite"}
ENEMY_INTENT_CATEGORIES = {
    "brace_test",
    "dps_race",
    "item_window",
    "attrition_pressure",
    "tempo_break",
}

DEFINITION_ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
SUPPORTED_CONDITION_OPS = {"always", "eq", "neq", "gt", "gte", "lt", "lte", "has_tag", "not_has_tag"}
SUPPORTED_AUTHORING_TARGETS = {"self", "enemy"}
SUPPORTED_ENEMY_BEHAVIOR_TRIGGERS = {"passive"}
SUPPORTED_ENEMY_BEHAVIOR_EFFECTS = {"modify_stat"}
SUPPORTED_PASSIVE_ITEM_BEHAVIOR_TRIGGERS = {"passive"}
SUPPORTED_PASSIVE_ITEM_BEHAVIOR_EFFECTS = {"modify_stat"}
SUPPORTED_EQUIPMENT_BEHAVIOR_TRIGGERS = {"passive"}
SUPPORTED_EQUIPMENT_BEHAVIOR_EFFECTS = {"modify_stat"}
SUPPORTED_INTENT_EFFECTS = {"deal_damage", "apply_status"}
SUPPORTED_CONSUMABLE_USE_TRIGGER = "on_use"
SUPPORTED_CONSUMABLE_USE_TARGET = "self"
SUPPORTED_CONSUMABLE_EFFECTS = {"heal", "modify_hunger"}
SUPPORTED_EVENT_EFFECT_TYPES = {"grant_gold", "grant_xp", "heal", "modify_hunger", "repair_weapon", "damage_player"}
SUPPORTED_REWARD_EFFECT_TYPES = {"heal", "repair_weapon", "grant_xp", "grant_gold"}
SUPPORTED_REWARD_SELECTION_MODES = {"rotate_by_context", "seeded_reward_rng"}
SUPPORTED_STATUS_MODIFIER_KEYS = {
    "attack_power_bonus",
    "incoming_damage_flat_reduction",
    "durability_cost_flat_reduction",
    "skip_player_action",
}
SUPPORTED_MERCHANT_STOCK_EFFECT_TYPES = {"buy_consumable", "buy_weapon"}
SUPPORTED_MAP_TEMPLATE_NODE_FAMILIES = {
    "start",
    "combat",
    "event",
    "reward",
    "side_mission",
    "rest",
    "merchant",
    "blacksmith",
    "key",
    "boss",
}
SUPPORTED_MAP_TEMPLATE_SLOT_TYPES = {
    "opening_support",
    "late_primary",
    "late_event",
    "late_side_mission",
}
SUPPORTED_SIDE_MISSION_TYPES = {"hunt_marked_enemy"}
ORDERED_AUTHORING_FAMILIES = {"Enemies", "PassiveItems"}
ORDERING_FIELD_NAME = "authoring_order"


def main(argv: list[str]) -> int:
    if argv[1:]:
        print(f"Unknown arguments: {' '.join(argv[1:])}", file=sys.stderr)
        print("Usage (Windows): py -3 Tools/validate_content.py", file=sys.stderr)
        print("Usage (macOS/Linux): python3 Tools/validate_content.py", file=sys.stderr)
        return 2

    repo_root = Path(__file__).resolve().parent.parent
    content_root = repo_root / "ContentDefinitions"

    if not content_root.exists():
        print(f"Content root not found: {content_root}")
        return 1

    errors: list[ValidationIssue] = []
    warnings: list[ValidationIssue] = []
    seen_definition_ids: dict[str, Path] = {}
    seen_authoring_orders: dict[str, dict[int, Path]] = {}

    for json_path in iter_content_files(content_root):
        validate_file(json_path, content_root, seen_definition_ids, seen_authoring_orders, errors, warnings)

    if errors:
        for error in errors:
            print(f"{error.path} | {error.error_type} | {error.message}")
        return 1

    for warning in warnings:
        print(f"{warning.path} | warning:{warning.error_type} | {warning.message}")

    print("All content files valid.")
    return 0


def iter_content_files(content_root: Path) -> list[Path]:
    json_files: list[Path] = []

    for path in sorted(content_root.rglob("*.json")):
        json_files.append(path)

    return json_files


def validate_file(
    json_path: Path,
    content_root: Path,
    seen_definition_ids: dict[str, Path],
    seen_authoring_orders: dict[str, dict[int, Path]],
    errors: list["ValidationIssue"],
    warnings: list["ValidationIssue"],
) -> None:
    data = load_json(json_path, errors)
    if data is None:
        return

    if not isinstance(data, dict):
        errors.append(
            ValidationError(json_path, "invalid_root_type", "Top-level JSON value must be an object.")
        )
        return

    for field in REQUIRED_TOP_LEVEL_FIELDS:
        if field not in data:
            errors.append(
                ValidationError(json_path, "missing_required_field", f"Missing top-level field '{field}'.")
            )

    definition_id = data.get("definition_id")
    family = data.get("family")
    tags = data.get("tags")
    display = data.get("display")
    rules = data.get("rules")

    if isinstance(definition_id, str):
        validate_definition_id(json_path, definition_id, seen_definition_ids, errors)
        expected_stem = json_path.stem
        if definition_id != expected_stem:
            errors.append(
                ValidationError(
                    json_path,
                    "definition_id_filename_mismatch",
                    f"definition_id '{definition_id}' does not match file name '{expected_stem}'.",
                )
            )
    else:
        errors.append(
            ValidationError(json_path, "invalid_definition_id", "definition_id must be a string.")
        )

    if isinstance(family, str):
        validate_family(json_path, family, content_root, errors)
        validate_authoring_order(json_path, family, data, seen_authoring_orders, errors)
    else:
        errors.append(ValidationError(json_path, "invalid_family", "family must be a string."))

    if not isinstance(tags, list):
        errors.append(ValidationError(json_path, "invalid_tags", "tags must be an array."))

    if not isinstance(display, dict):
        errors.append(ValidationError(json_path, "invalid_display", "display must be an object."))
    elif "name" not in display or not isinstance(display.get("name"), str) or not display["name"].strip():
        errors.append(
            ValidationError(json_path, "invalid_display_name", "display.name must exist and be a non-empty string.")
        )

    if not isinstance(rules, dict):
        errors.append(ValidationError(json_path, "invalid_rules", "rules must be an object."))

    if family == "Enemies":
        validate_enemy_fields(json_path, data, errors, warnings)

    if isinstance(family, str) and isinstance(rules, dict):
        validate_runtime_support(json_path, family, data, rules, errors, warnings, content_root)


def load_json(json_path: Path, errors: list["ValidationIssue"]) -> dict | list | None:
    try:
        with json_path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except json.JSONDecodeError as exc:
        errors.append(
            ValidationError(
                json_path,
                "invalid_json",
                f"JSON parse error at line {exc.lineno}, column {exc.colno}: {exc.msg}",
            )
        )
    except OSError as exc:
        errors.append(ValidationError(json_path, "file_read_error", str(exc)))
    return None


def validate_definition_id(
    json_path: Path,
    definition_id: str,
    seen_definition_ids: dict[str, Path],
    errors: list["ValidationIssue"],
) -> None:
    if not DEFINITION_ID_PATTERN.match(definition_id):
        errors.append(
            ValidationError(
                json_path,
                "invalid_definition_id_format",
                f"definition_id '{definition_id}' must match ^[a-z][a-z0-9_]*$.",
            )
        )

    previous_path = seen_definition_ids.get(definition_id)
    if previous_path is not None:
        errors.append(
            ValidationError(
                json_path,
                "duplicate_definition_id",
                f"definition_id '{definition_id}' is already used by {previous_path}.",
            )
        )
        return

    seen_definition_ids[definition_id] = json_path


def validate_family(
    json_path: Path,
    family: str,
    content_root: Path,
    errors: list["ValidationIssue"],
) -> None:
    if family not in SUPPORTED_FAMILIES:
        errors.append(
            ValidationError(
                json_path,
                "invalid_family",
                f"family '{family}' is not in the supported family list.",
            )
        )
        return

    try:
        relative_parts = json_path.relative_to(content_root).parts
    except ValueError:
        errors.append(
            ValidationError(json_path, "path_error", "File is not inside ContentDefinitions root.")
        )
        return

    if not relative_parts:
        errors.append(
            ValidationError(json_path, "path_error", "Could not determine content family folder from path.")
        )
        return

    folder_name = relative_parts[0]
    if folder_name != family:
        errors.append(
            ValidationError(
                json_path,
                "family_folder_mismatch",
                f"Path folder '{folder_name}' does not match family '{family}'.",
            )
        )


def validate_authoring_order(
    json_path: Path,
    family: str,
    data: dict,
    seen_authoring_orders: dict[str, dict[int, Path]],
    errors: list["ValidationIssue"],
) -> None:
    if family not in ORDERED_AUTHORING_FAMILIES:
        return

    authoring_order = data.get(ORDERING_FIELD_NAME)
    if isinstance(authoring_order, bool) or not isinstance(authoring_order, int) or authoring_order <= 0:
        errors.append(
            ValidationError(
                json_path,
                "invalid_authoring_order",
                f"{family} definitions must use a positive integer top-level field '{ORDERING_FIELD_NAME}'.",
            )
        )
        return

    family_orders = seen_authoring_orders.setdefault(family, {})
    previous_path = family_orders.get(authoring_order)
    if previous_path is not None:
        errors.append(
            ValidationError(
                json_path,
                "duplicate_authoring_order",
                f"{family} '{ORDERING_FIELD_NAME}' value {authoring_order} is already used by {previous_path}.",
            )
        )
        return

    family_orders[authoring_order] = json_path


def validate_enemy_fields(
    json_path: Path,
    data: dict,
    errors: list["ValidationIssue"],
    warnings: list["ValidationIssue"],
) -> None:
    definition_id = data.get("definition_id", json_path.stem)
    encounter_tier = data.get("encounter_tier")
    if encounter_tier is not None and not isinstance(encounter_tier, str):
        errors.append(
            ValidationError(
                json_path,
                "invalid_encounter_tier_type",
                "Enemies definitions must use a string for optional field 'encounter_tier' when present.",
            )
        )
    elif isinstance(encounter_tier, str) and encounter_tier not in ENEMY_ENCOUNTER_TIERS:
        errors.append(
            ValidationError(
                json_path,
                "invalid_encounter_tier",
                f"encounter_tier '{encounter_tier}' must be one of: {', '.join(sorted(ENEMY_ENCOUNTER_TIERS))}.",
            )
        )

    design_intent_question = data.get("design_intent_question")
    if design_intent_question is None:
        errors.append(
            ValidationError(
                json_path,
                "missing_design_intent_question",
                f"Enemy {definition_id} missing required field: design_intent_question",
            )
        )
        return

    if not isinstance(design_intent_question, str):
        errors.append(
            ValidationError(
                json_path,
                "invalid_design_intent_question",
                f"Enemy {definition_id} must use a string for design_intent_question.",
            )
        )
        return

    if not design_intent_question.strip():
        errors.append(
            ValidationError(
                json_path,
                "empty_design_intent_question",
                f"Enemy {definition_id} has empty design_intent_question",
            )
        )
        return

    normalized_intent = design_intent_question.strip()
    if is_shorthand_intent_value(normalized_intent) and normalized_intent not in ENEMY_INTENT_CATEGORIES:
        warnings.append(
            ValidationWarning(
                json_path,
                "unknown_design_intent_category",
                f"Enemy {definition_id} uses shorthand design_intent_question '{normalized_intent}', which is outside the recommended inspiration set.",
            )
        )


def validate_runtime_support(
    json_path: Path,
    family: str,
    data: dict,
    rules: dict,
    errors: list["ValidationIssue"],
    warnings: list["ValidationIssue"],
    content_root: Path,
) -> None:
    if family == "Enemies":
        validate_enemy_runtime_support(json_path, data, rules, errors, content_root)
        return

    if family == "Weapons":
        validate_reserved_weapon_rules(json_path, rules, errors)
        return

    if family == "Consumables":
        validate_consumable_runtime_support(json_path, rules, errors)
        return

    if family == "PassiveItems":
        validate_passive_item_runtime_support(json_path, rules, errors)
        return

    if family in {"Armors", "Belts"}:
        validate_equipment_runtime_support(json_path, family, rules, errors)
        return

    if family == "Rewards":
        validate_reward_runtime_support(json_path, rules, errors)
        return

    if family == "EventTemplates":
        validate_event_template_runtime_support(json_path, rules, errors)
        return

    if family == "Statuses":
        validate_status_runtime_support(json_path, rules, errors)
        return

    if family == "RunLoadouts":
        validate_run_loadout_runtime_support(json_path, rules, errors, content_root)
        return

    if family == "MerchantStocks":
        validate_merchant_stock_runtime_support(json_path, rules, errors, content_root)
        return

    if family == "MapTemplates":
        validate_map_template_runtime_support(json_path, rules, errors)
        return

    if family == "SideMissions":
        validate_side_mission_runtime_support(json_path, rules, errors, content_root)
        return


def validate_enemy_runtime_support(
    json_path: Path,
    data: dict,
    rules: dict,
    errors: list["ValidationIssue"],
    content_root: Path,
) -> None:
    intent_pool = rules.get("intent_pool", [])
    if intent_pool:
        if not isinstance(intent_pool, list):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_intent_pool",
                    "Enemies.rules.intent_pool must be an array when present.",
                )
            )
        else:
            for index, intent in enumerate(intent_pool):
                validate_enemy_intent(json_path, intent, index, errors, content_root)

    behaviors = rules.get("behaviors", [])
    if behaviors:
        if not isinstance(behaviors, list):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_behaviors",
                    "rules.behaviors must be an array when present.",
                )
            )
        else:
            for index, behavior in enumerate(behaviors):
                validate_enemy_behavior(json_path, behavior, index, errors)

    boss_phases = rules.get("boss_phases", [])
    if boss_phases:
        validate_enemy_boss_phases(json_path, data, boss_phases, errors, content_root)
    elif boss_phases is not None and not isinstance(boss_phases, list):
        errors.append(
            ValidationError(
                json_path,
                "invalid_boss_phases",
                "Enemies.rules.boss_phases must be an array when present.",
            )
        )


def validate_enemy_boss_phases(
    json_path: Path,
    data: dict,
    boss_phases: object,
    errors: list["ValidationIssue"],
    content_root: Path,
) -> None:
    if not isinstance(boss_phases, list) or len(boss_phases) < 2:
        errors.append(
            ValidationError(
                json_path,
                "invalid_boss_phases",
                "Enemies.rules.boss_phases must be an array with at least 2 phases.",
            )
        )
        return

    tags = data.get("tags", [])
    if not isinstance(tags, list) or "boss" not in tags:
        errors.append(
            ValidationError(
                json_path,
                "boss_phases_require_boss_tag",
                "Enemies.rules.boss_phases are only supported on boss-tagged enemy definitions.",
            )
        )

    previous_threshold: int | None = None
    seen_phase_ids: set[str] = set()
    for index, phase in enumerate(boss_phases):
        if not isinstance(phase, dict):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_boss_phase_entry",
                    f"Enemies.rules.boss_phases[{index}] must be an object.",
                )
            )
            continue

        phase_id = phase.get("phase_id")
        if not isinstance(phase_id, str) or not phase_id.strip():
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_boss_phase_id",
                    f"Enemies.rules.boss_phases[{index}].phase_id must be a non-empty string.",
                )
            )
        elif phase_id in seen_phase_ids:
            errors.append(
                ValidationError(
                    json_path,
                    "duplicate_boss_phase_id",
                    f"Enemies.rules.boss_phases[{index}] reuses phase_id '{phase_id}'.",
                )
            )
        else:
            seen_phase_ids.add(phase_id)

        display_name = phase.get("display_name")
        if not isinstance(display_name, str) or not display_name.strip():
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_boss_phase_display_name",
                    f"Enemies.rules.boss_phases[{index}].display_name must be a non-empty string.",
                )
            )

        threshold = phase.get("enter_at_or_below_percent", None)
        if index == 0:
            if threshold is not None and threshold != 100:
                errors.append(
                    ValidationError(
                        json_path,
                        "invalid_initial_boss_phase_threshold",
                        "Enemies.rules.boss_phases[0].enter_at_or_below_percent must be omitted or set to 100.",
                    )
                )
        else:
            if not isinstance(threshold, int) or threshold <= 0 or threshold >= 100:
                errors.append(
                    ValidationError(
                        json_path,
                        "invalid_boss_phase_threshold",
                        f"Enemies.rules.boss_phases[{index}].enter_at_or_below_percent must be an integer in range 1..99.",
                    )
                )
            elif previous_threshold is not None and threshold >= previous_threshold:
                errors.append(
                    ValidationError(
                        json_path,
                        "invalid_boss_phase_threshold_order",
                        "Enemies.rules.boss_phases thresholds must descend as later phases get deeper.",
                    )
                )
            previous_threshold = threshold if isinstance(threshold, int) else previous_threshold

        intent_pool = phase.get("intent_pool", [])
        if not isinstance(intent_pool, list) or not intent_pool:
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_boss_phase_intent_pool",
                    f"Enemies.rules.boss_phases[{index}].intent_pool must be a non-empty array.",
                )
            )
            continue

        for intent_index, intent in enumerate(intent_pool):
            validate_enemy_intent(
                json_path,
                intent,
                intent_index,
                errors,
                content_root,
            )


def validate_enemy_intent(
    json_path: Path,
    intent: object,
    index: int,
    errors: list["ValidationIssue"],
    content_root: Path,
) -> None:
    if not isinstance(intent, dict):
        errors.append(
            ValidationError(
                json_path,
                "invalid_intent_entry",
                f"Enemies.rules.intent_pool[{index}] must be an object.",
            )
        )
        return

    if "weight" in intent:
        errors.append(
            ValidationError(
                json_path,
                "unsupported_intent_weight",
                f"Enemies.rules.intent_pool[{index}].weight is reserved for later weighted selection and must not be used in current canonical content.",
            )
        )

    effects = intent.get("effects", [])
    validate_effect_array(
        json_path,
        effects,
        SUPPORTED_INTENT_EFFECTS,
        f"Enemies.rules.intent_pool[{index}].effects",
        errors,
    )

    if not isinstance(effects, list):
        return

    for effect_index, effect in enumerate(effects):
        validate_enemy_intent_effect(json_path, effect, index, effect_index, errors, content_root)


def validate_enemy_behavior(
    json_path: Path,
    behavior: object,
    index: int,
    errors: list["ValidationIssue"],
) -> None:
    if not isinstance(behavior, dict):
        errors.append(
            ValidationError(
                json_path,
                "invalid_behavior_entry",
                f"Enemies.rules.behaviors[{index}] must be an object.",
            )
        )
        return

    trigger = behavior.get("trigger")
    if not isinstance(trigger, str) or trigger not in SUPPORTED_ENEMY_BEHAVIOR_TRIGGERS:
        errors.append(
            ValidationError(
                json_path,
                "unsupported_behavior_trigger",
                f"Enemies.rules.behaviors[{index}].trigger must be one of: {', '.join(sorted(SUPPORTED_ENEMY_BEHAVIOR_TRIGGERS))}.",
            )
        )

    validate_rule_condition(json_path, behavior.get("condition", None), f"Enemies.rules.behaviors[{index}].condition", errors)
    validate_rule_target(json_path, behavior.get("target", None), f"Enemies.rules.behaviors[{index}].target", errors)
    validate_effect_array(
        json_path,
        behavior.get("effects", []),
        SUPPORTED_ENEMY_BEHAVIOR_EFFECTS,
        f"Enemies.rules.behaviors[{index}].effects",
        errors,
    )


def validate_reserved_weapon_rules(
    json_path: Path,
    rules: dict,
    errors: list["ValidationIssue"],
) -> None:
    behaviors = rules.get("behaviors", [])
    if not behaviors:
        return

    errors.append(
        ValidationError(
            json_path,
            "unsupported_weapon_behaviors",
            "Weapon rule behaviors are not part of the current canonical content surface yet.",
        )
    )


def validate_consumable_runtime_support(
    json_path: Path,
    rules: dict,
    errors: list["ValidationIssue"],
) -> None:
    stats = rules.get("stats", {})
    if stats and not isinstance(stats, dict):
        errors.append(
            ValidationError(
                json_path,
                "invalid_consumable_stats",
                "Consumables.rules.stats must be an object when present.",
            )
        )
    elif isinstance(stats, dict):
        max_stack = stats.get("max_stack")
        if max_stack is not None and (not isinstance(max_stack, int) or max_stack <= 0):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_max_stack",
                    "Consumables.rules.stats.max_stack must be a positive integer when present.",
                )
            )

        restore_hp = stats.get("restore_hp")
        if restore_hp is not None and (not isinstance(restore_hp, int) or restore_hp <= 0):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_restore_hp",
                    "Consumables.rules.stats.restore_hp must be a positive integer when present.",
                )
            )

    use_effect = rules.get("use_effect")
    if use_effect is None:
        return

    if not isinstance(use_effect, dict):
        errors.append(
            ValidationError(
                json_path,
                "invalid_use_effect",
                "Consumables.rules.use_effect must be an object when present.",
            )
        )
        return

    trigger = use_effect.get("trigger")
    if not isinstance(trigger, str) or trigger != SUPPORTED_CONSUMABLE_USE_TRIGGER:
        errors.append(
            ValidationError(
                json_path,
                "unsupported_use_effect_trigger",
                "Consumables.rules.use_effect.trigger must be 'on_use' in the current runtime-backed slice.",
            )
        )

    condition_value = use_effect.get("condition", None)
    if condition_value is not None:
        if not isinstance(condition_value, dict):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_use_effect_condition",
                    "Consumables.rules.use_effect.condition must be an object when present.",
                )
            )
        elif condition_value.get("op") != "always":
            errors.append(
                ValidationError(
                    json_path,
                    "unsupported_use_effect_condition",
                    "Consumables.rules.use_effect.condition must be omitted or {'op': 'always'} in the current runtime-backed slice.",
                )
            )

    target = use_effect.get("target")
    if not isinstance(target, str) or target != SUPPORTED_CONSUMABLE_USE_TARGET:
        errors.append(
            ValidationError(
                json_path,
                "unsupported_use_effect_target",
                "Consumables.rules.use_effect.target must be 'self' in the current runtime-backed slice.",
            )
        )

    effects = use_effect.get("effects", [])
    validate_effect_array(
        json_path,
        effects,
        SUPPORTED_CONSUMABLE_EFFECTS,
        "Consumables.rules.use_effect.effects",
        errors,
    )

    if not isinstance(effects, list):
        return

    for index, effect in enumerate(effects):
        if not isinstance(effect, dict):
            continue
        params = effect.get("params")
        if not isinstance(params, dict):
            continue
        effect_type = effect.get("type")
        if effect_type == "heal":
            base = params.get("base")
            if not isinstance(base, int) or base <= 0:
                errors.append(
                    ValidationError(
                        json_path,
                        "invalid_heal_base",
                        f"Consumables.rules.use_effect.effects[{index}].params.base must be a positive integer.",
                    )
                )
        elif effect_type == "modify_hunger":
            amount = params.get("amount")
            if not isinstance(amount, int) or amount >= 0:
                errors.append(
                    ValidationError(
                        json_path,
                        "invalid_modify_hunger_amount",
                        f"Consumables.rules.use_effect.effects[{index}].params.amount must be a negative integer.",
                    )
                )
        else:
            errors.append(
                ValidationError(
                    json_path,
                    "unsupported_effect_type",
                    f"Consumables.rules.use_effect.effects[{index}].type must be one of: {', '.join(sorted(SUPPORTED_CONSUMABLE_EFFECTS))}.",
                )
            )


def validate_status_runtime_support(
    json_path: Path,
    rules: dict,
    errors: list["ValidationIssue"],
) -> None:
    stats = rules.get("stats", {})
    if not isinstance(stats, dict):
        errors.append(
            ValidationError(
                json_path,
                "invalid_status_stats",
                "Statuses.rules.stats must be an object in the current runtime-backed status slice.",
            )
        )
        return

    duration_turns = stats.get("duration_turns")
    if not isinstance(duration_turns, int) or duration_turns <= 0:
        errors.append(
            ValidationError(
                json_path,
                "invalid_status_duration_turns",
                "Statuses.rules.stats.duration_turns must be a positive integer.",
            )
        )

    max_stacks = stats.get("max_stacks")
    if not isinstance(max_stacks, int) or max_stacks <= 0:
        errors.append(
            ValidationError(
                json_path,
                "invalid_status_max_stacks",
                "Statuses.rules.stats.max_stacks must be a positive integer.",
            )
        )

    damage_per_turn = stats.get("damage_per_turn")
    if damage_per_turn is not None and (not isinstance(damage_per_turn, int) or damage_per_turn <= 0):
        errors.append(
            ValidationError(
                json_path,
                "invalid_status_damage_per_turn",
                "Statuses.rules.stats.damage_per_turn must be a positive integer when present.",
            )
        )

    stat_modifiers = stats.get("stat_modifiers")
    valid_modifier_count = 0
    if stat_modifiers is not None:
        if not isinstance(stat_modifiers, dict) or not stat_modifiers:
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_status_stat_modifiers",
                    "Statuses.rules.stats.stat_modifiers must be a non-empty object when present.",
                )
            )
        else:
            for modifier_key, modifier_value in stat_modifiers.items():
                if modifier_key not in SUPPORTED_STATUS_MODIFIER_KEYS:
                    errors.append(
                        ValidationError(
                            json_path,
                            "unsupported_status_modifier_key",
                            "Statuses.rules.stats.stat_modifiers key '%s' must be one of: %s."
                            % (modifier_key, ", ".join(sorted(SUPPORTED_STATUS_MODIFIER_KEYS))),
                        )
                    )
                    continue
                if not isinstance(modifier_value, int) or modifier_value == 0:
                    errors.append(
                        ValidationError(
                            json_path,
                            "invalid_status_modifier_amount",
                            "Statuses.rules.stats.stat_modifiers['%s'] must be a non-zero integer."
                            % modifier_key,
                        )
                    )
                    continue
                valid_modifier_count += 1

    has_damage_tick = isinstance(damage_per_turn, int) and damage_per_turn > 0
    has_supported_modifier = valid_modifier_count > 0
    if not has_damage_tick and not has_supported_modifier:
        errors.append(
            ValidationError(
                json_path,
                "empty_status_runtime_effect",
                "Statuses.rules.stats must define either damage_per_turn or a supported stat_modifiers entry in the current runtime-backed slice.",
            )
        )

    behaviors = rules.get("behaviors", [])
    if not behaviors:
        return

    errors.append(
        ValidationError(
            json_path,
            "unsupported_status_behaviors",
            "Status behavior resolution is reserved for later runtime support and must not be used in current canonical content.",
        )
    )


def validate_run_loadout_runtime_support(
    json_path: Path,
    rules: dict,
    errors: list["ValidationIssue"],
    content_root: Path,
) -> None:
    weapon_definition_id = rules.get("weapon_definition_id")
    if not isinstance(weapon_definition_id, str) or not weapon_definition_id.strip():
        errors.append(
            ValidationError(
                json_path,
                "invalid_run_loadout_weapon_definition_id",
                "RunLoadouts.rules.weapon_definition_id must be a non-empty string.",
            )
        )
    else:
        validate_cross_family_reference(
            json_path,
            content_root,
            "Weapons",
            weapon_definition_id,
            "RunLoadouts.rules.weapon_definition_id",
            errors,
        )

    consumable_slots = rules.get("consumable_slots", [])
    if not isinstance(consumable_slots, list):
        errors.append(
            ValidationError(
                json_path,
                "invalid_run_loadout_consumable_slots",
                "RunLoadouts.rules.consumable_slots must be an array.",
            )
        )
        return

    for index, slot in enumerate(consumable_slots):
        if not isinstance(slot, dict):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_run_loadout_consumable_slot_entry",
                    f"RunLoadouts.rules.consumable_slots[{index}] must be an object.",
                )
            )
            continue

        definition_id = slot.get("definition_id")
        if not isinstance(definition_id, str) or not definition_id.strip():
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_run_loadout_consumable_definition_id",
                    f"RunLoadouts.rules.consumable_slots[{index}].definition_id must be a non-empty string.",
                )
            )
        else:
            validate_cross_family_reference(
                json_path,
                content_root,
                "Consumables",
                definition_id,
                f"RunLoadouts.rules.consumable_slots[{index}].definition_id",
                errors,
            )

        current_stack = slot.get("current_stack")
        if isinstance(current_stack, bool) or not isinstance(current_stack, int) or current_stack <= 0:
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_run_loadout_consumable_stack",
                    f"RunLoadouts.rules.consumable_slots[{index}].current_stack must be a positive integer.",
                )
            )


def validate_merchant_stock_runtime_support(
    json_path: Path,
    rules: dict,
    errors: list["ValidationIssue"],
    content_root: Path,
) -> None:
    stock_entries = rules.get("stock", [])
    if not isinstance(stock_entries, list) or not stock_entries:
        errors.append(
            ValidationError(
                json_path,
                "invalid_merchant_stock_entries",
                "MerchantStocks.rules.stock must be a non-empty array.",
            )
        )
        return

    seen_offer_ids: set[str] = set()
    for index, stock_entry in enumerate(stock_entries):
        if not isinstance(stock_entry, dict):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_merchant_stock_entry",
                    f"MerchantStocks.rules.stock[{index}] must be an object.",
                )
            )
            continue

        offer_id = stock_entry.get("offer_id")
        if not isinstance(offer_id, str) or not offer_id.strip():
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_merchant_stock_offer_id",
                    f"MerchantStocks.rules.stock[{index}].offer_id must be a non-empty string.",
                )
            )
        elif offer_id in seen_offer_ids:
            errors.append(
                ValidationError(
                    json_path,
                    "duplicate_merchant_stock_offer_id",
                    f"MerchantStocks.rules.stock[{index}] reuses offer_id '{offer_id}'.",
                )
            )
        else:
            seen_offer_ids.add(offer_id)

        effect_type = stock_entry.get("effect_type")
        if not isinstance(effect_type, str) or effect_type not in SUPPORTED_MERCHANT_STOCK_EFFECT_TYPES:
            errors.append(
                ValidationError(
                    json_path,
                    "unsupported_merchant_stock_effect_type",
                    "MerchantStocks.rules.stock[%d].effect_type must be one of: %s."
                    % (index, ", ".join(sorted(SUPPORTED_MERCHANT_STOCK_EFFECT_TYPES))),
                )
            )
            continue

        definition_id = stock_entry.get("definition_id")
        if not isinstance(definition_id, str) or not definition_id.strip():
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_merchant_stock_definition_id",
                    f"MerchantStocks.rules.stock[{index}].definition_id must be a non-empty string.",
                )
            )
        else:
            validate_cross_family_reference(
                json_path,
                content_root,
                family_for_merchant_stock_entry(effect_type),
                definition_id,
                f"MerchantStocks.rules.stock[{index}].definition_id",
                errors,
            )

        cost_gold = stock_entry.get("cost_gold")
        if isinstance(cost_gold, bool) or not isinstance(cost_gold, int) or cost_gold <= 0:
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_merchant_stock_cost_gold",
                    f"MerchantStocks.rules.stock[{index}].cost_gold must be a positive integer.",
                )
            )

        amount = stock_entry.get("amount")
        if effect_type == "buy_consumable":
            if isinstance(amount, bool) or not isinstance(amount, int) or amount <= 0:
                errors.append(
                    ValidationError(
                        json_path,
                        "invalid_merchant_stock_amount",
                        f"MerchantStocks.rules.stock[{index}].amount must be a positive integer for buy_consumable entries.",
                    )
                )
        elif amount is not None:
            errors.append(
                ValidationError(
                    json_path,
                    "unexpected_merchant_stock_amount",
                    f"MerchantStocks.rules.stock[{index}] must not define amount for effect_type '{effect_type}'.",
                )
            )


def validate_map_template_runtime_support(
    json_path: Path,
    rules: dict,
    errors: list["ValidationIssue"],
) -> None:
    nodes = rules.get("nodes", [])
    if not isinstance(nodes, list) or not nodes:
        errors.append(
            ValidationError(
                json_path,
                "invalid_map_template_nodes",
                "MapTemplates.rules.nodes must be a non-empty array.",
            )
        )
        return

    node_families_by_id: dict[int, str] = {}
    slot_types_by_id: dict[int, str] = {}
    adjacency_by_id: dict[int, list[int]] = {}
    family_counts: dict[str, int] = {}
    slot_type_counts: dict[str, int] = {}
    uses_scaffold_slots = False

    for index, node in enumerate(nodes):
        if not isinstance(node, dict):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_map_template_node_entry",
                    f"MapTemplates.rules.nodes[{index}] must be an object.",
                )
            )
            continue

        node_id = node.get("node_id")
        if isinstance(node_id, bool) or not isinstance(node_id, int) or node_id < 0:
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_map_template_node_id",
                    f"MapTemplates.rules.nodes[{index}].node_id must be a non-negative integer.",
                )
            )
            continue

        if node_id in adjacency_by_id:
            errors.append(
                ValidationError(
                    json_path,
                    "duplicate_map_template_node_id",
                    f"MapTemplates.rules.nodes[{index}] reuses node_id {node_id}.",
                )
            )
            continue

        node_family = node.get("node_family")
        slot_type = node.get("slot_type")
        if node_family is not None and slot_type is not None:
            errors.append(
                ValidationError(
                    json_path,
                    "conflicting_map_template_node_shape",
                    f"MapTemplates.rules.nodes[{index}] must not define both node_family and slot_type.",
                )
            )
            continue
        if slot_type is not None:
            if not isinstance(slot_type, str) or slot_type not in SUPPORTED_MAP_TEMPLATE_SLOT_TYPES:
                errors.append(
                    ValidationError(
                        json_path,
                        "unsupported_map_template_slot_type",
                        "MapTemplates.rules.nodes[%d].slot_type must be one of: %s."
                        % (index, ", ".join(sorted(SUPPORTED_MAP_TEMPLATE_SLOT_TYPES))),
                    )
                )
                continue
            uses_scaffold_slots = True
            slot_types_by_id[node_id] = slot_type
            slot_type_counts[slot_type] = slot_type_counts.get(slot_type, 0) + 1
        elif not isinstance(node_family, str) or node_family not in SUPPORTED_MAP_TEMPLATE_NODE_FAMILIES:
            errors.append(
                ValidationError(
                    json_path,
                    "unsupported_map_template_node_family",
                    "MapTemplates.rules.nodes[%d].node_family must be one of: %s."
                    % (index, ", ".join(sorted(SUPPORTED_MAP_TEMPLATE_NODE_FAMILIES))),
                )
            )
            continue

        adjacent_node_ids = node.get("adjacent_node_ids")
        if not isinstance(adjacent_node_ids, list):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_map_template_adjacent_node_ids",
                    f"MapTemplates.rules.nodes[{index}].adjacent_node_ids must be an array.",
                )
            )
            continue

        normalized_adjacent_ids: list[int] = []
        for adjacent_index, adjacent_node_id in enumerate(adjacent_node_ids):
            if isinstance(adjacent_node_id, bool) or not isinstance(adjacent_node_id, int) or adjacent_node_id < 0:
                errors.append(
                    ValidationError(
                        json_path,
                        "invalid_map_template_adjacent_node_id",
                        f"MapTemplates.rules.nodes[{index}].adjacent_node_ids[{adjacent_index}] must be a non-negative integer.",
                    )
                )
                continue
            if adjacent_node_id == node_id:
                errors.append(
                    ValidationError(
                        json_path,
                        "self_referential_map_template_edge",
                        f"MapTemplates.rules.nodes[{index}] must not include its own node_id {node_id} in adjacent_node_ids.",
                    )
                )
                continue
            if adjacent_node_id in normalized_adjacent_ids:
                errors.append(
                    ValidationError(
                        json_path,
                        "duplicate_map_template_adjacent_node_id",
                        f"MapTemplates.rules.nodes[{index}] reuses adjacent node id {adjacent_node_id}.",
                    )
                )
                continue
            normalized_adjacent_ids.append(adjacent_node_id)

        if isinstance(node_family, str):
            node_families_by_id[node_id] = node_family
            family_counts[node_family] = family_counts.get(node_family, 0) + 1
        adjacency_by_id[node_id] = normalized_adjacent_ids

    if not adjacency_by_id:
        return

    if node_families_by_id.get(0) != "start":
        errors.append(
            ValidationError(
                json_path,
                "invalid_map_template_start_anchor",
                "MapTemplates must keep node_id 0 as the single start anchor for the current save-compatible slice.",
            )
        )

    if uses_scaffold_slots:
        validate_map_scaffold_runtime_support(
            json_path,
            family_counts,
            slot_type_counts,
            errors,
        )
    else:
        validate_fixed_map_template_runtime_support(
            json_path,
            family_counts,
            errors,
        )

    for node_id, adjacent_node_ids in adjacency_by_id.items():
        for adjacent_node_id in adjacent_node_ids:
            if adjacent_node_id not in adjacency_by_id:
                errors.append(
                    ValidationError(
                        json_path,
                        "missing_map_template_adjacent_reference",
                        f"MapTemplates node_id {node_id} references missing adjacent node_id {adjacent_node_id}.",
                    )
                )
                continue
            if node_id not in adjacency_by_id[adjacent_node_id]:
                errors.append(
                    ValidationError(
                        json_path,
                        "asymmetric_map_template_edge",
                        f"MapTemplates edge {node_id} <-> {adjacent_node_id} must be bidirectional.",
                    )
                )

    unreachable_node_ids = collect_unreachable_map_template_node_ids(adjacency_by_id, 0)
    if unreachable_node_ids:
        errors.append(
            ValidationError(
                json_path,
                "disconnected_map_template_graph",
                "MapTemplates must keep every node reachable from start node_id 0 in the current runtime-backed slice. "
                f"Unreachable node_ids: {', '.join(str(node_id) for node_id in unreachable_node_ids)}.",
            )
        )


def validate_fixed_map_template_runtime_support(
    json_path: Path,
    family_counts: dict[str, int],
    errors: list["ValidationIssue"],
) -> None:
    for required_single_family in ("start", "key", "boss"):
        if family_counts.get(required_single_family, 0) != 1:
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_map_template_required_family_count",
                    f"MapTemplates must contain exactly one '{required_single_family}' node in the current runtime-backed slice.",
                )
            )

    if family_counts.get("combat", 0) < 3:
        errors.append(
            ValidationError(
                json_path,
                "insufficient_map_template_combat_nodes",
                "MapTemplates must contain at least 3 non-boss combat nodes in the current runtime-backed slice.",
            )
        )

    if family_counts.get("reward", 0) < 1:
        errors.append(
            ValidationError(
                json_path,
                "missing_map_template_reward_node",
                "MapTemplates must contain at least 1 reward node in the current runtime-backed slice.",
            )
        )

    support_node_count = (
        family_counts.get("rest", 0)
        + family_counts.get("merchant", 0)
        + family_counts.get("blacksmith", 0)
    )
    if support_node_count < 1:
        errors.append(
            ValidationError(
                json_path,
                "missing_map_template_support_node",
                "MapTemplates must contain at least 1 support node in the current runtime-backed slice.",
            )
        )

    prep_valve_count = family_counts.get("rest", 0) + family_counts.get("blacksmith", 0)
    if prep_valve_count < 1:
        errors.append(
            ValidationError(
                json_path,
                "missing_map_template_prep_valve",
                "MapTemplates must contain at least 1 prep-valve node (`rest` or `blacksmith`) in the current runtime-backed slice.",
            )
        )


def validate_event_template_runtime_support(
    json_path: Path,
    rules: dict,
    errors: list["ValidationIssue"],
) -> None:
    choices = rules.get("choices", [])
    if not isinstance(choices, list) or len(choices) != 2:
        errors.append(
            ValidationError(
                json_path,
                "invalid_event_choices",
                "EventTemplates.rules.choices must be an array with exactly 2 entries in the current runtime-backed slice.",
            )
        )
        return

    seen_choice_ids: set[str] = set()
    for index, choice in enumerate(choices):
        if not isinstance(choice, dict):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_event_choice_entry",
                    f"EventTemplates.rules.choices[{index}] must be an object.",
                )
            )
            continue

        choice_id = choice.get("choice_id")
        if not isinstance(choice_id, str) or not choice_id.strip():
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_event_choice_id",
                    f"EventTemplates.rules.choices[{index}].choice_id must be a non-empty string.",
                )
            )
        elif choice_id in seen_choice_ids:
            errors.append(
                ValidationError(
                    json_path,
                    "duplicate_event_choice_id",
                    f"EventTemplates.rules.choices[{index}] reuses choice_id '{choice_id}'.",
                )
            )
        else:
            seen_choice_ids.add(choice_id)

        label = choice.get("label")
        if not isinstance(label, str) or not label.strip():
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_event_choice_label",
                    f"EventTemplates.rules.choices[{index}].label must be a non-empty string.",
                )
            )

        summary = choice.get("summary")
        if not isinstance(summary, str) or not summary.strip():
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_event_choice_summary",
                    f"EventTemplates.rules.choices[{index}].summary must be a non-empty string.",
                )
            )

        effect_type = choice.get("effect_type")
        if not isinstance(effect_type, str) or effect_type not in SUPPORTED_EVENT_EFFECT_TYPES:
            errors.append(
                ValidationError(
                    json_path,
                    "unsupported_event_effect_type",
                    "EventTemplates.rules.choices[%d].effect_type must be one of: %s."
                    % (index, ", ".join(sorted(SUPPORTED_EVENT_EFFECT_TYPES))),
                )
            )
            continue

        amount = choice.get("amount")
        if effect_type in {"grant_gold", "grant_xp", "heal", "damage_player"}:
            if not isinstance(amount, int) or amount <= 0:
                errors.append(
                    ValidationError(
                        json_path,
                        "invalid_event_amount",
                        f"EventTemplates.rules.choices[{index}].amount must be a positive integer for effect_type '{effect_type}'.",
                    )
                )
        elif effect_type == "modify_hunger":
            if not isinstance(amount, int) or amount == 0:
                errors.append(
                    ValidationError(
                        json_path,
                        "invalid_event_hunger_amount",
                        f"EventTemplates.rules.choices[{index}].amount must be a non-zero integer for effect_type '{effect_type}'.",
                    )
                )
        elif amount is not None:
            errors.append(
                ValidationError(
                    json_path,
                    "unexpected_event_amount",
                    f"EventTemplates.rules.choices[{index}] must not define amount for effect_type '{effect_type}'.",
                )
            )


def validate_map_scaffold_runtime_support(
    json_path: Path,
    family_counts: dict[str, int],
    slot_type_counts: dict[str, int],
    errors: list["ValidationIssue"],
) -> None:
    required_fixed_family_counts = {
        "start": 1,
        "combat": 2,
        "reward": 1,
        "boss": 1,
    }
    for family, expected_count in required_fixed_family_counts.items():
        if family_counts.get(family, 0) != expected_count:
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_map_scaffold_fixed_family_count",
                    f"Procedural scaffold templates must contain exactly {expected_count} fixed '{family}' nodes.",
                )
            )

    for disallowed_fixed_family in ("rest", "merchant", "blacksmith", "side_mission", "key", "event"):
        if family_counts.get(disallowed_fixed_family, 0) != 0:
            errors.append(
                ValidationError(
                    json_path,
                    "unexpected_map_scaffold_fixed_family",
                    f"Procedural scaffold templates must not pre-place fixed '{disallowed_fixed_family}' nodes.",
                )
            )

    required_slot_counts = {
        "opening_support": 1,
        "late_event": 1,
        "late_side_mission": 1,
    }
    for slot_type, expected_count in required_slot_counts.items():
        if slot_type_counts.get(slot_type, 0) != expected_count:
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_map_scaffold_slot_count",
                    f"Procedural scaffold templates must contain exactly {expected_count} '{slot_type}' slots.",
                )
            )

    if slot_type_counts.get("late_primary", 0) < 6:
        errors.append(
            ValidationError(
                json_path,
                "invalid_map_scaffold_slot_count",
                "Procedural scaffold templates must contain at least 6 'late_primary' slots.",
            )
        )


def validate_side_mission_runtime_support(
    json_path: Path,
    rules: dict,
    errors: list["ValidationIssue"],
    content_root: Path,
) -> None:
    mission_type = rules.get("mission_type")
    if not isinstance(mission_type, str) or mission_type not in SUPPORTED_SIDE_MISSION_TYPES:
        errors.append(
            ValidationError(
                json_path,
                "invalid_side_mission_type",
                "SideMissions.rules.mission_type must be one of: %s."
                % ", ".join(sorted(SUPPORTED_SIDE_MISSION_TYPES)),
            )
        )

    for field_name in (
        "briefing_text",
        "accept_label",
        "accepted_text",
        "reminder_label",
        "completed_text",
        "claimed_text",
        "claimed_label",
    ):
        value = rules.get(field_name)
        if not isinstance(value, str) or not value.strip():
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_side_mission_text",
                    f"SideMissions.rules.{field_name} must be a non-empty string.",
                )
            )

    reward_pool = rules.get("reward_pool", [])
    if not isinstance(reward_pool, list) or len(reward_pool) < 2:
        errors.append(
            ValidationError(
                json_path,
                "invalid_side_mission_reward_pool",
                "SideMissions.rules.reward_pool must be an array with at least 2 entries.",
            )
        )
        return

    seen_offer_ids: set[str] = set()
    for index, reward_offer in enumerate(reward_pool):
        if not isinstance(reward_offer, dict):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_side_mission_reward_offer",
                    f"SideMissions.rules.reward_pool[{index}] must be an object.",
                )
            )
            continue

        offer_id = reward_offer.get("offer_id")
        if not isinstance(offer_id, str) or not offer_id.strip():
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_side_mission_reward_offer_id",
                    f"SideMissions.rules.reward_pool[{index}].offer_id must be a non-empty string.",
                )
            )
        elif offer_id in seen_offer_ids:
            errors.append(
                ValidationError(
                    json_path,
                    "duplicate_side_mission_reward_offer_id",
                    f"SideMissions.rules.reward_pool[{index}] reuses offer_id '{offer_id}'.",
                )
            )
        else:
            seen_offer_ids.add(offer_id)

        inventory_family = reward_offer.get("inventory_family")
        if not isinstance(inventory_family, str) or inventory_family not in {"weapon", "armor"}:
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_side_mission_reward_family",
                    "SideMissions.rules.reward_pool[%d].inventory_family must be 'weapon' or 'armor'." % index,
                )
            )
            continue

        definition_id = reward_offer.get("definition_id")
        if not isinstance(definition_id, str) or not definition_id.strip():
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_side_mission_reward_definition_id",
                    f"SideMissions.rules.reward_pool[{index}].definition_id must be a non-empty string.",
                )
            )
            continue

        validate_cross_family_reference(
            json_path,
            content_root,
            "Weapons" if inventory_family == "weapon" else "Armors",
            definition_id,
            f"SideMissions.rules.reward_pool[{index}].definition_id",
            errors,
        )


def collect_unreachable_map_template_node_ids(
    adjacency_by_id: dict[int, list[int]],
    start_node_id: int,
) -> list[int]:
    if start_node_id not in adjacency_by_id:
        return sorted(adjacency_by_id.keys())

    visited: set[int] = set()
    queued_node_ids: deque[int] = deque([start_node_id])
    while queued_node_ids:
        node_id = queued_node_ids.popleft()
        if node_id in visited:
            continue
        visited.add(node_id)
        for adjacent_node_id in adjacency_by_id.get(node_id, []):
            if adjacent_node_id not in visited:
                queued_node_ids.append(adjacent_node_id)

    return sorted(node_id for node_id in adjacency_by_id if node_id not in visited)


def validate_reward_runtime_support(
    json_path: Path,
    rules: dict,
    errors: list["ValidationIssue"],
) -> None:
    offers = rules.get("offers", [])
    offer_pool = rules.get("offer_pool", [])
    if offers and offer_pool:
        errors.append(
            ValidationError(
                json_path,
                "conflicting_reward_offer_shapes",
                "Rewards.rules must define either offers or offer_pool, not both.",
            )
        )
        return

    reward_entries = offer_pool if offer_pool else offers
    if not isinstance(reward_entries, list) or not reward_entries:
        errors.append(
            ValidationError(
                json_path,
                "invalid_reward_offers",
                "Rewards.rules.offers or Rewards.rules.offer_pool must be a non-empty array in the current runtime-backed slice.",
            )
        )
        return

    if offer_pool:
        selection_mode = rules.get("selection_mode")
        if not isinstance(selection_mode, str) or selection_mode not in SUPPORTED_REWARD_SELECTION_MODES:
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_reward_selection_mode",
                    "Rewards.rules.selection_mode must be one of: %s when offer_pool is used."
                    % ", ".join(sorted(SUPPORTED_REWARD_SELECTION_MODES)),
                )
            )

        present_count = rules.get("present_count")
        if not isinstance(present_count, int) or present_count <= 0:
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_reward_present_count",
                    "Rewards.rules.present_count must be a positive integer when offer_pool is used.",
                )
            )
        elif present_count > len(offer_pool):
            errors.append(
                ValidationError(
                    json_path,
                    "reward_present_count_exceeds_pool",
                    "Rewards.rules.present_count must not exceed the number of entries in offer_pool.",
                )
            )

    seen_offer_ids: set[str] = set()
    for index, offer in enumerate(reward_entries):
        if not isinstance(offer, dict):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_reward_offer_entry",
                    f"Rewards reward entry [{index}] must be an object.",
                )
            )
            continue

        offer_id = offer.get("offer_id")
        if not isinstance(offer_id, str) or not offer_id.strip():
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_reward_offer_id",
                    f"Rewards reward entry [{index}].offer_id must be a non-empty string.",
                )
            )
        elif offer_id in seen_offer_ids:
            errors.append(
                ValidationError(
                    json_path,
                    "duplicate_reward_offer_id",
                    f"Rewards reward entry [{index}] reuses offer_id '{offer_id}'.",
                )
            )
        else:
            seen_offer_ids.add(offer_id)

        label = offer.get("label")
        if not isinstance(label, str) or not label.strip():
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_reward_offer_label",
                    f"Rewards reward entry [{index}].label must be a non-empty string.",
                )
            )

        effect_type = offer.get("effect_type")
        if not isinstance(effect_type, str) or effect_type not in SUPPORTED_REWARD_EFFECT_TYPES:
            errors.append(
                ValidationError(
                    json_path,
                    "unsupported_reward_effect_type",
                    "Rewards reward entry [%d].effect_type must be one of: %s."
                    % (index, ", ".join(sorted(SUPPORTED_REWARD_EFFECT_TYPES))),
                )
            )
            continue

        amount = offer.get("amount")
        if effect_type in {"heal", "grant_xp", "grant_gold"}:
            if not isinstance(amount, int) or amount <= 0:
                errors.append(
                    ValidationError(
                        json_path,
                        "invalid_reward_amount",
                        f"Rewards reward entry [{index}].amount must be a positive integer for effect_type '{effect_type}'.",
                    )
                )
        elif amount is not None:
            errors.append(
                ValidationError(
                    json_path,
                    "unexpected_reward_amount",
                    f"Rewards reward entry [{index}] must not define amount for effect_type '{effect_type}'.",
                )
            )


def validate_enemy_intent_effect(
    json_path: Path,
    effect: object,
    intent_index: int,
    effect_index: int,
    errors: list["ValidationIssue"],
    content_root: Path,
) -> None:
    if not isinstance(effect, dict):
        return

    if effect.get("type") != "apply_status":
        return

    params = effect.get("params")
    if not isinstance(params, dict):
        return

    definition_id = params.get("definition_id")
    if not isinstance(definition_id, str) or not definition_id.strip():
        errors.append(
            ValidationError(
                json_path,
                "invalid_status_definition_id",
                f"Enemies.rules.intent_pool[{intent_index}].effects[{effect_index}].params.definition_id must be a non-empty string.",
            )
        )
        return

    referenced_status_path = content_root / "Statuses" / f"{definition_id}.json"
    if not referenced_status_path.exists():
        errors.append(
            ValidationError(
                json_path,
                "missing_status_reference",
                f"Enemies.rules.intent_pool[{intent_index}].effects[{effect_index}] references missing status definition '{definition_id}'.",
            )
        )

    duration_turns = params.get("duration_turns")
    if duration_turns is not None and (not isinstance(duration_turns, int) or duration_turns <= 0):
        errors.append(
            ValidationError(
                json_path,
                "invalid_status_duration_override",
                f"Enemies.rules.intent_pool[{intent_index}].effects[{effect_index}].params.duration_turns must be a positive integer when present.",
            )
        )

    stacks = params.get("stacks")
    if stacks is not None and (not isinstance(stacks, int) or stacks <= 0):
        errors.append(
            ValidationError(
                json_path,
                "invalid_status_stack_override",
                f"Enemies.rules.intent_pool[{intent_index}].effects[{effect_index}].params.stacks must be a positive integer when present.",
            )
        )


def validate_passive_item_runtime_support(
    json_path: Path,
    rules: dict,
    errors: list["ValidationIssue"],
) -> None:
    behaviors = rules.get("behaviors", [])
    if not isinstance(behaviors, list) or not behaviors:
        errors.append(
            ValidationError(
                json_path,
                "missing_passive_item_behaviors",
                "PassiveItems.rules.behaviors must be a non-empty array in the current runtime-backed slice.",
            )
        )
        return

    for index, behavior in enumerate(behaviors):
        validate_passive_item_behavior(json_path, behavior, index, errors)


def validate_passive_item_behavior(
    json_path: Path,
    behavior: object,
    index: int,
    errors: list["ValidationIssue"],
) -> None:
    if not isinstance(behavior, dict):
        errors.append(
            ValidationError(
                json_path,
                "invalid_passive_item_behavior_entry",
                f"PassiveItems.rules.behaviors[{index}] must be an object.",
            )
        )
        return

    trigger = behavior.get("trigger")
    if not isinstance(trigger, str) or trigger not in SUPPORTED_PASSIVE_ITEM_BEHAVIOR_TRIGGERS:
        errors.append(
            ValidationError(
                json_path,
                "unsupported_passive_item_behavior_trigger",
                f"PassiveItems.rules.behaviors[{index}].trigger must be one of: {', '.join(sorted(SUPPORTED_PASSIVE_ITEM_BEHAVIOR_TRIGGERS))}.",
            )
        )

    validate_rule_condition(json_path, behavior.get("condition", None), f"PassiveItems.rules.behaviors[{index}].condition", errors)
    target_value = behavior.get("target", None)
    validate_rule_target(json_path, target_value, f"PassiveItems.rules.behaviors[{index}].target", errors)
    if target_value is not None and str(target_value) != "self":
        errors.append(
            ValidationError(
                json_path,
                "unsupported_passive_item_target",
                f"PassiveItems.rules.behaviors[{index}].target must be 'self' in the current runtime-backed slice.",
            )
        )
    validate_effect_array(
        json_path,
        behavior.get("effects", []),
        SUPPORTED_PASSIVE_ITEM_BEHAVIOR_EFFECTS,
        f"PassiveItems.rules.behaviors[{index}].effects",
        errors,
    )


def validate_equipment_runtime_support(
    json_path: Path,
    family: str,
    rules: dict,
    errors: list["ValidationIssue"],
) -> None:
    behaviors = rules.get("behaviors", [])
    if not isinstance(behaviors, list) or not behaviors:
        errors.append(
            ValidationError(
                json_path,
                "missing_equipment_behaviors",
                f"{family}.rules.behaviors must be a non-empty array in the current runtime-backed slice.",
            )
        )
        return

    for index, behavior in enumerate(behaviors):
        validate_equipment_behavior(json_path, family, behavior, index, errors)


def validate_equipment_behavior(
    json_path: Path,
    family: str,
    behavior: object,
    index: int,
    errors: list["ValidationIssue"],
) -> None:
    if not isinstance(behavior, dict):
        errors.append(
            ValidationError(
                json_path,
                "invalid_equipment_behavior_entry",
                f"{family}.rules.behaviors[{index}] must be an object.",
            )
        )
        return

    trigger = behavior.get("trigger")
    if not isinstance(trigger, str) or trigger not in SUPPORTED_EQUIPMENT_BEHAVIOR_TRIGGERS:
        errors.append(
            ValidationError(
                json_path,
                "unsupported_equipment_behavior_trigger",
                f"{family}.rules.behaviors[{index}].trigger must be one of: {', '.join(sorted(SUPPORTED_EQUIPMENT_BEHAVIOR_TRIGGERS))}.",
            )
        )

    validate_rule_condition(json_path, behavior.get("condition", None), f"{family}.rules.behaviors[{index}].condition", errors)
    target_value = behavior.get("target", None)
    validate_rule_target(json_path, target_value, f"{family}.rules.behaviors[{index}].target", errors)
    if target_value is not None and str(target_value) != "self":
        errors.append(
            ValidationError(
                json_path,
                "unsupported_equipment_target",
                f"{family}.rules.behaviors[{index}].target must be 'self' in the current runtime-backed slice.",
            )
        )
    validate_effect_array(
        json_path,
        behavior.get("effects", []),
        SUPPORTED_EQUIPMENT_BEHAVIOR_EFFECTS,
        f"{family}.rules.behaviors[{index}].effects",
        errors,
    )


def validate_rule_condition(
    json_path: Path,
    condition_value: object,
    location: str,
    errors: list["ValidationIssue"],
) -> None:
    if condition_value is None:
        return

    if not isinstance(condition_value, dict):
        errors.append(
            ValidationError(json_path, "invalid_condition", f"{location} must be an object when present.")
        )
        return

    op = condition_value.get("op")
    if not isinstance(op, str) or op not in SUPPORTED_CONDITION_OPS:
        errors.append(
            ValidationError(
                json_path,
                "unsupported_condition_op",
                f"{location}.op must be one of: {', '.join(sorted(SUPPORTED_CONDITION_OPS))}.",
            )
        )
        return

    if op == "always":
        return

    stat_name = condition_value.get("stat")
    if not isinstance(stat_name, str) or not stat_name.strip():
        errors.append(
            ValidationError(
                json_path,
                "invalid_condition_stat",
                f"{location}.stat must be a non-empty string for comparison operators.",
            )
        )
        return

    if "." in stat_name:
        errors.append(
            ValidationError(
                json_path,
                "unsupported_condition_path",
                f"{location}.stat does not support nested paths in current runtime.",
            )
        )

    if stat_name == "random_roll_percent":
        errors.append(
            ValidationError(
                json_path,
                "reserved_random_roll_percent",
                f"{location}.stat must not use random_roll_percent in current canonical content.",
            )
        )

    if "value" not in condition_value:
        errors.append(
            ValidationError(
                json_path,
                "missing_condition_value",
                f"{location}.value is required for comparison operators.",
            )
        )


def validate_rule_target(
    json_path: Path,
    target_value: object,
    location: str,
    errors: list["ValidationIssue"],
) -> None:
    if target_value is None:
        return

    if not isinstance(target_value, str) or target_value not in SUPPORTED_AUTHORING_TARGETS:
        errors.append(
            ValidationError(
                json_path,
                "unsupported_target",
                f"{location} must be one of: {', '.join(sorted(SUPPORTED_AUTHORING_TARGETS))}.",
            )
        )


def validate_effect_array(
    json_path: Path,
    effects_value: object,
    allowed_effect_types: set[str],
    location: str,
    errors: list["ValidationIssue"],
) -> None:
    if not isinstance(effects_value, list):
        errors.append(
            ValidationError(json_path, "invalid_effects", f"{location} must be an array.")
        )
        return

    for index, effect in enumerate(effects_value):
        if not isinstance(effect, dict):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_effect_entry",
                    f"{location}[{index}] must be an object.",
                )
            )
            continue

        effect_type = effect.get("type")
        if not isinstance(effect_type, str) or effect_type not in allowed_effect_types:
            errors.append(
                ValidationError(
                    json_path,
                    "unsupported_effect_type",
                    f"{location}[{index}].type must be one of: {', '.join(sorted(allowed_effect_types))}.",
                )
            )

        params = effect.get("params")
        if not isinstance(params, dict):
            errors.append(
                ValidationError(
                    json_path,
                    "invalid_effect_params",
                    f"{location}[{index}].params must be an object.",
                )
            )


def validate_cross_family_reference(
    json_path: Path,
    content_root: Path,
    family: str,
    definition_id: str,
    location: str,
    errors: list["ValidationIssue"],
) -> None:
    referenced_path = content_root / family / f"{definition_id}.json"
    if referenced_path.exists():
        return

    errors.append(
        ValidationError(
            json_path,
            "missing_content_reference",
            f"{location} references missing {family} definition '{definition_id}'.",
        )
    )


def family_for_merchant_stock_entry(effect_type: str) -> str:
    if effect_type == "buy_consumable":
        return "Consumables"
    return "Weapons"


def is_shorthand_intent_value(value: str) -> bool:
    return bool(re.fullmatch(r"[a-z_]+", value))


class ValidationIssue:
    def __init__(self, path: Path, error_type: str, message: str) -> None:
        self.path = str(path)
        self.error_type = error_type
        self.message = message


class ValidationError(ValidationIssue):
    pass


class ValidationWarning(ValidationIssue):
    pass


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
