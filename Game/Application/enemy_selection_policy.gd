# Layer: Application
extends RefCounted
class_name EnemySelectionPolicy

const NODE_FAMILY_BOSS: String = "boss"
const ENEMY_TAG_BOSS: String = "boss"
const STAGE_TAG_PREFIX: String = "stage_"


func resolve_combat_enemy_definition_id(loader: ContentLoader, active_run_state: RunState, encounter_node_family: String) -> String:
	if loader == null or active_run_state == null:
		return ""
	var stage_index: int = max(1, int(active_run_state.stage_index))
	if encounter_node_family == NODE_FAMILY_BOSS:
		return find_boss_enemy_definition_id(loader, stage_index)

	var enemy_definition_ids: Array[String] = list_combat_enemy_definition_ids(loader, stage_index)
	if enemy_definition_ids.is_empty():
		return ""

	var current_node_id: int = active_run_state.map_runtime_state.current_node_id
	var encounter_index: int = max(0, current_node_id - 1)
	return enemy_definition_ids[encounter_index % enemy_definition_ids.size()]


func list_combat_enemy_definition_ids(loader: ContentLoader, stage_index: int = 1) -> Array[String]:
	if loader == null:
		return []

	var stage_specific_ids: Array[String] = []
	var fallback_ids: Array[String] = []
	var stage_tag: String = _build_stage_tag(stage_index)
	var enemy_definition_ids: Array[String] = []
	for definition_id in loader.list_definition_ids_by_authoring_order("Enemies"):
		var enemy_definition: Dictionary = loader.load_definition("Enemies", definition_id)
		if enemy_definition.is_empty():
			continue
		if is_combat_enemy_definition_allowed(enemy_definition):
			if _enemy_definition_has_tag(enemy_definition, stage_tag):
				stage_specific_ids.append(definition_id)
			else:
				fallback_ids.append(definition_id)

	if not stage_specific_ids.is_empty():
		enemy_definition_ids = stage_specific_ids
	else:
		enemy_definition_ids = fallback_ids

	if enemy_definition_ids.is_empty():
		return loader.list_definition_ids_by_authoring_order("Enemies")
	return enemy_definition_ids


func find_boss_enemy_definition_id(loader: ContentLoader, stage_index: int = 1) -> String:
	if loader == null:
		return ""

	var stage_tag: String = _build_stage_tag(stage_index)
	var fallback_definition_id: String = ""
	for definition_id in loader.list_definition_ids_by_authoring_order("Enemies"):
		var enemy_definition: Dictionary = loader.load_definition("Enemies", definition_id)
		if enemy_definition.is_empty():
			continue
		if not is_boss_enemy_definition(enemy_definition):
			continue
		if fallback_definition_id.is_empty():
			fallback_definition_id = definition_id
		if _enemy_definition_has_tag(enemy_definition, stage_tag):
			return definition_id
	return fallback_definition_id


func is_combat_enemy_definition_allowed(enemy_definition: Dictionary) -> bool:
	var encounter_tier: String = String(enemy_definition.get("encounter_tier", "minor"))
	if encounter_tier == "elite":
		return false
	if is_boss_enemy_definition(enemy_definition):
		return false
	return true


func is_boss_enemy_definition(enemy_definition: Dictionary) -> bool:
	var tags_variant: Variant = enemy_definition.get("tags", [])
	if typeof(tags_variant) != TYPE_ARRAY:
		return false

	for tag_value in tags_variant:
		if String(tag_value) == ENEMY_TAG_BOSS:
			return true
	return false


func _build_stage_tag(stage_index: int) -> String:
	return "%s%d" % [STAGE_TAG_PREFIX, max(1, stage_index)]


func _enemy_definition_has_tag(enemy_definition: Dictionary, tag_name: String) -> bool:
	if tag_name.is_empty():
		return false
	var tags_variant: Variant = enemy_definition.get("tags", [])
	if typeof(tags_variant) != TYPE_ARRAY:
		return false
	for tag_value in tags_variant:
		if String(tag_value) == tag_name:
			return true
	return false
