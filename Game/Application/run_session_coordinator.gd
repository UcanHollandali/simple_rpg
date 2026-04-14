# Layer: Application
extends RefCounted
class_name RunSessionCoordinator

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")
const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")
const LevelUpStateScript = preload("res://Game/RuntimeState/level_up_state.gd")
const SupportInteractionStateScript = preload("res://Game/RuntimeState/support_interaction_state.gd")
const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")
const EventApplicationPolicyScript = preload("res://Game/Application/event_application_policy.gd")
const RewardApplicationPolicyScript = preload("res://Game/Application/reward_application_policy.gd")
const SupportActionApplicationPolicyScript = preload("res://Game/Application/support_action_application_policy.gd")
const EnemySelectionPolicyScript = preload("res://Game/Application/enemy_selection_policy.gd")
const LevelUpOfferWindowPolicyScript = preload("res://Game/Application/level_up_offer_window_policy.gd")
const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")

const COMBAT_VICTORY_XP: int = 5
const FINAL_STAGE_INDEX: int = 3
const MAP_MOVE_HUNGER_COST: int = 1
const ROADSIDE_ENCOUNTER_STREAM_NAME: String = "roadside_encounter_rng"
const ROADSIDE_ENCOUNTER_TRIGGER_CHANCE: float = 0.12
const ROADSIDE_ENCOUNTER_EXCLUDED_FAMILIES: PackedStringArray = [
	"start",
	"boss",
	"reward",
	"event",
	"key",
	"support",
	"rest",
	"merchant",
	"blacksmith",
	"side_mission",
]
const NODE_FAMILY_COMBAT: String = "combat"
const NODE_FAMILY_BOSS: String = "boss"
const NODE_FAMILY_SIDE_MISSION: String = "side_mission"
const DIRECT_SUPPORT_NODE_FAMILIES: PackedStringArray = [
	SupportInteractionStateScript.TYPE_REST,
	SupportInteractionStateScript.TYPE_MERCHANT,
	SupportInteractionStateScript.TYPE_BLACKSMITH,
	NODE_FAMILY_SIDE_MISSION,
]
const DIRECT_COMBAT_NODE_FAMILIES: PackedStringArray = [
	NODE_FAMILY_COMBAT,
	NODE_FAMILY_BOSS,
]

var game_flow_manager: GameFlowManager
var run_state: RunState
var inventory_actions: InventoryActions
# Keep deterministic policy tables out of the coordinator so this class stays focused on flow/state orchestration.
var event_application_policy: EventApplicationPolicy
var reward_application_policy: RewardApplicationPolicy
var support_action_application_policy: SupportActionApplicationPolicy
var enemy_selection_policy: EnemySelectionPolicy
var level_up_offer_window_policy: LevelUpOfferWindowPolicy
var event_state: EventStateScript
var reward_state: RewardState
var level_up_state: LevelUpState
var support_interaction_state: SupportInteractionState
var last_run_result: String = ""


func setup(flow_manager: GameFlowManager, active_run_state: RunState) -> void:
	game_flow_manager = flow_manager
	run_state = active_run_state
	if inventory_actions == null:
		inventory_actions = InventoryActionsScript.new()
	if event_application_policy == null:
		event_application_policy = EventApplicationPolicyScript.new()
	if reward_application_policy == null:
		reward_application_policy = RewardApplicationPolicyScript.new()
	if support_action_application_policy == null:
		support_action_application_policy = SupportActionApplicationPolicyScript.new()
	if enemy_selection_policy == null:
		enemy_selection_policy = EnemySelectionPolicyScript.new()
	if level_up_offer_window_policy == null:
		level_up_offer_window_policy = LevelUpOfferWindowPolicyScript.new()


func ensure_run_state_initialized() -> RunState:
	if run_state == null:
		return null
	if run_state.inventory_state.weapon_instance.is_empty():
		run_state.reset_for_new_run()
	return run_state


func reset_for_new_run() -> void:
	event_state = null
	reward_state = null
	level_up_state = null
	support_interaction_state = null
	last_run_result = ""


func get_event_state() -> EventStateScript:
	return event_state


func get_reward_state() -> RewardState:
	return reward_state


func get_level_up_state() -> LevelUpState:
	return level_up_state


func get_support_interaction_state() -> SupportInteractionState:
	return support_interaction_state


func get_last_run_result() -> String:
	return last_run_result


func get_app_state_save_data() -> Dictionary:
	return {
		"last_run_result": last_run_result,
	}


func build_combat_setup_data() -> Dictionary:
	var active_run_state: RunState = ensure_run_state_initialized()
	if active_run_state == null:
		return {"ok": false, "error": "missing_run_state"}

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
		enemy_definition_id = String(map_runtime_state.get_side_mission_target_enemy_definition_id(map_runtime_state.current_node_id))
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
		"is_boss_combat": encounter_node_family == NODE_FAMILY_BOSS,
	}


func toggle_inventory_equipment(slot_id: int) -> Dictionary:
	var active_run_state: RunState = ensure_run_state_initialized()
	if active_run_state == null:
		return {"ok": false, "slot_id": slot_id, "error": "missing_run_state"}
	return inventory_actions.toggle_equipment_slot(active_run_state.inventory_state, slot_id)


func move_inventory_slot(slot_id: int, target_index: int) -> Dictionary:
	var active_run_state: RunState = ensure_run_state_initialized()
	if active_run_state == null:
		return {"ok": false, "slot_id": slot_id, "target_index": target_index, "error": "missing_run_state"}
	return inventory_actions.move_slot_to_index(active_run_state.inventory_state, slot_id, target_index)


func use_inventory_consumable(slot_id: int) -> Dictionary:
	var active_run_state: RunState = ensure_run_state_initialized()
	if active_run_state == null:
		return {"ok": false, "slot_id": slot_id, "error": "missing_run_state"}

	var inventory_state: InventoryState = active_run_state.inventory_state
	var slot_index: int = inventory_state.find_slot_index_by_id(slot_id)
	if slot_index < 0:
		return {
			"ok": false,
			"slot_id": slot_id,
			"error": "missing_inventory_slot",
		}

	var slot: Dictionary = inventory_state.inventory_slots[slot_index]
	if String(slot.get("inventory_family", "")) != InventoryState.INVENTORY_FAMILY_CONSUMABLE:
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

	var use_profile: Dictionary = _extract_consumable_use_profile(consumable_definition.get("rules", {}).get("use_effect", {}))
	var heal_amount: int = int(use_profile.get("heal_amount", 0))
	var hunger_delta: int = int(use_profile.get("hunger_delta", 0))
	var previous_hp: int = active_run_state.player_hp
	var previous_hunger: int = active_run_state.hunger
	var healed_amount: int = 0
	var hunger_restored_amount: int = 0

	if heal_amount > 0:
		var next_hp: int = min(RunState.DEFAULT_PLAYER_HP, previous_hp + heal_amount)
		healed_amount = next_hp - previous_hp
		active_run_state.player_hp = next_hp
	if hunger_delta < 0:
		var next_hunger: int = int(clamp(previous_hunger - hunger_delta, 0, RunState.DEFAULT_HUNGER))
		hunger_restored_amount = next_hunger - previous_hunger
		active_run_state.hunger = next_hunger

	if healed_amount <= 0 and hunger_restored_amount <= 0:
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

	var display_name: String = String(consumable_definition.get("display", {}).get("name", definition_id))
	return {
		"ok": true,
		"slot_id": slot_id,
		"definition_id": definition_id,
		"display_name": display_name,
		"healed_amount": healed_amount,
		"hunger_restored_amount": hunger_restored_amount,
		"remaining_stack": current_stack,
		"player_hp": active_run_state.player_hp,
		"hunger": active_run_state.hunger,
	}


func choose_move_to_node(node_reference: Variant) -> Dictionary:
	var active_run_state: RunState = ensure_run_state_initialized()
	if active_run_state == null:
		return {"ok": false, "error": "missing_run_state"}

	var map_runtime_state: RefCounted = active_run_state.map_runtime_state
	var target_node_id: int = map_runtime_state.find_adjacent_node_id(node_reference)
	if target_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
		return {
			"ok": false,
			"error": "invalid_map_target",
			"node_reference": node_reference,
		}
	var from_node_id: int = map_runtime_state.current_node_id
	if not map_runtime_state.can_move_to_node(target_node_id):
		return {
			"ok": false,
			"error": "invalid_map_move",
			"node_id": target_node_id,
			"node_type": map_runtime_state.get_node_family(target_node_id),
			"node_state": map_runtime_state.get_node_state(target_node_id),
		}

	active_run_state.hunger = max(0, active_run_state.hunger - MAP_MOVE_HUNGER_COST)
	if active_run_state.hunger == 0:
		active_run_state.player_hp = max(0, active_run_state.player_hp - 1)
	map_runtime_state.move_to_node(target_node_id)
	var target_node_type: String = map_runtime_state.get_node_family(target_node_id)
	var target_node_state: String = map_runtime_state.get_node_state(target_node_id)
	var target_state: int = FlowStateScript.Type.MAP_EXPLORE
	if active_run_state.player_hp <= 0:
		last_run_result = "defeat"
		target_state = FlowStateScript.Type.RUN_END
		_request_transition(target_state)
	elif _should_open_roadside_encounter(active_run_state, map_runtime_state, from_node_id, target_node_id, target_node_type, target_node_state):
		var should_open_roadside_event: bool = _open_event_state(
			target_node_id,
			EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER,
		)
		if should_open_roadside_event and map_runtime_state.consume_roadside_encounter_slot():
			map_runtime_state.mark_node_resolved(target_node_id)
			target_state = FlowStateScript.Type.EVENT
		else:
			if should_open_roadside_event:
				event_state = null
			target_state = FlowStateScript.Type.MAP_EXPLORE
	elif map_runtime_state.node_requires_resolution(target_node_id):
		if target_node_type == "key":
			map_runtime_state.mark_node_resolved(target_node_id)
			map_runtime_state.resolve_stage_key()
		elif DIRECT_SUPPORT_NODE_FAMILIES.has(target_node_type):
			_open_support_interaction_state(target_node_type, target_node_id)
			target_state = FlowStateScript.Type.SUPPORT_INTERACTION
			_request_transition(target_state)
		elif DIRECT_COMBAT_NODE_FAMILIES.has(target_node_type):
			target_state = FlowStateScript.Type.COMBAT
			_request_transition(target_state)
		else:
			map_runtime_state.set_pending_node(target_node_id)
			target_state = FlowStateScript.Type.NODE_RESOLVE
			_request_transition(target_state)
	return {
		"ok": true,
		"node_id": target_node_id,
		"node_type": target_node_type,
		"node_state": map_runtime_state.get_node_state(target_node_id),
		"hunger": active_run_state.hunger,
		"player_hp": active_run_state.player_hp,
		"current_node_id": map_runtime_state.current_node_id,
		"target_state": target_state,
	}


func resolve_pending_node() -> Dictionary:
	var active_run_state: RunState = ensure_run_state_initialized()
	if active_run_state == null:
		return {"ok": false, "error": "missing_run_state"}

	var map_runtime_state: RefCounted = active_run_state.map_runtime_state
	var pending_node_data: Dictionary = active_run_state.map_runtime_state.consume_pending_node_data()
	var pending_node_id: int = int(pending_node_data.get("pending_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var node_type: String = String(pending_node_data.get("pending_node_type", ""))
	var target_state: int = FlowStateScript.Type.MAP_EXPLORE

	match node_type:
		NODE_FAMILY_COMBAT, NODE_FAMILY_BOSS:
			target_state = FlowStateScript.Type.COMBAT
		"event":
			target_state = FlowStateScript.Type.EVENT if _open_event_state(
				pending_node_id,
				EventStateScript.SOURCE_CONTEXT_NODE_EVENT,
			) else FlowStateScript.Type.MAP_EXPLORE
		"reward":
			_open_reward_state(RewardStateScript.SOURCE_REWARD_NODE)
			target_state = FlowStateScript.Type.REWARD
		"key":
			map_runtime_state.resolve_stage_key()
			target_state = FlowStateScript.Type.MAP_EXPLORE
		SupportInteractionStateScript.TYPE_REST, SupportInteractionStateScript.TYPE_MERCHANT, SupportInteractionStateScript.TYPE_BLACKSMITH, NODE_FAMILY_SIDE_MISSION:
			_open_support_interaction_state(node_type, pending_node_id)
			target_state = FlowStateScript.Type.SUPPORT_INTERACTION
		_:
			target_state = FlowStateScript.Type.MAP_EXPLORE

	if target_state not in [
		FlowStateScript.Type.EVENT,
		FlowStateScript.Type.REWARD,
		FlowStateScript.Type.SUPPORT_INTERACTION,
	]:
		_request_transition(target_state)
	return {
		"pending_node_id": pending_node_id,
		"pending_node_type": node_type,
		"stage_key_resolved": map_runtime_state.is_stage_key_resolved(),
		"boss_gate_unlocked": map_runtime_state.is_boss_gate_unlocked(),
		"target_state": target_state,
	}


func choose_reward_option(option_id: String) -> Dictionary:
	var active_run_state: RunState = ensure_run_state_initialized()
	var result: Dictionary = reward_application_policy.apply_option(
		active_run_state,
		reward_state,
		inventory_actions,
		option_id
	)
	if not bool(result.get("ok", false)):
		return result

	reward_state = null
	var target_state: int = _resolve_post_reward_progression()
	result["target_state"] = target_state
	return result


func choose_event_option(option_id: String) -> Dictionary:
	var active_run_state: RunState = ensure_run_state_initialized()
	var result: Dictionary = event_application_policy.apply_option(
		active_run_state,
		event_state,
		inventory_actions,
		option_id
	)
	if not bool(result.get("ok", false)):
		return result

	event_state = null
	var target_state: int = _resolve_post_event_progression(result)
	result["target_state"] = target_state
	return result


func resolve_combat_result(result: String) -> Dictionary:
	var target_state: int = FlowStateScript.Type.RUN_END
	if result == "victory":
		var active_run_state: RunState = ensure_run_state_initialized()
		if active_run_state == null:
			return {"ok": false, "result": result, "error": "missing_run_state"}
		var map_runtime_state: RefCounted = active_run_state.map_runtime_state
		if String(map_runtime_state.get_current_node_family()) == "boss":
			if active_run_state.stage_index >= FINAL_STAGE_INDEX:
				last_run_result = "victory"
				_request_transition(FlowStateScript.Type.RUN_END)
				target_state = FlowStateScript.Type.RUN_END
			else:
				active_run_state.stage_index += 1
				map_runtime_state.reset_for_next_stage(active_run_state.stage_index)
				_request_transition(FlowStateScript.Type.STAGE_TRANSITION)
				target_state = FlowStateScript.Type.STAGE_TRANSITION
		else:
			if map_runtime_state != null:
				map_runtime_state.mark_side_mission_target_completed(int(map_runtime_state.current_node_id))
			active_run_state.xp += COMBAT_VICTORY_XP
			_open_reward_state(RewardStateScript.SOURCE_COMBAT_VICTORY)
			target_state = FlowStateScript.Type.REWARD
	else:
		last_run_result = result
		_request_transition(target_state)
	return {
		"ok": true,
		"result": result,
		"xp": run_state.xp if run_state != null else 0,
		"stage_index": run_state.stage_index if run_state != null else 0,
		"target_state": target_state,
	}


func choose_level_up_option(option_id: String) -> Dictionary:
	var active_run_state: RunState = ensure_run_state_initialized()
	if active_run_state == null:
		return {"ok": false, "option_id": option_id, "error": "missing_run_state"}
	if level_up_state == null:
		return {"ok": false, "option_id": option_id, "error": "missing_level_up_state"}

	var offer: Dictionary = level_up_state.get_offer_by_id(option_id)
	if offer.is_empty():
		return {"ok": false, "option_id": option_id, "error": "unknown_level_up_option"}

	var passive_result: Dictionary = inventory_actions.add_passive_item(
		active_run_state.inventory_state,
		option_id,
		max(1, active_run_state.inventory_state.get_total_capacity())
	)
	if not bool(passive_result.get("ok", false)):
		return {"ok": false, "option_id": option_id, "error": String(passive_result.get("error", "level_up_apply_failed"))}

	var replaced_definition_id: String = String(passive_result.get("replaced_definition_id", ""))
	active_run_state.current_level = int(level_up_state.target_level)
	level_up_state = null

	var target_state: int = FlowStateScript.Type.MAP_EXPLORE
	if _should_offer_level_up():
		_open_level_up_state(LevelUpStateScript.SOURCE_LEVEL_CHAIN)
		target_state = FlowStateScript.Type.LEVEL_UP
	else:
		_request_transition(target_state)

	return {
		"ok": true,
		"option_id": option_id,
		"current_level": active_run_state.current_level,
		"replaced_definition_id": replaced_definition_id,
		"target_state": target_state,
	}


func choose_support_action(action_id: String) -> Dictionary:
	var active_run_state: RunState = ensure_run_state_initialized()
	if active_run_state == null:
		return {"ok": false, "action_id": action_id, "error": "missing_run_state"}
	if support_interaction_state == null:
		return {"ok": false, "action_id": action_id, "error": "missing_support_state"}

	if action_id == "leave":
		_persist_active_support_node_state()
		support_interaction_state = null
		_request_transition(FlowStateScript.Type.MAP_EXPLORE)
		return {"ok": true, "action_id": action_id, "target_state": FlowStateScript.Type.MAP_EXPLORE}
	if action_id == "return_to_blacksmith_services":
		support_interaction_state.return_to_blacksmith_services(active_run_state.inventory_state)
		return {"ok": true, "action_id": action_id, "target_state": FlowStateScript.Type.SUPPORT_INTERACTION}

	var result: Dictionary = support_action_application_policy.apply_action(
		active_run_state,
		support_interaction_state,
		inventory_actions,
		enemy_selection_policy,
		action_id
	)
	if not bool(result.get("ok", false)):
		return result

	_persist_active_support_node_state()
	if bool(result.get("close_interaction", false)):
		support_interaction_state = null
		_request_transition(FlowStateScript.Type.MAP_EXPLORE)
		result["target_state"] = FlowStateScript.Type.MAP_EXPLORE
	else:
		result["target_state"] = FlowStateScript.Type.SUPPORT_INTERACTION
	result.erase("close_interaction")

	return result


func restore_pending_states_for_snapshot(active_flow_state: int, snapshot: Dictionary) -> Dictionary:
	var app_state_variant: Variant = snapshot.get("app_state", {})
	var app_state: Dictionary = app_state_variant if typeof(app_state_variant) == TYPE_DICTIONARY else {}
	last_run_result = String(app_state.get("last_run_result", ""))

	if run_state != null and run_state.map_runtime_state.pending_node_type.is_empty():
		run_state.map_runtime_state.pending_node_type = String(app_state.get("pending_node_type", ""))

	event_state = null
	reward_state = null
	level_up_state = null
	support_interaction_state = null

	if active_flow_state == FlowStateScript.Type.REWARD:
		var reward_variant: Variant = snapshot.get("reward_state", {})
		if typeof(reward_variant) != TYPE_DICTIONARY:
			return {"ok": false, "error": "missing_reward_state"}
		reward_state = RewardStateScript.new()
		reward_state.load_from_save_dict(reward_variant)

	if active_flow_state == FlowStateScript.Type.LEVEL_UP:
		var level_up_variant: Variant = snapshot.get("level_up_state", {})
		if typeof(level_up_variant) != TYPE_DICTIONARY:
			return {"ok": false, "error": "missing_level_up_state"}
		level_up_state = LevelUpStateScript.new()
		level_up_state.load_from_save_dict(level_up_variant)

	if active_flow_state == FlowStateScript.Type.SUPPORT_INTERACTION:
		var support_interaction_variant: Variant = snapshot.get("support_interaction_state", {})
		if typeof(support_interaction_variant) != TYPE_DICTIONARY:
			return {"ok": false, "error": "missing_support_interaction_state"}
		support_interaction_state = SupportInteractionStateScript.new()
		support_interaction_state.load_from_save_dict(support_interaction_variant)

	return {"ok": true}


func _open_event_state(node_id: int, source_context: String = EventStateScript.SOURCE_CONTEXT_NODE_EVENT) -> bool:
	event_state = EventStateScript.new()
	event_state.setup_for_node(
		node_id,
		run_state.stage_index if run_state != null else 1,
		source_context,
	)
	if event_state.choices.is_empty():
		event_state = null
		return false
	_request_transition(FlowStateScript.Type.EVENT)
	return true


func _should_open_roadside_encounter(
	active_run_state: RunState,
	map_runtime_state: RefCounted,
	from_node_id: int,
	target_node_id: int,
	target_node_type: String,
	target_node_state: String,
) -> bool:
	if not map_runtime_state.can_trigger_roadside_encounter():
		return false
	if target_node_state != MapRuntimeStateScript.NODE_STATE_DISCOVERED:
		return false
	if target_node_type in ROADSIDE_ENCOUNTER_EXCLUDED_FAMILIES:
		return false

	var roadside_roll_payload: Dictionary = active_run_state.consume_named_rng_context(
		ROADSIDE_ENCOUNTER_STREAM_NAME,
		"%s|from:%d|to:%d|stage:%d" % [
			target_node_type,
			from_node_id,
			target_node_id,
			active_run_state.stage_index,
		]
	)
	var roadside_rng := RandomNumberGenerator.new()
	roadside_rng.seed = int(roadside_roll_payload.get("stream_seed", 1))
	return roadside_rng.randf() < ROADSIDE_ENCOUNTER_TRIGGER_CHANCE


func _open_reward_state(source_context: String) -> void:
	reward_state = RewardStateScript.new()
	reward_state.setup_for_source(source_context, _build_reward_generation_context(source_context))
	_request_transition(FlowStateScript.Type.REWARD)


func _open_level_up_state(source_context: String) -> void:
	level_up_state = LevelUpStateScript.new()
	var loader: ContentLoader = ContentLoaderScript.new()
	level_up_state.setup_for_level(
		source_context,
		run_state.current_level,
		level_up_offer_window_policy.build_offer_window(loader, run_state.current_level),
		run_state.inventory_state.get_used_capacity() >= run_state.inventory_state.get_total_capacity()
	)
	_request_transition(FlowStateScript.Type.LEVEL_UP)


func _open_support_interaction_state(support_type: String, node_id: int) -> void:
	support_interaction_state = SupportInteractionStateScript.new()
	var persisted_node_state: Dictionary = {}
	var stage_index: int = 1
	if run_state != null:
		if support_type == NODE_FAMILY_SIDE_MISSION:
			persisted_node_state = run_state.map_runtime_state.get_side_mission_node_runtime_state(node_id)
		else:
			persisted_node_state = run_state.map_runtime_state.get_support_node_runtime_state(node_id)
		stage_index = max(1, int(run_state.stage_index))
	support_interaction_state.setup_for_type(
		support_type,
		node_id,
		persisted_node_state,
		stage_index,
		run_state.inventory_state if run_state != null else null,
		run_state.map_runtime_state if run_state != null else null
	)
	_request_transition(FlowStateScript.Type.SUPPORT_INTERACTION)


func _persist_active_support_node_state() -> void:
	if run_state == null or support_interaction_state == null:
		return
	var support_node_id: int = int(support_interaction_state.source_node_id)
	if support_node_id < 0:
		return
	if String(support_interaction_state.support_type) == NODE_FAMILY_SIDE_MISSION:
		run_state.map_runtime_state.save_side_mission_node_runtime_state(
			support_node_id,
			support_interaction_state.build_persisted_node_state()
		)
		return
	run_state.map_runtime_state.save_support_node_runtime_state(
		support_node_id,
		support_interaction_state.build_persisted_node_state()
	)


func _resolve_post_reward_progression() -> int:
	if _should_offer_level_up():
		_open_level_up_state(LevelUpStateScript.SOURCE_REWARD_RESOLUTION)
		return FlowStateScript.Type.LEVEL_UP

	_request_transition(FlowStateScript.Type.MAP_EXPLORE)
	return FlowStateScript.Type.MAP_EXPLORE


func _resolve_post_event_progression(event_result: Dictionary) -> int:
	if bool(event_result.get("player_defeated", false)):
		last_run_result = "defeat"
		_request_transition(FlowStateScript.Type.RUN_END)
		return FlowStateScript.Type.RUN_END

	if _should_offer_level_up():
		_open_level_up_state(LevelUpStateScript.SOURCE_EVENT_RESOLUTION)
		return FlowStateScript.Type.LEVEL_UP

	_request_transition(FlowStateScript.Type.MAP_EXPLORE)
	return FlowStateScript.Type.MAP_EXPLORE


func _should_offer_level_up() -> bool:
	if run_state == null:
		return false
	var next_level: int = run_state.current_level + 1
	var threshold: int = LevelUpStateScript.threshold_for_level(next_level)
	return threshold >= 0 and run_state.xp >= threshold


func _request_transition(target_state: int) -> void:
	if game_flow_manager == null:
		return
	game_flow_manager.request_transition(target_state)


func _build_reward_generation_context(source_context: String) -> Dictionary:
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
	}


func _extract_consumable_use_profile(use_effect: Dictionary) -> Dictionary:
	if use_effect.is_empty():
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
		}
	if String(use_effect.get("trigger", "")) != "on_use":
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
		}
	if String(use_effect.get("target", "")) != "self":
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
		}

	var effects_variant: Variant = use_effect.get("effects", [])
	if typeof(effects_variant) != TYPE_ARRAY:
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
		}

	var heal_amount: int = 0
	var hunger_delta: int = 0
	for effect_value in effects_variant:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		var params: Dictionary = effect.get("params", {})
		match String(effect.get("type", "")):
			"heal":
				heal_amount += int(params.get("base", 0))
			"modify_hunger":
				hunger_delta += int(params.get("amount", 0))

	return {
		"heal_amount": heal_amount,
		"hunger_delta": hunger_delta,
	}
