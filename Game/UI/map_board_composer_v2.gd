# Layer: UI
extends RefCounted
class_name MapBoardComposerV2

const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")

const DEFAULT_TEMPLATE_PROFILE := "corridor"
const BASE_CENTER_FACTOR := Vector2(0.50, 0.56)
const MIN_BOARD_MARGIN := Vector2(108.0, 128.0)
const RING_RADIUS_FACTORS := [0.0, 0.20, 0.33, 0.46, 0.58, 0.70]
const ARC_START_RADIANS := -2.72
const ARC_END_RADIANS := -0.28
const PATH_FAMILY_SHORT_STRAIGHT := "short_straight"
const PATH_FAMILY_GENTLE_CURVE := "gentle_curve"
const PATH_FAMILY_WIDER_CURVE := "wider_curve"
const PATH_FAMILY_OUTWARD_RECONNECTING_ARC := "outward_reconnecting_arc"


func compose(
	run_state: RunState,
	board_size: Vector2,
	focus_anchor_factor: Vector2,
	max_focus_offset: Vector2
) -> Dictionary:
	if run_state == null or board_size.x <= 0.0 or board_size.y <= 0.0:
		return _empty_composition()

	var map_runtime_state: RefCounted = run_state.map_runtime_state
	if map_runtime_state == null:
		return _empty_composition()

	var graph_snapshot: Array[Dictionary] = map_runtime_state.build_realized_graph_snapshots()
	if graph_snapshot.is_empty():
		return _empty_composition()

	graph_snapshot.sort_custom(Callable(self, "_sort_node_entry_by_id"))
	var graph_by_id: Dictionary = _index_graph_snapshot(graph_snapshot)
	var start_node_id: int = _resolve_start_node_id(graph_snapshot)
	var depth_by_node_id: Dictionary = _build_depth_by_node_id(graph_by_id, start_node_id)
	var sector_by_node_id: Dictionary = _build_sector_by_node_id(graph_by_id, depth_by_node_id, start_node_id)
	var current_node_id: int = int(map_runtime_state.current_node_id)
	var active_template_id: String = String(map_runtime_state.get_active_template_id())
	var template_profile: String = _template_profile_for_id(active_template_id)
	var board_seed: int = _build_board_seed(run_state, active_template_id, graph_snapshot)
	var side_mission_highlight: Dictionary = map_runtime_state.build_side_mission_highlight_snapshot()
	var world_positions: Dictionary = _build_world_positions(
		graph_snapshot,
		graph_by_id,
		board_size,
		depth_by_node_id,
		sector_by_node_id,
		board_seed
	)
	var visible_nodes: Array[Dictionary] = _build_visible_node_entries(
		graph_snapshot,
		graph_by_id,
		world_positions,
		current_node_id,
		board_size
	)
	var visible_edges: Array[Dictionary] = _build_visible_edges(
		graph_by_id,
		visible_nodes,
		world_positions,
		template_profile,
		board_seed,
		board_size
	)
	var focus_anchor: Vector2 = board_size * focus_anchor_factor
	var current_world_position: Vector2 = world_positions.get(current_node_id, board_size * BASE_CENTER_FACTOR)
	var focus_offset: Vector2 = _clamp_focus_offset(focus_anchor - current_world_position, max_focus_offset)
	var forest_shapes: Array[Dictionary] = _build_forest_shapes(
		board_size,
		visible_nodes,
		visible_edges,
		template_profile,
		board_seed
	)
	return {
		"seed": board_seed,
		"template_profile": template_profile,
		"current_node_id": current_node_id,
		"side_mission_highlight_node_id": int(side_mission_highlight.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)),
		"side_mission_highlight_state": String(side_mission_highlight.get("highlight_state", "")),
		"world_positions": world_positions,
		"visible_nodes": visible_nodes,
		"visible_edges": visible_edges,
		"forest_shapes": forest_shapes,
		"focus_offset": focus_offset,
	}


func _empty_composition() -> Dictionary:
	return {
		"seed": 0,
		"template_profile": DEFAULT_TEMPLATE_PROFILE,
		"current_node_id": MapRuntimeStateScript.NO_PENDING_NODE_ID,
		"side_mission_highlight_node_id": MapRuntimeStateScript.NO_PENDING_NODE_ID,
		"side_mission_highlight_state": "",
		"world_positions": {},
		"visible_nodes": [],
		"visible_edges": [],
		"forest_shapes": [],
		"focus_offset": Vector2.ZERO,
	}


func _index_graph_snapshot(graph_snapshot: Array[Dictionary]) -> Dictionary:
	var graph_by_id: Dictionary = {}
	for node_entry in graph_snapshot:
		graph_by_id[int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))] = node_entry.duplicate(true)
	return graph_by_id


func _resolve_start_node_id(graph_snapshot: Array[Dictionary]) -> int:
	for node_entry in graph_snapshot:
		if String(node_entry.get("node_family", "")) == "start":
			return int(node_entry.get("node_id", 0))
	return 0


func _build_depth_by_node_id(graph_by_id: Dictionary, start_node_id: int) -> Dictionary:
	var depth_by_node_id: Dictionary = {start_node_id: 0}
	var open_node_ids: Array[int] = [start_node_id]
	while not open_node_ids.is_empty():
		var node_id: int = open_node_ids.pop_front()
		var node_depth: int = int(depth_by_node_id.get(node_id, 0))
		var adjacent_node_ids: PackedInt32Array = _adjacent_ids_for(graph_by_id, node_id)
		for adjacent_node_id in adjacent_node_ids:
			if depth_by_node_id.has(adjacent_node_id):
				continue
			depth_by_node_id[adjacent_node_id] = node_depth + 1
			open_node_ids.append(adjacent_node_id)
	return depth_by_node_id


func _build_sector_by_node_id(graph_by_id: Dictionary, depth_by_node_id: Dictionary, start_node_id: int) -> Dictionary:
	var sector_by_node_id: Dictionary = {start_node_id: 0.0}
	var start_adjacent_ids: Array[int] = _sorted_adjacent_ids(graph_by_id, start_node_id)
	for index in range(start_adjacent_ids.size()):
		sector_by_node_id[start_adjacent_ids[index]] = float(index)

	var pending_node_ids: Array[int] = []
	for node_id_variant in graph_by_id.keys():
		pending_node_ids.append(int(node_id_variant))
	pending_node_ids.sort()

	for node_id in pending_node_ids:
		if node_id == start_node_id or sector_by_node_id.has(node_id):
			continue
		var node_depth: int = int(depth_by_node_id.get(node_id, 0))
		var parent_sectors: Array[float] = []
		for adjacent_node_id in _adjacent_ids_for(graph_by_id, node_id):
			if int(depth_by_node_id.get(adjacent_node_id, -1)) != node_depth - 1:
				continue
			if not sector_by_node_id.has(adjacent_node_id):
				continue
			parent_sectors.append(float(sector_by_node_id[adjacent_node_id]))
		sector_by_node_id[node_id] = _average_float_array(parent_sectors)
	return sector_by_node_id


func _build_world_positions(
	graph_snapshot: Array[Dictionary],
	graph_by_id: Dictionary,
	board_size: Vector2,
	depth_by_node_id: Dictionary,
	sector_by_node_id: Dictionary,
	board_seed: int
) -> Dictionary:
	var origin: Vector2 = board_size * BASE_CENTER_FACTOR
	var board_min_dimension: float = min(board_size.x, board_size.y)
	var start_adjacent_ids: Array[int] = _sorted_adjacent_ids(graph_by_id, _resolve_start_node_id(graph_snapshot))
	var sector_count: int = max(1, start_adjacent_ids.size())
	var max_depth: int = 0
	for depth_value in depth_by_node_id.values():
		max_depth = max(max_depth, int(depth_value))
	var world_positions: Dictionary = {}

	for node_entry in graph_snapshot:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var node_depth: int = int(depth_by_node_id.get(node_id, 0))
		if node_depth <= 0:
			world_positions[node_id] = origin
			continue

		var node_seed_rng := RandomNumberGenerator.new()
		node_seed_rng.seed = _derive_seed(board_seed, "layout:%d" % node_id)
		var sector_value: float = float(sector_by_node_id.get(node_id, 0.0))
		var sector_t: float = 0.5 if sector_count <= 1 else clampf(sector_value / float(sector_count - 1), 0.0, 1.0)
		var depth_t: float = 0.0 if max_depth <= 1 else clampf(float(node_depth - 1) / float(max_depth - 1), 0.0, 1.0)
		var arc_start: float = lerpf(ARC_START_RADIANS, ARC_START_RADIANS - 0.20, depth_t)
		var arc_end: float = lerpf(ARC_END_RADIANS, ARC_END_RADIANS + 0.34, depth_t)
		var base_angle: float = lerpf(arc_start, arc_end, sector_t)
		var ring_index: int = min(node_depth, RING_RADIUS_FACTORS.size() - 1)
		var ring_radius: float = board_min_dimension * float(RING_RADIUS_FACTORS[ring_index])
		var neighbor_count: int = max(1, _adjacent_ids_for(graph_by_id, node_id).size())
		var angle_jitter_scale: float = 0.12
		if node_depth == 1:
			angle_jitter_scale = 0.035 if sector_count >= 3 else 0.028
		elif node_depth == 2:
			angle_jitter_scale = 0.058 if neighbor_count >= 4 else 0.076
		elif neighbor_count >= 4:
			angle_jitter_scale = 0.062
		var angle_jitter: float = node_seed_rng.randf_range(-angle_jitter_scale, angle_jitter_scale)
		var radial_jitter_inward: float = board_min_dimension * (0.012 if node_depth == 1 else 0.020)
		var radial_jitter_outward: float = board_min_dimension * (0.018 if node_depth == 1 else 0.030)
		var radial_jitter: float = node_seed_rng.randf_range(-radial_jitter_inward, radial_jitter_outward)
		var tangent_jitter_scale: float = 0.028 if node_depth == 1 else 0.040 if node_depth == 2 else 0.055
		var tangent_jitter: float = node_seed_rng.randf_range(-board_min_dimension * tangent_jitter_scale, board_min_dimension * tangent_jitter_scale)
		var angle: float = base_angle + angle_jitter
		var radial_position: Vector2 = Vector2(cos(angle), sin(angle)) * max(0.0, ring_radius + radial_jitter)
		var tangent_normal: Vector2 = Vector2(-sin(angle), cos(angle))
		var position: Vector2 = origin + radial_position + tangent_normal * tangent_jitter
		world_positions[node_id] = _clamp_to_board(position, board_size)

	_relax_collisions(world_positions, graph_snapshot, board_size, depth_by_node_id)
	return world_positions


func _build_visible_node_entries(
	graph_snapshot: Array[Dictionary],
	graph_by_id: Dictionary,
	world_positions: Dictionary,
	current_node_id: int,
	board_size: Vector2
) -> Array[Dictionary]:
	var visible_nodes: Array[Dictionary] = []
	var current_adjacent_ids: PackedInt32Array = _adjacent_ids_for(graph_by_id, current_node_id)
	for node_entry in graph_snapshot:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var node_state: String = String(node_entry.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
		var is_current: bool = node_id == current_node_id
		if not is_current and node_state == MapRuntimeStateScript.NODE_STATE_UNDISCOVERED:
			continue
		var node_family: String = String(node_entry.get("node_family", ""))
		var state_semantic: String = _semantic_for_node(node_state, is_current)
		var world_position: Vector2 = world_positions.get(node_id, board_size * BASE_CENTER_FACTOR)
		visible_nodes.append({
			"node_id": node_id,
			"node_family": node_family,
			"node_state": node_state,
			"state_semantic": state_semantic,
			"is_current": is_current,
			"is_adjacent": current_adjacent_ids.has(node_id),
			"world_position": world_position,
			"clearing_radius": _clearing_radius_for(node_family, state_semantic, board_size),
		})
	visible_nodes.sort_custom(Callable(self, "_sort_visible_node_entries"))
	return visible_nodes


func _build_visible_edges(
	graph_by_id: Dictionary,
	visible_nodes: Array[Dictionary],
	world_positions: Dictionary,
	template_profile: String,
	board_seed: int,
	board_size: Vector2
) -> Array[Dictionary]:
	var visible_node_ids: Dictionary = {}
	var visible_node_by_id: Dictionary = {}
	for node_entry in visible_nodes:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		visible_node_ids[node_id] = true
		visible_node_by_id[node_id] = node_entry

	var visible_edges: Array[Dictionary] = []
	var processed_edges: Dictionary = {}
	for node_id_variant in graph_by_id.keys():
		var node_id: int = int(node_id_variant)
		if not visible_node_ids.has(node_id):
			continue
		for adjacent_node_id in _adjacent_ids_for(graph_by_id, node_id):
			if not visible_node_ids.has(adjacent_node_id):
				continue
			var edge_key: String = _edge_key(node_id, adjacent_node_id)
			if processed_edges.has(edge_key):
				continue
			processed_edges[edge_key] = true
			var from_node: Dictionary = visible_node_by_id.get(node_id, {})
			var to_node: Dictionary = visible_node_by_id.get(adjacent_node_id, {})
			var edge_semantic: String = _edge_semantic_for(from_node, to_node)
			var path_model: Dictionary = _build_edge_path_model(
				from_node,
				to_node,
				world_positions,
				template_profile,
				board_seed,
				board_size
			)
			visible_edges.append({
				"from_node_id": node_id,
				"to_node_id": adjacent_node_id,
				"state_semantic": edge_semantic,
				"path_family": String(path_model.get("path_family", PATH_FAMILY_GENTLE_CURVE)),
				"points": path_model.get("points", PackedVector2Array()),
			})
	return visible_edges


func _build_forest_shapes(
	board_size: Vector2,
	visible_nodes: Array[Dictionary],
	visible_edges: Array[Dictionary],
	template_profile: String,
	board_seed: int
) -> Array[Dictionary]:
	var canopy_rng := RandomNumberGenerator.new()
	canopy_rng.seed = _derive_seed(board_seed, "forest")
	var forest_shapes: Array[Dictionary] = []
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
			visible_nodes,
			visible_edges,
			"canopy",
			template_profile,
			index
		)
		if not canopy_shape.is_empty():
			forest_shapes.append(canopy_shape)

	for index in range(decor_count):
		var decor_shape: Dictionary = _build_forest_shape(
			canopy_rng,
			board_size,
			visible_nodes,
			visible_edges,
			"decor",
			template_profile,
			index
		)
		if not decor_shape.is_empty():
			forest_shapes.append(decor_shape)
	return forest_shapes


func _build_forest_shape(
	rng: RandomNumberGenerator,
	board_size: Vector2,
	visible_nodes: Array[Dictionary],
	visible_edges: Array[Dictionary],
	shape_family: String,
	template_profile: String,
	shape_index: int
) -> Dictionary:
	var attempts: int = 0
	while attempts < 20:
		attempts += 1
		var center: Vector2 = _candidate_forest_center(rng, board_size, shape_family)
		if _conflicts_with_visible_pocket(center, board_size, visible_nodes, visible_edges, shape_family):
			continue
		var radius: float = _forest_radius_for(rng, shape_family, template_profile)
		return {
			"family": shape_family,
			"center": center,
			"radius": radius,
			"tone": _forest_tone_for(template_profile, shape_family, shape_index),
		}
	return {}


func _candidate_forest_center(rng: RandomNumberGenerator, board_size: Vector2, shape_family: String) -> Vector2:
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


func _forest_radius_for(rng: RandomNumberGenerator, shape_family: String, template_profile: String) -> float:
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


func _forest_tone_for(template_profile: String, shape_family: String, shape_index: int) -> Color:
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


func _conflicts_with_visible_pocket(
	point: Vector2,
	board_size: Vector2,
	visible_nodes: Array[Dictionary],
	visible_edges: Array[Dictionary],
	shape_family: String
) -> bool:
	for node_entry in visible_nodes:
		var node_center: Vector2 = node_entry.get("world_position", Vector2.ZERO)
		var node_radius: float = float(node_entry.get("clearing_radius", 0.0))
		var exclusion_radius: float = node_radius * (1.65 if shape_family == "canopy" else 1.18)
		if point.distance_to(node_center) < exclusion_radius:
			return true

	for edge_entry in visible_edges:
		var edge_points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
		if _distance_to_polyline(point, edge_points) < (48.0 if shape_family == "canopy" else 24.0):
			return true
	if point.x > board_size.x - 150.0 and point.y < 120.0:
		return true
	return false


func _distance_to_polyline(point: Vector2, polyline: PackedVector2Array) -> float:
	if polyline.size() < 2:
		return INF
	var shortest_distance: float = INF
	for index in range(polyline.size() - 1):
		shortest_distance = min(shortest_distance, _distance_to_segment(point, polyline[index], polyline[index + 1]))
	return shortest_distance


func _distance_to_segment(point: Vector2, from_point: Vector2, to_point: Vector2) -> float:
	var segment: Vector2 = to_point - from_point
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= 0.0001:
		return point.distance_to(from_point)
	var projection: float = clampf((point - from_point).dot(segment) / segment_length_squared, 0.0, 1.0)
	return point.distance_to(from_point + segment * projection)


func _build_edge_path_model(
	from_node: Dictionary,
	to_node: Dictionary,
	world_positions: Dictionary,
	template_profile: String,
	board_seed: int,
	board_size: Vector2
) -> Dictionary:
	var from_node_id: int = int(from_node.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var to_node_id: int = int(to_node.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var start_point: Vector2 = world_positions.get(from_node_id, Vector2.ZERO)
	var end_point: Vector2 = world_positions.get(to_node_id, Vector2.ZERO)
	var direction: Vector2 = end_point - start_point
	var distance: float = direction.length()
	if distance <= 0.001:
		return {
			"path_family": PATH_FAMILY_SHORT_STRAIGHT,
			"points": PackedVector2Array([start_point, end_point]),
		}

	var direction_normalized: Vector2 = direction / distance
	var normal: Vector2 = Vector2(-direction_normalized.y, direction_normalized.x)
	var start_radius: float = float(from_node.get("clearing_radius", 42.0))
	var end_radius: float = float(to_node.get("clearing_radius", 42.0))
	var start_inset: float = min(start_radius * 0.78, distance * 0.34)
	var end_inset: float = min(end_radius * 0.78, distance * 0.34)
	var p0: Vector2 = start_point + direction_normalized * start_inset
	var p3: Vector2 = end_point - direction_normalized * end_inset
	var board_center: Vector2 = board_size * BASE_CENTER_FACTOR
	var midpoint: Vector2 = (start_point + end_point) * 0.5
	var outward_bias: Vector2 = midpoint - board_center
	if outward_bias.length_squared() <= 0.001:
		outward_bias = normal
	var outward_direction: Vector2 = outward_bias.normalized()
	var outward_tangent: Vector2 = Vector2(-outward_direction.y, outward_direction.x)
	var board_unit: float = max(1.0, min(board_size.x, board_size.y))
	var distance_ratio: float = distance / board_unit
	var midpoint_radius_ratio: float = midpoint.distance_to(board_center) / board_unit
	var radial_alignment: float = absf(direction_normalized.dot(outward_direction))
	var tangential_alignment: float = absf(direction_normalized.dot(outward_tangent))
	var direction_angle: float = atan2(direction_normalized.y, direction_normalized.x)
	var angle_bucket: int = int(floor(((direction_angle + PI) / TAU) * 12.0))
	var edge_hash: int = _derive_seed(
		board_seed,
		"edge-family:%s|%d|%d|%d" % [
			_edge_key(from_node_id, to_node_id),
			int(round(distance_ratio * 1000.0)),
			angle_bucket,
			int(round(midpoint_radius_ratio * 1000.0)),
		]
	)
	var path_family: String = _resolve_edge_path_family(
		edge_hash,
		distance_ratio,
		midpoint_radius_ratio,
		radial_alignment,
		tangential_alignment
	)
	var locked_edge: bool = (
		String(from_node.get("state_semantic", "")) == "locked"
		or String(to_node.get("state_semantic", "")) == "locked"
	)
	var profile_multiplier: float = _edge_profile_curve_multiplier(template_profile)
	var tangent_length: float = clampf(distance * 0.20, 24.0, 104.0)
	var p1: Vector2 = p0 + direction_normalized * tangent_length
	var p2: Vector2 = p3 - direction_normalized * tangent_length

	match path_family:
		PATH_FAMILY_SHORT_STRAIGHT:
			var straight_detour: float = 10.0 if locked_edge else 0.0
			p1 += outward_direction * straight_detour
			p2 += outward_direction * straight_detour * 0.72
		PATH_FAMILY_GENTLE_CURVE:
			tangent_length = clampf(distance * 0.21, 26.0, 108.0)
			p1 = p0 + direction_normalized * tangent_length
			p2 = p3 - direction_normalized * tangent_length
			var gentle_curvature: float = clampf(distance * 0.12 * profile_multiplier, 12.0, 72.0)
			var gentle_outward: float = max(14.0 if locked_edge else 0.0, gentle_curvature * 0.12)
			var gentle_sign: float = _curve_sign_for(edge_hash, normal, outward_direction, false)
			var gentle_offset: Vector2 = normal * gentle_curvature * gentle_sign + outward_direction * gentle_outward
			p1 += gentle_offset
			p2 += gentle_offset * 0.88
		PATH_FAMILY_WIDER_CURVE:
			tangent_length = clampf(distance * 0.24, 28.0, 116.0)
			p1 = p0 + direction_normalized * tangent_length
			p2 = p3 - direction_normalized * tangent_length
			var wide_curvature: float = clampf(distance * 0.19 * profile_multiplier, 18.0, 104.0)
			var wide_outward: float = max(18.0 if locked_edge else 0.0, wide_curvature * 0.18)
			var wide_sign: float = _curve_sign_for(_derive_seed(edge_hash, "wider"), normal, outward_direction, true)
			var wide_offset: Vector2 = normal * wide_curvature * wide_sign + outward_direction * wide_outward
			p1 += wide_offset
			p2 += wide_offset * 0.93
		PATH_FAMILY_OUTWARD_RECONNECTING_ARC:
			tangent_length = clampf(distance * 0.26, 30.0, 120.0)
			p1 = p0 + direction_normalized * tangent_length
			p2 = p3 - direction_normalized * tangent_length
			var arc_curvature: float = clampf(distance * 0.11 * profile_multiplier, 10.0, 56.0)
			var arc_outward: float = clampf(distance * 0.19, 26.0, 96.0) + (12.0 if locked_edge else 0.0)
			var arc_sign: float = _curve_sign_for(_derive_seed(edge_hash, "arc"), normal, outward_direction, true)
			p1 += outward_direction * arc_outward * 1.08 + normal * arc_curvature * arc_sign * 0.62
			p2 += outward_direction * arc_outward * 0.82 + normal * arc_curvature * arc_sign * 0.34

	return {
		"path_family": path_family,
		"points": _sample_cubic_bezier(p0, p1, p2, p3, 16),
	}


func _resolve_edge_path_family(
	edge_hash: int,
	distance_ratio: float,
	midpoint_radius_ratio: float,
	radial_alignment: float,
	tangential_alignment: float
) -> String:
	var seed_bias: float = float(abs(edge_hash % 997)) / 996.0
	var straight_distance_cap: float = lerpf(0.162, 0.204, seed_bias)
	var straight_alignment_floor: float = lerpf(0.78, 0.58, seed_bias)
	if distance_ratio <= straight_distance_cap and radial_alignment >= straight_alignment_floor:
		return PATH_FAMILY_SHORT_STRAIGHT

	var reconnect_tangent_floor: float = lerpf(0.76, 0.64, seed_bias)
	var reconnect_outer_floor: float = lerpf(0.30, 0.22, seed_bias)
	if tangential_alignment >= reconnect_tangent_floor and midpoint_radius_ratio >= reconnect_outer_floor:
		return PATH_FAMILY_OUTWARD_RECONNECTING_ARC

	var wide_distance_floor: float = lerpf(0.248, 0.308, seed_bias)
	var wide_tangent_floor: float = lerpf(0.50, 0.62, seed_bias)
	var wide_outer_floor: float = lerpf(0.22, 0.34, seed_bias)
	if distance_ratio >= wide_distance_floor or (
		tangential_alignment >= wide_tangent_floor and midpoint_radius_ratio >= wide_outer_floor
	):
		return PATH_FAMILY_WIDER_CURVE
	return PATH_FAMILY_GENTLE_CURVE


func _edge_profile_curve_multiplier(template_profile: String) -> float:
	match template_profile:
		"corridor":
			return 0.94
		"openfield":
			return 1.06
		"loop":
			return 1.14
		_:
			return 1.0


func _curve_sign_for(edge_hash: int, normal: Vector2, outward_direction: Vector2, prefer_outward: bool) -> float:
	var outward_alignment: float = normal.dot(outward_direction)
	if absf(outward_alignment) >= 0.12:
		var outward_sign: float = 1.0 if outward_alignment >= 0.0 else -1.0
		if prefer_outward or ((edge_hash >> 1) & 1) == 0:
			return outward_sign
		return -outward_sign
	return 1.0 if (edge_hash & 1) == 0 else -1.0


func _sample_cubic_bezier(
	p0: Vector2,
	p1: Vector2,
	p2: Vector2,
	p3: Vector2,
	segment_count: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segment_count + 1):
		var t: float = float(index) / float(segment_count)
		var one_minus_t: float = 1.0 - t
		var point: Vector2 = (
			p0 * pow(one_minus_t, 3.0)
			+ p1 * 3.0 * pow(one_minus_t, 2.0) * t
			+ p2 * 3.0 * one_minus_t * pow(t, 2.0)
			+ p3 * pow(t, 3.0)
		)
		points.append(point)
	return points


func _edge_semantic_for(from_node: Dictionary, to_node: Dictionary) -> String:
	if String(from_node.get("state_semantic", "")) == "locked" or String(to_node.get("state_semantic", "")) == "locked":
		return "locked"
	var from_resolved: bool = String(from_node.get("node_state", "")) == MapRuntimeStateScript.NODE_STATE_RESOLVED
	var to_resolved: bool = String(to_node.get("node_state", "")) == MapRuntimeStateScript.NODE_STATE_RESOLVED
	if from_resolved and to_resolved:
		return "resolved"
	return "open"


func _semantic_for_node(node_state: String, is_current: bool) -> String:
	if is_current:
		return "current"
	match node_state:
		MapRuntimeStateScript.NODE_STATE_LOCKED:
			return "locked"
		MapRuntimeStateScript.NODE_STATE_RESOLVED:
			return "resolved"
		_:
			return "open"


func _clearing_radius_for(node_family: String, state_semantic: String, board_size: Vector2) -> float:
	var board_unit: float = min(board_size.x, board_size.y)
	var factor: float = 0.058
	match node_family:
		"start":
			factor = 0.076
		"boss":
			factor = 0.072
		"reward", "rest", "merchant", "blacksmith", "key":
			factor = 0.067
		"combat", "event":
			factor = 0.061
	if state_semantic == "current":
		factor += 0.010
	if state_semantic == "resolved":
		factor -= 0.008
	return clampf(board_unit * factor, 42.0, 88.0)


func _clamp_focus_offset(desired_offset: Vector2, max_focus_offset: Vector2) -> Vector2:
	return Vector2(
		clampf(desired_offset.x, -max_focus_offset.x, max_focus_offset.x),
		clampf(desired_offset.y, -max_focus_offset.y, max_focus_offset.y)
	)


func _clamp_to_board(position: Vector2, board_size: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, MIN_BOARD_MARGIN.x, board_size.x - MIN_BOARD_MARGIN.x),
		clampf(position.y, MIN_BOARD_MARGIN.y, board_size.y - MIN_BOARD_MARGIN.y)
	)


func _relax_collisions(world_positions: Dictionary, graph_snapshot: Array[Dictionary], board_size: Vector2, depth_by_node_id: Dictionary) -> void:
	var ordered_node_ids: Array[int] = []
	for node_entry in graph_snapshot:
		ordered_node_ids.append(int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)))
	var board_unit: float = min(board_size.x, board_size.y)
	for _iteration in range(10):
		for left_index in range(ordered_node_ids.size()):
			var left_node_id: int = ordered_node_ids[left_index]
			for right_index in range(left_index + 1, ordered_node_ids.size()):
				var right_node_id: int = ordered_node_ids[right_index]
				if left_node_id == 0 and right_node_id == 0:
					continue
				var left_position: Vector2 = world_positions.get(left_node_id, Vector2.ZERO)
				var right_position: Vector2 = world_positions.get(right_node_id, Vector2.ZERO)
				var delta: Vector2 = right_position - left_position
				var distance: float = delta.length()
				var left_depth: int = int(depth_by_node_id.get(left_node_id, 0))
				var right_depth: int = int(depth_by_node_id.get(right_node_id, 0))
				var minimum_spacing: float = clampf(board_unit * 0.156, 132.0, 176.0)
				if left_depth <= 1 or right_depth <= 1:
					minimum_spacing += 14.0
				elif left_depth == 2 and right_depth == 2:
					minimum_spacing += 6.0
				if distance >= minimum_spacing:
					continue
				var push_direction: Vector2 = Vector2.RIGHT if distance <= 0.001 else delta / distance
				var push_amount: float = (minimum_spacing - max(distance, 0.001)) * 0.5
				if left_node_id != 0:
					world_positions[left_node_id] = _clamp_to_board(left_position - push_direction * push_amount, board_size)
				if right_node_id != 0:
					world_positions[right_node_id] = _clamp_to_board(right_position + push_direction * push_amount, board_size)


func _build_board_seed(run_state: RunState, active_template_id: String, graph_snapshot: Array[Dictionary]) -> int:
	var signature_parts: PackedStringArray = []
	for node_entry in graph_snapshot:
		var adjacent_ids: Array[String] = []
		for adjacent_node_id in _adjacent_ids_from_entry(node_entry):
			adjacent_ids.append(str(adjacent_node_id))
		signature_parts.append(
			"%d|%s|%s|%s" % [
				int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)),
				String(node_entry.get("node_family", "")),
				String(node_entry.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED)),
				",".join(adjacent_ids),
			]
		)
	var raw_seed: String = "%d|%d|%s|%s" % [
		int(run_state.run_seed),
		int(run_state.stage_index),
		active_template_id,
		"|".join(signature_parts),
	]
	return _hash_seed_string(raw_seed)


func _derive_seed(board_seed: int, salt: String) -> int:
	return _hash_seed_string("%d|%s" % [board_seed, salt])


func _hash_seed_string(value: String) -> int:
	var accumulator: int = 216613626
	var bytes: PackedByteArray = value.to_utf8_buffer()
	for byte in bytes:
		accumulator = abs(int((accumulator ^ int(byte)) * 16777619))
	if accumulator == 0:
		return 1
	return accumulator


func _template_profile_for_id(active_template_id: String) -> String:
	if active_template_id.contains("openfield"):
		return "openfield"
	if active_template_id.contains("loop"):
		return "loop"
	return DEFAULT_TEMPLATE_PROFILE


func _adjacent_ids_for(graph_by_id: Dictionary, node_id: int) -> PackedInt32Array:
	return _adjacent_ids_from_entry(graph_by_id.get(node_id, {}))


func _adjacent_ids_from_entry(node_entry: Dictionary) -> PackedInt32Array:
	var adjacent_variant: Variant = node_entry.get("adjacent_node_ids", PackedInt32Array())
	if typeof(adjacent_variant) == TYPE_PACKED_INT32_ARRAY:
		return adjacent_variant
	var adjacent_ids := PackedInt32Array()
	if typeof(adjacent_variant) == TYPE_ARRAY:
		for adjacent_node_id in adjacent_variant:
			adjacent_ids.append(int(adjacent_node_id))
	return adjacent_ids


func _sorted_adjacent_ids(graph_by_id: Dictionary, node_id: int) -> Array[int]:
	var adjacent_ids: Array[int] = []
	for adjacent_node_id in _adjacent_ids_for(graph_by_id, node_id):
		adjacent_ids.append(adjacent_node_id)
	adjacent_ids.sort()
	return adjacent_ids


func _edge_key(from_node_id: int, to_node_id: int) -> String:
	var ordered_ids: Array[int] = [from_node_id, to_node_id]
	ordered_ids.sort()
	return "%d:%d" % [ordered_ids[0], ordered_ids[1]]


func _average_float_array(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += value
	return total / float(values.size())


func _sort_node_entry_by_id(left: Dictionary, right: Dictionary) -> bool:
	return int(left.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)) < int(right.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))


func _sort_visible_node_entries(left: Dictionary, right: Dictionary) -> bool:
	var left_current: bool = bool(left.get("is_current", false))
	var right_current: bool = bool(right.get("is_current", false))
	if left_current != right_current:
		return left_current
	var left_adjacent: bool = bool(left.get("is_adjacent", false))
	var right_adjacent: bool = bool(right.get("is_adjacent", false))
	if left_adjacent != right_adjacent:
		return left_adjacent
	return int(left.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)) < int(right.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
