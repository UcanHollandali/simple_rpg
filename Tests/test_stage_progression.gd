# Layer: Tests
extends SceneTree
class_name TestStageProgression

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const GameFlowManagerScript = preload("res://Game/Application/game_flow_manager.gd")
const RunSessionCoordinatorScript = preload("res://Game/Application/run_session_coordinator.gd")
const SaveRuntimeBridgeScript = preload("res://Game/Application/save_runtime_bridge.gd")
const SaveServiceScript = preload("res://Game/Infrastructure/save_service.gd")
const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")
const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")

func _init() -> void:
	test_boss_node_resolution_opens_combat_with_boss_setup()
	test_stage_specific_boss_selection_uses_authored_stage_bosses()
	test_boss_clear_advances_stage()
	test_stage_three_boss_clear_ends_run()
	test_save_snapshot_roundtrip_preserves_key_gate_and_stage_state()
	print("test_stage_progression: all assertions passed")
	quit()


func test_boss_node_resolution_opens_combat_with_boss_setup() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	_prepare_boss_reachable_map_state(run_state, 1)

	var boss_move: Dictionary = coordinator.call("choose_move_to_node", "boss")
	assert(bool(boss_move.get("ok", false)), "Expected unlocked boss traversal to remain available.")
	assert(int(boss_move.get("target_state", -1)) == FlowStateScript.Type.NODE_RESOLVE, "Expected boss traversal to route through NodeResolve before combat.")

	var boss_resolve: Dictionary = coordinator.call("resolve_pending_node")
	assert(String(boss_resolve.get("pending_node_type", "")) == "boss", "Expected boss resolve payload to preserve the pending boss family.")
	assert(int(boss_resolve.get("target_state", -1)) == FlowStateScript.Type.COMBAT, "Expected live boss node resolution to enter Combat.")
	assert(int(flow_manager.call("get_current_state")) == FlowStateScript.Type.COMBAT, "Expected flow state to enter Combat after resolving a boss node.")
	assert(run_state.map_runtime_state.get_current_node_family() == "boss", "Expected the runtime map position to stay on the boss node during combat setup.")

	var combat_setup: Dictionary = coordinator.call("build_combat_setup_data")
	assert(bool(combat_setup.get("ok", false)), "Expected boss combat setup payload to build from coordinator-owned runtime truth.")
	assert(String(combat_setup.get("encounter_node_family", "")) == "boss", "Expected combat setup to expose the authoritative boss encounter family.")
	assert(bool(combat_setup.get("is_boss_combat", false)), "Expected combat setup to expose a boss-specific runtime surface.")
	assert(String(combat_setup.get("enemy_definition_id", "")) == _expected_boss_enemy_definition_id(1), "Expected stage-1 boss combat setup to load the authored stage boss enemy definition.")
	_free_node(flow_manager)


func test_stage_specific_boss_selection_uses_authored_stage_bosses() -> void:
	for stage_index in [2, 3]:
		var flow_manager: Node = GameFlowManagerScript.new()
		flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

		var run_state: RunState = RunStateScript.new()
		run_state.reset_for_new_run()

		var coordinator: RefCounted = RunSessionCoordinatorScript.new()
		coordinator.call("setup", flow_manager, run_state)
		_prepare_boss_reachable_map_state(run_state, stage_index)

		var boss_move: Dictionary = coordinator.call("choose_move_to_node", "boss")
		assert(bool(boss_move.get("ok", false)), "Expected unlocked boss traversal to remain available on stage %d." % stage_index)

		var boss_resolve: Dictionary = coordinator.call("resolve_pending_node")
		assert(int(boss_resolve.get("target_state", -1)) == FlowStateScript.Type.COMBAT, "Expected stage %d boss resolution to enter Combat." % stage_index)

		var combat_setup: Dictionary = coordinator.call("build_combat_setup_data")
		assert(bool(combat_setup.get("ok", false)), "Expected stage %d boss combat setup payload to build." % stage_index)
		assert(
			String(combat_setup.get("enemy_definition_id", "")) == _expected_boss_enemy_definition_id(stage_index),
			"Expected stage %d boss combat setup to use the authored stage boss definition." % stage_index
		)
		_free_node(flow_manager)


func test_boss_clear_advances_stage() -> void:
	var context: Dictionary = _build_boss_ready_context(1)
	var coordinator: RefCounted = context.get("coordinator")
	var run_state: RunState = context.get("run_state")
	var flow_manager: Node = context.get("flow_manager")

	var result: Dictionary = coordinator.call("resolve_combat_result", "victory")
	assert(bool(result.get("ok", false)), "Expected boss victory resolution to succeed.")
	assert(int(result.get("target_state", -1)) == FlowStateScript.Type.STAGE_TRANSITION, "Expected non-final boss clear to advance into StageTransition.")
	assert(run_state.stage_index == 2, "Expected boss clear on stage 1 to advance the run into stage 2.")
	assert(int(flow_manager.call("get_current_state")) == FlowStateScript.Type.STAGE_TRANSITION, "Expected flow state to enter StageTransition after a non-final boss clear.")
	assert(run_state.map_runtime_state.current_node_id == 0, "Expected the next stage graph to reset back to the center-start node.")
	assert(not run_state.map_runtime_state.is_stage_key_resolved(), "Expected stage-local key state to reset for the next stage.")
	_free_node(flow_manager)


func test_stage_three_boss_clear_ends_run() -> void:
	var context: Dictionary = _build_boss_ready_context(3)
	var coordinator: RefCounted = context.get("coordinator")
	var run_state: RunState = context.get("run_state")
	var flow_manager: Node = context.get("flow_manager")

	var result: Dictionary = coordinator.call("resolve_combat_result", "victory")
	assert(bool(result.get("ok", false)), "Expected final boss victory resolution to succeed.")
	assert(int(result.get("target_state", -1)) == FlowStateScript.Type.RUN_END, "Expected stage 3 boss clear to end the run.")
	assert(run_state.stage_index == 3, "Expected final-stage boss clear to leave the run on stage 3 for terminal display.")
	assert(int(flow_manager.call("get_current_state")) == FlowStateScript.Type.RUN_END, "Expected flow state to enter RunEnd after final boss clear.")
	assert(String(coordinator.call("get_last_run_result")) == "victory", "Expected final boss clear to record a victory run result.")
	_free_node(flow_manager)


func test_save_snapshot_roundtrip_preserves_key_gate_and_stage_state() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.stage_index = 2
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var key_node_id: int = _prepare_key_resolved_runtime_state(run_state, run_state.stage_index)

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	var save_service: RefCounted = SaveServiceScript.new()
	var save_runtime_bridge: RefCounted = SaveRuntimeBridgeScript.new()
	save_runtime_bridge.call("setup", flow_manager, run_state, coordinator, save_service)

	var snapshot_result: Dictionary = save_runtime_bridge.call("build_save_snapshot")
	assert(bool(snapshot_result.get("ok", false)), "Expected map snapshot build to succeed for key/gate/stage save coverage.")
	var snapshot: Dictionary = snapshot_result.get("snapshot", {})

	run_state.stage_index = 1
	run_state.map_runtime_state.reset_for_new_run(run_state.stage_index)

	var restore_result: Dictionary = save_runtime_bridge.call("restore_from_snapshot", snapshot)
	assert(bool(restore_result.get("ok", false)), "Expected key/gate/stage snapshot restore to succeed.")
	assert(int(restore_result.get("active_flow_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected restored snapshot to return to MapExplore.")
	assert(run_state.stage_index == 2, "Expected snapshot restore to preserve the current stage index.")
	assert(run_state.map_runtime_state.current_node_id == key_node_id, "Expected snapshot restore to preserve the current key-node position.")
	assert(run_state.map_runtime_state.is_stage_key_resolved(), "Expected snapshot restore to preserve stage-local key ownership.")
	assert(run_state.map_runtime_state.is_boss_gate_unlocked(), "Expected snapshot restore to preserve boss-gate unlock state.")
	assert(
		run_state.map_runtime_state.get_node_state(run_state.map_runtime_state.get_boss_node_id()) != MapRuntimeStateScript.NODE_STATE_LOCKED,
		"Expected snapshot restore to preserve the unlocked boss-gate state."
	)
	_free_node(flow_manager)


func _build_boss_ready_context(stage_index: int) -> Dictionary:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.set("current_state", FlowStateScript.Type.COMBAT)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	_prepare_boss_reachable_map_state(run_state, stage_index)
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	map_runtime_state.move_to_node(map_runtime_state.get_boss_node_id())
	map_runtime_state.mark_node_resolved(map_runtime_state.get_boss_node_id())

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	return {
		"flow_manager": flow_manager,
		"run_state": run_state,
		"coordinator": coordinator,
	}


func _prepare_boss_reachable_map_state(run_state: RunState, stage_index: int) -> void:
	run_state.stage_index = stage_index
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var key_node_id: int = _prepare_key_resolved_runtime_state(run_state, stage_index)
	var boss_node_id: int = map_runtime_state.get_boss_node_id()
	var boss_hub_node_id: int = map_runtime_state.get_adjacent_node_ids(boss_node_id)[0]
	var path_to_boss_hub: Array[int] = _build_path_between_nodes(map_runtime_state, key_node_id, boss_hub_node_id)
	_traverse_path_and_mark_resolved(map_runtime_state, path_to_boss_hub)


func _prepare_key_resolved_runtime_state(run_state: RunState, stage_index: int) -> int:
	run_state.stage_index = stage_index
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	map_runtime_state.reset_for_new_run(stage_index)
	var key_node_id: int = _find_node_id_by_family(map_runtime_state, "key")
	var path_to_key: Array[int] = _build_path_between_nodes(map_runtime_state, map_runtime_state.current_node_id, key_node_id)
	_traverse_path_and_mark_resolved(map_runtime_state, path_to_key)
	map_runtime_state.resolve_stage_key()
	return key_node_id


func _find_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == node_family:
			return int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	return MapRuntimeStateScript.NO_PENDING_NODE_ID


func _traverse_path_and_mark_resolved(map_runtime_state: RefCounted, path: Array[int]) -> void:
	for path_index in range(1, path.size()):
		var node_id: int = path[path_index]
		map_runtime_state.move_to_node(node_id)
		map_runtime_state.mark_node_resolved(node_id)


func _build_path_between_nodes(map_runtime_state: RefCounted, start_node_id: int, target_node_id: int) -> Array[int]:
	var queued_paths: Array = [[start_node_id]]
	var visited: Dictionary = {}
	while not queued_paths.is_empty():
		var path: Array = queued_paths.pop_front()
		var current_node_id: int = int(path[path.size() - 1])
		if current_node_id == target_node_id:
			var typed_path: Array[int] = []
			for node_id_variant in path:
				typed_path.append(int(node_id_variant))
			return typed_path
		if visited.has(current_node_id):
			continue
		visited[current_node_id] = true
		for adjacent_node_id in map_runtime_state.get_adjacent_node_ids(current_node_id):
			if visited.has(adjacent_node_id):
				continue
			var next_path: Array = path.duplicate()
			next_path.append(adjacent_node_id)
			queued_paths.append(next_path)
	return []


func _free_node(node: Node) -> void:
	if node == null:
		return
	node.free()


func _expected_boss_enemy_definition_id(stage_index: int) -> String:
	match stage_index:
		2:
			return "chain_herald"
		3:
			return "briar_sovereign"
		_:
			return "gate_warden"
