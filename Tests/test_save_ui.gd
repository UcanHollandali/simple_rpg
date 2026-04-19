# Layer: Tests
extends SceneTree
class_name TestSaveUi

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const AudioPreferencesScript = preload("res://Game/UI/audio_preferences.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const SaveServiceScript = preload("res://Game/Infrastructure/save_service.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")

const SAVE_PATH: String = SaveServiceScript.DEFAULT_SAVE_PATH
const MAIN_MENU_START_BUTTON_PATH := "Margin/VBox/ActionPanel/ActionVBox/StartRunButton"
const MAIN_MENU_LOAD_BUTTON_PATH := "Margin/VBox/ActionPanel/ActionVBox/LoadRunButton"
const MAP_SAFE_MENU_LAUNCHER_BUTTON_PATH := "Margin/VBox/TopRow/SettingsMenuAnchor/SettingsButton"
const MAP_SAFE_MENU_TOAST_PATH := "SafeMenuOverlay/StatusToast"
const MAP_SAFE_MENU_SAVE_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/SaveRunButton"
const MAP_SAFE_MENU_LOAD_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/LoadRunButton"
const MAP_SAFE_MENU_MAIN_MENU_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/ReturnToMainMenuButton"
const MAP_SAFE_MENU_MUSIC_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/MusicToggleButton"
const MAP_SAFE_MENU_QUIT_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/QuitGameButton"
const MAP_SAFE_MENU_TOAST_LABEL_PATH := "SafeMenuOverlay/StatusToast/StatusToastLabel"
const PHASE_TIMEOUT_MS := 6000

var _phase: int = 0
var _phase_started_at_ms: int = 0
var _pending_saved_stats: Dictionary = {}
var _is_finishing: bool = false


func _init() -> void:
	print("test_save_ui: setup")
	_ensure_autoload_like_nodes()
	var delete_result: Dictionary = _get_bootstrap().call("delete_save_game", SAVE_PATH)
	_require(bool(delete_result.get("ok", false)), "Expected stale UI save cleanup to succeed.")
	change_scene_to_file("res://scenes/main.tscn")
	_phase_started_at_ms = Time.get_ticks_msec()
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	match _phase:
		0:
			if _is_scene("Main"):
				current_scene.call("skip_to_main_menu")
			elif _is_scene("MainMenu"):
				var load_button: Button = current_scene.get_node(MAIN_MENU_LOAD_BUTTON_PATH) as Button
				_require(load_button != null, "Expected load button on MainMenu.")
				_require(load_button.disabled, "Expected MainMenu load button to start disabled when no save exists.")
				_press(MAIN_MENU_START_BUTTON_PATH)
				_advance_phase(1)
		1:
			if _is_scene("MapExplore"):
				var active_flow_state: int = int(_get_bootstrap().call("get_flow_manager").call("get_current_state"))
				if active_flow_state != FlowStateScript.Type.MAP_EXPLORE:
					return
				var run_state: RunState = _get_run_state()
				_require(run_state != null, "Expected RunState on MapExplore.")
				var launcher_button: Button = current_scene.get_node(MAP_SAFE_MENU_LAUNCHER_BUTTON_PATH) as Button
				var load_button_before_save: Button = current_scene.get_node(MAP_SAFE_MENU_LOAD_BUTTON_PATH) as Button
				var main_menu_button: Button = current_scene.get_node(MAP_SAFE_MENU_MAIN_MENU_BUTTON_PATH) as Button
				var music_button: Button = current_scene.get_node(MAP_SAFE_MENU_MUSIC_BUTTON_PATH) as Button
				var quit_button: Button = current_scene.get_node(MAP_SAFE_MENU_QUIT_BUTTON_PATH) as Button
				_require(launcher_button != null, "Expected launcher button on MapExplore.")
				_require(launcher_button.text.is_empty(), "Expected safe menu launcher to stay icon-only.")
				_require(launcher_button.tooltip_text == "Settings", "Expected safe menu launcher tooltip to read Settings.")
				_require(load_button_before_save != null, "Expected load button on MapExplore.")
				_require(load_button_before_save.disabled, "Expected MapExplore load button to start disabled when no save exists.")
				_require(main_menu_button != null, "Expected return-to-main-menu button on MapExplore settings drawer.")
				_require(music_button != null, "Expected music toggle button on MapExplore settings drawer.")
				_require(quit_button != null, "Expected quit button on MapExplore settings drawer.")
				_require(music_button.text == "Music: On", "Expected music toggle to start enabled.")
				music_button.emit_signal("pressed")
				_require(not AudioPreferencesScript.is_music_enabled(), "Expected music toggle to mute music.")
				_require(music_button.text == "Music: Off", "Expected music toggle text to flip off.")
				music_button.emit_signal("pressed")
				_require(AudioPreferencesScript.is_music_enabled(), "Expected music toggle to restore music.")
				_require(music_button.text == "Music: On", "Expected music toggle text to flip back on.")
				run_state.player_hp = 39
				run_state.gold = 21
				run_state.hunger = 8
				var save_button: Button = current_scene.get_node(MAP_SAFE_MENU_SAVE_BUTTON_PATH) as Button
				var toast_panel: PanelContainer = current_scene.get_node(MAP_SAFE_MENU_TOAST_PATH) as PanelContainer
				var toast_label: Label = current_scene.get_node(MAP_SAFE_MENU_TOAST_LABEL_PATH) as Label
				_require(save_button != null, "Expected save button on MapExplore.")
				save_button.emit_signal("pressed")
				_require(toast_panel != null and toast_panel.visible, "Expected save success toast panel on MapExplore.")
				_require(toast_label != null and toast_label.text == "Run saved.", "Expected save success toast on MapExplore.")
				_pending_saved_stats = {
					"player_hp": 39,
					"gold": 21,
					"hunger": 8,
				}
				_advance_phase(2)
		2:
			if _is_scene("MapExplore"):
				var load_button_after_save_on_map: Button = current_scene.get_node(MAP_SAFE_MENU_LOAD_BUTTON_PATH) as Button
				var main_menu_button: Button = current_scene.get_node(MAP_SAFE_MENU_MAIN_MENU_BUTTON_PATH) as Button
				_require(bool(_get_bootstrap().call("has_save_game")), "Expected UI save to create the default save file.")
				_require(load_button_after_save_on_map != null, "Expected load button on MapExplore after save.")
				_require(not load_button_after_save_on_map.disabled, "Expected MapExplore load button to enable after save succeeds.")
				var run_state_after_save: RunState = _get_run_state()
				run_state_after_save.player_hp = 1
				run_state_after_save.gold = 0
				run_state_after_save.hunger = 0
				_require(main_menu_button != null, "Expected return-to-main-menu button after save.")
				main_menu_button.emit_signal("pressed")
				_advance_phase(3)
		3:
			if _is_scene("MainMenu"):
				var load_button_after_save: Button = current_scene.get_node(MAIN_MENU_LOAD_BUTTON_PATH) as Button
				_require(not load_button_after_save.disabled, "Expected MainMenu load button to enable after a save exists.")
				load_button_after_save.emit_signal("pressed")
				_advance_phase(4)
		4:
			if _is_scene("MapExplore"):
				var restored_run_state: RunState = _get_run_state()
				_require(restored_run_state.player_hp == int(_pending_saved_stats.get("player_hp", -1)), "Expected UI load to restore HP.")
				_require(restored_run_state.gold == int(_pending_saved_stats.get("gold", -1)), "Expected UI load to restore gold.")
				_require(restored_run_state.hunger == int(_pending_saved_stats.get("hunger", -1)), "Expected UI load to restore hunger.")
				var delete_result_after_load: Dictionary = _get_bootstrap().call("delete_save_game", SAVE_PATH)
				_require(bool(delete_result_after_load.get("ok", false)), "Expected UI save cleanup to succeed.")
				_require(not bool(_get_bootstrap().call("has_save_game")), "Expected UI save file to be removed.")
				await _finish_success("test_save_ui")

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


func _get_bootstrap() -> Node:
	return get_root().get_node_or_null("AppBootstrap")


func _get_scene_router() -> Node:
	return get_root().get_node_or_null("SceneRouter")


func _get_run_state() -> RunState:
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.call("get_run_state")


func _is_scene(expected_name: String) -> bool:
	return current_scene != null and current_scene.name == expected_name


func _press(node_path: String) -> void:
	var button: Button = current_scene.get_node(node_path) as Button
	_require(button != null, "Expected button at %s." % node_path)
	button.emit_signal("pressed")


func _advance_phase(new_phase: int) -> void:
	_phase = new_phase
	_phase_started_at_ms = Time.get_ticks_msec()


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
	if Time.get_ticks_msec() - _phase_started_at_ms < PHASE_TIMEOUT_MS:
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
	print(message)
	quit(1)
