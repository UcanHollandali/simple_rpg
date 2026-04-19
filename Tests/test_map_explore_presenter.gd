# Layer: Tests
extends SceneTree
class_name TestMapExplorePresenter

const MapExplorePresenterScript = preload("res://Game/UI/map_explore_presenter.gd")
const MapExploreSceneScript = preload("res://scenes/map_explore.gd")
const MapFocusHelperScript = preload("res://Game/UI/map_focus_helper.gd")
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
	test_map_scene_builds_route_move_path_from_composed_edge_geometry()
	test_map_scene_builds_pending_roadside_visual_sample_from_edge_geometry()
	test_map_scene_accepts_deferred_roadside_transition_for_destination_restore()
	test_map_scene_keeps_focus_offset_quiet_inside_deadzone()
	test_map_scene_blends_focus_toward_visible_cluster_context()
	test_event_overlay_uses_stable_offers_shell()
	test_map_scene_delays_camera_follow_until_after_departure()
	print("test_map_explore_presenter: all assertions passed")
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


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
		presenter.call("build_title_text", run_state) == "Stage 2",
		"Expected map presenter title to reflect the current stage."
	)
	assert(
		presenter.call("build_stage_badge_text", run_state) == "II",
		"Expected the map presenter stage badge read to expose a compact Roman numeral for the top-shell medallion."
	)
	assert(
		String(presenter.call("build_progress_text", run_state)).to_lower().contains("open"),
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
		String(presenter.call("build_route_overview_text", run_state)).contains("At Combat"),
		"Expected the top route overview to start from the current runtime-owned pocket read."
	)
	assert(
		String(presenter.call("build_route_overview_text", run_state)).contains("Boss locked"),
		"Expected the top route overview to surface gate readiness without relying on the bottom status log."
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
		presenter.call("build_node_family_display_name", "boss") == "Boss Gate",
		"Expected node-family display names to stay presenter-owned for the route board."
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
		presenter.call("build_node_family_display_name", "hamlet") == "Hamlet",
		"Expected hamlet routes to expose the canonical settlement label."
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
		presenter.call("build_route_icon_texture_path", "event") == "res://Assets/Icons/icon_map_trail_event.svg",
		"Expected event routes to resolve to the dedicated Trail Event icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "hamlet") == "res://Assets/Icons/icon_map_side_mission.svg",
		"Expected hamlet routes to use the dedicated settlement-contract icon floor."
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
		String(route_models[0].get("text", "")) == "Combat\nOpen Route",
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
		if String(route_model.get("text", "")) != "Start\nBacktrack":
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
		String(reward_focus_model.get("title_text", "")).contains("Reward"),
		"Expected a focused route panel to surface the route family display name."
	)
	assert(
		String(reward_focus_model.get("hint_text", "")).contains("immediate pickup"),
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


func test_map_scene_builds_route_move_path_from_composed_edge_geometry() -> void:
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
	})
	var route_points: PackedVector2Array = scene.call(
		"_build_route_move_world_path",
		3,
		5,
		Vector2.ZERO,
		Vector2.ZERO
	)
	assert(route_points.size() == 5, "Expected route travel to include start, composed edge points, and target in the walker path.")
	assert(route_points[0].distance_to(Vector2(128.0, 244.0)) <= 0.001, "Expected route travel to start from the current node world position.")
	assert(route_points[1].distance_to(Vector2(154.0, 262.0)) <= 0.001, "Expected route travel to preserve the composed trail geometry for departure.")
	assert(route_points[route_points.size() - 1].distance_to(Vector2(302.0, 388.0)) <= 0.001, "Expected route travel to end at the target node world position.")
	_free_control(scene)


func test_map_scene_builds_pending_roadside_visual_sample_from_edge_geometry() -> void:
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
	scene.set("_route_layout_offset", Vector2.ZERO)
	scene.call("_prime_roadside_visual_state", 0, 4)
	var sample: Dictionary = scene.call("_build_pending_roadside_visual_sample")
	var sample_point: Vector2 = sample.get("point", Vector2.ZERO)
	assert(not sample.is_empty(), "Expected roadside interruption visuals to sample a mid-route point from the composed edge geometry.")
	assert(
		sample_point.distance_to(Vector2(180.0, 520.0)) > 32.0 and sample_point.distance_to(Vector2(520.0, 220.0)) > 32.0,
		"Expected roadside interruption visuals not to collapse back onto the source node or jump all the way to the destination node."
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


func test_map_scene_keeps_focus_offset_quiet_inside_deadzone() -> void:
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
	scene.set("_route_layout_offset", Vector2.ZERO)
	var centered_offset: Vector2 = scene.call("_desired_focus_offset_for_world_position", Vector2(540.0, 960.0))
	assert(
		centered_offset == Vector2.ZERO,
		"Expected the board focus deadzone to keep the map quiet when the current node is already inside the readable center envelope."
	)
	var edge_offset: Vector2 = scene.call("_desired_focus_offset_for_world_position", Vector2(140.0, 180.0))
	assert(
		edge_offset.length() > 0.0,
		"Expected the board focus deadzone still to allow a limited corrective offset for extreme edge positions."
	)
	assert(
		edge_offset.length() < Vector2(540.0, 780.0).length(),
		"Expected corrective map focus movement to stay damped instead of fully re-centering the board every step."
	)
	_free_control(scene)


func test_map_scene_blends_focus_toward_visible_cluster_context() -> void:
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
	scene.set("_route_layout_offset", Vector2.ZERO)
	scene.set("_board_composition_cache", {
		"visible_nodes": [
			{"node_id": 0, "is_current": true, "is_adjacent": false, "state_semantic": "current", "world_position": Vector2(860.0, 980.0)},
			{"node_id": 1, "is_current": false, "is_adjacent": true, "state_semantic": "open", "world_position": Vector2(720.0, 940.0)},
			{"node_id": 2, "is_current": false, "is_adjacent": false, "state_semantic": "resolved", "world_position": Vector2(650.0, 900.0)},
		],
	})
	var current_world_position := Vector2(860.0, 980.0)
	var raw_offset: Vector2 = MapFocusHelperScript.desired_focus_offset(
		route_grid,
		Vector2.ZERO,
		current_world_position,
		Vector2(0.5, 0.55),
		Vector2(0.05, 0.06),
		Vector2(0.18, 0.20),
		0.42
	)
	var contextual_offset: Vector2 = scene.call("_desired_focus_offset_for_world_position", current_world_position)
	assert(
		absf(contextual_offset.x) < absf(raw_offset.x),
		"Expected map focus to preserve more visible-cluster context instead of pulling the board fully toward the current node."
	)
	_free_control(scene)


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


func test_map_scene_delays_camera_follow_until_after_departure() -> void:
	var scene: Control = MapExploreSceneScript.new()
	var early_progress: float = scene.call("_route_camera_follow_progress", 0.10)
	var mid_progress: float = scene.call("_route_camera_follow_progress", 0.50)
	var late_progress: float = scene.call("_route_camera_follow_progress", 0.85)
	var final_progress: float = scene.call("_route_camera_follow_progress", 1.0)
	assert(is_equal_approx(early_progress, 0.0), "Expected board follow to hold briefly at departure so the walker can leave the current node before the board recenters.")
	assert(mid_progress < 0.5, "Expected board follow to lag behind raw route progress through the middle of the travel beat.")
	assert(late_progress > mid_progress, "Expected board follow to keep catching up through the late route phase.")
	assert(is_equal_approx(final_progress, 1.0), "Expected board follow to settle fully onto the target focus by the end of the route.")
	_free_control(scene)


func _free_control(control: Control) -> void:
	if control == null:
		return
	var parent: Node = control.get_parent()
	if parent != null:
		parent.remove_child(control)
	control.free()
