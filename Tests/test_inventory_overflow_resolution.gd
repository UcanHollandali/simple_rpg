# Layer: Tests
extends SceneTree

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const GameFlowManagerScript = preload("res://Game/Application/game_flow_manager.gd")
const RunSessionCoordinatorScript = preload("res://Game/Application/run_session_coordinator.gd")
const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")
const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")
const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")
const SupportInteractionStateScript = preload("res://Game/RuntimeState/support_interaction_state.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")


func _init() -> void:
	test_reward_choice_requires_discard_resolution()
	test_event_choice_can_leave_item_without_mutation()
	test_support_purchase_requires_discard_before_commit()
	print("test_inventory_overflow_resolution: all assertions passed")
	quit()


func test_reward_choice_requires_discard_resolution() -> void:
	var flow_manager: GameFlowManager = GameFlowManagerScript.new()
	flow_manager.restore_state(FlowStateScript.Type.REWARD)
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	_fill_backpack_to_capacity(run_state)

	var coordinator: RunSessionCoordinator = RunSessionCoordinatorScript.new()
	coordinator.setup(flow_manager, run_state)

	var reward_state: RewardState = RewardStateScript.new()
	reward_state.source_context = RewardStateScript.SOURCE_REWARD_NODE
	reward_state.title_text = "Overflow Reward"
	reward_state.offers = [{
		"offer_id": "claim_splitter_axe",
		"effect_type": "grant_item",
		"inventory_family": InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		"definition_id": "splitter_axe",
		"amount": 1,
	}]
	coordinator.reward_state = reward_state

	var prompt_result: Dictionary = coordinator.choose_reward_option("claim_splitter_axe")
	assert(not bool(prompt_result.get("ok", false)), "Expected reward choice to defer when the backpack is full.")
	assert(String(prompt_result.get("error", "")) == "inventory_choice_required", "Expected explicit overflow prompt error for reward choice.")
	assert(coordinator.get_reward_state() != null, "Expected pending reward state to stay open while waiting for discard choice.")
	assert(not _inventory_contains_definition(run_state.inventory_state, "splitter_axe"), "Expected reward item not to be added before discard confirmation.")

	var discard_slot_id: int = int(run_state.inventory_state.inventory_slots[0].get("slot_id", -1))
	var resolve_result: Dictionary = coordinator.choose_reward_option("claim_splitter_axe", discard_slot_id)
	assert(bool(resolve_result.get("ok", false)), "Expected reward choice to resolve after choosing a discard slot.")
	assert(int(resolve_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected resolved reward overflow choice to return to MapExplore.")
	assert(coordinator.get_reward_state() == null, "Expected reward state to clear after final reward resolution.")
	assert(_inventory_contains_definition(run_state.inventory_state, "splitter_axe"), "Expected chosen reward item to enter the backpack after discard confirmation.")
	assert(not _inventory_contains_definition(run_state.inventory_state, "wild_berries"), "Expected the explicitly discarded backpack item to be gone after reward resolution.")
	_free_node(flow_manager)


func test_event_choice_can_leave_item_without_mutation() -> void:
	var flow_manager: GameFlowManager = GameFlowManagerScript.new()
	flow_manager.current_state = FlowStateScript.Type.EVENT
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	_fill_backpack_to_capacity(run_state)

	var coordinator: RunSessionCoordinator = RunSessionCoordinatorScript.new()
	coordinator.setup(flow_manager, run_state)

	var event_state: EventState = EventStateScript.new()
	event_state.template_definition_id = "overflow_event"
	event_state.source_node_id = 7
	event_state.source_context = EventStateScript.SOURCE_CONTEXT_NODE_EVENT
	event_state.title_text = "Overflow Event"
	event_state.summary_text = "Take it or leave it."
	event_state.choices = [{
		"choice_id": "pack_the_charm",
		"label": "Pack the Charm",
		"summary": "A passive charm is wedged in the shrine.",
		"effect_type": "grant_item",
		"inventory_family": InventoryStateScript.INVENTORY_FAMILY_PASSIVE,
		"definition_id": "iron_grip_charm",
		"amount": 1,
	}]
	coordinator.event_state = event_state

	var prompt_result: Dictionary = coordinator.choose_event_option("pack_the_charm")
	assert(not bool(prompt_result.get("ok", false)), "Expected event item choice to defer when the backpack is full.")
	assert(String(prompt_result.get("error", "")) == "inventory_choice_required", "Expected explicit overflow prompt error for event choice.")
	assert(coordinator.get_event_state() != null, "Expected pending event state to stay open while waiting for discard choice.")
	assert(not _inventory_contains_definition(run_state.inventory_state, "iron_grip_charm"), "Expected event item not to be added before overflow resolution.")

	var leave_result: Dictionary = coordinator.choose_event_option("pack_the_charm", -1, true)
	assert(bool(leave_result.get("ok", false)), "Expected event choice to resolve when the player leaves the item behind.")
	assert(bool(leave_result.get("item_left", false)), "Expected event overflow leave path to report that the item was left behind.")
	assert(int(leave_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected leaving an event item behind to return to MapExplore.")
	assert(coordinator.get_event_state() == null, "Expected event state to clear after resolving the leave-item path.")
	assert(not _inventory_contains_definition(run_state.inventory_state, "iron_grip_charm"), "Expected leave-item event resolution not to mutate the backpack.")
	assert(_inventory_contains_definition(run_state.inventory_state, "wild_berries"), "Expected existing backpack items to remain untouched when the event item is left behind.")
	_free_node(flow_manager)


func test_support_purchase_requires_discard_before_commit() -> void:
	var flow_manager: GameFlowManager = GameFlowManagerScript.new()
	flow_manager.restore_state(FlowStateScript.Type.SUPPORT_INTERACTION)
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.gold = 20
	_fill_backpack_to_capacity(run_state)

	var coordinator: RunSessionCoordinator = RunSessionCoordinatorScript.new()
	coordinator.setup(flow_manager, run_state)

	var support_state: SupportInteractionState = SupportInteractionStateScript.new()
	support_state.support_type = SupportInteractionStateScript.TYPE_MERCHANT
	support_state.source_node_id = 11
	support_state.title_text = "Overflow Merchant"
	support_state.summary_text = "Test merchant state."
	support_state.offers = [{
		"offer_id": "buy_splitter_axe",
		"label": "Buy Splitter Axe",
		"effect_type": "buy_weapon",
		"definition_id": "splitter_axe",
		"cost_gold": 7,
		"available": true,
	}]
	coordinator.support_interaction_state = support_state

	var prompt_result: Dictionary = coordinator.choose_support_action("buy_splitter_axe")
	assert(not bool(prompt_result.get("ok", false)), "Expected merchant purchase to defer when the backpack is full.")
	assert(String(prompt_result.get("error", "")) == "inventory_choice_required", "Expected explicit overflow prompt error for merchant purchase.")
	assert(coordinator.get_support_interaction_state() != null, "Expected support interaction to stay open while waiting for discard choice.")
	assert(run_state.gold == 20, "Expected gold not to change before merchant overflow resolution.")
	assert(not _inventory_contains_definition(run_state.inventory_state, "splitter_axe"), "Expected merchant item not to be added before discard confirmation.")
	assert(bool((coordinator.get_support_interaction_state().offers[0] as Dictionary).get("available", false)), "Expected merchant offer to remain available before final commit.")

	var discard_slot_id: int = int(run_state.inventory_state.inventory_slots[0].get("slot_id", -1))
	var resolve_result: Dictionary = coordinator.choose_support_action("buy_splitter_axe", discard_slot_id)
	assert(bool(resolve_result.get("ok", false)), "Expected merchant purchase to resolve after choosing a discard slot.")
	assert(int(resolve_result.get("target_state", -1)) == FlowStateScript.Type.MAP_EXPLORE, "Expected one-off merchant test purchase to close back to MapExplore after commit.")
	assert(run_state.gold == 13, "Expected merchant purchase to spend gold only after the discard choice commits.")
	assert(_inventory_contains_definition(run_state.inventory_state, "splitter_axe"), "Expected merchant item to enter the backpack after discard confirmation.")
	assert(not _inventory_contains_definition(run_state.inventory_state, "wild_berries"), "Expected the explicitly discarded backpack item to be removed after merchant commit.")
	assert(coordinator.get_support_interaction_state() == null, "Expected support state to clear when the only merchant offer is consumed.")
	_free_node(flow_manager)


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
		"lean_pack_token",
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
	assert(run_state.inventory_state.get_used_capacity() == run_state.inventory_state.get_total_capacity(), "Expected helper to fill the backpack to capacity for overflow coverage.")


func _inventory_contains_definition(inventory_state: InventoryState, definition_id: String) -> bool:
	if inventory_state == null or definition_id.is_empty():
		return false
	for slot in inventory_state.inventory_slots:
		if String(slot.get("definition_id", "")) == definition_id:
			return true
	return false


func _free_node(node: Node) -> void:
	if node == null:
		return
	node.free()
