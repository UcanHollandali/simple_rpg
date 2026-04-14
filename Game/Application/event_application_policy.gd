# Layer: Application
extends RefCounted
class_name EventApplicationPolicy

const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")

func apply_option(active_run_state: RunState, active_event_state: EventStateScript, inventory_actions: InventoryActions, option_id: String) -> Dictionary:
	if active_run_state == null:
		return {"ok": false, "option_id": option_id, "error": "missing_run_state"}
	if active_event_state == null:
		return {"ok": false, "option_id": option_id, "error": "missing_event_state"}

	var choice: Dictionary = active_event_state.get_choice_by_id(option_id)
	if choice.is_empty():
		return {"ok": false, "option_id": option_id, "error": "unknown_event_option"}

	var result: Dictionary = {
		"ok": true,
		"option_id": option_id,
		"template_definition_id": active_event_state.template_definition_id,
		"source_node_id": active_event_state.source_node_id,
	}
	var effect_type: String = String(choice.get("effect_type", ""))
	var amount: int = int(choice.get("amount", 0))

	match effect_type:
		"grant_gold":
			active_run_state.gold += amount
			result["gold"] = active_run_state.gold
			result["applied_amount"] = amount
		"grant_xp":
			active_run_state.xp += amount
			result["xp"] = active_run_state.xp
			result["applied_amount"] = amount
		"heal":
			active_run_state.player_hp = min(RunState.DEFAULT_PLAYER_HP, active_run_state.player_hp + amount)
			result["player_hp"] = active_run_state.player_hp
			result["applied_amount"] = amount
		"modify_hunger":
			active_run_state.hunger = clamp(active_run_state.hunger - amount, 0, RunState.DEFAULT_HUNGER)
			result["hunger"] = active_run_state.hunger
			result["applied_amount"] = amount
		"repair_weapon":
			var repair_result: Dictionary = inventory_actions.repair_active_weapon(active_run_state.inventory_state)
			if not bool(repair_result.get("ok", false)):
				return {"ok": false, "option_id": option_id, "error": String(repair_result.get("error", "event_apply_failed"))}
			result.merge(repair_result, true)
		"damage_player":
			active_run_state.player_hp = max(0, active_run_state.player_hp - amount)
			result["player_hp"] = active_run_state.player_hp
			result["applied_amount"] = amount
			result["player_defeated"] = active_run_state.player_hp <= 0
		_:
			return {"ok": false, "option_id": option_id, "error": "unknown_event_option"}

	return result
