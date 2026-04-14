# Layer: Infrastructure
extends RefCounted
class_name ContentLoader

const FALLBACK_AUTHORING_ORDER: int = 2147483647


func load_definition(family: String, stable_id: String) -> Dictionary:
	var definition_path: String = "res://ContentDefinitions/%s/%s.json" % [family, stable_id]
	if not FileAccess.file_exists(definition_path):
		push_error("Content definition not found: %s" % definition_path)
		return {}

	var file: FileAccess = FileAccess.open(definition_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open content definition: %s" % definition_path)
		return {}

	var raw_text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Content definition did not parse into a Dictionary: %s" % definition_path)
		return {}

	var definition: Dictionary = parsed
	return definition


func list_definition_ids(family: String) -> Array[String]:
	var result: Array[String] = []
	var family_path: String = "res://ContentDefinitions/%s" % family
	var directory: DirAccess = DirAccess.open(family_path)
	if directory == null:
		push_error("Content family directory not found: %s" % family_path)
		return result

	directory.list_dir_begin()
	while true:
		var entry_name: String = directory.get_next()
		if entry_name.is_empty():
			break
		if directory.current_is_dir():
			continue
		if not entry_name.ends_with(".json"):
			continue
		if entry_name.begins_with("."):
			continue
		result.append(entry_name.trim_suffix(".json"))
	directory.list_dir_end()

	result.sort()
	return result


func list_definition_ids_by_authoring_order(family: String) -> Array[String]:
	var ordered_entries: Array[Dictionary] = []
	for definition_id in list_definition_ids(family):
		var definition: Dictionary = load_definition(family, definition_id)
		if definition.is_empty():
			continue
		ordered_entries.append({
			"definition_id": definition_id,
			"authoring_order": _extract_authoring_order(definition, family, definition_id),
		})

	ordered_entries.sort_custom(Callable(self, "_sort_definition_order_entries"))

	var ordered_ids: Array[String] = []
	for entry in ordered_entries:
		var ordered_definition_id: String = String(entry.get("definition_id", ""))
		if ordered_definition_id.is_empty():
			continue
		ordered_ids.append(ordered_definition_id)
	return ordered_ids


func _extract_authoring_order(definition: Dictionary, family: String, definition_id: String) -> int:
	var authoring_order: Variant = definition.get("authoring_order", null)
	if typeof(authoring_order) == TYPE_INT:
		return int(authoring_order)

	if typeof(authoring_order) == TYPE_FLOAT and is_equal_approx(authoring_order, round(authoring_order)):
		return int(authoring_order)

	if typeof(authoring_order) == TYPE_STRING and String(authoring_order).is_valid_int():
		return String(authoring_order).to_int()

	if typeof(authoring_order) != TYPE_INT:
		push_error("Content definition missing integer authoring_order: %s/%s" % [family, definition_id])
		return FALLBACK_AUTHORING_ORDER
	return int(authoring_order)


func _sort_definition_order_entries(left: Dictionary, right: Dictionary) -> bool:
	var left_order: int = int(left.get("authoring_order", FALLBACK_AUTHORING_ORDER))
	var right_order: int = int(right.get("authoring_order", FALLBACK_AUTHORING_ORDER))
	if left_order == right_order:
		return String(left.get("definition_id", "")) < String(right.get("definition_id", ""))
	return left_order < right_order
