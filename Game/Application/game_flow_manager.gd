# Layer: Application
extends Node
class_name GameFlowManager

const FlowStateScript = preload("res://Game/Application/flow_state.gd")

signal flow_state_changed(old_state: int, new_state: int)

var transitions: Dictionary = {
	FlowStateScript.Type.BOOT: PackedInt32Array([FlowStateScript.Type.MAIN_MENU]),
	FlowStateScript.Type.MAIN_MENU: PackedInt32Array([FlowStateScript.Type.RUN_SETUP]),
	FlowStateScript.Type.RUN_SETUP: PackedInt32Array([FlowStateScript.Type.MAP_EXPLORE]),
	FlowStateScript.Type.MAP_EXPLORE: PackedInt32Array([
		FlowStateScript.Type.NODE_RESOLVE,
		FlowStateScript.Type.SUPPORT_INTERACTION,
		FlowStateScript.Type.COMBAT,
		FlowStateScript.Type.RUN_END,
	]),
	FlowStateScript.Type.NODE_RESOLVE: PackedInt32Array([
		FlowStateScript.Type.COMBAT,
		FlowStateScript.Type.EVENT,
		FlowStateScript.Type.REWARD,
		FlowStateScript.Type.LEVEL_UP,
		FlowStateScript.Type.SUPPORT_INTERACTION,
		FlowStateScript.Type.STAGE_TRANSITION,
		FlowStateScript.Type.MAP_EXPLORE,
		FlowStateScript.Type.RUN_END,
	]),
	FlowStateScript.Type.EVENT: PackedInt32Array([FlowStateScript.Type.LEVEL_UP, FlowStateScript.Type.MAP_EXPLORE, FlowStateScript.Type.RUN_END]),
	FlowStateScript.Type.COMBAT: PackedInt32Array([FlowStateScript.Type.REWARD, FlowStateScript.Type.STAGE_TRANSITION, FlowStateScript.Type.RUN_END]),
	FlowStateScript.Type.REWARD: PackedInt32Array([FlowStateScript.Type.LEVEL_UP, FlowStateScript.Type.MAP_EXPLORE, FlowStateScript.Type.RUN_END]),
	FlowStateScript.Type.LEVEL_UP: PackedInt32Array([FlowStateScript.Type.MAP_EXPLORE]),
	FlowStateScript.Type.SUPPORT_INTERACTION: PackedInt32Array([FlowStateScript.Type.MAP_EXPLORE]),
	FlowStateScript.Type.STAGE_TRANSITION: PackedInt32Array([FlowStateScript.Type.MAP_EXPLORE, FlowStateScript.Type.RUN_END]),
	FlowStateScript.Type.RUN_END: PackedInt32Array([FlowStateScript.Type.MAIN_MENU, FlowStateScript.Type.RUN_SETUP]),
}

var current_state: int = FlowStateScript.Type.BOOT


# Deprecated compatibility shim for older call sites only.
# Current repo truth: there are no in-repo runtime callers that should be using this path.
# New flow work should call request_transition() directly instead of widening this surface.
func dispatch(command: Dictionary) -> Dictionary:
	var command_type: String = String(command.get("type", ""))

	match command_type:
		"request_transition":
			if not command.has("target_state"):
				push_error("GameFlowManager.dispatch missing 'target_state' for request_transition.")
				return {
					"ok": false,
					"error": "missing_target_state",
				}
			# Deprecated compatibility shim only. request_transition() is the active formal surface.
			return request_transition(int(command.get("target_state", current_state)))
		_:
			push_error("Unknown deprecated GameFlowManager.dispatch command type: %s" % command_type)
			return {
				"ok": false,
				"error": "unknown_command_type",
				"command_type": command_type,
			}


func request_transition(new_state: int) -> Dictionary:
	if not _is_valid_transition(current_state, new_state):
		push_error(
			"Invalid flow transition: %s -> %s"
			% [FlowStateScript.name_of(current_state), FlowStateScript.name_of(new_state)]
		)
		return {
			"ok": false,
			"error": "invalid_transition",
			"old_state": current_state,
			"new_state": new_state,
		}

	var old_state: int = current_state
	current_state = new_state
	emit_signal("flow_state_changed", old_state, current_state)
	return {
		"ok": true,
		"old_state": old_state,
		"new_state": current_state,
	}


func transition_to(new_state: int) -> void:
	request_transition(new_state)


func get_current_state() -> int:
	return current_state


func restore_state(restored_state: int) -> Dictionary:
	if not FlowStateScript.is_implemented_save_safe_now(restored_state):
		push_error("Invalid restore flow state: %s" % FlowStateScript.name_of(restored_state))
		return {
			"ok": false,
			"error": "invalid_restore_state",
			"restored_state": restored_state,
		}

	var old_state: int = current_state
	current_state = restored_state
	return {
		"ok": true,
		"old_state": old_state,
		"new_state": current_state,
		"changed": old_state != current_state,
	}


func _is_valid_transition(old_state: int, new_state: int) -> bool:
	var allowed: PackedInt32Array = transitions.get(old_state, PackedInt32Array())
	return allowed.has(new_state)
