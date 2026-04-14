# Layer: Tests
extends SceneTree
class_name TestRewardRng

const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")
const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")


func _init() -> void:
	test_same_seed_reproduces_same_reward_window()
	test_reward_rng_stream_advances_deterministically()
	test_reward_rng_stream_continues_after_save_roundtrip()
	print("test_reward_rng: all assertions passed")
	quit()


func test_same_seed_reproduces_same_reward_window() -> void:
	var first_run: RunState = RunStateScript.new()
	var second_run: RunState = RunStateScript.new()
	first_run.configure_run_seed(20260413)
	second_run.configure_run_seed(20260413)

	var first_reward_state: RewardState = RewardStateScript.new()
	first_reward_state.setup_for_source(
		RewardStateScript.SOURCE_COMBAT_VICTORY,
		_build_reward_context(first_run, RewardStateScript.SOURCE_COMBAT_VICTORY, 1, 1, 1)
	)
	var mirrored_reward_state: RewardState = RewardStateScript.new()
	mirrored_reward_state.setup_for_source(
		RewardStateScript.SOURCE_COMBAT_VICTORY,
		_build_reward_context(second_run, RewardStateScript.SOURCE_COMBAT_VICTORY, 1, 1, 1)
	)

	_require(_offer_ids_of(first_reward_state) == _offer_ids_of(mirrored_reward_state), "Expected same run seed to reproduce the same combat reward window.")


func test_reward_rng_stream_advances_deterministically() -> void:
	var first_run: RunState = RunStateScript.new()
	var second_run: RunState = RunStateScript.new()
	first_run.configure_run_seed(424242)
	second_run.configure_run_seed(424242)

	var first_reward_state: RewardState = RewardStateScript.new()
	first_reward_state.setup_for_source(
		RewardStateScript.SOURCE_REWARD_NODE,
		_build_reward_context(first_run, RewardStateScript.SOURCE_REWARD_NODE, 1, 3, 1)
	)
	var second_reward_state: RewardState = RewardStateScript.new()
	second_reward_state.setup_for_source(
		RewardStateScript.SOURCE_REWARD_NODE,
		_build_reward_context(first_run, RewardStateScript.SOURCE_REWARD_NODE, 2, 4, 2)
	)
	var mirrored_second_reward_state: RewardState = RewardStateScript.new()
	mirrored_second_reward_state.setup_for_source(
		RewardStateScript.SOURCE_REWARD_NODE,
		_build_reward_context(second_run, RewardStateScript.SOURCE_REWARD_NODE, 1, 3, 1)
	)
	var mirrored_third_reward_state: RewardState = RewardStateScript.new()
	mirrored_third_reward_state.setup_for_source(
		RewardStateScript.SOURCE_REWARD_NODE,
		_build_reward_context(second_run, RewardStateScript.SOURCE_REWARD_NODE, 2, 4, 2)
	)

	_require(_offer_ids_of(second_reward_state) == _offer_ids_of(mirrored_third_reward_state), "Expected reward_rng cursor advancement to stay deterministic across mirrored runs.")
	_require(_offer_ids_of(first_reward_state) != _offer_ids_of(second_reward_state), "Expected reward_rng cursor advancement to change the next reward window.")
	_require(_offer_ids_of(mirrored_second_reward_state) == _offer_ids_of(first_reward_state), "Expected the mirrored run to reproduce the first reward window before advancing.")


func test_reward_rng_stream_continues_after_save_roundtrip() -> void:
	var original_run: RunState = RunStateScript.new()
	original_run.configure_run_seed(9001)
	_build_reward_context(original_run, RewardStateScript.SOURCE_COMBAT_VICTORY, 1, 1, 1)
	var save_data: Dictionary = original_run.to_save_dict()
	_require(save_data.has("run_seed"), "Expected run_state save payload to persist run_seed for reward_rng continuity.")
	_require(save_data.has("rng_stream_states"), "Expected run_state save payload to persist rng_stream_states for reward_rng continuity.")

	var restored_run: RunState = RunStateScript.new()
	restored_run.load_from_save_dict(save_data)

	var original_next_context: Dictionary = _build_reward_context(original_run, RewardStateScript.SOURCE_REWARD_NODE, 2, 5, 2)
	var restored_next_context: Dictionary = _build_reward_context(restored_run, RewardStateScript.SOURCE_REWARD_NODE, 2, 5, 2)
	_require(int(original_next_context.get("reward_rng_seed", 0)) == int(restored_next_context.get("reward_rng_seed", 0)), "Expected save roundtrip to preserve reward_rng continuation for future rewards.")

	var original_reward_state: RewardState = RewardStateScript.new()
	original_reward_state.setup_for_source(RewardStateScript.SOURCE_REWARD_NODE, original_next_context)
	var restored_reward_state: RewardState = RewardStateScript.new()
	restored_reward_state.setup_for_source(RewardStateScript.SOURCE_REWARD_NODE, restored_next_context)
	_require(_offer_ids_of(original_reward_state) == _offer_ids_of(restored_reward_state), "Expected restored reward_rng stream to reproduce the same future reward offers.")


func _build_reward_context(
	run_state: RunState,
	source_context: String,
	stage_index: int,
	current_node_id: int,
	current_level: int
) -> Dictionary:
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
