# Layer: UI
extends RefCounted
class_name StageTransitionPresenter

const RunStatusPresenterScript = preload("res://Game/UI/run_status_presenter.gd")
const UiCompactCopyScript = preload("res://Game/UI/ui_compact_copy.gd")
const PERSONALITY_PILGRIM := "pilgrim"
const PERSONALITY_FRONTIER := "frontier"
const PERSONALITY_TRADE := "trade"


func build_chip_text(stage_index: int) -> String:
	return "STAGE %d CLEAR" % max(stage_index - 1, 1)


func build_title_text(stage_index: int, stage_personality: String = "") -> String:
	return "Stage %d — %s" % [max(1, stage_index), _build_stage_title_suffix(stage_personality)]


func build_summary_text(stage_personality: String = "") -> String:
	match stage_personality:
		PERSONALITY_FRONTIER:
			return "Hard contracts. Rougher pay."
		PERSONALITY_PILGRIM:
			return "Safer jobs. Survival pay."
		PERSONALITY_TRADE:
			return "Practical jobs. Utility pay."
		_:
			return "New route open."


func build_hint_text() -> String:
	return UiCompactCopyScript.objective_key_boss()


func build_run_status_model(run_state: RunState) -> Dictionary:
	return RunStatusPresenterScript.build_status_model(run_state, {
		"variant": RunStatusPresenterScript.VARIANT_STANDARD,
		"include_weapon": true,
		"include_xp": true,
	})


func _build_stage_title_suffix(stage_personality: String) -> String:
	match stage_personality:
		PERSONALITY_FRONTIER:
			return "Frontier Reach"
		PERSONALITY_PILGRIM:
			return "Pilgrim Roads"
		PERSONALITY_TRADE:
			return "Trade Lanes"
		_:
			return "Beyond the Treeline"
