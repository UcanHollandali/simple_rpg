# Layer: UI
extends RefCounted
class_name MapBoardBackdropBuilder

const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")


static func build_forest_shapes(
	board_size: Vector2,
	graph_nodes: Array[Dictionary],
	graph_by_id: Dictionary,
	world_positions: Dictionary,
	template_profile: String,
	board_seed: int,
	base_center_factor: Vector2,
	min_board_margin: Vector2
) -> Array[Dictionary]:
	var canopy_rng := RandomNumberGenerator.new()
	canopy_rng.seed = _derive_seed(board_seed, "forest")
	var forest_shapes: Array[Dictionary] = []
	var graph_edge_segments: Array[PackedVector2Array] = _build_graph_edge_segments(graph_by_id, world_positions)
	var pocket_anchors: Array[Vector2] = _build_pocket_anchors(graph_nodes, graph_edge_segments)
	var canopy_count: int = 10
	var decor_count: int = 12
	match template_profile:
		"corridor":
			canopy_count = 14
			decor_count = 8
		"openfield":
			canopy_count = 8
			decor_count = 10
		"loop":
			canopy_count = 12
			decor_count = 12

	for index in range(canopy_count):
		var canopy_shape: Dictionary = _build_forest_shape(
			canopy_rng,
			board_size,
			graph_nodes,
			graph_edge_segments,
			pocket_anchors,
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
			graph_edge_segments,
			pocket_anchors,
			"decor",
			template_profile,
			board_seed,
			index,
			base_center_factor,
			min_board_margin
		)
		if not decor_shape.is_empty():
			forest_shapes.append(decor_shape)
	return forest_shapes


static func _build_graph_edge_segments(graph_by_id: Dictionary, world_positions: Dictionary) -> Array[PackedVector2Array]:
	var sorted_node_ids: Array[int] = []
	for node_id_variant in graph_by_id.keys():
		sorted_node_ids.append(int(node_id_variant))
	sorted_node_ids.sort()
	var seen_edge_keys: Dictionary = {}
	var graph_edge_segments: Array[PackedVector2Array] = []
	for node_id in sorted_node_ids:
		var from_position: Vector2 = world_positions.get(node_id, Vector2.ZERO)
		if from_position == Vector2.ZERO:
			continue
		for adjacent_node_id in _sorted_adjacent_ids(graph_by_id, node_id):
			var edge_key: String = _edge_key(node_id, adjacent_node_id)
			if seen_edge_keys.has(edge_key):
				continue
			seen_edge_keys[edge_key] = true
			var to_position: Vector2 = world_positions.get(adjacent_node_id, Vector2.ZERO)
			if to_position == Vector2.ZERO:
				continue
			graph_edge_segments.append(PackedVector2Array([from_position, to_position]))
	return graph_edge_segments


static func _build_pocket_anchors(node_entries: Array[Dictionary], edge_segments: Array[PackedVector2Array]) -> Array[Vector2]:
	var anchors: Array[Vector2] = []
	for node_entry in node_entries:
		anchors.append(Vector2(node_entry.get("world_position", Vector2.ZERO)))
	for edge_points in edge_segments:
		if edge_points.size() >= 2:
			anchors.append((edge_points[0] + edge_points[edge_points.size() - 1]) * 0.5)
	return anchors


static func _build_forest_shape(
	rng: RandomNumberGenerator,
	board_size: Vector2,
	graph_nodes: Array[Dictionary],
	graph_edge_segments: Array[PackedVector2Array],
	pocket_anchors: Array[Vector2],
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
		var center: Vector2 = _candidate_forest_center(
			rng,
			board_size,
			pocket_anchors,
			shape_family,
			template_profile,
			base_center_factor,
			min_board_margin
		)
		if _conflicts_with_pocket(center, board_size, graph_nodes, graph_edge_segments, shape_family):
			continue
		var radius: float = _forest_radius_for(rng, shape_family, template_profile)
		return {
			"family": shape_family,
			"center": center,
			"radius": radius,
			"tone": _forest_tone_for(template_profile, shape_family, shape_index),
			"texture_path": _forest_texture_path_for(shape_family, board_seed, shape_index),
			"rotation_degrees": _forest_rotation_degrees_for(shape_family, board_seed, shape_index),
		}
	return {}


static func _candidate_forest_center(
	rng: RandomNumberGenerator,
	board_size: Vector2,
	pocket_anchors: Array[Vector2],
	shape_family: String,
	template_profile: String,
	base_center_factor: Vector2,
	min_board_margin: Vector2
) -> Vector2:
	if not pocket_anchors.is_empty():
		var anchor: Vector2 = pocket_anchors[rng.randi_range(0, pocket_anchors.size() - 1)]
		var board_center: Vector2 = board_size * base_center_factor
		var outward_direction: Vector2 = anchor - board_center
		if outward_direction.length_squared() <= 0.001:
			outward_direction = Vector2(rng.randf_range(-0.6, 0.6), -1.0).normalized()
		else:
			outward_direction = outward_direction.normalized()
		var tangent_direction: Vector2 = Vector2(-outward_direction.y, outward_direction.x)
		var board_unit: float = min(board_size.x, board_size.y)
		var outward_distance: float = board_unit * (0.18 if shape_family == "canopy" else 0.08)
		var tangent_distance: float = board_unit * (0.08 if shape_family == "canopy" else 0.05)
		match template_profile:
			"corridor":
				if shape_family == "canopy":
					outward_distance *= 1.08
				else:
					outward_distance *= 0.94
				tangent_distance *= 0.76
			"openfield":
				if shape_family == "canopy":
					outward_distance *= 1.18
				else:
					outward_distance *= 1.06
				tangent_distance *= 1.12
			"loop":
				if shape_family == "canopy":
					outward_distance *= 1.10
				tangent_distance *= 1.04
		var candidate: Vector2 = (
			anchor
			+ outward_direction * rng.randf_range(outward_distance * 0.72, outward_distance * 1.18)
			+ tangent_direction * rng.randf_range(-tangent_distance, tangent_distance)
		)
		return _clamp_to_board(candidate, board_size, min_board_margin)
	if shape_family == "canopy":
		var edge_index: int = rng.randi_range(0, 3)
		match edge_index:
			0:
				return Vector2(rng.randf_range(0.0, board_size.x), rng.randf_range(0.0, board_size.y * 0.16))
			1:
				return Vector2(board_size.x - rng.randf_range(0.0, board_size.x * 0.14), rng.randf_range(0.0, board_size.y))
			2:
				return Vector2(rng.randf_range(0.0, board_size.x), board_size.y - rng.randf_range(0.0, board_size.y * 0.14))
			_:
				return Vector2(rng.randf_range(0.0, board_size.x * 0.14), rng.randf_range(0.0, board_size.y))
	return Vector2(
		rng.randf_range(44.0, board_size.x - 44.0),
		rng.randf_range(34.0, board_size.y - 34.0)
	)


static func _forest_radius_for(rng: RandomNumberGenerator, shape_family: String, template_profile: String) -> float:
	match shape_family:
		"canopy":
			if template_profile == "openfield":
				return rng.randf_range(96.0, 156.0)
			if template_profile == "corridor":
				return rng.randf_range(118.0, 196.0)
			return rng.randf_range(104.0, 178.0)
		_:
			if template_profile == "corridor":
				return rng.randf_range(26.0, 54.0)
			if template_profile == "openfield":
				return rng.randf_range(22.0, 42.0)
			return rng.randf_range(24.0, 48.0)


static func _forest_tone_for(template_profile: String, shape_family: String, shape_index: int) -> Color:
	var base_color := Color(0.06, 0.14, 0.10, 0.22)
	match template_profile:
		"corridor":
			base_color = Color(0.05, 0.12, 0.09, 0.26)
		"openfield":
			base_color = Color(0.07, 0.15, 0.10, 0.18)
		"loop":
			base_color = Color(0.06, 0.13, 0.11, 0.22)
	if shape_family == "decor":
		return base_color.lightened(0.08 + float(shape_index % 3) * 0.03)
	return base_color


static func _conflicts_with_pocket(
	point: Vector2,
	board_size: Vector2,
	node_entries: Array[Dictionary],
	edge_segments: Array[PackedVector2Array],
	shape_family: String
) -> bool:
	for node_entry in node_entries:
		var node_center: Vector2 = node_entry.get("world_position", Vector2.ZERO)
		var node_radius: float = float(node_entry.get("clearing_radius", 0.0))
		var exclusion_radius: float = node_radius * (1.65 if shape_family == "canopy" else 1.18)
		if point.distance_to(node_center) < exclusion_radius:
			return true

	for edge_points in edge_segments:
		if _distance_to_polyline(point, edge_points) < (48.0 if shape_family == "canopy" else 24.0):
			return true
	if point.x > board_size.x - 150.0 and point.y < 120.0:
		return true
	return false


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


static func _adjacent_ids_from_entry(node_entry: Dictionary) -> PackedInt32Array:
	var adjacent_variant: Variant = node_entry.get("adjacent_node_ids", PackedInt32Array())
	if typeof(adjacent_variant) == TYPE_PACKED_INT32_ARRAY:
		return adjacent_variant
	var adjacent_ids := PackedInt32Array()
	if typeof(adjacent_variant) == TYPE_ARRAY:
		for adjacent_node_id in adjacent_variant:
			adjacent_ids.append(int(adjacent_node_id))
	return adjacent_ids


static func _sorted_adjacent_ids(graph_by_id: Dictionary, node_id: int) -> Array[int]:
	var adjacent_ids: Array[int] = []
	for adjacent_node_id in _adjacent_ids_from_entry(graph_by_id.get(node_id, {})):
		adjacent_ids.append(adjacent_node_id)
	adjacent_ids.sort()
	return adjacent_ids


static func _edge_key(from_node_id: int, to_node_id: int) -> String:
	var ordered_ids: Array[int] = [from_node_id, to_node_id]
	ordered_ids.sort()
	return "%d:%d" % [ordered_ids[0], ordered_ids[1]]


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


static func _clamp_to_board(position: Vector2, board_size: Vector2, min_board_margin: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, min_board_margin.x, board_size.x - min_board_margin.x),
		clampf(position.y, min_board_margin.y, board_size.y - min_board_margin.y)
	)
