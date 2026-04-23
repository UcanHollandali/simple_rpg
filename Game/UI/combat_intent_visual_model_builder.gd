# Layer: UI
extends RefCounted
class_name CombatIntentVisualModelBuilder

const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")


static func build_enemy_bust_intent_visual_model(intent: Dictionary) -> Dictionary:
	if intent.is_empty():
		return {
			"visible": false,
			"semantic": "none",
			"accent_key": "attack",
			"badge_text": "",
			"icon_texture_path": "",
		}

	var uses_damage_effect: bool = _intent_uses_damage_effect(intent)
	var uses_non_damage_effect: bool = _intent_uses_non_damage_effect(intent)
	var primary_status_name: String = _extract_primary_intent_status_name(intent)
	var threat_level: String = String(intent.get("threat_level", ""))
	if uses_damage_effect and threat_level == "high":
		return {
			"visible": true,
			"semantic": "heavy_attack",
			"accent_key": "heavy",
			"badge_text": "HEAVY",
			"icon_texture_path": UiAssetPathsScript.ENEMY_INTENT_HEAVY_ICON_TEXTURE_PATH,
		}
	if uses_non_damage_effect:
		return {
			"visible": true,
			"semantic": "status_pressure",
			"accent_key": "status",
			"badge_text": primary_status_name.to_upper() if not primary_status_name.is_empty() else "STATUS",
			"icon_texture_path": UiAssetPathsScript.ENEMY_INTENT_ATTACK_ICON_TEXTURE_PATH if uses_damage_effect else "",
		}
	if uses_damage_effect:
		return {
			"visible": true,
			"semantic": "attack",
			"accent_key": "attack",
			"badge_text": "ATTACK",
			"icon_texture_path": UiAssetPathsScript.ENEMY_INTENT_ATTACK_ICON_TEXTURE_PATH,
		}
	return {
		"visible": true,
		"semantic": "watch",
		"accent_key": "watch",
		"badge_text": _humanize_identifier_token(String(intent.get("action_family", intent.get("intent_id", "watch")))).to_upper(),
		"icon_texture_path": "",
	}


static func _intent_uses_damage_effect(intent: Dictionary) -> bool:
	var effects: Array = intent.get("effects", [])
	if effects.is_empty():
		return String(intent.get("action_family", "")) == "attack"
	for effect_value in effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		if String((effect_value as Dictionary).get("type", "")) == "deal_damage":
			return true
	return false


static func _intent_uses_non_damage_effect(intent: Dictionary) -> bool:
	var effects: Array = intent.get("effects", [])
	for effect_value in effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		if String((effect_value as Dictionary).get("type", "")) != "deal_damage":
			return true
	return false


static func _extract_primary_intent_status_name(intent: Dictionary) -> String:
	var effects: Array = intent.get("effects", [])
	for effect_value in effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value as Dictionary
		var effect_type: String = String(effect.get("type", ""))
		match effect_type:
			"deal_damage":
				continue
			"apply_status":
				return _humanize_identifier_token(String(effect.get("params", {}).get("definition_id", "")))
			_:
				return _humanize_identifier_token(effect_type)
	return ""


static func _humanize_identifier_token(value: String) -> String:
	if value.is_empty():
		return ""
	var lowered: String = value.replace("_", " ")
	var words: PackedStringArray = lowered.split(" ", false)
	for index in range(words.size()):
		var word: String = words[index]
		if not word.is_empty():
			words[index] = word.substr(0, 1).to_upper() + word.substr(1)
	return " ".join(words)
