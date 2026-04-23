# Layer: Tests
extends SceneTree
class_name TestEventSavePolicy

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const GameFlowManagerScript = preload("res://Game/Application/game_flow_manager.gd")
const RunSessionCoordinatorScript = preload("res://Game/Application/run_session_coordinator.gd")
const SaveRuntimeBridgeScript = preload("res://Game/Application/save_runtime_bridge.gd")
const SaveServiceScript = preload("res://Game/Infrastructure/save_service.gd")
const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")


func _init() -> void:
	test_event_state_save_is_explicitly_unsupported()
	test_other_non_safe_states_stay_explicitly_unsupported()
	print("test_event_save_policy: all assertions passed")
	quit()


func test_event_state_save_is_explicitly_unsupported() -> void:
	_assert_state_snapshot_is_unsupported(FlowStateScript.Type.EVENT, "Event")


func test_other_non_safe_states_stay_explicitly_unsupported() -> void:
	_assert_state_snapshot_is_unsupported(FlowStateScript.Type.COMBAT, "Combat")
	_assert_state_snapshot_is_unsupported(FlowStateScript.Type.NODE_RESOLVE, "NodeResolve")
	_assert_state_snapshot_is_unsupported(FlowStateScript.Type.BOOT, "Boot")


func _assert_state_snapshot_is_unsupported(flow_state: int, state_name: String) -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	var save_service: SaveService = SaveServiceScript.new()
	var save_runtime_bridge: RefCounted = SaveRuntimeBridgeScript.new()
	save_runtime_bridge.call("setup", flow_manager, run_state, coordinator, save_service)

	flow_manager.current_state = flow_state
	var snapshot_result: Dictionary = save_runtime_bridge.call("build_save_snapshot")
	assert(not bool(snapshot_result.get("ok", true)), "Expected %s flow snapshots to stay unsupported in the current save-safe baseline." % state_name)
	assert(String(snapshot_result.get("error", "")) == "unsupported_save_state", "Expected %s flow snapshot attempts to fail with unsupported_save_state." % state_name)

	var synthetic_snapshot: Dictionary = save_service.create_snapshot(
		"",
		flow_state,
		run_state.to_save_dict(),
		null,
		null,
		null,
		{}
	)
	var validation_result: Dictionary = save_service.validate_snapshot(synthetic_snapshot)
	assert(not bool(validation_result.get("ok", true)), "Expected SaveService validation to reject %s snapshots." % state_name)
	assert(String(validation_result.get("error", "")) == "unsupported_save_state", "Expected %s snapshot validation to fail with unsupported_save_state." % state_name)
	_free_node(flow_manager)


func _free_node(node: Node) -> void:
	if node == null:
		return
	node.free()
