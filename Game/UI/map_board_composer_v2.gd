# Layer: UI
extends RefCounted
class_name MapBoardComposerV2

const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const MapBoardBackdropBuilderScript = preload("res://Game/UI/map_board_backdrop_builder.gd")
const MapBoardGroundBuilderScript = preload("res://Game/UI/map_board_ground_builder.gd")
const MapBoardFillerBuilderScript = preload("res://Game/UI/map_board_filler_builder.gd")
const MapBoardGeometryScript = preload("res://Game/UI/map_board_geometry.gd")
const MapBoardEdgeRoutingScript = preload("res://Game/UI/map_board_edge_routing.gd")
const MapBoardLayoutSolverScript = preload("res://Game/UI/map_board_layout_solver.gd")

const DEFAULT_TEMPLATE_PROFILE := "corridor"
const BASE_CENTER_FACTOR := Vector2(0.50, 0.60)
const MIN_BOARD_MARGIN := Vector2(136.0, 108.0)
const STABLE_LAYOUT_REUSE_POSITION_TOLERANCE := 48.0
const OPENING_BRANCH_ANGLE_PRESETS := {
	1: [-PI * 0.5],
	2: [-1.94, -1.06],
	3: [-2.22, -1.50, -0.80],
	4: [-2.30, -1.74, -1.08, -0.56],
}
const DEPTH_STEP_FACTORS := [0.0, 0.220, 0.190, 0.176, 0.166, 0.158]
const DEPTH_SPREAD_FACTORS := [0.0, 0.028, 0.042, 0.050, 0.056, 0.060]
const DEPTH_DIRECTION_PULL_FACTORS := [0.0, 0.0, 0.24, 0.40, 0.56, 0.70]
const DEPTH_LATERAL_SPREAD_SCALE_FACTORS := [1.0, 0.80, 0.54, 0.38, 0.26, 0.20]
const DEPTH_DOWNWARD_BIAS_FACTORS := [0.0, 0.0, 0.056, 0.100, 0.148, 0.184]
const DEPTH_CENTER_PULL_FACTORS := [0.0, 0.0, 0.062, 0.120, 0.208, 0.280]
const BRANCH_GLOBAL_ROTATION_RANGE := 0.92
const BRANCH_ANGLE_NOISE := 0.04
const PATH_FAMILY_SHORT_STRAIGHT := "short_straight"
const PATH_FAMILY_GENTLE_CURVE := "gentle_curve"
const PATH_FAMILY_WIDER_CURVE := "wider_curve"
const PATH_FAMILY_OUTWARD_RECONNECTING_ARC := "outward_reconnecting_arc"
const EDGE_NODE_AVOIDANCE_PADDING := 18.0
const EDGE_NODE_AVOIDANCE_MIN_SHIFT := 24.0
const EDGE_NODE_AVOIDANCE_MAX_SHIFT := 86.0
const EDGE_NODE_AVOIDANCE_MAX_PASSES := 5
func compose(
	run_state: RunState,
	board_size: Vector2,
	focus_anchor_factor: Vector2,
	max_focus_offset: Vector2,
	stable_layout: Dictionary = {}
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
	var current_node_id: int = int(map_runtime_state.current_node_id)
	var active_template_id: String = String(map_runtime_state.get_active_template_id())
	var template_profile: String = _template_profile_for_id(active_template_id)
	var board_seed: int = _build_board_seed(run_state, active_template_id, graph_snapshot)
	var side_quest_highlight: Dictionary = map_runtime_state.build_side_quest_highlight_snapshot()
	var layout_context: Dictionary = _build_layout_context(
		graph_snapshot,
		graph_by_id,
		depth_by_node_id,
		start_node_id,
		template_profile,
		board_seed
	)
	var stable_world_positions: Dictionary = (stable_layout.get("world_positions", {}) as Dictionary).duplicate(true)
	var can_reuse_stable_layout: bool = _stable_layout_matches_board_size(stable_world_positions, start_node_id, board_size)
	var world_positions: Dictionary = stable_world_positions if can_reuse_stable_layout else {}
	if world_positions.is_empty(): world_positions = _build_world_positions(graph_snapshot, board_size, layout_context, template_profile, board_seed)
	var graph_nodes: Array[Dictionary] = _build_graph_node_entries(graph_snapshot, world_positions, board_size)
	var layout_edges: Array = (stable_layout.get("layout_edges", []) as Array).duplicate(true) if can_reuse_stable_layout else []
	if layout_edges.is_empty(): layout_edges = _build_full_edge_layouts(graph_by_id, graph_nodes, world_positions, layout_context, template_profile, board_seed, board_size)
	var visible_nodes: Array = _build_visible_node_entries(graph_snapshot, graph_by_id, world_positions, current_node_id, board_size)
	var visible_edges: Array = _build_visible_edges(layout_edges, visible_nodes, current_node_id, board_size)
	var focus_anchor: Vector2 = board_size * focus_anchor_factor
	var current_world_position: Vector2 = world_positions.get(current_node_id, board_size * BASE_CENTER_FACTOR)
	var focus_offset: Vector2 = _clamp_focus_offset(focus_anchor - current_world_position, max_focus_offset)
	var ground_shapes: Array = (stable_layout.get("ground_shapes", []) as Array).duplicate(true) if can_reuse_stable_layout else []
	if ground_shapes.is_empty(): ground_shapes = MapBoardGroundBuilderScript.build_ground_shapes(board_size, graph_nodes, template_profile, board_seed, BASE_CENTER_FACTOR, MIN_BOARD_MARGIN)
	var filler_shapes: Array = (stable_layout.get("filler_shapes", []) as Array).duplicate(true) if can_reuse_stable_layout else []
	if filler_shapes.is_empty(): filler_shapes = MapBoardFillerBuilderScript.build_filler_shapes(board_size, graph_nodes, layout_edges, template_profile, board_seed, BASE_CENTER_FACTOR, MIN_BOARD_MARGIN)
	var forest_shapes: Array = (stable_layout.get("forest_shapes", []) as Array).duplicate(true) if can_reuse_stable_layout else []
	if forest_shapes.is_empty(): forest_shapes = MapBoardBackdropBuilderScript.build_forest_shapes(board_size, graph_nodes, graph_by_id, world_positions, template_profile, board_seed, BASE_CENTER_FACTOR, MIN_BOARD_MARGIN)
	return {
		"seed": board_seed,
		"template_profile": template_profile,
		"current_node_id": current_node_id,
		"side_quest_highlight_node_id": int(side_quest_highlight.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)),
		"side_quest_highlight_state": String(side_quest_highlight.get("highlight_state", "")),
		"world_positions": world_positions,
		"layout_edges": layout_edges,
		"visible_nodes": visible_nodes,
		"visible_edges": visible_edges,
		"ground_shapes": ground_shapes,
		"filler_shapes": filler_shapes,
		"forest_shapes": forest_shapes,
		"focus_offset": focus_offset,
	}


func build_clearing_radius(node_family: String, state_semantic: String, board_size: Vector2) -> float:
	return _clearing_radius_for(node_family, state_semantic, board_size)


func _empty_composition() -> Dictionary:
	return {
		"seed": 0,
		"template_profile": DEFAULT_TEMPLATE_PROFILE,
		"current_node_id": MapRuntimeStateScript.NO_PENDING_NODE_ID,
		"side_quest_highlight_node_id": MapRuntimeStateScript.NO_PENDING_NODE_ID,
		"side_quest_highlight_state": "",
		"world_positions": {},
		"layout_edges": [],
		"visible_nodes": [],
		"visible_edges": [],
		"ground_shapes": [],
		"filler_shapes": [],
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
func _build_layout_context(
	graph_snapshot: Array[Dictionary],
	graph_by_id: Dictionary,
	depth_by_node_id: Dictionary,
	start_node_id: int,
	template_profile: String,
	board_seed: int
) -> Dictionary:
	var parent_ids_by_node_id: Dictionary = _build_parent_ids_by_node_id(graph_by_id, depth_by_node_id)
	var primary_parent_by_node_id: Dictionary = _build_primary_parent_by_node_id(parent_ids_by_node_id)
	var branch_root_by_node_id: Dictionary = _build_branch_root_by_node_id(
		graph_snapshot,
		depth_by_node_id,
		start_node_id,
		primary_parent_by_node_id
	)
	return {
		"start_node_id": start_node_id,
		"depth_by_node_id": depth_by_node_id,
		"degree_by_node_id": _build_degree_by_node_id(graph_by_id),
		"parent_ids_by_node_id": parent_ids_by_node_id,
		"primary_parent_by_node_id": primary_parent_by_node_id,
		"branch_root_by_node_id": branch_root_by_node_id,
		"child_ids_by_parent": _build_child_ids_by_parent(primary_parent_by_node_id),
		"branch_direction_by_root": _build_branch_direction_by_root(graph_by_id, start_node_id, template_profile, board_seed),
		"max_depth": _max_depth_from_values(depth_by_node_id.values()),
	}
func _build_degree_by_node_id(graph_by_id: Dictionary) -> Dictionary:
	var degree_by_node_id: Dictionary = {}
	for node_id_variant in graph_by_id.keys():
		var node_id: int = int(node_id_variant)
		degree_by_node_id[node_id] = _adjacent_ids_for(graph_by_id, node_id).size()
	return degree_by_node_id
func _build_parent_ids_by_node_id(graph_by_id: Dictionary, depth_by_node_id: Dictionary) -> Dictionary:
	var parent_ids_by_node_id: Dictionary = {}
	for node_id_variant in graph_by_id.keys():
		var node_id: int = int(node_id_variant)
		var node_depth: int = int(depth_by_node_id.get(node_id, 0))
		var parent_ids: Array[int] = []
		for adjacent_node_id in _adjacent_ids_for(graph_by_id, node_id):
			if int(depth_by_node_id.get(adjacent_node_id, -1)) == node_depth - 1:
				parent_ids.append(adjacent_node_id)
		parent_ids.sort()
		parent_ids_by_node_id[node_id] = parent_ids
	return parent_ids_by_node_id
func _build_primary_parent_by_node_id(parent_ids_by_node_id: Dictionary) -> Dictionary:
	var primary_parent_by_node_id: Dictionary = {}
	for node_id_variant in parent_ids_by_node_id.keys():
		var node_id: int = int(node_id_variant)
		var parent_ids: Array[int] = _int_array_from_variant(parent_ids_by_node_id.get(node_id, []))
		if parent_ids.is_empty():
			continue
		primary_parent_by_node_id[node_id] = parent_ids[0]
	return primary_parent_by_node_id
func _build_branch_root_by_node_id(
	graph_snapshot: Array[Dictionary],
	depth_by_node_id: Dictionary,
	start_node_id: int,
	primary_parent_by_node_id: Dictionary
) -> Dictionary:
	var branch_root_by_node_id: Dictionary = {start_node_id: start_node_id}
	for node_entry in graph_snapshot:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var node_depth: int = int(depth_by_node_id.get(node_id, 0))
		if node_depth <= 0:
			continue
		if node_depth == 1:
			branch_root_by_node_id[node_id] = node_id
			continue
		var walker_id: int = int(primary_parent_by_node_id.get(node_id, start_node_id))
		while int(depth_by_node_id.get(walker_id, 0)) > 1:
			walker_id = int(primary_parent_by_node_id.get(walker_id, start_node_id))
		branch_root_by_node_id[node_id] = walker_id
	return branch_root_by_node_id
func _build_child_ids_by_parent(primary_parent_by_node_id: Dictionary) -> Dictionary:
	var child_ids_by_parent: Dictionary = {}
	var sorted_node_ids: Array[int] = []
	for node_id_variant in primary_parent_by_node_id.keys():
		sorted_node_ids.append(int(node_id_variant))
	sorted_node_ids.sort()
	for node_id in sorted_node_ids:
		var parent_id: int = int(primary_parent_by_node_id.get(node_id, MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if not child_ids_by_parent.has(parent_id):
			child_ids_by_parent[parent_id] = []
		var child_ids: Array[int] = _int_array_from_variant(child_ids_by_parent.get(parent_id, []))
		child_ids.append(node_id)
		child_ids_by_parent[parent_id] = child_ids
	return child_ids_by_parent
func _build_branch_direction_by_root(
	graph_by_id: Dictionary,
	start_node_id: int,
	template_profile: String,
	board_seed: int
) -> Dictionary:
	var branch_root_ids: Array[int] = _sorted_adjacent_ids(graph_by_id, start_node_id)
	var branch_angles: Array[float] = _branch_angles_for_count(branch_root_ids.size())
	var branch_direction_by_root: Dictionary = {}
	var profile_rotation: float = 0.0
	var rotation_rng := RandomNumberGenerator.new()
	rotation_rng.seed = _derive_seed(board_seed, "branch-global-rotation")
	var global_rotation: float = rotation_rng.randf_range(-BRANCH_GLOBAL_ROTATION_RANGE, BRANCH_GLOBAL_ROTATION_RANGE)
	match template_profile:
		"corridor":
			profile_rotation = -0.04
		"openfield":
			profile_rotation = 0.03
		"loop":
			profile_rotation = 0.01
	for index in range(branch_root_ids.size()):
		var branch_root_id: int = branch_root_ids[index]
		var base_angle: float = branch_angles[index] if index < branch_angles.size() else lerpf(-2.74, -0.40, float(index) / float(max(1, branch_root_ids.size() - 1)))
		var branch_rng := RandomNumberGenerator.new()
		branch_rng.seed = _derive_seed(board_seed, "branch-angle:%d" % branch_root_id)
		var angle: float = wrapf(base_angle + global_rotation + profile_rotation + branch_rng.randf_range(-BRANCH_ANGLE_NOISE, BRANCH_ANGLE_NOISE), -PI, PI)
		branch_direction_by_root[branch_root_id] = Vector2(cos(angle), sin(angle)).normalized()
	return branch_direction_by_root
func _branch_angles_for_count(branch_count: int) -> Array[float]:
	if OPENING_BRANCH_ANGLE_PRESETS.has(branch_count):
		var preset_angles: Array = OPENING_BRANCH_ANGLE_PRESETS[branch_count]
		var typed_angles: Array[float] = []
		for angle_value in preset_angles:
			typed_angles.append(float(angle_value))
		return typed_angles
	var angles: Array[float] = []
	for index in range(branch_count):
		var t: float = 0.5 if branch_count <= 1 else float(index) / float(branch_count - 1)
		angles.append(lerpf(-2.72, -0.42, t))
	return angles
func _build_world_positions(
	graph_snapshot: Array[Dictionary],
	board_size: Vector2,
	layout_context: Dictionary,
	template_profile: String,
	board_seed: int
) -> Dictionary:
	return MapBoardLayoutSolverScript.build_world_positions(
		graph_snapshot,
		board_size,
		layout_context,
		template_profile,
		board_seed,
		{
			"base_center_factor": BASE_CENTER_FACTOR,
			"min_board_margin": MIN_BOARD_MARGIN,
			"depth_step_factors": DEPTH_STEP_FACTORS,
			"depth_spread_factors": DEPTH_SPREAD_FACTORS,
			"depth_direction_pull_factors": DEPTH_DIRECTION_PULL_FACTORS,
			"depth_lateral_spread_scale_factors": DEPTH_LATERAL_SPREAD_SCALE_FACTORS,
			"depth_downward_bias_factors": DEPTH_DOWNWARD_BIAS_FACTORS,
			"depth_center_pull_factors": DEPTH_CENTER_PULL_FACTORS,
			"clearing_radius_by_node_id": _build_open_clearing_radius_by_node_id(graph_snapshot, board_size),
		}
	)
func _build_open_clearing_radius_by_node_id(graph_snapshot: Array[Dictionary], board_size: Vector2) -> Dictionary:
	var clearing_radius_by_node_id: Dictionary = {}
	for node_entry in graph_snapshot:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		clearing_radius_by_node_id[node_id] = _clearing_radius_for(String(node_entry.get("node_family", "")), "open", board_size)
	return clearing_radius_by_node_id
func _int_array_from_variant(value: Variant) -> Array[int]:
	return MapBoardLayoutSolverScript.int_array_from_variant(value)
func _branch_direction_for_root(layout_context: Dictionary, branch_root_id: int) -> Vector2:
	return MapBoardLayoutSolverScript.branch_direction_for_root(layout_context, branch_root_id)


func _max_depth_from_values(depth_values: Array) -> int:
	var max_depth: int = 0
	for depth_value in depth_values:
		max_depth = max(max_depth, int(depth_value))
	return max_depth


func _average_vector2_array(values: Array[Vector2]) -> Vector2:
	if values.is_empty():
		return Vector2.ZERO
	var total: Vector2 = Vector2.ZERO
	for value in values:
		total += value
	return total / float(values.size())


func _stable_layout_matches_board_size(world_positions: Dictionary, start_node_id: int, board_size: Vector2) -> bool:
	if world_positions.is_empty():
		return false
	var start_position: Vector2 = world_positions.get(start_node_id, Vector2.ZERO)
	if start_position == Vector2.ZERO:
		return false
	var expected_origin: Vector2 = board_size * BASE_CENTER_FACTOR
	return start_position.distance_to(expected_origin) <= STABLE_LAYOUT_REUSE_POSITION_TOLERANCE


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
		var is_adjacent: bool = current_adjacent_ids.has(node_id)
		var state_semantic: String = _semantic_for_node(node_state, is_current)
		var world_position: Vector2 = world_positions.get(node_id, board_size * BASE_CENTER_FACTOR)
		visible_nodes.append({
			"node_id": node_id,
			"node_family": node_family,
			"node_state": node_state,
			"state_semantic": state_semantic,
			"is_current": is_current,
			"is_adjacent": is_adjacent,
			"show_known_icon": node_state != MapRuntimeStateScript.NODE_STATE_UNDISCOVERED or is_current,
			"icon_texture_path": _icon_texture_path_for_family(node_family),
			"node_plate_texture_path": _node_plate_texture_path_for(state_semantic),
			"clearing_decal_texture_path": _clearing_decal_texture_path_for(node_family),
			"world_position": world_position,
			"clearing_radius": _clearing_radius_for(node_family, state_semantic, board_size),
		})
	visible_nodes.sort_custom(Callable(self, "_sort_visible_node_entries"))
	return visible_nodes
func _build_visible_edges(layout_edges: Array, visible_nodes: Array[Dictionary], current_node_id: int, board_size: Vector2) -> Array[Dictionary]:
	var visible_node_ids: Dictionary = {}
	var visible_node_by_id: Dictionary = {}
	for node_entry in visible_nodes:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		visible_node_ids[node_id] = true
		visible_node_by_id[node_id] = node_entry

	var history_edges: Array[Dictionary] = []
	var local_focus_edges: Array[Dictionary] = []
	for edge_variant in layout_edges:
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var base_edge: Dictionary = edge_variant
		var from_node_id: int = int(base_edge.get("from_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var to_node_id: int = int(base_edge.get("to_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if not visible_node_ids.has(from_node_id) or not visible_node_ids.has(to_node_id):
			continue
		var from_node: Dictionary = visible_node_by_id.get(from_node_id, {})
		var to_node: Dictionary = visible_node_by_id.get(to_node_id, {})
		var is_local_focus_edge: bool = from_node_id == current_node_id or to_node_id == current_node_id
		if not is_local_focus_edge and not _should_show_history_edge(from_node, to_node):
			continue
		var edge_points: PackedVector2Array = base_edge.get("points", PackedVector2Array())
		if not is_local_focus_edge and (
			MapBoardGeometryScript.polyline_hits_other_visible_nodes(
				edge_points,
				from_node_id,
				to_node_id,
				visible_nodes,
				EDGE_NODE_AVOIDANCE_PADDING
			)
			or not MapBoardGeometryScript.polyline_stays_inside_board_frame(edge_points, board_size)
		):
			continue
		var edge_entry: Dictionary = base_edge.duplicate(true)
		edge_entry["state_semantic"] = _edge_semantic_for(from_node, to_node)
		edge_entry["is_history"] = not is_local_focus_edge
		if is_local_focus_edge:
			local_focus_edges.append(edge_entry)
		else:
			history_edges.append(edge_entry)
	var filtered_history_edges: Array[Dictionary] = _filter_non_crossing_history_edges(local_focus_edges, history_edges)
	return filtered_history_edges + local_focus_edges
func _build_full_edge_layouts(
	graph_by_id: Dictionary,
	graph_nodes: Array[Dictionary],
	world_positions: Dictionary,
	layout_context: Dictionary,
	template_profile: String,
	board_seed: int,
	board_size: Vector2
) -> Array[Dictionary]:
	var node_layout_by_id: Dictionary = {}
	for node_entry in graph_nodes:
		node_layout_by_id[int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))] = node_entry
	var depth_by_node_id: Dictionary = layout_context.get("depth_by_node_id", {})
	var layout_edges: Array[Dictionary] = []
	var processed_edges: Dictionary = {}
	for node_id_variant in graph_by_id.keys():
		var node_id: int = int(node_id_variant)
		for adjacent_node_id in _adjacent_ids_for(graph_by_id, node_id):
			var edge_key: String = _edge_key(node_id, adjacent_node_id)
			if processed_edges.has(edge_key):
				continue
			processed_edges[edge_key] = true
			var path_model: Dictionary = _build_edge_path_model(
				node_layout_by_id.get(node_id, {}),
				node_layout_by_id.get(adjacent_node_id, {}),
				graph_nodes,
				world_positions,
				layout_context,
				template_profile,
				board_seed,
				board_size
			)
			layout_edges.append({
				"from_node_id": node_id,
				"to_node_id": adjacent_node_id,
				"is_reconnect_edge": bool(path_model.get("is_reconnect_edge", false)),
				"depth_delta": abs(int(depth_by_node_id.get(node_id, 0)) - int(depth_by_node_id.get(adjacent_node_id, 0))),
				"path_family": String(path_model.get("path_family", PATH_FAMILY_GENTLE_CURVE)),
				"trail_texture_path": _trail_texture_path_for_family(String(path_model.get("path_family", PATH_FAMILY_GENTLE_CURVE))),
				"points": path_model.get("points", PackedVector2Array()),
			})
	layout_edges.sort_custom(func(left_edge: Dictionary, right_edge: Dictionary) -> bool:
		var left_key: String = _edge_key(int(left_edge.get("from_node_id", -1)), int(left_edge.get("to_node_id", -1)))
		var right_key: String = _edge_key(int(right_edge.get("from_node_id", -1)), int(right_edge.get("to_node_id", -1)))
		return left_key < right_key
	)
	return layout_edges
func _filter_non_crossing_history_edges(
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


func _build_graph_node_entries(graph_snapshot: Array[Dictionary], world_positions: Dictionary, board_size: Vector2) -> Array[Dictionary]:
	var graph_nodes: Array[Dictionary] = []
	for node_entry in graph_snapshot:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		graph_nodes.append({
			"node_id": node_id,
			"world_position": world_positions.get(node_id, Vector2.ZERO),
			"clearing_radius": _clearing_radius_for(String(node_entry.get("node_family", "")), "open", board_size),
	})
	return graph_nodes


func _build_edge_path_model(
	from_node: Dictionary,
	to_node: Dictionary,
	visible_nodes: Array[Dictionary],
	world_positions: Dictionary,
	layout_context: Dictionary,
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
			"is_reconnect_edge": false,
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
	var depth_by_node_id: Dictionary = layout_context.get("depth_by_node_id", {})
	var primary_parent_by_node_id: Dictionary = layout_context.get("primary_parent_by_node_id", {})
	var branch_root_by_node_id: Dictionary = layout_context.get("branch_root_by_node_id", {})
	var from_depth: int = int(depth_by_node_id.get(from_node_id, 0))
	var to_depth: int = int(depth_by_node_id.get(to_node_id, 0))
	var is_primary_corridor_edge: bool = (
		int(primary_parent_by_node_id.get(from_node_id, MapRuntimeStateScript.NO_PENDING_NODE_ID)) == to_node_id
		or int(primary_parent_by_node_id.get(to_node_id, MapRuntimeStateScript.NO_PENDING_NODE_ID)) == from_node_id
	)
	var is_reconnect_edge: bool = not is_primary_corridor_edge
	var same_branch: bool = int(branch_root_by_node_id.get(from_node_id, from_node_id)) == int(branch_root_by_node_id.get(to_node_id, to_node_id))
	var deeper_node_id: int = to_node_id if to_depth >= from_depth else from_node_id
	var branch_direction: Vector2 = _branch_direction_for_root(layout_context, int(branch_root_by_node_id.get(deeper_node_id, deeper_node_id)))
	var branch_tangent: Vector2 = Vector2(-branch_direction.y, branch_direction.x)
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
		tangential_alignment,
		is_reconnect_edge,
		same_branch,
		abs(from_depth - to_depth)
	)
	var locked_edge: bool = (
		String(from_node.get("state_semantic", "")) == "locked"
		or String(to_node.get("state_semantic", "")) == "locked"
	)
	var profile_multiplier: float = _edge_profile_curve_multiplier(template_profile)
	var tangent_length: float = clampf(distance * 0.18, 22.0, 88.0)
	var p1: Vector2 = p0 + direction_normalized * tangent_length
	var p2: Vector2 = p3 - direction_normalized * tangent_length
	var branch_bias_amount: float = clampf(distance * 0.08, 8.0, 34.0)
	var branch_bias_sign: float = 1.0 if branch_tangent.dot(normal) >= 0.0 else -1.0
	var branch_bias: Vector2 = branch_tangent * branch_bias_amount * branch_bias_sign

	match path_family:
		PATH_FAMILY_SHORT_STRAIGHT:
			var straight_detour: float = 10.0 if locked_edge else 0.0
			p1 += outward_direction * straight_detour
			p2 += outward_direction * straight_detour * 0.72
		PATH_FAMILY_GENTLE_CURVE:
			tangent_length = clampf(distance * 0.18, 24.0, 92.0)
			p1 = p0 + direction_normalized * tangent_length
			p2 = p3 - direction_normalized * tangent_length
			var gentle_curvature: float = clampf(distance * 0.052 * profile_multiplier, 6.0, 28.0)
			var gentle_outward: float = max(6.0 if locked_edge else 0.0, gentle_curvature * 0.03)
			var gentle_sign: float = _curve_sign_for(edge_hash, normal, outward_direction, false)
			var gentle_offset: Vector2 = normal * gentle_curvature * gentle_sign + outward_direction * gentle_outward + branch_bias * 0.18
			p1 += gentle_offset
			p2 += gentle_offset * 0.82
		PATH_FAMILY_WIDER_CURVE:
			tangent_length = clampf(distance * 0.21, 28.0, 104.0)
			p1 = p0 + direction_normalized * tangent_length
			p2 = p3 - direction_normalized * tangent_length
			var wide_curvature: float = clampf(distance * 0.118 * profile_multiplier, 16.0, 62.0)
			var wide_outward: float = max(11.0 if locked_edge else 0.0, wide_curvature * 0.09)
			var wide_sign: float = _curve_sign_for(_derive_seed(edge_hash, "wider"), normal, outward_direction, true)
			var wide_offset: Vector2 = normal * wide_curvature * wide_sign + outward_direction * wide_outward + branch_bias * 0.46
			p1 += wide_offset
			p2 += wide_offset * 0.98
		PATH_FAMILY_OUTWARD_RECONNECTING_ARC:
			tangent_length = clampf(distance * 0.24, 30.0, 110.0)
			p1 = p0 + direction_normalized * tangent_length
			p2 = p3 - direction_normalized * tangent_length
			var arc_curvature: float = clampf(distance * 0.086 * profile_multiplier, 10.0, 40.0)
			var arc_outward: float = clampf(distance * 0.14, 18.0, 56.0) + (8.0 if locked_edge else 0.0)
			var arc_sign: float = _curve_sign_for(_derive_seed(edge_hash, "arc"), normal, outward_direction, true)
			p1 += outward_direction * arc_outward * 1.14 + normal * arc_curvature * arc_sign * 0.58
			p2 += outward_direction * arc_outward * 0.92 + normal * arc_curvature * arc_sign * 0.34
	var points: PackedVector2Array = _sample_cubic_bezier(p0, p1, p2, p3, 16)
	var avoidance_offset: Vector2 = MapBoardGeometryScript.edge_node_avoidance_offset(
		points,
		from_node_id,
		to_node_id,
		visible_nodes,
		p0,
		p3,
		midpoint,
		EDGE_NODE_AVOIDANCE_PADDING,
		EDGE_NODE_AVOIDANCE_MIN_SHIFT,
		EDGE_NODE_AVOIDANCE_MAX_SHIFT
	)
	var avoidance_pass: int = 0
	while avoidance_pass < EDGE_NODE_AVOIDANCE_MAX_PASSES and avoidance_offset != Vector2.ZERO:
		var avoidance_scale: float = 1.0 + float(avoidance_pass) * 0.55
		p1 += avoidance_offset * avoidance_scale
		p2 += avoidance_offset * avoidance_scale * 0.92
		points = _sample_cubic_bezier(p0, p1, p2, p3, 16)
		if not MapBoardGeometryScript.polyline_hits_other_visible_nodes(
			points,
			from_node_id,
			to_node_id,
			visible_nodes,
			EDGE_NODE_AVOIDANCE_PADDING
		):
			break
		avoidance_offset = MapBoardGeometryScript.edge_node_avoidance_offset(
			points,
			from_node_id,
			to_node_id,
			visible_nodes,
			p0,
			p3,
			midpoint,
			EDGE_NODE_AVOIDANCE_PADDING,
			EDGE_NODE_AVOIDANCE_MIN_SHIFT,
			EDGE_NODE_AVOIDANCE_MAX_SHIFT
		)
		avoidance_pass += 1
	if MapBoardGeometryScript.polyline_hits_other_visible_nodes(points, from_node_id, to_node_id, visible_nodes, EDGE_NODE_AVOIDANCE_PADDING):
		path_family = PATH_FAMILY_OUTWARD_RECONNECTING_ARC
		var outward_escape: float = clampf(distance * 0.42, 46.0, 148.0)
		var fallback_tangent: float = clampf(distance * 0.18, 24.0, 92.0)
		p1 = p0 + direction_normalized * fallback_tangent + outward_direction * outward_escape
		p2 = p3 - direction_normalized * fallback_tangent + outward_direction * outward_escape * 0.92
		points = _sample_cubic_bezier(p0, p1, p2, p3, 16)
		if MapBoardGeometryScript.polyline_hits_other_visible_nodes(points, from_node_id, to_node_id, visible_nodes, EDGE_NODE_AVOIDANCE_PADDING):
			var fallback_points: PackedVector2Array = _build_outer_reconnect_fallback_points(
				p0,
				p3,
				visible_nodes,
				from_node_id,
				to_node_id,
				board_size
			)
			if not fallback_points.is_empty():
				points = fallback_points
	return {
		"is_reconnect_edge": is_reconnect_edge,
		"path_family": path_family,
		"points": points,
	}
func _resolve_edge_path_family(
	edge_hash: int,
	distance_ratio: float,
	midpoint_radius_ratio: float,
	radial_alignment: float,
	tangential_alignment: float,
	is_reconnect_edge: bool,
	same_branch: bool,
	depth_delta: int
) -> String:
	var seed_bias: float = float(abs(edge_hash % 997)) / 996.0
	if is_reconnect_edge:
		if depth_delta == 0:
			return PATH_FAMILY_OUTWARD_RECONNECTING_ARC
		if distance_ratio >= lerpf(0.24, 0.31, seed_bias) or tangential_alignment >= lerpf(0.54, 0.68, seed_bias):
			return PATH_FAMILY_WIDER_CURVE
		return PATH_FAMILY_GENTLE_CURVE
	var straight_distance_cap: float = lerpf(0.194, 0.244, seed_bias)
	var straight_alignment_floor: float = lerpf(0.68, 0.82, seed_bias)
	if (
		distance_ratio <= straight_distance_cap
		and radial_alignment >= straight_alignment_floor
		and midpoint_radius_ratio <= lerpf(0.22, 0.32, seed_bias)
	):
		return PATH_FAMILY_SHORT_STRAIGHT

	var wide_distance_floor: float = lerpf(0.25, 0.33, seed_bias)
	var wide_tangent_floor: float = lerpf(0.56, 0.70, seed_bias)
	var wide_outer_floor: float = lerpf(0.20, 0.32, seed_bias)
	if distance_ratio >= wide_distance_floor or (
		tangential_alignment >= wide_tangent_floor and midpoint_radius_ratio >= wide_outer_floor
	):
		return PATH_FAMILY_WIDER_CURVE
	if not same_branch and (
		distance_ratio >= lerpf(0.21, 0.27, seed_bias)
		or tangential_alignment >= lerpf(0.42, 0.56, seed_bias)
	):
		return PATH_FAMILY_WIDER_CURVE
	return PATH_FAMILY_GENTLE_CURVE
func _edge_profile_curve_multiplier(template_profile: String) -> float:
	match template_profile:
		"corridor":
			return 0.76
		"openfield":
			return 0.82
		"loop":
			return 0.86
		_:
			return 0.80
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
func _build_outer_reconnect_fallback_points(
	p0: Vector2,
	p3: Vector2,
	visible_nodes: Array[Dictionary],
	from_node_id: int,
	to_node_id: int,
	board_size: Vector2
) -> PackedVector2Array:
	return MapBoardEdgeRoutingScript.build_outer_reconnect_fallback_points(
		p0,
		p3,
		visible_nodes,
		from_node_id,
		to_node_id,
		board_size,
		MIN_BOARD_MARGIN,
		EDGE_NODE_AVOIDANCE_PADDING
	)
func _edge_semantic_for(from_node: Dictionary, to_node: Dictionary) -> String:
	if String(from_node.get("state_semantic", "")) == "locked" or String(to_node.get("state_semantic", "")) == "locked":
		return "locked"
	var from_resolved: bool = String(from_node.get("node_state", "")) == MapRuntimeStateScript.NODE_STATE_RESOLVED
	var to_resolved: bool = String(to_node.get("node_state", "")) == MapRuntimeStateScript.NODE_STATE_RESOLVED
	if from_resolved and to_resolved:
		return "resolved"
	return "open"
func _should_show_history_edge(from_node: Dictionary, to_node: Dictionary) -> bool:
	var from_node_state: String = String(from_node.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
	var to_node_state: String = String(to_node.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
	if from_node_state == MapRuntimeStateScript.NODE_STATE_UNDISCOVERED or to_node_state == MapRuntimeStateScript.NODE_STATE_UNDISCOVERED:
		return false
	return true
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
func _icon_texture_path_for_family(node_family: String) -> String:
	match node_family:
		"start":
			return UiAssetPathsScript.START_ICON_TEXTURE_PATH
		"combat":
			return UiAssetPathsScript.ATTACK_ICON_TEXTURE_PATH
		"event":
			return UiAssetPathsScript.EVENT_ICON_TEXTURE_PATH
		"reward":
			return UiAssetPathsScript.REWARD_ICON_TEXTURE_PATH
		"hamlet":
			return UiAssetPathsScript.HAMLET_ICON_TEXTURE_PATH
		"rest":
			return UiAssetPathsScript.REST_ICON_TEXTURE_PATH
		"merchant":
			return UiAssetPathsScript.MERCHANT_ICON_TEXTURE_PATH
		"blacksmith":
			return UiAssetPathsScript.BLACKSMITH_ICON_TEXTURE_PATH
		"key":
			return UiAssetPathsScript.KEY_ICON_TEXTURE_PATH
		"boss":
			return UiAssetPathsScript.BOSS_ICON_TEXTURE_PATH
		_:
			return ""


func _node_plate_texture_path_for(state_semantic: String) -> String:
	match state_semantic:
		"resolved":
			return UiAssetPathsScript.MAP_NODE_PLATE_RESOLVED_TEXTURE_PATH
		"locked":
			return UiAssetPathsScript.MAP_NODE_PLATE_LOCKED_TEXTURE_PATH
		_:
			return UiAssetPathsScript.MAP_NODE_PLATE_REACHABLE_TEXTURE_PATH


func _clearing_decal_texture_path_for(node_family: String) -> String:
	match node_family:
		"boss", "key":
			return UiAssetPathsScript.MAP_CLEARING_DECAL_BOSS_TEXTURE_PATH
		_:
			return UiAssetPathsScript.MAP_CLEARING_DECAL_NEUTRAL_TEXTURE_PATH


func _trail_texture_path_for_family(path_family: String) -> String:
	return String(UiAssetPathsScript.MAP_TRAIL_TEXTURE_PATHS_BY_FAMILY.get(path_family, ""))
func _clearing_radius_for(node_family: String, state_semantic: String, board_size: Vector2) -> float:
	var board_unit: float = min(board_size.x, board_size.y)
	var factor: float = 0.054
	match node_family:
		"start":
			factor = 0.070
		"boss":
			factor = 0.068
		"reward", "rest", "merchant", "blacksmith", "key":
			factor = 0.062
		"combat", "event":
			factor = 0.057
	if state_semantic == "resolved":
		factor -= 0.006
	return clampf(board_unit * factor, 40.0, 78.0)


func _clamp_focus_offset(desired_offset: Vector2, max_focus_offset: Vector2) -> Vector2:
	return Vector2(
		clampf(desired_offset.x, -max_focus_offset.x, max_focus_offset.x),
		clampf(desired_offset.y, -max_focus_offset.y, max_focus_offset.y)
	)


func _build_board_seed(run_state: RunState, active_template_id: String, graph_snapshot: Array[Dictionary]) -> int:
	var signature_parts: PackedStringArray = []
	for node_entry in graph_snapshot:
		var adjacent_ids: Array[String] = []
		for adjacent_node_id in _adjacent_ids_from_entry(node_entry):
			adjacent_ids.append(str(adjacent_node_id))
		signature_parts.append(
			"%d|%s|%s" % [
				int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)),
				String(node_entry.get("node_family", "")),
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
	return MapBoardLayoutSolverScript.derive_seed(board_seed, salt)


func _hash_seed_string(value: String) -> int:
	return MapBoardLayoutSolverScript.hash_seed_string(value)


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
