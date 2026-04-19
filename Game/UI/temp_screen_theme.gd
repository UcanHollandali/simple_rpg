# Layer: UI
extends RefCounted
class_name TempScreenTheme

const UiTypographyScript = preload("res://Game/UI/ui_typography.gd")

const PANEL_FILL_COLOR := Color(0.0549019, 0.0784314, 0.0941176, 0.96)
const PANEL_SOFT_FILL_COLOR := Color(0.0980392, 0.1294118, 0.145098, 0.94)
const PANEL_BORDER_COLOR := Color(0.5686275, 0.4862745, 0.3411765, 0.96)
const TEAL_ACCENT_COLOR := Color(0.2470588, 0.4196078, 0.3960784, 0.94)
const RUST_ACCENT_COLOR := Color(0.6588235, 0.3372549, 0.2470588, 0.96)
const REWARD_ACCENT_COLOR := Color(0.7803922, 0.6862745, 0.3843137, 0.98)
const TEXT_PRIMARY_COLOR := Color(0.9568627, 0.945098, 0.8745098, 1.0)
const TEXT_MUTED_COLOR := Color(0.8156863, 0.7647059, 0.6235294, 0.98)
const TEXT_SUBTLE_COLOR := Color(0.8745098, 0.8509804, 0.7843137, 0.96)
const DISABLED_TEXT_COLOR := Color(0.5294118, 0.5137255, 0.4705882, 0.74)
const BACKDROP_SCRIM_COLOR := Color(0.0235294, 0.0352941, 0.0470588, 0.76)


static func apply_portrait_safe_margins(margin: MarginContainer, max_content_width: int = 960, min_side_margin: int = 28, top_margin: int = 30, bottom_margin: int = 30) -> int:
	if margin == null:
		return 0

	var viewport_width: float = margin.get_viewport_rect().size.x
	var target_content_width: float = max(0.0, min(float(max_content_width), viewport_width - float(min_side_margin * 2)))
	var side_margin: int = min_side_margin
	if viewport_width > 0.0 and target_content_width > 0.0:
		side_margin = max(min_side_margin, int(floor((viewport_width - target_content_width) * 0.5)))

	margin.add_theme_constant_override("margin_left", side_margin)
	margin.add_theme_constant_override("margin_right", side_margin)
	margin.add_theme_constant_override("margin_top", top_margin)
	margin.add_theme_constant_override("margin_bottom", bottom_margin)
	return int(target_content_width)


static func ensure_shell(parent: Control, target: Control, shell_name: String, pad_x: float = 12.0, pad_y: float = 12.0, accent: Color = PANEL_BORDER_COLOR) -> PanelContainer:
	if parent == null or target == null:
		return null

	var shell: PanelContainer = parent.get_node_or_null(shell_name) as PanelContainer
	if shell == null:
		shell = PanelContainer.new()
		shell.name = shell_name
		shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(shell)

	parent.move_child(shell, 0)
	shell.anchor_left = target.anchor_left
	shell.anchor_top = target.anchor_top
	shell.anchor_right = target.anchor_right
	shell.anchor_bottom = target.anchor_bottom
	shell.offset_left = target.offset_left - pad_x
	shell.offset_top = target.offset_top - pad_y
	shell.offset_right = target.offset_right + pad_x
	shell.offset_bottom = target.offset_bottom + pad_y
	apply_panel(shell, accent, 22, 0.88)
	return shell


static func apply_panel(panel: PanelContainer, accent: Color = PANEL_BORDER_COLOR, corner_radius: int = 18, fill_alpha: float = 0.9) -> void:
	if panel == null:
		return

	var style: StyleBoxFlat = StyleBoxFlat.new()
	var accent_tint: Color = accent.darkened(0.78)
	var fill_color: Color = PANEL_FILL_COLOR.lerp(accent_tint, 0.12).lightened(0.02)
	fill_color.a = fill_alpha
	style.bg_color = fill_color
	style.border_color = accent.lightened(0.08)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.18)
	style.shadow_size = 22
	style.content_margin_left = 18
	style.content_margin_top = 16
	style.content_margin_right = 18
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)


static func apply_chip(panel: PanelContainer, label: Label, accent: Color = TEAL_ACCENT_COLOR) -> void:
	if panel == null or label == null:
		return

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_SOFT_FILL_COLOR.lerp(accent.darkened(0.74), 0.16)
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
	panel.add_theme_stylebox_override("panel", style)
	apply_font_role(label, UiTypographyScript.ROLE_HEADING)
	label.add_theme_color_override("font_color", TEXT_PRIMARY_COLOR)
	label.add_theme_font_size_override("font_size", UiTypographyScript.DEFAULT_CHIP_SIZE)


static func apply_compact_status_area(panel: PanelContainer, accent: Color = PANEL_BORDER_COLOR) -> void:
	if panel == null:
		return
	apply_panel(panel, accent, 16, 0.88)
	intensify_panel(panel, accent, 3, 18, 0.03, 0.18, 16, 12)


static func apply_choice_card_shell(panel: PanelContainer, accent: Color = PANEL_BORDER_COLOR) -> void:
	if panel == null:
		return
	apply_panel(panel, accent, 18, 0.9)
	intensify_panel(panel, accent, 3, 20, 0.04, 0.24, 18, 16)


static func apply_inventory_section_panel(panel: PanelContainer, accent: Color = PANEL_BORDER_COLOR, density: String = "standard") -> void:
	if panel == null:
		return

	var corner_radius: int = 18
	var fill_alpha: float = 0.9
	var border_width: int = 3
	var shadow_size: int = 20
	var fill_boost: float = 0.04
	var shadow_alpha: float = 0.24
	var margin_x: int = 18
	var margin_y: int = 16
	match density:
		"compact":
			corner_radius = 16
			fill_alpha = 0.88
			border_width = 3
			shadow_size = 18
			fill_boost = 0.03
			shadow_alpha = 0.22
			margin_x = 16
			margin_y = 13
		"roomy":
			corner_radius = 18
			fill_alpha = 0.9
			border_width = 3
			shadow_size = 22
			fill_boost = 0.04
			shadow_alpha = 0.24
			margin_x = 18
			margin_y = 16
	apply_panel(panel, accent, corner_radius, fill_alpha)
	intensify_panel(panel, accent, border_width, shadow_size, fill_boost, shadow_alpha, margin_x, margin_y)


static func apply_inventory_section_text(title_label: Label, hint_label: Label, tone: String, density: String = "standard") -> void:
	if title_label != null:
		apply_label(title_label, tone)
		var title_size: int = UiTypographyScript.DEFAULT_HEADING_SIZE
		match tone:
			"accent":
				title_size = UiTypographyScript.DEFAULT_HEADING_SIZE
			"reward":
				title_size = UiTypographyScript.DEFAULT_HEADING_SIZE + 1
			_:
				title_size = UiTypographyScript.DEFAULT_HEADING_SIZE
		if density == "compact":
			title_size -= 1
		title_label.add_theme_font_size_override("font_size", title_size)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		title_label.max_lines_visible = 1

	if hint_label != null:
		apply_label(hint_label, "muted")
		hint_label.add_theme_font_size_override("font_size", 13 if density == "compact" else 14)
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_label.max_lines_visible = 1 if density == "compact" else 2


static func apply_status_chip_shell(panel: PanelContainer, accent: Color = TEAL_ACCENT_COLOR, density: String = "compact") -> void:
	if panel == null:
		return

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_SOFT_FILL_COLOR.lerp(accent.darkened(0.78), 0.18)
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
	panel.add_theme_stylebox_override("panel", style)


static func apply_status_progress_bar(bar: ProgressBar, accent: Color = TEAL_ACCENT_COLOR) -> void:
	if bar == null:
		return

	var background_style: StyleBoxFlat = StyleBoxFlat.new()
	background_style.bg_color = PANEL_SOFT_FILL_COLOR.darkened(0.2)
	background_style.corner_radius_top_left = 6
	background_style.corner_radius_top_right = 6
	background_style.corner_radius_bottom_right = 6
	background_style.corner_radius_bottom_left = 6
	background_style.content_margin_left = 0
	background_style.content_margin_top = 0
	background_style.content_margin_right = 0
	background_style.content_margin_bottom = 0

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = accent
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_right = 6
	fill_style.corner_radius_bottom_left = 6

	bar.add_theme_stylebox_override("background", background_style)
	bar.add_theme_stylebox_override("fill", fill_style)


static func resolve_status_accent(semantic: String, fallback: Color = PANEL_BORDER_COLOR) -> Color:
	match semantic:
		"health", "danger":
			return RUST_ACCENT_COLOR
		"hunger", "sustain":
			return REWARD_ACCENT_COLOR.darkened(0.12)
		"gold", "wealth", "reward":
			return REWARD_ACCENT_COLOR
		"durability", "equipment", "weapon", "shield", "offhand", "guard":
			return PANEL_BORDER_COLOR
		"xp", "progress", "perk":
			return TEAL_ACCENT_COLOR
		"muted":
			return TEXT_MUTED_COLOR
		_:
			return fallback


static func apply_button(button: Button, accent: Color = PANEL_BORDER_COLOR, is_secondary: bool = false) -> void:
	if button == null:
		return

	var minimum_size: Vector2 = button.custom_minimum_size
	if minimum_size.y < 68.0:
		minimum_size.y = 68.0
		button.custom_minimum_size = minimum_size

	var normal_fill: Color = PANEL_SOFT_FILL_COLOR if is_secondary else PANEL_FILL_COLOR
	normal_fill = normal_fill.lerp(accent.darkened(0.8), 0.12)
	var hover_fill: Color = normal_fill.lightened(0.11)
	var pressed_fill: Color = normal_fill.darkened(0.1)
	var disabled_fill: Color = normal_fill.darkened(0.12)
	disabled_fill.a = 0.72

	button.add_theme_stylebox_override("normal", _build_button_box(normal_fill, accent, 14, 16, 12, 2, 10, 0.24))
	button.add_theme_stylebox_override("hover", _build_button_box(hover_fill, accent.lightened(0.14), 14, 16, 12, 2, 12, 0.28))
	button.add_theme_stylebox_override("pressed", _build_button_box(pressed_fill, accent, 14, 16, 12, 2, 8, 0.2))
	button.add_theme_stylebox_override("disabled", _build_button_box(disabled_fill, accent.darkened(0.2), 14, 16, 12, 2, 8, 0.12))
	button.add_theme_stylebox_override("focus", _build_button_box(hover_fill, accent.lightened(0.2), 14, 16, 12, 2, 12, 0.3))
	button.add_theme_color_override("font_color", TEXT_PRIMARY_COLOR)
	button.add_theme_color_override("font_hover_color", TEXT_PRIMARY_COLOR)
	button.add_theme_color_override("font_pressed_color", TEXT_PRIMARY_COLOR)
	button.add_theme_color_override("font_disabled_color", DISABLED_TEXT_COLOR)
	button.add_theme_constant_override("h_separation", 10)
	button.add_theme_constant_override("icon_max_width", 24)
	button.add_theme_constant_override("outline_size", 0)
	apply_font_role(button, UiTypographyScript.ROLE_BUTTON)
	button.add_theme_font_size_override("font_size", UiTypographyScript.DEFAULT_BUTTON_SIZE)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


static func apply_small_button(button: Button, accent: Color = PANEL_BORDER_COLOR, is_secondary: bool = true) -> void:
	if button == null:
		return

	var minimum_size: Vector2 = button.custom_minimum_size
	if minimum_size.y < 46.0:
		minimum_size.y = 46.0
	if minimum_size.x < 92.0:
		minimum_size.x = 92.0
	button.custom_minimum_size = minimum_size

	var normal_fill: Color = PANEL_SOFT_FILL_COLOR if is_secondary else PANEL_FILL_COLOR
	normal_fill = normal_fill.lerp(accent.darkened(0.82), 0.12)
	var hover_fill: Color = normal_fill.lightened(0.08)
	var pressed_fill: Color = normal_fill.darkened(0.08)
	var disabled_fill: Color = normal_fill.darkened(0.06)
	disabled_fill.a = 0.72

	button.add_theme_stylebox_override("normal", _build_button_box(normal_fill, accent, 12, 12, 8, 2, 8, 0.2))
	button.add_theme_stylebox_override("hover", _build_button_box(hover_fill, accent.lightened(0.12), 12, 12, 8, 2, 9, 0.24))
	button.add_theme_stylebox_override("pressed", _build_button_box(pressed_fill, accent, 12, 12, 8, 2, 7, 0.16))
	button.add_theme_stylebox_override("disabled", _build_button_box(disabled_fill, accent.darkened(0.2), 12, 12, 8, 2, 6, 0.1))
	button.add_theme_stylebox_override("focus", _build_button_box(hover_fill, accent.lightened(0.18), 12, 12, 8, 2, 10, 0.24))
	button.add_theme_color_override("font_color", TEXT_PRIMARY_COLOR)
	button.add_theme_color_override("font_hover_color", TEXT_PRIMARY_COLOR)
	button.add_theme_color_override("font_pressed_color", TEXT_PRIMARY_COLOR)
	button.add_theme_color_override("font_disabled_color", DISABLED_TEXT_COLOR)
	button.add_theme_constant_override("icon_max_width", 18)
	apply_font_role(button, UiTypographyScript.ROLE_BUTTON)
	button.add_theme_font_size_override("font_size", UiTypographyScript.DEFAULT_SMALL_BUTTON_SIZE)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


static func apply_scrim(color_rect: ColorRect) -> void:
	if color_rect == null:
		return
	color_rect.color = BACKDROP_SCRIM_COLOR


static func apply_wayfinder_backdrop(root: Control, far_alpha: float = 0.52, mid_alpha: float = 0.24, overlay_alpha: float = 0.16, overlay_visible: bool = true) -> void:
	if root == null:
		return

	var far_layer: CanvasItem = root.get_node_or_null("BackgroundFar") as CanvasItem
	if far_layer != null:
		far_layer.visible = true
		far_layer.modulate = Color(1, 1, 1, clamp(far_alpha, 0.0, 1.0))

	var mid_layer: CanvasItem = root.get_node_or_null("BackgroundMid") as CanvasItem
	if mid_layer != null:
		mid_layer.visible = true
		mid_layer.modulate = Color(1, 1, 1, clamp(mid_alpha, 0.0, 1.0))

	var overlay_layer: CanvasItem = root.get_node_or_null("BackgroundOverlay") as CanvasItem
	if overlay_layer != null:
		overlay_layer.visible = overlay_visible and overlay_alpha > 0.0
		overlay_layer.modulate = Color(1, 1, 1, clamp(overlay_alpha, 0.0, 1.0))


static func apply_modal_popup_shell(root: Control, margin: MarginContainer, content: Control, accent: Color = PANEL_BORDER_COLOR, shell_name: String = "ContentShell", margin_left: int = 36, margin_top: int = 104, margin_right: int = 36, margin_bottom: int = 104) -> PanelContainer:
	if root == null or margin == null or content == null:
		return null

	apply_wayfinder_backdrop(root, 0.36, 0.18, 0.08, true)

	var scrim: ColorRect = root.get_node_or_null("Scrim") as ColorRect
	if scrim != null:
		scrim.visible = true
		apply_scrim(scrim)
		scrim.color = Color(scrim.color.r, scrim.color.g, scrim.color.b, 0.74)

	margin.add_theme_constant_override("margin_left", margin_left)
	margin.add_theme_constant_override("margin_top", margin_top)
	margin.add_theme_constant_override("margin_right", margin_right)
	margin.add_theme_constant_override("margin_bottom", margin_bottom)

	var shell: PanelContainer = ensure_shell(margin, content, shell_name, 0.0, 0.0, accent)
	if shell != null:
		var shell_style: StyleBoxFlat = shell.get_theme_stylebox("panel") as StyleBoxFlat
		if shell_style != null:
			var popup_style: StyleBoxFlat = shell_style.duplicate() as StyleBoxFlat
			popup_style.bg_color = popup_style.bg_color.lightened(0.02)
			popup_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.2)
			popup_style.shadow_size = 36
			popup_style.border_width_left = 2
			popup_style.border_width_top = 2
			popup_style.border_width_right = 2
			popup_style.border_width_bottom = 2
			popup_style.border_color = accent.lightened(0.12)
			popup_style.content_margin_left = 24
			popup_style.content_margin_top = 22
			popup_style.content_margin_right = 24
			popup_style.content_margin_bottom = 22
			shell.add_theme_stylebox_override("panel", popup_style)
	return shell


static func intensify_panel(panel: PanelContainer, accent: Color, border_width: int = 2, shadow_size: int = 20, fill_boost: float = 0.02, shadow_alpha: float = 0.22, margin_x: int = -1, margin_y: int = -1) -> void:
	if panel == null:
		return

	var existing_style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if existing_style == null:
		return

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
	panel.add_theme_stylebox_override("panel", tuned_style)


static func apply_label(label: Label, tone: String = "body") -> void:
	if label == null:
		return

	var color: Color = TEXT_SUBTLE_COLOR
	var font_size: int = UiTypographyScript.DEFAULT_BODY_SIZE
	match tone:
		"title":
			color = TEXT_PRIMARY_COLOR
			font_size = UiTypographyScript.DEFAULT_TITLE_SIZE
		"accent":
			color = TEXT_MUTED_COLOR
			font_size = UiTypographyScript.DEFAULT_HEADING_SIZE
		"reward":
			color = REWARD_ACCENT_COLOR
			font_size = UiTypographyScript.DEFAULT_HEADING_SIZE
		"danger":
			color = RUST_ACCENT_COLOR
			font_size = UiTypographyScript.DEFAULT_DANGER_SIZE
		"muted":
			color = TEXT_MUTED_COLOR
			font_size = UiTypographyScript.DEFAULT_MUTED_SIZE
		_:
			color = TEXT_SUBTLE_COLOR
			font_size = UiTypographyScript.DEFAULT_BODY_SIZE
	apply_font_role(label, UiTypographyScript.resolve_label_role(tone))
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)


static func apply_font_role(control: Control, role: String = UiTypographyScript.ROLE_BODY) -> void:
	if control == null:
		return
	control.add_theme_font_override("font", UiTypographyScript.resolve_font(role))


static func compute_overlay_margins(viewport_size: Vector2, max_content_width: int = 920, min_side_margin: int = 30) -> Dictionary:
	"""Returns margin values suitable for popup-style overlays that preserve context behind them."""
	var is_portrait: bool = viewport_size.y >= viewport_size.x
	var top_margin: int = 80 if is_portrait else 40
	var bottom_margin: int = 80 if is_portrait else 40
	if viewport_size.y < 1600.0:
		top_margin = 60
		bottom_margin = 60
	if viewport_size.y < 1200.0:
		top_margin = 40
		bottom_margin = 40
	var side_margin: int = min_side_margin
	if viewport_size.x > 0.0:
		var target_width: float = min(float(max_content_width), viewport_size.x - float(min_side_margin * 2))
		side_margin = max(min_side_margin, int(floor((viewport_size.x - target_width) * 0.5)))
	return {
		"left": side_margin,
		"top": top_margin,
		"right": side_margin,
		"bottom": bottom_margin,
	}


static func _build_button_box(fill_color: Color, accent: Color, corner_radius: int = 14, margin_x: int = 14, margin_y: int = 10, border_width: int = 2, shadow_size: int = 10, shadow_alpha: float = 0.22) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
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
