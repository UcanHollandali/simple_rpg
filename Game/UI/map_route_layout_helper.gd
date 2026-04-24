# Layer: UI
extends RefCounted
class_name MapRouteLayoutHelper

const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const MapFocusHelperScript = preload("res://Game/UI/map_focus_helper.gd")


static func visible_routes_need_emergency_slot_layout(
	route_models_cache: Array[Dictionary],
	board_composition_cache: Dictionary,
	visible_route_indices: Array[int]
) -> bool:
	for visible_route_index in visible_route_indices:
		if visible_route_index < 0 or visible_route_index >= route_models_cache.size():
			continue
		var node_id: int = int(route_models_cache[visible_route_index].get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if get_node_world_position(board_composition_cache, node_id) == Vector2.ZERO:
			return true
	return false


static func build_emergency_route_slot_factor_map(
	route_models_cache: Array[Dictionary],
	board_composition_cache: Dictionary,
	visible_route_indices: Array[int],
	visible_count_to_slot_factors: Dictionary
) -> Dictionary:
	var missing_visible_slot_indices: Array[int] = []
	for visible_slot_index in range(visible_route_indices.size()):
		var route_index: int = visible_route_indices[visible_slot_index]
		if route_index < 0 or route_index >= route_models_cache.size():
			continue
		var node_id: int = int(route_models_cache[route_index].get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if get_node_world_position(board_composition_cache, node_id) != Vector2.ZERO:
			continue
		missing_visible_slot_indices.append(visible_slot_index)
	var slot_factors: Array[Vector2] = _build_emergency_route_slot_factors(
		missing_visible_slot_indices.size(),
		visible_count_to_slot_factors
	)
	var slot_factor_by_visible_index: Dictionary = {}
	for factor_index in range(min(missing_visible_slot_indices.size(), slot_factors.size())):
		slot_factor_by_visible_index[missing_visible_slot_indices[factor_index]] = slot_factors[factor_index]
	return slot_factor_by_visible_index


static func build_board_graph_signature(run_state) -> String:
	if run_state == null or run_state.map_runtime_state == null:
		return ""
	var map_runtime_state = run_state.map_runtime_state
	var graph_snapshot: Array[Dictionary] = map_runtime_state.build_realized_graph_snapshots()
	var normalized_nodes: Array[Dictionary] = []
	for node_variant in graph_snapshot:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var adjacent_node_ids: Array[int] = []
		for adjacent_variant in node_entry.get("adjacent_node_ids", []):
			adjacent_node_ids.append(int(adjacent_variant))
		adjacent_node_ids.sort()
		normalized_nodes.append({
			"node_id": int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)),
			"node_family": String(node_entry.get("node_family", "")),
			"adjacent_node_ids": adjacent_node_ids,
		})
	normalized_nodes.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("node_id", -1)) < int(right.get("node_id", -1))
	)
	return JSON.stringify({
		"run_seed": int(run_state.run_seed),
		"stage_index": int(run_state.stage_index),
		"template_id": String(map_runtime_state.get_active_template_id()),
		"nodes": normalized_nodes,
	})


static func build_stable_layout_snapshot(
	board_composition_cache: Dictionary,
	force_next_layout_recompose: bool,
	graph_signature: String,
	board_graph_signature: String
) -> Dictionary:
	if force_next_layout_recompose or graph_signature != board_graph_signature or board_composition_cache.is_empty():
		return {}
	return {
		"world_positions": (board_composition_cache.get("world_positions", {}) as Dictionary).duplicate(true),
		"ground_shapes": (board_composition_cache.get("ground_shapes", []) as Array).duplicate(true),
		"filler_shapes": (board_composition_cache.get("filler_shapes", []) as Array).duplicate(true),
		"forest_shapes": (board_composition_cache.get("forest_shapes", []) as Array).duplicate(true),
		"layout_edges": (board_composition_cache.get("layout_edges", []) as Array).duplicate(true),
	}


static func refresh_cached_visible_node_radii(
	board_composition_cache: Dictionary,
	board_composer: RefCounted,
	board_size: Vector2
) -> Dictionary:
	if board_composition_cache.is_empty() or board_composer == null:
		return board_composition_cache
	var cached_visible_nodes: Array = board_composition_cache.get("visible_nodes", [])
	if cached_visible_nodes.is_empty():
		return board_composition_cache
	var updated_cache: Dictionary = board_composition_cache.duplicate(true)
	var refreshed_visible_nodes: Array[Dictionary] = []
	for node_variant in cached_visible_nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = (node_variant as Dictionary).duplicate(true)
		node_entry["clearing_radius"] = board_composer.build_clearing_radius(
			String(node_entry.get("node_family", "")),
			String(node_entry.get("state_semantic", "open")),
			board_size
		)
		refreshed_visible_nodes.append(node_entry)
	updated_cache["visible_nodes"] = refreshed_visible_nodes
	return updated_cache


static func restore_visible_edge_continuity(board_composition_cache: Dictionary) -> Dictionary:
	if board_composition_cache.is_empty():
		return board_composition_cache
	var updated_cache: Dictionary = board_composition_cache.duplicate(true)
	var visible_nodes: Array = updated_cache.get("visible_nodes", [])
	var layout_edges: Array = updated_cache.get("layout_edges", [])
	var visible_edges: Array = (updated_cache.get("visible_edges", []) as Array).duplicate(true)
	var current_node_id: int = int(updated_cache.get("current_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var current_branch_root_id: int = int(updated_cache.get("current_branch_root_id", current_node_id))
	var branch_root_by_node_id: Dictionary = updated_cache.get("branch_root_by_node_id", {})
	if visible_nodes.is_empty() or layout_edges.is_empty() or current_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
		return updated_cache
	var visible_node_ids: Dictionary = {}
	var visible_node_by_id: Dictionary = {}
	for node_variant in visible_nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		visible_node_ids[node_id] = true
		visible_node_by_id[node_id] = node_entry
	var connected_node_ids: Dictionary = _visible_edge_component_node_ids(visible_edges, current_node_id)
	if connected_node_ids.size() >= visible_node_ids.size():
		return updated_cache
	var accepted_edge_keys: Dictionary = {}
	for edge_entry in visible_edges:
		accepted_edge_keys["%d:%d" % [
			min(int(edge_entry.get("from_node_id", -1)), int(edge_entry.get("to_node_id", -1))),
			max(int(edge_entry.get("from_node_id", -1)), int(edge_entry.get("to_node_id", -1))),
		]] = true
	for edge_variant in layout_edges:
		if typeof(edge_variant) != TYPE_DICTIONARY or connected_node_ids.size() >= visible_node_ids.size():
			continue
		var edge_entry: Dictionary = edge_variant
		var from_node_id: int = int(edge_entry.get("from_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var to_node_id: int = int(edge_entry.get("to_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var edge_key: String = "%d:%d" % [min(from_node_id, to_node_id), max(from_node_id, to_node_id)]
		if accepted_edge_keys.has(edge_key):
			continue
		if not visible_node_ids.has(from_node_id) or not visible_node_ids.has(to_node_id):
			continue
		if connected_node_ids.has(from_node_id) == connected_node_ids.has(to_node_id):
			continue
		var extra_edge: Dictionary = edge_entry.duplicate(true)
		var from_node: Dictionary = visible_node_by_id.get(from_node_id, {})
		var to_node: Dictionary = visible_node_by_id.get(to_node_id, {})
		extra_edge["state_semantic"] = "locked" if String(from_node.get("state_semantic", "")) == "locked" or String(to_node.get("state_semantic", "")) == "locked" else ("resolved" if String(from_node.get("node_state", "")) == MapRuntimeStateScript.NODE_STATE_RESOLVED and String(to_node.get("node_state", "")) == MapRuntimeStateScript.NODE_STATE_RESOLVED else "open")
		extra_edge["is_history"] = not (from_node_id == current_node_id or to_node_id == current_node_id)
		var corridor_role_semantic: String = "history_corridor"
		if bool(extra_edge.get("is_reconnect_edge", false)):
			corridor_role_semantic = "reconnect_corridor"
		elif (
			int(extra_edge.get("from_branch_root_id", branch_root_by_node_id.get(from_node_id, from_node_id))) == current_branch_root_id
			or int(extra_edge.get("to_branch_root_id", branch_root_by_node_id.get(to_node_id, to_node_id))) == current_branch_root_id
			or from_node_id == current_branch_root_id
			or to_node_id == current_branch_root_id
		):
			corridor_role_semantic = "branch_history_corridor"
		extra_edge["corridor_role_semantic"] = corridor_role_semantic
		extra_edge["route_surface_semantic"] = corridor_role_semantic
		extra_edge["corridor_draw_priority"] = _corridor_draw_priority(corridor_role_semantic)
		visible_edges.append(extra_edge)
		accepted_edge_keys[edge_key] = true
		connected_node_ids = _visible_edge_component_node_ids(visible_edges, current_node_id)
	visible_edges.sort_custom(func(left_edge: Dictionary, right_edge: Dictionary) -> bool:
		var left_priority: int = int(left_edge.get("corridor_draw_priority", 0))
		var right_priority: int = int(right_edge.get("corridor_draw_priority", 0))
		if left_priority != right_priority:
			return left_priority < right_priority
		var left_key: String = "%d:%d" % [min(int(left_edge.get("from_node_id", -1)), int(left_edge.get("to_node_id", -1))), max(int(left_edge.get("from_node_id", -1)), int(left_edge.get("to_node_id", -1)))]
		var right_key: String = "%d:%d" % [min(int(right_edge.get("from_node_id", -1)), int(right_edge.get("to_node_id", -1))), max(int(right_edge.get("from_node_id", -1)), int(right_edge.get("to_node_id", -1)))]
		return left_key < right_key
	)
	updated_cache["visible_edges"] = visible_edges
	return updated_cache


static func marker_position_for_route_model(
	board_composition_cache: Dictionary,
	route_layout_offset: Vector2,
	route_marker_size: Vector2,
	board_focus_anchor_factor: Vector2,
	model: Dictionary,
	emergency_slot_index: int,
	emergency_slot_factor_by_visible_index: Dictionary,
	board_size: Vector2,
	frame_padding: Vector2 = Vector2.ZERO
) -> Vector2:
	var node_id: int = int(model.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var world_position: Vector2 = get_node_world_position(board_composition_cache, node_id)
	if world_position != Vector2.ZERO:
		return world_position + route_layout_offset - (route_marker_size * 0.5)
	if emergency_slot_factor_by_visible_index.has(emergency_slot_index):
		var slot_factor: Vector2 = Vector2(
			emergency_slot_factor_by_visible_index.get(emergency_slot_index, board_focus_anchor_factor)
		)
		return clamp_marker_position_to_padded_frame(
			emergency_route_marker_position(route_layout_offset, route_marker_size, board_size, slot_factor),
			route_marker_size,
			board_size,
			frame_padding
		)
	return clamp_marker_position_to_padded_frame(
		emergency_board_anchor_marker_position(route_marker_size, board_size, board_focus_anchor_factor),
		route_marker_size,
		board_size,
		frame_padding
	)


static func get_node_world_position(board_composition_cache: Dictionary, node_id: int) -> Vector2:
	if node_id < 0 or board_composition_cache.is_empty():
		return Vector2.ZERO
	var world_positions: Dictionary = board_composition_cache.get("world_positions", {})
	return world_positions.get(node_id, Vector2.ZERO)


static func _corridor_draw_priority(corridor_role_semantic: String) -> int:
	match corridor_role_semantic:
		"reconnect_corridor":
			return 0
		"history_corridor":
			return 1
		"branch_history_corridor":
			return 2
		"branch_actionable_corridor":
			return 3
		"primary_actionable_corridor":
			return 4
		_:
			return 1


static func desired_focus_offset_for_world_position(
	route_grid: Control,
	board_composition_cache: Dictionary,
	current_offset: Vector2,
	world_position: Vector2,
	board_focus_anchor_factor: Vector2,
	board_max_offset_factor: Vector2,
	board_focus_deadzone_factor: Vector2,
	board_focus_damping: float,
	board_focus_context_blend_min: float,
	board_focus_context_blend_max: float,
	board_focus_clamp_padding: Vector2,
	board_visible_content_padding: Vector2,
	node_plate_half_size: Vector2,
	board_lower_fill_target_factor: float
) -> Vector2:
	return Vector2.ZERO


static func emergency_route_marker_position(
	route_layout_offset: Vector2,
	route_marker_size: Vector2,
	board_size: Vector2,
	slot_factor: Vector2
) -> Vector2:
	return board_size * slot_factor - (route_marker_size * 0.5) + route_layout_offset


static func emergency_board_anchor_marker_position(
	route_marker_size: Vector2,
	board_size: Vector2,
	board_focus_anchor_factor: Vector2
) -> Vector2:
	return board_size * board_focus_anchor_factor - (route_marker_size * 0.5)


static func clamp_marker_position_to_padded_frame(
	marker_position: Vector2,
	route_marker_size: Vector2,
	board_size: Vector2,
	frame_padding: Vector2
) -> Vector2:
	if board_size == Vector2.ZERO or route_marker_size == Vector2.ZERO:
		return marker_position
	var min_x: float = maxf(0.0, frame_padding.x)
	var min_y: float = maxf(0.0, frame_padding.y)
	var max_x: float = maxf(min_x, board_size.x - frame_padding.x - route_marker_size.x)
	var max_y: float = maxf(min_y, board_size.y - frame_padding.y - route_marker_size.y)
	return Vector2(
		clampf(marker_position.x, min_x, max_x),
		clampf(marker_position.y, min_y, max_y)
	)


static func nudge_focus_offset_to_visible_node_plate_bounds(
	board_composition_cache: Dictionary,
	board_size: Vector2,
	proposed_offset: Vector2,
	frame_padding: Vector2,
	plate_half_size: Vector2
) -> Vector2:
	if board_composition_cache.is_empty() or board_size == Vector2.ZERO:
		return proposed_offset
	return Vector2(
		_nudge_focus_offset_axis_to_visible_node_plate_bounds(board_composition_cache, board_size.x, frame_padding.x, plate_half_size.x, proposed_offset.x, true),
		_nudge_focus_offset_axis_to_visible_node_plate_bounds(board_composition_cache, board_size.y, frame_padding.y, plate_half_size.y, proposed_offset.y, false)
	)


static func nudge_focus_offset_to_visible_edge_bounds(
	board_composition_cache: Dictionary,
	board_size: Vector2,
	proposed_offset: Vector2,
	frame_padding: Vector2,
	edge_padding: float = 16.0
) -> Vector2:
	if board_composition_cache.is_empty() or board_size == Vector2.ZERO:
		return proposed_offset
	return Vector2(
		_nudge_focus_offset_axis_to_visible_edge_bounds(board_composition_cache, board_size.x, frame_padding.x, edge_padding, proposed_offset.x, true),
		_nudge_focus_offset_axis_to_visible_edge_bounds(board_composition_cache, board_size.y, frame_padding.y, edge_padding, proposed_offset.y, false)
	)


static func refine_focus_offset_for_visible_content(
	board_composition_cache: Dictionary,
	board_size: Vector2,
	proposed_offset: Vector2,
	frame_padding: Vector2,
	plate_half_size: Vector2,
	target_factor: float,
	edge_padding: float = 16.0
) -> Vector2:
	var node_plate_nudged_offset: Vector2 = nudge_focus_offset_to_visible_node_plate_bounds(
		board_composition_cache,
		board_size,
		proposed_offset,
		frame_padding,
		plate_half_size
	)
	var edge_nudged_offset: Vector2 = nudge_focus_offset_to_visible_edge_bounds(
		board_composition_cache,
		board_size,
		node_plate_nudged_offset,
		frame_padding,
		edge_padding
	)
	return nudge_focus_offset_for_lower_board_fill(
		board_composition_cache,
		board_size,
		edge_nudged_offset,
		frame_padding,
		plate_half_size,
		target_factor,
		edge_padding
	)


static func nudge_focus_offset_for_lower_board_fill(
	board_composition_cache: Dictionary,
	board_size: Vector2,
	proposed_offset: Vector2,
	frame_padding: Vector2,
	plate_half_size: Vector2,
	target_factor: float,
	edge_padding: float = 16.0
) -> Vector2:
	if board_composition_cache.is_empty() or board_size == Vector2.ZERO:
		return proposed_offset
	var deepest_visible_y: float = -INF
	var has_visible_nodes: bool = false
	for node_variant in board_composition_cache.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var world_position: Vector2 = Vector2((node_variant as Dictionary).get("world_position", Vector2.ZERO))
		if world_position == Vector2.ZERO:
			continue
		has_visible_nodes = true
		deepest_visible_y = maxf(deepest_visible_y, world_position.y + proposed_offset.y)
	if not has_visible_nodes:
		return proposed_offset
	var target_deepest_y: float = board_size.y * clampf(target_factor, 0.0, 1.0)
	if deepest_visible_y >= target_deepest_y:
		return proposed_offset
	var desired_y_offset: float = proposed_offset.y + (target_deepest_y - deepest_visible_y)
	var plate_clamped_y: float = _nudge_focus_offset_axis_to_visible_node_plate_bounds(
		board_composition_cache,
		board_size.y,
		frame_padding.y,
		plate_half_size.y,
		desired_y_offset,
		false
	)
	var edge_clamped_y: float = _nudge_focus_offset_axis_to_visible_edge_bounds(
		board_composition_cache,
		board_size.y,
		frame_padding.y,
		edge_padding,
		plate_clamped_y,
		false
	)
	return Vector2(proposed_offset.x, maxf(proposed_offset.y, edge_clamped_y))


static func _nudge_focus_offset_axis_to_visible_node_plate_bounds(
	board_composition_cache: Dictionary,
	viewport_size: float,
	padding: float,
	plate_half_size: float,
	proposed_offset: float,
	use_x_axis: bool
) -> float:
	var lower_bound: float = -INF
	var upper_bound: float = INF
	var has_visible_nodes: bool = false
	for node_variant in board_composition_cache.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var world_position: Vector2 = Vector2((node_variant as Dictionary).get("world_position", Vector2.ZERO))
		if world_position == Vector2.ZERO:
			continue
		has_visible_nodes = true
		var axis_position: float = world_position.x if use_x_axis else world_position.y
		lower_bound = maxf(lower_bound, padding + plate_half_size - axis_position)
		upper_bound = minf(upper_bound, viewport_size - padding - plate_half_size - axis_position)
	if not has_visible_nodes:
		return proposed_offset
	if lower_bound > upper_bound:
		return (lower_bound + upper_bound) * 0.5
	return clampf(proposed_offset, lower_bound, upper_bound)


static func _nudge_focus_offset_axis_to_visible_edge_bounds(
	board_composition_cache: Dictionary,
	viewport_size: float,
	padding: float,
	edge_padding: float,
	proposed_offset: float,
	use_x_axis: bool
) -> float:
	var lower_bound: float = -INF
	var upper_bound: float = INF
	var has_points: bool = false
	for edge_variant in board_composition_cache.get("visible_edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var points: PackedVector2Array = (edge_variant as Dictionary).get("points", PackedVector2Array())
		for point in points:
			has_points = true
			var axis_position: float = point.x if use_x_axis else point.y
			lower_bound = maxf(lower_bound, padding + edge_padding - axis_position)
			upper_bound = minf(upper_bound, viewport_size - padding - edge_padding - axis_position)
	if not has_points:
		return proposed_offset
	if lower_bound > upper_bound:
		return (lower_bound + upper_bound) * 0.5
	return clampf(proposed_offset, lower_bound, upper_bound)


static func _build_emergency_route_slot_factors(
	visible_count: int,
	visible_count_to_slot_factors: Dictionary
) -> Array[Vector2]:
	var slot_factors_variant: Variant = visible_count_to_slot_factors.get(
		visible_count,
		visible_count_to_slot_factors.get(-1, [])
	)
	var slot_factors: Array[Vector2] = []
	if typeof(slot_factors_variant) != TYPE_ARRAY:
		return slot_factors
	for slot_factor_variant in slot_factors_variant:
		slot_factors.append(Vector2(slot_factor_variant))
	return slot_factors


static func _visible_edge_component_node_ids(edges: Array, start_node_id: int) -> Dictionary:
	var adjacency: Dictionary = {}
	for edge_entry in edges:
		var from_node_id: int = int(edge_entry.get("from_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var to_node_id: int = int(edge_entry.get("to_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if from_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID or to_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
			continue
		if not adjacency.has(from_node_id):
			adjacency[from_node_id] = []
		if not adjacency.has(to_node_id):
			adjacency[to_node_id] = []
		(adjacency[from_node_id] as Array).append(to_node_id)
		(adjacency[to_node_id] as Array).append(from_node_id)
	var component_node_ids: Dictionary = {start_node_id: true}
	var open_node_ids: Array[int] = [start_node_id]
	while not open_node_ids.is_empty():
		var node_id: int = open_node_ids.pop_front()
		for adjacent_node_id_variant in adjacency.get(node_id, []):
			var adjacent_node_id: int = int(adjacent_node_id_variant)
			if component_node_ids.has(adjacent_node_id):
				continue
			component_node_ids[adjacent_node_id] = true
			open_node_ids.append(adjacent_node_id)
	return component_node_ids
