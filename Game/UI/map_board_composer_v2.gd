# Layer: UI
extends RefCounted
class_name MapBoardComposerV2

const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const MapBoardBackdropBuilderScript = preload("res://Game/UI/map_board_backdrop_builder.gd")
const MapBoardGroundBuilderScript = preload("res://Game/UI/map_board_ground_builder.gd")
const MapBoardFillerBuilderScript = preload("res://Game/UI/map_board_filler_builder.gd")
const MapBoardGeometryScript = preload("res://Game/UI/map_board_geometry.gd")
const MapBoardHistoryEdgeFilterScript = preload("res://Game/UI/map_board_history_edge_filter.gd")
const MapBoardEdgeRoutingScript = preload("res://Game/UI/map_board_edge_routing.gd")
const MapBoardLayoutSolverScript = preload("res://Game/UI/map_board_layout_solver.gd")
const MapBoardRenderModelMasksSlotsScript = preload("res://Game/UI/map_board_render_model_masks_slots.gd")

const DEFAULT_TEMPLATE_PROFILE := "corridor"
const BASE_CENTER_FACTOR := Vector2(0.50, 0.63)
const CENTER_ANCHOR_FACTOR_IN_PLAYABLE_RECT := Vector2(0.50, 0.60)
const MIN_BOARD_MARGIN := Vector2(136.0, 108.0)
const MAX_NODE_CLEARING_RADIUS := 78.0
const PATH_STROKE_CLEARANCE := 18.0
const WALKER_FOOTPRINT_CLEARANCE := 26.0
const OVERLAY_CLEARANCE := Vector2(58.0, 30.0)
const LOCAL_CLEARING_SILHOUETTE_CLEARANCE := 12.0
const STABLE_LAYOUT_REUSE_POSITION_TOLERANCE := 48.0
const OPENING_BRANCH_ANGLE_PRESETS := {
	1: [-PI * 0.5],
	2: [-2.00, -1.00],
	3: [-2.28, -1.54, -0.74],
	4: [-2.36, -1.80, -1.02, -0.48],
}
const DEPTH_STEP_FACTORS := [0.0, 0.240, 0.230, 0.222, 0.214, 0.208]
const DEPTH_SPREAD_FACTORS := [0.0, 0.044, 0.072, 0.090, 0.104, 0.112]
const DEPTH_DIRECTION_PULL_FACTORS := [0.0, 0.0, 0.10, 0.17, 0.22, 0.28]
const DEPTH_LATERAL_SPREAD_SCALE_FACTORS := [1.0, 0.96, 0.88, 0.78, 0.68, 0.60]
const DEPTH_DOWNWARD_BIAS_FACTORS := [0.0, 0.0, 0.018, 0.030, 0.042, 0.054]
const DEPTH_CENTER_PULL_FACTORS := [0.0, 0.0, 0.014, 0.024, 0.036, 0.048]
const DEPTH_SECTOR_PULL_FACTORS := [0.0, 0.0, 0.24, 0.38, 0.50, 0.58]
const DEPTH_SECTOR_HORIZONTAL_FACTORS := [0.0, 0.0, 0.30, 0.44, 0.56, 0.64]
const DEPTH_SECTOR_VERTICAL_FACTORS := [0.0, 0.0, 0.18, 0.30, 0.42, 0.50]
const DEPTH_OUTER_POCKET_PULL_FACTORS := [0.0, 0.0, 0.10, 0.22, 0.34, 0.44]
const DEPTH_OUTER_POCKET_HORIZONTAL_FACTORS := [0.0, 0.0, 0.24, 0.36, 0.48, 0.56]
const DEPTH_OUTER_POCKET_VERTICAL_FACTORS := [0.0, 0.0, 0.08, 0.18, 0.28, 0.38]
const DEPTH_SIBLING_RADIAL_STAGGER_FACTORS := [0.0, 0.0, 0.020, 0.030, 0.038, 0.046]
const DEPTH_TOP_EDGE_RELIEF_FACTORS := [0.0, 0.0, 0.0, 0.032, 0.046, 0.058]
const BRANCH_GLOBAL_ROTATION_RANGE := 0.52
const BRANCH_ANGLE_NOISE := 0.04
const PATH_FAMILY_SHORT_STRAIGHT := "short_straight"
const PATH_FAMILY_GENTLE_CURVE := "gentle_curve"
const PATH_FAMILY_WIDER_CURVE := "wider_curve"
const PATH_FAMILY_OUTWARD_RECONNECTING_ARC := "outward_reconnecting_arc"
const RENDER_MODEL_SCHEMA_VERSION := 1
const CORRIDOR_ROLE_PRIMARY_ACTIONABLE := "primary_actionable_corridor"
const CORRIDOR_ROLE_BRANCH_ACTIONABLE := "branch_actionable_corridor"
const CORRIDOR_ROLE_BRANCH_HISTORY := "branch_history_corridor"
const CORRIDOR_ROLE_HISTORY := "history_corridor"
const CORRIDOR_ROLE_RECONNECT := "reconnect_corridor"
const EDGE_NODE_AVOIDANCE_PADDING := 18.0
const EDGE_NODE_AVOIDANCE_MIN_SHIFT := 24.0
const EDGE_NODE_AVOIDANCE_MAX_SHIFT := 86.0
const EDGE_NODE_AVOIDANCE_MAX_PASSES := 5
const OUTER_RECONNECT_MARGIN_BIAS := Vector2(42.0, 64.0)
const SAME_DEPTH_RECONNECT_MAX_RATIO := 1.60
const SAME_DEPTH_RECONNECT_MIN_EDGE_CLEARANCE := 72.0
const RENDER_PATH_SURFACE_WIDTH_BY_ROLE := {
	"primary_actionable_corridor": 34.0,
	"branch_actionable_corridor": 28.0,
	"branch_history_corridor": 22.0,
	"history_corridor": 18.0,
	"reconnect_corridor": 14.0,
}
const LEGACY_FIELD_STATUS := {
	"layout_edges": "fallback",
	"visible_edges": "fallback",
	"ground_shapes": "wrapper",
	"filler_shapes": "wrapper",
	"forest_shapes": "wrapper",
}
func compose(
	run_state: RunState,
	board_size: Vector2,
	focus_anchor_factor: Vector2,
	max_focus_offset: Vector2,
	stable_layout: Dictionary = {}
) -> Dictionary:
	if run_state == null or board_size.x <= 0.0 or board_size.y <= 0.0:
		return _empty_composition()

	var map_runtime_state: RefCounted = run_state.map_runtime_state
	if map_runtime_state == null:
		return _empty_composition()

	var graph_snapshot: Array[Dictionary] = _build_layout_graph_snapshot(map_runtime_state)
	if graph_snapshot.is_empty():
		return _empty_composition()

	graph_snapshot.sort_custom(Callable(self, "_sort_node_entry_by_id"))
	var graph_by_id: Dictionary = _index_graph_snapshot(graph_snapshot)
	var start_node_id: int = _resolve_start_node_id(graph_snapshot)
	var depth_by_node_id: Dictionary = _build_depth_by_node_id(graph_by_id, start_node_id)
	var current_node_id: int = int(map_runtime_state.current_node_id)
	var active_template_id: String = String(map_runtime_state.get_active_template_id())
	var template_profile: String = _template_profile_for_id(active_template_id)
	var board_seed: int = _build_board_seed(run_state, active_template_id, graph_snapshot)
	var side_quest_highlight: Dictionary = map_runtime_state.build_side_quest_highlight_snapshot()
	var layout_context: Dictionary = _build_layout_context(
		graph_snapshot,
		graph_by_id,
		depth_by_node_id,
		start_node_id,
		template_profile,
		board_seed
	)
	layout_context["current_branch_root_id"] = _current_branch_root_id(
		start_node_id,
		current_node_id,
		layout_context.get("branch_root_by_node_id", {})
	)
	var playable_rect: Rect2 = build_playable_rect(board_size)
	var min_board_margin: Vector2 = playable_rect.position
	var stable_world_positions: Dictionary = (stable_layout.get("world_positions", {}) as Dictionary).duplicate(true)
	var can_reuse_stable_layout: bool = _stable_layout_matches_board_size(stable_world_positions, start_node_id, board_size)
	var world_positions: Dictionary = stable_world_positions if can_reuse_stable_layout else {}
	if world_positions.is_empty(): world_positions = _build_world_positions(graph_snapshot, board_size, layout_context, template_profile, board_seed)
	var graph_nodes: Array[Dictionary] = _build_graph_node_entries(graph_snapshot, world_positions, board_size)
	var layout_edges: Array = (stable_layout.get("layout_edges", []) as Array).duplicate(true) if can_reuse_stable_layout else []
	if layout_edges.is_empty(): layout_edges = _build_full_edge_layouts(graph_by_id, graph_nodes, world_positions, layout_context, template_profile, board_seed, board_size)
	graph_nodes = _decorate_node_entries_with_landmark_footprints(graph_nodes, layout_edges, board_seed, board_size)
	var visible_nodes: Array = _build_visible_node_entries(graph_snapshot, graph_by_id, world_positions, current_node_id, board_size)
	var visible_edges: Array = _build_visible_edges(layout_edges, visible_nodes, current_node_id, layout_context, board_size)
	visible_nodes = _decorate_node_entries_with_landmark_footprints(visible_nodes, visible_edges, board_seed, board_size)
	var terrain_mask_context: Dictionary = _build_render_model_core(layout_edges, graph_nodes, layout_context, board_size, template_profile)
	var render_model_core: Dictionary = _build_render_model_core(visible_edges, visible_nodes, layout_context, board_size, template_profile)
	# Wrapper terrain/decor payloads are retained only as render-model mask/socket derivation sources.
	# The canvas default lane draws from render_model surfaces, not these legacy wrapper fields.
	var can_reuse_terrain_shapes: bool = can_reuse_stable_layout and _stable_terrain_shapes_have_surface_masks(stable_layout)
	var ground_shapes: Array = (stable_layout.get("ground_shapes", []) as Array).duplicate(true) if can_reuse_terrain_shapes else []
	if ground_shapes.is_empty(): ground_shapes = MapBoardGroundBuilderScript.build_ground_shapes(board_size, graph_nodes, layout_edges, template_profile, board_seed, BASE_CENTER_FACTOR, min_board_margin, terrain_mask_context)
	var filler_shapes: Array = (stable_layout.get("filler_shapes", []) as Array).duplicate(true) if can_reuse_terrain_shapes else []
	if filler_shapes.is_empty(): filler_shapes = MapBoardFillerBuilderScript.build_filler_shapes(board_size, graph_nodes, layout_edges, template_profile, board_seed, BASE_CENTER_FACTOR, min_board_margin, terrain_mask_context)
	var forest_shapes: Array = (stable_layout.get("forest_shapes", []) as Array).duplicate(true) if can_reuse_terrain_shapes else []
	if forest_shapes.is_empty(): forest_shapes = MapBoardBackdropBuilderScript.build_forest_shapes(board_size, graph_nodes, layout_edges, template_profile, board_seed, BASE_CENTER_FACTOR, min_board_margin, terrain_mask_context)
	var render_model: Dictionary = MapBoardRenderModelMasksSlotsScript.extend_render_model(render_model_core, visible_nodes, filler_shapes, forest_shapes)
	return {
		"seed": board_seed,
		"template_profile": template_profile,
		"current_node_id": current_node_id,
		"current_branch_root_id": int(layout_context.get("current_branch_root_id", current_node_id)),
		"side_quest_highlight_node_id": int(side_quest_highlight.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)),
		"side_quest_highlight_state": String(side_quest_highlight.get("highlight_state", "")),
		"depth_by_node_id": (depth_by_node_id as Dictionary).duplicate(true),
		"layout_sector_by_node_id": (layout_context.get("sector_by_node_id", {}) as Dictionary).duplicate(true),
		"layout_route_role_by_node_id": (layout_context.get("route_role_by_node_id", {}) as Dictionary).duplicate(true),
		"slot_anchor_sector_by_node_id": (layout_context.get("slot_anchor_sector_by_node_id", {}) as Dictionary).duplicate(true),
		"slot_anchor_index_by_node_id": (layout_context.get("slot_anchor_index_by_node_id", {}) as Dictionary).duplicate(true),
		"orientation_profile_id": String(layout_context.get("orientation_profile_id", "")),
		"topology_blueprint_id": String(layout_context.get("topology_blueprint_id", "")),
		"placement_mode": String(layout_context.get("placement_mode", "derived_layout")),
		"post_anchor_relief_mode": String(layout_context.get("post_anchor_relief_mode", "")),
		"primary_parent_by_node_id": (layout_context.get("primary_parent_by_node_id", {}) as Dictionary).duplicate(true),
		"branch_root_by_node_id": (layout_context.get("branch_root_by_node_id", {}) as Dictionary).duplicate(true),
		"world_positions": world_positions,
		"layout_edges": layout_edges,
		"visible_nodes": visible_nodes,
		"visible_edges": visible_edges,
		"ground_shapes": ground_shapes,
		"filler_shapes": filler_shapes,
		"forest_shapes": forest_shapes,
		"render_model": render_model,
		"focus_offset": Vector2.ZERO,
	}


func build_clearing_radius(node_family: String, state_semantic: String, board_size: Vector2) -> float:
	return _clearing_radius_for(node_family, state_semantic, board_size)


static func build_playable_rect(board_size: Vector2) -> Rect2:
	var margin: Vector2 = build_playable_margin()
	return Rect2(
		margin,
		Vector2(
			maxf(0.0, board_size.x - margin.x * 2.0),
			maxf(0.0, board_size.y - margin.y * 2.0)
		)
	)


static func build_center_anchor_position(board_size: Vector2) -> Vector2:
	var playable_rect: Rect2 = build_playable_rect(board_size)
	return playable_rect.position + playable_rect.size * CENTER_ANCHOR_FACTOR_IN_PLAYABLE_RECT


static func build_playable_margin() -> Vector2:
	return Vector2(
		MAX_NODE_CLEARING_RADIUS + maxf(OVERLAY_CLEARANCE.x, maxf(PATH_STROKE_CLEARANCE, maxf(WALKER_FOOTPRINT_CLEARANCE, LOCAL_CLEARING_SILHOUETTE_CLEARANCE))),
		MAX_NODE_CLEARING_RADIUS + maxf(OVERLAY_CLEARANCE.y, maxf(PATH_STROKE_CLEARANCE, maxf(WALKER_FOOTPRINT_CLEARANCE, LOCAL_CLEARING_SILHOUETTE_CLEARANCE)))
	)


static func build_path_safe_rect(board_size: Vector2) -> Rect2:
	var path_margin: float = maxf(PATH_STROKE_CLEARANCE, WALKER_FOOTPRINT_CLEARANCE * 0.5)
	return Rect2(
		Vector2(path_margin, path_margin),
		Vector2(
			maxf(0.0, board_size.x - path_margin * 2.0),
			maxf(0.0, board_size.y - path_margin * 2.0)
		)
	)


func _empty_composition() -> Dictionary:
	return {
		"seed": 0,
		"template_profile": DEFAULT_TEMPLATE_PROFILE,
		"current_node_id": MapRuntimeStateScript.NO_PENDING_NODE_ID,
		"side_quest_highlight_node_id": MapRuntimeStateScript.NO_PENDING_NODE_ID,
		"side_quest_highlight_state": "",
		"world_positions": {},
		"layout_edges": [],
		"visible_nodes": [],
		"visible_edges": [],
		"ground_shapes": [],
		"filler_shapes": [],
		"forest_shapes": [],
		"render_model": _empty_render_model(),
		"focus_offset": Vector2.ZERO,
	}


func _empty_render_model() -> Dictionary:
	return {
		"schema_version": RENDER_MODEL_SCHEMA_VERSION,
		"orientation_profile_id": "",
		"center_outward_emphasis_id": "",
		"topology_blueprint_id": "",
		"template_profile": DEFAULT_TEMPLATE_PROFILE,
		"legacy_field_status": LEGACY_FIELD_STATUS.duplicate(true),
		"path_surfaces": [],
		"junctions": [],
		"clearing_surfaces": [],
		"canopy_masks": [],
		"landmark_slots": [],
		"decor_slots": [],
	}


func rebuild_render_model_for_composition(composition: Dictionary) -> Dictionary:
	if composition.is_empty():
		return composition
	var updated_composition: Dictionary = composition.duplicate(true)
	var layout_context := {
		"orientation_profile_id": String(updated_composition.get("orientation_profile_id", "")),
		"topology_blueprint_id": String(updated_composition.get("topology_blueprint_id", "")),
	}
	updated_composition["render_model"] = _build_render_model_payload(
		(updated_composition.get("visible_edges", []) as Array).duplicate(true),
		(updated_composition.get("visible_nodes", []) as Array).duplicate(true),
		(updated_composition.get("filler_shapes", []) as Array).duplicate(true),
		(updated_composition.get("forest_shapes", []) as Array).duplicate(true),
		layout_context,
		Vector2(updated_composition.get("board_size", Vector2.ZERO)),
		String(updated_composition.get("template_profile", DEFAULT_TEMPLATE_PROFILE))
	)
	return updated_composition


func _build_render_model_payload(
	visible_edges: Array,
	visible_nodes: Array,
	filler_shapes: Array,
	forest_shapes: Array,
	layout_context: Dictionary,
	board_size: Vector2,
	template_profile: String
) -> Dictionary:
	var render_model: Dictionary = _build_render_model_core(visible_edges, visible_nodes, layout_context, board_size, template_profile)
	return MapBoardRenderModelMasksSlotsScript.extend_render_model(render_model, visible_nodes, filler_shapes, forest_shapes)


func _stable_terrain_shapes_have_surface_masks(stable_layout: Dictionary) -> bool:
	for field_name in ["ground_shapes", "filler_shapes", "forest_shapes"]:
		var shape_entries: Array = stable_layout.get(field_name, [])
		if shape_entries.is_empty():
			return false
		for shape_variant in shape_entries:
			if typeof(shape_variant) != TYPE_DICTIONARY:
				return false
			var shape_entry: Dictionary = shape_variant
			if String(shape_entry.get("mask_source", "")).is_empty():
				return false
	return true


func _build_render_model_core(
	visible_edges: Array,
	visible_nodes: Array,
	layout_context: Dictionary,
	board_size: Vector2,
	template_profile: String
) -> Dictionary:
	var path_surfaces: Array[Dictionary] = _build_render_model_path_surfaces(visible_edges)
	var junctions: Array[Dictionary] = _build_render_model_junctions(visible_nodes, path_surfaces)
	var clearing_surfaces: Array[Dictionary] = _build_render_model_clearing_surfaces(visible_nodes, path_surfaces)
	return {
		"schema_version": RENDER_MODEL_SCHEMA_VERSION,
		"orientation_profile_id": String(layout_context.get("orientation_profile_id", "")),
		"center_outward_emphasis_id": String(layout_context.get("orientation_profile_id", "")),
		"topology_blueprint_id": String(layout_context.get("topology_blueprint_id", "")),
		"template_profile": template_profile,
		"board_size": board_size,
		"legacy_field_status": LEGACY_FIELD_STATUS.duplicate(true),
		"path_surfaces": path_surfaces,
		"junctions": junctions,
		"clearing_surfaces": clearing_surfaces,
	}


func _build_render_model_path_surfaces(visible_edges: Array) -> Array[Dictionary]:
	var path_surfaces: Array[Dictionary] = []
	for edge_variant in visible_edges:
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		var points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		var from_node_id: int = int(edge_entry.get("from_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var to_node_id: int = int(edge_entry.get("to_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var corridor_role: String = String(edge_entry.get("corridor_role_semantic", edge_entry.get("route_surface_semantic", "")))
		var cardinal_direction: String = String(edge_entry.get("corridor_cardinal_direction", ""))
		var surface_width: float = _render_path_surface_width_for_role(corridor_role)
		var centerline_points: PackedVector2Array = _duplicate_packed_vector2_array(points)
		path_surfaces.append({
			"surface_id": _render_path_surface_id(from_node_id, to_node_id),
			"shape": "polyline_strip",
			"centerline_points": centerline_points,
			"surface_width": surface_width,
			"outer_width": surface_width + 10.0,
			"endpoint_node_ids": [from_node_id, to_node_id],
			"from_node_id": from_node_id,
			"to_node_id": to_node_id,
			"from_endpoint": centerline_points[0],
			"to_endpoint": centerline_points[centerline_points.size() - 1],
			"role": corridor_role,
			"route_surface_semantic": String(edge_entry.get("route_surface_semantic", corridor_role)),
			"state_semantic": String(edge_entry.get("state_semantic", "open")),
			"path_family": String(edge_entry.get("path_family", "")),
			"cardinal_direction": cardinal_direction,
			"outward_route_hint": _render_path_outward_route_hint(edge_entry, cardinal_direction),
			"corridor_throat_id": String(edge_entry.get("corridor_throat_id", "")),
			"corridor_departure_node_id": int(edge_entry.get("corridor_departure_node_id", from_node_id)),
			"corridor_arrival_node_id": int(edge_entry.get("corridor_arrival_node_id", to_node_id)),
			"corridor_departure_sector_id": String(edge_entry.get("corridor_departure_sector_id", "")),
			"corridor_arrival_sector_id": String(edge_entry.get("corridor_arrival_sector_id", "")),
			"is_history": bool(edge_entry.get("is_history", false)),
			"is_reconnect_edge": bool(edge_entry.get("is_reconnect_edge", false)),
		})
	return path_surfaces


func _build_render_model_junctions(visible_nodes: Array, path_surfaces: Array[Dictionary]) -> Array[Dictionary]:
	var surface_links_by_node_id: Dictionary = _build_render_surface_links_by_node_id(path_surfaces)
	var junctions: Array[Dictionary] = []
	for node_variant in visible_nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var link_entry: Dictionary = surface_links_by_node_id.get(node_id, {})
		var connected_surface_ids: Array = link_entry.get("surface_ids", [])
		if connected_surface_ids.is_empty():
			continue
		junctions.append({
			"junction_id": "junction:%d" % node_id,
			"node_id": node_id,
			"center": Vector2(node_entry.get("world_position", Vector2.ZERO)),
			"junction_radius": maxf(18.0, float(node_entry.get("clearing_radius", 0.0)) * 0.82),
			"junction_role": _render_junction_role(node_entry, connected_surface_ids.size()),
			"connected_surface_ids": connected_surface_ids.duplicate(true),
			"throat_ids": (link_entry.get("throat_ids", []) as Array).duplicate(true),
			"cardinal_directions": (link_entry.get("cardinal_directions", []) as Array).duplicate(true),
			"endpoint_points": (link_entry.get("endpoint_points", []) as Array).duplicate(true),
		})
	return junctions


func _build_render_model_clearing_surfaces(visible_nodes: Array, path_surfaces: Array[Dictionary]) -> Array[Dictionary]:
	var surface_links_by_node_id: Dictionary = _build_render_surface_links_by_node_id(path_surfaces)
	var clearing_surfaces: Array[Dictionary] = []
	for node_variant in visible_nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var link_entry: Dictionary = surface_links_by_node_id.get(node_id, {})
		clearing_surfaces.append({
			"surface_id": "clearing:%d" % node_id,
			"node_id": node_id,
			"node_family": String(node_entry.get("node_family", "")),
			"node_state": String(node_entry.get("node_state", "")),
			"state_semantic": String(node_entry.get("state_semantic", "open")),
			"shape": "clearing_disc",
			"center": Vector2(node_entry.get("world_position", Vector2.ZERO)),
			"radius": float(node_entry.get("clearing_radius", 0.0)),
			"connected_path_surface_ids": (link_entry.get("surface_ids", []) as Array).duplicate(true),
			"road_endpoint_points": (link_entry.get("endpoint_points", []) as Array).duplicate(true),
			"entry_throat_ids": (link_entry.get("throat_ids", []) as Array).duplicate(true),
			"is_current": bool(node_entry.get("is_current", false)),
			"is_adjacent": bool(node_entry.get("is_adjacent", false)),
		})
	return clearing_surfaces


func _build_render_surface_links_by_node_id(path_surfaces: Array[Dictionary]) -> Dictionary:
	var links_by_node_id: Dictionary = {}
	for surface_entry in path_surfaces:
		var surface_id: String = String(surface_entry.get("surface_id", ""))
		var throat_id: String = String(surface_entry.get("corridor_throat_id", ""))
		var cardinal_direction: String = String(surface_entry.get("cardinal_direction", ""))
		_append_render_surface_link(
			links_by_node_id,
			int(surface_entry.get("from_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)),
			surface_id,
			throat_id,
			cardinal_direction,
			Vector2(surface_entry.get("from_endpoint", Vector2.ZERO))
		)
		_append_render_surface_link(
			links_by_node_id,
			int(surface_entry.get("to_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)),
			surface_id,
			throat_id,
			cardinal_direction,
			Vector2(surface_entry.get("to_endpoint", Vector2.ZERO))
		)
	return links_by_node_id


func _append_render_surface_link(
	links_by_node_id: Dictionary,
	node_id: int,
	surface_id: String,
	throat_id: String,
	cardinal_direction: String,
	endpoint_point: Vector2
) -> void:
	if node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID or surface_id.is_empty():
		return
	var link_entry: Dictionary = links_by_node_id.get(node_id, {
		"surface_ids": [],
		"throat_ids": [],
		"cardinal_directions": [],
		"endpoint_points": [],
	})
	_append_unique_string(link_entry["surface_ids"], surface_id)
	_append_unique_string(link_entry["throat_ids"], throat_id)
	_append_unique_string(link_entry["cardinal_directions"], cardinal_direction)
	var endpoint_points: Array = link_entry.get("endpoint_points", [])
	endpoint_points.append(endpoint_point)
	link_entry["endpoint_points"] = endpoint_points
	links_by_node_id[node_id] = link_entry


func _render_path_surface_width_for_role(corridor_role: String) -> float:
	return float(RENDER_PATH_SURFACE_WIDTH_BY_ROLE.get(corridor_role, 18.0))


func _render_path_surface_id(from_node_id: int, to_node_id: int) -> String:
	return "path:%s" % _edge_key(from_node_id, to_node_id)


func _render_path_outward_route_hint(edge_entry: Dictionary, cardinal_direction: String) -> String:
	if cardinal_direction.is_empty():
		return ""
	if bool(edge_entry.get("is_reconnect_edge", false)):
		return "reconnect_%s" % cardinal_direction
	if bool(edge_entry.get("is_history", false)):
		return "history_%s" % cardinal_direction
	return "outward_%s" % cardinal_direction


func _render_junction_role(node_entry: Dictionary, connected_surface_count: int) -> String:
	if bool(node_entry.get("is_current", false)) and connected_surface_count > 1:
		return "local_choice_blend"
	if bool(node_entry.get("is_adjacent", false)):
		return "branch_throat"
	if connected_surface_count > 1:
		return "history_or_reconnect_blend"
	return "path_endpoint"


func _duplicate_packed_vector2_array(points: PackedVector2Array) -> PackedVector2Array:
	var duplicated_points := PackedVector2Array()
	for point in points:
		duplicated_points.append(point)
	return duplicated_points


func _append_unique_string(values: Array, value: String) -> void:
	if value.is_empty() or values.has(value):
		return
	values.append(value)


func _build_layout_graph_snapshot(map_runtime_state: RefCounted) -> Array[Dictionary]:
	var layout_graph_snapshot: Array[Dictionary] = []
	if map_runtime_state.has_method("build_layout_graph_snapshots"):
		var layout_snapshot_variant: Variant = map_runtime_state.call("build_layout_graph_snapshots")
		if typeof(layout_snapshot_variant) == TYPE_ARRAY:
			for entry_variant in layout_snapshot_variant:
				if typeof(entry_variant) != TYPE_DICTIONARY:
					continue
				layout_graph_snapshot.append((entry_variant as Dictionary).duplicate(true))
	if not layout_graph_snapshot.is_empty():
		return layout_graph_snapshot
	return map_runtime_state.build_realized_graph_snapshots()


func _index_graph_snapshot(graph_snapshot: Array[Dictionary]) -> Dictionary:
	var graph_by_id: Dictionary = {}
	for node_entry in graph_snapshot:
		graph_by_id[int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))] = node_entry.duplicate(true)
	return graph_by_id
func _resolve_start_node_id(graph_snapshot: Array[Dictionary]) -> int:
	for node_entry in graph_snapshot:
		if String(node_entry.get("node_family", "")) == "start":
			return int(node_entry.get("node_id", 0))
	return 0
func _build_depth_by_node_id(graph_by_id: Dictionary, start_node_id: int) -> Dictionary:
	var depth_by_node_id: Dictionary = {start_node_id: 0}
	var open_node_ids: Array[int] = [start_node_id]
	while not open_node_ids.is_empty():
		var node_id: int = open_node_ids.pop_front()
		var node_depth: int = int(depth_by_node_id.get(node_id, 0))
		var adjacent_node_ids: PackedInt32Array = _adjacent_ids_for(graph_by_id, node_id)
		for adjacent_node_id in adjacent_node_ids:
			if depth_by_node_id.has(adjacent_node_id):
				continue
			depth_by_node_id[adjacent_node_id] = node_depth + 1
			open_node_ids.append(adjacent_node_id)
	return depth_by_node_id
func _build_layout_context(
	graph_snapshot: Array[Dictionary],
	graph_by_id: Dictionary,
	depth_by_node_id: Dictionary,
	start_node_id: int,
	template_profile: String,
	board_seed: int
) -> Dictionary:
	var parent_ids_by_node_id: Dictionary = _build_parent_ids_by_node_id(graph_by_id, depth_by_node_id)
	var primary_parent_by_node_id: Dictionary = _build_primary_parent_by_node_id(parent_ids_by_node_id)
	var branch_root_by_node_id: Dictionary = _build_branch_root_by_node_id(
		graph_snapshot,
		depth_by_node_id,
		start_node_id,
		primary_parent_by_node_id
	)
	var sector_by_node_id: Dictionary = _build_string_field_by_node_id(graph_snapshot, "sector_id")
	var route_role_by_node_id: Dictionary = _build_string_field_by_node_id(graph_snapshot, "route_role")
	return {
		"start_node_id": start_node_id,
		"depth_by_node_id": depth_by_node_id,
		"degree_by_node_id": _build_degree_by_node_id(graph_by_id),
		"parent_ids_by_node_id": parent_ids_by_node_id,
		"primary_parent_by_node_id": primary_parent_by_node_id,
		"branch_root_by_node_id": branch_root_by_node_id,
		"child_ids_by_parent": _build_child_ids_by_parent(primary_parent_by_node_id),
		"branch_direction_by_root": _build_branch_direction_by_root(graph_by_id, start_node_id, template_profile, board_seed),
		"sector_by_node_id": sector_by_node_id,
		"route_role_by_node_id": route_role_by_node_id,
		"orientation_profile_id": _first_string_field_value(graph_snapshot, "orientation_profile_id"),
		"topology_blueprint_id": _first_string_field_value(graph_snapshot, "topology_blueprint_id"),
		"max_depth": _max_depth_from_values(depth_by_node_id.values()),
	}


func _build_string_field_by_node_id(graph_snapshot: Array[Dictionary], field_name: String) -> Dictionary:
	var field_by_node_id: Dictionary = {}
	for node_entry in graph_snapshot:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var field_value: String = String(node_entry.get(field_name, ""))
		if node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID or field_value.is_empty():
			continue
		field_by_node_id[node_id] = field_value
	return field_by_node_id


func _first_string_field_value(graph_snapshot: Array[Dictionary], field_name: String) -> String:
	for node_entry in graph_snapshot:
		var field_value: String = String(node_entry.get(field_name, ""))
		if not field_value.is_empty():
			return field_value
	return ""


func _build_degree_by_node_id(graph_by_id: Dictionary) -> Dictionary:
	var degree_by_node_id: Dictionary = {}
	for node_id_variant in graph_by_id.keys():
		var node_id: int = int(node_id_variant)
		degree_by_node_id[node_id] = _adjacent_ids_for(graph_by_id, node_id).size()
	return degree_by_node_id
func _build_parent_ids_by_node_id(graph_by_id: Dictionary, depth_by_node_id: Dictionary) -> Dictionary:
	var parent_ids_by_node_id: Dictionary = {}
	for node_id_variant in graph_by_id.keys():
		var node_id: int = int(node_id_variant)
		var node_depth: int = int(depth_by_node_id.get(node_id, 0))
		var parent_ids: Array[int] = []
		for adjacent_node_id in _adjacent_ids_for(graph_by_id, node_id):
			if int(depth_by_node_id.get(adjacent_node_id, -1)) == node_depth - 1:
				parent_ids.append(adjacent_node_id)
		parent_ids.sort()
		parent_ids_by_node_id[node_id] = parent_ids
	return parent_ids_by_node_id
func _build_primary_parent_by_node_id(parent_ids_by_node_id: Dictionary) -> Dictionary:
	var primary_parent_by_node_id: Dictionary = {}
	for node_id_variant in parent_ids_by_node_id.keys():
		var node_id: int = int(node_id_variant)
		var parent_ids: Array[int] = _int_array_from_variant(parent_ids_by_node_id.get(node_id, []))
		if parent_ids.is_empty():
			continue
		primary_parent_by_node_id[node_id] = parent_ids[0]
	return primary_parent_by_node_id
func _build_branch_root_by_node_id(
	graph_snapshot: Array[Dictionary],
	depth_by_node_id: Dictionary,
	start_node_id: int,
	primary_parent_by_node_id: Dictionary
) -> Dictionary:
	var branch_root_by_node_id: Dictionary = {start_node_id: start_node_id}
	for node_entry in graph_snapshot:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var node_depth: int = int(depth_by_node_id.get(node_id, 0))
		if node_depth <= 0:
			continue
		if node_depth == 1:
			branch_root_by_node_id[node_id] = node_id
			continue
		var walker_id: int = int(primary_parent_by_node_id.get(node_id, start_node_id))
		while int(depth_by_node_id.get(walker_id, 0)) > 1:
			walker_id = int(primary_parent_by_node_id.get(walker_id, start_node_id))
		branch_root_by_node_id[node_id] = walker_id
	return branch_root_by_node_id
func _build_child_ids_by_parent(primary_parent_by_node_id: Dictionary) -> Dictionary:
	var child_ids_by_parent: Dictionary = {}
	var sorted_node_ids: Array[int] = []
	for node_id_variant in primary_parent_by_node_id.keys():
		sorted_node_ids.append(int(node_id_variant))
	sorted_node_ids.sort()
	for node_id in sorted_node_ids:
		var parent_id: int = int(primary_parent_by_node_id.get(node_id, MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if not child_ids_by_parent.has(parent_id):
			child_ids_by_parent[parent_id] = []
		var child_ids: Array[int] = _int_array_from_variant(child_ids_by_parent.get(parent_id, []))
		child_ids.append(node_id)
		child_ids_by_parent[parent_id] = child_ids
	return child_ids_by_parent
func _build_branch_direction_by_root(
	graph_by_id: Dictionary,
	start_node_id: int,
	template_profile: String,
	board_seed: int
) -> Dictionary:
	var branch_root_ids: Array[int] = _sorted_adjacent_ids(graph_by_id, start_node_id)
	var branch_angles: Array[float] = _branch_angles_for_count(branch_root_ids.size())
	var branch_direction_by_root: Dictionary = {}
	var profile_rotation: float = 0.0
	var rotation_rng := RandomNumberGenerator.new()
	rotation_rng.seed = _derive_seed(board_seed, "branch-global-rotation")
	var global_rotation: float = rotation_rng.randf_range(-BRANCH_GLOBAL_ROTATION_RANGE, BRANCH_GLOBAL_ROTATION_RANGE)
	match template_profile:
		"corridor":
			profile_rotation = -0.04
		"openfield":
			profile_rotation = 0.03
		"loop":
			profile_rotation = 0.01
	for index in range(branch_root_ids.size()):
		var branch_root_id: int = branch_root_ids[index]
		var base_angle: float = branch_angles[index] if index < branch_angles.size() else lerpf(-2.74, -0.40, float(index) / float(max(1, branch_root_ids.size() - 1)))
		var branch_rng := RandomNumberGenerator.new()
		branch_rng.seed = _derive_seed(board_seed, "branch-angle:%d" % branch_root_id)
		var angle: float = wrapf(base_angle + global_rotation + profile_rotation + branch_rng.randf_range(-BRANCH_ANGLE_NOISE, BRANCH_ANGLE_NOISE), -PI, PI)
		branch_direction_by_root[branch_root_id] = Vector2(cos(angle), sin(angle)).normalized()
	return branch_direction_by_root
func _branch_angles_for_count(branch_count: int) -> Array[float]:
	if OPENING_BRANCH_ANGLE_PRESETS.has(branch_count):
		var preset_angles: Array = OPENING_BRANCH_ANGLE_PRESETS[branch_count]
		var typed_angles: Array[float] = []
		for angle_value in preset_angles:
			typed_angles.append(float(angle_value))
		return typed_angles
	var angles: Array[float] = []
	for index in range(branch_count):
		var t: float = 0.5 if branch_count <= 1 else float(index) / float(branch_count - 1)
		angles.append(lerpf(-2.72, -0.42, t))
	return angles
func _build_world_positions(
	graph_snapshot: Array[Dictionary],
	board_size: Vector2,
	layout_context: Dictionary,
	template_profile: String,
	board_seed: int
) -> Dictionary:
	return MapBoardLayoutSolverScript.build_world_positions(
		graph_snapshot,
		board_size,
		layout_context,
		template_profile,
		board_seed,
		{
			"base_center_factor": BASE_CENTER_FACTOR,
			"playable_rect": build_playable_rect(board_size),
			"min_board_margin": build_playable_margin(),
			"depth_step_factors": DEPTH_STEP_FACTORS,
			"depth_spread_factors": DEPTH_SPREAD_FACTORS,
			"depth_direction_pull_factors": DEPTH_DIRECTION_PULL_FACTORS,
			"depth_lateral_spread_scale_factors": DEPTH_LATERAL_SPREAD_SCALE_FACTORS,
			"depth_downward_bias_factors": DEPTH_DOWNWARD_BIAS_FACTORS,
			"depth_center_pull_factors": DEPTH_CENTER_PULL_FACTORS,
			"depth_sector_pull_factors": DEPTH_SECTOR_PULL_FACTORS,
			"depth_sector_horizontal_factors": DEPTH_SECTOR_HORIZONTAL_FACTORS,
			"depth_sector_vertical_factors": DEPTH_SECTOR_VERTICAL_FACTORS,
			"depth_outer_pocket_pull_factors": DEPTH_OUTER_POCKET_PULL_FACTORS,
			"depth_outer_pocket_horizontal_factors": DEPTH_OUTER_POCKET_HORIZONTAL_FACTORS,
			"depth_outer_pocket_vertical_factors": DEPTH_OUTER_POCKET_VERTICAL_FACTORS,
			"depth_sibling_radial_stagger_factors": DEPTH_SIBLING_RADIAL_STAGGER_FACTORS,
			"depth_top_edge_relief_factors": DEPTH_TOP_EDGE_RELIEF_FACTORS,
			"clearing_radius_by_node_id": _build_open_clearing_radius_by_node_id(graph_snapshot, board_size),
		}
	)
func _build_open_clearing_radius_by_node_id(graph_snapshot: Array[Dictionary], board_size: Vector2) -> Dictionary:
	var clearing_radius_by_node_id: Dictionary = {}
	for node_entry in graph_snapshot:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		clearing_radius_by_node_id[node_id] = _clearing_radius_for(String(node_entry.get("node_family", "")), "open", board_size)
	return clearing_radius_by_node_id
func _int_array_from_variant(value: Variant) -> Array[int]:
	return MapBoardLayoutSolverScript.int_array_from_variant(value)
func _branch_direction_for_root(layout_context: Dictionary, branch_root_id: int) -> Vector2:
	return MapBoardLayoutSolverScript.branch_direction_for_root(layout_context, branch_root_id)


func _max_depth_from_values(depth_values: Array) -> int:
	var max_depth: int = 0
	for depth_value in depth_values:
		max_depth = max(max_depth, int(depth_value))
	return max_depth


func _average_vector2_array(values: Array[Vector2]) -> Vector2:
	if values.is_empty():
		return Vector2.ZERO
	var total: Vector2 = Vector2.ZERO
	for value in values:
		total += value
	return total / float(values.size())


func _stable_layout_matches_board_size(world_positions: Dictionary, start_node_id: int, board_size: Vector2) -> bool:
	if world_positions.is_empty():
		return false
	var start_position: Vector2 = world_positions.get(start_node_id, Vector2.ZERO)
	if start_position == Vector2.ZERO:
		return false
	var expected_origin: Vector2 = build_center_anchor_position(board_size)
	return start_position.distance_to(expected_origin) <= STABLE_LAYOUT_REUSE_POSITION_TOLERANCE


func _build_visible_node_entries(
	graph_snapshot: Array[Dictionary],
	graph_by_id: Dictionary,
	world_positions: Dictionary,
	current_node_id: int,
	board_size: Vector2
) -> Array[Dictionary]:
	var visible_nodes: Array[Dictionary] = []
	var current_adjacent_ids: PackedInt32Array = _adjacent_ids_for(graph_by_id, current_node_id)
	for node_entry in graph_snapshot:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var node_state: String = String(node_entry.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
		var is_current: bool = node_id == current_node_id
		if not is_current and node_state == MapRuntimeStateScript.NODE_STATE_UNDISCOVERED:
			continue
		var node_family: String = String(node_entry.get("node_family", ""))
		var is_adjacent: bool = current_adjacent_ids.has(node_id)
		var state_semantic: String = _semantic_for_node(node_state, is_current)
		var world_position: Vector2 = world_positions.get(node_id, board_size * BASE_CENTER_FACTOR)
		visible_nodes.append({
			"node_id": node_id,
			"node_family": node_family,
			"node_state": node_state,
			"state_semantic": state_semantic,
			"is_current": is_current,
			"is_adjacent": is_adjacent,
			"show_known_icon": node_state != MapRuntimeStateScript.NODE_STATE_UNDISCOVERED or is_current,
			"icon_texture_path": _icon_texture_path_for_family(node_family),
			"world_position": world_position,
			"clearing_radius": _clearing_radius_for(node_family, state_semantic, board_size),
		})
	visible_nodes.sort_custom(Callable(self, "_sort_visible_node_entries"))
	return visible_nodes


func _decorate_node_entries_with_landmark_footprints(
	node_entries: Array[Dictionary],
	edge_entries: Array[Dictionary],
	board_seed: int,
	board_size: Vector2
) -> Array[Dictionary]:
	var route_vectors_by_node_id: Dictionary = _build_visible_route_vectors_by_node_id(node_entries, edge_entries)
	var decorated_nodes: Array[Dictionary] = []
	for node_entry in node_entries:
		var decorated_entry: Dictionary = node_entry.duplicate(true)
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var route_vectors: Array = route_vectors_by_node_id.get(node_id, [])
		decorated_entry["landmark_footprint"] = _build_landmark_footprint_for_node(
			node_entry,
			route_vectors,
			board_seed,
			board_size
		)
		decorated_nodes.append(decorated_entry)
	return decorated_nodes


func _build_visible_route_vectors_by_node_id(
	visible_nodes: Array[Dictionary],
	visible_edges: Array[Dictionary]
) -> Dictionary:
	var route_vectors_by_node_id: Dictionary = {}
	for node_entry in visible_nodes:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		route_vectors_by_node_id[node_id] = []
	for edge_entry in visible_edges:
		var from_node_id: int = int(edge_entry.get("from_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var to_node_id: int = int(edge_entry.get("to_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var edge_points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
		if edge_points.size() < 2:
			continue
		var from_route_vectors: Array = route_vectors_by_node_id.get(from_node_id, [])
		var from_vector: Vector2 = edge_points[1] - edge_points[0]
		if from_vector.length_squared() > 0.001:
			from_route_vectors.append(from_vector.normalized())
			route_vectors_by_node_id[from_node_id] = from_route_vectors
		var to_route_vectors: Array = route_vectors_by_node_id.get(to_node_id, [])
		var to_vector: Vector2 = edge_points[edge_points.size() - 2] - edge_points[edge_points.size() - 1]
		if to_vector.length_squared() > 0.001:
			to_route_vectors.append(to_vector.normalized())
			route_vectors_by_node_id[to_node_id] = to_route_vectors
	return route_vectors_by_node_id


func _build_landmark_footprint_for_node(
	node_entry: Dictionary,
	route_vectors: Array,
	board_seed: int,
	board_size: Vector2
) -> Dictionary:
	var node_family: String = String(node_entry.get("node_family", ""))
	var state_semantic: String = String(node_entry.get("state_semantic", "open"))
	var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var clearing_radius: float = float(node_entry.get("clearing_radius", _clearing_radius_for(node_family, state_semantic, board_size)))
	if clearing_radius <= 0.0:
		return {}
	var landmark_seed: int = _derive_seed(board_seed, "landmark_%d_%s" % [node_id, node_family])
	var route_pull: Vector2 = Vector2.ZERO
	for route_vector_variant in route_vectors:
		if typeof(route_vector_variant) != TYPE_VECTOR2:
			continue
		route_pull += Vector2(route_vector_variant)
	if route_pull.length_squared() <= 0.001 and not route_vectors.is_empty() and typeof(route_vectors[0]) == TYPE_VECTOR2:
		route_pull = Vector2(route_vectors[0])
	if route_pull.length_squared() <= 0.001:
		var fallback_angle: float = float(abs(landmark_seed % 628)) / 100.0
		route_pull = Vector2.RIGHT.rotated(fallback_angle)
	var route_anchor_direction: Vector2 = (-route_pull).normalized()
	if route_anchor_direction.length_squared() <= 0.001:
		route_anchor_direction = Vector2.UP
	var route_lateral_direction: Vector2 = route_anchor_direction.orthogonal().normalized()
	var pocket_rotation_degrees: float = rad_to_deg(route_lateral_direction.angle())
	var resolved_scale: float = 0.92 if state_semantic == "resolved" else 1.0
	var current_scale: float = 1.04 if bool(node_entry.get("is_current", false)) else 1.0

	var footprint := {
		"route_anchor_direction": route_anchor_direction,
		"route_lateral_direction": route_lateral_direction,
		"pocket_shape": "ellipse",
		"pocket_center_offset": route_anchor_direction * clearing_radius * 0.34,
		"pocket_half_size": Vector2(clearing_radius * 1.46, clearing_radius * 1.08) * resolved_scale * current_scale,
		"pocket_rotation_degrees": pocket_rotation_degrees,
		"pocket_arrival_grammar": "stone_arrival",
		"landmark_shape": "standing_stone",
		"landmark_center_offset": route_anchor_direction * clearing_radius * 0.62,
		"landmark_half_size": Vector2(clearing_radius * 0.26, clearing_radius * 0.38) * resolved_scale,
		"landmark_rotation_degrees": pocket_rotation_degrees,
		"signage_shape": "round_badge",
		"signage_center_offset": route_anchor_direction * clearing_radius * 0.18 + route_lateral_direction * clearing_radius * 0.44,
		"signage_scale": 0.72,
	}

	match node_family:
		"combat":
			footprint["pocket_shape"] = "ellipse"
			footprint["pocket_center_offset"] = route_anchor_direction * clearing_radius * 0.38 + route_lateral_direction * clearing_radius * 0.08
			footprint["pocket_half_size"] = Vector2(clearing_radius * 1.54, clearing_radius * 1.10) * resolved_scale * current_scale
			footprint["pocket_arrival_grammar"] = "combat_stakes_arrival"
			footprint["landmark_shape"] = "crossed_stakes"
			footprint["landmark_center_offset"] = route_anchor_direction * clearing_radius * 0.66
			footprint["landmark_half_size"] = Vector2(clearing_radius * 0.44, clearing_radius * 0.30) * resolved_scale
			footprint["signage_shape"] = "round_badge"
			footprint["signage_center_offset"] = route_anchor_direction * clearing_radius * 0.14 + route_lateral_direction * clearing_radius * 0.54
			footprint["signage_scale"] = 0.56
		"reward":
			footprint["pocket_shape"] = "rect"
			footprint["pocket_center_offset"] = route_anchor_direction * clearing_radius * 0.28 + route_lateral_direction * clearing_radius * 0.04
			footprint["pocket_half_size"] = Vector2(clearing_radius * 1.30, clearing_radius * 0.92) * resolved_scale * current_scale
			footprint["pocket_arrival_grammar"] = "cache_slab_arrival"
			footprint["landmark_shape"] = "cache_slab"
			footprint["landmark_center_offset"] = route_anchor_direction * clearing_radius * 0.52
			footprint["landmark_half_size"] = Vector2(clearing_radius * 0.48, clearing_radius * 0.28) * resolved_scale
			footprint["signage_shape"] = "tab"
			footprint["signage_center_offset"] = route_anchor_direction * clearing_radius * 0.12 + route_lateral_direction * clearing_radius * 0.46
			footprint["signage_scale"] = 0.54
		"event":
			footprint["pocket_shape"] = "ellipse"
			footprint["pocket_center_offset"] = route_anchor_direction * clearing_radius * 0.32
			footprint["pocket_half_size"] = Vector2(clearing_radius * 1.42, clearing_radius * 1.04) * resolved_scale * current_scale
			footprint["pocket_arrival_grammar"] = "standing_stone_arrival"
			footprint["landmark_shape"] = "standing_stone"
			footprint["landmark_center_offset"] = route_anchor_direction * clearing_radius * 0.60
			footprint["landmark_half_size"] = Vector2(clearing_radius * 0.24, clearing_radius * 0.42) * resolved_scale
			footprint["signage_shape"] = "tab"
			footprint["signage_center_offset"] = route_anchor_direction * clearing_radius * 0.12 - route_lateral_direction * clearing_radius * 0.40
			footprint["signage_scale"] = 0.66
		"hamlet":
			footprint["pocket_shape"] = "rect"
			footprint["pocket_center_offset"] = route_anchor_direction * clearing_radius * 0.26
			footprint["pocket_half_size"] = Vector2(clearing_radius * 1.34, clearing_radius * 0.90) * resolved_scale * current_scale
			footprint["pocket_arrival_grammar"] = "waypost_arrival"
			footprint["landmark_shape"] = "waypost"
			footprint["landmark_center_offset"] = route_anchor_direction * clearing_radius * 0.56 - route_lateral_direction * clearing_radius * 0.20
			footprint["landmark_half_size"] = Vector2(clearing_radius * 0.38, clearing_radius * 0.42) * resolved_scale
			footprint["signage_shape"] = "tab"
			footprint["signage_center_offset"] = route_anchor_direction * clearing_radius * 0.10 + route_lateral_direction * clearing_radius * 0.50
			footprint["signage_scale"] = 0.52
		"rest":
			footprint["pocket_shape"] = "ellipse"
			footprint["pocket_center_offset"] = route_anchor_direction * clearing_radius * 0.30
			footprint["pocket_half_size"] = Vector2(clearing_radius * 1.36, clearing_radius * 0.98) * resolved_scale * current_scale
			footprint["pocket_arrival_grammar"] = "campfire_arrival"
			footprint["landmark_shape"] = "campfire"
			footprint["landmark_center_offset"] = route_anchor_direction * clearing_radius * 0.44
			footprint["landmark_half_size"] = Vector2(clearing_radius * 0.46, clearing_radius * 0.32) * resolved_scale
			footprint["signage_shape"] = "round_badge"
			footprint["signage_center_offset"] = route_anchor_direction * clearing_radius * 0.08 + route_lateral_direction * clearing_radius * 0.48
			footprint["signage_scale"] = 0.52
		"merchant":
			footprint["pocket_shape"] = "rect"
			footprint["pocket_center_offset"] = route_anchor_direction * clearing_radius * 0.24
			footprint["pocket_half_size"] = Vector2(clearing_radius * 1.42, clearing_radius * 0.92) * resolved_scale * current_scale
			footprint["pocket_arrival_grammar"] = "market_stall_arrival"
			footprint["landmark_shape"] = "stall"
			footprint["landmark_center_offset"] = route_anchor_direction * clearing_radius * 0.54
			footprint["landmark_half_size"] = Vector2(clearing_radius * 0.52, clearing_radius * 0.32) * resolved_scale
			footprint["signage_shape"] = "tab"
			footprint["signage_center_offset"] = route_anchor_direction * clearing_radius * 0.10 - route_lateral_direction * clearing_radius * 0.50
			footprint["signage_scale"] = 0.50
		"blacksmith":
			footprint["pocket_shape"] = "rect"
			footprint["pocket_center_offset"] = route_anchor_direction * clearing_radius * 0.26
			footprint["pocket_half_size"] = Vector2(clearing_radius * 1.40, clearing_radius * 0.94) * resolved_scale * current_scale
			footprint["pocket_arrival_grammar"] = "forge_hearth_arrival"
			footprint["landmark_shape"] = "forge"
			footprint["landmark_center_offset"] = route_anchor_direction * clearing_radius * 0.58
			footprint["landmark_half_size"] = Vector2(clearing_radius * 0.48, clearing_radius * 0.34) * resolved_scale
			footprint["signage_shape"] = "tab"
			footprint["signage_center_offset"] = route_anchor_direction * clearing_radius * 0.10 + route_lateral_direction * clearing_radius * 0.48
			footprint["signage_scale"] = 0.50
		"key":
			footprint["pocket_shape"] = "diamond"
			footprint["pocket_center_offset"] = route_anchor_direction * clearing_radius * 0.34
			footprint["pocket_half_size"] = Vector2(clearing_radius * 1.42, clearing_radius * 1.16) * resolved_scale * current_scale
			footprint["pocket_arrival_grammar"] = "key_shrine_arrival"
			footprint["landmark_shape"] = "shrine"
			footprint["landmark_center_offset"] = route_anchor_direction * clearing_radius * 0.68
			footprint["landmark_half_size"] = Vector2(clearing_radius * 0.36, clearing_radius * 0.52) * resolved_scale
			footprint["signage_shape"] = "round_badge"
			footprint["signage_center_offset"] = route_anchor_direction * clearing_radius * 0.12 + route_lateral_direction * clearing_radius * 0.42
			footprint["signage_scale"] = 0.48
		"boss":
			footprint["pocket_shape"] = "rect"
			footprint["pocket_center_offset"] = route_anchor_direction * clearing_radius * 0.40
			footprint["pocket_half_size"] = Vector2(clearing_radius * 1.92, clearing_radius * 1.24) * resolved_scale * current_scale
			footprint["pocket_arrival_grammar"] = "boss_gate_arrival"
			footprint["landmark_shape"] = "gate"
			footprint["landmark_center_offset"] = route_anchor_direction * clearing_radius * 0.78
			footprint["landmark_half_size"] = Vector2(clearing_radius * 0.72, clearing_radius * 0.48) * resolved_scale
			footprint["signage_shape"] = "tab"
			footprint["signage_center_offset"] = route_anchor_direction * clearing_radius * 0.16 + route_lateral_direction * clearing_radius * 0.48
			footprint["signage_scale"] = 0.46
	footprint["pocket_rotation_degrees"] = rad_to_deg(route_lateral_direction.angle())
	footprint["landmark_rotation_degrees"] = footprint.get("pocket_rotation_degrees", 0.0)
	return footprint
func _build_visible_edges(
	layout_edges: Array,
	visible_nodes: Array[Dictionary],
	current_node_id: int,
	layout_context: Dictionary,
	board_size: Vector2
) -> Array[Dictionary]:
	var visible_node_ids: Dictionary = {}
	var visible_node_by_id: Dictionary = {}
	for node_entry in visible_nodes:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		visible_node_ids[node_id] = true
		visible_node_by_id[node_id] = node_entry

	var history_edges: Array[Dictionary] = []
	var local_focus_edges: Array[Dictionary] = []
	for edge_variant in layout_edges:
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var base_edge: Dictionary = edge_variant
		var from_node_id: int = int(base_edge.get("from_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var to_node_id: int = int(base_edge.get("to_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if not visible_node_ids.has(from_node_id) or not visible_node_ids.has(to_node_id):
			continue
		var from_node: Dictionary = visible_node_by_id.get(from_node_id, {})
		var to_node: Dictionary = visible_node_by_id.get(to_node_id, {})
		var is_local_focus_edge: bool = from_node_id == current_node_id or to_node_id == current_node_id
		if not is_local_focus_edge and not _should_show_history_edge(from_node, to_node):
			continue
		var edge_points: PackedVector2Array = base_edge.get("points", PackedVector2Array())
		if not is_local_focus_edge and (
			MapBoardGeometryScript.polyline_hits_other_visible_nodes(
				edge_points,
				from_node_id,
				to_node_id,
				visible_nodes,
				EDGE_NODE_AVOIDANCE_PADDING
			)
			or not MapBoardGeometryScript.polyline_stays_inside_rect(edge_points, build_path_safe_rect(board_size), 1.0)
		):
			continue
		var edge_entry: Dictionary = base_edge.duplicate(true)
		var departure_node_id: int = from_node_id
		var arrival_node_id: int = to_node_id
		if is_local_focus_edge:
			departure_node_id = current_node_id
			arrival_node_id = to_node_id if from_node_id == current_node_id else from_node_id
		_decorate_visible_edge_corridor_metadata(
			edge_entry,
			departure_node_id,
			arrival_node_id,
			visible_node_by_id,
			layout_context
		)
		edge_entry["state_semantic"] = _edge_semantic_for(from_node, to_node)
		edge_entry["is_history"] = not is_local_focus_edge
		edge_entry["is_local_actionable"] = is_local_focus_edge
		if is_local_focus_edge:
			local_focus_edges.append(edge_entry)
		else:
			history_edges.append(edge_entry)
	var primary_actionable_edge_key: String = _select_primary_actionable_edge_key(local_focus_edges, current_node_id, layout_context)
	_assign_visible_edge_corridor_roles(local_focus_edges, history_edges, current_node_id, primary_actionable_edge_key, layout_context)
	var filtered_history_edges: Array[Dictionary] = MapBoardHistoryEdgeFilterScript.filter_non_crossing_history_edges(local_focus_edges, history_edges)
	var visible_edges: Array[Dictionary] = filtered_history_edges + local_focus_edges
	visible_edges.sort_custom(func(left_edge: Dictionary, right_edge: Dictionary) -> bool:
		var left_priority: int = int(left_edge.get("corridor_draw_priority", 0))
		var right_priority: int = int(right_edge.get("corridor_draw_priority", 0))
		if left_priority != right_priority:
			return left_priority < right_priority
		return MapBoardGeometryScript.compare_visible_edge_priority(left_edge, right_edge)
	)
	return visible_edges


func _decorate_visible_edge_corridor_metadata(
	edge_entry: Dictionary,
	departure_node_id: int,
	arrival_node_id: int,
	visible_node_by_id: Dictionary,
	layout_context: Dictionary
) -> void:
	var departure_node: Dictionary = visible_node_by_id.get(departure_node_id, {})
	var arrival_node: Dictionary = visible_node_by_id.get(arrival_node_id, {})
	var departure_position: Vector2 = Vector2(departure_node.get("world_position", Vector2.ZERO))
	var arrival_position: Vector2 = Vector2(arrival_node.get("world_position", Vector2.ZERO))
	var departure_sector_id: String = _sector_id_for_corridor_node(departure_node_id, layout_context)
	var arrival_sector_id: String = _sector_id_for_corridor_node(arrival_node_id, layout_context)
	var cardinal_direction: String = _corridor_cardinal_direction_for_delta(arrival_position - departure_position)
	edge_entry["corridor_departure_node_id"] = departure_node_id
	edge_entry["corridor_arrival_node_id"] = arrival_node_id
	edge_entry["corridor_departure_sector_id"] = departure_sector_id
	edge_entry["corridor_arrival_sector_id"] = arrival_sector_id
	edge_entry["corridor_cardinal_direction"] = cardinal_direction
	edge_entry["corridor_throat_id"] = _corridor_throat_id(
		departure_node_id,
		arrival_node_id,
		departure_sector_id,
		arrival_sector_id,
		cardinal_direction
	)


func _sector_id_for_corridor_node(node_id: int, layout_context: Dictionary) -> String:
	var slot_anchor_sector_by_node_id: Dictionary = layout_context.get("slot_anchor_sector_by_node_id", {})
	var slot_sector_id: String = String(slot_anchor_sector_by_node_id.get(node_id, ""))
	if not slot_sector_id.is_empty():
		return slot_sector_id
	var sector_by_node_id: Dictionary = layout_context.get("sector_by_node_id", {})
	return String(sector_by_node_id.get(node_id, ""))


func _corridor_cardinal_direction_for_delta(delta: Vector2) -> String:
	if delta.length_squared() <= 0.001:
		return ""
	if absf(delta.x) >= absf(delta.y):
		return "east" if delta.x >= 0.0 else "west"
	return "south" if delta.y >= 0.0 else "north"


func _corridor_throat_id(
	departure_node_id: int,
	arrival_node_id: int,
	departure_sector_id: String,
	arrival_sector_id: String,
	cardinal_direction: String
) -> String:
	if cardinal_direction.is_empty():
		return ""
	var departure_label: String = departure_sector_id
	if departure_label.is_empty():
		departure_label = "node_%d" % departure_node_id
	var arrival_label: String = arrival_sector_id
	if arrival_label.is_empty():
		arrival_label = "node_%d" % arrival_node_id
	return "%s>%s:%s" % [departure_label, arrival_label, cardinal_direction]


func _assign_visible_edge_corridor_roles(
	local_focus_edges: Array[Dictionary],
	history_edges: Array[Dictionary],
	current_node_id: int,
	primary_actionable_edge_key: String,
	layout_context: Dictionary
) -> void:
	var current_branch_root_id: int = _current_branch_root_id(
		int(layout_context.get("start_node_id", current_node_id)),
		current_node_id,
		layout_context.get("branch_root_by_node_id", {})
	)
	for edge_entry in local_focus_edges:
		var corridor_role_semantic: String = CORRIDOR_ROLE_RECONNECT if bool(edge_entry.get("is_reconnect_edge", false)) else CORRIDOR_ROLE_BRANCH_ACTIONABLE
		if not bool(edge_entry.get("is_reconnect_edge", false)):
			corridor_role_semantic = CORRIDOR_ROLE_PRIMARY_ACTIONABLE if _edge_key(
				int(edge_entry.get("from_node_id", -1)),
				int(edge_entry.get("to_node_id", -1))
			) == primary_actionable_edge_key else CORRIDOR_ROLE_BRANCH_ACTIONABLE
		edge_entry["corridor_role_semantic"] = corridor_role_semantic
		edge_entry["route_surface_semantic"] = corridor_role_semantic
		edge_entry["corridor_draw_priority"] = _corridor_draw_priority(corridor_role_semantic)
	for edge_entry in history_edges:
		var history_semantic: String = CORRIDOR_ROLE_HISTORY
		if bool(edge_entry.get("is_reconnect_edge", false)):
			history_semantic = CORRIDOR_ROLE_RECONNECT
		elif _edge_belongs_to_current_branch_history(edge_entry, current_branch_root_id, layout_context):
			history_semantic = CORRIDOR_ROLE_BRANCH_HISTORY
		edge_entry["corridor_role_semantic"] = history_semantic
		edge_entry["route_surface_semantic"] = history_semantic
		edge_entry["corridor_draw_priority"] = _corridor_draw_priority(history_semantic)


func _select_primary_actionable_edge_key(
	local_focus_edges: Array[Dictionary],
	current_node_id: int,
	layout_context: Dictionary
) -> String:
	var best_edge_key := ""
	var best_score := -INF
	for edge_entry in local_focus_edges:
		if bool(edge_entry.get("is_reconnect_edge", false)):
			continue
		var score: float = _score_primary_actionable_edge(edge_entry, current_node_id, layout_context)
		var edge_key: String = _edge_key(
			int(edge_entry.get("from_node_id", -1)),
			int(edge_entry.get("to_node_id", -1))
		)
		if score > best_score or (is_equal_approx(score, best_score) and (best_edge_key == "" or edge_key < best_edge_key)):
			best_score = score
			best_edge_key = edge_key
	return best_edge_key


func _score_primary_actionable_edge(edge_entry: Dictionary, current_node_id: int, layout_context: Dictionary) -> float:
	var from_node_id: int = int(edge_entry.get("from_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var to_node_id: int = int(edge_entry.get("to_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var adjacent_node_id: int = to_node_id if from_node_id == current_node_id else from_node_id
	if adjacent_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
		return -INF
	var depth_by_node_id: Dictionary = layout_context.get("depth_by_node_id", {})
	var child_ids_by_parent: Dictionary = layout_context.get("child_ids_by_parent", {})
	var primary_parent_by_node_id: Dictionary = layout_context.get("primary_parent_by_node_id", {})
	var branch_root_by_node_id: Dictionary = layout_context.get("branch_root_by_node_id", {})
	var current_depth: int = int(depth_by_node_id.get(current_node_id, 0))
	var adjacent_depth: int = int(depth_by_node_id.get(adjacent_node_id, current_depth))
	var current_branch_root_id: int = _current_branch_root_id(
		int(layout_context.get("start_node_id", current_node_id)),
		current_node_id,
		branch_root_by_node_id
	)
	var adjacent_branch_root_id: int = _current_branch_root_id(
		int(layout_context.get("start_node_id", adjacent_node_id)),
		adjacent_node_id,
		branch_root_by_node_id
	)
	var score := 0.0
	if adjacent_depth > current_depth:
		score += 240.0
	elif adjacent_depth < current_depth:
		score -= 120.0
	else:
		score += 12.0
	var child_ids: Array[int] = _int_array_from_variant(child_ids_by_parent.get(current_node_id, []))
	if adjacent_node_id in child_ids:
		score += 220.0
	if int(primary_parent_by_node_id.get(adjacent_node_id, MapRuntimeStateScript.NO_PENDING_NODE_ID)) == current_node_id:
		score += 180.0
	if int(primary_parent_by_node_id.get(current_node_id, MapRuntimeStateScript.NO_PENDING_NODE_ID)) == adjacent_node_id:
		score += 64.0
	if adjacent_branch_root_id == current_branch_root_id:
		score += 56.0
	if adjacent_depth == current_depth + 1:
		score += 48.0
	return score


func _edge_belongs_to_current_branch_history(edge_entry: Dictionary, current_branch_root_id: int, layout_context: Dictionary) -> bool:
	var branch_root_by_node_id: Dictionary = layout_context.get("branch_root_by_node_id", {})
	var from_node_id: int = int(edge_entry.get("from_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var to_node_id: int = int(edge_entry.get("to_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var from_branch_root_id: int = int(edge_entry.get("from_branch_root_id", branch_root_by_node_id.get(from_node_id, from_node_id)))
	var to_branch_root_id: int = int(edge_entry.get("to_branch_root_id", branch_root_by_node_id.get(to_node_id, to_node_id)))
	return (
		from_branch_root_id == current_branch_root_id
		or to_branch_root_id == current_branch_root_id
		or from_node_id == current_branch_root_id
		or to_node_id == current_branch_root_id
	)


func _current_branch_root_id(start_node_id: int, node_id: int, branch_root_by_node_id: Dictionary) -> int:
	if node_id == start_node_id:
		return start_node_id
	return int(branch_root_by_node_id.get(node_id, node_id))


func _corridor_draw_priority(corridor_role_semantic: String) -> int:
	match corridor_role_semantic:
		CORRIDOR_ROLE_RECONNECT:
			return 0
		CORRIDOR_ROLE_HISTORY:
			return 1
		CORRIDOR_ROLE_BRANCH_HISTORY:
			return 2
		CORRIDOR_ROLE_BRANCH_ACTIONABLE:
			return 3
		CORRIDOR_ROLE_PRIMARY_ACTIONABLE:
			return 4
		_:
			return 1
func _build_full_edge_layouts(
	graph_by_id: Dictionary,
	graph_nodes: Array[Dictionary],
	world_positions: Dictionary,
	layout_context: Dictionary,
	template_profile: String,
	board_seed: int,
	board_size: Vector2
) -> Array[Dictionary]:
	var node_layout_by_id: Dictionary = {}
	for node_entry in graph_nodes:
		node_layout_by_id[int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))] = node_entry
	var depth_by_node_id: Dictionary = layout_context.get("depth_by_node_id", {})
	var layout_edges: Array[Dictionary] = []
	var processed_edges: Dictionary = {}
	for node_id_variant in graph_by_id.keys():
		var node_id: int = int(node_id_variant)
		for adjacent_node_id in _adjacent_ids_for(graph_by_id, node_id):
			var edge_key: String = _edge_key(node_id, adjacent_node_id)
			if processed_edges.has(edge_key):
				continue
			processed_edges[edge_key] = true
			var path_model: Dictionary = _build_edge_path_model(
				node_layout_by_id.get(node_id, {}),
				node_layout_by_id.get(adjacent_node_id, {}),
				graph_nodes,
				world_positions,
				layout_context,
				template_profile,
				board_seed,
				board_size
			)
			layout_edges.append({
				"from_node_id": node_id,
				"to_node_id": adjacent_node_id,
				"is_reconnect_edge": bool(path_model.get("is_reconnect_edge", false)),
				"is_primary_tree_edge": bool(path_model.get("is_primary_tree_edge", false)),
				"from_depth": int(depth_by_node_id.get(node_id, 0)),
				"to_depth": int(depth_by_node_id.get(adjacent_node_id, 0)),
				"from_branch_root_id": int(path_model.get("from_branch_root_id", node_id)),
				"to_branch_root_id": int(path_model.get("to_branch_root_id", adjacent_node_id)),
				"depth_delta": abs(int(depth_by_node_id.get(node_id, 0)) - int(depth_by_node_id.get(adjacent_node_id, 0))),
				"path_family": String(path_model.get("path_family", PATH_FAMILY_GENTLE_CURVE)),
				"points": path_model.get("points", PackedVector2Array()),
			})
	layout_edges.sort_custom(func(left_edge: Dictionary, right_edge: Dictionary) -> bool:
		var left_key: String = _edge_key(int(left_edge.get("from_node_id", -1)), int(left_edge.get("to_node_id", -1)))
		var right_key: String = _edge_key(int(right_edge.get("from_node_id", -1)), int(right_edge.get("to_node_id", -1)))
		return left_key < right_key
	)
	return layout_edges
func _build_graph_node_entries(graph_snapshot: Array[Dictionary], world_positions: Dictionary, board_size: Vector2) -> Array[Dictionary]:
	var graph_nodes: Array[Dictionary] = []
	for node_entry in graph_snapshot:
		var node_id: int = int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var node_family: String = String(node_entry.get("node_family", ""))
		graph_nodes.append({
			"node_id": node_id,
			"node_family": node_family,
			"world_position": world_positions.get(node_id, Vector2.ZERO),
			"clearing_radius": _clearing_radius_for(node_family, "open", board_size),
	})
	return graph_nodes


func _filter_non_crossing_history_edges(
	local_focus_edges: Array[Dictionary],
	history_edges: Array[Dictionary]
) -> Array[Dictionary]:
	return MapBoardHistoryEdgeFilterScript.filter_non_crossing_history_edges(local_focus_edges, history_edges)


func _build_edge_path_model(
	from_node: Dictionary,
	to_node: Dictionary,
	visible_nodes: Array[Dictionary],
	world_positions: Dictionary,
	layout_context: Dictionary,
	template_profile: String,
	board_seed: int,
	board_size: Vector2
) -> Dictionary:
	var from_node_id: int = int(from_node.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var to_node_id: int = int(to_node.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var start_point: Vector2 = world_positions.get(from_node_id, Vector2.ZERO)
	var end_point: Vector2 = world_positions.get(to_node_id, Vector2.ZERO)
	var direction: Vector2 = end_point - start_point
	var distance: float = direction.length()
	if distance <= 0.001:
		return {
			"is_reconnect_edge": false,
			"is_primary_tree_edge": true,
			"from_branch_root_id": from_node_id,
			"to_branch_root_id": to_node_id,
			"path_family": PATH_FAMILY_SHORT_STRAIGHT,
			"points": PackedVector2Array([start_point, end_point]),
		}

	var direction_normalized: Vector2 = direction / distance
	var normal: Vector2 = Vector2(-direction_normalized.y, direction_normalized.x)
	var start_radius: float = float(from_node.get("clearing_radius", 42.0))
	var end_radius: float = float(to_node.get("clearing_radius", 42.0))
	var start_inset: float = min(start_radius * 0.96, distance * 0.42)
	var end_inset: float = min(end_radius * 0.96, distance * 0.42)
	var p0: Vector2 = start_point + direction_normalized * start_inset
	var p3: Vector2 = end_point - direction_normalized * end_inset
	var board_center: Vector2 = board_size * BASE_CENTER_FACTOR
	var midpoint: Vector2 = (start_point + end_point) * 0.5
	var outward_bias: Vector2 = midpoint - board_center
	if outward_bias.length_squared() <= 0.001:
		outward_bias = normal
	var outward_direction: Vector2 = outward_bias.normalized()
	var outward_tangent: Vector2 = Vector2(-outward_direction.y, outward_direction.x)
	var depth_by_node_id: Dictionary = layout_context.get("depth_by_node_id", {})
	var primary_parent_by_node_id: Dictionary = layout_context.get("primary_parent_by_node_id", {})
	var branch_root_by_node_id: Dictionary = layout_context.get("branch_root_by_node_id", {})
	var from_depth: int = int(depth_by_node_id.get(from_node_id, 0))
	var to_depth: int = int(depth_by_node_id.get(to_node_id, 0))
	var is_primary_corridor_edge: bool = (
		int(primary_parent_by_node_id.get(from_node_id, MapRuntimeStateScript.NO_PENDING_NODE_ID)) == to_node_id
		or int(primary_parent_by_node_id.get(to_node_id, MapRuntimeStateScript.NO_PENDING_NODE_ID)) == from_node_id
	)
	var is_reconnect_edge: bool = not is_primary_corridor_edge
	var is_same_depth_reconnect_edge: bool = is_reconnect_edge and abs(from_depth - to_depth) == 0
	var same_branch: bool = int(branch_root_by_node_id.get(from_node_id, from_node_id)) == int(branch_root_by_node_id.get(to_node_id, to_node_id))
	var deeper_node_id: int = to_node_id if to_depth >= from_depth else from_node_id
	var branch_direction: Vector2 = _branch_direction_for_root(layout_context, int(branch_root_by_node_id.get(deeper_node_id, deeper_node_id)))
	var branch_tangent: Vector2 = Vector2(-branch_direction.y, branch_direction.x)
	var board_unit: float = max(1.0, min(board_size.x, board_size.y))
	var distance_ratio: float = distance / board_unit
	var midpoint_radius_ratio: float = midpoint.distance_to(board_center) / board_unit
	var radial_alignment: float = absf(direction_normalized.dot(outward_direction))
	var tangential_alignment: float = absf(direction_normalized.dot(outward_tangent))
	var direction_angle: float = atan2(direction_normalized.y, direction_normalized.x)
	var angle_bucket: int = int(floor(((direction_angle + PI) / TAU) * 12.0))
	var edge_hash: int = _derive_seed(
		board_seed,
		"edge-family:%s|%d|%d|%d" % [
			_edge_key(from_node_id, to_node_id),
			int(round(distance_ratio * 1000.0)),
			angle_bucket,
			int(round(midpoint_radius_ratio * 1000.0)),
		]
	)
	var path_family: String = _resolve_edge_path_family(
		edge_hash,
		distance_ratio,
		midpoint_radius_ratio,
		radial_alignment,
		tangential_alignment,
		is_reconnect_edge,
		same_branch,
		abs(from_depth - to_depth)
	)
	var locked_edge: bool = (
		String(from_node.get("state_semantic", "")) == "locked"
		or String(to_node.get("state_semantic", "")) == "locked"
	)
	var profile_multiplier: float = _edge_profile_curve_multiplier(template_profile)
	var tangent_length: float = clampf(distance * 0.18, 22.0, 88.0)
	var p1: Vector2 = p0 + direction_normalized * tangent_length
	var p2: Vector2 = p3 - direction_normalized * tangent_length
	var branch_bias_amount: float = clampf(distance * 0.08, 8.0, 34.0)
	var branch_bias_sign: float = 1.0 if branch_tangent.dot(normal) >= 0.0 else -1.0
	var branch_bias: Vector2 = branch_tangent * branch_bias_amount * branch_bias_sign

	match path_family:
		PATH_FAMILY_SHORT_STRAIGHT:
			var straight_detour: float = 10.0 if locked_edge else 0.0
			p1 += outward_direction * straight_detour
			p2 += outward_direction * straight_detour * 0.72
		PATH_FAMILY_GENTLE_CURVE:
			tangent_length = clampf(distance * 0.18, 24.0, 92.0)
			p1 = p0 + direction_normalized * tangent_length
			p2 = p3 - direction_normalized * tangent_length
			var gentle_curvature: float = clampf(distance * 0.052 * profile_multiplier, 6.0, 28.0)
			var gentle_outward: float = max(6.0 if locked_edge else 0.0, gentle_curvature * 0.03)
			var gentle_sign: float = _curve_sign_for(edge_hash, normal, outward_direction, false)
			var gentle_offset: Vector2 = normal * gentle_curvature * gentle_sign + outward_direction * gentle_outward + branch_bias * 0.18
			p1 += gentle_offset
			p2 += gentle_offset * 0.82
		PATH_FAMILY_WIDER_CURVE:
			tangent_length = clampf(distance * 0.21, 28.0, 104.0)
			p1 = p0 + direction_normalized * tangent_length
			p2 = p3 - direction_normalized * tangent_length
			var wide_curvature: float = clampf(distance * 0.118 * profile_multiplier, 16.0, 62.0)
			var wide_outward: float = max(11.0 if locked_edge else 0.0, wide_curvature * 0.09)
			var wide_sign: float = _curve_sign_for(_derive_seed(edge_hash, "wider"), normal, outward_direction, true)
			var wide_offset: Vector2 = normal * wide_curvature * wide_sign + outward_direction * wide_outward + branch_bias * 0.46
			p1 += wide_offset
			p2 += wide_offset * 0.98
		PATH_FAMILY_OUTWARD_RECONNECTING_ARC:
			tangent_length = clampf(distance * 0.21, 26.0, 96.0)
			p1 = p0 + direction_normalized * tangent_length
			p2 = p3 - direction_normalized * tangent_length
			var arc_curvature: float = clampf(distance * 0.072 * profile_multiplier, 8.0, 28.0)
			var arc_outward: float = clampf(distance * 0.102, 14.0, 40.0) + (6.0 if locked_edge else 0.0)
			var arc_sign: float = _curve_sign_for(_derive_seed(edge_hash, "arc"), normal, outward_direction, true)
			p1 += outward_direction * arc_outward * 0.92 + normal * arc_curvature * arc_sign * 0.46 + branch_bias * 0.22
			p2 += outward_direction * arc_outward * 0.80 + normal * arc_curvature * arc_sign * 0.28 + branch_bias * 0.14
	var points: PackedVector2Array = _sample_cubic_bezier(p0, p1, p2, p3, 16)
	var avoidance_offset: Vector2 = MapBoardGeometryScript.edge_node_avoidance_offset(
		points,
		from_node_id,
		to_node_id,
		visible_nodes,
		p0,
		p3,
		midpoint,
		EDGE_NODE_AVOIDANCE_PADDING,
		EDGE_NODE_AVOIDANCE_MIN_SHIFT,
		EDGE_NODE_AVOIDANCE_MAX_SHIFT
	)
	var avoidance_pass: int = 0
	while avoidance_pass < EDGE_NODE_AVOIDANCE_MAX_PASSES and avoidance_offset != Vector2.ZERO:
		var avoidance_scale: float = 1.0 + float(avoidance_pass) * 0.55
		p1 += avoidance_offset * avoidance_scale
		p2 += avoidance_offset * avoidance_scale * 0.92
		points = _sample_cubic_bezier(p0, p1, p2, p3, 16)
		if not MapBoardGeometryScript.polyline_hits_other_visible_nodes(
			points,
			from_node_id,
			to_node_id,
			visible_nodes,
			EDGE_NODE_AVOIDANCE_PADDING
		):
			break
		avoidance_offset = MapBoardGeometryScript.edge_node_avoidance_offset(
			points,
			from_node_id,
			to_node_id,
			visible_nodes,
			p0,
			p3,
			midpoint,
			EDGE_NODE_AVOIDANCE_PADDING,
			EDGE_NODE_AVOIDANCE_MIN_SHIFT,
			EDGE_NODE_AVOIDANCE_MAX_SHIFT
		)
		avoidance_pass += 1
	if MapBoardGeometryScript.polyline_hits_other_visible_nodes(points, from_node_id, to_node_id, visible_nodes, EDGE_NODE_AVOIDANCE_PADDING):
		path_family = PATH_FAMILY_OUTWARD_RECONNECTING_ARC
		var outward_escape: float = clampf(distance * 0.26, 30.0, 94.0)
		var fallback_tangent: float = clampf(distance * 0.16, 20.0, 70.0)
		var fallback_curve: float = clampf(distance * 0.10, 12.0, 36.0)
		var fallback_sign: float = _curve_sign_for(_derive_seed(edge_hash, "fallback-arc"), normal, outward_direction, true)
		p1 = p0 + direction_normalized * fallback_tangent + outward_direction * outward_escape + normal * fallback_curve * fallback_sign + branch_bias * 0.16
		p2 = p3 - direction_normalized * fallback_tangent + outward_direction * outward_escape * 0.88 + normal * fallback_curve * fallback_sign * 0.60 + branch_bias * 0.12
		points = _sample_cubic_bezier(p0, p1, p2, p3, 16)
		if MapBoardGeometryScript.polyline_hits_other_visible_nodes(points, from_node_id, to_node_id, visible_nodes, EDGE_NODE_AVOIDANCE_PADDING):
			if is_same_depth_reconnect_edge:
				var local_fallback_points: PackedVector2Array = _build_same_depth_reconnect_local_fallback_points(
					p0,
					p3,
					visible_nodes,
					from_node_id,
					to_node_id,
					board_size,
					outward_direction
				)
				if not local_fallback_points.is_empty():
					points = local_fallback_points
					return {
						"is_reconnect_edge": is_reconnect_edge,
						"is_primary_tree_edge": is_primary_corridor_edge,
						"from_branch_root_id": int(branch_root_by_node_id.get(from_node_id, from_node_id)),
						"to_branch_root_id": int(branch_root_by_node_id.get(to_node_id, to_node_id)),
						"path_family": path_family,
						"points": points,
					}
			var fallback_points: PackedVector2Array = _build_outer_reconnect_fallback_points(
				p0,
				p3,
				visible_nodes,
				from_node_id,
				to_node_id,
				board_size
			)
			if not fallback_points.is_empty():
				if is_same_depth_reconnect_edge and not _same_depth_reconnect_points_are_acceptable(fallback_points, p0, p3, board_size):
					var bounded_fallback_points: PackedVector2Array = _build_same_depth_reconnect_local_fallback_points(
						p0,
						p3,
						visible_nodes,
						from_node_id,
						to_node_id,
						board_size,
						outward_direction
					)
					if not bounded_fallback_points.is_empty():
						points = bounded_fallback_points
					else:
						points = fallback_points
				else:
					points = fallback_points
	return {
		"is_reconnect_edge": is_reconnect_edge,
		"is_primary_tree_edge": is_primary_corridor_edge,
		"from_branch_root_id": int(branch_root_by_node_id.get(from_node_id, from_node_id)),
		"to_branch_root_id": int(branch_root_by_node_id.get(to_node_id, to_node_id)),
		"path_family": path_family,
		"points": points,
	}


func _build_same_depth_reconnect_local_fallback_points(
	p0: Vector2,
	p3: Vector2,
	visible_nodes: Array[Dictionary],
	from_node_id: int,
	to_node_id: int,
	board_size: Vector2,
	outward_direction: Vector2
) -> PackedVector2Array:
	var direct_min_x: float = minf(p0.x, p3.x)
	var direct_max_x: float = maxf(p0.x, p3.x)
	var direct_min_y: float = minf(p0.y, p3.y)
	var direct_max_y: float = maxf(p0.y, p3.y)
	var safe_left: float = SAME_DEPTH_RECONNECT_MIN_EDGE_CLEARANCE
	var safe_right: float = board_size.x - SAME_DEPTH_RECONNECT_MIN_EDGE_CLEARANCE
	var safe_top: float = SAME_DEPTH_RECONNECT_MIN_EDGE_CLEARANCE
	var safe_bottom: float = board_size.y - SAME_DEPTH_RECONNECT_MIN_EDGE_CLEARANCE
	var preferred_vertical_offset: float = clampf(board_size.y * 0.05, 28.0, 72.0)
	var preferred_horizontal_offset: float = clampf(board_size.x * 0.05, 28.0, 72.0)
	var secondary_vertical_offset: float = clampf(preferred_vertical_offset * 0.68, 20.0, preferred_vertical_offset)
	var secondary_horizontal_offset: float = clampf(preferred_horizontal_offset * 0.68, 20.0, preferred_horizontal_offset)
	var direct_midpoint: Vector2 = (p0 + p3) * 0.5
	var horizontal_lanes: Array[float] = []
	var vertical_lanes: Array[float] = []
	_append_unique_lane(horizontal_lanes, clampf(direct_min_y - secondary_vertical_offset, safe_top, safe_bottom))
	_append_unique_lane(horizontal_lanes, clampf(direct_min_y - preferred_vertical_offset, safe_top, safe_bottom))
	_append_unique_lane(horizontal_lanes, clampf(direct_max_y + secondary_vertical_offset, safe_top, safe_bottom))
	_append_unique_lane(horizontal_lanes, clampf(direct_max_y + preferred_vertical_offset, safe_top, safe_bottom))
	_append_unique_lane(horizontal_lanes, clampf(lerpf(p0.y, p3.y, 0.36), safe_top, safe_bottom))
	_append_unique_lane(horizontal_lanes, clampf(lerpf(p0.y, p3.y, 0.64), safe_top, safe_bottom))
	_append_unique_lane(horizontal_lanes, clampf(direct_midpoint.y + outward_direction.y * board_size.y * 0.06, safe_top, safe_bottom))
	_append_unique_lane(vertical_lanes, clampf(direct_min_x - secondary_horizontal_offset, safe_left, safe_right))
	_append_unique_lane(vertical_lanes, clampf(direct_min_x - preferred_horizontal_offset, safe_left, safe_right))
	_append_unique_lane(vertical_lanes, clampf(direct_max_x + secondary_horizontal_offset, safe_left, safe_right))
	_append_unique_lane(vertical_lanes, clampf(direct_max_x + preferred_horizontal_offset, safe_left, safe_right))
	_append_unique_lane(vertical_lanes, clampf(lerpf(p0.x, p3.x, 0.22), safe_left, safe_right))
	_append_unique_lane(vertical_lanes, clampf(lerpf(p0.x, p3.x, 0.38), safe_left, safe_right))
	_append_unique_lane(vertical_lanes, clampf(direct_midpoint.x + outward_direction.x * board_size.x * 0.06, safe_left, safe_right))

	var candidates: Array[Dictionary] = []
	for lane_y in horizontal_lanes:
		if absf(lane_y - p0.y) < 18.0 and absf(lane_y - p3.y) < 18.0:
			continue
		_append_same_depth_reconnect_candidate(
			candidates,
			PackedVector2Array([p0, Vector2(p0.x, lane_y), Vector2(p3.x, lane_y), p3]),
			visible_nodes,
			from_node_id,
			to_node_id,
			board_size,
			p0,
			p3
		)
	for lane_x in vertical_lanes:
		if absf(lane_x - p0.x) < 18.0 and absf(lane_x - p3.x) < 18.0:
			continue
		_append_same_depth_reconnect_candidate(
			candidates,
			PackedVector2Array([p0, Vector2(lane_x, p0.y), Vector2(lane_x, p3.y), p3]),
			visible_nodes,
			from_node_id,
			to_node_id,
			board_size,
			p0,
			p3
		)
	for lane_x in vertical_lanes:
		for lane_y in horizontal_lanes:
			_append_same_depth_reconnect_candidate(
				candidates,
				PackedVector2Array([p0, Vector2(p0.x, lane_y), Vector2(lane_x, lane_y), Vector2(lane_x, p3.y), p3]),
				visible_nodes,
				from_node_id,
				to_node_id,
				board_size,
				p0,
				p3
			)
			_append_same_depth_reconnect_candidate(
				candidates,
				PackedVector2Array([p0, Vector2(lane_x, p0.y), Vector2(lane_x, lane_y), Vector2(p3.x, lane_y), p3]),
				visible_nodes,
				from_node_id,
				to_node_id,
				board_size,
				p0,
				p3
			)
	if candidates.is_empty():
		return PackedVector2Array()
	candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_score: float = float(left.get("score", INF))
		var right_score: float = float(right.get("score", INF))
		if not is_equal_approx(left_score, right_score):
			return left_score < right_score
		return float(left.get("length", INF)) < float(right.get("length", INF))
	)
	return PackedVector2Array((candidates[0] as Dictionary).get("points", PackedVector2Array()))


func _append_same_depth_reconnect_candidate(
	candidates: Array[Dictionary],
	points: PackedVector2Array,
	visible_nodes: Array[Dictionary],
	from_node_id: int,
	to_node_id: int,
	board_size: Vector2,
	p0: Vector2,
	p3: Vector2
) -> void:
	if points.size() < 2:
		return
	if MapBoardGeometryScript.polyline_hits_other_visible_nodes(
		points,
		from_node_id,
		to_node_id,
		visible_nodes,
		EDGE_NODE_AVOIDANCE_PADDING
	):
		return
	if not _same_depth_reconnect_points_are_acceptable(points, p0, p3, board_size):
		return
	candidates.append({
		"points": points,
		"length": MapBoardGeometryScript.visible_edge_polyline_length({"points": points}),
		"score": MapBoardEdgeRoutingScript.score_outer_reconnect_candidate(points, p0, p3, board_size),
	})


func _same_depth_reconnect_points_are_acceptable(
	points: PackedVector2Array,
	p0: Vector2,
	p3: Vector2,
	board_size: Vector2
) -> bool:
	if points.size() < 2:
		return false
	var direct_distance: float = p0.distance_to(p3)
	if direct_distance <= 0.001:
		return false
	var path_length: float = MapBoardGeometryScript.visible_edge_polyline_length({"points": points})
	if path_length > direct_distance * SAME_DEPTH_RECONNECT_MAX_RATIO:
		return false
	return _minimum_polyline_edge_clearance(points, board_size) >= SAME_DEPTH_RECONNECT_MIN_EDGE_CLEARANCE


func _minimum_polyline_edge_clearance(points: PackedVector2Array, board_size: Vector2) -> float:
	var minimum_clearance: float = INF
	for point in points:
		minimum_clearance = minf(
			minimum_clearance,
			minf(
				minf(point.x, board_size.x - point.x),
				minf(point.y, board_size.y - point.y)
			)
		)
	return minimum_clearance


func _append_unique_lane(lanes: Array[float], value: float) -> void:
	for lane in lanes:
		if is_equal_approx(float(lane), value) or absf(float(lane) - value) < 14.0:
			return
	lanes.append(value)


func _resolve_edge_path_family(
	edge_hash: int,
	distance_ratio: float,
	midpoint_radius_ratio: float,
	radial_alignment: float,
	tangential_alignment: float,
	is_reconnect_edge: bool,
	same_branch: bool,
	depth_delta: int
) -> String:
	var seed_bias: float = float(abs(edge_hash % 997)) / 996.0
	if is_reconnect_edge:
		if depth_delta == 0:
			return PATH_FAMILY_OUTWARD_RECONNECTING_ARC
		if distance_ratio >= lerpf(0.24, 0.31, seed_bias) or tangential_alignment >= lerpf(0.54, 0.68, seed_bias):
			return PATH_FAMILY_WIDER_CURVE
		return PATH_FAMILY_GENTLE_CURVE
	if distance_ratio <= 0.24 and midpoint_radius_ratio <= 0.42:
		return PATH_FAMILY_SHORT_STRAIGHT
	var straight_distance_cap: float = lerpf(0.232, 0.272, seed_bias)
	var straight_alignment_floor: float = lerpf(0.70, 0.84, seed_bias)
	if (
		distance_ratio <= straight_distance_cap
		and radial_alignment >= straight_alignment_floor
		and midpoint_radius_ratio <= lerpf(0.22, 0.32, seed_bias)
	):
		return PATH_FAMILY_SHORT_STRAIGHT

	var wide_distance_floor: float = lerpf(0.25, 0.33, seed_bias)
	var wide_tangent_floor: float = lerpf(0.56, 0.70, seed_bias)
	var wide_outer_floor: float = lerpf(0.20, 0.32, seed_bias)
	if distance_ratio >= wide_distance_floor or (
		tangential_alignment >= wide_tangent_floor and midpoint_radius_ratio >= wide_outer_floor
	):
		return PATH_FAMILY_WIDER_CURVE
	if not same_branch and (
		distance_ratio >= lerpf(0.21, 0.27, seed_bias)
		or tangential_alignment >= lerpf(0.42, 0.56, seed_bias)
	):
		return PATH_FAMILY_WIDER_CURVE
	return PATH_FAMILY_GENTLE_CURVE
func _edge_profile_curve_multiplier(template_profile: String) -> float:
	match template_profile:
		"corridor":
			return 0.76
		"openfield":
			return 0.82
		"loop":
			return 0.86
		_:
			return 0.80
func _curve_sign_for(edge_hash: int, normal: Vector2, outward_direction: Vector2, prefer_outward: bool) -> float:
	var outward_alignment: float = normal.dot(outward_direction)
	if absf(outward_alignment) >= 0.12:
		var outward_sign: float = 1.0 if outward_alignment >= 0.0 else -1.0
		if prefer_outward or ((edge_hash >> 1) & 1) == 0:
			return outward_sign
		return -outward_sign
	return 1.0 if (edge_hash & 1) == 0 else -1.0
func _sample_cubic_bezier(
	p0: Vector2,
	p1: Vector2,
	p2: Vector2,
	p3: Vector2,
	segment_count: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segment_count + 1):
		var t: float = float(index) / float(segment_count)
		var one_minus_t: float = 1.0 - t
		var point: Vector2 = (
			p0 * pow(one_minus_t, 3.0)
			+ p1 * 3.0 * pow(one_minus_t, 2.0) * t
			+ p2 * 3.0 * one_minus_t * pow(t, 2.0)
		+ p3 * pow(t, 3.0)
		)
		points.append(point)
	return points
func _build_outer_reconnect_fallback_points(
	p0: Vector2,
	p3: Vector2,
	visible_nodes: Array[Dictionary],
	from_node_id: int,
	to_node_id: int,
	board_size: Vector2
) -> PackedVector2Array:
	return MapBoardEdgeRoutingScript.build_outer_reconnect_fallback_points(
		p0,
		p3,
		visible_nodes,
		from_node_id,
		to_node_id,
		board_size,
		build_playable_margin() + OUTER_RECONNECT_MARGIN_BIAS,
		EDGE_NODE_AVOIDANCE_PADDING
	)
func _edge_semantic_for(from_node: Dictionary, to_node: Dictionary) -> String:
	if String(from_node.get("state_semantic", "")) == "locked" or String(to_node.get("state_semantic", "")) == "locked":
		return "locked"
	var from_resolved: bool = String(from_node.get("node_state", "")) == MapRuntimeStateScript.NODE_STATE_RESOLVED
	var to_resolved: bool = String(to_node.get("node_state", "")) == MapRuntimeStateScript.NODE_STATE_RESOLVED
	if from_resolved and to_resolved:
		return "resolved"
	return "open"
func _should_show_history_edge(from_node: Dictionary, to_node: Dictionary) -> bool:
	var from_node_state: String = String(from_node.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
	var to_node_state: String = String(to_node.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
	if from_node_state == MapRuntimeStateScript.NODE_STATE_UNDISCOVERED or to_node_state == MapRuntimeStateScript.NODE_STATE_UNDISCOVERED:
		return false
	return true
func _semantic_for_node(node_state: String, is_current: bool) -> String:
	if is_current:
		return "current"
	match node_state:
		MapRuntimeStateScript.NODE_STATE_LOCKED:
			return "locked"
		MapRuntimeStateScript.NODE_STATE_RESOLVED:
			return "resolved"
		_:
			return "open"
func _icon_texture_path_for_family(node_family: String) -> String:
	match node_family:
		"start":
			return UiAssetPathsScript.START_ICON_TEXTURE_PATH
		"combat":
			return UiAssetPathsScript.MAP_COMBAT_ICON_TEXTURE_PATH
		"event":
			return UiAssetPathsScript.EVENT_ICON_TEXTURE_PATH
		"reward":
			return UiAssetPathsScript.REWARD_ICON_TEXTURE_PATH
		"hamlet":
			return UiAssetPathsScript.HAMLET_ICON_TEXTURE_PATH
		"rest":
			return UiAssetPathsScript.REST_ICON_TEXTURE_PATH
		"merchant":
			return UiAssetPathsScript.MERCHANT_ICON_TEXTURE_PATH
		"blacksmith":
			return UiAssetPathsScript.BLACKSMITH_ICON_TEXTURE_PATH
		"key":
			return UiAssetPathsScript.MAP_KEY_ICON_TEXTURE_PATH
		"boss":
			return UiAssetPathsScript.MAP_BOSS_ICON_TEXTURE_PATH
		_:
			return ""


func _clearing_radius_for(node_family: String, state_semantic: String, board_size: Vector2) -> float:
	var board_unit: float = min(board_size.x, board_size.y)
	var factor: float = 0.054
	match node_family:
		"start":
			factor = 0.070
		"boss":
			factor = 0.068
		"reward", "rest", "merchant", "blacksmith", "key":
			factor = 0.062
		"combat", "event":
			factor = 0.057
	if state_semantic == "resolved":
		factor -= 0.006
	return clampf(board_unit * factor, 40.0, 78.0)


func _clamp_focus_offset(desired_offset: Vector2, max_focus_offset: Vector2) -> Vector2:
	return Vector2(
		clampf(desired_offset.x, -max_focus_offset.x, max_focus_offset.x),
		clampf(desired_offset.y, -max_focus_offset.y, max_focus_offset.y)
	)


func _build_board_seed(run_state: RunState, active_template_id: String, graph_snapshot: Array[Dictionary]) -> int:
	var signature_parts: PackedStringArray = []
	for node_entry in graph_snapshot:
		var adjacent_ids: Array[String] = []
		for adjacent_node_id in _adjacent_ids_from_entry(node_entry):
			adjacent_ids.append(str(adjacent_node_id))
		signature_parts.append(
			"%d|%s|%s" % [
				int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)),
				String(node_entry.get("node_family", "")),
				",".join(adjacent_ids),
			]
		)
	var raw_seed: String = "%d|%d|%s|%s" % [
		int(run_state.run_seed),
		int(run_state.stage_index),
		active_template_id,
		"|".join(signature_parts),
	]
	return _hash_seed_string(raw_seed)


func _derive_seed(board_seed: int, salt: String) -> int:
	return MapBoardLayoutSolverScript.derive_seed(board_seed, salt)


func _hash_seed_string(value: String) -> int:
	return MapBoardLayoutSolverScript.hash_seed_string(value)


func _template_profile_for_id(active_template_id: String) -> String:
	if active_template_id.contains("openfield"):
		return "openfield"
	if active_template_id.contains("loop"):
		return "loop"
	return DEFAULT_TEMPLATE_PROFILE


func _adjacent_ids_for(graph_by_id: Dictionary, node_id: int) -> PackedInt32Array:
	return _adjacent_ids_from_entry(graph_by_id.get(node_id, {}))


func _adjacent_ids_from_entry(node_entry: Dictionary) -> PackedInt32Array:
	var adjacent_variant: Variant = node_entry.get("adjacent_node_ids", PackedInt32Array())
	if typeof(adjacent_variant) == TYPE_PACKED_INT32_ARRAY:
		return adjacent_variant
	var adjacent_ids := PackedInt32Array()
	if typeof(adjacent_variant) == TYPE_ARRAY:
		for adjacent_node_id in adjacent_variant:
			adjacent_ids.append(int(adjacent_node_id))
	return adjacent_ids


func _sorted_adjacent_ids(graph_by_id: Dictionary, node_id: int) -> Array[int]:
	var adjacent_ids: Array[int] = []
	for adjacent_node_id in _adjacent_ids_for(graph_by_id, node_id):
		adjacent_ids.append(adjacent_node_id)
	adjacent_ids.sort()
	return adjacent_ids


func _edge_key(from_node_id: int, to_node_id: int) -> String:
	var ordered_ids: Array[int] = [from_node_id, to_node_id]
	ordered_ids.sort()
	return "%d:%d" % [ordered_ids[0], ordered_ids[1]]


func _sort_node_entry_by_id(left: Dictionary, right: Dictionary) -> bool:
	return int(left.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)) < int(right.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))


func _sort_visible_node_entries(left: Dictionary, right: Dictionary) -> bool:
	var left_current: bool = bool(left.get("is_current", false))
	var right_current: bool = bool(right.get("is_current", false))
	if left_current != right_current:
		return left_current
	var left_adjacent: bool = bool(left.get("is_adjacent", false))
	var right_adjacent: bool = bool(right.get("is_adjacent", false))
	if left_adjacent != right_adjacent:
		return left_adjacent
	return int(left.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)) < int(right.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
