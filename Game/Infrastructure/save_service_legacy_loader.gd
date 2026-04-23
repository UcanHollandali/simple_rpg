# Layer: Infrastructure
extends RefCounted
class_name SaveServiceLegacyLoader

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const SaveValidationCommonScript = preload("res://Game/Infrastructure/save_validation_common.gd")

const PREVIOUS_SAVE_SCHEMA_VERSION: int = 7
const OLDER_SAVE_SCHEMA_VERSION: int = 6
const SHARED_BAG_SAVE_SCHEMA_VERSION: int = 5
const LEGACY_REWARD_SAVE_SCHEMA_VERSION: int = 2
const LEGACY_SAVE_SCHEMA_VERSION: int = 1
const LEGACY_CONTENT_VERSION: String = "prototype_content_v4"
const OLDER_CONTENT_VERSION: String = "prototype_content_v5"
const PREVIOUS_CONTENT_VERSION: String = "prototype_content_v6"
const SUPPORTED_LEGACY_SAVE_SCHEMA_VERSIONS := [
	LEGACY_SAVE_SCHEMA_VERSION,
	LEGACY_REWARD_SAVE_SCHEMA_VERSION,
	SHARED_BAG_SAVE_SCHEMA_VERSION,
	OLDER_SAVE_SCHEMA_VERSION,
	PREVIOUS_SAVE_SCHEMA_VERSION,
]


func supports_schema_version(save_schema_version: int) -> bool:
	return save_schema_version in SUPPORTED_LEGACY_SAVE_SCHEMA_VERSIONS


func content_version_matches_schema(
	save_schema_version: int,
	snapshot_content_version: String,
	current_content_version: String
) -> bool:
	if save_schema_version >= PREVIOUS_SAVE_SCHEMA_VERSION:
		return snapshot_content_version in [PREVIOUS_CONTENT_VERSION, current_content_version]
	if save_schema_version >= OLDER_SAVE_SCHEMA_VERSION:
		return snapshot_content_version in [OLDER_CONTENT_VERSION, PREVIOUS_CONTENT_VERSION, current_content_version]
	return snapshot_content_version in [LEGACY_CONTENT_VERSION, OLDER_CONTENT_VERSION, PREVIOUS_CONTENT_VERSION, current_content_version]


func validate_schema_specific_run_state(save_schema_version: int, run_state_data: Dictionary) -> Dictionary:
	if save_schema_version >= OLDER_SAVE_SCHEMA_VERSION:
		var run_seed: int = int(run_state_data.get("run_seed", 0))
		if run_seed <= 0:
			return {
				"ok": false,
				"error": "invalid_run_seed",
			}
		var rng_stream_states_variant: Variant = run_state_data.get("rng_stream_states", null)
		if typeof(rng_stream_states_variant) != TYPE_DICTIONARY or not _rng_stream_states_are_valid(rng_stream_states_variant as Dictionary):
			return {
				"ok": false,
				"error": "invalid_rng_stream_states",
			}
		var backpack_slots_variant: Variant = run_state_data.get("backpack_slots", null)
		if typeof(backpack_slots_variant) != TYPE_ARRAY or not _inventory_slots_are_valid(backpack_slots_variant as Array):
			return {
				"ok": false,
				"error": "invalid_backpack_slots",
			}
		if int(run_state_data.get("inventory_next_slot_id", 0)) <= 0:
			return {
				"ok": false,
				"error": "invalid_inventory_next_slot_id",
			}
		if not _equipped_inventory_slot_is_valid(run_state_data.get("equipped_right_hand_slot", {}), "weapon"):
			return {
				"ok": false,
				"error": "invalid_equipped_right_hand_slot",
			}
		if not _equipped_inventory_slot_is_valid(run_state_data.get("equipped_left_hand_slot", {}), ["weapon", "shield"], true):
			return {
				"ok": false,
				"error": "invalid_equipped_left_hand_slot",
			}
		if not _equipped_inventory_slot_is_valid(run_state_data.get("equipped_armor_slot", {}), "armor", true):
			return {
				"ok": false,
				"error": "invalid_equipped_armor_slot",
			}
		if not _equipped_inventory_slot_is_valid(run_state_data.get("equipped_belt_slot", {}), "belt", true):
			return {
				"ok": false,
				"error": "invalid_equipped_belt_slot",
			}
		if not _inventory_slot_ids_are_unique_for_v6(run_state_data, backpack_slots_variant as Array):
			return {
				"ok": false,
				"error": "duplicate_inventory_slot_id",
			}
		if not _backpack_capacity_is_valid_for_v6(run_state_data, backpack_slots_variant as Array):
			return {
				"ok": false,
				"error": "invalid_backpack_capacity",
			}
		if save_schema_version >= PREVIOUS_SAVE_SCHEMA_VERSION:
			var character_perk_state_variant: Variant = run_state_data.get("character_perk_state", null)
			if typeof(character_perk_state_variant) != TYPE_DICTIONARY or not _character_perk_state_is_valid(character_perk_state_variant as Dictionary):
				return {
					"ok": false,
					"error": "invalid_character_perk_state",
				}
			if not SaveValidationCommonScript.equipped_technique_definition_id_is_valid(String(run_state_data.get("equipped_technique_definition_id", "")).strip_edges()):
				return {
					"ok": false,
					"error": "invalid_equipped_technique_definition_id",
				}
	elif save_schema_version >= SHARED_BAG_SAVE_SCHEMA_VERSION:
		var inventory_slots_variant: Variant = run_state_data.get("inventory_slots", null)
		if typeof(inventory_slots_variant) != TYPE_ARRAY or not _inventory_slots_are_valid(inventory_slots_variant as Array):
			return {
				"ok": false,
				"error": "invalid_inventory_slots",
			}
		if not _active_inventory_slot_is_valid(
			run_state_data,
			inventory_slots_variant as Array,
			"active_weapon_slot_id",
			"weapon"
		):
			return {
				"ok": false,
				"error": "invalid_active_weapon_slot",
			}
		if not _active_inventory_slot_is_valid(
			run_state_data,
			inventory_slots_variant as Array,
			"active_armor_slot_id",
			"armor",
			true
		):
			return {
				"ok": false,
				"error": "invalid_active_armor_slot",
			}
		if not _active_inventory_slot_is_valid(
			run_state_data,
			inventory_slots_variant as Array,
			"active_belt_slot_id",
			"belt",
			true
		):
			return {
				"ok": false,
				"error": "invalid_active_belt_slot",
			}
	if save_schema_version < PREVIOUS_SAVE_SCHEMA_VERSION:
		var weapon_variant: Variant = run_state_data.get("weapon_instance", {})
		if typeof(weapon_variant) == TYPE_DICTIONARY and int((weapon_variant as Dictionary).get("current_durability", 0)) < 0:
			return {
				"ok": false,
				"error": "invalid_weapon_durability",
			}
	return {
		"ok": true,
	}


func validate_pending_state_snapshot(
	active_flow_state: int,
	reward_variant: Variant,
	level_up_variant: Variant,
	support_interaction_variant: Variant,
	app_state: Dictionary,
	support_interaction_source_node_is_valid: bool,
	map_node_states: Array = [],
	realized_graph: Array = []
) -> Dictionary:
	match active_flow_state:
		FlowStateScript.Type.MAP_EXPLORE:
			if typeof(reward_variant) != TYPE_NIL or typeof(level_up_variant) != TYPE_NIL or typeof(support_interaction_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_pending_choice_state",
				}
		FlowStateScript.Type.REWARD:
			if typeof(reward_variant) != TYPE_DICTIONARY:
				return {
					"ok": false,
					"error": "missing_reward_state",
				}
			if typeof(level_up_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_level_up_state",
				}
			if typeof(support_interaction_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_support_interaction_state",
				}
			if _extract_offer_count(reward_variant as Dictionary) <= 0:
				return {
					"ok": false,
					"error": "empty_reward_offers",
				}
		FlowStateScript.Type.LEVEL_UP:
			if typeof(level_up_variant) != TYPE_DICTIONARY:
				return {
					"ok": false,
					"error": "missing_level_up_state",
				}
			if typeof(reward_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_reward_state",
				}
			if typeof(support_interaction_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_support_interaction_state",
				}
			if _extract_offer_count(level_up_variant as Dictionary) <= 0:
				return {
					"ok": false,
					"error": "empty_level_up_offers",
				}
		FlowStateScript.Type.SUPPORT_INTERACTION:
			if typeof(support_interaction_variant) != TYPE_DICTIONARY:
				return {
					"ok": false,
					"error": "missing_support_interaction_state",
				}
			if typeof(reward_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_reward_state",
				}
			if typeof(level_up_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_level_up_state",
				}
			var support_interaction_data: Dictionary = support_interaction_variant
			if _extract_offer_count(support_interaction_data) <= 0:
				return {
					"ok": false,
					"error": "empty_support_interaction_offers",
				}
			if not _support_interaction_state_is_valid(support_interaction_data, map_node_states, realized_graph):
				return {
					"ok": false,
					"error": "invalid_support_interaction_state",
				}
			if not support_interaction_source_node_is_valid:
				return {
					"ok": false,
					"error": "invalid_support_interaction_source_node",
				}
		FlowStateScript.Type.STAGE_TRANSITION:
			if typeof(reward_variant) != TYPE_NIL or typeof(level_up_variant) != TYPE_NIL or typeof(support_interaction_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_pending_choice_state",
				}
		FlowStateScript.Type.RUN_END:
			if typeof(reward_variant) != TYPE_NIL or typeof(level_up_variant) != TYPE_NIL or typeof(support_interaction_variant) != TYPE_NIL:
				return {
					"ok": false,
					"error": "unexpected_pending_choice_state",
				}
			var last_run_result: String = String(app_state.get("last_run_result", "")).strip_edges()
			if last_run_result.is_empty():
				return {
					"ok": false,
					"error": "missing_run_result",
				}
			if last_run_result not in ["victory", "defeat"]:
				return {
					"ok": false,
					"error": "invalid_run_result",
				}
		_:
			return {
				"ok": false,
				"error": "unsupported_save_state",
				"active_flow_state": active_flow_state,
			}
	return {
		"ok": true,
	}


func _rng_stream_states_are_valid(stream_states: Dictionary) -> bool:
	for key_variant in stream_states.keys():
		var stream_name: String = String(key_variant).strip_edges()
		if stream_name.is_empty():
			return false
		if int(stream_states.get(key_variant, -1)) < 0:
			return false
	return true


func _character_perk_state_is_valid(character_perk_state: Dictionary) -> bool:
	var owned_perk_ids_variant: Variant = character_perk_state.get("owned_perk_ids", null)
	if typeof(owned_perk_ids_variant) != TYPE_ARRAY:
		return false
	var seen_perk_ids: Dictionary = {}
	for perk_id_variant in owned_perk_ids_variant:
		var perk_id: String = String(perk_id_variant).strip_edges()
		if perk_id.is_empty() or seen_perk_ids.has(perk_id):
			return false
		seen_perk_ids[perk_id] = true
	return true


func _inventory_slots_are_valid(inventory_slots: Array) -> bool:
	var seen_slot_ids: Dictionary = {}
	for entry_variant in inventory_slots:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return false
		var entry: Dictionary = entry_variant
		var slot_id: int = int(entry.get("slot_id", -1))
		if slot_id <= 0 or seen_slot_ids.has(slot_id):
			return false
		seen_slot_ids[slot_id] = true

		var inventory_family: String = String(entry.get("inventory_family", ""))
		if inventory_family not in ["weapon", "shield", "armor", "belt", "consumable", "passive", "quest_item", "shield_attachment"]:
			return false
		if String(entry.get("definition_id", "")).is_empty():
			return false
		if inventory_family == "weapon" and int(entry.get("current_durability", 0)) < 0:
			return false
		if inventory_family in ["weapon", "armor"] and int(entry.get("upgrade_level", 0)) < 0:
			return false
		if inventory_family == "consumable" and int(entry.get("current_stack", 0)) <= 0:
			return false
		if not _shield_attachment_metadata_is_valid(entry, inventory_family):
			return false
	return true


func _equipped_inventory_slot_is_valid(slot_variant: Variant, required_family: Variant, allow_empty: bool = false) -> bool:
	if typeof(slot_variant) != TYPE_DICTIONARY:
		return allow_empty
	var slot: Dictionary = slot_variant as Dictionary
	if slot.is_empty():
		return allow_empty
	if int(slot.get("slot_id", -1)) <= 0:
		return false
	var inventory_family: String = String(slot.get("inventory_family", ""))
	var allowed_families: PackedStringArray = []
	match typeof(required_family):
		TYPE_STRING:
			allowed_families.append(String(required_family))
		TYPE_ARRAY:
			for family_value in required_family:
				allowed_families.append(String(family_value))
		_:
			return false
	if not allowed_families.has(inventory_family):
		return false
	if String(slot.get("definition_id", "")).is_empty():
		return false
	if inventory_family == "weapon" and int(slot.get("current_durability", 0)) < 0:
		return false
	if inventory_family in ["weapon", "armor"] and int(slot.get("upgrade_level", 0)) < 0:
		return false
	if not _shield_attachment_metadata_is_valid(slot, inventory_family):
		return false
	return true


func _inventory_slot_ids_are_unique_for_v6(run_state_data: Dictionary, backpack_slots: Array) -> bool:
	var seen_slot_ids: Dictionary = {}
	for entry_variant in backpack_slots:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return false
		var slot_id: int = int((entry_variant as Dictionary).get("slot_id", -1))
		if slot_id <= 0 or seen_slot_ids.has(slot_id):
			return false
		seen_slot_ids[slot_id] = true

	for key_name in [
		"equipped_right_hand_slot",
		"equipped_left_hand_slot",
		"equipped_armor_slot",
		"equipped_belt_slot",
	]:
		var slot_variant: Variant = run_state_data.get(key_name, {})
		if typeof(slot_variant) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = slot_variant as Dictionary
		if slot.is_empty():
			continue
		var slot_id: int = int(slot.get("slot_id", -1))
		if slot_id <= 0 or seen_slot_ids.has(slot_id):
			return false
		seen_slot_ids[slot_id] = true
	return true


func _backpack_capacity_is_valid_for_v6(run_state_data: Dictionary, backpack_slots: Array) -> bool:
	var equipped_belt_slot_variant: Variant = run_state_data.get("equipped_belt_slot", {})
	var total_capacity: int = 5 + _resolve_equipped_belt_capacity_bonus(equipped_belt_slot_variant)
	return backpack_slots.size() <= total_capacity


func _shield_attachment_metadata_is_valid(slot: Dictionary, inventory_family: String) -> bool:
	if not slot.has("attachment_definition_id"):
		return true
	if inventory_family != "shield":
		return false
	var attachment_definition_id: Variant = slot.get("attachment_definition_id", "")
	return typeof(attachment_definition_id) == TYPE_STRING and not String(attachment_definition_id).strip_edges().is_empty()


func _resolve_equipped_belt_capacity_bonus(slot_variant: Variant) -> int:
	if typeof(slot_variant) != TYPE_DICTIONARY:
		return 0
	var slot: Dictionary = slot_variant as Dictionary
	if slot.is_empty():
		return 0
	var definition_id: String = String(slot.get("definition_id", "")).strip_edges()
	if definition_id.is_empty():
		return 0
	var loader: ContentLoader = ContentLoaderScript.new()
	var belt_definition: Dictionary = loader.load_definition("Belts", definition_id)
	if belt_definition.is_empty():
		return 2
	return max(0, int(belt_definition.get("rules", {}).get("backpack_capacity_bonus", 2)))


func _active_inventory_slot_is_valid(
	run_state_data: Dictionary,
	inventory_slots: Array,
	key_name: String,
	required_family: String,
	allow_empty: bool = false
) -> bool:
	var slot_id: int = int(run_state_data.get(key_name, -1))
	if slot_id < 0:
		return allow_empty
	for entry_variant in inventory_slots:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		if int(entry.get("slot_id", -1)) != slot_id:
			continue
		return String(entry.get("inventory_family", "")) == required_family
	return false


func _extract_offer_count(state_data: Dictionary) -> int:
	var offers_variant: Variant = state_data.get("offers", [])
	if typeof(offers_variant) != TYPE_ARRAY:
		return 0
	return (offers_variant as Array).size()


func _support_interaction_state_is_valid(
	support_interaction_data: Dictionary,
	map_node_states: Array = [],
	realized_graph: Array = []
) -> bool:
	var support_type: String = String(support_interaction_data.get("support_type", ""))
	if support_type not in ["rest", "merchant", "blacksmith", "hamlet", "side_mission"]:
		return false
	if support_type in ["hamlet", "side_mission"]:
		return SaveValidationCommonScript.hamlet_support_interaction_state_is_valid(
			support_interaction_data,
			map_node_states,
			realized_graph
		)
	if support_type != "blacksmith":
		return true

	var blacksmith_view_mode: String = String(support_interaction_data.get("blacksmith_view_mode", "services"))
	if blacksmith_view_mode not in ["services", "weapon_targets", "armor_targets"]:
		return false
	return int(support_interaction_data.get("blacksmith_target_page", 0)) >= 0
