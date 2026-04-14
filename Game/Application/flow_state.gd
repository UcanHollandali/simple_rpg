# Layer: Application
extends RefCounted
class_name FlowState

enum Type {
	BOOT,
	MAIN_MENU,
	RUN_SETUP,
	MAP_EXPLORE,
	NODE_RESOLVE,
	COMBAT,
	EVENT,
	REWARD,
	LEVEL_UP,
	SUPPORT_INTERACTION,
	STAGE_TRANSITION,
	RUN_END,
}


static func is_architecturally_save_safe(state: int) -> bool:
	match state:
		Type.MAP_EXPLORE, Type.REWARD, Type.LEVEL_UP, Type.SUPPORT_INTERACTION, Type.STAGE_TRANSITION, Type.RUN_END:
			return true
		_:
			return false


static func is_implemented_save_safe_now(state: int) -> bool:
	# Current baseline intentionally matches the architectural safe-state set.
	return is_architecturally_save_safe(state)


static func is_save_safe(state: int) -> bool:
	# Compatibility alias for older code/tests. Prefer the explicit helpers above.
	return is_implemented_save_safe_now(state)


static func name_of(state: int) -> String:
	match state:
		Type.BOOT:
			return "BOOT"
		Type.MAIN_MENU:
			return "MAIN_MENU"
		Type.RUN_SETUP:
			return "RUN_SETUP"
		Type.MAP_EXPLORE:
			return "MAP_EXPLORE"
		Type.NODE_RESOLVE:
			return "NODE_RESOLVE"
		Type.COMBAT:
			return "COMBAT"
		Type.EVENT:
			return "EVENT"
		Type.REWARD:
			return "REWARD"
		Type.LEVEL_UP:
			return "LEVEL_UP"
		Type.SUPPORT_INTERACTION:
			return "SUPPORT_INTERACTION"
		Type.STAGE_TRANSITION:
			return "STAGE_TRANSITION"
		Type.RUN_END:
			return "RUN_END"
		_:
			return "UNKNOWN"
