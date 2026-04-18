# Layer: Tests
extends SceneTree
class_name TestRunStatusPresenter

const RunStatusPresenterScript = preload("res://Game/UI/run_status_presenter.gd")
const UiFormattingScript = preload("res://Game/UI/ui_formatting.gd")


func _init() -> void:
	test_shared_run_status_model_exposes_variants()
	test_ui_formatting_helpers_keep_shared_copy_stable()
	print("test_run_status_presenter: all assertions passed")
	quit()


func test_shared_run_status_model_exposes_variants() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 33
	run_state.hunger = 12
	run_state.gold = 15
	run_state.xp = 8
	run_state.current_level = 1
	run_state.inventory_state.weapon_instance["current_durability"] = 6
	run_state.inventory_state.weapon_instance["upgrade_level"] = 2

	assert(
		RunStatusPresenterScript.build_compact_status_text(run_state) == "HP 33 | Hunger 12 | Gold 15 | Durability 6",
		"Expected the raw compact fallback string to stay stable while the structured status strip becomes primary."
	)

	var standard_model: Dictionary = RunStatusPresenterScript.build_status_model(run_state, {
		"variant": RunStatusPresenterScript.VARIANT_STANDARD,
		"include_weapon": true,
		"include_xp": true,
	})
	var standard_primary: Array = standard_model.get("primary_items", [])
	var standard_secondary: Array = standard_model.get("secondary_items", [])
	var standard_progress: Array = standard_model.get("progress_items", [])
	assert(
		String(standard_model.get("variant", "")) == "standard",
		"Expected the shared presenter to preserve the requested standard variant."
	)
	assert(standard_primary.size() == 4, "Expected the shared presenter to emit four primary run-status chips.")
	assert(
		String((standard_primary[0] as Dictionary).get("value_text", "")) == "33/60",
		"Expected HP chips to expose current and max values in the structured run-status model."
	)
	assert(
		int((standard_primary[1] as Dictionary).get("current_value", -1)) == 12 and int((standard_primary[1] as Dictionary).get("max_value", -1)) == 20,
		"Expected hunger chips to expose numeric values so threshold feedback can stay presenter-backed instead of parsing display text."
	)
	assert(
		standard_secondary.size() == 1 and String((standard_secondary[0] as Dictionary).get("value_text", "")) == "Iron Sword +2",
		"Expected the standard run-status model to surface the active weapon summary."
	)
	assert(
		standard_progress.size() == 1 and String((standard_progress[0] as Dictionary).get("value_text", "")) == "8/10",
		"Expected the standard run-status model to surface next-level XP progress."
	)

	var minimal_model: Dictionary = RunStatusPresenterScript.build_status_model(run_state, {
		"variant": RunStatusPresenterScript.VARIANT_MINIMAL,
	})
	var minimal_secondary: Array = minimal_model.get("secondary_items", [])
	var minimal_progress: Array = minimal_model.get("progress_items", [])
	assert(
		String(minimal_model.get("variant", "")) == "minimal",
		"Expected the shared presenter to preserve the requested minimal variant."
	)
	assert(
		minimal_secondary.is_empty(),
		"Expected the minimal variant to omit secondary summary rows."
	)
	assert(
		minimal_progress.is_empty(),
		"Expected the minimal variant to omit progress rows."
	)


func test_ui_formatting_helpers_keep_shared_copy_stable() -> void:
	assert(
		UiFormattingScript.build_hp_text(18, 60, ": ") == "HP: 18/60",
		"Expected shared HP formatting to preserve combat-facing punctuation."
	)
	assert(
		UiFormattingScript.build_gold_text(9) == "Gold 9",
		"Expected shared gold formatting to preserve compact shell reads."
	)
	assert(
		UiFormattingScript.build_enemy_intent_summary({
			"action_family": "attack",
			"effects": [
				{"type": "deal_damage", "params": {"base": 6}},
				{"type": "apply_status", "params": {"definition_id": "poison"}},
			],
		}) == "Intent: Attack 6 + Poison",
		"Expected shared enemy intent formatting to preserve the player-facing combat summary."
	)
	assert(
		String(UiFormattingScript.build_consequence_preview_texts({
			"attack_damage_preview": 5,
			"attack_dodge_chance": 10,
			"uses_fallback_attack": false,
			"durability_spend_preview": 1,
			"defense_preview": 2,
			"incoming_damage_preview": 4,
			"guard_gain_preview": 2,
			"guard_absorb_preview": 2,
			"guard_damage_preview": 2,
			"hunger_tick_preview": 1,
		}).get("attack", "")) == "Hit 5 | Dodge 10%",
		"Expected shared consequence preview formatting to preserve combat tooltip copy."
	)
	assert(
		UiFormattingScript.build_status_summary([
			{
				"display_name": "Poison",
				"remaining_turns": 2,
			},
		], "none", "inline") == "Poison(2)",
		"Expected shared status-summary formatting to preserve the inline combat summary contract."
	)
