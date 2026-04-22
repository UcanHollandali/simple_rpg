# Layer: Application
extends RefCounted
class_name OverlayFlowContract

const FlowStateScript = preload("res://Game/Application/flow_state.gd")

const OPEN_OVERLAY_FOR_STATE_METHOD := "open_overlay_for_state"
const CLOSE_OVERLAY_FOR_STATE_METHOD := "close_overlay_for_state"
const CLOSE_ALL_OVERLAYS_METHOD := "close_all_overlays"

const OVERLAY_FLOW_STATES: Array[int] = [
	FlowStateScript.Type.EVENT,
	FlowStateScript.Type.SUPPORT_INTERACTION,
	FlowStateScript.Type.REWARD,
	FlowStateScript.Type.LEVEL_UP,
]


static func is_overlay_state(state: int) -> bool:
	return state in OVERLAY_FLOW_STATES
