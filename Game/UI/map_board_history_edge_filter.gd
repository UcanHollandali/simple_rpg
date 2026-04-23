# Layer: UI
extends RefCounted
class_name MapBoardHistoryEdgeFilter

const MapBoardGeometryScript = preload("res://Game/UI/map_board_geometry.gd")


static func filter_non_crossing_history_edges(
	local_focus_edges: Array[Dictionary],
	history_edges: Array[Dictionary]
) -> Array[Dictionary]:
	var sorted_history_edges: Array[Dictionary] = history_edges.duplicate(true)
	sorted_history_edges.sort_custom(func(left_edge: Dictionary, right_edge: Dictionary) -> bool:
		return MapBoardGeometryScript.compare_visible_edge_priority(left_edge, right_edge)
	)
	var filtered_history_edges: Array[Dictionary] = []
	for edge_entry in sorted_history_edges:
		var conflicting_history_indexes: Array[int] = MapBoardGeometryScript.conflicting_visible_edge_indexes(edge_entry, filtered_history_edges)
		if conflicting_history_indexes.is_empty():
			if MapBoardGeometryScript.visible_edge_crosses_any(edge_entry, local_focus_edges):
				continue
			filtered_history_edges.append(edge_entry)
			continue
		if bool(edge_entry.get("is_reconnect_edge", false)) or MapBoardGeometryScript.visible_edge_crosses_any(edge_entry, local_focus_edges):
			continue
		var can_replace_reconnects: bool = true
		for edge_index in conflicting_history_indexes:
			if not bool((filtered_history_edges[edge_index] as Dictionary).get("is_reconnect_edge", false)):
				can_replace_reconnects = false
				break
		if not can_replace_reconnects:
			continue
		MapBoardGeometryScript.remove_visible_edges_at_indexes(filtered_history_edges, conflicting_history_indexes)
		filtered_history_edges.append(edge_entry)
	var has_same_depth_reconnect: bool = false
	for edge_entry in filtered_history_edges:
		if bool(edge_entry.get("is_reconnect_edge", false)) and int(edge_entry.get("depth_delta", 1)) == 0:
			has_same_depth_reconnect = true
			break
	if has_same_depth_reconnect:
		return filtered_history_edges
	var accepted_edge_keys: Dictionary = {}
	for edge_entry in filtered_history_edges:
		accepted_edge_keys[_edge_key(int(edge_entry.get("from_node_id", -1)), int(edge_entry.get("to_node_id", -1)))] = true
	for edge_entry in sorted_history_edges:
		if not bool(edge_entry.get("is_reconnect_edge", false)) or int(edge_entry.get("depth_delta", 1)) != 0:
			continue
		var edge_key: String = _edge_key(int(edge_entry.get("from_node_id", -1)), int(edge_entry.get("to_node_id", -1)))
		if accepted_edge_keys.has(edge_key) or MapBoardGeometryScript.visible_edge_crosses_any(edge_entry, local_focus_edges):
			continue
		var conflicting_history_indexes: Array[int] = MapBoardGeometryScript.conflicting_visible_edge_indexes(edge_entry, filtered_history_edges)
		if not conflicting_history_indexes.is_empty():
			if filtered_history_edges.size() - conflicting_history_indexes.size() < 2:
				continue
			MapBoardGeometryScript.remove_visible_edges_at_indexes(filtered_history_edges, conflicting_history_indexes)
		filtered_history_edges.append(edge_entry)
		break
	return filtered_history_edges


static func _edge_key(from_node_id: int, to_node_id: int) -> String:
	var ordered_ids: Array[int] = [from_node_id, to_node_id]
	ordered_ids.sort()
	return "%d:%d" % [ordered_ids[0], ordered_ids[1]]
