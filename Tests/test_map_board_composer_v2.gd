# Layer: Tests
extends SceneTree
class_name TestMapBoardComposerV2

const MapBoardComposerV2Script = preload("res://Game/UI/map_board_composer_v2.gd")
const MapBoardEdgeRoutingScript = preload("res://Game/UI/map_board_edge_routing.gd")
const MapBoardFillerBuilderScript = preload("res://Game/UI/map_board_filler_builder.gd")
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
	test_map_board_composer_keeps_opening_anchor_near_vertical_center()
	test_map_board_composer_rotates_opening_shell_beyond_the_upper_half()
	test_map_board_composer_uses_lower_board_height_in_late_routes()
	test_map_board_composer_surfaces_known_icons_for_seen_non_adjacent_nodes()
	test_map_board_composer_surfaces_known_icons_for_current_and_adjacent_nodes()
	test_map_board_composer_surfaces_side_quest_highlights()
	test_map_board_composer_keeps_visible_nodes_portrait_safe_without_overlap()
	test_map_board_composer_emits_deterministic_ground_shapes()
	test_map_board_composer_emits_deterministic_filler_shapes()
	test_map_board_composer_emits_deterministic_forest_shapes()
	test_map_board_composer_keeps_layout_backdrop_stable_across_progression()
	test_map_board_composer_keeps_full_edge_layout_stable_across_progression()
	test_map_board_composer_does_not_scale_current_nodes()
	test_map_board_composer_keeps_visible_edges_readable_without_crossings()
	test_map_board_composer_keeps_visible_edges_clear_of_other_node_clearings()
	test_map_board_composer_keeps_visible_edges_inside_board_frame()
	test_map_board_composer_exposes_public_clearing_radius_helper()
	test_map_board_composer_penalizes_edge_hugging_outer_reconnect_fallbacks()
	test_map_board_composer_keeps_outer_reconnect_fallbacks_inside_the_inner_frame()
	test_map_board_composer_keeps_discovered_history_edges_visible()
	test_map_board_composer_keeps_one_visible_outer_reconnect_in_late_route_history()
	test_map_board_composer_prefers_non_reconnect_history_when_crossing_reconnect_conflicts()
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
	assert(
		not String(first_edge.get("trail_texture_path", "")).is_empty(),
		"Expected visible edges to expose a presentation-only trail texture path for the prototype map kit hookup."
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
	var first_visible_node: Dictionary = (composition_a.get("visible_nodes", [])[0] as Dictionary)
	assert(
		not String(first_visible_node.get("node_plate_texture_path", "")).is_empty(),
		"Expected visible nodes to expose a presentation-only node-plate asset path for the prototype kit hookup."
	)
	assert(
		not String(first_visible_node.get("clearing_decal_texture_path", "")).is_empty(),
		"Expected visible nodes to expose a presentation-only clearing-decal asset path for the prototype kit hookup."
	)
	assert(
		(composition_a.get("forest_shapes", []) as Array).size() > 0,
		"Expected the prototype composer to emit forest/canopy fill shapes around the visible pocket."
	)


func test_map_board_composer_assigns_deterministic_path_families() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var observed_family_set: Dictionary = {}
	for scenario_variant in [
		{"seed": 75, "steps": 0},
		{"seed": 11, "steps": 5},
		{"seed": 29, "steps": 5},
		{"seed": 41, "steps": 5},
	]:
		var scenario: Dictionary = scenario_variant
		var seed: int = int(scenario.get("seed", 0))
		var steps: int = int(scenario.get("steps", 0))
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, steps)

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
		observed_family_set.size() == ALLOWED_PATH_FAMILIES.size(),
		"Expected curated opening and late-route board views to surface all four supported path families, not collapse into a smaller visual subset."
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


func test_map_board_composer_keeps_opening_anchor_near_vertical_center() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(99)
	var board_size := Vector2(920, 1180)
	var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
	var world_positions: Dictionary = composition.get("world_positions", {})
	var start_position: Vector2 = world_positions.get(0, Vector2.ZERO)
	assert(start_position != Vector2.ZERO, "Expected the opening anchor node to keep a composed world position.")
	assert(
		start_position.y >= board_size.y * 0.57 and start_position.y <= board_size.y * 0.64,
		"Expected the opening anchor node to stay near the portrait board's vertical center instead of drifting too far upward or downward."
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


func test_map_board_composer_rotates_opening_shell_beyond_the_upper_half() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var observed_above: bool = false
	var observed_below: bool = false
	var observed_left: bool = false
	var observed_right: bool = false
	for seed in range(1, 13):
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
		var world_positions: Dictionary = composition.get("world_positions", {})
		var start_position: Vector2 = world_positions.get(0, Vector2.ZERO)
		for adjacent_node_id in run_state.map_runtime_state.get_adjacent_node_ids(0):
			var branch_position: Vector2 = world_positions.get(int(adjacent_node_id), Vector2.ZERO)
			if branch_position == Vector2.ZERO:
				continue
			var offset: Vector2 = branch_position - start_position
			observed_above = observed_above or offset.y < -24.0
			observed_below = observed_below or offset.y > 24.0
			observed_left = observed_left or offset.x < -24.0
			observed_right = observed_right or offset.x > 24.0
		if observed_above and observed_below and observed_left and observed_right:
			break
	assert(observed_above, "Expected some seeded opening-shell branches to remain above the start anchor.")
	assert(observed_below, "Expected seeded opening-shell branches to sometimes rotate below the start anchor instead of always clustering upward.")
	assert(observed_left and observed_right, "Expected seeded opening-shell branches to span both left and right sides around the start anchor.")


func test_map_board_composer_uses_lower_board_height_in_late_routes() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var board_size := Vector2(920, 1180)
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 5)
		var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
		var visible_bounds: Rect2 = _visible_node_bounds(composition)
		assert(
			visible_bounds.end.y >= board_size.y * 0.80,
			"Expected progressed node scatter to keep using the lower portrait board instead of collapsing into mostly upper / lateral lanes. Seed=%d bounds=%s." % [seed, str(visible_bounds)]
		)
		assert(
			visible_bounds.size.y >= board_size.y * 0.25,
			"Expected progressed node scatter to preserve a meaningful vertical footprint after footprint widening. Seed=%d bounds=%s." % [seed, str(visible_bounds)]
		)


func test_map_board_composer_penalizes_edge_hugging_outer_reconnect_fallbacks() -> void:
	var board_size := Vector2(920.0, 1180.0)
	var p0 := Vector2(452.0, 348.0)
	var p3 := Vector2(216.0, 662.0)
	var edge_hugging_candidate := PackedVector2Array([
		p0,
		Vector2(p0.x, 84.0),
		Vector2(72.0, 84.0),
		Vector2(72.0, p3.y),
		p3,
	])
	var safer_candidate := PackedVector2Array([
		p0,
		Vector2(p0.x, 196.0),
		Vector2(264.0, 196.0),
		Vector2(264.0, p3.y),
		p3,
	])
	var edge_hugging_score: float = MapBoardEdgeRoutingScript.score_outer_reconnect_candidate(
		edge_hugging_candidate,
		p0,
		p3,
		board_size
	)
	var safer_score: float = MapBoardEdgeRoutingScript.score_outer_reconnect_candidate(
		safer_candidate,
		p0,
		p3,
		board_size
	)
	assert(
		edge_hugging_score > safer_score,
		"Expected outer reconnect fallback scoring to demote frame-hugging detours when a more centered candidate is available."
	)


func test_map_board_composer_keeps_outer_reconnect_fallbacks_inside_the_inner_frame() -> void:
	var board_size := Vector2(920.0, 1180.0)
	var p0 := Vector2(786.0, 522.0)
	var p3 := Vector2(212.0, 296.0)
	var fallback_points: PackedVector2Array = MapBoardEdgeRoutingScript.build_outer_reconnect_fallback_points(
		p0,
		p3,
		[],
		7,
		3,
		board_size,
		MapBoardComposerV2Script.MIN_BOARD_MARGIN,
		18.0
	)
	assert(
		fallback_points.size() >= 4,
		"Expected outer reconnect fallback generation to keep a usable multi-segment detour candidate."
	)
	for point_index in range(1, fallback_points.size() - 1):
		var point: Vector2 = fallback_points[point_index]
		assert(
			point.x >= 84.0 and point.x <= board_size.x - 84.0 and point.y >= 96.0 and point.y <= board_size.y - 96.0,
			"Expected outer reconnect fallback points to stay inside the inner board frame instead of hugging the hard edge. Point=%s" % [str(point)]
		)


func test_map_board_composer_surfaces_known_icons_for_seen_non_adjacent_nodes() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(19)
	run_state.map_runtime_state.move_to_node(1)
	run_state.map_runtime_state.mark_node_resolved(1)

	var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var reward_node: Dictionary = _find_visible_node_by_family(composition, "reward", false)
	assert(not reward_node.is_empty(), "Expected a discovered non-adjacent reward node to remain visible after moving deeper into the stage.")
	assert(
		bool(reward_node.get("show_known_icon", false)),
		"Expected discovered non-adjacent nodes to expose known-icon metadata for board rendering."
	)
	assert(
		String(reward_node.get("icon_texture_path", "")) == "res://Assets/Icons/icon_reward.svg",
		"Expected discovered non-adjacent reward nodes to keep their family icon path once they are known."
	)


func test_map_board_composer_surfaces_known_icons_for_current_and_adjacent_nodes() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(29)

	var opening_composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var current_node: Dictionary = _find_visible_node_by_id(opening_composition, int(run_state.map_runtime_state.current_node_id))
	assert(not current_node.is_empty(), "Expected the current map node to stay visible on the composed board.")
	assert(
		bool(current_node.get("show_known_icon", false)),
		"Expected the current node to keep its family icon metadata so standing on it does not hide what the stop is."
	)
	for adjacent_node_id in run_state.map_runtime_state.get_adjacent_node_ids():
		var adjacent_node: Dictionary = _find_visible_node_by_id(opening_composition, int(adjacent_node_id))
		assert(not adjacent_node.is_empty(), "Expected each adjacent discovered node to be visible in the opening pocket.")
		assert(
			bool(adjacent_node.get("show_known_icon", false)),
			"Expected adjacent discovered nodes to keep their family icon metadata for direct readability."
		)


func test_map_board_composer_surfaces_side_quest_highlights() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(41)

	var side_mission_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	var target_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "combat")
	assert(side_mission_node_id >= 0, "Expected one hamlet node in the procedural map runtime.")
	assert(target_node_id >= 0, "Expected at least one combat node for side-quest highlight coverage.")

	run_state.map_runtime_state.save_side_mission_node_runtime_state(side_mission_node_id, {
		"support_type": "hamlet",
		"mission_definition_id": "trail_contract_hunt",
		"mission_status": "accepted",
		"target_node_id": target_node_id,
		"target_enemy_definition_id": "barbed_hunter",
		"reward_offers": [],
	})
	var accepted_composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	assert(
		int(accepted_composition.get("side_quest_highlight_node_id", -1)) == target_node_id,
		"Expected accepted side-quest composition to expose the marked combat node highlight."
	)
	assert(
		String(accepted_composition.get("side_quest_highlight_state", "")) == "target",
		"Expected accepted side-quest composition to expose the target highlight state."
	)

	run_state.map_runtime_state.save_side_mission_node_runtime_state(side_mission_node_id, {
		"support_type": "hamlet",
		"mission_definition_id": "trail_contract_hunt",
		"mission_status": "completed",
		"target_node_id": target_node_id,
		"target_enemy_definition_id": "barbed_hunter",
		"reward_offers": [],
	})
	var completed_composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	assert(
		int(completed_composition.get("side_quest_highlight_node_id", -1)) == side_mission_node_id,
		"Expected completed side-quest composition to expose the return-to-hamlet highlight."
	)
	assert(
		String(completed_composition.get("side_quest_highlight_state", "")) == "return",
		"Expected completed side-quest composition to expose the return highlight state."
	)


func test_map_board_composer_keeps_visible_nodes_portrait_safe_without_overlap() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(29)
	_advance_visible_branch(run_state, 4)
	var board_size := Vector2(920, 1180)
	var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
	var world_positions: Dictionary = composition.get("world_positions", {})
	for node_variant in composition.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var node_id: int = int(node_entry.get("node_id", -1))
		var position: Vector2 = world_positions.get(node_id, Vector2.ZERO)
		assert(position != Vector2.ZERO, "Expected every visible node to have a non-zero world position.")
		assert(
			position.x >= MapBoardComposerV2Script.MIN_BOARD_MARGIN.x and position.x <= board_size.x - MapBoardComposerV2Script.MIN_BOARD_MARGIN.x,
			"Expected visible node placement to stay inside portrait-safe horizontal margins."
		)
		assert(
			position.y >= MapBoardComposerV2Script.MIN_BOARD_MARGIN.y and position.y <= board_size.y - MapBoardComposerV2Script.MIN_BOARD_MARGIN.y,
			"Expected visible node placement to stay inside portrait-safe vertical margins."
		)
	assert(
		_min_visible_node_spacing(composition) >= 120.0,
		"Expected visible node pockets to keep enough spacing for portrait overlays and hit targets."
	)
	var visible_node_ids: PackedInt32Array = _visible_node_ids(composition)
	for edge_variant in composition.get("visible_edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		assert(
			visible_node_ids.has(int(edge_entry.get("from_node_id", -1))) and visible_node_ids.has(int(edge_entry.get("to_node_id", -1))),
			"Expected visible edge rendering not to leak hidden node ids into the composed board pocket."
		)


func test_map_board_composer_emits_deterministic_forest_shapes() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(41)
	_advance_visible_branch(run_state, 3)
	var composition_a: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var composition_b: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var forest_shapes_a: Array = composition_a.get("forest_shapes", [])
	var forest_shapes_b: Array = composition_b.get("forest_shapes", [])
	assert(forest_shapes_a.size() == forest_shapes_b.size(), "Expected repeated compose calls to emit the same number of forest shapes.")
	assert(not forest_shapes_a.is_empty(), "Expected composed boards to emit deterministic forest pocket fill.")
	for index in range(forest_shapes_a.size()):
		var shape_a: Dictionary = forest_shapes_a[index]
		var shape_b: Dictionary = forest_shapes_b[index]
		assert(shape_a.get("family", "") == shape_b.get("family", ""), "Expected forest shape family ordering to stay deterministic.")
		assert(shape_a.get("center", Vector2.ZERO) == shape_b.get("center", Vector2.ZERO), "Expected forest shape centers to stay deterministic.")
		assert(shape_a.get("radius", 0.0) == shape_b.get("radius", -1.0), "Expected forest shape radii to stay deterministic.")
		assert(shape_a.get("tone", Color.WHITE) == shape_b.get("tone", Color.BLACK), "Expected forest shape tones to stay deterministic.")
		assert(shape_a.get("texture_path", "") == shape_b.get("texture_path", ""), "Expected forest shape asset selection to stay deterministic.")
		assert(shape_a.get("rotation_degrees", 0.0) == shape_b.get("rotation_degrees", -999.0), "Expected forest shape rotation metadata to stay deterministic.")
	var canopy_shape: Dictionary = _find_forest_shape_by_family(composition_a, "canopy")
	assert(not canopy_shape.is_empty(), "Expected the prototype map kit hookup to tag at least one canopy shape for textured stamp rendering.")
	assert(
		not String(canopy_shape.get("texture_path", "")).is_empty(),
		"Expected canopy shapes to expose a texture path for forest-pocket stamp hookup."
	)


func test_map_board_composer_emits_deterministic_ground_shapes() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(41)
	_advance_visible_branch(run_state, 3)
	var composition_a: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var composition_b: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var ground_shapes_a: Array = composition_a.get("ground_shapes", [])
	var ground_shapes_b: Array = composition_b.get("ground_shapes", [])
	assert(ground_shapes_a.size() == ground_shapes_b.size(), "Expected repeated compose calls to emit the same number of ground shapes.")
	assert(not ground_shapes_a.is_empty(), "Expected composed boards to emit a deterministic ground/surface payload.")
	for index in range(ground_shapes_a.size()):
		var shape_a: Dictionary = ground_shapes_a[index]
		var shape_b: Dictionary = ground_shapes_b[index]
		assert(shape_a.get("family", "") == shape_b.get("family", ""), "Expected ground shape family ordering to stay deterministic.")
		assert(shape_a.get("center", Vector2.ZERO) == shape_b.get("center", Vector2.ZERO), "Expected ground shape centers to stay deterministic.")
		assert(shape_a.get("half_size", Vector2.ZERO) == shape_b.get("half_size", Vector2.ZERO), "Expected ground shape sizes to stay deterministic.")
		assert(shape_a.get("rotation_degrees", 0.0) == shape_b.get("rotation_degrees", -999.0), "Expected ground shape rotation metadata to stay deterministic.")
		assert(shape_a.get("tone_shift", 0.0) == shape_b.get("tone_shift", 1.0), "Expected ground tone variation to stay deterministic.")
		assert(shape_a.get("alpha_scale", 0.0) == shape_b.get("alpha_scale", -1.0), "Expected ground alpha variation to stay deterministic.")
		assert(not shape_a.has("node_family"), "Expected ground payload to stay free of node-family semantics.")
		assert(not shape_a.has("adjacent_node_ids"), "Expected ground payload to stay free of route-logic semantics.")
	var bed_shape: Dictionary = ground_shapes_a[0]
	assert(String(bed_shape.get("family", "")) == "bed", "Expected the ground payload to begin with the main board-surface bed shape.")
	assert(
		Vector2(bed_shape.get("half_size", Vector2.ZERO)).x > 120.0 and Vector2(bed_shape.get("half_size", Vector2.ZERO)).y > 80.0,
		"Expected the primary ground bed to define a meaningful board-interior surface area instead of a tiny decal."
	)


func test_map_board_composer_emits_deterministic_filler_shapes() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(41)
	_advance_visible_branch(run_state, 3)
	var composition_a: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var composition_b: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var filler_shapes_a: Array = composition_a.get("filler_shapes", [])
	var filler_shapes_b: Array = composition_b.get("filler_shapes", [])
	assert(filler_shapes_a.size() == filler_shapes_b.size(), "Expected repeated compose calls to emit the same number of filler shapes.")
	assert(not filler_shapes_a.is_empty(), "Expected composed boards to emit a sparse deterministic filler/landmark payload.")
	assert(
		filler_shapes_a.size() <= MapBoardFillerBuilderScript.max_fillers_for_profile(String(composition_a.get("template_profile", "corridor"))),
		"Expected filler payload to stay within the auditable sparse-density cap for the active board profile."
	)
	for index in range(filler_shapes_a.size()):
		var shape_a: Dictionary = filler_shapes_a[index]
		var shape_b: Dictionary = filler_shapes_b[index]
		assert(shape_a.get("family", "") == shape_b.get("family", ""), "Expected filler shape family ordering to stay deterministic.")
		assert(shape_a.get("center", Vector2.ZERO) == shape_b.get("center", Vector2.ZERO), "Expected filler shape centers to stay deterministic.")
		assert(shape_a.get("half_size", Vector2.ZERO) == shape_b.get("half_size", Vector2.ZERO), "Expected filler shape sizes to stay deterministic.")
		assert(shape_a.get("rotation_degrees", 0.0) == shape_b.get("rotation_degrees", -999.0), "Expected filler shape rotation metadata to stay deterministic.")
		assert(shape_a.get("tone_shift", 0.0) == shape_b.get("tone_shift", 1.0), "Expected filler tone variation to stay deterministic.")
		assert(shape_a.get("alpha_scale", 0.0) == shape_b.get("alpha_scale", -1.0), "Expected filler alpha variation to stay deterministic.")
		assert(not shape_a.has("node_family"), "Expected filler payload to stay free of node-family semantics.")
		assert(not shape_a.has("adjacent_node_ids"), "Expected filler payload to stay free of route-logic semantics.")
		var half_size: Vector2 = Vector2(shape_a.get("half_size", Vector2.ZERO))
		var filler_center: Vector2 = Vector2(shape_a.get("center", Vector2.ZERO))
		var nearest_node_clearance: float = _nearest_filler_node_clearance(filler_center, half_size, composition_a)
		assert(
			nearest_node_clearance >= 0.0,
			"Expected filler shapes to respect the explicit node-exclusion contract."
		)
		var nearest_route_clearance: float = _nearest_filler_route_clearance(filler_center, half_size, composition_a)
		assert(
			nearest_route_clearance >= 0.0,
			"Expected filler shapes to stay outside the explicit route-exclusion contract."
		)


func test_map_board_composer_keeps_layout_backdrop_stable_across_progression() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(41)
	var board_size := Vector2(920, 1180)
	var opening_composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
	_advance_visible_branch(run_state, 2)
	var progressed_composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
	assert(
		int(opening_composition.get("seed", 0)) == int(progressed_composition.get("seed", -1)),
		"Expected board composition seed to stay stable across node-state progression for the same realized stage graph."
	)
	assert(
		opening_composition.get("world_positions", {}) == progressed_composition.get("world_positions", {}),
		"Expected board world positions to stay fixed while the player progresses through the realized stage graph."
	)
	assert(
		opening_composition.get("forest_shapes", []) == progressed_composition.get("forest_shapes", []),
		"Expected background canopy/decor composition to stay fixed while the player moves through the same stage."
	)
	assert(
		opening_composition.get("ground_shapes", []) == progressed_composition.get("ground_shapes", []),
		"Expected board ground composition to stay fixed while progression only changes visibility inside the same realized stage."
	)
	assert(
		opening_composition.get("filler_shapes", []) == progressed_composition.get("filler_shapes", []),
		"Expected sparse filler composition to stay fixed while progression only changes visibility inside the same realized stage."
	)


func test_map_board_composer_keeps_full_edge_layout_stable_across_progression() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(41)
	var board_size := Vector2(920, 1180)
	var opening_composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
	_advance_visible_branch(run_state, 2)
	var progressed_composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
	assert(
		opening_composition.get("layout_edges", []) == progressed_composition.get("layout_edges", []),
		"Expected full edge layout geometry to stay fixed while progression only widens visibility."
	)
	for edge_variant in progressed_composition.get("visible_edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		var layout_edge: Dictionary = _find_layout_edge_by_node_ids(
			progressed_composition,
			int(edge_entry.get("from_node_id", -1)),
			int(edge_entry.get("to_node_id", -1))
		)
		assert(not layout_edge.is_empty(), "Expected every visible edge to come from the frozen full edge layout set.")
		assert(
			layout_edge.get("points", PackedVector2Array()) == edge_entry.get("points", PackedVector2Array()),
			"Expected visible edge rendering to filter the frozen layout instead of mutating path geometry during reveal."
		)


func test_map_board_composer_does_not_scale_current_nodes() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var board_size := Vector2(920, 1180)
	var combat_open_radius: float = float(composer.call("build_clearing_radius", "combat", "open", board_size))
	var combat_current_radius: float = float(composer.call("build_clearing_radius", "combat", "current", board_size))
	assert(
		is_equal_approx(combat_open_radius, combat_current_radius),
		"Expected current-node highlight to stay color-only instead of enlarging the active node clearing."
	)
	var reward_open_radius: float = float(composer.call("build_clearing_radius", "reward", "open", board_size))
	var reward_current_radius: float = float(composer.call("build_clearing_radius", "reward", "current", board_size))
	assert(
		is_equal_approx(reward_open_radius, reward_current_radius),
		"Expected presentation-only current-node emphasis to keep reward clearings at the same size."
	)


func test_map_board_composer_keeps_visible_edges_readable_without_crossings() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 6)
		var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
		assert(
			_count_visible_edge_crossings(composition) == 0,
			"Expected composed visible road geometry to stay readable without crossing other visible roads."
		)


func test_map_board_composer_keeps_visible_edges_clear_of_other_node_clearings() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 6)
		var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
		var visible_nodes: Array = composition.get("visible_nodes", [])
		for edge_variant in composition.get("visible_edges", []):
			if typeof(edge_variant) != TYPE_DICTIONARY:
				continue
			var edge_entry: Dictionary = edge_variant
			var points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
			var from_node_id: int = int(edge_entry.get("from_node_id", -1))
			var to_node_id: int = int(edge_entry.get("to_node_id", -1))
			for node_variant in visible_nodes:
				if typeof(node_variant) != TYPE_DICTIONARY:
					continue
				var node_entry: Dictionary = node_variant
				var node_id: int = int(node_entry.get("node_id", -1))
				if node_id == from_node_id or node_id == to_node_id:
					continue
				var node_center: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
				var clearance_floor: float = float(node_entry.get("clearing_radius", 0.0)) + 10.0
				assert(
					_polyline_distance_to_point(points, node_center) >= clearance_floor,
					"Expected visible roads to stay out of other node clearings. Seed=%d edge=%s blocking_node=%d." % [
						seed,
						JSON.stringify([from_node_id, to_node_id]),
						node_id,
					]
				)


func test_map_board_composer_keeps_visible_edges_inside_board_frame() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var board_size := Vector2(920, 1180)
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 6)
		var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
		for edge_variant in composition.get("visible_edges", []):
			if typeof(edge_variant) != TYPE_DICTIONARY:
				continue
			var edge_entry: Dictionary = edge_variant
			var points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
			for point in points:
				assert(
					point.x >= -12.0 and point.x <= board_size.x + 12.0 and point.y >= -12.0 and point.y <= board_size.y + 12.0,
					"Expected composed road fallback points to stay inside the compact board frame instead of jumping to far offscreen lanes. Seed=%d edge=%s point=%s." % [
						seed,
						JSON.stringify([int(edge_entry.get("from_node_id", -1)), int(edge_entry.get("to_node_id", -1))]),
						str(point),
					]
				)


func test_map_board_composer_exposes_public_clearing_radius_helper() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var board_size := Vector2(920.0, 1180.0)
	var boss_open_radius: float = composer.call("build_clearing_radius", "boss", "open", board_size)
	var combat_open_radius: float = composer.call("build_clearing_radius", "combat", "open", board_size)
	var reward_open_radius: float = composer.call("build_clearing_radius", "reward", "open", board_size)
	var reward_resolved_radius: float = composer.call("build_clearing_radius", "reward", "resolved", board_size)
	assert(
		boss_open_radius > combat_open_radius,
		"Expected the public clearing-radius helper to preserve the larger boss shell footprint."
	)
	assert(
		reward_resolved_radius < reward_open_radius,
		"Expected the public clearing-radius helper to preserve resolved-node compaction."
	)


func test_map_board_composer_keeps_discovered_history_edges_visible() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 5)
		var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
		var current_node_id: int = int(composition.get("current_node_id", -1))
		var adjacent_node_ids: PackedInt32Array = PackedInt32Array()
		for node_variant in composition.get("visible_nodes", []):
			if typeof(node_variant) != TYPE_DICTIONARY:
				continue
			var node_entry: Dictionary = node_variant
			if bool(node_entry.get("is_adjacent", false)):
				adjacent_node_ids.append(int(node_entry.get("node_id", -1)))
		assert(not adjacent_node_ids.is_empty(), "Expected a progressed map pocket to keep adjacent actionable routes.")
		var history_edge_count: int = 0
		var local_edge_count: int = 0
		var visible_node_ids: PackedInt32Array = _visible_node_ids(composition)
		var non_local_visible_node_count: int = 0
		for visible_node_id in visible_node_ids:
			if visible_node_id == current_node_id or adjacent_node_ids.has(visible_node_id):
				continue
			non_local_visible_node_count += 1
		for edge_variant in composition.get("visible_edges", []):
			if typeof(edge_variant) != TYPE_DICTIONARY:
				continue
			var edge_entry: Dictionary = edge_variant
			var from_node_id: int = int(edge_entry.get("from_node_id", -1))
			var to_node_id: int = int(edge_entry.get("to_node_id", -1))
			assert(
				visible_node_ids.has(from_node_id) and visible_node_ids.has(to_node_id),
				"Expected composed visible roads to stay scoped to already-visible nodes."
			)
			if bool(edge_entry.get("is_history", false)):
				history_edge_count += 1
				assert(
					not (
						(from_node_id == current_node_id or adjacent_node_ids.has(from_node_id))
						and (to_node_id == current_node_id or adjacent_node_ids.has(to_node_id))
					),
					"Expected history roads to cover discovered traversal memory outside the immediate actionable pocket."
				)
				assert(
					String(edge_entry.get("state_semantic", "")) in ["open", "resolved", "locked"],
					"Expected non-local discovered roads to keep their underlying traversal semantic instead of disappearing."
				)
			else:
				local_edge_count += 1
				assert(
					(from_node_id == current_node_id or adjacent_node_ids.has(from_node_id))
					and (to_node_id == current_node_id or adjacent_node_ids.has(to_node_id)),
					"Expected actionable roads to stay anchored to the current local movement pocket."
				)
		assert(
			history_edge_count > 0 or non_local_visible_node_count == 0,
			"Expected progressed map views to preserve at least one discovered history road. Seed=%d current=%d adjacent=%s non_local_visible=%d local_edges=%d history_edges=%d." % [
				seed,
				current_node_id,
				JSON.stringify(adjacent_node_ids),
				non_local_visible_node_count,
				local_edge_count,
				history_edge_count,
			]
		)
		assert(local_edge_count > 0, "Expected progressed map views to keep immediate actionable roads visible.")


func test_map_board_composer_keeps_one_visible_outer_reconnect_in_late_route_history() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 5)
		var graph_snapshot: Array[Dictionary] = run_state.map_runtime_state.build_realized_graph_snapshots()
		var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
		var reconnect_edge: Dictionary = _find_visible_same_depth_edge(composition, graph_snapshot)
		assert(
			not reconnect_edge.is_empty(),
			"Expected each seeded map to keep at least one visible same-depth outer reconnect once late-route history is in view. Seed=%d." % seed
		)
		assert(
			String(reconnect_edge.get("path_family", "")) == "outward_reconnecting_arc",
			"Expected visible same-depth reconnects to use the dedicated outward reconnect family instead of blending back into the ordinary corridor curves. Seed=%d." % seed
		)


func test_map_board_composer_prefers_non_reconnect_history_when_crossing_reconnect_conflicts() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var local_focus_edges: Array[Dictionary] = []
	var history_edges: Array[Dictionary] = [
		{
			"from_node_id": 10,
			"to_node_id": 11,
			"is_reconnect_edge": true,
			"depth_delta": 0,
			"points": PackedVector2Array([Vector2(160.0, 160.0), Vector2(420.0, 420.0)]),
		},
		{
			"from_node_id": 20,
			"to_node_id": 21,
			"is_reconnect_edge": false,
			"depth_delta": 1,
			"points": PackedVector2Array([Vector2(160.0, 420.0), Vector2(420.0, 160.0)]),
		},
	]
	var filtered_history_edges: Array[Dictionary] = composer.call(
		"_filter_non_crossing_history_edges",
		local_focus_edges,
		history_edges
	)
	assert(
		filtered_history_edges.size() == 1,
		"Expected the crossing-history filter to keep only one of two crossing history edges in this synthetic priority case."
	)
	assert(
		not bool((filtered_history_edges[0] as Dictionary).get("is_reconnect_edge", true)),
		"Expected non-reconnect history roads to win over crossing reconnect history edges so ordinary discovered routes do not disappear behind a decorative reconnect."
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


func _nearest_filler_node_clearance(center: Vector2, half_size: Vector2, composition: Dictionary) -> float:
	var nearest_clearance: float = INF
	for node_variant in composition.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var node_center: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
		var required_clearance: float = MapBoardFillerBuilderScript.node_exclusion_radius(
			float(node_entry.get("clearing_radius", 0.0)),
			half_size
		)
		nearest_clearance = min(nearest_clearance, center.distance_to(node_center) - required_clearance)
	return nearest_clearance


func _nearest_filler_route_clearance(center: Vector2, half_size: Vector2, composition: Dictionary) -> float:
	var nearest_clearance: float = INF
	for edge_variant in composition.get("layout_edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		var points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		var required_clearance: float = MapBoardFillerBuilderScript.route_exclusion_radius(half_size)
		nearest_clearance = min(nearest_clearance, _polyline_distance_to_point(points, center) - required_clearance)
	return nearest_clearance


func _visible_node_bounds(composition: Dictionary) -> Rect2:
	var has_bounds: bool = false
	var min_point: Vector2 = Vector2.ZERO
	var max_point: Vector2 = Vector2.ZERO
	for node_variant in composition.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var position: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
		if position == Vector2.ZERO:
			continue
		if not has_bounds:
			has_bounds = true
			min_point = position
			max_point = position
			continue
		min_point = Vector2(minf(min_point.x, position.x), minf(min_point.y, position.y))
		max_point = Vector2(maxf(max_point.x, position.x), maxf(max_point.y, position.y))
	if not has_bounds:
		return Rect2()
	return Rect2(min_point, max_point - min_point)


func _polyline_distance_to_point(points: PackedVector2Array, point: Vector2) -> float:
	if points.is_empty():
		return INF
	if points.size() == 1:
		return points[0].distance_to(point)
	var closest_distance: float = INF
	for point_index in range(points.size() - 1):
		closest_distance = min(
			closest_distance,
			_distance_point_to_segment(point, points[point_index], points[point_index + 1])
		)
	return closest_distance


func _distance_point_to_segment(point: Vector2, start_point: Vector2, end_point: Vector2) -> float:
	var segment: Vector2 = end_point - start_point
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= 0.001:
		return point.distance_to(start_point)
	var t: float = clampf((point - start_point).dot(segment) / segment_length_squared, 0.0, 1.0)
	var projection: Vector2 = start_point + segment * t
	return point.distance_to(projection)


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


func _find_visible_same_depth_edge(composition: Dictionary, graph_snapshot: Array[Dictionary]) -> Dictionary:
	var depth_by_node_id: Dictionary = _build_depth_by_node_id_from_snapshot(graph_snapshot)
	for edge_variant in composition.get("visible_edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		var from_node_id: int = int(edge_entry.get("from_node_id", -1))
		var to_node_id: int = int(edge_entry.get("to_node_id", -1))
		if int(depth_by_node_id.get(from_node_id, -1)) == int(depth_by_node_id.get(to_node_id, -2)):
			return edge_entry
	return {}


func _find_visible_node_by_family(composition: Dictionary, node_family: String, require_adjacent: bool) -> Dictionary:
	for node_variant in composition.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		if String(node_entry.get("node_family", "")) != node_family:
			continue
		if bool(node_entry.get("is_adjacent", false)) != require_adjacent:
			continue
		return node_entry
	return {}


func _find_visible_node_by_id(composition: Dictionary, node_id: int) -> Dictionary:
	for node_variant in composition.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		if int(node_entry.get("node_id", -1)) == node_id:
			return node_entry
	return {}


func _find_layout_edge_by_node_ids(composition: Dictionary, from_node_id: int, to_node_id: int) -> Dictionary:
	for edge_variant in composition.get("layout_edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		var left_id: int = int(edge_entry.get("from_node_id", -1))
		var right_id: int = int(edge_entry.get("to_node_id", -1))
		if (left_id == from_node_id and right_id == to_node_id) or (left_id == to_node_id and right_id == from_node_id):
			return edge_entry
	return {}


func _find_forest_shape_by_family(composition: Dictionary, shape_family: String) -> Dictionary:
	for shape_variant in composition.get("forest_shapes", []):
		if typeof(shape_variant) != TYPE_DICTIONARY:
			continue
		var shape_entry: Dictionary = shape_variant
		if String(shape_entry.get("family", "")) == shape_family:
			return shape_entry
	return {}


func _count_visible_edge_crossings(composition: Dictionary) -> int:
	var visible_edges: Array = composition.get("visible_edges", [])
	var crossing_count: int = 0
	for left_index in range(visible_edges.size()):
		for right_index in range(left_index + 1, visible_edges.size()):
			var left_edge: Dictionary = visible_edges[left_index]
			var right_edge: Dictionary = visible_edges[right_index]
			if _visible_edges_share_node(left_edge, right_edge):
				continue
			if _polylines_intersect(
				left_edge.get("points", PackedVector2Array()),
				right_edge.get("points", PackedVector2Array())
			):
				crossing_count += 1
	return crossing_count


func _visible_edges_share_node(left_edge: Dictionary, right_edge: Dictionary) -> bool:
	var left_ids: Array[int] = [int(left_edge.get("from_node_id", -1)), int(left_edge.get("to_node_id", -1))]
	var right_ids: Array[int] = [int(right_edge.get("from_node_id", -1)), int(right_edge.get("to_node_id", -1))]
	for left_id in left_ids:
		if left_id in right_ids:
			return true
	return false


func _polylines_intersect(left_points: PackedVector2Array, right_points: PackedVector2Array) -> bool:
	if left_points.size() < 2 or right_points.size() < 2:
		return false
	for left_segment_index in range(left_points.size() - 1):
		for right_segment_index in range(right_points.size() - 1):
			if _segments_intersect(
				left_points[left_segment_index],
				left_points[left_segment_index + 1],
				right_points[right_segment_index],
				right_points[right_segment_index + 1]
			):
				return true
	return false


func _segments_intersect(a0: Vector2, a1: Vector2, b0: Vector2, b1: Vector2) -> bool:
	var a0_to_b0: Vector2 = b0 - a0
	var a0_to_b1: Vector2 = b1 - a0
	var a0_to_a1: Vector2 = a1 - a0
	var b0_to_a0: Vector2 = a0 - b0
	var b0_to_a1: Vector2 = a1 - b0
	var b0_to_b1: Vector2 = b1 - b0
	var d1: float = a0_to_a1.cross(a0_to_b0)
	var d2: float = a0_to_a1.cross(a0_to_b1)
	var d3: float = b0_to_b1.cross(b0_to_a0)
	var d4: float = b0_to_b1.cross(b0_to_a1)
	return _segment_straddles(d1, d2) and _segment_straddles(d3, d4)


func _segment_straddles(left: float, right: float) -> bool:
	return (left > 0.0 and right < 0.0) or (left < 0.0 and right > 0.0)


func _build_depth_by_node_id_from_snapshot(graph_snapshot: Array[Dictionary]) -> Dictionary:
	var graph_by_id: Dictionary = {}
	for node_entry in graph_snapshot:
		graph_by_id[int(node_entry.get("node_id", -1))] = node_entry
	var start_node_id: int = 0
	for node_entry in graph_snapshot:
		if String(node_entry.get("node_family", "")) == "start":
			start_node_id = int(node_entry.get("node_id", 0))
			break
	var depth_by_node_id: Dictionary = {start_node_id: 0}
	var open_node_ids: Array[int] = [start_node_id]
	while not open_node_ids.is_empty():
		var node_id: int = open_node_ids.pop_front()
		var node_depth: int = int(depth_by_node_id.get(node_id, 0))
		var adjacent_node_ids: PackedInt32Array = _adjacent_ids_from_snapshot_entry(graph_by_id.get(node_id, {}))
		for adjacent_node_id in adjacent_node_ids:
			if depth_by_node_id.has(adjacent_node_id):
				continue
			depth_by_node_id[adjacent_node_id] = node_depth + 1
			open_node_ids.append(adjacent_node_id)
	return depth_by_node_id


func _adjacent_ids_from_snapshot_entry(node_entry: Dictionary) -> PackedInt32Array:
	var adjacent_variant: Variant = node_entry.get("adjacent_node_ids", PackedInt32Array())
	if typeof(adjacent_variant) == TYPE_PACKED_INT32_ARRAY:
		return adjacent_variant
	var adjacent_ids := PackedInt32Array()
	if typeof(adjacent_variant) == TYPE_ARRAY:
		for adjacent_node_id in adjacent_variant:
			adjacent_ids.append(int(adjacent_node_id))
	return adjacent_ids
