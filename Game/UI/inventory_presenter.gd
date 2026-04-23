# Layer: UI
extends RefCounted
class_name InventoryPresenter

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const ItemDefinitionTooltipBuilderScript = preload("res://Game/UI/item_definition_tooltip_builder.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")

const EQUIPMENT_SLOT_LABELS := {
	InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND: "RIGHT HAND",
	InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND: "LEFT HAND",
	InventoryStateScript.EQUIPMENT_SLOT_ARMOR: "ARMOR",
	InventoryStateScript.EQUIPMENT_SLOT_BELT: "BELT",
}

var _loader: ContentLoader = ContentLoaderScript.new()
var _item_tooltip_builder: ItemDefinitionTooltipBuilder = ItemDefinitionTooltipBuilderScript.new()


func build_equipment_title_text() -> String:
	return "Equipment"


func build_equipment_hint_text(is_combat: bool = false) -> String:
	return (
		"Only packed hand swaps are legal in combat. Swap ends turn. Armor and belt stay locked."
		if is_combat
		else "Tap a slot to equip or unequip. Right/Left hand, armor, and belt stay outside the backpack."
	)


func build_inventory_title_text(inventory_state: InventoryState) -> String:
	if inventory_state == null:
		return "Backpack 0/%d" % InventoryStateScript.BASE_BACKPACK_CAPACITY

	var total_capacity: int = inventory_state.get_total_capacity()
	return "Backpack %d/%d" % [inventory_state.get_used_capacity(), total_capacity]


func build_inventory_drawer_summary_text(inventory_state: InventoryState = null) -> String:
	if inventory_state == null:
		return build_inventory_title_text(null)
	if inventory_state.get_used_capacity() <= 0:
		return "Pack empty"
	return "Carry %d/%d" % [inventory_state.get_used_capacity(), inventory_state.get_total_capacity()]


func build_run_inventory_hint_text(inventory_state: InventoryState = null) -> String:
	if inventory_state != null and inventory_state.get_used_capacity() <= 0:
		return "Pack empty. Pick up what helps."
	return "Food, gear, passives, cargo, and mods."


func build_combat_inventory_hint_text() -> String:
	return "Only consumables work in combat."


func build_run_equipment_cards(run_state: RunState) -> Array[Dictionary]:
	if run_state == null:
		return _build_empty_equipment_cards()
	return _build_equipment_cards(run_state.inventory_state, null)


func build_run_inventory_cards(run_state: RunState) -> Array[Dictionary]:
	if run_state == null:
		return _build_empty_backpack_cards(InventoryStateScript.BASE_BACKPACK_CAPACITY)
	return _build_backpack_cards(run_state.inventory_state, null)


func build_combat_equipment_cards(combat_state: CombatState, inventory_source: Variant = null) -> Array[Dictionary]:
	var inventory_state: InventoryState = _resolve_combat_inventory_state(combat_state, inventory_source)
	if inventory_state == null:
		return _build_empty_equipment_cards(null, combat_state)
	return _build_equipment_cards(inventory_state, combat_state)


func build_combat_inventory_cards(combat_state: CombatState, inventory_source: Variant = null) -> Array[Dictionary]:
	var inventory_state: InventoryState = _resolve_combat_inventory_state(combat_state, inventory_source)
	if inventory_state == null:
		return _build_empty_backpack_cards(InventoryStateScript.BASE_BACKPACK_CAPACITY)
	return _build_backpack_cards(inventory_state, combat_state)


func decorate_card_interaction_state(
	card_model: Dictionary,
	is_combat: bool,
	is_clickable: bool,
	is_selected: bool = false,
	is_draggable: bool = false
) -> Dictionary:
	var decorated_model: Dictionary = card_model
	decorated_model["action_hint_text"] = _build_action_hint_text(card_model, is_combat, is_clickable, is_selected)
	decorated_model["action_hint_tone"] = _build_action_hint_tone(card_model, is_clickable, is_selected)
	decorated_model["compact_mode"] = is_combat
	return decorated_model


func _resolve_combat_inventory_state(combat_state: CombatState, inventory_source: Variant) -> InventoryState:
	if inventory_source is InventoryState:
		return combat_state.build_inventory_projection(inventory_source) if combat_state != null else inventory_source
	if typeof(inventory_source) == TYPE_ARRAY:
		return _build_compat_inventory_state(combat_state, inventory_source as Array)
	return null


func _build_equipment_cards(inventory_state: InventoryState, combat_state: CombatState = null) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for equipment_slot_name in InventoryStateScript.EQUIPMENT_SLOT_NAMES:
		var slot: Dictionary = inventory_state.build_equipment_slot_snapshot(equipment_slot_name)
		if slot.is_empty():
			cards.append(_build_empty_equipment_card(equipment_slot_name, inventory_state, combat_state))
			continue
		cards.append(_build_populated_card(slot, inventory_state, combat_state, _equipment_slot_label(equipment_slot_name), -1, true))
	return cards


func _build_backpack_cards(inventory_state: InventoryState, combat_state: CombatState = null) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	if inventory_state == null:
		return _build_empty_backpack_cards(InventoryStateScript.BASE_BACKPACK_CAPACITY)

	var total_capacity: int = inventory_state.get_total_capacity()
	var combat_consumable_index_by_slot_id: Dictionary = _build_combat_consumable_index_by_slot_id(combat_state, inventory_state)
	for slot_index in range(total_capacity):
		if slot_index < inventory_state.inventory_slots.size():
			var slot: Dictionary = inventory_state.inventory_slots[slot_index]
			cards.append(
				_build_populated_card(
					slot,
					inventory_state,
					combat_state,
					"PACK %d" % (slot_index + 1),
					slot_index,
					false,
					combat_consumable_index_by_slot_id
				)
			)
		else:
			cards.append(_build_empty_backpack_card(slot_index))
	return cards


func _build_empty_equipment_cards(inventory_state: InventoryState = null, combat_state: CombatState = null) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for equipment_slot_name in InventoryStateScript.EQUIPMENT_SLOT_NAMES:
		cards.append(_build_empty_equipment_card(equipment_slot_name, inventory_state, combat_state))
	return cards


func _build_empty_backpack_cards(card_count: int) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for slot_index in range(card_count):
		cards.append(_build_empty_backpack_card(slot_index))
	return cards


func _build_compat_inventory_state(combat_state: CombatState, passive_slot_list: Array) -> InventoryState:
	if combat_state == null:
		return null
	# Legacy test shim only: hydrate a throwaway InventoryState view from combat-local
	# compatibility fields, but do not push the hydrated slot ids back into CombatState.
	var inventory_state: InventoryState = InventoryStateScript.new()
	inventory_state.set_weapon_instance(combat_state.weapon_instance)
	inventory_state.set_left_hand_instance(combat_state.left_hand_instance)
	inventory_state.set_armor_instance(combat_state.armor_instance)
	inventory_state.set_belt_instance(combat_state.belt_instance)
	inventory_state.set_consumable_slots(combat_state.consumable_slots)
	inventory_state.set_passive_slots(passive_slot_list)
	return inventory_state


func _build_populated_card(
	slot: Dictionary,
	inventory_state: InventoryState,
	combat_state: CombatState,
	slot_label: String,
	backpack_slot_index: int,
	is_equipment_slot: bool,
	combat_consumable_index_by_slot_id: Dictionary = {}
) -> Dictionary:
	var inventory_family: String = String(slot.get("inventory_family", ""))
	match inventory_family:
		InventoryStateScript.INVENTORY_FAMILY_WEAPON:
			return _build_weapon_card(slot, slot_label, backpack_slot_index, is_equipment_slot, combat_state)
		InventoryStateScript.INVENTORY_FAMILY_SHIELD:
			return _build_shield_card(slot, slot_label, backpack_slot_index, is_equipment_slot)
		InventoryStateScript.INVENTORY_FAMILY_ARMOR:
			return _build_armor_card(slot, slot_label, backpack_slot_index, is_equipment_slot)
		InventoryStateScript.INVENTORY_FAMILY_BELT:
			return _build_belt_card(slot, slot_label, backpack_slot_index, is_equipment_slot)
		InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
			return _build_consumable_card(slot, slot_label, backpack_slot_index, combat_consumable_index_by_slot_id)
		InventoryStateScript.INVENTORY_FAMILY_PASSIVE:
			return _build_passive_card(slot, slot_label, backpack_slot_index)
		InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
			return _build_quest_item_card(slot, slot_label, backpack_slot_index)
		InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
			return _build_shield_attachment_card(slot, slot_label, backpack_slot_index)
		_:
			return _build_empty_equipment_card(InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND) if is_equipment_slot else _build_empty_backpack_card(backpack_slot_index)


func _build_empty_equipment_card(
	equipment_slot_name: String,
	inventory_state: InventoryState = null,
	combat_state: CombatState = null
) -> Dictionary:
	var title_text: String = "Open Slot"
	var detail_text: String = _build_empty_equipment_detail_text(equipment_slot_name, inventory_state, combat_state)
	return _build_card_model(
		"empty",
		_equipment_slot_label(equipment_slot_name),
		-1,
		-1,
		title_text,
		detail_text,
		"",
		"",
		detail_text,
		TempScreenThemeScript.PANEL_BORDER_COLOR.darkened(0.18),
		false
	)


func _build_empty_equipment_detail_text(
	equipment_slot_name: String,
	inventory_state: InventoryState = null,
	combat_state: CombatState = null
) -> String:
	if combat_state != null:
		match equipment_slot_name:
			InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND:
				return "Swap packed spare." if _has_eligible_combat_hand_spare(inventory_state, equipment_slot_name) else "No spare weapon."
			InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND:
				return "Swap packed spare." if _has_eligible_combat_hand_spare(inventory_state, equipment_slot_name) else "No spare shield/offhand."
			InventoryStateScript.EQUIPMENT_SLOT_ARMOR:
				return "Armor locked."
			InventoryStateScript.EQUIPMENT_SLOT_BELT:
				return "Belt locked."

	match equipment_slot_name:
		InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND:
			return "Equip weapon."
		InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND:
			return "Equip shield or offhand."
		InventoryStateScript.EQUIPMENT_SLOT_ARMOR:
			return "Equip armor."
		InventoryStateScript.EQUIPMENT_SLOT_BELT:
			return "Equip belt for pack space."
	return ""


func _has_eligible_combat_hand_spare(inventory_state: InventoryState, equipment_slot_name: String) -> bool:
	if inventory_state == null:
		return false
	if equipment_slot_name != InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND and equipment_slot_name != InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND:
		return false
	for slot in inventory_state.inventory_slots:
		if inventory_state.slot_can_equip_to(slot, equipment_slot_name):
			return true
	return false

func _build_empty_backpack_card(slot_index: int) -> Dictionary:
	var slot_label: String = "PACK %d" % (slot_index + 1)
	return _build_card_model(
		"empty",
		slot_label,
		slot_index,
		-1,
		"Open Slot",
		"",
		"",
		"",
		"Open backpack slot.",
		TempScreenThemeScript.PANEL_BORDER_COLOR.darkened(0.18),
		false
	)


func _build_weapon_card(
	slot: Dictionary,
	slot_label: String,
	backpack_slot_index: int,
	is_equipment_slot: bool,
	combat_state: CombatState
) -> Dictionary:
	var definition_id: String = String(slot.get("definition_id", ""))
	var definition: Dictionary = _load_definition("Weapons", definition_id)
	var stats: Dictionary = definition.get("rules", {}).get("stats", {})
	var current_durability: int = int(slot.get("current_durability", 0))
	if combat_state != null and is_equipment_slot and int(slot.get("slot_id", -1)) == int(combat_state.active_weapon_slot_id):
		current_durability = int(combat_state.weapon_instance.get("current_durability", current_durability))
	var max_durability: int = max(1, int(stats.get("max_durability", current_durability)))
	var upgrade_level: int = _extract_upgrade_level(slot)
	var base_damage: int = int(stats.get("base_damage", 0)) + (upgrade_level * InventoryStateScript.WEAPON_UPGRADE_ATTACK_BONUS_PER_LEVEL)
	return _build_card_model(
		InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		slot_label,
		backpack_slot_index,
		int(slot.get("slot_id", -1)),
		_build_item_display_name(definition, definition_id, slot),
		("EQUIPPED | " if is_equipment_slot else "") + ("BROKEN" if current_durability <= 0 else "DMG %d" % base_damage),
		"%d/%d" % [current_durability, max_durability],
		UiAssetPathsScript.WEAPON_ICON_TEXTURE_PATH,
		_item_tooltip_builder.build_definition_tooltip_text(
			InventoryStateScript.INVENTORY_FAMILY_WEAPON,
			definition_id,
			1,
			_build_equipment_toggle_hint(is_equipment_slot, combat_state),
			slot
		),
		TempScreenThemeScript.RUST_ACCENT_COLOR,
		is_equipment_slot
	)

func _build_armor_card(slot: Dictionary, slot_label: String, backpack_slot_index: int, is_equipment_slot: bool) -> Dictionary:
	var definition_id: String = String(slot.get("definition_id", ""))
	var definition: Dictionary = _load_definition("Armors", definition_id)
	var summary: Dictionary = _build_modifier_summary(definition, false, {
		"incoming_damage_flat_reduction": _extract_upgrade_level(slot) * InventoryStateScript.ARMOR_UPGRADE_DEFENSE_BONUS_PER_LEVEL,
	})
	return _build_card_model(
		InventoryStateScript.INVENTORY_FAMILY_ARMOR,
		slot_label,
		backpack_slot_index,
		int(slot.get("slot_id", -1)),
		_build_item_display_name(definition, definition_id, slot),
		("EQUIPPED | " if is_equipment_slot else "") + String(summary.get("short_text", "Armor")),
		"EQP" if is_equipment_slot else "",
		UiAssetPathsScript.ARMOR_ICON_TEXTURE_PATH,
		_item_tooltip_builder.build_definition_tooltip_text(
			InventoryStateScript.INVENTORY_FAMILY_ARMOR,
			definition_id,
			1,
			_build_equipment_toggle_hint(is_equipment_slot, null),
			slot
		),
		TempScreenThemeScript.TEAL_ACCENT_COLOR,
		is_equipment_slot
	)


func _build_shield_card(slot: Dictionary, slot_label: String, backpack_slot_index: int, is_equipment_slot: bool) -> Dictionary:
	var definition_id: String = String(slot.get("definition_id", ""))
	var definition: Dictionary = _load_definition("Shields", definition_id)
	var attachment_definition_id: String = String(slot.get(InventoryStateScript.SHIELD_ATTACHMENT_ID_KEY, "")).strip_edges()
	var attachment_definition: Dictionary = _load_definition("ShieldAttachments", attachment_definition_id)
	var attachment_name: String = _load_display_name(attachment_definition, attachment_definition_id) if not attachment_definition.is_empty() else ""
	return _build_card_model(
		InventoryStateScript.INVENTORY_FAMILY_SHIELD,
		slot_label,
		backpack_slot_index,
		int(slot.get("slot_id", -1)),
		_build_item_display_name(definition, definition_id, slot),
		("EQUIPPED | " if is_equipment_slot else "") + ("DEFEND BOOST | MOD" if not attachment_name.is_empty() else "DEFEND BOOST"),
		"MOD" if not attachment_name.is_empty() else ("EQP" if is_equipment_slot else ""),
		UiAssetPathsScript.SHIELD_ICON_TEXTURE_PATH,
		_item_tooltip_builder.build_definition_tooltip_text(
			InventoryStateScript.INVENTORY_FAMILY_SHIELD,
			definition_id,
			1,
			_build_equipment_toggle_hint(is_equipment_slot, null),
			slot
		),
		TempScreenThemeScript.TEAL_ACCENT_COLOR,
		is_equipment_slot,
		-1,
		{"has_attachment": not attachment_name.is_empty()}
	)


func _build_belt_card(slot: Dictionary, slot_label: String, backpack_slot_index: int, is_equipment_slot: bool) -> Dictionary:
	var definition_id: String = String(slot.get("definition_id", ""))
	var definition: Dictionary = _load_definition("Belts", definition_id)
	var belt_capacity_bonus: int = _extract_belt_capacity_bonus(definition)
	var summary: Dictionary = _build_modifier_summary(definition, true, {}, belt_capacity_bonus)
	return _build_card_model(
		InventoryStateScript.INVENTORY_FAMILY_BELT,
		slot_label,
		backpack_slot_index,
		int(slot.get("slot_id", -1)),
		_build_item_display_name(definition, definition_id, slot),
		("EQUIPPED | " if is_equipment_slot else "") + String(summary.get("short_text", "+2 INV")),
		"EQP" if is_equipment_slot else "",
		UiAssetPathsScript.BELT_ICON_TEXTURE_PATH,
		_item_tooltip_builder.build_definition_tooltip_text(
			InventoryStateScript.INVENTORY_FAMILY_BELT,
			definition_id,
			1,
			_build_equipment_toggle_hint(is_equipment_slot, null),
			slot
		),
		TempScreenThemeScript.PANEL_BORDER_COLOR,
		is_equipment_slot
	)


func _build_consumable_card(
	slot: Dictionary,
	slot_label: String,
	backpack_slot_index: int,
	combat_consumable_index_by_slot_id: Dictionary
) -> Dictionary:
	var definition_id: String = String(slot.get("definition_id", ""))
	var current_stack: int = int(slot.get("current_stack", 0))
	var definition: Dictionary = _load_definition("Consumables", definition_id)
	var profile: Dictionary = _extract_consumable_profile(definition)
	var inventory_slot_id: int = int(slot.get("slot_id", -1))
	return _build_card_model(
		InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE,
		slot_label,
		backpack_slot_index,
		inventory_slot_id,
		_build_item_display_name(definition, definition_id, slot),
		String(profile.get("short_text", "Item")),
		"x%d" % current_stack,
		UiAssetPathsScript.CONSUMABLE_ICON_TEXTURE_PATH,
		_item_tooltip_builder.build_definition_tooltip_text(
			InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE,
			definition_id,
			current_stack,
			_build_consumable_use_hint(combat_consumable_index_by_slot_id.has(inventory_slot_id)),
			slot
		),
		TempScreenThemeScript.REWARD_ACCENT_COLOR,
		false,
		int(combat_consumable_index_by_slot_id.get(inventory_slot_id, -1))
	)


func _build_passive_card(slot: Dictionary, slot_label: String, backpack_slot_index: int) -> Dictionary:
	var definition_id: String = String(slot.get("definition_id", ""))
	var definition: Dictionary = _load_definition("PassiveItems", definition_id)
	var summary: Dictionary = _build_modifier_summary(definition, false)
	return _build_card_model(
		InventoryStateScript.INVENTORY_FAMILY_PASSIVE,
		slot_label,
		backpack_slot_index,
		int(slot.get("slot_id", -1)),
		_build_item_display_name(definition, definition_id, slot),
		String(summary.get("short_text", "Passive")),
		"",
		UiAssetPathsScript.PASSIVE_ICON_TEXTURE_PATH,
		_item_tooltip_builder.build_definition_tooltip_text(
			InventoryStateScript.INVENTORY_FAMILY_PASSIVE,
			definition_id,
			1,
			"",
			slot
		),
		TempScreenThemeScript.TEAL_ACCENT_COLOR,
		false
	)


func _build_quest_item_card(slot: Dictionary, slot_label: String, backpack_slot_index: int) -> Dictionary:
	var definition_id: String = String(slot.get("definition_id", ""))
	var definition: Dictionary = _load_definition("QuestItems", definition_id)
	return _build_card_model(
		InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM,
		slot_label,
		backpack_slot_index,
		int(slot.get("slot_id", -1)),
		_build_item_display_name(definition, definition_id, slot),
		"QUEST ITEM",
		"",
		UiAssetPathsScript.QUEST_ITEM_ICON_TEXTURE_PATH,
		_item_tooltip_builder.build_definition_tooltip_text(
			InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM,
			definition_id,
			1,
			"",
			slot
		),
		TempScreenThemeScript.REWARD_ACCENT_COLOR,
		false
	)


func _build_shield_attachment_card(slot: Dictionary, slot_label: String, backpack_slot_index: int) -> Dictionary:
	var definition_id: String = String(slot.get("definition_id", ""))
	var definition: Dictionary = _load_definition("ShieldAttachments", definition_id)
	var summary: Dictionary = _build_modifier_summary(definition, false)
	return _build_card_model(
		InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT,
		slot_label,
		backpack_slot_index,
		int(slot.get("slot_id", -1)),
		_build_item_display_name(definition, definition_id, slot),
		String(summary.get("short_text", "Shield Mod")),
		"",
		UiAssetPathsScript.SHIELD_ATTACHMENT_ICON_TEXTURE_PATH,
		_item_tooltip_builder.build_definition_tooltip_text(
			InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT,
			definition_id,
			1,
			"",
			slot
		),
		TempScreenThemeScript.TEAL_ACCENT_COLOR,
		false
	)


func _build_combat_consumable_index_by_slot_id(combat_state: CombatState, inventory_state: InventoryState = null) -> Dictionary:
	var result: Dictionary = {}
	if combat_state == null:
		return result
	var consumable_slots: Array[Dictionary] = inventory_state.consumable_slots if inventory_state != null else combat_state.consumable_slots
	for index in range(consumable_slots.size()):
		var slot: Dictionary = consumable_slots[index]
		result[int(slot.get("slot_id", -1))] = index
	return result


func _equipment_slot_label(equipment_slot_name: String) -> String:
	return String(EQUIPMENT_SLOT_LABELS.get(equipment_slot_name, equipment_slot_name.to_upper()))


func _build_card_name(slot_label: String, backpack_slot_index: int) -> String:
	if backpack_slot_index >= 0:
		return "InventorySlot%dCard" % (backpack_slot_index + 1)
	return "InventorySlot%sCard" % slot_label.replace(" ", "")


func _build_card_model(
	card_family: String,
	slot_label: String,
	backpack_slot_index: int,
	inventory_slot_id: int,
	title_text: String,
	detail_text: String,
	count_text: String,
	icon_texture_path: String,
	tooltip_text: String,
	accent_color: Color,
	is_equipped: bool,
	slot_index: int = -1,
	extra_fields: Dictionary = {}
) -> Dictionary:
	var card_model := {
		"card_name": _build_card_name(slot_label, backpack_slot_index),
		"card_family": card_family,
		"slot_index": slot_index,
		"inventory_slot_index": backpack_slot_index,
		"inventory_slot_id": inventory_slot_id,
		"slot_label": slot_label,
		"title_text": title_text,
		"detail_text": detail_text,
		"count_text": count_text,
		"icon_texture_path": icon_texture_path,
		"tooltip_text": tooltip_text,
		"accent_color": accent_color,
		"is_equipped": is_equipped,
	}
	for key in extra_fields.keys():
		card_model[key] = extra_fields[key]
	return card_model


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

	var short_fragments: PackedStringArray = []
	var long_fragments: PackedStringArray = []
	if heal_amount > 0:
		short_fragments.append("+%d HP" % heal_amount)
		long_fragments.append("Heals %d HP." % heal_amount)
	if hunger_restore > 0:
		short_fragments.append("+%d H" % hunger_restore)
		long_fragments.append("Restores hunger by %d." % hunger_restore)
	if repairs_weapon:
		short_fragments.append("REPAIR")
		long_fragments.append("Repairs the active weapon to full durability.")

	return {
		"short_text": " | ".join(short_fragments),
		"long_text": " ".join(long_fragments),
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

	var short_fragments: PackedStringArray = []
	var long_fragments: PackedStringArray = []
	if include_belt_capacity_bonus:
		short_fragments.append("+%d INV" % max(0, belt_capacity_bonus))
		long_fragments.append("Adds %d backpack slots while equipped." % max(0, belt_capacity_bonus))

	for stat_name in [
		"attack_power_bonus",
		"incoming_damage_flat_reduction",
		"durability_cost_flat_reduction",
	]:
		var total_amount: int = int(modifier_totals.get(stat_name, 0))
		if total_amount == 0:
			continue
		var summary: Dictionary = _build_modifier_text(stat_name, total_amount)
		var short_text: String = String(summary.get("short_text", ""))
		var long_text: String = String(summary.get("long_text", ""))
		if not short_text.is_empty():
			short_fragments.append(short_text)
		if not long_text.is_empty():
			long_fragments.append(long_text)

	return {
		"short_text": " | ".join(short_fragments),
		"long_text": " ".join(long_fragments),
	}


func _build_modifier_text(stat_name: String, amount: int) -> Dictionary:
	match stat_name:
		"attack_power_bonus":
			return {
				"short_text": "%+d ATK" % amount,
				"long_text": "Adds %d attack power in combat." % amount,
			}
		"incoming_damage_flat_reduction":
			return {
				"short_text": "-%d DMG" % amount,
				"long_text": "Reduces incoming damage by %d." % amount,
			}
		"durability_cost_flat_reduction":
			return {
				"short_text": "-%d DUR" % amount,
				"long_text": "Reduces attack durability cost by %d." % amount,
			}
		_:
			return {
				"short_text": "",
				"long_text": "",
			}


func _load_definition(family: String, definition_id: String) -> Dictionary:
	if definition_id.is_empty():
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


func _extract_upgrade_level(slot: Dictionary) -> int:
	return max(0, int(slot.get("upgrade_level", 0)))


func _build_equipment_toggle_hint(is_equipped: bool, combat_state: CombatState) -> String:
	if combat_state != null:
		return "Only packed hand swaps are legal in combat. Swap ends turn. Armor and belt stay locked."
	return "Click to unequip." if is_equipped else "Click to equip."


func _build_consumable_use_hint(is_combat_card: bool) -> String:
	return "Click in combat to use now. This ends your turn." if is_combat_card else "Click to use now."


func _build_action_hint_text(
	card_model: Dictionary,
	is_combat: bool,
	is_clickable: bool,
	is_selected: bool
) -> String:
	var combat_action_hint_override: String = String(card_model.get("combat_action_hint_override", "")).strip_edges()
	if is_combat and not combat_action_hint_override.is_empty():
		return combat_action_hint_override
	var card_family: String = String(card_model.get("card_family", ""))
	var is_equipped: bool = bool(card_model.get("is_equipped", false))
	match card_family:
		InventoryStateScript.INVENTORY_FAMILY_WEAPON, InventoryStateScript.INVENTORY_FAMILY_SHIELD:
			if is_combat:
				return "Packed spare needed" if is_equipped else "Use Hand Swap panel"
			if card_family == InventoryStateScript.INVENTORY_FAMILY_SHIELD and is_equipped and bool(card_model.get("has_attachment", false)):
				return "Tap to detach mod"
			if is_clickable:
				return "Tap to unequip" if is_equipped else "Tap to equip"
			return "Stored"
		InventoryStateScript.INVENTORY_FAMILY_ARMOR, InventoryStateScript.INVENTORY_FAMILY_BELT:
			if is_combat:
				return "Armor and belt stay locked"
			if is_clickable:
				return "Tap to unequip" if is_equipped else "Tap to equip"
			return "Stored"
		InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
			if is_clickable:
				if is_combat:
					return "Ends turn" if is_selected else "Tap to use"
				return "Tap to use"
			return "No HP or hunger gain right now"
		InventoryStateScript.INVENTORY_FAMILY_PASSIVE:
			return "Active while carried | not a perk"
		InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
			return "Quest cargo"
		InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
			if is_combat:
				return "Shield mods stay locked"
			if is_clickable:
				return "Tap to attach to equipped shield"
			return "Requires equipped shield"
		_:
			return ""


func _build_action_hint_tone(card_model: Dictionary, is_clickable: bool, is_selected: bool) -> String:
	var card_family: String = String(card_model.get("card_family", ""))
	if is_selected:
		return "selected"
	if is_clickable:
		return "interactive"
	if card_family == "empty":
		return "muted"
	if card_family == InventoryStateScript.INVENTORY_FAMILY_PASSIVE:
		return "passive"
	return "disabled"


func _extract_belt_capacity_bonus(definition: Dictionary) -> int:
	return max(0, int(definition.get("rules", {}).get("backpack_capacity_bonus", InventoryStateScript.DEFAULT_BELT_BACKPACK_CAPACITY_BONUS)))
