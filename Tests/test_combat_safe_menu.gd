# Layer: Tests
extends SceneTree
class_name TestCombatSafeMenu

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const FirstRunHintControllerScript = preload("res://Game/UI/first_run_hint_controller.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")

const MAIN_MENU_START_BUTTON_PATH := "Margin/VBox/ActionPanel/ActionVBox/StartRunButton"
const COMBAT_SAFE_MENU_LAUNCHER_BUTTON_PATH := "SafeMenuOverlay/MenuLauncherButton"
const COMBAT_SAFE_MENU_MENU_LAYER_PATH := "SafeMenuOverlay/MenuLayer"
const COMBAT_SAFE_MENU_STATUS_LABEL_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/StatusLabel"
const COMBAT_SAFE_MENU_TITLE_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/TitleLabel"
const COMBAT_SAFE_MENU_SUBTITLE_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/SubtitleLabel"
const COMBAT_SAFE_MENU_TUTORIAL_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/DisableTutorialHintsButton"
const COMBAT_SAFE_MENU_MAIN_MENU_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/ReturnToMainMenuButton"
const COMBAT_SAFE_MENU_TOAST_PANEL_PATH := "SafeMenuOverlay/StatusToast"
const COMBAT_SAFE_MENU_TOAST_LABEL_PATH := "SafeMenuOverlay/StatusToast/StatusToastLabel"
const ROUTE_BUTTON_NODE_NAMES: PackedStringArray = [
	"CombatNodeButton",
	"RewardNodeButton",
	"RestNodeButton",
	"MerchantNodeButton",
	"BlacksmithNodeButton",
	"BossNodeButton",
]

var _phase: int = 0
var _phase_frame_count: int = 0
var _is_finishing: bool = false


func _init() -> void:
	print("test_combat_safe_menu: setup")
	_ensure_autoload_like_nodes()
	change_scene_to_file("res://scenes/main.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	_phase_frame_count += 1

	match _phase:
		0:
			if _is_scene("Main"):
				current_scene.call("skip_to_main_menu")
			elif _is_scene("MainMenu"):
				_press(MAIN_MENU_START_BUTTON_PATH)
				_advance_phase(1)
		1:
			if _is_scene("MapExplore"):
				var run_state: RunState = _get_run_state()
				_require(run_state != null, "Expected RunState before routing into combat.")
				run_state.configure_run_seed(1)
				var combat_node_id: int = _prepare_map_adjacent_to_family("combat")
				current_scene.call("_refresh_ui")
				current_scene.call("_move_to_node", combat_node_id)
				_advance_phase(2)
		2:
			if _is_scene("Combat"):
				_require(_current_state() == FlowStateScript.Type.COMBAT, "Expected Combat flow state before opening the combat safe menu.")
				var launcher_button: Button = current_scene.get_node_or_null(COMBAT_SAFE_MENU_LAUNCHER_BUTTON_PATH) as Button
				_require(launcher_button != null, "Expected Combat to expose the shared safe-menu launcher.")
				launcher_button.emit_signal("pressed")
				_advance_phase(3)
		3:
			if _is_scene("Combat"):
				var menu_layer: Control = current_scene.get_node_or_null(COMBAT_SAFE_MENU_MENU_LAYER_PATH) as Control
				var title_label: Label = current_scene.get_node_or_null(COMBAT_SAFE_MENU_TITLE_PATH) as Label
				var subtitle_label: Label = current_scene.get_node_or_null(COMBAT_SAFE_MENU_SUBTITLE_PATH) as Label
				var tutorial_button: Button = current_scene.get_node_or_null(COMBAT_SAFE_MENU_TUTORIAL_BUTTON_PATH) as Button
				var main_menu_button: Button = current_scene.get_node_or_null(COMBAT_SAFE_MENU_MAIN_MENU_BUTTON_PATH) as Button
				_require(menu_layer != null and menu_layer.visible, "Expected combat safe menu to open after pressing the launcher.")
				_require(title_label != null and title_label.text == "Settings", "Expected combat safe menu title to match the shared Settings title.")
				_require(tutorial_button != null and tutorial_button.visible and not tutorial_button.disabled, "Expected combat safe menu to expose the tutorial suppression button while hints remain.")
				_require(main_menu_button != null, "Expected combat safe menu to keep the return-to-main-menu button node for shared menu structure.")
				_require(main_menu_button.visible, "Expected combat safe menu to keep Return to Main Menu visible for shared layout consistency.")
				_require(main_menu_button.disabled, "Expected combat safe menu to disable Return to Main Menu because combat is not a direct main-menu exit state.")
				_require(subtitle_label != null and subtitle_label.text == "Save, load, return to menu, mute music, or quit.", "Expected combat safe-menu subtitle to match the shared settings copy.")
				tutorial_button.emit_signal("pressed")
				_advance_phase(4)
		4:
			if _is_scene("Combat"):
				if _phase_frame_count < 12:
					return
				var bootstrap: Node = get_root().get_node_or_null("AppBootstrap")
				var coordinator: RefCounted = bootstrap.run_session_coordinator if bootstrap != null else null
				var hint_controller: FirstRunHintController = coordinator.get("_first_run_hint_controller") as FirstRunHintController if coordinator != null else null
				var tutorial_button: Button = current_scene.get_node_or_null(COMBAT_SAFE_MENU_TUTORIAL_BUTTON_PATH) as Button
				var menu_layer: Control = current_scene.get_node_or_null(COMBAT_SAFE_MENU_MENU_LAYER_PATH) as Control
				var status_label: Label = current_scene.get_node_or_null(COMBAT_SAFE_MENU_STATUS_LABEL_PATH) as Label
				var toast_panel: PanelContainer = current_scene.get_node_or_null(COMBAT_SAFE_MENU_TOAST_PANEL_PATH) as PanelContainer
				var toast_label: Label = current_scene.get_node_or_null(COMBAT_SAFE_MENU_TOAST_LABEL_PATH) as Label
				var expected_hint_ids: Array[String] = []
				for hint_id in FirstRunHintControllerScript.FROZEN_HINT_IDS:
					expected_hint_ids.append(String(hint_id))
				expected_hint_ids.sort()
				_require(hint_controller != null, "Expected combat safe-menu coverage to resolve the shared first-run hint controller.")
				_require(hint_controller.get_active_hint_id().is_empty(), "Expected safe-menu tutorial suppression to dismiss the active hint immediately.")
				_require(
					hint_controller.build_save_data() == expected_hint_ids,
					"Expected safe-menu tutorial suppression to mark the frozen hint set as shown for this save."
				)
				_require(menu_layer == null or not menu_layer.visible, "Expected tutorial suppression to close the safe-menu panel instead of leaving the large settings surface visible.")
				_require(status_label == null or not status_label.visible, "Expected tutorial suppression status copy to stay out of the large settings panel after the menu closes.")
				_require(toast_panel != null and toast_panel.visible, "Expected tutorial suppression to fall back to the compact toast lane after the menu closes.")
				_require(toast_label != null and String(toast_label.text) == "Tutorial hints disabled for this save.", "Expected the tutorial suppression toast to keep the shared status copy.")
				_require(tutorial_button != null and not tutorial_button.visible, "Expected the tutorial suppression button to hide once no hints remain.")
				await _finish_success("test_combat_safe_menu")

	_assert_phase_timeout()


func _ensure_autoload_like_nodes() -> void:
	var root: Window = get_root()
	var bootstrap: Node = root.get_node_or_null("AppBootstrap")
	if bootstrap == null:
		bootstrap = AppBootstrapScript.new()
		bootstrap.name = "AppBootstrap"
		root.add_child(bootstrap)

	var scene_router: Node = root.get_node_or_null("SceneRouter")
	if scene_router == null:
		scene_router = SceneRouterScript.new()
		scene_router.name = "SceneRouter"
		root.add_child(scene_router)


func _is_scene(expected_name: String) -> bool:
	return current_scene != null and current_scene.name == expected_name


func _press(node_path: String) -> void:
	var button: Button = current_scene.get_node_or_null(node_path) as Button
	_require(button != null, "Expected button at %s." % node_path)
	button.emit_signal("pressed")


func _press_map_route_containing(label_fragment: String) -> void:
	_require(current_scene != null and current_scene.name == "MapExplore", "Expected MapExplore before pressing a route button.")
	var route_models: Array = current_scene.get("_route_models_cache")
	for route_index in range(ROUTE_BUTTON_NODE_NAMES.size()):
		var button_name: String = String(ROUTE_BUTTON_NODE_NAMES[route_index])
		var button: Button = current_scene.get_node_or_null("Margin/VBox/RouteGrid/%s" % button_name) as Button
		if button == null or not button.visible or button.disabled:
			continue
		var route_label: String = button.text if not button.text.is_empty() else button.tooltip_text
		if route_label.contains(label_fragment):
			if route_index >= 0 and route_index < route_models.size():
				var target_node_id: int = int((route_models[route_index] as Dictionary).get("node_id", -1))
				if target_node_id >= 0:
					current_scene.call("_move_to_node", target_node_id)
					return
			button.emit_signal("pressed")
			return
	_fail("Expected a visible enabled route button containing %s." % label_fragment)


func _current_state() -> int:
	var bootstrap: Node = get_root().get_node_or_null("AppBootstrap")
	if bootstrap == null:
		return -1
	var flow_manager: Node = bootstrap.call("get_flow_manager")
	if flow_manager == null:
		return -1
	return int(flow_manager.call("get_current_state"))


func _get_run_state() -> RunState:
	var bootstrap: Node = get_root().get_node_or_null("AppBootstrap")
	if bootstrap == null:
		return null
	return bootstrap.call("get_run_state")


func _prepare_map_adjacent_to_family(node_family: String) -> int:
	var run_state: RunState = _get_run_state()
	_require(run_state != null, "Expected RunState before preparing map adjacency for %s." % node_family)
	var target_node_id: int = _find_unresolved_node_id_by_family(run_state.map_runtime_state, node_family)
	_require(target_node_id >= 0, "Expected an unresolved %s node for combat safe-menu coverage." % node_family)
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, target_node_id)
	return target_node_id


func _find_unresolved_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) != node_family:
			continue
		if String(node_snapshot.get("node_state", "")) != "resolved":
			return int(node_snapshot.get("node_id", -1))
	return -1


func _prepare_current_node_adjacent_to_target(map_runtime_state: RefCounted, target_node_id: int) -> void:
	var path: Array[int] = _build_path_between_nodes(map_runtime_state, map_runtime_state.current_node_id, target_node_id)
	_require(path.size() >= 2, "Expected a valid runtime path to target node %d." % target_node_id)
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
		for adjacent_node_id in map_runtime_state.get_adjacent_node_ids(current_node_id):
			if visited.has(adjacent_node_id):
				continue
			var next_path: Array = path.duplicate()
			next_path.append(adjacent_node_id)
			queued_paths.append(next_path)
	return []


func _advance_phase(new_phase: int) -> void:
	_phase = new_phase
	_phase_frame_count = 0


func _finish_success(test_name: String) -> void:
	if _is_finishing:
		return
	_is_finishing = true
	var process_frame_handler := Callable(self, "_on_process_frame")
	if process_frame.is_connected(process_frame_handler):
		process_frame.disconnect(process_frame_handler)
	print("%s: all assertions passed" % test_name)
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func _assert_phase_timeout() -> void:
	if _phase_frame_count < 120:
		return
	_fail("Phase %d timed out on scene %s." % [_phase, _stringify_current_scene()])


func _stringify_current_scene() -> String:
	if current_scene == null:
		return "<null>"
	return "%s (%s)" % [current_scene.name, current_scene.scene_file_path]


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _fail(message: String) -> void:
	push_error(message)
	printerr(message)
	quit(1)
