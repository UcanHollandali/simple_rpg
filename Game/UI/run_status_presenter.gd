# Layer: UI
extends RefCounted
class_name RunStatusPresenter

const UiFormattingScript = preload("res://Game/UI/ui_formatting.gd")

const VARIANT_COMPACT := "compact"
const VARIANT_STANDARD := "standard"
const VARIANT_MINIMAL := "minimal"


static func build_compact_status_text(run_state: RunState) -> String:
	if run_state == null:
		return ""

	var inventory_state: RefCounted = run_state.inventory_state
	return "%s | %s | %s | %s" % [
		UiFormattingScript.build_hp_text(run_state.player_hp),
		UiFormattingScript.build_hunger_text(run_state.hunger),
		UiFormattingScript.build_gold_text(run_state.gold),
		UiFormattingScript.build_durability_text(int(inventory_state.weapon_instance.get("current_durability", 0))),
	]


static func build_status_model(run_state: RunState, options: Dictionary = {}) -> Dictionary:
	var variant: String = _normalize_variant(String(options.get("variant", VARIANT_COMPACT)))
	var include_weapon: bool = bool(options.get("include_weapon", variant != VARIANT_MINIMAL))
	var include_xp: bool = bool(options.get("include_xp", variant == VARIANT_STANDARD))
	var density: String = variant
	if run_state == null:
		return {
			"variant": variant,
			"density": density,
			"primary_items": [],
			"secondary_items": [],
			"progress_items": [],
			"fallback_text": "",
		}

	var inventory_state: RefCounted = run_state.inventory_state
	var primary_items: Array[Dictionary] = [
		_build_metric_item("hp", "HP", UiFormattingScript.build_metric_value_text(run_state.player_hp, RunState.DEFAULT_PLAYER_HP), "health", run_state.player_hp, RunState.DEFAULT_PLAYER_HP),
		_build_metric_item("hunger", "Hunger", UiFormattingScript.build_metric_value_text(run_state.hunger, RunState.DEFAULT_HUNGER), "hunger", run_state.hunger, RunState.DEFAULT_HUNGER),
		_build_metric_item("gold", "Gold", UiFormattingScript.build_metric_value_text(run_state.gold), "gold", run_state.gold),
		_build_metric_item(
			"durability",
			"Durability",
			UiFormattingScript.build_metric_value_text(int(inventory_state.weapon_instance.get("current_durability", 0))),
			"durability",
			int(inventory_state.weapon_instance.get("current_durability", 0)),
			int(inventory_state.weapon_instance.get("max_durability", inventory_state.weapon_instance.get("current_durability", 0)))
		),
	]
	var secondary_items: Array[Dictionary] = []
	if include_weapon:
		secondary_items.append({
			"key": "weapon",
			"label_text": "Weapon",
			"value_text": UiFormattingScript.build_weapon_summary(inventory_state.weapon_instance),
			"semantic": "weapon",
		})

	var progress_items: Array[Dictionary] = []
	if include_xp:
		var xp_progress: Dictionary = UiFormattingScript.build_xp_progress_model(run_state.xp, run_state.current_level)
		progress_items.append({
			"key": "xp",
			"label_text": String(xp_progress.get("label_text", "XP")),
			"value_text": String(xp_progress.get("value_text", "0/0")),
			"current_value": int(xp_progress.get("current_value", 0)),
			"max_value": int(xp_progress.get("max_value", 1)),
			"fill_ratio": float(xp_progress.get("fill_ratio", 0.0)),
			"semantic": "xp",
		})

	var primary_rows: Array = _build_primary_rows(primary_items, options.get("primary_row_keys", []))

	return {
		"variant": variant,
		"density": density,
		"primary_items": primary_items,
		"primary_rows": primary_rows,
		"secondary_items": secondary_items,
		"progress_items": progress_items,
		"fallback_text": build_compact_status_text(run_state),
	}


static func _normalize_variant(variant: String) -> String:
	match variant:
		VARIANT_STANDARD, VARIANT_MINIMAL:
			return variant
		_:
			return VARIANT_COMPACT


static func _build_metric_item(key: String, label_text: String, value_text: String, semantic: String, current_value: int, max_value: int = -1) -> Dictionary:
	var item := {
		"key": key,
		"label_text": label_text,
		"value_text": value_text,
		"semantic": semantic,
	}
	item["current_value"] = current_value
	if max_value >= 0:
		item["max_value"] = max_value
	return item


static func _build_primary_rows(primary_items: Array[Dictionary], row_keys_variant: Variant) -> Array:
	if typeof(row_keys_variant) != TYPE_ARRAY:
		return []

	var item_by_key: Dictionary = {}
	for item in primary_items:
		var item_key: String = String(item.get("key", "")).strip_edges()
		if item_key.is_empty():
			continue
		item_by_key[item_key] = item

	var rows: Array = []
	for row_keys_variant_entry in row_keys_variant:
		if typeof(row_keys_variant_entry) != TYPE_ARRAY:
			continue
		var row_items: Array[Dictionary] = []
		for key_variant in row_keys_variant_entry:
			var item_key: String = String(key_variant).strip_edges()
			if item_key.is_empty() or not item_by_key.has(item_key):
				continue
			row_items.append(item_by_key[item_key])
		if not row_items.is_empty():
			rows.append(row_items)
	return rows
