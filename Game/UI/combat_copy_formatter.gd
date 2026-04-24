# Layer: UI
extends RefCounted
class_name CombatCopyFormatter


static func build_intent_title_text() -> String:
	return "Next Threat"


static func build_intent_summary_text(intent: Dictionary, preview_snapshot: Dictionary = {}) -> String:
	var extra_effects: PackedStringArray = _extract_intent_extra_effect_names(intent)
	var intent_damage: int = _extract_visible_intent_damage(intent, preview_snapshot)
	if intent_damage > 0:
		var hit_copy: String = "Heavy hit" if _intent_is_heavy_damage(intent) else "Hit"
		if extra_effects.is_empty():
			return "%s for %d" % [hit_copy, intent_damage]
		return "%s for %d + %s" % [hit_copy, intent_damage, " + ".join(extra_effects)]

	if not extra_effects.is_empty():
		return "Applies %s" % ", ".join(extra_effects)

	return _humanize_identifier(String(intent.get("action_family", intent.get("intent_id", "unknown"))))


static func build_intent_detail_text(intent: Dictionary) -> String:
	var detail_parts: PackedStringArray = []
	if _intent_is_heavy_damage(intent):
		detail_parts.append("High threat.")
	var extra_effects: PackedStringArray = _extract_intent_extra_effect_names(intent)
	if not extra_effects.is_empty():
		detail_parts.append("Also applies %s." % ", ".join(extra_effects))
	return " ".join(detail_parts)


static func build_intent_reveal_text(intent: Dictionary) -> String:
	if intent.is_empty():
		return "Enemy telegraphs nothing."

	var summary_text: String = build_intent_summary_text(intent)
	var detail_text: String = build_intent_detail_text(intent)
	var reveal_text: String = "Enemy telegraphs %s." % summary_text.to_lower()
	if detail_text.is_empty():
		return reveal_text
	return "%s %s" % [reveal_text, detail_text]


static func build_enemy_type_text(combat_state: CombatState) -> String:
	if combat_state == null:
		return "Unknown"
	var tags_variant: Variant = combat_state.enemy_definition.get("tags", [])
	if typeof(tags_variant) != TYPE_ARRAY:
		return "Unknown"

	for tag_value in tags_variant:
		var tag: String = String(tag_value)
		if tag.is_empty() or tag == "enemy":
			continue
		return _humanize_identifier(tag)

	return "Unknown"


static func build_enemy_trait_text(combat_state: CombatState) -> String:
	if combat_state == null:
		return ""
	var traits_variant: Variant = combat_state.enemy_definition.get("rules", {}).get("traits", [])
	if typeof(traits_variant) != TYPE_ARRAY:
		return ""

	var trait_names: PackedStringArray = []
	for trait_value in traits_variant:
		var trait_name: String = _humanize_identifier(String(trait_value))
		if not trait_name.is_empty():
			trait_names.append(trait_name)
	return ", ".join(trait_names)


static func build_enemy_overview_text(combat_state: CombatState) -> String:
	var overview_parts: PackedStringArray = []
	var enemy_type_text: String = build_enemy_type_text(combat_state)
	if not enemy_type_text.is_empty() and enemy_type_text != "Unknown":
		overview_parts.append(enemy_type_text)
	var enemy_trait_text: String = build_enemy_trait_text(combat_state)
	if not enemy_trait_text.is_empty():
		overview_parts.append(enemy_trait_text)
	if overview_parts.is_empty():
		return "Unknown"
	return " | ".join(overview_parts)


static func build_enemy_hp_text(combat_state: CombatState, preview_snapshot: Dictionary = {}) -> String:
	if combat_state == null:
		return "HP 0/0 | Armor 0"
	var rules: Dictionary = combat_state.enemy_definition.get("rules", {})
	var stats: Dictionary = rules.get("stats", {})
	var max_hp: int = max(1, int(stats.get("base_hp", combat_state.enemy_hp)))
	return "HP %d/%d | Armor %d" % [
		combat_state.enemy_hp,
		max_hp,
		_extract_enemy_defense_value(combat_state, preview_snapshot),
	]


static func build_attack_action_preview(preview_snapshot: Dictionary) -> String:
	if preview_snapshot.is_empty():
		return "Deal damage | spend durability"

	var attack_fragments: PackedStringArray = []
	var attack_damage: int = int(preview_snapshot.get("attack_damage_preview", 0))
	if bool(preview_snapshot.get("uses_fallback_attack", false)):
		attack_fragments.append("Fallback %d dmg" % attack_damage)
	else:
		attack_fragments.append("Deal %d dmg" % attack_damage)
	var dodge_chance: int = int(preview_snapshot.get("attack_dodge_chance", 0))
	if dodge_chance > 0:
		attack_fragments.append("%d%% miss" % dodge_chance)
	var durability_spend: int = int(preview_snapshot.get("durability_spend_preview", 0))
	if durability_spend > 0:
		attack_fragments.append("-%d dur" % durability_spend)
	return " | ".join(attack_fragments)


static func build_defend_action_preview(preview_snapshot: Dictionary) -> String:
	if preview_snapshot.is_empty():
		return "Gain guard before the hit | Costs extra hunger"
	return "Gain %d guard | Take %d dmg | -%d hunger" % [
		int(preview_snapshot.get("guard_gain_preview", 0)),
		int(preview_snapshot.get("guard_damage_preview", 0)),
		int(preview_snapshot.get("defend_hunger_cost_preview", preview_snapshot.get("hunger_tick_preview", 1))),
	]


static func _extract_enemy_defense_value(combat_state: CombatState, preview_snapshot: Dictionary = {}) -> int:
	if not preview_snapshot.is_empty() and preview_snapshot.has("enemy_defense_preview"):
		return max(0, int(preview_snapshot.get("enemy_defense_preview", 0)))
	if combat_state == null:
		return 0
	return _extract_enemy_definition_defense(combat_state.enemy_definition)


static func _extract_enemy_definition_defense(enemy_definition: Dictionary) -> int:
	if enemy_definition.is_empty():
		return 0

	var total_defense: int = int(enemy_definition.get("rules", {}).get("stats", {}).get("incoming_damage_flat_reduction", 0))
	var behaviors_variant: Variant = enemy_definition.get("rules", {}).get("behaviors", [])
	if typeof(behaviors_variant) != TYPE_ARRAY:
		return max(0, total_defense)

	for behavior_value in behaviors_variant:
		if typeof(behavior_value) != TYPE_DICTIONARY:
			continue
		var behavior: Dictionary = behavior_value
		if String(behavior.get("trigger", "")) != "passive":
			continue
		var effects_variant: Variant = behavior.get("effects", [])
		if typeof(effects_variant) != TYPE_ARRAY:
			continue
		for effect_value in effects_variant:
			if typeof(effect_value) != TYPE_DICTIONARY:
				continue
			var effect: Dictionary = effect_value
			if String(effect.get("type", "")) != "modify_stat":
				continue
			var params_variant: Variant = effect.get("params", {})
			if typeof(params_variant) != TYPE_DICTIONARY:
				continue
			if String((params_variant as Dictionary).get("stat", "")) == "incoming_damage_flat_reduction":
				total_defense += int((params_variant as Dictionary).get("amount", 0))

	return max(0, total_defense)


static func _extract_intent_damage(intent: Dictionary) -> int:
	var total_damage: int = 0
	var effects_variant: Variant = intent.get("effects", [])
	if typeof(effects_variant) != TYPE_ARRAY:
		return 0
	for effect_value in effects_variant:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		if String(effect.get("type", "")) == "deal_damage":
			total_damage += int(effect.get("params", {}).get("base", 0))
	return max(0, total_damage)


static func _extract_visible_intent_damage(intent: Dictionary, preview_snapshot: Dictionary = {}) -> int:
	var authored_damage: int = _extract_intent_damage(intent)
	if not preview_snapshot.is_empty() and preview_snapshot.has("incoming_damage_preview"):
		var preview_damage: int = max(0, int(preview_snapshot.get("incoming_damage_preview", 0)))
		if preview_damage > 0 or authored_damage <= 0:
			return preview_damage
	return authored_damage


static func _extract_intent_extra_effect_names(intent: Dictionary) -> PackedStringArray:
	var effect_names: PackedStringArray = []
	var effects_variant: Variant = intent.get("effects", [])
	if typeof(effects_variant) != TYPE_ARRAY:
		return effect_names
	for effect_value in effects_variant:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		var effect_type: String = String(effect.get("type", ""))
		if effect_type == "deal_damage":
			continue
		match effect_type:
			"apply_status":
				var status_name: String = _humanize_identifier(String(effect.get("params", {}).get("definition_id", "")))
				if not status_name.is_empty():
					effect_names.append(status_name)
			_:
				var generic_name: String = _humanize_identifier(effect_type)
				if not generic_name.is_empty():
					effect_names.append(generic_name)
	return effect_names


static func _intent_is_heavy_damage(intent: Dictionary) -> bool:
	return _extract_intent_damage(intent) > 0 and String(intent.get("threat_level", "")) == "high"


static func _humanize_identifier(value: String) -> String:
	if value.is_empty():
		return ""
	var lowered: String = value.replace("_", " ")
	var words: PackedStringArray = lowered.split(" ", false)
	for index in range(words.size()):
		var word: String = words[index]
		if not word.is_empty():
			words[index] = word.substr(0, 1).to_upper() + word.substr(1)
	return " ".join(words)
