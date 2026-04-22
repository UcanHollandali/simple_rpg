# Layer: RuntimeState
extends RefCounted
class_name EventState

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")

const EVENT_TEMPLATE_FAMILY: String = "EventTemplates"
const NO_SOURCE_NODE_ID: int = -1
const REQUIRED_CHOICE_COUNT: int = 2
const SOURCE_CONTEXT_NODE_EVENT: String = "node_event"
const SOURCE_CONTEXT_ROADSIDE_ENCOUNTER: String = "roadside_encounter"
const SOURCE_CONTEXT_DEFAULT: String = SOURCE_CONTEXT_NODE_EVENT
const EVENT_TEMPLATE_TAG_EVENT: String = "event"
const EVENT_TEMPLATE_TAG_ROADSIDE: String = "roadside"
const DEFAULT_SELECTION_SEED: int = 1
const TRIGGER_STAT_HUNGER: String = "hunger"
const TRIGGER_STAT_HP_PERCENT: String = "hp_percent"
const TRIGGER_STAT_GOLD: String = "gold"

var template_definition_id: String = ""
var source_node_id: int = NO_SOURCE_NODE_ID
var source_context: String = SOURCE_CONTEXT_DEFAULT
var title_text: String = ""
var summary_text: String = ""
var choices: Array[Dictionary] = []


func setup_for_node(
	node_id: int,
	stage_index: int = 1,
	new_source_context: String = SOURCE_CONTEXT_DEFAULT,
	selection_seed: int = DEFAULT_SELECTION_SEED,
	trigger_context: Dictionary = {}
) -> void:
	source_node_id = node_id
	source_context = String(new_source_context).strip_edges()
	if source_context.is_empty():
		source_context = SOURCE_CONTEXT_DEFAULT
	var loader: ContentLoader = ContentLoaderScript.new()
	template_definition_id = _resolve_template_definition_id(
		loader,
		stage_index,
		max(DEFAULT_SELECTION_SEED, selection_seed),
		trigger_context
	)
	if template_definition_id.is_empty():
		title_text = "Roadside Encounter" if source_context == SOURCE_CONTEXT_ROADSIDE_ENCOUNTER else "Trail Event"
		summary_text = ""
		choices = []
		return

	var event_definition: Dictionary = loader.load_definition(EVENT_TEMPLATE_FAMILY, template_definition_id)
	var display: Dictionary = event_definition.get("display", {})
	var rules: Dictionary = event_definition.get("rules", {})
	title_text = String(display.get("name", template_definition_id))
	summary_text = String(display.get("short_description", ""))
	choices = _extract_choice_array(rules.get("choices", []))


func get_choice_by_id(choice_id: String) -> Dictionary:
	for choice in choices:
		if String(choice.get("choice_id", "")) == choice_id:
			return choice.duplicate(true)
	return {}


func build_filtered_template_ids(loader: ContentLoader, trigger_context: Dictionary = {}) -> Array[String]:
	return _filter_template_ids_for_source_context(
		loader.list_definition_ids(EVENT_TEMPLATE_FAMILY),
		loader,
		trigger_context
	)


func to_save_dict() -> Dictionary:
	return {
		"template_definition_id": template_definition_id,
		"source_node_id": source_node_id,
		"source_context": source_context,
		"title_text": title_text,
		"summary_text": summary_text,
		"choices": choices.duplicate(true),
	}


func load_from_save_dict(save_data: Dictionary) -> void:
	template_definition_id = String(save_data.get("template_definition_id", ""))
	source_node_id = int(save_data.get("source_node_id", NO_SOURCE_NODE_ID))
	source_context = String(save_data.get("source_context", SOURCE_CONTEXT_DEFAULT)).strip_edges()
	if source_context.is_empty():
		source_context = SOURCE_CONTEXT_DEFAULT
	title_text = String(save_data.get("title_text", ""))
	summary_text = String(save_data.get("summary_text", ""))
	choices = _extract_choice_array(save_data.get("choices", []))


func _resolve_template_definition_id(
	loader: ContentLoader,
	stage_index: int,
	selection_seed: int = DEFAULT_SELECTION_SEED,
	trigger_context: Dictionary = {}
) -> String:
	var template_ids: Array[String] = _filter_template_ids_for_source_context(
		loader.list_definition_ids(EVENT_TEMPLATE_FAMILY),
		loader,
		trigger_context
	)
	if template_ids.is_empty():
		template_ids = loader.list_definition_ids(EVENT_TEMPLATE_FAMILY)
	if template_ids.is_empty():
		return ""
	var stage_offset: int = max(0, stage_index - 1)
	if selection_seed <= DEFAULT_SELECTION_SEED:
		return String(template_ids[stage_offset % template_ids.size()])
	var selection_index: int = posmod(stage_offset + _build_selection_seed_offset(selection_seed), template_ids.size())
	return String(template_ids[selection_index])


func _filter_template_ids_for_source_context(
	template_ids: Array[String],
	loader: ContentLoader,
	trigger_context: Dictionary = {}
) -> Array[String]:
	var filtered_ids: Array[String] = []
	for template_definition_id in template_ids:
		var event_definition: Dictionary = loader.load_definition(EVENT_TEMPLATE_FAMILY, template_definition_id)
		var tags: Array = event_definition.get("tags", [])
		var has_roadside_tag: bool = tags.has(EVENT_TEMPLATE_TAG_ROADSIDE)
		if source_context == SOURCE_CONTEXT_ROADSIDE_ENCOUNTER:
			if has_roadside_tag and _trigger_condition_matches(event_definition, trigger_context):
				filtered_ids.append(template_definition_id)
			continue
		if tags.has(EVENT_TEMPLATE_TAG_EVENT) and not has_roadside_tag:
			filtered_ids.append(template_definition_id)
	return filtered_ids


func _extract_choice_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result

	for entry in value:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		result.append((entry as Dictionary).duplicate(true))

	if result.size() > REQUIRED_CHOICE_COUNT:
		result.resize(REQUIRED_CHOICE_COUNT)
	return result


func _build_selection_seed_offset(selection_seed: int) -> int:
	var pool_bias_source: String = "%d|%d|%s" % [selection_seed, source_node_id, source_context]
	return abs(_hash_seed_string(pool_bias_source))


func _trigger_condition_matches(event_definition: Dictionary, trigger_context: Dictionary) -> bool:
	var rules: Dictionary = event_definition.get("rules", {})
	return _condition_matches(rules.get("trigger_condition", null), trigger_context, {})


func _condition_matches(condition_value: Variant, source_state: Dictionary, target_state: Dictionary) -> bool:
	if condition_value == null:
		return true
	if typeof(condition_value) != TYPE_DICTIONARY:
		return false

	var condition: Dictionary = condition_value
	var op: String = String(condition.get("op", "always"))
	if op == "always":
		return true

	var stat_name: String = String(condition.get("stat", ""))
	var comparison_value: Variant = condition.get("value", null)
	var state_value: Variant = _resolve_condition_stat(stat_name, source_state, target_state)
	if state_value == null:
		return false

	match op:
		"eq":
			return state_value == comparison_value
		"neq":
			return state_value != comparison_value
		"gt":
			return float(state_value) > float(comparison_value)
		"gte":
			return float(state_value) >= float(comparison_value)
		"lt":
			return float(state_value) < float(comparison_value)
		"lte":
			return float(state_value) <= float(comparison_value)
		"has_tag":
			return _state_has_tag(state_value, comparison_value)
		"not_has_tag":
			return not _state_has_tag(state_value, comparison_value)
		_:
			return false


func _resolve_condition_stat(stat_name: String, source_state: Dictionary, target_state: Dictionary) -> Variant:
	if source_state.has(stat_name):
		return source_state.get(stat_name)
	if target_state.has(stat_name):
		return target_state.get(stat_name)
	return null


func _state_has_tag(state_value: Variant, comparison_value: Variant) -> bool:
	if typeof(state_value) != TYPE_ARRAY:
		return false
	return (state_value as Array).has(comparison_value)


func _hash_seed_string(value: String) -> int:
	var accumulator: int = 216613626
	var bytes: PackedByteArray = value.to_utf8_buffer()
	for byte in bytes:
		accumulator = abs(int((accumulator ^ int(byte)) * 16777619))
	if accumulator == 0:
		return DEFAULT_SELECTION_SEED
	return accumulator
