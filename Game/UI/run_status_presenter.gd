# Layer: UI
extends RefCounted
class_name RunStatusPresenter


static func build_compact_status_text(run_state: RunState) -> String:
	if run_state == null:
		return ""

	var inventory_state: RefCounted = run_state.inventory_state
	return "HP %d | Hunger %d | Gold %d | Durability %d" % [
		run_state.player_hp,
		run_state.hunger,
		run_state.gold,
		int(inventory_state.weapon_instance.get("current_durability", 0)),
	]
