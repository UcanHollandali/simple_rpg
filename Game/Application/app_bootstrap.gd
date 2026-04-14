# Layer: Application (Autoload)
extends Node

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const GameFlowManagerScript = preload("res://Game/Application/game_flow_manager.gd")
const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")
const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")
const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")
const LevelUpStateScript = preload("res://Game/RuntimeState/level_up_state.gd")
const SupportInteractionStateScript = preload("res://Game/RuntimeState/support_interaction_state.gd")
const SaveServiceScript = preload("res://Game/Infrastructure/save_service.gd")
const RunSessionCoordinatorScript = preload("res://Game/Application/run_session_coordinator.gd")
const SaveRuntimeBridgeScript = preload("res://Game/Application/save_runtime_bridge.gd")

const BASE_UI_REFERENCE_RESOLUTION := Vector2i(1080, 1920)

var game_flow_manager: GameFlowManager
var run_state: RunState
var save_service: SaveService
var run_session_coordinator: RunSessionCoordinator
var save_runtime_bridge: SaveRuntimeBridge
var _coordinator_bound_flow_manager: GameFlowManager
var _coordinator_bound_run_state: RunState
var _save_bridge_bound_flow_manager: GameFlowManager
var _save_bridge_bound_run_state: RunState
var _save_bridge_bound_run_session_coordinator: RunSessionCoordinator
var _save_bridge_bound_save_service: SaveService
var _is_fullscreen: bool = false


func _ready() -> void:
	_apply_startup_resolution()
	_apply_startup_window_mode()
	call_deferred("apply_ui_scale_to_active_scene")
	game_flow_manager = _ensure_flow_manager()
	run_state = _ensure_run_state()
	save_service = _ensure_save_service()
	run_session_coordinator = _ensure_run_session_coordinator()
	save_runtime_bridge = _ensure_save_runtime_bridge()


func get_flow_manager() -> GameFlowManager:
	return game_flow_manager


func get_run_state() -> RunState:
	return run_state


func get_map_runtime_state() -> MapRuntimeState:
	var active_run_state: RunState = get_run_state()
	if active_run_state == null:
		return null
	return active_run_state.map_runtime_state as MapRuntimeState


func get_reward_state() -> RewardState:
	return _ensure_run_session_coordinator().get_reward_state() as RewardState


func get_level_up_state() -> LevelUpState:
	return _ensure_run_session_coordinator().get_level_up_state() as LevelUpState


func get_event_state() -> EventStateScript:
	return _ensure_run_session_coordinator().get_event_state() as EventStateScript


func get_support_interaction_state() -> SupportInteractionState:
	return _ensure_run_session_coordinator().get_support_interaction_state() as SupportInteractionState


func build_combat_setup_data() -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().build_combat_setup_data()


func save_game(save_path: String = "") -> Dictionary:
	return _ensure_save_runtime_bridge().save_game(save_path)


func load_game(save_path: String = "") -> Dictionary:
	var load_result: Dictionary = _ensure_save_runtime_bridge().load_game(save_path)
	if bool(load_result.get("ok", false)):
		_route_restore_state(int(load_result.get("active_flow_state", -1)))
	return load_result


func build_save_snapshot(save_path: String = "") -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_save_runtime_bridge().build_save_snapshot(save_path)


func restore_from_snapshot(snapshot: Dictionary) -> Dictionary:
	var restore_result: Dictionary = _ensure_save_runtime_bridge().restore_from_snapshot(snapshot)
	if bool(restore_result.get("ok", false)):
		_route_restore_state(int(restore_result.get("active_flow_state", -1)))
	return restore_result


func get_supported_resolution_options() -> Array[String]:
	return []


func get_active_resolution_index() -> int:
	return 0


func is_fullscreen_enabled() -> bool:
	return _is_fullscreen


func get_ui_scale_factor() -> float:
	return 1.0


func apply_fullscreen_mode(enabled: bool) -> Dictionary:
	var applied: bool = _apply_fullscreen_mode(false)
	if not applied:
		return {"ok": false, "error": "window_unavailable", "fullscreen": false}

	_is_fullscreen = false
	apply_ui_scale_to_active_scene()
	_save_fullscreen_setting(false)
	return {"ok": true, "fullscreen": false}


func apply_ui_scale_to_active_scene() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	var control_root: Control = current_scene as Control
	if control_root == null:
		return
	control_root.scale = Vector2.ONE


func apply_resolution_by_index(index: int) -> Dictionary:
	var requested_size: Vector2i = BASE_UI_REFERENCE_RESOLUTION
	var target_window_size: Vector2i = _resolve_windowed_size_for_display(requested_size)
	var applied: bool = _apply_window_size(target_window_size)
	if not applied:
		return {
			"ok": false,
			"error": "window_unavailable",
			"index": 0,
			"size": requested_size,
			"window_size": target_window_size,
		}
	apply_ui_scale_to_active_scene()
	return {
		"ok": true,
		"index": 0,
		"size": requested_size,
		"window_size": target_window_size,
		"deferred_until_windowed": false,
	}


func has_save_game(save_path: String = "") -> bool:
	return _ensure_save_runtime_bridge().has_save_game(save_path)


func delete_save_game(save_path: String = "") -> Dictionary:
	return _ensure_save_runtime_bridge().delete_save_game(save_path)


func reset_run_state_for_new_run() -> void:
	if run_state == null:
		run_state = _ensure_run_state()
	run_state.reset_for_new_run()
	_ensure_run_session_coordinator().reset_for_new_run()


func ensure_run_state_initialized() -> RunState:
	if run_state == null:
		run_state = _ensure_run_state()
	return _ensure_run_session_coordinator().ensure_run_state_initialized()


func get_last_run_result() -> String:
	return _ensure_run_session_coordinator().get_last_run_result()


func choose_move_to_node(node_reference: Variant) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().choose_move_to_node(node_reference)


func toggle_inventory_equipment(slot_id: int) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().toggle_inventory_equipment(slot_id)


func move_inventory_slot(slot_id: int, target_index: int) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().move_inventory_slot(slot_id, target_index)


func use_inventory_consumable(slot_id: int) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().use_inventory_consumable(slot_id)


func resolve_pending_node() -> Dictionary:
	return _ensure_run_session_coordinator().resolve_pending_node()


func choose_reward_option(option_id: String) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().choose_reward_option(option_id)


func choose_event_option(option_id: String) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().choose_event_option(option_id)


func resolve_combat_result(result: String) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().resolve_combat_result(result)


func choose_level_up_option(option_id: String) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().choose_level_up_option(option_id)


func choose_support_action(action_id: String) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().choose_support_action(action_id)


func finish_boot_to_main_menu() -> void:
	if game_flow_manager == null:
		return
	if game_flow_manager.get_current_state() != FlowStateScript.Type.BOOT:
		return
	_request_transition(FlowStateScript.Type.MAIN_MENU)


func _ensure_flow_manager() -> GameFlowManager:
	var existing_manager: Node = get_node_or_null("GameFlowManager")
	if existing_manager != null and existing_manager.get_script() == GameFlowManagerScript:
		return existing_manager as GameFlowManager

	var new_manager: GameFlowManager = GameFlowManagerScript.new()
	new_manager.name = "GameFlowManager"
	add_child(new_manager)
	return new_manager


func _ensure_run_state() -> RunState:
	if run_state != null:
		return run_state

	run_state = RunStateScript.new()
	return run_state


func _ensure_save_service() -> SaveService:
	if save_service != null:
		return save_service

	save_service = SaveServiceScript.new()
	return save_service


func _ensure_run_session_coordinator() -> RunSessionCoordinator:
	if run_session_coordinator == null:
		run_session_coordinator = RunSessionCoordinatorScript.new()

	var flow_manager: GameFlowManager = _ensure_flow_manager()
	var active_run_state: RunState = _ensure_run_state()
	# AppBootstrap stays a facade only; it tracks the dependency snapshot it bound last time
	# instead of re-running coordinator setup on every delegated call.
	if _coordinator_binding_changed(flow_manager, active_run_state):
		run_session_coordinator.setup(flow_manager, active_run_state)
		_coordinator_bound_flow_manager = flow_manager
		_coordinator_bound_run_state = active_run_state
	return run_session_coordinator


func _coordinator_binding_changed(flow_manager: GameFlowManager, active_run_state: RunState) -> bool:
	return _coordinator_bound_flow_manager != flow_manager or _coordinator_bound_run_state != active_run_state


func _ensure_save_runtime_bridge() -> SaveRuntimeBridge:
	if save_runtime_bridge == null:
		save_runtime_bridge = SaveRuntimeBridgeScript.new()
	var flow_manager: GameFlowManager = _ensure_flow_manager()
	var active_run_state: RunState = _ensure_run_state()
	var session_coordinator: RunSessionCoordinator = _ensure_run_session_coordinator()
	var active_save_service: SaveService = _ensure_save_service()
	if _save_bridge_binding_changed(flow_manager, active_run_state, session_coordinator, active_save_service):
		save_runtime_bridge.setup(
			flow_manager,
			active_run_state,
			session_coordinator,
			active_save_service
		)
		_save_bridge_bound_flow_manager = flow_manager
		_save_bridge_bound_run_state = active_run_state
		_save_bridge_bound_run_session_coordinator = session_coordinator
		_save_bridge_bound_save_service = active_save_service
	return save_runtime_bridge


func _save_bridge_binding_changed(
	flow_manager: GameFlowManager,
	active_run_state: RunState,
	session_coordinator: RunSessionCoordinator,
	active_save_service: SaveService
) -> bool:
	return (
		_save_bridge_bound_flow_manager != flow_manager
		or _save_bridge_bound_run_state != active_run_state
		or _save_bridge_bound_run_session_coordinator != session_coordinator
		or _save_bridge_bound_save_service != active_save_service
	)


func _request_transition(target_state: int) -> void:
	if game_flow_manager == null:
		return
	game_flow_manager.request_transition(target_state)


func _apply_startup_resolution() -> void:
	apply_resolution_by_index(0)


func _apply_startup_window_mode() -> void:
	apply_fullscreen_mode(false)


func _apply_window_size(size: Vector2i) -> bool:
	var root_window: Window = get_window()
	if root_window == null:
		return false
	root_window.size = size
	_center_window(root_window, size)
	return true


func _resolve_windowed_size_for_display(requested_size: Vector2i) -> Vector2i:
	if requested_size.x <= 0 or requested_size.y <= 0:
		return BASE_UI_REFERENCE_RESOLUTION
	var display_size: Vector2i = _get_primary_display_size()
	if display_size.x <= 0 or display_size.y <= 0:
		return requested_size
	if requested_size.x <= display_size.x and requested_size.y <= display_size.y:
		return requested_size
	var scale_x: float = float(display_size.x) / float(requested_size.x)
	var scale_y: float = float(display_size.y) / float(requested_size.y)
	var scale: float = min(scale_x, scale_y)
	return Vector2i(
		max(1, int(floor(float(requested_size.x) * scale))),
		max(1, int(floor(float(requested_size.y) * scale)))
	)


func _center_window(root_window: Window, window_size: Vector2i) -> void:
	var display_size: Vector2i = _get_primary_display_size()
	if display_size.x <= 0 or display_size.y <= 0:
		return
	root_window.position = Vector2i(
		max(0, int((display_size.x - window_size.x) * 0.5)),
		max(0, int((display_size.y - window_size.y) * 0.5))
	)


func _get_current_window_size() -> Vector2i:
	var root_window: Window = get_window()
	if root_window == null:
		return Vector2i.ZERO
	return root_window.size


func _get_primary_display_size() -> Vector2i:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	if screen_size.x <= 0 or screen_size.y <= 0:
		return Vector2i.ZERO
	return screen_size


func _apply_fullscreen_mode(enabled: bool) -> bool:
	var root_window: Window = get_window()
	if root_window == null:
		return false
	root_window.borderless = false
	root_window.mode = Window.MODE_WINDOWED
	var restored_window_size: Vector2i = _resolve_windowed_size_for_display(BASE_UI_REFERENCE_RESOLUTION)
	root_window.size = restored_window_size
	_center_window(root_window, restored_window_size)
	_is_fullscreen = false
	return true


func _load_fullscreen_setting() -> bool:
	return false


func _save_fullscreen_setting(enabled: bool) -> void:
	_is_fullscreen = false


func _route_restore_state(active_flow_state: int) -> void:
	var scene_router = get_node_or_null("/root/SceneRouter")
	if scene_router != null:
		scene_router.route_to_state_for_restore(active_flow_state)

