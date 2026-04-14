# Layer: Tests
extends SceneTree
class_name TestStatusStunned


func _init() -> void:
	test_stunned_skips_the_next_player_action_but_still_spends_the_turn()
	print("test_status_stunned: all assertions passed")
	quit()


func test_stunned_skips_the_next_player_action_but_still_spends_the_turn() -> void:
	var context: Dictionary = _build_flow_context("skeletal_hound")
	var flow: CombatFlow = context["flow"]
	var loader: ContentLoader = ContentLoader.new()
	var status_definition: Dictionary = loader.load_definition("Statuses", "stunned")

	var applied_status: Dictionary = flow.combat_state.apply_player_status_definition(status_definition, 1)
	assert(String(applied_status.get("definition_id", "")) == "stunned", "Expected stunned to apply through the combat-local status lane.")

	var full_turn_result: Dictionary = flow.resolve_attack_turn()
	var action_result: Dictionary = full_turn_result.get("action_result", {})
	assert(bool(action_result.get("skipped", false)), "Expected stunned to skip the chosen player action.")
	assert(bool(action_result.get("consume_turn", false)), "Expected stunned to consume the turn instead of behaving like a free cancel.")
	assert(String(action_result.get("skipped_reason", "")) == "stunned", "Expected stunned skip reason to stay explicit.")
	assert(int(flow.combat_state.weapon_instance.get("current_durability", -1)) == 20, "Expected stunned skip to avoid spending weapon durability.")

	var enemy_result: Dictionary = full_turn_result.get("enemy_result", {})
	assert(int(enemy_result.get("damage_applied", -1)) == 4, "Expected stunned turn to continue into the enemy action.")
	assert(int(flow.combat_state.current_turn) == 2, "Expected stunned skip to still advance combat to the next turn.")
	assert(flow.combat_state.player_statuses.is_empty(), "Expected stunned to expire after the skipped-action turn end.")


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
