# Layer: UI
extends RefCounted
class_name SupportInteractionPresenter

const RunStatusPresenterScript = preload("res://Game/UI/run_status_presenter.gd")
const DEFAULT_BUTTON_COUNT: int = 3


func build_chip_text(support_state: RefCounted) -> String:
	if support_state == null:
		return "STOP"
	match String(support_state.support_type):
		"rest":
			return "SAFE REST"
		"merchant":
			return "MERCHANT"
		"blacksmith":
			if bool(support_state.call("is_blacksmith_target_selection_active")):
				return "FORGE TARGET"
			return "FORGE SERVICE"
		"hamlet":
			return "HAMLET"
		_:
			return "SUPPORT"


func build_title_text(support_state: RefCounted) -> String:
	if support_state == null:
		return "Support unavailable."
	var title_text: String = String(support_state.title_text).strip_edges()
	if not title_text.is_empty():
		return title_text
	return "Support"


func build_context_text(support_state: RefCounted) -> String:
	if support_state == null:
		return ""

	match String(support_state.support_type):
		"rest":
			return "Safe shelter. Take one recovery action or leave with your current supplies."
		"merchant":
			return "Fixed stock. Buy any offers you can afford and still carry."
		"blacksmith":
			if bool(support_state.call("is_blacksmith_target_selection_active")):
				return "Choose the carried target for this one service."
			return "One forge service resolves this stop. Pick the service that matters most."
		"hamlet":
			var mission_status: String = String(support_state.get("mission_status"))
			match mission_status:
				"offered":
					return "Accept one hamlet request to mark a stage objective."
				"accepted":
					return "The hamlet request is live. Finish the marked objective, then return here to claim aid."
				"completed":
					return "The hamlet request is done. Claim one aid reward now before you leave."
				_:
					return "This hamlet board is settled. Leave when ready."
		_:
			return ""


func build_summary_text(support_state: RefCounted) -> String:
	if support_state == null:
		return ""
	return String(support_state.summary_text)


func build_hint_text(support_state: RefCounted) -> String:
	if support_state == null:
		return ""

	match String(support_state.support_type):
		"rest":
			return "Single use. Rest heals 10 HP and spends 3 hunger."
		"merchant":
			return "You can buy multiple offers here. Leave when your pack or gold says stop."
		"blacksmith":
			if bool(support_state.call("is_blacksmith_target_selection_active")):
				return "Pick one carried target. Applying an upgrade ends this stop."
			return "Pick one service. Repair or upgrade resolves the stop immediately."
		"hamlet":
			var mission_status: String = String(support_state.get("mission_status"))
			match mission_status:
				"offered":
					return "Accept the request, finish the marked objective, then return here to claim aid."
				"accepted":
					return "The marked objective is now on the map. Complete it, then return here."
				"completed":
					return "Choose 1 aid reward. Claiming it closes this request."
				_:
					return "This hamlet board is settled. Leave when ready."
		_:
			return ""


func build_run_status_model(run_state: RunState) -> Dictionary:
	return RunStatusPresenterScript.build_status_model(run_state, {
		"variant": RunStatusPresenterScript.VARIANT_COMPACT,
		"include_weapon": false,
	})


func build_action_view_models(support_state: RefCounted, button_count: int = DEFAULT_BUTTON_COUNT) -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	var offers: Array[Dictionary] = []
	if support_state != null:
		offers = support_state.offers

	for index in range(button_count):
		if support_state != null and index < offers.size():
			var offer: Dictionary = offers[index]
			var support_type: String = String(support_state.support_type)
			var is_available: bool = bool(offer.get("available", true))
			models.append({
				"text": _build_offer_text(
					String(offer.get("label", offer.get("offer_id", ""))),
					support_type,
					is_available,
					String(offer.get("unavailable_reason", ""))
				),
				"visible": true,
				"disabled": not is_available,
			})
		else:
			models.append({
				"text": "",
				"visible": false,
				"disabled": true,
			})

	return models


func build_leave_button_text(support_state: RefCounted) -> String:
	if support_state != null and String(support_state.support_type) == "blacksmith" and bool(support_state.call("is_blacksmith_target_selection_active")):
		return "Back to Services"
	return "Back to the Road"


func _build_offer_text(label_text: String, support_type: String, is_available: bool, unavailable_reason: String = "") -> String:
	if is_available:
		return label_text
	if unavailable_reason == "no_target":
		return label_text
	if unavailable_reason in ["contract_active", "contract_claimed"]:
		return label_text
	match support_type:
		"merchant":
			return "%s\nGone" % label_text
		_:
			return "%s\nSpent" % label_text
