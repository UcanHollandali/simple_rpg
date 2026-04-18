# Layer: Tests
extends SceneTree
class_name TestStageTransition

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")
const CONFIRM_ICON_PATH := "res://Assets/Icons/icon_confirm.svg"
const CONTINUE_BUTTON_PATH := "Margin/Center/ContentCard/VBox/ContinueButton"
const TITLE_LABEL_PATH := "Margin/Center/ContentCard/VBox/TitleLabel"
const SUMMARY_LABEL_PATH := "Margin/Center/ContentCard/VBox/SummaryLabel"
const HINT_LABEL_PATH := "Margin/Center/ContentCard/VBox/HintLabel"
const SAFE_MENU_SAVE_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/SaveRunButton"
const SAFE_MENU_LOAD_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/LoadRunButton"

var _phase: int = 0
var _phase_frame_count: int = 0
var _stage_transition_frames: int = 0
var _is_finishing: bool = false


func _init() -> void:
	print("test_stage_transition: setup")
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
				var bootstrap: Node = _get_bootstrap()
				bootstrap.call("reset_run_state_for_new_run")
				var run_state: RunState = bootstrap.call("get_run_state")
				_require(run_state != null, "Expected RunState before stage transition test.")
				run_state.stage_index = 3
				run_state.map_runtime_state.reset_for_next_stage(run_state.stage_index, run_state.run_seed)
				bootstrap.call("get_flow_manager").call("restore_state", FlowStateScript.Type.STAGE_TRANSITION)
				_get_scene_router().call("route_to_state_for_restore", FlowStateScript.Type.STAGE_TRANSITION)
				_advance_phase(1)
		1:
			if _is_scene("StageTransition"):
				_require(_current_state() == FlowStateScript.Type.STAGE_TRANSITION, "Expected StageTransition flow state.")
				_require_stage_transition_background_shell()
				_require_audio_player_stream("UiConfirmSfxPlayer")
				_require_audio_player_stream("PanelOpenSfxPlayer")
				_require_audio_player_stream("PanelCloseSfxPlayer")
				_require_audio_player_stream("StageTransitionMusicPlayer")
				var title_label: Label = current_scene.get_node(TITLE_LABEL_PATH) as Label
				var summary_label: Label = current_scene.get_node(SUMMARY_LABEL_PATH) as Label
				var hint_label: Label = current_scene.get_node(HINT_LABEL_PATH) as Label
				_require(title_label != null, "Expected stage transition title label.")
				_require(summary_label != null, "Expected stage transition summary label.")
				_require(hint_label != null, "Expected stage transition hint label.")
				_require(title_label.text.contains("Stage 3"), "Expected stage transition title to reflect the incoming stage number.")
				_require(title_label.text.contains("Trade"), "Expected stage transition title to surface the stage personality read.")
				_require(summary_label.text.contains("Trade"), "Expected stage transition summary to surface the stage-personality copy.")
				_require(hint_label.text.contains("key"), "Expected stage transition hint to expose the stage objective.")
				_require(hint_label.text.contains("boss"), "Expected stage transition hint to keep the boss objective visible.")
				_require_button_icon(CONTINUE_BUTTON_PATH, CONFIRM_ICON_PATH)
				_require_button_icon(SAFE_MENU_SAVE_BUTTON_PATH, CONFIRM_ICON_PATH)
				_require_button_icon(SAFE_MENU_LOAD_BUTTON_PATH, CONFIRM_ICON_PATH)
				_stage_transition_frames += 1
				if _stage_transition_frames < 5:
					return
				_press(CONTINUE_BUTTON_PATH)
				_advance_phase(2)
		2:
			if _is_scene("MapExplore"):
				var run_state_after_continue: RunState = _get_bootstrap().call("get_run_state")
				_require(run_state_after_continue != null, "Expected RunState after stage transition continue.")
				_require(run_state_after_continue.stage_index == 3, "Expected stage index to persist through StageTransition.")
				await _finish_success("test_stage_transition")

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


func _is_scene(expected_name: String) -> bool:
	return current_scene != null and current_scene.name == expected_name


func _current_state() -> int:
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return -1
	var flow_manager: Node = bootstrap.call("get_flow_manager")
	if flow_manager == null:
		return -1
	return int(flow_manager.call("get_current_state"))


func _press(node_path: String) -> void:
	if current_scene == null:
		_fail("Expected current scene before pressing %s." % node_path)
	var button: Button = current_scene.get_node(node_path) as Button
	_require(button != null, "Expected button at %s." % node_path)
	button.emit_signal("pressed")


func _require_stage_transition_background_shell() -> void:
	_require(current_scene != null and current_scene.name == "StageTransition", "Expected StageTransition scene before reading background shell state.")
	_require_texture_rect_present("BackgroundFar")
	_require_texture_rect_present("BackgroundMid")
	_require_texture_rect_present("BackgroundOverlay")


func _require_texture_rect_present(node_name: String) -> void:
	var texture_rect: TextureRect = current_scene.get_node_or_null(node_name) as TextureRect
	_require(texture_rect != null, "Expected TextureRect %s to exist on %s." % [node_name, current_scene.name])
	_require(texture_rect.visible, "Expected TextureRect %s to stay visible on %s." % [node_name, current_scene.name])
	_require(texture_rect.texture != null, "Expected TextureRect %s to have a texture on %s." % [node_name, current_scene.name])


func _require_audio_player_stream(node_name: String) -> void:
	var player: AudioStreamPlayer = current_scene.get_node_or_null(node_name) as AudioStreamPlayer
	_require(player != null, "Expected AudioStreamPlayer %s to exist on %s." % [node_name, current_scene.name])
	_require(player.stream != null, "Expected AudioStreamPlayer %s to have a stream on %s." % [node_name, current_scene.name])


func _require_button_icon(node_path: String, expected_path: String) -> void:
	var button: Button = current_scene.get_node_or_null(node_path) as Button
	_require(button != null, "Expected button %s on %s." % [node_path, current_scene.name])
	_require(button.icon != null, "Expected button %s to expose an icon on %s." % [node_path, current_scene.name])
	_require(button.icon.resource_path == expected_path, "Expected button %s to use %s on %s, got %s." % [node_path, expected_path, current_scene.name, button.icon.resource_path])


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
	print(message)
	quit(1)
