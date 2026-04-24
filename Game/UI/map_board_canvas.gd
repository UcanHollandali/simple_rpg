# Layer: UI
extends Control
class_name MapBoardCanvas

const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const MapBoardStyleScript = preload("res://Game/UI/map_board_style.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")

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
	var uses_render_model_surface_lane: bool = _uses_render_model_surface_lane()
	_draw_board_background()
	if uses_render_model_surface_lane:
		_draw_render_landmark_pocket_underlays()
		_draw_path_surfaces(false)
		_draw_path_surface_socket_smoke_dressing()
		_draw_render_junctions()
		_draw_path_surfaces(true)
		_draw_render_clearing_surfaces()
		_draw_render_identity_overlays()
		_draw_landmark_socket_smoke_dressing()
	if uses_render_model_surface_lane:
		_draw_decor_socket_smoke_dressing()


func _draw_board_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), MapBoardStyleScript.ATMOSPHERE_BACKGROUND_COLOR, true)


func _draw_path_surface_socket_smoke_dressing() -> void:
	_draw_socket_smoke_entries(_path_surface_socket_smoke_entries())


func _draw_landmark_socket_smoke_dressing() -> void:
	_draw_socket_smoke_entries(_landmark_socket_smoke_entries())


func _draw_decor_socket_smoke_dressing() -> void:
	_draw_socket_smoke_entries(_decor_socket_smoke_entries())


func _draw_socket_smoke_entries(entries: Array) -> void:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		var texture_path: String = String(entry.get("texture_path", ""))
		var texture: Texture2D = SceneLayoutHelperScript.load_texture_or_null(texture_path)
		if texture == null:
			continue
		_draw_texture_stamp(
			texture,
			Vector2(entry.get("center", Vector2.ZERO)),
			Vector2(entry.get("draw_size", Vector2.ZERO)),
			entry.get("modulate", Color.WHITE),
			float(entry.get("rotation_radians", 0.0))
		)


func _draw_path_surfaces(draw_highlight_pass: bool) -> void:
	for surface_variant in _path_surface_entries():
		if typeof(surface_variant) != TYPE_DICTIONARY:
			continue
		var surface: Dictionary = surface_variant
		var display_points: PackedVector2Array = _display_path_surface_points(surface)
		if display_points.size() < 2:
			continue
		var edge_proxy: Dictionary = _edge_proxy_for_path_surface(surface)
		var emphasis_level: int = _edge_emphasis_level(edge_proxy)
		var visual_profile: Dictionary = _edge_visual_profile(edge_proxy, emphasis_level)
		var is_history: bool = bool(surface.get("is_history", false))
		var state_semantic: String = String(surface.get("state_semantic", "open"))
		if draw_highlight_pass:
			if not bool(visual_profile.get("draw_highlight", emphasis_level > 0)):
				continue
			var highlight_color: Color = MapBoardStyleScript.road_highlight_color(state_semantic, emphasis_level)
			highlight_color.a *= float(visual_profile.get("highlight_alpha_scale", 1.0))
			_draw_polyline_surface(
				display_points,
				MapBoardStyleScript.road_highlight_width(is_history, emphasis_level) * float(visual_profile.get("highlight_width_scale", 1.0)),
				highlight_color
			)
			continue
		var surface_width: float = maxf(1.0, float(surface.get("surface_width", MapBoardStyleScript.road_base_width(is_history, emphasis_level))))
		var outer_width: float = maxf(surface_width, float(surface.get("outer_width", surface_width + 10.0)))
		var base_color: Color = MapBoardStyleScript.road_base_color(state_semantic, emphasis_level)
		base_color.a *= float(visual_profile.get("base_alpha_scale", 1.0))
		_draw_polyline_surface(
			display_points,
			outer_width * float(visual_profile.get("shadow_width_scale", 1.0)),
			Color(0.02, 0.03, 0.02, MapBoardStyleScript.road_shadow_alpha(is_history) * float(visual_profile.get("shadow_alpha_scale", 1.0)))
		)
		_draw_polyline_surface(
			display_points,
			surface_width * float(visual_profile.get("base_width_scale", 1.0)),
			base_color
		)


func _draw_render_junctions() -> void:
	for junction_variant in _junction_entries():
		if typeof(junction_variant) != TYPE_DICTIONARY:
			continue
		var junction: Dictionary = junction_variant
		var center: Vector2 = Vector2(junction.get("center", Vector2.ZERO)) + _board_offset
		var radius: float = float(junction.get("junction_radius", 0.0))
		if radius <= 0.0:
			continue
		var junction_role: String = String(junction.get("junction_role", ""))
		var alpha_scale: float = 0.40 if junction_role == "local_choice_blend" else 0.26
		draw_circle(center + Vector2(0.0, radius * 0.10), radius * 1.18, Color(0.01, 0.02, 0.02, 0.18))
		draw_circle(center, radius, Color(0.56, 0.47, 0.26, alpha_scale))


func _draw_render_landmark_pocket_underlays() -> void:
	for clearing_variant in _clearing_surface_entries():
		if typeof(clearing_variant) != TYPE_DICTIONARY:
			continue
		var clearing: Dictionary = clearing_variant
		var node_entry: Dictionary = _visible_node_entry_by_id(int(clearing.get("node_id", -1)))
		if node_entry.is_empty():
			continue
		_draw_landmark_pocket_underlay(
			node_entry,
			Vector2(clearing.get("center", Vector2.ZERO)) + _board_offset,
			float(clearing.get("radius", 0.0))
		)


func _draw_render_clearing_surfaces() -> void:
	var highlight_node_id: int = int(_composition.get("side_quest_highlight_node_id", -1))
	var highlight_state: String = String(_composition.get("side_quest_highlight_state", ""))
	for clearing_variant in _clearing_surface_entries():
		if typeof(clearing_variant) != TYPE_DICTIONARY:
			continue
		var clearing: Dictionary = clearing_variant
		var center: Vector2 = Vector2(clearing.get("center", Vector2.ZERO)) + _board_offset
		var radius: float = float(clearing.get("radius", 0.0))
		if radius <= 0.0:
			continue
		var state_semantic: String = String(clearing.get("state_semantic", "open"))
		var node_family: String = String(clearing.get("node_family", ""))
		var is_current: bool = bool(clearing.get("is_current", false))
		var node_id: int = int(clearing.get("node_id", -1))
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


func _draw_render_identity_overlays() -> void:
	for clearing_variant in _clearing_surface_entries():
		if typeof(clearing_variant) != TYPE_DICTIONARY:
			continue
		var clearing: Dictionary = clearing_variant
		var node_entry: Dictionary = _visible_node_entry_by_id(int(clearing.get("node_id", -1)))
		if node_entry.is_empty():
			continue
		var center: Vector2 = Vector2(clearing.get("center", Vector2.ZERO)) + _board_offset
		var radius: float = float(clearing.get("radius", 0.0))
		_draw_landmark_identity_overlay(node_entry, center, radius)
		_draw_known_node_icon(node_entry, center, radius)


func _edge_emphasis_level(edge: Dictionary) -> int:
	var from_node_id: int = int(edge.get("from_node_id", -1))
	var to_node_id: int = int(edge.get("to_node_id", -1))
	var current_node_id: int = int(_composition.get("current_node_id", -1))
	if _active_target_node_id >= 0:
		return 3 if (
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


func _edge_route_surface_semantic(edge: Dictionary, emphasis_level: int = -1) -> String:
	if emphasis_level < 0:
		emphasis_level = _edge_emphasis_level(edge)
	if emphasis_level >= 3:
		return "selected"
	if emphasis_level == 2:
		return "preview"
	var route_surface_semantic: String = String(edge.get("route_surface_semantic", ""))
	match route_surface_semantic:
		"primary_actionable_corridor":
			return "primary_actionable_corridor"
		"branch_actionable_corridor":
			return "branch_actionable_corridor"
		"branch_history_corridor":
			return "branch_history_corridor"
		"reconnect_corridor":
			return "reconnect_corridor"
		"history_corridor":
			return "history_corridor"
		"local_actionable":
			return "primary_actionable_corridor"
		"history_reconnect":
			return "reconnect_corridor"
		"history":
			return "history_corridor"
	var is_history: bool = bool(edge.get("is_history", false))
	if not is_history:
		return "primary_actionable_corridor"
	return "reconnect_corridor" if bool(edge.get("is_reconnect_edge", false)) else "history_corridor"


func _edge_visual_profile(edge: Dictionary, emphasis_level: int = -1) -> Dictionary:
	if emphasis_level < 0:
		emphasis_level = _edge_emphasis_level(edge)
	var route_surface_semantic: String = _edge_route_surface_semantic(edge, emphasis_level)
	match route_surface_semantic:
		"selected":
			return {
				"draw_highlight": true,
				"base_alpha_scale": 1.08,
				"base_width_scale": 1.08,
				"shadow_alpha_scale": 1.0,
				"shadow_width_scale": 1.04,
				"highlight_alpha_scale": 1.0,
				"highlight_width_scale": 1.08,
				"trim_scale": 1.0,
				"smoothing_strength": 1.0,
				"corner_radius_min": 18.0,
				"corner_radius_max": 52.0,
			}
		"preview":
			return {
				"draw_highlight": true,
				"base_alpha_scale": 0.88,
				"base_width_scale": 0.94,
				"shadow_alpha_scale": 0.84,
				"shadow_width_scale": 0.94,
				"highlight_alpha_scale": 0.54,
				"highlight_width_scale": 0.94,
				"trim_scale": 0.96,
				"smoothing_strength": 0.92,
				"corner_radius_min": 16.0,
				"corner_radius_max": 46.0,
			}
		"primary_actionable_corridor":
			return {
				"draw_highlight": emphasis_level > 0,
				"base_alpha_scale": 1.0,
				"base_width_scale": 1.0,
				"shadow_alpha_scale": 1.0,
				"shadow_width_scale": 1.0,
				"highlight_alpha_scale": 1.0,
				"highlight_width_scale": 1.0,
				"trim_scale": 1.0,
				"smoothing_strength": 1.0,
				"corner_radius_min": 18.0,
				"corner_radius_max": 52.0,
			}
		"branch_actionable_corridor", "actionable_secondary":
			return {
				"draw_highlight": false,
				"base_alpha_scale": 0.74,
				"base_width_scale": 0.88,
				"shadow_alpha_scale": 0.68,
				"shadow_width_scale": 0.90,
				"highlight_alpha_scale": 0.0,
				"highlight_width_scale": 0.84,
				"trim_scale": 0.92,
				"smoothing_strength": 0.78,
				"corner_radius_min": 14.0,
				"corner_radius_max": 40.0,
			}
		"branch_history_corridor":
			return {
				"draw_highlight": false,
				"base_alpha_scale": 0.58,
				"base_width_scale": 0.82,
				"shadow_alpha_scale": 0.52,
				"shadow_width_scale": 0.82,
				"highlight_alpha_scale": 0.0,
				"highlight_width_scale": 0.78,
				"trim_scale": 0.86,
				"smoothing_strength": 0.38,
				"corner_radius_min": 12.0,
				"corner_radius_max": 30.0,
			}
		"history_corridor":
			return {
				"draw_highlight": false,
				"base_alpha_scale": 0.42,
				"base_width_scale": 0.72,
				"shadow_alpha_scale": 0.40,
				"shadow_width_scale": 0.76,
				"highlight_alpha_scale": 0.0,
				"highlight_width_scale": 0.76,
				"trim_scale": 0.84,
				"smoothing_strength": 0.34,
				"corner_radius_min": 10.0,
				"corner_radius_max": 24.0,
			}
		"reconnect_corridor", "history_reconnect":
			return {
				"draw_highlight": false,
				"base_alpha_scale": 0.22,
				"base_width_scale": 0.68,
				"shadow_alpha_scale": 0.28,
				"shadow_width_scale": 0.72,
				"highlight_alpha_scale": 0.0,
				"highlight_width_scale": 0.72,
				"trim_scale": 0.82,
				"smoothing_strength": 0.0,
				"corner_radius_min": 0.0,
				"corner_radius_max": 0.0,
			}
		_:
			return {
				"draw_highlight": false,
				"base_alpha_scale": 0.22,
				"base_width_scale": 0.68,
				"shadow_alpha_scale": 0.28,
				"shadow_width_scale": 0.72,
				"highlight_alpha_scale": 0.0,
				"highlight_width_scale": 0.72,
				"trim_scale": 0.82,
				"smoothing_strength": 0.0,
				"corner_radius_min": 0.0,
				"corner_radius_max": 0.0,
			}


func _has_route_interaction_target() -> bool:
	return _active_target_node_id >= 0 or _hovered_target_node_id >= 0


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


func _render_model() -> Dictionary:
	var render_model_variant: Variant = _composition.get("render_model", {})
	return render_model_variant if typeof(render_model_variant) == TYPE_DICTIONARY else {}


func _uses_render_model_surface_lane() -> bool:
	return not _path_surface_entries().is_empty() and not _clearing_surface_entries().is_empty()


func _path_surface_entries() -> Array:
	var render_model: Dictionary = _render_model()
	return (render_model.get("path_surfaces", []) as Array).duplicate(true)


func _landmark_slot_entries() -> Array:
	var render_model: Dictionary = _render_model()
	return (render_model.get("landmark_slots", []) as Array).duplicate(true)


func _decor_slot_entries() -> Array:
	var render_model: Dictionary = _render_model()
	return (render_model.get("decor_slots", []) as Array).duplicate(true)


func _path_surface_socket_smoke_entries() -> Array:
	var entries: Array = []
	var texture_path: String = UiAssetPathsScript.build_map_path_surface_socket_texture_path()
	if texture_path.is_empty():
		return entries
	for surface_variant in _path_surface_entries():
		if typeof(surface_variant) != TYPE_DICTIONARY:
			continue
		var surface: Dictionary = surface_variant
		var display_points: PackedVector2Array = _display_path_surface_points(surface)
		if display_points.size() < 2:
			continue
		var is_history: bool = bool(surface.get("is_history", false))
		var surface_width: float = maxf(1.0, float(surface.get("surface_width", 24.0)))
		var direction: Vector2 = _direction_for_polyline(display_points)
		entries.append({
			"socket_kind": UiAssetPathsScript.MAP_SOCKET_SMOKE_KIND_PATH_SURFACE,
			"surface_id": String(surface.get("surface_id", "")),
			"texture_path": texture_path,
			"center": _midpoint_for_polyline(display_points),
			"draw_size": Vector2(
				clampf(surface_width * 1.72, 24.0, 52.0),
				clampf(surface_width * 0.68, 12.0, 24.0)
			),
			"rotation_radians": atan2(direction.y, direction.x),
			"modulate": Color(1, 1, 1, 0.14 if is_history else 0.22),
		})
	return entries


func _landmark_socket_smoke_entries() -> Array:
	var entries: Array = []
	for slot_variant in _landmark_slot_entries():
		if typeof(slot_variant) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = slot_variant
		var texture_path: String = UiAssetPathsScript.build_map_landmark_socket_texture_path(
			String(slot.get("asset_family_key", "")),
			String(slot.get("node_family", ""))
		)
		if texture_path.is_empty():
			continue
		var landmark_half_size: Vector2 = Vector2(slot.get("landmark_half_size", Vector2.ONE * 18.0))
		var draw_span: float = clampf(maxf(landmark_half_size.x, landmark_half_size.y) * 1.08, 18.0, 38.0)
		var slot_role: String = String(slot.get("slot_role", ""))
		entries.append({
			"socket_kind": UiAssetPathsScript.MAP_SOCKET_SMOKE_KIND_LANDMARK,
			"slot_id": String(slot.get("slot_id", "")),
			"texture_path": texture_path,
			"center": Vector2(slot.get("anchor_point", Vector2.ZERO)) + _board_offset,
			"draw_size": Vector2.ONE * draw_span,
			"rotation_radians": deg_to_rad(float(slot.get("rotation_degrees", 0.0))),
			"modulate": Color(1, 1, 1, 0.38 if slot_role in ["current_landmark", "adjacent_landmark"] else 0.26),
		})
	return entries


func _decor_socket_smoke_entries() -> Array:
	var entries: Array = []
	for slot_variant in _decor_slot_entries():
		if typeof(slot_variant) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = slot_variant
		var texture_path: String = UiAssetPathsScript.build_map_decor_socket_texture_path(String(slot.get("asset_family_key", "")))
		if texture_path.is_empty():
			continue
		var half_size: Vector2 = Vector2(slot.get("half_size", Vector2.ZERO))
		var radius: float = float(slot.get("radius", 0.0))
		var footprint_span: float = maxf(radius * 1.36, maxf(half_size.x, half_size.y) * 0.68)
		entries.append({
			"socket_kind": UiAssetPathsScript.MAP_SOCKET_SMOKE_KIND_DECOR,
			"slot_id": String(slot.get("slot_id", "")),
			"texture_path": texture_path,
			"center": Vector2(slot.get("anchor_point", Vector2.ZERO)) + _board_offset,
			"draw_size": Vector2.ONE * clampf(footprint_span, 12.0, 30.0),
			"rotation_radians": deg_to_rad(float(slot.get("rotation_degrees", 0.0))),
			"modulate": Color(1, 1, 1, 0.34),
		})
	return entries


func _junction_entries() -> Array:
	var render_model: Dictionary = _render_model()
	return (render_model.get("junctions", []) as Array).duplicate(true)


func _clearing_surface_entries() -> Array:
	var render_model: Dictionary = _render_model()
	return (render_model.get("clearing_surfaces", []) as Array).duplicate(true)


func _edge_proxy_for_path_surface(surface: Dictionary) -> Dictionary:
	return {
		"from_node_id": int(surface.get("from_node_id", -1)),
		"to_node_id": int(surface.get("to_node_id", -1)),
		"is_history": bool(surface.get("is_history", false)),
		"is_reconnect_edge": bool(surface.get("is_reconnect_edge", false)),
		"route_surface_semantic": String(surface.get("route_surface_semantic", surface.get("role", ""))),
		"state_semantic": String(surface.get("state_semantic", "open")),
	}


func _display_path_surface_points(surface: Dictionary) -> PackedVector2Array:
	var points: PackedVector2Array = surface.get("centerline_points", PackedVector2Array())
	var edge_proxy: Dictionary = _edge_proxy_for_path_surface(surface)
	var visual_profile: Dictionary = _edge_visual_profile(edge_proxy)
	var smoothing_strength: float = float(visual_profile.get("smoothing_strength", 1.0))
	if points.size() < 3 or smoothing_strength <= 0.01:
		return _translated_edge_points(points)
	return _display_edge_points(
		points,
		smoothing_strength,
		float(visual_profile.get("corner_radius_min", 18.0)),
		float(visual_profile.get("corner_radius_max", 52.0))
	)


func _draw_polyline_surface(points: PackedVector2Array, width: float, color: Color) -> void:
	if points.size() < 2 or width <= 0.0 or color.a <= 0.0:
		return
	var half_width: float = width * 0.5
	var surface_polygons: Array[PackedVector2Array] = _polyline_surface_segment_polygons(points, half_width)
	if surface_polygons.is_empty():
		return
	for surface_polygon in surface_polygons:
		draw_colored_polygon(surface_polygon, color)
	var cap_points: PackedVector2Array = _deduplicated_surface_points(points)
	for cap_point in cap_points:
		draw_circle(cap_point, half_width, color)


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
	var footprint: Dictionary = _landmark_footprint_for_node(node_entry)
	var icon_tint: Color = MapBoardStyleScript.icon_modulate_for_semantic(node_family, state_semantic, false, false)
	if state_semantic == "open":
		icon_tint.a = min(icon_tint.a, MapBoardStyleScript.KNOWN_ICON_OPEN_ALPHA_CAP)
	if not footprint.is_empty():
		icon_tint.a *= MapBoardStyleScript.landmark_icon_alpha_scale(state_semantic, is_current)
	var icon_rect: Rect2 = _known_icon_rect_for_node(node_entry, center, radius)
	draw_texture_rect(icon_texture, icon_rect, false, icon_tint)


func _draw_landmark_pocket_underlay(node_entry: Dictionary, center: Vector2, radius: float) -> void:
	var footprint: Dictionary = _landmark_footprint_for_node(node_entry)
	if footprint.is_empty():
		return
	var state_semantic: String = String(node_entry.get("state_semantic", "open"))
	var node_family: String = String(node_entry.get("node_family", ""))
	var is_current: bool = bool(node_entry.get("is_current", false))
	var pocket_polygon: PackedVector2Array = _landmark_pocket_polygon(center, footprint, radius)
	if pocket_polygon.is_empty():
		return
	draw_colored_polygon(
		pocket_polygon,
		MapBoardStyleScript.landmark_pocket_fill_color(node_family, state_semantic, is_current)
	)
	_draw_closed_polyline(
		pocket_polygon,
		MapBoardStyleScript.landmark_pocket_rim_color(node_family, state_semantic, is_current),
		3.0 if node_family in ["key", "boss"] else 2.4
	)


func _draw_landmark_identity_overlay(node_entry: Dictionary, center: Vector2, radius: float) -> void:
	var footprint: Dictionary = _landmark_footprint_for_node(node_entry)
	if footprint.is_empty():
		return
	var state_semantic: String = String(node_entry.get("state_semantic", "open"))
	var node_family: String = String(node_entry.get("node_family", ""))
	var is_current: bool = bool(node_entry.get("is_current", false))
	var anchor_color: Color = MapBoardStyleScript.landmark_anchor_color(node_family, state_semantic, is_current)
	var signage_color: Color = MapBoardStyleScript.landmark_signage_color(node_family, state_semantic, is_current)
	var route_anchor_direction: Vector2 = Vector2(footprint.get("route_anchor_direction", Vector2.UP))
	var route_lateral_direction: Vector2 = Vector2(footprint.get("route_lateral_direction", Vector2.RIGHT))
	var landmark_center: Vector2 = center + Vector2(footprint.get("landmark_center_offset", Vector2.ZERO))
	var landmark_half_size: Vector2 = Vector2(footprint.get("landmark_half_size", Vector2.ZERO))
	var landmark_rotation_radians: float = deg_to_rad(float(footprint.get("landmark_rotation_degrees", 0.0)))
	var landmark_shape: String = String(footprint.get("landmark_shape", ""))
	_draw_landmark_anchor_shape(
		landmark_shape,
		landmark_center,
		landmark_half_size,
		landmark_rotation_radians,
		route_anchor_direction,
		route_lateral_direction,
		anchor_color
	)
	var signage_center: Vector2 = center + Vector2(footprint.get("signage_center_offset", Vector2.ZERO))
	var signage_scale: float = float(footprint.get("signage_scale", 0.72))
	var signage_shape: String = String(footprint.get("signage_shape", "round_badge"))
	var signage_size: Vector2 = Vector2.ONE * clampf(radius * signage_scale, 18.0, 34.0)
	if signage_shape == "tab":
		var tab_polygon: PackedVector2Array = _rotated_rect_polygon(signage_center, Vector2(signage_size.x * 0.78, signage_size.y * 0.44), landmark_rotation_radians)
		draw_colored_polygon(tab_polygon, signage_color)
		_draw_closed_polyline(tab_polygon, Color(1, 1, 1, signage_color.a * 0.38), 1.4)
	else:
		draw_circle(signage_center, signage_size.x * 0.38, signage_color)
		draw_arc(signage_center, signage_size.x * 0.38, 0.0, TAU, 24, Color(1, 1, 1, signage_color.a * 0.44), 1.6, true)


func _draw_landmark_anchor_shape(
	landmark_shape: String,
	landmark_center: Vector2,
	landmark_half_size: Vector2,
	landmark_rotation_radians: float,
	route_anchor_direction: Vector2,
	route_lateral_direction: Vector2,
	anchor_color: Color
) -> void:
	if landmark_half_size.x <= 0.0 or landmark_half_size.y <= 0.0:
		return
	match landmark_shape:
		"crossed_stakes":
			var left_stake: PackedVector2Array = _rotated_rect_polygon(landmark_center + route_lateral_direction * landmark_half_size.x * 0.12, Vector2(landmark_half_size.x * 0.14, landmark_half_size.y), landmark_rotation_radians - 0.52)
			var right_stake: PackedVector2Array = _rotated_rect_polygon(landmark_center - route_lateral_direction * landmark_half_size.x * 0.12, Vector2(landmark_half_size.x * 0.14, landmark_half_size.y), landmark_rotation_radians + 0.52)
			draw_colored_polygon(left_stake, anchor_color)
			draw_colored_polygon(right_stake, anchor_color)
			draw_circle(landmark_center + route_anchor_direction * landmark_half_size.y * 0.10, landmark_half_size.x * 0.28, Color(anchor_color.r, anchor_color.g, anchor_color.b, anchor_color.a * 0.54))
		"cache_slab":
			var cache_slab: PackedVector2Array = _rotated_rect_polygon(landmark_center, landmark_half_size, landmark_rotation_radians)
			draw_colored_polygon(cache_slab, anchor_color)
			draw_circle(landmark_center - route_lateral_direction * landmark_half_size.x * 0.38, landmark_half_size.y * 0.26, Color(1, 1, 1, anchor_color.a * 0.18))
			draw_circle(landmark_center + route_lateral_direction * landmark_half_size.x * 0.38, landmark_half_size.y * 0.26, Color(1, 1, 1, anchor_color.a * 0.18))
		"standing_stone":
			var stone: PackedVector2Array = _rotated_rect_polygon(landmark_center, Vector2(landmark_half_size.x * 0.60, landmark_half_size.y), landmark_rotation_radians)
			draw_colored_polygon(stone, anchor_color)
			draw_arc(landmark_center, landmark_half_size.x * 0.52, -1.2, 1.2, 14, Color(1, 1, 1, anchor_color.a * 0.18), 1.4, true)
		"waypost":
			var post: PackedVector2Array = _rotated_rect_polygon(landmark_center + route_anchor_direction * landmark_half_size.y * 0.10, Vector2(landmark_half_size.x * 0.14, landmark_half_size.y), landmark_rotation_radians)
			var signboard: PackedVector2Array = _rotated_rect_polygon(landmark_center - route_anchor_direction * landmark_half_size.y * 0.22 + route_lateral_direction * landmark_half_size.x * 0.24, Vector2(landmark_half_size.x * 0.46, landmark_half_size.y * 0.22), landmark_rotation_radians)
			draw_colored_polygon(post, anchor_color)
			draw_colored_polygon(signboard, Color(anchor_color.r, anchor_color.g, anchor_color.b, anchor_color.a * 0.88))
		"campfire":
			draw_circle(landmark_center, landmark_half_size.x * 0.34, anchor_color)
			var left_roll: PackedVector2Array = _ellipse_polygon(landmark_center - route_lateral_direction * landmark_half_size.x * 0.54 + route_anchor_direction * landmark_half_size.y * 0.18, Vector2(landmark_half_size.x * 0.30, landmark_half_size.y * 0.18), landmark_rotation_radians, 18)
			var right_roll: PackedVector2Array = _ellipse_polygon(landmark_center + route_lateral_direction * landmark_half_size.x * 0.54 + route_anchor_direction * landmark_half_size.y * 0.18, Vector2(landmark_half_size.x * 0.30, landmark_half_size.y * 0.18), landmark_rotation_radians, 18)
			draw_colored_polygon(left_roll, Color(anchor_color.r, anchor_color.g, anchor_color.b, anchor_color.a * 0.52))
			draw_colored_polygon(right_roll, Color(anchor_color.r, anchor_color.g, anchor_color.b, anchor_color.a * 0.52))
		"stall":
			var awning: PackedVector2Array = _rotated_rect_polygon(landmark_center - route_anchor_direction * landmark_half_size.y * 0.20, Vector2(landmark_half_size.x, landmark_half_size.y * 0.24), landmark_rotation_radians)
			var table: PackedVector2Array = _rotated_rect_polygon(landmark_center + route_anchor_direction * landmark_half_size.y * 0.16, Vector2(landmark_half_size.x * 0.72, landmark_half_size.y * 0.20), landmark_rotation_radians)
			draw_colored_polygon(awning, anchor_color)
			draw_colored_polygon(table, Color(anchor_color.r, anchor_color.g, anchor_color.b, anchor_color.a * 0.68))
		"forge":
			var hearth: PackedVector2Array = _rotated_rect_polygon(landmark_center + route_anchor_direction * landmark_half_size.y * 0.14, Vector2(landmark_half_size.x * 0.72, landmark_half_size.y * 0.28), landmark_rotation_radians)
			var anvil: PackedVector2Array = _rotated_rect_polygon(landmark_center - route_anchor_direction * landmark_half_size.y * 0.18, Vector2(landmark_half_size.x * 0.42, landmark_half_size.y * 0.18), landmark_rotation_radians)
			draw_colored_polygon(hearth, anchor_color)
			draw_colored_polygon(anvil, Color(anchor_color.r, anchor_color.g, anchor_color.b, anchor_color.a * 0.72))
		"shrine":
			var pedestal: PackedVector2Array = _rotated_rect_polygon(landmark_center + route_anchor_direction * landmark_half_size.y * 0.14, Vector2(landmark_half_size.x * 0.32, landmark_half_size.y * 0.48), landmark_rotation_radians)
			draw_colored_polygon(pedestal, anchor_color)
			draw_circle(landmark_center - route_anchor_direction * landmark_half_size.y * 0.22, landmark_half_size.x * 0.24, Color(1, 1, 1, anchor_color.a * 0.30))
		"gate":
			var left_post: PackedVector2Array = _rotated_rect_polygon(landmark_center - route_lateral_direction * landmark_half_size.x * 0.56, Vector2(landmark_half_size.x * 0.18, landmark_half_size.y), landmark_rotation_radians)
			var right_post: PackedVector2Array = _rotated_rect_polygon(landmark_center + route_lateral_direction * landmark_half_size.x * 0.56, Vector2(landmark_half_size.x * 0.18, landmark_half_size.y), landmark_rotation_radians)
			var lintel: PackedVector2Array = _rotated_rect_polygon(landmark_center - route_anchor_direction * landmark_half_size.y * 0.42, Vector2(landmark_half_size.x * 0.78, landmark_half_size.y * 0.16), landmark_rotation_radians)
			draw_colored_polygon(left_post, anchor_color)
			draw_colored_polygon(right_post, anchor_color)
			draw_colored_polygon(lintel, Color(anchor_color.r, anchor_color.g, anchor_color.b, anchor_color.a * 0.80))
		_:
			var fallback_stone: PackedVector2Array = _ellipse_polygon(landmark_center, landmark_half_size, landmark_rotation_radians, 18)
			draw_colored_polygon(fallback_stone, anchor_color)


func _known_icon_rect_for_node(node_entry: Dictionary, center: Vector2, radius: float) -> Rect2:
	var is_current: bool = bool(node_entry.get("is_current", false))
	var icon_size: float = MapBoardStyleScript.known_icon_size(radius, is_current)
	var icon_center: Vector2 = MapBoardStyleScript.known_icon_center(center, radius, is_current)
	var footprint: Dictionary = _landmark_footprint_for_node(node_entry)
	if not footprint.is_empty():
		icon_center = center + Vector2(footprint.get("signage_center_offset", Vector2.ZERO))
		icon_size *= clampf(float(footprint.get("signage_scale", 0.72)), 0.52, 0.92)
	return Rect2(icon_center - Vector2.ONE * (icon_size * 0.5), Vector2.ONE * icon_size)


func _landmark_pocket_polygon(center: Vector2, footprint: Dictionary, radius: float) -> PackedVector2Array:
	var pocket_center: Vector2 = center + Vector2(footprint.get("pocket_center_offset", Vector2.ZERO))
	var pocket_half_size: Vector2 = Vector2(footprint.get("pocket_half_size", Vector2.ZERO))
	var pocket_rotation_radians: float = deg_to_rad(float(footprint.get("pocket_rotation_degrees", 0.0)))
	var pocket_shape: String = String(footprint.get("pocket_shape", "ellipse"))
	if pocket_half_size.x <= radius or pocket_half_size.y <= radius * 0.6:
		return PackedVector2Array()
	if pocket_shape == "rect":
		return _rotated_rect_polygon(pocket_center, pocket_half_size, pocket_rotation_radians)
	if pocket_shape == "diamond":
		return _diamond_polygon(pocket_center, pocket_half_size, pocket_rotation_radians)
	return _ellipse_polygon(pocket_center, pocket_half_size, pocket_rotation_radians, 24)


func _landmark_footprint_for_node(node_entry: Dictionary) -> Dictionary:
	var footprint_variant: Variant = node_entry.get("landmark_footprint", {})
	return footprint_variant if typeof(footprint_variant) == TYPE_DICTIONARY else {}


func _translated_edge_points(points: PackedVector2Array) -> PackedVector2Array:
	var translated_points := PackedVector2Array()
	for point in points:
		translated_points.append(point + _board_offset)
	return translated_points


func _display_edge_points(
	points: PackedVector2Array,
	smoothing_strength: float = 1.0,
	corner_radius_min: float = 18.0,
	corner_radius_max: float = 52.0
) -> PackedVector2Array:
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
		var corner_radius: float = clampf(
			minf(incoming_length, outgoing_length) * 0.26 * smoothing_strength,
			corner_radius_min,
			corner_radius_max
		)
		var entry_point: Vector2 = corner_point - incoming_direction * corner_radius
		var exit_point: Vector2 = corner_point + outgoing_direction * corner_radius
		_append_display_point(smoothed_points, entry_point)
		var curved_points: PackedVector2Array = _sample_quadratic_display_curve(entry_point, corner_point, exit_point, 5)
		for curved_point_index in range(1, curved_points.size()):
			_append_display_point(smoothed_points, curved_points[curved_point_index])
	_append_display_point(smoothed_points, translated_points[translated_points.size() - 1])
	return smoothed_points


func _polyline_strip_polygon(points: PackedVector2Array, half_width: float) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	if points.size() < 2 or half_width <= 0.0:
		return polygon
	var left_points := PackedVector2Array()
	var right_points := PackedVector2Array()
	for point_index in range(points.size()):
		var offset: Vector2 = _polyline_strip_offset_at(points, point_index, half_width)
		left_points.append(points[point_index] + offset)
		right_points.append(points[point_index] - offset)
	for point in left_points:
		polygon.append(point)
	for reverse_index in range(right_points.size() - 1, -1, -1):
		polygon.append(right_points[reverse_index])
	return polygon


func _polyline_surface_segment_polygons(points: PackedVector2Array, half_width: float) -> Array[PackedVector2Array]:
	var surface_polygons: Array[PackedVector2Array] = []
	var surface_points: PackedVector2Array = _deduplicated_surface_points(points)
	if surface_points.size() < 2 or half_width <= 0.0:
		return surface_polygons
	for point_index in range(surface_points.size() - 1):
		var segment_polygon: PackedVector2Array = _polyline_surface_segment_polygon(
			surface_points[point_index],
			surface_points[point_index + 1],
			half_width
		)
		if segment_polygon.size() >= 3:
			surface_polygons.append(segment_polygon)
	return surface_polygons


func _polyline_surface_segment_polygon(from_point: Vector2, to_point: Vector2, half_width: float) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	var segment: Vector2 = to_point - from_point
	if segment.length_squared() <= 0.001 or half_width <= 0.0:
		return polygon
	var normal: Vector2 = Vector2(-segment.y, segment.x).normalized() * half_width
	polygon.append(from_point + normal)
	polygon.append(to_point + normal)
	polygon.append(to_point - normal)
	polygon.append(from_point - normal)
	return polygon


func _deduplicated_surface_points(points: PackedVector2Array) -> PackedVector2Array:
	var deduplicated_points := PackedVector2Array()
	for point in points:
		if deduplicated_points.is_empty() or deduplicated_points[deduplicated_points.size() - 1].distance_squared_to(point) > 0.001:
			deduplicated_points.append(point)
	return deduplicated_points


func _polyline_strip_offset_at(points: PackedVector2Array, point_index: int, half_width: float) -> Vector2:
	var point_count: int = points.size()
	var previous_point: Vector2 = points[max(point_index - 1, 0)]
	var current_point: Vector2 = points[point_index]
	var next_point: Vector2 = points[min(point_index + 1, point_count - 1)]
	var tangent: Vector2 = next_point - previous_point
	if tangent.length_squared() <= 0.001:
		tangent = Vector2.RIGHT
	var normal: Vector2 = Vector2(-tangent.y, tangent.x).normalized()
	if point_index <= 0 or point_index >= point_count - 1:
		return normal * half_width
	var incoming: Vector2 = current_point - previous_point
	var outgoing: Vector2 = next_point - current_point
	if incoming.length_squared() <= 0.001 or outgoing.length_squared() <= 0.001:
		return normal * half_width
	var incoming_normal: Vector2 = Vector2(-incoming.y, incoming.x).normalized()
	var outgoing_normal: Vector2 = Vector2(-outgoing.y, outgoing.x).normalized()
	var miter: Vector2 = incoming_normal + outgoing_normal
	if miter.length_squared() <= 0.001:
		return outgoing_normal * half_width
	miter = miter.normalized()
	var denominator: float = maxf(0.45, absf(miter.dot(outgoing_normal)))
	return miter * minf(half_width / denominator, half_width * 1.85)


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


func _ellipse_polygon(center: Vector2, half_size: Vector2, rotation_radians: float, point_count: int) -> PackedVector2Array:
	var ellipse_points := PackedVector2Array()
	var basis_x: Vector2 = Vector2.RIGHT.rotated(rotation_radians)
	var basis_y: Vector2 = Vector2.DOWN.rotated(rotation_radians)
	for index in range(point_count):
		var angle: float = TAU * float(index) / float(point_count)
		ellipse_points.append(
			center
			+ basis_x * cos(angle) * half_size.x
			+ basis_y * sin(angle) * half_size.y
		)
	return ellipse_points


func _rotated_rect_polygon(center: Vector2, half_size: Vector2, rotation_radians: float) -> PackedVector2Array:
	var rect_points := PackedVector2Array()
	var basis_x: Vector2 = Vector2.RIGHT.rotated(rotation_radians)
	var basis_y: Vector2 = Vector2.DOWN.rotated(rotation_radians)
	rect_points.append(center + basis_x * -half_size.x + basis_y * -half_size.y)
	rect_points.append(center + basis_x * half_size.x + basis_y * -half_size.y)
	rect_points.append(center + basis_x * half_size.x + basis_y * half_size.y)
	rect_points.append(center + basis_x * -half_size.x + basis_y * half_size.y)
	return rect_points


func _diamond_polygon(center: Vector2, half_size: Vector2, rotation_radians: float) -> PackedVector2Array:
	var diamond_points := PackedVector2Array()
	var basis_x: Vector2 = Vector2.RIGHT.rotated(rotation_radians)
	var basis_y: Vector2 = Vector2.DOWN.rotated(rotation_radians)
	diamond_points.append(center - basis_y * half_size.y)
	diamond_points.append(center + basis_x * half_size.x)
	diamond_points.append(center + basis_y * half_size.y)
	diamond_points.append(center - basis_x * half_size.x)
	return diamond_points


func _draw_closed_polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2 or color.a <= 0.0 or width <= 0.0:
		return
	var closed_points := PackedVector2Array(points)
	closed_points.append(points[0])
	draw_polyline(closed_points, color, width, true)


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
