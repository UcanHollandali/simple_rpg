# Layer: Tests
extends SceneTree
class_name TestCombatPresenter

const CombatPresenterScript = preload("res://Game/UI/combat_presenter.gd")


func _init() -> void:
	test_state_text_reflects_combat_snapshot()
	test_domain_event_and_turn_end_lines_are_human_readable()
	test_action_tooltips_describe_real_effects()
	test_feedback_models_expose_layered_intensity()
	print("test_combat_presenter: all assertions passed")
	quit()


func test_state_text_reflects_combat_snapshot() -> void:
	var presenter: RefCounted = CombatPresenterScript.new()
	var combat_state: CombatState = CombatState.new()
	combat_state.current_turn = 3
	combat_state.player_hp = 18
	combat_state.player_hunger = 7
	combat_state.weapon_instance = {"definition_id": "iron_sword", "current_durability": 11, "upgrade_level": 2}
	combat_state.left_hand_instance = {"definition_id": "weathered_buckler", "inventory_family": "shield"}
	combat_state.armor_instance = {"definition_id": "watcher_mail", "upgrade_level": 1}
	combat_state.belt_instance = {"definition_id": "trailhook_bandolier"}
	combat_state.consumable_slots = [
		{"definition_id": "traveler_bread", "current_stack": 2},
		{"definition_id": "wild_berries", "current_stack": 1},
	]
	combat_state.player_statuses = [
		{
			"display_name": "Poison",
			"remaining_turns": 2,
		},
	]
	combat_state.current_guard = 3
	combat_state.enemy_hp = 14

	assert(presenter.build_turn_text(combat_state) == "Turn 3", "Expected turn text to mirror current turn.")
	assert(
		presenter.build_intent_text({"intent_id": "heavy_strike", "threat_level": "high"}) == "Enemy intends: heavy_strike (high)",
		"Expected intent text to use stable combat intent fields."
	)
	assert(
		presenter.call("build_intent_summary_text", {
			"action_family": "attack",
			"effects": [
				{"type": "deal_damage", "params": {"base": 6}},
				{"type": "apply_status", "params": {"definition_id": "poison"}},
			],
		}) == "Hits for 6",
		"Expected combat presenter to expose the next enemy hit in damage-first language."
	)
	assert(
		presenter.call("build_intent_detail_text", {
			"action_family": "attack",
			"effects": [
				{"type": "deal_damage", "params": {"base": 6}},
				{"type": "apply_status", "params": {"definition_id": "poison"}},
			],
		}) == "Extra: Poison",
		"Expected combat presenter to move extra hit effects into a separate detail helper."
	)
	assert(
		presenter.call("build_intent_icon_texture_path", {
			"action_family": "attack",
			"threat_level": "medium",
			"effects": [{"type": "deal_damage", "params": {"base": 6}}],
		}) == "res://Assets/Icons/icon_enemy_intent_attack.svg",
		"Expected medium attack intents to resolve to the standard attack intent icon."
	)
	assert(
		presenter.call("build_intent_icon_texture_path", {
			"action_family": "attack",
			"threat_level": "high",
			"effects": [{"type": "deal_damage", "params": {"base": 9}}],
		}) == "res://Assets/Icons/icon_enemy_intent_heavy.svg",
		"Expected high-threat attack intents to resolve to the heavy intent icon."
	)
	assert(
		presenter.build_state_text(combat_state) == "Player HP: 18 | Hunger: 7 | Durability: 11 | Guard: 3 | Items: 3 | Status: Poison(2) | Enemy HP: 14",
		"Expected presenter state line to summarize combat-local truth."
	)
	combat_state.enemy_definition = {
		"definition_id": "bone_raider",
		"display": {"name": "Bone Raider"},
		"tags": ["enemy", "undead", "raider"],
		"rules": {
			"stats": {"base_hp": 24},
			"traits": ["armored"],
		},
	}
	assert(
		presenter.call("build_enemy_name_text", combat_state) == "Bone Raider",
		"Expected enemy title text to use runtime-backed display names."
	)
	assert(
		presenter.call("build_enemy_type_text", combat_state) == "Undead",
		"Expected combat presenter to expose the bare enemy type read without extra label noise."
	)
	assert(
		presenter.call("build_enemy_trait_text", combat_state) == "Armored",
		"Expected combat presenter to expose authored enemy trait hints without extra label noise."
	)
	assert(
		presenter.call("build_enemy_overview_text", combat_state) == "Undead | Armored",
		"Expected combat presenter to collapse the enemy overview into one compact line."
	)
	assert(
		presenter.call("build_enemy_hp_text", combat_state, {"enemy_defense_preview": 2}) == "HP 14/24 | Armor 2",
		"Expected enemy top-line vitals to show HP and armor together."
	)
	assert(
		presenter.call("build_player_identity_text") == "Wayfinder",
		"Expected combat presenter to expose the player-facing identity copy."
	)
	assert(
		presenter.call("build_player_badge_text") == "YOU",
		"Expected combat presenter to expose the player bust badge copy."
	)
	assert(
		presenter.call("build_resource_hud_texts", combat_state).get("hp", "") == "HP 18/60",
		"Expected resource HUD text to expose the compact HP read."
	)
	assert(
		presenter.call("build_player_bust_texture_path") == "res://Assets/Characters/player_bust.png",
		"Expected player bust lookup to stay presenter-owned."
	)
	assert(
		presenter.call("build_hp_icon_texture_path") == "res://Assets/Icons/icon_hp.svg",
		"Expected HP reads to resolve through the dedicated HP icon slot."
	)
	assert(
		presenter.call("build_hunger_icon_texture_path") == "res://Assets/Icons/icon_hunger.svg",
		"Expected hunger reads to resolve through the dedicated hunger icon slot."
	)
	assert(
		presenter.call("build_durability_icon_texture_path") == "res://Assets/Icons/icon_durability.svg",
		"Expected durability reads to resolve through the dedicated durability icon slot."
	)
	assert(
		presenter.call("build_enemy_bust_texture_path", combat_state) == "res://Assets/Enemies/enemy_bone_raider_bust.png",
		"Expected combat-state bust lookup to resolve through the stable enemy_<definition_id>_bust naming convention."
	)
	assert(
		presenter.call("build_enemy_bust_texture_path_from_definition_id", "gate_warden") == "res://Assets/Enemies/enemy_gate_warden_bust.png",
		"Expected boss bust lookup to reuse the same definition_id-based runtime naming convention."
	)
	var boss_combat_state: CombatState = CombatState.new()
	boss_combat_state.enemy_definition = {
		"definition_id": "gate_warden",
		"display": {"icon_key": "enemy_gate_warden"},
		"tags": ["enemy", "boss"],
	}
	assert(
		presenter.call("build_enemy_token_texture_path", boss_combat_state) == "res://Assets/Enemies/enemy_gate_warden_token.png",
		"Expected boss token lookup to resolve through the authored icon_key at the stable runtime token path."
	)
	assert(
		presenter.call("build_enemy_bust_texture_path_from_definition_id", "skeletal_hound") == "res://Assets/Enemies/enemy_skeletal_hound_bust.png",
		"Expected skeletal_hound to resolve once a matching runtime bust file exists."
	)
	assert(
		presenter.call("build_enemy_token_texture_path", combat_state).is_empty(),
		"Expected non-boss enemies to keep the boss-token slot empty."
	)
	assert(
		presenter.call("build_enemy_bust_texture_path_from_definition_id", "forest_brigand") == "res://Assets/Enemies/enemy_forest_brigand_bust.png",
		"Expected forest_brigand to resolve once a matching runtime bust file exists."
	)
	assert(
		presenter.call("build_enemy_bust_texture_path_from_definition_id", "carrion_runner") == "res://Assets/Enemies/enemy_venom_scavenger_bust.png",
		"Expected live enemies without bespoke busts to fall back to the closest readable prototype silhouette."
	)
	var early_boss_combat_state: CombatState = CombatState.new()
	early_boss_combat_state.enemy_definition = {
		"definition_id": "tollhouse_captain",
		"display": {"icon_key": "enemy_tollhouse_captain"},
		"tags": ["enemy", "boss"],
	}
	assert(
		presenter.call("build_enemy_token_texture_path", early_boss_combat_state) == "res://Assets/Enemies/enemy_gate_warden_token.png",
		"Expected early bosses without a bespoke token to reuse the current prototype boss token fallback."
	)
	assert(
		presenter.call("build_enemy_bust_texture_path_from_definition_id", "").is_empty(),
		"Expected empty definition ids to preserve the text-only fallback."
	)
	assert(
		presenter.call("build_enemy_bust_texture_path_from_definition_id", "missing_runtime_bust").is_empty(),
		"Expected missing runtime bust files to keep the empty-string fallback instead of inventing a path."
	)
	assert(
		presenter.call("build_active_weapon_text", combat_state) == "Active Weapon: Iron Sword +2",
		"Expected active weapon text to include forged weapon tiers."
	)
	var player_status_model: Dictionary = presenter.call("build_player_status_model", combat_state)
	var primary_items: Array = player_status_model.get("primary_items", [])
	var secondary_items: Array = player_status_model.get("secondary_items", [])
	assert(String(player_status_model.get("variant", "")) == "compact", "Expected combat status strip model to stay compact by default.")
	assert(primary_items.size() == 4, "Expected combat status strip primary lane to expose HP, hunger, durability, and guard.")
	assert(String((primary_items[0] as Dictionary).get("value_text", "")) == "18/60", "Expected combat status strip HP metric to expose current and max values.")
	assert(String((primary_items[1] as Dictionary).get("value_text", "")) == "7/20", "Expected combat status strip hunger metric to expose current and max values.")
	assert(int((primary_items[1] as Dictionary).get("current_value", -1)) == 7 and int((primary_items[1] as Dictionary).get("max_value", -1)) == 20, "Expected combat hunger metrics to expose numeric values for threshold warning presentation.")
	assert(String((primary_items[2] as Dictionary).get("value_text", "")) == "11/11", "Expected combat status strip durability metric to expose current and max values.")
	assert(String((primary_items[3] as Dictionary).get("value_text", "")) == "3", "Expected combat status strip to expose current guard.")
	assert(secondary_items.size() == 4, "Expected combat status strip secondary lane to expose weapon, left-hand, armor, and belt context.")
	assert(String((secondary_items[0] as Dictionary).get("value_text", "")) == "Iron Sword +2", "Expected combat status strip to surface the active weapon summary.")
	assert(String((secondary_items[1] as Dictionary).get("value_text", "")) == "Weathered Buckler", "Expected combat status strip to surface equipped left-hand summary.")
	assert(String((secondary_items[2] as Dictionary).get("value_text", "")) == "Watcher Mail +1", "Expected combat status strip to surface equipped armor summary.")
	assert(String((secondary_items[3] as Dictionary).get("value_text", "")) == "Trailhook Bandolier", "Expected combat status strip to surface equipped belt summary.")
	assert(
		presenter.call("build_player_loadout_text", combat_state) == "Shield Weathered Buckler | Armor Watcher Mail +1 | Belt Trailhook Bandolier",
		"Expected combat presenter to expose a concise player loadout summary row."
	)
	assert(
		presenter.call("build_defensive_action_label", combat_state) == "Defend",
		"Expected combat presenter to keep the current defensive action label while the slot stays generic."
	)
	assert(
		presenter.call("build_guard_badge_text", 3) == "Guard: 3",
		"Expected combat presenter to own the compact player-card guard badge copy."
	)
	var preview_texts: Dictionary = presenter.call("build_preview_texts", {
		"attack_damage_preview": 5,
		"attack_dodge_chance": 10,
		"uses_fallback_attack": false,
		"durability_spend_preview": 1,
		"defense_preview": 2,
		"incoming_damage_preview": 4,
		"guard_gain_preview": 2,
		"guard_absorb_preview": 2,
		"guard_damage_preview": 2,
		"hunger_tick_preview": 1,
	})
	assert(String(preview_texts.get("attack", "")) == "Hit 5 | Dodge 10%", "Expected preview text to show expected outgoing damage and dodge risk.")
	assert(String(preview_texts.get("defense", "")) == "Armor 2", "Expected preview text to expose armor readout.")
	assert(String(preview_texts.get("incoming", "")) == "Incoming 4", "Expected preview text to expose incoming damage readout.")
	assert(String(preview_texts.get("defend", "")) == "Guard 2", "Expected preview text to expose defend guard readout.")
	assert(String(preview_texts.get("guard_result", "")) == "Guard 2 | HP 2", "Expected preview text to expose guard-vs-HP fallout.")
	assert(String(preview_texts.get("hunger_tick", "")) == "Tick -1 hunger", "Expected preview text to expose the hunger tick cost.")
	assert(String(preview_texts.get("durability_spend", "")) == "Swing -1 durability", "Expected preview text to expose durability spend.")
	assert(String(preview_texts.get("intent_detail", "")) == "Incoming 4 | Guard 2", "Expected preview text to expose the enemy hit detail helper.")
	assert(
		presenter.call("build_weapon_slot_body_text", combat_state) == "Iron Sword +2",
		"Expected weapon quick-slot body text to resolve forged weapon display names outside the scene."
	)
	assert(
		presenter.call("build_consumable_slot_body_text", combat_state.consumable_slots[0]) == "Traveler Bread",
		"Expected consumable quick-slot body text to resolve authored consumable display names outside the scene."
	)
	assert(
		presenter.call("build_consumable_slot_body_text", {}) == "No Item",
		"Expected empty consumable slots to keep the no-item fallback."
	)
	assert(
		presenter.call("build_action_card_preview_text", "attack", combat_state, {}, {
			"attack_damage_preview": 5,
			"attack_dodge_chance": 10,
			"durability_spend_preview": 1,
		}) == "Deal 5 dmg | 10% miss | -1 dur",
		"Expected attack action card preview to use the compact player-facing action summary."
	)
	assert(
		presenter.call("build_action_card_preview_text", "defend", combat_state, {}, {
			"incoming_damage_preview": 4,
			"guard_gain_preview": 2,
			"guard_absorb_preview": 2,
			"guard_damage_preview": 2,
		}) == "Gain 2 guard | Take 2 dmg",
		"Expected defensive action card preview to explain the guard gain and remaining damage in plain language."
	)
	assert(
		presenter.call("build_action_card_preview_text", "use_item", combat_state, {"definition_id": "traveler_bread", "current_stack": 1}, {}) == "Traveler Bread | +8 HP | +2 hunger",
		"Expected item action card preview to summarize the ready consumable effect."
	)
	var chip_texts: PackedStringArray = presenter.call("build_status_chip_texts", combat_state.player_statuses, "No Player Status")
	assert(chip_texts.size() == 1 and chip_texts[0] == "Poison 2T", "Expected status chip text formatting for combat placeholder UI.")
	assert(
		presenter.build_status_log_text(PackedStringArray(["Line A", "Line B"])) == "Line A\nLine B",
		"Expected status log text to preserve line order."
	)
	assert(presenter.are_action_buttons_enabled(combat_state), "Expected buttons to stay enabled before combat ends.")
	combat_state.combat_ended = true
	assert(not presenter.are_action_buttons_enabled(combat_state), "Expected buttons to disable after combat ends.")


func test_domain_event_and_turn_end_lines_are_human_readable() -> void:
	var presenter: RefCounted = CombatPresenterScript.new()
	assert(
		presenter.format_action_result_line("Player", "enemy", {"damage_applied": 5}) == "Player hit enemy for 5.",
		"Expected action line to stay presentation-focused."
	)
	assert(
		presenter.format_turn_end_line({"current_turn": 4, "player_hunger": 9}) == "Turn 4 prepared. Hunger: 9.",
		"Expected turn-end line to stay stable."
	)
	assert(
		presenter.format_player_turn_phase_line("attack", {"damage_applied": 5}) == "Player hit enemy for 5.",
		"Expected attack phase line to reuse the player-facing action summary."
	)
	assert(
		presenter.format_player_turn_phase_line("use_item", {"skipped": true}) == "No usable item.",
		"Expected skipped use-item phase line to stay explicit for the combat shell."
	)
	assert(
		presenter.format_enemy_turn_phase_line({"damage_applied": 3}) == "Enemy hit player for 3.",
		"Expected enemy phase line to reuse the enemy action summary."
	)
	assert(
		presenter.format_domain_event_line("GuardGained", {"guard_points": 4, "shield_bonus_applied": true}) == "Defend raised 4 guard with shield support.",
		"Expected defend event lines to stay presenter-owned."
	)
	assert(
		presenter.format_domain_event_line("GuardAbsorbed", {"guard_absorbed": 3, "hp_damage": 1}) == "Guard absorbed 3 damage. 1 still reached HP.",
		"Expected guard-absorb event lines to stay presenter-owned."
	)
	assert(
		presenter.format_domain_event_line("ConsumableUsed", {"display_name": "Traveler Bread", "healed_amount": 8, "hunger_restored_amount": 10}) == "Used Traveler Bread and healed 8 HP while restoring hunger by 10.",
		"Expected consumable event lines to surface mixed HP and hunger recovery."
	)
	assert(
		presenter.format_domain_event_line("EnemyIntentRevealed", {"intent": {"intent_id": "jab", "threat_level": "low"}}) == "Enemy intends: jab (low)",
		"Expected intent reveal line to reuse presenter intent formatting."
	)


func test_action_tooltips_describe_real_effects() -> void:
	var presenter: RefCounted = CombatPresenterScript.new()
	var combat_state: CombatState = CombatState.new()
	combat_state.player_hp = 18
	combat_state.player_hunger = 12
	combat_state.weapon_instance = {
		"definition_id": "iron_sword",
		"current_durability": 2,
	}
	var attack_tooltip: String = presenter.call("build_action_tooltip_text", "attack", combat_state)
	assert(
		attack_tooltip.contains("Iron Sword") and attack_tooltip.contains("durability"),
		"Expected attack tooltip to describe the equipped weapon, durability use, and broken-weapon fallback."
	)
	var projected_attack_tooltip: String = presenter.call("build_action_tooltip_text", "attack", combat_state, {}, {
		"attack_damage_preview": 5,
		"attack_dodge_chance": 10,
		"durability_spend_preview": 1,
	})
	assert(
		projected_attack_tooltip.to_lower().contains("expected") and projected_attack_tooltip.to_lower().contains("hit 5") and projected_attack_tooltip.to_lower().contains("swing -1 durability"),
		"Expected attack tooltip to include the user-facing forecast copy when a preview snapshot is available."
	)

	combat_state.weapon_instance["current_durability"] = 0
	var broken_attack_tooltip: String = presenter.call("build_action_tooltip_text", "attack", combat_state)
	assert(
		broken_attack_tooltip.contains("Broken") and broken_attack_tooltip.contains("hits for 1"),
		"Expected attack tooltip to call out the weak fallback once durability hits zero."
	)

	var defend_tooltip: String = presenter.call("build_action_tooltip_text", "defend", combat_state)
	assert(
		defend_tooltip.contains("guard before HP") and defend_tooltip.contains("Shields add more") and defend_tooltip.contains("carries"),
		"Expected defend tooltip to describe guard order, carryover decay, and shield synergy."
	)
	var projected_defend_tooltip: String = presenter.call("build_action_tooltip_text", "defend", combat_state, {}, {
		"guard_gain_preview": 2,
		"guard_absorb_preview": 2,
		"guard_damage_preview": 2,
	})
	assert(
		projected_defend_tooltip.contains("guard 2") and projected_defend_tooltip.contains("hp 2"),
		"Expected defend tooltip to include the guard forecast when a preview snapshot is available."
	)

	var item_slot := {
		"definition_id": "traveler_bread",
		"current_stack": 1,
	}
	var use_item_tooltip: String = presenter.call("build_action_tooltip_text", "use_item", combat_state, item_slot)
	assert(
		use_item_tooltip.contains("Traveler Bread") and use_item_tooltip.contains("No durability cost") and use_item_tooltip.contains("restores hunger"),
		"Expected use-item tooltip to explain the direct-click consumable behavior in player-facing language."
	)


func test_feedback_models_expose_layered_intensity() -> void:
	var presenter: RefCounted = CombatPresenterScript.new()
	var light_model: Dictionary = presenter.call("build_impact_feedback_model", "player", 1)
	var medium_model: Dictionary = presenter.call("build_impact_feedback_model", "enemy", 4)
	var heavy_model: Dictionary = presenter.call("build_impact_feedback_model", "enemy", 7)
	assert(String(light_model.get("intensity", "")) == "light", "Expected chip damage to keep the light feedback tier.")
	assert(String(medium_model.get("intensity", "")) == "medium", "Expected mid-range hits to keep the medium feedback tier.")
	assert(String(heavy_model.get("intensity", "")) == "heavy", "Expected large hits to keep the heavy feedback tier.")
	assert(String(medium_model.get("text", "")) == "-4", "Expected feedback text to expose the damage amount.")
	assert(float(heavy_model.get("flash_alpha", 0.0)) > float(medium_model.get("flash_alpha", 1.0)), "Expected heavy hits to flash harder than medium hits.")
	assert(int(heavy_model.get("font_size", 0)) > int(light_model.get("font_size", 99)), "Expected heavy hits to render larger floating text than light hits.")
	assert(int(heavy_model.get("flash_cycles", 0)) == 2, "Expected impact feedback to use the double-flash timing from the style guide.")
	var guard_model: Dictionary = presenter.call("build_guard_feedback_model", 4)
	assert(String(guard_model.get("text", "")) == "Guard +4", "Expected guard feedback to expose the generated guard readout.")
	var guard_delta_model: Dictionary = presenter.call("build_guard_delta_feedback_model", 4, "guard")
	assert(String(guard_delta_model.get("text", "")) == "+4 guard", "Expected guard delta feedback to use the signed gain readout requested by combat UI.")
	var guard_decay_model: Dictionary = presenter.call("build_guard_decay_feedback_model", 1)
	assert(String(guard_decay_model.get("text", "")) == "-1 decay", "Expected guard decay feedback to surface turn-end carryover loss.")
	var guard_absorb_model: Dictionary = presenter.call("build_guard_absorb_feedback_model", 3)
	assert(String(guard_absorb_model.get("text", "")) == "Block 3", "Expected guard absorption feedback to read as mitigation instead of guard gain.")
	var recovery_models: Array[Dictionary] = presenter.call("build_recovery_feedback_models", 5, 16)
	assert(recovery_models.size() == 2, "Expected mixed HP and hunger recovery to emit two readable feedback bursts.")
	assert(String(recovery_models[0].get("text", "")) == "+5 HP", "Expected the first recovery burst to surface the HP gain.")
	assert(String(recovery_models[1].get("text", "")) == "+16 H", "Expected the second recovery burst to surface the hunger gain.")
	assert(int(recovery_models[0].get("flash_cycles", 0)) == 1, "Expected recovery feedback to stay softer than impact hits.")
