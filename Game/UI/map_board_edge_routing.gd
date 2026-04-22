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
	var lane_inset_x: float = clampf(min_board_margin.x * 0.92, min_board_margin.x * 0.92, max(min_board_margin.x * 0.92, board_size.x * 0.20))
	var lane_inset_y: float = clampf(min_board_margin.y * 0.92, min_board_margin.y * 0.92, max(min_board_margin.y * 0.92, board_size.y * 0.20))
	var left_x: float = lane_inset_x
	var right_x: float = board_size.x - lane_inset_x
	var top_y: float = lane_inset_y
	var bottom_y: float = board_size.y - lane_inset_y
	var lane_x_values: Array[float] = [left_x, right_x]
	var lane_y_values: Array[float] = [top_y, bottom_y]
	var secondary_left_x: float = clampf(min_board_margin.x * 0.76, 92.0, left_x)
	var secondary_top_y: float = clampf(min_board_margin.y * 0.76, 96.0, top_y)
	if secondary_left_x < left_x - 6.0:
		lane_x_values.append(secondary_left_x)
		lane_x_values.append(board_size.x - secondary_left_x)
	if secondary_top_y < top_y - 6.0:
		lane_y_values.append(secondary_top_y)
		lane_y_values.append(board_size.y - secondary_top_y)
	var outer_left_x: float = clampf(min_board_margin.x * 0.28, 28.0, left_x)
	var outer_top_y: float = clampf(min_board_margin.y * 0.28, 32.0, top_y)
	if outer_left_x < secondary_left_x - 6.0:
		lane_x_values.append(outer_left_x)
		lane_x_values.append(board_size.x - outer_left_x)
	if outer_top_y < secondary_top_y - 6.0:
		lane_y_values.append(outer_top_y)
		lane_y_values.append(board_size.y - outer_top_y)
	var candidates: Array[Dictionary] = []
	for lane_y in lane_y_values:
		_append_outer_reconnect_candidate(
			candidates,
			PackedVector2Array([p0, Vector2(p0.x, lane_y), Vector2(p3.x, lane_y), p3]),
			visible_nodes,
			from_node_id,
			to_node_id,
			edge_padding,
			p0,
			p3,
			board_size
		)
	for lane_x in lane_x_values:
		_append_outer_reconnect_candidate(
			candidates,
			PackedVector2Array([p0, Vector2(lane_x, p0.y), Vector2(lane_x, p3.y), p3]),
			visible_nodes,
			from_node_id,
			to_node_id,
			edge_padding,
			p0,
			p3,
			board_size
		)
	for lane_x in lane_x_values:
		for lane_y in lane_y_values:
			_append_outer_reconnect_candidate(
				candidates,
				PackedVector2Array([p0, Vector2(p0.x, lane_y), Vector2(lane_x, lane_y), Vector2(lane_x, p3.y), p3]),
				visible_nodes,
				from_node_id,
				to_node_id,
				edge_padding,
				p0,
				p3,
				board_size
			)
			_append_outer_reconnect_candidate(
				candidates,
				PackedVector2Array([p0, Vector2(lane_x, p0.y), Vector2(lane_x, lane_y), Vector2(p3.x, lane_y), p3]),
				visible_nodes,
				from_node_id,
				to_node_id,
				edge_padding,
				p0,
				p3,
				board_size
			)
	if candidates.is_empty():
		return PackedVector2Array()
	candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_score: float = float(left.get("score", INF))
		var right_score: float = float(right.get("score", INF))
		if not is_equal_approx(left_score, right_score):
			return left_score < right_score
		return float(left.get("length", INF)) < float(right.get("length", INF))
	)
	return PackedVector2Array((candidates[0] as Dictionary).get("points", PackedVector2Array()))


static func _append_outer_reconnect_candidate(
	candidates: Array[Dictionary],
	points: PackedVector2Array,
	visible_nodes: Array[Dictionary],
	from_node_id: int,
	to_node_id: int,
	edge_padding: float,
	p0: Vector2,
	p3: Vector2,
	board_size: Vector2
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
		"score": _outer_reconnect_candidate_score(points, p0, p3, board_size),
	})


static func score_outer_reconnect_candidate(
	points: PackedVector2Array,
	p0: Vector2,
	p3: Vector2,
	board_size: Vector2
) -> float:
	return _outer_reconnect_candidate_score(points, p0, p3, board_size)


static func _outer_reconnect_candidate_score(
	points: PackedVector2Array,
	p0: Vector2,
	p3: Vector2,
	board_size: Vector2
) -> float:
	var path_length: float = MapBoardGeometryScript.visible_edge_polyline_length({"points": points})
	if points.is_empty():
		return path_length
	var direct_min_x: float = minf(p0.x, p3.x)
	var direct_max_x: float = maxf(p0.x, p3.x)
	var direct_min_y: float = minf(p0.y, p3.y)
	var direct_max_y: float = maxf(p0.y, p3.y)
	var candidate_min_x: float = points[0].x
	var candidate_max_x: float = points[0].x
	var candidate_min_y: float = points[0].y
	var candidate_max_y: float = points[0].y
	for point in points:
		candidate_min_x = minf(candidate_min_x, point.x)
		candidate_max_x = maxf(candidate_max_x, point.x)
		candidate_min_y = minf(candidate_min_y, point.y)
		candidate_max_y = maxf(candidate_max_y, point.y)
	var horizontal_expansion: float = maxf(0.0, direct_min_x - candidate_min_x) + maxf(0.0, candidate_max_x - direct_max_x)
	var vertical_expansion: float = maxf(0.0, direct_min_y - candidate_min_y) + maxf(0.0, candidate_max_y - direct_max_y)
	var direct_width: float = maxf(1.0, direct_max_x - direct_min_x)
	var direct_height: float = maxf(1.0, direct_max_y - direct_min_y)
	var candidate_width: float = candidate_max_x - candidate_min_x
	var candidate_height: float = candidate_max_y - candidate_min_y
	var detour_area: float = maxf(0.0, (candidate_width * candidate_height) - (direct_width * direct_height))
	var bend_penalty: float = float(max(0, points.size() - 2)) * 24.0
	var edge_hugging_penalty: float = 0.0
	if board_size.x > 0.0 and board_size.y > 0.0 and points.size() > 2:
		var preferred_edge_clearance: float = clampf(minf(board_size.x, board_size.y) * 0.17, 118.0, 188.0)
		for point_index in range(1, points.size() - 1):
			var bend_point: Vector2 = points[point_index]
			var edge_clearance: float = minf(
				minf(bend_point.x, board_size.x - bend_point.x),
				minf(bend_point.y, board_size.y - bend_point.y)
			)
			if edge_clearance < preferred_edge_clearance:
				var clearance_shortfall: float = preferred_edge_clearance - edge_clearance
				edge_hugging_penalty += clearance_shortfall * clearance_shortfall * 0.05
	return (
		path_length
		+ horizontal_expansion * 1.05
		+ vertical_expansion * 1.20
		+ detour_area * 0.015
		+ bend_penalty
		+ edge_hugging_penalty
	)
