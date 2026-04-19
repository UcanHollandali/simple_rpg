# Layer: UI
extends RefCounted
class_name MapRouteBinding

const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const MapBoardStyleScript = preload("res://Game/UI/map_board_style.gd")
const MapExploreSceneUiScript = preload("res://Game/UI/map_explore_scene_ui.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const MapFocusHelperScript = preload("res://Game/UI/map_focus_helper.gd")

const MAP_BOARD_BACKDROP_TEXTURE: Texture2D = preload("res://Assets/UI/Map/ui_map_board_backdrop.svg")
const MAP_WALKER_IDLE_TEXTURE: Texture2D = preload("res://Assets/UI/Map/Walker/ui_map_walker_idle.svg")
const MAP_WALKER_WALK_A_TEXTURE: Texture2D = preload("res://Assets/UI/Map/Walker/ui_map_walker_walk_a.svg")
const MAP_WALKER_WALK_B_TEXTURE: Texture2D = preload("res://Assets/UI/Map/Walker/ui_map_walker_walk_b.svg")
const KEY_MARKER_ICON_TEXTURE: Texture2D = preload("res://Assets/Icons/icon_confirm.svg")

const ROUTE_GRID_PATH := "Margin/VBox/RouteGrid"
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
const BOARD_FOCUS_ANCHOR_FACTOR := Vector2(0.5, 0.65)
const BOARD_MAX_OFFSET_FACTOR := Vector2(0.05, 0.06)
const BOARD_FOCUS_DEADZONE_FACTOR := Vector2(0.18, 0.15)
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
const NODE_PLATE_SIZE := Vector2(116, 116)
const NODE_ICON_SIZE := Vector2(92, 92)
const KEY_MARKER_SIZE := Vector2(36, 36)
const KEY_ICON_SIZE := Vector2(18, 18)
const STATE_PIP_SIZE := Vector2(14, 14)

var _owner: Control
var _scene_node_getter: Callable
var _board_composer: RefCounted
var _route_models_cache: Array[Dictionary] = []
var _board_composition_cache: Dictionary = {}
var _current_run_state
var _current_marker: TextureRect
var _board_canvas: Control
var _walker_root: Control
var _walker_shadow: PanelContainer
var _walker_sprite: TextureRect
var _walker_cycle_token: int = 0
var _walker_frame_interval: float = 0.1
var _walker_facing_right: bool = true
var _active_route_index: int = -1
var _hovered_route_index: int = -1
var _route_layout_offset: Vector2 = Vector2.ZERO
var _route_move_start_offset: Vector2 = Vector2.ZERO
var _route_move_target_offset: Vector2 = Vector2.ZERO
var _route_move_world_path: PackedVector2Array = PackedVector2Array()
var _route_move_path_length: float = 0.0
var _route_move_stride_cycles: float = 0.0
var _route_move_sample_start_progress: float = 0.0
var _route_move_sample_end_progress: float = 1.0
var _roadside_visual_state: Dictionary = {}
var _roadside_transition_in_flight: bool = false
var _route_selection_in_flight: bool = false
var _board_graph_signature: String = ""
var _board_visibility_signature: String = ""
var _force_next_layout_recompose: bool = false
var _composed_board_size: Vector2 = Vector2.ZERO
var _allow_large_resize_recompose_once: bool = true


func configure(owner: Control, scene_node_getter: Callable, board_composer: RefCounted) -> void:
	_owner = owner
	_scene_node_getter = scene_node_getter
	_board_composer = board_composer


func get_route_grid() -> Control:
	return _scene_node(ROUTE_GRID_PATH) as Control


func connect_buttons(on_pressed: Callable) -> void:
	for button_node_name in ROUTE_BUTTON_NODE_NAMES:
		var route_button: Button = _scene_node("%s/%s" % [ROUTE_GRID_PATH, button_node_name]) as Button
		if route_button == null:
			continue
		var pressed_handler: Callable = on_pressed.bind(button_node_name)
		var entered_handler: Callable = Callable(self, "_on_route_button_mouse_entered").bind(button_node_name)
		var exited_handler: Callable = Callable(self, "_on_route_button_mouse_exited").bind(button_node_name)
		var focus_entered_handler: Callable = Callable(self, "_on_route_button_focus_entered").bind(button_node_name)
		var focus_exited_handler: Callable = Callable(self, "_on_route_button_focus_exited").bind(button_node_name)
		if not route_button.is_connected("pressed", pressed_handler):
			route_button.connect("pressed", pressed_handler)
		if not route_button.is_connected("mouse_entered", entered_handler):
			route_button.connect("mouse_entered", entered_handler)
		if not route_button.is_connected("mouse_exited", exited_handler):
			route_button.connect("mouse_exited", exited_handler)
		if not route_button.is_connected("focus_entered", focus_entered_handler):
			route_button.connect("focus_entered", focus_entered_handler)
		if not route_button.is_connected("focus_exited", focus_exited_handler):
			route_button.connect("focus_exited", focus_exited_handler)


func style_route_buttons_for_overlay_mode() -> void:
	MapExploreSceneUiScript.style_route_buttons_for_overlay_mode(get_route_grid(), ROUTE_BUTTON_NODE_NAMES)


func apply_static_map_textures() -> void:
	_set_texture_rect_texture("%s/BoardBackdrop" % ROUTE_GRID_PATH, MAP_BOARD_BACKDROP_TEXTURE)
	_set_texture_rect_texture("%s/KeyMarkerCard" % ROUTE_GRID_PATH, null)


func ensure_runtime_board_nodes() -> void:
	var route_grid: Control = get_route_grid()
	if route_grid == null:
		return
	var setup_result: Dictionary = MapExploreSceneUiScript.ensure_runtime_board_nodes(
		route_grid,
		ROUTE_MARKER_NODE_NAMES,
		_current_marker,
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


func set_route_models(route_models: Array[Dictionary]) -> void:
	_route_models_cache = route_models


func prepare_for_refresh(run_state) -> void:
	_current_run_state = run_state
	var route_grid: Control = get_route_grid()
	var graph_signature: String = _build_board_graph_signature(run_state)
	var visibility_signature: String = _build_board_visibility_signature(run_state)
	var stable_layout: Dictionary = {}
	if not _force_next_layout_recompose and graph_signature == _board_graph_signature and not _board_composition_cache.is_empty():
		stable_layout = {
			"world_positions": (_board_composition_cache.get("world_positions", {}) as Dictionary).duplicate(true),
			"forest_shapes": (_board_composition_cache.get("forest_shapes", []) as Array).duplicate(true),
		}
		if visibility_signature == _board_visibility_signature:
			stable_layout["visible_nodes"] = (_board_composition_cache.get("visible_nodes", []) as Array).duplicate(true)
			stable_layout["visible_edges"] = (_board_composition_cache.get("visible_edges", []) as Array).duplicate(true)
	_board_composition_cache = _build_board_composition(run_state, stable_layout)
	_board_graph_signature = graph_signature
	_board_visibility_signature = visibility_signature
	_force_next_layout_recompose = false
	_composed_board_size = route_grid.size if route_grid != null else Vector2.ZERO
	if not _route_selection_in_flight:
		_route_layout_offset = _desired_focus_offset_for_world_position(
			_get_node_world_position(int(run_state.map_runtime_state.current_node_id))
		)
	if has_pending_roadside_visual_state() and not _roadside_transition_in_flight:
		_route_layout_offset = Vector2(_roadside_visual_state.get("offset", _route_layout_offset))


func refresh_layout_for_resize(run_state) -> void:
	_current_run_state = run_state
	if _route_selection_in_flight or run_state == null or run_state.map_runtime_state == null:
		return
	var route_grid: Control = get_route_grid()
	if route_grid == null:
		return
	if _board_composition_cache.is_empty():
		_force_next_layout_recompose = true
		prepare_for_refresh(run_state)
		return
	var size_delta: Vector2 = route_grid.size - _composed_board_size
	if _allow_large_resize_recompose_once and (size_delta.x > 320.0 or size_delta.y > 320.0):
		_force_next_layout_recompose = true
		_allow_large_resize_recompose_once = false
		prepare_for_refresh(run_state)
		return
	_allow_large_resize_recompose_once = false
	_composed_board_size = route_grid.size
	var current_node_id: int = int(run_state.map_runtime_state.current_node_id)
	var current_world_position: Vector2 = _get_node_world_position(current_node_id)
	if current_world_position != Vector2.ZERO:
		_route_layout_offset = _desired_focus_offset_for_world_position(current_world_position)
	if has_pending_roadside_visual_state() and not _roadside_transition_in_flight:
		_route_layout_offset = Vector2(_roadside_visual_state.get("offset", _route_layout_offset))


func request_next_refresh_full_recompose() -> void:
	_force_next_layout_recompose = true
	_allow_large_resize_recompose_once = true


func render(run_state) -> void:
	if _route_models_cache.is_empty():
		return
	for index in range(ROUTE_BUTTON_NODE_NAMES.size()):
		var route_button: Button = _scene_node("%s/%s" % [ROUTE_GRID_PATH, ROUTE_BUTTON_NODE_NAMES[index]]) as Button
		if route_button == null or index >= _route_models_cache.size():
			continue
		var model: Dictionary = _route_models_cache[index]
		route_button.visible = bool(model.get("visible", false))
		route_button.disabled = bool(model.get("disabled", true))
		var route_label: String = String(model.get("text", ""))
		route_button.text = route_label
		route_button.tooltip_text = ""
		route_button.set_meta("target_node_id", int(model.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)))
		_update_route_marker_view(index, model)
	_layout_route_grid()
	_update_current_marker_view(run_state)
	_refresh_route_roads()
	if not _route_selection_in_flight:
		_sync_walker_visual_state()


func resolve_target_node_id(button_node_name: String) -> int:
	var button: Button = _scene_node("%s/%s" % [ROUTE_GRID_PATH, button_node_name]) as Button
	if button == null:
		return MapRuntimeStateScript.NO_PENDING_NODE_ID
	return int(button.get_meta("target_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))


func resolve_focused_node_id(run_state) -> int:
	if _active_route_index >= 0 and _active_route_index < _route_models_cache.size():
		return int(_route_models_cache[_active_route_index].get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	if _hovered_route_index >= 0 and _hovered_route_index < _route_models_cache.size():
		return int(_route_models_cache[_hovered_route_index].get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	if run_state == null or run_state.map_runtime_state == null:
		return MapRuntimeStateScript.NO_PENDING_NODE_ID
	return int(run_state.map_runtime_state.current_node_id)


func is_selection_in_flight() -> bool:
	return _route_selection_in_flight


func begin_selection() -> void:
	_route_selection_in_flight = true


func finish_selection() -> void:
	_route_selection_in_flight = false


func has_pending_roadside_visual_state() -> bool:
	return not _roadside_visual_state.is_empty() and int(_roadside_visual_state.get("target_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)) != MapRuntimeStateScript.NO_PENDING_NODE_ID


func clear_pending_roadside_visual_state() -> void:
	_roadside_visual_state = {}
	_roadside_transition_in_flight = false
	if not _route_selection_in_flight:
		_active_route_index = -1


func prime_roadside_visual_state(current_node_id: int, target_node_id: int) -> void:
	if current_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID or target_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
		clear_pending_roadside_visual_state()
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


func is_roadside_transition_in_flight() -> bool:
	return _roadside_transition_in_flight


func set_roadside_transition_in_flight(value: bool) -> void:
	_roadside_transition_in_flight = value


func stop_walker_walk_cycle() -> void:
	_walker_cycle_token += 1


func animate_route_selection(button_node_name: String, target_node_id: int, move_to_node_callback: Callable) -> void:
	await _run_route_selection(button_node_name, target_node_id, move_to_node_callback)


func animate_pending_roadside_continuation() -> void:
	await _run_pending_roadside_continuation()


func _run_route_selection(button_node_name: String, target_node_id: int, move_to_node_callback: Callable) -> void:
	var route_index: int = ROUTE_BUTTON_NODE_NAMES.find(button_node_name)
	if route_index < 0:
		move_to_node_callback.call(target_node_id)
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
		move_to_node_callback.call(target_node_id)
		return

	_set_walker_facing(target_center.x >= start_center.x)
	var target_world_position: Vector2 = _get_node_world_position(target_node_id)
	var target_offset: Vector2 = _desired_focus_offset_for_world_position(target_world_position)
	await _animate_route_move_camera_follow(start_center, target_center, target_offset, current_node_id, target_node_id)

	stop_walker_walk_cycle()
	_set_walker_texture(MAP_WALKER_IDLE_TEXTURE)
	_reset_walker_stride_visuals()
	if _owner != null and _owner.is_inside_tree():
		await _owner.get_tree().create_timer(WALKER_ARRIVAL_PAUSE).timeout

	move_to_node_callback.call(target_node_id)
	if not has_pending_roadside_visual_state():
		_active_route_index = -1
	_refresh_route_roads()

	if _owner != null and _owner.is_inside_tree() and _owner.get_tree().current_scene == _owner:
		_sync_walker_visual_state()


func _run_pending_roadside_continuation() -> void:
	if not has_pending_roadside_visual_state():
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
	stop_walker_walk_cycle()
	_set_walker_texture(MAP_WALKER_IDLE_TEXTURE)
	_reset_walker_stride_visuals()
	if _owner != null and _owner.is_inside_tree():
		await _owner.get_tree().create_timer(WALKER_ARRIVAL_PAUSE).timeout


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


func _update_route_marker_view(index: int, model: Dictionary) -> void:
	if index < 0 or index >= ROUTE_MARKER_NODE_NAMES.size():
		return
	var marker_rect: TextureRect = _scene_node("%s/%s" % [ROUTE_GRID_PATH, ROUTE_MARKER_NODE_NAMES[index]]) as TextureRect
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


func _update_current_marker_view(run_state) -> void:
	if _current_marker == null or run_state == null:
		return
	var current_family: String = String(run_state.map_runtime_state.get_current_node_family())
	_current_marker.visible = true
	_current_marker.texture = null
	_apply_marker_visual_state(_current_marker, "", current_family, "", "", "current", false, false)


func _apply_marker_visual_state(marker_rect: TextureRect, icon_texture_path: String, node_family: String, family_label: String, chip_text: String, state_semantic: String, is_disabled: bool, is_selected: bool) -> void:
	if marker_rect == null:
		return
	var is_preview_node: bool = is_disabled and state_semantic == "open"
	marker_rect.modulate = MapBoardStyleScript.marker_modulate_for_semantic(state_semantic, is_disabled)
	var node_plate: PanelContainer = marker_rect.get_node_or_null("NodePlate") as PanelContainer
	if node_plate != null:
		node_plate.visible = state_semantic != "current"
		node_plate.size = NODE_PLATE_SIZE
		node_plate.position = (marker_rect.size - NODE_PLATE_SIZE) * 0.5
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
	var chip_label: Label = chip_panel.get_node_or_null("StateChipLabel") as Label if chip_panel != null else null
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
			chip_panel.position = Vector2(marker_rect.size.x - STATE_PIP_SIZE.x - 8.0, marker_rect.size.y - STATE_PIP_SIZE.y - 8.0) if state_semantic == "resolved" else Vector2(marker_rect.size.x - STATE_PIP_SIZE.x - 8.0, 8.0)
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
	if _board_canvas != null:
		_board_canvas.call("set_composition", _board_composition_cache)
		_board_canvas.call("set_board_offset", _route_layout_offset)
		_board_canvas.call("set_interaction_state", _active_target_node_id(), _hovered_target_node_id())


func _refresh_route_board_offset() -> void:
	if _board_canvas == null:
		return
	_board_canvas.call("set_board_offset", _route_layout_offset)


func _layout_route_grid() -> void:
	var route_grid: Control = get_route_grid()
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
		var marker_rect: TextureRect = _scene_node("%s/%s" % [ROUTE_GRID_PATH, ROUTE_MARKER_NODE_NAMES[index]]) as TextureRect
		var route_button: Button = _scene_node("%s/%s" % [ROUTE_GRID_PATH, ROUTE_BUTTON_NODE_NAMES[index]]) as Button
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


func _build_board_graph_signature(run_state) -> String:
	if run_state == null or run_state.map_runtime_state == null:
		return ""
	var map_runtime_state = run_state.map_runtime_state
	var graph_snapshot: Array[Dictionary] = map_runtime_state.build_realized_graph_snapshots()
	var normalized_nodes: Array[Dictionary] = []
	for node_variant in graph_snapshot:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node_entry: Dictionary = node_variant
		var adjacent_node_ids: Array[int] = []
		for adjacent_variant in node_entry.get("adjacent_node_ids", []):
			adjacent_node_ids.append(int(adjacent_variant))
		adjacent_node_ids.sort()
		normalized_nodes.append({
			"node_id": int(node_entry.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)),
			"node_family": String(node_entry.get("node_family", "")),
			"adjacent_node_ids": adjacent_node_ids,
		})
	normalized_nodes.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("node_id", -1)) < int(right.get("node_id", -1))
	)
	return JSON.stringify({
		"run_seed": int(run_state.run_seed),
		"stage_index": int(run_state.stage_index),
		"template_id": String(map_runtime_state.get_active_template_id()),
		"nodes": normalized_nodes,
	})


func _build_board_visibility_signature(run_state) -> String:
	if run_state == null or run_state.map_runtime_state == null:
		return ""
	return JSON.stringify({
		"current_node_id": int(run_state.map_runtime_state.current_node_id),
		"nodes": run_state.map_runtime_state.build_node_snapshots(),
	})


func _build_board_composition(run_state, stable_layout: Dictionary = {}) -> Dictionary:
	var route_grid: Control = get_route_grid()
	if route_grid == null or _board_composer == null:
		return {}
	return _board_composer.call(
		"compose",
		run_state,
		route_grid.size,
		BOARD_FOCUS_ANCHOR_FACTOR,
		Vector2(route_grid.size.x * BOARD_MAX_OFFSET_FACTOR.x, route_grid.size.y * BOARD_MAX_OFFSET_FACTOR.y),
		stable_layout
	)


func _marker_position_for_route_model(model: Dictionary, emergency_slot_index: int, emergency_slot_factor_by_visible_index: Dictionary, board_size: Vector2) -> Vector2:
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
	return board_size * slot_factor - (ROUTE_MARKER_SIZE * 0.5) + _route_layout_offset


func _emergency_board_anchor_marker_position(board_size: Vector2) -> Vector2:
	return board_size * BOARD_FOCUS_ANCHOR_FACTOR - (ROUTE_MARKER_SIZE * 0.5)


func _desired_focus_offset_for_world_position(world_position: Vector2) -> Vector2:
	var route_grid: Control = get_route_grid()
	var context_world_position: Vector2 = MapFocusHelperScript.focus_context_world_position(_board_composition_cache, world_position)
	var context_blend: float = MapFocusHelperScript.context_blend_for_positions(route_grid, world_position, context_world_position, BOARD_FOCUS_CONTEXT_BLEND_MIN, BOARD_FOCUS_CONTEXT_BLEND_MAX)
	return MapFocusHelperScript.desired_focus_offset(route_grid, _route_layout_offset, world_position, BOARD_FOCUS_ANCHOR_FACTOR, BOARD_MAX_OFFSET_FACTOR, BOARD_FOCUS_DEADZONE_FACTOR, BOARD_FOCUS_DAMPING, context_world_position, context_blend)


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


func _sync_walker_visual_state() -> void:
	if has_pending_roadside_visual_state():
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
	return center - Vector2(WALKER_ROOT_SIZE.x * 0.5, WALKER_ROOT_SIZE.y * 0.82)


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
	while token == _walker_cycle_token and _owner != null and _owner.is_inside_tree():
		_set_walker_texture(MAP_WALKER_WALK_A_TEXTURE if frame_index % 2 == 0 else MAP_WALKER_WALK_B_TEXTURE)
		frame_index += 1
		await _owner.get_tree().create_timer(_walker_frame_interval).timeout


func _animate_route_move_camera_follow(start_center: Vector2, target_center: Vector2, target_offset: Vector2, current_node_id: int, target_node_id: int) -> void:
	_route_move_world_path = _build_route_move_world_path(current_node_id, target_node_id, start_center - _route_layout_offset, target_center - _route_layout_offset)
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
	var tween: Tween = _owner.create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(Callable(self, "_update_route_move_progress"), 0.0, 1.0, move_duration)
	await tween.finished


func _animate_route_move_camera_follow_segment(current_node_id: int, target_node_id: int, target_offset: Vector2, start_progress: float, end_progress: float) -> void:
	_route_move_world_path = _build_route_move_world_path(current_node_id, target_node_id, _get_node_world_position(current_node_id), _get_node_world_position(target_node_id))
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
	var tween: Tween = _owner.create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(Callable(self, "_update_route_move_progress"), 0.0, 1.0, move_duration)
	await tween.finished


func _update_route_move_progress(progress: float) -> void:
	var travel_progress: float = lerpf(_route_move_sample_start_progress, _route_move_sample_end_progress, _ease_in_out_sine(progress))
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
	return clampf(ROUTE_MOVE_BASE_DURATION + (distance / ROUTE_MOVE_PIXELS_PER_SECOND), ROUTE_MOVE_MIN_DURATION, ROUTE_MOVE_MAX_DURATION)


func _route_camera_follow_progress(progress: float) -> float:
	var delayed_progress: float = clampf((progress - ROUTE_MOVE_CAMERA_DELAY_RATIO) / max(0.001, 1.0 - ROUTE_MOVE_CAMERA_DELAY_RATIO), 0.0, 1.0)
	return _ease_in_out_sine(delayed_progress)


func _build_route_move_world_path(current_node_id: int, target_node_id: int, fallback_start_world: Vector2, fallback_target_world: Vector2) -> PackedVector2Array:
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
	if not has_pending_roadside_visual_state():
		return {}
	var current_node_id: int = int(_roadside_visual_state.get("current_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	var target_node_id: int = int(_roadside_visual_state.get("target_node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	if current_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID or target_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
		return {}
	var start_world: Vector2 = _get_node_world_position(current_node_id)
	var target_world: Vector2 = _get_node_world_position(target_node_id)
	var route_path: PackedVector2Array = _build_route_move_world_path(current_node_id, target_node_id, start_world, target_world)
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
		return {"point": fallback_point, "direction": Vector2.RIGHT}
	var travel_distance: float = _route_move_path_length * clampf(progress, 0.0, 1.0)
	var current_sample: Dictionary = _sample_polyline_at_distance(_route_move_world_path, travel_distance)
	var lookahead_distance: float = min(_route_move_path_length, travel_distance + max(18.0, _route_move_path_length * 0.05))
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
	var bob_amplitude: float = min(WALKER_STRIDE_BOB_MAX, WALKER_STRIDE_BOB_MAX * clampf(_route_move_path_length / 220.0, 0.45, 1.0))
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
	var marker_rect: TextureRect = _scene_node("%s/%s" % [ROUTE_GRID_PATH, ROUTE_MARKER_NODE_NAMES[index]]) as TextureRect
	if marker_rect == null:
		return Vector2.ZERO
	return marker_rect.position + (marker_rect.size * 0.5)


func _set_texture_rect_texture(node_path: String, texture: Texture2D) -> void:
	var texture_rect: TextureRect = _scene_node(node_path) as TextureRect
	if texture_rect != null:
		texture_rect.texture = texture


func _scene_node(path: String) -> Node:
	if not _scene_node_getter.is_valid():
		return null
	return _scene_node_getter.call(path)
