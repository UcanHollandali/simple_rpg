# Layer: Tests
extends SceneTree
class_name TestRewardContent

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const LevelUpOfferWindowPolicyScript = preload("res://Game/Application/level_up_offer_window_policy.gd")


func _init() -> void:
	test_reward_state_builds_seeded_combat_victory_offers()
	test_reward_state_prefers_brigand_tone_for_stage_two_combat_rewards()
	test_reward_state_builds_seeded_reward_node_offers()
	test_reward_state_filters_reward_nodes_by_stage()
	test_level_up_offer_generation_reads_character_perk_content()
	test_level_up_offer_generation_rotates_three_offer_window_when_character_perk_pool_grows()
	print("test_reward_content: all assertions passed")
	quit()


func test_reward_state_builds_seeded_combat_victory_offers() -> void:
	var reward_state: RewardState = RewardState.new()
	reward_state.setup_for_source(
		RewardState.SOURCE_COMBAT_VICTORY,
		_build_reward_context(42, RewardState.SOURCE_COMBAT_VICTORY, 1, 1, 1)
	)

	_require(reward_state.title_text == "What You Salvage", "Expected combat-victory reward title to load from Rewards content.")
	_require(reward_state.offers.size() == 3, "Expected combat-victory reward content to expose 3 offers.")
	_require(
		_offer_ids_of(reward_state) == [
			"field_provisions_traveler_bread",
			"quick_refit_set_the_edge",
			"scavengers_find_watchman_shield",
		],
		"Expected the stage-1 combat reward window to open on the tuned tutorial food / repair / shield lane."
	)
	var mirrored_reward_state: RewardState = RewardState.new()
	mirrored_reward_state.setup_for_source(
		RewardState.SOURCE_COMBAT_VICTORY,
		_build_reward_context(42, RewardState.SOURCE_COMBAT_VICTORY, 1, 1, 1)
	)
	_require(_offer_ids_of(reward_state) == _offer_ids_of(mirrored_reward_state), "Expected same seeded combat context to reproduce the same authored reward window.")

	var second_reward_state: RewardState = RewardState.new()
	second_reward_state.setup_for_source(
		RewardState.SOURCE_COMBAT_VICTORY,
		_build_reward_context(42, RewardState.SOURCE_COMBAT_VICTORY, 1, 2, 2, 1)
	)
	_require(second_reward_state.offers.size() == 3, "Expected second seeded combat draw to keep the 3-offer reward window.")
	_require(_offer_ids_of(reward_state) != _offer_ids_of(second_reward_state), "Expected a different seeded combat context to advance to a different authored reward window.")

	var stage_three_reward_state: RewardState = RewardState.new()
	stage_three_reward_state.setup_for_source(
		RewardState.SOURCE_COMBAT_VICTORY,
		_build_reward_context(42, RewardState.SOURCE_COMBAT_VICTORY, 3, 1, 3)
	)
	var mirrored_stage_three_reward_state: RewardState = RewardState.new()
	mirrored_stage_three_reward_state.setup_for_source(
		RewardState.SOURCE_COMBAT_VICTORY,
		_build_reward_context(42, RewardState.SOURCE_COMBAT_VICTORY, 3, 1, 3)
	)
	_require(stage_three_reward_state.offers.size() == 3, "Expected later-stage seeded combat rewards to still expose 3 offers.")
	_require(_offer_ids_of(stage_three_reward_state) == _offer_ids_of(mirrored_stage_three_reward_state), "Expected later-stage seeded combat reward windows to stay deterministic for the same seed.")
	_require(
		not _offer_ids_of(reward_state).has("scavengers_find_gatebreaker_club"),
		"Expected stage-1 combat rewards not to leak stage-3 club rewards."
	)


func test_reward_state_prefers_brigand_tone_for_stage_two_combat_rewards() -> void:
	var reward_state: RewardState = RewardState.new()
	reward_state.setup_for_source(
		RewardState.SOURCE_COMBAT_VICTORY,
		_build_reward_context(71, RewardState.SOURCE_COMBAT_VICTORY, 2, 2, 2, 0, ["brigand"])
	)

	var offer_ids: Array[String] = _offer_ids_of(reward_state)
	_require(reward_state.offers.size() == 3, "Expected stage-2 combat rewards to stay capped at 3 offers.")
	_require(
		String(offer_ids[0]) == "scavengers_find_bandit_hatchet",
		"Expected brigand-tagged combat rewards to bias toward the stage-2 light-weapon lane first."
	)
	_require(
		offer_ids.has("scavengers_find_cutpurse_coin"),
		"Expected brigand-tagged combat rewards to keep a gold-toned scavenger payoff in the visible window."
	)
	_require(
		not offer_ids.has("scavengers_find_gatewall_kite_shield"),
		"Expected stage-2 brigand combat rewards not to leak stage-3 defensive gear."
	)


func test_reward_state_builds_seeded_reward_node_offers() -> void:
	var reward_state: RewardState = RewardState.new()
	reward_state.setup_for_source(
		RewardState.SOURCE_REWARD_NODE,
		_build_reward_context(99, RewardState.SOURCE_REWARD_NODE, 1, 1, 1)
	)

	_require(reward_state.title_text == "Cracked Trail Cache", "Expected reward-node title to load from Rewards content.")
	_require(reward_state.offers.size() == 2, "Expected reward-node reward content to expose 2 offers.")
	_require(String(reward_state.offers[0].get("offer_id", "")) == "field_provisions_traveler_bread", "Expected reward-node rotation to keep the early-node food offer first.")
	_require(String(reward_state.offers[1].get("offer_id", "")) == "quick_refit_binding_resin", "Expected reward-node rotation to keep the early-node repair consumable offer second.")
	_require(String(reward_state.offers[1].get("label", "")) == "Quick Refit: Binding Resin", "Expected reward-node label to reflect the tuned refit family.")

	var later_reward_state: RewardState = RewardState.new()
	later_reward_state.setup_for_source(
		RewardState.SOURCE_REWARD_NODE,
		_build_reward_context(42, RewardState.SOURCE_REWARD_NODE, 1, 3, 1, 1)
	)
	_require(later_reward_state.offers.size() == 2, "Expected later reward-node draws to stay capped at 2 offers.")
	_require(_offer_ids_of(reward_state) != _offer_ids_of(later_reward_state), "Expected later reward-node draws to advance deterministically through the authored reward stream.")

	var mirrored_reward_state: RewardState = RewardState.new()
	mirrored_reward_state.setup_for_source(
		RewardState.SOURCE_REWARD_NODE,
		_build_reward_context(42, RewardState.SOURCE_REWARD_NODE, 1, 3, 1, 1)
	)
	_require(_offer_ids_of(later_reward_state) == _offer_ids_of(mirrored_reward_state), "Expected same seed and same reward_rng draw to reproduce the same reward-node offer pair.")


func test_reward_state_filters_reward_nodes_by_stage() -> void:
	var reward_state: RewardState = RewardState.new()
	reward_state.setup_for_source(
		RewardState.SOURCE_REWARD_NODE,
		_build_reward_context(88, RewardState.SOURCE_REWARD_NODE, 3, 5, 3)
	)

	var offer_ids: Array[String] = _offer_ids_of(reward_state)
	_require(reward_state.offers.size() == 2, "Expected stage-3 reward-node windows to stay capped at 2 offers.")
	_require(
		offer_ids == [
			"quick_refit_binding_resin_stage3",
			"scavengers_find_warden_spear",
		],
		"Expected stage-3 reward nodes to surface the late-run refit and disciplined weapon lane first."
	)


func test_level_up_offer_generation_reads_character_perk_content() -> void:
	var policy: RefCounted = LevelUpOfferWindowPolicyScript.new()
	var loader: ContentLoader = ContentLoaderScript.new()
	var offer_list: Array = policy.call("build_offer_window", loader, 1)
	var expected_definition_ids: Array[String] = loader.list_definition_ids_by_authoring_order("CharacterPerks")
	_require(expected_definition_ids.size() >= 8, "Expected the authored character-perk baseline to provide enough deterministic level-up choices for the variety pass.")
	_require(offer_list.size() == 3, "Expected LevelUp to expose exactly 3 choices.")
	for index in range(offer_list.size()):
		var offer: Dictionary = offer_list[index]
		_require(
			String(offer.get("offer_id", "")) == expected_definition_ids[index],
			"Expected the first level-up window to keep the explicit authored order from CharacterPerks content."
		)


func test_level_up_offer_generation_rotates_three_offer_window_when_character_perk_pool_grows() -> void:
	var policy: RefCounted = LevelUpOfferWindowPolicyScript.new()
	var authored_offers: Array[Dictionary] = [
		{"offer_id": "alpha_perk", "label": "Alpha", "summary": "A"},
		{"offer_id": "beta_perk", "label": "Beta", "summary": "B"},
		{"offer_id": "gamma_perk", "label": "Gamma", "summary": "C"},
		{"offer_id": "delta_perk", "label": "Delta", "summary": "D"},
	]

	var level_two_window: Array = policy.call("select_offer_window", authored_offers, 2, 3)
	_require(level_two_window.size() == 3, "Expected widened perk content to still cap LevelUp at 3 choices.")
	_require(String(level_two_window[0].get("offer_id", "")) == "beta_perk", "Expected level 2 window to rotate forward by one offer.")
	_require(String(level_two_window[1].get("offer_id", "")) == "gamma_perk", "Expected level 2 window to preserve authored order after rotation.")
	_require(String(level_two_window[2].get("offer_id", "")) == "delta_perk", "Expected level 2 window to keep the next authored perk visible.")

	var level_four_window: Array = policy.call("select_offer_window", authored_offers, 4, 3)
	_require(level_four_window.size() == 3, "Expected wrapped deterministic windows to remain capped at 3 choices.")
	_require(String(level_four_window[0].get("offer_id", "")) == "delta_perk", "Expected later levels to keep rotating instead of hiding later perks forever.")
	_require(String(level_four_window[1].get("offer_id", "")) == "alpha_perk", "Expected rotation to wrap to the front of the authored list.")
	_require(String(level_four_window[2].get("offer_id", "")) == "beta_perk", "Expected wrapped windows to continue in authored order.")


func _build_reward_context(
	run_seed: int,
	source_context: String,
	stage_index: int,
	current_node_id: int,
	current_level: int,
	draw_index: int = 0,
	enemy_tags: Array[String] = []
) -> Dictionary:
	var run_state: RunState = RunState.new()
	run_state.configure_run_seed(run_seed)
	for _i in range(draw_index):
		run_state.consume_named_rng_context("reward_rng", "padding|%d" % _i)
	var rng_context: Dictionary = run_state.consume_named_rng_context(
		"reward_rng",
		"%s|stage:%d|node:%d|level:%d" % [source_context, stage_index, current_node_id, current_level]
	)
	return {
		"current_node_id": current_node_id,
		"stage_index": stage_index,
		"current_level": current_level,
		"reward_rng_seed": int(rng_context.get("stream_seed", 0)),
		"reward_rng_draw_index": int(rng_context.get("draw_index", 0)),
		"enemy_tags": enemy_tags.duplicate(),
	}


func _offer_ids_of(reward_state: RewardState) -> Array[String]:
	var offer_ids: Array[String] = []
	for offer in reward_state.offers:
		offer_ids.append(String(offer.get("offer_id", "")))
	return offer_ids


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _fail(message: String) -> void:
	push_error(message)
	print(message)
	quit(1)
