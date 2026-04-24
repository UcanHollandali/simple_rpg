# Layer: UI
extends RefCounted
class_name MapBoardGroundBuilder

const MapBoardLayoutSolverScript = preload("res://Game/UI/map_board_layout_solver.gd")

const GROUND_PATCH_COUNT_BY_PROFILE := {
	"corridor": 5,
	"openfield": 5,
	"loop": 6,
}
const GROUND_BED_SIZE_MULTIPLIERS_BY_PROFILE := {
	"corridor": Vector2(0.60, 0.42),
	"openfield": Vector2(0.84, 0.70),
	"loop": Vector2(0.80, 0.66),
}
const GROUND_BED_ALPHA_SCALE_BY_PROFILE := {
	"corridor": 0.46,
	"openfield": 0.72,
	"loop": 0.70,
}
const GROUND_CENTER_PULL_BY_PROFILE := {
	"corridor": 0.02,
	"openfield": 0.04,
	"loop": 0.03,
}
const GROUND_ACTION_BOUNDS_TRIM_BY_PROFILE := {
	"corridor": Vector2(0.16, 0.18),
	"openfield": Vector2(0.08, 0.10),
	"loop": Vector2(0.10, 0.12),
}
const GROUND_PATCH_CENTER_PULL_BY_PROFILE := {
	"corridor": {"patch": 0.34, "breakup": 0.28},
	"openfield": {"patch": 0.22, "breakup": 0.18},
	"loop": {"patch": 0.26, "breakup": 0.22},
}
const GROUND_PATCH_LOCAL_BOUNDS_SCALE_BY_PROFILE := {
	"corridor": {"patch": Vector2(1.02, 1.08), "breakup": Vector2(1.10, 1.14)},
	"openfield": {"patch": Vector2(1.12, 1.16), "breakup": Vector2(1.18, 1.20)},
	"loop": {"patch": Vector2(1.08, 1.12), "breakup": Vector2(1.14, 1.18)},
}
const GROUND_CORRIDOR_SHAPE_CAP_BY_PROFILE := {
	"corridor": 5,
	"openfield": 6,
	"loop": 6,
}
const GROUND_CORRIDOR_HALF_HEIGHT_BY_PROFILE := {
	"corridor": 24.0,
	"openfield": 28.0,
	"loop": 26.0,
}
const GROUND_BREAKUP_ZONE_FACTORS_BY_PROFILE := {
	"corridor": [
		Vector2(0.20, 0.26),
		Vector2(0.80, 0.28),
		Vector2(0.24, 0.80),
		Vector2(0.76, 0.82),
		Vector2(0.50, 0.90),
	],
	"openfield": [
		Vector2(0.18, 0.24),
		Vector2(0.82, 0.24),
		Vector2(0.18, 0.80),
		Vector2(0.82, 0.80),
		Vector2(0.50, 0.88),
	],
	"loop": [
		Vector2(0.20, 0.24),
		Vector2(0.80, 0.24),
		Vector2(0.18, 0.74),
		Vector2(0.82, 0.76),
		Vector2(0.50, 0.88),
	],
}


# Contract:
# - Input is limited to existing board-space derived truth: board size, graph-node positions,
#   frozen route geometry, derived landmark-pocket footprints, template profile, existing
#   board seed, and board margin/center hints.
# - Output is an ordered array of board-space ground shapes with these fields:
#   `family`, `center`, `half_size`, `rotation_degrees`, `tone_shift`, `alpha_scale`,
#   and optional derived `shape`.
# - The builder stays presentation-only. It may read derived route/pocket masks, but it
#   does not own graph truth, traversal semantics, or save state.
# - MapBoardCanvas owns drawing, and MapBoardStyle owns every visual token used to render it.
static func build_ground_shapes(
	board_size: Vector2,
	graph_nodes: Array[Dictionary],
	layout_edges: Array,
	template_profile: String,
	board_seed: int,
	base_center_factor: Vector2,
	min_board_margin: Vector2,
	surface_mask_context: Dictionary = {}
) -> Array[Dictionary]:
	var ordered_positions: Array[Vector2] = _ordered_node_positions(graph_nodes)
	if ordered_positions.is_empty():
		return []
	var action_points: Array[Vector2] = _action_points(ordered_positions, layout_edges)
	action_points.append_array(_surface_action_points(surface_mask_context))
	if action_points.is_empty():
		action_points = ordered_positions.duplicate()

	var board_center: Vector2 = board_size * base_center_factor
	var action_bounds: Rect2 = _trimmed_bounds_for_positions(
		action_points,
		_trim_ratio_for(template_profile)
	)
	var action_center: Vector2 = action_bounds.position + action_bounds.size * 0.5
	var ground_center: Vector2 = action_center.lerp(board_center, _ground_center_pull_for(template_profile))
	var board_unit: float = maxf(1.0, minf(board_size.x, board_size.y))
	var bed_half_size: Vector2 = _bed_half_size_for(template_profile, action_bounds.size, board_unit)
	var bed_rotation_degrees: float = _bed_rotation_degrees_for(board_seed, template_profile)
	var pocket_masks: Array[Dictionary] = _build_pocket_masks(graph_nodes)
	pocket_masks.append_array(_build_clearing_masks(surface_mask_context))
	var shapes: Array[Dictionary] = [{
		"family": "bed",
		"center": _clamp_shape_center(ground_center, bed_half_size, board_size, min_board_margin),
		"half_size": bed_half_size,
		"rotation_degrees": bed_rotation_degrees,
		"tone_shift": 0.0,
		"alpha_scale": _bed_alpha_scale_for(template_profile),
		"shape": "ellipse",
		"terrain_role": "negative_space_bed",
		"mask_source": _surface_mask_source(surface_mask_context, "action_bounds"),
		"exclusion_source": _surface_mask_source(surface_mask_context, "landmark_footprints"),
	}]
	shapes.append_array(
		_build_corridor_ground_shapes(
			board_size,
			layout_edges,
			template_profile,
			board_seed,
			min_board_margin,
			pocket_masks,
			surface_mask_context
		)
	)
	shapes.append_array(_build_pocket_ground_shapes(board_size, graph_nodes, min_board_margin))

	var rng := RandomNumberGenerator.new()
	rng.seed = _derive_seed(board_seed, "ground")
	var patch_count: int = int(GROUND_PATCH_COUNT_BY_PROFILE.get(template_profile, GROUND_PATCH_COUNT_BY_PROFILE["corridor"]))
	var breakup_slots: Array[Vector2] = _breakup_zone_slots(board_size, template_profile, min_board_margin)
	for patch_index in range(min(patch_count, breakup_slots.size())):
		var anchor: Vector2 = breakup_slots[patch_index]
		var offset_basis: Dictionary = _offset_basis_for_anchor(anchor, ground_center, patch_index, patch_count, board_seed)
		var outward_direction: Vector2 = offset_basis.get("outward_direction", Vector2.UP)
		var tangent_direction: Vector2 = offset_basis.get("tangent_direction", Vector2.RIGHT)
		var family: String = "breakup"
		var half_size: Vector2 = _patch_half_size_for(template_profile, bed_half_size, family, rng)
		var radial_offset: float = rng.randf_range(-half_size.y * 0.18, half_size.y * 0.18)
		var tangential_offset: float = rng.randf_range(-bed_half_size.x * 0.08, bed_half_size.x * 0.08)
		var candidate_center: Vector2 = (
			anchor
			+ outward_direction * radial_offset
			+ tangent_direction * tangential_offset
		).lerp(anchor, 0.84)
		candidate_center = _clamp_shape_center_to_local_rect(
			candidate_center,
			half_size,
			anchor,
			Vector2(half_size.x * 1.6, half_size.y * 1.8)
		)
		if _center_conflicts_with_pocket_masks(candidate_center, half_size, pocket_masks):
			continue
		shapes.append({
			"family": family,
			"center": _clamp_shape_center(candidate_center, half_size, board_size, min_board_margin),
			"half_size": half_size,
			"rotation_degrees": rng.randf_range(-18.0, 18.0) + bed_rotation_degrees * 0.46,
			"tone_shift": rng.randf_range(-0.08, 0.08),
			"alpha_scale": rng.randf_range(0.62, 0.76),
			"shape": "ellipse",
			"terrain_role": "route_separator_breakup",
			"mask_source": "negative_space_slots",
			"exclusion_source": _surface_mask_source(surface_mask_context, "landmark_footprints"),
		})
	return shapes


static func _action_points(ordered_positions: Array[Vector2], layout_edges: Array) -> Array[Vector2]:
	var points: Array[Vector2] = ordered_positions.duplicate()
	for edge_variant in layout_edges:
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		var edge_points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
		if edge_points.is_empty():
			continue
		points.append(edge_points[0])
		if edge_points.size() >= 2:
			points.append(edge_points[edge_points.size() - 1])
			points.append(_polyline_midpoint(edge_points))
	return points


static func _surface_action_points(surface_mask_context: Dictionary) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for surface_variant in surface_mask_context.get("path_surfaces", []):
		if typeof(surface_variant) != TYPE_DICTIONARY:
			continue
		var surface_entry: Dictionary = surface_variant
		var surface_points: PackedVector2Array = surface_entry.get("centerline_points", PackedVector2Array())
		if surface_points.is_empty():
			continue
		points.append(surface_points[0])
		if surface_points.size() >= 2:
			points.append(surface_points[surface_points.size() - 1])
			points.append(_polyline_midpoint(surface_points))
	for clearing_variant in surface_mask_context.get("clearing_surfaces", []):
		if typeof(clearing_variant) != TYPE_DICTIONARY:
			continue
		var clearing_entry: Dictionary = clearing_variant
		var center: Vector2 = Vector2(clearing_entry.get("center", Vector2.ZERO))
		var radius: float = float(clearing_entry.get("radius", 0.0))
		if center == Vector2.ZERO or radius <= 0.0:
			continue
		points.append(center)
		points.append(center + Vector2(radius, 0.0))
		points.append(center + Vector2(-radius, 0.0))
		points.append(center + Vector2(0.0, radius))
		points.append(center + Vector2(0.0, -radius))
	return points


static func _ordered_node_positions(graph_nodes: Array[Dictionary]) -> Array[Vector2]:
	var ordered_nodes: Array[Dictionary] = []
	for node_variant in graph_nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var world_position: Vector2 = node_entry.get("world_position", Vector2.ZERO)
		if world_position == Vector2.ZERO:
			continue
		ordered_nodes.append(node_entry)
	ordered_nodes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("node_id", 0)) < int(b.get("node_id", 0))
	)
	var ordered_positions: Array[Vector2] = []
	for node_entry in ordered_nodes:
		ordered_positions.append(node_entry.get("world_position", Vector2.ZERO))
	return ordered_positions


static func _average_position(points: Array[Vector2]) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var accumulator := Vector2.ZERO
	for point in points:
		accumulator += point
	return accumulator / float(points.size())


static func _bounds_for_positions(points: Array[Vector2]) -> Rect2:
	if points.is_empty():
		return Rect2()
	var min_point: Vector2 = points[0]
	var max_point: Vector2 = points[0]
	for point in points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	return Rect2(min_point, max_point - min_point)


static func _trimmed_bounds_for_positions(points: Array[Vector2], trim_ratio: Vector2) -> Rect2:
	if points.size() < 5:
		return _bounds_for_positions(points)
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
		return _bounds_for_positions(points)
	var trimmed_bounds := Rect2(
		Vector2(sorted_x[min_index_x], sorted_y[min_index_y]),
		Vector2(
			sorted_x[max_index_x] - sorted_x[min_index_x],
			sorted_y[max_index_y] - sorted_y[min_index_y]
		)
	)
	if trimmed_bounds.size.x <= 0.001 or trimmed_bounds.size.y <= 0.001:
		return _bounds_for_positions(points)
	return trimmed_bounds


static func _polyline_midpoint(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]
	var total_length: float = 0.0
	for index in range(points.size() - 1):
		total_length += points[index].distance_to(points[index + 1])
	if total_length <= 0.001:
		var midpoint_index: int = max(0, int(floor(float(points.size() - 1) * 0.5)))
		return points[midpoint_index]
	var remaining_length: float = total_length * 0.5
	for index in range(points.size() - 1):
		var from_point: Vector2 = points[index]
		var to_point: Vector2 = points[index + 1]
		var segment_length: float = from_point.distance_to(to_point)
		if segment_length <= 0.001:
			continue
		if remaining_length <= segment_length:
			return from_point.lerp(to_point, remaining_length / segment_length)
		remaining_length -= segment_length
	return points[points.size() - 1]


static func _bed_half_size_for(template_profile: String, node_spread: Vector2, board_unit: float) -> Vector2:
	var spread_half_size := Vector2(
		clampf(node_spread.x * 0.52, board_unit * 0.22, board_unit * 0.40),
		clampf(node_spread.y * 0.48, board_unit * 0.16, board_unit * 0.30)
	)
	var profile_scale: Vector2 = GROUND_BED_SIZE_MULTIPLIERS_BY_PROFILE.get(template_profile, GROUND_BED_SIZE_MULTIPLIERS_BY_PROFILE["corridor"])
	return Vector2(
		spread_half_size.x * profile_scale.x,
		spread_half_size.y * profile_scale.y
	)


static func _bed_rotation_degrees_for(board_seed: int, template_profile: String) -> float:
	var profile_bias: float = 0.0
	match template_profile:
		"corridor":
			profile_bias = -4.0
		"openfield":
			profile_bias = 2.0
		"loop":
			profile_bias = -1.0
	return float((_derive_seed(board_seed, "ground-bed-rotation") % 19) - 9) + profile_bias


static func _bed_alpha_scale_for(template_profile: String) -> float:
	return float(GROUND_BED_ALPHA_SCALE_BY_PROFILE.get(template_profile, GROUND_BED_ALPHA_SCALE_BY_PROFILE["corridor"]))


static func _trim_ratio_for(template_profile: String) -> Vector2:
	return GROUND_ACTION_BOUNDS_TRIM_BY_PROFILE.get(template_profile, GROUND_ACTION_BOUNDS_TRIM_BY_PROFILE["corridor"])


static func _ground_center_pull_for(template_profile: String) -> float:
	return float(GROUND_CENTER_PULL_BY_PROFILE.get(template_profile, GROUND_CENTER_PULL_BY_PROFILE["corridor"]))


static func _anchor_index_for(board_seed: int, patch_index: int, position_count: int) -> int:
	if position_count <= 0:
		return 0
	var seed_value: int = abs(_derive_seed(board_seed, "ground-anchor:%d" % patch_index))
	return seed_value % position_count


static func _offset_basis_for_anchor(
	anchor: Vector2,
	ground_center: Vector2,
	patch_index: int,
	patch_count: int,
	board_seed: int
) -> Dictionary:
	var outward_direction: Vector2 = anchor - ground_center
	if outward_direction.length_squared() <= 0.001:
		var fallback_angle: float = (TAU * float(patch_index) / float(max(1, patch_count))) + float((_derive_seed(board_seed, "ground-angle:%d" % patch_index) % 19) - 9) * 0.02
		outward_direction = Vector2.RIGHT.rotated(fallback_angle)
	else:
		outward_direction = outward_direction.normalized()
	var tangent_direction: Vector2 = Vector2(-outward_direction.y, outward_direction.x)
	return {
		"outward_direction": outward_direction,
		"tangent_direction": tangent_direction,
	}


static func _patch_half_size_for(
	template_profile: String,
	bed_half_size: Vector2,
	family: String,
	rng: RandomNumberGenerator
) -> Vector2:
	var min_scale: Vector2
	var max_scale: Vector2
	match family:
		"breakup":
			min_scale = Vector2(0.18, 0.16)
			max_scale = Vector2(0.26, 0.24)
		_:
			min_scale = Vector2(0.24, 0.20)
			max_scale = Vector2(0.34, 0.30)
	if template_profile == "openfield":
		max_scale += Vector2(0.02, 0.02)
	elif template_profile == "corridor":
		min_scale -= Vector2(0.02, 0.01)
	return Vector2(
		bed_half_size.x * rng.randf_range(min_scale.x, max_scale.x),
		bed_half_size.y * rng.randf_range(min_scale.y, max_scale.y)
	)


static func _patch_center_pull_for(template_profile: String, family: String) -> float:
	var profile_map: Dictionary = GROUND_PATCH_CENTER_PULL_BY_PROFILE.get(
		template_profile,
		GROUND_PATCH_CENTER_PULL_BY_PROFILE["corridor"]
	)
	return float(profile_map.get(family, profile_map.get("patch", 0.22)))


static func _patch_local_half_size(template_profile: String, bed_half_size: Vector2, family: String) -> Vector2:
	var profile_map: Dictionary = GROUND_PATCH_LOCAL_BOUNDS_SCALE_BY_PROFILE.get(
		template_profile,
		GROUND_PATCH_LOCAL_BOUNDS_SCALE_BY_PROFILE["corridor"]
	)
	var scale: Vector2 = profile_map.get(family, profile_map.get("patch", Vector2.ONE))
	return Vector2(bed_half_size.x * scale.x, bed_half_size.y * scale.y)


static func _clamp_shape_center(position: Vector2, half_size: Vector2, board_size: Vector2, min_board_margin: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, min_board_margin.x + half_size.x, board_size.x - min_board_margin.x - half_size.x),
		clampf(position.y, min_board_margin.y + half_size.y, board_size.y - min_board_margin.y - half_size.y)
	)


static func _clamp_shape_center_to_local_rect(
	position: Vector2,
	half_size: Vector2,
	rect_center: Vector2,
	rect_half_size: Vector2
) -> Vector2:
	return Vector2(
		clampf(position.x, rect_center.x - rect_half_size.x + half_size.x, rect_center.x + rect_half_size.x - half_size.x),
		clampf(position.y, rect_center.y - rect_half_size.y + half_size.y, rect_center.y + rect_half_size.y - half_size.y)
	)


static func _derive_seed(board_seed: int, salt: String) -> int:
	return MapBoardLayoutSolverScript.derive_seed(board_seed, salt)


static func _build_pocket_masks(graph_nodes: Array[Dictionary]) -> Array[Dictionary]:
	var pocket_masks: Array[Dictionary] = []
	for node_entry in graph_nodes:
		var footprint_variant: Variant = node_entry.get("landmark_footprint", {})
		if typeof(footprint_variant) != TYPE_DICTIONARY:
			continue
		var footprint: Dictionary = footprint_variant
		if footprint.is_empty():
			continue
		var pocket_half_size: Vector2 = Vector2(footprint.get("pocket_half_size", Vector2.ZERO))
		if pocket_half_size.x <= 0.0 or pocket_half_size.y <= 0.0:
			continue
		var node_center: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
		pocket_masks.append({
			"node_id": int(node_entry.get("node_id", -1)),
			"center": node_center + Vector2(footprint.get("pocket_center_offset", Vector2.ZERO)),
			"half_size": pocket_half_size,
			"rotation_degrees": float(footprint.get("pocket_rotation_degrees", 0.0)),
			"shape": String(footprint.get("pocket_shape", "ellipse")),
		})
	return pocket_masks


static func _build_clearing_masks(surface_mask_context: Dictionary) -> Array[Dictionary]:
	var masks: Array[Dictionary] = []
	for clearing_variant in surface_mask_context.get("clearing_surfaces", []):
		if typeof(clearing_variant) != TYPE_DICTIONARY:
			continue
		var clearing_entry: Dictionary = clearing_variant
		var radius: float = float(clearing_entry.get("radius", 0.0))
		if radius <= 0.0:
			continue
		masks.append({
			"node_id": int(clearing_entry.get("node_id", -1)),
			"center": Vector2(clearing_entry.get("center", Vector2.ZERO)),
			"half_size": Vector2.ONE * radius,
			"rotation_degrees": 0.0,
			"shape": "ellipse",
			"mask_source": "render_model.clearing_surfaces",
		})
	return masks


static func _build_corridor_ground_shapes(
	board_size: Vector2,
	layout_edges: Array,
	template_profile: String,
	board_seed: int,
	min_board_margin: Vector2,
	pocket_masks: Array[Dictionary],
	surface_mask_context: Dictionary = {}
) -> Array[Dictionary]:
	var candidate_shapes: Array[Dictionary] = []
	var board_unit: float = maxf(1.0, minf(board_size.x, board_size.y))
	for source_entry in _corridor_ground_sources(layout_edges, surface_mask_context):
		var points: PackedVector2Array = source_entry.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		var total_length: float = 0.0
		for point_index in range(points.size() - 1):
			total_length += points[point_index].distance_to(points[point_index + 1])
		if total_length <= board_unit * 0.14:
			continue
		var midpoint: Vector2 = _polyline_midpoint(points)
		var direction: Vector2 = points[points.size() - 1] - points[0]
		if direction.length_squared() <= 0.001:
			continue
		var half_size := Vector2(
			clampf(total_length * 0.18, board_unit * 0.08, board_unit * 0.18),
			maxf(
				float(GROUND_CORRIDOR_HALF_HEIGHT_BY_PROFILE.get(template_profile, GROUND_CORRIDOR_HALF_HEIGHT_BY_PROFILE["corridor"])),
				float(source_entry.get("surface_width", 0.0)) * 0.60
			)
		)
		if _center_conflicts_with_pocket_masks(midpoint, half_size, pocket_masks):
			continue
		var edge_key: String = String(source_entry.get("source_key", ""))
		candidate_shapes.append({
			"family": "corridor",
			"center": _clamp_shape_center(midpoint, half_size, board_size, min_board_margin),
			"half_size": half_size,
			"rotation_degrees": rad_to_deg(direction.angle()),
			"tone_shift": float((_derive_seed(board_seed, "ground-corridor-tone:%s" % edge_key) % 17) - 8) * 0.008,
			"alpha_scale": 0.74,
			"shape": "ellipse",
			"terrain_role": "path_surface_ground_frame",
			"mask_source": String(source_entry.get("mask_source", "layout_edges")),
			"exclusion_source": _surface_mask_source(surface_mask_context, "landmark_footprints"),
			"sort_length": total_length,
			"sort_key": edge_key,
		})
	candidate_shapes.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_length: float = float(left.get("sort_length", 0.0))
		var right_length: float = float(right.get("sort_length", 0.0))
		if not is_equal_approx(left_length, right_length):
			return left_length > right_length
		return String(left.get("sort_key", "")) < String(right.get("sort_key", ""))
	)
	var capped_shapes: Array[Dictionary] = []
	var max_shapes: int = int(GROUND_CORRIDOR_SHAPE_CAP_BY_PROFILE.get(template_profile, GROUND_CORRIDOR_SHAPE_CAP_BY_PROFILE["corridor"]))
	for shape_index in range(min(max_shapes, candidate_shapes.size())):
		var shape: Dictionary = candidate_shapes[shape_index].duplicate(true)
		shape.erase("sort_length")
		shape.erase("sort_key")
		capped_shapes.append(shape)
	return capped_shapes


static func _corridor_ground_sources(layout_edges: Array, surface_mask_context: Dictionary) -> Array[Dictionary]:
	var sources: Array[Dictionary] = []
	for surface_variant in surface_mask_context.get("path_surfaces", []):
		if typeof(surface_variant) != TYPE_DICTIONARY:
			continue
		var surface_entry: Dictionary = surface_variant
		var points: PackedVector2Array = surface_entry.get("centerline_points", PackedVector2Array())
		if points.size() < 2:
			continue
		sources.append({
			"points": points,
			"source_key": String(surface_entry.get("surface_id", "")),
			"surface_width": maxf(
				float(surface_entry.get("surface_width", 0.0)),
				float(surface_entry.get("outer_width", 0.0))
			),
			"mask_source": "render_model.path_surfaces",
		})
	if not sources.is_empty():
		return sources
	for edge_variant in layout_edges:
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge_entry: Dictionary = edge_variant
		var points: PackedVector2Array = edge_entry.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		sources.append({
			"points": points,
			"source_key": String(edge_entry.get("edge_key", "")),
			"surface_width": 0.0,
			"mask_source": "layout_edges",
		})
	return sources


static func _build_pocket_ground_shapes(
	board_size: Vector2,
	graph_nodes: Array[Dictionary],
	min_board_margin: Vector2
) -> Array[Dictionary]:
	var pocket_shapes: Array[Dictionary] = []
	for node_entry in graph_nodes:
		var footprint_variant: Variant = node_entry.get("landmark_footprint", {})
		if typeof(footprint_variant) != TYPE_DICTIONARY:
			continue
		var footprint: Dictionary = footprint_variant
		if footprint.is_empty():
			continue
		var pocket_half_size: Vector2 = Vector2(footprint.get("pocket_half_size", Vector2.ZERO)) * Vector2(0.92, 0.88)
		if pocket_half_size.x <= 0.0 or pocket_half_size.y <= 0.0:
			continue
		var node_center: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
		pocket_shapes.append({
			"family": "pocket",
			"center": _clamp_shape_center(
				node_center + Vector2(footprint.get("pocket_center_offset", Vector2.ZERO)),
				pocket_half_size,
				board_size,
				min_board_margin
			),
			"half_size": pocket_half_size,
			"rotation_degrees": float(footprint.get("pocket_rotation_degrees", 0.0)),
			"tone_shift": 0.0,
			"alpha_scale": 0.76,
			"shape": String(footprint.get("pocket_shape", "ellipse")),
			"terrain_role": "landmark_pocket_ground",
			"mask_source": "landmark_footprints",
			"exclusion_source": "landmark_footprints",
		})
	return pocket_shapes


static func _breakup_zone_slots(board_size: Vector2, template_profile: String, min_board_margin: Vector2) -> Array[Vector2]:
	var slots: Array[Vector2] = []
	for factor_variant in GROUND_BREAKUP_ZONE_FACTORS_BY_PROFILE.get(
		template_profile,
		GROUND_BREAKUP_ZONE_FACTORS_BY_PROFILE["corridor"]
	):
		var factor: Vector2 = Vector2(factor_variant)
		var candidate: Vector2 = board_size * factor
		slots.append(Vector2(
			clampf(candidate.x, min_board_margin.x + 48.0, board_size.x - min_board_margin.x - 48.0),
			clampf(candidate.y, min_board_margin.y + 48.0, board_size.y - min_board_margin.y - 48.0)
		))
	return slots


static func _center_conflicts_with_pocket_masks(center: Vector2, half_size: Vector2, pocket_masks: Array[Dictionary]) -> bool:
	for mask_entry in pocket_masks:
		var mask_center: Vector2 = Vector2(mask_entry.get("center", Vector2.ZERO))
		var mask_half_size: Vector2 = Vector2(mask_entry.get("half_size", Vector2.ZERO))
		var expanded_mask_half_size := Vector2(
			mask_half_size.x + half_size.x * 0.44,
			mask_half_size.y + half_size.y * 0.40
		)
		if _point_inside_mask(center, mask_center, expanded_mask_half_size, String(mask_entry.get("shape", "ellipse"))):
			return true
	return false


static func _point_inside_mask(point: Vector2, center: Vector2, half_size: Vector2, shape: String) -> bool:
	if half_size.x <= 0.001 or half_size.y <= 0.001:
		return false
	if shape == "rect":
		return Rect2(center - half_size, half_size * 2.0).has_point(point)
	if shape == "diamond":
		return absf(point.x - center.x) / half_size.x + absf(point.y - center.y) / half_size.y <= 1.0
	var normalized_x: float = (point.x - center.x) / half_size.x
	var normalized_y: float = (point.y - center.y) / half_size.y
	return normalized_x * normalized_x + normalized_y * normalized_y <= 1.0


static func _surface_mask_source(surface_mask_context: Dictionary, fallback_source: String) -> String:
	if not (surface_mask_context.get("path_surfaces", []) as Array).is_empty() or not (surface_mask_context.get("clearing_surfaces", []) as Array).is_empty():
		return "render_model.path_surfaces+clearing_surfaces"
	return fallback_source
