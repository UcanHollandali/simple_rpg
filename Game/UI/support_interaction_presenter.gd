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
			return "ROAD TRADE"
		"blacksmith":
			if bool(support_state.call("is_blacksmith_target_selection_active")):
				return "FORGE TARGET"
			return "FORGE SERVICE"
		"side_mission":
			return "VILLAGE REQUEST"
		_:
			return "SUPPORT"


func build_title_text(support_state: RefCounted) -> String:
	if support_state == null:
		return "Support unavailable."
	var title_text: String = String(support_state.title_text).strip_edges()
	if not title_text.is_empty():
		return title_text
	return "Support"


func build_summary_text(support_state: RefCounted) -> String:
	if support_state == null:
		return ""
	return String(support_state.summary_text)


func build_hint_text(support_state: RefCounted) -> String:
	if support_state == null:
		return ""

	match String(support_state.support_type):
		"rest":
			return "Single use. Rest heals 8 HP and spends 4 hunger."
		"merchant":
			return "Buy as many valid offers as you can afford, then leave when ready."
		"blacksmith":
			if bool(support_state.call("is_blacksmith_target_selection_active")):
				return "Pick one carried target. Applying an upgrade ends this stop."
			return "Pick one service. Repair or upgrade resolves the stop immediately."
		"side_mission":
			var mission_status: String = String(support_state.get("mission_status"))
			match mission_status:
				"offered":
					return "Accept the request, hunt the marked avcı, then return here for a reward."
				"accepted":
					return "The marked avcı is now on the map. Defeat it, then return."
				"completed":
					return "Choose 1 aid reward. Taking it closes this request."
				_:
					return "This request board is settled. Leave when ready."
		_:
			return ""


func build_run_status_text(run_state: RunState) -> String:
	return RunStatusPresenterScript.build_compact_status_text(run_state)


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
