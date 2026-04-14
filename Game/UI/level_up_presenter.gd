# Layer: UI
extends RefCounted
class_name LevelUpPresenter

const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const DEFAULT_BUTTON_COUNT: int = 3
const UNAVAILABLE_TITLE_TEXT: String = "Level Up unavailable."
const REPLACEMENT_WARNING_TEXT: String = "Inventory full. Choosing a passive will displace the oldest unequipped carried item."


func build_title_text(level_up_state: LevelUpState) -> String:
	if level_up_state == null:
		return UNAVAILABLE_TITLE_TEXT
	return "Level %d -> %d" % [
		int(level_up_state.current_level),
		int(level_up_state.target_level),
	]


func build_note_text(level_up_state: LevelUpState) -> String:
	if level_up_state == null:
		return ""
	if bool(level_up_state.requires_replacement):
		return REPLACEMENT_WARNING_TEXT
	return ""


func build_offer_view_models(level_up_state: LevelUpState, button_count: int = DEFAULT_BUTTON_COUNT) -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	var offers: Array[Dictionary] = []
	if level_up_state != null:
		offers = level_up_state.offers

	for index in range(button_count):
		if index < offers.size():
			var offer: Dictionary = offers[index]
			var title_text: String = String(offer.get("label", ""))
			var detail_text: String = String(offer.get("summary", ""))
			models.append({
				"text": "%s\n%s" % [title_text, detail_text],
				"title_text": title_text,
				"detail_text": detail_text,
				"visible": true,
				"disabled": false,
			})
		else:
			models.append({
				"text": "",
				"title_text": "",
				"detail_text": "",
				"visible": false,
				"disabled": true,
			})

	return models


func build_initial_status_text() -> String:
	return ""


func build_save_status_text(save_result: Dictionary) -> String:
	return RunMenuSceneHelperScript.build_save_status_text(save_result)


func build_load_status_text(load_result: Dictionary) -> String:
	if bool(load_result.get("ok", false)):
		return ""
	return RunMenuSceneHelperScript.build_load_failure_status_text(load_result)


func build_load_button_disabled(has_save: bool) -> bool:
	return not has_save
