# Layer: Tests
extends SceneTree
class_name TestEventContent

const EventApplicationPolicyScript = preload("res://Game/Application/event_application_policy.gd")
const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")
const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")
const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")


func _init() -> void:
	test_event_state_rotates_by_stage()
	test_event_application_policy_covers_supported_outcomes()
	print("test_event_content: all assertions passed")
	quit()


func test_event_state_rotates_by_stage() -> void:
	var stage_one_event: EventState = EventStateScript.new()
	stage_one_event.setup_for_node(10, 1)
	assert(String(stage_one_event.template_definition_id) == "forest_shrine_echo", "Expected stage 1 to resolve the first stable-id event template.")
	assert(stage_one_event.choices.size() == 2, "Expected stage 1 event state to expose exactly 2 choices.")

	var stage_two_event: EventState = EventStateScript.new()
	stage_two_event.setup_for_node(10, 2)
	assert(String(stage_two_event.template_definition_id) == "ghost_lantern_bargain", "Expected stage 2 to resolve the second stable-id event template.")

	var stage_three_event: EventState = EventStateScript.new()
	stage_three_event.setup_for_node(10, 3)
	assert(String(stage_three_event.template_definition_id) == "moss_waystone_tithe", "Expected stage 3 to resolve the third stable-id event template after the authored event variety expansion.")

	var stage_four_event: EventState = EventStateScript.new()
	stage_four_event.setup_for_node(10, 4)
	assert(String(stage_four_event.template_definition_id) == "trickster_stump_feast", "Expected stage 4 to wrap into the fourth stable-id event template after the authored event variety expansion.")


func test_event_application_policy_covers_supported_outcomes() -> void:
	var policy: EventApplicationPolicy = EventApplicationPolicyScript.new()
	var inventory_actions: InventoryActions = InventoryActionsScript.new()

	var heal_run_state: RunState = _build_run_state()
	heal_run_state.player_hp = 40
	var heal_event: EventState = EventStateScript.new()
	heal_event.setup_for_node(10, 1)
	var heal_result: Dictionary = policy.apply_option(heal_run_state, heal_event, inventory_actions, "drink_from_the_basin")
	assert(bool(heal_result.get("ok", false)), "Expected heal event outcome to apply successfully.")
	assert(heal_run_state.player_hp == 50, "Expected heal event outcome to restore HP.")

	var gold_run_state: RunState = _build_run_state()
	gold_run_state.gold = 3
	var waystone_event: EventState = EventStateScript.new()
	waystone_event.setup_for_node(10, 3)
	var gold_result: Dictionary = policy.apply_option(gold_run_state, waystone_event, inventory_actions, "lift_the_tithe")
	assert(bool(gold_result.get("ok", false)), "Expected gold event outcome to apply successfully.")
	assert(gold_run_state.gold == 10, "Expected gold event outcome to grant the authored waystone payout.")

	var xp_run_state: RunState = _build_run_state()
	xp_run_state.xp = 6
	var ghost_event: EventState = EventStateScript.new()
	ghost_event.setup_for_node(10, 2)
	var xp_result: Dictionary = policy.apply_option(xp_run_state, ghost_event, inventory_actions, "answer_the_question")
	assert(bool(xp_result.get("ok", false)), "Expected XP event outcome to apply successfully.")
	assert(xp_run_state.xp == 11, "Expected XP event outcome to grant XP.")

	var damage_run_state: RunState = _build_run_state()
	damage_run_state.player_hp = 5
	var damage_result: Dictionary = policy.apply_option(damage_run_state, ghost_event, inventory_actions, "walk_through_the_light")
	assert(bool(damage_result.get("ok", false)), "Expected damage event outcome to apply successfully.")
	assert(damage_run_state.player_hp == 0, "Expected damage event outcome to reduce HP to zero when lethal.")
	assert(bool(damage_result.get("player_defeated", false)), "Expected lethal damage event outcome to flag defeat.")

	var hunger_run_state: RunState = _build_run_state()
	hunger_run_state.hunger = 15
	var trick_event: EventState = EventStateScript.new()
	trick_event.setup_for_node(10, 4)
	var hunger_result: Dictionary = policy.apply_option(hunger_run_state, trick_event, inventory_actions, "eat_the_false_meal")
	assert(bool(hunger_result.get("ok", false)), "Expected hunger event outcome to apply successfully.")
	assert(hunger_run_state.hunger == 11, "Expected hunger event outcome to apply the authored hunger loss.")

	var repair_run_state: RunState = _build_run_state()
	repair_run_state.inventory_state.weapon_instance["current_durability"] = 3
	var repair_result: Dictionary = policy.apply_option(repair_run_state, trick_event, inventory_actions, "pry_free_the_blade")
	assert(bool(repair_result.get("ok", false)), "Expected repair event outcome to apply successfully.")
	assert(int(repair_run_state.inventory_state.weapon_instance.get("current_durability", 0)) == 20, "Expected repair event outcome to restore weapon durability.")


func _build_run_state() -> RunState:
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	return run_state
