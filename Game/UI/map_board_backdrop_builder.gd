# Layer: UI
extends RefCounted
class_name MapBoardBackdropBuilder

const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const MapBoardStyleScript = preload("res://Game/UI/map_board_style.gd")
const CANOPY_ACTION_POCKET_PADDING := Vector2(92.0, 104.0)
const DECOR_ACTION_POCKET_PADDING := Vector2(46.0, 52.0)
const CANOPY_ROUTE_CLEARANCE := 88.0
const DECOR_ROUTE_CLEARANCE := 36.0


static func build_forest_shapes(
	board_size: Vector2,
	graph_nodes: Array[Dictionary],
	layout_edges: Array,
	template_profile: String,
	board_seed: int,
	base_center_factor: Vector2,
	min_board_margin: Vector2
) -> Array[Dictionary]:
	var canopy_rng := RandomNumberGenerator.new()
	canopy_rng.seed = _derive_seed(board_seed, "forest")
	var forest_shapes: Array[Dictionary] = []
	var layout_edge_polylines: Array[PackedVector2Array] = _build_layout_edge_polylines(layout_edges)
	var action_bounds: Rect2 = _build_action_bounds(graph_nodes, layout_edge_polylines)
	var pocket_anchors: Array[Vector2] = _build_pocket_anchors(graph_nodes, layout_edge_polylines, action_bounds)
	var canopy_count: int = 10
	var decor_count: int = 12
	match template_profile:
		"corridor":
			canopy_count = 11
			decor_count = 8
		"openfield":
			canopy_count = 7
			decor_count = 10
		"loop":
			canopy_count = 10
			decor_count = 12

	for index in range(canopy_count):
		var canopy_shape: Dictionary = _build_forest_shape(
			canopy_rng,
			board_size,
			graph_nodes,
			layout_edge_polylines,
			pocket_anchors,
			action_bounds,
			"canopy",
			template_profile,
			board_seed,
			index,
			base_center_factor,
			min_board_margin
		)
		if not canopy_shape.is_empty():
			forest_shapes.append(canopy_shape)

	for index in range(decor_count):
		var decor_shape: Dictionary = _build_forest_shape(
			canopy_rng,
			board_size,
			graph_nodes,
			layout_edge_polylines,
			pocket_anchors,
			action_bounds,
			"decor",
			template_profile,
			board_seed,
			index,
			base_center_factor,
			min_board_margin
		)
		if not decor_shape.is_empty():
			forest_shapes.append(decor_shape)
	_ensure_minimum_forest_shape(
		forest_shapes,
		board_size,
		graph_nodes,
		layout_edge_polylines,
		action_bounds,
		"canopy",
		template_profile,
		board_seed,
		base_center_factor,
		min_board_margin
	)
	_ensure_minimum_forest_shape(
		forest_shapes,
		board_size,
		graph_nodes,
		layout_edge_polylines,
		action_bounds,
		"decor",
		template_profile,
		board_seed,
		base_center_factor,
		min_board_margin
	)
	return forest_shapes


static func forest_draw_half_extent(radius: float, shape_family: String) -> float:
	if radius <= 0.0:
		return 0.0
	if shape_family == "canopy":
		return maxf(radius, radius * MapBoardStyleScript.forest_texture_scale(shape_family) * 0.5)
	return radius


static func action_pocket_padding(radius: float, shape_family: String) -> Vector2:
	var base_padding: Vector2 = CANOPY_ACTION_POCKET_PADDING if shape_family == "canopy" else DECOR_ACTION_POCKET_PADDING
	var draw_half_extent: float = forest_draw_half_extent(radius, shape_family)
	return Vector2(maxf(base_padding.x, draw_half_extent), maxf(base_padding.y, draw_half_extent))


static func node_clearance_radius(node_radius: float, radius: float, shape_family: String) -> float:
	var legacy_extent: float = minf(radius * (0.52 if shape_family == "canopy" else 0.24), radius)
	var padding: float = 18.0 if shape_family == "canopy" else 8.0
	return node_radius + maxf(legacy_extent, forest_draw_half_extent(radius, shape_family)) + padding


static func route_clearance_radius(radius: float, shape_family: String) -> float:
	var legacy_clearance: float = maxf(
		radius * (0.46 if shape_family == "canopy" else 0.18),
		CANOPY_ROUTE_CLEARANCE if shape_family == "canopy" else DECOR_ROUTE_CLEARANCE
	)
	return maxf(legacy_clearance, forest_draw_half_extent(radius, shape_family))


static func _build_layout_edge_polylines(layout_edges: Array) -> Array[PackedVector2Array]:
	var polylines: Array[PackedVector2Array] = []
	for edge_variant in layout_edges:
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		var points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		polylines.append(points)
	return polylines


static func _build_action_bounds(node_entries: Array[Dictionary], edge_segments: Array[PackedVector2Array]) -> Rect2:
	var points: Array[Vector2] = []
	for node_entry in node_entries:
		var node_position: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
		if node_position != Vector2.ZERO:
			points.append(node_position)
	for edge_points in edge_segments:
		for point in edge_points:
			points.append(point)
	return _bounds_for_points(points)


static func _build_pocket_anchors(node_entries: Array[Dictionary], edge_segments: Array[PackedVector2Array], action_bounds: Rect2) -> Array[Vector2]:
	var anchors: Array[Vector2] = []
	for node_entry in node_entries:
		var node_position: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
		if node_position != Vector2.ZERO:
			anchors.append(node_position)
	for edge_points in edge_segments:
		if edge_points.size() >= 2:
			anchors.append((edge_points[0] + edge_points[edge_points.size() - 1]) * 0.5)
			anchors.append(_polyline_midpoint(edge_points))
	if action_bounds.size != Vector2.ZERO:
		var action_center: Vector2 = action_bounds.position + action_bounds.size * 0.5
		anchors.append(action_center)
	return anchors


static func _build_forest_shape(
	rng: RandomNumberGenerator,
	board_size: Vector2,
	graph_nodes: Array[Dictionary],
	layout_edge_polylines: Array[PackedVector2Array],
	pocket_anchors: Array[Vector2],
	action_bounds: Rect2,
	shape_family: String,
	template_profile: String,
	board_seed: int,
	shape_index: int,
	base_center_factor: Vector2,
	min_board_margin: Vector2
) -> Dictionary:
	var attempts: int = 0
	while attempts < 20:
		attempts += 1
		var radius: float = _forest_radius_for(rng, shape_family, template_profile)
		var center: Vector2 = _candidate_forest_center(
			rng,
			board_size,
			pocket_anchors,
			action_bounds,
			shape_family,
			template_profile,
			radius,
			base_center_factor,
			min_board_margin
		)
		if _conflicts_with_pocket(center, radius, board_size, graph_nodes, layout_edge_polylines, shape_family, action_bounds):
			continue
		return {
			"family": shape_family,
			"center": center,
			"radius": radius,
			"tone": _forest_tone_for(template_profile, shape_family, shape_index),
			"texture_path": _forest_texture_path_for(shape_family, board_seed, shape_index),
			"rotation_degrees": _forest_rotation_degrees_for(shape_family, board_seed, shape_index),
		}
	return {}


static func _ensure_minimum_forest_shape(
	forest_shapes: Array[Dictionary],
	board_size: Vector2,
	graph_nodes: Array[Dictionary],
	layout_edge_polylines: Array[PackedVector2Array],
	action_bounds: Rect2,
	shape_family: String,
	template_profile: String,
	board_seed: int,
	base_center_factor: Vector2,
	min_board_margin: Vector2
) -> void:
	for shape_entry in forest_shapes:
		if String(shape_entry.get("family", "")) == shape_family:
			return
	var fallback_shape: Dictionary = _build_fallback_forest_shape(
		board_size,
		graph_nodes,
		layout_edge_polylines,
		action_bounds,
		shape_family,
		template_profile,
		board_seed,
		base_center_factor,
		min_board_margin
	)
	if not fallback_shape.is_empty():
		forest_shapes.append(fallback_shape)


static func _build_fallback_forest_shape(
	board_size: Vector2,
	graph_nodes: Array[Dictionary],
	layout_edge_polylines: Array[PackedVector2Array],
	action_bounds: Rect2,
	shape_family: String,
	template_profile: String,
	board_seed: int,
	base_center_factor: Vector2,
	min_board_margin: Vector2
) -> Dictionary:
	var fallback_rng := RandomNumberGenerator.new()
	fallback_rng.seed = _derive_seed(board_seed, "forest-fallback:%s" % shape_family)
	var base_radius: float = _forest_radius_for(fallback_rng, shape_family, template_profile)
	var radius_scales: Array = [1.0, 0.86, 0.74] if shape_family == "canopy" else [1.0, 0.90]
	for scale in radius_scales:
		var radius: float = maxf(18.0, base_radius * scale)
		var slots: Array[Vector2] = _fallback_forest_slots(board_size, action_bounds, shape_family, radius, min_board_margin)
		if slots.is_empty():
			continue
		var rotation: int = abs(_derive_seed(board_seed, "forest-fallback-slot:%s:%0.2f" % [shape_family, scale])) % slots.size()
		for offset in range(slots.size()):
			var slot_index: int = (rotation + offset) % slots.size()
			var candidate: Vector2 = _clamp_to_board(slots[slot_index], board_size, min_board_margin, radius, shape_family)
			if _conflicts_with_pocket(candidate, radius, board_size, graph_nodes, layout_edge_polylines, shape_family, action_bounds):
				continue
			return {
				"family": shape_family,
				"center": candidate,
				"radius": radius,
				"tone": _forest_tone_for(template_profile, shape_family, slot_index),
				"texture_path": _forest_texture_path_for(shape_family, board_seed, slot_index),
				"rotation_degrees": _forest_rotation_degrees_for(shape_family, board_seed, slot_index),
			}
	for scale in radius_scales:
		var relaxed_radius: float = maxf(18.0, base_radius * scale)
		var relaxed_slots: Array[Vector2] = _fallback_forest_slots(board_size, action_bounds, shape_family, relaxed_radius, min_board_margin)
		if relaxed_slots.is_empty():
			continue
		var relaxed_rotation: int = abs(_derive_seed(board_seed, "forest-fallback-relaxed:%s:%0.2f" % [shape_family, scale])) % relaxed_slots.size()
		for offset in range(relaxed_slots.size()):
			var slot_index: int = (relaxed_rotation + offset) % relaxed_slots.size()
			var candidate: Vector2 = _clamp_to_board(relaxed_slots[slot_index], board_size, min_board_margin, relaxed_radius, shape_family)
			if _conflicts_with_nodes_or_action_bounds(candidate, relaxed_radius, board_size, graph_nodes, shape_family, action_bounds):
				continue
			return {
				"family": shape_family,
				"center": candidate,
				"radius": relaxed_radius,
				"tone": _forest_tone_for(template_profile, shape_family, slot_index),
				"texture_path": _forest_texture_path_for(shape_family, board_seed, slot_index),
				"rotation_degrees": _forest_rotation_degrees_for(shape_family, board_seed, slot_index),
			}
	var best_effort_radius: float = maxf(18.0, base_radius * float(radius_scales[radius_scales.size() - 1]))
	var best_effort_slot_index: int = _best_effort_fallback_slot_index(
		_fallback_forest_slots(board_size, action_bounds, shape_family, best_effort_radius, min_board_margin),
		graph_nodes,
		action_bounds
	)
	if best_effort_slot_index >= 0:
		var best_effort_slots: Array[Vector2] = _fallback_forest_slots(board_size, action_bounds, shape_family, best_effort_radius, min_board_margin)
		var best_effort_candidate: Vector2 = _clamp_to_board(
			best_effort_slots[best_effort_slot_index],
			board_size,
			min_board_margin,
			best_effort_radius,
			shape_family
		)
		return {
			"family": shape_family,
			"center": best_effort_candidate,
			"radius": best_effort_radius,
			"tone": _forest_tone_for(template_profile, shape_family, best_effort_slot_index),
			"texture_path": _forest_texture_path_for(shape_family, board_seed, best_effort_slot_index),
			"rotation_degrees": _forest_rotation_degrees_for(shape_family, board_seed, best_effort_slot_index),
		}
	return {}


static func _fallback_forest_slots(
	board_size: Vector2,
	action_bounds: Rect2,
	shape_family: String,
	radius: float,
	min_board_margin: Vector2
) -> Array[Vector2]:
	var center: Vector2 = action_bounds.position + action_bounds.size * 0.5 if action_bounds.size != Vector2.ZERO else board_size * 0.5
	var edge_padding: float = forest_draw_half_extent(radius, shape_family)
	var left_x: float = min_board_margin.x + edge_padding + 12.0
	var right_x: float = board_size.x - min_board_margin.x - edge_padding - 12.0
	var top_y: float = min_board_margin.y + edge_padding + 18.0
	var bottom_y: float = board_size.y - min_board_margin.y - edge_padding - 18.0
	var upper_mid_y: float = lerpf(top_y, center.y, 0.42)
	var lower_mid_y: float = lerpf(center.y, bottom_y, 0.58)
	return [
		Vector2(left_x, upper_mid_y),
		Vector2(right_x, upper_mid_y),
		Vector2(left_x, lower_mid_y),
		Vector2(right_x, lower_mid_y),
		Vector2(center.x, top_y),
		Vector2(center.x, bottom_y),
		Vector2(lerpf(left_x, center.x, 0.34), top_y),
		Vector2(lerpf(center.x, right_x, 0.66), top_y),
		Vector2(lerpf(left_x, center.x, 0.34), bottom_y),
		Vector2(lerpf(center.x, right_x, 0.66), bottom_y),
	]


static func _candidate_forest_center(
	rng: RandomNumberGenerator,
	board_size: Vector2,
	pocket_anchors: Array[Vector2],
	action_bounds: Rect2,
	shape_family: String,
	template_profile: String,
	radius: float,
	base_center_factor: Vector2,
	min_board_margin: Vector2
) -> Vector2:
	var action_center: Vector2 = action_bounds.position + action_bounds.size * 0.5 if action_bounds.size != Vector2.ZERO else board_size * base_center_factor
	if not pocket_anchors.is_empty():
		var anchor: Vector2 = pocket_anchors[rng.randi_range(0, pocket_anchors.size() - 1)]
		var outward_direction: Vector2 = anchor - action_center
		if outward_direction.length_squared() <= 0.001:
			outward_direction = Vector2(rng.randf_range(-0.6, 0.6), -1.0).normalized()
		else:
			outward_direction = outward_direction.normalized()
		var tangent_direction: Vector2 = Vector2(-outward_direction.y, outward_direction.x)
		var board_unit: float = min(board_size.x, board_size.y)
		var outward_distance: float = board_unit * (0.22 if shape_family == "canopy" else 0.10)
		var tangent_distance: float = board_unit * (0.06 if shape_family == "canopy" else 0.04)
		match template_profile:
			"corridor":
				if shape_family == "canopy":
					outward_distance *= 1.12
				else:
					outward_distance *= 0.98
				tangent_distance *= 0.72
			"openfield":
				if shape_family == "canopy":
					outward_distance *= 1.16
				else:
					outward_distance *= 1.02
				tangent_distance *= 0.96
			"loop":
				if shape_family == "canopy":
					outward_distance *= 1.08
				tangent_distance *= 0.90
		var candidate: Vector2 = (
			anchor
			+ outward_direction * rng.randf_range(outward_distance * 0.72, outward_distance * 1.18)
			+ tangent_direction * rng.randf_range(-tangent_distance, tangent_distance)
		)
		return _clamp_to_board(candidate, board_size, min_board_margin, radius, shape_family)
	if shape_family == "canopy":
		var edge_index: int = rng.randi_range(0, 3)
		match edge_index:
			0:
				return _clamp_to_board(Vector2(rng.randf_range(0.0, board_size.x), rng.randf_range(0.0, board_size.y * 0.16)), board_size, min_board_margin, radius, shape_family)
			1:
				return _clamp_to_board(Vector2(board_size.x - rng.randf_range(0.0, board_size.x * 0.14), rng.randf_range(0.0, board_size.y)), board_size, min_board_margin, radius, shape_family)
			2:
				return _clamp_to_board(Vector2(rng.randf_range(0.0, board_size.x), board_size.y - rng.randf_range(0.0, board_size.y * 0.14)), board_size, min_board_margin, radius, shape_family)
			_:
				return _clamp_to_board(Vector2(rng.randf_range(0.0, board_size.x * 0.14), rng.randf_range(0.0, board_size.y)), board_size, min_board_margin, radius, shape_family)
	return _clamp_to_board(Vector2(
		rng.randf_range(44.0, board_size.x - 44.0),
		rng.randf_range(34.0, board_size.y - 34.0)
	), board_size, min_board_margin, radius, shape_family)


static func _forest_radius_for(rng: RandomNumberGenerator, shape_family: String, template_profile: String) -> float:
	match shape_family:
		"canopy":
			if template_profile == "openfield":
				return rng.randf_range(84.0, 138.0)
			if template_profile == "corridor":
				return rng.randf_range(102.0, 166.0)
			return rng.randf_range(92.0, 154.0)
		_:
			if template_profile == "corridor":
				return rng.randf_range(22.0, 46.0)
			if template_profile == "openfield":
				return rng.randf_range(20.0, 38.0)
			return rng.randf_range(22.0, 42.0)


static func _forest_tone_for(template_profile: String, shape_family: String, shape_index: int) -> Color:
	var base_color := Color(0.06, 0.14, 0.10, 0.22)
	match template_profile:
		"corridor":
			base_color = Color(0.05, 0.12, 0.09, 0.20)
		"openfield":
			base_color = Color(0.07, 0.15, 0.10, 0.15)
		"loop":
			base_color = Color(0.06, 0.13, 0.11, 0.18)
	if shape_family == "decor":
		return base_color.lightened(0.08 + float(shape_index % 3) * 0.03)
	return base_color


static func _conflicts_with_pocket(
	point: Vector2,
	radius: float,
	board_size: Vector2,
	node_entries: Array[Dictionary],
	edge_segments: Array[PackedVector2Array],
	shape_family: String,
	action_bounds: Rect2
) -> bool:
	if _conflicts_with_nodes_or_action_bounds(point, radius, board_size, node_entries, shape_family, action_bounds):
		return true
	for edge_points in edge_segments:
		var route_clearance: float = route_clearance_radius(radius, shape_family)
		if _distance_to_polyline(point, edge_points) < route_clearance:
			return true
	return false


static func _conflicts_with_nodes_or_action_bounds(
	point: Vector2,
	radius: float,
	board_size: Vector2,
	node_entries: Array[Dictionary],
	shape_family: String,
	action_bounds: Rect2
) -> bool:
	if action_bounds.size != Vector2.ZERO:
		var action_padding: Vector2 = action_pocket_padding(radius, shape_family)
		var padded_action_bounds := Rect2(
			action_bounds.position - action_padding,
			action_bounds.size + action_padding * 2.0
		)
		if padded_action_bounds.has_point(point):
			return true
	for node_entry in node_entries:
		var node_center: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
		var node_radius: float = float(node_entry.get("clearing_radius", 0.0))
		var exclusion_radius: float = node_clearance_radius(node_radius, radius, shape_family)
		if point.distance_to(node_center) < exclusion_radius:
			return true
	if point.x > board_size.x - 150.0 and point.y < 120.0:
		return true
	return false


static func _bounds_for_points(points: Array[Vector2]) -> Rect2:
	if points.is_empty():
		return Rect2()
	var min_point: Vector2 = points[0]
	var max_point: Vector2 = points[0]
	for point in points:
		min_point = Vector2(minf(min_point.x, point.x), minf(min_point.y, point.y))
		max_point = Vector2(maxf(max_point.x, point.x), maxf(max_point.y, point.y))
	return Rect2(min_point, max_point - min_point)


static func _polyline_midpoint(polyline: PackedVector2Array) -> Vector2:
	if polyline.is_empty():
		return Vector2.ZERO
	if polyline.size() == 1:
		return polyline[0]
	var total_length: float = 0.0
	for index in range(polyline.size() - 1):
		total_length += polyline[index].distance_to(polyline[index + 1])
	if total_length <= 0.001:
		var midpoint_index: int = max(0, int(floor(float(polyline.size() - 1) * 0.5)))
		return polyline[midpoint_index]
	var remaining_length: float = total_length * 0.5
	for index in range(polyline.size() - 1):
		var from_point: Vector2 = polyline[index]
		var to_point: Vector2 = polyline[index + 1]
		var segment_length: float = from_point.distance_to(to_point)
		if segment_length <= 0.001:
			continue
		if remaining_length <= segment_length:
			return from_point.lerp(to_point, remaining_length / segment_length)
		remaining_length -= segment_length
	return polyline[polyline.size() - 1]


static func _distance_to_polyline(point: Vector2, polyline: PackedVector2Array) -> float:
	if polyline.size() < 2:
		return INF
	var shortest_distance: float = INF
	for index in range(polyline.size() - 1):
		shortest_distance = min(shortest_distance, _distance_to_segment(point, polyline[index], polyline[index + 1]))
	return shortest_distance


static func _distance_to_segment(point: Vector2, from_point: Vector2, to_point: Vector2) -> float:
	var segment: Vector2 = to_point - from_point
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= 0.0001:
		return point.distance_to(from_point)
	var projection: float = clampf((point - from_point).dot(segment) / segment_length_squared, 0.0, 1.0)
	return point.distance_to(from_point + segment * projection)


static func _best_effort_fallback_slot_index(slots: Array[Vector2], node_entries: Array[Dictionary], action_bounds: Rect2) -> int:
	if slots.is_empty():
		return -1
	var action_center: Vector2 = action_bounds.position + action_bounds.size * 0.5 if action_bounds.size != Vector2.ZERO else Vector2.ZERO
	var best_index: int = 0
	var best_score: float = -INF
	for index in range(slots.size()):
		var slot: Vector2 = slots[index]
		var nearest_node_distance: float = INF
		for node_entry in node_entries:
			var node_center: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
			nearest_node_distance = minf(nearest_node_distance, slot.distance_to(node_center))
		if nearest_node_distance == INF:
			nearest_node_distance = 0.0
		var action_distance: float = slot.distance_to(action_center) if action_bounds.size != Vector2.ZERO else 0.0
		var score: float = nearest_node_distance + action_distance * 0.28
		if score > best_score:
			best_score = score
			best_index = index
	return best_index


static func _forest_texture_path_for(shape_family: String, board_seed: int, shape_index: int) -> String:
	if shape_family != "canopy" or UiAssetPathsScript.MAP_CANOPY_TEXTURE_PATHS.is_empty():
		return ""
	var texture_index: int = abs(_derive_seed(board_seed, "forest-texture:%d" % shape_index)) % UiAssetPathsScript.MAP_CANOPY_TEXTURE_PATHS.size()
	return String(UiAssetPathsScript.MAP_CANOPY_TEXTURE_PATHS[texture_index])


static func _forest_rotation_degrees_for(shape_family: String, board_seed: int, shape_index: int) -> float:
	if shape_family != "canopy":
		return 0.0
	var rotation_seed: int = _derive_seed(board_seed, "forest-rotation:%d" % shape_index)
	return float((rotation_seed % 29) - 14)


static func _derive_seed(board_seed: int, salt: String) -> int:
	return _hash_seed_string("%d|%s" % [board_seed, salt])


static func _hash_seed_string(value: String) -> int:
	var accumulator: int = 216613626
	var bytes: PackedByteArray = value.to_utf8_buffer()
	for byte in bytes:
		accumulator = abs(int((accumulator ^ int(byte)) * 16777619))
	if accumulator == 0:
		return 1
	return accumulator


static func _clamp_to_board(
	position: Vector2,
	board_size: Vector2,
	min_board_margin: Vector2,
	radius: float = 0.0,
	shape_family: String = ""
) -> Vector2:
	var edge_padding: float = forest_draw_half_extent(radius, shape_family)
	return Vector2(
		clampf(position.x, min_board_margin.x + edge_padding, board_size.x - min_board_margin.x - edge_padding),
		clampf(position.y, min_board_margin.y + edge_padding, board_size.y - min_board_margin.y - edge_padding)
	)
