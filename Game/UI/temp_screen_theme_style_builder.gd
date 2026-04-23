# Layer: UI
extends RefCounted
class_name TempScreenThemeStyleBuilder


static func build_panel_style(
	base_fill: Color,
	accent: Color,
	corner_radius: int,
	fill_alpha: float,
	tokens: Dictionary
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var accent_tint: Color = accent.darkened(0.78)
	var fill_color: Color = base_fill.lerp(
		accent_tint,
		float(tokens.get("fill_mix", 0.12))
	).lightened(float(tokens.get("fill_lighten", 0.02)))
	fill_color.a = fill_alpha
	style.bg_color = fill_color
	style.border_color = accent.lightened(float(tokens.get("border_lighten", 0.08)))
	var border_width: int = int(tokens.get("border_width", 2))
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.shadow_color = Color(accent.r, accent.g, accent.b, float(tokens.get("shadow_alpha", 0.18)))
	style.shadow_size = int(tokens.get("shadow_size", 22))
	var margin_x: int = int(tokens.get("content_margin_x", 18))
	var margin_y: int = int(tokens.get("content_margin_y", 16))
	style.content_margin_left = margin_x
	style.content_margin_top = margin_y
	style.content_margin_right = margin_x
	style.content_margin_bottom = margin_y
	return style


static func apply_panel_style(
	panel: PanelContainer,
	base_fill: Color,
	accent: Color,
	corner_radius: int,
	fill_alpha: float,
	tokens: Dictionary
) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override(
		"panel",
		build_panel_style(base_fill, accent, corner_radius, fill_alpha, tokens)
	)


static func build_chip_style(soft_fill: Color, accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = soft_fill.lerp(accent.darkened(0.74), 0.16)
	style.border_color = accent.lightened(0.1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 12
	style.content_margin_top = 5
	style.content_margin_right = 12
	style.content_margin_bottom = 5
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.16)
	style.shadow_size = 8
	return style


static func build_status_chip_style(soft_fill: Color, accent: Color, density: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = soft_fill.lerp(accent.darkened(0.78), 0.18)
	style.border_color = accent.lightened(0.08)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.16)
	style.shadow_size = 8
	match density:
		"minimal":
			style.content_margin_left = 10
			style.content_margin_top = 6
			style.content_margin_right = 10
			style.content_margin_bottom = 6
		"standard":
			style.content_margin_left = 14
			style.content_margin_top = 8
			style.content_margin_right = 14
			style.content_margin_bottom = 8
		_:
			style.content_margin_left = 12
			style.content_margin_top = 7
			style.content_margin_right = 12
			style.content_margin_bottom = 7
	return style


static func build_progress_bar_background_style(soft_fill: Color) -> StyleBoxFlat:
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = soft_fill.darkened(0.2)
	background_style.corner_radius_top_left = 6
	background_style.corner_radius_top_right = 6
	background_style.corner_radius_bottom_right = 6
	background_style.corner_radius_bottom_left = 6
	background_style.content_margin_left = 0
	background_style.content_margin_top = 0
	background_style.content_margin_right = 0
	background_style.content_margin_bottom = 0
	return background_style


static func build_progress_bar_fill_style(accent: Color) -> StyleBoxFlat:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = accent
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_right = 6
	fill_style.corner_radius_bottom_left = 6
	return fill_style


static func build_tuned_panel_style(
	existing_style: StyleBoxFlat,
	accent: Color,
	border_width: int,
	shadow_size: int,
	fill_boost: float,
	shadow_alpha: float,
	margin_x: int = -1,
	margin_y: int = -1
) -> StyleBoxFlat:
	var tuned_style: StyleBoxFlat = existing_style.duplicate() as StyleBoxFlat
	tuned_style.border_width_left = border_width
	tuned_style.border_width_top = border_width
	tuned_style.border_width_right = border_width
	tuned_style.border_width_bottom = border_width
	tuned_style.border_color = accent.lightened(0.12)
	tuned_style.bg_color = tuned_style.bg_color.lightened(fill_boost)
	tuned_style.shadow_color = Color(accent.r, accent.g, accent.b, shadow_alpha)
	tuned_style.shadow_size = shadow_size
	if margin_x >= 0:
		tuned_style.content_margin_left = margin_x
		tuned_style.content_margin_right = margin_x
	if margin_y >= 0:
		tuned_style.content_margin_top = margin_y
		tuned_style.content_margin_bottom = margin_y
	return tuned_style


static func build_button_box(
	fill_color: Color,
	accent: Color,
	corner_radius: int = 14,
	margin_x: int = 14,
	margin_y: int = 10,
	border_width: int = 2,
	shadow_size: int = 10,
	shadow_alpha: float = 0.22
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = accent.lightened(0.06)
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.content_margin_left = margin_x
	style.content_margin_top = margin_y
	style.content_margin_right = margin_x
	style.content_margin_bottom = margin_y
	style.shadow_color = Color(accent.r, accent.g, accent.b, shadow_alpha)
	style.shadow_size = shadow_size
	return style


static func apply_button_state_overrides(
	button: Button,
	accent: Color,
	normal_fill: Color,
	hover_fill: Color,
	pressed_fill: Color,
	disabled_fill: Color,
	tokens: Dictionary
) -> void:
	if button == null:
		return
	var corner_radius: int = int(tokens.get("corner_radius", 14))
	var margin_x: int = int(tokens.get("margin_x", 14))
	var margin_y: int = int(tokens.get("margin_y", 10))
	var border_width: int = int(tokens.get("border_width", 2))
	button.add_theme_stylebox_override(
		"normal",
		build_button_box(
			normal_fill,
			accent,
			corner_radius,
			margin_x,
			margin_y,
			border_width,
			int(tokens.get("normal_shadow_size", 10)),
			float(tokens.get("normal_shadow_alpha", 0.24))
		)
	)
	button.add_theme_stylebox_override(
		"hover",
		build_button_box(
			hover_fill,
			accent.lightened(float(tokens.get("hover_border_lighten", 0.14))),
			corner_radius,
			margin_x,
			margin_y,
			border_width,
			int(tokens.get("hover_shadow_size", 12)),
			float(tokens.get("hover_shadow_alpha", 0.28))
		)
	)
	button.add_theme_stylebox_override(
		"pressed",
		build_button_box(
			pressed_fill,
			accent,
			corner_radius,
			margin_x,
			margin_y,
			border_width,
			int(tokens.get("pressed_shadow_size", 8)),
			float(tokens.get("pressed_shadow_alpha", 0.2))
		)
	)
	button.add_theme_stylebox_override(
		"disabled",
		build_button_box(
			disabled_fill,
			accent.darkened(0.2),
			corner_radius,
			margin_x,
			margin_y,
			border_width,
			int(tokens.get("disabled_shadow_size", 8)),
			float(tokens.get("disabled_shadow_alpha", 0.12))
		)
	)
	button.add_theme_stylebox_override(
		"focus",
		build_button_box(
			hover_fill,
			accent.lightened(float(tokens.get("focus_border_lighten", 0.2))),
			corner_radius,
			margin_x,
			margin_y,
			border_width,
			int(tokens.get("focus_shadow_size", 12)),
			float(tokens.get("focus_shadow_alpha", 0.3))
		)
	)
