# Layer: Tools
extends SceneTree

const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")
const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const MapBoardComposerV2Script = preload("res://Game/UI/map_board_composer_v2.gd")
const MapBoardCanvasScript = preload("res://Game/UI/map_board_canvas.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")

const DEFAULT_OUTPUT_DIR := "res://Docs/ProductionAssetBriefs"
const DEFAULT_SNAPSHOT_DATE := "2026-04-25"
const DEFAULT_BOARD_SIZE := Vector2(920.0, 1180.0)
const DEFAULT_FOCUS_ANCHOR := Vector2(0.5, 0.58)
const DEFAULT_MAX_FOCUS_OFFSET := Vector2(148.0, 212.0)
const DEFAULT_SEEDS: Array[int] = [11, 29, 41, 73, 97]
const DEFAULT_STAGES: Array[int] = [1, 2, 3]
const DEFAULT_PROGRESS_STEPS: Array[int] = [0, 3, 6]
const REQUIRED_RUNTIME_NODE_FAMILIES: Array[String] = [
	"start",
	"combat",
	"event",
	"reward",
	"hamlet",
	"rest",
	"merchant",
	"blacksmith",
	"key",
	"boss",
]
const SOURCE_FILES: Array[String] = [
	"Game/RuntimeState/run_state.gd",
	"Game/RuntimeState/map_runtime_state.gd",
	"Game/UI/map_board_composer_v2.gd",
	"Game/UI/map_board_render_model_masks_slots.gd",
	"Game/UI/map_board_canvas.gd",
	"Game/UI/ui_asset_paths.gd",
]

var _output_dir := DEFAULT_OUTPUT_DIR
var _snapshot_date := DEFAULT_SNAPSHOT_DATE
var _seeds: Array[int] = DEFAULT_SEEDS.duplicate()
var _stages: Array[int] = DEFAULT_STAGES.duplicate()
var _progress_steps: Array[int] = DEFAULT_PROGRESS_STEPS.duplicate()


func _init() -> void:
	var parse_error: String = _parse_args(OS.get_cmdline_user_args())
	if not parse_error.is_empty():
		push_error(parse_error)
		quit(1)
		return

	var export_result: Dictionary = _build_export()
	var write_error: String = _write_export(export_result)
	if not write_error.is_empty():
		push_error(write_error)
		quit(1)
		return

	print("MAP_SOCKET_ASSET_BRIEF: wrote %s and %s" % [
		String(export_result.get("markdown_path", "")),
		String(export_result.get("json_path", "")),
	])
	quit(0)


func _parse_args(args: PackedStringArray) -> String:
	var index := 0
	while index < args.size():
		var arg := String(args[index])
		match arg:
			"--output-dir":
				index += 1
				if index >= args.size():
					return "missing path after --output-dir"
				_output_dir = String(args[index]).replace("\\", "/")
			"--snapshot-date":
				index += 1
				if index >= args.size():
					return "missing date after --snapshot-date"
				_snapshot_date = String(args[index]).strip_edges()
			"--seeds":
				index += 1
				if index >= args.size():
					return "missing value after --seeds"
				var parsed_seeds: Array[int] = _parse_int_list(String(args[index]))
				if parsed_seeds.is_empty():
					return "invalid --seeds value: %s" % String(args[index])
				_seeds = parsed_seeds
			"--stages":
				index += 1
				if index >= args.size():
					return "missing value after --stages"
				var parsed_stages: Array[int] = _parse_int_list(String(args[index]))
				if parsed_stages.is_empty():
					return "invalid --stages value: %s" % String(args[index])
				_stages = parsed_stages
			"--progress-steps":
				index += 1
				if index >= args.size():
					return "missing value after --progress-steps"
				var parsed_steps: Array[int] = _parse_int_list(String(args[index]))
				if parsed_steps.is_empty():
					return "invalid --progress-steps value: %s" % String(args[index])
				_progress_steps = parsed_steps
			_:
				return "unexpected argument: %s" % arg
		index += 1

	if _snapshot_date.is_empty():
		return "snapshot date must not be empty"
	return ""


func _parse_int_list(raw_value: String) -> Array[int]:
	var values: Array[int] = []
	for part in raw_value.split(",", false):
		var normalized := String(part).strip_edges()
		if normalized.is_empty():
			continue
		values.append(int(normalized))
	values.sort()
	return values


func _build_export() -> Dictionary:
	var scenarios: Array[Dictionary] = []
	var path_summary: Dictionary = {}
	var landmark_summary: Dictionary = {}
	var clearing_summary: Dictionary = {}
	var canopy_summary: Dictionary = {}
	var decor_summary: Dictionary = {}
	var filler_shape_summary: Dictionary = {}
	var render_summary: Dictionary = {
		"path_surface_count": _empty_number_range(),
		"junction_count": _empty_number_range(),
		"clearing_surface_count": _empty_number_range(),
		"canopy_mask_count": _empty_number_range(),
		"landmark_slot_count": _empty_number_range(),
		"decor_slot_count": _empty_number_range(),
		"template_profiles": [],
		"orientation_profile_ids": [],
		"topology_blueprint_ids": [],
	}
	var first_composition: Dictionary = {}
	var composer: RefCounted = MapBoardComposerV2Script.new()

	for stage in _stages:
		for seed in _seeds:
			for steps in _progress_steps:
				var run_state: RunState = _build_run_state(stage, seed, steps)
				var visible_composition: Dictionary = composer.call(
					"compose",
					run_state,
					DEFAULT_BOARD_SIZE,
					DEFAULT_FOCUS_ANCHOR,
					DEFAULT_MAX_FOCUS_OFFSET
				)
				var visible_render_model: Dictionary = visible_composition.get("render_model", {})
				_accumulate_canopy_masks(visible_render_model.get("canopy_masks", []), canopy_summary)
				_accumulate_decor_slots(visible_render_model.get("decor_slots", []), decor_summary)
				_accumulate_filler_shapes(visible_composition.get("filler_shapes", []), filler_shape_summary)
				_reveal_all_nodes(run_state.map_runtime_state)
				var composition: Dictionary = composer.call(
					"compose",
					run_state,
					DEFAULT_BOARD_SIZE,
					DEFAULT_FOCUS_ANCHOR,
					DEFAULT_MAX_FOCUS_OFFSET
				)
				if first_composition.is_empty():
					first_composition = composition.duplicate(true)
				var scenario: Dictionary = _build_scenario_summary(stage, seed, steps, composition)
				scenarios.append(scenario)
				_accumulate_composition(
					composition,
					path_summary,
					landmark_summary,
					clearing_summary,
					canopy_summary,
					decor_summary,
					render_summary
				)

	var canvas_summary: Dictionary = _build_canvas_boundary_summary(first_composition)
	var coverage_summary: Dictionary = _build_coverage_summary(landmark_summary, decor_summary)
	var brief: Dictionary = {
		"snapshot_date": _snapshot_date,
		"generator": "Tools/map_socket_asset_brief_export.gd",
		"source_files": SOURCE_FILES.duplicate(),
		"snapshot_inputs": {
			"board_size": _vector_to_payload(DEFAULT_BOARD_SIZE),
			"stages": _stages.duplicate(),
			"seeds": _seeds.duplicate(),
			"progress_steps": _progress_steps.duplicate(),
			"scenario_count": scenarios.size(),
			"coverage_mode": "path/landmark coverage uses all nodes revealed inside export pass; environment family sizing also samples normal visible compositions before reveal",
		},
		"default_render_boundary": canvas_summary,
		"render_model_summary": _finalize_nested_summary(render_summary),
		"path_surface_summary": _finalize_group_summary(path_summary),
		"landmark_slot_summary": _finalize_group_summary(landmark_summary),
		"clearing_surface_summary": _finalize_group_summary(clearing_summary),
		"canopy_mask_summary": _finalize_group_summary(canopy_summary),
		"decor_slot_summary": _finalize_group_summary(decor_summary),
		"filler_shape_summary": _finalize_group_summary(filler_shape_summary),
		"coverage_summary": coverage_summary,
		"production_requests": _build_production_requests(path_summary, landmark_summary, canopy_summary, decor_summary, filler_shape_summary),
		"scenarios": scenarios,
	}
	return {
		"brief": brief,
		"markdown": _build_markdown(brief),
		"markdown_path": "%s/map_socket_production_asset_brief.md" % _output_dir.trim_suffix("/"),
		"json_path": "%s/map_socket_production_asset_brief.json" % _output_dir.trim_suffix("/"),
	}


func _build_run_state(stage: int, seed: int, steps: int) -> RunState:
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.stage_index = max(1, stage)
	run_state.configure_run_seed(max(1, seed))
	_advance_visible_branch(run_state, max(0, steps))
	return run_state


func _advance_visible_branch(run_state: RunState, steps: int) -> void:
	var visited_node_ids: Dictionary = {int(run_state.map_runtime_state.current_node_id): true}
	for _step in range(steps):
		var chosen_node_id := _choose_next_progression_node_id(run_state.map_runtime_state, visited_node_ids)
		if chosen_node_id < 0:
			return
		run_state.map_runtime_state.move_to_node(chosen_node_id)
		if run_state.map_runtime_state.get_node_family(chosen_node_id) == "key":
			run_state.map_runtime_state.resolve_stage_key()
		run_state.map_runtime_state.mark_node_resolved(chosen_node_id)
		visited_node_ids[chosen_node_id] = true


func _choose_next_progression_node_id(map_runtime_state: RefCounted, visited_node_ids: Dictionary) -> int:
	for adjacent_node_id in map_runtime_state.get_adjacent_node_ids():
		if visited_node_ids.has(int(adjacent_node_id)):
			continue
		if not map_runtime_state.is_node_discovered(int(adjacent_node_id)):
			continue
		if map_runtime_state.is_node_locked(int(adjacent_node_id)):
			continue
		return int(adjacent_node_id)
	for adjacent_node_id in map_runtime_state.get_adjacent_node_ids():
		if int(adjacent_node_id) == 0:
			continue
		if not map_runtime_state.is_node_discovered(int(adjacent_node_id)):
			continue
		if map_runtime_state.is_node_locked(int(adjacent_node_id)):
			continue
		return int(adjacent_node_id)
	return MapRuntimeStateScript.NO_PENDING_NODE_ID


func _reveal_all_nodes(map_runtime_state: RefCounted) -> void:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		var node_id := int((node_snapshot as Dictionary).get("node_id", MapRuntimeStateScript.NO_PENDING_NODE_ID))
		if node_id == MapRuntimeStateScript.NO_PENDING_NODE_ID:
			continue
		map_runtime_state.reveal_node(node_id)


func _build_scenario_summary(stage: int, seed: int, steps: int, composition: Dictionary) -> Dictionary:
	var render_model: Dictionary = composition.get("render_model", {})
	var visible_family_counts: Dictionary = {}
	for node_variant in composition.get("visible_nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var family := String((node_variant as Dictionary).get("node_family", ""))
		visible_family_counts[family] = int(visible_family_counts.get(family, 0)) + 1
	return {
		"stage": stage,
		"seed": seed,
		"progress_steps": steps,
		"template_profile": String(composition.get("template_profile", "")),
		"orientation_profile_id": String(composition.get("orientation_profile_id", "")),
		"topology_blueprint_id": String(composition.get("topology_blueprint_id", "")),
		"visible_family_counts": visible_family_counts,
		"render_model_counts": {
			"path_surfaces": (render_model.get("path_surfaces", []) as Array).size(),
			"junctions": (render_model.get("junctions", []) as Array).size(),
			"clearing_surfaces": (render_model.get("clearing_surfaces", []) as Array).size(),
			"canopy_masks": (render_model.get("canopy_masks", []) as Array).size(),
			"landmark_slots": (render_model.get("landmark_slots", []) as Array).size(),
			"decor_slots": (render_model.get("decor_slots", []) as Array).size(),
		},
	}


func _accumulate_composition(
	composition: Dictionary,
	path_summary: Dictionary,
	landmark_summary: Dictionary,
	clearing_summary: Dictionary,
	canopy_summary: Dictionary,
	decor_summary: Dictionary,
	render_summary: Dictionary
) -> void:
	var render_model: Dictionary = composition.get("render_model", {})
	_update_number_range(render_summary["path_surface_count"], (render_model.get("path_surfaces", []) as Array).size())
	_update_number_range(render_summary["junction_count"], (render_model.get("junctions", []) as Array).size())
	_update_number_range(render_summary["clearing_surface_count"], (render_model.get("clearing_surfaces", []) as Array).size())
	_update_number_range(render_summary["canopy_mask_count"], (render_model.get("canopy_masks", []) as Array).size())
	_update_number_range(render_summary["landmark_slot_count"], (render_model.get("landmark_slots", []) as Array).size())
	_update_number_range(render_summary["decor_slot_count"], (render_model.get("decor_slots", []) as Array).size())
	_append_unique(render_summary["template_profiles"], String(composition.get("template_profile", "")))
	_append_unique(render_summary["orientation_profile_ids"], String(composition.get("orientation_profile_id", "")))
	_append_unique(render_summary["topology_blueprint_ids"], String(composition.get("topology_blueprint_id", "")))
	_accumulate_path_surfaces(render_model.get("path_surfaces", []), path_summary)
	_accumulate_landmark_slots(render_model.get("landmark_slots", []), landmark_summary)
	_accumulate_clearing_surfaces(render_model.get("clearing_surfaces", []), clearing_summary)
	_accumulate_canopy_masks(render_model.get("canopy_masks", []), canopy_summary)
	_accumulate_decor_slots(render_model.get("decor_slots", []), decor_summary)


func _accumulate_path_surfaces(path_surfaces: Array, path_summary: Dictionary) -> void:
	for surface_variant in path_surfaces:
		if typeof(surface_variant) != TYPE_DICTIONARY:
			continue
		var surface: Dictionary = surface_variant
		var role := String(surface.get("role", ""))
		if role.is_empty():
			role = "unknown"
		var entry: Dictionary = _ensure_group_entry(path_summary, role)
		_update_number_range(entry["surface_width"], float(surface.get("surface_width", 0.0)))
		_update_number_range(entry["outer_width"], float(surface.get("outer_width", 0.0)))
		_update_number_range(entry["centerline_point_count"], (surface.get("centerline_points", PackedVector2Array()) as PackedVector2Array).size())
		_append_unique(entry["path_families"], String(surface.get("path_family", "")))
		_append_unique(entry["state_semantics"], String(surface.get("state_semantic", "")))
		_append_unique(entry["route_surface_semantics"], String(surface.get("route_surface_semantic", "")))
		_append_unique(entry["cardinal_directions"], String(surface.get("cardinal_direction", "")))
		entry["candidate_texture_path"] = UiAssetPathsScript.build_map_path_surface_socket_texture_path(false)
		entry["production_status"] = "candidate_hidden_by_default" if not String(entry.get("candidate_texture_path", "")).is_empty() else "gap"
		_increment_group_count(entry)


func _accumulate_landmark_slots(landmark_slots: Array, landmark_summary: Dictionary) -> void:
	for slot_variant in landmark_slots:
		if typeof(slot_variant) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = slot_variant
		var family := String(slot.get("node_family", ""))
		if family.is_empty():
			family = "unknown"
		var entry: Dictionary = _ensure_group_entry(landmark_summary, family)
		var asset_family_key := String(slot.get("asset_family_key", ""))
		var texture_path := UiAssetPathsScript.build_map_landmark_socket_texture_path(asset_family_key, family, false)
		_append_unique(entry["asset_family_keys"], asset_family_key)
		_append_unique(entry["landmark_shapes"], String(slot.get("landmark_shape", "")))
		_append_unique(entry["pocket_shapes"], String(slot.get("pocket_shape", "")))
		_append_unique(entry["signage_shapes"], String(slot.get("signage_shape", "")))
		_append_unique(entry["slot_roles"], String(slot.get("slot_role", "")))
		_append_unique(entry["state_semantics"], String(slot.get("state_semantic", "")))
		_append_unique(entry["cardinal_directions"], String(slot.get("cardinal_direction", "")))
		_append_unique(entry["outward_route_hints"], String(slot.get("outward_route_hint", "")))
		_update_vector_range(entry["landmark_half_size"], Vector2(slot.get("landmark_half_size", Vector2.ZERO)))
		_update_vector_range(entry["pocket_half_size"], Vector2(slot.get("pocket_half_size", Vector2.ZERO)))
		_update_number_range(entry["scale"], float(slot.get("scale", 0.0)))
		_update_number_range(entry["signage_scale"], float(slot.get("signage_scale", 0.0)))
		_update_number_range(entry["connected_path_count"], (slot.get("connected_path_surface_ids", []) as Array).size())
		entry["candidate_texture_path"] = texture_path
		entry["production_status"] = "candidate_hidden_by_default" if not texture_path.is_empty() else "gap"
		_increment_group_count(entry)


func _accumulate_clearing_surfaces(clearing_surfaces: Array, clearing_summary: Dictionary) -> void:
	for clearing_variant in clearing_surfaces:
		if typeof(clearing_variant) != TYPE_DICTIONARY:
			continue
		var clearing: Dictionary = clearing_variant
		var family := String(clearing.get("node_family", ""))
		if family.is_empty():
			family = "unknown"
		var entry: Dictionary = _ensure_group_entry(clearing_summary, family)
		_append_unique(entry["state_semantics"], String(clearing.get("state_semantic", "")))
		_append_unique(entry["shapes"], String(clearing.get("shape", "")))
		_update_number_range(entry["radius"], float(clearing.get("radius", 0.0)))
		_update_number_range(entry["connected_path_count"], (clearing.get("connected_path_surface_ids", []) as Array).size())
		_increment_group_count(entry)


func _accumulate_canopy_masks(canopy_masks: Array, canopy_summary: Dictionary) -> void:
	for mask_variant in canopy_masks:
		if typeof(mask_variant) != TYPE_DICTIONARY:
			continue
		var mask: Dictionary = mask_variant
		var source_family := String(mask.get("source_family", "canopy"))
		var entry: Dictionary = _ensure_group_entry(canopy_summary, source_family)
		_append_unique(entry["asset_socket_kinds"], String(mask.get("asset_socket_kind", "")))
		_append_unique(entry["mask_roles"], String(mask.get("mask_role", "")))
		_append_unique(entry["clearance_roles"], String(mask.get("clearance_role", "")))
		_append_unique(entry["cardinal_sides"], String(mask.get("cardinal_side", "")))
		_append_unique(entry["outward_route_hints"], String(mask.get("outward_route_hint", "")))
		_update_number_range(entry["radius"], float(mask.get("radius", 0.0)))
		_update_number_range(entry["frames_path_count"], (mask.get("frames_path_surface_ids", []) as Array).size())
		_update_number_range(entry["frames_clearing_count"], (mask.get("frames_clearing_surface_ids", []) as Array).size())
		entry["production_status"] = "mask_metadata_only_no_runtime_asset_path"
		_increment_group_count(entry)


func _accumulate_decor_slots(decor_slots: Array, decor_summary: Dictionary) -> void:
	for slot_variant in decor_slots:
		if typeof(slot_variant) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = slot_variant
		var decor_family := String(slot.get("decor_family", ""))
		if decor_family.is_empty():
			decor_family = "unknown"
		var entry: Dictionary = _ensure_group_entry(decor_summary, decor_family)
		var texture_path := UiAssetPathsScript.build_map_decor_socket_texture_path(decor_family, false)
		_append_unique(entry["asset_socket_kinds"], String(slot.get("asset_socket_kind", "")))
		_append_unique(entry["source_legacy_fields"], String(slot.get("source_legacy_field", "")))
		_append_unique(entry["slot_roles"], String(slot.get("slot_role", "")))
		_append_unique(entry["relation_types"], String(slot.get("relation_type", "")))
		_append_unique(entry["cardinal_sides"], String(slot.get("cardinal_side", "")))
		_append_unique(entry["outward_route_hints"], String(slot.get("outward_route_hint", "")))
		_update_vector_range(entry["half_size"], Vector2(slot.get("half_size", Vector2.ZERO)))
		_update_number_range(entry["radius"], float(slot.get("radius", 0.0)))
		_update_number_range(entry["scale"], float(slot.get("scale", 0.0)))
		entry["candidate_texture_path"] = texture_path
		entry["production_status"] = "generic_candidate_hidden_by_default" if not texture_path.is_empty() else "gap"
		_increment_group_count(entry)


func _accumulate_filler_shapes(filler_shapes: Array, filler_summary: Dictionary) -> void:
	for shape_variant in filler_shapes:
		if typeof(shape_variant) != TYPE_DICTIONARY:
			continue
		var shape: Dictionary = shape_variant
		var family := String(shape.get("family", ""))
		if family.is_empty():
			family = "unknown"
		var entry: Dictionary = _ensure_group_entry(filler_summary, family)
		_append_unique(entry["source_legacy_fields"], "filler_shapes")
		_append_unique(entry["slot_roles"], String(shape.get("terrain_role", "negative_space_filler")))
		_update_vector_range(entry["half_size"], Vector2(shape.get("half_size", Vector2.ZERO)))
		_update_number_range(entry["scale"], float(shape.get("alpha_scale", 0.0)))
		entry["production_status"] = "wrapper_metadata_for_decor_socket_derivation"
		_increment_group_count(entry)


func _build_canvas_boundary_summary(first_composition: Dictionary) -> Dictionary:
	var canvas: Control = MapBoardCanvasScript.new()
	canvas.call("set_composition", first_composition)
	var default_path_entries: Array = canvas.call("_path_surface_socket_smoke_entries")
	var default_landmark_entries: Array = canvas.call("_landmark_socket_smoke_entries")
	var default_decor_entries: Array = canvas.call("_decor_socket_smoke_entries")
	canvas.call("set_prototype_socket_dressing_enabled", true)
	var prototype_path_entries: Array = canvas.call("_path_surface_socket_smoke_entries")
	var prototype_landmark_entries: Array = canvas.call("_landmark_socket_smoke_entries")
	var prototype_decor_entries: Array = canvas.call("_decor_socket_smoke_entries")
	canvas.queue_free()
	return {
		"uses_render_model_surface_lane": not first_composition.is_empty(),
		"prototype_socket_dressing_enabled_by_default": false,
		"default_socket_draw_entry_counts": {
			"path_surface": default_path_entries.size(),
			"landmark": default_landmark_entries.size(),
			"decor": default_decor_entries.size(),
		},
		"prototype_socket_draw_entry_counts_when_enabled": {
			"path_surface": prototype_path_entries.size(),
			"landmark": prototype_landmark_entries.size(),
			"decor": prototype_decor_entries.size(),
		},
		"promotion_note": "normal/default render remains render_model.path_surfaces + junctions + clearing_surfaces; socket art requires explicit prototype/debug canvas enablement",
	}


func _build_coverage_summary(landmark_summary: Dictionary, decor_summary: Dictionary) -> Dictionary:
	var observed_landmark_families: Array[String] = []
	var hidden_candidate_landmark_families: Array[String] = []
	var missing_landmark_families: Array[String] = []
	for family in _sorted_string_keys(landmark_summary):
		observed_landmark_families.append(family)
		var entry: Dictionary = landmark_summary.get(family, {})
		if String(entry.get("production_status", "")) == "gap":
			missing_landmark_families.append(family)
		else:
			hidden_candidate_landmark_families.append(family)
	var unobserved_required_families: Array[String] = []
	for required_family in REQUIRED_RUNTIME_NODE_FAMILIES:
		if not observed_landmark_families.has(required_family):
			unobserved_required_families.append(required_family)
	var decor_candidate_present := false
	for family in decor_summary.keys():
		var entry: Dictionary = decor_summary.get(family, {})
		if not String(entry.get("candidate_texture_path", "")).is_empty():
			decor_candidate_present = true
			break
	return {
		"observed_landmark_families": observed_landmark_families,
		"hidden_candidate_landmark_families": hidden_candidate_landmark_families,
		"missing_landmark_families": missing_landmark_families,
		"unobserved_required_families": unobserved_required_families,
		"path_candidate_present": not UiAssetPathsScript.build_map_path_surface_socket_texture_path(false).is_empty(),
		"decor_candidate_present": decor_candidate_present,
		"required_gap_callout": _build_required_gap_callout(missing_landmark_families, unobserved_required_families),
	}


func _build_required_gap_callout(missing_landmark_families: Array[String], unobserved_required_families: Array[String]) -> String:
	var priority_gap_families: Array[String] = []
	for family in ["combat", "event", "reward", "blacksmith", "hamlet"]:
		if missing_landmark_families.has(family) or unobserved_required_families.has(family):
			priority_gap_families.append(family)
	var optional_gap_families: Array[String] = []
	if missing_landmark_families.has("start") or unobserved_required_families.has("start"):
		optional_gap_families.append("start")
	var parts: PackedStringArray = []
	if priority_gap_families.is_empty():
		parts.append("no priority combat/event/reward/blacksmith/hamlet landmark production gap lacks a hidden candidate texture path")
	else:
		parts.append("%s remain production gaps when no hidden candidate texture path exists" % "/".join(priority_gap_families))
	if not optional_gap_families.is_empty():
		parts.append("%s remains optional/lower-priority origin marker gap" % "/".join(optional_gap_families))
	parts.append("production review is still required before default render promotion")
	return "; ".join(parts)


func _build_production_requests(
	path_summary: Dictionary,
	landmark_summary: Dictionary,
	canopy_summary: Dictionary,
	decor_summary: Dictionary,
	filler_shape_summary: Dictionary
) -> Array[Dictionary]:
	var requests: Array[Dictionary] = []
	requests.append({
		"brief_id": "map_path_brush_production",
		"socket_source": "render_model.path_surfaces",
		"priority": "pilot_candidate_replacement",
		"current_status": "candidate hidden by default" if not UiAssetPathsScript.build_map_path_surface_socket_texture_path(false).is_empty() else "gap",
		"observed_roles": _sorted_string_keys(path_summary),
		"size_reference": _path_size_reference(path_summary),
	})
	for family in _sorted_string_keys(landmark_summary):
		var entry: Dictionary = landmark_summary.get(family, {})
		var status: String = String(entry.get("production_status", "gap"))
		var priority := "gap_fill"
		if family in ["boss", "key", "rest", "merchant"]:
			priority = "pilot_candidate_replacement"
		elif family == "start":
			priority = "optional_origin_marker"
		requests.append({
			"brief_id": "map_landmark_%s_production" % family,
			"socket_source": "render_model.landmark_slots",
			"priority": priority,
			"current_status": status,
			"asset_family_keys": (entry.get("asset_family_keys", []) as Array).duplicate(true),
			"landmark_shapes": (entry.get("landmark_shapes", []) as Array).duplicate(true),
			"pocket_shapes": (entry.get("pocket_shapes", []) as Array).duplicate(true),
			"landmark_half_size": _payload_range(entry.get("landmark_half_size", {})),
			"pocket_half_size": _payload_range(entry.get("pocket_half_size", {})),
		})
	if not canopy_summary.is_empty():
		requests.append({
			"brief_id": "map_canopy_frame_family_production",
			"socket_source": "render_model.canopy_masks",
			"priority": "environment_expansion",
			"current_status": "mask metadata only; no runtime asset path",
			"observed_families": _sorted_string_keys(canopy_summary),
		})
	if not decor_summary.is_empty():
		requests.append({
			"brief_id": "map_decor_stamp_family_production",
			"socket_source": "render_model.decor_slots",
			"priority": "pilot_candidate_replacement",
			"current_status": "generic candidate hidden by default" if _decor_has_candidate(decor_summary) else "gap",
			"observed_families": _sorted_string_keys(decor_summary),
		})
	if not filler_shape_summary.is_empty():
		requests.append({
			"brief_id": "map_filler_shape_family_production",
			"socket_source": "filler_shapes wrapper metadata feeding render_model.decor_slots",
			"priority": "environment_expansion",
			"current_status": "wrapper metadata only; no family-specific runtime asset path",
			"observed_families": _sorted_string_keys(filler_shape_summary),
		})
	else:
		requests.append({
			"brief_id": "map_filler_shape_family_watch",
			"socket_source": "filler_shapes wrapper metadata feeding render_model.decor_slots",
			"priority": "deferred_observation",
			"current_status": "no live filler_shapes observed in sampled compositions",
			"observed_families": [],
		})
	return requests


func _path_size_reference(path_summary: Dictionary) -> Dictionary:
	var merged := {
		"surface_width": _empty_number_range(),
		"outer_width": _empty_number_range(),
	}
	for role in path_summary.keys():
		var entry: Dictionary = path_summary.get(role, {})
		_merge_number_range(merged["surface_width"], entry.get("surface_width", {}))
		_merge_number_range(merged["outer_width"], entry.get("outer_width", {}))
	return _finalize_nested_summary(merged)


func _decor_has_candidate(decor_summary: Dictionary) -> bool:
	for family in decor_summary.keys():
		var entry: Dictionary = decor_summary.get(family, {})
		if not String(entry.get("candidate_texture_path", "")).is_empty():
			return true
	return false


func _build_markdown(brief: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("# Map Socket Production Asset Brief")
	lines.append("")
	lines.append("Generated: %s" % String(brief.get("snapshot_date", "")))
	lines.append("")
	lines.append("Source: live GDScript render/socket metadata, not archived prompt packs or retired art briefs.")
	lines.append("")
	lines.append("## Snapshot Inputs")
	lines.append("")
	var inputs: Dictionary = brief.get("snapshot_inputs", {})
	lines.append("- Generator: `%s`" % String(brief.get("generator", "")))
	lines.append("- Board size: `%sx%s`" % [
		_format_number(float((inputs.get("board_size", {}) as Dictionary).get("x", 0.0))),
		_format_number(float((inputs.get("board_size", {}) as Dictionary).get("y", 0.0))),
	])
	lines.append("- Stages: `%s`" % _join_values(inputs.get("stages", [])))
	lines.append("- Seeds: `%s`" % _join_values(inputs.get("seeds", [])))
	lines.append("- Progress steps: `%s`" % _join_values(inputs.get("progress_steps", [])))
	lines.append("- Scenarios: `%d`" % int(inputs.get("scenario_count", 0)))
	lines.append("- Coverage mode: %s." % String(inputs.get("coverage_mode", "")))
	lines.append("")
	lines.append("Source `.gd` files:")
	lines.append("")
	for source_file in brief.get("source_files", []):
		lines.append("- `%s`" % String(source_file))
	lines.append("")
	lines.append("## Default Render Boundary")
	lines.append("")
	var boundary: Dictionary = brief.get("default_render_boundary", {})
	var default_counts: Dictionary = boundary.get("default_socket_draw_entry_counts", {})
	var enabled_counts: Dictionary = boundary.get("prototype_socket_draw_entry_counts_when_enabled", {})
	lines.append("- Default socket draw entries: path `%d`, landmark `%d`, decor `%d`." % [
		int(default_counts.get("path_surface", 0)),
		int(default_counts.get("landmark", 0)),
		int(default_counts.get("decor", 0)),
	])
	lines.append("- When explicit prototype socket dressing is enabled: path `%d`, landmark `%d`, decor `%d`." % [
		int(enabled_counts.get("path_surface", 0)),
		int(enabled_counts.get("landmark", 0)),
		int(enabled_counts.get("decor", 0)),
	])
	lines.append("- Promotion boundary: %s." % String(boundary.get("promotion_note", "")))
	lines.append("")
	lines.append("## Render Model")
	lines.append("")
	var render_summary: Dictionary = brief.get("render_model_summary", {})
	lines.append("- Path surfaces per scenario: `%s`." % _range_to_text(render_summary.get("path_surface_count", {})))
	lines.append("- Junctions per scenario: `%s`." % _range_to_text(render_summary.get("junction_count", {})))
	lines.append("- Clearing surfaces per scenario: `%s`." % _range_to_text(render_summary.get("clearing_surface_count", {})))
	lines.append("- Canopy masks per scenario: `%s`." % _range_to_text(render_summary.get("canopy_mask_count", {})))
	lines.append("- Landmark slots per scenario: `%s`." % _range_to_text(render_summary.get("landmark_slot_count", {})))
	lines.append("- Decor slots per scenario: `%s`." % _range_to_text(render_summary.get("decor_slot_count", {})))
	lines.append("- Template profiles: `%s`." % _join_values(render_summary.get("template_profiles", [])))
	lines.append("- Orientation profiles: `%s`." % _join_values(render_summary.get("orientation_profile_ids", [])))
	lines.append("")
	lines.append("## Path Brush")
	lines.append("")
	lines.append("| role | count | surface width | outer width | path families | status |")
	lines.append("|---|---:|---:|---:|---|---|")
	var path_summary: Dictionary = brief.get("path_surface_summary", {})
	for role in _sorted_string_keys(path_summary):
		var entry: Dictionary = path_summary.get(role, {})
		lines.append("| `%s` | %d | `%s` | `%s` | `%s` | %s |" % [
			role,
			int(entry.get("count", 0)),
			_range_to_text(entry.get("surface_width", {})),
			_range_to_text(entry.get("outer_width", {})),
			_join_values(entry.get("path_families", [])),
			String(entry.get("production_status", "")),
		])
	lines.append("")
	lines.append("## Landmark Sockets")
	lines.append("")
	lines.append("| family | asset family keys | landmark shapes | pocket shapes | landmark half-size | pocket half-size | status |")
	lines.append("|---|---|---|---|---:|---:|---|")
	var landmark_summary: Dictionary = brief.get("landmark_slot_summary", {})
	for family in _sorted_string_keys(landmark_summary):
		var entry: Dictionary = landmark_summary.get(family, {})
		lines.append("| `%s` | `%s` | `%s` | `%s` | `%s` | `%s` | %s |" % [
			family,
			_join_values(entry.get("asset_family_keys", [])),
			_join_values(entry.get("landmark_shapes", [])),
			_join_values(entry.get("pocket_shapes", [])),
			_vector_range_to_text(entry.get("landmark_half_size", {})),
			_vector_range_to_text(entry.get("pocket_half_size", {})),
			String(entry.get("production_status", "")),
		])
	lines.append("")
	lines.append("## Coverage Gaps")
	lines.append("")
	var coverage: Dictionary = brief.get("coverage_summary", {})
	lines.append("- Hidden candidate landmark families: `%s`." % _join_values(coverage.get("hidden_candidate_landmark_families", [])))
	lines.append("- Missing production landmark families: `%s`." % _join_values(coverage.get("missing_landmark_families", [])))
	lines.append("- Required-but-unobserved families: `%s`." % _join_values(coverage.get("unobserved_required_families", [])))
	lines.append("- Required gap callout: %s." % String(coverage.get("required_gap_callout", "")))
	lines.append("")
	lines.append("## Canopy And Decor")
	lines.append("")
	lines.append("| socket | family | count | size/radius | relations | status |")
	lines.append("|---|---|---:|---:|---|---|")
	var canopy_summary: Dictionary = brief.get("canopy_mask_summary", {})
	for family in _sorted_string_keys(canopy_summary):
		var entry: Dictionary = canopy_summary.get(family, {})
		lines.append("| canopy | `%s` | %d | radius `%s` | `%s` | %s |" % [
			family,
			int(entry.get("count", 0)),
			_range_to_text(entry.get("radius", {})),
			_join_values(entry.get("mask_roles", [])),
			String(entry.get("production_status", "")),
		])
	var decor_summary: Dictionary = brief.get("decor_slot_summary", {})
	for family in _sorted_string_keys(decor_summary):
		var entry: Dictionary = decor_summary.get(family, {})
		lines.append("| decor | `%s` | %d | half `%s`, radius `%s` | `%s` | %s |" % [
			family,
			int(entry.get("count", 0)),
			_vector_range_to_text(entry.get("half_size", {})),
			_range_to_text(entry.get("radius", {})),
			_join_values(entry.get("relation_types", [])),
			String(entry.get("production_status", "")),
		])
	var filler_summary: Dictionary = brief.get("filler_shape_summary", {})
	for family in _sorted_string_keys(filler_summary):
		var entry: Dictionary = filler_summary.get(family, {})
		lines.append("| filler-wrapper | `%s` | %d | half `%s` | `%s` | %s |" % [
			family,
			int(entry.get("count", 0)),
			_vector_range_to_text(entry.get("half_size", {})),
			_join_values(entry.get("slot_roles", [])),
			String(entry.get("production_status", "")),
		])
	if filler_summary.is_empty():
		lines.append("| filler-wrapper | `none observed` | 0 | n/a | n/a | no live filler_shapes observed in sampled compositions |")
	lines.append("")
	lines.append("## Production Request Queue")
	lines.append("")
	for request_variant in brief.get("production_requests", []):
		var request: Dictionary = request_variant
		lines.append("- `%s`: %s, source `%s`, status `%s`." % [
			String(request.get("brief_id", "")),
			String(request.get("priority", "")),
			String(request.get("socket_source", "")),
			String(request.get("current_status", "")),
		])
	lines.append("")
	lines.append("## Promotion Gate")
	lines.append("")
	lines.append("- Do not enable candidate or production art in normal/default board render inside this brief step.")
	lines.append("- Runtime promotion still needs manifest/provenance truth, screenshot review, and pixel diff.")
	lines.append("- This brief does not change gameplay truth, save shape, flow state, or asset approval status.")
	lines.append("")
	return "\n".join(lines)


func _write_export(export_result: Dictionary) -> String:
	var markdown_path: String = String(export_result.get("markdown_path", ""))
	var json_path: String = String(export_result.get("json_path", ""))
	var output_dir_absolute := ProjectSettings.globalize_path(_output_dir)
	var make_dir_result := DirAccess.make_dir_recursive_absolute(output_dir_absolute)
	if make_dir_result != OK:
		return "failed to create output directory %s: %d" % [output_dir_absolute, make_dir_result]
	var markdown_error := _write_text_file(markdown_path, String(export_result.get("markdown", "")))
	if not markdown_error.is_empty():
		return markdown_error
	var json_text := JSON.stringify(export_result.get("brief", {}), "\t", false)
	var json_error := _write_text_file(json_path, "%s\n" % json_text)
	if not json_error.is_empty():
		return json_error
	return ""


func _write_text_file(path: String, text: String) -> String:
	var absolute_path := ProjectSettings.globalize_path(path)
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return "failed to open %s for write: %d" % [absolute_path, FileAccess.get_open_error()]
	file.store_string(text)
	file.close()
	return ""


func _ensure_group_entry(summary: Dictionary, key: String) -> Dictionary:
	if not summary.has(key):
		summary[key] = {
			"count": 0,
			"asset_family_keys": [],
			"landmark_shapes": [],
			"pocket_shapes": [],
			"signage_shapes": [],
			"slot_roles": [],
			"state_semantics": [],
			"cardinal_directions": [],
			"outward_route_hints": [],
			"path_families": [],
			"route_surface_semantics": [],
			"asset_socket_kinds": [],
			"mask_roles": [],
			"clearance_roles": [],
			"cardinal_sides": [],
			"source_legacy_fields": [],
			"relation_types": [],
			"shapes": [],
			"surface_width": _empty_number_range(),
			"outer_width": _empty_number_range(),
			"centerline_point_count": _empty_number_range(),
			"landmark_half_size": _empty_vector_range(),
			"pocket_half_size": _empty_vector_range(),
			"half_size": _empty_vector_range(),
			"scale": _empty_number_range(),
			"signage_scale": _empty_number_range(),
			"connected_path_count": _empty_number_range(),
			"radius": _empty_number_range(),
			"frames_path_count": _empty_number_range(),
			"frames_clearing_count": _empty_number_range(),
			"candidate_texture_path": "",
			"production_status": "",
		}
	return summary[key]


func _increment_group_count(entry: Dictionary) -> void:
	entry["count"] = int(entry.get("count", 0)) + 1


func _empty_number_range() -> Dictionary:
	return {
		"min": INF,
		"max": -INF,
	}


func _empty_vector_range() -> Dictionary:
	return {
		"min": _vector_to_payload(Vector2(INF, INF)),
		"max": _vector_to_payload(Vector2(-INF, -INF)),
	}


func _update_number_range(range_entry: Dictionary, value: float) -> void:
	if value == INF or value == -INF:
		return
	range_entry["min"] = minf(float(range_entry.get("min", INF)), value)
	range_entry["max"] = maxf(float(range_entry.get("max", -INF)), value)


func _update_vector_range(range_entry: Dictionary, value: Vector2) -> void:
	var min_entry: Dictionary = range_entry.get("min", _vector_to_payload(Vector2(INF, INF)))
	var max_entry: Dictionary = range_entry.get("max", _vector_to_payload(Vector2(-INF, -INF)))
	min_entry["x"] = minf(float(min_entry.get("x", INF)), value.x)
	min_entry["y"] = minf(float(min_entry.get("y", INF)), value.y)
	max_entry["x"] = maxf(float(max_entry.get("x", -INF)), value.x)
	max_entry["y"] = maxf(float(max_entry.get("y", -INF)), value.y)
	range_entry["min"] = min_entry
	range_entry["max"] = max_entry


func _merge_number_range(target: Dictionary, source_variant: Variant) -> void:
	if typeof(source_variant) != TYPE_DICTIONARY:
		return
	var source: Dictionary = source_variant
	_update_number_range(target, float(source.get("min", INF)))
	_update_number_range(target, float(source.get("max", -INF)))


func _append_unique(values: Array, value: String) -> void:
	var normalized := value.strip_edges()
	if normalized.is_empty():
		return
	if values.has(normalized):
		return
	values.append(normalized)
	values.sort()


func _finalize_group_summary(summary: Dictionary) -> Dictionary:
	var finalized: Dictionary = {}
	for key in _sorted_string_keys(summary):
		finalized[key] = _finalize_nested_summary(summary.get(key, {}))
	return finalized


func _finalize_nested_summary(value: Variant) -> Variant:
	if typeof(value) == TYPE_DICTIONARY:
		var source: Dictionary = value
		if source.has("min") and source.has("max"):
			return _payload_range(source)
		var result: Dictionary = {}
		for key in _sorted_string_keys(source):
			result[key] = _finalize_nested_summary(source.get(key))
		return result
	if typeof(value) == TYPE_ARRAY:
		var duplicated: Array = (value as Array).duplicate(true)
		duplicated.sort()
		return duplicated
	return value


func _payload_range(range_entry: Variant) -> Dictionary:
	if typeof(range_entry) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = range_entry
	var min_value: Variant = source.get("min", INF)
	var max_value: Variant = source.get("max", -INF)
	if typeof(min_value) == TYPE_DICTIONARY or typeof(max_value) == TYPE_DICTIONARY:
		var min_entry: Dictionary = min_value if typeof(min_value) == TYPE_DICTIONARY else {}
		var max_entry: Dictionary = max_value if typeof(max_value) == TYPE_DICTIONARY else {}
		if _vector_payload_range_is_empty(min_entry, max_entry):
			return {
				"min": _vector_to_payload(Vector2.ZERO),
				"max": _vector_to_payload(Vector2.ZERO),
			}
		return {
			"min": min_value,
			"max": max_value,
		}
	if float(min_value) == INF and float(max_value) == -INF:
		return {
			"min": 0.0,
			"max": 0.0,
		}
	return {
		"min": snappedf(float(min_value), 0.001),
		"max": snappedf(float(max_value), 0.001),
	}


func _vector_payload_range_is_empty(min_entry: Dictionary, max_entry: Dictionary) -> bool:
	if min_entry.is_empty() or max_entry.is_empty():
		return true
	for axis in ["x", "y"]:
		var min_value := float(min_entry.get(axis, INF))
		var max_value := float(max_entry.get(axis, -INF))
		if is_inf(min_value) or is_inf(max_value):
			return true
		if min_value > 1.0e20 or max_value < -1.0e20:
			return true
	return false


func _vector_to_payload(value: Vector2) -> Dictionary:
	return {
		"x": snappedf(value.x, 0.001),
		"y": snappedf(value.y, 0.001),
	}


func _sorted_string_keys(value: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key_variant in value.keys():
		keys.append(String(key_variant))
	keys.sort()
	return keys


func _join_values(values_variant: Variant) -> String:
	if typeof(values_variant) != TYPE_ARRAY:
		return ""
	var values: Array[String] = []
	for value in values_variant:
		values.append(str(value))
	values.sort()
	return ", ".join(values)


func _range_to_text(range_variant: Variant) -> String:
	if typeof(range_variant) != TYPE_DICTIONARY:
		return ""
	var range_entry: Dictionary = range_variant
	return "%s-%s" % [
		_format_number(float(range_entry.get("min", 0.0))),
		_format_number(float(range_entry.get("max", 0.0))),
	]


func _vector_range_to_text(range_variant: Variant) -> String:
	if typeof(range_variant) != TYPE_DICTIONARY:
		return ""
	var range_entry: Dictionary = range_variant
	var min_entry: Dictionary = range_entry.get("min", {})
	var max_entry: Dictionary = range_entry.get("max", {})
	if min_entry.is_empty() or max_entry.is_empty():
		return ""
	return "%sx%s-%sx%s" % [
		_format_number(float(min_entry.get("x", 0.0))),
		_format_number(float(min_entry.get("y", 0.0))),
		_format_number(float(max_entry.get("x", 0.0))),
		_format_number(float(max_entry.get("y", 0.0))),
	]


func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.2f" % value
