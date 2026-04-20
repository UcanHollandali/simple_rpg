# Layer: UI
extends RefCounted
class_name MapBoardGeometry


static func visible_edge_polyline_length(edge_entry: Dictionary) -> float:
	var points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
	if points.size() < 2:
		return 0.0
	var total_length: float = 0.0
	for point_index in range(points.size() - 1):
		total_length += points[point_index].distance_to(points[point_index + 1])
	return total_length


static func visible_edge_crosses_any(candidate_edge: Dictionary, accepted_edges: Array[Dictionary]) -> bool:
	for edge_entry in accepted_edges:
		if visible_edges_share_node(candidate_edge, edge_entry):
			continue
		if visible_edge_polylines_intersect(candidate_edge, edge_entry):
			return true
	return false


static func conflicting_visible_edge_indexes(candidate_edge: Dictionary, accepted_edges: Array[Dictionary]) -> Array[int]:
	var conflicting_indexes: Array[int] = []
	for edge_index in range(accepted_edges.size()):
		var edge_entry: Dictionary = accepted_edges[edge_index]
		if visible_edges_share_node(candidate_edge, edge_entry):
			continue
		if visible_edge_polylines_intersect(candidate_edge, edge_entry):
			conflicting_indexes.append(edge_index)
	return conflicting_indexes


static func remove_visible_edges_at_indexes(edges: Array[Dictionary], indexes_to_remove: Array[int]) -> void:
	var sorted_indexes: Array[int] = indexes_to_remove.duplicate()
	sorted_indexes.sort()
	for remove_offset in range(sorted_indexes.size() - 1, -1, -1):
		edges.remove_at(sorted_indexes[remove_offset])


static func compare_visible_edge_priority(left_edge: Dictionary, right_edge: Dictionary) -> bool:
	var left_depth_delta: int = int(left_edge.get("depth_delta", 1))
	var right_depth_delta: int = int(right_edge.get("depth_delta", 1))
	if left_depth_delta != right_depth_delta:
		return left_depth_delta < right_depth_delta
	var left_length: float = visible_edge_polyline_length(left_edge)
	var right_length: float = visible_edge_polyline_length(right_edge)
	if not is_equal_approx(left_length, right_length):
		return left_length < right_length
	return _visible_edge_key(left_edge) < _visible_edge_key(right_edge)


static func visible_edges_share_node(left_edge: Dictionary, right_edge: Dictionary) -> bool:
	var left_ids: Array[int] = [int(left_edge.get("from_node_id", -1)), int(left_edge.get("to_node_id", -1))]
	var right_ids: Array[int] = [int(right_edge.get("from_node_id", -1)), int(right_edge.get("to_node_id", -1))]
	for left_id in left_ids:
		if left_id in right_ids:
			return true
	return false


static func visible_edge_polylines_intersect(left_edge: Dictionary, right_edge: Dictionary) -> bool:
	var left_points: PackedVector2Array = left_edge.get("points", PackedVector2Array())
	var right_points: PackedVector2Array = right_edge.get("points", PackedVector2Array())
	if left_points.size() < 2 or right_points.size() < 2:
		return false
	for left_segment_index in range(left_points.size() - 1):
		for right_segment_index in range(right_points.size() - 1):
			if segments_intersect(
				left_points[left_segment_index],
				left_points[left_segment_index + 1],
				right_points[right_segment_index],
				right_points[right_segment_index + 1]
			):
				return true
	return false


static func polyline_hits_other_visible_nodes(
	points: PackedVector2Array,
	from_node_id: int,
	to_node_id: int,
	visible_nodes: Array[Dictionary],
	padding: float
) -> bool:
	for node_entry in visible_nodes:
		var node_id: int = int(node_entry.get("node_id", -1))
		if node_id == from_node_id or node_id == to_node_id:
			continue
		var node_center: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
		var required_clearance: float = float(node_entry.get("clearing_radius", 0.0)) + padding
		if polyline_distance_to_point(points, node_center) < required_clearance:
			return true
	return false


static func edge_node_avoidance_offset(
	points: PackedVector2Array,
	from_node_id: int,
	to_node_id: int,
	visible_nodes: Array[Dictionary],
	start_point: Vector2,
	end_point: Vector2,
	midpoint: Vector2,
	padding: float,
	min_shift: float,
	max_shift: float
) -> Vector2:
	var total_offset: Vector2 = Vector2.ZERO
	var chord_direction: Vector2 = end_point - start_point
	if chord_direction.length_squared() <= 0.001:
		chord_direction = Vector2.RIGHT
	else:
		chord_direction = chord_direction.normalized()
	var chord_normal: Vector2 = Vector2(-chord_direction.y, chord_direction.x)
	for node_entry in visible_nodes:
		var node_id: int = int(node_entry.get("node_id", -1))
		if node_id == from_node_id or node_id == to_node_id:
			continue
		var node_center: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
		var required_clearance: float = float(node_entry.get("clearing_radius", 0.0)) + padding
		var actual_distance: float = polyline_distance_to_point(points, node_center)
		if actual_distance >= required_clearance:
			continue
		var away_direction: Vector2 = midpoint - node_center
		if away_direction.length_squared() <= 0.001:
			away_direction = chord_normal
		var overlap: float = required_clearance - actual_distance
		var blocker_side: float = chord_normal.dot(node_center - midpoint)
		var lateral_sign: float = -1.0 if blocker_side >= 0.0 else 1.0
		var lateral_offset: Vector2 = chord_normal * overlap * lateral_sign
		var radial_offset: Vector2 = away_direction.normalized() * overlap * 0.60
		total_offset += lateral_offset + radial_offset
	if total_offset.length_squared() <= 0.001:
		return Vector2.ZERO
	return total_offset.normalized() * clampf(total_offset.length(), min_shift, max_shift)


static func polyline_distance_to_point(points: PackedVector2Array, point: Vector2) -> float:
	if points.is_empty():
		return INF
	if points.size() == 1:
		return points[0].distance_to(point)
	var closest_distance: float = INF
	for point_index in range(points.size() - 1):
		closest_distance = min(
			closest_distance,
			distance_point_to_segment(point, points[point_index], points[point_index + 1])
		)
	return closest_distance


static func distance_point_to_segment(point: Vector2, start_point: Vector2, end_point: Vector2) -> float:
	var segment: Vector2 = end_point - start_point
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= 0.001:
		return point.distance_to(start_point)
	var t: float = clampf((point - start_point).dot(segment) / segment_length_squared, 0.0, 1.0)
	var projection: Vector2 = start_point + segment * t
	return point.distance_to(projection)


static func segments_intersect(a0: Vector2, a1: Vector2, b0: Vector2, b1: Vector2) -> bool:
	var a0_to_b0: Vector2 = b0 - a0
	var a0_to_b1: Vector2 = b1 - a0
	var a0_to_a1: Vector2 = a1 - a0
	var b0_to_a0: Vector2 = a0 - b0
	var b0_to_a1: Vector2 = a1 - b0
	var b0_to_b1: Vector2 = b1 - b0
	var d1: float = a0_to_a1.cross(a0_to_b0)
	var d2: float = a0_to_a1.cross(a0_to_b1)
	var d3: float = b0_to_b1.cross(b0_to_a0)
	var d4: float = b0_to_b1.cross(b0_to_a1)
	return segment_straddles(d1, d2) and segment_straddles(d3, d4)


static func segment_straddles(left: float, right: float) -> bool:
	return (left > 0.0 and right < 0.0) or (left < 0.0 and right > 0.0)


static func _visible_edge_key(edge_entry: Dictionary) -> String:
	var from_node_id: int = int(edge_entry.get("from_node_id", -1))
	var to_node_id: int = int(edge_entry.get("to_node_id", -1))
	return "%d:%d" % [min(from_node_id, to_node_id), max(from_node_id, to_node_id)]
