# Layer: UI
extends RefCounted
class_name MapExplorePresenter

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const DEFAULT_ROUTE_BUTTON_COUNT: int = 6
const DEFAULT_FOG_PREVIEW_COUNT: int = 3

const FAMILY_DISPLAY_NAMES: Dictionary = {
	"start": "Start",
	"combat": "Combat",
	"event": "Event",
	"reward": "Reward",
	"rest": "Rest",
	"merchant": "Merchant",
	"blacksmith": "Blacksmith",
	"key": "Key",
	"boss": "Boss Gate",
}

const FAMILY_SORT_ORDER: Dictionary = {
	"start": 0,
	"combat": 1,
	"event": 2,
	"reward": 3,
	"rest": 4,
	"merchant": 5,
	"blacksmith": 6,
	"key": 7,
	"boss": 8,
}

var _loader: ContentLoader = ContentLoaderScript.new()


func build_title_text(run_state: RunState) -> String:
	if run_state == null:
		return "Route Board"
	return "Stage %d Route" % run_state.stage_index


func build_progress_text(run_state: RunState) -> String:
	if run_state == null:
		return ""
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	return "Node %d | Seen %d/%d | Cleared %d" % [
		map_runtime_state.current_node_id,
		map_runtime_state.get_discovered_node_count(),
		map_runtime_state.get_node_count(),
		map_runtime_state.get_resolved_node_count(),
	]


func build_run_status_text(run_state: RunState) -> String:
	if run_state == null:
		return ""

	var weapon_name: String = _build_weapon_display_name(run_state.weapon_instance)
	return "HP %d | Hunger %d | Gold %d | %s (%d)" % [
		run_state.player_hp,
		run_state.hunger,
		run_state.gold,
		weapon_name,
		int(run_state.weapon_instance.get("current_durability", 0)),
	]


func build_node_family_text() -> String:
	return "Families: start, combat, event, reward, rest, merchant, blacksmith, key, boss"


func build_map_shell_note_text() -> String:
	return "Bounded cluster shell. Move only to adjacent revealed nodes while key, gate, and revisit truth stay runtime-owned."


func build_state_legend_text() -> String:
	return "State read: OPEN ready | SPENT traversable | LOCKED gate"


func build_key_legend_text() -> String:
	return "Key marker updates from runtime truth."


func build_boss_gate_legend_text() -> String:
	return "Boss gate stays locked until the key is claimed."


func build_current_anchor_chip_text() -> String:
	return "YOU ARE HERE"


func build_node_family_display_name(node_family: String) -> String:
	return _display_name_for_family(node_family)


func build_current_anchor_text(run_state: RunState) -> String:
	if run_state == null:
		return "Center-start graph"
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	return "%s\nNode %d" % [
		_display_name_for_family(map_runtime_state.get_current_node_family()),
		map_runtime_state.current_node_id,
	]


func build_current_anchor_detail_text(run_state: RunState) -> String:
	if run_state == null:
		return ""
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	return "Cleared: %s | Key: %s | Reachable: %d" % [
		"yes" if map_runtime_state.is_node_resolved(map_runtime_state.current_node_id) else "no",
		"yes" if map_runtime_state.is_stage_key_resolved() else "no",
		map_runtime_state.get_discovered_adjacent_node_ids().size(),
	]


func build_cluster_read_text(run_state: RunState) -> String:
	if run_state == null:
		return ""

	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var adjacent_node_ids: PackedInt32Array = map_runtime_state.get_adjacent_node_ids()
	var reachable_labels: PackedStringArray = []
	for node_snapshot in map_runtime_state.build_adjacent_node_snapshots():
		reachable_labels.append(_format_cluster_node_label(node_snapshot))

	var seen_beyond_reach: PackedStringArray = []
	var locked_labels: PackedStringArray = []
	for node_snapshot in map_runtime_state.build_node_snapshots():
		var node_id: int = int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if node_id == map_runtime_state.current_node_id or adjacent_node_ids.has(node_id):
			continue

		var node_state: String = String(node_snapshot.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
		match node_state:
			MapRuntimeStateScript.NODE_STATE_DISCOVERED:
				seen_beyond_reach.append(_display_name_for_family(String(node_snapshot.get("node_family", ""))))
			MapRuntimeStateScript.NODE_STATE_RESOLVED:
				seen_beyond_reach.append("%s spent" % _display_name_for_family(String(node_snapshot.get("node_family", ""))))
			MapRuntimeStateScript.NODE_STATE_LOCKED:
				locked_labels.append(_display_name_for_family(String(node_snapshot.get("node_family", ""))))

	return "Reachable: %s\nSeen ahead: %s\nLocked: %s" % [
		", ".join(reachable_labels) if not reachable_labels.is_empty() else "none yet",
		", ".join(seen_beyond_reach) if not seen_beyond_reach.is_empty() else "none yet",
		", ".join(locked_labels) if not locked_labels.is_empty() else "none visible",
	]


func build_fog_preview_texts(run_state: RunState, preview_count: int = DEFAULT_FOG_PREVIEW_COUNT) -> PackedStringArray:
	var preview_texts: PackedStringArray = []
	for index in range(preview_count):
		preview_texts.append("")
	return preview_texts


func build_key_marker_text(run_state: RunState) -> String:
	if run_state != null and run_state.map_runtime_state.is_stage_key_resolved():
		return "KEY\nTAKEN"
	return "KEY\nAHEAD"


func build_status_log_text(status_lines: PackedStringArray) -> String:
	return "\n".join(status_lines)


func build_route_icon_texture_path(node_family: String) -> String:
	if node_family.is_empty():
		return ""
	match node_family:
		"start":
			return UiAssetPathsScript.START_ICON_TEXTURE_PATH
		"combat":
			return UiAssetPathsScript.ATTACK_ICON_TEXTURE_PATH
		"event":
			return UiAssetPathsScript.EVENT_ICON_TEXTURE_PATH
		"reward":
			return UiAssetPathsScript.REWARD_ICON_TEXTURE_PATH
		"rest":
			return UiAssetPathsScript.REST_ICON_TEXTURE_PATH
		"merchant":
			return UiAssetPathsScript.MERCHANT_ICON_TEXTURE_PATH
		"blacksmith":
			return UiAssetPathsScript.BLACKSMITH_ICON_TEXTURE_PATH
		"key":
			return UiAssetPathsScript.KEY_ICON_TEXTURE_PATH
		"boss":
			return UiAssetPathsScript.BOSS_ICON_TEXTURE_PATH
	if FAMILY_DISPLAY_NAMES.has(node_family):
		return UiAssetPathsScript.ROUTE_ICON_TEXTURE_PATH
	return ""


func build_route_view_models(run_state: RunState, button_count: int = DEFAULT_ROUTE_BUTTON_COUNT) -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	var visible_nodes: Array[Dictionary] = []
	if run_state != null:
		visible_nodes = _build_visible_route_snapshots(run_state, button_count)

	for index in range(button_count):
		if index < visible_nodes.size():
			var node_snapshot: Dictionary = visible_nodes[index]
			var node_state: String = String(node_snapshot.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
			var node_family: String = String(node_snapshot.get("node_family", ""))
			var is_adjacent: bool = bool(node_snapshot.get("is_adjacent", true))
			models.append({
				"visible": true,
				"disabled": node_state == MapRuntimeStateScript.NODE_STATE_LOCKED or not is_adjacent,
				"node_id": int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)),
				"node_family": node_family,
				"family_label": _display_name_for_family(node_family),
				"state_chip_text": _build_route_state_chip_text(node_snapshot, is_adjacent),
				"state_semantic": _build_route_state_semantic(node_snapshot),
				"show_road": is_adjacent,
				"icon_texture_path": build_route_icon_texture_path(node_family),
				"text": _build_route_button_text(node_snapshot, is_adjacent),
			})
		else:
			models.append({
				"visible": false,
				"disabled": true,
				"node_id": MapRuntimeStateScript.NO_PENDING_NODE_ID,
				"node_family": "",
				"family_label": "",
				"state_chip_text": "",
				"state_semantic": "",
				"icon_texture_path": "",
				"text": "",
			})

	return models


func _build_visible_route_snapshots(run_state: RunState, button_count: int) -> Array[Dictionary]:
	var visible_nodes: Array[Dictionary] = []
	var adjacent_nodes: Array[Dictionary] = run_state.map_runtime_state.build_adjacent_node_snapshots()
	adjacent_nodes.sort_custom(Callable(self, "_sort_adjacent_node_snapshots"))
	for node_snapshot in adjacent_nodes:
		visible_nodes.append(_with_route_visibility_meta(node_snapshot, true))

	if visible_nodes.size() >= button_count:
		return visible_nodes

	var discovered_nodes: Array[Dictionary] = _build_discovered_context_snapshots(run_state)
	discovered_nodes.sort_custom(Callable(self, "_sort_adjacent_node_snapshots"))
	for node_snapshot in discovered_nodes:
		if visible_nodes.size() >= button_count:
			break
		visible_nodes.append(_with_route_visibility_meta(node_snapshot, false))
	return visible_nodes


func _build_discovered_context_snapshots(run_state: RunState) -> Array[Dictionary]:
	var context_nodes: Array[Dictionary] = []
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var adjacent_node_ids: PackedInt32Array = map_runtime_state.get_adjacent_node_ids()
	for node_snapshot in map_runtime_state.build_node_snapshots():
		var node_id: int = int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if node_id == map_runtime_state.current_node_id or adjacent_node_ids.has(node_id):
			continue
		var node_state: String = String(node_snapshot.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
		if node_state == MapRuntimeStateScript.NODE_STATE_UNDISCOVERED:
			continue
		context_nodes.append(node_snapshot)
	return context_nodes


func _with_route_visibility_meta(node_snapshot: Dictionary, is_adjacent: bool) -> Dictionary:
	var snapshot_with_meta: Dictionary = node_snapshot.duplicate(true)
	snapshot_with_meta["is_adjacent"] = is_adjacent
	return snapshot_with_meta


func _build_route_button_text(node_snapshot: Dictionary, is_adjacent: bool = true) -> String:
	var node_family: String = String(node_snapshot.get("node_family", ""))
	var node_state: String = String(node_snapshot.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
	var family_name: String = _display_name_for_family(node_family)

	if not is_adjacent:
		match node_state:
			MapRuntimeStateScript.NODE_STATE_LOCKED:
				return "%s\nSeen Lock" % family_name
			MapRuntimeStateScript.NODE_STATE_RESOLVED:
				return "%s\nSeen Path" % family_name
			_:
				return "%s\nSeen" % family_name

	match node_state:
		MapRuntimeStateScript.NODE_STATE_LOCKED:
			return "%s\nLocked" % family_name
		MapRuntimeStateScript.NODE_STATE_RESOLVED:
			if node_family == "start":
				return "%s\nSpent Path" % family_name
			return "%s\nSpent" % family_name
		_:
			return "%s\nReachable" % family_name


func _build_route_state_chip_text(node_snapshot: Dictionary, is_adjacent: bool = true) -> String:
	if not is_adjacent:
		return ""
	var node_state: String = String(node_snapshot.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
	match node_state:
		MapRuntimeStateScript.NODE_STATE_LOCKED:
			return "LOCK"
		MapRuntimeStateScript.NODE_STATE_RESOLVED:
			return "SPENT"
		_:
			return "OPEN"


func _build_route_state_semantic(node_snapshot: Dictionary) -> String:
	var node_state: String = String(node_snapshot.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
	match node_state:
		MapRuntimeStateScript.NODE_STATE_LOCKED:
			return "locked"
		MapRuntimeStateScript.NODE_STATE_RESOLVED:
			return "resolved"
		_:
			return "open"


func _sort_adjacent_node_snapshots(left: Dictionary, right: Dictionary) -> bool:
	return _node_sort_weight(left) < _node_sort_weight(right)


func _node_sort_weight(node_snapshot: Dictionary) -> int:
	var node_state: String = String(node_snapshot.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
	var node_family: String = String(node_snapshot.get("node_family", ""))
	var state_weight: int = 0
	match node_state:
		MapRuntimeStateScript.NODE_STATE_DISCOVERED:
			state_weight = 0
		MapRuntimeStateScript.NODE_STATE_RESOLVED:
			state_weight = 100
		MapRuntimeStateScript.NODE_STATE_LOCKED:
			state_weight = 200
		_:
			state_weight = 300
	return state_weight + int(FAMILY_SORT_ORDER.get(node_family, 999))


func _display_name_for_family(node_family: String) -> String:
	return String(FAMILY_DISPLAY_NAMES.get(node_family, node_family.capitalize()))


func _build_weapon_display_name(weapon_instance: Dictionary) -> String:
	var definition_id: String = String(weapon_instance.get("definition_id", "none"))
	if definition_id.is_empty() or definition_id == "none":
		return "None"

	var weapon_definition: Dictionary = _loader.load_definition("Weapons", definition_id)
	var display: Dictionary = weapon_definition.get("display", {})
	return String(display.get("name", definition_id))


func _format_cluster_node_label(node_snapshot: Dictionary) -> String:
	var node_family: String = String(node_snapshot.get("node_family", ""))
	var node_state: String = String(node_snapshot.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
	var family_name: String = _display_name_for_family(node_family)
	if node_state == MapRuntimeStateScript.NODE_STATE_RESOLVED:
		return "%s spent" % family_name
	if node_state == MapRuntimeStateScript.NODE_STATE_LOCKED:
		return "%s locked" % family_name
	return family_name
