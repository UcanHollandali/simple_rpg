# Layer: UI
extends RefCounted
class_name MainMenuPresenter

const MapDisplayNameHelperScript = preload("res://Game/UI/map_display_name_helper.gd")
const UiCompactCopyScript = preload("res://Game/UI/ui_compact_copy.gd")


func build_title_text() -> String:
	return "Ashwood Descent"


func build_subtitle_text() -> String:
	return "Roadbound Survival"


func build_mood_text() -> String:
	return "Survive the road. Reach the gate."


func build_playtest_chip_text() -> String:
	return "WAYFINDER RUN"


func build_save_chip_text(has_save: bool) -> String:
	if has_save:
		return "SAFE SAVE READY"
	return "FRESH ROAD"


func build_playtest_read_text(has_save: bool) -> String:
	if has_save:
		return "Start fresh or return to your last safe stop."
	return "Step onto a fresh road. The first branches teach fast."


func build_flow_read_text() -> String:
	var planned_event_label: String = MapDisplayNameHelperScript.build_family_display_name("event")
	return UiCompactCopyScript.join_steps([
		"Map",
		planned_event_label,
		"Roadside",
		"Combat",
		"Support",
		"Reward",
		"Perk",
		"Gate",
	])


func build_status_text(has_save: bool) -> String:
	if has_save:
		return "Resume returns you to your last safe stop."
	return "Resume unlocks after your first safe-stop save."
