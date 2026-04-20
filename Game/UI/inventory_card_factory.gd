# Layer: UI
extends RefCounted
class_name InventoryCardFactory

const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const CUSTOM_TOOLTIP_META_KEY := "custom_tooltip_text"
const ACCENT_COLOR_META_KEY := "accent_color"
const EQUIPPED_HIGHLIGHT_COLOR := Color(0.40, 0.82, 0.56, 0.98)
const SELECTED_HIGHLIGHT_COLOR := Color(0.55, 0.90, 0.66, 0.98)
const STABLE_CARD_BORDER_WIDTH := 3
const STABLE_CARD_SHADOW_SIZE := 16


static func rebuild_cards(container: Container, card_models: Array[Dictionary]) -> Array[PanelContainer]:
	var cards: Array[PanelContainer] = []
	if container == null:
		return cards

	while container.get_child_count() > 0:
		var child: Node = container.get_child(0)
		container.remove_child(child)
		child.free()

	for card_model in card_models:
		var card: PanelContainer = _build_card(card_model)
		container.add_child(card)
		cards.append(card)

	return cards


static func _build_card(card_model: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var is_clickable: bool = bool(card_model.get("is_clickable", false))
	var is_selected: bool = bool(card_model.get("is_selected", false))
	var is_equipped: bool = bool(card_model.get("is_equipped", false))
	var is_draggable: bool = bool(card_model.get("is_draggable", false))
	var compact_mode: bool = bool(card_model.get("compact_mode", false))
	var density_preset: String = String(card_model.get("density_preset", "map"))
	var combat_compact_density: bool = density_preset == "combat_compact"
	var action_hint_tone: String = String(card_model.get("action_hint_tone", "muted"))
	var accent: Color = Color(card_model.get("accent_color", TempScreenThemeScript.PANEL_BORDER_COLOR))
	card.name = String(card_model.get("card_name", "InventoryCard"))
	card.custom_minimum_size = Vector2(104, 96) if compact_mode else Vector2(118, 126) if combat_compact_density else Vector2(152, 148)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.clip_contents = compact_mode or combat_compact_density
	if is_clickable:
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	elif is_draggable:
		card.mouse_default_cursor_shape = Control.CURSOR_MOVE
	else:
		card.mouse_default_cursor_shape = Control.CURSOR_ARROW
	card.tooltip_text = ""
	card.set_meta(CUSTOM_TOOLTIP_META_KEY, String(card_model.get("tooltip_text", "")))
	card.set_meta(ACCENT_COLOR_META_KEY, accent)
	card.set_meta("card_family", String(card_model.get("card_family", "")))
	card.set_meta("slot_index", int(card_model.get("slot_index", -1)))
	card.set_meta("inventory_slot_index", int(card_model.get("inventory_slot_index", -1)))
	card.set_meta("inventory_slot_id", int(card_model.get("inventory_slot_id", -1)))
	card.set_meta("is_clickable", is_clickable)
	card.set_meta("is_selected", is_selected)
	card.set_meta("is_equipped", is_equipped)
	card.set_meta("is_draggable", is_draggable)
	card.set_meta("action_hint_tone", action_hint_tone)
	card.set_meta("is_hovered", false)
	card.set_meta("is_dragging", false)
	_apply_card_style(card, accent, is_selected, false, is_equipped, false)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 1 if compact_mode else 3 if combat_compact_density else 4)
	card.add_child(vbox)

	var accent_bar := ColorRect.new()
	accent_bar.name = "AccentBar"
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent_bar.custom_minimum_size = Vector2(0, 4)
	accent_bar.color = Color(accent.r, accent.g, accent.b, 0.84)
	vbox.add_child(accent_bar)

	var inner_glow := PanelContainer.new()
	inner_glow.name = "InnerGlowFrame"
	inner_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_glow.offset_left = 6.0
	inner_glow.offset_top = 6.0
	inner_glow.offset_right = -6.0
	inner_glow.offset_bottom = -6.0
	_apply_inner_glow_style(inner_glow, accent, false)
	card.add_child(inner_glow)
	card.move_child(inner_glow, 0)

	var header_row := HBoxContainer.new()
	header_row.name = "HeaderRow"
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 6 if combat_compact_density else 8)
	vbox.add_child(header_row)

	var slot_label := Label.new()
	slot_label.name = "SlotLabel"
	slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_label.text = String(card_model.get("slot_label", ""))
	slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	TempScreenThemeScript.apply_label(slot_label, "muted")
	slot_label.add_theme_font_size_override("font_size", 10 if compact_mode else 12 if combat_compact_density else 13)
	header_row.add_child(slot_label)

	var count_label := Label.new()
	count_label.name = "CountLabel"
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_label.custom_minimum_size = Vector2(28, 0) if compact_mode else Vector2(34, 0) if combat_compact_density else Vector2(40, 0)
	count_label.text = String(card_model.get("count_text", ""))
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	TempScreenThemeScript.apply_label(count_label, "accent")
	count_label.add_theme_font_size_override("font_size", 10 if compact_mode else 13 if combat_compact_density else 14)
	header_row.add_child(count_label)

	var icon_rect := TextureRect.new()
	icon_rect.name = "IconRect"
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.custom_minimum_size = Vector2(42, 42)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture = SceneLayoutHelperScript.load_texture_or_null(String(card_model.get("icon_texture_path", "")))
	icon_rect.modulate = Color(0.96, 0.93, 0.82, 0.98)
	icon_rect.visible = icon_rect.texture != null
	vbox.add_child(icon_rect)

	var placeholder_label := Label.new()
	placeholder_label.name = "PlaceholderLabel"
	placeholder_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placeholder_label.text = "+"
	placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	TempScreenThemeScript.apply_label(placeholder_label, "muted")
	placeholder_label.add_theme_font_size_override("font_size", 16 if compact_mode else 22 if combat_compact_density else 24)
	placeholder_label.visible = icon_rect.texture == null
	vbox.add_child(placeholder_label)

	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = String(card_model.get("title_text", ""))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF if combat_compact_density else TextServer.AUTOWRAP_WORD_SMART
	title_label.clip_text = compact_mode or combat_compact_density
	title_label.max_lines_visible = 1 if (compact_mode or combat_compact_density) else -1
	TempScreenThemeScript.apply_label(title_label)
	title_label.add_theme_font_size_override("font_size", 13 if compact_mode else 15 if combat_compact_density else 17)
	vbox.add_child(title_label)

	var detail_label := Label.new()
	detail_label.name = "DetailLabel"
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_label.text = String(card_model.get("detail_text", ""))
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_OFF if (compact_mode or combat_compact_density) else TextServer.AUTOWRAP_WORD_SMART
	detail_label.clip_text = compact_mode or combat_compact_density
	detail_label.max_lines_visible = 1 if (compact_mode or combat_compact_density) else -1
	TempScreenThemeScript.apply_label(detail_label, "muted")
	detail_label.add_theme_font_size_override("font_size", 10 if compact_mode else 11 if combat_compact_density else 14)
	detail_label.visible = not detail_label.text.is_empty()
	vbox.add_child(detail_label)

	var action_hint_label := Label.new()
	action_hint_label.name = "ActionHintLabel"
	action_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_hint_label.text = String(card_model.get("action_hint_text", ""))
	action_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF if (compact_mode or combat_compact_density) else TextServer.AUTOWRAP_WORD_SMART
	action_hint_label.clip_text = compact_mode or combat_compact_density
	action_hint_label.max_lines_visible = 1 if (compact_mode or combat_compact_density) else -1
	_apply_action_hint_style(action_hint_label, accent, action_hint_tone, false)
	action_hint_label.add_theme_font_size_override("font_size", 10 if compact_mode else 11 if combat_compact_density else 12)
	action_hint_label.visible = not action_hint_label.text.is_empty()
	vbox.add_child(action_hint_label)

	card.mouse_entered.connect(func() -> void:
		_set_card_hover_state(card, true)
	)
	card.mouse_exited.connect(func() -> void:
		_set_card_hover_state(card, false)
	)
	card.focus_entered.connect(func() -> void:
		_set_card_hover_state(card, true)
	)
	card.focus_exited.connect(func() -> void:
		_set_card_hover_state(card, false)
	)

	return card


static func _apply_card_style(
	card: PanelContainer,
	accent: Color,
	is_selected: bool = false,
	is_hovered: bool = false,
	is_equipped: bool = false,
	is_dragging: bool = false
) -> void:
	TempScreenThemeScript.apply_panel(card, accent, 14, 0.82)
	var style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return

	var compact_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	compact_style.border_width_left = STABLE_CARD_BORDER_WIDTH
	compact_style.border_width_top = STABLE_CARD_BORDER_WIDTH
	compact_style.border_width_right = STABLE_CARD_BORDER_WIDTH
	compact_style.border_width_bottom = STABLE_CARD_BORDER_WIDTH
	compact_style.border_color = accent.lightened(0.08)
	compact_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.22)
	compact_style.shadow_size = STABLE_CARD_SHADOW_SIZE
	compact_style.bg_color = compact_style.bg_color.lightened(0.02)
	if is_equipped:
		var equipped_color: Color = EQUIPPED_HIGHLIGHT_COLOR
		compact_style.border_color = equipped_color
		compact_style.bg_color = compact_style.bg_color.lerp(equipped_color.darkened(0.78), 0.14)
		compact_style.shadow_color = Color(equipped_color.r, equipped_color.g, equipped_color.b, 0.34)
		compact_style.shadow_size = STABLE_CARD_SHADOW_SIZE
	if is_hovered:
		compact_style.border_color = accent.lightened(0.18)
		compact_style.bg_color = compact_style.bg_color.lightened(0.05)
		compact_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.32)
		compact_style.shadow_size = STABLE_CARD_SHADOW_SIZE
	if is_selected:
		var selected_color: Color = SELECTED_HIGHLIGHT_COLOR
		compact_style.border_color = selected_color
		compact_style.bg_color = compact_style.bg_color.lerp(selected_color.darkened(0.80), 0.12)
		compact_style.shadow_color = Color(selected_color.r, selected_color.g, selected_color.b, 0.32)
		compact_style.shadow_size = STABLE_CARD_SHADOW_SIZE
		if is_hovered:
			compact_style.border_color = selected_color.lightened(0.08)
			compact_style.shadow_color = Color(selected_color.r, selected_color.g, selected_color.b, 0.40)
			compact_style.shadow_size = STABLE_CARD_SHADOW_SIZE
	if is_dragging:
		compact_style.bg_color = compact_style.bg_color.lightened(0.10)
		compact_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.44)
		compact_style.shadow_size = STABLE_CARD_SHADOW_SIZE + 2
	compact_style.content_margin_left = 10
	compact_style.content_margin_top = 9
	compact_style.content_margin_right = 10
	compact_style.content_margin_bottom = 9
	card.add_theme_stylebox_override("panel", compact_style)

	var accent_bar: ColorRect = card.get_node_or_null("VBox/AccentBar") as ColorRect
	if accent_bar != null:
		var accent_color: Color = accent
		if is_selected:
			accent_color = SELECTED_HIGHLIGHT_COLOR
		elif is_equipped:
			accent_color = EQUIPPED_HIGHLIGHT_COLOR
		var accent_alpha: float = 1.0 if is_hovered else 0.96 if (is_equipped or is_selected) else 0.84
		accent_bar.color = Color(accent_color.r, accent_color.g, accent_color.b, accent_alpha)

	var icon_rect: TextureRect = card.get_node_or_null("VBox/IconRect") as TextureRect
	if icon_rect != null:
		icon_rect.modulate = Color(1, 0.98, 0.90, 1.0) if is_hovered else Color(0.96, 0.93, 0.82, 0.98)

	var placeholder_label: Label = card.get_node_or_null("VBox/PlaceholderLabel") as Label
	if placeholder_label != null:
		placeholder_label.modulate = Color(1, 0.96, 0.82, 0.92) if is_hovered else Color(0.86, 0.82, 0.70, 0.86)

	var action_hint_label: Label = card.get_node_or_null("VBox/ActionHintLabel") as Label
	if action_hint_label != null:
		_apply_action_hint_style(
			action_hint_label,
			accent,
			String(card.get_meta("action_hint_tone", "muted")),
			is_hovered or is_selected,
		)

	var inner_glow: PanelContainer = card.get_node_or_null("InnerGlowFrame") as PanelContainer
	if inner_glow != null:
		_apply_inner_glow_style(inner_glow, accent, is_hovered or is_equipped or is_dragging)


static func _set_card_hover_state(card: PanelContainer, is_hovered: bool) -> void:
	if card == null or not is_instance_valid(card):
		return
	card.set_meta("is_hovered", is_hovered)
	var accent: Color = Color(card.get_meta(ACCENT_COLOR_META_KEY, TempScreenThemeScript.PANEL_BORDER_COLOR))
	var is_selected: bool = bool(card.get_meta("is_selected", false))
	var is_equipped: bool = bool(card.get_meta("is_equipped", false))
	var is_dragging: bool = bool(card.get_meta("is_dragging", false))
	_apply_card_style(card, accent, is_selected, is_hovered, is_equipped, is_dragging)


static func set_card_dragging_state(card: PanelContainer, is_dragging: bool) -> void:
	if card == null or not is_instance_valid(card):
		return
	card.set_meta("is_dragging", is_dragging)
	var accent: Color = Color(card.get_meta(ACCENT_COLOR_META_KEY, TempScreenThemeScript.PANEL_BORDER_COLOR))
	var is_selected: bool = bool(card.get_meta("is_selected", false))
	var is_hovered: bool = bool(card.get_meta("is_hovered", false))
	var is_equipped: bool = bool(card.get_meta("is_equipped", false))
	_apply_card_style(card, accent, is_selected, is_hovered, is_equipped, is_dragging)


static func _apply_inner_glow_style(panel: PanelContainer, accent: Color, is_hovered: bool) -> void:
	if panel == null:
		return

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.28 if is_hovered else 0.14)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	panel.add_theme_stylebox_override("panel", style)


static func _apply_action_hint_style(label: Label, accent: Color, tone: String, is_emphasized: bool) -> void:
	if label == null:
		return

	var current_font_size: int = label.get_theme_font_size("font_size")
	TempScreenThemeScript.apply_label(label, "muted")
	if current_font_size > 0:
		label.add_theme_font_size_override("font_size", current_font_size)
	var color: Color = TempScreenThemeScript.TEXT_MUTED_COLOR
	match tone:
		"selected":
			color = TempScreenThemeScript.REWARD_ACCENT_COLOR.lightened(0.06)
		"interactive":
			color = accent.lightened(0.18) if is_emphasized else Color(accent.r, accent.g, accent.b, 0.96)
		"passive":
			color = TempScreenThemeScript.TEXT_SUBTLE_COLOR.lightened(0.04 if is_emphasized else 0.0)
		"disabled":
			color = TempScreenThemeScript.DISABLED_TEXT_COLOR.lightened(0.06 if is_emphasized else 0.0)
		_:
			color = TempScreenThemeScript.TEXT_MUTED_COLOR.lightened(0.04 if is_emphasized else 0.0)
	label.add_theme_color_override("font_color", color)
