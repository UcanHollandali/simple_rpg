# Layer: Tests
extends SceneTree
class_name TestStatusCorroded


func _init() -> void:
	test_corroded_increases_weapon_durability_loss()
	print("test_status_corroded: all assertions passed")
	quit()


func test_corroded_increases_weapon_durability_loss() -> void:
	var context: Dictionary = _build_flow_context("skeletal_hound")
	var flow: CombatFlow = context["flow"]
	var loader: ContentLoader = ContentLoader.new()
	var status_definition: Dictionary = loader.load_definition("Statuses", "corroded")

	var applied_status: Dictionary = flow.combat_state.apply_player_status_definition(status_definition)
	assert(String(applied_status.get("definition_id", "")) == "corroded", "Expected corroded to apply through the combat-local status lane.")

	var full_turn_result: Dictionary = flow.resolve_attack_turn()
	var action_result: Dictionary = full_turn_result.get("action_result", {})
	assert(int(action_result.get("damage_applied", -1)) == 6, "Expected corroded not to change iron sword base damage.")
	assert(int(flow.combat_state.weapon_instance.get("current_durability", -1)) == 18, "Expected corroded to raise iron sword durability cost from 1 to 2.")
	assert(flow.combat_state.player_statuses.size() == 1, "Expected corroded to remain active after the first turn.")
	assert(int(flow.combat_state.player_statuses[0].get("remaining_turns", -1)) == 2, "Expected corroded to tick down after turn end.")


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
