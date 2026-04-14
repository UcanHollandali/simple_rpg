# Layer: Infrastructure
extends RefCounted
class_name SaveService

const FlowStateScript = preload("res://Game/Application/flow_state.gd")

const DEFAULT_SAVE_PATH: String = "user://simple_rpg_safe_state_save.json"
const SAVE_SCHEMA_VERSION: int = 5
const PREVIOUS_SAVE_SCHEMA_VERSION: int = 4
const LEGACY_REWARD_SAVE_SCHEMA_VERSION: int = 2
const LEGACY_SAVE_SCHEMA_VERSION: int = 1
const CONTENT_VERSION: String = "prototype_content_v4"
const SAVE_TYPE_SAFE_STATE: String = "safe_state_manual"
const SAVE_KEY_ACTIVE_TEMPLATE_ID: String = "active_map_template_id"
const SAVE_KEY_REALIZED_GRAPH: String = "map_realized_graph"
const SUPPORTED_NODE_FAMILIES := [
	"start",
	"combat",
	"event",
	"reward",
	"rest",
	"merchant",
	"blacksmith",
	"side_mission",
	"key",
	"boss",
]
const SUPPORTED_NODE_STATES := [
	"undiscovered",
	"discovered",
	"resolved",
	"locked",
]

func is_implemented_save_safe_now(state: int) -> bool:
	return FlowStateScript.is_implemented_save_safe_now(state)


func is_supported_save_state_now(state: int) -> bool:
	# Compatibility alias. Prefer is_implemented_save_safe_now().
	return is_implemented_save_safe_now(state)


func create_snapshot(
	save_path: String,
	active_flow_state: int,
	run_state_data: Dictionary,
	reward_state_data: Variant,
	level_up_state_data: Variant,
	support_interaction_state_data: Variant,
	app_state_data: Dictionary
) -> Dictionary:
	var normalized_path: String = _normalize_path(save_path)
	var timestamp: int = int(Time.get_unix_time_from_system())
	var created_at: int = _resolve_created_at(normalized_path, timestamp)

	return {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"content_version": CONTENT_VERSION,
		"created_at": created_at,
		"updated_at": timestamp,
		"save_type": SAVE_TYPE_SAFE_STATE,
		"active_flow_state": active_flow_state,
		"run_state": run_state_data.duplicate(true),
		"reward_state": _duplicate_variant(reward_state_data),
		"level_up_state": _duplicate_variant(level_up_state_data),
		"support_interaction_state": _duplicate_variant(support_interaction_state_data),
		"app_state": app_state_data.duplicate(true),
	}


func write_snapshot(save_path: String, snapshot: Dictionary) -> Dictionary:
	var validation: Dictionary = validate_snapshot(snapshot)
	if not bool(validation.get("ok", false)):
		validation["path"] = _normalize_path(save_path)
		return validation

	var normalized_path: String = _normalize_path(save_path)
	var file: FileAccess = FileAccess.open(normalized_path, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"error": "save_open_failed",
			"path": normalized_path,
		}

	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	return {
		"ok": true,
		"path": normalized_path,
		"active_flow_state": int(snapshot.get("active_flow_state", -1)),
	}


func load_snapshot(save_path: String) -> Dictionary:
	var normalized_path: String = _normalize_path(save_path)
	if not FileAccess.file_exists(normalized_path):
		return {
			"ok": false,
			"error": "save_file_missing",
			"path": normalized_path,
		}

	var snapshot_variant: Variant = _load_raw_snapshot(normalized_path)
	if typeof(snapshot_variant) != TYPE_DICTIONARY:
		return {
			"ok": false,
			"error": "invalid_save_root",
			"path": normalized_path,
		}

	var snapshot: Dictionary = snapshot_variant
	var validation: Dictionary = validate_snapshot(snapshot)
	if not bool(validation.get("ok", false)):
		validation["path"] = normalized_path
		return validation

	return {
		"ok": true,
		"path": normalized_path,
		"snapshot": snapshot.duplicate(true),
	}


func has_save_file(save_path: String) -> bool:
	return FileAccess.file_exists(_normalize_path(save_path))


func delete_save_file(save_path: String) -> Dictionary:
	var normalized_path: String = _normalize_path(save_path)
	if not FileAccess.file_exists(normalized_path):
		return {
			"ok": true,
			"deleted": false,
			"path": normalized_path,
		}

	var error_code: Error = DirAccess.remove_absolute(_absolute_path(normalized_path))
	return {
		"ok": error_code == OK,
		"deleted": error_code == OK,
		"error": "delete_failed" if error_code != OK else "",
		"path": normalized_path,
	}


func validate_snapshot(snapshot: Dictionary) -> Dictionary:
	var active_flow_state: int = int(snapshot.get("active_flow_state", -1))
	var save_schema_version: int = int(snapshot.get("save_schema_version", -1))
	if save_schema_version not in [
		LEGACY_SAVE_SCHEMA_VERSION,
		LEGACY_REWARD_SAVE_SCHEMA_VERSION,
		PREVIOUS_SAVE_SCHEMA_VERSION,
		SAVE_SCHEMA_VERSION,
	]:
		return {
			"ok": false,
			"error": "unsupported_save_schema_version",
		}
	var snapshot_content_version: String = String(snapshot.get("content_version", ""))
	if snapshot_content_version.is_empty():
		return {
			"ok": false,
			"error": "missing_content_version",
		}
	if snapshot_content_version != CONTENT_VERSION:
		return {
			"ok": false,
			"error": "unsupported_content_version",
			"content_version": snapshot_content_version,
		}
	if not is_implemented_save_safe_now(active_flow_state):
		return {
			"ok": false,
			"error": "unsupported_save_state",
			"active_flow_state": active_flow_state,
		}

	var run_state_variant: Variant = snapshot.get("run_state", null)
	if typeof(run_state_variant) != TYPE_DICTIONARY:
		return {
			"ok": false,
			"error": "missing_run_state",
		}

	var run_state_data: Dictionary = run_state_variant
	if int(run_state_data.get("player_hp", -1)) < 0:
		return {
			"ok": false,
			"error": "invalid_player_hp",
		}
	var current_node_id: int = int(run_state_data.get("current_node_id", run_state_data.get("current_node_index", -1)))
	if current_node_id < 0:
		return {
			"ok": false,
			"error": "invalid_current_node_index",
		}
	if save_schema_version >= SAVE_SCHEMA_VERSION:
		var run_seed: int = int(run_state_data.get("run_seed", 0))
		if run_seed <= 0:
			return {
				"ok": false,
				"error": "invalid_run_seed",
			}
		var rng_stream_states_variant: Variant = run_state_data.get("rng_stream_states", null)
		if typeof(rng_stream_states_variant) != TYPE_DICTIONARY or not _rng_stream_states_are_valid(rng_stream_states_variant as Dictionary):
			return {
				"ok": false,
				"error": "invalid_rng_stream_states",
			}
		var inventory_slots_variant: Variant = run_state_data.get("inventory_slots", null)
		if typeof(inventory_slots_variant) != TYPE_ARRAY or not _inventory_slots_are_valid(inventory_slots_variant as Array):
			return {
				"ok": false,
				"error": "invalid_inventory_slots",
			}
		if not _active_inventory_slot_is_valid(
			run_state_data,
			inventory_slots_variant as Array,
			"active_weapon_slot_id",
			"weapon"
		):
			return {
				"ok": false,
				"error": "invalid_active_weapon_slot",
			}
		if not _active_inventory_slot_is_valid(
			run_state_data,
			inventory_slots_variant as Array,
			"active_armor_slot_id",
			"armor",
			true
		):
			return {
				"ok": false,
				"error": "invalid_active_armor_slot",
			}
		if not _active_inventory_slot_is_valid(
			run_state_data,
			inventory_slots_variant as Array,
			"active_belt_slot_id",
			"belt",
			true
		):
			return {
				"ok": false,
				"error": "invalid_active_belt_slot",
			}
	var realized_graph_variant: Variant = run_state_data.get(SAVE_KEY_REALIZED_GRAPH, null)
	var has_realized_graph: bool = save_schema_version >= LEGACY_REWARD_SAVE_SCHEMA_VERSION or typeof(realized_graph_variant) == TYPE_ARRAY
	var realized_graph: Array = []
	if has_realized_graph:
		if typeof(realized_graph_variant) != TYPE_ARRAY or (realized_graph_variant as Array).is_empty():
			return {
				"ok": false,
				"error": "missing_map_realized_graph",
			}
		realized_graph = realized_graph_variant as Array
		if String(run_state_data.get(SAVE_KEY_ACTIVE_TEMPLATE_ID, "")).is_empty():
			return {
				"ok": false,
				"error": "missing_active_map_template_id",
			}
		if not _realized_graph_is_valid(realized_graph):
			return {
				"ok": false,
				"error": "invalid_map_realized_graph",
			}
		if not _realized_graph_contains_node(realized_graph, current_node_id):
			return {
				"ok": false,
				"error": "current_node_not_in_map",
			}
	var map_node_states_variant: Variant = run_state_data.get("map_node_states", null)
	if typeof(map_node_states_variant) != TYPE_ARRAY or (map_node_states_variant as Array).is_empty():
		return {
			"ok": false,
			"error": "missing_map_node_states",
		}
	if not has_realized_graph and not _map_node_states_contain_node(map_node_states_variant as Array, current_node_id):
		return {
			"ok": false,
			"error": "current_node_not_in_map",
		}
	if has_realized_graph and not _map_node_states_match_realized_graph(map_node_states_variant as Array, realized_graph):
		return {
			"ok": false,
			"error": "map_node_state_mismatch",
		}
	var support_node_states_variant: Variant = run_state_data.get("support_node_states", [])
	if typeof(support_node_states_variant) != TYPE_ARRAY:
		return {
			"ok": false,
			"error": "invalid_support_node_states",
		}
	if not _support_node_states_are_valid(
		support_node_states_variant as Array,
		map_node_states_variant as Array,
		realized_graph
	):
		return {
			"ok": false,
			"error": "invalid_support_node_states",
		}
	var side_mission_node_states_variant: Variant = run_state_data.get("side_mission_node_states", [])
	if save_schema_version >= SAVE_SCHEMA_VERSION and typeof(side_mission_node_states_variant) != TYPE_ARRAY:
		return {
			"ok": false,
			"error": "invalid_side_mission_node_states",
		}
	if typeof(side_mission_node_states_variant) == TYPE_ARRAY and not _side_mission_node_states_are_valid(
		side_mission_node_states_variant as Array,
		map_node_states_variant as Array,
		realized_graph
	):
		return {
			"ok": false,
			"error": "invalid_side_mission_node_states",
		}
	if int(run_state_data.get("pending_node_id", -1)) >= 0:
		return {
			"ok": false,
			"error": "unexpected_pending_node_id",
		}
	if not String(run_state_data.get("pending_node_type", "")).is_empty():
		return {
			"ok": false,
			"error": "unexpected_pending_node_type",
		}
	if save_schema_version < SAVE_SCHEMA_VERSION:
		var weapon_variant: Variant = run_state_data.get("weapon_instance", {})
		if typeof(weapon_variant) == TYPE_DICTIONARY and int((weapon_variant as Dictionary).get("current_durability", 0)) < 0:
			return {
				"ok": false,
				"error": "invalid_weapon_durability",
			}

	var reward_variant: Variant = snapshot.get("reward_state", null)
	var level_up_variant: Variant = snapshot.get("level_up_state", null)
	var support_interaction_variant: Variant = snapshot.get("support_interaction_state", null)
	var app_state_variant: Variant = snapshot.get("app_state", {})
	var app_state: Dictionary = app_state_variant if typeof(app_state_variant) == TYPE_DICTIONARY else {}
	match active_flow_state:
		FlowStateScript.Type.MAP_EXPLORE:
			if typeof(reward_variant) != TYPE_NIL or typeof(level_up_variant) != TYPE_NIL or typeof(support_interaction_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_pending_choice_state",
				}
		FlowStateScript.Type.REWARD:
			if typeof(reward_variant) != TYPE_DICTIONARY:
				return {
					"ok": false,
					"error": "missing_reward_state",
				}
			if typeof(level_up_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_level_up_state",
				}
			if typeof(support_interaction_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_support_interaction_state",
				}
			var reward_data: Dictionary = reward_variant
			if _extract_offer_count(reward_data) <= 0:
				return {
					"ok": false,
					"error": "empty_reward_offers",
				}
		FlowStateScript.Type.LEVEL_UP:
			if typeof(level_up_variant) != TYPE_DICTIONARY:
				return {
					"ok": false,
					"error": "missing_level_up_state",
				}
			if typeof(reward_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_reward_state",
				}
			if typeof(support_interaction_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_support_interaction_state",
				}
			var level_up_data: Dictionary = level_up_variant
			if _extract_offer_count(level_up_data) <= 0:
				return {
					"ok": false,
					"error": "empty_level_up_offers",
				}
		FlowStateScript.Type.SUPPORT_INTERACTION:
			if typeof(support_interaction_variant) != TYPE_DICTIONARY:
				return {
					"ok": false,
					"error": "missing_support_interaction_state",
				}
			if typeof(reward_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_reward_state",
				}
			if typeof(level_up_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_level_up_state",
				}
			var support_interaction_data: Dictionary = support_interaction_variant
			if _extract_offer_count(support_interaction_data) <= 0:
				return {
					"ok": false,
					"error": "empty_support_interaction_offers",
				}
			if not _support_interaction_state_is_valid(support_interaction_data):
				return {
					"ok": false,
					"error": "invalid_support_interaction_state",
				}
			if not _map_contains_node(
				int(support_interaction_data.get("source_node_id", -1)),
				map_node_states_variant as Array,
				realized_graph
			):
				return {
					"ok": false,
					"error": "invalid_support_interaction_source_node",
				}
		FlowStateScript.Type.STAGE_TRANSITION:
			if typeof(reward_variant) != TYPE_NIL or typeof(level_up_variant) != TYPE_NIL or typeof(support_interaction_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_pending_choice_state",
				}
		FlowStateScript.Type.RUN_END:
			if typeof(reward_variant) != TYPE_NIL or typeof(level_up_variant) != TYPE_NIL or typeof(support_interaction_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_pending_choice_state",
				}
			if String(app_state.get("last_run_result", "")).is_empty():
				return {
					"ok": false,
					"error": "missing_run_result",
				}
		_:
			return {
				"ok": false,
				"error": "unsupported_save_state",
				"active_flow_state": active_flow_state,
			}

	return {
		"ok": true,
	}


func _normalize_path(save_path: String) -> String:
	if save_path.is_empty():
		return DEFAULT_SAVE_PATH
	return save_path


func _resolve_created_at(save_path: String, fallback_timestamp: int) -> int:
	if not FileAccess.file_exists(save_path):
		return fallback_timestamp

	var snapshot_variant: Variant = _load_raw_snapshot(save_path)
	if typeof(snapshot_variant) != TYPE_DICTIONARY:
		return fallback_timestamp

	return int((snapshot_variant as Dictionary).get("created_at", fallback_timestamp))


func _absolute_path(path: String) -> String:
	if path.begins_with("user://") or path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	return path


func _load_raw_snapshot(save_path: String) -> Variant:
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return null

	var raw_text: String = file.get_as_text()
	file.close()
	return JSON.parse_string(raw_text)


func _duplicate_variant(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			return (value as Dictionary).duplicate(true)
		TYPE_ARRAY:
			return (value as Array).duplicate(true)
		TYPE_NIL:
			return null
		_:
			return value


func _extract_offer_count(state_data: Dictionary) -> int:
	var offers_variant: Variant = state_data.get("offers", [])
	if typeof(offers_variant) != TYPE_ARRAY:
		return 0
	return (offers_variant as Array).size()


func _map_node_states_contain_node(map_node_states: Array, node_id: int) -> bool:
	for entry_variant in map_node_states:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		if int((entry_variant as Dictionary).get("node_id", -1)) == node_id:
			return true
	return false


func _support_node_states_are_valid(support_node_states: Array, map_node_states: Array, realized_graph: Array = []) -> bool:
	var support_families_by_node_id: Dictionary = _build_support_family_lookup(realized_graph)
	for entry_variant in support_node_states:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return false
		var entry: Dictionary = entry_variant
		var node_id: int = int(entry.get("node_id", -1))
		if not _map_contains_node(node_id, map_node_states, realized_graph):
			return false
		var support_type: String = String(entry.get("support_type", ""))
		if support_type not in ["rest", "merchant", "blacksmith"]:
			return false
		if not support_families_by_node_id.is_empty() and String(support_families_by_node_id.get(node_id, "")) != support_type:
			return false
		var unavailable_ids_variant: Variant = entry.get("unavailable_offer_ids", [])
		if typeof(unavailable_ids_variant) != TYPE_ARRAY:
			return false
		for offer_id_variant in unavailable_ids_variant:
			if String(offer_id_variant).is_empty():
				return false
	return true


func _side_mission_node_states_are_valid(side_mission_node_states: Array, map_node_states: Array, realized_graph: Array = []) -> bool:
	var side_mission_families_by_node_id: Dictionary = _build_side_mission_family_lookup(realized_graph)
	for entry_variant in side_mission_node_states:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return false
		var entry: Dictionary = entry_variant
		var node_id: int = int(entry.get("node_id", -1))
		if not _map_contains_node(node_id, map_node_states, realized_graph):
			return false
		if not side_mission_families_by_node_id.is_empty() and String(side_mission_families_by_node_id.get(node_id, "")) != "side_mission":
			return false
		var mission_definition_id: String = String(entry.get("mission_definition_id", "")).strip_edges()
		if mission_definition_id.is_empty():
			return false
		var mission_status: String = String(entry.get("mission_status", ""))
		if mission_status not in ["offered", "accepted", "completed", "claimed"]:
			return false
		var target_node_id: int = int(entry.get("target_node_id", -1))
		var target_enemy_definition_id: String = String(entry.get("target_enemy_definition_id", "")).strip_edges()
		if target_node_id >= 0:
			if not _map_contains_node(target_node_id, map_node_states, realized_graph):
				return false
			if not _realized_graph_node_matches_family(realized_graph, target_node_id, "combat"):
				return false
			if target_enemy_definition_id.is_empty():
				return false
		elif mission_status in ["accepted", "completed"]:
			return false
		var reward_offers_variant: Variant = entry.get("reward_offers", [])
		if typeof(reward_offers_variant) != TYPE_ARRAY:
			return false
		for offer_variant in reward_offers_variant:
			if typeof(offer_variant) != TYPE_DICTIONARY:
				return false
			var offer: Dictionary = offer_variant
			if String(offer.get("offer_id", "")).strip_edges().is_empty():
				return false
			if String(offer.get("definition_id", "")).strip_edges().is_empty():
				return false
			if String(offer.get("inventory_family", "")) not in ["weapon", "armor"]:
				return false
	return true


func _map_contains_node(node_id: int, map_node_states: Array, realized_graph: Array) -> bool:
	if _map_node_states_contain_node(map_node_states, node_id):
		return true
	return _realized_graph_contains_node(realized_graph, node_id)


func _map_node_states_match_realized_graph(map_node_states: Array, realized_graph: Array) -> bool:
	var realized_states_by_node_id: Dictionary = {}
	for entry_variant in realized_graph:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return false
		var entry: Dictionary = entry_variant
		realized_states_by_node_id[int(entry.get("node_id", -1))] = String(entry.get("node_state", ""))

	for state_entry_variant in map_node_states:
		if typeof(state_entry_variant) != TYPE_DICTIONARY:
			return false
		var state_entry: Dictionary = state_entry_variant
		var node_id: int = int(state_entry.get("node_id", -1))
		if not realized_states_by_node_id.has(node_id):
			return false
		if String(state_entry.get("node_state", "")) != String(realized_states_by_node_id.get(node_id, "")):
			return false

	return realized_states_by_node_id.size() == map_node_states.size()


func _realized_graph_contains_node(realized_graph: Array, node_id: int) -> bool:
	for entry_variant in realized_graph:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		if int((entry_variant as Dictionary).get("node_id", -1)) == node_id:
			return true
	return false


func _realized_graph_is_valid(realized_graph: Array) -> bool:
	var families_by_node_id: Dictionary = {}
	var adjacency_by_node_id: Dictionary = {}
	var family_counts: Dictionary = {}

	for entry_variant in realized_graph:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return false
		var entry: Dictionary = entry_variant
		var node_id: int = int(entry.get("node_id", -1))
		if node_id < 0 or families_by_node_id.has(node_id):
			return false

		var node_family: String = String(entry.get("node_family", ""))
		if node_family not in SUPPORTED_NODE_FAMILIES:
			return false
		var node_state: String = String(entry.get("node_state", ""))
		if node_state not in SUPPORTED_NODE_STATES:
			return false

		var adjacent_node_ids: Array[int] = _variant_to_node_id_array(entry.get("adjacent_node_ids", []))
		if adjacent_node_ids.is_empty() and node_family != "boss":
			return false
		var seen_adjacent_ids: Dictionary = {}
		for adjacent_node_id in adjacent_node_ids:
			if adjacent_node_id < 0 or adjacent_node_id == node_id or seen_adjacent_ids.has(adjacent_node_id):
				return false
			seen_adjacent_ids[adjacent_node_id] = true

		families_by_node_id[node_id] = node_family
		adjacency_by_node_id[node_id] = adjacent_node_ids
		family_counts[node_family] = int(family_counts.get(node_family, 0)) + 1

	if String(families_by_node_id.get(0, "")) != "start":
		return false
	if int(family_counts.get("start", 0)) != 1:
		return false
	if int(family_counts.get("boss", 0)) != 1:
		return false
	if int(family_counts.get("key", 0)) != 1:
		return false
	if int(family_counts.get("event", 0)) != 1:
		return false
	if int(family_counts.get("reward", 0)) != 1:
		return false
	if int(family_counts.get("side_mission", 0)) != 1:
		return false
	if int(family_counts.get("combat", 0)) != 6:
		return false
	var support_node_count: int = (
		int(family_counts.get("rest", 0))
		+ int(family_counts.get("merchant", 0))
		+ int(family_counts.get("blacksmith", 0))
	)
	if support_node_count != 2:
		return false
	var prep_valve_count: int = int(family_counts.get("rest", 0)) + int(family_counts.get("blacksmith", 0))
	if prep_valve_count < 1:
		return false

	for node_id in adjacency_by_node_id.keys():
		var adjacent_node_ids: Array[int] = _variant_to_node_id_array(adjacency_by_node_id.get(node_id, []))
		for adjacent_node_id in adjacent_node_ids:
			if not adjacency_by_node_id.has(adjacent_node_id):
				return false
			var reverse_adjacent_ids: Array[int] = _variant_to_node_id_array(adjacency_by_node_id.get(adjacent_node_id, []))
			if not reverse_adjacent_ids.has(node_id):
				return false

	if not _realized_graph_is_connected_to_start(adjacency_by_node_id):
		return false

	return true


func _realized_graph_is_connected_to_start(adjacency_by_node_id: Dictionary) -> bool:
	if not adjacency_by_node_id.has(0):
		return false

	var visited: Dictionary = {}
	var queued_node_ids: Array[int] = [0]
	while not queued_node_ids.is_empty():
		var node_id: int = queued_node_ids.pop_front()
		if visited.has(node_id):
			continue
		visited[node_id] = true
		for adjacent_node_id in _variant_to_node_id_array(adjacency_by_node_id.get(node_id, [])):
			if not visited.has(adjacent_node_id):
				queued_node_ids.append(adjacent_node_id)

	return visited.size() == adjacency_by_node_id.size()


func _build_support_family_lookup(realized_graph: Array) -> Dictionary:
	var support_families_by_node_id: Dictionary = {}
	for entry_variant in realized_graph:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		var node_family: String = String(entry.get("node_family", ""))
		if node_family in ["rest", "merchant", "blacksmith"]:
			support_families_by_node_id[int(entry.get("node_id", -1))] = node_family
	return support_families_by_node_id


func _build_side_mission_family_lookup(realized_graph: Array) -> Dictionary:
	var side_mission_families_by_node_id: Dictionary = {}
	for entry_variant in realized_graph:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		if String(entry.get("node_family", "")) == "side_mission":
			side_mission_families_by_node_id[int(entry.get("node_id", -1))] = "side_mission"
	return side_mission_families_by_node_id


func _realized_graph_node_matches_family(realized_graph: Array, node_id: int, expected_family: String) -> bool:
	for entry_variant in realized_graph:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		if int(entry.get("node_id", -1)) != node_id:
			continue
		return String(entry.get("node_family", "")) == expected_family
	return false


func _variant_to_node_id_array(value: Variant) -> Array[int]:
	var node_ids: Array[int] = []
	match typeof(value):
		TYPE_ARRAY:
			for entry in value:
				node_ids.append(int(entry))
		TYPE_PACKED_INT32_ARRAY:
			for entry in value:
				node_ids.append(int(entry))
		_:
			return node_ids
	return node_ids


func _rng_stream_states_are_valid(stream_states: Dictionary) -> bool:
	for key_variant in stream_states.keys():
		var stream_name: String = String(key_variant).strip_edges()
		if stream_name.is_empty():
			return false
		if int(stream_states.get(key_variant, -1)) < 0:
			return false
	return true


func _inventory_slots_are_valid(inventory_slots: Array) -> bool:
	var seen_slot_ids: Dictionary = {}
	for entry_variant in inventory_slots:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return false
		var entry: Dictionary = entry_variant
		var slot_id: int = int(entry.get("slot_id", -1))
		if slot_id <= 0 or seen_slot_ids.has(slot_id):
			return false
		seen_slot_ids[slot_id] = true

		var inventory_family: String = String(entry.get("inventory_family", ""))
		if inventory_family not in ["weapon", "armor", "belt", "consumable", "passive"]:
			return false
		if String(entry.get("definition_id", "")).is_empty():
			return false
		if inventory_family == "weapon" and int(entry.get("current_durability", 0)) < 0:
			return false
		if inventory_family in ["weapon", "armor"] and int(entry.get("upgrade_level", 0)) < 0:
			return false
		if inventory_family == "consumable" and int(entry.get("current_stack", 0)) <= 0:
			return false
	return true


func _support_interaction_state_is_valid(support_interaction_data: Dictionary) -> bool:
	var support_type: String = String(support_interaction_data.get("support_type", ""))
	if support_type not in ["rest", "merchant", "blacksmith", "side_mission"]:
		return false
	if support_type == "side_mission":
		var mission_status: String = String(support_interaction_data.get("mission_status", ""))
		if mission_status not in ["offered", "accepted", "completed", "claimed"]:
			return false
		var reward_offers_variant: Variant = support_interaction_data.get("reward_offers", [])
		if typeof(reward_offers_variant) != TYPE_ARRAY:
			return false
		return true
	if support_type != "blacksmith":
		return true

	var blacksmith_view_mode: String = String(support_interaction_data.get("blacksmith_view_mode", "services"))
	if blacksmith_view_mode not in ["services", "weapon_targets", "armor_targets"]:
		return false
	return int(support_interaction_data.get("blacksmith_target_page", 0)) >= 0


func _active_inventory_slot_is_valid(
	run_state_data: Dictionary,
	inventory_slots: Array,
	key_name: String,
	required_family: String,
	allow_empty: bool = false
) -> bool:
	var slot_id: int = int(run_state_data.get(key_name, -1))
	if slot_id < 0:
		return allow_empty
	for entry_variant in inventory_slots:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		if int(entry.get("slot_id", -1)) != slot_id:
			continue
		return String(entry.get("inventory_family", "")) == required_family
	return false
