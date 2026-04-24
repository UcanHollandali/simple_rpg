# Layer: RuntimeState
extends RefCounted
class_name MapRuntimeState

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const MapScatterGraphToolsScript = preload("res://Game/RuntimeState/map_scatter_graph_tools.gd")
const MapRuntimeGraphCodecScript = preload("res://Game/RuntimeState/map_runtime_graph_codec.gd")
const MapRuntimeLocalStateHelperScript = preload("res://Game/RuntimeState/map_runtime_local_state_helper.gd")

const NODE_STATE_UNDISCOVERED: String = "undiscovered"
const NODE_STATE_DISCOVERED: String = "discovered"
const NODE_STATE_RESOLVED: String = "resolved"
const NODE_STATE_LOCKED: String = "locked"

const DEFAULT_NODE_INDEX: int = 0
const NO_PENDING_NODE_ID: int = -1
const MAP_TEMPLATE_FAMILY: String = "MapTemplates"
const DEFAULT_LEGACY_TEMPLATE_ID: String = "fixed_stage_cluster"
const DEFAULT_SCAFFOLD_TEMPLATE_ID: String = "procedural_stage_corridor_v1"
const STAGE_SCAFFOLD_TEMPLATE_IDS: PackedStringArray = [
	"procedural_stage_corridor_v1",
	"procedural_stage_openfield_v1",
	"procedural_stage_loop_v1",
]
const SCATTER_NODE_COUNT: int = 14
const SCATTER_START_BRANCH_COUNT: int = 3
const SCATTER_START_SPUR_NODE_COUNT: int = 1
const SCATTER_REQUIRED_START_DEGREE: int = 4
const SCATTER_MAX_NODE_DEGREE: int = 4
const SCATTER_MAX_NON_START_NODE_DEGREE: int = 3
const SCATTER_MAX_OPENING_NODE_DEGREE: int = 2
const SCATTER_EXTRA_EDGES_MIN: int = 2
const SCATTER_EXTRA_EDGES_MAX: int = 4
const SCATTER_ATTEMPT_LIMIT: int = 16
const SCATTER_MIN_RECONNECT_EDGE_COUNT: int = 1
const SCATTER_MAX_RECONNECT_EDGE_COUNT: int = 2
const SCATTER_MIN_RECONNECT_PATH_LENGTH: int = 3
const SCATTER_MAX_RECONNECT_PATH_LENGTH: int = 6
const SCATTER_MIN_LEAF_COUNT: int = 2
const SCATTER_MIN_TWO_WAY_COUNT: int = 2
const SCATTER_MIN_THREE_WAY_COUNT: int = 1
const SCATTER_BRANCH_COMBAT: int = 0
const SCATTER_BRANCH_REWARD: int = 1
const SCATTER_BRANCH_SUPPORT: int = 2
const SCATTER_ROLE_OPENING_COMBAT: String = "opening_combat_node_id"
const SCATTER_ROLE_OPENING_REWARD: String = "opening_reward_node_id"
const SCATTER_ROLE_OPENING_SUPPORT: String = "opening_support_node_id"
const SCATTER_ROLE_LATE_SUPPORT: String = "late_support_node_id"
const SCATTER_ROLE_EVENT: String = "event_node_id"
const SCATTER_ROLE_HAMLET: String = "hamlet_node_id"
const SCATTER_ROLE_SIDE_MISSION: String = SCATTER_ROLE_HAMLET
const SCATTER_ROLE_KEY: String = "key_node_id"
const SCATTER_ROLE_BOSS: String = "boss_node_id"
const LAYOUT_SECTOR_CENTER_ANCHOR: String = "center_anchor"
const LAYOUT_SECTOR_NORTH_WEST: String = "north_west"
const LAYOUT_SECTOR_NORTH_CENTER: String = "north_center"
const LAYOUT_SECTOR_NORTH_EAST: String = "north_east"
const LAYOUT_SECTOR_MID_LEFT: String = "mid_left"
const LAYOUT_SECTOR_MID_RIGHT: String = "mid_right"
const LAYOUT_SECTOR_SOUTH_WEST: String = "south_west"
const LAYOUT_SECTOR_SOUTH_CENTER: String = "south_center"
const LAYOUT_SECTOR_SOUTH_EAST: String = "south_east"
const LAYOUT_SECTOR_OUTER_LATE_WEST: String = "outer_late_west"
const LAYOUT_SECTOR_OUTER_LATE_EAST: String = "outer_late_east"
const LAYOUT_ROUTE_ROLE_CENTER_START: String = "center_start"
const LAYOUT_ROUTE_ROLE_OPENING_COMBAT: String = "opening_combat"
const LAYOUT_ROUTE_ROLE_OPENING_REWARD: String = "opening_reward"
const LAYOUT_ROUTE_ROLE_OPENING_SUPPORT: String = "opening_support"
const LAYOUT_ROUTE_ROLE_LATE_SUPPORT: String = "late_support"
const LAYOUT_ROUTE_ROLE_EVENT_DETOUR: String = "event_detour"
const LAYOUT_ROUTE_ROLE_HAMLET_DETOUR: String = "hamlet_detour"
const LAYOUT_ROUTE_ROLE_KEY_PRESSURE: String = "key_pressure"
const LAYOUT_ROUTE_ROLE_BOSS_PRESSURE: String = "boss_pressure"
const LAYOUT_ROUTE_ROLE_COMBAT_ROUTE: String = "combat_route"
const LAYOUT_ROUTE_ROLE_BRANCH_POCKET: String = "branch_pocket"
const LAYOUT_ORIENTATION_PROFILE_BALANCED: String = "center_outward_balanced"
const LAYOUT_ORIENTATION_PROFILE_WEST_WEIGHTED: String = "center_outward_west_weighted"
const LAYOUT_ORIENTATION_PROFILE_EAST_WEIGHTED: String = "center_outward_east_weighted"
const SCATTER_RECONNECT_DEPTH_MID: int = 2
const SCATTER_RECONNECT_DEPTH_LATE: int = 3
const SCATTER_MAX_LOCAL_BRANCH_DISTANCE: int = 1
const PLACEMENT_BRANCH_TARGET_NODE_COUNT: int = 4
const PLACEMENT_OPENING_MAX_DEPTH: int = 2
const PLACEMENT_OUTER_MIN_DEPTH: int = 3
const PLACEMENT_LATE_SUPPORT_TARGET_DEPTH: int = 3
const PLACEMENT_EVENT_TARGET_DEPTH: int = 3
const PLACEMENT_SCORE_STRONG_BONUS: float = 8.0
const PLACEMENT_SCORE_MEDIUM_BONUS: float = 4.0
const PLACEMENT_SCORE_LIGHT_BONUS: float = 1.5
const PLACEMENT_SHORTLIST_STANDARD_LIMIT: int = 3
const PLACEMENT_SHORTLIST_DETOUR_LIMIT: int = 4
const PLACEMENT_SHORTLIST_NARROW_SCORE_WINDOW: float = 1.25
const PLACEMENT_SHORTLIST_STANDARD_SCORE_WINDOW: float = 1.75
const PLACEMENT_SHORTLIST_WIDE_SCORE_WINDOW: float = 3.0
const LEGACY_STAGE_TEMPLATE_IDS: PackedStringArray = [
	"fixed_stage_cluster",
	"fixed_stage_detour",
]
const SAVE_KEY_ACTIVE_TEMPLATE_ID: String = "active_map_template_id"
const SAVE_KEY_REALIZED_GRAPH: String = "map_realized_graph"
const SAVE_KEY_SIDE_MISSION_NODE_STATES: String = "side_mission_node_states"
const SAVE_KEY_ROADSIDE_ENCOUNTERS_THIS_STAGE: String = "roadside_encounters_this_stage"
const SLOT_TYPE_OPENING_SUPPORT: String = "opening_support"
const SLOT_TYPE_LATE_PRIMARY: String = "late_primary"
const SLOT_TYPE_LATE_EVENT: String = "late_event"
const SLOT_TYPE_LATE_HAMLET: String = "late_hamlet"
const SLOT_TYPE_LATE_SIDE_MISSION: String = SLOT_TYPE_LATE_HAMLET
const SIDE_MISSION_DEFAULT_DEFINITION_ID: String = "trail_contract_hunt"
const MAX_ROADSIDE_ENCOUNTERS_PER_STAGE: int = 3
const DEFAULT_GENERATION_SEED: int = 1
const SUPPORT_NODE_FAMILIES: PackedStringArray = ["rest", "merchant", "blacksmith"]
const SIDE_MISSION_STATUS_OFFERED: String = "offered"
const SIDE_MISSION_STATUS_ACCEPTED: String = "accepted"
const SIDE_MISSION_STATUS_COMPLETED: String = "completed"
const SIDE_MISSION_STATUS_CLAIMED: String = "claimed"
const NODE_FAMILY_HAMLET: String = "hamlet"
const LEGACY_NODE_FAMILY_SIDE_MISSION: String = "side_mission"
const SIDE_QUEST_MISSION_TYPE_HUNT_MARKED_ENEMY: String = "hunt_marked_enemy"
const SIDE_QUEST_MISSION_TYPE_DELIVER_SUPPLIES: String = "deliver_supplies"
const SIDE_QUEST_MISSION_TYPE_RESCUE_MISSING_SCOUT: String = "rescue_missing_scout"
const SIDE_QUEST_MISSION_TYPE_BRING_PROOF: String = "bring_proof"
const STAGE_SUPPORT_LAYOUTS: Array[Dictionary] = [
	{
		"opening_support_family": "rest",
		"late_support_family": "merchant",
	},
	{
		"opening_support_family": "merchant",
		"late_support_family": "blacksmith",
	},
	{
		"opening_support_family": "rest",
		"late_support_family": "blacksmith",
	},
]

var current_node_id: int = DEFAULT_NODE_INDEX
var pending_node_id: int = NO_PENDING_NODE_ID
var pending_node_type: String = ""
var stage_key_resolved: bool = false
var roadside_encounters_this_stage: int = 0
var _node_graph: Array[Dictionary] = []
var _support_node_states: Dictionary = {}
var _side_mission_node_states: Dictionary = {}
var _active_template_id: String = DEFAULT_SCAFFOLD_TEMPLATE_ID
var _generation_stage_index: int = 1
var _generation_seed: int = DEFAULT_GENERATION_SEED
var _active_topology_blueprint_id: String = ""
var _family_budget_slot_reservations: Dictionary = {}
var _graph_codec: MapRuntimeGraphCodec = MapRuntimeGraphCodecScript.new()

var current_node_index: int:
	get:
		return current_node_id
	set(value):
		current_node_id = value

func reset_for_new_run(stage_index: int = 1, generation_seed: int = -1) -> void:
	_reset_runtime_state()
	_generation_stage_index = max(1, stage_index)
	_generation_seed = _resolve_generation_seed(generation_seed)
	_active_template_id = _resolve_scaffold_id_for_stage(_generation_stage_index)
	_node_graph = _build_scaffold_graph(_active_template_id, _generation_stage_index)
	_set_node_state(DEFAULT_NODE_INDEX, NODE_STATE_RESOLVED)
	_reveal_adjacent_nodes(DEFAULT_NODE_INDEX)


func reset_for_next_stage(stage_index: int = 1, generation_seed: int = -1) -> void:
	reset_for_new_run(stage_index, generation_seed)


func has_node(node_id: int) -> bool:
	return _find_node_graph_index(node_id) >= 0


func get_node_count() -> int:
	return _node_graph.size()


func get_current_node_family() -> String:
	return get_node_family(current_node_id)


func get_stage_key_node_id() -> int:
	return _find_first_node_id_by_family("key")


func get_boss_node_id() -> int:
	return _find_first_node_id_by_family("boss")


func get_active_template_id() -> String:
	return _active_template_id


func get_active_topology_blueprint_id() -> String:
	return _active_topology_blueprint_id


func get_node_family(node_id: int) -> String:
	var node_data: Dictionary = _get_node_data(node_id)
	return String(node_data.get("node_family", ""))


func get_node_state(node_id: int) -> String:
	var node_data: Dictionary = _get_node_data(node_id)
	return String(node_data.get("node_state", NODE_STATE_UNDISCOVERED))


func get_adjacent_node_ids(node_id: int = current_node_id) -> PackedInt32Array:
	var node_data: Dictionary = _get_node_data(node_id)
	var adjacent_variant: Variant = node_data.get("adjacent_node_ids", PackedInt32Array())
	if typeof(adjacent_variant) == TYPE_PACKED_INT32_ARRAY:
		return adjacent_variant
	if typeof(adjacent_variant) == TYPE_ARRAY:
		var adjacent_ids: PackedInt32Array = PackedInt32Array()
		for value in adjacent_variant:
			adjacent_ids.append(int(value))
		return adjacent_ids
	return PackedInt32Array()


func get_discovered_adjacent_node_ids(node_id: int = current_node_id) -> PackedInt32Array:
	var discovered_ids: PackedInt32Array = PackedInt32Array()
	for adjacent_node_id in get_adjacent_node_ids(node_id):
		if is_node_discovered(adjacent_node_id):
			discovered_ids.append(adjacent_node_id)
	return discovered_ids


func get_frontier_fog_count() -> int:
	var frontier_count: int = 0
	for node_data in _node_graph:
		if String(node_data.get("node_state", NODE_STATE_UNDISCOVERED)) != NODE_STATE_UNDISCOVERED:
			continue
		var adjacent_variant: Variant = node_data.get("adjacent_node_ids", [])
		var adjacent_ids: PackedInt32Array = _coerce_adjacent_ids(adjacent_variant)
		for adjacent_node_id in adjacent_ids:
			if is_node_discovered(adjacent_node_id):
				frontier_count += 1
				break
	return frontier_count


func get_discovered_node_count() -> int:
	var discovered_count: int = 0
	for node_data in _node_graph:
		if String(node_data.get("node_state", NODE_STATE_UNDISCOVERED)) != NODE_STATE_UNDISCOVERED:
			discovered_count += 1
	return discovered_count


func get_resolved_node_count() -> int:
	var resolved_count: int = 0
	for node_data in _node_graph:
		if String(node_data.get("node_state", NODE_STATE_UNDISCOVERED)) == NODE_STATE_RESOLVED:
			resolved_count += 1
	return resolved_count


func is_stage_key_resolved() -> bool:
	return stage_key_resolved


func is_boss_gate_unlocked() -> bool:
	return stage_key_resolved


func is_node_discovered(node_id: int) -> bool:
	return get_node_state(node_id) != NODE_STATE_UNDISCOVERED


func is_node_locked(node_id: int) -> bool:
	return get_node_state(node_id) == NODE_STATE_LOCKED


func is_node_resolved(node_id: int) -> bool:
	return get_node_state(node_id) == NODE_STATE_RESOLVED


func is_support_node(node_id: int) -> bool:
	return _is_support_node_family(get_node_family(node_id))


func is_hamlet_node(node_id: int) -> bool:
	return get_node_family(node_id) == NODE_FAMILY_HAMLET


func is_side_mission_node(node_id: int) -> bool:
	return is_hamlet_node(node_id)


func get_hamlet_personality(node_id: int) -> String:
	if not has_node(node_id) or not is_hamlet_node(node_id):
		return ""
	return SupportInteractionState.resolve_hamlet_personality_for_stage(_generation_stage_index)


func can_move_to_node(node_id: int) -> bool:
	if not has_node(node_id):
		return false
	if not get_adjacent_node_ids().has(node_id):
		return false
	var node_state: String = get_node_state(node_id)
	return node_state != NODE_STATE_UNDISCOVERED and node_state != NODE_STATE_LOCKED


func can_trigger_roadside_encounter() -> bool:
	return roadside_encounters_this_stage < MAX_ROADSIDE_ENCOUNTERS_PER_STAGE


func consume_roadside_encounter_slot() -> bool:
	if not can_trigger_roadside_encounter():
		return false
	roadside_encounters_this_stage += 1
	return true


func get_roadside_encounters_this_stage() -> int:
	return roadside_encounters_this_stage


func node_requires_resolution(node_id: int) -> bool:
	if not has_node(node_id):
		return false
	var node_family: String = get_node_family(node_id)
	if node_family == "start":
		return false
	var node_state: String = get_node_state(node_id)
	if node_family == NODE_FAMILY_HAMLET:
		if node_state in [NODE_STATE_UNDISCOVERED, NODE_STATE_LOCKED]:
			return false
		var mission_status: String = String(get_side_quest_node_runtime_state(node_id).get("mission_status", SIDE_MISSION_STATUS_OFFERED))
		return mission_status != SIDE_MISSION_STATUS_CLAIMED
	if _is_support_node_family(node_family):
		return node_state == NODE_STATE_DISCOVERED
	return node_state == NODE_STATE_DISCOVERED


func move_to_node(node_id: int) -> void:
	if not has_node(node_id):
		return
	current_node_id = node_id
	if get_node_state(node_id) == NODE_STATE_UNDISCOVERED:
		_set_node_state(node_id, NODE_STATE_DISCOVERED)
	_reveal_adjacent_nodes(node_id)


func resolve_stage_key() -> void:
	stage_key_resolved = true
	_sync_boss_gate_state()


func mark_node_resolved(node_id: int) -> void:
	if not has_node(node_id):
		return
	if get_node_state(node_id) == NODE_STATE_LOCKED:
		return
	_set_node_state(node_id, NODE_STATE_RESOLVED)


func has_pending_node() -> bool:
	return pending_node_id != NO_PENDING_NODE_ID and has_node(pending_node_id)


func clear_pending_node() -> void:
	pending_node_id = NO_PENDING_NODE_ID
	pending_node_type = ""


func set_pending_node(node_id: int) -> void:
	if not has_node(node_id):
		clear_pending_node()
		return
	pending_node_id = node_id
	pending_node_type = get_node_family(node_id)


func consume_pending_node_data() -> Dictionary:
	var pending_data: Dictionary = {
		"pending_node_id": pending_node_id,
		"pending_node_type": pending_node_type,
	}
	clear_pending_node()
	return pending_data


func find_adjacent_node_id(node_reference: Variant) -> int:
	if typeof(node_reference) == TYPE_INT:
		var target_node_id: int = int(node_reference)
		return target_node_id if get_adjacent_node_ids().has(target_node_id) else NO_PENDING_NODE_ID

	var reference_text: String = String(node_reference)
	if reference_text.is_valid_int():
		var parsed_node_id: int = int(reference_text)
		return parsed_node_id if get_adjacent_node_ids().has(parsed_node_id) else NO_PENDING_NODE_ID

	for adjacent_node_id in get_adjacent_node_ids():
		if get_node_family(adjacent_node_id) == reference_text:
			return adjacent_node_id
	return NO_PENDING_NODE_ID


func build_adjacent_node_snapshots() -> Array[Dictionary]:
	var node_snapshots: Array[Dictionary] = []
	for node_id in get_adjacent_node_ids():
		node_snapshots.append(_build_node_snapshot(node_id))
	return node_snapshots


func build_node_snapshots() -> Array[Dictionary]:
	var node_snapshots: Array[Dictionary] = []
	for node_data in _node_graph:
		node_snapshots.append(_build_node_snapshot(int(node_data.get("node_id", NO_PENDING_NODE_ID))))
	return node_snapshots


func build_realized_graph_snapshots() -> Array[Dictionary]:
	return _graph_codec.build_realized_graph_save_payload(_node_graph, NO_PENDING_NODE_ID, NODE_STATE_UNDISCOVERED)


func build_layout_graph_snapshots() -> Array[Dictionary]:
	var adjacency_by_node_id: Dictionary = _build_adjacency_lookup_from_graph(_node_graph)
	var depth_by_node_id: Dictionary = _build_scatter_depth_map(adjacency_by_node_id)
	var route_role_by_node_id: Dictionary = _build_layout_route_role_by_node_id()
	var sector_by_node_id: Dictionary = _build_layout_sector_by_node_id(adjacency_by_node_id, depth_by_node_id, route_role_by_node_id)
	var orientation_profile_id: String = _build_layout_orientation_profile_id()
	var topology_blueprint_id: String = _active_topology_blueprint_id
	var layout_snapshots: Array[Dictionary] = []
	for node_data in _node_graph:
		var node_id: int = int(node_data.get("node_id", NO_PENDING_NODE_ID))
		layout_snapshots.append({
			"node_id": node_id,
			"node_family": String(node_data.get("node_family", "")),
			"node_state": String(node_data.get("node_state", NODE_STATE_UNDISCOVERED)),
			"adjacent_node_ids": PackedInt32Array(_coerce_adjacent_ids(node_data.get("adjacent_node_ids", PackedInt32Array()))),
			"sector_id": String(sector_by_node_id.get(node_id, LAYOUT_SECTOR_CENTER_ANCHOR)),
			"route_role": String(route_role_by_node_id.get(node_id, LAYOUT_ROUTE_ROLE_BRANCH_POCKET)),
			"orientation_profile_id": orientation_profile_id,
			"topology_blueprint_id": topology_blueprint_id,
		})
	return layout_snapshots


func get_support_node_runtime_state(node_id: int) -> Dictionary:
	if not has_node(node_id) or not is_support_node(node_id):
		return {}
	if _support_node_states.has(node_id):
		return (_support_node_states[node_id] as Dictionary).duplicate(true)
	return MapRuntimeLocalStateHelperScript.build_default_support_node_state(get_node_family(node_id))


func get_side_mission_node_runtime_state(node_id: int) -> Dictionary:
	return get_side_quest_node_runtime_state(node_id)


func get_side_quest_node_runtime_state(node_id: int) -> Dictionary:
	if not has_node(node_id) or not is_hamlet_node(node_id):
		return {}
	if _side_mission_node_states.has(node_id):
		return (_side_mission_node_states[node_id] as Dictionary).duplicate(true)
	return MapRuntimeLocalStateHelperScript.build_default_side_quest_node_state(
		get_node_family(node_id),
		_side_quest_state_helper_config()
	)


func save_support_node_runtime_state(node_id: int, support_node_state: Dictionary) -> void:
	if not has_node(node_id) or not is_support_node(node_id):
		return

	var normalized_state: Dictionary = MapRuntimeLocalStateHelperScript.normalize_support_node_state(
		get_node_family(node_id),
		support_node_state
	)
	if not MapRuntimeLocalStateHelperScript.support_state_should_persist(normalized_state):
		_support_node_states.erase(node_id)
		return
	_support_node_states[node_id] = normalized_state


func save_side_mission_node_runtime_state(node_id: int, side_mission_state: Dictionary) -> void:
	save_side_quest_node_runtime_state(node_id, side_mission_state)


func save_side_quest_node_runtime_state(node_id: int, side_quest_state: Dictionary) -> void:
	if not has_node(node_id) or not is_hamlet_node(node_id):
		return

	var normalized_state: Dictionary = MapRuntimeLocalStateHelperScript.normalize_side_quest_node_state(
		side_quest_state,
		get_node_family(node_id),
		_build_node_family_lookup(),
		_side_quest_state_helper_config()
	)
	if not MapRuntimeLocalStateHelperScript.side_quest_state_should_persist(
		normalized_state,
		_side_quest_state_helper_config()
	):
		_side_mission_node_states.erase(node_id)
		return
	_side_mission_node_states[node_id] = normalized_state


func list_eligible_side_mission_target_node_ids(excluded_node_id: int = NO_PENDING_NODE_ID) -> Array[int]:
	return list_eligible_side_quest_target_node_ids(excluded_node_id)


func list_eligible_side_quest_target_node_ids(
	excluded_node_id: int = NO_PENDING_NODE_ID,
	target_families: PackedStringArray = PackedStringArray()
) -> Array[int]:
	var target_node_ids: Array[int] = []
	for node_data in _node_graph:
		var node_id: int = int(node_data.get("node_id", NO_PENDING_NODE_ID))
		if node_id == excluded_node_id:
			continue
		var node_family: String = get_node_family(node_id)
		if not target_families.is_empty() and not target_families.has(node_family):
			continue
		if target_families.is_empty() and node_family != "combat":
			continue
		if String(node_data.get("node_state", NODE_STATE_UNDISCOVERED)) == NODE_STATE_RESOLVED:
			continue
		target_node_ids.append(node_id)
	return target_node_ids


func reveal_node(node_id: int) -> void:
	if not has_node(node_id):
		return
	if get_node_state(node_id) != NODE_STATE_UNDISCOVERED:
		return
	var node_family: String = get_node_family(node_id)
	if node_family == "boss" and not stage_key_resolved:
		_set_node_state(node_id, NODE_STATE_LOCKED)
		return
	_set_node_state(node_id, NODE_STATE_DISCOVERED)


func get_side_mission_target_enemy_definition_id(node_id: int) -> String:
	return get_side_quest_target_enemy_definition_id(node_id)


func get_side_quest_target_enemy_definition_id(node_id: int) -> String:
	return MapRuntimeLocalStateHelperScript.build_target_enemy_definition_id(
		_side_mission_node_states,
		node_id,
		_side_quest_state_helper_config()
	)


func mark_side_mission_target_completed(target_node_id: int) -> Dictionary:
	return mark_side_quest_target_completed(target_node_id)


func mark_side_quest_target_completed(target_node_id: int) -> Dictionary:
	return MapRuntimeLocalStateHelperScript.mark_side_quest_target_completed(
		_side_mission_node_states,
		target_node_id,
		_build_node_family_lookup(),
		_side_quest_state_helper_config()
	)


func build_side_mission_highlight_snapshot() -> Dictionary:
	return build_side_quest_highlight_snapshot()


func build_side_quest_highlight_snapshot() -> Dictionary:
	return MapRuntimeLocalStateHelperScript.build_side_quest_highlight_snapshot(
		_side_mission_node_states,
		_side_quest_state_helper_config()
	)


func get_active_side_quest_by_target_node_id(target_node_id: int) -> Dictionary:
	return MapRuntimeLocalStateHelperScript.active_side_quest_by_target_node_id(
		_side_mission_node_states,
		target_node_id,
		_side_quest_state_helper_config()
	)


func build_family_budget_slot_snapshot() -> Dictionary:
	return _family_budget_slot_reservations.duplicate(true)


func to_save_dict() -> Dictionary:
	return {
		SAVE_KEY_ACTIVE_TEMPLATE_ID: _active_template_id,
		"current_node_index": current_node_id,
		"current_node_id": current_node_id,
		"stage_key_resolved": stage_key_resolved,
		"boss_gate_unlocked": is_boss_gate_unlocked(),
		SAVE_KEY_ROADSIDE_ENCOUNTERS_THIS_STAGE: roadside_encounters_this_stage,
		SAVE_KEY_REALIZED_GRAPH: _graph_codec.build_realized_graph_save_payload(_node_graph, NO_PENDING_NODE_ID, NODE_STATE_UNDISCOVERED),
		"map_node_states": _graph_codec.build_node_state_save_payload(_node_graph, NO_PENDING_NODE_ID, NODE_STATE_UNDISCOVERED),
		"support_node_states": _graph_codec.build_support_node_state_save_payload(_support_node_states),
		SAVE_KEY_SIDE_MISSION_NODE_STATES: _graph_codec.build_side_mission_node_state_save_payload(_side_mission_node_states),
	}


func load_from_save_dict(save_data: Dictionary, stage_index: int = 1) -> void:
	_reset_runtime_state()
	_generation_stage_index = max(1, stage_index)
	_active_topology_blueprint_id = ""
	var restored_template_id: String = String(save_data.get(SAVE_KEY_ACTIVE_TEMPLATE_ID, ""))
	var restored_realized_graph: Array[Dictionary] = _graph_codec.extract_realized_graph_array(save_data.get(SAVE_KEY_REALIZED_GRAPH, []))
	if not restored_realized_graph.is_empty():
		_active_template_id = restored_template_id if not restored_template_id.is_empty() else _resolve_scaffold_id_for_stage(_generation_stage_index)
		_node_graph = _graph_codec.build_graph_from_realized_payload(
			restored_realized_graph,
			NO_PENDING_NODE_ID,
			NODE_STATE_UNDISCOVERED,
			LEGACY_NODE_FAMILY_SIDE_MISSION,
			NODE_FAMILY_HAMLET
		)
	else:
		_active_template_id = _resolve_legacy_template_id_for_stage(_generation_stage_index)
		_node_graph = _build_legacy_fixed_graph(_active_template_id)

	var restored_current_node_id: int = int(save_data.get("current_node_id", save_data.get("current_node_index", DEFAULT_NODE_INDEX)))
	if has_node(restored_current_node_id):
		current_node_id = restored_current_node_id

	var restored_pending_node_id: int = int(save_data.get("pending_node_id", NO_PENDING_NODE_ID))
	pending_node_id = restored_pending_node_id if has_node(restored_pending_node_id) else NO_PENDING_NODE_ID
	pending_node_type = String(save_data.get("pending_node_type", get_node_family(pending_node_id) if pending_node_id >= 0 else ""))
	stage_key_resolved = bool(save_data.get("stage_key_resolved", save_data.get("boss_gate_unlocked", false)))
	roadside_encounters_this_stage = max(0, int(save_data.get(SAVE_KEY_ROADSIDE_ENCOUNTERS_THIS_STAGE, 0)))

	var saved_node_states_variant: Variant = save_data.get("map_node_states", [])
	if restored_realized_graph.is_empty() and typeof(saved_node_states_variant) == TYPE_ARRAY:
		for entry_variant in saved_node_states_variant:
			if typeof(entry_variant) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = entry_variant
			var node_id: int = int(entry.get("node_id", NO_PENDING_NODE_ID))
			var node_state: String = String(entry.get("node_state", NODE_STATE_UNDISCOVERED))
			if not has_node(node_id):
				continue
			if not _is_valid_node_state(node_state):
				continue
			_set_node_state(node_id, node_state)

	var saved_support_states_variant: Variant = save_data.get("support_node_states", [])
	var node_family_by_id: Dictionary = _build_node_family_lookup()
	_support_node_states = MapRuntimeLocalStateHelperScript.restore_support_node_states(
		saved_support_states_variant,
		node_family_by_id,
		SUPPORT_NODE_FAMILIES,
		NO_PENDING_NODE_ID
	)

	var saved_side_mission_states_variant: Variant = save_data.get(SAVE_KEY_SIDE_MISSION_NODE_STATES, [])
	_side_mission_node_states = MapRuntimeLocalStateHelperScript.restore_side_quest_node_states(
		saved_side_mission_states_variant,
		node_family_by_id,
		NODE_FAMILY_HAMLET,
		_side_quest_state_helper_config()
	)

	_sync_boss_gate_state()
	_rebuild_family_budget_slot_reservations_from_graph()


func _build_legacy_fixed_graph(template_id: String) -> Array[Dictionary]:
	var graph: Array[Dictionary] = []
	for template_node in _load_graph_template_nodes(template_id):
		graph.append({
			"node_id": int(template_node.get("node_id", NO_PENDING_NODE_ID)),
			"node_family": String(template_node.get("node_family", "")),
			"node_state": NODE_STATE_UNDISCOVERED,
			"adjacent_node_ids": _coerce_adjacent_ids(template_node.get("adjacent_node_ids", [])),
		})
	return graph


func _load_graph_template_nodes(template_id: String) -> Array[Dictionary]:
	var loader: ContentLoader = ContentLoaderScript.new()
	var template_definition: Dictionary = loader.load_definition(MAP_TEMPLATE_FAMILY, template_id)
	if template_definition.is_empty() and template_id != DEFAULT_SCAFFOLD_TEMPLATE_ID:
		template_definition = loader.load_definition(MAP_TEMPLATE_FAMILY, DEFAULT_SCAFFOLD_TEMPLATE_ID)
	var rules: Dictionary = template_definition.get("rules", {})
	return _extract_template_node_array(rules.get("nodes", []))


func _resolve_scaffold_id_for_stage(stage_index: int) -> String:
	if STAGE_SCAFFOLD_TEMPLATE_IDS.is_empty():
		return DEFAULT_SCAFFOLD_TEMPLATE_ID
	var stage_offset: int = max(0, stage_index - 1)
	return String(STAGE_SCAFFOLD_TEMPLATE_IDS[stage_offset % STAGE_SCAFFOLD_TEMPLATE_IDS.size()])


func _resolve_legacy_template_id_for_stage(stage_index: int) -> String:
	if LEGACY_STAGE_TEMPLATE_IDS.is_empty():
		return ""
	var stage_offset: int = max(0, stage_index - 1)
	return String(LEGACY_STAGE_TEMPLATE_IDS[stage_offset % LEGACY_STAGE_TEMPLATE_IDS.size()])


func _extract_template_node_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result

	for entry in value:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		result.append((entry as Dictionary).duplicate(true))
	return result


func _build_node_snapshot(node_id: int) -> Dictionary:
	var snapshot: Dictionary = {
		"node_id": node_id,
		"node_family": get_node_family(node_id),
		"node_state": get_node_state(node_id),
	}
	if is_hamlet_node(node_id):
		snapshot["hamlet_personality"] = get_hamlet_personality(node_id)
	return snapshot


func _build_layout_route_role_by_node_id() -> Dictionary:
	var role_by_node_id: Dictionary = {
		DEFAULT_NODE_INDEX: LAYOUT_ROUTE_ROLE_CENTER_START,
	}
	var role_name_to_layout_role: Dictionary = {
		SCATTER_ROLE_OPENING_COMBAT: LAYOUT_ROUTE_ROLE_OPENING_COMBAT,
		SCATTER_ROLE_OPENING_REWARD: LAYOUT_ROUTE_ROLE_OPENING_REWARD,
		SCATTER_ROLE_OPENING_SUPPORT: LAYOUT_ROUTE_ROLE_OPENING_SUPPORT,
		SCATTER_ROLE_LATE_SUPPORT: LAYOUT_ROUTE_ROLE_LATE_SUPPORT,
		SCATTER_ROLE_EVENT: LAYOUT_ROUTE_ROLE_EVENT_DETOUR,
		SCATTER_ROLE_SIDE_MISSION: LAYOUT_ROUTE_ROLE_HAMLET_DETOUR,
		SCATTER_ROLE_KEY: LAYOUT_ROUTE_ROLE_KEY_PRESSURE,
		SCATTER_ROLE_BOSS: LAYOUT_ROUTE_ROLE_BOSS_PRESSURE,
	}
	for role_name_variant in role_name_to_layout_role.keys():
		var role_name: String = String(role_name_variant)
		var node_id: int = int(_family_budget_slot_reservations.get(role_name, NO_PENDING_NODE_ID))
		if node_id == NO_PENDING_NODE_ID:
			continue
		role_by_node_id[node_id] = String(role_name_to_layout_role.get(role_name, LAYOUT_ROUTE_ROLE_BRANCH_POCKET))

	for node_data in _node_graph:
		var node_id: int = int(node_data.get("node_id", NO_PENDING_NODE_ID))
		if node_id == NO_PENDING_NODE_ID or role_by_node_id.has(node_id):
			continue
		var node_family: String = String(node_data.get("node_family", ""))
		role_by_node_id[node_id] = _fallback_layout_route_role_for_family(node_family)
	return role_by_node_id


func _fallback_layout_route_role_for_family(node_family: String) -> String:
	match node_family:
		"start":
			return LAYOUT_ROUTE_ROLE_CENTER_START
		"combat":
			return LAYOUT_ROUTE_ROLE_COMBAT_ROUTE
		"event":
			return LAYOUT_ROUTE_ROLE_EVENT_DETOUR
		NODE_FAMILY_HAMLET:
			return LAYOUT_ROUTE_ROLE_HAMLET_DETOUR
		"key":
			return LAYOUT_ROUTE_ROLE_KEY_PRESSURE
		"boss":
			return LAYOUT_ROUTE_ROLE_BOSS_PRESSURE
		"reward":
			return LAYOUT_ROUTE_ROLE_OPENING_REWARD
		_:
			if _is_support_node_family(node_family):
				return LAYOUT_ROUTE_ROLE_LATE_SUPPORT
	return LAYOUT_ROUTE_ROLE_BRANCH_POCKET


func _build_layout_sector_by_node_id(
	adjacency_by_node_id: Dictionary,
	depth_by_node_id: Dictionary,
	route_role_by_node_id: Dictionary
) -> Dictionary:
	var sector_by_node_id: Dictionary = {}
	var sorted_node_ids: Array[int] = _sorted_scatter_node_ids(adjacency_by_node_id.keys())
	var parent_by_node_id: Dictionary = _build_scatter_parent_map(adjacency_by_node_id, depth_by_node_id, sorted_node_ids)
	var branch_root_by_node_id: Dictionary = {}
	if not parent_by_node_id.is_empty():
		branch_root_by_node_id = _build_scatter_branch_root_map(parent_by_node_id, sorted_node_ids)
	var lane_by_branch_root: Dictionary = _build_layout_lane_index_by_branch_root(adjacency_by_node_id)
	for node_data in _node_graph:
		var node_id: int = int(node_data.get("node_id", NO_PENDING_NODE_ID))
		var node_family: String = String(node_data.get("node_family", ""))
		var depth: int = int(depth_by_node_id.get(node_id, -1))
		var branch_root_node_id: int = int(branch_root_by_node_id.get(node_id, node_id))
		var lane_index: int = int(lane_by_branch_root.get(branch_root_node_id, -1))
		var route_role: String = String(route_role_by_node_id.get(node_id, _fallback_layout_route_role_for_family(node_family)))
		sector_by_node_id[node_id] = _resolve_layout_sector_id(node_id, node_family, route_role, depth, lane_index)
	return sector_by_node_id


func _build_layout_lane_index_by_branch_root(adjacency_by_node_id: Dictionary) -> Dictionary:
	var branch_root_ids: Array[int] = []
	for adjacent_node_id in _coerce_adjacent_ids(adjacency_by_node_id.get(DEFAULT_NODE_INDEX, PackedInt32Array())):
		var resolved_adjacent_node_id: int = int(adjacent_node_id)
		if _coerce_adjacent_ids(adjacency_by_node_id.get(resolved_adjacent_node_id, PackedInt32Array())).size() <= 1:
			continue
		branch_root_ids.append(resolved_adjacent_node_id)
	if branch_root_ids.is_empty():
		for adjacent_node_id in _coerce_adjacent_ids(adjacency_by_node_id.get(DEFAULT_NODE_INDEX, PackedInt32Array())):
			branch_root_ids.append(int(adjacent_node_id))
	branch_root_ids.sort()

	var lane_by_branch_root: Dictionary = {}
	for index in range(branch_root_ids.size()):
		var branch_root_id: int = branch_root_ids[index]
		lane_by_branch_root[branch_root_id] = min(index, SCATTER_START_BRANCH_COUNT - 1)
	return lane_by_branch_root


func _resolve_layout_sector_id(
	node_id: int,
	node_family: String,
	route_role: String,
	depth: int,
	lane_index: int
) -> String:
	if node_id == DEFAULT_NODE_INDEX:
		return LAYOUT_SECTOR_CENTER_ANCHOR
	if lane_index < 0:
		return LAYOUT_SECTOR_SOUTH_CENTER
	if _is_layout_pressure_route(node_family, route_role):
		return _layout_outer_sector_for_lane(lane_index)
	if route_role == LAYOUT_ROUTE_ROLE_EVENT_DETOUR or route_role == LAYOUT_ROUTE_ROLE_HAMLET_DETOUR:
		return _layout_south_sector_for_lane(lane_index)
	if _is_support_node_family(node_family):
		return _layout_mid_sector_for_lane(lane_index) if depth <= 1 else _layout_south_sector_for_lane(lane_index)
	if depth <= 1:
		return _layout_north_sector_for_lane(lane_index)
	if depth == 2:
		return _layout_mid_sector_for_lane(lane_index)
	if depth == 3:
		return _layout_south_sector_for_lane(lane_index)
	return _layout_outer_sector_for_lane(lane_index)


func _is_layout_pressure_route(node_family: String, route_role: String) -> bool:
	return node_family == "key" or node_family == "boss" or route_role == LAYOUT_ROUTE_ROLE_KEY_PRESSURE or route_role == LAYOUT_ROUTE_ROLE_BOSS_PRESSURE


func _layout_north_sector_for_lane(lane_index: int) -> String:
	match lane_index:
		0:
			return LAYOUT_SECTOR_NORTH_WEST
		2:
			return LAYOUT_SECTOR_NORTH_EAST
	return LAYOUT_SECTOR_NORTH_CENTER


func _layout_mid_sector_for_lane(lane_index: int) -> String:
	match lane_index:
		0:
			return LAYOUT_SECTOR_MID_LEFT
		2:
			return LAYOUT_SECTOR_MID_RIGHT
	return LAYOUT_SECTOR_NORTH_CENTER


func _layout_south_sector_for_lane(lane_index: int) -> String:
	match lane_index:
		0:
			return LAYOUT_SECTOR_SOUTH_WEST
		2:
			return LAYOUT_SECTOR_SOUTH_EAST
	return LAYOUT_SECTOR_SOUTH_CENTER


func _layout_outer_sector_for_lane(lane_index: int) -> String:
	match lane_index:
		0:
			return LAYOUT_SECTOR_OUTER_LATE_WEST
		2:
			return LAYOUT_SECTOR_OUTER_LATE_EAST
	return LAYOUT_SECTOR_NORTH_CENTER


func _build_layout_orientation_profile_id() -> String:
	if _active_topology_blueprint_id.ends_with(":switchback") or _active_topology_blueprint_id.ends_with(":return"):
		return LAYOUT_ORIENTATION_PROFILE_WEST_WEIGHTED
	if _active_topology_blueprint_id.ends_with(":lane") or _active_topology_blueprint_id.ends_with(":crossback"):
		return LAYOUT_ORIENTATION_PROFILE_EAST_WEIGHTED
	return LAYOUT_ORIENTATION_PROFILE_BALANCED


func _reveal_adjacent_nodes(node_id: int) -> void:
	for adjacent_node_id in get_adjacent_node_ids(node_id):
		if get_node_state(adjacent_node_id) != NODE_STATE_UNDISCOVERED:
			continue
		var node_family: String = get_node_family(adjacent_node_id)
		if node_family == "boss" and not stage_key_resolved:
			_set_node_state(adjacent_node_id, NODE_STATE_LOCKED)
		else:
			_set_node_state(adjacent_node_id, NODE_STATE_DISCOVERED)


func _find_node_graph_index(node_id: int) -> int:
	for index in range(_node_graph.size()):
		if int(_node_graph[index].get("node_id", NO_PENDING_NODE_ID)) == node_id:
			return index
	return -1


func _get_node_data(node_id: int) -> Dictionary:
	var node_index: int = _find_node_graph_index(node_id)
	if node_index < 0:
		return {}
	return _node_graph[node_index]


func _find_first_node_id_by_family(node_family: String) -> int:
	for node_data in _node_graph:
		if String(node_data.get("node_family", "")) == node_family:
			return int(node_data.get("node_id", NO_PENDING_NODE_ID))
	return NO_PENDING_NODE_ID


func _set_node_state(node_id: int, node_state: String) -> void:
	var node_index: int = _find_node_graph_index(node_id)
	if node_index < 0 or not _is_valid_node_state(node_state):
		return
	var updated_node: Dictionary = _node_graph[node_index].duplicate(true)
	updated_node["node_state"] = node_state
	_node_graph[node_index] = updated_node


func _is_valid_node_state(node_state: String) -> bool:
	return node_state in [
		NODE_STATE_UNDISCOVERED,
		NODE_STATE_DISCOVERED,
		NODE_STATE_RESOLVED,
		NODE_STATE_LOCKED,
	]


func _is_support_node_family(node_family: String) -> bool:
	return SUPPORT_NODE_FAMILIES.has(node_family)


func _build_node_family_lookup() -> Dictionary:
	return MapRuntimeLocalStateHelperScript.build_node_family_lookup(_node_graph, NO_PENDING_NODE_ID)


func _side_quest_state_helper_config() -> Dictionary:
	return {
		"no_pending_node_id": NO_PENDING_NODE_ID,
		"default_definition_id": SIDE_MISSION_DEFAULT_DEFINITION_ID,
		"default_mission_type": SIDE_QUEST_MISSION_TYPE_HUNT_MARKED_ENEMY,
		"offered_status": SIDE_MISSION_STATUS_OFFERED,
		"accepted_status": SIDE_MISSION_STATUS_ACCEPTED,
		"completed_status": SIDE_MISSION_STATUS_COMPLETED,
		"claimed_status": SIDE_MISSION_STATUS_CLAIMED,
		"hunt_marked_enemy_type": SIDE_QUEST_MISSION_TYPE_HUNT_MARKED_ENEMY,
		"deliver_supplies_type": SIDE_QUEST_MISSION_TYPE_DELIVER_SUPPLIES,
		"rescue_missing_scout_type": SIDE_QUEST_MISSION_TYPE_RESCUE_MISSING_SCOUT,
		"bring_proof_type": SIDE_QUEST_MISSION_TYPE_BRING_PROOF,
	}


func _sync_boss_gate_state() -> void:
	var boss_node_id: int = get_boss_node_id()
	if boss_node_id == NO_PENDING_NODE_ID:
		return

	var boss_node_state: String = get_node_state(boss_node_id)
	if stage_key_resolved:
		if boss_node_state == NODE_STATE_LOCKED:
			_set_node_state(boss_node_id, NODE_STATE_DISCOVERED)
		return

	if boss_node_state == NODE_STATE_DISCOVERED:
		_set_node_state(boss_node_id, NODE_STATE_LOCKED)


func _coerce_adjacent_ids(adjacent_variant: Variant) -> PackedInt32Array:
	return MapScatterGraphToolsScript.coerce_adjacent_ids(adjacent_variant)


func _reset_runtime_state() -> void:
	current_node_id = DEFAULT_NODE_INDEX
	pending_node_id = NO_PENDING_NODE_ID
	pending_node_type = ""
	stage_key_resolved = false
	roadside_encounters_this_stage = 0
	_node_graph = []
	_support_node_states = {}
	_side_mission_node_states = {}
	_active_topology_blueprint_id = ""
	_family_budget_slot_reservations = {}


func _resolve_generation_seed(generation_seed: int) -> int:
	if generation_seed >= 0:
		return _normalize_generation_seed(generation_seed)
	return _normalize_generation_seed(_generation_seed)


func _normalize_generation_seed(generation_seed: int) -> int:
	var normalized_seed: int = abs(generation_seed)
	if normalized_seed == 0:
		return DEFAULT_GENERATION_SEED
	return normalized_seed


func _build_scaffold_graph(template_id: String, stage_index: int) -> Array[Dictionary]:
	for attempt_index in range(SCATTER_ATTEMPT_LIMIT):
		var topology: Dictionary = _build_controlled_scatter_topology(template_id, attempt_index)
		var node_adjacency: Dictionary = topology.get("node_adjacency", {})
		var role_targets: Dictionary = topology.get("role_targets", {})
		if not _validate_controlled_scatter_topology(node_adjacency, role_targets):
			continue
		var family_assignments: Dictionary = _build_controlled_scatter_family_assignments(node_adjacency, role_targets, stage_index)
		var graph: Array[Dictionary] = _build_scatter_graph_payload(node_adjacency, family_assignments)
		if _validate_scatter_runtime_graph(graph):
			_active_topology_blueprint_id = String(topology.get("blueprint_id", ""))
			_family_budget_slot_reservations = _build_family_budget_slot_reservations_from_graph(graph)
			return graph
		if _validate_scatter_runtime_graph_min_floor(graph):
			_active_topology_blueprint_id = String(topology.get("blueprint_id", ""))
			_family_budget_slot_reservations = _build_family_budget_slot_reservations_from_graph(graph)
			return graph
	return _build_scatter_graph_fallback(template_id, stage_index)


func _build_scatter_graph_fallback(template_id: String, stage_index: int) -> Array[Dictionary]:
	for fallback_template_id in [template_id, DEFAULT_SCAFFOLD_TEMPLATE_ID]:
		for attempt_offset in range(SCATTER_ATTEMPT_LIMIT):
			var topology: Dictionary = _build_controlled_scatter_topology(fallback_template_id, attempt_offset + SCATTER_ATTEMPT_LIMIT)
			var node_adjacency: Dictionary = topology.get("node_adjacency", {})
			var role_targets: Dictionary = topology.get("role_targets", {})
			if not _validate_controlled_scatter_topology(node_adjacency, role_targets):
				continue
			var assignments: Dictionary = _build_controlled_scatter_family_assignments(node_adjacency, role_targets, stage_index)
			var fallback_graph: Array[Dictionary] = _build_scatter_graph_payload(node_adjacency, assignments)
			if _validate_scatter_runtime_graph(fallback_graph):
				_active_topology_blueprint_id = String(topology.get("blueprint_id", ""))
				_family_budget_slot_reservations = _build_family_budget_slot_reservations_from_graph(fallback_graph)
				return fallback_graph
			if _validate_scatter_runtime_graph_min_floor(fallback_graph):
				_active_topology_blueprint_id = String(topology.get("blueprint_id", ""))
				_family_budget_slot_reservations = _build_family_budget_slot_reservations_from_graph(fallback_graph)
				return fallback_graph
	return []


func _validate_scatter_runtime_graph_min_floor(graph: Array[Dictionary], allow_reconnect_shortfall: bool = false) -> bool:
	if graph.size() != SCATTER_NODE_COUNT:
		return false
	if not _is_graph_connected_scatter(graph):
		return false

	var family_counts: Dictionary = {}
	var degree_counts: Dictionary = {}
	var adjacency_by_node_id: Dictionary = {}
	var key_node_id: int = NO_PENDING_NODE_ID
	var boss_node_id: int = NO_PENDING_NODE_ID
	var start_node_id: int = NO_PENDING_NODE_ID

	for entry_variant in graph:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return false
		var entry: Dictionary = entry_variant
		var node_id: int = int(entry.get("node_id", NO_PENDING_NODE_ID))
		var node_family: String = String(entry.get("node_family", ""))
		family_counts[node_family] = int(family_counts.get(node_family, 0)) + 1
		if node_family == "":
			return false
		var adjacent_ids: PackedInt32Array = _coerce_adjacent_ids(entry.get("adjacent_node_ids", []))
		if adjacent_ids.size() < 1:
			return false
		if adjacent_ids.size() > SCATTER_MAX_NODE_DEGREE:
			return false

		var seen_adjacent_ids: Dictionary = {}
		for adjacent_node_id in adjacent_ids:
			if adjacent_node_id < 0 or adjacent_node_id == node_id or seen_adjacent_ids.has(adjacent_node_id):
				return false
			seen_adjacent_ids[adjacent_node_id] = true
		adjacency_by_node_id[node_id] = adjacent_ids

		if node_family == "start":
			start_node_id = node_id
		elif node_family == "key":
			key_node_id = node_id
		elif node_family == "boss":
			boss_node_id = node_id

		var degree: int = adjacent_ids.size()
		degree_counts[degree] = int(degree_counts.get(degree, 0)) + 1

	for node_id in adjacency_by_node_id.keys():
		for adjacent_node_id in adjacency_by_node_id.get(node_id, PackedInt32Array()):
			if not adjacency_by_node_id.has(adjacent_node_id):
				return false
			var reciprocal_adjacent_ids: PackedInt32Array = adjacency_by_node_id.get(adjacent_node_id, PackedInt32Array())
			if not reciprocal_adjacent_ids.has(node_id):
				return false

	var support_count: int = int(family_counts.get("rest", 0)) + int(family_counts.get("merchant", 0)) + int(family_counts.get("blacksmith", 0))
	if int(family_counts.get("start", 0)) != 1:
		return false
	if int(family_counts.get("event", 0)) != 1:
		return false
	if int(family_counts.get("reward", 0)) != 1:
		return false
	if int(family_counts.get(NODE_FAMILY_HAMLET, 0)) != 1:
		return false
	if int(family_counts.get("key", 0)) != 1:
		return false
	if int(family_counts.get("boss", 0)) != 1:
		return false
	if support_count != 2:
		return false

	var depth_by_node_id: Dictionary = _build_scatter_depth_map(adjacency_by_node_id)
	if depth_by_node_id.size() != SCATTER_NODE_COUNT:
		return false
	var max_depth: int = 0
	for depth in depth_by_node_id.values():
		max_depth = max(max_depth, int(depth))

	var start_degree: int = adjacency_by_node_id.get(start_node_id, PackedInt32Array()).size()
	if start_degree != SCATTER_REQUIRED_START_DEGREE:
		return false
	for node_id_variant in adjacency_by_node_id.keys():
		var node_id: int = int(node_id_variant)
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		var degree: int = int(adjacency_by_node_id.get(node_id, PackedInt32Array()).size())
		if node_id == start_node_id:
			continue
		if degree > SCATTER_MAX_NON_START_NODE_DEGREE:
			return false
		if node_depth == 1 and degree > SCATTER_MAX_OPENING_NODE_DEGREE:
			return false
	if int(degree_counts.get(1, 0)) < 2:
		return false
	if int(degree_counts.get(2, 0)) < 2:
		return false
	if int(degree_counts.get(3, 0)) < 1:
		return false
	if int(degree_counts.get(0, 0)) > 0:
		return false

	if key_node_id == NO_PENDING_NODE_ID or boss_node_id == NO_PENDING_NODE_ID:
		return false
	var key_depth: int = int(depth_by_node_id.get(key_node_id, -1))
	var boss_depth: int = int(depth_by_node_id.get(boss_node_id, -1))
	if key_depth < max(2, max_depth - 1):
		return false
	if boss_depth < max_depth:
		return false

	var reconnect_count: int = _count_scatter_same_depth_reconnects(adjacency_by_node_id, depth_by_node_id)
	if reconnect_count < 1 and not allow_reconnect_shortfall:
		return false
	var sorted_node_ids: Array[int] = _sorted_scatter_node_ids(adjacency_by_node_id.keys())
	var parent_by_node_id: Dictionary = _build_scatter_parent_map(adjacency_by_node_id, depth_by_node_id, sorted_node_ids)
	if parent_by_node_id.is_empty():
		return false
	var branch_root_by_node_id: Dictionary = _build_scatter_branch_root_map(parent_by_node_id, sorted_node_ids)
	var children_count_by_node_id: Dictionary = _build_scatter_children_count_map(parent_by_node_id, sorted_node_ids)
	if reconnect_count > 0 and not _scatter_connectivity_rules_hold(adjacency_by_node_id, depth_by_node_id, branch_root_by_node_id, children_count_by_node_id):
		return false

	return true


func _build_controlled_scatter_topology(template_id: String, attempt_index: int) -> Dictionary:
	var blueprint: Dictionary = _select_controlled_scatter_blueprint(template_id, attempt_index, _generation_seed)
	if blueprint.is_empty():
		return {}
	var node_adjacency: Dictionary = {}
	var branch_node_ids: Array = []
	if blueprint.has("fixed_branch_node_ids"):
		var fixed_topology: Dictionary = _build_fixed_scatter_backbone_topology(blueprint)
		node_adjacency = fixed_topology.get("node_adjacency", {})
		branch_node_ids = fixed_topology.get("branch_node_ids", [])
	else:
		var frontier_tree: Dictionary = _build_controlled_scatter_frontier_tree(blueprint, _generation_seed)
		node_adjacency = frontier_tree.get("node_adjacency", {})
		branch_node_ids = frontier_tree.get("branch_node_ids", [])
	if node_adjacency.is_empty() or branch_node_ids.size() != SCATTER_START_BRANCH_COUNT:
		return {}
	var depth_by_node_id: Dictionary = _build_scatter_depth_map(node_adjacency)
	if not depth_by_node_id.is_empty():
		_apply_controlled_scatter_reconnects(node_adjacency, branch_node_ids, depth_by_node_id, blueprint, attempt_index, _generation_seed)
	var role_targets: Dictionary = _reserve_controlled_scatter_role_targets(node_adjacency, branch_node_ids, blueprint)
	return {
		"node_adjacency": node_adjacency,
		"role_targets": role_targets,
		"blueprint_id": String(blueprint.get("blueprint_id", "")),
	}


func _select_controlled_scatter_blueprint(template_id: String, attempt_index: int, generation_seed: int = DEFAULT_GENERATION_SEED) -> Dictionary:
	var blueprint_catalog: Array[Dictionary] = _build_controlled_scatter_blueprint_catalog(template_id)
	if blueprint_catalog.is_empty():
		return {}
	var blueprint_index: int = 0
	if blueprint_catalog.size() > 1:
		var selection_seed: String = "%s|blueprint|%d" % [template_id, _normalize_generation_seed(generation_seed)]
		blueprint_index = (_hash_scatter_seed_string(selection_seed) + max(0, attempt_index)) % blueprint_catalog.size()
	return (blueprint_catalog[blueprint_index] as Dictionary).duplicate(true)


func _build_controlled_scatter_blueprint_catalog(template_id: String) -> Array[Dictionary]:
	if template_id.find("openfield") != -1:
		return [
			_build_fixed_scatter_backbone_blueprint(
				"%s:fan" % template_id,
				PackedInt32Array([1, 6, 9, 13]),
				PackedInt32Array([2, 5, 10, 12]),
				PackedInt32Array([3, 7, 8, 11]),
				[
					_build_fixed_scatter_reconnect_plan(SCATTER_BRANCH_COMBAT, SCATTER_BRANCH_REWARD, SCATTER_RECONNECT_DEPTH_LATE, 0, 1, 7),
					_build_fixed_scatter_reconnect_plan(SCATTER_BRANCH_REWARD, SCATTER_BRANCH_SUPPORT, SCATTER_RECONNECT_DEPTH_LATE),
				],
				SCATTER_BRANCH_SUPPORT
			),
			_build_fixed_scatter_backbone_blueprint(
				"%s:lane" % template_id,
				PackedInt32Array([1, 5, 9, 13]),
				PackedInt32Array([2, 6, 7, 12]),
				PackedInt32Array([3, 8, 10, 11]),
				[
					_build_fixed_scatter_reconnect_plan(SCATTER_BRANCH_COMBAT, SCATTER_BRANCH_REWARD, SCATTER_RECONNECT_DEPTH_LATE, 0, 1, 7),
					_build_fixed_scatter_reconnect_plan(SCATTER_BRANCH_REWARD, SCATTER_BRANCH_SUPPORT, SCATTER_RECONNECT_DEPTH_LATE),
				],
				SCATTER_BRANCH_REWARD
			),
		]
	if template_id.find("loop") != -1:
		return [
			_build_fixed_scatter_backbone_blueprint(
				"%s:return" % template_id,
				PackedInt32Array([1, 5, 6, 13]),
				PackedInt32Array([2, 7, 10, 12]),
				PackedInt32Array([3, 8, 11, 9]),
				[
					_build_fixed_scatter_reconnect_plan(SCATTER_BRANCH_COMBAT, SCATTER_BRANCH_REWARD, SCATTER_RECONNECT_DEPTH_LATE, 0, 1, 7),
					_build_fixed_scatter_reconnect_plan(SCATTER_BRANCH_REWARD, SCATTER_BRANCH_SUPPORT, SCATTER_RECONNECT_DEPTH_LATE),
				],
				SCATTER_BRANCH_SUPPORT
			),
			_build_fixed_scatter_backbone_blueprint(
				"%s:crossback" % template_id,
				PackedInt32Array([1, 5, 9, 13]),
				PackedInt32Array([2, 6, 10, 12]),
				PackedInt32Array([3, 7, 11, 8]),
				[
					_build_fixed_scatter_reconnect_plan(SCATTER_BRANCH_COMBAT, SCATTER_BRANCH_REWARD, SCATTER_RECONNECT_DEPTH_LATE, 0, 1, 7),
					_build_fixed_scatter_reconnect_plan(SCATTER_BRANCH_REWARD, SCATTER_BRANCH_SUPPORT, SCATTER_RECONNECT_DEPTH_MID),
				],
				SCATTER_BRANCH_SUPPORT
			),
		]
	return [
			_build_fixed_scatter_backbone_blueprint(
			"%s:spine" % template_id,
			PackedInt32Array([1, 5, 9, 13]),
			PackedInt32Array([2, 6, 10, 12]),
			PackedInt32Array([3, 7, 8, 11]),
			[
				_build_fixed_scatter_reconnect_plan(SCATTER_BRANCH_COMBAT, SCATTER_BRANCH_REWARD, SCATTER_RECONNECT_DEPTH_LATE, 0, 1, 7),
				_build_fixed_scatter_reconnect_plan(SCATTER_BRANCH_REWARD, SCATTER_BRANCH_SUPPORT, SCATTER_RECONNECT_DEPTH_LATE),
			],
			SCATTER_BRANCH_REWARD
		),
		_build_fixed_scatter_backbone_blueprint(
			"%s:switchback" % template_id,
			PackedInt32Array([1, 5, 6, 13]),
			PackedInt32Array([2, 7, 10, 12]),
			PackedInt32Array([3, 8, 9, 11]),
			[
				_build_fixed_scatter_reconnect_plan(SCATTER_BRANCH_COMBAT, SCATTER_BRANCH_REWARD, SCATTER_RECONNECT_DEPTH_LATE, 0, 1, 7),
				_build_fixed_scatter_reconnect_plan(SCATTER_BRANCH_REWARD, SCATTER_BRANCH_SUPPORT, SCATTER_RECONNECT_DEPTH_LATE),
			],
			SCATTER_BRANCH_COMBAT
		),
	]


func _build_fixed_scatter_backbone_blueprint(
	blueprint_id: String,
	combat_branch_node_ids: PackedInt32Array,
	reward_branch_node_ids: PackedInt32Array,
	support_branch_node_ids: PackedInt32Array,
	reconnect_plans: Array,
	event_branch_id: int
) -> Dictionary:
	var fixed_branch_node_ids: Array = [
		PackedInt32Array(combat_branch_node_ids),
		PackedInt32Array(reward_branch_node_ids),
		PackedInt32Array(support_branch_node_ids),
	]
	return {
		"blueprint_id": blueprint_id,
		"fixed_branch_node_ids": fixed_branch_node_ids,
		"reconnect_plans": reconnect_plans.duplicate(true),
		"event_branch_id": event_branch_id,
	}


func _build_fixed_scatter_reconnect_plan(
	left_branch_id: int,
	right_branch_id: int,
	preferred_depth: int,
	left_depth_offset: int = 0,
	right_depth_offset: int = 0,
	max_path_length: int = SCATTER_MAX_RECONNECT_PATH_LENGTH
) -> Dictionary:
	return {
		"left_branch_id": left_branch_id,
		"right_branch_id": right_branch_id,
		"preferred_depth": preferred_depth,
		"left_depth_offset": left_depth_offset,
		"right_depth_offset": right_depth_offset,
		"max_path_length": max_path_length,
	}


func _build_fixed_scatter_backbone_topology(blueprint: Dictionary) -> Dictionary:
	var fixed_branch_node_ids_variant: Variant = blueprint.get("fixed_branch_node_ids", [])
	if typeof(fixed_branch_node_ids_variant) != TYPE_ARRAY:
		return {}
	var fixed_branch_node_ids: Array = fixed_branch_node_ids_variant
	if fixed_branch_node_ids.size() != SCATTER_START_BRANCH_COUNT:
		return {}

	var branch_node_ids: Array = []
	var used_node_ids: Dictionary = {0: true, 4: true}
	for branch_nodes_variant in fixed_branch_node_ids:
		var branch_node_ids_for_lane: PackedInt32Array = _coerce_adjacent_ids(branch_nodes_variant)
		if branch_node_ids_for_lane.size() != 4:
			return {}
		for node_id in branch_node_ids_for_lane:
			if node_id <= 0 or node_id >= SCATTER_NODE_COUNT or used_node_ids.has(node_id):
				return {}
			used_node_ids[node_id] = true
		branch_node_ids.append(PackedInt32Array(branch_node_ids_for_lane))
	if used_node_ids.size() != SCATTER_NODE_COUNT:
		return {}

	var node_adjacency: Dictionary = {}
	for node_id in range(SCATTER_NODE_COUNT):
		node_adjacency[node_id] = PackedInt32Array()

	for branch_nodes_variant in branch_node_ids:
		var branch_nodes: PackedInt32Array = branch_nodes_variant
		_add_scatter_edge(node_adjacency, 0, int(branch_nodes[0]))
		for branch_index in range(branch_nodes.size() - 1):
			_add_scatter_edge(node_adjacency, int(branch_nodes[branch_index]), int(branch_nodes[branch_index + 1]))
	_add_scatter_edge(node_adjacency, 0, 4)

	return {
		"node_adjacency": node_adjacency,
		"branch_node_ids": branch_node_ids,
	}


func _build_controlled_scatter_blueprint(
	blueprint_id: String,
	branch_target_lengths: PackedInt32Array,
	branch_priority_order: PackedInt32Array,
	reconnect_plans: Array,
	event_branch_id: int
) -> Dictionary:
	var normalized_reconnect_plans: Array[Dictionary] = []
	for reconnect_plan_variant in reconnect_plans:
		if typeof(reconnect_plan_variant) != TYPE_DICTIONARY:
			continue
		normalized_reconnect_plans.append((reconnect_plan_variant as Dictionary).duplicate(true))
	return {
		"blueprint_id": blueprint_id,
		"branch_target_lengths": PackedInt32Array(branch_target_lengths),
		"branch_priority_order": PackedInt32Array(branch_priority_order),
		"reconnect_plans": normalized_reconnect_plans,
		"event_branch_id": event_branch_id,
	}


func _build_controlled_scatter_frontier_tree(blueprint: Dictionary, generation_seed: int = DEFAULT_GENERATION_SEED) -> Dictionary:
	var branch_target_lengths: PackedInt32Array = _frontier_branch_target_lengths(blueprint)
	if branch_target_lengths.size() != SCATTER_START_BRANCH_COUNT:
		return {}
	var target_node_count: int = SCATTER_START_SPUR_NODE_COUNT
	for branch_target_length in branch_target_lengths:
		target_node_count += int(branch_target_length)
	if target_node_count != SCATTER_NODE_COUNT - 1:
		return {}
	var branch_growth_order: PackedInt32Array = _frontier_branch_growth_order(blueprint, branch_target_lengths, generation_seed)
	var node_adjacency: Dictionary = {}
	for node_id in range(SCATTER_NODE_COUNT):
		node_adjacency[node_id] = []
	var branch_node_ids: Array = [[], [], []]
	var next_node_id: int = 1
	for branch_id in range(SCATTER_START_BRANCH_COUNT):
		_add_scatter_edge(node_adjacency, 0, next_node_id)
		(branch_node_ids[branch_id] as Array).append(next_node_id)
		next_node_id += 1
	for _spur_index in range(SCATTER_START_SPUR_NODE_COUNT):
		if next_node_id >= SCATTER_NODE_COUNT:
			break
		_add_scatter_edge(node_adjacency, 0, next_node_id)
		next_node_id += 1
	for branch_id_variant in branch_growth_order:
		var branch_id: int = int(branch_id_variant)
		if branch_id < 0 or branch_id >= branch_node_ids.size():
			return {}
		if next_node_id >= SCATTER_NODE_COUNT:
			break
		var branch_nodes: Array = branch_node_ids[branch_id] as Array
		if branch_nodes.is_empty():
			return {}
		var parent_node_id: int = int(branch_nodes[branch_nodes.size() - 1])
		_add_scatter_edge(node_adjacency, parent_node_id, next_node_id)
		branch_nodes.append(next_node_id)
		branch_node_ids[branch_id] = branch_nodes
		next_node_id += 1
	if next_node_id != SCATTER_NODE_COUNT:
		return {}
	return {
		"node_adjacency": node_adjacency,
		"branch_node_ids": branch_node_ids,
	}


func _frontier_branch_target_lengths(blueprint: Dictionary) -> PackedInt32Array:
	return _coerce_adjacent_ids(blueprint.get("branch_target_lengths", PackedInt32Array()))


func _frontier_branch_growth_order(blueprint: Dictionary, branch_target_lengths: PackedInt32Array, generation_seed: int = DEFAULT_GENERATION_SEED) -> PackedInt32Array:
	var priority_order: PackedInt32Array = _frontier_branch_priority_order(blueprint, generation_seed)
	var branch_current_lengths: PackedInt32Array = PackedInt32Array([1, 1, 1])
	var growth_order: PackedInt32Array = PackedInt32Array()
	var required_growth_steps: int = 0
	for branch_target_length in branch_target_lengths:
		required_growth_steps += max(0, int(branch_target_length) - 1)
	while growth_order.size() < required_growth_steps:
		var added_this_round: bool = false
		for branch_id in priority_order:
			if branch_id < 0 or branch_id >= branch_target_lengths.size():
				continue
			if int(branch_current_lengths[branch_id]) >= int(branch_target_lengths[branch_id]):
				continue
			growth_order.append(branch_id)
			branch_current_lengths[branch_id] = int(branch_current_lengths[branch_id]) + 1
			added_this_round = true
			if growth_order.size() >= required_growth_steps:
				break
		if not added_this_round:
			break
	return growth_order


func _frontier_branch_priority_order(blueprint: Dictionary, generation_seed: int = DEFAULT_GENERATION_SEED) -> PackedInt32Array:
	var base_order: PackedInt32Array = _coerce_adjacent_ids(
		blueprint.get(
			"branch_priority_order",
			PackedInt32Array([SCATTER_BRANCH_COMBAT, SCATTER_BRANCH_SUPPORT, SCATTER_BRANCH_REWARD])
		)
	)
	if base_order.size() != SCATTER_START_BRANCH_COUNT:
		base_order = PackedInt32Array([SCATTER_BRANCH_COMBAT, SCATTER_BRANCH_SUPPORT, SCATTER_BRANCH_REWARD])
	var blueprint_id: String = String(blueprint.get("blueprint_id", ""))
	var rotation_offset: int = 0
	if base_order.size() > 1 and not blueprint_id.is_empty():
		rotation_offset = _hash_scatter_seed_string("%s|branch-priority|%d" % [blueprint_id, _normalize_generation_seed(generation_seed)]) % base_order.size()
	return _rotate_packed_int32_array(base_order, rotation_offset)


func _rotate_packed_int32_array(values: PackedInt32Array, rotation_offset: int) -> PackedInt32Array:
	if values.is_empty():
		return PackedInt32Array()
	var rotated_values := PackedInt32Array()
	for index in range(values.size()):
		rotated_values.append(int(values[(index + rotation_offset) % values.size()]))
	return rotated_values


func _apply_controlled_scatter_reconnects(
	node_adjacency: Dictionary,
	branch_node_ids: Array,
	depth_by_node_id: Dictionary,
	blueprint: Dictionary,
	attempt_index: int,
	generation_seed: int = DEFAULT_GENERATION_SEED
) -> void:
	var reconnect_plans: Array = _scatter_reconnect_plans(blueprint)
	var applied_count: int = 0
	var plan_offset: int = 0
	if reconnect_plans.size() > 0:
		var blueprint_id: String = String(blueprint.get("blueprint_id", ""))
		var generation_offset: int = _hash_scatter_seed_string("%s|reconnect|%d" % [blueprint_id, _normalize_generation_seed(generation_seed)]) % reconnect_plans.size()
		plan_offset = (attempt_index + generation_offset) % reconnect_plans.size()
	for plan_index in range(reconnect_plans.size()):
		var rotated_index: int = (plan_index + plan_offset) % reconnect_plans.size()
		var reconnect_plan_variant: Variant = reconnect_plans[rotated_index]
		if typeof(reconnect_plan_variant) != TYPE_DICTIONARY:
			continue
		var reconnect_plan: Dictionary = reconnect_plan_variant
		var reconnect_edge: Array[int] = _pick_controlled_reconnect_edge(node_adjacency, branch_node_ids, depth_by_node_id, reconnect_plan)
		if reconnect_edge.size() != 2:
			continue
		_add_scatter_edge(node_adjacency, reconnect_edge[0], reconnect_edge[1])
		applied_count += 1
		if applied_count >= SCATTER_MAX_RECONNECT_EDGE_COUNT:
			break


func _scatter_reconnect_plans(blueprint: Dictionary) -> Array:
	var reconnect_plans_variant: Variant = blueprint.get("reconnect_plans", [])
	var reconnect_plans: Array = []
	if typeof(reconnect_plans_variant) != TYPE_ARRAY:
		return reconnect_plans
	for reconnect_plan_variant in reconnect_plans_variant:
		if typeof(reconnect_plan_variant) != TYPE_DICTIONARY:
			continue
		reconnect_plans.append((reconnect_plan_variant as Dictionary).duplicate(true))
	return reconnect_plans


func _pick_controlled_reconnect_edge(
	node_adjacency: Dictionary,
	branch_node_ids: Array,
	depth_by_node_id: Dictionary,
	reconnect_plan: Dictionary
) -> Array[int]:
	var left_branch_id: int = int(reconnect_plan.get("left_branch_id", -1))
	var right_branch_id: int = int(reconnect_plan.get("right_branch_id", -1))
	if left_branch_id < 0 or right_branch_id < 0:
		return []
	if left_branch_id >= branch_node_ids.size() or right_branch_id >= branch_node_ids.size():
		return []
	if not _scatter_branches_are_local_neighbors(left_branch_id, right_branch_id):
		return []
	var preferred_depth: int = int(reconnect_plan.get("preferred_depth", SCATTER_RECONNECT_DEPTH_MID))
	var left_preferred_depth: int = preferred_depth + int(reconnect_plan.get("left_depth_offset", 0))
	var right_preferred_depth: int = preferred_depth + int(reconnect_plan.get("right_depth_offset", 0))
	var max_path_length: int = int(reconnect_plan.get("max_path_length", SCATTER_MAX_RECONNECT_PATH_LENGTH))
	var left_candidates: Array[int] = _preferred_reconnect_candidates(branch_node_ids[left_branch_id] as Array, depth_by_node_id, left_preferred_depth)
	var right_candidates: Array[int] = _preferred_reconnect_candidates(branch_node_ids[right_branch_id] as Array, depth_by_node_id, right_preferred_depth)
	for left_node_id in left_candidates:
		for right_node_id in right_candidates:
			if left_node_id == right_node_id:
				continue
			if _has_scatter_edge(node_adjacency, left_node_id, right_node_id):
				continue
			if _get_scatter_degree(node_adjacency, left_node_id) >= SCATTER_MAX_NODE_DEGREE:
				continue
			if _get_scatter_degree(node_adjacency, right_node_id) >= SCATTER_MAX_NODE_DEGREE:
				continue
			var left_depth: int = int(depth_by_node_id.get(left_node_id, -1))
			var right_depth: int = int(depth_by_node_id.get(right_node_id, -1))
			if left_depth != left_preferred_depth or right_depth != right_preferred_depth:
				continue
			var reconnect_path_length: int = _build_scatter_path_length(node_adjacency, left_node_id, right_node_id)
			if reconnect_path_length < SCATTER_MIN_RECONNECT_PATH_LENGTH or reconnect_path_length > max_path_length:
				continue
			return [left_node_id, right_node_id]
	return []


func _scatter_branches_are_local_neighbors(left_branch_id: int, right_branch_id: int) -> bool:
	return abs(left_branch_id - right_branch_id) <= SCATTER_MAX_LOCAL_BRANCH_DISTANCE


func _preferred_reconnect_candidates(branch_nodes: Array, depth_by_node_id: Dictionary, preferred_depth: int) -> Array[int]:
	var candidates: Array[int] = []
	var maximum_index: int = max(1, branch_nodes.size())
	for branch_index in range(1, maximum_index):
		candidates.append(int(branch_nodes[branch_index]))
	candidates.sort_custom(func(left_id: int, right_id: int) -> bool:
		var left_depth_distance: int = abs(int(depth_by_node_id.get(left_id, -1)) - preferred_depth)
		var right_depth_distance: int = abs(int(depth_by_node_id.get(right_id, -1)) - preferred_depth)
		if left_depth_distance == right_depth_distance:
			return left_id < right_id
		return left_depth_distance < right_depth_distance
	)
	return candidates


func _reserve_controlled_scatter_role_targets(node_adjacency: Dictionary, branch_node_ids: Array, blueprint: Dictionary) -> Dictionary:
	if branch_node_ids.size() != SCATTER_START_BRANCH_COUNT:
		return {}
	var opening_combat_id: int = _branch_role_node_id(branch_node_ids, SCATTER_BRANCH_COMBAT, 0)
	var opening_reward_id: int = _branch_role_node_id(branch_node_ids, SCATTER_BRANCH_REWARD, 0)
	var opening_support_id: int = _branch_role_node_id(branch_node_ids, SCATTER_BRANCH_SUPPORT, 0)
	var late_support_id: int = _branch_role_node_id(branch_node_ids, SCATTER_BRANCH_SUPPORT, 1)
	var boss_node_id: int = _branch_role_node_id(branch_node_ids, SCATTER_BRANCH_COMBAT, -1)
	var key_node_id: int = _branch_role_node_id(branch_node_ids, SCATTER_BRANCH_REWARD, -1)
	var side_mission_node_id: int = _branch_role_node_id(branch_node_ids, SCATTER_BRANCH_SUPPORT, -1)
	var event_node_id: int = _reserve_event_slot_node_id(node_adjacency, branch_node_ids, blueprint)
	return {
		SCATTER_ROLE_OPENING_COMBAT: opening_combat_id,
		SCATTER_ROLE_OPENING_REWARD: opening_reward_id,
		SCATTER_ROLE_OPENING_SUPPORT: opening_support_id,
		SCATTER_ROLE_LATE_SUPPORT: late_support_id,
		SCATTER_ROLE_EVENT: event_node_id,
		SCATTER_ROLE_SIDE_MISSION: side_mission_node_id,
		SCATTER_ROLE_KEY: key_node_id,
		SCATTER_ROLE_BOSS: boss_node_id,
	}


func _reserve_event_slot_node_id(node_adjacency: Dictionary, branch_node_ids: Array, blueprint: Dictionary) -> int:
	var event_branch_id: int = int(blueprint.get("event_branch_id", SCATTER_BRANCH_REWARD))
	var branch_nodes: Array = branch_node_ids[event_branch_id] as Array
	var last_index: int = branch_nodes.size() - 2
	while last_index >= 1:
		var candidate_node_id: int = int(branch_nodes[last_index])
		if _get_scatter_degree(node_adjacency, candidate_node_id) <= SCATTER_MAX_NODE_DEGREE:
			return candidate_node_id
		last_index -= 1
	return NO_PENDING_NODE_ID


func _branch_role_node_id(branch_node_ids: Array, branch_id: int, branch_index: int) -> int:
	if branch_id < 0 or branch_id >= branch_node_ids.size():
		return NO_PENDING_NODE_ID
	var branch_nodes: Array = branch_node_ids[branch_id] as Array
	if branch_nodes.is_empty():
		return NO_PENDING_NODE_ID
	var resolved_index: int = branch_index
	if resolved_index < 0:
		resolved_index = branch_nodes.size() + resolved_index
	if resolved_index < 0 or resolved_index >= branch_nodes.size():
		return NO_PENDING_NODE_ID
	return int(branch_nodes[resolved_index])


func _validate_controlled_scatter_topology(node_adjacency: Dictionary, role_targets: Dictionary) -> bool:
	if node_adjacency.size() != SCATTER_NODE_COUNT:
		return false
	if not _controlled_scatter_role_targets_are_valid(node_adjacency, role_targets):
		return false
	var graph: Array[Dictionary] = []
	for node_id_variant in node_adjacency.keys():
		var node_id: int = int(node_id_variant)
		graph.append({
			"node_id": node_id,
			"adjacent_node_ids": _coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array())),
		})
	if not _is_graph_connected_scatter(graph):
		return false
	var degree_counts: Dictionary = {}
	for node_id_variant in node_adjacency.keys():
		var node_id: int = int(node_id_variant)
		var degree: int = _get_scatter_degree(node_adjacency, node_id)
		if degree < 1:
			return false
		if node_id == 0:
			if degree != SCATTER_REQUIRED_START_DEGREE:
				return false
		elif degree > SCATTER_MAX_NON_START_NODE_DEGREE:
			return false
		degree_counts[degree] = int(degree_counts.get(degree, 0)) + 1
	if int(degree_counts.get(1, 0)) < SCATTER_MIN_LEAF_COUNT:
		return false
	if int(degree_counts.get(2, 0)) < SCATTER_MIN_TWO_WAY_COUNT:
		return false
	if int(degree_counts.get(3, 0)) < SCATTER_MIN_THREE_WAY_COUNT:
		return false
	var reconnect_edge_count: int = _count_scatter_extra_edges(node_adjacency)
	if reconnect_edge_count < SCATTER_MIN_RECONNECT_EDGE_COUNT or reconnect_edge_count > SCATTER_MAX_RECONNECT_EDGE_COUNT:
		return false
	var depth_by_node_id: Dictionary = _build_scatter_depth_map(node_adjacency)
	if _count_scatter_same_depth_reconnects(node_adjacency, depth_by_node_id) < 1:
		return false
	var sorted_node_ids: Array[int] = _sorted_scatter_node_ids(node_adjacency.keys())
	var parent_by_node_id: Dictionary = _build_scatter_parent_map(node_adjacency, depth_by_node_id, sorted_node_ids)
	if parent_by_node_id.is_empty():
		return false
	var branch_root_by_node_id: Dictionary = _build_scatter_branch_root_map(parent_by_node_id, sorted_node_ids)
	var children_count_by_node_id: Dictionary = _build_scatter_children_count_map(parent_by_node_id, sorted_node_ids)
	if not _scatter_connectivity_rules_hold(node_adjacency, depth_by_node_id, branch_root_by_node_id, children_count_by_node_id):
		return false
	return true


func _scatter_connectivity_rules_hold(
	node_adjacency: Dictionary,
	depth_by_node_id: Dictionary,
	branch_root_by_node_id: Dictionary,
	children_count_by_node_id: Dictionary
) -> bool:
	if depth_by_node_id.size() != SCATTER_NODE_COUNT:
		return false
	if not _same_depth_reconnects_stay_local(node_adjacency, depth_by_node_id):
		return false
	for node_id_variant in node_adjacency.keys():
		var node_id: int = int(node_id_variant)
		var degree: int = _get_scatter_degree(node_adjacency, node_id)
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		if node_id == 0:
			if degree != SCATTER_REQUIRED_START_DEGREE:
				return false
			continue
		if degree < 1 or degree > SCATTER_MAX_NON_START_NODE_DEGREE:
			return false
		if node_depth == 1 and degree > SCATTER_MAX_OPENING_NODE_DEGREE:
			return false
	var seen_edges: Dictionary = {}
	for node_id_variant in node_adjacency.keys():
		var node_id: int = int(node_id_variant)
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		for adjacent_node_id in _coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array())):
			var resolved_adjacent_node_id: int = int(adjacent_node_id)
			var adjacent_depth: int = int(depth_by_node_id.get(resolved_adjacent_node_id, -1))
			var left_id: int = min(node_id, resolved_adjacent_node_id)
			var right_id: int = max(node_id, resolved_adjacent_node_id)
			var edge_key: String = "%d:%d" % [left_id, right_id]
			if seen_edges.has(edge_key):
				continue
			seen_edges[edge_key] = true
			if node_depth < 2 or adjacent_depth < 2 or node_depth != adjacent_depth:
				continue
			var left_branch_root: int = int(branch_root_by_node_id.get(left_id, NO_PENDING_NODE_ID))
			var right_branch_root: int = int(branch_root_by_node_id.get(right_id, NO_PENDING_NODE_ID))
			if left_branch_root == NO_PENDING_NODE_ID or right_branch_root == NO_PENDING_NODE_ID:
				return false
			if not _scatter_branches_are_local_neighbors(left_branch_root - 1, right_branch_root - 1):
				return false
			if not _scatter_node_has_forward_neighbor(node_adjacency, depth_by_node_id, left_id):
				return false
			if not _scatter_node_has_forward_neighbor(node_adjacency, depth_by_node_id, right_id):
				return false
	return true


func _scatter_node_has_forward_neighbor(node_adjacency: Dictionary, depth_by_node_id: Dictionary, node_id: int) -> bool:
	var node_depth: int = int(depth_by_node_id.get(node_id, -1))
	for adjacent_node_id in _coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array())):
		if int(depth_by_node_id.get(int(adjacent_node_id), -1)) > node_depth:
			return true
	return false


func _build_controlled_scatter_family_assignments(node_adjacency: Dictionary, role_targets: Dictionary, stage_index: int) -> Dictionary:
	if not _controlled_scatter_role_targets_are_valid(node_adjacency, role_targets):
		return {}
	var analysis: Dictionary = _build_scatter_structural_family_analysis(node_adjacency, role_targets, stage_index)
	if analysis.is_empty():
		return {}
	var support_layout: Dictionary = _resolve_stage_support_layout(stage_index)
	var opening_support_family: String = String(support_layout.get("opening_support_family", "rest"))
	var late_support_family: String = String(support_layout.get("late_support_family", "merchant"))
	var assignments: Dictionary = {
		0: "start",
	}
	var role_assignments: Dictionary = {}
	var depth_by_node_id: Dictionary = analysis.get("depth_by_node_id", {})
	var branch_root_by_node_id: Dictionary = analysis.get("branch_root_by_node_id", {})
	var start_adjacent_ids: Array[int] = analysis.get("start_adjacent_ids", [])
	var max_depth: int = int(analysis.get("max_depth", 0))
	var mainline_start_adjacent_ids: Array[int] = _filter_scatter_node_ids_by_min_degree(start_adjacent_ids, node_adjacency, 2)
	var opening_shell_candidates: Array[int] = start_adjacent_ids
	if not mainline_start_adjacent_ids.is_empty():
		opening_shell_candidates = mainline_start_adjacent_ids

	var opening_support_candidates: Array[int] = _filter_unassigned_node_ids(opening_shell_candidates, assignments)
	var opening_support_id: int = _pick_best_scatter_role_candidate(
		opening_support_candidates,
		node_adjacency,
		analysis,
		SCATTER_ROLE_OPENING_SUPPORT,
		role_assignments
	)
	if opening_support_id == NO_PENDING_NODE_ID:
		return {}
	assignments[opening_support_id] = opening_support_family
	role_assignments[SCATTER_ROLE_OPENING_SUPPORT] = opening_support_id

	var reward_candidates: Array[int] = _filter_unassigned_node_ids(opening_shell_candidates, assignments)
	var opening_support_branch_root: int = int(branch_root_by_node_id.get(opening_support_id, NO_PENDING_NODE_ID))
	var diverse_reward_candidates: Array[int] = _filter_nodes_by_branch_root(reward_candidates, branch_root_by_node_id, opening_support_branch_root, false)
	if not diverse_reward_candidates.is_empty():
		reward_candidates = diverse_reward_candidates
	var reward_node_id: int = _pick_best_scatter_role_candidate(
		reward_candidates,
		node_adjacency,
		analysis,
		SCATTER_ROLE_OPENING_REWARD,
		role_assignments
	)
	if reward_node_id == NO_PENDING_NODE_ID:
		return {}
	assignments[reward_node_id] = "reward"
	role_assignments[SCATTER_ROLE_OPENING_REWARD] = reward_node_id

	var boss_candidates: Array[int] = _filter_unassigned_node_ids(_build_unassigned_scatter_node_ids(node_adjacency, assignments), assignments)
	boss_candidates = _filter_nodes_by_depth_and_max(boss_candidates, depth_by_node_id, max(PLACEMENT_OUTER_MIN_DEPTH, max_depth - 1), max_depth)
	if boss_candidates.is_empty():
		boss_candidates = _filter_nodes_by_depth_and_max(_build_unassigned_scatter_node_ids(node_adjacency, assignments), depth_by_node_id, 2, max_depth)
	var boss_node_id: int = _pick_best_scatter_role_candidate(
		boss_candidates,
		node_adjacency,
		analysis,
		SCATTER_ROLE_BOSS,
		role_assignments
	)
	if boss_node_id == NO_PENDING_NODE_ID:
		return {}
	assignments[boss_node_id] = "boss"
	role_assignments[SCATTER_ROLE_BOSS] = boss_node_id

	var key_candidates: Array[int] = _filter_nodes_by_depth_and_max(_build_unassigned_scatter_node_ids(node_adjacency, assignments), depth_by_node_id, max(2, max_depth - 1), max_depth)
	if key_candidates.is_empty():
		key_candidates = _filter_nodes_by_depth_and_max(_build_unassigned_scatter_node_ids(node_adjacency, assignments), depth_by_node_id, 2, max_depth)
	var boss_branch_root: int = int(branch_root_by_node_id.get(boss_node_id, NO_PENDING_NODE_ID))
	var separated_key_candidates: Array[int] = _filter_nodes_by_branch_root(key_candidates, branch_root_by_node_id, boss_branch_root, false)
	if not separated_key_candidates.is_empty():
		key_candidates = separated_key_candidates
	var distant_key_candidates: Array[int] = _filter_nodes_by_min_path_length(key_candidates, node_adjacency, boss_node_id, 2)
	if not distant_key_candidates.is_empty():
		key_candidates = distant_key_candidates
	var key_node_id: int = _pick_best_scatter_role_candidate(
		key_candidates,
		node_adjacency,
		analysis,
		SCATTER_ROLE_KEY,
		role_assignments
	)
	if key_node_id == NO_PENDING_NODE_ID:
		return {}
	assignments[key_node_id] = "key"
	role_assignments[SCATTER_ROLE_KEY] = key_node_id

	var late_support_candidates: Array[int] = _filter_nodes_by_depth_and_max(_build_unassigned_scatter_node_ids(node_adjacency, assignments), depth_by_node_id, min(max_depth, max(2, int(depth_by_node_id.get(opening_support_id, 1)) + 1)), max_depth)
	var adjacent_support_candidates: Array[int] = _filter_nodes_adjacent_to_target(late_support_candidates, node_adjacency, opening_support_id)
	if not adjacent_support_candidates.is_empty():
		late_support_candidates = adjacent_support_candidates
	else:
		var lineage_support_candidates: Array[int] = _filter_nodes_by_branch_root(late_support_candidates, branch_root_by_node_id, opening_support_branch_root, true)
		if not lineage_support_candidates.is_empty():
			late_support_candidates = lineage_support_candidates
	if late_support_candidates.is_empty():
		late_support_candidates = _filter_nodes_by_depth_and_max(_build_unassigned_scatter_node_ids(node_adjacency, assignments), depth_by_node_id, 2, max_depth)
	var late_support_id: int = _pick_best_scatter_role_candidate(
		late_support_candidates,
		node_adjacency,
		analysis,
		SCATTER_ROLE_LATE_SUPPORT,
		role_assignments
	)
	if late_support_id == NO_PENDING_NODE_ID:
		return {}
	assignments[late_support_id] = late_support_family
	role_assignments[SCATTER_ROLE_LATE_SUPPORT] = late_support_id

	var side_mission_candidates: Array[int] = _filter_nodes_by_depth_and_max(_build_unassigned_scatter_node_ids(node_adjacency, assignments), depth_by_node_id, PLACEMENT_OUTER_MIN_DEPTH, max_depth)
	var leaf_like_side_mission_candidates: Array[int] = _filter_leaf_like_scatter_nodes(side_mission_candidates, analysis)
	if not leaf_like_side_mission_candidates.is_empty():
		side_mission_candidates = leaf_like_side_mission_candidates
	var detour_side_mission_candidates: Array[int] = _filter_nodes_by_branch_root(side_mission_candidates, branch_root_by_node_id, boss_branch_root, false)
	if not detour_side_mission_candidates.is_empty():
		side_mission_candidates = detour_side_mission_candidates
	if side_mission_candidates.is_empty():
		side_mission_candidates = _filter_nodes_by_depth_and_max(_build_unassigned_scatter_node_ids(node_adjacency, assignments), depth_by_node_id, 2, max_depth)
	var side_mission_node_id: int = _pick_best_scatter_role_candidate(
		side_mission_candidates,
		node_adjacency,
		analysis,
		SCATTER_ROLE_SIDE_MISSION,
		role_assignments
	)
	if side_mission_node_id == NO_PENDING_NODE_ID:
		return {}
	assignments[side_mission_node_id] = NODE_FAMILY_HAMLET
	role_assignments[SCATTER_ROLE_SIDE_MISSION] = side_mission_node_id

	var event_candidates: Array[int] = _filter_nodes_by_depth_and_max(_build_unassigned_scatter_node_ids(node_adjacency, assignments), depth_by_node_id, 2, max(2, max_depth - 1))
	var connector_event_candidates: Array[int] = _filter_connector_friendly_scatter_nodes(event_candidates, analysis)
	if not connector_event_candidates.is_empty():
		event_candidates = connector_event_candidates
	var boss_key_branch_candidates: Array[int] = _filter_nodes_away_from_role_branches(event_candidates, analysis, role_assignments, [SCATTER_ROLE_BOSS, SCATTER_ROLE_KEY])
	if not boss_key_branch_candidates.is_empty():
		event_candidates = boss_key_branch_candidates
	if event_candidates.is_empty():
		event_candidates = _build_unassigned_scatter_node_ids(node_adjacency, assignments)
	var event_node_id: int = _pick_best_scatter_role_candidate(
		event_candidates,
		node_adjacency,
		analysis,
		SCATTER_ROLE_EVENT,
		role_assignments
	)
	if event_node_id == NO_PENDING_NODE_ID:
		return {}
	assignments[event_node_id] = "event"
	role_assignments[SCATTER_ROLE_EVENT] = event_node_id

	for node_id_variant in node_adjacency.keys():
		var node_id: int = int(node_id_variant)
		if assignments.has(node_id):
			continue
		assignments[node_id] = "combat"

	return assignments


func _build_scatter_structural_family_analysis(node_adjacency: Dictionary, role_targets: Dictionary, stage_index: int) -> Dictionary:
	var depth_by_node_id: Dictionary = _build_scatter_depth_map(node_adjacency)
	if depth_by_node_id.size() != SCATTER_NODE_COUNT:
		return {}
	var degree_by_node_id: Dictionary = {}
	var sorted_node_ids: Array[int] = _sorted_scatter_node_ids(node_adjacency.keys())
	for node_id in sorted_node_ids:
		degree_by_node_id[node_id] = _get_scatter_degree(node_adjacency, node_id)
	var parent_by_node_id: Dictionary = _build_scatter_parent_map(node_adjacency, depth_by_node_id, sorted_node_ids)
	if parent_by_node_id.is_empty():
		return {}
	var branch_root_by_node_id: Dictionary = _build_scatter_branch_root_map(parent_by_node_id, sorted_node_ids)
	var children_count_by_node_id: Dictionary = _build_scatter_children_count_map(parent_by_node_id, sorted_node_ids)
	var same_depth_reconnect_node_ids: Dictionary = _build_scatter_same_depth_reconnect_node_set(node_adjacency, depth_by_node_id)
	var start_adjacent_ids: Array[int] = _sorted_scatter_node_ids(_coerce_adjacent_ids(node_adjacency.get(0, PackedInt32Array())))
	var branch_summaries: Dictionary = _build_scatter_branch_summaries(
		sorted_node_ids,
		depth_by_node_id,
		branch_root_by_node_id,
		children_count_by_node_id,
		same_depth_reconnect_node_ids,
		start_adjacent_ids
	)
	var max_depth: int = 0
	for depth_value in depth_by_node_id.values():
		max_depth = max(max_depth, int(depth_value))
	return {
		"depth_by_node_id": depth_by_node_id,
		"degree_by_node_id": degree_by_node_id,
		"parent_by_node_id": parent_by_node_id,
		"branch_root_by_node_id": branch_root_by_node_id,
		"children_count_by_node_id": children_count_by_node_id,
		"same_depth_reconnect_node_ids": same_depth_reconnect_node_ids,
		"start_adjacent_ids": start_adjacent_ids,
		"branch_summaries": branch_summaries,
		"max_depth": max_depth,
		"reserved_role_targets": role_targets.duplicate(true),
		"placement_seed": _build_scatter_placement_seed(node_adjacency, stage_index, _generation_seed),
	}


func _sorted_scatter_node_ids(node_id_variants: Variant) -> Array[int]:
	return MapScatterGraphToolsScript.sorted_node_ids(node_id_variants)


func _build_scatter_parent_map(node_adjacency: Dictionary, depth_by_node_id: Dictionary, sorted_node_ids: Array[int]) -> Dictionary:
	var parent_by_node_id: Dictionary = {0: NO_PENDING_NODE_ID}
	for node_id in sorted_node_ids:
		if node_id == 0:
			continue
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		if node_depth == 1:
			parent_by_node_id[node_id] = 0
			continue
		var parent_candidates: Array[int] = []
		for adjacent_node_id in _coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array())):
			if int(depth_by_node_id.get(adjacent_node_id, -1)) == node_depth - 1:
				parent_candidates.append(int(adjacent_node_id))
		parent_candidates.sort()
		if parent_candidates.is_empty():
			return {}
		parent_by_node_id[node_id] = parent_candidates[0]
	return parent_by_node_id


func _build_scatter_branch_root_map(parent_by_node_id: Dictionary, sorted_node_ids: Array[int]) -> Dictionary:
	var branch_root_by_node_id: Dictionary = {0: 0}
	for node_id in sorted_node_ids:
		if node_id == 0:
			continue
		var parent_node_id: int = int(parent_by_node_id.get(node_id, NO_PENDING_NODE_ID))
		if parent_node_id == 0:
			branch_root_by_node_id[node_id] = node_id
			continue
		branch_root_by_node_id[node_id] = int(branch_root_by_node_id.get(parent_node_id, parent_node_id))
	return branch_root_by_node_id


func _build_scatter_children_count_map(parent_by_node_id: Dictionary, sorted_node_ids: Array[int]) -> Dictionary:
	var children_count_by_node_id: Dictionary = {}
	for node_id in sorted_node_ids:
		children_count_by_node_id[node_id] = 0
	for node_id in sorted_node_ids:
		if node_id == 0:
			continue
		var parent_node_id: int = int(parent_by_node_id.get(node_id, NO_PENDING_NODE_ID))
		if parent_node_id == NO_PENDING_NODE_ID:
			continue
		children_count_by_node_id[parent_node_id] = int(children_count_by_node_id.get(parent_node_id, 0)) + 1
	return children_count_by_node_id


func _build_scatter_same_depth_reconnect_node_set(node_adjacency: Dictionary, depth_by_node_id: Dictionary) -> Dictionary:
	var reconnect_node_ids: Dictionary = {}
	var seen_edges: Dictionary = {}
	for node_id_variant in node_adjacency.keys():
		var node_id: int = int(node_id_variant)
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		for adjacent_node_id in _coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array())):
			var adjacent_depth: int = int(depth_by_node_id.get(adjacent_node_id, -1))
			var left_id: int = min(node_id, int(adjacent_node_id))
			var right_id: int = max(node_id, int(adjacent_node_id))
			var edge_key: String = "%d:%d" % [left_id, right_id]
			if seen_edges.has(edge_key):
				continue
			seen_edges[edge_key] = true
			if node_depth < 2 or adjacent_depth < 2 or node_depth != adjacent_depth:
				continue
			reconnect_node_ids[node_id] = true
			reconnect_node_ids[int(adjacent_node_id)] = true
	return reconnect_node_ids


func _build_scatter_branch_summaries(
	sorted_node_ids: Array[int],
	depth_by_node_id: Dictionary,
	branch_root_by_node_id: Dictionary,
	children_count_by_node_id: Dictionary,
	same_depth_reconnect_node_ids: Dictionary,
	start_adjacent_ids: Array[int]
) -> Dictionary:
	var branch_summaries: Dictionary = {}
	for branch_root_id in start_adjacent_ids:
		branch_summaries[branch_root_id] = {
			"node_count": 0,
			"max_depth": 0,
			"leaf_like_count": 0,
			"reconnect_touch_count": 0,
		}
	for node_id in sorted_node_ids:
		if node_id == 0:
			continue
		var branch_root_id: int = int(branch_root_by_node_id.get(node_id, node_id))
		var summary: Dictionary = (branch_summaries.get(branch_root_id, {
			"node_count": 0,
			"max_depth": 0,
			"leaf_like_count": 0,
			"reconnect_touch_count": 0,
		}) as Dictionary).duplicate(true)
		summary["node_count"] = int(summary.get("node_count", 0)) + 1
		summary["max_depth"] = max(int(summary.get("max_depth", 0)), int(depth_by_node_id.get(node_id, 0)))
		if _is_leaf_like_scatter_node(node_id, depth_by_node_id, children_count_by_node_id):
			summary["leaf_like_count"] = int(summary.get("leaf_like_count", 0)) + 1
		if same_depth_reconnect_node_ids.has(node_id):
			summary["reconnect_touch_count"] = int(summary.get("reconnect_touch_count", 0)) + 1
		branch_summaries[branch_root_id] = summary
	return branch_summaries


func _build_scatter_placement_seed(node_adjacency: Dictionary, stage_index: int, generation_seed: int = DEFAULT_GENERATION_SEED) -> int:
	return _hash_scatter_seed_string("%s|stage:%d|seed:%d|%s" % [
		_active_template_id,
		max(1, stage_index),
		_normalize_generation_seed(generation_seed),
		_build_scatter_topology_signature(node_adjacency),
	])


func _build_scatter_topology_signature(node_adjacency: Dictionary) -> String:
	return MapScatterGraphToolsScript.build_topology_signature(node_adjacency)

func _build_unassigned_scatter_node_ids(node_adjacency: Dictionary, assignments: Dictionary) -> Array[int]:
	var node_ids: Array[int] = []
	for node_id in _sorted_scatter_node_ids(node_adjacency.keys()):
		if assignments.has(node_id):
			continue
		node_ids.append(node_id)
	return node_ids

func _filter_unassigned_node_ids(node_ids: Array[int], assignments: Dictionary) -> Array[int]:
	var filtered_node_ids: Array[int] = []
	for node_id in node_ids:
		if assignments.has(node_id):
			continue
		filtered_node_ids.append(node_id)
	return filtered_node_ids

func _filter_scatter_node_ids_by_min_degree(node_ids: Array[int], node_adjacency: Dictionary, min_degree: int) -> Array[int]:
	var filtered_node_ids: Array[int] = []
	for node_id in node_ids:
		if _get_scatter_degree(node_adjacency, node_id) < min_degree:
			continue
		filtered_node_ids.append(node_id)
	return filtered_node_ids

func _filter_nodes_by_branch_root(node_ids: Array[int], branch_root_by_node_id: Dictionary, branch_root: int, require_match: bool) -> Array[int]:
	var filtered_node_ids: Array[int] = []
	for node_id in node_ids:
		var node_branch_root: int = int(branch_root_by_node_id.get(node_id, NO_PENDING_NODE_ID))
		if require_match and node_branch_root != branch_root:
			continue
		if not require_match and node_branch_root == branch_root:
			continue
		filtered_node_ids.append(node_id)
	return filtered_node_ids

func _filter_nodes_by_min_path_length(node_ids: Array[int], node_adjacency: Dictionary, target_node_id: int, min_path_length: int) -> Array[int]:
	var filtered_node_ids: Array[int] = []
	for node_id in node_ids:
		if _build_scatter_path_length(node_adjacency, node_id, target_node_id) >= min_path_length:
			filtered_node_ids.append(node_id)
	return filtered_node_ids

func _filter_nodes_adjacent_to_target(node_ids: Array[int], node_adjacency: Dictionary, target_node_id: int) -> Array[int]:
	var filtered_node_ids: Array[int] = []
	var adjacent_node_ids: PackedInt32Array = _coerce_adjacent_ids(node_adjacency.get(target_node_id, PackedInt32Array()))
	for node_id in node_ids:
		if adjacent_node_ids.has(node_id):
			filtered_node_ids.append(node_id)
	return filtered_node_ids

func _filter_leaf_like_scatter_nodes(node_ids: Array[int], analysis: Dictionary) -> Array[int]:
	var filtered_node_ids: Array[int] = []
	var depth_by_node_id: Dictionary = analysis.get("depth_by_node_id", {})
	var children_count_by_node_id: Dictionary = analysis.get("children_count_by_node_id", {})
	for node_id in node_ids:
		if _is_leaf_like_scatter_node(node_id, depth_by_node_id, children_count_by_node_id):
			filtered_node_ids.append(node_id)
	return filtered_node_ids

func _filter_connector_friendly_scatter_nodes(node_ids: Array[int], analysis: Dictionary) -> Array[int]:
	var filtered_node_ids: Array[int] = []
	for node_id in node_ids:
		if _connector_score_for_scatter_node(node_id, analysis) >= 3.0:
			filtered_node_ids.append(node_id)
	return filtered_node_ids

func _filter_nodes_away_from_role_branches(node_ids: Array[int], analysis: Dictionary, role_assignments: Dictionary, role_names: Array[String]) -> Array[int]:
	var filtered_node_ids: Array[int] = []
	var branch_root_by_node_id: Dictionary = analysis.get("branch_root_by_node_id", {})
	var blocked_branch_roots: Dictionary = {}
	for role_name in role_names:
		var assigned_node_id: int = int(role_assignments.get(role_name, NO_PENDING_NODE_ID))
		if assigned_node_id == NO_PENDING_NODE_ID:
			continue
		blocked_branch_roots[int(branch_root_by_node_id.get(assigned_node_id, NO_PENDING_NODE_ID))] = true
	for node_id in node_ids:
		var branch_root: int = int(branch_root_by_node_id.get(node_id, NO_PENDING_NODE_ID))
		if blocked_branch_roots.has(branch_root):
			continue
		filtered_node_ids.append(node_id)
	return filtered_node_ids


func _constrained_scatter_role_shortlist_limit(role_name: String) -> int:
	match role_name:
		SCATTER_ROLE_SIDE_MISSION, SCATTER_ROLE_EVENT:
			return PLACEMENT_SHORTLIST_DETOUR_LIMIT
		SCATTER_ROLE_BOSS, SCATTER_ROLE_KEY:
			return 2
	return PLACEMENT_SHORTLIST_STANDARD_LIMIT


func _constrained_scatter_role_score_window(role_name: String) -> float:
	match role_name:
		SCATTER_ROLE_BOSS, SCATTER_ROLE_KEY:
			return PLACEMENT_SHORTLIST_NARROW_SCORE_WINDOW
		SCATTER_ROLE_SIDE_MISSION, SCATTER_ROLE_EVENT:
			return PLACEMENT_SHORTLIST_WIDE_SCORE_WINDOW
	return PLACEMENT_SHORTLIST_STANDARD_SCORE_WINDOW


func _build_constrained_scatter_role_shortlist(scored_candidates: Array[Dictionary], role_name: String) -> Array[Dictionary]:
	var shortlist: Array[Dictionary] = []
	if scored_candidates.is_empty():
		return shortlist
	var best_score: float = float(scored_candidates[0].get("score", -INF))
	var shortlist_limit: int = _constrained_scatter_role_shortlist_limit(role_name)
	var score_window: float = _constrained_scatter_role_score_window(role_name)
	for scored_candidate in scored_candidates:
		if shortlist.size() >= shortlist_limit:
			break
		var score: float = float(scored_candidate.get("score", -INF))
		if score + score_window < best_score:
			break
		shortlist.append((scored_candidate as Dictionary).duplicate(true))
	if shortlist.is_empty():
		shortlist.append((scored_candidates[0] as Dictionary).duplicate(true))
	return shortlist


func _build_scatter_role_assignment_signature(role_assignments: Dictionary) -> String:
	if role_assignments.is_empty():
		return "none"
	var ordered_role_names: Array[String] = []
	for role_name_variant in role_assignments.keys():
		ordered_role_names.append(String(role_name_variant))
	ordered_role_names.sort()
	var fragments: PackedStringArray = []
	for role_name in ordered_role_names:
		fragments.append("%s:%d" % [role_name, int(role_assignments.get(role_name, NO_PENDING_NODE_ID))])
	return "|".join(fragments)


func _build_scatter_role_selection_roll(role_name: String, analysis: Dictionary, role_assignments: Dictionary) -> float:
	var placement_seed: int = int(analysis.get("placement_seed", 1))
	var roll_hash: int = _hash_scatter_seed_string("%d|%s|%s" % [
		placement_seed,
		role_name,
		_build_scatter_role_assignment_signature(role_assignments),
	])
	return float(roll_hash % 1000000) / 1000000.0


func _pick_constrained_scatter_role_candidate(shortlist: Array[Dictionary], role_name: String, analysis: Dictionary, role_assignments: Dictionary) -> int:
	if shortlist.is_empty():
		return NO_PENDING_NODE_ID
	if shortlist.size() == 1:
		return int(shortlist[0].get("node_id", NO_PENDING_NODE_ID))
	var lowest_score: float = INF
	for scored_candidate in shortlist:
		lowest_score = min(lowest_score, float(scored_candidate.get("score", INF)))
	var candidate_weights: Array[float] = []
	var total_weight: float = 0.0
	for shortlist_index in range(shortlist.size()):
		var scored_candidate: Dictionary = shortlist[shortlist_index]
		var score: float = float(scored_candidate.get("score", lowest_score))
		var weight: float = max(0.25, (score - lowest_score) + 1.0)
		weight += float(shortlist.size() - shortlist_index) * 0.35
		candidate_weights.append(weight)
		total_weight += weight
	var selection_value: float = _build_scatter_role_selection_roll(role_name, analysis, role_assignments) * total_weight
	var cumulative_weight: float = 0.0
	for shortlist_index in range(shortlist.size()):
		cumulative_weight += float(candidate_weights[shortlist_index])
		if selection_value <= cumulative_weight + 0.0001:
			return int((shortlist[shortlist_index] as Dictionary).get("node_id", NO_PENDING_NODE_ID))
	return int((shortlist[shortlist.size() - 1] as Dictionary).get("node_id", NO_PENDING_NODE_ID))


func _pick_best_scatter_role_candidate(
	candidate_node_ids: Array[int],
	node_adjacency: Dictionary,
	analysis: Dictionary,
	role_name: String,
	role_assignments: Dictionary
) -> int:
	var scored_candidates: Array[Dictionary] = []
	for node_id in candidate_node_ids:
		var score: float = _score_scatter_role_candidate(node_id, node_adjacency, analysis, role_name, role_assignments)
		var tiebreak_value: float = _role_tiebreak_value(role_name, node_id, analysis)
		scored_candidates.append({
			"node_id": node_id,
			"score": score,
			"tiebreak": tiebreak_value,
		})
	if scored_candidates.is_empty():
		return NO_PENDING_NODE_ID
	scored_candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_score: float = float(left.get("score", -INF))
		var right_score: float = float(right.get("score", -INF))
		if abs(left_score - right_score) <= 0.0001:
			return float(left.get("tiebreak", -INF)) > float(right.get("tiebreak", -INF))
		return left_score > right_score
	)
	var shortlist: Array[Dictionary] = _build_constrained_scatter_role_shortlist(scored_candidates, role_name)
	return _pick_constrained_scatter_role_candidate(shortlist, role_name, analysis, role_assignments)


func _score_scatter_role_candidate(
	node_id: int,
	node_adjacency: Dictionary,
	analysis: Dictionary,
	role_name: String,
	role_assignments: Dictionary
) -> float:
	var depth_by_node_id: Dictionary = analysis.get("depth_by_node_id", {})
	var branch_root_by_node_id: Dictionary = analysis.get("branch_root_by_node_id", {})
	var branch_summaries: Dictionary = analysis.get("branch_summaries", {})
	var reserved_role_targets: Dictionary = analysis.get("reserved_role_targets", {})
	var children_count_by_node_id: Dictionary = analysis.get("children_count_by_node_id", {})
	var depth: int = int(depth_by_node_id.get(node_id, -1))
	var branch_root: int = int(branch_root_by_node_id.get(node_id, NO_PENDING_NODE_ID))
	var branch_summary: Dictionary = branch_summaries.get(branch_root, {})
	var branch_node_count: int = int(branch_summary.get("node_count", 1))
	var branch_max_depth: int = int(branch_summary.get("max_depth", depth))
	var branch_reconnect_touch_count: int = int(branch_summary.get("reconnect_touch_count", 0))
	var frontier_score: float = _frontier_score_for_scatter_node(node_id, analysis)
	var connector_score: float = _connector_score_for_scatter_node(node_id, analysis)
	var progress_corridor_score: float = _progress_corridor_score_for_scatter_node(node_id, analysis)
	var optional_detour_score: float = _optional_detour_score_for_scatter_node(node_id, analysis, role_assignments)
	var reserved_node_id: int = int(reserved_role_targets.get(role_name, NO_PENDING_NODE_ID))
	match role_name:
		SCATTER_ROLE_OPENING_SUPPORT:
			var opening_support_score: float = _target_proximity_score(branch_node_count, PLACEMENT_BRANCH_TARGET_NODE_COUNT, 6.0)
			opening_support_score += float(branch_max_depth) * 2.0
			opening_support_score -= float(branch_reconnect_touch_count) * 2.0
			if depth <= PLACEMENT_OPENING_MAX_DEPTH:
				opening_support_score += PLACEMENT_SCORE_STRONG_BONUS
			if node_id == reserved_node_id:
				opening_support_score += PLACEMENT_SCORE_LIGHT_BONUS
			return opening_support_score
		SCATTER_ROLE_OPENING_REWARD:
			var support_branch_root: int = int(branch_root_by_node_id.get(int(role_assignments.get(SCATTER_ROLE_OPENING_SUPPORT, NO_PENDING_NODE_ID)), NO_PENDING_NODE_ID))
			var opening_reward_score: float = _target_proximity_score(branch_node_count, PLACEMENT_BRANCH_TARGET_NODE_COUNT, 6.0)
			opening_reward_score += float(branch_max_depth) * 1.5
			opening_reward_score -= float(branch_reconnect_touch_count)
			if branch_root != support_branch_root:
				opening_reward_score += PLACEMENT_SCORE_STRONG_BONUS
			if node_id == reserved_node_id:
				opening_reward_score += PLACEMENT_SCORE_LIGHT_BONUS
			return opening_reward_score
		SCATTER_ROLE_BOSS:
			var boss_score: float = float(depth) * 10.0
			boss_score += frontier_score * 6.0
			boss_score += progress_corridor_score * 2.0
			boss_score -= connector_score * 2.0
			if node_id == reserved_node_id:
				boss_score += PLACEMENT_SCORE_LIGHT_BONUS
			return boss_score
		SCATTER_ROLE_KEY:
			var boss_node_id: int = int(role_assignments.get(SCATTER_ROLE_BOSS, NO_PENDING_NODE_ID))
			var boss_branch_root: int = int(branch_root_by_node_id.get(boss_node_id, NO_PENDING_NODE_ID))
			var boss_separation: int = _build_scatter_path_length(node_adjacency, node_id, boss_node_id)
			var key_score: float = float(depth) * 8.0
			key_score += frontier_score * 3.0
			key_score += progress_corridor_score * 3.0
			key_score += float(max(0, boss_separation)) * 3.0
			if branch_root != boss_branch_root:
				key_score += PLACEMENT_SCORE_STRONG_BONUS
			if int(children_count_by_node_id.get(node_id, 0)) > 0:
				key_score += PLACEMENT_SCORE_LIGHT_BONUS
			if node_id == reserved_node_id:
				key_score += PLACEMENT_SCORE_LIGHT_BONUS
			return key_score
		SCATTER_ROLE_LATE_SUPPORT:
			var opening_support_id: int = int(role_assignments.get(SCATTER_ROLE_OPENING_SUPPORT, NO_PENDING_NODE_ID))
			var opening_support_branch_root: int = int(branch_root_by_node_id.get(opening_support_id, NO_PENDING_NODE_ID))
			var opening_support_depth: int = int(depth_by_node_id.get(opening_support_id, 1))
			var opening_support_distance: int = _build_scatter_path_length(node_adjacency, opening_support_id, node_id)
			var late_support_score: float = _target_proximity_score(depth, max(PLACEMENT_LATE_SUPPORT_TARGET_DEPTH, opening_support_depth + 1), 4.0)
			late_support_score += connector_score * 2.0
			late_support_score += progress_corridor_score * 1.5
			late_support_score -= frontier_score * 1.5
			if opening_support_distance == 1:
				late_support_score += PLACEMENT_SCORE_STRONG_BONUS * 2.0
			if branch_root == opening_support_branch_root:
				late_support_score += PLACEMENT_SCORE_STRONG_BONUS
			if depth > opening_support_depth:
				late_support_score += PLACEMENT_SCORE_MEDIUM_BONUS
			if node_id == reserved_node_id:
				late_support_score += PLACEMENT_SCORE_LIGHT_BONUS
			return late_support_score
		SCATTER_ROLE_SIDE_MISSION:
			var boss_branch_root_for_side: int = int(branch_root_by_node_id.get(int(role_assignments.get(SCATTER_ROLE_BOSS, NO_PENDING_NODE_ID)), NO_PENDING_NODE_ID))
			var key_branch_root_for_side: int = int(branch_root_by_node_id.get(int(role_assignments.get(SCATTER_ROLE_KEY, NO_PENDING_NODE_ID)), NO_PENDING_NODE_ID))
			var opening_support_branch_root_for_side: int = int(branch_root_by_node_id.get(int(role_assignments.get(SCATTER_ROLE_OPENING_SUPPORT, NO_PENDING_NODE_ID)), NO_PENDING_NODE_ID))
			var side_mission_score: float = optional_detour_score * 6.0
			side_mission_score += float(depth) * 2.0
			side_mission_score += frontier_score * 1.5
			side_mission_score -= connector_score
			if branch_root != boss_branch_root_for_side:
				side_mission_score += PLACEMENT_SCORE_MEDIUM_BONUS
			if branch_root != key_branch_root_for_side:
				side_mission_score += PLACEMENT_SCORE_LIGHT_BONUS
			if branch_root != opening_support_branch_root_for_side:
				side_mission_score += PLACEMENT_SCORE_LIGHT_BONUS
			if node_id == reserved_node_id:
				side_mission_score += PLACEMENT_SCORE_LIGHT_BONUS
			return side_mission_score
		SCATTER_ROLE_EVENT:
			var boss_branch_root_for_event: int = int(branch_root_by_node_id.get(int(role_assignments.get(SCATTER_ROLE_BOSS, NO_PENDING_NODE_ID)), NO_PENDING_NODE_ID))
			var key_branch_root_for_event: int = int(branch_root_by_node_id.get(int(role_assignments.get(SCATTER_ROLE_KEY, NO_PENDING_NODE_ID)), NO_PENDING_NODE_ID))
			var opening_support_branch_root_for_event: int = int(branch_root_by_node_id.get(int(role_assignments.get(SCATTER_ROLE_OPENING_SUPPORT, NO_PENDING_NODE_ID)), NO_PENDING_NODE_ID))
			var side_mission_branch_root_for_event: int = int(branch_root_by_node_id.get(int(role_assignments.get(SCATTER_ROLE_SIDE_MISSION, NO_PENDING_NODE_ID)), NO_PENDING_NODE_ID))
			var event_score: float = connector_score * 6.0
			event_score += _target_proximity_score(depth, min(int(analysis.get("max_depth", depth)), PLACEMENT_EVENT_TARGET_DEPTH), 4.0)
			event_score -= frontier_score * 1.5
			if branch_root != boss_branch_root_for_event:
				event_score += PLACEMENT_SCORE_LIGHT_BONUS
			if branch_root != key_branch_root_for_event:
				event_score += PLACEMENT_SCORE_LIGHT_BONUS
			if branch_root != opening_support_branch_root_for_event:
				event_score += PLACEMENT_SCORE_LIGHT_BONUS
			if side_mission_branch_root_for_event != NO_PENDING_NODE_ID and branch_root != side_mission_branch_root_for_event:
				event_score += PLACEMENT_SCORE_LIGHT_BONUS
			if node_id == reserved_node_id:
				event_score += PLACEMENT_SCORE_LIGHT_BONUS
			return event_score
	return 0.0


func _frontier_score_for_scatter_node(node_id: int, analysis: Dictionary) -> float:
	var depth_by_node_id: Dictionary = analysis.get("depth_by_node_id", {})
	var degree_by_node_id: Dictionary = analysis.get("degree_by_node_id", {})
	var children_count_by_node_id: Dictionary = analysis.get("children_count_by_node_id", {})
	var same_depth_reconnect_node_ids: Dictionary = analysis.get("same_depth_reconnect_node_ids", {})
	var max_depth: int = max(1, int(analysis.get("max_depth", 1)))
	var depth: int = int(depth_by_node_id.get(node_id, 0))
	var degree: int = int(degree_by_node_id.get(node_id, 0))
	var children_count: int = int(children_count_by_node_id.get(node_id, 0))
	var score: float = (float(depth) / float(max_depth)) * 4.0
	if _is_leaf_like_scatter_node(node_id, depth_by_node_id, children_count_by_node_id):
		score += 2.5
	if degree <= 2:
		score += 1.0
	if same_depth_reconnect_node_ids.has(node_id):
		score -= 0.75
	if children_count > 1:
		score -= float(children_count - 1) * 0.5
	return score


func _connector_score_for_scatter_node(node_id: int, analysis: Dictionary) -> float:
	var depth_by_node_id: Dictionary = analysis.get("depth_by_node_id", {})
	var degree_by_node_id: Dictionary = analysis.get("degree_by_node_id", {})
	var children_count_by_node_id: Dictionary = analysis.get("children_count_by_node_id", {})
	var same_depth_reconnect_node_ids: Dictionary = analysis.get("same_depth_reconnect_node_ids", {})
	var depth: int = int(depth_by_node_id.get(node_id, 0))
	var degree: int = int(degree_by_node_id.get(node_id, 0))
	var score: float = 0.0
	if depth < 2:
		return score
	if degree >= 2:
		score += 2.0
	if degree >= 3:
		score += 2.0
	if same_depth_reconnect_node_ids.has(node_id):
		score += 2.5
	score += _target_proximity_score(depth, PLACEMENT_EVENT_TARGET_DEPTH, 2.0)
	if int(children_count_by_node_id.get(node_id, 0)) == 0:
		score -= 1.0
	return score


func _progress_corridor_score_for_scatter_node(node_id: int, analysis: Dictionary) -> float:
	var branch_root_by_node_id: Dictionary = analysis.get("branch_root_by_node_id", {})
	var branch_summaries: Dictionary = analysis.get("branch_summaries", {})
	var children_count_by_node_id: Dictionary = analysis.get("children_count_by_node_id", {})
	var branch_root: int = int(branch_root_by_node_id.get(node_id, NO_PENDING_NODE_ID))
	var branch_summary: Dictionary = branch_summaries.get(branch_root, {})
	var score: float = float(int(branch_summary.get("max_depth", 0)))
	score += float(int(children_count_by_node_id.get(node_id, 0))) * 1.5
	if int(branch_summary.get("reconnect_touch_count", 0)) == 0:
		score += 0.5
	return score


func _optional_detour_score_for_scatter_node(node_id: int, analysis: Dictionary, role_assignments: Dictionary) -> float:
	var branch_root_by_node_id: Dictionary = analysis.get("branch_root_by_node_id", {})
	var depth_by_node_id: Dictionary = analysis.get("depth_by_node_id", {})
	var children_count_by_node_id: Dictionary = analysis.get("children_count_by_node_id", {})
	var score: float = _frontier_score_for_scatter_node(node_id, analysis) * 1.5
	score -= _connector_score_for_scatter_node(node_id, analysis) * 0.5
	if _is_leaf_like_scatter_node(node_id, depth_by_node_id, children_count_by_node_id):
		score += 3.0
	var boss_branch_root: int = int(branch_root_by_node_id.get(int(role_assignments.get(SCATTER_ROLE_BOSS, NO_PENDING_NODE_ID)), NO_PENDING_NODE_ID))
	var key_branch_root: int = int(branch_root_by_node_id.get(int(role_assignments.get(SCATTER_ROLE_KEY, NO_PENDING_NODE_ID)), NO_PENDING_NODE_ID))
	var branch_root: int = int(branch_root_by_node_id.get(node_id, NO_PENDING_NODE_ID))
	if boss_branch_root != NO_PENDING_NODE_ID and branch_root != boss_branch_root:
		score += PLACEMENT_SCORE_LIGHT_BONUS
	if key_branch_root != NO_PENDING_NODE_ID and branch_root != key_branch_root:
		score += 1.0
	return score


func _is_leaf_like_scatter_node(node_id: int, depth_by_node_id: Dictionary, children_count_by_node_id: Dictionary) -> bool:
	return int(depth_by_node_id.get(node_id, 0)) >= 2 and int(children_count_by_node_id.get(node_id, 0)) == 0


func _target_proximity_score(actual_value: int, target_value: int, max_score: float) -> float:
	return max(0.0, max_score - abs(float(actual_value - target_value)))


func _role_tiebreak_value(role_name: String, node_id: int, analysis: Dictionary) -> float:
	var placement_seed: int = int(analysis.get("placement_seed", 1))
	return float(_hash_scatter_seed_string("%d|%s|%d" % [placement_seed, role_name, node_id]))


func _hash_scatter_seed_string(value: String) -> int:
	var accumulator: int = 216613626
	var bytes: PackedByteArray = value.to_utf8_buffer()
	for byte in bytes:
		accumulator = abs(int((accumulator ^ int(byte)) * 16777619))
	if accumulator == 0:
		return 1
	return accumulator


func _controlled_scatter_role_targets_are_valid(node_adjacency: Dictionary, role_targets: Dictionary) -> bool:
	if node_adjacency.is_empty() or role_targets.is_empty():
		return false

	var required_role_names: PackedStringArray = [
		SCATTER_ROLE_OPENING_COMBAT,
		SCATTER_ROLE_OPENING_REWARD,
		SCATTER_ROLE_OPENING_SUPPORT,
		SCATTER_ROLE_LATE_SUPPORT,
		SCATTER_ROLE_EVENT,
		SCATTER_ROLE_SIDE_MISSION,
		SCATTER_ROLE_KEY,
		SCATTER_ROLE_BOSS,
	]
	var used_node_ids: Dictionary = {0: true}
	for role_name in required_role_names:
		var node_id: int = int(role_targets.get(role_name, NO_PENDING_NODE_ID))
		if node_id == NO_PENDING_NODE_ID or not node_adjacency.has(node_id) or used_node_ids.has(node_id):
			return false
		used_node_ids[node_id] = true

	var start_adjacent_ids: PackedInt32Array = _coerce_adjacent_ids(node_adjacency.get(0, PackedInt32Array()))
	if not start_adjacent_ids.has(int(role_targets.get(SCATTER_ROLE_OPENING_COMBAT, NO_PENDING_NODE_ID))):
		return false
	if not start_adjacent_ids.has(int(role_targets.get(SCATTER_ROLE_OPENING_REWARD, NO_PENDING_NODE_ID))):
		return false
	if not start_adjacent_ids.has(int(role_targets.get(SCATTER_ROLE_OPENING_SUPPORT, NO_PENDING_NODE_ID))):
		return false

	var opening_support_node_id: int = int(role_targets.get(SCATTER_ROLE_OPENING_SUPPORT, NO_PENDING_NODE_ID))
	var late_support_node_id: int = int(role_targets.get(SCATTER_ROLE_LATE_SUPPORT, NO_PENDING_NODE_ID))
	if not _coerce_adjacent_ids(node_adjacency.get(opening_support_node_id, PackedInt32Array())).has(late_support_node_id):
		return false

	var depth_by_node_id: Dictionary = _build_scatter_depth_map(node_adjacency)
	var event_node_id: int = int(role_targets.get(SCATTER_ROLE_EVENT, NO_PENDING_NODE_ID))
	var side_mission_node_id: int = int(role_targets.get(SCATTER_ROLE_SIDE_MISSION, NO_PENDING_NODE_ID))
	var key_node_id: int = int(role_targets.get(SCATTER_ROLE_KEY, NO_PENDING_NODE_ID))
	var boss_node_id: int = int(role_targets.get(SCATTER_ROLE_BOSS, NO_PENDING_NODE_ID))
	if int(depth_by_node_id.get(event_node_id, -1)) < 3:
		return false
	if int(depth_by_node_id.get(side_mission_node_id, -1)) < 3:
		return false
	if int(depth_by_node_id.get(key_node_id, -1)) < 3:
		return false
	if int(depth_by_node_id.get(boss_node_id, -1)) < 4:
		return false
	if _build_scatter_path_length(node_adjacency, key_node_id, boss_node_id) < 2:
		return false

	return true


func _build_scatter_path_length(node_adjacency: Dictionary, start_node_id: int, target_node_id: int) -> int:
	return MapScatterGraphToolsScript.build_path_length(node_adjacency, start_node_id, target_node_id)


func _build_scatter_path_length_without_edge(
	node_adjacency: Dictionary,
	start_node_id: int,
	target_node_id: int,
	ignored_left_id: int,
	ignored_right_id: int
) -> int:
	if start_node_id == target_node_id:
		return 0
	if not node_adjacency.has(start_node_id) or not node_adjacency.has(target_node_id):
		return -1

	var visited: Dictionary = {start_node_id: true}
	var queue: Array[Dictionary] = [{"node_id": start_node_id, "distance": 0}]
	while not queue.is_empty():
		var entry: Dictionary = queue.pop_front()
		var node_id: int = int(entry.get("node_id", -1))
		var distance: int = int(entry.get("distance", 0))
		for adjacent_node_id in _coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array())):
			var resolved_adjacent_node_id: int = int(adjacent_node_id)
			var ignores_active_edge: bool = (
				(node_id == ignored_left_id and resolved_adjacent_node_id == ignored_right_id)
				or (node_id == ignored_right_id and resolved_adjacent_node_id == ignored_left_id)
			)
			if ignores_active_edge:
				continue
			if resolved_adjacent_node_id == target_node_id:
				return distance + 1
			if visited.has(resolved_adjacent_node_id):
				continue
			visited[resolved_adjacent_node_id] = true
			queue.append({
				"node_id": resolved_adjacent_node_id,
				"distance": distance + 1,
			})
	return -1


func _count_scatter_same_depth_reconnects(adjacency_by_node_id: Dictionary, depth_by_node_id: Dictionary) -> int:
	return MapScatterGraphToolsScript.count_same_depth_reconnects(adjacency_by_node_id, depth_by_node_id)


func _same_depth_reconnects_stay_local(node_adjacency: Dictionary, depth_by_node_id: Dictionary) -> bool:
	var seen_edges: Dictionary = {}
	for node_id_variant in node_adjacency.keys():
		var node_id: int = int(node_id_variant)
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		for adjacent_node_id in _coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array())):
			var resolved_adjacent_node_id: int = int(adjacent_node_id)
			var adjacent_depth: int = int(depth_by_node_id.get(resolved_adjacent_node_id, -1))
			var left_id: int = min(node_id, resolved_adjacent_node_id)
			var right_id: int = max(node_id, resolved_adjacent_node_id)
			var edge_key: String = "%d:%d" % [left_id, right_id]
			if seen_edges.has(edge_key):
				continue
			seen_edges[edge_key] = true
			if node_depth < 2 or adjacent_depth < 2 or node_depth != adjacent_depth:
				continue
			var reconnect_path_length: int = _build_scatter_path_length_without_edge(node_adjacency, left_id, right_id, left_id, right_id)
			if reconnect_path_length < SCATTER_MIN_RECONNECT_PATH_LENGTH:
				return false
			if reconnect_path_length > SCATTER_MAX_RECONNECT_PATH_LENGTH:
				return false
	return true


func _count_scatter_extra_edges(node_adjacency: Dictionary) -> int:
	return MapScatterGraphToolsScript.count_extra_edges(node_adjacency, SCATTER_NODE_COUNT)

func _build_adjacency_lookup_from_graph(graph: Array[Dictionary]) -> Dictionary:
	return MapScatterGraphToolsScript.build_adjacency_lookup_from_graph(graph, NO_PENDING_NODE_ID)

func _build_family_budget_slot_reservations_from_graph(graph: Array[Dictionary]) -> Dictionary:
	var reservations: Dictionary = {}
	if graph.is_empty():
		return reservations
	var support_layout: Dictionary = _resolve_stage_support_layout(_generation_stage_index)
	var opening_support_family: String = String(support_layout.get("opening_support_family", "rest"))
	var late_support_family: String = String(support_layout.get("late_support_family", "merchant"))
	var adjacency_by_node_id: Dictionary = _build_adjacency_lookup_from_graph(graph)
	var opening_combat_id: int = NO_PENDING_NODE_ID
	for node_entry in graph:
		var node_id: int = int(node_entry.get("node_id", NO_PENDING_NODE_ID))
		var node_family: String = String(node_entry.get("node_family", ""))
		if node_family == "combat" and adjacency_by_node_id.get(0, PackedInt32Array()).has(node_id) and opening_combat_id == NO_PENDING_NODE_ID:
			opening_combat_id = node_id
		match node_family:
			"reward":
				reservations[SCATTER_ROLE_OPENING_REWARD] = node_id
			"event":
				reservations[SCATTER_ROLE_EVENT] = node_id
			NODE_FAMILY_HAMLET:
				reservations[SCATTER_ROLE_SIDE_MISSION] = node_id
			"key":
				reservations[SCATTER_ROLE_KEY] = node_id
			"boss":
				reservations[SCATTER_ROLE_BOSS] = node_id
			_:
				if node_family == opening_support_family:
					reservations[SCATTER_ROLE_OPENING_SUPPORT] = node_id
				elif node_family == late_support_family:
					reservations[SCATTER_ROLE_LATE_SUPPORT] = node_id
	if opening_combat_id != NO_PENDING_NODE_ID:
		reservations[SCATTER_ROLE_OPENING_COMBAT] = opening_combat_id
	return reservations

func _rebuild_family_budget_slot_reservations_from_graph() -> void:
	_family_budget_slot_reservations = _build_family_budget_slot_reservations_from_graph(_node_graph)

func _has_scatter_edge(node_adjacency: Dictionary, left_id: int, right_id: int) -> bool:
	return MapScatterGraphToolsScript.has_edge(node_adjacency, left_id, right_id)

func _add_scatter_edge(node_adjacency: Dictionary, left_id: int, right_id: int) -> void:
	MapScatterGraphToolsScript.add_edge(node_adjacency, left_id, right_id)


func _get_scatter_degree(node_adjacency: Dictionary, node_id: int) -> int:
	return MapScatterGraphToolsScript.degree(node_adjacency, node_id)


func _build_scatter_graph_payload(node_adjacency: Dictionary, family_assignments: Dictionary) -> Array[Dictionary]:
	var graph: Array[Dictionary] = []
	var ordered_node_ids: Array[int] = []
	for node_id in node_adjacency.keys():
		ordered_node_ids.append(int(node_id))
	ordered_node_ids.sort()

	for node_id in ordered_node_ids:
		var adjacent_node_ids: PackedInt32Array = _coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array()))
		adjacent_node_ids.sort()
		graph.append({
			"node_id": node_id,
			"node_family": String(family_assignments.get(node_id, "")),
			"node_state": NODE_STATE_UNDISCOVERED,
			"adjacent_node_ids": PackedInt32Array(adjacent_node_ids),
		})
	return graph


func _validate_scatter_runtime_graph(graph: Array[Dictionary]) -> bool:
	if graph.size() != SCATTER_NODE_COUNT:
		return false
	if not _is_graph_connected_scatter(graph):
		return false

	var family_counts: Dictionary = {}
	var adjacency_by_node_id: Dictionary = {}
	for entry_variant in graph:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return false
		var entry: Dictionary = entry_variant
		var node_id: int = int(entry.get("node_id", NO_PENDING_NODE_ID))
		if node_id < 0:
			return false
		if adjacency_by_node_id.has(node_id):
			return false
		var node_family: String = String(entry.get("node_family", ""))
		family_counts[node_family] = int(family_counts.get(node_family, 0)) + 1
		var adjacent_ids: PackedInt32Array = _coerce_adjacent_ids(entry.get("adjacent_node_ids", []))
		if adjacent_ids.is_empty() and node_family != "boss":
			return false
		var seen_adjacent_ids: Dictionary = {}
		for adjacent_node_id in adjacent_ids:
			if adjacent_node_id < 0 or adjacent_node_id == node_id or seen_adjacent_ids.has(adjacent_node_id):
				return false
			seen_adjacent_ids[adjacent_node_id] = true
		adjacency_by_node_id[node_id] = adjacent_ids

	for node_id in adjacency_by_node_id.keys():
		var adjacent_node_ids: PackedInt32Array = adjacency_by_node_id[node_id]
		for adjacent_node_id in adjacent_node_ids:
			if not adjacency_by_node_id.has(adjacent_node_id):
				return false
			var reciprocal_adjacent_node_ids: PackedInt32Array = adjacency_by_node_id[adjacent_node_id]
			if not reciprocal_adjacent_node_ids.has(node_id):
				return false

	var expected_families: Dictionary = {
		"start": 1,
		"combat": 6,
		"event": 1,
		"reward": 1,
		NODE_FAMILY_HAMLET: 1,
		"key": 1,
		"boss": 1,
	}
	var support_count: int = int(family_counts.get("rest", 0)) + int(family_counts.get("merchant", 0)) + int(family_counts.get("blacksmith", 0))
	if int(family_counts.get("start", 0)) != expected_families["start"]:
		return false
	if int(family_counts.get("combat", 0)) != expected_families["combat"]:
		return false
	if int(family_counts.get("event", 0)) != expected_families["event"]:
		return false
	if int(family_counts.get("reward", 0)) != expected_families["reward"]:
		return false
	if int(family_counts.get(NODE_FAMILY_HAMLET, 0)) != expected_families[NODE_FAMILY_HAMLET]:
		return false
	if int(family_counts.get("key", 0)) != expected_families["key"]:
		return false
	if int(family_counts.get("boss", 0)) != expected_families["boss"]:
		return false
	if support_count != 2:
		return false

	var node0_entry: Dictionary = {}
	for entry in graph:
		if int(entry.get("node_id", NO_PENDING_NODE_ID)) == 0:
			node0_entry = entry
			break
	if node0_entry.is_empty():
		return false
	var start_degree: int = int(_coerce_adjacent_ids(node0_entry.get("adjacent_node_ids", [])).size())
	if start_degree != SCATTER_REQUIRED_START_DEGREE:
		return false

	var degree_counts: Dictionary = {}
	for entry in graph:
		var node_id: int = int(entry.get("node_id", NO_PENDING_NODE_ID))
		var adjacent_ids: PackedInt32Array = _coerce_adjacent_ids(entry.get("adjacent_node_ids", []))
		var degree: int = adjacent_ids.size()
		degree_counts[degree] = int(degree_counts.get(degree, 0)) + 1
		if degree < 1:
			return false
		if node_id == 0:
			if degree != SCATTER_REQUIRED_START_DEGREE:
				return false
		elif degree > SCATTER_MAX_NON_START_NODE_DEGREE:
			return false

	if int(degree_counts.get(1, 0)) < 2:
		return false
	if int(degree_counts.get(2, 0)) < 2:
		return false
	if int(degree_counts.get(3, 0)) < 1:
		return false

	var depth_by_node_id: Dictionary = _build_scatter_depth_map(adjacency_by_node_id)
	if _count_scatter_same_depth_reconnects(adjacency_by_node_id, depth_by_node_id) < 1:
		# Keep at least one late reconnect so the graph does not collapse into a pure tree.
		return false
	var sorted_node_ids: Array[int] = _sorted_scatter_node_ids(adjacency_by_node_id.keys())
	var parent_by_node_id: Dictionary = _build_scatter_parent_map(adjacency_by_node_id, depth_by_node_id, sorted_node_ids)
	if parent_by_node_id.is_empty():
		return false
	var branch_root_by_node_id: Dictionary = _build_scatter_branch_root_map(parent_by_node_id, sorted_node_ids)
	var children_count_by_node_id: Dictionary = _build_scatter_children_count_map(parent_by_node_id, sorted_node_ids)
	if not _scatter_connectivity_rules_hold(adjacency_by_node_id, depth_by_node_id, branch_root_by_node_id, children_count_by_node_id):
		return false

	return true


func _is_graph_connected_scatter(graph: Array[Dictionary]) -> bool:
	return MapScatterGraphToolsScript.is_graph_connected(graph, NO_PENDING_NODE_ID)


func _build_scatter_depth_map(node_adjacency: Dictionary) -> Dictionary:
	return MapScatterGraphToolsScript.build_depth_map(node_adjacency)


func _filter_nodes_by_depth_and_max(node_ids: Array[int], depth_by_node_id: Dictionary, min_depth: int, max_depth: int) -> Array[int]:
	return MapScatterGraphToolsScript.filter_nodes_by_depth_range(node_ids, depth_by_node_id, min_depth, max_depth)


func _resolve_stage_support_layout(stage_index: int) -> Dictionary:
	if STAGE_SUPPORT_LAYOUTS.is_empty():
		return {
			"opening_support_family": "rest",
			"late_support_family": "merchant",
		}
	var stage_offset: int = max(0, stage_index - 1)
	return (STAGE_SUPPORT_LAYOUTS[stage_offset % STAGE_SUPPORT_LAYOUTS.size()] as Dictionary).duplicate(true)
