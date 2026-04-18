# Layer: Application
extends RefCounted
class_name RewardApplicationPolicy

const INVENTORY_CHOICE_REQUIRED_ERROR: String = "inventory_choice_required"


func apply_option(
	active_run_state: RunState,
	active_reward_state: RewardState,
	inventory_actions: InventoryActions,
	option_id: String,
	discard_slot_id: int = -1,
	leave_item: bool = false
) -> Dictionary:
	if active_run_state == null:
		return {"ok": false, "option_id": option_id, "error": "missing_run_state"}
	if active_reward_state == null:
		return {"ok": false, "option_id": option_id, "error": "missing_reward_state"}

	var offer: Dictionary = active_reward_state.get_offer_by_id(option_id)
	if offer.is_empty():
		return {"ok": false, "option_id": option_id, "error": "unknown_reward_option"}

	var result: Dictionary = {
		"ok": true,
		"option_id": option_id,
		"source_context": active_reward_state.source_context,
	}
	var effect_type: String = String(offer.get("effect_type", ""))
	var amount: int = int(offer.get("amount", 0))

	match effect_type:
		"heal":
			active_run_state.player_hp = min(RunState.DEFAULT_PLAYER_HP, active_run_state.player_hp + amount)
			result["player_hp"] = active_run_state.player_hp
			result["applied_amount"] = amount
		"repair_weapon":
			var repair_result: Dictionary = inventory_actions.repair_active_weapon(active_run_state.inventory_state)
			if not bool(repair_result.get("ok", false)):
				return {"ok": false, "option_id": option_id, "error": String(repair_result.get("error", "reward_apply_failed"))}
			result.merge(repair_result, true)
		"grant_xp":
			active_run_state.xp += amount
			result["xp"] = active_run_state.xp
			result["applied_amount"] = amount
		"grant_gold":
			active_run_state.gold += amount
			result["gold"] = active_run_state.gold
			result["applied_amount"] = amount
		"grant_item":
			var inventory_family: String = String(offer.get("inventory_family", "")).strip_edges()
			var definition_id: String = String(offer.get("definition_id", "")).strip_edges()
			if leave_item:
				result["item_left"] = true
				result["inventory_family"] = inventory_family
				result["definition_id"] = definition_id
				result["applied_amount"] = 0
			else:
				var preview_result: Dictionary = inventory_actions.preview_inventory_item_grant(
					active_run_state.inventory_state,
					inventory_family,
					definition_id,
					max(1, amount)
				)
				if not bool(preview_result.get("ok", false)):
					return preview_result.merged({
						"ok": false,
						"option_id": option_id,
						"error": String(preview_result.get("error", "reward_apply_failed")),
					}, true)
				if bool(preview_result.get("inventory_choice_required", false)) and discard_slot_id <= 0:
					return preview_result.merged({
						"ok": false,
						"option_id": option_id,
						"error": INVENTORY_CHOICE_REQUIRED_ERROR,
					}, true)
				var grant_result: Dictionary = inventory_actions.grant_inventory_item(
					active_run_state.inventory_state,
					inventory_family,
					definition_id,
					max(1, amount),
					discard_slot_id
				)
				if not bool(grant_result.get("ok", false)):
					return {"ok": false, "option_id": option_id, "error": String(grant_result.get("error", "reward_apply_failed"))}
				result.merge(grant_result, true)
		_:
			return {"ok": false, "option_id": option_id, "error": "unknown_reward_option"}

	return result
