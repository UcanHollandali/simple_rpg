# Layer: Tests
extends SceneTree
class_name TestInventoryPresenter

const InventoryPresenterScript = preload("res://Game/UI/inventory_presenter.gd")
const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")


func _init() -> void:
	test_run_inventory_cards_expose_equipment_and_tooltips()
	test_inventory_interaction_hints_explain_map_and_combat_actions()
	test_combat_inventory_cards_follow_combat_local_stacks()
	test_combat_inventory_cards_follow_combat_local_equipment_projection()
	print("test_inventory_presenter: all assertions passed")
	quit()


func test_run_inventory_cards_expose_equipment_and_tooltips() -> void:
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

	var cards: Array[Dictionary] = presenter.call("build_run_inventory_cards", run_state)
	assert(cards.size() == 7, "Expected shared inventory cards to expand to 7 slots while an equipped belt adds 2 capacity.")
	assert(String(cards[0].get("card_family", "")) == "weapon", "Expected weapon card metadata to keep the stable weapon family.")
	assert(String(cards[0].get("title_text", "")) == "Iron Sword +2", "Expected run inventory to surface forged weapon display names.")
	assert(String(cards[0].get("count_text", "")) == "11/20", "Expected weapon card to show live durability.")
	assert(String(cards[0].get("tooltip_text", "")).contains("Damage 8"), "Expected weapon tooltip to describe forged weapon stats.")
	assert(String(cards[0].get("tooltip_text", "")).contains("Forge bonus +2 attack."), "Expected weapon tooltip to expose forge bonus text.")
	assert(String(cards[1].get("detail_text", "")) == "EQUIPPED | -2 DMG", "Expected armor card to expose upgraded mitigation summary and equipped-state read.")
	assert(String(cards[1].get("count_text", "")) == "EQP", "Expected equipped armor card to expose a compact equipped marker.")
	assert(String(cards[2].get("detail_text", "")).contains("+2 INV"), "Expected belt card to expose the shared-inventory bonus.")
	assert(String(cards[2].get("detail_text", "")).contains("-1 DUR"), "Expected belt card to keep its compact durability-help summary.")
	assert(String(cards[2].get("tooltip_text", "")).contains("Click to unequip."), "Expected active belt tooltip copy to explain map-side unequip interaction.")
	assert(String(cards[3].get("slot_label", "")) == "INV 4", "Expected the first consumable to live in the fourth shared inventory slot.")
	assert(String(cards[3].get("card_family", "")) == "consumable", "Expected consumable cards to keep stable family metadata for scene-side selection logic.")
	assert(int(cards[3].get("slot_index", -1)) == -1, "Expected run inventory cards to avoid combat-only consumable selection indices.")
	assert(String(cards[3].get("count_text", "")) == "x2", "Expected consumable cards to expose live stack counts.")
	assert(String(cards[3].get("tooltip_text", "")).contains("Click to use now."), "Expected run inventory consumables to explain the direct-click use interaction.")
	assert(String(cards[3].get("detail_text", "")).contains("+4 HP"), "Expected consumable detail text to summarize heal output.")
	assert(String(cards[5].get("title_text", "")) == "Thorn Grip Charm", "Expected passive cards to resolve authored display names.")
	assert(String(cards[5].get("detail_text", "")) == "+1 ATK", "Expected passive cards to show compact combat bonus summary.")
	assert(String(cards[6].get("title_text", "")) == "Open Slot", "Expected unused shared inventory capacity to keep a single open-slot label.")
	assert(String(cards[6].get("detail_text", "")) == "", "Expected unused shared inventory capacity to avoid duplicate empty-slot copy.")


func test_inventory_interaction_hints_explain_map_and_combat_actions() -> void:
	var presenter: RefCounted = InventoryPresenterScript.new()
	assert(
		String(presenter.call("build_run_inventory_hint_text")).contains("Tap gear to equip"),
		"Expected map inventory guidance copy to explain tap-to-equip interaction."
	)
	assert(
		String(presenter.call("build_combat_inventory_hint_text")).contains("spend your turn"),
		"Expected combat inventory guidance copy to explain turn-spending taps."
	)

	var equipped_weapon_card: Dictionary = {
		"card_family": "weapon",
		"is_equipped": true,
	}
	var map_hint_card: Dictionary = presenter.call("decorate_card_interaction_state", equipped_weapon_card, false, true, false, true)
	assert(
		String(map_hint_card.get("action_hint_text", "")).contains("Tap to unequip"),
		"Expected equipped map gear to explain the tap-to-unequip affordance."
	)
	assert(
		not String(map_hint_card.get("action_hint_text", "")).contains("Drag to sort"),
		"Expected map gear not to suggest drag-to-sort in this UI variant."
	)

	var combat_consumable_card: Dictionary = {
		"card_family": "consumable",
	}
	var combat_hint_card: Dictionary = presenter.call("decorate_card_interaction_state", combat_consumable_card, true, true, true, true)
	assert(
		String(combat_hint_card.get("action_hint_text", "")).contains("Ends turn"),
		"Expected combat consumables to explain the turn-spending tap affordance."
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
	var cards: Array[Dictionary] = presenter.call("build_combat_inventory_cards", combat_state, passive_slots)
	assert(String(cards[0].get("count_text", "")) == "7/20", "Expected combat inventory to use combat-local durability instead of stale run values.")
	assert(String(cards[3].get("title_text", "")) == "Traveler Bread", "Expected combat inventory to keep the active consumable stack visible.")
	assert(String(cards[3].get("card_family", "")) == "consumable", "Expected combat inventory cards to keep the consumable family metadata.")
	assert(int(cards[3].get("slot_index", -1)) == 0, "Expected combat consumable cards to preserve slot indices for scene-side selection.")
	assert(String(cards[3].get("tooltip_text", "")).contains("Current stack 1/3"), "Expected consumable tooltip to expose live stack and cap.")
	assert(String(cards[3].get("tooltip_text", "")).contains("Click in combat to use now."), "Expected combat consumables to explain the turn-spending direct-click use interaction.")
	assert(String(cards[4].get("title_text", "")) == "Thorn Grip Charm", "Expected combat inventory compatibility path to keep carried passives visible in the shared inventory.")
	assert(String(cards[6].get("title_text", "")) == "Open Slot", "Expected later shared inventory lanes to keep a single open-slot label.")
	assert(String(cards[6].get("detail_text", "")) == "", "Expected later shared inventory lanes to avoid duplicate empty-slot copy.")


func test_combat_inventory_cards_follow_combat_local_equipment_projection() -> void:
	var presenter: RefCounted = InventoryPresenterScript.new()
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	var replace_result: Dictionary = inventory_actions.replace_active_weapon(run_state.inventory_state, "splitter_axe")
	assert(bool(replace_result.get("ok", false)), "Expected a carried backup weapon for combat equip projection coverage.")

	var carried_weapon_slot_id: int = -1
	for slot in run_state.inventory_state.inventory_slots:
		if String(slot.get("inventory_family", "")) != InventoryState.INVENTORY_FAMILY_WEAPON:
			continue
		if int(slot.get("slot_id", -1)) == int(run_state.inventory_state.active_weapon_slot_id):
			continue
		carried_weapon_slot_id = int(slot.get("slot_id", -1))
		break

	assert(carried_weapon_slot_id > 0, "Expected a non-active carried weapon slot for combat projection coverage.")
	var combat_state: CombatState = CombatState.new()
	combat_state.active_weapon_slot_id = carried_weapon_slot_id
	combat_state.active_armor_slot_id = int(run_state.inventory_state.active_armor_slot_id)
	combat_state.active_belt_slot_id = int(run_state.inventory_state.active_belt_slot_id)
	combat_state.weapon_instance = run_state.inventory_state.inventory_slots[run_state.inventory_state.find_slot_index_by_id(carried_weapon_slot_id)].duplicate(true)
	combat_state.weapon_instance["current_durability"] = 4
	combat_state.armor_instance = run_state.inventory_state.armor_instance.duplicate(true)
	combat_state.belt_instance = run_state.inventory_state.belt_instance.duplicate(true)
	combat_state.consumable_slots = run_state.inventory_state.consumable_slots.duplicate(true)

	var cards: Array[Dictionary] = presenter.call("build_combat_inventory_cards", combat_state, run_state.inventory_state)
	var iron_sword_card: Dictionary = {}
	var splitter_axe_card: Dictionary = {}
	for card in cards:
		match String(card.get("title_text", "")):
			"Iron Sword":
				iron_sword_card = card
			"Splitter Axe":
				splitter_axe_card = card
	assert(not iron_sword_card.is_empty(), "Expected projected combat inventory to keep the carried starter weapon visible.")
	assert(not splitter_axe_card.is_empty(), "Expected projected combat inventory to keep the non-active backup weapon visible.")
	assert(String(iron_sword_card.get("detail_text", "")).begins_with("EQUIPPED |"), "Expected projected combat inventory to mark the combat-local equipped weapon as equipped.")
	assert(String(iron_sword_card.get("count_text", "")) == "4/20", "Expected projected combat inventory to surface combat-local weapon durability on the active carried weapon.")
	assert(String(splitter_axe_card.get("tooltip_text", "")).contains("Click in combat to equip."), "Expected non-active carried weapons to explain the combat equip interaction in tooltip copy.")
