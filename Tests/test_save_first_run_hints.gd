# Layer: Tests
extends SceneTree
class_name TestSaveFirstRunHints

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const GameFlowManagerScript = preload("res://Game/Application/game_flow_manager.gd")
const RunSessionCoordinatorScript = preload("res://Game/Application/run_session_coordinator.gd")
const SaveRuntimeBridgeScript = preload("res://Game/Application/save_runtime_bridge.gd")
const SaveServiceScript = preload("res://Game/Infrastructure/save_service.gd")
const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")

const SAVE_PATH := "user://test_first_run_hints_save.json"


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	test_missing_shown_first_run_hints_defaults_to_empty_on_restore()
	test_save_roundtrip_writes_and_restores_shown_first_run_hints()
	test_fresh_save_surfaces_hints_in_first_appearance_order()
	test_restored_shown_hints_stay_suppressed_across_second_run()
	print("test_save_first_run_hints: all assertions passed")
	quit()


func test_missing_shown_first_run_hints_defaults_to_empty_on_restore() -> void:
	var context: Dictionary = _build_save_context()
	var flow_manager: Node = context.get("flow_manager")
	var coordinator: RefCounted = context.get("coordinator")
	var save_runtime_bridge: RefCounted = context.get("save_runtime_bridge")
	var hint_controller: FirstRunHintController = _get_hint_controller(coordinator)
	assert(hint_controller != null, "Expected save context setup to instantiate the first-run hint controller.")

	assert(
		hint_controller.mark_hint_shown("first_combat_defend"),
		"Expected test setup to seed one shown hint before restore."
	)
	var snapshot_result: Dictionary = save_runtime_bridge.call("build_save_snapshot")
	assert(bool(snapshot_result.get("ok", false)), "Expected snapshot build to succeed for the additive app_state coverage.")
	var snapshot: Dictionary = (snapshot_result.get("snapshot", {}) as Dictionary).duplicate(true)
	var app_state: Dictionary = (snapshot.get("app_state", {}) as Dictionary).duplicate(true)
	app_state.erase("shown_first_run_hints")
	snapshot["app_state"] = app_state

	var restore_result: Dictionary = save_runtime_bridge.call("restore_from_snapshot", snapshot)
	assert(bool(restore_result.get("ok", false)), "Expected restore to accept snapshots that predate the shown-hint field.")
	assert(
		_get_hint_controller(coordinator).build_save_data().is_empty(),
		"Expected missing shown-hint save data to default to an empty set on restore."
	)
	var resave_snapshot_result: Dictionary = save_runtime_bridge.call("build_save_snapshot")
	assert(bool(resave_snapshot_result.get("ok", false)), "Expected a restored legacy snapshot to build a new snapshot cleanly.")
	var resaved_app_state: Dictionary = (resave_snapshot_result.get("snapshot", {}) as Dictionary).get("app_state", {})
	assert(
		resaved_app_state.get("shown_first_run_hints", []) == [],
		"Expected the additive shown-hint set to round-trip from a legacy snapshot as an explicit empty array."
	)
	_free_node(flow_manager)


func test_save_roundtrip_writes_and_restores_shown_first_run_hints() -> void:
	var context: Dictionary = _build_save_context()
	var flow_manager: Node = context.get("flow_manager")
	var coordinator: RefCounted = context.get("coordinator")
	var save_service: SaveService = context.get("save_service")
	var save_runtime_bridge: RefCounted = context.get("save_runtime_bridge")
	var hint_controller: FirstRunHintController = _get_hint_controller(coordinator)
	assert(hint_controller != null, "Expected save context setup to instantiate the first-run hint controller.")

	assert(
		hint_controller.mark_hint_shown("first_hamlet"),
		"Expected the first persisted hint to register."
	)
	assert(
		hint_controller.mark_hint_shown("first_key_required_route"),
		"Expected the second persisted hint to register."
	)
	var save_result: Dictionary = save_runtime_bridge.call("save_game", SAVE_PATH)
	assert(bool(save_result.get("ok", false)), "Expected save_game() to write a snapshot with the shown-hint set.")

	var load_result: Dictionary = save_service.load_snapshot(SAVE_PATH)
	assert(bool(load_result.get("ok", false)), "Expected the written save file to load successfully.")
	var snapshot: Dictionary = load_result.get("snapshot", {})
	var app_state: Dictionary = snapshot.get("app_state", {})
	assert(
		app_state.get("shown_first_run_hints", []) == ["first_hamlet", "first_key_required_route"],
		"Expected snapshots to persist the shown-hint set under app_state.shown_first_run_hints."
	)

	var restored_context: Dictionary = _build_save_context()
	var restored_flow_manager: Node = restored_context.get("flow_manager")
	var restored_coordinator: RefCounted = restored_context.get("coordinator")
	var restored_save_runtime_bridge: RefCounted = restored_context.get("save_runtime_bridge")
	var restore_result: Dictionary = restored_save_runtime_bridge.call("restore_from_snapshot", snapshot)
	assert(bool(restore_result.get("ok", false)), "Expected snapshot restore to hydrate the shown-hint set.")
	assert(
		_get_hint_controller(restored_coordinator).build_save_data() == ["first_hamlet", "first_key_required_route"],
		"Expected restored save state to preserve the shown-hint ids exactly."
	)

	var delete_result: Dictionary = save_service.delete_save_file(SAVE_PATH)
	assert(bool(delete_result.get("ok", false)), "Expected the temporary save file to be deleted after roundtrip coverage.")
	_free_node(flow_manager)
	_free_node(restored_flow_manager)


func test_fresh_save_surfaces_hints_in_first_appearance_order() -> void:
	var context: Dictionary = _build_save_context()
	var flow_manager: Node = context.get("flow_manager")
	var run_state: RunState = context.get("run_state")
	var coordinator: RefCounted = context.get("coordinator")
	var hint_controller: FirstRunHintController = _get_hint_controller(coordinator)
	assert(hint_controller != null, "Expected save context setup to instantiate the first-run hint controller.")

	run_state.inventory_state.load_from_flat_save_dict(_build_inventory_hint_save_data())
	var shown_order: Array[String] = []
	hint_controller.scan_inventory_hints(run_state.inventory_state)
	_consume_visible_hints(hint_controller, shown_order)
	for hint_id in [
		"first_low_hunger_warning",
		"first_combat_defend",
		"first_combat_technique",
		"first_combat_hand_swap",
		"first_hamlet",
		"first_roadside_encounter",
		"first_key_required_route",
	]:
		_request_and_dismiss_hint(hint_controller, hint_id, shown_order)

	assert(
		shown_order == [
			"first_left_hand_shield",
			"first_left_hand_offhand_weapon",
			"first_belt_capacity",
			"first_low_hunger_warning",
			"first_combat_defend",
			"first_combat_technique",
			"first_combat_hand_swap",
			"first_hamlet",
			"first_roadside_encounter",
			"first_key_required_route",
		],
		"Expected a fresh save to surface hints in the same order that their contexts first appear."
	)
	_free_node(flow_manager)


func test_restored_shown_hints_stay_suppressed_across_second_run() -> void:
	var context: Dictionary = _build_save_context()
	var flow_manager: Node = context.get("flow_manager")
	var coordinator: RefCounted = context.get("coordinator")
	var save_runtime_bridge: RefCounted = context.get("save_runtime_bridge")
	var hint_controller: FirstRunHintController = _get_hint_controller(coordinator)
	assert(hint_controller != null, "Expected save context setup to instantiate the first-run hint controller.")

	for hint_id in [
		"first_left_hand_shield",
		"first_left_hand_offhand_weapon",
		"first_belt_capacity",
		"first_low_hunger_warning",
		"first_combat_defend",
		"first_combat_technique",
		"first_combat_hand_swap",
		"first_hamlet",
		"first_roadside_encounter",
		"first_key_required_route",
	]:
		_request_and_dismiss_hint(hint_controller, hint_id)

	var snapshot_result: Dictionary = save_runtime_bridge.call("build_save_snapshot")
	assert(bool(snapshot_result.get("ok", false)), "Expected the fully shown hint set to serialize cleanly.")
	var snapshot: Dictionary = snapshot_result.get("snapshot", {})

	var restored_context: Dictionary = _build_save_context()
	var restored_flow_manager: Node = restored_context.get("flow_manager")
	var restored_run_state: RunState = restored_context.get("run_state")
	var restored_coordinator: RefCounted = restored_context.get("coordinator")
	var restored_save_runtime_bridge: RefCounted = restored_context.get("save_runtime_bridge")
	var restore_result: Dictionary = restored_save_runtime_bridge.call("restore_from_snapshot", snapshot)
	assert(
		bool(restore_result.get("ok", false)),
		"Expected the shown hint set to restore cleanly before a new run. Got: %s" % [str(restore_result)]
	)
	restored_run_state.reset_for_new_run()
	restored_coordinator.call("reset_for_new_run")
	var restored_hint_controller: FirstRunHintController = _get_hint_controller(restored_coordinator)
	assert(restored_hint_controller != null, "Expected the restored coordinator to keep the hint controller alive across runs.")

	for hint_id in [
		"first_combat_defend",
		"first_combat_technique",
		"first_combat_hand_swap",
		"first_hamlet",
		"first_roadside_encounter",
		"first_key_required_route",
		"first_low_hunger_warning",
	]:
		assert(
			not restored_hint_controller.request_hint(hint_id),
			"Expected restored shown hints to stay suppressed on a second run for %s." % hint_id
		)
	restored_run_state.inventory_state.load_from_flat_save_dict(_build_inventory_hint_save_data())
	restored_hint_controller.scan_inventory_hints(restored_run_state.inventory_state)
	assert(
		restored_hint_controller.get_active_hint_id().is_empty()
		and restored_hint_controller.get_pending_hint_ids().is_empty(),
		"Expected inventory-backed hints to stay suppressed on a second run of the same save."
	)

	_free_node(flow_manager)
	_free_node(restored_flow_manager)


func _build_save_context() -> Dictionary:
	var flow_manager: Node = GameFlowManagerScript.new()
	flow_manager.call("restore_state", FlowStateScript.Type.MAP_EXPLORE)
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	var coordinator: RefCounted = RunSessionCoordinatorScript.new()
	coordinator.call("setup", flow_manager, run_state)
	var save_service: SaveService = SaveServiceScript.new()
	var save_runtime_bridge: RefCounted = SaveRuntimeBridgeScript.new()
	save_runtime_bridge.call("setup", flow_manager, run_state, coordinator, save_service)
	return {
		"flow_manager": flow_manager,
		"run_state": run_state,
		"coordinator": coordinator,
		"save_service": save_service,
		"save_runtime_bridge": save_runtime_bridge,
	}


func _get_hint_controller(coordinator: RefCounted) -> FirstRunHintController:
	return coordinator.get("_first_run_hint_controller") as FirstRunHintController


func _build_inventory_hint_save_data() -> Dictionary:
	return {
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
	}


func _consume_visible_hints(controller: FirstRunHintController, shown_order: Array[String] = []) -> void:
	while not controller.get_active_hint_id().is_empty():
		shown_order.append(controller.get_active_hint_id())
		controller.dismiss_active_hint()


func _request_and_dismiss_hint(controller: FirstRunHintController, hint_id: String, shown_order: Array[String] = []) -> void:
	assert(controller.request_hint(hint_id), "Expected %s to surface once on a fresh save." % hint_id)
	assert(controller.get_active_hint_id() == hint_id, "Expected %s to become active immediately." % hint_id)
	shown_order.append(hint_id)
	controller.dismiss_active_hint()


func _free_node(node: Node) -> void:
	if node == null:
		return
	node.free()
