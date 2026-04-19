# Layer: UI
extends Control
class_name InventoryOverflowPrompt

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")

signal discard_requested(slot_id: int)
signal leave_requested

const PANEL_MAX_WIDTH: float = 620.0
const PANEL_MIN_WIDTH: float = 360.0

var _accent_color: Color = TempScreenThemeScript.PANEL_BORDER_COLOR
var _scrim: ColorRect
var _panel_holder: CenterContainer
var _panel: PanelContainer
var _content_vbox: VBoxContainer
var _title_label: Label
var _context_label: Label
var _options_vbox: VBoxContainer
var _leave_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0
	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 180
	visible = false
	_build_ui()
	_apply_viewport_layout()
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var resized_handler := Callable(self, "_on_viewport_size_changed")
		if not viewport.is_connected("size_changed", resized_handler):
			viewport.connect("size_changed", resized_handler)


func configure(accent_color: Color) -> void:
	_accent_color = accent_color
	_apply_theme()


func present(prompt_result: Dictionary, leave_button_text: String = "Leave Item") -> void:
	if _panel == null:
		return
	_title_label.text = "Backpack Full"
	_context_label.text = _build_context_text(prompt_result)
	_leave_button.text = leave_button_text
	_rebuild_option_buttons(prompt_result)
	_apply_theme()
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate = Color(1, 1, 1, 0)
	_panel.scale = Vector2(0.98, 0.98)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.14)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.18)
	var first_button: Button = _find_first_option_button()
	if first_button != null:
		first_button.grab_focus()
	else:
		_leave_button.grab_focus()


func dismiss() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_ui() -> void:
	_scrim = ColorRect.new()
	_scrim.name = "PromptScrim"
	_scrim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_scrim)

	_panel_holder = CenterContainer.new()
	_panel_holder.name = "PromptHolder"
	_panel_holder.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_panel_holder.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel_holder)

	_panel = PanelContainer.new()
	_panel.name = "PromptPanel"
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_panel_holder.add_child(_panel)

	_content_vbox = VBoxContainer.new()
	_content_vbox.name = "PromptVBox"
	_content_vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(_content_vbox)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_vbox.add_child(_title_label)

	_context_label = Label.new()
	_context_label.name = "ContextLabel"
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_vbox.add_child(_context_label)

	_options_vbox = VBoxContainer.new()
	_options_vbox.name = "OptionsVBox"
	_options_vbox.add_theme_constant_override("separation", 10)
	_content_vbox.add_child(_options_vbox)

	_leave_button = Button.new()
	_leave_button.name = "LeaveButton"
	_leave_button.text = "Leave Item"
	_leave_button.pressed.connect(_on_leave_pressed)
	_content_vbox.add_child(_leave_button)

	_apply_theme()


func _apply_theme() -> void:
	if _scrim != null:
		TempScreenThemeScript.apply_scrim(_scrim)
		_scrim.color = Color(_scrim.color.r, _scrim.color.g, _scrim.color.b, 0.78)
	if _panel != null:
		TempScreenThemeScript.apply_panel(_panel, _accent_color, 22, 0.96)
		TempScreenThemeScript.intensify_panel(_panel, _accent_color, 3, 28, 0.02, 0.24, 22, 18)
	if _title_label != null:
		TempScreenThemeScript.apply_label(_title_label, "title")
		_title_label.add_theme_font_size_override("font_size", 32)
	if _context_label != null:
		TempScreenThemeScript.apply_label(_context_label, "body")
		_context_label.add_theme_font_size_override("font_size", 18)
		_context_label.modulate = Color(1, 1, 1, 0.9)
	if _leave_button != null:
		TempScreenThemeScript.apply_button(_leave_button, TempScreenThemeScript.PANEL_BORDER_COLOR, true)


func _rebuild_option_buttons(prompt_result: Dictionary) -> void:
	for child in _options_vbox.get_children():
		child.queue_free()

	var discardable_slots: Array = prompt_result.get("discardable_slots", [])
	for slot_variant in discardable_slots:
		if typeof(slot_variant) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = slot_variant
		var button := Button.new()
		button.name = "DiscardSlot%dButton" % int(slot.get("slot_id", -1))
		button.text = _build_slot_button_text(slot)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 72)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_discard_pressed.bind(int(slot.get("slot_id", -1))))
		TempScreenThemeScript.apply_button(button, _accent_color)
		_options_vbox.add_child(button)


func _build_context_text(prompt_result: Dictionary) -> String:
	var custom_context_text: String = String(prompt_result.get("context_text", "")).strip_edges()
	if not custom_context_text.is_empty():
		return custom_context_text
	var display_name: String = String(prompt_result.get("display_name", prompt_result.get("definition_id", "item"))).strip_edges()
	var inventory_family: String = String(prompt_result.get("inventory_family", "")).strip_edges()
	var amount: int = max(1, int(prompt_result.get("amount", 1)))
	if inventory_family == InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE and amount > 1:
		display_name = "%s x%d" % [display_name, amount]
	return "Choose one backpack item to discard for %s, or leave it behind." % display_name


func _build_slot_button_text(slot: Dictionary) -> String:
	var slot_label: String = String(slot.get("slot_label", "Pack"))
	var display_name: String = String(slot.get("display_name", slot.get("definition_id", ""))).strip_edges()
	var family_label: String = _build_family_label(String(slot.get("inventory_family", "")))
	return "Discard %s - %s\n%s" % [slot_label, display_name, family_label]


func _build_family_label(inventory_family: String) -> String:
	match inventory_family:
		InventoryStateScript.INVENTORY_FAMILY_WEAPON:
			return "Weapon"
		InventoryStateScript.INVENTORY_FAMILY_SHIELD:
			return "Shield"
		InventoryStateScript.INVENTORY_FAMILY_ARMOR:
			return "Armor"
		InventoryStateScript.INVENTORY_FAMILY_BELT:
			return "Belt"
		InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
			return "Consumable"
		InventoryStateScript.INVENTORY_FAMILY_PASSIVE:
			return "Passive"
		InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
			return "Shield Mod"
		InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
			return "Quest Cargo"
		_:
			return "Carried Item"


func _find_first_option_button() -> Button:
	for child in _options_vbox.get_children():
		var button: Button = child as Button
		if button != null and button.visible and not button.disabled:
			return button
	return null


func _apply_viewport_layout() -> void:
	if _panel == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_width: float = clamp(viewport_size.x - 84.0, PANEL_MIN_WIDTH, PANEL_MAX_WIDTH)
	if viewport_size.x <= 420.0:
		panel_width = max(300.0, viewport_size.x - 40.0)
	_panel.custom_minimum_size = Vector2(panel_width, 0)
	_content_vbox.add_theme_constant_override("separation", 10 if viewport_size.y < 1560.0 else 12)
	_panel_holder.offset_left = 20
	_panel_holder.offset_top = 20
	_panel_holder.offset_right = -20
	_panel_holder.offset_bottom = -20


func _on_viewport_size_changed() -> void:
	_apply_viewport_layout()


func _on_discard_pressed(slot_id: int) -> void:
	discard_requested.emit(slot_id)


func _on_leave_pressed() -> void:
	leave_requested.emit()
