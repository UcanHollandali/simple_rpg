extends RefCounted
class_name CharacterPerkState

const CONTENT_FAMILY: String = "CharacterPerks"

const LEGACY_PASSIVE_TO_PERK_ID := {
	"iron_grip_charm": "thorn_grip_training",
	"whetstone_loop": "whetstone_discipline",
	"razor_relic": "razor_instinct",
	"wolfspur_ring": "wolfspur_frenzy",
	"rushnail_loop": "rushnail_method",
	"sturdy_wraps": "sturdy_stance",
	"bulwark_reliquary": "bulwark_doctrine",
	"gate_oak_idol": "gate_oak_posture",
	"marchwarden_talisman": "marchwarden_drill",
	"tempered_binding": "tempered_maintenance",
	"scavenger_straps": "scavenger_stride",
	"lean_pack_token": "lean_kit_training",
	"packrat_clasp": "packrat_routine",
	"scrap_ledger_clasp": "ledger_method",
	"salvager_rivet": "salvager_eye",
}

var owned_perk_ids: Array[String] = []


func reset_for_new_run() -> void:
	owned_perk_ids = []


func has_perk(definition_id: String) -> bool:
	var normalized_definition_id: String = definition_id.strip_edges()
	if normalized_definition_id.is_empty():
		return false
	return owned_perk_ids.has(normalized_definition_id)


func learn_perk(definition_id: String) -> Dictionary:
	var normalized_definition_id: String = definition_id.strip_edges()
	if normalized_definition_id.is_empty():
		return {
			"ok": false,
			"error": "invalid_perk_definition_id",
		}
	if has_perk(normalized_definition_id):
		return {
			"ok": false,
			"error": "perk_already_owned",
			"definition_id": normalized_definition_id,
		}
	owned_perk_ids.append(normalized_definition_id)
	return {
		"ok": true,
		"definition_id": normalized_definition_id,
	}


func get_owned_perk_ids() -> Array[String]:
	return owned_perk_ids.duplicate()


func to_save_dict() -> Dictionary:
	return {
		"owned_perk_ids": owned_perk_ids.duplicate(),
	}


func load_from_save_dict(save_data: Dictionary) -> void:
	owned_perk_ids = _extract_unique_string_array(save_data.get("owned_perk_ids", []))


func load_from_legacy_passive_slots(passive_slot_list: Array[Dictionary]) -> void:
	owned_perk_ids = []
	for slot in passive_slot_list:
		var definition_id: String = String(slot.get("definition_id", "")).strip_edges()
		if definition_id.is_empty():
			continue
		var perk_definition_id: String = resolve_legacy_perk_definition_id(definition_id)
		if perk_definition_id.is_empty() or owned_perk_ids.has(perk_definition_id):
			continue
		owned_perk_ids.append(perk_definition_id)


func resolve_legacy_perk_definition_id(definition_id: String) -> String:
	return String(LEGACY_PASSIVE_TO_PERK_ID.get(definition_id.strip_edges(), ""))


func _extract_unique_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result

	for entry in value:
		var normalized_entry: String = String(entry).strip_edges()
		if normalized_entry.is_empty() or result.has(normalized_entry):
			continue
		result.append(normalized_entry)
	return result
