# Layer: UI
extends RefCounted
class_name LevelUpPresenter

const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const RunStatusPresenterScript = preload("res://Game/UI/run_status_presenter.gd")
const UiCompactCopyScript = preload("res://Game/UI/ui_compact_copy.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const DEFAULT_BUTTON_COUNT: int = 3
const CHIP_TEXT: String = "LEVEL UP"
const UNAVAILABLE_TITLE_TEXT: String = "Level Up unavailable."
const PERK_NOTE_TEXT: String = "No backpack slot."


func build_chip_text() -> String:
	return CHIP_TEXT


func build_title_text(level_up_state: LevelUpState) -> String:
	if level_up_state == null:
		return UNAVAILABLE_TITLE_TEXT
	return "Level %d -> %d" % [
		int(level_up_state.current_level),
		int(level_up_state.target_level),
	]


func build_context_text(level_up_state: LevelUpState) -> String:
	if level_up_state == null:
		return ""
	return UiCompactCopyScript.pick_one("perk")


func build_hint_text(level_up_state: LevelUpState) -> String:
	if level_up_state == null:
		return ""
	return "Always on."


func build_note_text(level_up_state: LevelUpState) -> String:
	if level_up_state == null:
		return ""
	return PERK_NOTE_TEXT


func build_offer_view_models(level_up_state: LevelUpState, button_count: int = DEFAULT_BUTTON_COUNT) -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	var offers: Array[Dictionary] = []
	if level_up_state != null:
		offers = level_up_state.offers

	for index in range(button_count):
		if index < offers.size():
			var offer: Dictionary = offers[index]
			var title_text: String = String(offer.get("label", ""))
			var perk_family_label: String = String(offer.get("perk_family_label", "Perk")).strip_edges()
			var summary_text: String = String(offer.get("summary", ""))
			var detail_text: String = "%s perk. %s" % [perk_family_label, summary_text]
			models.append({
				"text": "%s\n%s" % [title_text, detail_text],
				"title_text": title_text,
				"detail_text": detail_text,
				"icon_texture_path": UiAssetPathsScript.build_perk_family_icon_texture_path(perk_family_label),
				"visible": true,
				"disabled": false,
			})
		else:
			models.append({
				"text": "",
				"title_text": "",
				"detail_text": "",
				"icon_texture_path": "",
				"visible": false,
				"disabled": true,
			})

	return models


func build_run_status_model(run_state: RunState) -> Dictionary:
	return RunStatusPresenterScript.build_status_model(run_state, {
		"variant": RunStatusPresenterScript.VARIANT_STANDARD,
		"include_weapon": true,
		"include_xp": true,
	})


func build_save_status_text(save_result: Dictionary) -> String:
	return RunMenuSceneHelperScript.build_save_status_text(save_result)


func build_load_status_text(load_result: Dictionary) -> String:
	if bool(load_result.get("ok", false)):
		return ""
	return RunMenuSceneHelperScript.build_load_failure_status_text(load_result)


func build_load_button_disabled(has_save: bool) -> bool:
	return not has_save
