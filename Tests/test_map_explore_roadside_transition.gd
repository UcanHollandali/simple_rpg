# Layer: Tests
extends SceneTree
class_name TestMapExploreRoadsideTransition

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const MapExploreSceneScript = preload("res://scenes/map_explore.gd")
const MapExplorePackedScene: PackedScene = preload("res://scenes/map_explore.tscn")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	test_map_scene_accepts_deferred_roadside_transition_for_destination_restore()
	await test_map_scene_accepts_deferred_roadside_transition_for_intermediate_map_restore()
	test_map_scene_holds_followup_route_restore_while_roadside_continuation_is_in_flight()
	print("test_map_explore_roadside_transition: all assertions passed")
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func test_map_scene_accepts_deferred_roadside_transition_for_destination_restore() -> void:
	var scene: Control = MapExploreSceneScript.new()
	scene.set("_roadside_visual_state", {
		"current_node_id": 0,
		"target_node_id": 4,
		"progress": 0.58,
		"offset": Vector2.ZERO,
		"target_offset": Vector2(42.0, -18.0),
	})
	var accepted: bool = bool(scene.call(
		"begin_deferred_scene_transition",
		FlowStateScript.Type.REWARD,
		FlowStateScript.Type.EVENT
	))
	assert(
		accepted,
		"Expected roadside destination restores to defer the reward/combat route until the remaining path animation finishes."
	)
	assert(
		bool(scene.get("_roadside_transition_in_flight")),
		"Expected deferred roadside destination restores to flag the in-flight continuation beat."
	)
	_free_node(scene)


func test_map_scene_accepts_deferred_roadside_transition_for_intermediate_map_restore() -> void:
	var bootstrap: AppBootstrapScript = AppBootstrapScript.new()
	bootstrap.name = "AppBootstrap"
	get_root().add_child(bootstrap)
	var scene: Control = MapExplorePackedScene.instantiate() as Control
	assert(scene != null, "Expected full map scene instance for roadside intermediate-restore coverage.")
	get_root().add_child(scene)
	await process_frame
	await process_frame
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.SUPPORT_INTERACTION)
	scene.set("_route_binding", null)
	scene.set("_roadside_visual_state", {
		"current_node_id": 0,
		"target_node_id": 4,
		"progress": 0.58,
		"offset": Vector2.ZERO,
		"target_offset": Vector2(42.0, -18.0),
	})
	var accepted: bool = bool(scene.call(
		"begin_deferred_scene_transition",
		FlowStateScript.Type.MAP_EXPLORE,
		FlowStateScript.Type.EVENT
	))
	assert(
		accepted,
		"Expected roadside continuation to defer the intermediate MapExplore handoff until the remaining path animation finishes."
	)
	assert(
		bool(scene.get("_roadside_transition_in_flight")),
		"Expected intermediate roadside continuation handoffs to keep the continuation beat flagged as in flight."
	)
	_free_node(scene)
	_free_node(bootstrap)


func test_map_scene_holds_followup_route_restore_while_roadside_continuation_is_in_flight() -> void:
	var scene: Control = MapExploreSceneScript.new()
	scene.set("_roadside_transition_in_flight", true)
	var held: bool = bool(scene.call(
		"begin_deferred_scene_transition",
		FlowStateScript.Type.SUPPORT_INTERACTION,
		FlowStateScript.Type.MAP_EXPLORE
	))
	assert(
		held,
		"Expected follow-up destination restores to stay paused while the roadside continuation beat is already in flight."
	)
	_free_node(scene)


func _free_node(node: Node) -> void:
	if node == null:
		return
	var parent: Node = node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
