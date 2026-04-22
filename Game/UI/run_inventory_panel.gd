# Layer: UI
extends RefCounted
class_name RunInventoryPanel

const InventoryPresenterScript = preload("res://Game/UI/inventory_presenter.gd")
const InventoryCardInteractionHandlerScript = preload("res://Game/UI/inventory_card_interaction_handler.gd")
const InventoryTooltipControllerScript = preload("res://Game/UI/inventory_tooltip_controller.gd")
const InventoryPanelLayoutScript = preload("res://Game/UI/inventory_panel_layout.gd")
const DENSITY_MAP := "map"
const DENSITY_COMBAT_COMPACT := "combat_compact"

var _owner: Control
var _config: Dictionary = {}
var _mode: String = "map"
var _inventory_presenter: InventoryPresenter
var _inventory_card_handler: InventoryCardInteractionHandler
var _inventory_tooltip_controller: InventoryTooltipController
var _equipment_cards_signature: String = ""
var _backpack_cards_signature: String = ""
var _external_drag_started_handler: Callable = Callable()


func configure(owner: Control, config: Dictionary) -> void:
	_owner = owner
	_config = config.duplicate(false)
	_inventory_presenter = InventoryPresenterScript.new()
	_inventory_card_handler = InventoryCardInteractionHandlerScript.new()
	_external_drag_started_handler = _config.get("drag_started_handler", Callable())
	if bool(_config.get("enable_tooltip", false)):
		_inventory_tooltip_controller = InventoryTooltipControllerScript.new()
		_inventory_tooltip_controller.configure(owner)
	else:
		_inventory_tooltip_controller = null

	var handler_config := {
		"click_handler": _config.get("click_handler", Callable()),
		"drag_complete_handler": _config.get("drag_complete_handler", Callable()),
		"drag_started_handler": Callable(self, "_on_drag_started"),
		"drag_threshold": float(_config.get("drag_threshold", 14.0)),
		"release_on_global_mouse_up": bool(_config.get("release_on_global_mouse_up", false)),
	}
	if _inventory_tooltip_controller != null:
		handler_config["mouse_entered_handler"] = Callable(_inventory_tooltip_controller, "on_inventory_card_mouse_entered")
		handler_config["mouse_exited_handler"] = Callable(_inventory_tooltip_controller, "on_inventory_card_mouse_exited")
	_inventory_card_handler.configure(owner, handler_config)


func set_interaction_mode(mode: String) -> void:
	_mode = mode


func get_presenter() -> InventoryPresenter:
	return _inventory_presenter


func build_combat_pack_summary_card(hidden_non_combat_count: int, hidden_empty_count: int) -> Dictionary:
	return _build_combat_pack_summary_card(hidden_non_combat_count, hidden_empty_count)


func build_combat_inventory_hint_text(
	base_hint: String,
	visible_cards: Array[Dictionary],
	hidden_non_combat_count: int
) -> String:
	return _build_combat_inventory_hint_text(base_hint, visible_cards, hidden_non_combat_count)


func handle_root_input(event: InputEvent) -> void:
	if _inventory_card_handler == null:
		return
	_inventory_card_handler.handle_root_input(event)


func refresh_hovered_tooltip() -> void:
	if _inventory_tooltip_controller == null:
		return
	_inventory_tooltip_controller.refresh_hovered_tooltip()


func release() -> void:
	if _inventory_card_handler != null:
		_inventory_card_handler.stop_interaction()
	if _inventory_tooltip_controller != null:
		_inventory_tooltip_controller.release()
	_inventory_presenter = null
	_inventory_card_handler = null
	_inventory_tooltip_controller = null
	_owner = null
	_config.clear()
	_equipment_cards_signature = ""
	_backpack_cards_signature = ""


func render(model: Dictionary) -> void:
	var equipment_container: Container = _config.get("equipment_container", null)
	var backpack_container: Container = _config.get("backpack_container", null)
	if _inventory_presenter == null or equipment_container == null or backpack_container == null:
		return

	if _inventory_tooltip_controller != null:
		_inventory_tooltip_controller.hide(true)
	if _inventory_card_handler != null:
		_inventory_card_handler.stop_interaction()

	var effective_model: Dictionary = model.duplicate(false)
	var drawer_enabled: bool = bool(model.get("drawer_enabled", false))
	var drawer_expanded: bool = bool(model.get("drawer_expanded", true))
	var drawer_contents_visible: bool = (not drawer_enabled) or drawer_expanded

	_apply_drawer_model(effective_model, drawer_enabled, drawer_expanded)
	_apply_text_model(effective_model, drawer_contents_visible)
	_apply_section_visibility(effective_model, equipment_container, backpack_container, drawer_contents_visible)
	if not drawer_contents_visible:
		_clear_cards(equipment_container)
		_clear_cards(backpack_container)
		return

	var clickable_resolver: Callable = model.get("clickable_resolver", Callable())
	var selected_resolver: Callable = model.get("selected_resolver", Callable())
	var draggable_resolver: Callable = model.get("draggable_resolver", Callable())
	var has_compact_mode_override: bool = model.has("card_compact_mode_override")
	var compact_mode_override: bool = bool(model.get("card_compact_mode_override", false))
	var density_preset: String = DENSITY_COMBAT_COMPACT if _mode == "combat" else String(model.get("layout_density", DENSITY_MAP))

	var equipment_card_models: Array[Dictionary] = _decorate_card_models(
		model.get("equipment_cards", []),
		clickable_resolver,
		selected_resolver,
		draggable_resolver,
		density_preset,
		has_compact_mode_override,
		compact_mode_override
	)
	var backpack_card_models: Array[Dictionary] = _decorate_card_models(
		model.get("backpack_cards", []),
		clickable_resolver,
		selected_resolver,
		draggable_resolver,
		density_preset,
		has_compact_mode_override,
		compact_mode_override
	)
	if _mode == "combat":
		equipment_card_models = _build_compact_combat_equipment_cards(equipment_card_models)
		var combat_backpack_state: Dictionary = _build_combat_visible_backpack_cards(
			backpack_card_models,
			String(effective_model.get("inventory_hint", ""))
		)
		backpack_card_models = combat_backpack_state.get("visible_cards", backpack_card_models)
		effective_model["inventory_hint"] = String(combat_backpack_state.get("inventory_hint", String(effective_model.get("inventory_hint", ""))))
		effective_model["inventory_hint_visible"] = true
		_apply_text_model(effective_model, true)
		_apply_section_visibility(effective_model, equipment_container, backpack_container, true)

	var equipment_signature: String = _inventory_card_models_signature(equipment_card_models)
	var backpack_signature: String = _inventory_card_models_signature(backpack_card_models)
	if _inventory_card_handler != null:
		if equipment_signature != _equipment_cards_signature:
			_inventory_card_handler.rebuild_cards(equipment_container, equipment_card_models)
			_equipment_cards_signature = equipment_signature
		if backpack_signature != _backpack_cards_signature:
			_inventory_card_handler.rebuild_cards(backpack_container, backpack_card_models)
			_backpack_cards_signature = backpack_signature

	if _mode == "combat":
		return

	var viewport_height: float = _owner.get_viewport_rect().size.y if _owner != null else 0.0
	var density_band: String = InventoryPanelLayoutScript.card_density_band_for_viewport_height(viewport_height)
	InventoryPanelLayoutScript.apply_card_density_overrides(equipment_container, density_band)
	InventoryPanelLayoutScript.apply_card_density_overrides(backpack_container, density_band)


func _apply_text_model(model: Dictionary, drawer_contents_visible: bool = true) -> void:
	var equipment_title_label: Label = _config.get("equipment_title_label", null)
	if equipment_title_label != null:
		equipment_title_label.text = String(model.get("equipment_title", ""))
		equipment_title_label.visible = drawer_contents_visible and bool(model.get("show_equipment", true))

	var equipment_hint_label: Label = _config.get("equipment_hint_label", null)
	if equipment_hint_label != null:
		equipment_hint_label.text = String(model.get("equipment_hint", ""))
		equipment_hint_label.visible = drawer_contents_visible and bool(model.get("equipment_hint_visible", not equipment_hint_label.text.is_empty()))

	var inventory_title_label: Label = _config.get("inventory_title_label", null)
	if inventory_title_label != null:
		inventory_title_label.text = String(model.get("inventory_title", ""))
		inventory_title_label.visible = drawer_contents_visible and bool(model.get("show_backpack", true))

	var inventory_hint_label: Label = _config.get("inventory_hint_label", null)
	if inventory_hint_label != null:
		inventory_hint_label.text = String(model.get("inventory_hint", ""))
		inventory_hint_label.visible = drawer_contents_visible and bool(model.get("inventory_hint_visible", not inventory_hint_label.text.is_empty()))


func _apply_drawer_model(model: Dictionary, drawer_enabled: bool, drawer_expanded: bool) -> void:
	var drawer_card: CanvasItem = _config.get("drawer_card", null)
	if drawer_card != null:
		drawer_card.visible = drawer_enabled

	var drawer_title_label: Label = _config.get("drawer_title_label", null)
	if drawer_title_label != null:
		drawer_title_label.text = String(model.get("drawer_title", ""))
		drawer_title_label.visible = drawer_enabled and not drawer_title_label.text.is_empty()

	var drawer_summary_label: Label = _config.get("drawer_summary_label", null)
	if drawer_summary_label != null:
		drawer_summary_label.text = String(model.get("drawer_summary", ""))
		drawer_summary_label.visible = drawer_enabled and not drawer_summary_label.text.is_empty()

	var drawer_toggle_button: Button = _config.get("drawer_toggle_button", null)
	if drawer_toggle_button != null:
		drawer_toggle_button.text = String(model.get("drawer_toggle_text", ""))
		drawer_toggle_button.visible = drawer_enabled
		drawer_toggle_button.disabled = not drawer_enabled
		drawer_toggle_button.set_meta("drawer_expanded", drawer_expanded)


func _apply_section_visibility(
	model: Dictionary,
	equipment_container: Container,
	backpack_container: Container,
	drawer_contents_visible: bool
) -> void:
	var show_equipment: bool = drawer_contents_visible and bool(model.get("show_equipment", true))
	var show_backpack: bool = drawer_contents_visible and bool(model.get("show_backpack", true))

	var equipment_panel: CanvasItem = _config.get("equipment_panel", null)
	if equipment_panel != null:
		equipment_panel.visible = show_equipment
	equipment_container.visible = show_equipment

	var backpack_panel: CanvasItem = _config.get("backpack_panel", null)
	if backpack_panel != null:
		backpack_panel.visible = show_backpack
	backpack_container.visible = show_backpack


func _clear_cards(container: Container) -> void:
	if container == null:
		return
	if _inventory_card_handler != null:
		_inventory_card_handler.rebuild_cards(container, [])
	else:
		for child in container.get_children():
			child.queue_free()
	if container == _config.get("equipment_container", null):
		_equipment_cards_signature = ""
	elif container == _config.get("backpack_container", null):
		_backpack_cards_signature = ""


func _build_compact_combat_equipment_cards(card_models: Array[Dictionary]) -> Array[Dictionary]:
	var compact_models: Array[Dictionary] = []
	for card_model in card_models:
		var compact_model: Dictionary = card_model.duplicate(true)
		compact_model["compact_mode"] = true
		compact_model["density_preset"] = DENSITY_COMBAT_COMPACT
		compact_models.append(compact_model)
	return compact_models


func _build_combat_visible_backpack_cards(card_models: Array[Dictionary], base_hint: String) -> Dictionary:
	var usable_consumables: Array[Dictionary] = []
	var resting_consumables: Array[Dictionary] = []
	var hidden_non_combat_count: int = 0
	var hidden_empty_count: int = 0

	for source_card_model in card_models:
		var visible_card_model: Dictionary = source_card_model.duplicate(true)
		visible_card_model["compact_mode"] = false
		visible_card_model["density_preset"] = DENSITY_COMBAT_COMPACT
		var card_family: String = String(visible_card_model.get("card_family", ""))
		if card_family == "consumable":
			if bool(visible_card_model.get("is_clickable", false)):
				usable_consumables.append(visible_card_model)
			else:
				resting_consumables.append(visible_card_model)
			continue
		if card_family == "empty":
			hidden_empty_count += 1
			continue
		hidden_non_combat_count += 1

	var visible_cards: Array[Dictionary] = []
	visible_cards.append_array(usable_consumables)
	visible_cards.append_array(resting_consumables)
	if visible_cards.is_empty():
		visible_cards.append(_build_combat_pack_summary_card(hidden_non_combat_count, hidden_empty_count))

	return {
		"visible_cards": visible_cards,
		"inventory_hint": _build_combat_inventory_hint_text(base_hint, visible_cards, hidden_non_combat_count),
	}


func _build_combat_pack_summary_card(hidden_non_combat_count: int, hidden_empty_count: int) -> Dictionary:
	var detail_text: String = "Pack empty"
	if hidden_non_combat_count > 0:
		detail_text = "%d other pack card%s packed away" % [hidden_non_combat_count, "" if hidden_non_combat_count == 1 else "s"]
	elif hidden_empty_count > 0:
		detail_text = "%d open slot%s" % [hidden_empty_count, "" if hidden_empty_count == 1 else "s"]
	return {
		"card_name": "InventorySlotCombatPackSummaryCard",
		"card_family": "empty",
		"slot_index": -1,
		"inventory_slot_index": -1,
		"inventory_slot_id": -1,
		"slot_label": "COMBAT PACK",
		"title_text": "No consumable ready",
		"detail_text": detail_text,
		"count_text": "",
		"icon_texture_path": "",
		"tooltip_text": "",
		"accent_color": Color(0.72, 0.78, 0.84, 0.96),
		"is_clickable": false,
		"is_selected": false,
		"is_draggable": false,
		"is_equipped": false,
		"density_preset": DENSITY_COMBAT_COMPACT,
		"compact_mode": false,
		"action_hint_text": "",
		"action_hint_tone": "disabled",
	}


func _build_combat_inventory_hint_text(base_hint: String, visible_cards: Array[Dictionary], hidden_non_combat_count: int) -> String:
	var hint_text: String = base_hint.strip_edges()
	var has_visible_consumable: bool = false
	for card_model in visible_cards:
		if String(card_model.get("card_family", "")) == "consumable":
			has_visible_consumable = true
			break
	if hint_text.is_empty():
		hint_text = "Only consumables work in combat."
	if not has_visible_consumable:
		return "No consumable packed." if hidden_non_combat_count > 0 else "Pack empty."
	if hidden_non_combat_count <= 0:
		return hint_text
	return "%s %d other pack card%s stay hidden." % [
		hint_text,
		hidden_non_combat_count,
		"" if hidden_non_combat_count == 1 else "s",
	]


func _decorate_card_models(
	original_models: Variant,
	clickable_resolver: Callable,
	selected_resolver: Callable,
	draggable_resolver: Callable,
	density_preset: String,
	has_compact_mode_override: bool = false,
	compact_mode_override: bool = false
) -> Array[Dictionary]:
	var source_models: Array = original_models if original_models is Array else []
	var decorated_models: Array[Dictionary] = []
	for source_model in source_models:
		if not (source_model is Dictionary):
			continue
		var card_model: Dictionary = (source_model as Dictionary).duplicate(true)
		var is_clickable: bool = clickable_resolver.call(card_model) if clickable_resolver.is_valid() else false
		var is_selected: bool = selected_resolver.call(card_model) if selected_resolver.is_valid() else false
		var is_draggable: bool = draggable_resolver.call(card_model) if draggable_resolver.is_valid() else false
		card_model["is_clickable"] = is_clickable
		card_model["is_selected"] = is_selected
		card_model["is_draggable"] = is_draggable
		var decorated_model: Dictionary = _inventory_presenter.decorate_card_interaction_state(
			card_model,
			_mode == "combat",
			is_clickable,
			is_selected,
			is_draggable
		)
		decorated_model["density_preset"] = density_preset
		if has_compact_mode_override:
			decorated_model["compact_mode"] = compact_mode_override
		decorated_models.append(decorated_model)
	return decorated_models


func _inventory_card_models_signature(card_models: Array[Dictionary]) -> String:
	var parts := PackedStringArray()
	for card_model in card_models:
		parts.append(_inventory_card_model_signature(card_model))
	return "\n".join(parts)


func _inventory_card_model_signature(card_model: Dictionary) -> String:
	var fields := PackedStringArray([
		str(card_model.get("card_name", "")),
		str(card_model.get("card_family", "")),
		str(int(card_model.get("slot_index", -1))),
		str(int(card_model.get("inventory_slot_index", -1))),
		str(int(card_model.get("inventory_slot_id", -1))),
		str(card_model.get("slot_label", "")),
		str(card_model.get("title_text", "")),
		str(card_model.get("detail_text", "")),
		str(card_model.get("count_text", "")),
		str(card_model.get("icon_texture_path", "")),
		str(card_model.get("tooltip_text", "")),
		str(card_model.get("action_hint_text", "")),
		str(card_model.get("action_hint_tone", "")),
		_color_signature(Color(card_model.get("accent_color", Color.WHITE))),
		str(bool(card_model.get("is_clickable", false))),
		str(bool(card_model.get("is_selected", false))),
		str(bool(card_model.get("is_equipped", false))),
		str(bool(card_model.get("is_draggable", false))),
		str(card_model.get("density_preset", "")),
		str(bool(card_model.get("compact_mode", false))),
	])
	return "|".join(fields)


func _color_signature(color: Color) -> String:
	return "%.4f,%.4f,%.4f,%.4f" % [color.r, color.g, color.b, color.a]


func _on_drag_started() -> void:
	if _inventory_tooltip_controller != null:
		_inventory_tooltip_controller.hide(true)
	if _external_drag_started_handler.is_valid():
		_external_drag_started_handler.call()
