# Layer: Scenes - presentation only
extends Control

const MapExplorePresenterScript = preload("res://Game/UI/map_explore_presenter.gd")
const InventoryPresenterScript = preload("res://Game/UI/inventory_presenter.gd")
const InventoryCardFactoryScript = preload("res://Game/UI/inventory_card_factory.gd")
const MapBoardStyleScript = preload("res://Game/UI/map_board_style.gd")
const MapBoardComposerV2Script = preload("res://Game/UI/map_board_composer_v2.gd")
const MapExploreSceneUiScript = preload("res://Game/UI/map_explore_scene_ui.gd")
const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const EventSceneScript: PackedScene = preload("res://scenes/event.tscn")
const SupportInteractionSceneScript: PackedScene = preload("res://scenes/support_interaction.tscn")
const RewardSceneScript: PackedScene = preload("res://scenes/reward.tscn")
const LevelUpSceneScript: PackedScene = preload("res://scenes/level_up.tscn")
const MAP_BOARD_BACKDROP_TEXTURE: Texture2D = preload("res://Assets/UI/Map/ui_map_board_backdrop.svg")
const MAP_WALKER_IDLE_TEXTURE: Texture2D = preload("res://Assets/UI/Map/Walker/ui_map_walker_idle.svg")
const MAP_WALKER_WALK_A_TEXTURE: Texture2D = preload("res://Assets/UI/Map/Walker/ui_map_walker_walk_a.svg")
const MAP_WALKER_WALK_B_TEXTURE: Texture2D = preload("res://Assets/UI/Map/Walker/ui_map_walker_walk_b.svg")
const KEY_MARKER_ICON_TEXTURE: Texture2D = preload("res://Assets/Icons/icon_confirm.svg")
const EVENT_OVERLAY_OPEN_DURATION := 0.26
const EVENT_OVERLAY_CLOSE_DURATION := 0.2
const EVENT_OVERLAY_OPEN_SCALE := 0.985
const EVENT_OVERLAY_CLOSED_SCALE := 0.965
const EVENT_OVERLAY_Z_INDEX := 180
const EVENT_OVERLAY_FAR_ALPHA := 0.04
const EVENT_OVERLAY_MID_ALPHA := 0.08
const EVENT_OVERLAY_OVERLAY_ALPHA := 0.03
const EVENT_OVERLAY_SCRIM_ALPHA := 0.20
const EVENT_OVERLAY_TWEEN_TRANSITION := Tween.TRANS_EXPO
const NODE_SELECT_SFX_PATH := "res://Assets/Audio/SFX/sfx_node_select_01.ogg"
const MAP_MUSIC_LOOP_PATH := "res://Assets/Audio/Music/music_ui_hub_loop_temp_01.ogg"
const AUDIO_PLAYER_NODE_NAMES: Array[String] = [
	"NodeSelectSfxPlayer",
	"MapMusicPlayer",
]
const INVENTORY_TOOLTIP_PANEL_NAME := "InventoryTooltipPanel"
const INVENTORY_TOOLTIP_LABEL_NAME := "InventoryTooltipLabel"
const INVENTORY_TOOLTIP_MARGIN := 16.0
const INVENTORY_TOOLTIP_GAP := 12.0
const INVENTORY_TOOLTIP_MAX_WIDTH := 320.0
const INVENTORY_TOOLTIP_META_KEY := "custom_tooltip_text"
const INVENTORY_DRAG_THRESHOLD := 14.0
const PORTRAIT_SAFE_MAX_WIDTH := 1120
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 14
const SETTINGS_MENU_ANCHOR_PATH := "Margin/VBox/TopRow/SettingsMenuAnchor"

const ROUTE_BUTTON_NODE_NAMES: PackedStringArray = [
	"CombatNodeButton",
	"RewardNodeButton",
	"RestNodeButton",
	"MerchantNodeButton",
	"BlacksmithNodeButton",
	"BossNodeButton",
]

const ROUTE_MARKER_NODE_NAMES: PackedStringArray = [
	"CombatNodeMarker",
	"RewardNodeMarker",
	"RestNodeMarker",
	"MerchantNodeMarker",
	"BlacksmithNodeMarker",
	"BossNodeMarker",
]

const ROUTE_SLOT_TOP_LEFT := Vector2(0.38, 0.40)
const ROUTE_SLOT_TOP_RIGHT := Vector2(0.62, 0.40)
const ROUTE_SLOT_BOTTOM_LEFT := Vector2(0.40, 0.68)
const ROUTE_SLOT_BOTTOM_RIGHT := Vector2(0.60, 0.68)
const ROUTE_SLOT_LOWER_MID := Vector2(0.50, 0.80)
const ROUTE_SLOT_FORWARD := Vector2(0.50, 0.24)
const ROUTE_MARKER_SIZE := Vector2(164, 164)
const ROUTE_HITBOX_SIZE := Vector2(180, 180)
const CURRENT_MARKER_SIZE := Vector2(36, 36)
const BOARD_FOCUS_ANCHOR_FACTOR := Vector2(0.5, 0.55)
const BOARD_MAX_OFFSET_FACTOR := Vector2(0.16, 0.18)
const WALKER_ROOT_SIZE := Vector2(122, 150)
const WALKER_SHADOW_SIZE := Vector2(40, 10)
const WALKER_SPRITE_SIZE := Vector2(100, 120)
const NODE_PLATE_SIZE := Vector2(132, 132)
const NODE_ICON_SIZE := Vector2(108, 108)
const KEY_MARKER_SIZE := Vector2(36, 36)
const KEY_ICON_SIZE := Vector2(18, 18)
const STATE_PIP_SIZE := Vector2(14, 14)

var _status_lines: PackedStringArray = []
var _presenter: RefCounted
var _inventory_presenter: RefCounted
var _board_composer: RefCounted
var _route_selection_in_flight: bool = false
var _route_models_cache: Array[Dictionary] = []
var _board_composition_cache: Dictionary = {}
var _texture_cache: Dictionary = {}
var _current_marker: TextureRect
var _board_canvas: Control
var _road_base_lines: Array[Line2D] = []
var _road_highlight_lines: Array[Line2D] = []
var _walker_root: Control
var _walker_shadow: PanelContainer
var _walker_sprite: TextureRect
var _walker_cycle_token: int = 0
var _active_route_index: int = -1
var _hovered_route_index: int = -1
var _safe_menu: SafeMenuOverlay
var _route_layout_offset: Vector2 = Vector2.ZERO
var _route_move_start_center: Vector2 = Vector2.ZERO
var _route_move_target_center: Vector2 = Vector2.ZERO
var _route_move_start_offset: Vector2 = Vector2.ZERO
var _route_move_target_offset: Vector2 = Vector2.ZERO
var _inventory_tooltip_panel: PanelContainer
var _inventory_tooltip_label: Label
var _hovered_inventory_card: Control
var _hovered_inventory_accent: Color = TempScreenThemeScript.PANEL_BORDER_COLOR
var _pressed_inventory_card: PanelContainer
var _pressed_inventory_slot_id: int = -1
var _pressed_inventory_slot_index: int = -1
var _pressed_inventory_family: String = ""
var _pressed_inventory_position: Vector2 = Vector2.ZERO
var _inventory_drag_active: bool = false
var _event_overlay: Control
var _event_overlay_tween: Tween
var _support_overlay: Control
var _support_overlay_tween: Tween
var _reward_overlay: Control
var _reward_overlay_tween: Tween
var _level_up_overlay: Control
var _level_up_overlay_tween: Tween
var _is_refreshing_ui: bool = false
var _refresh_ui_pending: bool = false


func _ready() -> void:
	_presenter = MapExplorePresenterScript.new()
	_inventory_presenter = InventoryPresenterScript.new()
	_board_composer = MapBoardComposerV2Script.new()
	_connect_route_buttons()
	_apply_static_map_textures()
	_configure_audio_players()
	_ensure_runtime_board_nodes()
	_ensure_inventory_hint_label()
	_apply_temp_theme()
	_ensure_inventory_tooltip_shell()
	_style_route_buttons_for_overlay_mode()
	_apply_text_density_pass()
	_setup_safe_menu()
	_connect_viewport_layout_updates()
	_apply_portrait_safe_layout()
	SceneAudioPlayersScript.start_looping(self, "MapMusicPlayer")

	var route_grid: Control = get_node_or_null("Margin/VBox/RouteGrid") as Control
	if route_grid != null:
		var resized_handler := Callable(self, "_on_route_grid_resized")
		if not route_grid.is_connected("resized", resized_handler):
			route_grid.connect("resized", resized_handler)

	var bootstrap = _get_app_bootstrap()
	if bootstrap != null:
		bootstrap.ensure_run_state_initialized()

	call_deferred("_sync_overlays_with_flow_state")
	call_deferred("_refresh_ui")


func _exit_tree() -> void:
	_stop_walker_walk_cycle()
	_disconnect_viewport_layout_updates()
	_stop_inventory_card_interaction()
	_hide_inventory_tooltip(true)
	close_event_overlay(true)
	close_support_overlay(true)
	close_reward_overlay(true)
	close_level_up_overlay(true)
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


func _input(event: InputEvent) -> void:
	if _pressed_inventory_card == null:
		return
	if event is InputEventMouseMotion:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		if not _inventory_drag_active and motion_event.position.distance_to(_pressed_inventory_position) >= INVENTORY_DRAG_THRESHOLD:
			_inventory_drag_active = true
			_hide_inventory_tooltip(true)
			InventoryCardFactoryScript.set_card_dragging_state(_pressed_inventory_card, true)
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or mouse_event.pressed:
			return
		if _inventory_drag_active:
			_complete_inventory_card_drag()
		else:
			_handle_inventory_card_click(_pressed_inventory_slot_id, _pressed_inventory_family)
		_stop_inventory_card_interaction()


func _on_route_button_pressed(button_node_name: String) -> void:
	if _route_selection_in_flight:
		return
	var button: Button = get_node_or_null("Margin/VBox/RouteGrid/%s" % button_node_name) as Button
	if button == null:
		return
	var target_node_id: int = int(button.get_meta("target_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	if target_node_id < 0:
		return
	_route_selection_in_flight = true
	SceneAudioPlayersScript.play(self, "NodeSelectSfxPlayer")
	await _animate_route_selection(button_node_name, target_node_id)
	_route_selection_in_flight = false


func _on_save_run_pressed() -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return
	var save_result: Dictionary = bootstrap.save_game()
	if bool(save_result.get("ok", false)):
		_append_status_line("Run saved.")
		if _safe_menu != null:
			_safe_menu.set_status_text(RunMenuSceneHelperScript.build_save_status_text(save_result))
	else:
		var save_status_text: String = RunMenuSceneHelperScript.build_save_status_text(save_result)
		_append_status_line(save_status_text)
		if _safe_menu != null:
			_safe_menu.set_status_text(save_status_text)
	_refresh_ui()


func _on_load_run_pressed() -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return
	var load_result: Dictionary = bootstrap.load_game()
	if bool(load_result.get("ok", false)):
		return
	var load_failure_text: String = RunMenuSceneHelperScript.build_load_failure_status_text(load_result)
	_append_status_line(load_failure_text)
	if _safe_menu != null:
		_safe_menu.set_status_text(load_failure_text)
	_refresh_ui()


func _move_to_node(node_reference: Variant) -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		_append_status_line("AppBootstrap not available.")
		_refresh_ui()
		return

	var result: Dictionary = bootstrap.choose_move_to_node(node_reference)
	if not bool(result.get("ok", false)):
		_append_status_line("Move failed: %s" % String(result.get("error", "unknown")))
		_refresh_ui()
		return

	var node_type: String = String(result.get("node_type", "node"))
	var node_state: String = String(result.get("node_state", ""))
	var target_state: int = int(result.get("target_state", FlowState.Type.MAP_EXPLORE))
	if target_state == FlowState.Type.NODE_RESOLVE:
		_append_status_line("Entered %s node. Hunger: %d" % [node_type, int(result.get("hunger", 0))])
	elif target_state == FlowState.Type.COMBAT:
		_append_status_line("Entered %s combat. Hunger: %d" % [node_type, int(result.get("hunger", 0))])
	else:
		_append_status_line("Traversed to %s (%s). Hunger: %d" % [node_type, node_state, int(result.get("hunger", 0))])
	_refresh_ui()


func _refresh_ui() -> void:
	if _is_refreshing_ui:
		_refresh_ui_pending = true
		call_deferred("_consume_pending_refresh_ui")
		return
	_is_refreshing_ui = true

	var run_state: RunState = _get_run_state()
	if run_state == null:
		_is_refreshing_ui = false
		return
	_route_models_cache = _presenter.build_route_view_models(run_state, ROUTE_BUTTON_NODE_NAMES.size())
	_board_composition_cache = _build_board_composition(run_state)
	if not _route_selection_in_flight:
		_route_layout_offset = Vector2(_board_composition_cache.get("focus_offset", Vector2.ZERO))

	_refresh_inventory_cards(run_state)

	var title_label: Label = get_node_or_null("Margin/VBox/TopRow/HeaderCard/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.text = _presenter.build_title_text(run_state)

	var progress_label: Label = get_node_or_null("Margin/VBox/TopRow/HeaderCard/HeaderStack/ProgressLabel") as Label
	if progress_label != null:
		progress_label.text = _presenter.build_progress_text(run_state)
	var hp_status_label: Label = get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HpRow/HpStatusLabel") as Label
	if hp_status_label != null:
		hp_status_label.text = _presenter.build_hp_status_text(run_state)
	_apply_texture_rect_asset(
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HpRow/HpStatusIcon",
		_presenter.build_hp_icon_texture_path()
	)
	var hunger_status_label: Label = get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HungerRow/HungerStatusLabel") as Label
	if hunger_status_label != null:
		hunger_status_label.text = _presenter.build_hunger_status_text(run_state)
	_apply_texture_rect_asset(
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HungerRow/HungerStatusIcon",
		_presenter.build_hunger_icon_texture_path()
	)
	var durability_status_label: Label = get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/DurabilityRow/DurabilityStatusLabel") as Label
	if durability_status_label != null:
		durability_status_label.text = _presenter.build_durability_status_text(run_state)
	_apply_texture_rect_asset(
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/DurabilityRow/DurabilityStatusIcon",
		_presenter.build_durability_icon_texture_path()
	)

	# Update Gold label (now in HpRow)
	var gold_value_label: Label = get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HpRow/GoldStatusValueLabel") as Label
	if gold_value_label != null:
		gold_value_label.text = _presenter.build_gold_status_text(run_state)
	_apply_texture_rect_asset(
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HpRow/GoldStatusIcon",
		_presenter.build_gold_icon_texture_path()
	)

	# Update XP bar
	var xp_progress_bar: ProgressBar = get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/XpRow/XpProgressBar") as ProgressBar
	var xp_label: Label = get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/XpRow/XpLabel") as Label
	if run_state != null:
		var level_up_threshold: int = _presenter.get_level_up_threshold(run_state)
		if xp_progress_bar != null:
			xp_progress_bar.max_value = float(level_up_threshold)
			xp_progress_bar.value = float(run_state.experience)
		if xp_label != null:
			xp_label.text = "XP %d/%d" % [run_state.experience, level_up_threshold]

	var current_anchor_label: Label = get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorLabel") as Label
	if current_anchor_label != null:
		current_anchor_label.text = _presenter.build_current_anchor_text(run_state)

	var current_anchor_detail_label: Label = get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorDetailLabel") as Label
	if current_anchor_detail_label != null:
		current_anchor_detail_label.text = _presenter.build_current_anchor_detail_text(run_state)

	for index in range(ROUTE_BUTTON_NODE_NAMES.size()):
		var route_button: Button = get_node_or_null("Margin/VBox/RouteGrid/%s" % ROUTE_BUTTON_NODE_NAMES[index]) as Button
		if route_button == null:
			continue
		var model: Dictionary = _route_models_cache[index]
		route_button.visible = bool(model.get("visible", false))
		route_button.disabled = bool(model.get("disabled", true))
		var route_label: String = String(model.get("text", ""))
		route_button.text = route_label
		route_button.tooltip_text = route_label
		route_button.set_meta("target_node_id", int(model.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)))
		_update_route_marker_view(index, model)

	var status_label: Label = get_node_or_null("Margin/VBox/BottomRow/StatusCard/StatusLabel") as Label
	if status_label != null:
		status_label.text = _presenter.build_status_log_text(_status_lines, run_state)
		status_label.visible = not status_label.text.is_empty()
	var status_card: Control = get_node_or_null("Margin/VBox/BottomRow/StatusCard") as Control
	if status_card != null and status_label != null:
		status_card.visible = status_label.visible

	if _safe_menu != null:
		var bootstrap = _get_app_bootstrap()
		RunMenuSceneHelperScript.sync_load_available(_safe_menu, bootstrap)

	if not _route_selection_in_flight:
		_apply_portrait_safe_layout()
	_layout_route_grid()
	_update_current_marker_view(run_state)
	_refresh_route_roads()
	if not _route_selection_in_flight:
		_sync_walker_to_current_marker()

	_is_refreshing_ui = false
	if _refresh_ui_pending:
		call_deferred("_consume_pending_refresh_ui")


func _remove_hp_from_run_status_text(raw_status_text: String) -> String:
	var status_parts: PackedStringArray = raw_status_text.split(" | ", false)
	if status_parts.is_empty():
		return ""
	var filtered_status_parts: PackedStringArray = []
	for status_part in status_parts:
		if status_part.begins_with("HP ") or status_part.begins_with("Hunger "):
			continue
		filtered_status_parts.append(status_part)
	if filtered_status_parts.is_empty():
		return ""
	return " | ".join(filtered_status_parts)


func _append_status_line(line: String) -> void:
	_status_lines.append(line)
	if _status_lines.size() > 6:
		_status_lines.remove_at(0)


func _refresh_inventory_cards(run_state: RunState) -> void:
	var container: Container = get_node_or_null("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow") as Container
	if container == null or _inventory_presenter == null:
		return

	_hide_inventory_tooltip(true)
	var inventory_title_label: Label = get_node_or_null("Margin/VBox/InventorySection/InventoryTitleLabel") as Label
	if inventory_title_label != null:
		inventory_title_label.text = _inventory_presenter.build_inventory_title_text(run_state.inventory_state if run_state != null else null)
	var inventory_hint_label: Label = get_node_or_null("Margin/VBox/InventorySection/InventoryHintLabel") as Label
	if inventory_hint_label != null:
		inventory_hint_label.text = _inventory_presenter.build_run_inventory_hint_text()
	var card_models: Array[Dictionary] = _inventory_presenter.build_run_inventory_cards(run_state)
	for index in range(card_models.size()):
		var card_model: Dictionary = card_models[index]
		var is_clickable: bool = _inventory_card_is_clickable(card_model)
		var is_draggable: bool = _inventory_card_is_draggable(card_model)
		card_model["is_clickable"] = is_clickable
		card_model["is_draggable"] = is_draggable
		card_models[index] = _inventory_presenter.decorate_card_interaction_state(
			card_model,
			false,
			is_clickable,
			false,
			is_draggable
		)
	var cards: Array[PanelContainer] = InventoryCardFactoryScript.rebuild_cards(container, card_models)
	for index in range(min(cards.size(), card_models.size())):
		_connect_inventory_card_interactions(cards[index], card_models[index])


func _connect_inventory_card_interactions(card: PanelContainer, card_model: Dictionary) -> void:
	if card == null:
		return

	var accent: Color = Color(card_model.get("accent_color", TempScreenThemeScript.PANEL_BORDER_COLOR))
	var entered_handler := Callable(self, "_on_inventory_card_mouse_entered").bind(card, accent)
	var exited_handler := Callable(self, "_on_inventory_card_mouse_exited").bind(card)
	var input_handler := Callable(self, "_on_inventory_card_gui_input").bind(card)
	
	if not card.is_connected("mouse_entered", entered_handler):
		card.connect("mouse_entered", entered_handler)
	if not card.is_connected("mouse_exited", exited_handler):
		card.connect("mouse_exited", exited_handler)
	if not card.is_connected("gui_input", input_handler):
		card.connect("gui_input", input_handler)
		# Verify card can receive input
		if card.mouse_filter != Control.MOUSE_FILTER_STOP:
			card.mouse_filter = Control.MOUSE_FILTER_STOP


func _inventory_card_is_clickable(card_model: Dictionary) -> bool:
	var card_family: String = String(card_model.get("card_family", ""))
	return card_family in ["weapon", "armor", "belt", "consumable"]


func _inventory_card_is_draggable(card_model: Dictionary) -> bool:
	return String(card_model.get("card_family", "")) != "empty"


func _on_inventory_card_gui_input(event: InputEvent, card: PanelContainer) -> void:
	if event == null or card == null:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		_pressed_inventory_card = card
		_pressed_inventory_slot_id = int(card.get_meta("inventory_slot_id", -1))
		_pressed_inventory_slot_index = int(card.get_meta("inventory_slot_index", -1))
		_pressed_inventory_family = String(card.get_meta("card_family", ""))
		_pressed_inventory_position = mouse_event.position + card.get_global_rect().position
		_inventory_drag_active = false
	else:
		# Mouse button released
		if _inventory_drag_active:
			_complete_inventory_card_drag()
		else:
			_handle_inventory_card_click(_pressed_inventory_slot_id, _pressed_inventory_family)
		_stop_inventory_card_interaction()


func _handle_inventory_card_click(slot_id: int, card_family: String) -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return

	match card_family:
		"weapon", "armor", "belt":
			var toggle_result: Dictionary = bootstrap.toggle_inventory_equipment(slot_id)
			if not bool(toggle_result.get("ok", false)):
				_append_status_line(_build_inventory_failure_text(toggle_result))
			else:
				var definition_name: String = _build_inventory_result_name(toggle_result)
				var action_label: String = "Equipped" if bool(toggle_result.get("equipped", false)) else "Unequipped"
				_append_status_line("%s %s." % [action_label, definition_name])
		"consumable":
			var use_result: Dictionary = bootstrap.use_inventory_consumable(slot_id)
			if not bool(use_result.get("ok", false)):
				_append_status_line(_build_inventory_failure_text(use_result))
			else:
				_append_status_line(_build_consumable_result_text(use_result))
		_:
			return

	_refresh_ui()


func _complete_inventory_card_drag() -> void:
	if _pressed_inventory_card == null:
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
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return
	var move_result: Dictionary = bootstrap.move_inventory_slot(_pressed_inventory_slot_id, target_index)
	if not bool(move_result.get("ok", false)):
		_append_status_line(_build_inventory_failure_text(move_result))
		return
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


func _build_inventory_result_name(result: Dictionary) -> String:
	return String(result.get("display_name", result.get("definition_id", "item")))


func _build_consumable_result_text(result: Dictionary) -> String:
	var item_name: String = _build_inventory_result_name(result)
	var healed_amount: int = int(result.get("healed_amount", 0))
	var hunger_restored_amount: int = int(result.get("hunger_restored_amount", 0))
	if healed_amount > 0 and hunger_restored_amount > 0:
		return "Used %s. +%d HP, +%d Hunger." % [item_name, healed_amount, hunger_restored_amount]
	if hunger_restored_amount > 0:
		return "Used %s. +%d Hunger." % [item_name, hunger_restored_amount]
	return "Used %s. +%d HP." % [item_name, healed_amount]


func _build_inventory_failure_text(result: Dictionary) -> String:
	match String(result.get("error", "")):
		"no_effect":
			return "No need to use that item right now."
		"belt_capacity_required":
			return "Free 2 inventory space before unequipping that belt."
		_:
			return "Inventory action failed."


func _get_app_bootstrap():
	return get_node_or_null("/root/AppBootstrap")


func _get_run_state() -> RunState:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.get_run_state()


func _connect_route_buttons() -> void:
	for button_node_name in ROUTE_BUTTON_NODE_NAMES:
		var route_button: Button = get_node_or_null("Margin/VBox/RouteGrid/%s" % button_node_name) as Button
		if route_button == null:
			continue
		var handler: Callable = Callable(self, "_on_route_button_pressed").bind(button_node_name)
		if not route_button.is_connected("pressed", handler):
			route_button.connect("pressed", handler)
		var entered_handler: Callable = Callable(self, "_on_route_button_mouse_entered").bind(button_node_name)
		var exited_handler: Callable = Callable(self, "_on_route_button_mouse_exited").bind(button_node_name)
		var focus_entered_handler: Callable = Callable(self, "_on_route_button_focus_entered").bind(button_node_name)
		var focus_exited_handler: Callable = Callable(self, "_on_route_button_focus_exited").bind(button_node_name)
		if not route_button.is_connected("mouse_entered", entered_handler):
			route_button.connect("mouse_entered", entered_handler)
		if not route_button.is_connected("mouse_exited", exited_handler):
			route_button.connect("mouse_exited", exited_handler)
		if not route_button.is_connected("focus_entered", focus_entered_handler):
			route_button.connect("focus_entered", focus_entered_handler)
		if not route_button.is_connected("focus_exited", focus_exited_handler):
			route_button.connect("focus_exited", focus_exited_handler)


func _on_route_button_mouse_entered(button_node_name: String) -> void:
	var route_index: int = ROUTE_BUTTON_NODE_NAMES.find(button_node_name)
	if route_index == _hovered_route_index:
		return
	_hovered_route_index = route_index
	_refresh_route_visual_state()


func _on_route_button_mouse_exited(button_node_name: String) -> void:
	if ROUTE_BUTTON_NODE_NAMES.find(button_node_name) != _hovered_route_index:
		return
	_hovered_route_index = -1
	_refresh_route_visual_state()


func _on_route_button_focus_entered(button_node_name: String) -> void:
	var route_index: int = ROUTE_BUTTON_NODE_NAMES.find(button_node_name)
	if route_index == _hovered_route_index:
		return
	_hovered_route_index = route_index
	_refresh_route_visual_state()


func _on_route_button_focus_exited(button_node_name: String) -> void:
	if ROUTE_BUTTON_NODE_NAMES.find(button_node_name) != _hovered_route_index:
		return
	_hovered_route_index = -1
	_refresh_route_visual_state()


func _refresh_route_visual_state() -> void:
	if _route_models_cache.is_empty():
		return
	for index in range(ROUTE_BUTTON_NODE_NAMES.size()):
		if index >= _route_models_cache.size():
			break
		_update_route_marker_view(index, _route_models_cache[index])
	_refresh_route_roads()


func _apply_static_map_textures() -> void:
	_set_texture_rect_texture("Margin/VBox/RouteGrid/BoardBackdrop", MAP_BOARD_BACKDROP_TEXTURE)
	_set_texture_rect_texture("Margin/VBox/RouteGrid/KeyMarkerCard", null)


func _configure_audio_players() -> void:
	SceneAudioPlayersScript.assign_stream_from_path(self, "NodeSelectSfxPlayer", NODE_SELECT_SFX_PATH)
	SceneAudioPlayersScript.assign_music_stream_from_path(self, "MapMusicPlayer", MAP_MUSIC_LOOP_PATH, true)


func _animate_route_selection(button_node_name: String, target_node_id: int) -> void:
	var route_index: int = ROUTE_BUTTON_NODE_NAMES.find(button_node_name)
	if route_index < 0:
		_move_to_node(target_node_id)
		return

	_active_route_index = route_index
	_refresh_route_roads()
	_sync_walker_to_current_marker()

	var start_center: Vector2 = _get_current_marker_center()
	var target_center: Vector2 = _get_route_marker_center(route_index)
	if start_center == Vector2.ZERO or target_center == Vector2.ZERO:
		_active_route_index = -1
		_refresh_route_roads()
		_move_to_node(target_node_id)
		return

	_set_walker_facing(target_center.x >= start_center.x)
	_start_walker_walk_cycle()
	_walker_root.visible = true

	var target_world_position: Vector2 = _get_node_world_position(target_node_id)
	var target_offset: Vector2 = _desired_focus_offset_for_world_position(target_world_position)
	await _animate_route_move_camera_follow(start_center, target_center, target_offset)

	_stop_walker_walk_cycle()
	_set_walker_texture(MAP_WALKER_IDLE_TEXTURE)
	if is_inside_tree():
		await get_tree().create_timer(0.12).timeout

	_active_route_index = -1
	_refresh_route_roads()
	_move_to_node(target_node_id)

	if is_inside_tree() and get_tree().current_scene == self:
		_sync_walker_to_current_marker()


func _ensure_runtime_board_nodes() -> void:
	var route_grid: Control = get_node_or_null("Margin/VBox/RouteGrid") as Control
	if route_grid == null:
		return
	var setup_result: Dictionary = MapExploreSceneUiScript.ensure_runtime_board_nodes(
		route_grid,
		ROUTE_MARKER_NODE_NAMES,
		_current_marker,
		_road_base_lines,
		_road_highlight_lines,
		_walker_root,
		_walker_shadow,
		_walker_sprite,
		WALKER_ROOT_SIZE,
		WALKER_SHADOW_SIZE,
		WALKER_SPRITE_SIZE,
		_board_canvas
	)
	_current_marker = setup_result.get("current_marker", _current_marker) as TextureRect
	_board_canvas = setup_result.get("board_canvas", _board_canvas) as Control
	_walker_root = setup_result.get("walker_root", _walker_root) as Control
	_walker_shadow = setup_result.get("walker_shadow", _walker_shadow) as PanelContainer
	_walker_sprite = setup_result.get("walker_sprite", _walker_sprite) as TextureRect


func _update_route_marker_view(index: int, model: Dictionary) -> void:
	if index < 0 or index >= ROUTE_MARKER_NODE_NAMES.size():
		return

	var marker_rect: TextureRect = get_node_or_null("Margin/VBox/RouteGrid/%s" % ROUTE_MARKER_NODE_NAMES[index]) as TextureRect
	if marker_rect == null:
		return

	var is_visible: bool = bool(model.get("visible", false))
	marker_rect.visible = is_visible
	if not is_visible:
		return

	marker_rect.texture = null
	_apply_marker_visual_state(
		marker_rect,
		String(model.get("icon_texture_path", "")),
		String(model.get("node_family", "")),
		String(model.get("family_label", "")),
		String(model.get("state_chip_text", "")),
		String(model.get("state_semantic", "")),
		bool(model.get("disabled", true)),
		_active_route_index == index or _hovered_route_index == index
	)


func _update_current_marker_view(run_state: RunState) -> void:
	if _current_marker == null or run_state == null:
		return

	var current_family: String = String(run_state.map_runtime_state.get_current_node_family())
	_current_marker.visible = true
	_current_marker.texture = null
	_apply_marker_visual_state(
		_current_marker,
		"",
		current_family,
		"",
		"",
		"current",
		false,
		false
	)


func _apply_marker_visual_state(marker_rect: TextureRect, icon_texture_path: String, node_family: String, family_label: String, chip_text: String, state_semantic: String, is_disabled: bool, is_selected: bool) -> void:
	if marker_rect == null:
		return

	var is_preview_node: bool = is_disabled and state_semantic == "open"
	marker_rect.modulate = MapBoardStyleScript.marker_modulate_for_semantic(state_semantic, is_disabled)

	var node_plate: PanelContainer = marker_rect.get_node_or_null("NodePlate") as PanelContainer
	if node_plate != null:
		node_plate.visible = state_semantic != "current"
		var plate_size: Vector2 = NODE_PLATE_SIZE
		node_plate.size = plate_size
		node_plate.position = (marker_rect.size - plate_size) * 0.5
		MapBoardStyleScript.apply_node_plate_style(node_plate, node_family, state_semantic, is_disabled, is_preview_node)

	var icon_rect: TextureRect = marker_rect.get_node_or_null("RouteIcon") as TextureRect
	if icon_rect != null:
		icon_rect.position = (marker_rect.size - NODE_ICON_SIZE) * 0.5
		icon_rect.size = NODE_ICON_SIZE
		icon_rect.texture = _load_texture_or_null(icon_texture_path)
		icon_rect.visible = icon_rect.texture != null and state_semantic != "current"
		icon_rect.modulate = MapBoardStyleScript.icon_modulate_for_semantic(node_family, state_semantic, is_disabled, is_preview_node)

	var selection_ring: PanelContainer = marker_rect.get_node_or_null("SelectionRing") as PanelContainer
	if selection_ring != null:
		selection_ring.position = ((marker_rect.size - NODE_PLATE_SIZE) * 0.5) - Vector2(6, 6)
		selection_ring.size = NODE_PLATE_SIZE + Vector2(12, 12)
		selection_ring.visible = not is_disabled and is_selected
		MapBoardStyleScript.apply_selection_ring(selection_ring, state_semantic, is_selected)

	var chip_panel: PanelContainer = marker_rect.get_node_or_null("StateChip") as PanelContainer
	var chip_label: Label = null
	if chip_panel != null:
		chip_label = chip_panel.get_node_or_null("StateChipLabel") as Label
	if chip_panel != null and chip_label != null:
		var should_show_pill: bool = is_selected and not family_label.is_empty() and state_semantic != "current"
		var should_show_state_pip: bool = not should_show_pill and not chip_text.is_empty() and (state_semantic == "locked" or state_semantic == "resolved")
		chip_panel.visible = should_show_pill or should_show_state_pip
		if should_show_pill:
			var pill_width: float = max(72.0, float(family_label.length() * 9 + 26))
			chip_panel.size = Vector2(pill_width, 24.0)
			chip_panel.position = Vector2((marker_rect.size.x - pill_width) * 0.5, -14.0)
			chip_label.position = Vector2.ZERO
			chip_label.size = chip_panel.size
			chip_label.text = family_label
			chip_label.visible = true
		else:
			chip_panel.size = STATE_PIP_SIZE
			if state_semantic == "resolved":
				chip_panel.position = Vector2(marker_rect.size.x - STATE_PIP_SIZE.x - 8.0, marker_rect.size.y - STATE_PIP_SIZE.y - 8.0)
			else:
				chip_panel.position = Vector2(marker_rect.size.x - STATE_PIP_SIZE.x - 8.0, 8.0)
			chip_label.position = Vector2.ZERO
			chip_label.size = chip_panel.size
			chip_label.text = ""
			chip_label.visible = false
		MapBoardStyleScript.apply_chip_style(chip_panel, chip_label, state_semantic)

	var fallback_label: Label = marker_rect.get_node_or_null("FallbackLabel") as Label
	if fallback_label != null:
		fallback_label.visible = false

	if state_semantic == "current":
		marker_rect.modulate = Color(1, 1, 1, 0.0)


func _refresh_route_roads() -> void:
	if _current_marker == null or _route_models_cache.is_empty():
		return
	for base_line in _road_base_lines:
		base_line.visible = false
	for highlight_line in _road_highlight_lines:
		highlight_line.visible = false
	if _board_canvas != null:
		_board_canvas.call("set_composition", _board_composition_cache)
		_board_canvas.call("set_board_offset", _route_layout_offset)
		_board_canvas.call("set_interaction_state", _active_target_node_id(), _hovered_target_node_id())


func _refresh_route_board_offset() -> void:
	if _board_canvas == null:
		return
	_board_canvas.call("set_board_offset", _route_layout_offset)


func _layout_route_grid() -> void:
	var route_grid: Control = get_node_or_null("Margin/VBox/RouteGrid") as Control
	if route_grid == null:
		return

	var board_backdrop: TextureRect = route_grid.get_node_or_null("BoardBackdrop") as TextureRect
	if board_backdrop != null:
		board_backdrop.offset_left = 4.0
		board_backdrop.offset_top = 4.0
		board_backdrop.offset_right = -4.0
		board_backdrop.offset_bottom = -4.0
		board_backdrop.modulate = Color(1, 1, 1, 1.0)

	var visible_route_indices: Array[int] = []
	for index in range(ROUTE_MARKER_NODE_NAMES.size()):
		if index < _route_models_cache.size() and bool(_route_models_cache[index].get("visible", false)):
			visible_route_indices.append(index)

	var slot_factors: Array[Vector2] = _route_slot_factors_for_visible_count(visible_route_indices.size())

	for index in range(ROUTE_MARKER_NODE_NAMES.size()):
		var marker_rect: TextureRect = route_grid.get_node_or_null(ROUTE_MARKER_NODE_NAMES[index]) as TextureRect
		var route_button: Button = route_grid.get_node_or_null(ROUTE_BUTTON_NODE_NAMES[index]) as Button
		if marker_rect == null or route_button == null:
			continue
		var visible_slot_index: int = visible_route_indices.find(index)
		if visible_slot_index < 0:
			marker_rect.visible = false
			route_button.visible = false
			continue
		var marker_model: Dictionary = _route_models_cache[index]
		var marker_position: Vector2 = _marker_position_for_route_model(marker_model, visible_slot_index, slot_factors, route_grid.size)
		marker_rect.size = ROUTE_MARKER_SIZE
		marker_rect.position = marker_position
		route_button.size = ROUTE_HITBOX_SIZE
		route_button.position = marker_position - ((ROUTE_HITBOX_SIZE - ROUTE_MARKER_SIZE) * 0.5)

	if _current_marker != null:
		_current_marker.size = CURRENT_MARKER_SIZE
		var current_node_id: int = int(_board_composition_cache.get("current_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var current_world_position: Vector2 = _get_node_world_position(current_node_id)
		if current_world_position == Vector2.ZERO:
			current_world_position = route_grid.size * BOARD_FOCUS_ANCHOR_FACTOR
		_current_marker.position = current_world_position + _route_layout_offset - (CURRENT_MARKER_SIZE * 0.5)

	_layout_auxiliary_board_cards(route_grid)


func _route_slot_factors_for_visible_count(visible_count: int) -> Array[Vector2]:
	match visible_count:
		0:
			return []
		1:
			return [ROUTE_SLOT_FORWARD]
		2:
			return [ROUTE_SLOT_TOP_LEFT, ROUTE_SLOT_TOP_RIGHT]
		3:
			return [ROUTE_SLOT_FORWARD, ROUTE_SLOT_TOP_LEFT, ROUTE_SLOT_TOP_RIGHT]
		4:
			return [ROUTE_SLOT_FORWARD, ROUTE_SLOT_TOP_LEFT, ROUTE_SLOT_TOP_RIGHT, ROUTE_SLOT_LOWER_MID]
		5:
			return [ROUTE_SLOT_FORWARD, ROUTE_SLOT_TOP_LEFT, ROUTE_SLOT_TOP_RIGHT, ROUTE_SLOT_BOTTOM_LEFT, ROUTE_SLOT_BOTTOM_RIGHT]
		_:
			return [ROUTE_SLOT_FORWARD, ROUTE_SLOT_TOP_LEFT, ROUTE_SLOT_TOP_RIGHT, ROUTE_SLOT_BOTTOM_LEFT, ROUTE_SLOT_BOTTOM_RIGHT, ROUTE_SLOT_LOWER_MID]


func _should_hold_map_after_move(run_state: RunState) -> bool:
	if run_state == null:
		return false
	return String(run_state.map_runtime_state.get_current_node_family()) == "start"


func _clamp_route_layout_offset(desired_offset: Vector2) -> Vector2:
	var route_grid: Control = get_node_or_null("Margin/VBox/RouteGrid") as Control
	if route_grid == null:
		return desired_offset
	var max_offset_x: float = route_grid.size.x * BOARD_MAX_OFFSET_FACTOR.x
	var max_offset_y: float = route_grid.size.y * BOARD_MAX_OFFSET_FACTOR.y
	return Vector2(
		clamp(desired_offset.x, -max_offset_x, max_offset_x),
		clamp(desired_offset.y, -max_offset_y, max_offset_y)
	)


func _build_board_composition(run_state: RunState) -> Dictionary:
	var route_grid: Control = get_node_or_null("Margin/VBox/RouteGrid") as Control
	if route_grid == null or _board_composer == null:
		return {}
	return _board_composer.call(
		"compose",
		run_state,
		route_grid.size,
		BOARD_FOCUS_ANCHOR_FACTOR,
		Vector2(route_grid.size.x * BOARD_MAX_OFFSET_FACTOR.x, route_grid.size.y * BOARD_MAX_OFFSET_FACTOR.y)
	)


func _marker_position_for_route_model(
	model: Dictionary,
	visible_slot_index: int,
	slot_factors: Array[Vector2],
	board_size: Vector2
) -> Vector2:
	var node_id: int = int(model.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var world_position: Vector2 = _get_node_world_position(node_id)
	if world_position != Vector2.ZERO:
		return world_position + _route_layout_offset - (ROUTE_MARKER_SIZE * 0.5)
	if visible_slot_index >= 0 and visible_slot_index < slot_factors.size():
		return board_size * slot_factors[visible_slot_index] - (ROUTE_MARKER_SIZE * 0.5) + _route_layout_offset
	return board_size * BOARD_FOCUS_ANCHOR_FACTOR - (ROUTE_MARKER_SIZE * 0.5)


func _get_node_world_position(node_id: int) -> Vector2:
	if node_id < 0 or _board_composition_cache.is_empty():
		return Vector2.ZERO
	var world_positions: Dictionary = _board_composition_cache.get("world_positions", {})
	return world_positions.get(node_id, Vector2.ZERO)


func _desired_focus_offset_for_world_position(world_position: Vector2) -> Vector2:
	var route_grid: Control = get_node_or_null("Margin/VBox/RouteGrid") as Control
	if route_grid == null or world_position == Vector2.ZERO:
		return _route_layout_offset
	return _clamp_route_layout_offset(route_grid.size * BOARD_FOCUS_ANCHOR_FACTOR - world_position)


func _active_target_node_id() -> int:
	if _active_route_index < 0 or _active_route_index >= _route_models_cache.size():
		return MapRuntimeStateScript.NO_PENDING_NODE_ID
	return int(_route_models_cache[_active_route_index].get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))


func _hovered_target_node_id() -> int:
	if _hovered_route_index < 0 or _hovered_route_index >= _route_models_cache.size():
		return MapRuntimeStateScript.NO_PENDING_NODE_ID
	return int(_route_models_cache[_hovered_route_index].get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))


func _layout_auxiliary_board_cards(route_grid: Control) -> void:
	var key_marker_card: TextureRect = route_grid.get_node_or_null("KeyMarkerCard") as TextureRect

	if key_marker_card != null:
		key_marker_card.visible = true
		key_marker_card.texture = null
		key_marker_card.size = KEY_MARKER_SIZE
		key_marker_card.position = Vector2(route_grid.size.x - key_marker_card.size.x - 12.0, 14.0)
		MapExploreSceneUiScript.ensure_key_marker_visual(key_marker_card)
		var key_icon: TextureRect = key_marker_card.get_node_or_null("KeyMarkerIcon") as TextureRect
		if key_icon != null:
			key_icon.texture = KEY_MARKER_ICON_TEXTURE
			key_icon.size = KEY_ICON_SIZE
			key_icon.position = Vector2((key_marker_card.size.x - key_icon.size.x) * 0.5, (key_marker_card.size.y - key_icon.size.y) * 0.5)
			key_icon.modulate = Color(1, 1, 1, 0.96)


func _sync_walker_to_current_marker() -> void:
	if _walker_root == null or _current_marker == null or not _current_marker.visible:
		return
	_set_walker_texture(MAP_WALKER_IDLE_TEXTURE)
	_set_walker_facing(true)
	_walker_root.visible = true
	_walker_root.position = _position_for_walker_center(_get_current_marker_center())


func _position_for_walker_center(center: Vector2) -> Vector2:
	return center - Vector2(WALKER_ROOT_SIZE.x * 0.5, WALKER_ROOT_SIZE.y * 0.88)


func _set_walker_facing(facing_right: bool) -> void:
	if _walker_sprite != null:
		_walker_sprite.scale = Vector2(1, 1) if facing_right else Vector2(-1, 1)


func _set_walker_texture(texture: Texture2D) -> void:
	if _walker_sprite != null:
		_walker_sprite.texture = texture


func _start_walker_walk_cycle() -> void:
	_walker_cycle_token += 1
	_run_walker_cycle(_walker_cycle_token)


func _run_walker_cycle(token: int) -> void:
	var frame_index: int = 0
	while token == _walker_cycle_token and is_inside_tree():
		_set_walker_texture(MAP_WALKER_WALK_A_TEXTURE if frame_index % 2 == 0 else MAP_WALKER_WALK_B_TEXTURE)
		frame_index += 1
		await get_tree().create_timer(0.1).timeout


func _stop_walker_walk_cycle() -> void:
	_walker_cycle_token += 1


func _animate_route_move_camera_follow(start_center: Vector2, target_center: Vector2, target_offset: Vector2) -> void:
	var move_duration: float = _clamp_route_move_duration(start_center.distance_to(target_center))
	_route_move_start_center = start_center
	_route_move_target_center = target_center
	_route_move_start_offset = _route_layout_offset
	_route_move_target_offset = target_offset

	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_method(Callable(self, "_update_route_move_progress"), 0.0, 1.0, move_duration)
	await tween.finished


func _update_route_move_progress(progress: float) -> void:
	var current_offset: Vector2 = _route_move_start_offset.lerp(_route_move_target_offset, progress)
	_route_layout_offset = current_offset
	_layout_route_grid()
	_refresh_route_board_offset()

	if _walker_root == null:
		return

	var path_center: Vector2 = _route_move_start_center.lerp(_route_move_target_center, progress)
	var offset_delta: Vector2 = current_offset - _route_move_start_offset
	_walker_root.position = _position_for_walker_center(path_center + offset_delta)


func _clamp_route_move_duration(distance: float) -> float:
	return clamp(distance / 480.0, 0.24, 0.5)


func _get_current_marker_center() -> Vector2:
	if _current_marker == null:
		return Vector2.ZERO
	return _current_marker.position + (_current_marker.size * 0.5)


func _get_route_marker_center(index: int) -> Vector2:
	if index < 0 or index >= ROUTE_MARKER_NODE_NAMES.size():
		return Vector2.ZERO
	var marker_rect: TextureRect = get_node_or_null("Margin/VBox/RouteGrid/%s" % ROUTE_MARKER_NODE_NAMES[index]) as TextureRect
	if marker_rect == null:
		return Vector2.ZERO
	return marker_rect.position + (marker_rect.size * 0.5)


func _set_texture_rect_texture(node_path: String, texture: Texture2D) -> void:
	var texture_rect: TextureRect = get_node_or_null(node_path) as TextureRect
	if texture_rect != null:
		texture_rect.texture = texture


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

	if _texture_cache.has(asset_path):
		return _texture_cache[asset_path] as Texture2D

	var resource: Resource = load(asset_path)
	if resource is Texture2D:
		var texture: Texture2D = resource as Texture2D
		_texture_cache[asset_path] = texture
		return texture
	return null


func _apply_temp_theme() -> void:
	MapExploreSceneUiScript.apply_temp_theme(self)


func _style_route_buttons_for_overlay_mode() -> void:
	var route_grid: Control = get_node_or_null("Margin/VBox/RouteGrid") as Control
	MapExploreSceneUiScript.style_route_buttons_for_overlay_mode(route_grid, ROUTE_BUTTON_NODE_NAMES)


func _apply_text_density_pass() -> void:
	MapExploreSceneUiScript.apply_text_density_pass(self)


func _on_route_grid_resized() -> void:
	if _route_selection_in_flight:
		return
	_refresh_ui_pending = true
	call_deferred("_consume_pending_refresh_ui")
	_position_overlay(_event_overlay)
	_position_overlay(_support_overlay)
	_position_overlay(_reward_overlay)
	_position_overlay(_level_up_overlay)


func _consume_pending_refresh_ui() -> void:
	if _is_refreshing_ui:
		call_deferred("_consume_pending_refresh_ui")
		return
	if not _refresh_ui_pending:
		return
	_refresh_ui_pending = false
	_refresh_ui()


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
	call_deferred("_refresh_safe_menu_anchor_layout")
	_refresh_hovered_inventory_tooltip()
	_position_overlay(_event_overlay)
	_position_overlay(_support_overlay)
	_position_overlay(_reward_overlay)
	_position_overlay(_level_up_overlay)


func _sync_overlays_with_flow_state() -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return

	var flow_manager = bootstrap.get_flow_manager()
	if flow_manager == null:
		return

	var current_state: int = flow_manager.get_current_state()

	# Handle event overlay
	if current_state == FlowStateScript.Type.EVENT:
		open_event_overlay()
	else:
		close_event_overlay(false)

	# Handle support interaction overlay
	if current_state == FlowStateScript.Type.SUPPORT_INTERACTION:
		open_support_overlay()
	else:
		close_support_overlay(false)

	# Handle reward overlay
	if current_state == FlowStateScript.Type.REWARD:
		open_reward_overlay()
	else:
		close_reward_overlay(false)

	# Handle level up overlay
	if current_state == FlowStateScript.Type.LEVEL_UP:
		open_level_up_overlay()
	else:
		close_level_up_overlay(false)


func open_event_overlay() -> void:
	if _event_overlay_tween != null and is_instance_valid(_event_overlay_tween):
		_event_overlay_tween.kill()
		_event_overlay_tween = null

	if _event_overlay != null and not is_instance_valid(_event_overlay):
		_event_overlay = null
	if _event_overlay != null and _event_overlay.is_queued_for_deletion():
		_event_overlay = null
	if _event_overlay == null:
		var overlay_instance: Node = EventSceneScript.instantiate()
		if overlay_instance == null:
			return
		var overlay_control: Control = overlay_instance as Control
		if overlay_control == null:
			push_error("Event overlay must inherit Control.")
			overlay_instance.queue_free()
			return

		overlay_control.name = "EventOverlay"
		overlay_control.top_level = true
		overlay_control.z_as_relative = false
		overlay_control.z_index = EVENT_OVERLAY_Z_INDEX
		overlay_control.visible = false
		overlay_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay_control.anchor_right = 1.0
		overlay_control.anchor_bottom = 1.0
		overlay_control.grow_horizontal = Control.GROW_DIRECTION_BOTH
		overlay_control.grow_vertical = Control.GROW_DIRECTION_BOTH
		add_child(overlay_control)
		_event_overlay = overlay_control

	if _event_overlay == null or not is_instance_valid(_event_overlay):
		return

	_event_overlay.visible = true
	_event_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_tune_event_overlay_visuals(_event_overlay)
	_event_overlay.modulate = Color(1, 1, 1, 0)
	_event_overlay.scale = Vector2(EVENT_OVERLAY_OPEN_SCALE, EVENT_OVERLAY_OPEN_SCALE)
	_position_event_overlay()

	var tween: Tween = create_tween()
	_event_overlay_tween = tween
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(EVENT_OVERLAY_TWEEN_TRANSITION)
	tween.tween_property(_event_overlay, "modulate", Color(1, 1, 1, 1), EVENT_OVERLAY_OPEN_DURATION)
	tween.parallel().tween_property(_event_overlay, "scale", Vector2.ONE, EVENT_OVERLAY_OPEN_DURATION)
	tween.finished.connect(func() -> void:
		if _event_overlay_tween == tween:
			_event_overlay_tween = null
	)


func close_event_overlay(immediate: bool = false) -> void:
	if _event_overlay == null or not is_instance_valid(_event_overlay):
		_event_overlay = null
		_event_overlay_tween = null
		return

	if _event_overlay_tween != null and is_instance_valid(_event_overlay_tween):
		_event_overlay_tween.kill()
		_event_overlay_tween = null

	if immediate:
		_remove_event_overlay()
		return

	var overlay: Control = _event_overlay
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween: Tween = create_tween()
	_event_overlay_tween = tween
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(EVENT_OVERLAY_TWEEN_TRANSITION)
	tween.tween_property(overlay, "modulate", Color(1, 1, 1, 0), EVENT_OVERLAY_CLOSE_DURATION)
	tween.parallel().tween_property(overlay, "scale", Vector2(EVENT_OVERLAY_CLOSED_SCALE, EVENT_OVERLAY_CLOSED_SCALE), EVENT_OVERLAY_CLOSE_DURATION)
	tween.finished.connect(func() -> void:
		if overlay != null and is_instance_valid(overlay):
			_remove_event_overlay()
		if _event_overlay_tween == tween:
			_event_overlay_tween = null
	)


func _remove_event_overlay() -> void:
	if _event_overlay != null and is_instance_valid(_event_overlay):
		_event_overlay.queue_free()
	_event_overlay = null


func _position_overlay(overlay: Control) -> void:
	if overlay == null or not is_instance_valid(overlay):
		return
	var viewport_rect: Rect2 = get_viewport_rect()
	overlay.position = viewport_rect.position
	overlay.size = viewport_rect.size

	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.grow_horizontal = Control.GROW_DIRECTION_BOTH
	overlay.grow_vertical = Control.GROW_DIRECTION_BOTH
	overlay.pivot_offset = viewport_rect.size * 0.5


func _position_event_overlay() -> void:
	_position_overlay(_event_overlay)


func open_support_overlay() -> void:
	if _support_overlay_tween != null and is_instance_valid(_support_overlay_tween):
		_support_overlay_tween.kill()
		_support_overlay_tween = null

	if _support_overlay != null and not is_instance_valid(_support_overlay):
		_support_overlay = null
	if _support_overlay != null and _support_overlay.is_queued_for_deletion():
		_support_overlay = null
	if _support_overlay == null:
		var overlay_instance: Node = SupportInteractionSceneScript.instantiate()
		if overlay_instance == null:
			return
		var overlay_control: Control = overlay_instance as Control
		if overlay_control == null:
			push_error("Support interaction overlay must inherit Control.")
			overlay_instance.queue_free()
			return

		overlay_control.name = "SupportOverlay"
		overlay_control.top_level = true
		overlay_control.z_as_relative = false
		overlay_control.z_index = EVENT_OVERLAY_Z_INDEX
		overlay_control.visible = false
		overlay_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay_control.anchor_right = 1.0
		overlay_control.anchor_bottom = 1.0
		overlay_control.grow_horizontal = Control.GROW_DIRECTION_BOTH
		overlay_control.grow_vertical = Control.GROW_DIRECTION_BOTH
		add_child(overlay_control)
		_support_overlay = overlay_control

	if _support_overlay == null or not is_instance_valid(_support_overlay):
		return

	_support_overlay.visible = true
	_support_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_tune_event_overlay_visuals(_support_overlay)
	_support_overlay.modulate = Color(1, 1, 1, 0)
	_support_overlay.scale = Vector2(EVENT_OVERLAY_OPEN_SCALE, EVENT_OVERLAY_OPEN_SCALE)
	_position_overlay(_support_overlay)

	var tween: Tween = create_tween()
	_support_overlay_tween = tween
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(EVENT_OVERLAY_TWEEN_TRANSITION)
	tween.tween_property(_support_overlay, "modulate", Color(1, 1, 1, 1), EVENT_OVERLAY_OPEN_DURATION)
	tween.parallel().tween_property(_support_overlay, "scale", Vector2.ONE, EVENT_OVERLAY_OPEN_DURATION)
	tween.finished.connect(func() -> void:
		if _support_overlay_tween == tween:
			_support_overlay_tween = null
	)


func close_support_overlay(immediate: bool = false) -> void:
	if _support_overlay == null or not is_instance_valid(_support_overlay):
		_support_overlay = null
		_support_overlay_tween = null
		return

	if _support_overlay_tween != null and is_instance_valid(_support_overlay_tween):
		_support_overlay_tween.kill()
		_support_overlay_tween = null

	if immediate:
		_remove_support_overlay()
		return

	var overlay: Control = _support_overlay
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween: Tween = create_tween()
	_support_overlay_tween = tween
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(EVENT_OVERLAY_TWEEN_TRANSITION)
	tween.tween_property(overlay, "modulate", Color(1, 1, 1, 0), EVENT_OVERLAY_CLOSE_DURATION)
	tween.parallel().tween_property(overlay, "scale", Vector2(EVENT_OVERLAY_CLOSED_SCALE, EVENT_OVERLAY_CLOSED_SCALE), EVENT_OVERLAY_CLOSE_DURATION)
	tween.finished.connect(func() -> void:
		if overlay != null and is_instance_valid(overlay):
			_remove_support_overlay()
		if _support_overlay_tween == tween:
			_support_overlay_tween = null
	)


func _remove_support_overlay() -> void:
	if _support_overlay != null and is_instance_valid(_support_overlay):
		_support_overlay.queue_free()
	_support_overlay = null


func open_reward_overlay() -> void:
	if _reward_overlay_tween != null and is_instance_valid(_reward_overlay_tween):
		_reward_overlay_tween.kill()
		_reward_overlay_tween = null

	if _reward_overlay != null and not is_instance_valid(_reward_overlay):
		_reward_overlay = null
	if _reward_overlay != null and _reward_overlay.is_queued_for_deletion():
		_reward_overlay = null
	if _reward_overlay == null:
		var overlay_instance: Node = RewardSceneScript.instantiate()
		if overlay_instance == null:
			return
		var overlay_control: Control = overlay_instance as Control
		if overlay_control == null:
			push_error("Reward overlay must inherit Control.")
			overlay_instance.queue_free()
			return

		overlay_control.name = "RewardOverlay"
		overlay_control.top_level = true
		overlay_control.z_as_relative = false
		overlay_control.z_index = EVENT_OVERLAY_Z_INDEX
		overlay_control.visible = false
		overlay_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay_control.anchor_right = 1.0
		overlay_control.anchor_bottom = 1.0
		overlay_control.grow_horizontal = Control.GROW_DIRECTION_BOTH
		overlay_control.grow_vertical = Control.GROW_DIRECTION_BOTH
		add_child(overlay_control)
		_reward_overlay = overlay_control

	if _reward_overlay == null or not is_instance_valid(_reward_overlay):
		return

	_reward_overlay.visible = true
	_reward_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_tune_event_overlay_visuals(_reward_overlay)
	_reward_overlay.modulate = Color(1, 1, 1, 0)
	_reward_overlay.scale = Vector2(EVENT_OVERLAY_OPEN_SCALE, EVENT_OVERLAY_OPEN_SCALE)
	_position_overlay(_reward_overlay)

	var tween: Tween = create_tween()
	_reward_overlay_tween = tween
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(EVENT_OVERLAY_TWEEN_TRANSITION)
	tween.tween_property(_reward_overlay, "modulate", Color(1, 1, 1, 1), EVENT_OVERLAY_OPEN_DURATION)
	tween.parallel().tween_property(_reward_overlay, "scale", Vector2.ONE, EVENT_OVERLAY_OPEN_DURATION)
	tween.finished.connect(func() -> void:
		if _reward_overlay_tween == tween:
			_reward_overlay_tween = null
	)


func close_reward_overlay(immediate: bool = false) -> void:
	if _reward_overlay == null or not is_instance_valid(_reward_overlay):
		_reward_overlay = null
		_reward_overlay_tween = null
		return

	if _reward_overlay_tween != null and is_instance_valid(_reward_overlay_tween):
		_reward_overlay_tween.kill()
		_reward_overlay_tween = null

	if immediate:
		_remove_reward_overlay()
		return

	var overlay: Control = _reward_overlay
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween: Tween = create_tween()
	_reward_overlay_tween = tween
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(EVENT_OVERLAY_TWEEN_TRANSITION)
	tween.tween_property(overlay, "modulate", Color(1, 1, 1, 0), EVENT_OVERLAY_CLOSE_DURATION)
	tween.parallel().tween_property(overlay, "scale", Vector2(EVENT_OVERLAY_CLOSED_SCALE, EVENT_OVERLAY_CLOSED_SCALE), EVENT_OVERLAY_CLOSE_DURATION)
	tween.finished.connect(func() -> void:
		if overlay != null and is_instance_valid(overlay):
			_remove_reward_overlay()
		if _reward_overlay_tween == tween:
			_reward_overlay_tween = null
	)


func _remove_reward_overlay() -> void:
	if _reward_overlay != null and is_instance_valid(_reward_overlay):
		_reward_overlay.queue_free()
	_reward_overlay = null


func open_level_up_overlay() -> void:
	if _level_up_overlay_tween != null and is_instance_valid(_level_up_overlay_tween):
		_level_up_overlay_tween.kill()
		_level_up_overlay_tween = null

	if _level_up_overlay != null and not is_instance_valid(_level_up_overlay):
		_level_up_overlay = null
	if _level_up_overlay != null and _level_up_overlay.is_queued_for_deletion():
		_level_up_overlay = null
	if _level_up_overlay == null:
		var overlay_instance: Node = LevelUpSceneScript.instantiate()
		if overlay_instance == null:
			return
		var overlay_control: Control = overlay_instance as Control
		if overlay_control == null:
			push_error("Level up overlay must inherit Control.")
			overlay_instance.queue_free()
			return

		overlay_control.name = "LevelUpOverlay"
		overlay_control.top_level = true
		overlay_control.z_as_relative = false
		overlay_control.z_index = EVENT_OVERLAY_Z_INDEX
		overlay_control.visible = false
		overlay_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay_control.anchor_right = 1.0
		overlay_control.anchor_bottom = 1.0
		overlay_control.grow_horizontal = Control.GROW_DIRECTION_BOTH
		overlay_control.grow_vertical = Control.GROW_DIRECTION_BOTH
		add_child(overlay_control)
		_level_up_overlay = overlay_control

	if _level_up_overlay == null or not is_instance_valid(_level_up_overlay):
		return

	_level_up_overlay.visible = true
	_level_up_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_tune_event_overlay_visuals(_level_up_overlay)
	_level_up_overlay.modulate = Color(1, 1, 1, 0)
	_level_up_overlay.scale = Vector2(EVENT_OVERLAY_OPEN_SCALE, EVENT_OVERLAY_OPEN_SCALE)
	_position_overlay(_level_up_overlay)

	var tween: Tween = create_tween()
	_level_up_overlay_tween = tween
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(EVENT_OVERLAY_TWEEN_TRANSITION)
	tween.tween_property(_level_up_overlay, "modulate", Color(1, 1, 1, 1), EVENT_OVERLAY_OPEN_DURATION)
	tween.parallel().tween_property(_level_up_overlay, "scale", Vector2.ONE, EVENT_OVERLAY_OPEN_DURATION)
	tween.finished.connect(func() -> void:
		if _level_up_overlay_tween == tween:
			_level_up_overlay_tween = null
	)


func close_level_up_overlay(immediate: bool = false) -> void:
	if _level_up_overlay == null or not is_instance_valid(_level_up_overlay):
		_level_up_overlay = null
		_level_up_overlay_tween = null
		return

	if _level_up_overlay_tween != null and is_instance_valid(_level_up_overlay_tween):
		_level_up_overlay_tween.kill()
		_level_up_overlay_tween = null

	if immediate:
		_remove_level_up_overlay()
		return

	var overlay: Control = _level_up_overlay
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween: Tween = create_tween()
	_level_up_overlay_tween = tween
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(EVENT_OVERLAY_TWEEN_TRANSITION)
	tween.tween_property(overlay, "modulate", Color(1, 1, 1, 0), EVENT_OVERLAY_CLOSE_DURATION)
	tween.parallel().tween_property(overlay, "scale", Vector2(EVENT_OVERLAY_CLOSED_SCALE, EVENT_OVERLAY_CLOSED_SCALE), EVENT_OVERLAY_CLOSE_DURATION)
	tween.finished.connect(func() -> void:
		if overlay != null and is_instance_valid(overlay):
			_remove_level_up_overlay()
		if _level_up_overlay_tween == tween:
			_level_up_overlay_tween = null
	)


func _remove_level_up_overlay() -> void:
	if _level_up_overlay != null and is_instance_valid(_level_up_overlay):
		_level_up_overlay.queue_free()
	_level_up_overlay = null


func _tune_event_overlay_visuals(event_overlay: Control) -> void:
	if event_overlay == null or not is_instance_valid(event_overlay):
		return

	var background_far: CanvasItem = event_overlay.get_node_or_null("BackgroundFar") as CanvasItem
	if background_far != null:
		background_far.modulate = Color(1, 1, 1, EVENT_OVERLAY_FAR_ALPHA)
	var background_mid: CanvasItem = event_overlay.get_node_or_null("BackgroundMid") as CanvasItem
	if background_mid != null:
		background_mid.modulate = Color(1, 1, 1, EVENT_OVERLAY_MID_ALPHA)
	var background_overlay: CanvasItem = event_overlay.get_node_or_null("BackgroundOverlay") as CanvasItem
	if background_overlay != null:
		background_overlay.modulate = Color(1, 1, 1, EVENT_OVERLAY_OVERLAY_ALPHA)
	var scrim: ColorRect = event_overlay.get_node_or_null("Scrim") as ColorRect
	if scrim != null:
		scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scrim.color = Color(scrim.color.r, scrim.color.g, scrim.color.b, EVENT_OVERLAY_SCRIM_ALPHA)


func _apply_portrait_safe_layout() -> void:
	MapExploreSceneUiScript.apply_portrait_safe_layout(self, PORTRAIT_SAFE_MAX_WIDTH, PORTRAIT_SAFE_MIN_SIDE_MARGIN)


func _setup_safe_menu() -> void:
	_safe_menu = RunMenuSceneHelperScript.ensure_safe_menu(
		self,
		_safe_menu,
		"Settings",
		"Save your run, mute music, or quit.",
		"Settings",
		Callable(self, "_on_save_run_pressed"),
		Callable(self, "_on_load_run_pressed")
	)
	_refresh_safe_menu_anchor_layout()


func _refresh_safe_menu_anchor_layout() -> void:
	if _safe_menu != null and _safe_menu.has_method("set_launcher_corner"):
		_safe_menu.set_launcher_corner("top_left")
	if _safe_menu != null and _safe_menu.has_method("set_launcher_alignment_target"):
		var settings_anchor: Control = get_node_or_null(SETTINGS_MENU_ANCHOR_PATH) as Control
		if settings_anchor == null:
			settings_anchor = get_node_or_null("Margin/VBox/TopRow")
		if settings_anchor != null:
			_safe_menu.set_launcher_alignment_target(settings_anchor)

func _ensure_inventory_tooltip_shell() -> void:
	if _inventory_tooltip_panel != null and is_instance_valid(_inventory_tooltip_panel):
		return

	_inventory_tooltip_panel = PanelContainer.new()
	_inventory_tooltip_panel.name = INVENTORY_TOOLTIP_PANEL_NAME
	_inventory_tooltip_panel.visible = false
	_inventory_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inventory_tooltip_panel.top_level = true
	_inventory_tooltip_panel.z_index = 120
	add_child(_inventory_tooltip_panel)

	_inventory_tooltip_label = Label.new()
	_inventory_tooltip_label.name = INVENTORY_TOOLTIP_LABEL_NAME
	_inventory_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inventory_tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_inventory_tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_inventory_tooltip_panel.add_child(_inventory_tooltip_label)
	_apply_inventory_tooltip_style(TempScreenThemeScript.PANEL_BORDER_COLOR)


func _ensure_inventory_hint_label() -> void:
	var inventory_section: VBoxContainer = get_node_or_null("Margin/VBox/InventorySection") as VBoxContainer
	if inventory_section == null:
		return
	var inventory_hint_label: Label = inventory_section.get_node_or_null("InventoryHintLabel") as Label
	if inventory_hint_label == null:
		inventory_hint_label = Label.new()
		inventory_hint_label.name = "InventoryHintLabel"
		inventory_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inventory_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inventory_section.add_child(inventory_hint_label)
		inventory_section.move_child(inventory_hint_label, 1)




func _apply_inventory_tooltip_style(accent: Color) -> void:
	if _inventory_tooltip_panel == null or _inventory_tooltip_label == null:
		return

	TempScreenThemeScript.apply_panel(_inventory_tooltip_panel, accent, 16, 0.96)
	TempScreenThemeScript.apply_label(_inventory_tooltip_label)
	_inventory_tooltip_label.add_theme_font_size_override("font_size", 18)
	_inventory_tooltip_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)


func _on_inventory_card_mouse_entered(card: Control, accent: Color) -> void:
	if card == null:
		return

	_hovered_inventory_card = card
	_hovered_inventory_accent = accent
	_show_inventory_tooltip(card, accent, _get_inventory_tooltip_text(card))


func _on_inventory_card_mouse_exited(card: Control) -> void:
	if card != _hovered_inventory_card:
		return
	_hide_inventory_tooltip(true)


func _refresh_hovered_inventory_tooltip() -> void:
	if _hovered_inventory_card == null or not is_instance_valid(_hovered_inventory_card):
		return
	if not _hovered_inventory_card.visible:
		_hide_inventory_tooltip(true)
		return
	_show_inventory_tooltip(_hovered_inventory_card, _hovered_inventory_accent, _get_inventory_tooltip_text(_hovered_inventory_card))


func _show_inventory_tooltip(card: Control, accent: Color, tooltip_text: String) -> void:
	_ensure_inventory_tooltip_shell()
	if _inventory_tooltip_panel == null or _inventory_tooltip_label == null:
		return

	var trimmed_text: String = tooltip_text.strip_edges()
	if card == null or trimmed_text.is_empty():
		_hide_inventory_tooltip()
		return

	_apply_inventory_tooltip_style(accent)
	_inventory_tooltip_label.text = trimmed_text
	var viewport_width: float = get_viewport_rect().size.x
	var tooltip_width: float = clamp(viewport_width - (INVENTORY_TOOLTIP_MARGIN * 2.0), 200.0, INVENTORY_TOOLTIP_MAX_WIDTH)
	_inventory_tooltip_panel.custom_minimum_size = Vector2(tooltip_width, 0.0)
	_inventory_tooltip_panel.size = _inventory_tooltip_panel.get_combined_minimum_size()
	_position_inventory_tooltip(card)
	_inventory_tooltip_panel.visible = true


func _position_inventory_tooltip(card: Control) -> void:
	if _inventory_tooltip_panel == null or card == null:
		return

	var card_rect: Rect2 = card.get_global_rect()
	var viewport_size: Vector2 = get_viewport_rect().size
	var tooltip_size: Vector2 = _inventory_tooltip_panel.size
	var x_position: float = clamp(
		card_rect.position.x + ((card_rect.size.x - tooltip_size.x) * 0.5),
		INVENTORY_TOOLTIP_MARGIN,
		max(INVENTORY_TOOLTIP_MARGIN, viewport_size.x - tooltip_size.x - INVENTORY_TOOLTIP_MARGIN)
	)
	var y_position: float = card_rect.position.y - tooltip_size.y - INVENTORY_TOOLTIP_GAP
	if y_position < INVENTORY_TOOLTIP_MARGIN:
		y_position = min(
			viewport_size.y - tooltip_size.y - INVENTORY_TOOLTIP_MARGIN,
			card_rect.position.y + card_rect.size.y + INVENTORY_TOOLTIP_GAP
		)
	_inventory_tooltip_panel.global_position = Vector2(x_position, y_position)


func _get_inventory_tooltip_text(card: Control) -> String:
	if card == null:
		return ""
	if card.has_meta(INVENTORY_TOOLTIP_META_KEY):
		return String(card.get_meta(INVENTORY_TOOLTIP_META_KEY, ""))
	return card.tooltip_text


func _hide_inventory_tooltip(clear_hovered_card: bool = false) -> void:
	if _inventory_tooltip_panel != null:
		_inventory_tooltip_panel.visible = false
	if clear_hovered_card:
		_hovered_inventory_card = null
