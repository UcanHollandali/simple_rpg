# Layer: Scenes - presentation only
extends Control

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const RunSessionCoordinatorScript = preload("res://Game/Application/run_session_coordinator.gd")
const MapExplorePresenterScript = preload("res://Game/UI/map_explore_presenter.gd")
const MapQuestLogPanelScript = preload("res://Game/UI/map_quest_log_panel.gd")
const RunInventoryPanelScript = preload("res://Game/UI/run_inventory_panel.gd")
const MapOverlayDirectorScript = preload("res://Game/UI/map_overlay_director.gd")
const MapRouteBindingScript = preload("res://Game/UI/map_route_binding.gd")
const MapBoardComposerV2Script = preload("res://Game/UI/map_board_composer_v2.gd")
const MapExploreSceneUiScript = preload("res://Game/UI/map_explore_scene_ui.gd")
const RunStatusStripScript = preload("res://Game/UI/run_status_strip.gd")
const InventoryOverflowPromptScript = preload("res://Game/UI/inventory_overflow_prompt.gd")
const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const MapRouteMotionHelperScript = preload("res://Game/UI/map_route_motion_helper.gd")
const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")
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
const AUDIO_PLAYER_CONFIG := {
	"NodeSelectSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_node_select_01.ogg"},
	"MapMusicPlayer": {"path": "res://Assets/Audio/Music/music_ui_hub_loop_proto_01.ogg", "music": true, "loop": true},
}
const INVENTORY_DRAG_THRESHOLD := 14.0
const PORTRAIT_SAFE_MAX_WIDTH := 1120
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 14
const TOP_ROW_PATH := "Margin/VBox/TopRow"
const HEADER_STACK_PATH := "Margin/VBox/TopRow/HeaderCard/HeaderRow/HeaderStack"
const STAGE_BADGE_LABEL_PATH := "Margin/VBox/TopRow/HeaderCard/HeaderRow/StageBadge/StageBadgeLabel"
const RUN_SUMMARY_CARD_PATH := "Margin/VBox/TopRow/RunSummaryCard"
const SETTINGS_MENU_ANCHOR_PATH := "Margin/VBox/TopRow/SettingsMenuAnchor"
const WALKER_ARRIVAL_PAUSE := 0.08
const ROADSIDE_CONTINUATION_CLOSE_LEAD_IN := 0.14
const ROADSIDE_CONTINUATION_RESUME_STATES := [FlowStateScript.Type.MAP_EXPLORE, FlowStateScript.Type.NODE_RESOLVE, FlowStateScript.Type.COMBAT, FlowStateScript.Type.REWARD, FlowStateScript.Type.SUPPORT_INTERACTION]
const MAP_INVENTORY_DRAWER_TITLE := "Inventory + Equipment"

var _status_lines: PackedStringArray = []
var _presenter: RefCounted
var _run_inventory_panel: RunInventoryPanel
var _board_composer: RefCounted
var _route_binding: MapRouteBinding
var _route_layout_offset: Vector2 = Vector2.ZERO
var _board_composition_cache: Dictionary = {}
var _route_models_cache: Array[Dictionary] = []
var _roadside_visual_state: Dictionary = {}
var _roadside_transition_in_flight: bool = false
var _safe_menu: SafeMenuOverlay
var _overlay_director: MapOverlayDirector
var _overflow_prompt: InventoryOverflowPrompt
var _pending_overflow_slot_id: int = -1
var _is_refreshing_ui: bool = false
var _refresh_ui_pending: bool = false
var _map_inventory_drawer_expanded: bool = false
var _run_status_model_signature: String = ""
var _run_status_strip: RunStatusStrip
var _hunger_warning_toast: HungerWarningToast
var _scene_node_cache: Dictionary = {}
var _inventory_drawer_card: PanelContainer
var _inventory_drawer_title_label: Label
var _inventory_drawer_summary_label: Label
var _inventory_drawer_toggle_button: Button
var _quest_log_panel: MapQuestLogPanel
var _first_run_hint_controller: FirstRunHintController

@onready var _header_title_label: Label = _scene_node("%s/TitleLabel" % HEADER_STACK_PATH) as Label
@onready var _stage_badge_label: Label = _scene_node(STAGE_BADGE_LABEL_PATH) as Label
@onready var _progress_label: Label = _scene_node("%s/ProgressLabel" % HEADER_STACK_PATH) as Label
@onready var _route_read_label: Label = _scene_node("%s/RouteReadLabel" % HEADER_STACK_PATH) as Label
@onready var _run_summary_card: PanelContainer = _scene_node(RUN_SUMMARY_CARD_PATH) as PanelContainer
@onready var _run_status_label: Label = _scene_node("%s/RunStatusLabel" % RUN_SUMMARY_CARD_PATH) as Label
@onready var _current_anchor_label: Label = _scene_node("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorLabel") as Label
@onready var _current_anchor_detail_label: Label = _scene_node("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorDetailLabel") as Label
@onready var _current_anchor_hint_label: Label = _scene_node("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorHintLabel") as Label
@onready var _status_label: Label = _scene_node("Margin/VBox/BottomRow/StatusCard/StatusLabel") as Label
@onready var _status_card: Control = _scene_node("Margin/VBox/BottomRow/StatusCard") as Control
@onready var _equipment_panel: PanelContainer = _scene_node("Margin/VBox/InventorySection/EquipmentCard") as PanelContainer
@onready var _equipment_container: Container = _scene_node("Margin/VBox/InventorySection/EquipmentCard/EquipmentCardsFlow") as Container
@onready var _backpack_panel: PanelContainer = _scene_node("Margin/VBox/InventorySection/InventoryCard") as PanelContainer
@onready var _backpack_container: Container = _scene_node("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow") as Container
@onready var _equipment_title_label: Label = _scene_node("Margin/VBox/InventorySection/EquipmentTitleLabel") as Label
@onready var _equipment_hint_label: Label = _scene_node("Margin/VBox/InventorySection/EquipmentHintLabel") as Label
@onready var _inventory_title_label: Label = _scene_node("Margin/VBox/InventorySection/InventoryTitleLabel") as Label
@onready var _inventory_hint_label: Label = _scene_node("Margin/VBox/InventorySection/InventoryHintLabel") as Label
@onready var _inventory_section: VBoxContainer = _scene_node("Margin/VBox/InventorySection") as VBoxContainer

func _ready() -> void:
	_scene_node_cache.clear()
	_presenter = MapExplorePresenterScript.new()
	_board_composer = MapBoardComposerV2Script.new()
	_route_binding = MapRouteBindingScript.new()
	_route_binding.configure(self, Callable(self, "_scene_node"), _board_composer)
	var drawer_nodes: Dictionary = MapExploreSceneUiScript.ensure_inventory_drawer_controls(self)
	_inventory_drawer_card = drawer_nodes.get("drawer_card", null) as PanelContainer
	_inventory_drawer_title_label = drawer_nodes.get("title_label", null) as Label
	_inventory_drawer_summary_label = drawer_nodes.get("summary_label", null) as Label
	_inventory_drawer_toggle_button = drawer_nodes.get("toggle_button", null) as Button
	if _inventory_drawer_toggle_button != null:
		var toggle_handler := Callable(self, "_on_inventory_drawer_toggle_pressed")
		if not _inventory_drawer_toggle_button.is_connected("pressed", toggle_handler):
			_inventory_drawer_toggle_button.pressed.connect(toggle_handler)
	_run_status_strip = RunStatusStripScript.new()
	if _run_status_strip != null and not _run_status_strip.is_connected("hunger_threshold_crossed", Callable(self, "_on_hunger_threshold_crossed")):
		_run_status_strip.connect("hunger_threshold_crossed", Callable(self, "_on_hunger_threshold_crossed"))
	_run_inventory_panel = RunInventoryPanelScript.new()
	_run_inventory_panel.configure(self, {
		"equipment_container": _equipment_container,
		"backpack_container": _backpack_container,
		"equipment_panel": _equipment_panel,
		"backpack_panel": _backpack_panel,
		"equipment_title_label": _equipment_title_label,
		"equipment_hint_label": _equipment_hint_label,
		"inventory_title_label": _inventory_title_label,
		"inventory_hint_label": _inventory_hint_label,
		"drawer_card": _inventory_drawer_card,
		"drawer_title_label": _inventory_drawer_title_label,
		"drawer_summary_label": _inventory_drawer_summary_label,
		"drawer_toggle_button": _inventory_drawer_toggle_button,
		"click_handler": Callable(self, "_handle_inventory_card_click"),
		"drag_complete_handler": Callable(self, "_handle_inventory_card_drag_completed"),
		"drag_threshold": INVENTORY_DRAG_THRESHOLD,
		"enable_tooltip": true,
	})
	_run_inventory_panel.set_interaction_mode("map")
	_overlay_director = MapOverlayDirectorScript.new()
	_overlay_director.configure(self, {
		"event_scene": EventSceneScript,
		"support_scene": SupportInteractionSceneScript,
		"reward_scene": RewardSceneScript,
		"level_up_scene": LevelUpSceneScript,
	})
	_route_binding.connect_buttons(Callable(self, "_on_route_button_pressed"))
	_route_binding.apply_static_map_textures()
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	_route_binding.ensure_runtime_board_nodes()
	_setup_overflow_prompt()
	_apply_temp_theme()
	_prime_inventory_drawer_preview()
	_ensure_hunger_warning_toast()
	_route_binding.style_route_buttons_for_overlay_mode()
	_apply_text_density_pass()
	SceneLayoutHelperScript.bind_viewport_size_changed(self, Callable(self, "_on_viewport_size_changed"))
	_apply_portrait_safe_layout()
	_quest_log_panel = MapQuestLogPanelScript.new()
	_quest_log_panel.configure(self, Callable(self, "_before_quest_log_toggle"))
	_setup_safe_menu()
	SceneAudioPlayersScript.start_looping(self, "MapMusicPlayer")

	var route_grid: Control = _route_binding.get_route_grid() if _route_binding != null else null
	if route_grid != null:
		var resized_handler := Callable(self, "_on_route_grid_resized")
		if not route_grid.is_connected("resized", resized_handler):
			route_grid.connect("resized", resized_handler)

	var bootstrap = _get_app_bootstrap()
	if bootstrap != null:
		bootstrap.ensure_run_state_initialized()
	_setup_first_run_hint_controller()

	call_deferred("_sync_overlays_with_flow_state")
	call_deferred("_refresh_ui")


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
	if _route_binding != null:
		_route_binding.stop_walker_walk_cycle()
	if _hunger_warning_toast != null:
		_hunger_warning_toast.release()
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_on_viewport_size_changed"))
	_release_first_run_hint_controller_host()
	if _run_inventory_panel != null:
		_run_inventory_panel.release()
	if _overlay_director != null:
		_overlay_director.close_all(true)
	SceneAudioCleanupScript.release_players(self, SceneAudioPlayersScript.node_names_from_config(AUDIO_PLAYER_CONFIG))


func _input(event: InputEvent) -> void:
	if _run_inventory_panel == null:
		return
	_run_inventory_panel.handle_root_input(event)


func _on_route_button_pressed(button_node_name: String) -> void:
	if _route_binding == null or _route_binding.is_selection_in_flight():
		return
	var target_node_id: int = _route_binding.resolve_target_node_id(button_node_name)
	if target_node_id < 0:
		return
	var selection_end_progress: float = MapRouteBindingScript.ROADSIDE_INTERRUPTION_PROGRESS if _would_open_roadside_encounter_preview(target_node_id) else 1.0
	_route_binding.begin_selection()
	SceneAudioPlayersScript.play(self, "NodeSelectSfxPlayer")
	await _route_binding.animate_route_selection(
		button_node_name,
		target_node_id,
		Callable(self, "_move_to_node"),
		selection_end_progress
	)
	var run_state: RunState = _get_run_state()
	_route_binding.finish_selection_and_render(run_state)

func _would_open_roadside_encounter_preview(target_node_id: int) -> bool:
	var run_state: RunState = _get_run_state()
	if run_state == null or run_state.map_runtime_state == null:
		return false
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	if not map_runtime_state.can_move_to_node(target_node_id):
		return false
	var predicted_hunger: int = max(0, run_state.hunger - RunSessionCoordinatorScript.MAP_MOVE_HUNGER_COST)
	var predicted_player_hp: int = run_state.player_hp
	if predicted_hunger == 0:
		predicted_player_hp = max(0, predicted_player_hp - 1)
	if predicted_player_hp <= 0:
		return false
	var target_node_type: String = map_runtime_state.get_node_family(target_node_id)
	var target_node_state: String = map_runtime_state.get_node_state(target_node_id)
	if target_node_state != MapRuntimeStateScript.NODE_STATE_DISCOVERED:
		return false
	if not map_runtime_state.get_active_side_quest_by_target_node_id(target_node_id).is_empty():
		return false
	if target_node_type in RunSessionCoordinatorScript.ROADSIDE_ENCOUNTER_EXCLUDED_FAMILIES:
		return false
	if not _has_eligible_roadside_template_preview(run_state, target_node_id, predicted_hunger, predicted_player_hp):
		return false
	var draw_index: int = max(0, int(run_state.rng_stream_states.get(RunSessionCoordinatorScript.ROADSIDE_ENCOUNTER_STREAM_NAME, 0)))
	var context_salt: String = "%s|from:%d|to:%d|stage:%d" % [
		target_node_type,
		int(map_runtime_state.current_node_id),
		target_node_id,
		run_state.stage_index,
	]
	var roadside_rng := RandomNumberGenerator.new()
	roadside_rng.seed = int(run_state._build_stream_seed(
		RunSessionCoordinatorScript.ROADSIDE_ENCOUNTER_STREAM_NAME,
		draw_index,
		context_salt
	))
	return roadside_rng.randf() < RunSessionCoordinatorScript.ROADSIDE_ENCOUNTER_TRIGGER_CHANCE


func _has_eligible_roadside_template_preview(
	run_state: RunState,
	target_node_id: int,
	predicted_hunger: int,
	predicted_player_hp: int
) -> bool:
	if run_state == null:
		return false
	var preview_event_state: EventStateScript = EventStateScript.new()
	preview_event_state.setup_for_node(
		target_node_id,
		run_state.stage_index,
		EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER,
		run_state.run_seed,
		_build_roadside_trigger_context_preview(run_state, predicted_hunger, predicted_player_hp)
	)
	return not preview_event_state.choices.is_empty()


func _build_roadside_trigger_context_preview(
	run_state: RunState,
	predicted_hunger: int,
	predicted_player_hp: int
) -> Dictionary:
	if run_state == null:
		return {}
	var max_hp: int = max(1, RunState.DEFAULT_PLAYER_HP)
	var hp_percent: float = (float(predicted_player_hp) / float(max_hp)) * 100.0
	return {
		EventStateScript.TRIGGER_STAT_HUNGER: predicted_hunger,
		EventStateScript.TRIGGER_STAT_HP_PERCENT: hp_percent,
		EventStateScript.TRIGGER_STAT_GOLD: run_state.gold,
	}


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
		_clear_pending_roadside_visual_bridge()
		_append_status_line("Move failed: %s" % String(result.get("error", "unknown")))
		_refresh_ui()
		return

	var node_type: String = String(result.get("node_type", "node"))
	var node_state: String = String(result.get("node_state", ""))
	var target_state: int = int(result.get("target_state", FlowState.Type.MAP_EXPLORE))
	if _is_roadside_interruption_result(result):
		var run_state: RunState = _get_run_state()
		if run_state != null and run_state.map_runtime_state != null:
			_prime_pending_roadside_visual_bridge(
				int(run_state.map_runtime_state.current_node_id),
				int(result.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
			)
		_append_status_line("Roadside stop before the node.")
	else:
		_clear_pending_roadside_visual_bridge()
	if target_state == FlowState.Type.NODE_RESOLVE:
		_append_status_line("Entered %s node. Hunger: %d" % [node_type, int(result.get("hunger", 0))])
	elif target_state == FlowState.Type.COMBAT:
		_append_status_line("Entered %s combat. Hunger: %d" % [node_type, int(result.get("hunger", 0))])
	else:
		_append_status_line("Traversed to %s (%s). Hunger: %d" % [node_type, node_state, int(result.get("hunger", 0))])
	_refresh_ui()


func _refresh_ui() -> void:
	if _is_refreshing_ui:
		_queue_refresh_ui()
		return
	_is_refreshing_ui = true

	var run_state: RunState = _get_run_state()
	if run_state == null:
		_is_refreshing_ui = false
		return
	if _route_binding != null:
		_route_binding.set_route_models(_presenter.build_route_view_models(run_state, MapRouteBindingScript.ROUTE_BUTTON_NODE_NAMES.size()))
		_route_binding.prepare_for_refresh(run_state)

	_refresh_inventory_cards(run_state)

	var title_label: Label = _header_title_label if _header_title_label != null and is_instance_valid(_header_title_label) else _scene_node("%s/TitleLabel" % HEADER_STACK_PATH) as Label
	if title_label != null:
		title_label.text = _presenter.build_title_text(run_state)
	var stage_badge_label: Label = _stage_badge_label if _stage_badge_label != null and is_instance_valid(_stage_badge_label) else _scene_node(STAGE_BADGE_LABEL_PATH) as Label
	if stage_badge_label != null:
		stage_badge_label.text = _presenter.build_stage_badge_text(run_state)

	var progress_label: Label = _progress_label if _progress_label != null and is_instance_valid(_progress_label) else _scene_node("%s/ProgressLabel" % HEADER_STACK_PATH) as Label
	if progress_label != null:
		progress_label.text = _presenter.build_progress_text(run_state)
	var route_read_label: Label = _route_read_label if _route_read_label != null and is_instance_valid(_route_read_label) else _scene_node("%s/RouteReadLabel" % HEADER_STACK_PATH) as Label
	if route_read_label != null:
		route_read_label.text = _presenter.build_route_overview_text(run_state)
		route_read_label.visible = not route_read_label.text.is_empty()
	var run_summary_card: PanelContainer = _run_summary_card if _run_summary_card != null and is_instance_valid(_run_summary_card) else _scene_node(RUN_SUMMARY_CARD_PATH) as PanelContainer
	var run_status_label: Label = _run_status_label if _run_status_label != null and is_instance_valid(_run_status_label) else _scene_node("%s/RunStatusLabel" % RUN_SUMMARY_CARD_PATH) as Label
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

	var focused_node_id: int = _route_binding.resolve_focused_node_id(run_state) if _route_binding != null else MapRuntimeStateScript.NO_PENDING_NODE_ID
	var focus_model: Dictionary = _presenter.build_focus_panel_model(run_state, focused_node_id)
	var current_anchor_label: Label = _current_anchor_label if _current_anchor_label != null and is_instance_valid(_current_anchor_label) else _scene_node("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorLabel") as Label
	if current_anchor_label != null:
		current_anchor_label.text = String(focus_model.get("title_text", ""))

	var current_anchor_detail_label: Label = _current_anchor_detail_label if _current_anchor_detail_label != null and is_instance_valid(_current_anchor_detail_label) else _scene_node("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorDetailLabel") as Label
	if current_anchor_detail_label != null:
		current_anchor_detail_label.text = String(focus_model.get("detail_text", ""))

	var current_anchor_hint_label: Label = _current_anchor_hint_label if _current_anchor_hint_label != null and is_instance_valid(_current_anchor_hint_label) else _scene_node("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorHintLabel") as Label
	if current_anchor_hint_label != null:
		current_anchor_hint_label.text = String(focus_model.get("hint_text", ""))
		current_anchor_hint_label.visible = not current_anchor_hint_label.text.is_empty()

	var status_label: Label = _status_label if _status_label != null and is_instance_valid(_status_label) else _scene_node("Margin/VBox/BottomRow/StatusCard/StatusLabel") as Label
	var has_status_history: bool = not _status_lines.is_empty()
	if status_label != null:
		status_label.text = _presenter.build_status_log_text(_status_lines, run_state) if has_status_history else ""
		status_label.visible = not status_label.text.is_empty()
	var status_card: Control = _status_card if _status_card != null and is_instance_valid(_status_card) else _scene_node("Margin/VBox/BottomRow/StatusCard") as Control
	if status_card != null and status_label != null:
		status_card.visible = status_label.visible

	if _quest_log_panel != null:
		_quest_log_panel.apply_model(_presenter.build_quest_log_model(run_state))

	if _safe_menu != null:
		var bootstrap = _get_app_bootstrap()
		RunMenuSceneHelperScript.sync_load_available(_safe_menu, bootstrap)
		RunMenuSceneHelperScript.sync_tutorial_hints_available(_safe_menu, _first_run_hint_controller)
		_sync_safe_menu_launcher_visibility()

	if _route_binding == null or not _route_binding.is_selection_in_flight():
		_apply_portrait_safe_layout()
	if _route_binding != null:
		_route_binding.render(run_state)
	_request_first_contextual_map_hints(run_state)

	_is_refreshing_ui = false
	if _refresh_ui_pending:
		_schedule_refresh_ui_consume()


func _append_status_line(line: String) -> void:
	_status_lines.append(line)
	if _status_lines.size() > 6:
		_status_lines.remove_at(0)


func _refresh_inventory_cards(run_state: RunState) -> void:
	if _run_inventory_panel == null:
		return
	var inventory_presenter: InventoryPresenter = _run_inventory_panel.get_presenter()
	if inventory_presenter == null:
		return
	var pressure_text: String = _presenter.build_inventory_pressure_text(run_state)
	_run_inventory_panel.render({
		"drawer_enabled": true,
		"drawer_expanded": _map_inventory_drawer_expanded,
		"drawer_title": MAP_INVENTORY_DRAWER_TITLE,
		"drawer_summary": inventory_presenter.build_inventory_drawer_summary_text(run_state.inventory_state if run_state != null else null),
		"drawer_toggle_text": "Hide Cards" if _map_inventory_drawer_expanded else "Show Cards",
		"equipment_title": inventory_presenter.build_equipment_title_text(),
		"equipment_hint": inventory_presenter.build_equipment_hint_text(false),
		"equipment_hint_visible": true,
		"inventory_title": inventory_presenter.build_inventory_title_text(run_state.inventory_state if run_state != null else null),
		"inventory_hint": pressure_text if not pressure_text.is_empty() else inventory_presenter.build_run_inventory_hint_text(run_state.inventory_state if run_state != null else null),
		"inventory_hint_visible": (not pressure_text.is_empty() or not inventory_presenter.build_run_inventory_hint_text(run_state.inventory_state if run_state != null else null).is_empty()) and get_viewport_rect().size.y >= 2000.0,
		"equipment_cards": inventory_presenter.build_run_equipment_cards(run_state),
		"backpack_cards": inventory_presenter.build_run_inventory_cards(run_state),
		"clickable_resolver": Callable(self, "_inventory_card_is_clickable"),
		"draggable_resolver": Callable(self, "_inventory_card_is_draggable"),
	})
	_scan_first_run_inventory_hints(run_state)

func _inventory_card_is_clickable(card_model: Dictionary) -> bool:
	var card_family: String = String(card_model.get("card_family", ""))
	return card_family in ["weapon", "shield", "armor", "belt", "consumable", "shield_attachment"]


func _inventory_card_is_draggable(card_model: Dictionary) -> bool:
	return String(card_model.get("card_family", "")) != "empty" and int(card_model.get("inventory_slot_index", -1)) >= 0


func _handle_inventory_card_click(_slot_index: int, slot_id: int, card_family: String) -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return

	match card_family:
		"weapon", "shield", "armor", "belt", "shield_attachment":
			var toggle_result: Dictionary = bootstrap.toggle_inventory_equipment(slot_id)
			if not bool(toggle_result.get("ok", false)):
				if String(toggle_result.get("error", "")) == "inventory_choice_required":
					_present_inventory_overflow_prompt(slot_id, toggle_result)
					return
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


func _handle_inventory_card_drag_completed(slot_id: int, target_index: int) -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return
	var move_result: Dictionary = bootstrap.move_inventory_slot(slot_id, target_index)
	if not bool(move_result.get("ok", false)):
		_append_status_line(_build_inventory_failure_text(move_result))
		return
	_refresh_ui()


func _on_inventory_drawer_toggle_pressed() -> void:
	_map_inventory_drawer_expanded = not _map_inventory_drawer_expanded
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


func _get_app_bootstrap() -> AppBootstrapScript:
	return (_scene_node("/root/AppBootstrap") as AppBootstrapScript) if is_inside_tree() else null


func _setup_first_run_hint_controller() -> void:
	_first_run_hint_controller = _resolve_first_run_hint_controller()
	if _first_run_hint_controller == null:
		return
	_first_run_hint_controller.setup(self, TOP_ROW_PATH, 140)
	RunMenuSceneHelperScript.sync_tutorial_hints_available(_safe_menu, _first_run_hint_controller)


func _release_first_run_hint_controller_host() -> void:
	if _first_run_hint_controller == null:
		return
	_first_run_hint_controller.release_host(self)
	_first_run_hint_controller = null
	RunMenuSceneHelperScript.sync_tutorial_hints_available(_safe_menu, _first_run_hint_controller)


func _request_first_run_hint(hint_id: String) -> void:
	_setup_first_run_hint_controller()
	if _first_run_hint_controller == null:
		return
	_first_run_hint_controller.request_hint(hint_id)


func _scan_first_run_inventory_hints(run_state: RunState) -> void:
	_setup_first_run_hint_controller()
	if _first_run_hint_controller == null or run_state == null:
		return
	_first_run_hint_controller.scan_inventory_hints(run_state.inventory_state)


func _resolve_first_run_hint_controller() -> FirstRunHintController:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return null
	bootstrap.ensure_run_state_initialized()
	var coordinator: RefCounted = bootstrap.run_session_coordinator
	if coordinator == null:
		return null
	return coordinator.get("_first_run_hint_controller") as FirstRunHintController

func _on_disable_tutorial_hints_pressed() -> void:
	_setup_first_run_hint_controller()
	if _first_run_hint_controller == null:
		return
	var changed: bool = _first_run_hint_controller.mark_all_hints_shown()
	RunMenuSceneHelperScript.sync_tutorial_hints_available(_safe_menu, _first_run_hint_controller)
	if _safe_menu != null:
		_safe_menu.set_status_text(RunMenuSceneHelperScript.build_tutorial_hints_status_text(changed))


func _setup_overflow_prompt() -> void:
	_overflow_prompt = InventoryOverflowPromptScript.new()
	_overflow_prompt.name = "InventoryOverflowPrompt"
	_overflow_prompt.configure(TempScreenThemeScript.TEAL_ACCENT_COLOR)
	add_child(_overflow_prompt)
	_overflow_prompt.discard_requested.connect(_on_overflow_discard_requested)
	_overflow_prompt.leave_requested.connect(_on_overflow_leave_requested)


func _present_inventory_overflow_prompt(slot_id: int, prompt_result: Dictionary) -> void:
	_pending_overflow_slot_id = slot_id
	if _overflow_prompt == null:
		return
	_overflow_prompt.present(prompt_result, "Keep Equipped")


func _clear_overflow_prompt() -> void:
	_pending_overflow_slot_id = -1
	if _overflow_prompt != null:
		_overflow_prompt.dismiss()


func _on_overflow_discard_requested(discard_slot_id: int) -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null or _pending_overflow_slot_id <= 0:
		return
	var result: Dictionary = bootstrap.toggle_inventory_equipment(_pending_overflow_slot_id, discard_slot_id)
	_clear_overflow_prompt()
	if bool(result.get("ok", false)):
		_append_status_line(_build_inventory_toggle_result_text(result))
	else:
		_append_status_line(_build_inventory_failure_text(result))
	_refresh_ui()


func _on_overflow_leave_requested() -> void:
	_clear_overflow_prompt()


func _get_run_state() -> RunState:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.get_run_state()


func _schedule_refresh_ui_consume() -> void:
	call_deferred("_consume_pending_refresh_ui")


func _queue_refresh_ui() -> void:
	_refresh_ui_pending = true
	_schedule_refresh_ui_consume()


func _is_roadside_transition_in_flight() -> bool:
	return _route_binding.is_roadside_transition_in_flight() if _route_binding != null else _roadside_transition_in_flight


func _set_roadside_transition_in_flight(value: bool) -> void:
	if _route_binding != null:
		_route_binding.set_roadside_transition_in_flight(value)
	else:
		_roadside_transition_in_flight = value


func _has_pending_roadside_visual_bridge() -> bool:
	return _route_binding.has_pending_roadside_visual_state() if _route_binding != null else _has_pending_roadside_visual_state()


func _prime_pending_roadside_visual_bridge(current_node_id: int, target_node_id: int) -> void:
	if _route_binding != null:
		_route_binding.prime_roadside_visual_state(current_node_id, target_node_id)
	else:
		_prime_roadside_visual_state(current_node_id, target_node_id)


func _clear_pending_roadside_visual_bridge() -> void:
	if _route_binding != null:
		_route_binding.clear_pending_roadside_visual_state()
	else:
		_clear_pending_roadside_visual_state()


func _close_roadside_source_overlay(old_state: int) -> void:
	match old_state:
		FlowStateScript.Type.EVENT:
			close_overlay_for_state(FlowStateScript.Type.EVENT, false)
		FlowStateScript.Type.LEVEL_UP:
			close_overlay_for_state(FlowStateScript.Type.LEVEL_UP, false)


func begin_deferred_scene_transition(new_state: int, old_state: int) -> bool:
	if _is_roadside_transition_in_flight():
		return _should_hold_roadside_transition_request(new_state)
	if not _has_pending_roadside_visual_bridge():
		return false
	if _should_defer_roadside_continuation_transition(new_state, old_state):
		var deferred_target_state: int = _resolve_roadside_continuation_target_state(new_state)
		_set_roadside_transition_in_flight(true)
		call_deferred("_run_roadside_continuation_transition", deferred_target_state, old_state)
		return true
	if new_state not in [FlowStateScript.Type.EVENT, FlowStateScript.Type.LEVEL_UP]:
		_clear_pending_roadside_visual_bridge()
	return false


func _marker_position_for_route_model(model: Dictionary, emergency_slot_index: int, emergency_slot_factor_by_visible_index: Dictionary, board_size: Vector2) -> Vector2:
	var node_id: int = int(model.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var world_position: Vector2 = _get_node_world_position(node_id)
	if world_position != Vector2.ZERO:
		return world_position + _route_layout_offset - (MapRouteBindingScript.ROUTE_MARKER_SIZE * 0.5)
	if emergency_slot_factor_by_visible_index.has(emergency_slot_index):
		return board_size * Vector2(emergency_slot_factor_by_visible_index.get(emergency_slot_index, MapRouteBindingScript.BOARD_FOCUS_ANCHOR_FACTOR)) - (MapRouteBindingScript.ROUTE_MARKER_SIZE * 0.5) + _route_layout_offset
	return board_size * MapRouteBindingScript.BOARD_FOCUS_ANCHOR_FACTOR - (MapRouteBindingScript.ROUTE_MARKER_SIZE * 0.5)


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


func _build_emergency_route_slot_factors(visible_count: int) -> Array[Vector2]:
	match visible_count:
		0:
			return []
		1:
			return [MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_FORWARD]
		2:
			return [MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_TOP_LEFT, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_TOP_RIGHT]
		3:
			return [MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_FORWARD, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_TOP_LEFT, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_TOP_RIGHT]
		4:
			return [MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_FORWARD, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_TOP_LEFT, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_TOP_RIGHT, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_LOWER_MID]
		5:
			return [MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_FORWARD, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_TOP_LEFT, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_TOP_RIGHT, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_BOTTOM_LEFT, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_BOTTOM_RIGHT]
		_:
			return [MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_FORWARD, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_TOP_LEFT, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_TOP_RIGHT, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_BOTTOM_LEFT, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_BOTTOM_RIGHT, MapRouteBindingScript.EMERGENCY_ROUTE_SLOT_LOWER_MID]


func _build_route_move_world_path(current_node_id: int, target_node_id: int, fallback_start_world: Vector2, fallback_target_world: Vector2) -> PackedVector2Array:
	return MapRouteMotionHelperScript.build_route_move_world_path(
		_board_composition_cache,
		current_node_id,
		target_node_id,
		fallback_start_world,
		fallback_target_world
	)


func _build_pending_roadside_visual_sample() -> Dictionary:
	if not _has_pending_roadside_visual_state():
		return {}
	var current_node_id: int = int(_roadside_visual_state.get("current_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var target_node_id: int = int(_roadside_visual_state.get("target_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	if current_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID or target_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
		return {}
	var route_path: PackedVector2Array = _build_route_move_world_path(
		current_node_id,
		target_node_id,
		_get_node_world_position(current_node_id),
		_get_node_world_position(target_node_id)
	)
	var route_length: float = _polyline_length(route_path)
	if route_length <= 0.001:
		return {}
	var progress: float = clampf(float(_roadside_visual_state.get("progress", MapRouteBindingScript.ROADSIDE_INTERRUPTION_PROGRESS)), 0.0, 1.0)
	var sample: Dictionary = _sample_polyline_at_distance(route_path, route_length * progress)
	sample["offset"] = Vector2(_roadside_visual_state.get("offset", _route_layout_offset))
	return sample


func _prime_roadside_visual_state(current_node_id: int, target_node_id: int) -> void:
	if current_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID or target_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
		_clear_pending_roadside_visual_state()
		return
	var target_offset: Vector2 = _fixed_board_layout_offset()
	var interruption_offset: Vector2 = _fixed_board_layout_offset()
	_roadside_visual_state = {
		"current_node_id": current_node_id,
		"target_node_id": target_node_id,
		"progress": MapRouteBindingScript.ROADSIDE_INTERRUPTION_PROGRESS,
		"offset": interruption_offset,
		"target_offset": target_offset,
	}


func _clear_pending_roadside_visual_state() -> void:
	_roadside_visual_state = {}
	_roadside_transition_in_flight = false


func _has_pending_roadside_visual_state() -> bool:
	return not _roadside_visual_state.is_empty() and int(_roadside_visual_state.get("target_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)) != MapRuntimeStateScript.NO_PENDING_NODE_ID


func _desired_focus_offset_for_world_position(world_position: Vector2) -> Vector2:
	return _fixed_board_layout_offset()


func _route_camera_follow_progress(progress: float) -> float:
	return 0.0


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


func _fixed_board_layout_offset() -> Vector2:
	return Vector2.ZERO


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


func _sample_polyline_at_distance(points: PackedVector2Array, distance: float) -> Dictionary:
	if points.is_empty():
		return {"point": Vector2.ZERO, "direction": Vector2.RIGHT}
	if points.size() == 1:
		return {"point": points[0], "direction": Vector2.RIGHT}
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
			return {"point": from_point.lerp(to_point, segment_progress), "direction": segment / segment_length}
		remaining_distance -= segment_length
	var last_segment: Vector2 = points[points.size() - 1] - points[points.size() - 2]
	return {
		"point": points[points.size() - 1],
		"direction": last_segment.normalized() if last_segment.length_squared() > 0.001 else Vector2.RIGHT,
	}


func _get_node_world_position(node_id: int) -> Vector2:
	if node_id < 0 or _board_composition_cache.is_empty():
		return Vector2.ZERO
	var world_positions: Dictionary = _board_composition_cache.get("world_positions", {})
	return world_positions.get(node_id, Vector2.ZERO)


func _ease_in_out_sine(value: float) -> float:
	var clamped_value: float = clampf(value, 0.0, 1.0)
	return 0.5 - (cos(clamped_value * PI) * 0.5)


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


func _should_defer_roadside_continuation_transition(new_state: int, old_state: int) -> bool:
	return old_state in [FlowStateScript.Type.EVENT, FlowStateScript.Type.LEVEL_UP] and ROADSIDE_CONTINUATION_RESUME_STATES.has(new_state)


func _should_hold_roadside_transition_request(new_state: int) -> bool:
	return ROADSIDE_CONTINUATION_RESUME_STATES.has(new_state)


func _resolve_roadside_continuation_target_state(new_state: int) -> int:
	if new_state != FlowStateScript.Type.MAP_EXPLORE:
		return new_state
	var bootstrap = _get_app_bootstrap()
	var flow_manager = bootstrap.get_flow_manager() if bootstrap != null else null
	if flow_manager == null:
		return new_state
	var live_flow_state: int = int(flow_manager.get_current_state())
	if ROADSIDE_CONTINUATION_RESUME_STATES.has(live_flow_state) and live_flow_state != FlowStateScript.Type.MAP_EXPLORE:
		return live_flow_state
	return new_state


func _run_roadside_continuation_transition(target_state: int, old_state: int) -> void:
	await _play_roadside_continuation_transition(target_state, old_state)


func _play_roadside_continuation_transition(target_state: int, old_state: int) -> void:
	_close_roadside_source_overlay(old_state)
	if is_inside_tree():
		await get_tree().create_timer(ROADSIDE_CONTINUATION_CLOSE_LEAD_IN).timeout
	if _route_binding != null:
		await _route_binding.animate_pending_roadside_continuation()
	_clear_pending_roadside_visual_bridge()
	_refresh_ui()
	var scene_router: Node = _scene_node("/root/SceneRouter")
	if scene_router != null:
		scene_router.call_deferred("route_to_state_for_restore", target_state)


func _apply_temp_theme() -> void:
	MapExploreSceneUiScript.apply_temp_theme(self)


func _apply_text_density_pass() -> void:
	MapExploreSceneUiScript.apply_text_density_pass(self)


func _on_route_grid_resized() -> void:
	if _is_refreshing_ui:
		if _route_binding != null:
			_route_binding.request_next_refresh_full_recompose()
		_queue_refresh_ui()
		return
	if _route_binding != null and _route_binding.is_selection_in_flight():
		return
	var run_state: RunState = _get_run_state()
	if _route_binding != null and run_state != null:
		_route_binding.refresh_layout_for_resize(run_state)
		_route_binding.render(run_state)
	_position_active_overlays()


func _consume_pending_refresh_ui() -> void:
	if _is_refreshing_ui:
		_schedule_refresh_ui_consume()
		return
	if not _refresh_ui_pending:
		return
	_refresh_ui_pending = false
	_refresh_ui()


func _on_viewport_size_changed() -> void:
	_apply_portrait_safe_layout()
	if _run_inventory_panel != null:
		_run_inventory_panel.refresh_hovered_tooltip()
	if _first_run_hint_controller != null:
		_first_run_hint_controller.refresh_position()
	if _hunger_warning_toast != null:
		_hunger_warning_toast.position_toast()
	_position_active_overlays()
	if _route_binding != null:
		_route_binding.request_next_refresh_full_recompose()
	_queue_refresh_ui()


func _sync_overlays_with_flow_state() -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return
	var flow_manager = bootstrap.get_flow_manager()
	if flow_manager == null or _overlay_director == null:
		return
	_overlay_director.sync_with_flow_state(flow_manager.get_current_state())
	_sync_safe_menu_launcher_visibility()


func _position_active_overlays() -> void:
	if _overlay_director != null:
		_overlay_director.position_overlays()
	_sync_safe_menu_launcher_visibility()


func _request_overlay_ui_refresh() -> void:
	_queue_refresh_ui()


func open_overlay_for_state(flow_state: int) -> void:
	if _overlay_director != null:
		_overlay_director.open_overlay_for_state(flow_state)
	_sync_safe_menu_launcher_visibility()


func close_overlay_for_state(flow_state: int, immediate: bool = false) -> void:
	if _overlay_director != null:
		_overlay_director.close_overlay_for_state(flow_state, immediate)
	_sync_safe_menu_launcher_visibility()


func close_all_overlays(immediate: bool = false) -> void:
	if _overlay_director != null:
		_overlay_director.close_all(immediate)
	_sync_safe_menu_launcher_visibility()


func _apply_portrait_safe_layout() -> void:
	MapExploreSceneUiScript.apply_portrait_safe_layout(self, PORTRAIT_SAFE_MAX_WIDTH, PORTRAIT_SAFE_MIN_SIDE_MARGIN)
	if _quest_log_panel != null:
		_quest_log_panel.refresh_layout()


func _prime_inventory_drawer_preview() -> void:
	if _inventory_drawer_card != null:
		_inventory_drawer_card.visible = true
	if _inventory_drawer_title_label != null:
		_inventory_drawer_title_label.text = MAP_INVENTORY_DRAWER_TITLE
		_inventory_drawer_title_label.visible = true
	if _inventory_drawer_summary_label != null:
		_inventory_drawer_summary_label.text = ""
		_inventory_drawer_summary_label.visible = false
	if _inventory_drawer_toggle_button != null:
		_inventory_drawer_toggle_button.text = "Show Cards"
		_inventory_drawer_toggle_button.visible = true
	if _equipment_panel != null:
		_equipment_panel.visible = false
	if _backpack_panel != null:
		_backpack_panel.visible = false
	if _equipment_title_label != null:
		_equipment_title_label.visible = false
	if _equipment_hint_label != null:
		_equipment_hint_label.visible = false
	if _inventory_title_label != null:
		_inventory_title_label.visible = false
	if _inventory_hint_label != null:
		_inventory_hint_label.visible = false
func _setup_safe_menu() -> void:
	var menu_config: Dictionary = RunMenuSceneHelperScript.shared_menu_config()
	_safe_menu = RunMenuSceneHelperScript.ensure_safe_menu(
		self,
		_safe_menu,
		String(menu_config.get("title_text", RunMenuSceneHelperScript.SHARED_MENU_TITLE)),
		String(menu_config.get("subtitle_text", RunMenuSceneHelperScript.SHARED_MENU_SUBTITLE)),
		String(menu_config.get("launcher_text", RunMenuSceneHelperScript.SHARED_LAUNCHER_TEXT)),
		Callable(self, "_on_save_run_pressed"),
		Callable(self, "_on_load_run_pressed"),
		Callable(self, "_on_return_to_main_menu_pressed"),
		Callable(self, "_on_disable_tutorial_hints_pressed")
	)
	if _safe_menu != null:
		_safe_menu.set_launcher_enabled(false)
	MapExploreSceneUiScript.ensure_settings_menu_button(self, Callable(self, "_open_safe_menu"))
	_sync_safe_menu_launcher_visibility()

func _open_safe_menu() -> void:
	if _quest_log_panel != null: _quest_log_panel.close()
	if _safe_menu != null: _safe_menu.open_menu()
	_sync_safe_menu_launcher_visibility()


func _before_quest_log_toggle() -> void:
	if _safe_menu != null and _safe_menu.is_menu_open():
		_safe_menu.close_menu()
	call_deferred("_sync_safe_menu_launcher_visibility")


func _sync_safe_menu_launcher_visibility() -> void:
	var has_overlay: bool = _overlay_director != null and _overlay_director.has_active_overlay()
	var quest_log_open: bool = _quest_log_panel != null and _quest_log_panel.is_open()
	var settings_button: Button = _scene_node("%s/SettingsButton" % SETTINGS_MENU_ANCHOR_PATH) as Button
	if settings_button != null:
		var settings_interaction_enabled: bool = not has_overlay and not quest_log_open
		settings_button.visible = settings_interaction_enabled
		settings_button.focus_mode = Control.FOCUS_ALL if settings_interaction_enabled else Control.FOCUS_NONE
		settings_button.mouse_filter = Control.MOUSE_FILTER_STOP if settings_interaction_enabled else Control.MOUSE_FILTER_IGNORE
	if _quest_log_panel != null: _quest_log_panel.set_interaction_enabled(not has_overlay)
	if _safe_menu != null:
		_safe_menu.set_launcher_enabled(false)
		if has_overlay and _safe_menu.is_menu_open(): _safe_menu.close_menu()
func _ensure_hunger_warning_toast() -> void:
	if _hunger_warning_toast == null:
		_hunger_warning_toast = HungerWarningToastScript.new()
	_hunger_warning_toast.setup(self, TOP_ROW_PATH, 130)
func _on_hunger_threshold_crossed(_old_threshold: int, new_threshold: int) -> void:
	var warning_text: String = RunStatusStripScript.build_hunger_threshold_warning_text(new_threshold)
	if warning_text.is_empty():
		return
	_ensure_hunger_warning_toast()
	if _hunger_warning_toast != null:
		_hunger_warning_toast.show_warning(warning_text, new_threshold)
	_request_first_run_hint("first_low_hunger_warning")


func _request_first_contextual_map_hints(run_state: RunState) -> void:
	if run_state == null:
		return
	if _overlay_director != null and _overlay_director.has_active_overlay():
		return
	if _has_key_required_route_hint_context(run_state):
		_request_first_run_hint("first_key_required_route")


func _has_key_required_route_hint_context(run_state: RunState) -> bool:
	if run_state == null or run_state.map_runtime_state == null:
		return false
	for node_snapshot_variant in run_state.map_runtime_state.build_adjacent_node_snapshots():
		if typeof(node_snapshot_variant) != TYPE_DICTIONARY:
			continue
		var node_snapshot: Dictionary = node_snapshot_variant
		if String(node_snapshot.get("node_family", "")) != "boss":
			continue
		if String(node_snapshot.get("node_state", "")) == MapRuntimeStateScript.NODE_STATE_LOCKED:
			return true
	return false
