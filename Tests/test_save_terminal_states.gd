# Layer: Tests
extends SceneTree
class_name TestSaveTerminalStates

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")
const SaveServiceScript = preload("res://Game/Infrastructure/save_service.gd")

const SAVE_PATH: String = SaveServiceScript.DEFAULT_SAVE_PATH
const CONTENT_VERSION_MISMATCH_PATH: String = "user://test_save_content_version_mismatch.json"
const MAIN_MENU_LOAD_BUTTON_PATH := "Margin/VBox/ActionPanel/ActionVBox/LoadRunButton"
const MAP_SAFE_MENU_LOAD_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/LoadRunButton"
const SAFE_MENU_SAVE_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/SaveRunButton"
const STAGE_SUMMARY_LABEL_PATH := "Margin/Center/ContentCard/VBox/SummaryLabel"
const STAGE_TITLE_LABEL_PATH := "Margin/Center/ContentCard/VBox/TitleLabel"
const STAGE_CONTINUE_BUTTON_PATH := "Margin/Center/ContentCard/VBox/ContinueButton"
const RUN_END_RESULT_LABEL_PATH := "Margin/Center/ContentCard/VBox/ResultLabel"
const RUN_END_RETURN_BUTTON_PATH := "Margin/Center/ContentCard/VBox/ReturnButton"

var _phase: int = 0
var _phase_frame_count: int = 0


func _init() -> void:
	print("test_save_terminal_states: setup")
	_assert_content_version_mismatch_is_rejected()
	_ensure_autoload_like_nodes()
	var delete_result: Dictionary = _get_bootstrap().call("delete_save_game", SAVE_PATH)
	_require(bool(delete_result.get("ok", false)), "Expected stale save cleanup to succeed.")
	change_scene_to_file("res://scenes/main.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	_phase_frame_count += 1

	match _phase:
		0:
			if _is_scene("Main"):
				current_scene.call("skip_to_main_menu")
			elif _is_scene("MainMenu"):
				_get_bootstrap().call("reset_run_state_for_new_run")
				var run_state: RunState = _get_run_state()
				_require(run_state != null, "Expected RunState before stage transition restore.")
				run_state.stage_index = 2
				_get_bootstrap().call("get_flow_manager").call("restore_state", FlowStateScript.Type.STAGE_TRANSITION)
				_get_scene_router().call("route_to_state_for_restore", FlowStateScript.Type.STAGE_TRANSITION)
				_advance_phase(1)
		1:
			if _is_scene("StageTransition"):
				var title_label: Label = current_scene.get_node(STAGE_TITLE_LABEL_PATH) as Label
				var summary_label: Label = current_scene.get_node(STAGE_SUMMARY_LABEL_PATH) as Label
				_require(title_label != null, "Expected stage transition title label.")
				_require(summary_label != null, "Expected stage transition summary label.")
				_require(summary_label.text.contains("2"), "Expected stage transition summary to reflect the saved stage index.")
				_press(SAFE_MENU_SAVE_BUTTON_PATH)
				_require(bool(_get_bootstrap().call("has_save_game", SAVE_PATH)), "Expected stage transition save to create a save file.")
				_press(STAGE_CONTINUE_BUTTON_PATH)
				_advance_phase(2)
		2:
			if _is_scene("MapExplore"):
				var run_state_after_continue: RunState = _get_run_state()
				_require(run_state_after_continue != null, "Expected RunState after stage transition continue.")
				run_state_after_continue.stage_index = 99
				_press(MAP_SAFE_MENU_LOAD_BUTTON_PATH)
				_advance_phase(3)
		3:
			if _is_scene("StageTransition"):
				var restored_summary_label: Label = current_scene.get_node(STAGE_SUMMARY_LABEL_PATH) as Label
				_require(restored_summary_label.text.contains("2"), "Expected stage transition load to restore the saved stage index.")
				_press(STAGE_CONTINUE_BUTTON_PATH)
				_advance_phase(4)
		4:
			if _is_scene("MapExplore"):
				_get_bootstrap().call("get_flow_manager").set("current_state", FlowStateScript.Type.COMBAT)
				_get_bootstrap().call("resolve_combat_result", "defeat")
				_advance_phase(5)
		5:
			if _is_scene("RunEnd"):
				var title_label: Label = current_scene.get_node(STAGE_TITLE_LABEL_PATH) as Label
				var result_label: Label = current_scene.get_node(RUN_END_RESULT_LABEL_PATH) as Label
				_require(title_label != null, "Expected RunEnd title label.")
				_require(result_label != null, "Expected RunEnd result label.")
				_require(title_label.text == "Journey's End", "Expected RunEnd title to show the saved defeat heading.")
				_require(result_label.text == "The road took this run.", "Expected RunEnd label to show the saved defeat result copy.")
				_press(SAFE_MENU_SAVE_BUTTON_PATH)
				_require(bool(_get_bootstrap().call("has_save_game", SAVE_PATH)), "Expected RunEnd save to create a save file.")
				_press(RUN_END_RETURN_BUTTON_PATH)
				_advance_phase(6)
		6:
			if _is_scene("MainMenu"):
				_press(MAIN_MENU_LOAD_BUTTON_PATH)
				_advance_phase(7)
		7:
			if _is_scene("RunEnd"):
				var restored_title_label: Label = current_scene.get_node(STAGE_TITLE_LABEL_PATH) as Label
				var restored_result_label: Label = current_scene.get_node(RUN_END_RESULT_LABEL_PATH) as Label
				_require(restored_title_label.text == "Journey's End", "Expected RunEnd load to restore the defeat heading.")
				_require(restored_result_label.text == "The road took this run.", "Expected RunEnd load to restore the defeat result label.")
				var delete_result_after_load: Dictionary = _get_bootstrap().call("delete_save_game", SAVE_PATH)
				_require(bool(delete_result_after_load.get("ok", false)), "Expected terminal save cleanup to succeed.")
				_require(not bool(_get_bootstrap().call("has_save_game", SAVE_PATH)), "Expected terminal save file to be removed.")
				print("test_save_terminal_states: all assertions passed")
				quit()

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
	_phase_frame_count = 0


func _assert_phase_timeout() -> void:
	if _phase_frame_count < 120:
		return
	_fail("Phase %d timed out on scene %s." % [_phase, _stringify_current_scene()])


func _stringify_current_scene() -> String:
	if current_scene == null:
		return "<null>"
	return "%s (%s)" % [current_scene.name, current_scene.scene_file_path]


func _assert_content_version_mismatch_is_rejected() -> void:
	var save_service: SaveService = SaveServiceScript.new()
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	var snapshot: Dictionary = save_service.create_snapshot(
		CONTENT_VERSION_MISMATCH_PATH,
		FlowStateScript.Type.MAP_EXPLORE,
		run_state.to_save_dict(),
		null,
		null,
		null,
		{}
	)
	snapshot["content_version"] = "prototype_content_v999"
	var file: FileAccess = FileAccess.open(CONTENT_VERSION_MISMATCH_PATH, FileAccess.WRITE)
	_require(file != null, "Expected to open mismatch save path for write.")
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var load_result: Dictionary = save_service.load_snapshot(CONTENT_VERSION_MISMATCH_PATH)
	_require(not bool(load_result.get("ok", false)), "Expected mismatched content_version save to be rejected.")
	_require(
		String(load_result.get("error", "")) == "unsupported_content_version",
		"Expected content_version mismatch to fail with unsupported_content_version."
	)
	var delete_result: Dictionary = save_service.delete_save_file(CONTENT_VERSION_MISMATCH_PATH)
	_require(bool(delete_result.get("ok", false)), "Expected mismatch save cleanup to succeed.")


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _fail(message: String) -> void:
	push_error(message)
	print(message)
	quit(1)
