# Layer: Scenes - presentation only
extends Control

const MapExplorePresenterScript = preload("res://Game/UI/map_explore_presenter.gd")
const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const SafeMenuOverlayScript = preload("res://Game/UI/safe_menu_overlay.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const MAP_BOARD_BACKDROP_TEXTURE: Texture2D = preload("res://Assets/UI/Map/ui_map_board_backdrop.svg")
const MAP_MARKER_BACKPLATE_TEXTURE: Texture2D = preload("res://Assets/UI/Map/ui_map_marker_backplate_component.svg")
const MAP_WALKER_IDLE_TEXTURE: Texture2D = preload("res://Assets/UI/Map/Walker/ui_map_walker_idle.svg")
const MAP_WALKER_WALK_A_TEXTURE: Texture2D = preload("res://Assets/UI/Map/Walker/ui_map_walker_walk_a.svg")
const MAP_WALKER_WALK_B_TEXTURE: Texture2D = preload("res://Assets/UI/Map/Walker/ui_map_walker_walk_b.svg")
const KEY_MARKER_ICON_TEXTURE: Texture2D = preload("res://Assets/Icons/icon_confirm.svg")
const NODE_SELECT_SFX = preload("res://Assets/Audio/SFX/sfx_node_select_01.ogg")
const MAP_MUSIC_LOOP = preload("res://Assets/Audio/Music/music_map_loop_temp_01.ogg")
const AUDIO_PLAYER_NODE_NAMES: Array[String] = [
	"NodeSelectSfxPlayer",
	"MapMusicPlayer",
]

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

const FOG_PREVIEW_LABEL_NAMES: PackedStringArray = [
	"FogNorthLabel",
	"FogWestLabel",
	"FogEastLabel",
]

const ROUTE_SLOT_TOP_LEFT := Vector2(0.33, 0.35)
const ROUTE_SLOT_TOP_RIGHT := Vector2(0.67, 0.35)
const ROUTE_SLOT_BOTTOM_LEFT := Vector2(0.29, 0.67)
const ROUTE_SLOT_BOTTOM_RIGHT := Vector2(0.71, 0.67)
const ROUTE_SLOT_LOWER_MID := Vector2(0.50, 0.82)
const ROUTE_SLOT_FORWARD := Vector2(0.50, 0.19)
const ROUTE_MARKER_SIZE := Vector2(144, 144)
const ROUTE_HITBOX_SIZE := Vector2(156, 156)
const CURRENT_MARKER_SIZE := Vector2(40, 40)
const CURRENT_MARKER_POSITION_FACTOR := Vector2(0.5, 0.56)
const WALKER_ROOT_SIZE := Vector2(94, 112)
const WALKER_SHADOW_SIZE := Vector2(30, 8)
const WALKER_SPRITE_SIZE := Vector2(80, 96)
const NODE_PLATE_SIZE := Vector2(104, 104)
const NODE_ICON_SIZE := Vector2(128, 128)
const KEY_MARKER_SIZE := Vector2(34, 34)
const KEY_ICON_SIZE := Vector2(18, 18)
const STATE_PIP_SIZE := Vector2(14, 14)

var _status_lines: PackedStringArray = []
var _presenter: RefCounted
var _route_selection_in_flight: bool = false
var _route_models_cache: Array[Dictionary] = []
var _current_marker: TextureRect
var _road_base_lines: Array[Line2D] = []
var _road_highlight_lines: Array[Line2D] = []
var _walker_root: Control
var _walker_shadow: PanelContainer
var _walker_sprite: TextureRect
var _walker_cycle_token: int = 0
var _active_route_index: int = -1
var _hovered_route_index: int = -1
var _safe_menu: SafeMenuOverlay


func _ready() -> void:
	_presenter = MapExplorePresenterScript.new()
	_connect_route_buttons()
	_apply_static_map_textures()
	_configure_audio_players()
	_ensure_runtime_board_nodes()
	_apply_temp_theme()
	_style_route_buttons_for_overlay_mode()
	_apply_text_density_pass()
	_setup_safe_menu()
	_start_looping_audio_player("MapMusicPlayer")

	var route_grid: Control = get_node_or_null("Margin/VBox/RouteGrid") as Control
	if route_grid != null:
		var resized_handler := Callable(self, "_on_route_grid_resized")
		if not route_grid.is_connected("resized", resized_handler):
			route_grid.connect("resized", resized_handler)

	var bootstrap = _get_app_bootstrap()
	if bootstrap != null:
		bootstrap.ensure_run_state_initialized()

	call_deferred("_refresh_ui")


func _exit_tree() -> void:
	_stop_walker_walk_cycle()
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


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
	_play_audio_player("NodeSelectSfxPlayer")
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
			_safe_menu.set_status_text("Run saved.")
	else:
		_append_status_line("Save failed: %s" % String(save_result.get("error", "unknown")))
		if _safe_menu != null:
			_safe_menu.set_status_text("Save failed: %s" % String(save_result.get("error", "unknown")))
	_refresh_ui()


func _on_load_run_pressed() -> void:
	var bootstrap = _get_app_bootstrap()
	if bootstrap == null:
		return
	var load_result: Dictionary = bootstrap.load_game()
	if bool(load_result.get("ok", false)):
		return
	_append_status_line("Load failed: %s" % String(load_result.get("error", "unknown")))
	if _safe_menu != null:
		_safe_menu.set_status_text("Load failed: %s" % String(load_result.get("error", "unknown")))
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
	if int(result.get("target_state", FlowState.Type.MAP_EXPLORE)) == FlowState.Type.NODE_RESOLVE:
		_append_status_line("Entered %s node. Hunger: %d" % [node_type, int(result.get("hunger", 0))])
	else:
		_append_status_line("Traversed to %s (%s). Hunger: %d" % [node_type, node_state, int(result.get("hunger", 0))])
	_refresh_ui()


func _refresh_ui() -> void:
	var run_state: RunState = _get_run_state()
	if run_state == null:
		return

	_layout_route_grid()

	var title_label: Label = get_node_or_null("Margin/VBox/TopRow/HeaderCard/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.text = _presenter.build_title_text(run_state)

	var progress_label: Label = get_node_or_null("Margin/VBox/TopRow/HeaderCard/HeaderStack/ProgressLabel") as Label
	if progress_label != null:
		progress_label.text = _presenter.build_progress_text(run_state)

	var stats_label: Label = get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsLabel") as Label
	if stats_label != null:
		stats_label.text = _presenter.build_run_status_text(run_state)

	var board_note_label: Label = get_node_or_null("Margin/VBox/BoardNoteLabel") as Label
	if board_note_label != null:
		board_note_label.text = _presenter.build_map_shell_note_text()

	var cluster_read_label: Label = get_node_or_null("Margin/VBox/ClusterReadLabel") as Label
	if cluster_read_label != null:
		cluster_read_label.text = _presenter.build_cluster_read_text(run_state)

	var node_family_label: Label = get_node_or_null("Margin/VBox/NodeFamilyLabel") as Label
	if node_family_label != null:
		node_family_label.text = _presenter.build_node_family_text()

	var state_legend_label: Label = get_node_or_null("Margin/VBox/StateLegendLabel") as Label
	if state_legend_label != null:
		state_legend_label.text = _presenter.build_state_legend_text()

	var key_legend_label: Label = get_node_or_null("Margin/VBox/KeyLegendLabel") as Label
	if key_legend_label != null:
		key_legend_label.text = _presenter.build_key_legend_text()

	var boss_legend_label: Label = get_node_or_null("Margin/VBox/BossLegendLabel") as Label
	if boss_legend_label != null:
		boss_legend_label.text = _presenter.build_boss_gate_legend_text()

	var current_chip_label: Label = get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentChipLabel") as Label
	if current_chip_label != null:
		current_chip_label.text = _presenter.build_current_anchor_chip_text()

	var current_anchor_label: Label = get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorLabel") as Label
	if current_anchor_label != null:
		current_anchor_label.text = _presenter.build_current_anchor_text(run_state)

	var current_anchor_detail_label: Label = get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorDetailLabel") as Label
	if current_anchor_detail_label != null:
		current_anchor_detail_label.text = _presenter.build_current_anchor_detail_text(run_state)

	var fog_preview_texts: PackedStringArray = _presenter.build_fog_preview_texts(run_state, FOG_PREVIEW_LABEL_NAMES.size())
	for index in range(FOG_PREVIEW_LABEL_NAMES.size()):
		var preview_label: Label = get_node_or_null("Margin/VBox/RouteGrid/%sCard/%s" % [FOG_PREVIEW_LABEL_NAMES[index].trim_suffix("Label"), FOG_PREVIEW_LABEL_NAMES[index]]) as Label
		if preview_label != null:
			preview_label.text = fog_preview_texts[index]

	var key_marker_label: Label = get_node_or_null("Margin/VBox/RouteGrid/KeyMarkerCard/KeyMarkerLabel") as Label
	if key_marker_label != null:
		key_marker_label.text = _presenter.build_key_marker_text(run_state)

	var route_models: Array[Dictionary] = _presenter.build_route_view_models(run_state, ROUTE_BUTTON_NODE_NAMES.size())
	_route_models_cache = route_models
	for index in range(ROUTE_BUTTON_NODE_NAMES.size()):
		var route_button: Button = get_node_or_null("Margin/VBox/RouteGrid/%s" % ROUTE_BUTTON_NODE_NAMES[index]) as Button
		if route_button == null:
			continue
		var model: Dictionary = route_models[index]
		route_button.visible = bool(model.get("visible", false))
		route_button.disabled = bool(model.get("disabled", true))
		route_button.text = String(model.get("text", ""))
		route_button.set_meta("target_node_id", int(model.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)))
		_update_route_marker_view(index, model)

	_update_current_marker_view(run_state)
	_refresh_route_roads()
	if not _route_selection_in_flight:
		_sync_walker_to_current_marker()

	var status_label: Label = get_node_or_null("Margin/VBox/BottomRow/StatusCard/StatusLabel") as Label
	if status_label != null:
		status_label.text = _presenter.build_status_log_text(_status_lines)
		status_label.visible = not status_label.text.is_empty()
	var status_card: Control = get_node_or_null("Margin/VBox/BottomRow/StatusCard") as Control
	if status_card != null and status_label != null:
		status_card.visible = status_label.visible

	if _safe_menu != null:
		var bootstrap = _get_app_bootstrap()
		_safe_menu.set_load_available(bootstrap != null and bootstrap.has_save_game())

func _append_status_line(line: String) -> void:
	_status_lines.append(line)
	if _status_lines.size() > 6:
		_status_lines.remove_at(0)


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
	_hovered_route_index = ROUTE_BUTTON_NODE_NAMES.find(button_node_name)
	_refresh_ui()


func _on_route_button_mouse_exited(button_node_name: String) -> void:
	if ROUTE_BUTTON_NODE_NAMES.find(button_node_name) != _hovered_route_index:
		return
	_hovered_route_index = -1
	_refresh_ui()


func _on_route_button_focus_entered(button_node_name: String) -> void:
	_hovered_route_index = ROUTE_BUTTON_NODE_NAMES.find(button_node_name)
	_refresh_ui()


func _on_route_button_focus_exited(button_node_name: String) -> void:
	if ROUTE_BUTTON_NODE_NAMES.find(button_node_name) != _hovered_route_index:
		return
	_hovered_route_index = -1
	_refresh_ui()


func _apply_static_map_textures() -> void:
	_set_texture_rect_texture("Margin/VBox/RouteGrid/BoardBackdrop", MAP_BOARD_BACKDROP_TEXTURE)
	_set_texture_rect_texture("Margin/VBox/RouteGrid/FogWestCard", MAP_MARKER_BACKPLATE_TEXTURE)
	_set_texture_rect_texture("Margin/VBox/RouteGrid/FogNorthCard", MAP_MARKER_BACKPLATE_TEXTURE)
	_set_texture_rect_texture("Margin/VBox/RouteGrid/FogEastCard", MAP_MARKER_BACKPLATE_TEXTURE)
	_set_texture_rect_texture("Margin/VBox/RouteGrid/KeyMarkerCard", null)


func _configure_audio_players() -> void:
	var node_select_player: AudioStreamPlayer = get_node_or_null("NodeSelectSfxPlayer") as AudioStreamPlayer
	if node_select_player != null:
		node_select_player.stream = NODE_SELECT_SFX
	var map_music_player: AudioStreamPlayer = get_node_or_null("MapMusicPlayer") as AudioStreamPlayer
	if map_music_player != null:
		map_music_player.stream = MAP_MUSIC_LOOP


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

	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(_walker_root, "position", _position_for_walker_center(target_center), _clamp_route_move_duration(start_center.distance_to(target_center)))
	await tween.finished

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

	for marker_name in ROUTE_MARKER_NODE_NAMES:
		var marker_rect: TextureRect = get_node_or_null("Margin/VBox/RouteGrid/%s" % marker_name) as TextureRect
		if marker_rect == null:
			continue
		marker_rect.clip_contents = false
		marker_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker_rect.z_index = 20
		_ensure_marker_overlay(marker_rect)

	if _current_marker == null:
		_current_marker = TextureRect.new()
		_current_marker.name = "CurrentNodeMarker"
		_current_marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_current_marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_current_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_current_marker.clip_contents = false
		_current_marker.z_index = 30
		route_grid.add_child(_current_marker)
	_ensure_marker_overlay(_current_marker)
	route_grid.move_child(_current_marker, route_grid.get_child_count() - 1)

	if _road_base_lines.is_empty():
		for index in range(ROUTE_MARKER_NODE_NAMES.size()):
			var base_line := Line2D.new()
			base_line.name = "RouteRoadBase%d" % index
			base_line.width = 10.0
			base_line.default_color = Color(0.57, 0.49, 0.30, 0.82)
			base_line.antialiased = true
			base_line.z_index = 2
			base_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			base_line.end_cap_mode = Line2D.LINE_CAP_ROUND
			base_line.joint_mode = Line2D.LINE_JOINT_ROUND
			route_grid.add_child(base_line)
			route_grid.move_child(base_line, 1)
			_road_base_lines.append(base_line)

			var highlight_line := Line2D.new()
			highlight_line.name = "RouteRoadHighlight%d" % index
			highlight_line.width = 4.0
			highlight_line.default_color = Color(0.96, 0.90, 0.70, 0.78)
			highlight_line.antialiased = true
			highlight_line.z_index = 3
			highlight_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			highlight_line.end_cap_mode = Line2D.LINE_CAP_ROUND
			highlight_line.joint_mode = Line2D.LINE_JOINT_ROUND
			route_grid.add_child(highlight_line)
			route_grid.move_child(highlight_line, 2)
			_road_highlight_lines.append(highlight_line)

	if _walker_root == null:
		_walker_root = Control.new()
		_walker_root.name = "WalkerActor"
		_walker_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_walker_root.size = WALKER_ROOT_SIZE
		_walker_root.z_index = 40
		route_grid.add_child(_walker_root)

		_walker_shadow = PanelContainer.new()
		_walker_shadow.name = "WalkerShadow"
		_walker_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_walker_shadow.size = WALKER_SHADOW_SIZE
		_walker_shadow.position = Vector2((WALKER_ROOT_SIZE.x - WALKER_SHADOW_SIZE.x) * 0.5, WALKER_ROOT_SIZE.y - WALKER_SHADOW_SIZE.y - 4.0)
		_walker_root.add_child(_walker_shadow)
		_apply_walker_shadow_style()

		_walker_sprite = TextureRect.new()
		_walker_sprite.name = "WalkerSprite"
		_walker_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_walker_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_walker_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_walker_sprite.size = WALKER_SPRITE_SIZE
		_walker_sprite.position = Vector2((WALKER_ROOT_SIZE.x - WALKER_SPRITE_SIZE.x) * 0.5, 4.0)
		_walker_sprite.pivot_offset = WALKER_SPRITE_SIZE * 0.5
		_walker_root.add_child(_walker_sprite)

	route_grid.move_child(_walker_root, route_grid.get_child_count() - 1)
	_walker_root.visible = false


func _ensure_marker_overlay(marker_rect: TextureRect) -> void:
	var selection_ring: PanelContainer = marker_rect.get_node_or_null("SelectionRing") as PanelContainer
	if selection_ring == null:
		selection_ring = PanelContainer.new()
		selection_ring.name = "SelectionRing"
		selection_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker_rect.add_child(selection_ring)

	var node_plate: PanelContainer = marker_rect.get_node_or_null("NodePlate") as PanelContainer
	if node_plate == null:
		node_plate = PanelContainer.new()
		node_plate.name = "NodePlate"
		node_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker_rect.add_child(node_plate)

	var icon_rect: TextureRect = marker_rect.get_node_or_null("RouteIcon") as TextureRect
	if icon_rect == null:
		icon_rect = TextureRect.new()
		icon_rect.name = "RouteIcon"
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		marker_rect.add_child(icon_rect)

	var chip_panel: PanelContainer = marker_rect.get_node_or_null("StateChip") as PanelContainer
	if chip_panel == null:
		chip_panel = PanelContainer.new()
		chip_panel.name = "StateChip"
		chip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker_rect.add_child(chip_panel)

	var chip_label: Label = null
	if chip_panel != null:
		chip_label = chip_panel.get_node_or_null("StateChipLabel") as Label
	if chip_label == null and chip_panel != null:
		chip_label = Label.new()
		chip_label.name = "StateChipLabel"
		chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip_panel.add_child(chip_label)

	var fallback_label: Label = marker_rect.get_node_or_null("FallbackLabel") as Label
	if fallback_label == null:
		fallback_label = Label.new()
		fallback_label.name = "FallbackLabel"
		fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fallback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker_rect.add_child(fallback_label)


func _ensure_key_marker_visual(card_rect: TextureRect) -> void:
	if card_rect == null:
		return

	var icon_rect: TextureRect = card_rect.get_node_or_null("KeyMarkerIcon") as TextureRect
	if icon_rect == null:
		icon_rect = TextureRect.new()
		icon_rect.name = "KeyMarkerIcon"
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_rect.add_child(icon_rect)


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
		"",
		"",
		"current",
		false,
		false
	)


func _apply_marker_visual_state(marker_rect: TextureRect, icon_texture_path: String, family_label: String, chip_text: String, state_semantic: String, is_disabled: bool, is_selected: bool) -> void:
	if marker_rect == null:
		return

	marker_rect.modulate = _marker_modulate_for_semantic(state_semantic, is_disabled)

	var node_plate: PanelContainer = marker_rect.get_node_or_null("NodePlate") as PanelContainer
	if node_plate != null:
		var plate_size: Vector2 = NODE_PLATE_SIZE
		if state_semantic == "current":
			plate_size = Vector2(54, 54)
		node_plate.visible = true
		node_plate.size = plate_size
		node_plate.position = (marker_rect.size - plate_size) * 0.5
		_apply_node_plate_style(node_plate, state_semantic, is_disabled)

	var icon_rect: TextureRect = marker_rect.get_node_or_null("RouteIcon") as TextureRect
	if icon_rect != null:
		icon_rect.position = (marker_rect.size - NODE_ICON_SIZE) * 0.5
		icon_rect.size = NODE_ICON_SIZE
		icon_rect.texture = _load_texture_or_null(icon_texture_path)
		icon_rect.visible = icon_rect.texture != null and state_semantic != "current"
		icon_rect.modulate = _icon_modulate_for_semantic(state_semantic, is_disabled)

	var selection_ring: PanelContainer = marker_rect.get_node_or_null("SelectionRing") as PanelContainer
	if selection_ring != null:
		selection_ring.position = ((marker_rect.size - NODE_ICON_SIZE) * 0.5) - Vector2(8, 8)
		selection_ring.size = NODE_ICON_SIZE + Vector2(16, 16)
		selection_ring.visible = not is_disabled and is_selected
		_apply_selection_ring(selection_ring, state_semantic, is_selected)

	var chip_panel: PanelContainer = marker_rect.get_node_or_null("StateChip") as PanelContainer
	var chip_label: Label = null
	if chip_panel != null:
		chip_label = chip_panel.get_node_or_null("StateChipLabel") as Label
	if chip_panel != null and chip_label != null:
		var should_show_chip: bool = not chip_text.is_empty() and (state_semantic == "locked" or state_semantic == "resolved")
		chip_panel.visible = should_show_chip
		chip_panel.size = STATE_PIP_SIZE
		if state_semantic == "resolved":
			chip_panel.position = Vector2(marker_rect.size.x - STATE_PIP_SIZE.x - 8.0, marker_rect.size.y - STATE_PIP_SIZE.y - 8.0)
		else:
			chip_panel.position = Vector2(marker_rect.size.x - STATE_PIP_SIZE.x - 8.0, 8.0)
		chip_label.position = Vector2.ZERO
		chip_label.size = chip_panel.size
		chip_label.text = ""
		chip_label.visible = false
		_apply_chip_style(chip_panel, chip_label, state_semantic)

	var fallback_label: Label = marker_rect.get_node_or_null("FallbackLabel") as Label
	if fallback_label != null:
		fallback_label.visible = false

	if state_semantic == "current":
		marker_rect.modulate = Color(1, 1, 1, 0.0)


func _apply_selection_ring(selection_ring: PanelContainer, state_semantic: String, is_selected: bool) -> void:
	if selection_ring == null:
		return

	var accent: Color = _accent_color_for_semantic(state_semantic)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = accent.lightened(0.1) if is_selected else accent
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 36
	style.corner_radius_top_right = 36
	style.corner_radius_bottom_right = 36
	style.corner_radius_bottom_left = 36
	style.shadow_color = Color(0, 0, 0, 0.0)
	style.shadow_size = 0
	selection_ring.add_theme_stylebox_override("panel", style)
	selection_ring.modulate = Color(1, 1, 1, 1.0) if is_selected else Color(1, 1, 1, 0.86)


func _apply_node_plate_style(node_plate: PanelContainer, state_semantic: String, is_disabled: bool) -> void:
	if node_plate == null:
		return

	var fill_color := Color(0.10, 0.14, 0.11, 0.90)
	match state_semantic:
		"resolved":
			fill_color = Color(0.19, 0.22, 0.18, 0.82)
		"locked":
			fill_color = Color(0.20, 0.15, 0.13, 0.88)
		"current":
			fill_color = Color(0.67, 0.56, 0.30, 0.92)
	if is_disabled:
		fill_color.a = 0.70

	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color(0, 0, 0, 0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_right = 999
	style.corner_radius_bottom_left = 999
	style.shadow_color = Color(0, 0, 0, 0.0)
	style.shadow_size = 0
	node_plate.add_theme_stylebox_override("panel", style)


func _apply_chip_style(chip_panel: PanelContainer, chip_label: Label, state_semantic: String) -> void:
	if chip_panel == null or chip_label == null:
		return

	var accent: Color = _accent_color_for_semantic(state_semantic)
	var fill: Color = TempScreenThemeScript.PANEL_SOFT_FILL_COLOR.lerp(accent, 0.52)
	fill.a = 0.98

	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = accent
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.corner_radius_top_left = 100
	style.corner_radius_top_right = 100
	style.corner_radius_bottom_right = 100
	style.corner_radius_bottom_left = 100
	chip_panel.add_theme_stylebox_override("panel", style)
	chip_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)


func _icon_modulate_for_semantic(state_semantic: String, is_disabled: bool) -> Color:
	if is_disabled:
		return Color(0.84, 0.82, 0.76, 0.82)
	match state_semantic:
		"resolved":
			return Color(0.94, 0.92, 0.86, 0.92)
		"locked":
			return Color(0.92, 0.82, 0.74, 0.84)
		_:
			return Color(1, 1, 1, 1.0)


func _marker_modulate_for_semantic(state_semantic: String, is_disabled: bool) -> Color:
	if is_disabled:
		return Color(1, 1, 1, 0.90)
	match state_semantic:
		"resolved":
			return Color(0.94, 0.9, 0.82, 1.0)
		"locked":
			return Color(0.90, 0.84, 0.78, 0.92)
		"current":
			return Color(1, 1, 1, 1.0)
		_:
			return Color(1, 1, 1, 1.0)


func _accent_color_for_semantic(state_semantic: String) -> Color:
	match state_semantic:
		"resolved":
			return TempScreenThemeScript.PANEL_BORDER_COLOR
		"locked":
			return TempScreenThemeScript.RUST_ACCENT_COLOR
		"current":
			return TempScreenThemeScript.REWARD_ACCENT_COLOR
		_:
			return TempScreenThemeScript.TEAL_ACCENT_COLOR


func _refresh_route_roads() -> void:
	if _current_marker == null or _route_models_cache.is_empty():
		return

	var start_center: Vector2 = _get_current_marker_center()
	for index in range(ROUTE_MARKER_NODE_NAMES.size()):
		if index >= _road_base_lines.size() or index >= _road_highlight_lines.size():
			continue
		var base_line: Line2D = _road_base_lines[index]
		var highlight_line: Line2D = _road_highlight_lines[index]
		var visible: bool = index < _route_models_cache.size() and bool(_route_models_cache[index].get("visible", false))
		var show_road: bool = visible and bool(_route_models_cache[index].get("show_road", true))
		if not show_road:
			base_line.visible = false
			highlight_line.visible = false
			continue

		var end_center: Vector2 = _get_route_marker_center(index)
		var road_points := PackedVector2Array([start_center, end_center])
		var state_semantic: String = String(_route_models_cache[index].get("state_semantic", "open"))
		var is_selected: bool = _active_route_index == index

		base_line.points = road_points
		base_line.visible = true
		base_line.width = 12.0 if is_selected else 10.0
		base_line.default_color = _road_base_color(state_semantic, is_selected)
		highlight_line.points = road_points
		highlight_line.visible = true
		highlight_line.width = 5.0 if is_selected else 4.0
		highlight_line.default_color = _road_highlight_color(state_semantic, is_selected)


func _road_base_color(state_semantic: String, is_selected: bool) -> Color:
	match state_semantic:
		"resolved":
			return Color(0.46, 0.44, 0.38, 0.84 if is_selected else 0.68)
		"locked":
			return Color(0.56, 0.34, 0.25, 0.90 if is_selected else 0.72)
		_:
			return Color(0.65, 0.54, 0.30, 0.94 if is_selected else 0.80)


func _road_highlight_color(state_semantic: String, is_selected: bool) -> Color:
	var color: Color = _accent_color_for_semantic(state_semantic)
	color.a = 0.98 if is_selected else 0.82
	return color


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
			continue
		var marker_position: Vector2 = route_grid.size * slot_factors[visible_slot_index] - (ROUTE_MARKER_SIZE * 0.5)
		marker_rect.size = ROUTE_MARKER_SIZE
		marker_rect.position = marker_position
		route_button.size = ROUTE_HITBOX_SIZE
		route_button.position = marker_position - ((ROUTE_HITBOX_SIZE - ROUTE_MARKER_SIZE) * 0.5)

	if _current_marker != null:
		_current_marker.size = CURRENT_MARKER_SIZE
		_current_marker.position = route_grid.size * CURRENT_MARKER_POSITION_FACTOR - (CURRENT_MARKER_SIZE * 0.5)

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


func _layout_auxiliary_board_cards(route_grid: Control) -> void:
	var fog_north_card: TextureRect = route_grid.get_node_or_null("FogNorthCard") as TextureRect
	var fog_west_card: TextureRect = route_grid.get_node_or_null("FogWestCard") as TextureRect
	var fog_east_card: TextureRect = route_grid.get_node_or_null("FogEastCard") as TextureRect
	var key_marker_card: TextureRect = route_grid.get_node_or_null("KeyMarkerCard") as TextureRect

	if fog_north_card != null:
		fog_north_card.visible = false
	if fog_west_card != null:
		fog_west_card.visible = false
	if fog_east_card != null:
		fog_east_card.visible = false
	if key_marker_card != null:
		key_marker_card.visible = true
		key_marker_card.texture = null
		key_marker_card.size = KEY_MARKER_SIZE
		key_marker_card.position = Vector2(route_grid.size.x - key_marker_card.size.x - 12.0, 14.0)
		_ensure_key_marker_visual(key_marker_card)
		var key_label: Label = key_marker_card.get_node_or_null("KeyMarkerLabel") as Label
		if key_label != null:
			key_label.visible = false
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


func _clamp_route_move_duration(distance: float) -> float:
	return clamp(distance / 260.0, 0.26, 0.52)


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


func _load_texture_or_null(asset_path: String) -> Texture2D:
	if asset_path.is_empty():
		return null

	var resource: Resource = load(asset_path)
	if resource is Texture2D:
		return resource as Texture2D
	return null


func _play_audio_player(node_path: String) -> void:
	var player: AudioStreamPlayer = get_node_or_null(node_path) as AudioStreamPlayer
	if player != null and player.stream != null:
		player.play()


func _start_looping_audio_player(node_path: String) -> void:
	var player: AudioStreamPlayer = get_node_or_null(node_path) as AudioStreamPlayer
	if player != null and player.stream != null and not player.playing:
		player.play()


func _apply_temp_theme() -> void:
	_apply_compact_map_panel(get_node_or_null("Margin/VBox/TopRow/HeaderCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 14, 0.88, 10, 6)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/TopRow/HeaderCard/HeaderStack/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/TopRow/HeaderCard/HeaderStack/ProgressLabel") as Label, "accent")
	_apply_compact_map_panel(get_node_or_null("Margin/VBox/TopRow/RunSummaryCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 14, 0.88, 10, 6)
	_apply_compact_map_panel(get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 14, 0.90, 10, 6)
	_apply_compact_map_panel(get_node_or_null("Margin/VBox/BottomRow/StatusCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 14, 0.88, 10, 6)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsLabel") as Label)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentChipLabel") as Label, "accent")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorDetailLabel") as Label)

	for label_path in [
		"Margin/VBox/BoardNoteLabel",
		"Margin/VBox/ClusterReadLabel",
		"Margin/VBox/NodeFamilyLabel",
		"Margin/VBox/StateLegendLabel",
		"Margin/VBox/KeyLegendLabel",
		"Margin/VBox/BossLegendLabel",
		"Margin/VBox/BottomRow/StatusCard/StatusLabel",
		"Margin/VBox/RouteGrid/FogWestCard/FogWestLabel",
		"Margin/VBox/RouteGrid/FogNorthCard/FogNorthLabel",
		"Margin/VBox/RouteGrid/FogEastCard/FogEastLabel",
		"Margin/VBox/RouteGrid/KeyMarkerCard/KeyMarkerLabel",
	]:
		TempScreenThemeScript.apply_label(get_node_or_null(label_path) as Label)

	var title_label: Label = get_node_or_null("Margin/VBox/TopRow/HeaderCard/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 24)

	var progress_label: Label = get_node_or_null("Margin/VBox/TopRow/HeaderCard/HeaderStack/ProgressLabel") as Label
	if progress_label != null:
		progress_label.add_theme_font_size_override("font_size", 15)

	var stats_label: Label = get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsLabel") as Label
	if stats_label != null:
		stats_label.add_theme_font_size_override("font_size", 14)

	var current_chip_label: Label = get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentChipLabel") as Label
	if current_chip_label != null:
		current_chip_label.add_theme_font_size_override("font_size", 11)

	var current_anchor_label: Label = get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorLabel") as Label
	if current_anchor_label != null:
		current_anchor_label.add_theme_font_size_override("font_size", 17)

	var current_anchor_detail_label: Label = get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorDetailLabel") as Label
	if current_anchor_detail_label != null:
		current_anchor_detail_label.add_theme_font_size_override("font_size", 13)


func _apply_compact_map_panel(panel: PanelContainer, accent: Color, corner_radius: int, fill_alpha: float, margin_x: int, margin_y: int) -> void:
	if panel == null:
		return

	TempScreenThemeScript.apply_panel(panel, accent, corner_radius, fill_alpha)
	var existing_style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if existing_style == null:
		return

	var compact_style: StyleBoxFlat = existing_style.duplicate() as StyleBoxFlat
	compact_style.shadow_size = 6
	compact_style.content_margin_left = margin_x
	compact_style.content_margin_top = margin_y
	compact_style.content_margin_right = margin_x
	compact_style.content_margin_bottom = margin_y
	panel.add_theme_stylebox_override("panel", compact_style)


func _style_route_buttons_for_overlay_mode() -> void:
	for button_node_name in ROUTE_BUTTON_NODE_NAMES:
		var route_button: Button = get_node_or_null("Margin/VBox/RouteGrid/%s" % button_node_name) as Button
		if route_button == null:
			continue
		route_button.flat = true
		route_button.z_index = 12
		route_button.focus_mode = Control.FOCUS_ALL
		route_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		route_button.add_theme_stylebox_override("normal", _build_route_button_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
		route_button.add_theme_stylebox_override("hover", _build_route_button_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
		route_button.add_theme_stylebox_override("pressed", _build_route_button_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
		route_button.add_theme_stylebox_override("focus", _build_route_button_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
		route_button.add_theme_stylebox_override("disabled", _build_route_button_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
		route_button.add_theme_color_override("font_color", Color(1, 1, 1, 0.0))
		route_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0.0))
		route_button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.0))
		route_button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.0))


func _build_route_button_box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 34
	style.corner_radius_top_right = 34
	style.corner_radius_bottom_right = 34
	style.corner_radius_bottom_left = 34
	style.shadow_color = Color(0, 0, 0, 0.14)
	style.shadow_size = 6
	return style


func _apply_text_density_pass() -> void:
	for label_path in [
		"Margin/VBox/BoardNoteLabel",
		"Margin/VBox/ClusterReadLabel",
		"Margin/VBox/NodeFamilyLabel",
		"Margin/VBox/KeyLegendLabel",
		"Margin/VBox/BossLegendLabel",
	]:
		var hidden_control: Control = get_node_or_null(label_path) as Control
		if hidden_control != null:
			hidden_control.visible = false

	var state_legend_label: Label = get_node_or_null("Margin/VBox/StateLegendLabel") as Label
	if state_legend_label != null:
		state_legend_label.add_theme_font_size_override("font_size", 13)

	var status_label: Label = get_node_or_null("Margin/VBox/BottomRow/StatusCard/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 13)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var current_chip_label: Label = get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentChipLabel") as Label
	if current_chip_label != null:
		current_chip_label.visible = false


func _apply_walker_shadow_style() -> void:
	if _walker_shadow == null:
		return

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.22)
	style.corner_radius_top_left = 100
	style.corner_radius_top_right = 100
	style.corner_radius_bottom_right = 100
	style.corner_radius_bottom_left = 100
	_walker_shadow.add_theme_stylebox_override("panel", style)


func _on_route_grid_resized() -> void:
	if _route_selection_in_flight:
		return
	_refresh_ui()


func _setup_safe_menu() -> void:
	if _safe_menu != null:
		return

	_safe_menu = SafeMenuOverlayScript.new()
	_safe_menu.name = "SafeMenuOverlay"
	_safe_menu.configure("Run Tools", "Save or load from this safe screen without covering route choices.", "Tools")
	add_child(_safe_menu)
	_safe_menu.save_requested.connect(Callable(self, "_on_save_run_pressed"))
	_safe_menu.load_requested.connect(Callable(self, "_on_load_run_pressed"))
