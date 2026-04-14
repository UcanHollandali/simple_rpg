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

var template_definition_id: String = ""
var source_node_id: int = NO_SOURCE_NODE_ID
var source_context: String = SOURCE_CONTEXT_DEFAULT
var title_text: String = ""
var summary_text: String = ""
var choices: Array[Dictionary] = []


func setup_for_node(node_id: int, stage_index: int = 1, new_source_context: String = SOURCE_CONTEXT_DEFAULT) -> void:
	source_node_id = node_id
	source_context = String(new_source_context).strip_edges()
	if source_context.is_empty():
		source_context = SOURCE_CONTEXT_DEFAULT
	var loader: ContentLoader = ContentLoaderScript.new()
	template_definition_id = _resolve_template_definition_id(loader, stage_index)
	if template_definition_id.is_empty():
		title_text = "Roadside Encounter"
		summary_text = ""
		source_context = SOURCE_CONTEXT_ROADSIDE_ENCOUNTER
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


func _resolve_template_definition_id(loader: ContentLoader, stage_index: int) -> String:
	var template_ids: Array[String] = loader.list_definition_ids(EVENT_TEMPLATE_FAMILY)
	if template_ids.is_empty():
		return ""
	var stage_offset: int = max(0, stage_index - 1)
	return String(template_ids[stage_offset % template_ids.size()])


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
