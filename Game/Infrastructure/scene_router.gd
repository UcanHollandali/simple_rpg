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
	FlowStateScript.Type.RUN_SETUP: "res://scenes/run_setup.tscn",
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
	Callable(self, "_route_to_state").call_deferred(new_state, true)


func _route_to_state(new_state: int, old_state: int = -1, force_reload: bool = false) -> void:
	var current_scene: Node = get_tree().current_scene
	if new_state == FlowStateScript.Type.COMBAT:
		_cleanup_stale_combat_status_hud(current_scene)
		Callable(self, "_cleanup_stale_combat_status_hud").call_deferred()

	# Handle overlay states (event, support, reward, level_up) as popups on MapExplore
	if _is_overlay_state(new_state):
		if _handle_overlay_state_transition(current_scene, new_state, old_state):
			_apply_overlay_scene_scale_if_needed()
			return
	else:
		# Leaving an overlay state: close all overlays on the map
		_close_all_map_overlays(current_scene)

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
	Callable(self, "_open_overlay_on_map_explore").call_deferred(new_state)
	return true


func _open_overlay_on_map_explore(target_state: int) -> void:
	var active_scene: Node = get_tree().current_scene
	if active_scene == null:
		return
	if String(active_scene.scene_file_path) != MAP_EXPLORE_SCENE_PATH:
		return

	var bootstrap = get_node_or_null("/root/AppBootstrap")
	if bootstrap == null:
		return
	var flow_manager = bootstrap.get_flow_manager()
	if flow_manager == null:
		return
	if flow_manager.get_current_state() != target_state:
		return

	var open_method: String = String(OVERLAY_OPEN_METHODS.get(target_state, ""))
	if open_method.is_empty():
		return
	if not active_scene.has_method(open_method):
		return
	active_scene.call_deferred(open_method)


func _close_all_map_overlays(current_scene: Node, immediate: bool = false) -> void:
	if current_scene == null:
		return
	if String(current_scene.scene_file_path) != MAP_EXPLORE_SCENE_PATH:
		return
	for close_method in OVERLAY_CLOSE_METHODS.values():
		var method_name: String = String(close_method)
		if current_scene.has_method(method_name):
			current_scene.call_deferred(method_name, immediate)


func _cleanup_stale_combat_status_hud(reference_scene: Node = null) -> void:
	var scan_roots: Array[Node] = []
	if reference_scene != null and is_instance_valid(reference_scene):
		scan_roots.append(reference_scene)
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene != reference_scene and is_instance_valid(current_scene):
		scan_roots.append(current_scene)
	var tree_root: Node = get_tree().get_root()
	if tree_root != null and is_instance_valid(tree_root):
		scan_roots.append(tree_root)

	var seen_nodes: Dictionary = {}
	for scan_root in scan_roots:
		var stale_cards: Array[Node] = scan_root.find_children("RunSummaryCard", "Node", true, false)
		for stale_card in stale_cards:
			if stale_card == null or not is_instance_valid(stale_card):
				continue
			if not _is_stale_run_summary_card(stale_card):
				continue
			var instance_id: int = stale_card.get_instance_id()
			if seen_nodes.has(instance_id):
				continue
			seen_nodes[instance_id] = true
			stale_card.queue_free()


func _is_stale_run_summary_card(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if String(node.name) != "RunSummaryCard":
		return false
	return (
		node.get_node_or_null("StatsStack/StatusRows/HpRow/HpStatusLabel") != null
		and node.get_node_or_null("StatsStack/StatusRows/HungerRow/HungerStatusLabel") != null
		and (
			node.get_node_or_null("StatsStack/StatusRows/HungerRow/DurabilityStatusLabel") != null
			or node.get_node_or_null("StatsStack/StatusRows/DurabilityRow/DurabilityStatusLabel") != null
		)
	)


func _apply_overlay_scene_scale_if_needed() -> void:
	Callable(self, "_apply_ui_scale_for_current_scene").call_deferred()


func _apply_ui_scale_for_current_scene() -> void:
	var bootstrap = get_node_or_null("/root/AppBootstrap")
	if bootstrap == null:
		return
	if not bootstrap.has_method("apply_ui_scale_to_active_scene"):
		return
	bootstrap.apply_ui_scale_to_active_scene()
