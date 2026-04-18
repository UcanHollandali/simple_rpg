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

const COMBAT_VICTORY_XP: int = 6
const FINAL_STAGE_INDEX: int = 3
const MAP_MOVE_HUNGER_COST: int = 1
const ROADSIDE_ENCOUNTER_STREAM_NAME: String = "roadside_encounter_rng"
const ROADSIDE_ENCOUNTER_TRIGGER_CHANCE: float = 0.28
const APP_STATE_KEY_PENDING_NODE_ID: String = "pending_node_id"
const APP_STATE_KEY_PENDING_NODE_TYPE: String = "pending_node_type"
const ROADSIDE_ENCOUNTER_EXCLUDED_FAMILIES: PackedStringArray = [
	"start",
	"boss",
	"event",
	"key",
	"support",
	"rest",
	"merchant",
	"blacksmith",
	"hamlet",
]
const NODE_FAMILY_COMBAT: String = "combat"
const NODE_FAMILY_BOSS: String = "boss"
const NODE_FAMILY_KEY: String = "key"
const NODE_FAMILY_EVENT: String = "event"
const NODE_FAMILY_REWARD: String = "reward"
const NODE_FAMILY_HAMLET: String = "hamlet"
const LEGACY_NODE_FAMILY_SIDE_MISSION: String = "side_mission"
const DIRECT_SUPPORT_NODE_FAMILIES: PackedStringArray = [
	SupportInteractionStateScript.TYPE_REST,
	SupportInteractionStateScript.TYPE_MERCHANT,
	SupportInteractionStateScript.TYPE_BLACKSMITH,
	NODE_FAMILY_HAMLET,
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
var _last_combat_reward_context: Dictionary = {}

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
	_last_combat_reward_context = {}


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
	var app_state: Dictionary = {
		"last_run_result": last_run_result,
	}
	if run_state != null and run_state.map_runtime_state != null and run_state.map_runtime_state.has_pending_node():
		app_state[APP_STATE_KEY_PENDING_NODE_ID] = int(run_state.map_runtime_state.pending_node_id)
		app_state[APP_STATE_KEY_PENDING_NODE_TYPE] = String(run_state.map_runtime_state.pending_node_type)
	return app_state


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
	_last_combat_reward_context = _build_combat_reward_generation_context(enemy_definition_id, enemy_definition)

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

	var use_profile: Dictionary = InventoryActionsScript.extract_consumable_use_profile(consumable_definition.get("rules", {}).get("use_effect", {}))
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
	if active_run_state.player_hp <= 0:
		last_run_result = "defeat"
		_request_transition(FlowStateScript.Type.RUN_END)
		return {
			"ok": true,
			"node_id": target_node_id,
			"node_type": map_runtime_state.get_node_family(target_node_id),
			"node_state": map_runtime_state.get_node_state(target_node_id),
			"hunger": active_run_state.hunger,
			"player_hp": active_run_state.player_hp,
			"current_node_id": map_runtime_state.current_node_id,
			"stage_key_resolved": map_runtime_state.is_stage_key_resolved(),
			"boss_gate_unlocked": map_runtime_state.is_boss_gate_unlocked(),
			"target_state": FlowStateScript.Type.RUN_END,
		}
	var target_node_type: String = map_runtime_state.get_node_family(target_node_id)
	var target_node_state: String = map_runtime_state.get_node_state(target_node_id)
	if _should_open_roadside_encounter(
		active_run_state,
		map_runtime_state,
		from_node_id,
		target_node_id,
		target_node_type,
		target_node_state
	):
		if _begin_roadside_encounter_for_destination(map_runtime_state, target_node_id):
			return {
				"ok": true,
				"node_id": target_node_id,
				"node_type": target_node_type,
				"node_state": map_runtime_state.get_node_state(target_node_id),
				"hunger": active_run_state.hunger,
				"player_hp": active_run_state.player_hp,
				"current_node_id": map_runtime_state.current_node_id,
				"stage_key_resolved": map_runtime_state.is_stage_key_resolved(),
				"boss_gate_unlocked": map_runtime_state.is_boss_gate_unlocked(),
				"target_state": FlowStateScript.Type.EVENT,
			}
	map_runtime_state.move_to_node(target_node_id)
	var target_state: int = _resolve_post_move_target_state(
		active_run_state,
		map_runtime_state,
		from_node_id,
		target_node_id,
		target_node_type,
		target_node_state
	)
	return {
		"ok": true,
		"node_id": target_node_id,
		"node_type": target_node_type,
		"node_state": map_runtime_state.get_node_state(target_node_id),
		"hunger": active_run_state.hunger,
		"player_hp": active_run_state.player_hp,
		"current_node_id": map_runtime_state.current_node_id,
		"stage_key_resolved": map_runtime_state.is_stage_key_resolved(),
		"boss_gate_unlocked": map_runtime_state.is_boss_gate_unlocked(),
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
	var target_state: int = _resolve_pending_node_target_state(
		map_runtime_state,
		pending_node_id,
		node_type
	)

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


func choose_reward_option(option_id: String, discard_slot_id: int = -1, leave_item: bool = false) -> Dictionary:
	var active_run_state: RunState = ensure_run_state_initialized()
	var result: Dictionary = reward_application_policy.apply_option(
		active_run_state,
		reward_state,
		inventory_actions,
		option_id,
		discard_slot_id,
		leave_item
	)
	if not bool(result.get("ok", false)):
		return result

	reward_state = null
	var target_state: int = _resolve_post_reward_progression()
	result["target_state"] = target_state
	return result

func choose_event_option(option_id: String, discard_slot_id: int = -1, leave_item: bool = false) -> Dictionary:
	var active_run_state: RunState = ensure_run_state_initialized()
	var source_context: String = event_state.source_context if event_state != null else EventStateScript.SOURCE_CONTEXT_DEFAULT
	var result: Dictionary = event_application_policy.apply_option(
		active_run_state,
		event_state,
		inventory_actions,
		option_id,
		discard_slot_id,
		leave_item
	)
	if not bool(result.get("ok", false)):
		return result

	event_state = null
	var target_state: int = _resolve_post_event_progression(result, source_context)
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
				map_runtime_state.reset_for_next_stage(active_run_state.stage_index, active_run_state.run_seed)
				_request_transition(FlowStateScript.Type.STAGE_TRANSITION)
				target_state = FlowStateScript.Type.STAGE_TRANSITION
		else:
			if map_runtime_state != null:
				var completed_side_quest_state: Dictionary = map_runtime_state.mark_side_quest_target_completed(int(map_runtime_state.current_node_id))
				_apply_side_quest_completion_hooks(active_run_state, completed_side_quest_state)
			active_run_state.xp += COMBAT_VICTORY_XP
			_open_reward_state(RewardStateScript.SOURCE_COMBAT_VICTORY, true)
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

	var perk_result: Dictionary = active_run_state.character_perk_state.learn_perk(option_id)
	if not bool(perk_result.get("ok", false)):
		return {"ok": false, "option_id": option_id, "error": String(perk_result.get("error", "level_up_apply_failed"))}

	active_run_state.current_level = int(level_up_state.target_level)
	level_up_state = null

	var target_state: int = FlowStateScript.Type.MAP_EXPLORE
	if _should_offer_level_up():
		_open_level_up_state(LevelUpStateScript.SOURCE_LEVEL_CHAIN)
		target_state = FlowStateScript.Type.LEVEL_UP
	else:
		if active_run_state.map_runtime_state != null and active_run_state.map_runtime_state.has_pending_node():
			target_state = _continue_pending_destination_flow(active_run_state.map_runtime_state)
		else:
			_request_transition(target_state)

	return {
		"ok": true,
		"option_id": option_id,
		"learned_perk_id": String(perk_result.get("definition_id", option_id)),
		"current_level": active_run_state.current_level,
		"target_state": target_state,
	}

func choose_support_action(action_id: String, discard_slot_id: int = -1) -> Dictionary:
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
		action_id,
		discard_slot_id
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

	if run_state != null and run_state.map_runtime_state != null:
		var restored_pending_node_id: int = int(app_state.get(APP_STATE_KEY_PENDING_NODE_ID, MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if restored_pending_node_id != MapRuntimeStateScript.NO_PENDING_NODE_ID:
			run_state.map_runtime_state.set_pending_node(restored_pending_node_id)
			if run_state.map_runtime_state.pending_node_type.is_empty():
				run_state.map_runtime_state.pending_node_type = String(app_state.get(APP_STATE_KEY_PENDING_NODE_TYPE, ""))

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


func _resolve_post_move_target_state(
	active_run_state: RunState,
	map_runtime_state: RefCounted,
	from_node_id: int,
	target_node_id: int,
	target_node_type: String,
	target_node_state: String,
) -> int:
	if active_run_state.player_hp <= 0:
		last_run_result = "defeat"
		_request_transition(FlowStateScript.Type.RUN_END)
		return FlowStateScript.Type.RUN_END

	_complete_noncombat_side_quest_target_on_arrival(
		active_run_state,
		map_runtime_state,
		target_node_id,
		target_node_type
	)

	if not map_runtime_state.node_requires_resolution(target_node_id):
		return FlowStateScript.Type.MAP_EXPLORE

	return _resolve_direct_node_entry_target_state(map_runtime_state, target_node_id, target_node_type)


func _begin_roadside_encounter_for_destination(map_runtime_state: RefCounted, target_node_id: int) -> bool:
	map_runtime_state.set_pending_node(target_node_id)
	var should_open_roadside_event: bool = _open_event_state(
		target_node_id,
		EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER,
	)
	if should_open_roadside_event and map_runtime_state.consume_roadside_encounter_slot():
		return true
	if should_open_roadside_event:
		event_state = null
	map_runtime_state.clear_pending_node()
	return false


func _resolve_direct_node_entry_target_state(
	map_runtime_state: RefCounted,
	target_node_id: int,
	target_node_type: String,
) -> int:
	if target_node_type == NODE_FAMILY_KEY:
		map_runtime_state.mark_node_resolved(target_node_id)
		map_runtime_state.resolve_stage_key()
		return FlowStateScript.Type.MAP_EXPLORE
	if target_node_type == NODE_FAMILY_EVENT:
		return FlowStateScript.Type.EVENT if _open_event_state(
			target_node_id,
			EventStateScript.SOURCE_CONTEXT_NODE_EVENT,
			true
		) else FlowStateScript.Type.MAP_EXPLORE
	if target_node_type == NODE_FAMILY_REWARD:
		_open_reward_state(RewardStateScript.SOURCE_REWARD_NODE, true)
		return FlowStateScript.Type.REWARD
	if DIRECT_SUPPORT_NODE_FAMILIES.has(target_node_type):
		_open_support_interaction_state(target_node_type, target_node_id)
		return FlowStateScript.Type.SUPPORT_INTERACTION
	if DIRECT_COMBAT_NODE_FAMILIES.has(target_node_type):
		_request_transition(FlowStateScript.Type.COMBAT)
		return FlowStateScript.Type.COMBAT

	map_runtime_state.set_pending_node(target_node_id)
	_request_transition(FlowStateScript.Type.NODE_RESOLVE)
	return FlowStateScript.Type.NODE_RESOLVE


func _resolve_pending_node_target_state(
	map_runtime_state: RefCounted,
	pending_node_id: int,
	node_type: String,
) -> int:
	match node_type:
		NODE_FAMILY_COMBAT, NODE_FAMILY_BOSS:
			return FlowStateScript.Type.COMBAT
		NODE_FAMILY_EVENT:
			return FlowStateScript.Type.EVENT if _open_event_state(
				pending_node_id,
				EventStateScript.SOURCE_CONTEXT_NODE_EVENT,
			) else FlowStateScript.Type.MAP_EXPLORE
		NODE_FAMILY_REWARD:
			_open_reward_state(RewardStateScript.SOURCE_REWARD_NODE)
			return FlowStateScript.Type.REWARD
		NODE_FAMILY_KEY:
			map_runtime_state.resolve_stage_key()
			return FlowStateScript.Type.MAP_EXPLORE
		SupportInteractionStateScript.TYPE_REST, SupportInteractionStateScript.TYPE_MERCHANT, SupportInteractionStateScript.TYPE_BLACKSMITH, NODE_FAMILY_HAMLET, LEGACY_NODE_FAMILY_SIDE_MISSION:
			_open_support_interaction_state(node_type, pending_node_id)
			return FlowStateScript.Type.SUPPORT_INTERACTION
		_:
			return FlowStateScript.Type.MAP_EXPLORE


func _open_event_state(
	node_id: int,
	source_context: String = EventStateScript.SOURCE_CONTEXT_NODE_EVENT,
	mark_source_node_resolved: bool = false,
) -> bool:
	event_state = EventStateScript.new()
	var trigger_context: Dictionary = {}
	if source_context == EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER:
		trigger_context = _build_roadside_trigger_context(run_state)
	event_state.setup_for_node(
		node_id,
		run_state.stage_index if run_state != null else 1,
		source_context,
		run_state.run_seed if run_state != null else EventStateScript.DEFAULT_SELECTION_SEED,
		trigger_context
	)
	if event_state.choices.is_empty():
		event_state = null
		return false
	if mark_source_node_resolved and run_state != null and run_state.map_runtime_state != null:
		run_state.map_runtime_state.mark_node_resolved(node_id)
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
	if not map_runtime_state.get_active_side_quest_by_target_node_id(target_node_id).is_empty():
		return false
	if target_node_type in ROADSIDE_ENCOUNTER_EXCLUDED_FAMILIES:
		return false
	if not _has_eligible_roadside_template(active_run_state, target_node_id):
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


func _has_eligible_roadside_template(active_run_state: RunState, target_node_id: int) -> bool:
	if active_run_state == null:
		return false
	var preview_event_state: EventStateScript = EventStateScript.new()
	preview_event_state.setup_for_node(
		target_node_id,
		active_run_state.stage_index,
		EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER,
		active_run_state.run_seed,
		_build_roadside_trigger_context(active_run_state)
	)
	return not preview_event_state.choices.is_empty()


func _build_roadside_trigger_context(active_run_state: RunState) -> Dictionary:
	if active_run_state == null:
		return {}
	var inventory_state: InventoryState = active_run_state.inventory_state
	var max_hp: int = max(1, RunState.DEFAULT_PLAYER_HP)
	var hp_percent: float = (float(active_run_state.player_hp) / float(max_hp)) * 100.0
	return {
		EventStateScript.TRIGGER_STAT_HUNGER: active_run_state.hunger,
		EventStateScript.TRIGGER_STAT_HP_PERCENT: hp_percent,
		EventStateScript.TRIGGER_STAT_GOLD: active_run_state.gold,
		EventStateScript.TRIGGER_STAT_HAS_EMPTY_BACKPACK_SLOT: inventory_state != null and inventory_state.has_capacity_for_new_slot(),
	}


func _open_reward_state(source_context: String, mark_current_node_resolved: bool = false) -> void:
	reward_state = RewardStateScript.new()
	reward_state.setup_for_source(source_context, _build_reward_generation_context(source_context))
	if mark_current_node_resolved and run_state != null and run_state.map_runtime_state != null:
		run_state.map_runtime_state.mark_node_resolved(run_state.map_runtime_state.current_node_id)
	_request_transition(FlowStateScript.Type.REWARD)


func _open_level_up_state(source_context: String) -> void:
	level_up_state = LevelUpStateScript.new()
	var loader: ContentLoader = ContentLoaderScript.new()
	level_up_state.setup_for_level(
		source_context,
		run_state.current_level,
		level_up_offer_window_policy.build_offer_window(
			loader,
			run_state.current_level,
			run_state.character_perk_state.get_owned_perk_ids()
		)
	)
	_request_transition(FlowStateScript.Type.LEVEL_UP)


func _open_support_interaction_state(support_type: String, node_id: int) -> void:
	support_interaction_state = SupportInteractionStateScript.new()
	var persisted_node_state: Dictionary = {}
	var stage_index: int = 1
	var normalized_support_type: String = _normalize_support_route_family(support_type)
	if run_state != null:
		if normalized_support_type == NODE_FAMILY_HAMLET:
			persisted_node_state = run_state.map_runtime_state.get_side_quest_node_runtime_state(node_id)
		else:
			persisted_node_state = run_state.map_runtime_state.get_support_node_runtime_state(node_id)
		stage_index = max(1, int(run_state.stage_index))
	support_interaction_state.setup_for_type(
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
	_request_transition(FlowStateScript.Type.SUPPORT_INTERACTION)


func _persist_active_support_node_state() -> void:
	if run_state == null or support_interaction_state == null:
		return
	var support_node_id: int = int(support_interaction_state.source_node_id)
	if support_node_id < 0:
		return
	if String(support_interaction_state.support_type) == NODE_FAMILY_HAMLET:
		run_state.map_runtime_state.save_side_quest_node_runtime_state(
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


func _resolve_post_event_progression(
	event_result: Dictionary,
	source_context: String = EventStateScript.SOURCE_CONTEXT_DEFAULT,
) -> int:
	var map_runtime_state: RefCounted = run_state.map_runtime_state if run_state != null else null
	if bool(event_result.get("player_defeated", false)):
		if map_runtime_state != null:
			map_runtime_state.clear_pending_node()
		last_run_result = "defeat"
		_request_transition(FlowStateScript.Type.RUN_END)
		return FlowStateScript.Type.RUN_END

	if _should_offer_level_up():
		_open_level_up_state(LevelUpStateScript.SOURCE_EVENT_RESOLUTION)
		return FlowStateScript.Type.LEVEL_UP

	if source_context == EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER and map_runtime_state != null and map_runtime_state.has_pending_node():
		return _continue_pending_destination_flow(map_runtime_state)

	_request_transition(FlowStateScript.Type.MAP_EXPLORE)
	return FlowStateScript.Type.MAP_EXPLORE


func _continue_pending_destination_flow(map_runtime_state: RefCounted) -> int:
	if map_runtime_state == null or not map_runtime_state.has_pending_node():
		_request_transition(FlowStateScript.Type.MAP_EXPLORE)
		return FlowStateScript.Type.MAP_EXPLORE
	if game_flow_manager != null and game_flow_manager.get_current_state() != FlowStateScript.Type.MAP_EXPLORE:
		_request_transition(FlowStateScript.Type.MAP_EXPLORE)
	var pending_node_data: Dictionary = map_runtime_state.consume_pending_node_data()
	var pending_node_id: int = int(pending_node_data.get("pending_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	if pending_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID or not map_runtime_state.has_node(pending_node_id):
		_request_transition(FlowStateScript.Type.MAP_EXPLORE)
		return FlowStateScript.Type.MAP_EXPLORE
	map_runtime_state.move_to_node(pending_node_id)
	if not map_runtime_state.node_requires_resolution(pending_node_id):
		_request_transition(FlowStateScript.Type.MAP_EXPLORE)
		return FlowStateScript.Type.MAP_EXPLORE
	var pending_node_type: String = String(pending_node_data.get("pending_node_type", ""))
	if pending_node_type.is_empty():
		pending_node_type = String(map_runtime_state.get_node_family(pending_node_id))
	return _resolve_direct_node_entry_target_state(map_runtime_state, pending_node_id, pending_node_type)


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
	}.merged(_last_combat_reward_context if source_context == RewardStateScript.SOURCE_COMBAT_VICTORY else {}, true)


func _build_combat_reward_generation_context(enemy_definition_id: String, enemy_definition: Dictionary) -> Dictionary:
	return {
		"enemy_definition_id": enemy_definition_id,
		"enemy_tags": _extract_enemy_tags(enemy_definition),
	}


func _extract_enemy_tags(enemy_definition: Dictionary) -> PackedStringArray:
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


func _normalize_support_route_family(node_family: String) -> String:
	return NODE_FAMILY_HAMLET if node_family == LEGACY_NODE_FAMILY_SIDE_MISSION else node_family


func _complete_noncombat_side_quest_target_on_arrival(
	active_run_state: RunState,
	map_runtime_state: RefCounted,
	target_node_id: int,
	target_node_type: String
) -> void:
	if active_run_state == null or map_runtime_state == null:
		return
	if target_node_type in DIRECT_COMBAT_NODE_FAMILIES:
		return
	var active_side_quest_state: Dictionary = map_runtime_state.get_active_side_quest_by_target_node_id(target_node_id)
	if active_side_quest_state.is_empty():
		return

	var mission_type: String = String(active_side_quest_state.get("mission_type", SupportInteractionStateScript.MISSION_TYPE_HUNT_MARKED_ENEMY))
	if mission_type == SupportInteractionStateScript.MISSION_TYPE_HUNT_MARKED_ENEMY:
		return

	var quest_item_definition_id: String = String(active_side_quest_state.get("quest_item_definition_id", "")).strip_edges()
	if mission_type == SupportInteractionStateScript.MISSION_TYPE_DELIVER_SUPPLIES:
		if quest_item_definition_id.is_empty():
			return
		var remove_result: Dictionary = inventory_actions.remove_quest_item(active_run_state.inventory_state, quest_item_definition_id)
		if not bool(remove_result.get("ok", false)):
			return

	var completed_side_quest_state: Dictionary = map_runtime_state.mark_side_quest_target_completed(target_node_id)
	_apply_side_quest_completion_hooks(active_run_state, completed_side_quest_state)


func _apply_side_quest_completion_hooks(active_run_state: RunState, completed_side_quest_state: Dictionary) -> void:
	if active_run_state == null or completed_side_quest_state.is_empty():
		return
	var mission_type: String = String(completed_side_quest_state.get("mission_type", ""))
	var quest_item_definition_id: String = String(completed_side_quest_state.get("quest_item_definition_id", "")).strip_edges()
	if mission_type != SupportInteractionStateScript.MISSION_TYPE_BRING_PROOF:
		return
	if quest_item_definition_id.is_empty():
		return
	if _inventory_contains_family_definition(active_run_state.inventory_state, InventoryState.INVENTORY_FAMILY_QUEST_ITEM, quest_item_definition_id):
		return
	inventory_actions.add_quest_item(active_run_state.inventory_state, quest_item_definition_id)


func _inventory_contains_family_definition(
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
