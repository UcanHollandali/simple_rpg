extends SceneTree

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const SupportInteractionStateScript = preload("res://Game/RuntimeState/support_interaction_state.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")

const SUPPORT_ACTION_B_BUTTON_PATH := "Margin/VBox/OffersShell/VBox/ActionsRow/ActionBButton"
const OVERFLOW_PROMPT_PATH := "InventoryOverflowPrompt"
const OVERFLOW_OPTIONS_PATH := "%s/PromptHolder/PromptPanel/PromptVBox/OptionsVBox" % OVERFLOW_PROMPT_PATH

var _phase: int = 0
var _phase_frame_count: int = 0
var _is_finishing: bool = false


func _init() -> void:
	print("test_support_overflow_prompt: setup")
	_ensure_autoload_like_nodes()
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	_phase_frame_count += 1

	match _phase:
		0:
			_prepare_support_scene_state()
			change_scene_to_file("res://scenes/support_interaction.tscn")
			_advance_phase(1)
		1:
			if current_scene != null and current_scene.name == "SupportInteraction":
				_press(SUPPORT_ACTION_B_BUTTON_PATH)
				_advance_phase(2)
		2:
			if current_scene != null and current_scene.name == "SupportInteraction":
				var overflow_prompt: Control = current_scene.get_node_or_null(OVERFLOW_PROMPT_PATH) as Control
				_require(overflow_prompt != null and overflow_prompt.visible, "Expected merchant buy on a full backpack to open the shared inventory overflow prompt.")
				var options_vbox: Control = current_scene.get_node_or_null(OVERFLOW_OPTIONS_PATH) as Control
				_require(options_vbox != null, "Expected the support overflow prompt to expose the discard options container.")
				var enabled_button_count: int = 0
				var disabled_button_count: int = 0
				for child in options_vbox.get_children():
					var button: Button = child as Button
					if button == null or not button.visible or button.disabled:
						if button != null and button.disabled:
							disabled_button_count += 1
						continue
					enabled_button_count += 1
				_require(
					enabled_button_count > 0,
					"Expected merchant overflow prompt to render at least one enabled discard option when the backpack is full. children=%d disabled=%d" % [
						options_vbox.get_child_count(),
						disabled_button_count,
					]
				)
				await _finish_success("test_support_overflow_prompt")

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


func _prepare_support_scene_state() -> void:
	var bootstrap: AppBootstrap = get_root().get_node_or_null("AppBootstrap") as AppBootstrap
	_require(bootstrap != null, "Expected AppBootstrap before preparing the support overflow scene test.")
	if bootstrap.get_flow_manager() == null:
		bootstrap.game_flow_manager = bootstrap._ensure_flow_manager()
	_require(bootstrap.game_flow_manager != null, "Expected flow manager before preparing the support overflow scene test.")
	var run_state: RunState = bootstrap.ensure_run_state_initialized()
	_require(run_state != null, "Expected RunState before preparing the support overflow scene test.")
	run_state.reset_for_new_run()
	run_state.gold = 20
	_fill_backpack_to_capacity(run_state)
	bootstrap.game_flow_manager.restore_state(FlowStateScript.Type.SUPPORT_INTERACTION)

	var support_state: SupportInteractionState = SupportInteractionStateScript.new()
	support_state.support_type = SupportInteractionStateScript.TYPE_MERCHANT
	support_state.source_node_id = 11
	support_state.title_text = "Road Merchant"
	support_state.summary_text = "Buy what you need before the wagon rolls on."
	support_state.offers = [
		{
			"offer_id": "buy_embersalt_ration_x1",
			"label": "Buy Embersalt Ration x1 (7 Gold)",
			"effect_type": "buy_consumable",
			"definition_id": "embersalt_ration",
			"amount": 1,
			"cost_gold": 7,
			"available": true,
		},
		{
			"offer_id": "buy_hedge_sabre",
			"label": "Buy Hedge Sabre (12 Gold)",
			"effect_type": "buy_weapon",
			"definition_id": "hedge_sabre",
			"cost_gold": 12,
			"available": true,
		},
		{
			"offer_id": "buy_wayfarer_frame",
			"label": "Buy Wayfarer Frame (10 Gold)",
			"effect_type": "buy_belt",
			"definition_id": "wayfarer_frame",
			"cost_gold": 10,
			"available": true,
		},
	]
	bootstrap.run_session_coordinator.support_interaction_state = support_state
	var prompt_result: Dictionary = bootstrap.choose_support_action("buy_hedge_sabre")
	_require(String(prompt_result.get("error", "")) == "inventory_choice_required", "Expected the focused merchant overflow setup to hit the shared inventory-choice contract before scene rendering.")
	_require(
		not (prompt_result.get("discardable_slots", []) as Array).is_empty(),
		"Expected the merchant overflow contract to include discardable backpack slots before the support scene renders the prompt. prompt=%s" % JSON.stringify(prompt_result)
	)


func _fill_backpack_to_capacity(run_state: RunState) -> void:
	var inventory_snapshot: Dictionary = run_state.inventory_state.to_save_dict()
	var backpack_slots: Array = inventory_snapshot.get("backpack_slots", []).duplicate(true)
	var next_slot_id: int = int(inventory_snapshot.get("inventory_next_slot_id", 1))
	var filler_ids: Array[String] = [
		"sturdy_wraps",
		"packrat_clasp",
		"lean_pack_token",
		"tempered_binding",
		"sturdy_wraps",
		"packrat_clasp",
	]
	var filler_index: int = 0
	while backpack_slots.size() < run_state.inventory_state.get_total_capacity():
		backpack_slots.append({
			"slot_id": next_slot_id,
			"inventory_family": InventoryStateScript.INVENTORY_FAMILY_PASSIVE,
			"definition_id": filler_ids[filler_index % filler_ids.size()],
		})
		next_slot_id += 1
		filler_index += 1
	inventory_snapshot["backpack_slots"] = backpack_slots
	inventory_snapshot["inventory_next_slot_id"] = next_slot_id
	run_state.inventory_state.load_from_flat_save_dict(inventory_snapshot)
	_require(run_state.inventory_state.get_used_capacity() == run_state.inventory_state.get_total_capacity(), "Expected helper to fill the backpack before opening the merchant overflow prompt.")


func _press(node_path: String) -> void:
	_require(current_scene != null, "Expected current scene before pressing %s." % node_path)
	var button: Button = current_scene.get_node_or_null(node_path) as Button
	_require(button != null, "Expected button at %s." % node_path)
	button.emit_signal("pressed")


func _advance_phase(new_phase: int) -> void:
	_phase = new_phase
	_phase_frame_count = 0


func _finish_success(test_name: String) -> void:
	if _is_finishing:
		return
	_is_finishing = true
	var process_frame_handler := Callable(self, "_on_process_frame")
	if process_frame.is_connected(process_frame_handler):
		process_frame.disconnect(process_frame_handler)
	print("%s: all assertions passed" % test_name)
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


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
