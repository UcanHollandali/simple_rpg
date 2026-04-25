# Layer: UI
extends RefCounted
class_name MapExplorePresenter

const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const LevelUpStateScript = preload("res://Game/RuntimeState/level_up_state.gd")
const MapDisplayNameHelperScript = preload("res://Game/UI/map_display_name_helper.gd")
const MapQuestLogModelBuilderScript = preload("res://Game/UI/map_quest_log_model_builder.gd")
const RunStatusPresenterScript = preload("res://Game/UI/run_status_presenter.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const UiFormattingScript = preload("res://Game/UI/ui_formatting.gd")
const RunSessionCoordinatorScript = preload("res://Game/Application/run_session_coordinator.gd")
const DEFAULT_ROUTE_BUTTON_COUNT: int = 6

const FAMILY_SORT_ORDER: Dictionary = {
	"start": 0,
	"combat": 1,
	"event": 2,
	"reward": 3,
	"hamlet": 4,
	"rest": 5,
	"merchant": 6,
	"blacksmith": 7,
	"key": 8,
	"boss": 9,
}
const SUPPORT_DETOUR_FAMILIES: PackedStringArray = [
	"rest",
	"merchant",
	"blacksmith",
	"hamlet",
]

func build_title_text(run_state: RunState) -> String:
	if run_state == null:
		return "Route Board"
	return "Stage %d" % run_state.stage_index


func build_stage_badge_text(run_state: RunState) -> String:
	if run_state == null:
		return "I"
	return _to_roman_stage(max(1, int(run_state.stage_index)))


func build_progress_text(run_state: RunState) -> String:
	if run_state == null:
		return ""
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var detail_parts := PackedStringArray([
		_build_compact_move_hunger_read_text(run_state),
		"%d routes" % map_runtime_state.get_discovered_adjacent_node_ids().size(),
	])
	var support_detour_read: String = _build_support_detour_read_text(map_runtime_state)
	if not support_detour_read.is_empty():
		detail_parts.append(support_detour_read.replace("Prep detour:", "Prep:"))
	detail_parts.append(_build_key_boss_commitment_read_text(map_runtime_state))
	return " | ".join(detail_parts)


func build_run_status_model(run_state: RunState) -> Dictionary:
	return RunStatusPresenterScript.build_status_model(run_state, {
		"variant": RunStatusPresenterScript.VARIANT_MINIMAL,
		"include_weapon": false,
		"include_xp": true,
		"primary_row_keys": [
			["hp", "durability"],
			["hunger", "gold"],
		],
	})


func get_level_up_threshold(run_state: RunState) -> int:
	if run_state == null:
		# Fallback: level 2 threshold (10 XP)
		return LevelUpStateScript.threshold_for_level(2)
	var next_level: int = int(run_state.current_level) + 1
	var threshold: int = LevelUpStateScript.threshold_for_level(next_level)
	if threshold < 0:
		# If next level doesn't exist, return current level's highest XP
		return 70  # Fallback to max threshold
	return threshold


func build_node_family_display_name(node_family: String, hamlet_personality: String = "") -> String:
	return _display_name_for_family(node_family, hamlet_personality)


func build_current_anchor_text(run_state: RunState) -> String:
	if run_state == null:
		return "At the trailhead"
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	return "At %s" % _display_name_for_node_id(map_runtime_state, int(map_runtime_state.current_node_id))


func build_current_anchor_detail_text(run_state: RunState) -> String:
	if run_state == null:
		return ""
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var detail_parts := PackedStringArray([
		"Node %d" % int(map_runtime_state.current_node_id),
		"Key %s" % ("taken" if map_runtime_state.is_stage_key_resolved() else "ahead"),
		"Boss %s" % ("open" if map_runtime_state.is_stage_key_resolved() else "locked"),
	])
	var side_quest_read: String = _build_side_quest_highlight_read_text(map_runtime_state)
	if not side_quest_read.is_empty():
		detail_parts.append(side_quest_read)
	detail_parts.append("%d open" % map_runtime_state.get_discovered_adjacent_node_ids().size())
	return " | ".join(detail_parts)


func build_route_overview_text(run_state: RunState) -> String:
	if run_state == null:
		return ""
	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var detail_parts := PackedStringArray()
	detail_parts.append(_build_move_hunger_read_text(run_state))
	var route_choice_read: String = _build_route_choice_read_text(map_runtime_state)
	if not route_choice_read.is_empty():
		detail_parts.append(route_choice_read)
	var support_detour_read: String = _build_support_detour_read_text(map_runtime_state)
	if not support_detour_read.is_empty():
		detail_parts.append(support_detour_read)
	detail_parts.append(_build_key_boss_commitment_read_text(map_runtime_state))
	var side_quest_read: String = _build_side_quest_highlight_read_text(map_runtime_state)
	if not side_quest_read.is_empty():
		detail_parts.append(side_quest_read)
	return " | ".join(detail_parts)


func build_inventory_pressure_text(run_state: RunState) -> String:
	if run_state == null or run_state.inventory_state == null:
		return ""
	var inventory_state: RefCounted = run_state.inventory_state
	var used_capacity: int = inventory_state.get_used_capacity()
	var total_capacity: int = inventory_state.get_total_capacity()
	var pressure_text: String = "Carry %d/%d" % [used_capacity, total_capacity]
	var weapon_summary: String = UiFormattingScript.build_weapon_summary(inventory_state.weapon_instance, true)
	if weapon_summary == "No weapon":
		return pressure_text
	return "%s | %s" % [pressure_text, weapon_summary]


func build_quest_log_model(run_state: RunState) -> Dictionary:
	return MapQuestLogModelBuilderScript.build_model(run_state)


func build_focus_panel_model(run_state: RunState, focused_node_id: int = MapRuntimeStateScript.NO_PENDING_NODE_ID) -> Dictionary:
	if run_state == null:
		return {
			"title_text": "Current Stop",
			"detail_text": "",
			"hint_text": "",
		}

	var map_runtime_state: RefCounted = run_state.map_runtime_state
	var resolved_focus_node_id: int = focused_node_id
	if resolved_focus_node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
		resolved_focus_node_id = int(map_runtime_state.current_node_id)
	var node_snapshot: Dictionary = _find_node_snapshot_by_id(map_runtime_state, resolved_focus_node_id)
	if node_snapshot.is_empty():
		return {
			"title_text": build_current_anchor_text(run_state),
			"detail_text": build_current_anchor_detail_text(run_state),
			"hint_text": build_cluster_read_text(run_state),
		}

	var is_current: bool = resolved_focus_node_id == int(map_runtime_state.current_node_id)
	var family_name: String = _display_name_for_snapshot(node_snapshot)
	var detail_parts := PackedStringArray(["Node %d" % resolved_focus_node_id])
	var state_phrase: String = _build_focus_state_phrase(run_state, node_snapshot, is_current)
	if not state_phrase.is_empty():
		detail_parts.append(state_phrase)
	var title_prefix: String = "Current Stop" if is_current else "Route Ahead"
	return {
		"title_text": "%s: %s" % [title_prefix, family_name],
		"detail_text": " | ".join(detail_parts),
		"hint_text": _build_focus_hint_text(run_state, node_snapshot, is_current),
	}


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
				seen_beyond_reach.append(_display_name_for_snapshot(node_snapshot))
			MapRuntimeStateScript.NODE_STATE_RESOLVED:
				seen_beyond_reach.append("%s spent" % _display_name_for_snapshot(node_snapshot))
			MapRuntimeStateScript.NODE_STATE_LOCKED:
				locked_labels.append(_display_name_for_snapshot(node_snapshot))

	var lines: PackedStringArray = []
	lines.append("Next: %s" % (", ".join(reachable_labels) if not reachable_labels.is_empty() else "none"))
	if not seen_beyond_reach.is_empty():
		lines.append("Ahead: %s" % ", ".join(seen_beyond_reach))
	if not locked_labels.is_empty():
		lines.append("Locked: %s" % ", ".join(locked_labels))
	return " | ".join(lines)


func build_status_log_text(status_lines: PackedStringArray, run_state: RunState = null) -> String:
	var helper_line: String = ""
	if run_state != null:
		helper_line = build_cluster_read_text(run_state)
	if status_lines.is_empty():
		return helper_line

	var last_status: String = String(status_lines[status_lines.size() - 1])
	if helper_line.is_empty():
		return "Last: %s" % last_status
	return "%s | Last: %s" % [helper_line, last_status]


func build_route_icon_texture_path(node_family: String) -> String:
	if node_family.is_empty():
		return ""
	match node_family:
		"start":
			return UiAssetPathsScript.START_ICON_TEXTURE_PATH
		"combat":
			return UiAssetPathsScript.MAP_COMBAT_ICON_TEXTURE_PATH
		"event":
			return UiAssetPathsScript.EVENT_ICON_TEXTURE_PATH
		"reward":
			return UiAssetPathsScript.REWARD_ICON_TEXTURE_PATH
		"hamlet":
			return UiAssetPathsScript.HAMLET_ICON_TEXTURE_PATH
		"rest":
			return UiAssetPathsScript.REST_ICON_TEXTURE_PATH
		"merchant":
			return UiAssetPathsScript.MERCHANT_ICON_TEXTURE_PATH
		"blacksmith":
			return UiAssetPathsScript.BLACKSMITH_ICON_TEXTURE_PATH
		"key":
			return UiAssetPathsScript.MAP_KEY_ICON_TEXTURE_PATH
		"boss":
			return UiAssetPathsScript.MAP_BOSS_ICON_TEXTURE_PATH
	if FAMILY_SORT_ORDER.has(node_family):
		return UiAssetPathsScript.ROUTE_ICON_TEXTURE_PATH
	return ""


func build_route_view_models(run_state: RunState, button_count: int = DEFAULT_ROUTE_BUTTON_COUNT) -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	var visible_nodes: Array[Dictionary] = []
	if run_state != null:
		visible_nodes = _build_visible_route_snapshots(run_state)

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
				"family_label": _display_name_for_snapshot(node_snapshot),
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


func _build_visible_route_snapshots(run_state: RunState) -> Array[Dictionary]:
	var visible_nodes: Array[Dictionary] = []
	var adjacent_nodes: Array[Dictionary] = run_state.map_runtime_state.build_adjacent_node_snapshots()
	adjacent_nodes.sort_custom(Callable(self, "_sort_adjacent_node_snapshots"))
	for node_snapshot in adjacent_nodes:
		visible_nodes.append(_with_route_visibility_meta(node_snapshot, true))
	return visible_nodes


func _with_route_visibility_meta(node_snapshot: Dictionary, is_adjacent: bool) -> Dictionary:
	var snapshot_with_meta: Dictionary = node_snapshot.duplicate(true)
	snapshot_with_meta["is_adjacent"] = is_adjacent
	return snapshot_with_meta


func _build_route_button_text(node_snapshot: Dictionary, is_adjacent: bool = true) -> String:
	var node_family: String = String(node_snapshot.get("node_family", ""))
	var node_state: String = String(node_snapshot.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
	var family_name: String = _display_name_for_snapshot(node_snapshot)

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
			if node_family == "boss":
				return "%s\nNeed Key" % family_name
			return "%s\nLocked" % family_name
		MapRuntimeStateScript.NODE_STATE_RESOLVED:
			if node_family == "start":
				return "%s\nBacktrack" % family_name
			return "%s\nCleared" % family_name
		_:
			return "%s\nOpen Route" % family_name


func _build_route_state_chip_text(node_snapshot: Dictionary, is_adjacent: bool = true) -> String:
	if not is_adjacent:
		return ""
	var node_state: String = String(node_snapshot.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
	var node_family: String = String(node_snapshot.get("node_family", ""))
	match node_state:
		MapRuntimeStateScript.NODE_STATE_LOCKED:
			if node_family == "boss":
				return "KEY"
			return "LOCK"
		MapRuntimeStateScript.NODE_STATE_RESOLVED:
			return "CLEAR"
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
	var left_weight: int = _node_sort_weight(left)
	var right_weight: int = _node_sort_weight(right)
	if left_weight == right_weight:
		return int(left.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)) < int(right.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
	return left_weight < right_weight


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


func _build_move_hunger_read_text(run_state: RunState) -> String:
	var move_cost: int = RunSessionCoordinatorScript.MAP_MOVE_HUNGER_COST
	var current_hunger: int = max(0, int(run_state.hunger))
	var next_hunger: int = max(0, current_hunger - move_cost)
	if next_hunger == 0:
		var current_hp: int = max(0, int(run_state.player_hp))
		var next_hp: int = max(0, current_hp - 1)
		return "Hunger -%d: %d->%d, HP %d->%d" % [
			move_cost,
			current_hunger,
			next_hunger,
			current_hp,
			next_hp,
		]
	return "Hunger -%d: %d->%d" % [move_cost, current_hunger, next_hunger]


func _build_compact_move_hunger_read_text(run_state: RunState) -> String:
	var move_cost: int = RunSessionCoordinatorScript.MAP_MOVE_HUNGER_COST
	var current_hunger: int = max(0, int(run_state.hunger))
	var next_hunger: int = max(0, current_hunger - move_cost)
	if next_hunger == 0:
		var current_hp: int = max(0, int(run_state.player_hp))
		var next_hp: int = max(0, current_hp - 1)
		return "Hunger -%d %d->%d HP %d->%d" % [
			move_cost,
			current_hunger,
			next_hunger,
			current_hp,
			next_hp,
		]
	return "Hunger -%d %d->%d" % [move_cost, current_hunger, next_hunger]


func _build_route_choice_read_text(map_runtime_state: RefCounted) -> String:
	if map_runtime_state == null:
		return ""
	var route_labels := PackedStringArray()
	var adjacent_nodes: Array[Dictionary] = map_runtime_state.build_adjacent_node_snapshots()
	adjacent_nodes.sort_custom(Callable(self, "_sort_adjacent_node_snapshots"))
	for node_snapshot in adjacent_nodes:
		route_labels.append(_display_name_for_snapshot(node_snapshot))
	var route_count: int = route_labels.size()
	if route_count <= 0:
		return "Routes: none"
	var visible_label_count: int = min(3, route_count)
	var visible_labels := PackedStringArray()
	for index in range(visible_label_count):
		visible_labels.append(route_labels[index])
	var overflow_count: int = route_count - visible_label_count
	var route_text: String = ", ".join(visible_labels)
	if overflow_count > 0:
		route_text = "%s +%d" % [route_text, overflow_count]
	return "Routes: %s" % route_text


func _build_support_detour_read_text(map_runtime_state: RefCounted) -> String:
	if map_runtime_state == null:
		return ""
	var adjacent_support_labels := PackedStringArray()
	for node_snapshot in map_runtime_state.build_adjacent_node_snapshots():
		var node_family: String = String(node_snapshot.get("node_family", ""))
		if not SUPPORT_DETOUR_FAMILIES.has(node_family):
			continue
		if String(node_snapshot.get("node_state", "")) == MapRuntimeStateScript.NODE_STATE_RESOLVED:
			continue
		adjacent_support_labels.append(_display_name_for_snapshot(node_snapshot))
	if not adjacent_support_labels.is_empty():
		return "Prep detour: %s" % _first_compact_label(adjacent_support_labels)

	var seen_support_labels := PackedStringArray()
	var current_node_id: int = int(map_runtime_state.current_node_id)
	var adjacent_node_ids: PackedInt32Array = map_runtime_state.get_adjacent_node_ids()
	for node_snapshot in map_runtime_state.build_node_snapshots():
		var node_id: int = int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if node_id == current_node_id or adjacent_node_ids.has(node_id):
			continue
		var node_family: String = String(node_snapshot.get("node_family", ""))
		var node_state: String = String(node_snapshot.get("node_state", ""))
		if not SUPPORT_DETOUR_FAMILIES.has(node_family):
			continue
		if node_state != MapRuntimeStateScript.NODE_STATE_DISCOVERED:
			continue
		seen_support_labels.append(_display_name_for_snapshot(node_snapshot))
	if seen_support_labels.is_empty():
		return ""
	return "Prep seen: %s" % _first_compact_label(seen_support_labels)


func _build_key_boss_commitment_read_text(map_runtime_state: RefCounted) -> String:
	if map_runtime_state == null:
		return ""
	if map_runtime_state.is_stage_key_resolved():
		return "Boss route open"
	for node_snapshot in map_runtime_state.build_adjacent_node_snapshots():
		var node_family: String = String(node_snapshot.get("node_family", ""))
		if node_family == "key":
			return "Key route open"
		if node_family == "boss" and String(node_snapshot.get("node_state", "")) == MapRuntimeStateScript.NODE_STATE_LOCKED:
			return "Boss needs key"
	return "Key ahead"


func _first_compact_label(labels: PackedStringArray) -> String:
	if labels.is_empty():
		return ""
	var first_label: String = labels[0]
	if labels.size() == 1:
		return first_label
	return "%s +%d" % [first_label, labels.size() - 1]


func _display_name_for_family(node_family: String, hamlet_personality: String = "") -> String:
	return MapDisplayNameHelperScript.build_family_display_name(node_family, hamlet_personality)


func _display_name_for_snapshot(node_snapshot: Dictionary) -> String:
	return _display_name_for_family(
		String(node_snapshot.get("node_family", "")),
		String(node_snapshot.get("hamlet_personality", ""))
	)


func _display_name_for_node_id(map_runtime_state: RefCounted, node_id: int) -> String:
	var typed_map_runtime_state: MapRuntimeState = map_runtime_state as MapRuntimeState
	if typed_map_runtime_state == null:
		return ""
	var node_snapshot: Dictionary = _find_node_snapshot_by_id(typed_map_runtime_state, node_id)
	if not node_snapshot.is_empty():
		return _display_name_for_snapshot(node_snapshot)
	var hamlet_personality: String = typed_map_runtime_state.get_hamlet_personality(node_id)
	return _display_name_for_family(String(typed_map_runtime_state.get_node_family(node_id)), hamlet_personality)


func _format_cluster_node_label(node_snapshot: Dictionary) -> String:
	var node_state: String = String(node_snapshot.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
	var family_name: String = _display_name_for_snapshot(node_snapshot)
	if node_state == MapRuntimeStateScript.NODE_STATE_RESOLVED:
		return "%s spent" % family_name
	if node_state == MapRuntimeStateScript.NODE_STATE_LOCKED:
		return "%s locked" % family_name
	return family_name


func _build_side_quest_highlight_read_text(map_runtime_state: RefCounted) -> String:
	var typed_map_runtime_state: MapRuntimeState = map_runtime_state as MapRuntimeState
	if typed_map_runtime_state == null:
		return ""
	var highlight_snapshot: Dictionary = typed_map_runtime_state.build_side_quest_highlight_snapshot()
	match String(highlight_snapshot.get("highlight_state", "")):
		"target":
			return "Marked target"
		"return":
			return "Return marked"
		_:
			return ""


func _find_node_snapshot_by_id(map_runtime_state: RefCounted, node_id: int) -> Dictionary:
	if map_runtime_state == null:
		return {}
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if int(node_snapshot.get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID)) == node_id:
			return node_snapshot
	return {}


func _build_focus_state_phrase(run_state: RunState, node_snapshot: Dictionary, is_current: bool) -> String:
	var node_state: String = String(node_snapshot.get("node_state", MapRuntimeStateScript.NODE_STATE_UNDISCOVERED))
	var node_family: String = String(node_snapshot.get("node_family", ""))
	if is_current:
		return "%d routes open" % run_state.map_runtime_state.get_discovered_adjacent_node_ids().size()
	match node_state:
		MapRuntimeStateScript.NODE_STATE_LOCKED:
			if node_family == "boss":
				return "Need key first"
			return "Locked for now"
		MapRuntimeStateScript.NODE_STATE_RESOLVED:
			return "Already cleared"
		_:
			return "Open route"


func _build_focus_hint_text(run_state: RunState, node_snapshot: Dictionary, is_current: bool) -> String:
	var node_family: String = String(node_snapshot.get("node_family", ""))
	var key_resolved: bool = bool(run_state.map_runtime_state.is_stage_key_resolved())
	match node_family:
		"combat":
			return "Fight here to move on." if not is_current else "Combat stop. Pick the next route."
		"reward":
			return "Quick pickup lane."
		"event":
			return "Planned choice event."
		"rest":
			return "Recover HP or hunger."
		"merchant":
			return "Buy supplies or repairs."
		"blacksmith":
			return "Repair or improve gear."
		"hamlet":
			return "Take or turn in a request."
		"key":
			return "Take the key first."
		"boss":
			return "Boss lane ready." if key_resolved else "Boss lane locked. Need key."
		"start":
			return "Trailhead. Re-center here."
		_:
			return ""


func _to_roman_stage(stage_index: int) -> String:
	match stage_index:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
		4:
			return "IV"
		5:
			return "V"
		_:
			return str(stage_index)
