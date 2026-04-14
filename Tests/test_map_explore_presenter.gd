# Layer: Tests
extends SceneTree
class_name TestMapExplorePresenter

const MapExplorePresenterScript = preload("res://Game/UI/map_explore_presenter.gd")


func _init() -> void:
	test_map_presenter_builds_runtime_graph_labels()
	print("test_map_explore_presenter: all assertions passed")
	quit()


func test_map_presenter_builds_runtime_graph_labels() -> void:
	var presenter: RefCounted = MapExplorePresenterScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.stage_index = 2
	run_state.player_hp = 48
	run_state.hunger = 11
	run_state.gold = 17
	run_state.inventory_state.weapon_instance["current_durability"] = 9
	run_state.map_runtime_state.move_to_node(1)
	run_state.map_runtime_state.mark_node_resolved(1)

	assert(
		presenter.call("build_title_text", run_state) == "Stage 2 Route",
		"Expected map presenter title to reflect the current stage."
	)
	assert(
		String(presenter.call("build_progress_text", run_state)).contains("open"),
		"Expected map presenter progress text to foreground reachable roads."
	)
	assert(
		presenter.call("build_run_status_text", run_state) == "HP 48 | Hunger 11 | Gold 17 | Iron Sword (9)",
		"Expected map presenter to summarize the active run snapshot."
	)
	assert(
		presenter.call("build_hp_status_text", run_state) == "HP 48",
		"Expected map presenter to expose a compact HP status row read."
	)
	assert(
		presenter.call("build_hunger_status_text", run_state) == "Hunger 11",
		"Expected map presenter to expose a compact hunger status row read."
	)
	assert(
		presenter.call("build_durability_status_text", run_state) == "Durability 9",
		"Expected map presenter to expose a compact durability status row read."
	)
	assert(
		presenter.call("build_hp_icon_texture_path") == "res://Assets/Icons/icon_hp.svg",
		"Expected map HP reads to resolve through the dedicated HP icon slot."
	)
	assert(
		presenter.call("build_hunger_icon_texture_path") == "res://Assets/Icons/icon_hunger.svg",
		"Expected map hunger reads to resolve through the dedicated hunger icon slot."
	)
	assert(
		presenter.call("build_durability_icon_texture_path") == "res://Assets/Icons/icon_durability.svg",
		"Expected map durability reads to resolve through the dedicated durability icon slot."
	)
	assert(
		String(presenter.call("build_cluster_read_text", run_state)).contains("Ahead:")
		and String(presenter.call("build_cluster_read_text", run_state)).contains("Reward"),
		"Expected the map presenter to summarize discovered pockets beyond the immediate adjacent shell, including the off-path reward pocket."
	)
	assert(
		presenter.call("build_current_anchor_text", run_state) == "At Combat",
		"Expected map presenter to build a short current-position read from the runtime-owned current node."
	)
	assert(
		String(presenter.call("build_current_anchor_detail_text", run_state)).contains("Key ahead"),
		"Expected current-anchor detail text to reflect runtime-owned key progress."
	)
	assert(
		String(presenter.call("build_current_anchor_detail_text", run_state)).contains("Boss locked"),
		"Expected current-anchor detail text to surface boss-gate legibility before the key is secured."
	)
	assert(
		presenter.call("build_node_family_display_name", "boss") == "Boss Gate",
		"Expected node-family display names to stay presenter-owned for the route board."
	)
	assert(
		presenter.call("build_node_family_display_name", "event") == "Roadside Encounter",
		"Expected event routes to render through the player-facing roadside-encounter label."
	)
	assert(
		presenter.call("build_node_family_display_name", "side_mission") == "Village Request",
		"Expected side-mission routes to expose the player-facing request label."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "combat") == "res://Assets/Icons/icon_attack.svg",
		"Expected combat routes to resolve to the dedicated combat icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "rest") == "res://Assets/Icons/icon_map_rest.svg",
		"Expected rest routes to resolve to the dedicated rest icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "merchant") == "res://Assets/Icons/icon_map_merchant.svg",
		"Expected merchant routes to resolve to the dedicated merchant icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "blacksmith") == "res://Assets/Icons/icon_map_blacksmith.svg",
		"Expected blacksmith routes to resolve to the dedicated blacksmith icon floor."
		)
	assert(
		presenter.call("build_route_icon_texture_path", "reward") == "res://Assets/Icons/icon_reward.svg",
		"Expected reward routes to resolve to the reward icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "event") == "res://Assets/Icons/icon_node_marker.svg",
		"Expected event routes to reuse the narrow event marker icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "side_mission") == "res://Assets/Icons/icon_map_side_mission.svg",
		"Expected side-mission routes to use the dedicated contract icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "key") == "res://Assets/Icons/icon_confirm.svg",
		"Expected key routes to use the dedicated key marker icon treatment."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "boss") == "res://Assets/Icons/icon_enemy_intent_heavy.svg",
		"Expected boss routes to use the dedicated boss marker icon treatment."
	)
	var route_models: Array[Dictionary] = presenter.call("build_route_view_models", run_state, 6)
	var visible_route_models: Array[Dictionary] = []
	for route_model in route_models:
		if bool(route_model.get("visible", false)):
			visible_route_models.append(route_model)

	assert(
		String(route_models[0].get("text", "")) == "Combat\nReachable",
		"Expected unresolved adjacent combat nodes to sort ahead of revisit-only traversal nodes."
	)
	assert(
		String(route_models[0].get("icon_texture_path", "")) == "res://Assets/Icons/icon_attack.svg",
		"Expected route view models to expose the presenter-owned route icon texture path."
	)
	assert(
		String(route_models[0].get("state_chip_text", "")) == "OPEN",
		"Expected route view models to expose compact state-chip text for the shell overlay."
	)
	var spent_start_found: bool = false
	for route_model in visible_route_models:
		if String(route_model.get("text", "")) != "Start\nSpent Path":
			continue
		spent_start_found = true
		assert(
			String(route_model.get("state_chip_text", "")) == "SPENT",
			"Expected resolved start-node traversal to expose the spent-state chip text."
		)
		assert(
			not bool(route_model.get("disabled", true)),
			"Expected spent adjacent routes to remain traversable for revisit positioning."
		)
	assert(spent_start_found, "Expected one visible spent start-path route model after moving off the center anchor.")

	assert(
		visible_route_models.size() == run_state.map_runtime_state.get_adjacent_node_ids().size(),
		"Expected the board to show every adjacent traversal option and only adjacent traversal options."
	)

	var hidden_route_model_index: int = visible_route_models.size()
	if hidden_route_model_index < route_models.size():
		assert(
			not bool(route_models[hidden_route_model_index].get("visible", true)),
			"Expected board slots beyond the adjacent traversal set to stay hidden."
		)
		assert(
			String(route_models[hidden_route_model_index].get("text", "")) == "",
			"Expected hidden board slots to stay empty."
		)
	run_state.map_runtime_state.resolve_stage_key()
	assert(
		String(presenter.call("build_current_anchor_detail_text", run_state)).contains("Key taken"),
		"Expected current-anchor detail text to update once the stage key is resolved."
	)
	assert(
		String(presenter.call("build_current_anchor_detail_text", run_state)).contains("Boss open"),
		"Expected current-anchor detail text to expose boss-gate readiness after key resolution."
	)

	var side_mission_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "side_mission")
	var target_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "combat")
	assert(side_mission_node_id >= 0, "Expected one side-mission node in the runtime-owned map.")
	assert(target_node_id >= 0, "Expected at least one combat node for target-readability coverage.")
	run_state.map_runtime_state.save_side_mission_node_runtime_state(side_mission_node_id, {
		"support_type": "side_mission",
		"mission_definition_id": "trail_contract_hunt",
		"mission_status": "accepted",
		"target_node_id": target_node_id,
		"target_enemy_definition_id": "barbed_hunter",
		"reward_offers": [],
	})
	assert(
		String(presenter.call("build_current_anchor_detail_text", run_state)).contains("Marked target"),
		"Expected current-anchor detail text to surface accepted side-mission target readability."
	)
	run_state.map_runtime_state.save_side_mission_node_runtime_state(side_mission_node_id, {
		"support_type": "side_mission",
		"mission_definition_id": "trail_contract_hunt",
		"mission_status": "completed",
		"target_node_id": target_node_id,
		"target_enemy_definition_id": "barbed_hunter",
		"reward_offers": [],
	})
	assert(
		String(presenter.call("build_current_anchor_detail_text", run_state)).contains("Return marked"),
		"Expected current-anchor detail text to surface completed side-mission return readability."
	)


func _find_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == node_family:
			return int(node_snapshot.get("node_id", -1))
	return -1
