# Layer: Tests
extends SceneTree
class_name TestMapRuntimeState

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const GameFlowManagerScript = preload("res://Game/Application/game_flow_manager.gd")
const RunSessionCoordinatorScript = preload("res://Game/Application/run_session_coordinator.gd")
const SaveRuntimeBridgeScript = preload("res://Game/Application/save_runtime_bridge.gd")
const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const SaveServiceScript = preload("res://Game/Infrastructure/save_service.gd")
const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")
const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")


func _init() -> void:
	test_map_runtime_state_uses_scatter_template_profile_for_stage_one()
	test_map_runtime_state_uses_scatter_template_profile_for_stage_two()
	test_map_runtime_state_uses_scatter_template_profile_for_stage_three()
	test_map_runtime_state_builds_center_start_graph()
	test_map_runtime_state_restricts_movement_to_adjacent_discovered_nodes()
	test_map_runtime_state_reveals_local_neighbors_on_move()
	test_event_node_resolution_opens_dedicated_event_flow()
	test_event_node_revisit_does_not_reopen_primary_value()
	test_reward_node_revisit_does_not_reopen_primary_value()
	test_roadside_encounter_roll_is_rng_deterministic_and_stage_gated()
	test_roadside_encounter_excludes_key_boss_support_families()
	test_content_loader_respects_enemy_authoring_order()
	test_boss_gate_stays_locked_before_key_resolution()
	test_key_resolution_updates_runtime_state_and_unlocks_boss_gate()
	test_support_families_enter_support_interaction_without_node_resolve()
	test_support_node_revisit_stays_traversal_only()
	test_one_shot_support_nodes_stay_traversal_only_after_consumption()
	test_side_mission_accept_marks_target_and_claims_reward()
	test_map_move_at_zero_hunger_costs_hp_and_can_end_the_run()
	test_map_runtime_state_serializes_through_run_state()
	test_legacy_save_snapshot_restores_fixed_template_path()
	test_save_runtime_restore_rejects_disconnected_realized_graph_snapshot()
	test_run_session_coordinator_builds_content_backed_combat_setup()
	print("test_map_runtime_state: all assertions passed")
	quit()


func test_map_runtime_state_uses_scatter_template_profile_for_stage_one() -> void:
	_assert_scatter_runtime_matches_template_profile("procedural_stage_corridor_v1", 1)


func test_map_runtime_state_uses_scatter_template_profile_for_stage_two() -> void:
	_assert_scatter_runtime_matches_template_profile("procedural_stage_openfield_v1", 2)


func test_map_runtime_state_uses_scatter_template_profile_for_stage_three() -> void:
	_assert_scatter_runtime_matches_template_profile("procedural_stage_loop_v1", 3)


func test_map_runtime_state_builds_center_start_graph() -> void:
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var start_adjacents: PackedInt32Array = map_runtime_state.get_adjacent_node_ids(0)

	assert(map_runtime_state.current_node_id == 0, "Expected runtime to anchor map center on node 0.")
	assert(map_runtime_state.get_current_node_family() == "start", "Expected node 0 to stay the start family.")
	assert(map_runtime_state.get_node_state(0) == MapRuntimeStateScript.NODE_STATE_RESOLVED, "Expected the start anchor to be a resolved traversal node.")
	assert(map_runtime_state.get_discovered_node_count() == 1 + start_adjacents.size(), "Expected start to reveal only its adjacent local cluster.")
	assert(map_runtime_state.get_node_count() == 14, "Expected scatter maps to keep the 14-node target node count.")
	assert(map_runtime_state.get_frontier_fog_count() >= 3, "Expected deeper graph nodes to remain under partial fog at run start.")
	assert(map_runtime_state.get_node_state(map_runtime_state.get_boss_node_id()) != MapRuntimeStateScript.NODE_STATE_DISCOVERED, "Expected boss to remain non-discoverable until later.")


func test_map_runtime_state_restricts_movement_to_adjacent_discovered_nodes() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	var undiscovered_node_ids: Array[int] = []
	for node_snapshot in run_state.map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED)) == MapRuntimeStateScript.NODE_STATE_UNDISCOVERED:
			undiscovered_node_ids.append(int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)))
	assert(undiscovered_node_ids.size() > 0, "Expected at least one undiscovered node on graph init.")

	var blocked_move_result: Dictionary = coordinator.call("choose_move_to_node", undiscovered_node_ids[0])
	assert(not bool(blocked_move_result.get("ok", false)), "Expected non-adjacent hidden moves to be rejected.")
	assert(String(blocked_move_result.get("error", "")) == "invalid_map_target", "Expected invalid hidden moves to fail before traversal.")
	_free_node(flow_manager)


func test_map_runtime_state_reveals_local_neighbors_on_move() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	var start_adjacents: PackedInt32Array = run_state.map_runtime_state.get_adjacent_node_ids(0)
	var target_combat_id: int = MapRuntimeStateScript.NO_PENDING_NODE_ID
	for candidate_node_id in start_adjacents:
		if run_state.map_runtime_state.get_node_family(int(candidate_node_id)) == "combat":
			target_combat_id = int(candidate_node_id)
			break
	assert(target_combat_id != MapRuntimeStateScript.NO_PENDING_NODE_ID, "Expected start adjacency to include at least one combat node.")

	var move_result: Dictionary = coordinator.call("choose_move_to_node", target_combat_id)
	assert(bool(move_result.get("ok", false)), "Expected adjacent combat node traversal to succeed.")
	assert(run_state.map_runtime_state.current_node_id == target_combat_id, "Expected movement to advance onto the chosen adjacent node.")
	var discovered_neighbors: int = 0
	for adjacent_node_id in run_state.map_runtime_state.get_adjacent_node_ids(target_combat_id):
		if run_state.map_runtime_state.get_node_state(int(adjacent_node_id)) == MapRuntimeStateScript.NODE_STATE_DISCOVERED:
			discovered_neighbors += 1
	assert(discovered_neighbors > 0, "Expected moving locally to reveal at least one immediate neighbor.")
	assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.NODE_RESOLVE, "Expected unresolved adjacent entries to route through NodeResolve.")
	_free_node(flow_manager)


func test_content_loader_respects_enemy_authoring_order() -> void:
	var loader: ContentLoader = ContentLoaderScript.new()
	var ordered_enemy_ids: Array[String] = loader.list_definition_ids_by_authoring_order("Enemies")
	var expected_enemy_ids: Array[String] = [
		"barbed_hunter",
		"bone_raider",
		"drain_adept",
		"venom_scavenger",
		"skeletal_hound",
		"forest_brigand",
		"gate_warden",
		"ash_gnawer",
		"lantern_cutpurse",
		"mossback_ram",
		"briar_alchemist",
		"chain_trapper",
		"grave_chanter",
		"dusk_pikeman",
		"rotbound_reaver",
		"ember_harrier",
		"chain_herald",
		"briar_sovereign",
	]
	assert(
		ordered_enemy_ids == expected_enemy_ids,
		"Expected enemy authored-order reads to stay stable against JSON-loaded authoring_order values."
	)


func test_event_node_resolution_opens_dedicated_event_flow() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	var event_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "event")
	assert(event_node_id >= 0, "Expected the procedural v1 map to place one event node.")
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, event_node_id)

	var move_result: Dictionary = coordinator.call("choose_move_to_node", event_node_id)
	assert(bool(move_result.get("ok", false)), "Expected adjacent event traversal to succeed.")
	assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.NODE_RESOLVE, "Expected event entry to route through NodeResolve.")

	var resolve_result: Dictionary = coordinator.call("resolve_pending_node")
	assert(int(resolve_result.get("target_state", -1)) == FlowStateScript.Type.EVENT, "Expected event resolution to open the dedicated Event flow.")
	assert(int(flow_manager.call("get_current_state")) == FlowStateScript.Type.EVENT, "Expected flow state to enter Event after resolving an event node.")
	var event_state: RefCounted = coordinator.call("get_event_state")
	assert(event_state != null, "Expected EventState after resolving an event node.")
	assert(String(event_state.template_definition_id) == "forest_shrine_echo", "Expected stage-1 event selection to stay deterministic.")
	assert(event_state.choices.size() == 2, "Expected EventState to expose exactly 2 authored choices.")
	_free_node(flow_manager)


func test_event_node_revisit_does_not_reopen_primary_value() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 40

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	var event_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "event")
	assert(event_node_id >= 0, "Expected one event node for revisit coverage.")
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, event_node_id)

	var move_result: Dictionary = coordinator.call("choose_move_to_node", event_node_id)
	assert(bool(move_result.get("ok", false)), "Expected event traversal to succeed.")
	var resolve_result: Dictionary = coordinator.call("resolve_pending_node")
	assert(int(resolve_result.get("target_state", -1)) == FlowStateScript.Type.EVENT, "Expected first event visit to open Event.")
	var event_state: RefCounted = coordinator.call("get_event_state")
	assert(event_state != null, "Expected EventState before claiming an event outcome.")

	var choice_result: Dictionary = coordinator.call("choose_event_option", "drink_from_the_basin")
	assert(bool(choice_result.get("ok", false)), "Expected healing event choice to resolve successfully.")
	assert(int(choice_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected first event resolution to return to map without extra shells.")
	assert(run_state.player_hp == 50, "Expected healing event choice to update runtime-backed HP.")

	var adjacent_node_id: int = int(run_state.map_runtime_state.get_adjacent_node_ids(event_node_id)[0])
	var leave_event_move: Dictionary = coordinator.call("choose_move_to_node", adjacent_node_id)
	assert(bool(leave_event_move.get("ok", false)), "Expected traversal away from the resolved event node to stay valid.")
	var revisit_move: Dictionary = coordinator.call("choose_move_to_node", event_node_id)
	assert(bool(revisit_move.get("ok", false)), "Expected revisit onto the resolved event node to stay traversable.")
	assert(int(revisit_move.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected resolved event revisit not to reopen Event.")
	assert(coordinator.call("get_event_state") == null, "Expected EventState to remain cleared on event revisit.")
	_free_node(flow_manager)


func test_reward_node_revisit_does_not_reopen_primary_value() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	var reward_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "reward")
	assert(reward_node_id >= 0, "Expected one reward node for revisit coverage.")
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, reward_node_id)

	var move_result: Dictionary = coordinator.call("choose_move_to_node", reward_node_id)
	assert(bool(move_result.get("ok", false)), "Expected reward traversal to succeed.")
	var resolve_result: Dictionary = coordinator.call("resolve_pending_node")
	assert(int(resolve_result.get("target_state", -1)) == FlowStateScript.Type.REWARD, "Expected first reward visit to open Reward.")
	var active_reward_state: RefCounted = coordinator.call("get_reward_state")
	assert(active_reward_state != null, "Expected RewardState before claiming a reward option.")
	assert(active_reward_state.offers.size() == 2, "Expected reward-node revisit coverage to use the current 2-offer reward slice.")
	var chosen_offer_id: String = String(active_reward_state.offers[0].get("offer_id", ""))
	assert(not chosen_offer_id.is_empty(), "Expected reward revisit coverage to find a valid first reward offer id.")

	var choice_result: Dictionary = coordinator.call("choose_reward_option", chosen_offer_id)
	assert(bool(choice_result.get("ok", false)), "Expected reward-node choice to resolve successfully.")
	assert(int(choice_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected first reward resolution to return to map.")

	var adjacent_node_id: int = int(run_state.map_runtime_state.get_adjacent_node_ids(reward_node_id)[0])
	var leave_reward_move: Dictionary = coordinator.call("choose_move_to_node", adjacent_node_id)
	assert(bool(leave_reward_move.get("ok", false)), "Expected traversal away from the resolved reward node to stay valid.")
	var revisit_move: Dictionary = coordinator.call("choose_move_to_node", reward_node_id)
	assert(bool(revisit_move.get("ok", false)), "Expected revisit onto the resolved reward node to stay traversable.")
	assert(int(revisit_move.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected resolved reward revisit not to reopen Reward.")
	assert(coordinator.call("get_reward_state") == null, "Expected RewardState to remain cleared on reward revisit.")
	_free_node(flow_manager)


func test_roadside_encounter_roll_is_rng_deterministic_and_stage_gated() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(123)

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	var map_runtime_state: RefCounted = run_state.map_runtime_state

	var combat_node_ids: Array[int] = []
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == "combat":
			combat_node_ids.append(int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)))
	assert(combat_node_ids.size() > 0, "Expected at least one combat node for roadside-encounter RNG prediction coverage.")
	var target_node_id: int = combat_node_ids[0]
	var target_node_type: String = "combat"
	var target_node_state: String = map_runtime_state.get_node_state(target_node_id)
	var from_node_id: int = map_runtime_state.current_node_id

	var stream_name: String = coordinator.ROADSIDE_ENCOUNTER_STREAM_NAME
	var expected_open: bool = _predict_roadside_open(
		run_state,
		stream_name,
		coordinator.ROADSIDE_ENCOUNTER_TRIGGER_CHANCE,
		from_node_id,
		target_node_id,
		target_node_type,
	)
	var actual_open: bool = bool(coordinator.call(
		"_should_open_roadside_encounter",
		run_state,
		map_runtime_state,
		from_node_id,
		target_node_id,
		target_node_type,
		target_node_state,
	))
	assert(actual_open == expected_open, "Expected roadside RNG check to stay deterministic for the same draw context.")
	assert(map_runtime_state.can_trigger_roadside_encounter(), "Expected roadside encounters to be initially available at stage start.")
	assert(map_runtime_state.consume_roadside_encounter_slot(), "Expected first roadside encounter slot to be consumable when staged.")
	assert(not map_runtime_state.can_trigger_roadside_encounter(), "Expected roadside encounter slot to stop further triggers after quota reach.")
	assert(
		not bool(coordinator.call(
			"_should_open_roadside_encounter",
			run_state,
			map_runtime_state,
			from_node_id,
			target_node_id,
			target_node_type,
			target_node_state,
		)),
		"Expected roadside encounter checks to stay blocked after quota is exhausted."
	)
	_free_node(flow_manager)


func test_roadside_encounter_excludes_key_boss_support_families() -> void:
	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	coordinator.call("setup", flow_manager, run_state)
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var from_node_id: int = map_runtime_state.current_node_id

	var excluded_families: PackedStringArray = ["key", "boss", "support"]
	for excluded_family in excluded_families:
		assert(
			not bool(coordinator.call(
				"_should_open_roadside_encounter",
				run_state,
				map_runtime_state,
				from_node_id,
				MapRuntimeStateScript.NO_PENDING_NODE_ID,
				excluded_family,
				MapRuntimeStateScript.NODE_STATE_DISCOVERED,
			)),
			"Expected %s-family movement to skip roadside encounter source handling." % excluded_family
		)
	_free_node(flow_manager)


func test_boss_gate_stays_locked_before_key_resolution() -> void:
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	var map_runtime_state: RefCounted = run_state.map_runtime_state

	var boss_node_id: int = map_runtime_state.get_boss_node_id()
	_prepare_current_node_adjacent_to_target(map_runtime_state, boss_node_id)

	assert(not map_runtime_state.is_stage_key_resolved(), "Expected the stage key to start unresolved.")
	assert(map_runtime_state.get_node_state(map_runtime_state.get_boss_node_id()) == MapRuntimeStateScript.NODE_STATE_LOCKED, "Expected the boss gate to stay locked before the key is resolved.")
	assert(not map_runtime_state.can_move_to_node(map_runtime_state.get_boss_node_id()), "Expected locked boss access to stay non-traversable before key resolution.")


func test_key_resolution_updates_runtime_state_and_unlocks_boss_gate() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var key_node_id: int = _find_node_id_by_family(map_runtime_state, "key")
	_prepare_current_node_adjacent_to_target(map_runtime_state, key_node_id)

	var key_move: Dictionary = coordinator.call("choose_move_to_node", key_node_id)
	assert(bool(key_move.get("ok", false)), "Expected adjacent key traversal to succeed.")
	assert(int(key_move.get("target_state", -1)) == FlowStateScript.Type.NODE_RESOLVE, "Expected key entry to route through NodeResolve.")

	var key_resolve: Dictionary = coordinator.call("resolve_pending_node")
	assert(int(key_resolve.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected key resolution to return directly to map explore.")
	assert(bool(key_resolve.get("stage_key_resolved", false)), "Expected key resolution to update runtime-owned stage key state.")
	assert(bool(key_resolve.get("boss_gate_unlocked", false)), "Expected key resolution to unlock the boss gate runtime state.")
	assert(run_state.map_runtime_state.is_stage_key_resolved(), "Expected the stage key flag to persist on MapRuntimeState.")
	assert(
		run_state.map_runtime_state.get_node_state(run_state.map_runtime_state.get_boss_node_id()) != MapRuntimeStateScript.NODE_STATE_LOCKED,
		"Expected boss-gate lock state to clear after key resolution even if the boss node was already visible."
	)
	_free_node(flow_manager)


func test_support_families_enter_support_interaction_without_node_resolve() -> void:
	var support_cases: Array[Dictionary] = [
		{
			"stage_index": 1,
			"family": "rest",
			"expected_support_type": "rest",
		},
		{
			"stage_index": 1,
			"family": "merchant",
			"expected_support_type": "merchant",
		},
		{
			"stage_index": 3,
			"family": "blacksmith",
			"expected_support_type": "blacksmith",
		},
		{
			"stage_index": 1,
			"family": "side_mission",
			"expected_support_type": "side_mission",
		},
	]

	for case_variant in support_cases:
		var case_data: Dictionary = case_variant
		var flow_manager: Node = GameFlowManagerScript.new()
		flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

		var transition_sequence: Array[String] = []
		flow_manager.flow_state_changed.connect(func(old_state: int, new_state: int) -> void:
			transition_sequence.append("%s->%s" % [
				FlowStateScript.name_of(old_state),
				FlowStateScript.name_of(new_state),
			])
		)

		var run_state: RunState = RunStateScript.new()
		run_state.reset_for_new_run()
		run_state.stage_index = int(case_data.get("stage_index", 1))
		run_state.map_runtime_state.reset_for_new_run(run_state.stage_index)

		var coordinator: RefCounted = RunSessionCoordinatorScript.new()
		coordinator.call("setup", flow_manager, run_state)

		var target_family: String = String(case_data.get("family", ""))
		var target_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, target_family)
		assert(target_node_id >= 0, "Expected stage %d map to contain %s." % [run_state.stage_index, target_family])
		_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, target_node_id)

		var move_result: Dictionary = coordinator.call("choose_move_to_node", target_node_id)
		assert(bool(move_result.get("ok", false)), "Expected %s traversal to succeed." % target_family)
		assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected %s to target SupportInteraction directly." % target_family)
		assert(int(flow_manager.call("get_current_state")) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected %s traversal to land in SupportInteraction." % target_family)
		assert(
			transition_sequence == ["MAP_EXPLORE->SUPPORT_INTERACTION"],
			"Expected %s traversal to transition directly without NodeResolve, got %s." % [target_family, ", ".join(transition_sequence)]
		)
		var support_state: RefCounted = coordinator.call("get_support_interaction_state")
		assert(support_state != null, "Expected support state after entering %s." % target_family)
		assert(
			String(support_state.support_type) == String(case_data.get("expected_support_type", "")),
			"Expected %s traversal to hydrate support state %s, got %s." % [
				target_family,
				String(case_data.get("expected_support_type", "")),
				String(support_state.support_type),
			]
		)

		_free_node(flow_manager)


func test_support_node_revisit_stays_traversal_only() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.gold = 10
	run_state.inventory_state.set_consumable_slots([
		{
			"definition_id": "wild_berries",
			"current_stack": 1,
		},
	])

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	var merchant_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "merchant")
	assert(merchant_node_id >= 0, "Expected stage 1 procedural fill to include a merchant support node.")
	var rest_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "rest")
	assert(rest_node_id >= 0, "Expected stage 1 map to include a rest support node.")

	var rest_move: Dictionary = coordinator.call("choose_move_to_node", "rest")
	assert(bool(rest_move.get("ok", false)), "Expected rest traversal to open the support-side merchant path.")
	assert(int(rest_move.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected rest traversal to open SupportInteraction directly.")
	assert(coordinator.call("get_support_interaction_state") != null, "Expected support state immediately after entering rest.")
	var leave_rest_result: Dictionary = coordinator.call("choose_support_action", "leave")
	assert(bool(leave_rest_result.get("ok", false)), "Expected leaving rest to keep the branch traversable.")

	var merchant_move: Dictionary = coordinator.call("choose_move_to_node", "merchant")
	assert(bool(merchant_move.get("ok", false)), "Expected merchant move to succeed from the revealed support branch.")
	assert(
		run_state.map_runtime_state.get_node_state(merchant_node_id) == MapRuntimeStateScript.NODE_STATE_RESOLVED,
		"Expected unresolved entries to become resolved once the visit begins in the current placeholder slice."
	)

	assert(int(merchant_move.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected merchant traversal to open the support flow directly.")
	assert(coordinator.call("get_support_interaction_state") != null, "Expected support state after entering the merchant node.")

	var purchase_result: Dictionary = coordinator.call("choose_support_action", "buy_traveler_bread_x1")
	assert(bool(purchase_result.get("ok", false)), "Expected the first merchant purchase to succeed.")
	assert(run_state.inventory_state.consumable_slots.size() == 2, "Expected the first merchant food purchase to add a second stack.")
	assert(String(run_state.inventory_state.consumable_slots[1].get("definition_id", "")) == "traveler_bread", "Expected merchant food purchase to grant traveler bread.")
	assert(int(run_state.inventory_state.consumable_slots[1].get("current_stack", 0)) == 1, "Expected merchant purchase to grant the configured consumable amount once.")

	var leave_result: Dictionary = coordinator.call("choose_support_action", "leave")
	assert(bool(leave_result.get("ok", false)), "Expected the merchant visit to be closable through the support surface.")
	assert(int(leave_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected leaving support to return to map explore.")

	var return_to_rest_result: Dictionary = coordinator.call("choose_move_to_node", rest_node_id)
	assert(bool(return_to_rest_result.get("ok", false)), "Expected traversal back onto the resolved rest node to succeed.")
	assert(int(return_to_rest_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected resolved rest revisit to stay pure traversal.")
	assert(coordinator.call("get_support_interaction_state") == null, "Expected rest revisit not to reopen support state.")

	var revisit_result: Dictionary = coordinator.call("choose_move_to_node", merchant_node_id)
	assert(bool(revisit_result.get("ok", false)), "Expected revisit on a resolved merchant node to stay traversable.")
	assert(int(revisit_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected resolved merchant revisit to stay pure traversal.")
	assert(coordinator.call("get_support_interaction_state") == null, "Expected merchant revisit not to reopen support state.")
	assert(run_state.inventory_state.consumable_slots.size() == 2, "Expected spent merchant offers not to mint extra consumable stacks on revisit.")
	assert(String(run_state.inventory_state.consumable_slots[1].get("definition_id", "")) == "traveler_bread", "Expected the spent merchant food stack to remain stable on revisit.")
	_free_node(flow_manager)


func test_one_shot_support_nodes_stay_traversal_only_after_consumption() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.stage_index = 3
	run_state.map_runtime_state.reset_for_new_run(run_state.stage_index)
	run_state.gold = 20
	run_state.player_hp = 40
	run_state.hunger = 13
	run_state.inventory_state.weapon_instance["current_durability"] = 5

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	var blacksmith_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "blacksmith")
	assert(blacksmith_node_id >= 0, "Expected stage 3 procedural fill to include a blacksmith support node.")
	var rest_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "rest")
	assert(rest_node_id >= 0, "Expected stage 3 map to include a rest support node.")
	var start_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "start")
	assert(start_node_id >= 0, "Expected map to include a start node.")

	var rest_move: Dictionary = coordinator.call("choose_move_to_node", "rest")
	assert(bool(rest_move.get("ok", false)), "Expected initial rest traversal to succeed.")
	assert(int(rest_move.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected initial rest visit to open SupportInteraction directly.")
	var rest_action: Dictionary = coordinator.call("choose_support_action", "rest_once")
	assert(bool(rest_action.get("ok", false)), "Expected first rest action to succeed.")
	assert(run_state.player_hp == 48, "Expected first rest action to heal once.")
	assert(run_state.hunger == 8, "Expected first rest action to spend hunger once after the move cost.")

	var back_to_start_from_rest: Dictionary = coordinator.call("choose_move_to_node", start_node_id)
	assert(bool(back_to_start_from_rest.get("ok", false)), "Expected traversal away from the resolved rest node to succeed.")
	var rest_revisit_move: Dictionary = coordinator.call("choose_move_to_node", rest_node_id)
	assert(bool(rest_revisit_move.get("ok", false)), "Expected revisit onto the resolved rest node to succeed.")
	assert(int(rest_revisit_move.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected resolved rest revisit to stay pure traversal.")
	assert(coordinator.call("get_support_interaction_state") == null, "Expected rest revisit not to reopen support state.")
	assert(run_state.player_hp == 48, "Expected rest revisit not to grant a second heal.")
	assert(run_state.hunger == 6, "Expected rest revisit to pay only the traversal hunger cost.")

	var blacksmith_move: Dictionary = coordinator.call("choose_move_to_node", blacksmith_node_id)
	assert(bool(blacksmith_move.get("ok", false)), "Expected blacksmith traversal to succeed from the revealed support branch.")
	assert(int(blacksmith_move.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected blacksmith node to open SupportInteraction directly.")
	var repair_action: Dictionary = coordinator.call("choose_support_action", "repair_active_weapon")
	assert(bool(repair_action.get("ok", false)), "Expected first blacksmith repair to succeed.")
	assert(run_state.gold == 15, "Expected blacksmith repair to spend gold once.")
	assert(int(run_state.inventory_state.weapon_instance.get("current_durability", 0)) == 20, "Expected blacksmith repair to restore durability once.")

	var back_to_rest_from_blacksmith: Dictionary = coordinator.call("choose_move_to_node", rest_node_id)
	assert(bool(back_to_rest_from_blacksmith.get("ok", false)), "Expected traversal away from the resolved blacksmith node to succeed.")
	assert(int(back_to_rest_from_blacksmith.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected returning through the resolved rest hub to stay pure traversal.")

	var blacksmith_revisit_move: Dictionary = coordinator.call("choose_move_to_node", blacksmith_node_id)
	assert(bool(blacksmith_revisit_move.get("ok", false)), "Expected revisit onto the resolved blacksmith node to succeed.")
	assert(int(blacksmith_revisit_move.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected resolved blacksmith revisit to stay pure traversal.")
	assert(coordinator.call("get_support_interaction_state") == null, "Expected blacksmith revisit not to reopen support state.")
	assert(run_state.gold == 15, "Expected blacksmith revisit not to spend extra gold.")
	assert(int(run_state.inventory_state.weapon_instance.get("current_durability", 0)) == 20, "Expected blacksmith revisit not to grant a second repair.")
	_free_node(flow_manager)


func test_side_mission_accept_marks_target_and_claims_reward() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	var side_mission_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "side_mission")
	assert(side_mission_node_id >= 0, "Expected procedural v1 map generation to place one side-mission node.")
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, side_mission_node_id)

	var move_result: Dictionary = coordinator.call("choose_move_to_node", side_mission_node_id)
	assert(bool(move_result.get("ok", false)), "Expected side-mission traversal to succeed once the node is adjacent.")
	assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected side-mission entry to open SupportInteraction directly.")
	var side_mission_state: RefCounted = coordinator.call("get_support_interaction_state")
	assert(side_mission_state != null, "Expected SupportInteractionState for side mission.")
	assert(String(side_mission_state.support_type) == "side_mission", "Expected side-mission support type.")
	assert(String(side_mission_state.title_text) == "Village Request", "Expected authored side-mission title text.")
	assert(side_mission_state.offers.size() == 1, "Expected offered side mission to expose the accept action only.")

	var accept_result: Dictionary = coordinator.call("choose_support_action", "accept_side_mission")
	assert(bool(accept_result.get("ok", false)), "Expected accepting the side mission to succeed.")
	assert(int(accept_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected accepting the side mission to return directly to the map.")
	assert(coordinator.call("get_support_interaction_state") == null, "Expected side-mission support state to close after accepting the contract.")

	var persisted_side_mission_state: Dictionary = run_state.map_runtime_state.get_side_mission_node_runtime_state(side_mission_node_id)
	assert(String(persisted_side_mission_state.get("mission_status", "")) == "accepted", "Expected accepted side mission to persist on MapRuntimeState.")
	var target_node_id: int = int(persisted_side_mission_state.get("target_node_id", -1))
	var target_enemy_definition_id: String = String(persisted_side_mission_state.get("target_enemy_definition_id", ""))
	assert(target_node_id >= 0, "Expected accepted side mission to bind a target combat node.")
	assert(not target_enemy_definition_id.is_empty(), "Expected accepted side mission to bind a specific target enemy.")
	assert(run_state.map_runtime_state.get_node_state(target_node_id) != MapRuntimeStateScript.NODE_STATE_UNDISCOVERED, "Expected accepted side mission to reveal the marked combat node.")
	var accepted_highlight: Dictionary = run_state.map_runtime_state.build_side_mission_highlight_snapshot()
	assert(int(accepted_highlight.get("node_id", -1)) == target_node_id, "Expected accepted side mission highlight to point at the marked combat node.")
	assert(String(accepted_highlight.get("highlight_state", "")) == "target", "Expected accepted side mission to use the target highlight state.")
	var reward_offers: Array = persisted_side_mission_state.get("reward_offers", [])
	assert(reward_offers.size() == 2, "Expected accepted side mission to prepare exactly 2 reward offers.")
	assert(
		String((reward_offers[0] as Dictionary).get("offer_id", "")) != String((reward_offers[1] as Dictionary).get("offer_id", "")),
		"Expected accepted side mission reward offers to be unique."
	)

	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, target_node_id)
	var target_move: Dictionary = coordinator.call("choose_move_to_node", target_node_id)
	assert(bool(target_move.get("ok", false)), "Expected traversal onto the marked combat node to succeed.")
	assert(int(target_move.get("target_state", -1)) == FlowStateScript.Type.NODE_RESOLVE, "Expected marked combat node entry to route through NodeResolve.")
	var combat_resolve: Dictionary = coordinator.call("resolve_pending_node")
	assert(int(combat_resolve.get("target_state", -1)) == FlowStateScript.Type.COMBAT, "Expected marked target combat to open Combat.")

	var combat_setup: Dictionary = coordinator.call("build_combat_setup_data")
	assert(bool(combat_setup.get("ok", false)), "Expected combat setup to succeed for the marked contract fight.")
	assert(
		String(combat_setup.get("enemy_definition_id", "")) == target_enemy_definition_id,
		"Expected accepted side mission target to override the default combat enemy selection."
	)

	var combat_result: Dictionary = coordinator.call("resolve_combat_result", "victory")
	assert(bool(combat_result.get("ok", false)), "Expected marked target victory to resolve successfully.")
	assert(int(combat_result.get("target_state", -1)) == FlowStateScript.Type.REWARD, "Expected marked target victory to keep the normal combat reward flow.")
	var completed_side_mission_state: Dictionary = run_state.map_runtime_state.get_side_mission_node_runtime_state(side_mission_node_id)
	assert(String(completed_side_mission_state.get("mission_status", "")) == "completed", "Expected victory over the marked target to complete the side mission.")
	var completed_highlight: Dictionary = run_state.map_runtime_state.build_side_mission_highlight_snapshot()
	assert(int(completed_highlight.get("node_id", -1)) == side_mission_node_id, "Expected completed side mission highlight to point back at the contract node.")
	assert(String(completed_highlight.get("highlight_state", "")) == "return", "Expected completed side mission to use the return highlight state.")

	var reward_state: RefCounted = coordinator.call("get_reward_state")
	assert(reward_state != null and reward_state.offers.size() == 3, "Expected marked target victory to still grant the normal 3-offer combat reward.")
	var combat_reward_offer_id: String = ""
	for offer_variant in reward_state.offers:
		if typeof(offer_variant) != TYPE_DICTIONARY:
			continue
		var offer: Dictionary = offer_variant
		if String(offer.get("effect_type", "")) == "grant_xp":
			continue
		combat_reward_offer_id = String(offer.get("offer_id", ""))
		break
	if combat_reward_offer_id.is_empty():
		combat_reward_offer_id = String(reward_state.offers[0].get("offer_id", ""))
	var reward_choice_result: Dictionary = coordinator.call("choose_reward_option", combat_reward_offer_id)
	assert(bool(reward_choice_result.get("ok", false)), "Expected standard combat reward choice after marked target victory.")
	if int(reward_choice_result.get("target_state", -1)) == FlowStateScript.Type.LEVEL_UP:
		var level_up_state: RefCounted = coordinator.call("get_level_up_state")
		assert(level_up_state != null and level_up_state.offers.size() > 0, "Expected level-up state when combat reward XP crosses a threshold.")
		var level_up_result: Dictionary = coordinator.call("choose_level_up_option", String(level_up_state.offers[0].get("offer_id", "")))
		assert(bool(level_up_result.get("ok", false)), "Expected post-reward level-up claim to resolve successfully.")
		assert(int(level_up_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected level-up resolution to return to MapExplore before the side-mission turn-in.")
	else:
		assert(int(reward_choice_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected combat reward resolution to return to MapExplore.")

	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, side_mission_node_id)
	var return_move: Dictionary = coordinator.call("choose_move_to_node", side_mission_node_id)
	assert(bool(return_move.get("ok", false)), "Expected return traversal to the completed contract node to succeed.")
	assert(int(return_move.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected completed side mission to reopen SupportInteraction directly for reward claim.")
	var return_support_state: RefCounted = coordinator.call("get_support_interaction_state")
	assert(return_support_state != null, "Expected side-mission return support state.")
	assert(return_support_state.offers.size() == 2, "Expected completed side mission to offer exactly 2 reward claims.")
	var claim_offer: Dictionary = return_support_state.offers[0]
	var claimed_definition_id: String = String(claim_offer.get("definition_id", ""))
	var claim_result: Dictionary = coordinator.call("choose_support_action", String(claim_offer.get("offer_id", "")))
	assert(bool(claim_result.get("ok", false)), "Expected claiming a side-mission reward to succeed.")
	assert(int(claim_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected side-mission reward claim to return directly to the map.")
	assert(_inventory_contains_definition(run_state.inventory_state, claimed_definition_id), "Expected claimed side-mission gear to be added to the shared carried inventory.")
	var claimed_side_mission_state: Dictionary = run_state.map_runtime_state.get_side_mission_node_runtime_state(side_mission_node_id)
	assert(String(claimed_side_mission_state.get("mission_status", "")) == "claimed", "Expected side-mission runtime state to become claimed after reward pickup.")

	var adjacent_node_id: int = int(run_state.map_runtime_state.get_adjacent_node_ids(side_mission_node_id)[0])
	run_state.map_runtime_state.mark_node_resolved(adjacent_node_id)
	var leave_contract_move: Dictionary = coordinator.call("choose_move_to_node", adjacent_node_id)
	assert(bool(leave_contract_move.get("ok", false)), "Expected traversal away from the claimed contract node to stay valid.")
	var revisit_claimed_move: Dictionary = coordinator.call("choose_move_to_node", side_mission_node_id)
	assert(bool(revisit_claimed_move.get("ok", false)), "Expected revisit onto the claimed side-mission node to stay traversable.")
	assert(int(revisit_claimed_move.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected claimed side-mission revisit not to reopen SupportInteraction.")
	assert(coordinator.call("get_support_interaction_state") == null, "Expected no lingering support state after claimed side-mission revisit.")
	_free_node(flow_manager)


func test_map_move_at_zero_hunger_costs_hp_and_can_end_the_run() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 1
	run_state.hunger = 1

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	var move_result: Dictionary = coordinator.call("choose_move_to_node", "combat")
	assert(bool(move_result.get("ok", false)), "Expected adjacent move at low hunger to still resolve.")
	assert(run_state.hunger == 0, "Expected map movement to drain hunger down to zero.")
	assert(run_state.player_hp == 0, "Expected zero-hunger movement to cost 1 HP.")
	assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.RUN_END, "Expected lethal zero-hunger movement to route straight to RunEnd.")
	assert(int(flow_manager.call("get_current_state")) == FlowStateScript.Type.RUN_END, "Expected flow state to switch to RunEnd after lethal map starvation.")
	assert(String(coordinator.call("get_last_run_result")) == "defeat", "Expected lethal map starvation to register as defeat.")
	_free_node(flow_manager)


func test_map_runtime_state_serializes_through_run_state() -> void:
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	var rest_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "rest")
	var merchant_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "merchant")
	var side_mission_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "side_mission")
	var combat_node_ids: Array[int] = _find_node_ids_by_family(run_state.map_runtime_state, "combat")
	var side_mission_target_node_id: int = MapRuntimeStateScript.NO_PENDING_NODE_ID
	for node_id in combat_node_ids:
		if node_id != side_mission_node_id:
			side_mission_target_node_id = node_id
			break
	assert(side_mission_target_node_id != MapRuntimeStateScript.NO_PENDING_NODE_ID, "Expected a combat node for accepted side-mission save payload.")
	run_state.map_runtime_state.save_support_node_runtime_state(rest_node_id, {
		"support_type": "rest",
		"unavailable_offer_ids": ["rest_once"],
	})
	run_state.map_runtime_state.save_support_node_runtime_state(merchant_node_id, {
		"support_type": "merchant",
		"unavailable_offer_ids": ["buy_traveler_bread_x1"],
	})
	run_state.map_runtime_state.save_side_mission_node_runtime_state(side_mission_node_id, {
		"support_type": "side_mission",
		"mission_definition_id": "trail_contract_hunt",
		"mission_status": "accepted",
		"target_node_id": side_mission_target_node_id,
		"target_enemy_definition_id": "barbed_hunter",
		"reward_offers": [
			{
				"offer_id": "claim_emberhook_blade",
				"inventory_family": "weapon",
				"definition_id": "emberhook_blade",
				"available": true,
			},
			{
				"offer_id": "claim_gravehide_plates",
				"inventory_family": "armor",
				"definition_id": "gravehide_plates",
				"available": true,
			},
		],
	})
	assert(run_state.map_runtime_state.consume_roadside_encounter_slot(), "Expected roadside encounter slot to be consumable before serialization.")
	var expected_roadside_encounters_this_stage: int = run_state.map_runtime_state.get_roadside_encounters_this_stage()
	var boss_node_id: int = run_state.map_runtime_state.get_boss_node_id()
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, boss_node_id)
	run_state.map_runtime_state.move_to_node(side_mission_target_node_id)
	run_state.map_runtime_state.mark_node_resolved(side_mission_target_node_id)
	var expected_current_node_id: int = int(run_state.map_runtime_state.current_node_id)

	var save_data: Dictionary = run_state.to_save_dict()
	assert(String(save_data.get("active_map_template_id", "")).contains("procedural_stage_"), "Expected run-state save data to include the active procedural scaffold id.")
	assert(int(save_data.get("current_node_id", -1)) == expected_current_node_id, "Expected run-state save data to include the stable current node id.")
	assert(int(save_data.get("current_node_index", -1)) == expected_current_node_id, "Expected the compatibility node index to mirror the stable current node id.")
	assert(save_data.has("map_realized_graph"), "Expected run-state save data to include the realized map-graph payload.")
	assert(save_data.has("map_node_states"), "Expected run-state save data to include map node-state payload.")
	assert(save_data.has("support_node_states"), "Expected run-state save data to include support-node persistence payload.")
	assert(save_data.has("side_mission_node_states"), "Expected run-state save data to include side-mission persistence payload.")
	assert(int(save_data.get("roadside_encounters_this_stage", -1)) == expected_roadside_encounters_this_stage, "Expected run-state save data to include roadside encounter stage quota progress.")

	var restored_run_state: RunState = RunStateScript.new()
	restored_run_state.load_from_save_dict(save_data)
	assert(restored_run_state.map_runtime_state.current_node_id == expected_current_node_id, "Expected restored MapRuntimeState current node id.")
	assert(restored_run_state.map_runtime_state.get_node_state(side_mission_target_node_id) == MapRuntimeStateScript.NODE_STATE_RESOLVED, "Expected restored map node-state payload to preserve resolved traversal nodes.")
	assert(restored_run_state.map_runtime_state.get_node_state(boss_node_id) == MapRuntimeStateScript.NODE_STATE_LOCKED, "Expected restored map state to preserve discovered locked nodes after local reveal.")
	assert(restored_run_state.map_runtime_state.get_roadside_encounters_this_stage() == expected_roadside_encounters_this_stage, "Expected roadside encounter quota usage to restore through save payload.")
	var restored_rest_state: Dictionary = restored_run_state.map_runtime_state.get_support_node_runtime_state(rest_node_id)
	assert((restored_rest_state.get("unavailable_offer_ids", []) as Array).has("rest_once"), "Expected restored map state to preserve rest-node one-shot persistence by node id.")
	var restored_merchant_state: Dictionary = restored_run_state.map_runtime_state.get_support_node_runtime_state(merchant_node_id)
	assert((restored_merchant_state.get("unavailable_offer_ids", []) as Array).has("buy_traveler_bread_x1"), "Expected restored map state to preserve merchant-local spent offers by node id.")
	var restored_side_mission_state: Dictionary = restored_run_state.map_runtime_state.get_side_mission_node_runtime_state(side_mission_node_id)
	assert(String(restored_side_mission_state.get("mission_status", "")) == "accepted", "Expected restored map state to preserve accepted side-mission status by node id.")
	assert(String(restored_side_mission_state.get("target_enemy_definition_id", "")) == "barbed_hunter", "Expected restored map state to preserve the marked contract enemy by node id.")


func test_legacy_save_snapshot_restores_fixed_template_path() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	var save_service: RefCounted = SaveServiceScript.new()
	var save_runtime_bridge: RefCounted = SaveRuntimeBridgeScript.new()
	save_runtime_bridge.call("setup", flow_manager, run_state, coordinator, save_service)

	var base_run_state: RunState = RunStateScript.new()
	base_run_state.reset_for_new_run()
	var legacy_run_state_data: Dictionary = base_run_state.to_save_dict()
	legacy_run_state_data.erase("active_map_template_id")
	legacy_run_state_data.erase("map_realized_graph")
	legacy_run_state_data["current_node_index"] = 6
	legacy_run_state_data["current_node_id"] = 6
	legacy_run_state_data["stage_key_resolved"] = false
	legacy_run_state_data["boss_gate_unlocked"] = false
	legacy_run_state_data["map_node_states"] = [
		{"node_id": 0, "node_state": MapRuntimeStateScript.NODE_STATE_RESOLVED},
		{"node_id": 1, "node_state": MapRuntimeStateScript.NODE_STATE_RESOLVED},
		{"node_id": 2, "node_state": MapRuntimeStateScript.NODE_STATE_DISCOVERED},
		{"node_id": 3, "node_state": MapRuntimeStateScript.NODE_STATE_DISCOVERED},
		{"node_id": 4, "node_state": MapRuntimeStateScript.NODE_STATE_UNDISCOVERED},
		{"node_id": 5, "node_state": MapRuntimeStateScript.NODE_STATE_DISCOVERED},
		{"node_id": 6, "node_state": MapRuntimeStateScript.NODE_STATE_RESOLVED},
		{"node_id": 7, "node_state": MapRuntimeStateScript.NODE_STATE_UNDISCOVERED},
		{"node_id": 8, "node_state": MapRuntimeStateScript.NODE_STATE_LOCKED},
		{"node_id": 9, "node_state": MapRuntimeStateScript.NODE_STATE_DISCOVERED},
	]
	legacy_run_state_data["support_node_states"] = [
		{
			"node_id": 5,
			"support_type": "blacksmith",
			"unavailable_offer_ids": ["repair_active_weapon"],
		},
	]
	var legacy_snapshot: Dictionary = {
		"save_schema_version": 1,
		"content_version": SaveServiceScript.CONTENT_VERSION,
		"created_at": 1,
		"updated_at": 1,
		"save_type": SaveServiceScript.SAVE_TYPE_SAFE_STATE,
		"active_flow_state": FlowStateScript.Type.MAP_EXPLORE,
		"run_state": legacy_run_state_data,
		"reward_state": null,
		"level_up_state": null,
		"support_interaction_state": null,
		"app_state": {},
	}

	var validation_result: Dictionary = save_service.call("validate_snapshot", legacy_snapshot)
	assert(bool(validation_result.get("ok", false)), "Expected save validation to accept the legacy schema-1 map payload.")
	var restore_result: Dictionary = save_runtime_bridge.call("restore_from_snapshot", legacy_snapshot)
	assert(bool(restore_result.get("ok", false)), "Expected save runtime restore to accept the legacy schema-1 map payload.")
	assert(run_state.map_runtime_state.current_node_id == 6, "Expected legacy save restore to preserve the fixed-template current node id.")
	assert(run_state.map_runtime_state.get_node_family(5) == "blacksmith", "Expected legacy save restore to rebuild the old fixed-template family layout.")
	var restored_blacksmith_state: Dictionary = run_state.map_runtime_state.get_support_node_runtime_state(5)
	assert((restored_blacksmith_state.get("unavailable_offer_ids", []) as Array).has("repair_active_weapon"), "Expected legacy save restore to preserve support persistence on the fixed-template path.")
	_free_node(flow_manager)


func test_save_runtime_restore_rejects_disconnected_realized_graph_snapshot() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	var save_service: RefCounted = SaveServiceScript.new()
	var save_runtime_bridge: RefCounted = SaveRuntimeBridgeScript.new()
	save_runtime_bridge.call("setup", flow_manager, run_state, coordinator, save_service)

	var snapshot: Dictionary = save_service.call(
		"create_snapshot",
		"",
		FlowStateScript.Type.MAP_EXPLORE,
		run_state.to_save_dict(),
		null,
		null,
		null,
		{}
	)
	var snapshot_run_state: Dictionary = (snapshot.get("run_state", {}) as Dictionary).duplicate(true)
	var realized_graph: Array = (snapshot_run_state.get("map_realized_graph", []) as Array).duplicate(true)
	_set_realized_graph_adjacency(realized_graph, 6, [1, 2, 5])
	_set_realized_graph_adjacency(realized_graph, 8, [9])
	_set_realized_graph_adjacency(realized_graph, 9, [8])
	snapshot_run_state["map_realized_graph"] = realized_graph
	snapshot["run_state"] = snapshot_run_state

	var validation_result: Dictionary = save_service.call("validate_snapshot", snapshot)
	assert(not bool(validation_result.get("ok", true)), "Expected disconnected realized graphs to be rejected during snapshot validation.")
	assert(String(validation_result.get("error", "")) == "invalid_map_realized_graph", "Expected disconnected realized graphs to fail with invalid_map_realized_graph.")

	var restore_result: Dictionary = save_runtime_bridge.call("restore_from_snapshot", snapshot)
	assert(not bool(restore_result.get("ok", true)), "Expected direct snapshot restore to reject disconnected realized graphs.")
	assert(String(restore_result.get("error", "")) == "invalid_map_realized_graph", "Expected direct snapshot restore to surface invalid_map_realized_graph.")
	_free_node(flow_manager)


func test_run_session_coordinator_builds_content_backed_combat_setup() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.set("current_state", FlowStateScript.Type.COMBAT)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	var initial_combat_node_ids: Array[int] = _find_node_ids_by_family(run_state.map_runtime_state, "combat")
	assert(initial_combat_node_ids.size() > 0, "Expected stage-1 map to include a combat node.")
	run_state.map_runtime_state.current_node_id = initial_combat_node_ids[0]

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	var loader: ContentLoader = ContentLoaderScript.new()
	var expected_enemy_ids: Array[String] = _expected_live_minor_enemy_ids_for_stage(loader, 1)

	var combat_setup: Dictionary = coordinator.call("build_combat_setup_data")
	assert(bool(combat_setup.get("ok", false)), "Expected combat setup payload to build from coordinator-owned deterministic content.")
	var weapon_definition: Dictionary = combat_setup.get("weapon_definition", {})
	var enemy_definition: Dictionary = combat_setup.get("enemy_definition", {})
	assert(
		String(weapon_definition.get("definition_id", "")) == String(run_state.inventory_state.weapon_instance.get("definition_id", "")),
		"Expected combat setup to use the equipped weapon definition instead of a scene hardcode."
	)
	assert(
		String(enemy_definition.get("definition_id", "")) == expected_enemy_ids[0],
		"Expected first combat setup to use the first authored-order enemy from the active stage-specific pool."
	)

	if expected_enemy_ids.size() > 1:
		assert(initial_combat_node_ids.size() > 1, "Expected stage-1 map to include a second combat node for rotation coverage.")
		run_state.map_runtime_state.current_node_id = initial_combat_node_ids[1]
		var rotated_setup: Dictionary = coordinator.call("build_combat_setup_data")
		var rotated_enemy_definition: Dictionary = rotated_setup.get("enemy_definition", {})
		var expected_index: int = posmod(run_state.map_runtime_state.current_node_id - 1, expected_enemy_ids.size())
		assert(
			String(rotated_enemy_definition.get("definition_id", "")) == expected_enemy_ids[expected_index],
			"Expected stage-specific combat setup rotation to remain deterministic against the current node id."
		)

	run_state.stage_index = 3
	run_state.map_runtime_state.reset_for_new_run(run_state.stage_index)
	var stage_three_combat_node_ids: Array[int] = _find_node_ids_by_family(run_state.map_runtime_state, "combat")
	assert(stage_three_combat_node_ids.size() > 0, "Expected stage-3 map to include a combat node.")
	run_state.map_runtime_state.current_node_id = stage_three_combat_node_ids[0]
	var stage_three_expected_enemy_ids: Array[String] = _expected_live_minor_enemy_ids_for_stage(loader, run_state.stage_index)
	var stage_three_setup: Dictionary = coordinator.call("build_combat_setup_data")
	var stage_three_enemy_definition: Dictionary = stage_three_setup.get("enemy_definition", {})
	assert(
		String(stage_three_enemy_definition.get("definition_id", "")) == stage_three_expected_enemy_ids[0],
		"Expected stage-3 combat setup to switch to the authored stage-3 minor pool."
	)
	_free_node(flow_manager)


func _assert_scatter_runtime_matches_template_profile(template_id: String, stage_index: int) -> void:
	var map_runtime_state: RefCounted = MapRuntimeStateScript.new()
	map_runtime_state.reset_for_new_run(stage_index)
	var save_data: Dictionary = map_runtime_state.to_save_dict()
	assert(String(save_data.get("active_map_template_id", "")) == template_id, "Expected MapRuntimeState to record the active scaffold id in save data.")
	var support_layout: Dictionary = _expected_stage_support_layout(stage_index)
	var expected_late_support_family: String = String(support_layout.get("late_support_family", "merchant"))
	var expected_opening_support_family: String = String(support_layout.get("opening_support_family", "rest"))
	var family_counts: Dictionary = _build_family_counts(map_runtime_state)

	assert(int(map_runtime_state.get_node_count()) == 14, "Expected scatter maps to keep the 14-node target count.")
	assert(int(family_counts.get("start", 0)) == 1, "Expected exactly one start node in scatter maps.")
	assert(int(family_counts.get("combat", 0)) == 6, "Expected scatter maps to keep 6 combat nodes.")
	assert(int(family_counts.get("event", 0)) == 1, "Expected scatter maps to keep 1 dedicated event node.")
	assert(int(family_counts.get("reward", 0)) == 1, "Expected scatter maps to keep 1 reward node.")
	assert(int(family_counts.get("side_mission", 0)) == 1, "Expected scatter maps to keep 1 dedicated side-mission node.")
	assert(int(family_counts.get("key", 0)) == 1, "Expected scatter maps to keep 1 key node.")
	assert(int(family_counts.get("boss", 0)) == 1, "Expected scatter maps to keep 1 boss node.")
	assert(int(family_counts.get(expected_opening_support_family, 0)) == 1, "Expected opening support layout to resolve into one opening support node.")
	assert(int(family_counts.get(expected_late_support_family, 0)) == 1, "Expected late support layout to resolve into one late support node.")

	var depth_by_node_id: Dictionary = _build_depth_map_from_start(map_runtime_state)
	assert(depth_by_node_id.size() == 14, "Expected connected scatter maps to have depth map entries for all 14 nodes.")

	var max_depth: int = 0
	for depth in depth_by_node_id.values():
		max_depth = max(max_depth, int(depth))

	var start_adjacent_count: int = int(map_runtime_state.get_adjacent_node_ids(0).size())
	assert(start_adjacent_count >= 2 and start_adjacent_count <= 4, "Expected controlled center start adjacency to stay in [2, 4].")
	assert(int(_count_same_depth_reconnect_links(map_runtime_state)) >= 1, "Expected scatter topology to include at least one late reconnect link.")
	var start_adjacent_families: Dictionary = {}
	for adjacent_node_id in map_runtime_state.get_adjacent_node_ids(0):
		start_adjacent_families[String(map_runtime_state.get_node_family(int(adjacent_node_id)))] = true
	assert(bool(start_adjacent_families.get("combat", false)), "Expected start adjacency to preserve an early combat route.")
	assert(bool(start_adjacent_families.get("reward", false)), "Expected start adjacency to preserve an early reward route.")
	assert(bool(start_adjacent_families.get(expected_opening_support_family, false)), "Expected start adjacency to preserve an early support route.")

	var degree_counts: Dictionary = {}
	for node_data in map_runtime_state.build_node_snapshots():
		var node_id: int = int(node_data.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var degree: int = int(map_runtime_state.get_adjacent_node_ids(node_id).size())
		degree_counts[degree] = int(degree_counts.get(degree, 0)) + 1
		assert(degree >= 1 and degree <= 4, "Expected controlled scatter nodes to stay within [1, 4] degree.")
	assert(int(degree_counts.get(1, 0)) >= 2, "Expected controlled scatter to include multiple leaf branches.")
	assert(int(degree_counts.get(2, 0)) >= 2, "Expected controlled scatter to include at least two 2-way connectors.")
	assert(int(degree_counts.get(3, 0)) >= 1, "Expected controlled scatter to include branched connectors.")

	assert(_are_all_nodes_reachable_from_start(map_runtime_state), "Expected scatter graph to stay connected to the start node.")
	var key_node_id: int = map_runtime_state.get_stage_key_node_id()
	var boss_node_id: int = map_runtime_state.get_boss_node_id()
	var late_support_node_id: int = _find_node_id_by_family(map_runtime_state, expected_late_support_family)
	var opening_support_node_id: int = _find_node_id_by_family(map_runtime_state, expected_opening_support_family)
	assert(key_node_id >= 0, "Expected scatter maps to include a key node.")
	assert(boss_node_id >= 0, "Expected scatter maps to include a boss node.")
	assert(late_support_node_id >= 0, "Expected scatter maps to include the late support placement.")
	assert(opening_support_node_id >= 0, "Expected scatter maps to include the opening support placement.")
	assert(int(depth_by_node_id.get(key_node_id, -1)) >= max(2, max_depth - 1), "Expected key placement to be biased to outer layers.")
	assert(int(depth_by_node_id.get(boss_node_id, -1)) == max_depth, "Expected boss placement to be pinned near the outer-most layer.")
	assert(map_runtime_state.get_adjacent_node_ids(opening_support_node_id).has(late_support_node_id), "Expected late support placement to stay adjacent to the opening support branch.")
	assert((_build_path_between_nodes(map_runtime_state, key_node_id, boss_node_id).size() - 1) >= 2, "Expected key-to-boss push not to collapse into an immediate adjacent click.")
	assert(int(depth_by_node_id.get(_find_node_id_by_family(map_runtime_state, "side_mission"), -1)) >= 3, "Expected side mission placement to stay on an optional late detour.")


func _expected_stage_support_layout(stage_index: int) -> Dictionary:
	var layouts: Array[Dictionary] = [
		{
			"opening_support_family": "rest",
			"late_support_family": "merchant",
		},
		{
			"opening_support_family": "merchant",
			"late_support_family": "blacksmith",
		},
		{
			"opening_support_family": "rest",
			"late_support_family": "blacksmith",
		},
	]
	var stage_offset: int = max(0, stage_index - 1)
	return (layouts[stage_offset % layouts.size()] as Dictionary).duplicate(true)


func _predict_roadside_open(
	run_state: RunState,
	stream_name: String,
	chance: float,
	from_node_id: int,
	target_node_id: int,
	target_node_type: String,
) -> bool:
	if run_state == null:
		return false
	var draw_index: int = int(run_state.rng_stream_states.get(stream_name, 0))
	var context_salt: String = "%s|from:%d|to:%d|stage:%d" % [
		target_node_type,
		from_node_id,
		target_node_id,
		run_state.stage_index,
	]
	var stream_seed: int = _build_named_stream_seed(run_state.run_seed, stream_name, draw_index, context_salt)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = stream_seed
	return rng.randf() < chance


func _build_named_stream_seed(run_seed: int, stream_name: String, draw_index: int, context_salt: String) -> int:
	var accumulator: int = 216613626
	var seed_value: String = "%d|%s|%d|%s" % [run_seed, stream_name, draw_index, context_salt]
	for byte in seed_value.to_utf8_buffer():
		accumulator = abs(int((accumulator ^ int(byte)) * 16777619))
	if accumulator == 0:
		return 1
	return accumulator


func _build_family_counts(map_runtime_state: RefCounted) -> Dictionary:
	var counts: Dictionary = {}
	for node_snapshot in map_runtime_state.build_node_snapshots():
		var node_family: String = String(node_snapshot.get("node_family", ""))
		counts[node_family] = int(counts.get(node_family, 0)) + 1
	return counts


func _find_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == node_family:
			return int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	return MapRuntimeStateScript.NO_PENDING_NODE_ID


func _prepare_current_node_adjacent_to_target(map_runtime_state: RefCounted, target_node_id: int) -> void:
	var path: Array[int] = _build_path_between_nodes(map_runtime_state, map_runtime_state.current_node_id, target_node_id)
	assert(path.size() >= 2, "Expected a valid runtime path to the target node.")
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


func _find_node_ids_by_family(map_runtime_state: RefCounted, node_family: String) -> Array[int]:
	var node_ids: Array[int] = []
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == node_family:
			node_ids.append(int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)))
	node_ids.sort()
	return node_ids


func _build_depth_map_from_start(map_runtime_state: RefCounted) -> Dictionary:
	var depth_by_node_id: Dictionary = {}
	var visited: Dictionary = {}
	var queue: Array[int] = [map_runtime_state.current_node_id]
	depth_by_node_id[map_runtime_state.current_node_id] = 0
	while not queue.is_empty():
		var node_id: int = queue.pop_front()
		var node_depth: int = int(depth_by_node_id[node_id])
		if visited.has(node_id):
			continue
		visited[node_id] = true
		for adjacent_node_id in map_runtime_state.get_adjacent_node_ids(node_id):
			if depth_by_node_id.has(adjacent_node_id):
				continue
			depth_by_node_id[adjacent_node_id] = node_depth + 1
			queue.append(adjacent_node_id)
	return depth_by_node_id


func _are_all_nodes_reachable_from_start(map_runtime_state: RefCounted) -> bool:
	var all_node_ids: Dictionary = {}
	for node_snapshot in map_runtime_state.build_node_snapshots():
		var node_id: int = int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		all_node_ids[node_id] = true
	if all_node_ids.size() != map_runtime_state.get_node_count():
		return false

	var visited: Dictionary = {}
	var queue: Array[int] = [map_runtime_state.current_node_id]
	visited[map_runtime_state.current_node_id] = true
	while not queue.is_empty():
		var node_id: int = queue.pop_front()
		for adjacent_node_id in map_runtime_state.get_adjacent_node_ids(node_id):
			if visited.has(adjacent_node_id):
				continue
			visited[adjacent_node_id] = true
			queue.append(adjacent_node_id)
	return visited.size() == all_node_ids.size()


func _count_same_depth_reconnect_links(map_runtime_state: RefCounted) -> int:
	var link_count: int = 0
	var depth_by_node_id: Dictionary = _build_depth_map_from_start(map_runtime_state)
	var seen_edges: Dictionary = {}
	for node_snapshot in map_runtime_state.build_node_snapshots():
		var node_id: int = int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		var adjacent_ids: PackedInt32Array = map_runtime_state.get_adjacent_node_ids(node_id)
		for adjacent_node_id in adjacent_ids:
			var adjacent_depth: int = int(depth_by_node_id.get(int(adjacent_node_id), -1))
			var left_id: int = min(node_id, int(adjacent_node_id))
			var right_id: int = max(node_id, int(adjacent_node_id))
			var edge_key: String = "%d:%d" % [left_id, right_id]
			if seen_edges.has(edge_key):
				continue
			seen_edges[edge_key] = true
			if node_depth < 2 or adjacent_depth < 2:
				continue
			if node_depth != adjacent_depth:
				continue
			link_count += 1
	return link_count


func _set_realized_graph_adjacency(realized_graph: Array, node_id: int, adjacent_node_ids: Array) -> void:
	for index in range(realized_graph.size()):
		var entry_variant: Variant = realized_graph[index]
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = (entry_variant as Dictionary).duplicate(true)
		if int(entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)) != node_id:
			continue
		entry["adjacent_node_ids"] = adjacent_node_ids.duplicate()
		realized_graph[index] = entry
		return


func _inventory_contains_definition(inventory_state: InventoryState, definition_id: String) -> bool:
	for slot in inventory_state.inventory_slots:
		if String(slot.get("definition_id", "")) == definition_id:
			return true
	return false


func _free_node(node: Node) -> void:
	if node == null:
		return
	node.free()


func _expected_live_minor_enemy_ids_for_stage(loader: ContentLoader, stage_index: int) -> Array[String]:
	var stage_tag: String = "stage_%d" % max(1, stage_index)
	var stage_specific_ids: Array[String] = []
	var fallback_ids: Array[String] = []
	for definition_id in loader.list_definition_ids_by_authoring_order("Enemies"):
		var enemy_definition: Dictionary = loader.load_definition("Enemies", definition_id)
		if String(enemy_definition.get("encounter_tier", "minor")) == "elite":
			continue
		var tags: Array = enemy_definition.get("tags", [])
		var has_stage_tag: bool = false
		for tag_value in tags:
			if String(tag_value) == stage_tag:
				has_stage_tag = true
				break
		if has_stage_tag:
			stage_specific_ids.append(definition_id)
		else:
			fallback_ids.append(definition_id)
	if not stage_specific_ids.is_empty():
		return stage_specific_ids
	return fallback_ids
