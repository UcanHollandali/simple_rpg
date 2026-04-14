# Layer: UI
extends Control
class_name SafeMenuOverlay

const AudioPreferencesScript = preload("res://Game/UI/audio_preferences.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const CONFIRM_ICON = preload("res://Assets/Icons/icon_confirm.svg")
const CANCEL_ICON = preload("res://Assets/Icons/icon_cancel.svg")
const SETTINGS_ICON = preload("res://Assets/Icons/icon_settings.svg")
const LARGE_LAYOUT_MIN_HEIGHT := 1640.0
const MEDIUM_LAYOUT_MIN_HEIGHT := 1460.0
const OVERLAY_BASE_Z_INDEX := 140
const LAUNCHER_Z_INDEX := 4
const TOAST_Z_INDEX := 3
const MENU_LAYER_Z_INDEX := 10
const LAUNCHER_CORNER_TOP_LEFT := "top_left"
const LAUNCHER_CORNER_TOP_RIGHT := "top_right"
const LAUNCHER_CORNER_BOTTOM_LEFT := "bottom_left"

signal save_requested
signal load_requested

var _title_text: String = "Run Menu"
var _subtitle_text: String = "Save, load, mute music, or quit."
var _launcher_text: String = "Settings"
var _load_available: bool = false
var _status_text: String = ""
var _menu_open: bool = false
var _status_cycle_token: int = 0
var _launcher_corner: String = LAUNCHER_CORNER_TOP_LEFT

var _launcher_button: Button
var _menu_layer: Control
var _menu_panel: PanelContainer
var _title_label: Label
var _subtitle_label: Label
var _save_button: Button
var _load_button: Button
var _display_label: Label
var _resolution_option: OptionButton
var _fullscreen_toggle: CheckButton
var _music_toggle_button: Button
var _quit_button: Button
var _close_button: Button
var _status_label: Label
var _toast_panel: PanelContainer
var _toast_label: Label
var _launcher_alignment_target: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0
	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_BOTH
	z_index = OVERLAY_BASE_Z_INDEX
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_full_rect()
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var resized_handler := Callable(self, "_on_viewport_size_changed")
		if not viewport.is_connected("size_changed", resized_handler):
			viewport.connect("size_changed", resized_handler)
	_build_ui()
	_apply_viewport_layout()
	_refresh()


func configure(title_text: String, subtitle_text: String, launcher_text: String = "Run Menu") -> void:
	_title_text = title_text
	_subtitle_text = subtitle_text
	_launcher_text = launcher_text
	if is_inside_tree():
		_refresh()


func set_load_available(is_available: bool) -> void:
	_load_available = is_available
	if _load_button != null:
		_load_button.disabled = not _load_available


func set_status_text(text: String) -> void:
	_status_text = text
	if _status_label != null:
		_status_label.text = _status_text
		_status_label.visible = not _status_text.is_empty()
	_refresh_status_toast()


func clear_status_text() -> void:
	_status_text = ""
	_status_cycle_token += 1
	if _status_label != null:
		_status_label.text = ""
		_status_label.visible = false
	if _toast_panel != null:
		_toast_panel.visible = false
		_toast_panel.modulate = Color(1, 1, 1, 0)
	if _toast_label != null:
		_toast_label.text = ""


func set_launcher_alignment_target(target: Control) -> void:
	_launcher_alignment_target = target
	if is_inside_tree():
		_apply_viewport_layout()


func set_launcher_corner(corner: String) -> void:
	if corner == LAUNCHER_CORNER_BOTTOM_LEFT:
		_launcher_corner = LAUNCHER_CORNER_BOTTOM_LEFT
	elif corner == LAUNCHER_CORNER_TOP_RIGHT:
		_launcher_corner = LAUNCHER_CORNER_TOP_RIGHT
	else:
		_launcher_corner = LAUNCHER_CORNER_TOP_LEFT
	if is_inside_tree():
		_apply_viewport_layout()


func open_menu() -> void:
	if _menu_layer == null or _menu_panel == null:
		return
	if _menu_open:
		return

	_menu_open = true
	_menu_layer.visible = true
	_menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_layer.modulate = Color(1, 1, 1, 0)
	_menu_panel.scale = Vector2(0.98, 0.98)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_menu_layer, "modulate", Color(1, 1, 1, 1), 0.16)
	tween.parallel().tween_property(_menu_panel, "scale", Vector2.ONE, 0.18)
	if _save_button != null and not _save_button.disabled and _save_button.visible:
		_save_button.grab_focus()
	elif _load_button != null and not _load_button.disabled and _load_button.visible:
		_load_button.grab_focus()
	elif _close_button != null:
		_close_button.grab_focus()


func close_menu() -> void:
	if _menu_layer == null or _menu_panel == null:
		return
	if not _menu_open:
		return

	_menu_open = false
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(_menu_layer, "modulate", Color(1, 1, 1, 0), 0.12)
	tween.parallel().tween_property(_menu_panel, "scale", Vector2(0.98, 0.98), 0.12)
	tween.finished.connect(func() -> void:
		if _menu_layer != null:
			_menu_layer.visible = false
			_menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_menu_panel.scale = Vector2.ONE
		if _launcher_button != null:
			_launcher_button.grab_focus()
	)


func is_menu_open() -> bool:
	return _menu_open


func _build_ui() -> void:
	if _launcher_button != null:
		return

	_launcher_button = Button.new()
	_launcher_button.name = "MenuLauncherButton"
	_launcher_button.anchor_left = 0.0
	_launcher_button.anchor_top = 0.0
	_launcher_button.anchor_right = 0.0
	_launcher_button.anchor_bottom = 0.0
	_launcher_button.offset_left = 12.0
	_launcher_button.offset_top = 10.0
	_launcher_button.offset_right = 54.0
	_launcher_button.offset_bottom = 52.0
	_launcher_button.text = ""
	_launcher_button.tooltip_text = _launcher_text
	_launcher_button.icon = SETTINGS_ICON
	_launcher_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_launcher_button.custom_minimum_size = Vector2(42, 42)
	_set_launcher_button_icon_alignment()
	_launcher_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_launcher_button.z_index = LAUNCHER_Z_INDEX
	_launcher_button.pressed.connect(Callable(self, "_on_launcher_pressed"))
	add_child(_launcher_button)

	_toast_panel = PanelContainer.new()
	_toast_panel.name = "StatusToast"
	_toast_panel.anchor_left = 1.0
	_toast_panel.anchor_top = 0.0
	_toast_panel.anchor_right = 1.0
	_toast_panel.anchor_bottom = 0.0
	_toast_panel.offset_left = -248.0
	_toast_panel.offset_top = 60.0
	_toast_panel.offset_right = -12.0
	_toast_panel.offset_bottom = 106.0
	_toast_panel.visible = false
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.modulate = Color(1, 1, 1, 0)
	_toast_panel.z_index = TOAST_Z_INDEX
	add_child(_toast_panel)

	_toast_label = Label.new()
	_toast_label.name = "StatusToastLabel"
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_panel.add_child(_toast_label)

	_menu_layer = Control.new()
	_menu_layer.name = "MenuLayer"
	_menu_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_menu_layer.anchor_right = 1.0
	_menu_layer.anchor_bottom = 1.0
	_menu_layer.grow_horizontal = GROW_DIRECTION_BOTH
	_menu_layer.grow_vertical = GROW_DIRECTION_BOTH
	_menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_layer.visible = false
	_menu_layer.z_index = MENU_LAYER_Z_INDEX
	add_child(_menu_layer)

	var scrim := ColorRect.new()
	scrim.name = "Backdrop"
	scrim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scrim.anchor_right = 1.0
	scrim.anchor_bottom = 1.0
	scrim.grow_horizontal = GROW_DIRECTION_BOTH
	scrim.grow_vertical = GROW_DIRECTION_BOTH
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TempScreenThemeScript.apply_scrim(scrim)
	scrim.color = Color(scrim.color.r, scrim.color.g, scrim.color.b, 0.2)
	_menu_layer.add_child(scrim)

	var dismiss_button := Button.new()
	dismiss_button.name = "DismissButton"
	dismiss_button.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	dismiss_button.anchor_right = 1.0
	dismiss_button.anchor_bottom = 1.0
	dismiss_button.grow_horizontal = GROW_DIRECTION_BOTH
	dismiss_button.grow_vertical = GROW_DIRECTION_BOTH
	dismiss_button.flat = true
	dismiss_button.focus_mode = Control.FOCUS_NONE
	var transparent_box := StyleBoxEmpty.new()
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		dismiss_button.add_theme_stylebox_override(style_name, transparent_box)
	dismiss_button.pressed.connect(Callable(self, "_on_dismiss_pressed"))
	_menu_layer.add_child(dismiss_button)

	var panel_holder := MarginContainer.new()
	panel_holder.name = "PanelHolder"
	panel_holder.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	panel_holder.anchor_right = 1.0
	panel_holder.anchor_bottom = 1.0
	panel_holder.grow_horizontal = GROW_DIRECTION_BOTH
	panel_holder.grow_vertical = GROW_DIRECTION_BOTH
	panel_holder.add_theme_constant_override("margin_left", 12)
	panel_holder.add_theme_constant_override("margin_top", 54)
	panel_holder.add_theme_constant_override("margin_right", 12)
	panel_holder.add_theme_constant_override("margin_bottom", 12)
	panel_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_layer.add_child(panel_holder)

	var panel_row := HBoxContainer.new()
	panel_row.name = "PanelRow"
	panel_row.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	panel_row.anchor_right = 1.0
	panel_row.anchor_bottom = 1.0
	panel_row.grow_horizontal = GROW_DIRECTION_BOTH
	panel_row.grow_vertical = GROW_DIRECTION_BOTH
	panel_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_holder.add_child(panel_row)

	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_row.add_child(spacer)

	_menu_panel = PanelContainer.new()
	_menu_panel.name = "MenuPanel"
	_menu_panel.custom_minimum_size = Vector2(228, 0)
	_menu_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel_row.add_child(_menu_panel)

	var panel_vbox := VBoxContainer.new()
	panel_vbox.name = "VBox"
	panel_vbox.add_theme_constant_override("separation", 6)
	_menu_panel.add_child(panel_vbox)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	panel_vbox.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "SubtitleLabel"
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vbox.add_child(_subtitle_label)

	var actions_vbox := VBoxContainer.new()
	actions_vbox.name = "ActionsVBox"
	actions_vbox.add_theme_constant_override("separation", 5)
	panel_vbox.add_child(actions_vbox)

	_save_button = Button.new()
	_save_button.name = "SaveRunButton"
	_save_button.text = "Save Progress"
	_save_button.icon = CONFIRM_ICON
	_save_button.custom_minimum_size = Vector2(0, 42)
	_save_button.pressed.connect(func() -> void:
		emit_signal("save_requested")
	)
	actions_vbox.add_child(_save_button)

	_load_button = Button.new()
	_load_button.name = "LoadRunButton"
	_load_button.text = "Load Save"
	_load_button.icon = CONFIRM_ICON
	_load_button.custom_minimum_size = Vector2(0, 42)
	_load_button.pressed.connect(func() -> void:
		emit_signal("load_requested")
	)
	actions_vbox.add_child(_load_button)

	_display_label = Label.new()
	_display_label.name = "DisplayLabel"
	_display_label.text = "Display"
	actions_vbox.add_child(_display_label)

	_resolution_option = OptionButton.new()
	_resolution_option.name = "ResolutionOption"
	_resolution_option.custom_minimum_size = Vector2(0, 42)
	_resolution_option.item_selected.connect(Callable(self, "_on_resolution_option_selected"))
	actions_vbox.add_child(_resolution_option)

	_fullscreen_toggle = CheckButton.new()
	_fullscreen_toggle.name = "FullscreenToggle"
	_fullscreen_toggle.text = "Tam Ekran"
	_fullscreen_toggle.custom_minimum_size = Vector2(0, 42)
	_fullscreen_toggle.toggled.connect(Callable(self, "_on_fullscreen_toggled"))
	actions_vbox.add_child(_fullscreen_toggle)

	_music_toggle_button = Button.new()
	_music_toggle_button.name = "MusicToggleButton"
	_music_toggle_button.custom_minimum_size = Vector2(0, 42)
	_music_toggle_button.pressed.connect(Callable(self, "_on_music_toggle_pressed"))
	actions_vbox.add_child(_music_toggle_button)

	_quit_button = Button.new()
	_quit_button.name = "QuitGameButton"
	_quit_button.text = "Quit Game"
	_quit_button.icon = CANCEL_ICON
	_quit_button.custom_minimum_size = Vector2(0, 42)
	_quit_button.pressed.connect(Callable(self, "_on_quit_pressed"))
	actions_vbox.add_child(_quit_button)

	_close_button = Button.new()
	_close_button.name = "CloseButton"
	_close_button.text = "Close"
	_close_button.icon = CANCEL_ICON
	_close_button.custom_minimum_size = Vector2(0, 42)
	_close_button.pressed.connect(Callable(self, "close_menu"))
	actions_vbox.add_child(_close_button)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vbox.add_child(_status_label)


func _refresh() -> void:
	if _launcher_button == null:
		return

	_launcher_button.text = ""
	_launcher_button.tooltip_text = _launcher_text
	_launcher_button.icon = SETTINGS_ICON
	if _title_label != null:
		_title_label.text = _title_text
	if _subtitle_label != null:
		_subtitle_label.text = _subtitle_text
	if _status_label != null:
		_status_label.text = _status_text
		_status_label.visible = not _status_text.is_empty()
	_refresh_display_controls()
	if _load_button != null:
		_load_button.disabled = not _load_available
	if _music_toggle_button != null:
		_music_toggle_button.text = "Music: %s" % ("On" if AudioPreferencesScript.is_music_enabled() else "Off")

	_apply_launcher_button_style()
	TempScreenThemeScript.apply_panel(_menu_panel, TempScreenThemeScript.PANEL_BORDER_COLOR, 16, 0.98)
	TempScreenThemeScript.apply_label(_title_label, "accent")
	TempScreenThemeScript.apply_label(_subtitle_label, "muted")
	TempScreenThemeScript.apply_small_button(_save_button, TempScreenThemeScript.PANEL_BORDER_COLOR, false)
	TempScreenThemeScript.apply_small_button(_load_button, TempScreenThemeScript.TEAL_ACCENT_COLOR, true)
	TempScreenThemeScript.apply_label(_display_label, "muted")
	TempScreenThemeScript.apply_small_button(_resolution_option, TempScreenThemeScript.PANEL_BORDER_COLOR, true)
	TempScreenThemeScript.apply_small_button(
		_fullscreen_toggle,
		TempScreenThemeScript.TEAL_ACCENT_COLOR if _fullscreen_toggle != null and _fullscreen_toggle.button_pressed else TempScreenThemeScript.PANEL_BORDER_COLOR,
		true
	)
	if _fullscreen_toggle != null:
		_fullscreen_toggle.visible = false
	if _display_label != null:
		_display_label.visible = false
	if _resolution_option != null:
		_resolution_option.visible = false
	TempScreenThemeScript.apply_small_button(
		_music_toggle_button,
		TempScreenThemeScript.TEAL_ACCENT_COLOR if AudioPreferencesScript.is_music_enabled() else TempScreenThemeScript.RUST_ACCENT_COLOR,
		true
	)
	TempScreenThemeScript.apply_small_button(_quit_button, TempScreenThemeScript.RUST_ACCENT_COLOR, true)
	TempScreenThemeScript.apply_small_button(_close_button, TempScreenThemeScript.PANEL_BORDER_COLOR, true)
	TempScreenThemeScript.apply_label(_status_label, "muted")
	if _toast_panel != null:
		var toast_accent: Color = TempScreenThemeScript.RUST_ACCENT_COLOR if _status_text.to_lower().contains("fail") else TempScreenThemeScript.TEAL_ACCENT_COLOR
		TempScreenThemeScript.apply_panel(_toast_panel, toast_accent, 14, 0.96)
	if _toast_label != null:
		TempScreenThemeScript.apply_label(_toast_label, "muted")
	_apply_viewport_layout()


func _on_launcher_pressed() -> void:
	if _menu_open:
		close_menu()
		return
	open_menu()


func _on_dismiss_pressed() -> void:
	close_menu()


func _on_music_toggle_pressed() -> void:
	var is_enabled: bool = AudioPreferencesScript.toggle_music_enabled()
	set_status_text("Music %s." % ("enabled" if is_enabled else "muted"))
	_refresh()


func _on_resolution_option_selected(index: int) -> void:
	var bootstrap = _get_bootstrap()
	if bootstrap == null:
		return
	var result: Dictionary = bootstrap.apply_resolution_by_index(index)
	set_status_text(_build_resolution_status_text(result))
	_refresh_display_controls()


func _on_fullscreen_toggled(toggled: bool) -> void:
	var bootstrap = _get_bootstrap()
	if bootstrap == null:
		return
	var result: Dictionary = bootstrap.apply_fullscreen_mode(toggled)
	set_status_text(_build_fullscreen_status_text(result))
	_refresh_display_controls()


func _on_quit_pressed() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	tree.quit()


func _unhandled_input(event: InputEvent) -> void:
	if event == null:
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	if not _menu_open:
		return
	close_menu()
	get_viewport().set_input_as_handled()


func _on_viewport_size_changed() -> void:
	_sync_full_rect()
	_apply_viewport_layout()


func _sync_full_rect() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)


func _apply_launcher_button_style() -> void:
	if _launcher_button == null:
		return

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
	box.content_margin_left = 6
	box.content_margin_top = 6
	box.content_margin_right = 6
	box.content_margin_bottom = 6
	box.shadow_color = Color(0, 0, 0, 0.24)
	box.shadow_size = 8

	var hover_box: StyleBoxFlat = box.duplicate() as StyleBoxFlat
	hover_box.bg_color = hover_box.bg_color.lightened(0.05)
	hover_box.border_color = TempScreenThemeScript.PANEL_BORDER_COLOR.lightened(0.08)

	for style_name in ["normal", "pressed", "focus", "disabled"]:
		_launcher_button.add_theme_stylebox_override(style_name, box)
	_launcher_button.add_theme_stylebox_override("hover", hover_box)
	_launcher_button.add_theme_constant_override("h_separation", 0)
	_launcher_button.add_theme_constant_override("icon_max_width", 24)
	_set_launcher_button_icon_alignment()
	_launcher_button.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	_launcher_button.add_theme_color_override("font_hover_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	_launcher_button.add_theme_color_override("font_pressed_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	_launcher_button.add_theme_color_override("font_disabled_color", TempScreenThemeScript.DISABLED_TEXT_COLOR)
	_launcher_button.add_theme_font_size_override("font_size", 1)
	_launcher_button.focus_mode = Control.FOCUS_ALL
	_launcher_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _apply_viewport_layout() -> void:
	if _launcher_button == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var large_layout: bool = viewport_size.y >= LARGE_LAYOUT_MIN_HEIGHT and viewport_size.x >= 900.0
	var medium_layout: bool = not large_layout and viewport_size.y >= MEDIUM_LAYOUT_MIN_HEIGHT and viewport_size.x >= 760.0

	var launcher_size: float = 58.0 if large_layout else 52.0 if medium_layout else 44.0
	var launcher_inset: float = 18.0 if large_layout else 16.0 if medium_layout else 12.0
	var launcher_top: float = 18.0 if large_layout else 14.0 if medium_layout else 10.0
	var launcher_left: float = _resolve_launcher_left_edge(viewport_size.x, launcher_inset)
	var is_top_right: bool = _launcher_corner == LAUNCHER_CORNER_TOP_RIGHT
	if is_top_right:
		launcher_left = _resolve_launcher_right_edge(viewport_size.x, launcher_inset, launcher_size)
	if _launcher_corner == LAUNCHER_CORNER_BOTTOM_LEFT:
		launcher_top = viewport_size.y - launcher_size - launcher_inset
	_launcher_button.offset_top = launcher_top
	_launcher_button.offset_left = launcher_left
	_launcher_button.offset_right = launcher_left + launcher_size
	_launcher_button.offset_bottom = launcher_top + launcher_size
	_launcher_button.custom_minimum_size = Vector2(launcher_size, launcher_size)
	var launcher_icon_size: int = int(round(launcher_size * 0.62))
	launcher_icon_size = clamp(launcher_icon_size, 24, int(launcher_size) - 10)
	_launcher_button.add_theme_constant_override("icon_max_width", launcher_icon_size)
	_set_launcher_button_icon_alignment()

	if _toast_panel != null:
		var toast_width: float = 328.0 if large_layout else 292.0 if medium_layout else 236.0
		var toast_height: float = 60.0 if large_layout else 54.0 if medium_layout else 46.0
		var toast_top: float = launcher_top + launcher_size + 12.0
		if _launcher_corner == LAUNCHER_CORNER_BOTTOM_LEFT:
			toast_top = launcher_top - toast_height - 12.0
		_toast_panel.offset_left = launcher_left
		_toast_panel.offset_top = toast_top
		_toast_panel.offset_right = launcher_left + toast_width
		_toast_panel.offset_bottom = toast_top + toast_height

	var panel_holder: MarginContainer = _menu_layer.get_node_or_null("PanelHolder") as MarginContainer
	if panel_holder != null:
		panel_holder.add_theme_constant_override("margin_left", 18 if large_layout else 16 if medium_layout else 12)
		panel_holder.add_theme_constant_override("margin_top", 84 if large_layout else 72 if medium_layout else 54)
		panel_holder.add_theme_constant_override("margin_right", 18 if large_layout else 16 if medium_layout else 12)
		panel_holder.add_theme_constant_override("margin_bottom", 18 if large_layout else 16 if medium_layout else 12)

	if _menu_panel != null:
		_menu_panel.custom_minimum_size = Vector2(332.0 if large_layout else 300.0 if medium_layout else 244.0, 0.0)

	var panel_vbox: VBoxContainer = _menu_panel.get_node_or_null("VBox") as VBoxContainer
	if panel_vbox != null:
		panel_vbox.add_theme_constant_override("separation", 10 if large_layout else 8 if medium_layout else 6)
	var actions_vbox: VBoxContainer = _menu_panel.get_node_or_null("VBox/ActionsVBox") as VBoxContainer
	if actions_vbox != null:
		actions_vbox.add_theme_constant_override("separation", 8 if large_layout else 7 if medium_layout else 5)

	var button_height: float = 54.0 if large_layout else 50.0 if medium_layout else 42.0
	for button in [_save_button, _load_button, _resolution_option, _fullscreen_toggle, _music_toggle_button, _quit_button, _close_button]:
		if button != null:
			button.custom_minimum_size = Vector2(0.0, button_height)
			button.add_theme_font_size_override("font_size", 18 if large_layout else 17 if medium_layout else 15)
			button.add_theme_constant_override("icon_max_width", 22 if large_layout else 20 if medium_layout else 18)

	if _toast_label != null:
		_toast_label.add_theme_font_size_override("font_size", 16 if large_layout else 15 if medium_layout else 14)
	if _title_label != null:
		_title_label.add_theme_font_size_override("font_size", 22 if large_layout else 20 if medium_layout else 18)
	if _subtitle_label != null:
		_subtitle_label.add_theme_font_size_override("font_size", 15 if large_layout else 14 if medium_layout else 12)
	if _display_label != null:
		_display_label.add_theme_font_size_override("font_size", 14 if large_layout else 13 if medium_layout else 12)
	if _status_label != null:
		_status_label.add_theme_font_size_override("font_size", 15 if large_layout else 14 if medium_layout else 12)


func _resolve_launcher_left_edge(_viewport_width: float, launcher_inset: float) -> float:
	if _launcher_alignment_target != null and is_instance_valid(_launcher_alignment_target):
		var target_rect: Rect2 = _launcher_alignment_target.get_global_rect()
		if target_rect.size.x > 0.0:
			return target_rect.position.x + launcher_inset
	return launcher_inset


func _resolve_launcher_right_edge(_viewport_width: float, launcher_inset: float, launcher_size: float) -> float:
	if _launcher_alignment_target != null and is_instance_valid(_launcher_alignment_target):
		var target_rect: Rect2 = _launcher_alignment_target.get_global_rect()
		if target_rect.size.x > 0.0:
			var target_width: float = max(0.0, target_rect.size.x)
			var effective_launcher_size: float = clamp(launcher_size, 34.0, max(34.0, target_width - (launcher_inset * 2.0)))
			var aligned_left: float = target_rect.position.x + target_width - launcher_inset - effective_launcher_size
			return clamp(aligned_left, launcher_inset, max(launcher_inset, _viewport_width - launcher_inset - effective_launcher_size))
	var fallback_x: float = _viewport_width - launcher_inset - launcher_size
	return clamp(fallback_x, launcher_inset, max(launcher_inset, _viewport_width - launcher_inset - launcher_size))


func _set_launcher_button_icon_alignment() -> void:
	if _launcher_button == null:
		return
	for property_meta in _launcher_button.get_property_list():
		if String(property_meta.get("name", "")) == "icon_alignment":
			_launcher_button.set("icon_alignment", HORIZONTAL_ALIGNMENT_CENTER)
			return


func _refresh_status_toast() -> void:
	if _toast_panel == null or _toast_label == null:
		return
	if _status_text.is_empty():
		_toast_label.text = ""
		_toast_panel.visible = false
		_toast_panel.modulate = Color(1, 1, 1, 0)
		return

	_status_cycle_token += 1
	var local_token: int = _status_cycle_token
	_toast_label.text = _status_text
	_refresh()
	_toast_panel.visible = true
	_toast_panel.modulate = Color(1, 1, 1, 0)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_toast_panel, "modulate", Color(1, 1, 1, 1), 0.12)
	tween.finished.connect(func() -> void:
		if local_token != _status_cycle_token or not is_inside_tree():
			return
		_schedule_status_toast_hide(local_token)
	)


func _schedule_status_toast_hide(local_token: int) -> void:
	await get_tree().create_timer(2.0).timeout
	if local_token != _status_cycle_token or not is_inside_tree():
		return
	var fade_tween: Tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_IN)
	fade_tween.tween_property(_toast_panel, "modulate", Color(1, 1, 1, 0), 0.18)
	fade_tween.finished.connect(func() -> void:
		if local_token != _status_cycle_token or _toast_panel == null:
			return
		_toast_panel.visible = false
		_toast_label.text = ""
		_status_text = ""
		if _status_label != null:
			_status_label.text = ""
			_status_label.visible = false
	)


func _refresh_display_controls() -> void:
	var bootstrap = _get_bootstrap()
	if _resolution_option != null:
		_resolution_option.clear()
	if bootstrap == null:
		if _resolution_option != null:
			_resolution_option.disabled = true
			_resolution_option.visible = false
		if _fullscreen_toggle != null:
			_fullscreen_toggle.disabled = true
			_fullscreen_toggle.visible = false
			_fullscreen_toggle.set_pressed_no_signal(false)
		if _display_label != null:
			_display_label.visible = false
		return

	var options: Array[String] = bootstrap.get_supported_resolution_options()
	if _resolution_option != null:
		for option_index in range(options.size()):
			_resolution_option.add_item(options[option_index], option_index)
		_resolution_option.disabled = options.is_empty()
		if not options.is_empty():
			var selected_index: int = clamp(int(bootstrap.get_active_resolution_index()), 0, options.size() - 1)
			_resolution_option.select(selected_index)
	if _fullscreen_toggle != null:
		_fullscreen_toggle.disabled = false
		_fullscreen_toggle.visible = false
		_fullscreen_toggle.text = "Tam Ekran"
		_fullscreen_toggle.set_pressed_no_signal(bool(bootstrap.is_fullscreen_enabled()))
	if _display_label != null:
		_display_label.visible = false
	if _resolution_option != null:
		_resolution_option.visible = false


func _get_bootstrap():
	return get_node_or_null("/root/AppBootstrap")


func _active_resolution_label() -> String:
	var bootstrap = _get_bootstrap()
	if bootstrap == null:
		return "Resolution"
	var options: Array[String] = bootstrap.get_supported_resolution_options()
	if options.is_empty():
		return "Resolution"
	var selected_index: int = clamp(int(bootstrap.get_active_resolution_index()), 0, options.size() - 1)
	return options[selected_index]


func _build_resolution_status_text(result: Dictionary) -> String:
	if not bool(result.get("ok", false)):
		return "Resolution change failed: %s" % String(result.get("error", "unknown"))
	var resolution_label: String = _active_resolution_label()
	if bool(result.get("deferred_until_windowed", false)):
		return "%s saved. It will apply after leaving fullscreen." % resolution_label
	var window_size: Vector2i = result.get("window_size", Vector2i.ZERO) as Vector2i
	if window_size.x > 0 and window_size.y > 0:
		return "%s applied at %dx%d." % [resolution_label, window_size.x, window_size.y]
	return "%s applied." % resolution_label


func _build_fullscreen_status_text(result: Dictionary) -> String:
	if not bool(result.get("ok", false)):
		return "Display mode change failed: %s" % String(result.get("error", "unknown"))
	return "Fullscreen enabled." if bool(result.get("fullscreen", false)) else "Windowed mode restored."
