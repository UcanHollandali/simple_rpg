# Layer: Scenes - presentation only
extends Control

const CombatFlowScript = preload("res://Game/Application/combat_flow.gd")
const CombatPresenterScript = preload("res://Game/UI/combat_presenter.gd")
const InventoryPresenterScript = preload("res://Game/UI/inventory_presenter.gd")
const InventoryCardFactoryScript = preload("res://Game/UI/inventory_card_factory.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const ATTACK_RESOLVE_SFX_PATH := "res://Assets/Audio/SFX/sfx_combat_hit_light_01.ogg"
const BRACE_SFX_PATH := "res://Assets/Audio/SFX/sfx_brace_01.ogg"
const ITEM_USE_SFX_PATH := "res://Assets/Audio/SFX/sfx_item_use_01.ogg"
const COMBAT_MUSIC_LOOP_PATH := "res://Assets/Audio/Music/music_combat_loop_temp_01.ogg"
const AUDIO_PLAYER_NODE_NAMES: Array[String] = [
	"AttackResolveSfxPlayer",
	"BraceSfxPlayer",
	"ItemUseSfxPlayer",
	"CombatMusicPlayer",
]
const ACTION_HINT_PANEL_MAX_WIDTH := 520.0
const ACTION_HINT_PANEL_MARGIN := 16.0
const COMBAT_SECONDARY_SCROLL_PATH := "Margin/VBox/SecondaryScroll"
const COMBAT_SECONDARY_SCROLL_CONTENT_PATH := "Margin/VBox/SecondaryScroll/SecondaryScrollContent"
const COMBAT_ACTION_HINT_PANEL_PATH := "Margin/VBox/Buttons/ActionHintPanel"
const ACTION_HINT_LABEL_PATH := "Margin/VBox/Buttons/ActionHintPanel/ActionContextLabel"
const ACTION_HINT_META_KEY := "action_hint_text"
const INVENTORY_DRAG_THRESHOLD := 14.0
const PORTRAIT_SAFE_MAX_WIDTH := 1020
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 20
const PORTRAIT_COMPACT_WIDTH := 760.0
const PORTRAIT_ULTRA_WIDTH := 600.0
const PORTRAIT_COMPACT_HEIGHT := 1520.0
const PORTRAIT_ULTRA_HEIGHT := 1240.0
const PORTRAIT_MIN_SAFE_WIDTH := 420.0
const ENEMY_HP_BAR_NAME := "EnemyHpBar"
const COMBAT_FEEDBACK_LAYER_NAME := "CombatFeedbackLayer"
const IMPACT_FLASH_NODE_NAME := "ImpactFlash"
const FEEDBACK_TEXT_LAYER_NAME := "FeedbackTextLayer"
const BAR_TWEEN_META_KEY := "bar_tween"
const BAR_INITIALIZED_META_KEY := "bar_initialized"
const FEEDBACK_TWEEN_META_KEY := "feedback_tween"
const PLAYER_FEEDBACK_Y_FACTOR := 0.6
const ENEMY_FEEDBACK_Y_FACTOR := 0.46

var _combat_flow: CombatFlow
var _presenter: RefCounted
var _inventory_presenter: RefCounted
var _run_state: RunState
var _status_lines: PackedStringArray = []
var _transition_requested: bool = false
var _action_hint_panel: PanelContainer
var _action_hint_label: Label
var _hovered_action_button: Control
var _hovered_action_accent: Color = TempScreenThemeScript.PANEL_BORDER_COLOR
var _selected_consumable_slot_index: int = -1
var _pressed_inventory_card: PanelContainer
var _pressed_inventory_slot_id: int = -1
var _pressed_inventory_slot_index: int = -1
var _pressed_inventory_family: String = ""
var _pressed_inventory_position: Vector2 = Vector2.ZERO
var _inventory_drag_active: bool = false
var _feedback_lane_by_target := {
	"player": 0,
	"enemy": 0,
}
var _feedback_lane_reset_scheduled: bool = false
var _is_compact_layout: bool = false


func _ready() -> void:
	_connect_buttons()
	_ensure_readability_shells()
	_ensure_inventory_hint_label()
	_ensure_action_hint_controls()
	_presenter = CombatPresenterScript.new()
	_inventory_presenter = InventoryPresenterScript.new()
	_configure_audio_players()
	_apply_temp_theme()
	_connect_viewport_layout_updates()
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
	_append_status_line("Combat ready.")
	SceneAudioPlayersScript.start_looping(self, "CombatMusicPlayer")
	_refresh_ui()


func _exit_tree() -> void:
	_disconnect_viewport_layout_updates()
	_stop_inventory_card_interaction()
	_hide_action_hint_panel(true)
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


func _input(event: InputEvent) -> void:
	if _pressed_inventory_card == null:
		return
	if event is InputEventMouseMotion:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		if not _inventory_drag_active and motion_event.position.distance_to(_pressed_inventory_position) >= INVENTORY_DRAG_THRESHOLD:
			_inventory_drag_active = true
			_hide_action_hint_panel(true)
			InventoryCardFactoryScript.set_card_dragging_state(_pressed_inventory_card, true)
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or mouse_event.pressed:
			return
		if _inventory_drag_active:
			_complete_inventory_card_drag()
		else:
			_handle_inventory_card_click(_pressed_inventory_slot_index, _pressed_inventory_slot_id, _pressed_inventory_family)
		_stop_inventory_card_interaction()


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
	_action_hint_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_hint_panel.size_flags_vertical = Control.SIZE_SHRINK_END
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
	_apply_action_hint_panel_style(TempScreenThemeScript.TEAL_ACCENT_COLOR)


func _update_action_hint_panel_visibility() -> void:
	_refresh_active_action_hint_panel()


func _connect_buttons() -> void:
	var attack_button: Button = get_node_or_null("Margin/VBox/Buttons/AttackButton") as Button
	var brace_button: Button = get_node_or_null("Margin/VBox/Buttons/BraceButton") as Button
	var use_item_button: Button = get_node_or_null("Margin/VBox/Buttons/UseItemButton") as Button

	if attack_button != null and not attack_button.is_connected("pressed", Callable(self, "_on_attack_pressed")):
		attack_button.connect("pressed", Callable(self, "_on_attack_pressed"))
	_connect_action_tooltip_events(attack_button, CombatFlowScript.ACTION_ATTACK, TempScreenThemeScript.RUST_ACCENT_COLOR)
	if brace_button != null and not brace_button.is_connected("pressed", Callable(self, "_on_brace_pressed")):
		brace_button.connect("pressed", Callable(self, "_on_brace_pressed"))
	_connect_action_tooltip_events(brace_button, CombatFlowScript.ACTION_BRACE, TempScreenThemeScript.TEAL_ACCENT_COLOR)
	if use_item_button != null and not use_item_button.is_connected("pressed", Callable(self, "_on_use_item_pressed")):
		use_item_button.connect("pressed", Callable(self, "_on_use_item_pressed"))
	_connect_action_tooltip_events(use_item_button, CombatFlowScript.ACTION_USE_ITEM, TempScreenThemeScript.REWARD_ACCENT_COLOR)


func _ensure_readability_shells() -> void:
	var header_stack: VBoxContainer = get_node_or_null("Margin/VBox/HeaderStack") as VBoxContainer
	if header_stack == null:
		return

	var enemy_info_vbox: VBoxContainer = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox") as VBoxContainer
	if enemy_info_vbox != null:
		var enemy_hp_label: Label = enemy_info_vbox.get_node_or_null("EnemyHpLabel") as Label
		var enemy_hp_bar: ProgressBar = enemy_info_vbox.get_node_or_null(ENEMY_HP_BAR_NAME) as ProgressBar
		if enemy_hp_bar == null:
			enemy_hp_bar = ProgressBar.new()
			enemy_hp_bar.name = ENEMY_HP_BAR_NAME
			enemy_hp_bar.show_percentage = false
			enemy_info_vbox.add_child(enemy_hp_bar)
		enemy_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if enemy_hp_label != null:
			enemy_info_vbox.move_child(enemy_hp_bar, enemy_hp_label.get_index() + 1)

		var enemy_trait_label: Label = _ensure_named_label(enemy_info_vbox, "EnemyTraitLabel")
		var enemy_type_label: Label = enemy_info_vbox.get_node_or_null("EnemyTypeLabel") as Label
		if enemy_trait_label != null and enemy_type_label != null:
			enemy_info_vbox.move_child(enemy_trait_label, enemy_type_label.get_index() + 1)
		var intent_detail_label: Label = _ensure_named_label(enemy_info_vbox, "IntentDetailLabel")
		if intent_detail_label != null:
			intent_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			intent_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			intent_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			intent_detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var intent_row: HBoxContainer = enemy_info_vbox.get_node_or_null("IntentRow") as HBoxContainer
		var intent_label: Label = enemy_info_vbox.get_node_or_null("IntentRow/IntentLabel") as Label
		if intent_label != null:
			intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			intent_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if intent_detail_label != null and intent_row != null:
			enemy_info_vbox.move_child(intent_detail_label, intent_row.get_index() + 1)

	var player_bust_frame: PanelContainer = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame") as PanelContainer
	if player_bust_frame != null:
		var hero_badge_panel: PanelContainer = player_bust_frame.get_node_or_null("HeroBadgePanel") as PanelContainer
		if hero_badge_panel == null:
			hero_badge_panel = PanelContainer.new()
			hero_badge_panel.name = "HeroBadgePanel"
			hero_badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			player_bust_frame.add_child(hero_badge_panel)
		hero_badge_panel.anchor_left = 0.0
		hero_badge_panel.anchor_top = 0.0
		hero_badge_panel.anchor_right = 0.0
		hero_badge_panel.anchor_bottom = 0.0
		hero_badge_panel.offset_left = 8.0
		hero_badge_panel.offset_top = 8.0
		hero_badge_panel.offset_right = 72.0
		hero_badge_panel.offset_bottom = 34.0
		hero_badge_panel.z_index = 2
		var hero_badge_label: Label = _ensure_named_label(hero_badge_panel, "HeroBadgeLabel")
		if hero_badge_label != null:
			hero_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hero_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var player_info_vbox: VBoxContainer = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox") as VBoxContainer
	if player_info_vbox != null:
		var player_identity_row: HBoxContainer = player_info_vbox.get_node_or_null("PlayerIdentityRow") as HBoxContainer
		if player_identity_row == null:
			player_identity_row = HBoxContainer.new()
			player_identity_row.name = "PlayerIdentityRow"
			player_info_vbox.add_child(player_identity_row)
		player_identity_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		player_identity_row.add_theme_constant_override("separation", 6)
		player_info_vbox.move_child(player_identity_row, 0)
		_ensure_named_label(player_identity_row, "PlayerNameLabel")

		var forecast_card: PanelContainer = player_info_vbox.get_node_or_null("ForecastCard") as PanelContainer
		if forecast_card == null:
			forecast_card = PanelContainer.new()
			forecast_card.name = "ForecastCard"
			player_info_vbox.add_child(forecast_card)
		forecast_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var forecast_vbox: VBoxContainer = forecast_card.get_node_or_null("ForecastVBox") as VBoxContainer
		if forecast_vbox == null:
			forecast_vbox = VBoxContainer.new()
			forecast_vbox.name = "ForecastVBox"
			forecast_card.add_child(forecast_vbox)
		forecast_vbox.add_theme_constant_override("separation", 4)

		_ensure_named_label(forecast_vbox, "ForecastTitleLabel")
		var forecast_grid: GridContainer = forecast_vbox.get_node_or_null("ForecastGrid") as GridContainer
		if forecast_grid == null:
			forecast_grid = GridContainer.new()
			forecast_grid.name = "ForecastGrid"
			forecast_grid.columns = 2
			forecast_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			forecast_vbox.add_child(forecast_grid)
		forecast_grid.add_theme_constant_override("h_separation", 8)
		forecast_grid.add_theme_constant_override("v_separation", 4)

		for label_name in [
			"ForecastAttackLabel",
			"ForecastDefenseLabel",
			"ForecastIncomingLabel",
			"ForecastBraceLabel",
			"ForecastHungerTickLabel",
			"ForecastDurabilitySpendLabel",
		]:
			var forecast_label: Label = _ensure_named_label(forecast_grid, label_name)
			_configure_single_line_label(forecast_label)

		var durability_bar: ProgressBar = player_info_vbox.get_node_or_null("DurabilityBar") as ProgressBar
		if durability_bar != null:
			player_info_vbox.move_child(forecast_card, durability_bar.get_index() + 1)

	_ensure_feedback_shells()


func _ensure_inventory_hint_label() -> void:
	var quick_item_section: VBoxContainer = _combat_secondary_node("QuickItemSection") as VBoxContainer
	if quick_item_section == null:
		return
	var inventory_hint_label: Label = quick_item_section.get_node_or_null("InventoryHintLabel") as Label
	if inventory_hint_label == null:
		inventory_hint_label = Label.new()
		inventory_hint_label.name = "InventoryHintLabel"
		inventory_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inventory_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quick_item_section.add_child(inventory_hint_label)
		quick_item_section.move_child(inventory_hint_label, 1)


func _ensure_named_label(parent: Node, label_name: String) -> Label:
	if parent == null:
		return null
	var label: Label = parent.get_node_or_null(label_name) as Label
	if label == null:
		label = Label.new()
		label.name = label_name
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(label)
	_configure_single_line_label(label)
	return label


func _configure_single_line_label(label: Label) -> void:
	if label == null:
		return
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL


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


func _on_brace_pressed() -> void:
	_resolve_player_turn(CombatFlowScript.ACTION_BRACE)


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
	_play_feedback_for_domain_event(event_name, payload)
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
		CombatFlowScript.PHASE_TURN_END:
			line = _presenter.format_turn_end_line(result)

	if not line.is_empty():
		_append_status_line(line)


func _resolve_player_turn(action_name: String, action_value: int = -1) -> void:
	if _combat_flow == null or _combat_flow.combat_state.combat_ended:
		return

	_hide_action_hint_panel(true)
	_play_action_start_sfx(action_name)
	match action_name:
		CombatFlowScript.ACTION_ATTACK:
			_combat_flow.resolve_attack_turn()
		CombatFlowScript.ACTION_BRACE:
			_combat_flow.resolve_brace_turn()
		CombatFlowScript.ACTION_USE_ITEM:
			_combat_flow.resolve_use_item_turn(action_value)
		CombatFlowScript.ACTION_CHANGE_EQUIPMENT:
			_combat_flow.resolve_change_equipment_turn(action_value)
		_:
			return

	_refresh_ui()


func _refresh_ui() -> void:
	var preview_consumable: Dictionary = {}
	var preview_snapshot: Dictionary = {}
	var turn_label: Label = get_node_or_null("Margin/VBox/HeaderStack/TurnLabel") as Label
	if turn_label != null and _combat_flow != null:
		turn_label.text = _presenter.build_turn_text(_combat_flow.combat_state)
	if _combat_flow != null:
		preview_snapshot = _combat_flow.build_preview_snapshot()
		_sync_selected_consumable_slot_index()

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

	var intent_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentRow/IntentLabel") as Label
	if intent_label != null and _combat_flow != null:
		var current_intent: Dictionary = _combat_flow.get_current_intent()
		intent_label.text = _presenter.build_intent_summary_text(current_intent)
		_apply_texture_rect_asset(
			"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentRow/IntentIcon",
			_presenter.build_intent_icon_texture_path(current_intent)
		)
	var intent_detail_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentDetailLabel") as Label
	if intent_detail_label != null:
		intent_detail_label.text = String(_presenter.build_preview_texts(preview_snapshot).get("intent_detail", "Incoming ? | Brace ?"))

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
	var forecast_title_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastTitleLabel") as Label
	if forecast_title_label != null:
		forecast_title_label.text = "Combat Forecast"

	var hp_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerHpRow/PlayerHpValueLabel") as Label
	if hp_label != null and _combat_flow != null:
		hp_label.text = _presenter.build_player_hp_text(_combat_flow.combat_state)
	_apply_texture_rect_asset(
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerHpRow/PlayerHpIcon",
		_presenter.build_hp_icon_texture_path()
	)

	var hp_bar: ProgressBar = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerHpBar") as ProgressBar
	if hp_bar != null and _combat_flow != null:
		_animate_progress_bar(hp_bar, RunState.DEFAULT_PLAYER_HP, _combat_flow.combat_state.player_hp)

	var hunger_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/HungerRow/HungerValueLabel") as Label
	if hunger_label != null and _combat_flow != null:
		hunger_label.text = _presenter.build_hunger_text(_combat_flow.combat_state)
	_apply_texture_rect_asset(
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/HungerRow/HungerIcon",
		_presenter.build_hunger_icon_texture_path()
	)

	var hunger_bar: ProgressBar = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/HungerBar") as ProgressBar
	if hunger_bar != null and _combat_flow != null:
		_animate_progress_bar(hunger_bar, RunState.DEFAULT_HUNGER, _combat_flow.combat_state.player_hunger)

	var active_weapon_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ActiveWeaponLabel") as Label
	if active_weapon_label != null and _combat_flow != null:
		active_weapon_label.text = _presenter.build_active_weapon_text(_combat_flow.combat_state)
	if _combat_flow != null:
		preview_consumable = _preview_consumable_slot()

	var durability_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/DurabilityRow/DurabilityValueLabel") as Label
	if durability_label != null and _combat_flow != null:
		durability_label.text = _presenter.build_durability_text(_combat_flow.combat_state)
	_apply_texture_rect_asset(
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/DurabilityRow/DurabilityIcon",
		_presenter.build_durability_icon_texture_path()
	)

	var durability_bar: ProgressBar = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/DurabilityBar") as ProgressBar
	if durability_bar != null and _combat_flow != null:
		var current_durability: int = int(_combat_flow.combat_state.weapon_instance.get("current_durability", 0))
		var max_durability: int = max(1, int(_combat_flow.combat_state.weapon_instance.get("max_durability", current_durability)))
		_animate_progress_bar(durability_bar, max_durability, current_durability)

	var preview_texts: Dictionary = _presenter.build_preview_texts(preview_snapshot)
	for label_name in [
		"ForecastAttackLabel",
		"ForecastDefenseLabel",
		"ForecastIncomingLabel",
		"ForecastBraceLabel",
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
			"ForecastBraceLabel":
				forecast_label.text = String(preview_texts.get("brace", "Brace ?"))
			"ForecastHungerTickLabel":
				forecast_label.text = String(preview_texts.get("hunger_tick", "Tick -1 hunger"))
			"ForecastDurabilitySpendLabel":
				forecast_label.text = String(preview_texts.get("durability_spend", "Swing -? durability"))

	var status_section: VBoxContainer = _combat_secondary_node("StatusSection") as VBoxContainer
	var player_status_title: Label = _combat_secondary_node("StatusSection/PlayerStatusTitleLabel") as Label
	var player_status_row: HFlowContainer = _combat_secondary_node("StatusSection/PlayerStatusRow") as HFlowContainer
	var enemy_status_title: Label = _combat_secondary_node("StatusSection/EnemyStatusTitleLabel") as Label
	var enemy_status_row: HFlowContainer = _combat_secondary_node("StatusSection/EnemyStatusRow") as HFlowContainer
	if status_section != null:
		status_section.visible = false
	if player_status_title != null:
		player_status_title.visible = false
	if player_status_row != null:
		player_status_row.visible = false
		_render_status_chips(player_status_row, PackedStringArray())
	if enemy_status_title != null:
		enemy_status_title.visible = false
	if enemy_status_row != null:
		enemy_status_row.visible = false
		_render_status_chips(enemy_status_row, PackedStringArray())

	# Toggle status section visibility based on whether any statuses exist
	var status_section_node: VBoxContainer = _combat_secondary_node("StatusSection") as VBoxContainer
	if status_section_node != null:
		var player_status_row_node: HFlowContainer = _combat_secondary_node("StatusSection/PlayerStatusRow") as HFlowContainer
		var enemy_status_row_node: HFlowContainer = _combat_secondary_node("StatusSection/EnemyStatusRow") as HFlowContainer
		var has_any_statuses: bool = (player_status_row_node != null and player_status_row_node.get_child_count() > 0) or (enemy_status_row_node != null and enemy_status_row_node.get_child_count() > 0)
		status_section_node.visible = has_any_statuses

	if _combat_flow != null:
		var player_status_texts: PackedStringArray = _presenter.build_status_chip_texts(_combat_flow.combat_state.player_statuses, "")
		var has_player_statuses: bool = _status_chip_list_has_entry(player_status_texts)
		if player_status_title != null:
			player_status_title.visible = has_player_statuses
		if player_status_row != null:
			player_status_row.visible = has_player_statuses
		_render_status_chips(player_status_row, player_status_texts if has_player_statuses else PackedStringArray())

		var enemy_status_texts: PackedStringArray = _presenter.build_status_chip_texts(_combat_flow.combat_state.enemy_statuses, "")
		var has_enemy_statuses: bool = _status_chip_list_has_entry(enemy_status_texts)
		if enemy_status_title != null:
			enemy_status_title.visible = has_enemy_statuses
		if enemy_status_row != null:
			enemy_status_row.visible = has_enemy_statuses
		if has_enemy_statuses:
			_render_status_chips(
				enemy_status_row,
				enemy_status_texts
			)
		if status_section != null:
			status_section.visible = has_player_statuses or has_enemy_statuses

	var status_label: Label = _combat_secondary_node("CombatLogCard/CombatLogLabel") as Label
	if status_label != null:
		status_label.text = _presenter.build_status_log_text(_status_lines)

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


func _play_feedback_for_domain_event(event_name: String, payload: Dictionary) -> void:
	if _presenter == null:
		return

	match event_name:
		"DamageApplied":
			var amount: int = int(payload.get("amount", 0))
			if amount <= 0:
				return
			_play_feedback_burst(_presenter.build_impact_feedback_model(String(payload.get("target", "enemy")), amount))
		"BraceMitigated":
			_play_feedback_burst(
				_presenter.build_brace_feedback_model(
					int(payload.get("raw_damage", 0)),
					int(payload.get("reduced_damage", 0))
				)
			)
		"ConsumableUsed":
			var models: Array[Dictionary] = _presenter.build_recovery_feedback_models(
				int(payload.get("healed_amount", 0)),
				int(payload.get("hunger_restored_amount", 0))
			)
			for model in models:
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
	_feedback_lane_reset_scheduled = false


func _play_feedback_flash(flash: ColorRect, model: Dictionary, lane_index: int) -> void:
	if flash == null:
		return

	_kill_control_tween(flash, FEEDBACK_TWEEN_META_KEY)
	var flash_color: Color = Color(model.get("flash_color", TempScreenThemeScript.RUST_ACCENT_COLOR))
	var target_alpha: float = float(model.get("flash_alpha", 0.2))
	flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
	var tween: Tween = create_tween()
	flash.set_meta(FEEDBACK_TWEEN_META_KEY, tween)
	tween.tween_interval(float(lane_index) * 0.05)
	tween.tween_property(flash, "color", Color(flash_color.r, flash_color.g, flash_color.b, target_alpha), 0.08)
	tween.tween_property(flash, "color", Color(flash_color.r, flash_color.g, flash_color.b, 0.0), 0.22)
	tween.finished.connect(Callable(self, "_clear_control_meta").bind(flash, FEEDBACK_TWEEN_META_KEY), CONNECT_ONE_SHOT)


func _play_feedback_pulse(pulse_control: Control, model: Dictionary, lane_index: int) -> void:
	if pulse_control == null:
		return

	_kill_control_tween(pulse_control, FEEDBACK_TWEEN_META_KEY)
	pulse_control.scale = Vector2.ONE
	pulse_control.pivot_offset = pulse_control.size * 0.5
	var target_scale: float = float(model.get("pulse_scale", 1.03))
	var tween: Tween = create_tween()
	pulse_control.set_meta(FEEDBACK_TWEEN_META_KEY, tween)
	tween.tween_interval(float(lane_index) * 0.05)
	tween.tween_property(pulse_control, "scale", Vector2.ONE * target_scale, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse_control, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(Callable(self, "_clear_control_meta").bind(pulse_control, FEEDBACK_TWEEN_META_KEY), CONNECT_ONE_SHOT)


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

	var delay_seconds: float = float(lane_index) * 0.05
	var motion_tween: Tween = create_tween()
	motion_tween.tween_interval(delay_seconds)
	motion_tween.tween_property(label, "position", end_position, 0.54).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var scale_tween: Tween = create_tween()
	scale_tween.tween_interval(delay_seconds)
	scale_tween.tween_property(label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var fade_tween: Tween = create_tween()
	fade_tween.tween_interval(delay_seconds)
	fade_tween.tween_property(label, "modulate", Color(1, 1, 1, 1), 0.08)
	fade_tween.tween_interval(0.18)
	fade_tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 0.2)
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

	var tween: Tween = create_tween()
	bar.set_meta(BAR_TWEEN_META_KEY, tween)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(bar, "value", clamped_value, 0.24)
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


func _extract_enemy_max_hp_from_state(combat_state: CombatState) -> int:
	if combat_state == null:
		return 1
	var rules: Dictionary = combat_state.enemy_definition.get("rules", {})
	var stats: Dictionary = rules.get("stats", {})
	return max(1, int(stats.get("base_hp", combat_state.enemy_hp)))


func _configure_audio_players() -> void:
	SceneAudioPlayersScript.assign_stream_from_path(self, "AttackResolveSfxPlayer", ATTACK_RESOLVE_SFX_PATH)
	SceneAudioPlayersScript.assign_stream_from_path(self, "BraceSfxPlayer", BRACE_SFX_PATH)
	SceneAudioPlayersScript.assign_stream_from_path(self, "ItemUseSfxPlayer", ITEM_USE_SFX_PATH)
	SceneAudioPlayersScript.assign_music_stream_from_path(self, "CombatMusicPlayer", COMBAT_MUSIC_LOOP_PATH, true)


func _set_buttons_enabled(is_enabled: bool) -> void:
	if not is_enabled:
		_hide_action_hint_panel(true)
	for node_name in ["AttackButton", "BraceButton", "UseItemButton"]:
		var button: Button = get_node_or_null("Margin/VBox/Buttons/%s" % node_name) as Button
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
		CombatFlowScript.ACTION_BRACE:
			SceneAudioPlayersScript.play(self, "BraceSfxPlayer")
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
		"weapon", "armor", "belt":
			return _combat_flow.can_change_equipment_slot(int(card_model.get("inventory_slot_id", -1)))
		_:
			return false


func _inventory_card_is_draggable(card_model: Dictionary) -> bool:
	return String(card_model.get("card_family", "")) != "empty"


func _inventory_card_is_selected(card_model: Dictionary) -> bool:
	if String(card_model.get("card_family", "")) != "consumable":
		return false
	var slot_index: int = int(card_model.get("slot_index", -1))
	return _combat_flow != null and _combat_flow.is_consumable_slot_usable(slot_index) and slot_index == _selected_consumable_slot_index


func _refresh_inventory_cards() -> void:
	var container: Container = _combat_secondary_node("QuickItemSection/InventoryCard/InventoryCardsFlow") as Container
	if container == null or _inventory_presenter == null:
		return

	_hide_action_hint_panel(true)
	var inventory_title_label: Label = _combat_secondary_node("QuickItemSection/InventoryTitleLabel") as Label
	if inventory_title_label != null:
		inventory_title_label.text = _inventory_presenter.build_inventory_title_text(_run_state.inventory_state if _run_state != null else null)
	var inventory_hint_label: Label = _combat_secondary_node("QuickItemSection/InventoryHintLabel") as Label
	if inventory_hint_label != null:
		inventory_hint_label.text = _inventory_presenter.build_combat_inventory_hint_text()

	var card_models: Array[Dictionary] = _inventory_presenter.build_combat_inventory_cards(
		_combat_flow.combat_state if _combat_flow != null else null,
		_run_state.inventory_state if _run_state != null else null
	)
	for index in range(card_models.size()):
		var card_model: Dictionary = card_models[index]
		var is_clickable: bool = _inventory_card_is_clickable(card_model)
		var is_selected: bool = _inventory_card_is_selected(card_model)
		var is_draggable: bool = _inventory_card_is_draggable(card_model)
		card_model["is_clickable"] = is_clickable
		card_model["is_selected"] = is_selected
		card_model["is_draggable"] = is_draggable
		card_models[index] = _inventory_presenter.decorate_card_interaction_state(
			card_model,
			true,
			is_clickable,
			is_selected,
			is_draggable
		)

	var cards: Array[PanelContainer] = InventoryCardFactoryScript.rebuild_cards(container, card_models)
	for index in range(min(cards.size(), card_models.size())):
		_connect_inventory_card_interactions(cards[index], card_models[index])


func _connect_inventory_card_interactions(card: PanelContainer, card_model: Dictionary) -> void:
	if card == null:
		return
	var input_handler := Callable(self, "_on_inventory_card_gui_input").bind(card)
	if not card.is_connected("gui_input", input_handler):
		card.connect("gui_input", input_handler)


func _on_inventory_card_gui_input(event: InputEvent, card: PanelContainer) -> void:
	if event == null:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_event.pressed:
		return
	_pressed_inventory_card = card
	_pressed_inventory_slot_index = int(card.get_meta("slot_index", -1))
	_pressed_inventory_slot_id = int(card.get_meta("inventory_slot_id", -1))
	_pressed_inventory_family = String(card.get_meta("card_family", ""))
	_pressed_inventory_position = mouse_event.position + card.get_global_rect().position
	_inventory_drag_active = false


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
		"weapon", "armor", "belt":
			if not _combat_flow.can_change_equipment_slot(inventory_slot_id):
				if card_family == "belt" and _combat_flow.combat_state != null and int(_combat_flow.combat_state.active_belt_slot_id) == inventory_slot_id:
					_append_status_line("Free 2 inventory space before unequipping that belt.")
				else:
					_append_status_line("That gear cannot be changed right now.")
				_refresh_ui()
				return
			_resolve_player_turn(CombatFlowScript.ACTION_CHANGE_EQUIPMENT, inventory_slot_id)
		_:
			return


func _complete_inventory_card_drag() -> void:
	if _combat_flow == null or _pressed_inventory_card == null:
		return
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var hovered_control: Control = viewport.gui_get_hovered_control()
	var target_card: PanelContainer = _find_inventory_card_from_control(hovered_control)
	if target_card == null:
		return
	var target_index: int = int(target_card.get_meta("inventory_slot_index", -1))
	if _pressed_inventory_slot_id <= 0 or target_index < 0:
		return
	var move_result: Dictionary = _combat_flow.reorder_inventory_slot(_pressed_inventory_slot_id, target_index)
	if not bool(move_result.get("ok", false)):
		_append_status_line("Inventory reorder failed.")
		return
	_sync_selected_consumable_slot_index()
	_refresh_ui()


func _find_inventory_card_from_control(control: Control) -> PanelContainer:
	var cursor: Node = control
	while cursor != null:
		if cursor is PanelContainer and String((cursor as PanelContainer).name).begins_with("InventorySlot"):
			return cursor as PanelContainer
		cursor = cursor.get_parent()
	return null


func _stop_inventory_card_interaction() -> void:
	if _pressed_inventory_card != null and is_instance_valid(_pressed_inventory_card):
		InventoryCardFactoryScript.set_card_dragging_state(_pressed_inventory_card, false)
	_pressed_inventory_card = null
	_pressed_inventory_slot_id = -1
	_pressed_inventory_slot_index = -1
	_pressed_inventory_family = ""
	_pressed_inventory_position = Vector2.ZERO
	_inventory_drag_active = false


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

	var texture: Texture2D = _load_texture_or_null(asset_path)
	texture_rect.texture = texture
	frame.visible = texture != null


func _apply_texture_rect_asset(node_path: String, asset_path: String) -> void:
	var texture_rect: TextureRect = get_node_or_null(node_path) as TextureRect
	if texture_rect == null:
		return

	var texture: Texture2D = _load_texture_or_null(asset_path)
	texture_rect.texture = texture
	texture_rect.visible = texture != null


func _load_texture_or_null(asset_path: String) -> Texture2D:
	if asset_path.is_empty():
		return null

	var resource: Resource = load(asset_path)
	if resource is Texture2D:
		return resource as Texture2D
	return null


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
	var attack_button: Button = get_node_or_null("Margin/VBox/Buttons/AttackButton") as Button
	var brace_button: Button = get_node_or_null("Margin/VBox/Buttons/BraceButton") as Button
	var use_item_button: Button = get_node_or_null("Margin/VBox/Buttons/UseItemButton") as Button
	var combat_state: CombatState = _combat_flow.combat_state if _combat_flow != null else null
	var attack_tooltip_text: String = ""
	var brace_tooltip_text: String = ""
	var use_item_tooltip_text: String = ""

	if attack_button != null:
		attack_tooltip_text = _presenter.build_action_tooltip_text(CombatFlowScript.ACTION_ATTACK, combat_state, {}, preview_snapshot)
		_set_action_hint_text(
			attack_button,
			attack_tooltip_text
		)
	if brace_button != null:
		brace_tooltip_text = _presenter.build_action_tooltip_text(CombatFlowScript.ACTION_BRACE, combat_state, {}, preview_snapshot)
		_set_action_hint_text(
			brace_button,
			brace_tooltip_text
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
	_action_hint_panel.visible = true

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


func _hide_action_hint_panel(clear_hovered_button: bool = false) -> void:
	if _action_hint_panel != null:
		_action_hint_panel.visible = false
	if clear_hovered_button:
		_hovered_action_button = null


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




func _apply_temp_theme() -> void:
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderStack/ScreenTitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderStack/TurnLabel") as Label, "accent")
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR)
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard") as PanelContainer)
	TempScreenThemeScript.apply_panel(_combat_secondary_node("CombatLogCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 16, 0.84)
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 14, 0.78)
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 14, 0.78)
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/BossTokenFrame") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 12, 0.78)
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard") as PanelContainer, TempScreenThemeScript.REWARD_ACCENT_COLOR, 14, 0.76)
	TempScreenThemeScript.apply_panel(_combat_secondary_node("QuickItemSection/InventoryCard") as PanelContainer, TempScreenThemeScript.REWARD_ACCENT_COLOR, 14, 0.82)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 3, 24, 0.03, 0.24, 18, 16)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 3, 24, 0.03, 0.22, 18, 16)
	TempScreenThemeScript.intensify_panel(_combat_secondary_node("CombatLogCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 3, 18, 0.03, 0.2, 18, 16)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 2, 14, 0.03, 0.24)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 2, 14, 0.03, 0.2)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/BossTokenFrame") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 2, 12, 0.03, 0.24)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard") as PanelContainer, TempScreenThemeScript.REWARD_ACCENT_COLOR, 3, 18, 0.04, 0.22, 16, 14)
	TempScreenThemeScript.intensify_panel(_combat_secondary_node("QuickItemSection/InventoryCard") as PanelContainer, TempScreenThemeScript.REWARD_ACCENT_COLOR, 3, 18, 0.04, 0.22, 16, 14)
	_apply_progress_bar_style(
		get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/%s" % ENEMY_HP_BAR_NAME) as ProgressBar,
		TempScreenThemeScript.RUST_ACCENT_COLOR,
		TempScreenThemeScript.RUST_ACCENT_COLOR
	)
	_apply_progress_bar_style(
		get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerHpBar") as ProgressBar,
		TempScreenThemeScript.RUST_ACCENT_COLOR,
		TempScreenThemeScript.RUST_ACCENT_COLOR
	)
	_apply_progress_bar_style(
		get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/HungerBar") as ProgressBar,
		TempScreenThemeScript.REWARD_ACCENT_COLOR,
		TempScreenThemeScript.REWARD_ACCENT_COLOR
	)
	_apply_progress_bar_style(
		get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/DurabilityBar") as ProgressBar,
		TempScreenThemeScript.TEAL_ACCENT_COLOR,
		TempScreenThemeScript.TEAL_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_chip(
		get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/HeroBadgePanel") as PanelContainer,
		get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/HeroBadgePanel/HeroBadgeLabel") as Label,
		TempScreenThemeScript.REWARD_ACCENT_COLOR
	)

	for label_path in [
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyNameLabel",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyTraitLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerHpRow/PlayerHpValueLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/HungerRow/HungerValueLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerIdentityRow/PlayerNameLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ActiveWeaponLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/DurabilityRow/DurabilityValueLabel",
		"StatusSection/PlayerStatusTitleLabel",
		"StatusSection/EnemyStatusTitleLabel",
	]:
		TempScreenThemeScript.apply_label(_combat_secondary_node(label_path) as Label, "accent")

	for label_path in [
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentDetailLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastTitleLabel",
	]:
		TempScreenThemeScript.apply_label(get_node_or_null(label_path) as Label, "reward")

	for label_path in [
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastAttackLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastDefenseLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastIncomingLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastBraceLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastHungerTickLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastDurabilitySpendLabel",
	]:
		TempScreenThemeScript.apply_label(get_node_or_null(label_path) as Label)

	TempScreenThemeScript.apply_label(_combat_secondary_node("CombatLogCard/CombatLogLabel") as Label)
	TempScreenThemeScript.apply_label(_combat_secondary_node("QuickItemSection/InventoryTitleLabel") as Label, "reward")
	TempScreenThemeScript.apply_label(_combat_secondary_node("QuickItemSection/InventoryHintLabel") as Label, "muted")
	TempScreenThemeScript.apply_button(get_node_or_null("Margin/VBox/Buttons/AttackButton") as Button, TempScreenThemeScript.RUST_ACCENT_COLOR)
	TempScreenThemeScript.apply_button(get_node_or_null("Margin/VBox/Buttons/BraceButton") as Button, TempScreenThemeScript.TEAL_ACCENT_COLOR)
	TempScreenThemeScript.apply_button(get_node_or_null("Margin/VBox/Buttons/UseItemButton") as Button, TempScreenThemeScript.REWARD_ACCENT_COLOR)

	var turn_label: Label = get_node_or_null("Margin/VBox/HeaderStack/TurnLabel") as Label
	if turn_label != null:
		turn_label.add_theme_font_size_override("font_size", 24)

	for label_path in [
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyNameLabel",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyHpLabel",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyTraitLabel",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentDetailLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerIdentityRow/PlayerNameLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerHpRow/PlayerHpValueLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/HungerRow/HungerValueLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ActiveWeaponLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/DurabilityRow/DurabilityValueLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastTitleLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastAttackLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastDefenseLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastIncomingLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastBraceLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastHungerTickLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastDurabilitySpendLabel",
	]:
		var info_label: Label = _combat_secondary_node(label_path) as Label
		if info_label != null:
			info_label.add_theme_font_size_override("font_size", 22)

	for icon_path in [
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerHpRow/PlayerHpIcon",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/HungerRow/HungerIcon",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/DurabilityRow/DurabilityIcon",
	]:
		var icon_rect: TextureRect = get_node_or_null(icon_path) as TextureRect
		if icon_rect != null:
			icon_rect.custom_minimum_size = Vector2(24, 24)
			icon_rect.modulate = Color(0.96, 0.93, 0.82, 0.95)

	var combat_log_label: Label = _combat_secondary_node("CombatLogCard/CombatLogLabel") as Label
	if combat_log_label != null:
		combat_log_label.add_theme_font_size_override("font_size", 20)

	var inventory_title_label: Label = _combat_secondary_node("QuickItemSection/InventoryTitleLabel") as Label
	if inventory_title_label != null:
		inventory_title_label.add_theme_font_size_override("font_size", 20)
	var inventory_hint_label: Label = _combat_secondary_node("QuickItemSection/InventoryHintLabel") as Label
	if inventory_hint_label != null:
		inventory_hint_label.add_theme_font_size_override("font_size", 15)

	var hero_badge_label: Label = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/HeroBadgePanel/HeroBadgeLabel") as Label
	if hero_badge_label != null:
		hero_badge_label.add_theme_font_size_override("font_size", 14)

	for button_path in [
		"Margin/VBox/Buttons/AttackButton",
		"Margin/VBox/Buttons/BraceButton",
		"Margin/VBox/Buttons/UseItemButton",
	]:
		var action_button: Button = get_node_or_null(button_path) as Button
		if action_button != null:
			action_button.custom_minimum_size.y = max(action_button.custom_minimum_size.y, 74.0)
			action_button.add_theme_font_size_override("font_size", 20)


func _apply_progress_bar_style(bar: ProgressBar, accent: Color, fill_color: Color) -> void:
	if bar == null:
		return

	var background_style := StyleBoxFlat.new()
	background_style.bg_color = TempScreenThemeScript.PANEL_SOFT_FILL_COLOR.darkened(0.18)
	background_style.border_color = accent.darkened(0.18)
	background_style.border_width_left = 2
	background_style.border_width_top = 2
	background_style.border_width_right = 2
	background_style.border_width_bottom = 2
	background_style.corner_radius_top_left = 10
	background_style.corner_radius_top_right = 10
	background_style.corner_radius_bottom_left = 10
	background_style.corner_radius_bottom_right = 10
	background_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.16)
	background_style.shadow_size = 8

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color.lightened(0.04)
	fill_style.corner_radius_top_left = 8
	fill_style.corner_radius_top_right = 8
	fill_style.corner_radius_bottom_left = 8
	fill_style.corner_radius_bottom_right = 8

	bar.add_theme_stylebox_override("background", background_style)
	bar.add_theme_stylebox_override("fill", fill_style)
	bar.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	bar.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.84))
	bar.add_theme_constant_override("outline_size", 4)


func _connect_viewport_layout_updates() -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var size_changed_handler := Callable(self, "_on_viewport_size_changed")
	if not viewport.is_connected("size_changed", size_changed_handler):
		viewport.connect("size_changed", size_changed_handler)


func _disconnect_viewport_layout_updates() -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var size_changed_handler := Callable(self, "_on_viewport_size_changed")
	if viewport.is_connected("size_changed", size_changed_handler):
		viewport.disconnect("size_changed", size_changed_handler)


func _on_viewport_size_changed() -> void:
	_apply_portrait_safe_layout()
	_refresh_active_action_hint_panel()


func _apply_portrait_safe_layout() -> void:
	var margin: MarginContainer = get_node_or_null("Margin") as MarginContainer
	var vbox: VBoxContainer = get_node_or_null("Margin/VBox") as VBoxContainer
	var header_stack: VBoxContainer = get_node_or_null("Margin/VBox/HeaderStack") as VBoxContainer
	var battle_cards_row: VBoxContainer = get_node_or_null("Margin/VBox/BattleCardsRow") as VBoxContainer
	var buttons_box: VBoxContainer = get_node_or_null("Margin/VBox/Buttons") as VBoxContainer
	var secondary_scroll: ScrollContainer = get_node_or_null(COMBAT_SECONDARY_SCROLL_PATH) as ScrollContainer
	var secondary_scroll_content: VBoxContainer = get_node_or_null(COMBAT_SECONDARY_SCROLL_CONTENT_PATH) as VBoxContainer
	var quick_item_section: VBoxContainer = _combat_secondary_node("QuickItemSection") as VBoxContainer
	if margin == null or vbox == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var is_portrait: bool = viewport_size.y >= viewport_size.x
	var top_margin: int = 30
	var bottom_margin: int = 30
	if viewport_size.y < 1680.0:
		top_margin = 24
		bottom_margin = 24
	if viewport_size.y < 1480.0:
		top_margin = 18
		bottom_margin = 18
	if not is_portrait:
		top_margin = 14
		bottom_margin = 14

	var safe_width: int = TempScreenThemeScript.apply_portrait_safe_margins(
		margin,
		PORTRAIT_SAFE_MAX_WIDTH,
		PORTRAIT_SAFE_MIN_SIDE_MARGIN,
		top_margin,
		bottom_margin
	)

	var compact_layout: bool = safe_width < PORTRAIT_COMPACT_WIDTH or (is_portrait and viewport_size.y < PORTRAIT_COMPACT_HEIGHT) or (viewport_size.x < PORTRAIT_MIN_SAFE_WIDTH)
	var ultra_compact_layout: bool = compact_layout and (safe_width < PORTRAIT_ULTRA_WIDTH or viewport_size.y < PORTRAIT_ULTRA_HEIGHT)
	var large_layout: bool = not compact_layout and safe_width >= 900 and viewport_size.y >= 1700.0
	var medium_layout: bool = not large_layout and not compact_layout and safe_width >= PORTRAIT_COMPACT_WIDTH and viewport_size.y >= 1500.0
	_is_compact_layout = compact_layout

	vbox.size_flags_vertical = 3
	header_stack.size_flags_vertical = 0 if header_stack != null else 0
	battle_cards_row.size_flags_vertical = 1
	buttons_box.size_flags_vertical = 0 if buttons_box != null else 0
	if secondary_scroll != null:
		secondary_scroll.size_flags_vertical = 3
		secondary_scroll.size_flags_horizontal = 3
	if secondary_scroll_content != null:
		secondary_scroll_content.size_flags_vertical = 1

	var status_section: VBoxContainer = _combat_secondary_node("StatusSection") as VBoxContainer
	if status_section != null:
		status_section.size_flags_vertical = 0
	quick_item_section = _combat_secondary_node("QuickItemSection") as VBoxContainer
	if quick_item_section != null:
		quick_item_section.size_flags_vertical = 0
	var combat_log_card: PanelContainer = _combat_secondary_node("CombatLogCard") as PanelContainer
	if combat_log_card != null:
		combat_log_card.size_flags_vertical = 0
	var inventory_card: PanelContainer = _combat_secondary_node("QuickItemSection/InventoryCard") as PanelContainer
	if inventory_card != null:
		inventory_card.size_flags_vertical = 1

	_update_action_hint_panel_visibility()

	var compact_spacing: int = 8
	var normal_spacing: int = 16 if viewport_size.y >= 1640.0 else 14

	var base_spacing: int = normal_spacing
	if ultra_compact_layout:
		base_spacing = 6
	elif compact_layout:
		base_spacing = compact_spacing
	vbox.add_theme_constant_override("separation", base_spacing)
	if header_stack != null:
		header_stack.add_theme_constant_override("separation", 4 if not compact_layout else 3)
	if battle_cards_row != null:
		battle_cards_row.add_theme_constant_override("separation", (12 if not compact_layout else 6))
	if buttons_box != null:
		buttons_box.add_theme_constant_override("separation", (10 if not compact_layout else 5))
	if quick_item_section != null:
		quick_item_section.add_theme_constant_override("separation", (8 if not compact_layout else 5))

	var enemy_bust_size: Vector2 = Vector2(146, 214) if large_layout else Vector2(128, 188) if medium_layout else Vector2(108, 158) if not ultra_compact_layout else Vector2(84, 132)
	var player_bust_size: Vector2 = Vector2(168, 244) if large_layout else Vector2(148, 214) if medium_layout else Vector2(122, 190) if not ultra_compact_layout else Vector2(90, 150)
	var boss_token_size: Vector2 = Vector2(88, 88) if large_layout else Vector2(76, 76) if medium_layout else Vector2(62, 62) if not ultra_compact_layout else Vector2(50, 50)
	var status_icon_size: Vector2 = Vector2(30, 30) if large_layout else Vector2(26, 26) if medium_layout else Vector2(22, 22) if not ultra_compact_layout else Vector2(18, 18)
	var forecast_height: float = 118.0 if large_layout else 106.0 if medium_layout else 84.0 if not ultra_compact_layout else 72.0
	var button_height: float = 72.0 if large_layout else 64.0 if medium_layout else 54.0 if not ultra_compact_layout else 46.0
	var title_font_size: int = 48 if large_layout else 40 if medium_layout else 30 if not ultra_compact_layout else 24
	var turn_font_size: int = 28 if large_layout else 24 if medium_layout else 20 if not ultra_compact_layout else 18
	var body_font_size: int = 26 if large_layout else 23 if medium_layout else 18 if not ultra_compact_layout else 16
	var log_font_size: int = 24 if large_layout else 21 if medium_layout else 17 if not ultra_compact_layout else 15
	var button_font_size: int = 26 if large_layout else 23 if medium_layout else 18 if not ultra_compact_layout else 16
	var slot_height: float = 84.0 if large_layout else 74.0 if medium_layout else 60.0 if not ultra_compact_layout else 48.0
	var combat_log_height: float = 108.0 if large_layout else 92.0 if medium_layout else 68.0 if not ultra_compact_layout else 54.0

	var screen_title: Label = get_node_or_null("Margin/VBox/HeaderStack/ScreenTitleLabel") as Label
	if screen_title != null:
		screen_title.add_theme_font_size_override("font_size", title_font_size)

	var turn_label: Label = get_node_or_null("Margin/VBox/HeaderStack/TurnLabel") as Label
	if turn_label != null:
		turn_label.add_theme_font_size_override("font_size", turn_font_size)

	var hero_badge_panel: PanelContainer = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/HeroBadgePanel") as PanelContainer
	if hero_badge_panel != null:
		hero_badge_panel.offset_right = 82.0 if large_layout else 74.0 if medium_layout else 66.0
		hero_badge_panel.offset_bottom = 38.0 if large_layout else 34.0 if medium_layout else 30.0

	var boss_token_frame: PanelContainer = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/BossTokenFrame") as PanelContainer
	if boss_token_frame != null:
		boss_token_frame.custom_minimum_size = boss_token_size
	var boss_token_texture: TextureRect = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/BossTokenFrame/BossTokenTexture") as TextureRect
	if boss_token_texture != null:
		boss_token_texture.custom_minimum_size = boss_token_size

	var intent_icon: TextureRect = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentRow/IntentIcon") as TextureRect
	if intent_icon != null:
		intent_icon.custom_minimum_size = status_icon_size

	for icon_path in [
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerHpRow/PlayerHpIcon",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/HungerRow/HungerIcon",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/DurabilityRow/DurabilityIcon",
	]:
		var icon_rect: TextureRect = get_node_or_null(icon_path) as TextureRect
		if icon_rect != null:
			icon_rect.custom_minimum_size = status_icon_size

	for label_path in [
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyNameLabel",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyTypeLabel",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyHpLabel",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyTraitLabel",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentDetailLabel",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentRow/IntentLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerIdentityRow/PlayerNameLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerHpRow/PlayerHpValueLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/HungerRow/HungerValueLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ActiveWeaponLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/DurabilityRow/DurabilityValueLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastTitleLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastAttackLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastDefenseLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastIncomingLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastBraceLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastHungerTickLabel",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastDurabilitySpendLabel",
		"StatusSection/PlayerStatusTitleLabel",
		"StatusSection/EnemyStatusTitleLabel",
		"QuickItemSection/InventoryTitleLabel",
	]:
		var info_label: Label = _combat_secondary_node(label_path) as Label
		if info_label != null:
			info_label.add_theme_font_size_override("font_size", body_font_size)
			if label_path == "Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentDetailLabel" or label_path == "Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentRow/IntentLabel":
				info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inventory_hint_label: Label = _combat_secondary_node("QuickItemSection/InventoryHintLabel") as Label
	if inventory_hint_label != null:
		inventory_hint_label.add_theme_font_size_override("font_size", max(14, body_font_size - 5))

	for bar_path in [
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/%s" % ENEMY_HP_BAR_NAME,
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerHpBar",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/HungerBar",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/DurabilityBar",
	]:
		var bar: ProgressBar = get_node_or_null(bar_path) as ProgressBar
		if bar != null:
			bar.custom_minimum_size = Vector2(0.0, 20.0 if large_layout else 18.0 if medium_layout else 16.0)

	var combat_log_label: Label = _combat_secondary_node("CombatLogCard/CombatLogLabel") as Label
	if combat_log_label != null:
		combat_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		combat_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		combat_log_label.add_theme_font_size_override("font_size", log_font_size)

	# Set bust frame sizes from layout tier
	var enemy_bust_frame: PanelContainer = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame") as PanelContainer
	if enemy_bust_frame != null:
		enemy_bust_frame.custom_minimum_size = enemy_bust_size
	var enemy_bust_texture: TextureRect = get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame/BustTexture") as TextureRect
	if enemy_bust_texture != null:
		enemy_bust_texture.custom_minimum_size = enemy_bust_size

	var player_bust_frame: PanelContainer = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame") as PanelContainer
	if player_bust_frame != null:
		player_bust_frame.custom_minimum_size = player_bust_size
	var player_bust_texture: TextureRect = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/BustTexture") as TextureRect
	if player_bust_texture != null:
		player_bust_texture.custom_minimum_size = player_bust_size

	var forecast_card: PanelContainer = get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard") as PanelContainer
	if forecast_card != null:
		forecast_card.custom_minimum_size = Vector2(0.0, forecast_height)

	for button_path in [
		"Margin/VBox/Buttons/AttackButton",
		"Margin/VBox/Buttons/BraceButton",
		"Margin/VBox/Buttons/UseItemButton",
	]:
		var action_button: Button = get_node_or_null(button_path) as Button
		if action_button != null:
			action_button.custom_minimum_size = Vector2(0.0, button_height)
			action_button.add_theme_font_size_override("font_size", button_font_size)
			action_button.add_theme_constant_override("icon_max_width", 34 if large_layout else 30 if medium_layout else 26)

	inventory_card = _combat_secondary_node("QuickItemSection/InventoryCard") as PanelContainer
	if inventory_card != null:
		inventory_card.custom_minimum_size = Vector2(0.0, max(slot_height * 1.8, 128.0 if large_layout else 124.0 if medium_layout else 116.0))

	combat_log_card = _combat_secondary_node("CombatLogCard") as PanelContainer
	if combat_log_card != null:
		combat_log_card.custom_minimum_size = Vector2(0.0, combat_log_height)

	var player_status_title: Label = _combat_secondary_node("StatusSection/PlayerStatusTitleLabel") as Label
	if player_status_title != null:
		player_status_title.add_theme_font_size_override("font_size", max(14, body_font_size - 2))
	var enemy_status_title: Label = _combat_secondary_node("StatusSection/EnemyStatusTitleLabel") as Label
	if enemy_status_title != null:
		enemy_status_title.add_theme_font_size_override("font_size", max(14, body_font_size - 2))
	var player_status_row: HFlowContainer = _combat_secondary_node("StatusSection/PlayerStatusRow") as HFlowContainer
	if player_status_row != null:
		player_status_row.add_theme_constant_override("h_separation", 4 if not compact_layout else 3)
		player_status_row.add_theme_constant_override("v_separation", 4 if not compact_layout else 3)
	var enemy_status_row: HFlowContainer = _combat_secondary_node("StatusSection/EnemyStatusRow") as HFlowContainer
	if enemy_status_row != null:
		enemy_status_row.add_theme_constant_override("h_separation", 5 if not compact_layout else 3)
		enemy_status_row.add_theme_constant_override("v_separation", 4 if not compact_layout else 3)
