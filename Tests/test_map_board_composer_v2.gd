# Layer: Tests
extends SceneTree
class_name TestMapBoardComposerV2

const MapBoardComposerV2Script = preload("res://Game/UI/map_board_composer_v2.gd")
const ALLOWED_PATH_FAMILIES := [
	"short_straight",
	"gentle_curve",
	"wider_curve",
	"outward_reconnecting_arc",
]


func _init() -> void:
	test_map_board_composer_is_deterministic_from_saved_truth()
	test_map_board_composer_assigns_deterministic_path_families()
	test_map_board_composer_survives_save_restore_without_layout_fields()
	test_map_board_composer_uses_run_seed_for_controlled_random_variation()
	test_map_board_composer_surfaces_side_mission_highlights()
	print("test_map_board_composer_v2: all assertions passed")
	quit()


func test_map_board_composer_is_deterministic_from_saved_truth() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(99)

	var composition_a: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var composition_b: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))

	assert(
		int(composition_a.get("seed", 0)) == int(composition_b.get("seed", -1)),
		"Expected board composition to hash to the same deterministic seed on repeated compose calls."
	)
	var world_positions_a: Dictionary = composition_a.get("world_positions", {})
	var world_positions_b: Dictionary = composition_b.get("world_positions", {})
	assert(
		world_positions_a.get(1, Vector2.ZERO) == world_positions_b.get(1, Vector2.ZERO),
		"Expected repeated compose calls to keep node 1 at the same derived board position."
	)
	assert(
		_nearest_visible_distance_from_node(composition_a, 0) >= 150.0,
		"Expected the center-start shell to keep readable spacing around the current anchor."
	)
	assert(
		_min_visible_node_spacing(composition_a) >= 128.0,
		"Expected visible node spacing to stay inside the portrait readability floor."
	)
	assert(
		_visible_node_ids(composition_a).has(0) and not _visible_node_ids(composition_a).has(8),
		"Expected the current start node to stay visible while the deeper hidden boss node remains concealed at run start."
	)
	var visible_edges: Array = composition_a.get("visible_edges", [])
	assert(not visible_edges.is_empty(), "Expected the board composer to emit curved visible edge paths for the discovered pocket.")
	var first_edge: Dictionary = visible_edges[0]
	var first_edge_points: PackedVector2Array = first_edge.get("points", PackedVector2Array())
	var repeated_first_edge: Dictionary = (composition_b.get("visible_edges", [])[0] as Dictionary)
	assert(first_edge_points.size() > 2, "Expected visible edges to be sampled into a curved polyline, not a 2-point straight segment.")
	assert(
		ALLOWED_PATH_FAMILIES.has(String(first_edge.get("path_family", ""))),
		"Expected visible edges to advertise one of the deterministic path family labels."
	)
	assert(
		String(first_edge.get("path_family", "")) == String(repeated_first_edge.get("path_family", "")),
		"Expected repeated compose calls to keep the same path family classification for the same visible edge."
	)
	var current_world_position: Vector2 = world_positions_a.get(0, Vector2.ZERO)
	assert(
		first_edge_points[0].distance_to(current_world_position) > 8.0,
		"Expected edge rendering to start from the clearing edge instead of the current-node center."
	)
	var first_edge_to_position: Vector2 = world_positions_a.get(int(first_edge.get("to_node_id", -1)), Vector2.ZERO)
	assert(
		first_edge_points[first_edge_points.size() - 1].distance_to(first_edge_to_position) > 8.0,
		"Expected edge rendering to return into the target clearing edge instead of stopping at the node center."
	)
	assert(
		(composition_a.get("forest_shapes", []) as Array).size() > 0,
		"Expected the prototype composer to emit forest/canopy fill shapes around the visible pocket."
	)


func test_map_board_composer_assigns_deterministic_path_families() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var observed_family_set: Dictionary = {}
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 3)

		var composition_a: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
		var composition_b: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
		var families_a: Array[String] = _visible_edge_families(composition_a)
		var families_b: Array[String] = _visible_edge_families(composition_b)
		assert(not families_a.is_empty(), "Expected revealed map pockets to expose visible edge families.")
		assert(
			families_a == families_b,
			"Expected path family assignment to stay deterministic for the same realized graph and compose inputs."
		)
		for family in families_a:
			assert(
				ALLOWED_PATH_FAMILIES.has(family),
				"Expected every visible edge family to resolve through the supported deterministic family set."
			)
			observed_family_set[family] = true
	assert(
		observed_family_set.size() >= 3,
		"Expected seeded/local-geometry variation to surface at least three distinct edge path families."
	)


func test_map_board_composer_survives_save_restore_without_layout_fields() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(77)
	run_state.map_runtime_state.move_to_node(1)
	run_state.map_runtime_state.mark_node_resolved(1)
	var original_composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))

	var save_data: Dictionary = run_state.to_save_dict()
	assert(
		not save_data.has("map_board_layout") and not save_data.has("node_screen_positions"),
		"Expected save data to stay free of presentation-owned board layout payload."
	)
	var restored_run_state: RunState = RunState.new()
	restored_run_state.load_from_save_dict(save_data)
	var restored_composition: Dictionary = composer.call("compose", restored_run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))

	assert(
		original_composition.get("world_positions", {}).get(6, Vector2.ZERO) == restored_composition.get("world_positions", {}).get(6, Vector2.ZERO),
		"Expected save/restore to reproduce the same derived board position for a revealed late node."
	)
	assert(
		original_composition.get("focus_offset", Vector2.ZERO) == restored_composition.get("focus_offset", Vector2.ZERO),
		"Expected save/restore to reproduce the same derived focus offset without saving presentation state."
	)


func test_map_board_composer_uses_run_seed_for_controlled_random_variation() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state_a: RunState = RunState.new()
	run_state_a.reset_for_new_run()
	run_state_a.configure_run_seed(11)
	var run_state_b: RunState = RunState.new()
	run_state_b.reset_for_new_run()
	run_state_b.configure_run_seed(13)

	var composition_a: Dictionary = composer.call("compose", run_state_a, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var composition_b: Dictionary = composer.call("compose", run_state_b, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	assert(
		composition_a.get("world_positions", {}).get(1, Vector2.ZERO) != composition_b.get("world_positions", {}).get(1, Vector2.ZERO),
		"Expected run seed changes to perturb composer placement deterministically for controlled-random variation."
	)


func test_map_board_composer_surfaces_side_mission_highlights() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(41)

	var side_mission_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "side_mission")
	var target_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "combat")
	assert(side_mission_node_id >= 0, "Expected one side-mission node in the procedural map runtime.")
	assert(target_node_id >= 0, "Expected at least one combat node for side-mission highlight coverage.")

	run_state.map_runtime_state.save_side_mission_node_runtime_state(side_mission_node_id, {
		"support_type": "side_mission",
		"mission_definition_id": "trail_contract_hunt",
		"mission_status": "accepted",
		"target_node_id": target_node_id,
		"target_enemy_definition_id": "barbed_hunter",
		"reward_offers": [],
	})
	var accepted_composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	assert(
		int(accepted_composition.get("side_mission_highlight_node_id", -1)) == target_node_id,
		"Expected accepted side-mission composition to expose the marked combat node highlight."
	)
	assert(
		String(accepted_composition.get("side_mission_highlight_state", "")) == "target",
		"Expected accepted side-mission composition to expose the target highlight state."
	)

	run_state.map_runtime_state.save_side_mission_node_runtime_state(side_mission_node_id, {
		"support_type": "side_mission",
		"mission_definition_id": "trail_contract_hunt",
		"mission_status": "completed",
		"target_node_id": target_node_id,
		"target_enemy_definition_id": "barbed_hunter",
		"reward_offers": [],
	})
	var completed_composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	assert(
		int(completed_composition.get("side_mission_highlight_node_id", -1)) == side_mission_node_id,
		"Expected completed side-mission composition to expose the return-to-contract highlight."
	)
	assert(
		String(completed_composition.get("side_mission_highlight_state", "")) == "return",
		"Expected completed side-mission composition to expose the return highlight state."
	)


func _visible_node_ids(composition: Dictionary) -> PackedInt32Array:
	var node_ids := PackedInt32Array()
	for node_variant in composition.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		node_ids.append(int((node_variant as Dictionary).get("node_id", -1)))
	return node_ids


func _visible_edge_families(composition: Dictionary) -> Array[String]:
	var families: Array[String] = []
	for edge_variant in composition.get("visible_edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		families.append(String((edge_variant as Dictionary).get("path_family", "")))
	return families


func _nearest_visible_distance_from_node(composition: Dictionary, anchor_node_id: int) -> float:
	var world_positions: Dictionary = composition.get("world_positions", {})
	var anchor_position: Vector2 = world_positions.get(anchor_node_id, Vector2.ZERO)
	var nearest_distance: float = INF
	for node_variant in composition.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var node_id: int = int(node_entry.get("node_id", -1))
		if node_id == anchor_node_id:
			continue
		nearest_distance = min(nearest_distance, anchor_position.distance_to(world_positions.get(node_id, Vector2.ZERO)))
	return nearest_distance


func _min_visible_node_spacing(composition: Dictionary) -> float:
	var world_positions: Dictionary = composition.get("world_positions", {})
	var visible_node_ids: Array[int] = []
	for node_variant in composition.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		visible_node_ids.append(int((node_variant as Dictionary).get("node_id", -1)))
	var minimum_spacing: float = INF
	for left_index in range(visible_node_ids.size()):
		for right_index in range(left_index + 1, visible_node_ids.size()):
			var left_position: Vector2 = world_positions.get(visible_node_ids[left_index], Vector2.ZERO)
			var right_position: Vector2 = world_positions.get(visible_node_ids[right_index], Vector2.ZERO)
			minimum_spacing = min(minimum_spacing, left_position.distance_to(right_position))
	return minimum_spacing


func _advance_visible_branch(run_state: RunState, steps: int) -> void:
	var visited_node_ids: Dictionary = {int(run_state.map_runtime_state.current_node_id): true}
	for _step in range(steps):
		var chosen_node_id: int = -1
		for adjacent_node_id in run_state.map_runtime_state.get_adjacent_node_ids():
			if visited_node_ids.has(adjacent_node_id):
				continue
			chosen_node_id = int(adjacent_node_id)
			break
		if chosen_node_id < 0:
			for adjacent_node_id in run_state.map_runtime_state.get_adjacent_node_ids():
				if int(adjacent_node_id) == 0:
					continue
				chosen_node_id = int(adjacent_node_id)
				break
		if chosen_node_id < 0:
			return
		run_state.map_runtime_state.move_to_node(chosen_node_id)
		run_state.map_runtime_state.mark_node_resolved(chosen_node_id)
		visited_node_ids[chosen_node_id] = true


func _find_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == node_family:
			return int(node_snapshot.get("node_id", -1))
	return -1
