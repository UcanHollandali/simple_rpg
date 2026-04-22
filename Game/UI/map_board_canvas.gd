# Layer: UI
extends Control
class_name MapBoardCanvas

const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
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
	_draw_trail_decals()
	_draw_clearings()
	_draw_edges(true)
	_draw_forest_shapes("decor")


func _draw_board_atmosphere() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), MapBoardStyleScript.ATMOSPHERE_BACKGROUND_COLOR, true)
	var board_span: float = minf(size.x, size.y)
	var center: Vector2 = MapBoardStyleScript.board_atmosphere_center(size, _board_offset)
	for index in range(MapBoardStyleScript.ATMOSPHERE_LAYER_RADIUS_MULTIPLIERS.size()):
		draw_circle(
			center,
			board_span * float(MapBoardStyleScript.ATMOSPHERE_LAYER_RADIUS_MULTIPLIERS[index]),
			MapBoardStyleScript.ATMOSPHERE_LAYER_COLORS[index]
		)
	var upper_glow_center: Vector2 = MapBoardStyleScript.board_atmosphere_upper_glow_center(size, _board_offset)
	draw_circle(
		upper_glow_center,
		board_span * MapBoardStyleScript.ATMOSPHERE_UPPER_GLOW_RADIUS_MULTIPLIER,
		MapBoardStyleScript.ATMOSPHERE_UPPER_GLOW_COLOR
	)
	draw_circle(
		size * MapBoardStyleScript.ATMOSPHERE_LOWER_SHADE_CENTER_RATIO,
		board_span * MapBoardStyleScript.ATMOSPHERE_LOWER_SHADE_RADIUS_MULTIPLIER,
		MapBoardStyleScript.ATMOSPHERE_LOWER_SHADE_COLOR
	)
	draw_arc(
		center,
		board_span * MapBoardStyleScript.ATMOSPHERE_GUIDE_ARC_WARM_RADIUS_MULTIPLIER,
		-0.16,
		PI + 0.16,
		48,
		MapBoardStyleScript.ATMOSPHERE_GUIDE_ARC_WARM_COLOR,
		MapBoardStyleScript.ATMOSPHERE_GUIDE_ARC_WARM_WIDTH,
		true
	)
	draw_arc(
		center,
		board_span * MapBoardStyleScript.ATMOSPHERE_GUIDE_ARC_COOL_RADIUS_MULTIPLIER,
		PI + 0.18,
		TAU - 0.18,
		52,
		MapBoardStyleScript.ATMOSPHERE_GUIDE_ARC_COOL_COLOR,
		MapBoardStyleScript.ATMOSPHERE_GUIDE_ARC_COOL_WIDTH,
		true
	)


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
		var tinted_tone: Color = MapBoardStyleScript.forest_shape_tint(shape_family, tone)
		var texture_path: String = String(shape.get("texture_path", ""))
		var texture: Texture2D = SceneLayoutHelperScript.load_texture_or_null(texture_path)
		var rotation_radians: float = deg_to_rad(float(shape.get("rotation_degrees", 0.0)))
		if texture != null:
			var texture_scale: float = MapBoardStyleScript.forest_texture_scale(shape_family)
			_draw_texture_stamp(
				texture,
				center,
				Vector2.ONE * radius * texture_scale,
				tinted_tone,
				rotation_radians
			)
			continue
		for circle_variant in MapBoardStyleScript.forest_shape_fallback_circles(shape_family, center, radius, rotation_radians):
			var circle_center: Vector2 = circle_variant.get("center", center)
			var circle_radius: float = float(circle_variant.get("radius", radius))
			var alpha_scale: float = float(circle_variant.get("alpha_scale", 1.0))
			draw_circle(
				circle_center,
				circle_radius,
				Color(tinted_tone.r, tinted_tone.g, tinted_tone.b, tinted_tone.a * alpha_scale)
			)


func _draw_trail_decals() -> void:
	var visible_edges: Array = _composition.get("visible_edges", [])
	for edge_variant in visible_edges:
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = edge_variant
		var trail_texture_path: String = String(edge.get("trail_texture_path", ""))
		var trail_texture: Texture2D = SceneLayoutHelperScript.load_texture_or_null(trail_texture_path)
		if trail_texture == null:
			continue
		var translated_points: PackedVector2Array = _display_edge_points(edge.get("points", PackedVector2Array()))
		if translated_points.size() < 2:
			continue
		var center: Vector2 = _midpoint_for_polyline(translated_points)
		var direction: Vector2 = _direction_for_polyline(translated_points)
		var chord_length: float = translated_points[0].distance_to(translated_points[translated_points.size() - 1])
		var size_scale: Vector2 = Vector2(
			clampf(chord_length * 0.88, 110.0, 224.0),
			clampf(34.0 + chord_length * 0.06, 26.0, 58.0)
		)
		var state_semantic: String = String(edge.get("state_semantic", "open"))
		var emphasis_level: int = _edge_emphasis_level(edge)
		var stamp_tint: Color = MapBoardStyleScript.road_base_color(state_semantic, emphasis_level)
		stamp_tint.a = min(MapBoardStyleScript.TRAIL_STAMP_ALPHA_CAP, stamp_tint.a * MapBoardStyleScript.TRAIL_STAMP_ALPHA_MULTIPLIER)
		_draw_texture_stamp(
			trail_texture,
			center,
			size_scale,
			stamp_tint,
			atan2(direction.y, direction.x)
		)


func _draw_edges(draw_highlight_pass: bool) -> void:
	var visible_edges: Array = _composition.get("visible_edges", [])
	for edge_variant in visible_edges:
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = edge_variant
		var points: PackedVector2Array = edge.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		var is_history: bool = bool(edge.get("is_history", false))
		var translated_points: PackedVector2Array = _display_edge_points(points)
		var state_semantic: String = String(edge.get("state_semantic", "open"))
		var emphasis_level: int = _edge_emphasis_level(edge)
		if draw_highlight_pass:
			if is_history and emphasis_level == 0:
				continue
			var highlight_points: PackedVector2Array = _trim_polyline_endpoints(
				translated_points,
				MapBoardStyleScript.road_endpoint_trim(emphasis_level),
				MapBoardStyleScript.road_endpoint_trim(emphasis_level)
			)
			draw_polyline(
				highlight_points,
				MapBoardStyleScript.road_highlight_color(state_semantic, emphasis_level),
				MapBoardStyleScript.road_highlight_width(is_history, emphasis_level),
				true
			)
		else:
			var base_width: float = MapBoardStyleScript.road_base_width(is_history, emphasis_level)
			var shadow_width: float = MapBoardStyleScript.road_shadow_width(is_history)
			var shadow_alpha: float = MapBoardStyleScript.road_shadow_alpha(is_history)
			draw_polyline(
				translated_points,
				Color(0.02, 0.03, 0.02, shadow_alpha),
				base_width + shadow_width,
				true
			)
			draw_polyline(
				translated_points,
				MapBoardStyleScript.road_base_color(state_semantic, emphasis_level),
				base_width,
				true
			)


func _draw_clearings() -> void:
	var visible_nodes: Array = _composition.get("visible_nodes", [])
	var highlight_node_id: int = int(_composition.get("side_quest_highlight_node_id", -1))
	var highlight_state: String = String(_composition.get("side_quest_highlight_state", ""))
	for node_variant in visible_nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var center: Vector2 = node_entry.get("world_position", Vector2.ZERO) + _board_offset
		var radius: float = float(node_entry.get("clearing_radius", 0.0))
		var state_semantic: String = String(node_entry.get("state_semantic", "open"))
		var node_family: String = String(node_entry.get("node_family", ""))
		var is_current: bool = bool(node_entry.get("is_current", false))
		var is_resolved: bool = state_semantic == "resolved"
		var node_id: int = int(node_entry.get("node_id", -1))
		var plate_texture: Texture2D = SceneLayoutHelperScript.load_texture_or_null(String(node_entry.get("node_plate_texture_path", "")))
		if plate_texture != null:
			var plate_size: float = radius * MapBoardStyleScript.CLEARING_PLATE_SCALE
			_draw_texture_stamp(
				plate_texture,
				center,
				Vector2.ONE * plate_size,
				Color(1, 1, 1, MapBoardStyleScript.clearing_plate_alpha(is_current, is_resolved))
			)
		var clearing_texture: Texture2D = SceneLayoutHelperScript.load_texture_or_null(String(node_entry.get("clearing_decal_texture_path", "")))
		if clearing_texture != null:
			var clearing_size: Vector2 = radius * MapBoardStyleScript.CLEARING_DECAL_SIZE_MULTIPLIER
			_draw_texture_stamp(
				clearing_texture,
				center + Vector2(0.0, radius * MapBoardStyleScript.CLEARING_DECAL_Y_OFFSET_MULTIPLIER),
				clearing_size,
				Color(1, 1, 1, MapBoardStyleScript.clearing_decal_alpha(is_current, is_resolved))
			)
		draw_circle(
			center + Vector2(0.0, radius * MapBoardStyleScript.CLEARING_SHADOW_Y_OFFSET_MULTIPLIER),
			radius * MapBoardStyleScript.CLEARING_SHADOW_RADIUS_MULTIPLIER,
			Color(0.01, 0.02, 0.02, MapBoardStyleScript.CLEARING_SHADOW_ALPHA)
		)
		draw_circle(
			center,
			radius * MapBoardStyleScript.CLEARING_RIM_RADIUS_MULTIPLIER,
			MapBoardStyleScript.clearing_rim_color(node_family, state_semantic, is_current)
		)
		draw_circle(
			center,
			radius * MapBoardStyleScript.CLEARING_FILL_RADIUS_MULTIPLIER,
			MapBoardStyleScript.clearing_fill_color(node_family, state_semantic, is_current)
		)
		match node_family:
			"key":
				draw_arc(center, radius * 1.10, -0.70, 4.90, 30, Color(1.0, 0.92, 0.56, 0.46), 3.2, true)
			"boss":
				draw_arc(center, radius * 1.12, -0.18, TAU - 0.18, 36, Color(1.0, 0.58, 0.54, 0.52), 3.8, true)
				draw_arc(center, radius * 0.72, 0.44, 2.70, 16, Color(0.94, 0.78, 0.72, 0.28), 2.2, true)
		if node_id == highlight_node_id and not highlight_state.is_empty():
			var highlight_color: Color = MapBoardStyleScript.side_quest_highlight_color(highlight_state)
			draw_circle(center, radius * 1.22, Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.06))
			draw_arc(center, radius * 1.12, 0.0, TAU, 40, highlight_color, 5.0, true)
			draw_arc(center, radius * 1.24, 0.32, TAU + 0.32, 40, Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.46), 2.8, true)
		_draw_known_node_icon(node_entry, center, radius)


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
	var highlight_node_id: int = int(_composition.get("side_quest_highlight_node_id", -1))
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


func _draw_known_node_icon(node_entry: Dictionary, center: Vector2, radius: float) -> void:
	if not bool(node_entry.get("show_known_icon", false)):
		return
	var icon_texture_path: String = String(node_entry.get("icon_texture_path", ""))
	if icon_texture_path.is_empty():
		return
	var icon_texture: Texture2D = SceneLayoutHelperScript.load_texture_or_null(icon_texture_path)
	if icon_texture == null:
		return
	var state_semantic: String = String(node_entry.get("state_semantic", "open"))
	var node_family: String = String(node_entry.get("node_family", ""))
	var is_current: bool = bool(node_entry.get("is_current", false))
	var icon_tint: Color = MapBoardStyleScript.icon_modulate_for_semantic(node_family, state_semantic, false, false)
	if state_semantic == "open":
		icon_tint.a = min(icon_tint.a, MapBoardStyleScript.KNOWN_ICON_OPEN_ALPHA_CAP)
	var icon_size: float = MapBoardStyleScript.known_icon_size(radius, is_current)
	var icon_center: Vector2 = MapBoardStyleScript.known_icon_center(center, radius, is_current)
	var icon_rect := Rect2(icon_center - Vector2.ONE * (icon_size * 0.5), Vector2.ONE * icon_size)
	draw_texture_rect(icon_texture, icon_rect, false, icon_tint)


func _translated_edge_points(points: PackedVector2Array) -> PackedVector2Array:
	var translated_points := PackedVector2Array()
	for point in points:
		translated_points.append(point + _board_offset)
	return translated_points


func _display_edge_points(points: PackedVector2Array) -> PackedVector2Array:
	var translated_points: PackedVector2Array = _translated_edge_points(points)
	if translated_points.size() < 3:
		return translated_points
	var smoothed_points := PackedVector2Array()
	_append_display_point(smoothed_points, translated_points[0])
	for point_index in range(1, translated_points.size() - 1):
		var previous_point: Vector2 = translated_points[point_index - 1]
		var corner_point: Vector2 = translated_points[point_index]
		var next_point: Vector2 = translated_points[point_index + 1]
		var incoming: Vector2 = corner_point - previous_point
		var outgoing: Vector2 = next_point - corner_point
		var incoming_length: float = incoming.length()
		var outgoing_length: float = outgoing.length()
		if incoming_length <= 0.001 or outgoing_length <= 0.001:
			_append_display_point(smoothed_points, corner_point)
			continue
		var incoming_direction: Vector2 = incoming / incoming_length
		var outgoing_direction: Vector2 = outgoing / outgoing_length
		if absf(incoming_direction.dot(outgoing_direction)) >= 0.999:
			_append_display_point(smoothed_points, corner_point)
			continue
		var corner_radius: float = clampf(minf(incoming_length, outgoing_length) * 0.26, 18.0, 52.0)
		var entry_point: Vector2 = corner_point - incoming_direction * corner_radius
		var exit_point: Vector2 = corner_point + outgoing_direction * corner_radius
		_append_display_point(smoothed_points, entry_point)
		var curved_points: PackedVector2Array = _sample_quadratic_display_curve(entry_point, corner_point, exit_point, 5)
		for curved_point_index in range(1, curved_points.size()):
			_append_display_point(smoothed_points, curved_points[curved_point_index])
	_append_display_point(smoothed_points, translated_points[translated_points.size() - 1])
	return smoothed_points


func _sample_quadratic_display_curve(
	p0: Vector2,
	p1: Vector2,
	p2: Vector2,
	segment_count: int
) -> PackedVector2Array:
	var sampled_points := PackedVector2Array()
	for index in range(segment_count + 1):
		var t: float = float(index) / float(segment_count)
		var one_minus_t: float = 1.0 - t
		var point: Vector2 = (
			p0 * one_minus_t * one_minus_t
			+ p1 * 2.0 * one_minus_t * t
			+ p2 * t * t
		)
		sampled_points.append(point)
	return sampled_points


func _append_display_point(points: PackedVector2Array, point: Vector2) -> void:
	if points.is_empty() or points[points.size() - 1].distance_to(point) > 0.5:
		points.append(point)


func _midpoint_for_polyline(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	return points[int(points.size() / 2)]


func _direction_for_polyline(points: PackedVector2Array) -> Vector2:
	if points.size() < 2:
		return Vector2.RIGHT
	var midpoint_index: int = int(points.size() / 2)
	var from_index: int = max(0, midpoint_index - 1)
	var to_index: int = min(points.size() - 1, midpoint_index + 1)
	var direction: Vector2 = points[to_index] - points[from_index]
	if direction.length_squared() <= 0.001:
		direction = points[points.size() - 1] - points[0]
	return direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT


func _trim_polyline_endpoints(points: PackedVector2Array, start_trim: float, end_trim: float) -> PackedVector2Array:
	if points.size() < 2:
		return points
	var trimmed_points: Array = []
	for point in points:
		trimmed_points.append(point)
	trimmed_points = _trim_polyline_side(trimmed_points, start_trim, true)
	trimmed_points = _trim_polyline_side(trimmed_points, end_trim, false)
	if trimmed_points.size() < 2:
		return points
	var packed_points := PackedVector2Array()
	for point in trimmed_points:
		packed_points.append(point)
	return packed_points


func _trim_polyline_side(points: Array, trim_amount: float, trim_from_start: bool) -> Array:
	var remaining: float = trim_amount
	while remaining > 0.001 and points.size() >= 2:
		var anchor_index: int = 0 if trim_from_start else points.size() - 1
		var neighbor_index: int = 1 if trim_from_start else points.size() - 2
		var anchor_point: Vector2 = points[anchor_index]
		var neighbor_point: Vector2 = points[neighbor_index]
		var segment: Vector2 = neighbor_point - anchor_point
		var segment_length: float = segment.length()
		if segment_length <= 0.001:
			points.remove_at(anchor_index)
			continue
		if segment_length <= remaining and points.size() > 2:
			points.remove_at(anchor_index)
			remaining -= segment_length
			continue
		var direction: Vector2 = segment / segment_length
		remaining = min(remaining, maxf(segment_length - 0.001, 0.0))
		if trim_from_start:
			points[0] = anchor_point + direction * remaining
		else:
			points[points.size() - 1] = anchor_point + direction * remaining
		break
	return points


func _draw_texture_stamp(
	texture: Texture2D,
	center: Vector2,
	draw_size: Vector2,
	modulate: Color,
	rotation_radians: float = 0.0
) -> void:
	if texture == null:
		return
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale: Vector2 = Vector2(
		draw_size.x / texture_size.x,
		draw_size.y / texture_size.y
	)
	draw_set_transform(center, rotation_radians, scale)
	draw_texture_rect(
		texture,
		Rect2(-texture_size * 0.5, texture_size),
		false,
		modulate
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
