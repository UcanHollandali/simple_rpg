# Layer: RuntimeState
extends RefCounted
class_name MapScatterGraphTools


static func coerce_adjacent_ids(adjacent_variant: Variant) -> PackedInt32Array:
	if typeof(adjacent_variant) == TYPE_PACKED_INT32_ARRAY:
		return adjacent_variant

	var adjacent_ids: PackedInt32Array = PackedInt32Array()
	if typeof(adjacent_variant) == TYPE_ARRAY:
		for value in adjacent_variant:
			adjacent_ids.append(int(value))
	return adjacent_ids


static func sorted_node_ids(node_id_variants: Variant) -> Array[int]:
	var ordered_node_ids: Array[int] = []
	if typeof(node_id_variants) == TYPE_ARRAY:
		for node_id_variant in node_id_variants:
			ordered_node_ids.append(int(node_id_variant))
	elif typeof(node_id_variants) == TYPE_PACKED_INT32_ARRAY:
		for node_id_variant in node_id_variants:
			ordered_node_ids.append(int(node_id_variant))
	ordered_node_ids.sort()
	return ordered_node_ids


static func has_edge(node_adjacency: Dictionary, left_id: int, right_id: int) -> bool:
	return (node_adjacency.get(left_id, []) as Array[int]).has(right_id)


static func add_edge(node_adjacency: Dictionary, left_id: int, right_id: int) -> void:
	var left_adjacent: Array = node_adjacency.get(left_id, [])
	var right_adjacent: Array = node_adjacency.get(right_id, [])
	left_adjacent.append(right_id)
	right_adjacent.append(left_id)
	node_adjacency[left_id] = left_adjacent
	node_adjacency[right_id] = right_adjacent


static func degree(node_adjacency: Dictionary, node_id: int) -> int:
	return int((node_adjacency.get(node_id, []) as Array).size())


static func build_path_length(node_adjacency: Dictionary, start_node_id: int, target_node_id: int) -> int:
	if start_node_id == target_node_id:
		return 0
	if not node_adjacency.has(start_node_id) or not node_adjacency.has(target_node_id):
		return -1

	var visited: Dictionary = {start_node_id: true}
	var queue: Array[Dictionary] = [{"node_id": start_node_id, "distance": 0}]
	while not queue.is_empty():
		var entry: Dictionary = queue.pop_front()
		var node_id: int = int(entry.get("node_id", -1))
		var distance: int = int(entry.get("distance", 0))
		for adjacent_node_id in coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array())):
			var resolved_adjacent_node_id: int = int(adjacent_node_id)
			if resolved_adjacent_node_id == target_node_id:
				return distance + 1
			if visited.has(resolved_adjacent_node_id):
				continue
			visited[resolved_adjacent_node_id] = true
			queue.append({
				"node_id": resolved_adjacent_node_id,
				"distance": distance + 1,
			})
	return -1


static func count_same_depth_reconnects(node_adjacency: Dictionary, depth_by_node_id: Dictionary) -> int:
	var reconnect_count: int = 0
	var seen_edges: Dictionary = {}
	for node_id_variant in node_adjacency.keys():
		var node_id: int = int(node_id_variant)
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		for adjacent_node_id in coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array())):
			var adjacent_depth: int = int(depth_by_node_id.get(adjacent_node_id, -1))
			var left_id: int = min(node_id, int(adjacent_node_id))
			var right_id: int = max(node_id, int(adjacent_node_id))
			var edge_key: String = "%d:%d" % [left_id, right_id]
			if seen_edges.has(edge_key):
				continue
			seen_edges[edge_key] = true
			if node_depth < 2 or adjacent_depth < 2:
				continue
			if node_depth != adjacent_depth:
				continue
			reconnect_count += 1
	return reconnect_count


static func count_extra_edges(node_adjacency: Dictionary, node_count: int) -> int:
	var undirected_edge_count: int = 0
	for node_id_variant in node_adjacency.keys():
		var node_id: int = int(node_id_variant)
		undirected_edge_count += coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array())).size()
	return max(0, int(undirected_edge_count / 2) - (node_count - 1))


static func build_adjacency_lookup_from_graph(graph: Array[Dictionary], missing_node_id: int) -> Dictionary:
	var adjacency_by_node_id: Dictionary = {}
	for entry in graph:
		var node_id: int = int(entry.get("node_id", missing_node_id))
		if node_id < 0:
			continue
		adjacency_by_node_id[node_id] = coerce_adjacent_ids(entry.get("adjacent_node_ids", PackedInt32Array()))
	return adjacency_by_node_id


static func is_graph_connected(graph: Array[Dictionary], missing_node_id: int, start_node_id: int = 0) -> bool:
	var adjacency_by_node_id: Dictionary = {}
	var node_ids: Array[int] = []
	for entry in graph:
		var node_id: int = int(entry.get("node_id", missing_node_id))
		adjacency_by_node_id[node_id] = coerce_adjacent_ids(entry.get("adjacent_node_ids", []))
		node_ids.append(node_id)
	if not adjacency_by_node_id.has(start_node_id):
		return false

	var visited: Dictionary = {}
	var queue: Array[int] = [start_node_id]
	while not queue.is_empty():
		var node_id: int = queue.pop_front()
		if visited.has(node_id):
			continue
		visited[node_id] = true
		for adjacent_node_id in adjacency_by_node_id.get(node_id, PackedInt32Array()):
			if not visited.has(adjacent_node_id):
				queue.append(int(adjacent_node_id))
	return visited.size() == node_ids.size()


static func build_depth_map(node_adjacency: Dictionary, start_node_id: int = 0) -> Dictionary:
	var depth_by_node_id: Dictionary = {}
	var queue: Array[int] = [start_node_id]
	depth_by_node_id[start_node_id] = 0
	while not queue.is_empty():
		var node_id: int = queue.pop_front()
		var current_depth: int = int(depth_by_node_id.get(node_id, 0))
		for adjacent_node_id in node_adjacency.get(node_id, PackedInt32Array()):
			if depth_by_node_id.has(adjacent_node_id):
				continue
			depth_by_node_id[adjacent_node_id] = current_depth + 1
			queue.append(int(adjacent_node_id))
	return depth_by_node_id


static func filter_nodes_by_depth_range(node_ids: Array[int], depth_by_node_id: Dictionary, min_depth: int, max_depth: int) -> Array[int]:
	var filtered_node_ids: Array[int] = []
	for node_id in node_ids:
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		if node_depth >= min_depth and node_depth <= max_depth:
			filtered_node_ids.append(node_id)
	return filtered_node_ids


static func build_topology_signature(node_adjacency: Dictionary) -> String:
	var fragments: PackedStringArray = []
	for node_id in sorted_node_ids(node_adjacency.keys()):
		var adjacent_fragment: PackedStringArray = []
		for adjacent_node_id in coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array())):
			adjacent_fragment.append(str(int(adjacent_node_id)))
		fragments.append("%d:%s" % [node_id, ",".join(adjacent_fragment)])
	return "|".join(fragments)
