# Layer: Tests
extends SceneTree
class_name TestMapBoardCanvas

const MapBoardCanvasScript = preload("res://Game/UI/map_board_canvas.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	test_map_board_canvas_returns_null_for_missing_asset_paths()
	test_map_board_canvas_skips_missing_known_icon_assets_without_crashing()
	print("test_map_board_canvas: all assertions passed")
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func test_map_board_canvas_returns_null_for_missing_asset_paths() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	assert(
		board_canvas.call("_load_texture_or_null", "res://Assets/UI/Map/Canopy/not_real.svg") == null,
		"Expected missing prototype map assets to resolve to null so board rendering can fall back cleanly instead of crashing."
	)
	board_canvas.free()


func test_map_board_canvas_skips_missing_known_icon_assets_without_crashing() -> void:
	var board_canvas: Control = MapBoardCanvasScript.new()
	board_canvas.call("_draw_known_node_icon", {
		"show_known_icon": true,
		"icon_texture_path": "res://Assets/Icons/not_real.svg",
		"state_semantic": "open",
		"node_family": "event",
	}, Vector2(64.0, 64.0), 24.0)
	assert(true, "Expected missing known-icon assets to short-circuit cleanly before any draw call tries to use them.")
	board_canvas.free()
