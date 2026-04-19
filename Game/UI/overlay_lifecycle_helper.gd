# Layer: UI
extends RefCounted
class_name OverlayLifecycleHelper

var _owner: Control
var _overlay_z_index: int = 180
var _open_duration: float = 0.26
var _close_duration: float = 0.2
var _open_scale: float = 0.985
var _closed_scale: float = 0.965
var _tween_transition: Tween.TransitionType = Tween.TRANS_EXPO
var _before_show_handler: Callable = Callable()
var _state_changed_handler: Callable = Callable()
var _overlay_states: Dictionary = {}


func configure(owner: Control, config: Dictionary = {}) -> void:
	_owner = owner
	_overlay_z_index = int(config.get("overlay_z_index", _overlay_z_index))
	_open_duration = float(config.get("open_duration", _open_duration))
	_close_duration = float(config.get("close_duration", _close_duration))
	_open_scale = float(config.get("open_scale", _open_scale))
	_closed_scale = float(config.get("closed_scale", _closed_scale))
	_tween_transition = int(config.get("tween_transition", _tween_transition))
	_before_show_handler = config.get("before_show_handler", Callable())
	_state_changed_handler = config.get("state_changed_handler", Callable())


func open_overlay(key: String, overlay_scene: PackedScene, overlay_name: String, error_context: String) -> void:
	if _owner == null or not is_instance_valid(_owner):
		return

	var state: Dictionary = _get_state(key)
	state["tween"] = _stop_overlay_tween(state.get("tween") as Tween)
	var overlay: Control = _normalize_overlay_instance(state.get("overlay") as Control)
	if overlay == null:
		overlay = _create_overlay_control(overlay_scene, overlay_name, error_context)
	if overlay == null:
		state["overlay"] = null
		state["tween"] = null
		_overlay_states[key] = state
		return

	state["overlay"] = overlay
	var tween: Tween = _show_overlay_with_tween(overlay)
	state["tween"] = tween
	_overlay_states[key] = state
	_notify_state_changed()
	if tween != null:
		tween.finished.connect(Callable(self, "_on_open_tween_finished").bind(key, tween.get_instance_id()), CONNECT_ONE_SHOT)


func close_overlay(key: String, immediate: bool = false) -> void:
	var state: Dictionary = _get_state(key)
	var overlay: Control = _normalize_overlay_instance(state.get("overlay") as Control)
	if overlay == null:
		state["overlay"] = null
		state["tween"] = null
		_overlay_states[key] = state
		return

	state["tween"] = _stop_overlay_tween(state.get("tween") as Tween)
	if immediate:
		state["overlay"] = _remove_overlay(overlay)
		state["tween"] = null
		_overlay_states[key] = state
		_notify_state_changed()
		return

	var tween: Tween = _hide_overlay_with_tween(overlay)
	state["tween"] = tween
	_overlay_states[key] = state
	if tween != null:
		tween.finished.connect(Callable(self, "_on_close_tween_finished").bind(key, tween.get_instance_id()), CONNECT_ONE_SHOT)


func close_overlays(keys: Array, immediate: bool = false) -> void:
	for key_name in keys:
		close_overlay(String(key_name), immediate)


func position_overlays(keys: Array) -> void:
	for key_name in keys:
		_position_overlay(get_overlay(String(key_name)))


func get_overlay(key: String) -> Control:
	var state: Dictionary = _get_state(key)
	var overlay: Control = _normalize_overlay_instance(state.get("overlay") as Control)
	state["overlay"] = overlay
	_overlay_states[key] = state
	return overlay


func _get_state(key: String) -> Dictionary:
	var state: Dictionary = _overlay_states.get(key, {})
	if not state.has("overlay"):
		state["overlay"] = null
	if not state.has("tween"):
		state["tween"] = null
	return state


func _stop_overlay_tween(overlay_tween: Tween) -> Tween:
	if overlay_tween != null and is_instance_valid(overlay_tween):
		overlay_tween.kill()
	return null


func _normalize_overlay_instance(overlay: Control) -> Control:
	if overlay != null and not is_instance_valid(overlay):
		return null
	if overlay != null and overlay.is_queued_for_deletion():
		return null
	return overlay


func _create_overlay_control(overlay_scene: PackedScene, overlay_name: String, error_context: String) -> Control:
	if overlay_scene == null:
		return null
	var overlay_instance: Node = overlay_scene.instantiate()
	if overlay_instance == null:
		return null
	var overlay_control: Control = overlay_instance as Control
	if overlay_control == null:
		push_error("%s overlay must inherit Control." % error_context)
		overlay_instance.queue_free()
		return null

	overlay_control.name = overlay_name
	overlay_control.top_level = true
	overlay_control.z_as_relative = false
	overlay_control.z_index = _overlay_z_index
	overlay_control.visible = false
	overlay_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_control.anchor_right = 1.0
	overlay_control.anchor_bottom = 1.0
	overlay_control.grow_horizontal = Control.GROW_DIRECTION_BOTH
	overlay_control.grow_vertical = Control.GROW_DIRECTION_BOTH
	_owner.add_child(overlay_control)
	return overlay_control


func _show_overlay_with_tween(overlay: Control) -> Tween:
	if overlay == null or not is_instance_valid(overlay) or _owner == null or not is_instance_valid(_owner):
		return null
	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if _before_show_handler.is_valid():
		_before_show_handler.call(overlay)
	overlay.modulate = Color(1, 1, 1, 0)
	overlay.scale = Vector2(_open_scale, _open_scale)
	_position_overlay(overlay)

	var tween: Tween = _owner.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(_tween_transition)
	tween.tween_property(overlay, "modulate", Color(1, 1, 1, 1), _open_duration)
	tween.parallel().tween_property(overlay, "scale", Vector2.ONE, _open_duration)
	return tween


func _hide_overlay_with_tween(overlay: Control) -> Tween:
	if overlay == null or not is_instance_valid(overlay) or _owner == null or not is_instance_valid(_owner):
		return null
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tween: Tween = _owner.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(_tween_transition)
	tween.tween_property(overlay, "modulate", Color(1, 1, 1, 0), _close_duration)
	tween.parallel().tween_property(overlay, "scale", Vector2(_closed_scale, _closed_scale), _close_duration)
	return tween


func _position_overlay(overlay: Control) -> void:
	if overlay == null or not is_instance_valid(overlay) or _owner == null or not is_instance_valid(_owner):
		return
	var viewport_rect: Rect2 = _owner.get_viewport_rect()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.offset_left = 0.0
	overlay.offset_top = 0.0
	overlay.offset_right = 0.0
	overlay.offset_bottom = 0.0
	overlay.grow_horizontal = Control.GROW_DIRECTION_BOTH
	overlay.grow_vertical = Control.GROW_DIRECTION_BOTH
	overlay.pivot_offset = viewport_rect.size * 0.5


func _remove_overlay(overlay: Control) -> Control:
	if overlay != null and is_instance_valid(overlay):
		var parent: Node = overlay.get_parent()
		if parent != null:
			parent.remove_child(overlay)
		overlay.queue_free()
	return null


func _remove_overlay_for_key(key: String) -> void:
	var state: Dictionary = _get_state(key)
	state["overlay"] = _remove_overlay(state.get("overlay") as Control)
	_overlay_states[key] = state
	_notify_state_changed()


func _on_open_tween_finished(key: String, tween_instance_id: int) -> void:
	_clear_finished_tween_by_id(key, tween_instance_id)


func _on_close_tween_finished(key: String, tween_instance_id: int) -> void:
	var cleared: bool = _clear_finished_tween_by_id(key, tween_instance_id)
	if cleared:
		_remove_overlay_for_key(key)


func _clear_finished_tween_by_id(key: String, tween_instance_id: int) -> bool:
	var state: Dictionary = _get_state(key)
	var active_tween: Tween = state.get("tween") as Tween
	if active_tween != null and is_instance_valid(active_tween) and active_tween.get_instance_id() == tween_instance_id:
		state["tween"] = null
		_overlay_states[key] = state
		return true
	return false


func _notify_state_changed() -> void:
	if _state_changed_handler.is_valid():
		_state_changed_handler.call()
