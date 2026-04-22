# Layer: UI
extends RefCounted
class_name MapBoardLayoutSolver

const MapBoardGeometryScript = preload("res://Game/UI/map_board_geometry.gd")


static func build_world_positions(
	graph_snapshot: Array[Dictionary],
	board_size: Vector2,
	layout_context: Dictionary,
	template_profile: String,
	board_seed: int,
	config: Dictionary
) -> Dictionary:
	var base_center_factor: Vector2 = config.get("base_center_factor", Vector2(0.50, 0.60))
	var min_board_margin: Vector2 = config.get("min_board_margin", Vector2(96.0, 108.0))
	var depth_step_factors: Array = config.get("depth_step_factors", [])
	var depth_spread_factors: Array = config.get("depth_spread_factors", [])
	var depth_direction_pull_factors: Array = config.get("depth_direction_pull_factors", [])
	var depth_lateral_spread_scale_factors: Array = config.get("depth_lateral_spread_scale_factors", [])
	var depth_downward_bias_factors: Array = config.get("depth_downward_bias_factors", [])
	var depth_center_pull_factors: Array = config.get("depth_center_pull_factors", [])
	var clearing_radius_by_node_id: Dictionary = config.get("clearing_radius_by_node_id", {})
	var origin: Vector2 = board_size * base_center_factor
	var board_min_dimension: float = min(board_size.x, board_size.y)
	var world_positions: Dictionary = {}
	var start_node_id: int = int(layout_context.get("start_node_id", 0))
	var depth_by_node_id: Dictionary = layout_context.get("depth_by_node_id", {})
	var parent_ids_by_node_id: Dictionary = layout_context.get("parent_ids_by_node_id", {})
	var primary_parent_by_node_id: Dictionary = layout_context.get("primary_parent_by_node_id", {})
	var child_ids_by_parent: Dictionary = layout_context.get("child_ids_by_parent", {})
	var branch_root_by_node_id: Dictionary = layout_context.get("branch_root_by_node_id", {})
	world_positions[start_node_id] = origin

	for node_id in _sorted_node_ids_by_depth(graph_snapshot, depth_by_node_id):
		if node_id == start_node_id:
			continue
		var node_depth: int = int(depth_by_node_id.get(node_id, 0))
		var parent_ids: Array[int] = int_array_from_variant(parent_ids_by_node_id.get(node_id, []))
		if parent_ids.is_empty():
			world_positions[node_id] = origin
			continue
		var primary_parent_id: int = int(primary_parent_by_node_id.get(node_id, start_node_id))
		var parent_position: Vector2 = world_positions.get(primary_parent_id, origin)
		var branch_root_id: int = int(branch_root_by_node_id.get(node_id, primary_parent_id))
		var branch_direction: Vector2 = branch_direction_for_root(layout_context, branch_root_id)
		var outward_source: Vector2 = parent_position - origin
		var outward_direction: Vector2 = branch_direction if outward_source.length_squared() <= 0.001 else (branch_direction * 0.62 + outward_source.normalized() * 0.38).normalized()
		outward_direction = _apply_depth_direction_pull(
			outward_direction,
			node_depth,
			branch_direction,
			template_profile,
			depth_direction_pull_factors
		)
		var tangent_direction: Vector2 = Vector2(-outward_direction.y, outward_direction.x)
		var node_seed_rng := RandomNumberGenerator.new()
		node_seed_rng.seed = derive_seed(board_seed, "layout:%d" % node_id)
		var position: Vector2
		if parent_ids.size() > 1:
			position = _position_reconnect_node(
				node_id,
				parent_ids,
				world_positions,
				layout_context,
				board_size,
				template_profile,
				board_seed,
				origin,
				depth_direction_pull_factors,
				depth_lateral_spread_scale_factors,
				depth_downward_bias_factors,
				depth_center_pull_factors
			)
		else:
			var sibling_ids: Array[int] = int_array_from_variant(child_ids_by_parent.get(primary_parent_id, []))
			var sibling_index: int = sibling_ids.find(node_id)
			var sibling_offset_units: float = _symmetric_offset_for_index(sibling_index, sibling_ids.size())
			var child_ids: Array[int] = int_array_from_variant(child_ids_by_parent.get(node_id, []))
			var leaf_like: bool = child_ids.is_empty()
			var step_length: float = board_min_dimension * _depth_step_factor(node_depth, depth_step_factors) * _profile_layout_scale(template_profile)
			if leaf_like and node_depth >= max(2, int(layout_context.get("max_depth", 0)) - 1):
				step_length += board_min_dimension * 0.018
			var lateral_spread_scale: float = _depth_lateral_spread_scale(
				node_depth,
				branch_direction,
				depth_lateral_spread_scale_factors
			)
			var spread_length: float = board_min_dimension * _depth_spread_factor(node_depth, depth_spread_factors) * _profile_spread_scale(template_profile) * lateral_spread_scale
			var tangent_jitter: float = node_seed_rng.randf_range(-board_min_dimension * 0.014, board_min_dimension * 0.014) * _depth_lateral_random_scale(lateral_spread_scale)
			var outward_jitter: float = node_seed_rng.randf_range(-board_min_dimension * 0.008, board_min_dimension * 0.020)
			var branch_curve_bias: float = node_seed_rng.randf_range(-board_min_dimension * 0.010, board_min_dimension * 0.010) * _depth_lateral_random_scale(lateral_spread_scale)
			var lateral_offset: float = spread_length * sibling_offset_units + tangent_jitter + branch_curve_bias
			position = parent_position + outward_direction * (step_length + outward_jitter) + tangent_direction * lateral_offset
			position += _depth_downward_bias(node_depth, branch_direction, board_size, template_profile, depth_downward_bias_factors)
			position = _apply_depth_center_pull(position, origin, node_depth, branch_direction, template_profile, depth_center_pull_factors)
		world_positions[node_id] = _clamp_to_board(position, board_size, min_board_margin)

	_relax_collisions(
		world_positions,
		graph_snapshot,
		board_size,
		layout_context,
		clearing_radius_by_node_id,
		min_board_margin
	)
	_reduce_edge_crossings(world_positions, graph_snapshot, board_size, layout_context, min_board_margin)
	_relax_collisions(
		world_positions,
		graph_snapshot,
		board_size,
		layout_context,
		clearing_radius_by_node_id,
		min_board_margin
	)
	return world_positions


static func int_array_from_variant(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		result.append(int(item))
	return result


static func branch_direction_for_root(layout_context: Dictionary, branch_root_id: int) -> Vector2:
	var branch_direction_by_root: Dictionary = layout_context.get("branch_direction_by_root", {})
	var direction: Vector2 = branch_direction_by_root.get(branch_root_id, Vector2(0.0, -1.0))
	return direction if direction.length_squared() > 0.001 else Vector2(0.0, -1.0)


static func derive_seed(board_seed: int, salt: String) -> int:
	return hash_seed_string("%d|%s" % [board_seed, salt])


static func hash_seed_string(value: String) -> int:
	var accumulator: int = 216613626
	var bytes: PackedByteArray = value.to_utf8_buffer()
	for byte in bytes:
		accumulator = abs(int((accumulator ^ int(byte)) * 16777619))
	if accumulator == 0:
		return 1
	return accumulator


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


static func _position_reconnect_node(
	node_id: int,
	parent_ids: Array[int],
	world_positions: Dictionary,
	layout_context: Dictionary,
	board_size: Vector2,
	template_profile: String,
	board_seed: int,
	origin: Vector2,
	depth_direction_pull_factors: Array,
	depth_lateral_spread_scale_factors: Array,
	depth_downward_bias_factors: Array,
	depth_center_pull_factors: Array
) -> Vector2:
	var board_unit: float = min(board_size.x, board_size.y)
	var parent_positions: Array[Vector2] = []
	for parent_id in parent_ids:
		parent_positions.append(world_positions.get(parent_id, origin))
	var midpoint: Vector2 = _average_vector2_array(parent_positions)
	var branch_root_id: int = int(layout_context.get("branch_root_by_node_id", {}).get(node_id, parent_ids[0]))
	var branch_direction: Vector2 = branch_direction_for_root(layout_context, branch_root_id)
	var outward_direction: Vector2 = midpoint - origin
	if outward_direction.length_squared() <= 0.001:
		outward_direction = branch_direction
	else:
		outward_direction = (branch_direction * 0.48 + outward_direction.normalized() * 0.52).normalized()
	var depth_by_node_id: Dictionary = layout_context.get("depth_by_node_id", {})
	var node_depth: int = int(depth_by_node_id.get(node_id, 0))
	outward_direction = _apply_depth_direction_pull(
		outward_direction,
		node_depth,
		branch_direction,
		template_profile,
		depth_direction_pull_factors
	)
	var tangent_direction: Vector2 = Vector2(-outward_direction.y, outward_direction.x)
	var reconnect_rng := RandomNumberGenerator.new()
	reconnect_rng.seed = derive_seed(board_seed, "reconnect-layout:%d" % node_id)
	var outward_distance: float = board_unit * 0.072
	var tangent_distance: float = board_unit * 0.036
	match template_profile:
		"corridor":
			outward_distance = board_unit * 0.062
			tangent_distance = board_unit * 0.028
		"openfield":
			outward_distance = board_unit * 0.080
			tangent_distance = board_unit * 0.042
		"loop":
			outward_distance = board_unit * 0.076
			tangent_distance = board_unit * 0.040
	var lateral_spread_scale: float = _depth_lateral_spread_scale(
		node_depth,
		branch_direction,
		depth_lateral_spread_scale_factors
	)
	tangent_distance *= lateral_spread_scale
	var tangent_sign: float = -1.0 if (reconnect_rng.randi() & 1) == 0 else 1.0
	var tangent_jitter: float = reconnect_rng.randf_range(-board_unit * 0.010, board_unit * 0.010) * _depth_lateral_random_scale(lateral_spread_scale)
	var outward_jitter: float = reconnect_rng.randf_range(-board_unit * 0.008, board_unit * 0.014)
	var position: Vector2 = midpoint + outward_direction * (outward_distance + outward_jitter) + tangent_direction * (tangent_distance * tangent_sign + tangent_jitter)
	position += _depth_downward_bias(node_depth, branch_direction, board_size, template_profile, depth_downward_bias_factors)
	return _apply_depth_center_pull(position, origin, node_depth, branch_direction, template_profile, depth_center_pull_factors)


static func _symmetric_offset_for_index(index: int, count: int) -> float:
	if count <= 1 or index < 0:
		return 0.0
	return float(index) - (float(count - 1) * 0.5)


static func _depth_step_factor(depth: int, depth_step_factors: Array) -> float:
	if depth_step_factors.is_empty():
		return 0.0
	var factor_index: int = clampi(depth, 0, depth_step_factors.size() - 1)
	return float(depth_step_factors[factor_index])


static func _depth_spread_factor(depth: int, depth_spread_factors: Array) -> float:
	if depth_spread_factors.is_empty():
		return 0.0
	var factor_index: int = clampi(depth, 0, depth_spread_factors.size() - 1)
	return float(depth_spread_factors[factor_index])


static func _profile_layout_scale(template_profile: String) -> float:
	match template_profile:
		"corridor":
			return 1.02
		"openfield":
			return 1.08
		"loop":
			return 1.04
		_:
			return 1.0


static func _profile_spread_scale(template_profile: String) -> float:
	match template_profile:
		"corridor":
			return 0.96
		"openfield":
			return 1.18
		"loop":
			return 1.06
		_:
			return 1.0


static func _apply_depth_direction_pull(
	outward_direction: Vector2,
	node_depth: int,
	branch_direction: Vector2,
	template_profile: String,
	depth_direction_pull_factors: Array
) -> Vector2:
	if node_depth <= 1 or outward_direction.length_squared() <= 0.001:
		return outward_direction
	var base_pull: float = _depth_config_factor(node_depth, depth_direction_pull_factors, 0.0)
	match template_profile:
		"corridor":
			base_pull *= 1.06
		"openfield":
			base_pull *= 0.94
		"loop":
			base_pull *= 1.00
	var upward_pull: float = maxf(0.0, -branch_direction.y)
	var lateral_pull: float = 1.0 - absf(branch_direction.y)
	var downward_relief: float = maxf(0.0, branch_direction.y)
	var pull_weight: float = clampf(0.46 + lateral_pull * 0.54 + upward_pull * 0.28 - downward_relief * 0.04, 0.0, 1.0)
	var effective_pull: float = clampf(base_pull * pull_weight, 0.0, 0.64)
	return (outward_direction * (1.0 - effective_pull) + Vector2.DOWN * effective_pull).normalized()


static func _depth_lateral_spread_scale(node_depth: int, branch_direction: Vector2, depth_lateral_spread_scale_factors: Array) -> float:
	var base_scale: float = _depth_config_factor(node_depth, depth_lateral_spread_scale_factors, 1.0)
	var lateral_pull: float = 1.0 - absf(branch_direction.y)
	return lerpf(1.0, base_scale, clampf(0.40 + lateral_pull * 0.60, 0.0, 1.0))


static func _depth_lateral_random_scale(lateral_spread_scale: float) -> float:
	return lerpf(1.0, lateral_spread_scale, 0.78)


static func _apply_depth_center_pull(
	position: Vector2,
	origin: Vector2,
	node_depth: int,
	branch_direction: Vector2,
	template_profile: String,
	depth_center_pull_factors: Array
) -> Vector2:
	if node_depth <= 1:
		return position
	var base_pull: float = _depth_config_factor(node_depth, depth_center_pull_factors, 0.0)
	match template_profile:
		"corridor":
			base_pull *= 1.04
		"openfield":
			base_pull *= 0.94
		"loop":
			base_pull *= 1.00
	var lateral_pull: float = 1.0 - absf(branch_direction.y)
	var pull_weight: float = clampf(0.30 + lateral_pull * 0.70, 0.0, 1.0)
	var effective_pull: float = clampf(base_pull * pull_weight, 0.0, 0.32)
	var vertical_pull_scale: float = 0.78 if position.y < origin.y else 0.0
	var vertical_pull: float = clampf(effective_pull * vertical_pull_scale, 0.0, 0.13)
	return Vector2(lerpf(position.x, origin.x, effective_pull), lerpf(position.y, origin.y, vertical_pull))


static func _depth_downward_bias(
	node_depth: int,
	branch_direction: Vector2,
	board_size: Vector2,
	template_profile: String,
	depth_downward_bias_factors: Array
) -> Vector2:
	if node_depth <= 1:
		return Vector2.ZERO
	var board_unit: float = maxf(1.0, minf(board_size.x, board_size.y))
	var base_bias: float = board_unit * _depth_config_factor(node_depth, depth_downward_bias_factors, 0.0)
	match template_profile:
		"corridor":
			base_bias *= 1.08
		"openfield":
			base_bias *= 0.94
		"loop":
			base_bias *= 1.00
	var upward_pull: float = maxf(0.0, -branch_direction.y)
	var lateral_pull: float = 1.0 - absf(branch_direction.y)
	var downward_relief: float = maxf(0.0, branch_direction.y)
	var bias_weight: float = clampf(0.54 + upward_pull * 0.48 + lateral_pull * 0.18 - downward_relief * 0.02, 0.0, 1.0)
	return Vector2.DOWN * base_bias * bias_weight


static func _depth_config_factor(depth: int, factors: Array, fallback: float) -> float:
	if factors.is_empty():
		return fallback
	var factor_index: int = clampi(depth, 0, factors.size() - 1)
	return float(factors[factor_index])


static func _average_vector2_array(values: Array[Vector2]) -> Vector2:
	if values.is_empty():
		return Vector2.ZERO
	var total: Vector2 = Vector2.ZERO
	for value in values:
		total += value
	return total / float(values.size())


static func _clamp_to_board(position: Vector2, board_size: Vector2, min_board_margin: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, min_board_margin.x, board_size.x - min_board_margin.x),
		clampf(position.y, min_board_margin.y, board_size.y - min_board_margin.y)
	)


static func _relax_collisions(
	world_positions: Dictionary,
	graph_snapshot: Array[Dictionary],
	board_size: Vector2,
	layout_context: Dictionary,
	clearing_radius_by_node_id: Dictionary,
	min_board_margin: Vector2
) -> void:
	var ordered_node_ids: Array[int] = []
	for node_entry in graph_snapshot:
		ordered_node_ids.append(int(node_entry.get("node_id", -1)))
	var board_unit: float = min(board_size.x, board_size.y)
	var depth_by_node_id: Dictionary = layout_context.get("depth_by_node_id", {})
	var branch_root_by_node_id: Dictionary = layout_context.get("branch_root_by_node_id", {})
	for _iteration in range(24):
		for left_index in range(ordered_node_ids.size()):
			var left_node_id: int = ordered_node_ids[left_index]
			for right_index in range(left_index + 1, ordered_node_ids.size()):
				var right_node_id: int = ordered_node_ids[right_index]
				if left_node_id == 0 and right_node_id == 0:
					continue
				var left_position: Vector2 = world_positions.get(left_node_id, Vector2.ZERO)
				var right_position: Vector2 = world_positions.get(right_node_id, Vector2.ZERO)
				var delta: Vector2 = right_position - left_position
				var distance: float = delta.length()
				var left_depth: int = int(depth_by_node_id.get(left_node_id, 0))
				var right_depth: int = int(depth_by_node_id.get(right_node_id, 0))
				var left_radius: float = float(clearing_radius_by_node_id.get(left_node_id, 42.0))
				var right_radius: float = float(clearing_radius_by_node_id.get(right_node_id, 42.0))
				var minimum_spacing: float = left_radius + right_radius + clampf(board_unit * 0.066, 58.0, 82.0)
				if left_depth <= 1 or right_depth <= 1:
					minimum_spacing += 26.0
				elif left_depth == 2 and right_depth == 2:
					minimum_spacing += 18.0
				if distance >= minimum_spacing:
					continue
				var same_branch: bool = int(branch_root_by_node_id.get(left_node_id, left_node_id)) == int(branch_root_by_node_id.get(right_node_id, right_node_id))
				var push_direction: Vector2 = Vector2.RIGHT if distance <= 0.001 else delta / distance
				if same_branch:
					var branch_direction: Vector2 = branch_direction_for_root(layout_context, int(branch_root_by_node_id.get(left_node_id, left_node_id)))
					var tangent_direction: Vector2 = Vector2(-branch_direction.y, branch_direction.x)
					var tangent_sign: float = 1.0 if (right_position - left_position).dot(tangent_direction) >= 0.0 else -1.0
					push_direction = tangent_direction * tangent_sign
				var push_amount: float = (minimum_spacing - max(distance, 0.001)) * 0.5
				if left_node_id != 0:
					world_positions[left_node_id] = _clamp_to_board(left_position - push_direction * push_amount, board_size, min_board_margin)
				if right_node_id != 0:
					world_positions[right_node_id] = _clamp_to_board(right_position + push_direction * push_amount, board_size, min_board_margin)


static func _reduce_edge_crossings(
	world_positions: Dictionary,
	graph_snapshot: Array[Dictionary],
	board_size: Vector2,
	layout_context: Dictionary,
	min_board_margin: Vector2
) -> void:
	var board_unit: float = min(board_size.x, board_size.y)
	var depth_by_node_id: Dictionary = layout_context.get("depth_by_node_id", {})
	for _iteration in range(8):
		var adjusted: bool = false
		var edge_entries: Array[Dictionary] = _build_layout_edge_entries(graph_snapshot, world_positions)
		for left_index in range(edge_entries.size()):
			for right_index in range(left_index + 1, edge_entries.size()):
				var left_edge: Dictionary = edge_entries[left_index]
				var right_edge: Dictionary = edge_entries[right_index]
				if _layout_edges_share_node(left_edge, right_edge):
					continue
				if not MapBoardGeometryScript.segments_intersect(
					Vector2(left_edge.get("from_position", Vector2.ZERO)),
					Vector2(left_edge.get("to_position", Vector2.ZERO)),
					Vector2(right_edge.get("from_position", Vector2.ZERO)),
					Vector2(right_edge.get("to_position", Vector2.ZERO))
				):
					continue
				var left_move_node_id: int = _preferred_crossing_move_node_id(left_edge, depth_by_node_id)
				var right_move_node_id: int = _preferred_crossing_move_node_id(right_edge, depth_by_node_id)
				if left_move_node_id < 0 or right_move_node_id < 0:
					continue
				var left_midpoint: Vector2 = (Vector2(left_edge.get("from_position", Vector2.ZERO)) + Vector2(left_edge.get("to_position", Vector2.ZERO))) * 0.5
				var right_midpoint: Vector2 = (Vector2(right_edge.get("from_position", Vector2.ZERO)) + Vector2(right_edge.get("to_position", Vector2.ZERO))) * 0.5
				var push_direction: Vector2 = right_midpoint - left_midpoint
				if push_direction.length_squared() <= 0.001:
					push_direction = Vector2(
						-(Vector2(left_edge.get("to_position", Vector2.ZERO)) - Vector2(left_edge.get("from_position", Vector2.ZERO))).y,
						(Vector2(left_edge.get("to_position", Vector2.ZERO)) - Vector2(left_edge.get("from_position", Vector2.ZERO))).x
					)
				if push_direction.length_squared() <= 0.001:
					push_direction = Vector2.RIGHT
				push_direction = push_direction.normalized()
				var push_amount: float = board_unit * 0.046
				world_positions[left_move_node_id] = _clamp_to_board(
					Vector2(world_positions.get(left_move_node_id, Vector2.ZERO)) - push_direction * push_amount,
					board_size,
					min_board_margin
				)
				world_positions[right_move_node_id] = _clamp_to_board(
					Vector2(world_positions.get(right_move_node_id, Vector2.ZERO)) + push_direction * push_amount,
					board_size,
					min_board_margin
				)
				adjusted = true
		if not adjusted:
			return


static func _build_layout_edge_entries(graph_snapshot: Array[Dictionary], world_positions: Dictionary) -> Array[Dictionary]:
	var edge_entries: Array[Dictionary] = []
	var seen_edge_keys: Dictionary = {}
	for node_entry in graph_snapshot:
		var from_node_id: int = int(node_entry.get("node_id", -1))
		var from_position: Vector2 = world_positions.get(from_node_id, Vector2.ZERO)
		for adjacent_node_id in _adjacent_ids_from_entry(node_entry):
			var edge_key: String = _edge_key(from_node_id, adjacent_node_id)
			if seen_edge_keys.has(edge_key):
				continue
			seen_edge_keys[edge_key] = true
			var to_position: Vector2 = world_positions.get(adjacent_node_id, Vector2.ZERO)
			if from_position == Vector2.ZERO or to_position == Vector2.ZERO:
				continue
			edge_entries.append({
				"from_node_id": from_node_id,
				"to_node_id": int(adjacent_node_id),
				"from_position": from_position,
				"to_position": to_position,
			})
	return edge_entries


static func _layout_edges_share_node(left_edge: Dictionary, right_edge: Dictionary) -> bool:
	var left_ids: Array[int] = [int(left_edge.get("from_node_id", -1)), int(left_edge.get("to_node_id", -1))]
	var right_ids: Array[int] = [int(right_edge.get("from_node_id", -1)), int(right_edge.get("to_node_id", -1))]
	for left_id in left_ids:
		if left_id in right_ids:
			return true
	return false


static func _preferred_crossing_move_node_id(edge_entry: Dictionary, depth_by_node_id: Dictionary) -> int:
	var from_node_id: int = int(edge_entry.get("from_node_id", -1))
	var to_node_id: int = int(edge_entry.get("to_node_id", -1))
	var from_depth: int = int(depth_by_node_id.get(from_node_id, 0))
	var to_depth: int = int(depth_by_node_id.get(to_node_id, 0))
	if from_node_id == 0:
		return to_node_id
	if to_node_id == 0:
		return from_node_id
	if from_depth == to_depth:
		return max(from_node_id, to_node_id)
	return from_node_id if from_depth > to_depth else to_node_id


static func _adjacent_ids_from_entry(node_entry: Dictionary) -> PackedInt32Array:
	var adjacent_variant: Variant = node_entry.get("adjacent_node_ids", PackedInt32Array())
	if typeof(adjacent_variant) == TYPE_PACKED_INT32_ARRAY:
		return adjacent_variant
	var adjacent_ids := PackedInt32Array()
	if typeof(adjacent_variant) == TYPE_ARRAY:
		for adjacent_node_id in adjacent_variant:
			adjacent_ids.append(int(adjacent_node_id))
	return adjacent_ids


static func _edge_key(from_node_id: int, to_node_id: int) -> String:
	var ordered_ids: Array[int] = [from_node_id, to_node_id]
	ordered_ids.sort()
	return "%d:%d" % [ordered_ids[0], ordered_ids[1]]
