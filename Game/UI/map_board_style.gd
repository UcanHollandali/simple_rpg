# Layer: UI
extends RefCounted
class_name MapBoardStyle

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")


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
			base_color = Color(0.34, 0.32, 0.28, 0.78)
		"locked":
			base_color = Color(0.54, 0.28, 0.18, 0.84)
		_:
			base_color = Color(0.66, 0.56, 0.30, 0.92)
	if emphasis_level >= 2:
		return _apply_color_emphasis(base_color, 0.12, 0.08)
	if emphasis_level == 1:
		return _apply_color_emphasis(base_color, 0.05, 0.04)
	return base_color


static func road_highlight_color(state_semantic: String, emphasis_level: int = 0) -> Color:
	var highlight_color: Color
	match state_semantic:
		"resolved":
			highlight_color = Color(0.74, 0.72, 0.66, 0.82)
		"locked":
			highlight_color = Color(0.94, 0.72, 0.48, 0.88)
		_:
			highlight_color = Color(0.96, 0.92, 0.80, 0.92)
	if emphasis_level >= 2:
		return _apply_color_emphasis(highlight_color, 0.08, 0.06)
	if emphasis_level == 1:
		return _apply_color_emphasis(highlight_color, 0.03, 0.03)
	return highlight_color


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
