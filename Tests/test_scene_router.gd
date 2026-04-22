# Layer: Tests
extends SceneTree
class_name TestSceneRouter

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const OverlayFlowContractScript = preload("res://Game/Application/overlay_flow_contract.gd")
const MapOverlayContractScript = preload("res://Game/UI/map_overlay_contract.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_ensure_autoload_like_nodes()
	await _route_to_clean_map()
	await test_missing_support_overlay_state_recovers_to_map()
	await _route_to_clean_map()
	await test_missing_reward_overlay_state_recovers_to_map()
	await _route_to_clean_map()
	await test_missing_level_up_overlay_state_recovers_to_map()
	await _route_to_clean_map()
	await test_missing_event_overlay_state_stays_on_map()
	await _route_to_clean_map()
	await test_map_overlay_sync_skips_empty_support_overlay()
	await _route_to_clean_map()
	await test_map_overlay_sync_skips_empty_reward_overlay()
	await _route_to_clean_map()
	await test_map_overlay_sync_skips_empty_level_up_overlay()
	await _route_to_clean_map()
	await test_map_overlay_sync_skips_empty_event_overlay()
	print("test_scene_router: all assertions passed")
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func test_missing_support_overlay_state_recovers_to_map() -> void:
	var bootstrap: Node = _get_bootstrap()
	var scene_router: Node = _get_scene_router()
	var flow_manager: Node = bootstrap.get_flow_manager()
	assert(bootstrap.get_support_interaction_state() == null, "Expected support test precondition to start without a runtime support state.")
	assert(flow_manager.restore_state(FlowStateScript.Type.SUPPORT_INTERACTION).get("ok", false), "Expected support-state restore to succeed for router recovery coverage.")
	scene_router.route_to_state_for_restore(FlowStateScript.Type.SUPPORT_INTERACTION)
	await _wait_for_map_without_overlay()
	assert(int(flow_manager.get_current_state()) == FlowStateScript.Type.MAP_EXPLORE, "Expected missing support overlay state to normalize back to MapExplore.")
	assert(_get_visible_overlay_root() == null, "Expected support overlay recovery path not to leave a visible popup behind.")


func test_missing_reward_overlay_state_recovers_to_map() -> void:
	var bootstrap: Node = _get_bootstrap()
	var scene_router: Node = _get_scene_router()
	var flow_manager: Node = bootstrap.get_flow_manager()
	assert(bootstrap.get_reward_state() == null, "Expected reward test precondition to start without a runtime reward state.")
	assert(flow_manager.restore_state(FlowStateScript.Type.REWARD).get("ok", false), "Expected reward-state restore to succeed for router recovery coverage.")
	scene_router.route_to_state_for_restore(FlowStateScript.Type.REWARD)
	await _wait_for_map_without_overlay()
	assert(int(flow_manager.get_current_state()) == FlowStateScript.Type.MAP_EXPLORE, "Expected missing reward overlay state to normalize back to MapExplore.")
	assert(_get_visible_overlay_root() == null, "Expected reward overlay recovery path not to leave a visible popup behind.")


func test_missing_level_up_overlay_state_recovers_to_map() -> void:
	var bootstrap: Node = _get_bootstrap()
	var scene_router: Node = _get_scene_router()
	var flow_manager: Node = bootstrap.get_flow_manager()
	assert(bootstrap.get_level_up_state() == null, "Expected level-up test precondition to start without a runtime level-up state.")
	assert(flow_manager.restore_state(FlowStateScript.Type.LEVEL_UP).get("ok", false), "Expected level-up restore to succeed for router recovery coverage.")
	scene_router.route_to_state_for_restore(FlowStateScript.Type.LEVEL_UP)
	await _wait_for_map_without_overlay()
	assert(int(flow_manager.get_current_state()) == FlowStateScript.Type.MAP_EXPLORE, "Expected missing level-up overlay state to normalize back to MapExplore.")
	assert(_get_visible_overlay_root() == null, "Expected level-up overlay recovery path not to leave a visible popup behind.")


func test_missing_event_overlay_state_stays_on_map() -> void:
	var bootstrap: Node = _get_bootstrap()
	var scene_router: Node = _get_scene_router()
	var flow_manager: Node = bootstrap.get_flow_manager()
	assert(bootstrap.get_event_state() == null, "Expected event test precondition to start without a runtime event state.")
	assert(int(flow_manager.get_current_state()) == FlowStateScript.Type.MAP_EXPLORE, "Expected event recovery coverage to begin from MapExplore.")
	scene_router.route_to_state_for_restore(FlowStateScript.Type.EVENT)
	await _wait_for_map_without_overlay()
	assert(int(flow_manager.get_current_state()) == FlowStateScript.Type.MAP_EXPLORE, "Expected missing event overlay route not to disturb the active MapExplore state.")
	assert(_get_visible_overlay_root() == null, "Expected missing event overlay route not to create a visible popup.")


func test_map_overlay_sync_skips_empty_support_overlay() -> void:
	await _assert_map_overlay_sync_skips_empty_state(FlowStateScript.Type.SUPPORT_INTERACTION)


func test_map_overlay_sync_skips_empty_reward_overlay() -> void:
	await _assert_map_overlay_sync_skips_empty_state(FlowStateScript.Type.REWARD)


func test_map_overlay_sync_skips_empty_level_up_overlay() -> void:
	await _assert_map_overlay_sync_skips_empty_state(FlowStateScript.Type.LEVEL_UP)


func test_map_overlay_sync_skips_empty_event_overlay() -> void:
	assert(current_scene != null and current_scene.name == "MapExplore", "Expected event overlay guard coverage to run on MapExplore.")
	current_scene.call(OverlayFlowContractScript.OPEN_OVERLAY_FOR_STATE_METHOD, FlowStateScript.Type.EVENT)
	await process_frame
	assert(_get_visible_overlay_root() == null, "Expected map overlay sync to ignore EVENT when its runtime state is missing.")


func _route_to_clean_map() -> void:
	var bootstrap: Node = _get_bootstrap()
	var scene_router: Node = _get_scene_router()
	bootstrap.reset_run_state_for_new_run()
	assert(bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE).get("ok", false), "Expected map restore to succeed before router coverage.")
	scene_router.route_to_state_for_restore(FlowStateScript.Type.MAP_EXPLORE)
	await _wait_for_map_without_overlay()


func _assert_map_overlay_sync_skips_empty_state(flow_state: int) -> void:
	var bootstrap: Node = _get_bootstrap()
	var flow_manager: Node = bootstrap.get_flow_manager()
	assert(int(flow_manager.get_current_state()) == FlowStateScript.Type.MAP_EXPLORE, "Expected map overlay guard coverage to start from MapExplore.")
	assert(current_scene != null and current_scene.name == "MapExplore", "Expected map overlay guard coverage to run on MapExplore.")
	assert(flow_manager.restore_state(flow_state).get("ok", false), "Expected restore_state to accept the overlay flow under test.")
	current_scene.call("_sync_overlays_with_flow_state")
	await process_frame
	assert(_get_visible_overlay_root() == null, "Expected map overlay sync to ignore %s when its runtime state is missing." % FlowStateScript.name_of(flow_state))
	assert(flow_manager.restore_state(FlowStateScript.Type.MAP_EXPLORE).get("ok", false), "Expected cleanup restore to return to MapExplore after overlay guard coverage.")


func _wait_for_map_without_overlay(frame_budget: int = 60) -> void:
	for _step in range(frame_budget):
		await process_frame
		if current_scene != null and current_scene.name == "MapExplore" and _get_visible_overlay_root() == null:
			return
	assert(false, "Expected SceneRouter to land on MapExplore with no active overlay.")


func _ensure_autoload_like_nodes() -> void:
	var root: Window = get_root()
	var bootstrap: Node = root.get_node_or_null("AppBootstrap")
	if bootstrap == null:
		bootstrap = AppBootstrapScript.new()
		bootstrap.name = "AppBootstrap"
		root.add_child(bootstrap)

	var scene_router: Node = root.get_node_or_null("SceneRouter")
	if scene_router == null:
		scene_router = SceneRouterScript.new()
		scene_router.name = "SceneRouter"
		root.add_child(scene_router)


func _get_bootstrap() -> Node:
	return get_root().get_node_or_null("AppBootstrap")


func _get_scene_router() -> Node:
	return get_root().get_node_or_null("SceneRouter")


func _get_visible_overlay_root() -> Node:
	if current_scene == null:
		return null
	for overlay_root_name in MapOverlayContractScript.overlay_root_names():
		var overlay_root: Control = _find_visible_overlay_root(overlay_root_name)
		if overlay_root != null:
			return overlay_root
	return null


func _find_visible_overlay_root(overlay_root_name: String) -> Control:
	if current_scene == null:
		return null
	var exact_match: Control = current_scene.get_node_or_null(overlay_root_name) as Control
	if exact_match != null and exact_match.visible:
		return exact_match
	for child in current_scene.get_children():
		var overlay_root: Control = child as Control
		if overlay_root == null or not overlay_root.visible:
			continue
		if String(overlay_root.name).begins_with(overlay_root_name):
			return overlay_root
	return null
