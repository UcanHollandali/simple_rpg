# Layer: RuntimeState
extends RefCounted
class_name RunState

const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const MapRuntimeStateScript = preload("res://Game/RuntimeState/map_runtime_state.gd")
const CharacterPerkStateScript = preload("res://Game/RuntimeState/character_perk_state.gd")

const DEFAULT_PLAYER_HP: int = 60
const DEFAULT_HUNGER: int = 20
const DEFAULT_XP: int = 0
const DEFAULT_LEVEL: int = 1
const DEFAULT_STAGE_INDEX: int = 1
const DEFAULT_GOLD: int = 0
const DEFAULT_NODE_INDEX: int = 0
const DEFAULT_RUN_SEED: int = 1

var player_hp: int = DEFAULT_PLAYER_HP
var hunger: int = DEFAULT_HUNGER
var xp: int = DEFAULT_XP
var current_level: int = DEFAULT_LEVEL
var stage_index: int = DEFAULT_STAGE_INDEX
var gold: int = DEFAULT_GOLD
var run_seed: int = DEFAULT_RUN_SEED
var rng_stream_states: Dictionary = {}
var equipped_technique_definition_id: String = ""
var inventory_state: RefCounted = InventoryStateScript.new()
var map_runtime_state: RefCounted = MapRuntimeStateScript.new()
var character_perk_state: RefCounted = CharacterPerkStateScript.new()

# Compatibility mirror only. Active map ownership stays on MapRuntimeState.current_node_id;
# do not reopen routing or save growth through this legacy scalar.
var current_node_index: int:
	get:
		return map_runtime_state.current_node_index
	set(value):
		map_runtime_state.current_node_index = value

var weapon_instance: Dictionary:
	get:
		return inventory_state.weapon_instance
	set(value):
		inventory_state.set_weapon_instance(value)

# Compatibility accessors only. Active inventory ownership stays on InventoryState;
# do not reopen broader equipment growth through RunState just for convenience.
var armor_instance: Dictionary:
	get:
		return inventory_state.armor_instance
	set(value):
		inventory_state.set_armor_instance(value)

var belt_instance: Dictionary:
	get:
		return inventory_state.belt_instance
	set(value):
		inventory_state.set_belt_instance(value)

var consumable_slots: Array[Dictionary]:
	get:
		return inventory_state.consumable_slots
	set(value):
		inventory_state.set_consumable_slots(value)

var passive_slots: Array[Dictionary]:
	get:
		return inventory_state.passive_slots
	set(value):
		inventory_state.set_passive_slots(value)


func reset_for_new_run() -> void:
	player_hp = DEFAULT_PLAYER_HP
	hunger = DEFAULT_HUNGER
	xp = DEFAULT_XP
	current_level = DEFAULT_LEVEL
	stage_index = DEFAULT_STAGE_INDEX
	gold = DEFAULT_GOLD
	run_seed = _generate_new_run_seed()
	rng_stream_states = {}
	equipped_technique_definition_id = ""
	inventory_state.reset_for_new_run()
	map_runtime_state.reset_for_new_run(stage_index, run_seed)
	character_perk_state.reset_for_new_run()


func commit_combat_result(combat_state: CombatState) -> void:
	player_hp = combat_state.player_hp
	hunger = clamp(int(combat_state.player_hunger), 0, DEFAULT_HUNGER)
	inventory_state.copy_from_combat_state(combat_state)


func configure_run_seed(seed: int) -> void:
	run_seed = _normalize_seed(seed)
	rng_stream_states = {}
	if map_runtime_state != null:
		map_runtime_state.reset_for_new_run(stage_index, run_seed)


func consume_named_rng_context(stream_name: String, context_salt: String = "") -> Dictionary:
	var normalized_stream_name: String = stream_name.strip_edges()
	if normalized_stream_name.is_empty():
		return {}
	if run_seed <= 0:
		run_seed = _generate_new_run_seed()

	var draw_index: int = max(0, int(rng_stream_states.get(normalized_stream_name, 0)))
	rng_stream_states[normalized_stream_name] = draw_index + 1
	return {
		"stream_name": normalized_stream_name,
		"draw_index": draw_index,
		"stream_seed": _build_stream_seed(normalized_stream_name, draw_index, context_salt),
	}


func to_save_dict() -> Dictionary:
	return {
		"player_hp": player_hp,
		"hunger": hunger,
		"xp": xp,
		"current_level": current_level,
		"stage_index": stage_index,
		"gold": gold,
		"run_seed": run_seed,
		"rng_stream_states": _duplicate_stream_states(),
		"equipped_technique_definition_id": equipped_technique_definition_id,
		"character_perk_state": character_perk_state.to_save_dict(),
	}.merged(inventory_state.to_save_dict(), true).merged(map_runtime_state.to_save_dict(), true)


func load_from_save_dict(save_data: Dictionary, save_schema_version: int = -1) -> void:
	var resolved_save_schema_version: int = _resolve_save_schema_version_for_load(save_data, save_schema_version)
	player_hp = int(save_data.get("player_hp", DEFAULT_PLAYER_HP))
	hunger = clamp(int(save_data.get("hunger", DEFAULT_HUNGER)), 0, DEFAULT_HUNGER)
	xp = int(save_data.get("xp", DEFAULT_XP))
	current_level = int(save_data.get("current_level", DEFAULT_LEVEL))
	stage_index = int(save_data.get("stage_index", DEFAULT_STAGE_INDEX))
	gold = int(save_data.get("gold", DEFAULT_GOLD))
	run_seed = _normalize_seed(int(save_data.get("run_seed", _derive_legacy_run_seed(save_data))))
	rng_stream_states = _extract_rng_stream_states(save_data.get("rng_stream_states", {}))
	equipped_technique_definition_id = String(save_data.get("equipped_technique_definition_id", "")).strip_edges()
	inventory_state.load_from_flat_save_dict(save_data)
	map_runtime_state.load_from_save_dict(save_data, stage_index)
	if resolved_save_schema_version >= 7 and typeof(save_data.get("character_perk_state", null)) == TYPE_DICTIONARY:
		character_perk_state.load_from_save_dict(save_data.get("character_perk_state", {}))
	else:
		character_perk_state.load_from_legacy_passive_slots(inventory_state.passive_slots)
		if resolved_save_schema_version >= 0 and not inventory_state.passive_slots.is_empty():
			inventory_state.set_passive_slots([])


func _duplicate_stream_states() -> Dictionary:
	var result: Dictionary = {}
	for key_variant in rng_stream_states.keys():
		var stream_name: String = String(key_variant).strip_edges()
		if stream_name.is_empty():
			continue
		result[stream_name] = max(0, int(rng_stream_states.get(key_variant, 0)))
	return result


func _extract_rng_stream_states(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return result

	var source: Dictionary = value
	for key_variant in source.keys():
		var stream_name: String = String(key_variant).strip_edges()
		if stream_name.is_empty():
			continue
		result[stream_name] = max(0, int(source.get(key_variant, 0)))
	return result


func _build_stream_seed(stream_name: String, draw_index: int, context_salt: String) -> int:
	var raw: String = "%d|%s|%d|%s" % [run_seed, stream_name, draw_index, context_salt]
	return _hash_seed_string(raw)


func _generate_new_run_seed() -> int:
	var raw: String = "%d|%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	return _hash_seed_string(raw)


func _derive_legacy_run_seed(save_data: Dictionary) -> int:
	var legacy_bits: Array[String] = [
		str(save_data.get("player_hp", DEFAULT_PLAYER_HP)),
		str(save_data.get("hunger", DEFAULT_HUNGER)),
		str(save_data.get("xp", DEFAULT_XP)),
		str(save_data.get("current_level", DEFAULT_LEVEL)),
		str(save_data.get("stage_index", DEFAULT_STAGE_INDEX)),
		str(save_data.get("gold", DEFAULT_GOLD)),
		str(save_data.get("current_node_id", save_data.get("current_node_index", DEFAULT_NODE_INDEX))),
	]
	return _hash_seed_string("|".join(legacy_bits))


func _normalize_seed(seed: int) -> int:
	var normalized: int = abs(seed)
	if normalized == 0:
		return DEFAULT_RUN_SEED
	return normalized


func _hash_seed_string(value: String) -> int:
	var accumulator: int = 216613626
	var bytes: PackedByteArray = value.to_utf8_buffer()
	for byte in bytes:
		accumulator = abs(int((accumulator ^ int(byte)) * 16777619))
	if accumulator == 0:
		return DEFAULT_RUN_SEED
	return accumulator


func _resolve_save_schema_version_for_load(save_data: Dictionary, save_schema_version: int) -> int:
	if save_schema_version >= 0:
		return save_schema_version
	if typeof(save_data.get("character_perk_state", null)) == TYPE_DICTIONARY:
		if _save_data_uses_item_taxonomy_v8(save_data):
			return 8
		return 7
	if typeof(save_data.get("backpack_slots", null)) == TYPE_ARRAY:
		return 6
	if typeof(save_data.get("inventory_slots", null)) == TYPE_ARRAY:
		return 5
	return -1


func _save_data_uses_item_taxonomy_v8(save_data: Dictionary) -> bool:
	var content_version: String = String(save_data.get("content_version", "")).strip_edges()
	if content_version == "prototype_content_v7":
		return true
	var backpack_slots_variant: Variant = save_data.get("backpack_slots", [])
	if typeof(backpack_slots_variant) == TYPE_ARRAY:
		for entry_variant in backpack_slots_variant:
			if typeof(entry_variant) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = entry_variant
			var inventory_family: String = String(entry.get("inventory_family", ""))
			if inventory_family in [InventoryState.INVENTORY_FAMILY_QUEST_ITEM, InventoryState.INVENTORY_FAMILY_SHIELD_ATTACHMENT]:
				return true
			if entry.has(InventoryState.SHIELD_ATTACHMENT_ID_KEY):
				return true
	var left_hand_slot_variant: Variant = save_data.get("equipped_left_hand_slot", {})
	if typeof(left_hand_slot_variant) == TYPE_DICTIONARY and (left_hand_slot_variant as Dictionary).has(InventoryState.SHIELD_ATTACHMENT_ID_KEY):
		return true
	return false
