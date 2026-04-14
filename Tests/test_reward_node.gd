# Layer: Tests
extends SceneTree
class_name TestRewardNode

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu.tscn"
const CONFIRM_ICON_PATH := "res://Assets/Icons/icon_confirm.svg"
const REWARD_TITLE_LABEL_PATH := "Margin/VBox/HeaderRow/HeaderStack/TitleLabel"
const REWARD_SAFE_MENU_SAVE_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/SaveRunButton"
const REWARD_SAFE_MENU_LOAD_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/LoadRunButton"

var _phase: int = 0
var _phase_frame_count: int = 0
var _starting_gold: int = 0
var _starting_xp: int = 0
var _selected_reward_effect_type: String = ""
var _selected_reward_amount: int = 0


func _init() -> void:
	_ensure_autoload_like_nodes()
	change_scene_to_file(MAIN_MENU_SCENE_PATH)
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	_phase_frame_count += 1

	match _phase:
		0:
			if _is_scene("MainMenu"):
				_get_bootstrap().call("reset_run_state_for_new_run")
				_get_bootstrap().call("get_flow_manager").call("restore_state", FlowStateScript.Type.MAP_EXPLORE)
				_get_scene_router().call("route_to_state_for_restore", FlowStateScript.Type.MAP_EXPLORE)
				_advance_phase(1)
		1:
			if _is_scene("MapExplore"):
				var run_state = _get_run_state()
				_require(run_state != null, "Expected RunState on MapExplore.")
				run_state.configure_run_seed(99)
				_starting_gold = run_state.gold
				_starting_xp = run_state.xp
				_press("Margin/VBox/RouteGrid/RewardNodeButton")
				_advance_phase(2)
		2:
			if _is_scene("Reward"):
				_require(_current_state() == FlowStateScript.Type.REWARD, "Expected reward flow state after reward node.")
				var reward_state = _get_reward_state()
				_require(reward_state != null, "Expected RewardState during reward node flow.")
				_require(
					reward_state.source_context == RewardStateScript.SOURCE_REWARD_NODE,
					"Expected reward node source context."
				)
				_require(reward_state.offers.size() == 2, "Expected reward node to expose 2 offers.")

				var title_label: Label = current_scene.get_node(REWARD_TITLE_LABEL_PATH) as Label
				var choice_a_card: Control = current_scene.get_node("Margin/VBox/CardsRow/ChoiceACard") as Control
				var choice_b_card: Control = current_scene.get_node("Margin/VBox/CardsRow/ChoiceBCard") as Control
				var choice_c_card: Control = current_scene.get_node("Margin/VBox/CardsRow/ChoiceCCard") as Control
				var choice_a_button: Button = current_scene.get_node("Margin/VBox/CardsRow/ChoiceACard/VBox/ChoiceAButton") as Button
				var choice_b_button: Button = current_scene.get_node("Margin/VBox/CardsRow/ChoiceBCard/VBox/ChoiceBButton") as Button
				var choice_c_button: Button = current_scene.get_node("Margin/VBox/CardsRow/ChoiceCCard/VBox/ChoiceCButton") as Button
				var save_button: Button = current_scene.get_node(REWARD_SAFE_MENU_SAVE_BUTTON_PATH) as Button
				var load_button: Button = current_scene.get_node(REWARD_SAFE_MENU_LOAD_BUTTON_PATH) as Button
				var choice_a_title: Label = current_scene.get_node("Margin/VBox/CardsRow/ChoiceACard/VBox/OfferTitleLabel") as Label
				var choice_b_title: Label = current_scene.get_node("Margin/VBox/CardsRow/ChoiceBCard/VBox/OfferTitleLabel") as Label

				_require(title_label.text == "Cracked Trail Cache", "Expected reward node title to render from RewardState.")
				_require(choice_a_card.visible and not choice_a_button.disabled, "Expected first reward card to be active.")
				_require(choice_b_card.visible and not choice_b_button.disabled, "Expected second reward card to be active.")
				_require(not choice_c_card.visible and choice_c_button.disabled, "Expected third reward card to be hidden for reward node.")
				_require(choice_a_title.text == _expected_reward_title(reward_state.offers[0]), "Expected first reward-node card title to follow the current reward presenter mapping.")
				_require(choice_b_title.text == _expected_reward_title(reward_state.offers[1]), "Expected second reward-node card title to follow the current reward presenter mapping.")
				_require_button_has_no_icon(choice_a_button, "Expected reward claim button A to stay text-first.")
				_require_button_has_no_icon(choice_b_button, "Expected reward claim button B to stay text-first.")
				_require_button_has_no_icon(choice_c_button, "Expected reward claim button C to stay text-first while hidden.")
				_require_button_icon(save_button, CONFIRM_ICON_PATH, "Expected reward save button to expose the confirm icon floor.")
				_require_button_icon(load_button, CONFIRM_ICON_PATH, "Expected reward load button to expose the confirm icon floor.")

				_selected_reward_effect_type = String(reward_state.offers[0].get("effect_type", ""))
				_selected_reward_amount = int(reward_state.offers[0].get("amount", 0))
				choice_a_button.emit_signal("pressed")
				_advance_phase(3)
		3:
			if _is_scene("MapExplore"):
				var run_state_after_claim = _get_run_state()
				_require(_current_state() == FlowStateScript.Type.MAP_EXPLORE, "Expected return to MapExplore after reward node claim.")
				_require(_get_reward_state() == null, "Expected RewardState to clear after reward node claim.")
				match _selected_reward_effect_type:
					"grant_gold":
						_require(run_state_after_claim.gold == _starting_gold + _selected_reward_amount, "Expected reward-node gold claim to persist.")
						_require(run_state_after_claim.xp == _starting_xp, "Expected reward-node gold claim not to change XP.")
					"grant_xp":
						_require(run_state_after_claim.gold == _starting_gold, "Expected reward-node XP claim not to change gold.")
						_require(run_state_after_claim.xp == _starting_xp + _selected_reward_amount, "Expected reward-node XP claim to persist.")
					_:
						_require(true, "Expected reward-node first offer to resolve without a stat assertion branch.")
				print("test_reward_node: all assertions passed")
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


func _get_run_state():
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.call("get_run_state")


func _get_reward_state():
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.call("get_reward_state")


func _current_state() -> int:
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return -1
	var flow_manager: Node = bootstrap.call("get_flow_manager")
	if flow_manager == null:
		return -1
	return int(flow_manager.call("get_current_state"))


func _is_scene(expected_name: String) -> bool:
	return current_scene != null and current_scene.name == expected_name


func _press(node_path: String) -> void:
	var button: Button = current_scene.get_node(node_path) as Button
	_require(button != null, "Expected button at %s." % node_path)
	button.emit_signal("pressed")


func _advance_phase(new_phase: int) -> void:
	_phase = new_phase
	_phase_frame_count = 0


func _expected_reward_title(offer: Dictionary) -> String:
	var label_text: String = String(offer.get("label", ""))
	if not label_text.is_empty():
		return label_text
	return "Reward"


func _require_button_icon(button: Button, expected_path: String, message: String) -> void:
	_require(button != null, "Expected button before checking icon path.")
	_require(button.icon != null, message)
	_require(button.icon.resource_path == expected_path, "%s Got %s." % [message, button.icon.resource_path])


func _require_button_has_no_icon(button: Button, message: String) -> void:
	_require(button != null, "Expected button before checking icon absence.")
	_require(button.icon == null, message)


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
