# Layer: Scenes - presentation only
extends Control

const MapExplorePresenterScript = preload("res://Game/UI/map_explore_presenter.gd")
const InventoryPresenterScript = preload("res://Game/UI/inventory_presenter.gd")
const InventoryCardInteractionHandlerScript = preload("res://Game/UI/inventory_card_interaction_handler.gd")
const OverlayLifecycleHelperScript = preload("res://Game/UI/overlay_lifecycle_helper.gd")
const MapBoardStyleScript = preload("res://Game/UI/map_board_style.gd")
const MapBoardComposerV2Script = preload("res://Game/UI/map_board_composer_v2.gd")
const MapExploreSceneUiScript = preload("res://Game/UI/map_explore_scene_ui.gd")
const RunStatusStripScript = preload("res://Game/UI/run_status_strip.gd")
const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const HungerWarningToastScript = preload("res://Game/UI/hunger_warning_toast.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const MapFocusHelperScript = preload("res://Game/UI/map_focus_helper.gd")
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
const EVENT_OVERLAY_FAR_ALPHA := 0.0
const EVENT_OVERLAY_MID_ALPHA := 0.0
const EVENT_OVERLAY_OVERLAY_ALPHA := 0.0
const EVENT_OVERLAY_SCRIM_ALPHA := 0.42
const EVENT_OVERLAY_ROADSIDE_SCRIM_ALPHA := 0.54
const EVENT_OVERLAY_TWEEN_TRANSITION := Tween.TRANS_EXPO
const AUDIO_PLAYER_CONFIG := {
	"NodeSelectSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_node_select_01.ogg"},
	"MapMusicPlayer": {"path": "res://Assets/Audio/Music/music_ui_hub_loop_proto_01.ogg", "music": true, "loop": true},
}
const INVENTORY_TOOLTIP_PANEL_NAME := "InventoryTooltipPanel"
const INVENTORY_TOOLTIP_LABEL_NAME := "InventoryTooltipLabel"
const INVENTORY_TOOLTIP_MARGIN := 16.0
const INVENTORY_TOOLTIP_GAP := 12.0
const INVENTORY_TOOLTIP_MAX_WIDTH := 320.0
const INVENTORY_TOOLTIP_META_KEY := "custom_tooltip_text"
const INVENTORY_DRAG_THRESHOLD := 14.0
const PORTRAIT_SAFE_MAX_WIDTH := 1120
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 14
const TOP_ROW_PATH := "Margin/VBox/TopRow"
const HEADER_STACK_PATH := "Margin/VBox/TopRow/HeaderCard/HeaderRow/HeaderStack"
const STAGE_BADGE_LABEL_PATH := "Margin/VBox/TopRow/HeaderCard/HeaderRow/StageBadge/StageBadgeLabel"
const RUN_SUMMARY_CARD_PATH := "Margin/VBox/TopRow/RunSummaryCard"
const ROUTE_GRID_PATH := "Margin/VBox/RouteGrid"
const SETTINGS_MENU_ANCHOR_PATH := "Margin/VBox/TopRow/SettingsMenuAnchor"
const OVERLAY_KEYS := ["event", "support", "reward", "level_up"]
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

const EMERGENCY_ROUTE_SLOT_TOP_LEFT := Vector2(0.38, 0.40)
const EMERGENCY_ROUTE_SLOT_TOP_RIGHT := Vector2(0.62, 0.40)
const EMERGENCY_ROUTE_SLOT_BOTTOM_LEFT := Vector2(0.40, 0.68)
const EMERGENCY_ROUTE_SLOT_BOTTOM_RIGHT := Vector2(0.60, 0.68)
const EMERGENCY_ROUTE_SLOT_LOWER_MID := Vector2(0.50, 0.80)
const EMERGENCY_ROUTE_SLOT_FORWARD := Vector2(0.50, 0.24)
const ROUTE_MARKER_SIZE := Vector2(144, 144)
const ROUTE_HITBOX_SIZE := Vector2(160, 160)
const CURRENT_MARKER_SIZE := Vector2(36, 36)
const BOARD_FOCUS_ANCHOR_FACTOR := Vector2(0.5, 0.55)
const BOARD_MAX_OFFSET_FACTOR := Vector2(0.05, 0.06)
const BOARD_FOCUS_DEADZONE_FACTOR := Vector2(0.18, 0.20)
const BOARD_FOCUS_DAMPING := 0.42
const BOARD_FOCUS_CONTEXT_BLEND_MIN := 0.08
const BOARD_FOCUS_CONTEXT_BLEND_MAX := 0.24
const WALKER_ROOT_SIZE := Vector2(122, 150)
const WALKER_SHADOW_SIZE := Vector2(40, 10)
const WALKER_SPRITE_SIZE := Vector2(100, 120)
const ROUTE_MOVE_MIN_DURATION := 0.30
const ROUTE_MOVE_MAX_DURATION := 0.88
const ROUTE_MOVE_BASE_DURATION := 0.20
const ROUTE_MOVE_PIXELS_PER_SECOND := 820.0
const ROUTE_MOVE_CAMERA_DELAY_RATIO := 0.12
const WALKER_FRAME_INTERVAL_MIN := 0.075
const WALKER_FRAME_INTERVAL_MAX := 0.12
const WALKER_STRIDE_PIXELS_PER_CYCLE := 118.0
const WALKER_STRIDE_BOB_MAX := 6.0
const WALKER_ARRIVAL_PAUSE := 0.08
const ROADSIDE_INTERRUPTION_PROGRESS := 0.58
const ROADSIDE_CONTINUATION_CLOSE_LEAD_IN := 0.06
const NODE_PLATE_SIZE := Vector2(116, 116)
const NODE_ICON_SIZE := Vector2(92, 92)
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
var _current_marker: TextureRect
var _board_canvas: Control
var _road_base_lines: Array[Line2D] = []
var _road_highlight_lines: Array[Line2D] = []
var _walker_root: Control
var _walker_shadow: PanelContainer
var _walker_sprite: TextureRect
var _walker_cycle_token: int = 0
var _walker_frame_interval: float = 0.1
var _walker_facing_right: bool = true
var _active_route_index: int = -1
var _hovered_route_index: int = -1
var _safe_menu: SafeMenuOverlay
var _route_layout_offset: Vector2 = Vector2.ZERO
var _route_move_start_offset: Vector2 = Vector2.ZERO
var _route_move_target_offset: Vector2 = Vector2.ZERO
var _route_move_world_path: PackedVector2Array = PackedVector2Array()
var _route_move_path_length: float = 0.0
var _route_move_stride_cycles: float = 0.0
var _route_move_sample_start_progress: float = 0.0
var _route_move_sample_end_progress: float = 1.0
var _inventory_tooltip_panel: PanelContainer
var _inventory_tooltip_label: Label
var _hovered_inventory_card: Control
var _hovered_inventory_accent: Color = TempScreenThemeScript.PANEL_BORDER_COLOR
var _inventory_card_handler: InventoryCardInteractionHandler
var _overlay_lifecycle: OverlayLifecycleHelper
var _is_refreshing_ui: bool = false
var _refresh_ui_pending: bool = false
var _run_status_model_signature: String = ""
var _equipment_cards_signature: String = ""
var _backpack_cards_signature: String = ""
var _roadside_visual_state: Dictionary = {}
var _roadside_transition_in_flight: bool = false
var _run_status_strip: RunStatusStrip
var _hunger_warning_toast: HungerWarningToast

func _ready() -> void:
	_presenter = MapExplorePresenterScript.new()
	_inventory_presenter = InventoryPresenterScript.new()
	_board_composer = MapBoardComposerV2Script.new()
	_run_status_strip = RunStatusStripScript.new()
	if _run_status_strip != null and not _run_status_strip.is_connected("hunger_threshold_crossed", Callable(self, "_on_hunger_threshold_crossed")):
		_run_status_strip.connect("hunger_threshold_crossed", Callable(self, "_on_hunger_threshold_crossed"))
	_inventory_card_handler = InventoryCardInteractionHandlerScript.new()
	_inventory_card_handler.configure(self, {
		"click_handler": Callable(self, "_handle_inventory_card_click"),
		"drag_complete_handler": Callable(self, "_handle_inventory_card_drag_completed"),
		"drag_started_handler": Callable(self, "_on_inventory_card_drag_started"),
		"mouse_entered_handler": Callable(self, "_on_inventory_card_mouse_entered"),
		"mouse_exited_handler": Callable(self, "_on_inventory_card_mouse_exited"),
		"drag_threshold": INVENTORY_DRAG_THRESHOLD,
	})
	_overlay_lifecycle = OverlayLifecycleHelperScript.new()
	_overlay_lifecycle.configure(self, {
		"overlay_z_index": EVENT_OVERLAY_Z_INDEX,
		"open_duration": EVENT_OVERLAY_OPEN_DURATION,
		"close_duration": EVENT_OVERLAY_CLOSE_DURATION,
		"open_scale": EVENT_OVERLAY_OPEN_SCALE,
		"closed_scale": EVENT_OVERLAY_CLOSED_SCALE,
		"tween_transition": EVENT_OVERLAY_TWEEN_TRANSITION,
		"before_show_handler": Callable(self, "_tune_event_overlay_visuals"),
	})
	_connect_route_buttons()
	_apply_static_map_textures()
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	_ensure_runtime_board_nodes()
	_ensure_inventory_hint_label()
	_apply_temp_theme()
	_ensure_hunger_warning_toast()
	_ensure_inventory_tooltip_shell()
	_style_route_buttons_for_overlay_mode()
	_apply_text_density_pass()
	_setup_safe_menu()
	SceneLayoutHelperScript.bind_viewport_size_changed(self, Callable(self, "_on_viewport_size_changed"))
	_apply_portrait_safe_layout()
	SceneAudioPlayersScript.start_looping(self, "MapMusicPlayer")

	var route_grid: Control = get_node_or_null(ROUTE_GRID_PATH) as Control
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
	if _hunger_warning_toast != null:
		_hunger_warning_toast.release()
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_on_viewport_size_changed"))
	if _inventory_card_handler != null:
		_inventory_card_handler.stop_interaction()
	_hide_inventory_tooltip(true)
	close_event_overlay(true)
	close_support_overlay(true)
	close_reward_overlay(true)
	close_level_up_overlay(true)
	SceneAudioCleanupScript.release_players(self, SceneAudioPlayersScript.node_names_from_config(AUDIO_PLAYER_CONFIG))


func _input(event: InputEvent) -> void:
	if _inventory_card_handler == null:
		return
	_inventory_card_handler.handle_root_input(event)


func _on_route_button_pressed(button_node_name: String) -> void:
	if _route_selection_in_flight:
		return
	var button: Button = get_node_or_null("%s/%s" % [ROUTE_GRID_PATH, button_node_name]) as Button
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


func _on_return_to_main_menu_pressed() -> void:
	var bootstrap = _get_app_bootstrap()
	var flow_manager = bootstrap.get_flow_manager() if bootstrap != null else null
	if flow_manager != null:
		flow_manager.request_transition(FlowStateScript.Type.MAIN_MENU)


func _move_to_node(node_reference: Variant) -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		_append_status_line("AppBootstrap not available.")
		_refresh_ui()
		return

	var result: Dictionary = bootstrap.choose_move_to_node(node_reference)
	if not bool(result.get("ok", false)):
		_clear_pending_roadside_visual_state()
		_append_status_line("Move failed: %s" % String(result.get("error", "unknown")))
		_refresh_ui()
		return

	var node_type: String = String(result.get("node_type", "node"))
	var node_state: String = String(result.get("node_state", ""))
	var target_state: int = int(result.get("target_state", FlowState.Type.MAP_EXPLORE))
	if _is_roadside_interruption_result(result):
		var run_state: RunState = _get_run_state()
		if run_state != null and run_state.map_runtime_state != null:
			_prime_roadside_visual_state(
				int(run_state.map_runtime_state.current_node_id),
				int(result.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
			)
		_append_status_line("Roadside encounter interrupts the trail before the destination.")
	else:
		_clear_pending_roadside_visual_state()
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
		_route_layout_offset = _desired_focus_offset_for_world_position(
			_get_node_world_position(int(run_state.map_runtime_state.current_node_id))
		)
	if _has_pending_roadside_visual_state() and not _roadside_transition_in_flight:
		_route_layout_offset = Vector2(_roadside_visual_state.get("offset", _route_layout_offset))

	_refresh_inventory_cards(run_state)

	var title_label: Label = get_node_or_null("%s/TitleLabel" % HEADER_STACK_PATH) as Label
	if title_label != null:
		title_label.text = _presenter.build_title_text(run_state)
	var stage_badge_label: Label = get_node_or_null(STAGE_BADGE_LABEL_PATH) as Label
	if stage_badge_label != null:
		stage_badge_label.text = _presenter.build_stage_badge_text(run_state)

	var progress_label: Label = get_node_or_null("%s/ProgressLabel" % HEADER_STACK_PATH) as Label
	if progress_label != null:
		progress_label.text = _presenter.build_progress_text(run_state)
	var route_read_label: Label = get_node_or_null("%s/RouteReadLabel" % HEADER_STACK_PATH) as Label
	if route_read_label != null:
		route_read_label.text = _presenter.build_route_overview_text(run_state)
		route_read_label.visible = not route_read_label.text.is_empty()
	var run_summary_card: PanelContainer = get_node_or_null(RUN_SUMMARY_CARD_PATH) as PanelContainer
	var run_status_label: Label = get_node_or_null("%s/RunStatusLabel" % RUN_SUMMARY_CARD_PATH) as Label
	var run_status_model: Dictionary = _presenter.build_run_status_model(run_state)
	var run_status_signature: String = JSON.stringify(run_status_model)
	if run_summary_card != null and run_status_signature != _run_status_model_signature:
		_run_status_strip.render_into_with_hunger_signal(
			run_summary_card,
			run_status_label,
			run_status_model,
			TempScreenThemeScript.PANEL_BORDER_COLOR
		)
		_run_status_model_signature = run_status_signature

	var focus_model: Dictionary = _presenter.build_focus_panel_model(run_state, _resolve_focused_node_id(run_state))
	var current_anchor_label: Label = get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorLabel") as Label
	if current_anchor_label != null:
		current_anchor_label.text = String(focus_model.get("title_text", ""))

	var current_anchor_detail_label: Label = get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorDetailLabel") as Label
	if current_anchor_detail_label != null:
		current_anchor_detail_label.text = String(focus_model.get("detail_text", ""))

	var current_anchor_hint_label: Label = get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorHintLabel") as Label
	if current_anchor_hint_label != null:
		current_anchor_hint_label.text = String(focus_model.get("hint_text", ""))
		current_anchor_hint_label.visible = not current_anchor_hint_label.text.is_empty()

	for index in range(ROUTE_BUTTON_NODE_NAMES.size()):
		var route_button: Button = get_node_or_null("%s/%s" % [ROUTE_GRID_PATH, ROUTE_BUTTON_NODE_NAMES[index]]) as Button
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
	var has_status_history: bool = not _status_lines.is_empty()
	if status_label != null:
		status_label.text = _presenter.build_status_log_text(_status_lines, run_state) if has_status_history else ""
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
		_sync_walker_visual_state()

	_is_refreshing_ui = false
	if _refresh_ui_pending:
		call_deferred("_consume_pending_refresh_ui")


func _append_status_line(line: String) -> void:
	_status_lines.append(line)
	if _status_lines.size() > 6:
		_status_lines.remove_at(0)


func _refresh_inventory_cards(run_state: RunState) -> void:
	var equipment_container: Container = get_node_or_null("Margin/VBox/InventorySection/EquipmentCard/EquipmentCardsFlow") as Container
	var backpack_container: Container = get_node_or_null("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow") as Container
	if _inventory_presenter == null or equipment_container == null or backpack_container == null:
		return

	_hide_inventory_tooltip(true)
	if _inventory_card_handler != null:
		_inventory_card_handler.stop_interaction()
	var equipment_title_label: Label = get_node_or_null("Margin/VBox/InventorySection/EquipmentTitleLabel") as Label
	if equipment_title_label != null:
		equipment_title_label.text = _inventory_presenter.build_equipment_title_text()
	var equipment_hint_label: Label = get_node_or_null("Margin/VBox/InventorySection/EquipmentHintLabel") as Label
	if equipment_hint_label != null:
		equipment_hint_label.text = _inventory_presenter.build_equipment_hint_text(false)
		equipment_hint_label.visible = not equipment_hint_label.text.is_empty()
	var inventory_title_label: Label = get_node_or_null("Margin/VBox/InventorySection/InventoryTitleLabel") as Label
	if inventory_title_label != null:
		inventory_title_label.text = _inventory_presenter.build_inventory_title_text(run_state.inventory_state if run_state != null else null)
	var inventory_hint_label: Label = get_node_or_null("Margin/VBox/InventorySection/InventoryHintLabel") as Label
	if inventory_hint_label != null:
		var pressure_text: String = _presenter.build_inventory_pressure_text(run_state)
		inventory_hint_label.text = pressure_text if not pressure_text.is_empty() else _inventory_presenter.build_run_inventory_hint_text()
		inventory_hint_label.visible = not inventory_hint_label.text.is_empty() and get_viewport_rect().size.y >= 2000.0
	var equipment_card_models: Array[Dictionary] = _inventory_presenter.build_run_equipment_cards(run_state)
	for index in range(equipment_card_models.size()):
		var card_model: Dictionary = equipment_card_models[index]
		var is_clickable: bool = _inventory_card_is_clickable(card_model)
		var is_draggable: bool = _inventory_card_is_draggable(card_model)
		card_model["is_clickable"] = is_clickable
		card_model["is_draggable"] = is_draggable
		equipment_card_models[index] = _inventory_presenter.decorate_card_interaction_state(
			card_model,
			false,
			is_clickable,
			false,
			is_draggable
		)
	var backpack_card_models: Array[Dictionary] = _inventory_presenter.build_run_inventory_cards(run_state)
	for index in range(backpack_card_models.size()):
		var card_model: Dictionary = backpack_card_models[index]
		var is_clickable: bool = _inventory_card_is_clickable(card_model)
		var is_draggable: bool = _inventory_card_is_draggable(card_model)
		card_model["is_clickable"] = is_clickable
		card_model["is_draggable"] = is_draggable
		backpack_card_models[index] = _inventory_presenter.decorate_card_interaction_state(
			card_model,
			false,
			is_clickable,
			false,
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
	_apply_map_inventory_card_density(equipment_container)
	_apply_map_inventory_card_density(backpack_container)


func _inventory_card_is_clickable(card_model: Dictionary) -> bool:
	var card_family: String = String(card_model.get("card_family", ""))
	return card_family in ["weapon", "shield", "armor", "belt", "consumable", "shield_attachment"]


func _inventory_card_is_draggable(card_model: Dictionary) -> bool:
	return String(card_model.get("card_family", "")) != "empty" and int(card_model.get("inventory_slot_index", -1)) >= 0

func _apply_map_inventory_card_density(container: Container) -> void:
	if container == null:
		return
	var viewport_height: float = get_viewport_rect().size.y
	var compact_viewport: bool = viewport_height < 1560.0
	var very_compact_viewport: bool = viewport_height < 1360.0
	for child in container.get_children():
		var card: PanelContainer = child as PanelContainer
		if card == null:
			continue
		card.custom_minimum_size = Vector2(
			102.0 if very_compact_viewport else 112.0 if compact_viewport else 126.0,
			116.0 if very_compact_viewport else 126.0 if compact_viewport else 142.0
		)
		var slot_label: Label = card.get_node_or_null("VBox/HeaderRow/SlotLabel") as Label
		if slot_label != null:
			slot_label.add_theme_font_size_override("font_size", 11 if very_compact_viewport else 12)
		var count_label: Label = card.get_node_or_null("VBox/HeaderRow/CountLabel") as Label
		if count_label != null:
			count_label.add_theme_font_size_override("font_size", 12 if very_compact_viewport else 13)
		var icon_rect: TextureRect = card.get_node_or_null("VBox/IconRect") as TextureRect
		if icon_rect != null:
			icon_rect.custom_minimum_size = Vector2(34.0, 34.0) if very_compact_viewport else Vector2(38.0, 38.0) if compact_viewport else Vector2(42.0, 42.0)
		var placeholder_label: Label = card.get_node_or_null("VBox/PlaceholderLabel") as Label
		if placeholder_label != null:
			placeholder_label.add_theme_font_size_override("font_size", 20 if very_compact_viewport else 22 if compact_viewport else 24)
		var title_label: Label = card.get_node_or_null("VBox/TitleLabel") as Label
		if title_label != null:
			title_label.add_theme_font_size_override("font_size", 14 if very_compact_viewport else 15 if compact_viewport else 16)
		var detail_label: Label = card.get_node_or_null("VBox/DetailLabel") as Label
		if detail_label != null:
			detail_label.add_theme_font_size_override("font_size", 11 if very_compact_viewport else 12 if compact_viewport else 13)
		var action_hint_label: Label = card.get_node_or_null("VBox/ActionHintLabel") as Label
		if action_hint_label != null:
			action_hint_label.add_theme_font_size_override("font_size", 10 if very_compact_viewport else 11 if compact_viewport else 12)


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


func _handle_inventory_card_click(_slot_index: int, slot_id: int, card_family: String) -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return

	match card_family:
		"weapon", "shield", "armor", "belt", "shield_attachment":
			var toggle_result: Dictionary = bootstrap.toggle_inventory_equipment(slot_id)
			if not bool(toggle_result.get("ok", false)):
				_append_status_line(_build_inventory_failure_text(toggle_result))
			else:
				_append_status_line(_build_inventory_toggle_result_text(toggle_result))
		"consumable":
			var use_result: Dictionary = bootstrap.use_inventory_consumable(slot_id)
			if not bool(use_result.get("ok", false)):
				_append_status_line(_build_inventory_failure_text(use_result))
			else:
				_append_status_line(_build_consumable_result_text(use_result))
		_:
			return

	_refresh_ui()


func _on_inventory_card_drag_started() -> void:
	_hide_inventory_tooltip(true)


func _handle_inventory_card_drag_completed(slot_id: int, target_index: int) -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return
	var move_result: Dictionary = bootstrap.move_inventory_slot(slot_id, target_index)
	if not bool(move_result.get("ok", false)):
		_append_status_line(_build_inventory_failure_text(move_result))
		return
	_refresh_ui()


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


func _build_inventory_toggle_result_text(result: Dictionary) -> String:
	var action_name: String = String(result.get("action", "")).strip_edges()
	var definition_name: String = _build_inventory_result_name(result)
	match action_name:
		"attached_attachment":
			return "Attached %s to the equipped shield." % definition_name
		"detached_attachment":
			return "Detached %s from the equipped shield." % definition_name
		_:
			var action_label: String = "Equipped" if bool(result.get("equipped", false)) else "Unequipped"
			return "%s %s." % [action_label, definition_name]


func _build_inventory_failure_text(result: Dictionary) -> String:
	match String(result.get("error", "")):
		"no_effect":
			return "No need to use that item right now."
		"belt_capacity_required":
			var overflow_slots: int = max(1, int(result.get("required_capacity", 0)) - int(result.get("next_capacity", 0)))
			return "Free %d backpack slot%s before unequipping that belt." % [overflow_slots, "" if overflow_slots == 1 else "s"]
		"missing_shield_target":
			return "Equip a shield in the left hand before attaching that mod."
		"shield_attachment_slot_occupied":
			return "That shield already has a mod attached."
		"missing_shield_attachment":
			return "That shield has no attached mod to detach."
		_:
			return "Inventory action failed."


func _get_app_bootstrap():
	return get_node_or_null("/root/AppBootstrap") if is_inside_tree() else null


func _get_run_state() -> RunState:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.get_run_state()


func _connect_route_buttons() -> void:
	for button_node_name in ROUTE_BUTTON_NODE_NAMES:
		var route_button: Button = get_node_or_null("%s/%s" % [ROUTE_GRID_PATH, button_node_name]) as Button
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
	_set_texture_rect_texture("%s/BoardBackdrop" % ROUTE_GRID_PATH, MAP_BOARD_BACKDROP_TEXTURE)
	_set_texture_rect_texture("%s/KeyMarkerCard" % ROUTE_GRID_PATH, null)


func _animate_route_selection(button_node_name: String, target_node_id: int) -> void:
	var route_index: int = ROUTE_BUTTON_NODE_NAMES.find(button_node_name)
	if route_index < 0:
		_move_to_node(target_node_id)
		return

	_active_route_index = route_index
	_refresh_route_roads()
	_sync_walker_to_current_marker()

	var current_node_id: int = int(_board_composition_cache.get("current_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var start_center: Vector2 = _get_current_marker_center()
	var target_center: Vector2 = _get_route_marker_center(route_index)
	if start_center == Vector2.ZERO or target_center == Vector2.ZERO:
		_active_route_index = -1
		_refresh_route_roads()
		_move_to_node(target_node_id)
		return

	_set_walker_facing(target_center.x >= start_center.x)

	var target_world_position: Vector2 = _get_node_world_position(target_node_id)
	var target_offset: Vector2 = _desired_focus_offset_for_world_position(target_world_position)
	await _animate_route_move_camera_follow(
		start_center,
		target_center,
		target_offset,
		current_node_id,
		target_node_id
	)

	_stop_walker_walk_cycle()
	_set_walker_texture(MAP_WALKER_IDLE_TEXTURE)
	_reset_walker_stride_visuals()
	if is_inside_tree():
		await get_tree().create_timer(WALKER_ARRIVAL_PAUSE).timeout

	_move_to_node(target_node_id)
	if not _has_pending_roadside_visual_state():
		_active_route_index = -1
	_refresh_route_roads()

	if is_inside_tree() and get_tree().current_scene == self:
		_sync_walker_visual_state()


func _ensure_runtime_board_nodes() -> void:
	var route_grid: Control = get_node_or_null(ROUTE_GRID_PATH) as Control
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

	var marker_rect: TextureRect = get_node_or_null("%s/%s" % [ROUTE_GRID_PATH, ROUTE_MARKER_NODE_NAMES[index]]) as TextureRect
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
		icon_rect.texture = SceneLayoutHelperScript.load_texture_or_null(icon_texture_path)
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
	var route_grid: Control = get_node_or_null(ROUTE_GRID_PATH) as Control
	if route_grid == null:
		return

	var board_frame: PanelContainer = route_grid.get_node_or_null("BoardFrame") as PanelContainer
	if board_frame != null:
		board_frame.offset_left = 0.0
		board_frame.offset_top = 0.0
		board_frame.offset_right = 0.0
		board_frame.offset_bottom = 0.0

	var board_backdrop: TextureRect = route_grid.get_node_or_null("BoardBackdrop") as TextureRect
	if board_backdrop != null:
		board_backdrop.offset_left = 14.0
		board_backdrop.offset_top = 14.0
		board_backdrop.offset_right = -14.0
		board_backdrop.offset_bottom = -14.0
		board_backdrop.modulate = Color(1, 1, 1, 1.0)

	var visible_route_indices: Array[int] = []
	for index in range(ROUTE_MARKER_NODE_NAMES.size()):
		if index < _route_models_cache.size() and bool(_route_models_cache[index].get("visible", false)):
			visible_route_indices.append(index)

	var emergency_slot_factor_by_visible_index: Dictionary = {}
	if _visible_routes_need_emergency_slot_layout(visible_route_indices):
		emergency_slot_factor_by_visible_index = _build_emergency_route_slot_factor_map(visible_route_indices)

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
		var marker_position: Vector2 = _marker_position_for_route_model(marker_model, visible_slot_index, emergency_slot_factor_by_visible_index, route_grid.size)
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


func _visible_routes_need_emergency_slot_layout(visible_route_indices: Array[int]) -> bool:
	for visible_route_index in visible_route_indices:
		if visible_route_index < 0 or visible_route_index >= _route_models_cache.size():
			continue
		var node_id: int = int(_route_models_cache[visible_route_index].get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if _get_node_world_position(node_id) == Vector2.ZERO:
			return true
	return false


func _build_emergency_route_slot_factors(visible_count: int) -> Array[Vector2]:
	match visible_count:
		0:
			return []
		1:
			return [EMERGENCY_ROUTE_SLOT_FORWARD]
		2:
			return [EMERGENCY_ROUTE_SLOT_TOP_LEFT, EMERGENCY_ROUTE_SLOT_TOP_RIGHT]
		3:
			return [EMERGENCY_ROUTE_SLOT_FORWARD, EMERGENCY_ROUTE_SLOT_TOP_LEFT, EMERGENCY_ROUTE_SLOT_TOP_RIGHT]
		4:
			return [EMERGENCY_ROUTE_SLOT_FORWARD, EMERGENCY_ROUTE_SLOT_TOP_LEFT, EMERGENCY_ROUTE_SLOT_TOP_RIGHT, EMERGENCY_ROUTE_SLOT_LOWER_MID]
		5:
			return [EMERGENCY_ROUTE_SLOT_FORWARD, EMERGENCY_ROUTE_SLOT_TOP_LEFT, EMERGENCY_ROUTE_SLOT_TOP_RIGHT, EMERGENCY_ROUTE_SLOT_BOTTOM_LEFT, EMERGENCY_ROUTE_SLOT_BOTTOM_RIGHT]
		_:
			return [EMERGENCY_ROUTE_SLOT_FORWARD, EMERGENCY_ROUTE_SLOT_TOP_LEFT, EMERGENCY_ROUTE_SLOT_TOP_RIGHT, EMERGENCY_ROUTE_SLOT_BOTTOM_LEFT, EMERGENCY_ROUTE_SLOT_BOTTOM_RIGHT, EMERGENCY_ROUTE_SLOT_LOWER_MID]


func _build_emergency_route_slot_factor_map(visible_route_indices: Array[int]) -> Dictionary:
	var missing_visible_slot_indices: Array[int] = []
	for visible_slot_index in range(visible_route_indices.size()):
		var route_index: int = visible_route_indices[visible_slot_index]
		if route_index < 0 or route_index >= _route_models_cache.size():
			continue
		var node_id: int = int(_route_models_cache[route_index].get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if _get_node_world_position(node_id) != Vector2.ZERO:
			continue
		missing_visible_slot_indices.append(visible_slot_index)

	var slot_factors: Array[Vector2] = _build_emergency_route_slot_factors(missing_visible_slot_indices.size())
	var slot_factor_by_visible_index: Dictionary = {}
	for factor_index in range(min(missing_visible_slot_indices.size(), slot_factors.size())):
		slot_factor_by_visible_index[missing_visible_slot_indices[factor_index]] = slot_factors[factor_index]
	return slot_factor_by_visible_index


func _build_board_composition(run_state: RunState) -> Dictionary:
	var route_grid: Control = get_node_or_null(ROUTE_GRID_PATH) as Control
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
	emergency_slot_index: int,
	emergency_slot_factor_by_visible_index: Dictionary,
	board_size: Vector2
) -> Vector2:
	var node_id: int = int(model.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var world_position: Vector2 = _get_node_world_position(node_id)
	if world_position != Vector2.ZERO:
		return world_position + _route_layout_offset - (ROUTE_MARKER_SIZE * 0.5)
	if emergency_slot_factor_by_visible_index.has(emergency_slot_index):
		return _emergency_route_marker_position(board_size, Vector2(emergency_slot_factor_by_visible_index.get(emergency_slot_index, BOARD_FOCUS_ANCHOR_FACTOR)))
	return _emergency_board_anchor_marker_position(board_size)


func _get_node_world_position(node_id: int) -> Vector2:
	if node_id < 0 or _board_composition_cache.is_empty():
		return Vector2.ZERO
	var world_positions: Dictionary = _board_composition_cache.get("world_positions", {})
	return world_positions.get(node_id, Vector2.ZERO)


func _emergency_route_marker_position(board_size: Vector2, slot_factor: Vector2) -> Vector2:
	# Composer world positions are authoritative for board layout; fixed slots remain only as a narrow safety fallback.
	return board_size * slot_factor - (ROUTE_MARKER_SIZE * 0.5) + _route_layout_offset


func _emergency_board_anchor_marker_position(board_size: Vector2) -> Vector2:
	return board_size * BOARD_FOCUS_ANCHOR_FACTOR - (ROUTE_MARKER_SIZE * 0.5)


func _desired_focus_offset_for_world_position(world_position: Vector2) -> Vector2:
	var route_grid: Control = get_node_or_null(ROUTE_GRID_PATH) as Control
	var context_world_position: Vector2 = MapFocusHelperScript.focus_context_world_position(_board_composition_cache, world_position)
	var context_blend: float = MapFocusHelperScript.context_blend_for_positions(route_grid, world_position, context_world_position, BOARD_FOCUS_CONTEXT_BLEND_MIN, BOARD_FOCUS_CONTEXT_BLEND_MAX)
	return MapFocusHelperScript.desired_focus_offset(route_grid, _route_layout_offset, world_position, BOARD_FOCUS_ANCHOR_FACTOR, BOARD_MAX_OFFSET_FACTOR, BOARD_FOCUS_DEADZONE_FACTOR, BOARD_FOCUS_DAMPING, context_world_position, context_blend)


func _active_target_node_id() -> int:
	if _active_route_index < 0 or _active_route_index >= _route_models_cache.size():
		return MapRuntimeStateScript.NO_PENDING_NODE_ID
	return int(_route_models_cache[_active_route_index].get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))


func _resolve_focused_node_id(run_state: RunState) -> int:
	if _active_route_index >= 0 and _active_route_index < _route_models_cache.size():
		return int(_route_models_cache[_active_route_index].get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	if _hovered_route_index >= 0 and _hovered_route_index < _route_models_cache.size():
		return int(_route_models_cache[_hovered_route_index].get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	if run_state == null or run_state.map_runtime_state == null:
		return MapRuntimeStateScript.NO_PENDING_NODE_ID
	return int(run_state.map_runtime_state.current_node_id)


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


func _sync_walker_visual_state() -> void:
	if _has_pending_roadside_visual_state():
		_sync_walker_to_pending_roadside_visual()
		return
	_sync_walker_to_current_marker()


func _sync_walker_to_current_marker() -> void:
	if _walker_root == null or _current_marker == null or not _current_marker.visible:
		return
	_set_walker_texture(MAP_WALKER_IDLE_TEXTURE)
	_set_walker_facing(_walker_facing_right)
	_reset_walker_stride_visuals()
	_walker_root.visible = true
	_walker_root.position = _position_for_walker_center(_get_current_marker_center())


func _sync_walker_to_pending_roadside_visual() -> void:
	if _walker_root == null:
		return
	var sample: Dictionary = _build_pending_roadside_visual_sample()
	if sample.is_empty():
		_sync_walker_to_current_marker()
		return
	_set_walker_texture(MAP_WALKER_IDLE_TEXTURE)
	var direction: Vector2 = Vector2(sample.get("direction", Vector2.RIGHT))
	if direction.length_squared() > 0.001 and absf(direction.x) >= 0.08:
		_set_walker_facing(direction.x >= 0.0)
	_reset_walker_stride_visuals()
	_walker_root.visible = true
	var offset: Vector2 = Vector2(sample.get("offset", _route_layout_offset))
	var point: Vector2 = Vector2(sample.get("point", Vector2.ZERO))
	_walker_root.position = _position_for_walker_center(point + offset)


func _position_for_walker_center(center: Vector2) -> Vector2:
	return center - Vector2(WALKER_ROOT_SIZE.x * 0.5, WALKER_ROOT_SIZE.y * 0.88)


func _set_walker_facing(facing_right: bool) -> void:
	_walker_facing_right = facing_right
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
		await get_tree().create_timer(_walker_frame_interval).timeout


func _stop_walker_walk_cycle() -> void:
	_walker_cycle_token += 1


func _animate_route_move_camera_follow(
	start_center: Vector2,
	target_center: Vector2,
	target_offset: Vector2,
	current_node_id: int,
	target_node_id: int
) -> void:
	_route_move_world_path = _build_route_move_world_path(
		current_node_id,
		target_node_id,
		start_center - _route_layout_offset,
		target_center - _route_layout_offset
	)
	_route_move_path_length = _polyline_length(_route_move_world_path)
	var move_duration: float = _clamp_route_move_duration(_route_move_path_length)
	_route_move_stride_cycles = _resolve_route_move_stride_cycles(_route_move_path_length)
	_walker_frame_interval = _resolve_walker_frame_interval(_route_move_path_length, move_duration)
	_route_move_start_offset = _route_layout_offset
	_route_move_target_offset = target_offset
	_route_move_sample_start_progress = 0.0
	_route_move_sample_end_progress = 1.0
	if _walker_root != null:
		_walker_root.visible = true
		_reset_walker_stride_visuals()
	_start_walker_walk_cycle()

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(Callable(self, "_update_route_move_progress"), 0.0, 1.0, move_duration)
	await tween.finished


func _animate_route_move_camera_follow_segment(
	current_node_id: int,
	target_node_id: int,
	target_offset: Vector2,
	start_progress: float,
	end_progress: float
) -> void:
	_route_move_world_path = _build_route_move_world_path(
		current_node_id,
		target_node_id,
		_get_node_world_position(current_node_id),
		_get_node_world_position(target_node_id)
	)
	_route_move_path_length = _polyline_length(_route_move_world_path)
	var segment_start: float = clampf(start_progress, 0.0, 1.0)
	var segment_end: float = clampf(end_progress, 0.0, 1.0)
	if _route_move_path_length <= 0.001 or is_equal_approx(segment_start, segment_end):
		_route_layout_offset = target_offset
		_layout_route_grid()
		_refresh_route_board_offset()
		return

	var segment_length: float = _route_move_path_length * absf(segment_end - segment_start)
	var move_duration: float = _clamp_route_move_duration(segment_length)
	_route_move_stride_cycles = _resolve_route_move_stride_cycles(segment_length)
	_walker_frame_interval = _resolve_walker_frame_interval(segment_length, move_duration)
	_route_move_start_offset = _route_layout_offset
	_route_move_target_offset = target_offset
	_route_move_sample_start_progress = segment_start
	_route_move_sample_end_progress = segment_end
	if _walker_root != null:
		_walker_root.visible = true
		_reset_walker_stride_visuals()
	_start_walker_walk_cycle()

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(Callable(self, "_update_route_move_progress"), 0.0, 1.0, move_duration)
	await tween.finished


func _update_route_move_progress(progress: float) -> void:
	var travel_progress: float = lerpf(
		_route_move_sample_start_progress,
		_route_move_sample_end_progress,
		_ease_in_out_sine(progress)
	)
	var camera_progress: float = _route_camera_follow_progress(progress)
	var current_offset: Vector2 = _route_move_start_offset.lerp(_route_move_target_offset, camera_progress)
	_route_layout_offset = current_offset
	_layout_route_grid()
	_refresh_route_board_offset()

	if _walker_root == null:
		return

	var sample: Dictionary = _sample_route_move_world_state(travel_progress)
	var world_point: Vector2 = sample.get("point", Vector2.ZERO)
	var direction: Vector2 = sample.get("direction", Vector2.RIGHT)
	if direction.length_squared() > 0.001 and absf(direction.x) >= 0.08:
		_set_walker_facing(direction.x >= 0.0)
	var stride_offset: Vector2 = _walker_stride_offset(travel_progress)
	_apply_walker_stride_visuals(stride_offset)
	_walker_root.position = _position_for_walker_center(world_point + current_offset + stride_offset)


func _clamp_route_move_duration(distance: float) -> float:
	if distance <= 0.0:
		return ROUTE_MOVE_MIN_DURATION
	return clampf(
		ROUTE_MOVE_BASE_DURATION + (distance / ROUTE_MOVE_PIXELS_PER_SECOND),
		ROUTE_MOVE_MIN_DURATION,
		ROUTE_MOVE_MAX_DURATION
	)


func _route_camera_follow_progress(progress: float) -> float:
	var delayed_progress: float = clampf(
		(progress - ROUTE_MOVE_CAMERA_DELAY_RATIO) / max(0.001, 1.0 - ROUTE_MOVE_CAMERA_DELAY_RATIO),
		0.0,
		1.0
	)
	return _ease_in_out_sine(delayed_progress)


func begin_deferred_scene_transition(new_state: int, old_state: int) -> bool:
	if _roadside_transition_in_flight or not _has_pending_roadside_visual_state():
		return false
	if new_state in [FlowStateScript.Type.REWARD, FlowStateScript.Type.COMBAT] and old_state in [FlowStateScript.Type.EVENT, FlowStateScript.Type.LEVEL_UP]:
		_roadside_transition_in_flight = true
		call_deferred("_run_roadside_continuation_transition", new_state, old_state)
		return true
	if new_state not in [FlowStateScript.Type.EVENT, FlowStateScript.Type.LEVEL_UP]:
		_clear_pending_roadside_visual_state()
	return false


func _build_route_move_world_path(
	current_node_id: int,
	target_node_id: int,
	fallback_start_world: Vector2,
	fallback_target_world: Vector2
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var start_world: Vector2 = _get_node_world_position(current_node_id)
	if start_world == Vector2.ZERO:
		start_world = fallback_start_world
	var target_world: Vector2 = _get_node_world_position(target_node_id)
	if target_world == Vector2.ZERO:
		target_world = fallback_target_world
	_append_route_move_world_point(points, start_world)

	var visible_edge_points: PackedVector2Array = _visible_edge_points_for_route(current_node_id, target_node_id)
	for point in visible_edge_points:
		_append_route_move_world_point(points, point)

	_append_route_move_world_point(points, target_world)
	if points.size() >= 2:
		return points
	return PackedVector2Array([start_world, target_world])


func _build_pending_roadside_visual_sample() -> Dictionary:
	if not _has_pending_roadside_visual_state():
		return {}
	var current_node_id: int = int(_roadside_visual_state.get("current_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var target_node_id: int = int(_roadside_visual_state.get("target_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	if current_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID or target_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
		return {}
	var start_world: Vector2 = _get_node_world_position(current_node_id)
	var target_world: Vector2 = _get_node_world_position(target_node_id)
	var route_path: PackedVector2Array = _build_route_move_world_path(
		current_node_id,
		target_node_id,
		start_world,
		target_world
	)
	var route_length: float = _polyline_length(route_path)
	if route_length <= 0.001:
		return {}
	var progress: float = clampf(float(_roadside_visual_state.get("progress", ROADSIDE_INTERRUPTION_PROGRESS)), 0.0, 1.0)
	var sample: Dictionary = _sample_polyline_at_distance(route_path, route_length * progress)
	sample["offset"] = Vector2(_roadside_visual_state.get("offset", _route_layout_offset))
	return sample


func _visible_edge_points_for_route(current_node_id: int, target_node_id: int) -> PackedVector2Array:
	for edge_variant in _board_composition_cache.get("visible_edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = edge_variant
		var from_node_id: int = int(edge.get("from_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		var to_node_id: int = int(edge.get("to_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if from_node_id == current_node_id and to_node_id == target_node_id:
			return edge.get("points", PackedVector2Array())
		if from_node_id == target_node_id and to_node_id == current_node_id:
			var reversed_points := PackedVector2Array()
			var points: PackedVector2Array = edge.get("points", PackedVector2Array())
			for index in range(points.size() - 1, -1, -1):
				reversed_points.append(points[index])
			return reversed_points
	return PackedVector2Array()


func _append_route_move_world_point(points: PackedVector2Array, point: Vector2) -> void:
	if point == Vector2.ZERO:
		return
	if points.is_empty() or points[points.size() - 1].distance_to(point) > 0.5:
		points.append(point)


func _polyline_length(points: PackedVector2Array) -> float:
	if points.size() < 2:
		return 0.0
	var total_length: float = 0.0
	for index in range(points.size() - 1):
		total_length += points[index].distance_to(points[index + 1])
	return total_length


func _sample_route_move_world_state(progress: float) -> Dictionary:
	if _route_move_world_path.size() < 2:
		var fallback_point: Vector2 = _route_move_world_path[0] if not _route_move_world_path.is_empty() else Vector2.ZERO
		return {
			"point": fallback_point,
			"direction": Vector2.RIGHT,
		}

	var travel_distance: float = _route_move_path_length * clampf(progress, 0.0, 1.0)
	var current_sample: Dictionary = _sample_polyline_at_distance(_route_move_world_path, travel_distance)
	var lookahead_distance: float = min(
		_route_move_path_length,
		travel_distance + max(18.0, _route_move_path_length * 0.05)
	)
	var lookahead_sample: Dictionary = _sample_polyline_at_distance(_route_move_world_path, lookahead_distance)
	var direction: Vector2 = Vector2(lookahead_sample.get("point", Vector2.ZERO)) - Vector2(current_sample.get("point", Vector2.ZERO))
	if direction.length_squared() <= 0.001:
		direction = Vector2(current_sample.get("direction", Vector2.RIGHT))
	return {
		"point": current_sample.get("point", Vector2.ZERO),
		"direction": direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT,
	}


func _sample_polyline_at_distance(points: PackedVector2Array, distance: float) -> Dictionary:
	if points.is_empty():
		return {
			"point": Vector2.ZERO,
			"direction": Vector2.RIGHT,
		}
	if points.size() == 1:
		return {
			"point": points[0],
			"direction": Vector2.RIGHT,
		}

	var remaining_distance: float = max(0.0, distance)
	for index in range(points.size() - 1):
		var from_point: Vector2 = points[index]
		var to_point: Vector2 = points[index + 1]
		var segment: Vector2 = to_point - from_point
		var segment_length: float = segment.length()
		if segment_length <= 0.001:
			continue
		if remaining_distance <= segment_length:
			var segment_progress: float = remaining_distance / segment_length
			return {
				"point": from_point.lerp(to_point, segment_progress),
				"direction": segment / segment_length,
			}
		remaining_distance -= segment_length

	var last_segment: Vector2 = points[points.size() - 1] - points[points.size() - 2]
	return {
		"point": points[points.size() - 1],
		"direction": last_segment.normalized() if last_segment.length_squared() > 0.001 else Vector2.RIGHT,
	}


func _prime_roadside_visual_state(current_node_id: int, target_node_id: int) -> void:
	if current_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID or target_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
		_clear_pending_roadside_visual_state()
		return
	var target_world_position: Vector2 = _get_node_world_position(target_node_id)
	var target_offset: Vector2 = _desired_focus_offset_for_world_position(target_world_position)
	var interruption_offset: Vector2 = _route_layout_offset.lerp(
		target_offset,
		_route_camera_follow_progress(ROADSIDE_INTERRUPTION_PROGRESS)
	)
	_roadside_visual_state = {
		"current_node_id": current_node_id,
		"target_node_id": target_node_id,
		"progress": ROADSIDE_INTERRUPTION_PROGRESS,
		"offset": interruption_offset,
		"target_offset": target_offset,
	}


func _clear_pending_roadside_visual_state() -> void:
	_roadside_visual_state = {}
	_roadside_transition_in_flight = false
	if not _route_selection_in_flight:
		_active_route_index = -1


func _has_pending_roadside_visual_state() -> bool:
	return not _roadside_visual_state.is_empty() and int(_roadside_visual_state.get("target_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)) != MapRuntimeStateScript.NO_PENDING_NODE_ID


func _is_roadside_interruption_result(result: Dictionary) -> bool:
	if int(result.get("target_state", -1)) != FlowStateScript.Type.EVENT:
		return false
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return false
	var active_event_state: EventState = bootstrap.get_event_state()
	if active_event_state == null or String(active_event_state.source_context) != "roadside_encounter":
		return false
	var run_state: RunState = _get_run_state()
	if run_state == null or run_state.map_runtime_state == null or not run_state.map_runtime_state.has_pending_node():
		return false
	return int(run_state.map_runtime_state.current_node_id) != int(result.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))


func _run_roadside_continuation_transition(target_state: int, old_state: int) -> void:
	await _play_roadside_continuation_transition(target_state, old_state)


func _play_roadside_continuation_transition(target_state: int, old_state: int) -> void:
	match old_state:
		FlowStateScript.Type.EVENT:
			close_event_overlay(false)
		FlowStateScript.Type.LEVEL_UP:
			close_level_up_overlay(false)
	if is_inside_tree():
		await get_tree().create_timer(ROADSIDE_CONTINUATION_CLOSE_LEAD_IN).timeout
	await _animate_pending_roadside_continuation()
	_clear_pending_roadside_visual_state()
	_refresh_ui()
	var scene_router: Node = get_node_or_null("/root/SceneRouter")
	if scene_router != null:
		scene_router.call_deferred("route_to_state_for_restore", target_state)


func _animate_pending_roadside_continuation() -> void:
	if not _has_pending_roadside_visual_state():
		return
	var current_node_id: int = int(_roadside_visual_state.get("current_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var target_node_id: int = int(_roadside_visual_state.get("target_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	if current_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID or target_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
		return
	var target_offset: Vector2 = Vector2(_roadside_visual_state.get("target_offset", _route_layout_offset))
	await _animate_route_move_camera_follow_segment(
		current_node_id,
		target_node_id,
		target_offset,
		float(_roadside_visual_state.get("progress", ROADSIDE_INTERRUPTION_PROGRESS)),
		1.0
	)
	_stop_walker_walk_cycle()
	_set_walker_texture(MAP_WALKER_IDLE_TEXTURE)
	_reset_walker_stride_visuals()
	if is_inside_tree():
		await get_tree().create_timer(WALKER_ARRIVAL_PAUSE).timeout


func _resolve_route_move_stride_cycles(path_length: float) -> float:
	return clampf(path_length / WALKER_STRIDE_PIXELS_PER_CYCLE, 1.0, 4.25)


func _resolve_walker_frame_interval(path_length: float, move_duration: float) -> float:
	if path_length <= 0.0 or move_duration <= 0.0:
		return WALKER_FRAME_INTERVAL_MAX
	var travel_speed: float = path_length / move_duration
	return clampf(44.0 / max(1.0, travel_speed), WALKER_FRAME_INTERVAL_MIN, WALKER_FRAME_INTERVAL_MAX)


func _walker_stride_offset(progress: float) -> Vector2:
	if _route_move_path_length <= 0.0:
		return Vector2.ZERO
	var stride_envelope: float = sin(clampf(progress, 0.0, 1.0) * PI)
	if stride_envelope <= 0.0:
		return Vector2.ZERO
	var bob_wave: float = absf(sin(clampf(progress, 0.0, 1.0) * TAU * _route_move_stride_cycles))
	var bob_amplitude: float = min(
		WALKER_STRIDE_BOB_MAX,
		WALKER_STRIDE_BOB_MAX * clampf(_route_move_path_length / 220.0, 0.45, 1.0)
	)
	return Vector2(0.0, -bob_wave * bob_amplitude * stride_envelope)


func _apply_walker_stride_visuals(stride_offset: Vector2) -> void:
	if _walker_shadow == null:
		return
	var lift_strength: float = clampf(absf(stride_offset.y) / max(0.001, WALKER_STRIDE_BOB_MAX), 0.0, 1.0)
	_walker_shadow.scale = Vector2(1.0 - lift_strength * 0.16, 1.0 - lift_strength * 0.22)
	_walker_shadow.modulate = Color(1, 1, 1, 1.0 - lift_strength * 0.24)


func _reset_walker_stride_visuals() -> void:
	if _walker_shadow != null:
		_walker_shadow.scale = Vector2.ONE
		_walker_shadow.modulate = Color.WHITE


func _ease_in_out_sine(value: float) -> float:
	var clamped_value: float = clampf(value, 0.0, 1.0)
	return 0.5 - (cos(clamped_value * PI) * 0.5)


func _get_current_marker_center() -> Vector2:
	if _current_marker == null:
		return Vector2.ZERO
	return _current_marker.position + (_current_marker.size * 0.5)


func _get_route_marker_center(index: int) -> Vector2:
	if index < 0 or index >= ROUTE_MARKER_NODE_NAMES.size():
		return Vector2.ZERO
	var marker_rect: TextureRect = get_node_or_null("%s/%s" % [ROUTE_GRID_PATH, ROUTE_MARKER_NODE_NAMES[index]]) as TextureRect
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

	var texture: Texture2D = SceneLayoutHelperScript.load_texture_or_null(asset_path)
	texture_rect.texture = texture
	texture_rect.visible = texture != null


func _apply_temp_theme() -> void:
	MapExploreSceneUiScript.apply_temp_theme(self)


func _style_route_buttons_for_overlay_mode() -> void:
	var route_grid: Control = get_node_or_null(ROUTE_GRID_PATH) as Control
	MapExploreSceneUiScript.style_route_buttons_for_overlay_mode(route_grid, ROUTE_BUTTON_NODE_NAMES)


func _apply_text_density_pass() -> void:
	MapExploreSceneUiScript.apply_text_density_pass(self)


func _on_route_grid_resized() -> void:
	if _route_selection_in_flight:
		return
	_refresh_ui_pending = true
	call_deferred("_consume_pending_refresh_ui")
	_position_active_overlays()


func _consume_pending_refresh_ui() -> void:
	if _is_refreshing_ui:
		call_deferred("_consume_pending_refresh_ui")
		return
	if not _refresh_ui_pending:
		return
	_refresh_ui_pending = false
	_refresh_ui()


func _on_viewport_size_changed() -> void:
	_apply_portrait_safe_layout()
	call_deferred("_refresh_safe_menu_anchor_layout")
	_refresh_hovered_inventory_tooltip()
	_position_hunger_warning_toast()
	_position_active_overlays()


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


func _position_active_overlays() -> void:
	if _overlay_lifecycle != null:
		_overlay_lifecycle.position_overlays(OVERLAY_KEYS)


func open_event_overlay() -> void:
	if _overlay_lifecycle != null:
		_overlay_lifecycle.open_overlay("event", EventSceneScript, "EventOverlay", "Event")


func close_event_overlay(immediate: bool = false) -> void:
	if _overlay_lifecycle != null:
		_overlay_lifecycle.close_overlay("event", immediate)


func open_support_overlay() -> void:
	if _overlay_lifecycle != null:
		_overlay_lifecycle.open_overlay("support", SupportInteractionSceneScript, "SupportOverlay", "Support interaction")


func close_support_overlay(immediate: bool = false) -> void:
	if _overlay_lifecycle != null:
		_overlay_lifecycle.close_overlay("support", immediate)


func open_reward_overlay() -> void:
	if _overlay_lifecycle != null:
		_overlay_lifecycle.open_overlay("reward", RewardSceneScript, "RewardOverlay", "Reward")


func close_reward_overlay(immediate: bool = false) -> void:
	if _overlay_lifecycle != null:
		_overlay_lifecycle.close_overlay("reward", immediate)


func open_level_up_overlay() -> void:
	if _overlay_lifecycle != null:
		_overlay_lifecycle.open_overlay("level_up", LevelUpSceneScript, "LevelUpOverlay", "Level up")


func close_level_up_overlay(immediate: bool = false) -> void:
	if _overlay_lifecycle != null:
		_overlay_lifecycle.close_overlay("level_up", immediate)


func _tune_event_overlay_visuals(event_overlay: Control) -> void:
	if event_overlay == null or not is_instance_valid(event_overlay):
		return
	var event_state = event_overlay.get("_event_state")
	var roadside_overlay: bool = event_state != null and String(event_state.source_context) == "roadside_encounter"

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
		var scrim_alpha: float = EVENT_OVERLAY_ROADSIDE_SCRIM_ALPHA if roadside_overlay else EVENT_OVERLAY_SCRIM_ALPHA
		scrim.color = Color(scrim.color.r, scrim.color.g, scrim.color.b, scrim_alpha)


func _apply_portrait_safe_layout() -> void:
	MapExploreSceneUiScript.apply_portrait_safe_layout(self, PORTRAIT_SAFE_MAX_WIDTH, PORTRAIT_SAFE_MIN_SIDE_MARGIN)


func _setup_safe_menu() -> void:
	_safe_menu = RunMenuSceneHelperScript.ensure_safe_menu(self, _safe_menu, "Settings", "Save, load, return to menu, mute music, or quit.", "Settings", Callable(self, "_on_save_run_pressed"), Callable(self, "_on_load_run_pressed"), Callable(self, "_on_return_to_main_menu_pressed"))
	_refresh_safe_menu_anchor_layout()


func _refresh_safe_menu_anchor_layout() -> void:
	if _safe_menu != null and _safe_menu.has_method("set_launcher_corner"):
		_safe_menu.set_launcher_corner("top_right")
	if _safe_menu != null and _safe_menu.has_method("set_launcher_alignment_target"):
		var settings_anchor: Control = get_node_or_null(SETTINGS_MENU_ANCHOR_PATH) as Control
		if settings_anchor == null:
			settings_anchor = get_node_or_null(TOP_ROW_PATH)
		if settings_anchor != null:
			_safe_menu.set_launcher_alignment_target(settings_anchor)


func _ensure_hunger_warning_toast() -> void:
	if _hunger_warning_toast == null:
		_hunger_warning_toast = HungerWarningToastScript.new()
	_hunger_warning_toast.setup(self, TOP_ROW_PATH, 130)


func _on_hunger_threshold_crossed(_old_threshold: int, new_threshold: int) -> void:
	var warning_text: String = RunStatusStripScript.build_hunger_threshold_warning_text(new_threshold)
	if warning_text.is_empty():
		return
	_show_hunger_warning(warning_text, new_threshold)


func _show_hunger_warning(warning_text: String, threshold: int) -> void:
	_ensure_hunger_warning_toast()
	if _hunger_warning_toast == null:
		return
	_hunger_warning_toast.show_warning(warning_text, threshold)


func _position_hunger_warning_toast() -> void:
	if _hunger_warning_toast == null:
		return
	_hunger_warning_toast.position_toast()


func _finish_hiding_hunger_warning() -> void:
	if _hunger_warning_toast == null:
		return
	_hunger_warning_toast.finish_hide()

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
