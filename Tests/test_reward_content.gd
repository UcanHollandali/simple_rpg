# Layer: Tests
extends SceneTree
class_name TestRewardContent

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const LevelUpOfferWindowPolicyScript = preload("res://Game/Application/level_up_offer_window_policy.gd")


func _init() -> void:
	test_reward_state_builds_seeded_combat_victory_offers()
	test_reward_state_builds_seeded_reward_node_offers()
	test_level_up_offer_generation_reads_passive_content()
	test_level_up_offer_generation_rotates_three_offer_window_when_passive_pool_grows()
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
	_require(String(reward_state.offers[0].get("offer_id", "")) == "heal_10", "Expected same seeded run context to produce the authored heal-first combat reward window.")
	_require(String(reward_state.offers[1].get("offer_id", "")) == "gain_xp_3", "Expected seeded combat reward window to keep authored order after the seeded start index.")
	_require(String(reward_state.offers[2].get("offer_id", "")) == "repair_weapon", "Expected seeded combat reward window to keep the authored repair follow-up.")

	var second_reward_state: RewardState = RewardState.new()
	second_reward_state.setup_for_source(
		RewardState.SOURCE_COMBAT_VICTORY,
		_build_reward_context(42, RewardState.SOURCE_COMBAT_VICTORY, 1, 2, 2, 1)
	)
	_require(String(second_reward_state.offers[0].get("offer_id", "")) == "gain_xp_3", "Expected second seeded combat draw to advance through the reward stream deterministically.")
	_require(String(second_reward_state.offers[1].get("offer_id", "")) == "repair_weapon", "Expected second seeded combat draw to keep authored order after the seeded start index.")
	_require(String(second_reward_state.offers[2].get("offer_id", "")) == "gain_gold_12", "Expected second seeded combat draw to surface the next authored gold bundle.")

	var stage_three_reward_state: RewardState = RewardState.new()
	stage_three_reward_state.setup_for_source(
		RewardState.SOURCE_COMBAT_VICTORY,
		_build_reward_context(42, RewardState.SOURCE_COMBAT_VICTORY, 3, 1, 3)
	)
	_require(String(stage_three_reward_state.offers[0].get("offer_id", "")) == "heal_6", "Expected later-stage seeded combat rewards to still stay deterministic for the same seed.")
	_require(String(stage_three_reward_state.offers[1].get("offer_id", "")) == "gain_xp_5", "Expected stage-3 seeded combat reward window to keep authored order after the seeded start index.")
	_require(String(stage_three_reward_state.offers[2].get("offer_id", "")) == "repair_weapon_patch", "Expected stage-3 seeded combat reward window to continue with the authored repair patch offer.")


func test_reward_state_builds_seeded_reward_node_offers() -> void:
	var reward_state: RewardState = RewardState.new()
	reward_state.setup_for_source(
		RewardState.SOURCE_REWARD_NODE,
		_build_reward_context(99, RewardState.SOURCE_REWARD_NODE, 1, 1, 1)
	)

	_require(reward_state.title_text == "Cracked Trail Cache", "Expected reward-node title to load from Rewards content.")
	_require(reward_state.offers.size() == 2, "Expected reward-node reward content to expose 2 offers.")
	_require(String(reward_state.offers[0].get("offer_id", "")) == "heal_5", "Expected reward-node rotation to keep the early-node heal offer first.")
	_require(String(reward_state.offers[1].get("offer_id", "")) == "gain_gold_10", "Expected reward-node gold offer ID from content.")
	_require(String(reward_state.offers[1].get("label", "")) == "Unwrap the Stash", "Expected reward-node label from content.")

	var later_reward_state: RewardState = RewardState.new()
	later_reward_state.setup_for_source(
		RewardState.SOURCE_REWARD_NODE,
		_build_reward_context(42, RewardState.SOURCE_REWARD_NODE, 1, 3, 1, 1)
	)
	_require(String(later_reward_state.offers[0].get("offer_id", "")) == "heal_7", "Expected later reward-node draws to advance deterministically through the seeded reward stream.")
	_require(String(later_reward_state.offers[1].get("offer_id", "")) == "heal_5", "Expected seeded reward-node windows to preserve authored adjacency after the seeded start index.")

	var mirrored_reward_state: RewardState = RewardState.new()
	mirrored_reward_state.setup_for_source(
		RewardState.SOURCE_REWARD_NODE,
		_build_reward_context(42, RewardState.SOURCE_REWARD_NODE, 1, 3, 1, 1)
	)
	_require(_offer_ids_of(later_reward_state) == _offer_ids_of(mirrored_reward_state), "Expected same seed and same reward_rng draw to reproduce the same reward-node offer pair.")


func test_level_up_offer_generation_reads_passive_content() -> void:
	var policy: RefCounted = LevelUpOfferWindowPolicyScript.new()
	var loader: ContentLoader = ContentLoaderScript.new()
	var offer_list: Array = policy.call("build_offer_window", loader, 1)
	var expected_definition_ids: Array[String] = loader.list_definition_ids_by_authoring_order("PassiveItems")
	_require(expected_definition_ids.size() >= 5, "Expected the authored passive baseline to provide at least 5 deterministic level-up choices for the variety pass.")
	_require(offer_list.size() == 3, "Expected LevelUp to expose exactly 3 choices.")
	for index in range(offer_list.size()):
		var offer: Dictionary = offer_list[index]
		_require(
			String(offer.get("offer_id", "")) == expected_definition_ids[index],
			"Expected the first level-up window to keep the explicit authored order from PassiveItems content."
		)


func test_level_up_offer_generation_rotates_three_offer_window_when_passive_pool_grows() -> void:
	var policy: RefCounted = LevelUpOfferWindowPolicyScript.new()
	var authored_offers: Array[Dictionary] = [
		{"offer_id": "alpha_passive", "label": "Alpha", "summary": "A"},
		{"offer_id": "beta_passive", "label": "Beta", "summary": "B"},
		{"offer_id": "gamma_passive", "label": "Gamma", "summary": "C"},
		{"offer_id": "delta_passive", "label": "Delta", "summary": "D"},
	]

	var level_two_window: Array = policy.call("select_offer_window", authored_offers, 2, 3)
	_require(level_two_window.size() == 3, "Expected widened passive content to still cap LevelUp at 3 choices.")
	_require(String(level_two_window[0].get("offer_id", "")) == "beta_passive", "Expected level 2 window to rotate forward by one offer.")
	_require(String(level_two_window[1].get("offer_id", "")) == "gamma_passive", "Expected level 2 window to preserve authored order after rotation.")
	_require(String(level_two_window[2].get("offer_id", "")) == "delta_passive", "Expected level 2 window to keep the next authored passive visible.")

	var level_four_window: Array = policy.call("select_offer_window", authored_offers, 4, 3)
	_require(level_four_window.size() == 3, "Expected wrapped deterministic windows to remain capped at 3 choices.")
	_require(String(level_four_window[0].get("offer_id", "")) == "delta_passive", "Expected later levels to keep rotating instead of hiding later passives forever.")
	_require(String(level_four_window[1].get("offer_id", "")) == "alpha_passive", "Expected rotation to wrap to the front of the authored list.")
	_require(String(level_four_window[2].get("offer_id", "")) == "beta_passive", "Expected wrapped windows to continue in authored order.")


func _build_reward_context(
	run_seed: int,
	source_context: String,
	stage_index: int,
	current_node_id: int,
	current_level: int,
	draw_index: int = 0
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
