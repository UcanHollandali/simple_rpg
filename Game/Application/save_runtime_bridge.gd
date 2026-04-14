# Layer: Application
extends RefCounted
class_name SaveRuntimeBridge

var game_flow_manager: GameFlowManager
var run_state: RunState
var run_session_coordinator: RunSessionCoordinator
var save_service: SaveService


func setup(
	flow_manager: GameFlowManager,
	active_run_state: RunState,
	session_coordinator: RunSessionCoordinator,
	active_save_service: SaveService
) -> void:
	game_flow_manager = flow_manager
	run_state = active_run_state
	run_session_coordinator = session_coordinator
	save_service = active_save_service


func save_game(save_path: String = "") -> Dictionary:
	if game_flow_manager == null or save_service == null:
		return {"ok": false, "error": "missing_save_dependencies"}

	var active_flow_state: int = game_flow_manager.get_current_state()
	if not save_service.is_implemented_save_safe_now(active_flow_state):
		return {
			"ok": false,
			"error": "unsupported_save_state",
			"active_flow_state": active_flow_state,
		}

	var snapshot_result: Dictionary = build_save_snapshot(save_path)
	if not bool(snapshot_result.get("ok", false)):
		return snapshot_result
	return save_service.write_snapshot(save_path, snapshot_result.get("snapshot", {}))


func load_game(save_path: String = "") -> Dictionary:
	if save_service == null:
		return {"ok": false, "error": "missing_save_service"}

	var load_result: Dictionary = save_service.load_snapshot(save_path)
	if not bool(load_result.get("ok", false)):
		return load_result

	var restore_result: Dictionary = restore_from_snapshot(load_result.get("snapshot", {}))
	if not bool(restore_result.get("ok", false)):
		return restore_result

	restore_result["path"] = String(load_result.get("path", ""))
	return restore_result


func build_save_snapshot(save_path: String = "") -> Dictionary:
	if game_flow_manager == null or run_state == null or run_session_coordinator == null or save_service == null:
		return {"ok": false, "error": "missing_save_dependencies"}

	var active_flow_state: int = game_flow_manager.get_current_state()
	if not save_service.is_implemented_save_safe_now(active_flow_state):
		return {
			"ok": false,
			"error": "unsupported_save_state",
			"active_flow_state": active_flow_state,
		}

	var reward_state: RewardState = run_session_coordinator.get_reward_state()
	var level_up_state: LevelUpState = run_session_coordinator.get_level_up_state()
	var support_interaction_state: SupportInteractionState = run_session_coordinator.get_support_interaction_state()
	return {
		"ok": true,
		"snapshot": save_service.create_snapshot(
			save_path,
			active_flow_state,
			run_state.to_save_dict(),
			reward_state.to_save_dict() if reward_state != null else null,
			level_up_state.to_save_dict() if level_up_state != null else null,
			support_interaction_state.to_save_dict() if support_interaction_state != null else null,
			run_session_coordinator.get_app_state_save_data()
		),
	}


func restore_from_snapshot(snapshot: Dictionary) -> Dictionary:
	if game_flow_manager == null or run_state == null or run_session_coordinator == null or save_service == null:
		return {"ok": false, "error": "missing_save_dependencies"}

	var validation_result: Dictionary = save_service.validate_snapshot(snapshot)
	if not bool(validation_result.get("ok", false)):
		return validation_result

	var active_flow_state: int = int(snapshot.get("active_flow_state", -1))
	if not save_service.is_implemented_save_safe_now(active_flow_state):
		return {
			"ok": false,
			"error": "unsupported_save_state",
			"active_flow_state": active_flow_state,
		}

	var snapshot_run_state: Variant = snapshot.get("run_state", {})
	if typeof(snapshot_run_state) != TYPE_DICTIONARY:
		return {"ok": false, "error": "missing_run_state"}

	run_state.load_from_save_dict(snapshot_run_state)

	var session_restore_result: Dictionary = run_session_coordinator.restore_pending_states_for_snapshot(active_flow_state, snapshot)
	if not bool(session_restore_result.get("ok", false)):
		return session_restore_result

	var restore_result: Dictionary = game_flow_manager.restore_state(active_flow_state)
	if not bool(restore_result.get("ok", false)):
		return restore_result

	return {
		"ok": true,
		"active_flow_state": active_flow_state,
	}


func has_save_game(save_path: String = "") -> bool:
	return save_service != null and save_service.has_save_file(save_path)


func delete_save_game(save_path: String = "") -> Dictionary:
	if save_service == null:
		return {"ok": false, "error": "missing_save_service"}
	return save_service.delete_save_file(save_path)
