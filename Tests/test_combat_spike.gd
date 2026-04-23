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
	test_defend_generates_guard_for_current_turn()
	test_resolve_defend_turn_applies_extra_hunger_cost()
	test_shield_bonus_increases_defend_guard()
	test_dual_wield_adjusts_attack_and_defend()
	test_turn_end_guard_decay_carries_remainder()
	test_preview_snapshot_surfaces_readability_numbers()
	test_cleanse_pulse_clears_player_statuses_and_spends_once()
	test_sundering_strike_ignores_enemy_armor()
	test_blood_draw_heals_from_damage_dealt()
	test_echo_strike_primes_the_next_attack()
	test_hand_swap_candidate_queries_stay_slot_specific()
	test_resolve_swap_hand_turn_replaces_right_hand_and_spends_the_turn()
	test_hand_swap_updates_active_weapon_damage_preview_technique_and_repair_truth()
	test_weapon_durability_profiles_scale_attack_wear()
	test_use_item_heals_and_consumes_stack()
	test_use_item_reduces_hunger_when_food_is_used_at_full_hp()
	test_use_item_uses_first_usable_stack_when_front_slot_cannot_change_state()
	test_use_item_can_resolve_an_explicit_selected_slot()
	test_passive_attack_bonus_applies_in_combat()
	test_armor_damage_reduction_applies_in_combat()
	test_attached_shield_mod_applies_in_combat()
	test_belt_is_inventory_utility_only()
	test_inventory_actions_repair_weapon_resets_to_max_durability()
	test_inventory_actions_block_belt_unequip_when_capacity_would_overflow()
	test_inventory_actions_swap_backup_weapon_when_backpack_is_full()
	test_inventory_actions_offer_discard_prompt_for_full_backpack_unequip()
	test_inventory_actions_attach_and_detach_shield_mods()
	test_inventory_actions_move_slot_to_index_reorders_backpack()
	test_inventory_actions_preserve_quest_items_when_backpack_is_full()
	test_inventory_actions_can_upgrade_non_active_carried_weapon_slot()
	test_inventory_actions_can_upgrade_non_active_carried_armor_slot()
	test_inventory_actions_add_and_remove_consumable_stack()
	test_inventory_actions_replaces_oldest_non_equipped_item_when_backpack_is_full()
	test_inventory_actions_replace_active_armor_and_belt()
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
	var authored_backpack_items: Array = starter_rules.get("backpack_items", [])
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()

	assert(
		String(run_state.inventory_state.weapon_instance.get("definition_id", "")) == String(starter_rules.get("right_hand_definition_id", "")),
		"Expected new-run weapon instance to come from the authored starter loadout."
	)
	assert(
		run_state.inventory_state.inventory_slots.size() == authored_backpack_items.size(),
		"Expected new-run backpack slot count to come from the authored starter loadout."
	)
	assert(
		String(run_state.inventory_state.inventory_slots[0].get("definition_id", "")) == String((authored_backpack_items[0] as Dictionary).get("definition_id", "")),
		"Expected starter backpack item definition to come from the authored starter loadout."
	)
	assert(
		int(run_state.inventory_state.inventory_slots[0].get("current_stack", -1)) == int((authored_backpack_items[0] as Dictionary).get("current_stack", -2)),
		"Expected starter backpack stack count to come from the authored starter loadout."
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


func test_defend_generates_guard_for_current_turn() -> void:
	var flow: CombatFlow = _build_flow(20)
	var defend_result: Dictionary = flow.process_defend()
	assert(not bool(defend_result.get("skipped", true)), "Expected defend action to resolve.")
	assert(int(defend_result.get("guard_generated", -1)) == 3, "Expected baseline defend to raise 3 guard.")
	assert(int(defend_result.get("extra_hunger_cost", -1)) == 1, "Expected defend to report the extra hunger tradeoff.")
	assert(int(defend_result.get("turn_hunger_cost", -1)) == 2, "Expected defend to surface the full defend-turn hunger cost.")
	assert(flow.combat_state.current_guard == 3, "Expected combat guard to mirror the defend result before the enemy action.")
	var enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(enemy_result.get("raw_damage", -1)) == 5, "Expected first enemy intent to threaten 5 raw damage.")
	assert(int(enemy_result.get("guard_absorbed", -1)) == 3, "Expected defend guard to absorb 3 damage from the first hit.")
	assert(int(enemy_result.get("damage_applied", -1)) == 2, "Expected the remaining 2 damage to leak into HP after guard.")
	assert(flow.combat_state.player_hp == 28, "Expected player HP to drop from 30 to 28 after guard is consumed.")
	assert(flow.combat_state.current_guard == 0, "Expected guard to clear after the enemy action consumes it.")
	assert(int(flow.combat_state.weapon_instance.get("current_durability", -1)) == 20, "Expected defend not to consume weapon durability.")


func test_resolve_defend_turn_applies_extra_hunger_cost() -> void:
	var flow: CombatFlow = _build_flow(20)
	var full_turn_result: Dictionary = flow.resolve_defend_turn()
	var action_result: Dictionary = full_turn_result.get("action_result", {})
	var turn_end_result: Dictionary = full_turn_result.get("turn_end_result", {})
	assert(int(action_result.get("guard_generated", -1)) == 3, "Expected full defend turn to keep the stronger defend guard floor.")
	assert(int(turn_end_result.get("hunger_spent", -1)) == 2, "Expected defend turn end to spend the standard hunger tick plus the extra defend cost.")
	assert(int(turn_end_result.get("player_hunger", -1)) == RunState.DEFAULT_HUNGER - 2, "Expected defend turns to spend 2 hunger from a full reserve.")
	assert(flow.combat_state.player_hunger == RunState.DEFAULT_HUNGER - 2, "Expected combat state hunger to stay synced after the defend tradeoff is applied.")
	assert(flow.combat_state.current_turn == 2, "Expected full defend turn to advance the combat turn.")


func test_shield_bonus_increases_defend_guard() -> void:
	var flow: CombatFlow = _build_flow(20, [], "", "", 0, 0, {
		"definition_id": "weathered_buckler",
		"inventory_family": InventoryState.INVENTORY_FAMILY_SHIELD,
	})
	var defend_result: Dictionary = flow.process_defend()
	assert(int(defend_result.get("guard_generated", -1)) == 5, "Expected shield support to raise defend guard from 3 to 5.")
	assert(bool(defend_result.get("shield_bonus_applied", false)), "Expected shield defend result to report shield support.")
	var enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(enemy_result.get("guard_absorbed", -1)) == 5, "Expected shield defend guard to absorb 5 incoming damage.")
	assert(int(enemy_result.get("damage_applied", -1)) == 0, "Expected shield defend to fully block the first bone-raider hit.")


func test_dual_wield_adjusts_attack_and_defend() -> void:
	var flow: CombatFlow = _build_flow(20, [], "", "", 0, 0, {
		"definition_id": "forager_knife",
		"inventory_family": InventoryState.INVENTORY_FAMILY_WEAPON,
		"current_durability": 10,
	})
	var attack_result: Dictionary = flow.process_player_attack()
	assert(int(attack_result.get("damage_applied", -1)) == 6, "Expected dual wield to add 1 attack power against the bone-raider baseline.")
	assert(flow.combat_state.enemy_hp == 18, "Expected dual wield attack bonus to reduce bone-raider HP by 6 after armor.")
	var defend_result: Dictionary = flow.process_defend()
	assert(int(defend_result.get("guard_generated", -1)) == 2, "Expected dual wield to reduce defend guard from 3 to 2.")
	assert(bool(defend_result.get("dual_wield_penalty_applied", false)), "Expected defend result to report the dual-wield guard penalty.")


func test_turn_end_guard_decay_carries_remainder() -> void:
	var flow: CombatFlow = _build_flow(20)
	var defend_result: Dictionary = flow.process_defend()
	assert(int(defend_result.get("guard_generated", -1)) == 3, "Expected baseline defend to still generate 3 guard before decay.")
	assert(int(defend_result.get("guard_points", -1)) == 3, "Expected first defend to start from zero carried guard.")
	var turn_end_result: Dictionary = flow.process_turn_end()
	assert(int(turn_end_result.get("guard_points", -1)) == 1, "Expected 25% carryover from 3 guard to round into 1 retained guard.")
	assert(flow.combat_state.current_guard == 1, "Expected combat state to keep the rounded retained guard after turn end.")
	var next_defend_result: Dictionary = flow.process_defend()
	assert(int(next_defend_result.get("guard_generated", -1)) == 3, "Expected defend to keep adding the same new guard amount.")
	assert(int(next_defend_result.get("guard_points", -1)) == 4, "Expected the next defend to stack new guard on top of the carried remainder.")
	assert(flow.combat_state.current_guard == 4, "Expected combat guard to reflect stacked carried guard plus the new defend gain.")


func test_preview_snapshot_surfaces_readability_numbers() -> void:
	var flow: CombatFlow = _build_flow(20, [], "watcher_mail")
	var preview: Dictionary = flow.build_preview_snapshot()
	assert(int(preview.get("attack_damage_preview", -1)) == 5, "Expected preview snapshot to surface the outgoing hit after enemy armor.")
	assert(int(preview.get("enemy_defense_preview", -1)) == 1, "Expected preview snapshot to surface enemy armor for the compact enemy vitals read.")
	assert(int(preview.get("defense_preview", -1)) == 1, "Expected preview snapshot to surface equipped armor reduction.")
	assert(int(preview.get("incoming_damage_preview", -1)) == 4, "Expected preview snapshot to surface the next incoming hit after defense.")
	assert(int(preview.get("guard_gain_preview", -1)) == 3, "Expected preview snapshot to surface defend guard generation.")
	assert(int(preview.get("guard_absorb_preview", -1)) == 3, "Expected preview snapshot to surface guard absorption after armor.")
	assert(int(preview.get("guard_damage_preview", -1)) == 1, "Expected preview snapshot to surface the remaining HP damage after guard.")
	assert(int(preview.get("durability_spend_preview", -1)) == 1, "Expected preview snapshot to surface the next swing durability cost.")
	assert(int(preview.get("hunger_tick_preview", -1)) == 1, "Expected preview snapshot to surface the standard combat hunger tick.")
	assert(int(preview.get("defend_hunger_cost_preview", -1)) == 2, "Expected preview snapshot to surface the full defend-turn hunger cost.")


func test_cleanse_pulse_clears_player_statuses_and_spends_once() -> void:
	var flow: CombatFlow = _build_flow(20, [], "", "", 0, 0, {}, "iron_sword", "cleanse_pulse")
	var loader: ContentLoader = ContentLoader.new()
	flow.combat_state.apply_player_status_definition(loader.load_definition("Statuses", "poison"))
	flow.combat_state.apply_player_status_definition(loader.load_definition("Statuses", "weakened"))
	assert(flow.is_technique_available(), "Expected cleanse technique to stay available while the player is afflicted.")
	var preview: Dictionary = flow.build_preview_snapshot()
	assert(int(preview.get("technique_removed_status_count", -1)) == 2, "Expected cleanse preview to surface the current afflicted-status count.")
	assert(int(preview.get("technique_guard_gain_preview", -1)) == 2, "Expected cleanse preview to surface the small guard pulse.")
	var result: Dictionary = flow.process_technique()
	assert(not bool(result.get("skipped", false)), "Expected cleanse technique to resolve.")
	assert(String(result.get("technique_effect_type", "")) == "remove_statuses", "Expected cleanse technique to resolve through the remove-statuses lane.")
	assert(int(result.get("removed_status_count", -1)) == 2, "Expected cleanse technique to clear all current player statuses.")
	assert(int(result.get("guard_gained", -1)) == 2, "Expected cleanse technique to add the authored small guard pulse.")
	assert(flow.combat_state.player_statuses.is_empty(), "Expected cleanse technique to leave no player statuses behind.")
	assert(flow.combat_state.current_guard == 2, "Expected cleanse technique to sync the authored guard pulse into combat guard truth.")
	assert(flow.combat_state.technique_spent, "Expected cleanse technique to spend the once-per-combat slot.")
	assert(not flow.is_technique_available(), "Expected cleanse technique not to remain reusable after it resolves once.")
	var second_result: Dictionary = flow.process_technique()
	assert(bool(second_result.get("skipped", false)), "Expected cleanse technique to reject a second use in the same combat.")
	assert(String(second_result.get("error", "")) == "technique_spent", "Expected second cleanse use to report the spent once-per-combat slot.")


func test_sundering_strike_ignores_enemy_armor() -> void:
	var flow: CombatFlow = _build_flow(20, [], "", "", 0, 0, {}, "iron_sword", "sundering_strike")
	var preview: Dictionary = flow.build_preview_snapshot()
	assert(bool(preview.get("has_equipped_technique", false)), "Expected technique preview snapshot to surface the equipped technique lane.")
	assert(int(preview.get("technique_damage_preview", -1)) == 6, "Expected Sundering Strike preview to ignore the bone-raider armor floor.")
	var result: Dictionary = flow.process_technique()
	assert(not bool(result.get("skipped", false)), "Expected Sundering Strike to resolve.")
	assert(int(result.get("damage_applied", -1)) == 6, "Expected Sundering Strike to deal the full iron-sword hit through armor.")
	assert(bool(result.get("ignores_armor", false)), "Expected Sundering Strike to mark the ignore-armor technique lane in resolver output.")
	assert(flow.combat_state.enemy_hp == 18, "Expected Sundering Strike to leave the bone-raider at 18 HP.")


func test_blood_draw_heals_from_damage_dealt() -> void:
	var flow: CombatFlow = _build_flow(20, [], "", "", 0, 0, {}, "iron_sword", "blood_draw")
	flow.combat_state.player_hp = 20
	flow.combat_state.player_state["hp"] = 20
	var result: Dictionary = flow.process_technique()
	assert(not bool(result.get("skipped", false)), "Expected Blood Draw to resolve.")
	assert(int(result.get("damage_applied", -1)) == 5, "Expected Blood Draw to keep the normal iron-sword damage after armor.")
	assert(int(result.get("healed_amount", -1)) == 2, "Expected Blood Draw to heal for half the damage dealt, rounded down.")
	assert(flow.combat_state.player_hp == 22, "Expected Blood Draw to restore HP on the attacker runtime state.")


func test_echo_strike_primes_the_next_attack() -> void:
	var flow: CombatFlow = _build_flow(20, [], "", "", 0, 0, {}, "iron_sword", "echo_strike")
	var technique_turn_result: Dictionary = flow.resolve_technique_turn()
	var action_result: Dictionary = technique_turn_result.get("action_result", {})
	assert(String(action_result.get("technique_effect_type", "")) == "prime_next_attack", "Expected Echo Strike to resolve through the prime-next-attack lane.")
	assert(int(action_result.get("queued_attack_multiplier", -1)) == 3, "Expected Echo Strike to prime a x3 next-attack multiplier.")
	assert(flow.combat_state.technique_spent, "Expected Echo Strike to spend the once-per-combat slot immediately.")
	assert(flow.combat_state.queued_attack_multiplier == 3, "Expected Echo Strike to persist the queued multiplier across the enemy turn.")
	var preview_after_prime: Dictionary = flow.build_preview_snapshot()
	assert(int(preview_after_prime.get("attack_damage_preview", -1)) == 17, "Expected the next normal attack preview to reflect the queued x3 attack multiplier.")
	var attack_result: Dictionary = flow.process_player_attack()
	assert(int(attack_result.get("damage_applied", -1)) == 17, "Expected the next normal attack to consume the queued x3 multiplier.")
	assert(flow.combat_state.queued_attack_multiplier == 1, "Expected the queued attack multiplier to clear after the primed attack resolves.")


func test_hand_swap_candidate_queries_stay_slot_specific() -> void:
	var loader: ContentLoader = ContentLoader.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	_append_backpack_slot(run_state, {
		"inventory_family": InventoryState.INVENTORY_FAMILY_SHIELD,
		"definition_id": "weathered_buckler",
	})
	_append_backpack_slot(run_state, {
		"inventory_family": InventoryState.INVENTORY_FAMILY_WEAPON,
		"definition_id": "forager_knife",
		"current_durability": 10,
	})
	_append_backpack_slot(run_state, {
		"inventory_family": InventoryState.INVENTORY_FAMILY_WEAPON,
		"definition_id": "splitter_axe",
		"current_durability": 14,
	})
	var flow := CombatFlow.new()
	flow.setup_combat(
		run_state,
		loader.load_definition("Enemies", "bone_raider"),
		loader.load_definition("Weapons", "iron_sword")
	)

	var right_candidates: Array[Dictionary] = flow.get_hand_swap_candidates(InventoryState.EQUIPMENT_SLOT_RIGHT_HAND)
	var left_candidates: Array[Dictionary] = flow.get_hand_swap_candidates(InventoryState.EQUIPMENT_SLOT_LEFT_HAND)
	assert(right_candidates.size() == 2, "Expected right-hand swap to list only carried weapons that can equip to the right hand.")
	assert(left_candidates.size() == 2, "Expected left-hand swap to list the shield and offhand-capable weapon only.")
	assert(not _candidate_list_contains_definition(right_candidates, "weathered_buckler"), "Expected right-hand swap candidates not to include carried shields.")
	assert(_candidate_list_contains_definition(left_candidates, "weathered_buckler"), "Expected left-hand swap candidates to include carried shields.")
	assert(_candidate_list_contains_definition(left_candidates, "forager_knife"), "Expected left-hand swap candidates to include offhand-capable carried weapons.")
	assert(not _candidate_list_contains_definition(left_candidates, "splitter_axe"), "Expected left-hand swap candidates not to include right-hand-only carried weapons.")


func test_resolve_swap_hand_turn_replaces_right_hand_and_spends_the_turn() -> void:
	var loader: ContentLoader = ContentLoader.new()
	var inventory_actions: InventoryActions = InventoryActionsScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	var replace_result: Dictionary = inventory_actions.replace_active_weapon(run_state.inventory_state, "splitter_axe")
	assert(bool(replace_result.get("ok", false)), "Expected the test helper to equip a non-default active weapon before combat.")
	var iron_sword_slot_id: int = _find_backpack_slot_id_by_definition(run_state.inventory_state, "iron_sword")
	assert(iron_sword_slot_id > 0, "Expected the old starter sword to remain in the backpack as a legal swap target.")

	var flow := CombatFlow.new()
	flow.setup_combat(
		run_state,
		loader.load_definition("Enemies", "bone_raider"),
		loader.load_definition("Weapons", "splitter_axe")
	)
	assert(flow.has_hand_swap_candidates(InventoryState.EQUIPMENT_SLOT_RIGHT_HAND), "Expected a carried spare weapon to enable right-hand combat swap.")

	var full_turn_result: Dictionary = flow.resolve_swap_hand_turn(InventoryState.EQUIPMENT_SLOT_RIGHT_HAND, iron_sword_slot_id)
	var action_result: Dictionary = full_turn_result.get("action_result", {})
	assert(not bool(action_result.get("skipped", true)), "Expected the legal right-hand swap to resolve.")
	assert(String(action_result.get("equipped_definition_id", "")) == "iron_sword", "Expected the swap action result to report the newly equipped right-hand weapon.")
	assert(String(flow.combat_state.weapon_instance.get("definition_id", "")) == "iron_sword", "Expected combat-local weapon truth to update immediately after the swap.")
	assert(full_turn_result.has("enemy_result"), "Expected hand swap to spend the turn and resolve the enemy follow-up.")
	assert(full_turn_result.has("turn_end_result"), "Expected hand swap to include the normal turn-end sequence.")
	assert(flow.combat_state.current_turn == 2, "Expected hand swap to count as the player's turn and advance combat.")
	assert(flow.combat_state.player_hunger == RunState.DEFAULT_HUNGER - 1, "Expected hand swap turns to pay only the normal turn-end hunger tick.")
	var projected_inventory: InventoryState = flow.combat_state.build_inventory_projection(run_state.inventory_state)
	assert(_inventory_contains_definition(projected_inventory, "splitter_axe"), "Expected the displaced right-hand weapon to move back into the projected backpack after the swap.")


func test_hand_swap_updates_active_weapon_damage_preview_technique_and_repair_truth() -> void:
	var loader: ContentLoader = ContentLoader.new()
	var inventory_actions: InventoryActions = InventoryActionsScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.equipped_technique_definition_id = "blood_draw"
	run_state.inventory_state.set_consumable_slots([{
		"definition_id": "tinker_oil",
		"current_stack": 1,
	}])
	var replace_result: Dictionary = inventory_actions.replace_active_weapon(run_state.inventory_state, "splitter_axe")
	assert(bool(replace_result.get("ok", false)), "Expected a non-default active weapon before testing post-swap combat truth.")
	var iron_sword_slot_id: int = _find_backpack_slot_id_by_definition(run_state.inventory_state, "iron_sword")
	assert(iron_sword_slot_id > 0, "Expected the starter sword to remain packed as the legal swap target.")
	var iron_sword_slot_index: int = run_state.inventory_state.find_slot_index_by_id(iron_sword_slot_id)
	assert(iron_sword_slot_index >= 0, "Expected to locate the packed starter sword before combat.")
	run_state.inventory_state.inventory_slots[iron_sword_slot_index]["current_durability"] = 7

	var flow := CombatFlow.new()
	flow.setup_combat(
		run_state,
		loader.load_definition("Enemies", "bone_raider"),
		loader.load_definition("Weapons", "splitter_axe")
	)

	var swap_turn_result: Dictionary = flow.resolve_swap_hand_turn(InventoryState.EQUIPMENT_SLOT_RIGHT_HAND, iron_sword_slot_id)
	assert(not bool((swap_turn_result.get("action_result", {}) as Dictionary).get("skipped", true)), "Expected the swap setup turn to resolve before post-swap truth checks.")
	assert(String(flow.combat_state.weapon_instance.get("definition_id", "")) == "iron_sword", "Expected the right-hand swap to make Iron Sword the active combat weapon before preview and technique checks.")

	var preview_after_swap: Dictionary = flow.build_preview_snapshot()
	assert(int(preview_after_swap.get("attack_damage_preview", -1)) == 5, "Expected post-swap attack preview to use Iron Sword damage instead of the old Splitter Axe profile.")
	assert(int(preview_after_swap.get("technique_damage_preview", -1)) == 5, "Expected Blood Draw preview to follow the swapped Iron Sword damage truth.")
	assert(int(preview_after_swap.get("technique_heal_preview", -1)) == 2, "Expected Blood Draw preview to use the swapped weapon damage for its heal forecast.")

	flow.combat_state.player_hp = 20
	flow.combat_state.player_state["hp"] = 20
	var technique_result: Dictionary = flow.process_technique()
	assert(int(technique_result.get("damage_applied", -1)) == 5, "Expected Blood Draw to use the swapped Iron Sword profile after the hand swap.")
	assert(int(technique_result.get("healed_amount", -1)) == 2, "Expected Blood Draw healing to follow the swapped weapon damage after the hand swap.")

	var repair_result: Dictionary = flow.process_use_item()
	assert(not bool(repair_result.get("skipped", true)), "Expected Tinker Oil to stay usable while the swapped Iron Sword is damaged.")
	assert(int(repair_result.get("repaired_durability", -1)) == 14, "Expected weapon repair to restore the swapped Iron Sword to its authored max durability instead of the old Splitter Axe cap.")
	assert(int(flow.combat_state.weapon_instance.get("current_durability", -1)) == 20, "Expected the swapped Iron Sword durability to repair up to 20/20.")


func test_weapon_durability_profiles_scale_attack_wear() -> void:
	var sturdy_flow: CombatFlow = _build_flow(20)
	sturdy_flow.process_player_attack()
	assert(int(sturdy_flow.combat_state.weapon_instance.get("current_durability", -1)) == 19, "Expected sturdy iron_sword profile to keep effective swing wear at 1.")

	var standard_flow: CombatFlow = _build_flow(18, [], "", "", 0, 0, {}, "forager_knife")
	standard_flow.process_player_attack()
	assert(int(standard_flow.combat_state.weapon_instance.get("current_durability", -1)) == 17, "Expected standard forager_knife profile to spend 1 durability per attack.")

	var fragile_flow: CombatFlow = _build_flow(16, [], "", "", 0, 0, {}, "bandit_hatchet")
	fragile_flow.process_player_attack()
	assert(int(fragile_flow.combat_state.weapon_instance.get("current_durability", -1)) == 14, "Expected fragile bandit_hatchet profile to spend 2 durability per attack.")

	var rapier_flow: CombatFlow = _build_flow(10, [], "", "", 0, 0, {}, "thorn_rapier")
	rapier_flow.process_player_attack()
	assert(int(rapier_flow.combat_state.weapon_instance.get("current_durability", -1)) == 7, "Expected fragile thorn_rapier profile to spend 3 durability per attack.")

	var heavy_flow: CombatFlow = _build_flow(20, [], "", "", 0, 0, {}, "gatebreaker_club")
	heavy_flow.process_player_attack()
	assert(int(heavy_flow.combat_state.weapon_instance.get("current_durability", -1)) == 16, "Expected heavy gatebreaker_club profile to spend 4 durability per attack.")


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


func test_attached_shield_mod_applies_in_combat() -> void:
	var flow: CombatFlow = _build_flow(20, [], "", "", 0, 0, {
		"definition_id": "weathered_buckler",
		"inventory_family": InventoryState.INVENTORY_FAMILY_SHIELD,
		"attachment_definition_id": "reinforced_rim_lining",
	})
	var enemy_result: Dictionary = flow.process_enemy_action()
	assert(int(enemy_result.get("damage_applied", -1)) == 4, "Expected attached shield lining to add 1 flat reduction after armorless guard-less damage.")
	assert(flow.combat_state.player_hp == 26, "Expected attached shield lining to preserve 1 HP from the first 5-damage hit.")


func test_belt_is_inventory_utility_only() -> void:
	var flow: CombatFlow = _build_flow(20, [], "", "trailhook_bandolier")
	var result: Dictionary = flow.process_player_attack()
	assert(int(result.get("damage_applied", 0)) == 5, "Expected trailhook_bandolier not to change iron sword damage.")
	assert(int(flow.combat_state.weapon_instance.get("current_durability", -1)) == 19, "Expected belts to stop offsetting weapon durability cost in combat.")


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
		{"definition_id": "lean_pack_token"},
	])
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var result: Dictionary = inventory_actions.toggle_equipment_slot(run_state.inventory_state, int(run_state.inventory_state.active_belt_slot_id))
	assert(not bool(result.get("ok", true)), "Expected belt unequip to fail when the backpack would overflow after losing belt capacity.")
	assert(String(result.get("error", "")) == "belt_capacity_required", "Expected belt unequip failure to report the backpack-capacity guard.")
	assert(String(run_state.inventory_state.belt_instance.get("definition_id", "")) == "trailhook_bandolier", "Expected belt lane to remain equipped after the blocked unequip.")


func test_inventory_actions_swap_backup_weapon_when_backpack_is_full() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	_fill_backpack_to_capacity(run_state, [{
		"inventory_family": InventoryState.INVENTORY_FAMILY_WEAPON,
		"definition_id": "splitter_axe",
		"current_durability": 14,
		"upgrade_level": 0,
	}])
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var backup_weapon_slot_id: int = _find_backpack_slot_id_by_definition(run_state.inventory_state, "splitter_axe")
	assert(backup_weapon_slot_id > 0, "Expected a carried backup weapon in the full-backpack swap test.")
	var result: Dictionary = inventory_actions.toggle_equipment_slot(run_state.inventory_state, backup_weapon_slot_id)
	assert(bool(result.get("ok", false)), "Expected clicking a backup weapon in the backpack to swap directly even when the backpack is full.")
	assert(String(run_state.inventory_state.weapon_instance.get("definition_id", "")) == "splitter_axe", "Expected the backup weapon to become the equipped right-hand truth after the swap.")
	assert(_inventory_contains_definition(run_state.inventory_state, "iron_sword"), "Expected the previously equipped weapon to become the new carried backup after the swap.")
	assert(run_state.inventory_state.get_used_capacity() == run_state.inventory_state.get_total_capacity(), "Expected full-backpack weapon swapping to preserve used capacity instead of overflowing.")


func test_inventory_actions_offer_discard_prompt_for_full_backpack_unequip() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	_fill_backpack_to_capacity(run_state)
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var active_weapon_slot_id: int = int(run_state.inventory_state.active_weapon_slot_id)
	var prompt_result: Dictionary = inventory_actions.toggle_equipment_slot(run_state.inventory_state, active_weapon_slot_id)
	assert(not bool(prompt_result.get("ok", false)), "Expected full-backpack unequip to defer behind an explicit discard choice.")
	assert(String(prompt_result.get("error", "")) == "inventory_choice_required", "Expected full-backpack unequip to return the shared inventory overflow prompt contract.")
	assert(not (prompt_result.get("discardable_slots", []) as Array).is_empty(), "Expected the unequip overflow prompt to offer discardable backpack slots.")
	var discard_slot_id: int = int(((prompt_result.get("discardable_slots", []) as Array)[0] as Dictionary).get("slot_id", -1))
	var resolve_result: Dictionary = inventory_actions.toggle_equipment_slot(run_state.inventory_state, active_weapon_slot_id, discard_slot_id)
	assert(bool(resolve_result.get("ok", false)), "Expected choosing a discard slot to finish the pending unequip.")
	assert(run_state.inventory_state.weapon_instance.is_empty(), "Expected the equipped weapon lane to be empty after resolving the full-backpack unequip.")
	assert(_inventory_contains_definition(run_state.inventory_state, "iron_sword"), "Expected the unequipped weapon to re-enter the backpack after discard resolution.")
	assert(not _inventory_contains_slot_id(run_state.inventory_state, discard_slot_id), "Expected the chosen discard slot to be removed from the backpack.")


func test_inventory_actions_attach_and_detach_shield_mods() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.inventory_state.set_left_hand_instance({
		"definition_id": "weathered_buckler",
		"inventory_family": InventoryState.INVENTORY_FAMILY_SHIELD,
	})
	var inventory_snapshot: Dictionary = run_state.inventory_state.to_save_dict()
	var next_slot_id: int = int(inventory_snapshot.get("inventory_next_slot_id", 1))
	var backpack_slots: Array = inventory_snapshot.get("backpack_slots", []).duplicate(true)
	backpack_slots.append({
		"slot_id": next_slot_id,
		"inventory_family": InventoryState.INVENTORY_FAMILY_SHIELD_ATTACHMENT,
		"definition_id": "reinforced_rim_lining",
	})
	inventory_snapshot["backpack_slots"] = backpack_slots
	inventory_snapshot["inventory_next_slot_id"] = next_slot_id + 1
	run_state.inventory_state.load_from_flat_save_dict(inventory_snapshot)

	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var attachment_slot_id: int = int(run_state.inventory_state.inventory_slots[1].get("slot_id", -1))
	var attach_result: Dictionary = inventory_actions.toggle_equipment_slot(run_state.inventory_state, attachment_slot_id)
	assert(bool(attach_result.get("ok", false)), "Expected shield attachment attach to succeed from the backpack.")
	assert(String(run_state.inventory_state.left_hand_instance.get("attachment_definition_id", "")) == "reinforced_rim_lining", "Expected the equipped shield to retain the attached mod id.")
	assert(run_state.inventory_state.inventory_slots.size() == 1, "Expected attaching a shield mod to remove the detached mod item from the backpack.")

	var detach_result: Dictionary = inventory_actions.toggle_equipment_slot(run_state.inventory_state, int(run_state.inventory_state.active_left_hand_slot_id))
	assert(bool(detach_result.get("ok", false)), "Expected clicking the equipped shield again to detach the attached mod.")
	assert(String(run_state.inventory_state.left_hand_instance.get("attachment_definition_id", "")) == "", "Expected detaching to clear shield attachment state.")
	assert(run_state.inventory_state.inventory_slots.size() == 2, "Expected detached shield mods to return to the backpack.")
	assert(String(run_state.inventory_state.inventory_slots[1].get("inventory_family", "")) == InventoryState.INVENTORY_FAMILY_SHIELD_ATTACHMENT, "Expected detached shield mods to re-enter the backpack as shield_attachment items.")


func test_inventory_actions_move_slot_to_index_reorders_backpack() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.inventory_state.set_armor_instance({"definition_id": "watcher_mail"})
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var replace_result: Dictionary = inventory_actions.replace_active_armor(run_state.inventory_state, "gatebound_cuirass")
	assert(bool(replace_result.get("ok", false)), "Expected a carried armor piece before backpack reorder coverage.")
	var carried_armor_slot_id: int = -1
	for slot in run_state.inventory_state.inventory_slots:
		if String(slot.get("inventory_family", "")) != InventoryState.INVENTORY_FAMILY_ARMOR:
			continue
		carried_armor_slot_id = int(slot.get("slot_id", -1))
		break
	assert(carried_armor_slot_id > 0, "Expected a carried armor slot to reorder inside the backpack.")
	var result: Dictionary = inventory_actions.move_slot_to_index(run_state.inventory_state, carried_armor_slot_id, 0)
	assert(bool(result.get("ok", false)), "Expected move_slot_to_index to reorder backpack slots.")
	assert(int(run_state.inventory_state.inventory_slots[0].get("slot_id", -1)) == carried_armor_slot_id, "Expected the carried armor slot to move into the requested backpack lane.")
	assert(String(run_state.inventory_state.armor_instance.get("definition_id", "")) == "gatebound_cuirass", "Expected equipped armor truth to survive backpack reorder.")


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
	assert(int(run_state.inventory_state.inventory_slots[carried_slot_index].get("upgrade_level", 0)) == 1, "Expected carried weapon upgrade to persist on the targeted backpack slot.")


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
	assert(int(run_state.inventory_state.inventory_slots[carried_slot_index].get("upgrade_level", 0)) == 1, "Expected carried armor upgrade to persist on the targeted backpack slot.")


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


func test_inventory_actions_replaces_oldest_non_equipped_item_when_backpack_is_full() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.inventory_state.set_passive_slots([
		{"definition_id": "iron_grip_charm"},
		{"definition_id": "sturdy_wraps"},
		{"definition_id": "packrat_clasp"},
		{"definition_id": "lean_pack_token"},
	])
	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var result: Dictionary = inventory_actions.add_passive_item(run_state.inventory_state, "tempered_binding", 2)
	assert(bool(result.get("ok", false)), "Expected add_passive_item to succeed.")
	assert(String(result.get("replaced_definition_id", "")) == "wild_berries", "Expected the oldest carried backpack item to be displaced when the backpack is full.")
	assert(String(result.get("replaced_family", "")) == "consumable", "Expected the displacement result to report the removed item family.")
	assert(run_state.inventory_state.passive_slots.size() == 5, "Expected the newly chosen passive to consume backpack space.")
	assert(String(run_state.inventory_state.passive_slots[4].get("definition_id", "")) == "tempered_binding", "Expected the newly chosen passive to occupy the newest backpack slot.")
	assert(run_state.inventory_state.consumable_slots.is_empty(), "Expected the displaced starter consumable to be removed from the backpack.")


func _fill_backpack_to_capacity(run_state: RunState, extra_slots: Array[Dictionary] = []) -> void:
	var inventory_snapshot: Dictionary = run_state.inventory_state.to_save_dict()
	var backpack_slots: Array = inventory_snapshot.get("backpack_slots", []).duplicate(true)
	var next_slot_id: int = int(inventory_snapshot.get("inventory_next_slot_id", 1))
	var filler_ids: Array[String] = [
		"sturdy_wraps",
		"packrat_clasp",
		"lean_pack_token",
		"tempered_binding",
	]
	var filler_index: int = 0
	while backpack_slots.size() + extra_slots.size() < run_state.inventory_state.get_total_capacity():
		backpack_slots.append({
			"slot_id": next_slot_id,
			"inventory_family": InventoryState.INVENTORY_FAMILY_PASSIVE,
			"definition_id": filler_ids[filler_index % filler_ids.size()],
		})
		next_slot_id += 1
		filler_index += 1
	for extra_slot_value in extra_slots:
		var extra_slot: Dictionary = (extra_slot_value as Dictionary).duplicate(true)
		extra_slot["slot_id"] = next_slot_id
		backpack_slots.append(extra_slot)
		next_slot_id += 1
	inventory_snapshot["backpack_slots"] = backpack_slots
	inventory_snapshot["inventory_next_slot_id"] = next_slot_id
	run_state.inventory_state.load_from_flat_save_dict(inventory_snapshot)
	assert(run_state.inventory_state.get_used_capacity() == run_state.inventory_state.get_total_capacity(), "Expected helper to fill the backpack to capacity.")


func _find_backpack_slot_id_by_definition(inventory_state: InventoryState, definition_id: String) -> int:
	for slot in inventory_state.inventory_slots:
		if String(slot.get("definition_id", "")) == definition_id:
			return int(slot.get("slot_id", -1))
	return -1


func _inventory_contains_definition(inventory_state: InventoryState, definition_id: String) -> bool:
	if inventory_state == null or definition_id.is_empty():
		return false
	for slot in inventory_state.inventory_slots:
		if String(slot.get("definition_id", "")) == definition_id:
			return true
	return false


func _inventory_contains_slot_id(inventory_state: InventoryState, slot_id: int) -> bool:
	if inventory_state == null or slot_id <= 0:
		return false
	for slot in inventory_state.inventory_slots:
		if int(slot.get("slot_id", -1)) == slot_id:
			return true
	return false


func _candidate_list_contains_definition(candidate_slots: Array[Dictionary], definition_id: String) -> bool:
	for candidate_slot in candidate_slots:
		if String(candidate_slot.get("definition_id", "")) == definition_id:
			return true
	return false


func _append_backpack_slot(run_state: RunState, slot_entry: Dictionary) -> void:
	var inventory_snapshot: Dictionary = run_state.inventory_state.to_save_dict()
	var backpack_slots: Array = inventory_snapshot.get("backpack_slots", []).duplicate(true)
	var next_slot_id: int = int(inventory_snapshot.get("inventory_next_slot_id", 1))
	var appended_slot: Dictionary = slot_entry.duplicate(true)
	appended_slot["slot_id"] = next_slot_id
	backpack_slots.append(appended_slot)
	inventory_snapshot["backpack_slots"] = backpack_slots
	inventory_snapshot["inventory_next_slot_id"] = next_slot_id + 1
	run_state.inventory_state.load_from_flat_save_dict(inventory_snapshot)


func test_inventory_actions_preserve_quest_items_when_backpack_is_full() -> void:
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	var inventory_snapshot: Dictionary = run_state.inventory_state.to_save_dict()
	var backpack_slots: Array = inventory_snapshot.get("backpack_slots", []).duplicate(true)
	var next_slot_id: int = int(inventory_snapshot.get("inventory_next_slot_id", 1))
	backpack_slots[0] = {
		"slot_id": next_slot_id,
		"inventory_family": InventoryState.INVENTORY_FAMILY_QUEST_ITEM,
		"definition_id": "hamlet_seal",
	}
	next_slot_id += 1
	for entry in [
		{"inventory_family": InventoryState.INVENTORY_FAMILY_PASSIVE, "definition_id": "iron_grip_charm"},
		{"inventory_family": InventoryState.INVENTORY_FAMILY_PASSIVE, "definition_id": "sturdy_wraps"},
		{"inventory_family": InventoryState.INVENTORY_FAMILY_PASSIVE, "definition_id": "packrat_clasp"},
		{"inventory_family": InventoryState.INVENTORY_FAMILY_PASSIVE, "definition_id": "lean_pack_token"},
	]:
		var slot_entry: Dictionary = entry.duplicate(true)
		slot_entry["slot_id"] = next_slot_id
		next_slot_id += 1
		backpack_slots.append(slot_entry)
	inventory_snapshot["backpack_slots"] = backpack_slots
	inventory_snapshot["inventory_next_slot_id"] = next_slot_id
	run_state.inventory_state.load_from_flat_save_dict(inventory_snapshot)

	var inventory_actions: RefCounted = InventoryActionsScript.new()
	var result: Dictionary = inventory_actions.add_passive_item(run_state.inventory_state, "tempered_binding", 2)
	assert(bool(result.get("ok", false)), "Expected add_passive_item to still succeed with a protected quest item in the backpack.")
	assert(String(result.get("replaced_definition_id", "")) == "iron_grip_charm", "Expected quest cargo to be skipped before backpack eviction reaches normal carried loot.")
	assert(String(run_state.inventory_state.inventory_slots[0].get("definition_id", "")) == "hamlet_seal", "Expected quest cargo to stay anchored in the backpack after normal-loot eviction.")


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
	armor_upgrade_level: int = 0,
	left_hand_slot: Dictionary = {},
	weapon_definition_id: String = "iron_sword",
	technique_definition_id: String = ""
) -> CombatFlow:
	var loader: ContentLoader = ContentLoader.new()
	var run_state: RunState = RunState.new()
	var inventory_actions: InventoryActions = InventoryActionsScript.new()
	run_state.reset_for_new_run()
	run_state.player_hp = 30
	run_state.hunger = RunState.DEFAULT_HUNGER
	run_state.xp = 0
	run_state.current_level = 1
	run_state.stage_index = 1
	run_state.equipped_technique_definition_id = technique_definition_id
	if weapon_definition_id != "iron_sword":
		var replace_result: Dictionary = inventory_actions.replace_active_weapon(run_state.inventory_state, weapon_definition_id)
		assert(bool(replace_result.get("ok", false)), "Expected test helper to swap the active weapon before combat setup.")
	run_state.inventory_state.weapon_instance["current_durability"] = starting_durability
	run_state.inventory_state.weapon_instance["upgrade_level"] = max(0, weapon_upgrade_level)
	run_state.inventory_state.set_armor_instance({"definition_id": armor_definition_id} if not armor_definition_id.is_empty() else {})
	if armor_upgrade_level > 0 and not run_state.inventory_state.armor_instance.is_empty():
		run_state.inventory_state.armor_instance["upgrade_level"] = armor_upgrade_level
	run_state.inventory_state.set_belt_instance({"definition_id": belt_definition_id} if not belt_definition_id.is_empty() else {})
	if not left_hand_slot.is_empty():
		run_state.inventory_state.set_left_hand_instance(left_hand_slot)
	var passive_slots: Array[Dictionary] = []
	for definition_id in passive_definition_ids:
		passive_slots.append({
			"definition_id": definition_id,
		})
	run_state.inventory_state.set_passive_slots(passive_slots)

	var weapon_def: Dictionary = loader.load_definition("Weapons", weapon_definition_id)
	var enemy_def: Dictionary = loader.load_definition("Enemies", "bone_raider")

	var flow: CombatFlow = CombatFlow.new()
	flow.setup_combat(run_state, enemy_def, weapon_def)
	return flow


func _on_combat_end_signal_for_test(_result: String) -> void:
	_combat_end_signal_count += 1
