# Layer: Tests
extends SceneTree
class_name TestSaveFileRoundtrip

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")
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
var _saved_level_up_offer_id: String = ""
var _is_finishing: bool = false


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
				run_state.inventory_state.set_left_hand_instance({
					"definition_id": "weathered_buckler",
					"inventory_family": "shield",
					"attachment_definition_id": "reinforced_rim_lining",
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
				var inventory_snapshot: Dictionary = run_state.inventory_state.to_save_dict()
				var next_slot_id: int = int(inventory_snapshot.get("inventory_next_slot_id", 1))
				var backpack_slots: Array = inventory_snapshot.get("backpack_slots", []).duplicate(true)
				backpack_slots.append({
					"slot_id": next_slot_id,
					"inventory_family": "quest_item",
					"definition_id": "supply_bundle",
				})
				inventory_snapshot["backpack_slots"] = backpack_slots
				inventory_snapshot["inventory_next_slot_id"] = next_slot_id + 1
				run_state.inventory_state.load_from_flat_save_dict(inventory_snapshot)
				var side_mission_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
				_require(side_mission_node_id >= 0, "Expected a hamlet node before file-backed save coverage.")
				var side_mission_target_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "combat")
				_require(side_mission_target_node_id >= 0, "Expected a combat node for hamlet save coverage.")
				run_state.map_runtime_state.save_side_mission_node_runtime_state(side_mission_node_id, {
					"support_type": "hamlet",
					"mission_definition_id": "trail_contract_hunt",
					"mission_status": "accepted",
					"target_node_id": side_mission_target_node_id,
					"target_enemy_definition_id": "barbed_hunter",
					"reward_offers": [
						{
							"offer_id": "claim_bandit_hatchet",
							"effect_type": "grant_item",
							"inventory_family": "weapon",
							"definition_id": "bandit_hatchet",
							"available": true,
						},
						{
							"offer_id": "claim_trailhook_bandolier",
							"effect_type": "grant_item",
							"inventory_family": "belt",
							"definition_id": "trailhook_bandolier",
							"available": true,
						},
					],
				})
				var carried_consumable_slot_id: int = int(run_state.inventory_state.consumable_slots[0].get("slot_id", -1))
				var reorder_result: Dictionary = _get_bootstrap().call("move_inventory_slot", carried_consumable_slot_id, 1)
				_require(bool(reorder_result.get("ok", false)), "Expected backpack reorder to succeed before file-backed save.")
				var save_shape_preview: Dictionary = run_state.to_save_dict()
				_require(save_shape_preview.has("backpack_slots"), "Expected inventory saves to serialize backpack_slots.")
				_require(save_shape_preview.has("equipped_right_hand_slot"), "Expected inventory saves to serialize equipped right-hand slot.")
				_require(save_shape_preview.has("equipped_left_hand_slot"), "Expected inventory saves to serialize equipped left-hand slot.")
				_require(save_shape_preview.has("equipped_armor_slot"), "Expected inventory saves to serialize equipped armor slot.")
				_require(save_shape_preview.has("equipped_belt_slot"), "Expected inventory saves to serialize equipped belt slot.")
				_require(save_shape_preview.has("character_perk_state"), "Expected progression saves to serialize character perk state.")
				_require(save_shape_preview.has("side_mission_node_states"), "Expected file-backed save shape to preserve the compatibility side_mission_node_states key.")
				_require((save_shape_preview.get("backpack_slots", []) as Array).size() == 2, "Expected backpack save shape to keep only the carried consumable and quest cargo in backpack_slots.")
				_require(int((save_shape_preview.get("equipped_right_hand_slot", {}) as Dictionary).get("slot_id", -1)) > 0, "Expected inventory save shape to store the equipped right-hand slot.")
				_require(String((save_shape_preview.get("equipped_left_hand_slot", {}) as Dictionary).get("inventory_family", "")) == "shield", "Expected inventory save shape to preserve shield left-hand family truth.")
				_require(String((save_shape_preview.get("equipped_left_hand_slot", {}) as Dictionary).get("attachment_definition_id", "")) == "reinforced_rim_lining", "Expected inventory save shape to preserve attached shield-mod state on the left-hand shield.")
				_require(int((save_shape_preview.get("equipped_armor_slot", {}) as Dictionary).get("slot_id", -1)) > 0, "Expected inventory save shape to store the equipped armor slot.")
				_require(int((save_shape_preview.get("equipped_belt_slot", {}) as Dictionary).get("slot_id", -1)) > 0, "Expected inventory save shape to store the equipped belt slot.")
				var has_saved_quest_item: bool = false
				for entry_variant in save_shape_preview.get("backpack_slots", []):
					if typeof(entry_variant) != TYPE_DICTIONARY:
						continue
					if String((entry_variant as Dictionary).get("inventory_family", "")) != "quest_item":
						continue
					has_saved_quest_item = true
					break
				_require(has_saved_quest_item, "Expected inventory save shape to preserve quest-item backpack family entries.")
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
				_require(String(restored_run_state.inventory_state.left_hand_instance.get("definition_id", "")) == "weathered_buckler", "Expected file-backed load to restore the equipped left-hand slot.")
				_require(String(restored_run_state.inventory_state.left_hand_instance.get("inventory_family", "")) == "shield", "Expected file-backed load to preserve shield left-hand family truth.")
				_require(String(restored_run_state.inventory_state.left_hand_instance.get("attachment_definition_id", "")) == "reinforced_rim_lining", "Expected file-backed load to restore attached shield-mod state.")
				_require(String(restored_run_state.inventory_state.armor_instance.get("definition_id", "")) == "watcher_mail", "Expected file-backed load to restore the equipped armor slot.")
				_require(int(restored_run_state.inventory_state.armor_instance.get("upgrade_level", 0)) == 1, "Expected file-backed load to restore armor forge level.")
				_require(String(restored_run_state.inventory_state.belt_instance.get("definition_id", "")) == "trailhook_bandolier", "Expected file-backed load to restore the equipped belt slot.")
				_require(restored_run_state.inventory_state.consumable_slots.size() == 1, "Expected file-backed load to restore consumable slots.")
				_require(int(restored_run_state.inventory_state.consumable_slots[0].get("current_stack", 0)) == 2, "Expected file-backed load to restore consumable stack count.")
				_require(restored_run_state.inventory_state.get_total_capacity() == 7, "Expected equipped belt to restore the +2 backpack bonus after file-backed load.")
				_require(String(restored_run_state.inventory_state.inventory_slots[1].get("inventory_family", "")) == InventoryState.INVENTORY_FAMILY_QUEST_ITEM, "Expected file-backed load to preserve quest-item backpack family truth.")
				_require(String(restored_run_state.inventory_state.inventory_slots[0].get("inventory_family", "")) == InventoryState.INVENTORY_FAMILY_CONSUMABLE, "Expected file-backed load to preserve backpack slot order after drag-style reorder.")
				var restored_side_mission_state: Dictionary = restored_run_state.map_runtime_state.get_side_mission_node_runtime_state(_find_node_id_by_family(restored_run_state.map_runtime_state, "hamlet"))
				_require(String(restored_side_mission_state.get("mission_status", "")) == "accepted", "Expected file-backed load to restore accepted hamlet runtime state.")
				_require(String(restored_side_mission_state.get("target_enemy_definition_id", "")) == "barbed_hunter", "Expected file-backed load to restore the marked hamlet contract enemy.")
				_exhaust_roadside_quota(restored_run_state)
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
				_saved_level_up_offer_id = String(level_up_state.offers[0].get("offer_id", ""))
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
				_require(run_state_after_level_restore.character_perk_state.get_owned_perk_ids().size() == 1, "Expected a learned character perk after restored level-up claim.")
				_require(run_state_after_level_restore.character_perk_state.has_perk(_saved_level_up_offer_id), "Expected the restored level-up claim to learn the saved perk choice.")
				var learned_perk_leaked_to_inventory: bool = false
				for passive_slot in run_state_after_level_restore.inventory_state.passive_slots:
					if String(passive_slot.get("definition_id", "")) == _saved_level_up_offer_id:
						learned_perk_leaked_to_inventory = true
						break
				_require(not learned_perk_leaked_to_inventory, "Expected learned character perks to stay out of passive-item backpack inventory.")
				var delete_result: Dictionary = _get_bootstrap().call("delete_save_game", SAVE_PATH)
				_require(bool(delete_result.get("ok", false)), "Expected save file deletion to succeed after the test.")
				_require(not bool(_get_bootstrap().call("has_save_game", SAVE_PATH)), "Expected test save file to be deleted.")
				await _finish_success("test_save_file_roundtrip")

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
	var fallback_family: String = _resolve_node_family_for_route_label(label_fragment)
	if not fallback_family.is_empty():
		var run_state: RunState = _get_run_state()
		var target_node_id: int = _find_unresolved_node_id_by_family(run_state.map_runtime_state, fallback_family) if run_state != null else -1
		if target_node_id < 0 and run_state != null:
			target_node_id = _find_any_node_id_by_family(run_state.map_runtime_state, fallback_family)
		if target_node_id >= 0:
			_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, target_node_id)
			current_scene.call("_refresh_ui")
			current_scene.call("_move_to_node", target_node_id)
			return
	_fail("Expected a visible enabled route button containing %s." % label_fragment)


func _press_reward_offer_by_effect_type(effect_type: String) -> void:
	var reward_state: RefCounted = _get_reward_state()
	_require(reward_state != null, "Expected RewardState before selecting a reward offer.")
	for index in range(reward_state.offers.size()):
		if String(reward_state.offers[index].get("effect_type", "")) == effect_type:
			_press("Margin/VBox/OffersShell/VBox/CardsRow/%s/VBox/%s" % [_reward_card_name_for_index(index), _reward_button_name_for_index(index)])
			return
	_fail("Expected reward offer with effect_type %s." % effect_type)


func _press_reward_offer_by_index(index: int) -> void:
	_press("Margin/VBox/OffersShell/VBox/CardsRow/%s/VBox/%s" % [_reward_card_name_for_index(index), _reward_button_name_for_index(index)])


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


func _exhaust_roadside_quota(run_state: RunState) -> void:
	_require(run_state != null, "Expected RunState before suppressing roadside interruptions for save roundtrip routing.")
	run_state.map_runtime_state.roadside_encounters_this_stage = run_state.map_runtime_state.MAX_ROADSIDE_ENCOUNTERS_PER_STAGE


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


func _resolve_node_family_for_route_label(label_fragment: String) -> String:
	match label_fragment:
		"Reward":
			return "reward"
		_:
			return ""


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


func _find_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == node_family:
			return int(node_snapshot.get("node_id", -1))
	return -1


func _fail(message: String) -> void:
	push_error(message)
	print(message)
	quit(1)
