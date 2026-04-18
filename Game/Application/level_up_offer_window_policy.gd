# Layer: Application
extends RefCounted
class_name LevelUpOfferWindowPolicy

const DEFAULT_PRESENT_COUNT: int = 3
const CONTENT_FAMILY: String = "CharacterPerks"
const PERK_FAMILY_LABELS := {
	"offense": "Offense",
	"defense": "Defense",
	"survival": "Survival",
	"economy_route": "Route",
}


func build_offer_window(
	loader: ContentLoader,
	from_level: int,
	owned_perk_ids: Array[String] = [],
	present_count: int = DEFAULT_PRESENT_COUNT
) -> Array[Dictionary]:
	return select_offer_window(build_authored_offers(loader, owned_perk_ids), from_level, present_count)


func build_authored_offers(loader: ContentLoader, owned_perk_ids: Array[String] = []) -> Array[Dictionary]:
	var authored_offers: Array[Dictionary] = []
	if loader == null:
		return authored_offers

	var owned_lookup: Dictionary = {}
	for owned_perk_id in owned_perk_ids:
		var normalized_owned_perk_id: String = String(owned_perk_id).strip_edges()
		if normalized_owned_perk_id.is_empty():
			continue
		owned_lookup[normalized_owned_perk_id] = true

	for definition_id in loader.list_definition_ids_by_authoring_order(CONTENT_FAMILY):
		if owned_lookup.has(definition_id):
			continue
		var perk_definition: Dictionary = loader.load_definition(CONTENT_FAMILY, definition_id)
		if perk_definition.is_empty():
			continue
		var display: Dictionary = perk_definition.get("display", {})
		var rules: Dictionary = perk_definition.get("rules", {})
		var perk_family: String = String(rules.get("perk_family", "")).strip_edges()
		authored_offers.append({
			"offer_id": String(perk_definition.get("definition_id", definition_id)),
			"label": String(display.get("name", definition_id)),
			"summary": String(display.get("short_description", "")),
			"perk_family": perk_family,
			"perk_family_label": _resolve_perk_family_label(perk_family),
		})
	return authored_offers


func select_offer_window(authored_offers: Array[Dictionary], from_level: int, present_count: int = DEFAULT_PRESENT_COUNT) -> Array[Dictionary]:
	if present_count <= 0:
		return []
	if authored_offers.size() <= present_count:
		return authored_offers.duplicate(true)

	var start_index: int = posmod(max(1, from_level) - 1, authored_offers.size())
	var window: Array[Dictionary] = []
	for offset in range(present_count):
		var offer_index: int = posmod(start_index + offset, authored_offers.size())
		window.append(authored_offers[offer_index].duplicate(true))
	return window


func _resolve_perk_family_label(perk_family: String) -> String:
	return String(PERK_FAMILY_LABELS.get(perk_family, "Perk"))
