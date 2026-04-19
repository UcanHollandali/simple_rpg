# Layer: Tests
extends SceneTree
class_name TestRewardNode

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu.tscn"
const CONFIRM_ICON_PATH := "res://Assets/Icons/icon_confirm.svg"
const REWARD_TITLE_LABEL_PATH := "Margin/VBox/OffersShell/VBox/HeaderRow/HeaderCard/HeaderStack/TitleLabel"
const REWARD_OFFERS_SHELL_PATH := "Margin/VBox/OffersShell"
const REWARD_HEADER_CARD_PATH := "Margin/VBox/OffersShell/VBox/HeaderRow/HeaderCard"
const REWARD_SAFE_MENU_SAVE_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/SaveRunButton"
const REWARD_SAFE_MENU_LOAD_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/LoadRunButton"

var _phase: int = 0
var _phase_frame_count: int = 0
var _starting_gold: int = 0
var _starting_xp: int = 0
var _selected_reward_effect_type: String = ""
var _selected_reward_amount: int = 0
var _selected_reward_definition_id: String = ""
var _selected_reward_inventory_family: String = ""
var _is_finishing: bool = false


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
				var reward_node_id: int = _prepare_map_adjacent_to_family("reward")
				current_scene.call("_move_to_node", reward_node_id)
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
				var reward_root: Node = _get_scene_root("Reward")

				var title_label: Label = reward_root.get_node(REWARD_TITLE_LABEL_PATH) as Label
				var offers_shell: PanelContainer = reward_root.get_node(REWARD_OFFERS_SHELL_PATH) as PanelContainer
				var header_card: PanelContainer = reward_root.get_node(REWARD_HEADER_CARD_PATH) as PanelContainer
				var choice_a_card: Control = reward_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceACard") as Control
				var choice_b_card: Control = reward_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceBCard") as Control
				var choice_c_card: Control = reward_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceCCard") as Control
				var choice_a_button: Button = reward_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceACard/VBox/ChoiceAButton") as Button
				var choice_b_button: Button = reward_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceBCard/VBox/ChoiceBButton") as Button
				var choice_c_button: Button = reward_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceCCard/VBox/ChoiceCButton") as Button
				var save_button: Button = reward_root.get_node(REWARD_SAFE_MENU_SAVE_BUTTON_PATH) as Button
				var load_button: Button = reward_root.get_node(REWARD_SAFE_MENU_LOAD_BUTTON_PATH) as Button
				var run_status_card: PanelContainer = reward_root.get_node_or_null("Margin/VBox/OffersShell/VBox/HeaderRow/RunStatusCard") as PanelContainer
				var choice_a_title: Label = reward_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceACard/VBox/OfferTitleLabel") as Label
				var choice_b_title: Label = reward_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceBCard/VBox/OfferTitleLabel") as Label
				var tooltip_panel: PanelContainer = reward_root.get_node_or_null("InventoryTooltipPanel") as PanelContainer
				var tooltip_label: Label = tooltip_panel.get_node_or_null("InventoryTooltipLabel") as Label if tooltip_panel != null else null

				_require(title_label.text == "Cracked Trail Cache", "Expected reward node title to render from RewardState.")
				_require(offers_shell != null, "Expected reward overlay to expose the shared offer shell.")
				_require(header_card != null, "Expected reward header copy to sit inside a dedicated header card.")
				_require(run_status_card != null and not run_status_card.visible, "Expected reward overlay to hide the duplicate run-status card because the shared top bar already shows it.")
				_require(choice_a_card.visible and not choice_a_button.disabled, "Expected first reward card to be active.")
				_require(choice_b_card.visible and not choice_b_button.disabled, "Expected second reward card to be active.")
				_require(not choice_c_card.visible and choice_c_button.disabled, "Expected third reward card to be hidden for reward node.")
				_require(choice_a_title.text == _expected_reward_title(reward_state.offers[0]), "Expected first reward-node card title to follow the current reward presenter mapping.")
				_require(choice_b_title.text == _expected_reward_title(reward_state.offers[1]), "Expected second reward-node card title to follow the current reward presenter mapping.")
				var choice_a_tooltip_text: String = String(choice_a_button.get_meta("custom_tooltip_text", ""))
				var choice_b_tooltip_text: String = String(choice_b_button.get_meta("custom_tooltip_text", ""))
				_require(not choice_a_tooltip_text.is_empty(), "Expected reward claim button A to expose hover tooltip copy.")
				_require(not choice_b_tooltip_text.is_empty(), "Expected reward claim button B to expose hover tooltip copy.")
				_require(tooltip_panel != null and tooltip_label != null, "Expected reward overlay to create the shared tooltip bubble shell.")
				choice_a_button.emit_signal("mouse_entered")
				_require(tooltip_panel.visible, "Expected reward choice hover to show the shared tooltip bubble.")
				_require(tooltip_label.text == choice_a_tooltip_text, "Expected reward hover bubble to mirror the button tooltip copy.")
				_require(tooltip_panel.size.y < 220.0, "Expected first reward hover bubble sizing not to stretch the shared tooltip vertically.")
				choice_a_button.emit_signal("mouse_exited")
				_require(not tooltip_panel.visible, "Expected reward hover bubble to hide after pointer exit.")
				_require_button_icon(choice_a_button, _expected_reward_button_icon_path(reward_state.offers[0]), "Expected reward claim button A to expose the offer effect icon.")
				_require_button_icon(choice_b_button, _expected_reward_button_icon_path(reward_state.offers[1]), "Expected reward claim button B to expose the offer effect icon.")
				_require_button_has_no_icon(choice_c_button, "Expected reward claim button C to stay icon-free while hidden.")
				_require_button_icon(save_button, CONFIRM_ICON_PATH, "Expected reward save button to expose the confirm icon floor.")
				_require_button_icon(load_button, CONFIRM_ICON_PATH, "Expected reward load button to expose the confirm icon floor.")

				var selected_reward_index: int = _find_reward_offer_index_by_effect_type(reward_state.offers, "grant_item")
				if selected_reward_index < 0:
					reward_state.offers[0] = {
						"offer_id": "test_item_reward",
						"effect_type": "grant_item",
						"inventory_family": "shield",
						"definition_id": "watchman_shield",
						"amount": 1,
						"label": "Test Reward: Watchman Shield",
					}
					reward_root.call("_render_reward_state")
					selected_reward_index = 0
				_selected_reward_effect_type = String(reward_state.offers[selected_reward_index].get("effect_type", ""))
				_selected_reward_amount = int(reward_state.offers[selected_reward_index].get("amount", 0))
				_selected_reward_definition_id = String(reward_state.offers[selected_reward_index].get("definition_id", ""))
				_selected_reward_inventory_family = String(reward_state.offers[selected_reward_index].get("inventory_family", ""))
				_match_reward_button_by_index(selected_reward_index, choice_a_button, choice_b_button, choice_c_button).emit_signal("pressed")
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
					"grant_item":
						_require(
							_inventory_contains_family_definition(run_state_after_claim.inventory_state, _selected_reward_inventory_family, _selected_reward_definition_id),
							"Expected claimed reward item to enter InventoryState before any later movement refresh."
						)
						_require(
							_map_backpack_contains_title(_expected_item_display_name(_selected_reward_inventory_family, _selected_reward_definition_id)),
							"Expected claimed reward item to render in the map backpack immediately after returning from Reward."
						)
					_:
						_require(true, "Expected reward-node first offer to resolve without a stat assertion branch.")
				await _finish_success("test_reward_node")

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


func _advance_phase(new_phase: int) -> void:
	_phase = new_phase
	_phase_frame_count = 0


func _expected_reward_title(offer: Dictionary) -> String:
	var label_text: String = String(offer.get("label", ""))
	if not label_text.is_empty():
		return label_text
	return "Reward"


func _expected_reward_button_icon_path(offer: Dictionary) -> String:
	return UiAssetPathsScript.build_effect_icon_texture_path(
		String(offer.get("effect_type", "")),
		String(offer.get("inventory_family", ""))
	)


func _find_reward_offer_index_by_effect_type(offers: Array, effect_type: String) -> int:
	for index in range(offers.size()):
		if String((offers[index] as Dictionary).get("effect_type", "")) == effect_type:
			return index
	return -1


func _match_reward_button_by_index(index: int, choice_a_button: Button, choice_b_button: Button, choice_c_button: Button) -> Button:
	match index:
		0:
			return choice_a_button
		1:
			return choice_b_button
		2:
			return choice_c_button
		_:
			return choice_a_button


func _inventory_contains_family_definition(inventory_state: InventoryState, inventory_family: String, definition_id: String) -> bool:
	if inventory_state == null or inventory_family.is_empty() or definition_id.is_empty():
		return false
	for slot in inventory_state.inventory_slots:
		if String(slot.get("inventory_family", "")) != inventory_family:
			continue
		if String(slot.get("definition_id", "")) == definition_id:
			return true
	return false


func _map_backpack_contains_title(expected_title: String) -> bool:
	if current_scene == null:
		return false
	var inventory_cards_flow: Node = current_scene.get_node_or_null("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow")
	if inventory_cards_flow == null:
		return false
	for child in inventory_cards_flow.get_children():
		var title_label: Label = child.get_node_or_null("VBox/TitleLabel") as Label
		if title_label != null and title_label.text == expected_title:
			return true
	return false


func _expected_item_display_name(inventory_family: String, definition_id: String) -> String:
	match inventory_family:
		"weapon":
			return "Iron Sword" if definition_id == "iron_sword" else "Weapon"
		"shield":
			return "Watchman Shield" if definition_id == "watchman_shield" else "Shield"
		"armor":
			return "Watcher Mail" if definition_id == "watcher_mail" else "Armor"
		"belt":
			return "Trailhook Bandolier" if definition_id == "trailhook_bandolier" else "Belt"
		"consumable":
			return "Traveler Bread" if definition_id == "traveler_bread" else "Consumable"
		"passive":
			return "Thorn Grip Charm" if definition_id == "iron_grip_charm" else "Passive"
		_:
			return definition_id


func _prepare_map_adjacent_to_family(node_family: String) -> int:
	var run_state = _get_run_state()
	_require(run_state != null, "Expected RunState before preparing reward test adjacency for %s." % node_family)
	var map_runtime_state = run_state.map_runtime_state
	var target_node_id: int = _find_unresolved_node_id_by_family(map_runtime_state, node_family)
	if target_node_id < 0:
		target_node_id = _find_any_node_id_by_family(map_runtime_state, node_family)
	_require(target_node_id >= 0, "Expected a %s node for reward integration coverage." % node_family)
	_prepare_current_node_adjacent_to_target(map_runtime_state, target_node_id)
	current_scene.call("_refresh_ui")
	return target_node_id


func _find_unresolved_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) != node_family:
			continue
		if String(node_snapshot.get("node_state", "")) != "resolved":
			return int(node_snapshot.get("node_id", -1))
	return -1


func _find_any_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == node_family:
			return int(node_snapshot.get("node_id", -1))
	return -1


func _prepare_current_node_adjacent_to_target(map_runtime_state: RefCounted, target_node_id: int) -> void:
	var path: Array[int] = _build_path_between_nodes(map_runtime_state, map_runtime_state.current_node_id, target_node_id)
	_require(path.size() >= 2, "Expected a valid runtime path to reward target node %d." % target_node_id)
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
	for overlay_root_name in ["EventOverlay", "RewardOverlay", "SupportOverlay", "LevelUpOverlay"]:
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
		"Event":
			return "EventOverlay"
		"Reward":
			return "RewardOverlay"
		"SupportInteraction":
			return "SupportOverlay"
		"LevelUp":
			return "LevelUpOverlay"
		_:
			return ""


func _finish_success(test_name: String) -> void:
	if _is_finishing:
		return
	_is_finishing = true
	var process_frame_handler := Callable(self, "_on_process_frame")
	if process_frame.is_connected(process_frame_handler):
		process_frame.disconnect(process_frame_handler)
	print("%s: all assertions passed" % test_name)
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _fail(message: String) -> void:
	push_error(message)
	print(message)
	quit(1)
