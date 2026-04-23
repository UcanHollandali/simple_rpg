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
	"corridor": Vector2(0.82, 0.68),
	"openfield": Vector2(1.08, 0.92),
	"loop": Vector2(1.04, 0.90),
}
const GROUND_BED_ALPHA_SCALE_BY_PROFILE := {
	"corridor": 0.68,
	"openfield": 0.92,
	"loop": 0.90,
}
const GROUND_CENTER_PULL_BY_PROFILE := {
	"corridor": 0.04,
	"openfield": 0.08,
	"loop": 0.06,
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


# Contract:
# - Input is limited to existing board-space derived truth: board size, graph-node positions,
#   template profile, existing board seed, and board margin/center hints.
# - Output is an ordered array of board-space ground shapes with these fields:
#   `family`, `center`, `half_size`, `rotation_degrees`, `tone_shift`, `alpha_scale`.
# - The builder never reads node-family semantics or route adjacency meaning.
# - MapBoardCanvas owns drawing, and MapBoardStyle owns every visual token used to render it.
static func build_ground_shapes(
	board_size: Vector2,
	graph_nodes: Array[Dictionary],
	layout_edges: Array,
	template_profile: String,
	board_seed: int,
	base_center_factor: Vector2,
	min_board_margin: Vector2
) -> Array[Dictionary]:
	var ordered_positions: Array[Vector2] = _ordered_node_positions(graph_nodes)
	if ordered_positions.is_empty():
		return []
	var action_points: Array[Vector2] = _action_points(ordered_positions, layout_edges)
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
	var shapes: Array[Dictionary] = [{
		"family": "bed",
		"center": _clamp_shape_center(ground_center, bed_half_size, board_size, min_board_margin),
		"half_size": bed_half_size,
		"rotation_degrees": bed_rotation_degrees,
		"tone_shift": 0.0,
		"alpha_scale": _bed_alpha_scale_for(template_profile),
	}]

	var rng := RandomNumberGenerator.new()
	rng.seed = _derive_seed(board_seed, "ground")
	var patch_count: int = int(GROUND_PATCH_COUNT_BY_PROFILE.get(template_profile, GROUND_PATCH_COUNT_BY_PROFILE["corridor"]))
	for patch_index in range(patch_count):
		var anchor: Vector2 = ordered_positions[_anchor_index_for(board_seed, patch_index, ordered_positions.size())]
		var offset_basis: Dictionary = _offset_basis_for_anchor(anchor, ground_center, patch_index, patch_count, board_seed)
		var outward_direction: Vector2 = offset_basis.get("outward_direction", Vector2.UP)
		var tangent_direction: Vector2 = offset_basis.get("tangent_direction", Vector2.RIGHT)
		var family: String = "patch" if patch_index < patch_count - 2 else "breakup"
		var half_size: Vector2 = _patch_half_size_for(template_profile, bed_half_size, family, rng)
		var radial_offset: float = rng.randf_range(-half_size.y * 0.40, bed_half_size.y * 0.18)
		var tangential_offset: float = rng.randf_range(-bed_half_size.x * 0.18, bed_half_size.x * 0.18)
		var candidate_center: Vector2 = (
			anchor
			+ outward_direction * radial_offset
			+ tangent_direction * tangential_offset
		).lerp(ground_center, _patch_center_pull_for(template_profile, family))
		candidate_center = _clamp_shape_center_to_local_rect(
			candidate_center,
			half_size,
			ground_center,
			_patch_local_half_size(template_profile, bed_half_size, family)
		)
		shapes.append({
			"family": family,
			"center": _clamp_shape_center(candidate_center, half_size, board_size, min_board_margin),
			"half_size": half_size,
			"rotation_degrees": rng.randf_range(-18.0, 18.0) + bed_rotation_degrees * 0.46,
			"tone_shift": rng.randf_range(-0.08, 0.08),
			"alpha_scale": rng.randf_range(0.80, 0.96) if family == "patch" else rng.randf_range(0.66, 0.82),
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
