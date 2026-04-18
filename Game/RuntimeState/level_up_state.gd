# Layer: RuntimeState
extends RefCounted
class_name LevelUpState

const SOURCE_REWARD_RESOLUTION: String = "reward_resolution"
const SOURCE_EVENT_RESOLUTION: String = "event_resolution"
const SOURCE_LEVEL_CHAIN: String = "level_chain"

const LEVEL_THRESHOLDS: Dictionary = {
	2: 10,
	3: 25,
	4: 45,
	5: 70,
}

var source_context: String = ""
var current_level: int = 1
var target_level: int = 2
var offers: Array[Dictionary] = []


static func threshold_for_level(level: int) -> int:
	return int(LEVEL_THRESHOLDS.get(level, -1))


func setup_for_level(source_name: String, from_level: int, offer_list: Array[Dictionary], replacement_needed: bool = false) -> void:
	source_context = source_name
	current_level = from_level
	target_level = current_level + 1
	offers = offer_list.duplicate(true)
	# Legacy argument kept only so old tests/callers do not widen this migration patch.
	# Current perk-based level-up flow no longer uses shared-inventory replacement pressure.
	if replacement_needed:
		pass


func get_offer_by_id(offer_id: String) -> Dictionary:
	for offer in offers:
		if String(offer.get("offer_id", "")) == offer_id:
			return offer.duplicate(true)
	return {}


func to_save_dict() -> Dictionary:
	return {
		"source_context": source_context,
		"current_level": current_level,
		"target_level": target_level,
		"offers": offers.duplicate(true),
	}


func load_from_save_dict(save_data: Dictionary) -> void:
	source_context = String(save_data.get("source_context", ""))
	current_level = int(save_data.get("current_level", 1))
	target_level = int(save_data.get("target_level", current_level + 1))
	offers = _extract_offer_array(save_data.get("offers", []))


func _extract_offer_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result

	for entry in value:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		result.append((entry as Dictionary).duplicate(true))
	return result
