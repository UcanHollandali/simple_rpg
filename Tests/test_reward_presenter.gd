# Layer: Tests
extends SceneTree
class_name TestRewardPresenter

const RewardPresenterScript = preload("res://Game/UI/reward_presenter.gd")
const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")


func _init() -> void:
	test_reward_presenter_builds_combat_reward_cards()
	test_reward_presenter_hides_unused_small_reward_card()
	test_reward_presenter_builds_compact_run_status_strip()
	test_reward_presenter_surfaces_offer_tooltips()
	test_reward_presenter_surfaces_failure_copy()
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
		presenter.call("build_context_text", reward_state) == "Pick 1 spoil.",
		"Expected reward presenter to expose the shorter combat reward shell context."
	)
	assert(
		presenter.call("build_hint_text", reward_state) == "",
		"Expected reward presenter to hide the redundant hint line."
	)

	var models: Array = presenter.call("build_offer_view_models", reward_state, 3)
	assert(models.size() == 3, "Expected one reward view model per visible combat-reward card.")
	assert(String((models[0] as Dictionary).get("title_text", "")) == "Field Provisions: Traveler Bread", "Expected reward presenter to surface the tuned field-provisions label first.")
	assert(String((models[1] as Dictionary).get("title_text", "")) == "Quick Refit: Set the Edge Straight", "Expected reward presenter to surface the tuned refit label second.")
	assert(String((models[2] as Dictionary).get("title_text", "")) == "Scavenger's Find: Watchman Shield", "Expected reward presenter to surface the tuned tutorial shield label third.")
	assert(String((models[0] as Dictionary).get("badge_text", "")) == "Supplies", "Expected consumable reward badges to stay supply-focused.")
	assert(String((models[2] as Dictionary).get("badge_text", "")) == "Shield", "Expected shield reward badges to expose the equipped family clearly.")
	assert(String((models[0] as Dictionary).get("button_text", "")) == "Pack It", "Expected inventory reward items to use the pack CTA.")
	assert(String((models[1] as Dictionary).get("button_text", "")) == "Repair Weapon", "Expected repair rewards to expose the repair CTA.")
	assert(String((models[2] as Dictionary).get("button_text", "")) == "Pack It", "Expected shield rewards to use the pack CTA.")
	assert(String((models[0] as Dictionary).get("icon_texture_path", "")) == "res://Assets/Icons/icon_consumable.svg", "Expected consumable rewards to expose the dedicated consumable icon path.")
	assert(String((models[1] as Dictionary).get("icon_texture_path", "")) == "res://Assets/Icons/icon_weapon.svg", "Expected repair rewards to expose the weapon icon path.")
	assert(String((models[2] as Dictionary).get("icon_texture_path", "")) == "res://Assets/Icons/icon_shield.svg", "Expected shield rewards to expose the shield icon path.")


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

	var status_model: Dictionary = presenter.call("build_run_status_model", run_state)
	var secondary_items: Array = status_model.get("secondary_items", [])
	var progress_items: Array = status_model.get("progress_items", [])
	assert(
		String(status_model.get("variant", "")) == "standard",
		"Expected reward presenter to opt into the richer shared run-status variant."
	)
	assert(
		secondary_items.size() == 1 and String((secondary_items[0] as Dictionary).get("value_text", "")).contains("Iron Sword"),
		"Expected reward presenter to surface the active weapon summary alongside the shared chips."
	)
	assert(progress_items.size() == 1, "Expected reward presenter to expose the XP progress row in the shared status strip.")
	assert(
		String((progress_items[0] as Dictionary).get("label_text", "")).contains("Lv 2"),
		"Expected reward presenter to expose the next-level target in the shared XP row."
	)
	assert(
		String(status_model.get("fallback_text", "")) == "HP 41 | Hunger 12 | Gold 18 | Durability 7",
		"Expected reward presenter to keep the compact fallback string inside the shared run-status model."
	)


func test_reward_presenter_surfaces_offer_tooltips() -> void:
	var presenter: RefCounted = RewardPresenterScript.new()
	var reward_state: RefCounted = RewardStateScript.new()
	reward_state.call("setup_for_source", RewardStateScript.SOURCE_COMBAT_VICTORY, {"current_node_id": 0, "stage_index": 1})

	var models: Array = presenter.call("build_offer_view_models", reward_state, 3)
	var bread_tooltip: String = String((models[0] as Dictionary).get("tooltip_text", ""))
	var shield_tooltip: String = String((models[2] as Dictionary).get("tooltip_text", ""))
	assert(bread_tooltip.contains("Traveler Bread"), "Expected reward item tooltip to include the item name.")
	assert(bread_tooltip.contains("H +"), "Expected reward consumable tooltip to keep compact effect details.")
	assert(shield_tooltip.contains("Watchman Shield"), "Expected reward gear tooltip to include the item name.")
	assert(shield_tooltip.contains("Guard first"), "Expected reward shield tooltip to keep the gameplay-facing shield summary compact.")


func test_reward_presenter_surfaces_failure_copy() -> void:
	var presenter: RefCounted = RewardPresenterScript.new()
	assert(
		String(presenter.call("build_failure_text", "unknown_reward_option")) == "That reward is no longer available.",
		"Expected reward presenter to expose a player-facing missing-offer failure line."
	)
	assert(
		String(presenter.call("build_failure_text", "missing_reward_state")) == "Reward unavailable.",
		"Expected reward presenter to reuse the unavailable shell wording for missing reward state failures."
	)
