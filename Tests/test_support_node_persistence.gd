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
	test_support_snapshot_roundtrip_preserves_hamlet_training_choice_and_equipped_technique()
	test_support_snapshot_roundtrip_preserves_hamlet_training_skip_path()
	test_leaving_open_hamlet_training_choice_drops_the_same_visit_offer()
	print("test_support_node_persistence: all assertions passed")
	quit()


func test_support_node_snapshot_roundtrip_preserves_merchant_local_state() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(1)
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


func test_support_snapshot_roundtrip_preserves_hamlet_training_choice_and_equipped_technique() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(1)
	run_state.equipped_technique_definition_id = "blood_draw"

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	var hamlet_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	assert(hamlet_node_id >= 0, "Expected one hamlet node for training persistence coverage.")
	run_state.map_runtime_state.save_side_mission_node_runtime_state(hamlet_node_id, {
		"support_type": "hamlet",
		"mission_definition_id": "trail_contract_hunt",
		"mission_type": "hunt_marked_enemy",
		"mission_status": "completed",
		"target_node_id": 2,
		"target_enemy_definition_id": "barbed_hunter",
		"reward_offers": [{
			"offer_id": "claim_traveler_bread",
			"label": "Claim Traveler Bread",
			"effect_type": "claim_side_mission_reward",
			"inventory_family": "consumable",
			"definition_id": "traveler_bread",
			"amount": 1,
			"available": true,
		}],
		"training_step": "",
		"technique_offers": [],
	})
	var persisted_training_offers: Array[Dictionary] = [
			{
				"offer_id": "equip_cleanse_pulse",
				"label": "Take Cleanse Pulse",
				"effect_type": "equip_technique",
				"definition_id": "cleanse_pulse",
				"replaces_definition_id": "blood_draw",
				"available": true,
			},
			{
				"offer_id": "equip_echo_strike",
				"label": "Take Echo Strike",
				"effect_type": "equip_technique",
				"definition_id": "echo_strike",
				"replaces_definition_id": "blood_draw",
				"available": true,
			},
			{
				"offer_id": "skip_hamlet_training",
				"label": "Skip for now",
				"effect_type": "skip_training_choice",
				"available": true,
			},
		]
	run_state.map_runtime_state.save_side_mission_node_runtime_state(hamlet_node_id, run_state.map_runtime_state.get_side_quest_node_runtime_state(hamlet_node_id).merged({
		"technique_offers": persisted_training_offers,
	}, true))
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, hamlet_node_id)
	var hamlet_move: Dictionary = coordinator.call("choose_move_to_node", hamlet_node_id)
	assert(bool(hamlet_move.get("ok", false)), "Expected hamlet traversal before training snapshot.")
	assert(int(hamlet_move.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected completed hamlet revisit to open SupportInteraction before reward claim.")
	var claim_result: Dictionary = coordinator.call("choose_support_action", "claim_traveler_bread")
	assert(bool(claim_result.get("ok", false)), "Expected hamlet reward claim to succeed before snapshotting the open training step.")
	assert(int(claim_result.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected hamlet reward claim to stay inside SupportInteraction for the training choice.")
	var support_state: RefCounted = coordinator.call("get_support_interaction_state")
	assert(support_state != null, "Expected open hamlet training state before snapshot.")
	assert(String(support_state.training_step) == "technique_choice", "Expected hamlet training state to expose the active training step before snapshot.")

	var save_service: RefCounted = SaveServiceScript.new()
	var save_runtime_bridge: RefCounted = SaveRuntimeBridgeScript.new()
	save_runtime_bridge.call("setup", flow_manager, run_state, coordinator, save_service)

	var snapshot_result: Dictionary = save_runtime_bridge.call("build_save_snapshot")
	assert(bool(snapshot_result.get("ok", false)), "Expected support snapshot build to succeed during the open hamlet training step.")
	var snapshot: Dictionary = snapshot_result.get("snapshot", {})
	var snapshot_support_state: Dictionary = snapshot.get("support_interaction_state", {})
	assert(String(snapshot_support_state.get("training_step", "")) == "technique_choice", "Expected support snapshot to keep the active hamlet training step.")
	assert((snapshot_support_state.get("technique_offers", []) as Array).size() == 3, "Expected support snapshot to keep the 2-offer-plus-skip training payload.")
	var snapshot_skip_offer_found: bool = false
	for offer_variant in snapshot_support_state.get("technique_offers", []):
		if typeof(offer_variant) != TYPE_DICTIONARY:
			continue
		if String((offer_variant as Dictionary).get("effect_type", "")) == "skip_training_choice":
			snapshot_skip_offer_found = true
			break
	assert(snapshot_skip_offer_found, "Expected support snapshot to keep the explicit skip_training_choice offer.")
	var snapshot_run_state: Dictionary = snapshot.get("run_state", {})
	assert(String(snapshot_run_state.get("equipped_technique_definition_id", "")) == "blood_draw", "Expected support snapshot to keep the currently equipped technique continuity.")

	var restored_flow_manager: Node = GameFlowManagerScript.new()
	var restored_run_state: RunState = RunStateScript.new()
	var restored_coordinator: RefCounted = RunSessionCoordinatorScript.new()
	restored_coordinator.call("setup", restored_flow_manager, restored_run_state)
	var restored_save_runtime_bridge: RefCounted = SaveRuntimeBridgeScript.new()
	restored_save_runtime_bridge.call("setup", restored_flow_manager, restored_run_state, restored_coordinator, save_service)

	var restore_result: Dictionary = restored_save_runtime_bridge.call("restore_from_snapshot", snapshot)
	assert(bool(restore_result.get("ok", false)), "Expected support snapshot restore to succeed for hamlet training continuity.")
	assert(int(restore_result.get("active_flow_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected hamlet training snapshot restore to reopen SupportInteraction.")
	assert(restored_run_state.equipped_technique_definition_id == "blood_draw", "Expected restored run state to keep the previously equipped technique before the player chooses again.")
	var restored_support_state: RefCounted = restored_coordinator.call("get_support_interaction_state")
	assert(restored_support_state != null, "Expected restored support state for the hamlet training step.")
	assert(String(restored_support_state.training_step) == "technique_choice", "Expected restored support state to keep the active training step.")
	assert(restored_support_state.offers.size() == 3, "Expected restored support state to keep the 2-offer-plus-skip layout.")
	var restored_skip_offer_found: bool = false
	var selected_definition_id: String = ""
	var equip_offer_id: String = ""
	for offer in restored_support_state.offers:
		var typed_offer: Dictionary = offer
		if String(typed_offer.get("effect_type", "")) == "skip_training_choice":
			restored_skip_offer_found = true
		if equip_offer_id.is_empty() and String(typed_offer.get("effect_type", "")) == "equip_technique":
			equip_offer_id = String((offer as Dictionary).get("offer_id", ""))
			selected_definition_id = String((offer as Dictionary).get("definition_id", ""))
	assert(restored_skip_offer_found, "Expected restored hamlet training state to keep the explicit skip path.")
	assert(not equip_offer_id.is_empty() and not selected_definition_id.is_empty(), "Expected restored hamlet training step to keep a selectable technique offer.")
	var training_result: Dictionary = restored_coordinator.call("choose_support_action", equip_offer_id)
	assert(bool(training_result.get("ok", false)), "Expected restored hamlet training choice to resolve successfully.")
	assert(int(training_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected resolved hamlet training choice to return to MapExplore.")
	assert(restored_run_state.equipped_technique_definition_id == selected_definition_id, "Expected restored training choice to equip the selected technique after restore.")
	assert(restored_coordinator.call("get_support_interaction_state") == null, "Expected restored hamlet training choice to close SupportInteraction immediately.")
	_free_node(flow_manager)
	_free_node(restored_flow_manager)


func test_support_snapshot_roundtrip_preserves_hamlet_training_skip_path() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(1)
	run_state.equipped_technique_definition_id = "blood_draw"

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	var hamlet_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	assert(hamlet_node_id >= 0, "Expected one hamlet node for training skip persistence coverage.")
	run_state.map_runtime_state.save_side_mission_node_runtime_state(hamlet_node_id, {
		"support_type": "hamlet",
		"mission_definition_id": "trail_contract_hunt",
		"mission_type": "hunt_marked_enemy",
		"mission_status": "completed",
		"target_node_id": 2,
		"target_enemy_definition_id": "barbed_hunter",
		"reward_offers": [{
			"offer_id": "claim_traveler_bread",
			"label": "Claim Traveler Bread",
			"effect_type": "claim_side_mission_reward",
			"inventory_family": "consumable",
			"definition_id": "traveler_bread",
			"amount": 1,
			"available": true,
		}],
		"training_step": "",
		"technique_offers": [{
			"offer_id": "equip_cleanse_pulse",
			"label": "Take Cleanse Pulse",
			"effect_type": "equip_technique",
			"definition_id": "cleanse_pulse",
			"replaces_definition_id": "blood_draw",
			"available": true,
		}, {
			"offer_id": "equip_echo_strike",
			"label": "Take Echo Strike",
			"effect_type": "equip_technique",
			"definition_id": "echo_strike",
			"replaces_definition_id": "blood_draw",
			"available": true,
		}, {
			"offer_id": "skip_hamlet_training",
			"label": "Skip for now",
			"effect_type": "skip_training_choice",
			"available": true,
		}],
	})
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, hamlet_node_id)
	var hamlet_move: Dictionary = coordinator.call("choose_move_to_node", hamlet_node_id)
	assert(bool(hamlet_move.get("ok", false)), "Expected hamlet traversal before training-skip snapshot.")
	assert(int(hamlet_move.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected completed hamlet revisit to open SupportInteraction before reward claim.")
	var claim_result: Dictionary = coordinator.call("choose_support_action", "claim_traveler_bread")
	assert(bool(claim_result.get("ok", false)), "Expected hamlet reward claim to succeed before snapshotting the open training-skip step.")
	assert(int(claim_result.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected hamlet reward claim to stay inside SupportInteraction for the training choice.")

	var save_service: RefCounted = SaveServiceScript.new()
	var save_runtime_bridge: RefCounted = SaveRuntimeBridgeScript.new()
	save_runtime_bridge.call("setup", flow_manager, run_state, coordinator, save_service)
	var snapshot_result: Dictionary = save_runtime_bridge.call("build_save_snapshot")
	assert(bool(snapshot_result.get("ok", false)), "Expected support snapshot build to succeed during the open hamlet training-skip step.")
	var snapshot: Dictionary = snapshot_result.get("snapshot", {})

	var restored_flow_manager: Node = GameFlowManagerScript.new()
	var restored_run_state: RunState = RunStateScript.new()
	var restored_coordinator: RefCounted = RunSessionCoordinatorScript.new()
	restored_coordinator.call("setup", restored_flow_manager, restored_run_state)
	var restored_save_runtime_bridge: RefCounted = SaveRuntimeBridgeScript.new()
	restored_save_runtime_bridge.call("setup", restored_flow_manager, restored_run_state, restored_coordinator, save_service)

	var restore_result: Dictionary = restored_save_runtime_bridge.call("restore_from_snapshot", snapshot)
	assert(bool(restore_result.get("ok", false)), "Expected support snapshot restore to succeed for hamlet training skip continuity.")
	assert(int(restore_result.get("active_flow_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected hamlet training skip snapshot restore to reopen SupportInteraction.")
	assert(restored_run_state.equipped_technique_definition_id == "blood_draw", "Expected restored run state to keep the previously equipped technique before a skip.")
	var restored_support_state: RefCounted = restored_coordinator.call("get_support_interaction_state")
	assert(restored_support_state != null, "Expected restored support state for the hamlet training skip step.")
	var skip_offer_id: String = ""
	for offer in restored_support_state.offers:
		if String((offer as Dictionary).get("effect_type", "")) == "skip_training_choice":
			skip_offer_id = String((offer as Dictionary).get("offer_id", ""))
			break
	assert(not skip_offer_id.is_empty(), "Expected restored hamlet training skip step to keep the explicit skip offer.")
	var skip_result: Dictionary = restored_coordinator.call("choose_support_action", skip_offer_id)
	assert(bool(skip_result.get("ok", false)), "Expected restored hamlet training skip choice to resolve successfully.")
	assert(int(skip_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected skipping the restored hamlet training choice to return to MapExplore.")
	assert(restored_run_state.equipped_technique_definition_id == "blood_draw", "Expected skipping hamlet training to preserve the previously equipped technique.")
	assert(restored_coordinator.call("get_support_interaction_state") == null, "Expected restored hamlet training skip choice to close SupportInteraction immediately.")
	_free_node(flow_manager)
	_free_node(restored_flow_manager)


func test_leaving_open_hamlet_training_choice_drops_the_same_visit_offer() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(1)
	run_state.equipped_technique_definition_id = "blood_draw"

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	var hamlet_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	assert(hamlet_node_id >= 0, "Expected one hamlet node for same-visit training-leave coverage.")
	run_state.map_runtime_state.save_side_mission_node_runtime_state(hamlet_node_id, {
		"support_type": "hamlet",
		"mission_definition_id": "trail_contract_hunt",
		"mission_type": "hunt_marked_enemy",
		"mission_status": "completed",
		"target_node_id": 2,
		"target_enemy_definition_id": "barbed_hunter",
		"reward_offers": [{
			"offer_id": "claim_traveler_bread",
			"label": "Claim Traveler Bread",
			"effect_type": "claim_side_mission_reward",
			"inventory_family": "consumable",
			"definition_id": "traveler_bread",
			"amount": 1,
			"available": true,
		}],
		"training_step": "",
		"technique_offers": [{
			"offer_id": "equip_cleanse_pulse",
			"label": "Take Cleanse Pulse",
			"effect_type": "equip_technique",
			"definition_id": "cleanse_pulse",
			"replaces_definition_id": "blood_draw",
			"available": true,
		}, {
			"offer_id": "equip_echo_strike",
			"label": "Take Echo Strike",
			"effect_type": "equip_technique",
			"definition_id": "echo_strike",
			"replaces_definition_id": "blood_draw",
			"available": true,
		}, {
			"offer_id": "skip_hamlet_training",
			"label": "Skip for now",
			"effect_type": "skip_training_choice",
			"available": true,
		}],
	})
	var path_to_hamlet: Array[int] = _build_path_between_nodes(run_state.map_runtime_state, int(run_state.map_runtime_state.current_node_id), hamlet_node_id)
	assert(path_to_hamlet.size() >= 2, "Expected a valid path to the hamlet before same-visit leave coverage.")
	var approach_node_id: int = path_to_hamlet[path_to_hamlet.size() - 2]
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, hamlet_node_id)
	var hamlet_move: Dictionary = coordinator.call("choose_move_to_node", hamlet_node_id)
	assert(bool(hamlet_move.get("ok", false)), "Expected hamlet traversal before same-visit leave coverage.")
	assert(int(hamlet_move.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected completed hamlet revisit to open SupportInteraction before reward claim.")
	var claim_result: Dictionary = coordinator.call("choose_support_action", "claim_traveler_bread")
	assert(bool(claim_result.get("ok", false)), "Expected hamlet reward claim to succeed before leaving the open training step.")
	assert(int(claim_result.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected reward claim to leave the training choice open in the same visit.")
	var open_training_state: RefCounted = coordinator.call("get_support_interaction_state")
	assert(open_training_state != null and String(open_training_state.training_step) == "technique_choice", "Expected the hamlet training choice to be open before the player leaves.")

	var leave_result: Dictionary = coordinator.call("choose_support_action", "leave")
	assert(bool(leave_result.get("ok", false)), "Expected leaving the open hamlet training step to succeed.")
	assert(int(leave_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected leaving the open hamlet training step to return to MapExplore.")
	assert(coordinator.call("get_support_interaction_state") == null, "Expected leaving the open hamlet training step to close SupportInteraction immediately.")

	var persisted_state: Dictionary = run_state.map_runtime_state.get_side_quest_node_runtime_state(hamlet_node_id)
	assert(String(persisted_state.get("mission_status", "")) == "claimed", "Expected leaving the open hamlet training step to keep the hamlet node in the claimed state.")
	assert(String(persisted_state.get("training_step", "")) == "", "Expected leaving the open hamlet training step to clear the same-visit training marker.")
	assert((persisted_state.get("technique_offers", []) as Array).is_empty(), "Expected leaving the open hamlet training step not to persist training offers for a later revisit.")

	run_state.map_runtime_state.move_to_node(approach_node_id)
	var revisit_result: Dictionary = coordinator.call("choose_move_to_node", hamlet_node_id)
	assert(bool(revisit_result.get("ok", false)), "Expected hamlet revisit after leaving the training step.")
	assert(int(revisit_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected claimed hamlet revisit after leaving training to stay pure traversal.")
	assert(coordinator.call("get_support_interaction_state") == null, "Expected claimed hamlet revisit after leaving training not to reopen SupportInteraction.")
	assert(run_state.equipped_technique_definition_id == "blood_draw", "Expected leaving the training step to preserve the previously equipped technique.")
	_free_node(flow_manager)


func _find_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) != node_family:
			continue
		return int(node_snapshot.get("node_id", -1))
	return -1


func _prepare_current_node_adjacent_to_target(map_runtime_state: RefCounted, target_node_id: int) -> void:
	var path: Array[int] = _build_path_between_nodes(map_runtime_state, int(map_runtime_state.current_node_id), target_node_id)
	assert(path.size() >= 2, "Expected a valid runtime path to target node %d." % target_node_id)
	for path_index in range(1, path.size() - 1):
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
