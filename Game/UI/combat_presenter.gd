# Layer: UI
extends RefCounted
class_name CombatPresenter

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const ItemDefinitionTooltipBuilderScript = preload("res://Game/UI/item_definition_tooltip_builder.gd")
const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const CombatFeedbackFactoryScript = preload("res://Game/UI/combat_feedback_factory.gd")
const CombatCopyFormatterScript = preload("res://Game/UI/combat_copy_formatter.gd")
const CombatIntentVisualModelBuilderScript = preload("res://Game/UI/combat_intent_visual_model_builder.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")
const UiFormattingScript = preload("res://Game/UI/ui_formatting.gd")

var _loader: ContentLoader = ContentLoaderScript.new()
var _item_tooltip_builder: ItemDefinitionTooltipBuilder = ItemDefinitionTooltipBuilderScript.new()


func build_turn_text(combat_state: CombatState) -> String:
	return "Turn %d" % combat_state.current_turn


func build_combat_ready_text(combat_state: CombatState) -> String:
	if combat_state == null:
		return "Combat open. Pick your move."
	return "Turn %d. Pick your move." % max(1, int(combat_state.current_turn))


func build_intent_text(intent: Dictionary) -> String:
	return CombatCopyFormatterScript.build_intent_reveal_text(intent)


func build_intent_title_text() -> String:
	return CombatCopyFormatterScript.build_intent_title_text()


func build_intent_summary_text(intent: Dictionary, preview_snapshot: Dictionary = {}) -> String:
	return CombatCopyFormatterScript.build_intent_summary_text(intent, preview_snapshot)


func build_intent_detail_text(intent: Dictionary) -> String:
	return CombatCopyFormatterScript.build_intent_detail_text(intent)


func build_intent_icon_texture_path(intent: Dictionary) -> String:
	if intent.is_empty():
		return ""

	if not _intent_uses_damage_effect(intent):
		return ""

	if String(intent.get("threat_level", "")) == "high":
		return UiAssetPathsScript.ENEMY_INTENT_HEAVY_ICON_TEXTURE_PATH

	return UiAssetPathsScript.ENEMY_INTENT_ATTACK_ICON_TEXTURE_PATH


func build_enemy_bust_intent_visual_model(intent: Dictionary) -> Dictionary:
	return CombatIntentVisualModelBuilderScript.build_enemy_bust_intent_visual_model(intent)


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
	return CombatCopyFormatterScript.build_enemy_type_text(combat_state)


func build_enemy_trait_text(combat_state: CombatState) -> String:
	return CombatCopyFormatterScript.build_enemy_trait_text(combat_state)


func build_enemy_overview_text(combat_state: CombatState) -> String:
	return CombatCopyFormatterScript.build_enemy_overview_text(combat_state)


func build_enemy_hp_text(combat_state: CombatState, preview_snapshot: Dictionary = {}) -> String:
	return CombatCopyFormatterScript.build_enemy_hp_text(combat_state, preview_snapshot)


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
		"key": "guard",
		"label_text": "Guard",
		"value_text": str(max(0, int(combat_state.current_guard))),
		"semantic": "guard",
		"current_value": max(0, int(combat_state.current_guard)),
	})
	primary_items.append({
		"key": "hunger",
		"label_text": "Hunger",
		"value_text": UiFormattingScript.build_metric_value_text(combat_state.player_hunger, RunState.DEFAULT_HUNGER),
		"semantic": "hunger",
		"current_value": combat_state.player_hunger,
		"max_value": RunState.DEFAULT_HUNGER,
	})
	var durability_metric: Dictionary = _build_durability_metric_item(combat_state)
	primary_items.append({
		"key": "durability",
		"label_text": String(durability_metric.get("label_text", "Durability")),
		"value_text": UiFormattingScript.build_metric_value_text(
			int(combat_state.weapon_instance.get("current_durability", 0)),
			_extract_weapon_max_durability(combat_state)
		),
		"semantic": String(durability_metric.get("semantic", "durability")),
		"current_value": int(combat_state.weapon_instance.get("current_durability", 0)),
		"max_value": _extract_weapon_max_durability(combat_state),
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
		return "No offhand / armor / belt."
	return " | ".join(fragments)


func build_player_identity_text() -> String:
	return "Wayfinder"


func build_player_badge_text() -> String:
	return "YOU"


func build_defensive_action_label(_combat_state: CombatState = null) -> String:
	return "Defend"


func build_technique_action_label(combat_state: CombatState) -> String:
	if combat_state == null or not combat_state.has_equipped_technique():
		return "Technique"
	return String(
		combat_state.equipped_technique_definition.get("display", {}).get("name", combat_state.equipped_technique_definition_id)
	)


func build_technique_action_eyebrow_text(combat_state: CombatState) -> String:
	if combat_state == null or not combat_state.has_equipped_technique():
		return "TACTICAL TECHNIQUE"
	if bool(combat_state.technique_spent):
		return "SPENT THIS FIGHT"
	var effect_type: String = String(
		combat_state.equipped_technique_definition.get("rules", {}).get("effect", {}).get("type", "")
	).strip_edges()
	match effect_type:
		"remove_statuses":
			return "CLEAR AFFLICTIONS"
		"prime_next_attack":
			return "SET UP NEXT HIT"
		_:
			return "TACTICAL TECHNIQUE"


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
	match action_name:
		"attack":
			return CombatCopyFormatterScript.build_attack_action_preview(preview_snapshot)
		"defend":
			return CombatCopyFormatterScript.build_defend_action_preview(preview_snapshot)
		"technique":
			return _build_technique_action_preview_text(combat_state, preview_snapshot)
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


func build_combat_quickbar_title_text() -> String:
	return "Quick Use"


func build_combat_equipment_hint_text() -> String:
	return "Only hand swaps are legal here. Swap ends turn. Armor and belt stay locked."


func build_combat_quickbar_hint_text(combat_state: CombatState, preview_consumable_slot: Dictionary = {}) -> String:
	var base_text: String = "Only consumables work in combat."
	if combat_state == null:
		return base_text
	if preview_consumable_slot.is_empty():
		return "%s %s" % [base_text, "No consumable packed." if not _has_any_combat_consumable(combat_state) else "No consumable ready."]

	var item_name: String = _build_consumable_display_name(preview_consumable_slot)
	if item_name.is_empty():
		item_name = "Consumable"
	if not _is_consumable_slot_usable_in_combat(combat_state, preview_consumable_slot):
		return "%s %s won't help HP or hunger right now." % [base_text, item_name]

	var effect_profile: Dictionary = _extract_consumable_use_profile(preview_consumable_slot)
	var effect_fragments: PackedStringArray = []
	var heal_amount: int = int(effect_profile.get("heal_amount", 0))
	var hunger_restore: int = max(0, -int(effect_profile.get("hunger_delta", 0)))
	if heal_amount > 0:
		effect_fragments.append("+%d HP" % heal_amount)
	if hunger_restore > 0:
		effect_fragments.append("+%d hunger" % hunger_restore)
	if effect_fragments.is_empty():
		return "%s Tap %s. Ends turn." % [base_text, item_name]
	return "%s Tap %s for %s. Ends turn." % [
		base_text,
		item_name,
		" and ".join(effect_fragments),
	]


func build_hand_swap_surface_model(
	combat_state: CombatState,
	slot_candidates_by_name: Dictionary,
	selected_slot_name: String
) -> Dictionary:
	var ordered_slot_names: Array[String] = [
		InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND,
		InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND,
	]
	var visible_slot_names: Array[String] = []
	for slot_name in ordered_slot_names:
		var slot_candidates: Array = slot_candidates_by_name.get(slot_name, [])
		if slot_candidates.is_empty():
			continue
		visible_slot_names.append(slot_name)
	if visible_slot_names.is_empty():
		return {
			"visible": false,
		}

	var resolved_selected_slot_name: String = selected_slot_name
	if not visible_slot_names.has(resolved_selected_slot_name):
		resolved_selected_slot_name = visible_slot_names[0]

	var current_item_name: String = _build_hand_swap_equipped_item_name(combat_state, resolved_selected_slot_name)
	var selected_candidates: Array = slot_candidates_by_name.get(resolved_selected_slot_name, [])
	var slot_buttons: Array[Dictionary] = []
	for slot_name in visible_slot_names:
		var candidates: Array = slot_candidates_by_name.get(slot_name, [])
		slot_buttons.append({
			"slot_name": slot_name,
			"text": _build_hand_swap_slot_label(slot_name),
			"selected": slot_name == resolved_selected_slot_name,
			"count_text": "%d spare%s" % [candidates.size(), "" if candidates.size() == 1 else "s"],
		})

	var candidate_buttons: Array[Dictionary] = []
	for candidate_value in selected_candidates:
		if typeof(candidate_value) != TYPE_DICTIONARY:
			continue
		var candidate_slot: Dictionary = candidate_value
		candidate_buttons.append({
			"slot_id": int(candidate_slot.get("slot_id", -1)),
			"text": _build_hand_swap_candidate_display_name(candidate_slot),
			"hint_text": _build_hand_swap_candidate_hint_text(resolved_selected_slot_name, candidate_slot),
		})

	return {
		"visible": true,
		"title_text": "Hand Swap",
		"hint_text": "%s is %s. Tap a packed spare. Swap ends turn. Armor and belt stay locked." % [
			_build_hand_swap_slot_label(resolved_selected_slot_name),
			current_item_name,
		],
		"selected_slot_name": resolved_selected_slot_name,
		"slot_buttons": slot_buttons,
		"candidate_buttons": candidate_buttons,
	}


func build_action_tooltip_text(action_name: String, combat_state: CombatState, preview_consumable_slot: Dictionary = {}, preview_snapshot: Dictionary = {}) -> String:
	match action_name:
		"attack":
			return _build_attack_tooltip_text(combat_state, preview_snapshot)
		"defend":
			return _build_defend_tooltip_text(combat_state, preview_snapshot)
		"technique":
			return _build_technique_tooltip_text(combat_state, preview_snapshot)
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
			return "Defend raised %d guard. Costs +%d extra hunger." % [
				int(result.get("guard_generated", result.get("guard_points", 0))),
				int(result.get("extra_hunger_cost", 0)),
			]
		"technique":
			if bool(result.get("skipped", false)):
				return "Technique unavailable."
			return _format_technique_turn_phase_line(result)
		"use_item":
			if bool(result.get("skipped", false)):
				return "No consumable ready."
			return ""
		"swap_hand":
			if bool(result.get("skipped", false)):
				return "No legal hand swap."
			return "Swapped %s to %s." % [
				_build_hand_swap_slot_label(String(result.get("equipment_slot_name", ""))).to_lower(),
				_build_hand_swap_result_name(result),
			]
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
			var extra_hunger_cost: int = int(payload.get("extra_hunger_cost", 0))
			var hunger_cost_suffix: String = ""
			if extra_hunger_cost > 0:
				hunger_cost_suffix = " Costs +%d extra hunger." % extra_hunger_cost
			if bool(payload.get("shield_bonus_applied", false)):
				return "Defend raised %d guard with shield support.%s" % [guard_points, hunger_cost_suffix]
			if bool(payload.get("dual_wield_penalty_applied", false)):
				return "Defend raised %d guard while dual wielding.%s" % [guard_points, hunger_cost_suffix]
			return "Defend raised %d guard.%s" % [guard_points, hunger_cost_suffix]
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
		"TechniqueUsed":
			return _format_technique_domain_event_line(payload)
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


func _build_durability_metric_item(combat_state: CombatState) -> Dictionary:
	var current_durability: int = max(0, int(combat_state.weapon_instance.get("current_durability", 0)))
	var max_durability: int = _extract_weapon_max_durability(combat_state)
	if current_durability <= 0:
		return {
			"label_text": "BROKEN",
			"semantic": "danger",
		}
	if current_durability <= _resolve_low_durability_threshold(max_durability):
		return {
			"label_text": "LOW DUR.",
			"semantic": "danger",
		}
	return {
		"label_text": "Durability",
		"semantic": "durability",
	}


func _resolve_low_durability_threshold(max_durability: int) -> int:
	return max(1, int(ceil(float(max_durability) * 0.25)))


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
		return "Attack. Costs durability. Broken weapons hit for 1."

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
		return "Attack unarmed. Hits for 1.%s" % preview_fragment
	if current_durability <= 0:
		return "Attack with %s. Broken: hits for 1.%s" % [weapon_name, preview_fragment]
	return "Attack with %s. Costs durability.%s" % [weapon_name, preview_fragment]


func _build_defend_tooltip_text(combat_state: CombatState, preview_snapshot: Dictionary = {}) -> String:
	var base_text: String = "Defend. Gain guard before HP. Some guard carries. Shields add more. Costs +1 extra hunger."
	var left_hand_family: String = _left_hand_inventory_family(combat_state)
	if left_hand_family == "weapon":
		base_text += " Offhand weapons lower guard."
	if preview_snapshot.is_empty():
		return base_text

	var preview_texts: Dictionary = build_preview_texts(preview_snapshot)
	return "%s Expected %s into %s. %s." % [
		base_text,
		String(preview_texts.get("defend", "Guard ?")).to_lower(),
		String(preview_texts.get("guard_result", "Guard ? | HP ?")).to_lower(),
		String(preview_texts.get("defend_cost", "Turn -? hunger")),
	]


func _build_use_item_tooltip_text(combat_state: CombatState, preview_consumable_slot: Dictionary) -> String:
	if combat_state == null:
		return "Use a consumable card. HP or hunger only."

	if preview_consumable_slot.is_empty():
		return "Use a consumable card. HP or hunger only."

	var item_name: String = _build_consumable_display_name(preview_consumable_slot)
	if item_name.is_empty():
		item_name = "this item"

	if not _is_consumable_slot_usable_in_combat(combat_state, preview_consumable_slot):
		return "%s won't help HP or hunger right now." % item_name

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

	return "Use %s. No durability cost.%s" % [
		item_name,
		effect_summary,
	]


func _build_technique_action_preview_text(combat_state: CombatState, preview_snapshot: Dictionary = {}) -> String:
	if combat_state == null or not combat_state.has_equipped_technique():
		return "No technique equipped."
	if bool(preview_snapshot.get("technique_spent", combat_state.technique_spent)):
		return "Spent this combat."
	if not bool(preview_snapshot.get("technique_available", true)):
		match String(preview_snapshot.get("technique_unavailable_reason", "")):
			"no_statuses_to_cleanse":
				return "No afflictions to clear."
			_:
				return "Unavailable."

	var effect_type: String = String(preview_snapshot.get("technique_effect_type", ""))
	match effect_type:
		"remove_statuses":
			return _build_cleanse_preview_text(combat_state, preview_snapshot)
		"attack_ignore_armor":
			return "Hit %d | Ignore armor" % int(preview_snapshot.get("technique_damage_preview", 0))
		"attack_lifesteal":
			return "Hit %d | Heal %d" % [
				int(preview_snapshot.get("technique_damage_preview", 0)),
				int(preview_snapshot.get("technique_heal_preview", 0)),
			]
		"prime_next_attack":
			return "Prime x%d next attack" % int(preview_snapshot.get("technique_attack_multiplier_preview", 2))
		_:
			return String(preview_snapshot.get("technique_short_description", "Technique")).strip_edges()


func _build_technique_tooltip_text(combat_state: CombatState, preview_snapshot: Dictionary = {}) -> String:
	if combat_state == null or not combat_state.has_equipped_technique():
		return "No technique equipped."
	var display: Dictionary = combat_state.equipped_technique_definition.get("display", {})
	var short_description: String = String(display.get("short_description", "")).strip_edges()
	var base_text: String = "%s. Once per combat." % (
		short_description if not short_description.is_empty() else build_technique_action_label(combat_state)
	)
	if bool(preview_snapshot.get("technique_spent", combat_state.technique_spent)):
		return "%s Already spent this fight." % base_text
	match String(preview_snapshot.get("technique_unavailable_reason", "")):
		"no_statuses_to_cleanse":
			return "%s Unavailable until you have a current affliction to clear." % base_text
		_:
			if String(preview_snapshot.get("technique_effect_type", "")) == "remove_statuses":
				var current_afflictions_text: String = _build_current_affliction_names_text(combat_state.player_statuses)
				if not current_afflictions_text.is_empty():
					return "%s Current afflictions: %s." % [base_text, current_afflictions_text]
			return base_text


func _format_technique_turn_phase_line(result: Dictionary) -> String:
	var display_name: String = String(result.get("technique_display_name", result.get("technique_definition_id", "Technique")))
	match String(result.get("technique_effect_type", "")):
		"remove_statuses":
			var removed_status_count: int = int(result.get("removed_status_count", 0))
			var guard_gained: int = int(result.get("guard_gained", 0))
			if guard_gained > 0:
				return "%s cleared %d afflictions and raised %d guard." % [
					display_name,
					removed_status_count,
					guard_gained,
				]
			return "%s cleared %d afflictions." % [
				display_name,
				removed_status_count,
			]
		"attack_ignore_armor":
			return "%s hit through armor for %d." % [
				display_name,
				int(result.get("damage_applied", 0)),
			]
		"attack_lifesteal":
			return "%s hit for %d and healed %d." % [
				display_name,
				int(result.get("damage_applied", 0)),
				int(result.get("healed_amount", 0)),
			]
		"prime_next_attack":
			return "%s primed the next attack at x%d." % [
				display_name,
				int(result.get("queued_attack_multiplier", 1)),
			]
		_:
			return "%s resolved." % display_name


func _format_technique_domain_event_line(payload: Dictionary) -> String:
	var display_name: String = String(payload.get("display_name", payload.get("technique_definition_id", "Technique")))
	match String(payload.get("technique_effect_type", "")):
		"remove_statuses":
			return "%s is ready to clear afflictions." % display_name
		"attack_ignore_armor":
			return "%s will ignore armor on hit." % display_name
		"attack_lifesteal":
			return "%s will heal from damage dealt." % display_name
		"prime_next_attack":
			return "%s prepares a stronger next swing." % display_name
		_:
			return "%s equipped." % display_name


func _build_hand_swap_result_name(result: Dictionary) -> String:
	var definition_id: String = String(result.get("equipped_definition_id", "")).strip_edges()
	var inventory_family: String = String(result.get("equipped_inventory_family", "")).strip_edges()
	if definition_id.is_empty():
		return "new gear"
	return _build_inventory_item_display_name(inventory_family, definition_id, result)


func _build_hand_swap_slot_label(slot_name: String) -> String:
	match slot_name:
		InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND:
			return "Right Hand"
		InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND:
			return "Left Hand"
		_:
			return "Hand"


func _build_hand_swap_equipped_item_name(combat_state: CombatState, slot_name: String) -> String:
	if combat_state == null:
		return "Empty"
	match slot_name:
		InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND:
			return _build_inventory_item_display_name(
				InventoryStateScript.INVENTORY_FAMILY_WEAPON,
				String(combat_state.weapon_instance.get("definition_id", "")),
				combat_state.weapon_instance
			)
		InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND:
			var left_hand_slot: Dictionary = combat_state.left_hand_instance
			var inventory_family: String = String(left_hand_slot.get("inventory_family", "")).strip_edges()
			return _build_inventory_item_display_name(
				inventory_family,
				String(left_hand_slot.get("definition_id", "")),
				left_hand_slot
			)
		_:
			return "Empty"


func _build_hand_swap_candidate_display_name(slot: Dictionary) -> String:
	var inventory_family: String = String(slot.get("inventory_family", "")).strip_edges()
	var definition_id: String = String(slot.get("definition_id", "")).strip_edges()
	var display_name: String = _build_inventory_item_display_name(inventory_family, definition_id, slot)
	if inventory_family == InventoryStateScript.INVENTORY_FAMILY_WEAPON and int(slot.get("current_durability", 1)) <= 0:
		return "%s (Broken)" % display_name
	return display_name


func _build_hand_swap_candidate_hint_text(slot_name: String, slot: Dictionary) -> String:
	var display_name: String = _build_hand_swap_candidate_display_name(slot)
	var inventory_family: String = String(slot.get("inventory_family", "")).strip_edges()
	var hint_fragments: Array[String] = []
	match slot_name:
		InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND:
			var main_hand_summary: String = _item_tooltip_builder.build_definition_summary_text(
				InventoryStateScript.INVENTORY_FAMILY_WEAPON,
				String(slot.get("definition_id", "")),
				1,
				slot
			)
			hint_fragments.append("Main attack uses this weapon.")
			if not main_hand_summary.is_empty():
				hint_fragments.append(main_hand_summary)
		InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND:
			if inventory_family == InventoryStateScript.INVENTORY_FAMILY_SHIELD:
				hint_fragments.append("Shield lane: Defend +2.")
				var shield_passive_summary: String = _build_shield_swap_passive_summary_text(String(slot.get("definition_id", "")))
				if not shield_passive_summary.is_empty():
					hint_fragments.append(shield_passive_summary)
			elif inventory_family == InventoryStateScript.INVENTORY_FAMILY_WEAPON:
				hint_fragments.append("Offhand only: Attack +1 | Defend -1.")
				hint_fragments.append("Main attack stays in the right hand.")
		_:
			pass
	hint_fragments.append("Ends turn.")
	return "%s to %s. %s" % [
		display_name,
		_build_hand_swap_slot_label(slot_name).to_lower(),
		" ".join(hint_fragments),
	]


func _build_shield_swap_passive_summary_text(definition_id: String) -> String:
	var shield_definition: Dictionary = _loader.load_definition("Shields", definition_id)
	if shield_definition.is_empty():
		return ""
	var rules: Dictionary = shield_definition.get("rules", {})
	var behaviors: Array = rules.get("behaviors", [])
	var modifier_fragments: Array[String] = []
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
			var stat_name: String = String(params.get("stat", "")).strip_edges()
			var amount: int = int(params.get("amount", 0))
			match stat_name:
				"attack_power_bonus":
					modifier_fragments.append("%+d attack" % amount)
				"incoming_damage_flat_reduction":
					modifier_fragments.append("%+d defense" % amount)
				"durability_cost_flat_reduction":
					if amount < 0:
						modifier_fragments.append("%d less durability/use" % abs(amount))
					elif amount > 0:
						modifier_fragments.append("%+d durability/use" % amount)
				_:
					pass
	if modifier_fragments.is_empty():
		return ""
	return "Passive: %s." % " | ".join(modifier_fragments)


func _build_cleanse_preview_text(combat_state: CombatState, preview_snapshot: Dictionary) -> String:
	var affliction_text: String = _build_current_affliction_names_text(combat_state.player_statuses if combat_state != null else [])
	var removed_status_count: int = int(preview_snapshot.get("technique_removed_status_count", 0))
	var guard_gain: int = _resolve_cleanse_guard_gain(preview_snapshot, combat_state)
	var fragments: Array[String] = []
	if not affliction_text.is_empty():
		fragments.append("Clear %s" % affliction_text)
	elif removed_status_count > 0:
		fragments.append("Clear %d afflictions" % removed_status_count)
	else:
		fragments.append("Clear afflictions")
	if guard_gain > 0:
		fragments.append("Guard +%d" % guard_gain)
	return " | ".join(fragments)


func _build_current_affliction_names_text(statuses: Array) -> String:
	var names: Array[String] = []
	for status_value in statuses:
		if typeof(status_value) != TYPE_DICTIONARY:
			continue
		var status: Dictionary = status_value
		var definition_id: String = String(status.get("definition_id", "")).strip_edges()
		if definition_id.is_empty():
			continue
		var status_definition: Dictionary = _loader.load_definition("Statuses", definition_id)
		var display_name: String = String(status_definition.get("display", {}).get("name", definition_id)).strip_edges()
		if display_name.is_empty():
			continue
		names.append(display_name)
	if names.is_empty():
		return ""
	if names.size() == 1:
		return names[0]
	if names.size() == 2:
		return "%s + %s" % [names[0], names[1]]
	return "%s +%d more" % [names[0], names.size() - 1]


func _resolve_cleanse_guard_gain(preview_snapshot: Dictionary, combat_state: CombatState) -> int:
	var preview_guard_gain: int = int(preview_snapshot.get("technique_guard_gain_preview", 0))
	if preview_guard_gain > 0:
		return preview_guard_gain
	if combat_state == null or not combat_state.has_equipped_technique():
		return 0
	var params: Dictionary = combat_state.equipped_technique_definition.get("rules", {}).get("effect", {}).get("params", {})
	return max(0, int(params.get("guard_gain", 0)))


func _build_inventory_item_display_name(inventory_family: String, definition_id: String, slot: Dictionary = {}) -> String:
	if definition_id.is_empty():
		return "Empty"
	var slot_snapshot: Dictionary = slot.duplicate(true)
	if String(slot_snapshot.get("definition_id", "")).strip_edges().is_empty():
		slot_snapshot["definition_id"] = definition_id
	match inventory_family:
		InventoryStateScript.INVENTORY_FAMILY_WEAPON:
			return _build_equipment_display_name("Weapons", slot_snapshot)
		InventoryStateScript.INVENTORY_FAMILY_SHIELD:
			return _build_equipment_display_name("Shields", slot_snapshot)
		InventoryStateScript.INVENTORY_FAMILY_ARMOR:
			return _build_equipment_display_name("Armors", slot_snapshot)
		InventoryStateScript.INVENTORY_FAMILY_BELT:
			return _build_equipment_display_name("Belts", slot_snapshot)
		_:
			return definition_id


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


func _has_any_combat_consumable(combat_state: CombatState) -> bool:
	if combat_state == null:
		return false
	for slot_value in combat_state.consumable_slots:
		var slot: Dictionary = slot_value
		if String(slot.get("definition_id", "")).strip_edges().is_empty():
			continue
		if int(slot.get("current_stack", 0)) > 0:
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
