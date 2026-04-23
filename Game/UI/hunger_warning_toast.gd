# Layer: UI helper
extends RefCounted
class_name HungerWarningToast

const RunStatusStripScript = preload("res://Game/UI/run_status_strip.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")

const PANEL_NAME := "HungerWarningToast"
const LABEL_NAME := "HungerWarningLabel"
const SHOW_DURATION := 2.0
const MARGIN := 16.0
const TOP_GAP := 12.0

var _owner: Control
var _anchor_path: String = ""
var _z_index: int = 130
var _compact_layout: bool = false
var _current_threshold: int = RunStatusStripScript.HUNGER_THRESHOLD_HUNGRY
var _panel: PanelContainer
var _label: Label
var _tween: Tween


func setup(owner: Control, anchor_path: String, z_index: int = 130, compact_layout: bool = false) -> void:
	_owner = owner
	_anchor_path = anchor_path
	_z_index = z_index
	_compact_layout = compact_layout
	ensure_toast()


func ensure_toast() -> void:
	if _panel != null and is_instance_valid(_panel):
		_apply_style(_current_threshold)
		position_toast()
		return
	if _owner == null or not is_instance_valid(_owner):
		return

	_panel = PanelContainer.new()
	_panel.name = PANEL_NAME
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.top_level = true
	_panel.z_index = _z_index
	_panel.modulate = Color(1, 1, 1, 0)
	_owner.add_child(_panel)

	_label = Label.new()
	_label.name = LABEL_NAME
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)

	_apply_style(_current_threshold)
	finish_hide()


func show_warning(warning_text: String, threshold: int) -> void:
	ensure_toast()
	if _panel == null or _label == null:
		return
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()

	_current_threshold = threshold
	_label.text = warning_text
	_apply_style(threshold)
	_panel.custom_minimum_size = Vector2(max(220.0, min(_owner.get_viewport_rect().size.x - (MARGIN * 2.0), 420.0)), 0.0)
	_label.custom_minimum_size = Vector2(max(200.0, _panel.custom_minimum_size.x - 20.0), 0.0)
	_panel.size = _panel.get_combined_minimum_size()
	position_toast()
	_panel.visible = true
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.96, 0.96)
	_panel.modulate = Color(1, 1, 1, 0)

	_tween = _owner.create_tween()
	_tween.parallel().tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.16)
	_tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(SHOW_DURATION)
	_tween.parallel().tween_property(_panel, "modulate", Color(1, 1, 1, 0), 0.18)
	_tween.parallel().tween_property(_panel, "scale", Vector2(0.98, 0.98), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.finished.connect(Callable(self, "finish_hide"), CONNECT_ONE_SHOT)


func position_toast() -> void:
	if _owner == null or _panel == null or not is_instance_valid(_panel):
		return
	var viewport_size: Vector2 = _owner.get_viewport_rect().size
	var panel_size: Vector2 = _panel.size
	var anchor_bottom: float = MARGIN
	var anchor_control: Control = _owner.get_node_or_null(_anchor_path) as Control
	if anchor_control != null and anchor_control.visible:
		anchor_bottom = anchor_control.get_global_rect().end.y + TOP_GAP
	var x_position: float = clampf(
		(viewport_size.x - panel_size.x) * 0.5,
		MARGIN,
		max(MARGIN, viewport_size.x - panel_size.x - MARGIN)
	)
	var y_position: float = clampf(
		anchor_bottom,
		MARGIN,
		max(MARGIN, viewport_size.y - panel_size.y - MARGIN)
	)
	_panel.global_position = Vector2(x_position, y_position)


func set_compact_layout(compact_layout: bool) -> void:
	_compact_layout = compact_layout
	_apply_style(_current_threshold)


func finish_hide() -> void:
	if _panel == null or not is_instance_valid(_panel):
		return
	_panel.visible = false
	_panel.modulate = Color(1, 1, 1, 0)
	_panel.scale = Vector2.ONE
	_tween = null


func release() -> void:
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()
	_tween = null


func _apply_style(threshold: int) -> void:
	if _panel == null or _label == null or _owner == null:
		return
	var accent: Color = RunStatusStripScript.resolve_hunger_threshold_accent(threshold)
	TempScreenThemeScript.apply_panel(_panel, accent, 16, 0.94)
	TempScreenThemeScript.apply_label(_label, "muted")
	_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.04, 0.76))
	_label.add_theme_constant_override("shadow_size", 2)
	var viewport_height: float = _owner.get_viewport_rect().size.y
	var font_size: int = 18 if not _compact_layout else 17
	if viewport_height < 1400.0:
		font_size = 16 if not _compact_layout else 15
	elif viewport_height >= 1800.0 and not _compact_layout:
		font_size = 20
	_label.add_theme_font_size_override("font_size", font_size)
