# Layer: UI
extends RefCounted
class_name MapExploreSceneUi

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const MapBoardCanvasScript = preload("res://Game/UI/map_board_canvas.gd")
const SAFE_MENU_ANCHOR_PATH := "Margin/VBox/TopRow/SettingsMenuAnchor"


static func ensure_runtime_board_nodes(route_grid: Control, route_marker_node_names: PackedStringArray, current_marker: TextureRect, road_base_lines: Array[Line2D], road_highlight_lines: Array[Line2D], walker_root: Control, walker_shadow: PanelContainer, walker_sprite: TextureRect, walker_root_size: Vector2, walker_shadow_size: Vector2, walker_sprite_size: Vector2, board_canvas: Control) -> Dictionary:
	if route_grid == null:
		return {
			"current_marker": current_marker,
			"road_base_lines": road_base_lines,
			"road_highlight_lines": road_highlight_lines,
			"walker_root": walker_root,
			"walker_shadow": walker_shadow,
			"walker_sprite": walker_sprite,
			"board_canvas": board_canvas,
		}

	if board_canvas == null:
		board_canvas = route_grid.get_node_or_null("ComposedBoardCanvas") as Control
	if board_canvas == null:
		board_canvas = MapBoardCanvasScript.new()
		board_canvas.name = "ComposedBoardCanvas"
		board_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board_canvas.z_index = 4
		board_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
		route_grid.add_child(board_canvas)
		route_grid.move_child(board_canvas, 1)

	for marker_name in route_marker_node_names:
		var marker_rect: TextureRect = route_grid.get_node_or_null(marker_name) as TextureRect
		if marker_rect == null:
			continue
		marker_rect.clip_contents = false
		marker_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker_rect.z_index = 20
		_ensure_marker_overlay(marker_rect)

	if current_marker == null:
		current_marker = TextureRect.new()
		current_marker.name = "CurrentNodeMarker"
		current_marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		current_marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		current_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		current_marker.clip_contents = false
		current_marker.z_index = 30
		route_grid.add_child(current_marker)
	_ensure_marker_overlay(current_marker)
	route_grid.move_child(current_marker, route_grid.get_child_count() - 1)

	if road_base_lines.is_empty():
		for index in range(route_marker_node_names.size()):
			var base_line := Line2D.new()
			base_line.name = "RouteRoadBase%d" % index
			base_line.width = 14.0
			base_line.default_color = Color(0.57, 0.49, 0.30, 0.82)
			base_line.antialiased = true
			base_line.z_index = 2
			base_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			base_line.end_cap_mode = Line2D.LINE_CAP_ROUND
			base_line.joint_mode = Line2D.LINE_JOINT_ROUND
			route_grid.add_child(base_line)
			route_grid.move_child(base_line, 1)
			road_base_lines.append(base_line)

			var highlight_line := Line2D.new()
			highlight_line.name = "RouteRoadHighlight%d" % index
			highlight_line.width = 6.0
			highlight_line.default_color = Color(0.96, 0.90, 0.70, 0.78)
			highlight_line.antialiased = true
			highlight_line.z_index = 3
			highlight_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			highlight_line.end_cap_mode = Line2D.LINE_CAP_ROUND
			highlight_line.joint_mode = Line2D.LINE_JOINT_ROUND
			route_grid.add_child(highlight_line)
			route_grid.move_child(highlight_line, 2)
			road_highlight_lines.append(highlight_line)

	if walker_root == null:
		walker_root = Control.new()
		walker_root.name = "WalkerActor"
		walker_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		walker_root.size = walker_root_size
		walker_root.z_index = 40
		route_grid.add_child(walker_root)

		walker_shadow = PanelContainer.new()
		walker_shadow.name = "WalkerShadow"
		walker_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		walker_shadow.size = walker_shadow_size
		walker_shadow.position = Vector2((walker_root_size.x - walker_shadow_size.x) * 0.5, walker_root_size.y - walker_shadow_size.y - 4.0)
		walker_root.add_child(walker_shadow)
		_apply_walker_shadow_style(walker_shadow)

		walker_sprite = TextureRect.new()
		walker_sprite.name = "WalkerSprite"
		walker_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		walker_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		walker_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		walker_sprite.size = walker_sprite_size
		walker_sprite.position = Vector2((walker_root_size.x - walker_sprite_size.x) * 0.5, 4.0)
		walker_sprite.pivot_offset = walker_sprite_size * 0.5
		walker_root.add_child(walker_sprite)

	route_grid.move_child(walker_root, route_grid.get_child_count() - 1)
	walker_root.visible = false

	return {
		"current_marker": current_marker,
		"road_base_lines": road_base_lines,
		"road_highlight_lines": road_highlight_lines,
		"walker_root": walker_root,
		"walker_shadow": walker_shadow,
		"walker_sprite": walker_sprite,
		"board_canvas": board_canvas,
	}


static func ensure_key_marker_visual(card_rect: TextureRect) -> void:
	if card_rect == null:
		return

	var icon_rect: TextureRect = card_rect.get_node_or_null("KeyMarkerIcon") as TextureRect
	if icon_rect == null:
		icon_rect = TextureRect.new()
		icon_rect.name = "KeyMarkerIcon"
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_rect.add_child(icon_rect)


static func apply_temp_theme(root: Control) -> void:
	if root == null:
		return

	TempScreenThemeScript.apply_wayfinder_backdrop(root, 0.30, 0.14, 0.03, true)

	_apply_compact_map_panel(root.get_node_or_null("Margin/VBox/TopRow/HeaderCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 14, 0.84, 8, 6)
	TempScreenThemeScript.apply_label(root.get_node_or_null("Margin/VBox/TopRow/HeaderCard/HeaderStack/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(root.get_node_or_null("Margin/VBox/TopRow/HeaderCard/HeaderStack/ProgressLabel") as Label, "accent")
	_apply_compact_map_panel(root.get_node_or_null("Margin/VBox/TopRow/RunSummaryCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 14, 0.82, 8, 6)
	_apply_compact_map_panel(root.get_node_or_null("Margin/VBox/InventorySection/InventoryCard") as PanelContainer, TempScreenThemeScript.REWARD_ACCENT_COLOR, 14, 0.80, 10, 8)
	_apply_compact_map_panel(root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 14, 0.82, 10, 7)
	_apply_compact_map_panel(root.get_node_or_null("Margin/VBox/BottomRow/StatusCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 14, 0.74, 10, 7)
	for label_path in [
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HpRow/HpStatusLabel",
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HungerRow/HungerStatusLabel",
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/DurabilityRow/DurabilityStatusLabel",
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/GoldRow/GoldStatusLabel",
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/GoldRow/GoldStatusValueLabel",
	]:
		TempScreenThemeScript.apply_label(root.get_node_or_null(label_path) as Label)
	TempScreenThemeScript.apply_label(root.get_node_or_null("Margin/VBox/InventorySection/InventoryTitleLabel") as Label, "reward")
	TempScreenThemeScript.apply_label(root.get_node_or_null("Margin/VBox/InventorySection/InventoryHintLabel") as Label, "muted")
	TempScreenThemeScript.apply_label(root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorLabel") as Label, "accent")
	TempScreenThemeScript.apply_label(root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorDetailLabel") as Label)
	TempScreenThemeScript.apply_label(root.get_node_or_null("Margin/VBox/BottomRow/StatusCard/StatusLabel") as Label, "muted")

	var title_label: Label = root.get_node_or_null("Margin/VBox/TopRow/HeaderCard/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 28)
		title_label.clip_text = true
		title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title_label.max_lines_visible = 1

	var progress_label: Label = root.get_node_or_null("Margin/VBox/TopRow/HeaderCard/HeaderStack/ProgressLabel") as Label
	if progress_label != null:
		progress_label.add_theme_font_size_override("font_size", 16)
		progress_label.clip_text = true
		progress_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		progress_label.max_lines_visible = 1

	var header_stack: VBoxContainer = root.get_node_or_null("Margin/VBox/TopRow/HeaderCard/HeaderStack") as VBoxContainer
	if header_stack != null:
		header_stack.add_theme_constant_override("separation", 1)
	var stats_stack: VBoxContainer = root.get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsStack") as VBoxContainer
	if stats_stack != null:
		stats_stack.add_theme_constant_override("separation", 2)
	var status_rows: VBoxContainer = root.get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows") as VBoxContainer
	if status_rows != null:
		status_rows.add_theme_constant_override("separation", 1)
	var status_row_nodes: Array[Container] = [
		root.get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HpRow") as Container,
		root.get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HungerRow") as Container,
		root.get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/DurabilityRow") as Container,
		root.get_node_or_null("Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/GoldRow") as Container,
	]
	for status_row in status_row_nodes:
		if status_row != null:
			status_row.add_theme_constant_override("separation", 4)

	for status_label_path in [
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HpRow/HpStatusLabel",
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HungerRow/HungerStatusLabel",
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/DurabilityRow/DurabilityStatusLabel",
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/GoldRow/GoldStatusLabel",
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/GoldRow/GoldStatusValueLabel",
	]:
		var status_label: Label = root.get_node_or_null(status_label_path) as Label
		if status_label != null:
			status_label.add_theme_font_size_override("font_size", 16)
			if status_label.name == "GoldStatusValueLabel":
				status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			else:
				status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	for icon_path in [
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HpRow/HpStatusIcon",
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/HungerRow/HungerStatusIcon",
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/DurabilityRow/DurabilityStatusIcon",
		"Margin/VBox/TopRow/RunSummaryCard/StatsStack/StatusRows/GoldRow/GoldStatusIcon",
	]:
		var icon_rect: TextureRect = root.get_node_or_null(icon_path) as TextureRect
		if icon_rect != null:
			icon_rect.custom_minimum_size = Vector2(16, 16)
			icon_rect.modulate = Color(0.96, 0.93, 0.82, 0.95)

	var current_anchor_label: Label = root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorLabel") as Label
	if current_anchor_label != null:
		current_anchor_label.add_theme_font_size_override("font_size", 21)

	var current_anchor_detail_label: Label = root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorDetailLabel") as Label
	if current_anchor_detail_label != null:
		current_anchor_detail_label.add_theme_font_size_override("font_size", 17)

	var inventory_title_label: Label = root.get_node_or_null("Margin/VBox/InventorySection/InventoryTitleLabel") as Label
	if inventory_title_label != null:
		inventory_title_label.add_theme_font_size_override("font_size", 22)
	var inventory_hint_label: Label = root.get_node_or_null("Margin/VBox/InventorySection/InventoryHintLabel") as Label
	if inventory_hint_label != null:
		inventory_hint_label.add_theme_font_size_override("font_size", 15 if root.get_viewport_rect().size.y >= 1560.0 else 14)


static func style_route_buttons_for_overlay_mode(route_grid: Control, route_button_node_names: PackedStringArray) -> void:
	if route_grid == null:
		return

	for button_node_name in route_button_node_names:
		var route_button: Button = route_grid.get_node_or_null(button_node_name) as Button
		if route_button == null:
			continue
		route_button.flat = true
		route_button.z_index = 12
		route_button.mouse_filter = Control.MOUSE_FILTER_STOP
		route_button.focus_mode = Control.FOCUS_ALL
		route_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		route_button.add_theme_stylebox_override("normal", _build_route_button_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
		route_button.add_theme_stylebox_override("hover", _build_route_button_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
		route_button.add_theme_stylebox_override("pressed", _build_route_button_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
		route_button.add_theme_stylebox_override("focus", _build_route_button_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
		route_button.add_theme_stylebox_override("disabled", _build_route_button_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
		route_button.add_theme_color_override("font_color", Color(1, 1, 1, 0.0))
		route_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0.0))
		route_button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.0))
		route_button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.0))


static func apply_text_density_pass(root: Control) -> void:
	if root == null:
		return

	var status_label: Label = root.get_node_or_null("Margin/VBox/BottomRow/StatusCard/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 17)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status_label.max_lines_visible = 3


static func apply_portrait_safe_layout(root: Control, max_width: int, min_side_margin: int) -> void:
	if root == null:
		return

	var margin: MarginContainer = root.get_node_or_null("Margin") as MarginContainer
	var vbox: VBoxContainer = root.get_node_or_null("Margin/VBox") as VBoxContainer
	var route_grid: Control = root.get_node_or_null("Margin/VBox/RouteGrid") as Control
	var header_card: PanelContainer = root.get_node_or_null("Margin/VBox/TopRow/HeaderCard") as PanelContainer
	var inventory_section: VBoxContainer = root.get_node_or_null("Margin/VBox/InventorySection") as VBoxContainer
	var inventory_card: PanelContainer = root.get_node_or_null("Margin/VBox/InventorySection/InventoryCard") as PanelContainer
	var inventory_cards_flow: HBoxContainer = root.get_node_or_null("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow") as HBoxContainer
	var inventory_title_label: Label = root.get_node_or_null("Margin/VBox/InventorySection/InventoryTitleLabel") as Label
	var inventory_hint_label: Label = root.get_node_or_null("Margin/VBox/InventorySection/InventoryHintLabel") as Label
	var top_row: HBoxContainer = root.get_node_or_null("Margin/VBox/TopRow") as HBoxContainer
	var bottom_row: VBoxContainer = root.get_node_or_null("Margin/VBox/BottomRow") as VBoxContainer
	var current_anchor_card: PanelContainer = root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard") as PanelContainer
	var status_card: PanelContainer = root.get_node_or_null("Margin/VBox/BottomRow/StatusCard") as PanelContainer
	var safe_menu_anchor: Control = root.get_node_or_null(SAFE_MENU_ANCHOR_PATH) as Control
	var run_summary_card: PanelContainer = root.get_node_or_null("Margin/VBox/TopRow/RunSummaryCard") as PanelContainer
	if margin == null or route_grid == null:
		return

	var viewport_size: Vector2 = root.get_viewport_rect().size
	var top_margin: int = 4
	var bottom_margin: int = 8
	var compact_layout: bool = viewport_size.y < 1540.0
	var very_compact_layout: bool = viewport_size.y < 1360.0
	if viewport_size.y >= 1560.0:
		top_margin = 8
		bottom_margin = 10
	elif viewport_size.y >= 1400.0:
		top_margin = 7
		bottom_margin = 9

	TempScreenThemeScript.apply_portrait_safe_margins(
		margin,
		max_width,
		min_side_margin,
		top_margin,
		bottom_margin
	)

	if vbox != null:
		vbox.add_theme_constant_override("separation", 0)

	# Top HUD
	if top_row != null:
		top_row.alignment = 0
		top_row.add_theme_constant_override("separation", 0)
		top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		if header_card != null:
			header_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			header_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			header_card.size_flags_stretch_ratio = 1.0
			header_card.custom_minimum_size = Vector2(0.0, 0.0)
		if run_summary_card != null:
			run_summary_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			run_summary_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			run_summary_card.size_flags_stretch_ratio = 1.0
			run_summary_card.custom_minimum_size = Vector2(0.0, 0.0)
		if safe_menu_anchor != null:
			safe_menu_anchor.size_flags_horizontal = Control.SIZE_SHRINK_END
			safe_menu_anchor.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			safe_menu_anchor.size_flags_stretch_ratio = 0.0
			safe_menu_anchor.custom_minimum_size = Vector2(74, 52)

	# Middle map (main content)
	route_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	route_grid.custom_minimum_size = Vector2(0.0, 0.0)

	# Bottom action/info block (inventory + state summary)
	if inventory_section != null:
		inventory_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inventory_section.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		inventory_section.add_theme_constant_override("separation", 2 if very_compact_layout else 3)
		inventory_section.custom_minimum_size = Vector2.ZERO
		if inventory_title_label != null:
			inventory_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF if very_compact_layout else TextServer.AUTOWRAP_OFF
		if inventory_hint_label != null:
			inventory_hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		if inventory_cards_flow != null:
			inventory_cards_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			inventory_cards_flow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			inventory_cards_flow.custom_minimum_size = Vector2.ZERO
		if inventory_card != null:
			inventory_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			inventory_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			inventory_card.custom_minimum_size = Vector2(0.0, 0.0)

	if bottom_row != null:
		bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bottom_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		bottom_row.add_theme_constant_override("separation", 3 if very_compact_layout else 4)
		bottom_row.custom_minimum_size = Vector2.ZERO
		if current_anchor_card != null:
			current_anchor_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			current_anchor_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		if status_card != null:
			status_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			status_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	_flush_container_layout(vbox)
	_flush_container_layout(top_row)
	_flush_container_layout(route_grid)
	_flush_container_layout(inventory_section)
	_flush_container_layout(bottom_row)

static func _ensure_marker_overlay(marker_rect: TextureRect) -> void:
	var selection_ring: PanelContainer = marker_rect.get_node_or_null("SelectionRing") as PanelContainer
	if selection_ring == null:
		selection_ring = PanelContainer.new()
		selection_ring.name = "SelectionRing"
		selection_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker_rect.add_child(selection_ring)
	selection_ring.z_index = 22

	var node_plate: PanelContainer = marker_rect.get_node_or_null("NodePlate") as PanelContainer
	if node_plate == null:
		node_plate = PanelContainer.new()
		node_plate.name = "NodePlate"
		node_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker_rect.add_child(node_plate)
	node_plate.z_index = 8

	var icon_rect: TextureRect = marker_rect.get_node_or_null("RouteIcon") as TextureRect
	if icon_rect == null:
		icon_rect = TextureRect.new()
		icon_rect.name = "RouteIcon"
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		marker_rect.add_child(icon_rect)
	icon_rect.z_index = 16

	var chip_panel: PanelContainer = marker_rect.get_node_or_null("StateChip") as PanelContainer
	if chip_panel == null:
		chip_panel = PanelContainer.new()
		chip_panel.name = "StateChip"
		chip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker_rect.add_child(chip_panel)
	chip_panel.z_index = 24

	var chip_label: Label = null
	if chip_panel != null:
		chip_label = chip_panel.get_node_or_null("StateChipLabel") as Label
	if chip_label == null and chip_panel != null:
		chip_label = Label.new()
		chip_label.name = "StateChipLabel"
		chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip_panel.add_child(chip_label)

	var fallback_label: Label = marker_rect.get_node_or_null("FallbackLabel") as Label
	if fallback_label == null:
		fallback_label = Label.new()
		fallback_label.name = "FallbackLabel"
		fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fallback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker_rect.add_child(fallback_label)
	fallback_label.z_index = 18

	marker_rect.move_child(node_plate, 0)
	marker_rect.move_child(selection_ring, marker_rect.get_child_count() - 1)
	marker_rect.move_child(icon_rect, marker_rect.get_child_count() - 1)
	marker_rect.move_child(chip_panel, marker_rect.get_child_count() - 1)
	marker_rect.move_child(fallback_label, marker_rect.get_child_count() - 1)


static func _flush_container_layout(control: Control) -> void:
	if control == null:
		return
	if control is Container:
		var container: Container = control as Container
		container.queue_sort()


static func _apply_compact_map_panel(panel: PanelContainer, accent: Color, corner_radius: int, fill_alpha: float, margin_x: int, margin_y: int) -> void:
	if panel == null:
		return

	TempScreenThemeScript.apply_panel(panel, accent, corner_radius, fill_alpha)
	var existing_style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if existing_style == null:
		return

	var compact_style: StyleBoxFlat = existing_style.duplicate() as StyleBoxFlat
	compact_style.border_width_left = 2
	compact_style.border_width_top = 2
	compact_style.border_width_right = 2
	compact_style.border_width_bottom = 2
	compact_style.border_color = accent.lightened(0.16)
	compact_style.bg_color = compact_style.bg_color.lightened(0.04)
	compact_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.24)
	compact_style.shadow_size = 14
	compact_style.content_margin_left = margin_x + 1
	compact_style.content_margin_top = margin_y
	compact_style.content_margin_right = margin_x + 1
	compact_style.content_margin_bottom = margin_y
	panel.add_theme_stylebox_override("panel", compact_style)


static func _build_route_button_box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 34
	style.corner_radius_top_right = 34
	style.corner_radius_bottom_right = 34
	style.corner_radius_bottom_left = 34
	style.shadow_color = Color(0, 0, 0, 0.14)
	style.shadow_size = 6
	return style


static func _apply_walker_shadow_style(walker_shadow: PanelContainer) -> void:
	if walker_shadow == null:
		return

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.22)
	style.corner_radius_top_left = 100
	style.corner_radius_top_right = 100
	style.corner_radius_bottom_right = 100
	style.corner_radius_bottom_left = 100
	walker_shadow.add_theme_stylebox_override("panel", style)
