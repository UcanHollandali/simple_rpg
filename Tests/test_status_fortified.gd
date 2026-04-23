# Layer: Tests
extends SceneTree
class_name TestStatusFortified


func _init() -> void:
	test_fortified_reduces_incoming_damage_and_expires()
	print("test_status_fortified: all assertions passed")
	quit()


func test_fortified_reduces_incoming_damage_and_expires() -> void:
	var context: Dictionary = _build_flow_context("skeletal_hound")
	var flow: CombatFlow = context["flow"]
	var loader: ContentLoader = ContentLoader.new()
	var status_definition: Dictionary = loader.load_definition("Statuses", "fortified")

	var applied_status: Dictionary = flow.combat_state.apply_player_status_definition(status_definition)
	assert(String(applied_status.get("definition_id", "")) == "fortified", "Expected fortified to apply through the combat-local status lane.")

	var enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(enemy_result.get("damage_applied", -1)) == 0, "Expected fortified to reduce darting_bite from 2 to 0.")
	assert(flow.combat_state.player_hp == 60, "Expected fortified to fully preserve HP on the first hit.")

	var turn_end_result: Dictionary = flow.process_turn_end()
	assert(int(turn_end_result.get("player_hunger", -1)) == RunState.DEFAULT_HUNGER - 1, "Expected turn end to remain intact while fortified is active.")
	assert(flow.combat_state.player_statuses.size() == 1, "Expected fortified to remain active after the first turn end.")
	assert(int(flow.combat_state.player_statuses[0].get("remaining_turns", -1)) == 1, "Expected fortified to tick down after turn end.")

	var second_enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(second_enemy_result.get("damage_applied", -1)) == 0, "Expected fortified to fully absorb the hamstring snap after reduction.")

	flow.process_turn_end()
	for status in flow.combat_state.player_statuses:
		assert(String(status.get("definition_id", "")) != "fortified", "Expected fortified to expire after its second turn-end tick.")


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
