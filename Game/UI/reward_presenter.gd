# Layer: UI
extends RefCounted
class_name RewardPresenter

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const RunStatusPresenterScript = preload("res://Game/UI/run_status_presenter.gd")
const DEFAULT_CARD_COUNT: int = 3

var _loader: ContentLoader = ContentLoaderScript.new()


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
			return "Choose 1 of 3 spoils now before you move on."
		"reward_node":
			return "Choose 1 of 2 finds now before the cache gives way."
		_:
			return "Choose 1 salvage"


func build_hint_text(reward_state: RefCounted) -> String:
	if reward_state == null:
		return ""
	match String(reward_state.source_context):
		"combat_victory":
			return "Claim one payoff now. The other spoils are left behind."
		"reward_node":
			return "Claim one cache find now. The rest stays buried."
		_:
			return "Choose one salvage result."


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
				"button_disabled": false,
			})
		else:
			models.append({
				"visible": false,
				"badge_text": "",
				"title_text": "",
				"detail_text": "",
				"button_text": "",
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
			return _load_inventory_display_name(inventory_family, definition_id)
		_:
			return "Reward"


func _build_offer_detail(offer: Dictionary) -> String:
	var effect_type: String = String(offer.get("effect_type", ""))
	var amount: int = int(offer.get("amount", 0))

	match effect_type:
		"heal":
			return "Recover %d HP before the next leg." % amount
		"repair_weapon":
			return "Restore your active weapon to full durability."
		"grant_xp":
			return "Gain %d XP and keep the route moving." % amount
		"grant_gold":
			return "Gain %d gold for the next stop." % amount
		"grant_item":
			var inventory_family: String = String(offer.get("inventory_family", "")).strip_edges()
			var definition_id: String = String(offer.get("definition_id", "")).strip_edges()
			var item_name: String = _load_inventory_display_name(inventory_family, definition_id)
			if inventory_family == InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
				return "Add %s x%d to the backpack." % [item_name, max(1, amount)]
			if inventory_family == InventoryStateScript.INVENTORY_FAMILY_PASSIVE:
				return "Carry %s for its backpack-only passive bonus." % item_name
			if inventory_family == InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
				return "Pack %s as a shield mod for later attachment." % item_name
			if inventory_family == InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
				return "Carry %s as quest cargo. It stays separate from normal loot." % item_name
			return "Add %s to the backpack." % item_name
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
