# Layer: UI
extends RefCounted
class_name EventPresenter

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const ItemDefinitionTooltipBuilderScript = preload("res://Game/UI/item_definition_tooltip_builder.gd")
const MapDisplayNameHelperScript = preload("res://Game/UI/map_display_name_helper.gd")
const RunStatusPresenterScript = preload("res://Game/UI/run_status_presenter.gd")
const UiCompactCopyScript = preload("res://Game/UI/ui_compact_copy.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const DEFAULT_CARD_COUNT: int = 2
const ROADSIDE_EVENT_CHIP_TEXT: String = "ROADSIDE ENCOUNTER"

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
	var trimmed_error: String = error_text.strip_edges()
	var is_roadside: bool = event_state != null and String(event_state.source_context) == EventState.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER
	match trimmed_error:
		"missing_choice", "unknown_event_option":
			return "That roadside choice is no longer available." if is_roadside else "That choice is no longer available."
		"missing_event_state":
			return "Roadside encounter unavailable." if is_roadside else "Event unavailable."
		_:
			var prefix: String = "Event"
			if is_roadside:
				prefix = "Roadside encounter"
			return "%s failed: %s" % [prefix, trimmed_error if not trimmed_error.is_empty() else "unknown"]


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
			var is_available: bool = bool(choice.get("available", true))
			models.append({
				"visible": true,
				"badge_text": _build_badge_text(choice),
				"title_text": String(choice.get("label", choice.get("choice_id", ""))),
				"summary_text": _build_choice_summary_text(choice),
				"detail_text": _build_detail_text(choice),
				"availability_text": _build_availability_text(choice),
				"button_text": _build_button_text(choice, is_available),
				"tooltip_text": _build_choice_tooltip_text(choice, is_available),
				"icon_texture_path": _build_choice_icon_texture_path_for_choice(choice, event_state),
				"button_disabled": not is_available,
			})
		else:
			models.append({
				"visible": false,
				"badge_text": "",
				"title_text": "",
				"summary_text": "",
				"detail_text": "",
				"availability_text": "",
				"button_text": "",
				"icon_texture_path": "",
				"button_disabled": true,
			})

	return models


func _build_choice_summary_text(choice: Dictionary) -> String:
	var summary_text: String = _compact_summary_text(String(choice.get("summary", "")), 88)
	if summary_text.is_empty():
		return ""
	var detail_text: String = _build_outcome_text(
		String(choice.get("effect_type", "")),
		int(choice.get("amount", 0)),
		choice
	)
	if detail_text.is_empty():
		return ""
	return "" if summary_text == detail_text else summary_text


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
	var lead_text: String = _build_cost_text(int(choice.get("cost_gold", 0)))
	if outcome_text.is_empty():
		return _join_compact_parts([lead_text, _compact_summary_text(String(choice.get("summary", "")), 88)])
	return _join_compact_parts([lead_text, outcome_text])


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


func _build_button_text(choice: Dictionary, is_available: bool = true) -> String:
	if not is_available:
		return "Unavailable"
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


func _build_choice_tooltip_text(choice: Dictionary, is_available: bool = true) -> String:
	var effect_type: String = String(choice.get("effect_type", ""))
	var amount: int = int(choice.get("amount", 0))
	var lead_text: String = _build_cost_text(int(choice.get("cost_gold", 0)))
	var tooltip_text: String = ""
	match effect_type:
		"heal":
			tooltip_text = _join_compact_parts([lead_text, "Recover %d HP." % amount])
		"grant_gold":
			tooltip_text = _join_compact_parts([lead_text, "Gain %d gold." % amount])
		"grant_xp":
			tooltip_text = _join_compact_parts([lead_text, "Gain %d XP." % amount])
		"modify_hunger":
			tooltip_text = _join_compact_parts([
				lead_text,
				"Restore %d hunger." % abs(amount) if amount < 0 else "Lose %d hunger." % amount,
			])
		"repair_weapon":
			tooltip_text = _join_compact_parts([lead_text, "Full weapon repair."])
		"damage_player":
			tooltip_text = _join_compact_parts([lead_text, "Take %d damage." % amount])
		"grant_item":
			var inventory_family: String = String(choice.get("inventory_family", "")).strip_edges()
			var definition_id: String = String(choice.get("definition_id", "")).strip_edges()
			tooltip_text = _item_tooltip_builder.build_definition_tooltip_text(
				inventory_family,
				definition_id,
				max(1, amount),
				lead_text
			)
		_:
			tooltip_text = lead_text
	if not is_available:
		tooltip_text = _join_compact_parts([tooltip_text, _build_unavailable_text(String(choice.get("unavailable_reason", "")))])
	return tooltip_text


func build_choice_pending_feedback_text(choice: Dictionary, result: Dictionary) -> String:
	if String(result.get("error", "")) != "inventory_choice_required":
		return ""
	var inventory_family: String = String(choice.get("inventory_family", "")).strip_edges()
	var definition_id: String = String(choice.get("definition_id", "")).strip_edges()
	var item_name: String = _item_tooltip_builder.build_definition_display_name(inventory_family, definition_id)
	if not item_name.is_empty():
		return "Backpack full. Replace a slot or leave %s." % item_name
	return "Backpack full. Replace a slot or leave the item."


func _build_choice_icon_texture_path_for_choice(choice: Dictionary, event_state: EventState = null) -> String:
	var inventory_family: String = String(choice.get("inventory_family", "")).strip_edges()
	var effect_icon_path: String = UiAssetPathsScript.build_effect_icon_texture_path(
		String(choice.get("effect_type", "")),
		inventory_family
	)
	if not effect_icon_path.is_empty():
		return effect_icon_path
	return build_choice_icon_texture_path(event_state)


func _build_availability_text(choice: Dictionary) -> String:
	if bool(choice.get("available", true)):
		return ""
	return _build_unavailable_text(String(choice.get("unavailable_reason", "")))


func _build_cost_text(cost_gold: int) -> String:
	return "Cost %dg" % cost_gold if cost_gold > 0 else ""


func _build_unavailable_text(unavailable_reason: String) -> String:
	var trimmed_reason: String = unavailable_reason.strip_edges()
	if not trimmed_reason.is_empty():
		return trimmed_reason
	return "This choice is unavailable."


func _join_compact_parts(parts: Array) -> String:
	var filtered: PackedStringArray = []
	for part_value in parts:
		var part: String = String(part_value).strip_edges()
		if not part.is_empty():
			filtered.append(part)
	return " | ".join(filtered)


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
