# Layer: UI
extends RefCounted
class_name SupportInteractionPresenter

const ItemDefinitionTooltipBuilderScript = preload("res://Game/UI/item_definition_tooltip_builder.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const RunStatusPresenterScript = preload("res://Game/UI/run_status_presenter.gd")
const UiCompactCopyScript = preload("res://Game/UI/ui_compact_copy.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const DEFAULT_BUTTON_COUNT: int = 3

var _item_tooltip_builder: ItemDefinitionTooltipBuilder = ItemDefinitionTooltipBuilderScript.new()


func build_chip_text(support_state: RefCounted) -> String:
	if support_state == null:
		return "STOP"
	match String(support_state.support_type):
		"rest":
			return "SAFE REST"
		"merchant":
			return "MERCHANT"
		"blacksmith":
			if _is_blacksmith_target_selection_active(support_state):
				return "FORGE TARGET"
			return "FORGE SERVICE"
		"hamlet":
			return "HAMLET"
		_:
			return "SUPPORT"


func build_title_text(support_state: RefCounted) -> String:
	if support_state == null:
		return "Support unavailable."
	var title_text: String = String(support_state.title_text).strip_edges()
	if not title_text.is_empty():
		return title_text
	return "Support"


func build_context_text(support_state: RefCounted) -> String:
	if support_state == null:
		return ""

	match String(support_state.support_type):
		"rest":
			return UiCompactCopyScript.pick_one("recovery")
		"merchant":
			return "Buy what helps."
		"blacksmith":
			if _is_blacksmith_target_selection_active(support_state):
				return "Pick a target."
			return UiCompactCopyScript.pick_one("service")
		"hamlet":
			var mission_status: String = String(support_state.get("mission_status"))
			match mission_status:
				"offered":
					return UiCompactCopyScript.pick_one("request")
				"accepted":
					return "Finish the mark."
				"completed":
					return UiCompactCopyScript.pick_one("reward")
				_:
					return "Nothing left here."
		_:
			return ""


func build_summary_text(support_state: RefCounted) -> String:
	if support_state == null:
		return ""
	return _compact_summary_text(String(support_state.summary_text))


func build_hint_text(support_state: RefCounted) -> String:
	if support_state == null:
		return ""

	match String(support_state.support_type):
		"rest":
			return "One use. +10 HP, -3 Hunger."
		"merchant":
			return "Hover for stats."
		"blacksmith":
			if _is_blacksmith_target_selection_active(support_state):
				return "Pick 1 target."
			return "One service."
		"hamlet":
			var mission_status: String = String(support_state.get("mission_status"))
			match mission_status:
				"offered":
					return "Accept it. Clear it. Return."
				"accepted":
					return "Back after the marked fight."
				"completed":
					return "One reward."
				_:
					return ""
		_:
			return ""


func build_action_failure_text(error_text: String) -> String:
	var trimmed_error: String = error_text.strip_edges()
	match trimmed_error:
		"support_action_unavailable", "unknown_support_action":
			return "That service is no longer available."
		"insufficient_gold":
			return "Not enough gold for that service."
		"missing_support_state":
			return "Support unavailable."
		_:
			return "Action failed: %s" % (trimmed_error if not trimmed_error.is_empty() else "unknown")


func build_run_status_model(run_state: RunState) -> Dictionary:
	return RunStatusPresenterScript.build_status_model(run_state, {
		"variant": RunStatusPresenterScript.VARIANT_COMPACT,
		"include_weapon": false,
	})


func build_action_view_models(support_state: RefCounted, button_count: int = DEFAULT_BUTTON_COUNT) -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	var offers: Array[Dictionary] = []
	if support_state != null:
		offers = support_state.offers

	for index in range(button_count):
		if support_state != null and index < offers.size():
			var offer: Dictionary = offers[index]
			var support_type: String = String(support_state.support_type)
			var is_available: bool = bool(offer.get("available", true))
			models.append({
				"text": _build_offer_text(
					String(offer.get("label", offer.get("offer_id", ""))),
					_build_action_detail_text(support_state, offer),
					support_type,
					is_available,
					String(offer.get("unavailable_reason", ""))
				),
				"title_text": _build_action_title_text(offer),
				"detail_text": _build_action_detail_text(support_state, offer),
				"icon_texture_path": _build_action_icon_texture_path(support_state, offer),
				"tooltip_text": _build_offer_tooltip_text(support_state, offer),
				"visible": true,
				"disabled": not is_available,
			})
		else:
			models.append({
				"text": "",
				"title_text": "",
				"detail_text": "",
				"icon_texture_path": "",
				"tooltip_text": "",
				"visible": false,
				"disabled": true,
			})

	return models


func build_leave_button_text(support_state: RefCounted) -> String:
	if support_state != null and String(support_state.support_type) == "blacksmith" and _is_blacksmith_target_selection_active(support_state):
		return "Back to Services"
	return "Back to the Road"


func _is_blacksmith_target_selection_active(support_state: RefCounted) -> bool:
	var typed_support_state: SupportInteractionState = support_state as SupportInteractionState
	if typed_support_state == null:
		return false
	return typed_support_state.is_blacksmith_target_selection_active()


func _build_offer_text(label_text: String, detail_text: String, support_type: String, is_available: bool, unavailable_reason: String = "") -> String:
	var title_text: String = label_text
	var detail_copy: String = detail_text
	if is_available:
		return _join_multiline_parts([title_text, detail_copy])
	if unavailable_reason == "no_target":
		return _join_multiline_parts([title_text, detail_copy])
	if unavailable_reason in ["contract_active", "contract_claimed"]:
		return _join_multiline_parts([title_text, detail_copy])
	match support_type:
		"merchant":
			return _join_multiline_parts([title_text, "Sold out"])
		_:
			return _join_multiline_parts([title_text, "Spent"])


func _build_action_title_text(offer: Dictionary) -> String:
	return String(offer.get("label", offer.get("offer_id", ""))).strip_edges()


func _build_action_detail_text(support_state: RefCounted, offer: Dictionary) -> String:
	var effect_type: String = String(offer.get("effect_type", "")).strip_edges()
	var amount: int = int(offer.get("amount", 0))
	var cost_gold: int = int(offer.get("cost_gold", 0))
	match effect_type:
		"rest":
			return "+%d HP | -%d Hunger" % [
				max(0, int(offer.get("heal_amount", 0))),
				abs(int(offer.get("hunger_delta", 0))),
			]
		"repair_weapon":
			return _join_tooltip_parts([_build_cost_text(cost_gold), "Full repair"])
		"open_blacksmith_weapon_targets":
			return _join_tooltip_parts([_build_cost_text(cost_gold), "Pick weapon", "+1 ATK"])
		"open_blacksmith_armor_targets":
			return _join_tooltip_parts([_build_cost_text(cost_gold), "Pick armor", "+1 DEF"])
		"upgrade_weapon":
			return _join_tooltip_parts([_build_cost_text(cost_gold), "+1 ATK"])
		"upgrade_armor":
			return _join_tooltip_parts([_build_cost_text(cost_gold), "+1 DEF"])
		"cycle_blacksmith_page":
			return "See more services."
		"accept_side_mission":
			return "Take contract."
		"side_mission_info":
			return _compact_summary_text(String(support_state.summary_text if support_state != null else ""))
		"grant_gold":
			return "Gain %d gold." % amount
		"buy_consumable", "buy_weapon", "buy_shield", "buy_armor", "buy_belt", "buy_passive_item", "grant_item", "claim_side_mission_reward":
			var inventory_family: String = _resolve_inventory_family_for_offer(offer)
			var definition_id: String = String(offer.get("definition_id", "")).strip_edges()
			return _join_tooltip_parts([
				_build_cost_text(cost_gold) if effect_type.begins_with("buy_") else "",
				_item_tooltip_builder.build_definition_summary_text(
					inventory_family,
					definition_id,
					max(1, amount)
				),
			])
		_:
			return ""


func _build_action_icon_texture_path(support_state: RefCounted, offer: Dictionary) -> String:
	var inventory_family: String = _resolve_inventory_family_for_offer(offer)
	var effect_icon: String = UiAssetPathsScript.build_effect_icon_texture_path(
		String(offer.get("effect_type", "")),
		inventory_family,
		String(support_state.support_type if support_state != null else "")
	)
	if not effect_icon.is_empty():
		return effect_icon
	return UiAssetPathsScript.build_support_type_icon_texture_path(String(support_state.support_type if support_state != null else ""))


func _build_offer_tooltip_text(support_state: RefCounted, offer: Dictionary) -> String:
	var effect_type: String = String(offer.get("effect_type", "")).strip_edges()
	var amount: int = int(offer.get("amount", 0))
	var cost_gold: int = int(offer.get("cost_gold", 0))
	var tooltip_text: String = ""
	match effect_type:
		"rest":
			tooltip_text = "+%d HP | -%d Hunger" % [
				max(0, int(offer.get("heal_amount", 0))),
				abs(int(offer.get("hunger_delta", 0))),
			]
		"repair_weapon":
			tooltip_text = _join_tooltip_parts([
				_build_cost_text(cost_gold),
				"Full weapon repair",
			])
		"open_blacksmith_weapon_targets":
			tooltip_text = _join_tooltip_parts([
				_build_cost_text(cost_gold),
				"+1 ATK",
			])
		"open_blacksmith_armor_targets":
			tooltip_text = _join_tooltip_parts([
				_build_cost_text(cost_gold),
				"+1 DEF",
			])
		"upgrade_weapon":
			tooltip_text = _item_tooltip_builder.build_definition_tooltip_text(
				InventoryStateScript.INVENTORY_FAMILY_WEAPON,
				String(offer.get("definition_id", "")),
				1,
				_join_tooltip_parts([
					_build_cost_text(cost_gold),
					"+1 ATK",
				])
			)
		"upgrade_armor":
			tooltip_text = _item_tooltip_builder.build_definition_tooltip_text(
				InventoryStateScript.INVENTORY_FAMILY_ARMOR,
				String(offer.get("definition_id", "")),
				1,
				_join_tooltip_parts([
					_build_cost_text(cost_gold),
					"+1 DEF",
				])
			)
		"cycle_blacksmith_page":
			tooltip_text = "Next forge page."
		"accept_side_mission":
			tooltip_text = "Accept request."
		"side_mission_info":
			tooltip_text = _compact_summary_text(String(support_state.summary_text if support_state != null else ""))
		"grant_gold":
			tooltip_text = "Gain %d gold." % amount
		"buy_consumable", "buy_weapon", "buy_shield", "buy_armor", "buy_belt", "buy_passive_item", "grant_item", "claim_side_mission_reward":
			var inventory_family: String = _resolve_inventory_family_for_offer(offer)
			var definition_id: String = String(offer.get("definition_id", "")).strip_edges()
			var lead_parts: Array[String] = []
			if effect_type.begins_with("buy_"):
				lead_parts.append(_build_cost_text(cost_gold))
			tooltip_text = _item_tooltip_builder.build_definition_tooltip_text(
				inventory_family,
				definition_id,
				max(1, amount),
				_join_tooltip_parts(lead_parts)
			)
		_:
			tooltip_text = String(offer.get("label", offer.get("offer_id", "")))

	if not bool(offer.get("available", true)):
		var unavailable_text: String = _build_unavailable_tooltip_text(String(offer.get("unavailable_reason", "")))
		tooltip_text = _join_tooltip_parts([tooltip_text, unavailable_text])
	return tooltip_text


func _resolve_inventory_family_for_offer(offer: Dictionary) -> String:
	var effect_type: String = String(offer.get("effect_type", "")).strip_edges()
	match effect_type:
		"buy_consumable":
			return InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE
		"buy_weapon", "upgrade_weapon":
			return InventoryStateScript.INVENTORY_FAMILY_WEAPON
		"buy_shield":
			return InventoryStateScript.INVENTORY_FAMILY_SHIELD
		"buy_armor", "upgrade_armor":
			return InventoryStateScript.INVENTORY_FAMILY_ARMOR
		"buy_belt":
			return InventoryStateScript.INVENTORY_FAMILY_BELT
		"buy_passive_item":
			return InventoryStateScript.INVENTORY_FAMILY_PASSIVE
		"grant_item", "claim_side_mission_reward":
			return String(offer.get("inventory_family", "")).strip_edges()
		_:
			return ""


func _build_cost_text(cost_gold: int) -> String:
	return "Cost %dg" % cost_gold if cost_gold > 0 else ""


func _build_unavailable_tooltip_text(unavailable_reason: String) -> String:
	match unavailable_reason:
		"no_target":
			return "No valid target."
		"contract_active":
			return "Request already active."
		"contract_claimed":
			return "Already settled."
		_:
			return "Unavailable."


func _join_tooltip_parts(parts: Array) -> String:
	var filtered: PackedStringArray = []
	for part_value in parts:
		var part: String = String(part_value).strip_edges()
		if not part.is_empty():
			filtered.append(part)
	return " ".join(filtered)


func _join_multiline_parts(parts: Array) -> String:
	var filtered: PackedStringArray = []
	for part_value in parts:
		var part: String = String(part_value).strip_edges()
		if not part.is_empty():
			filtered.append(part)
	return "\n".join(filtered)


func _compact_summary_text(summary_text: String, max_length: int = 100) -> String:
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
