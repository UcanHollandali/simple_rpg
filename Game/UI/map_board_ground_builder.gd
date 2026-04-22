# Layer: UI
extends RefCounted
class_name MapBoardGroundBuilder

const MapBoardLayoutSolverScript = preload("res://Game/UI/map_board_layout_solver.gd")

const GROUND_PATCH_COUNT_BY_PROFILE := {
	"corridor": 7,
	"openfield": 5,
	"loop": 6,
}
const GROUND_BED_SIZE_MULTIPLIERS_BY_PROFILE := {
	"corridor": Vector2(1.10, 0.92),
	"openfield": Vector2(1.18, 0.98),
	"loop": Vector2(1.14, 0.96),
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
	template_profile: String,
	board_seed: int,
	base_center_factor: Vector2,
	min_board_margin: Vector2
) -> Array[Dictionary]:
	var ordered_positions: Array[Vector2] = _ordered_node_positions(graph_nodes)
	if ordered_positions.is_empty():
		return []

	var board_center: Vector2 = board_size * base_center_factor
	var cluster_center: Vector2 = _average_position(ordered_positions)
	var ground_center: Vector2 = cluster_center.lerp(board_center, 0.18)
	var node_bounds: Rect2 = _bounds_for_positions(ordered_positions)
	var board_unit: float = maxf(1.0, minf(board_size.x, board_size.y))
	var bed_half_size: Vector2 = _bed_half_size_for(template_profile, node_bounds.size, board_unit)
	var bed_rotation_degrees: float = _bed_rotation_degrees_for(board_seed, template_profile)
	var shapes: Array[Dictionary] = [{
		"family": "bed",
		"center": _clamp_shape_center(ground_center, bed_half_size, board_size, min_board_margin),
		"half_size": bed_half_size,
		"rotation_degrees": bed_rotation_degrees,
		"tone_shift": 0.0,
		"alpha_scale": 1.0,
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
		).lerp(ground_center, 0.12 if family == "patch" else 0.06)
		shapes.append({
			"family": family,
			"center": _clamp_shape_center(candidate_center, half_size, board_size, min_board_margin),
			"half_size": half_size,
			"rotation_degrees": rng.randf_range(-18.0, 18.0) + bed_rotation_degrees * 0.46,
			"tone_shift": rng.randf_range(-0.08, 0.08),
			"alpha_scale": rng.randf_range(0.88, 1.06) if family == "patch" else rng.randf_range(0.74, 0.92),
		})
	return shapes


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


static func _bed_half_size_for(template_profile: String, node_spread: Vector2, board_unit: float) -> Vector2:
	var spread_half_size := Vector2(
		clampf(node_spread.x * 0.58, board_unit * 0.22, board_unit * 0.42),
		clampf(node_spread.y * 0.52, board_unit * 0.16, board_unit * 0.32)
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


static func _clamp_shape_center(position: Vector2, half_size: Vector2, board_size: Vector2, min_board_margin: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, min_board_margin.x + half_size.x, board_size.x - min_board_margin.x - half_size.x),
		clampf(position.y, min_board_margin.y + half_size.y, board_size.y - min_board_margin.y - half_size.y)
	)


static func _derive_seed(board_seed: int, salt: String) -> int:
	return MapBoardLayoutSolverScript.derive_seed(board_seed, salt)
