# Layer: UI
extends RefCounted
class_name MapBoardStyle

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")

const ATMOSPHERE_BACKGROUND_COLOR := Color(0.02, 0.05, 0.04, 0.24)
const ATMOSPHERE_CENTER_RATIO := Vector2(0.50, 0.60)
const ATMOSPHERE_CENTER_OFFSET_SCALE := 0.18
const ATMOSPHERE_LAYER_RADIUS_MULTIPLIERS := [0.48, 0.34]
const ATMOSPHERE_LAYER_COLORS := [
	Color(0.14, 0.17, 0.11, 0.11),
	Color(0.26, 0.23, 0.12, 0.08),
]
const ATMOSPHERE_UPPER_GLOW_CENTER_RATIO := Vector2(0.50, 0.18)
const ATMOSPHERE_UPPER_GLOW_OFFSET_SCALE := 0.08
const ATMOSPHERE_UPPER_GLOW_RADIUS_MULTIPLIER := 0.13
const ATMOSPHERE_UPPER_GLOW_COLOR := Color(0.66, 0.55, 0.24, 0.05)
const ATMOSPHERE_LOWER_SHADE_CENTER_RATIO := Vector2(0.50, 0.92)
const ATMOSPHERE_LOWER_SHADE_RADIUS_MULTIPLIER := 0.18
const ATMOSPHERE_LOWER_SHADE_COLOR := Color(0.02, 0.04, 0.03, 0.16)
const ATMOSPHERE_GUIDE_ARC_WARM_RADIUS_MULTIPLIER := 0.28
const ATMOSPHERE_GUIDE_ARC_WARM_COLOR := Color(0.84, 0.74, 0.40, 0.05)
const ATMOSPHERE_GUIDE_ARC_WARM_WIDTH := 1.4
const ATMOSPHERE_GUIDE_ARC_COOL_RADIUS_MULTIPLIER := 0.38
const ATMOSPHERE_GUIDE_ARC_COOL_COLOR := Color(0.20, 0.38, 0.30, 0.07)
const ATMOSPHERE_GUIDE_ARC_COOL_WIDTH := 1.8

const CANOPY_TEXTURE_SCALE := 1.92
const DECOR_TEXTURE_SCALE := 1.56
const CANOPY_ALPHA_SCALE := 0.54
const DECOR_ALPHA_SCALE := 0.72
const CANOPY_FALLBACK_LOBE_SCALES := [0.94, 0.72, 0.56]
const CANOPY_FALLBACK_LOBE_OFFSETS := [Vector2(-0.18, -0.10), Vector2(0.18, 0.02), Vector2(0.04, 0.20)]
const CANOPY_FALLBACK_ALPHA_SCALES := [0.84, 0.68, 0.54]

const TRAIL_STAMP_ALPHA_CAP := 0.34
const TRAIL_STAMP_ALPHA_MULTIPLIER := 0.42
const ROAD_HIGHLIGHT_WIDTH_DEFAULT := 3.2
const ROAD_HIGHLIGHT_WIDTH_HISTORY := 3.4
const ROAD_HIGHLIGHT_WIDTH_CURRENT := 4.6
const ROAD_HIGHLIGHT_WIDTH_TARGET := 5.8
const ROAD_BASE_WIDTH_DEFAULT := 12.0
const ROAD_BASE_WIDTH_HISTORY := 10.0
const ROAD_BASE_WIDTH_CURRENT := 13.5
const ROAD_BASE_WIDTH_TARGET := 16.0
const ROAD_SHADOW_WIDTH_DEFAULT := 4.5
const ROAD_SHADOW_WIDTH_HISTORY := 3.8
const ROAD_SHADOW_ALPHA_DEFAULT := 0.22
const ROAD_SHADOW_ALPHA_HISTORY := 0.16
const ROAD_ENDPOINT_TRIM_DEFAULT := 4.0
const ROAD_ENDPOINT_TRIM_CURRENT := 6.0
const ROAD_ENDPOINT_TRIM_TARGET := 8.0

const CLEARING_PLATE_SCALE := 2.32
const CLEARING_PLATE_ALPHA_CURRENT := 0.78
const CLEARING_PLATE_ALPHA_RESOLVED := 0.72
const CLEARING_PLATE_ALPHA_DEFAULT := 0.66
const CLEARING_DECAL_SIZE_MULTIPLIER := Vector2(2.38, 1.70)
const CLEARING_DECAL_Y_OFFSET_MULTIPLIER := 0.01
const CLEARING_DECAL_ALPHA_CURRENT := 0.46
const CLEARING_DECAL_ALPHA_RESOLVED := 0.40
const CLEARING_DECAL_ALPHA_DEFAULT := 0.32
const CLEARING_SHADOW_Y_OFFSET_MULTIPLIER := 0.09
const CLEARING_SHADOW_RADIUS_MULTIPLIER := 0.92
const CLEARING_SHADOW_ALPHA := 0.18
const CLEARING_RIM_RADIUS_MULTIPLIER := 1.02
const CLEARING_FILL_RADIUS_MULTIPLIER := 0.90
const CLEARING_CURRENT_FILL_LIGHTEN := 0.12
const CLEARING_RESOLVED_FILL_MIX := 0.48
const CLEARING_RESOLVED_FILL_ALPHA := 0.60
const CLEARING_LOCKED_FILL_COLOR := Color(0.28, 0.18, 0.12, 0.74)
const CLEARING_RIM_LIGHTEN := 0.18
const CLEARING_RESOLVED_RIM_MIX := 0.40
const CLEARING_RESOLVED_RIM_ALPHA := 0.20
const CLEARING_LOCKED_RIM_COLOR := Color(0.78, 0.52, 0.30, 0.30)
const CLEARING_CURRENT_RIM_COLOR := Color(0.94, 0.84, 0.58, 0.28)
const CLEARING_DEFAULT_RIM_ALPHA := 0.24
const KNOWN_ICON_OPEN_ALPHA_CAP := 0.82
const KNOWN_ICON_SIZE_MULTIPLIER_DEFAULT := 0.98
const KNOWN_ICON_SIZE_MULTIPLIER_CURRENT := 0.74
const KNOWN_ICON_MIN_SIZE_DEFAULT := 28.0
const KNOWN_ICON_MIN_SIZE_CURRENT := 26.0
const KNOWN_ICON_MAX_SIZE_DEFAULT := 42.0
const KNOWN_ICON_MAX_SIZE_CURRENT := 38.0
const KNOWN_ICON_CURRENT_Y_OFFSET_MULTIPLIER := 0.20


static func marker_modulate_for_semantic(state_semantic: String, is_disabled: bool) -> Color:
	if is_disabled:
		return Color(1, 1, 1, 0.9)
	match state_semantic:
		"resolved":
			return Color(0.74, 0.76, 0.72, 0.46)
		"locked":
			return Color(0.90, 0.84, 0.78, 0.92)
		"current":
			return Color(1, 1, 1, 1.0)
		_:
			return Color(1, 1, 1, 1.0)


static func icon_modulate_for_semantic(node_family: String, state_semantic: String, is_disabled: bool, is_preview_node: bool) -> Color:
	if is_preview_node:
		return Color(0.82, 0.86, 0.76, 0.58)
	if is_disabled:
		return Color(0.90, 0.86, 0.76, 0.90)
	match state_semantic:
		"resolved":
			var resolved_color: Color = _family_icon_color(node_family).lerp(Color(0.70, 0.72, 0.68, 1.0), 0.42)
			resolved_color.a = 0.62
			return resolved_color
		"locked":
			return Color(0.96, 0.83, 0.74, 0.90)
		"current":
			var current_color: Color = _family_icon_color(node_family).lightened(0.08)
			current_color.a = 0.96
			return current_color
		_:
			return _family_icon_color(node_family).lightened(0.22)


static func apply_selection_ring(selection_ring: PanelContainer, state_semantic: String, is_selected: bool) -> void:
	if selection_ring == null:
		return

	var accent: Color = _accent_color_for_semantic(state_semantic)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = accent.lightened(0.1) if is_selected else accent
	style.border_width_left = 3 if is_selected else 2
	style.border_width_top = 3 if is_selected else 2
	style.border_width_right = 3 if is_selected else 2
	style.border_width_bottom = 3 if is_selected else 2
	style.corner_radius_top_left = 36
	style.corner_radius_top_right = 36
	style.corner_radius_bottom_right = 36
	style.corner_radius_bottom_left = 36
	style.shadow_color = Color(0, 0, 0, 0.26)
	style.shadow_size = 8
	selection_ring.add_theme_stylebox_override("panel", style)
	selection_ring.modulate = Color(1, 1, 1, 1.0) if is_selected else Color(1, 1, 1, 0.86)


static func apply_node_plate_style(node_plate: PanelContainer, node_family: String, state_semantic: String, is_disabled: bool, is_preview_node: bool) -> void:
	if node_plate == null:
		return

	var fill_color := _family_plate_fill_color(node_family)
	var border_color := _family_border_color(node_family)
	var border_width := 2
	match state_semantic:
		"resolved":
			fill_color = Color(0.06, 0.08, 0.06, 0.48)
			border_color = Color(0.48, 0.48, 0.42, 0.26)
			border_width = 1
		"locked":
			fill_color = Color(0.20, 0.12, 0.10, 0.94)
			border_color = Color(0.88, 0.56, 0.34, 0.92)
		"current":
			fill_color = Color(0.67, 0.56, 0.30, 0.92)
			border_color = Color(1, 0.94, 0.72, 0.0)
			border_width = 0
	if is_preview_node:
		fill_color = Color(0.08, 0.12, 0.09, 0.70)
		border_color = Color(0.40, 0.48, 0.40, 0.32)
		border_width = 1
	if is_disabled:
		fill_color.a *= 0.88
	elif state_semantic == "open":
		fill_color = fill_color.lightened(0.05)
		fill_color.a = 0.96

	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_right = 999
	style.corner_radius_bottom_left = 999
	style.shadow_color = Color(0, 0, 0, 0.26)
	style.shadow_size = 10 if state_semantic == "open" else 4
	node_plate.add_theme_stylebox_override("panel", style)


static func apply_chip_style(chip_panel: PanelContainer, chip_label: Label, state_semantic: String) -> void:
	if chip_panel == null or chip_label == null:
		return

	var accent: Color = _accent_color_for_semantic(state_semantic)
	var fill: Color = TempScreenThemeScript.PANEL_SOFT_FILL_COLOR.lerp(accent, 0.62)
	fill.a = 0.98

	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = accent
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 100
	style.corner_radius_top_right = 100
	style.corner_radius_bottom_right = 100
	style.corner_radius_bottom_left = 100
	style.content_margin_left = 11
	style.content_margin_top = 5
	style.content_margin_right = 11
	style.content_margin_bottom = 5
	chip_panel.add_theme_stylebox_override("panel", style)
	TempScreenThemeScript.apply_font_role(chip_label, "heading")
	chip_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	chip_label.add_theme_font_size_override("font_size", 13)


static func road_base_color(state_semantic: String, emphasis_level: int = 0) -> Color:
	var base_color: Color
	match state_semantic:
		"resolved":
			base_color = Color(0.30, 0.30, 0.28, 0.56)
		"locked":
			base_color = Color(0.50, 0.28, 0.18, 0.76)
		_:
			base_color = Color(0.60, 0.52, 0.30, 0.82)
	if emphasis_level >= 2:
		return _apply_color_emphasis(base_color, 0.08, 0.05)
	if emphasis_level == 1:
		return _apply_color_emphasis(base_color, 0.03, 0.02)
	return base_color


static func road_highlight_color(state_semantic: String, emphasis_level: int = 0) -> Color:
	var highlight_color: Color
	match state_semantic:
		"resolved":
			highlight_color = Color(0.70, 0.69, 0.64, 0.38)
		"locked":
			highlight_color = Color(0.90, 0.70, 0.46, 0.56)
		_:
			highlight_color = Color(0.92, 0.88, 0.76, 0.60)
	if emphasis_level >= 2:
		return _apply_color_emphasis(highlight_color, 0.05, 0.04)
	if emphasis_level == 1:
		return _apply_color_emphasis(highlight_color, 0.02, 0.015)
	return highlight_color


static func board_atmosphere_center(board_size: Vector2, board_offset: Vector2) -> Vector2:
	return board_size * ATMOSPHERE_CENTER_RATIO + board_offset * ATMOSPHERE_CENTER_OFFSET_SCALE


static func board_atmosphere_upper_glow_center(board_size: Vector2, board_offset: Vector2) -> Vector2:
	return board_size * ATMOSPHERE_UPPER_GLOW_CENTER_RATIO + board_offset * ATMOSPHERE_UPPER_GLOW_OFFSET_SCALE


static func forest_texture_scale(shape_family: String) -> float:
	return CANOPY_TEXTURE_SCALE if shape_family == "canopy" else DECOR_TEXTURE_SCALE


static func forest_shape_tint(shape_family: String, tone: Color) -> Color:
	var scaled_tone: Color = tone
	scaled_tone.a *= CANOPY_ALPHA_SCALE if shape_family == "canopy" else DECOR_ALPHA_SCALE
	return scaled_tone


static func forest_shape_fallback_circles(shape_family: String, center: Vector2, radius: float, rotation_radians: float) -> Array:
	if shape_family != "canopy" or radius <= 0.0:
		return [{"center": center, "radius": radius, "alpha_scale": 1.0}]
	var fallback_circles: Array = []
	var mirror_x: float = -1.0 if int(floor(absf(center.x * 0.013 + center.y * 0.009 + radius * 0.17))) % 2 == 1 else 1.0
	var rotation_basis: Vector2 = Vector2.RIGHT.rotated(rotation_radians)
	var cross_basis: Vector2 = rotation_basis.orthogonal()
	for index in range(CANOPY_FALLBACK_LOBE_SCALES.size()):
		var offset_hint: Vector2 = CANOPY_FALLBACK_LOBE_OFFSETS[index]
		var blob_center: Vector2 = center + (
			rotation_basis * (offset_hint.x * mirror_x * radius)
			+ cross_basis * (offset_hint.y * radius)
		)
		fallback_circles.append({
			"center": blob_center,
			"radius": radius * float(CANOPY_FALLBACK_LOBE_SCALES[index]),
			"alpha_scale": float(CANOPY_FALLBACK_ALPHA_SCALES[index]),
		})
	return fallback_circles


static func road_highlight_width(is_history: bool, emphasis_level: int) -> float:
	if emphasis_level >= 2:
		return ROAD_HIGHLIGHT_WIDTH_TARGET
	if emphasis_level == 1:
		return ROAD_HIGHLIGHT_WIDTH_CURRENT
	return ROAD_HIGHLIGHT_WIDTH_HISTORY if is_history else ROAD_HIGHLIGHT_WIDTH_DEFAULT


static func road_base_width(is_history: bool, emphasis_level: int) -> float:
	if emphasis_level >= 2:
		return ROAD_BASE_WIDTH_TARGET
	if emphasis_level == 1:
		return ROAD_BASE_WIDTH_CURRENT
	return ROAD_BASE_WIDTH_HISTORY if is_history else ROAD_BASE_WIDTH_DEFAULT


static func road_shadow_width(is_history: bool) -> float:
	return ROAD_SHADOW_WIDTH_HISTORY if is_history else ROAD_SHADOW_WIDTH_DEFAULT


static func road_shadow_alpha(is_history: bool) -> float:
	return ROAD_SHADOW_ALPHA_HISTORY if is_history else ROAD_SHADOW_ALPHA_DEFAULT


static func road_endpoint_trim(emphasis_level: int) -> float:
	if emphasis_level >= 2:
		return ROAD_ENDPOINT_TRIM_TARGET
	if emphasis_level == 1:
		return ROAD_ENDPOINT_TRIM_CURRENT
	return ROAD_ENDPOINT_TRIM_DEFAULT


static func clearing_plate_alpha(is_current: bool, is_resolved: bool) -> float:
	if is_current:
		return CLEARING_PLATE_ALPHA_CURRENT
	if is_resolved:
		return CLEARING_PLATE_ALPHA_RESOLVED
	return CLEARING_PLATE_ALPHA_DEFAULT


static func clearing_decal_alpha(is_current: bool, is_resolved: bool) -> float:
	if is_current:
		return CLEARING_DECAL_ALPHA_CURRENT
	if is_resolved:
		return CLEARING_DECAL_ALPHA_RESOLVED
	return CLEARING_DECAL_ALPHA_DEFAULT


static func clearing_fill_color(node_family: String, state_semantic: String, is_current: bool) -> Color:
	var base_color: Color = family_ground_tint(node_family)
	if state_semantic == "resolved":
		var muted_fill: Color = base_color.lerp(Color(0.18, 0.20, 0.17, base_color.a), CLEARING_RESOLVED_FILL_MIX)
		muted_fill.a = CLEARING_RESOLVED_FILL_ALPHA
		return muted_fill
	if state_semantic == "locked":
		return CLEARING_LOCKED_FILL_COLOR
	if is_current:
		return base_color.lightened(CLEARING_CURRENT_FILL_LIGHTEN)
	return base_color


static func clearing_rim_color(node_family: String, state_semantic: String, is_current: bool) -> Color:
	var base_color: Color = family_ground_tint(node_family).lightened(CLEARING_RIM_LIGHTEN)
	if state_semantic == "resolved":
		var muted_rim: Color = base_color.lerp(Color(0.54, 0.58, 0.50, 1.0), CLEARING_RESOLVED_RIM_MIX)
		muted_rim.a = CLEARING_RESOLVED_RIM_ALPHA
		return muted_rim
	if state_semantic == "locked":
		return CLEARING_LOCKED_RIM_COLOR
	if is_current:
		return CLEARING_CURRENT_RIM_COLOR
	return Color(base_color.r, base_color.g, base_color.b, CLEARING_DEFAULT_RIM_ALPHA)


static func family_ground_tint(node_family: String) -> Color:
	match node_family:
		"combat":
			return Color(0.48, 0.26, 0.18, 0.80)
		"reward":
			return Color(0.52, 0.44, 0.16, 0.82)
		"hamlet":
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


static func known_icon_size(radius: float, is_current: bool) -> float:
	var multiplier: float = KNOWN_ICON_SIZE_MULTIPLIER_CURRENT if is_current else KNOWN_ICON_SIZE_MULTIPLIER_DEFAULT
	var min_size: float = KNOWN_ICON_MIN_SIZE_CURRENT if is_current else KNOWN_ICON_MIN_SIZE_DEFAULT
	var max_size: float = KNOWN_ICON_MAX_SIZE_CURRENT if is_current else KNOWN_ICON_MAX_SIZE_DEFAULT
	return clampf(radius * multiplier, min_size, max_size)


static func known_icon_center(center: Vector2, radius: float, is_current: bool) -> Vector2:
	if not is_current:
		return center
	return center + Vector2(0.0, radius * KNOWN_ICON_CURRENT_Y_OFFSET_MULTIPLIER)


static func _accent_color_for_semantic(state_semantic: String) -> Color:
	match state_semantic:
		"resolved":
			return TempScreenThemeScript.PANEL_BORDER_COLOR
		"locked":
			return TempScreenThemeScript.RUST_ACCENT_COLOR
		"current":
			return TempScreenThemeScript.REWARD_ACCENT_COLOR
		_:
			return TempScreenThemeScript.TEAL_ACCENT_COLOR


static func _family_plate_fill_color(node_family: String) -> Color:
	match node_family:
		"combat":
			return Color(0.42, 0.22, 0.18, 0.98)
		"reward":
			return Color(0.40, 0.34, 0.14, 0.98)
		"hamlet":
			return Color(0.26, 0.20, 0.36, 0.98)
		"rest":
			return Color(0.18, 0.34, 0.28, 0.98)
		"merchant":
			return Color(0.24, 0.22, 0.40, 0.98)
		"blacksmith":
			return Color(0.36, 0.24, 0.16, 0.98)
		"key":
			return Color(0.44, 0.38, 0.14, 0.98)
		"boss":
			return Color(0.40, 0.16, 0.18, 0.98)
		"event":
			return Color(0.18, 0.28, 0.40, 0.98)
		_:
			return Color(0.30, 0.40, 0.18, 1.0)


static func _family_border_color(node_family: String) -> Color:
	match node_family:
		"combat":
			return Color(0.98, 0.64, 0.48, 1.0)
		"reward":
			return Color(1.0, 0.90, 0.56, 1.0)
		"hamlet":
			return Color(0.88, 0.76, 1.0, 1.0)
		"rest":
			return Color(0.68, 1.0, 0.82, 1.0)
		"merchant":
			return Color(0.84, 0.76, 1.0, 1.0)
		"blacksmith":
			return Color(0.98, 0.74, 0.50, 1.0)
		"key":
			return Color(1.0, 0.92, 0.48, 1.0)
		"boss":
			return Color(1.0, 0.56, 0.60, 1.0)
		"event":
			return Color(0.66, 0.88, 1.0, 1.0)
		_:
			return Color(0.98, 0.90, 0.62, 1.0)


static func _family_icon_color(node_family: String) -> Color:
	match node_family:
		"combat":
			return Color(1.0, 0.86, 0.78, 1.0)
		"reward":
			return Color(1.0, 0.97, 0.68, 1.0)
		"hamlet":
			return Color(0.96, 0.90, 1.0, 1.0)
		"rest":
			return Color(0.88, 1.0, 0.92, 1.0)
		"merchant":
			return Color(0.94, 0.90, 1.0, 1.0)
		"blacksmith":
			return Color(1.0, 0.88, 0.72, 1.0)
		"key":
			return Color(1.0, 0.98, 0.72, 1.0)
		"boss":
			return Color(1.0, 0.80, 0.82, 1.0)
		"event":
			return Color(0.88, 0.98, 1.0, 1.0)
		_:
			return Color(1.0, 0.99, 0.90, 1.0)


static func side_quest_highlight_color(highlight_state: String) -> Color:
	match highlight_state:
		"target":
			return Color(0.96, 0.58, 0.36, 0.94)
		"return":
			return Color(0.84, 0.72, 1.0, 0.94)
		_:
			return Color(0.92, 0.88, 0.72, 0.88)


static func _apply_color_emphasis(color: Color, light_amount: float, alpha_add: float) -> Color:
	var emphasized: Color = color.lightened(light_amount)
	emphasized.a = clampf(color.a + alpha_add, 0.0, 1.0)
	return emphasized
