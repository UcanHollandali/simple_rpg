# Layer: UI
extends RefCounted
class_name MapFocusHelper


static func desired_focus_offset(
	route_grid: Control,
	current_offset: Vector2,
	world_position: Vector2,
	focus_anchor_factor: Vector2,
	max_offset_factor: Vector2,
	deadzone_factor: Vector2,
	focus_damping: float,
	context_world_position: Vector2 = Vector2.ZERO,
	context_blend: float = 0.0
) -> Vector2:
	if route_grid == null or world_position == Vector2.ZERO:
		return current_offset
	var anchored_world_position: Vector2 = world_position
	if context_world_position != Vector2.ZERO and context_blend > 0.0:
		anchored_world_position = world_position.lerp(context_world_position, clampf(context_blend, 0.0, 0.40))
	var desired_offset: Vector2 = route_grid.size * focus_anchor_factor - anchored_world_position
	var deadzone: Vector2 = route_grid.size * deadzone_factor
	if absf(desired_offset.x) <= deadzone.x:
		desired_offset.x = 0.0
	else:
		desired_offset.x = (absf(desired_offset.x) - deadzone.x) * sign(desired_offset.x)
	if absf(desired_offset.y) <= deadzone.y:
		desired_offset.y = 0.0
	else:
		desired_offset.y = (absf(desired_offset.y) - deadzone.y) * sign(desired_offset.y)
	var max_offset: Vector2 = route_grid.size * max_offset_factor
	return Vector2(
		clampf(desired_offset.x * focus_damping, -max_offset.x, max_offset.x),
		clampf(desired_offset.y * focus_damping, -max_offset.y, max_offset.y)
	)


static func focus_context_world_position(composition: Dictionary, fallback_world_position: Vector2) -> Vector2:
	var visible_nodes: Array = composition.get("visible_nodes", [])
	if visible_nodes.is_empty():
		return fallback_world_position
	var weighted_total: Vector2 = Vector2.ZERO
	var total_weight: float = 0.0
	for node_variant in visible_nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var world_position: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
		if world_position == Vector2.ZERO:
			continue
		var weight: float = 1.0
		if bool(node_entry.get("is_current", false)):
			weight = 4.0
		elif bool(node_entry.get("is_adjacent", false)):
			weight = 2.8
		match String(node_entry.get("state_semantic", "open")):
			"resolved":
				weight *= 1.1
			"locked":
				weight *= 1.25
			_:
				pass
		weighted_total += world_position * weight
		total_weight += weight
	if total_weight <= 0.0:
		return fallback_world_position
	return weighted_total / total_weight


static func context_blend_for_positions(
	route_grid: Control,
	world_position: Vector2,
	context_world_position: Vector2,
	min_blend: float,
	max_blend: float
) -> float:
	if route_grid == null or world_position == Vector2.ZERO or context_world_position == Vector2.ZERO:
		return 0.0
	var max_distance: float = max(route_grid.size.x, route_grid.size.y) * 0.34
	if max_distance <= 0.001:
		return 0.0
	var distance_ratio: float = clampf(world_position.distance_to(context_world_position) / max_distance, 0.0, 1.0)
	if distance_ratio <= 0.0:
		return 0.0
	return lerpf(min_blend, max_blend, distance_ratio)
