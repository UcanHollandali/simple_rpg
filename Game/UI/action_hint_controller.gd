# Layer: UI
extends RefCounted
class_name ActionHintController

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")

const ACTION_HINT_META_KEY := "action_hint_text"
const ACTION_HINT_TWEEN_META_KEY := "action_hint_tween"
const ACTION_BUTTON_TWEEN_META_KEY := "action_button_tween"
const ACTION_HINT_PANEL_MAX_WIDTH := 440.0
const ACTION_HINT_PANEL_MARGIN := 16.0
const ACTION_HINT_PANEL_OPEN_DURATION := 0.2
const ACTION_HINT_PANEL_CLOSE_DURATION := 0.15
const ACTION_HINT_PANEL_HIDDEN_SCALE := Vector2(0.98, 0.94)
const ACTION_HINT_PANEL_VISIBLE_SCALE := Vector2.ONE
const BUTTON_BOUNCE_DOWN_DURATION := 0.1
const BUTTON_BOUNCE_UP_DURATION := 0.08

var _host: Control
var _action_hint_panel: PanelContainer
var _action_hint_label: Label
var _hovered_action_button: Control
var _hovered_action_accent: Color = TempScreenThemeScript.PANEL_BORDER_COLOR


func configure(host: Control, action_hint_panel: PanelContainer = null, action_hint_label: Label = null) -> void:
	_host = host
	_action_hint_panel = action_hint_panel
	_action_hint_label = action_hint_label
	if _action_hint_panel == null:
		return
	_action_hint_panel.visible = false
	_action_hint_panel.scale = ACTION_HINT_PANEL_HIDDEN_SCALE
	_action_hint_panel.modulate = Color(1, 1, 1, 0)
	_apply_action_hint_panel_style(TempScreenThemeScript.TEAL_ACCENT_COLOR)


func connect_button(button: Button, action_name: String, accent: Color) -> void:
	if button == null:
		return

	button.tooltip_text = ""
	button.focus_mode = Control.FOCUS_ALL
	set_action_hint_text(button, "")
	button.set_meta("action_name", action_name)
	var enter_handler := Callable(self, "_on_action_button_mouse_entered").bind(button, accent)
	var exit_handler := Callable(self, "_on_action_button_mouse_exited").bind(button)
	var focus_enter_handler := Callable(self, "_on_action_button_focus_entered").bind(button, accent)
	var focus_exit_handler := Callable(self, "_on_action_button_focus_exited").bind(button)
	var press_handler := Callable(self, "_on_action_button_pressed").bind(button, accent)
	var down_handler := Callable(self, "_on_action_button_down").bind(button, accent)
	if button.is_connected("mouse_entered", enter_handler):
		button.disconnect("mouse_entered", enter_handler)
	if not button.is_connected("mouse_entered", enter_handler):
		button.connect("mouse_entered", enter_handler)
	if button.is_connected("mouse_exited", exit_handler):
		button.disconnect("mouse_exited", exit_handler)
	if not button.is_connected("mouse_exited", exit_handler):
		button.connect("mouse_exited", exit_handler)
	if button.is_connected("focus_entered", focus_enter_handler):
		button.disconnect("focus_entered", focus_enter_handler)
	if not button.is_connected("focus_entered", focus_enter_handler):
		button.connect("focus_entered", focus_enter_handler)
	if button.is_connected("focus_exited", focus_exit_handler):
		button.disconnect("focus_exited", focus_exit_handler)
	if not button.is_connected("focus_exited", focus_exit_handler):
		button.connect("focus_exited", focus_exit_handler)
	if button.is_connected("pressed", press_handler):
		button.disconnect("pressed", press_handler)
	if not button.is_connected("pressed", press_handler):
		button.connect("pressed", press_handler)
	if button.is_connected("button_down", down_handler):
		button.disconnect("button_down", down_handler)
	if not button.is_connected("button_down", down_handler):
		button.connect("button_down", down_handler)


func refresh_button_tooltips(
	attack_button: Button,
	defense_button: Button,
	use_item_button: Button,
	presenter: RefCounted,
	combat_state: RefCounted,
	preview_consumable: Dictionary,
	preview_snapshot: Dictionary = {}
) -> void:
	if presenter == null:
		return

	if attack_button != null:
		set_action_hint_text(
			attack_button,
			presenter.build_action_tooltip_text(String(attack_button.get_meta("action_name", "")), combat_state, {}, preview_snapshot)
		)
	if defense_button != null:
		set_action_hint_text(
			defense_button,
			presenter.build_action_tooltip_text(String(defense_button.get_meta("action_name", "")), combat_state, {}, preview_snapshot)
		)
	if use_item_button != null:
		use_item_button.text = "Use Item"
		set_action_hint_text(
			use_item_button,
			presenter.build_action_tooltip_text(String(use_item_button.get_meta("action_name", "")), combat_state, preview_consumable, preview_snapshot)
		)
	update_visibility()


func update_visibility() -> void:
	_refresh_active_action_hint_panel()


func hide_panel(clear_hovered_button: bool = false, immediate: bool = false) -> void:
	if clear_hovered_button:
		_hovered_action_button = null
	if _action_hint_panel == null:
		return
	_kill_control_tween(_action_hint_panel, ACTION_HINT_TWEEN_META_KEY)
	if immediate or not _action_hint_panel.visible:
		_finish_hiding_action_hint_panel()
		return
	_action_hint_panel.pivot_offset = _action_hint_panel.size * 0.5
	var tween: Tween = _host.create_tween()
	_action_hint_panel.set_meta(ACTION_HINT_TWEEN_META_KEY, tween)
	tween.parallel().tween_property(_action_hint_panel, "modulate", Color(1, 1, 1, 0), ACTION_HINT_PANEL_CLOSE_DURATION)
	tween.parallel().tween_property(_action_hint_panel, "scale", ACTION_HINT_PANEL_HIDDEN_SCALE, ACTION_HINT_PANEL_CLOSE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(Callable(self, "_finish_hiding_action_hint_panel"), CONNECT_ONE_SHOT)


func set_action_hint_text(control: Control, text: String) -> void:
	if control == null:
		return
	var trimmed_text: String = text.strip_edges()
	if trimmed_text.is_empty():
		if control.has_meta(ACTION_HINT_META_KEY):
			control.remove_meta(ACTION_HINT_META_KEY)
		_update_action_hint_panel_if_active(control, trimmed_text)
	else:
		control.set_meta(ACTION_HINT_META_KEY, trimmed_text)
		_update_action_hint_panel_if_active(control, trimmed_text)


func _apply_action_hint_panel_style(accent: Color) -> void:
	if _action_hint_panel == null or _action_hint_label == null:
		return
	TempScreenThemeScript.apply_panel(_action_hint_panel, accent, 16, 0.96)
	TempScreenThemeScript.apply_label(_action_hint_label)
	_action_hint_label.add_theme_font_size_override("font_size", 18)
	_action_hint_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	_action_hint_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.04, 0.7))
	_action_hint_label.add_theme_constant_override("shadow_size", 2)


func _on_action_button_mouse_entered(button: Control, accent: Color) -> void:
	if button == null:
		return
	if button is BaseButton and (button as BaseButton).disabled:
		return
	_set_active_action_button(button, accent)


func _on_action_button_mouse_exited(button: Control) -> void:
	if button != _hovered_action_button:
		return
	hide_panel(true)


func _on_action_button_focus_entered(button: Control, accent: Color) -> void:
	if button == null:
		return
	if button is BaseButton and (button as BaseButton).disabled:
		return
	_set_active_action_button(button, accent)


func _on_action_button_focus_exited(button: Control) -> void:
	if button != _hovered_action_button:
		return
	hide_panel(true)


func _on_action_button_pressed(button: Control, accent: Color) -> void:
	if button == null:
		return
	if button is BaseButton and (button as BaseButton).disabled:
		return
	_set_active_action_button(button, accent)


func _on_action_button_down(button: Control, accent: Color) -> void:
	if button == null:
		return
	if button is BaseButton and (button as BaseButton).disabled:
		return
	_set_active_action_button(button, accent)
	_play_action_button_bounce(button)


func _refresh_active_action_hint_panel() -> void:
	if _action_hint_panel == null:
		return
	if _hovered_action_button == null or not is_instance_valid(_hovered_action_button):
		hide_panel()
		return
	if not _hovered_action_button.visible:
		hide_panel(true)
		return
	if _hovered_action_button is BaseButton and (_hovered_action_button as BaseButton).disabled:
		hide_panel(true)
		return
	var tooltip_text: String = _get_action_hint_text(_hovered_action_button).strip_edges()
	if tooltip_text.is_empty():
		hide_panel()
		return

	_apply_action_hint_panel_style(_hovered_action_accent)
	_action_hint_label.text = tooltip_text
	var parent_width: float = 0.0
	if _action_hint_panel.get_parent() != null:
		parent_width = _action_hint_panel.get_parent().size.x
	var viewport_width: float = _host.get_viewport_rect().size.x
	var fallback_width: float = viewport_width - (ACTION_HINT_PANEL_MARGIN * 2.0)
	var available_width: float = max(parent_width, fallback_width)
	var panel_width: float = clamp(available_width, 220.0, ACTION_HINT_PANEL_MAX_WIDTH)
	_action_hint_panel.custom_minimum_size = Vector2(panel_width, 0.0)
	_action_hint_panel.size = _action_hint_panel.get_combined_minimum_size()
	_action_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action_hint_label.custom_minimum_size = Vector2(panel_width - 20.0, 0.0)
	_action_hint_label.visible = true
	_position_action_hint_panel(_hovered_action_button)
	_show_action_hint_panel()


func _set_active_action_button(button: Control, accent: Color) -> void:
	_hovered_action_button = button
	_hovered_action_accent = accent
	_refresh_active_action_hint_panel()


func _get_action_hint_text(control: Control) -> String:
	if control == null or not control.has_meta(ACTION_HINT_META_KEY):
		return ""
	return String(control.get_meta(ACTION_HINT_META_KEY, ""))


func _update_action_hint_panel_if_active(control: Control, hint_text: String) -> void:
	if control == null or not is_instance_valid(control):
		return
	if _hovered_action_button != control:
		return
	if hint_text.strip_edges().is_empty():
		hide_panel(true)
		return
	_refresh_active_action_hint_panel()


func _show_action_hint_panel() -> void:
	if _action_hint_panel == null:
		return
	_kill_control_tween(_action_hint_panel, ACTION_HINT_TWEEN_META_KEY)
	var was_visible: bool = _action_hint_panel.visible and _action_hint_panel.modulate.a > 0.01
	_action_hint_panel.visible = true
	_action_hint_panel.pivot_offset = _action_hint_panel.size * 0.5
	if not was_visible:
		_action_hint_panel.scale = ACTION_HINT_PANEL_HIDDEN_SCALE
		_action_hint_panel.modulate = Color(1, 1, 1, 0)
	var tween: Tween = _host.create_tween()
	_action_hint_panel.set_meta(ACTION_HINT_TWEEN_META_KEY, tween)
	tween.parallel().tween_property(_action_hint_panel, "modulate", Color(1, 1, 1, 1), ACTION_HINT_PANEL_OPEN_DURATION)
	tween.parallel().tween_property(_action_hint_panel, "scale", ACTION_HINT_PANEL_VISIBLE_SCALE, ACTION_HINT_PANEL_OPEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(Callable(self, "_clear_control_meta").bind(_action_hint_panel, ACTION_HINT_TWEEN_META_KEY), CONNECT_ONE_SHOT)


func _finish_hiding_action_hint_panel() -> void:
	if _action_hint_panel == null or not is_instance_valid(_action_hint_panel):
		return
	_action_hint_panel.visible = false
	_action_hint_panel.scale = ACTION_HINT_PANEL_HIDDEN_SCALE
	_action_hint_panel.modulate = Color(1, 1, 1, 0)
	_clear_control_meta(_action_hint_panel, ACTION_HINT_TWEEN_META_KEY)


func _position_action_hint_panel(button: Control) -> void:
	if _action_hint_panel == null or button == null or not is_instance_valid(button):
		return
	var button_rect: Rect2 = button.get_global_rect()
	var viewport_size: Vector2 = _host.get_viewport_rect().size
	var panel_size: Vector2 = _action_hint_panel.size
	var x_position: float = clampf(
		button_rect.position.x + ((button_rect.size.x - panel_size.x) * 0.5),
		ACTION_HINT_PANEL_MARGIN,
		max(ACTION_HINT_PANEL_MARGIN, viewport_size.x - panel_size.x - ACTION_HINT_PANEL_MARGIN)
	)
	var y_position: float = button_rect.position.y - panel_size.y - 12.0
	if y_position < ACTION_HINT_PANEL_MARGIN:
		y_position = min(
			viewport_size.y - panel_size.y - ACTION_HINT_PANEL_MARGIN,
			button_rect.end.y + 12.0
		)
	_action_hint_panel.global_position = Vector2(x_position, y_position)


func _play_action_button_bounce(button: Control) -> void:
	if button == null or not is_instance_valid(button):
		return
	_kill_control_tween(button, ACTION_BUTTON_TWEEN_META_KEY)
	button.pivot_offset = button.size * 0.5
	button.scale = Vector2.ONE
	var tween: Tween = _host.create_tween()
	button.set_meta(ACTION_BUTTON_TWEEN_META_KEY, tween)
	tween.tween_property(button, "scale", Vector2.ONE * 0.95, BUTTON_BOUNCE_DOWN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, BUTTON_BOUNCE_UP_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(Callable(self, "_clear_control_meta").bind(button, ACTION_BUTTON_TWEEN_META_KEY), CONNECT_ONE_SHOT)


func _kill_control_tween(control: Control, meta_key: String) -> void:
	if control == null or not control.has_meta(meta_key):
		return
	var tween_value: Variant = control.get_meta(meta_key, null)
	if tween_value is Tween:
		var tween: Tween = tween_value as Tween
		if is_instance_valid(tween):
			tween.kill()
	control.remove_meta(meta_key)


func _clear_control_meta(control: Control, meta_key: String) -> void:
	if control == null or not is_instance_valid(control):
		return
	if control.has_meta(meta_key):
		control.remove_meta(meta_key)
