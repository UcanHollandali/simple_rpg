# Layer: UI
extends RefCounted
class_name MapOverlayDirector

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const OverlayLifecycleHelperScript = preload("res://Game/UI/overlay_lifecycle_helper.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const MapOverlayContractScript = preload("res://Game/UI/map_overlay_contract.gd")

const EVENT_OVERLAY_OPEN_DURATION := 0.26
const EVENT_OVERLAY_CLOSE_DURATION := 0.2
const EVENT_OVERLAY_OPEN_SCALE := 0.985
const EVENT_OVERLAY_CLOSED_SCALE := 0.965
const EVENT_OVERLAY_Z_INDEX := 180
const EVENT_OVERLAY_FAR_ALPHA := 0.0
const EVENT_OVERLAY_MID_ALPHA := 0.0
const EVENT_OVERLAY_OVERLAY_ALPHA := 0.0
const EVENT_OVERLAY_SCRIM_ALPHA := 0.42
const EVENT_OVERLAY_ROADSIDE_SCRIM_ALPHA := 0.54
const EVENT_OVERLAY_TWEEN_TRANSITION := Tween.TRANS_EXPO

var _owner: Control
var _overlay_lifecycle: OverlayLifecycleHelper
var _event_scene: PackedScene
var _support_scene: PackedScene
var _reward_scene: PackedScene
var _level_up_scene: PackedScene


func configure(owner: Control, config: Dictionary) -> void:
	_owner = owner
	_event_scene = config.get("event_scene") as PackedScene
	_support_scene = config.get("support_scene") as PackedScene
	_reward_scene = config.get("reward_scene") as PackedScene
	_level_up_scene = config.get("level_up_scene") as PackedScene
	_overlay_lifecycle = OverlayLifecycleHelperScript.new()
	_overlay_lifecycle.configure(_owner, {
		"overlay_z_index": EVENT_OVERLAY_Z_INDEX,
		"open_duration": EVENT_OVERLAY_OPEN_DURATION,
		"close_duration": EVENT_OVERLAY_CLOSE_DURATION,
		"open_scale": EVENT_OVERLAY_OPEN_SCALE,
		"closed_scale": EVENT_OVERLAY_CLOSED_SCALE,
		"tween_transition": EVENT_OVERLAY_TWEEN_TRANSITION,
		"before_show_handler": Callable(self, "_tune_event_overlay_visuals"),
		"state_changed_handler": Callable(self, "_notify_overlay_state_changed"),
	})


func close_all(immediate: bool = false) -> void:
	if _overlay_lifecycle == null:
		return
	_overlay_lifecycle.close_overlays(_overlay_keys(), immediate)


func position_overlays() -> void:
	if _overlay_lifecycle == null:
		return
	_overlay_lifecycle.position_overlays(_overlay_keys())


func has_active_overlay() -> bool:
	if _overlay_lifecycle == null:
		return false
	for overlay_key in _overlay_keys():
		var overlay: Control = _overlay_lifecycle.get_overlay(overlay_key)
		if overlay != null and overlay.visible:
			return true
	return false


func sync_with_flow_state(current_state: int) -> void:
	for overlay_state in MapOverlayContractScript.overlay_states():
		if current_state == overlay_state:
			open_overlay_for_state(overlay_state)
		else:
			close_overlay_for_state(overlay_state, false)


func open_overlay_for_state(flow_state: int) -> void:
	var overlay_key: String = MapOverlayContractScript.overlay_key(flow_state)
	if overlay_key.is_empty():
		return
	if not _can_open_overlay_for_state(flow_state):
		close_overlay_for_state(flow_state, true)
		return
	_open_overlay(
		overlay_key,
		_overlay_scene_for_state(flow_state),
		MapOverlayContractScript.overlay_root_name(flow_state),
		MapOverlayContractScript.overlay_error_context(flow_state)
	)


func close_overlay_for_state(flow_state: int, immediate: bool = false) -> void:
	var overlay_key: String = MapOverlayContractScript.overlay_key(flow_state)
	if overlay_key.is_empty():
		return
	_close_overlay(overlay_key, immediate)


func _open_overlay(key: String, overlay_scene: PackedScene, overlay_name: String, error_context: String) -> void:
	if _overlay_lifecycle == null:
		return
	_overlay_lifecycle.open_overlay(key, overlay_scene, overlay_name, error_context)


func _close_overlay(key: String, immediate: bool) -> void:
	if _overlay_lifecycle == null:
		return
	_overlay_lifecycle.close_overlay(key, immediate)


func _overlay_keys() -> Array[String]:
	var overlay_keys: Array[String] = []
	for overlay_state in MapOverlayContractScript.overlay_states():
		overlay_keys.append(MapOverlayContractScript.overlay_key(overlay_state))
	return overlay_keys


func _overlay_scene_for_state(flow_state: int) -> PackedScene:
	match flow_state:
		FlowStateScript.Type.EVENT:
			return _event_scene
		FlowStateScript.Type.SUPPORT_INTERACTION:
			return _support_scene
		FlowStateScript.Type.REWARD:
			return _reward_scene
		FlowStateScript.Type.LEVEL_UP:
			return _level_up_scene
		_:
			return null


func _tune_event_overlay_visuals(event_overlay: Control) -> void:
	if event_overlay == null or not is_instance_valid(event_overlay):
		return
	var event_state = event_overlay.get("_event_state")
	var roadside_overlay: bool = event_state != null and String(event_state.source_context) == "roadside_encounter"

	var background_far: CanvasItem = event_overlay.get_node_or_null("BackgroundFar") as CanvasItem
	if background_far != null:
		background_far.modulate = Color(1, 1, 1, EVENT_OVERLAY_FAR_ALPHA)
	var background_mid: CanvasItem = event_overlay.get_node_or_null("BackgroundMid") as CanvasItem
	if background_mid != null:
		background_mid.modulate = Color(1, 1, 1, EVENT_OVERLAY_MID_ALPHA)
	var background_overlay: CanvasItem = event_overlay.get_node_or_null("BackgroundOverlay") as CanvasItem
	if background_overlay != null:
		background_overlay.modulate = Color(1, 1, 1, EVENT_OVERLAY_OVERLAY_ALPHA)
	var scrim: ColorRect = event_overlay.get_node_or_null("Scrim") as ColorRect
	if scrim != null:
		scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var scrim_alpha: float = EVENT_OVERLAY_ROADSIDE_SCRIM_ALPHA if roadside_overlay else EVENT_OVERLAY_SCRIM_ALPHA
		scrim.color = Color(scrim.color.r, scrim.color.g, scrim.color.b, scrim_alpha)


func _notify_overlay_state_changed() -> void:
	if _owner != null and is_instance_valid(_owner):
		Callable(_owner, "_sync_safe_menu_launcher_visibility").call_deferred()
		Callable(_owner, "_request_overlay_ui_refresh").call_deferred()


func _can_open_overlay_for_state(flow_state: int) -> bool:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return true
	match flow_state:
		FlowStateScript.Type.EVENT:
			return bootstrap.get_event_state() != null
		FlowStateScript.Type.SUPPORT_INTERACTION:
			return bootstrap.get_support_interaction_state() != null
		FlowStateScript.Type.REWARD:
			return bootstrap.get_reward_state() != null
		FlowStateScript.Type.LEVEL_UP:
			return bootstrap.get_level_up_state() != null
		_:
			return true


func _get_app_bootstrap() -> AppBootstrapScript:
	if _owner == null or not is_instance_valid(_owner):
		return null
	return _owner.get_node_or_null("/root/AppBootstrap") as AppBootstrapScript
