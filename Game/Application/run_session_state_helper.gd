# Layer: Application
extends RefCounted
class_name RunSessionStateHelper

const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")
const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")
const LevelUpStateScript = preload("res://Game/RuntimeState/level_up_state.gd")
const SupportInteractionStateScript = preload("res://Game/RuntimeState/support_interaction_state.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")
const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")


static func build_combat_setup_data(
	active_run_state: RunState,
	enemy_selection_policy: Variant,
	boss_node_family: String
) -> Dictionary:
	var loader: ContentLoader = ContentLoaderScript.new()
	var weapon_definition_id: String = String(active_run_state.inventory_state.weapon_instance.get("definition_id", ""))
	var weapon_definition: Dictionary = {}
	if not weapon_definition_id.is_empty():
		weapon_definition = loader.load_definition("Weapons", weapon_definition_id)
	if not weapon_definition_id.is_empty() and weapon_definition.is_empty():
		return {
			"ok": false,
			"error": "missing_weapon_definition",
			"definition_id": weapon_definition_id,
		}

	var map_runtime_state: RefCounted = active_run_state.map_runtime_state
	var encounter_node_family: String = String(map_runtime_state.get_current_node_family())
	var enemy_definition_id: String = ""
	if map_runtime_state != null:
		enemy_definition_id = String(map_runtime_state.get_side_quest_target_enemy_definition_id(map_runtime_state.current_node_id))
	if enemy_definition_id.is_empty():
		enemy_definition_id = enemy_selection_policy.resolve_combat_enemy_definition_id(
			loader,
			active_run_state,
			encounter_node_family
		)
	if enemy_definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_enemy_definition_for_encounter",
			"encounter_node_family": encounter_node_family,
		}

	var enemy_definition: Dictionary = loader.load_definition("Enemies", enemy_definition_id)
	if enemy_definition.is_empty():
		return {
			"ok": false,
			"error": "missing_enemy_definition",
			"definition_id": enemy_definition_id,
			"encounter_node_family": encounter_node_family,
		}

	return {
		"ok": true,
		"weapon_definition_id": weapon_definition_id,
		"weapon_definition": weapon_definition,
		"enemy_definition_id": enemy_definition_id,
		"enemy_definition": enemy_definition,
		"encounter_node_family": encounter_node_family,
		"is_boss_combat": encounter_node_family == boss_node_family,
		"combat_reward_context": build_combat_reward_generation_context(enemy_definition_id, enemy_definition),
	}


static func use_inventory_consumable(
	active_run_state: RunState,
	inventory_actions: InventoryActions,
	slot_id: int
) -> Dictionary:
	var inventory_state: InventoryState = active_run_state.inventory_state
	var slot_index: int = inventory_state.find_slot_index_by_id(slot_id)
	if slot_index < 0:
		return {
			"ok": false,
			"slot_id": slot_id,
			"error": "missing_inventory_slot",
		}

	var slot: Dictionary = inventory_state.inventory_slots[slot_index]
	if String(slot.get("inventory_family", "")) != InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
		return {
			"ok": false,
			"slot_id": slot_id,
			"error": "invalid_inventory_family",
		}

	var definition_id: String = String(slot.get("definition_id", ""))
	var current_stack: int = int(slot.get("current_stack", 0))
	if definition_id.is_empty() or current_stack <= 0:
		return {
			"ok": false,
			"slot_id": slot_id,
			"error": "invalid_consumable_slot",
		}

	var loader: ContentLoader = ContentLoaderScript.new()
	var consumable_definition: Dictionary = loader.load_definition("Consumables", definition_id)
	if consumable_definition.is_empty():
		return {
			"ok": false,
			"slot_id": slot_id,
			"error": "missing_consumable_definition",
			"definition_id": definition_id,
		}

	var use_profile: Dictionary = InventoryActionsScript.extract_consumable_use_profile(
		consumable_definition.get("rules", {}).get("use_effect", {})
	)
	var heal_amount: int = int(use_profile.get("heal_amount", 0))
	var hunger_delta: int = int(use_profile.get("hunger_delta", 0))
	var repairs_weapon: bool = bool(use_profile.get("repairs_weapon", false))
	var previous_hp: int = active_run_state.player_hp
	var previous_hunger: int = active_run_state.hunger
	var previous_durability: int = int(active_run_state.inventory_state.weapon_instance.get("current_durability", 0))
	var healed_amount: int = 0
	var hunger_restored_amount: int = 0
	var repaired_durability: int = 0

	if heal_amount > 0:
		var next_hp: int = min(RunState.DEFAULT_PLAYER_HP, previous_hp + heal_amount)
		healed_amount = next_hp - previous_hp
		active_run_state.player_hp = next_hp
	if hunger_delta < 0:
		var next_hunger: int = int(clamp(previous_hunger - hunger_delta, 0, RunState.DEFAULT_HUNGER))
		hunger_restored_amount = next_hunger - previous_hunger
		active_run_state.hunger = next_hunger
	if repairs_weapon:
		var repair_result: Dictionary = inventory_actions.repair_active_weapon(active_run_state.inventory_state)
		if bool(repair_result.get("ok", false)):
			repaired_durability = int(repair_result.get("current_durability", previous_durability)) - previous_durability

	if healed_amount <= 0 and hunger_restored_amount <= 0 and repaired_durability <= 0:
		return {
			"ok": false,
			"slot_id": slot_id,
			"definition_id": definition_id,
			"error": "no_effect",
		}

	current_stack -= 1
	if current_stack <= 0:
		inventory_state.inventory_slots.remove_at(slot_index)
	else:
		slot["current_stack"] = current_stack
		inventory_state.inventory_slots[slot_index] = slot
	inventory_state.mark_inventory_dirty()

	var display_name: String = String(consumable_definition.get("display", {}).get("name", definition_id))
	return {
		"ok": true,
		"slot_id": slot_id,
		"definition_id": definition_id,
		"display_name": display_name,
		"healed_amount": healed_amount,
		"hunger_restored_amount": hunger_restored_amount,
		"repaired_durability": repaired_durability,
		"remaining_stack": current_stack,
		"player_hp": active_run_state.player_hp,
		"hunger": active_run_state.hunger,
	}


static func build_event_state(
	run_state: RunState,
	node_id: int,
	source_context: String = EventStateScript.SOURCE_CONTEXT_NODE_EVENT,
	mark_source_node_resolved: bool = false
) -> EventStateScript:
	var next_event_state: EventStateScript = EventStateScript.new()
	var trigger_context: Dictionary = {}
	if source_context == EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER:
		trigger_context = build_roadside_trigger_context(run_state)
	next_event_state.setup_for_node(
		node_id,
		run_state.stage_index if run_state != null else 1,
		source_context,
		run_state.run_seed if run_state != null else EventStateScript.DEFAULT_SELECTION_SEED,
		trigger_context
	)
	if next_event_state.choices.is_empty():
		return null
	if mark_source_node_resolved and run_state != null and run_state.map_runtime_state != null:
		run_state.map_runtime_state.mark_node_resolved(node_id)
	return next_event_state


static func has_eligible_roadside_template(active_run_state: RunState, target_node_id: int) -> bool:
	if active_run_state == null:
		return false
	var preview_event_state: EventStateScript = EventStateScript.new()
	preview_event_state.setup_for_node(
		target_node_id,
		active_run_state.stage_index,
		EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER,
		active_run_state.run_seed,
		build_roadside_trigger_context(active_run_state)
	)
	return not preview_event_state.choices.is_empty()


static func build_roadside_trigger_context(active_run_state: RunState) -> Dictionary:
	if active_run_state == null:
		return {}
	var max_hp: int = max(1, RunState.DEFAULT_PLAYER_HP)
	var hp_percent: float = (float(active_run_state.player_hp) / float(max_hp)) * 100.0
	return {
		EventStateScript.TRIGGER_STAT_HUNGER: active_run_state.hunger,
		EventStateScript.TRIGGER_STAT_HP_PERCENT: hp_percent,
		EventStateScript.TRIGGER_STAT_GOLD: active_run_state.gold,
	}


static func build_reward_state(
	run_state: RunState,
	source_context: String,
	last_combat_reward_context: Dictionary,
	mark_current_node_resolved: bool = false
) -> RewardState:
	var next_reward_state: RewardState = RewardStateScript.new()
	next_reward_state.setup_for_source(
		source_context,
		build_reward_generation_context(run_state, source_context, last_combat_reward_context)
	)
	if mark_current_node_resolved and run_state != null and run_state.map_runtime_state != null:
		run_state.map_runtime_state.mark_node_resolved(run_state.map_runtime_state.current_node_id)
	return next_reward_state


static func build_level_up_state(
	run_state: RunState,
	level_up_offer_window_policy: Variant,
	source_context: String
) -> LevelUpState:
	var next_level_up_state: LevelUpState = LevelUpStateScript.new()
	var loader: ContentLoader = ContentLoaderScript.new()
	next_level_up_state.setup_for_level(
		source_context,
		run_state.current_level,
		level_up_offer_window_policy.build_offer_window(
			loader,
			run_state.current_level,
			run_state.character_perk_state.get_owned_perk_ids()
		)
	)
	return next_level_up_state


static func build_support_interaction_state(
	run_state: RunState,
	support_type: String,
	node_id: int,
	hamlet_node_family: String,
	legacy_side_mission_family: String
) -> SupportInteractionState:
	var next_support_interaction_state: SupportInteractionState = SupportInteractionStateScript.new()
	var persisted_node_state: Dictionary = {}
	var stage_index: int = 1
	var normalized_support_type: String = normalize_support_route_family(
		support_type,
		hamlet_node_family,
		legacy_side_mission_family
	)
	if run_state != null:
		if normalized_support_type == hamlet_node_family:
			persisted_node_state = run_state.map_runtime_state.get_side_quest_node_runtime_state(node_id)
		else:
			persisted_node_state = run_state.map_runtime_state.get_support_node_runtime_state(node_id)
		stage_index = max(1, int(run_state.stage_index))
	next_support_interaction_state.setup_for_type(
		normalized_support_type,
		node_id,
		persisted_node_state,
		stage_index,
		run_state.inventory_state if run_state != null else null,
		run_state.map_runtime_state if run_state != null else null,
		run_state.run_seed if run_state != null else SupportInteractionStateScript.DEFAULT_SELECTION_SEED
	)
	if run_state != null and run_state.map_runtime_state != null:
		run_state.map_runtime_state.mark_node_resolved(node_id)
	return next_support_interaction_state


static func persist_active_support_node_state(
	run_state: RunState,
	support_interaction_state: SupportInteractionState,
	hamlet_node_family: String
) -> void:
	if run_state == null or support_interaction_state == null:
		return
	var support_node_id: int = int(support_interaction_state.source_node_id)
	if support_node_id < 0:
		return
	if String(support_interaction_state.support_type) == hamlet_node_family:
		run_state.map_runtime_state.save_side_quest_node_runtime_state(
			support_node_id,
			support_interaction_state.build_persisted_node_state()
		)
		return
	run_state.map_runtime_state.save_support_node_runtime_state(
		support_node_id,
		support_interaction_state.build_persisted_node_state()
	)


static func build_reward_generation_context(
	run_state: RunState,
	source_context: String,
	last_combat_reward_context: Dictionary
) -> Dictionary:
	if run_state == null:
		return {}
	var current_node_id: int = run_state.map_runtime_state.current_node_id
	var rng_context: Dictionary = run_state.consume_named_rng_context(
		"reward_rng",
		"%s|stage:%d|node:%d|level:%d" % [source_context, run_state.stage_index, current_node_id, run_state.current_level]
	)
	return {
		"current_node_id": current_node_id,
		"stage_index": run_state.stage_index,
		"current_level": run_state.current_level,
		"reward_rng_seed": int(rng_context.get("stream_seed", 0)),
		"reward_rng_draw_index": int(rng_context.get("draw_index", 0)),
	}.merged(last_combat_reward_context if source_context == RewardStateScript.SOURCE_COMBAT_VICTORY else {}, true)


static func build_combat_reward_generation_context(enemy_definition_id: String, enemy_definition: Dictionary) -> Dictionary:
	return {
		"enemy_definition_id": enemy_definition_id,
		"enemy_tags": extract_enemy_tags(enemy_definition),
	}


static func extract_enemy_tags(enemy_definition: Dictionary) -> PackedStringArray:
	var tags: PackedStringArray = PackedStringArray()
	var tags_variant: Variant = enemy_definition.get("tags", [])
	if typeof(tags_variant) != TYPE_ARRAY:
		return tags
	for tag_value in tags_variant:
		var tag_name: String = String(tag_value).strip_edges()
		if tag_name.is_empty() or tags.has(tag_name):
			continue
		tags.append(tag_name)
	return tags


static func normalize_support_route_family(
	node_family: String,
	hamlet_node_family: String,
	legacy_side_mission_family: String
) -> String:
	return hamlet_node_family if node_family == legacy_side_mission_family else node_family


static func complete_noncombat_side_quest_target_on_arrival(
	active_run_state: RunState,
	map_runtime_state: RefCounted,
	target_node_id: int,
	target_node_type: String,
	direct_combat_node_families: PackedStringArray,
	inventory_actions: InventoryActions
) -> void:
	if active_run_state == null or map_runtime_state == null:
		return
	if target_node_type in direct_combat_node_families:
		return
	var active_side_quest_state: Dictionary = map_runtime_state.get_active_side_quest_by_target_node_id(target_node_id)
	if active_side_quest_state.is_empty():
		return

	var mission_type: String = String(
		active_side_quest_state.get("mission_type", SupportInteractionStateScript.MISSION_TYPE_HUNT_MARKED_ENEMY)
	)
	if mission_type == SupportInteractionStateScript.MISSION_TYPE_HUNT_MARKED_ENEMY:
		return

	var quest_item_definition_id: String = String(active_side_quest_state.get("quest_item_definition_id", "")).strip_edges()
	if mission_type == SupportInteractionStateScript.MISSION_TYPE_DELIVER_SUPPLIES:
		if quest_item_definition_id.is_empty():
			return
		var remove_result: Dictionary = inventory_actions.remove_quest_item(
			active_run_state.inventory_state,
			quest_item_definition_id
		)
		if not bool(remove_result.get("ok", false)):
			return

	var completed_side_quest_state: Dictionary = map_runtime_state.mark_side_quest_target_completed(target_node_id)
	apply_side_quest_completion_hooks(active_run_state, completed_side_quest_state, inventory_actions)


static func apply_side_quest_completion_hooks(
	active_run_state: RunState,
	completed_side_quest_state: Dictionary,
	inventory_actions: InventoryActions
) -> void:
	if active_run_state == null or completed_side_quest_state.is_empty():
		return
	var mission_type: String = String(completed_side_quest_state.get("mission_type", ""))
	var quest_item_definition_id: String = String(completed_side_quest_state.get("quest_item_definition_id", "")).strip_edges()
	if mission_type != SupportInteractionStateScript.MISSION_TYPE_BRING_PROOF:
		return
	if quest_item_definition_id.is_empty():
		return
	if _inventory_contains_family_definition(
		active_run_state.inventory_state,
		InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM,
		quest_item_definition_id
	):
		return
	inventory_actions.add_quest_item(active_run_state.inventory_state, quest_item_definition_id)


static func _inventory_contains_family_definition(
	inventory_state: InventoryState,
	inventory_family: String,
	definition_id: String
) -> bool:
	if inventory_state == null or definition_id.is_empty():
		return false
	for slot in inventory_state.inventory_slots:
		if String(slot.get("inventory_family", "")) != inventory_family:
			continue
		if String(slot.get("definition_id", "")) == definition_id:
			return true
	return false
