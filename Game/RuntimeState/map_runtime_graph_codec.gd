# Layer: RuntimeState helper
extends RefCounted
class_name MapRuntimeGraphCodec


func extract_realized_graph_array(value: Variant) -> Array[Dictionary]:
	var realized_graph: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return realized_graph

	for entry_variant in value:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		realized_graph.append((entry_variant as Dictionary).duplicate(true))
	return realized_graph


func build_graph_from_realized_payload(
	realized_graph: Array[Dictionary],
	no_pending_node_id: int,
	node_state_undiscovered: String,
	legacy_node_family_side_mission: String,
	node_family_hamlet: String
) -> Array[Dictionary]:
	var graph: Array[Dictionary] = []
	for entry in realized_graph:
		var node_family: String = _normalize_loaded_node_family(
			String(entry.get("node_family", "")),
			legacy_node_family_side_mission,
			node_family_hamlet
		)
		if node_family.is_empty():
			continue
		graph.append({
			"node_id": int(entry.get("node_id", no_pending_node_id)),
			"node_family": node_family,
			"node_state": String(entry.get("node_state", node_state_undiscovered)),
			"adjacent_node_ids": _coerce_adjacent_ids(entry.get("adjacent_node_ids", [])),
		})
	graph.sort_custom(Callable(self, "_sort_graph_nodes_by_id"))
	return graph


func build_node_state_save_payload(node_graph: Array[Dictionary], no_pending_node_id: int, node_state_undiscovered: String) -> Array[Dictionary]:
	var node_states: Array[Dictionary] = []
	for node_data in node_graph:
		node_states.append({
			"node_id": int(node_data.get("node_id", no_pending_node_id)),
			"node_state": String(node_data.get("node_state", node_state_undiscovered)),
		})
	return node_states


func build_support_node_state_save_payload(support_node_states: Dictionary) -> Array[Dictionary]:
	var support_states: Array[Dictionary] = []
	for node_id in support_node_states.keys():
		support_states.append({
			"node_id": int(node_id),
		}.merged((support_node_states[node_id] as Dictionary).duplicate(true), true))
	return support_states


func build_side_mission_node_state_save_payload(side_mission_node_states: Dictionary) -> Array[Dictionary]:
	var mission_states: Array[Dictionary] = []
	for node_id in side_mission_node_states.keys():
		mission_states.append({
			"node_id": int(node_id),
		}.merged((side_mission_node_states[node_id] as Dictionary).duplicate(true), true))
	return mission_states


func build_realized_graph_save_payload(
	node_graph: Array[Dictionary],
	no_pending_node_id: int,
	node_state_undiscovered: String
) -> Array[Dictionary]:
	var realized_graph: Array[Dictionary] = []
	for node_data in node_graph:
		realized_graph.append({
			"node_id": int(node_data.get("node_id", no_pending_node_id)),
			"node_family": String(node_data.get("node_family", "")),
			"node_state": String(node_data.get("node_state", node_state_undiscovered)),
			"adjacent_node_ids": _coerce_adjacent_ids(node_data.get("adjacent_node_ids", [])),
		})
	return realized_graph


func _normalize_loaded_node_family(
	node_family: String,
	legacy_node_family_side_mission: String,
	node_family_hamlet: String
) -> String:
	if node_family == legacy_node_family_side_mission:
		return node_family_hamlet
	return node_family


func _sort_graph_nodes_by_id(left: Dictionary, right: Dictionary) -> bool:
	return int(left.get("node_id", -1)) < int(right.get("node_id", -1))


func _coerce_adjacent_ids(adjacent_variant: Variant) -> PackedInt32Array:
	if typeof(adjacent_variant) == TYPE_PACKED_INT32_ARRAY:
		return adjacent_variant

	var adjacent_ids: PackedInt32Array = PackedInt32Array()
	if typeof(adjacent_variant) == TYPE_ARRAY:
		for value in adjacent_variant:
			adjacent_ids.append(int(value))
	return adjacent_ids
