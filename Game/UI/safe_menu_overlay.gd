# Layer: UI
extends Control
class_name SafeMenuOverlay

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const CONFIRM_ICON = preload("res://Assets/Icons/icon_confirm.svg")
const CANCEL_ICON = preload("res://Assets/Icons/icon_cancel.svg")

signal save_requested
signal load_requested

var _title_text: String = "Run Tools"
var _subtitle_text: String = "Save or load from safe screens."
var _launcher_text: String = "Tools"
var _load_available: bool = false
var _status_text: String = ""
var _menu_open: bool = false

var _launcher_button: Button
var _menu_layer: Control
var _menu_panel: PanelContainer
var _title_label: Label
var _subtitle_label: Label
var _save_button: Button
var _load_button: Button
var _close_button: Button
var _status_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0
	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_full_rect()
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var resized_handler := Callable(self, "_on_viewport_size_changed")
		if not viewport.is_connected("size_changed", resized_handler):
			viewport.connect("size_changed", resized_handler)
	_build_ui()
	_refresh()


func configure(title_text: String, subtitle_text: String, launcher_text: String = "Tools") -> void:
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


func clear_status_text() -> void:
	set_status_text("")


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
	_launcher_button.anchor_left = 1.0
	_launcher_button.anchor_top = 0.0
	_launcher_button.anchor_right = 1.0
	_launcher_button.anchor_bottom = 0.0
	_launcher_button.offset_left = -106.0
	_launcher_button.offset_top = 12.0
	_launcher_button.offset_right = -12.0
	_launcher_button.offset_bottom = 44.0
	_launcher_button.text = _launcher_text
	_launcher_button.custom_minimum_size = Vector2(82, 32)
	_launcher_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_launcher_button.pressed.connect(Callable(self, "_on_launcher_pressed"))
	add_child(_launcher_button)

	_menu_layer = Control.new()
	_menu_layer.name = "MenuLayer"
	_menu_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_menu_layer.anchor_right = 1.0
	_menu_layer.anchor_bottom = 1.0
	_menu_layer.grow_horizontal = GROW_DIRECTION_BOTH
	_menu_layer.grow_vertical = GROW_DIRECTION_BOTH
	_menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_layer.visible = false
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
	panel_holder.add_theme_constant_override("margin_left", 16)
	panel_holder.add_theme_constant_override("margin_top", 52)
	panel_holder.add_theme_constant_override("margin_right", 16)
	panel_holder.add_theme_constant_override("margin_bottom", 16)
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
	_menu_panel.custom_minimum_size = Vector2(268, 0)
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
	actions_vbox.add_theme_constant_override("separation", 6)
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

	_close_button = Button.new()
	_close_button.name = "CloseButton"
	_close_button.text = "Back"
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

	_launcher_button.text = _launcher_text
	if _title_label != null:
		_title_label.text = _title_text
	if _subtitle_label != null:
		_subtitle_label.text = _subtitle_text
	if _status_label != null:
		_status_label.text = _status_text
		_status_label.visible = not _status_text.is_empty()
	if _load_button != null:
		_load_button.disabled = not _load_available

	TempScreenThemeScript.apply_small_button(_launcher_button, TempScreenThemeScript.TEAL_ACCENT_COLOR, true)
	TempScreenThemeScript.apply_panel(_menu_panel, TempScreenThemeScript.PANEL_BORDER_COLOR, 16, 0.97)
	TempScreenThemeScript.apply_label(_title_label, "title")
	TempScreenThemeScript.apply_label(_subtitle_label, "muted")
	TempScreenThemeScript.apply_button(_save_button)
	TempScreenThemeScript.apply_button(_load_button, TempScreenThemeScript.TEAL_ACCENT_COLOR, true)
	TempScreenThemeScript.apply_button(_close_button, TempScreenThemeScript.RUST_ACCENT_COLOR, true)
	TempScreenThemeScript.apply_label(_status_label, "muted")


func _on_launcher_pressed() -> void:
	if _menu_open:
		close_menu()
		return
	open_menu()


func _on_dismiss_pressed() -> void:
	close_menu()


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


func _sync_full_rect() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
