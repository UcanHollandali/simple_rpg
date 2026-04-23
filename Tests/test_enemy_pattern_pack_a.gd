# Layer: Tests
extends SceneTree
class_name TestEnemyPatternPackA

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const EnemySelectionPolicyScript = preload("res://Game/Application/enemy_selection_policy.gd")


func _init() -> void:
	test_pattern_pack_a_stage_pools_stay_live()
	test_pattern_pack_a_authors_readable_questions_inside_current_grammar()
	print("test_enemy_pattern_pack_a: all assertions passed")
	quit()


func test_pattern_pack_a_stage_pools_stay_live() -> void:
	var loader: ContentLoader = ContentLoaderScript.new()
	var selection_policy: EnemySelectionPolicy = EnemySelectionPolicyScript.new()

	var stage_one_enemy_ids: Array[String] = selection_policy.list_combat_enemy_definition_ids(loader, 1)
	assert(stage_one_enemy_ids.has("mossback_ram"), "Expected stage-1 rotation to keep Mossback Ram live for the light-into-heavy question.")
	assert(stage_one_enemy_ids.has("skeletal_hound"), "Expected stage-1 rotation to keep Skeletal Hound live for the bleed-chase question.")

	var stage_two_enemy_ids: Array[String] = selection_policy.list_combat_enemy_definition_ids(loader, 2)
	assert(stage_two_enemy_ids.has("chain_trapper"), "Expected stage-2 rotation to keep Chain Trapper live for the control punish line.")
	assert(stage_two_enemy_ids.has("grave_chanter"), "Expected stage-2 rotation to keep Grave Chanter live for the stun punish line.")

	var stage_three_enemy_ids: Array[String] = selection_policy.list_combat_enemy_definition_ids(loader, 3)
	assert(stage_three_enemy_ids.has("dusk_pikeman"), "Expected stage-3 rotation to keep Dusk Pikeman live for the impale timing question.")
	assert(stage_three_enemy_ids.has("ashen_sapper"), "Expected stage-3 rotation to keep Ashen Sapper live for the corrosion breach line.")

	assert(selection_policy.find_boss_enemy_definition_id(loader, 1) == "tollhouse_captain", "Expected stage-1 boss selection to remain on Tollhouse Captain for the revised spike pattern.")


func test_pattern_pack_a_authors_readable_questions_inside_current_grammar() -> void:
	var loader: ContentLoader = ContentLoaderScript.new()

	var mossback_ram: Dictionary = loader.load_definition("Enemies", "mossback_ram")
	assert(_intent_damage_sequence(mossback_ram) == [1, 1, 5], "Expected Mossback Ram to author a clean chip-chip-crash damage sequence.")
	assert(_intent_threat_sequence(mossback_ram) == ["low", "low", "high"], "Expected Mossback Ram to read as a clear light-into-heavy guard test.")
	assert(_all_effect_types_are_supported(mossback_ram), "Expected Mossback Ram to stay inside the current supported effect families.")

	var skeletal_hound: Dictionary = loader.load_definition("Enemies", "skeletal_hound")
	assert(_intent_pool_applies_status(skeletal_hound, "bleed"), "Expected Skeletal Hound to keep a bleed pressure beat.")
	assert(_max_intent_damage(skeletal_hound) >= 5, "Expected Skeletal Hound to cash in with a real lunge punish.")
	assert((skeletal_hound.get("rules", {}) as Dictionary).get("behaviors", []).is_empty(), "Expected Skeletal Hound to keep the pattern authored in the intent pool instead of hidden passive escalation.")
	assert(_all_effect_types_are_supported(skeletal_hound), "Expected Skeletal Hound to stay inside the current supported effect families.")

	var dusk_pikeman: Dictionary = loader.load_definition("Enemies", "dusk_pikeman")
	assert(_intent_threat_sequence(dusk_pikeman) == ["low", "medium", "high"], "Expected Dusk Pikeman to keep a readable setup-into-impale ladder.")
	assert(_intent_pool_applies_status(dusk_pikeman, "weakened"), "Expected Dusk Pikeman to spoil the next swing before the punish turn.")
	assert(_max_intent_damage(dusk_pikeman) >= 8, "Expected Dusk Pikeman to keep a real high-threat impale beat.")

	var ashen_sapper: Dictionary = loader.load_definition("Enemies", "ashen_sapper")
	assert(_intent_pool_applies_status(ashen_sapper, "corroded"), "Expected Ashen Sapper to keep corrosion pressure live.")
	assert(_intent_damage_sequence(ashen_sapper) == [2, 2, 7], "Expected Ashen Sapper to probe, corrode, then breach in one readable line.")
	assert(_all_effect_types_are_supported(ashen_sapper), "Expected Ashen Sapper to stay inside the current supported effect families.")

	var chain_trapper: Dictionary = loader.load_definition("Enemies", "chain_trapper")
	assert(String(chain_trapper.get("encounter_tier", "")) == "minor", "Expected Chain Trapper to stay minor-tier so the current stage rotation keeps it live; broader elite routing remains deferred.")
	assert(_intent_pool_applies_status(chain_trapper, "weakened"), "Expected Chain Trapper to keep the weakened setup beat.")
	assert(_intent_pool_applies_status(chain_trapper, "corroded"), "Expected Chain Trapper to keep the corroded setup beat.")
	assert(_intent_pool_applies_status(chain_trapper, "bleed"), "Expected Chain Trapper to keep the bleed cash-in beat.")
	assert(_max_intent_damage(chain_trapper) >= 6, "Expected Chain Trapper to land a sharper punish than its setup turns.")

	var grave_chanter: Dictionary = loader.load_definition("Enemies", "grave_chanter")
	assert(String(grave_chanter.get("encounter_tier", "")) == "minor", "Expected Grave Chanter to stay minor-tier so the current stage rotation keeps it live; broader elite routing remains deferred.")
	assert(_intent_ids(grave_chanter) == ["finger_tap", "dulling_dirge", "vault_note"], "Expected Grave Chanter to open on light chip before the stun and heavy punish turns.")
	assert(_intent_pool_applies_status(grave_chanter, "stunned"), "Expected Grave Chanter to keep the stun setup beat.")
	assert(_max_intent_damage(grave_chanter) >= 6, "Expected Grave Chanter to keep a real punish note after the setup.")

	var tollhouse_captain: Dictionary = loader.load_definition("Enemies", "tollhouse_captain")
	assert(String(tollhouse_captain.get("encounter_tier", "")) == "elite", "Expected Tollhouse Captain to remain the authored elite-tagged boss example while encounter-tier flow behavior stays deferred.")
	assert(_intent_count(tollhouse_captain) == 3, "Expected Tollhouse Captain base intent pool to expose setup, pressure, and punish beats.")
	var boss_phases: Array = (tollhouse_captain.get("rules", {}) as Dictionary).get("boss_phases", [])
	assert(boss_phases.size() == 3, "Expected Tollhouse Captain to keep its three-phase boss read.")
	assert(String((boss_phases[0] as Dictionary).get("phase_id", "")) == "road_toll", "Expected the first Tollhouse Captain phase id to stay stable.")
	assert(String((((boss_phases[0] as Dictionary).get("intent_pool", [])[0] as Dictionary).get("intent_id", ""))) == "captain_test_cut", "Expected Road Toll to still reveal the light setup cut first.")
	assert(String((((boss_phases[1] as Dictionary).get("intent_pool", [])[0] as Dictionary).get("intent_id", ""))) == "tollhouse_command", "Expected Captain's Push to still open on the weakening command.")
	assert(String((((boss_phases[2] as Dictionary).get("intent_pool", [])[0] as Dictionary).get("intent_id", ""))) == "captain_finish", "Expected Last Collector to open on the bleed spike beat.")
	assert(_phase_all_high((boss_phases[2] as Dictionary)), "Expected the final Tollhouse Captain phase to stay a true spike window.")
	assert(_all_effect_types_are_supported(tollhouse_captain), "Expected Tollhouse Captain to stay inside the current supported effect families.")


func _intent_count(enemy_definition: Dictionary) -> int:
	return ((enemy_definition.get("rules", {}) as Dictionary).get("intent_pool", []) as Array).size()


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


func _intent_damage_sequence(enemy_definition: Dictionary) -> Array[int]:
	var sequence: Array[int] = []
	var intent_pool: Array = (enemy_definition.get("rules", {}) as Dictionary).get("intent_pool", [])
	for intent_value in intent_pool:
		if typeof(intent_value) != TYPE_DICTIONARY:
			continue
		var intent: Dictionary = intent_value
		var damage_value: int = 0
		for effect_value in intent.get("effects", []):
			if typeof(effect_value) != TYPE_DICTIONARY:
				continue
			var effect: Dictionary = effect_value
			if String(effect.get("type", "")) != "deal_damage":
				continue
			damage_value += int((effect.get("params", {}) as Dictionary).get("base", 0))
		sequence.append(damage_value)
	return sequence


func _intent_threat_sequence(enemy_definition: Dictionary) -> Array[String]:
	var sequence: Array[String] = []
	var intent_pool: Array = (enemy_definition.get("rules", {}) as Dictionary).get("intent_pool", [])
	for intent_value in intent_pool:
		if typeof(intent_value) != TYPE_DICTIONARY:
			continue
		sequence.append(String((intent_value as Dictionary).get("threat_level", "")))
	return sequence


func _intent_ids(enemy_definition: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	var intent_pool: Array = (enemy_definition.get("rules", {}) as Dictionary).get("intent_pool", [])
	for intent_value in intent_pool:
		if typeof(intent_value) != TYPE_DICTIONARY:
			continue
		ids.append(String((intent_value as Dictionary).get("intent_id", "")))
	return ids


func _max_intent_damage(enemy_definition: Dictionary) -> int:
	var max_damage: int = 0
	for damage_value in _intent_damage_sequence(enemy_definition):
		max_damage = max(max_damage, int(damage_value))
	return max_damage


func _all_effect_types_are_supported(enemy_definition: Dictionary) -> bool:
	var allowed_effect_types: Dictionary = {
		"deal_damage": true,
		"apply_status": true,
	}
	var intent_pool: Array = (enemy_definition.get("rules", {}) as Dictionary).get("intent_pool", [])
	for intent_value in intent_pool:
		if typeof(intent_value) != TYPE_DICTIONARY:
			return false
		for effect_value in (intent_value as Dictionary).get("effects", []):
			if typeof(effect_value) != TYPE_DICTIONARY:
				return false
			if not allowed_effect_types.has(String((effect_value as Dictionary).get("type", ""))):
				return false
	var boss_phases: Array = (enemy_definition.get("rules", {}) as Dictionary).get("boss_phases", [])
	for phase_value in boss_phases:
		if typeof(phase_value) != TYPE_DICTIONARY:
			return false
		for intent_value in (phase_value as Dictionary).get("intent_pool", []):
			if typeof(intent_value) != TYPE_DICTIONARY:
				return false
			for effect_value in (intent_value as Dictionary).get("effects", []):
				if typeof(effect_value) != TYPE_DICTIONARY:
					return false
				if not allowed_effect_types.has(String((effect_value as Dictionary).get("type", ""))):
					return false
	return true


func _phase_all_high(phase_definition: Dictionary) -> bool:
	var intent_pool: Array = phase_definition.get("intent_pool", [])
	if intent_pool.is_empty():
		return false
	for intent_value in intent_pool:
		if typeof(intent_value) != TYPE_DICTIONARY:
			return false
		if String((intent_value as Dictionary).get("threat_level", "")) != "high":
			return false
	return true
