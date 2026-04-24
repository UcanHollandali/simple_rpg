# Layer: UI
extends RefCounted
class_name MapBoardThroatBlendModel

const MapBoardStyleScript = preload("res://Game/UI/map_board_style.gd")


static func build_entries(clearing_surfaces: Array, path_sources_by_id: Dictionary, board_offset: Vector2) -> Array:
	var entries: Array = []
	if path_sources_by_id.is_empty():
		return entries
	for clearing_variant in clearing_surfaces:
		if typeof(clearing_variant) != TYPE_DICTIONARY:
			continue
		var clearing: Dictionary = clearing_variant
		var clearing_center: Vector2 = Vector2(clearing.get("center", Vector2.ZERO)) + board_offset
		var clearing_radius: float = float(clearing.get("radius", 0.0))
		var connected_surface_ids: Array = clearing.get("connected_path_surface_ids", [])
		if clearing_radius <= 0.0 or connected_surface_ids.is_empty():
			continue
		var node_family: String = String(clearing.get("node_family", ""))
		var is_current: bool = bool(clearing.get("is_current", false))
		var clearing_state_semantic: String = String(clearing.get("state_semantic", "open"))
		var clearing_color: Color = MapBoardStyleScript.clearing_fill_color(
			node_family,
			clearing_state_semantic,
			is_current
		)
		clearing_color.a = minf(clearing_color.a * 0.36, 0.22)
		for surface_id_variant in connected_surface_ids:
			var surface_id: String = String(surface_id_variant)
			var source: Dictionary = path_sources_by_id.get(surface_id, {})
			if source.is_empty():
				continue
			var display_points: PackedVector2Array = source.get("display_points", PackedVector2Array())
			if display_points.size() < 2:
				continue
			var throat_point: Vector2 = _nearest_polyline_endpoint(display_points, clearing_center)
			var inward_direction: Vector2 = clearing_center - throat_point
			if inward_direction.length_squared() <= 0.001:
				inward_direction = Vector2(source.get("path_direction", Vector2.RIGHT))
			if inward_direction.length_squared() <= 0.001:
				inward_direction = Vector2.RIGHT
			inward_direction = inward_direction.normalized()
			var is_history: bool = bool(source.get("is_history", false))
			var emphasis_level: int = int(source.get("emphasis_level", 0))
			var surface_width: float = maxf(1.0, float(source.get("surface_width", MapBoardStyleScript.ROAD_BASE_WIDTH_DEFAULT)))
			var blend_radius: float = clampf(surface_width * 0.58, 7.0, clearing_radius * 0.46)
			var road_color: Color = MapBoardStyleScript.road_base_color(
				String(source.get("state_semantic", "open")),
				emphasis_level
			)
			road_color.a = minf(road_color.a * (0.34 if is_history else 0.42), 0.34)
			entries.append({
				"surface_id": surface_id,
				"clearing_surface_id": String(clearing.get("surface_id", "")),
				"node_id": int(clearing.get("node_id", -1)),
				"center": throat_point,
				"inner_center": throat_point + inward_direction * minf(blend_radius * 0.42, clearing_radius * 0.18),
				"outer_radius": blend_radius * 1.28,
				"base_radius": blend_radius,
				"inner_radius": blend_radius * 0.72,
				"road_color": road_color,
				"clearing_color": clearing_color,
			})
	return entries


static func _nearest_polyline_endpoint(points: PackedVector2Array, target: Vector2) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var first_point: Vector2 = points[0]
	var last_point: Vector2 = points[points.size() - 1]
	return first_point if first_point.distance_squared_to(target) <= last_point.distance_squared_to(target) else last_point
