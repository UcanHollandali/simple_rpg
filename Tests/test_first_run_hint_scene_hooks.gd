# Layer: Tests
extends SceneTree
class_name TestFirstRunHintSceneHooks

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const RunSessionCoordinatorScript = preload("res://Game/Application/run_session_coordinator.gd")
const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")
const RunStatusStripScript = preload("res://Game/UI/run_status_strip.gd")
const MapExplorePackedScene: PackedScene = preload("res://scenes/map_explore.tscn")
const CombatPackedScene: PackedScene = preload("res://scenes/combat.tscn")
const EventPackedScene: PackedScene = preload("res://scenes/event.tscn")
const SupportInteractionPackedScene: PackedScene = preload("res://scenes/support_interaction.tscn")

const COMBAT_DEFENSE_BUTTON_PATH := "Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionButton"
const COMBAT_TECHNIQUE_BUTTON_PATH := "Margin/VBox/Buttons/ActionCardsRow/TechniqueActionCard/TechniqueActionVBox/TechniqueActionButton"
const COMBAT_RIGHT_HAND_SWAP_BUTTON_PATH := "Margin/VBox/SecondaryScroll/SecondaryScrollContent/QuickItemSection/HandSwapPanel/HandSwapVBox/HandSwapSlotButtonsRow/RightHandSwapButton"
const FIRST_RUN_HINT_PANEL_PATH := "FirstRunHintPanel"
const EVENT_CHOICE_BUTTON_NAMES := ["ChoiceAButton", "ChoiceBButton"]
const SUPPORT_ACTION_BUTTON_NAMES := ["ActionAButton", "ActionBButton", "ActionCButton"]
const EVENT_CHOICE_BUTTON_PATHS := [
	"Margin/VBox/OffersShell/VBox/CardsRow/ChoiceACard/VBox/ActionShell/ChoiceAButton",
	"Margin/VBox/OffersShell/VBox/CardsRow/ChoiceBCard/VBox/ActionShell/ChoiceBButton",
]
const SUPPORT_ACTION_BUTTON_PATHS := [
	"Margin/VBox/OffersShell/VBox/ActionsRow/ActionAButton",
	"Margin/VBox/OffersShell/VBox/ActionsRow/ActionBButton",
	"Margin/VBox/OffersShell/VBox/ActionsRow/ActionCButton",
]
const MAP_ROUTE_BUTTON_PATHS := [
	"Margin/VBox/RouteGrid/CombatNodeButton",
	"Margin/VBox/RouteGrid/RewardNodeButton",
	"Margin/VBox/RouteGrid/RestNodeButton",
	"Margin/VBox/RouteGrid/MerchantNodeButton",
	"Margin/VBox/RouteGrid/BlacksmithNodeButton",
]


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	await test_map_scene_hints_trigger_once_without_retrigger()
	await test_combat_scene_defend_hint_keeps_actions_clear()
	await test_combat_scene_technique_hint_keeps_actions_clear()
	await test_combat_scene_hand_swap_hint_keeps_actions_clear()
	await test_map_scene_key_route_hint_triggers_once_without_retrigger()
	await test_hamlet_hint_keeps_support_actions_clear()
	await test_roadside_hint_keeps_event_choices_clear()
	print("test_first_run_hint_scene_hooks: all assertions passed")
	quit()


func test_map_scene_hints_trigger_once_without_retrigger() -> void:
	var bootstrap: AppBootstrapScript = await _install_runtime_nodes()
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE)
	bootstrap.reset_run_state_for_new_run()
	bootstrap.ensure_run_state_initialized()
	var controller: FirstRunHintController = _get_hint_controller(bootstrap)
	controller.reset()
	controller.mark_hint_shown("first_key_required_route")

	var run_state: RunState = bootstrap.get_run_state()
	run_state.inventory_state.load_from_flat_save_dict({
		"inventory_next_slot_id": 12,
		"backpack_slots": [
			{
				"slot_id": 11,
				"inventory_family": "weapon",
				"definition_id": "briar_knife",
				"current_durability": 17,
			},
		],
		"equipped_right_hand_slot": {},
		"equipped_left_hand_slot": {
			"slot_id": 7,
			"inventory_family": "shield",
			"definition_id": "watchman_shield",
		},
		"equipped_armor_slot": {},
		"equipped_belt_slot": {
			"slot_id": 9,
			"inventory_family": "belt",
			"definition_id": "provisioner_belt",
		},
	})

	var map_scene: Control = await _mount_scene(MapExplorePackedScene.instantiate() as Control)
	assert(map_scene != null, "Expected the map scene for first-run hint coverage.")
	await _settle_frames(4)

	assert(
		controller.get_active_hint_id() == "first_left_hand_shield",
		"Expected the map inventory scan to surface the shield hint first."
	)
	assert(
		controller.get_pending_hint_ids() == ["first_left_hand_offhand_weapon", "first_belt_capacity"],
		"Expected map inventory hints to queue offhand and belt guidance behind the shield hint."
	)

	controller.dismiss_active_hint()
	controller.dismiss_active_hint()
	controller.dismiss_active_hint()
	assert(controller.get_active_hint_id().is_empty(), "Expected map inventory hints to fully dismiss.")

	map_scene.call("_refresh_ui")
	await _settle_frames(2)
	assert(
		controller.get_active_hint_id().is_empty() and controller.get_pending_hint_ids().is_empty(),
		"Expected already shown inventory hints not to retrigger on later map refreshes."
	)

	map_scene.call(
		"_on_hunger_threshold_crossed",
		RunStatusStripScript.HUNGER_THRESHOLD_SAFE,
		RunStatusStripScript.HUNGER_THRESHOLD_HUNGRY
	)
	await _settle_frames(2)
	assert(
		controller.get_active_hint_id() == "first_low_hunger_warning",
		"Expected the map hunger-threshold trigger to surface the low-hunger hint."
	)
	controller.dismiss_active_hint()
	map_scene.call(
		"_on_hunger_threshold_crossed",
		RunStatusStripScript.HUNGER_THRESHOLD_SAFE,
		RunStatusStripScript.HUNGER_THRESHOLD_HUNGRY
	)
	await _settle_frames(2)
	assert(
		controller.get_active_hint_id().is_empty(),
		"Expected the low-hunger hint not to retrigger after it was already shown on this save."
	)

	await _clear_current_scene()
	await _remove_runtime_nodes()


func test_combat_scene_defend_hint_keeps_actions_clear() -> void:
	var bootstrap: AppBootstrapScript = await _install_runtime_nodes()
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE)
	bootstrap.reset_run_state_for_new_run()
	bootstrap.ensure_run_state_initialized()
	var controller: FirstRunHintController = _get_hint_controller(bootstrap)
	controller.reset()

	var combat_scene: Control = await _mount_scene(CombatPackedScene.instantiate() as Control)
	assert(combat_scene != null, "Expected the combat scene for first-run defend-hint coverage.")
	await _settle_frames(5)

	assert(
		controller.get_active_hint_id() == "first_combat_defend",
		"Expected entering combat to surface the defend hint once."
	)
	var hint_panel: PanelContainer = _find_first_run_hint_panel()
	var defense_button: Button = combat_scene.get_node_or_null(COMBAT_DEFENSE_BUTTON_PATH) as Button
	assert(hint_panel != null and hint_panel.visible, "Expected a visible first-run hint panel on combat entry.")
	assert(defense_button != null and defense_button.visible and not defense_button.disabled, "Expected the combat defend button to stay active while the hint is visible.")
	var defense_center: Vector2 = defense_button.get_global_rect().get_center()
	assert(
		not hint_panel.get_global_rect().has_point(defense_center),
		"Expected the first-run hint panel not to cover the defend button's primary tap target."
	)

	var combat_flow: CombatFlow = combat_scene.get("_combat_flow") as CombatFlow
	assert(combat_flow != null, "Expected combat flow to be ready for the defend-hint interaction check.")
	var turn_before: int = int(combat_flow.combat_state.current_turn)
	defense_button.emit_signal("pressed")
	await _settle_frames(4)
	assert(
		int(combat_flow.combat_state.current_turn) > turn_before,
		"Expected the defend action to resolve even while the first-run hint stayed on screen."
	)

	controller.dismiss_active_hint()
	assert(
		not controller.request_hint("first_combat_defend"),
		"Expected the defend hint not to requeue after it was already shown once on this save."
	)

	await _clear_current_scene()
	await _remove_runtime_nodes()


func test_combat_scene_technique_hint_keeps_actions_clear() -> void:
	var bootstrap: AppBootstrapScript = await _install_runtime_nodes()
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE)
	bootstrap.reset_run_state_for_new_run()
	bootstrap.ensure_run_state_initialized()
	var controller: FirstRunHintController = _get_hint_controller(bootstrap)
	controller.reset()
	controller.mark_hint_shown("first_combat_defend")

	var run_state: RunState = bootstrap.get_run_state()
	run_state.equipped_technique_definition_id = "sundering_strike"
	run_state.inventory_state.load_from_flat_save_dict({
		"inventory_next_slot_id": 5,
		"backpack_slots": [],
		"equipped_right_hand_slot": {
			"slot_id": 4,
			"inventory_family": "weapon",
			"definition_id": "iron_sword",
			"current_durability": 11,
		},
		"equipped_left_hand_slot": {},
		"equipped_armor_slot": {},
		"equipped_belt_slot": {},
	})

	var combat_scene: Control = await _mount_scene(CombatPackedScene.instantiate() as Control)
	assert(combat_scene != null, "Expected the combat scene for first-run technique-hint coverage.")
	await _settle_frames(5)

	assert(
		controller.get_active_hint_id() == "first_combat_technique",
		"Expected a first equipped technique to surface the technique hint once defend was already shown."
	)
	var hint_panel: PanelContainer = _find_first_run_hint_panel()
	var technique_button: Button = combat_scene.get_node_or_null(COMBAT_TECHNIQUE_BUTTON_PATH) as Button
	assert(hint_panel != null and hint_panel.visible, "Expected a visible first-run hint panel for the technique action.")
	assert(technique_button != null and technique_button.visible and not technique_button.disabled, "Expected the technique action to stay enabled while the hint is visible.")
	var technique_center: Vector2 = technique_button.get_global_rect().get_center()
	assert(
		not hint_panel.get_global_rect().has_point(technique_center),
		"Expected the first-run technique hint panel not to cover the technique button's tap target."
	)

	controller.dismiss_active_hint()
	assert(
		not controller.request_hint("first_combat_technique"),
		"Expected the technique hint not to requeue after it was already shown once on this save."
	)

	await _clear_current_scene()
	await _remove_runtime_nodes()


func test_combat_scene_hand_swap_hint_keeps_actions_clear() -> void:
	var bootstrap: AppBootstrapScript = await _install_runtime_nodes()
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE)
	bootstrap.reset_run_state_for_new_run()
	bootstrap.ensure_run_state_initialized()
	var controller: FirstRunHintController = _get_hint_controller(bootstrap)
	controller.reset()
	controller.mark_hint_shown("first_combat_defend")
	controller.mark_hint_shown("first_combat_technique")

	var run_state: RunState = bootstrap.get_run_state()
	run_state.equipped_technique_definition_id = ""
	run_state.inventory_state.load_from_flat_save_dict({
		"inventory_next_slot_id": 13,
		"backpack_slots": [
			{
				"slot_id": 12,
				"inventory_family": "weapon",
				"definition_id": "splitter_axe",
				"current_durability": 14,
			},
		],
		"equipped_right_hand_slot": {
			"slot_id": 4,
			"inventory_family": "weapon",
			"definition_id": "iron_sword",
			"current_durability": 11,
		},
		"equipped_left_hand_slot": {},
		"equipped_armor_slot": {},
		"equipped_belt_slot": {},
	})

	var combat_scene: Control = await _mount_scene(CombatPackedScene.instantiate() as Control)
	assert(combat_scene != null, "Expected the combat scene for first-run hand-swap hint coverage.")
	await _settle_frames(5)

	assert(
		controller.get_active_hint_id() == "first_combat_hand_swap",
		"Expected a legal packed hand swap to surface the hand-swap hint once defend was already shown."
	)
	var hint_panel: PanelContainer = _find_first_run_hint_panel()
	var right_hand_swap_button: Button = combat_scene.get_node_or_null(COMBAT_RIGHT_HAND_SWAP_BUTTON_PATH) as Button
	assert(hint_panel != null and hint_panel.visible, "Expected a visible first-run hint panel for the hand-swap action.")
	assert(right_hand_swap_button != null and right_hand_swap_button.visible and not right_hand_swap_button.disabled, "Expected the right-hand swap button to stay enabled while the hint is visible.")
	var right_hand_swap_center: Vector2 = right_hand_swap_button.get_global_rect().get_center()
	assert(
		not hint_panel.get_global_rect().has_point(right_hand_swap_center),
		"Expected the first-run hand-swap hint panel not to cover the swap button's tap target."
	)

	right_hand_swap_button.emit_signal("pressed")
	await _settle_frames(2)
	assert(
		String(combat_scene.get("_selected_hand_swap_slot_name")) == InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND,
		"Expected the right-hand swap button to remain tappable while the hint is visible."
	)

	controller.dismiss_active_hint()
	assert(
		not controller.request_hint("first_combat_hand_swap"),
		"Expected the hand-swap hint not to requeue after it was already shown once on this save."
	)

	await _clear_current_scene()
	await _remove_runtime_nodes()


func test_map_scene_key_route_hint_triggers_once_without_retrigger() -> void:
	var bootstrap: AppBootstrapScript = await _install_runtime_nodes()
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE)
	bootstrap.reset_run_state_for_new_run()
	bootstrap.ensure_run_state_initialized()
	var controller: FirstRunHintController = _get_hint_controller(bootstrap)
	controller.reset()
	controller.mark_hint_shown("first_hamlet")
	controller.mark_hint_shown("first_roadside_encounter")

	var run_state: RunState = bootstrap.get_run_state()
	var boss_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "boss")
	assert(boss_node_id >= 0, "Expected a boss node before key-route first-run hint coverage.")
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, boss_node_id)

	var map_scene: Control = await _mount_scene(MapExplorePackedScene.instantiate() as Control)
	assert(map_scene != null, "Expected the map scene for key-route first-run hint coverage.")
	await _settle_frames(4)

	assert(
		controller.get_active_hint_id() == "first_key_required_route",
		"Expected the first visible locked boss route to surface the key-required hint."
	)
	var hint_panel: PanelContainer = _find_first_run_hint_panel()
	var fallback_route_button: Button = _find_first_visible_enabled_button_not_covered(map_scene, MAP_ROUTE_BUTTON_PATHS, hint_panel)
	assert(hint_panel != null and hint_panel.visible, "Expected a visible key-required route first-run hint panel on the map.")
	assert(fallback_route_button != null, "Expected at least one visible enabled route button to remain clear while the key-required hint is active.")

	controller.dismiss_active_hint()
	map_scene.call("_refresh_ui")
	await _settle_frames(2)
	assert(
		controller.get_active_hint_id().is_empty(),
		"Expected the key-required route hint not to retrigger after it was already shown on this save."
	)

	await _clear_current_scene()
	await _remove_runtime_nodes()


func test_hamlet_hint_keeps_support_actions_clear() -> void:
	var bootstrap: AppBootstrapScript = await _install_runtime_nodes()
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE)
	bootstrap.reset_run_state_for_new_run()
	bootstrap.ensure_run_state_initialized()
	var controller: FirstRunHintController = _get_hint_controller(bootstrap)
	controller.reset()
	controller.mark_hint_shown("first_key_required_route")
	controller.mark_hint_shown("first_roadside_encounter")

	var run_state: RunState = bootstrap.get_run_state()
	var hamlet_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	assert(hamlet_node_id >= 0, "Expected a hamlet node before first-run hamlet hint coverage.")
	_prepare_current_node_adjacent_to_target(run_state.map_runtime_state, hamlet_node_id)
	var move_result: Dictionary = bootstrap.choose_move_to_node(hamlet_node_id)
	assert(bool(move_result.get("ok", false)), "Expected hamlet traversal to succeed for first-run hint coverage.")
	assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.SUPPORT_INTERACTION, "Expected hamlet traversal to open SupportInteraction.")

	var support_scene: Control = SupportInteractionPackedScene.instantiate() as Control
	assert(support_scene != null, "Expected the support interaction scene for first-run hamlet hint coverage.")
	support_scene.top_level = true
	await _mount_scene(support_scene)
	await _settle_frames(4)
	var active_support_scene: Control = current_scene as Control
	assert(active_support_scene != null and is_instance_valid(active_support_scene), "Expected an active support interaction scene after mounting hamlet hint coverage.")

	assert(
		controller.get_active_hint_id() == "first_hamlet",
		"Expected the first hamlet entry to surface the hamlet hint."
	)
	var hint_panel: PanelContainer = _find_first_run_hint_panel()
	var action_button: Button = _find_first_visible_enabled_button_by_names(SUPPORT_ACTION_BUTTON_NAMES)
	assert(action_button != null, "Expected at least one visible support action while the hamlet hint is active.")
	if hint_panel != null and hint_panel.visible:
		assert(
			not hint_panel.get_global_rect().has_point(action_button.get_global_rect().get_center()),
			"Expected the hamlet hint panel not to cover the primary support-action tap target."
		)

	controller.dismiss_active_hint()
	await _clear_current_scene()
	var remounted_support_scene: Control = SupportInteractionPackedScene.instantiate() as Control
	assert(remounted_support_scene != null, "Expected the remounted support interaction scene for no-retrigger coverage.")
	remounted_support_scene.top_level = true
	await _mount_scene(remounted_support_scene)
	await _settle_frames(3)
	assert(
		controller.get_active_hint_id().is_empty(),
		"Expected the hamlet hint not to retrigger after it was already shown on this save."
	)

	await _clear_current_scene()
	await _remove_runtime_nodes()


func test_roadside_hint_keeps_event_choices_clear() -> void:
	var bootstrap: AppBootstrapScript = await _install_runtime_nodes()
	bootstrap.get_flow_manager().restore_state(FlowStateScript.Type.MAP_EXPLORE)
	bootstrap.reset_run_state_for_new_run()
	bootstrap.ensure_run_state_initialized()
	var controller: FirstRunHintController = _get_hint_controller(bootstrap)
	controller.reset()
	controller.mark_hint_shown("first_key_required_route")
	controller.mark_hint_shown("first_hamlet")

	var run_state: RunState = bootstrap.get_run_state()
	var move_context: Dictionary = _configure_seed_for_any_predicted_roadside_adjacent_family(run_state)
	assert(not move_context.is_empty(), "Expected a deterministic roadside-open route for first-run roadside hint coverage.")
	var move_result: Dictionary = bootstrap.choose_move_to_node(int(move_context.get("target_node_id", -1)))
	assert(bool(move_result.get("ok", false)), "Expected roadside trigger movement to succeed for first-run hint coverage.")
	assert(int(move_result.get("target_state", -1)) == FlowStateScript.Type.EVENT, "Expected roadside hint coverage move to open Event.")

	var event_scene: Control = EventPackedScene.instantiate() as Control
	assert(event_scene != null, "Expected the event scene for first-run roadside hint coverage.")
	event_scene.top_level = true
	await _mount_scene(event_scene)
	await _settle_frames(4)

	assert(
		controller.get_active_hint_id() == "first_roadside_encounter",
		"Expected the first roadside interruption to surface the roadside hint."
	)
	var hint_panel: PanelContainer = _find_first_run_hint_panel()
	var choice_button: Button = _find_first_visible_enabled_button_by_names(EVENT_CHOICE_BUTTON_NAMES)
	assert(choice_button != null, "Expected at least one visible enabled event choice while the roadside hint is active.")
	if hint_panel != null and hint_panel.visible:
		assert(
			not hint_panel.get_global_rect().has_point(choice_button.get_global_rect().get_center()),
			"Expected the roadside hint panel not to cover the primary event-choice tap target."
		)

	controller.dismiss_active_hint()
	await _clear_current_scene()
	var remounted_event_scene: Control = EventPackedScene.instantiate() as Control
	assert(remounted_event_scene != null, "Expected the remounted event scene for no-retrigger coverage.")
	remounted_event_scene.top_level = true
	await _mount_scene(remounted_event_scene)
	await _settle_frames(3)
	assert(
		controller.get_active_hint_id().is_empty(),
		"Expected the roadside hint not to retrigger after it was already shown on this save."
	)

	await _clear_current_scene()
	await _remove_runtime_nodes()


func _install_runtime_nodes() -> AppBootstrapScript:
	var root: Window = get_root()
	var bootstrap: AppBootstrapScript = root.get_node_or_null("AppBootstrap") as AppBootstrapScript
	if bootstrap == null:
		bootstrap = AppBootstrapScript.new()
		bootstrap.name = "AppBootstrap"
		root.add_child(bootstrap)
	var scene_router: Node = root.get_node_or_null("SceneRouter")
	if scene_router == null:
		scene_router = SceneRouterScript.new()
		scene_router.name = "SceneRouter"
		root.add_child(scene_router)
	await _settle_frames(2)
	return bootstrap


func _remove_runtime_nodes() -> void:
	var root: Window = get_root()
	for node_name in ["SceneRouter", "AppBootstrap"]:
		var runtime_node: Node = root.get_node_or_null(node_name)
		if runtime_node != null:
			runtime_node.queue_free()
	await _settle_frames(2)


func _mount_scene(scene: Control) -> Control:
	await _clear_current_scene()
	var root: Window = get_root()
	root.add_child(scene)
	current_scene = scene
	await _settle_frames(3)
	return scene


func _clear_current_scene() -> void:
	if current_scene == null:
		return
	var active_scene: Node = current_scene
	current_scene = null
	active_scene.queue_free()
	await _settle_frames(3)


func _settle_frames(frame_count: int = 2) -> void:
	for _frame in range(max(1, frame_count)):
		await process_frame


func _get_hint_controller(bootstrap: AppBootstrapScript) -> FirstRunHintController:
	assert(bootstrap != null, "Expected AppBootstrap before reading the first-run hint controller.")
	return bootstrap.run_session_coordinator.get("_first_run_hint_controller") as FirstRunHintController


func _find_first_visible_enabled_button(scene: Control, button_paths: Array) -> Button:
	for button_path_variant in button_paths:
		var button_path: String = String(button_path_variant)
		var button: Button = scene.get_node_or_null(button_path) as Button
		if button != null and button.visible and not button.disabled:
			return button
	return null


func _find_first_visible_enabled_button_not_covered(scene: Control, button_paths: Array, blocking_panel: Control) -> Button:
	for button_path_variant in button_paths:
		var button_path: String = String(button_path_variant)
		var button: Button = scene.get_node_or_null(button_path) as Button
		if button == null or not button.visible or button.disabled:
			continue
		if blocking_panel == null or not blocking_panel.get_global_rect().has_point(button.get_global_rect().get_center()):
			return button
	return null


func _find_first_visible_enabled_button_by_names(button_names: Array) -> Button:
	for button_name_variant in button_names:
		var button: Button = _find_node_by_name(get_root(), String(button_name_variant)) as Button
		if button != null and button.visible and not button.disabled:
			return button
	return null


func _find_first_run_hint_panel() -> PanelContainer:
	return _find_visible_node_by_name(get_root(), FIRST_RUN_HINT_PANEL_PATH) as PanelContainer


func _find_node_by_name(root_node: Node, target_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == target_name:
		return root_node
	for child in root_node.get_children():
		var resolved_child: Node = _find_node_by_name(child, target_name)
		if resolved_child != null:
			return resolved_child
	return null


func _find_visible_node_by_name(root_node: Node, target_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == target_name and root_node is CanvasItem and (root_node as CanvasItem).visible:
		return root_node
	for child in root_node.get_children():
		var resolved_child: Node = _find_visible_node_by_name(child, target_name)
		if resolved_child != null:
			return resolved_child
	return null


func _configure_seed_for_any_predicted_roadside_adjacent_family(run_state: RunState, max_seed: int = 512) -> Dictionary:
	if run_state == null or run_state.map_runtime_state == null:
		return {}
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var from_node_id: int = map_runtime_state.current_node_id
	var stream_name: String = String(RunSessionCoordinatorScript.ROADSIDE_ENCOUNTER_STREAM_NAME)
	var trigger_chance: float = float(RunSessionCoordinatorScript.ROADSIDE_ENCOUNTER_TRIGGER_CHANCE)
	for seed in range(1, max_seed + 1):
		run_state.configure_run_seed(seed)
		run_state.rng_stream_states.clear()
		for adjacent_node_id_variant in map_runtime_state.get_adjacent_node_ids(from_node_id):
			var target_node_id: int = int(adjacent_node_id_variant)
			var target_family: String = String(map_runtime_state.get_node_family(target_node_id))
			if RunSessionCoordinatorScript.ROADSIDE_ENCOUNTER_EXCLUDED_FAMILIES.has(target_family):
				continue
			if not _predict_roadside_open(run_state, stream_name, trigger_chance, from_node_id, target_node_id, target_family):
				continue
			var preview_event_state := EventStateScript.new()
			preview_event_state.setup_for_node(
				target_node_id,
				run_state.stage_index,
				EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER,
				seed,
				_build_test_roadside_trigger_context(run_state)
			)
			if preview_event_state.choices.is_empty():
				continue
			return {
				"seed": seed,
				"from_node_id": from_node_id,
				"target_node_id": target_node_id,
				"target_family": target_family,
			}
	run_state.rng_stream_states.clear()
	return {}


func _build_test_roadside_trigger_context(run_state: RunState) -> Dictionary:
	if run_state == null:
		return {}
	var max_hp: int = max(1, RunState.DEFAULT_PLAYER_HP)
	return {
		EventStateScript.TRIGGER_STAT_HUNGER: run_state.hunger,
		EventStateScript.TRIGGER_STAT_HP_PERCENT: (float(run_state.player_hp) / float(max_hp)) * 100.0,
		EventStateScript.TRIGGER_STAT_GOLD: run_state.gold,
	}


func _predict_roadside_open(
	run_state: RunState,
	stream_name: String,
	chance: float,
	from_node_id: int,
	target_node_id: int,
	target_node_type: String
) -> bool:
	if run_state == null:
		return false
	var draw_index: int = int(run_state.rng_stream_states.get(stream_name, 0))
	var context_salt: String = "%s|from:%d|to:%d|stage:%d" % [
		target_node_type,
		from_node_id,
		target_node_id,
		run_state.stage_index,
	]
	var stream_seed: int = _build_named_stream_seed(run_state.run_seed, stream_name, draw_index, context_salt)
	var rng := RandomNumberGenerator.new()
	rng.seed = stream_seed
	return rng.randf() < chance


func _build_named_stream_seed(run_seed: int, stream_name: String, draw_index: int, context_salt: String) -> int:
	var accumulator: int = 216613626
	var seed_value: String = "%d|%s|%d|%s" % [run_seed, stream_name, draw_index, context_salt]
	for byte in seed_value.to_utf8_buffer():
		accumulator = abs(int((accumulator ^ int(byte)) * 16777619))
	if accumulator == 0:
		return 1
	return accumulator


func _find_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot_variant in map_runtime_state.build_node_snapshots():
		if typeof(node_snapshot_variant) != TYPE_DICTIONARY:
			continue
		var node_snapshot: Dictionary = node_snapshot_variant
		if String(node_snapshot.get("node_family", "")) == node_family:
			return int(node_snapshot.get("node_id", -1))
	return -1


func _prepare_current_node_adjacent_to_target(map_runtime_state: RefCounted, target_node_id: int) -> void:
	var path: Array[int] = _build_path_between_nodes(map_runtime_state, int(map_runtime_state.current_node_id), target_node_id)
	assert(path.size() >= 2, "Expected a valid runtime path to the target node for first-run hint coverage.")
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
		for adjacent_node_id_variant in map_runtime_state.get_adjacent_node_ids(current_node_id):
			var adjacent_node_id: int = int(adjacent_node_id_variant)
			if visited.has(adjacent_node_id):
				continue
			var next_path: Array = path.duplicate()
			next_path.append(adjacent_node_id)
			queued_paths.append(next_path)
	return []
