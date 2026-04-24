# Layer: UI
extends RefCounted
class_name MapBoardRenderModelMasksSlots

const CANOPY_FRAME_LINK_COUNT := 3
const DECOR_RELATION_LINK_COUNT := 1


static func extend_render_model(
	render_model: Dictionary,
	visible_nodes: Array,
	filler_shapes: Array,
	forest_shapes: Array
) -> Dictionary:
	var extended_model: Dictionary = render_model.duplicate(true)
	var path_surfaces: Array = extended_model.get("path_surfaces", [])
	var clearing_surfaces: Array = extended_model.get("clearing_surfaces", [])
	var board_size: Vector2 = extended_model.get("board_size", Vector2.ZERO)
	extended_model["canopy_masks"] = _build_canopy_masks(forest_shapes, path_surfaces, clearing_surfaces, board_size)
	extended_model["landmark_slots"] = _build_landmark_slots(visible_nodes, path_surfaces, clearing_surfaces, board_size)
	extended_model["decor_slots"] = _build_decor_slots(filler_shapes, forest_shapes, path_surfaces, clearing_surfaces, board_size)
	return extended_model


static func empty_masks_slots_payload() -> Dictionary:
	return {
		"canopy_masks": [],
		"landmark_slots": [],
		"decor_slots": [],
	}


static func _build_canopy_masks(
	forest_shapes: Array,
	path_surfaces: Array,
	clearing_surfaces: Array,
	board_size: Vector2
) -> Array[Dictionary]:
	var masks: Array[Dictionary] = []
	for shape_index in range(forest_shapes.size()):
		var shape_variant: Variant = forest_shapes[shape_index]
		if typeof(shape_variant) != TYPE_DICTIONARY:
			continue
		var shape_entry: Dictionary = shape_variant
		if String(shape_entry.get("family", "")) != "canopy":
			continue
		var center: Vector2 = shape_entry.get("center", Vector2.ZERO)
		var radius: float = float(shape_entry.get("radius", 0.0))
		if radius <= 0.0:
			continue
		var path_refs: Array[Dictionary] = _nearest_path_surface_refs(center, path_surfaces, CANOPY_FRAME_LINK_COUNT)
		var clearing_refs: Array[Dictionary] = _nearest_clearing_surface_refs(center, clearing_surfaces, CANOPY_FRAME_LINK_COUNT)
		masks.append({
			"mask_id": "canopy:%d" % shape_index,
			"source_legacy_field": "forest_shapes",
			"source_shape_index": shape_index,
			"source_family": "canopy",
			"shape": "circle",
			"center": center,
			"radius": radius,
			"rotation_degrees": float(shape_entry.get("rotation_degrees", 0.0)),
			"mask_role": _canopy_mask_role(clearing_refs),
			"frames_path_surface_ids": _surface_ids_from_refs(path_refs),
			"frames_clearing_surface_ids": _surface_ids_from_refs(clearing_refs),
			"cardinal_side": _cardinal_side_for_point(center, board_size),
			"outward_route_hint": _outward_hint_from_refs(path_refs, center, board_size),
			"clearance_role": "road_and_clearing_frame",
			"asset_socket_kind": "canopy_mask",
		})
	return masks


static func _build_landmark_slots(
	visible_nodes: Array,
	path_surfaces: Array,
	clearing_surfaces: Array,
	board_size: Vector2
) -> Array[Dictionary]:
	var path_surface_by_id: Dictionary = _surface_by_id(path_surfaces)
	var clearing_by_node_id: Dictionary = _clearing_surface_by_node_id(clearing_surfaces)
	var slots: Array[Dictionary] = []
	for node_variant in visible_nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var footprint_variant: Variant = node_entry.get("landmark_footprint", {})
		if typeof(footprint_variant) != TYPE_DICTIONARY:
			continue
		var footprint: Dictionary = footprint_variant
		if footprint.is_empty():
			continue
		var node_id: int = int(node_entry.get("node_id", -1))
		var center: Vector2 = node_entry.get("world_position", Vector2.ZERO)
		var clearing_surface: Dictionary = clearing_by_node_id.get(node_id, {})
		var connected_surface_ids: Array = clearing_surface.get("connected_path_surface_ids", [])
		var cardinal_direction: String = _cardinal_for_surface_ids(connected_surface_ids, path_surface_by_id, center, board_size)
		var outward_route_hint: String = _outward_hint_for_surface_ids(connected_surface_ids, path_surface_by_id, center, board_size)
		var landmark_half_size: Vector2 = footprint.get("landmark_half_size", Vector2.ZERO)
		var clearing_radius: float = maxf(1.0, float(node_entry.get("clearing_radius", 1.0)))
		slots.append({
			"slot_id": "landmark:%d" % node_id,
			"node_id": node_id,
			"node_family": String(node_entry.get("node_family", "")),
			"node_state": String(node_entry.get("node_state", "")),
			"state_semantic": String(node_entry.get("state_semantic", "open")),
			"slot_role": _landmark_slot_role(node_entry),
			"anchor_point": center + Vector2(footprint.get("landmark_center_offset", Vector2.ZERO)),
			"pocket_anchor_point": center + Vector2(footprint.get("pocket_center_offset", Vector2.ZERO)),
			"signage_anchor_point": center + Vector2(footprint.get("signage_center_offset", Vector2.ZERO)),
			"clearing_center": center,
			"landmark_shape": String(footprint.get("landmark_shape", "")),
			"pocket_shape": String(footprint.get("pocket_shape", "")),
			"signage_shape": String(footprint.get("signage_shape", "")),
			"landmark_half_size": landmark_half_size,
			"pocket_half_size": Vector2(footprint.get("pocket_half_size", Vector2.ZERO)),
			"rotation_degrees": float(footprint.get("landmark_rotation_degrees", footprint.get("pocket_rotation_degrees", 0.0))),
			"scale": maxf(0.1, maxf(landmark_half_size.x, landmark_half_size.y) / clearing_radius),
			"signage_scale": float(footprint.get("signage_scale", 1.0)),
			"cardinal_direction": cardinal_direction,
			"outward_route_hint": outward_route_hint,
			"connected_path_surface_ids": connected_surface_ids.duplicate(true),
			"asset_socket_kind": "landmark",
			"asset_family_key": "%s:%s" % [String(node_entry.get("node_family", "")), String(footprint.get("landmark_shape", ""))],
		})
	return slots


static func _build_decor_slots(
	filler_shapes: Array,
	forest_shapes: Array,
	path_surfaces: Array,
	clearing_surfaces: Array,
	board_size: Vector2
) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for shape_index in range(filler_shapes.size()):
		var shape_variant: Variant = filler_shapes[shape_index]
		if typeof(shape_variant) != TYPE_DICTIONARY:
			continue
		var shape_entry: Dictionary = shape_variant
		var center: Vector2 = shape_entry.get("center", Vector2.ZERO)
		var half_size: Vector2 = shape_entry.get("half_size", Vector2.ZERO)
		if half_size == Vector2.ZERO:
			continue
		slots.append(_build_decor_slot(
			"decor:filler:%d" % shape_index,
			"filler_shapes",
			shape_index,
			String(shape_entry.get("family", "")),
			center,
			float(shape_entry.get("rotation_degrees", 0.0)),
			maxf(0.1, maxf(half_size.x, half_size.y) / maxf(1.0, minf(board_size.x, board_size.y))),
			half_size,
			0.0,
			path_surfaces,
			clearing_surfaces,
			board_size
		))
	for shape_index in range(forest_shapes.size()):
		var shape_variant: Variant = forest_shapes[shape_index]
		if typeof(shape_variant) != TYPE_DICTIONARY:
			continue
		var shape_entry: Dictionary = shape_variant
		if String(shape_entry.get("family", "")) != "decor":
			continue
		var center: Vector2 = shape_entry.get("center", Vector2.ZERO)
		var radius: float = float(shape_entry.get("radius", 0.0))
		if radius <= 0.0:
			continue
		slots.append(_build_decor_slot(
			"decor:forest:%d" % shape_index,
			"forest_shapes",
			shape_index,
			"forest_decor",
			center,
			float(shape_entry.get("rotation_degrees", 0.0)),
			maxf(0.1, radius / maxf(1.0, minf(board_size.x, board_size.y))),
			Vector2.ZERO,
			radius,
			path_surfaces,
			clearing_surfaces,
			board_size
		))
	return slots


static func _build_decor_slot(
	slot_id: String,
	source_legacy_field: String,
	source_shape_index: int,
	decor_family: String,
	anchor_point: Vector2,
	rotation_degrees: float,
	scale: float,
	half_size: Vector2,
	radius: float,
	path_surfaces: Array,
	clearing_surfaces: Array,
	board_size: Vector2
) -> Dictionary:
	var path_refs: Array[Dictionary] = _nearest_path_surface_refs(anchor_point, path_surfaces, DECOR_RELATION_LINK_COUNT)
	var clearing_refs: Array[Dictionary] = _nearest_clearing_surface_refs(anchor_point, clearing_surfaces, DECOR_RELATION_LINK_COUNT)
	var nearest_path_distance: float = INF
	if not path_refs.is_empty():
		nearest_path_distance = float((path_refs[0] as Dictionary).get("distance", INF))
	var nearest_clearing_distance: float = INF
	if not clearing_refs.is_empty():
		nearest_clearing_distance = float((clearing_refs[0] as Dictionary).get("distance", INF))
	var relation_type: String = "route_side" if nearest_path_distance <= nearest_clearing_distance else "clearing_edge"
	return {
		"slot_id": slot_id,
		"source_legacy_field": source_legacy_field,
		"source_shape_index": source_shape_index,
		"decor_family": decor_family,
		"slot_role": "negative_space_decor",
		"anchor_point": anchor_point,
		"rotation_degrees": rotation_degrees,
		"scale": scale,
		"half_size": half_size,
		"radius": radius,
		"relation_type": relation_type,
		"related_path_surface_id": String((path_refs[0] as Dictionary).get("surface_id", "")) if not path_refs.is_empty() else "",
		"related_clearing_surface_id": String((clearing_refs[0] as Dictionary).get("surface_id", "")) if not clearing_refs.is_empty() else "",
		"cardinal_side": _cardinal_side_for_point(anchor_point, board_size),
		"outward_route_hint": _outward_hint_from_refs(path_refs, anchor_point, board_size),
		"asset_socket_kind": "decor",
	}


static func _nearest_path_surface_refs(point: Vector2, path_surfaces: Array, max_count: int) -> Array[Dictionary]:
	var refs: Array[Dictionary] = []
	for surface_variant in path_surfaces:
		if typeof(surface_variant) != TYPE_DICTIONARY:
			continue
		var surface_entry: Dictionary = surface_variant
		var surface_id: String = String(surface_entry.get("surface_id", ""))
		var points: PackedVector2Array = surface_entry.get("centerline_points", PackedVector2Array())
		if surface_id.is_empty() or points.size() < 2:
			continue
		refs.append({
			"surface_id": surface_id,
			"distance": _distance_to_polyline(point, points),
			"cardinal_direction": String(surface_entry.get("cardinal_direction", "")),
			"outward_route_hint": String(surface_entry.get("outward_route_hint", "")),
		})
	refs.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_distance: float = float(left.get("distance", INF))
		var right_distance: float = float(right.get("distance", INF))
		if not is_equal_approx(left_distance, right_distance):
			return left_distance < right_distance
		return String(left.get("surface_id", "")) < String(right.get("surface_id", ""))
	)
	return refs.slice(0, min(max_count, refs.size()))


static func _nearest_clearing_surface_refs(point: Vector2, clearing_surfaces: Array, max_count: int) -> Array[Dictionary]:
	var refs: Array[Dictionary] = []
	for surface_variant in clearing_surfaces:
		if typeof(surface_variant) != TYPE_DICTIONARY:
			continue
		var surface_entry: Dictionary = surface_variant
		var surface_id: String = String(surface_entry.get("surface_id", ""))
		var center: Vector2 = surface_entry.get("center", Vector2.ZERO)
		var radius: float = float(surface_entry.get("radius", 0.0))
		if surface_id.is_empty():
			continue
		refs.append({
			"surface_id": surface_id,
			"node_id": int(surface_entry.get("node_id", -1)),
			"distance": maxf(0.0, point.distance_to(center) - radius),
			"is_current": bool(surface_entry.get("is_current", false)),
		})
	refs.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_distance: float = float(left.get("distance", INF))
		var right_distance: float = float(right.get("distance", INF))
		if not is_equal_approx(left_distance, right_distance):
			return left_distance < right_distance
		return String(left.get("surface_id", "")) < String(right.get("surface_id", ""))
	)
	return refs.slice(0, min(max_count, refs.size()))


static func _distance_to_polyline(point: Vector2, points: PackedVector2Array) -> float:
	var best_distance: float = INF
	for point_index in range(points.size() - 1):
		best_distance = minf(best_distance, _distance_to_segment(point, points[point_index], points[point_index + 1]))
	return best_distance


static func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment: Vector2 = end - start
	var length_squared: float = segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var t: float = clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


static func _surface_ids_from_refs(refs: Array[Dictionary]) -> Array[String]:
	var surface_ids: Array[String] = []
	for ref_entry in refs:
		var surface_id: String = String(ref_entry.get("surface_id", ""))
		if not surface_id.is_empty():
			surface_ids.append(surface_id)
	return surface_ids


static func _surface_by_id(path_surfaces: Array) -> Dictionary:
	var surface_by_id: Dictionary = {}
	for surface_variant in path_surfaces:
		if typeof(surface_variant) != TYPE_DICTIONARY:
			continue
		var surface_entry: Dictionary = surface_variant
		var surface_id: String = String(surface_entry.get("surface_id", ""))
		if not surface_id.is_empty():
			surface_by_id[surface_id] = surface_entry
	return surface_by_id


static func _clearing_surface_by_node_id(clearing_surfaces: Array) -> Dictionary:
	var clearing_by_node_id: Dictionary = {}
	for surface_variant in clearing_surfaces:
		if typeof(surface_variant) != TYPE_DICTIONARY:
			continue
		var surface_entry: Dictionary = surface_variant
		clearing_by_node_id[int(surface_entry.get("node_id", -1))] = surface_entry
	return clearing_by_node_id


static func _cardinal_for_surface_ids(surface_ids: Array, path_surface_by_id: Dictionary, fallback_point: Vector2, board_size: Vector2) -> String:
	for surface_id_variant in surface_ids:
		var surface_entry: Dictionary = path_surface_by_id.get(String(surface_id_variant), {})
		var cardinal_direction: String = String(surface_entry.get("cardinal_direction", ""))
		if not cardinal_direction.is_empty():
			return cardinal_direction
	return _cardinal_side_for_point(fallback_point, board_size)


static func _outward_hint_for_surface_ids(surface_ids: Array, path_surface_by_id: Dictionary, fallback_point: Vector2, board_size: Vector2) -> String:
	for surface_id_variant in surface_ids:
		var surface_entry: Dictionary = path_surface_by_id.get(String(surface_id_variant), {})
		var outward_route_hint: String = String(surface_entry.get("outward_route_hint", ""))
		if not outward_route_hint.is_empty():
			return outward_route_hint
	return "slot_%s" % _cardinal_side_for_point(fallback_point, board_size)


static func _outward_hint_from_refs(path_refs: Array[Dictionary], fallback_point: Vector2, board_size: Vector2) -> String:
	if not path_refs.is_empty():
		var outward_route_hint: String = String((path_refs[0] as Dictionary).get("outward_route_hint", ""))
		if not outward_route_hint.is_empty():
			return outward_route_hint
	return "slot_%s" % _cardinal_side_for_point(fallback_point, board_size)


static func _canopy_mask_role(clearing_refs: Array[Dictionary]) -> String:
	for ref_entry in clearing_refs:
		if bool(ref_entry.get("is_current", false)):
			return "opening_canopy_frame"
	return "route_canopy_frame"


static func _landmark_slot_role(node_entry: Dictionary) -> String:
	if bool(node_entry.get("is_current", false)):
		return "current_landmark"
	if bool(node_entry.get("is_adjacent", false)):
		return "adjacent_landmark"
	return "known_landmark"


static func _cardinal_side_for_point(point: Vector2, board_size: Vector2) -> String:
	if board_size.x <= 0.0 or board_size.y <= 0.0:
		return "center"
	var delta: Vector2 = point - board_size * 0.5
	var board_unit: float = maxf(1.0, minf(board_size.x, board_size.y))
	if delta.length() <= board_unit * 0.08:
		return "center"
	if absf(delta.x) >= absf(delta.y):
		return "east" if delta.x >= 0.0 else "west"
	return "south" if delta.y >= 0.0 else "north"
