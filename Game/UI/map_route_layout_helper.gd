# Layer: UI
extends RefCounted
class_name MapRouteLayoutHelper

const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")


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
