# Layer: Tests
extends SceneTree
class_name TestStatusPoison


func _init() -> void:
	test_poison_applies_ticks_and_expires_in_combat_state()
	print("test_status_poison: all assertions passed")
	quit()


func test_poison_applies_ticks_and_expires_in_combat_state() -> void:
	var context: Dictionary = _build_poison_flow_context()
	var flow: CombatFlow = context["flow"]
	var run_state: RunState = context["run_state"]

	var defend_result: Dictionary = flow.process_defend()
	assert(not bool(defend_result.get("skipped", true)), "Expected defend to resolve before the first poison attack.")

	var enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(enemy_result.get("damage_applied", -1)) == 2, "Expected defend guard to reduce the first venom hit from 4 to 2.")
	assert(flow.combat_state.player_hp == 58, "Expected player HP to drop from 60 to 58 after the first venom hit.")
	assert(flow.combat_state.player_statuses.size() == 1, "Expected poison status to be applied to the player.")
	assert(
		String(flow.combat_state.player_statuses[0].get("definition_id", "")) == "poison",
		"Expected poison to be the applied status."
	)
	assert(
		int(flow.combat_state.player_statuses[0].get("remaining_turns", -1)) == 2,
		"Expected poison to start with 2 remaining turns."
	)

	var first_turn_end: Dictionary = flow.process_turn_end()
	assert(flow.combat_state.player_hp == 56, "Expected poison to tick for 2 damage at the first turn end.")
	assert(
		int(flow.combat_state.player_statuses[0].get("remaining_turns", -1)) == 1,
		"Expected poison to drop to 1 remaining turn after the first tick."
	)
	assert(int(first_turn_end.get("player_hunger", -1)) == RunState.DEFAULT_HUNGER - 1, "Expected normal hunger drain to continue after poison resolution.")

	flow.process_defend()
	var second_enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(second_enemy_result.get("damage_applied", -1)) == 0, "Expected defend guard to blank the second venom enemy hit from 2 to 0.")

	var second_turn_end: Dictionary = flow.process_turn_end()
	assert(flow.combat_state.player_hp == 54, "Expected second poison tick to apply before the status expires.")
	assert(flow.combat_state.player_statuses.is_empty(), "Expected poison to expire after its second tick.")
	assert(int(second_turn_end.get("player_hunger", -1)) == RunState.DEFAULT_HUNGER - 2, "Expected hunger progression to remain intact on the second turn end.")

	run_state.commit_combat_result(flow.combat_state)
	assert(run_state.player_hp == 54, "Expected committed run HP to reflect combat-local poison damage.")
	assert(not run_state.to_save_dict().has("player_statuses"), "Expected combat-local statuses to stay out of RunState save data.")


func _build_poison_flow_context() -> Dictionary:
	var loader: ContentLoader = ContentLoader.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 60
	run_state.hunger = RunState.DEFAULT_HUNGER
	run_state.xp = 0
	run_state.current_level = 1
	run_state.stage_index = 1

	var weapon_def: Dictionary = loader.load_definition("Weapons", "iron_sword")
	var enemy_def: Dictionary = loader.load_definition("Enemies", "venom_scavenger")

	var flow: CombatFlow = CombatFlow.new()
	flow.setup_combat(run_state, enemy_def, weapon_def)
	return {
		"flow": flow,
		"run_state": run_state,
	}
