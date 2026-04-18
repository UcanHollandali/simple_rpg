# Layer: Tests
extends SceneTree
class_name TestSupportInteraction

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const CONFIRM_ICON_PATH := "res://Assets/Icons/icon_confirm.svg"
const MAIN_MENU_START_BUTTON_PATH := "Margin/VBox/ActionPanel/ActionVBox/StartRunButton"
const SUPPORT_ACTION_A_BUTTON_PATH := "Margin/VBox/ActionsRow/ActionAButton"
const SUPPORT_ACTION_B_BUTTON_PATH := "Margin/VBox/ActionsRow/ActionBButton"
const SUPPORT_ACTION_C_BUTTON_PATH := "Margin/VBox/ActionsRow/ActionCButton"
const SUPPORT_LEAVE_BUTTON_PATH := "Margin/VBox/FooterRow/LeaveButton"
const SAFE_MENU_SAVE_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/SaveRunButton"
const SAFE_MENU_LOAD_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/LoadRunButton"
const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")
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
	print("test_support_interaction: setup")
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
				_require_generic_background_shell()
				_press(MAIN_MENU_START_BUTTON_PATH)
				_advance_phase(1)
		1:
			if _is_scene("MapExplore"):
				var run_state: RunState = _get_run_state()
				_require(run_state != null, "Expected RunState to exist.")
				run_state.configure_run_seed(1)
				run_state.player_hp = 40
				run_state.hunger = 13
				run_state.gold = 20
				run_state.inventory_state.weapon_instance["current_durability"] = 5
				run_state.inventory_state.set_consumable_slots([
					{
						"definition_id": "wild_berries",
						"current_stack": 1,
					},
				])
				_press_map_route_containing("Rest")
				_advance_phase(2)
		2:
			if _is_scene("SupportInteraction"):
				_require_modal_popup_shell()
				_require(_current_state() == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected SupportInteraction flow state.")
				_require_support_button_icon_floor()
				var support_state: RefCounted = _get_support_state()
				_require(support_state != null, "Expected SupportInteractionState for rest.")
				_require(String(support_state.support_type) == "rest", "Expected rest support type.")
				_require(support_state.offers.size() == 1, "Expected one rest action.")
				_press(SUPPORT_ACTION_A_BUTTON_PATH)
				_advance_phase(3)
		3:
			if _is_scene("MapExplore"):
				var run_state_after_rest: RunState = _get_run_state()
				_require(run_state_after_rest.player_hp == 50, "Expected rest to heal 10 HP.")
				_require(run_state_after_rest.hunger == 9, "Expected rest to spend 3 hunger after the node-move hunger cost.")
				_require(_get_support_state() == null, "Expected support state to clear after rest.")
				_press_map_route_containing("Merchant")
				_advance_phase(4)
		4:
			if _is_scene("SupportInteraction"):
				_require_modal_popup_shell()
				_require_support_button_icon_floor()
				var merchant_state: RefCounted = _get_support_state()
				_require(merchant_state != null, "Expected SupportInteractionState for merchant.")
				_require(String(merchant_state.support_type) == "merchant", "Expected merchant support type.")
				_require(merchant_state.offers.size() == 3, "Expected merchant to expose 3 offers.")
				_press(SUPPORT_ACTION_A_BUTTON_PATH)
				_advance_phase(5)
		5:
			if _is_scene("SupportInteraction"):
				var run_state_after_purchase: RunState = _get_run_state()
				_require(run_state_after_purchase.gold == 14, "Expected first merchant purchase to cost 6 gold.")
				_require(run_state_after_purchase.inventory_state.consumable_slots.size() == 2, "Expected bread purchase to add a second food stack beside the starter food.")
				_require(String(run_state_after_purchase.inventory_state.consumable_slots[0].get("definition_id", "")) == "wild_berries", "Expected the starter food stack to remain first.")
				_require(String(run_state_after_purchase.inventory_state.consumable_slots[1].get("definition_id", "")) == "traveler_bread", "Expected the first merchant food purchase to add traveler bread.")
				_require(int(run_state_after_purchase.inventory_state.consumable_slots[1].get("current_stack", 0)) == 1, "Expected the purchased bread stack to add exactly one item.")
				var merchant_state_after_purchase: RefCounted = _get_support_state()
				_require(merchant_state_after_purchase != null, "Expected merchant state to persist after one purchase.")
				_require(not bool(merchant_state_after_purchase.offers[0].get("available", true)), "Expected purchased offer to become unavailable.")
				_press(SUPPORT_LEAVE_BUTTON_PATH)
				_advance_phase(6)
		6:
			if _is_scene("MapExplore"):
				_require(_get_support_state() == null, "Expected support state to clear after leaving the merchant.")
				_set_stage_on_current_run(2)
				_press_map_route_containing("Merchant")
				_advance_phase(7)
		7:
			if _is_scene("SupportInteraction"):
				_require_modal_popup_shell()
				_require_support_button_icon_floor()
				var stage_two_merchant_state: RefCounted = _get_support_state()
				_require(stage_two_merchant_state != null, "Expected stage-2 merchant support state.")
				_require(String(stage_two_merchant_state.support_type) == "merchant", "Expected stage-2 opening support to route to merchant.")
				_require(stage_two_merchant_state.offers.size() == 3, "Expected stage-2 merchant stock to expose 3 offers.")
				_require(
					String(stage_two_merchant_state.offers[0].get("offer_id", "")) == "buy_war_biscuit_x1",
					"Expected the stage-2 merchant stock to switch to the authored stage-2 consumable offer."
				)
				_require(
					String(stage_two_merchant_state.offers[1].get("offer_id", "")) == "buy_bandit_hatchet",
					"Expected the stage-2 merchant stock to switch to the authored dual-wield weapon offer."
				)
				_require(
					String(stage_two_merchant_state.offers[2].get("offer_id", "")) == "buy_pilgrim_board",
					"Expected the stage-2 merchant stock to expose the authored survival shield offer."
				)
				_press(SUPPORT_LEAVE_BUTTON_PATH)
				_advance_phase(8)
		8:
			if _is_scene("MapExplore"):
				_set_stage_on_current_run(3)
				_press_map_route_containing("Rest")
				_advance_phase(9)
		9:
			if _is_scene("SupportInteraction"):
				_require_modal_popup_shell()
				_require_support_button_icon_floor()
				var stage_three_rest_state: RefCounted = _get_support_state()
				_require(stage_three_rest_state != null, "Expected stage-3 rest hub before blacksmith routing.")
				_require(String(stage_three_rest_state.support_type) == "rest", "Expected stage-3 opening support to remain rest.")
				_press(SUPPORT_LEAVE_BUTTON_PATH)
				_advance_phase(10)
		10:
			if _is_scene("MapExplore"):
				var inventory_actions: RefCounted = InventoryActionsScript.new()
				var prepare_blacksmith_result: Dictionary = inventory_actions.replace_active_weapon(_get_run_state().inventory_state, "splitter_axe")
				_require(bool(prepare_blacksmith_result.get("ok", false)), "Expected carried weapon setup before blacksmith coverage.")
				_press_map_route_containing("Blacksmith")
				_advance_phase(11)
		11:
			if _is_scene("SupportInteraction"):
				_require_modal_popup_shell()
				_require_support_button_icon_floor()
				var blacksmith_state: RefCounted = _get_support_state()
				_require(blacksmith_state != null, "Expected SupportInteractionState for blacksmith.")
				_require(String(blacksmith_state.support_type) == "blacksmith", "Expected blacksmith support type.")
				_require(blacksmith_state.offers.size() == 3, "Expected blacksmith to expose three service actions.")
				_require(String(blacksmith_state.offers[0].get("label", "")).contains("Temper Weapon"), "Expected blacksmith root action A to open weapon targeting.")
				_require(String(blacksmith_state.offers[1].get("label", "")).contains("No Target"), "Expected blacksmith root action B to explain missing carried armor targets.")
				_press(SUPPORT_ACTION_A_BUTTON_PATH)
				_advance_phase(12)
		12:
			if _is_scene("SupportInteraction"):
				var blacksmith_target_state: RefCounted = _get_support_state()
				_require(blacksmith_target_state != null, "Expected blacksmith target-selection state after opening weapon tempering.")
				_require(bool(blacksmith_target_state.call("is_blacksmith_target_selection_active")), "Expected blacksmith to switch into target-selection mode.")
				_require(String(blacksmith_target_state.title_text) == "Temper Weapon", "Expected blacksmith target-selection title to stay explicit.")
				_require(String(blacksmith_target_state.offers[0].get("label", "")).contains("Iron Sword"), "Expected the first blacksmith target to include the carried non-active weapon.")
				var support_root: Node = _get_scene_root("SupportInteraction")
				var leave_button: Button = support_root.get_node_or_null(SUPPORT_LEAVE_BUTTON_PATH) as Button
				_require(leave_button != null and leave_button.text == "Back to Services", "Expected blacksmith target-selection to retitle the leave button as a service back action.")
				_press(SUPPORT_ACTION_A_BUTTON_PATH)
				_advance_phase(13)
		13:
			if _is_scene("MapExplore"):
				var run_state_after_blacksmith: RunState = _get_run_state()
				_require(run_state_after_blacksmith.gold == 7, "Expected blacksmith tempering to cost 7 gold after the earlier 6-gold merchant spend.")
				_require(String(run_state_after_blacksmith.inventory_state.weapon_instance.get("definition_id", "")) == "splitter_axe", "Expected tempering a carried weapon not to swap the active weapon lane.")
				var carried_weapon_slot_id: int = -1
				for slot in run_state_after_blacksmith.inventory_state.inventory_slots:
					if String(slot.get("inventory_family", "")) != "weapon":
						continue
					if int(slot.get("slot_id", -1)) == int(run_state_after_blacksmith.inventory_state.active_weapon_slot_id):
						continue
					carried_weapon_slot_id = int(slot.get("slot_id", -1))
					break
				_require(carried_weapon_slot_id > 0, "Expected a carried non-active weapon slot after blacksmith tempering.")
				var carried_weapon_slot_index: int = run_state_after_blacksmith.inventory_state.find_slot_index_by_id(carried_weapon_slot_id)
				_require(int(run_state_after_blacksmith.inventory_state.inventory_slots[carried_weapon_slot_index].get("upgrade_level", 0)) == 1, "Expected blacksmith tempering to upgrade the carried weapon slot.")
				_require(_get_support_state() == null, "Expected support state to clear after blacksmith.")
				_press_map_route_containing("Rest")
				_advance_phase(14)
		14:
			if _is_scene("MapExplore"):
				_require(_get_support_state() == null, "Expected resolved rest revisit after blacksmith not to reopen support state.")
				_advance_phase(15)
		15:
			if _is_scene("MapExplore") and _phase_frame_count >= 60:
				await _finish_success("test_support_interaction")

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
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return -1
	var flow_manager: Node = bootstrap.call("get_flow_manager")
	if flow_manager == null:
		return -1
	return int(flow_manager.call("get_current_state"))


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


func _get_bootstrap() -> Node:
	return get_root().get_node_or_null("AppBootstrap")


func _set_stage_on_current_run(stage_index: int) -> void:
	var run_state: RunState = _get_run_state()
	_require(run_state != null, "Expected RunState before switching stage lanes in the support integration test.")
	run_state.stage_index = stage_index
	run_state.map_runtime_state.reset_for_new_run(stage_index)
	current_scene.call("_refresh_ui")


func _require_modal_popup_shell() -> void:
	var scene_root: Node = _get_scene_root()
	var scrim: ColorRect = scene_root.get_node_or_null("Scrim") as ColorRect
	_require(scrim != null, "Expected Scrim on %s." % scene_root.name)
	_require(scrim.visible, "Expected Scrim to stay visible on %s." % scene_root.name)
	var margin: Control = scene_root.get_node_or_null("Margin") as Control
	_require(margin != null, "Expected Margin popup root on %s." % scene_root.name)
	_require(margin.visible, "Expected Margin popup root to stay visible on %s." % scene_root.name)
	var shell: PanelContainer = scene_root.get_node_or_null("Margin/ContentShell") as PanelContainer
	var uses_full_scene_shell: bool = shell != null and shell.visible
	if uses_full_scene_shell:
		_require_texture_rect_present("BackgroundFar")
		_require_texture_rect_present("BackgroundMid")
	else:
		_require_hidden_texture_rect_present("BackgroundFar")
		_require_hidden_texture_rect_present("BackgroundMid")
	var overlay: TextureRect = scene_root.get_node_or_null("BackgroundOverlay") as TextureRect
	_require(overlay != null, "Expected TextureRect BackgroundOverlay to exist on %s." % scene_root.name)
	_require(overlay.visible if uses_full_scene_shell else not overlay.visible, "Expected TextureRect BackgroundOverlay visibility on %s to match the current popup mode." % scene_root.name)
	_require(overlay.texture != null, "Expected TextureRect BackgroundOverlay to keep a texture on %s." % scene_root.name)


func _require_generic_background_shell() -> void:
	_require_texture_rect_present("BackgroundFar")
	_require_texture_rect_present("BackgroundMid")
	_require_texture_rect_present("BackgroundOverlay")


func _require_texture_rect_present(node_name: String) -> void:
	var scene_root: Node = _get_scene_root()
	var texture_rect: TextureRect = scene_root.get_node_or_null(node_name) as TextureRect
	_require(texture_rect != null, "Expected TextureRect %s to exist on %s." % [node_name, scene_root.name])
	_require(texture_rect.visible, "Expected TextureRect %s to stay visible on %s." % [node_name, scene_root.name])
	_require(texture_rect.texture != null, "Expected TextureRect %s to have a texture on %s." % [node_name, scene_root.name])


func _require_hidden_texture_rect_present(node_name: String) -> void:
	var scene_root: Node = _get_scene_root()
	var texture_rect: TextureRect = scene_root.get_node_or_null(node_name) as TextureRect
	_require(texture_rect != null, "Expected TextureRect %s to exist on %s." % [node_name, scene_root.name])
	_require(not texture_rect.visible, "Expected TextureRect %s to stay hidden on %s." % [node_name, scene_root.name])
	_require(texture_rect.texture != null, "Expected TextureRect %s to have a texture on %s." % [node_name, scene_root.name])


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
