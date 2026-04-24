# Layer: Tests
extends SceneTree
class_name TestMapReviewCaptureHelper

const MapReviewCaptureHelperScript = preload("res://Tools/map_review_capture_helper.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	await test_map_review_capture_helper_reports_lower_half_node_readback()
	await test_map_review_capture_helper_reports_root_overlay_intersections()
	print("test_map_review_capture_helper: all assertions passed")
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func test_map_review_capture_helper_reports_lower_half_node_readback() -> void:
	var fixture: Dictionary = await _build_map_review_fixture()
	var root: Control = fixture.get("root")
	var review: Dictionary = MapReviewCaptureHelperScript.build_map_explore_review(
		root,
		{
			"visible_nodes": [
				{"node_id": 0, "world_position": Vector2(180.0, 120.0)},
				{"node_id": 1, "world_position": Vector2(200.0, 460.0)},
				{"node_id": 2, "world_position": Vector2(220.0, 700.0)},
			],
		},
		"test_override"
	)
	var lower_half_readback: Dictionary = review.get("lower_half_readback", {})
	assert(
		String(review.get("composition_source", "")) == "test_override",
		"Expected map review helper to preserve the explicit composition-source override in baseline reports."
	)
	assert(
		int(lower_half_readback.get("visible_node_count", 0)) == 3,
		"Expected map review helper to count all visible nodes in the baseline readback."
	)
	assert(
		int(lower_half_readback.get("lower_half_visible_node_count", 0)) == 2,
		"Expected map review helper to count lower-half visible nodes from route-grid local positions."
	)
	assert(
		int(lower_half_readback.get("lower_third_visible_node_count", 0)) == 1,
		"Expected map review helper to count the deeper lower-third visible nodes separately from the broader lower half."
	)


func test_map_review_capture_helper_reports_root_overlay_intersections() -> void:
	var fixture: Dictionary = await _build_map_review_fixture()
	var root: Control = fixture.get("root")
	var overlay_panel: PanelContainer = PanelContainer.new()
	overlay_panel.name = "QuestLogPanel"
	overlay_panel.position = Vector2(720.0, 180.0)
	overlay_panel.size = Vector2(220.0, 260.0)
	root.add_child(overlay_panel)
	await process_frame

	var review: Dictionary = MapReviewCaptureHelperScript.build_map_explore_review(
		root,
		{
			"visible_nodes": [
				{"node_id": 0, "world_position": Vector2(180.0, 120.0)},
			],
		},
		"test_override"
	)
	var overlap_failures: Array = review.get("ui_overlap_failures", [])
	assert(
		int(review.get("ui_overlap_failure_count", 0)) == 1,
		"Expected map review helper to surface direct-root overlay intersections with the route grid."
	)
	assert(
		not overlap_failures.is_empty() and String((overlap_failures[0] as Dictionary).get("node_name", "")) == "QuestLogPanel",
		"Expected the overlap report to identify the intersecting root overlay node by name."
	)


func _build_map_review_fixture() -> Dictionary:
	var root := Control.new()
	root.name = "MapExploreFixture"
	root.size = Vector2(1080.0, 1920.0)
	get_root().add_child(root)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.size = root.size
	root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size = root.size
	margin.add_child(vbox)

	var top_row := HBoxContainer.new()
	top_row.name = "TopRow"
	top_row.position = Vector2(0.0, 0.0)
	top_row.size = Vector2(1040.0, 112.0)
	top_row.custom_minimum_size = top_row.size
	vbox.add_child(top_row)

	var route_grid := Control.new()
	route_grid.name = "RouteGrid"
	route_grid.position = Vector2(0.0, 132.0)
	route_grid.size = Vector2(1040.0, 840.0)
	route_grid.custom_minimum_size = route_grid.size
	vbox.add_child(route_grid)

	var inventory_section := VBoxContainer.new()
	inventory_section.name = "InventorySection"
	inventory_section.position = Vector2(0.0, 1000.0)
	inventory_section.size = Vector2(1040.0, 280.0)
	inventory_section.custom_minimum_size = inventory_section.size
	vbox.add_child(inventory_section)

	await process_frame
	return {
		"root": root,
	}
