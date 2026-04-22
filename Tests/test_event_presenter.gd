# Layer: Tests
extends SceneTree
class_name TestEventPresenter

const EventPresenterScript = preload("res://Game/UI/event_presenter.gd")
const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")


func _init() -> void:
	test_event_presenter_surfaces_choice_tooltips()
	test_event_presenter_surfaces_existing_choice_costs_and_disabled_reasons()
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
	var heal_summary_text: String = String((models[0] as Dictionary).get("summary_text", ""))
	var heal_detail_text: String = String((models[0] as Dictionary).get("detail_text", ""))
	var heal_tooltip: String = String((models[0] as Dictionary).get("tooltip_text", ""))
	var item_tooltip: String = String((models[1] as Dictionary).get("tooltip_text", ""))
	assert(heal_summary_text == "Rinse off the march and breathe for a moment.", "Expected event choice summary text to preserve the authored flavor read in compact form.")
	assert(heal_detail_text == "Recover 10 HP.", "Expected event card detail text to stay compact and outcome-only.")
	assert(not heal_detail_text.contains("Rinse off the march"), "Expected event card detail text to stop duplicating long flavor summary copy.")
	assert(heal_tooltip.to_lower().contains("recover 10 hp"), "Expected event heal tooltip to expose the exact heal amount.")
	assert(item_tooltip.contains("Cured Meat"), "Expected event item tooltip to include the item name.")
	assert(item_tooltip.contains("HP +14"), "Expected event item tooltip to expose the consumable heal effect in compact form.")


func test_event_presenter_surfaces_existing_choice_costs_and_disabled_reasons() -> void:
	var presenter: RefCounted = EventPresenterScript.new()
	var event_state: EventState = EventStateScript.new()
	event_state.source_context = EventState.SOURCE_CONTEXT_NODE_EVENT
	event_state.choices = [
		{
			"choice_id": "offer_the_toll",
			"label": "Offer the toll",
			"summary": "Set down a quiet payment and wait for the gate to shift.",
			"effect_type": "grant_gold",
			"amount": 7,
			"cost_gold": 3,
			"available": false,
			"unavailable_reason": "Need 3 gold.",
		},
		{
			"choice_id": "wait_for_the_gate",
			"label": "Wait for the gate",
			"summary": "Hold your ground and see whether the road opens on its own.",
			"effect_type": "grant_xp",
			"amount": 2,
			"available": false,
		},
	]

	var models: Array = presenter.call("build_choice_view_models", event_state, 2)
	var priced_model: Dictionary = models[0] as Dictionary
	var generic_model: Dictionary = models[1] as Dictionary
	assert(String(priced_model.get("detail_text", "")) == "Cost 3g | Gain 7 gold.", "Expected existing choice cost and reward truth to be surfaced together in the detail line.")
	assert(String(priced_model.get("availability_text", "")) == "Need 3 gold.", "Expected existing disabled-reason truth to surface on the card.")
	assert(bool(priced_model.get("button_disabled", false)), "Expected existing unavailable choices to keep the CTA disabled.")
	assert(String(priced_model.get("button_text", "")) == "Unavailable", "Expected unavailable event choices to use an explicit disabled CTA label.")
	assert(String(priced_model.get("tooltip_text", "")).contains("Need 3 gold."), "Expected event choice tooltips to carry the existing disabled reason when present.")
	assert(String(generic_model.get("availability_text", "")) == "This choice is unavailable.", "Expected unavailable event choices without a modeled reason to use the local fallback wording.")
	assert(String(generic_model.get("tooltip_text", "")).contains("This choice is unavailable."), "Expected unavailable event tooltips to reuse the local fallback wording when no reason is modeled.")
