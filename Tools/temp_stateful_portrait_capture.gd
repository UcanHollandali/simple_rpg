# Layer: Tools
extends SceneTree

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const SupportInteractionStateScript = preload("res://Game/RuntimeState/support_interaction_state.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")

const DEFAULT_TIMEOUT_MS := 5000
const DEFAULT_SETTLE_MS := 700
const DEFAULT_CAPTURE_SIZE := Vector2i(1080, 1920)

var _scenario := ""
var _output_path := ""
var _capture_size := DEFAULT_CAPTURE_SIZE
var _timeout_ms := DEFAULT_TIMEOUT_MS
var _settle_ms := DEFAULT_SETTLE_MS


func _init() -> void:
	var parse_error: String = _parse_args(OS.get_cmdline_user_args())
	if not parse_error.is_empty():
		_fail(parse_error)
		return

	Callable(self, "_run_capture").call_deferred()


func _parse_args(args: PackedStringArray) -> String:
	var index: int = 0
	while index < args.size():
		var arg: String = String(args[index])
		match arg:
			"--scenario":
				index += 1
				if index >= args.size():
					return "missing scenario after --scenario"
				_scenario = String(args[index]).strip_edges()
			"--output":
				index += 1
				if index >= args.size():
					return "missing output path after --output"
				_output_path = String(args[index]).replace("\\", "/")
			"--size":
				index += 1
				if index >= args.size():
					return "missing size after --size"
				var parsed_size: Vector2i = _parse_size(String(args[index]))
				if parsed_size == Vector2i.ZERO:
					return "invalid size: %s" % String(args[index])
				_capture_size = parsed_size
			"--timeout-ms":
				index += 1
				if index >= args.size():
					return "missing timeout after --timeout-ms"
				_timeout_ms = max(DEFAULT_TIMEOUT_MS, int(args[index]))
			"--settle-ms":
				index += 1
				if index >= args.size():
					return "missing settle after --settle-ms"
				_settle_ms = max(DEFAULT_SETTLE_MS, int(args[index]))
			_:
				return "unexpected argument: %s" % arg
		index += 1

	if _scenario.is_empty():
		return "missing required --scenario"
	if _output_path.is_empty():
		return "missing required --output"
	if _scenario not in ["map_expanded", "combat_equipped_technique", "support_training"]:
		return "unsupported scenario: %s" % _scenario
	return ""


func _parse_size(size_text: String) -> Vector2i:
	var parts: PackedStringArray = size_text.to_lower().split("x")
	if parts.size() != 2:
		return Vector2i.ZERO
	var width: int = int(parts[0])
	var height: int = int(parts[1])
	if width <= 0 or height <= 0:
		return Vector2i.ZERO
	return Vector2i(width, height)


func _run_capture() -> void:
	_ensure_runtime_bootstrap_nodes()
	_configure_capture_window()

	match _scenario:
		"map_expanded":
			await _capture_map_expanded()
		"combat_equipped_technique":
			await _capture_combat_equipped_technique()
		"support_training":
			await _capture_support_training()

	await _cleanup_before_quit()
	quit()


func _capture_map_expanded() -> void:
	var bootstrap: Node = get_root().get_node_or_null("AppBootstrap")
	if bootstrap == null:
		_fail("missing AppBootstrap")
		return
	bootstrap.call("ensure_run_state_initialized")
	_disable_runtime_hints(bootstrap)
	var run_state: RunState = bootstrap.call("get_run_state")
	if run_state == null:
		_fail("missing run state")
		return
	run_state.equipped_technique_definition_id = "echo_strike"
	change_scene_to_file("res://scenes/map_explore.tscn")
	var map_scene: Node = await _wait_for_scene("res://scenes/map_explore.tscn", _timeout_ms)
	if map_scene == null:
		_fail("timeout waiting for map_explore")
		return
	map_scene.set("_map_inventory_drawer_expanded", true)
	map_scene.call("_refresh_ui")
	await _settle_and_capture()


func _capture_combat_equipped_technique() -> void:
	var bootstrap: Node = get_root().get_node_or_null("AppBootstrap")
	if bootstrap == null:
		_fail("missing AppBootstrap")
		return
	bootstrap.call("ensure_run_state_initialized")
	_disable_runtime_hints(bootstrap)
	var run_state: RunState = bootstrap.call("get_run_state")
	if run_state == null:
		_fail("missing run state")
		return
	run_state.equipped_technique_definition_id = "echo_strike"
	change_scene_to_file("res://scenes/combat.tscn")
	var combat_scene: Node = await _wait_for_scene("res://scenes/combat.tscn", _timeout_ms)
	if combat_scene == null:
		_fail("timeout waiting for combat")
		return
	await _settle_and_capture()


func _capture_support_training() -> void:
	var bootstrap: AppBootstrap = get_root().get_node_or_null("AppBootstrap") as AppBootstrap
	if bootstrap == null:
		_fail("missing AppBootstrap")
		return
	bootstrap.ensure_run_state_initialized()
	_disable_runtime_hints(bootstrap)
	var run_state: RunState = bootstrap.get_run_state()
	if run_state == null:
		_fail("missing run state")
		return
	run_state.equipped_technique_definition_id = "blood_draw"
	var side_mission_node_id: int = _find_first_hamlet_node_id(run_state)
	if side_mission_node_id < 0:
		_fail("missing hamlet node")
		return

	var support_state: SupportInteractionState = SupportInteractionStateScript.new()
	support_state.setup_for_type("hamlet", side_mission_node_id, {
		"mission_definition_id": "trail_contract_hunt",
		"mission_status": "claimed",
		"training_step": "technique_choice",
		"technique_offers": [
			{
				"offer_id": "equip_cleanse_pulse",
				"label": "Take Cleanse Pulse",
				"effect_type": "equip_technique",
				"definition_id": "cleanse_pulse",
				"replaces_definition_id": "blood_draw",
				"available": true,
			},
			{
				"offer_id": "equip_echo_strike",
				"label": "Take Echo Strike",
				"effect_type": "equip_technique",
				"definition_id": "echo_strike",
				"available": true,
			},
			{
				"offer_id": "skip_hamlet_training",
				"label": "Skip for now",
				"effect_type": "skip_training_choice",
				"available": true,
			},
		],
	}, 1, run_state.inventory_state, run_state.map_runtime_state)
	bootstrap.run_session_coordinator.support_interaction_state = support_state

	change_scene_to_file("res://scenes/map_explore.tscn")
	var map_scene: Node = await _wait_for_scene("res://scenes/map_explore.tscn", _timeout_ms)
	if map_scene == null:
		_fail("timeout waiting for map_explore during support overlay capture")
		return
	var flow_manager: Object = bootstrap.get_flow_manager() as Object
	if flow_manager != null:
		flow_manager.call("restore_state", FlowStateScript.Type.SUPPORT_INTERACTION)
	var support_overlay: Node = await _wait_for_child_node(map_scene, "SupportOverlay", _timeout_ms)
	if support_overlay == null:
		_fail("timeout waiting for support overlay during capture")
		return
	await _settle_and_capture()


func _find_first_hamlet_node_id(run_state: RunState) -> int:
	if run_state == null or run_state.map_runtime_state == null:
		return -1
	for node_snapshot in run_state.map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == "hamlet":
			return int(node_snapshot.get("node_id", -1))
	return -1


func _settle_and_capture() -> void:
	var active_scene: Node = current_scene
	_prepare_scene_for_capture(active_scene)
	await process_frame
	await process_frame
	await create_timer(float(_settle_ms) / 1000.0).timeout
	_prepare_scene_for_capture(active_scene)
	await process_frame
	await process_frame
	var write_error: Error = _capture_current_window_to_png(_output_path)
	if write_error != OK:
		_fail("save_png_failed %s %d" % [_output_path, write_error])
		return
	print("TEMP_STATEFUL_CAPTURE: wrote %s" % _output_path)


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
	root_window.position = Vector2i(40, 40)


func _wait_for_scene(scene_path: String, timeout_ms: int) -> Node:
	var deadline_ms: int = Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline_ms:
		var active_scene: Node = current_scene
		if active_scene != null and String(active_scene.scene_file_path) == scene_path:
			return active_scene
		await create_timer(0.05).timeout
	return null


func _wait_for_child_node(parent: Node, child_name: String, timeout_ms: int) -> Node:
	if parent == null:
		return null
	var deadline_ms: int = Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline_ms:
		var child: Node = parent.get_node_or_null(child_name)
		if child != null and is_instance_valid(child):
			return child
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


func _prepare_scene_for_capture(active_scene: Node) -> void:
	if active_scene == null:
		return
	_prepare_node_for_capture(active_scene)
	var support_overlay: Node = active_scene.get_node_or_null("SupportOverlay")
	if support_overlay != null and is_instance_valid(support_overlay):
		_prepare_node_for_capture(support_overlay)


func _prepare_node_for_capture(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("_on_disable_tutorial_hints_pressed"):
		target.call("_on_disable_tutorial_hints_pressed")
	var safe_menu: Node = target.get("_safe_menu") as Node
	if safe_menu != null and is_instance_valid(safe_menu) and safe_menu.has_method("clear_status_text"):
		safe_menu.call("clear_status_text")
	var hint_controller: Object = target.get("_first_run_hint_controller") as Object
	if hint_controller != null and hint_controller.has_method("mark_all_hints_shown"):
		hint_controller.call("mark_all_hints_shown")
	elif hint_controller != null and hint_controller.has_method("dismiss_active_hint"):
		hint_controller.call("dismiss_active_hint")
	var hint_panel: CanvasItem = target.get_node_or_null("FirstRunHintPanel") as CanvasItem
	if hint_panel != null and is_instance_valid(hint_panel):
		hint_panel.visible = false


func _disable_runtime_hints(bootstrap: Node) -> void:
	if bootstrap == null:
		return
	var coordinator: Object = bootstrap.get("run_session_coordinator") as Object
	if coordinator == null:
		return
	var hint_controller: Object = coordinator.get("_first_run_hint_controller") as Object
	if hint_controller != null and hint_controller.has_method("mark_all_hints_shown"):
		hint_controller.call("mark_all_hints_shown")


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
	await process_frame
	await process_frame


func _fail(message: String) -> void:
	push_error("TEMP_STATEFUL_CAPTURE: failed %s" % message)
	printerr("TEMP_STATEFUL_CAPTURE: failed %s" % message)
	quit(1)
