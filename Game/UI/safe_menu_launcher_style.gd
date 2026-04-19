# Layer: UI
extends RefCounted
class_name SafeMenuLauncherStyle

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const SETTINGS_ICON = preload("res://Assets/Icons/icon_settings.svg")
const LARGE_LAYOUT_MIN_HEIGHT := 1640.0
const MEDIUM_LAYOUT_MIN_HEIGHT := 1460.0
const LAUNCHER_DIMENSIONS_SMALL := Vector2(56.0, 64.0)
const LAUNCHER_DIMENSIONS_MEDIUM := Vector2(62.0, 70.0)
const LAUNCHER_DIMENSIONS_LARGE := Vector2(68.0, 76.0)


static func resolve_launcher_metrics_for_viewport(viewport_size: Vector2) -> Dictionary:
	var large_layout: bool = viewport_size.y >= LARGE_LAYOUT_MIN_HEIGHT and viewport_size.x >= 900.0
	var medium_layout: bool = not large_layout and viewport_size.y >= MEDIUM_LAYOUT_MIN_HEIGHT and viewport_size.x >= 760.0
	var launcher_dimensions: Vector2 = LAUNCHER_DIMENSIONS_LARGE if large_layout else LAUNCHER_DIMENSIONS_MEDIUM if medium_layout else LAUNCHER_DIMENSIONS_SMALL
	var launcher_inset: float = 18.0 if large_layout else 16.0 if medium_layout else 12.0
	var launcher_top: float = 18.0 if large_layout else 14.0 if medium_layout else 10.0
	var launcher_icon_size: int = int(round(minf(launcher_dimensions.x, launcher_dimensions.y) * 0.52))
	launcher_icon_size = clamp(launcher_icon_size, 24, int(minf(launcher_dimensions.x, launcher_dimensions.y)) - 10)
	return {
		"large_layout": large_layout,
		"medium_layout": medium_layout,
		"dimensions": launcher_dimensions,
		"inset": launcher_inset,
		"top": launcher_top,
		"icon_size": launcher_icon_size,
	}


static func apply_shared_launcher_button_style(button: Button, launcher_text: String = "Settings", launcher_dimensions: Vector2 = LAUNCHER_DIMENSIONS_MEDIUM, launcher_icon_size: int = 28) -> void:
	if button == null:
		return
	button.text = ""
	button.tooltip_text = launcher_text
	button.icon = SETTINGS_ICON
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size = launcher_dimensions

	var box := StyleBoxFlat.new()
	box.bg_color = TempScreenThemeScript.PANEL_FILL_COLOR
	box.bg_color.a = 0.98
	box.border_color = TempScreenThemeScript.PANEL_BORDER_COLOR
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.corner_radius_top_left = 20
	box.corner_radius_top_right = 20
	box.corner_radius_bottom_right = 20
	box.corner_radius_bottom_left = 20
	box.content_margin_left = 0
	box.content_margin_top = 0
	box.content_margin_right = 0
	box.content_margin_bottom = 0
	box.shadow_color = Color(0, 0, 0, 0.24)
	box.shadow_size = 10

	var hover_box: StyleBoxFlat = box.duplicate() as StyleBoxFlat
	hover_box.bg_color = hover_box.bg_color.lightened(0.05)
	hover_box.border_color = TempScreenThemeScript.PANEL_BORDER_COLOR.lightened(0.08)

	for style_name in ["normal", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(style_name, box)
	button.add_theme_stylebox_override("hover", hover_box)
	button.add_theme_constant_override("h_separation", 0)
	button.add_theme_constant_override("icon_max_width", launcher_icon_size)
	button.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	button.add_theme_color_override("font_hover_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	button.add_theme_color_override("font_pressed_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	button.add_theme_color_override("font_disabled_color", TempScreenThemeScript.DISABLED_TEXT_COLOR)
	button.add_theme_font_size_override("font_size", 1)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for property_meta in button.get_property_list():
		var property_name: String = String(property_meta.get("name", ""))
		if property_name == "icon_alignment":
			button.set("icon_alignment", HORIZONTAL_ALIGNMENT_CENTER)
		elif property_name == "expand_icon":
			button.set("expand_icon", false)
