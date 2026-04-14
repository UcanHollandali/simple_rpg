# Layer: UI
extends RefCounted
class_name EventPresenter

const RunStatusPresenterScript = preload("res://Game/UI/run_status_presenter.gd")
const DEFAULT_CARD_COUNT: int = 2


func build_chip_text() -> String:
	return "ROADSIDE ENCOUNTER"


func build_title_text(event_state: EventState) -> String:
	if event_state == null:
		return "Roadside Encounter unavailable."
	return String(event_state.title_text)


func build_summary_text(event_state: EventState) -> String:
	if event_state == null:
		return ""
	return String(event_state.summary_text)


func build_hint_text() -> String:
	return "Badges signal the likely tone. Detail text shows the exact outcome. Mid-roadside-save is not part of the current v1 slice."


func build_run_status_text(run_state: RunState) -> String:
	return RunStatusPresenterScript.build_compact_status_text(run_state)


func build_choice_view_models(event_state: EventState, card_count: int = DEFAULT_CARD_COUNT) -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	var choices: Array[Dictionary] = []
	if event_state != null:
		choices = event_state.choices

	for index in range(card_count):
		if index < choices.size():
			var choice: Dictionary = choices[index]
			models.append({
				"visible": true,
				"badge_text": _build_badge_text(choice),
				"title_text": String(choice.get("label", choice.get("choice_id", ""))),
				"detail_text": _build_detail_text(choice),
				"button_text": _build_button_text(choice),
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


func _build_badge_text(choice: Dictionary) -> String:
	var effect_type: String = String(choice.get("effect_type", ""))
	var amount: int = int(choice.get("amount", 0))
	match effect_type:
		"heal":
			return "Recovery"
		"grant_gold":
			return "Windfall"
		"grant_xp":
			return "Insight"
		"modify_hunger":
			return "Relief" if amount < 0 else "Risk"
		"repair_weapon":
			return "Salvage"
		"damage_player":
			return "Risk"
		_:
			return "Road"


func _build_detail_text(choice: Dictionary) -> String:
	var effect_type: String = String(choice.get("effect_type", ""))
	var summary_text: String = String(choice.get("summary", ""))
	var outcome_text: String = _build_outcome_text(effect_type, int(choice.get("amount", 0)))
	if outcome_text.is_empty():
		return summary_text
	if summary_text.is_empty():
		return outcome_text
	return "%s\n%s" % [outcome_text, summary_text]


func _build_outcome_text(effect_type: String, amount: int) -> String:
	match effect_type:
		"heal":
			return "Recover %d HP." % amount
		"grant_gold":
			return "Gain %d gold." % amount
		"grant_xp":
			return "Gain %d XP." % amount
		"modify_hunger":
			return "Restore %d hunger." % abs(amount) if amount < 0 else "Lose %d hunger." % amount
		"repair_weapon":
			return "Restore your active weapon to full durability."
		"damage_player":
			return "Take %d damage." % amount
		_:
			return ""


func _build_button_text(choice: Dictionary) -> String:
	match _build_badge_text(choice):
		"Recovery":
			return "Choose Recovery"
		"Windfall":
			return "Take the Windfall"
		"Insight":
			return "Take the Insight"
		"Relief":
			return "Settle Hunger"
		"Salvage":
			return "Take the Salvage"
		"Risk":
			return "Risk the Encounter"
		_:
			return "Choose This Encounter"
