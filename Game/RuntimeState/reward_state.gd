# Layer: RuntimeState
extends RefCounted
class_name RewardState

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")

const SOURCE_COMBAT_VICTORY: String = "combat_victory"
const SOURCE_REWARD_NODE: String = "reward_node"
const SELECTION_MODE_ROTATE_BY_CONTEXT: String = "rotate_by_context"
const SELECTION_MODE_SEEDED_REWARD_RNG: String = "seeded_reward_rng"

var source_context: String = ""
var title_text: String = ""
var offers: Array[Dictionary] = []
var generation_context: Dictionary = {}


func setup_for_source(source_name: String, context: Dictionary = {}) -> void:
	source_context = source_name
	generation_context = _extract_generation_context(context)
	var loader: ContentLoader = ContentLoaderScript.new()
	var reward_definition: Dictionary = loader.load_definition("Rewards", source_context)
	var display: Dictionary = reward_definition.get("display", {})
	var rules: Dictionary = reward_definition.get("rules", {})

	title_text = String(display.get("name", "Choose a reward"))
	offers = _build_offer_list(rules)


func get_offer_by_id(offer_id: String) -> Dictionary:
	for offer in offers:
		if String(offer.get("offer_id", "")) == offer_id:
			return offer.duplicate(true)
	return {}


func to_save_dict() -> Dictionary:
	return {
		"source_context": source_context,
		"title_text": title_text,
		"offers": offers.duplicate(true),
	}


func load_from_save_dict(save_data: Dictionary) -> void:
	source_context = String(save_data.get("source_context", ""))
	title_text = String(save_data.get("title_text", ""))
	offers = _extract_offer_array(save_data.get("offers", []))
	generation_context = {}


func _build_offer_list(rules: Dictionary) -> Array[Dictionary]:
	var present_count: int = int(rules.get("present_count", 0))
	var selection_mode: String = String(rules.get("selection_mode", ""))
	var offer_pool: Array[Dictionary] = _extract_offer_array(rules.get("offer_pool", []))
	if offer_pool.is_empty():
		return _extract_offer_array(rules.get("offers", []))

	if present_count <= 0:
		present_count = offer_pool.size()
	present_count = min(present_count, offer_pool.size())

	if selection_mode == SELECTION_MODE_SEEDED_REWARD_RNG:
		return _build_seeded_offer_window(offer_pool, present_count)

	var start_index: int = _derive_offer_start_index(offer_pool.size(), selection_mode)
	var selected_offers: Array[Dictionary] = []
	for offset in range(present_count):
		var pool_index: int = posmod(start_index + offset, offer_pool.size())
		selected_offers.append(offer_pool[pool_index].duplicate(true))
	return selected_offers


func _extract_offer_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result

	for entry in value:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		result.append((entry as Dictionary).duplicate(true))
	return result


func _extract_generation_context(context: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var current_node_id: int = int(context.get("current_node_id", context.get("current_node_index", 0)))
	result["current_node_id"] = current_node_id
	for key in ["stage_index", "current_level", "reward_rng_seed", "reward_rng_draw_index"]:
		if context.has(key):
			result[key] = int(context.get(key, 0))
	return result


func _derive_offer_start_index(pool_size: int, selection_mode: String) -> int:
	if pool_size <= 0:
		return 0
	if generation_context.is_empty():
		return 0
	if selection_mode != SELECTION_MODE_ROTATE_BY_CONTEXT:
		return 0

	var current_node_id: int = max(0, int(generation_context.get("current_node_id", 0)))
	var stage_index: int = max(1, int(generation_context.get("stage_index", 1)))
	var source_offset: int = _source_rotation_offset()
	return posmod(current_node_id + ((stage_index - 1) * 2) + source_offset, pool_size)


func _source_rotation_offset() -> int:
	match source_context:
		SOURCE_COMBAT_VICTORY:
			return 4
		SOURCE_REWARD_NODE:
			return 3
		_:
			return 0


func _build_seeded_offer_window(offer_pool: Array[Dictionary], present_count: int) -> Array[Dictionary]:
	var start_index: int = _derive_seeded_start_index(offer_pool.size())
	var selected_offers: Array[Dictionary] = []
	for offset in range(present_count):
		var pool_index: int = posmod(start_index + offset, offer_pool.size())
		selected_offers.append(offer_pool[pool_index].duplicate(true))
	return selected_offers


func _derive_seeded_start_index(pool_size: int) -> int:
	if pool_size <= 0:
		return 0
	var reward_rng_seed: int = int(generation_context.get("reward_rng_seed", 0))
	if reward_rng_seed <= 0:
		return 0
	return posmod(reward_rng_seed, pool_size)
