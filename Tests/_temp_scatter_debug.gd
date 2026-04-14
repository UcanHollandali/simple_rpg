extends SceneTree

const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")

func _init() -> void:
	for stage_index in range(1, 4):
		var map_runtime_state = MapRuntimeStateScript.new()
		var template_id: String = map_runtime_state._resolve_scaffold_id_for_stage(stage_index)
		var depth_profile: Array[int] = map_runtime_state._resolve_scatter_depth_profile(template_id)
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var found := false
		for attempt in range(16):
			var adjacency: Dictionary = map_runtime_state._build_scatter_adjacency(depth_profile, rng)
			var family_assignments: Dictionary = map_runtime_state._build_scaffold_family_assignments(adjacency, stage_index, rng)
			if family_assignments.is_empty():
				print("stage=%d attempt=%d families=empty" % [stage_index, attempt])
				continue
			var graph: Array[Dictionary] = map_runtime_state._build_scatter_graph_payload(adjacency, family_assignments)
			if graph.is_empty():
				print("stage=%d attempt=%d graph_empty" % [stage_index, attempt])
				continue
			var strict_ok: bool = map_runtime_state._validate_scatter_runtime_graph(graph)
			var floor_ok: bool = map_runtime_state._validate_scatter_runtime_graph_min_floor(graph)
			if strict_ok or floor_ok:
				print("stage=%d attempt=%d valid=%s floor=%s" % [stage_index, attempt, strict_ok, floor_ok])
				if strict_ok:
					found = true
					break
				continue
			print("stage=%d attempt=%d invalid strict/floor families=%s" % [stage_index, attempt, _family_counts(family_assignments)])
			var degrees: Array[int] = []
			for node in graph:
				degrees.append(int(node.get("adjacent_node_ids", PackedInt32Array()).size()))
			print("   degrees=%s" % [str(degrees)])
		if not found:
			var generated = map_runtime_state._build_scaffold_graph(template_id, stage_index)
			print("stage=%d final_graph_count=%d strict=%s floor=%s" % [stage_index, generated.size(), map_runtime_state._validate_scatter_runtime_graph(generated), map_runtime_state._validate_scatter_runtime_graph_min_floor(generated)])

func _family_counts(families: Dictionary) -> String:
	var counts: Dictionary = {}
	for node_id in families.keys():
		var family: String = String(families[node_id])
		counts[family] = int(counts.get(family, 0)) + 1
	return str(counts)
