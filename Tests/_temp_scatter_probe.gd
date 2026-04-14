extends SceneTree

const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")

func _init() -> void:
	for stage_index in range(1, 4):
		var m: RefCounted = MapRuntimeStateScript.new()
		var template_id: String = m._resolve_scaffold_id_for_stage(stage_index)
		var depth_profile: Array[int] = m._resolve_scatter_depth_profile(template_id)
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var success_count := 0
		var attempt := 0
		while attempt < 16:
			var adj: Dictionary = m._build_scatter_adjacency(depth_profile, rng)
			var families: Dictionary = m._build_scatter_family_assignments(adj, stage_index, rng)
			var graph: Array[Dictionary] = []
			var is_valid := false
			if not families.is_empty():
				graph = m._build_scatter_graph_payload(adj, families)
				is_valid = m._validate_scatter_runtime_graph(graph)
			print("stage=%d attempt=%d adj_nodes=%d families=%d valid=%s node0=%s" % [stage_index, attempt, adj.size(), families.size(), str(is_valid), graph.size()])
			if is_valid:
				success_count += 1
			attempt += 1
		print("stage=%d template=%s profile=%s successes=%d of 16" % [stage_index, template_id, str(depth_profile), success_count])

	quit()

func _max_depth(depth: Dictionary) -> int:
	var max_depth := 0
	for d in depth.values():
		max_depth = max(max_depth, int(d))
	return max_depth
