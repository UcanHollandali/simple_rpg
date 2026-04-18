# Layer: UI
extends RefCounted
class_name UiFormatting

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const LevelUpStateScript = preload("res://Game/RuntimeState/level_up_state.gd")


static func build_metric_value_text(current_value: int, max_value: int = -1) -> String:
	if max_value >= 0:
		return "%d/%d" % [current_value, max_value]
	return str(current_value)


static func build_metric_text(label_text: String, current_value: int, max_value: int = -1, separator: String = " ") -> String:
	return "%s%s%s" % [label_text, separator, build_metric_value_text(current_value, max_value)]


static func build_hp_text(current_value: int, max_value: int = -1, separator: String = " ") -> String:
	return build_metric_text("HP", current_value, max_value, separator)


static func build_hunger_text(current_value: int, max_value: int = -1, separator: String = " ") -> String:
	return build_metric_text("Hunger", current_value, max_value, separator)


static func build_durability_text(current_value: int, max_value: int = -1, separator: String = " ") -> String:
	return build_metric_text("Durability", current_value, max_value, separator)


static func build_gold_text(gold: int, separator: String = " ") -> String:
	return "Gold%s%d" % [separator, gold]


static func build_weapon_display_name(weapon_instance: Dictionary) -> String:
	var definition_id: String = String(weapon_instance.get("definition_id", "none"))
	if definition_id.is_empty() or definition_id == "none":
		return "None"

	var loader: ContentLoader = ContentLoaderScript.new()
	var weapon_definition: Dictionary = loader.load_definition("Weapons", definition_id)
	var display: Dictionary = weapon_definition.get("display", {})
	var display_name: String = String(display.get("name", definition_id))
	var upgrade_level: int = max(0, int(weapon_instance.get("upgrade_level", 0)))
	if upgrade_level <= 0:
		return display_name
	return "%s +%d" % [display_name, upgrade_level]


static func build_weapon_summary(weapon_instance: Dictionary, include_durability: bool = false) -> String:
	var weapon_name: String = build_weapon_display_name(weapon_instance)
	if weapon_name == "None":
		return "No weapon"
	if not include_durability:
		return weapon_name
	return "%s | Durability %d" % [
		weapon_name,
		int(weapon_instance.get("current_durability", 0)),
	]


static func build_xp_progress_model(current_xp: int, current_level: int) -> Dictionary:
	var next_level: int = max(1, current_level) + 1
	var threshold: int = LevelUpStateScript.threshold_for_level(next_level)
	if threshold < 0:
		var maxed_xp: int = max(0, current_xp)
		return {
			"label_text": "XP",
			"value_text": "%d/MAX" % maxed_xp,
			"current_value": 1,
			"max_value": 1,
			"fill_ratio": 1.0,
		}

	var capped_xp: int = clamp(current_xp, 0, threshold)
	return {
		"label_text": "XP -> Lv %d" % next_level,
		"value_text": "%d/%d" % [capped_xp, threshold],
		"current_value": capped_xp,
		"max_value": max(1, threshold),
		"fill_ratio": clamp(float(capped_xp) / float(max(1, threshold)), 0.0, 1.0),
	}


static func build_status_summary(statuses: Array[Dictionary], empty_text: String = "none", style: String = "inline") -> String:
	if statuses.is_empty():
		return empty_text

	var parts: PackedStringArray = []
	for status_value in statuses:
		if typeof(status_value) != TYPE_DICTIONARY:
			continue
		var status: Dictionary = status_value
		var display_name: String = String(status.get("display_name", status.get("definition_id", "")))
		var turns: int = int(status.get("remaining_turns", 0))
		match style:
			"chip":
				parts.append("%s %dT" % [display_name, turns])
			_:
				parts.append("%s(%d)" % [display_name, turns])

	if parts.is_empty():
		return empty_text
	return ", ".join(parts)


static func build_status_chip_texts(statuses: Array[Dictionary], empty_text: String) -> PackedStringArray:
	if statuses.is_empty():
		return PackedStringArray([empty_text])

	var result: PackedStringArray = []
	for status_value in statuses:
		if typeof(status_value) != TYPE_DICTIONARY:
			continue
		var status: Dictionary = status_value
		result.append("%s %dT" % [
			String(status.get("display_name", status.get("definition_id", ""))),
			int(status.get("remaining_turns", 0)),
		])
	if result.is_empty():
		return PackedStringArray([empty_text])
	return result


static func build_enemy_intent_summary(intent: Dictionary) -> String:
	if intent.is_empty():
		return "Intent: Unknown"

	var parts: PackedStringArray = []
	var total_damage: int = 0
	var status_names: PackedStringArray = []
	var effects: Array = intent.get("effects", [])
	for effect_value in effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		var effect_type: String = String(effect.get("type", ""))
		var params_variant: Variant = effect.get("params", {})
		var params: Dictionary = params_variant if typeof(params_variant) == TYPE_DICTIONARY else {}
		match effect_type:
			"deal_damage":
				total_damage += int(params.get("base", 0))
			"apply_status":
				var status_id: String = String(params.get("definition_id", ""))
				if not status_id.is_empty():
					status_names.append(_humanize_identifier(status_id))

	if total_damage > 0:
		parts.append("Attack %d" % total_damage)
	for status_name in status_names:
		parts.append(status_name)

	if parts.is_empty():
		parts.append(_humanize_identifier(String(intent.get("action_family", intent.get("intent_id", "unknown")))))

	return "Intent: %s" % " + ".join(parts)


static func build_consequence_preview_texts(preview_snapshot: Dictionary) -> Dictionary:
	if preview_snapshot.is_empty():
		return {
			"attack": "Hit ?",
			"defense": "Armor ?",
			"incoming": "Incoming ?",
			"defend": "Guard ?",
			"guard_result": "Guard ? | HP ?",
			"hunger_tick": "Tick -1 hunger",
			"durability_spend": "Swing -? durability",
			"intent_detail": "Incoming ? | Guard ?",
		}

	var attack_text: String = "Hit %d" % int(preview_snapshot.get("attack_damage_preview", 0))
	if bool(preview_snapshot.get("uses_fallback_attack", false)):
		attack_text = "Fallback %d" % int(preview_snapshot.get("attack_damage_preview", 0))
	var dodge_chance: int = int(preview_snapshot.get("attack_dodge_chance", 0))
	if dodge_chance > 0:
		attack_text = "%s | Dodge %d%%" % [attack_text, dodge_chance]

	return {
		"attack": attack_text,
		"defense": "Armor %d" % int(preview_snapshot.get("defense_preview", 0)),
		"incoming": "Incoming %d" % int(preview_snapshot.get("incoming_damage_preview", 0)),
		"defend": "Guard %d" % int(preview_snapshot.get("guard_gain_preview", 0)),
		"guard_result": "Guard %d | HP %d" % [
			int(preview_snapshot.get("guard_absorb_preview", 0)),
			int(preview_snapshot.get("guard_damage_preview", 0)),
		],
		"hunger_tick": "Tick -%d hunger" % int(preview_snapshot.get("hunger_tick_preview", 1)),
		"durability_spend": "Swing -%d durability" % int(preview_snapshot.get("durability_spend_preview", 0)),
		"intent_detail": "Incoming %d | Guard %d" % [
			int(preview_snapshot.get("incoming_damage_preview", 0)),
			int(preview_snapshot.get("guard_gain_preview", 0)),
		],
	}


static func _humanize_identifier(identifier: String) -> String:
	var trimmed_identifier: String = identifier.strip_edges()
	if trimmed_identifier.is_empty():
		return ""

	var words: PackedStringArray = trimmed_identifier.split("_", false)
	for index in range(words.size()):
		words[index] = words[index].capitalize()
	return " ".join(words)
