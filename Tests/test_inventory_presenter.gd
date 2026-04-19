# Layer: Tests
extends SceneTree
class_name TestInventoryPresenter

const InventoryPresenterScript = preload("res://Game/UI/inventory_presenter.gd")
const ItemDefinitionTooltipBuilderScript = preload("res://Game/UI/item_definition_tooltip_builder.gd")
const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")


func _init() -> void:
	test_run_inventory_cards_split_equipment_and_backpack()
	test_run_inventory_cards_surface_quest_cargo_and_shield_mods()
	test_inventory_cards_use_family_specific_icon_paths()
	test_inventory_interaction_hints_explain_backpack_and_equipment_actions()
	test_combat_inventory_cards_follow_combat_local_stacks()
	test_combat_inventory_cards_follow_combat_local_equipment_projection()
	test_definition_tooltips_surface_offer_item_details()
	print("test_inventory_presenter: all assertions passed")
	quit()


func test_run_inventory_cards_split_equipment_and_backpack() -> void:
	var presenter: RefCounted = InventoryPresenterScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.inventory_state.weapon_instance["current_durability"] = 11
	run_state.inventory_state.weapon_instance["upgrade_level"] = 2
	run_state.inventory_state.set_armor_instance({"definition_id": "watcher_mail", "upgrade_level": 1})
	run_state.inventory_state.set_belt_instance({"definition_id": "trailhook_bandolier"})
	run_state.inventory_state.set_consumable_slots([
		{"definition_id": "wild_berries", "current_stack": 2},
		{"definition_id": "minor_heal_potion", "current_stack": 1},
	])
	run_state.inventory_state.set_passive_slots([
		{"definition_id": "iron_grip_charm"},
	])

	var equipment_cards: Array[Dictionary] = presenter.call("build_run_equipment_cards", run_state)
	var backpack_cards: Array[Dictionary] = presenter.call("build_run_inventory_cards", run_state)

	assert(equipment_cards.size() == 4, "Expected four explicit equipment cards.")
	assert(String(equipment_cards[0].get("slot_label", "")) == "RIGHT HAND", "Expected the first equipment slot to be the right hand.")
	assert(String(equipment_cards[0].get("title_text", "")) == "Iron Sword +2", "Expected equipped right-hand weapon display name.")
	assert(String(equipment_cards[0].get("count_text", "")) == "11/20", "Expected equipped right-hand weapon durability to stay visible.")
	assert(String(equipment_cards[0].get("detail_text", "")).begins_with("EQUIPPED |"), "Expected equipment cards to mark equipped gear.")
	assert(String(equipment_cards[1].get("slot_label", "")) == "LEFT HAND", "Expected the second equipment slot to be left hand.")
	assert(String(equipment_cards[1].get("title_text", "")) == "Open Slot", "Expected empty left hand slot placeholder.")
	assert(String(equipment_cards[2].get("title_text", "")) == "Watcher Mail +1", "Expected armor slot to resolve equipped armor.")
	assert(String(equipment_cards[3].get("detail_text", "")).contains("+2 INV"), "Expected belt slot to expose backpack utility.")
	assert(
		String(presenter.call("build_inventory_title_text", run_state.inventory_state)) == "Backpack 3/7",
		"Expected backpack title text to keep the original used/total format when a belt adds capacity."
	)

	assert(backpack_cards.size() == 7, "Expected backpack cards to expand to 7 slots while a belt adds 2 capacity.")
	assert(String(backpack_cards[0].get("slot_label", "")) == "PACK 1", "Expected backpack cards to use PACK slot labels.")
	assert(String(backpack_cards[0].get("card_family", "")) == "consumable", "Expected the first carried slot to stay consumable.")
	assert(String(backpack_cards[0].get("count_text", "")) == "x2", "Expected carried consumables to preserve stack counts.")
	assert(String(backpack_cards[1].get("title_text", "")) == "Minor Heal Potion", "Expected backpack to show later carried consumables.")
	assert(String(backpack_cards[2].get("title_text", "")) == "Thorn Grip Charm", "Expected passive items to stay in the backpack section.")
	assert(String(backpack_cards[2].get("detail_text", "")) == "+1 ATK", "Expected passive items to summarize combat bonus.")
	assert(String(backpack_cards[6].get("title_text", "")) == "Open Slot", "Expected unused backpack capacity to show open slots.")


func test_run_inventory_cards_surface_quest_cargo_and_shield_mods() -> void:
	var presenter: RefCounted = InventoryPresenterScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.inventory_state.set_left_hand_instance({
		"definition_id": "weathered_buckler",
		"inventory_family": InventoryState.INVENTORY_FAMILY_SHIELD,
		"attachment_definition_id": "reinforced_rim_lining",
	})
	var inventory_snapshot: Dictionary = run_state.inventory_state.to_save_dict()
	var backpack_slots: Array = inventory_snapshot.get("backpack_slots", []).duplicate(true)
	var next_slot_id: int = int(inventory_snapshot.get("inventory_next_slot_id", 1))
	backpack_slots.append({
		"slot_id": next_slot_id,
		"inventory_family": InventoryState.INVENTORY_FAMILY_QUEST_ITEM,
		"definition_id": "hamlet_seal",
	})
	next_slot_id += 1
	backpack_slots.append({
		"slot_id": next_slot_id,
		"inventory_family": InventoryState.INVENTORY_FAMILY_SHIELD_ATTACHMENT,
		"definition_id": "reinforced_rim_lining",
	})
	inventory_snapshot["backpack_slots"] = backpack_slots
	inventory_snapshot["inventory_next_slot_id"] = next_slot_id + 1
	run_state.inventory_state.load_from_flat_save_dict(inventory_snapshot)

	var equipment_cards: Array[Dictionary] = presenter.call("build_run_equipment_cards", run_state)
	var backpack_cards: Array[Dictionary] = presenter.call("build_run_inventory_cards", run_state)
	assert(String(equipment_cards[1].get("title_text", "")) == "Weathered Buckler", "Expected the equipped left-hand shield to render through the explicit shield slot.")
	assert(bool(equipment_cards[1].get("has_attachment", false)), "Expected shield cards to expose attached shield-mod state.")
	assert(String(equipment_cards[1].get("tooltip_text", "")).contains("Reinforced Rim Lining"), "Expected shield tooltips to surface the attached shield mod name.")
	assert(String(backpack_cards[1].get("card_family", "")) == InventoryState.INVENTORY_FAMILY_QUEST_ITEM, "Expected quest cargo to stay in the backpack section with its own family.")
	assert(String(backpack_cards[1].get("detail_text", "")) == "QUEST ITEM", "Expected quest cargo cards to avoid normal-loot labeling.")
	assert(String(backpack_cards[2].get("card_family", "")) == InventoryState.INVENTORY_FAMILY_SHIELD_ATTACHMENT, "Expected detached shield mods to render as their own backpack item family.")
	var decorated_attachment_card: Dictionary = presenter.call("decorate_card_interaction_state", backpack_cards[2], false, true, false, false)
	assert(String(decorated_attachment_card.get("action_hint_text", "")).contains("attach"), "Expected shield-mod cards to explain their attach affordance on the map screen.")


func test_inventory_cards_use_family_specific_icon_paths() -> void:
	var presenter: RefCounted = InventoryPresenterScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.inventory_state.set_left_hand_instance({
		"definition_id": "weathered_buckler",
		"inventory_family": InventoryState.INVENTORY_FAMILY_SHIELD,
		"attachment_definition_id": "reinforced_rim_lining",
	})
	run_state.inventory_state.set_armor_instance({"definition_id": "watcher_mail"})
	run_state.inventory_state.set_belt_instance({"definition_id": "trailhook_bandolier"})
	run_state.inventory_state.set_passive_slots([
		{"definition_id": "iron_grip_charm"},
	])
	var inventory_snapshot: Dictionary = run_state.inventory_state.to_save_dict()
	var backpack_slots: Array = inventory_snapshot.get("backpack_slots", []).duplicate(true)
	var next_slot_id: int = int(inventory_snapshot.get("inventory_next_slot_id", 1))
	backpack_slots.append({
		"slot_id": next_slot_id,
		"inventory_family": InventoryState.INVENTORY_FAMILY_QUEST_ITEM,
		"definition_id": "hamlet_seal",
	})
	next_slot_id += 1
	backpack_slots.append({
		"slot_id": next_slot_id,
		"inventory_family": InventoryState.INVENTORY_FAMILY_SHIELD_ATTACHMENT,
		"definition_id": "reinforced_rim_lining",
	})
	inventory_snapshot["backpack_slots"] = backpack_slots
	inventory_snapshot["inventory_next_slot_id"] = next_slot_id + 1
	run_state.inventory_state.load_from_flat_save_dict(inventory_snapshot)

	var equipment_cards: Array[Dictionary] = presenter.call("build_run_equipment_cards", run_state)
	var backpack_cards: Array[Dictionary] = presenter.call("build_run_inventory_cards", run_state)
	var backpack_cards_by_family: Dictionary = {}
	for card in backpack_cards:
		var family: String = String(card.get("card_family", ""))
		if family.is_empty():
			continue
		backpack_cards_by_family[family] = card

	assert(String(equipment_cards[0].get("icon_texture_path", "")) == "res://Assets/Icons/icon_weapon.svg", "Expected equipped right-hand weapons to keep the dedicated weapon icon.")
	assert(String(equipment_cards[1].get("icon_texture_path", "")) == "res://Assets/Icons/icon_shield.svg", "Expected left-hand shields to use the dedicated shield icon.")
	assert(String(equipment_cards[2].get("icon_texture_path", "")) == "res://Assets/Icons/icon_armor.svg", "Expected armor cards to use the dedicated armor icon.")
	assert(String(equipment_cards[3].get("icon_texture_path", "")) == "res://Assets/Icons/icon_belt.svg", "Expected belt cards to use the dedicated belt icon.")
	assert(String(backpack_cards_by_family.get(InventoryState.INVENTORY_FAMILY_PASSIVE, {}).get("icon_texture_path", "")) == "res://Assets/Icons/icon_passive.svg", "Expected passive cards to stop reusing the generic reward icon.")
	assert(String(backpack_cards_by_family.get(InventoryState.INVENTORY_FAMILY_QUEST_ITEM, {}).get("icon_texture_path", "")) == "res://Assets/Icons/icon_quest_item.svg", "Expected quest cargo cards to use a dedicated quest-item icon.")
	assert(String(backpack_cards_by_family.get(InventoryState.INVENTORY_FAMILY_SHIELD_ATTACHMENT, {}).get("icon_texture_path", "")) == "res://Assets/Icons/icon_shield_attachment.svg", "Expected detached shield mods to use a dedicated shield-attachment icon.")


func test_inventory_interaction_hints_explain_backpack_and_equipment_actions() -> void:
	var presenter: RefCounted = InventoryPresenterScript.new()
	assert(
		String(presenter.call("build_equipment_hint_text", false)).contains("equip or unequip")
		and String(presenter.call("build_equipment_hint_text", false)).contains("outside the backpack"),
		"Expected run equipment hint to keep the original equip/unequip and backpack-separation wording."
	)
	assert(
		String(presenter.call("build_run_inventory_hint_text")).contains("passives"),
		"Expected run backpack hint to explain carried item families."
	)
	assert(
		String(presenter.call("build_combat_inventory_hint_text")).contains("Only consumables"),
		"Expected combat backpack hint to explain that gear and backpack order are locked in combat."
	)

	var equipped_weapon_card: Dictionary = {
		"card_family": "weapon",
		"is_equipped": true,
	}
	var map_hint_card: Dictionary = presenter.call("decorate_card_interaction_state", equipped_weapon_card, false, true, false, false)
	assert(
		String(map_hint_card.get("action_hint_text", "")).contains("Tap to unequip"),
		"Expected equipped map gear to explain tap-to-unequip affordance."
	)

	var combat_consumable_card: Dictionary = {
		"card_family": "consumable",
	}
	var combat_hint_card: Dictionary = presenter.call("decorate_card_interaction_state", combat_consumable_card, true, true, true, true)
	assert(
		String(combat_hint_card.get("action_hint_text", "")).contains("Ends turn"),
		"Expected combat consumables to explain turn-spending taps."
	)
	assert(
		String(combat_hint_card.get("action_hint_tone", "")) == "selected",
		"Expected the selected combat consumable to expose the selected action-hint tone."
	)


func test_combat_inventory_cards_follow_combat_local_stacks() -> void:
	var presenter: RefCounted = InventoryPresenterScript.new()
	var combat_state: CombatState = CombatState.new()
	combat_state.weapon_instance = {"definition_id": "iron_sword", "current_durability": 7}
	combat_state.armor_instance = {"definition_id": "watcher_mail"}
	combat_state.belt_instance = {"definition_id": "trailhook_bandolier"}
	combat_state.consumable_slots = [
		{"definition_id": "traveler_bread", "current_stack": 1},
	]

	var passive_slots: Array[Dictionary] = [
		{"definition_id": "iron_grip_charm"},
	]
	var equipment_cards: Array[Dictionary] = presenter.call("build_combat_equipment_cards", combat_state, passive_slots)
	var backpack_cards: Array[Dictionary] = presenter.call("build_combat_inventory_cards", combat_state, passive_slots)
	assert(String(equipment_cards[0].get("count_text", "")) == "7/20", "Expected combat equipment to use combat-local durability instead of stale run values.")
	assert(String(backpack_cards[0].get("title_text", "")) == "Traveler Bread", "Expected combat backpack to keep the active consumable stack visible.")
	assert(String(backpack_cards[0].get("card_family", "")) == "consumable", "Expected combat backpack cards to keep the consumable family metadata.")
	assert(int(backpack_cards[0].get("slot_index", -1)) == 0, "Expected combat consumable cards to preserve slot indices for scene-side selection.")
	assert(String(backpack_cards[0].get("tooltip_text", "")).contains("x1 | max 3"), "Expected consumable tooltip to expose live stack and cap in compact form.")
	assert(String(backpack_cards[0].get("tooltip_text", "")).contains("Click in combat to use now."), "Expected combat consumables to explain the direct-click use interaction.")
	assert(String(backpack_cards[1].get("title_text", "")) == "Thorn Grip Charm", "Expected carried passives to remain in the backpack section.")
	assert(String(backpack_cards[6].get("title_text", "")) == "Open Slot", "Expected later backpack lanes to keep open-slot labels.")


func test_combat_inventory_cards_follow_combat_local_equipment_projection() -> void:
	var presenter: RefCounted = InventoryPresenterScript.new()
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	var replace_result: Dictionary = inventory_actions.replace_active_weapon(run_state.inventory_state, "splitter_axe")
	assert(bool(replace_result.get("ok", false)), "Expected a replacement active weapon for combat equip projection coverage.")

	var combat_state: CombatState = CombatState.new()
	combat_state.active_weapon_slot_id = int(run_state.inventory_state.active_weapon_slot_id)
	combat_state.active_armor_slot_id = int(run_state.inventory_state.active_armor_slot_id)
	combat_state.active_belt_slot_id = int(run_state.inventory_state.active_belt_slot_id)
	combat_state.weapon_instance = run_state.inventory_state.weapon_instance.duplicate(true)
	combat_state.weapon_instance["current_durability"] = 4
	combat_state.armor_instance = run_state.inventory_state.armor_instance.duplicate(true)
	combat_state.belt_instance = run_state.inventory_state.belt_instance.duplicate(true)
	combat_state.consumable_slots = run_state.inventory_state.consumable_slots.duplicate(true)

	var equipment_cards: Array[Dictionary] = presenter.call("build_combat_equipment_cards", combat_state, run_state.inventory_state)
	var backpack_cards: Array[Dictionary] = presenter.call("build_combat_inventory_cards", combat_state, run_state.inventory_state)
	var splitter_axe_card: Dictionary = equipment_cards[0]
	var iron_sword_card: Dictionary = {}
	for card in backpack_cards:
		if String(card.get("title_text", "")) == "Iron Sword":
			iron_sword_card = card
			break
	assert(String(splitter_axe_card.get("title_text", "")) == "Splitter Axe", "Expected projected combat equipment to keep the combat-local right-hand weapon.")
	assert(String(splitter_axe_card.get("detail_text", "")).begins_with("EQUIPPED |"), "Expected projected combat equipment to keep the right-hand slot marked equipped.")
	assert(String(splitter_axe_card.get("count_text", "")) == "4/14", "Expected projected combat equipment to surface combat-local weapon durability.")
	assert(not iron_sword_card.is_empty(), "Expected projected combat backpack to keep the displaced starter weapon visible.")
	assert(String(iron_sword_card.get("tooltip_text", "")).contains("Equipment is locked during combat."), "Expected carried weapons to explain the combat lock instead of an equip interaction.")


func test_definition_tooltips_surface_offer_item_details() -> void:
	var tooltip_builder: RefCounted = ItemDefinitionTooltipBuilderScript.new()
	var weapon_tooltip: String = tooltip_builder.call(
		"build_definition_tooltip_text",
		InventoryState.INVENTORY_FAMILY_WEAPON,
		"iron_sword",
		1,
		"Claim this reward to add it to the backpack."
	)
	assert(weapon_tooltip.contains("Iron Sword"), "Expected definition tooltip builder to include the item name.")
	assert(weapon_tooltip.contains("DMG 6"), "Expected weapon offer tooltip to expose base damage in compact form.")
	assert(weapon_tooltip.contains("DUR 20/20"), "Expected weapon offer tooltip to default to max durability for fresh rewards.")

	var consumable_tooltip: String = tooltip_builder.call(
		"build_definition_tooltip_text",
		InventoryState.INVENTORY_FAMILY_CONSUMABLE,
		"traveler_bread",
		2,
		"Pack this find."
	)
	assert(consumable_tooltip.contains("Traveler Bread"), "Expected consumable offer tooltip to include the item name.")
	assert(consumable_tooltip.contains("H +"), "Expected consumable offer tooltip to include compact effect details.")
	assert(consumable_tooltip.contains("x2 | max"), "Expected consumable offer tooltip to include the incoming stack amount in compact form.")
