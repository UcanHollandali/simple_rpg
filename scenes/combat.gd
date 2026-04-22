# Layer: Scenes - presentation only
extends Control

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const CombatFlowScript = preload("res://Game/Application/combat_flow.gd")
const CombatPresenterScript = preload("res://Game/UI/combat_presenter.gd")
const CombatSceneUiScript = preload("res://Game/UI/combat_scene_ui.gd")
const CombatSceneShellScript = preload("res://Game/UI/combat_scene_shell.gd")
const CombatFeedbackLaneScript = preload("res://Game/UI/combat_feedback_lane.gd")
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
const PLAYER_GUARD_BADGE_PANEL_NAME := "PlayerGuardBadgePanel"
const PLAYER_GUARD_BADGE_LABEL_NAME := "PlayerGuardBadgeLabel"
const HUNGER_WARNING_PANEL_NAME := "HungerWarningToast"
const HUNGER_WARNING_LABEL_NAME := "HungerWarningLabel"
const ATTACK_BUTTON_PATH := "Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackButton"
const DEFENSE_BUTTON_PATH := "Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionButton"
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
const PLAYER_GUARD_BADGE_TWEEN_META_KEY := "player_guard_badge_tween"
const HUNGER_WARNING_Z_INDEX := 125
const HUNGER_WARNING_SHOW_DURATION := 2.0
const HUNGER_WARNING_MARGIN := 16.0
const HUNGER_WARNING_TOP_GAP := 12.0
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
var _player_guard_badge_panel: PanelContainer
var _player_guard_badge_label: Label
var _selected_consumable_slot_index: int = -1
var _pending_phase_feedback_models: Array[Dictionary] = []
var _is_compact_layout: bool = false
var _last_rendered_guard: int = -1
var _guard_before_turn_end_phase: int = -1
var _run_status_strip: RunStatusStrip
var _safe_menu: SafeMenuOverlay
var _hunger_warning_panel: PanelContainer
var _hunger_warning_label: Label
var _hunger_warning_tween: Tween
var _scene_node_cache: Dictionary = {}

@onready var _root_vbox: Control = _scene_node("Margin/VBox") as Control
@onready var _combat_secondary_scroll_content: Control = _scene_node(COMBAT_SECONDARY_SCROLL_CONTENT_PATH) as Control
@onready var _header_stack: Control = _scene_node(COMBAT_HEADER_STACK_PATH) as Control
@onready var _turn_label: Label = _scene_node("Margin/VBox/HeaderStack/TurnLabel") as Label
@onready var _attack_button: Button = _scene_node(ATTACK_BUTTON_PATH) as Button
@onready var _defense_button: Button = _scene_node(DEFENSE_BUTTON_PATH) as Button
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
	_append_status_line("Combat ready.")
	SceneAudioPlayersScript.start_looping(self, "CombatMusicPlayer")
	_refresh_ui()


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
	if _hunger_warning_tween != null and is_instance_valid(_hunger_warning_tween):
		_hunger_warning_tween.kill()
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_on_viewport_size_changed"))
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


func _on_attack_pressed() -> void:
	_resolve_player_turn(CombatFlowScript.ACTION_ATTACK)


func _on_defend_pressed() -> void:
	_resolve_player_turn(CombatFlowScript.ACTION_DEFEND)


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

	var intent_title_label: Label = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentTitleLabel") as Label
	if intent_title_label != null:
		intent_title_label.text = _presenter.build_intent_title_text()
	var intent_label: Label = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentRow/IntentLabel") as Label
	if intent_label != null and _combat_flow != null:
		var current_intent: Dictionary = _combat_flow.get_current_intent()
		intent_label.text = _presenter.build_intent_summary_text(current_intent, preview_snapshot)
		_apply_texture_rect_asset(
			"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentRow/IntentIcon",
			_presenter.build_intent_icon_texture_path(current_intent)
		)
	var intent_detail_label: Label = _scene_node("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentDetailLabel") as Label
	if intent_detail_label != null and _combat_flow != null:
		var intent_detail_text: String = _presenter.build_intent_detail_text(_combat_flow.get_current_intent())
		intent_detail_label.text = intent_detail_text
		intent_detail_label.visible = not intent_detail_text.is_empty()

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
	var action_section_title_label: Label = _scene_node("Margin/VBox/Buttons/ActionSectionTitleLabel") as Label
	if action_section_title_label != null:
		action_section_title_label.text = "Pick Your Move"
	var attack_eyebrow_label: Label = _scene_node("Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackActionEyebrowLabel") as Label
	if attack_eyebrow_label != null:
		attack_eyebrow_label.text = "DEAL DAMAGE"
	var defense_eyebrow_label: Label = _scene_node("Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionEyebrowLabel") as Label
	if defense_eyebrow_label != null:
		defense_eyebrow_label.text = "BLOCK THE HIT"
	var attack_preview_label: Label = _scene_node("Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackActionPreviewLabel") as Label
	if attack_preview_label != null:
		attack_preview_label.text = _presenter.build_action_card_preview_text(CombatFlowScript.ACTION_ATTACK, _combat_flow.combat_state if _combat_flow != null else null, {}, preview_snapshot)
	var defense_preview_label: Label = _scene_node("Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionPreviewLabel") as Label
	if defense_preview_label != null:
		defense_preview_label.text = _presenter.build_action_card_preview_text(CombatFlowScript.ACTION_DEFEND, _combat_flow.combat_state if _combat_flow != null else null, {}, preview_snapshot)

	_refresh_inventory_cards()
	_refresh_action_button_tooltips(preview_consumable, preview_snapshot)
	_set_buttons_enabled(_combat_flow != null and _presenter.are_action_buttons_enabled(_combat_flow.combat_state))
	_refresh_safe_menu_controls()


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
		"BossPhaseChanged":
			if _feedback_lane != null:
				_feedback_lane.queue_intent_reveal_feedback(true)


func _kill_control_tween(control: Control, meta_key: String) -> void:
	if control == null or not control.has_meta(meta_key):
		return
	var tween_value: Variant = control.get_meta(meta_key, null)
	if tween_value is Tween:
		var tween: Tween = tween_value as Tween
		if is_instance_valid(tween):
			tween.kill()
	control.remove_meta(meta_key)


func _clear_control_meta(control: Control, meta_key: String) -> void:
	if control == null or not is_instance_valid(control):
		return
	if control.has_meta(meta_key):
		control.remove_meta(meta_key)


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


func _get_app_bootstrap() -> AppBootstrapScript:
	return _scene_node("/root/AppBootstrap") as AppBootstrapScript


func _on_save_pressed() -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return
	var save_result: Dictionary = bootstrap.save_game()
	if _safe_menu != null:
		_safe_menu.set_status_text(RunMenuSceneHelperScript.build_save_status_text(save_result))
	_refresh_safe_menu_controls()


func _on_load_pressed() -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return
	var load_result: Dictionary = bootstrap.load_game()
	if bool(load_result.get("ok", false)):
		return
	if _safe_menu != null:
		_safe_menu.set_status_text(RunMenuSceneHelperScript.build_load_failure_status_text(load_result))
	_refresh_safe_menu_controls()


func _on_return_to_main_menu_pressed() -> void:
	var bootstrap = _get_app_bootstrap()
	var flow_manager = bootstrap.get_flow_manager() if bootstrap != null else null
	if flow_manager != null: flow_manager.request_transition(FlowStateScript.Type.MAIN_MENU)


func _refresh_safe_menu_controls() -> void:
	RunMenuSceneHelperScript.sync_load_available(_safe_menu, _get_app_bootstrap())


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
		Callable(self, "_on_return_to_main_menu_pressed")
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


func _refresh_inventory_cards() -> void:
	if _run_inventory_panel == null:
		return

	if _action_hint_controller != null:
		_action_hint_controller.hide_panel(true)
	var inventory_presenter: InventoryPresenter = _run_inventory_panel.get_presenter()
	if inventory_presenter == null:
		return
	_run_inventory_panel.render({
		"equipment_title": inventory_presenter.build_equipment_title_text(),
		"equipment_hint": inventory_presenter.build_equipment_hint_text(true),
		"equipment_hint_visible": true,
		"inventory_title": inventory_presenter.build_inventory_title_text(_run_state.inventory_state if _run_state != null else null),
		"inventory_hint": inventory_presenter.build_combat_inventory_hint_text(),
		"inventory_hint_visible": true,
		"equipment_cards": inventory_presenter.build_combat_equipment_cards(
			_combat_flow.combat_state if _combat_flow != null else null,
			_run_state.inventory_state if _run_state != null else null
		),
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
			_append_status_line("Equipment is locked during combat.")
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
	var info_vbox: VBoxContainer = _player_info_vbox if _player_info_vbox != null and is_instance_valid(_player_info_vbox) else _scene_node(PLAYER_INFO_VBOX_PATH) as VBoxContainer
	if info_vbox == null:
		return

	if _player_guard_badge_panel == null or not is_instance_valid(_player_guard_badge_panel):
		_player_guard_badge_panel = info_vbox.get_node_or_null(PLAYER_GUARD_BADGE_PANEL_NAME) as PanelContainer
	if _player_guard_badge_panel == null:
		_player_guard_badge_panel = PanelContainer.new()
		_player_guard_badge_panel.name = PLAYER_GUARD_BADGE_PANEL_NAME
		_player_guard_badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_player_guard_badge_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_player_guard_badge_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		info_vbox.add_child(_player_guard_badge_panel)

	if _player_guard_badge_label == null or not is_instance_valid(_player_guard_badge_label):
		_player_guard_badge_label = _player_guard_badge_panel.get_node_or_null(PLAYER_GUARD_BADGE_LABEL_NAME) as Label
	if _player_guard_badge_label == null:
		_player_guard_badge_label = Label.new()
		_player_guard_badge_label.name = PLAYER_GUARD_BADGE_LABEL_NAME
		_player_guard_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_player_guard_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_player_guard_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_player_guard_badge_panel.add_child(_player_guard_badge_label)

	var player_run_summary_card: PanelContainer = _player_run_summary_card if _player_run_summary_card != null and is_instance_valid(_player_run_summary_card) else _scene_node(PLAYER_RUN_SUMMARY_CARD_PATH) as PanelContainer
	if player_run_summary_card != null:
		info_vbox.move_child(_player_guard_badge_panel, min(info_vbox.get_child_count() - 1, player_run_summary_card.get_index() + 1))

	_style_player_guard_badge()
	_apply_player_guard_badge_layout()
	if _last_rendered_guard < 0:
		_finish_hiding_player_guard_badge()


func _style_player_guard_badge() -> void:
	if _player_guard_badge_panel == null or _player_guard_badge_label == null:
		return
	TempScreenThemeScript.apply_chip(_player_guard_badge_panel, _player_guard_badge_label, TempScreenThemeScript.TEAL_ACCENT_COLOR)
	TempScreenThemeScript.apply_label(_player_guard_badge_label)
	_player_guard_badge_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	_player_guard_badge_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.84))
	_player_guard_badge_label.add_theme_constant_override("outline_size", 4)


func _apply_player_guard_badge_layout() -> void:
	if _player_guard_badge_panel == null or _player_guard_badge_label == null:
		return
	var viewport_height: float = get_viewport_rect().size.y
	var font_size: int = 16 if _is_compact_layout else 18
	if viewport_height < 1500.0:
		font_size = 15 if _is_compact_layout else 16
	elif viewport_height >= 1800.0 and not _is_compact_layout:
		font_size = 19
	_player_guard_badge_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_player_guard_badge_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_player_guard_badge_label.add_theme_font_size_override("font_size", font_size)


func _refresh_player_guard_badge() -> void:
	_ensure_player_guard_badge()
	if _player_guard_badge_panel == null or _player_guard_badge_label == null:
		return

	var current_guard: int = max(0, int(_combat_flow.combat_state.current_guard)) if _combat_flow != null else 0
	_player_guard_badge_label.text = _presenter.build_guard_badge_text(current_guard) if _presenter != null else "Guard: %d" % current_guard
	_apply_player_guard_badge_layout()

	if _last_rendered_guard < 0:
		_last_rendered_guard = current_guard
		if current_guard > 0:
			_player_guard_badge_panel.visible = true
			_player_guard_badge_panel.modulate = Color(1, 1, 1, 1)
			_player_guard_badge_panel.scale = Vector2.ONE
		else:
			_finish_hiding_player_guard_badge()
		return

	if current_guard <= 0:
		if _last_rendered_guard > 0 or _player_guard_badge_panel.visible:
			_hide_player_guard_badge()
		else:
			_finish_hiding_player_guard_badge()
		_last_rendered_guard = 0
		return

	var should_pop: bool = _last_rendered_guard <= 0 or current_guard > _last_rendered_guard
	_show_player_guard_badge(should_pop)
	_last_rendered_guard = current_guard


func _show_player_guard_badge(pop_badge: bool = false) -> void:
	if _player_guard_badge_panel == null:
		return
	_kill_control_tween(_player_guard_badge_panel, PLAYER_GUARD_BADGE_TWEEN_META_KEY)
	_player_guard_badge_panel.pivot_offset = _player_guard_badge_panel.get_combined_minimum_size() * 0.5
	var needs_fade_in: bool = not _player_guard_badge_panel.visible or _player_guard_badge_panel.modulate.a < 0.99
	_player_guard_badge_panel.visible = true
	if not needs_fade_in and not pop_badge:
		_player_guard_badge_panel.modulate = Color(1, 1, 1, 1)
		_player_guard_badge_panel.scale = Vector2.ONE
		return

	_player_guard_badge_panel.modulate = Color(1, 1, 1, 0) if needs_fade_in else Color(1, 1, 1, 1)
	_player_guard_badge_panel.scale = Vector2.ONE * (0.88 if pop_badge else 0.96)
	var tween: Tween = create_tween()
	_player_guard_badge_panel.set_meta(PLAYER_GUARD_BADGE_TWEEN_META_KEY, tween)
	tween.parallel().tween_property(_player_guard_badge_panel, "modulate", Color(1, 1, 1, 1), 0.16)
	tween.parallel().tween_property(_player_guard_badge_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(Callable(self, "_clear_control_meta").bind(_player_guard_badge_panel, PLAYER_GUARD_BADGE_TWEEN_META_KEY), CONNECT_ONE_SHOT)


func _hide_player_guard_badge() -> void:
	if _player_guard_badge_panel == null:
		return
	_kill_control_tween(_player_guard_badge_panel, PLAYER_GUARD_BADGE_TWEEN_META_KEY)
	if not _player_guard_badge_panel.visible:
		_finish_hiding_player_guard_badge()
		return
	_player_guard_badge_panel.pivot_offset = _player_guard_badge_panel.get_combined_minimum_size() * 0.5
	var tween: Tween = create_tween()
	_player_guard_badge_panel.set_meta(PLAYER_GUARD_BADGE_TWEEN_META_KEY, tween)
	tween.parallel().tween_property(_player_guard_badge_panel, "modulate", Color(1, 1, 1, 0), 0.14)
	tween.parallel().tween_property(_player_guard_badge_panel, "scale", Vector2.ONE * 0.94, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(Callable(self, "_finish_hiding_player_guard_badge"), CONNECT_ONE_SHOT)

func _finish_hiding_player_guard_badge() -> void:
	if _player_guard_badge_panel == null or not is_instance_valid(_player_guard_badge_panel):
		return
	_player_guard_badge_panel.visible = false
	_player_guard_badge_panel.modulate = Color(1, 1, 1, 0)
	_player_guard_badge_panel.scale = Vector2.ONE
	_clear_control_meta(_player_guard_badge_panel, PLAYER_GUARD_BADGE_TWEEN_META_KEY)

func _ensure_hunger_warning_toast() -> void:
	if _hunger_warning_panel != null and is_instance_valid(_hunger_warning_panel):
		_apply_hunger_warning_style(RunStatusStripScript.HUNGER_THRESHOLD_HUNGRY)
		_position_hunger_warning_toast()
		return

	_hunger_warning_panel = PanelContainer.new()
	_hunger_warning_panel.name = HUNGER_WARNING_PANEL_NAME
	_hunger_warning_panel.visible = false
	_hunger_warning_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hunger_warning_panel.top_level = true
	_hunger_warning_panel.z_index = HUNGER_WARNING_Z_INDEX
	_hunger_warning_panel.modulate = Color(1, 1, 1, 0)
	add_child(_hunger_warning_panel)

	_hunger_warning_label = Label.new()
	_hunger_warning_label.name = HUNGER_WARNING_LABEL_NAME
	_hunger_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hunger_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hunger_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hunger_warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hunger_warning_panel.add_child(_hunger_warning_label)
	_apply_hunger_warning_style(RunStatusStripScript.HUNGER_THRESHOLD_HUNGRY)
	_finish_hiding_hunger_warning()

func _apply_hunger_warning_style(threshold: int) -> void:
	if _hunger_warning_panel == null or _hunger_warning_label == null:
		return
	var accent: Color = RunStatusStripScript.resolve_hunger_threshold_accent(threshold)
	TempScreenThemeScript.apply_panel(_hunger_warning_panel, accent, 16, 0.94)
	TempScreenThemeScript.apply_label(_hunger_warning_label, "muted")
	_hunger_warning_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	_hunger_warning_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.04, 0.76))
	_hunger_warning_label.add_theme_constant_override("shadow_size", 2)
	var font_size: int = 18 if not _is_compact_layout else 17
	var viewport_height: float = get_viewport_rect().size.y
	if viewport_height < 1400.0:
		font_size = 16 if not _is_compact_layout else 15
	elif viewport_height >= 1800.0 and not _is_compact_layout:
		font_size = 20
	_hunger_warning_label.add_theme_font_size_override("font_size", font_size)

func _on_hunger_threshold_crossed(_old_threshold: int, new_threshold: int) -> void:
	var warning_text: String = RunStatusStripScript.build_hunger_threshold_warning_text(new_threshold)
	if warning_text.is_empty():
		return
	_show_hunger_warning(warning_text, new_threshold)

func _show_hunger_warning(warning_text: String, threshold: int) -> void:
	_ensure_hunger_warning_toast()
	if _hunger_warning_panel == null or _hunger_warning_label == null:
		return
	if _hunger_warning_tween != null and is_instance_valid(_hunger_warning_tween):
		_hunger_warning_tween.kill()
	_hunger_warning_label.text = warning_text
	_apply_hunger_warning_style(threshold)
	_hunger_warning_panel.custom_minimum_size = Vector2(max(220.0, min(get_viewport_rect().size.x - (HUNGER_WARNING_MARGIN * 2.0), 420.0)), 0.0)
	_hunger_warning_label.custom_minimum_size = Vector2(max(200.0, _hunger_warning_panel.custom_minimum_size.x - 20.0), 0.0)
	_hunger_warning_panel.size = _hunger_warning_panel.get_combined_minimum_size()
	_position_hunger_warning_toast()
	_hunger_warning_panel.visible = true
	_hunger_warning_panel.pivot_offset = _hunger_warning_panel.size * 0.5
	_hunger_warning_panel.scale = Vector2(0.96, 0.96)
	_hunger_warning_panel.modulate = Color(1, 1, 1, 0)

	_hunger_warning_tween = create_tween()
	_hunger_warning_tween.parallel().tween_property(_hunger_warning_panel, "modulate", Color(1, 1, 1, 1), 0.16)
	_hunger_warning_tween.parallel().tween_property(_hunger_warning_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hunger_warning_tween.tween_interval(HUNGER_WARNING_SHOW_DURATION)
	_hunger_warning_tween.parallel().tween_property(_hunger_warning_panel, "modulate", Color(1, 1, 1, 0), 0.18)
	_hunger_warning_tween.parallel().tween_property(_hunger_warning_panel, "scale", Vector2(0.98, 0.98), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_hunger_warning_tween.finished.connect(Callable(self, "_finish_hiding_hunger_warning"), CONNECT_ONE_SHOT)

func _position_hunger_warning_toast() -> void:
	if _hunger_warning_panel == null or not is_instance_valid(_hunger_warning_panel):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = _hunger_warning_panel.size
	var anchor_bottom: float = HUNGER_WARNING_MARGIN
	var header_stack: Control = _header_stack if _header_stack != null and is_instance_valid(_header_stack) else _scene_node(COMBAT_HEADER_STACK_PATH) as Control
	if header_stack != null and header_stack.visible:
		anchor_bottom = header_stack.get_global_rect().end.y + HUNGER_WARNING_TOP_GAP
	var x_position: float = clampf(
		(viewport_size.x - panel_size.x) * 0.5,
		HUNGER_WARNING_MARGIN,
		max(HUNGER_WARNING_MARGIN, viewport_size.x - panel_size.x - HUNGER_WARNING_MARGIN)
	)
	var y_position: float = clampf(
		anchor_bottom,
		HUNGER_WARNING_MARGIN,
		max(HUNGER_WARNING_MARGIN, viewport_size.y - panel_size.y - HUNGER_WARNING_MARGIN)
	)
	_hunger_warning_panel.global_position = Vector2(x_position, y_position)

func _finish_hiding_hunger_warning() -> void:
	if _hunger_warning_panel == null or not is_instance_valid(_hunger_warning_panel):
		return
	_hunger_warning_panel.visible = false
	_hunger_warning_panel.modulate = Color(1, 1, 1, 0)
	_hunger_warning_panel.scale = Vector2.ONE
	_hunger_warning_tween = null


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
	var combat_state: CombatState = _combat_flow.combat_state if _combat_flow != null else null
	if _action_hint_controller != null:
		_action_hint_controller.refresh_button_tooltips(
			attack_button,
			defense_button,
			null,
			_presenter,
			combat_state,
			preview_consumable,
			preview_snapshot
		)


func _apply_temp_theme() -> void:
	CombatSceneUiScript.apply_temp_theme(self, Callable(self, "_combat_secondary_node"))
	_style_player_guard_badge()
	_apply_hunger_warning_style(RunStatusStripScript.HUNGER_THRESHOLD_HUNGRY)


func _on_viewport_size_changed() -> void:
	_apply_portrait_safe_layout()
	if _action_hint_controller != null:
		_action_hint_controller.update_visibility()
	_position_hunger_warning_toast()


func _apply_portrait_safe_layout() -> void:
	var layout_result: Dictionary = CombatSceneUiScript.apply_portrait_safe_layout(self, Callable(self, "_combat_secondary_node"))
	_is_compact_layout = bool(layout_result.get("is_compact_layout", false))
	_apply_player_guard_badge_layout()
	_apply_hunger_warning_style(RunStatusStripScript.HUNGER_THRESHOLD_HUNGRY)
	_position_hunger_warning_toast()
	if _action_hint_controller != null:
		_action_hint_controller.update_visibility()
