from __future__ import annotations

import argparse
import copy
import heapq
import json
import math
from dataclasses import dataclass
from pathlib import Path
from statistics import mean


REPO_ROOT = Path(__file__).resolve().parents[1]
CONTENT_ROOT = REPO_ROOT / "ContentDefinitions"
DOC_PATH = REPO_ROOT / "Docs" / "BALANCE_ANALYSIS.md"

DEFAULT_PLAYER_HP = 60
DEFAULT_PLAYER_HUNGER = 0
HUNGRY_THRESHOLD = 70
STARVING_THRESHOLD = 90
MAX_HUNGER = 100
MOVE_HUNGER_COST = 3
COMBAT_HUNGER_COST = 1
FALLBACK_ATTACK_DAMAGE = 1
BRACE_DAMAGE_MULTIPLIER = 0.5

LIVE_STAGE_SUPPORT_LAYOUTS = {
    1: {"opening_support_family": "rest", "late_support_family": "merchant"},
    2: {"opening_support_family": "merchant", "late_support_family": "blacksmith"},
    3: {"opening_support_family": "rest", "late_support_family": "blacksmith"},
}
LIVE_STAGE_TEMPLATES = {
    1: "procedural_stage_corridor_v1",
    2: "procedural_stage_openfield_v1",
    3: "procedural_stage_loop_v1",
}
LIVE_STAGE_MERCHANT_STOCK_IDS = {
    1: "basic_merchant_stock",
    2: "stage_2_merchant_stock",
    3: "stage_3_merchant_stock",
}


@dataclass
class CombatOutcome:
    enemy_id: str
    policy: str
    outcome: str
    turns_taken: int
    hp_lost: int
    hunger_gained: int
    durability_spent: int
    consumables_used: int
    enemy_name: str


def _load_definition(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def load_family(family: str) -> dict[str, dict]:
    family_root = CONTENT_ROOT / family
    return {
        path.stem: _load_definition(path)
        for path in sorted(family_root.glob("*.json"))
    }


def sort_by_authoring_order(definitions: dict[str, dict]) -> list[tuple[str, dict]]:
    return sorted(
        definitions.items(),
        key=lambda item: (
            int(item[1].get("authoring_order", 2_147_483_647)),
            item[0],
        ),
    )


def extract_consumable_profile(definition: dict) -> dict:
    effects = (
        definition.get("rules", {})
        .get("use_effect", {})
        .get("effects", [])
    )
    heal = 0
    hunger_delta = 0
    for effect in effects:
        params = effect.get("params", {})
        if effect.get("type") == "heal":
            heal += int(params.get("base", 0))
        elif effect.get("type") == "modify_hunger":
            hunger_delta += int(params.get("amount", 0))
    return {"heal_amount": heal, "hunger_delta": hunger_delta}


def extract_passive_modifiers(definition: dict) -> dict[str, int]:
    totals: dict[str, int] = {}
    for behavior in definition.get("rules", {}).get("behaviors", []):
        if behavior.get("trigger") != "passive":
            continue
        if behavior.get("target") != "self":
            continue
        for effect in behavior.get("effects", []):
            if effect.get("type") != "modify_stat":
                continue
            params = effect.get("params", {})
            stat = str(params.get("stat", ""))
            if not stat:
                continue
            totals[stat] = totals.get(stat, 0) + int(params.get("amount", 0))
    return totals


def extract_status_template(definition: dict, duration_override: int = 0, stack_override: int = 1) -> dict:
    stats = definition.get("rules", {}).get("stats", {})
    remaining_turns = int(duration_override) if int(duration_override) > 0 else int(stats.get("duration_turns", 0))
    stacks = max(1, int(stack_override))
    return {
        "definition_id": definition.get("definition_id", ""),
        "display_name": definition.get("display", {}).get("name", definition.get("definition_id", "")),
        "damage_per_turn": int(stats.get("damage_per_turn", 0)),
        "stat_modifiers": {
            str(key): int(value)
            for key, value in stats.get("stat_modifiers", {}).items()
        },
        "remaining_turns": remaining_turns,
        "stacks": stacks,
        "max_stacks": max(1, int(stats.get("max_stacks", 1))),
    }


def resolve_hunger_attack_penalty(hunger: int) -> int:
    if hunger >= STARVING_THRESHOLD:
        return -2
    if hunger >= HUNGRY_THRESHOLD:
        return -1
    return 0


def condition_matches(condition: dict | None, source_state: dict, target_state: dict) -> bool:
    if condition is None:
        return True
    if not isinstance(condition, dict):
        return False
    op = str(condition.get("op", "always"))
    if op == "always":
        return True
    stat_name = str(condition.get("stat", ""))
    if stat_name in source_state:
        state_value = source_state.get(stat_name)
    elif stat_name in target_state:
        state_value = target_state.get(stat_name)
    else:
        return False
    value = condition.get("value")
    if op == "lte":
        return float(state_value) <= float(value)
    if op == "lt":
        return float(state_value) < float(value)
    if op == "gte":
        return float(state_value) >= float(value)
    if op == "gt":
        return float(state_value) > float(value)
    if op == "eq":
        return state_value == value
    if op == "neq":
        return state_value != value
    return False


def apply_passive_definition_effects(state: dict, definition: dict) -> dict:
    hydrated = copy.deepcopy(state)
    rules = definition.get("rules", {})
    for behavior in rules.get("behaviors", []):
        if behavior.get("trigger") != "passive":
            continue
        if not condition_matches(behavior.get("condition"), hydrated, hydrated):
            continue
        for effect in behavior.get("effects", []):
            if effect.get("type") != "modify_stat":
                continue
            params = effect.get("params", {})
            stat_name = str(params.get("stat", ""))
            if not stat_name:
                continue
            hydrated[stat_name] = int(hydrated.get(stat_name, 0)) + int(params.get("amount", 0))
    return hydrated


def prepare_enemy_state(enemy_state: dict) -> dict:
    working = copy.deepcopy(enemy_state)
    definition = copy.deepcopy(working.get("definition", {}))
    stats = definition.get("rules", {}).get("stats", {})
    for stat_key, stat_value in stats.items():
        working.setdefault(stat_key, stat_value)
    return apply_passive_definition_effects(working, definition)


def build_effective_player_state(runtime: dict) -> dict:
    state = copy.deepcopy(runtime["player"])
    for status in runtime["player_statuses"]:
        stacks = max(1, int(status.get("stacks", 1)))
        for stat_name, amount in status.get("stat_modifiers", {}).items():
            state[stat_name] = int(state.get(stat_name, 0)) + int(amount) * stacks
    return state


def reduce_durability(weapon_instance: dict, amount: int) -> dict:
    updated = copy.deepcopy(weapon_instance)
    updated["current_durability"] = max(0, int(updated.get("current_durability", 0)) - max(0, amount))
    return updated


def apply_damage(target_state: dict, amount: int) -> dict:
    updated = copy.deepcopy(target_state)
    updated["hp"] = max(0, int(updated.get("hp", 0)) - max(0, amount))
    return updated


def extract_intent_damage(intent: dict) -> int:
    total = 0
    for effect in intent.get("effects", []):
        if effect.get("type") != "deal_damage":
            continue
        total += int(effect.get("params", {}).get("base", 0))
    return total


def projected_status_tick_damage(intent: dict, status_defs: dict[str, dict]) -> int:
    total = 0
    for effect in intent.get("effects", []):
        if effect.get("type") != "apply_status":
            continue
        params = effect.get("params", {})
        definition_id = str(params.get("definition_id", ""))
        if definition_id not in status_defs:
            continue
        status = extract_status_template(
            status_defs[definition_id],
            duration_override=int(params.get("duration_turns", 0)),
            stack_override=int(params.get("stacks", 1)),
        )
        total += int(status.get("damage_per_turn", 0)) * int(status.get("stacks", 1))
    return total


def current_turn_end_status_damage(runtime: dict) -> int:
    total = 0
    for status in runtime["player_statuses"]:
        total += int(status.get("damage_per_turn", 0)) * max(1, int(status.get("stacks", 1)))
    return total


def earliest_usable_consumable_slot(runtime: dict, consumable_defs: dict[str, dict]) -> int:
    slots = runtime["player"].get("consumable_slots", [])
    player_hp = int(runtime["player"]["hp"])
    player_hunger = int(runtime["player"]["hunger"])
    missing_hp = DEFAULT_PLAYER_HP - player_hp
    for index, slot in enumerate(slots):
        if int(slot.get("current_stack", 0)) <= 0:
            continue
        definition_id = str(slot.get("definition_id", ""))
        definition = consumable_defs.get(definition_id)
        if not definition:
            continue
        profile = extract_consumable_profile(definition)
        if profile["heal_amount"] > 0 and missing_hp > 0:
            return index
        if profile["hunger_delta"] < 0 and player_hunger > 0:
            return index
    return -1


def projected_enemy_damage(runtime: dict, intent: dict, brace_active: bool = False) -> int:
    enemy = prepare_enemy_state(runtime["enemy"])
    player = build_effective_player_state(runtime)
    base = extract_intent_damage(intent)
    if base <= 0:
        base = int(enemy.get("base_damage", 0))
    damage = base + int(enemy.get("attack_power_bonus", 0))
    damage = max(0, damage - int(player.get("incoming_damage_flat_reduction", 0)))
    if brace_active and damage > 0:
        damage = int(math.ceil(float(damage) * BRACE_DAMAGE_MULTIPLIER))
    return damage


def choose_action_baseline_safe(runtime: dict, weapon_def: dict, consumable_defs: dict[str, dict], status_defs: dict[str, dict]) -> tuple[str, int]:
    intent = runtime["current_intent"]
    player_hp = int(runtime["player"]["hp"])
    projected_damage = projected_enemy_damage(runtime, intent, brace_active=False)
    braced_damage = projected_enemy_damage(runtime, intent, brace_active=True)
    projected_new_status_damage = projected_status_tick_damage(intent, status_defs)
    existing_status_damage = current_turn_end_status_damage(runtime)
    usable_slot = earliest_usable_consumable_slot(runtime, consumable_defs)
    lethal_without_item = player_hp <= projected_damage + projected_new_status_damage + existing_status_damage

    if usable_slot >= 0 and (lethal_without_item or player_hp <= 16):
        return ("use_item", usable_slot)

    if (
        projected_damage >= 6
        or (player_hp <= projected_damage and braced_damage < player_hp)
        or (projected_new_status_damage >= 2 and projected_damage >= 3)
    ):
        return ("brace", -1)

    return ("attack", -1)


def choose_action_attack_only(runtime: dict, weapon_def: dict, consumable_defs: dict[str, dict], status_defs: dict[str, dict]) -> tuple[str, int]:
    return ("attack", -1)


def execute_player_attack(runtime: dict, weapon_def: dict) -> None:
    player = build_effective_player_state(runtime)
    enemy = prepare_enemy_state(runtime["enemy"])
    weapon_instance = copy.deepcopy(player.get("weapon_instance", {}))
    used_fallback = int(weapon_instance.get("current_durability", 0)) <= 0
    attack_power_bonus = int(player.get("attack_power_bonus", 0)) + resolve_hunger_attack_penalty(int(player.get("hunger", 0)))
    defense_reduction = int(enemy.get("incoming_damage_flat_reduction", 0))
    base_damage = FALLBACK_ATTACK_DAMAGE
    if not used_fallback:
        weapon_stats = weapon_def.get("rules", {}).get("stats", {})
        base_damage = int(weapon_stats.get("base_damage", FALLBACK_ATTACK_DAMAGE))
        durability_cost = int(weapon_stats.get("durability_cost_per_attack", 1))
        durability_cost = max(0, durability_cost - int(player.get("durability_cost_flat_reduction", 0)))
        weapon_instance = reduce_durability(weapon_instance, durability_cost)
    damage = max(1, base_damage + attack_power_bonus - defense_reduction)
    runtime["enemy"] = apply_damage(runtime["enemy"], damage)
    runtime["player"]["weapon_instance"] = weapon_instance


def execute_player_use_item(runtime: dict, slot_index: int, consumable_defs: dict[str, dict]) -> bool:
    slots = runtime["player"].get("consumable_slots", [])
    if slot_index < 0 or slot_index >= len(slots):
        return False
    slot = copy.deepcopy(slots[slot_index])
    if int(slot.get("current_stack", 0)) <= 0:
        return False
    definition_id = str(slot.get("definition_id", ""))
    definition = consumable_defs.get(definition_id)
    if not definition:
        return False
    profile = extract_consumable_profile(definition)
    previous_hp = int(runtime["player"]["hp"])
    previous_hunger = int(runtime["player"]["hunger"])
    missing_hp = DEFAULT_PLAYER_HP - previous_hp
    healed_amount = min(profile["heal_amount"], missing_hp) if profile["heal_amount"] > 0 else 0
    next_hunger = previous_hunger
    if profile["hunger_delta"] < 0:
        next_hunger = max(0, min(MAX_HUNGER, previous_hunger + profile["hunger_delta"]))
    hunger_reduced = previous_hunger - next_hunger
    if healed_amount <= 0 and hunger_reduced <= 0:
        return False
    if healed_amount > 0:
        runtime["player"]["hp"] = min(DEFAULT_PLAYER_HP, previous_hp + healed_amount)
    if hunger_reduced > 0:
        runtime["player"]["hunger"] = next_hunger
    slot["current_stack"] = int(slot.get("current_stack", 0)) - 1
    if int(slot["current_stack"]) <= 0:
        del slots[slot_index]
    else:
        slots[slot_index] = slot
    return True


def execute_player_brace(runtime: dict) -> None:
    runtime["player"]["brace_active"] = True


def apply_status_from_intent(runtime: dict, intent: dict, status_defs: dict[str, dict]) -> None:
    for effect in intent.get("effects", []):
        if effect.get("type") != "apply_status":
            continue
        params = effect.get("params", {})
        definition_id = str(params.get("definition_id", ""))
        if definition_id not in status_defs:
            continue
        status_instance = extract_status_template(
            status_defs[definition_id],
            duration_override=int(params.get("duration_turns", 0)),
            stack_override=int(params.get("stacks", 1)),
        )
        if int(status_instance.get("remaining_turns", 0)) <= 0:
            continue
        refreshed = False
        for existing in runtime["player_statuses"]:
            if existing.get("definition_id") != definition_id:
                continue
            existing["remaining_turns"] = max(
                int(existing.get("remaining_turns", 0)),
                int(status_instance.get("remaining_turns", 0)),
            )
            existing["stacks"] = min(
                int(existing.get("max_stacks", 1)),
                max(int(existing.get("stacks", 1)), int(status_instance.get("stacks", 1))),
            )
            refreshed = True
            break
        if not refreshed:
            runtime["player_statuses"].append(status_instance)


def execute_enemy_action(runtime: dict, intent: dict, status_defs: dict[str, dict]) -> None:
    enemy = prepare_enemy_state(runtime["enemy"])
    player = build_effective_player_state(runtime)
    damage = extract_intent_damage(intent)
    if damage <= 0:
        damage = int(enemy.get("base_damage", 0))
    damage += int(enemy.get("attack_power_bonus", 0))
    damage = max(0, damage - int(player.get("incoming_damage_flat_reduction", 0)))
    if bool(player.get("brace_active", False)) and damage > 0:
        damage = int(math.ceil(float(damage) * BRACE_DAMAGE_MULTIPLIER))
    runtime["player"]["hp"] = max(0, int(runtime["player"]["hp"]) - damage)
    runtime["player"]["brace_active"] = False
    if int(runtime["player"]["hp"]) > 0:
        apply_status_from_intent(runtime, intent, status_defs)


def resolve_turn_end(runtime: dict) -> None:
    runtime["player"]["brace_active"] = False
    updated_statuses = []
    for status in runtime["player_statuses"]:
        remaining = int(status.get("remaining_turns", 0))
        if remaining <= 0:
            continue
        damage = int(status.get("damage_per_turn", 0)) * max(1, int(status.get("stacks", 1)))
        if damage > 0:
            runtime["player"]["hp"] = max(0, int(runtime["player"]["hp"]) - damage)
        remaining -= 1
        if remaining > 0:
            status_copy = copy.deepcopy(status)
            status_copy["remaining_turns"] = remaining
            updated_statuses.append(status_copy)
    runtime["player_statuses"] = updated_statuses
    if int(runtime["player"]["hp"]) <= 0:
        return
    runtime["player"]["hunger"] = min(MAX_HUNGER, int(runtime["player"]["hunger"]) + COMBAT_HUNGER_COST)
    if int(runtime["player"]["hunger"]) >= STARVING_THRESHOLD:
        runtime["player"]["hp"] = max(0, int(runtime["player"]["hp"]) - 1)
    runtime["turn"] += 1
    if runtime["intent_pool"]:
        runtime["intent_index"] = (runtime["intent_index"] + 1) % len(runtime["intent_pool"])
        runtime["current_intent"] = copy.deepcopy(runtime["intent_pool"][runtime["intent_index"]])


def simulate_combat(enemy_id: str, enemy_def: dict, weapon_def: dict, starter_slots: list[dict], passive_defs: dict[str, dict], consumable_defs: dict[str, dict], status_defs: dict[str, dict], policy_name: str) -> CombatOutcome:
    runtime = {
        "player": {
            "hp": DEFAULT_PLAYER_HP,
            "hunger": DEFAULT_PLAYER_HUNGER,
            "weapon_instance": {
                "definition_id": weapon_def.get("definition_id", ""),
                "current_durability": int(weapon_def.get("rules", {}).get("stats", {}).get("max_durability", 0)),
            },
            "consumable_slots": copy.deepcopy(starter_slots),
            "brace_active": False,
            "random_roll_percent": 100,
        },
        "enemy": {
            "hp": int(enemy_def.get("rules", {}).get("stats", {}).get("base_hp", 0)),
            "definition": copy.deepcopy(enemy_def),
        },
        "player_statuses": [],
        "turn": 1,
        "intent_pool": copy.deepcopy(enemy_def.get("rules", {}).get("intent_pool", [])),
        "intent_index": 0,
        "current_intent": copy.deepcopy(enemy_def.get("rules", {}).get("intent_pool", [{}])[0]) if enemy_def.get("rules", {}).get("intent_pool") else {},
    }

    for passive_def in passive_defs.values():
        for stat_name, amount in extract_passive_modifiers(passive_def).items():
            runtime["player"][stat_name] = int(runtime["player"].get(stat_name, 0)) + amount

    initial_weapon_durability = int(runtime["player"]["weapon_instance"]["current_durability"])
    initial_consumable_count = sum(int(slot.get("current_stack", 0)) for slot in runtime["player"]["consumable_slots"])
    policy_fn = choose_action_baseline_safe if policy_name == "safe" else choose_action_attack_only

    while runtime["turn"] <= 30:
        action_name, slot_index = policy_fn(runtime, weapon_def, consumable_defs, status_defs)
        if action_name == "attack":
            execute_player_attack(runtime, weapon_def)
        elif action_name == "brace":
            execute_player_brace(runtime)
        elif action_name == "use_item":
            used = execute_player_use_item(runtime, slot_index, consumable_defs)
            if not used:
                execute_player_attack(runtime, weapon_def)

        if int(runtime["enemy"]["hp"]) <= 0:
            break

        execute_enemy_action(runtime, runtime["current_intent"], status_defs)
        if int(runtime["player"]["hp"]) <= 0:
            break

        resolve_turn_end(runtime)
        if int(runtime["player"]["hp"]) <= 0 or int(runtime["enemy"]["hp"]) <= 0:
            break

    outcome = "victory" if int(runtime["enemy"]["hp"]) <= 0 and int(runtime["player"]["hp"]) > 0 else "defeat"
    final_consumable_count = sum(int(slot.get("current_stack", 0)) for slot in runtime["player"]["consumable_slots"])
    return CombatOutcome(
        enemy_id=enemy_id,
        policy=policy_name,
        outcome=outcome,
        turns_taken=int(runtime["turn"]),
        hp_lost=DEFAULT_PLAYER_HP - int(runtime["player"]["hp"]),
        hunger_gained=int(runtime["player"]["hunger"]) - DEFAULT_PLAYER_HUNGER,
        durability_spent=initial_weapon_durability - int(runtime["player"]["weapon_instance"].get("current_durability", 0)),
        consumables_used=initial_consumable_count - final_consumable_count,
        enemy_name=str(enemy_def.get("display", {}).get("name", enemy_id)),
    )


def classify_enemy_stage(enemy_def: dict) -> str:
    tags = set(enemy_def.get("tags", []))
    if "boss" in tags:
        if "stage_2" in tags:
            return "stage_2_boss"
        if "stage_3" in tags or "final_boss" in tags:
            return "stage_3_boss"
        return "stage_1_boss"
    if "stage_1" in tags:
        return "stage_1"
    if "stage_2" in tags:
        return "stage_2"
    if "stage_3" in tags:
        return "stage_3"
    return "untiered_live_minor_pool"


def _stage_tag(stage_index: int) -> str:
    return f"stage_{max(1, stage_index)}"


def _definition_has_tag(definition: dict, tag: str) -> bool:
    return tag in set(definition.get("tags", []))


def current_live_minor_enemy_ids(enemies: dict[str, dict], stage_index: int) -> list[str]:
    stage_specific_ids: list[str] = []
    fallback_ids: list[str] = []
    required_stage_tag = _stage_tag(stage_index)
    for enemy_id, enemy_def in sort_by_authoring_order(enemies):
        if enemy_def.get("encounter_tier", "minor") == "elite":
            continue
        if "boss" in set(enemy_def.get("tags", [])):
            continue
        if _definition_has_tag(enemy_def, required_stage_tag):
            stage_specific_ids.append(enemy_id)
        else:
            fallback_ids.append(enemy_id)
    return stage_specific_ids or fallback_ids


def current_live_boss_enemy_id(enemies: dict[str, dict], stage_index: int) -> str:
    required_stage_tag = _stage_tag(stage_index)
    fallback_enemy_id = ""
    for enemy_id, enemy_def in sort_by_authoring_order(enemies):
        if "boss" not in set(enemy_def.get("tags", [])):
            continue
        if not fallback_enemy_id:
            fallback_enemy_id = enemy_id
        if _definition_has_tag(enemy_def, required_stage_tag):
            return enemy_id
    return fallback_enemy_id


def current_live_merchant_stock_id(stage_index: int) -> str:
    return LIVE_STAGE_MERCHANT_STOCK_IDS.get(max(1, stage_index), LIVE_STAGE_MERCHANT_STOCK_IDS[1])


def current_live_event_ids(events: dict[str, dict]) -> list[str]:
    return sorted(events.keys())[:3]


def reward_window(reward_def: dict, source_context: str, stage_index: int, current_node_id: int) -> list[dict]:
    rules = reward_def.get("rules", {})
    offer_pool = copy.deepcopy(rules.get("offer_pool", []))
    if not offer_pool:
        return copy.deepcopy(rules.get("offers", []))
    present_count = min(int(rules.get("present_count", 0)) or len(offer_pool), len(offer_pool))
    source_offset = 4 if source_context == "combat_victory" else 3 if source_context == "reward_node" else 0
    start_index = (max(0, current_node_id) + ((max(1, stage_index) - 1) * 2) + source_offset) % len(offer_pool)
    return [copy.deepcopy(offer_pool[(start_index + offset) % len(offer_pool)]) for offset in range(present_count)]


def stage_template_assignments(template_def: dict, stage_index: int) -> list[dict[int, str]]:
    nodes = template_def.get("rules", {}).get("nodes", [])
    assignments: dict[int, str] = {}
    opening_support_id = -1
    late_primary_ids: list[int] = []
    late_event_id = -1
    adjacency: dict[int, list[int]] = {}
    for node in nodes:
        node_id = int(node["node_id"])
        adjacency[node_id] = [int(v) for v in node.get("adjacent_node_ids", [])]
        fixed_family = str(node.get("node_family", ""))
        if fixed_family:
            assignments[node_id] = fixed_family
            continue
        slot_type = str(node.get("slot_type", ""))
        if slot_type == "opening_support":
            opening_support_id = node_id
        elif slot_type == "late_primary":
            late_primary_ids.append(node_id)
        elif slot_type == "late_event":
            late_event_id = node_id

    layout = LIVE_STAGE_SUPPORT_LAYOUTS[stage_index]
    assignments[opening_support_id] = layout["opening_support_family"]
    assignments[late_event_id] = "event"
    candidates = [node_id for node_id in adjacency[opening_support_id] if node_id in late_primary_ids]
    if not candidates:
        candidates = late_primary_ids[:]

    realized_assignments: list[dict[int, str]] = []
    for support_id in sorted(candidates):
        remaining = [node_id for node_id in late_primary_ids if node_id != support_id]
        for key_id in sorted(remaining):
            mapping = dict(assignments)
            mapping[support_id] = layout["late_support_family"]
            for node_id in remaining:
                mapping[node_id] = "key" if node_id == key_id else "combat"
            realized_assignments.append(mapping)
    return realized_assignments


def shortest_exposure_route(template_def: dict, family_map: dict[int, str]) -> dict:
    adjacency = {
        int(node["node_id"]): [int(v) for v in node.get("adjacent_node_ids", [])]
        for node in template_def.get("rules", {}).get("nodes", [])
    }
    combat_nodes = sorted([node_id for node_id, family in family_map.items() if family in {"combat", "boss"}])
    combat_index = {node_id: index for index, node_id in enumerate(combat_nodes)}

    heap: list[tuple[int, int, int, bool, bool, bool, int, list[int]]] = []
    heapq.heappush(heap, (0, 0, 0, False, False, False, 0, [0]))
    best: dict[tuple[int, bool, bool, bool, int], tuple[int, int]] = {}

    while heap:
        moves, combat_count, node_id, got_reward, got_support, got_key, combat_mask, path = heapq.heappop(heap)
        family = family_map[node_id]
        if family == "reward":
            got_reward = True
        elif family in {"rest", "merchant", "blacksmith"}:
            got_support = True
        elif family == "key":
            got_key = True
        elif family == "boss" and got_key and got_reward and got_support:
            return {"moves": moves, "combat_count": combat_count, "path": path}

        state_key = (node_id, got_reward, got_support, got_key, combat_mask)
        prior = best.get(state_key)
        if prior is not None and prior <= (moves, combat_count):
            continue
        best[state_key] = (moves, combat_count)

        for adjacent in adjacency[node_id]:
            adjacent_family = family_map[adjacent]
            if adjacent_family == "boss" and not got_key:
                continue
            next_mask = combat_mask
            next_combat_count = combat_count
            if adjacent in combat_index and not (combat_mask & (1 << combat_index[adjacent])):
                next_mask |= 1 << combat_index[adjacent]
                next_combat_count += 1
            heapq.heappush(
                heap,
                (
                    moves + 1,
                    next_combat_count,
                    adjacent,
                    got_reward,
                    got_support,
                    got_key,
                    next_mask,
                    path + [adjacent],
                ),
            )
    return {"moves": -1, "combat_count": -1, "path": []}


def summarize_stage_assignments(template_def: dict, stage_index: int, enemies: dict[str, dict], reward_defs: dict[str, dict]) -> dict:
    minor_ids = current_live_minor_enemy_ids(enemies, stage_index)
    live_boss_id = current_live_boss_enemy_id(enemies, stage_index)
    reward_def = reward_defs["reward_node"]
    route_summaries = []

    for family_map in stage_template_assignments(template_def, stage_index):
        route = shortest_exposure_route(template_def, family_map)
        if route["moves"] < 0:
            continue
        reward_node_id = next(node_id for node_id, family in family_map.items() if family == "reward")
        reward_offers = reward_window(reward_def, "reward_node", stage_index, reward_node_id)
        combat_enemy_ids = []
        for node_id in route["path"][1:]:
            family = family_map[node_id]
            if family == "combat":
                combat_enemy_ids.append(minor_ids[(node_id - 1) % len(minor_ids)])
            elif family == "boss" and live_boss_id:
                combat_enemy_ids.append(live_boss_id)
        route_summaries.append(
            {
                "moves": route["moves"],
                "move_hunger": route["moves"] * MOVE_HUNGER_COST,
                "combat_count": route["combat_count"],
                "path": route["path"],
                "reward_offers": [offer.get("effect_type", "") for offer in reward_offers],
                "combat_enemy_ids": combat_enemy_ids,
                "support_families": sorted({family for family in family_map.values() if family in {"rest", "merchant", "blacksmith"}}),
            }
        )

    return {
        "routes": route_summaries,
        "moves_range": (
            min(route["moves"] for route in route_summaries),
            max(route["moves"] for route in route_summaries),
        ),
        "move_hunger_range": (
            min(route["move_hunger"] for route in route_summaries),
            max(route["move_hunger"] for route in route_summaries),
        ),
    }


def build_report() -> str:
    enemies = load_family("Enemies")
    weapons = load_family("Weapons")
    consumables = load_family("Consumables")
    passive_items = load_family("PassiveItems")
    rewards = load_family("Rewards")
    merchant_stocks = load_family("MerchantStocks")
    event_templates = load_family("EventTemplates")
    statuses = load_family("Statuses")
    map_templates = load_family("MapTemplates")
    starter_loadout = _load_definition(CONTENT_ROOT / "RunLoadouts" / "starter_loadout.json")

    starter_weapon_id = str(starter_loadout.get("rules", {}).get("weapon_definition_id", "iron_sword"))
    starter_weapon = weapons[starter_weapon_id]
    starter_consumable_slots = copy.deepcopy(starter_loadout.get("rules", {}).get("consumable_slots", []))

    enemy_metrics: dict[str, dict[str, CombatOutcome]] = {}
    for enemy_id, enemy_def in enemies.items():
        enemy_metrics[enemy_id] = {
            "attack_only": simulate_combat(enemy_id, enemy_def, starter_weapon, [], {}, consumables, statuses, "attack_only"),
            "safe": simulate_combat(enemy_id, enemy_def, starter_weapon, starter_consumable_slots, {}, consumables, statuses, "safe"),
        }

    grouped_enemy_ids: dict[str, list[str]] = {}
    for enemy_id, enemy_def in enemies.items():
        grouped_enemy_ids.setdefault(classify_enemy_stage(enemy_def), []).append(enemy_id)

    stage_rows = []
    for group_name in ["stage_1", "stage_2", "stage_3", "untiered_live_minor_pool"]:
        ids = grouped_enemy_ids.get(group_name, [])
        if not ids:
            continue
        stage_rows.append({
            "group": group_name,
            "enemy_count": len(ids),
            "avg_attack_only_turns": mean(enemy_metrics[enemy_id]["attack_only"].turns_taken for enemy_id in ids),
            "avg_safe_turns": mean(enemy_metrics[enemy_id]["safe"].turns_taken for enemy_id in ids),
            "avg_safe_hp_loss": mean(enemy_metrics[enemy_id]["safe"].hp_lost for enemy_id in ids),
            "avg_safe_durability": mean(enemy_metrics[enemy_id]["safe"].durability_spent for enemy_id in ids),
        })

    weapon_rows = []
    for weapon_id, weapon_def in sort_by_authoring_order(weapons):
        row = {
            "weapon_id": weapon_id,
            "display_name": weapon_def.get("display", {}).get("name", weapon_id),
            "base_damage": int(weapon_def.get("rules", {}).get("stats", {}).get("base_damage", 0)),
            "durability": int(weapon_def.get("rules", {}).get("stats", {}).get("max_durability", 0)),
        }
        for label, ids in [("stage1", grouped_enemy_ids.get("stage_1", [])), ("stage2", grouped_enemy_ids.get("stage_2", [])), ("stage3", grouped_enemy_ids.get("stage_3", []))]:
            if ids:
                row[f"{label}_avg_attack_turns"] = mean(
                    simulate_combat(enemy_id, enemies[enemy_id], weapon_def, [], {}, consumables, statuses, "attack_only").turns_taken
                    for enemy_id in ids
                )
        weapon_rows.append(row)

    passive_rows = []
    sample_stage1_enemy_id = grouped_enemy_ids.get("stage_1", current_live_minor_enemy_ids(enemies, 1))[0]
    for passive_id, passive_def in sort_by_authoring_order(passive_items):
        modifiers = extract_passive_modifiers(passive_def)
        passive_rows.append({
            "display_name": passive_def.get("display", {}).get("name", passive_id),
            "modifiers": modifiers,
            "solo_vs_stage1_hp_loss": simulate_combat(
                sample_stage1_enemy_id,
                enemies[sample_stage1_enemy_id],
                starter_weapon,
                starter_consumable_slots,
                {passive_id: passive_def},
                consumables,
                statuses,
                "safe",
            ).hp_lost,
        })

    consumable_rows = []
    for consumable_id, consumable_def in sort_by_authoring_order(consumables):
        profile = extract_consumable_profile(consumable_def)
        consumable_rows.append({
            "display_name": consumable_def.get("display", {}).get("name", consumable_id),
            "heal_amount": profile["heal_amount"],
            "hunger_reduction": max(0, -profile["hunger_delta"]),
        })

    event_stage_ids = current_live_event_ids(event_templates)
    live_event_rows = []
    for stage_index, event_id in enumerate(event_stage_ids, start=1):
        event_def = event_templates[event_id]
        live_event_rows.append({
            "stage": stage_index,
            "event_id": event_id,
            "name": event_def.get("display", {}).get("name", event_id),
            "effects": [f"{choice.get('effect_type')}:{choice.get('amount', 'repair')}" for choice in event_def.get("rules", {}).get("choices", [])],
        })

    map_rows = []
    for stage_index, template_id in LIVE_STAGE_TEMPLATES.items():
        summary = summarize_stage_assignments(map_templates[template_id], stage_index, enemies, rewards)
        map_rows.append({
            "stage": stage_index,
            "template_id": template_id,
            "moves_range": summary["moves_range"],
            "move_hunger_range": summary["move_hunger_range"],
            "route_samples": summary["routes"][:2],
        })

    live_stage_minor_ids = {stage_index: current_live_minor_enemy_ids(enemies, stage_index) for stage_index in LIVE_STAGE_TEMPLATES.keys()}
    live_stage_boss_ids = {stage_index: current_live_boss_enemy_id(enemies, stage_index) for stage_index in LIVE_STAGE_TEMPLATES.keys()}

    lines: list[str] = []
    lines.append("# Balance Analysis")
    lines.append("")
    lines.append("Generated by `Tools/analyze_balance.py`.")
    lines.append("")
    lines.append("## Scope")
    lines.append("")
    lines.append("This report is analysis-only. No values were changed in this pass.")
    lines.append("")
    lines.append("## Confirmed Runtime Facts")
    lines.append("")
    lines.append("- Baseline player truth comes from current runtime authority:")
    lines.append(f"  - HP: `{DEFAULT_PLAYER_HP}`")
    lines.append(f"  - Hunger starts at `{DEFAULT_PLAYER_HUNGER}` and increases; it does not start at `100`.")
    lines.append(f"  - Starter weapon: `{starter_weapon_id}`")
    lines.append(f"  - Starter consumable loadout: `{', '.join(slot['definition_id'] for slot in starter_consumable_slots) or 'none'}`")
    lines.append("- Current live merchant stocks are stage-aware:")
    for stage_index in sorted(LIVE_STAGE_MERCHANT_STOCK_IDS.keys()):
        lines.append(f"  - stage `{stage_index}` -> `{current_live_merchant_stock_id(stage_index)}`")
    lines.append("- Current live boss selection is stage-aware:")
    for stage_index in sorted(live_stage_boss_ids.keys()):
        lines.append(f"  - stage `{stage_index}` -> `{live_stage_boss_ids[stage_index]}`")
    lines.append(f"- Current live stage events are alphabetical stable-id rotation: `{', '.join(event_stage_ids)}`.")
    lines.append("- Current live minor enemy pools are stage-aware deterministic rotations:")
    for stage_index in sorted(live_stage_minor_ids.keys()):
        lines.append(f"  - stage `{stage_index}` -> `{', '.join(live_stage_minor_ids[stage_index])}`")
    lines.append("")
    lines.append("## Analysis Assumptions")
    lines.append("")
    lines.append("- Combat simulation uses current resolver formulas plus a narrow `baseline_safe` policy:")
    lines.append("  - `Attack` by default")
    lines.append("  - `Brace` on heavier visible hits or obvious status pressure")
    lines.append("  - `Use Item` only when the starter consumable would immediately matter")
    lines.append("- This is a comparative heuristic, not a claim about perfect play.")
    lines.append("")
    lines.append("## Stage Cohort Combat Summary")
    lines.append("")
    lines.append("| Cohort | Enemy Count | Avg Attack-Only Turns To Win | Avg Safe Turns | Avg Safe HP Loss | Avg Safe Durability |")
    lines.append("|---|---:|---:|---:|---:|---:|")
    for row in stage_rows:
        lines.append("| {group} | {enemy_count} | {avg_attack_only_turns:.2f} | {avg_safe_turns:.2f} | {avg_safe_hp_loss:.2f} | {avg_safe_durability:.2f} |".format(**row))
    lines.append("")
    lines.append("## Enemy-by-Enemy Baseline")
    lines.append("")
    lines.append("| Enemy | Cohort | Attack-Only Outcome | Attack-Only Turns | Safe Outcome | Safe Turns | Safe HP Loss | Safe Hunger Gain | Safe Durability | Safe Consumables |")
    lines.append("|---|---|---|---:|---|---:|---:|---:|---:|---:|")
    for enemy_id, enemy_def in sort_by_authoring_order(enemies):
        attack_only = enemy_metrics[enemy_id]["attack_only"]
        safe = enemy_metrics[enemy_id]["safe"]
        lines.append(f"| {safe.enemy_name} | {classify_enemy_stage(enemy_def)} | {attack_only.outcome} | {attack_only.turns_taken} | {safe.outcome} | {safe.turns_taken} | {safe.hp_lost} | {safe.hunger_gained} | {safe.durability_spent} | {safe.consumables_used} |")
    lines.append("")
    lines.append("## Weapon Pressure Snapshot")
    lines.append("")
    lines.append("| Weapon | Damage | Durability | Avg Turns vs Stage 1 | Avg Turns vs Stage 2 | Avg Turns vs Stage 3 |")
    lines.append("|---|---:|---:|---:|---:|---:|")
    for row in weapon_rows:
        lines.append(f"| {row['display_name']} | {row['base_damage']} | {row['durability']} | {row.get('stage1_avg_attack_turns', float('nan')):.2f} | {row.get('stage2_avg_attack_turns', float('nan')):.2f} | {row.get('stage3_avg_attack_turns', float('nan')):.2f} |")
    lines.append("")
    lines.append("## Consumable Efficiency Snapshot")
    lines.append("")
    lines.append("| Consumable | Heal | Hunger Reduction |")
    lines.append("|---|---:|---:|")
    for row in consumable_rows:
        lines.append(f"| {row['display_name']} | {row['heal_amount']} | {row['hunger_reduction']} |")
    lines.append("")
    lines.append("## Passive Vector Snapshot")
    lines.append("")
    lines.append("| Passive | Modifiers | Solo Safe HP Loss vs First Stage-1 Enemy |")
    lines.append("|---|---|---:|")
    for row in passive_rows:
        modifier_text = ", ".join(f"{key} {value:+d}" for key, value in sorted(row["modifiers"].items()))
        lines.append(f"| {row['display_name']} | {modifier_text or 'none'} | {row['solo_vs_stage1_hp_loss']} |")
    lines.append("")
    lines.append("## Live Event and Support Economy")
    lines.append("")
    lines.append("| Stage | Live Event | Choice Effects |")
    lines.append("|---|---|---|")
    for row in live_event_rows:
        lines.append(f"| {row['stage']} | {row['name']} (`{row['event_id']}`) | {', '.join(row['effects'])} |")
    lines.append("")
    lines.append("- Live merchant stocks:")
    for stage_index in sorted(LIVE_STAGE_MERCHANT_STOCK_IDS.keys()):
        stock_id = current_live_merchant_stock_id(stage_index)
        lines.append(f"  - stage `{stage_index}` -> `{stock_id}`")
        for stock_entry in merchant_stocks[stock_id]["rules"]["stock"]:
            lines.append(f"    - `{stock_entry['definition_id']}` via `{stock_entry['effect_type']}` for `{stock_entry['cost_gold']}` gold")
    lines.append("- Live rest value is fixed: `+2 HP`, `-20 Hunger`.")
    lines.append("- Live blacksmith value is fixed: `repair active weapon to full` for `4` gold.")
    lines.append("")
    lines.append("## Live Map Pressure Snapshot")
    lines.append("")
    for row in map_rows:
        lines.append(f"### Stage {row['stage']} - `{row['template_id']}`")
        lines.append(f"- Minimal exposed route move range to see `reward + support + key + boss`: `{row['moves_range'][0]}-{row['moves_range'][1]}` moves")
        lines.append(f"- Move-only hunger range on that route: `{row['move_hunger_range'][0]}-{row['move_hunger_range'][1]}`")
        for sample in row["route_samples"]:
            lines.append(f"- Sample path `{sample['path']}` -> combat ids `{', '.join(sample['combat_enemy_ids'])}` -> reward window `{', '.join(sample['reward_offers'])}` -> support families `{', '.join(sample['support_families'])}`")
        lines.append("")

    lines.append("## Key Findings")
    lines.append("")
    lines.append("### Confirmed")
    lines.append("")
    lines.append("- Authored stage-tagged enemies do produce a readable authored power climb: stage-1 cohorts are shorter and lighter than stage-2 and stage-3 cohorts.")
    lines.append("- Current live runtime now does use stage tagging for enemy selection when a stage-local pool exists; each stage draws from its authored tagged minor pool.")
    lines.append("- Current live runtime now routes the authored stage-local boss definitions on stages `1-3`.")
    lines.append("- Current live runtime now routes authored stage-specific merchant stocks on stages `1-3`.")
    lines.append("- Stage-1 live reward-node first window is economy/progression (`grant_xp`, `grant_gold`) rather than sustain (`heal`, `repair_weapon`).")
    lines.append("- Stage-2 live event is currently `ghost_lantern_bargain`, which offers `grant_xp 4` or `damage_player 6`; it adds pressure, not recovery.")
    lines.append("")
    lines.append("### Inference")
    lines.append("")
    lines.append("- Hunger pressure is meaningful but not yet the primary killer on shortest boss routes. Movement alone usually lands in the `15-24` hunger-per-stage band before optional detours; attrition becomes much sharper when route indecision and longer combats stack on top.")
    lines.append("- Healing looks sufficient for short successful routes **if** the player takes rest nodes and at least some heal rewards. It looks thin for exploratory or mistake-heavy routes because live stage-2 support is merchant-first, not rest-first.")
    lines.append("- The biggest remaining curve problem is no longer missing staged routing; it is the actual numeric pressure inside those now-live stage-tagged pools and the sustain floor around them.")
    lines.append("")
    lines.append("## Recommended Value Adjustments (Not Applied)")
    lines.append("")
    lines.append("1. If `bone_raider` stays in the live early minor pool, reduce either `base_damage 5 -> 4` or `base_hp 24 -> 22`. It currently asks for starter-weapon four-hit cleanup while hitting above the stage-1 authored cohort.")
    lines.append("2. If `skeletal_hound` stays in the live early minor pool, reduce `base_damage 4 -> 3`. Its low HP is fair, but it spikes early HP loss harder than the authored stage-1 tutorial set.")
    lines.append("3. Reduce `ghost_lantern_bargain` self-damage from `6 -> 4` if it remains the live stage-2 event. Right now it pressures HP without offering sustain or economy on the safer branch.")
    lines.append("4. Increase stage-1 reward-node sustain floor by rotating one early `heal` or `repair_weapon` result into the first live window, or lowering nearby combat pressure if that reward window stays economy-only.")
    lines.append("5. Re-check `stage_3` boss `briar_sovereign` and `stage_2` boss `chain_herald` now that both are live; any future numeric tuning should be based on real stage-playtest data instead of the old routing gap.")
    lines.append("")
    lines.append("## Structural Notes That Are Not Value Changes")
    lines.append("")
    lines.append("- Stage-aware enemy and merchant routing are now live, so future balance passes should tune values against real staged behavior instead of reopening routing first.")
    lines.append("- This report remains analysis-only; it does not apply value changes.")
    lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Analyze balance curves from current ContentDefinitions.")
    parser.add_argument("--write-doc", action="store_true", help="Write the markdown report to Docs/BALANCE_ANALYSIS.md.")
    args = parser.parse_args()

    report = build_report()
    if args.write_doc:
        DOC_PATH.write_text(report, encoding="utf-8")
        print(f"Wrote {DOC_PATH}")
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
