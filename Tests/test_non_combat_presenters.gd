# Layer: Tests
extends SceneTree
class_name TestNonCombatPresenters

const LaunchIntroPresenterScript = preload("res://Game/UI/launch_intro_presenter.gd")
const EventPresenterScript = preload("res://Game/UI/event_presenter.gd")
const LevelUpPresenterScript = preload("res://Game/UI/level_up_presenter.gd")
const MainMenuPresenterScript = preload("res://Game/UI/main_menu_presenter.gd")
const SupportInteractionPresenterScript = preload("res://Game/UI/support_interaction_presenter.gd")
const StageTransitionPresenterScript = preload("res://Game/UI/stage_transition_presenter.gd")
const TransitionShellPresenterScript = preload("res://Game/UI/transition_shell_presenter.gd")
const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")
const EventStateScript = preload("res://Game/RuntimeState/event_state.gd")
const SupportInteractionStateScript = preload("res://Game/RuntimeState/support_interaction_state.gd")
const LevelUpStateScript = preload("res://Game/RuntimeState/level_up_state.gd")
const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")


func _init() -> void:
	test_launch_intro_presenter_builds_boot_splash_copy()
	test_event_presenter_builds_two_choice_event_models()
	test_level_up_presenter_builds_text_first_view_models()
	test_main_menu_presenter_builds_playtest_shell_text()
	test_support_interaction_presenter_builds_non_combat_view_models()
	test_support_interaction_presenter_builds_hamlet_contract_models()
	test_support_interaction_state_roundtrips_blacksmith_target_selection_state()
	test_stage_transition_presenter_builds_interstitial_text()
	test_transition_shell_presenter_builds_node_resolve_text()
	print("test_non_combat_presenters: all assertions passed")
	quit()


func test_launch_intro_presenter_builds_boot_splash_copy() -> void:
	var presenter: RefCounted = LaunchIntroPresenterScript.new()
	assert(
		presenter.call("build_chip_text") == "ASHWOOD ROAD",
		"Expected launch intro presenter chip text to stay stable."
	)
	assert(
		presenter.call("build_title_text") == "Simple RPG",
		"Expected launch intro presenter to expose the player-facing title."
	)
	assert(
		presenter.call("build_mood_text") == "Ashwood Descent",
		"Expected launch intro presenter to keep the flavor subtitle line."
	)
	assert(
		String(presenter.call("build_continue_hint_text")).contains("Tap"),
		"Expected launch intro presenter to keep the continue hint."
	)


func test_event_presenter_builds_two_choice_event_models() -> void:
	var presenter: RefCounted = EventPresenterScript.new()
	var event_state: EventState = EventStateScript.new()
	event_state.setup_for_node(10, 1)
	var roadside_event_state: EventState = EventStateScript.new()
	roadside_event_state.setup_for_node(10, 1, EventStateScript.SOURCE_CONTEXT_ROADSIDE_ENCOUNTER)

	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 36
	run_state.hunger = 14
	run_state.gold = 9
	run_state.inventory_state.weapon_instance["current_durability"] = 7

	assert(
		presenter.call("build_chip_text", event_state) == "TRAIL EVENT",
		"Expected planned event nodes to expose the dedicated trail-event chip."
	)
	assert(
		presenter.call("build_chip_text", roadside_event_state) == "ROADSIDE ENCOUNTER",
		"Expected movement-triggered interruptions to keep the roadside encounter chip."
	)
	assert(
		presenter.call("build_title_text", event_state) == "The Shrine in the Moss",
		"Expected event presenter to use runtime-backed event title text."
	)
	assert(
		String(presenter.call("build_summary_text", event_state)).contains("half-sunken shrine"),
		"Expected event presenter to use runtime-backed event summary text."
	)
	assert(
		presenter.call("build_context_text", event_state) == "Pick 1 result.",
		"Expected planned event nodes to use the shorter shell context."
	)
	assert(
		presenter.call("build_context_text", roadside_event_state) == "Roadside stop. Resolve it and move on.",
		"Expected roadside encounters to use the shorter interruption context."
	)
	assert(
		presenter.call("build_hint_text") == "Hover for details.",
		"Expected event presenter to keep the hover read compact."
	)
	assert(
		String(presenter.call("build_choice_failure_text", event_state, "missing_choice")) == "Event failed: missing_choice",
		"Expected planned event failures to avoid reusing the roadside-only label."
	)
	assert(
		String(presenter.call("build_choice_failure_text", roadside_event_state, "missing_choice")) == "Roadside encounter failed: missing_choice",
		"Expected movement-triggered interruptions to keep the roadside-specific failure prefix."
	)
	assert(
		String(presenter.call("build_choice_icon_texture_path", event_state)) == "res://Assets/Icons/icon_map_trail_event.svg",
		"Expected planned event nodes to expose the dedicated trail-event icon path."
	)
	assert(
		String(presenter.call("build_choice_icon_texture_path", roadside_event_state)) == "res://Assets/Icons/icon_node_marker.svg",
		"Expected roadside interruptions to keep the generic route marker icon path."
	)
	var event_status_model: Dictionary = presenter.call("build_run_status_model", run_state)
	var event_primary_items: Array = event_status_model.get("primary_items", [])
	var event_secondary_items: Array = event_status_model.get("secondary_items", [])
	assert(
		String(event_status_model.get("variant", "")) == "compact",
		"Expected event presenter to expose the compact shared run-status variant."
	)
	assert(event_primary_items.size() == 4, "Expected event presenter to expose the four core run-status chips.")
	assert(
		event_secondary_items.size() == 1 and String((event_secondary_items[0] as Dictionary).get("value_text", "")).contains("Iron Sword"),
		"Expected event presenter to expose the active weapon summary in the shared run-status strip."
	)
	assert(
		String(event_status_model.get("fallback_text", "")) == "HP 36 | Hunger 14 | Gold 9 | Durability 7",
		"Expected event presenter to keep the compact fallback string inside the shared run-status model."
	)

	var models: Array = presenter.call("build_choice_view_models", event_state, 2)
	assert(models.size() == 2, "Expected event presenter to return one model per event choice.")
	assert(String((models[0] as Dictionary).get("badge_text", "")) == "Recovery", "Expected heal event choices to surface the recovery badge.")
	assert(String((models[0] as Dictionary).get("title_text", "")) == "Wash the road dust away", "Expected the first event choice title to come from content.")
	assert(String((models[0] as Dictionary).get("detail_text", "")).contains("Recover 10 HP."), "Expected event presenter to surface explicit numeric outcome text for healing choices.")
	assert(String((models[0] as Dictionary).get("button_text", "")) == "Choose Recovery", "Expected recovery choices to expose a clearer CTA.")
	assert(String((models[0] as Dictionary).get("icon_texture_path", "")) == "res://Assets/Icons/icon_hp.svg", "Expected heal event choices to expose the HP icon path.")
	assert(String((models[1] as Dictionary).get("badge_text", "")) == "Risk", "Expected harmful encounter choices to surface the risk badge.")
	assert(String((models[1] as Dictionary).get("title_text", "")) == "Turn over the offering bowl", "Expected the second event choice title to come from content.")
	assert(String((models[1] as Dictionary).get("detail_text", "")).contains("Take 4 damage."), "Expected event presenter to surface explicit numeric outcome text for harmful choices.")
	assert(String((models[1] as Dictionary).get("button_text", "")) == "Risk the Encounter", "Expected risky encounter choices to expose a clearer CTA.")
	assert(String((models[1] as Dictionary).get("icon_texture_path", "")) == "res://Assets/Icons/icon_attack.svg", "Expected harmful event choices to expose the attack icon path.")


func test_level_up_presenter_builds_text_first_view_models() -> void:
	var presenter: RefCounted = LevelUpPresenterScript.new()
	var level_up_state: LevelUpState = LevelUpStateScript.new()
	level_up_state.setup_for_level("test_level_up", 2, [
		{
			"offer_id": "iron_skin",
			"label": "Iron Skin",
			"summary": "Gain +2 armor.",
			"perk_family_label": "Defense",
		},
		{
			"offer_id": "quick_step",
			"label": "Quick Step",
			"summary": "Draw faster next turn.",
			"perk_family_label": "Offense",
		},
	])

	assert(
		presenter.call("build_chip_text") == "LEVEL UP",
		"Expected level-up presenter to expose the unified overlay chip."
	)
	assert(
		presenter.call("build_title_text", null) == "Level Up unavailable.",
		"Expected level-up presenter to keep the text-first placeholder shell title."
	)
	assert(
		presenter.call("build_context_text", level_up_state) == "Pick 1 perk.",
		"Expected level-up presenter to explain the immediate choice context with shorter copy."
	)
	assert(
		presenter.call("build_hint_text", level_up_state) == "Always on.",
		"Expected level-up presenter to explain that perks are separate from carried inventory with shorter copy."
	)
	assert(
		presenter.call("build_note_text", null) == "",
		"Expected level-up presenter to keep placeholder note text empty."
	)
	assert(
		presenter.call("build_title_text", level_up_state) == "Level 2 -> 3",
		"Expected level-up presenter to build title text from runtime-owned level state."
	)
	assert(
		presenter.call("build_note_text", level_up_state) == "No backpack slot.",
		"Expected level-up presenter to keep the perk note short and explicit."
	)

	var button_models: Array = presenter.call("build_offer_view_models", level_up_state, 3)
	assert(button_models.size() == 3, "Expected level-up presenter to return one model per choice button.")
	assert(
		String((button_models[0] as Dictionary).get("text", "")) == "Iron Skin\nDefense perk. Gain +2 armor.",
		"Expected first level-up offer text to expose the perk family before the numeric detail."
	)
	assert(
		String((button_models[0] as Dictionary).get("title_text", "")) == "Iron Skin",
		"Expected first level-up offer title copy to be exposed separately for card layout."
	)
	assert(
		String((button_models[0] as Dictionary).get("detail_text", "")) == "Defense perk. Gain +2 armor.",
		"Expected first level-up offer detail copy to be exposed separately for wrapped body text."
	)
	assert(
		String((button_models[0] as Dictionary).get("icon_texture_path", "")) == "res://Assets/Icons/icon_shield.svg",
		"Expected defense perks to expose the shield icon path."
	)
	assert(bool((button_models[0] as Dictionary).get("visible", false)), "Expected first level-up offer to remain visible.")
	assert(not bool((button_models[0] as Dictionary).get("disabled", true)), "Expected first level-up offer to stay enabled.")
	assert(
		String((button_models[1] as Dictionary).get("text", "")) == "Quick Step\nOffense perk. Draw faster next turn.",
		"Expected second level-up offer text to stay label-first with summary detail."
	)
	assert(
		String((button_models[1] as Dictionary).get("title_text", "")) == "Quick Step",
		"Expected second level-up offer title copy to be exposed separately."
	)
	assert(
		String((button_models[1] as Dictionary).get("detail_text", "")) == "Offense perk. Draw faster next turn.",
		"Expected second level-up offer detail copy to be exposed separately."
	)
	assert(
		String((button_models[1] as Dictionary).get("icon_texture_path", "")) == "res://Assets/Icons/icon_attack.svg",
		"Expected offense perks to expose the attack icon path."
	)
	assert(not bool((button_models[2] as Dictionary).get("visible", true)), "Expected missing level-up offers to remain hidden.")
	assert(bool((button_models[2] as Dictionary).get("disabled", false)), "Expected missing level-up offers to remain disabled.")
	assert(
		String((button_models[2] as Dictionary).get("title_text", "")).is_empty(),
		"Expected missing level-up offers to keep title copy empty."
	)
	assert(
		String((button_models[2] as Dictionary).get("detail_text", "")).is_empty(),
		"Expected missing level-up offers to keep detail copy empty."
	)
	var level_up_run_state: RunState = RunState.new()
	level_up_run_state.reset_for_new_run()
	level_up_run_state.player_hp = 28
	level_up_run_state.hunger = 9
	level_up_run_state.gold = 22
	level_up_run_state.xp = 8
	level_up_run_state.current_level = 1
	level_up_run_state.inventory_state.weapon_instance["upgrade_level"] = 1
	var level_up_status_model: Dictionary = presenter.call("build_run_status_model", level_up_run_state)
	var level_up_progress_items: Array = level_up_status_model.get("progress_items", [])
	var level_up_secondary_items: Array = level_up_status_model.get("secondary_items", [])
	assert(
		String(level_up_status_model.get("variant", "")) == "standard",
		"Expected level-up presenter to opt into the richer shared run-status variant."
	)
	assert(level_up_progress_items.size() == 1, "Expected level-up presenter to expose the XP progress row.")
	assert(
		String((level_up_progress_items[0] as Dictionary).get("value_text", "")) == "8/10",
		"Expected level-up presenter to expose current XP against the next-level threshold."
	)
	assert(
		level_up_secondary_items.size() == 1 and String((level_up_secondary_items[0] as Dictionary).get("value_text", "")).contains("Iron Sword +1"),
		"Expected level-up presenter to carry the active weapon summary into the shared status strip."
	)
	assert(
		String(level_up_status_model.get("fallback_text", "")) == "HP 28 | Hunger 9 | Gold 22 | Durability 20",
		"Expected level-up presenter to preserve the compact fallback string inside the shared run-status model."
	)
	assert(
		presenter.call("build_save_status_text", {"ok": true}) == "Run saved.",
		"Expected level-up presenter to keep the save success read stable."
	)
	assert(
		presenter.call("build_save_status_text", {"ok": false, "error": "disk full"}) == "Save failed: disk full",
		"Expected level-up presenter to keep the save failure read stable."
	)
	assert(
		presenter.call("build_load_status_text", {"ok": false, "error": "missing"}) == "Load failed: missing",
		"Expected level-up presenter to keep the load failure read stable."
	)
	assert(
		bool(presenter.call("build_load_button_disabled", false)),
		"Expected level-up presenter to keep load disabled before a save exists."
	)
	assert(
		not bool(presenter.call("build_load_button_disabled", true)),
		"Expected level-up presenter to leave load enabled after a save exists."
	)


func test_main_menu_presenter_builds_playtest_shell_text() -> void:
	var presenter: RefCounted = MainMenuPresenterScript.new()
	assert(
		presenter.call("build_title_text") == "Ashwood Descent",
		"Expected main menu presenter title to stay stable."
	)
	assert(
		presenter.call("build_mood_text") == "Survive the road. Reach the gate.",
		"Expected main menu presenter to keep the first-run guidance line."
	)
	assert(
		String(presenter.call("build_playtest_read_text", false)).contains("fresh road"),
		"Expected main menu presenter to keep the first-run call to action short and direct."
	)
	assert(
		String(presenter.call("build_status_text", true)).contains("last safe stop"),
		"Expected main menu presenter to explain save-safe resume behavior."
	)
	assert(
		String(presenter.call("build_flow_read_text")).contains("Map"),
		"Expected main menu presenter to expose a short run-flow read for first-time orientation."
	)
	assert(
		String(presenter.call("build_flow_read_text")).contains("Trail Event"),
		"Expected main menu presenter flow read to reflect the planned event-node label."
	)
	assert(
		String(presenter.call("build_flow_read_text")).contains("Roadside"),
		"Expected main menu presenter flow read to keep the travel interruption label."
	)
	assert(
		not String(presenter.call("build_flow_read_text")).contains("Shelter"),
		"Expected main menu presenter flow read to stop using the stale shelter shorthand."
	)


func test_support_interaction_presenter_builds_non_combat_view_models() -> void:
	var presenter: RefCounted = SupportInteractionPresenterScript.new()
	var support_state: RefCounted = SupportInteractionStateScript.new()
	support_state.call("setup_for_type", "merchant")
	support_state.call("mark_offer_unavailable", "buy_traveler_bread_x1")
	var loader: ContentLoader = ContentLoaderScript.new()
	var merchant_stock_definition: Dictionary = loader.load_definition("MerchantStocks", "basic_merchant_stock")
	var merchant_stock_entries: Array = merchant_stock_definition.get("rules", {}).get("stock", [])

	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 17
	run_state.hunger = 5
	run_state.gold = 9
	run_state.inventory_state.weapon_instance["current_durability"] = 4

	assert(
		presenter.call("build_chip_text", support_state) == "MERCHANT",
		"Expected support presenter to expose a player-facing merchant chip."
	)
	assert(
		presenter.call("build_title_text", support_state) == "Road Merchant",
		"Expected support presenter to keep the merchant stop more player-facing."
	)
	assert(
		String(presenter.call("build_summary_text", support_state)).contains("wagon"),
		"Expected support presenter to keep the merchant summary shorter and more player-facing."
	)
	assert(
		presenter.call("build_context_text", support_state) == "Buy what helps.",
		"Expected support presenter to keep the merchant stop context compact."
	)
	assert(
		presenter.call("build_hint_text", support_state) == "Hover for stats.",
		"Expected support presenter to keep the merchant hint short and focused on item reads."
	)
	var support_status_model: Dictionary = presenter.call("build_run_status_model", run_state)
	var support_secondary_items: Array = support_status_model.get("secondary_items", [])
	var support_progress_items: Array = support_status_model.get("progress_items", [])
	assert(
		String(support_status_model.get("variant", "")) == "compact",
		"Expected support presenter to expose the compact shared run-status variant."
	)
	assert(
		support_secondary_items.is_empty(),
		"Expected support presenter to keep the support-action status strip on the core attrition chips only."
	)
	assert(
		support_progress_items.is_empty(),
		"Expected support presenter to keep the compact support strip free of XP progress by default."
	)
	assert(
		String(support_status_model.get("fallback_text", "")) == "HP 17 | Hunger 5 | Gold 9 | Durability 4",
		"Expected support presenter to keep the compact fallback string inside the shared run-status model."
	)

	var button_models: Array = presenter.call("build_action_view_models", support_state, 3)
	assert(button_models.size() == 3, "Expected support presenter to return one model per button.")
	assert(support_state.offers.size() == merchant_stock_entries.size(), "Expected merchant runtime offers to match the authored stock entry count.")
	assert(
		String(support_state.offers[0].get("offer_id", "")) == String((merchant_stock_entries[0] as Dictionary).get("offer_id", "")),
		"Expected first merchant runtime offer to keep the authored stock order."
	)
	assert(bool((button_models[0] as Dictionary).get("visible", false)), "Expected purchased merchant offer to remain visible.")
	assert(bool((button_models[0] as Dictionary).get("disabled", false)), "Expected purchased merchant offer to render disabled.")
	assert(
		String((button_models[0] as Dictionary).get("title_text", "")).contains("Traveler Bread"),
		"Expected merchant offer labels to derive from authored item definitions."
	)
	assert(
		String((button_models[0] as Dictionary).get("text", "")).contains("Sold out"),
		"Expected unavailable merchant offers to read as sold out."
	)
	assert(bool((button_models[1] as Dictionary).get("visible", false)), "Expected second merchant offer to remain visible.")
	assert(not bool((button_models[1] as Dictionary).get("disabled", true)), "Expected available merchant offer to stay enabled.")
	assert(
		String((button_models[1] as Dictionary).get("title_text", "")).contains("Binding Resin"),
		"Expected the second merchant offer to surface the tuned repair consumable."
	)
	assert(
		String((button_models[2] as Dictionary).get("title_text", "")).contains("Watchman Shield"),
		"Expected shield offer labels to derive from the tuned tutorial merchant stock."
	)
	assert(
		String((button_models[1] as Dictionary).get("icon_texture_path", "")) == "res://Assets/Icons/icon_consumable.svg",
		"Expected merchant consumables to expose the consumable icon path."
	)
	assert(
		String((button_models[2] as Dictionary).get("icon_texture_path", "")) == "res://Assets/Icons/icon_shield.svg",
		"Expected shield merchant offers to expose the shield icon path."
	)

	var blacksmith_state: RefCounted = SupportInteractionStateScript.new()
	blacksmith_state.call("setup_for_type", "blacksmith", -1, {}, 3, run_state.inventory_state)
	var blacksmith_models: Array = presenter.call("build_action_view_models", blacksmith_state, 3)
	assert(blacksmith_models.size() == 3, "Expected blacksmith to expose three service buttons.")
	assert(
		presenter.call("build_chip_text", blacksmith_state) == "FORGE SERVICE",
		"Expected support presenter to expose the blacksmith services chip."
	)
	assert(
		String((blacksmith_models[0] as Dictionary).get("text", "")).contains("Temper Weapon"),
		"Expected blacksmith to surface the weapon tempering entry point."
	)
	assert(
		String((blacksmith_models[1] as Dictionary).get("tooltip_text", "")).contains("No valid target."),
		"Expected blacksmith to explain missing carried armor targets in tooltip copy."
	)
	assert(
		String((blacksmith_models[2] as Dictionary).get("text", "")).contains("Repair Active Weapon"),
		"Expected blacksmith to keep a direct repair service alongside gear upgrades."
	)
	assert(
		bool((blacksmith_models[1] as Dictionary).get("disabled", false)),
		"Expected missing carried armor targets to disable the reinforce action."
	)
	assert(
		String(presenter.call("build_hint_text", blacksmith_state)).contains("One service."),
		"Expected support presenter to explain blacksmith one-service resolution."
	)
	assert(
		presenter.call("build_context_text", blacksmith_state) == "Pick 1 service.",
		"Expected support presenter to explain the blacksmith service-selection context."
	)


func test_support_interaction_presenter_builds_hamlet_contract_models() -> void:
	var presenter: RefCounted = SupportInteractionPresenterScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	var side_mission_node_id: int = -1
	for node_snapshot in run_state.map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) != "hamlet":
			continue
		side_mission_node_id = int(node_snapshot.get("node_id", -1))
		break
	assert(side_mission_node_id >= 0, "Expected one hamlet node in the runtime-authored map.")

	var side_mission_state: SupportInteractionState = SupportInteractionStateScript.new()
	side_mission_state.setup_for_type("hamlet", side_mission_node_id, {
		"mission_definition_id": "trail_contract_hunt",
		"mission_status": "completed",
		"target_node_id": 1,
		"target_enemy_definition_id": "barbed_hunter",
		"reward_offers": [
			{
				"offer_id": "claim_emberhook_blade",
				"inventory_family": "weapon",
				"definition_id": "emberhook_blade",
				"available": true,
			},
			{
				"offer_id": "claim_gravehide_plates",
				"inventory_family": "armor",
				"definition_id": "gravehide_plates",
				"available": true,
			},
		],
	}, 1, run_state.inventory_state, run_state.map_runtime_state)

	assert(
		presenter.call("build_chip_text", side_mission_state) == "HAMLET",
		"Expected support presenter to expose the canonical hamlet chip."
	)
	assert(
		presenter.call("build_title_text", side_mission_state) == "Hunt Marked Brigand",
		"Expected support presenter to surface the authored hamlet request title."
	)
	assert(
		String(presenter.call("build_summary_text", side_mission_state)).contains("Pilgrim board"),
		"Expected support presenter to surface the hamlet personality summary lead."
	)
	assert(
		String(presenter.call("build_hint_text", side_mission_state)).contains("One reward."),
		"Expected support presenter to explain the completed hamlet payout rule."
	)
	var accepted_side_mission_state: SupportInteractionState = SupportInteractionStateScript.new()
	accepted_side_mission_state.setup_for_type("hamlet", side_mission_node_id, {
		"mission_definition_id": "trail_contract_hunt",
		"mission_status": "accepted",
		"target_node_id": 1,
		"target_enemy_definition_id": "barbed_hunter",
	}, 1, run_state.inventory_state, run_state.map_runtime_state)
	assert(
		presenter.call("build_context_text", accepted_side_mission_state) == "Finish the mark.",
		"Expected accepted hamlet states to keep the request-followup context compact."
	)
	assert(
		presenter.call("build_hint_text", accepted_side_mission_state) == "Back after the marked fight.",
		"Expected hamlet hint text to keep the generalized marked-objective wording."
	)
	var models: Array = presenter.call("build_action_view_models", side_mission_state, 3)
	assert(models.size() == 3, "Expected support presenter to keep hamlet rewards inside the standard 3-button layout.")
	assert(
		String((models[0] as Dictionary).get("text", "")).contains("Claim Emberhook Blade"),
		"Expected the first hamlet claim button to derive from the referenced weapon definition."
	)
	assert(
		String((models[1] as Dictionary).get("text", "")).contains("Claim Gravehide Plates"),
		"Expected the second hamlet claim button to derive from the referenced armor definition."
	)
	assert(not bool((models[0] as Dictionary).get("disabled", true)), "Expected completed hamlet claim buttons to stay enabled.")
	assert(not bool((models[1] as Dictionary).get("disabled", true)), "Expected completed hamlet claim buttons to stay enabled.")
	assert(not bool((models[2] as Dictionary).get("visible", true)), "Expected unused support buttons to stay hidden on the hamlet reward read.")


func test_support_interaction_state_roundtrips_blacksmith_target_selection_state() -> void:
	var support_state: SupportInteractionState = SupportInteractionStateScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()

	var inventory_actions: InventoryActions = InventoryActionsScript.new()
	var replace_weapon_result: Dictionary = inventory_actions.replace_active_weapon(run_state.inventory_state, "splitter_axe")
	assert(bool(replace_weapon_result.get("ok", false)), "Expected extra carried weapon setup for blacksmith serialization coverage.")

	support_state.setup_for_type("blacksmith", 5, {}, 1, run_state.inventory_state)
	support_state.open_blacksmith_target_selection(
		SupportInteractionState.BLACKSMITH_VIEW_MODE_WEAPON_TARGETS,
		run_state.inventory_state
	)

	var save_data: Dictionary = support_state.to_save_dict()
	assert(String(save_data.get("blacksmith_view_mode", "")) == SupportInteractionState.BLACKSMITH_VIEW_MODE_WEAPON_TARGETS, "Expected blacksmith save data to preserve target-selection mode.")
	assert(int(save_data.get("blacksmith_target_page", -1)) == 0, "Expected blacksmith save data to preserve the current target page.")

	var restored_state: SupportInteractionState = SupportInteractionStateScript.new()
	restored_state.load_from_save_dict(save_data)
	assert(restored_state.is_blacksmith_target_selection_active(), "Expected blacksmith restore to preserve target-selection mode.")
	assert(String(restored_state.title_text) == "Temper Weapon", "Expected blacksmith restore to preserve the target-selection title.")
	assert(restored_state.offers.size() == 1, "Expected blacksmith restore to preserve the visible carried weapon target offers on the current page.")
	assert(String(restored_state.offers[0].get("label", "")).contains("Iron Sword"), "Expected blacksmith restore to keep the carried weapon target label.")


func test_stage_transition_presenter_builds_interstitial_text() -> void:
	var presenter: RefCounted = StageTransitionPresenterScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 31
	run_state.hunger = 8
	run_state.gold = 13
	run_state.xp = 6
	run_state.current_level = 1
	run_state.inventory_state.weapon_instance["upgrade_level"] = 2
	assert(
		presenter.call("build_title_text", 3, "trade") == "Stage 3 — Trade Lanes",
		"Expected stage transition presenter to surface the incoming stage number and personality in the title."
	)
	assert(
		presenter.call("build_chip_text", 3) == "STAGE 2 CLEAR",
		"Expected stage transition presenter to expose the completed-stage chip."
	)
	assert(
		presenter.call("build_summary_text", "trade") == "Practical jobs. Utility pay.",
		"Expected stage transition presenter to build the stage-personality summary text."
	)
	assert(
		String(presenter.call("build_hint_text")).contains("Find the key") and String(presenter.call("build_hint_text")).contains("boss"),
		"Expected stage transition presenter to keep the objective line explicit on the interstitial card."
	)
	var status_model: Dictionary = presenter.call("build_run_status_model", run_state)
	var progress_items: Array = status_model.get("progress_items", [])
	var secondary_items: Array = status_model.get("secondary_items", [])
	assert(
		String(status_model.get("variant", "")) == "standard",
		"Expected stage transition presenter to opt into the richer shared run-status variant."
	)
	assert(progress_items.size() == 1, "Expected stage transition presenter to expose the XP progress row.")
	assert(
		String((progress_items[0] as Dictionary).get("value_text", "")) == "6/10",
		"Expected stage transition presenter to expose current XP against the next-level threshold."
	)
	assert(
		secondary_items.size() == 1 and String((secondary_items[0] as Dictionary).get("value_text", "")).contains("Iron Sword +2"),
		"Expected stage transition presenter to carry the active weapon summary into the shared status strip."
	)
	assert(
		String(status_model.get("fallback_text", "")) == "HP 31 | Hunger 8 | Gold 13 | Durability 20",
		"Expected stage transition presenter to preserve the compact fallback string inside the shared run-status model."
	)


func test_transition_shell_presenter_builds_node_resolve_text() -> void:
	var presenter: RefCounted = TransitionShellPresenterScript.new()
	assert(
		presenter.call("build_node_resolve_title_text", "boss") == "Opening Warden",
		"Expected node resolve title to use the node-family display name."
	)
	assert(
		String(presenter.call("build_node_resolve_summary_text", "key")).contains("Gate unlocked"),
		"Expected key resolution copy to stay aligned with runtime-owned gate truth."
	)
	assert(
		String(presenter.call("build_node_resolve_summary_text", "event")).contains("Event ahead"),
		"Expected event resolution copy to reflect the planned trail-event handoff."
	)
	assert(
		String(presenter.call("build_node_resolve_detail_text", "reward", 7)).contains("Node 7"),
		"Expected node resolve detail text to retain the pending node read."
	)
	assert(
		String(presenter.call("build_node_resolve_hint_text", "event")) == "Auto bridge.",
		"Expected node resolve hint text to reflect the planned-event handoff rather than the roadside interruption label."
	)
	assert(
		String(presenter.call("build_node_resolve_hint_text", "reward")) == "Auto bridge.",
		"Expected reward resolve hint text to keep the runtime handoff explicit."
	)
	assert(
		String(presenter.call("build_node_icon_texture_path", "combat")) == "res://Assets/Icons/icon_attack.svg",
		"Expected combat node resolve shell to reuse the attack icon."
	)
	assert(
		String(presenter.call("build_node_icon_texture_path", "event")) == "res://Assets/Icons/icon_map_trail_event.svg",
		"Expected event node resolve shell to expose the dedicated trail-event icon."
	)
	assert(
		String(presenter.call("build_node_icon_texture_path", "reward")) == "res://Assets/Icons/icon_reward.svg",
		"Expected reward node resolve shell to expose the reward icon."
	)
