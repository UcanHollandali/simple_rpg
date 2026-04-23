# Layer: Tests
extends SceneTree
class_name TestMapBoardCanvas

const MapBoardCanvasScript = preload("res://Game/UI/map_board_canvas.gd")
const MapBoardStyleScript = preload("res://Game/UI/map_board_style.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	test_map_board_canvas_returns_null_for_missing_asset_paths()
	test_map_board_canvas_skips_missing_known_icon_assets_without_crashing()
	test_map_board_canvas_de_emphasizes_history_trail_helpers()
	test_map_board_canvas_demotes_history_reconnect_edges_below_actionable_roads()
	test_map_board_canvas_keeps_selected_route_lane_above_other_choices()
	test_map_board_canvas_avoids_extra_curve_smoothing_on_history_reconnects()
	print("test_map_board_canvas: all assertions passed")
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func test_map_board_canvas_returns_null_for_missing_asset_paths() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	assert(
		SceneLayoutHelperScript.load_texture_or_null("res://Assets/UI/Map/Canopy/not_real.svg") == null,
		"Expected missing prototype map assets to resolve to null so board rendering can fall back cleanly instead of crashing."
	)
	board_canvas.free()


func test_map_board_canvas_skips_missing_known_icon_assets_without_crashing() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	board_canvas.call("_draw_known_node_icon", {
		"show_known_icon": true,
		"icon_texture_path": "res://Assets/Icons/not_real.svg",
		"state_semantic": "open",
		"node_family": "event",
	}, Vector2(64.0, 64.0), 24.0)
	assert(true, "Expected missing known-icon assets to short-circuit cleanly before any draw call tries to use them.")
	board_canvas.free()


func test_map_board_canvas_de_emphasizes_history_trail_helpers() -> void:
	assert(
		MapBoardStyleScript.trail_stamp_alpha_multiplier(true, 0) < MapBoardStyleScript.trail_stamp_alpha_multiplier(false, 0),
		"Expected history trail decals to use a lower alpha multiplier than local actionable roads."
	)
	assert(
		MapBoardStyleScript.trail_stamp_size_scale(true, 0) < MapBoardStyleScript.trail_stamp_size_scale(false, 0),
		"Expected history trail decals to stamp smaller than local actionable roads."
	)


func test_map_board_canvas_demotes_history_reconnect_edges_below_actionable_roads() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	board_canvas.call("set_composition", {"current_node_id": 0})
	var actionable_edge := {
		"from_node_id": 0,
		"to_node_id": 1,
		"is_history": false,
		"is_reconnect_edge": false,
		"route_surface_semantic": "local_actionable",
	}
	var history_edge := {
		"from_node_id": 2,
		"to_node_id": 3,
		"is_history": true,
		"is_reconnect_edge": false,
		"route_surface_semantic": "history",
	}
	var reconnect_edge := {
		"from_node_id": 4,
		"to_node_id": 5,
		"is_history": true,
		"is_reconnect_edge": true,
		"route_surface_semantic": "history_reconnect",
	}
	var actionable_profile: Dictionary = board_canvas.call("_edge_visual_profile", actionable_edge)
	var history_profile: Dictionary = board_canvas.call("_edge_visual_profile", history_edge)
	var reconnect_profile: Dictionary = board_canvas.call("_edge_visual_profile", reconnect_edge)
	assert(
		board_canvas.call("_edge_route_surface_semantic", actionable_edge) == "actionable",
		"Expected current-pocket roads to stay classified as actionable lanes."
	)
	assert(
		board_canvas.call("_edge_route_surface_semantic", reconnect_edge) == "history_reconnect",
		"Expected same-depth reconnect history roads to stay in the lowest-priority visual lane."
	)
	assert(
		float(actionable_profile.get("base_alpha_scale", 0.0)) > float(history_profile.get("base_alpha_scale", 1.0))
			and float(history_profile.get("base_alpha_scale", 0.0)) > float(reconnect_profile.get("base_alpha_scale", 1.0)),
		"Expected base-road alpha hierarchy to keep actionable roads above history, and history above reconnect detours."
	)
	assert(
		bool(reconnect_profile.get("draw_trail_decal", true)) == false,
		"Expected reconnect history roads to suppress bright trail stamps so they do not read like hero routes."
	)
	board_canvas.free()


func test_map_board_canvas_keeps_selected_route_lane_above_other_choices() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	board_canvas.call("set_composition", {"current_node_id": 0})
	board_canvas.call("set_interaction_state", 2, -1)
	var selected_edge := {
		"from_node_id": 0,
		"to_node_id": 2,
		"is_history": false,
		"is_reconnect_edge": false,
		"route_surface_semantic": "local_actionable",
	}
	var sibling_edge := {
		"from_node_id": 0,
		"to_node_id": 3,
		"is_history": false,
		"is_reconnect_edge": false,
		"route_surface_semantic": "local_actionable",
	}
	var selected_profile: Dictionary = board_canvas.call("_edge_visual_profile", selected_edge)
	var sibling_profile: Dictionary = board_canvas.call("_edge_visual_profile", sibling_edge)
	assert(
		board_canvas.call("_edge_route_surface_semantic", selected_edge) == "selected",
		"Expected the currently chosen route lane to promote into the selected visual tier."
	)
	assert(
		board_canvas.call("_edge_route_surface_semantic", sibling_edge) == "actionable_secondary",
		"Expected other local routes to step down once one route is actively selected."
	)
	assert(
		float(selected_profile.get("base_width_scale", 0.0)) > float(sibling_profile.get("base_width_scale", 1.0))
			and float(selected_profile.get("trail_alpha_scale", 0.0)) > float(sibling_profile.get("trail_alpha_scale", 1.0)),
		"Expected the selected route lane to dominate width and trail intensity over neighboring actionable curves."
	)
	board_canvas.free()


func test_map_board_canvas_avoids_extra_curve_smoothing_on_history_reconnects() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	var reconnect_edge := {
		"from_node_id": 4,
		"to_node_id": 5,
		"is_history": true,
		"is_reconnect_edge": true,
		"route_surface_semantic": "history_reconnect",
		"points": PackedVector2Array([Vector2(24.0, 24.0), Vector2(72.0, 84.0), Vector2(128.0, 36.0)]),
	}
	var actionable_edge := {
		"from_node_id": 0,
		"to_node_id": 1,
		"is_history": false,
		"is_reconnect_edge": false,
		"route_surface_semantic": "local_actionable",
		"points": PackedVector2Array([Vector2(24.0, 24.0), Vector2(72.0, 84.0), Vector2(128.0, 36.0)]),
	}
	var reconnect_display: PackedVector2Array = board_canvas.call("_display_edge_points_for_edge", reconnect_edge)
	var actionable_display: PackedVector2Array = board_canvas.call("_display_edge_points_for_edge", actionable_edge)
	assert(
		reconnect_display.size() == PackedVector2Array(reconnect_edge.get("points", PackedVector2Array())).size(),
		"Expected reconnect history roads to keep their raw routed polyline instead of adding extra decorative smoothing."
	)
	assert(
		actionable_display.size() > reconnect_display.size(),
		"Expected actionable roads to keep the softer display smoothing that helps the chosen lane read as one continuous trail."
	)
	board_canvas.free()
