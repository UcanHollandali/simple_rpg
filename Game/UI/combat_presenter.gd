# Layer: UI
extends RefCounted
class_name CombatPresenter

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")

var _loader: ContentLoader = ContentLoaderScript.new()


func build_turn_text(combat_state: CombatState) -> String:
	return "Turn %d" % combat_state.current_turn


func build_intent_text(intent: Dictionary) -> String:
	return "Enemy intends: %s (%s)" % [
		String(intent.get("intent_id", "none")),
		String(intent.get("threat_level", "unknown")),
	]


func build_intent_summary_text(intent: Dictionary) -> String:
	if intent.is_empty():
		return "Intent: Unknown"

	var parts: PackedStringArray = []
	var total_damage: int = 0
	var status_names: PackedStringArray = []
	var effects: Array = intent.get("effects", [])
	for effect_value in effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		var effect_type: String = String(effect.get("type", ""))
		var params: Dictionary = effect.get("params", {})
		match effect_type:
			"deal_damage":
				total_damage += int(params.get("base", 0))
			"apply_status":
				var status_id: String = String(params.get("definition_id", ""))
				if not status_id.is_empty():
					status_names.append(_humanize_identifier(status_id))

	if total_damage > 0:
		parts.append("Attack %d" % total_damage)
	for status_name in status_names:
		parts.append(status_name)

	if parts.is_empty():
		parts.append(_humanize_identifier(String(intent.get("action_family", intent.get("intent_id", "unknown")))))

	return "Intent: %s" % " + ".join(parts)


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
	return "HP: %d/%d" % [combat_state.player_hp, RunState.DEFAULT_PLAYER_HP]


func build_hp_icon_texture_path() -> String:
	return UiAssetPathsScript.HP_ICON_TEXTURE_PATH


func build_hunger_text(combat_state: CombatState) -> String:
	return "Hunger: %d/%d" % [combat_state.player_hunger, RunState.DEFAULT_HUNGER]


func build_hunger_icon_texture_path() -> String:
	return UiAssetPathsScript.HUNGER_ICON_TEXTURE_PATH


func build_durability_text(combat_state: CombatState) -> String:
	var max_durability: int = _extract_weapon_max_durability(combat_state)
	return "Durability: %d/%d" % [int(combat_state.weapon_instance.get("current_durability", 0)), max_durability]


func build_durability_icon_texture_path() -> String:
	return UiAssetPathsScript.DURABILITY_ICON_TEXTURE_PATH


func build_active_weapon_text(combat_state: CombatState) -> String:
	return "Active Weapon: %s" % _build_weapon_display_name(combat_state.weapon_instance)


func build_player_identity_text() -> String:
	return "Wayfinder"


func build_player_badge_text() -> String:
	return "YOU"


func build_resource_hud_texts(combat_state: CombatState) -> Dictionary:
	if combat_state == null:
		return {
			"hp": "HP 0/60",
			"hunger": "Hunger 0/%d" % RunState.DEFAULT_HUNGER,
			"durability": "Durability 0/0",
		}

	return {
		"hp": "HP %d/%d" % [combat_state.player_hp, RunState.DEFAULT_PLAYER_HP],
		"hunger": "Hunger %d/%d" % [combat_state.player_hunger, RunState.DEFAULT_HUNGER],
		"durability": "Durability %d/%d" % [
			int(combat_state.weapon_instance.get("current_durability", 0)),
			_extract_weapon_max_durability(combat_state),
		],
	}


func build_impact_feedback_model(target: String, amount: int) -> Dictionary:
	var intensity: String = _resolve_impact_intensity(amount)
	var pulse_scale: float = 1.02
	var flash_alpha: float = 0.18
	var float_distance: float = 44.0
	var font_size: int = 22
	match intensity:
		"medium":
			pulse_scale = 1.045
			flash_alpha = 0.26
			float_distance = 56.0
			font_size = 26
		"heavy":
			pulse_scale = 1.075
			flash_alpha = 0.38
			float_distance = 72.0
			font_size = 32

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
	}


func build_brace_feedback_model(raw_damage: int, reduced_damage: int) -> Dictionary:
	return {
		"target": "player",
		"text": "Brace %d->%d" % [raw_damage, reduced_damage],
		"intensity": "medium",
		"flash_color": TempScreenThemeScript.TEAL_ACCENT_COLOR,
		"font_color": TempScreenThemeScript.TEAL_ACCENT_COLOR.lightened(0.2),
		"flash_alpha": 0.22,
		"pulse_scale": 1.04,
		"float_distance": 48.0,
		"font_size": 20,
	}


func build_recovery_feedback_models(healed_amount: int, hunger_restored_amount: int) -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	if healed_amount > 0:
		models.append({
			"target": "player",
			"text": "+%d HP" % healed_amount,
			"intensity": "medium",
			"flash_color": TempScreenThemeScript.TEAL_ACCENT_COLOR,
			"font_color": TempScreenThemeScript.TEAL_ACCENT_COLOR.lightened(0.25),
			"flash_alpha": 0.18,
			"pulse_scale": 1.035,
			"float_distance": 52.0,
			"font_size": 24,
		})
	if hunger_restored_amount > 0:
		models.append({
			"target": "player",
			"text": "+%d H" % hunger_restored_amount,
			"intensity": "light",
			"flash_color": TempScreenThemeScript.REWARD_ACCENT_COLOR,
			"font_color": TempScreenThemeScript.REWARD_ACCENT_COLOR,
			"flash_alpha": 0.14,
			"pulse_scale": 1.025,
			"float_distance": 44.0,
			"font_size": 20,
		})
	return models


func build_preview_texts(preview_snapshot: Dictionary) -> Dictionary:
	if preview_snapshot.is_empty():
		return {
			"attack": "Hit ?",
			"defense": "Defense ?",
			"incoming": "Incoming ?",
			"brace": "Brace ?",
			"hunger_tick": "Tick -1 hunger",
			"durability_spend": "Swing -? durability",
			"intent_detail": "Incoming ? | Brace ?",
		}

	var attack_text: String = "Hit %d" % int(preview_snapshot.get("attack_damage_preview", 0))
	if bool(preview_snapshot.get("uses_fallback_attack", false)):
		attack_text = "Fallback %d" % int(preview_snapshot.get("attack_damage_preview", 0))
	var dodge_chance: int = int(preview_snapshot.get("attack_dodge_chance", 0))
	if dodge_chance > 0:
		attack_text = "%s | Dodge %d%%" % [attack_text, dodge_chance]

	return {
		"attack": attack_text,
		"defense": "Defense %d" % int(preview_snapshot.get("defense_preview", 0)),
		"incoming": "Incoming %d" % int(preview_snapshot.get("incoming_damage_preview", 0)),
		"brace": "Brace %d" % int(preview_snapshot.get("brace_damage_preview", 0)),
		"hunger_tick": "Tick -%d hunger" % int(preview_snapshot.get("hunger_tick_preview", 1)),
		"durability_spend": "Swing -%d durability" % int(preview_snapshot.get("durability_spend_preview", 0)),
		"intent_detail": "Incoming %d | Brace %d" % [
			int(preview_snapshot.get("incoming_damage_preview", 0)),
			int(preview_snapshot.get("brace_damage_preview", 0)),
		],
	}


func build_quick_slot_title_text(slot_type: String) -> String:
	match slot_type:
		"weapon":
			return "EQ"
		"consumable":
			return "ITEM"
		_:
			return ""


func build_weapon_slot_body_text(combat_state: CombatState) -> String:
	return _build_quick_slot_body_text(_build_weapon_display_name(combat_state.weapon_instance), "Weapon")


func build_consumable_slot_body_text(consumable_slot: Dictionary) -> String:
	return _build_quick_slot_body_text(_build_consumable_display_name(consumable_slot), "No Item")


func _build_quick_slot_body_text(label_text: String, empty_label: String) -> String:
	if label_text.is_empty():
		return empty_label
	return label_text


func build_quick_slot_count_text(amount: int) -> String:
	return str(amount) if amount > 0 else ""


func build_action_tooltip_text(action_name: String, combat_state: CombatState, preview_consumable_slot: Dictionary = {}, preview_snapshot: Dictionary = {}) -> String:
	match action_name:
		"attack":
			return _build_attack_tooltip_text(combat_state, preview_snapshot)
		"brace":
			return _build_brace_tooltip_text(preview_snapshot)
		"use_item":
			return _build_use_item_tooltip_text(combat_state, preview_consumable_slot)
		_:
			return ""


func build_status_chip_texts(statuses: Array[Dictionary], empty_text: String) -> PackedStringArray:
	if statuses.is_empty():
		return PackedStringArray([empty_text])

	var result: PackedStringArray = []
	for status in statuses:
		result.append("%s %dT" % [
			String(status.get("display_name", status.get("definition_id", ""))),
			int(status.get("remaining_turns", 0)),
		])
	return result


func build_state_text(combat_state: CombatState) -> String:
	var item_count: int = 0
	for slot_value in combat_state.consumable_slots:
		var slot: Dictionary = slot_value
		item_count += int(slot.get("current_stack", 0))

	return "Player HP: %d | Hunger: %d | Durability: %d | Items: %d | Status: %s | Brace: %s | Enemy HP: %d" % [
		combat_state.player_hp,
		combat_state.player_hunger,
		int(combat_state.weapon_instance.get("current_durability", 0)),
		item_count,
		_format_status_summary(combat_state.player_statuses),
		"on" if combat_state.brace_active else "off",
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
		"use_item":
			if bool(result.get("skipped", false)):
				return "No usable item."
			return ""
		"change_equipment":
			if bool(result.get("skipped", false)):
				return ""
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
		"BraceActivated":
			return "Brace prepared for the incoming hit."
		"BraceMitigated":
			return "Brace reduced damage from %d to %d." % [
				int(payload.get("raw_damage", 0)),
				int(payload.get("reduced_damage", 0)),
			]
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
		"EquipmentChanged":
			var item_name: String = String(payload.get("display_name", payload.get("definition_id", "")))
			var inventory_family: String = _humanize_identifier(String(payload.get("inventory_family", "equipment")))
			var is_equipped: bool = bool(payload.get("equipped", true))
			if is_equipped:
				return "Equipped %s as %s. The enemy still acts this turn." % [item_name, inventory_family.to_lower()]
			return "Unequipped %s from %s. The enemy still acts this turn." % [item_name, inventory_family.to_lower()]
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
	if statuses.is_empty():
		return "none"

	var parts: PackedStringArray = []
	for status in statuses:
		parts.append("%s(%d)" % [
			String(status.get("display_name", status.get("definition_id", ""))),
			int(status.get("remaining_turns", 0)),
		])
	return ", ".join(parts)


func _extract_enemy_max_hp(combat_state: CombatState) -> int:
	var rules: Dictionary = combat_state.enemy_definition.get("rules", {})
	var stats: Dictionary = rules.get("stats", {})
	return max(1, int(stats.get("base_hp", combat_state.enemy_hp)))


func _extract_weapon_max_durability(combat_state: CombatState) -> int:
	return max(1, int(combat_state.weapon_instance.get("max_durability", combat_state.weapon_instance.get("current_durability", 1))))


func _build_weapon_display_name(weapon_instance: Dictionary) -> String:
	var definition_id: String = String(weapon_instance.get("definition_id", "none"))
	if definition_id.is_empty() or definition_id == "none":
		return "None"

	var weapon_definition: Dictionary = _loader.load_definition("Weapons", definition_id)
	var display: Dictionary = weapon_definition.get("display", {})
	var display_name: String = String(display.get("name", definition_id))
	var upgrade_level: int = max(0, int(weapon_instance.get("upgrade_level", 0)))
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

	var weapon_name: String = _build_weapon_display_name(combat_state.weapon_instance)
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


func _build_brace_tooltip_text(preview_snapshot: Dictionary = {}) -> String:
	if preview_snapshot.is_empty():
		return "Brace for this turn. The next incoming hit is cut by 50%, rounded up. It deals no damage and does not spend durability."

	var preview_texts: Dictionary = build_preview_texts(preview_snapshot)
	return "Brace for this turn. The next incoming hit is cut by 50%%, rounded up. It deals no damage and does not spend durability. Expected %s into %s." % [
		String(preview_texts.get("incoming", "Incoming ?")).to_lower(),
		String(preview_texts.get("brace", "Brace ?")).to_lower(),
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
	if use_effect.is_empty():
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
		}
	if String(use_effect.get("trigger", "")) != "on_use":
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
		}
	if String(use_effect.get("target", "")) != "self":
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
		}

	var effects: Variant = use_effect.get("effects", [])
	if typeof(effects) != TYPE_ARRAY:
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
		}

	var heal_amount: int = 0
	var hunger_delta: int = 0
	for effect_value in effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		var params_value: Variant = effect.get("params", {})
		if typeof(params_value) != TYPE_DICTIONARY:
			continue
		var params: Dictionary = params_value
		match String(effect.get("type", "")):
			"heal":
				heal_amount += int(params.get("base", 0))
			"modify_hunger":
				hunger_delta += int(params.get("amount", 0))

	return {
		"heal_amount": heal_amount,
		"hunger_delta": hunger_delta,
	}


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
