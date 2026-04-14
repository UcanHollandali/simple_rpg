# Layer: UI
extends RefCounted
class_name MainMenuPresenter


func build_title_text() -> String:
	return "Simple RPG"


func build_subtitle_text() -> String:
	return "Ashwood Descent"


func build_mood_text() -> String:
	return "Choose a road. Survive the stops. Reach the gate."


func build_playtest_chip_text() -> String:
	return "ASHWOOD ROAD"


func build_save_chip_text(has_save: bool) -> String:
	if has_save:
		return "LOAD READY"
	return "NEW RUN"


func build_playtest_read_text(has_save: bool) -> String:
	if has_save:
		return "Start fresh or wake at your last safe screen."
	return "Start a new run. Your first road waits on the map."


func build_flow_read_text() -> String:
	return "Map -> Roadside Encounter / Combat / Shelter -> Reward / Level Up -> Gate"


func build_status_text(has_save: bool) -> String:
	if has_save:
		return "Load returns you to your last save on a safe screen."
	return "Load unlocks after your first safe-screen save."
