# Layer: Tests
extends SceneTree
class_name TestEventNode

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const SafeMenuLauncherStyleScript = preload("res://Game/UI/safe_menu_launcher_style.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")
const ROUTE_BUTTON_NODE_NAMES: PackedStringArray = [
	"CombatNodeButton",
	"RewardNodeButton",
	"RestNodeButton",
	"MerchantNodeButton",
	"BlacksmithNodeButton",
	"BossNodeButton",
]
const SAFE_MENU_LAUNCHER_BUTTON_PATH := "SafeMenuOverlay/MenuLauncherButton"
const PHASE_TIMEOUT_FRAMES := 240

var _phase: int = 0
var _phase_frame_count: int = 0
var _is_finishing: bool = false


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
				run_state.configure_run_seed(1)
				run_state.player_hp = 40
				var event_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "event")
				_require(event_node_id >= 0, "Expected one event node on the procedural stage.")
				_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, event_node_id)
				current_scene.call("_refresh_ui")
				_press_map_route_containing("Trail Event")
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
				_require(String(event_state.source_context) == "node_event", "Expected planned event nodes to keep the dedicated node-event source context.")
				_require(String(event_state.template_definition_id) == "forest_shrine_echo", "Expected deterministic stage-1 event template selection.")
				_require(event_state.choices.size() == 2, "Expected EventState to expose exactly 2 choices.")
				var event_root: Node = _get_scene_root("Event")

				var title_label: Label = event_root.get_node("Margin/VBox/OffersShell/VBox/HeaderRow/HeaderCard/HeaderStack/TitleLabel") as Label
				var context_label: Label = event_root.get_node("Margin/VBox/OffersShell/VBox/HeaderRow/HeaderCard/HeaderStack/ContextLabel") as Label
				var hint_label: Label = event_root.get_node("Margin/VBox/OffersShell/VBox/HeaderRow/HeaderCard/HeaderStack/HintLabel") as Label
				var choice_a_card: Control = event_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceACard") as Control
				var choice_b_card: Control = event_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceBCard") as Control
				var choice_a_button: Button = event_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceACard/VBox/ChoiceAButton") as Button
				var choice_b_button: Button = event_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceBCard/VBox/ChoiceBButton") as Button
				var choice_a_title: Label = event_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceACard/VBox/ChoiceTitleLabel") as Label
				var choice_b_title: Label = event_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceBCard/VBox/ChoiceTitleLabel") as Label
				var choice_a_detail: Label = event_root.get_node("Margin/VBox/OffersShell/VBox/CardsRow/ChoiceACard/VBox/ChoiceDetailLabel") as Label
				var launcher_button: Button = event_root.get_node_or_null(SAFE_MENU_LAUNCHER_BUTTON_PATH) as Button
				var run_status_card: PanelContainer = event_root.get_node_or_null("Margin/VBox/OffersShell/VBox/HeaderRow/RunStatusCard") as PanelContainer
				var tooltip_panel: PanelContainer = event_root.get_node_or_null("InventoryTooltipPanel") as PanelContainer
				var tooltip_label: Label = tooltip_panel.get_node_or_null("InventoryTooltipLabel") as Label if tooltip_panel != null else null

				_require(title_label.text == "The Shrine in the Moss", "Expected event title to render from EventState.")
				_require(context_label.text == "Pick 1 result.", "Expected planned event nodes to keep the scene shell context compact.")
				_require(hint_label.text == "Hover for details.", "Expected event scene hint text to keep the hover guidance compact.")
				_require(run_status_card != null and not run_status_card.visible, "Expected event overlay to hide the duplicate run-status card because the shared top bar already shows it.")
				_require(choice_a_card.visible and not choice_a_button.disabled, "Expected first event card to stay active.")
				_require(choice_b_card.visible and not choice_b_button.disabled, "Expected second event card to stay active.")
				_require(launcher_button != null and launcher_button.visible, "Expected Event to expose the shared safe menu launcher.")
				var launcher_metrics: Dictionary = SafeMenuLauncherStyleScript.resolve_launcher_metrics_for_viewport(current_scene.get_viewport_rect().size)
				var expected_dimensions: Vector2 = Vector2(launcher_metrics.get("dimensions", Vector2.ZERO))
				_require(launcher_button.size.is_equal_approx(expected_dimensions), "Expected Event safe menu launcher to keep the shared launcher dimensions.")
				_require(launcher_button.get_theme_constant("icon_max_width") == int(launcher_metrics.get("icon_size", -1)), "Expected Event safe menu launcher to keep the shared icon scale.")
				_require(choice_a_title.text == "Wash the road dust away", "Expected first roadside-encounter choice title from content.")
				_require(choice_b_title.text == "Turn over the offering bowl", "Expected second roadside-encounter choice title from content.")
				_require(choice_a_detail.text == "Recover 10 HP.", "Expected event card detail to stay short and outcome-first.")
				var choice_a_tooltip_text: String = String(choice_a_button.get_meta("custom_tooltip_text", ""))
				var choice_b_tooltip_text: String = String(choice_b_button.get_meta("custom_tooltip_text", ""))
				_require(not choice_a_tooltip_text.is_empty(), "Expected first event choice button to expose custom hover tooltip copy.")
				_require(not choice_b_tooltip_text.is_empty(), "Expected second event choice button to expose custom hover tooltip copy.")
				_require(tooltip_panel != null and tooltip_label != null, "Expected Event to create the shared tooltip bubble shell.")
				choice_a_button.emit_signal("mouse_entered")
				_require(tooltip_panel.visible, "Expected event choice hover to show the shared tooltip bubble.")
				_require(tooltip_label.text == choice_a_tooltip_text, "Expected event choice hover bubble to mirror the button tooltip copy.")
				choice_a_button.emit_signal("mouse_exited")
				_require(not tooltip_panel.visible, "Expected event choice hover bubble to hide after pointer exit.")
				_require_button_icon(choice_a_button, UiAssetPathsScript.build_effect_icon_texture_path(String(event_state.choices[0].get("effect_type", "")), String(event_state.choices[0].get("inventory_family", ""))), "Expected event choice A to expose the effect icon floor.")
				_require_button_icon(choice_b_button, UiAssetPathsScript.build_effect_icon_texture_path(String(event_state.choices[1].get("effect_type", "")), String(event_state.choices[1].get("inventory_family", ""))), "Expected event choice B to expose the effect icon floor.")

				choice_a_button.emit_signal("pressed")
				_advance_phase(3)
		3:
			if _is_scene("MapExplore"):
				var run_state_after_event: RunState = _get_run_state()
				_require(_current_state() == FlowStateScript.Type.MAP_EXPLORE, "Expected event resolution to return to MapExplore.")
				_require(_get_event_state() == null, "Expected EventState to clear after claiming an event outcome.")
				_require(run_state_after_event.player_hp == 50, "Expected the healing event choice to persist on RunState.")
				await _finish_success("test_event_node")

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
	if current_scene == null:
		return false
	if expected_name == "MapExplore":
		return current_scene.name == "MapExplore" and _get_visible_overlay_root() == null
	return _get_scene_root(expected_name) != null


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
	var scene_root: Node = _get_scene_root()
	var texture_rect: TextureRect = scene_root.get_node_or_null(node_name) as TextureRect
	_require(texture_rect != null, "Expected TextureRect %s to exist on %s." % [node_name, scene_root.name])
	_require(texture_rect.visible, "Expected TextureRect %s to stay visible on %s." % [node_name, scene_root.name])
	_require(texture_rect.texture != null, "Expected TextureRect %s to have a texture on %s." % [node_name, scene_root.name])


func _require_modal_popup_shell() -> void:
	var scene_root: Node = _get_scene_root()
	var scrim: ColorRect = scene_root.get_node_or_null("Scrim") as ColorRect
	_require(scrim != null, "Expected Scrim to exist on %s." % scene_root.name)
	_require(scrim.visible, "Expected Scrim to stay visible on %s." % scene_root.name)
	var margin: Control = scene_root.get_node_or_null("Margin") as Control
	_require(margin != null, "Expected Margin popup root to exist on %s." % scene_root.name)
	_require(margin.visible, "Expected Margin popup root to stay visible on %s." % scene_root.name)
	var shell: PanelContainer = scene_root.get_node_or_null("Margin/ContentShell") as PanelContainer
	var uses_full_scene_shell: bool = shell != null and shell.visible
	for node_name in ["BackgroundFar", "BackgroundMid", "BackgroundOverlay"]:
		var texture_rect: TextureRect = scene_root.get_node_or_null(node_name) as TextureRect
		if texture_rect != null:
			if uses_full_scene_shell:
				_require(texture_rect.visible, "Expected %s to stay visible on full-scene %s." % [node_name, scene_root.name])
			else:
				_require(not texture_rect.visible, "Expected %s to stay hidden behind overlay cards on %s." % [node_name, scene_root.name])
			_require(texture_rect.texture != null, "Expected %s to keep a texture on %s." % [node_name, scene_root.name])


func _require_audio_player_stream(node_name: String) -> void:
	var scene_root: Node = _get_scene_root()
	var player: AudioStreamPlayer = scene_root.get_node_or_null(node_name) as AudioStreamPlayer
	_require(player != null, "Expected AudioStreamPlayer %s to exist on %s." % [node_name, scene_root.name])
	_require(player.stream != null, "Expected AudioStreamPlayer %s to have a stream on %s." % [node_name, scene_root.name])


func _require_button_icon(button: Button, expected_path: String, message: String) -> void:
	_require(button != null, "Expected button before checking icon path.")
	_require(button.icon != null, message)
	_require(button.icon.resource_path == expected_path, "%s Got %s." % [message, button.icon.resource_path])


func _assert_phase_timeout() -> void:
	if _phase_frame_count < PHASE_TIMEOUT_FRAMES:
		return
	_fail("Phase %d timed out on scene %s." % [_phase, _stringify_current_scene()])


func _stringify_current_scene() -> String:
	if current_scene == null:
		return "<null>"
	var overlay_root: Node = _get_visible_overlay_root()
	if overlay_root != null:
		return "%s (%s) + %s" % [current_scene.name, current_scene.scene_file_path, overlay_root.name]
	return "%s (%s)" % [current_scene.name, current_scene.scene_file_path]


func _get_scene_root(expected_name: String = "") -> Node:
	if current_scene == null:
		return null
	if expected_name.is_empty():
		var overlay_root: Node = _get_visible_overlay_root()
		return overlay_root if overlay_root != null else current_scene
	if current_scene.name == expected_name:
		return current_scene
	if current_scene.name != "MapExplore":
		return null
	var overlay_root_name: String = _overlay_root_name(expected_name)
	if overlay_root_name.is_empty():
		return null
	return _find_visible_overlay_root(overlay_root_name)


func _get_visible_overlay_root() -> Node:
	if current_scene == null or current_scene.name != "MapExplore":
		return null
	for overlay_root_name in ["EventOverlay", "RewardOverlay", "SupportOverlay", "LevelUpOverlay"]:
		var overlay_root: Control = _find_visible_overlay_root(overlay_root_name)
		if overlay_root != null:
			return overlay_root
	return null


func _find_visible_overlay_root(overlay_root_name: String) -> Control:
	if current_scene == null:
		return null
	var exact_match: Control = current_scene.get_node_or_null(overlay_root_name) as Control
	if exact_match != null and exact_match.visible:
		return exact_match
	for child in current_scene.get_children():
		var overlay_root: Control = child as Control
		if overlay_root == null or not overlay_root.visible:
			continue
		if String(overlay_root.name).begins_with(overlay_root_name):
			return overlay_root
	return null


func _overlay_root_name(expected_name: String) -> String:
	match expected_name:
		"Event":
			return "EventOverlay"
		"Reward":
			return "RewardOverlay"
		"SupportInteraction":
			return "SupportOverlay"
		"LevelUp":
			return "LevelUpOverlay"
		_:
			return ""


func _finish_success(test_name: String) -> void:
	if _is_finishing:
		return
	_is_finishing = true
	var process_frame_handler := Callable(self, "_on_process_frame")
	if process_frame.is_connected(process_frame_handler):
		process_frame.disconnect(process_frame_handler)
	print("%s: all assertions passed" % test_name)
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _fail(message: String) -> void:
	push_error(message)
	print(message)
	quit(1)
