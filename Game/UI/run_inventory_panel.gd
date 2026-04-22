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

	_apply_text_model(model)
	equipment_container.visible = bool(model.get("show_equipment", true))
	backpack_container.visible = bool(model.get("show_backpack", true))

	var clickable_resolver: Callable = model.get("clickable_resolver", Callable())
	var selected_resolver: Callable = model.get("selected_resolver", Callable())
	var draggable_resolver: Callable = model.get("draggable_resolver", Callable())
	var has_compact_mode_override: bool = model.has("card_compact_mode_override")
	var compact_mode_override: bool = bool(model.get("card_compact_mode_override", false))
	var density_preset: String = String(model.get(
		"layout_density",
		DENSITY_COMBAT_COMPACT if _mode == "combat" else DENSITY_MAP
	))

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

	var equipment_signature: String = _inventory_card_models_signature(equipment_card_models)
	var backpack_signature: String = _inventory_card_models_signature(backpack_card_models)
	if _inventory_card_handler != null:
		if equipment_signature != _equipment_cards_signature:
			_inventory_card_handler.rebuild_cards(equipment_container, equipment_card_models)
			_equipment_cards_signature = equipment_signature
		if backpack_signature != _backpack_cards_signature:
			_inventory_card_handler.rebuild_cards(backpack_container, backpack_card_models)
			_backpack_cards_signature = backpack_signature

	var viewport_height: float = _owner.get_viewport_rect().size.y if _owner != null else 0.0
	var density_band: String = InventoryPanelLayoutScript.card_density_band_for_viewport_height(viewport_height)
	InventoryPanelLayoutScript.apply_card_density_overrides(equipment_container, density_band)
	InventoryPanelLayoutScript.apply_card_density_overrides(backpack_container, density_band)


func _apply_text_model(model: Dictionary) -> void:
	var equipment_title_label: Label = _config.get("equipment_title_label", null)
	if equipment_title_label != null:
		equipment_title_label.text = String(model.get("equipment_title", ""))
		equipment_title_label.visible = bool(model.get("show_equipment", true))

	var equipment_hint_label: Label = _config.get("equipment_hint_label", null)
	if equipment_hint_label != null:
		equipment_hint_label.text = String(model.get("equipment_hint", ""))
		equipment_hint_label.visible = bool(model.get("equipment_hint_visible", not equipment_hint_label.text.is_empty()))

	var inventory_title_label: Label = _config.get("inventory_title_label", null)
	if inventory_title_label != null:
		inventory_title_label.text = String(model.get("inventory_title", ""))
		inventory_title_label.visible = bool(model.get("show_backpack", true))

	var inventory_hint_label: Label = _config.get("inventory_hint_label", null)
	if inventory_hint_label != null:
		inventory_hint_label.text = String(model.get("inventory_hint", ""))
		inventory_hint_label.visible = bool(model.get("inventory_hint_visible", not inventory_hint_label.text.is_empty()))


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
