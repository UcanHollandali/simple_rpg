# Layer: UI
extends Control
class_name MapBoardCanvas

const MapBoardStyleScript = preload("res://Game/UI/map_board_style.gd")

var _composition: Dictionary = {}
var _board_offset: Vector2 = Vector2.ZERO
var _active_target_node_id: int = -1
var _hovered_target_node_id: int = -1


func set_composition(composition: Dictionary) -> void:
	_composition = composition.duplicate(true)
	queue_redraw()


func set_board_offset(board_offset: Vector2) -> void:
	if _board_offset == board_offset:
		return
	_board_offset = board_offset
	queue_redraw()


func set_interaction_state(active_target_node_id: int, hovered_target_node_id: int) -> void:
	if _active_target_node_id == active_target_node_id and _hovered_target_node_id == hovered_target_node_id:
		return
	_active_target_node_id = active_target_node_id
	_hovered_target_node_id = hovered_target_node_id
	queue_redraw()


func _draw() -> void:
	if _composition.is_empty():
		return
	_draw_board_atmosphere()
	_draw_forest_shapes("canopy")
	_draw_edges(false)
	_draw_clearings()
	_draw_edges(true)
	_draw_forest_shapes("decor")


func _draw_board_atmosphere() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.07, 0.05, 0.14), true)
	var center: Vector2 = size * Vector2(0.5, 0.58) + _board_offset * 0.18
	var atmosphere_radii: Array[float] = [min(size.x, size.y) * 0.48, min(size.x, size.y) * 0.34]
	var atmosphere_colors: Array[Color] = [
		Color(0.18, 0.16, 0.10, 0.14),
		Color(0.32, 0.26, 0.13, 0.10),
	]
	for index in range(atmosphere_radii.size()):
		draw_circle(center, atmosphere_radii[index], atmosphere_colors[index])


func _draw_forest_shapes(shape_family: String) -> void:
	var forest_shapes: Array = _composition.get("forest_shapes", [])
	for shape_variant in forest_shapes:
		if typeof(shape_variant) != TYPE_DICTIONARY:
			continue
		var shape: Dictionary = shape_variant
		if String(shape.get("family", "")) != shape_family:
			continue
		var center: Vector2 = shape.get("center", Vector2.ZERO) + _board_offset
		var radius: float = float(shape.get("radius", 0.0))
		var tone: Color = shape.get("tone", Color(0.0, 0.0, 0.0, 0.0))
		draw_circle(center, radius, tone)


func _draw_edges(draw_highlight_pass: bool) -> void:
	var visible_edges: Array = _composition.get("visible_edges", [])
	for edge_variant in visible_edges:
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = edge_variant
		var points: PackedVector2Array = edge.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		var translated_points := PackedVector2Array()
		for point in points:
			translated_points.append(point + _board_offset)
		var state_semantic: String = String(edge.get("state_semantic", "open"))
		var emphasis_level: int = _edge_emphasis_level(edge)
		if draw_highlight_pass:
			var highlight_width: float = 4.0
			if emphasis_level >= 2:
				highlight_width = 7.0
			elif emphasis_level == 1:
				highlight_width = 5.2
			draw_polyline(
				translated_points,
				MapBoardStyleScript.road_highlight_color(state_semantic, emphasis_level),
				highlight_width,
				true
			)
		else:
			var base_width: float = 14.0
			if emphasis_level >= 2:
				base_width = 19.0
			elif emphasis_level == 1:
				base_width = 16.0
			draw_polyline(
				translated_points,
				MapBoardStyleScript.road_base_color(state_semantic, emphasis_level),
				base_width,
				true
			)


func _draw_clearings() -> void:
	var visible_nodes: Array = _composition.get("visible_nodes", [])
	var highlight_node_id: int = int(_composition.get("side_mission_highlight_node_id", -1))
	var highlight_state: String = String(_composition.get("side_mission_highlight_state", ""))
	for node_variant in visible_nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var center: Vector2 = node_entry.get("world_position", Vector2.ZERO) + _board_offset
		var radius: float = float(node_entry.get("clearing_radius", 0.0))
		var state_semantic: String = String(node_entry.get("state_semantic", "open"))
		var node_family: String = String(node_entry.get("node_family", ""))
		var is_current: bool = bool(node_entry.get("is_current", false))
		var node_id: int = int(node_entry.get("node_id", -1))
		if is_current:
			draw_circle(center, radius * 1.58, Color(0.96, 0.90, 0.60, 0.08))
		draw_circle(center, radius * 1.08, _clearing_rim_color(node_family, state_semantic, is_current))
		draw_circle(center, radius * 0.92, _clearing_fill_color(node_family, state_semantic, is_current))
		match node_family:
			"key":
				draw_arc(center, radius * 1.10, -0.70, 4.90, 30, Color(1.0, 0.92, 0.56, 0.46), 3.2, true)
			"boss":
				draw_arc(center, radius * 1.12, -0.18, TAU - 0.18, 36, Color(1.0, 0.58, 0.54, 0.52), 3.8, true)
				draw_arc(center, radius * 0.72, 0.44, 2.70, 16, Color(0.94, 0.78, 0.72, 0.28), 2.2, true)
		if node_id == highlight_node_id and not highlight_state.is_empty():
			var highlight_color: Color = MapBoardStyleScript.side_mission_highlight_color(highlight_state)
			draw_circle(center, radius * 1.30, Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.08))
			draw_arc(center, radius * 1.18, 0.0, TAU, 40, highlight_color, 6.0, true)
			draw_arc(center, radius * 1.34, 0.32, TAU + 0.32, 40, Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.54), 3.2, true)
		if is_current:
			draw_arc(center, radius * 1.26, 0.0, TAU, 48, Color(0.98, 0.92, 0.70, 0.84), 4.6, true)
			draw_circle(center, radius * 0.68, Color(0.96, 0.88, 0.56, 0.20))


func _edge_emphasis_level(edge: Dictionary) -> int:
	var from_node_id: int = int(edge.get("from_node_id", -1))
	var to_node_id: int = int(edge.get("to_node_id", -1))
	var current_node_id: int = int(_composition.get("current_node_id", -1))
	if _active_target_node_id >= 0:
		return 2 if (
			(from_node_id == current_node_id and to_node_id == _active_target_node_id)
			or (to_node_id == current_node_id and from_node_id == _active_target_node_id)
		) else 0
	if _hovered_target_node_id >= 0:
		return 2 if (
			(from_node_id == current_node_id and to_node_id == _hovered_target_node_id)
			or (to_node_id == current_node_id and from_node_id == _hovered_target_node_id)
		) else 0
	var emphasis_level: int = 0
	if from_node_id == current_node_id or to_node_id == current_node_id:
		emphasis_level = 1
	var highlight_node_id: int = int(_composition.get("side_mission_highlight_node_id", -1))
	if highlight_node_id >= 0 and (from_node_id == highlight_node_id or to_node_id == highlight_node_id):
		emphasis_level = max(emphasis_level, 2 if from_node_id == current_node_id or to_node_id == current_node_id else 1)
	if _edge_touches_family(from_node_id, to_node_id, "key") or _edge_touches_family(from_node_id, to_node_id, "boss"):
		emphasis_level = max(emphasis_level, 1)
	return emphasis_level


func _edge_touches_family(from_node_id: int, to_node_id: int, node_family: String) -> bool:
	var from_node: Dictionary = _visible_node_entry_by_id(from_node_id)
	if String(from_node.get("node_family", "")) == node_family:
		return true
	var to_node: Dictionary = _visible_node_entry_by_id(to_node_id)
	return String(to_node.get("node_family", "")) == node_family


func _visible_node_entry_by_id(node_id: int) -> Dictionary:
	for node_variant in _composition.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		if int(node_entry.get("node_id", -1)) == node_id:
			return node_entry
	return {}


func _clearing_fill_color(node_family: String, state_semantic: String, is_current: bool) -> Color:
	if state_semantic == "resolved":
		return Color(0.18, 0.19, 0.15, 0.62)
	if state_semantic == "locked":
		return Color(0.30, 0.18, 0.12, 0.80)
	var base_color: Color = _family_ground_tint(node_family)
	if is_current:
		return base_color.lightened(0.20)
	return base_color


func _clearing_rim_color(node_family: String, state_semantic: String, is_current: bool) -> Color:
	if state_semantic == "resolved":
		return Color(0.42, 0.46, 0.38, 0.34)
	if state_semantic == "locked":
		return Color(0.82, 0.52, 0.28, 0.38)
	var base_color: Color = _family_ground_tint(node_family).lightened(0.22)
	if is_current:
		return Color(0.96, 0.88, 0.60, 0.40)
	return Color(base_color.r, base_color.g, base_color.b, 0.32)


func _family_ground_tint(node_family: String) -> Color:
	match node_family:
		"combat":
			return Color(0.48, 0.26, 0.18, 0.80)
		"reward":
			return Color(0.52, 0.44, 0.16, 0.82)
		"side_mission":
			return Color(0.30, 0.22, 0.46, 0.82)
		"rest":
			return Color(0.18, 0.38, 0.28, 0.82)
		"merchant":
			return Color(0.24, 0.24, 0.46, 0.82)
		"blacksmith":
			return Color(0.48, 0.30, 0.16, 0.82)
		"key":
			return Color(0.62, 0.50, 0.14, 0.84)
		"boss":
			return Color(0.52, 0.20, 0.18, 0.86)
		"event":
			return Color(0.18, 0.34, 0.48, 0.82)
		_:
			return Color(0.28, 0.34, 0.18, 0.72)
