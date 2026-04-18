# Layer: Tests
extends SceneTree
class_name TestEnemyContent

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const EnemySelectionPolicyScript = preload("res://Game/Application/enemy_selection_policy.gd")


func _init() -> void:
	test_new_enemy_pack_is_live_in_stage_rotation()
	test_enemy_pack_scrubs_brace_wording_from_authored_questions()
	print("test_enemy_content: all assertions passed")
	quit()


func test_new_enemy_pack_is_live_in_stage_rotation() -> void:
	var loader: ContentLoader = ContentLoaderScript.new()
	var selection_policy: EnemySelectionPolicy = EnemySelectionPolicyScript.new()

	var stage_one_enemy_ids: Array[String] = selection_policy.list_combat_enemy_definition_ids(loader, 1)
	assert(stage_one_enemy_ids.has("carrion_runner"), "Expected stage-1 rotation to include the new Carrion Runner.")
	assert(stage_one_enemy_ids.has("skeletal_hound"), "Expected stage-1 rotation to surface Skeletal Hound once the beast lane is adapted into the stage-1 pool.")

	var stage_two_enemy_ids: Array[String] = selection_policy.list_combat_enemy_definition_ids(loader, 2)
	assert(stage_two_enemy_ids.has("briar_alchemist"), "Expected stage-2 rotation to keep Briar Alchemist live after the attrition-model adaptation.")
	assert(stage_two_enemy_ids.has("chain_trapper"), "Expected stage-2 rotation to keep Chain Trapper live after the disruption-model adaptation.")
	assert(stage_two_enemy_ids.has("cutpurse_duelist"), "Expected stage-2 rotation to include the new Cutpurse Duelist.")
	assert(stage_two_enemy_ids.has("thornwood_warder"), "Expected stage-2 rotation to include the new Thornwood Warder.")

	var stage_three_enemy_ids: Array[String] = selection_policy.list_combat_enemy_definition_ids(loader, 3)
	assert(stage_three_enemy_ids.has("gatebreaker_brute"), "Expected stage-3 rotation to include the new Gatebreaker Brute.")
	assert(stage_three_enemy_ids.has("ashen_sapper"), "Expected stage-3 rotation to include the new Ashen Sapper.")
	assert(selection_policy.find_boss_enemy_definition_id(loader, 1) == "tollhouse_captain", "Expected stage-1 boss selection to use the new Tollhouse Captain.")

	var carrion_runner: Dictionary = loader.load_definition("Enemies", "carrion_runner")
	assert(_intent_count(carrion_runner) == 3, "Expected Carrion Runner to author exactly 3 readable intents.")
	assert(_intent_pool_applies_status(carrion_runner, "bleed"), "Expected Carrion Runner to carry an early bleed pressure beat.")

	var cutpurse_duelist: Dictionary = loader.load_definition("Enemies", "cutpurse_duelist")
	assert(_intent_count(cutpurse_duelist) == 3, "Expected Cutpurse Duelist to author exactly 3 readable intents.")
	assert(_intent_pool_applies_status(cutpurse_duelist, "bleed"), "Expected Cutpurse Duelist to carry a bleed pressure beat.")
	assert(_intent_pool_applies_status(cutpurse_duelist, "weakened"), "Expected Cutpurse Duelist to carry a weakened setup beat.")

	var thornwood_warder: Dictionary = loader.load_definition("Enemies", "thornwood_warder")
	assert(_intent_count(thornwood_warder) == 3, "Expected Thornwood Warder to author exactly 3 readable intents.")
	assert(_passive_stat_amount(thornwood_warder, "incoming_damage_flat_reduction") == 2, "Expected Thornwood Warder to express shielded patience through flat mitigation.")

	var gatebreaker_brute: Dictionary = loader.load_definition("Enemies", "gatebreaker_brute")
	assert(_intent_count(gatebreaker_brute) == 3, "Expected Gatebreaker Brute to author exactly 3 readable intents.")
	assert(_max_intent_damage(gatebreaker_brute) >= 8, "Expected Gatebreaker Brute to expose a real telegraphed heavy hit.")

	var ashen_sapper: Dictionary = loader.load_definition("Enemies", "ashen_sapper")
	assert(_intent_count(ashen_sapper) == 3, "Expected Ashen Sapper to author exactly 3 readable intents.")
	assert(_intent_pool_applies_status(ashen_sapper, "corroded"), "Expected Ashen Sapper to pressure durability through corroded setup.")

	var skeletal_hound: Dictionary = loader.load_definition("Enemies", "skeletal_hound")
	assert(_intent_count(skeletal_hound) == 3, "Expected Skeletal Hound to author exactly 3 readable intents.")
	assert(_intent_pool_applies_status(skeletal_hound, "bleed"), "Expected Skeletal Hound to keep a bleed chase beat.")
	assert(_max_intent_damage(skeletal_hound) >= 4, "Expected Skeletal Hound to keep one harder lunge beat behind its chip pattern.")

	var briar_alchemist: Dictionary = loader.load_definition("Enemies", "briar_alchemist")
	assert(_intent_count(briar_alchemist) == 3, "Expected Briar Alchemist to author exactly 3 readable intents.")
	assert(_intent_pool_applies_status(briar_alchemist, "poison"), "Expected Briar Alchemist to keep poison pressure live.")
	assert(_intent_pool_applies_status(briar_alchemist, "corroded"), "Expected Briar Alchemist to pressure durability through corrosive setup.")
	assert(_intent_pool_applies_status(briar_alchemist, "weakened"), "Expected Briar Alchemist to carry one weakening punish beat.")

	var chain_trapper: Dictionary = loader.load_definition("Enemies", "chain_trapper")
	assert(_intent_count(chain_trapper) == 3, "Expected Chain Trapper to author exactly 3 readable intents.")
	assert(_intent_pool_applies_status(chain_trapper, "weakened"), "Expected Chain Trapper to foul clean prep turns through weakened.")
	assert(_intent_pool_applies_status(chain_trapper, "corroded"), "Expected Chain Trapper to pressure weapon upkeep through corroded.")
	assert(_intent_pool_applies_status(chain_trapper, "bleed"), "Expected Chain Trapper to keep one bleeding cash-in beat.")


func test_enemy_pack_scrubs_brace_wording_from_authored_questions() -> void:
	var loader: ContentLoader = ContentLoaderScript.new()
	for definition_id in loader.list_definition_ids("Enemies"):
		var enemy_definition: Dictionary = loader.load_definition("Enemies", definition_id)
		var question_text: String = String(enemy_definition.get("design_intent_question", ""))
		assert(
			not question_text.contains("Brace"),
			"Expected enemy design intent copy to stop referencing removed Brace semantics: %s" % definition_id
		)


func _intent_count(enemy_definition: Dictionary) -> int:
	return (enemy_definition.get("rules", {}) as Dictionary).get("intent_pool", []).size()


func _intent_pool_applies_status(enemy_definition: Dictionary, status_definition_id: String) -> bool:
	var intent_pool: Array = (enemy_definition.get("rules", {}) as Dictionary).get("intent_pool", [])
	for intent_value in intent_pool:
		if typeof(intent_value) != TYPE_DICTIONARY:
			continue
		var intent: Dictionary = intent_value
		for effect_value in intent.get("effects", []):
			if typeof(effect_value) != TYPE_DICTIONARY:
				continue
			var effect: Dictionary = effect_value
			if String(effect.get("type", "")) != "apply_status":
				continue
			var params: Dictionary = effect.get("params", {})
			if String(params.get("definition_id", "")) == status_definition_id:
				return true
	return false


func _passive_stat_amount(enemy_definition: Dictionary, stat_name: String) -> int:
	var behaviors: Array = (enemy_definition.get("rules", {}) as Dictionary).get("behaviors", [])
	for behavior_value in behaviors:
		if typeof(behavior_value) != TYPE_DICTIONARY:
			continue
		var behavior: Dictionary = behavior_value
		if String(behavior.get("trigger", "")) != "passive":
			continue
		for effect_value in behavior.get("effects", []):
			if typeof(effect_value) != TYPE_DICTIONARY:
				continue
			var effect: Dictionary = effect_value
			if String(effect.get("type", "")) != "modify_stat":
				continue
			var params: Dictionary = effect.get("params", {})
			if String(params.get("stat", "")) == stat_name:
				return int(params.get("amount", 0))
	return 0


func _max_intent_damage(enemy_definition: Dictionary) -> int:
	var max_damage: int = 0
	var intent_pool: Array = (enemy_definition.get("rules", {}) as Dictionary).get("intent_pool", [])
	for intent_value in intent_pool:
		if typeof(intent_value) != TYPE_DICTIONARY:
			continue
		var intent: Dictionary = intent_value
		for effect_value in intent.get("effects", []):
			if typeof(effect_value) != TYPE_DICTIONARY:
				continue
			var effect: Dictionary = effect_value
			if String(effect.get("type", "")) != "deal_damage":
				continue
			var params: Dictionary = effect.get("params", {})
			max_damage = max(max_damage, int(params.get("base", 0)))
	return max_damage
