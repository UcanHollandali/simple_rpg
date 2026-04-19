# Layer: Tests
extends SceneTree
class_name TestButtonTour

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const AudioPreferencesScript = preload("res://Game/UI/audio_preferences.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")
const ROUTE_BUTTON_NODE_NAMES: PackedStringArray = [
	"CombatNodeButton",
	"RewardNodeButton",
	"RestNodeButton",
	"MerchantNodeButton",
	"BlacksmithNodeButton",
	"BossNodeButton",
]

const MAIN_MENU_START_BUTTON_PATH := "Margin/VBox/ActionPanel/ActionVBox/StartRunButton"
const MAP_SETTINGS_LAUNCHER_BUTTON_PATH := "Margin/VBox/TopRow/SettingsMenuAnchor/SettingsButton"
const MAP_SETTINGS_CLOSE_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/CloseButton"
const MAP_SETTINGS_MUSIC_BUTTON_PATH := "SafeMenuOverlay/MenuLayer/PanelHolder/PanelRow/MenuPanel/VBox/ActionsVBox/MusicToggleButton"
const SUPPORT_ACTION_A_BUTTON_PATH := "Margin/VBox/ActionsRow/ActionAButton"
const SUPPORT_ACTION_B_BUTTON_PATH := "Margin/VBox/ActionsRow/ActionBButton"
const SUPPORT_ACTION_C_BUTTON_PATH := "Margin/VBox/ActionsRow/ActionCButton"
const SUPPORT_LEAVE_BUTTON_PATH := "Margin/VBox/FooterRow/LeaveButton"
const EVENT_CHOICE_B_BUTTON_PATH := "Margin/VBox/OffersShell/VBox/CardsRow/ChoiceBCard/VBox/ChoiceBButton"
const COMBAT_ATTACK_BUTTON_PATH := "Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackButton"
const COMBAT_DEFEND_BUTTON_PATH := "Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionButton"
const COMBAT_RIGHT_HAND_CARD_PATH := "Margin/VBox/SecondaryScroll/SecondaryScrollContent/QuickItemSection/EquipmentCard/EquipmentCardsFlow/InventorySlotRIGHTHANDCard"
const COMBAT_CONSUMABLE_3_CARD_PATH := "Margin/VBox/SecondaryScroll/SecondaryScrollContent/QuickItemSection/InventoryCard/InventoryCardsFlow/InventorySlot3Card"
const REWARD_CHOICE_C_BUTTON_PATH := "Margin/VBox/OffersShell/VBox/CardsRow/ChoiceCCard/VBox/ChoiceCButton"
const LEVEL_UP_CHOICE_B_BUTTON_PATH := "Margin/VBox/ChoicesRow/ChoiceBButton"
const RUN_END_RETURN_BUTTON_PATH := "Margin/Center/ContentCard/VBox/ReturnButton"
const PHASE_TIMEOUT_MS := 8000

var _phase: int = 0
var _phase_started_at_ms: int = 0
var _combat_attack_count: int = 0
var _combat_hp_before_use_item: int = 0
var _combat_hunger_before_use_item: int = 0
var _combat_durability_before_use_item: int = 0
var _selected_consumable_definition_before_use_item: String = ""
var _event_gold_before: int = 0
var _event_hp_before: int = 0
var _event_hunger_before: int = 0
var _event_xp_before: int = 0
var _event_inventory_slot_count_before: int = 0
var _map_inventory_cycle_step: int = 0
var _combat_inventory_cycle_step: int = 0
var _map_inventory_current_node_before_equipment: int = -1
var _map_inventory_signature_before_equipment: String = ""
var _map_board_visual_signature_before_equipment: String = ""
var _map_inventory_snapshot_before_overflow_prompt: Dictionary = {}
var _map_weapon_slot_id_before_equipment: int = -1
var _map_weapon_definition_id_before_equipment: String = ""
var _combat_locked_equipment_signature_before_click: String = ""
var _combat_log_before_locked_equipment_click: String = ""
var _is_finishing: bool = false


func _init() -> void:
	print("test_button_tour: setup")
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
				var run_state: RunState = _get_run_state()
				_require(run_state != null, "Expected RunState on first MapExplore.")
				run_state.configure_run_seed(1)
				_exhaust_roadside_quota(run_state)
				run_state.player_hp = 40
				run_state.hunger = 14
				run_state.gold = 40
				run_state.xp = 9
				run_state.inventory_state.weapon_instance["current_durability"] = 12
				run_state.inventory_state.set_consumable_slots([
					{
						"definition_id": "minor_heal_potion",
						"current_stack": 2,
					},
				])
				current_scene.call("_refresh_ui")
				_press(MAP_SETTINGS_LAUNCHER_BUTTON_PATH)
				_advance_phase(2)
		2:
			if _is_scene("MapExplore"):
				var music_button: Button = current_scene.get_node(MAP_SETTINGS_MUSIC_BUTTON_PATH) as Button
				_require(music_button != null, "Expected music button in settings drawer.")
				_require(music_button.text == "Music: On", "Expected music toggle to start on in full-tour test.")
				music_button.emit_signal("pressed")
				_advance_phase(3)
		3:
			if _is_scene("MapExplore"):
				var music_button: Button = current_scene.get_node(MAP_SETTINGS_MUSIC_BUTTON_PATH) as Button
				_require(not AudioPreferencesScript.is_music_enabled(), "Expected first settings toggle to mute music.")
				_require(music_button.text == "Music: Off", "Expected muted settings label after first toggle.")
				music_button.emit_signal("pressed")
				_advance_phase(4)
		4:
			if _is_scene("MapExplore"):
				_require(AudioPreferencesScript.is_music_enabled(), "Expected second settings toggle to restore music.")
				_press(MAP_SETTINGS_CLOSE_BUTTON_PATH)
				_advance_phase(5)
		5:
			if _is_scene("MapExplore"):
				var run_state_on_map: RunState = _get_run_state()
				_require(run_state_on_map != null, "Expected RunState before exercising map equip/unequip flow.")
				match _map_inventory_cycle_step:
					0:
						_map_inventory_current_node_before_equipment = int(run_state_on_map.map_runtime_state.current_node_id)
						_map_inventory_signature_before_equipment = _build_map_signature(run_state_on_map)
						_map_board_visual_signature_before_equipment = _build_route_board_visual_signature(current_scene)
						_map_weapon_slot_id_before_equipment = int(run_state_on_map.inventory_state.weapon_instance.get("slot_id", -1))
						_map_weapon_definition_id_before_equipment = String(run_state_on_map.inventory_state.weapon_instance.get("definition_id", ""))
						_require(_map_weapon_slot_id_before_equipment > 0, "Expected starter weapon slot id before map equip/unequip cycle.")
						_require(not _map_weapon_definition_id_before_equipment.is_empty(), "Expected starter weapon definition before map equip/unequip cycle.")
						_click_map_inventory_card("Margin/VBox/InventorySection/EquipmentCard/EquipmentCardsFlow/InventorySlotRIGHTHANDCard")
						_map_inventory_cycle_step = 1
					1:
						_require(_current_state() == FlowStateScript.Type.MAP_EXPLORE, "Expected map equip/unequip to keep the flow in MAP_EXPLORE.")
						_require(int(run_state_on_map.map_runtime_state.current_node_id) == _map_inventory_current_node_before_equipment, "Expected map equip/unequip not to change the current node.")
						_require(_build_map_signature(run_state_on_map) == _map_inventory_signature_before_equipment, "Expected map equip/unequip not to rebuild or reset the active map.")
						_require(_build_route_board_visual_signature(current_scene) == _map_board_visual_signature_before_equipment, "Expected map equip/unequip not to re-layout the visible board geometry.")
						_require(run_state_on_map.inventory_state.weapon_instance.is_empty(), "Expected clicking the equipped right-hand card to unequip the weapon on MapExplore.")
						_require(_inventory_contains_slot_id(run_state_on_map, _map_weapon_slot_id_before_equipment), "Expected unequipped weapon slot to move into the backpack instead of disappearing.")
						_require_inventory_card_action_copy("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow/InventorySlot2Card", "Tap to equip")
						_click_map_inventory_card("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow/InventorySlot2Card")
						_map_inventory_cycle_step = 2
					2:
						_require(_current_state() == FlowStateScript.Type.MAP_EXPLORE, "Expected re-equipping on MapExplore to keep the flow in MAP_EXPLORE.")
						_require(int(run_state_on_map.map_runtime_state.current_node_id) == _map_inventory_current_node_before_equipment, "Expected re-equipping not to change the current node.")
						_require(_build_map_signature(run_state_on_map) == _map_inventory_signature_before_equipment, "Expected re-equipping not to rebuild or reset the active map.")
						_require(_build_route_board_visual_signature(current_scene) == _map_board_visual_signature_before_equipment, "Expected re-equipping not to re-layout the visible board geometry.")
						_require(String(run_state_on_map.inventory_state.weapon_instance.get("definition_id", "")) == _map_weapon_definition_id_before_equipment, "Expected map re-equip to restore the original weapon definition.")
						_require(int(run_state_on_map.inventory_state.weapon_instance.get("slot_id", -1)) == _map_weapon_slot_id_before_equipment, "Expected map re-equip to restore the original weapon slot id.")
						_require(not _inventory_contains_slot_id(run_state_on_map, _map_weapon_slot_id_before_equipment), "Expected re-equipped weapon slot to leave the backpack.")
						_map_inventory_snapshot_before_overflow_prompt = run_state_on_map.inventory_state.to_save_dict()
						_fill_backpack_to_capacity(run_state_on_map)
						current_scene.call("_refresh_ui")
						_click_map_inventory_card("Margin/VBox/InventorySection/EquipmentCard/EquipmentCardsFlow/InventorySlotRIGHTHANDCard")
						_map_inventory_cycle_step = 3
					3:
						_require(_current_state() == FlowStateScript.Type.MAP_EXPLORE, "Expected full-backpack unequip prompt to keep the flow in MAP_EXPLORE.")
						var overflow_prompt: Control = _get_map_inventory_overflow_prompt()
						_require(overflow_prompt != null and overflow_prompt.visible, "Expected full-backpack unequip on MapExplore to open the inventory overflow prompt.")
						_press_map_overflow_prompt_first_discard()
						_map_inventory_cycle_step = 4
					4:
						_require(_current_state() == FlowStateScript.Type.MAP_EXPLORE, "Expected discard-resolved unequip to stay on MapExplore.")
						_require(run_state_on_map.inventory_state.weapon_instance.is_empty(), "Expected discard-resolved unequip to clear the active weapon lane.")
						_require(_inventory_contains_slot_id(run_state_on_map, _map_weapon_slot_id_before_equipment), "Expected discard-resolved unequip to move the active weapon into the backpack.")
						_click_map_inventory_card_by_slot_id(_map_weapon_slot_id_before_equipment)
						_map_inventory_cycle_step = 5
					5:
						_require(_current_state() == FlowStateScript.Type.MAP_EXPLORE, "Expected re-equipping after discard-resolved unequip to keep the flow on MapExplore.")
						_require(String(run_state_on_map.inventory_state.weapon_instance.get("definition_id", "")) == _map_weapon_definition_id_before_equipment, "Expected the original weapon to re-equip after the discard-resolved unequip path.")
						run_state_on_map.inventory_state.load_from_flat_save_dict(_map_inventory_snapshot_before_overflow_prompt)
						current_scene.call("_refresh_ui")
						_prepare_map_adjacent_to_family("rest")
						_press_map_route_containing("Rest")
						_advance_phase(6)
		6:
			if _is_scene("SupportInteraction"):
				_press(SUPPORT_ACTION_A_BUTTON_PATH)
				_advance_phase(7)
		7:
			if _is_scene("MapExplore"):
				var run_state_after_rest: RunState = _get_run_state()
				_require(run_state_after_rest.player_hp == 50, "Expected rest button A to heal 10 HP.")
				_require(run_state_after_rest.hunger == 10, "Expected rest button A to spend 3 hunger after map move cost.")
				_prepare_map_adjacent_to_family("merchant")
				_press_map_route_containing("Merchant")
				_advance_phase(8)
		8:
			if _is_scene("SupportInteraction"):
				var merchant_state: RefCounted = _get_support_state()
				_require(merchant_state != null, "Expected merchant support state.")
				_require(String(merchant_state.support_type) == "merchant", "Expected merchant support type.")
				_require(merchant_state.offers.size() == 3, "Expected all three merchant buttons to be available.")
				_press(SUPPORT_ACTION_A_BUTTON_PATH)
				_advance_phase(9)
		9:
			if _is_scene("SupportInteraction"):
				var run_state_after_action_a: RunState = _get_run_state()
				_require(run_state_after_action_a.gold == 34, "Expected merchant action A to cost 6 gold.")
				_require(run_state_after_action_a.inventory_state.consumable_slots.size() == 2, "Expected merchant action A to add a consumable slot.")
				_press(SUPPORT_ACTION_B_BUTTON_PATH)
				_advance_phase(10)
		10:
			if _is_scene("SupportInteraction"):
				var run_state_after_action_b: RunState = _get_run_state()
				_require(run_state_after_action_b.gold == 26, "Expected merchant action B to cost 8 gold.")
				_require(run_state_after_action_b.inventory_state.consumable_slots.size() == 3, "Expected merchant action B to add the second merchant consumable.")
				_press(SUPPORT_ACTION_C_BUTTON_PATH)
				_advance_phase(11)
		11:
			if _is_scene("MapExplore"):
				var run_state_after_action_c: RunState = _get_run_state()
				_require(run_state_after_action_c.gold == 13, "Expected merchant action C to cost 13 gold.")
				_require(String(run_state_after_action_c.inventory_state.left_hand_instance.get("definition_id", "")) != "watchman_shield", "Expected merchant action C not to auto-equip the purchased shield.")
				var carried_watchman_shield_found: bool = false
				for slot in run_state_after_action_c.inventory_state.inventory_slots:
					if String(slot.get("inventory_family", "")) != InventoryState.INVENTORY_FAMILY_SHIELD:
						continue
					if String(slot.get("definition_id", "")) != "watchman_shield":
						continue
					carried_watchman_shield_found = true
					break
				_require(carried_watchman_shield_found, "Expected merchant action C to add Watchman Shield as a carried shield.")
				_advance_phase(12)
		12:
			if _is_scene("MapExplore"):
				var run_state_before_event: RunState = _get_run_state()
				run_state_before_event.configure_run_seed(1)
				_exhaust_roadside_quota(run_state_before_event)
				_event_gold_before = run_state_before_event.gold
				_event_hp_before = run_state_before_event.player_hp
				_event_hunger_before = run_state_before_event.hunger
				_event_xp_before = run_state_before_event.xp
				_event_inventory_slot_count_before = run_state_before_event.inventory_state.inventory_slots.size()
				_prepare_map_adjacent_to_family("event")
				_press_map_route_containing("Trail Event")
				_advance_phase(13)
		13:
			if _is_scene("Event"):
				_press(EVENT_CHOICE_B_BUTTON_PATH)
				_advance_phase(14)
		14:
			if _is_scene("MapExplore"):
				var run_state_after_event: RunState = _get_run_state()
				var event_outcome_changed_state: bool = (
					run_state_after_event.gold != _event_gold_before
					or run_state_after_event.player_hp != _event_hp_before
					or run_state_after_event.hunger != _event_hunger_before
					or run_state_after_event.xp != _event_xp_before
					or run_state_after_event.inventory_state.inventory_slots.size() != _event_inventory_slot_count_before
				)
				_require(event_outcome_changed_state, "Expected event choice B to resolve into a real authored outcome before returning to MapExplore.")
				run_state_after_event.player_hp = 30
				run_state_after_event.hunger = 16
				run_state_after_event.xp = 9
				current_scene.call("_refresh_ui")
				_prepare_map_adjacent_to_family("combat")
				_press_map_route_containing("Combat")
				_advance_phase(15)
		15:
			if _is_scene("Combat"):
				var combat_flow = current_scene.get("_combat_flow")
				_require(combat_flow != null, "Expected combat flow owner on Combat scene.")
				match _combat_inventory_cycle_step:
					0:
						_require_inventory_card_action_copy(COMBAT_RIGHT_HAND_CARD_PATH, "Locked during combat")
						_require_combat_inventory_card_density()
						_combat_locked_equipment_signature_before_click = _build_combat_inventory_signature(combat_flow)
						_combat_log_before_locked_equipment_click = _combat_log_text()
						_click_combat_card(COMBAT_RIGHT_HAND_CARD_PATH)
						_combat_inventory_cycle_step = 1
					1:
						_require(
							_build_combat_inventory_signature(combat_flow) == _combat_locked_equipment_signature_before_click,
							"Expected combat equipment clicks on locked gear to leave combat inventory state unchanged."
						)
						_require(
							_combat_log_text() == _combat_log_before_locked_equipment_click,
							"Expected combat equipment clicks on locked gear not to append extra combat-log lines."
						)
						_combat_hp_before_use_item = int(combat_flow.combat_state.player_hp)
						_combat_hunger_before_use_item = int(combat_flow.combat_state.player_hunger)
						_combat_durability_before_use_item = int(combat_flow.combat_state.weapon_instance.get("current_durability", 0))
						var consumable_card: PanelContainer = current_scene.get_node(COMBAT_CONSUMABLE_3_CARD_PATH) as PanelContainer
						_require(consumable_card != null, "Expected the third combat consumable card after the merchant setup path.")
						_require(combat_flow.combat_state.consumable_slots.size() >= 3, "Expected merchant setup path to leave at least three combat-usable consumable slots.")
						_selected_consumable_definition_before_use_item = String(combat_flow.combat_state.consumable_slots[2].get("definition_id", ""))
						_require(not _selected_consumable_definition_before_use_item.is_empty(), "Expected the third combat consumable slot to resolve to a live consumable definition.")
						_click_combat_card(COMBAT_CONSUMABLE_3_CARD_PATH)
						_advance_phase(16)
		16:
			if _is_scene("Combat"):
				var combat_flow = current_scene.get("_combat_flow")
				_require(combat_flow != null, "Expected combat flow owner after use-item.")
				var item_click_applied_effect: bool = (
					combat_flow.combat_state.player_hp > _combat_hp_before_use_item
					or combat_flow.combat_state.player_hunger > _combat_hunger_before_use_item
					or int(combat_flow.combat_state.weapon_instance.get("current_durability", 0)) > _combat_durability_before_use_item
				)
				_require(item_click_applied_effect, "Expected clicking a combat consumable card to apply one authored combat-usable consumable effect.")
				_require(not _combat_has_consumable_definition(combat_flow, _selected_consumable_definition_before_use_item), "Expected clicking a combat consumable card to consume that stack directly instead of waiting for the action button.")
				_press(COMBAT_DEFEND_BUTTON_PATH)
				_advance_phase(17)
		17:
			if _is_scene("Combat"):
				var combat_log_text: String = _combat_log_text()
				_require(combat_log_text.contains("Defend") or combat_log_text.contains("guard"), "Expected defend button to write to the combat log.")
				var defend_entry: Label = _find_combat_log_entry_containing(["Defend", "guard"])
				_require(defend_entry != null, "Expected a readable player-side combat log entry after defending.")
				var defend_color: Color = defend_entry.get_theme_color("font_color")
				_require(defend_color.g > defend_color.r, "Expected player combat-log entries to lean green.")
				var enemy_entry: Label = _find_combat_log_entry_containing(["Enemy hit player", "player damage"])
				_require(enemy_entry != null, "Expected an enemy-side combat log entry after the enemy action resolves.")
				var enemy_color: Color = enemy_entry.get_theme_color("font_color")
				_require(enemy_color.r > enemy_color.g, "Expected enemy combat-log entries to lean red.")
				_press(COMBAT_ATTACK_BUTTON_PATH)
				_combat_attack_count = 1
				_advance_phase(18)
		18:
			if _is_scene("Combat"):
				_combat_attack_count += 1
				_require(_combat_attack_count <= 4, "Expected combat to end within four attacks after using item and defend.")
				_press(COMBAT_ATTACK_BUTTON_PATH)
			elif _is_scene("Reward"):
				var reward_root: Node = _get_scene_root("Reward")
				var reward_button_c: Button = reward_root.get_node(REWARD_CHOICE_C_BUTTON_PATH) as Button
				_require(reward_button_c != null and reward_button_c.visible and not reward_button_c.disabled, "Expected combat reward button C to stay available.")
				reward_button_c.emit_signal("pressed")
				_advance_phase(19)
		19:
			if _is_scene("LevelUp"):
				_press(LEVEL_UP_CHOICE_B_BUTTON_PATH)
				_advance_phase(20)
		20:
			if _is_scene("MapExplore"):
				var run_state_after_level_up: RunState = _get_run_state()
				_require(run_state_after_level_up.current_level == 2, "Expected full tour to reach level 2 after reward/level-up branch.")
				_require(run_state_after_level_up.character_perk_state.get_owned_perk_ids().size() == 1, "Expected one character perk after level-up choice.")
				_require(run_state_after_level_up.inventory_state.passive_slots.is_empty(), "Expected level-up progression to stop writing passive-item backpack slots.")
				run_state_after_level_up.player_hp = 1
				_reset_current_map_for_active_stage()
				run_state_after_level_up.map_runtime_state.roadside_encounters_this_stage = run_state_after_level_up.map_runtime_state.MAX_ROADSIDE_ENCOUNTERS_PER_STAGE
				current_scene.call("_refresh_ui")
				_prepare_map_adjacent_to_family("combat")
				_press_map_route_containing("Combat")
				_advance_phase(21)
		21:
			if _is_scene("Combat"):
				_press(COMBAT_ATTACK_BUTTON_PATH)
				_advance_phase(22)
		22:
			if _is_scene("RunEnd"):
				_press(RUN_END_RETURN_BUTTON_PATH)
				_advance_phase(23)
		23:
			if _is_scene("MainMenu"):
				await _finish_success("test_button_tour")

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


func _get_bootstrap() -> Node:
	return get_root().get_node_or_null("AppBootstrap")


func _get_run_state() -> RunState:
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.call("get_run_state")


func _current_state() -> int:
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return -1
	var flow_manager: Node = bootstrap.call("get_flow_manager")
	if flow_manager == null:
		return -1
	return int(flow_manager.call("get_current_state"))


func _get_support_state() -> RefCounted:
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.call("get_support_interaction_state")


func _press(node_path: String) -> void:
	var scene_root: Node = _get_scene_root()
	_require(scene_root != null, "Expected current scene before pressing %s." % node_path)
	var button: Button = scene_root.get_node(node_path) as Button
	_require(button != null, "Expected button at %s." % node_path)
	button.emit_signal("pressed")


func _click_combat_card(node_path: String) -> void:
	_require(current_scene != null, "Expected current scene before clicking %s." % node_path)
	var card: Control = current_scene.get_node(node_path) as Control
	_require(card != null, "Expected combat card at %s." % node_path)
	var press_event := InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = true
	card.emit_signal("gui_input", press_event)
	var release_event := InputEventMouseButton.new()
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.pressed = false
	current_scene.call("_input", release_event)


func _click_map_inventory_card(node_path: String) -> void:
	_require(current_scene != null and current_scene.name == "MapExplore", "Expected MapExplore before clicking %s." % node_path)
	var card: Control = current_scene.get_node(node_path) as Control
	_require(card != null, "Expected map inventory card at %s." % node_path)
	var press_event := InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = true
	press_event.position = Vector2(8, 8)
	card.emit_signal("gui_input", press_event)
	var release_event := InputEventMouseButton.new()
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.pressed = false
	release_event.position = Vector2(8, 8)
	card.emit_signal("gui_input", release_event)


func _click_map_inventory_card_by_slot_id(slot_id: int) -> void:
	_require(current_scene != null and current_scene.name == "MapExplore", "Expected MapExplore before clicking backpack slot %d." % slot_id)
	var inventory_cards_flow: Control = current_scene.get_node_or_null("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow") as Control
	_require(inventory_cards_flow != null, "Expected map backpack card flow before clicking slot %d." % slot_id)
	for child in inventory_cards_flow.get_children():
		var card: Control = child as Control
		if card == null:
			continue
		if int(card.get_meta("inventory_slot_id", -1)) != slot_id:
			continue
		_click_map_inventory_card(card.get_path())
		return
	_fail("Expected a map backpack card for slot id %d." % slot_id)


func _require_inventory_card_action_copy(node_path: String, expected_fragment: String) -> void:
	var card: PanelContainer = _get_scene_root().get_node_or_null(node_path) as PanelContainer
	_require(card != null, "Expected inventory card at %s." % node_path)
	var action_hint_label: Label = card.get_node_or_null("VBox/ActionHintLabel") as Label
	_require(action_hint_label != null, "Expected inventory card action copy label at %s." % node_path)
	_require(
		action_hint_label.text.contains(expected_fragment),
		"Expected inventory card action copy at %s to contain %s, got %s." % [node_path, expected_fragment, action_hint_label.text]
	)


func _require_combat_inventory_card_density() -> void:
	var equipment_card: Control = _get_scene_root().get_node_or_null("Margin/VBox/SecondaryScroll/SecondaryScrollContent/QuickItemSection/EquipmentCard") as Control
	var equipment_cards_flow: Control = _get_scene_root().get_node_or_null("Margin/VBox/SecondaryScroll/SecondaryScrollContent/QuickItemSection/EquipmentCard/EquipmentCardsFlow") as Control
	var inventory_card: Control = _get_scene_root().get_node_or_null("Margin/VBox/SecondaryScroll/SecondaryScrollContent/QuickItemSection/InventoryCard") as Control
	var inventory_cards_flow: Control = _get_scene_root().get_node_or_null("Margin/VBox/SecondaryScroll/SecondaryScrollContent/QuickItemSection/InventoryCard/InventoryCardsFlow") as Control
	_require(equipment_card != null and equipment_cards_flow != null, "Expected combat equipment card container and flow for density checks.")
	_require(inventory_card != null and inventory_cards_flow != null, "Expected combat backpack card container and flow for density checks.")
	var equipment_gap: float = equipment_card.get_global_rect().end.y - equipment_cards_flow.get_global_rect().end.y
	var inventory_gap: float = inventory_card.get_global_rect().end.y - inventory_cards_flow.get_global_rect().end.y
	_require(equipment_gap <= 24.0, "Expected combat equipment panel to hug its card row, got bottom gap %.2f." % equipment_gap)
	_require(inventory_gap <= 24.0, "Expected combat backpack panel to hug its card row, got bottom gap %.2f." % inventory_gap)


func _build_combat_inventory_signature(combat_flow: Variant) -> String:
	if combat_flow == null:
		return ""
	var combat_state: CombatState = combat_flow.combat_state
	var run_state: RunState = _get_run_state()
	if combat_state == null or run_state == null:
		return ""
	var projected_inventory: InventoryState = combat_state.build_inventory_projection(run_state.inventory_state)
	return JSON.stringify({
		"active_weapon_slot_id": int(combat_state.active_weapon_slot_id),
		"active_left_hand_slot_id": int(combat_state.active_left_hand_slot_id),
		"active_armor_slot_id": int(combat_state.active_armor_slot_id),
		"active_belt_slot_id": int(combat_state.active_belt_slot_id),
		"weapon_instance": combat_state.weapon_instance,
		"left_hand_instance": combat_state.left_hand_instance,
		"armor_instance": combat_state.armor_instance,
		"belt_instance": combat_state.belt_instance,
		"consumable_slots": combat_state.consumable_slots,
		"projected_inventory": projected_inventory.to_save_dict() if projected_inventory != null else {},
	})


func _combat_log_text() -> String:
	var entry_texts: PackedStringArray = []
	for entry_label in _combat_log_entry_labels():
		entry_texts.append(entry_label.text)
	return "\n".join(entry_texts)


func _combat_log_entry_labels() -> Array[Label]:
	var labels: Array[Label] = []
	if current_scene == null:
		return labels
	var entries_root: Control = current_scene.get_node_or_null("Margin/VBox/SecondaryScroll/SecondaryScrollContent/CombatLogCard/CombatLogVBox/CombatLogEntries") as Control
	if entries_root == null:
		return labels
	for child in entries_root.get_children():
		var entry_label: Label = child as Label
		if entry_label != null:
			labels.append(entry_label)
	return labels


func _find_combat_log_entry_containing(fragments: Array[String]) -> Label:
	for entry_label in _combat_log_entry_labels():
		var entry_text: String = entry_label.text
		for fragment in fragments:
			if entry_text.contains(fragment):
				return entry_label
	return null


func _combat_has_consumable_definition(combat_flow: Variant, definition_id: String) -> bool:
	if combat_flow == null or definition_id.is_empty():
		return false
	for slot_value in combat_flow.combat_state.consumable_slots:
		var slot: Dictionary = slot_value
		if String(slot.get("definition_id", "")) == definition_id:
			return true
	return false


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
	var fallback_family: String = _resolve_node_family_for_route_label(label_fragment)
	if not fallback_family.is_empty():
		var run_state: RunState = _get_run_state()
		var target_node_id: int = _find_unresolved_node_id_by_family(run_state.map_runtime_state, fallback_family) if run_state != null else -1
		if target_node_id >= 0:
			_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, target_node_id)
			current_scene.call("_refresh_ui")
			current_scene.call("_move_to_node", target_node_id)
			return
	_fail("Expected a visible enabled route button containing %s." % label_fragment)


func _get_map_inventory_overflow_prompt() -> Control:
	if current_scene == null or current_scene.name != "MapExplore":
		return null
	return current_scene.get_node_or_null("InventoryOverflowPrompt") as Control


func _press_map_overflow_prompt_first_discard() -> void:
	var overflow_prompt: Control = _get_map_inventory_overflow_prompt()
	_require(overflow_prompt != null and overflow_prompt.visible, "Expected a visible map inventory overflow prompt before discarding.")
	var options_vbox: Control = overflow_prompt.get_node_or_null("PromptHolder/PromptPanel/PromptVBox/OptionsVBox") as Control
	_require(options_vbox != null, "Expected discard options container on the map inventory overflow prompt.")
	for child in options_vbox.get_children():
		var button: Button = child as Button
		if button == null or button.disabled or not button.visible:
			continue
		button.emit_signal("pressed")
		return
	_fail("Expected at least one enabled discard option on the map inventory overflow prompt.")


func _prepare_map_adjacent_to_family(node_family: String) -> void:
	var run_state: RunState = _get_run_state()
	_require(run_state != null, "Expected RunState before preparing map adjacency for %s." % node_family)
	var target_node_id: int = _find_unresolved_node_id_by_family(run_state.map_runtime_state, node_family)
	_require(target_node_id >= 0, "Expected an unresolved %s node for the full button tour." % node_family)
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, target_node_id)
	current_scene.call("_refresh_ui")


func _fill_backpack_to_capacity(run_state: RunState) -> void:
	if run_state == null or run_state.inventory_state == null:
		return
	var inventory_snapshot: Dictionary = run_state.inventory_state.to_save_dict()
	var backpack_slots: Array = inventory_snapshot.get("backpack_slots", []).duplicate(true)
	var next_slot_id: int = int(inventory_snapshot.get("inventory_next_slot_id", 1))
	var filler_ids: Array[String] = [
		"sturdy_wraps",
		"packrat_clasp",
		"lean_pack_token",
		"tempered_binding",
	]
	var filler_index: int = 0
	while backpack_slots.size() < run_state.inventory_state.get_total_capacity():
		backpack_slots.append({
			"slot_id": next_slot_id,
			"inventory_family": InventoryState.INVENTORY_FAMILY_PASSIVE,
			"definition_id": filler_ids[filler_index % filler_ids.size()],
		})
		next_slot_id += 1
		filler_index += 1
	inventory_snapshot["backpack_slots"] = backpack_slots
	inventory_snapshot["inventory_next_slot_id"] = next_slot_id
	run_state.inventory_state.load_from_flat_save_dict(inventory_snapshot)


func _exhaust_roadside_quota(run_state: RunState) -> void:
	_require(run_state != null, "Expected RunState before suppressing roadside interruptions in the button tour.")
	run_state.map_runtime_state.roadside_encounters_this_stage = run_state.map_runtime_state.MAX_ROADSIDE_ENCOUNTERS_PER_STAGE


func _find_unresolved_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) != node_family:
			continue
		var node_state: String = String(node_snapshot.get("node_state", ""))
		if node_state != "resolved":
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
		"Rest":
			return "rest"
		"Merchant":
			return "merchant"
		"Blacksmith":
			return "blacksmith"
		"Trail Event":
			return "event"
		"Combat":
			return "combat"
		_:
			return ""


func _reset_current_map_for_active_stage() -> void:
	var run_state: RunState = _get_run_state()
	_require(run_state != null, "Expected RunState before resetting the active-stage map in the full button tour.")
	run_state.map_runtime_state.reset_for_new_run(run_state.stage_index)


func _build_map_signature(run_state: RunState) -> String:
	if run_state == null or run_state.map_runtime_state == null:
		return ""
	return JSON.stringify({
		"stage_index": run_state.stage_index,
		"run_seed": run_state.run_seed,
		"current_node_id": int(run_state.map_runtime_state.current_node_id),
		"nodes": run_state.map_runtime_state.build_node_snapshots(),
	})


func _build_route_board_visual_signature(scene: Node) -> String:
	if scene == null:
		return ""
	var route_binding: Object = scene.get("_route_binding")
	if route_binding == null:
		return ""
	var composition: Dictionary = route_binding.get("_board_composition_cache")
	var world_positions: Dictionary = composition.get("world_positions", {})
	var position_ids: Array[int] = []
	for node_id_variant in world_positions.keys():
		position_ids.append(int(node_id_variant))
	position_ids.sort()
	var position_parts: Array[String] = []
	for node_id in position_ids:
		var world_position: Vector2 = world_positions.get(node_id, Vector2.ZERO)
		position_parts.append("%d:%.2f,%.2f" % [node_id, world_position.x, world_position.y])
	var edge_parts: Array[String] = []
	for edge_variant in composition.get("visible_edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = edge_variant
		var point_parts: Array[String] = []
		var points: PackedVector2Array = edge.get("points", PackedVector2Array())
		for point in points:
			point_parts.append("%.2f,%.2f" % [point.x, point.y])
		edge_parts.append("%d>%d:%s" % [int(edge.get("from_node_id", -1)), int(edge.get("to_node_id", -1)), "|".join(point_parts)])
	edge_parts.sort()
	return "%s||%s" % [",".join(position_parts), ",".join(edge_parts)]


func _inventory_contains_slot_id(run_state: RunState, slot_id: int) -> bool:
	if run_state == null or run_state.inventory_state == null or slot_id <= 0:
		return false
	for slot_value in run_state.inventory_state.inventory_slots:
		var slot: Dictionary = slot_value
		if int(slot.get("slot_id", -1)) == slot_id:
			return true
	return false


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
