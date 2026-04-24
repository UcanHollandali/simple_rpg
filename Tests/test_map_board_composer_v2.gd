# Layer: Tests
extends SceneTree
class_name TestMapBoardComposerV2

const MapBoardComposerV2Script = preload("res://Game/UI/map_board_composer_v2.gd")
const MapBoardBackdropBuilderScript = preload("res://Game/UI/map_board_backdrop_builder.gd")
const MapBoardEdgeRoutingScript = preload("res://Game/UI/map_board_edge_routing.gd")
const MapBoardFillerBuilderScript = preload("res://Game/UI/map_board_filler_builder.gd")
const MapBoardGeometryScript = preload("res://Game/UI/map_board_geometry.gd")
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
	test_map_board_composer_keeps_opening_anchor_center_local_on_fixed_board()
	test_map_board_composer_base_center_factor_tracks_center_anchor_zone()
	test_map_board_composer_consumes_runtime_layout_snapshots_for_slot_anchors()
	test_map_board_composer_emits_core_render_model_payload()
	test_map_board_composer_emits_masks_slots_render_model_payload()
	test_map_board_composer_rebuilds_render_model_after_visible_edge_updates()
	test_map_board_composer_spreads_opening_shell_across_a_readable_upper_fan()
	test_map_board_composer_materially_uses_the_lower_band_in_opening_shell()
	test_map_board_composer_uses_the_mid_and_upper_portrait_band_in_late_routes()
	test_map_board_composer_materially_uses_the_lower_portrait_band_in_late_routes()
	test_map_board_composer_keeps_late_routes_off_the_top_edge_knot()
	test_map_board_composer_separates_late_route_adjacent_choices_into_distinct_lanes()
	test_map_board_composer_spreads_late_routes_across_distinct_cardinal_sectors()
	test_map_board_composer_surfaces_known_icons_for_seen_non_adjacent_nodes()
	test_map_board_composer_surfaces_known_icons_for_current_and_adjacent_nodes()
	test_map_board_composer_surfaces_landmark_footprints_for_visible_nodes()
	test_map_board_composer_builds_family_distinct_landmark_profiles()
	test_map_board_composer_surfaces_side_quest_highlights()
	test_map_board_composer_exposes_fixed_board_safe_bounds_contract()
	test_map_board_composer_keeps_visible_nodes_portrait_safe_without_overlap()
	test_map_board_composer_emits_deterministic_ground_shapes()
	test_map_board_composer_emits_deterministic_filler_shapes()
	test_map_board_composer_breaks_ground_into_corridor_and_pocket_masks()
	test_map_board_composer_emits_deterministic_forest_shapes()
	test_map_board_composer_derives_terrain_masks_from_render_model_surfaces()
	test_map_board_composer_centers_ground_bed_on_layout_action_bounds()
	test_map_board_composer_tames_corridor_ground_bed_footprint()
	test_map_board_composer_keeps_forest_shapes_clear_of_route_action_pocket()
	test_map_board_composer_keeps_layout_backdrop_stable_across_progression()
	test_map_board_composer_keeps_full_edge_layout_stable_across_progression()
	test_map_board_composer_does_not_scale_current_nodes()
	test_map_board_composer_keeps_visible_edges_readable_without_crossings()
	test_map_board_composer_routes_visible_edges_from_clearing_throats()
	test_map_board_composer_separates_opening_choices_into_distinct_corridor_throats()
	test_map_board_composer_keeps_visible_edges_clear_of_other_node_clearings()
	test_map_board_composer_keeps_visible_edges_inside_board_frame()
	test_map_board_composer_exposes_public_clearing_radius_helper()
	test_map_board_composer_penalizes_edge_hugging_outer_reconnect_fallbacks()
	test_map_board_composer_keeps_outer_reconnect_fallbacks_inside_the_inner_frame()
	test_map_board_composer_keeps_discovered_history_edges_visible()
	test_map_board_composer_exposes_sector_corridor_metadata_for_visible_edges()
	test_map_board_composer_exposes_route_surface_semantics_for_visible_edges()
	test_map_board_composer_rejects_near_parallel_history_braids()
	test_map_board_composer_keeps_one_visible_outer_reconnect_in_late_route_history()
	test_map_board_composer_limits_same_depth_reconnect_detours_on_fixed_board()
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
	for required_family in ["short_straight", "wider_curve", "outward_reconnecting_arc"]:
		assert(
			observed_family_set.has(required_family),
			"Expected curated opening and late-route board views to keep the active Prompt 48 compatibility family set visible instead of collapsing below the short/wide/reconnect baseline."
		)
	assert(
		observed_family_set.size() >= 3,
		"Expected curated opening and late-route board views to preserve multiple deterministic path families even when the Prompt 48 runtime backbone no longer surfaces every supported family inside the same visible-history window."
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


func test_map_board_composer_keeps_opening_anchor_center_local_on_fixed_board() -> void:
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
		start_position.x >= board_size.x * 0.46 and start_position.x <= board_size.x * 0.54,
		"Expected the fixed-board opening anchor to stay horizontally center-local instead of drifting into a side pocket."
	)
	assert(
		start_position.y >= board_size.y * 0.54 and start_position.y <= board_size.y * 0.64,
		"Expected the fixed-board opening anchor to stay center-local instead of sliding too low on the portrait board."
	)


func test_map_board_composer_base_center_factor_tracks_center_anchor_zone() -> void:
	var board_size := Vector2(920, 1180)
	var base_origin: Vector2 = board_size * MapBoardComposerV2Script.BASE_CENTER_FACTOR
	var center_anchor_position: Vector2 = MapBoardComposerV2Script.build_center_anchor_position(board_size)
	assert(
		absf(base_origin.x - center_anchor_position.x) <= 1.0,
		"Expected BASE_CENTER_FACTOR to stay horizontally aligned with the center-local slot anchor zone."
	)
	assert(
		base_origin.y >= center_anchor_position.y and base_origin.y <= board_size.y * 0.65,
		"Expected BASE_CENTER_FACTOR to remain a center-local decor/layout origin while the explicit slot anchor owns the start position."
	)


func test_map_board_composer_consumes_runtime_layout_snapshots_for_slot_anchors() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(29)
	var board_size := Vector2(920, 1180)
	var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
	var runtime_layout_snapshots: Array[Dictionary] = run_state.map_runtime_state.build_layout_graph_snapshots()
	var runtime_sector_by_node_id: Dictionary = {}
	var runtime_route_role_by_node_id: Dictionary = {}
	var expected_orientation_profile_id: String = ""
	var expected_topology_blueprint_id: String = ""
	for snapshot in runtime_layout_snapshots:
		var node_id: int = int(snapshot.get("node_id", -1))
		runtime_sector_by_node_id[node_id] = String(snapshot.get("sector_id", ""))
		runtime_route_role_by_node_id[node_id] = String(snapshot.get("route_role", ""))
		if expected_orientation_profile_id.is_empty():
			expected_orientation_profile_id = String(snapshot.get("orientation_profile_id", ""))
		if expected_topology_blueprint_id.is_empty():
			expected_topology_blueprint_id = String(snapshot.get("topology_blueprint_id", ""))

	assert(String(composition.get("placement_mode", "")) == "runtime_slot_anchor", "Expected composer placement to consume runtime layout metadata through the slot-anchor path.")
	assert(String(composition.get("post_anchor_relief_mode", "")) == "depth_silhouette", "Expected legacy depth relief to be explicit metadata instead of a silent second placement default.")
	assert(String(composition.get("orientation_profile_id", "")) == expected_orientation_profile_id, "Expected composer layout metadata to preserve the runtime orientation profile id.")
	assert(String(composition.get("topology_blueprint_id", "")) == expected_topology_blueprint_id, "Expected composer layout metadata to preserve the runtime topology blueprint id.")
	assert(composition.get("layout_sector_by_node_id", {}) == runtime_sector_by_node_id, "Expected composer layout sector metadata to mirror MapRuntimeState read-only layout snapshots.")
	assert(composition.get("layout_route_role_by_node_id", {}) == runtime_route_role_by_node_id, "Expected composer route-role metadata to mirror MapRuntimeState read-only layout snapshots.")

	var world_positions: Dictionary = composition.get("world_positions", {})
	var slot_anchor_sector_by_node_id: Dictionary = composition.get("slot_anchor_sector_by_node_id", {})
	var start_position: Vector2 = Vector2(world_positions.get(0, Vector2.ZERO))
	assert(start_position.distance_to(MapBoardComposerV2Script.build_center_anchor_position(board_size)) <= 1.0, "Expected the start node to sit on the explicit center-local slot anchor.")
	assert(String(slot_anchor_sector_by_node_id.get(0, "")) == "center_anchor", "Expected the start node slot sector to stay center-local.")

	var opening_slot_sectors: Dictionary = {}
	for adjacent_node_id in run_state.map_runtime_state.get_adjacent_node_ids(0):
		opening_slot_sectors[String(slot_anchor_sector_by_node_id.get(int(adjacent_node_id), ""))] = true
	assert(opening_slot_sectors.size() >= 3, "Expected first choices to claim multiple sector-local slot anchors instead of one centroid stack.")

	var save_data: Dictionary = run_state.to_save_dict()
	for forbidden_key in ["layout_sector_by_node_id", "layout_route_role_by_node_id", "slot_anchor_sector_by_node_id", "slot_anchor_index_by_node_id", "orientation_profile_id", "topology_blueprint_id", "placement_mode", "post_anchor_relief_mode", "render_model"]:
		assert(not save_data.has(forbidden_key), "Expected UI placement metadata key %s to stay out of save data." % forbidden_key)


func test_map_board_composer_emits_core_render_model_payload() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(29)
	_advance_visible_branch(run_state, 5)
	var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var render_model: Dictionary = composition.get("render_model", {})
	assert(not render_model.is_empty(), "Expected composer output to include the first nested UI-only render_model payload.")
	assert(int(render_model.get("schema_version", 0)) == 1, "Expected render_model.schema_version to lock the first core payload shape.")
	assert(String(render_model.get("orientation_profile_id", "")) == String(composition.get("orientation_profile_id", "")), "Expected render_model to preserve the runtime-derived center-outward orientation profile metadata.")
	assert(String(render_model.get("center_outward_emphasis_id", "")) == String(composition.get("orientation_profile_id", "")), "Expected render_model to carry equivalent center-outward emphasis metadata for later surface rendering.")
	assert(String(render_model.get("topology_blueprint_id", "")) == String(composition.get("topology_blueprint_id", "")), "Expected render_model to keep topology blueprint metadata as presentation readback only.")
	assert(render_model.has("canopy_masks"), "Expected Prompt 08 render_model to carry canopy mask metadata without switching the canvas lane.")
	assert(render_model.has("landmark_slots"), "Expected Prompt 08 render_model to carry landmark socket metadata without adding assets.")
	assert(render_model.has("decor_slots"), "Expected Prompt 08 render_model to carry decor socket metadata without adding assets.")

	var legacy_field_status: Dictionary = render_model.get("legacy_field_status", {})
	assert(String(legacy_field_status.get("layout_edges", "")) == "fallback", "Expected layout_edges to be explicitly labeled as a fallback lane before render-model canvas adoption.")
	assert(String(legacy_field_status.get("visible_edges", "")) == "fallback", "Expected visible_edges to be labeled fallback once render_model.path_surfaces owns the default canvas road lane.")
	assert(String(legacy_field_status.get("ground_shapes", "")) == "wrapper", "Expected ground_shapes to be labeled as a wrapper terrain bed while render_model owns road/clearing surfaces.")
	assert(String(legacy_field_status.get("filler_shapes", "")) == "wrapper", "Expected filler_shapes to be labeled as wrapper decor metadata after Prompt 08 slots land.")
	assert(String(legacy_field_status.get("forest_shapes", "")) == "wrapper", "Expected forest_shapes to be labeled as wrapper canopy/decor metadata after Prompt 08 masks/slots land.")

	var path_surfaces: Array = render_model.get("path_surfaces", [])
	var junctions: Array = render_model.get("junctions", [])
	var clearing_surfaces: Array = render_model.get("clearing_surfaces", [])
	assert(path_surfaces.size() == (composition.get("visible_edges", []) as Array).size(), "Expected render_model.path_surfaces to wrap every visible road without switching the canvas default lane.")
	assert(clearing_surfaces.size() == (composition.get("visible_nodes", []) as Array).size(), "Expected render_model.clearing_surfaces to wrap every visible clearing.")
	assert(not junctions.is_empty(), "Expected render_model.junctions to expose local choice and branch-throat blend points.")

	var allowed_roles := {
		"primary_actionable_corridor": true,
		"branch_actionable_corridor": true,
		"branch_history_corridor": true,
		"history_corridor": true,
		"reconnect_corridor": true,
	}
	var observed_primary_path: bool = false
	for surface_variant in path_surfaces:
		if typeof(surface_variant) != TYPE_DICTIONARY:
			continue
		var surface_entry: Dictionary = surface_variant
		var centerline_points: PackedVector2Array = surface_entry.get("centerline_points", PackedVector2Array())
		var role: String = String(surface_entry.get("role", ""))
		assert(allowed_roles.has(role), "Expected path surfaces to carry first-class corridor roles, not ad hoc route text. Surface=%s." % JSON.stringify(surface_entry))
		assert(centerline_points.size() >= 2, "Expected path surfaces to carry centerline geometry for later surface drawing. Surface=%s." % JSON.stringify(surface_entry))
		assert(float(surface_entry.get("surface_width", 0.0)) > 0.0, "Expected every path surface to expose a positive terrain-surface width.")
		assert(String(surface_entry.get("shape", "")) == "polyline_strip", "Expected Prompt 07 path surfaces to use core polyline-strip metadata instead of masks/slots.")
		assert(not String(surface_entry.get("cardinal_direction", "")).is_empty(), "Expected path surfaces to preserve cardinal route read metadata.")
		assert(not String(surface_entry.get("outward_route_hint", "")).is_empty(), "Expected path surfaces to expose an outward/history/reconnect route hint.")
		assert(not String(surface_entry.get("corridor_throat_id", "")).is_empty(), "Expected path surfaces to preserve corridor throat identity from Prompt 06.")
		assert(Vector2(surface_entry.get("from_endpoint", Vector2.ZERO)) == centerline_points[0], "Expected path surface endpoint metadata to match its centerline start.")
		assert(Vector2(surface_entry.get("to_endpoint", Vector2.ZERO)) == centerline_points[centerline_points.size() - 1], "Expected path surface endpoint metadata to match its centerline end.")
		if role == "primary_actionable_corridor":
			observed_primary_path = true
	assert(observed_primary_path, "Expected render_model.path_surfaces to include the current primary actionable corridor.")

	var current_node_id: int = int(composition.get("current_node_id", -1))
	var observed_current_junction: bool = false
	for junction_variant in junctions:
		if typeof(junction_variant) != TYPE_DICTIONARY:
			continue
		var junction_entry: Dictionary = junction_variant
		assert(not (junction_entry.get("connected_surface_ids", []) as Array).is_empty(), "Expected every render junction to name connected path surfaces.")
		assert(float(junction_entry.get("junction_radius", 0.0)) > 0.0, "Expected every render junction to expose a blend radius.")
		if int(junction_entry.get("node_id", -1)) == current_node_id:
			observed_current_junction = true
			assert(String(junction_entry.get("junction_role", "")) == "local_choice_blend", "Expected the current node junction to blend local choices.")
	assert(observed_current_junction, "Expected render_model.junctions to include the current local-choice junction.")

	for clearing_variant in clearing_surfaces:
		if typeof(clearing_variant) != TYPE_DICTIONARY:
			continue
		var clearing_entry: Dictionary = clearing_variant
		assert(String(clearing_entry.get("shape", "")) == "clearing_disc", "Expected Prompt 07 clearing surfaces to stay core clearing geometry, not Prompt 08 slots.")
		assert(float(clearing_entry.get("radius", 0.0)) > 0.0, "Expected every clearing surface to expose its clearing radius.")
		assert(not (clearing_entry.get("connected_path_surface_ids", []) as Array).is_empty() or bool(clearing_entry.get("is_current", false)), "Expected visible destination clearings to connect to road endpoints where graph visibility exposes them.")


func test_map_board_composer_emits_masks_slots_render_model_payload() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(29)
	_advance_visible_branch(run_state, 5)
	var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var render_model: Dictionary = composition.get("render_model", {})
	var canopy_masks: Array = render_model.get("canopy_masks", [])
	var landmark_slots: Array = render_model.get("landmark_slots", [])
	var decor_slots: Array = render_model.get("decor_slots", [])
	assert(not canopy_masks.is_empty(), "Expected Prompt 08 to expose canopy masks derived from forest canopy shapes.")
	assert(not landmark_slots.is_empty(), "Expected Prompt 08 to expose landmark slots derived from visible landmark footprints.")
	assert(not decor_slots.is_empty(), "Expected Prompt 08 to expose decor slots derived from existing filler/decor shapes.")

	var legacy_field_status: Dictionary = render_model.get("legacy_field_status", {})
	assert(String(legacy_field_status.get("ground_shapes", "")) == "wrapper", "Expected ground_shapes to be labeled as wrapper terrain metadata after the render-model canvas lane lands.")
	assert(String(legacy_field_status.get("filler_shapes", "")) == "wrapper", "Expected filler_shapes to be labeled as wrapper decor metadata after render_model.decor_slots land.")
	assert(String(legacy_field_status.get("forest_shapes", "")) == "wrapper", "Expected forest_shapes to be labeled as wrapper canopy/decor metadata after render_model masks/slots land.")

	var path_surface_ids: Dictionary = {}
	for path_variant in render_model.get("path_surfaces", []):
		if typeof(path_variant) != TYPE_DICTIONARY:
			continue
		var path_entry: Dictionary = path_variant
		path_surface_ids[String(path_entry.get("surface_id", ""))] = true
	var clearing_surface_ids: Dictionary = {}
	for clearing_variant in render_model.get("clearing_surfaces", []):
		if typeof(clearing_variant) != TYPE_DICTIONARY:
			continue
		var clearing_entry: Dictionary = clearing_variant
		clearing_surface_ids[String(clearing_entry.get("surface_id", ""))] = true

	for mask_variant in canopy_masks:
		assert(typeof(mask_variant) == TYPE_DICTIONARY, "Expected canopy masks to be dictionaries.")
		var mask_entry: Dictionary = mask_variant
		assert(String(mask_entry.get("source_legacy_field", "")) == "forest_shapes", "Expected canopy masks to wrap the live forest_shapes lane.")
		assert(String(mask_entry.get("source_family", "")) == "canopy", "Expected canopy masks to expose only canopy-source shapes.")
		assert(String(mask_entry.get("shape", "")) == "circle", "Expected canopy masks to expose a stable shape primitive.")
		assert(float(mask_entry.get("radius", 0.0)) > 0.0, "Expected canopy masks to expose a positive radius.")
		assert(not String(mask_entry.get("mask_role", "")).is_empty(), "Expected canopy masks to expose a framing role.")
		assert(not String(mask_entry.get("cardinal_side", "")).is_empty(), "Expected canopy masks to preserve board-side/cardinal metadata.")
		assert(not String(mask_entry.get("outward_route_hint", "")).is_empty(), "Expected canopy masks to preserve outward-route metadata.")
		assert(not (mask_entry.get("frames_path_surface_ids", []) as Array).is_empty(), "Expected canopy masks to link to nearby path surfaces.")
		assert(not (mask_entry.get("frames_clearing_surface_ids", []) as Array).is_empty(), "Expected canopy masks to link to nearby clearing surfaces.")
		for surface_id_variant in mask_entry.get("frames_path_surface_ids", []):
			assert(path_surface_ids.has(String(surface_id_variant)), "Expected canopy mask path links to name existing path surfaces.")
		for surface_id_variant in mask_entry.get("frames_clearing_surface_ids", []):
			assert(clearing_surface_ids.has(String(surface_id_variant)), "Expected canopy mask clearing links to name existing clearing surfaces.")
		assert(not mask_entry.has("texture_path"), "Expected canopy mask sockets to avoid asset path/provenance claims.")

	var observed_current_landmark: bool = false
	for slot_variant in landmark_slots:
		assert(typeof(slot_variant) == TYPE_DICTIONARY, "Expected landmark slots to be dictionaries.")
		var slot_entry: Dictionary = slot_variant
		assert(int(slot_entry.get("node_id", -1)) >= 0, "Expected landmark slots to stay tied to visible node ids.")
		assert(not String(slot_entry.get("node_family", "")).is_empty(), "Expected landmark slots to expose node-family socket metadata.")
		assert(not String(slot_entry.get("slot_role", "")).is_empty(), "Expected landmark slots to expose role metadata.")
		assert(Vector2(slot_entry.get("anchor_point", Vector2.ZERO)) != Vector2.ZERO, "Expected landmark slots to expose an asset-ready anchor point.")
		assert(not String(slot_entry.get("landmark_shape", "")).is_empty(), "Expected landmark slots to expose landmark shape metadata.")
		assert(float(slot_entry.get("scale", 0.0)) > 0.0, "Expected landmark slots to expose a positive scale.")
		assert(not String(slot_entry.get("cardinal_direction", "")).is_empty(), "Expected landmark slots to expose cardinal route relationship.")
		assert(not String(slot_entry.get("outward_route_hint", "")).is_empty(), "Expected landmark slots to expose outward route relationship.")
		for surface_id_variant in slot_entry.get("connected_path_surface_ids", []):
			assert(path_surface_ids.has(String(surface_id_variant)), "Expected landmark slots to link only existing path surfaces.")
		assert(not slot_entry.has("texture_path"), "Expected landmark slots to avoid asset path/provenance claims.")
		if String(slot_entry.get("slot_role", "")) == "current_landmark":
			observed_current_landmark = true
	assert(observed_current_landmark, "Expected landmark slots to include the current clearing socket.")

	for slot_variant in decor_slots:
		assert(typeof(slot_variant) == TYPE_DICTIONARY, "Expected decor slots to be dictionaries.")
		var slot_entry: Dictionary = slot_variant
		assert(String(slot_entry.get("source_legacy_field", "")) in ["filler_shapes", "forest_shapes"], "Expected decor slots to wrap only current live decor lanes.")
		assert(not String(slot_entry.get("decor_family", "")).is_empty(), "Expected decor slots to expose a decor family key.")
		assert(Vector2(slot_entry.get("anchor_point", Vector2.ZERO)) != Vector2.ZERO, "Expected decor slots to expose an asset-ready anchor point.")
		assert(float(slot_entry.get("scale", 0.0)) > 0.0, "Expected decor slots to expose a positive scale.")
		assert(String(slot_entry.get("relation_type", "")) in ["route_side", "clearing_edge"], "Expected decor slots to expose route/clearing relationship metadata.")
		assert(not String(slot_entry.get("cardinal_side", "")).is_empty(), "Expected decor slots to preserve board-side/cardinal metadata.")
		assert(not String(slot_entry.get("outward_route_hint", "")).is_empty(), "Expected decor slots to preserve outward-route metadata.")
		var related_path_surface_id: String = String(slot_entry.get("related_path_surface_id", ""))
		if not related_path_surface_id.is_empty():
			assert(path_surface_ids.has(related_path_surface_id), "Expected decor slots to link only existing path surfaces.")
		var related_clearing_surface_id: String = String(slot_entry.get("related_clearing_surface_id", ""))
		if not related_clearing_surface_id.is_empty():
			assert(clearing_surface_ids.has(related_clearing_surface_id), "Expected decor slots to link only existing clearing surfaces.")
		assert(not slot_entry.has("texture_path"), "Expected decor slots to avoid asset path/provenance claims.")


func test_map_board_composer_rebuilds_render_model_after_visible_edge_updates() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(29)
	_advance_visible_branch(run_state, 5)
	var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var visible_edges: Array = composition.get("visible_edges", [])
	assert(visible_edges.size() >= 2, "Expected progressed composition to expose multiple visible edges before render-model rebuild coverage.")
	composition["visible_edges"] = [(visible_edges[0] as Dictionary).duplicate(true)]
	var refreshed_composition: Dictionary = composer.call("rebuild_render_model_for_composition", composition)
	var refreshed_render_model: Dictionary = refreshed_composition.get("render_model", {})
	assert(
		(refreshed_render_model.get("path_surfaces", []) as Array).size() == 1,
		"Expected render_model rebuild to reflect the current visible_edges lane after continuity fallback changes."
	)
	assert(
		(refreshed_render_model.get("clearing_surfaces", []) as Array).size() == (composition.get("visible_nodes", []) as Array).size(),
		"Expected render_model rebuild to preserve clearing surface coverage while refreshing path surfaces."
	)
	assert(
		(refreshed_render_model.get("landmark_slots", []) as Array).size() == (composition.get("visible_nodes", []) as Array).size(),
		"Expected render_model rebuild to refresh Prompt 08 socket metadata together with path surfaces."
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


func test_map_board_composer_spreads_opening_shell_across_a_readable_upper_fan() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var observed_above: bool = false
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
			observed_left = observed_left or offset.x < -24.0
			observed_right = observed_right or offset.x > 24.0
		if observed_above and observed_left and observed_right:
			break
	assert(observed_above, "Expected seeded opening-shell branches to keep a readable upward fan off the fixed-board anchor.")
	assert(observed_left and observed_right, "Expected seeded opening-shell branches to span both left and right sides around the fixed-board anchor.")


func test_map_board_composer_materially_uses_the_lower_band_in_opening_shell() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var board_size := Vector2(920, 1180)
	var playable_rect: Rect2 = MapBoardComposerV2Script.build_playable_rect(board_size)
	var lower_band_floor: float = playable_rect.position.y + playable_rect.size.y * 0.72
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
		var lower_band_visible_count: int = 0
		for node_variant in composition.get("visible_nodes", []):
			if typeof(node_variant) != TYPE_DICTIONARY:
				continue
			var position: Vector2 = Vector2((node_variant as Dictionary).get("world_position", Vector2.ZERO))
			if position.y >= lower_band_floor:
				lower_band_visible_count += 1
		assert(
			lower_band_visible_count >= 2,
			"Expected the opening-shell layout to keep at least two visible nodes materially inside the lower portrait band so the first board read does not stay trapped in the middle strip. Seed=%d lower_band_visible_count=%d." % [seed, lower_band_visible_count]
		)


func test_map_board_composer_uses_the_mid_and_upper_portrait_band_in_late_routes() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var board_size := Vector2(920, 1180)
	var playable_rect: Rect2 = MapBoardComposerV2Script.build_playable_rect(board_size)
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 5)
		var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
		var visible_bounds: Rect2 = _visible_node_bounds(composition)
		assert(
			visible_bounds.position.y <= playable_rect.position.y + playable_rect.size.y * 0.22,
			"Expected late-route board scatter to reach the upper playable band instead of collapsing into mostly lower lanes. Seed=%d bounds=%s." % [seed, str(visible_bounds)]
		)
		assert(
			visible_bounds.end.y >= playable_rect.position.y + playable_rect.size.y * 0.70,
			"Expected late-route board scatter to keep a grounded lower read while still using the upper portrait band. Seed=%d bounds=%s." % [seed, str(visible_bounds)]
		)
		assert(
			visible_bounds.size.y >= playable_rect.size.y * 0.64,
			"Expected progressed node scatter to preserve a tall portrait footprint after layout convergence. Seed=%d bounds=%s." % [seed, str(visible_bounds)]
		)


func test_map_board_composer_materially_uses_the_lower_portrait_band_in_late_routes() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var board_size := Vector2(920, 1180)
	var playable_rect: Rect2 = MapBoardComposerV2Script.build_playable_rect(board_size)
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 5)
		var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
		var lower_band_floor: float = playable_rect.position.y + playable_rect.size.y * 0.66 - 2.0
		var lower_band_visible_count: int = 0
		for node_variant in composition.get("visible_nodes", []):
			if typeof(node_variant) != TYPE_DICTIONARY:
				continue
			var position: Vector2 = Vector2((node_variant as Dictionary).get("world_position", Vector2.ZERO))
			if position.y >= lower_band_floor:
				lower_band_visible_count += 1
		assert(
			lower_band_visible_count >= 2,
			"Expected late-route layout to keep at least two visible nodes materially inside the lower portrait band so the board does not read as a top-only cluster. Seed=%d lower_band_visible_count=%d." % [seed, lower_band_visible_count]
		)


func test_map_board_composer_keeps_late_routes_off_the_top_edge_knot() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var board_size := Vector2(920, 1180)
	var playable_rect: Rect2 = MapBoardComposerV2Script.build_playable_rect(board_size)
	var top_edge_band_y: float = playable_rect.position.y + 24.0
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 5)
		var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
		var world_positions: Dictionary = composition.get("world_positions", {})
		var depth_by_node_id: Dictionary = _build_depth_by_node_id_from_snapshot(run_state.map_runtime_state.build_realized_graph_snapshots())
		var top_edge_count: int = 0
		for node_variant in composition.get("visible_nodes", []):
			if typeof(node_variant) != TYPE_DICTIONARY:
				continue
			var node_entry: Dictionary = node_variant
			var node_id: int = int(node_entry.get("node_id", -1))
			if int(depth_by_node_id.get(node_id, 0)) <= 2:
				continue
			var position: Vector2 = world_positions.get(node_id, Vector2.ZERO)
			if position.y <= top_edge_band_y:
				top_edge_count += 1
		assert(
			top_edge_count <= 1,
			"Expected late-route layout to avoid collapsing multiple deeper nodes into one top-edge knot. Seed=%d top_edge_count=%d." % [seed, top_edge_count]
		)


func test_map_board_composer_separates_late_route_adjacent_choices_into_distinct_lanes() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var board_size := Vector2(920, 1180)
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 5)
		var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
		var world_positions: Dictionary = composition.get("world_positions", {})
		var current_node_id: int = int(run_state.map_runtime_state.current_node_id)
		var current_position: Vector2 = world_positions.get(current_node_id, Vector2.ZERO)
		var adjacent_angles: Array[float] = []
		for adjacent_node_id in run_state.map_runtime_state.get_adjacent_node_ids():
			if String(run_state.map_runtime_state.get_node_state(int(adjacent_node_id))) == "resolved":
				continue
			var target_position: Vector2 = world_positions.get(int(adjacent_node_id), Vector2.ZERO)
			if target_position == Vector2.ZERO or target_position == current_position:
				continue
			var delta: Vector2 = target_position - current_position
			adjacent_angles.append(_normalize_angle_degrees(rad_to_deg(atan2(delta.y, delta.x))))
		if adjacent_angles.size() < 2:
			continue
		adjacent_angles.sort()
		var minimum_gap: float = _minimum_sorted_angle_gap_degrees(adjacent_angles)
		assert(
			minimum_gap >= 22.0,
			"Expected late-route adjacent choices to separate into distinct board lanes instead of one stacked visual corridor. Seed=%d min_gap=%.2f." % [seed, minimum_gap]
		)


func test_map_board_composer_spreads_late_routes_across_distinct_cardinal_sectors() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var board_size := Vector2(920, 1180)
	var sector_threshold_x: float = board_size.x * 0.08
	var sector_threshold_y: float = board_size.y * 0.07
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 5)
		var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
		var world_positions: Dictionary = composition.get("world_positions", {})
		var start_position: Vector2 = world_positions.get(0, Vector2.ZERO)
		var occupied_sectors: Dictionary = {}
		for node_variant in composition.get("visible_nodes", []):
			if typeof(node_variant) != TYPE_DICTIONARY:
				continue
			var node_entry: Dictionary = node_variant
			var node_id: int = int(node_entry.get("node_id", -1))
			if node_id == 0:
				continue
			var position: Vector2 = world_positions.get(node_id, Vector2.ZERO)
			if position == Vector2.ZERO:
				continue
			var delta: Vector2 = position - start_position
			if absf(delta.x) < sector_threshold_x and absf(delta.y) < sector_threshold_y:
				continue
			var horizontal_label: String = "center"
			if delta.x <= -sector_threshold_x:
				horizontal_label = "left"
			elif delta.x >= sector_threshold_x:
				horizontal_label = "right"
			var vertical_label: String = "mid"
			if delta.y <= -sector_threshold_y:
				vertical_label = "upper"
			elif delta.y >= sector_threshold_y:
				vertical_label = "lower"
			occupied_sectors["%s_%s" % [horizontal_label, vertical_label]] = true
		assert(
			occupied_sectors.size() >= 4,
			"Expected late-route board layout to occupy at least four distinct directional sectors so the footprint reads as a whole tabletop world. Seed=%d sectors=%s." % [seed, JSON.stringify(occupied_sectors.keys())]
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


func test_map_board_composer_surfaces_landmark_footprints_for_visible_nodes() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(29)

	var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var landmark_node: Dictionary = {}
	for node_variant in composition.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var node_family: String = String(node_entry.get("node_family", ""))
		if node_family == "start":
			continue
		landmark_node = node_entry
		break
	assert(not landmark_node.is_empty(), "Expected at least one visible non-start node for landmark-footprint coverage.")
	var footprint: Dictionary = landmark_node.get("landmark_footprint", {})
	assert(not footprint.is_empty(), "Expected visible nodes to expose family landmark-footprint metadata.")
	assert(
		not String(footprint.get("landmark_shape", "")).is_empty(),
		"Expected visible non-start nodes to expose a concrete landmark shape instead of a generic icon-only payload."
	)
	assert(
		Vector2(footprint.get("pocket_half_size", Vector2.ZERO)).x > float(landmark_node.get("clearing_radius", 0.0)),
		"Expected landmark pockets to be larger than the inner clearing so the node reads as a place, not just a circle."
	)
	assert(
		Vector2(footprint.get("signage_center_offset", Vector2.ZERO)).length() > 4.0,
		"Expected landmark signage to live off-center from the clearing so the icon can act as secondary confirmation."
	)


func test_map_board_composer_builds_family_distinct_landmark_profiles() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var board_size := Vector2(920.0, 1180.0)
	var route_vectors: Array = [Vector2.RIGHT, Vector2(0.3, -0.7).normalized()]
	var combat_profile: Dictionary = composer.call("_build_landmark_footprint_for_node", {
		"node_id": 1,
		"node_family": "combat",
		"state_semantic": "open",
		"clearing_radius": 56.0,
	}, route_vectors, 19, board_size)
	var reward_profile: Dictionary = composer.call("_build_landmark_footprint_for_node", {
		"node_id": 2,
		"node_family": "reward",
		"state_semantic": "open",
		"clearing_radius": 60.0,
	}, route_vectors, 19, board_size)
	var merchant_profile: Dictionary = composer.call("_build_landmark_footprint_for_node", {
		"node_id": 3,
		"node_family": "merchant",
		"state_semantic": "open",
		"clearing_radius": 60.0,
	}, route_vectors, 19, board_size)
	var rest_profile: Dictionary = composer.call("_build_landmark_footprint_for_node", {
		"node_id": 4,
		"node_family": "rest",
		"state_semantic": "open",
		"clearing_radius": 60.0,
	}, route_vectors, 19, board_size)
	var blacksmith_profile: Dictionary = composer.call("_build_landmark_footprint_for_node", {
		"node_id": 7,
		"node_family": "blacksmith",
		"state_semantic": "open",
		"clearing_radius": 60.0,
	}, route_vectors, 19, board_size)
	var hamlet_profile: Dictionary = composer.call("_build_landmark_footprint_for_node", {
		"node_id": 8,
		"node_family": "hamlet",
		"state_semantic": "open",
		"clearing_radius": 60.0,
	}, route_vectors, 19, board_size)
	var key_profile: Dictionary = composer.call("_build_landmark_footprint_for_node", {
		"node_id": 5,
		"node_family": "key",
		"state_semantic": "open",
		"clearing_radius": 62.0,
	}, route_vectors, 19, board_size)
	var boss_profile: Dictionary = composer.call("_build_landmark_footprint_for_node", {
		"node_id": 6,
		"node_family": "boss",
		"state_semantic": "open",
		"clearing_radius": 68.0,
	}, route_vectors, 19, board_size)
	assert(
		String(combat_profile.get("landmark_shape", "")) == "crossed_stakes",
		"Expected combat nodes to carry the combat landmark grammar instead of a generic pillar."
	)
	assert(
		String(reward_profile.get("landmark_shape", "")) == "cache_slab",
		"Expected reward nodes to carry the cache landmark grammar."
	)
	assert(
		String(merchant_profile.get("landmark_shape", "")) == "stall"
			and String(rest_profile.get("landmark_shape", "")) == "campfire",
		"Expected merchant and rest nodes to keep distinct support-family landmark grammars."
	)
	var support_shapes := {
		String(rest_profile.get("landmark_shape", "")): true,
		String(merchant_profile.get("landmark_shape", "")): true,
		String(blacksmith_profile.get("landmark_shape", "")): true,
		String(hamlet_profile.get("landmark_shape", "")): true,
	}
	var support_arrivals := {
		String(rest_profile.get("pocket_arrival_grammar", "")): true,
		String(merchant_profile.get("pocket_arrival_grammar", "")): true,
		String(blacksmith_profile.get("pocket_arrival_grammar", "")): true,
		String(hamlet_profile.get("pocket_arrival_grammar", "")): true,
	}
	assert(
		support_shapes.size() == 4 and support_arrivals.size() == 4,
		"Expected rest, merchant, blacksmith, and hamlet to keep separate icon-off support pocket grammars."
	)
	assert(
		Vector2(key_profile.get("route_anchor_direction", Vector2.ZERO)).length() > 0.1,
		"Expected landmark profiles to keep a route-anchor direction so local identity can orient against the corridor lane."
	)
	assert(
		String(key_profile.get("pocket_shape", "")) == "diamond"
			and String(key_profile.get("pocket_arrival_grammar", "")) == "key_shrine_arrival",
		"Expected key pockets to use a diamond shrine arrival grammar instead of reading like a reward slab or boss gate."
	)
	assert(
		String(boss_profile.get("pocket_shape", "")) == "rect"
			and String(boss_profile.get("pocket_arrival_grammar", "")) == "boss_gate_arrival"
			and String(boss_profile.get("pocket_arrival_grammar", "")) != String(key_profile.get("pocket_arrival_grammar", "")),
		"Expected boss pockets to keep a separate gate arrival grammar from key shrines."
	)
	assert(
		Vector2(boss_profile.get("pocket_half_size", Vector2.ZERO)).x > Vector2(combat_profile.get("pocket_half_size", Vector2.ZERO)).x,
		"Expected boss pockets to claim a larger footprint than ordinary combat pockets."
	)
	assert(
		float(reward_profile.get("signage_scale", 1.0)) <= 0.54
			and float(key_profile.get("signage_scale", 1.0)) <= 0.50
			and float(boss_profile.get("signage_scale", 1.0)) <= 0.50,
		"Expected landmark signage scale to keep the icon lane secondary to the pocket footprint."
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
	var playable_rect: Rect2 = MapBoardComposerV2Script.build_playable_rect(board_size)
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
			position.x >= playable_rect.position.x and position.x <= playable_rect.end.x,
			"Expected visible node placement to stay inside portrait-safe horizontal margins."
		)
		assert(
			position.y >= playable_rect.position.y and position.y <= playable_rect.end.y,
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


func test_map_board_composer_derives_terrain_masks_from_render_model_surfaces() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(41)
	_advance_visible_branch(run_state, 3)
	var board_size := Vector2(920, 1180)
	var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
	var render_model: Dictionary = composition.get("render_model", {})
	var path_surfaces: Array = render_model.get("path_surfaces", [])
	var clearing_surfaces: Array = render_model.get("clearing_surfaces", [])
	assert(not path_surfaces.is_empty(), "Expected render-model path surfaces before checking terrain mask ownership.")
	assert(not clearing_surfaces.is_empty(), "Expected render-model clearing surfaces before checking terrain mask ownership.")

	for shape_variant in composition.get("ground_shapes", []):
		if typeof(shape_variant) != TYPE_DICTIONARY:
			continue
		var shape_entry: Dictionary = shape_variant
		assert(
			not String(shape_entry.get("mask_source", "")).is_empty(),
			"Expected every ground shape to expose the terrain mask source used to keep old wrapper terrain auditable."
		)
		if String(shape_entry.get("family", "")) == "corridor":
			assert(
				String(shape_entry.get("mask_source", "")) == "render_model.path_surfaces",
				"Expected corridor ground masks to derive from render_model.path_surfaces, not only legacy layout_edges."
			)
	for shape_variant in composition.get("filler_shapes", []):
		if typeof(shape_variant) != TYPE_DICTIONARY:
			continue
		var shape_entry: Dictionary = shape_variant
		assert(
			String(shape_entry.get("mask_source", "")) == "render_model.path_surfaces+clearing_surfaces",
			"Expected filler masks to declare render-model path/clearing exclusion instead of acting as generic board decor."
		)
		var center: Vector2 = Vector2(shape_entry.get("center", Vector2.ZERO))
		var half_size: Vector2 = Vector2(shape_entry.get("half_size", Vector2.ZERO))
		var family: String = String(shape_entry.get("family", "rock"))
		assert(
			_nearest_filler_render_surface_clearance(center, half_size, family, composition) >= 0.0,
			"Expected filler masks to stay outside render-model path surfaces and clearing surfaces."
		)
	for shape_variant in composition.get("forest_shapes", []):
		if typeof(shape_variant) != TYPE_DICTIONARY:
			continue
		var shape_entry: Dictionary = shape_variant
		assert(
			String(shape_entry.get("mask_source", "")) == "render_model.path_surfaces+clearing_surfaces",
			"Expected canopy/decor masks to declare render-model path/clearing exclusion."
		)
		var center: Vector2 = Vector2(shape_entry.get("center", Vector2.ZERO))
		var radius: float = float(shape_entry.get("radius", 0.0))
		var family: String = String(shape_entry.get("family", "decor"))
		assert(
			_nearest_forest_render_surface_clearance(center, radius, family, composition) >= 0.0,
			"Expected canopy/decor masks to stay outside render-model path surfaces and clearing surfaces."
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
		assert(shape_a.get("shape", "ellipse") == shape_b.get("shape", ""), "Expected ground mask shape metadata to stay deterministic.")
		assert(not shape_a.has("node_family"), "Expected ground payload to stay free of node-family semantics.")
		assert(not shape_a.has("adjacent_node_ids"), "Expected ground payload to stay free of route-logic semantics.")
	var bed_shape: Dictionary = ground_shapes_a[0]
	assert(String(bed_shape.get("family", "")) == "bed", "Expected the ground payload to begin with the main board-surface bed shape.")
	assert(
		Vector2(bed_shape.get("half_size", Vector2.ZERO)).x > 120.0 and Vector2(bed_shape.get("half_size", Vector2.ZERO)).y > 80.0,
		"Expected the primary ground bed to define a meaningful board-interior surface area instead of a tiny decal."
	)


func test_map_board_composer_breaks_ground_into_corridor_and_pocket_masks() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(41)
	_advance_visible_branch(run_state, 4)
	var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
	var ground_shapes: Array = composition.get("ground_shapes", [])
	assert(not ground_shapes.is_empty(), "Expected ground composition before checking route/pocket masks.")
	var families := {}
	for shape_variant in ground_shapes:
		if typeof(shape_variant) != TYPE_DICTIONARY:
			continue
		var shape_entry: Dictionary = shape_variant
		families[String(shape_entry.get("family", ""))] = true
	assert(families.has("corridor"), "Expected ground composition to include explicit corridor masks instead of only one central slab.")
	assert(families.has("pocket"), "Expected ground composition to include landmark pocket masks instead of leaving local identity to clearings alone.")


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
	var ground_shapes: Array = composition_a.get("ground_shapes", [])
	assert(filler_shapes_a.size() == filler_shapes_b.size(), "Expected repeated compose calls to emit the same number of filler shapes.")
	assert(not ground_shapes.is_empty(), "Expected ground shapes before checking filler negative-space restraint.")
	var bed_shape: Dictionary = ground_shapes[0]
	var bed_center: Vector2 = Vector2(bed_shape.get("center", Vector2.ZERO))
	var bed_half_size: Vector2 = Vector2(bed_shape.get("half_size", Vector2.ZERO))
	assert(
		filler_shapes_a.size() <= MapBoardFillerBuilderScript.max_fillers_for_profile(String(composition_a.get("template_profile", "corridor"))),
		"Expected filler payload to stay within the auditable sparse-density cap for the active board profile."
	)
	if filler_shapes_a.is_empty():
		return
	for index in range(filler_shapes_a.size()):
		var shape_a: Dictionary = filler_shapes_a[index]
		var shape_b: Dictionary = filler_shapes_b[index]
		assert(shape_a.get("family", "") == shape_b.get("family", ""), "Expected filler shape family ordering to stay deterministic.")
		assert(shape_a.get("center", Vector2.ZERO) == shape_b.get("center", Vector2.ZERO), "Expected filler shape centers to stay deterministic.")
		assert(shape_a.get("half_size", Vector2.ZERO) == shape_b.get("half_size", Vector2.ZERO), "Expected filler shape sizes to stay deterministic.")
		assert(shape_a.get("rotation_degrees", 0.0) == shape_b.get("rotation_degrees", -999.0), "Expected filler shape rotation metadata to stay deterministic.")
		assert(shape_a.get("tone_shift", 0.0) == shape_b.get("tone_shift", 1.0), "Expected filler tone variation to stay deterministic.")
		assert(shape_a.get("alpha_scale", 0.0) == shape_b.get("alpha_scale", -1.0), "Expected filler alpha variation to stay deterministic.")
		assert(shape_a.get("texture_path", "") == shape_b.get("texture_path", ""), "Expected filler texture hookup to stay deterministic.")
		assert(shape_a.get("texture_scale", 0.0) == shape_b.get("texture_scale", -1.0), "Expected filler texture scale metadata to stay deterministic.")
		assert(not shape_a.has("node_family"), "Expected filler payload to stay free of node-family semantics.")
		assert(not shape_a.has("adjacent_node_ids"), "Expected filler payload to stay free of route-logic semantics.")
		assert(not String(shape_a.get("texture_path", "")).is_empty(), "Expected every filler shape family to expose a stable runtime texture path after the map-only asset hookup.")
		var half_size: Vector2 = Vector2(shape_a.get("half_size", Vector2.ZERO))
		var filler_center: Vector2 = Vector2(shape_a.get("center", Vector2.ZERO))
		var family: String = String(shape_a.get("family", "rock"))
		var nearest_node_clearance: float = _nearest_filler_node_clearance(filler_center, half_size, family, composition_a)
		assert(
			nearest_node_clearance >= 0.0,
			"Expected filler shapes to respect the explicit textured node-exclusion contract."
		)
		var nearest_route_clearance: float = _nearest_filler_route_clearance(filler_center, half_size, family, composition_a)
		assert(
			nearest_route_clearance >= 0.0,
			"Expected filler shapes to stay outside the explicit textured route-exclusion contract."
		)
		assert(
			not _visible_landmark_pocket_contains_point(
				composition_a,
				filler_center,
				Vector2(
					MapBoardFillerBuilderScript.footprint_half_size(half_size, family).x * 0.68 + 10.0,
					MapBoardFillerBuilderScript.footprint_half_size(half_size, family).y * 0.56 + 10.0
				)
			),
			"Expected filler shapes to stay out of visible landmark pockets instead of polluting local identity clearings."
		)
		var filler_footprint: Vector2 = MapBoardFillerBuilderScript.footprint_half_size(half_size, family)
		assert(
			not _ellipse_contains_point(
				filler_center,
				bed_center,
				Vector2(
					bed_half_size.x + filler_footprint.x * 0.26,
					bed_half_size.y + filler_footprint.y * 0.22
				)
			),
			"Expected filler shapes to stay in negative space outside the main ground bed instead of reading like props pasted onto the central slab."
		)


func test_map_board_composer_centers_ground_bed_on_layout_action_bounds() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(29)
	_advance_visible_branch(run_state, 4)
	var board_size := Vector2(920, 1180)
	var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
	var ground_shapes: Array = composition.get("ground_shapes", [])
	assert(not ground_shapes.is_empty(), "Expected ground composition before checking action-bounds alignment.")
	var bed_shape: Dictionary = ground_shapes[0]
	var action_bounds: Rect2 = _action_bounds_from_composition(composition)
	var action_center: Vector2 = action_bounds.position + action_bounds.size * 0.5
	assert(
		Vector2(bed_shape.get("center", Vector2.ZERO)).distance_to(action_center) <= 116.0,
		"Expected the main ground bed to track the frozen node/path action bounds instead of drifting away from the playable board pocket."
	)


func test_map_board_composer_tames_corridor_ground_bed_footprint() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var board_size := Vector2(920, 1180)
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 4)
		var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
		assert(
			String(composition.get("template_profile", "")) == "corridor",
			"Expected this regression sweep to stay on the corridor profile seeds it was curated from."
		)
		var ground_shapes: Array = composition.get("ground_shapes", [])
		assert(not ground_shapes.is_empty(), "Expected ground shapes before corridor bed tuning checks.")
		var bed_shape: Dictionary = ground_shapes[0]
		var bed_center: Vector2 = Vector2(bed_shape.get("center", Vector2.ZERO))
		var bed_half_size: Vector2 = Vector2(bed_shape.get("half_size", Vector2.ZERO))
		assert(
			bed_half_size.x * 2.0 <= board_size.x * 0.72,
			"Expected corridor ground beds to stay off the broad full-board mass look in late seeds. Seed=%d half_size=%s." % [seed, str(bed_half_size)]
		)
		assert(
			bed_half_size.y * 2.0 <= board_size.y * 0.37,
			"Expected corridor ground beds to avoid the older tall dark slab look in late seeds. Seed=%d half_size=%s." % [seed, str(bed_half_size)]
		)
		assert(
			float(bed_shape.get("alpha_scale", 1.0)) <= 0.72,
			"Expected corridor ground beds to keep a lighter alpha scale than the older heavier board-center mass. Seed=%d alpha=%.2f." % [seed, float(bed_shape.get("alpha_scale", 1.0))]
		)
		for shape_index in range(1, ground_shapes.size()):
			var shape_entry: Dictionary = ground_shapes[shape_index]
			if String(shape_entry.get("family", "")) != "breakup":
				continue
			var shape_center: Vector2 = Vector2(shape_entry.get("center", Vector2.ZERO))
			var shape_half_size: Vector2 = Vector2(shape_entry.get("half_size", Vector2.ZERO))
			assert(
				not _visible_landmark_pocket_contains_point(composition, shape_center, shape_half_size * 0.36),
				"Expected corridor ground breakup patches to stay out of landmark pocket masks instead of muddying local clearings. Seed=%d shape=%s." % [seed, JSON.stringify(shape_entry)]
			)


func test_map_board_composer_keeps_forest_shapes_clear_of_route_action_pocket() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(41)
	_advance_visible_branch(run_state, 4)
	var board_size := Vector2(920, 1180)
	var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
	var graph_snapshot: Array[Dictionary] = run_state.map_runtime_state.build_realized_graph_snapshots()
	var world_positions: Dictionary = composition.get("world_positions", {})
	for shape_variant in composition.get("forest_shapes", []):
		if typeof(shape_variant) != TYPE_DICTIONARY:
			continue
		var shape: Dictionary = shape_variant
		var center: Vector2 = Vector2(shape.get("center", Vector2.ZERO))
		var radius: float = float(shape.get("radius", 0.0))
		var family: String = String(shape.get("family", "decor"))
		var nearest_node_clearance: float = INF
		for node_entry in graph_snapshot:
			var node_id: int = int(node_entry.get("node_id", -1))
			var node_position: Vector2 = Vector2(world_positions.get(node_id, Vector2.ZERO))
			if node_position == Vector2.ZERO:
				continue
			var node_radius: float = float(composer.call("build_clearing_radius", String(node_entry.get("node_family", "")), "open", board_size))
			var required_node_clearance: float = MapBoardBackdropBuilderScript.node_clearance_radius(node_radius, radius, family)
			nearest_node_clearance = min(nearest_node_clearance, center.distance_to(node_position) - required_node_clearance)
		assert(
			nearest_node_clearance >= 0.0,
			"Expected %s world-fill shapes to stay out of node clearings after textured layout convergence." % family
		)
		var nearest_route_clearance: float = _nearest_forest_route_clearance(center, radius, family, composition)
		assert(
			nearest_route_clearance >= 0.0,
			"Expected %s world-fill shapes to stay outside the frozen route pocket after textured layout convergence." % family
		)
		assert(
			not _visible_landmark_pocket_contains_point(
				composition,
				center,
				Vector2.ONE * (MapBoardBackdropBuilderScript.forest_draw_half_extent(radius, family) * 0.30 + 14.0)
			),
			"Expected %s world-fill shapes to stay out of visible landmark pocket masks after the terrain/filler pass." % family
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


func test_map_board_composer_routes_visible_edges_from_clearing_throats() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 6)
		var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
		for edge_variant in composition.get("visible_edges", []):
			if typeof(edge_variant) != TYPE_DICTIONARY:
				continue
			var edge_entry: Dictionary = edge_variant
			var points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
			assert(points.size() >= 2, "Expected every visible road to expose sampled endpoint geometry. Seed=%d edge=%s." % [seed, JSON.stringify(edge_entry)])
			var from_node_id: int = int(edge_entry.get("from_node_id", -1))
			var to_node_id: int = int(edge_entry.get("to_node_id", -1))
			var from_node: Dictionary = _find_visible_node_by_id(composition, from_node_id)
			var to_node: Dictionary = _find_visible_node_by_id(composition, to_node_id)
			assert(not from_node.is_empty() and not to_node.is_empty(), "Expected visible edge endpoints to resolve to visible nodes before throat checks.")
			var from_center: Vector2 = Vector2(from_node.get("world_position", Vector2.ZERO))
			var to_center: Vector2 = Vector2(to_node.get("world_position", Vector2.ZERO))
			var center_distance: float = from_center.distance_to(to_center)
			var start_floor: float = minf(float(from_node.get("clearing_radius", 0.0)) * 0.90, center_distance * 0.38)
			var end_floor: float = minf(float(to_node.get("clearing_radius", 0.0)) * 0.90, center_distance * 0.38)
			assert(
				points[0].distance_to(from_center) >= start_floor,
				"Expected visible roads to leave from the source clearing throat, not the icon center. Seed=%d edge=%s distance=%.2f floor=%.2f." % [
					seed,
					JSON.stringify([from_node_id, to_node_id]),
					points[0].distance_to(from_center),
					start_floor,
				]
			)
			assert(
				points[points.size() - 1].distance_to(to_center) >= end_floor,
				"Expected visible roads to enter through the target clearing throat, not the icon center. Seed=%d edge=%s distance=%.2f floor=%.2f." % [
					seed,
					JSON.stringify([from_node_id, to_node_id]),
					points[points.size() - 1].distance_to(to_center),
					end_floor,
				]
			)


func test_map_board_composer_separates_opening_choices_into_distinct_corridor_throats() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
		var current_node_id: int = int(composition.get("current_node_id", -1))
		var throat_ids: Dictionary = {}
		var cardinal_directions: Dictionary = {}
		var opening_edge_count: int = 0
		for edge_variant in composition.get("visible_edges", []):
			if typeof(edge_variant) != TYPE_DICTIONARY:
				continue
			var edge_entry: Dictionary = edge_variant
			if not bool(edge_entry.get("is_local_actionable", false)):
				continue
			assert(
				int(edge_entry.get("corridor_departure_node_id", -1)) == current_node_id,
				"Expected opening roads to derive departure from the current center-local pocket. Seed=%d edge=%s." % [seed, JSON.stringify(edge_entry)]
			)
			var throat_id: String = String(edge_entry.get("corridor_throat_id", ""))
			var cardinal_direction: String = String(edge_entry.get("corridor_cardinal_direction", ""))
			assert(not throat_id.is_empty(), "Expected opening roads to expose a stable corridor throat id. Seed=%d edge=%s." % [seed, JSON.stringify(edge_entry)])
			assert(
				not throat_ids.has(throat_id),
				"Expected first choices to leave through distinct corridor throats instead of sharing the same lane. Seed=%d throat=%s." % [seed, throat_id]
			)
			throat_ids[throat_id] = true
			cardinal_directions[cardinal_direction] = true
			opening_edge_count += 1
		assert(opening_edge_count >= 2, "Expected the opening shell to expose multiple route choices before checking throat separation. Seed=%d." % seed)
		assert(cardinal_directions.size() >= 2, "Expected opening routes to read in more than one board direction. Seed=%d directions=%s." % [seed, JSON.stringify(cardinal_directions.keys())])


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
	var path_safe_rect: Rect2 = MapBoardComposerV2Script.build_path_safe_rect(board_size)
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
			assert(
				MapBoardGeometryScript.polyline_stays_inside_rect(points, path_safe_rect, 1.0),
				"Expected composed road geometry to stay inside the fixed-board safe path rect instead of leaning on off-frame rescue lanes. Seed=%d edge=%s." % [
					seed,
					JSON.stringify([int(edge_entry.get("from_node_id", -1)), int(edge_entry.get("to_node_id", -1))]),
				]
			)


func test_map_board_composer_exposes_fixed_board_safe_bounds_contract() -> void:
	var board_size := Vector2(920.0, 1180.0)
	var playable_rect: Rect2 = MapBoardComposerV2Script.build_playable_rect(board_size)
	var path_safe_rect: Rect2 = MapBoardComposerV2Script.build_path_safe_rect(board_size)
	var playable_margin: Vector2 = MapBoardComposerV2Script.build_playable_margin()
	assert(
		is_equal_approx(playable_margin.x, MapBoardComposerV2Script.MIN_BOARD_MARGIN.x)
		and is_equal_approx(playable_margin.y, MapBoardComposerV2Script.MIN_BOARD_MARGIN.y),
		"Expected the fixed-board playable margin helper to preserve the checked-in node-center envelope."
	)
	assert(
		playable_rect.position == playable_margin and playable_rect.end == board_size - playable_margin,
		"Expected the fixed-board playable rect to be derived directly from the explicit safe margin contract."
	)
	assert(
		playable_margin.x >= MapBoardComposerV2Script.MAX_NODE_CLEARING_RADIUS + MapBoardComposerV2Script.OVERLAY_CLEARANCE.x
		and playable_margin.y >= MapBoardComposerV2Script.MAX_NODE_CLEARING_RADIUS + MapBoardComposerV2Script.OVERLAY_CLEARANCE.y,
		"Expected the playable rect to reserve explicit node plus overlay clearance instead of leaving it implicit."
	)
	assert(
		path_safe_rect.position.x >= MapBoardComposerV2Script.PATH_STROKE_CLEARANCE
		and path_safe_rect.position.y >= MapBoardComposerV2Script.PATH_STROKE_CLEARANCE,
		"Expected the path-safe rect to reserve explicit trail stroke clearance at the board edge."
	)
	assert(
		path_safe_rect.position.x >= MapBoardComposerV2Script.WALKER_FOOTPRINT_CLEARANCE * 0.5
		and path_safe_rect.position.y >= MapBoardComposerV2Script.WALKER_FOOTPRINT_CLEARANCE * 0.5,
		"Expected the path-safe rect to reserve walker footprint clearance at the board edge."
	)
	assert(
		playable_rect.position.x > path_safe_rect.position.x and playable_rect.position.y > path_safe_rect.position.y,
		"Expected node-center placement to stay inside a stricter safe envelope than the routed trail footprint."
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


func test_map_board_composer_exposes_sector_corridor_metadata_for_visible_edges() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var allowed_cardinal_directions := {
		"north": true,
		"south": true,
		"east": true,
		"west": true,
	}
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 5)
		var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
		assert(String(composition.get("placement_mode", "")) == "runtime_slot_anchor", "Expected corridor metadata checks to run against runtime-derived slot anchors.")
		var current_node_id: int = int(composition.get("current_node_id", -1))
		var adjacent_node_ids: Dictionary = {}
		for adjacent_node_id in run_state.map_runtime_state.get_adjacent_node_ids(current_node_id):
			adjacent_node_ids[int(adjacent_node_id)] = true
		for edge_variant in composition.get("visible_edges", []):
			if typeof(edge_variant) != TYPE_DICTIONARY:
				continue
			var edge_entry: Dictionary = edge_variant
			var departure_sector_id: String = String(edge_entry.get("corridor_departure_sector_id", ""))
			var arrival_sector_id: String = String(edge_entry.get("corridor_arrival_sector_id", ""))
			var cardinal_direction: String = String(edge_entry.get("corridor_cardinal_direction", ""))
			assert(not departure_sector_id.is_empty(), "Expected visible roads to keep derived departure sector metadata. Seed=%d edge=%s." % [seed, JSON.stringify(edge_entry)])
			assert(not arrival_sector_id.is_empty(), "Expected visible roads to keep derived arrival sector metadata. Seed=%d edge=%s." % [seed, JSON.stringify(edge_entry)])
			assert(allowed_cardinal_directions.has(cardinal_direction), "Expected visible roads to expose a board-cardinal corridor read. Seed=%d direction=%s edge=%s." % [seed, cardinal_direction, JSON.stringify(edge_entry)])
			assert(not String(edge_entry.get("corridor_throat_id", "")).is_empty(), "Expected visible roads to expose a stable presentation-only corridor throat id. Seed=%d edge=%s." % [seed, JSON.stringify(edge_entry)])
			if bool(edge_entry.get("is_local_actionable", false)):
				assert(int(edge_entry.get("corridor_departure_node_id", -1)) == current_node_id, "Expected local actionable corridor metadata to be current-pocket relative. Seed=%d edge=%s." % [seed, JSON.stringify(edge_entry)])
				assert(adjacent_node_ids.has(int(edge_entry.get("corridor_arrival_node_id", -1))), "Expected local actionable corridor metadata to point at an actual current adjacent node. Seed=%d edge=%s." % [seed, JSON.stringify(edge_entry)])


func test_map_board_composer_exposes_route_surface_semantics_for_visible_edges() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var observed_branch_actionable: bool = false
	var observed_branch_history: bool = false
	var observed_reconnect_history: bool = false
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 5)
		var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
		var primary_actionable_count: int = 0
		for edge_variant in composition.get("visible_edges", []):
			if typeof(edge_variant) != TYPE_DICTIONARY:
				continue
			var edge_entry: Dictionary = edge_variant
			var route_surface_semantic: String = String(edge_entry.get("route_surface_semantic", ""))
			var corridor_role_semantic: String = String(edge_entry.get("corridor_role_semantic", route_surface_semantic))
			assert(
				corridor_role_semantic == route_surface_semantic,
				"Expected visible roads to keep the same first-class corridor role and route semantic instead of splitting hierarchy truth across two fields. Seed=%d edge=%s role=%s surface=%s." % [
					seed,
					JSON.stringify([int(edge_entry.get("from_node_id", -1)), int(edge_entry.get("to_node_id", -1))]),
					corridor_role_semantic,
					route_surface_semantic,
				]
			)
			if bool(edge_entry.get("is_history", false)):
				if bool(edge_entry.get("is_reconnect_edge", false)):
					assert(
						route_surface_semantic == "reconnect_corridor",
						"Expected reconnect history roads to expose the dedicated reconnect corridor semantic. Seed=%d edge=%s semantic=%s." % [
							seed,
							JSON.stringify([int(edge_entry.get("from_node_id", -1)), int(edge_entry.get("to_node_id", -1))]),
							route_surface_semantic,
						]
					)
					observed_reconnect_history = true
				else:
					assert(
						route_surface_semantic in ["branch_history_corridor", "history_corridor"],
						"Expected non-local discovered roads to stay in the branch/history corridor set instead of collapsing back into the older generic history tag. Seed=%d edge=%s semantic=%s." % [
							seed,
							JSON.stringify([int(edge_entry.get("from_node_id", -1)), int(edge_entry.get("to_node_id", -1))]),
							route_surface_semantic,
						]
					)
					if route_surface_semantic == "branch_history_corridor":
						observed_branch_history = true
			else:
				assert(
					bool(edge_entry.get("is_local_actionable", false)),
					"Expected non-history visible roads to stay anchored to the current local movement pocket. Seed=%d edge=%s semantic=%s." % [
						seed,
						JSON.stringify([int(edge_entry.get("from_node_id", -1)), int(edge_entry.get("to_node_id", -1))]),
						route_surface_semantic,
					]
				)
				assert(
					route_surface_semantic in ["primary_actionable_corridor", "branch_actionable_corridor", "reconnect_corridor"],
					"Expected current-pocket roads to expose the stronger corridor hierarchy instead of falling back to the older local/history ladder. Seed=%d edge=%s semantic=%s." % [
						seed,
						JSON.stringify([int(edge_entry.get("from_node_id", -1)), int(edge_entry.get("to_node_id", -1))]),
						route_surface_semantic,
					]
				)
				if route_surface_semantic == "primary_actionable_corridor":
					primary_actionable_count += 1
				elif route_surface_semantic == "branch_actionable_corridor":
					observed_branch_actionable = true
		assert(primary_actionable_count == 1, "Expected each visible pocket to keep exactly one dominant primary actionable corridor.")
	assert(
		observed_reconnect_history,
		"Expected the curated late-route seed set to keep at least one visible reconnect corridor once the Prompt 48 backbone-compatible history window is in view."
	)
	assert(
		observed_branch_actionable,
		"Expected the curated late-route seed set to keep at least one branch actionable corridor visible once Prompt 51 hierarchy lands."
	)
	assert(
		observed_branch_history,
		"Expected the curated late-route seed set to keep at least one branch history corridor visible once Prompt 51 hierarchy lands."
	)


func test_map_board_composer_rejects_near_parallel_history_braids() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var local_focus_edges: Array[Dictionary] = [
		{
			"from_node_id": 0,
			"to_node_id": 1,
			"route_surface_semantic": "primary_actionable_corridor",
			"corridor_role_semantic": "primary_actionable_corridor",
			"points": PackedVector2Array([Vector2(140.0, 220.0), Vector2(420.0, 220.0)]),
		}
	]
	var history_edges: Array[Dictionary] = [
		{
			"from_node_id": 10,
			"to_node_id": 11,
			"is_reconnect_edge": true,
			"depth_delta": 0,
			"route_surface_semantic": "reconnect_corridor",
			"corridor_role_semantic": "reconnect_corridor",
			"points": PackedVector2Array([Vector2(140.0, 246.0), Vector2(420.0, 246.0)]),
		},
		{
			"from_node_id": 20,
			"to_node_id": 21,
			"is_reconnect_edge": false,
			"depth_delta": 1,
			"route_surface_semantic": "history_corridor",
			"corridor_role_semantic": "history_corridor",
			"points": PackedVector2Array([Vector2(140.0, 332.0), Vector2(420.0, 332.0)]),
		},
	]
	var filtered_history_edges: Array[Dictionary] = composer.call(
		"_filter_non_crossing_history_edges",
		local_focus_edges,
		history_edges
	)
	assert(
		filtered_history_edges.size() == 1,
		"Expected the history-edge owner to reject near-parallel braid ambiguity instead of only catching literal road crossings."
	)
	assert(
		not bool((filtered_history_edges[0] as Dictionary).get("is_reconnect_edge", true)),
		"Expected an ordinary discovered branch/history road to win over a near-parallel reconnect braid candidate."
	)


func test_map_board_composer_keeps_one_visible_outer_reconnect_in_late_route_history() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var observed_reconnect_seed_count: int = 0
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 5)
		var graph_snapshot: Array[Dictionary] = run_state.map_runtime_state.build_realized_graph_snapshots()
		var composition: Dictionary = composer.call("compose", run_state, Vector2(920, 1180), Vector2(0.5, 0.58), Vector2(148, 212))
		var reconnect_edge: Dictionary = _find_visible_same_depth_edge(composition, graph_snapshot)
		if reconnect_edge.is_empty():
			continue
		observed_reconnect_seed_count += 1
		assert(
			String(reconnect_edge.get("path_family", "")) == "outward_reconnecting_arc",
			"Expected visible same-depth reconnects to use the dedicated outward reconnect family instead of blending back into the ordinary corridor curves. Seed=%d." % seed
		)
	assert(
		observed_reconnect_seed_count > 0,
		"Expected the curated late-route seed set to keep at least one visible same-depth outer reconnect once the Prompt 48 backbone-compatible history window is in view."
	)


func test_map_board_composer_limits_same_depth_reconnect_detours_on_fixed_board() -> void:
	var composer: RefCounted = MapBoardComposerV2Script.new()
	var board_size := Vector2(920, 1180)
	var observed_reconnect_seed_count: int = 0
	for seed in [11, 29, 41]:
		var run_state: RunState = RunState.new()
		run_state.reset_for_new_run()
		run_state.configure_run_seed(seed)
		_advance_visible_branch(run_state, 5)
		var graph_snapshot: Array[Dictionary] = run_state.map_runtime_state.build_realized_graph_snapshots()
		var composition: Dictionary = composer.call("compose", run_state, board_size, Vector2(0.5, 0.58), Vector2(148, 212))
		var reconnect_edge: Dictionary = _find_visible_same_depth_edge(composition, graph_snapshot)
		if reconnect_edge.is_empty():
			continue
		observed_reconnect_seed_count += 1
		var points: PackedVector2Array = reconnect_edge.get("points", PackedVector2Array())
		var path_length: float = MapBoardGeometryScript.visible_edge_polyline_length({"points": points})
		var direct_distance: float = points[0].distance_to(points[points.size() - 1])
		assert(
			path_length <= direct_distance * 1.60,
			"Expected same-depth reconnect history roads to stay board-local instead of taking a giant outer-frame detour. Seed=%d ratio=%.3f." % [seed, path_length / maxf(1.0, direct_distance)]
		)
		assert(
			_minimum_polyline_edge_clearance(points, board_size) >= 72.0,
			"Expected same-depth reconnect history roads to stay off the portrait frame edge after convergence. Seed=%d." % seed
		)
	assert(
		observed_reconnect_seed_count > 0,
		"Expected the curated late-route seed set to expose at least one same-depth reconnect for the bounded-detour check once the Prompt 48 backbone-compatible history window is in view."
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


func _nearest_filler_node_clearance(center: Vector2, half_size: Vector2, family: String, composition: Dictionary) -> float:
	var nearest_clearance: float = INF
	for node_variant in composition.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var node_center: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
		var required_clearance: float = MapBoardFillerBuilderScript.node_exclusion_radius(
			float(node_entry.get("clearing_radius", 0.0)),
			half_size,
			family
		)
		nearest_clearance = min(nearest_clearance, center.distance_to(node_center) - required_clearance)
	return nearest_clearance


func _nearest_filler_route_clearance(center: Vector2, half_size: Vector2, family: String, composition: Dictionary) -> float:
	var nearest_clearance: float = INF
	for edge_variant in composition.get("layout_edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		var points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		var required_clearance: float = MapBoardFillerBuilderScript.route_exclusion_radius(half_size, family)
		nearest_clearance = min(nearest_clearance, _polyline_distance_to_point(points, center) - required_clearance)
	return nearest_clearance


func _nearest_forest_route_clearance(center: Vector2, radius: float, family: String, composition: Dictionary) -> float:
	var nearest_clearance: float = INF
	for edge_variant in composition.get("layout_edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		var points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		var required_clearance: float = MapBoardBackdropBuilderScript.route_clearance_radius(radius, family)
		nearest_clearance = min(nearest_clearance, _polyline_distance_to_point(points, center) - required_clearance)
	return nearest_clearance


func _nearest_filler_render_surface_clearance(center: Vector2, half_size: Vector2, family: String, composition: Dictionary) -> float:
	var nearest_clearance: float = INF
	var render_model: Dictionary = composition.get("render_model", {})
	for surface_variant in render_model.get("path_surfaces", []):
		if typeof(surface_variant) != TYPE_DICTIONARY:
			continue
		var surface_entry: Dictionary = surface_variant
		var points: PackedVector2Array = surface_entry.get("centerline_points", PackedVector2Array())
		if points.size() < 2:
			continue
		var surface_width: float = maxf(float(surface_entry.get("surface_width", 0.0)), float(surface_entry.get("outer_width", 0.0)))
		var required_clearance: float = MapBoardFillerBuilderScript.route_exclusion_radius(half_size, family) + surface_width * 0.50
		nearest_clearance = min(nearest_clearance, _polyline_distance_to_point(points, center) - required_clearance)
	for clearing_variant in render_model.get("clearing_surfaces", []):
		if typeof(clearing_variant) != TYPE_DICTIONARY:
			continue
		var clearing_entry: Dictionary = clearing_variant
		var clearing_center: Vector2 = Vector2(clearing_entry.get("center", Vector2.ZERO))
		var clearing_radius: float = float(clearing_entry.get("radius", 0.0))
		var filler_footprint: Vector2 = MapBoardFillerBuilderScript.footprint_half_size(half_size, family)
		var required_clearing_clearance: float = clearing_radius + maxf(filler_footprint.x, filler_footprint.y) + 18.0
		nearest_clearance = min(nearest_clearance, center.distance_to(clearing_center) - required_clearing_clearance)
	return nearest_clearance


func _nearest_forest_render_surface_clearance(center: Vector2, radius: float, family: String, composition: Dictionary) -> float:
	var nearest_clearance: float = INF
	var render_model: Dictionary = composition.get("render_model", {})
	for surface_variant in render_model.get("path_surfaces", []):
		if typeof(surface_variant) != TYPE_DICTIONARY:
			continue
		var surface_entry: Dictionary = surface_variant
		var points: PackedVector2Array = surface_entry.get("centerline_points", PackedVector2Array())
		if points.size() < 2:
			continue
		var required_clearance: float = MapBoardBackdropBuilderScript.route_clearance_radius(radius, family)
		nearest_clearance = min(nearest_clearance, _polyline_distance_to_point(points, center) - required_clearance)
	for clearing_variant in render_model.get("clearing_surfaces", []):
		if typeof(clearing_variant) != TYPE_DICTIONARY:
			continue
		var clearing_entry: Dictionary = clearing_variant
		var clearing_center: Vector2 = Vector2(clearing_entry.get("center", Vector2.ZERO))
		var clearing_radius: float = float(clearing_entry.get("radius", 0.0))
		var required_clearing_clearance: float = clearing_radius + MapBoardBackdropBuilderScript.forest_draw_half_extent(radius, family) * 0.34 + 14.0
		nearest_clearance = min(nearest_clearance, center.distance_to(clearing_center) - required_clearing_clearance)
	return nearest_clearance


func _action_bounds_from_composition(composition: Dictionary) -> Rect2:
	var points: Array[Vector2] = []
	for point_variant in (composition.get("world_positions", {}) as Dictionary).values():
		var point: Vector2 = Vector2(point_variant)
		if point != Vector2.ZERO:
			points.append(point)
	for edge_variant in composition.get("layout_edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		for point in PackedVector2Array(edge_entry.get("points", PackedVector2Array())):
			points.append(point)
	if points.is_empty():
		return Rect2()
	var min_point: Vector2 = points[0]
	var max_point: Vector2 = points[0]
	for point in points:
		min_point = Vector2(minf(min_point.x, point.x), minf(min_point.y, point.y))
		max_point = Vector2(maxf(max_point.x, point.x), maxf(max_point.y, point.y))
	return Rect2(min_point, max_point - min_point)


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


func _minimum_polyline_edge_clearance(points: PackedVector2Array, board_size: Vector2) -> float:
	if points.is_empty():
		return 0.0
	var nearest_clearance: float = INF
	for point_index in range(1, max(1, points.size() - 1)):
		var point: Vector2 = points[point_index]
		nearest_clearance = min(
			nearest_clearance,
			minf(minf(point.x, board_size.x - point.x), minf(point.y, board_size.y - point.y))
	)
	return nearest_clearance if nearest_clearance < INF else 0.0


func _normalize_angle_degrees(angle: float) -> float:
	var normalized: float = fposmod(angle, 360.0)
	if normalized < 0.0:
		normalized += 360.0
	return normalized


func _minimum_sorted_angle_gap_degrees(sorted_angles: Array[float]) -> float:
	if sorted_angles.size() < 2:
		return 360.0
	var minimum_gap: float = 360.0
	for index in range(sorted_angles.size()):
		var current_angle: float = float(sorted_angles[index])
		var next_angle: float = float(sorted_angles[(index + 1) % sorted_angles.size()])
		if next_angle <= current_angle:
			next_angle += 360.0
		minimum_gap = minf(minimum_gap, next_angle - current_angle)
	return minimum_gap


func _distance_point_to_segment(point: Vector2, start_point: Vector2, end_point: Vector2) -> float:
	var segment: Vector2 = end_point - start_point
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= 0.001:
		return point.distance_to(start_point)
	var t: float = clampf((point - start_point).dot(segment) / segment_length_squared, 0.0, 1.0)
	var projection: Vector2 = start_point + segment * t
	return point.distance_to(projection)


func _ellipse_contains_point(point: Vector2, center: Vector2, half_size: Vector2) -> bool:
	if half_size.x <= 0.001 or half_size.y <= 0.001:
		return false
	var normalized_x: float = (point.x - center.x) / half_size.x
	var normalized_y: float = (point.y - center.y) / half_size.y
	return normalized_x * normalized_x + normalized_y * normalized_y <= 1.0


func _visible_landmark_pocket_contains_point(composition: Dictionary, point: Vector2, expansion_half_size: Vector2 = Vector2.ZERO) -> bool:
	for node_variant in composition.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var footprint_variant: Variant = node_entry.get("landmark_footprint", {})
		if typeof(footprint_variant) != TYPE_DICTIONARY:
			continue
		var footprint: Dictionary = footprint_variant
		if footprint.is_empty():
			continue
		var pocket_center: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO)) + Vector2(footprint.get("pocket_center_offset", Vector2.ZERO))
		var pocket_half_size: Vector2 = Vector2(footprint.get("pocket_half_size", Vector2.ZERO)) + expansion_half_size
		var pocket_shape: String = String(footprint.get("pocket_shape", "ellipse"))
		if _mask_contains_point(point, pocket_center, pocket_half_size, pocket_shape):
			return true
	return false


func _mask_contains_point(point: Vector2, center: Vector2, half_size: Vector2, shape: String) -> bool:
	if shape == "rect":
		return Rect2(center - half_size, half_size * 2.0).has_point(point)
	return _ellipse_contains_point(point, center, half_size)


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
