# Layer: Tests
extends SceneTree
class_name TestDesktopPreviewScaling

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	test_windowed_display_safe_frame_keeps_desktop_headroom()
	print("test_desktop_preview_scaling: all assertions passed")
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func test_windowed_display_safe_frame_keeps_desktop_headroom() -> void:
	var bootstrap: Node = AppBootstrapScript.new()
	var logical_reference := Vector2i(1080, 1920)
	var targets := [
		{
			"display_size": Vector2i(1080, 2400),
			"expected_window_size": Vector2i(972, 1728),
		},
		{
			"display_size": Vector2i(1080, 1920),
			"expected_window_size": Vector2i(972, 1728),
		},
		{
			"display_size": Vector2i(720, 1280),
			"expected_window_size": Vector2i(648, 1152),
		},
		{
			"display_size": Vector2i(1366, 768),
			"expected_window_size": Vector2i(388, 691),
		},
		{
			"display_size": Vector2i(1920, 1080),
			"expected_window_size": Vector2i(546, 972),
		},
	]

	for target in targets:
		var display_size: Vector2i = target["display_size"]
		var safe_display_size: Vector2i = bootstrap.call("_build_windowed_safe_display_size", display_size)
		var resolved_window_size: Vector2i = bootstrap.call("_resolve_windowed_size_to_available_area", logical_reference, safe_display_size)
		assert(
			resolved_window_size == target["expected_window_size"],
			"Expected logical portrait reference to fit inside the desktop-safe frame for %s." % [str(display_size)]
		)
		assert(
			resolved_window_size.x <= safe_display_size.x and resolved_window_size.y <= safe_display_size.y,
			"Expected resolved window size to stay inside the safe display frame."
		)
	bootstrap.free()
