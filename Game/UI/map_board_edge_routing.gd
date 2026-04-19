# Layer: UI
extends RefCounted
class_name MapBoardEdgeRouting

const MapBoardGeometryScript = preload("res://Game/UI/map_board_geometry.gd")


static func build_outer_reconnect_fallback_points(
	p0: Vector2,
	p3: Vector2,
	visible_nodes: Array[Dictionary],
	from_node_id: int,
	to_node_id: int,
	board_size: Vector2,
	min_board_margin: Vector2,
	edge_padding: float
) -> PackedVector2Array:
	var lane_inset_x: float = clampf(min_board_margin.x * 0.62, 72.0, max(72.0, board_size.x * 0.18))
	var lane_inset_y: float = clampf(min_board_margin.y * 0.62, 84.0, max(84.0, board_size.y * 0.18))
	var left_x: float = lane_inset_x
	var right_x: float = board_size.x - lane_inset_x
	var top_y: float = lane_inset_y
	var bottom_y: float = board_size.y - lane_inset_y
	var candidates: Array[Dictionary] = []
	_append_outer_reconnect_candidate(
		candidates,
		PackedVector2Array([p0, Vector2(p0.x, top_y), Vector2(p3.x, top_y), p3]),
		visible_nodes,
		from_node_id,
		to_node_id,
		edge_padding
	)
	_append_outer_reconnect_candidate(
		candidates,
		PackedVector2Array([p0, Vector2(p0.x, bottom_y), Vector2(p3.x, bottom_y), p3]),
		visible_nodes,
		from_node_id,
		to_node_id,
		edge_padding
	)
	_append_outer_reconnect_candidate(
		candidates,
		PackedVector2Array([p0, Vector2(left_x, p0.y), Vector2(left_x, p3.y), p3]),
		visible_nodes,
		from_node_id,
		to_node_id,
		edge_padding
	)
	_append_outer_reconnect_candidate(
		candidates,
		PackedVector2Array([p0, Vector2(right_x, p0.y), Vector2(right_x, p3.y), p3]),
		visible_nodes,
		from_node_id,
		to_node_id,
		edge_padding
	)
	for lane_x in [left_x, right_x]:
		for lane_y in [top_y, bottom_y]:
			_append_outer_reconnect_candidate(
				candidates,
				PackedVector2Array([p0, Vector2(p0.x, lane_y), Vector2(lane_x, lane_y), Vector2(lane_x, p3.y), p3]),
				visible_nodes,
				from_node_id,
				to_node_id,
				edge_padding
			)
			_append_outer_reconnect_candidate(
				candidates,
				PackedVector2Array([p0, Vector2(lane_x, p0.y), Vector2(lane_x, lane_y), Vector2(p3.x, lane_y), p3]),
				visible_nodes,
				from_node_id,
				to_node_id,
				edge_padding
			)
	if candidates.is_empty():
		return PackedVector2Array()
	candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return float(left.get("length", INF)) < float(right.get("length", INF))
	)
	return PackedVector2Array((candidates[0] as Dictionary).get("points", PackedVector2Array()))


static func _append_outer_reconnect_candidate(
	candidates: Array[Dictionary],
	points: PackedVector2Array,
	visible_nodes: Array[Dictionary],
	from_node_id: int,
	to_node_id: int,
	edge_padding: float
) -> void:
	if points.size() < 2:
		return
	if MapBoardGeometryScript.polyline_hits_other_visible_nodes(
		points,
		from_node_id,
		to_node_id,
		visible_nodes,
		edge_padding
	):
		return
	candidates.append({
		"points": points,
		"length": MapBoardGeometryScript.visible_edge_polyline_length({"points": points}),
	})
