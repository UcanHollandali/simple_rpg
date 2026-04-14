# Layer: Application
extends RefCounted
class_name LevelUpOfferWindowPolicy

const DEFAULT_PRESENT_COUNT: int = 3


func build_offer_window(loader: ContentLoader, from_level: int, present_count: int = DEFAULT_PRESENT_COUNT) -> Array[Dictionary]:
	return select_offer_window(build_authored_offers(loader), from_level, present_count)


func build_authored_offers(loader: ContentLoader) -> Array[Dictionary]:
	var authored_offers: Array[Dictionary] = []
	if loader == null:
		return authored_offers

	for definition_id in loader.list_definition_ids_by_authoring_order("PassiveItems"):
		var passive_definition: Dictionary = loader.load_definition("PassiveItems", definition_id)
		if passive_definition.is_empty():
			continue
		var display: Dictionary = passive_definition.get("display", {})
		authored_offers.append({
			"offer_id": String(passive_definition.get("definition_id", definition_id)),
			"label": String(display.get("name", definition_id)),
			"summary": String(display.get("short_description", "")),
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
