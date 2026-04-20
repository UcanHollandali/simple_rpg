# Layer: Tests
extends SceneTree
class_name TestFlowState

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const GameFlowManagerScript = preload("res://Game/Application/game_flow_manager.gd")


func _init() -> void:
	test_valid_transition_boot_to_main_menu()
	test_valid_transition_main_menu_to_map_explore()
	test_valid_transition_map_explore_to_event()
	test_valid_transition_save_safe_states_to_main_menu()
	test_invalid_transition_combat_to_map_explore()
	test_save_safe_naming_split()
	test_request_transition()
	print("test_flow_state: all assertions passed")
	quit()


func test_valid_transition_boot_to_main_menu() -> void:
	var manager = GameFlowManagerScript.new()
	manager.call("request_transition", FlowStateScript.Type.MAIN_MENU)
	assert(
		manager.call("get_current_state") == FlowStateScript.Type.MAIN_MENU,
		"Expected BOOT -> MAIN_MENU to be valid."
	)
	manager.free()


func test_invalid_transition_combat_to_map_explore() -> void:
	var manager = GameFlowManagerScript.new()
	manager.current_state = FlowStateScript.Type.COMBAT
	print("test_flow_state: expecting an invalid transition log next; COMBAT -> MAP_EXPLORE is a negative assertion, not a runtime bug.")
	manager.call("request_transition", FlowStateScript.Type.MAP_EXPLORE)
	assert(
		manager.call("get_current_state") == FlowStateScript.Type.COMBAT,
		"Expected COMBAT -> MAP_EXPLORE to be rejected."
	)
	manager.free()


func test_valid_transition_main_menu_to_map_explore() -> void:
	var manager = GameFlowManagerScript.new()
	manager.current_state = FlowStateScript.Type.MAIN_MENU
	manager.call("request_transition", FlowStateScript.Type.MAP_EXPLORE)
	assert(
		manager.call("get_current_state") == FlowStateScript.Type.MAP_EXPLORE,
		"Expected MAIN_MENU -> MAP_EXPLORE to be valid."
	)
	manager.free()


func test_valid_transition_map_explore_to_event() -> void:
	var manager = GameFlowManagerScript.new()
	manager.current_state = FlowStateScript.Type.MAP_EXPLORE
	manager.call("request_transition", FlowStateScript.Type.EVENT)
	assert(
		manager.call("get_current_state") == FlowStateScript.Type.EVENT,
		"Expected MAP_EXPLORE -> EVENT to be valid."
	)
	manager.free()


func test_valid_transition_save_safe_states_to_main_menu() -> void:
	for state in [
		FlowStateScript.Type.MAP_EXPLORE,
		FlowStateScript.Type.REWARD,
		FlowStateScript.Type.LEVEL_UP,
		FlowStateScript.Type.SUPPORT_INTERACTION,
		FlowStateScript.Type.STAGE_TRANSITION,
		FlowStateScript.Type.RUN_END,
	]:
		var manager = GameFlowManagerScript.new()
		manager.current_state = state
		manager.call("request_transition", FlowStateScript.Type.MAIN_MENU)
		assert(
			manager.call("get_current_state") == FlowStateScript.Type.MAIN_MENU,
			"Expected %s -> MAIN_MENU to be valid." % FlowStateScript.name_of(state)
		)
		manager.free()


func test_save_safe_naming_split() -> void:
	var save_service: SaveService = SaveService.new()

	for state in [
		FlowStateScript.Type.MAP_EXPLORE,
		FlowStateScript.Type.REWARD,
		FlowStateScript.Type.LEVEL_UP,
		FlowStateScript.Type.SUPPORT_INTERACTION,
		FlowStateScript.Type.STAGE_TRANSITION,
		FlowStateScript.Type.RUN_END,
	]:
		assert(FlowStateScript.is_architecturally_save_safe(state), "Expected state to be architecturally save-safe.")
		assert(FlowStateScript.is_implemented_save_safe_now(state), "Expected state to be in the implemented save-safe baseline.")
		assert(save_service.is_implemented_save_safe_now(state), "Expected SaveService baseline to match the implemented save-safe helper.")

	for state in [
		FlowStateScript.Type.BOOT,
		FlowStateScript.Type.MAIN_MENU,
		FlowStateScript.Type.NODE_RESOLVE,
		FlowStateScript.Type.COMBAT,
		FlowStateScript.Type.EVENT,
	]:
		assert(not FlowStateScript.is_architecturally_save_safe(state), "Expected state to remain architecturally non-save-safe.")
		assert(not FlowStateScript.is_implemented_save_safe_now(state), "Expected state to remain outside the implemented save-safe baseline.")
		assert(not save_service.is_implemented_save_safe_now(state), "Expected SaveService baseline to reject non-save-safe states.")


func test_request_transition() -> void:
	var manager = GameFlowManagerScript.new()
	var result: Dictionary = manager.call("request_transition", FlowStateScript.Type.MAIN_MENU)
	assert(bool(result.get("ok", false)), "Expected request_transition to be the active formal flow command surface.")
	assert(
		manager.call("get_current_state") == FlowStateScript.Type.MAIN_MENU,
		"Expected request_transition to move the flow state."
	)
	manager.free()
