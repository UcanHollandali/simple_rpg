# Layer: Tests
extends SceneTree
class_name TestMapExplorePresenter

const MapExplorePresenterScript = preload("res://Game/UI/map_explore_presenter.gd")
const MapExploreSceneScript = preload("res://scenes/map_explore.gd")
const MapExplorePackedScene: PackedScene = preload("res://scenes/map_explore.tscn")
const MapFocusHelperScript = preload("res://Game/UI/map_focus_helper.gd")
const MapRouteBindingScript = preload("res://Game/UI/map_route_binding.gd")
const MapRouteMotionHelperScript = preload("res://Game/UI/map_route_motion_helper.gd")
const MapBoardComposerV2Script = preload("res://Game/UI/map_board_composer_v2.gd")
const EventScenePacked: PackedScene = preload("res://scenes/event.tscn")
const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	test_map_presenter_builds_runtime_graph_labels()
	test_map_scene_prefers_composer_world_positions()
	test_map_scene_keeps_emergency_route_slot_fallback_narrow()
	test_map_scene_only_assigns_emergency_slots_to_missing_world_positions()
	test_map_scene_builds_route_move_path_from_render_model_surface_geometry()
	test_map_route_motion_helper_falls_back_to_visible_edge_geometry_without_render_model()
	test_map_scene_builds_pending_roadside_visual_sample_from_render_model_surface_geometry()
	test_map_scene_accepts_deferred_roadside_transition_for_destination_restore()
	test_map_scene_reports_zero_fixed_board_offset_for_focus_requests()
	test_map_route_binding_keeps_fixed_board_offset_after_refresh()
	test_map_scene_keeps_roadside_visual_offset_fixed()
	test_map_route_binding_places_idle_walker_below_current_node_center()
	test_map_route_binding_keeps_hover_preview_marker_weaker_than_active_selection()
	test_map_route_binding_leans_idle_walker_toward_focused_route_lane()
	test_map_route_motion_helper_emits_grounded_stride_sway()
	test_map_route_binding_recomposes_board_positions_after_route_grid_resize()
	test_map_route_binding_refreshes_cached_node_radii_after_moderate_resize()
	test_map_route_buttons_suppress_default_tooltip_copy()
	test_map_scene_does_not_spawn_legacy_line2d_roads()
	test_event_overlay_uses_stable_offers_shell()
	test_map_scene_retires_camera_follow_progress_by_default()
	test_map_scene_queues_recompose_when_route_grid_resizes_during_refresh()
	test_map_route_binding_reconciles_route_buttons_after_selection_finishes()
	print("test_map_explore_presenter: all assertions passed")
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func test_map_presenter_builds_runtime_graph_labels() -> void:
	var presenter: RefCounted = MapExplorePresenterScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.stage_index = 2
	run_state.configure_run_seed(1)
	run_state.player_hp = 48
	run_state.hunger = 11
	run_state.gold = 17
	run_state.inventory_state.weapon_instance["current_durability"] = 9
	run_state.map_runtime_state.move_to_node(1)
	run_state.map_runtime_state.mark_node_resolved(1)
	var current_family_name: String = String(presenter.call(
		"build_node_family_display_name",
		run_state.map_runtime_state.get_current_node_family()
	))
	var reward_family_name: String = String(presenter.call("build_node_family_display_name", "reward"))
	var start_family_name: String = String(presenter.call("build_node_family_display_name", "start"))

	assert(
		presenter.call("build_title_text", run_state) == "Stage 2",
		"Expected map presenter title to reflect the current stage."
	)
	assert(
		presenter.call("build_stage_badge_text", run_state) == "II",
		"Expected the map presenter stage badge read to expose a compact Roman numeral for the top-shell medallion."
	)
	assert(
		String(presenter.call("build_progress_text", run_state)).contains("Hunger -1 11->10"),
		"Expected map presenter progress text to foreground next-move hunger pressure."
	)
	assert(
		String(presenter.call("build_progress_text", run_state)).contains("routes"),
		"Expected map presenter progress text to foreground reachable roads."
	)
	var run_status_model: Dictionary = presenter.call("build_run_status_model", run_state)
	var primary_status_items: Array = run_status_model.get("primary_items", [])
	var secondary_status_items: Array = run_status_model.get("secondary_items", [])
	var progress_status_items: Array = run_status_model.get("progress_items", [])
	assert(
		primary_status_items.size() == 4,
		"Expected the map HUD status model to expose the four primary attrition metrics."
	)
	assert(
		secondary_status_items.is_empty(),
		"Expected the map HUD status model to keep the compact strip focused on primary attrition only."
	)
	assert(
		progress_status_items.size() == 1,
		"Expected the map HUD status model to keep a compact XP progress read in the top-row strip."
	)
	assert(
		String(run_status_model.get("fallback_text", "")) == "HP 48 | Hunger 11 | Gold 17 | Durability 9",
		"Expected map presenter to keep the compact fallback string inside the shared run-status model."
	)
	assert(
		String((primary_status_items[0] as Dictionary).get("value_text", "")) == "48/60",
		"Expected the map HUD status model to expose HP through the structured chip values."
	)
	assert(
		String((primary_status_items[1] as Dictionary).get("value_text", "")) == "11/20",
		"Expected the map HUD status model to expose hunger through the structured chip values."
	)
	assert(
		String((primary_status_items[3] as Dictionary).get("value_text", "")) == "9",
		"Expected the map HUD status model to expose durability through the structured chip values."
	)
	var cluster_read_text: String = String(presenter.call("build_cluster_read_text", run_state))
	assert(
		cluster_read_text.contains("Ahead:"),
		"Expected the map presenter to summarize discovered pockets beyond the immediate adjacent shell."
	)
	var ahead_payload: String = cluster_read_text.split("Ahead:", false, 1)[1].strip_edges()
	if ahead_payload.contains("|"):
		ahead_payload = ahead_payload.split("|", false, 1)[0].strip_edges()
	assert(
		not ahead_payload.is_empty(),
		"Expected the map presenter to keep a non-empty discovered-destination summary beyond the immediate adjacent shell after local-connectivity tightening."
	)
	assert(
		presenter.call("build_current_anchor_text", run_state) == "At %s" % current_family_name,
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
	var route_overview_text: String = String(presenter.call("build_route_overview_text", run_state))
	assert(
		route_overview_text.contains("Hunger -1: 11->10"),
		"Expected the top route overview to foreground movement hunger pressure from runtime-owned run state."
	)
	assert(
		route_overview_text.contains("Routes:"),
		"Expected the top route overview to summarize immediate runtime-owned route choices."
	)
	assert(
		route_overview_text.contains("Key"),
		"Expected the top route overview to surface key/boss commitment without relying on the bottom status log."
	)
	var initial_run_state: RunState = RunState.new()
	initial_run_state.reset_for_new_run()
	initial_run_state.configure_run_seed(1)
	var opening_route_overview: String = String(presenter.call("build_route_overview_text", initial_run_state))
	assert(
		opening_route_overview.contains("Hunger -1: 20->19"),
		"Expected the top route overview to surface the next movement hunger cost before route commitment."
	)
	assert(
		opening_route_overview.contains("Routes:"),
		"Expected the top route overview to summarize immediate runtime-owned route choices."
	)
	assert(
		opening_route_overview.contains("Prep detour:"),
		"Expected the top route overview to call out the opening support/prep detour when the runtime graph exposes one."
	)
	run_state.hunger = 1
	run_state.player_hp = 7
	var starvation_route_overview: String = String(presenter.call("build_route_overview_text", run_state))
	assert(
		starvation_route_overview.contains("Hunger -1: 1->0, HP 7->6"),
		"Expected the top route overview to preview starvation HP pressure when the next map move would empty hunger."
	)
	assert(
		String(presenter.call("build_inventory_pressure_text", run_state)).contains("Carry"),
		"Expected the map inventory pressure read to foreground carried-slot pressure."
	)
	assert(
		String(presenter.call("build_inventory_pressure_text", run_state)).contains("Iron Sword"),
		"Expected the map inventory pressure read to include the active weapon summary."
	)
	assert(
		presenter.call("build_node_family_display_name", "boss") == "Warden",
		"Expected node-family display names to stay presenter-owned for the route board."
	)
	assert(
		presenter.call("build_node_family_display_name", "reward") == "Cache",
		"Expected reward routes to expose the current authored cache label."
	)
	assert(
		presenter.call("build_node_family_display_name", "event") == "Trail Event",
		"Expected planned event routes to expose the dedicated trail-event label instead of the roadside interruption label."
	)
	assert(
		presenter.call("build_node_family_display_name", "event") != "Roadside Encounter",
		"Expected the roadside interruption label to stay reserved for travel-triggered encounters rather than planned map nodes."
	)
	assert(
		presenter.call("build_node_family_display_name", "hamlet") == "Waypost",
		"Expected hamlet routes to expose the canonical settlement label."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "combat") == "res://Assets/Icons/icon_map_combat.svg",
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
		presenter.call("build_route_icon_texture_path", "event") == "res://Assets/Icons/icon_map_trail_event.svg",
		"Expected event routes to resolve to the dedicated Trail Event icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "hamlet") == "res://Assets/Icons/icon_map_side_mission.svg",
		"Expected hamlet routes to use the dedicated settlement-contract icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "key") == "res://Assets/Icons/icon_map_key.svg",
		"Expected key routes to use the dedicated key marker icon treatment."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "boss") == "res://Assets/Icons/icon_map_boss.svg",
		"Expected boss routes to use the dedicated boss marker icon treatment."
	)
	var route_models: Array[Dictionary] = presenter.call("build_route_view_models", run_state, 6)
	var visible_route_models: Array[Dictionary] = []
	for route_model in route_models:
		if bool(route_model.get("visible", false)):
			visible_route_models.append(route_model)

	assert(
		String(route_models[0].get("text", "")).ends_with("\nOpen Route"),
		"Expected unresolved adjacent routes to sort ahead of revisit-only traversal nodes."
	)
	assert(
		String(route_models[0].get("icon_texture_path", "")) == presenter.call(
			"build_route_icon_texture_path",
			String(route_models[0].get("node_family", ""))
		),
		"Expected route view models to expose the presenter-owned route icon texture path."
	)
	assert(
		String(route_models[0].get("state_chip_text", "")) == "OPEN",
		"Expected route view models to expose compact state-chip text for the shell overlay."
	)
	var spent_start_found: bool = false
	for route_model in visible_route_models:
		if String(route_model.get("text", "")) != "%s\nBacktrack" % start_family_name:
			continue
		spent_start_found = true
		assert(
			String(route_model.get("state_chip_text", "")) == "CLEAR",
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

	var side_mission_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	var target_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "combat")
	assert(side_mission_node_id >= 0, "Expected one hamlet node in the runtime-owned map.")
	assert(target_node_id >= 0, "Expected at least one combat node for target-readability coverage.")
	run_state.map_runtime_state.save_side_mission_node_runtime_state(side_mission_node_id, {
		"support_type": "hamlet",
		"mission_definition_id": "trail_contract_hunt",
		"mission_status": "accepted",
		"target_node_id": target_node_id,
		"target_enemy_definition_id": "barbed_hunter",
		"reward_offers": [],
	})
	assert(
		String(presenter.call("build_current_anchor_detail_text", run_state)).contains("Marked target"),
		"Expected current-anchor detail text to surface accepted hamlet-request target readability."
	)
	run_state.map_runtime_state.save_side_mission_node_runtime_state(side_mission_node_id, {
		"support_type": "hamlet",
		"mission_definition_id": "trail_contract_hunt",
		"mission_status": "completed",
		"target_node_id": target_node_id,
		"target_enemy_definition_id": "barbed_hunter",
		"reward_offers": [],
	})
	assert(
		String(presenter.call("build_current_anchor_detail_text", run_state)).contains("Return marked"),
		"Expected current-anchor detail text to surface completed hamlet-request return readability."
	)
	var reward_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "reward")
	assert(reward_node_id >= 0, "Expected one reward node for focus-panel readability coverage.")
	var current_focus_model: Dictionary = presenter.call("build_focus_panel_model", run_state)
	assert(
		String(current_focus_model.get("title_text", "")).contains("Current Stop"),
		"Expected the focus panel to default to the current pocket when no hovered route is provided."
	)
	assert(
		String(current_focus_model.get("detail_text", "")).contains("Node 1"),
		"Expected the current focus panel detail to surface the current node id."
	)
	var reward_focus_model: Dictionary = presenter.call("build_focus_panel_model", run_state, reward_node_id)
	assert(
		String(reward_focus_model.get("title_text", "")).contains(reward_family_name),
		"Expected a focused route panel to surface the route family display name."
	)
	assert(
		String(reward_focus_model.get("hint_text", "")).contains("pickup"),
		"Expected reward focus panels to expose practical route intent rather than flavor-only copy."
	)


func _find_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == node_family:
			return int(node_snapshot.get("node_id", -1))
	return -1


func test_map_scene_prefers_composer_world_positions() -> void:
	var scene: Control = MapExploreSceneScript.new()
	scene.set("_board_composition_cache", {
		"world_positions": {
			7: Vector2(420.0, 360.0),
		},
	})
	scene.set("_route_layout_offset", Vector2(18.0, -12.0))
	var marker_position: Vector2 = scene.call(
		"_marker_position_for_route_model",
		{"node_id": 7},
		1,
		{},
		Vector2(1080.0, 1920.0)
	)
	var expected_position := Vector2(420.0, 360.0) + Vector2(18.0, -12.0) - Vector2(72.0, 72.0)
	assert(
		marker_position.distance_to(expected_position) <= 0.001,
		"Expected route markers to prefer composer world positions over legacy slot safety placement."
	)
	_free_control(scene)


func test_map_scene_keeps_emergency_route_slot_fallback_narrow() -> void:
	var scene: Control = MapExploreSceneScript.new()
	scene.set("_route_layout_offset", Vector2(24.0, 10.0))
	var emergency_marker_position: Vector2 = scene.call(
		"_marker_position_for_route_model",
		{"node_id": 99},
		0,
		{0: Vector2(0.25, 0.40)},
		Vector2(1080.0, 1920.0)
	)
	var expected_emergency_position := (Vector2(1080.0, 1920.0) * Vector2(0.25, 0.40)) - Vector2(72.0, 72.0) + Vector2(24.0, 10.0)
	assert(
		emergency_marker_position.distance_to(expected_emergency_position) <= 0.001,
		"Expected legacy slot placement to remain only as the narrow emergency safety fallback when composer positions are missing."
	)
	_free_control(scene)


func test_map_scene_only_assigns_emergency_slots_to_missing_world_positions() -> void:
	var scene: Control = MapExploreSceneScript.new()
	scene.set("_route_layout_offset", Vector2(24.0, 10.0))
	var route_models: Array[Dictionary] = [
		{"node_id": 1},
		{"node_id": 2},
		{"node_id": 3},
	]
	scene.set("_route_models_cache", route_models)
	scene.set("_board_composition_cache", {
		"world_positions": {
			1: Vector2(420.0, 360.0),
			3: Vector2(720.0, 500.0),
		},
	})

	var factor_map: Dictionary = scene.call("_build_emergency_route_slot_factor_map", [0, 1, 2] as Array[int])
	assert(
		factor_map.size() == 1,
		"Expected emergency route-slot fallback assignment to stay limited to the visible route entries that are actually missing composer world positions."
	)

	var missing_marker_position: Vector2 = scene.call(
		"_marker_position_for_route_model",
		{"node_id": 2},
		1,
		factor_map,
		Vector2(1080.0, 1920.0)
	)
	var expected_missing_position := (Vector2(1080.0, 1920.0) * Vector2(0.50, 0.24)) - Vector2(72.0, 72.0) + Vector2(24.0, 10.0)
	assert(
		missing_marker_position.distance_to(expected_missing_position) <= 0.001,
		"Expected a lone missing composer position to use the single-slot emergency forward marker instead of inheriting a wider fixed-slot lattice."
	)

	var composed_marker_position: Vector2 = scene.call(
		"_marker_position_for_route_model",
		{"node_id": 1},
		0,
		factor_map,
		Vector2(1080.0, 1920.0)
	)
	var expected_composed_position := Vector2(420.0, 360.0) + Vector2(24.0, 10.0) - Vector2(72.0, 72.0)
	assert(
		composed_marker_position.distance_to(expected_composed_position) <= 0.001,
		"Expected routes with composer world positions to keep their composed placement even when a neighboring visible route needs emergency fallback."
	)
	_free_control(scene)


func test_map_scene_builds_route_move_path_from_render_model_surface_geometry() -> void:
	var scene: Control = MapExploreSceneScript.new()
	scene.set("_board_composition_cache", {
		"current_node_id": 3,
		"world_positions": {
			3: Vector2(128.0, 244.0),
			5: Vector2(302.0, 388.0),
		},
		"visible_edges": [
			{
				"from_node_id": 3,
				"to_node_id": 5,
				"points": PackedVector2Array([
					Vector2(154.0, 262.0),
					Vector2(210.0, 302.0),
					Vector2(264.0, 350.0),
				]),
			},
		],
		"render_model": {
			"schema_version": 1,
			"path_surfaces": [
				{
					"from_node_id": 3,
					"to_node_id": 5,
					"centerline_points": PackedVector2Array([
						Vector2(162.0, 270.0),
						Vector2(214.0, 306.0),
						Vector2(258.0, 344.0),
					]),
					"from_endpoint": Vector2(162.0, 270.0),
					"to_endpoint": Vector2(258.0, 344.0),
				},
			],
		},
	})
	var route_points: PackedVector2Array = scene.call(
		"_build_route_move_world_path",
		3,
		5,
		Vector2.ZERO,
		Vector2.ZERO
	)
	assert(route_points.size() == 3, "Expected route travel to use the render_model path-surface centerline instead of adding node-center endpoints.")
	assert(route_points[0].distance_to(Vector2(162.0, 270.0)) <= 0.001, "Expected route travel to depart from the render_model clearing throat.")
	assert(route_points[1].distance_to(Vector2(214.0, 306.0)) <= 0.001, "Expected route travel to preserve the selected render_model path surface centerline.")
	assert(route_points[route_points.size() - 1].distance_to(Vector2(258.0, 344.0)) <= 0.001, "Expected route travel to arrive through the render_model clearing throat.")
	assert(route_points[0].distance_to(Vector2(128.0, 244.0)) > 8.0, "Expected route travel not to collapse back onto the source node center when a render_model path surface exists.")
	_free_control(scene)


func test_map_route_motion_helper_falls_back_to_visible_edge_geometry_without_render_model() -> void:
	var route_points: PackedVector2Array = MapRouteMotionHelperScript.build_route_move_world_path(
		{
			"world_positions": {
				3: Vector2(128.0, 244.0),
				5: Vector2(302.0, 388.0),
			},
			"visible_edges": [
				{
					"from_node_id": 3,
					"to_node_id": 5,
					"points": PackedVector2Array([
						Vector2(154.0, 262.0),
						Vector2(210.0, 302.0),
						Vector2(264.0, 350.0),
					]),
				},
			],
		},
		3,
		5,
		Vector2.ZERO,
		Vector2.ZERO
	)
	assert(route_points.size() == 5, "Expected legacy visible_edges to remain the fallback route-motion source when no render_model path surface exists.")
	assert(route_points[0].distance_to(Vector2(128.0, 244.0)) <= 0.001, "Expected fallback route travel to keep source node world position coverage.")
	assert(route_points[1].distance_to(Vector2(154.0, 262.0)) <= 0.001, "Expected fallback route travel to keep legacy visible edge points.")
	assert(route_points[route_points.size() - 1].distance_to(Vector2(302.0, 388.0)) <= 0.001, "Expected fallback route travel to keep target node world position coverage.")


func test_map_scene_builds_pending_roadside_visual_sample_from_render_model_surface_geometry() -> void:
	var scene: Control = MapExploreSceneScript.new()
	scene.set("_board_composition_cache", {
		"current_node_id": 0,
		"world_positions": {
			0: Vector2(180.0, 520.0),
			4: Vector2(520.0, 220.0),
		},
		"visible_edges": [
			{
				"from_node_id": 0,
				"to_node_id": 4,
				"points": PackedVector2Array([
					Vector2(248.0, 470.0),
					Vector2(324.0, 392.0),
					Vector2(416.0, 302.0),
				]),
			},
		],
		"render_model": {
			"schema_version": 1,
			"path_surfaces": [
				{
					"from_node_id": 0,
					"to_node_id": 4,
					"centerline_points": PackedVector2Array([
						Vector2(258.0, 462.0),
						Vector2(334.0, 384.0),
						Vector2(426.0, 294.0),
					]),
					"from_endpoint": Vector2(258.0, 462.0),
					"to_endpoint": Vector2(426.0, 294.0),
				},
			],
		},
	})
	scene.set("_route_layout_offset", Vector2.ZERO)
	scene.call("_prime_roadside_visual_state", 0, 4)
	var sample: Dictionary = scene.call("_build_pending_roadside_visual_sample")
	var sample_point: Vector2 = sample.get("point", Vector2.ZERO)
	assert(not sample.is_empty(), "Expected roadside interruption visuals to sample a mid-route point from the composed edge geometry.")
	assert(
		sample_point.distance_to(Vector2(180.0, 520.0)) > 32.0 and sample_point.distance_to(Vector2(520.0, 220.0)) > 32.0,
		"Expected roadside interruption visuals not to collapse back onto the source node or jump all the way to the destination node."
	)
	assert(
		sample_point.distance_to(Vector2(334.0, 384.0)) < sample_point.distance_to(Vector2(324.0, 392.0)),
		"Expected roadside interruption visuals to sample the render_model path-surface lane before legacy visible_edges."
	)
	_free_control(scene)


func test_map_scene_accepts_deferred_roadside_transition_for_destination_restore() -> void:
	var scene: Control = MapExploreSceneScript.new()
	scene.set("_roadside_visual_state", {
		"current_node_id": 0,
		"target_node_id": 4,
		"progress": 0.58,
		"offset": Vector2.ZERO,
		"target_offset": Vector2(42.0, -18.0),
	})
	var accepted: bool = bool(scene.call(
		"begin_deferred_scene_transition",
		FlowStateScript.Type.REWARD,
		FlowStateScript.Type.EVENT
	))
	assert(
		accepted,
		"Expected roadside destination restores to defer the reward/combat route until the remaining path animation finishes."
	)
	assert(
		bool(scene.get("_roadside_transition_in_flight")),
		"Expected deferred roadside destination restores to flag the in-flight continuation beat."
	)
	_free_control(scene)


func test_map_scene_reports_zero_fixed_board_offset_for_focus_requests() -> void:
	var scene: Control = MapExploreSceneScript.new()
	var margin := MarginContainer.new()
	margin.name = "Margin"
	scene.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	var route_grid := Control.new()
	route_grid.name = "RouteGrid"
	route_grid.custom_minimum_size = Vector2(1080.0, 1920.0)
	route_grid.size = Vector2(1080.0, 1920.0)
	vbox.add_child(route_grid)
	scene.set("_route_layout_offset", Vector2(42.0, -18.0))
	var centered_offset: Vector2 = scene.call("_desired_focus_offset_for_world_position", Vector2(540.0, 960.0))
	assert(
		centered_offset == Vector2.ZERO,
		"Expected the fixed-board model to keep the board offset at zero for centered current-node requests."
	)
	var edge_offset: Vector2 = scene.call("_desired_focus_offset_for_world_position", Vector2(140.0, 180.0))
	assert(
		edge_offset == Vector2.ZERO,
		"Expected the fixed-board model not to recenter the board even for edge-biased node positions."
	)
	_free_control(scene)


func test_map_route_binding_keeps_fixed_board_offset_after_refresh() -> void:
	var owner := Control.new()
	var margin := MarginContainer.new()
	margin.name = "Margin"
	owner.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	var route_grid := Control.new()
	route_grid.name = "RouteGrid"
	route_grid.size = Vector2(1052.0, 1008.0)
	route_grid.custom_minimum_size = route_grid.size
	vbox.add_child(route_grid)
	var route_binding: RefCounted = MapRouteBindingScript.new()
	route_binding.call("configure", owner, Callable(owner, "get_node_or_null"), MapBoardComposerV2Script.new())
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(7)
	route_binding.set("_route_layout_offset", Vector2(84.0, -46.0))
	route_binding.call("prepare_for_refresh", run_state)
	assert(
		route_binding.get("_route_layout_offset") == Vector2.ZERO,
		"Expected board refresh to reset route-layout offset back to the fixed-board zero point."
	)
	var next_node_id: int = int(run_state.map_runtime_state.get_adjacent_node_ids()[0])
	run_state.map_runtime_state.move_to_node(next_node_id)
	route_binding.call("prepare_for_refresh", run_state)
	assert(
		route_binding.get("_route_layout_offset") == Vector2.ZERO,
		"Expected route refresh after movement to keep the board fixed instead of recentering around the new current node."
	)
	_free_control(owner)


func test_map_scene_keeps_roadside_visual_offset_fixed() -> void:
	var scene: Control = MapExploreSceneScript.new()
	scene.set("_board_composition_cache", {
		"current_node_id": 0,
		"world_positions": {
			0: Vector2(180.0, 520.0),
			4: Vector2(520.0, 220.0),
		},
		"visible_edges": [
			{
				"from_node_id": 0,
				"to_node_id": 4,
				"points": PackedVector2Array([
					Vector2(248.0, 470.0),
					Vector2(324.0, 392.0),
					Vector2(416.0, 302.0),
				]),
			},
		],
	})
	scene.set("_route_layout_offset", Vector2(30.0, -14.0))
	scene.call("_prime_roadside_visual_state", 0, 4)
	var roadside_visual_state: Dictionary = scene.get("_roadside_visual_state")
	assert(
		Vector2(roadside_visual_state.get("offset", Vector2.ONE)) == Vector2.ZERO,
		"Expected roadside interruption previews to keep the board offset fixed instead of carrying a recenter preview offset."
	)
	assert(
		Vector2(roadside_visual_state.get("target_offset", Vector2.ONE)) == Vector2.ZERO,
		"Expected roadside interruption previews to keep the target board offset fixed in the fixed-board model."
	)
	var sample: Dictionary = scene.call("_build_pending_roadside_visual_sample")
	assert(Vector2(sample.get("offset", Vector2.ONE)) == Vector2.ZERO, "Expected pending roadside visual samples to keep a zero board offset during the interrupted route beat.")
	_free_control(scene)


func test_map_route_binding_places_idle_walker_below_current_node_center() -> void:
	var owner := Control.new()
	var margin := MarginContainer.new()
	margin.name = "Margin"
	owner.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	var route_grid := Control.new()
	route_grid.name = "RouteGrid"
	route_grid.size = Vector2(1052.0, 1008.0)
	route_grid.custom_minimum_size = route_grid.size
	vbox.add_child(route_grid)
	var route_binding: RefCounted = MapRouteBindingScript.new()
	route_binding.call("configure", owner, Callable(owner, "get_node_or_null"), MapBoardComposerV2Script.new())
	route_binding.call("ensure_runtime_board_nodes")
	var current_marker: TextureRect = route_binding.get("_current_marker") as TextureRect
	var walker_root: Control = route_binding.get("_walker_root") as Control
	var walker_sprite: TextureRect = route_binding.get("_walker_sprite") as TextureRect
	assert(current_marker != null and walker_root != null and walker_sprite != null, "Expected runtime board nodes before idle walker placement coverage.")
	current_marker.visible = true
	current_marker.size = MapRouteBindingScript.CURRENT_MARKER_SIZE
	current_marker.position = Vector2(420.0, 340.0)
	route_binding.call("_sync_walker_to_current_marker")
	var current_center: Vector2 = current_marker.position + current_marker.size * 0.5
	var walker_sprite_bottom: float = walker_root.position.y + walker_sprite.position.y + walker_sprite.size.y
	assert(bool(walker_root.visible), "Expected idle walker placement to keep the walker visible on the fixed board.")
	assert(
		walker_sprite_bottom >= current_center.y + 18.0,
		"Expected idle walker placement to sit on the lower rim of the current clearing instead of covering the center icon."
	)
	_free_control(owner)


func test_map_route_binding_keeps_hover_preview_marker_weaker_than_active_selection() -> void:
	var owner := Control.new()
	var margin := MarginContainer.new()
	margin.name = "Margin"
	owner.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	var route_grid := Control.new()
	route_grid.name = "RouteGrid"
	route_grid.size = Vector2(1052.0, 1008.0)
	route_grid.custom_minimum_size = route_grid.size
	vbox.add_child(route_grid)
	var selected_marker := TextureRect.new()
	selected_marker.name = String(MapRouteBindingScript.ROUTE_MARKER_NODE_NAMES[0])
	route_grid.add_child(selected_marker)
	var preview_marker := TextureRect.new()
	preview_marker.name = String(MapRouteBindingScript.ROUTE_MARKER_NODE_NAMES[1])
	route_grid.add_child(preview_marker)
	var route_binding: RefCounted = MapRouteBindingScript.new()
	route_binding.call("configure", owner, Callable(owner, "get_node_or_null"), MapBoardComposerV2Script.new())
	route_binding.call("ensure_runtime_board_nodes")
	var route_models: Array[Dictionary] = [
		{
			"visible": true,
			"icon_texture_path": "res://Assets/Icons/icon_map_combat.svg",
			"node_family": "combat",
			"family_label": "Skirmish",
			"state_chip_text": "OPEN",
			"state_semantic": "open",
			"disabled": false,
			"node_id": 1,
		},
		{
			"visible": true,
			"icon_texture_path": "res://Assets/Icons/icon_reward.svg",
			"node_family": "reward",
			"family_label": "Cache",
			"state_chip_text": "OPEN",
			"state_semantic": "open",
			"disabled": false,
			"node_id": 2,
		},
	]
	route_binding.call("set_route_models", route_models)
	route_binding.set("_active_route_index", 0)
	route_binding.set("_hovered_route_index", 1)
	route_binding.call("_refresh_route_visual_state")

	assert(selected_marker != null and preview_marker != null, "Expected runtime route markers before marker focus-state coverage.")
	var selected_ring: PanelContainer = selected_marker.get_node_or_null("SelectionRing") as PanelContainer
	var preview_ring: PanelContainer = preview_marker.get_node_or_null("SelectionRing") as PanelContainer
	var selected_chip: PanelContainer = selected_marker.get_node_or_null("StateChip") as PanelContainer
	var preview_chip: PanelContainer = preview_marker.get_node_or_null("StateChip") as PanelContainer
	var selected_label: Label = selected_chip.get_node_or_null("StateChipLabel") as Label if selected_chip != null else null
	var preview_label: Label = preview_chip.get_node_or_null("StateChipLabel") as Label if preview_chip != null else null
	assert(selected_ring != null and preview_ring != null, "Expected route markers to keep dedicated selection rings for focus-state coverage.")
	assert(bool(selected_ring.visible) and bool(preview_ring.visible), "Expected both selected and preview markers to surface their focus rings.")
	assert(
		selected_ring.modulate.a > preview_ring.modulate.a,
		"Expected hover preview focus to stay visibly weaker than the committed route selection ring."
	)
	var selected_ring_style: StyleBoxFlat = selected_ring.get_theme_stylebox("panel") as StyleBoxFlat
	var preview_ring_style: StyleBoxFlat = preview_ring.get_theme_stylebox("panel") as StyleBoxFlat
	assert(selected_ring_style != null and preview_ring_style != null, "Expected route markers to expose style overrides for focus-ring hierarchy.")
	assert(
		selected_ring_style.border_width_left > preview_ring_style.border_width_left and selected_ring_style.shadow_size > preview_ring_style.shadow_size,
		"Expected the active route marker to keep a stronger ring border and shadow than a hover preview."
	)
	assert(
		selected_chip != null and bool(selected_chip.visible) and selected_label != null and selected_label.text == "Skirmish",
		"Expected only the active route marker to expose the family pill label."
	)
	assert(
		preview_chip != null and not bool(preview_chip.visible) and preview_label != null and preview_label.text.is_empty(),
		"Expected hover preview markers not to claim the active-route pill treatment."
	)
	_free_control(owner)


func test_map_route_binding_leans_idle_walker_toward_focused_route_lane() -> void:
	var owner := Control.new()
	var margin := MarginContainer.new()
	margin.name = "Margin"
	owner.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	var route_grid := Control.new()
	route_grid.name = "RouteGrid"
	route_grid.size = Vector2(1052.0, 1008.0)
	route_grid.custom_minimum_size = route_grid.size
	vbox.add_child(route_grid)
	var route_binding: RefCounted = MapRouteBindingScript.new()
	route_binding.call("configure", owner, Callable(owner, "get_node_or_null"), MapBoardComposerV2Script.new())
	route_binding.call("ensure_runtime_board_nodes")
	var current_marker: TextureRect = route_binding.get("_current_marker") as TextureRect
	var walker_root: Control = route_binding.get("_walker_root") as Control
	var walker_sprite: TextureRect = route_binding.get("_walker_sprite") as TextureRect
	assert(current_marker != null and walker_root != null and walker_sprite != null, "Expected runtime board nodes before walker focus-lane coverage.")
	current_marker.visible = true
	current_marker.size = MapRouteBindingScript.CURRENT_MARKER_SIZE
	current_marker.position = Vector2(420.0, 340.0)
	var current_center: Vector2 = current_marker.position + current_marker.size * 0.5
	var route_models: Array[Dictionary] = [
		{
			"visible": true,
			"icon_texture_path": "res://Assets/Icons/icon_map_combat.svg",
			"node_family": "combat",
			"family_label": "Skirmish",
			"state_chip_text": "OPEN",
			"state_semantic": "open",
			"disabled": false,
			"node_id": 7,
		},
	]
	route_binding.call("set_route_models", route_models)

	route_binding.set("_active_route_index", -1)
	route_binding.set("_hovered_route_index", -1)
	route_binding.call("_sync_walker_to_current_marker")
	var neutral_position: Vector2 = walker_root.position

	route_binding.set("_board_composition_cache", {
		"world_positions": {
			7: current_center + Vector2(160.0, -24.0),
		},
	})
	route_binding.set("_active_route_index", 0)
	route_binding.call("_sync_walker_to_current_marker")
	var right_focus_position: Vector2 = walker_root.position
	assert(
		right_focus_position.x > neutral_position.x + 4.0,
		"Expected the idle walker to lean toward the committed route lane instead of staying perfectly centered on the clearing."
	)
	assert(
		walker_sprite.scale.x > 0.0,
		"Expected the idle walker to face toward a right-side focused route lane."
	)

	route_binding.set("_board_composition_cache", {
		"world_positions": {
			7: current_center + Vector2(-160.0, -24.0),
		},
	})
	route_binding.call("_sync_walker_to_current_marker")
	var left_focus_position: Vector2 = walker_root.position
	assert(
		left_focus_position.x < neutral_position.x - 4.0,
		"Expected the idle walker to lean toward a left-side focused route lane instead of drifting generically."
	)
	assert(
		walker_sprite.scale.x < 0.0,
		"Expected the idle walker to face toward a left-side focused route lane."
	)
	_free_control(owner)


func test_map_route_motion_helper_emits_grounded_stride_sway() -> void:
	var start_offset: Vector2 = MapRouteMotionHelperScript.walker_stride_offset(0.0, 320.0, 2.25, 6.0)
	var mid_offset: Vector2 = MapRouteMotionHelperScript.walker_stride_offset(0.33, 320.0, 2.25, 6.0)
	var end_offset: Vector2 = MapRouteMotionHelperScript.walker_stride_offset(1.0, 320.0, 2.25, 6.0)
	assert(start_offset.length() <= 0.001 and end_offset.length() <= 0.001, "Expected walker stride offsets to settle back to zero at route endpoints.")
	assert(mid_offset.y < -0.1, "Expected walker stride sampling to keep a lifted foot bob during in-flight board motion.")
	assert(absf(mid_offset.x) >= 0.5, "Expected walker stride sampling to add a small lateral sway so route motion does not read as a pure vertical bob.")


func test_map_route_binding_recomposes_board_positions_after_route_grid_resize() -> void:
	var owner := Control.new()
	var margin := MarginContainer.new()
	margin.name = "Margin"
	owner.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	var route_grid := Control.new()
	route_grid.name = "RouteGrid"
	route_grid.size = Vector2(1052.0, 680.0)
	route_grid.custom_minimum_size = route_grid.size
	vbox.add_child(route_grid)
	var route_binding: RefCounted = MapRouteBindingScript.new()
	route_binding.call("configure", owner, Callable(owner, "get_node_or_null"), MapBoardComposerV2Script.new())
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(1)
	var opening_target_id: int = int(run_state.map_runtime_state.get_adjacent_node_ids()[0])
	run_state.map_runtime_state.move_to_node(opening_target_id)
	run_state.map_runtime_state.mark_node_resolved(opening_target_id)
	var branch_target_id: int = -1
	for adjacent_node_id in run_state.map_runtime_state.get_adjacent_node_ids():
		if int(adjacent_node_id) == 0:
			continue
		branch_target_id = int(adjacent_node_id)
		break
	assert(branch_target_id >= 0, "Expected a deeper branch node for resize-stability coverage.")
	run_state.map_runtime_state.move_to_node(branch_target_id)
	run_state.map_runtime_state.mark_node_resolved(branch_target_id)
	route_binding.call("prepare_for_refresh", run_state)
	var opening_world_positions: Dictionary = route_binding.get("_board_composition_cache").get("world_positions", {})
	var opening_visible_edges: Array = (route_binding.get("_board_composition_cache").get("visible_edges", []) as Array).duplicate(true)
	var opening_position: Vector2 = opening_world_positions.get(0, Vector2.ZERO)
	route_grid.size = Vector2(1052.0, 1322.0)
	route_binding.call("refresh_layout_for_resize", run_state)
	var resized_world_positions: Dictionary = route_binding.get("_board_composition_cache").get("world_positions", {})
	var resized_visible_edges: Array = (route_binding.get("_board_composition_cache").get("visible_edges", []) as Array).duplicate(true)
	var resized_position: Vector2 = resized_world_positions.get(0, Vector2.ZERO)
	var resized_playable_rect: Rect2 = MapBoardComposerV2Script.build_playable_rect(route_grid.size)
	var center_local_x: float = resized_playable_rect.position.x + resized_playable_rect.size.x * 0.5
	var lower_center_floor_y: float = resized_playable_rect.position.y + resized_playable_rect.size.y * 0.55
	var lower_center_ceiling_y: float = resized_playable_rect.position.y + resized_playable_rect.size.y * 0.78
	assert(
		resized_position.y > opening_position.y + 200.0,
		"Expected route-grid resize to recompose board positions against the larger map height instead of keeping the startup-sized opening anchor."
	)
	assert(
		absf(resized_position.x - center_local_x) <= resized_playable_rect.size.x * 0.08,
		"Expected the recomposed start anchor to stay center-local after the route grid expands."
	)
	assert(
		resized_position.y >= lower_center_floor_y and resized_position.y <= lower_center_ceiling_y,
		"Expected the recomposed start anchor to stay inside the locked lower-center / lower-third slot-anchor band after the route grid expands."
	)
	assert(not resized_visible_edges.is_empty(), "Expected the expanded route grid recompose to keep visible roads cached.")
	route_grid.size = Vector2(1052.0, 1008.0)
	route_binding.call("refresh_layout_for_resize", run_state)
	var shrunk_world_positions: Dictionary = route_binding.get("_board_composition_cache").get("world_positions", {})
	var shrunk_visible_edges: Array = (route_binding.get("_board_composition_cache").get("visible_edges", []) as Array).duplicate(true)
	var shrunk_position: Vector2 = shrunk_world_positions.get(0, Vector2.ZERO)
	assert(
		shrunk_position.distance_to(resized_position) <= 0.001,
		"Expected internal route-grid shrink from inventory growth to preserve the settled board anchor instead of recomposing known routes."
	)
	assert(
		JSON.stringify(shrunk_visible_edges) == JSON.stringify(resized_visible_edges),
		"Expected internal route-grid shrink to keep discovered visible roads stable instead of dropping previously known history edges."
	)
	_free_control(owner)


func test_map_route_binding_refreshes_cached_node_radii_after_moderate_resize() -> void:
	var owner := Control.new()
	var margin := MarginContainer.new()
	margin.name = "Margin"
	owner.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	var route_grid := Control.new()
	route_grid.name = "RouteGrid"
	route_grid.size = Vector2(1052.0, 1008.0)
	route_grid.custom_minimum_size = route_grid.size
	vbox.add_child(route_grid)
	var route_binding: RefCounted = MapRouteBindingScript.new()
	route_binding.call("configure", owner, Callable(owner, "get_node_or_null"), MapBoardComposerV2Script.new())
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(1)
	route_binding.call("prepare_for_refresh", run_state)
	var opening_visible_nodes: Array = (route_binding.get("_board_composition_cache").get("visible_nodes", []) as Array).duplicate(true)
	var opening_world_positions: Dictionary = route_binding.get("_board_composition_cache").get("world_positions", {})
	assert(not opening_visible_nodes.is_empty(), "Expected visible nodes before moderate route-grid resize coverage.")
	var opening_radius: float = _visible_node_radius_by_id(opening_visible_nodes, int(run_state.map_runtime_state.current_node_id))
	assert(opening_radius > 0.0, "Expected the current visible node to expose a clearing radius before resize.")

	route_grid.size = Vector2(1052.0, 1188.0)
	route_binding.call("refresh_layout_for_resize", run_state)
	var resized_visible_nodes: Array = (route_binding.get("_board_composition_cache").get("visible_nodes", []) as Array).duplicate(true)
	var resized_world_positions: Dictionary = route_binding.get("_board_composition_cache").get("world_positions", {})
	var resized_radius: float = _visible_node_radius_by_id(resized_visible_nodes, int(run_state.map_runtime_state.current_node_id))
	assert(
		resized_world_positions == opening_world_positions,
		"Expected moderate route-grid resize to keep stable world positions instead of forcing a full board re-layout."
	)
	assert(
		resized_radius > opening_radius,
		"Expected moderate route-grid resize to refresh cached clearing radii so node clearings grow with the larger board height."
	)
	_free_control(owner)


func test_map_scene_queues_recompose_when_route_grid_resizes_during_refresh() -> void:
	var map_scene: Control = MapExplorePackedScene.instantiate() as Control
	assert(map_scene != null, "Expected map scene instance for in-refresh route-grid resize coverage.")
	get_root().add_child(map_scene)
	await process_frame
	var route_binding: RefCounted = map_scene.get("_route_binding")
	assert(route_binding != null, "Expected route binding for in-refresh route-grid resize coverage.")
	map_scene.set("_is_refreshing_ui", true)
	map_scene.call("_on_route_grid_resized")
	assert(bool(map_scene.get("_refresh_ui_pending")), "Expected route-grid resize during refresh to queue a follow-up UI refresh.")
	assert(bool(route_binding.get("_force_next_layout_recompose")), "Expected route-grid resize during refresh to request a full board recompose on the next UI pass.")
	_free_control(map_scene)


func test_map_route_binding_reconciles_route_buttons_after_selection_finishes() -> void:
	var owner := Control.new()
	var margin := MarginContainer.new()
	margin.name = "Margin"
	owner.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	var route_grid := Control.new()
	route_grid.name = "RouteGrid"
	route_grid.size = Vector2(1052.0, 1008.0)
	route_grid.custom_minimum_size = route_grid.size
	vbox.add_child(route_grid)
	for index in range(MapRouteBindingScript.ROUTE_MARKER_NODE_NAMES.size()):
		var marker_rect := TextureRect.new()
		marker_rect.name = String(MapRouteBindingScript.ROUTE_MARKER_NODE_NAMES[index])
		route_grid.add_child(marker_rect)
		var route_button := Button.new()
		route_button.name = String(MapRouteBindingScript.ROUTE_BUTTON_NODE_NAMES[index])
		route_grid.add_child(route_button)
	var route_binding: RefCounted = MapRouteBindingScript.new()
	route_binding.call("configure", owner, Callable(owner, "get_node_or_null"), MapBoardComposerV2Script.new())
	route_binding.call("ensure_runtime_board_nodes")
	var presenter: RefCounted = MapExplorePresenterScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(1)
	route_binding.call(
		"set_route_models",
		presenter.call("build_route_view_models", run_state, MapRouteBindingScript.ROUTE_BUTTON_NODE_NAMES.size())
	)
	route_binding.call("prepare_for_refresh", run_state)
	route_binding.call("render", run_state)
	var target_node_id: int = int(run_state.map_runtime_state.get_adjacent_node_ids()[0])
	var stale_targets_before_move: Array[int] = _visible_route_button_targets(owner)
	assert(
		stale_targets_before_move.has(target_node_id),
		"Expected one visible route button to target the selected adjacent node before travel."
	)
	route_binding.call("begin_selection")
	run_state.map_runtime_state.move_to_node(target_node_id)
	run_state.map_runtime_state.mark_node_resolved(target_node_id)
	route_binding.call(
		"set_route_models",
		presenter.call("build_route_view_models", run_state, MapRouteBindingScript.ROUTE_BUTTON_NODE_NAMES.size())
	)
	var stale_targets_after_move: Array[int] = _visible_route_button_targets(owner)
	assert(
		stale_targets_after_move.has(target_node_id),
		"Expected skipped in-flight refresh coverage to leave the old target button visible until selection finalization."
	)
	route_binding.call("finish_selection_and_render", run_state)
	var refreshed_targets: Array[int] = _visible_route_button_targets(owner)
	assert(
		not refreshed_targets.has(int(run_state.map_runtime_state.current_node_id)),
		"Expected selection finalization to clear any stale route button that still targets the newly current node."
	)
	_free_control(owner)


func test_map_route_buttons_suppress_default_tooltip_copy() -> void:
	var map_scene: Control = MapExplorePackedScene.instantiate() as Control
	assert(map_scene != null, "Expected map scene instance for route-tooltip suppression coverage.")
	get_root().add_child(map_scene)
	await process_frame
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.configure_run_seed(1)
	var presenter: RefCounted = MapExplorePresenterScript.new()
	var route_binding: RefCounted = map_scene.get("_route_binding")
	assert(route_binding != null, "Expected map scene to create the shared route binding.")
	route_binding.call("set_route_models", presenter.call("build_route_view_models", run_state, 6))
	route_binding.call("prepare_for_refresh", run_state)
	route_binding.call("render", run_state)
	var route_grid: Control = map_scene.get_node_or_null("Margin/VBox/RouteGrid") as Control
	assert(route_grid != null, "Expected map scene route grid for tooltip suppression coverage.")
	var visible_route_button: Button = null
	for button_name in MapRouteBindingScript.ROUTE_BUTTON_NODE_NAMES:
		var route_button: Button = route_grid.get_node_or_null(button_name) as Button
		if route_button != null and route_button.visible:
			visible_route_button = route_button
			break
	assert(visible_route_button != null, "Expected at least one visible route button on the map scene.")
	assert(visible_route_button.text.contains("\n"), "Expected route buttons to keep their internal route label text.")
	assert(visible_route_button.tooltip_text.is_empty(), "Expected map route buttons to suppress the default Godot tooltip so only the marker chip remains visible.")
	_free_control(map_scene)


func test_map_scene_does_not_spawn_legacy_line2d_roads() -> void:
	var map_scene: Control = MapExplorePackedScene.instantiate() as Control
	assert(map_scene != null, "Expected map scene instance for runtime road-node cleanup coverage.")
	get_root().add_child(map_scene)
	await process_frame
	var route_grid: Control = map_scene.get_node_or_null("Margin/VBox/RouteGrid") as Control
	assert(route_grid != null, "Expected map scene route grid for road-node cleanup coverage.")
	assert(route_grid.get_node_or_null("RouteRoadBase0") == null, "Expected composed map board rendering to stop spawning legacy base road Line2D nodes.")
	assert(route_grid.get_node_or_null("RouteRoadHighlight0") == null, "Expected composed map board rendering to stop spawning legacy highlight Line2D nodes.")
	_free_control(map_scene)


func test_event_overlay_uses_stable_offers_shell() -> void:
	var node_event_scene: Control = EventScenePacked.instantiate() as Control
	assert(node_event_scene != null, "Expected planned event overlay regression test to instantiate the Event scene.")
	node_event_scene.top_level = true
	var node_event_host := Control.new()
	get_root().add_child(node_event_host)
	node_event_host.add_child(node_event_scene)
	var node_event_state: EventState = EventStateScript.new()
	node_event_state.setup_for_node(6, 1, EventStateScript.SOURCE_CONTEXT_NODE_EVENT)
	node_event_scene.set("_event_state", node_event_state)
	node_event_scene.call("_apply_temp_theme")
	var node_event_shell: PanelContainer = node_event_scene.get_node_or_null("Margin/VBox/OffersShell") as PanelContainer
	assert(node_event_shell != null and node_event_shell.visible, "Expected planned Trail Event overlays to keep the same stable offers shell as the other overlay family.")
	var node_event_header: PanelContainer = node_event_scene.get_node_or_null("Margin/VBox/OffersShell/VBox/HeaderRow/HeaderCard") as PanelContainer
	assert(node_event_header != null and node_event_header.visible, "Expected planned Trail Event overlays to keep a dedicated header card instead of floating title copy above the map bed.")
	var node_event_scrim: ColorRect = node_event_scene.get_node_or_null("Scrim") as ColorRect
	assert(node_event_scrim != null, "Expected planned Trail Event overlays to keep the shared scrim surface available under the stable shell.")
	_free_control(node_event_scene)
	_free_control(node_event_host)

	var roadside_scene: Control = EventScenePacked.instantiate() as Control
	assert(roadside_scene != null, "Expected roadside overlay regression test to instantiate the Event scene.")
	roadside_scene.top_level = true
	var roadside_host := Control.new()
	get_root().add_child(roadside_host)
	roadside_host.add_child(roadside_scene)
	var roadside_state: EventState = EventStateScript.new()
	roadside_state.setup_for_node(10, 1, EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER)
	roadside_scene.set("_event_state", roadside_state)
	roadside_scene.call("_apply_temp_theme")
	var roadside_shell: PanelContainer = roadside_scene.get_node_or_null("Margin/VBox/OffersShell") as PanelContainer
	assert(roadside_shell != null and roadside_shell.visible, "Expected roadside event overlays to keep the same stable offers shell above the map bed.")
	var roadside_scrim: ColorRect = roadside_scene.get_node_or_null("Scrim") as ColorRect
	assert(roadside_scrim != null and roadside_scrim.visible and roadside_scrim.color.a >= 0.50, "Expected roadside event overlays to strengthen the scrim so the interruption reads as a focused modal beat.")
	_free_control(roadside_scene)
	_free_control(roadside_host)


func test_map_scene_retires_camera_follow_progress_by_default() -> void:
	var scene: Control = MapExploreSceneScript.new()
	var early_progress: float = scene.call("_route_camera_follow_progress", 0.10)
	var mid_progress: float = scene.call("_route_camera_follow_progress", 0.50)
	var late_progress: float = scene.call("_route_camera_follow_progress", 0.85)
	var final_progress: float = scene.call("_route_camera_follow_progress", 1.0)
	assert(is_equal_approx(early_progress, 0.0), "Expected the fixed-board model to retire early traversal camera follow.")
	assert(is_equal_approx(mid_progress, 0.0), "Expected the fixed-board model to keep the board still through the middle of route travel.")
	assert(is_equal_approx(late_progress, 0.0), "Expected the fixed-board model to keep the board still through the late route phase.")
	assert(is_equal_approx(final_progress, 0.0), "Expected the fixed-board model not to settle onto a target focus at route end.")
	_free_control(scene)


func _free_control(control: Control) -> void:
	if control == null:
		return
	var parent: Node = control.get_parent()
	if parent != null:
		parent.remove_child(control)
	control.free()


func _visible_node_radius_by_id(visible_nodes: Array, node_id: int) -> float:
	for node_variant in visible_nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		if int(node_entry.get("node_id", -1)) == node_id:
			return float(node_entry.get("clearing_radius", 0.0))
	return 0.0


func _visible_route_button_targets(owner: Control) -> Array[int]:
	var targets: Array[int] = []
	for button_name in MapRouteBindingScript.ROUTE_BUTTON_NODE_NAMES:
		var route_button: Button = owner.get_node_or_null("Margin/VBox/RouteGrid/%s" % button_name) as Button
		if route_button == null or not route_button.visible:
			continue
		targets.append(int(route_button.get_meta("target_node_id", -1)))
	return targets
