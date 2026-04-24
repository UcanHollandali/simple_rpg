# Layer: UI
extends Control
class_name SafeMenuOverlay

const AudioPreferencesScript = preload("res://Game/UI/audio_preferences.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const SafeMenuLauncherStyleScript = preload("res://Game/UI/safe_menu_launcher_style.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const CONFIRM_ICON = preload("res://Assets/Icons/icon_confirm.svg")
const CANCEL_ICON = preload("res://Assets/Icons/icon_cancel.svg")
const SETTINGS_ICON = preload("res://Assets/Icons/icon_settings.svg")
const OVERLAY_BASE_Z_INDEX := 140
const LAUNCHER_Z_INDEX := 4
const TOAST_Z_INDEX := 3
const MENU_LAYER_Z_INDEX := 10
const LAUNCHER_CORNER_TOP_RIGHT := "top_right"
const LAUNCHER_CORNER_TOP_LEFT := "top_left"
const LAUNCHER_CORNER_BOTTOM_LEFT := "bottom_left"

signal save_requested
signal load_requested
signal return_to_main_menu_requested
signal disable_tutorial_hints_requested

var _title_text: String = "Settings"
var _subtitle_text: String = "Save, load, return to menu, mute music, or quit."
var _launcher_text: String = "Settings"
var _load_available: bool = false
var _tutorial_hints_available: bool = false
var _status_text: String = ""
var _menu_open: bool = false
var _status_cycle_token: int = 0
var _launcher_corner: String = LAUNCHER_CORNER_TOP_RIGHT
var _launcher_enabled: bool = true
var _main_menu_enabled: bool = true

var _launcher_button: Button
var _menu_layer: Control
var _menu_panel: PanelContainer
var _title_label: Label
var _subtitle_label: Label
var _save_button: Button
var _load_button: Button
var _tutorial_hints_button: Button
var _main_menu_button: Button
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

func configure(title_text: String, subtitle_text: String, launcher_text: String = "Settings") -> void:
	_title_text = title_text
	_subtitle_text = subtitle_text
	_launcher_text = launcher_text
	if is_inside_tree():
		_refresh()

func set_load_available(is_available: bool) -> void:
	_load_available = is_available
	if _load_button != null: _load_button.disabled = not _load_available
func set_tutorial_hints_available(is_available: bool) -> void:
	_tutorial_hints_available = is_available
	if _tutorial_hints_button != null: _tutorial_hints_button.visible = _tutorial_hints_available
func set_status_text(text: String) -> void:
	_status_text = text
	_sync_status_label()
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
	if is_inside_tree(): _apply_viewport_layout()
func set_launcher_corner(corner: String) -> void:
	_launcher_corner = LAUNCHER_CORNER_TOP_LEFT
	if corner == LAUNCHER_CORNER_BOTTOM_LEFT:
		_launcher_corner = LAUNCHER_CORNER_BOTTOM_LEFT
	elif corner == LAUNCHER_CORNER_TOP_RIGHT:
		_launcher_corner = LAUNCHER_CORNER_TOP_RIGHT
	if is_inside_tree(): _apply_viewport_layout()
func set_launcher_enabled(is_enabled: bool) -> void:
	_launcher_enabled = is_enabled
	if is_inside_tree(): _apply_launcher_interactivity()
	if not _launcher_enabled and _menu_open: close_menu()
func set_main_menu_enabled(is_enabled: bool) -> void:
	_main_menu_enabled = is_enabled
	if is_inside_tree(): _refresh()
func open_menu() -> void:
	if _menu_layer == null or _menu_panel == null or _menu_open:
		return
	_menu_open = true
	_sync_status_label()
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
	elif _main_menu_button != null and _main_menu_button.visible:
		_main_menu_button.grab_focus()
	elif _close_button != null:
		_close_button.grab_focus()
func close_menu() -> void:
	if _menu_layer == null or _menu_panel == null or not _menu_open:
		return
	_menu_open = false
	_sync_status_label()
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(_menu_layer, "modulate", Color(1, 1, 1, 0), 0.12)
	tween.parallel().tween_property(_menu_panel, "scale", Vector2(0.98, 0.98), 0.12)
	tween.finished.connect(Callable(self, "_finish_menu_close"), CONNECT_ONE_SHOT)
func is_menu_open() -> bool: return _menu_open


func _close_menu_immediately() -> void:
	if _menu_layer == null or _menu_panel == null or not _menu_open:
		return
	_menu_open = false
	_sync_status_label()
	_menu_layer.modulate = Color(1, 1, 1, 0)
	_finish_menu_close()
func _build_ui() -> void:
	if _launcher_button != null: return
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
	_launcher_button.custom_minimum_size = Vector2(62, 70)
	_set_launcher_button_expand_mode()
	_set_launcher_button_icon_alignment()
	_launcher_button.z_index = LAUNCHER_Z_INDEX
	_launcher_button.pressed.connect(Callable(self, "_on_launcher_pressed"))
	add_child(_launcher_button)
	_apply_launcher_interactivity()

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

	_save_button = _build_menu_button("SaveRunButton", "Save Progress", CONFIRM_ICON, "_emit_save_requested")
	actions_vbox.add_child(_save_button)

	_load_button = _build_menu_button("LoadRunButton", "Load Save", CONFIRM_ICON, "_emit_load_requested")
	actions_vbox.add_child(_load_button)

	_tutorial_hints_button = _build_menu_button("DisableTutorialHintsButton", "Disable Tutorial Hints", CANCEL_ICON, "_emit_disable_tutorial_hints_requested")
	actions_vbox.add_child(_tutorial_hints_button)

	_main_menu_button = _build_menu_button("ReturnToMainMenuButton", "Return to Main Menu", CONFIRM_ICON, "_emit_return_to_main_menu_requested")
	actions_vbox.add_child(_main_menu_button)

	_music_toggle_button = _build_menu_button("MusicToggleButton", "", null, "_on_music_toggle_pressed")
	actions_vbox.add_child(_music_toggle_button)

	_quit_button = _build_menu_button("QuitGameButton", "Quit Game", CANCEL_ICON, "_on_quit_pressed")
	actions_vbox.add_child(_quit_button)

	_close_button = _build_menu_button("CloseButton", "Close", CANCEL_ICON, "close_menu")
	actions_vbox.add_child(_close_button)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vbox.add_child(_status_label)
func _refresh() -> void:
	if _launcher_button == null: return
	_launcher_button.text = ""
	_launcher_button.tooltip_text = _launcher_text
	_launcher_button.icon = SETTINGS_ICON
	if _title_label != null:
		_title_label.text = _title_text
	if _subtitle_label != null:
		_subtitle_label.text = _subtitle_text
	_sync_status_label()
	if _load_button != null:
		_load_button.disabled = not _load_available
	if _tutorial_hints_button != null:
		_tutorial_hints_button.visible = _tutorial_hints_available
	if _main_menu_button != null:
		_main_menu_button.visible = true
		_main_menu_button.disabled = not _main_menu_enabled
		_main_menu_button.tooltip_text = "" if _main_menu_enabled else "Unavailable during combat."
	if _music_toggle_button != null:
		_music_toggle_button.text = "Music: %s" % ("On" if AudioPreferencesScript.is_music_enabled() else "Off")

	_apply_launcher_button_style()
	TempScreenThemeScript.apply_panel(_menu_panel, TempScreenThemeScript.PANEL_BORDER_COLOR, 16, 0.98)
	TempScreenThemeScript.apply_label(_title_label, "accent")
	TempScreenThemeScript.apply_label(_subtitle_label, "muted")
	TempScreenThemeScript.apply_small_button(_save_button, TempScreenThemeScript.PANEL_BORDER_COLOR, false)
	TempScreenThemeScript.apply_small_button(_load_button, TempScreenThemeScript.TEAL_ACCENT_COLOR, true)
	TempScreenThemeScript.apply_small_button(_tutorial_hints_button, TempScreenThemeScript.PANEL_BORDER_COLOR, true)
	TempScreenThemeScript.apply_small_button(_main_menu_button, TempScreenThemeScript.REWARD_ACCENT_COLOR, true)
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
	_apply_launcher_interactivity()
func _on_launcher_pressed() -> void:
	if _menu_open:
		close_menu(); return
	open_menu()
func _on_dismiss_pressed() -> void:
	close_menu()
func _on_music_toggle_pressed() -> void:
	var is_enabled: bool = AudioPreferencesScript.toggle_music_enabled()
	set_status_text("Music %s." % ("enabled" if is_enabled else "muted"))
	_refresh()


func _on_quit_pressed() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var root_window: Window = tree.root
	if root_window != null:
		SceneAudioCleanupScript.release_all_audio_players(root_window)
	await tree.process_frame
	await tree.process_frame
	await tree.create_timer(0.05).timeout
	tree.quit()


func _emit_save_requested() -> void: emit_signal("save_requested")
func _emit_load_requested() -> void: emit_signal("load_requested")
func _emit_disable_tutorial_hints_requested() -> void:
	_close_menu_immediately()
	emit_signal("disable_tutorial_hints_requested")


func _emit_return_to_main_menu_requested() -> void:
	if not _main_menu_enabled:
		return
	close_menu()
	emit_signal("return_to_main_menu_requested")


func _finish_menu_close() -> void:
	if _menu_layer != null:
		_menu_layer.visible = false
		_menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_menu_panel.scale = Vector2.ONE
	if _launcher_button != null and _launcher_enabled and _launcher_button.visible:
		_launcher_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event == null or not event.is_action_pressed("ui_cancel") or not _menu_open:
		return
	close_menu()
	get_viewport().set_input_as_handled()


func _on_viewport_size_changed() -> void:
	_sync_full_rect(); _apply_viewport_layout()


func _sync_full_rect() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT); anchor_right = 1.0; anchor_bottom = 1.0; offset_left = 0.0; offset_top = 0.0; offset_right = 0.0; offset_bottom = 0.0; grow_horizontal = GROW_DIRECTION_BOTH; grow_vertical = GROW_DIRECTION_BOTH


func _apply_launcher_button_style() -> void:
	if _launcher_button == null: return
	var launcher_metrics: Dictionary = SafeMenuLauncherStyleScript.resolve_launcher_metrics_for_viewport(get_viewport_rect().size)
	SafeMenuLauncherStyleScript.apply_shared_launcher_button_style(
		_launcher_button,
		_launcher_text,
		Vector2(launcher_metrics.get("dimensions", Vector2(62.0, 70.0))),
		int(launcher_metrics.get("icon_size", 28))
	)
	_apply_launcher_interactivity()


func _apply_viewport_layout() -> void:
	if _launcher_button == null: return
	var viewport_size: Vector2 = get_viewport_rect().size
	var launcher_metrics: Dictionary = SafeMenuLauncherStyleScript.resolve_launcher_metrics_for_viewport(viewport_size)
	var large_layout: bool = bool(launcher_metrics.get("large_layout", false))
	var medium_layout: bool = bool(launcher_metrics.get("medium_layout", false))
	var launcher_dimensions: Vector2 = Vector2(launcher_metrics.get("dimensions", Vector2(62.0, 70.0)))
	var launcher_inset: float = float(launcher_metrics.get("inset", 12.0))
	var launcher_top: float = float(launcher_metrics.get("top", 10.0))
	SafeMenuLauncherStyleScript.apply_shared_launcher_button_style(
		_launcher_button,
		_launcher_text,
		launcher_dimensions,
		int(launcher_metrics.get("icon_size", 28))
	)
	if _launcher_alignment_target != null and is_instance_valid(_launcher_alignment_target) and _launcher_corner != LAUNCHER_CORNER_BOTTOM_LEFT:
		var target_rect: Rect2 = _launcher_alignment_target.get_global_rect()
		if target_rect.size.y > 0.0:
			launcher_top = target_rect.position.y + max(0.0, (target_rect.size.y - launcher_dimensions.y) * 0.5)
	var launcher_left: float = _resolve_launcher_left_edge(viewport_size.x, launcher_inset)
	var is_top_right: bool = _launcher_corner == LAUNCHER_CORNER_TOP_RIGHT
	if is_top_right:
		launcher_left = _resolve_launcher_right_edge(viewport_size.x, launcher_inset, launcher_dimensions.x)
	if _launcher_corner == LAUNCHER_CORNER_BOTTOM_LEFT:
		launcher_top = viewport_size.y - launcher_dimensions.y - launcher_inset
	_launcher_button.global_position = Vector2(launcher_left, launcher_top)
	_launcher_button.size = launcher_dimensions
	_launcher_button.custom_minimum_size = launcher_dimensions

	if _toast_panel != null:
		var toast_width: float = 328.0 if large_layout else 292.0 if medium_layout else 236.0
		var toast_height: float = 60.0 if large_layout else 54.0 if medium_layout else 46.0
		var toast_top: float = launcher_top + launcher_dimensions.y + 12.0
		if _launcher_corner == LAUNCHER_CORNER_BOTTOM_LEFT:
			toast_top = launcher_top - toast_height - 12.0
		var toast_left: float = _resolve_toast_left_edge(
			viewport_size.x,
			launcher_left,
			launcher_dimensions.x,
			toast_width,
			launcher_inset
		)
		toast_top = clamp(
			toast_top,
			launcher_inset,
			max(launcher_inset, viewport_size.y - toast_height - launcher_inset)
		)
		_toast_panel.global_position = Vector2(toast_left, toast_top)
		_toast_panel.size = Vector2(toast_width, toast_height)

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
	for button in [_save_button, _load_button, _tutorial_hints_button, _main_menu_button, _music_toggle_button, _quit_button, _close_button]:
		if button != null:
			button.custom_minimum_size = Vector2(0.0, button_height)
			button.add_theme_font_size_override("font_size", 17 if large_layout else 16 if medium_layout else 15)
			button.add_theme_constant_override("icon_max_width", 22 if large_layout else 20 if medium_layout else 18)

	if _toast_label != null:
		_toast_label.add_theme_font_size_override("font_size", 14 if large_layout else 13 if medium_layout else 12)
	if _title_label != null:
		_title_label.add_theme_font_size_override("font_size", 20 if large_layout else 18 if medium_layout else 16)
	if _subtitle_label != null:
		_subtitle_label.add_theme_font_size_override("font_size", 14 if large_layout else 13 if medium_layout else 12)
	if _status_label != null:
		_status_label.add_theme_font_size_override("font_size", 14 if large_layout else 13 if medium_layout else 12)


func _apply_launcher_interactivity() -> void:
	if _launcher_button == null: return
	_launcher_button.visible = _launcher_enabled
	_launcher_button.focus_mode = Control.FOCUS_ALL if _launcher_enabled else Control.FOCUS_NONE
	_launcher_button.mouse_filter = Control.MOUSE_FILTER_STOP if _launcher_enabled else Control.MOUSE_FILTER_IGNORE
	_launcher_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _launcher_enabled else Control.CURSOR_ARROW


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
			var target_width: float = max(34.0, target_rect.size.x)
			var effective_launcher_size: float = clamp(launcher_size, 34.0, target_width)
			var aligned_left: float = target_rect.position.x + target_width - effective_launcher_size
			return clamp(aligned_left, launcher_inset, max(launcher_inset, _viewport_width - launcher_inset - effective_launcher_size))
	var fallback_x: float = _viewport_width - launcher_inset - launcher_size
	return clamp(fallback_x, launcher_inset, max(launcher_inset, _viewport_width - launcher_inset - launcher_size))


func _resolve_toast_left_edge(
	viewport_width: float,
	launcher_left: float,
	launcher_width: float,
	toast_width: float,
	launcher_inset: float
) -> float:
	var preferred_left: float = launcher_left
	if _launcher_corner == LAUNCHER_CORNER_TOP_RIGHT:
		preferred_left = launcher_left + launcher_width - toast_width
	return clamp(
		preferred_left,
		launcher_inset,
		max(launcher_inset, viewport_width - toast_width - launcher_inset)
	)


func _set_launcher_button_icon_alignment() -> void:
	if _launcher_button == null: return
	for property_meta in _launcher_button.get_property_list():
		if String(property_meta.get("name", "")) == "icon_alignment":
			_launcher_button.set("icon_alignment", HORIZONTAL_ALIGNMENT_CENTER); return


func _set_launcher_button_expand_mode() -> void:
	if _launcher_button == null: return
	for property_meta in _launcher_button.get_property_list():
		if String(property_meta.get("name", "")) == "expand_icon":
			_launcher_button.set("expand_icon", false); return


func _build_menu_button(name: String, text: String, icon: Texture2D, handler_name: String) -> Button:
	var button := Button.new()
	button.name = name
	button.text = text
	button.icon = icon
	button.custom_minimum_size = Vector2(0, 42)
	button.pressed.connect(Callable(self, handler_name))
	return button


func _refresh_status_toast() -> void:
	if _toast_panel == null or _toast_label == null: return
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
	tween.finished.connect(Callable(self, "_on_status_toast_fade_in_finished").bind(local_token), CONNECT_ONE_SHOT)


func _schedule_status_toast_hide(local_token: int) -> void:
	await get_tree().create_timer(2.0).timeout
	if local_token != _status_cycle_token or not is_inside_tree(): return
	var fade_tween: Tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_IN)
	fade_tween.tween_property(_toast_panel, "modulate", Color(1, 1, 1, 0), 0.18)
	fade_tween.finished.connect(Callable(self, "_on_status_toast_fade_out_finished").bind(local_token), CONNECT_ONE_SHOT)


func _on_status_toast_fade_in_finished(local_token: int) -> void:
	if local_token != _status_cycle_token or not is_inside_tree(): return
	_schedule_status_toast_hide(local_token)


func _on_status_toast_fade_out_finished(local_token: int) -> void:
	if local_token != _status_cycle_token or _toast_panel == null: return
	_toast_panel.visible = false
	_toast_label.text = ""
	_status_text = ""
	_sync_status_label()


func _sync_status_label() -> void:
	if _status_label == null:
		return
	_status_label.text = _status_text
	_status_label.visible = _menu_open and not _status_text.is_empty()
