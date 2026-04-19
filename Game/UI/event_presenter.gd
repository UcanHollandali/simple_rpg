# Layer: UI
extends RefCounted
class_name EventPresenter

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const ItemDefinitionTooltipBuilderScript = preload("res://Game/UI/item_definition_tooltip_builder.gd")
const MapDisplayNameHelperScript = preload("res://Game/UI/map_display_name_helper.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const RunStatusPresenterScript = preload("res://Game/UI/run_status_presenter.gd")
const UiCompactCopyScript = preload("res://Game/UI/ui_compact_copy.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const DEFAULT_CARD_COUNT: int = 2
const ROADSIDE_EVENT_CHIP_TEXT: String = "ROADSIDE ENCOUNTER"

var _loader: ContentLoader = ContentLoaderScript.new()
var _item_tooltip_builder: ItemDefinitionTooltipBuilder = ItemDefinitionTooltipBuilderScript.new()


func build_chip_text(event_state: EventState = null) -> String:
	if event_state != null and String(event_state.source_context) == EventState.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER:
		return ROADSIDE_EVENT_CHIP_TEXT
	return MapDisplayNameHelperScript.build_family_display_name("event").to_upper()


func build_title_text(event_state: EventState) -> String:
	if event_state == null:
		return "Event unavailable."
	return String(event_state.title_text)


func build_context_text(event_state: EventState) -> String:
	if event_state != null and String(event_state.source_context) == EventState.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER:
		return "Roadside stop. Resolve it and move on."
	return UiCompactCopyScript.pick_one("result")


func build_summary_text(event_state: EventState) -> String:
	if event_state == null:
		return ""
	return _compact_summary_text(String(event_state.summary_text))


func build_hint_text() -> String:
	return UiCompactCopyScript.hover_for_details()


func build_choice_failure_text(event_state: EventState, error_text: String) -> String:
	var prefix: String = "Event"
	if event_state != null and String(event_state.source_context) == EventState.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER:
		prefix = "Roadside encounter"
	return "%s failed: %s" % [prefix, error_text]


func build_choice_icon_texture_path(event_state: EventState = null) -> String:
	if event_state != null and String(event_state.source_context) == EventState.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER:
		return UiAssetPathsScript.ROUTE_ICON_TEXTURE_PATH
	return UiAssetPathsScript.EVENT_ICON_TEXTURE_PATH


func build_run_status_model(run_state: RunState) -> Dictionary:
	return RunStatusPresenterScript.build_status_model(run_state, {
		"variant": RunStatusPresenterScript.VARIANT_COMPACT,
		"include_weapon": true,
	})


func build_choice_view_models(event_state: EventState, card_count: int = DEFAULT_CARD_COUNT) -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	var choices: Array[Dictionary] = []
	if event_state != null:
		choices = event_state.choices

	for index in range(card_count):
		if index < choices.size():
			var choice: Dictionary = choices[index]
			models.append({
				"visible": true,
				"badge_text": _build_badge_text(choice),
				"title_text": String(choice.get("label", choice.get("choice_id", ""))),
				"detail_text": _build_detail_text(choice),
				"button_text": _build_button_text(choice),
				"tooltip_text": _build_choice_tooltip_text(choice),
				"icon_texture_path": _build_choice_icon_texture_path_for_choice(choice, event_state),
				"button_disabled": false,
			})
		else:
			models.append({
				"visible": false,
				"badge_text": "",
				"title_text": "",
				"detail_text": "",
				"button_text": "",
				"icon_texture_path": "",
				"button_disabled": true,
			})

	return models


func _build_badge_text(choice: Dictionary) -> String:
	var effect_type: String = String(choice.get("effect_type", ""))
	var amount: int = int(choice.get("amount", 0))
	match effect_type:
		"heal":
			return "Recovery"
		"grant_gold":
			return "Windfall"
		"grant_xp":
			return "Insight"
		"modify_hunger":
			return "Relief" if amount < 0 else "Risk"
		"repair_weapon":
			return "Salvage"
		"damage_player":
			return "Risk"
		"grant_item":
			return "Find"
		_:
			return "Road"


func _build_detail_text(choice: Dictionary) -> String:
	var effect_type: String = String(choice.get("effect_type", ""))
	var outcome_text: String = _build_outcome_text(effect_type, int(choice.get("amount", 0)), choice)
	if outcome_text.is_empty():
		return String(choice.get("summary", ""))
	return outcome_text


func _build_outcome_text(effect_type: String, amount: int, choice: Dictionary = {}) -> String:
	match effect_type:
		"heal":
			return "Recover %d HP." % amount
		"grant_gold":
			return "Gain %d gold." % amount
		"grant_xp":
			return "Gain %d XP." % amount
		"modify_hunger":
			return "Restore %d hunger." % abs(amount) if amount < 0 else "Lose %d hunger." % amount
		"repair_weapon":
			return "Restore your active weapon to full durability."
		"damage_player":
			return "Take %d damage." % amount
		"grant_item":
			var inventory_family: String = String(choice.get("inventory_family", "")).strip_edges()
			var definition_id: String = String(choice.get("definition_id", "")).strip_edges()
			return _item_tooltip_builder.build_definition_summary_text(
				inventory_family,
				definition_id,
				max(1, amount)
			)
		_:
			return ""


func _build_button_text(choice: Dictionary) -> String:
	match _build_badge_text(choice):
		"Recovery":
			return "Choose Recovery"
		"Windfall":
			return "Take the Windfall"
		"Insight":
			return "Take the Insight"
		"Relief":
			return "Settle Hunger"
		"Salvage":
			return "Take the Salvage"
		"Risk":
			return "Risk the Encounter"
		"Find":
			return "Pack the Find"
		_:
			return "Choose This Encounter"


func _build_choice_tooltip_text(choice: Dictionary) -> String:
	var effect_type: String = String(choice.get("effect_type", ""))
	var amount: int = int(choice.get("amount", 0))
	match effect_type:
		"heal":
			return "Recover %d HP." % amount
		"grant_gold":
			return "Gain %d gold." % amount
		"grant_xp":
			return "Gain %d XP." % amount
		"modify_hunger":
			return "Restore %d hunger." % abs(amount) if amount < 0 else "Lose %d hunger." % amount
		"repair_weapon":
			return "Full weapon repair."
		"damage_player":
			return "Take %d damage." % amount
		"grant_item":
			var inventory_family: String = String(choice.get("inventory_family", "")).strip_edges()
			var definition_id: String = String(choice.get("definition_id", "")).strip_edges()
			return _item_tooltip_builder.build_definition_tooltip_text(
				inventory_family,
				definition_id,
				max(1, amount)
			)
		_:
			return ""


func _build_choice_icon_texture_path_for_choice(choice: Dictionary, event_state: EventState = null) -> String:
	var inventory_family: String = String(choice.get("inventory_family", "")).strip_edges()
	var effect_icon_path: String = UiAssetPathsScript.build_effect_icon_texture_path(
		String(choice.get("effect_type", "")),
		inventory_family
	)
	if not effect_icon_path.is_empty():
		return effect_icon_path
	return build_choice_icon_texture_path(event_state)


func _load_inventory_display_name(inventory_family: String, definition_id: String) -> String:
	var family_name: String = _definition_family_for_inventory_family(inventory_family)
	if family_name.is_empty() or definition_id.is_empty():
		return definition_id
	var definition: Dictionary = _loader.load_definition(family_name, definition_id)
	return String(definition.get("display", {}).get("name", definition_id))


func _definition_family_for_inventory_family(inventory_family: String) -> String:
	match inventory_family:
		InventoryStateScript.INVENTORY_FAMILY_WEAPON:
			return "Weapons"
		InventoryStateScript.INVENTORY_FAMILY_SHIELD:
			return "Shields"
		InventoryStateScript.INVENTORY_FAMILY_ARMOR:
			return "Armors"
		InventoryStateScript.INVENTORY_FAMILY_BELT:
			return "Belts"
		InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
			return "Consumables"
		InventoryStateScript.INVENTORY_FAMILY_PASSIVE:
			return "PassiveItems"
		InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
			return "ShieldAttachments"
		InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
			return "QuestItems"
		_:
			return ""


func _compact_summary_text(summary_text: String, max_length: int = 110) -> String:
	var normalized: String = String(summary_text).replace("\n", " ").strip_edges()
	while normalized.contains("  "):
		normalized = normalized.replace("  ", " ")
	if normalized.is_empty():
		return ""
	var first_sentence_end: int = normalized.find(". ")
	if first_sentence_end >= 0 and first_sentence_end + 1 <= max_length:
		return normalized.substr(0, first_sentence_end + 1)
	if normalized.length() <= max_length:
		return normalized
	return "%s..." % normalized.substr(0, max_length - 3).rstrip(" ,;:")
