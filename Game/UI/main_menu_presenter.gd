# Layer: UI
extends RefCounted
class_name MainMenuPresenter


func build_title_text() -> String:
	return "Ashwood Descent"


func build_subtitle_text() -> String:
	return "Roadbound Survival"


func build_mood_text() -> String:
	return "Choose a road through the ashwood. Keep your gear alive. Reach the gate."


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
	return "Map -> Trail Event / Roadside Encounter / Combat / Support -> Reward / Level Up -> Gate"


func build_status_text(has_save: bool) -> String:
	if has_save:
		return "Resume returns you to your last safe stop."
	return "Resume unlocks after your first safe-stop save."
