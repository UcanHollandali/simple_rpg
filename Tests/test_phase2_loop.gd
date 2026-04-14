# Layer: Tests
extends SceneTree
class_name TestPhase2Loop

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const CONFIRM_ICON_PATH := "res://Assets/Icons/icon_confirm.svg"
const CANCEL_ICON_PATH := "res://Assets/Icons/icon_cancel.svg"
const MAP_MUSIC_PATH := "res://Assets/Audio/Music/music_ui_hub_loop_temp_01.ogg"
const COMBAT_MUSIC_PATH := "res://Assets/Audio/Music/music_combat_loop_temp_01.ogg"
const MAIN_MENU_START_BUTTON_PATH := "Margin/VBox/ActionPanel/ActionVBox/StartRunButton"
const MAIN_MENU_LOAD_BUTTON_PATH := "Margin/VBox/ActionPanel/ActionVBox/LoadRunButton"
const LEVEL_UP_CHOICE_A_BUTTON_PATH := "Margin/VBox/ChoicesRow/ChoiceAButton"
const LEVEL_UP_CHOICE_B_BUTTON_PATH := "Margin/VBox/ChoicesRow/ChoiceBButton"
const LEVEL_UP_CHOICE_C_BUTTON_PATH := "Margin/VBox/ChoicesRow/ChoiceCButton"
const SAFE_MENU_LAUNCHER_BUTTON_PATH := "SafeMenuOverlay/MenuLauncherButton"
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
const PHASE_TIMEOUT_MS := 6000

var _reward_transition_count: int = 0
var _phase: int = 0
var _phase_started_at_ms: int = 0
var _durability_before_first_combat: int = 0
var _durability_before_second_combat: int = 0
var _defeat_attack_sent: bool = false
var _flow_signal_connected: bool = false
var _map_snapshot: Dictionary = {}
var _reward_snapshot: Dictionary = {}
var _level_up_snapshot: Dictionary = {}


func _init() -> void:
	print("phase2_loop: setup")
	_ensure_autoload_like_nodes()
	change_scene_to_file("res://scenes/main.tscn")
	_phase_started_at_ms = Time.get_ticks_msec()
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	_ensure_flow_signal_connection()
	match _phase:
		0:
			if _is_scene("Main"):
				current_scene.call("skip_to_main_menu")
			elif _is_scene("MainMenu"):
				print("phase2_loop: main menu")
				_require_generic_background_shell()
				_require_button_icon(MAIN_MENU_START_BUTTON_PATH, CONFIRM_ICON_PATH)
				_require_button_icon(MAIN_MENU_LOAD_BUTTON_PATH, CONFIRM_ICON_PATH)
				_require(_current_state() == FlowStateScript.Type.MAIN_MENU, "Expected MainMenu after boot.")
				_press(MAIN_MENU_START_BUTTON_PATH)
				_advance_phase(1)
		1:
			if _is_scene("MapExplore"):
				print("phase2_loop: map explore")
				_require(_current_state() == FlowStateScript.Type.MAP_EXPLORE, "Expected MapExplore after run setup.")
				var run_state: RunState = _get_run_state()
				_require(run_state != null, "Expected RunState to exist.")
				run_state.configure_run_seed(99)
				run_state.player_hp = 47
				run_state.hunger = 19
				run_state.gold = 14
				run_state.inventory_state.weapon_instance["current_durability"] = 11
				run_state.inventory_state.set_consumable_slots([
					{
						"definition_id": "minor_heal_potion",
						"current_stack": 2,
					},
				])
				var map_snapshot_result: Dictionary = _get_bootstrap().call("build_save_snapshot")
				_require(bool(map_snapshot_result.get("ok", false)), "Expected map snapshot build to succeed.")
				_map_snapshot = map_snapshot_result.get("snapshot", {})
				run_state.player_hp = 1
				run_state.hunger = 0
				run_state.gold = 0
				run_state.inventory_state.weapon_instance["current_durability"] = 0
				run_state.inventory_state.set_consumable_slots([])
				var map_restore_result: Dictionary = _get_bootstrap().call("restore_from_snapshot", _map_snapshot)
				_require(
					bool(map_restore_result.get("ok", false)),
					"Expected map snapshot restore to succeed, got %s." % [JSON.stringify(map_restore_result)]
				)
				_advance_phase(2)
		2:
			if _is_scene("MapExplore"):
				_require_map_background_shell()
				_require_audio_player_stream("NodeSelectSfxPlayer")
				_require_audio_player_stream("MapMusicPlayer")
				_require_shared_music_stream(MAP_MUSIC_PATH)
				_require_safe_menu_launcher_shell()
				_require_texture_rect_at_path("Margin/VBox/RouteGrid/CombatNodeMarker/RouteIcon")
				_require_button_icon(SAFE_MENU_SAVE_BUTTON_PATH, CONFIRM_ICON_PATH)
				_require_button_icon(SAFE_MENU_LOAD_BUTTON_PATH, CONFIRM_ICON_PATH)
				var restored_run_state: RunState = _get_run_state()
				_require(restored_run_state.player_hp == 47, "Expected map restore to recover HP.")
				_require(restored_run_state.hunger == 19, "Expected map restore to recover hunger.")
				_require(restored_run_state.gold == 14, "Expected map restore to recover gold.")
				_require(int(restored_run_state.inventory_state.weapon_instance.get("current_durability", 0)) == 11, "Expected map restore to recover durability.")
				_require(restored_run_state.inventory_state.consumable_slots.size() == 1, "Expected map restore to recover consumable slots.")
				_require(int(restored_run_state.inventory_state.consumable_slots[0].get("current_stack", 0)) == 2, "Expected map restore to recover consumable stack.")
				_durability_before_first_combat = int(restored_run_state.inventory_state.weapon_instance.get("current_durability", 0))
				var map_stats_label: Label = current_scene.get_node("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatsLabel") as Label
				_require(map_stats_label.text.contains("HP "), "Expected map stats label to show HP.")
				_require_texture_rect_at_path("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HpRow/HpStatusIcon")
				_require_texture_rect_at_path("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HungerRow/HungerStatusIcon")
				_require_texture_rect_at_path("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/DurabilityRow/DurabilityStatusIcon")
				_require_inventory_card("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow/InventorySlot1Card")
				_require_inventory_card("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow/InventorySlot2Card")
				_require_label_text_contains("Margin/VBox/InventorySection/InventoryHintLabel", "Tap gear to equip")
				_require_inventory_card_action_copy("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow/InventorySlot1Card", "Tap to unequip")
				_require_inventory_card_action_copy("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow/InventorySlot2Card", "Tap to use")
				_require_map_inventory_tooltip("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow/InventorySlot1Card")
				_require_map_vertical_stack_layout()
				_require_map_inventory_card_density()
				_require_empty_inventory_slot_copy("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow/InventorySlot3Card")
				_require_map_panel_polish()
				_press_map_route_containing("Combat")
				print("phase2_loop: first combat requested")
				_advance_phase(3)
		3:
			if _is_scene("Combat"):
				_require_combat_background_shell()
				_require_audio_player_stream("AttackResolveSfxPlayer")
				_require_audio_player_stream("BraceSfxPlayer")
				_require_audio_player_stream("ItemUseSfxPlayer")
				_require_audio_player_stream("CombatMusicPlayer")
				_require_shared_music_stream(COMBAT_MUSIC_PATH)
				_require_texture_rect_at_path("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentRow/IntentIcon")
				_require_texture_rect_at_path("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerHpRow/PlayerHpIcon")
				_require_texture_rect_at_path("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/HungerRow/HungerIcon")
				_require_texture_rect_at_path("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/DurabilityRow/DurabilityIcon")
				_require_combat_readability_shell()
				_require_inventory_card("Margin/VBox/QuickItemSection/InventoryCard/InventoryCardsFlow/InventorySlot1Card")
				_require_inventory_card("Margin/VBox/QuickItemSection/InventoryCard/InventoryCardsFlow/InventorySlot2Card")
				_require_label_text_contains("Margin/VBox/QuickItemSection/InventoryHintLabel", "spend your turn")
				_require_inventory_card_action_copy("Margin/VBox/QuickItemSection/InventoryCard/InventoryCardsFlow/InventorySlot1Card", "Ends turn")
				_require_inventory_card_action_copy("Margin/VBox/QuickItemSection/InventoryCard/InventoryCardsFlow/InventorySlot2Card", "Ends turn")
				_require_selected_inventory_card("Margin/VBox/QuickItemSection/InventoryCard/InventoryCardsFlow/InventorySlot2Card")
				_require_combat_inventory_tooltip("Margin/VBox/QuickItemSection/InventoryCard/InventoryCardsFlow/InventorySlot1Card")
				_require_combat_bust_shell("Ash Gnawer", true)
				_require_combat_action_tooltips()
				_press("Margin/VBox/Buttons/AttackButton")
			elif _is_scene("Reward"):
				_require_modal_popup_shell()
				_require_audio_player_stream("RewardClaimSfxPlayer")
				_require_audio_player_stream("RewardMusicPlayer")
				_require_shared_music_stream(MAP_MUSIC_PATH)
				print("phase2_loop: first reward")
				_require(_current_state() == FlowStateScript.Type.REWARD, "Expected Reward after first combat.")
				var first_reward_state: RefCounted = _get_reward_state()
				_require(first_reward_state != null, "Expected RewardState to exist during first reward.")
				_require(first_reward_state.source_context == RewardStateScript.SOURCE_COMBAT_VICTORY, "Expected first reward source to be combat victory.")
				_require(first_reward_state.offers.size() == 3, "Expected first reward to expose 3 offers.")
				_require(
					_reward_transition_count == 1,
					"Expected Reward transition count 1 after first combat, got %d." % _reward_transition_count
				)
				_require(
					int(_get_run_state().inventory_state.weapon_instance.get("current_durability", 0)) < _durability_before_first_combat,
					"Expected durability to persist after first combat."
				)
				var reward_snapshot_result: Dictionary = _get_bootstrap().call("build_save_snapshot")
				_require(bool(reward_snapshot_result.get("ok", false)), "Expected reward snapshot build to succeed.")
				_reward_snapshot = reward_snapshot_result.get("snapshot", {})
				_press_reward_offer_by_index(0)
				_advance_phase(4)
		4:
			if _is_scene("MapExplore"):
				var reward_restore_result: Dictionary = _get_bootstrap().call("restore_from_snapshot", _reward_snapshot)
				_require(
					bool(reward_restore_result.get("ok", false)),
					"Expected reward snapshot restore to succeed, got %s." % [JSON.stringify(reward_restore_result)]
				)
				_advance_phase(5)
		5:
			if _is_scene("Reward"):
				_require_modal_popup_shell()
				_require_audio_player_stream("RewardClaimSfxPlayer")
				_require_audio_player_stream("RewardMusicPlayer")
				_require_shared_music_stream(MAP_MUSIC_PATH)
				var restored_reward_state: RefCounted = _get_reward_state()
				_require(restored_reward_state != null, "Expected RewardState after reward restore.")
				_require(restored_reward_state.source_context == RewardStateScript.SOURCE_COMBAT_VICTORY, "Expected restored reward source to remain combat victory.")
				_require(restored_reward_state.offers.size() == 3, "Expected restored reward to keep 3 offers.")
				_get_run_state().xp = 10
				_press_reward_offer_by_index(0)
				_advance_phase(6)
		6:
			if _is_scene("LevelUp"):
				_require_modal_popup_shell()
				_require_audio_player_stream("LevelUpMusicPlayer")
				_require_button_has_no_icon(LEVEL_UP_CHOICE_A_BUTTON_PATH)
				_require_button_has_no_icon(LEVEL_UP_CHOICE_B_BUTTON_PATH)
				_require_button_has_no_icon(LEVEL_UP_CHOICE_C_BUTTON_PATH)
				_require_level_up_choice_copy(LEVEL_UP_CHOICE_A_BUTTON_PATH)
				_require_level_up_choice_copy(LEVEL_UP_CHOICE_B_BUTTON_PATH)
				_require_level_up_choice_copy(LEVEL_UP_CHOICE_C_BUTTON_PATH)
				_require_button_icon(SAFE_MENU_SAVE_BUTTON_PATH, CONFIRM_ICON_PATH)
				_require_button_icon(SAFE_MENU_LOAD_BUTTON_PATH, CONFIRM_ICON_PATH)
				_require(_current_state() == FlowStateScript.Type.LEVEL_UP, "Expected LevelUp after hitting the XP threshold.")
				var level_up_state: RefCounted = _get_level_up_state()
				_require(level_up_state != null, "Expected LevelUpState to exist.")
				_require(level_up_state.source_context == "reward_resolution", "Expected first level-up to come from reward resolution.")
				_require(int(level_up_state.current_level) == 1, "Expected level-up to start from level 1.")
				_require(int(level_up_state.target_level) == 2, "Expected first level-up target to be level 2.")
				_require(level_up_state.offers.size() == 3, "Expected LevelUp to expose 3 passive choices.")
				_require(_get_run_state().xp >= 10, "Expected reward resolution to leave enough XP for the first LevelUp.")
				var level_up_snapshot_result: Dictionary = _get_bootstrap().call("build_save_snapshot")
				_require(bool(level_up_snapshot_result.get("ok", false)), "Expected level-up snapshot build to succeed.")
				_level_up_snapshot = level_up_snapshot_result.get("snapshot", {})
				_press(LEVEL_UP_CHOICE_A_BUTTON_PATH)
				_advance_phase(7)
		7:
			if _is_scene("MapExplore"):
				var level_up_restore_result: Dictionary = _get_bootstrap().call("restore_from_snapshot", _level_up_snapshot)
				_require(
					bool(level_up_restore_result.get("ok", false)),
					"Expected level-up snapshot restore to succeed, got %s." % [JSON.stringify(level_up_restore_result)]
				)
				_advance_phase(8)
		8:
			if _is_scene("LevelUp"):
				_require_modal_popup_shell()
				_require_audio_player_stream("LevelUpMusicPlayer")
				_require_button_has_no_icon(LEVEL_UP_CHOICE_A_BUTTON_PATH)
				_require_button_has_no_icon(LEVEL_UP_CHOICE_B_BUTTON_PATH)
				_require_button_has_no_icon(LEVEL_UP_CHOICE_C_BUTTON_PATH)
				_require_level_up_choice_copy(LEVEL_UP_CHOICE_A_BUTTON_PATH)
				_require_level_up_choice_copy(LEVEL_UP_CHOICE_B_BUTTON_PATH)
				_require_level_up_choice_copy(LEVEL_UP_CHOICE_C_BUTTON_PATH)
				_require_button_icon(SAFE_MENU_SAVE_BUTTON_PATH, CONFIRM_ICON_PATH)
				_require_button_icon(SAFE_MENU_LOAD_BUTTON_PATH, CONFIRM_ICON_PATH)
				var restored_level_up_state: RefCounted = _get_level_up_state()
				_require(restored_level_up_state != null, "Expected LevelUpState after snapshot restore.")
				_require(int(restored_level_up_state.current_level) == 1, "Expected restored level-up current level to remain 1.")
				_require(int(restored_level_up_state.target_level) == 2, "Expected restored level-up target level to remain 2.")
				_require(restored_level_up_state.offers.size() == 3, "Expected restored level-up offers to remain intact.")
				_press(LEVEL_UP_CHOICE_A_BUTTON_PATH)
				_advance_phase(9)
		9:
			if _is_scene("MapExplore"):
				_require(_get_level_up_state() == null, "Expected LevelUpState to clear after claiming a passive.")
				_require(_get_run_state().current_level == 2, "Expected current level to advance to 2 after the first level-up.")
				_require(_get_run_state().inventory_state.passive_slots.size() == 1, "Expected one passive to be stored after LevelUp.")
				_require(
					String(_get_run_state().inventory_state.passive_slots[0].get("definition_id", "")) == "iron_grip_charm",
					"Expected the chosen passive to persist in RunState."
				)
				_require(_get_reward_state() == null, "Expected RewardState to clear after first reward claim.")
				print("phase2_loop: second combat requested")
				_durability_before_second_combat = int(_get_run_state().inventory_state.weapon_instance.get("current_durability", 0))
				_press_map_route_containing("Combat")
				_advance_phase(10)
		10:
			if _is_scene("Combat"):
				_require_combat_background_shell()
				_require_audio_player_stream("AttackResolveSfxPlayer")
				_require_audio_player_stream("BraceSfxPlayer")
				_require_audio_player_stream("ItemUseSfxPlayer")
				_require_audio_player_stream("CombatMusicPlayer")
				_require_shared_music_stream(COMBAT_MUSIC_PATH)
				_require_texture_rect_at_path("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentRow/IntentIcon")
				_require_texture_rect_at_path("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerHpRow/PlayerHpIcon")
				_require_texture_rect_at_path("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/HungerRow/HungerIcon")
				_require_texture_rect_at_path("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/DurabilityRow/DurabilityIcon")
				_require_inventory_card("Margin/VBox/QuickItemSection/InventoryCard/InventoryCardsFlow/InventorySlot1Card")
				_require_inventory_card("Margin/VBox/QuickItemSection/InventoryCard/InventoryCardsFlow/InventorySlot2Card")
				_require_combat_bust_shell("", true)
				_press("Margin/VBox/Buttons/AttackButton")
			elif _is_scene("Reward"):
				print("phase2_loop: second reward")
				_require_audio_player_stream("RewardMusicPlayer")
				_require_shared_music_stream(MAP_MUSIC_PATH)
				var second_reward_state: RefCounted = _get_reward_state()
				_require(second_reward_state != null, "Expected RewardState to exist during second reward.")
				_require(second_reward_state.source_context == RewardStateScript.SOURCE_COMBAT_VICTORY, "Expected second reward source to be combat victory.")
				_require(
					_reward_transition_count == 2,
					"Expected Reward transition count 2 after second combat, got %d." % _reward_transition_count
				)
				_require(
					int(_get_run_state().inventory_state.weapon_instance.get("current_durability", 0)) < _durability_before_second_combat,
					"Expected durability to persist after second combat."
				)
				_press_reward_offer_by_index(0)
				_advance_phase(11)
		11:
			if _is_scene("MapExplore"):
				_require(_get_reward_state() == null, "Expected RewardState to clear after second reward claim.")
				print("phase2_loop: defeat path requested")
				var run_state: RunState = _get_run_state()
				run_state.player_hp = 1
				_reset_current_map_for_active_stage()
				_press_map_route_containing("Combat")
				_advance_phase(12)
		12:
			if _is_scene("Combat") and not _defeat_attack_sent:
				_require_combat_background_shell()
				_require_audio_player_stream("AttackResolveSfxPlayer")
				_require_audio_player_stream("BraceSfxPlayer")
				_require_audio_player_stream("ItemUseSfxPlayer")
				_require_audio_player_stream("CombatMusicPlayer")
				_require_shared_music_stream(COMBAT_MUSIC_PATH)
				_require_texture_rect_at_path("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentRow/IntentIcon")
				_require_texture_rect_at_path("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerHpRow/PlayerHpIcon")
				_require_texture_rect_at_path("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/HungerRow/HungerIcon")
				_require_texture_rect_at_path("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/DurabilityRow/DurabilityIcon")
				_require_inventory_card("Margin/VBox/QuickItemSection/InventoryCard/InventoryCardsFlow/InventorySlot1Card")
				_require_inventory_card("Margin/VBox/QuickItemSection/InventoryCard/InventoryCardsFlow/InventorySlot2Card")
				_defeat_attack_sent = true
				_press("Margin/VBox/Buttons/AttackButton")
			elif _is_scene("RunEnd"):
				print("phase2_loop: run end")
				_require_generic_background_shell()
				_require_button_icon(SAFE_MENU_SAVE_BUTTON_PATH, CONFIRM_ICON_PATH)
				_require_button_icon(SAFE_MENU_LOAD_BUTTON_PATH, CONFIRM_ICON_PATH)
				_require_button_icon("Margin/Center/ContentCard/VBox/ReturnButton", CANCEL_ICON_PATH)
				_require(_current_state() == FlowStateScript.Type.RUN_END, "Expected RunEnd after player defeat.")
				var title_label: Label = current_scene.get_node("Margin/Center/ContentCard/VBox/TitleLabel") as Label
				var result_label: Label = current_scene.get_node("Margin/Center/ContentCard/VBox/ResultLabel") as Label
				_require(title_label.text == "Journey's End", "Expected run end title to use the game-facing defeat heading.")
				_require(result_label.text == "The road took this run.", "Expected run end screen to use the game-facing defeat copy.")
				_press("Margin/Center/ContentCard/VBox/ReturnButton")
				_advance_phase(13)
		13:
			if _is_scene("MainMenu"):
				_require_generic_background_shell()
				_require(_current_state() == FlowStateScript.Type.MAIN_MENU, "Expected MainMenu after returning from RunEnd.")
				print("test_phase2_loop: full run segment passed")
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


func _ensure_flow_signal_connection() -> void:
	if _flow_signal_connected:
		return

	var bootstrap: Node = get_root().get_node_or_null("AppBootstrap")
	if bootstrap == null:
		return

	var flow_manager: Node = bootstrap.call("get_flow_manager")
	if flow_manager == null:
		return

	var handler: Callable = Callable(self, "_on_flow_state_changed")
	if not flow_manager.is_connected("flow_state_changed", handler):
		flow_manager.connect("flow_state_changed", handler)
	_flow_signal_connected = true


func _on_flow_state_changed(_old_state: int, new_state: int) -> void:
	print("phase2_loop: flow -> %s" % FlowStateScript.name_of(new_state))
	if new_state == FlowStateScript.Type.REWARD:
		_reward_transition_count += 1


func _is_scene(expected_name: String) -> bool:
	return current_scene != null and current_scene.name == expected_name


func _press(node_path: String) -> void:
	if current_scene == null:
		_fail("Expected current scene before pressing %s." % node_path)
	var button: Button = current_scene.get_node(node_path) as Button
	_require(button != null, "Expected button at %s." % node_path)
	button.emit_signal("pressed")


func _press_map_route_containing(label_fragment: String) -> void:
	_require(current_scene != null, "Expected current scene before pressing a map route.")
	for button_name in ROUTE_BUTTON_NODE_NAMES:
		var button: Button = current_scene.get_node_or_null("Margin/VBox/RouteGrid/%s" % button_name) as Button
		if button == null or not button.visible or button.disabled:
			continue
		var route_label: String = button.text if not button.text.is_empty() else button.tooltip_text
		if route_label.contains(label_fragment):
			button.emit_signal("pressed")
			return
	_fail("Expected a visible enabled route button containing %s." % label_fragment)


func _press_reward_offer_by_index(index: int) -> void:
	_press("Margin/VBox/CardsRow/%s/VBox/%s" % [_reward_card_name_for_index(index), _reward_button_name_for_index(index)])


func _press_reward_offer_by_effect_type(effect_type: String) -> void:
	var reward_state: RefCounted = _get_reward_state()
	_require(reward_state != null, "Expected RewardState before selecting a reward offer.")
	for index in range(reward_state.offers.size()):
		if String(reward_state.offers[index].get("effect_type", "")) == effect_type:
			_press_reward_offer_by_index(index)
			return
	_fail("Expected reward offer with effect_type %s." % effect_type)


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


func _current_state() -> int:
	var bootstrap: Node = get_root().get_node_or_null("AppBootstrap")
	if bootstrap == null:
		return -1
	var flow_manager: Node = bootstrap.call("get_flow_manager")
	if flow_manager == null:
		return -1
	return int(flow_manager.call("get_current_state"))


func _get_run_state() -> RunState:
	var bootstrap: Node = get_root().get_node_or_null("AppBootstrap")
	if bootstrap == null:
		return null
	return bootstrap.call("get_run_state")


func _get_reward_state() -> RefCounted:
	var bootstrap: Node = get_root().get_node_or_null("AppBootstrap")
	if bootstrap == null:
		return null
	return bootstrap.call("get_reward_state")


func _get_bootstrap() -> Node:
	return get_root().get_node_or_null("AppBootstrap")


func _get_level_up_state() -> RefCounted:
	var bootstrap: Node = get_root().get_node_or_null("AppBootstrap")
	if bootstrap == null:
		return null
	return bootstrap.call("get_level_up_state")


func _reset_current_map_for_active_stage() -> void:
	var run_state: RunState = _get_run_state()
	_require(run_state != null, "Expected RunState before resetting the active-stage map for the defeat leg.")
	run_state.map_runtime_state.reset_for_new_run(run_state.stage_index)
	current_scene.call("_refresh_ui")


func _require_combat_bust_shell(expected_enemy_name: String, expect_enemy_bust: bool) -> void:
	_require(current_scene != null and current_scene.name == "Combat", "Expected Combat scene before reading bust shell state.")

	var enemy_name_label: Label = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyNameLabel") as Label
	var enemy_bust_frame: Control = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame") as Control
	var player_bust_frame: Control = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame") as Control
	_require(enemy_name_label != null, "Expected combat shell enemy name label to exist.")
	_require(enemy_bust_frame != null, "Expected combat shell enemy bust frame to exist.")
	_require(player_bust_frame != null, "Expected combat shell player bust frame to exist.")
	_require(not enemy_name_label.text.is_empty(), "Expected combat shell enemy name to stay readable.")
	if not expected_enemy_name.is_empty():
		_require(enemy_name_label.text == expected_enemy_name, "Expected combat shell enemy name %s, got %s." % [expected_enemy_name, enemy_name_label.text])
	_require(player_bust_frame.visible, "Expected combat shell player bust to stay visible.")
	_require(enemy_bust_frame.visible == expect_enemy_bust, "Expected combat shell enemy bust visibility %s for %s." % [expect_enemy_bust, expected_enemy_name])


func _require_map_background_shell() -> void:
	_require(current_scene != null and current_scene.name == "MapExplore", "Expected MapExplore scene before reading background shell state.")
	_require_texture_rect_present("BackgroundFar")
	_require_texture_rect_present("BackgroundMid")
	_require_texture_rect_present("BackgroundOverlay")


func _require_combat_background_shell() -> void:
	_require(current_scene != null and current_scene.name == "Combat", "Expected Combat scene before reading background shell state.")
	_require_texture_rect_present("BackgroundFar")
	_require_texture_rect_present("BackgroundMid")
	_require_texture_rect_present("BackgroundOverlay")


func _require_generic_background_shell() -> void:
	_require_texture_rect_present("BackgroundFar")
	_require_texture_rect_present("BackgroundMid")
	_require_texture_rect_present("BackgroundOverlay")


func _require_modal_popup_shell() -> void:
	var scrim: ColorRect = current_scene.get_node_or_null("Scrim") as ColorRect
	_require(scrim != null, "Expected Scrim on %s." % current_scene.name)
	_require(scrim.visible, "Expected Scrim to stay visible on %s." % current_scene.name)
	var shell: PanelContainer = current_scene.get_node_or_null("Margin/ContentShell") as PanelContainer
	_require(shell != null, "Expected ContentShell popup on %s." % current_scene.name)
	_require(shell.visible, "Expected ContentShell popup to stay visible on %s." % current_scene.name)
	for node_name in ["BackgroundFar", "BackgroundMid", "BackgroundOverlay"]:
		var texture_rect: TextureRect = current_scene.get_node_or_null(node_name) as TextureRect
		if texture_rect != null:
			_require(texture_rect.visible, "Expected TextureRect %s to stay visible on %s." % [node_name, current_scene.name])
			_require(texture_rect.texture != null, "Expected TextureRect %s to keep a texture on %s." % [node_name, current_scene.name])


func _require_texture_rect_present(node_name: String) -> void:
	var texture_rect: TextureRect = current_scene.get_node_or_null(node_name) as TextureRect
	_require(texture_rect != null, "Expected TextureRect %s to exist on %s." % [node_name, current_scene.name])
	_require(texture_rect.visible, "Expected TextureRect %s to stay visible on %s." % [node_name, current_scene.name])
	_require(texture_rect.texture != null, "Expected TextureRect %s to have a texture on %s." % [node_name, current_scene.name])


func _require_texture_rect_at_path(node_path: String) -> void:
	var texture_rect: TextureRect = current_scene.get_node_or_null(node_path) as TextureRect
	_require(texture_rect != null, "Expected TextureRect %s to exist on %s." % [node_path, current_scene.name])
	_require(texture_rect.visible, "Expected TextureRect %s to stay visible on %s." % [node_path, current_scene.name])
	_require(texture_rect.texture != null, "Expected TextureRect %s to have a texture on %s." % [node_path, current_scene.name])


func _require_inventory_card(node_path: String) -> PanelContainer:
	var card: PanelContainer = current_scene.get_node_or_null(node_path) as PanelContainer
	_require(card != null, "Expected inventory card %s to exist on %s." % [node_path, current_scene.name])
	_require(card.visible, "Expected inventory card %s to stay visible on %s." % [node_path, current_scene.name])
	var custom_tooltip_text: String = String(card.get_meta("custom_tooltip_text", ""))
	_require(not custom_tooltip_text.is_empty(), "Expected inventory card %s to expose custom tooltip text on %s." % [node_path, current_scene.name])
	_require(card.tooltip_text.is_empty(), "Expected inventory card %s to suppress the default Godot tooltip copy on %s." % [node_path, current_scene.name])
	var icon_rect: TextureRect = card.get_node_or_null("VBox/IconRect") as TextureRect
	if icon_rect == null:
		icon_rect = card.get_node_or_null("VBox/IconFrame/IconCenter/IconRect") as TextureRect
	_require(icon_rect != null, "Expected inventory card %s to include an icon slot on %s." % [node_path, current_scene.name])
	_require(icon_rect.visible, "Expected inventory icon %s to stay visible on %s." % [node_path, current_scene.name])
	_require(icon_rect.texture != null, "Expected inventory icon %s to keep a texture on %s." % [node_path, current_scene.name])
	_require(icon_rect.custom_minimum_size.x >= 46.0 and icon_rect.custom_minimum_size.y >= 46.0, "Expected inventory icon %s to use the larger polished size on %s." % [node_path, current_scene.name])
	var accent_bar: ColorRect = card.get_node_or_null("VBox/AccentBar") as ColorRect
	_require(accent_bar != null and accent_bar.custom_minimum_size.y >= 4.0, "Expected inventory card %s to expose the polished accent strip shell on %s." % [node_path, current_scene.name])
	var style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
	_require(style != null and style.border_width_left >= 2, "Expected inventory card %s to expose the polished thicker border shell on %s." % [node_path, current_scene.name])
	return card


func _require_map_inventory_tooltip(node_path: String) -> void:
	var card: PanelContainer = _require_inventory_card(node_path)
	var tooltip_panel: PanelContainer = current_scene.get_node_or_null("InventoryTooltipPanel") as PanelContainer
	_require(tooltip_panel != null, "Expected MapExplore to create an inventory tooltip bubble.")
	var tooltip_label: Label = tooltip_panel.get_node_or_null("InventoryTooltipLabel") as Label
	_require(tooltip_label != null, "Expected map inventory tooltip bubble to expose a label.")
	var custom_tooltip_text: String = String(card.get_meta("custom_tooltip_text", ""))
	card.emit_signal("mouse_entered")
	var hovered_style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
	_require(bool(card.get_meta("is_hovered", false)), "Expected inventory hover on %s to set the hover-state metadata." % node_path)
	_require(hovered_style != null and hovered_style.shadow_size >= 13, "Expected inventory hover on %s to strengthen the card shell." % node_path)
	_require(tooltip_panel.visible, "Expected map inventory tooltip bubble to show on hover.")
	_require(tooltip_label.text == custom_tooltip_text, "Expected map inventory hover bubble to mirror the card tooltip copy.")
	card.emit_signal("mouse_exited")
	var resting_style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
	_require(not bool(card.get_meta("is_hovered", false)), "Expected inventory hover on %s to clear after exit." % node_path)
	var is_equipped: bool = bool(card.get_meta("is_equipped", false))
	if is_equipped:
		_require(resting_style != null and resting_style.shadow_size >= 14, "Expected equipped inventory card %s to keep its equipped emphasis after hover exit." % node_path)
	else:
		_require(resting_style != null and resting_style.shadow_size <= hovered_style.shadow_size, "Expected inventory hover on %s to relax after exit." % node_path)
	_require(not tooltip_panel.visible, "Expected map inventory tooltip bubble to hide after hover ends.")


func _require_map_vertical_stack_layout() -> void:
	var inventory_card: Control = current_scene.get_node_or_null("Margin/VBox/InventorySection/InventoryCard") as Control
	var current_anchor_card: Control = current_scene.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard") as Control
	var route_grid: Control = current_scene.get_node_or_null("Margin/VBox/RouteGrid") as Control
	_require(inventory_card != null, "Expected MapExplore inventory card container to exist.")
	_require(current_anchor_card != null, "Expected MapExplore current anchor card to exist.")
	var inventory_rect: Rect2 = inventory_card.get_global_rect()
	var current_anchor_rect: Rect2 = current_anchor_card.get_global_rect()
	var viewport_height: float = current_scene.get_viewport_rect().size.y
	var vertical_gap: float = current_anchor_rect.position.y - (inventory_rect.position.y + inventory_rect.size.y)
	_require(vertical_gap <= 24.0, "Expected map inventory and bottom cards to stack tightly on first load, got gap %.2f." % vertical_gap)
	_require(
		current_anchor_rect.end.y <= viewport_height - 8.0,
		"Expected map bottom cards to stay inside the viewport on first load. Bottom %.2f vs viewport %.2f. Route %.2f / Inventory %.2f-%.2f / Bottom %.2f-%.2f." % [
			current_anchor_rect.end.y,
			viewport_height,
			route_grid.get_global_rect().size.y if route_grid != null else -1.0,
			inventory_rect.position.y,
			inventory_rect.end.y,
			current_anchor_rect.position.y,
			current_anchor_rect.end.y,
		]
	)


func _require_map_inventory_card_density() -> void:
	var inventory_card: Control = current_scene.get_node_or_null("Margin/VBox/InventorySection/InventoryCard") as Control
	var inventory_cards_flow: Control = current_scene.get_node_or_null("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow") as Control
	_require(inventory_card != null, "Expected MapExplore inventory card container to exist for density checks.")
	_require(inventory_cards_flow != null, "Expected MapExplore inventory flow to exist for density checks.")
	var inventory_rect: Rect2 = inventory_card.get_global_rect()
	var flow_rect: Rect2 = inventory_cards_flow.get_global_rect()
	var bottom_gap: float = inventory_rect.end.y - flow_rect.end.y
	_require(bottom_gap <= 24.0, "Expected map inventory panel to hug its card row, got bottom gap %.2f." % bottom_gap)


func _require_empty_inventory_slot_copy(node_path: String) -> void:
	var card: PanelContainer = current_scene.get_node_or_null(node_path) as PanelContainer
	if card == null:
		var flow: Node = current_scene.get_node_or_null("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow")
		var child_names: Array[String] = []
		if flow != null:
			for child in flow.get_children():
				child_names.append(String(child.name))
		_require(false, "Expected inventory empty-slot card %s to exist on %s. Flow children: %s" % [node_path, current_scene.name, ", ".join(child_names)])
		return
	var title_label: Label = card.get_node_or_null("VBox/TitleLabel") as Label
	var detail_label: Label = card.get_node_or_null("VBox/DetailLabel") as Label
	var placeholder_label: Label = card.get_node_or_null("VBox/PlaceholderLabel") as Label
	_require(title_label != null and title_label.text == "Open Slot", "Expected empty inventory card %s to keep a single Open Slot label." % node_path)
	_require(detail_label != null and detail_label.text.is_empty(), "Expected empty inventory card %s to avoid duplicate detail copy." % node_path)
	_require(not detail_label.visible, "Expected empty inventory card %s to hide the duplicate detail label shell." % node_path)
	_require(placeholder_label != null and placeholder_label.visible, "Expected empty inventory card %s to expose the placeholder slot glyph." % node_path)


func _require_inventory_card_action_copy(node_path: String, expected_fragment: String) -> void:
	var card: PanelContainer = current_scene.get_node_or_null(node_path) as PanelContainer
	_require(card != null, "Expected inventory card %s to exist on %s." % [node_path, current_scene.name])
	var action_hint_label: Label = card.get_node_or_null("VBox/ActionHintLabel") as Label
	_require(action_hint_label != null and action_hint_label.visible, "Expected inventory card %s to expose an action-hint label." % node_path)
	_require(
		action_hint_label.text.to_lower().contains(expected_fragment.to_lower()),
		"Expected inventory card %s action copy to contain %s, got %s." % [node_path, expected_fragment, action_hint_label.text]
	)


func _require_label_text_contains(node_path: String, expected_fragment: String) -> void:
	var label: Label = current_scene.get_node_or_null(node_path) as Label
	_require(label != null and label.visible, "Expected label %s to exist on %s." % [node_path, current_scene.name])
	_require(
		label.text.to_lower().contains(expected_fragment.to_lower()),
		"Expected label %s on %s to contain %s, got %s." % [node_path, current_scene.name, expected_fragment, label.text]
	)


func _require_map_panel_polish() -> void:
	var header_card: PanelContainer = current_scene.get_node_or_null("Margin/VBox/TopRow/HeaderCard") as PanelContainer
	var run_summary_card: PanelContainer = current_scene.get_node_or_null("Margin/VBox/TopRow/RunSummaryCard") as PanelContainer
	var inventory_card: PanelContainer = current_scene.get_node_or_null("Margin/VBox/InventorySection/InventoryCard") as PanelContainer
	for panel in [header_card, run_summary_card, inventory_card]:
		_require(panel != null, "Expected polished map panel shell to exist.")
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
		_require(style != null and style.border_width_left >= 2, "Expected polished map panel borders to stay thicker. Got %s." % [style.border_width_left if style != null else -1])
		_require(style != null and style.shadow_size >= 12, "Expected polished map panel shell to keep a visible shadow. Got %s." % [style.shadow_size if style != null else -1])


func _require_combat_inventory_tooltip(node_path: String) -> void:
	var card: PanelContainer = _require_inventory_card(node_path)
	var tooltip_panel: PanelContainer = current_scene.get_node_or_null("ActionTooltipPanel") as PanelContainer
	_require(tooltip_panel != null, "Expected Combat to reuse the themed tooltip bubble for inventory cards.")
	var tooltip_label: Label = tooltip_panel.get_node_or_null("ActionTooltipLabel") as Label
	_require(tooltip_label != null, "Expected combat inventory tooltip bubble to expose a label.")
	var custom_tooltip_text: String = String(card.get_meta("custom_tooltip_text", ""))
	card.emit_signal("mouse_entered")
	_require(tooltip_panel.visible, "Expected combat inventory tooltip bubble to show on hover.")
	_require(tooltip_label.text == custom_tooltip_text, "Expected combat inventory hover bubble to mirror the card tooltip copy.")
	card.emit_signal("mouse_exited")
	_require(not tooltip_panel.visible, "Expected combat inventory tooltip bubble to hide after hover ends.")


func _require_audio_player_stream(node_name: String) -> void:
	var player: AudioStreamPlayer = current_scene.get_node_or_null(node_name) as AudioStreamPlayer
	_require(player != null, "Expected AudioStreamPlayer %s to exist on %s." % [node_name, current_scene.name])
	_require(player.stream != null, "Expected AudioStreamPlayer %s to have a stream on %s." % [node_name, current_scene.name])


func _require_shared_music_stream(expected_path: String) -> void:
	var actual_path: String = SceneAudioPlayersScript.get_shared_music_resource_path(get_root())
	_require(not actual_path.is_empty(), "Expected shared music player to have a stream on %s." % _stringify_current_scene())
	_require(actual_path == expected_path, "Expected shared music stream %s on %s, got %s." % [expected_path, _stringify_current_scene(), actual_path])


func _require_button_icon(node_path: String, expected_path: String) -> void:
	var button: Button = current_scene.get_node_or_null(node_path) as Button
	_require(button != null, "Expected button %s to exist on %s." % [node_path, current_scene.name])
	_require(button.icon != null, "Expected button %s to expose an icon on %s." % [node_path, current_scene.name])
	_require(button.icon.resource_path == expected_path, "Expected button %s to use %s on %s, got %s." % [node_path, expected_path, current_scene.name, button.icon.resource_path])


func _require_button_has_no_icon(node_path: String) -> void:
	var button: Button = current_scene.get_node_or_null(node_path) as Button
	_require(button != null, "Expected button %s to exist on %s." % [node_path, current_scene.name])
	_require(button.icon == null, "Expected button %s to stay text-first on %s." % [node_path, current_scene.name])


func _require_level_up_choice_copy(node_path: String) -> void:
	var button: Button = current_scene.get_node_or_null(node_path) as Button
	_require(button != null, "Expected level-up choice button %s to exist on %s." % [node_path, current_scene.name])
	var title_label: Label = button.get_node_or_null("ContentMargin/ContentVBox/TitleLabel") as Label
	var detail_label: Label = button.get_node_or_null("ContentMargin/ContentVBox/DetailLabel") as Label
	_require(title_label != null and not title_label.text.is_empty(), "Expected level-up choice %s to expose a separate title label." % node_path)
	_require(detail_label != null and not detail_label.text.is_empty(), "Expected level-up choice %s to expose a wrapped detail label." % node_path)
	_require(button.text.is_empty(), "Expected level-up choice %s to render through the internal layout shell instead of raw button text." % node_path)


func _require_button_tooltip_contains(node_path: String, expected_fragment: String) -> void:
	var button: Button = current_scene.get_node_or_null(node_path) as Button
	_require(button != null, "Expected button %s to exist on %s." % [node_path, current_scene.name])
	_require(not button.tooltip_text.is_empty(), "Expected button %s to expose tooltip text on %s." % [node_path, current_scene.name])
	_require(
		button.tooltip_text.to_lower().contains(expected_fragment.to_lower()),
		"Expected button %s tooltip on %s to contain %s, got %s." % [node_path, current_scene.name, expected_fragment, button.tooltip_text]
	)


func _require_safe_menu_launcher_shell() -> void:
	var overlay: Control = current_scene.get_node_or_null("SafeMenuOverlay") as Control
	var launcher_button: Button = current_scene.get_node_or_null(SAFE_MENU_LAUNCHER_BUTTON_PATH) as Button
	var top_row: Control = current_scene.get_node_or_null("Margin/VBox/TopRow") as Control
	var run_summary_card: Control = current_scene.get_node_or_null("Margin/VBox/TopRow/RunSummaryCard") as Control
	var spacer: Control = current_scene.get_node_or_null("Margin/VBox/TopRow/SafeMenuSpacer") as Control
	_require(overlay != null, "Expected MapExplore to create the safe menu overlay shell.")
	_require(launcher_button != null, "Expected MapExplore to expose the safe menu launcher button.")
	_require(top_row != null, "Expected MapExplore to keep the top row shell for launcher clearance checks.")
	_require(run_summary_card != null, "Expected MapExplore to keep the run summary card for launcher clearance checks.")
	_require(spacer != null, "Expected MapExplore top row to reserve a spacer lane for the safe menu launcher.")
	_require(overlay.z_index > top_row.z_index, "Expected safe menu overlay to render above the top row.")
	var launcher_rect: Rect2 = launcher_button.get_global_rect()
	var run_summary_rect: Rect2 = run_summary_card.get_global_rect()
	var viewport_size: Vector2 = current_scene.get_viewport_rect().size
	var launcher_is_right: bool = (launcher_rect.position.x + launcher_rect.size.x * 0.5) >= (viewport_size.x * 0.5)
	if launcher_is_right:
		_require(spacer.custom_minimum_size.x >= launcher_button.size.x, "Expected the top-row safe-menu spacer to reserve at least one launcher width.")
	_require(launcher_rect.size.x > 0.0 and launcher_rect.size.y > 0.0, "Expected safe menu launcher to have a laid-out global rect.")
	_require(not launcher_rect.intersects(run_summary_rect), "Expected safe menu launcher to stay clear of the map run summary card.")
	var launcher_gap: float = launcher_rect.position.x - run_summary_rect.end.x
	_require(launcher_gap <= 22.0, "Expected safe menu launcher gap to stay tight after layout, got %.2f." % launcher_gap)


func _require_combat_action_tooltips() -> void:
	_require(current_scene != null and current_scene.name == "Combat", "Expected Combat scene before reading action tooltips.")
	_require_button_tooltip_contains("Margin/VBox/Buttons/AttackButton", "durability")
	_require_button_tooltip_contains("Margin/VBox/Buttons/BraceButton", "50%")
	_require_button_tooltip_contains("Margin/VBox/Buttons/UseItemButton", "consumable card")

	var attack_button: Button = current_scene.get_node_or_null("Margin/VBox/Buttons/AttackButton") as Button
	var tooltip_panel: PanelContainer = current_scene.get_node_or_null("ActionTooltipPanel") as PanelContainer
	_require(tooltip_panel != null, "Expected Combat to create a themed action tooltip bubble.")
	var tooltip_label: Label = tooltip_panel.get_node_or_null("ActionTooltipLabel") as Label
	_require(tooltip_label != null, "Expected action tooltip bubble to expose a label.")

	attack_button.emit_signal("mouse_entered")
	_require(tooltip_panel.visible, "Expected action tooltip bubble to show when hovering an action button.")
	_require(tooltip_label.text == attack_button.tooltip_text, "Expected hover bubble text to mirror the button tooltip copy.")
	attack_button.emit_signal("mouse_exited")
	_require(not tooltip_panel.visible, "Expected action tooltip bubble to hide after hover ends.")


func _require_combat_readability_shell() -> void:
	_require(current_scene != null and current_scene.name == "Combat", "Expected Combat scene before reading readability shell state.")
	var hud_hp_label: Label = current_scene.get_node_or_null("Margin/VBox/HeaderStack/HeaderStatsRow/CombatHudCard/HudVBox/HudHpLabel") as Label
	var hud_hunger_label: Label = current_scene.get_node_or_null("Margin/VBox/HeaderStack/HeaderStatsRow/CombatHudCard/HudVBox/HudHungerLabel") as Label
	var hud_durability_label: Label = current_scene.get_node_or_null("Margin/VBox/HeaderStack/HeaderStatsRow/CombatHudCard/HudVBox/HudDurabilityLabel") as Label
	var hero_badge_label: Label = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/HeroBadgePanel/HeroBadgeLabel") as Label
	var player_name_label: Label = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerIdentityRow/PlayerNameLabel") as Label
	var enemy_trait_label: Label = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyTraitLabel") as Label
	var intent_detail_label: Label = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentDetailLabel") as Label
	var enemy_hp_bar: ProgressBar = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyHpBar") as ProgressBar
	var enemy_feedback_layer: Control = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/CombatFeedbackLayer") as Control
	var enemy_feedback_flash: ColorRect = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/CombatFeedbackLayer/ImpactFlash") as ColorRect
	var enemy_feedback_text_layer: Control = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/CombatFeedbackLayer/FeedbackTextLayer") as Control
	var player_feedback_layer: Control = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/CombatFeedbackLayer") as Control
	var player_feedback_flash: ColorRect = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/CombatFeedbackLayer/ImpactFlash") as ColorRect
	var player_feedback_text_layer: Control = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/CombatFeedbackLayer/FeedbackTextLayer") as Control
	var forecast_attack_label: Label = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastAttackLabel") as Label
	var forecast_defense_label: Label = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastDefenseLabel") as Label
	var forecast_incoming_label: Label = current_scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastIncomingLabel") as Label
	_require(hud_hp_label != null and hud_hp_label.visible and hud_hp_label.text.contains("HP"), "Expected combat HUD to expose compact HP readout.")
	_require(hud_hunger_label != null and hud_hunger_label.visible and hud_hunger_label.text.contains("Hunger"), "Expected combat HUD to expose compact hunger readout.")
	_require(hud_durability_label != null and hud_durability_label.visible and hud_durability_label.text.contains("Durability"), "Expected combat HUD to expose compact durability readout.")
	_require(hero_badge_label != null and hero_badge_label.text == "YOU", "Expected player bust to expose a distinct YOU badge.")
	_require(player_name_label != null and player_name_label.text == "Wayfinder", "Expected player card to expose the wayfinder identity label.")
	_require(enemy_trait_label != null, "Expected enemy card to expose the trait-hint label shell.")
	_require(enemy_hp_bar != null and enemy_hp_bar.visible and enemy_hp_bar.max_value >= 1.0, "Expected enemy card to expose a readable HP bar.")
	_require(enemy_feedback_layer != null and enemy_feedback_flash != null and enemy_feedback_text_layer != null, "Expected enemy card to expose the combat feedback overlay shell.")
	_require(player_feedback_layer != null and player_feedback_flash != null and player_feedback_text_layer != null, "Expected player card to expose the combat feedback overlay shell.")
	_require(intent_detail_label != null and intent_detail_label.visible and intent_detail_label.text.contains("Incoming"), "Expected enemy card to expose incoming-hit detail helper copy.")
	_require(forecast_attack_label != null and forecast_attack_label.visible and forecast_attack_label.text.contains("Hit"), "Expected player forecast card to expose outgoing hit preview.")
	_require(forecast_defense_label != null and forecast_defense_label.visible and forecast_defense_label.text.contains("Defense"), "Expected player forecast card to expose defense preview.")
	_require(forecast_incoming_label != null and forecast_incoming_label.visible and forecast_incoming_label.text.contains("Incoming"), "Expected player forecast card to expose incoming-hit preview.")


func _require_selected_inventory_card(node_path: String) -> void:
	var card: PanelContainer = _require_inventory_card(node_path)
	_require(bool(card.get_meta("is_selected", false)), "Expected inventory card %s to expose the selected-slot highlight state." % node_path)
	var style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
	_require(style != null and style.border_width_left >= 2, "Expected selected inventory card %s to render a stronger border." % node_path)


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
