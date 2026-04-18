# Layer: Tests
extends SceneTree
class_name TestSaveSupportInteraction

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const SaveServiceScript = preload("res://Game/Infrastructure/save_service.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")
const CONFIRM_ICON_PATH := "res://Assets/Icons/icon_confirm.svg"
const CANCEL_ICON_PATH := "res://Assets/Icons/icon_cancel.svg"
const MAIN_MENU_START_BUTTON_PATH := "Margin/VBox/ActionPanel/ActionVBox/StartRunButton"
const SUPPORT_ACTION_A_BUTTON_PATH := "Margin/VBox/ActionsRow/ActionAButton"
const SUPPORT_ACTION_B_BUTTON_PATH := "Margin/VBox/ActionsRow/ActionBButton"
const SUPPORT_ACTION_C_BUTTON_PATH := "Margin/VBox/ActionsRow/ActionCButton"
const SUPPORT_LEAVE_BUTTON_PATH := "Margin/VBox/FooterRow/LeaveButton"
const SAFE_MENU_SAVE_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/SaveRunButton"
const SAFE_MENU_LOAD_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/LoadRunButton"
const ROUTE_BUTTON_NODE_NAMES: PackedStringArray = [
	"CombatNodeButton",
	"RewardNodeButton",
	"RestNodeButton",
	"MerchantNodeButton",
	"BlacksmithNodeButton",
	"BossNodeButton",
]

const SAVE_PATH: String = SaveServiceScript.DEFAULT_SAVE_PATH

var _phase: int = 0
var _phase_frame_count: int = 0
var _is_finishing: bool = false


func _init() -> void:
	print("test_save_support_interaction: setup")
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
				_press(MAIN_MENU_START_BUTTON_PATH)
				_advance_phase(1)
		1:
			if _is_scene("MapExplore"):
				var run_state: RunState = _get_run_state()
				_require(run_state != null, "Expected RunState on MapExplore.")
				run_state.configure_run_seed(1)
				run_state.gold = 20
				run_state.player_hp = 38
				run_state.hunger = 6
				run_state.inventory_state.set_consumable_slots([
					{
						"definition_id": "minor_heal_potion",
						"current_stack": 1,
					},
				])
				_press_map_route_containing("Rest")
				_advance_phase(2)
		2:
			if _is_scene("SupportInteraction"):
				_require_support_button_icon_floor()
				var rest_state: RefCounted = _get_support_state()
				_require(rest_state != null, "Expected support state on rest visit.")
				_require(String(rest_state.support_type) == "rest", "Expected rest support type before merchant routing.")
				_press(SUPPORT_LEAVE_BUTTON_PATH)
				_advance_phase(3)
		3:
			if _is_scene("MapExplore"):
				_press_map_route_containing("Merchant")
				_advance_phase(4)
		4:
			if _is_scene("SupportInteraction"):
				_require_support_button_icon_floor()
				var support_state: RefCounted = _get_support_state()
				_require(support_state != null, "Expected support state on merchant visit.")
				_require(String(support_state.support_type) == "merchant", "Expected merchant support type.")
				_press(SAFE_MENU_SAVE_BUTTON_PATH)
				_require(bool(_get_bootstrap().call("has_save_game", SAVE_PATH)), "Expected support save to create a save file.")
				_press(SUPPORT_ACTION_A_BUTTON_PATH)
				_advance_phase(5)
		5:
			if _is_scene("SupportInteraction"):
				var run_state_after_purchase: RunState = _get_run_state()
				_require(run_state_after_purchase.gold == 14, "Expected purchase to cost 6 gold before restore.")
				var support_state_after_purchase: RefCounted = _get_support_state()
				_require(not bool(support_state_after_purchase.offers[0].get("available", true)), "Expected first merchant offer to become unavailable after purchase.")
				_press(SAFE_MENU_LOAD_BUTTON_PATH)
				_advance_phase(6)
		6:
			if _is_scene("SupportInteraction"):
				_require_support_button_icon_floor()
				var restored_run_state: RunState = _get_run_state()
				_require(restored_run_state.gold == 20, "Expected support load to restore gold.")
				var restored_support_state: RefCounted = _get_support_state()
				_require(restored_support_state != null, "Expected support state after load.")
				_require(bool(restored_support_state.offers[0].get("available", false)), "Expected support load to restore merchant offer availability.")
				_press(SUPPORT_LEAVE_BUTTON_PATH)
				_advance_phase(7)
		7:
			if _is_scene("MapExplore"):
				_require(_get_support_state() == null, "Expected support state to clear after leaving restored merchant visit.")
				var delete_result: Dictionary = _get_bootstrap().call("delete_save_game", SAVE_PATH)
				_require(bool(delete_result.get("ok", false)), "Expected support save cleanup to succeed.")
				_require(not bool(_get_bootstrap().call("has_save_game", SAVE_PATH)), "Expected support save file to be removed.")
				await _finish_success("test_save_support_interaction")

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


func _get_run_state() -> RunState:
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.call("get_run_state")


func _get_support_state() -> RefCounted:
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.call("get_support_interaction_state")


func _is_scene(expected_name: String) -> bool:
	if current_scene == null:
		return false
	if expected_name == "MapExplore":
		return current_scene.name == "MapExplore" and _get_visible_overlay_root() == null
	return _get_scene_root(expected_name) != null


func _press(node_path: String) -> void:
	var scene_root: Node = _get_scene_root()
	_require(scene_root != null, "Expected current scene before pressing %s." % node_path)
	var button: Button = scene_root.get_node(node_path) as Button
	_require(button != null, "Expected button at %s." % node_path)
	button.emit_signal("pressed")


func _press_map_route_containing(label_fragment: String) -> void:
	_require(current_scene != null, "Expected current scene before pressing a map route.")
	_require(_get_visible_overlay_root() == null, "Expected no active overlay before pressing a map route.")
	for button_name in ROUTE_BUTTON_NODE_NAMES:
		var button: Button = current_scene.get_node_or_null("Margin/VBox/RouteGrid/%s" % button_name) as Button
		if button == null or not button.visible or button.disabled:
			continue
		var route_label: String = button.text if not button.text.is_empty() else button.tooltip_text
		if route_label.contains(label_fragment):
			button.emit_signal("pressed")
			return
	_fail("Expected a visible enabled route button containing %s." % label_fragment)


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


func _require_support_button_icon_floor() -> void:
	_require_button_has_no_icon(SUPPORT_ACTION_A_BUTTON_PATH)
	_require_button_has_no_icon(SUPPORT_ACTION_B_BUTTON_PATH)
	_require_button_has_no_icon(SUPPORT_ACTION_C_BUTTON_PATH)
	_require_button_icon(SAFE_MENU_SAVE_BUTTON_PATH, CONFIRM_ICON_PATH)
	_require_button_icon(SAFE_MENU_LOAD_BUTTON_PATH, CONFIRM_ICON_PATH)
	_require_button_has_no_icon(SUPPORT_LEAVE_BUTTON_PATH)


func _require_button_icon(node_path: String, expected_path: String) -> void:
	var scene_root: Node = _get_scene_root()
	var button: Button = scene_root.get_node_or_null(node_path) as Button
	_require(button != null, "Expected button %s on %s." % [node_path, scene_root.name])
	_require(button.icon != null, "Expected button %s to expose an icon on %s." % [node_path, scene_root.name])
	_require(button.icon.resource_path == expected_path, "Expected button %s to use %s on %s, got %s." % [node_path, expected_path, scene_root.name, button.icon.resource_path])


func _require_button_has_no_icon(node_path: String) -> void:
	var scene_root: Node = _get_scene_root()
	var button: Button = scene_root.get_node_or_null(node_path) as Button
	_require(button != null, "Expected button %s on %s." % [node_path, scene_root.name])
	_require(button.icon == null, "Expected button %s to stay text-first on %s." % [node_path, scene_root.name])


func _assert_phase_timeout() -> void:
	if _phase_frame_count < 120:
		return
	_fail("Phase %d timed out on scene %s." % [_phase, _stringify_current_scene()])


func _stringify_current_scene() -> String:
	if current_scene == null:
		return "<null>"
	var overlay_root: Node = _get_visible_overlay_root()
	if overlay_root != null:
		return "%s (%s) + %s" % [current_scene.name, current_scene.scene_file_path, overlay_root.name]
	return "%s (%s)" % [current_scene.name, current_scene.scene_file_path]


func _get_scene_root(expected_name: String = "") -> Node:
	if current_scene == null:
		return null
	if expected_name.is_empty():
		var overlay_root: Node = _get_visible_overlay_root()
		return overlay_root if overlay_root != null else current_scene
	if current_scene.name == expected_name:
		return current_scene
	if current_scene.name != "MapExplore":
		return null
	var overlay_root_name: String = _overlay_root_name(expected_name)
	if overlay_root_name.is_empty():
		return null
	return _find_visible_overlay_root(overlay_root_name)


func _get_visible_overlay_root() -> Node:
	if current_scene == null or current_scene.name != "MapExplore":
		return null
	for overlay_root_name in ["SupportOverlay", "EventOverlay", "RewardOverlay", "LevelUpOverlay"]:
		var overlay_root: Control = _find_visible_overlay_root(overlay_root_name)
		if overlay_root != null:
			return overlay_root
	return null


func _find_visible_overlay_root(overlay_root_name: String) -> Control:
	if current_scene == null:
		return null
	var exact_match: Control = current_scene.get_node_or_null(overlay_root_name) as Control
	if exact_match != null and exact_match.visible:
		return exact_match
	for child in current_scene.get_children():
		var overlay_root: Control = child as Control
		if overlay_root == null or not overlay_root.visible:
			continue
		if String(overlay_root.name).begins_with(overlay_root_name):
			return overlay_root
	return null


func _overlay_root_name(expected_name: String) -> String:
	match expected_name:
		"SupportInteraction":
			return "SupportOverlay"
		"Event":
			return "EventOverlay"
		"Reward":
			return "RewardOverlay"
		"LevelUp":
			return "LevelUpOverlay"
		_:
			return ""


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _fail(message: String) -> void:
	push_error(message)
	print(message)
	quit(1)
