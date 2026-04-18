# Layer: Tools
extends SceneTree

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")

const READY_MARKER_PREFIX := "PORTRAIT_REVIEW_CAPTURE: wrote "
const FAIL_MARKER_PREFIX := "PORTRAIT_REVIEW_CAPTURE: failed "
const DEFAULT_TIMEOUT_MS := 4000
const DEFAULT_SETTLE_MS := 450

var _scene_path := ""
var _output_path := ""
var _capture_size := Vector2i(1080, 1920)
var _timeout_ms := DEFAULT_TIMEOUT_MS
var _settle_ms := DEFAULT_SETTLE_MS


func _init() -> void:
	var parse_error := _parse_args(OS.get_cmdline_user_args())
	if parse_error != "":
		_fail(parse_error)
		return

	Callable(self, "_run_capture").call_deferred()


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
			"--output":
				index += 1
				if index >= args.size():
					return "missing output path after --output"
				_output_path = String(args[index]).replace("\\", "/")
			"--size":
				index += 1
				if index >= args.size():
					return "missing size after --size"
				var parsed_size := _parse_size(String(args[index]))
				if parsed_size == Vector2i.ZERO:
					return "invalid size: %s" % String(args[index])
				_capture_size = parsed_size
			"--timeout-ms":
				index += 1
				if index >= args.size():
					return "missing timeout after --timeout-ms"
				_timeout_ms = max(int(args[index]), DEFAULT_TIMEOUT_MS)
			"--settle-ms":
				index += 1
				if index >= args.size():
					return "missing settle delay after --settle-ms"
				_settle_ms = max(int(args[index]), DEFAULT_SETTLE_MS)
			_:
				return "unexpected argument: %s" % arg
		index += 1

	if _scene_path == "":
		return "missing required --scene argument"
	if _output_path == "":
		return "missing required --output argument"

	return ""


func _parse_size(size_text: String) -> Vector2i:
	var dimensions: PackedStringArray = size_text.to_lower().split("x")
	if dimensions.size() != 2:
		return Vector2i.ZERO
	var width: int = int(dimensions[0])
	var height: int = int(dimensions[1])
	if width <= 0 or height <= 0:
		return Vector2i.ZERO
	return Vector2i(width, height)


func _run_capture() -> void:
	_ensure_runtime_bootstrap_nodes()
	_configure_capture_window()
	change_scene_to_file(_scene_path)

	var isolated_scene: Node = await _wait_for_scene(_scene_path, _timeout_ms)
	if isolated_scene == null:
		_fail("timeout_before_scene_ready %s" % _scene_path)
		return

	await process_frame
	await process_frame
	await create_timer(float(_settle_ms) / 1000.0).timeout
	await process_frame
	await process_frame

	var capture_error := _capture_current_window_to_png(_output_path)
	if capture_error != OK:
		_fail("save_png_failed %s %d" % [_output_path, capture_error])
		return

	print("%s%s" % [READY_MARKER_PREFIX, _output_path])
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


func _configure_capture_window() -> void:
	var root_window: Window = get_root()
	root_window.mode = Window.MODE_WINDOWED
	root_window.min_size = _capture_size
	root_window.size = _capture_size
	root_window.position = Vector2i(32, 32)


func _wait_for_scene(scene_path: String, timeout_ms: int) -> Node:
	var deadline_ms: int = Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline_ms:
		var active_scene: Node = current_scene
		if active_scene != null and String(active_scene.scene_file_path) == scene_path:
			return active_scene
		await create_timer(0.05).timeout
	return null


func _capture_current_window_to_png(output_path: String) -> Error:
	var parent_directory: String = output_path.get_base_dir()
	var make_dir_result: Error = DirAccess.make_dir_recursive_absolute(parent_directory)
	if make_dir_result != OK:
		return make_dir_result

	var root_window: Window = get_root()
	var image: Image = root_window.get_texture().get_image()
	if image == null or image.is_empty():
		return ERR_CANT_CREATE
	return image.save_png(output_path)


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
	await create_timer(0.2).timeout


func _fail(message: String) -> void:
	var log_line := "%s%s" % [FAIL_MARKER_PREFIX, message]
	push_error(log_line)
	printerr(log_line)
	quit(1)
