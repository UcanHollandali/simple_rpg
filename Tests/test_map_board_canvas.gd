# Layer: Tests
extends SceneTree
class_name TestMapBoardCanvas

const MapBoardCanvasScript = preload("res://Game/UI/map_board_canvas.gd")
const MapBoardStyleScript = preload("res://Game/UI/map_board_style.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	test_map_board_canvas_returns_null_for_missing_asset_paths()
	test_map_board_canvas_skips_missing_known_icon_assets_without_crashing()
	test_map_board_canvas_demotes_history_reconnect_edges_below_actionable_roads()
	test_map_board_canvas_uses_render_model_surface_lane_by_default()
	test_map_board_canvas_derives_socket_art_from_render_model_slots()
	test_map_board_canvas_splits_tight_surface_paths_into_safe_segment_polygons()
	test_map_board_canvas_keeps_selected_route_lane_above_other_choices()
	test_map_board_canvas_keeps_hover_preview_below_selected_route_lane()
	test_map_board_canvas_uses_landmark_signage_slots_for_known_icons()
	test_map_board_canvas_subdues_icon_disc_support_when_landmark_footprints_exist()
	test_map_board_canvas_builds_key_diamond_pocket_polygon()
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


func test_map_board_canvas_demotes_history_reconnect_edges_below_actionable_roads() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	board_canvas.call("set_composition", {"current_node_id": 0})
	var primary_actionable_edge := {
		"from_node_id": 0,
		"to_node_id": 1,
		"is_history": false,
		"is_reconnect_edge": false,
		"route_surface_semantic": "primary_actionable_corridor",
	}
	var branch_actionable_edge := {
		"from_node_id": 0,
		"to_node_id": 2,
		"is_history": false,
		"is_reconnect_edge": false,
		"route_surface_semantic": "branch_actionable_corridor",
	}
	var branch_history_edge := {
		"from_node_id": 2,
		"to_node_id": 3,
		"is_history": true,
		"is_reconnect_edge": false,
		"route_surface_semantic": "branch_history_corridor",
	}
	var reconnect_edge := {
		"from_node_id": 4,
		"to_node_id": 5,
		"is_history": true,
		"is_reconnect_edge": true,
		"route_surface_semantic": "reconnect_corridor",
	}
	var primary_profile: Dictionary = board_canvas.call("_edge_visual_profile", primary_actionable_edge)
	var branch_actionable_profile: Dictionary = board_canvas.call("_edge_visual_profile", branch_actionable_edge)
	var branch_history_profile: Dictionary = board_canvas.call("_edge_visual_profile", branch_history_edge)
	var reconnect_profile: Dictionary = board_canvas.call("_edge_visual_profile", reconnect_edge)
	assert(
		board_canvas.call("_edge_route_surface_semantic", primary_actionable_edge) == "primary_actionable_corridor",
		"Expected the lead opening corridor to keep its first-class primary actionable semantic."
	)
	assert(
		board_canvas.call("_edge_route_surface_semantic", branch_actionable_edge) == "branch_actionable_corridor",
		"Expected non-primary local choices to stay in the branch corridor lane instead of collapsing back into generic actionable styling."
	)
	assert(
		board_canvas.call("_edge_route_surface_semantic", reconnect_edge) == "reconnect_corridor",
		"Expected reconnect detours to stay in the lowest-priority corridor lane."
	)
	assert(
		float(primary_profile.get("base_alpha_scale", 0.0)) > float(branch_actionable_profile.get("base_alpha_scale", 1.0))
			and float(branch_actionable_profile.get("base_alpha_scale", 0.0)) > float(branch_history_profile.get("base_alpha_scale", 1.0))
			and float(branch_history_profile.get("base_alpha_scale", 0.0)) > float(reconnect_profile.get("base_alpha_scale", 1.0)),
		"Expected the owner-level corridor hierarchy to keep primary corridors above branch corridors, branch history above generic reconnect detours."
	)
	assert(float(reconnect_profile.get("base_alpha_scale", 1.0)) < 0.30, "Expected reconnect history roads to stay below actionable roads in the render-model surface lane.")
	board_canvas.free()


func test_map_board_canvas_uses_render_model_surface_lane_by_default() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	var render_surface := {
		"surface_id": "path:0:1",
		"shape": "polyline_strip",
		"centerline_points": PackedVector2Array([Vector2(18.0, 22.0), Vector2(180.0, 92.0)]),
		"surface_width": 34.0,
		"outer_width": 44.0,
		"from_node_id": 0,
		"to_node_id": 1,
		"role": "primary_actionable_corridor",
		"route_surface_semantic": "primary_actionable_corridor",
		"state_semantic": "open",
		"is_history": false,
		"is_reconnect_edge": false,
	}
	board_canvas.call("set_composition", {
		"current_node_id": 0,
		"visible_edges": [{
			"from_node_id": 0,
			"to_node_id": 99,
			"points": PackedVector2Array([Vector2(400.0, 400.0), Vector2(600.0, 600.0)]),
			"route_surface_semantic": "history_corridor",
		}],
		"render_model": {
			"schema_version": 1,
			"path_surfaces": [render_surface],
			"junctions": [{
				"junction_id": "junction:0",
				"node_id": 0,
				"center": Vector2(18.0, 22.0),
				"junction_radius": 24.0,
				"junction_role": "local_choice_blend",
				"connected_surface_ids": ["path:0:1"],
			}],
			"clearing_surfaces": [{
				"surface_id": "clearing:0",
				"node_id": 0,
				"node_family": "start",
				"node_state": "resolved",
				"state_semantic": "current",
				"shape": "clearing_disc",
				"center": Vector2(18.0, 22.0),
				"radius": 42.0,
				"is_current": true,
			}],
		},
	})
	assert(
		bool(board_canvas.call("_uses_render_model_surface_lane")),
		"Expected canvas to treat render_model path/clearing surfaces as the default presentation lane when present."
	)
	var path_surfaces: Array = board_canvas.call("_path_surface_entries")
	assert(path_surfaces.size() == 1, "Expected canvas default path-surface reads to come from render_model rather than visible_edges.")
	var first_surface: Dictionary = path_surfaces[0]
	assert(
		PackedVector2Array(first_surface.get("centerline_points", PackedVector2Array()))[0] == Vector2(18.0, 22.0),
		"Expected render_model centerline geometry to win over mismatched legacy visible_edges geometry."
	)
	var strip_polygon: PackedVector2Array = board_canvas.call("_polyline_strip_polygon", PackedVector2Array(render_surface.get("centerline_points", PackedVector2Array())), 17.0)
	assert(strip_polygon.size() >= 4, "Expected render-model roads to expand into terrain surface polygons, not remain line-only strokes.")
	board_canvas.free()


func test_map_board_canvas_derives_socket_art_from_render_model_slots() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	board_canvas.call("set_composition", {
		"render_model": {
			"schema_version": 1,
			"path_surfaces": [{
				"surface_id": "path:0:1",
				"shape": "polyline_strip",
				"centerline_points": PackedVector2Array([Vector2(20.0, 24.0), Vector2(92.0, 64.0)]),
				"surface_width": 28.0,
				"role": "primary_actionable_corridor",
				"route_surface_semantic": "primary_actionable_corridor",
				"state_semantic": "open",
				"is_history": false,
			}],
			"clearing_surfaces": [{
				"surface_id": "clearing:0",
				"node_id": 0,
				"shape": "clearing_disc",
				"center": Vector2(20.0, 24.0),
				"radius": 32.0,
				"is_current": true,
			}],
			"landmark_slots": [{
				"slot_id": "landmark:0",
				"asset_socket_kind": "landmark",
				"node_family": "boss",
				"slot_role": "current_landmark",
				"anchor_point": Vector2(64.0, 72.0),
				"landmark_half_size": Vector2(16.0, 24.0),
				"rotation_degrees": 12.0,
				"asset_family_key": "boss:spire",
			}, {
				"slot_id": "landmark:1",
				"asset_socket_kind": "landmark",
				"node_family": "merchant",
				"slot_role": "adjacent_landmark",
				"anchor_point": Vector2(96.0, 82.0),
				"landmark_half_size": Vector2(16.0, 18.0),
				"rotation_degrees": -6.0,
				"asset_family_key": "merchant:stall",
			}],
			"decor_slots": [{
				"slot_id": "decor:filler:0",
				"asset_socket_kind": "decor",
				"anchor_point": Vector2(128.0, 88.0),
				"half_size": Vector2(18.0, 14.0),
				"radius": 0.0,
				"rotation_degrees": -8.0,
				"relation_type": "route_side",
			}],
		},
	})
	assert(
		SceneLayoutHelperScript.load_texture_or_null(UiAssetPathsScript.MAP_ART_PILOT_PATH_SURFACE_TEXTURE_PATH) != null,
		"Expected the path-surface art-pilot runtime asset to be loadable."
	)
	assert(
		SceneLayoutHelperScript.load_texture_or_null(UiAssetPathsScript.MAP_ART_PILOT_BOSS_LANDMARK_TEXTURE_PATH) != null,
		"Expected the boss landmark art-pilot runtime asset to be loadable."
	)
	assert(
		SceneLayoutHelperScript.load_texture_or_null(UiAssetPathsScript.MAP_ART_PILOT_KEY_LANDMARK_TEXTURE_PATH) != null,
		"Expected the key landmark art-pilot runtime asset to be loadable."
	)
	assert(
		SceneLayoutHelperScript.load_texture_or_null(UiAssetPathsScript.MAP_ART_PILOT_REST_LANDMARK_TEXTURE_PATH) != null,
		"Expected the rest landmark art-pilot runtime asset to be loadable."
	)
	assert(
		SceneLayoutHelperScript.load_texture_or_null(UiAssetPathsScript.MAP_ART_PILOT_DECOR_TEXTURE_PATH) != null,
		"Expected the decor art-pilot runtime asset to be loadable."
	)

	var path_entries: Array = board_canvas.call("_path_surface_socket_smoke_entries")
	var landmark_entries: Array = board_canvas.call("_landmark_socket_smoke_entries")
	var decor_entries: Array = board_canvas.call("_decor_socket_smoke_entries")
	assert(path_entries.size() == 1, "Expected path-surface socket art to derive from render_model.path_surfaces.")
	assert(landmark_entries.size() == 1, "Expected normal landmark socket art to skip uncovered socket-smoke placeholder families.")
	assert(decor_entries.size() == 1, "Expected decor socket art to derive from render_model.decor_slots.")

	var path_entry: Dictionary = path_entries[0]
	var landmark_entry: Dictionary = landmark_entries[0]
	var decor_entry: Dictionary = decor_entries[0]
	assert(String(path_entry.get("texture_path", "")) == UiAssetPathsScript.MAP_ART_PILOT_PATH_SURFACE_TEXTURE_PATH, "Expected path-surface sockets to use the art-pilot path brush.")
	assert(String(landmark_entry.get("texture_path", "")) == UiAssetPathsScript.MAP_ART_PILOT_BOSS_LANDMARK_TEXTURE_PATH, "Expected boss landmark sockets to use the art-pilot boss landmark.")
	assert(String(decor_entry.get("texture_path", "")) == UiAssetPathsScript.MAP_ART_PILOT_DECOR_TEXTURE_PATH, "Expected decor sockets to use the art-pilot decor stamp.")
	assert(UiAssetPathsScript.build_map_landmark_socket_texture_path("key:shrine", "") == UiAssetPathsScript.MAP_ART_PILOT_KEY_LANDMARK_TEXTURE_PATH, "Expected key landmark sockets to resolve to the key art-pilot asset.")
	assert(UiAssetPathsScript.build_map_landmark_socket_texture_path("rest:camp", "") == UiAssetPathsScript.MAP_ART_PILOT_REST_LANDMARK_TEXTURE_PATH, "Expected rest landmark sockets to resolve to the rest art-pilot asset.")
	assert(UiAssetPathsScript.build_map_landmark_socket_texture_path("merchant:stall", "merchant") == "", "Expected unsupported landmark pilot families to skip socket-smoke placeholders by default.")
	assert(UiAssetPathsScript.build_map_landmark_socket_texture_path("merchant:stall", "merchant", true) == UiAssetPathsScript.MAP_SOCKET_SMOKE_LANDMARK_TEXTURE_PATH, "Expected explicit debug socket-smoke mode to reveal placeholder landmark art.")
	assert(Vector2(landmark_entry.get("center", Vector2.ZERO)) == Vector2(64.0, 72.0), "Expected landmark smoke placement to come from the socket anchor point.")
	assert(Vector2(decor_entry.get("center", Vector2.ZERO)) == Vector2(128.0, 88.0), "Expected decor smoke placement to come from the socket anchor point.")
	assert(Vector2(path_entry.get("draw_size", Vector2.ZERO)).x <= 52.0, "Expected path smoke to stay small enough to avoid becoming road truth.")
	board_canvas.call("set_socket_smoke_placeholder_drawing_enabled", true)
	var debug_landmark_entries: Array = board_canvas.call("_landmark_socket_smoke_entries")
	assert(debug_landmark_entries.size() == 2, "Expected explicit debug socket-smoke mode to include uncovered landmark placeholders.")
	assert(String((debug_landmark_entries[1] as Dictionary).get("texture_path", "")) == UiAssetPathsScript.MAP_SOCKET_SMOKE_LANDMARK_TEXTURE_PATH, "Expected debug socket-smoke mode to use the placeholder landmark texture.")
	board_canvas.free()


func test_map_board_canvas_splits_tight_surface_paths_into_safe_segment_polygons() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	var tight_backtrack_points := PackedVector2Array([
		Vector2(40.0, 40.0),
		Vector2(160.0, 42.0),
		Vector2(72.0, 50.0),
		Vector2(170.0, 58.0),
	])
	var segment_polygons: Array = board_canvas.call("_polyline_surface_segment_polygons", tight_backtrack_points, 18.0)
	assert(
		segment_polygons.size() == tight_backtrack_points.size() - 1,
		"Expected tight render-model paths to draw as independent filled segment polygons instead of one self-intersecting strip."
	)
	for polygon_variant in segment_polygons:
		var polygon: PackedVector2Array = polygon_variant
		assert(polygon.size() == 4, "Expected each path-surface segment polygon to stay a simple quad.")
		var signed_area: float = 0.0
		for point_index in range(polygon.size()):
			var current_point: Vector2 = polygon[point_index]
			var next_point: Vector2 = polygon[(point_index + 1) % polygon.size()]
			signed_area += current_point.x * next_point.y - next_point.x * current_point.y
		assert(
			absf(signed_area * 0.5) > 1.0,
			"Expected every path-surface segment polygon to keep non-zero drawable area."
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
		"route_surface_semantic": "primary_actionable_corridor",
	}
	var sibling_edge := {
		"from_node_id": 0,
		"to_node_id": 3,
		"is_history": false,
		"is_reconnect_edge": false,
		"route_surface_semantic": "branch_actionable_corridor",
	}
	var selected_profile: Dictionary = board_canvas.call("_edge_visual_profile", selected_edge)
	var sibling_profile: Dictionary = board_canvas.call("_edge_visual_profile", sibling_edge)
	assert(
		board_canvas.call("_edge_route_surface_semantic", selected_edge) == "selected",
		"Expected the currently chosen route lane to promote into the selected visual tier."
	)
	assert(
		board_canvas.call("_edge_route_surface_semantic", sibling_edge) == "branch_actionable_corridor",
		"Expected sibling local routes to keep their branch corridor semantic instead of relying on temporary interaction demotion."
	)
	assert(
		float(selected_profile.get("base_width_scale", 0.0)) > float(sibling_profile.get("base_width_scale", 1.0))
			and float(selected_profile.get("base_alpha_scale", 0.0)) > float(sibling_profile.get("base_alpha_scale", 1.0)),
		"Expected the selected route lane to dominate surface width and presence over neighboring actionable curves."
	)
	board_canvas.free()


func test_map_board_canvas_keeps_hover_preview_below_selected_route_lane() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	board_canvas.call("set_composition", {"current_node_id": 0})
	var preview_edge := {
		"from_node_id": 0,
		"to_node_id": 2,
		"is_history": false,
		"is_reconnect_edge": false,
		"route_surface_semantic": "primary_actionable_corridor",
	}
	var branch_edge := {
		"from_node_id": 0,
		"to_node_id": 3,
		"is_history": false,
		"is_reconnect_edge": false,
		"route_surface_semantic": "branch_actionable_corridor",
	}
	board_canvas.call("set_interaction_state", -1, 2)
	var preview_profile: Dictionary = board_canvas.call("_edge_visual_profile", preview_edge)
	var branch_profile: Dictionary = board_canvas.call("_edge_visual_profile", branch_edge)
	assert(
		board_canvas.call("_edge_route_surface_semantic", preview_edge) == "preview",
		"Expected hovered route previews to keep a dedicated preview lane instead of reading as a fully selected traversal lane."
	)
	assert(
		float(preview_profile.get("base_width_scale", 0.0)) > float(branch_profile.get("base_width_scale", 1.0))
			and float(preview_profile.get("base_alpha_scale", 0.0)) > float(branch_profile.get("base_alpha_scale", 1.0)),
		"Expected hovered route previews to stay above ordinary branch lanes without overtaking the selected-route tier."
	)
	board_canvas.call("set_interaction_state", 2, -1)
	var selected_profile: Dictionary = board_canvas.call("_edge_visual_profile", preview_edge)
	assert(
		float(selected_profile.get("base_width_scale", 0.0)) > float(preview_profile.get("base_width_scale", 1.0))
			and float(selected_profile.get("base_alpha_scale", 0.0)) > float(preview_profile.get("base_alpha_scale", 1.0)),
		"Expected the committed route lane to stay visually stronger than a hover preview."
	)
	board_canvas.free()


func test_map_board_canvas_uses_landmark_signage_slots_for_known_icons() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	var default_icon_rect: Rect2 = board_canvas.call("_known_icon_rect_for_node", {
		"show_known_icon": true,
		"icon_texture_path": "res://Assets/Icons/icon_reward.svg",
		"state_semantic": "open",
		"node_family": "reward",
		"is_current": false,
	}, Vector2(64.0, 64.0), 24.0)
	var landmark_icon_rect: Rect2 = board_canvas.call("_known_icon_rect_for_node", {
		"show_known_icon": true,
		"icon_texture_path": "res://Assets/Icons/icon_reward.svg",
		"state_semantic": "open",
		"node_family": "reward",
		"is_current": false,
		"landmark_footprint": {
			"signage_center_offset": Vector2(18.0, -14.0),
			"signage_scale": 0.66,
		},
	}, Vector2(64.0, 64.0), 24.0)
	var default_center: Vector2 = default_icon_rect.position + default_icon_rect.size * 0.5
	var landmark_center: Vector2 = landmark_icon_rect.position + landmark_icon_rect.size * 0.5
	assert(
		landmark_center.distance_to(Vector2(64.0, 64.0)) > default_center.distance_to(Vector2(64.0, 64.0)) + 8.0,
		"Expected known icons to move onto the landmark signage slot instead of staying pinned to the clearing center."
	)
	assert(
		landmark_icon_rect.size.x < default_icon_rect.size.x,
		"Expected landmark signage icons to shrink below the default icon-disc size so the pocket remains primary."
	)
	board_canvas.free()


func test_map_board_canvas_subdues_icon_disc_support_when_landmark_footprints_exist() -> void:
	assert(
		MapBoardStyleScript.KNOWN_ICON_OPEN_ALPHA_CAP <= 0.56
			and MapBoardStyleScript.landmark_icon_alpha_scale("open", false) <= 0.64,
		"Expected open-node icons to stay below the older icon-disc dominance cap once pocket-first read is live."
	)
	assert(
		MapBoardStyleScript.landmark_pocket_fill_color("reward", "open", false).a >= 0.36
			and MapBoardStyleScript.landmark_anchor_color("reward", "open", false).a >= 0.80,
		"Expected pocket and landmark-anchor layers to carry materially more of the node read than the older generic plate-only shell."
	)


func test_map_board_canvas_builds_key_diamond_pocket_polygon() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	var pocket_polygon: PackedVector2Array = board_canvas.call("_landmark_pocket_polygon", Vector2(100.0, 100.0), {
		"pocket_shape": "diamond",
		"pocket_center_offset": Vector2(0.0, 0.0),
		"pocket_half_size": Vector2(42.0, 54.0),
		"pocket_rotation_degrees": 0.0,
	}, 24.0)
	assert(
		pocket_polygon.size() == 4,
		"Expected key shrine pockets to use a four-point diamond silhouette instead of another generic ellipse or slab."
	)
	assert(
		pocket_polygon[0].distance_to(Vector2(100.0, 46.0)) <= 0.001
			and pocket_polygon[1].distance_to(Vector2(142.0, 100.0)) <= 0.001,
		"Expected diamond pocket geometry to preserve a distinct shrine top/side silhouette for icon-off reads."
	)
	board_canvas.free()


func test_map_board_canvas_avoids_extra_curve_smoothing_on_history_reconnects() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	var reconnect_edge := {
		"from_node_id": 4,
		"to_node_id": 5,
		"is_history": true,
		"is_reconnect_edge": true,
		"route_surface_semantic": "reconnect_corridor",
		"centerline_points": PackedVector2Array([Vector2(24.0, 24.0), Vector2(72.0, 84.0), Vector2(128.0, 36.0)]),
	}
	var actionable_edge := {
		"from_node_id": 0,
		"to_node_id": 1,
		"is_history": false,
		"is_reconnect_edge": false,
		"route_surface_semantic": "primary_actionable_corridor",
		"centerline_points": PackedVector2Array([Vector2(24.0, 24.0), Vector2(72.0, 84.0), Vector2(128.0, 36.0)]),
	}
	var reconnect_display: PackedVector2Array = board_canvas.call("_display_path_surface_points", reconnect_edge)
	var actionable_display: PackedVector2Array = board_canvas.call("_display_path_surface_points", actionable_edge)
	assert(
		reconnect_display.size() == PackedVector2Array(reconnect_edge.get("centerline_points", PackedVector2Array())).size(),
		"Expected reconnect history surfaces to keep their raw routed polyline instead of adding extra decorative smoothing."
	)
	assert(
		actionable_display.size() > reconnect_display.size(),
		"Expected actionable render-model roads to keep the softer display smoothing that helps the chosen lane read as one continuous trail."
	)
	board_canvas.free()
