# Layer: Tests
extends SceneTree
class_name TestStatusBleed


func _init() -> void:
	test_bleed_applies_ticks_and_expires_in_combat_state()
	print("test_status_bleed: all assertions passed")
	quit()


func test_bleed_applies_ticks_and_expires_in_combat_state() -> void:
	var context: Dictionary = _build_bleed_flow_context()
	var flow: CombatFlow = context["flow"]
	var run_state: RunState = context["run_state"]

	var defend_result: Dictionary = flow.process_defend()
	assert(not bool(defend_result.get("skipped", true)), "Expected defend to resolve before the first bleed attack.")

	var first_enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(first_enemy_result.get("damage_applied", -1)) == 1, "Expected defend guard to reduce the first bleed hit from 3 to 1.")
	assert(flow.combat_state.player_hp == 59, "Expected player HP to drop from 60 to 59 after the first bleed hit.")
	assert(flow.combat_state.player_statuses.size() == 1, "Expected bleed status to be applied to the player.")
	assert(
		String(flow.combat_state.player_statuses[0].get("definition_id", "")) == "bleed",
		"Expected bleed to be the applied status."
	)
	assert(
		int(flow.combat_state.player_statuses[0].get("remaining_turns", -1)) == 3,
		"Expected bleed to start with 3 remaining turns."
	)

	var first_turn_end: Dictionary = flow.process_turn_end()
	assert(flow.combat_state.player_hp == 58, "Expected bleed to tick for 1 damage at the first turn end.")
	assert(
		int(flow.combat_state.player_statuses[0].get("remaining_turns", -1)) == 2,
		"Expected bleed to drop to 2 remaining turns after the first tick."
	)
	assert(int(first_turn_end.get("player_hunger", -1)) == RunState.DEFAULT_HUNGER - 1, "Expected hunger tick after first bleed resolution.")

	var second_enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(second_enemy_result.get("damage_applied", -1)) == 1, "Expected second barbed hunter hit to deal 1 damage.")
	var second_turn_end: Dictionary = flow.process_turn_end()
	assert(flow.combat_state.player_hp == 56, "Expected second bleed tick to land after the second enemy action.")
	assert(
		int(flow.combat_state.player_statuses[0].get("remaining_turns", -1)) == 1,
		"Expected bleed to drop to 1 remaining turn after the second tick."
	)
	assert(int(second_turn_end.get("player_hunger", -1)) == RunState.DEFAULT_HUNGER - 2, "Expected hunger progression to remain intact on the second turn.")

	var third_enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(third_enemy_result.get("damage_applied", -1)) == 1, "Expected third barbed hunter hit to deal 1 damage.")
	var third_turn_end: Dictionary = flow.process_turn_end()
	assert(flow.combat_state.player_hp == 54, "Expected third bleed tick to apply before the status expires.")
	assert(flow.combat_state.player_statuses.is_empty(), "Expected bleed to expire after its third tick.")
	assert(int(third_turn_end.get("player_hunger", -1)) == RunState.DEFAULT_HUNGER - 3, "Expected hunger progression to remain intact on the third turn.")

	run_state.commit_combat_result(flow.combat_state)
	assert(run_state.player_hp == 54, "Expected committed run HP to reflect combat-local bleed damage.")
	assert(not run_state.to_save_dict().has("player_statuses"), "Expected combat-local statuses to stay out of RunState save data.")


func _build_bleed_flow_context() -> Dictionary:
	var loader: ContentLoader = ContentLoader.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 60
	run_state.hunger = RunState.DEFAULT_HUNGER
	run_state.xp = 0
	run_state.current_level = 1
	run_state.stage_index = 1

	var weapon_def: Dictionary = loader.load_definition("Weapons", "iron_sword")
	var enemy_def: Dictionary = loader.load_definition("Enemies", "barbed_hunter")

	var flow: CombatFlow = CombatFlow.new()
	flow.setup_combat(run_state, enemy_def, weapon_def)
	return {
		"flow": flow,
		"run_state": run_state,
	}
