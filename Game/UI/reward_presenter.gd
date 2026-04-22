# Layer: UI
extends RefCounted
class_name RewardPresenter

const ItemDefinitionTooltipBuilderScript = preload("res://Game/UI/item_definition_tooltip_builder.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const RunStatusPresenterScript = preload("res://Game/UI/run_status_presenter.gd")
const UiCompactCopyScript = preload("res://Game/UI/ui_compact_copy.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const DEFAULT_CARD_COUNT: int = 3

var _item_tooltip_builder: ItemDefinitionTooltipBuilder = ItemDefinitionTooltipBuilderScript.new()


func build_chip_text(reward_state: RefCounted) -> String:
	if reward_state == null:
		return "SALVAGE"
	match String(reward_state.source_context):
		"combat_victory":
			return "COMBAT SPOILS"
		"reward_node":
			return "CACHE FIND"
		_:
			return "SALVAGE"


func build_title_text(reward_state: RefCounted) -> String:
	if reward_state == null:
		return "Reward unavailable."
	return String(reward_state.title_text)


func build_context_text(reward_state: RefCounted) -> String:
	if reward_state == null:
		return ""

	match String(reward_state.source_context):
		"combat_victory":
			return UiCompactCopyScript.pick_one("spoil")
		"reward_node":
			return UiCompactCopyScript.pick_one("find")
		_:
			return UiCompactCopyScript.pick_one("reward")


func build_hint_text(reward_state: RefCounted) -> String:
	return ""


func build_failure_text(error_text: String) -> String:
	var trimmed_error: String = error_text.strip_edges()
	match trimmed_error:
		"unknown_reward_option":
			return "That reward is no longer available."
		"missing_reward_state":
			return "Reward unavailable."
		_:
			return "Reward failed: %s" % (trimmed_error if not trimmed_error.is_empty() else "unknown")


func build_offer_view_models(reward_state: RefCounted, card_count: int = DEFAULT_CARD_COUNT) -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	var offers: Array[Dictionary] = []
	if reward_state != null:
		offers = reward_state.offers

	for index in range(card_count):
		if reward_state != null and index < offers.size():
			var offer: Dictionary = offers[index]
			var effect_type: String = String(offer.get("effect_type", ""))
			var source_context: String = String(reward_state.source_context)
			models.append({
				"visible": true,
				"badge_text": _build_badge_text(effect_type, offer),
				"title_text": _build_offer_title(offer, effect_type),
				"detail_text": _build_offer_detail(offer),
				"button_text": _build_button_text(effect_type, source_context),
				"tooltip_text": _build_offer_tooltip_text(offer, source_context),
				"icon_texture_path": _build_offer_icon_texture_path(offer),
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


func build_run_status_model(run_state: RunState) -> Dictionary:
	return RunStatusPresenterScript.build_status_model(run_state, {
		"variant": RunStatusPresenterScript.VARIANT_STANDARD,
		"include_weapon": true,
		"include_xp": true,
	})


func _build_badge_text(effect_type: String, offer: Dictionary = {}) -> String:
	match effect_type:
		"heal":
			return "Recovery"
		"repair_weapon":
			return "Forge"
		"grant_xp":
			return "Momentum"
		"grant_gold":
			return "Coins"
		"grant_item":
			match String(offer.get("inventory_family", "")):
				InventoryStateScript.INVENTORY_FAMILY_WEAPON:
					return "Weapon"
				InventoryStateScript.INVENTORY_FAMILY_SHIELD:
					return "Shield"
				InventoryStateScript.INVENTORY_FAMILY_ARMOR:
					return "Armor"
				InventoryStateScript.INVENTORY_FAMILY_BELT:
					return "Belt"
				InventoryStateScript.INVENTORY_FAMILY_PASSIVE:
					return "Passive"
				InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
					return "Shield Mod"
				InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
					return "Quest Cargo"
				_:
					return "Supplies"
		_:
			return "Reward"


func _build_offer_title(offer: Dictionary, effect_type: String) -> String:
	var label_text: String = String(offer.get("label", ""))
	if not label_text.is_empty():
		return label_text
	match effect_type:
		"heal":
			return "Bind Wounds"
		"repair_weapon":
			return "Sharpen Steel"
		"grant_xp":
			return "Take the Lesson"
		"grant_gold":
			return "Pocket the Coins"
		"grant_item":
			var inventory_family: String = String(offer.get("inventory_family", ""))
			var definition_id: String = String(offer.get("definition_id", ""))
			return _item_tooltip_builder.build_definition_display_name(inventory_family, definition_id)
		_:
			return "Reward"


func _build_offer_detail(offer: Dictionary) -> String:
	var effect_type: String = String(offer.get("effect_type", ""))
	var amount: int = int(offer.get("amount", 0))

	match effect_type:
		"heal":
			return "Recover %d HP." % amount
		"repair_weapon":
			return "Full weapon repair."
		"grant_xp":
			return "Gain %d XP." % amount
		"grant_gold":
			return "Gain %d gold." % amount
		"grant_item":
			var inventory_family: String = String(offer.get("inventory_family", "")).strip_edges()
			var definition_id: String = String(offer.get("definition_id", "")).strip_edges()
			return _item_tooltip_builder.build_definition_summary_text(
				inventory_family,
				definition_id,
				max(1, amount)
			)
		_:
			return String(offer.get("label", String(offer.get("offer_id", ""))))


func _build_button_text(effect_type: String, source_context: String) -> String:
	match effect_type:
		"heal":
			return "Recover HP"
		"repair_weapon":
			return "Repair Weapon"
		"grant_xp":
			return "Take XP"
		"grant_gold":
			return "Take Gold"
		"grant_item":
			return "Pack It"
		_:
			return "Pack It" if source_context == "combat_victory" else "Take It"


func _build_offer_tooltip_text(offer: Dictionary, source_context: String) -> String:
	var effect_type: String = String(offer.get("effect_type", ""))
	var amount: int = int(offer.get("amount", 0))
	match effect_type:
		"heal":
			return "Recover %d HP." % amount
		"repair_weapon":
			return "Full weapon repair."
		"grant_xp":
			return "Gain %d XP." % amount
		"grant_gold":
			return "Gain %d gold." % amount
		"grant_item":
			var inventory_family: String = String(offer.get("inventory_family", "")).strip_edges()
			var definition_id: String = String(offer.get("definition_id", "")).strip_edges()
			return _item_tooltip_builder.build_definition_tooltip_text(
				inventory_family,
				definition_id,
				max(1, amount)
			)
		_:
			return _build_offer_detail(offer)


func _build_offer_icon_texture_path(offer: Dictionary) -> String:
	return UiAssetPathsScript.build_effect_icon_texture_path(
		String(offer.get("effect_type", "")),
		String(offer.get("inventory_family", ""))
	)
