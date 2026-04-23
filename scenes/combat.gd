# Layer: Scenes - presentation only
extends Control

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const CombatFlowScript = preload("res://Game/Application/combat_flow.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const CombatPresenterScript = preload("res://Game/UI/combat_presenter.gd")
const CombatSceneUiScript = preload("res://Game/UI/combat_scene_ui.gd")
const CombatSceneShellScript = preload("res://Game/UI/combat_scene_shell.gd")
const CombatGuardBadgeScript = preload("res://Game/UI/combat_guard_badge.gd")
const CombatEnemyIntentBustVisualsScript = preload("res://Game/UI/combat_enemy_intent_bust_visuals.gd")
const CombatFeedbackLaneScript = preload("res://Game/UI/combat_feedback_lane.gd")
const HungerWarningToastScript = preload("res://Game/UI/hunger_warning_toast.gd")
const ActionHintControllerScript = preload("res://Game/UI/action_hint_controller.gd")
const RunInventoryPanelScript = preload("res://Game/UI/run_inventory_panel.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const RunStatusStripScript = preload("res://Game/UI/run_status_strip.gd")
const RunSummaryCleanupHelperScript = preload("res://Game/UI/run_summary_cleanup_helper.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const AUDIO_PLAYER_CONFIG := {
	"AttackResolveSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_combat_hit_light_01.ogg"},
	"DefendSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_defend_01.ogg"},
	"ItemUseSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_item_use_01.ogg"},
	"CombatMusicPlayer": {"path": "res://Assets/Audio/Music/music_combat_loop_proto_01.ogg", "music": true, "loop": true},
}
const COMBAT_SECONDARY_SCROLL_PATH := "Margin/VBox/SecondaryScroll"
const COMBAT_SECONDARY_SCROLL_CONTENT_PATH := "Margin/VBox/SecondaryScroll/SecondaryScrollContent"
const COMBAT_HEADER_STACK_PATH := "Margin/VBox/HeaderStack"
const PLAYER_INFO_VBOX_PATH := "Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox"
const PLAYER_RUN_SUMMARY_CARD_PATH := "Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerRunSummaryCard"
const PLAYER_RUN_SUMMARY_LABEL_PATH := "Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerRunSummaryCard/PlayerRunSummaryFallbackLabel"
const ATTACK_BUTTON_PATH := "Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackButton"
const DEFENSE_BUTTON_PATH := "Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionButton"
const TECHNIQUE_ACTION_CARD_PATH := "Margin/VBox/Buttons/ActionCardsRow/TechniqueActionCard"
const TECHNIQUE_BUTTON_PATH := "Margin/VBox/Buttons/ActionCardsRow/TechniqueActionCard/TechniqueActionVBox/TechniqueActionButton"
const HAND_SWAP_PANEL_PATH := "QuickItemSection/HandSwapPanel"
const HAND_SWAP_TITLE_PATH := "QuickItemSection/HandSwapPanel/HandSwapVBox/HandSwapTitleLabel"
const HAND_SWAP_HINT_PATH := "QuickItemSection/HandSwapPanel/HandSwapVBox/HandSwapHintLabel"
const HAND_SWAP_SLOT_BUTTONS_ROW_PATH := "QuickItemSection/HandSwapPanel/HandSwapVBox/HandSwapSlotButtonsRow"
const RIGHT_HAND_SWAP_BUTTON_PATH := "QuickItemSection/HandSwapPanel/HandSwapVBox/HandSwapSlotButtonsRow/RightHandSwapButton"
const LEFT_HAND_SWAP_BUTTON_PATH := "QuickItemSection/HandSwapPanel/HandSwapVBox/HandSwapSlotButtonsRow/LeftHandSwapButton"
const HAND_SWAP_CANDIDATES_FLOW_PATH := "QuickItemSection/HandSwapPanel/HandSwapVBox/HandSwapCandidatesFlow"
const COMBAT_LOG_TITLE_PATH := "CombatLogCard/CombatLogVBox/CombatLogTitleLabel"
const COMBAT_LOG_ENTRIES_PATH := "CombatLogCard/CombatLogVBox/CombatLogEntries"
const LOG_TONE_PLAYER := "player"
const LOG_TONE_ENEMY := "enemy"
const LOG_TONE_NEUTRAL := "neutral"
const INVENTORY_DRAG_THRESHOLD := 14.0
const ENEMY_HP_BAR_NAME := "EnemyHpBar"
const BAR_TWEEN_META_KEY := "bar_tween"
const BAR_INITIALIZED_META_KEY := "bar_initialized"
const ACTION_BUTTON_TWEEN_META_KEY := "action_button_tween"
const HUNGER_WARNING_Z_INDEX := 125
const BUTTON_BOUNCE_DOWN_DURATION := 0.1
const BUTTON_BOUNCE_UP_DURATION := 0.08
const BAR_TWEEN_MIN_DURATION := 0.18
const BAR_TWEEN_MAX_DURATION := 0.3
var _combat_flow: CombatFlow
var _presenter: RefCounted
var _run_inventory_panel: RunInventoryPanel
var _run_state: RunState
var _status_lines: PackedStringArray = []
var _status_line_tones: PackedStringArray = []
var _transition_requested: bool = false
var _feedback_lane: CombatFeedbackLane
var _action_hint_controller: ActionHintController
var _player_guard_badge: CombatGuardBadge
var _enemy_intent_bust_visuals: CombatEnemyIntentBustVisuals
var _selected_consumable_slot_index: int = -1
var _pending_phase_feedback_models: Array[Dictionary] = []
var _is_compact_layout: bool = false
var _guard_before_turn_end_phase: int = -1
var _selected_hand_swap_slot_name: String = ""
var _run_status_strip: RunStatusStrip
var _safe_menu: SafeMenuOverlay
var _hunger_warning_toast: HungerWarningToast
var _first_run_hint_controller: FirstRunHintController
var _scene_node_cache: Dictionary = {}
@onready var _root_vbox: Control = _scene_node("Margin/VBox") as Control
@onready var _combat_secondary_scroll_content: Control = _scene_node(COMBAT_SECONDARY_SCROLL_CONTENT_PATH) as Control
@onready var _header_stack: Control = _scene_node(COMBAT_HEADER_STACK_PATH) as Control
@onready var _turn_label: Label = _scene_node("Margin/VBox/HeaderStack/TurnLabel") as Label
@onready var _attack_button: Button = _scene_node(ATTACK_BUTTON_PATH) as Button
@onready var _defense_button: Button = _scene_node(DEFENSE_BUTTON_PATH) as Button
@onready var _technique_button: Button = _scene_node(TECHNIQUE_BUTTON_PATH) as Button
@onready var _enemy_hp_bar: ProgressBar = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/%s" % ENEMY_HP_BAR_NAME) as ProgressBar
@onready var _player_info_vbox: VBoxContainer = _scene_node(PLAYER_INFO_VBOX_PATH) as VBoxContainer
@onready var _player_run_summary_card: PanelContainer = _scene_node(PLAYER_RUN_SUMMARY_CARD_PATH) as PanelContainer
@onready var _player_run_summary_label: Label = _scene_node(PLAYER_RUN_SUMMARY_LABEL_PATH) as Label

func _ready() -> void:
	_scene_node_cache.clear()
	var tree_root: Node = get_tree().get_root()
	var active_scene_root: Node = get_tree().current_scene
	RunSummaryCleanupHelperScript.new().cleanup_orphaned_map_run_summary_cards(tree_root, active_scene_root)
	_feedback_lane = CombatFeedbackLaneScript.new()
	_feedback_lane.configure(self, Callable(self, "_scene_node"))
	_action_hint_controller = ActionHintControllerScript.new()
	_action_hint_controller.configure(self)
	_connect_buttons()
	CombatSceneShellScript.ensure_feedback_shells(Callable(self, "_scene_node"))
	var action_hint_controls: Dictionary = CombatSceneShellScript.ensure_action_hint_controls(Callable(self, "_scene_node"))
	_action_hint_controller.configure(
		self,
		action_hint_controls.get("panel") as PanelContainer,
		action_hint_controls.get("label") as Label
	)
	_ensure_player_guard_badge()
	_enemy_intent_bust_visuals = CombatEnemyIntentBustVisualsScript.new()
	_enemy_intent_bust_visuals.configure(self, Callable(self, "_scene_node"))
	_enemy_intent_bust_visuals.ensure_badge(_is_compact_layout)
	_ensure_hunger_warning_toast()
	_presenter = CombatPresenterScript.new()
	_run_status_strip = RunStatusStripScript.new()
	if _run_status_strip != null and not _run_status_strip.is_connected("hunger_threshold_crossed", Callable(self, "_on_hunger_threshold_crossed")):
		_run_status_strip.connect("hunger_threshold_crossed", Callable(self, "_on_hunger_threshold_crossed"))
	_run_inventory_panel = RunInventoryPanelScript.new()
	_run_inventory_panel.configure(self, {
		"equipment_container": _combat_secondary_node("QuickItemSection/EquipmentCard/EquipmentCardsFlow") as Container,
		"backpack_container": _combat_secondary_node("QuickItemSection/InventoryCard/InventoryCardsFlow") as Container,
		"equipment_title_label": _combat_secondary_node("QuickItemSection/EquipmentTitleLabel") as Label,
		"equipment_hint_label": _combat_secondary_node("QuickItemSection/EquipmentHintLabel") as Label,
		"inventory_title_label": _combat_secondary_node("QuickItemSection/InventoryTitleLabel") as Label,
		"inventory_hint_label": _combat_secondary_node("QuickItemSection/InventoryHintLabel") as Label,
		"click_handler": Callable(self, "_handle_inventory_card_click"),
		"drag_complete_handler": Callable(self, "_handle_inventory_card_drag_completed"),
		"drag_started_handler": Callable(self, "_on_inventory_card_drag_started"),
		"drag_threshold": INVENTORY_DRAG_THRESHOLD,
		"release_on_global_mouse_up": true,
	})
	_run_inventory_panel.set_interaction_mode("combat")
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	_apply_temp_theme()
	_apply_hand_swap_panel_style()
	_setup_safe_menu()
	SceneLayoutHelperScript.bind_viewport_size_changed(self, Callable(self, "_on_viewport_size_changed"))
	_apply_portrait_safe_layout()

	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		_append_status_line("AppBootstrap not found.")
		_refresh_ui()
		return

	_run_state = bootstrap.get_run_state()
	if _run_state == null:
		_append_status_line("RunState not available.")
		_refresh_ui()
		return

	if _run_state.inventory_state.weapon_instance.is_empty():
		bootstrap.ensure_run_state_initialized()
		_run_state = bootstrap.get_run_state()
	_setup_first_run_hint_controller()

	_combat_flow = CombatFlowScript.new()
	_combat_flow.connect("domain_event_emitted", Callable(self, "_on_domain_event_emitted"))
	_combat_flow.connect("combat_ended_signal", Callable(self, "_on_combat_ended"))
	_combat_flow.connect("turn_phase_resolved", Callable(self, "_on_turn_phase_resolved"))

	var combat_setup: Dictionary = bootstrap.build_combat_setup_data()
	if not bool(combat_setup.get("ok", false)):
		_append_status_line("Combat setup failed: %s" % String(combat_setup.get("error", "unknown")))
		_refresh_ui()
		return

	var enemy_definition: Dictionary = combat_setup.get("enemy_definition", {})
	var weapon_definition: Dictionary = combat_setup.get("weapon_definition", {})
	_combat_flow.setup_combat(_run_state, enemy_definition, weapon_definition, combat_setup)
	_sync_selected_consumable_slot_index()
	_transition_requested = false
	_guard_before_turn_end_phase = max(0, int(_combat_flow.combat_state.current_guard))
	_append_status_line(_presenter.build_combat_ready_text(_combat_flow.combat_state))
	SceneAudioPlayersScript.start_looping(self, "CombatMusicPlayer")
	_refresh_ui()
	_request_first_run_hint("first_combat_defend")
	_request_contextual_combat_hints()


func _scene_node(path: String) -> Node:
	if not is_inside_tree() and path.begins_with("/root/"):
		return null
	if _scene_node_cache.has(path):
		var cached_node: Node = _scene_node_cache[path] as Node
		if cached_node != null and is_instance_valid(cached_node):
			return cached_node
		_scene_node_cache.erase(path)
	var node: Node = get_node_or_null(path)
	if node != null:
		_scene_node_cache[path] = node
	return node

func _exit_tree() -> void:
	if _player_guard_badge != null:
		_player_guard_badge.release()
	if _hunger_warning_toast != null:
		_hunger_warning_toast.release()
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_on_viewport_size_changed"))
	_release_first_run_hint_controller_host()
	if _run_inventory_panel != null:
		_run_inventory_panel.release()
	if _action_hint_controller != null:
		_action_hint_controller.hide_panel(true, true)
	SceneAudioCleanupScript.release_players(self, SceneAudioPlayersScript.node_names_from_config(AUDIO_PLAYER_CONFIG))

func _input(event: InputEvent) -> void:
	if _run_inventory_panel == null:
		return
	_run_inventory_panel.handle_root_input(event)


func _combat_secondary_root() -> Control:
	var root: Control = _combat_secondary_scroll_content if _combat_secondary_scroll_content != null and is_instance_valid(_combat_secondary_scroll_content) else _scene_node(COMBAT_SECONDARY_SCROLL_CONTENT_PATH) as Control
	if root != null:
		return root
	return _root_vbox if _root_vbox != null and is_instance_valid(_root_vbox) else _scene_node("Margin/VBox") as Control


func _combat_secondary_node(relative_path: String) -> Node:
	var root: Node = _combat_secondary_root()
	if root == null:
		return null

	var node: Node = root.get_node_or_null(relative_path)
	if node != null:
		return node
	if relative_path.begins_with("Margin/VBox/SecondaryScroll/SecondaryScrollContent/"):
		node = root.get_node_or_null(relative_path.trim_prefix("Margin/VBox/SecondaryScroll/SecondaryScrollContent/"))
	if node != null:
		return node
	if relative_path.begins_with("Margin/VBox/"):
		node = root.get_node_or_null(relative_path.trim_prefix("Margin/VBox/"))
	if node != null:
		return node
	node = _scene_node(relative_path)
	if node != null:
		return node
	node = _scene_node("Margin/VBox/" + relative_path)
	if node == null:
		node = _scene_node("Margin/VBox/%s" % relative_path)
	return node


func _connect_buttons() -> void:
	var attack_button: Button = _attack_button if _attack_button != null and is_instance_valid(_attack_button) else _scene_node(ATTACK_BUTTON_PATH) as Button
	var defense_button: Button = _defense_button if _defense_button != null and is_instance_valid(_defense_button) else _scene_node(DEFENSE_BUTTON_PATH) as Button

	if attack_button != null and not attack_button.is_connected("pressed", Callable(self, "_on_attack_pressed")):
		attack_button.connect("pressed", Callable(self, "_on_attack_pressed"))
	if _action_hint_controller != null:
		_action_hint_controller.connect_button(attack_button, CombatFlowScript.ACTION_ATTACK, TempScreenThemeScript.RUST_ACCENT_COLOR)
	if defense_button != null and not defense_button.is_connected("pressed", Callable(self, "_on_defend_pressed")):
		defense_button.connect("pressed", Callable(self, "_on_defend_pressed"))
	if _action_hint_controller != null:
		_action_hint_controller.connect_button(defense_button, CombatFlowScript.ACTION_DEFEND, TempScreenThemeScript.TEAL_ACCENT_COLOR)
	var technique_button: Button = _technique_button if _technique_button != null and is_instance_valid(_technique_button) else _scene_node(TECHNIQUE_BUTTON_PATH) as Button
	if technique_button != null and not technique_button.is_connected("pressed", Callable(self, "_on_technique_pressed")):
		technique_button.connect("pressed", Callable(self, "_on_technique_pressed"))
	if _action_hint_controller != null:
		_action_hint_controller.connect_button(technique_button, CombatFlowScript.ACTION_TECHNIQUE, TempScreenThemeScript.REWARD_ACCENT_COLOR)
	var right_hand_swap_button: Button = _combat_secondary_node(RIGHT_HAND_SWAP_BUTTON_PATH) as Button
	if right_hand_swap_button != null and not right_hand_swap_button.is_connected("pressed", Callable(self, "_on_right_hand_swap_pressed")):
		right_hand_swap_button.connect("pressed", Callable(self, "_on_right_hand_swap_pressed"))
	var left_hand_swap_button: Button = _combat_secondary_node(LEFT_HAND_SWAP_BUTTON_PATH) as Button
	if left_hand_swap_button != null and not left_hand_swap_button.is_connected("pressed", Callable(self, "_on_left_hand_swap_pressed")):
		left_hand_swap_button.connect("pressed", Callable(self, "_on_left_hand_swap_pressed"))


func _on_attack_pressed() -> void:
	_resolve_player_turn(CombatFlowScript.ACTION_ATTACK)


func _on_defend_pressed() -> void:
	_resolve_player_turn(CombatFlowScript.ACTION_DEFEND)


func _on_technique_pressed() -> void:
	_resolve_player_turn(CombatFlowScript.ACTION_TECHNIQUE)


func _on_right_hand_swap_pressed() -> void:
	_on_hand_swap_slot_pressed(InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND)


func _on_left_hand_swap_pressed() -> void:
	_on_hand_swap_slot_pressed(InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND)


func _on_hand_swap_slot_pressed(slot_name: String) -> void:
	if _combat_flow == null or _combat_flow.combat_state.combat_ended:
		return
	if not _combat_flow.has_hand_swap_candidates(slot_name):
		return
	_selected_hand_swap_slot_name = slot_name
	_refresh_hand_swap_panel()


func _on_hand_swap_candidate_pressed(slot_name: String, backpack_slot_id: int) -> void:
	if _combat_flow == null or _combat_flow.combat_state.combat_ended:
		return
	_selected_hand_swap_slot_name = slot_name
	_resolve_hand_swap_turn(slot_name, backpack_slot_id)


func _on_combat_ended(result: String) -> void:
	if _transition_requested:
		return

	_transition_requested = true
	_set_buttons_enabled(false)
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return
	bootstrap.resolve_combat_result(result)


func _on_domain_event_emitted(event_name: String, payload: Dictionary) -> void:
	_queue_feedback_for_domain_event(event_name, payload)
	var line: String = ""
	if event_name != "EnemyIntentRevealed":
		line = _presenter.format_domain_event_line(event_name, payload)
	if not line.is_empty():
		_append_status_line(line, _resolve_domain_event_log_tone(event_name, payload))


func _on_turn_phase_resolved(phase_name: String, action_name: String, result: Dictionary) -> void:
	var line: String = ""
	match phase_name:
		CombatFlowScript.PHASE_PLAYER_ACTION:
			line = _presenter.format_player_turn_phase_line(action_name, result)
		CombatFlowScript.PHASE_ENEMY_ACTION:
			line = _presenter.format_enemy_turn_phase_line(result)
			_guard_before_turn_end_phase = max(0, int(_combat_flow.combat_state.current_guard)) if _combat_flow != null else 0
		CombatFlowScript.PHASE_TURN_END:
			line = _presenter.format_turn_end_line(result)
			_queue_guard_decay_feedback_from_turn_end(result)

	if not line.is_empty():
		_append_status_line(line, _resolve_turn_phase_log_tone(phase_name, action_name, result))

	_refresh_ui()
	if _feedback_lane != null and not _pending_phase_feedback_models.is_empty():
		var phase_models: Array[Dictionary] = _pending_phase_feedback_models.duplicate(true)
		_pending_phase_feedback_models.clear()
		_feedback_lane.flush_phase_feedbacks(phase_models)


func _resolve_player_turn(action_name: String, action_value: int = -1) -> void:
	if _combat_flow == null or _combat_flow.combat_state.combat_ended:
		return

	if _action_hint_controller != null:
		_action_hint_controller.hide_panel(true)
	_play_action_start_sfx(action_name)
	match action_name:
		CombatFlowScript.ACTION_ATTACK:
			_combat_flow.resolve_attack_turn()
		CombatFlowScript.ACTION_DEFEND:
			_combat_flow.resolve_defend_turn()
		CombatFlowScript.ACTION_USE_ITEM:
			_combat_flow.resolve_use_item_turn(action_value)
		_:
			return


func _resolve_hand_swap_turn(slot_name: String, backpack_slot_id: int) -> void:
	if _combat_flow == null or _combat_flow.combat_state.combat_ended:
		return

	if _action_hint_controller != null:
		_action_hint_controller.hide_panel(true)
	_play_action_start_sfx(CombatFlowScript.ACTION_SWAP_HAND)
	_combat_flow.resolve_swap_hand_turn(slot_name, backpack_slot_id)


func _refresh_ui() -> void:
	var preview_consumable: Dictionary = {}
	var preview_snapshot: Dictionary = {}
	var turn_label: Label = _turn_label if _turn_label != null and is_instance_valid(_turn_label) else _scene_node("Margin/VBox/HeaderStack/TurnLabel") as Label
	if turn_label != null and _combat_flow != null:
		turn_label.text = _presenter.build_turn_text(_combat_flow.combat_state)
	if _combat_flow != null:
		preview_snapshot = _combat_flow.build_preview_snapshot()
		_sync_selected_consumable_slot_index()
		preview_consumable = _preview_consumable_slot()

	var enemy_bust_path: String = ""
	if _combat_flow != null:
		enemy_bust_path = _presenter.build_enemy_bust_texture_path(_combat_flow.combat_state)
	_apply_bust_texture(
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame/BustTexture",
		enemy_bust_path
	)

	var enemy_name_label: Label = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyNameLabel") as Label
	if enemy_name_label != null and _combat_flow != null:
		enemy_name_label.text = _presenter.build_enemy_name_text(_combat_flow.combat_state)

	var enemy_type_label: Label = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyTypeLabel") as Label
	if enemy_type_label != null and _combat_flow != null:
		enemy_type_label.text = _presenter.build_enemy_overview_text(_combat_flow.combat_state)
	var enemy_trait_label: Label = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyTraitLabel") as Label
	if enemy_trait_label != null:
		enemy_trait_label.visible = false

	var enemy_hp_label: Label = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyHpLabel") as Label
	if enemy_hp_label != null and _combat_flow != null:
		enemy_hp_label.text = _presenter.build_enemy_hp_text(_combat_flow.combat_state, preview_snapshot)
	var enemy_hp_bar: ProgressBar = _enemy_hp_bar if _enemy_hp_bar != null and is_instance_valid(_enemy_hp_bar) else _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/%s" % ENEMY_HP_BAR_NAME) as ProgressBar
	if enemy_hp_bar != null and _combat_flow != null:
		var enemy_max_hp: int = _extract_enemy_max_hp_from_state(_combat_flow.combat_state)
		if _feedback_lane != null:
			_feedback_lane.animate_progress_bar(enemy_hp_bar, enemy_max_hp, _combat_flow.combat_state.enemy_hp)

	var enemy_token_path: String = ""
	if _combat_flow != null:
		enemy_token_path = _presenter.build_enemy_token_texture_path(_combat_flow.combat_state)
	_apply_bust_texture(
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/BossTokenFrame",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/BossTokenFrame/BossTokenTexture",
		enemy_token_path
	)

	var current_intent: Dictionary = {}
	if _combat_flow != null:
		current_intent = _combat_flow.get_current_intent()
	var intent_title_label: Label = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentTitleLabel") as Label
	if intent_title_label != null:
		intent_title_label.text = _presenter.build_intent_title_text()
	var intent_label: Label = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentRow/IntentLabel") as Label
	if intent_label != null and _combat_flow != null:
		intent_label.text = _presenter.build_intent_summary_text(current_intent, preview_snapshot)
		_apply_texture_rect_asset(
			"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentRow/IntentIcon",
			_presenter.build_intent_icon_texture_path(current_intent)
		)
	var intent_detail_label: Label = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentDetailLabel") as Label
	if intent_detail_label != null and _combat_flow != null:
		var intent_detail_text: String = _presenter.build_intent_detail_text(current_intent)
		intent_detail_label.text = intent_detail_text
		intent_detail_label.visible = not intent_detail_text.is_empty()
	if _enemy_intent_bust_visuals != null:
		_enemy_intent_bust_visuals.refresh(current_intent, _presenter, _is_compact_layout)

	_apply_bust_texture(
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/BustTexture",
		_presenter.build_player_bust_texture_path()
	)
	var player_name_label: Label = _scene_node("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerIdentityRow/PlayerNameLabel") as Label
	if player_name_label != null:
		player_name_label.text = _presenter.build_player_identity_text()
	var hero_badge_label: Label = _scene_node("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/HeroBadgePanel/HeroBadgeLabel") as Label
	if hero_badge_label != null:
		hero_badge_label.text = _presenter.build_player_badge_text()
	var player_loadout_label: Label = _scene_node("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerLoadoutLabel") as Label
	if player_loadout_label != null and _combat_flow != null:
		player_loadout_label.text = _presenter.build_player_loadout_text(_combat_flow.combat_state)
	var player_run_summary_card: PanelContainer = _player_run_summary_card if _player_run_summary_card != null and is_instance_valid(_player_run_summary_card) else _scene_node(PLAYER_RUN_SUMMARY_CARD_PATH) as PanelContainer
	var player_run_summary_label: Label = _player_run_summary_label if _player_run_summary_label != null and is_instance_valid(_player_run_summary_label) else _scene_node(PLAYER_RUN_SUMMARY_LABEL_PATH) as Label
	if player_run_summary_card != null:
		_run_status_strip.render_into_with_hunger_signal(
			player_run_summary_card,
			player_run_summary_label,
			_presenter.build_player_status_model(_combat_flow.combat_state if _combat_flow != null else null),
			TempScreenThemeScript.TEAL_ACCENT_COLOR
		)
	_refresh_player_guard_badge()
	var forecast_card: PanelContainer = _scene_node("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard") as PanelContainer
	if forecast_card != null:
		forecast_card.visible = false

	var player_status_section: VBoxContainer = _scene_node("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerStatusSection") as VBoxContainer
	var player_status_title: Label = _scene_node("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerStatusSection/PlayerStatusTitleLabel") as Label
	var player_status_row: HFlowContainer = _scene_node("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerStatusSection/PlayerStatusRow") as HFlowContainer
	var enemy_status_section: VBoxContainer = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyStatusSection") as VBoxContainer
	var enemy_status_title: Label = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyStatusSection/EnemyStatusTitleLabel") as Label
	var enemy_status_row: HFlowContainer = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyStatusSection/EnemyStatusRow") as HFlowContainer
	if _combat_flow != null:
		var player_status_texts: PackedStringArray = _presenter.build_status_chip_texts(_combat_flow.combat_state.player_statuses, "")
		var has_player_statuses: bool = _status_chip_list_has_entry(player_status_texts)
		if player_status_section != null:
			player_status_section.visible = has_player_statuses
		if player_status_title != null:
			player_status_title.visible = has_player_statuses
		_render_status_chips(player_status_row, player_status_texts if has_player_statuses else PackedStringArray())

		var enemy_status_texts: PackedStringArray = _presenter.build_status_chip_texts(_combat_flow.combat_state.enemy_statuses, "")
		var has_enemy_statuses: bool = _status_chip_list_has_entry(enemy_status_texts)
		if enemy_status_section != null:
			enemy_status_section.visible = has_enemy_statuses
		if enemy_status_title != null:
			enemy_status_title.visible = has_enemy_statuses
		_render_status_chips(enemy_status_row, enemy_status_texts if has_enemy_statuses else PackedStringArray())

	var combat_log_card: PanelContainer = _combat_secondary_node("CombatLogCard") as PanelContainer
	var combat_log_title: Label = _combat_secondary_node(COMBAT_LOG_TITLE_PATH) as Label
	var combat_log_entries: VBoxContainer = _combat_secondary_node(COMBAT_LOG_ENTRIES_PATH) as VBoxContainer
	var show_combat_log: bool = _should_show_combat_log()
	if combat_log_card != null:
		combat_log_card.visible = show_combat_log
	if combat_log_title != null:
		combat_log_title.visible = show_combat_log
	if combat_log_entries != null:
		_render_combat_log_entries(combat_log_entries if show_combat_log else null)

	var defense_button: Button = _defense_button if _defense_button != null and is_instance_valid(_defense_button) else _scene_node(DEFENSE_BUTTON_PATH) as Button
	if defense_button != null and _combat_flow != null:
		defense_button.text = _presenter.build_defensive_action_label(_combat_flow.combat_state)
	var technique_card: PanelContainer = _scene_node(TECHNIQUE_ACTION_CARD_PATH) as PanelContainer
	if technique_card != null:
		technique_card.visible = _combat_flow != null
	var technique_button: Button = _technique_button if _technique_button != null and is_instance_valid(_technique_button) else _scene_node(TECHNIQUE_BUTTON_PATH) as Button
	if technique_button != null and _combat_flow != null:
		technique_button.text = _presenter.build_technique_action_label(_combat_flow.combat_state)
	var action_section_title_label: Label = _scene_node("Margin/VBox/Buttons/ActionSectionTitleLabel") as Label
	if action_section_title_label != null:
		action_section_title_label.text = "Pick Your Move"
	var attack_eyebrow_label: Label = _scene_node("Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackActionEyebrowLabel") as Label
	if attack_eyebrow_label != null:
		attack_eyebrow_label.text = "DEAL DAMAGE"
	var defense_eyebrow_label: Label = _scene_node("Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionEyebrowLabel") as Label
	if defense_eyebrow_label != null:
		defense_eyebrow_label.text = "BLOCK THE HIT"
	var technique_eyebrow_label: Label = _scene_node("Margin/VBox/Buttons/ActionCardsRow/TechniqueActionCard/TechniqueActionVBox/TechniqueActionEyebrowLabel") as Label
	if technique_eyebrow_label != null and _combat_flow != null:
		technique_eyebrow_label.text = _presenter.build_technique_action_eyebrow_text(_combat_flow.combat_state)
	var attack_preview_label: Label = _scene_node("Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackActionPreviewLabel") as Label
	if attack_preview_label != null:
		attack_preview_label.text = _presenter.build_action_card_preview_text(CombatFlowScript.ACTION_ATTACK, _combat_flow.combat_state if _combat_flow != null else null, {}, preview_snapshot)
	var defense_preview_label: Label = _scene_node("Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionPreviewLabel") as Label
	if defense_preview_label != null:
		defense_preview_label.text = _presenter.build_action_card_preview_text(CombatFlowScript.ACTION_DEFEND, _combat_flow.combat_state if _combat_flow != null else null, {}, preview_snapshot)
	var technique_preview_label: Label = _scene_node("Margin/VBox/Buttons/ActionCardsRow/TechniqueActionCard/TechniqueActionVBox/TechniqueActionPreviewLabel") as Label
	if technique_preview_label != null and _combat_flow != null:
		technique_preview_label.text = _presenter.build_action_card_preview_text(CombatFlowScript.ACTION_TECHNIQUE, _combat_flow.combat_state, {}, preview_snapshot)

	_refresh_inventory_cards(preview_consumable)
	_refresh_hand_swap_panel()
	_refresh_action_button_tooltips(preview_consumable, preview_snapshot)
	_set_buttons_enabled(_combat_flow != null and _presenter.are_action_buttons_enabled(_combat_flow.combat_state))
	_refresh_safe_menu_controls()


func _refresh_hand_swap_panel() -> void:
	var hand_swap_panel: PanelContainer = _combat_secondary_node(HAND_SWAP_PANEL_PATH) as PanelContainer
	if hand_swap_panel == null:
		return
	if _presenter == null or _combat_flow == null or _combat_flow.combat_state == null:
		hand_swap_panel.visible = false
		_selected_hand_swap_slot_name = ""
		_render_hand_swap_candidate_buttons([], "")
		return

	var slot_candidates_by_name := {
		InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND: _combat_flow.get_hand_swap_candidates(InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND),
		InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND: _combat_flow.get_hand_swap_candidates(InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND),
	}
	var surface_model: Dictionary = _presenter.build_hand_swap_surface_model(
		_combat_flow.combat_state,
		slot_candidates_by_name,
		_selected_hand_swap_slot_name
	)
	var is_visible: bool = bool(surface_model.get("visible", false)) and not _transition_requested
	hand_swap_panel.visible = is_visible
	if not is_visible:
		_selected_hand_swap_slot_name = ""
		_render_hand_swap_candidate_buttons([], "")
		return

	_selected_hand_swap_slot_name = String(surface_model.get("selected_slot_name", ""))
	var title_label: Label = _combat_secondary_node(HAND_SWAP_TITLE_PATH) as Label
	if title_label != null:
		title_label.text = String(surface_model.get("title_text", "Hand Swap"))
	var hint_label: Label = _combat_secondary_node(HAND_SWAP_HINT_PATH) as Label
	if hint_label != null:
		hint_label.text = String(surface_model.get("hint_text", "Swap ends turn. Armor and belt stay locked."))

	var slot_models_by_name: Dictionary = {}
	for slot_button_value in surface_model.get("slot_buttons", []):
		if typeof(slot_button_value) != TYPE_DICTIONARY:
			continue
		var slot_button_model: Dictionary = slot_button_value
		slot_models_by_name[String(slot_button_model.get("slot_name", ""))] = slot_button_model

	_refresh_hand_swap_slot_button(
		_combat_secondary_node(RIGHT_HAND_SWAP_BUTTON_PATH) as Button,
		slot_models_by_name.get(InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND, {})
	)
	_refresh_hand_swap_slot_button(
		_combat_secondary_node(LEFT_HAND_SWAP_BUTTON_PATH) as Button,
		slot_models_by_name.get(InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND, {})
	)
	_render_hand_swap_candidate_buttons(surface_model.get("candidate_buttons", []), _selected_hand_swap_slot_name)


func _refresh_hand_swap_slot_button(button: Button, slot_button_model: Dictionary) -> void:
	if button == null:
		return
	var is_visible: bool = not slot_button_model.is_empty()
	button.visible = is_visible
	if not is_visible:
		button.disabled = true
		button.set_pressed_no_signal(false)
		button.tooltip_text = ""
		return
	button.text = String(slot_button_model.get("text", ""))
	button.tooltip_text = String(slot_button_model.get("count_text", ""))
	button.set_pressed_no_signal(bool(slot_button_model.get("selected", false)))
	button.disabled = _combat_flow == null or _combat_flow.combat_state.combat_ended


func _render_hand_swap_candidate_buttons(candidate_button_models: Array, slot_name: String) -> void:
	var candidates_flow: HFlowContainer = _combat_secondary_node(HAND_SWAP_CANDIDATES_FLOW_PATH) as HFlowContainer
	if candidates_flow == null:
		return
	for child in candidates_flow.get_children():
		candidates_flow.remove_child(child)
		child.queue_free()
	if slot_name.is_empty():
		return
	for candidate_value in candidate_button_models:
		if typeof(candidate_value) != TYPE_DICTIONARY:
			continue
		var candidate_model: Dictionary = candidate_value
		var button := Button.new()
		button.text = String(candidate_model.get("text", "Swap"))
		button.tooltip_text = String(candidate_model.get("hint_text", ""))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(160, 42)
		button.disabled = _combat_flow == null or _combat_flow.combat_state.combat_ended
		TempScreenThemeScript.apply_small_button(button, _hand_swap_accent_for_slot(slot_name), false)
		button.connect(
			"pressed",
			Callable(self, "_on_hand_swap_candidate_pressed").bind(
				slot_name,
				int(candidate_model.get("slot_id", -1))
			)
		)
		candidates_flow.add_child(button)


func _hand_swap_accent_for_slot(slot_name: String) -> Color:
	if slot_name == InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND:
		return TempScreenThemeScript.TEAL_ACCENT_COLOR
	return TempScreenThemeScript.RUST_ACCENT_COLOR


func _apply_hand_swap_panel_style() -> void:
	var hand_swap_panel: PanelContainer = _combat_secondary_node(HAND_SWAP_PANEL_PATH) as PanelContainer
	if hand_swap_panel != null:
		TempScreenThemeScript.apply_panel(hand_swap_panel, TempScreenThemeScript.REWARD_ACCENT_COLOR, 14, 0.76)
	var title_label: Label = _combat_secondary_node(HAND_SWAP_TITLE_PATH) as Label
	if title_label != null:
		TempScreenThemeScript.apply_label(title_label, "accent")
	var hint_label: Label = _combat_secondary_node(HAND_SWAP_HINT_PATH) as Label
	if hint_label != null:
		TempScreenThemeScript.apply_label(hint_label, "muted")
	var right_hand_button: Button = _combat_secondary_node(RIGHT_HAND_SWAP_BUTTON_PATH) as Button
	if right_hand_button != null:
		TempScreenThemeScript.apply_small_button(right_hand_button, TempScreenThemeScript.RUST_ACCENT_COLOR, false)
	var left_hand_button: Button = _combat_secondary_node(LEFT_HAND_SWAP_BUTTON_PATH) as Button
	if left_hand_button != null:
		TempScreenThemeScript.apply_small_button(left_hand_button, TempScreenThemeScript.TEAL_ACCENT_COLOR, false)


func _append_status_line(line: String, tone: String = LOG_TONE_NEUTRAL) -> void:
	var normalized_line: String = line.strip_edges()
	if normalized_line.is_empty():
		return
	var dedupe_scan_from: int = max(0, _status_lines.size() - 4)
	for existing_index in range(dedupe_scan_from, _status_lines.size()):
		if _status_lines[existing_index] == normalized_line:
			return
	if _status_lines.size() > 0 and _status_lines[_status_lines.size() - 1] == normalized_line:
		return
	_status_lines.append(normalized_line)
	_status_line_tones.append(tone)
	if _status_lines.size() > 8:
		_status_lines.remove_at(0)
		if not _status_line_tones.is_empty():
			_status_line_tones.remove_at(0)


func _render_combat_log_entries(container: VBoxContainer) -> void:
	var combat_log_entries: VBoxContainer = container if container != null and is_instance_valid(container) else _combat_secondary_node(COMBAT_LOG_ENTRIES_PATH) as VBoxContainer
	if combat_log_entries == null:
		return
	for child in combat_log_entries.get_children():
		combat_log_entries.remove_child(child)
		child.queue_free()
	for index in range(_status_lines.size()):
		var line_text: String = String(_status_lines[index]).strip_edges()
		if line_text.is_empty():
			continue
		var entry_label := Label.new()
		entry_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_label.text = line_text
		TempScreenThemeScript.apply_label(entry_label)
		entry_label.add_theme_font_size_override("font_size", _combat_log_font_size())
		entry_label.add_theme_color_override("font_color", _combat_log_entry_color(_status_line_tones[index] if index < _status_line_tones.size() else LOG_TONE_NEUTRAL))
		combat_log_entries.add_child(entry_label)


func _combat_log_font_size() -> int:
	var viewport_height: float = get_viewport_rect().size.y
	if viewport_height < 1360.0:
		return 12
	if _is_compact_layout or viewport_height < 1720.0:
		return 13
	return 14


func _combat_log_entry_color(tone: String) -> Color:
	match tone:
		LOG_TONE_PLAYER:
			return TempScreenThemeScript.TEAL_ACCENT_COLOR.lightened(0.62)
		LOG_TONE_ENEMY:
			return TempScreenThemeScript.RUST_ACCENT_COLOR.lightened(0.24)
		_:
			return TempScreenThemeScript.TEXT_MUTED_COLOR


func _queue_feedback_for_domain_event(event_name: String, payload: Dictionary) -> void:
	if _presenter == null:
		return

	match event_name:
		"DamageApplied":
			var amount: int = int(payload.get("amount", 0))
			if amount <= 0:
				return
			_pending_phase_feedback_models.append(_presenter.build_impact_feedback_model(String(payload.get("target", "enemy")), amount))
		"GuardGained":
			var guard_points: int = int(payload.get("guard_points", 0))
			if guard_points > 0:
				_pending_phase_feedback_models.append(_presenter.build_guard_delta_feedback_model(guard_points, "guard"))
		"GuardAbsorbed":
			var guard_absorbed: int = int(payload.get("guard_absorbed", 0))
			if guard_absorbed > 0:
				_pending_phase_feedback_models.append(_presenter.build_guard_absorb_feedback_model(guard_absorbed))
		"ConsumableUsed":
			var models: Array[Dictionary] = _presenter.build_recovery_feedback_models(
				int(payload.get("healed_amount", 0)),
				int(payload.get("hunger_restored_amount", 0))
			)
			for model in models:
				_pending_phase_feedback_models.append(model)
		"EnemyIntentRevealed":
			if _feedback_lane != null:
				_feedback_lane.queue_intent_reveal_feedback()
			if _enemy_intent_bust_visuals != null:
				_enemy_intent_bust_visuals.schedule_feedback(false, _is_compact_layout)
		"BossPhaseChanged":
			if _feedback_lane != null:
				_feedback_lane.queue_intent_reveal_feedback(true)
			if _enemy_intent_bust_visuals != null:
				_enemy_intent_bust_visuals.schedule_feedback(true, _is_compact_layout)


func _extract_enemy_max_hp_from_state(combat_state: CombatState) -> int:
	if combat_state == null:
		return 1
	var rules: Dictionary = combat_state.enemy_definition.get("rules", {})
	var stats: Dictionary = rules.get("stats", {})
	return max(1, int(stats.get("base_hp", combat_state.enemy_hp)))


func _set_buttons_enabled(is_enabled: bool) -> void:
	if not is_enabled:
		if _action_hint_controller != null:
			_action_hint_controller.hide_panel(true)
	for button in [
		_attack_button if _attack_button != null and is_instance_valid(_attack_button) else _scene_node(ATTACK_BUTTON_PATH) as Button,
		_defense_button if _defense_button != null and is_instance_valid(_defense_button) else _scene_node(DEFENSE_BUTTON_PATH) as Button,
	]:
		if button != null:
			button.disabled = not is_enabled
	var technique_button: Button = _technique_button if _technique_button != null and is_instance_valid(_technique_button) else _scene_node(TECHNIQUE_BUTTON_PATH) as Button
	if technique_button != null:
		var technique_enabled: bool = is_enabled and _combat_flow != null and _combat_flow.is_technique_available()
		technique_button.disabled = not technique_enabled
	for slot_button_path in [RIGHT_HAND_SWAP_BUTTON_PATH, LEFT_HAND_SWAP_BUTTON_PATH]:
		var slot_button: Button = _combat_secondary_node(slot_button_path) as Button
		if slot_button != null and slot_button.visible:
			slot_button.disabled = not is_enabled
	var candidates_flow: HFlowContainer = _combat_secondary_node(HAND_SWAP_CANDIDATES_FLOW_PATH) as HFlowContainer
	if candidates_flow != null:
		for child in candidates_flow.get_children():
			var candidate_button: Button = child as Button
			if candidate_button != null:
				candidate_button.disabled = not is_enabled


func _get_app_bootstrap() -> AppBootstrapScript:
	return _scene_node("/root/AppBootstrap") as AppBootstrapScript


func _setup_first_run_hint_controller() -> void:
	_first_run_hint_controller = _resolve_first_run_hint_controller()
	if _first_run_hint_controller == null: return
	_first_run_hint_controller.setup(self, COMBAT_HEADER_STACK_PATH, HUNGER_WARNING_Z_INDEX + 10)
	RunMenuSceneHelperScript.sync_tutorial_hints_available(_safe_menu, _first_run_hint_controller)
func _release_first_run_hint_controller_host() -> void:
	if _first_run_hint_controller == null: return
	_first_run_hint_controller.release_host(self)
	_first_run_hint_controller = null
	RunMenuSceneHelperScript.sync_tutorial_hints_available(_safe_menu, _first_run_hint_controller)
func _request_first_run_hint(hint_id: String) -> void:
	if _first_run_hint_controller == null:
		_setup_first_run_hint_controller()
	if _first_run_hint_controller == null: return
	_first_run_hint_controller.request_hint(hint_id)
func _scan_first_run_inventory_hints() -> void:
	if _first_run_hint_controller == null:
		_setup_first_run_hint_controller()
	if _first_run_hint_controller == null or _run_state == null: return
	_first_run_hint_controller.scan_inventory_hints(_run_state.inventory_state)


func _request_contextual_combat_hints() -> void:
	if _combat_flow == null or _combat_flow.combat_state == null:
		return
	if _combat_flow.has_equipped_technique():
		_request_first_run_hint("first_combat_technique")
	if _combat_flow.has_any_hand_swap_candidates():
		_request_first_run_hint("first_combat_hand_swap")


func _resolve_first_run_hint_controller() -> FirstRunHintController:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null: return null
	bootstrap.ensure_run_state_initialized()
	var coordinator: RefCounted = bootstrap.run_session_coordinator
	if coordinator == null: return null
	return coordinator.get("_first_run_hint_controller") as FirstRunHintController

func _on_disable_tutorial_hints_pressed() -> void:
	if _first_run_hint_controller == null:
		_setup_first_run_hint_controller()
	if _first_run_hint_controller == null: return
	var changed: bool = _first_run_hint_controller.mark_all_hints_shown()
	RunMenuSceneHelperScript.sync_tutorial_hints_available(_safe_menu, _first_run_hint_controller)
	if _safe_menu != null:
		_safe_menu.set_status_text(RunMenuSceneHelperScript.build_tutorial_hints_status_text(changed))
func _on_save_pressed() -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null: return
	var save_result: Dictionary = bootstrap.save_game()
	if _safe_menu != null:
		_safe_menu.set_status_text(RunMenuSceneHelperScript.build_save_status_text(save_result))
	_refresh_safe_menu_controls()
func _on_load_pressed() -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null: return
	var load_result: Dictionary = bootstrap.load_game()
	if bool(load_result.get("ok", false)): return
	if _safe_menu != null:
		_safe_menu.set_status_text(RunMenuSceneHelperScript.build_load_failure_status_text(load_result))
	_refresh_safe_menu_controls()
func _on_return_to_main_menu_pressed() -> void:
	var bootstrap = _get_app_bootstrap()
	var flow_manager = bootstrap.get_flow_manager() if bootstrap != null else null
	if flow_manager != null: flow_manager.request_transition(FlowStateScript.Type.MAIN_MENU)
func _refresh_safe_menu_controls() -> void:
	RunMenuSceneHelperScript.sync_load_available(_safe_menu, _get_app_bootstrap())
	RunMenuSceneHelperScript.sync_tutorial_hints_available(_safe_menu, _first_run_hint_controller)


func _setup_safe_menu() -> void:
	var menu_config: Dictionary = RunMenuSceneHelperScript.shared_menu_config()
	_safe_menu = RunMenuSceneHelperScript.ensure_safe_menu(
		self,
		_safe_menu,
		String(menu_config.get("title_text", RunMenuSceneHelperScript.SHARED_MENU_TITLE)),
		String(menu_config.get("subtitle_text", RunMenuSceneHelperScript.SHARED_MENU_SUBTITLE)),
		String(menu_config.get("launcher_text", RunMenuSceneHelperScript.SHARED_LAUNCHER_TEXT)),
		Callable(self, "_on_save_pressed"),
		Callable(self, "_on_load_pressed"),
		Callable(self, "_on_return_to_main_menu_pressed"),
		Callable(self, "_on_disable_tutorial_hints_pressed")
	)
	if _safe_menu != null: _safe_menu.set_main_menu_enabled(false)
func _first_consumable_slot(combat_state: CombatState) -> Dictionary:
	for slot_value in combat_state.consumable_slots:
		var slot: Dictionary = slot_value
		if int(slot.get("current_stack", 0)) > 0:
			return slot
	return {}


func _sync_selected_consumable_slot_index() -> void:
	if _combat_flow == null:
		_selected_consumable_slot_index = -1
		return
	if _combat_flow.is_consumable_slot_usable(_selected_consumable_slot_index):
		return
	_selected_consumable_slot_index = _combat_flow.find_first_usable_consumable_slot_index()


func _has_selected_usable_consumable() -> bool:
	return _combat_flow != null and _combat_flow.is_consumable_slot_usable(_selected_consumable_slot_index)


func _play_action_start_sfx(action_name: String) -> void:
	match action_name:
		CombatFlowScript.ACTION_ATTACK:
			SceneAudioPlayersScript.play(self, "AttackResolveSfxPlayer")
		CombatFlowScript.ACTION_DEFEND:
			SceneAudioPlayersScript.play(self, "DefendSfxPlayer")
		CombatFlowScript.ACTION_TECHNIQUE:
			SceneAudioPlayersScript.play(self, "ItemUseSfxPlayer")
		CombatFlowScript.ACTION_SWAP_HAND:
			SceneAudioPlayersScript.play(self, "ItemUseSfxPlayer")
		CombatFlowScript.ACTION_USE_ITEM:
			if _has_selected_usable_consumable():
				SceneAudioPlayersScript.play(self, "ItemUseSfxPlayer")


func _preview_consumable_slot() -> Dictionary:
	if _combat_flow == null:
		return {}

	if _selected_consumable_slot_index >= 0 and _selected_consumable_slot_index < _combat_flow.combat_state.consumable_slots.size():
		return _combat_flow.combat_state.consumable_slots[_selected_consumable_slot_index]
	return _first_consumable_slot(_combat_flow.combat_state)


func _inventory_card_is_clickable(card_model: Dictionary) -> bool:
	if _combat_flow == null:
		return false
	var card_family: String = String(card_model.get("card_family", ""))
	match card_family:
		"consumable":
			return _combat_flow.is_consumable_slot_usable(int(card_model.get("slot_index", -1)))
		_:
			return false


func _inventory_card_is_draggable(card_model: Dictionary) -> bool:
	return false


func _inventory_card_is_selected(card_model: Dictionary) -> bool:
	if String(card_model.get("card_family", "")) != "consumable":
		return false
	var slot_index: int = int(card_model.get("slot_index", -1))
	return _combat_flow != null and _combat_flow.is_consumable_slot_usable(slot_index) and slot_index == _selected_consumable_slot_index


func _decorate_combat_equipment_cards_for_hand_swap(equipment_cards: Array[Dictionary]) -> Array[Dictionary]:
	var decorated_cards: Array[Dictionary] = []
	for equipment_card in equipment_cards:
		var decorated_card: Dictionary = equipment_card.duplicate(true)
		var slot_name: String = _resolve_equipment_slot_name_from_card(decorated_card)
		if not slot_name.is_empty() and _combat_flow != null and _combat_flow.has_hand_swap_candidates(slot_name):
			decorated_card["combat_action_hint_override"] = "Swap below"
		decorated_cards.append(decorated_card)
	return decorated_cards


func _resolve_equipment_slot_name_from_card(card_model: Dictionary) -> String:
	match String(card_model.get("slot_label", "")):
		"RIGHT HAND":
			return InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND
		"LEFT HAND":
			return InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND
		"ARMOR":
			return InventoryStateScript.EQUIPMENT_SLOT_ARMOR
		"BELT":
			return InventoryStateScript.EQUIPMENT_SLOT_BELT
		_:
			return ""


func _refresh_inventory_cards(preview_consumable: Dictionary = {}) -> void:
	if _run_inventory_panel == null:
		return

	if _action_hint_controller != null:
		_action_hint_controller.hide_panel(true)
	var inventory_presenter: InventoryPresenter = _run_inventory_panel.get_presenter()
	if inventory_presenter == null:
		return
	var inventory_title_text: String = inventory_presenter.build_inventory_title_text(_run_state.inventory_state if _run_state != null else null)
	var inventory_hint_text: String = inventory_presenter.build_combat_inventory_hint_text()
	if _presenter != null:
		inventory_title_text = _presenter.build_combat_quickbar_title_text()
		inventory_hint_text = _presenter.build_combat_quickbar_hint_text(
			_combat_flow.combat_state if _combat_flow != null else null,
			preview_consumable
		)
	var equipment_cards: Array[Dictionary] = inventory_presenter.build_combat_equipment_cards(
		_combat_flow.combat_state if _combat_flow != null else null,
		_run_state.inventory_state if _run_state != null else null
	)
	equipment_cards = _decorate_combat_equipment_cards_for_hand_swap(equipment_cards)
	_run_inventory_panel.render({
		"equipment_title": inventory_presenter.build_equipment_title_text(),
		"equipment_hint": (
			_presenter.build_combat_equipment_hint_text()
			if _presenter != null
			else inventory_presenter.build_equipment_hint_text(true)
		),
		"equipment_hint_visible": true,
		"inventory_title": inventory_title_text,
		"inventory_hint": inventory_hint_text,
		"inventory_hint_visible": true,
		"equipment_cards": equipment_cards,
		"backpack_cards": inventory_presenter.build_combat_inventory_cards(
			_combat_flow.combat_state if _combat_flow != null else null,
			_run_state.inventory_state if _run_state != null else null
		),
		"layout_density": "map",
		"card_compact_mode_override": false,
		"clickable_resolver": Callable(self, "_inventory_card_is_clickable"),
		"selected_resolver": Callable(self, "_inventory_card_is_selected"),
		"draggable_resolver": Callable(self, "_inventory_card_is_draggable"),
	})
	_scan_first_run_inventory_hints()


func _handle_inventory_card_click(slot_index: int, inventory_slot_id: int, card_family: String) -> void:
	if _combat_flow == null:
		return
	match card_family:
		"consumable":
			if not _combat_flow.is_consumable_slot_usable(slot_index):
				_append_status_line("That item will not change HP or hunger right now.")
				_refresh_ui()
				return
			_resolve_player_turn(CombatFlowScript.ACTION_USE_ITEM, slot_index)
		"weapon", "shield", "armor", "belt", "quest_item", "shield_attachment":
			_append_status_line("Only hand swaps are legal in combat. Swap ends turn. Armor and belt stay locked.")
			_refresh_ui()
		_:
			return


func _on_inventory_card_drag_started() -> void:
	if _action_hint_controller != null:
		_action_hint_controller.hide_panel(true)


func _handle_inventory_card_drag_completed(inventory_slot_id: int, target_index: int) -> void:
	if inventory_slot_id >= 0 or target_index >= 0:
		_append_status_line("Backpack order is locked during combat.")
	_refresh_ui()


func _resolve_turn_phase_log_tone(phase_name: String, action_name: String, result: Dictionary) -> String:
	match phase_name:
		CombatFlowScript.PHASE_PLAYER_ACTION:
			if action_name == CombatFlowScript.ACTION_USE_ITEM and bool(result.get("skipped", false)):
				return LOG_TONE_NEUTRAL
			return LOG_TONE_PLAYER
		CombatFlowScript.PHASE_ENEMY_ACTION:
			return LOG_TONE_ENEMY
		_:
			return LOG_TONE_NEUTRAL


func _resolve_domain_event_log_tone(event_name: String, payload: Dictionary) -> String:
	match event_name:
		"DamageApplied", "StatusApplied", "StatusTicked":
			return LOG_TONE_PLAYER if String(payload.get("target", "")) == "enemy" else LOG_TONE_ENEMY
		"GuardGained", "ConsumableUsed":
			return LOG_TONE_PLAYER
		"EnemyIntentRevealed", "BossPhaseChanged":
			return LOG_TONE_ENEMY
		_:
			return LOG_TONE_NEUTRAL


func _should_show_combat_log() -> bool:
	for line in _status_lines:
		var normalized_line: String = String(line).strip_edges()
		if normalized_line.is_empty():
			continue
		return true
	return false

func _render_status_chips(container: Container, chip_texts: PackedStringArray) -> void:
	if container == null:
		return

	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

	for chip_text in chip_texts:
		var panel: PanelContainer = PanelContainer.new()
		var label: Label = Label.new()
		label.text = chip_text
		panel.add_child(label)
		container.add_child(panel)
		TempScreenThemeScript.apply_chip(panel, label)


func _ensure_player_guard_badge() -> void:
	if _player_guard_badge == null:
		_player_guard_badge = CombatGuardBadgeScript.new()
	_player_guard_badge.setup(self, Callable(self, "_scene_node"), PLAYER_INFO_VBOX_PATH, PLAYER_RUN_SUMMARY_CARD_PATH)


func _style_player_guard_badge() -> void:
	if _player_guard_badge != null:
		_player_guard_badge.refresh_style()


func _apply_player_guard_badge_layout() -> void:
	if _player_guard_badge != null:
		_player_guard_badge.apply_layout(_is_compact_layout)


func _refresh_player_guard_badge() -> void:
	_ensure_player_guard_badge()
	if _player_guard_badge == null:
		return

	var current_guard: int = max(0, int(_combat_flow.combat_state.current_guard)) if _combat_flow != null else 0
	var badge_text: String = _presenter.build_guard_badge_text(current_guard) if _presenter != null else "Guard: %d" % current_guard
	_player_guard_badge.refresh(current_guard, badge_text, _is_compact_layout)

func _ensure_hunger_warning_toast() -> void:
	if _hunger_warning_toast == null:
		_hunger_warning_toast = HungerWarningToastScript.new()
	_hunger_warning_toast.setup(self, COMBAT_HEADER_STACK_PATH, HUNGER_WARNING_Z_INDEX, _is_compact_layout)

func _on_hunger_threshold_crossed(_old_threshold: int, new_threshold: int) -> void:
	var warning_text: String = RunStatusStripScript.build_hunger_threshold_warning_text(new_threshold)
	if warning_text.is_empty():
		return
	_ensure_hunger_warning_toast()
	if _hunger_warning_toast != null:
		_hunger_warning_toast.show_warning(warning_text, new_threshold)
	_request_first_run_hint("first_low_hunger_warning")


func _queue_guard_decay_feedback_from_turn_end(turn_end_result: Dictionary) -> void:
	if _presenter == null:
		return
	var retained_guard: int = max(0, int(turn_end_result.get("guard_points", 0)))
	var guard_before_decay: int = max(0, _guard_before_turn_end_phase)
	var decayed_guard: int = max(0, guard_before_decay - retained_guard)
	if decayed_guard > 0:
		var guard_decay_model: Dictionary = _presenter.build_guard_decay_feedback_model(decayed_guard)
		if not guard_decay_model.is_empty():
			_pending_phase_feedback_models.append(guard_decay_model)
	_guard_before_turn_end_phase = retained_guard


func _status_chip_list_has_entry(chip_texts: PackedStringArray) -> bool:
	for chip_text in chip_texts:
		if not String(chip_text).strip_edges().is_empty():
			return true
	return false


func _apply_bust_texture(frame_path: String, texture_path: String, asset_path: String) -> void:
	var frame: Control = _scene_node(frame_path) as Control
	var texture_rect: TextureRect = _scene_node(texture_path) as TextureRect
	if frame == null or texture_rect == null:
		return

	var texture: Texture2D = SceneLayoutHelperScript.load_texture_or_null(asset_path)
	texture_rect.texture = texture
	texture_rect.visible = texture != null
	texture_rect.modulate = Color(1, 1, 1, 1)
	frame.visible = texture != null


func _apply_texture_rect_asset(node_path: String, asset_path: String) -> void:
	var texture_rect: TextureRect = _scene_node(node_path) as TextureRect
	if texture_rect == null:
		return

	var texture: Texture2D = SceneLayoutHelperScript.load_texture_or_null(asset_path)
	texture_rect.texture = texture
	texture_rect.visible = texture != null


func _refresh_action_button_tooltips(preview_consumable: Dictionary, preview_snapshot: Dictionary = {}) -> void:
	var attack_button: Button = _attack_button if _attack_button != null and is_instance_valid(_attack_button) else _scene_node(ATTACK_BUTTON_PATH) as Button
	var defense_button: Button = _defense_button if _defense_button != null and is_instance_valid(_defense_button) else _scene_node(DEFENSE_BUTTON_PATH) as Button
	var technique_button: Button = _technique_button if _technique_button != null and is_instance_valid(_technique_button) else _scene_node(TECHNIQUE_BUTTON_PATH) as Button
	var combat_state: CombatState = _combat_flow.combat_state if _combat_flow != null else null
	if _action_hint_controller != null:
		_action_hint_controller.refresh_button_tooltips(
			attack_button,
			defense_button,
			technique_button,
			null,
			_presenter,
			combat_state,
			preview_consumable,
			preview_snapshot
		)


func _apply_temp_theme() -> void:
	CombatSceneUiScript.apply_temp_theme(self, Callable(self, "_combat_secondary_node"))
	_style_player_guard_badge()
	if _hunger_warning_toast != null:
		_hunger_warning_toast.set_compact_layout(_is_compact_layout)
	if _enemy_intent_bust_visuals != null:
		_enemy_intent_bust_visuals.refresh(_combat_flow.get_current_intent() if _combat_flow != null else {}, _presenter, _is_compact_layout)


func _on_viewport_size_changed() -> void:
	_apply_portrait_safe_layout()
	if _action_hint_controller != null:
		_action_hint_controller.update_visibility()
	if _first_run_hint_controller != null:
		_first_run_hint_controller.refresh_position()
	if _hunger_warning_toast != null:
		_hunger_warning_toast.position_toast()


func _apply_portrait_safe_layout() -> void:
	var layout_result: Dictionary = CombatSceneUiScript.apply_portrait_safe_layout(self, Callable(self, "_combat_secondary_node"))
	_is_compact_layout = bool(layout_result.get("is_compact_layout", false))
	_apply_player_guard_badge_layout()
	if _hunger_warning_toast != null:
		_hunger_warning_toast.set_compact_layout(_is_compact_layout)
		_hunger_warning_toast.position_toast()
	if _enemy_intent_bust_visuals != null:
		_enemy_intent_bust_visuals.ensure_badge(_is_compact_layout)
		_enemy_intent_bust_visuals.refresh(_combat_flow.get_current_intent() if _combat_flow != null else {}, _presenter, _is_compact_layout)
	if _action_hint_controller != null:
		_action_hint_controller.update_visibility()
