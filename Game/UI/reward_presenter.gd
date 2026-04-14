# Layer: UI
extends RefCounted
class_name RewardPresenter

const RunStatusPresenterScript = preload("res://Game/UI/run_status_presenter.gd")
const DEFAULT_CARD_COUNT: int = 3


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
			return "Take 1 of 3 spoils before you move."
		"reward_node":
			return "Take 1 of 2 finds before the cache gives way."
		_:
			return "Choose 1 salvage"


func build_hint_text(reward_state: RefCounted) -> String:
	if reward_state == null:
		return ""
	match String(reward_state.source_context):
		"combat_victory":
			return "Choose one payoff. The rest is left behind on the road."
		"reward_node":
			return "Take one cache find. The rest stays buried."
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
				"badge_text": _build_badge_text(effect_type),
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


func build_run_status_text(run_state: RunState) -> String:
	return RunStatusPresenterScript.build_compact_status_text(run_state)


func _build_badge_text(effect_type: String) -> String:
	match effect_type:
		"heal":
			return "Recovery"
		"repair_weapon":
			return "Forge"
		"grant_xp":
			return "Momentum"
		"grant_gold":
			return "Coins"
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
		_:
			return "Pack It" if source_context == "combat_victory" else "Take It"
