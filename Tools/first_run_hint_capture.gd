# Layer: Tools
extends SceneTree

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const RunSessionCoordinatorScript = preload("res://Game/Application/run_session_coordinator.gd")
const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")
const RunStatusStripScript = preload("res://Game/UI/run_status_strip.gd")
const MapExplorePackedScene: PackedScene = preload("res://scenes/map_explore.tscn")
const CombatPackedScene: PackedScene = preload("res://scenes/combat.tscn")
const EventPackedScene: PackedScene = preload("res://scenes/event.tscn")
const SupportInteractionPackedScene: PackedScene = preload("res://scenes/support_interaction.tscn")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")

const READY_MARKER_PREFIX := "FIRST_RUN_HINT_CAPTURE: wrote "
const FAIL_MARKER_PREFIX := "FIRST_RUN_HINT_CAPTURE: failed "
const DEFAULT_TIMEOUT_MS := 6000
const DEFAULT_SETTLE_MS := 450
const SUPPORTED_HINT_IDS := {
	"first_combat_defend": true,
	"first_left_hand_shield": true,
	"first_left_hand_offhand_weapon": true,
	"first_belt_capacity": true,
	"first_low_hunger_warning": true,
	"first_hamlet": true,
	"first_roadside_encounter": true,
	"first_key_required_route": true,
}

var _hint_id: String = ""
var _mode: String = "trigger"
var _output_path: String = ""
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
			"--hint":
				index += 1
				if index >= args.size():
					return "missing hint id after --hint"
				_hint_id = String(args[index]).strip_edges()
			"--mode":
				index += 1
				if index >= args.size():
					return "missing mode after --mode"
				_mode = String(args[index]).strip_edges().to_lower()
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

	if not SUPPORTED_HINT_IDS.has(_hint_id):
		return "unsupported hint id: %s" % _hint_id
	if _mode not in ["trigger", "non_retrigger"]:
		return "unsupported mode: %s" % _mode
	if _output_path.is_empty():
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
	_configure_capture_window()
	var bootstrap: AppBootstrapScript = await _install_runtime_nodes()
	if bootstrap == null:
		_fail("missing_bootstrap")
		return
	match _hint_id:
		"first_combat_defend":
			await _capture_combat_defend(bootstrap)
		"first_left_hand_shield":
			await _capture_inventory_hint(bootstrap, {
				"inventory_next_slot_id": 8,
				"backpack_slots": [],
				"equipped_right_hand_slot": {},
				"equipped_left_hand_slot": {
					"slot_id": 7,
					"inventory_family": "shield",
					"definition_id": "watchman_shield",
				},
				"equipped_armor_slot": {},
				"equipped_belt_slot": {},
			})
		"first_left_hand_offhand_weapon":
			await _capture_inventory_hint(bootstrap, {
				"inventory_next_slot_id": 12,
				"backpack_slots": [
					{
						"slot_id": 11,
						"inventory_family": "weapon",
						"definition_id": "briar_knife",
						"current_durability": 17,
					},
				],
				"equipped_right_hand_slot": {},
				"equipped_left_hand_slot": {},
				"equipped_armor_slot": {},
				"equipped_belt_slot": {},
			})
		"first_belt_capacity":
			await _capture_inventory_hint(bootstrap, {
				"inventory_next_slot_id": 10,
				"backpack_slots": [],
				"equipped_right_hand_slot": {},
				"equipped_left_hand_slot": {},
				"equipped_armor_slot": {},
				"equipped_belt_slot": {
					"slot_id": 9,
					"inventory_family": "belt",
					"definition_id": "provisioner_belt",
				},
			})
		"first_low_hunger_warning":
			await _capture_low_hunger_hint(bootstrap)
		"first_hamlet":
			await _capture_hamlet_hint(bootstrap)
		"first_roadside_encounter":
			await _capture_roadside_hint(bootstrap)
		"first_key_required_route":
			await _capture_key_required_route_hint(bootstrap)
	var capture_error := _capture_current_window_to_png(_output_path)
	if capture_error != OK:
		_fail("save_png_failed %s %d" % [_output_path, capture_error])
		return
	print("%s%s" % [READY_MARKER_PREFIX, _output_path])
	await _cleanup_before_quit()
	quit()


func _capture_combat_defend(bootstrap: AppBootstrapScript) -> void:
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE)
	bootstrap.reset_run_state_for_new_run()
	bootstrap.ensure_run_state_initialized()
	var controller: FirstRunHintController = _get_hint_controller(bootstrap)
	controller.reset()
	if _mode == "non_retrigger":
		controller.mark_hint_shown("first_combat_defend")
	var combat_scene: Control = await _mount_scene(CombatPackedScene.instantiate() as Control)
	if combat_scene == null:
		_fail("combat_scene_mount_failed")
		return
	await _settle_capture_frames(5)


func _capture_inventory_hint(bootstrap: AppBootstrapScript, inventory_save_data: Dictionary) -> void:
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE)
	bootstrap.reset_run_state_for_new_run()
	bootstrap.ensure_run_state_initialized()
	var controller: FirstRunHintController = _get_hint_controller(bootstrap)
	controller.reset()
	if _mode == "non_retrigger":
		controller.mark_hint_shown(_hint_id)
	var run_state: RunState = bootstrap.get_run_state()
	run_state.inventory_state.load_from_flat_save_dict(inventory_save_data)
	var map_scene: Control = await _mount_scene(MapExplorePackedScene.instantiate() as Control)
	if map_scene == null:
		_fail("map_scene_mount_failed")
		return
	await _settle_capture_frames(5)


func _capture_low_hunger_hint(bootstrap: AppBootstrapScript) -> void:
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE)
	bootstrap.reset_run_state_for_new_run()
	bootstrap.ensure_run_state_initialized()
	var controller: FirstRunHintController = _get_hint_controller(bootstrap)
	controller.reset()
	if _mode == "non_retrigger":
		controller.mark_hint_shown("first_low_hunger_warning")
	var map_scene: Control = await _mount_scene(MapExplorePackedScene.instantiate() as Control)
	if map_scene == null:
		_fail("map_scene_mount_failed")
		return
	await _settle_capture_frames(4)
	map_scene.call(
		"_on_hunger_threshold_crossed",
		RunStatusStripScript.HUNGER_THRESHOLD_SAFE,
		RunStatusStripScript.HUNGER_THRESHOLD_HUNGRY
	)
	await _settle_capture_frames(4)


func _capture_hamlet_hint(bootstrap: AppBootstrapScript) -> void:
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE)
	bootstrap.reset_run_state_for_new_run()
	bootstrap.ensure_run_state_initialized()
	var controller: FirstRunHintController = _get_hint_controller(bootstrap)
	controller.reset()
	if _mode == "non_retrigger":
		controller.mark_hint_shown("first_hamlet")
	var run_state: RunState = bootstrap.get_run_state()
	var hamlet_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	if hamlet_node_id < 0:
		_fail("missing_hamlet_node")
		return
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, hamlet_node_id)
	var move_result: Dictionary = bootstrap.choose_move_to_node(hamlet_node_id)
	if not bool(move_result.get("ok", false)) or int(move_result.get("target_state", -1)) != FlowStateScript.Type.SUPPORT_INTERACTION:
		_fail("hamlet_move_failed")
		return
	var support_scene: Control = SupportInteractionPackedScene.instantiate() as Control
	if support_scene == null:
		_fail("support_scene_mount_failed")
		return
	support_scene.top_level = true
	await _mount_scene(support_scene)
	await _settle_capture_frames(5)


func _capture_roadside_hint(bootstrap: AppBootstrapScript) -> void:
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE)
	bootstrap.reset_run_state_for_new_run()
	bootstrap.ensure_run_state_initialized()
	var controller: FirstRunHintController = _get_hint_controller(bootstrap)
	controller.reset()
	if _mode == "non_retrigger":
		controller.mark_hint_shown("first_roadside_encounter")
	var run_state: RunState = bootstrap.get_run_state()
	var move_context: Dictionary = _configure_seed_for_any_predicted_roadside_adjacent_family(run_state)
	if move_context.is_empty():
		_fail("missing_roadside_route")
		return
	var move_result: Dictionary = bootstrap.choose_move_to_node(int(move_context.get("target_node_id", -1)))
	if not bool(move_result.get("ok", false)) or int(move_result.get("target_state", -1)) != FlowStateScript.Type.EVENT:
		_fail("roadside_move_failed")
		return
	var event_scene: Control = EventPackedScene.instantiate() as Control
	if event_scene == null:
		_fail("event_scene_mount_failed")
		return
	event_scene.top_level = true
	await _mount_scene(event_scene)
	await _settle_capture_frames(5)


func _capture_key_required_route_hint(bootstrap: AppBootstrapScript) -> void:
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE)
	bootstrap.reset_run_state_for_new_run()
	bootstrap.ensure_run_state_initialized()
	var controller: FirstRunHintController = _get_hint_controller(bootstrap)
	controller.reset()
	if _mode == "non_retrigger":
		controller.mark_hint_shown("first_key_required_route")
	var run_state: RunState = bootstrap.get_run_state()
	var boss_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "boss")
	if boss_node_id < 0:
		_fail("missing_boss_node")
		return
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, boss_node_id)
	var map_scene: Control = await _mount_scene(MapExplorePackedScene.instantiate() as Control)
	if map_scene == null:
		_fail("map_scene_mount_failed")
		return
	await _settle_capture_frames(5)


func _install_runtime_nodes() -> AppBootstrapScript:
	var root_window: Window = get_root()
	var bootstrap: AppBootstrapScript = root_window.get_node_or_null("AppBootstrap") as AppBootstrapScript
	if bootstrap == null:
		bootstrap = AppBootstrapScript.new()
		bootstrap.name = "AppBootstrap"
		root_window.add_child(bootstrap)
	var scene_router: Node = root_window.get_node_or_null("SceneRouter")
	if scene_router == null:
		scene_router = SceneRouterScript.new()
		scene_router.name = "SceneRouter"
		root_window.add_child(scene_router)
	await _settle_capture_frames(2)
	return bootstrap


func _mount_scene(scene: Control) -> Control:
	await _clear_current_scene()
	var root_window: Window = get_root()
	root_window.add_child(scene)
	current_scene = scene
	await _settle_capture_frames(3)
	return scene


func _clear_current_scene() -> void:
	if current_scene == null:
		return
	var active_scene: Node = current_scene
	current_scene = null
	active_scene.queue_free()
	await _settle_capture_frames(3)


func _settle_capture_frames(frame_count: int = 2) -> void:
	for _frame in range(max(1, frame_count)):
		await process_frame
	await create_timer(float(_settle_ms) / 1000.0).timeout


func _get_hint_controller(bootstrap: AppBootstrapScript) -> FirstRunHintController:
	return bootstrap.run_session_coordinator.get("_first_run_hint_controller") as FirstRunHintController


func _configure_seed_for_any_predicted_roadside_adjacent_family(run_state: RunState, max_seed: int = 512) -> Dictionary:
	if run_state == null or run_state.map_runtime_state == null:
		return {}
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var from_node_id: int = map_runtime_state.current_node_id
	var stream_name: String = String(RunSessionCoordinatorScript.ROADSIDE_ENCOUNTER_STREAM_NAME)
	var trigger_chance: float = float(RunSessionCoordinatorScript.ROADSIDE_ENCOUNTER_TRIGGER_CHANCE)
	for seed in range(1, max_seed + 1):
		run_state.configure_run_seed(seed)
		run_state.rng_stream_states.clear()
		for adjacent_node_id_variant in map_runtime_state.get_adjacent_node_ids(from_node_id):
			var target_node_id: int = int(adjacent_node_id_variant)
			var target_family: String = String(map_runtime_state.get_node_family(target_node_id))
			if RunSessionCoordinatorScript.ROADSIDE_ENCOUNTER_EXCLUDED_FAMILIES.has(target_family):
				continue
			if not _predict_roadside_open(run_state, stream_name, trigger_chance, from_node_id, target_node_id, target_family):
				continue
			var preview_event_state := EventStateScript.new()
			preview_event_state.setup_for_node(
				target_node_id,
				run_state.stage_index,
				EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER,
				seed,
				_build_test_roadside_trigger_context(run_state)
			)
			if preview_event_state.choices.is_empty():
				continue
			return {
				"seed": seed,
				"target_node_id": target_node_id,
				"target_family": target_family,
			}
	run_state.rng_stream_states.clear()
	return {}


func _build_test_roadside_trigger_context(run_state: RunState) -> Dictionary:
	if run_state == null:
		return {}
	var max_hp: int = max(1, RunState.DEFAULT_PLAYER_HP)
	return {
		EventStateScript.TRIGGER_STAT_HUNGER: run_state.hunger,
		EventStateScript.TRIGGER_STAT_HP_PERCENT: (float(run_state.player_hp) / float(max_hp)) * 100.0,
		EventStateScript.TRIGGER_STAT_GOLD: run_state.gold,
	}


func _predict_roadside_open(
	run_state: RunState,
	stream_name: String,
	chance: float,
	from_node_id: int,
	target_node_id: int,
	target_node_type: String
) -> bool:
	if run_state == null:
		return false
	var draw_index: int = int(run_state.rng_stream_states.get(stream_name, 0))
	var context_salt: String = "%s|from:%d|to:%d|stage:%d" % [
		target_node_type,
		from_node_id,
		target_node_id,
		run_state.stage_index,
	]
	var stream_seed: int = _build_named_stream_seed(run_state.run_seed, stream_name, draw_index, context_salt)
	var rng := RandomNumberGenerator.new()
	rng.seed = stream_seed
	return rng.randf() < chance


func _build_named_stream_seed(run_seed: int, stream_name: String, draw_index: int, context_salt: String) -> int:
	var accumulator: int = 216613626
	var seed_value: String = "%d|%s|%d|%s" % [run_seed, stream_name, draw_index, context_salt]
	for byte in seed_value.to_utf8_buffer():
		accumulator = abs(int((accumulator ^ int(byte)) * 16777619))
	if accumulator == 0:
		return 1
	return accumulator


func _find_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot_variant in map_runtime_state.build_node_snapshots():
		if typeof(node_snapshot_variant) != TYPE_DICTIONARY:
			continue
		var node_snapshot: Dictionary = node_snapshot_variant
		if String(node_snapshot.get("node_family", "")) == node_family:
			return int(node_snapshot.get("node_id", -1))
	return -1


func _prepare_current_node_adjacent_to_target(map_runtime_state: RefCounted, target_node_id: int) -> void:
	var path: Array[int] = _build_path_between_nodes(map_runtime_state, int(map_runtime_state.current_node_id), target_node_id)
	if path.size() < 2:
		return
	for path_index in range(1, path.size() - 1):
		var node_id: int = path[path_index]
		map_runtime_state.move_to_node(node_id)
		map_runtime_state.mark_node_resolved(node_id)


func _build_path_between_nodes(map_runtime_state: RefCounted, start_node_id: int, target_node_id: int) -> Array[int]:
	var queued_paths: Array = [[start_node_id]]
	var visited: Dictionary = {}
	while not queued_paths.is_empty():
		var path: Array = queued_paths.pop_front()
		var current_node_id: int = int(path[path.size() - 1])
		if current_node_id == target_node_id:
			var typed_path: Array[int] = []
			for node_id_variant in path:
				typed_path.append(int(node_id_variant))
			return typed_path
		if visited.has(current_node_id):
			continue
		visited[current_node_id] = true
		for adjacent_node_id_variant in map_runtime_state.get_adjacent_node_ids(current_node_id):
			var adjacent_node_id: int = int(adjacent_node_id_variant)
			if visited.has(adjacent_node_id):
				continue
			var next_path: Array = path.duplicate()
			next_path.append(adjacent_node_id)
			queued_paths.append(next_path)
	return []


func _configure_capture_window() -> void:
	var root_window: Window = get_root()
	root_window.mode = Window.MODE_WINDOWED
	root_window.min_size = _capture_size
	root_window.size = _capture_size
	root_window.position = Vector2i(32, 32)


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
	await _clear_current_scene()
	for node_name in ["SceneRouter", "AppBootstrap"]:
		var runtime_node: Node = root_window.get_node_or_null(node_name)
		if runtime_node != null:
			runtime_node.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.2).timeout


func _fail(message: String) -> void:
	var log_line := "%s%s" % [FAIL_MARKER_PREFIX, message]
	push_error(log_line)
	printerr(log_line)
	quit(1)
