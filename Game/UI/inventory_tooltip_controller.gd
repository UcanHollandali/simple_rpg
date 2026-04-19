# Layer: UI
extends RefCounted
class_name InventoryTooltipController

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")

const INVENTORY_TOOLTIP_PANEL_NAME := "InventoryTooltipPanel"
const INVENTORY_TOOLTIP_LABEL_NAME := "InventoryTooltipLabel"
const INVENTORY_TOOLTIP_MARGIN := 16.0
const INVENTORY_TOOLTIP_GAP := 12.0
const INVENTORY_TOOLTIP_MAX_WIDTH := 320.0
const INVENTORY_TOOLTIP_FONT_SIZE := 15
const INVENTORY_TOOLTIP_META_KEY := "custom_tooltip_text"
const INVENTORY_TOOLTIP_BASE_Z_INDEX := 160
const INVENTORY_TOOLTIP_Z_OFFSET := 20

var _owner: Control
var _inventory_tooltip_panel: PanelContainer
var _inventory_tooltip_label: Label
var _hovered_inventory_card: Control
var _hovered_inventory_accent: Color = TempScreenThemeScript.PANEL_BORDER_COLOR


func configure(owner: Control) -> void:
	_owner = owner
	_ensure_inventory_tooltip_shell()


func release() -> void:
	hide(true)
	_owner = null
	_inventory_tooltip_panel = null
	_inventory_tooltip_label = null


func on_inventory_card_mouse_entered(card: Control, accent: Color) -> void:
	if card == null:
		return
	_hovered_inventory_card = card
	_hovered_inventory_accent = accent
	_show_inventory_tooltip(card, accent, _get_inventory_tooltip_text(card))


func on_inventory_card_mouse_exited(card: Control) -> void:
	if card != _hovered_inventory_card:
		return
	hide(true)


func refresh_hovered_tooltip() -> void:
	if _hovered_inventory_card == null or not is_instance_valid(_hovered_inventory_card):
		return
	if not _hovered_inventory_card.visible:
		hide(true)
		return
	_show_inventory_tooltip(_hovered_inventory_card, _hovered_inventory_accent, _get_inventory_tooltip_text(_hovered_inventory_card))


func hide(clear_hovered_card: bool = false) -> void:
	if _inventory_tooltip_panel != null:
		_inventory_tooltip_panel.visible = false
	if clear_hovered_card:
		_hovered_inventory_card = null


func _ensure_inventory_tooltip_shell() -> void:
	if _owner == null:
		return
	if _inventory_tooltip_panel != null and is_instance_valid(_inventory_tooltip_panel):
		return
	_inventory_tooltip_panel = PanelContainer.new()
	_inventory_tooltip_panel.name = INVENTORY_TOOLTIP_PANEL_NAME
	_inventory_tooltip_panel.visible = false
	_inventory_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_inventory_tooltip_layering()
	_owner.add_child(_inventory_tooltip_panel)

	_inventory_tooltip_label = Label.new()
	_inventory_tooltip_label.name = INVENTORY_TOOLTIP_LABEL_NAME
	_inventory_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inventory_tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_inventory_tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_inventory_tooltip_panel.add_child(_inventory_tooltip_label)
	_apply_inventory_tooltip_style(TempScreenThemeScript.PANEL_BORDER_COLOR)


func _apply_inventory_tooltip_style(accent: Color) -> void:
	if _inventory_tooltip_panel == null or _inventory_tooltip_label == null:
		return
	TempScreenThemeScript.apply_panel(_inventory_tooltip_panel, accent, 16, 0.96)
	TempScreenThemeScript.apply_label(_inventory_tooltip_label)
	_inventory_tooltip_label.add_theme_font_size_override("font_size", INVENTORY_TOOLTIP_FONT_SIZE)
	_inventory_tooltip_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)


func _show_inventory_tooltip(card: Control, accent: Color, tooltip_text: String) -> void:
	_ensure_inventory_tooltip_shell()
	if _inventory_tooltip_panel == null or _inventory_tooltip_label == null or _owner == null:
		return
	var trimmed_text: String = tooltip_text.strip_edges()
	if card == null or trimmed_text.is_empty():
		hide()
		return
	_apply_inventory_tooltip_style(accent)
	_apply_inventory_tooltip_layering()
	_inventory_tooltip_label.text = trimmed_text
	var viewport_width: float = _owner.get_viewport_rect().size.x
	var tooltip_width: float = clamp(viewport_width - (INVENTORY_TOOLTIP_MARGIN * 2.0), 200.0, INVENTORY_TOOLTIP_MAX_WIDTH)
	_inventory_tooltip_panel.custom_minimum_size = Vector2(tooltip_width, 0.0)
	_inventory_tooltip_panel.size = _measure_inventory_tooltip_size(tooltip_width)
	_position_inventory_tooltip(card)
	_inventory_tooltip_panel.visible = true


func _position_inventory_tooltip(card: Control) -> void:
	if _inventory_tooltip_panel == null or card == null or _owner == null:
		return
	var card_rect: Rect2 = card.get_global_rect()
	var viewport_size: Vector2 = _owner.get_viewport_rect().size
	var tooltip_size: Vector2 = _inventory_tooltip_panel.size
	var x_position: float = clamp(
		card_rect.position.x + ((card_rect.size.x - tooltip_size.x) * 0.5),
		INVENTORY_TOOLTIP_MARGIN,
		max(INVENTORY_TOOLTIP_MARGIN, viewport_size.x - tooltip_size.x - INVENTORY_TOOLTIP_MARGIN)
	)
	var y_position: float = card_rect.position.y - tooltip_size.y - INVENTORY_TOOLTIP_GAP
	if y_position < INVENTORY_TOOLTIP_MARGIN:
		y_position = min(
			viewport_size.y - tooltip_size.y - INVENTORY_TOOLTIP_MARGIN,
			card_rect.position.y + card_rect.size.y + INVENTORY_TOOLTIP_GAP
		)
	_inventory_tooltip_panel.global_position = Vector2(x_position, y_position)


func _get_inventory_tooltip_text(card: Control) -> String:
	if card == null:
		return ""
	if card.has_meta(INVENTORY_TOOLTIP_META_KEY):
		return String(card.get_meta(INVENTORY_TOOLTIP_META_KEY, ""))
	return card.tooltip_text


func _measure_inventory_tooltip_size(panel_width: float) -> Vector2:
	if _inventory_tooltip_panel == null or _inventory_tooltip_label == null:
		return Vector2(panel_width, 0.0)
	var panel_style: StyleBox = _inventory_tooltip_panel.get_theme_stylebox("panel")
	var horizontal_padding: float = 0.0
	var vertical_padding: float = 0.0
	if panel_style != null:
		horizontal_padding = panel_style.get_margin(SIDE_LEFT) + panel_style.get_margin(SIDE_RIGHT)
		vertical_padding = panel_style.get_margin(SIDE_TOP) + panel_style.get_margin(SIDE_BOTTOM)
	var label_width: float = max(1.0, panel_width - horizontal_padding)
	_inventory_tooltip_label.custom_minimum_size = Vector2(label_width, 0.0)
	_inventory_tooltip_label.size = Vector2(label_width, 0.0)
	_inventory_tooltip_label.update_minimum_size()
	_inventory_tooltip_label.reset_size()
	var label_size: Vector2 = _inventory_tooltip_label.get_combined_minimum_size()
	return Vector2(panel_width, max(label_size.y + vertical_padding, vertical_padding))


func _apply_inventory_tooltip_layering() -> void:
	if _inventory_tooltip_panel == null:
		return
	_inventory_tooltip_panel.top_level = true
	_inventory_tooltip_panel.z_as_relative = false
	_inventory_tooltip_panel.z_index = _resolve_inventory_tooltip_z_index()


func _resolve_inventory_tooltip_z_index() -> int:
	var owner_z_index: int = 0
	if _owner != null:
		owner_z_index = _owner.z_index
	return max(INVENTORY_TOOLTIP_BASE_Z_INDEX, owner_z_index + INVENTORY_TOOLTIP_Z_OFFSET)
