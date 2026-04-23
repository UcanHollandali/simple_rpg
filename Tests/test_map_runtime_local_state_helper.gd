# Layer: Tests
extends SceneTree
class_name TestMapRuntimeLocalStateHelper

const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	test_hamlet_runtime_state_normalizes_mission_specific_targets()
	print("test_map_runtime_local_state_helper: all assertions passed")
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func test_hamlet_runtime_state_normalizes_mission_specific_targets() -> void:
	var map_runtime_state: RefCounted = MapRuntimeStateScript.new()
	map_runtime_state.reset_for_new_run(1)
	var hamlet_node_id: int = _find_node_id_by_family(map_runtime_state, "hamlet")
	var combat_node_id: int = _find_node_id_by_family(map_runtime_state, "combat")
	var reward_node_id: int = _find_node_id_by_family(map_runtime_state, "reward")
	assert(hamlet_node_id >= 0, "Expected one hamlet node for mission target normalization coverage.")
	assert(combat_node_id >= 0, "Expected one combat node for invalid delivery target coverage.")
	assert(reward_node_id >= 0, "Expected one reward node for bring-proof target normalization coverage.")

	map_runtime_state.save_side_mission_node_runtime_state(hamlet_node_id, {
		"support_type": "hamlet",
		"mission_definition_id": "deliver_supplies",
		"mission_type": "deliver_supplies",
		"mission_status": "accepted",
		"target_node_id": combat_node_id,
		"target_enemy_definition_id": "barbed_hunter",
		"quest_item_definition_id": "supply_bundle",
		"reward_offers": [],
	})

	var normalized_delivery_state: Dictionary = map_runtime_state.get_side_mission_node_runtime_state(hamlet_node_id)
	assert(
		int(normalized_delivery_state.get("target_node_id", 0)) == MapRuntimeStateScript.NO_PENDING_NODE_ID,
		"Expected delivery mission normalization to reject combat targets."
	)
	assert(
		String(normalized_delivery_state.get("target_enemy_definition_id", "")) == "",
		"Expected non-hunt delivery normalization to clear stale enemy target ids."
	)

	map_runtime_state.save_side_mission_node_runtime_state(hamlet_node_id, {
		"support_type": "hamlet",
		"mission_definition_id": "bring_proof",
		"mission_type": "bring_proof",
		"mission_status": "accepted",
		"target_node_id": reward_node_id,
		"target_enemy_definition_id": "barbed_hunter",
		"quest_item_definition_id": "brigand_proof",
		"reward_offers": [],
	})

	var normalized_bring_proof_state: Dictionary = map_runtime_state.get_side_mission_node_runtime_state(hamlet_node_id)
	assert(
		int(normalized_bring_proof_state.get("target_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)) == reward_node_id,
		"Expected bring-proof normalization to preserve reward-family targets."
	)
	assert(
		String(normalized_bring_proof_state.get("target_enemy_definition_id", "")) == "",
		"Expected non-hunt bring-proof normalization to clear stale enemy target ids."
	)


func _find_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == node_family:
			return int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	return MapRuntimeStateScript.NO_PENDING_NODE_ID
