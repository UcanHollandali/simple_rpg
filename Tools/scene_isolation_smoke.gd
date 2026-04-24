# Layer: Tools
extends SceneTree

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")

const READY_MARKER_PREFIX := "SCENE_ISOLATION_SMOKE: scene_ready "
const MAP_SHELL_MARKER_PREFIX := "SCENE_ISOLATION_SMOKE: map_shell_ready "
const FAIL_MARKER_PREFIX := "SCENE_ISOLATION_SMOKE: failed "
const DEFAULT_TIMEOUT_MS := 2000

var _scene_path := ""
var _timeout_ms := DEFAULT_TIMEOUT_MS


func _init() -> void:
	var parse_error := _parse_args(OS.get_cmdline_user_args())
	if parse_error != "":
		_fail(parse_error)
		return

	Callable(self, "_run_smoke").call_deferred()


func _parse_args(args: PackedStringArray) -> String:
	var index := 0
	while index < args.size():
		var arg := String(args[index])
		match arg:
			"--scene":
				index += 1
				if index >= args.size():
					return "missing scene path after --scene"
				_scene_path = String(args[index])
			"--timeout-ms":
				index += 1
				if index >= args.size():
					return "missing timeout after --timeout-ms"
				_timeout_ms = max(int(args[index]), DEFAULT_TIMEOUT_MS)
			_:
				return "unexpected argument: %s" % arg
		index += 1

	if _scene_path == "":
		return "missing required --scene argument"

	return ""


func _run_smoke() -> void:
	_ensure_runtime_bootstrap_nodes()
	change_scene_to_file(_scene_path)

	var isolated_scene: Node = await _wait_for_scene(_scene_path, _timeout_ms)
	if isolated_scene == null:
		_fail("timeout_before_scene_ready %s" % _scene_path)
		return

	await process_frame
	await process_frame
	await create_timer(0.05).timeout

	if _scene_path.ends_with("map_explore.tscn"):
		var map_shell_error: String = _validate_map_explore_shell(isolated_scene)
		if map_shell_error != "":
			_fail(map_shell_error)
			return
		print("%s%s" % [MAP_SHELL_MARKER_PREFIX, _scene_path])

	print("%s%s" % [READY_MARKER_PREFIX, _scene_path])
	await _cleanup_before_quit()
	quit()


func _ensure_runtime_bootstrap_nodes() -> void:
	var root_window: Window = get_root()
	if root_window.get_node_or_null("AppBootstrap") == null:
		var bootstrap: Node = AppBootstrapScript.new()
		bootstrap.name = "AppBootstrap"
		root_window.add_child(bootstrap)

	if root_window.get_node_or_null("SceneRouter") == null:
		var scene_router: Node = SceneRouterScript.new()
		scene_router.name = "SceneRouter"
		root_window.add_child(scene_router)


func _wait_for_scene(scene_path: String, timeout_ms: int) -> Node:
	var deadline_ms: int = Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline_ms:
		var active_scene: Node = current_scene
		if active_scene != null and String(active_scene.scene_file_path) == scene_path:
			return active_scene
		await create_timer(0.05).timeout
	return null


func _validate_map_explore_shell(scene_root: Node) -> String:
	for required_path in [
		"Margin/VBox/TopRow",
		"Margin/VBox/RouteGrid",
		"Margin/VBox/InventorySection",
		"Margin/VBox/RouteGrid/ComposedBoardCanvas",
	]:
		if scene_root.get_node_or_null(required_path) == null:
			return "missing_map_shell_node %s %s" % [_scene_path, required_path]

	var route_grid: Control = scene_root.get_node_or_null("Margin/VBox/RouteGrid") as Control
	if route_grid == null:
		return "missing_map_shell_node %s Margin/VBox/RouteGrid" % _scene_path
	var route_grid_height: float = maxf(route_grid.size.y, route_grid.custom_minimum_size.y)
	if route_grid_height <= 0.0:
		return "invalid_map_shell_route_grid_size %s %.2f" % [_scene_path, route_grid_height]

	return ""


func _cleanup_before_quit() -> void:
	var root_window: Window = get_root()
	SceneAudioCleanupScript.release_all_audio_players(root_window)
	await process_frame
	await process_frame

	var active_scene: Node = current_scene
	if active_scene != null:
		active_scene.queue_free()
		await process_frame
		await process_frame

	for node_name in ["SceneRouter", "AppBootstrap"]:
		var runtime_node: Node = root_window.get_node_or_null(node_name)
		if runtime_node != null:
			runtime_node.queue_free()

	SceneAudioCleanupScript.release_all_audio_players(root_window)
	await process_frame
	await process_frame
	await create_timer(0.5).timeout


func _fail(message: String) -> void:
	var log_line := "%s%s" % [FAIL_MARKER_PREFIX, message]
	push_error(log_line)
	printerr(log_line)
	quit(1)
