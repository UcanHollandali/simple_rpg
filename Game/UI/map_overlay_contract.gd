# Layer: UI
extends RefCounted
class_name MapOverlayContract

const FlowStateScript = preload("res://Game/Application/flow_state.gd")

const EVENT_OVERLAY_KEY := "event"
const SUPPORT_OVERLAY_KEY := "support"
const REWARD_OVERLAY_KEY := "reward"
const LEVEL_UP_OVERLAY_KEY := "level_up"

const OVERLAY_SPECS := {
	FlowStateScript.Type.EVENT: {
		"key": EVENT_OVERLAY_KEY,
		"root_name": "EventOverlay",
		"scene_name": "Event",
		"error_context": "Event",
	},
	FlowStateScript.Type.SUPPORT_INTERACTION: {
		"key": SUPPORT_OVERLAY_KEY,
		"root_name": "SupportOverlay",
		"scene_name": "SupportInteraction",
		"error_context": "Support interaction",
	},
	FlowStateScript.Type.REWARD: {
		"key": REWARD_OVERLAY_KEY,
		"root_name": "RewardOverlay",
		"scene_name": "Reward",
		"error_context": "Reward",
	},
	FlowStateScript.Type.LEVEL_UP: {
		"key": LEVEL_UP_OVERLAY_KEY,
		"root_name": "LevelUpOverlay",
		"scene_name": "LevelUp",
		"error_context": "Level up",
	},
}
const OVERLAY_FLOW_STATES: Array[int] = [
	FlowStateScript.Type.EVENT,
	FlowStateScript.Type.SUPPORT_INTERACTION,
	FlowStateScript.Type.REWARD,
	FlowStateScript.Type.LEVEL_UP,
]


static func overlay_states() -> Array[int]:
	return OVERLAY_FLOW_STATES.duplicate()


static func overlay_key(flow_state: int) -> String:
	return String(_overlay_spec(flow_state).get("key", ""))


static func overlay_root_name(flow_state: int) -> String:
	return String(_overlay_spec(flow_state).get("root_name", ""))


static func overlay_scene_name(flow_state: int) -> String:
	return String(_overlay_spec(flow_state).get("scene_name", ""))


static func overlay_error_context(flow_state: int) -> String:
	return String(_overlay_spec(flow_state).get("error_context", "Overlay"))


static func overlay_root_names() -> PackedStringArray:
	var root_names := PackedStringArray()
	for overlay_state in OVERLAY_FLOW_STATES:
		root_names.append(overlay_root_name(overlay_state))
	return root_names


static func overlay_state_from_scene_name(scene_name: String) -> int:
	for overlay_state in OVERLAY_FLOW_STATES:
		if overlay_scene_name(overlay_state) == scene_name:
			return overlay_state
	return -1


static func _overlay_spec(flow_state: int) -> Dictionary:
	return OVERLAY_SPECS.get(flow_state, {})
