# Layer: Tests
extends SceneTree
class_name TestQuitButton

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")

const MAIN_MENU_START_BUTTON_PATH := "Margin/VBox/ActionPanel/ActionVBox/StartRunButton"
const MAP_SETTINGS_LAUNCHER_BUTTON_PATH := "SafeMenuOverlay/MenuLauncherButton"
const MAP_SETTINGS_QUIT_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/QuitGameButton"
const PHASE_TIMEOUT_MS := 6000

var _phase: int = 0
var _phase_started_at_ms: int = 0


func _init() -> void:
	print("test_quit_button: setup")
	_ensure_autoload_like_nodes()
	change_scene_to_file("res://scenes/main.tscn")
	_phase_started_at_ms = Time.get_ticks_msec()
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	match _phase:
		0:
			if _is_scene("Main"):
				current_scene.call("skip_to_main_menu")
			elif _is_scene("MainMenu"):
				_press(MAIN_MENU_START_BUTTON_PATH)
				_advance_phase(1)
		1:
			if _is_scene("MapExplore"):
				_press(MAP_SETTINGS_LAUNCHER_BUTTON_PATH)
				_advance_phase(2)
		2:
			if _is_scene("MapExplore"):
				var quit_button: Button = current_scene.get_node(MAP_SETTINGS_QUIT_BUTTON_PATH) as Button
				_require(quit_button != null, "Expected quit button inside settings drawer.")
				quit_button.emit_signal("pressed")

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
	_require(current_scene != null, "Expected current scene before pressing %s." % node_path)
	var button: Button = current_scene.get_node(node_path) as Button
	_require(button != null, "Expected button at %s." % node_path)
	button.emit_signal("pressed")


func _advance_phase(new_phase: int) -> void:
	_phase = new_phase
	_phase_started_at_ms = Time.get_ticks_msec()


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
