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
const PlaytestLoggerScript = preload("res://Game/Infrastructure/playtest_logger.gd")
const RunSessionCoordinatorScript = preload("res://Game/Application/run_session_coordinator.gd")
const SaveRuntimeBridgeScript = preload("res://Game/Application/save_runtime_bridge.gd")

const BASE_UI_REFERENCE_RESOLUTION := Vector2i(1080, 1920)
const WINDOWED_PREVIEW_OVERRIDE_RESOLUTION := Vector2i(540, 960)
const WINDOWED_DISPLAY_SAFE_FRAME_PERCENT_X := 90
const WINDOWED_DISPLAY_SAFE_FRAME_PERCENT_Y := 90
const PLAYTEST_LOG_CMDLINE_ARG := "--playtest-log"

var game_flow_manager: GameFlowManager
var run_state: RunState
var save_service: SaveService
var run_session_coordinator: RunSessionCoordinator
var save_runtime_bridge: SaveRuntimeBridge
var playtest_logger: PlaytestLogger
var _coordinator_bound_flow_manager: GameFlowManager
var _coordinator_bound_run_state: RunState
var _save_bridge_bound_flow_manager: GameFlowManager
var _save_bridge_bound_run_state: RunState
var _save_bridge_bound_run_session_coordinator: RunSessionCoordinator
var _save_bridge_bound_save_service: SaveService


func _ready() -> void:
	apply_resolution_by_index(0)
	apply_fullscreen_mode(false)
	call_deferred("apply_ui_scale_to_active_scene")
	game_flow_manager = _ensure_flow_manager()
	run_state = _ensure_run_state()
	save_service = _ensure_save_service()
	run_session_coordinator = _ensure_run_session_coordinator()
	save_runtime_bridge = _ensure_save_runtime_bridge()
	_initialize_playtest_logger()


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


func apply_fullscreen_mode(_enabled: bool) -> Dictionary:
	var applied: bool = _apply_fullscreen_mode(false)
	if not applied:
		return {"ok": false, "error": "window_unavailable", "fullscreen": false}

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
	var active_run_state: RunState = get_run_state()
	var map_runtime_state: MapRuntimeState = active_run_state.map_runtime_state as MapRuntimeState if active_run_state != null else null
	var from_node_id: int = map_runtime_state.current_node_id if map_runtime_state != null else MapRuntimeStateScript.DEFAULT_NODE_INDEX
	var result: Dictionary = _ensure_run_session_coordinator().choose_move_to_node(node_reference)
	if bool(result.get("ok", false)):
		var current_node_id: int = int(result.get("current_node_id", from_node_id))
		if current_node_id != from_node_id:
			_log_playtest_event("node_transition", {"selected_id": current_node_id})
	return result


func toggle_inventory_equipment(slot_id: int, discard_slot_id: int = -1) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().toggle_inventory_equipment(slot_id, discard_slot_id)


func move_inventory_slot(slot_id: int, target_index: int) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().move_inventory_slot(slot_id, target_index)


func use_inventory_consumable(slot_id: int) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().use_inventory_consumable(slot_id)


func resolve_pending_node() -> Dictionary:
	return _ensure_run_session_coordinator().resolve_pending_node()


func choose_reward_option(option_id: String, discard_slot_id: int = -1, leave_item: bool = false) -> Dictionary:
	ensure_run_state_initialized()
	var result: Dictionary = _ensure_run_session_coordinator().choose_reward_option(option_id, discard_slot_id, leave_item)
	if bool(result.get("ok", false)):
		_log_playtest_event("reward_choice", {"selected_id": option_id})
	return result


func choose_event_option(option_id: String, discard_slot_id: int = -1, leave_item: bool = false) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().choose_event_option(option_id, discard_slot_id, leave_item)


func resolve_combat_result(result: String) -> Dictionary:
	ensure_run_state_initialized()
	var resolve_result: Dictionary = _ensure_run_session_coordinator().resolve_combat_result(result)
	if bool(resolve_result.get("ok", false)):
		_log_playtest_event("combat_result", {"selected_id": result})
	return resolve_result


func choose_level_up_option(option_id: String) -> Dictionary:
	ensure_run_state_initialized()
	var result: Dictionary = _ensure_run_session_coordinator().choose_level_up_option(option_id)
	if bool(result.get("ok", false)):
		var selected_perk_id: String = String(result.get("learned_perk_id", option_id)).strip_edges()
		_log_playtest_event("perk_choice", {"selected_id": selected_perk_id})
	return result


func choose_support_action(action_id: String, discard_slot_id: int = -1) -> Dictionary:
	ensure_run_state_initialized()
	return _ensure_run_session_coordinator().choose_support_action(action_id, discard_slot_id)


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


func _apply_window_size(size: Vector2i) -> bool:
	var root_window: Window = get_window()
	if root_window == null:
		return false
	root_window.size = size
	_center_window(root_window, size)
	return true


func _resolve_windowed_size_for_display(requested_size: Vector2i) -> Vector2i:
	if requested_size.x <= 0 or requested_size.y <= 0:
		return WINDOWED_PREVIEW_OVERRIDE_RESOLUTION
	var display_size: Vector2i = _get_primary_display_size()
	if display_size.x <= 0 or display_size.y <= 0:
		return requested_size
	var safe_display_size: Vector2i = _build_windowed_safe_display_size(display_size)
	if safe_display_size.x <= 0 or safe_display_size.y <= 0:
		return requested_size
	return _resolve_windowed_size_to_available_area(requested_size, safe_display_size)


func _build_windowed_safe_display_size(display_size: Vector2i) -> Vector2i:
	if display_size.x <= 0 or display_size.y <= 0:
		return Vector2i.ZERO
	return Vector2i(
		max(1, int((display_size.x * WINDOWED_DISPLAY_SAFE_FRAME_PERCENT_X) / 100)),
		max(1, int((display_size.y * WINDOWED_DISPLAY_SAFE_FRAME_PERCENT_Y) / 100))
	)


func _resolve_windowed_size_to_available_area(requested_size: Vector2i, available_size: Vector2i) -> Vector2i:
	if requested_size.x <= 0 or requested_size.y <= 0:
		return WINDOWED_PREVIEW_OVERRIDE_RESOLUTION
	if available_size.x <= 0 or available_size.y <= 0:
		return requested_size
	if requested_size.x <= available_size.x and requested_size.y <= available_size.y:
		return requested_size

	var width_bound: bool = available_size.x * requested_size.y <= available_size.y * requested_size.x
	if width_bound:
		return Vector2i(
			available_size.x,
			max(1, int((requested_size.y * available_size.x) / requested_size.x))
		)
	return Vector2i(
		max(1, int((requested_size.x * available_size.y) / requested_size.y)),
		available_size.y
	)


func _center_window(root_window: Window, window_size: Vector2i) -> void:
	var display_size: Vector2i = _get_primary_display_size()
	if display_size.x <= 0 or display_size.y <= 0:
		return
	root_window.position = Vector2i(
		max(0, int((display_size.x - window_size.x) * 0.5)),
		max(0, int((display_size.y - window_size.y) * 0.5))
	)


func _get_primary_display_size() -> Vector2i:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	if screen_size.x <= 0 or screen_size.y <= 0:
		return Vector2i.ZERO
	return screen_size


func _apply_fullscreen_mode(_enabled: bool) -> bool:
	var root_window: Window = get_window()
	if root_window == null:
		return false
	root_window.borderless = false
	root_window.mode = Window.MODE_WINDOWED
	var restored_window_size: Vector2i = _resolve_windowed_size_for_display(BASE_UI_REFERENCE_RESOLUTION)
	root_window.size = restored_window_size
	_center_window(root_window, restored_window_size)
	return true


func _save_fullscreen_setting(_enabled: bool) -> void:
	pass


func _route_restore_state(active_flow_state: int) -> void:
	var scene_router = get_node_or_null("/root/SceneRouter")
	if scene_router != null:
		scene_router.route_to_state_for_restore(active_flow_state)


func _initialize_playtest_logger() -> void:
	playtest_logger = PlaytestLoggerScript.new()
	playtest_logger.setup(_is_playtest_logging_enabled())
	if playtest_logger == null or not playtest_logger.is_enabled():
		return
	if game_flow_manager == null:
		return

	var state_changed_callable: Callable = Callable(self, "_on_playtest_flow_state_changed")
	if not game_flow_manager.flow_state_changed.is_connected(state_changed_callable):
		game_flow_manager.flow_state_changed.connect(state_changed_callable)


func _is_playtest_logging_enabled() -> bool:
	return OS.is_debug_build() or OS.get_cmdline_args().has(PLAYTEST_LOG_CMDLINE_ARG)


func _on_playtest_flow_state_changed(_old_state: int, new_state: int) -> void:
	if new_state != FlowStateScript.Type.RUN_END:
		return

	var selected_id: String = get_last_run_result().strip_edges()
	var event_data: Dictionary = {}
	if not selected_id.is_empty():
		event_data["selected_id"] = selected_id
	_log_playtest_event("run_end", event_data)


func _log_playtest_event(event_type: String, extra_data: Dictionary = {}) -> void:
	if playtest_logger == null or not playtest_logger.is_enabled():
		return
	playtest_logger.log_event(_build_playtest_log_payload(event_type, extra_data))


func _build_playtest_log_payload(event_type: String, extra_data: Dictionary = {}) -> Dictionary:
	var payload: Dictionary = {
		"event_type": event_type,
		"stage_index": 0,
		"hunger": 0,
		"gold": 0,
		"hp": 0,
		"current_node_id": MapRuntimeStateScript.DEFAULT_NODE_INDEX,
	}

	var active_run_state: RunState = get_run_state()
	if active_run_state != null:
		payload["stage_index"] = active_run_state.stage_index
		payload["hunger"] = active_run_state.hunger
		payload["gold"] = active_run_state.gold
		payload["hp"] = active_run_state.player_hp
		var map_runtime_state: MapRuntimeState = active_run_state.map_runtime_state as MapRuntimeState
		if map_runtime_state != null:
			payload["current_node_id"] = map_runtime_state.current_node_id

	payload["event_type"] = event_type
	for key in extra_data.keys():
		payload[key] = extra_data[key]
	return payload
