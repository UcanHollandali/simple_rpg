# Layer: UI
extends RefCounted
class_name InventoryCardInteractionHandler

const InventoryCardFactoryScript = preload("res://Game/UI/inventory_card_factory.gd")

var _owner: Control
var _click_handler: Callable = Callable()
var _drag_complete_handler: Callable = Callable()
var _drag_started_handler: Callable = Callable()
var _mouse_entered_handler: Callable = Callable()
var _mouse_exited_handler: Callable = Callable()
var _drag_threshold: float = 14.0
var _release_on_global_mouse_up: bool = false

var _pressed_card: PanelContainer
var _pressed_slot_id: int = -1
var _pressed_slot_index: int = -1
var _pressed_family: String = ""
var _pressed_position: Vector2 = Vector2.ZERO
var _pressed_is_draggable: bool = false
var _drag_active: bool = false


func configure(owner: Control, config: Dictionary = {}) -> void:
	_owner = owner
	_click_handler = config.get("click_handler", Callable())
	_drag_complete_handler = config.get("drag_complete_handler", Callable())
	_drag_started_handler = config.get("drag_started_handler", Callable())
	_mouse_entered_handler = config.get("mouse_entered_handler", Callable())
	_mouse_exited_handler = config.get("mouse_exited_handler", Callable())
	_drag_threshold = float(config.get("drag_threshold", 14.0))
	_release_on_global_mouse_up = bool(config.get("release_on_global_mouse_up", false))


func rebuild_cards(container: Container, card_models: Array[Dictionary]) -> Array[PanelContainer]:
	var cards: Array[PanelContainer] = InventoryCardFactoryScript.rebuild_cards(container, card_models)
	for index in range(min(cards.size(), card_models.size())):
		bind_card(cards[index], card_models[index])
	return cards


func bind_card(card: PanelContainer, card_model: Dictionary = {}) -> void:
	if card == null:
		return

	var input_handler := Callable(self, "_on_card_gui_input").bind(card)
	if not card.is_connected("gui_input", input_handler):
		card.connect("gui_input", input_handler)
	if card.mouse_filter != Control.MOUSE_FILTER_STOP:
		card.mouse_filter = Control.MOUSE_FILTER_STOP

	if _mouse_entered_handler.is_valid():
		var accent: Color = Color(card_model.get("accent_color", Color.WHITE))
		var entered_handler := Callable(self, "_on_card_mouse_entered").bind(card, accent)
		if not card.is_connected("mouse_entered", entered_handler):
			card.connect("mouse_entered", entered_handler)

	if _mouse_exited_handler.is_valid():
		var exited_handler := Callable(self, "_on_card_mouse_exited").bind(card)
		if not card.is_connected("mouse_exited", exited_handler):
			card.connect("mouse_exited", exited_handler)


func handle_root_input(event: InputEvent) -> void:
	if _pressed_card == null:
		return
	if event is InputEventMouseMotion:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		if _pressed_is_draggable and not _drag_active and motion_event.position.distance_to(_pressed_position) >= _drag_threshold:
			_drag_active = true
			if _drag_started_handler.is_valid():
				_drag_started_handler.call()
			if _pressed_card != null and is_instance_valid(_pressed_card):
				InventoryCardFactoryScript.set_card_dragging_state(_pressed_card, true)
	elif _release_on_global_mouse_up and event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or mouse_event.pressed:
			return
		_release_interaction()


func stop_interaction() -> void:
	if _pressed_card != null and is_instance_valid(_pressed_card):
		InventoryCardFactoryScript.set_card_dragging_state(_pressed_card, false)
	_pressed_card = null
	_pressed_slot_id = -1
	_pressed_slot_index = -1
	_pressed_family = ""
	_pressed_position = Vector2.ZERO
	_pressed_is_draggable = false
	_drag_active = false


func _on_card_mouse_entered(card: Control, accent: Color) -> void:
	if _mouse_entered_handler.is_valid():
		_mouse_entered_handler.call(card, accent)


func _on_card_mouse_exited(card: Control) -> void:
	if _mouse_exited_handler.is_valid():
		_mouse_exited_handler.call(card)


func _on_card_gui_input(event: InputEvent, card: PanelContainer) -> void:
	if event == null or card == null:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		_capture_press(mouse_event, card)
	elif not _release_on_global_mouse_up:
		_release_interaction()


func _capture_press(mouse_event: InputEventMouseButton, card: PanelContainer) -> void:
	_pressed_card = card
	_pressed_slot_index = int(card.get_meta("slot_index", -1))
	_pressed_slot_id = int(card.get_meta("inventory_slot_id", -1))
	_pressed_family = String(card.get_meta("card_family", ""))
	_pressed_is_draggable = bool(card.get_meta("is_draggable", false))
	_pressed_position = mouse_event.position + card.get_global_rect().position
	_drag_active = false


func _release_interaction() -> void:
	if _drag_active:
		_complete_drag()
	elif _click_handler.is_valid():
		_click_handler.call(_pressed_slot_index, _pressed_slot_id, _pressed_family)
	stop_interaction()


func _complete_drag() -> void:
	if _pressed_card == null or not _drag_complete_handler.is_valid():
		return
	if _owner == null or not is_instance_valid(_owner):
		return
	var viewport: Viewport = _owner.get_viewport()
	if viewport == null:
		return
	var hovered_control: Control = viewport.gui_get_hovered_control()
	var target_card: PanelContainer = _find_inventory_card_from_control(hovered_control)
	if target_card == null:
		return
	var target_index: int = int(target_card.get_meta("inventory_slot_index", -1))
	if _pressed_slot_id <= 0 or target_index < 0:
		return
	_drag_complete_handler.call(_pressed_slot_id, target_index)


func _find_inventory_card_from_control(control: Control) -> PanelContainer:
	var cursor: Node = control
	while cursor != null:
		if cursor is PanelContainer and String((cursor as PanelContainer).name).begins_with("InventorySlot"):
			return cursor as PanelContainer
		cursor = cursor.get_parent()
	return null
