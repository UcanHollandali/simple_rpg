# Layer: UI
extends RefCounted
class_name MapOverlayDirector

const OverlayLifecycleHelperScript = preload("res://Game/UI/overlay_lifecycle_helper.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")

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

const EVENT_OVERLAY_KEY := "event"
const SUPPORT_OVERLAY_KEY := "support"
const REWARD_OVERLAY_KEY := "reward"
const LEVEL_UP_OVERLAY_KEY := "level_up"
const OVERLAY_KEYS := [EVENT_OVERLAY_KEY, SUPPORT_OVERLAY_KEY, REWARD_OVERLAY_KEY, LEVEL_UP_OVERLAY_KEY]

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
	_overlay_lifecycle.close_overlays(OVERLAY_KEYS, immediate)


func position_overlays() -> void:
	if _overlay_lifecycle == null:
		return
	_overlay_lifecycle.position_overlays(OVERLAY_KEYS)


func has_active_overlay() -> bool:
	if _overlay_lifecycle == null:
		return false
	for overlay_key in OVERLAY_KEYS:
		var overlay: Control = _overlay_lifecycle.get_overlay(overlay_key)
		if overlay != null and overlay.visible:
			return true
	return false


func sync_with_flow_state(current_state: int) -> void:
	if current_state == FlowStateScript.Type.EVENT:
		open_event_overlay()
	else:
		close_event_overlay(false)

	if current_state == FlowStateScript.Type.SUPPORT_INTERACTION:
		open_support_overlay()
	else:
		close_support_overlay(false)

	if current_state == FlowStateScript.Type.REWARD:
		open_reward_overlay()
	else:
		close_reward_overlay(false)

	if current_state == FlowStateScript.Type.LEVEL_UP:
		open_level_up_overlay()
	else:
		close_level_up_overlay(false)


func open_event_overlay() -> void:
	if not _can_open_overlay_for_state(FlowStateScript.Type.EVENT):
		close_event_overlay(true)
		return
	_open_overlay(EVENT_OVERLAY_KEY, _event_scene, "EventOverlay", "Event")


func close_event_overlay(immediate: bool = false) -> void:
	_close_overlay(EVENT_OVERLAY_KEY, immediate)


func open_support_overlay() -> void:
	if not _can_open_overlay_for_state(FlowStateScript.Type.SUPPORT_INTERACTION):
		close_support_overlay(true)
		return
	_open_overlay(SUPPORT_OVERLAY_KEY, _support_scene, "SupportOverlay", "Support interaction")


func close_support_overlay(immediate: bool = false) -> void:
	_close_overlay(SUPPORT_OVERLAY_KEY, immediate)


func open_reward_overlay() -> void:
	if not _can_open_overlay_for_state(FlowStateScript.Type.REWARD):
		close_reward_overlay(true)
		return
	_open_overlay(REWARD_OVERLAY_KEY, _reward_scene, "RewardOverlay", "Reward")


func close_reward_overlay(immediate: bool = false) -> void:
	_close_overlay(REWARD_OVERLAY_KEY, immediate)


func open_level_up_overlay() -> void:
	if not _can_open_overlay_for_state(FlowStateScript.Type.LEVEL_UP):
		close_level_up_overlay(true)
		return
	_open_overlay(LEVEL_UP_OVERLAY_KEY, _level_up_scene, "LevelUpOverlay", "Level up")


func close_level_up_overlay(immediate: bool = false) -> void:
	_close_overlay(LEVEL_UP_OVERLAY_KEY, immediate)


func _open_overlay(key: String, overlay_scene: PackedScene, overlay_name: String, error_context: String) -> void:
	if _overlay_lifecycle == null:
		return
	_overlay_lifecycle.open_overlay(key, overlay_scene, overlay_name, error_context)


func _close_overlay(key: String, immediate: bool) -> void:
	if _overlay_lifecycle == null:
		return
	_overlay_lifecycle.close_overlay(key, immediate)


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
		_owner.call_deferred("_sync_safe_menu_launcher_visibility")
		if _owner.has_method("_request_overlay_ui_refresh"):
			_owner.call_deferred("_request_overlay_ui_refresh")


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


func _get_app_bootstrap() -> Node:
	if _owner == null or not is_instance_valid(_owner):
		return null
	return _owner.get_node_or_null("/root/AppBootstrap")
