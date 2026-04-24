# Layer: UI
extends RefCounted
class_name MapBoardHistoryEdgeFilter

const MapBoardGeometryScript = preload("res://Game/UI/map_board_geometry.gd")
const BRAID_DIRECTION_ALIGNMENT_FLOOR := 0.90
const BRAID_MAX_SEPARATION := 34.0
const BRAID_MIN_OVERLAP := 112.0


static func filter_non_crossing_history_edges(
	local_focus_edges: Array[Dictionary],
	history_edges: Array[Dictionary]
) -> Array[Dictionary]:
	var sorted_history_edges: Array[Dictionary] = history_edges.duplicate(true)
	sorted_history_edges.sort_custom(func(left_edge: Dictionary, right_edge: Dictionary) -> bool:
		var left_priority: int = _history_edge_priority(left_edge)
		var right_priority: int = _history_edge_priority(right_edge)
		if left_priority != right_priority:
			return left_priority > right_priority
		return MapBoardGeometryScript.compare_visible_edge_priority(left_edge, right_edge)
	)
	var filtered_history_edges: Array[Dictionary] = []
	for edge_entry in sorted_history_edges:
		var conflicting_history_indexes: Array[int] = _conflicting_history_indexes(edge_entry, filtered_history_edges)
		if conflicting_history_indexes.is_empty():
			if _history_edge_conflicts_with_visible_set(edge_entry, local_focus_edges):
				continue
			filtered_history_edges.append(edge_entry)
			continue
		if bool(edge_entry.get("is_reconnect_edge", false)) or _history_edge_conflicts_with_visible_set(edge_entry, local_focus_edges):
			continue
		var can_replace_conflicts: bool = true
		var candidate_priority: int = _history_edge_priority(edge_entry)
		for edge_index in conflicting_history_indexes:
			var accepted_edge: Dictionary = filtered_history_edges[edge_index] as Dictionary
			if _history_edge_priority(accepted_edge) >= candidate_priority:
				can_replace_conflicts = false
				break
		if not can_replace_conflicts:
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
		if accepted_edge_keys.has(edge_key) or _history_edge_conflicts_with_visible_set(edge_entry, local_focus_edges):
			continue
		var conflicting_history_indexes: Array[int] = _conflicting_history_indexes(edge_entry, filtered_history_edges)
		if not conflicting_history_indexes.is_empty():
			if filtered_history_edges.size() - conflicting_history_indexes.size() < 2:
				continue
			MapBoardGeometryScript.remove_visible_edges_at_indexes(filtered_history_edges, conflicting_history_indexes)
		filtered_history_edges.append(edge_entry)
		break
	return filtered_history_edges


static func _history_edge_conflicts_with_visible_set(candidate_edge: Dictionary, accepted_edges: Array[Dictionary]) -> bool:
	return MapBoardGeometryScript.visible_edge_crosses_any(candidate_edge, accepted_edges) or _visible_edge_braids_any(candidate_edge, accepted_edges)


static func _conflicting_history_indexes(candidate_edge: Dictionary, accepted_edges: Array[Dictionary]) -> Array[int]:
	var conflicting_indexes: Array[int] = MapBoardGeometryScript.conflicting_visible_edge_indexes(candidate_edge, accepted_edges)
	for edge_index in range(accepted_edges.size()):
		if edge_index in conflicting_indexes:
			continue
		var accepted_edge: Dictionary = accepted_edges[edge_index]
		if _visible_edges_form_braid(candidate_edge, accepted_edge):
			conflicting_indexes.append(edge_index)
	return conflicting_indexes


static func _history_edge_priority(edge_entry: Dictionary) -> int:
	match String(edge_entry.get("corridor_role_semantic", edge_entry.get("route_surface_semantic", ""))):
		"branch_history_corridor":
			return 2
		"history_corridor", "history":
			return 1
		_:
			return 0 if bool(edge_entry.get("is_reconnect_edge", false)) else 1


static func _visible_edge_braids_any(candidate_edge: Dictionary, accepted_edges: Array[Dictionary]) -> bool:
	for edge_entry in accepted_edges:
		if _visible_edges_form_braid(candidate_edge, edge_entry):
			return true
	return false


static func _visible_edges_form_braid(left_edge: Dictionary, right_edge: Dictionary) -> bool:
	if MapBoardGeometryScript.visible_edges_share_node(left_edge, right_edge):
		return false
	if MapBoardGeometryScript.visible_edge_polylines_intersect(left_edge, right_edge):
		return false
	var left_points: PackedVector2Array = left_edge.get("points", PackedVector2Array())
	var right_points: PackedVector2Array = right_edge.get("points", PackedVector2Array())
	if left_points.size() < 2 or right_points.size() < 2:
		return false
	var left_direction: Vector2 = (left_points[left_points.size() - 1] - left_points[0]).normalized()
	var right_direction: Vector2 = (right_points[right_points.size() - 1] - right_points[0]).normalized()
	if left_direction == Vector2.ZERO or right_direction == Vector2.ZERO:
		return false
	if absf(left_direction.dot(right_direction)) < BRAID_DIRECTION_ALIGNMENT_FLOOR:
		return false
	if _minimum_polyline_pair_distance(left_points, right_points) > BRAID_MAX_SEPARATION:
		return false
	return _polyline_projection_overlap(left_points, right_points, left_direction) >= BRAID_MIN_OVERLAP


static func _minimum_polyline_pair_distance(left_points: PackedVector2Array, right_points: PackedVector2Array) -> float:
	var minimum_distance: float = INF
	for point in left_points:
		minimum_distance = minf(minimum_distance, MapBoardGeometryScript.polyline_distance_to_point(right_points, point))
	for point in right_points:
		minimum_distance = minf(minimum_distance, MapBoardGeometryScript.polyline_distance_to_point(left_points, point))
	return minimum_distance


static func _polyline_projection_overlap(left_points: PackedVector2Array, right_points: PackedVector2Array, axis: Vector2) -> float:
	var left_min: float = INF
	var left_max: float = -INF
	for point in left_points:
		var projection: float = point.dot(axis)
		left_min = minf(left_min, projection)
		left_max = maxf(left_max, projection)
	var right_min: float = INF
	var right_max: float = -INF
	for point in right_points:
		var projection: float = point.dot(axis)
		right_min = minf(right_min, projection)
		right_max = maxf(right_max, projection)
	return maxf(0.0, minf(left_max, right_max) - maxf(left_min, right_min))


static func _edge_key(from_node_id: int, to_node_id: int) -> String:
	var ordered_ids: Array[int] = [from_node_id, to_node_id]
	ordered_ids.sort()
	return "%d:%d" % [ordered_ids[0], ordered_ids[1]]
