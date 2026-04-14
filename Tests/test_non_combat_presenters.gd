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
	test_support_interaction_presenter_builds_side_mission_contract_models()
	test_support_interaction_state_roundtrips_blacksmith_target_selection_state()
	test_stage_transition_presenter_builds_interstitial_text()
	test_transition_shell_presenter_builds_setup_and_node_resolve_text()
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

	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 36
	run_state.hunger = 14
	run_state.gold = 9
	run_state.inventory_state.weapon_instance["current_durability"] = 7

	assert(
		presenter.call("build_chip_text") == "ROADSIDE ENCOUNTER",
		"Expected event presenter to expose the player-facing roadside encounter chip."
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
		String(presenter.call("build_hint_text")).contains("Detail text shows the exact outcome"),
		"Expected event presenter to explain the new badge-plus-detail read."
	)
	assert(
		presenter.call("build_run_status_text", run_state) == "HP 36 | Hunger 14 | Gold 9 | Durability 7",
		"Expected event presenter to summarize attrition-sensitive run state."
	)

	var models: Array = presenter.call("build_choice_view_models", event_state, 2)
	assert(models.size() == 2, "Expected event presenter to return one model per event choice.")
	assert(String((models[0] as Dictionary).get("badge_text", "")) == "Recovery", "Expected heal event choices to surface the recovery badge.")
	assert(String((models[0] as Dictionary).get("title_text", "")) == "Wash the road dust away", "Expected the first event choice title to come from content.")
	assert(String((models[0] as Dictionary).get("detail_text", "")).contains("Recover 10 HP."), "Expected event presenter to surface explicit numeric outcome text for healing choices.")
	assert(String((models[0] as Dictionary).get("button_text", "")) == "Choose Recovery", "Expected recovery choices to expose a clearer CTA.")
	assert(String((models[1] as Dictionary).get("badge_text", "")) == "Risk", "Expected harmful encounter choices to surface the risk badge.")
	assert(String((models[1] as Dictionary).get("title_text", "")) == "Turn over the offering bowl", "Expected the second event choice title to come from content.")
	assert(String((models[1] as Dictionary).get("detail_text", "")).contains("Take 4 damage."), "Expected event presenter to surface explicit numeric outcome text for harmful choices.")
	assert(String((models[1] as Dictionary).get("button_text", "")) == "Risk the Encounter", "Expected risky encounter choices to expose a clearer CTA.")


func test_level_up_presenter_builds_text_first_view_models() -> void:
	var presenter: RefCounted = LevelUpPresenterScript.new()
	var level_up_state: LevelUpState = LevelUpStateScript.new()
	level_up_state.setup_for_level("test_level_up", 2, [
		{
			"offer_id": "passive_iron_skin",
			"label": "Iron Skin",
			"summary": "Gain +2 armor.",
		},
		{
			"offer_id": "passive_quick_step",
			"label": "Quick Step",
			"summary": "Draw faster next turn.",
		},
	], true)

	assert(
		presenter.call("build_title_text", null) == "Level Up unavailable.",
		"Expected level-up presenter to keep the text-first placeholder shell title."
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
		String(presenter.call("build_note_text", level_up_state)).contains("oldest unequipped"),
		"Expected level-up presenter to warn about shared-inventory displacement when the bag is full."
	)

	var button_models: Array = presenter.call("build_offer_view_models", level_up_state, 3)
	assert(button_models.size() == 3, "Expected level-up presenter to return one model per choice button.")
	assert(
		String((button_models[0] as Dictionary).get("text", "")) == "Iron Skin\nGain +2 armor.",
		"Expected first level-up offer text to stay label-first with summary detail."
	)
	assert(
		String((button_models[0] as Dictionary).get("title_text", "")) == "Iron Skin",
		"Expected first level-up offer title copy to be exposed separately for card layout."
	)
	assert(
		String((button_models[0] as Dictionary).get("detail_text", "")) == "Gain +2 armor.",
		"Expected first level-up offer detail copy to be exposed separately for wrapped body text."
	)
	assert(bool((button_models[0] as Dictionary).get("visible", false)), "Expected first level-up offer to remain visible.")
	assert(not bool((button_models[0] as Dictionary).get("disabled", true)), "Expected first level-up offer to stay enabled.")
	assert(
		String((button_models[1] as Dictionary).get("text", "")) == "Quick Step\nDraw faster next turn.",
		"Expected second level-up offer text to stay label-first with summary detail."
	)
	assert(
		String((button_models[1] as Dictionary).get("title_text", "")) == "Quick Step",
		"Expected second level-up offer title copy to be exposed separately."
	)
	assert(
		String((button_models[1] as Dictionary).get("detail_text", "")) == "Draw faster next turn.",
		"Expected second level-up offer detail copy to be exposed separately."
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
	assert(
		presenter.call("build_initial_status_text") == "",
		"Expected level-up presenter to keep initial status text empty."
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
		presenter.call("build_title_text") == "Simple RPG",
		"Expected main menu presenter title to stay stable."
	)
	assert(
		presenter.call("build_mood_text") == "Choose a road. Survive the stops. Reach the gate.",
		"Expected main menu presenter to keep the first-run guidance line."
	)
	assert(
		String(presenter.call("build_playtest_read_text", false)).contains("first road"),
		"Expected main menu presenter to keep the first-run call to action short and direct."
	)
	assert(
		String(presenter.call("build_status_text", true)).contains("last save"),
		"Expected main menu presenter to explain save-safe resume behavior."
	)
	assert(
		String(presenter.call("build_flow_read_text")).contains("Map"),
		"Expected main menu presenter to expose a short run-flow read for first-time orientation."
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
		presenter.call("build_chip_text", support_state) == "ROAD TRADE",
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
		String(presenter.call("build_hint_text", support_state)).contains("Buy as many valid offers"),
		"Expected support presenter to explain the merchant multi-buy rule."
	)
	assert(
		presenter.call("build_run_status_text", run_state) == "HP 17 | Hunger 5 | Gold 9 | Durability 4",
		"Expected support presenter to summarize run-side non-combat state."
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
		String((button_models[0] as Dictionary).get("text", "")).contains("Traveler Bread"),
		"Expected merchant offer labels to derive from authored item definitions."
	)
	assert(
		String((button_models[0] as Dictionary).get("text", "")).contains("Gone"),
		"Expected unavailable merchant offers to read as gone."
	)
	assert(bool((button_models[1] as Dictionary).get("visible", false)), "Expected second merchant offer to remain visible.")
	assert(not bool((button_models[1] as Dictionary).get("disabled", true)), "Expected available merchant offer to stay enabled.")
	assert(
		String((button_models[1] as Dictionary).get("text", "")).contains("Quick-Clot Poultice"),
		"Expected the second merchant offer to surface the refreshed authored consumable."
	)
	assert(
		String((button_models[2] as Dictionary).get("text", "")).contains("Splitter Axe"),
		"Expected weapon offer labels to derive from the widened authored merchant weapon content."
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
		String((blacksmith_models[1] as Dictionary).get("text", "")).contains("No Target"),
		"Expected blacksmith to explain when no carried armor target exists."
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
		String(presenter.call("build_hint_text", blacksmith_state)).contains("Pick one service"),
		"Expected support presenter to explain blacksmith one-service resolution."
	)


func test_support_interaction_presenter_builds_side_mission_contract_models() -> void:
	var presenter: RefCounted = SupportInteractionPresenterScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	var side_mission_node_id: int = -1
	for node_snapshot in run_state.map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) != "side_mission":
			continue
		side_mission_node_id = int(node_snapshot.get("node_id", -1))
		break
	assert(side_mission_node_id >= 0, "Expected one side-mission node in the runtime-authored map.")

	var side_mission_state: SupportInteractionState = SupportInteractionStateScript.new()
	side_mission_state.setup_for_type("side_mission", side_mission_node_id, {
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
		presenter.call("build_chip_text", side_mission_state) == "VILLAGE REQUEST",
		"Expected support presenter to expose a dedicated contract chip."
	)
	assert(
		presenter.call("build_title_text", side_mission_state) == "Village Request",
		"Expected support presenter to surface the authored side-mission title."
	)
	assert(
		String(presenter.call("build_summary_text", side_mission_state)).contains("Choose one aid reward"),
		"Expected support presenter to surface the completed side-mission summary."
	)
	assert(
		String(presenter.call("build_hint_text", side_mission_state)).contains("Choose 1 aid reward"),
		"Expected support presenter to explain the completed contract payout rule."
	)
	var models: Array = presenter.call("build_action_view_models", side_mission_state, 3)
	assert(models.size() == 3, "Expected support presenter to keep side-mission rewards inside the standard 3-button layout.")
	assert(
		String((models[0] as Dictionary).get("text", "")).contains("Claim Emberhook Blade"),
		"Expected the first side-mission claim button to derive from the referenced weapon definition."
	)
	assert(
		String((models[1] as Dictionary).get("text", "")).contains("Claim Gravehide Plates"),
		"Expected the second side-mission claim button to derive from the referenced armor definition."
	)
	assert(not bool((models[0] as Dictionary).get("disabled", true)), "Expected completed side-mission claim buttons to stay enabled.")
	assert(not bool((models[1] as Dictionary).get("disabled", true)), "Expected completed side-mission claim buttons to stay enabled.")
	assert(not bool((models[2] as Dictionary).get("visible", true)), "Expected unused support buttons to stay hidden on the side-mission reward read.")


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
	assert(restored_state.offers.size() == 2, "Expected blacksmith restore to preserve the visible weapon target offers on the current page.")
	assert(String(restored_state.offers[0].get("label", "")).contains("Iron Sword"), "Expected blacksmith restore to keep the carried weapon target label.")


func test_stage_transition_presenter_builds_interstitial_text() -> void:
	var presenter: RefCounted = StageTransitionPresenterScript.new()
	assert(
		presenter.call("build_title_text") == "The Next Road",
		"Expected stage transition presenter title to stay stable."
	)
	assert(
		presenter.call("build_summary_text", 4) == "Stage 4 waits beyond the trees.\nStep forward when ready.\nOpen Settings if you need save or load.",
		"Expected stage transition presenter to build the interstitial summary text."
	)


func test_transition_shell_presenter_builds_setup_and_node_resolve_text() -> void:
	var presenter: RefCounted = TransitionShellPresenterScript.new()
	assert(
		presenter.call("build_run_setup_title_text") == "Setting Out",
		"Expected transition shell presenter to build the run setup title."
	)
	assert(
		presenter.call("build_run_setup_chip_text") == "FIRST ROAD",
		"Expected transition shell presenter to expose the run setup chip."
	)
	assert(
		String(presenter.call("build_run_setup_detail_text")).contains("straight to the map"),
		"Expected transition shell presenter to keep run setup as a short map handoff."
	)
	assert(
		String(presenter.call("build_run_setup_hint_text")).contains("map"),
		"Expected transition shell presenter to keep the run setup handoff explicit."
	)
	assert(
		presenter.call("build_node_resolve_title_text", "boss") == "Resolving Boss Gate",
		"Expected node resolve title to use the node-family display name."
	)
	assert(
		String(presenter.call("build_node_resolve_summary_text", "key")).contains("Boss-gate access"),
		"Expected key resolution copy to stay aligned with runtime-owned gate truth."
	)
	assert(
		String(presenter.call("build_node_resolve_summary_text", "event")).contains("two-choice roadside"),
		"Expected event resolution copy to keep the roadside handoff explicit."
	)
	assert(
		String(presenter.call("build_node_resolve_detail_text", "reward", 7)).contains("Node 7"),
		"Expected node resolve detail text to retain the pending node read."
	)
	assert(
		String(presenter.call("build_node_resolve_hint_text", "event")).contains("two-choice story flow"),
		"Expected node resolve hint text to keep the roadside handoff explicit."
	)
	assert(
		String(presenter.call("build_node_resolve_hint_text", "reward")).contains("runtime-owned screen"),
		"Expected reward resolve hint text to keep the runtime handoff explicit."
	)
	assert(
		String(presenter.call("build_node_icon_texture_path", "combat")) == "res://Assets/Icons/icon_attack.svg",
		"Expected combat node resolve shell to reuse the attack icon."
	)
	assert(
		String(presenter.call("build_node_icon_texture_path", "event")) == "res://Assets/Icons/icon_node_marker.svg",
		"Expected event node resolve shell to reuse the event marker icon floor."
	)
	assert(
		String(presenter.call("build_node_icon_texture_path", "reward")) == "res://Assets/Icons/icon_reward.svg",
		"Expected reward node resolve shell to expose the reward icon."
	)
