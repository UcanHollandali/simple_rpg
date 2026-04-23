# Layer: Tests
extends SceneTree
class_name TestStatusWeakened


func _init() -> void:
	test_weakened_reduces_player_attack_and_expires_in_combat_state()
	print("test_status_weakened: all assertions passed")
	quit()


func test_weakened_reduces_player_attack_and_expires_in_combat_state() -> void:
	var context: Dictionary = _build_weakened_flow_context()
	var flow: CombatFlow = context["flow"]
	var run_state: RunState = context["run_state"]

	var defend_result: Dictionary = flow.process_defend()
	assert(not bool(defend_result.get("skipped", true)), "Expected defend to resolve before the first weaken hit.")

	var first_enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(first_enemy_result.get("damage_applied", -1)) == 0, "Expected defend guard to reduce the first weaken hit from 2 to 0.")
	assert(flow.combat_state.player_hp == 60, "Expected player HP to stay full after the first weaken hit is fully guarded.")
	assert(flow.combat_state.player_statuses.size() == 1, "Expected weakened status to be applied to the player.")
	assert(
		String(flow.combat_state.player_statuses[0].get("definition_id", "")) == "weakened",
		"Expected weakened to be the applied status."
	)
	assert(
		int(flow.combat_state.player_statuses[0].get("remaining_turns", -1)) == 2,
		"Expected weakened to start with 2 remaining turns."
	)

	var first_turn_end: Dictionary = flow.process_turn_end()
	assert(int(first_turn_end.get("player_hunger", -1)) == RunState.DEFAULT_HUNGER - 2, "Expected defend turn end to spend the baseline hunger tick plus the extra defend cost.")
	assert(
		int(flow.combat_state.player_statuses[0].get("remaining_turns", -1)) == 1,
		"Expected weakened to drop to 1 remaining turn after the first turn end."
	)

	var weakened_attack_result: Dictionary = flow.process_player_attack()
	assert(int(weakened_attack_result.get("damage_applied", -1)) == 4, "Expected weakened to reduce iron sword damage from 6 to 4.")
	assert(flow.combat_state.enemy_hp == 14, "Expected weakened attack to reduce enemy HP from 18 to 14.")

	var second_enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(second_enemy_result.get("damage_applied", -1)) == 2, "Expected second adept hit to deal normal 2 damage.")
	var second_turn_end: Dictionary = flow.process_turn_end()
	assert(int(second_turn_end.get("player_hunger", -1)) == RunState.DEFAULT_HUNGER - 3, "Expected hunger progression to remain intact on the second turn.")
	assert(flow.combat_state.player_statuses.is_empty(), "Expected weakened to expire after its second turn-end tick.")

	run_state.commit_combat_result(flow.combat_state)
	assert(run_state.player_hp == flow.combat_state.player_hp, "Expected committed run HP to reflect weakened-combat results.")
	assert(not run_state.to_save_dict().has("player_statuses"), "Expected combat-local weakened status to stay out of RunState save data.")


func _build_weakened_flow_context() -> Dictionary:
	var loader: ContentLoader = ContentLoader.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 60
	run_state.hunger = RunState.DEFAULT_HUNGER
	run_state.xp = 0
	run_state.current_level = 1
	run_state.stage_index = 1

	var weapon_def: Dictionary = loader.load_definition("Weapons", "iron_sword")
	var enemy_def: Dictionary = loader.load_definition("Enemies", "drain_adept")

	var flow: CombatFlow = CombatFlow.new()
	flow.setup_combat(run_state, enemy_def, weapon_def)
	return {
		"flow": flow,
		"run_state": run_state,
	}
