# Layer: Tools
extends RefCounted
class_name MapReviewCaptureHelper

const MAP_ROUTE_GRID_PATH := "Margin/VBox/RouteGrid"
const TOP_ROW_PATH := "Margin/VBox/TopRow"
const INVENTORY_SECTION_PATH := "Margin/VBox/InventorySection"


static func build_scene_review(
	scene_root: Node,
	scene_path: String,
	screenshot_path: String,
	viewport_size: Vector2i
) -> Dictionary:
	var normalized_screenshot_path: String = screenshot_path.replace("\\", "/")
	var review := {
		"scene_path": scene_path,
		"screenshot_path": normalized_screenshot_path,
		"viewport_size": {
			"width": viewport_size.x,
			"height": viewport_size.y,
		},
		"captured_at_utc": Time.get_datetime_string_from_system(true, true),
	}

	var control_root: Control = scene_root as Control
	if control_root == null:
		return review

	if scene_path.ends_with("map_explore.tscn"):
		review["map_review"] = build_map_explore_review(control_root)

	return review


static func build_map_explore_review(
	root: Control,
	composition_override: Dictionary = {},
	composition_source_override: String = ""
) -> Dictionary:
	var route_grid: Control = root.get_node_or_null(MAP_ROUTE_GRID_PATH) as Control
	var top_row: Control = root.get_node_or_null(TOP_ROW_PATH) as Control
	var inventory_section: Control = root.get_node_or_null(INVENTORY_SECTION_PATH) as Control
	var board_composition_result: Dictionary = _resolve_board_composition(root, composition_override, composition_source_override)
	var board_composition: Dictionary = board_composition_result.get("composition", {})
	var composition_source: String = String(board_composition_result.get("source", "missing"))

	var review := {
		"composition_source": composition_source,
		"route_grid_global_rect": _rect_to_dictionary(_safe_global_rect(route_grid)),
		"top_row_global_rect": _rect_to_dictionary(_safe_global_rect(top_row)),
		"inventory_section_global_rect": _rect_to_dictionary(_safe_global_rect(inventory_section)),
		"lower_half_readback": {
			"visible_node_count": 0,
			"lower_half_visible_node_count": 0,
			"lower_third_visible_node_count": 0,
			"lower_half_floor_y": 0.0,
			"lower_third_floor_y": 0.0,
			"lower_half_ratio": 0.0,
			"lower_half_node_ids": [],
			"lower_third_node_ids": [],
		},
		"ui_overlap_failures": [],
		"ui_overlap_failure_count": 0,
	}

	if route_grid != null:
		review["route_grid_local_size"] = _vector_to_dictionary(route_grid.size)
		review["lower_half_readback"] = _build_lower_half_readback(board_composition, route_grid.size)

		var overlap_failures: Array[Dictionary] = []
		overlap_failures.append_array(_collect_stack_overlap_failures(route_grid, top_row, inventory_section))
		overlap_failures.append_array(_collect_root_overlay_intersections(root, route_grid))
		review["ui_overlap_failures"] = overlap_failures
		review["ui_overlap_failure_count"] = overlap_failures.size()

	return review


static func _resolve_board_composition(
	root: Control,
	composition_override: Dictionary,
	composition_source_override: String
) -> Dictionary:
	if not composition_override.is_empty():
		return {
			"composition": composition_override.duplicate(true),
			"source": composition_source_override if not composition_source_override.is_empty() else "override",
		}

	var scene_composition_variant: Variant = _get_object_property_or_null(root, "_board_composition_cache")
	if scene_composition_variant is Dictionary and not (scene_composition_variant as Dictionary).is_empty():
		return {
			"composition": (scene_composition_variant as Dictionary).duplicate(true),
			"source": "scene._board_composition_cache",
		}

	var route_binding_variant: Variant = _get_object_property_or_null(root, "_route_binding")
	if route_binding_variant != null:
		var route_binding_composition_variant: Variant = _get_object_property_or_null(route_binding_variant, "_board_composition_cache")
		if route_binding_composition_variant is Dictionary and not (route_binding_composition_variant as Dictionary).is_empty():
			return {
				"composition": (route_binding_composition_variant as Dictionary).duplicate(true),
				"source": "route_binding._board_composition_cache",
			}

	var board_canvas: Control = root.get_node_or_null("%s/ComposedBoardCanvas" % MAP_ROUTE_GRID_PATH) as Control
	if board_canvas != null:
		var canvas_composition_variant: Variant = _get_object_property_or_null(board_canvas, "_composition")
		if canvas_composition_variant is Dictionary and not (canvas_composition_variant as Dictionary).is_empty():
			return {
				"composition": (canvas_composition_variant as Dictionary).duplicate(true),
				"source": "board_canvas._composition",
			}

	return {
		"composition": {},
		"source": "missing",
	}


static func _build_lower_half_readback(composition: Dictionary, route_grid_size: Vector2) -> Dictionary:
	var visible_nodes: Array = composition.get("visible_nodes", [])
	var lower_half_floor_y: float = route_grid_size.y * 0.5
	var lower_third_floor_y: float = route_grid_size.y * 0.66
	var visible_node_count: int = 0
	var lower_half_visible_node_count: int = 0
	var lower_third_visible_node_count: int = 0
	var lower_half_node_ids: Array[int] = []
	var lower_third_node_ids: Array[int] = []
	var local_bounds: Rect2 = _bounds_for_visible_nodes(visible_nodes)

	for node_variant in visible_nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var world_position: Vector2 = Vector2(node_entry.get("world_position", Vector2.ZERO))
		var node_id: int = int(node_entry.get("node_id", -1))
		visible_node_count += 1
		if world_position.y >= lower_half_floor_y:
			lower_half_visible_node_count += 1
			lower_half_node_ids.append(node_id)
		if world_position.y >= lower_third_floor_y:
			lower_third_visible_node_count += 1
			lower_third_node_ids.append(node_id)

	return {
		"visible_node_count": visible_node_count,
		"lower_half_visible_node_count": lower_half_visible_node_count,
		"lower_third_visible_node_count": lower_third_visible_node_count,
		"lower_half_floor_y": lower_half_floor_y,
		"lower_third_floor_y": lower_third_floor_y,
		"lower_half_ratio": float(lower_half_visible_node_count) / float(max(1, visible_node_count)),
		"lower_half_node_ids": lower_half_node_ids,
		"lower_third_node_ids": lower_third_node_ids,
		"visible_node_local_bounds": _rect_to_dictionary(local_bounds),
	}


static func _collect_stack_overlap_failures(route_grid: Control, top_row: Control, inventory_section: Control) -> Array[Dictionary]:
	var overlap_failures: Array[Dictionary] = []
	var route_grid_rect: Rect2 = _safe_global_rect(route_grid)
	if route_grid_rect.size == Vector2.ZERO:
		return overlap_failures

	for entry in [
		{"label": "top_row_vs_route_grid", "control": top_row},
		{"label": "inventory_section_vs_route_grid", "control": inventory_section},
	]:
		var target_control: Control = entry.get("control", null) as Control
		if target_control == null:
			continue
		var target_rect: Rect2 = _safe_global_rect(target_control)
		if target_rect.size == Vector2.ZERO or not target_rect.intersects(route_grid_rect):
			continue
		overlap_failures.append({
			"type": "stack_overlap",
			"label": String(entry.get("label", "")),
			"node_name": target_control.name,
			"target_rect": _rect_to_dictionary(target_rect),
			"route_grid_rect": _rect_to_dictionary(route_grid_rect),
			"intersection_rect": _rect_to_dictionary(target_rect.intersection(route_grid_rect)),
		})

	return overlap_failures


static func _collect_root_overlay_intersections(root: Control, route_grid: Control) -> Array[Dictionary]:
	var overlap_failures: Array[Dictionary] = []
	if root == null or route_grid == null:
		return overlap_failures

	var root_size: Vector2 = root.size if root.size != Vector2.ZERO else root.get_viewport_rect().size
	var route_grid_rect: Rect2 = _safe_global_rect(route_grid)
	if route_grid_rect.size == Vector2.ZERO:
		return overlap_failures

	for child_variant in root.get_children():
		var child_control: Control = child_variant as Control
		if child_control == null or not child_control.visible:
			continue
		if child_control.name == "Margin" or child_control == route_grid:
			continue

		var child_rect: Rect2 = _safe_global_rect(child_control)
		if child_rect.size == Vector2.ZERO or not child_rect.intersects(route_grid_rect):
			continue
		var fills_whole_root: bool = root_size != Vector2.ZERO \
			and child_rect.size.x >= root_size.x * 0.95 \
			and child_rect.size.y >= root_size.y * 0.95
		if fills_whole_root:
			continue

		overlap_failures.append({
			"type": "root_overlay_intersection",
			"node_name": child_control.name,
			"global_rect": _rect_to_dictionary(child_rect),
			"intersection_rect": _rect_to_dictionary(child_rect.intersection(route_grid_rect)),
		})

	return overlap_failures


static func _bounds_for_visible_nodes(visible_nodes: Array) -> Rect2:
	var has_bounds: bool = false
	var min_point: Vector2 = Vector2.ZERO
	var max_point: Vector2 = Vector2.ZERO
	for node_variant in visible_nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var world_position: Vector2 = Vector2((node_variant as Dictionary).get("world_position", Vector2.ZERO))
		if not has_bounds:
			has_bounds = true
			min_point = world_position
			max_point = world_position
			continue
		min_point = Vector2(minf(min_point.x, world_position.x), minf(min_point.y, world_position.y))
		max_point = Vector2(maxf(max_point.x, world_position.x), maxf(max_point.y, world_position.y))
	if not has_bounds:
		return Rect2()
	return Rect2(min_point, max_point - min_point)


static func _safe_global_rect(control: Control) -> Rect2:
	if control == null:
		return Rect2()
	var global_rect: Rect2 = control.get_global_rect()
	if global_rect.size != Vector2.ZERO:
		return global_rect
	return Rect2(control.position, control.size)


static func _get_object_property_or_null(target: Object, property_name: String) -> Variant:
	if target == null:
		return null
	for property_variant in target.get_property_list():
		if typeof(property_variant) != TYPE_DICTIONARY:
			continue
		var property_entry: Dictionary = property_variant
		if String(property_entry.get("name", "")) == property_name:
			return target.get(property_name)
	return null


static func _vector_to_dictionary(value: Vector2) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
	}


static func _rect_to_dictionary(rect: Rect2) -> Dictionary:
	return {
		"x": rect.position.x,
		"y": rect.position.y,
		"width": rect.size.x,
		"height": rect.size.y,
	}
