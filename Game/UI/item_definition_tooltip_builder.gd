# Layer: UI
extends RefCounted
class_name ItemDefinitionTooltipBuilder

const CombatResolverScript = preload("res://Game/Core/combat_resolver.gd")
const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")

var _loader: ContentLoader = ContentLoaderScript.new()


func build_definition_display_name(
	inventory_family: String,
	definition_id: String,
	slot_overrides: Dictionary = {}
) -> String:
	var normalized_inventory_family: String = String(inventory_family).strip_edges()
	var normalized_definition_id: String = String(definition_id).strip_edges()
	if normalized_inventory_family.is_empty() or normalized_definition_id.is_empty():
		return normalized_definition_id

	var definition_family: String = _definition_family_for_inventory_family(normalized_inventory_family)
	var definition: Dictionary = _load_definition(definition_family, normalized_definition_id)
	if definition.is_empty():
		return normalized_definition_id

	var slot: Dictionary = slot_overrides.duplicate(true)
	slot["definition_id"] = normalized_definition_id
	return _build_item_display_name(definition, normalized_definition_id, slot)


func build_definition_summary_text(
	inventory_family: String,
	definition_id: String,
	amount: int = 1,
	slot_overrides: Dictionary = {}
) -> String:
	var normalized_inventory_family: String = String(inventory_family).strip_edges()
	var normalized_definition_id: String = String(definition_id).strip_edges()
	if normalized_inventory_family.is_empty() or normalized_definition_id.is_empty():
		return ""

	var definition_family: String = _definition_family_for_inventory_family(normalized_inventory_family)
	var definition: Dictionary = _load_definition(definition_family, normalized_definition_id)
	if definition.is_empty():
		return ""

	var slot: Dictionary = slot_overrides.duplicate(true)
	slot["definition_id"] = normalized_definition_id
	var profile_lines: PackedStringArray = _build_item_profile_lines(normalized_inventory_family, definition, slot, amount)
	if profile_lines.is_empty():
		return ""
	var summary_text: String = String(profile_lines[0]).strip_edges()
	if normalized_inventory_family == InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
		return _join_compact_fragments(["x%d" % max(1, amount), summary_text])
	return summary_text


func build_definition_tooltip_text(
	inventory_family: String,
	definition_id: String,
	amount: int = 1,
	lead_text: String = "",
	slot_overrides: Dictionary = {}
) -> String:
	var normalized_inventory_family: String = String(inventory_family).strip_edges()
	var normalized_definition_id: String = String(definition_id).strip_edges()
	var trimmed_lead_text: String = lead_text.strip_edges()
	var lines: PackedStringArray = []
	if normalized_inventory_family.is_empty() or normalized_definition_id.is_empty():
		if not trimmed_lead_text.is_empty():
			lines.append(trimmed_lead_text)
		return _join_tooltip_lines(lines)

	var definition_family: String = _definition_family_for_inventory_family(normalized_inventory_family)
	var definition: Dictionary = _load_definition(definition_family, normalized_definition_id)
	if definition.is_empty():
		lines.append(normalized_definition_id)
		return _join_tooltip_lines(lines)

	var slot: Dictionary = slot_overrides.duplicate(true)
	slot["definition_id"] = normalized_definition_id
	var display_name: String = _build_item_display_name(definition, normalized_definition_id, slot)
	lines.append(display_name)
	if not trimmed_lead_text.is_empty():
		lines.append(trimmed_lead_text)

	for line_text in _build_item_profile_lines(normalized_inventory_family, definition, slot, amount):
		lines.append(line_text)

	return _join_tooltip_lines(lines)


func _build_item_profile_lines(inventory_family: String, definition: Dictionary, slot: Dictionary, amount: int) -> PackedStringArray:
	var lines: PackedStringArray = []
	match inventory_family:
		InventoryStateScript.INVENTORY_FAMILY_WEAPON:
			var stats: Dictionary = definition.get("rules", {}).get("stats", {})
			var upgrade_level: int = _extract_upgrade_level(slot)
			var max_durability: int = max(1, int(stats.get("max_durability", 1)))
			var current_durability: int = max(0, int(slot.get("current_durability", max_durability)))
			var base_damage: int = int(stats.get("base_damage", 0)) + (upgrade_level * InventoryStateScript.WEAPON_UPGRADE_ATTACK_BONUS_PER_LEVEL)
			lines.append("DMG %d | DUR %d/%d" % [base_damage, current_durability, max_durability])
			var durability_profile: String = CombatResolverScript.resolve_weapon_durability_profile(definition)
			var durability_cost: int = CombatResolverScript.resolve_weapon_base_durability_cost(definition)
			if durability_cost > 0:
				lines.append("%s | %d DUR/use" % [_format_durability_profile_label(durability_profile), durability_cost])
		InventoryStateScript.INVENTORY_FAMILY_SHIELD:
			var attachment_definition_id: String = String(slot.get(InventoryStateScript.SHIELD_ATTACHMENT_ID_KEY, "")).strip_edges()
			var attachment_definition: Dictionary = _load_definition("ShieldAttachments", attachment_definition_id)
			var attachment_name: String = _load_display_name(attachment_definition, attachment_definition_id) if not attachment_definition.is_empty() else ""
			var attachment_summary: Dictionary = _build_modifier_summary(attachment_definition, false) if not attachment_definition.is_empty() else {}
			lines.append("Shield | Guard first")
			if not attachment_name.is_empty():
				lines.append("Mod: %s" % attachment_name)
				var attachment_compact_text: String = String(attachment_summary.get("compact_text", "")).strip_edges()
				if not attachment_compact_text.is_empty():
					lines.append(attachment_compact_text)
		InventoryStateScript.INVENTORY_FAMILY_ARMOR:
			var armor_bonus_modifiers: Dictionary = {
				"incoming_damage_flat_reduction": _extract_upgrade_level(slot) * InventoryStateScript.ARMOR_UPGRADE_DEFENSE_BONUS_PER_LEVEL,
			}
			var armor_summary: Dictionary = _build_modifier_summary(definition, false, armor_bonus_modifiers)
			lines.append(_join_compact_fragments(["Armor", String(armor_summary.get("compact_text", ""))]))
		InventoryStateScript.INVENTORY_FAMILY_BELT:
			var belt_capacity_bonus: int = _extract_belt_capacity_bonus(definition)
			var belt_summary: Dictionary = _build_modifier_summary(definition, true, {}, belt_capacity_bonus)
			lines.append(_join_compact_fragments(["Belt", String(belt_summary.get("compact_text", ""))]))
		InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
			var consumable_profile: Dictionary = _extract_consumable_profile(definition)
			var max_stack: int = max(1, int(consumable_profile.get("max_stack", max(1, amount))))
			var current_stack: int = int(slot.get("current_stack", 0))
			lines.append(String(consumable_profile.get("compact_text", "")))
			if current_stack > 0:
				lines.append("x%d | max %d" % [current_stack, max_stack])
			else:
				lines.append("x%d | max %d" % [max(1, amount), max_stack])
		InventoryStateScript.INVENTORY_FAMILY_PASSIVE:
			var passive_summary: Dictionary = _build_modifier_summary(definition, false)
			lines.append(_join_compact_fragments([
				"Passive",
				String(passive_summary.get("compact_text", "")),
			]))
		InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
			lines.append("Quest cargo")
		InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
			var attachment_summary_only: Dictionary = _build_modifier_summary(definition, false)
			lines.append(_join_compact_fragments([
				"Shield mod",
				String(attachment_summary_only.get("compact_text", "")),
			]))
	return lines


func _extract_consumable_profile(definition: Dictionary) -> Dictionary:
	var rules: Dictionary = definition.get("rules", {})
	var stats: Dictionary = rules.get("stats", {})
	var use_effect: Dictionary = rules.get("use_effect", {})
	var heal_amount: int = 0
	var hunger_restore: int = 0
	var repairs_weapon: bool = false
	var effects: Array = use_effect.get("effects", [])
	for effect_value in effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		var params: Dictionary = effect.get("params", {})
		match String(effect.get("type", "")):
			"heal":
				heal_amount += int(params.get("base", 0))
			"modify_hunger":
				hunger_restore += max(0, -int(params.get("amount", 0)))
			"repair_weapon":
				repairs_weapon = true

	var compact_fragments: PackedStringArray = []
	if heal_amount > 0:
		compact_fragments.append("HP +%d" % heal_amount)
	if hunger_restore > 0:
		compact_fragments.append("H +%d" % hunger_restore)
	if repairs_weapon:
		compact_fragments.append("Full repair")

	return {
		"compact_text": " | ".join(compact_fragments),
		"max_stack": int(stats.get("max_stack", 0)),
	}


func _build_modifier_summary(definition: Dictionary, include_belt_capacity_bonus: bool, bonus_modifiers: Dictionary = {}, belt_capacity_bonus: int = 0) -> Dictionary:
	var modifier_totals: Dictionary = {}
	var behaviors: Array = definition.get("rules", {}).get("behaviors", [])
	for behavior_value in behaviors:
		if typeof(behavior_value) != TYPE_DICTIONARY:
			continue
		var behavior: Dictionary = behavior_value
		var effects: Array = behavior.get("effects", [])
		for effect_value in effects:
			if typeof(effect_value) != TYPE_DICTIONARY:
				continue
			var effect: Dictionary = effect_value
			if String(effect.get("type", "")) != "modify_stat":
				continue
			var params: Dictionary = effect.get("params", {})
			var stat_name: String = String(params.get("stat", ""))
			if stat_name.is_empty():
				continue
			modifier_totals[stat_name] = int(modifier_totals.get(stat_name, 0)) + int(params.get("amount", 0))

	for stat_name_variant in bonus_modifiers.keys():
		var stat_name: String = String(stat_name_variant)
		if stat_name.is_empty():
			continue
		modifier_totals[stat_name] = int(modifier_totals.get(stat_name, 0)) + int(bonus_modifiers.get(stat_name_variant, 0))

	var compact_fragments: PackedStringArray = []
	if include_belt_capacity_bonus:
		compact_fragments.append("+%d pack slots" % max(0, belt_capacity_bonus))

	for stat_name in [
		"attack_power_bonus",
		"incoming_damage_flat_reduction",
		"durability_cost_flat_reduction",
	]:
		var total_amount: int = int(modifier_totals.get(stat_name, 0))
		if total_amount == 0:
			continue
		var summary: Dictionary = _build_modifier_text(stat_name, total_amount)
		var compact_text: String = String(summary.get("compact_text", ""))
		if not compact_text.is_empty():
			compact_fragments.append(compact_text)

	return {
		"compact_text": " | ".join(compact_fragments),
	}


func _build_modifier_text(stat_name: String, amount: int) -> Dictionary:
	match stat_name:
		"attack_power_bonus":
			return {
				"compact_text": "+%d ATK" % amount,
			}
		"incoming_damage_flat_reduction":
			return {
				"compact_text": "-%d DMG" % amount,
			}
		"durability_cost_flat_reduction":
			return {
				"compact_text": "-%d DUR/use" % amount,
			}
		_:
			return {
				"compact_text": "",
			}


func _load_definition(family: String, definition_id: String) -> Dictionary:
	if family.is_empty() or definition_id.is_empty():
		return {}
	return _loader.load_definition(family, definition_id)


func _load_display_name(definition: Dictionary, fallback_id: String) -> String:
	return String(definition.get("display", {}).get("name", fallback_id))


func _build_item_display_name(definition: Dictionary, fallback_id: String, slot: Dictionary) -> String:
	var display_name: String = _load_display_name(definition, fallback_id)
	var upgrade_level: int = _extract_upgrade_level(slot)
	if upgrade_level <= 0:
		return display_name
	return "%s +%d" % [display_name, upgrade_level]


func _format_durability_profile_label(profile: String) -> String:
	match profile:
		"sturdy":
			return "Sturdy"
		"fragile":
			return "Fragile"
		"heavy":
			return "Heavy"
		_:
			return "Standard"


func _extract_upgrade_level(slot: Dictionary) -> int:
	return max(0, int(slot.get("upgrade_level", 0)))


func _join_tooltip_lines(parts: Array) -> String:
	var filtered: PackedStringArray = []
	for part_value in parts:
		var part: String = String(part_value).strip_edges()
		if not part.is_empty():
			filtered.append(part)
	return "\n".join(filtered)


func _join_compact_fragments(parts: Array) -> String:
	var filtered: PackedStringArray = []
	for part_value in parts:
		var part: String = String(part_value).strip_edges()
		if not part.is_empty():
			filtered.append(part)
	return " | ".join(filtered)


func _extract_belt_capacity_bonus(definition: Dictionary) -> int:
	return max(0, int(definition.get("rules", {}).get("backpack_capacity_bonus", InventoryStateScript.DEFAULT_BELT_BACKPACK_CAPACITY_BONUS)))


func _definition_family_for_inventory_family(inventory_family: String) -> String:
	match inventory_family:
		InventoryStateScript.INVENTORY_FAMILY_WEAPON:
			return "Weapons"
		InventoryStateScript.INVENTORY_FAMILY_SHIELD:
			return "Shields"
		InventoryStateScript.INVENTORY_FAMILY_ARMOR:
			return "Armors"
		InventoryStateScript.INVENTORY_FAMILY_BELT:
			return "Belts"
		InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
			return "Consumables"
		InventoryStateScript.INVENTORY_FAMILY_PASSIVE:
			return "PassiveItems"
		InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
			return "ShieldAttachments"
		InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
			return "QuestItems"
		_:
			return ""
