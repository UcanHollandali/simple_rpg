# Layer: Tools
extends SceneTree

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const MapReviewCaptureHelperScript = preload("res://Tools/map_review_capture_helper.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")

const READY_MARKER_PREFIX := "PORTRAIT_REVIEW_CAPTURE: wrote "
const REVIEW_MARKER_PREFIX := "PORTRAIT_REVIEW_CAPTURE: review "
const LOWER_HALF_MARKER_PREFIX := "PORTRAIT_REVIEW_CAPTURE: lower_half "
const UI_OVERLAP_MARKER_PREFIX := "PORTRAIT_REVIEW_CAPTURE: ui_overlap_count "
const FAIL_MARKER_PREFIX := "PORTRAIT_REVIEW_CAPTURE: failed "
const DEFAULT_TIMEOUT_MS := 4000
const DEFAULT_SETTLE_MS := 450

var _scene_path := ""
var _output_path := ""
var _review_output_path := ""
var _capture_size := Vector2i(1080, 1920)
var _timeout_ms := DEFAULT_TIMEOUT_MS
var _settle_ms := DEFAULT_SETTLE_MS
var _run_seed := 0
var _advance_steps := 0
var _scenario_tag := ""


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
			"--review-output":
				index += 1
				if index >= args.size():
					return "missing review output path after --review-output"
				_review_output_path = String(args[index]).replace("\\", "/")
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
			"--run-seed":
				index += 1
				if index >= args.size():
					return "missing run seed after --run-seed"
				_run_seed = max(0, int(args[index]))
			"--advance-steps":
				index += 1
				if index >= args.size():
					return "missing advance step count after --advance-steps"
				_advance_steps = max(0, int(args[index]))
			"--scenario-tag":
				index += 1
				if index >= args.size():
					return "missing scenario tag after --scenario-tag"
				_scenario_tag = String(args[index]).strip_edges()
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

	var map_state_error: String = await _apply_stateful_map_capture_state(isolated_scene)
	if not map_state_error.is_empty():
		_fail(map_state_error)
		return

	_prepare_scene_for_capture(isolated_scene)
	await process_frame
	await process_frame
	await create_timer(float(_settle_ms) / 1000.0).timeout
	await process_frame
	await process_frame

	var capture_error := _capture_current_window_to_png(_output_path)
	if capture_error != OK:
		_fail("save_png_failed %s %d" % [_output_path, capture_error])
		return

	if _review_output_path != "":
		var review_write_error := _write_review_sidecar(isolated_scene, _review_output_path)
		if review_write_error != OK:
			_fail("review_write_failed %s %d" % [_review_output_path, review_write_error])
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


func _prepare_scene_for_capture(active_scene: Node) -> void:
	if active_scene == null:
		return
	if active_scene.has_method("_on_disable_tutorial_hints_pressed"):
		active_scene.call("_on_disable_tutorial_hints_pressed")
		var safe_menu: Node = active_scene.get("_safe_menu") as Node
		if safe_menu != null and is_instance_valid(safe_menu) and safe_menu.has_method("clear_status_text"):
			safe_menu.call("clear_status_text")


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


func _write_review_sidecar(active_scene: Node, review_output_path: String) -> Error:
	var parent_directory: String = review_output_path.get_base_dir()
	var make_dir_result: Error = DirAccess.make_dir_recursive_absolute(parent_directory)
	if make_dir_result != OK:
		return make_dir_result

	var review_payload: Dictionary = MapReviewCaptureHelperScript.build_scene_review(
		active_scene,
		_scene_path,
		_output_path,
		_capture_size
	)
	if _run_seed > 0 or _advance_steps > 0 or not _scenario_tag.is_empty():
		review_payload["capture_scenario"] = {
			"label": _scenario_tag,
			"run_seed": _run_seed,
			"advance_steps": _advance_steps,
		}
	var review_file: FileAccess = FileAccess.open(review_output_path, FileAccess.WRITE)
	if review_file == null:
		return FileAccess.get_open_error()
	review_file.store_string("%s\n" % JSON.stringify(review_payload, "\t"))
	review_file.flush()
	review_file.close()

	print("%s%s" % [REVIEW_MARKER_PREFIX, review_output_path])
	var map_review: Dictionary = review_payload.get("map_review", {})
	if not map_review.is_empty():
		var lower_half_readback: Dictionary = map_review.get("lower_half_readback", {})
		var lower_half_visible_node_count: int = int(lower_half_readback.get("lower_half_visible_node_count", 0))
		var visible_node_count: int = int(lower_half_readback.get("visible_node_count", 0))
		var lower_third_visible_node_count: int = int(lower_half_readback.get("lower_third_visible_node_count", 0))
		print(
			"%s%d/%d lower_third=%d" % [
				LOWER_HALF_MARKER_PREFIX,
				lower_half_visible_node_count,
				visible_node_count,
				lower_third_visible_node_count,
			]
		)
		print("%s%d" % [UI_OVERLAP_MARKER_PREFIX, int(map_review.get("ui_overlap_failure_count", 0))])

	return OK


func _apply_stateful_map_capture_state(active_scene: Node) -> String:
	if not _scene_path.ends_with("map_explore.tscn"):
		return ""
	if _run_seed <= 0 and _advance_steps <= 0:
		return ""
	var bootstrap: AppBootstrap = get_root().get_node_or_null("AppBootstrap") as AppBootstrap
	if bootstrap == null:
		return "missing_app_bootstrap_for_stateful_map_capture"
	bootstrap.reset_run_state_for_new_run()
	var run_state: RunState = bootstrap.get_run_state()
	if run_state == null:
		return "missing_run_state_for_stateful_map_capture"
	if _run_seed > 0:
		run_state.configure_run_seed(_run_seed)
	if _advance_steps > 0:
		_advance_visible_branch(run_state, _advance_steps)
	var flow_manager: Object = bootstrap.get_flow_manager() as Object
	if flow_manager != null:
		flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)
	var route_binding: Object = active_scene.get("_route_binding") as Object
	if route_binding != null and route_binding.has_method("request_next_refresh_full_recompose"):
		route_binding.call("request_next_refresh_full_recompose")
	if active_scene.has_method("_refresh_ui"):
		active_scene.call("_refresh_ui")
	await process_frame
	await process_frame
	return ""


func _advance_visible_branch(run_state: RunState, steps: int) -> void:
	if run_state == null or run_state.map_runtime_state == null or steps <= 0:
		return
	var visited_node_ids: Dictionary = {int(run_state.map_runtime_state.current_node_id): true}
	for _step in range(steps):
		var chosen_node_id: int = MapRuntimeStateScript.NO_PENDING_NODE_ID
		for adjacent_node_id_variant in run_state.map_runtime_state.get_adjacent_node_ids():
			var adjacent_node_id: int = int(adjacent_node_id_variant)
			if visited_node_ids.has(adjacent_node_id):
				continue
			chosen_node_id = adjacent_node_id
			break
		if chosen_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
			for adjacent_node_id_variant in run_state.map_runtime_state.get_adjacent_node_ids():
				var adjacent_node_id: int = int(adjacent_node_id_variant)
				if adjacent_node_id == 0:
					continue
				chosen_node_id = adjacent_node_id
				break
		if chosen_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
			return
		run_state.map_runtime_state.move_to_node(chosen_node_id)
		run_state.map_runtime_state.mark_node_resolved(chosen_node_id)
		visited_node_ids[chosen_node_id] = true


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
