# Layer: Tests
extends SceneTree
class_name TestRewardPresenter

const RewardPresenterScript = preload("res://Game/UI/reward_presenter.gd")
const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")


func _init() -> void:
	test_reward_presenter_builds_combat_reward_cards()
	test_reward_presenter_hides_unused_small_reward_card()
	test_reward_presenter_builds_compact_run_status_strip()
	print("test_reward_presenter: all assertions passed")
	quit()


func test_reward_presenter_builds_combat_reward_cards() -> void:
	var presenter: RefCounted = RewardPresenterScript.new()
	var reward_state: RefCounted = RewardStateScript.new()
	reward_state.call("setup_for_source", RewardStateScript.SOURCE_COMBAT_VICTORY, {"current_node_id": 0, "stage_index": 1})

	assert(
		presenter.call("build_chip_text", reward_state) == "COMBAT SPOILS",
		"Expected reward presenter to expose the combat-spoils chip."
	)
	assert(
		presenter.call("build_title_text", reward_state) == "What You Salvage",
		"Expected reward presenter to use runtime-backed title text."
	)
	assert(
		presenter.call("build_context_text", reward_state) == "Take 1 of 3 spoils before you move.",
		"Expected reward presenter to expose the combat reward shell context."
	)
	assert(
		presenter.call("build_hint_text", reward_state) == "Choose one payoff. The rest is left behind on the road.",
		"Expected reward presenter to explain the one-claim salvage rule."
	)

	var models: Array = presenter.call("build_offer_view_models", reward_state, 3)
	assert(models.size() == 3, "Expected one reward view model per visible combat-reward card.")
	assert(String((models[0] as Dictionary).get("title_text", "")) == "Strip the Purse", "Expected reward presenter to prefer authored salvage labels for combat rewards.")
	assert(String((models[1] as Dictionary).get("title_text", "")) == "Bind the Cut", "Expected reward presenter to prefer authored salvage labels for healing rewards.")
	assert(String((models[2] as Dictionary).get("title_text", "")) == "Read the Opening", "Expected reward presenter to prefer authored salvage labels for XP rewards.")
	assert(String((models[0] as Dictionary).get("button_text", "")) == "Take Gold", "Expected gold rewards to expose a clearer CTA.")
	assert(String((models[1] as Dictionary).get("button_text", "")) == "Recover HP", "Expected healing rewards to expose a clearer CTA.")
	assert(String((models[2] as Dictionary).get("button_text", "")) == "Take XP", "Expected XP rewards to expose a clearer CTA.")


func test_reward_presenter_hides_unused_small_reward_card() -> void:
	var presenter: RefCounted = RewardPresenterScript.new()
	var reward_state: RefCounted = RewardStateScript.new()
	reward_state.call("setup_for_source", RewardStateScript.SOURCE_REWARD_NODE, {"current_node_id": 0, "stage_index": 1})
	assert(
		presenter.call("build_chip_text", reward_state) == "CACHE FIND",
		"Expected reward-node shells to expose the cache-find chip."
	)

	var models: Array = presenter.call("build_offer_view_models", reward_state, 3)
	assert(models.size() == 3, "Expected fixed card-model count for reward placeholder layout.")
	assert(bool((models[0] as Dictionary).get("visible", false)), "Expected first reward-node card to stay visible.")
	assert(bool((models[1] as Dictionary).get("visible", false)), "Expected second reward-node card to stay visible.")
	assert(not bool((models[2] as Dictionary).get("visible", true)), "Expected third reward-node card to stay hidden.")


func test_reward_presenter_builds_compact_run_status_strip() -> void:
	var presenter: RefCounted = RewardPresenterScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 41
	run_state.hunger = 12
	run_state.gold = 18
	run_state.inventory_state.weapon_instance["current_durability"] = 7

	assert(
		presenter.call("build_run_status_text", run_state) == "HP 41 | Hunger 12 | Gold 18 | Durability 7",
		"Expected reward presenter to keep the reward shell as a compact attrition-aware run-state strip."
	)
