# Layer: Tests
extends SceneTree
class_name TestSupportNodePersistence

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const GameFlowManagerScript = preload("res://Game/Application/game_flow_manager.gd")
const RunSessionCoordinatorScript = preload("res://Game/Application/run_session_coordinator.gd")
const SaveRuntimeBridgeScript = preload("res://Game/Application/save_runtime_bridge.gd")
const SaveServiceScript = preload("res://Game/Infrastructure/save_service.gd")
const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")


func _init() -> void:
	test_support_node_snapshot_roundtrip_preserves_merchant_local_state()
	print("test_support_node_persistence: all assertions passed")
	quit()


func test_support_node_snapshot_roundtrip_preserves_merchant_local_state() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.gold = 20
	run_state.inventory_state.set_consumable_slots([
		{
			"definition_id": "minor_heal_potion",
			"current_stack": 1,
		},
	])

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	var rest_move: Dictionary = coordinator.call("choose_move_to_node", "rest")
	assert(bool(rest_move.get("ok", false)), "Expected rest traversal to open the merchant branch before snapshot.")
	assert(int(rest_move.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected rest node to open SupportInteraction directly before merchant routing.")
	var leave_rest_result: Dictionary = coordinator.call("choose_support_action", "leave")
	assert(bool(leave_rest_result.get("ok", false)), "Expected leaving rest before merchant routing.")

	var merchant_move: Dictionary = coordinator.call("choose_move_to_node", "merchant")
	assert(bool(merchant_move.get("ok", false)), "Expected merchant traversal before snapshot.")
	assert(int(merchant_move.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected merchant node to open SupportInteraction directly before snapshot.")
	var purchase_result: Dictionary = coordinator.call("choose_support_action", "buy_traveler_bread_x1")
	assert(bool(purchase_result.get("ok", false)), "Expected merchant purchase before snapshot.")
	var leave_result: Dictionary = coordinator.call("choose_support_action", "leave")
	assert(bool(leave_result.get("ok", false)), "Expected leaving merchant before snapshot.")
	var return_to_rest_result: Dictionary = coordinator.call("choose_move_to_node", 3)
	assert(bool(return_to_rest_result.get("ok", false)), "Expected traversal back to the support hub before snapshot.")
	assert(int(return_to_rest_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected resolved rest revisit before snapshot to stay pure traversal.")

	var save_service: RefCounted = SaveServiceScript.new()
	var save_runtime_bridge: RefCounted = SaveRuntimeBridgeScript.new()
	save_runtime_bridge.call("setup", flow_manager, run_state, coordinator, save_service)

	var snapshot_result: Dictionary = save_runtime_bridge.call("build_save_snapshot")
	assert(bool(snapshot_result.get("ok", false)), "Expected snapshot build to succeed after merchant visit exit.")
	var snapshot: Dictionary = snapshot_result.get("snapshot", {})
	var snapshot_run_state: Dictionary = snapshot.get("run_state", {})
	var support_node_states: Array = snapshot_run_state.get("support_node_states", [])
	assert(not support_node_states.is_empty(), "Expected snapshot run-state payload to include support-node persistence state.")

	var restored_flow_manager: Node = GameFlowManagerScript.new()
	var restored_run_state: RunState = RunStateScript.new()
	var restored_coordinator: RefCounted = RunSessionCoordinatorScript.new()
	restored_coordinator.call("setup", restored_flow_manager, restored_run_state)
	var restored_save_runtime_bridge: RefCounted = SaveRuntimeBridgeScript.new()
	restored_save_runtime_bridge.call("setup", restored_flow_manager, restored_run_state, restored_coordinator, save_service)

	var restore_result: Dictionary = restored_save_runtime_bridge.call("restore_from_snapshot", snapshot)
	assert(bool(restore_result.get("ok", false)), "Expected snapshot restore to succeed for support-node persistence.")
	assert(int(restore_result.get("active_flow_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected support-node snapshot restore to return to MapExplore.")

	var revisit_move: Dictionary = restored_coordinator.call("choose_move_to_node", "merchant")
	assert(bool(revisit_move.get("ok", false)), "Expected merchant revisit after snapshot restore.")
	assert(int(revisit_move.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected merchant revisit after snapshot restore to stay pure traversal.")
	assert(restored_coordinator.call("get_support_interaction_state") == null, "Expected merchant revisit after snapshot restore not to reopen support state.")
	_free_node(flow_manager)
	_free_node(restored_flow_manager)


func _free_node(node: Node) -> void:
	if node == null:
		return
	node.free()
