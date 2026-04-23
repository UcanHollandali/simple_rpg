# Layer: UI
extends RefCounted
class_name FirstRunHintController

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")

const PANEL_NAME := "FirstRunHintPanel"
const LABEL_NAME := "FirstRunHintLabel"
const BUTTON_NAME := "FirstRunHintDismissButton"
const PANEL_MAX_WIDTH := 360.0
const PANEL_MIN_WIDTH := 240.0
const PANEL_MARGIN := 16.0
const PANEL_TOP_GAP := 16.0
const PANEL_OPEN_DURATION := 0.16
const PANEL_HIDDEN_SCALE := Vector2(0.98, 0.98)
const PANEL_VISIBLE_SCALE := Vector2.ONE
const FROZEN_HINT_IDS := [
	"first_combat_defend",
	"first_combat_technique",
	"first_combat_hand_swap",
	"first_left_hand_shield",
	"first_left_hand_offhand_weapon",
	"first_hamlet",
	"first_roadside_encounter",
	"first_key_required_route",
	"first_belt_capacity",
	"first_low_hunger_warning",
]
const HINT_MODELS := {
	"first_combat_defend": {
		"text": "Defend puts Guard in front of HP, but it costs +1 extra hunger. Some Guard carries into the next turn.",
		"accent": TempScreenThemeScript.TEAL_ACCENT_COLOR,
	},
	"first_combat_technique": {
		"text": "Techniques sit in the action row. Each one works once per combat and may stay unavailable until its condition is met.",
		"accent": TempScreenThemeScript.REWARD_ACCENT_COLOR,
	},
	"first_combat_hand_swap": {
		"text": "Hand Swap changes one hand slot from a packed spare and ends the turn. Armor and belt stay locked.",
		"accent": TempScreenThemeScript.RUST_ACCENT_COLOR,
	},
	"first_left_hand_shield": {
		"text": "The left hand is dual-purpose. It can hold a shield or an offhand weapon.",
		"accent": TempScreenThemeScript.TEAL_ACCENT_COLOR,
	},
	"first_left_hand_offhand_weapon": {
		"text": "Offhand weapons fit in the left hand, but they trade some Guard for extra pressure.",
		"accent": TempScreenThemeScript.RUST_ACCENT_COLOR,
	},
	"first_hamlet": {
		"text": "Hamlets follow the stage personality. Their requests stay deterministic within a run.",
		"accent": TempScreenThemeScript.REWARD_ACCENT_COLOR,
	},
	"first_roadside_encounter": {
		"text": "Roadside encounters interrupt travel, then send you back to the route you already chose.",
		"accent": TempScreenThemeScript.REWARD_ACCENT_COLOR,
	},
	"first_key_required_route": {
		"text": "Some routes need a key first. Find the key path before the boss lane opens.",
		"accent": TempScreenThemeScript.RUST_ACCENT_COLOR,
	},
	"first_belt_capacity": {
		"text": "Belts are backpack utility now. Equip one to open extra carry slots.",
		"accent": TempScreenThemeScript.REWARD_ACCENT_COLOR,
	},
	"first_low_hunger_warning": {
		"text": "Low hunger pressure carries across nodes. Let it stack too long and every route gets harsher.",
		"accent": TempScreenThemeScript.RUST_ACCENT_COLOR,
	},
}

signal hint_displayed(hint_id: String)
signal hint_dismissed(hint_id: String)

var _shown_hint_lookup: Dictionary = {}
var _pending_hint_ids: Array[String] = []
var _active_hint_id: String = ""
var _owner: Control
var _anchor_path: String = ""
var _z_index: int = 136
var _panel: PanelContainer
var _label: Label
var _dismiss_button: Button
var _tween: Tween
var _loader: ContentLoader = ContentLoaderScript.new()
var _weapon_offhand_cache: Dictionary = {}
var _belt_capacity_bonus_cache: Dictionary = {}


func setup(owner: Control, anchor_path: String, z_index: int = 136) -> void:
	if owner != _owner:
		_discard_panel()
	_owner = owner
	_anchor_path = anchor_path
	_z_index = z_index
	_ensure_panel()
	_refresh_visible_hint()


func release_host(owner: Control = null) -> void:
	if owner != null and owner != _owner:
		return
	_discard_panel()
	_owner = null
	_anchor_path = ""
	_panel = null
	_label = null
	_dismiss_button = null


func reset() -> void:
	_shown_hint_lookup.clear()
	_pending_hint_ids.clear()
	_active_hint_id = ""
	_hide_panel_immediate()


func load_from_save_data(saved_hint_ids: Variant) -> void:
	_shown_hint_lookup = _build_lookup(saved_hint_ids)
	_pending_hint_ids.clear()
	_active_hint_id = ""
	_hide_panel_immediate()


func has_shown_hint(hint_id: String) -> bool:
	var normalized_hint_id: String = _normalize_hint_id(hint_id)
	if normalized_hint_id.is_empty():
		return false
	return bool(_shown_hint_lookup.get(normalized_hint_id, false))


func mark_hint_shown(hint_id: String) -> bool:
	var normalized_hint_id: String = _normalize_hint_id(hint_id)
	if normalized_hint_id.is_empty():
		return false
	var was_already_shown: bool = has_shown_hint(normalized_hint_id)
	_shown_hint_lookup[normalized_hint_id] = true
	return not was_already_shown


func has_unshown_hints() -> bool:
	for hint_id in FROZEN_HINT_IDS:
		if not has_shown_hint(hint_id):
			return true
	return false


func mark_all_hints_shown() -> bool:
	var changed: bool = not _active_hint_id.is_empty() or not _pending_hint_ids.is_empty()
	for hint_id in FROZEN_HINT_IDS:
		if mark_hint_shown(hint_id):
			changed = true
	_pending_hint_ids.clear()
	_active_hint_id = ""
	_hide_panel_immediate()
	return changed


func build_save_data() -> Array[String]:
	var hint_ids: Array[String] = []
	for hint_id_variant in _shown_hint_lookup.keys():
		var hint_id: String = _normalize_hint_id(String(hint_id_variant))
		if hint_id.is_empty():
			continue
		hint_ids.append(hint_id)
	hint_ids.sort()
	return hint_ids


func request_hint(hint_id: String) -> bool:
	var normalized_hint_id: String = _normalize_hint_id(hint_id)
	if not _has_supported_hint(normalized_hint_id):
		return false
	if has_shown_hint(normalized_hint_id) or _active_hint_id == normalized_hint_id or _pending_hint_ids.has(normalized_hint_id):
		return false
	if _active_hint_id.is_empty():
		_activate_hint(normalized_hint_id)
	else:
		_pending_hint_ids.append(normalized_hint_id)
	return true


func dismiss_active_hint() -> void:
	if _active_hint_id.is_empty():
		return
	var dismissed_hint_id: String = _active_hint_id
	_active_hint_id = ""
	_hide_panel_immediate()
	hint_dismissed.emit(dismissed_hint_id)
	if not _pending_hint_ids.is_empty():
		var next_hint_id: String = String(_pending_hint_ids.pop_front())
		_activate_hint(next_hint_id)


func get_active_hint_id() -> String:
	return _active_hint_id


func get_pending_hint_ids() -> Array[String]:
	return _pending_hint_ids.duplicate()


func refresh_position() -> void:
	_position_panel()


func scan_inventory_hints(inventory_state: InventoryState) -> void:
	if inventory_state == null:
		return
	if _inventory_contains_shield(inventory_state):
		request_hint("first_left_hand_shield")
	if _inventory_contains_offhand_weapon(inventory_state):
		request_hint("first_left_hand_offhand_weapon")
	if _inventory_contains_capacity_belt(inventory_state):
		request_hint("first_belt_capacity")


func _activate_hint(hint_id: String) -> void:
	if not _has_supported_hint(hint_id):
		return
	_active_hint_id = hint_id
	mark_hint_shown(hint_id)
	_refresh_visible_hint()
	hint_displayed.emit(hint_id)


func _refresh_visible_hint() -> void:
	if _active_hint_id.is_empty():
		_hide_panel_immediate()
		return
	_ensure_panel()
	if _panel == null or _label == null or _dismiss_button == null:
		return
	var hint_model: Dictionary = HINT_MODELS.get(_active_hint_id, {})
	_label.text = String(hint_model.get("text", ""))
	var accent: Color = hint_model.get("accent", TempScreenThemeScript.PANEL_BORDER_COLOR)
	_apply_style(accent)
	_position_panel()
	_show_panel()


func _ensure_panel() -> void:
	if _owner == null or not is_instance_valid(_owner):
		return
	if _panel != null and is_instance_valid(_panel):
		if _panel.get_parent() != _owner:
			_discard_panel()
		else:
			_panel.z_index = _z_index
			return

	_panel = PanelContainer.new()
	_panel.name = PANEL_NAME
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.top_level = true
	_panel.z_index = _z_index
	_panel.modulate = Color(1, 1, 1, 0)
	_panel.scale = PANEL_HIDDEN_SCALE
	_owner.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.name = "HintVBox"
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_panel.add_child(vbox)

	_label = Label.new()
	_label.name = LABEL_NAME
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vbox.add_child(_label)

	_dismiss_button = Button.new()
	_dismiss_button.name = BUTTON_NAME
	_dismiss_button.text = "Got It"
	_dismiss_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_dismiss_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if not _dismiss_button.is_connected("pressed", Callable(self, "_on_dismiss_pressed")):
		_dismiss_button.pressed.connect(Callable(self, "_on_dismiss_pressed"))
	vbox.add_child(_dismiss_button)

	_apply_style(TempScreenThemeScript.TEAL_ACCENT_COLOR)


func _discard_panel() -> void:
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()
	_tween = null
	if _panel != null and is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null
	_label = null
	_dismiss_button = null


func _show_panel() -> void:
	if _panel == null or not is_instance_valid(_panel):
		return
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()
	_tween = null
	var was_visible: bool = _panel.visible and _panel.modulate.a > 0.01
	_panel.visible = true
	_panel.pivot_offset = _panel.size * 0.5
	if not was_visible:
		_panel.scale = PANEL_HIDDEN_SCALE
		_panel.modulate = Color(1, 1, 1, 0)
	_tween = _owner.create_tween() if _owner != null and is_instance_valid(_owner) else null
	if _tween == null:
		_panel.modulate = Color(1, 1, 1, 1)
		_panel.scale = PANEL_VISIBLE_SCALE
		return
	_tween.parallel().tween_property(_panel, "modulate", Color(1, 1, 1, 1), PANEL_OPEN_DURATION)
	_tween.parallel().tween_property(_panel, "scale", PANEL_VISIBLE_SCALE, PANEL_OPEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _hide_panel_immediate() -> void:
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()
	_tween = null
	if _panel == null or not is_instance_valid(_panel):
		return
	_panel.visible = false
	_panel.modulate = Color(1, 1, 1, 0)
	_panel.scale = PANEL_HIDDEN_SCALE


func _position_panel() -> void:
	if _owner == null or not is_instance_valid(_owner) or _panel == null or not is_instance_valid(_panel):
		return
	var viewport_size: Vector2 = _owner.get_viewport_rect().size
	var max_width: float = max(PANEL_MIN_WIDTH, viewport_size.x - (PANEL_MARGIN * 2.0))
	var panel_width: float = clampf(max_width, PANEL_MIN_WIDTH, PANEL_MAX_WIDTH)
	_panel.custom_minimum_size = Vector2(panel_width, 0.0)
	_panel.size = _measure_panel_size(panel_width)
	var panel_size: Vector2 = _panel.size
	var anchor_rect: Rect2 = _resolve_anchor_global_rect()
	var x_position: float = viewport_size.x - panel_size.x - PANEL_MARGIN
	var y_position: float = PANEL_MARGIN
	if anchor_rect.size != Vector2.ZERO:
		x_position = anchor_rect.position.x + anchor_rect.size.x - panel_size.x
		y_position = anchor_rect.position.y + max(0.0, anchor_rect.size.y - panel_size.y)
	x_position = clampf(
		x_position,
		PANEL_MARGIN,
		max(PANEL_MARGIN, viewport_size.x - panel_size.x - PANEL_MARGIN)
	)
	y_position = clampf(
		y_position,
		PANEL_MARGIN,
		max(PANEL_MARGIN, viewport_size.y - panel_size.y - PANEL_MARGIN)
	)
	_panel.global_position = Vector2(x_position, y_position)
	_panel.pivot_offset = panel_size * 0.5


func _measure_panel_size(panel_width: float) -> Vector2:
	if _panel == null or _label == null or _dismiss_button == null:
		return Vector2(panel_width, 0.0)
	var panel_style: StyleBox = _panel.get_theme_stylebox("panel")
	var horizontal_padding: float = 0.0
	var vertical_padding: float = 0.0
	if panel_style != null:
		horizontal_padding = panel_style.get_margin(SIDE_LEFT) + panel_style.get_margin(SIDE_RIGHT)
		vertical_padding = panel_style.get_margin(SIDE_TOP) + panel_style.get_margin(SIDE_BOTTOM)
	var label_width: float = max(200.0, panel_width - horizontal_padding)
	_label.custom_minimum_size = Vector2(label_width, 0.0)
	_label.size = Vector2(label_width, 0.0)
	_label.update_minimum_size()
	_label.reset_size()
	_dismiss_button.update_minimum_size()
	_dismiss_button.reset_size()
	var label_size: Vector2 = _label.get_combined_minimum_size()
	var button_size: Vector2 = _dismiss_button.get_combined_minimum_size()
	var content_height: float = label_size.y + 10.0 + button_size.y
	return Vector2(panel_width, max(content_height + vertical_padding, vertical_padding))


func _apply_style(accent: Color) -> void:
	if _panel == null or _label == null or _dismiss_button == null:
		return
	TempScreenThemeScript.apply_panel(_panel, accent, 16, 0.96)
	TempScreenThemeScript.apply_label(_label)
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.04, 0.72))
	_label.add_theme_constant_override("shadow_size", 2)
	TempScreenThemeScript.apply_small_button(_dismiss_button, accent, true)


func _on_dismiss_pressed() -> void:
	dismiss_active_hint()


func _resolve_anchor_global_rect() -> Rect2:
	if _owner == null or not is_instance_valid(_owner) or _anchor_path.is_empty():
		return Rect2()
	var anchor_control: Control = _owner.get_node_or_null(_anchor_path) as Control
	if anchor_control == null or not is_instance_valid(anchor_control) or not anchor_control.visible:
		return Rect2()
	return anchor_control.get_global_rect()


func _inventory_contains_shield(inventory_state: InventoryState) -> bool:
	if inventory_state == null:
		return false
	if String(inventory_state.left_hand_instance.get("inventory_family", "")) == InventoryStateScript.INVENTORY_FAMILY_SHIELD:
		return true
	for slot_value in inventory_state.inventory_slots:
		var slot: Dictionary = slot_value
		if String(slot.get("inventory_family", "")) == InventoryStateScript.INVENTORY_FAMILY_SHIELD:
			return true
	return false


func _inventory_contains_offhand_weapon(inventory_state: InventoryState) -> bool:
	if inventory_state == null:
		return false
	for slot in _inventory_equipment_and_backpack_slots(inventory_state):
		if String(slot.get("inventory_family", "")) != InventoryStateScript.INVENTORY_FAMILY_WEAPON:
			continue
		if _weapon_is_offhand_capable(String(slot.get("definition_id", ""))):
			return true
	return false


func _inventory_contains_capacity_belt(inventory_state: InventoryState) -> bool:
	if inventory_state == null:
		return false
	for slot in _inventory_equipment_and_backpack_slots(inventory_state):
		if String(slot.get("inventory_family", "")) != InventoryStateScript.INVENTORY_FAMILY_BELT:
			continue
		if _belt_capacity_bonus(String(slot.get("definition_id", ""))) > 0:
			return true
	return false


func _inventory_equipment_and_backpack_slots(inventory_state: InventoryState) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for slot_value in inventory_state.inventory_slots:
		if typeof(slot_value) == TYPE_DICTIONARY:
			slots.append((slot_value as Dictionary).duplicate(true))
	for slot in [
		inventory_state.right_hand_instance,
		inventory_state.left_hand_instance,
		inventory_state.armor_instance,
		inventory_state.belt_instance,
	]:
		if not slot.is_empty():
			slots.append(slot.duplicate(true))
	return slots


func _weapon_is_offhand_capable(definition_id: String) -> bool:
	var normalized_definition_id: String = definition_id.strip_edges()
	if normalized_definition_id.is_empty():
		return false
	if _weapon_offhand_cache.has(normalized_definition_id):
		return bool(_weapon_offhand_cache.get(normalized_definition_id, false))
	var definition: Dictionary = _loader.load_definition("Weapons", normalized_definition_id)
	var slot_compatibility: Dictionary = definition.get("rules", {}).get("slot_compatibility", {})
	var is_offhand_capable: bool = bool(slot_compatibility.get("offhand_capable", false))
	_weapon_offhand_cache[normalized_definition_id] = is_offhand_capable
	return is_offhand_capable


func _belt_capacity_bonus(definition_id: String) -> int:
	var normalized_definition_id: String = definition_id.strip_edges()
	if normalized_definition_id.is_empty():
		return 0
	if _belt_capacity_bonus_cache.has(normalized_definition_id):
		return int(_belt_capacity_bonus_cache.get(normalized_definition_id, 0))
	var definition: Dictionary = _loader.load_definition("Belts", normalized_definition_id)
	var bonus: int = max(0, int(definition.get("rules", {}).get("backpack_capacity_bonus", 0)))
	_belt_capacity_bonus_cache[normalized_definition_id] = bonus
	return bonus


func _has_supported_hint(hint_id: String) -> bool:
	return not hint_id.is_empty() and HINT_MODELS.has(hint_id) and FROZEN_HINT_IDS.has(hint_id)


func _build_lookup(saved_hint_ids: Variant) -> Dictionary:
	var shown_hint_lookup: Dictionary = {}
	if typeof(saved_hint_ids) != TYPE_ARRAY:
		return shown_hint_lookup
	for hint_id_variant in saved_hint_ids:
		var hint_id: String = _normalize_hint_id(String(hint_id_variant))
		if not _has_supported_hint(hint_id):
			continue
		shown_hint_lookup[hint_id] = true
	return shown_hint_lookup


func _normalize_hint_id(hint_id: String) -> String:
	return hint_id.strip_edges()
