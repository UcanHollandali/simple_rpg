# Layer: Tests
extends SceneTree
class_name TestSaveFileRoundtrip

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")
const LEVEL_UP_CHOICE_A_BUTTON_PATH := "Margin/VBox/ChoicesRow/ChoiceAButton"
const ROUTE_BUTTON_NODE_NAMES: PackedStringArray = [
	"CombatNodeButton",
	"RewardNodeButton",
	"RestNodeButton",
	"MerchantNodeButton",
	"BlacksmithNodeButton",
	"BossNodeButton",
]

const SAVE_PATH: String = "user://test_save_file_roundtrip.json"

var _phase: int = 0
var _phase_frame_count: int = 0
var _saved_reward_effect_type: String = ""
var _saved_reward_amount: int = 0


func _init() -> void:
	print("test_save_file_roundtrip: setup")
	_ensure_autoload_like_nodes()
	var delete_result: Dictionary = _get_bootstrap().call("delete_save_game", SAVE_PATH)
	_require(bool(delete_result.get("ok", false)), "Expected stale save cleanup to succeed before the test starts.")
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
				_get_bootstrap().call("get_flow_manager").call("restore_state", FlowStateScript.Type.MAP_EXPLORE)
				_get_scene_router().call("route_to_state_for_restore", FlowStateScript.Type.MAP_EXPLORE)
				_advance_phase(1)
		1:
			if _is_scene("MapExplore"):
				var run_state: RunState = _get_run_state()
				_require(run_state != null, "Expected RunState on MapExplore.")
				run_state.configure_run_seed(99)
				run_state.player_hp = 43
				run_state.hunger = 9
				run_state.gold = 17
				run_state.inventory_state.weapon_instance["current_durability"] = 13
				run_state.inventory_state.weapon_instance["upgrade_level"] = 2
				run_state.inventory_state.set_armor_instance({
					"definition_id": "watcher_mail",
					"upgrade_level": 1,
				})
				run_state.inventory_state.set_belt_instance({
					"definition_id": "trailhook_bandolier",
				})
				run_state.inventory_state.set_consumable_slots([
					{
						"definition_id": "minor_heal_potion",
						"current_stack": 2,
					},
				])
				var side_mission_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "side_mission")
				_require(side_mission_node_id >= 0, "Expected a side-mission node before file-backed save coverage.")
				var side_mission_target_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "combat")
				_require(side_mission_target_node_id >= 0, "Expected a combat node for side-mission save coverage.")
				run_state.map_runtime_state.save_side_mission_node_runtime_state(side_mission_node_id, {
					"support_type": "side_mission",
					"mission_definition_id": "trail_contract_hunt",
					"mission_status": "accepted",
					"target_node_id": side_mission_target_node_id,
					"target_enemy_definition_id": "barbed_hunter",
					"reward_offers": [
						{
							"offer_id": "claim_emberhook_blade",
							"inventory_family": "weapon",
							"definition_id": "emberhook_blade",
							"available": true,
						},
						{
							"offer_id": "claim_trailwarden_cloak",
							"inventory_family": "armor",
							"definition_id": "trailwarden_cloak",
							"available": true,
						},
					],
				})
				var carried_consumable_slot_id: int = int(run_state.inventory_state.consumable_slots[0].get("slot_id", -1))
				var reorder_result: Dictionary = _get_bootstrap().call("move_inventory_slot", carried_consumable_slot_id, 1)
				_require(bool(reorder_result.get("ok", false)), "Expected shared inventory reorder to succeed before file-backed save.")
				var save_shape_preview: Dictionary = run_state.to_save_dict()
				_require(save_shape_preview.has("inventory_slots"), "Expected shared inventory saves to serialize inventory_slots.")
				_require(save_shape_preview.has("side_mission_node_states"), "Expected file-backed shared save shape to serialize side_mission_node_states.")
				_require((save_shape_preview.get("inventory_slots", []) as Array).size() == 4, "Expected shared inventory save shape to capture weapon, armor, belt, and consumable slots.")
				_require(int(save_shape_preview.get("active_weapon_slot_id", -1)) > 0, "Expected shared inventory save shape to store the active weapon slot id.")
				_require(int(save_shape_preview.get("active_armor_slot_id", -1)) > 0, "Expected shared inventory save shape to store the active armor slot id.")
				_require(int(save_shape_preview.get("active_belt_slot_id", -1)) > 0, "Expected shared inventory save shape to store the active belt slot id.")
				var save_result: Dictionary = _get_bootstrap().call("save_game", SAVE_PATH)
				_require(bool(save_result.get("ok", false)), "Expected file-backed map save to succeed.")
				_require(bool(_get_bootstrap().call("has_save_game", SAVE_PATH)), "Expected save file to exist after map save.")
				run_state.player_hp = 1
				run_state.hunger = 0
				run_state.gold = 0
				run_state.inventory_state.weapon_instance["current_durability"] = 0
				run_state.inventory_state.set_armor_instance({})
				run_state.inventory_state.set_belt_instance({})
				run_state.inventory_state.set_consumable_slots([])
				var load_result: Dictionary = _get_bootstrap().call("load_game", SAVE_PATH)
				_require(bool(load_result.get("ok", false)), "Expected file-backed map load to succeed.")
				_advance_phase(2)
		2:
			if _is_scene("MapExplore"):
				var restored_run_state: RunState = _get_run_state()
				_require(restored_run_state.player_hp == 43, "Expected file-backed load to restore map HP.")
				_require(restored_run_state.hunger == 9, "Expected file-backed load to restore map hunger.")
				_require(restored_run_state.gold == 17, "Expected file-backed load to restore map gold.")
				_require(int(restored_run_state.inventory_state.weapon_instance.get("current_durability", 0)) == 13, "Expected file-backed load to restore weapon durability.")
				_require(int(restored_run_state.inventory_state.weapon_instance.get("upgrade_level", 0)) == 2, "Expected file-backed load to restore weapon forge level.")
				_require(String(restored_run_state.inventory_state.armor_instance.get("definition_id", "")) == "watcher_mail", "Expected file-backed load to restore the equipped armor slot.")
				_require(int(restored_run_state.inventory_state.armor_instance.get("upgrade_level", 0)) == 1, "Expected file-backed load to restore armor forge level.")
				_require(String(restored_run_state.inventory_state.belt_instance.get("definition_id", "")) == "trailhook_bandolier", "Expected file-backed load to restore the equipped belt slot.")
				_require(restored_run_state.inventory_state.consumable_slots.size() == 1, "Expected file-backed load to restore consumable slots.")
				_require(int(restored_run_state.inventory_state.consumable_slots[0].get("current_stack", 0)) == 2, "Expected file-backed load to restore consumable stack count.")
				_require(restored_run_state.inventory_state.get_total_capacity() == 7, "Expected equipped belt to restore the +2 shared inventory bonus after file-backed load.")
				_require(String(restored_run_state.inventory_state.inventory_slots[1].get("inventory_family", "")) == InventoryState.INVENTORY_FAMILY_CONSUMABLE, "Expected file-backed load to preserve shared inventory slot order after drag-style reorder.")
				var restored_side_mission_state: Dictionary = restored_run_state.map_runtime_state.get_side_mission_node_runtime_state(_find_node_id_by_family(restored_run_state.map_runtime_state, "side_mission"))
				_require(String(restored_side_mission_state.get("mission_status", "")) == "accepted", "Expected file-backed load to restore accepted side-mission runtime state.")
				_require(String(restored_side_mission_state.get("target_enemy_definition_id", "")) == "barbed_hunter", "Expected file-backed load to restore the marked contract enemy.")
				_press_map_route_containing("Reward")
				_advance_phase(3)
		3:
			if _is_scene("Reward"):
				var reward_state: RefCounted = _get_reward_state()
				_require(reward_state != null, "Expected RewardState during reward-node save test.")
				_require(reward_state.source_context == RewardStateScript.SOURCE_REWARD_NODE, "Expected reward-node source context before file-backed save.")
				_saved_reward_effect_type = String(reward_state.offers[0].get("effect_type", ""))
				_saved_reward_amount = int(reward_state.offers[0].get("amount", 0))
				var save_result: Dictionary = _get_bootstrap().call("save_game", SAVE_PATH)
				_require(bool(save_result.get("ok", false)), "Expected file-backed reward save to succeed.")
				_press_reward_offer_by_index(0)
				_advance_phase(4)
		4:
			if _is_scene("MapExplore"):
				var load_result: Dictionary = _get_bootstrap().call("load_game", SAVE_PATH)
				_require(bool(load_result.get("ok", false)), "Expected file-backed reward load to succeed.")
				_advance_phase(5)
		5:
			if _is_scene("Reward"):
				var restored_reward_state: RefCounted = _get_reward_state()
				_require(restored_reward_state != null, "Expected RewardState after file-backed reward load.")
				_require(restored_reward_state.source_context == RewardStateScript.SOURCE_REWARD_NODE, "Expected restored reward source to remain reward_node.")
				_require(restored_reward_state.offers.size() == 2, "Expected reward-node offers to survive file-backed load.")
				_require(String(restored_reward_state.offers[0].get("effect_type", "")) == _saved_reward_effect_type, "Expected restored reward-node first offer to survive file-backed load.")
				_press_reward_offer_by_index(0)
				_advance_phase(6)
		6:
			if _is_scene("MapExplore"):
				var run_state_after_reward_restore: RunState = _get_run_state()
				match _saved_reward_effect_type:
					"grant_gold":
						_require(run_state_after_reward_restore.gold == 17 + _saved_reward_amount, "Expected restored reward claim to grant the saved gold amount after file-backed load.")
					"grant_xp":
						_require(run_state_after_reward_restore.xp == _saved_reward_amount, "Expected restored reward claim to grant the saved XP amount after file-backed load.")
					"heal":
						_require(run_state_after_reward_restore.player_hp == min(RunState.DEFAULT_PLAYER_HP, 43 + _saved_reward_amount), "Expected restored reward claim to grant the saved heal amount after file-backed load.")
				run_state_after_reward_restore.xp = 5
				_get_bootstrap().call("get_flow_manager").set("current_state", FlowStateScript.Type.COMBAT)
				_get_bootstrap().call("resolve_combat_result", "victory")
				_advance_phase(7)
		7:
			if _is_scene("Reward"):
				var combat_reward_state: RefCounted = _get_reward_state()
				_require(combat_reward_state != null, "Expected combat reward state before level-up save path.")
				_require(combat_reward_state.source_context == RewardStateScript.SOURCE_COMBAT_VICTORY, "Expected combat-victory reward source.")
				_press_reward_offer_by_index(0)
				_advance_phase(8)
		8:
			if _is_scene("LevelUp"):
				var level_up_state: RefCounted = _get_level_up_state()
				_require(level_up_state != null, "Expected LevelUpState before file-backed save.")
				_require(int(level_up_state.current_level) == 1, "Expected current level to remain 1 before level-up claim.")
				_require(int(level_up_state.target_level) == 2, "Expected target level 2 before level-up claim.")
				var save_result: Dictionary = _get_bootstrap().call("save_game", SAVE_PATH)
				_require(bool(save_result.get("ok", false)), "Expected file-backed level-up save to succeed.")
				_press(LEVEL_UP_CHOICE_A_BUTTON_PATH)
				_advance_phase(9)
		9:
			if _is_scene("MapExplore"):
				var load_result: Dictionary = _get_bootstrap().call("load_game", SAVE_PATH)
				_require(bool(load_result.get("ok", false)), "Expected file-backed level-up load to succeed.")
				_advance_phase(10)
		10:
			if _is_scene("LevelUp"):
				var restored_level_up_state: RefCounted = _get_level_up_state()
				_require(restored_level_up_state != null, "Expected LevelUpState after file-backed load.")
				_require(int(restored_level_up_state.current_level) == 1, "Expected restored current level to remain 1 before claim.")
				_require(int(restored_level_up_state.target_level) == 2, "Expected restored target level to remain 2.")
				_require(restored_level_up_state.offers.size() == 3, "Expected level-up offers to survive file-backed load.")
				_press(LEVEL_UP_CHOICE_A_BUTTON_PATH)
				_advance_phase(11)
		11:
			if _is_scene("MapExplore"):
				var run_state_after_level_restore: RunState = _get_run_state()
				_require(run_state_after_level_restore.current_level == 2, "Expected level-up claim to persist after file-backed restore.")
				_require(run_state_after_level_restore.inventory_state.passive_slots.size() == 1, "Expected passive slot write after restored level-up claim.")
				var delete_result: Dictionary = _get_bootstrap().call("delete_save_game", SAVE_PATH)
				_require(bool(delete_result.get("ok", false)), "Expected save file deletion to succeed after the test.")
				_require(not bool(_get_bootstrap().call("has_save_game", SAVE_PATH)), "Expected test save file to be deleted.")
				print("test_save_file_roundtrip: all assertions passed")
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


func _get_reward_state() -> RefCounted:
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.call("get_reward_state")


func _get_level_up_state() -> RefCounted:
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.call("get_level_up_state")


func _is_scene(expected_name: String) -> bool:
	return current_scene != null and current_scene.name == expected_name


func _press(node_path: String) -> void:
	var button: Button = current_scene.get_node(node_path) as Button
	_require(button != null, "Expected button at %s." % node_path)
	button.emit_signal("pressed")


func _press_map_route_containing(label_fragment: String) -> void:
	for button_name in ROUTE_BUTTON_NODE_NAMES:
		var button: Button = current_scene.get_node_or_null("Margin/VBox/RouteGrid/%s" % button_name) as Button
		if button == null or not button.visible or button.disabled:
			continue
		var route_label: String = button.text if not button.text.is_empty() else button.tooltip_text
		if route_label.contains(label_fragment):
			button.emit_signal("pressed")
			return
	_fail("Expected a visible enabled route button containing %s." % label_fragment)


func _press_reward_offer_by_effect_type(effect_type: String) -> void:
	var reward_state: RefCounted = _get_reward_state()
	_require(reward_state != null, "Expected RewardState before selecting a reward offer.")
	for index in range(reward_state.offers.size()):
		if String(reward_state.offers[index].get("effect_type", "")) == effect_type:
			_press("Margin/VBox/CardsRow/%s/VBox/%s" % [_reward_card_name_for_index(index), _reward_button_name_for_index(index)])
			return
	_fail("Expected reward offer with effect_type %s." % effect_type)


func _press_reward_offer_by_index(index: int) -> void:
	_press("Margin/VBox/CardsRow/%s/VBox/%s" % [_reward_card_name_for_index(index), _reward_button_name_for_index(index)])


func _reward_button_name_for_index(index: int) -> String:
	match index:
		0:
			return "ChoiceAButton"
		1:
			return "ChoiceBButton"
		2:
			return "ChoiceCButton"
		_:
			return ""


func _reward_card_name_for_index(index: int) -> String:
	match index:
		0:
			return "ChoiceACard"
		1:
			return "ChoiceBCard"
		2:
			return "ChoiceCCard"
		_:
			return ""


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


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _find_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == node_family:
			return int(node_snapshot.get("node_id", -1))
	return -1


func _fail(message: String) -> void:
	push_error(message)
	print(message)
	quit(1)
