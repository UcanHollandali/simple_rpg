# Layer: UI
extends RefCounted
class_name MapRouteMotionHelper

const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")


static func route_camera_follow_progress(progress: float, route_move_camera_delay_ratio: float) -> float:
	var delayed_progress: float = clampf(
		(progress - route_move_camera_delay_ratio) / max(0.001, 1.0 - route_move_camera_delay_ratio),
		0.0,
		1.0
	)
	return ease_in_out_sine(delayed_progress)


static func route_layout_offset_for_move_progress(
	current_offset: Vector2,
	target_offset: Vector2,
	progress: float,
	route_move_camera_delay_ratio: float
) -> Vector2:
	return current_offset.lerp(
		target_offset,
		route_camera_follow_progress(progress, route_move_camera_delay_ratio)
	)


static func clamp_route_move_duration(
	distance: float,
	route_move_min_duration: float,
	route_move_max_duration: float,
	route_move_base_duration: float,
	route_move_pixels_per_second: float
) -> float:
	if distance <= 0.0:
		return route_move_min_duration
	return clampf(
		route_move_base_duration + (distance / route_move_pixels_per_second),
		route_move_min_duration,
		route_move_max_duration
	)


static func build_route_move_world_path(
	board_composition_cache: Dictionary,
	current_node_id: int,
	target_node_id: int,
	fallback_start_world: Vector2,
	fallback_target_world: Vector2
) -> PackedVector2Array:
	var render_model_path_points: PackedVector2Array = _render_model_path_surface_points_for_route(
		board_composition_cache,
		current_node_id,
		target_node_id
	)
	if render_model_path_points.size() >= 2:
		return render_model_path_points

	var points := PackedVector2Array()
	var start_world: Vector2 = _get_node_world_position(board_composition_cache, current_node_id)
	if start_world == Vector2.ZERO:
		start_world = fallback_start_world
	var target_world: Vector2 = _get_node_world_position(board_composition_cache, target_node_id)
	if target_world == Vector2.ZERO:
		target_world = fallback_target_world
	_append_route_move_world_point(points, start_world)
	var visible_edge_points: PackedVector2Array = _visible_edge_points_for_route(
		board_composition_cache,
		current_node_id,
		target_node_id
	)
	for point in visible_edge_points:
		_append_route_move_world_point(points, point)
	_append_route_move_world_point(points, target_world)
	if points.size() >= 2:
		return points
	return PackedVector2Array([start_world, target_world])


static func has_pending_roadside_visual_state(roadside_visual_state: Dictionary, no_pending_node_id: int) -> bool:
	return not roadside_visual_state.is_empty() and int(roadside_visual_state.get("target_node_id", no_pending_node_id)) != no_pending_node_id


static func build_roadside_visual_state(
	current_node_id: int,
	target_node_id: int,
	current_offset: Vector2,
	target_offset: Vector2,
	roadside_interruption_progress: float,
	route_move_camera_delay_ratio: float,
	no_pending_node_id: int
) -> Dictionary:
	if current_node_id == no_pending_node_id or target_node_id == no_pending_node_id:
		return {}
	return {
		"current_node_id": current_node_id,
		"target_node_id": target_node_id,
		"progress": roadside_interruption_progress,
		"offset": route_layout_offset_for_move_progress(
			current_offset,
			target_offset,
			roadside_interruption_progress,
			route_move_camera_delay_ratio
		),
		"target_offset": target_offset,
	}


static func build_pending_roadside_visual_sample(
	board_composition_cache: Dictionary,
	roadside_visual_state: Dictionary,
	route_layout_offset: Vector2,
	roadside_interruption_progress: float
) -> Dictionary:
	if roadside_visual_state.is_empty():
		return {}
	var current_node_id: int = int(roadside_visual_state.get("current_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var target_node_id: int = int(roadside_visual_state.get("target_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	if current_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID or target_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
		return {}
	var start_world: Vector2 = _get_node_world_position(board_composition_cache, current_node_id)
	var target_world: Vector2 = _get_node_world_position(board_composition_cache, target_node_id)
	var route_path: PackedVector2Array = build_route_move_world_path(
		board_composition_cache,
		current_node_id,
		target_node_id,
		start_world,
		target_world
	)
	var route_length: float = polyline_length(route_path)
	if route_length <= 0.001:
		return {}
	var progress: float = clampf(
		float(roadside_visual_state.get("progress", roadside_interruption_progress)),
		0.0,
		1.0
	)
	var sample: Dictionary = sample_polyline_at_distance(route_path, route_length * progress)
	sample["offset"] = Vector2(roadside_visual_state.get("offset", route_layout_offset))
	return sample


static func sample_route_move_world_state(
	route_move_world_path: PackedVector2Array,
	route_move_path_length: float,
	progress: float
) -> Dictionary:
	if route_move_world_path.size() < 2:
		var fallback_point: Vector2 = route_move_world_path[0] if not route_move_world_path.is_empty() else Vector2.ZERO
		return {"point": fallback_point, "direction": Vector2.RIGHT}
	var travel_distance: float = route_move_path_length * clampf(progress, 0.0, 1.0)
	var current_sample: Dictionary = sample_polyline_at_distance(route_move_world_path, travel_distance)
	var lookahead_distance: float = min(route_move_path_length, travel_distance + max(18.0, route_move_path_length * 0.05))
	var lookahead_sample: Dictionary = sample_polyline_at_distance(route_move_world_path, lookahead_distance)
	var direction: Vector2 = Vector2(lookahead_sample.get("point", Vector2.ZERO)) - Vector2(current_sample.get("point", Vector2.ZERO))
	if direction.length_squared() <= 0.001:
		direction = Vector2(current_sample.get("direction", Vector2.RIGHT))
	return {
		"point": current_sample.get("point", Vector2.ZERO),
		"direction": direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT,
	}


static func sample_polyline_at_distance(points: PackedVector2Array, distance: float) -> Dictionary:
	if points.is_empty():
		return {"point": Vector2.ZERO, "direction": Vector2.RIGHT}
	if points.size() == 1:
		return {"point": points[0], "direction": Vector2.RIGHT}
	var remaining_distance: float = max(0.0, distance)
	for index in range(points.size() - 1):
		var from_point: Vector2 = points[index]
		var to_point: Vector2 = points[index + 1]
		var segment: Vector2 = to_point - from_point
		var segment_length: float = segment.length()
		if segment_length <= 0.001:
			continue
		if remaining_distance <= segment_length:
			var segment_progress: float = remaining_distance / segment_length
			return {"point": from_point.lerp(to_point, segment_progress), "direction": segment / segment_length}
		remaining_distance -= segment_length
	var last_segment: Vector2 = points[points.size() - 1] - points[points.size() - 2]
	return {
		"point": points[points.size() - 1],
		"direction": last_segment.normalized() if last_segment.length_squared() > 0.001 else Vector2.RIGHT,
	}


static func polyline_length(points: PackedVector2Array) -> float:
	if points.size() < 2:
		return 0.0
	var total_length: float = 0.0
	for index in range(points.size() - 1):
		total_length += points[index].distance_to(points[index + 1])
	return total_length


static func resolve_route_move_stride_cycles(path_length: float, walker_stride_pixels_per_cycle: float) -> float:
	return clampf(path_length / walker_stride_pixels_per_cycle, 1.0, 4.25)


static func resolve_walker_frame_interval(
	path_length: float,
	move_duration: float,
	walker_frame_interval_min: float,
	walker_frame_interval_max: float
) -> float:
	if path_length <= 0.0 or move_duration <= 0.0:
		return walker_frame_interval_max
	var travel_speed: float = path_length / move_duration
	return clampf(44.0 / max(1.0, travel_speed), walker_frame_interval_min, walker_frame_interval_max)


static func walker_stride_offset(
	progress: float,
	route_move_path_length: float,
	route_move_stride_cycles: float,
	walker_stride_bob_max: float
) -> Vector2:
	if route_move_path_length <= 0.0:
		return Vector2.ZERO
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	var stride_envelope: float = sin(clamped_progress * PI)
	if stride_envelope <= 0.0:
		return Vector2.ZERO
	var stride_phase: float = clamped_progress * TAU * route_move_stride_cycles
	var bob_wave: float = absf(sin(stride_phase))
	var sway_wave: float = sin(stride_phase)
	var bob_amplitude: float = min(
		walker_stride_bob_max,
		walker_stride_bob_max * clampf(route_move_path_length / 220.0, 0.45, 1.0)
	)
	var sway_amplitude: float = min(
		4.0,
		4.0 * clampf(route_move_path_length / 220.0, 0.35, 1.0)
	)
	return Vector2(
		sway_wave * sway_amplitude * stride_envelope * 0.42,
		-bob_wave * bob_amplitude * stride_envelope
	)


static func ease_in_out_sine(value: float) -> float:
	var clamped_value: float = clampf(value, 0.0, 1.0)
	return 0.5 - (cos(clamped_value * PI) * 0.5)


static func _get_node_world_position(board_composition_cache: Dictionary, node_id: int) -> Vector2:
	if node_id < 0 or board_composition_cache.is_empty():
		return Vector2.ZERO
	var world_positions: Dictionary = board_composition_cache.get("world_positions", {})
	return world_positions.get(node_id, Vector2.ZERO)


static func _render_model_path_surface_points_for_route(
	board_composition_cache: Dictionary,
	current_node_id: int,
	target_node_id: int
) -> PackedVector2Array:
	var render_model_variant: Variant = board_composition_cache.get("render_model", {})
	if typeof(render_model_variant) != TYPE_DICTIONARY:
		return PackedVector2Array()
	var render_model: Dictionary = render_model_variant
	for surface_variant in render_model.get("path_surfaces", []):
		if typeof(surface_variant) != TYPE_DICTIONARY:
			continue
		var surface: Dictionary = surface_variant
		var from_node_id: int = int(surface.get("from_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var to_node_id: int = int(surface.get("to_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var centerline_points: PackedVector2Array = _path_surface_centerline_points(surface)
		if centerline_points.size() < 2:
			continue
		if from_node_id == current_node_id and to_node_id == target_node_id:
			return centerline_points
		if from_node_id == target_node_id and to_node_id == current_node_id:
			return _reversed_points(centerline_points)
	return PackedVector2Array()


static func _path_surface_centerline_points(surface: Dictionary) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in surface.get("centerline_points", PackedVector2Array()):
		_append_route_move_world_point(points, point)
	if points.size() >= 2:
		return points
	_append_route_move_world_point(points, Vector2(surface.get("from_endpoint", Vector2.ZERO)))
	_append_route_move_world_point(points, Vector2(surface.get("to_endpoint", Vector2.ZERO)))
	return points


static func _visible_edge_points_for_route(
	board_composition_cache: Dictionary,
	current_node_id: int,
	target_node_id: int
) -> PackedVector2Array:
	for edge_variant in board_composition_cache.get("visible_edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = edge_variant
		var from_node_id: int = int(edge.get("from_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var to_node_id: int = int(edge.get("to_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if from_node_id == current_node_id and to_node_id == target_node_id:
			return edge.get("points", PackedVector2Array())
		if from_node_id == target_node_id and to_node_id == current_node_id:
			var points: PackedVector2Array = edge.get("points", PackedVector2Array())
			return _reversed_points(points)
	return PackedVector2Array()


static func _reversed_points(points: PackedVector2Array) -> PackedVector2Array:
	var reversed_points := PackedVector2Array()
	for index in range(points.size() - 1, -1, -1):
		_append_route_move_world_point(reversed_points, points[index])
	return reversed_points


static func _append_route_move_world_point(points: PackedVector2Array, point: Vector2) -> void:
	if point == Vector2.ZERO:
		return
	if points.is_empty() or points[points.size() - 1].distance_to(point) > 0.5:
		points.append(point)
