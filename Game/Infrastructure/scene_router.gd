# Layer: Infrastructure
extends Node

const FlowStateScript = preload("res://Game/Application/flow_state.gd")

const MAP_EXPLORE_SCENE_PATH := "res://scenes/map_explore.tscn"

# Overlay states: these render as popups on top of MapExplore instead of full scene transitions.
const OVERLAY_STATES: Array[int] = [
	FlowStateScript.Type.EVENT,
	FlowStateScript.Type.SUPPORT_INTERACTION,
	FlowStateScript.Type.REWARD,
	FlowStateScript.Type.LEVEL_UP,
]

const OVERLAY_OPEN_METHODS: Dictionary = {
	FlowStateScript.Type.EVENT: "open_event_overlay",
	FlowStateScript.Type.SUPPORT_INTERACTION: "open_support_overlay",
	FlowStateScript.Type.REWARD: "open_reward_overlay",
	FlowStateScript.Type.LEVEL_UP: "open_level_up_overlay",
}

const OVERLAY_CLOSE_METHODS: Dictionary = {
	FlowStateScript.Type.EVENT: "close_event_overlay",
	FlowStateScript.Type.SUPPORT_INTERACTION: "close_support_overlay",
	FlowStateScript.Type.REWARD: "close_reward_overlay",
	FlowStateScript.Type.LEVEL_UP: "close_level_up_overlay",
}

var scene_map: Dictionary = {
	FlowStateScript.Type.MAIN_MENU: "res://scenes/main_menu.tscn",
	FlowStateScript.Type.MAP_EXPLORE: "res://scenes/map_explore.tscn",
	FlowStateScript.Type.NODE_RESOLVE: "res://scenes/node_resolve.tscn",
	FlowStateScript.Type.COMBAT: "res://scenes/combat.tscn",
	FlowStateScript.Type.EVENT: "res://scenes/event.tscn",
	FlowStateScript.Type.REWARD: "res://scenes/reward.tscn",
	FlowStateScript.Type.LEVEL_UP: "res://scenes/level_up.tscn",
	FlowStateScript.Type.SUPPORT_INTERACTION: "res://scenes/support_interaction.tscn",
	FlowStateScript.Type.STAGE_TRANSITION: "res://scenes/stage_transition.tscn",
	FlowStateScript.Type.RUN_END: "res://scenes/run_end.tscn",
}

var _flow_manager: GameFlowManager


func _ready() -> void:
	Callable(self, "_connect_to_flow_manager").call_deferred()


func _connect_to_flow_manager() -> void:
	var bootstrap = get_node_or_null("/root/AppBootstrap")
	if bootstrap == null:
		push_error("SceneRouter could not find AppBootstrap.")
		return

	_flow_manager = bootstrap.get_flow_manager()
	if _flow_manager == null:
		push_error("SceneRouter could not get GameFlowManager.")
		return

	var state_changed_callable: Callable = Callable(self, "_on_flow_state_changed")
	if not _flow_manager.flow_state_changed.is_connected(state_changed_callable):
		_flow_manager.flow_state_changed.connect(state_changed_callable)

	var current_state: int = _flow_manager.get_current_state()
	if current_state != FlowStateScript.Type.BOOT:
		_route_to_state(current_state)
	Callable(self, "_apply_ui_scale_for_current_scene").call_deferred()


func _on_flow_state_changed(_old_state: int, new_state: int) -> void:
	Callable(self, "_route_to_state").call_deferred(new_state, _old_state)


func route_to_state_for_restore(new_state: int) -> void:
	Callable(self, "_route_to_state").call_deferred(new_state, -1, true)


func _route_to_state(new_state: int, old_state: int = -1, force_reload: bool = false) -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.has_method("begin_deferred_scene_transition"):
		if bool(current_scene.call("begin_deferred_scene_transition", new_state, old_state)):
			return

	# Handle overlay states (event, support, reward, level_up) as popups on MapExplore
	if _is_overlay_state(new_state):
		if not _can_present_overlay_state(new_state):
			_recover_missing_overlay_state(current_scene, new_state)
			return
		if _handle_overlay_state_transition(current_scene, new_state, old_state):
			_apply_overlay_scene_scale_if_needed()
			return
	else:
		# Leaving an overlay state: close all overlays on the map
		_close_all_map_overlays(current_scene, _should_close_overlays_immediately(new_state, old_state))

	if new_state == FlowStateScript.Type.BOOT:
		return
	if not scene_map.has(new_state):
		push_error("SceneRouter missing scene for flow state: %s" % FlowStateScript.name_of(new_state))
		return

	var target_path: String = String(scene_map.get(new_state, ""))
	var next_scene: Node = get_tree().current_scene
	if not force_reload and next_scene != null and String(next_scene.scene_file_path) == target_path:
		return

	var error_code: Error = get_tree().change_scene_to_file(target_path)
	if error_code != OK:
		push_error("Failed to change scene to %s (error %d)." % [target_path, error_code])
		return

	Callable(self, "_apply_ui_scale_for_current_scene").call_deferred()


func _is_overlay_state(state: int) -> bool:
	return OVERLAY_OPEN_METHODS.has(state)


func _can_present_overlay_state(state: int) -> bool:
	var bootstrap = get_node_or_null("/root/AppBootstrap")
	if bootstrap == null:
		return false
	match state:
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


func _recover_missing_overlay_state(current_scene: Node, missing_state: int) -> void:
	push_warning("SceneRouter skipped %s overlay because its runtime state was missing." % FlowStateScript.name_of(missing_state))
	_close_all_map_overlays(current_scene, true)
	if _flow_manager != null and _flow_manager.get_current_state() == missing_state:
		_flow_manager.request_transition(FlowStateScript.Type.MAP_EXPLORE)
		return
	if current_scene != null and String(current_scene.scene_file_path) == MAP_EXPLORE_SCENE_PATH:
		_apply_overlay_scene_scale_if_needed()
		return
	var error_code: Error = get_tree().change_scene_to_file(MAP_EXPLORE_SCENE_PATH)
	if error_code != OK:
		push_error("Failed to recover from missing %s overlay state (error %d)." % [FlowStateScript.name_of(missing_state), error_code])
		return
	Callable(self, "_apply_ui_scale_for_current_scene").call_deferred()


func _should_close_overlays_immediately(new_state: int, old_state: int) -> bool:
	return new_state == FlowStateScript.Type.MAP_EXPLORE and _is_overlay_state(old_state)


func _handle_overlay_state_transition(current_scene: Node, new_state: int, _old_state: int) -> bool:
	if current_scene == null:
		return false

	var open_method: String = String(OVERLAY_OPEN_METHODS.get(new_state, ""))
	if open_method.is_empty():
		return false

	# If already on MapExplore, open overlay directly
	if String(current_scene.scene_file_path) == MAP_EXPLORE_SCENE_PATH:
		_close_all_map_overlays(current_scene, true)
		if current_scene.has_method(open_method):
			current_scene.call_deferred(open_method)
			return true
		return false

	# From any other scene (NodeResolve, Combat, etc.), switch to MapExplore first, then open overlay
	var error_code: Error = get_tree().change_scene_to_file(MAP_EXPLORE_SCENE_PATH)
	if error_code != OK:
		push_error("Failed to route to MapExplore for %s overlay (error %d)." % [open_method, error_code])
		return false
	return true

func _close_all_map_overlays(current_scene: Node, immediate: bool = false) -> void:
	if current_scene == null:
		return
	if String(current_scene.scene_file_path) != MAP_EXPLORE_SCENE_PATH:
		return
	for close_method in OVERLAY_CLOSE_METHODS.values():
		var method_name: String = String(close_method)
		if current_scene.has_method(method_name):
			current_scene.call_deferred(method_name, immediate)


func _apply_overlay_scene_scale_if_needed() -> void:
	Callable(self, "_apply_ui_scale_for_current_scene").call_deferred()


func _apply_ui_scale_for_current_scene() -> void:
	var bootstrap = get_node_or_null("/root/AppBootstrap")
	if bootstrap == null:
		return
	if not bootstrap.has_method("apply_ui_scale_to_active_scene"):
		return
	bootstrap.apply_ui_scale_to_active_scene()
