# Layer: UI helper
extends RefCounted
class_name CombatGuardBadge

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")

const PANEL_NAME := "PlayerGuardBadgePanel"
const LABEL_NAME := "PlayerGuardBadgeLabel"
const TWEEN_META_KEY := "player_guard_badge_tween"

var _owner: Control
var _scene_node_getter: Callable = Callable()
var _info_vbox_path: String = ""
var _summary_card_path: String = ""
var _panel: PanelContainer
var _label: Label
var _last_rendered_guard: int = -1
var _is_compact_layout: bool = false


func setup(owner: Control, scene_node_getter: Callable, info_vbox_path: String, summary_card_path: String) -> void:
	_owner = owner
	_scene_node_getter = scene_node_getter
	_info_vbox_path = info_vbox_path
	_summary_card_path = summary_card_path
	ensure_badge()


func ensure_badge() -> void:
	var info_vbox: VBoxContainer = _resolve_info_vbox()
	if info_vbox == null:
		return

	if _panel == null or not is_instance_valid(_panel):
		_panel = info_vbox.get_node_or_null(PANEL_NAME) as PanelContainer
	if _panel == null:
		_panel = PanelContainer.new()
		_panel.name = PANEL_NAME
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		info_vbox.add_child(_panel)

	if _label == null or not is_instance_valid(_label):
		_label = _panel.get_node_or_null(LABEL_NAME) as Label
	if _label == null:
		_label = Label.new()
		_label.name = LABEL_NAME
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_panel.add_child(_label)

	var player_run_summary_card: PanelContainer = _resolve_summary_card()
	if player_run_summary_card != null:
		info_vbox.move_child(_panel, min(info_vbox.get_child_count() - 1, player_run_summary_card.get_index() + 1))

	refresh_style()
	if _last_rendered_guard < 0:
		_finish_hide()


func refresh_style() -> void:
	if _panel == null or _label == null:
		return
	TempScreenThemeScript.apply_chip(_panel, _label, TempScreenThemeScript.TEAL_ACCENT_COLOR)
	TempScreenThemeScript.apply_label(_label)
	_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.84))
	_label.add_theme_constant_override("outline_size", 4)
	apply_layout(_is_compact_layout)


func apply_layout(is_compact_layout: bool) -> void:
	_is_compact_layout = is_compact_layout
	if _owner == null or _panel == null or _label == null:
		return
	var viewport_height: float = _owner.get_viewport_rect().size.y
	var font_size: int = 16 if _is_compact_layout else 18
	if viewport_height < 1500.0:
		font_size = 15 if _is_compact_layout else 16
	elif viewport_height >= 1800.0 and not _is_compact_layout:
		font_size = 19
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_label.add_theme_font_size_override("font_size", font_size)


func refresh(current_guard: int, badge_text: String, is_compact_layout: bool) -> void:
	ensure_badge()
	if _panel == null or _label == null:
		return

	_label.text = badge_text
	apply_layout(is_compact_layout)
	current_guard = max(0, current_guard)

	if _last_rendered_guard < 0:
		_last_rendered_guard = current_guard
		if current_guard > 0:
			_panel.visible = true
			_panel.modulate = Color(1, 1, 1, 1)
			_panel.scale = Vector2.ONE
		else:
			_finish_hide()
		return

	if current_guard <= 0:
		if _last_rendered_guard > 0 or _panel.visible:
			_hide()
		else:
			_finish_hide()
		_last_rendered_guard = 0
		return

	var should_pop: bool = _last_rendered_guard <= 0 or current_guard > _last_rendered_guard
	_show(should_pop)
	_last_rendered_guard = current_guard


func release() -> void:
	_kill_tween()


func _show(pop_badge: bool = false) -> void:
	if _panel == null or _owner == null:
		return
	_kill_tween()
	_panel.pivot_offset = _panel.get_combined_minimum_size() * 0.5
	var needs_fade_in: bool = not _panel.visible or _panel.modulate.a < 0.99
	_panel.visible = true
	if not needs_fade_in and not pop_badge:
		_panel.modulate = Color(1, 1, 1, 1)
		_panel.scale = Vector2.ONE
		return

	_panel.modulate = Color(1, 1, 1, 0) if needs_fade_in else Color(1, 1, 1, 1)
	_panel.scale = Vector2.ONE * (0.88 if pop_badge else 0.96)
	var tween: Tween = _owner.create_tween()
	_panel.set_meta(TWEEN_META_KEY, tween)
	tween.parallel().tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.16)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(Callable(self, "_clear_meta"), CONNECT_ONE_SHOT)


func _hide() -> void:
	if _panel == null or _owner == null:
		return
	_kill_tween()
	if not _panel.visible:
		_finish_hide()
		return
	_panel.pivot_offset = _panel.get_combined_minimum_size() * 0.5
	var tween: Tween = _owner.create_tween()
	_panel.set_meta(TWEEN_META_KEY, tween)
	tween.parallel().tween_property(_panel, "modulate", Color(1, 1, 1, 0), 0.14)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE * 0.94, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(Callable(self, "_finish_hide"), CONNECT_ONE_SHOT)


func _finish_hide() -> void:
	if _panel == null or not is_instance_valid(_panel):
		return
	_panel.visible = false
	_panel.modulate = Color(1, 1, 1, 0)
	_panel.scale = Vector2.ONE
	_clear_meta()


func _resolve_info_vbox() -> VBoxContainer:
	if not _scene_node_getter.is_valid():
		return null
	return _scene_node_getter.call(_info_vbox_path) as VBoxContainer


func _resolve_summary_card() -> PanelContainer:
	if not _scene_node_getter.is_valid():
		return null
	return _scene_node_getter.call(_summary_card_path) as PanelContainer


func _kill_tween() -> void:
	if _panel == null or not _panel.has_meta(TWEEN_META_KEY):
		return
	var tween_value: Variant = _panel.get_meta(TWEEN_META_KEY, null)
	if tween_value is Tween:
		var tween: Tween = tween_value as Tween
		if is_instance_valid(tween):
			tween.kill()
	_panel.remove_meta(TWEEN_META_KEY)


func _clear_meta() -> void:
	if _panel != null and is_instance_valid(_panel) and _panel.has_meta(TWEEN_META_KEY):
		_panel.remove_meta(TWEEN_META_KEY)
