# Layer: Tests
extends SceneTree
class_name TestEventPresenter

const EventPresenterScript = preload("res://Game/UI/event_presenter.gd")
const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")


func _init() -> void:
	test_event_presenter_surfaces_choice_tooltips()
	print("test_event_presenter: all assertions passed")
	quit()


func test_event_presenter_surfaces_choice_tooltips() -> void:
	var presenter: RefCounted = EventPresenterScript.new()
	var event_state: EventState = EventStateScript.new()
	event_state.source_context = EventState.SOURCE_CONTEXT_NODE_EVENT
	event_state.choices = [
		{
			"choice_id": "wash_the_road_dust_away",
			"label": "Wash the road dust away",
			"summary": "Rinse off the march and breathe for a moment.",
			"effect_type": "heal",
			"amount": 10,
		},
		{
			"choice_id": "bait_a_quick_snare",
			"label": "Bait a quick snare",
			"summary": "Lift what the wolves left behind and move on with fresh rations.",
			"effect_type": "grant_item",
			"inventory_family": "consumable",
			"definition_id": "cured_meat",
			"amount": 1,
		},
	]

	var models: Array = presenter.call("build_choice_view_models", event_state, 2)
	var heal_detail_text: String = String((models[0] as Dictionary).get("detail_text", ""))
	var heal_tooltip: String = String((models[0] as Dictionary).get("tooltip_text", ""))
	var item_tooltip: String = String((models[1] as Dictionary).get("tooltip_text", ""))
	assert(heal_detail_text == "Recover 10 HP.", "Expected event card detail text to stay compact and outcome-only.")
	assert(not heal_detail_text.contains("Rinse off the march"), "Expected event card detail text to stop duplicating long flavor summary copy.")
	assert(heal_tooltip.to_lower().contains("recover 10 hp"), "Expected event heal tooltip to expose the exact heal amount.")
	assert(item_tooltip.contains("Cured Meat"), "Expected event item tooltip to include the item name.")
	assert(item_tooltip.contains("HP +14"), "Expected event item tooltip to expose the consumable heal effect in compact form.")
