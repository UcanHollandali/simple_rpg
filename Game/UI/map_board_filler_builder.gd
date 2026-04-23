# Layer: UI
extends RefCounted
class_name MapBoardFillerBuilder

const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const MapBoardGeometryScript = preload("res://Game/UI/map_board_geometry.gd")
const MapBoardLayoutSolverScript = preload("res://Game/UI/map_board_layout_solver.gd")

const FILLER_ZONE_FACTORS_BY_PROFILE := {
	"corridor": [
		Vector2(0.24, 0.34),
		Vector2(0.76, 0.38),
		Vector2(0.30, 0.76),
		Vector2(0.70, 0.74),
	],
	"openfield": [
		Vector2(0.22, 0.34),
		Vector2(0.78, 0.34),
		Vector2(0.22, 0.72),
		Vector2(0.78, 0.72),
		Vector2(0.50, 0.82),
	],
	"loop": [
		Vector2(0.24, 0.32),
		Vector2(0.76, 0.34),
		Vector2(0.24, 0.68),
		Vector2(0.76, 0.70),
		Vector2(0.50, 0.82),
	],
}
const FILLER_FAMILIES_BY_PROFILE := {
	"corridor": ["rock", "ruin", "water_patch", "rock"],
	"openfield": ["rock", "water_patch", "ruin", "rock", "water_patch"],
	"loop": ["rock", "ruin", "rock", "water_patch", "ruin"],
}
const FILLER_FALLBACK_ZONE_FACTORS := [
	Vector2(0.16, 0.34),
	Vector2(0.84, 0.36),
	Vector2(0.18, 0.78),
	Vector2(0.82, 0.78),
]
const FILLER_MAX_ACCEPTED_BY_PROFILE := {
	"corridor": 3,
	"openfield": 4,
	"loop": 4,
}
const FILLER_REGION_ATTEMPTS := 5
const FILLER_ZONE_OFFSET_X_FACTOR := 0.028
const FILLER_ZONE_OFFSET_Y_FACTOR := 0.024
const FILLER_BOARD_MARGIN_EXTRA := Vector2(96.0, 84.0)
const FILLER_NODE_EXCLUSION_PADDING := 60.0
const FILLER_ROUTE_EXCLUSION_PADDING := 46.0
const FILLER_SHAPE_EXCLUSION_PADDING := 36.0
const FILLER_ACTION_BOUNDS_TRIM_BY_PROFILE := {
	"corridor": Vector2(0.16, 0.18),
	"openfield": Vector2(0.10, 0.12),
	"loop": Vector2(0.12, 0.14),
}
const FILLER_ACTION_POCKET_PADDING_BY_PROFILE := {
	"corridor": Vector2(104.0, 112.0),
	"openfield": Vector2(92.0, 100.0),
	"loop": Vector2(96.0, 104.0),
}


# Contract:
# - Input is limited to existing board-space derived truth: board size, graph-node positions,
#   frozen route polylines, template profile, existing board seed, and board margin/center hints.
# - Output is an ordered array of board-space filler shapes with these fields:
#   `family`, `center`, `half_size`, `rotation_degrees`, `tone_shift`, `alpha_scale`.
# - Density stays auditable: the builder attempts at most one accepted filler per seeded zone,
#   caps total accepted fillers per profile, and enforces explicit node/route/shape exclusion floors.
# - The builder never reads node-family semantics, does not mutate route geometry, and stays non-interactive.
static func build_filler_shapes(
	board_size: Vector2,
	graph_nodes: Array[Dictionary],
	layout_edges: Array,
	template_profile: String,
	board_seed: int,
	base_center_factor: Vector2,
	min_board_margin: Vector2
) -> Array[Dictionary]:
	var ordered_nodes: Array[Dictionary] = _ordered_graph_nodes(graph_nodes)
	if ordered_nodes.is_empty():
		return []

	var board_center: Vector2 = board_size * base_center_factor
	var action_bounds: Rect2 = _trimmed_action_bounds_for_inputs(ordered_nodes, layout_edges, template_profile)
	var accepted_shapes: Array[Dictionary] = []
	var zone_anchors: Array[Vector2] = _zone_anchors_for_profile(
		board_size,
		action_bounds,
		template_profile,
		base_center_factor,
		min_board_margin
	)
	var max_accepted: int = max_fillers_for_profile(template_profile)
	for zone_index in range(zone_anchors.size()):
		if accepted_shapes.size() >= max_accepted:
			break
		var zone_anchor: Vector2 = zone_anchors[zone_index].lerp(board_center, 0.02)
		var family: String = _family_for_zone(template_profile, zone_index, board_seed)
		for attempt_index in range(FILLER_REGION_ATTEMPTS):
			var candidate_rng := RandomNumberGenerator.new()
			candidate_rng.seed = _derive_seed(board_seed, "filler:%d:%d" % [zone_index, attempt_index])
			var half_size: Vector2 = _half_size_for_family(family, board_size, template_profile, candidate_rng)
			var candidate_center: Vector2 = _candidate_center_for_zone(
				zone_anchor,
				family,
				half_size,
				board_size,
				min_board_margin,
				candidate_rng
			)
			if not _is_candidate_clear(candidate_center, family, half_size, ordered_nodes, layout_edges, accepted_shapes, action_bounds, template_profile):
				continue
			accepted_shapes.append({
				"family": family,
				"center": candidate_center,
				"half_size": half_size,
				"rotation_degrees": candidate_rng.randf_range(-26.0, 26.0),
				"tone_shift": _tone_shift_for_family(family, candidate_rng),
				"alpha_scale": _alpha_scale_for_family(family, candidate_rng),
				"texture_path": _texture_path_for_family(family, board_seed, zone_index, accepted_shapes.size()),
				"texture_scale": _texture_scale_for_family(family),
			})
			break
	if accepted_shapes.is_empty():
		accepted_shapes = _build_corner_fallback_shapes(
			board_size,
			ordered_nodes,
			layout_edges,
			template_profile,
			board_seed,
			min_board_margin,
			max_accepted,
			action_bounds
		)
	return accepted_shapes


static func max_fillers_for_profile(template_profile: String) -> int:
	return int(FILLER_MAX_ACCEPTED_BY_PROFILE.get(template_profile, FILLER_MAX_ACCEPTED_BY_PROFILE["corridor"]))


static func footprint_half_size(half_size: Vector2, family: String = "") -> Vector2:
	if family.is_empty():
		return half_size
	var texture_scale: float = maxf(1.0, _texture_scale_for_family(family))
	return Vector2(half_size.x * texture_scale, half_size.y * texture_scale)


static func node_exclusion_radius(clearing_radius: float, half_size: Vector2, family: String = "") -> float:
	var clearance_half_size: Vector2 = footprint_half_size(half_size, family)
	return clearing_radius + maxf(clearance_half_size.x, clearance_half_size.y) + FILLER_NODE_EXCLUSION_PADDING


static func route_exclusion_radius(half_size: Vector2, family: String = "") -> float:
	var clearance_half_size: Vector2 = footprint_half_size(half_size, family)
	return maxf(clearance_half_size.x, clearance_half_size.y) * 0.82 + FILLER_ROUTE_EXCLUSION_PADDING


static func filler_spacing_radius(half_size: Vector2, family: String = "") -> float:
	var clearance_half_size: Vector2 = footprint_half_size(half_size, family)
	return maxf(clearance_half_size.x, clearance_half_size.y) * 1.14 + FILLER_SHAPE_EXCLUSION_PADDING


static func _ordered_graph_nodes(graph_nodes: Array[Dictionary]) -> Array[Dictionary]:
	var ordered_nodes: Array[Dictionary] = []
	for node_variant in graph_nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		if Vector2(node_entry.get("world_position", Vector2.ZERO)) == Vector2.ZERO:
			continue
		ordered_nodes.append(node_entry)
	ordered_nodes.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("node_id", 0)) < int(right.get("node_id", 0))
	)
	return ordered_nodes


static func _family_for_zone(template_profile: String, zone_index: int, board_seed: int) -> String:
	var families: Array = FILLER_FAMILIES_BY_PROFILE.get(template_profile, FILLER_FAMILIES_BY_PROFILE["corridor"])
	if families.is_empty():
		return "rock"
	var rotation_offset: int = abs(_derive_seed(board_seed, "filler-family-rotation")) % families.size()
	return String(families[(zone_index + rotation_offset) % families.size()])


static func _half_size_for_family(
	family: String,
	board_size: Vector2,
	template_profile: String,
	rng: RandomNumberGenerator
) -> Vector2:
	var board_unit: float = maxf(1.0, minf(board_size.x, board_size.y))
	var min_scale := Vector2(0.040, 0.024)
	var max_scale := Vector2(0.060, 0.038)
	match family:
		"ruin":
			min_scale = Vector2(0.034, 0.022)
			max_scale = Vector2(0.052, 0.032)
		"water_patch":
			min_scale = Vector2(0.046, 0.026)
			max_scale = Vector2(0.068, 0.042)
	if template_profile == "openfield":
		max_scale += Vector2(0.004, 0.004)
	elif template_profile == "corridor":
		max_scale -= Vector2(0.004, 0.002)
	return Vector2(
		board_unit * rng.randf_range(min_scale.x, max_scale.x),
		board_unit * rng.randf_range(min_scale.y, max_scale.y)
	)


static func _candidate_center_for_zone(
	zone_anchor: Vector2,
	family: String,
	half_size: Vector2,
	board_size: Vector2,
	min_board_margin: Vector2,
	rng: RandomNumberGenerator
) -> Vector2:
	var candidate_center: Vector2 = zone_anchor + Vector2(
		rng.randf_range(-board_size.x * FILLER_ZONE_OFFSET_X_FACTOR, board_size.x * FILLER_ZONE_OFFSET_X_FACTOR),
		rng.randf_range(-board_size.y * FILLER_ZONE_OFFSET_Y_FACTOR, board_size.y * FILLER_ZONE_OFFSET_Y_FACTOR)
	)
	var board_margin: Vector2 = min_board_margin + FILLER_BOARD_MARGIN_EXTRA
	var clearance_half_size: Vector2 = footprint_half_size(half_size, family)
	return Vector2(
		clampf(candidate_center.x, board_margin.x + clearance_half_size.x, board_size.x - board_margin.x - clearance_half_size.x),
		clampf(candidate_center.y, board_margin.y + clearance_half_size.y, board_size.y - board_margin.y - clearance_half_size.y)
	)


static func _is_candidate_clear(
	candidate_center: Vector2,
	family: String,
	half_size: Vector2,
	graph_nodes: Array[Dictionary],
	layout_edges: Array,
	accepted_shapes: Array[Dictionary],
	action_bounds: Rect2,
	template_profile: String
) -> bool:
	for node_entry in graph_nodes:
		var node_center: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
		var node_clearance: float = node_exclusion_radius(float(node_entry.get("clearing_radius", 0.0)), half_size, family)
		if candidate_center.distance_to(node_center) < node_clearance:
			return false
	for edge_variant in layout_edges:
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		var route_points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
		if route_points.size() < 2:
			continue
		if MapBoardGeometryScript.polyline_distance_to_point(route_points, candidate_center) < route_exclusion_radius(half_size, family):
			return false
	for shape_entry in accepted_shapes:
		var other_center: Vector2 = Vector2(shape_entry.get("center", Vector2.ZERO))
		var other_half_size: Vector2 = Vector2(shape_entry.get("half_size", Vector2.ZERO))
		var other_family: String = String(shape_entry.get("family", ""))
		var spacing_floor: float = maxf(
			filler_spacing_radius(half_size, family),
			filler_spacing_radius(other_half_size, other_family)
		)
		if candidate_center.distance_to(other_center) < spacing_floor:
			return false
	var pocket_exclusion_rect: Rect2 = _action_pocket_exclusion_rect(action_bounds, half_size, family, template_profile)
	if pocket_exclusion_rect.has_area() and pocket_exclusion_rect.has_point(candidate_center):
		return false
	return true


static func _tone_shift_for_family(family: String, rng: RandomNumberGenerator) -> float:
	match family:
		"water_patch":
			return rng.randf_range(-0.06, 0.04)
		"ruin":
			return rng.randf_range(-0.04, 0.08)
		_:
			return rng.randf_range(-0.08, 0.06)


static func _alpha_scale_for_family(family: String, rng: RandomNumberGenerator) -> float:
	match family:
		"water_patch":
			return rng.randf_range(0.80, 0.92)
		"ruin":
			return rng.randf_range(0.82, 0.96)
		_:
			return rng.randf_range(0.84, 1.00)


static func _build_corner_fallback_shapes(
	board_size: Vector2,
	graph_nodes: Array[Dictionary],
	layout_edges: Array,
	template_profile: String,
	board_seed: int,
	min_board_margin: Vector2,
	max_accepted: int,
	action_bounds: Rect2
) -> Array[Dictionary]:
	var fallback_shapes: Array[Dictionary] = []
	for zone_index in range(FILLER_FALLBACK_ZONE_FACTORS.size()):
		if fallback_shapes.size() >= min(2, max_accepted):
			break
		var family: String = _family_for_zone(template_profile, zone_index, board_seed)
		var attempt_rng := RandomNumberGenerator.new()
		attempt_rng.seed = _derive_seed(board_seed, "filler-fallback:%d" % zone_index)
		var half_size: Vector2 = _half_size_for_family(family, board_size, template_profile, attempt_rng) * 0.82
		var candidate_center: Vector2 = _candidate_center_for_zone(
			board_size * FILLER_FALLBACK_ZONE_FACTORS[zone_index],
			family,
			half_size,
			board_size,
			min_board_margin,
			attempt_rng
		)
		if not _is_candidate_clear(candidate_center, family, half_size, graph_nodes, layout_edges, fallback_shapes, action_bounds, template_profile):
			continue
		fallback_shapes.append({
			"family": family,
			"center": candidate_center,
			"half_size": half_size,
			"rotation_degrees": attempt_rng.randf_range(-18.0, 18.0),
			"tone_shift": _tone_shift_for_family(family, attempt_rng),
			"alpha_scale": _alpha_scale_for_family(family, attempt_rng),
			"texture_path": _texture_path_for_family(family, board_seed, zone_index, fallback_shapes.size()),
			"texture_scale": _texture_scale_for_family(family),
		})
	return fallback_shapes


static func _texture_path_for_family(family: String, board_seed: int, zone_index: int, accepted_index: int) -> String:
	var texture_paths: Array = UiAssetPathsScript.MAP_FILLER_TEXTURE_PATHS_BY_FAMILY.get(family, [])
	if texture_paths.is_empty():
		return ""
	var salt: String = "filler-texture:%s:%d:%d" % [family, zone_index, accepted_index]
	var texture_index: int = abs(_derive_seed(board_seed, salt)) % texture_paths.size()
	return String(texture_paths[texture_index])


static func _texture_scale_for_family(family: String) -> float:
	match family:
		"ruin":
			return 1.40
		"water_patch":
			return 1.48
		_:
			return 1.32


static func _trimmed_action_bounds_for_inputs(graph_nodes: Array[Dictionary], layout_edges: Array, template_profile: String) -> Rect2:
	var points: Array[Vector2] = []
	for node_entry in graph_nodes:
		points.append(Vector2(node_entry.get("world_position", Vector2.ZERO)))
	for edge_variant in layout_edges:
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		var route_points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
		if route_points.is_empty():
			continue
		points.append(route_points[0])
		points.append(route_points[route_points.size() - 1])
		if route_points.size() >= 2:
			points.append(route_points[int(floor(float(route_points.size() - 1) * 0.5))])
	if points.size() < 5:
		return Rect2()
	return _trimmed_bounds_for_points(
		points,
		FILLER_ACTION_BOUNDS_TRIM_BY_PROFILE.get(template_profile, FILLER_ACTION_BOUNDS_TRIM_BY_PROFILE["corridor"])
	)


static func _zone_anchors_for_profile(
	board_size: Vector2,
	action_bounds: Rect2,
	template_profile: String,
	base_center_factor: Vector2,
	min_board_margin: Vector2
) -> Array[Vector2]:
	if not action_bounds.has_area():
		var fallback_anchors: Array[Vector2] = []
		for zone_factor in FILLER_ZONE_FACTORS_BY_PROFILE.get(template_profile, FILLER_ZONE_FACTORS_BY_PROFILE["corridor"]):
			fallback_anchors.append(board_size * Vector2(zone_factor))
		return fallback_anchors
	var pocket_padding: Vector2 = FILLER_ACTION_POCKET_PADDING_BY_PROFILE.get(
		template_profile,
		FILLER_ACTION_POCKET_PADDING_BY_PROFILE["corridor"]
	)
	var board_center: Vector2 = board_size * base_center_factor
	var left_x: float = maxf(min_board_margin.x + 24.0, action_bounds.position.x - pocket_padding.x)
	var right_x: float = minf(board_size.x - min_board_margin.x - 24.0, action_bounds.end.x + pocket_padding.x)
	var upper_y: float = maxf(min_board_margin.y + 24.0, action_bounds.position.y - pocket_padding.y * 0.46)
	var middle_y: float = lerpf(action_bounds.position.y, action_bounds.end.y, 0.42)
	var lower_y: float = minf(board_size.y - min_board_margin.y - 24.0, action_bounds.end.y + pocket_padding.y)
	match template_profile:
		"openfield":
			return [
				Vector2(left_x, lerpf(upper_y, middle_y, 0.38)),
				Vector2(right_x, lerpf(upper_y, middle_y, 0.38)),
				Vector2(left_x, lower_y),
				Vector2(right_x, lower_y),
				Vector2(board_center.x, minf(board_size.y - min_board_margin.y - 24.0, action_bounds.end.y + pocket_padding.y * 1.14)),
			]
		"loop":
			return [
				Vector2(left_x, upper_y),
				Vector2(right_x, upper_y),
				Vector2(left_x, lower_y),
				Vector2(right_x, lower_y),
				Vector2(board_center.x, minf(board_size.y - min_board_margin.y - 24.0, action_bounds.end.y + pocket_padding.y * 1.08)),
			]
		_:
			return [
				Vector2(left_x, middle_y),
				Vector2(right_x, middle_y),
				Vector2(lerpf(action_bounds.position.x, board_center.x, 0.42), lower_y),
				Vector2(lerpf(board_center.x, action_bounds.end.x, 0.58), lower_y),
			]


static func _trimmed_bounds_for_points(points: Array[Vector2], trim_ratio: Vector2) -> Rect2:
	var sorted_x: Array[float] = []
	var sorted_y: Array[float] = []
	for point in points:
		sorted_x.append(point.x)
		sorted_y.append(point.y)
	sorted_x.sort()
	sorted_y.sort()
	var trim_count_x: int = int(floor(float(points.size() - 1) * clampf(trim_ratio.x, 0.0, 0.30)))
	var trim_count_y: int = int(floor(float(points.size() - 1) * clampf(trim_ratio.y, 0.0, 0.30)))
	var min_index_x: int = clamp(trim_count_x, 0, sorted_x.size() - 1)
	var max_index_x: int = clamp(sorted_x.size() - 1 - trim_count_x, 0, sorted_x.size() - 1)
	var min_index_y: int = clamp(trim_count_y, 0, sorted_y.size() - 1)
	var max_index_y: int = clamp(sorted_y.size() - 1 - trim_count_y, 0, sorted_y.size() - 1)
	if max_index_x <= min_index_x or max_index_y <= min_index_y:
		return Rect2()
	return Rect2(
		Vector2(sorted_x[min_index_x], sorted_y[min_index_y]),
		Vector2(sorted_x[max_index_x] - sorted_x[min_index_x], sorted_y[max_index_y] - sorted_y[min_index_y])
	)


static func _action_pocket_exclusion_rect(action_bounds: Rect2, half_size: Vector2, family: String, template_profile: String) -> Rect2:
	if not action_bounds.has_area():
		return Rect2()
	var pocket_padding: Vector2 = FILLER_ACTION_POCKET_PADDING_BY_PROFILE.get(
		template_profile,
		FILLER_ACTION_POCKET_PADDING_BY_PROFILE["corridor"]
	)
	var clearance_half_size: Vector2 = footprint_half_size(half_size, family)
	return action_bounds.grow_individual(
		clearance_half_size.x * 0.72 + pocket_padding.x * 0.26,
		clearance_half_size.y * 0.64 + pocket_padding.y * 0.18,
		clearance_half_size.x * 0.72 + pocket_padding.x * 0.26,
		clearance_half_size.y * 0.82 + pocket_padding.y * 0.24
	)


static func _derive_seed(board_seed: int, salt: String) -> int:
	return MapBoardLayoutSolverScript.derive_seed(board_seed, salt)
