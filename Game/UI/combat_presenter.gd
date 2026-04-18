# Layer: UI
extends RefCounted
class_name CombatPresenter

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")
const CombatFeedbackFactoryScript = preload("res://Game/UI/combat_feedback_factory.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const UiFormattingScript = preload("res://Game/UI/ui_formatting.gd")

var _loader: ContentLoader = ContentLoaderScript.new()


func build_turn_text(combat_state: CombatState) -> String:
	return "Turn %d" % combat_state.current_turn


func build_intent_text(intent: Dictionary) -> String:
	return "Enemy intends: %s (%s)" % [
		String(intent.get("intent_id", "none")),
		String(intent.get("threat_level", "unknown")),
	]


func build_intent_summary_text(intent: Dictionary) -> String:
	return UiFormattingScript.build_enemy_intent_summary(intent)


func build_intent_icon_texture_path(intent: Dictionary) -> String:
	if intent.is_empty():
		return ""

	if not _intent_uses_damage_effect(intent):
		return ""

	if String(intent.get("threat_level", "")) == "high":
		return UiAssetPathsScript.ENEMY_INTENT_HEAVY_ICON_TEXTURE_PATH

	return UiAssetPathsScript.ENEMY_INTENT_ATTACK_ICON_TEXTURE_PATH


func build_enemy_name_text(combat_state: CombatState) -> String:
	var display: Dictionary = combat_state.enemy_definition.get("display", {})
	return String(display.get("name", combat_state.enemy_definition.get("definition_id", "Enemy")))


func build_player_bust_texture_path() -> String:
	return UiAssetPathsScript.PLAYER_BUST_TEXTURE_PATH


func build_enemy_bust_texture_path(combat_state: CombatState) -> String:
	var definition_id: String = String(combat_state.enemy_definition.get("definition_id", ""))
	return build_enemy_bust_texture_path_from_definition_id(definition_id)


func build_enemy_bust_texture_path_from_definition_id(definition_id: String) -> String:
	return UiAssetPathsScript.build_enemy_bust_texture_path(definition_id)


func build_enemy_token_texture_path(combat_state: CombatState) -> String:
	if combat_state == null:
		return ""

	var enemy_definition: Dictionary = combat_state.enemy_definition
	if not _enemy_definition_is_boss(enemy_definition):
		return ""

	var display: Dictionary = enemy_definition.get("display", {})
	return UiAssetPathsScript.build_enemy_token_texture_path(
		String(display.get("icon_key", "")),
		String(enemy_definition.get("definition_id", ""))
	)


func build_enemy_type_text(combat_state: CombatState) -> String:
	var tags_variant: Variant = combat_state.enemy_definition.get("tags", [])
	if typeof(tags_variant) != TYPE_ARRAY:
		return "Type: Unknown"

	var tags: Array = tags_variant
	for tag_value in tags:
		var tag: String = String(tag_value)
		if tag.is_empty() or tag == "enemy":
			continue
		return "Type: %s" % _humanize_identifier(tag)

	return "Type: Unknown"


func build_enemy_trait_text(combat_state: CombatState) -> String:
	if combat_state == null:
		return ""

	var traits_variant: Variant = combat_state.enemy_definition.get("rules", {}).get("traits", [])
	if typeof(traits_variant) != TYPE_ARRAY:
		return ""

	var trait_names: PackedStringArray = []
	for trait_value in traits_variant:
		var trait_name: String = _humanize_identifier(String(trait_value))
		if trait_name.is_empty():
			continue
		trait_names.append(trait_name)

	if trait_names.is_empty():
		return ""

	return "Traits: %s" % ", ".join(trait_names)


func build_enemy_hp_text(combat_state: CombatState) -> String:
	var max_hp: int = _extract_enemy_max_hp(combat_state)
	return "Enemy HP: %d/%d" % [combat_state.enemy_hp, max_hp]


func build_player_hp_text(combat_state: CombatState) -> String:
	return UiFormattingScript.build_hp_text(combat_state.player_hp, RunState.DEFAULT_PLAYER_HP, ": ")


func build_hp_icon_texture_path() -> String:
	return UiAssetPathsScript.HP_ICON_TEXTURE_PATH


func build_hunger_text(combat_state: CombatState) -> String:
	return UiFormattingScript.build_hunger_text(combat_state.player_hunger, RunState.DEFAULT_HUNGER, ": ")


func build_hunger_icon_texture_path() -> String:
	return UiAssetPathsScript.HUNGER_ICON_TEXTURE_PATH


func build_durability_text(combat_state: CombatState) -> String:
	var max_durability: int = _extract_weapon_max_durability(combat_state)
	return UiFormattingScript.build_durability_text(int(combat_state.weapon_instance.get("current_durability", 0)), max_durability, ": ")


func build_durability_icon_texture_path() -> String:
	return UiAssetPathsScript.DURABILITY_ICON_TEXTURE_PATH


func build_active_weapon_text(combat_state: CombatState) -> String:
	return "Active Weapon: %s" % UiFormattingScript.build_weapon_display_name(combat_state.weapon_instance)


func build_player_status_model(combat_state: CombatState) -> Dictionary:
	var primary_items: Array[Dictionary] = []
	var secondary_items: Array[Dictionary] = []
	if combat_state == null:
		return {
			"variant": "compact",
			"density": "compact",
			"primary_items": primary_items,
			"secondary_items": secondary_items,
			"progress_items": [],
			"fallback_text": "",
		}

	primary_items.append({
		"key": "hp",
		"label_text": "HP",
		"value_text": UiFormattingScript.build_metric_value_text(combat_state.player_hp, RunState.DEFAULT_PLAYER_HP),
		"semantic": "health",
		"current_value": combat_state.player_hp,
		"max_value": RunState.DEFAULT_PLAYER_HP,
	})
	primary_items.append({
		"key": "hunger",
		"label_text": "Hunger",
		"value_text": UiFormattingScript.build_metric_value_text(combat_state.player_hunger, RunState.DEFAULT_HUNGER),
		"semantic": "hunger",
		"current_value": combat_state.player_hunger,
		"max_value": RunState.DEFAULT_HUNGER,
	})
	primary_items.append({
		"key": "durability",
		"label_text": "Durability",
		"value_text": UiFormattingScript.build_metric_value_text(
			int(combat_state.weapon_instance.get("current_durability", 0)),
			_extract_weapon_max_durability(combat_state)
		),
		"semantic": "durability",
		"current_value": int(combat_state.weapon_instance.get("current_durability", 0)),
		"max_value": _extract_weapon_max_durability(combat_state),
	})
	primary_items.append({
		"key": "guard",
		"label_text": "Guard",
		"value_text": str(max(0, int(combat_state.current_guard))),
		"semantic": "guard",
		"current_value": max(0, int(combat_state.current_guard)),
	})

	secondary_items.append({
		"key": "weapon",
		"label_text": "Weapon",
		"value_text": UiFormattingScript.build_weapon_summary(combat_state.weapon_instance),
		"semantic": "weapon",
	})
	var left_hand_summary: String = _build_left_hand_summary(combat_state)
	if not left_hand_summary.is_empty():
		secondary_items.append({
			"key": "left_hand",
			"label_text": "Left Hand",
			"value_text": left_hand_summary,
			"semantic": "offhand",
		})

	var armor_name: String = _build_equipment_display_name("Armors", combat_state.armor_instance)
	if not armor_name.is_empty():
		secondary_items.append({
			"key": "armor",
			"label_text": "Armor",
			"value_text": armor_name,
			"semantic": "armor",
		})

	var belt_name: String = _build_equipment_display_name("Belts", combat_state.belt_instance)
	if not belt_name.is_empty():
		secondary_items.append({
			"key": "belt",
			"label_text": "Belt",
			"value_text": belt_name,
			"semantic": "offhand",
		})

	return {
		"variant": "compact",
		"density": "compact",
		"primary_items": primary_items,
		"secondary_items": secondary_items,
		"progress_items": [],
		"fallback_text": build_state_text(combat_state),
	}


func build_player_loadout_text(combat_state: CombatState) -> String:
	if combat_state == null:
		return ""

	var fragments: PackedStringArray = []
	var left_hand_summary: String = _build_left_hand_loadout_fragment(combat_state)
	if not left_hand_summary.is_empty():
		fragments.append(left_hand_summary)
	var armor_name: String = _build_equipment_display_name("Armors", combat_state.armor_instance)
	if not armor_name.is_empty():
		fragments.append("Armor %s" % armor_name)
	var belt_name: String = _build_equipment_display_name("Belts", combat_state.belt_instance)
	if not belt_name.is_empty():
		fragments.append("Belt %s" % belt_name)
	if fragments.is_empty():
		return "No left-hand, armor, or belt equipped."
	return " | ".join(fragments)


func build_player_identity_text() -> String:
	return "Wayfinder"


func build_player_badge_text() -> String:
	return "YOU"


func build_defensive_action_label(_combat_state: CombatState = null) -> String:
	return "Defend"


func build_resource_hud_texts(combat_state: CombatState) -> Dictionary:
	if combat_state == null:
		return {
			"hp": UiFormattingScript.build_hp_text(0, RunState.DEFAULT_PLAYER_HP),
			"hunger": UiFormattingScript.build_hunger_text(0, RunState.DEFAULT_HUNGER),
			"durability": UiFormattingScript.build_durability_text(0, 0),
		}

	return {
		"hp": UiFormattingScript.build_hp_text(combat_state.player_hp, RunState.DEFAULT_PLAYER_HP),
		"hunger": UiFormattingScript.build_hunger_text(combat_state.player_hunger, RunState.DEFAULT_HUNGER),
		"durability": UiFormattingScript.build_durability_text(
			int(combat_state.weapon_instance.get("current_durability", 0)),
			_extract_weapon_max_durability(combat_state),
		),
		"guard": "Guard %d" % max(0, int(combat_state.current_guard)),
	}


func build_impact_feedback_model(target: String, amount: int) -> Dictionary:
	var intensity: String = _resolve_impact_intensity(amount)
	var pulse_scale: float = 1.02
	var flash_alpha: float = 0.18
	var float_distance: float = 44.0
	var font_size: int = 22
	var pulse_out_duration: float = 0.18
	match intensity:
		"medium":
			pulse_scale = 1.045
			flash_alpha = 0.26
			float_distance = 56.0
			font_size = 26
			pulse_out_duration = 0.2
		"heavy":
			pulse_scale = 1.075
			flash_alpha = 0.38
			float_distance = 72.0
			font_size = 32
			pulse_out_duration = 0.22

	var flash_color: Color = TempScreenThemeScript.RUST_ACCENT_COLOR
	var font_color: Color = TempScreenThemeScript.RUST_ACCENT_COLOR.lightened(0.18)
	if target == "enemy":
		flash_color = TempScreenThemeScript.REWARD_ACCENT_COLOR
		font_color = TempScreenThemeScript.REWARD_ACCENT_COLOR.lightened(0.12)

	return {
		"target": target,
		"text": "-%d" % max(0, amount),
		"intensity": intensity,
		"flash_color": flash_color,
		"font_color": font_color,
		"flash_alpha": flash_alpha,
		"pulse_scale": pulse_scale,
		"float_distance": float_distance,
		"font_size": font_size,
		"feedback_stagger": 0.08,
		"flash_cycles": 2,
		"flash_on_duration": 0.06,
		"flash_off_duration": 0.06,
		"pulse_in_duration": 0.08,
		"pulse_out_duration": pulse_out_duration,
		"text_fade_in_duration": 0.08,
		"text_hold_duration": 0.16,
		"text_fade_out_duration": 0.16,
		"text_float_duration": 0.4,
	}


func build_guard_feedback_model(guard_amount: int) -> Dictionary:
	return CombatFeedbackFactoryScript.build_guard_feedback_model(guard_amount)


func build_guard_delta_feedback_model(guard_delta: int, label_text: String = "guard") -> Dictionary:
	return CombatFeedbackFactoryScript.build_guard_delta_feedback_model(guard_delta, label_text)


func build_guard_decay_feedback_model(decay_amount: int) -> Dictionary:
	return CombatFeedbackFactoryScript.build_guard_decay_feedback_model(decay_amount)


func build_guard_absorb_feedback_model(guard_amount: int) -> Dictionary:
	return CombatFeedbackFactoryScript.build_guard_absorb_feedback_model(guard_amount)


func build_recovery_feedback_models(healed_amount: int, hunger_restored_amount: int) -> Array[Dictionary]:
	return CombatFeedbackFactoryScript.build_recovery_feedback_models(healed_amount, hunger_restored_amount)


func build_preview_texts(preview_snapshot: Dictionary) -> Dictionary:
	return UiFormattingScript.build_consequence_preview_texts(preview_snapshot)


func build_guard_badge_text(guard_amount: int) -> String:
	return "Guard: %d" % max(0, guard_amount)


func build_quick_slot_title_text(slot_type: String) -> String:
	match slot_type:
		"weapon":
			return "EQ"
		"consumable":
			return "ITEM"
		_:
			return ""


func build_weapon_slot_body_text(combat_state: CombatState) -> String:
	return _build_quick_slot_body_text(UiFormattingScript.build_weapon_display_name(combat_state.weapon_instance), "Weapon")


func build_consumable_slot_body_text(consumable_slot: Dictionary) -> String:
	return _build_quick_slot_body_text(_build_consumable_display_name(consumable_slot), "No Item")


func _build_quick_slot_body_text(label_text: String, empty_label: String) -> String:
	if label_text.is_empty():
		return empty_label
	return label_text


func build_quick_slot_count_text(amount: int) -> String:
	return str(amount) if amount > 0 else ""


func build_action_card_preview_text(action_name: String, combat_state: CombatState, preview_consumable_slot: Dictionary = {}, preview_snapshot: Dictionary = {}) -> String:
	var preview_texts: Dictionary = build_preview_texts(preview_snapshot)
	match action_name:
		"attack":
			if preview_snapshot.is_empty():
				return "Weapon strike that spends durability."
			return "%s | %s" % [
				String(preview_texts.get("attack", "Hit ?")),
				String(preview_texts.get("durability_spend", "Swing -? durability")),
			]
		"defend":
			if preview_snapshot.is_empty():
				return "Gain guard before the enemy swing."
			return String(preview_texts.get("guard_result", "Guard ? | HP ?"))
		"use_item":
			if combat_state == null:
				return "Select a consumable card below."
			if preview_consumable_slot.is_empty():
				return "Select a consumable card below."
			var item_name: String = _build_consumable_display_name(preview_consumable_slot)
			if item_name.is_empty():
				item_name = "Consumable"
			if not _is_consumable_slot_usable_in_combat(combat_state, preview_consumable_slot):
				return "%s ready, but it needs missing HP or hunger." % item_name
			var effect_profile: Dictionary = _extract_consumable_use_profile(preview_consumable_slot)
			var effect_fragments: PackedStringArray = []
			var heal_amount: int = int(effect_profile.get("heal_amount", 0))
			var hunger_restore: int = max(0, -int(effect_profile.get("hunger_delta", 0)))
			if heal_amount > 0:
				effect_fragments.append("+%d HP" % heal_amount)
			if hunger_restore > 0:
				effect_fragments.append("+%d hunger" % hunger_restore)
			if effect_fragments.is_empty():
				return item_name
			return "%s | %s" % [item_name, " | ".join(effect_fragments)]
		_:
			return ""


func build_action_tooltip_text(action_name: String, combat_state: CombatState, preview_consumable_slot: Dictionary = {}, preview_snapshot: Dictionary = {}) -> String:
	match action_name:
		"attack":
			return _build_attack_tooltip_text(combat_state, preview_snapshot)
		"defend":
			return _build_defend_tooltip_text(combat_state, preview_snapshot)
		"use_item":
			return _build_use_item_tooltip_text(combat_state, preview_consumable_slot)
		_:
			return ""


func build_status_chip_texts(statuses: Array[Dictionary], empty_text: String) -> PackedStringArray:
	return UiFormattingScript.build_status_chip_texts(statuses, empty_text)


func build_state_text(combat_state: CombatState) -> String:
	var item_count: int = 0
	for slot_value in combat_state.consumable_slots:
		var slot: Dictionary = slot_value
		item_count += int(slot.get("current_stack", 0))

	return "Player HP: %d | Hunger: %d | Durability: %d | Guard: %d | Items: %d | Status: %s | Enemy HP: %d" % [
		combat_state.player_hp,
		combat_state.player_hunger,
		int(combat_state.weapon_instance.get("current_durability", 0)),
		max(0, int(combat_state.current_guard)),
		item_count,
		_format_status_summary(combat_state.player_statuses),
		combat_state.enemy_hp,
	]


func build_status_log_text(status_lines: PackedStringArray) -> String:
	return "\n".join(status_lines)


func are_action_buttons_enabled(combat_state: CombatState) -> bool:
	return not combat_state.combat_ended


func format_action_result_line(source_name: String, target_name: String, result: Dictionary) -> String:
	if bool(result.get("skipped", false)):
		return "%s action skipped." % source_name
	return "%s hit %s for %d." % [source_name, target_name, int(result.get("damage_applied", 0))]


func format_player_turn_phase_line(action_name: String, result: Dictionary) -> String:
	match action_name:
		"attack":
			return format_action_result_line("Player", "enemy", result)
		"defend":
			if bool(result.get("skipped", false)):
				return ""
			return "Defend raised %d guard." % int(result.get("guard_generated", result.get("guard_points", 0)))
		"use_item":
			if bool(result.get("skipped", false)):
				return "No usable item."
			return ""
		_:
			return ""


func format_enemy_turn_phase_line(result: Dictionary) -> String:
	return format_action_result_line("Enemy", "player", result)


func format_turn_end_line(turn_end_result: Dictionary) -> String:
	return "Turn %d prepared. Hunger: %d." % [
		int(turn_end_result.get("current_turn", 0)),
		int(turn_end_result.get("player_hunger", 0)),
	]


func format_domain_event_line(event_name: String, payload: Dictionary) -> String:
	match event_name:
		"DamageApplied":
			return "%s damage: %d" % [String(payload.get("target", "")), int(payload.get("amount", 0))]
		"DurabilityReduced":
			return "Durability: %d" % int(payload.get("current_durability", 0))
		"WeaponBroken":
			return "Weapon broke."
		"GuardGained":
			var guard_points: int = int(payload.get("guard_points", 0))
			if bool(payload.get("shield_bonus_applied", false)):
				return "Defend raised %d guard with shield support." % guard_points
			if bool(payload.get("dual_wield_penalty_applied", false)):
				return "Defend raised %d guard while dual wielding." % guard_points
			return "Defend raised %d guard." % guard_points
		"GuardAbsorbed":
			var guard_absorbed: int = int(payload.get("guard_absorbed", 0))
			var hp_damage: int = int(payload.get("hp_damage", 0))
			if hp_damage > 0:
				return "Guard absorbed %d damage. %d still reached HP." % [guard_absorbed, hp_damage]
			return "Guard absorbed %d damage." % guard_absorbed
		"ConsumableUsed":
			var item_name: String = String(payload.get("display_name", payload.get("definition_id", "")))
			var healed_amount: int = int(payload.get("healed_amount", 0))
			var hunger_restored_amount: int = int(payload.get("hunger_restored_amount", payload.get("hunger_reduced_amount", 0)))
			if healed_amount > 0 and hunger_restored_amount > 0:
				return "Used %s and healed %d HP while restoring hunger by %d." % [
					item_name,
					healed_amount,
					hunger_restored_amount,
				]
			if hunger_restored_amount > 0:
				return "Used %s and restored hunger by %d." % [
					item_name,
					hunger_restored_amount,
				]
			return "Used %s and healed %d HP." % [
				item_name,
				healed_amount,
			]
		"StatusApplied":
			return "%s applied to %s for %d turns." % [
				String(payload.get("display_name", payload.get("definition_id", ""))),
				String(payload.get("target", "")),
				int(payload.get("remaining_turns", 0)),
			]
		"StatusTicked":
			return "%s dealt %d damage to %s." % [
				String(payload.get("display_name", payload.get("definition_id", ""))),
				int(payload.get("damage_applied", 0)),
				String(payload.get("target", "")),
			]
		"StatusExpired":
			return "%s expired on %s." % [
				String(payload.get("definition_id", "")),
				String(payload.get("target", "")),
			]
		"BossPhaseChanged":
			return "Boss phase: %s." % String(payload.get("display_name", payload.get("phase_id", "")))
		"EnemyIntentRevealed":
			var intent: Dictionary = payload.get("intent", {})
			return build_intent_text(intent)
		_:
			return ""


func _format_status_summary(statuses: Array[Dictionary]) -> String:
	return UiFormattingScript.build_status_summary(statuses, "none", "inline")


func _extract_enemy_max_hp(combat_state: CombatState) -> int:
	var rules: Dictionary = combat_state.enemy_definition.get("rules", {})
	var stats: Dictionary = rules.get("stats", {})
	return max(1, int(stats.get("base_hp", combat_state.enemy_hp)))


func _extract_weapon_max_durability(combat_state: CombatState) -> int:
	return max(1, int(combat_state.weapon_instance.get("max_durability", combat_state.weapon_instance.get("current_durability", 1))))


func _build_equipment_display_name(definition_folder: String, equipment_instance: Dictionary) -> String:
	var definition_id: String = String(equipment_instance.get("definition_id", ""))
	if definition_id.is_empty() or definition_id == "none":
		return ""

	var definition: Dictionary = _loader.load_definition(definition_folder, definition_id)
	var display_name: String = String(definition.get("display", {}).get("name", definition_id))
	var upgrade_level: int = max(0, int(equipment_instance.get("upgrade_level", 0)))
	if upgrade_level <= 0:
		return display_name
	return "%s +%d" % [display_name, upgrade_level]


func _build_consumable_display_name(consumable_slot: Dictionary) -> String:
	var definition_id: String = String(consumable_slot.get("definition_id", ""))
	if definition_id.is_empty():
		return ""

	var consumable_definition: Dictionary = _loader.load_definition("Consumables", definition_id)
	var display: Dictionary = consumable_definition.get("display", {})
	return String(display.get("name", definition_id))


func _build_attack_tooltip_text(combat_state: CombatState, preview_snapshot: Dictionary = {}) -> String:
	if combat_state == null:
		return "Attack the enemy. Starting the swing spends weapon durability, and broken weapons fall back to a weak 1 damage hit."

	var weapon_name: String = UiFormattingScript.build_weapon_display_name(combat_state.weapon_instance)
	var current_durability: int = int(combat_state.weapon_instance.get("current_durability", 0))
	var preview_texts: Dictionary = build_preview_texts(preview_snapshot)
	var preview_fragment: String = ""
	if not preview_snapshot.is_empty():
		preview_fragment = " Expected %s and %s." % [
			String(preview_texts.get("attack", "Hit ?")).to_lower(),
			String(preview_texts.get("durability_spend", "Swing -? durability")).to_lower(),
		]
	if weapon_name == "None":
		return "Attack with no equipped weapon. This is a weak fallback hit that only deals 1 damage.%s" % preview_fragment
	if current_durability <= 0:
		return "Attack with %s. The weapon is broken, so hits fall back to 1 damage until it is repaired or replaced.%s" % [weapon_name, preview_fragment]
	return "Attack with %s. Starting the swing spends weapon durability even if the enemy dodges. If the weapon breaks, later hits fall back to 1 damage.%s" % [weapon_name, preview_fragment]


func _build_defend_tooltip_text(combat_state: CombatState, preview_snapshot: Dictionary = {}) -> String:
	var base_text: String = "Defend raises temporary guard for the next hit. Armor reduces damage first; any remainder hits guard before HP. Most leftover guard decays at turn end, but a small remainder can carry forward. A shield in the left hand increases the guard gain."
	var left_hand_family: String = _left_hand_inventory_family(combat_state)
	if left_hand_family == "weapon":
		base_text += " An offhand weapon adds attack pressure but lowers defend guard."
	if preview_snapshot.is_empty():
		return base_text

	var preview_texts: Dictionary = build_preview_texts(preview_snapshot)
	return "%s Expected %s into %s." % [
		base_text,
		String(preview_texts.get("defend", "Guard ?")).to_lower(),
		String(preview_texts.get("guard_result", "Guard ? | HP ?")).to_lower(),
	]


func _build_use_item_tooltip_text(combat_state: CombatState, preview_consumable_slot: Dictionary) -> String:
	if combat_state == null:
		return "Click a consumable card to use it directly in combat. This button is a fallback for the current ready item. Only self-heal or hunger recovery consumables work, and it does not spend durability."

	if preview_consumable_slot.is_empty():
		return "Click a consumable card below to use it directly. This button is a fallback for the current ready item; only self-heal or hunger recovery consumables work in combat."

	var item_name: String = _build_consumable_display_name(preview_consumable_slot)
	if item_name.is_empty():
		item_name = "this item"

	if not _is_consumable_slot_usable_in_combat(combat_state, preview_consumable_slot):
		return "Click a consumable card below to use it directly. %s is highlighted right now, but it only fires when it would heal HP or restore hunger." % item_name

	var effect_profile: Dictionary = _extract_consumable_use_profile(preview_consumable_slot)
	var effect_fragments: PackedStringArray = []
	var heal_amount: int = int(effect_profile.get("heal_amount", 0))
	var hunger_restore: int = max(0, -int(effect_profile.get("hunger_delta", 0)))
	if heal_amount > 0:
		effect_fragments.append("heals %d HP" % heal_amount)
	if hunger_restore > 0:
		effect_fragments.append("restores hunger by %d" % hunger_restore)

	var effect_summary: String = ""
	if not effect_fragments.is_empty():
		effect_summary = " It %s." % " and ".join(effect_fragments)

	return "Click a consumable card to use it directly, or press this button for the current ready item: %s. It does not spend durability and only triggers when it would change HP or hunger.%s" % [
		item_name,
		effect_summary,
	]


func _is_consumable_slot_usable_in_combat(combat_state: CombatState, consumable_slot: Dictionary) -> bool:
	if combat_state == null or consumable_slot.is_empty():
		return false

	var effect_profile: Dictionary = _extract_consumable_use_profile(consumable_slot)
	var heal_amount: int = int(effect_profile.get("heal_amount", 0))
	var hunger_delta: int = int(effect_profile.get("hunger_delta", 0))
	var missing_hp: int = RunState.DEFAULT_PLAYER_HP - combat_state.player_hp
	if heal_amount > 0 and missing_hp > 0:
		return true
	if hunger_delta < 0 and combat_state.player_hunger < RunState.DEFAULT_HUNGER:
		return true
	return false


func _extract_consumable_use_profile(consumable_slot: Dictionary) -> Dictionary:
	var definition_id: String = String(consumable_slot.get("definition_id", ""))
	if definition_id.is_empty():
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
		}

	var consumable_definition: Dictionary = _loader.load_definition("Consumables", definition_id)
	var use_effect: Dictionary = consumable_definition.get("rules", {}).get("use_effect", {})
	return InventoryActionsScript.extract_consumable_use_profile(use_effect)


func _intent_uses_damage_effect(intent: Dictionary) -> bool:
	if String(intent.get("action_family", "")) == "attack":
		return true

	var effects: Array = intent.get("effects", [])
	for effect_value in effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		if String((effect_value as Dictionary).get("type", "")) == "deal_damage":
			return true
	return false


func _enemy_definition_is_boss(enemy_definition: Dictionary) -> bool:
	var tags_variant: Variant = enemy_definition.get("tags", [])
	if typeof(tags_variant) != TYPE_ARRAY:
		return false

	var tags: Array = tags_variant
	for tag_value in tags:
		if String(tag_value) == "boss":
			return true
	return false


func _humanize_identifier(value: String) -> String:
	if value.is_empty():
		return ""
	var lowered: String = value.replace("_", " ")
	var words: PackedStringArray = lowered.split(" ", false)
	for index in range(words.size()):
		var word: String = words[index]
		if word.is_empty():
			continue
		words[index] = word.substr(0, 1).to_upper() + word.substr(1)
	return " ".join(words)


func _resolve_impact_intensity(amount: int) -> String:
	if amount >= 6:
		return "heavy"
	if amount >= 3:
		return "medium"
	return "light"


func _build_left_hand_summary(combat_state: CombatState) -> String:
	if combat_state == null:
		return ""
	var left_hand_family: String = _left_hand_inventory_family(combat_state)
	match left_hand_family:
		"shield":
			return _build_equipment_display_name("Shields", combat_state.left_hand_instance)
		"weapon":
			return UiFormattingScript.build_weapon_display_name(combat_state.left_hand_instance)
		_:
			return ""


func _build_left_hand_loadout_fragment(combat_state: CombatState) -> String:
	var left_hand_summary: String = _build_left_hand_summary(combat_state)
	if left_hand_summary.is_empty():
		return ""
	var left_hand_family: String = _left_hand_inventory_family(combat_state)
	if left_hand_family == "shield":
		return "Shield %s" % left_hand_summary
	if left_hand_family == "weapon":
		return "Offhand %s" % left_hand_summary
	return "Left Hand %s" % left_hand_summary


func _left_hand_inventory_family(combat_state: CombatState) -> String:
	if combat_state == null:
		return ""
	return String(combat_state.left_hand_instance.get("inventory_family", ""))
