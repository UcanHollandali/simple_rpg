# Layer: Tests
extends SceneTree
class_name TestStatusEnraged


func _init() -> void:
	test_enraged_raises_damage_and_lowers_defense()
	print("test_status_enraged: all assertions passed")
	quit()


func test_enraged_raises_damage_and_lowers_defense() -> void:
	var context: Dictionary = _build_flow_context("drain_adept")
	var flow: CombatFlow = context["flow"]
	var loader: ContentLoader = ContentLoader.new()
	var status_definition: Dictionary = loader.load_definition("Statuses", "enraged")

	var applied_status: Dictionary = flow.combat_state.apply_player_status_definition(status_definition)
	assert(String(applied_status.get("definition_id", "")) == "enraged", "Expected enraged to apply through the combat-local status lane.")

	var attack_result: Dictionary = flow.process_player_attack()
	assert(int(attack_result.get("damage_applied", -1)) == 8, "Expected enraged to raise iron sword damage from 6 to 8.")
	assert(flow.combat_state.enemy_hp == 10, "Expected enraged attack to reduce drain adept HP from 18 to 10.")

	var enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(enemy_result.get("damage_applied", -1)) == 2, "Expected enraged not to push flat reduction below zero on the first adept hit.")
	assert(flow.combat_state.player_hp == 58, "Expected the return hit to stay at the adept's normal 2 damage with zero armor.")

	flow.process_turn_end()
	assert(flow.combat_state.player_statuses.size() == 2, "Expected enraged and weakened to coexist after the first turn.")


func _build_flow_context(enemy_definition_id: String) -> Dictionary:
	var loader: ContentLoader = ContentLoader.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 60
	run_state.hunger = RunState.DEFAULT_HUNGER
	run_state.xp = 0
	run_state.current_level = 1
	run_state.stage_index = 1

	var weapon_def: Dictionary = loader.load_definition("Weapons", "iron_sword")
	var enemy_def: Dictionary = loader.load_definition("Enemies", enemy_definition_id)

	var flow: CombatFlow = CombatFlow.new()
	flow.setup_combat(run_state, enemy_def, weapon_def)
	return {
		"flow": flow,
		"run_state": run_state,
	}
