# Layer: Tests
extends SceneTree
class_name TestCombatSpike

const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")

var _combat_end_signal_count: int = 0


func _init() -> void:
	test_player_attack_reduces_enemy_hp()
	test_durability_reduces_on_attack()
	test_enemy_defeat_check()
	test_fallback_attack_when_weapon_breaks()
	test_content_loader_loads_weapon()
	test_new_run_inventory_uses_authored_starter_loadout()
	test_resolver_updated_weapon_state_flows_into_combat_state()
	test_turn_end_hunger_tick_and_intent_progression()
	test_resolve_attack_turn_runs_enemy_and_turn_end_sequence()
	test_resolve_use_item_turn_stops_when_no_usable_item_exists()
	test_brace_halves_enemy_damage_for_current_turn()
	test_preview_snapshot_surfaces_readability_numbers()
	test_use_item_heals_and_consumes_stack()
	test_use_item_reduces_hunger_when_food_is_used_at_full_hp()
	test_use_item_uses_first_usable_stack_when_front_slot_cannot_change_state()
	test_use_item_can_resolve_an_explicit_selected_slot()
	test_change_equipment_turn_swaps_carried_weapon_and_consumes_turn()
	test_change_equipment_turn_can_unequip_active_weapon_and_fall_back()
	test_change_equipment_turn_swaps_carried_armor_and_enemy_still_hits()
	test_passive_attack_bonus_applies_in_combat()
	test_armor_damage_reduction_applies_in_combat()
	test_belt_durability_reduction_applies_in_combat()
	test_inventory_actions_repair_weapon_resets_to_max_durability()
	test_inventory_actions_block_belt_unequip_when_capacity_would_overflow()
	test_inventory_actions_move_slot_to_index_reorders_shared_inventory()
	test_inventory_actions_can_upgrade_non_active_carried_weapon_slot()
	test_inventory_actions_can_upgrade_non_active_carried_armor_slot()
	test_inventory_actions_add_and_remove_consumable_stack()
	test_inventory_actions_replaces_oldest_non_active_item_when_shared_inventory_is_full()
	test_inventory_actions_replace_active_armor_and_belt()
	test_combat_reorder_inventory_slot_persists_without_spending_turn()
	test_upgraded_weapon_adds_attack_power_in_combat()
	test_upgraded_armor_adds_defense_in_combat()
	test_weapon_durability_persists_across_three_combats()
	test_combat_end_signal_emits_once()
	print("test_combat_spike: all assertions passed")
	quit()


func test_player_attack_reduces_enemy_hp() -> void:
	var flow: CombatFlow = _build_flow(20)
	var result: Dictionary = flow.process_player_attack()
	assert(int(result.get("damage_applied", 0)) == 5, "Expected iron sword damage 6 reduced by enemy armor 1.")
	assert(flow.combat_state.enemy_hp == 19, "Expected enemy HP to drop from 24 to 19.")


func test_durability_reduces_on_attack() -> void:
	var flow: CombatFlow = _build_flow(20)
	flow.process_player_attack()
	assert(int(flow.combat_state.weapon_instance.get("current_durability", -1)) == 19, "Expected durability to drop by 1.")


func test_enemy_defeat_check() -> void:
	var resolver: CombatResolver = CombatResolver.new()
	assert(resolver.check_defeat({"hp": 0}), "Expected 0 HP to count as defeat.")
	assert(not resolver.check_defeat({"hp": 1}), "Expected positive HP to remain alive.")


func test_fallback_attack_when_weapon_breaks() -> void:
	var flow: CombatFlow = _build_flow(0)
	var result: Dictionary = flow.process_player_attack()
	assert(bool(result.get("used_fallback_attack", false)), "Expected fallback attack when durability is already 0.")
	assert(int(result.get("damage_applied", 0)) == 1, "Expected fallback attack to deal 1 damage.")
	assert(flow.combat_state.enemy_hp == 23, "Expected fallback attack to reduce enemy HP from 24 to 23.")


func test_content_loader_loads_weapon() -> void:
	var loader: ContentLoader = ContentLoader.new()
	var weapon_def: Dictionary = loader.load_definition("Weapons", "iron_sword")
	assert(not weapon_def.is_empty(), "Expected ContentLoader to return a weapon definition.")
	assert(String(weapon_def.get("definition_id", "")) == "iron_sword", "Expected loaded weapon stable ID to match.")
	assert(String(weapon_def.get("family", "")) == "Weapons", "Expected loaded weapon family to match.")


func test_new_run_inventory_uses_authored_starter_loadout() -> void:
	var loader: ContentLoader = ContentLoader.new()
	var starter_loadout: Dictionary = loader.load_definition("RunLoadouts", "starter_loadout")
	var starter_rules: Dictionary = starter_loadout.get("rules", {})
	var authored_consumable_slots: Array = starter_rules.get("consumable_slots", [])
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()

	assert(
		String(run_state.inventory_state.weapon_instance.get("definition_id", "")) == String(starter_rules.get("weapon_definition_id", "")),
		"Expected new-run weapon instance to come from the authored starter loadout."
	)
	assert(
		run_state.inventory_state.consumable_slots.size() == authored_consumable_slots.size(),
		"Expected new-run consumable slot count to come from the authored starter loadout."
	)
	assert(
		String(run_state.inventory_state.consumable_slots[0].get("definition_id", "")) == String((authored_consumable_slots[0] as Dictionary).get("definition_id", "")),
		"Expected starter consumable definition to come from the authored starter loadout."
	)
	assert(
		int(run_state.inventory_state.consumable_slots[0].get("current_stack", -1)) == int((authored_consumable_slots[0] as Dictionary).get("current_stack", -2)),
		"Expected starter consumable stack count to come from the authored starter loadout."
	)


func test_resolver_updated_weapon_state_flows_into_combat_state() -> void:
	var flow: CombatFlow = _build_flow(20)
	var result: Dictionary = flow.process_player_attack()
	var updated_weapon_state: Dictionary = result.get("updated_weapon_state", {})
	assert(not updated_weapon_state.is_empty(), "Expected resolver to return updated_weapon_state.")
	assert(
		int(updated_weapon_state.get("current_durability", -1)) == int(flow.combat_state.weapon_instance.get("current_durability", -2)),
		"Expected combat_state.weapon_instance to mirror resolver updated_weapon_state."
	)
	assert(
		int(flow.combat_state.player_state.get("hp", -1)) == flow.combat_state.player_hp,
		"Expected player_state HP mirror to remain synced."
	)


func test_turn_end_hunger_tick_and_intent_progression() -> void:
	var flow: CombatFlow = _build_flow(20)
	var initial_intent_id: String = String(flow.combat_state.current_intent.get("intent_id", ""))
	var turn_end: Dictionary = flow.process_turn_end()
	assert(int(turn_end.get("player_hunger", -1)) == RunState.DEFAULT_HUNGER - 1, "Expected turn-end hunger tick to spend 1 hunger from the full reserve.")
	assert(flow.combat_state.player_hunger == RunState.DEFAULT_HUNGER - 1, "Expected combat_state hunger to stay synced.")
	assert(flow.combat_state.current_turn == 2, "Expected current_turn to increment at turn end.")
	assert(
		String(flow.combat_state.current_intent.get("intent_id", "")) != initial_intent_id,
		"Expected intent progression to advance to the next intent."
	)


func test_resolve_attack_turn_runs_enemy_and_turn_end_sequence() -> void:
	var flow: CombatFlow = _build_flow(20)
	var full_turn_result: Dictionary = flow.resolve_attack_turn()
	var action_result: Dictionary = full_turn_result.get("action_result", {})
	var enemy_result: Dictionary = full_turn_result.get("enemy_result", {})
	var turn_end_result: Dictionary = full_turn_result.get("turn_end_result", {})
	assert(int(action_result.get("damage_applied", -1)) == 5, "Expected full attack turn to keep player attack resolution.")
	assert(int(enemy_result.get("damage_applied", -1)) == 5, "Expected full attack turn to include enemy follow-up resolution.")
	assert(int(turn_end_result.get("player_hunger", -1)) == RunState.DEFAULT_HUNGER - 1, "Expected full attack turn to include turn-end hunger drain.")
	assert(flow.combat_state.player_hp == 25, "Expected full attack turn to leave the player at post-enemy-hit HP.")
	assert(flow.combat_state.current_turn == 2, "Expected full attack turn to advance the combat turn.")


func test_resolve_use_item_turn_stops_when_no_usable_item_exists() -> void:
	var flow: CombatFlow = _build_flow(20)
	flow.combat_state.player_hp = RunState.DEFAULT_PLAYER_HP
	flow.combat_state.player_state["hp"] = RunState.DEFAULT_PLAYER_HP
	var full_turn_result: Dictionary = flow.resolve_use_item_turn()
	var action_result: Dictionary = full_turn_result.get("action_result", {})
	assert(bool(action_result.get("skipped", false)), "Expected full use-item turn to stop when no consumable would change HP or hunger.")
	assert(not full_turn_result.has("enemy_result"), "Expected skipped use-item turn not to resolve enemy follow-up.")
	assert(not full_turn_result.has("turn_end_result"), "Expected skipped use-item turn not to advance into turn end.")
	assert(flow.combat_state.current_turn == 1, "Expected skipped use-item turn not to advance the combat turn.")
	assert(flow.combat_state.player_hunger == RunState.DEFAULT_HUNGER, "Expected skipped use-item turn not to tick hunger.")


func test_brace_halves_enemy_damage_for_current_turn() -> void:
	var flow: CombatFlow = _build_flow(20)
	var brace_result: Dictionary = flow.process_brace()
	assert(not bool(brace_result.get("skipped", true)), "Expected brace action to resolve.")
	assert(flow.combat_state.brace_active, "Expected brace flag to activate before enemy action.")
	var enemy_result: Dictionary = flow.process_enemy_action()
	assert(bool(enemy_result.get("brace_applied", false)), "Expected brace to apply on the incoming hit.")
	assert(int(enemy_result.get("brace_reduced_damage_from", -1)) == 5, "Expected first enemy intent to threaten 5 damage.")
	assert(int(enemy_result.get("damage_applied", -1)) == 3, "Expected brace to halve 5 damage with round-up behavior.")
	assert(flow.combat_state.player_hp == 27, "Expected player HP to drop from 30 to 27 under brace.")
	assert(not flow.combat_state.brace_active, "Expected brace flag to clear after the enemy action.")
	assert(int(flow.combat_state.weapon_instance.get("current_durability", -1)) == 20, "Expected brace not to consume weapon durability.")


func test_preview_snapshot_surfaces_readability_numbers() -> void:
	var flow: CombatFlow = _build_flow(20, [], "watcher_mail")
	var preview: Dictionary = flow.build_preview_snapshot()
	assert(int(preview.get("attack_damage_preview", -1)) == 5, "Expected preview snapshot to surface the outgoing hit after enemy armor.")
	assert(int(preview.get("defense_preview", -1)) == 1, "Expected preview snapshot to surface equipped armor reduction.")
	assert(int(preview.get("incoming_damage_preview", -1)) == 4, "Expected preview snapshot to surface the next incoming hit after defense.")
	assert(int(preview.get("brace_damage_preview", -1)) == 2, "Expected preview snapshot to surface brace mitigation after defense.")
	assert(int(preview.get("durability_spend_preview", -1)) == 1, "Expected preview snapshot to surface the next swing durability cost.")
	assert(int(preview.get("hunger_tick_preview", -1)) == 1, "Expected preview snapshot to surface the standard combat hunger tick.")


func test_use_item_heals_and_consumes_stack() -> void:
	var flow: CombatFlow = _build_flow(20)
	assert(flow.combat_state.consumable_slots.size() == 1, "Expected starter consumable slot.")
	assert(
		int(flow.combat_state.consumable_slots[0].get("current_stack", -1)) == 1,
		"Expected starter consumable stack count to be 1."
	)
	var result: Dictionary = flow.process_use_item()
	assert(not bool(result.get("skipped", true)), "Expected use item action to resolve.")
	assert(String(result.get("definition_id", "")) == "wild_berries", "Expected the starter food to resolve from the authored loadout.")
	assert(int(result.get("healed_amount", -1)) == 4, "Expected wild berries to heal 4 HP.")
	assert(int(result.get("hunger_restored_amount", -1)) == 0, "Expected no hunger restoration when the player is already at full hunger.")
	assert(flow.combat_state.player_hp == 34, "Expected player HP to rise from 30 to 34.")
	assert(flow.combat_state.consumable_slots.is_empty(), "Expected single-stack starter consumable to be consumed.")
	assert(
		(flow.combat_state.player_state.get("consumable_slots", []) as Array).is_empty(),
		"Expected player_state consumable mirror to stay synced."
	)


func test_use_item_reduces_hunger_when_food_is_used_at_full_hp() -> void:
	var flow: CombatFlow = _build_flow(20)
	flow.combat_state.player_hp = RunState.DEFAULT_PLAYER_HP
	flow.combat_state.player_state["hp"] = RunState.DEFAULT_PLAYER_HP
	flow.combat_state.player_hunger = 18
	flow.combat_state.player_state["hunger"] = 18
	var result: Dictionary = flow.process_use_item()
	assert(not bool(result.get("skipped", true)), "Expected hunger-recovery food to stay usable at full HP.")
	assert(String(result.get("definition_id", "")) == "wild_berries", "Expected the starter food to be used for hunger recovery.")
	assert(int(result.get("healed_amount", -1)) == 0, "Expected no HP to be healed at full HP.")
	assert(int(result.get("hunger_restored_amount", -1)) == 2, "Expected hunger restoration to clamp against the missing reserve.")
	assert(flow.combat_state.player_hunger == RunState.DEFAULT_HUNGER, "Expected food use to restore combat hunger to the full cap when the food over-recovers the missing value.")
	assert(flow.combat_state.consumable_slots.is_empty(), "Expected the hunger-recovery food to still consume its stack.")


func test_use_item_uses_first_usable_stack_when_front_slot_cannot_change_state() -> void:
	var flow: CombatFlow = _build_flow(20)
	flow.combat_state.player_hp = RunState.DEFAULT_PLAYER_HP
	flow.combat_state.player_state["hp"] = RunState.DEFAULT_PLAYER_HP
	flow.combat_state.player_hunger = 18
	flow.combat_state.player_state["hunger"] = 18
	flow.combat_state.consumable_slots = [
		{
			"definition_id": "minor_heal_potion",
			"current_stack": 1,
		},
		{
			"definition_id": "traveler_bread",
			"current_stack": 1,
		},
	]
	flow.combat_state.player_state["consumable_slots"] = flow.combat_state.consumable_slots.duplicate(true)
	var result: Dictionary = flow.process_use_item()
	assert(not bool(result.get("skipped", true)), "Expected use item to search for a later usable stack.")
	assert(String(result.get("definition_id", "")) == "traveler_bread", "Expected the first usable food stack to be chosen over an unusable heal-only stack.")
	assert(int(result.get("healed_amount", -1)) == 0, "Expected no HP gain when the selected food is used at full HP.")
	assert(int(result.get("hunger_restored_amount", -1)) == 2, "Expected traveler bread to restore hunger up to the cap clamp.")
	assert(flow.combat_state.player_hunger == RunState.DEFAULT_HUNGER, "Expected the selected food to update combat hunger.")
	assert(flow.combat_state.consumable_slots.size() == 1, "Expected only the used stack to be consumed.")
	assert(String(flow.combat_state.consumable_slots[0].get("definition_id", "")) == "minor_heal_potion", "Expected the unusable front stack to remain in inventory.")


func test_use_item_can_resolve_an_explicit_selected_slot() -> void:
	var flow: CombatFlow = _build_flow(20)
	flow.combat_state.player_hp = 30
	flow.combat_state.player_state["hp"] = 30
	flow.combat_state.player_hunger = 16
	flow.combat_state.player_state["hunger"] = 16
	flow.combat_state.consumable_slots = [
		{
			"definition_id": "minor_heal_potion",
			"current_stack": 1,
		},
		{
			"definition_id": "traveler_bread",
			"current_stack": 1,
		},
	]
	flow.combat_state.player_state["consumable_slots"] = flow.combat_state.consumable_slots.duplicate(true)
	var result: Dictionary = flow.process_use_item(1)
	assert(not bool(result.get("skipped", true)), "Expected explicit use-item slot selection to resolve.")
	assert(String(result.get("definition_id", "")) == "traveler_bread", "Expected explicit slot selection to override the front usable stack.")
	assert(int(result.get("healed_amount", -1)) == 8, "Expected traveler bread to apply its heal profile when explicitly selected.")
	assert(int(result.get("hunger_restored_amount", -1)) == 2, "Expected traveler bread to apply its hunger-restoration profile when explicitly selected.")
	assert(flow.combat_state.player_hp == 38, "Expected the explicit selected food to update combat HP.")
	assert(flow.combat_state.player_hunger == 18, "Expected the explicit selected food to update combat hunger.")
	assert(flow.combat_state.consumable_slots.size() == 1, "Expected only the explicitly selected consumable stack to be consumed.")
	assert(String(flow.combat_state.consumable_slots[0].get("definition_id", "")) == "minor_heal_potion", "Expected the unselected front stack to remain in inventory after explicit selection.")


func test_change_equipment_turn_swaps_carried_weapon_and_consumes_turn() -> void:
	var loader: ContentLoader = ContentLoader.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 30
	run_state.hunger = RunState.DEFAULT_HUNGER
	run_state.inventory_state.weapon_instance["current_durability"] = 20
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var replace_result: Dictionary = inventory_actions.replace_active_weapon(run_state.inventory_state, "splitter_axe")
	assert(bool(replace_result.get("ok", false)), "Expected a backup weapon before testing combat-time swap.")

	var carried_weapon_slot_id: int = -1
	for slot in run_state.inventory_state.inventory_slots:
		if String(slot.get("inventory_family", "")) != InventoryState.INVENTORY_FAMILY_WEAPON:
			continue
		var slot_id: int = int(slot.get("slot_id", -1))
		if slot_id == int(run_state.inventory_state.active_weapon_slot_id):
			continue
		carried_weapon_slot_id = slot_id
		var slot_index: int = run_state.inventory_state.find_slot_index_by_id(slot_id)
		run_state.inventory_state.inventory_slots[slot_index]["current_durability"] = 4
		break

	assert(carried_weapon_slot_id > 0, "Expected a carried non-active weapon slot for combat-time swap coverage.")
	var active_weapon_def: Dictionary = loader.load_definition("Weapons", String(run_state.inventory_state.weapon_instance.get("definition_id", "")))
	var enemy_def: Dictionary = loader.load_definition("Enemies", "bone_raider")
	var flow: CombatFlow = CombatFlow.new()
	flow.setup_combat(run_state, enemy_def, active_weapon_def)

	var full_turn_result: Dictionary = flow.resolve_change_equipment_turn(carried_weapon_slot_id)
	var action_result: Dictionary = full_turn_result.get("action_result", {})
	var enemy_result: Dictionary = full_turn_result.get("enemy_result", {})
	var turn_end_result: Dictionary = full_turn_result.get("turn_end_result", {})
	assert(not bool(action_result.get("skipped", true)), "Expected carried weapon swap to resolve during combat.")
	assert(String(action_result.get("definition_id", "")) == "iron_sword", "Expected combat-time weapon swap to retarget the carried iron sword slot.")
	assert(String(flow.combat_state.weapon_instance.get("definition_id", "")) == "iron_sword", "Expected combat-local active weapon to update immediately after the swap.")
	assert(int(flow.combat_state.weapon_instance.get("current_durability", -1)) == 4, "Expected carried weapon durability to survive the swap into combat-local truth.")
	assert(int(enemy_result.get("damage_applied", -1)) == 5, "Expected enemy action to still resolve after spending the turn on a weapon swap.")
	assert(int(turn_end_result.get("player_hunger", -1)) == RunState.DEFAULT_HUNGER - 1, "Expected combat-time weapon swap to still pay the normal hunger tick at turn end.")
	assert(flow.combat_state.current_turn == 2, "Expected combat-time weapon swap to consume the turn and advance combat.")
	assert(String(run_state.inventory_state.weapon_instance.get("definition_id", "")) == "splitter_axe", "Expected combat-time weapon swap to stay combat-local until the combat result is committed.")

	run_state.commit_combat_result(flow.combat_state)
	assert(String(run_state.inventory_state.weapon_instance.get("definition_id", "")) == "iron_sword", "Expected committed combat result to persist the swapped weapon back into run inventory truth.")
	assert(int(run_state.inventory_state.weapon_instance.get("current_durability", -1)) == 4, "Expected committed combat result to persist the swapped weapon durability.")


func test_change_equipment_turn_can_unequip_active_weapon_and_fall_back() -> void:
	var flow: CombatFlow = _build_flow(20)
	var active_weapon_slot_id: int = int(flow.combat_state.active_weapon_slot_id)
	assert(active_weapon_slot_id > 0, "Expected an active weapon slot before testing combat-time unequip.")

	var full_turn_result: Dictionary = flow.resolve_change_equipment_turn(active_weapon_slot_id)
	var action_result: Dictionary = full_turn_result.get("action_result", {})
	var enemy_result: Dictionary = full_turn_result.get("enemy_result", {})
	assert(not bool(action_result.get("skipped", true)), "Expected active-weapon unequip to resolve during combat.")
	assert(not bool(action_result.get("equipped", true)), "Expected clicking the active weapon in combat to unequip it.")
	assert(flow.combat_state.weapon_instance.is_empty(), "Expected combat-local weapon truth to clear after unequipping the active weapon.")
	assert(int(flow.combat_state.active_weapon_slot_id) == -1, "Expected combat-local active weapon slot id to clear after unequip.")
	assert(int(enemy_result.get("damage_applied", -1)) == 5, "Expected enemy action to still resolve after spending the turn on an unequip.")
	assert(flow.combat_state.current_turn == 2, "Expected combat-time unequip to consume the turn and advance combat.")

	var fallback_attack_result: Dictionary = flow.process_player_attack()
	assert(bool(fallback_attack_result.get("used_fallback_attack", false)), "Expected the next attack to use fallback damage after combat-time weapon unequip.")
	assert(int(fallback_attack_result.get("damage_applied", 0)) == 1, "Expected fallback attack damage after combat-time weapon unequip.")


func test_change_equipment_turn_swaps_carried_armor_and_enemy_still_hits() -> void:
	var loader: ContentLoader = ContentLoader.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 30
	run_state.hunger = RunState.DEFAULT_HUNGER
	run_state.inventory_state.set_armor_instance({"definition_id": "watcher_mail"})
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var replace_result: Dictionary = inventory_actions.replace_active_armor(run_state.inventory_state, "gatebound_cuirass")
	assert(bool(replace_result.get("ok", false)), "Expected a backup armor piece before testing combat-time swap.")

	var carried_armor_slot_id: int = -1
	for slot in run_state.inventory_state.inventory_slots:
		if String(slot.get("inventory_family", "")) != InventoryState.INVENTORY_FAMILY_ARMOR:
			continue
		var slot_id: int = int(slot.get("slot_id", -1))
		if slot_id == int(run_state.inventory_state.active_armor_slot_id):
			continue
		carried_armor_slot_id = slot_id
		break

	assert(carried_armor_slot_id > 0, "Expected a carried non-active armor slot for combat-time swap coverage.")
	var weapon_def: Dictionary = loader.load_definition("Weapons", String(run_state.inventory_state.weapon_instance.get("definition_id", "")))
	var enemy_def: Dictionary = loader.load_definition("Enemies", "bone_raider")
	var flow: CombatFlow = CombatFlow.new()
	flow.setup_combat(run_state, enemy_def, weapon_def)

	var full_turn_result: Dictionary = flow.resolve_change_equipment_turn(carried_armor_slot_id)
	var action_result: Dictionary = full_turn_result.get("action_result", {})
	var enemy_result: Dictionary = full_turn_result.get("enemy_result", {})
	assert(not bool(action_result.get("skipped", true)), "Expected carried armor swap to resolve during combat.")
	assert(String(flow.combat_state.armor_instance.get("definition_id", "")) == "watcher_mail", "Expected combat-local active armor to switch to the carried target.")
	assert(int(enemy_result.get("damage_applied", -1)) == 4, "Expected enemy action to still resolve against the newly swapped armor in the same turn.")
	assert(flow.combat_state.player_hp == 26, "Expected swapped watcher_mail armor to mitigate the incoming hit down to 4 damage.")


func test_passive_attack_bonus_applies_in_combat() -> void:
	var flow: CombatFlow = _build_flow(20, ["iron_grip_charm"])
	var result: Dictionary = flow.process_player_attack()
	assert(int(result.get("damage_applied", 0)) == 6, "Expected iron grip passive to add 1 attack power in combat.")
	assert(flow.combat_state.enemy_hp == 18, "Expected enemy HP to drop from 24 to 18 with passive attack bonus.")


func test_armor_damage_reduction_applies_in_combat() -> void:
	var flow: CombatFlow = _build_flow(20, [], "watcher_mail")
	var enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(enemy_result.get("damage_applied", -1)) == 4, "Expected watcher_mail to reduce the first 5-damage hit down to 4.")
	assert(flow.combat_state.player_hp == 26, "Expected player HP to reflect equipped armor reduction.")


func test_belt_durability_reduction_applies_in_combat() -> void:
	var flow: CombatFlow = _build_flow(20, [], "", "trailhook_bandolier")
	var result: Dictionary = flow.process_player_attack()
	assert(int(result.get("damage_applied", 0)) == 5, "Expected trailhook_bandolier not to change iron sword damage.")
	assert(int(flow.combat_state.weapon_instance.get("current_durability", -1)) == 20, "Expected trailhook_bandolier to offset the iron sword durability cost by 1.")


func test_inventory_actions_repair_weapon_resets_to_max_durability() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.inventory_state.weapon_instance["current_durability"] = 3
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var result: Dictionary = inventory_actions.repair_active_weapon(run_state.inventory_state)
	assert(bool(result.get("ok", false)), "Expected repair_active_weapon to succeed.")
	assert(int(run_state.inventory_state.weapon_instance.get("current_durability", -1)) == 20, "Expected repair to restore iron sword durability to max.")


func test_inventory_actions_block_belt_unequip_when_capacity_would_overflow() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.inventory_state.set_belt_instance({"definition_id": "trailhook_bandolier"})
	run_state.inventory_state.set_passive_slots([
		{"definition_id": "iron_grip_charm"},
		{"definition_id": "tempered_binding"},
		{"definition_id": "packrat_clasp"},
	])
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var result: Dictionary = inventory_actions.toggle_equipment_slot(run_state.inventory_state, int(run_state.inventory_state.active_belt_slot_id))
	assert(not bool(result.get("ok", true)), "Expected belt unequip to fail when the shared inventory would overflow.")
	assert(String(result.get("error", "")) == "belt_capacity_required", "Expected belt unequip failure to report the shared-capacity guard.")
	assert(String(run_state.inventory_state.belt_instance.get("definition_id", "")) == "trailhook_bandolier", "Expected belt lane to remain equipped after the blocked unequip.")


func test_inventory_actions_move_slot_to_index_reorders_shared_inventory() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.inventory_state.set_armor_instance({"definition_id": "watcher_mail"})
	run_state.inventory_state.set_belt_instance({"definition_id": "trailhook_bandolier"})
	var belt_slot_id: int = int(run_state.inventory_state.active_belt_slot_id)
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var result: Dictionary = inventory_actions.move_slot_to_index(run_state.inventory_state, belt_slot_id, 1)
	assert(bool(result.get("ok", false)), "Expected move_slot_to_index to reorder the shared inventory.")
	assert(int(run_state.inventory_state.inventory_slots[1].get("slot_id", -1)) == belt_slot_id, "Expected the carried belt slot to move into the requested shared inventory lane.")
	assert(int(run_state.inventory_state.active_belt_slot_id) == belt_slot_id, "Expected active belt truth to survive inventory reorder.")


func test_inventory_actions_can_upgrade_non_active_carried_weapon_slot() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var replace_result: Dictionary = inventory_actions.replace_active_weapon(run_state.inventory_state, "splitter_axe")
	assert(bool(replace_result.get("ok", false)), "Expected second weapon replace to succeed for carried-gear upgrade coverage.")

	var carried_weapon_slot_id: int = -1
	for slot in run_state.inventory_state.inventory_slots:
		if String(slot.get("inventory_family", "")) != InventoryState.INVENTORY_FAMILY_WEAPON:
			continue
		var slot_id: int = int(slot.get("slot_id", -1))
		if slot_id == int(run_state.inventory_state.active_weapon_slot_id):
			continue
		carried_weapon_slot_id = slot_id
		break

	assert(carried_weapon_slot_id > 0, "Expected a carried non-active weapon slot for blacksmith targeting coverage.")
	var upgrade_result: Dictionary = inventory_actions.upgrade_weapon_slot(run_state.inventory_state, carried_weapon_slot_id)
	assert(bool(upgrade_result.get("ok", false)), "Expected carried weapon upgrade to succeed.")
	assert(String(run_state.inventory_state.weapon_instance.get("definition_id", "")) == "splitter_axe", "Expected upgrading a carried weapon not to swap the active weapon lane.")
	var carried_slot_index: int = run_state.inventory_state.find_slot_index_by_id(carried_weapon_slot_id)
	assert(int(run_state.inventory_state.inventory_slots[carried_slot_index].get("upgrade_level", 0)) == 1, "Expected carried weapon upgrade to persist on the targeted shared-inventory slot.")


func test_inventory_actions_can_upgrade_non_active_carried_armor_slot() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.inventory_state.set_armor_instance({"definition_id": "watcher_mail"})
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var replace_result: Dictionary = inventory_actions.replace_active_armor(run_state.inventory_state, "gatebound_cuirass")
	assert(bool(replace_result.get("ok", false)), "Expected second armor replace to succeed for carried-gear upgrade coverage.")

	var carried_armor_slot_id: int = -1
	for slot in run_state.inventory_state.inventory_slots:
		if String(slot.get("inventory_family", "")) != InventoryState.INVENTORY_FAMILY_ARMOR:
			continue
		var slot_id: int = int(slot.get("slot_id", -1))
		if slot_id == int(run_state.inventory_state.active_armor_slot_id):
			continue
		carried_armor_slot_id = slot_id
		break

	assert(carried_armor_slot_id > 0, "Expected a carried non-active armor slot for blacksmith targeting coverage.")
	var upgrade_result: Dictionary = inventory_actions.upgrade_armor_slot(run_state.inventory_state, carried_armor_slot_id)
	assert(bool(upgrade_result.get("ok", false)), "Expected carried armor upgrade to succeed.")
	assert(String(run_state.inventory_state.armor_instance.get("definition_id", "")) == "gatebound_cuirass", "Expected upgrading a carried armor piece not to swap the active armor lane.")
	var carried_slot_index: int = run_state.inventory_state.find_slot_index_by_id(carried_armor_slot_id)
	assert(int(run_state.inventory_state.inventory_slots[carried_slot_index].get("upgrade_level", 0)) == 1, "Expected carried armor upgrade to persist on the targeted shared-inventory slot.")


func test_inventory_actions_add_and_remove_consumable_stack() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	var inventory_actions: RefCounted = InventoryActionsScript.new()

	var add_result: Dictionary = inventory_actions.add_consumable_stack(run_state.inventory_state, "minor_heal_potion", 5)
	assert(bool(add_result.get("ok", false)), "Expected add_consumable_stack to succeed.")
	assert(run_state.inventory_state.consumable_slots.size() == 2, "Expected second consumable slot after overflowing the first stack.")
	var added_slot_index := -1
	for index in range(run_state.inventory_state.consumable_slots.size()):
		if String(run_state.inventory_state.consumable_slots[index].get("definition_id", "")) == "minor_heal_potion":
			added_slot_index = index
			break
	assert(added_slot_index >= 0, "Expected add_consumable_stack to create or extend a minor_heal_potion slot.")
	assert(int(run_state.inventory_state.consumable_slots[added_slot_index].get("current_stack", -1)) == 5, "Expected minor_heal_potion stack to cap at max_stack 5.")

	var remove_result: Dictionary = inventory_actions.remove_consumable_stack(run_state.inventory_state, "minor_heal_potion", 2)
	assert(bool(remove_result.get("ok", false)), "Expected remove_consumable_stack to succeed.")
	assert(run_state.inventory_state.consumable_slots.size() == 2, "Expected authored starter food slot plus one partial minor_heal_potion stack after removing 2.")
	assert(int(run_state.inventory_state.consumable_slots[added_slot_index].get("current_stack", -1)) == 3, "Expected removal to reduce the matching minor_heal_potion stack from 5 to 3.")


func test_inventory_actions_replaces_oldest_non_active_item_when_shared_inventory_is_full() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.inventory_state.set_passive_slots([
		{"definition_id": "iron_grip_charm"},
		{"definition_id": "sturdy_wraps"},
	])
	run_state.inventory_state.set_armor_instance({"definition_id": "watcher_mail"})
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var result: Dictionary = inventory_actions.add_passive_item(run_state.inventory_state, "tempered_binding", 2)
	assert(bool(result.get("ok", false)), "Expected add_passive_item to succeed.")
	assert(String(result.get("replaced_definition_id", "")) == "wild_berries", "Expected the oldest non-active carried item to be displaced when the shared inventory is full.")
	assert(String(result.get("replaced_family", "")) == "consumable", "Expected the displacement result to report the removed item family.")
	assert(run_state.inventory_state.passive_slots.size() == 3, "Expected the newly chosen passive to consume shared inventory space.")
	assert(String(run_state.inventory_state.passive_slots[2].get("definition_id", "")) == "tempered_binding", "Expected newly chosen passive to occupy the newest shared inventory slot.")
	assert(run_state.inventory_state.consumable_slots.is_empty(), "Expected the displaced starter consumable to be removed from the shared inventory.")


func test_inventory_actions_replace_active_armor_and_belt() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var armor_result: Dictionary = inventory_actions.replace_active_armor(run_state.inventory_state, "gatebound_cuirass")
	assert(bool(armor_result.get("ok", false)), "Expected replace_active_armor to succeed.")
	assert(String(run_state.inventory_state.armor_instance.get("definition_id", "")) == "gatebound_cuirass", "Expected equipped armor slot to store the authored definition id.")
	var belt_result: Dictionary = inventory_actions.replace_active_belt(run_state.inventory_state, "duelist_knot")
	assert(bool(belt_result.get("ok", false)), "Expected replace_active_belt to succeed.")
	assert(String(run_state.inventory_state.belt_instance.get("definition_id", "")) == "duelist_knot", "Expected equipped belt slot to store the authored definition id.")


func test_combat_reorder_inventory_slot_persists_without_spending_turn() -> void:
	var loader: ContentLoader = ContentLoader.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.inventory_state.set_armor_instance({"definition_id": "watcher_mail"})
	run_state.inventory_state.set_belt_instance({"definition_id": "trailhook_bandolier"})
	var belt_slot_id: int = int(run_state.inventory_state.active_belt_slot_id)
	var weapon_def: Dictionary = loader.load_definition("Weapons", "iron_sword")
	var enemy_def: Dictionary = loader.load_definition("Enemies", "bone_raider")
	var flow: CombatFlow = CombatFlow.new()
	flow.setup_combat(run_state, enemy_def, weapon_def)

	var move_result: Dictionary = flow.reorder_inventory_slot(belt_slot_id, 1)
	assert(bool(move_result.get("ok", false)), "Expected combat inventory reorder to succeed.")
	assert(flow.combat_state.current_turn == 1, "Expected combat inventory reorder not to consume the turn.")
	var projected_inventory: InventoryState = flow.combat_state.build_inventory_projection(run_state.inventory_state)
	assert(int(projected_inventory.inventory_slots[1].get("slot_id", -1)) == belt_slot_id, "Expected combat-local inventory reorder to update the projected shared inventory order.")

	run_state.commit_combat_result(flow.combat_state)
	assert(int(run_state.inventory_state.inventory_slots[1].get("slot_id", -1)) == belt_slot_id, "Expected committed combat result to persist the reordered shared inventory order.")


func test_upgraded_weapon_adds_attack_power_in_combat() -> void:
	var flow: CombatFlow = _build_flow(20, [], "", "", 1, 0)
	var result: Dictionary = flow.process_player_attack()
	assert(int(result.get("damage_applied", 0)) == 6, "Expected weapon +1 to add 1 attack power in combat.")
	assert(flow.combat_state.enemy_hp == 18, "Expected upgraded weapon attack to reduce enemy HP by 6 after enemy armor.")


func test_upgraded_armor_adds_defense_in_combat() -> void:
	var flow: CombatFlow = _build_flow(20, [], "watcher_mail", "", 0, 1)
	var enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(enemy_result.get("damage_applied", -1)) == 3, "Expected armor +1 to stack another point of flat defense in combat.")
	assert(flow.combat_state.player_hp == 27, "Expected upgraded armor to reduce the first enemy hit down to 3.")


func test_weapon_durability_persists_across_three_combats() -> void:
	var loader: ContentLoader = ContentLoader.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 60
	run_state.inventory_state.weapon_instance["current_durability"] = 3
	var weapon_def: Dictionary = loader.load_definition("Weapons", "iron_sword")
	var enemy_def: Dictionary = loader.load_definition("Enemies", "bone_raider")

	for _combat_index in range(3):
		var flow: CombatFlow = CombatFlow.new()
		flow.setup_combat(run_state, enemy_def, weapon_def)
		flow.process_player_attack()
		run_state.commit_combat_result(flow.combat_state)

	assert(
		int(run_state.inventory_state.weapon_instance.get("current_durability", -1)) == 0,
		"Expected weapon durability to persist across three combat commits."
	)


func test_combat_end_signal_emits_once() -> void:
	var flow: CombatFlow = _build_flow(20)
	_combat_end_signal_count = 0
	flow.connect("combat_ended_signal", Callable(self, "_on_combat_end_signal_for_test"))
	flow.combat_state.enemy_state["hp"] = 1
	flow.combat_state.enemy_hp = 1
	flow.process_player_attack()
	assert(flow.combat_state.combat_ended, "Expected combat to end after lethal attack.")
	assert(flow.combat_state.combat_result == "victory", "Expected combat result to lock to victory.")
	flow.check_combat_end()
	flow.check_combat_end()
	assert(_combat_end_signal_count == 1, "Expected combat_ended_signal to emit only once.")


func _build_flow(
	starting_durability: int,
	passive_definition_ids: Array[String] = [],
	armor_definition_id: String = "",
	belt_definition_id: String = "",
	weapon_upgrade_level: int = 0,
	armor_upgrade_level: int = 0
) -> CombatFlow:
	var loader: ContentLoader = ContentLoader.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 30
	run_state.hunger = RunState.DEFAULT_HUNGER
	run_state.xp = 0
	run_state.current_level = 1
	run_state.stage_index = 1
	run_state.inventory_state.weapon_instance["current_durability"] = starting_durability
	run_state.inventory_state.weapon_instance["upgrade_level"] = max(0, weapon_upgrade_level)
	run_state.inventory_state.set_armor_instance({"definition_id": armor_definition_id} if not armor_definition_id.is_empty() else {})
	if armor_upgrade_level > 0 and not run_state.inventory_state.armor_instance.is_empty():
		run_state.inventory_state.armor_instance["upgrade_level"] = armor_upgrade_level
	run_state.inventory_state.set_belt_instance({"definition_id": belt_definition_id} if not belt_definition_id.is_empty() else {})
	var passive_slots: Array[Dictionary] = []
	for definition_id in passive_definition_ids:
		passive_slots.append({
			"definition_id": definition_id,
		})
	run_state.inventory_state.set_passive_slots(passive_slots)

	var weapon_def: Dictionary = loader.load_definition("Weapons", "iron_sword")
	var enemy_def: Dictionary = loader.load_definition("Enemies", "bone_raider")

	var flow: CombatFlow = CombatFlow.new()
	flow.setup_combat(run_state, enemy_def, weapon_def)
	return flow


func _on_combat_end_signal_for_test(_result: String) -> void:
	_combat_end_signal_count += 1
