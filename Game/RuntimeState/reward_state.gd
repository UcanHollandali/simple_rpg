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

	offer_pool = _filter_offer_pool_for_generation_context(offer_pool, present_count)

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
	if context.has("enemy_definition_id"):
		result["enemy_definition_id"] = String(context.get("enemy_definition_id", "")).strip_edges()
	if context.has("enemy_tags"):
		result["enemy_tags"] = _extract_string_array(context.get("enemy_tags", []))
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


func _filter_offer_pool_for_generation_context(offer_pool: Array[Dictionary], present_count: int) -> Array[Dictionary]:
	var stage_filtered_pool: Array[Dictionary] = _filter_offer_pool_by_stage(offer_pool)
	var preferred_pool: Array[Dictionary] = _prioritize_offer_pool_for_enemy_tags(stage_filtered_pool, present_count)
	return preferred_pool if not preferred_pool.is_empty() else stage_filtered_pool


func _filter_offer_pool_by_stage(offer_pool: Array[Dictionary]) -> Array[Dictionary]:
	var stage_index: int = int(generation_context.get("stage_index", 0))
	if stage_index <= 0:
		return offer_pool

	var stage_filtered_pool: Array[Dictionary] = []
	for offer in offer_pool:
		if _reward_offer_matches_stage(offer, stage_index):
			stage_filtered_pool.append(offer.duplicate(true))
	if stage_filtered_pool.is_empty():
		return offer_pool
	return stage_filtered_pool


func _prioritize_offer_pool_for_enemy_tags(offer_pool: Array[Dictionary], present_count: int) -> Array[Dictionary]:
	if source_context != SOURCE_COMBAT_VICTORY:
		return offer_pool

	var enemy_tags: PackedStringArray = _extract_string_array(generation_context.get("enemy_tags", []))
	if enemy_tags.is_empty():
		return offer_pool

	var matched_pool: Array[Dictionary] = []
	var generic_pool: Array[Dictionary] = []
	var unmatched_pool: Array[Dictionary] = []
	for offer in offer_pool:
		var preferred_tags: PackedStringArray = _extract_string_array(offer.get("preferred_enemy_tags_any", []))
		if preferred_tags.is_empty():
			generic_pool.append(offer.duplicate(true))
			continue
		if _string_arrays_intersect(preferred_tags, enemy_tags):
			matched_pool.append(offer.duplicate(true))
		else:
			unmatched_pool.append(offer.duplicate(true))

	if matched_pool.is_empty():
		return offer_pool

	var prioritized_pool: Array[Dictionary] = []
	prioritized_pool.append_array(matched_pool)
	prioritized_pool.append_array(generic_pool)
	if prioritized_pool.size() < max(1, present_count):
		prioritized_pool.append_array(unmatched_pool)
	return prioritized_pool


func _reward_offer_matches_stage(offer: Dictionary, stage_index: int) -> bool:
	var min_stage: int = int(offer.get("stage_min", 0))
	var max_stage: int = int(offer.get("stage_max", 0))
	if min_stage > 0 and stage_index < min_stage:
		return false
	if max_stage > 0 and stage_index > max_stage:
		return false
	return true


func _extract_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry in value:
		var text: String = String(entry).strip_edges()
		if text.is_empty() or result.has(text):
			continue
		result.append(text)
	return result


func _string_arrays_intersect(left_values: PackedStringArray, right_values: PackedStringArray) -> bool:
	for left_value in left_values:
		if right_values.has(left_value):
			return true
	return false
