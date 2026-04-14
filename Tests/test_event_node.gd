# Layer: Tests
extends SceneTree
class_name TestEventNode

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const ROUTE_BUTTON_NODE_NAMES: PackedStringArray = [
	"CombatNodeButton",
	"RewardNodeButton",
	"RestNodeButton",
	"MerchantNodeButton",
	"BlacksmithNodeButton",
	"BossNodeButton",
]
const EVENT_ICON_PATH := "res://Assets/Icons/icon_node_marker.svg"

var _phase: int = 0
var _phase_frame_count: int = 0


func _init() -> void:
	_ensure_autoload_like_nodes()
	change_scene_to_file("res://scenes/main_menu.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	_phase_frame_count += 1

	match _phase:
		0:
			if _is_scene("MainMenu"):
				_get_bootstrap().call("reset_run_state_for_new_run")
				_get_bootstrap().call("get_flow_manager").call("restore_state", FlowStateScript.Type.MAP_EXPLORE)
				_get_scene_router().call("route_to_state_for_restore", FlowStateScript.Type.MAP_EXPLORE)
				_advance_phase(1)
		1:
			if _is_scene("MapExplore"):
				var run_state: RunState = _get_run_state()
				_require(run_state != null, "Expected RunState on MapExplore.")
				run_state.player_hp = 40
				var event_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "event")
				_require(event_node_id >= 0, "Expected one event node on the procedural stage.")
				_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, event_node_id)
				current_scene.call("_refresh_ui")
				_press_map_route_containing("Roadside Encounter")
				_advance_phase(2)
		2:
			if _is_scene("Event"):
				_require(_current_state() == FlowStateScript.Type.EVENT, "Expected dedicated Event flow state after resolving an event node.")
				_require_modal_popup_shell()
				_require_audio_player_stream("UiConfirmSfxPlayer")
				_require_audio_player_stream("PanelOpenSfxPlayer")
				_require_audio_player_stream("EventMusicPlayer")
				var event_state: RefCounted = _get_event_state()
				_require(event_state != null, "Expected EventState on the dedicated Event scene.")
				_require(String(event_state.template_definition_id) == "forest_shrine_echo", "Expected deterministic stage-1 event template selection.")
				_require(event_state.choices.size() == 2, "Expected EventState to expose exactly 2 choices.")

				var title_label: Label = current_scene.get_node("Margin/VBox/HeaderStack/TitleLabel") as Label
				var hint_label: Label = current_scene.get_node("Margin/VBox/HeaderStack/HintLabel") as Label
				var choice_a_card: Control = current_scene.get_node("Margin/VBox/CardsRow/ChoiceACard") as Control
				var choice_b_card: Control = current_scene.get_node("Margin/VBox/CardsRow/ChoiceBCard") as Control
				var choice_a_button: Button = current_scene.get_node("Margin/VBox/CardsRow/ChoiceACard/VBox/ChoiceAButton") as Button
				var choice_b_button: Button = current_scene.get_node("Margin/VBox/CardsRow/ChoiceBCard/VBox/ChoiceBButton") as Button
				var choice_a_title: Label = current_scene.get_node("Margin/VBox/CardsRow/ChoiceACard/VBox/ChoiceTitleLabel") as Label
				var choice_b_title: Label = current_scene.get_node("Margin/VBox/CardsRow/ChoiceBCard/VBox/ChoiceTitleLabel") as Label

				_require(title_label.text == "The Shrine in the Moss", "Expected event title to render from EventState.")
				_require(String(hint_label.text).contains("Mid-roadside-save"), "Expected roadside-save policy hint to stay explicit in the scene shell.")
				_require(choice_a_card.visible and not choice_a_button.disabled, "Expected first event card to stay active.")
				_require(choice_b_card.visible and not choice_b_button.disabled, "Expected second event card to stay active.")
				_require(choice_a_title.text == "Wash the road dust away", "Expected first roadside-encounter choice title from content.")
				_require(choice_b_title.text == "Turn over the offering bowl", "Expected second roadside-encounter choice title from content.")
				_require_button_icon(choice_a_button, EVENT_ICON_PATH, "Expected event choice A to expose the event icon floor.")
				_require_button_icon(choice_b_button, EVENT_ICON_PATH, "Expected event choice B to expose the event icon floor.")

				choice_a_button.emit_signal("pressed")
				_advance_phase(3)
		3:
			if _is_scene("MapExplore"):
				var run_state_after_event: RunState = _get_run_state()
				_require(_current_state() == FlowStateScript.Type.MAP_EXPLORE, "Expected event resolution to return to MapExplore.")
				_require(_get_event_state() == null, "Expected EventState to clear after claiming an event outcome.")
				_require(run_state_after_event.player_hp == 50, "Expected the healing event choice to persist on RunState.")
				print("test_event_node: all assertions passed")
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


func _get_bootstrap() -> Node:
	return get_root().get_node_or_null("AppBootstrap")


func _get_scene_router() -> Node:
	return get_root().get_node_or_null("SceneRouter")


func _get_run_state() -> RunState:
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.call("get_run_state")


func _get_event_state() -> RefCounted:
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return null
	return bootstrap.call("get_event_state")


func _current_state() -> int:
	var bootstrap: Node = _get_bootstrap()
	if bootstrap == null:
		return -1
	var flow_manager: Node = bootstrap.call("get_flow_manager")
	if flow_manager == null:
		return -1
	return int(flow_manager.call("get_current_state"))


func _is_scene(expected_name: String) -> bool:
	return current_scene != null and current_scene.name == expected_name


func _press_map_route_containing(label_fragment: String) -> void:
	for button_name in ROUTE_BUTTON_NODE_NAMES:
		var button: Button = current_scene.get_node_or_null("Margin/VBox/RouteGrid/%s" % button_name) as Button
		if button == null or not button.visible or button.disabled:
			continue
		var route_label: String = button.text if not button.text.is_empty() else button.tooltip_text
		if route_label.contains(label_fragment):
			button.emit_signal("pressed")
			return
	_fail("Expected a visible enabled route button containing %s." % label_fragment)


func _find_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == node_family:
			return int(node_snapshot.get("node_id", -1))
	return -1


func _prepare_current_node_adjacent_to_target(map_runtime_state: RefCounted, target_node_id: int) -> void:
	var path: Array[int] = _build_path_between_nodes(map_runtime_state, map_runtime_state.current_node_id, target_node_id)
	_require(path.size() >= 2, "Expected a valid runtime path to the target node.")
	for path_index in range(1, path.size() - 1):
		var node_id: int = path[path_index]
		map_runtime_state.move_to_node(node_id)
		map_runtime_state.mark_node_resolved(node_id)


func _build_path_between_nodes(map_runtime_state: RefCounted, start_node_id: int, target_node_id: int) -> Array[int]:
	var queued_paths: Array = [[start_node_id]]
	var visited: Dictionary = {}
	while not queued_paths.is_empty():
		var path: Array = queued_paths.pop_front()
		var current_node_id: int = int(path[path.size() - 1])
		if current_node_id == target_node_id:
			var typed_path: Array[int] = []
			for node_id_variant in path:
				typed_path.append(int(node_id_variant))
			return typed_path
		if visited.has(current_node_id):
			continue
		visited[current_node_id] = true
		for adjacent_node_id in map_runtime_state.get_adjacent_node_ids(current_node_id):
			if visited.has(adjacent_node_id):
				continue
			var next_path: Array = path.duplicate()
			next_path.append(adjacent_node_id)
			queued_paths.append(next_path)
	return []


func _advance_phase(new_phase: int) -> void:
	_phase = new_phase
	_phase_frame_count = 0


func _require_texture_rect_present(node_name: String) -> void:
	var texture_rect: TextureRect = current_scene.get_node_or_null(node_name) as TextureRect
	_require(texture_rect != null, "Expected TextureRect %s to exist on %s." % [node_name, current_scene.name])
	_require(texture_rect.visible, "Expected TextureRect %s to stay visible on %s." % [node_name, current_scene.name])
	_require(texture_rect.texture != null, "Expected TextureRect %s to have a texture on %s." % [node_name, current_scene.name])


func _require_modal_popup_shell() -> void:
	var scrim: ColorRect = current_scene.get_node_or_null("Scrim") as ColorRect
	_require(scrim != null, "Expected Scrim to exist on %s." % current_scene.name)
	_require(scrim.visible, "Expected Scrim to stay visible on %s." % current_scene.name)
	var shell: PanelContainer = current_scene.get_node_or_null("Margin/ContentShell") as PanelContainer
	_require(shell != null, "Expected ContentShell popup to exist on %s." % current_scene.name)
	_require(shell.visible, "Expected ContentShell popup to stay visible on %s." % current_scene.name)
	for node_name in ["BackgroundFar", "BackgroundMid", "BackgroundOverlay"]:
		var texture_rect: TextureRect = current_scene.get_node_or_null(node_name) as TextureRect
		if texture_rect != null:
			_require(texture_rect.visible, "Expected %s to stay visible on %s." % [node_name, current_scene.name])
			_require(texture_rect.texture != null, "Expected %s to keep a texture on %s." % [node_name, current_scene.name])


func _require_audio_player_stream(node_name: String) -> void:
	var player: AudioStreamPlayer = current_scene.get_node_or_null(node_name) as AudioStreamPlayer
	_require(player != null, "Expected AudioStreamPlayer %s to exist on %s." % [node_name, current_scene.name])
	_require(player.stream != null, "Expected AudioStreamPlayer %s to have a stream on %s." % [node_name, current_scene.name])


func _require_button_icon(button: Button, expected_path: String, message: String) -> void:
	_require(button != null, "Expected button before checking icon path.")
	_require(button.icon != null, message)
	_require(button.icon.resource_path == expected_path, "%s Got %s." % [message, button.icon.resource_path])


func _assert_phase_timeout() -> void:
	if _phase_frame_count < 120:
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
