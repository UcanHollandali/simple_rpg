# Layer: Tests
extends SceneTree
class_name TestEventContent

const EventApplicationPolicyScript = preload("res://Game/Application/event_application_policy.gd")
const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")
const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")
const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")


func _init() -> void:
	test_event_state_rotates_by_stage()
	test_event_state_varies_by_seed_but_stays_deterministic()
	test_roadside_trigger_conditions_filter_template_pool()
	test_event_template_pool_covers_named_event_and_roadside_pack()
	test_event_application_policy_covers_supported_outcomes()
	print("test_event_content: all assertions passed")
	quit()


func test_event_state_rotates_by_stage() -> void:
	var stage_one_event: EventState = EventStateScript.new()
	stage_one_event.setup_for_node(10, 1, EventStateScript.SOURCE_CONTEXT_NODE_EVENT, 1)
	assert(String(stage_one_event.template_definition_id) == "forest_shrine_echo", "Expected stage 1 to resolve the first stable-id event template.")
	assert(stage_one_event.choices.size() == 2, "Expected stage 1 event state to expose exactly 2 choices.")

	var stage_two_event: EventState = EventStateScript.new()
	stage_two_event.setup_for_node(10, 2, EventStateScript.SOURCE_CONTEXT_NODE_EVENT, 1)
	assert(String(stage_two_event.template_definition_id) == "ghost_lantern_bargain", "Expected stage 2 to resolve the second stable-id event template.")

	var stage_three_event: EventState = EventStateScript.new()
	stage_three_event.setup_for_node(10, 3, EventStateScript.SOURCE_CONTEXT_NODE_EVENT, 1)
	assert(String(stage_three_event.template_definition_id) == "moss_waystone_tithe", "Expected stage 3 to resolve the third stable-id event template after the authored event variety expansion.")

	var stage_four_event: EventState = EventStateScript.new()
	stage_four_event.setup_for_node(10, 4, EventStateScript.SOURCE_CONTEXT_NODE_EVENT, 1)
	assert(String(stage_four_event.template_definition_id) == "trickster_stump_feast", "Expected stage 4 to wrap into the fourth stable-id event template after the authored event variety expansion.")


func test_event_state_varies_by_seed_but_stays_deterministic() -> void:
	var seeded_event_a: EventState = EventStateScript.new()
	seeded_event_a.setup_for_node(10, 1, EventStateScript.SOURCE_CONTEXT_NODE_EVENT, 99)
	var mirrored_seeded_event_a: EventState = EventStateScript.new()
	mirrored_seeded_event_a.setup_for_node(10, 1, EventStateScript.SOURCE_CONTEXT_NODE_EVENT, 99)
	var seeded_event_b: EventState = EventStateScript.new()
	seeded_event_b.setup_for_node(10, 1, EventStateScript.SOURCE_CONTEXT_NODE_EVENT, 42)
	assert(
		String(seeded_event_a.template_definition_id) == String(mirrored_seeded_event_a.template_definition_id),
		"Expected the same event seed and context to reproduce the same planned event template."
	)
	assert(
		String(seeded_event_a.template_definition_id) != String(seeded_event_b.template_definition_id),
		"Expected different run seeds to surface different planned event templates from the authored pool."
	)

	var seeded_roadside_a: EventState = EventStateScript.new()
	seeded_roadside_a.setup_for_node(10, 1, EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER, 99)
	var mirrored_seeded_roadside_a: EventState = EventStateScript.new()
	mirrored_seeded_roadside_a.setup_for_node(10, 1, EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER, 99)
	assert(
		String(seeded_roadside_a.template_definition_id) == String(mirrored_seeded_roadside_a.template_definition_id),
		"Expected the same roadside seed and context to reproduce the same roadside template."
	)
	assert(
		String(seeded_roadside_a.template_definition_id) != String(seeded_event_a.template_definition_id),
		"Expected roadside and planned event contexts to stay separated inside the shared Event flow."
	)


func test_roadside_trigger_conditions_filter_template_pool() -> void:
	var loader: ContentLoader = ContentLoaderScript.new()
	var roadside_state: EventState = EventStateScript.new()
	roadside_state.source_context = EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER
	var template_ids: Array[String] = loader.list_definition_ids("EventTemplates")

	var wealthy_context: Dictionary = {
		EventStateScript.TRIGGER_STAT_HUNGER: 20,
		EventStateScript.TRIGGER_STAT_HP_PERCENT: 100.0,
		EventStateScript.TRIGGER_STAT_GOLD: 9,
		EventStateScript.TRIGGER_STAT_HAS_EMPTY_BACKPACK_SLOT: true,
	}
	var poor_context: Dictionary = wealthy_context.duplicate(true)
	poor_context[EventStateScript.TRIGGER_STAT_GOLD] = 0
	var hungry_context: Dictionary = wealthy_context.duplicate(true)
	hungry_context[EventStateScript.TRIGGER_STAT_HUNGER] = 6
	var fed_context: Dictionary = wealthy_context.duplicate(true)
	fed_context[EventStateScript.TRIGGER_STAT_HUNGER] = 16
	var wounded_context: Dictionary = wealthy_context.duplicate(true)
	wounded_context[EventStateScript.TRIGGER_STAT_HP_PERCENT] = 45.0
	var healthy_context: Dictionary = wealthy_context.duplicate(true)
	healthy_context[EventStateScript.TRIGGER_STAT_HP_PERCENT] = 100.0
	var full_pack_context: Dictionary = wealthy_context.duplicate(true)
	full_pack_context[EventStateScript.TRIGGER_STAT_HAS_EMPTY_BACKPACK_SLOT] = false

	var wealthy_ids: Array[String] = roadside_state.call("_filter_template_ids_for_source_context", template_ids, loader, wealthy_context)
	var poor_ids: Array[String] = roadside_state.call("_filter_template_ids_for_source_context", template_ids, loader, poor_context)
	var hungry_ids: Array[String] = roadside_state.call("_filter_template_ids_for_source_context", template_ids, loader, hungry_context)
	var fed_ids: Array[String] = roadside_state.call("_filter_template_ids_for_source_context", template_ids, loader, fed_context)
	var wounded_ids: Array[String] = roadside_state.call("_filter_template_ids_for_source_context", template_ids, loader, wounded_context)
	var healthy_ids: Array[String] = roadside_state.call("_filter_template_ids_for_source_context", template_ids, loader, healthy_context)
	var empty_pack_ids: Array[String] = roadside_state.call("_filter_template_ids_for_source_context", template_ids, loader, wealthy_context)
	var full_pack_ids: Array[String] = roadside_state.call("_filter_template_ids_for_source_context", template_ids, loader, full_pack_context)

	assert(wealthy_ids.has("yellow_road_cutpurses"), "Expected gold-triggered roadside cutpurses to join the eligible roadside pool when the player is carrying gold.")
	assert(not poor_ids.has("yellow_road_cutpurses"), "Expected gold-triggered roadside cutpurses to stay out of the eligible pool when the player is broke.")
	assert(hungry_ids.has("zigzag_wolf_sign"), "Expected hunger-triggered wolf-sign roadside content to join the eligible pool when hunger is low.")
	assert(not fed_ids.has("zigzag_wolf_sign"), "Expected hunger-triggered wolf-sign roadside content to stay out when hunger is still healthy.")
	assert(wounded_ids.has("zz_sunken_toll_fire"), "Expected HP-triggered toll-fire roadside content to join the eligible pool when the player is wounded.")
	assert(not healthy_ids.has("zz_sunken_toll_fire"), "Expected HP-triggered toll-fire roadside content to stay out when the player is healthy.")
	assert(empty_pack_ids.has("wrenched_supply_cart"), "Expected pack-sensitive roadside supply-cart content to join the eligible pool when the backpack has room.")
	assert(not full_pack_ids.has("wrenched_supply_cart"), "Expected pack-sensitive roadside supply-cart content to stay out when the backpack is full.")


func test_event_template_pool_covers_named_event_and_roadside_pack() -> void:
	var loader: ContentLoader = ContentLoaderScript.new()
	var planned_names: Array[String] = []
	var roadside_names: Array[String] = []
	for definition_id in loader.list_definition_ids("EventTemplates"):
		var event_definition: Dictionary = loader.load_definition("EventTemplates", definition_id)
		var tags: Array = event_definition.get("tags", [])
		var display_name: String = String(event_definition.get("display", {}).get("name", definition_id))
		if tags.has("roadside"):
			roadside_names.append(display_name)
		elif tags.has("event"):
			planned_names.append(display_name)

	for required_event_name in [
		"The Shrine in the Moss",
		"Lantern at the Split Path",
		"Waystone Toll",
		"Table Set by Nothing",
		"Wardenless Gate Toll",
		"Watchfire Ruin Cache",
		"Weathered Signal Tree",
		"Woodsmoke Bunkhouse",
		"Woundvine Altar",
		"Wrecked Bell Tower",
		"Ledger Beneath the Ash Tree",
		"Stones Around a Dry Well",
		"Embers in the Watch Post",
	]:
		assert(planned_names.has(required_event_name), "Expected planned event pool to include %s." % required_event_name)

	for required_roadside_name in [
		"Traveler Under the Wreck",
		"Roadside Cutpurses",
		"Half-Spent Campfire",
		"Broken Guard Hut",
		"Lost Supply Cart",
		"Hungry Wolf Tracks",
		"Crows at the Barrow Stones",
		"Split Axle on the Verge",
		"Sunken Toll Fire",
		"Suspicious Merchant",
		"Old Road Sign",
		"Broken Bridge Crossing",
		"Silent Grave Mound",
	]:
		assert(roadside_names.has(required_roadside_name), "Expected roadside event pool to include %s." % required_roadside_name)

	assert(planned_names.size() >= 15, "Expected at least 15 planned event templates in the live content pool after the authored expansion.")
	assert(roadside_names.size() >= 13, "Expected at least 13 roadside-tagged event templates in the live content pool after the extra roadside authored pass.")


func test_event_application_policy_covers_supported_outcomes() -> void:
	var policy: EventApplicationPolicy = EventApplicationPolicyScript.new()
	var inventory_actions: InventoryActions = InventoryActionsScript.new()

	var heal_run_state: RunState = _build_run_state()
	heal_run_state.player_hp = 40
	var heal_event: EventState = EventStateScript.new()
	heal_event.setup_for_node(10, 1)
	var heal_result: Dictionary = policy.apply_option(heal_run_state, heal_event, inventory_actions, "drink_from_the_basin")
	assert(bool(heal_result.get("ok", false)), "Expected heal event outcome to apply successfully.")
	assert(heal_run_state.player_hp == 50, "Expected heal event outcome to restore HP.")

	var gold_run_state: RunState = _build_run_state()
	gold_run_state.gold = 3
	var waystone_event: EventState = EventStateScript.new()
	waystone_event.setup_for_node(10, 3)
	var gold_result: Dictionary = policy.apply_option(gold_run_state, waystone_event, inventory_actions, "lift_the_tithe")
	assert(bool(gold_result.get("ok", false)), "Expected gold event outcome to apply successfully.")
	assert(gold_run_state.gold == 10, "Expected gold event outcome to grant the authored waystone payout.")

	var xp_run_state: RunState = _build_run_state()
	xp_run_state.xp = 6
	var ghost_event: EventState = EventStateScript.new()
	ghost_event.setup_for_node(10, 2)
	var xp_result: Dictionary = policy.apply_option(xp_run_state, ghost_event, inventory_actions, "answer_the_question")
	assert(bool(xp_result.get("ok", false)), "Expected XP event outcome to apply successfully.")
	assert(xp_run_state.xp == 11, "Expected XP event outcome to grant XP.")

	var damage_run_state: RunState = _build_run_state()
	damage_run_state.player_hp = 5
	var damage_result: Dictionary = policy.apply_option(damage_run_state, ghost_event, inventory_actions, "walk_through_the_light")
	assert(bool(damage_result.get("ok", false)), "Expected damage event outcome to apply successfully.")
	assert(damage_run_state.player_hp == 0, "Expected damage event outcome to reduce HP to zero when lethal.")
	assert(bool(damage_result.get("player_defeated", false)), "Expected lethal damage event outcome to flag defeat.")

	var hunger_run_state: RunState = _build_run_state()
	hunger_run_state.hunger = 15
	var trick_event: EventState = EventStateScript.new()
	trick_event.setup_for_node(10, 4)
	var hunger_result: Dictionary = policy.apply_option(hunger_run_state, trick_event, inventory_actions, "eat_the_false_meal")
	assert(bool(hunger_result.get("ok", false)), "Expected hunger event outcome to apply successfully.")
	assert(hunger_run_state.hunger == 11, "Expected hunger event outcome to apply the authored hunger loss.")

	var repair_run_state: RunState = _build_run_state()
	repair_run_state.inventory_state.weapon_instance["current_durability"] = 3
	var repair_result: Dictionary = policy.apply_option(repair_run_state, trick_event, inventory_actions, "pry_free_the_blade")
	assert(bool(repair_result.get("ok", false)), "Expected repair event outcome to apply successfully.")
	assert(int(repair_run_state.inventory_state.weapon_instance.get("current_durability", 0)) == 20, "Expected repair event outcome to restore weapon durability.")


func _build_run_state() -> RunState:
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	return run_state
