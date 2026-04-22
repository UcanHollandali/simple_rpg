# Layer: Tests
extends SceneTree
class_name TestFirstRunHintController

const FirstRunHintControllerScript = preload("res://Game/UI/first_run_hint_controller.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	test_mark_hint_shown_is_idempotent()
	test_request_hint_queues_once_and_never_retriggers()
	test_inventory_scan_queues_supported_inventory_hints_in_order()
	print("test_first_run_hint_controller: all assertions passed")
	quit()


func test_mark_hint_shown_is_idempotent() -> void:
	var controller: FirstRunHintController = FirstRunHintControllerScript.new()
	assert(not controller.has_shown_hint("first_combat_defend"), "Expected the controller to start empty.")
	assert(controller.mark_hint_shown("first_combat_defend"), "Expected the first mark to report a newly shown hint.")
	assert(controller.has_shown_hint("first_combat_defend"), "Expected the controller to report the marked hint as shown.")
	assert(not controller.mark_hint_shown("first_combat_defend"), "Expected repeated mark calls to stay idempotent.")

	controller.load_from_save_data([
		" first_hamlet ",
		"first_hamlet",
		"",
		"first_key_required_route",
	])
	assert(controller.has_shown_hint("first_hamlet"), "Expected saved hints to trim and restore stable ids.")
	assert(controller.has_shown_hint("first_key_required_route"), "Expected distinct saved hints to restore successfully.")
	assert(
		controller.build_save_data() == ["first_hamlet", "first_key_required_route"],
		"Expected saved hint ids to stay de-duplicated and sorted for stable persistence."
	)


func test_request_hint_queues_once_and_never_retriggers() -> void:
	var controller: FirstRunHintController = FirstRunHintControllerScript.new()
	assert(controller.request_hint("first_combat_defend"), "Expected the first combat hint to activate once.")
	assert(controller.get_active_hint_id() == "first_combat_defend", "Expected the first requested hint to become active.")
	assert(controller.has_shown_hint("first_combat_defend"), "Expected active hints to mark themselves as shown immediately.")
	assert(not controller.request_hint("first_combat_defend"), "Expected shown hints not to requeue.")
	assert(controller.request_hint("first_low_hunger_warning"), "Expected a second hint to queue while one stays active.")
	assert(
		controller.get_pending_hint_ids() == ["first_low_hunger_warning"],
		"Expected later hints to wait in a one-at-a-time queue."
	)
	controller.dismiss_active_hint()
	assert(
		controller.get_active_hint_id() == "first_low_hunger_warning",
		"Expected dismissing the active hint to reveal the next queued hint."
	)
	controller.dismiss_active_hint()
	assert(controller.get_active_hint_id().is_empty(), "Expected the queue to empty after dismissing the final hint.")
	assert(
		not controller.request_hint("first_low_hunger_warning"),
		"Expected already shown hints to stay suppressed after dismissal."
	)
	assert(
		not controller.request_hint("unknown_hint_id"),
		"Expected the controller to reject hints outside the frozen set."
	)


func test_inventory_scan_queues_supported_inventory_hints_in_order() -> void:
	var controller: FirstRunHintController = FirstRunHintControllerScript.new()
	var inventory_state: InventoryState = InventoryStateScript.new()
	inventory_state.load_from_flat_save_dict({
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

	controller.scan_inventory_hints(inventory_state)
	assert(
		controller.get_active_hint_id() == "first_left_hand_shield",
		"Expected shield discovery to surface first from the inventory scan order."
	)
	assert(
		controller.get_pending_hint_ids() == ["first_left_hand_offhand_weapon", "first_belt_capacity"],
		"Expected offhand-weapon and belt-capacity hints to queue behind the shield hint."
	)
	controller.dismiss_active_hint()
	assert(
		controller.get_active_hint_id() == "first_left_hand_offhand_weapon",
		"Expected dismissing the shield hint to surface the offhand-weapon hint next."
	)
	controller.dismiss_active_hint()
	assert(
		controller.get_active_hint_id() == "first_belt_capacity",
		"Expected the belt-capacity hint to remain reachable after the earlier inventory hints."
	)
	controller.dismiss_active_hint()
	assert(controller.get_active_hint_id().is_empty(), "Expected the inventory hint queue to empty after dismissal.")

	controller.scan_inventory_hints(inventory_state)
	assert(
		controller.get_active_hint_id().is_empty() and controller.get_pending_hint_ids().is_empty(),
		"Expected inventory scans not to retrigger hints that were already shown on this save."
	)
