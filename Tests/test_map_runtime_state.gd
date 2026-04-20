# Layer: Tests
extends SceneTree
class_name TestMapRuntimeState

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const GameFlowManagerScript = preload("res://Game/Application/game_flow_manager.gd")
const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")
const RunSessionCoordinatorScript = preload("res://Game/Application/run_session_coordinator.gd")
const SaveRuntimeBridgeScript = preload("res://Game/Application/save_runtime_bridge.gd")
const SupportActionApplicationPolicyScript = preload("res://Game/Application/support_action_application_policy.gd")
const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const SaveServiceScript = preload("res://Game/Infrastructure/save_service.gd")
const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")
const LevelUpStateScript = preload("res://Game/RuntimeState/level_up_state.gd")
const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")
const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const SupportInteractionStateScript = preload("res://Game/RuntimeState/support_interaction_state.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	test_map_runtime_state_uses_scatter_template_profile_for_stage_one()
	test_map_runtime_state_uses_scatter_template_profile_for_stage_two()
	test_map_runtime_state_uses_scatter_template_profile_for_stage_three()
	test_scatter_opening_shell_keeps_short_spur_as_combat_across_seed_sweep()
	test_map_runtime_state_generation_is_deterministic_per_profile()
	test_run_state_map_generation_varies_by_seed_but_stays_deterministic()
	test_map_runtime_state_profile_graphs_stay_distinct()
	test_map_runtime_state_builds_center_start_graph()
	test_map_runtime_state_restricts_movement_to_adjacent_discovered_nodes()
	test_map_runtime_state_reveals_local_neighbors_on_move()
	test_event_node_resolution_opens_dedicated_event_flow()
	test_event_node_revisit_does_not_reopen_primary_value()
	test_reward_node_revisit_does_not_reopen_primary_value()
	test_roadside_encounter_roll_is_rng_deterministic_and_stage_gated()
	test_roadside_encounter_excludes_key_boss_support_families()
	test_roadside_encounter_is_movement_scoped_and_preserves_reward_destination()
	test_roadside_pending_destination_continuation_survives_level_up_restore()
	test_content_loader_respects_enemy_authoring_order()
	test_boss_gate_stays_locked_before_key_resolution()
	test_key_resolution_updates_runtime_state_and_unlocks_boss_gate()
	test_live_map_families_skip_node_resolve_transition_shell()
	test_support_families_enter_support_interaction_without_node_resolve()
	test_support_node_revisit_stays_traversal_only()
	test_one_shot_support_nodes_stay_traversal_only_after_consumption()
	test_hamlet_accept_marks_target_and_claims_reward()
	test_support_interaction_state_uses_seeded_stage_local_merchant_pool()
	test_support_interaction_state_uses_seeded_stage_local_hamlet_pool()
	test_hamlet_nodes_expose_stage_personality()
	test_hamlet_personality_biases_stage_local_request_pool()
	test_hamlet_accept_biases_trade_reward_offers()
	test_hamlet_offer_uses_noncombat_targets_for_delivery_requests()
	test_hamlet_deliver_supplies_completes_on_arrival()
	test_hamlet_rescue_missing_scout_completes_on_arrival()
	test_hamlet_bring_proof_grants_quest_item_on_completion()
	test_map_move_at_zero_hunger_costs_hp_and_can_end_the_run()
	test_map_runtime_state_serializes_through_run_state()
	test_legacy_save_snapshot_restores_fixed_template_path()
	test_save_runtime_restore_rejects_disconnected_realized_graph_snapshot()
	test_run_session_coordinator_builds_content_backed_combat_setup()
	print("test_map_runtime_state: all assertions passed")
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func test_map_runtime_state_uses_scatter_template_profile_for_stage_one() -> void:
	_assert_scatter_runtime_matches_template_profile("procedural_stage_corridor_v1", 1)


func test_map_runtime_state_uses_scatter_template_profile_for_stage_two() -> void:
	_assert_scatter_runtime_matches_template_profile("procedural_stage_openfield_v1", 2)


func test_map_runtime_state_uses_scatter_template_profile_for_stage_three() -> void:
	_assert_scatter_runtime_matches_template_profile("procedural_stage_loop_v1", 3)


func test_scatter_opening_shell_keeps_short_spur_as_combat_across_seed_sweep() -> void:
	for stage_index in [1, 2, 3]:
		for generation_seed in range(0, 32):
			var map_runtime_state: RefCounted = MapRuntimeStateScript.new()
			map_runtime_state.reset_for_new_run(stage_index, generation_seed)
			var support_layout: Dictionary = _expected_stage_support_layout(stage_index)
			var expected_opening_support_family: String = String(support_layout.get("opening_support_family", "rest"))
			var family_counts: Dictionary = _build_family_counts(map_runtime_state)
			var support_count: int = int(family_counts.get("rest", 0)) + int(family_counts.get("merchant", 0)) + int(family_counts.get("blacksmith", 0))
			assert(int(family_counts.get("combat", 0)) == 6, "Expected stage %d seed %d to keep 6 combat nodes." % [stage_index, generation_seed])
			assert(int(family_counts.get("reward", 0)) == 1, "Expected stage %d seed %d to keep 1 reward node." % [stage_index, generation_seed])
			assert(support_count == 2, "Expected stage %d seed %d to keep exactly 2 support nodes." % [stage_index, generation_seed])
			var start_adjacent_families: Dictionary = {}
			var start_adjacent_combat_count: int = 0
			var start_adjacent_leaf_count: int = 0
			var start_adjacent_leaf_family: String = ""
			for adjacent_node_id in map_runtime_state.get_adjacent_node_ids(0):
				var resolved_adjacent_node_id: int = int(adjacent_node_id)
				var adjacent_family: String = String(map_runtime_state.get_node_family(resolved_adjacent_node_id))
				start_adjacent_families[adjacent_family] = true
				if adjacent_family == "combat":
					start_adjacent_combat_count += 1
				if int(map_runtime_state.get_adjacent_node_ids(resolved_adjacent_node_id).size()) == 1:
					start_adjacent_leaf_count += 1
					start_adjacent_leaf_family = adjacent_family
			assert(bool(start_adjacent_families.get("reward", false)), "Expected stage %d seed %d to keep reward on a main opening branch." % [stage_index, generation_seed])
			assert(bool(start_adjacent_families.get(expected_opening_support_family, false)), "Expected stage %d seed %d to keep support on a main opening branch." % [stage_index, generation_seed])
			assert(start_adjacent_combat_count >= 2, "Expected stage %d seed %d to keep both the combat branch and the short combat spur." % [stage_index, generation_seed])
			assert(start_adjacent_leaf_count == 1, "Expected stage %d seed %d to keep exactly one short opening spur." % [stage_index, generation_seed])
			assert(start_adjacent_leaf_family == "combat", "Expected stage %d seed %d to keep the short opening spur as combat." % [stage_index, generation_seed])


func test_map_runtime_state_generation_is_deterministic_per_profile() -> void:
	for stage_index in [1, 2, 3]:
		var first_map_runtime_state: RefCounted = MapRuntimeStateScript.new()
		first_map_runtime_state.reset_for_new_run(stage_index)
		var second_map_runtime_state: RefCounted = MapRuntimeStateScript.new()
		second_map_runtime_state.reset_for_new_run(stage_index)
		assert(
			_build_runtime_graph_signature(first_map_runtime_state) == _build_runtime_graph_signature(second_map_runtime_state),
			"Expected stage %d controlled scatter generation to stay deterministic across repeated new-run builds." % stage_index
		)


func test_run_state_map_generation_varies_by_seed_but_stays_deterministic() -> void:
	var seeded_run_a: RunState = RunStateScript.new()
	seeded_run_a.reset_for_new_run()
	seeded_run_a.configure_run_seed(99)
	var mirrored_run_a: RunState = RunStateScript.new()
	mirrored_run_a.reset_for_new_run()
	mirrored_run_a.configure_run_seed(99)
	assert(
		_build_runtime_graph_signature(seeded_run_a.map_runtime_state) == _build_runtime_graph_signature(mirrored_run_a.map_runtime_state),
		"Expected the same run seed to rebuild the same controlled-scatter runtime graph."
	)

	var observed_signatures: Dictionary = {}
	for seed in range(1, 17):
		var seeded_run: RunState = RunStateScript.new()
		seeded_run.reset_for_new_run()
		seeded_run.configure_run_seed(seed)
		observed_signatures[_build_runtime_graph_signature(seeded_run.map_runtime_state)] = true
	assert(
		observed_signatures.size() >= 2,
		"Expected different run seeds to surface at least two distinct controlled-scatter runtime graphs inside the same stage-profile floor."
	)


func test_map_runtime_state_profile_graphs_stay_distinct() -> void:
	var signatures: Dictionary = {}
	for stage_index in [1, 2, 3]:
		var map_runtime_state: RefCounted = MapRuntimeStateScript.new()
		map_runtime_state.reset_for_new_run(stage_index)
		signatures[stage_index] = _build_runtime_topology_signature(map_runtime_state)
	assert(
		String(signatures.get(1, "")) != String(signatures.get(2, "")),
		"Expected stage 1 and stage 2 controlled-scatter graphs to stay profile-distinct."
	)
	assert(
		String(signatures.get(2, "")) != String(signatures.get(3, "")),
		"Expected stage 2 and stage 3 controlled-scatter graphs to stay profile-distinct."
	)
	assert(
		String(signatures.get(1, "")) != String(signatures.get(3, "")),
		"Expected stage 1 and stage 3 controlled-scatter graphs to stay profile-distinct."
	)


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
	var context: Dictionary = _build_map_explore_context()
	var flow_manager: Node = context.get("flow_manager")
	var run_state: RunState = context.get("run_state")
	var coordinator: RefCounted = context.get("coordinator")

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
	var context: Dictionary = _build_map_explore_context()
	var flow_manager: Node = context.get("flow_manager")
	var run_state: RunState = context.get("run_state")
	var coordinator: RefCounted = context.get("coordinator")

	var start_adjacents: PackedInt32Array = run_state.map_runtime_state.get_adjacent_node_ids(0)
	var target_combat_id: int = MapRuntimeStateScript.NO_PENDING_NODE_ID
	for candidate_node_id in start_adjacents:
		if run_state.map_runtime_state.get_node_family(int(candidate_node_id)) == "combat":
			target_combat_id = int(candidate_node_id)
			break
	assert(target_combat_id != MapRuntimeStateScript.NO_PENDING_NODE_ID, "Expected start adjacency to include at least one combat node.")
	run_state.map_runtime_state.roadside_encounters_this_stage = MapRuntimeStateScript.MAX_ROADSIDE_ENCOUNTERS_PER_STAGE

	var move_result: Dictionary = coordinator.call("choose_move_to_node", target_combat_id)
	assert(bool(move_result.get("ok", false)), "Expected adjacent combat node traversal to succeed.")
	assert(run_state.map_runtime_state.current_node_id == target_combat_id, "Expected movement to advance onto the chosen adjacent node.")
	var discovered_neighbors: int = 0
	for adjacent_node_id in run_state.map_runtime_state.get_adjacent_node_ids(target_combat_id):
		if run_state.map_runtime_state.get_node_state(int(adjacent_node_id)) == MapRuntimeStateScript.NODE_STATE_DISCOVERED:
			discovered_neighbors += 1
	assert(discovered_neighbors > 0, "Expected moving locally to reveal at least one immediate neighbor.")
	assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.COMBAT, "Expected adjacent combat entries to open Combat directly.")
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
		"ash_gnawer",
		"lantern_cutpurse",
		"mossback_ram",
		"briar_alchemist",
		"chain_trapper",
		"cutpurse_duelist",
		"grave_chanter",
		"thornwood_warder",
		"dusk_pikeman",
		"rotbound_reaver",
		"gatebreaker_brute",
		"ember_harrier",
		"chain_herald",
		"briar_sovereign",
		"tollhouse_captain",
		"carrion_runner",
		"ashen_sapper",
	]
	assert(
		ordered_enemy_ids == expected_enemy_ids,
		"Expected enemy authored-order reads to stay stable against JSON-loaded authoring_order values."
	)


func test_event_node_resolution_opens_dedicated_event_flow() -> void:
	var context: Dictionary = _build_map_explore_context()
	var flow_manager: Node = context.get("flow_manager")
	var run_state: RunState = context.get("run_state")
	var coordinator: RefCounted = context.get("coordinator")
	var event_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "event")
	assert(event_node_id >= 0, "Expected the procedural v1 map to place one event node.")
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, event_node_id)

	var move_result: Dictionary = coordinator.call("choose_move_to_node", event_node_id)
	assert(bool(move_result.get("ok", false)), "Expected adjacent event traversal to succeed.")
	assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.EVENT, "Expected event entry to open the dedicated Event flow directly.")
	assert(int(flow_manager.call("get_current_state")) == FlowStateScript.Type.EVENT, "Expected flow state to enter Event after resolving an event node.")
	var event_state: RefCounted = coordinator.call("get_event_state")
	assert(event_state != null, "Expected EventState after resolving an event node.")
	assert(String(event_state.template_definition_id) == "forest_shrine_echo", "Expected stage-1 event selection to stay deterministic.")
	assert(event_state.choices.size() == 2, "Expected EventState to expose exactly 2 authored choices.")
	_free_node(flow_manager)


func test_event_node_revisit_does_not_reopen_primary_value() -> void:
	var context: Dictionary = _build_map_explore_context()
	var flow_manager: Node = context.get("flow_manager")
	var run_state: RunState = context.get("run_state")
	var coordinator: RefCounted = context.get("coordinator")
	run_state.player_hp = 40
	var event_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "event")
	assert(event_node_id >= 0, "Expected one event node for revisit coverage.")
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, event_node_id)

	var move_result: Dictionary = coordinator.call("choose_move_to_node", event_node_id)
	assert(bool(move_result.get("ok", false)), "Expected event traversal to succeed.")
	assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.EVENT, "Expected first event visit to open Event directly.")
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
	var context: Dictionary = _build_map_explore_context(1, false)
	var flow_manager: Node = context.get("flow_manager")
	var run_state: RunState = context.get("run_state")
	var coordinator: RefCounted = context.get("coordinator")
	var reward_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "reward")
	assert(reward_node_id >= 0, "Expected one reward node for revisit coverage.")
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, reward_node_id)
	run_state.map_runtime_state.roadside_encounters_this_stage = MapRuntimeStateScript.MAX_ROADSIDE_ENCOUNTERS_PER_STAGE

	var move_result: Dictionary = coordinator.call("choose_move_to_node", reward_node_id)
	assert(bool(move_result.get("ok", false)), "Expected reward traversal to succeed.")
	assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.REWARD, "Expected first reward visit to open Reward directly.")
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
	var context: Dictionary = _build_map_explore_context(123)
	var flow_manager: Node = context.get("flow_manager")
	var run_state: RunState = context.get("run_state")
	var coordinator: RefCounted = context.get("coordinator")
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
	for slot_index in range(MapRuntimeStateScript.MAX_ROADSIDE_ENCOUNTERS_PER_STAGE):
		assert(map_runtime_state.consume_roadside_encounter_slot(), "Expected roadside encounter slot %d to be consumable before the stage quota is exhausted." % (slot_index + 1))
		if slot_index < MapRuntimeStateScript.MAX_ROADSIDE_ENCOUNTERS_PER_STAGE - 1:
			assert(map_runtime_state.can_trigger_roadside_encounter(), "Expected roadside encounter quota to remain available until the last configured slot is consumed.")
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
	var context: Dictionary = _build_map_explore_context(1, false)
	var flow_manager: Node = context.get("flow_manager")
	var run_state: RunState = context.get("run_state")
	var coordinator: RefCounted = context.get("coordinator")
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var from_node_id: int = map_runtime_state.current_node_id

	var excluded_families: PackedStringArray = ["start", "event", "key", "boss", "support", "rest", "merchant", "blacksmith", "hamlet"]
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
	assert(
		not bool(coordinator.call(
			"_should_open_roadside_encounter",
			run_state,
			map_runtime_state,
			from_node_id,
			1,
			"combat",
			MapRuntimeStateScript.NODE_STATE_LOCKED,
		)),
		"Expected locked targets to skip roadside encounter source handling."
	)
	assert(
		not bool(coordinator.call(
			"_should_open_roadside_encounter",
			run_state,
			map_runtime_state,
			from_node_id,
			1,
			"combat",
			MapRuntimeStateScript.NODE_STATE_UNDISCOVERED,
		)),
		"Expected undiscovered targets to skip roadside encounter source handling."
	)
	_free_node(flow_manager)


func test_roadside_encounter_is_movement_scoped_and_preserves_reward_destination() -> void:
	var context: Dictionary = _build_map_explore_context(1, false)
	var flow_manager: Node = context.get("flow_manager")
	var run_state: RunState = context.get("run_state")
	var coordinator: RefCounted = context.get("coordinator")
	run_state.player_hp = 40
	run_state.xp = 0
	var move_context: Dictionary = _configure_seed_for_predicted_roadside_adjacent_family(run_state, coordinator, "reward")
	var from_node_id: int = int(run_state.map_runtime_state.current_node_id)
	var target_node_id: int = int(move_context.get("target_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	assert(target_node_id != MapRuntimeStateScript.NO_PENDING_NODE_ID, "Expected a deterministic roadside-open reward destination.")

	var move_result: Dictionary = coordinator.call("choose_move_to_node", target_node_id)
	assert(bool(move_result.get("ok", false)), "Expected reward movement with roadside interruption to succeed.")
	assert(String(move_result.get("node_type", "")) == "reward", "Expected roadside interruption to preserve the real destination family.")
	assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.EVENT, "Expected roadside interruption to open Event first.")
	assert(run_state.map_runtime_state.get_node_state(target_node_id) == MapRuntimeStateScript.NODE_STATE_DISCOVERED, "Expected roadside interruption not to resolve the destination node.")
	assert(run_state.map_runtime_state.current_node_id == from_node_id, "Expected movement-scoped roadside interruption to keep the player on the source node until the interruption closes.")
	var active_event_state: RefCounted = coordinator.call("get_event_state")
	assert(active_event_state != null, "Expected roadside interruption to create EventState.")
	assert(String(active_event_state.source_context) == "roadside_encounter", "Expected movement-triggered interruptions to expose the roadside source context.")
	assert(run_state.map_runtime_state.has_pending_node(), "Expected roadside interruption to retain pending destination continuation.")
	var roadside_choice_id: String = String(active_event_state.choices[0].get("choice_id", ""))
	assert(not roadside_choice_id.is_empty(), "Expected roadside interruption to expose at least one valid choice id.")

	var event_choice_result: Dictionary = coordinator.call("choose_event_option", roadside_choice_id)
	assert(bool(event_choice_result.get("ok", false)), "Expected roadside event choice to resolve successfully.")
	assert(int(event_choice_result.get("target_state", -1)) == FlowStateScript.Type.REWARD, "Expected roadside resolution to continue into the preserved reward destination.")
	assert(run_state.map_runtime_state.current_node_id == target_node_id, "Expected preserved roadside continuation to move onto the real destination only after the roadside flow closes.")
	assert(run_state.map_runtime_state.get_node_state(target_node_id) == MapRuntimeStateScript.NODE_STATE_RESOLVED, "Expected reward destination to resolve only when its own flow opens.")
	assert(coordinator.call("get_reward_state") != null, "Expected reward destination flow to open after roadside resolution.")
	assert(not run_state.map_runtime_state.has_pending_node(), "Expected pending destination continuation to clear once reward flow begins.")

	var reward_state: RefCounted = coordinator.call("get_reward_state")
	var chosen_offer_id: String = String(reward_state.offers[0].get("offer_id", ""))
	assert(not chosen_offer_id.is_empty(), "Expected roadside-preserved reward flow to expose at least one claimable offer.")
	var reward_choice_result: Dictionary = coordinator.call("choose_reward_option", chosen_offer_id)
	assert(bool(reward_choice_result.get("ok", false)), "Expected reward claim after roadside continuation to succeed.")
	assert(coordinator.call("get_reward_state") == null, "Expected reward state to clear after claiming the preserved destination reward.")
	_free_node(flow_manager)


func test_roadside_pending_destination_continuation_survives_level_up_restore() -> void:
	var context: Dictionary = _build_map_explore_context(1, false)
	var flow_manager: Node = context.get("flow_manager")
	var run_state: RunState = context.get("run_state")
	var coordinator: RefCounted = context.get("coordinator")
	run_state.xp = 10
	var save_service: RefCounted = SaveServiceScript.new()
	var save_runtime_bridge: RefCounted = SaveRuntimeBridgeScript.new()
	save_runtime_bridge.call("setup", flow_manager, run_state, coordinator, save_service)
	var move_context: Dictionary = _configure_seed_for_predicted_roadside_adjacent_family(run_state, coordinator, "combat", 512, "grant_xp")
	var target_node_id: int = int(move_context.get("target_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	assert(target_node_id != MapRuntimeStateScript.NO_PENDING_NODE_ID, "Expected a deterministic roadside-open combat destination.")

	var move_result: Dictionary = coordinator.call("choose_move_to_node", target_node_id)
	assert(bool(move_result.get("ok", false)), "Expected combat movement with roadside interruption to succeed.")
	assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.EVENT, "Expected roadside interruption to open Event before combat.")
	var active_event_state: RefCounted = coordinator.call("get_event_state")
	assert(active_event_state != null, "Expected roadside interruption to expose EventState before the level-up continuation check.")
	var xp_choice_id: String = ""
	var xp_choice_amount: int = 0
	for choice_variant in active_event_state.choices:
		if typeof(choice_variant) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = choice_variant
		if String(choice.get("effect_type", "")) != "grant_xp":
			continue
		xp_choice_id = String(choice.get("choice_id", ""))
		xp_choice_amount = int(choice.get("amount", 0))
		break
	assert(not xp_choice_id.is_empty(), "Expected the roadside template to expose one XP-awarding choice for level-up continuation coverage.")
	assert(xp_choice_amount > 0, "Expected the roadside XP-awarding choice to expose a positive amount.")
	run_state.xp = max(0, LevelUpStateScript.threshold_for_level(run_state.current_level + 1) - xp_choice_amount)
	var event_choice_result: Dictionary = coordinator.call("choose_event_option", xp_choice_id)
	assert(bool(event_choice_result.get("ok", false)), "Expected roadside event choice to resolve successfully before continuation.")
	assert(int(event_choice_result.get("target_state", -1)) == FlowStateScript.Type.LEVEL_UP, "Expected roadside event XP threshold to open LevelUp before destination continuation.")
	assert(run_state.map_runtime_state.has_pending_node(), "Expected pending destination continuation to remain through the save-safe level-up stop.")

	var snapshot_result: Dictionary = save_runtime_bridge.call("build_save_snapshot")
	assert(bool(snapshot_result.get("ok", false)), "Expected level-up snapshot build to succeed with pending roadside continuation.")
	var restore_result: Dictionary = save_runtime_bridge.call("restore_from_snapshot", snapshot_result.get("snapshot", {}))
	assert(bool(restore_result.get("ok", false)), "Expected level-up snapshot restore to preserve roadside continuation context.")
	assert(run_state.map_runtime_state.has_pending_node(), "Expected restored level-up state to retain the pending roadside destination.")

	var restored_level_up_state: RefCounted = coordinator.call("get_level_up_state")
	assert(restored_level_up_state != null, "Expected LevelUpState after restoring the roadside continuation snapshot.")
	var option_id: String = String(restored_level_up_state.offers[0].get("offer_id", ""))
	assert(not option_id.is_empty(), "Expected restored LevelUpState to expose a claimable perk option.")
	var level_up_result: Dictionary = coordinator.call("choose_level_up_option", option_id)
	assert(bool(level_up_result.get("ok", false)), "Expected restored level-up choice to resolve successfully.")
	assert(int(level_up_result.get("target_state", -1)) == FlowStateScript.Type.COMBAT, "Expected restored roadside continuation to resume the preserved combat destination after LevelUp.")
	assert(int(flow_manager.call("get_current_state")) == FlowStateScript.Type.COMBAT, "Expected flow state to enter Combat after restored roadside continuation.")
	assert(not run_state.map_runtime_state.has_pending_node(), "Expected pending roadside continuation to clear once combat opens.")
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
	var context: Dictionary = _build_map_explore_context(1, false)
	var flow_manager: Node = context.get("flow_manager")
	var run_state: RunState = context.get("run_state")
	var coordinator: RefCounted = context.get("coordinator")
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var key_node_id: int = _find_node_id_by_family(map_runtime_state, "key")
	_prepare_current_node_adjacent_to_target(map_runtime_state, key_node_id)

	var key_move: Dictionary = coordinator.call("choose_move_to_node", key_node_id)
	assert(bool(key_move.get("ok", false)), "Expected adjacent key traversal to succeed.")
	assert(int(key_move.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected key entry to resolve directly on MapExplore.")
	assert(bool(key_move.get("stage_key_resolved", false)), "Expected key resolution to update runtime-owned stage key state.")
	assert(bool(key_move.get("boss_gate_unlocked", false)), "Expected key resolution to unlock the boss gate runtime state.")
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
			"family": "hamlet",
			"expected_support_type": "hamlet",
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
		run_state.map_runtime_state.roadside_encounters_this_stage = run_state.map_runtime_state.MAX_ROADSIDE_ENCOUNTERS_PER_STAGE

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


func test_live_map_families_skip_node_resolve_transition_shell() -> void:
	var live_family_cases: Array[Dictionary] = [
		{
			"stage_index": 1,
			"family": "combat",
			"expected_target_state": FlowStateScript.Type.COMBAT,
		},
		{
			"stage_index": 1,
			"family": "event",
			"expected_target_state": FlowStateScript.Type.EVENT,
		},
		{
			"stage_index": 1,
			"family": "rest",
			"expected_target_state": FlowStateScript.Type.SUPPORT_INTERACTION,
		},
		{
			"stage_index": 1,
			"family": "merchant",
			"expected_target_state": FlowStateScript.Type.SUPPORT_INTERACTION,
		},
		{
			"stage_index": 2,
			"family": "blacksmith",
			"expected_target_state": FlowStateScript.Type.SUPPORT_INTERACTION,
		},
		{
			"stage_index": 1,
			"family": "hamlet",
			"expected_target_state": FlowStateScript.Type.SUPPORT_INTERACTION,
		},
		{
			"stage_index": 1,
			"family": "key",
			"expected_target_state": FlowStateScript.Type.MAP_EXPLORE,
		},
	]

	for case_variant in live_family_cases:
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
		run_state.map_runtime_state.roadside_encounters_this_stage = MapRuntimeStateScript.MAX_ROADSIDE_ENCOUNTERS_PER_STAGE

		var coordinator: RefCounted = RunSessionCoordinatorScript.new()
		coordinator.call("setup", flow_manager, run_state)

		var target_family: String = String(case_data.get("family", ""))
		var target_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, target_family)
		assert(target_node_id >= 0, "Expected stage %d map to contain %s." % [run_state.stage_index, target_family])
		_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, target_node_id)

		var move_result: Dictionary = coordinator.call("choose_move_to_node", target_node_id)
		assert(bool(move_result.get("ok", false)), "Expected %s traversal to succeed." % target_family)
		assert(
			int(move_result.get("target_state", -1)) == int(case_data.get("expected_target_state", -1)),
			"Expected %s traversal to target %s directly." % [
				target_family,
				FlowStateScript.name_of(int(case_data.get("expected_target_state", -1))),
			]
		)
		for transition in transition_sequence:
			assert(
				not String(transition).contains("NODE_RESOLVE"),
				"Expected live runtime-backed %s traversal to bypass NodeResolve, got %s." % [target_family, transition]
			)

		_free_node(flow_manager)


func test_support_node_revisit_stays_traversal_only() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(1)
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
	run_state.configure_run_seed(1)
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
	assert(run_state.player_hp == 50, "Expected first rest action to heal once.")
	assert(run_state.hunger == 9, "Expected first rest action to spend hunger once after the move cost.")

	var back_to_start_from_rest: Dictionary = coordinator.call("choose_move_to_node", start_node_id)
	assert(bool(back_to_start_from_rest.get("ok", false)), "Expected traversal away from the resolved rest node to succeed.")
	var rest_revisit_move: Dictionary = coordinator.call("choose_move_to_node", rest_node_id)
	assert(bool(rest_revisit_move.get("ok", false)), "Expected revisit onto the resolved rest node to succeed.")
	assert(int(rest_revisit_move.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected resolved rest revisit to stay pure traversal.")
	assert(coordinator.call("get_support_interaction_state") == null, "Expected rest revisit not to reopen support state.")
	assert(run_state.player_hp == 50, "Expected rest revisit not to grant a second heal.")
	assert(run_state.hunger == 7, "Expected rest revisit to pay only the traversal hunger cost.")

	var blacksmith_move: Dictionary = coordinator.call("choose_move_to_node", blacksmith_node_id)
	assert(bool(blacksmith_move.get("ok", false)), "Expected blacksmith traversal to succeed directly from the revealed support branch.")
	assert(int(blacksmith_move.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected blacksmith node to open SupportInteraction directly.")
	var repair_action: Dictionary = coordinator.call("choose_support_action", "repair_active_weapon")
	assert(bool(repair_action.get("ok", false)), "Expected first blacksmith repair to succeed.")
	assert(run_state.gold == 16, "Expected blacksmith repair to spend gold once.")
	assert(int(run_state.inventory_state.weapon_instance.get("current_durability", 0)) == 20, "Expected blacksmith repair to restore durability once.")

	var back_to_rest_from_blacksmith: Dictionary = coordinator.call("choose_move_to_node", rest_node_id)
	assert(bool(back_to_rest_from_blacksmith.get("ok", false)), "Expected traversal away from the resolved blacksmith node to succeed.")
	assert(int(back_to_rest_from_blacksmith.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected returning through the resolved rest hub to stay pure traversal.")

	var blacksmith_revisit_move: Dictionary = coordinator.call("choose_move_to_node", blacksmith_node_id)
	assert(bool(blacksmith_revisit_move.get("ok", false)), "Expected revisit onto the resolved blacksmith node to succeed.")
	assert(int(blacksmith_revisit_move.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected resolved blacksmith revisit to stay pure traversal.")
	assert(coordinator.call("get_support_interaction_state") == null, "Expected blacksmith revisit not to reopen support state.")
	assert(run_state.gold == 16, "Expected blacksmith revisit not to spend extra gold.")
	assert(int(run_state.inventory_state.weapon_instance.get("current_durability", 0)) == 20, "Expected blacksmith revisit not to grant a second repair.")
	_free_node(flow_manager)


func test_hamlet_accept_marks_target_and_claims_reward() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(1)

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	var side_mission_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	assert(side_mission_node_id >= 0, "Expected procedural v1 map generation to place one hamlet node.")
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, side_mission_node_id)

	var move_result: Dictionary = coordinator.call("choose_move_to_node", side_mission_node_id)
	assert(bool(move_result.get("ok", false)), "Expected hamlet traversal to succeed once the node is adjacent.")
	assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected hamlet entry to open SupportInteraction directly.")
	var side_mission_state: RefCounted = coordinator.call("get_support_interaction_state")
	assert(side_mission_state != null, "Expected SupportInteractionState for the hamlet request.")
	assert(String(side_mission_state.support_type) == "hamlet", "Expected hamlet support type.")
	assert(String(side_mission_state.title_text) == "Hunt Marked Brigand", "Expected authored hamlet title text.")
	assert(side_mission_state.offers.size() == 1, "Expected offered hamlet request to expose the accept action only.")

	var accept_result: Dictionary = coordinator.call("choose_support_action", "accept_side_mission")
	assert(bool(accept_result.get("ok", false)), "Expected accepting the hamlet request to succeed.")
	assert(int(accept_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected accepting the hamlet request to return directly to the map.")
	assert(coordinator.call("get_support_interaction_state") == null, "Expected hamlet support state to close after accepting the request.")

	var persisted_side_mission_state: Dictionary = run_state.map_runtime_state.get_side_mission_node_runtime_state(side_mission_node_id)
	assert(String(persisted_side_mission_state.get("mission_status", "")) == "accepted", "Expected accepted hamlet request to persist on MapRuntimeState.")
	var target_node_id: int = int(persisted_side_mission_state.get("target_node_id", -1))
	var target_enemy_definition_id: String = String(persisted_side_mission_state.get("target_enemy_definition_id", ""))
	assert(target_node_id >= 0, "Expected accepted hamlet request to bind a target combat node.")
	assert(not target_enemy_definition_id.is_empty(), "Expected accepted hamlet request to bind a specific target enemy.")
	assert(run_state.map_runtime_state.get_node_state(target_node_id) != MapRuntimeStateScript.NODE_STATE_UNDISCOVERED, "Expected accepted hamlet request to reveal the marked combat node.")
	var accepted_highlight: Dictionary = run_state.map_runtime_state.build_side_quest_highlight_snapshot()
	assert(int(accepted_highlight.get("node_id", -1)) == target_node_id, "Expected accepted hamlet request highlight to point at the marked combat node.")
	assert(String(accepted_highlight.get("highlight_state", "")) == "target", "Expected accepted hamlet request to use the target highlight state.")
	var reward_offers: Array = persisted_side_mission_state.get("reward_offers", [])
	assert(reward_offers.size() == 2, "Expected accepted hamlet request to prepare exactly 2 reward offers.")
	assert(
		String((reward_offers[0] as Dictionary).get("offer_id", "")) != String((reward_offers[1] as Dictionary).get("offer_id", "")),
		"Expected accepted hamlet reward offers to be unique."
	)

	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, target_node_id)
	var target_move: Dictionary = coordinator.call("choose_move_to_node", target_node_id)
	assert(bool(target_move.get("ok", false)), "Expected traversal onto the marked combat node to succeed.")
	assert(int(target_move.get("target_state", -1)) == FlowStateScript.Type.COMBAT, "Expected marked combat node entry to open Combat directly.")

	var combat_setup: Dictionary = coordinator.call("build_combat_setup_data")
	assert(bool(combat_setup.get("ok", false)), "Expected combat setup to succeed for the marked contract fight.")
	assert(
		String(combat_setup.get("enemy_definition_id", "")) == target_enemy_definition_id,
		"Expected accepted hamlet target to override the default combat enemy selection."
	)

	var combat_result: Dictionary = coordinator.call("resolve_combat_result", "victory")
	assert(bool(combat_result.get("ok", false)), "Expected marked target victory to resolve successfully.")
	assert(int(combat_result.get("target_state", -1)) == FlowStateScript.Type.REWARD, "Expected marked target victory to keep the normal combat reward flow.")
	var completed_side_mission_state: Dictionary = run_state.map_runtime_state.get_side_mission_node_runtime_state(side_mission_node_id)
	assert(String(completed_side_mission_state.get("mission_status", "")) == "completed", "Expected victory over the marked target to complete the hamlet request.")
	var completed_highlight: Dictionary = run_state.map_runtime_state.build_side_quest_highlight_snapshot()
	assert(int(completed_highlight.get("node_id", -1)) == side_mission_node_id, "Expected completed hamlet highlight to point back at the hamlet node.")
	assert(String(completed_highlight.get("highlight_state", "")) == "return", "Expected completed hamlet request to use the return highlight state.")

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
		assert(int(level_up_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected level-up resolution to return to MapExplore before the hamlet turn-in.")
	else:
		assert(int(reward_choice_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected combat reward resolution to return to MapExplore.")

	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, side_mission_node_id)
	var return_move: Dictionary = coordinator.call("choose_move_to_node", side_mission_node_id)
	assert(bool(return_move.get("ok", false)), "Expected return traversal to the completed contract node to succeed.")
	assert(int(return_move.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected completed hamlet request to reopen SupportInteraction directly for reward claim.")
	var return_support_state: RefCounted = coordinator.call("get_support_interaction_state")
	assert(return_support_state != null, "Expected hamlet return support state.")
	assert(return_support_state.offers.size() == 2, "Expected completed hamlet request to offer exactly 2 reward claims.")
	var claim_offer: Dictionary = return_support_state.offers[0]
	var claimed_definition_id: String = String(claim_offer.get("definition_id", ""))
	var claim_result: Dictionary = coordinator.call("choose_support_action", String(claim_offer.get("offer_id", "")))
	assert(bool(claim_result.get("ok", false)), "Expected claiming a hamlet reward to succeed.")
	assert(int(claim_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected hamlet reward claim to return directly to the map.")
	assert(_inventory_contains_definition(run_state.inventory_state, claimed_definition_id), "Expected claimed hamlet gear to be added to the shared carried inventory.")
	var claimed_side_mission_state: Dictionary = run_state.map_runtime_state.get_side_mission_node_runtime_state(side_mission_node_id)
	assert(String(claimed_side_mission_state.get("mission_status", "")) == "claimed", "Expected hamlet runtime state to become claimed after reward pickup.")

	var adjacent_node_id: int = int(run_state.map_runtime_state.get_adjacent_node_ids(side_mission_node_id)[0])
	run_state.map_runtime_state.mark_node_resolved(adjacent_node_id)
	var leave_contract_move: Dictionary = coordinator.call("choose_move_to_node", adjacent_node_id)
	assert(bool(leave_contract_move.get("ok", false)), "Expected traversal away from the claimed contract node to stay valid.")
	var revisit_claimed_move: Dictionary = coordinator.call("choose_move_to_node", side_mission_node_id)
	assert(bool(revisit_claimed_move.get("ok", false)), "Expected revisit onto the claimed hamlet node to stay traversable.")
	assert(int(revisit_claimed_move.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected claimed hamlet revisit not to reopen SupportInteraction.")
	assert(coordinator.call("get_support_interaction_state") == null, "Expected no lingering support state after claimed hamlet revisit.")
	_free_node(flow_manager)


func test_support_interaction_state_uses_seeded_stage_local_merchant_pool() -> void:
	var legacy_merchant_state: SupportInteractionState = SupportInteractionStateScript.new()
	legacy_merchant_state.setup_for_type("merchant", 7, {}, 2, null, null, 1)
	assert(
		_build_offer_id_signature(legacy_merchant_state.offers) == "buy_war_biscuit_x1|buy_bandit_hatchet|buy_pilgrim_board",
		"Expected seed-1 merchant setup to preserve the legacy stage-2 authored stock order."
	)

	var repeated_seed_a: SupportInteractionState = SupportInteractionStateScript.new()
	repeated_seed_a.setup_for_type("merchant", 7, {}, 2, null, null, 41)
	var mirrored_seed_a: SupportInteractionState = SupportInteractionStateScript.new()
	mirrored_seed_a.setup_for_type("merchant", 7, {}, 2, null, null, 41)
	assert(
		_build_offer_id_signature(repeated_seed_a.offers) == _build_offer_id_signature(mirrored_seed_a.offers),
		"Expected identical merchant selection seeds to resolve the same stage-local merchant stock."
	)

	var observed_stock_signatures: Dictionary = {}
	for seed in range(1, 65):
		var merchant_state: SupportInteractionState = SupportInteractionStateScript.new()
		merchant_state.setup_for_type("merchant", 7, {}, 2, null, null, seed)
		observed_stock_signatures[_build_offer_id_signature(merchant_state.offers)] = true
	assert(
		observed_stock_signatures.size() >= 3,
		"Expected stage-2 merchant setup to surface all three deterministic stock signatures across different run seeds."
	)
	assert(
		observed_stock_signatures.has("buy_forager_tea_x1|buy_briar_knife|buy_sturdy_wraps"),
		"Expected stage-2 merchant setup to surface the authored alternate kit stock across the run-seeded stage-local pool."
	)
	assert(
		observed_stock_signatures.has("buy_tinker_oil_x1|buy_patched_buffcoat|buy_packhook_sash"),
		"Expected stage-2 merchant setup to surface the authored forgegear stock across the run-seeded stage-local pool."
	)


func test_support_interaction_state_uses_seeded_stage_local_hamlet_pool() -> void:
	var legacy_hamlet_state: SupportInteractionState = SupportInteractionStateScript.new()
	legacy_hamlet_state.setup_for_type("hamlet", 11, {}, 3, null, null, 1)
	assert(
		String(legacy_hamlet_state.mission_definition_id) == "rescue_missing_scout",
		"Expected seed-1 hamlet setup to preserve the legacy stage-3 request definition."
	)

	var repeated_seed_a: SupportInteractionState = SupportInteractionStateScript.new()
	repeated_seed_a.setup_for_type("hamlet", 11, {}, 3, null, null, 41)
	var mirrored_seed_a: SupportInteractionState = SupportInteractionStateScript.new()
	mirrored_seed_a.setup_for_type("hamlet", 11, {}, 3, null, null, 41)
	assert(
		String(repeated_seed_a.mission_definition_id) == String(mirrored_seed_a.mission_definition_id),
		"Expected identical hamlet selection seeds to resolve the same stage-local request."
	)

	var observed_mission_ids: Dictionary = {}
	for seed in range(1, 97):
		var hamlet_state: SupportInteractionState = SupportInteractionStateScript.new()
		hamlet_state.setup_for_type("hamlet", 11, {}, 3, null, null, seed)
		observed_mission_ids[String(hamlet_state.mission_definition_id)] = true
	assert(
		observed_mission_ids.size() >= 4,
		"Expected stage-3 hamlet setup to surface all authored request definitions across different run seeds."
	)
	assert(
		observed_mission_ids.has("bring_proof"),
		"Expected stage-3 hamlet setup to surface the authored bring-proof request across the deterministic request pool."
	)
	assert(
		observed_mission_ids.has("ash_barricade_proof"),
		"Expected stage-3 hamlet setup to surface the authored barricade-proof request across the deterministic request pool."
	)

	var stage_one_mission_ids: Dictionary = {}
	for seed in range(1, 97):
		var stage_one_hamlet_state: SupportInteractionState = SupportInteractionStateScript.new()
		stage_one_hamlet_state.setup_for_type("hamlet", 9, {}, 1, null, null, seed)
		stage_one_mission_ids[String(stage_one_hamlet_state.mission_definition_id)] = true
	assert(
		stage_one_mission_ids.size() >= 3,
		"Expected stage-1 hamlet setup to surface all authored request definitions across different run seeds."
	)
	assert(
		stage_one_mission_ids.has("ridge_contract_hunt"),
		"Expected stage-1 hamlet setup to surface the authored ridge-contract request across the deterministic request pool."
	)

	var stage_two_mission_ids: Dictionary = {}
	for seed in range(1, 97):
		var stage_two_hamlet_state: SupportInteractionState = SupportInteractionStateScript.new()
		stage_two_hamlet_state.setup_for_type("hamlet", 10, {}, 2, null, null, seed)
		stage_two_mission_ids[String(stage_two_hamlet_state.mission_definition_id)] = true
	assert(
		stage_two_mission_ids.size() >= 3,
		"Expected stage-2 hamlet setup to surface all authored request definitions across different run seeds."
	)
	assert(
		stage_two_mission_ids.has("lantern_scout_recovery"),
		"Expected stage-2 hamlet setup to surface the authored lantern-scout recovery request across the deterministic request pool."
	)


func test_hamlet_nodes_expose_stage_personality() -> void:
	var stage_cases: Array[Dictionary] = [
		{"stage_index": 1, "expected_personality": SupportInteractionStateScript.HAMLET_PERSONALITY_PILGRIM},
		{"stage_index": 2, "expected_personality": SupportInteractionStateScript.HAMLET_PERSONALITY_FRONTIER},
		{"stage_index": 3, "expected_personality": SupportInteractionStateScript.HAMLET_PERSONALITY_TRADE},
	]
	for case_data in stage_cases:
		var map_runtime_state: MapRuntimeState = MapRuntimeStateScript.new()
		map_runtime_state.reset_for_new_run(int(case_data.get("stage_index", 1)))
		var hamlet_node_id: int = _find_node_id_by_family(map_runtime_state, "hamlet")
		assert(hamlet_node_id >= 0, "Expected one hamlet node for personality coverage.")
		assert(
			String(map_runtime_state.get_hamlet_personality(hamlet_node_id)) == String(case_data.get("expected_personality", "")),
			"Expected stage %d hamlet node to expose the authored personality mapping." % int(case_data.get("stage_index", 1))
		)
		var hamlet_snapshot: Dictionary = {}
		for node_snapshot in map_runtime_state.build_node_snapshots():
			if int(node_snapshot.get("node_id", -1)) != hamlet_node_id:
				continue
			hamlet_snapshot = node_snapshot
			break
		assert(
			String(hamlet_snapshot.get("hamlet_personality", "")) == String(case_data.get("expected_personality", "")),
			"Expected hamlet node snapshot to keep the derived personality read."
		)


func test_hamlet_personality_biases_stage_local_request_pool() -> void:
	var hamlet_state: SupportInteractionState = SupportInteractionStateScript.new()
	var loader: ContentLoader = ContentLoaderScript.new()
	var stage_one_weighted_pool: Array = hamlet_state.call(
		"_build_hamlet_weighted_definition_ids",
		loader,
		PackedStringArray(["trail_contract_hunt", "watchpath_hunt", "ridge_contract_hunt"]),
		SupportInteractionStateScript.HAMLET_PERSONALITY_PILGRIM
	)
	assert(
		_count_occurrences(stage_one_weighted_pool, "watchpath_hunt") > _count_occurrences(stage_one_weighted_pool, "trail_contract_hunt"),
		"Expected stage-1 pilgrim hamlet weighting to favor the more survival-lean watchpath request."
	)

	var stage_three_weighted_pool: Array = hamlet_state.call(
		"_build_hamlet_weighted_definition_ids",
		loader,
		PackedStringArray(["rescue_missing_scout", "recover_bell_scout", "bring_proof", "ash_barricade_proof"]),
		SupportInteractionStateScript.HAMLET_PERSONALITY_TRADE
	)
	assert(
		_count_occurrences(stage_three_weighted_pool, "bring_proof") > _count_occurrences(stage_three_weighted_pool, "rescue_missing_scout"),
		"Expected stage-3 trade hamlet weighting to favor the more utility-oriented proof contracts."
	)


func test_hamlet_accept_biases_trade_reward_offers() -> void:
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.stage_index = 3
	run_state.configure_run_seed(41)
	run_state.map_runtime_state.reset_for_next_stage(3)

	var hamlet_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	assert(hamlet_node_id >= 0, "Expected one hamlet node for trade-bias coverage.")

	var support_state: SupportInteractionState = SupportInteractionStateScript.new()
	support_state.setup_for_type("hamlet", hamlet_node_id, {
		"mission_definition_id": "bring_proof",
		"mission_status": "offered",
	}, 3, run_state.inventory_state, run_state.map_runtime_state, run_state.run_seed)

	var application_policy: RefCounted = SupportActionApplicationPolicyScript.new()
	var apply_result: Dictionary = application_policy.call(
		"apply_action",
		run_state,
		support_state,
		InventoryActionsScript.new(),
		null,
		"accept_side_mission"
	)
	assert(bool(apply_result.get("ok", false)), "Expected trade-hamlet reward bias accept coverage to succeed.")

	var reward_offers: Array = support_state.reward_offers
	assert(reward_offers.size() == 2, "Expected trade-hamlet accept coverage to keep exactly 2 reward offers.")

	var offer_ids: Array[String] = []
	for reward_offer in reward_offers:
		offer_ids.append(String((reward_offer as Dictionary).get("offer_id", "")))
	assert(
		offer_ids.has("claim_scavenger_strap"),
		"Expected trade-flavored hamlet reward bias to keep the belt payout in the surfaced offer window."
	)
	assert(
		offer_ids.has("claim_proof_bounty"),
		"Expected trade-flavored hamlet reward bias to keep the gold payout in the surfaced offer window."
	)


func test_hamlet_offer_uses_noncombat_targets_for_delivery_requests() -> void:
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	var hamlet_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	assert(hamlet_node_id >= 0, "Expected one hamlet node for non-combat delivery gating coverage.")

	for combat_node_id in _find_node_ids_by_family(run_state.map_runtime_state, "combat"):
		run_state.map_runtime_state.mark_node_resolved(combat_node_id)

	var support_state: SupportInteractionState = SupportInteractionStateScript.new()
	support_state.setup_for_type("hamlet", hamlet_node_id, {
		"mission_definition_id": "deliver_supplies",
		"mission_type": "deliver_supplies",
		"quest_item_definition_id": "supply_bundle",
	}, 1, run_state.inventory_state, run_state.map_runtime_state)
	assert(support_state.offers.size() == 1, "Expected offered hamlet delivery coverage to expose one accept button.")
	assert(
		bool(support_state.offers[0].get("available", false)),
		"Expected hamlet delivery accept to stay available when only non-combat targets remain."
	)
	assert(
		not String(support_state.offers[0].get("label", "")).contains("No Mark"),
		"Expected hamlet delivery accept copy not to fall back to the stale no-target read when reward/support targets still exist."
	)


func test_hamlet_deliver_supplies_completes_on_arrival() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	var hamlet_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	assert(hamlet_node_id >= 0, "Expected procedural v1 map generation to place one hamlet node.")

	var target_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "reward")
	assert(target_node_id >= 0, "Expected a non-combat node for hamlet delivery completion coverage.")

	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var add_quest_item_result: Dictionary = inventory_actions.call("add_quest_item", run_state.inventory_state, "supply_bundle")
	assert(bool(add_quest_item_result.get("ok", false)), "Expected delivery coverage to seed the required hamlet cargo.")

	run_state.map_runtime_state.save_side_mission_node_runtime_state(hamlet_node_id, {
		"support_type": "hamlet",
		"mission_definition_id": "deliver_supplies",
		"mission_type": "deliver_supplies",
		"mission_status": "accepted",
		"target_node_id": target_node_id,
		"target_enemy_definition_id": "",
		"quest_item_definition_id": "supply_bundle",
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

	assert(
		_inventory_contains_definition(run_state.inventory_state, "supply_bundle"),
		"Expected the seeded hamlet delivery cargo to live in the backpack before arrival."
	)

	run_state.map_runtime_state.roadside_encounters_this_stage = MapRuntimeStateScript.MAX_ROADSIDE_ENCOUNTERS_PER_STAGE
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, target_node_id)
	var move_result: Dictionary = coordinator.call("choose_move_to_node", target_node_id)
	assert(bool(move_result.get("ok", false)), "Expected traversal onto the hamlet delivery target to succeed.")
	assert(
		int(move_result.get("target_state", -1)) == FlowStateScript.Type.REWARD,
		"Expected the reward-family delivery target to keep its direct node entry flow."
	)

	var completed_hamlet_state: Dictionary = run_state.map_runtime_state.get_side_mission_node_runtime_state(hamlet_node_id)
	assert(
		String(completed_hamlet_state.get("mission_status", "")) == "completed",
		"Expected arriving at the hamlet delivery target to complete the accepted request."
	)
	assert(
		not _inventory_contains_definition(run_state.inventory_state, "supply_bundle"),
		"Expected delivery completion to remove the hamlet cargo from the backpack."
	)
	var completed_highlight: Dictionary = run_state.map_runtime_state.build_side_mission_highlight_snapshot()
	assert(
		int(completed_highlight.get("node_id", -1)) == hamlet_node_id,
		"Expected completed delivery highlight to point back at the hamlet node."
	)
	assert(
		String(completed_highlight.get("highlight_state", "")) == "return",
		"Expected completed hamlet delivery to use the return highlight state."
	)
	_free_node(flow_manager)


func test_hamlet_rescue_missing_scout_completes_on_arrival() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	var hamlet_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	var target_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "reward")
	assert(hamlet_node_id >= 0, "Expected one hamlet node for rescue hook coverage.")
	assert(target_node_id >= 0, "Expected one reward node for non-combat rescue completion coverage.")

	_seed_accepted_hamlet_state(
		run_state.map_runtime_state,
		hamlet_node_id,
		"rescue_missing_scout",
		target_node_id
	)

	run_state.map_runtime_state.roadside_encounters_this_stage = MapRuntimeStateScript.MAX_ROADSIDE_ENCOUNTERS_PER_STAGE
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, target_node_id)
	var move_result: Dictionary = coordinator.call("choose_move_to_node", target_node_id)
	assert(bool(move_result.get("ok", false)), "Expected traversal onto the rescue target to succeed.")
	assert(
		int(move_result.get("target_state", -1)) == FlowStateScript.Type.REWARD,
		"Expected reward-family rescue targets to keep their direct routing."
	)

	var completed_hamlet_state: Dictionary = run_state.map_runtime_state.get_side_mission_node_runtime_state(hamlet_node_id)
	assert(
		String(completed_hamlet_state.get("mission_status", "")) == "completed",
		"Expected rescue-on-arrival coverage to complete the active hamlet request."
	)
	assert(
		not _inventory_contains_definition(run_state.inventory_state, "brigand_proof"),
		"Expected rescue-on-arrival coverage not to mint quest cargo as a side effect."
	)
	var completed_highlight: Dictionary = run_state.map_runtime_state.build_side_quest_highlight_snapshot()
	assert(
		int(completed_highlight.get("node_id", -1)) == hamlet_node_id and String(completed_highlight.get("highlight_state", "")) == "return",
		"Expected completed rescue highlight to point back at the hamlet."
	)
	_free_node(flow_manager)


func test_hamlet_bring_proof_grants_quest_item_on_completion() -> void:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)

	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()

	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)

	var hamlet_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	var target_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "reward")
	assert(hamlet_node_id >= 0, "Expected one hamlet node for bring-proof coverage.")
	assert(target_node_id >= 0, "Expected one reward node for non-combat bring-proof completion coverage.")
	assert(
		not _inventory_contains_definition(run_state.inventory_state, "brigand_proof"),
		"Expected bring-proof coverage to start without the proof quest item in the backpack."
	)

	_seed_accepted_hamlet_state(
		run_state.map_runtime_state,
		hamlet_node_id,
		"bring_proof",
		target_node_id,
		"brigand_proof"
	)

	run_state.map_runtime_state.roadside_encounters_this_stage = MapRuntimeStateScript.MAX_ROADSIDE_ENCOUNTERS_PER_STAGE
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, target_node_id)
	var move_result: Dictionary = coordinator.call("choose_move_to_node", target_node_id)
	assert(bool(move_result.get("ok", false)), "Expected traversal onto the bring-proof target to succeed.")
	assert(
		int(move_result.get("target_state", -1)) == FlowStateScript.Type.REWARD,
		"Expected reward-family bring-proof targets to keep their direct routing."
	)

	var completed_hamlet_state: Dictionary = run_state.map_runtime_state.get_side_mission_node_runtime_state(hamlet_node_id)
	assert(
		String(completed_hamlet_state.get("mission_status", "")) == "completed",
		"Expected bring-proof coverage to complete the active hamlet request on arrival."
	)
	assert(
		_inventory_contains_definition(run_state.inventory_state, "brigand_proof"),
		"Expected bring-proof completion to grant the configured quest proof item for the return trip."
	)
	var completed_highlight: Dictionary = run_state.map_runtime_state.build_side_quest_highlight_snapshot()
	assert(
		int(completed_highlight.get("node_id", -1)) == hamlet_node_id and String(completed_highlight.get("highlight_state", "")) == "return",
		"Expected completed bring-proof highlight to point back at the hamlet."
	)
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
	var side_mission_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	var combat_node_ids: Array[int] = _find_node_ids_by_family(run_state.map_runtime_state, "combat")
	var side_mission_target_node_id: int = MapRuntimeStateScript.NO_PENDING_NODE_ID
	for node_id in combat_node_ids:
		if node_id != side_mission_node_id:
			side_mission_target_node_id = node_id
			break
	assert(side_mission_target_node_id != MapRuntimeStateScript.NO_PENDING_NODE_ID, "Expected a combat node for accepted hamlet save payload.")
	run_state.map_runtime_state.save_support_node_runtime_state(rest_node_id, {
		"support_type": "rest",
		"unavailable_offer_ids": ["rest_once"],
	})
	run_state.map_runtime_state.save_support_node_runtime_state(merchant_node_id, {
		"support_type": "merchant",
		"unavailable_offer_ids": ["buy_traveler_bread_x1"],
	})
	run_state.map_runtime_state.save_side_mission_node_runtime_state(side_mission_node_id, {
		"support_type": "hamlet",
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
	assert(String(restored_side_mission_state.get("mission_status", "")) == "accepted", "Expected restored map state to preserve accepted hamlet status by node id.")
	assert(String(restored_side_mission_state.get("target_enemy_definition_id", "")) == "barbed_hunter", "Expected restored map state to preserve the marked hamlet enemy by node id.")


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
	run_state.configure_run_seed(1)
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


func test_combat_enemy_selection_varies_by_seed_but_stays_deterministic() -> void:
	var loader: ContentLoader = ContentLoaderScript.new()
	var selection_policy: EnemySelectionPolicy = EnemySelectionPolicy.new()
	var stage_two_enemy_ids: Array[String] = selection_policy.list_combat_enemy_definition_ids(loader, 2)
	assert(stage_two_enemy_ids.size() >= 3, "Expected stage 2 to expose enough minor enemies for seed-variation coverage.")

	var run_a: RunState = RunStateScript.new()
	run_a.reset_for_new_run()
	run_a.configure_run_seed(99)
	run_a.stage_index = 2
	run_a.map_runtime_state.current_node_id = 1

	var mirrored_run_a: RunState = RunStateScript.new()
	mirrored_run_a.reset_for_new_run()
	mirrored_run_a.configure_run_seed(99)
	mirrored_run_a.stage_index = 2
	mirrored_run_a.map_runtime_state.current_node_id = 1

	var run_b: RunState = RunStateScript.new()
	run_b.reset_for_new_run()
	run_b.configure_run_seed(123)
	run_b.stage_index = 2
	run_b.map_runtime_state.current_node_id = 1

	var resolved_a: String = selection_policy.resolve_combat_enemy_definition_id(loader, run_a, "combat")
	var mirrored_resolved_a: String = selection_policy.resolve_combat_enemy_definition_id(loader, mirrored_run_a, "combat")
	var resolved_b: String = selection_policy.resolve_combat_enemy_definition_id(loader, run_b, "combat")
	assert(resolved_a == mirrored_resolved_a, "Expected the same run seed and node context to reproduce the same minor enemy selection.")
	assert(stage_two_enemy_ids.has(resolved_a), "Expected the seeded stage-2 enemy pick to stay inside the stage-tagged minor pool.")
	assert(stage_two_enemy_ids.has(resolved_b), "Expected alternate seeded stage-2 enemy pick to stay inside the stage-tagged minor pool.")
	assert(resolved_a != resolved_b, "Expected different run seeds to shift the stage-local minor enemy order.")


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
	assert(int(family_counts.get("hamlet", 0)) == 1, "Expected scatter maps to keep 1 dedicated hamlet node.")
	assert(int(family_counts.get("key", 0)) == 1, "Expected scatter maps to keep 1 key node.")
	assert(int(family_counts.get("boss", 0)) == 1, "Expected scatter maps to keep 1 boss node.")
	assert(int(family_counts.get(expected_opening_support_family, 0)) == 1, "Expected opening support layout to resolve into one opening support node.")
	assert(int(family_counts.get(expected_late_support_family, 0)) == 1, "Expected late support layout to resolve into one late support node.")

	var depth_by_node_id: Dictionary = _build_depth_map_from_start(map_runtime_state)
	assert(depth_by_node_id.size() == 14, "Expected connected scatter maps to have depth map entries for all 14 nodes.")
	var family_budget_slots: Dictionary = map_runtime_state.build_family_budget_slot_snapshot()
	for role_name in [
		MapRuntimeStateScript.SCATTER_ROLE_OPENING_COMBAT,
		MapRuntimeStateScript.SCATTER_ROLE_OPENING_REWARD,
		MapRuntimeStateScript.SCATTER_ROLE_OPENING_SUPPORT,
		MapRuntimeStateScript.SCATTER_ROLE_LATE_SUPPORT,
		MapRuntimeStateScript.SCATTER_ROLE_EVENT,
		MapRuntimeStateScript.SCATTER_ROLE_SIDE_MISSION,
		MapRuntimeStateScript.SCATTER_ROLE_KEY,
		MapRuntimeStateScript.SCATTER_ROLE_BOSS,
	]:
		assert(
			family_budget_slots.has(role_name),
			"Expected controlled scatter runtime to publish the reserved %s slot for later family placement continuity." % role_name
		)

	var max_depth: int = 0
	for depth in depth_by_node_id.values():
		max_depth = max(max_depth, int(depth))

	var start_adjacent_count: int = int(map_runtime_state.get_adjacent_node_ids(0).size())
	assert(start_adjacent_count == 4, "Expected controlled scatter fallback topology to expose 3 main routes plus 1 short spur from the start.")
	assert(int(_count_same_depth_reconnect_links(map_runtime_state)) >= 1, "Expected scatter topology to include at least one late reconnect link.")
	assert(int(_count_same_depth_reconnect_links_at_or_beyond_depth(map_runtime_state, MapRuntimeStateScript.SCATTER_RECONNECT_DEPTH_LATE)) >= 1, "Expected scatter topology to keep at least one outer-ring reconnect link at the late reconnect depth.")
	assert(int(_count_extra_edges_from_runtime(map_runtime_state)) >= 1 and int(_count_extra_edges_from_runtime(map_runtime_state)) <= 2, "Expected controlled scatter topology to keep reconnect budget inside [1, 2].")
	var start_adjacent_families: Dictionary = {}
	var start_adjacent_combat_count: int = 0
	var start_adjacent_leaf_count: int = 0
	var start_adjacent_leaf_family: String = ""
	for adjacent_node_id in map_runtime_state.get_adjacent_node_ids(0):
		var resolved_adjacent_node_id: int = int(adjacent_node_id)
		var adjacent_family: String = String(map_runtime_state.get_node_family(resolved_adjacent_node_id))
		start_adjacent_families[adjacent_family] = true
		if adjacent_family == "combat":
			start_adjacent_combat_count += 1
		if int(map_runtime_state.get_adjacent_node_ids(resolved_adjacent_node_id).size()) == 1:
			start_adjacent_leaf_count += 1
			start_adjacent_leaf_family = adjacent_family
	assert(bool(start_adjacent_families.get("combat", false)), "Expected start adjacency to preserve an early combat route.")
	assert(bool(start_adjacent_families.get("reward", false)), "Expected start adjacency to preserve an early reward route.")
	assert(bool(start_adjacent_families.get(expected_opening_support_family, false)), "Expected start adjacency to preserve an early support route.")
	assert(start_adjacent_combat_count >= 2, "Expected the fallback opening shell to keep one main combat route plus one short combat spur.")
	assert(start_adjacent_leaf_count == 1, "Expected the fallback opening shell to keep exactly one short leaf spur adjacent to the start.")
	assert(start_adjacent_leaf_family == "combat", "Expected the short opening spur to remain a combat-family detour instead of stealing reward or support ownership.")

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
	var branch_root_by_node_id: Dictionary = _build_branch_root_map_from_runtime(map_runtime_state)
	var reconnect_node_ids: Dictionary = _build_runtime_same_depth_reconnect_node_set(map_runtime_state)
	var reward_node_id: int = _find_node_id_by_family(map_runtime_state, "reward")
	var key_node_id: int = map_runtime_state.get_stage_key_node_id()
	var boss_node_id: int = map_runtime_state.get_boss_node_id()
	var event_node_id: int = _find_node_id_by_family(map_runtime_state, "event")
	var side_mission_node_id: int = _find_node_id_by_family(map_runtime_state, "hamlet")
	var late_support_node_id: int = _find_node_id_by_family(map_runtime_state, expected_late_support_family)
	var opening_support_node_id: int = _find_node_id_by_family(map_runtime_state, expected_opening_support_family)
	assert(int(family_budget_slots.get(MapRuntimeStateScript.SCATTER_ROLE_OPENING_REWARD, MapRuntimeStateScript.NO_PENDING_NODE_ID)) == reward_node_id, "Expected reward slot reservation to resolve to the actual reward node.")
	assert(int(family_budget_slots.get(MapRuntimeStateScript.SCATTER_ROLE_OPENING_SUPPORT, MapRuntimeStateScript.NO_PENDING_NODE_ID)) == opening_support_node_id, "Expected opening-support slot reservation to resolve to the actual opening support node.")
	assert(int(family_budget_slots.get(MapRuntimeStateScript.SCATTER_ROLE_LATE_SUPPORT, MapRuntimeStateScript.NO_PENDING_NODE_ID)) == late_support_node_id, "Expected late-support slot reservation to resolve to the actual late support node.")
	assert(int(family_budget_slots.get(MapRuntimeStateScript.SCATTER_ROLE_EVENT, MapRuntimeStateScript.NO_PENDING_NODE_ID)) == event_node_id, "Expected event slot reservation to resolve to the actual event node.")
	assert(int(family_budget_slots.get(MapRuntimeStateScript.SCATTER_ROLE_SIDE_MISSION, MapRuntimeStateScript.NO_PENDING_NODE_ID)) == side_mission_node_id, "Expected hamlet slot reservation to resolve to the actual hamlet node.")
	assert(int(family_budget_slots.get(MapRuntimeStateScript.SCATTER_ROLE_KEY, MapRuntimeStateScript.NO_PENDING_NODE_ID)) == key_node_id, "Expected key slot reservation to resolve to the actual key node.")
	assert(int(family_budget_slots.get(MapRuntimeStateScript.SCATTER_ROLE_BOSS, MapRuntimeStateScript.NO_PENDING_NODE_ID)) == boss_node_id, "Expected boss slot reservation to resolve to the actual boss node.")
	assert(key_node_id >= 0, "Expected scatter maps to include a key node.")
	assert(boss_node_id >= 0, "Expected scatter maps to include a boss node.")
	assert(event_node_id >= 0, "Expected scatter maps to include an event node.")
	assert(side_mission_node_id >= 0, "Expected scatter maps to include a hamlet node.")
	assert(late_support_node_id >= 0, "Expected scatter maps to include the late support placement.")
	assert(opening_support_node_id >= 0, "Expected scatter maps to include the opening support placement.")
	assert(branch_root_by_node_id.get(reward_node_id, -1) != branch_root_by_node_id.get(opening_support_node_id, -1), "Expected reward placement to stay on a different opening branch root than opening support.")
	assert(int(depth_by_node_id.get(key_node_id, -1)) >= max(2, max_depth - 1), "Expected key placement to be biased to outer layers.")
	assert(int(depth_by_node_id.get(boss_node_id, -1)) == max_depth, "Expected boss placement to be pinned near the outer-most layer.")
	assert(branch_root_by_node_id.get(late_support_node_id, -1) == branch_root_by_node_id.get(opening_support_node_id, -1), "Expected late support placement to stay on the same support lineage as the opening support node.")
	assert(map_runtime_state.get_adjacent_node_ids(opening_support_node_id).has(late_support_node_id), "Expected late support placement to stay directly adjacent to the opening support node.")
	assert((_build_path_between_nodes(map_runtime_state, key_node_id, boss_node_id).size() - 1) >= 2, "Expected key-to-boss push not to collapse into an immediate adjacent click.")
	assert(int(depth_by_node_id.get(side_mission_node_id, -1)) >= 3, "Expected side mission placement to stay on an optional late detour.")
	assert(_is_runtime_leaf_like_node(map_runtime_state, side_mission_node_id) or int(map_runtime_state.get_adjacent_node_ids(side_mission_node_id).size()) <= 2, "Expected side mission placement to feel like an optional branch detour instead of a dense hub.")
	assert(not map_runtime_state.get_adjacent_node_ids(0).has(event_node_id), "Expected event placement not to collapse into immediate start adjacency.")
	assert(int(map_runtime_state.get_adjacent_node_ids(event_node_id).size()) >= 2 or reconnect_node_ids.has(event_node_id), "Expected event placement to stay on a connector or controlled detour pocket.")


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


func _configure_seed_for_predicted_roadside_adjacent_family(
	run_state: RunState,
	coordinator: RefCounted,
	target_family: String,
	max_seed: int = 512,
	required_choice_effect_type: String = "",
) -> Dictionary:
	if run_state == null or coordinator == null:
		return {}
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	if map_runtime_state == null:
		return {}
	var stream_name: String = String(coordinator.ROADSIDE_ENCOUNTER_STREAM_NAME)
	var trigger_chance: float = float(coordinator.ROADSIDE_ENCOUNTER_TRIGGER_CHANCE)
	var from_node_id: int = map_runtime_state.current_node_id
	for seed in range(1, max_seed + 1):
		run_state.configure_run_seed(seed)
		run_state.rng_stream_states.clear()
		for adjacent_node_id in map_runtime_state.get_adjacent_node_ids(from_node_id):
			var node_id: int = int(adjacent_node_id)
			if String(map_runtime_state.get_node_family(node_id)) != target_family:
				continue
			var predicted_open: bool = _predict_roadside_open(
				run_state,
				stream_name,
				trigger_chance,
				from_node_id,
				node_id,
				target_family,
			)
			if not predicted_open:
				continue
			if not required_choice_effect_type.is_empty():
				var preview_event_state: EventState = EventState.new()
				preview_event_state.setup_for_node(
					node_id,
					run_state.stage_index,
					"roadside_encounter",
					seed,
					_build_test_roadside_trigger_context(run_state)
				)
				var has_required_choice_effect: bool = false
				for choice_variant in preview_event_state.choices:
					if typeof(choice_variant) != TYPE_DICTIONARY:
						continue
					var choice: Dictionary = choice_variant
					if String(choice.get("effect_type", "")) == required_choice_effect_type:
						has_required_choice_effect = true
						break
				if not has_required_choice_effect:
					continue
			return {
				"seed": seed,
				"target_node_id": node_id,
				"from_node_id": from_node_id,
			}
	run_state.rng_stream_states.clear()
	return {}


func _build_test_roadside_trigger_context(run_state: RunState) -> Dictionary:
	if run_state == null:
		return {}
	var max_hp: int = max(1, RunStateScript.DEFAULT_PLAYER_HP)
	return {
		EventStateScript.TRIGGER_STAT_HUNGER: run_state.hunger,
		EventStateScript.TRIGGER_STAT_HP_PERCENT: (float(run_state.player_hp) / float(max_hp)) * 100.0,
		EventStateScript.TRIGGER_STAT_GOLD: run_state.gold,
	}


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


func _build_branch_root_map_from_runtime(map_runtime_state: RefCounted) -> Dictionary:
	var depth_by_node_id: Dictionary = _build_depth_map_from_start(map_runtime_state)
	var sorted_node_ids: Array[int] = []
	for node_snapshot in map_runtime_state.build_node_snapshots():
		sorted_node_ids.append(int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)))
	sorted_node_ids.sort()
	var parent_by_node_id: Dictionary = {0: MapRuntimeStateScript.NO_PENDING_NODE_ID}
	for node_id in sorted_node_ids:
		if node_id == 0:
			continue
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		if node_depth == 1:
			parent_by_node_id[node_id] = 0
			continue
		var parent_candidates: Array[int] = []
		for adjacent_node_id in map_runtime_state.get_adjacent_node_ids(node_id):
			if int(depth_by_node_id.get(int(adjacent_node_id), -1)) == node_depth - 1:
				parent_candidates.append(int(adjacent_node_id))
		parent_candidates.sort()
		assert(not parent_candidates.is_empty(), "Expected reachable runtime nodes to keep at least one shallower parent candidate.")
		parent_by_node_id[node_id] = parent_candidates[0]
	var branch_root_by_node_id: Dictionary = {0: 0}
	for node_id in sorted_node_ids:
		if node_id == 0:
			continue
		var parent_node_id: int = int(parent_by_node_id.get(node_id, MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if parent_node_id == 0:
			branch_root_by_node_id[node_id] = node_id
			continue
		branch_root_by_node_id[node_id] = int(branch_root_by_node_id.get(parent_node_id, parent_node_id))
	return branch_root_by_node_id


func _build_runtime_children_count_map(map_runtime_state: RefCounted) -> Dictionary:
	var depth_by_node_id: Dictionary = _build_depth_map_from_start(map_runtime_state)
	var sorted_node_ids: Array[int] = []
	for node_snapshot in map_runtime_state.build_node_snapshots():
		sorted_node_ids.append(int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)))
	sorted_node_ids.sort()
	var children_count_by_node_id: Dictionary = {}
	for node_id in sorted_node_ids:
		children_count_by_node_id[node_id] = 0
	for node_id in sorted_node_ids:
		if node_id == 0:
			continue
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		if node_depth <= 0:
			continue
		var parent_candidates: Array[int] = []
		for adjacent_node_id in map_runtime_state.get_adjacent_node_ids(node_id):
			if int(depth_by_node_id.get(int(adjacent_node_id), -1)) == node_depth - 1:
				parent_candidates.append(int(adjacent_node_id))
		parent_candidates.sort()
		if parent_candidates.is_empty():
			continue
		var parent_node_id: int = parent_candidates[0]
		children_count_by_node_id[parent_node_id] = int(children_count_by_node_id.get(parent_node_id, 0)) + 1
	return children_count_by_node_id


func _is_runtime_leaf_like_node(map_runtime_state: RefCounted, node_id: int) -> bool:
	var depth_by_node_id: Dictionary = _build_depth_map_from_start(map_runtime_state)
	var children_count_by_node_id: Dictionary = _build_runtime_children_count_map(map_runtime_state)
	return int(depth_by_node_id.get(node_id, 0)) >= 2 and int(children_count_by_node_id.get(node_id, 0)) == 0


func _build_runtime_same_depth_reconnect_node_set(map_runtime_state: RefCounted) -> Dictionary:
	var reconnect_node_ids: Dictionary = {}
	var depth_by_node_id: Dictionary = _build_depth_map_from_start(map_runtime_state)
	var seen_edges: Dictionary = {}
	for node_snapshot in map_runtime_state.build_node_snapshots():
		var node_id: int = int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		for adjacent_node_id in map_runtime_state.get_adjacent_node_ids(node_id):
			var adjacent_depth: int = int(depth_by_node_id.get(int(adjacent_node_id), -1))
			var left_id: int = min(node_id, int(adjacent_node_id))
			var right_id: int = max(node_id, int(adjacent_node_id))
			var edge_key: String = "%d:%d" % [left_id, right_id]
			if seen_edges.has(edge_key):
				continue
			seen_edges[edge_key] = true
			if node_depth < 2 or adjacent_depth < 2 or node_depth != adjacent_depth:
				continue
			reconnect_node_ids[node_id] = true
			reconnect_node_ids[int(adjacent_node_id)] = true
	return reconnect_node_ids


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


func _count_same_depth_reconnect_links_at_or_beyond_depth(map_runtime_state: RefCounted, minimum_depth: int) -> int:
	var link_count: int = 0
	var depth_by_node_id: Dictionary = _build_depth_map_from_start(map_runtime_state)
	var seen_edges: Dictionary = {}
	for node_snapshot in map_runtime_state.build_node_snapshots():
		var node_id: int = int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		for adjacent_node_id in map_runtime_state.get_adjacent_node_ids(node_id):
			var adjacent_depth: int = int(depth_by_node_id.get(int(adjacent_node_id), -1))
			var left_id: int = min(node_id, int(adjacent_node_id))
			var right_id: int = max(node_id, int(adjacent_node_id))
			var edge_key: String = "%d:%d" % [left_id, right_id]
			if seen_edges.has(edge_key):
				continue
			seen_edges[edge_key] = true
			if node_depth < minimum_depth or adjacent_depth < minimum_depth or node_depth != adjacent_depth:
				continue
			link_count += 1
	return link_count


func _count_extra_edges_from_runtime(map_runtime_state: RefCounted) -> int:
	var directed_edge_count: int = 0
	for node_snapshot in map_runtime_state.build_node_snapshots():
		var node_id: int = int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		directed_edge_count += map_runtime_state.get_adjacent_node_ids(node_id).size()
	return max(0, int(directed_edge_count / 2) - (int(map_runtime_state.get_node_count()) - 1))


func _build_runtime_graph_signature(map_runtime_state: RefCounted) -> String:
	var fragments: Array[String] = []
	for node_snapshot in map_runtime_state.build_node_snapshots():
		var node_id: int = int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var adjacent_ids: PackedInt32Array = map_runtime_state.get_adjacent_node_ids(node_id)
		var adjacent_fragment: Array[String] = []
		for adjacent_node_id in adjacent_ids:
			adjacent_fragment.append(str(int(adjacent_node_id)))
		fragments.append("%d:%s:%s" % [
			node_id,
			String(node_snapshot.get("node_family", "")),
			",".join(adjacent_fragment),
		])
	fragments.sort()
	return "|".join(fragments)


func _build_runtime_topology_signature(map_runtime_state: RefCounted) -> String:
	var fragments: Array[String] = []
	for node_snapshot in map_runtime_state.build_node_snapshots():
		var node_id: int = int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var adjacent_ids: PackedInt32Array = map_runtime_state.get_adjacent_node_ids(node_id)
		var adjacent_fragment: Array[String] = []
		for adjacent_node_id in adjacent_ids:
			adjacent_fragment.append(str(int(adjacent_node_id)))
		fragments.append("%d:%s" % [node_id, ",".join(adjacent_fragment)])
	fragments.sort()
	return "|".join(fragments)


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


func _build_offer_id_signature(offers: Array[Dictionary]) -> String:
	var offer_ids: Array[String] = []
	for offer in offers:
		offer_ids.append(String(offer.get("offer_id", "")))
	return "|".join(offer_ids)


func _count_occurrences(values: Array, expected_value: String) -> int:
	var count: int = 0
	for value in values:
		if String(value) == expected_value:
			count += 1
	return count


func _seed_accepted_hamlet_state(
	map_runtime_state: RefCounted,
	hamlet_node_id: int,
	mission_type: String,
	target_node_id: int,
	quest_item_definition_id: String = ""
) -> void:
	map_runtime_state.save_side_mission_node_runtime_state(hamlet_node_id, {
		"support_type": "hamlet",
		"mission_definition_id": _definition_id_for_mission_type(mission_type),
		"mission_type": mission_type,
		"mission_status": "accepted",
		"target_node_id": target_node_id,
		"target_enemy_definition_id": "",
		"quest_item_definition_id": quest_item_definition_id,
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


func _definition_id_for_mission_type(mission_type: String) -> String:
	match mission_type:
		"deliver_supplies":
			return "deliver_supplies"
		"rescue_missing_scout":
			return "rescue_missing_scout"
		"bring_proof":
			return "bring_proof"
		_:
			return "trail_contract_hunt"


func _build_map_explore_context(seed: int = 1, configure_seed: bool = true) -> Dictionary:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	if configure_seed:
		run_state.configure_run_seed(seed)
	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	return {
		"flow_manager": flow_manager,
		"run_state": run_state,
		"coordinator": coordinator,
	}


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
