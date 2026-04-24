# Layer: UI
extends RefCounted
class_name MapBoardSlotAnchorLayout

const SECTOR_CENTER_ANCHOR := "center_anchor"
const SECTOR_NORTH_WEST := "north_west"
const SECTOR_NORTH_CENTER := "north_center"
const SECTOR_NORTH_EAST := "north_east"
const SECTOR_MID_LEFT := "mid_left"
const SECTOR_MID_RIGHT := "mid_right"
const SECTOR_SOUTH_WEST := "south_west"
const SECTOR_SOUTH_CENTER := "south_center"
const SECTOR_SOUTH_EAST := "south_east"
const SECTOR_OUTER_LATE_WEST := "outer_late_west"
const SECTOR_OUTER_LATE_EAST := "outer_late_east"

const SUPPORT_FAMILIES := {
	"rest": true,
	"merchant": true,
	"blacksmith": true,
	"hamlet": true,
	"event": true,
}
const LATE_PRESSURE_FAMILIES := {
	"key": true,
	"boss": true,
}

const SECTOR_MAX_OCCUPANCY := {
	SECTOR_CENTER_ANCHOR: 2,
	SECTOR_NORTH_WEST: 2,
	SECTOR_NORTH_CENTER: 2,
	SECTOR_NORTH_EAST: 2,
	SECTOR_MID_LEFT: 2,
	SECTOR_MID_RIGHT: 2,
	SECTOR_SOUTH_WEST: 2,
	SECTOR_SOUTH_CENTER: 1,
	SECTOR_SOUTH_EAST: 2,
	SECTOR_OUTER_LATE_WEST: 1,
	SECTOR_OUTER_LATE_EAST: 1,
}

const SECTOR_NEIGHBORS := {
	SECTOR_CENTER_ANCHOR: [SECTOR_NORTH_WEST, SECTOR_NORTH_CENTER, SECTOR_NORTH_EAST, SECTOR_MID_LEFT, SECTOR_MID_RIGHT, SECTOR_SOUTH_CENTER],
	SECTOR_NORTH_WEST: [SECTOR_CENTER_ANCHOR, SECTOR_NORTH_CENTER, SECTOR_MID_LEFT, SECTOR_OUTER_LATE_WEST],
	SECTOR_NORTH_CENTER: [SECTOR_CENTER_ANCHOR, SECTOR_NORTH_WEST, SECTOR_NORTH_EAST, SECTOR_MID_LEFT, SECTOR_MID_RIGHT],
	SECTOR_NORTH_EAST: [SECTOR_CENTER_ANCHOR, SECTOR_NORTH_CENTER, SECTOR_MID_RIGHT, SECTOR_OUTER_LATE_EAST],
	SECTOR_MID_LEFT: [SECTOR_CENTER_ANCHOR, SECTOR_NORTH_WEST, SECTOR_NORTH_CENTER, SECTOR_SOUTH_WEST, SECTOR_SOUTH_CENTER],
	SECTOR_MID_RIGHT: [SECTOR_CENTER_ANCHOR, SECTOR_NORTH_EAST, SECTOR_NORTH_CENTER, SECTOR_SOUTH_EAST, SECTOR_SOUTH_CENTER],
	SECTOR_SOUTH_WEST: [SECTOR_MID_LEFT, SECTOR_SOUTH_CENTER],
	SECTOR_SOUTH_CENTER: [SECTOR_CENTER_ANCHOR, SECTOR_MID_LEFT, SECTOR_MID_RIGHT, SECTOR_SOUTH_WEST, SECTOR_SOUTH_EAST],
	SECTOR_SOUTH_EAST: [SECTOR_MID_RIGHT, SECTOR_SOUTH_CENTER],
	SECTOR_OUTER_LATE_WEST: [SECTOR_NORTH_WEST, SECTOR_MID_LEFT],
	SECTOR_OUTER_LATE_EAST: [SECTOR_NORTH_EAST, SECTOR_MID_RIGHT],
}

const SECTOR_ANCHORS := {
	SECTOR_CENTER_ANCHOR: [Vector2(0.50, 0.60), Vector2(0.46, 0.58), Vector2(0.54, 0.62)],
	SECTOR_NORTH_WEST: [Vector2(0.28, 0.18), Vector2(0.22, 0.24), Vector2(0.34, 0.28)],
	SECTOR_NORTH_CENTER: [Vector2(0.50, 0.18), Vector2(0.46, 0.26), Vector2(0.54, 0.24)],
	SECTOR_NORTH_EAST: [Vector2(0.72, 0.18), Vector2(0.66, 0.28), Vector2(0.78, 0.24)],
	SECTOR_MID_LEFT: [Vector2(0.26, 0.42), Vector2(0.20, 0.50), Vector2(0.33, 0.36)],
	SECTOR_MID_RIGHT: [Vector2(0.74, 0.42), Vector2(0.80, 0.50), Vector2(0.67, 0.36)],
	SECTOR_SOUTH_WEST: [Vector2(0.24, 0.68), Vector2(0.18, 0.78), Vector2(0.30, 0.62)],
	SECTOR_SOUTH_CENTER: [Vector2(0.50, 0.74), Vector2(0.45, 0.68), Vector2(0.55, 0.80)],
	SECTOR_SOUTH_EAST: [Vector2(0.76, 0.68), Vector2(0.82, 0.78), Vector2(0.70, 0.62)],
	SECTOR_OUTER_LATE_WEST: [Vector2(0.12, 0.20), Vector2(0.10, 0.30), Vector2(0.16, 0.14)],
	SECTOR_OUTER_LATE_EAST: [Vector2(0.88, 0.20), Vector2(0.90, 0.30), Vector2(0.84, 0.14)],
}


static func build_world_positions(
	graph_snapshot: Array[Dictionary],
	board_size: Vector2,
	layout_context: Dictionary,
	template_profile: String,
	board_seed: int,
	config: Dictionary
) -> Dictionary:
	var anchor_payload: Dictionary = build_anchor_payload(
		graph_snapshot,
		board_size,
		layout_context,
		template_profile,
		board_seed,
		config
	)
	return (anchor_payload.get("world_positions", {}) as Dictionary).duplicate(true)


static func build_anchor_payload(
	graph_snapshot: Array[Dictionary],
	board_size: Vector2,
	layout_context: Dictionary,
	template_profile: String,
	board_seed: int,
	config: Dictionary
) -> Dictionary:
	if graph_snapshot.is_empty():
		return {}
	var playable_rect: Rect2 = config.get("playable_rect", Rect2(Vector2.ZERO, board_size))
	var base_center_factor: Vector2 = config.get("base_center_factor", Vector2(0.50, 0.60))
	var origin: Vector2 = board_size * base_center_factor
	var graph_by_id: Dictionary = _index_graph_snapshot(graph_snapshot)
	var start_node_id: int = int(layout_context.get("start_node_id", 0))
	var depth_by_node_id: Dictionary = layout_context.get("depth_by_node_id", {})
	var degree_by_node_id: Dictionary = layout_context.get("degree_by_node_id", {})
	var branch_root_by_node_id: Dictionary = layout_context.get("branch_root_by_node_id", {})
	var child_ids_by_parent: Dictionary = layout_context.get("child_ids_by_parent", {})
	var branch_direction_by_root: Dictionary = layout_context.get("branch_direction_by_root", {})
	var sector_by_node_id: Dictionary = layout_context.get("sector_by_node_id", {})
	var route_role_by_node_id: Dictionary = layout_context.get("route_role_by_node_id", {})
	var orientation_profile_id: String = String(layout_context.get("orientation_profile_id", ""))
	var topology_blueprint_id: String = String(layout_context.get("topology_blueprint_id", ""))
	var min_spacing_by_node_id: Dictionary = _build_min_spacing_by_node_id(graph_snapshot, board_size, config.get("clearing_radius_by_node_id", {}))
	var root_lane_by_id: Dictionary = _build_root_lane_by_id(graph_by_id, start_node_id, degree_by_node_id, branch_direction_by_root)
	var side_bias: int = _side_bias_sign(board_seed, template_profile, orientation_profile_id)
	var sector_occupancy: Dictionary = {}
	var chosen_sector_by_node_id: Dictionary = {}
	var anchor_index_by_node_id: Dictionary = {}
	var world_positions: Dictionary = {}
	var ordered_node_ids: Array[int] = _sorted_node_ids_by_depth(graph_snapshot, depth_by_node_id)
	ordered_node_ids.sort_custom(func(left: int, right: int) -> bool:
		var left_depth: int = int(depth_by_node_id.get(left, 0))
		var right_depth: int = int(depth_by_node_id.get(right, 0))
		if left_depth == right_depth:
			var left_degree: int = int(degree_by_node_id.get(left, 0))
			var right_degree: int = int(degree_by_node_id.get(right, 0))
			if left_degree == right_degree:
				return left < right
			return left_degree > right_degree
		return left_depth < right_depth
	)

	for node_id in ordered_node_ids:
		if node_id == start_node_id:
			var start_sector_id: String = _validated_sector_id(String(sector_by_node_id.get(node_id, SECTOR_CENTER_ANCHOR)), SECTOR_CENTER_ANCHOR)
			var start_anchors: Array = SECTOR_ANCHORS.get(start_sector_id, SECTOR_ANCHORS[SECTOR_CENTER_ANCHOR])
			var start_position: Vector2 = _point_in_playable_rect(playable_rect, Vector2(start_anchors[0]))
			world_positions[node_id] = start_position
			sector_occupancy[start_sector_id] = [node_id]
			chosen_sector_by_node_id[node_id] = start_sector_id
			anchor_index_by_node_id[node_id] = 0
			continue
		var node_entry: Dictionary = graph_by_id.get(node_id, {})
		if node_entry.is_empty():
			return {}
		var node_depth: int = int(depth_by_node_id.get(node_id, 0))
		var branch_root_id: int = int(branch_root_by_node_id.get(node_id, node_id))
		var root_lane: String = String(root_lane_by_id.get(branch_root_id, "center"))
		var root_entry: Dictionary = graph_by_id.get(branch_root_id, {})
		var root_family: String = String(root_entry.get("node_family", ""))
		var node_family: String = String(node_entry.get("node_family", ""))
		var metadata_sector_id: String = _validated_sector_id(String(sector_by_node_id.get(node_id, "")), "")
		var route_role: String = String(route_role_by_node_id.get(node_id, ""))
		var preferred_sectors: Array[String] = _preferred_sectors_for_node(
			node_id,
			node_family,
			root_lane,
			root_family,
			node_depth,
			board_seed,
			side_bias
		)
		preferred_sectors = _preferred_sectors_from_runtime_metadata(
			metadata_sector_id,
			route_role,
			orientation_profile_id,
			preferred_sectors
		)
		var candidate: Dictionary = _pick_best_slot_candidate(
			node_id,
			preferred_sectors,
			sector_occupancy,
			world_positions,
			playable_rect,
			origin,
			board_size,
			board_seed,
			min_spacing_by_node_id,
			layout_context,
			child_ids_by_parent
		)
		if candidate.is_empty():
			return {}
		var chosen_sector: String = String(candidate.get("sector_id", ""))
		var chosen_position: Vector2 = Vector2(candidate.get("position", Vector2.ZERO))
		if chosen_sector.is_empty() or chosen_position == Vector2.ZERO:
			return {}
		world_positions[node_id] = chosen_position
		var sector_node_ids: Array[int] = _int_array_from_variant(sector_occupancy.get(chosen_sector, []))
		sector_node_ids.append(node_id)
		sector_occupancy[chosen_sector] = sector_node_ids
		chosen_sector_by_node_id[node_id] = chosen_sector
		anchor_index_by_node_id[node_id] = int(candidate.get("anchor_index", 0))
	return {
		"world_positions": world_positions,
		"slot_anchor_sector_by_node_id": chosen_sector_by_node_id,
		"slot_anchor_index_by_node_id": anchor_index_by_node_id,
		"layout_sector_by_node_id": sector_by_node_id.duplicate(true),
		"layout_route_role_by_node_id": route_role_by_node_id.duplicate(true),
		"orientation_profile_id": orientation_profile_id,
		"topology_blueprint_id": topology_blueprint_id,
		"placement_mode": "runtime_slot_anchor" if not sector_by_node_id.is_empty() else "derived_slot_anchor",
	}


static func _build_root_lane_by_id(
	graph_by_id: Dictionary,
	start_node_id: int,
	degree_by_node_id: Dictionary,
	branch_direction_by_root: Dictionary
) -> Dictionary:
	var root_lane_by_id: Dictionary = {}
	var adjacent_root_ids: Array[int] = []
	for adjacent_node_id in _adjacent_ids_for(graph_by_id, start_node_id):
		adjacent_root_ids.append(int(adjacent_node_id))
	var counterweight_root_ids: Array[int] = []
	if adjacent_root_ids.size() >= 4:
		var counterweight_candidates: Array[int] = adjacent_root_ids.duplicate()
		counterweight_candidates.sort_custom(func(left: int, right: int) -> bool:
			var left_entry: Dictionary = graph_by_id.get(left, {})
			var right_entry: Dictionary = graph_by_id.get(right, {})
			var left_support_like: bool = SUPPORT_FAMILIES.has(String(left_entry.get("node_family", "")))
			var right_support_like: bool = SUPPORT_FAMILIES.has(String(right_entry.get("node_family", "")))
			if left_support_like != right_support_like:
				return left_support_like
			var left_degree: int = int(degree_by_node_id.get(left, 0))
			var right_degree: int = int(degree_by_node_id.get(right, 0))
			if left_degree != right_degree:
				return left_degree < right_degree
			var left_direction: Vector2 = branch_direction_by_root.get(left, Vector2.ZERO)
			var right_direction: Vector2 = branch_direction_by_root.get(right, Vector2.ZERO)
			if not is_equal_approx(absf(left_direction.x), absf(right_direction.x)):
				return absf(left_direction.x) < absf(right_direction.x)
			return left < right
		)
		if not counterweight_candidates.is_empty():
			counterweight_root_ids.append(counterweight_candidates[0])
	var mainline_root_ids: Array[int] = []
	for adjacent_root_id in adjacent_root_ids:
		if adjacent_root_id in counterweight_root_ids:
			continue
		mainline_root_ids.append(adjacent_root_id)
	mainline_root_ids.sort_custom(func(left: int, right: int) -> bool:
		var left_direction: Vector2 = branch_direction_by_root.get(left, Vector2.ZERO)
		var right_direction: Vector2 = branch_direction_by_root.get(right, Vector2.ZERO)
		if is_equal_approx(left_direction.x, right_direction.x):
			return left < right
		return left_direction.x < right_direction.x
	)
	for counterweight_root_id in counterweight_root_ids:
		root_lane_by_id[counterweight_root_id] = "counterweight"
	match mainline_root_ids.size():
		0:
			return root_lane_by_id
		1:
			root_lane_by_id[mainline_root_ids[0]] = "center"
		2:
			root_lane_by_id[mainline_root_ids[0]] = "left"
			root_lane_by_id[mainline_root_ids[1]] = "right"
		_:
			root_lane_by_id[mainline_root_ids[0]] = "left"
			root_lane_by_id[mainline_root_ids[1]] = "center"
			root_lane_by_id[mainline_root_ids[2]] = "right"
			for extra_index in range(3, mainline_root_ids.size()):
				root_lane_by_id[mainline_root_ids[extra_index]] = "center"
	return root_lane_by_id


static func _preferred_sectors_for_node(
	node_id: int,
	node_family: String,
	root_lane: String,
	root_family: String,
	node_depth: int,
	board_seed: int,
	side_bias: int
) -> Array[String]:
	if root_lane == "counterweight":
		return [SECTOR_SOUTH_CENTER, SECTOR_SOUTH_WEST, SECTOR_SOUTH_EAST]
	var support_like: bool = SUPPORT_FAMILIES.has(node_family) or SUPPORT_FAMILIES.has(root_family)
	var late_pressure: bool = LATE_PRESSURE_FAMILIES.has(node_family)
	match root_lane:
		"left":
			if node_depth <= 1:
				return [SECTOR_NORTH_WEST, SECTOR_MID_LEFT]
			if late_pressure and node_depth >= 3:
				return [SECTOR_OUTER_LATE_WEST, SECTOR_NORTH_WEST, SECTOR_SOUTH_WEST]
			if support_like and node_depth == 2:
				return [SECTOR_SOUTH_WEST, SECTOR_MID_LEFT, SECTOR_NORTH_WEST]
			if support_like and node_depth >= 3:
				return [SECTOR_NORTH_WEST, SECTOR_SOUTH_WEST, SECTOR_OUTER_LATE_WEST]
			if node_depth == 2:
				return [SECTOR_NORTH_WEST, SECTOR_MID_LEFT, SECTOR_SOUTH_WEST]
			if node_depth == 3:
				return [SECTOR_NORTH_WEST, SECTOR_SOUTH_WEST, SECTOR_OUTER_LATE_WEST]
			return [SECTOR_OUTER_LATE_WEST, SECTOR_NORTH_WEST, SECTOR_SOUTH_WEST]
		"right":
			if node_depth <= 1:
				return [SECTOR_NORTH_EAST, SECTOR_MID_RIGHT]
			if late_pressure and node_depth >= 3:
				return [SECTOR_OUTER_LATE_EAST, SECTOR_NORTH_EAST, SECTOR_SOUTH_EAST]
			if support_like and node_depth == 2:
				return [SECTOR_SOUTH_EAST, SECTOR_MID_RIGHT, SECTOR_NORTH_EAST]
			if support_like and node_depth >= 3:
				return [SECTOR_NORTH_EAST, SECTOR_SOUTH_EAST, SECTOR_OUTER_LATE_EAST]
			if node_depth == 2:
				return [SECTOR_NORTH_EAST, SECTOR_MID_RIGHT, SECTOR_SOUTH_EAST]
			if node_depth == 3:
				return [SECTOR_NORTH_EAST, SECTOR_SOUTH_EAST, SECTOR_OUTER_LATE_EAST]
			return [SECTOR_OUTER_LATE_EAST, SECTOR_NORTH_EAST, SECTOR_SOUTH_EAST]
		_:
			var upper_primary: String = SECTOR_NORTH_WEST if side_bias < 0 else SECTOR_NORTH_EAST
			var upper_secondary: String = SECTOR_NORTH_EAST if side_bias < 0 else SECTOR_NORTH_WEST
			var outer_primary: String = SECTOR_OUTER_LATE_WEST if side_bias < 0 else SECTOR_OUTER_LATE_EAST
			var outer_secondary: String = SECTOR_OUTER_LATE_EAST if side_bias < 0 else SECTOR_OUTER_LATE_WEST
			var mid_primary: String = SECTOR_MID_LEFT if side_bias < 0 else SECTOR_MID_RIGHT
			var mid_secondary: String = SECTOR_MID_RIGHT if side_bias < 0 else SECTOR_MID_LEFT
			if node_depth <= 1:
				return [SECTOR_NORTH_CENTER]
			if late_pressure and node_depth >= 3:
				return [outer_primary, upper_primary, outer_secondary, upper_secondary, SECTOR_NORTH_CENTER]
			if support_like and node_depth == 2:
				return [SECTOR_SOUTH_CENTER, SECTOR_NORTH_CENTER, mid_primary, mid_secondary]
			if support_like and node_depth >= 3:
				return [mid_primary, SECTOR_SOUTH_CENTER, upper_primary, upper_secondary]
			if node_depth == 2:
				return [SECTOR_NORTH_CENTER, upper_primary]
			if node_depth == 3:
				return [upper_primary, SECTOR_NORTH_CENTER, upper_secondary]
			return [outer_primary, upper_primary, outer_secondary, upper_secondary]


static func _preferred_sectors_from_runtime_metadata(
	metadata_sector_id: String,
	route_role: String,
	orientation_profile_id: String,
	fallback_sectors: Array[String]
) -> Array[String]:
	if not _is_known_sector_id(metadata_sector_id):
		return fallback_sectors
	return fallback_sectors


static func _pressure_sector_fallbacks(metadata_sector_id: String, orientation_profile_id: String) -> Array[String]:
	if metadata_sector_id == SECTOR_OUTER_LATE_WEST or metadata_sector_id == SECTOR_OUTER_LATE_EAST:
		return []
	if metadata_sector_id.ends_with("_west") or metadata_sector_id == SECTOR_MID_LEFT:
		return [SECTOR_OUTER_LATE_WEST, SECTOR_NORTH_WEST, SECTOR_MID_LEFT]
	if metadata_sector_id.ends_with("_east") or metadata_sector_id == SECTOR_MID_RIGHT:
		return [SECTOR_OUTER_LATE_EAST, SECTOR_NORTH_EAST, SECTOR_MID_RIGHT]
	if orientation_profile_id == "center_outward_west_weighted":
		return [SECTOR_OUTER_LATE_WEST, SECTOR_NORTH_WEST, SECTOR_MID_LEFT]
	if orientation_profile_id == "center_outward_east_weighted":
		return [SECTOR_OUTER_LATE_EAST, SECTOR_NORTH_EAST, SECTOR_MID_RIGHT]
	return [SECTOR_NORTH_CENTER, SECTOR_OUTER_LATE_WEST, SECTOR_OUTER_LATE_EAST]


static func _append_unique_sector(sector_ids: Array[String], sector_id: String) -> void:
	if sector_id.is_empty() or not _is_known_sector_id(sector_id) or sector_id in sector_ids:
		return
	sector_ids.append(sector_id)


static func _validated_sector_id(sector_id: String, fallback_sector_id: String) -> String:
	return sector_id if _is_known_sector_id(sector_id) else fallback_sector_id


static func _is_known_sector_id(sector_id: String) -> bool:
	return SECTOR_ANCHORS.has(sector_id)


static func _pick_best_slot_candidate(
	node_id: int,
	preferred_sectors: Array[String],
	sector_occupancy: Dictionary,
	world_positions: Dictionary,
	playable_rect: Rect2,
	origin: Vector2,
	board_size: Vector2,
	board_seed: int,
	min_spacing_by_node_id: Dictionary,
	layout_context: Dictionary,
	child_ids_by_parent: Dictionary
) -> Dictionary:
	var expanded_sectors: Array[String] = _expand_sector_fallbacks(preferred_sectors)
	var minimum_spacing: float = float(min_spacing_by_node_id.get(node_id, maxf(96.0, min(board_size.x, board_size.y) * 0.14)))
	var best_candidate: Dictionary = {}
	var best_score: float = -INF
	for sector_id in expanded_sectors:
		var occupied_node_ids: Array[int] = _int_array_from_variant(sector_occupancy.get(sector_id, []))
		var sector_penalty: float = float(occupied_node_ids.size()) * 32.0
		var sector_cap: int = int(SECTOR_MAX_OCCUPANCY.get(sector_id, 2))
		if occupied_node_ids.size() >= sector_cap:
			sector_penalty += 140.0
		var anchors: Array = SECTOR_ANCHORS.get(sector_id, [])
		for anchor_index in range(anchors.size()):
			var candidate_position: Vector2 = _build_anchor_candidate_position(
				node_id,
				sector_id,
				anchor_index,
				occupied_node_ids.size(),
				playable_rect,
				origin,
				board_size,
				board_seed,
				layout_context,
				child_ids_by_parent
			)
			var nearest_distance: float = _nearest_distance_to_positions(candidate_position, world_positions)
			var spacing_bonus: float = clampf(nearest_distance - minimum_spacing, -220.0, 280.0)
			var adjacency_penalty: float = _adjacency_penalty(
				node_id,
				candidate_position,
				world_positions,
				layout_context,
				board_size
			)
			var origin_distance: float = candidate_position.distance_to(origin)
			var score: float = spacing_bonus - sector_penalty - adjacency_penalty - origin_distance * 0.015
			if nearest_distance >= minimum_spacing:
				score += 320.0
			if score > best_score:
				best_score = score
				best_candidate = {
					"sector_id": sector_id,
					"anchor_index": anchor_index,
					"position": candidate_position,
				}
	return best_candidate


static func _build_anchor_candidate_position(
	node_id: int,
	sector_id: String,
	anchor_index: int,
	sector_occupancy_count: int,
	playable_rect: Rect2,
	origin: Vector2,
	board_size: Vector2,
	board_seed: int,
	layout_context: Dictionary,
	child_ids_by_parent: Dictionary
) -> Vector2:
	var anchors: Array = SECTOR_ANCHORS.get(sector_id, [])
	var anchor: Vector2 = Vector2(anchors[anchor_index])
	var position: Vector2 = _point_in_playable_rect(playable_rect, anchor)
	var seed: int = _derive_seed(board_seed, "%s:%d:%d" % [sector_id, node_id, anchor_index])
	var jitter_rng := RandomNumberGenerator.new()
	jitter_rng.seed = seed
	var board_unit: float = min(board_size.x, board_size.y)
	var radial_direction: Vector2 = position - origin
	if radial_direction.length_squared() <= 0.001:
		radial_direction = Vector2.UP
	else:
		radial_direction = radial_direction.normalized()
	var tangent_direction: Vector2 = Vector2(-radial_direction.y, radial_direction.x)
	var primary_parent_by_node_id: Dictionary = layout_context.get("primary_parent_by_node_id", {})
	var primary_parent_id: int = int(primary_parent_by_node_id.get(node_id, -1))
	var sibling_count: int = _int_array_from_variant(child_ids_by_parent.get(primary_parent_id, [])).size()
	var sector_offset_units: float = _sector_offset_for_index(sector_occupancy_count)
	var tangent_spread: float = board_unit * lerpf(0.020, 0.036, clampf(float(sector_occupancy_count) / 2.0, 0.0, 1.0))
	var radial_spread: float = board_unit * lerpf(0.010, 0.024, clampf(float(max(0, sibling_count - 1)) / 3.0, 0.0, 1.0))
	var tangent_jitter: float = jitter_rng.randf_range(-board_unit * 0.014, board_unit * 0.014)
	var radial_jitter: float = jitter_rng.randf_range(-board_unit * 0.012, board_unit * 0.018)
	position += tangent_direction * (sector_offset_units * tangent_spread + tangent_jitter)
	position += radial_direction * (sector_offset_units * radial_spread * 0.45 + radial_jitter)
	return _clamp_to_playable_rect(position, playable_rect)


static func _build_min_spacing_by_node_id(graph_snapshot: Array[Dictionary], board_size: Vector2, clearing_radius_by_node_id: Dictionary) -> Dictionary:
	var min_spacing_by_node_id: Dictionary = {}
	var board_unit: float = min(board_size.x, board_size.y)
	for node_entry in graph_snapshot:
		var node_id: int = int(node_entry.get("node_id", -1))
		var radius: float = float(clearing_radius_by_node_id.get(node_id, 42.0))
		min_spacing_by_node_id[node_id] = radius * 2.0 + clampf(board_unit * 0.050, 54.0, 74.0)
	return min_spacing_by_node_id


static func _expand_sector_fallbacks(preferred_sectors: Array[String]) -> Array[String]:
	var expanded_sectors: Array[String] = []
	var seen: Dictionary = {}
	for sector_id in preferred_sectors:
		if seen.has(sector_id):
			continue
		seen[sector_id] = true
		expanded_sectors.append(sector_id)
	for sector_id in preferred_sectors:
		for neighbor_sector_variant in SECTOR_NEIGHBORS.get(sector_id, []):
			var neighbor_sector_id: String = String(neighbor_sector_variant)
			if seen.has(neighbor_sector_id):
				continue
			seen[neighbor_sector_id] = true
			expanded_sectors.append(neighbor_sector_id)
	return expanded_sectors


static func _nearest_distance_to_positions(position: Vector2, world_positions: Dictionary) -> float:
	if world_positions.is_empty():
		return INF
	var nearest_distance: float = INF
	for placed_position_variant in world_positions.values():
		var placed_position: Vector2 = Vector2(placed_position_variant)
		nearest_distance = min(nearest_distance, position.distance_to(placed_position))
	return nearest_distance


static func _adjacency_penalty(
	node_id: int,
	candidate_position: Vector2,
	world_positions: Dictionary,
	layout_context: Dictionary,
	board_size: Vector2
) -> float:
	var parent_ids_by_node_id: Dictionary = layout_context.get("parent_ids_by_node_id", {})
	var parent_ids: Array[int] = _int_array_from_variant(parent_ids_by_node_id.get(node_id, []))
	if parent_ids.is_empty():
		return 0.0
	var board_unit: float = min(board_size.x, board_size.y)
	var minimum_distance: float = board_unit * 0.10
	var maximum_distance: float = board_unit * 0.28
	var penalty: float = 0.0
	for parent_id in parent_ids:
		if not world_positions.has(parent_id):
			continue
		var parent_position: Vector2 = Vector2(world_positions.get(parent_id, candidate_position))
		var parent_distance: float = candidate_position.distance_to(parent_position)
		if parent_distance < minimum_distance:
			penalty += (minimum_distance - parent_distance) * 2.4
		elif parent_distance > maximum_distance:
			penalty += (parent_distance - maximum_distance) * 1.2
	return penalty


static func _point_in_playable_rect(playable_rect: Rect2, normalized_point: Vector2) -> Vector2:
	return Vector2(
		playable_rect.position.x + playable_rect.size.x * normalized_point.x,
		playable_rect.position.y + playable_rect.size.y * normalized_point.y
	)


static func _side_bias_sign(board_seed: int, template_profile: String, orientation_profile_id: String) -> int:
	var bias_seed: int = _derive_seed(board_seed, "slot-anchor-bias:%s" % template_profile)
	return -1 if (bias_seed & 1) == 0 else 1


static func _sector_offset_for_index(index: int) -> float:
	if index <= 0:
		return 0.0
	var magnitude: float = ceilf(float(index) * 0.5)
	return -magnitude if (index & 1) == 1 else magnitude


static func _index_graph_snapshot(graph_snapshot: Array[Dictionary]) -> Dictionary:
	var graph_by_id: Dictionary = {}
	for node_entry in graph_snapshot:
		graph_by_id[int(node_entry.get("node_id", -1))] = node_entry
	return graph_by_id


static func _adjacent_ids_for(graph_by_id: Dictionary, node_id: int) -> PackedInt32Array:
	var node_entry: Dictionary = graph_by_id.get(node_id, {})
	var adjacent_ids_variant: Variant = node_entry.get("adjacent_node_ids", PackedInt32Array())
	if typeof(adjacent_ids_variant) == TYPE_PACKED_INT32_ARRAY:
		return adjacent_ids_variant
	var adjacent_ids := PackedInt32Array()
	if typeof(adjacent_ids_variant) != TYPE_ARRAY:
		return adjacent_ids
	for adjacent_node_id in adjacent_ids_variant:
		adjacent_ids.append(int(adjacent_node_id))
	return adjacent_ids


static func _sorted_node_ids_by_depth(graph_snapshot: Array[Dictionary], depth_by_node_id: Dictionary) -> Array[int]:
	var node_ids: Array[int] = []
	for node_entry in graph_snapshot:
		node_ids.append(int(node_entry.get("node_id", -1)))
	node_ids.sort_custom(func(left: int, right: int) -> bool:
		var left_depth: int = int(depth_by_node_id.get(left, 0))
		var right_depth: int = int(depth_by_node_id.get(right, 0))
		if left_depth == right_depth:
			return left < right
		return left_depth < right_depth
	)
	return node_ids


static func _int_array_from_variant(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		result.append(int(item))
	return result


static func _derive_seed(board_seed: int, salt: String) -> int:
	return _hash_seed_string("%d|%s" % [board_seed, salt])


static func _hash_seed_string(value: String) -> int:
	var accumulator: int = 216613626
	var bytes: PackedByteArray = value.to_utf8_buffer()
	for byte in bytes:
		accumulator = abs(int((accumulator ^ int(byte)) * 16777619))
	if accumulator == 0:
		return 1
	return accumulator


static func _clamp_to_playable_rect(position: Vector2, playable_rect: Rect2) -> Vector2:
	return Vector2(
		clampf(position.x, playable_rect.position.x, playable_rect.end.x),
		clampf(position.y, playable_rect.position.y, playable_rect.end.y)
	)
