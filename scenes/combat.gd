# Layer: Scenes - presentation only
extends Control

const CombatFlowScript = preload("res://Game/Application/combat_flow.gd")
const CombatPresenterScript = preload("res://Game/UI/combat_presenter.gd")
const CombatSceneUiScript = preload("res://Game/UI/combat_scene_ui.gd")
const InventoryPresenterScript = preload("res://Game/UI/inventory_presenter.gd")
const InventoryCardInteractionHandlerScript = preload("res://Game/UI/inventory_card_interaction_handler.gd")
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
const ACTION_HINT_PANEL_MAX_WIDTH := 440.0
const ACTION_HINT_PANEL_MARGIN := 16.0
const COMBAT_SECONDARY_SCROLL_PATH := "Margin/VBox/SecondaryScroll"
const COMBAT_SECONDARY_SCROLL_CONTENT_PATH := "Margin/VBox/SecondaryScroll/SecondaryScrollContent"
const COMBAT_ACTION_HINT_PANEL_PATH := "Margin/VBox/Buttons/ActionHintPanel"
const COMBAT_HEADER_STACK_PATH := "Margin/VBox/HeaderStack"
const PLAYER_INFO_VBOX_PATH := "Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox"
const PLAYER_RUN_SUMMARY_CARD_PATH := "Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerRunSummaryCard"
const PLAYER_RUN_SUMMARY_LABEL_PATH := "Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerRunSummaryCard/PlayerRunSummaryFallbackLabel"
const PLAYER_GUARD_BADGE_PANEL_NAME := "PlayerGuardBadgePanel"
const PLAYER_GUARD_BADGE_LABEL_NAME := "PlayerGuardBadgeLabel"
const HUNGER_WARNING_PANEL_NAME := "HungerWarningToast"
const HUNGER_WARNING_LABEL_NAME := "HungerWarningLabel"
const ATTACK_BUTTON_PATH := "Margin/VBox/Buttons/AttackActionCard/AttackActionVBox/AttackButton"
const DEFENSE_BUTTON_PATH := "Margin/VBox/Buttons/DefenseActionCard/DefenseActionVBox/DefenseActionButton"
const USE_ITEM_BUTTON_PATH := "Margin/VBox/Buttons/UseItemActionCard/UseItemActionVBox/UseItemButton"
const ACTION_HINT_LABEL_PATH := "ActionHintVBox/ActionContextLabel"
const ACTION_HINT_META_KEY := "action_hint_text"
const INVENTORY_DRAG_THRESHOLD := 14.0
const ENEMY_HP_BAR_NAME := "EnemyHpBar"
const COMBAT_FEEDBACK_LAYER_NAME := "CombatFeedbackLayer"
const IMPACT_FLASH_NODE_NAME := "ImpactFlash"
const FEEDBACK_TEXT_LAYER_NAME := "FeedbackTextLayer"
const INTENT_CARD_PATH := "Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard"
const BAR_TWEEN_META_KEY := "bar_tween"
const BAR_INITIALIZED_META_KEY := "bar_initialized"
const ACTION_HINT_TWEEN_META_KEY := "action_hint_tween"
const ACTION_BUTTON_TWEEN_META_KEY := "action_button_tween"
const INTENT_REVEAL_TWEEN_META_KEY := "intent_reveal_tween"
const PLAYER_GUARD_BADGE_TWEEN_META_KEY := "player_guard_badge_tween"
const HUNGER_WARNING_Z_INDEX := 125
const HUNGER_WARNING_SHOW_DURATION := 2.0
const HUNGER_WARNING_MARGIN := 16.0
const HUNGER_WARNING_TOP_GAP := 12.0
const PLAYER_FEEDBACK_Y_FACTOR := 0.6
const ENEMY_FEEDBACK_Y_FACTOR := 0.46
const BUTTON_BOUNCE_DOWN_DURATION := 0.1
const BUTTON_BOUNCE_UP_DURATION := 0.08
const ACTION_HINT_PANEL_OPEN_DURATION := 0.2
const ACTION_HINT_PANEL_CLOSE_DURATION := 0.15
const ACTION_HINT_PANEL_HIDDEN_SCALE := Vector2(0.98, 0.94)
const ACTION_HINT_PANEL_VISIBLE_SCALE := Vector2.ONE
const INTENT_REVEAL_DURATION := 0.2
const INTENT_REVEAL_START_SCALE := Vector2(0.92, 0.92)
const FEEDBACK_FALLBACK_STAGGER := 0.06
const BAR_TWEEN_MIN_DURATION := 0.18
const BAR_TWEEN_MAX_DURATION := 0.3

var _combat_flow: CombatFlow
var _presenter: RefCounted
var _inventory_presenter: RefCounted
var _run_state: RunState
var _status_lines: PackedStringArray = []
var _transition_requested: bool = false
var _action_hint_panel: PanelContainer
var _action_hint_label: Label
var _player_guard_badge_panel: PanelContainer
var _player_guard_badge_label: Label
var _hovered_action_button: Control
var _hovered_action_accent: Color = TempScreenThemeScript.PANEL_BORDER_COLOR
var _selected_consumable_slot_index: int = -1
var _inventory_card_handler: InventoryCardInteractionHandler
var _feedback_lane_by_target := {
	"player": 0,
	"enemy": 0,
}
var _feedback_visual_delay_by_target := {
	"player": 0.0,
	"enemy": 0.0,
}
var _feedback_lane_reset_scheduled: bool = false
var _pending_phase_feedback_models: Array[Dictionary] = []
var _intent_reveal_feedback_scheduled: bool = false
var _pending_boss_phase_reveal: bool = false
var _is_compact_layout: bool = false
var _last_rendered_guard: int = -1
var _guard_before_turn_end_phase: int = -1
var _equipment_cards_signature: String = ""
var _backpack_cards_signature: String = ""
var _run_status_strip: RunStatusStrip
var _hunger_warning_panel: PanelContainer
var _hunger_warning_label: Label
var _hunger_warning_tween: Tween


func _ready() -> void:
	var tree_root: Node = get_tree().get_root()
	var active_scene_root: Node = get_tree().current_scene
	RunSummaryCleanupHelperScript.new().cleanup_orphaned_map_run_summary_cards(tree_root, active_scene_root)
	_connect_buttons()
	_ensure_feedback_shells()
	_ensure_action_hint_controls()
	_ensure_player_guard_badge()
	_ensure_hunger_warning_toast()
	_presenter = CombatPresenterScript.new()
	_inventory_presenter = InventoryPresenterScript.new()
	_run_status_strip = RunStatusStripScript.new()
	if _run_status_strip != null and not _run_status_strip.is_connected("hunger_threshold_crossed", Callable(self, "_on_hunger_threshold_crossed")):
		_run_status_strip.connect("hunger_threshold_crossed", Callable(self, "_on_hunger_threshold_crossed"))
	_inventory_card_handler = InventoryCardInteractionHandlerScript.new()
	_inventory_card_handler.configure(self, {
		"click_handler": Callable(self, "_handle_inventory_card_click"),
		"drag_complete_handler": Callable(self, "_handle_inventory_card_drag_completed"),
		"drag_started_handler": Callable(self, "_on_inventory_card_drag_started"),
		"drag_threshold": INVENTORY_DRAG_THRESHOLD,
		"release_on_global_mouse_up": true,
	})
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	_apply_temp_theme()
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


func _exit_tree() -> void:
	if _hunger_warning_tween != null and is_instance_valid(_hunger_warning_tween):
		_hunger_warning_tween.kill()
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_on_viewport_size_changed"))
	if _inventory_card_handler != null:
		_inventory_card_handler.stop_interaction()
	_hide_action_hint_panel(true, true)
	SceneAudioCleanupScript.release_players(self, SceneAudioPlayersScript.node_names_from_config(AUDIO_PLAYER_CONFIG))


func _input(event: InputEvent) -> void:
	if _inventory_card_handler == null:
		return
	_inventory_card_handler.handle_root_input(event)


func _combat_secondary_root() -> Control:
	var root: Control = get_node_or_null(COMBAT_SECONDARY_SCROLL_CONTENT_PATH) as Control
	if root != null:
		return root
	return get_node_or_null("Margin/VBox") as Control


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
	node = get_node_or_null(relative_path)
	if node != null:
		return node
	node = get_node_or_null("Margin/VBox/" + relative_path)
	if node == null:
		node = get_node_or_null("Margin/VBox/%s" % relative_path)
	return node


func _ensure_action_hint_controls() -> void:
	if _action_hint_panel == null or not is_instance_valid(_action_hint_panel):
		_action_hint_panel = get_node_or_null(COMBAT_ACTION_HINT_PANEL_PATH) as PanelContainer
	if _action_hint_panel == null:
		return
	var action_hint_box: VBoxContainer = _action_hint_panel.get_node_or_null("ActionHintVBox") as VBoxContainer
	if action_hint_box == null and _action_hint_panel != null:
		action_hint_box = VBoxContainer.new()
		action_hint_box.name = "ActionHintVBox"
		_action_hint_panel.add_child(action_hint_box)
	if _action_hint_label == null or not is_instance_valid(_action_hint_label):
		_action_hint_label = _action_hint_panel.get_node_or_null(ACTION_HINT_LABEL_PATH) as Label
	if _action_hint_label == null and action_hint_box != null:
		_action_hint_label = Label.new()
		_action_hint_label.name = "ActionContextLabel"
		action_hint_box.add_child(_action_hint_label)
	_action_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_hint_panel.top_level = true
	_action_hint_panel.z_index = 120
	_action_hint_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_action_hint_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_action_hint_panel.custom_minimum_size = Vector2.ZERO
	if _action_hint_label != null:
		_action_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_action_hint_label.clip_text = false
		_action_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_action_hint_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_action_hint_label.visible = true
		_action_hint_label.text = ""
		if action_hint_box != null:
			action_hint_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_hint_panel.visible = false
	_action_hint_panel.scale = ACTION_HINT_PANEL_HIDDEN_SCALE
	_action_hint_panel.modulate = Color(1, 1, 1, 0)
	_apply_action_hint_panel_style(TempScreenThemeScript.TEAL_ACCENT_COLOR)


func _update_action_hint_panel_visibility() -> void:
	_refresh_active_action_hint_panel()


func _connect_buttons() -> void:
	var attack_button: Button = get_node_or_null(ATTACK_BUTTON_PATH) as Button
	var defense_button: Button = get_node_or_null(DEFENSE_BUTTON_PATH) as Button
	var use_item_button: Button = get_node_or_null(USE_ITEM_BUTTON_PATH) as Button

	if attack_button != null and not attack_button.is_connected("pressed", Callable(self, "_on_attack_pressed")):
		attack_button.connect("pressed", Callable(self, "_on_attack_pressed"))
	_connect_action_tooltip_events(attack_button, CombatFlowScript.ACTION_ATTACK, TempScreenThemeScript.RUST_ACCENT_COLOR)
	if defense_button != null and not defense_button.is_connected("pressed", Callable(self, "_on_defend_pressed")):
		defense_button.connect("pressed", Callable(self, "_on_defend_pressed"))
	_connect_action_tooltip_events(defense_button, CombatFlowScript.ACTION_DEFEND, TempScreenThemeScript.TEAL_ACCENT_COLOR)
	if use_item_button != null and not use_item_button.is_connected("pressed", Callable(self, "_on_use_item_pressed")):
		use_item_button.connect("pressed", Callable(self, "_on_use_item_pressed"))
	_connect_action_tooltip_events(use_item_button, CombatFlowScript.ACTION_USE_ITEM, TempScreenThemeScript.REWARD_ACCENT_COLOR)


func _ensure_feedback_shells() -> void:
	for card_path in [
		"Margin/VBox/BattleCardsRow/EnemyCard",
		"Margin/VBox/BattleCardsRow/PlayerCard",
	]:
		var card: PanelContainer = get_node_or_null(card_path) as PanelContainer
		if card == null:
			continue

		var feedback_layer: Control = card.get_node_or_null(COMBAT_FEEDBACK_LAYER_NAME) as Control
		if feedback_layer == null:
			feedback_layer = Control.new()
			feedback_layer.name = COMBAT_FEEDBACK_LAYER_NAME
			feedback_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			feedback_layer.clip_contents = false
			card.add_child(feedback_layer)
		feedback_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		feedback_layer.z_index = 4

		var flash: ColorRect = feedback_layer.get_node_or_null(IMPACT_FLASH_NODE_NAME) as ColorRect
		if flash == null:
			flash = ColorRect.new()
			flash.name = IMPACT_FLASH_NODE_NAME
			flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			feedback_layer.add_child(flash)
		flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		flash.color = Color(1, 1, 1, 0)
		flash.z_index = 0

		var text_layer: Control = feedback_layer.get_node_or_null(FEEDBACK_TEXT_LAYER_NAME) as Control
		if text_layer == null:
			text_layer = Control.new()
			text_layer.name = FEEDBACK_TEXT_LAYER_NAME
			text_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_layer.clip_contents = false
			feedback_layer.add_child(text_layer)
		text_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		text_layer.z_index = 1


func _on_attack_pressed() -> void:
	_resolve_player_turn(CombatFlowScript.ACTION_ATTACK)


func _on_defend_pressed() -> void:
	_resolve_player_turn(CombatFlowScript.ACTION_DEFEND)


func _on_use_item_pressed() -> void:
	if not _has_selected_usable_consumable():
		if _has_usable_consumable():
			_append_status_line("Select a usable item in ITEM first.")
		else:
			_append_status_line("No usable item ready.")
		_refresh_ui()
		return
	_resolve_player_turn(CombatFlowScript.ACTION_USE_ITEM, _selected_consumable_slot_index)


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
	var line: String = _presenter.format_domain_event_line(event_name, payload)
	if not line.is_empty():
		_append_status_line(line)


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
		_append_status_line(line)

	_refresh_ui()
	_flush_pending_phase_feedbacks()


func _resolve_player_turn(action_name: String, action_value: int = -1) -> void:
	if _combat_flow == null or _combat_flow.combat_state.combat_ended:
		return

	_hide_action_hint_panel(true)
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
	var turn_label: Label = get_node_or_null("Margin/VBox/HeaderStack/TurnLabel") as Label
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

	var enemy_name_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyNameLabel") as Label
	if enemy_name_label != null and _combat_flow != null:
		enemy_name_label.text = _presenter.build_enemy_name_text(_combat_flow.combat_state)

	var enemy_type_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyTypeLabel") as Label
	if enemy_type_label != null and _combat_flow != null:
		enemy_type_label.text = _presenter.build_enemy_type_text(_combat_flow.combat_state)
	var enemy_trait_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyTraitLabel") as Label
	if enemy_trait_label != null and _combat_flow != null:
		var enemy_trait_text: String = _presenter.build_enemy_trait_text(_combat_flow.combat_state)
		enemy_trait_label.text = enemy_trait_text
		enemy_trait_label.visible = not enemy_trait_text.is_empty()

	var enemy_hp_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyHpLabel") as Label
	if enemy_hp_label != null and _combat_flow != null:
		enemy_hp_label.text = _presenter.build_enemy_hp_text(_combat_flow.combat_state)
	var enemy_hp_bar: ProgressBar = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/%s" % ENEMY_HP_BAR_NAME) as ProgressBar
	if enemy_hp_bar != null and _combat_flow != null:
		var enemy_max_hp: int = _extract_enemy_max_hp_from_state(_combat_flow.combat_state)
		_animate_progress_bar(enemy_hp_bar, enemy_max_hp, _combat_flow.combat_state.enemy_hp)

	var enemy_token_path: String = ""
	if _combat_flow != null:
		enemy_token_path = _presenter.build_enemy_token_texture_path(_combat_flow.combat_state)
	_apply_bust_texture(
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/BossTokenFrame",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/BossTokenFrame/BossTokenTexture",
		enemy_token_path
	)

	var intent_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentRow/IntentLabel") as Label
	if intent_label != null and _combat_flow != null:
		var current_intent: Dictionary = _combat_flow.get_current_intent()
		intent_label.text = _presenter.build_intent_summary_text(current_intent)
		_apply_texture_rect_asset(
			"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentRow/IntentIcon",
			_presenter.build_intent_icon_texture_path(current_intent)
		)
	var intent_detail_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentDetailLabel") as Label
	if intent_detail_label != null:
		intent_detail_label.text = String(_presenter.build_preview_texts(preview_snapshot).get("intent_detail", "Incoming ? | Guard ?"))

	_apply_bust_texture(
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/BustTexture",
		_presenter.build_player_bust_texture_path()
	)
	var player_name_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerIdentityRow/PlayerNameLabel") as Label
	if player_name_label != null:
		player_name_label.text = _presenter.build_player_identity_text()
	var hero_badge_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/HeroBadgePanel/HeroBadgeLabel") as Label
	if hero_badge_label != null:
		hero_badge_label.text = _presenter.build_player_badge_text()
	var player_loadout_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerLoadoutLabel") as Label
	if player_loadout_label != null and _combat_flow != null:
		player_loadout_label.text = _presenter.build_player_loadout_text(_combat_flow.combat_state)
	var player_run_summary_card: PanelContainer = get_node_or_null(PLAYER_RUN_SUMMARY_CARD_PATH) as PanelContainer
	var player_run_summary_label: Label = get_node_or_null(PLAYER_RUN_SUMMARY_LABEL_PATH) as Label
	if player_run_summary_card != null:
		_run_status_strip.render_into_with_hunger_signal(
			player_run_summary_card,
			player_run_summary_label,
			_presenter.build_player_status_model(_combat_flow.combat_state if _combat_flow != null else null),
			TempScreenThemeScript.TEAL_ACCENT_COLOR
		)
	_refresh_player_guard_badge()
	var forecast_title_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastTitleLabel") as Label
	if forecast_title_label != null:
		forecast_title_label.text = "Combat Forecast"

	var preview_texts: Dictionary = _presenter.build_preview_texts(preview_snapshot)
	for label_name in [
		"ForecastAttackLabel",
		"ForecastDefenseLabel",
		"ForecastIncomingLabel",
		"ForecastGuardLabel",
		"ForecastHungerTickLabel",
		"ForecastDurabilitySpendLabel",
	]:
		var forecast_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/%s" % label_name) as Label
		if forecast_label == null:
			continue
		match label_name:
			"ForecastAttackLabel":
				forecast_label.text = String(preview_texts.get("attack", "Hit ?"))
			"ForecastDefenseLabel":
				forecast_label.text = String(preview_texts.get("defense", "Defense ?"))
			"ForecastIncomingLabel":
				forecast_label.text = String(preview_texts.get("incoming", "Incoming ?"))
			"ForecastGuardLabel":
				forecast_label.text = String(preview_texts.get("defend", "Guard ?"))
			"ForecastHungerTickLabel":
				forecast_label.text = String(preview_texts.get("hunger_tick", "Tick -1 hunger"))
			"ForecastDurabilitySpendLabel":
				forecast_label.text = String(preview_texts.get("durability_spend", "Swing -? durability"))

	var player_status_section: VBoxContainer = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerStatusSection") as VBoxContainer
	var player_status_title: Label = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerStatusSection/PlayerStatusTitleLabel") as Label
	var player_status_row: HFlowContainer = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerStatusSection/PlayerStatusRow") as HFlowContainer
	var enemy_status_section: VBoxContainer = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyStatusSection") as VBoxContainer
	var enemy_status_title: Label = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyStatusSection/EnemyStatusTitleLabel") as Label
	var enemy_status_row: HFlowContainer = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyStatusSection/EnemyStatusRow") as HFlowContainer
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

	var status_label: Label = _combat_secondary_node("CombatLogCard/CombatLogLabel") as Label
	if status_label != null:
		status_label.text = _presenter.build_status_log_text(_status_lines)

	var defense_button: Button = get_node_or_null(DEFENSE_BUTTON_PATH) as Button
	if defense_button != null and _combat_flow != null:
		defense_button.text = _presenter.build_defensive_action_label(_combat_flow.combat_state)
	var attack_preview_label: Label = get_node_or_null("Margin/VBox/Buttons/AttackActionCard/AttackActionVBox/AttackActionPreviewLabel") as Label
	if attack_preview_label != null:
		attack_preview_label.text = _presenter.build_action_card_preview_text(CombatFlowScript.ACTION_ATTACK, _combat_flow.combat_state if _combat_flow != null else null, {}, preview_snapshot)
	var defense_preview_label: Label = get_node_or_null("Margin/VBox/Buttons/DefenseActionCard/DefenseActionVBox/DefenseActionPreviewLabel") as Label
	if defense_preview_label != null:
		defense_preview_label.text = _presenter.build_action_card_preview_text(CombatFlowScript.ACTION_DEFEND, _combat_flow.combat_state if _combat_flow != null else null, {}, preview_snapshot)
	var use_item_preview_label: Label = get_node_or_null("Margin/VBox/Buttons/UseItemActionCard/UseItemActionVBox/UseItemActionPreviewLabel") as Label
	if use_item_preview_label != null:
		use_item_preview_label.text = _presenter.build_action_card_preview_text(CombatFlowScript.ACTION_USE_ITEM, _combat_flow.combat_state if _combat_flow != null else null, preview_consumable, preview_snapshot)

	_refresh_inventory_cards()
	_refresh_action_button_tooltips(preview_consumable, preview_snapshot)
	_set_buttons_enabled(_combat_flow != null and _presenter.are_action_buttons_enabled(_combat_flow.combat_state))


func _append_status_line(line: String) -> void:
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
	if _status_lines.size() > 8:
		_status_lines.remove_at(0)


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
			_queue_intent_reveal_feedback()
		"BossPhaseChanged":
			_queue_intent_reveal_feedback(true)


func _flush_pending_phase_feedbacks() -> void:
	if _pending_phase_feedback_models.is_empty():
		return

	var phase_models: Array[Dictionary] = _pending_phase_feedback_models.duplicate(true)
	_pending_phase_feedback_models.clear()
	var target_visual_claims: Dictionary = {}
	for model_value in phase_models:
		if typeof(model_value) != TYPE_DICTIONARY:
			continue
		var model: Dictionary = model_value.duplicate(true)
		var target: String = String(model.get("target", "player"))
		var visuals_claimed: bool = bool(target_visual_claims.get(target, false))
		if visuals_claimed or bool(model.get("text_only", false)):
			model["text_only"] = true
		else:
			var delay_seconds: float = float(_feedback_visual_delay_by_target.get(target, 0.0))
			model["delay_seconds"] = delay_seconds
			_feedback_visual_delay_by_target[target] = delay_seconds + _estimate_feedback_visual_duration(model) + float(model.get("feedback_stagger", FEEDBACK_FALLBACK_STAGGER))
			target_visual_claims[target] = true
		_play_feedback_burst(model)


func _play_feedback_burst(model: Dictionary) -> void:
	var target: String = String(model.get("target", "player"))
	var target_nodes: Dictionary = _resolve_feedback_target_nodes(target)
	if target_nodes.is_empty():
		return

	var lane_index: int = int(_feedback_lane_by_target.get(target, 0))
	_feedback_lane_by_target[target] = lane_index + 1
	if not _feedback_lane_reset_scheduled:
		_feedback_lane_reset_scheduled = true
		call_deferred("_reset_feedback_lane_state")

	var flash: ColorRect = target_nodes.get("flash") as ColorRect
	var pulse_control: Control = target_nodes.get("pulse") as Control
	var text_layer: Control = target_nodes.get("text_layer") as Control
	if not bool(model.get("text_only", false)):
		_play_feedback_flash(flash, model, lane_index)
		_play_feedback_pulse(pulse_control, model, lane_index)
	_spawn_feedback_text(text_layer, model, lane_index)


func _resolve_feedback_target_nodes(target: String) -> Dictionary:
	var card_path: String = "Margin/VBox/BattleCardsRow/PlayerCard"
	var pulse_path: String = "Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame"
	if target == "enemy":
		card_path = "Margin/VBox/BattleCardsRow/EnemyCard"
		pulse_path = "Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame"

	var card: PanelContainer = get_node_or_null(card_path) as PanelContainer
	if card == null:
		return {}
	var feedback_layer: Control = card.get_node_or_null(COMBAT_FEEDBACK_LAYER_NAME) as Control
	var flash: ColorRect = card.get_node_or_null("%s/%s" % [COMBAT_FEEDBACK_LAYER_NAME, IMPACT_FLASH_NODE_NAME]) as ColorRect
	var text_layer: Control = card.get_node_or_null("%s/%s" % [COMBAT_FEEDBACK_LAYER_NAME, FEEDBACK_TEXT_LAYER_NAME]) as Control
	var pulse_control: Control = get_node_or_null(pulse_path) as Control
	if pulse_control == null or not pulse_control.visible:
		pulse_control = card
	return {
		"card": card,
		"feedback_layer": feedback_layer,
		"flash": flash,
		"text_layer": text_layer,
		"pulse": pulse_control,
	}


func _reset_feedback_lane_state() -> void:
	_feedback_lane_by_target["player"] = 0
	_feedback_lane_by_target["enemy"] = 0
	_feedback_visual_delay_by_target["player"] = 0.0
	_feedback_visual_delay_by_target["enemy"] = 0.0
	_feedback_lane_reset_scheduled = false


func _play_feedback_flash(flash: ColorRect, model: Dictionary, lane_index: int) -> void:
	if flash == null:
		return

	var flash_color: Color = Color(model.get("flash_color", TempScreenThemeScript.RUST_ACCENT_COLOR))
	var target_alpha: float = float(model.get("flash_alpha", 0.2))
	var flash_cycles: int = max(1, int(model.get("flash_cycles", 1)))
	var flash_on_duration: float = float(model.get("flash_on_duration", 0.06))
	var flash_off_duration: float = float(model.get("flash_off_duration", 0.1))
	var delay_seconds: float = float(model.get("delay_seconds", 0.0))
	flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
	var tween: Tween = create_tween()
	tween.tween_interval(delay_seconds)
	for cycle_index in range(flash_cycles):
		tween.tween_property(flash, "color", Color(flash_color.r, flash_color.g, flash_color.b, target_alpha), flash_on_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(flash, "color", Color(flash_color.r, flash_color.g, flash_color.b, 0.0), flash_off_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)


func _play_feedback_pulse(pulse_control: Control, model: Dictionary, lane_index: int) -> void:
	if pulse_control == null:
		return

	pulse_control.pivot_offset = pulse_control.size * 0.5
	var start_scale: float = float(model.get("pulse_start_scale", 1.0))
	var target_scale: float = float(model.get("pulse_scale", 1.03))
	var delay_seconds: float = float(model.get("delay_seconds", 0.0))
	var pulse_in_duration: float = float(model.get("pulse_in_duration", 0.08))
	var pulse_out_duration: float = float(model.get("pulse_out_duration", 0.18))
	var tween: Tween = create_tween()
	tween.tween_interval(delay_seconds)
	tween.tween_callback(Callable(self, "_set_control_scale").bind(pulse_control, Vector2.ONE * start_scale))
	tween.tween_property(pulse_control, "scale", Vector2.ONE * target_scale, pulse_in_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse_control, "scale", Vector2.ONE, pulse_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _spawn_feedback_text(text_layer: Control, model: Dictionary, lane_index: int) -> void:
	if text_layer == null:
		return

	var feedback_text: String = String(model.get("text", "")).strip_edges()
	if feedback_text.is_empty():
		return

	var label: Label = Label.new()
	label.text = feedback_text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	TempScreenThemeScript.apply_label(label)
	label.add_theme_font_size_override("font_size", int(model.get("font_size", 22)))
	label.add_theme_color_override("font_color", Color(model.get("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)))
	label.add_theme_color_override("font_outline_color", Color(0.015, 0.02, 0.03, 0.92))
	label.add_theme_constant_override("outline_size", 6)
	text_layer.add_child(label)

	var label_size: Vector2 = label.get_combined_minimum_size()
	label.size = label_size
	label.pivot_offset = label_size * 0.5
	var y_factor: float = PLAYER_FEEDBACK_Y_FACTOR
	if String(model.get("target", "player")) == "enemy":
		y_factor = ENEMY_FEEDBACK_Y_FACTOR
	var start_position := Vector2(
		(text_layer.size.x - label_size.x) * 0.5,
		(text_layer.size.y * y_factor) - (label_size.y * 0.5) + (float(lane_index) * 18.0)
	)
	var end_position := start_position - Vector2(0.0, float(model.get("float_distance", 44.0)) + (float(lane_index) * 8.0))
	label.position = start_position
	label.scale = Vector2.ONE * 0.9
	label.modulate = Color(1, 1, 1, 0)

	var delay_seconds: float = float(model.get("delay_seconds", 0.0)) + (float(lane_index) * float(model.get("feedback_stagger", FEEDBACK_FALLBACK_STAGGER)))
	var text_float_duration: float = float(model.get("text_float_duration", 0.4))
	var text_fade_in_duration: float = float(model.get("text_fade_in_duration", 0.08))
	var text_hold_duration: float = float(model.get("text_hold_duration", 0.14))
	var text_fade_out_duration: float = float(model.get("text_fade_out_duration", 0.16))
	var motion_tween: Tween = create_tween()
	motion_tween.tween_interval(delay_seconds)
	motion_tween.tween_property(label, "position", end_position, text_float_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var scale_tween: Tween = create_tween()
	scale_tween.tween_interval(delay_seconds)
	scale_tween.tween_property(label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var fade_tween: Tween = create_tween()
	fade_tween.tween_interval(delay_seconds)
	fade_tween.tween_property(label, "modulate", Color(1, 1, 1, 1), text_fade_in_duration)
	fade_tween.tween_interval(text_hold_duration)
	fade_tween.tween_property(label, "modulate", Color(1, 1, 1, 0), text_fade_out_duration)
	fade_tween.finished.connect(Callable(label, "queue_free"), CONNECT_ONE_SHOT)


func _animate_progress_bar(bar: ProgressBar, max_value: float, target_value: float) -> void:
	if bar == null:
		return

	var clamped_max: float = max(1.0, max_value)
	var clamped_value: float = clamp(target_value, 0.0, clamped_max)
	var is_initialized: bool = bool(bar.get_meta(BAR_INITIALIZED_META_KEY, false))
	_kill_control_tween(bar, BAR_TWEEN_META_KEY)
	bar.max_value = clamped_max
	if not is_initialized:
		bar.value = clamped_value
		bar.set_meta(BAR_INITIALIZED_META_KEY, true)
		return
	if is_equal_approx(bar.value, clamped_value):
		return

	var delta_ratio: float = abs(clamped_value - bar.value) / clamped_max
	var tween_duration: float = lerp(BAR_TWEEN_MIN_DURATION, BAR_TWEEN_MAX_DURATION, clamp(delta_ratio * 1.4, 0.0, 1.0))
	var tween: Tween = create_tween()
	bar.set_meta(BAR_TWEEN_META_KEY, tween)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(bar, "value", clamped_value, tween_duration)
	tween.finished.connect(Callable(self, "_clear_control_meta").bind(bar, BAR_TWEEN_META_KEY), CONNECT_ONE_SHOT)


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


func _estimate_feedback_visual_duration(model: Dictionary) -> float:
	var flash_cycles: int = max(1, int(model.get("flash_cycles", 1)))
	var flash_total: float = (float(model.get("flash_on_duration", 0.06)) + float(model.get("flash_off_duration", 0.1))) * float(flash_cycles)
	var pulse_total: float = float(model.get("pulse_in_duration", 0.08)) + float(model.get("pulse_out_duration", 0.18))
	return max(flash_total, pulse_total)


func _queue_intent_reveal_feedback(is_boss_phase: bool = false) -> void:
	_pending_boss_phase_reveal = _pending_boss_phase_reveal or is_boss_phase
	if _intent_reveal_feedback_scheduled:
		return
	_intent_reveal_feedback_scheduled = true
	call_deferred("_play_pending_intent_reveal_feedback")


func _play_pending_intent_reveal_feedback() -> void:
	_intent_reveal_feedback_scheduled = false
	var is_boss_phase: bool = _pending_boss_phase_reveal
	_pending_boss_phase_reveal = false
	_play_intent_reveal_feedback(is_boss_phase)


func _play_intent_reveal_feedback(is_boss_phase: bool = false) -> void:
	var intent_card: Control = get_node_or_null(INTENT_CARD_PATH) as Control
	if intent_card == null or not intent_card.visible:
		return
	_kill_control_tween(intent_card, INTENT_REVEAL_TWEEN_META_KEY)
	intent_card.pivot_offset = intent_card.size * 0.5
	intent_card.scale = INTENT_REVEAL_START_SCALE if not is_boss_phase else Vector2(0.9, 0.9)
	intent_card.modulate = Color(1, 1, 1, 0.76 if not is_boss_phase else 0.88)
	var tween: Tween = create_tween()
	intent_card.set_meta(INTENT_REVEAL_TWEEN_META_KEY, tween)
	tween.parallel().tween_property(intent_card, "scale", Vector2.ONE, INTENT_REVEAL_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(intent_card, "modulate", Color(1, 1, 1, 1), INTENT_REVEAL_DURATION)
	tween.finished.connect(Callable(self, "_clear_control_meta").bind(intent_card, INTENT_REVEAL_TWEEN_META_KEY), CONNECT_ONE_SHOT)


func _set_control_scale(control: Control, target_scale: Vector2) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.scale = target_scale


func _extract_enemy_max_hp_from_state(combat_state: CombatState) -> int:
	if combat_state == null:
		return 1
	var rules: Dictionary = combat_state.enemy_definition.get("rules", {})
	var stats: Dictionary = rules.get("stats", {})
	return max(1, int(stats.get("base_hp", combat_state.enemy_hp)))


func _set_buttons_enabled(is_enabled: bool) -> void:
	if not is_enabled:
		_hide_action_hint_panel(true)
	for button_path in [ATTACK_BUTTON_PATH, DEFENSE_BUTTON_PATH, USE_ITEM_BUTTON_PATH]:
		var button: Button = get_node_or_null(button_path) as Button
		if button != null:
			button.disabled = not is_enabled


func _get_app_bootstrap():
	return get_node_or_null("/root/AppBootstrap")

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


func _has_usable_consumable() -> bool:
	return _combat_flow != null and _combat_flow.find_first_usable_consumable_slot_index() >= 0


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
	var equipment_container: Container = _combat_secondary_node("QuickItemSection/EquipmentCard/EquipmentCardsFlow") as Container
	var backpack_container: Container = _combat_secondary_node("QuickItemSection/InventoryCard/InventoryCardsFlow") as Container
	if _inventory_presenter == null or equipment_container == null or backpack_container == null:
		return

	_hide_action_hint_panel(true)
	if _inventory_card_handler != null:
		_inventory_card_handler.stop_interaction()
	var equipment_title_label: Label = _combat_secondary_node("QuickItemSection/EquipmentTitleLabel") as Label
	if equipment_title_label != null:
		equipment_title_label.text = _inventory_presenter.build_equipment_title_text()
	var equipment_hint_label: Label = _combat_secondary_node("QuickItemSection/EquipmentHintLabel") as Label
	if equipment_hint_label != null:
		equipment_hint_label.text = _inventory_presenter.build_equipment_hint_text(true)
	var inventory_title_label: Label = _combat_secondary_node("QuickItemSection/InventoryTitleLabel") as Label
	if inventory_title_label != null:
		inventory_title_label.text = _inventory_presenter.build_inventory_title_text(_run_state.inventory_state if _run_state != null else null)
	var inventory_hint_label: Label = _combat_secondary_node("QuickItemSection/InventoryHintLabel") as Label
	if inventory_hint_label != null:
		inventory_hint_label.text = _inventory_presenter.build_combat_inventory_hint_text()

	var equipment_card_models: Array[Dictionary] = _inventory_presenter.build_combat_equipment_cards(
		_combat_flow.combat_state if _combat_flow != null else null,
		_run_state.inventory_state if _run_state != null else null
	)
	for index in range(equipment_card_models.size()):
		var card_model: Dictionary = equipment_card_models[index]
		var is_clickable: bool = _inventory_card_is_clickable(card_model)
		var is_selected: bool = _inventory_card_is_selected(card_model)
		var is_draggable: bool = _inventory_card_is_draggable(card_model)
		card_model["is_clickable"] = is_clickable
		card_model["is_selected"] = is_selected
		card_model["is_draggable"] = is_draggable
		equipment_card_models[index] = _inventory_presenter.decorate_card_interaction_state(
			card_model,
			true,
			is_clickable,
			is_selected,
			is_draggable
		)

	var backpack_card_models: Array[Dictionary] = _inventory_presenter.build_combat_inventory_cards(
		_combat_flow.combat_state if _combat_flow != null else null,
		_run_state.inventory_state if _run_state != null else null
	)
	for index in range(backpack_card_models.size()):
		var card_model: Dictionary = backpack_card_models[index]
		var is_clickable: bool = _inventory_card_is_clickable(card_model)
		var is_selected: bool = _inventory_card_is_selected(card_model)
		var is_draggable: bool = _inventory_card_is_draggable(card_model)
		card_model["is_clickable"] = is_clickable
		card_model["is_selected"] = is_selected
		card_model["is_draggable"] = is_draggable
		backpack_card_models[index] = _inventory_presenter.decorate_card_interaction_state(
			card_model,
			true,
			is_clickable,
			is_selected,
			is_draggable
		)
	var equipment_signature: String = _inventory_card_models_signature(equipment_card_models)
	var backpack_signature: String = _inventory_card_models_signature(backpack_card_models)

	if _inventory_card_handler != null:
		if equipment_signature != _equipment_cards_signature:
			_inventory_card_handler.rebuild_cards(equipment_container, equipment_card_models)
			_equipment_cards_signature = equipment_signature
		if backpack_signature != _backpack_cards_signature:
			_inventory_card_handler.rebuild_cards(backpack_container, backpack_card_models)
			_backpack_cards_signature = backpack_signature


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
	_hide_action_hint_panel(true)


func _handle_inventory_card_drag_completed(inventory_slot_id: int, target_index: int) -> void:
	if inventory_slot_id >= 0 or target_index >= 0:
		_append_status_line("Backpack order is locked during combat.")
	_refresh_ui()


func _inventory_card_models_signature(card_models: Array[Dictionary]) -> String:
	var parts := PackedStringArray()
	for card_model in card_models:
		parts.append("%s|%s|%s|%s|%s|%d|%d|%s|%s|%s|%s|%s" % [
			str(card_model.get("card_name", "")),
			str(card_model.get("card_family", "")),
			str(card_model.get("slot_label", "")),
			str(card_model.get("title_text", "")),
			str(card_model.get("detail_text", "")),
			int(card_model.get("inventory_slot_id", -1)),
			int(card_model.get("inventory_slot_index", -1)),
			str(card_model.get("count_text", "")),
			str(card_model.get("action_hint_text", "")),
			str(card_model.get("action_hint_tone", "")),
			str(card_model.get("accent_color", "")),
			str(card_model.get("is_equipped", false)),
		])
	return "\n".join(parts)


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
	var info_vbox: VBoxContainer = get_node_or_null(PLAYER_INFO_VBOX_PATH) as VBoxContainer
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

	var player_run_summary_card: PanelContainer = get_node_or_null(PLAYER_RUN_SUMMARY_CARD_PATH) as PanelContainer
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
	var header_stack: Control = get_node_or_null(COMBAT_HEADER_STACK_PATH) as Control
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
	var frame: Control = get_node_or_null(frame_path) as Control
	var texture_rect: TextureRect = get_node_or_null(texture_path) as TextureRect
	if frame == null or texture_rect == null:
		return

	var texture: Texture2D = SceneLayoutHelperScript.load_texture_or_null(asset_path)
	texture_rect.texture = texture
	texture_rect.visible = texture != null
	texture_rect.modulate = Color(1, 1, 1, 1)
	frame.visible = texture != null


func _apply_texture_rect_asset(node_path: String, asset_path: String) -> void:
	var texture_rect: TextureRect = get_node_or_null(node_path) as TextureRect
	if texture_rect == null:
		return

	var texture: Texture2D = SceneLayoutHelperScript.load_texture_or_null(asset_path)
	texture_rect.texture = texture
	texture_rect.visible = texture != null


func _connect_action_tooltip_events(button: Button, action_name: String, accent: Color) -> void:
	if button == null:
		return

	button.tooltip_text = ""
	button.focus_mode = Control.FOCUS_ALL
	_set_action_hint_text(button, "")
	button.set_meta("action_name", action_name)
	var enter_handler := Callable(self, "_on_action_button_mouse_entered").bind(button, accent)
	var exit_handler := Callable(self, "_on_action_button_mouse_exited").bind(button)
	var focus_enter_handler := Callable(self, "_on_action_button_focus_entered").bind(button, accent)
	var focus_exit_handler := Callable(self, "_on_action_button_focus_exited").bind(button)
	var press_handler := Callable(self, "_on_action_button_pressed").bind(button, accent)
	var down_handler := Callable(self, "_on_action_button_down").bind(button, accent)
	if button.is_connected("mouse_entered", enter_handler):
		button.disconnect("mouse_entered", enter_handler)
	if not button.is_connected("mouse_entered", enter_handler):
		button.connect("mouse_entered", enter_handler)
	if button.is_connected("mouse_exited", exit_handler):
		button.disconnect("mouse_exited", exit_handler)
	if not button.is_connected("mouse_exited", exit_handler):
		button.connect("mouse_exited", exit_handler)
	if button.is_connected("focus_entered", focus_enter_handler):
		button.disconnect("focus_entered", focus_enter_handler)
	if not button.is_connected("focus_entered", focus_enter_handler):
		button.connect("focus_entered", focus_enter_handler)
	if button.is_connected("focus_exited", focus_exit_handler):
		button.disconnect("focus_exited", focus_exit_handler)
	if not button.is_connected("focus_exited", focus_exit_handler):
		button.connect("focus_exited", focus_exit_handler)
	if button.is_connected("pressed", press_handler):
		button.disconnect("pressed", press_handler)
	if not button.is_connected("pressed", press_handler):
		button.connect("pressed", press_handler)
	if button.is_connected("button_down", down_handler):
		button.disconnect("button_down", down_handler)
	if not button.is_connected("button_down", down_handler):
		button.connect("button_down", down_handler)


func _refresh_action_button_tooltips(preview_consumable: Dictionary, preview_snapshot: Dictionary = {}) -> void:
	var attack_button: Button = get_node_or_null(ATTACK_BUTTON_PATH) as Button
	var defense_button: Button = get_node_or_null(DEFENSE_BUTTON_PATH) as Button
	var use_item_button: Button = get_node_or_null(USE_ITEM_BUTTON_PATH) as Button
	var combat_state: CombatState = _combat_flow.combat_state if _combat_flow != null else null
	var attack_tooltip_text: String = ""
	var defense_tooltip_text: String = ""
	var use_item_tooltip_text: String = ""

	if attack_button != null:
		attack_tooltip_text = _presenter.build_action_tooltip_text(CombatFlowScript.ACTION_ATTACK, combat_state, {}, preview_snapshot)
		_set_action_hint_text(
			attack_button,
			attack_tooltip_text
		)
	if defense_button != null:
		defense_tooltip_text = _presenter.build_action_tooltip_text(CombatFlowScript.ACTION_DEFEND, combat_state, {}, preview_snapshot)
		_set_action_hint_text(
			defense_button,
			defense_tooltip_text
		)
	if use_item_button != null:
		use_item_button.text = "Use Item"
		use_item_tooltip_text = _presenter.build_action_tooltip_text(CombatFlowScript.ACTION_USE_ITEM, combat_state, preview_consumable, preview_snapshot)
		_set_action_hint_text(
			use_item_button,
			use_item_tooltip_text
		)
	_update_action_hint_panel_visibility()


func _apply_action_hint_panel_style(accent: Color) -> void:
	if _action_hint_panel == null or _action_hint_label == null:
		return

	TempScreenThemeScript.apply_panel(_action_hint_panel, accent, 16, 0.96)
	TempScreenThemeScript.apply_label(_action_hint_label)
	_action_hint_label.add_theme_font_size_override("font_size", 18)
	_action_hint_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	_action_hint_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.04, 0.7))
	_action_hint_label.add_theme_constant_override("shadow_size", 2)


func _on_action_button_mouse_entered(button: Control, accent: Color) -> void:
	if button == null:
		return
	if button is BaseButton and (button as BaseButton).disabled:
		return
	_set_active_action_button(button, accent)


func _on_action_button_mouse_exited(button: Control) -> void:
	if button != _hovered_action_button:
		return
	_hide_action_hint_panel(true)


func _on_action_button_focus_entered(button: Control, accent: Color) -> void:
	if button == null:
		return
	if button is BaseButton and (button as BaseButton).disabled:
		return
	_set_active_action_button(button, accent)


func _on_action_button_focus_exited(button: Control) -> void:
	if button != _hovered_action_button:
		return
	_hide_action_hint_panel(true)


func _on_action_button_pressed(button: Control, accent: Color) -> void:
	if button == null:
		return
	if button is BaseButton and (button as BaseButton).disabled:
		return
	_set_active_action_button(button, accent)


func _on_action_button_down(button: Control, accent: Color) -> void:
	if button == null:
		return
	if button is BaseButton and (button as BaseButton).disabled:
		return
	_set_active_action_button(button, accent)
	_play_action_button_bounce(button)


func _refresh_active_action_hint_panel() -> void:
	if _action_hint_panel == null:
		_ensure_action_hint_controls()
	if _action_hint_panel == null:
		return
	if _hovered_action_button == null or not is_instance_valid(_hovered_action_button):
		_hide_action_hint_panel()
		return
	if not _hovered_action_button.visible:
		_hide_action_hint_panel(true)
		return
	if _hovered_action_button is BaseButton and (_hovered_action_button as BaseButton).disabled:
		_hide_action_hint_panel(true)
		return
	var tooltip_text: String = _get_action_hint_text(_hovered_action_button).strip_edges()
	if tooltip_text.is_empty():
		_hide_action_hint_panel()
		return

	_apply_action_hint_panel_style(_hovered_action_accent)
	_action_hint_label.text = tooltip_text
	var parent_width: float = 0.0
	if _action_hint_panel.get_parent() != null:
		parent_width = _action_hint_panel.get_parent().size.x
	var viewport_width: float = get_viewport_rect().size.x
	var fallback_width: float = viewport_width - (ACTION_HINT_PANEL_MARGIN * 2.0)
	var available_width: float = max(parent_width, fallback_width)
	var panel_width: float = clamp(available_width, 220.0, ACTION_HINT_PANEL_MAX_WIDTH)
	_action_hint_panel.custom_minimum_size = Vector2(panel_width, 0.0)
	_action_hint_panel.size = _action_hint_panel.get_combined_minimum_size()
	_action_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action_hint_label.custom_minimum_size = Vector2(panel_width - 20.0, 0.0)
	_action_hint_label.visible = true
	_position_action_hint_panel(_hovered_action_button)
	_show_action_hint_panel()

func _set_active_action_button(button: Control, accent: Color) -> void:
	if button == null:
		return
	_hovered_action_button = button
	_hovered_action_accent = accent
	_refresh_active_action_hint_panel()


func _get_action_hint_text(control: Control) -> String:
	if control == null:
		return ""
	if not control.has_meta(ACTION_HINT_META_KEY):
		return ""
	return String(control.get_meta(ACTION_HINT_META_KEY, ""))


func _hide_action_hint_panel(clear_hovered_button: bool = false, immediate: bool = false) -> void:
	if clear_hovered_button:
		_hovered_action_button = null
	if _action_hint_panel == null:
		return
	_kill_control_tween(_action_hint_panel, ACTION_HINT_TWEEN_META_KEY)
	if immediate or not _action_hint_panel.visible:
		_finish_hiding_action_hint_panel()
		return
	_action_hint_panel.pivot_offset = _action_hint_panel.size * 0.5
	var tween: Tween = create_tween()
	_action_hint_panel.set_meta(ACTION_HINT_TWEEN_META_KEY, tween)
	tween.parallel().tween_property(_action_hint_panel, "modulate", Color(1, 1, 1, 0), ACTION_HINT_PANEL_CLOSE_DURATION)
	tween.parallel().tween_property(_action_hint_panel, "scale", ACTION_HINT_PANEL_HIDDEN_SCALE, ACTION_HINT_PANEL_CLOSE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(Callable(self, "_finish_hiding_action_hint_panel"), CONNECT_ONE_SHOT)


func _set_action_hint_text(control: Control, text: String) -> void:
	if control == null:
		return
	var trimmed_text: String = text.strip_edges()
	if trimmed_text.is_empty():
		if control.has_meta(ACTION_HINT_META_KEY):
			control.remove_meta(ACTION_HINT_META_KEY)
		_update_action_hint_panel_if_active(control, trimmed_text)
	else:
		control.set_meta(ACTION_HINT_META_KEY, trimmed_text)
		_update_action_hint_panel_if_active(control, trimmed_text)


func _update_action_hint_panel_if_active(control: Control, hint_text: String) -> void:
	if control == null or not is_instance_valid(control):
		return
	if _hovered_action_button != control:
		return
	if hint_text.strip_edges().is_empty():
		_hide_action_hint_panel(true)
		return
	_refresh_active_action_hint_panel()


func _show_action_hint_panel() -> void:
	if _action_hint_panel == null:
		return
	_kill_control_tween(_action_hint_panel, ACTION_HINT_TWEEN_META_KEY)
	var was_visible: bool = _action_hint_panel.visible and _action_hint_panel.modulate.a > 0.01
	_action_hint_panel.visible = true
	_action_hint_panel.pivot_offset = _action_hint_panel.size * 0.5
	if not was_visible:
		_action_hint_panel.scale = ACTION_HINT_PANEL_HIDDEN_SCALE
		_action_hint_panel.modulate = Color(1, 1, 1, 0)
	var tween: Tween = create_tween()
	_action_hint_panel.set_meta(ACTION_HINT_TWEEN_META_KEY, tween)
	tween.parallel().tween_property(_action_hint_panel, "modulate", Color(1, 1, 1, 1), ACTION_HINT_PANEL_OPEN_DURATION)
	tween.parallel().tween_property(_action_hint_panel, "scale", ACTION_HINT_PANEL_VISIBLE_SCALE, ACTION_HINT_PANEL_OPEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(Callable(self, "_clear_control_meta").bind(_action_hint_panel, ACTION_HINT_TWEEN_META_KEY), CONNECT_ONE_SHOT)


func _finish_hiding_action_hint_panel() -> void:
	if _action_hint_panel == null or not is_instance_valid(_action_hint_panel):
		return
	_action_hint_panel.visible = false
	_action_hint_panel.scale = ACTION_HINT_PANEL_HIDDEN_SCALE
	_action_hint_panel.modulate = Color(1, 1, 1, 0)
	_clear_control_meta(_action_hint_panel, ACTION_HINT_TWEEN_META_KEY)


func _position_action_hint_panel(button: Control) -> void:
	if _action_hint_panel == null or button == null or not is_instance_valid(button):
		return

	var button_rect: Rect2 = button.get_global_rect()
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = _action_hint_panel.size
	var x_position: float = clampf(
		button_rect.position.x + ((button_rect.size.x - panel_size.x) * 0.5),
		ACTION_HINT_PANEL_MARGIN,
		max(ACTION_HINT_PANEL_MARGIN, viewport_size.x - panel_size.x - ACTION_HINT_PANEL_MARGIN)
	)
	var y_position: float = button_rect.position.y - panel_size.y - 12.0
	if y_position < ACTION_HINT_PANEL_MARGIN:
		y_position = min(
			viewport_size.y - panel_size.y - ACTION_HINT_PANEL_MARGIN,
			button_rect.end.y + 12.0
		)
	_action_hint_panel.global_position = Vector2(x_position, y_position)


func _play_action_button_bounce(button: Control) -> void:
	if button == null or not is_instance_valid(button):
		return
	_kill_control_tween(button, ACTION_BUTTON_TWEEN_META_KEY)
	button.pivot_offset = button.size * 0.5
	button.scale = Vector2.ONE
	var tween: Tween = create_tween()
	button.set_meta(ACTION_BUTTON_TWEEN_META_KEY, tween)
	tween.tween_property(button, "scale", Vector2.ONE * 0.95, BUTTON_BOUNCE_DOWN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, BUTTON_BOUNCE_UP_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(Callable(self, "_clear_control_meta").bind(button, ACTION_BUTTON_TWEEN_META_KEY), CONNECT_ONE_SHOT)




func _apply_temp_theme() -> void:
	CombatSceneUiScript.apply_temp_theme(self, Callable(self, "_combat_secondary_node"))
	_style_player_guard_badge()
	_apply_hunger_warning_style(RunStatusStripScript.HUNGER_THRESHOLD_HUNGRY)


func _on_viewport_size_changed() -> void:
	_apply_portrait_safe_layout()
	_refresh_active_action_hint_panel()
	_position_hunger_warning_toast()


func _apply_portrait_safe_layout() -> void:
	var layout_result: Dictionary = CombatSceneUiScript.apply_portrait_safe_layout(self, Callable(self, "_combat_secondary_node"))
	_is_compact_layout = bool(layout_result.get("is_compact_layout", false))
	_apply_player_guard_badge_layout()
	_apply_hunger_warning_style(RunStatusStripScript.HUNGER_THRESHOLD_HUNGRY)
	_position_hunger_warning_toast()
	_update_action_hint_panel_visibility()
