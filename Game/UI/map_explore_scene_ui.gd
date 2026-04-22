# Layer: UI
extends RefCounted
class_name MapExploreSceneUi

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const MapBoardCanvasScript = preload("res://Game/UI/map_board_canvas.gd")
const SafeMenuLauncherStyleScript = preload("res://Game/UI/safe_menu_launcher_style.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const InventoryPanelLayoutScript = preload("res://Game/UI/inventory_panel_layout.gd")
const TOP_ROW_PATH := "Margin/VBox/TopRow"
const HEADER_CARD_PATH := "Margin/VBox/TopRow/HeaderCard"
const HEADER_STACK_PATH := "Margin/VBox/TopRow/HeaderCard/HeaderRow/HeaderStack"
const STAGE_BADGE_PATH := "Margin/VBox/TopRow/HeaderCard/HeaderRow/StageBadge"
const STAGE_BADGE_LABEL_PATH := "Margin/VBox/TopRow/HeaderCard/HeaderRow/StageBadge/StageBadgeLabel"
const RUN_SUMMARY_CARD_PATH := "Margin/VBox/TopRow/RunSummaryCard"
const ROUTE_GRID_PATH := "Margin/VBox/RouteGrid"
const BOARD_FRAME_PATH := "Margin/VBox/RouteGrid/BoardFrame"
const SAFE_MENU_ANCHOR_PATH := "Margin/VBox/TopRow/SettingsMenuAnchor"
const SHOW_BOTTOM_CONTEXT := false


static func ensure_runtime_board_nodes(route_grid: Control, route_marker_node_names: PackedStringArray, current_marker: TextureRect, walker_root: Control, walker_shadow: PanelContainer, walker_sprite: TextureRect, walker_root_size: Vector2, walker_shadow_size: Vector2, walker_sprite_size: Vector2, board_canvas: Control) -> Dictionary:
	if route_grid == null:
		return {
			"current_marker": current_marker,
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
	var top_row: HBoxContainer = root.get_node_or_null(TOP_ROW_PATH) as HBoxContainer
	var top_row_shell: PanelContainer = root.get_node_or_null("Margin/VBox/TopRowShell") as PanelContainer
	if top_row_shell == null:
		var root_vbox: VBoxContainer = root.get_node_or_null("Margin/VBox") as VBoxContainer
		if root_vbox != null:
			top_row_shell = PanelContainer.new()
			top_row_shell.name = "TopRowShell"
			top_row_shell.visible = false
			top_row_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root_vbox.add_child(top_row_shell)
			root_vbox.move_child(top_row_shell, 0)
	var header_card: PanelContainer = root.get_node_or_null(HEADER_CARD_PATH) as PanelContainer
	var run_summary_card: PanelContainer = root.get_node_or_null(RUN_SUMMARY_CARD_PATH) as PanelContainer
	var top_row_divider: ColorRect = root.get_node_or_null("%s/TopRowDivider" % TOP_ROW_PATH) as ColorRect
	var stage_badge: PanelContainer = root.get_node_or_null(STAGE_BADGE_PATH) as PanelContainer
	var stage_badge_label: Label = root.get_node_or_null(STAGE_BADGE_LABEL_PATH) as Label
	var settings_button: Button = root.get_node_or_null("%s/SettingsButton" % SAFE_MENU_ANCHOR_PATH) as Button
	var board_frame: PanelContainer = root.get_node_or_null(BOARD_FRAME_PATH) as PanelContainer
	var equipment_card: PanelContainer = root.get_node_or_null("Margin/VBox/InventorySection/EquipmentCard") as PanelContainer
	var inventory_card: PanelContainer = root.get_node_or_null("Margin/VBox/InventorySection/InventoryCard") as PanelContainer
	var current_anchor_card: PanelContainer = root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard") as PanelContainer
	var status_card: PanelContainer = root.get_node_or_null("Margin/VBox/BottomRow/StatusCard") as PanelContainer
	_apply_compact_map_panel(header_card, TempScreenThemeScript.PANEL_BORDER_COLOR, 16, 0.42, 12, 10)
	_apply_top_shell_cell(header_card, TempScreenThemeScript.PANEL_BORDER_COLOR)
	_apply_compact_map_panel(run_summary_card, TempScreenThemeScript.TEAL_ACCENT_COLOR.darkened(0.12), 16, 0.46, 12, 10)
	_apply_top_shell_cell(run_summary_card, TempScreenThemeScript.TEAL_ACCENT_COLOR)
	TempScreenThemeScript.apply_inventory_section_panel(equipment_card, TempScreenThemeScript.TEAL_ACCENT_COLOR, "roomy")
	TempScreenThemeScript.apply_inventory_section_panel(inventory_card, TempScreenThemeScript.REWARD_ACCENT_COLOR, "roomy")
	TempScreenThemeScript.apply_choice_card_shell(current_anchor_card, TempScreenThemeScript.TEAL_ACCENT_COLOR)
	_apply_compact_map_panel(status_card, TempScreenThemeScript.TEAL_ACCENT_COLOR.darkened(0.08), 16, 0.74, 12, 10)
	_apply_top_row_shell(top_row_shell)
	_apply_top_row_divider(top_row_divider)
	_apply_stage_badge_style(stage_badge, stage_badge_label)
	_apply_settings_button_style(settings_button)
	_apply_board_frame_style(board_frame)

	var title_label: Label = root.get_node_or_null("%s/TitleLabel" % HEADER_STACK_PATH) as Label
	TempScreenThemeScript.apply_label(title_label, "title")
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 30)
		title_label.clip_text = true
		title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title_label.max_lines_visible = 1

	var progress_label: Label = root.get_node_or_null("%s/ProgressLabel" % HEADER_STACK_PATH) as Label
	TempScreenThemeScript.apply_label(progress_label, "accent")
	if progress_label != null:
		progress_label.add_theme_font_size_override("font_size", 12)
		progress_label.clip_text = true
		progress_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		progress_label.max_lines_visible = 1

	var route_read_label: Label = root.get_node_or_null("%s/RouteReadLabel" % HEADER_STACK_PATH) as Label
	TempScreenThemeScript.apply_label(route_read_label, "muted")
	if route_read_label != null:
		route_read_label.add_theme_font_size_override("font_size", 14)
		route_read_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		route_read_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		route_read_label.max_lines_visible = 2

	var run_status_label: Label = root.get_node_or_null("%s/RunStatusLabel" % RUN_SUMMARY_CARD_PATH) as Label
	TempScreenThemeScript.apply_label(run_status_label, "muted")
	if run_status_label != null:
		run_status_label.add_theme_font_size_override("font_size", 14)
		run_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		run_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		run_status_label.max_lines_visible = 3

	var equipment_title_label: Label = root.get_node_or_null("Margin/VBox/InventorySection/EquipmentTitleLabel") as Label
	var equipment_hint_label: Label = root.get_node_or_null("Margin/VBox/InventorySection/EquipmentHintLabel") as Label
	TempScreenThemeScript.apply_inventory_section_text(equipment_title_label, equipment_hint_label, "accent", "standard")

	var inventory_title_label: Label = root.get_node_or_null("Margin/VBox/InventorySection/InventoryTitleLabel") as Label
	var inventory_hint_label: Label = root.get_node_or_null("Margin/VBox/InventorySection/InventoryHintLabel") as Label
	TempScreenThemeScript.apply_inventory_section_text(inventory_title_label, inventory_hint_label, "reward", "standard")

	var current_anchor_label: Label = root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorLabel") as Label
	TempScreenThemeScript.apply_label(current_anchor_label, "accent")
	if current_anchor_label != null:
		current_anchor_label.add_theme_font_size_override("font_size", 20)
	var current_anchor_detail_label: Label = root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorDetailLabel") as Label
	TempScreenThemeScript.apply_label(current_anchor_detail_label)
	if current_anchor_detail_label != null:
		current_anchor_detail_label.add_theme_font_size_override("font_size", 15)
		current_anchor_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		current_anchor_detail_label.max_lines_visible = 2
	var current_anchor_hint_label: Label = root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorHintLabel") as Label
	TempScreenThemeScript.apply_label(current_anchor_hint_label, "muted")
	if current_anchor_hint_label != null:
		current_anchor_hint_label.add_theme_font_size_override("font_size", 13)
		current_anchor_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		current_anchor_hint_label.max_lines_visible = 2

	var status_label: Label = root.get_node_or_null("Margin/VBox/BottomRow/StatusCard/StatusLabel") as Label
	TempScreenThemeScript.apply_label(status_label, "muted")
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 14)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status_label.max_lines_visible = 2

	var header_stack: VBoxContainer = root.get_node_or_null(HEADER_STACK_PATH) as VBoxContainer
	if header_stack != null:
		header_stack.add_theme_constant_override("separation", 3)
	var current_anchor_stack: VBoxContainer = root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox") as VBoxContainer
	if current_anchor_stack != null:
		current_anchor_stack.add_theme_constant_override("separation", 3)

	var board_backdrop: TextureRect = root.get_node_or_null("%s/BoardBackdrop" % ROUTE_GRID_PATH) as TextureRect
	if board_backdrop != null:
		board_backdrop.modulate = Color(0.78, 0.86, 0.82, 0.28)


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

	var route_read_label: Label = root.get_node_or_null("%s/RouteReadLabel" % HEADER_STACK_PATH) as Label
	if route_read_label != null:
		route_read_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		route_read_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		route_read_label.max_lines_visible = 2

	var current_anchor_detail_label: Label = root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorDetailLabel") as Label
	if current_anchor_detail_label != null:
		current_anchor_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		current_anchor_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		current_anchor_detail_label.max_lines_visible = 2

	var current_anchor_hint_label: Label = root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorHintLabel") as Label
	if current_anchor_hint_label != null:
		current_anchor_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		current_anchor_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		current_anchor_hint_label.max_lines_visible = 2

	var status_label: Label = root.get_node_or_null("Margin/VBox/BottomRow/StatusCard/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 15)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status_label.max_lines_visible = 2


static func apply_portrait_safe_layout(root: Control, max_width: int, min_side_margin: int) -> void:
	if root == null:
		return

	var margin: MarginContainer = root.get_node_or_null("Margin") as MarginContainer
	var vbox: VBoxContainer = root.get_node_or_null("Margin/VBox") as VBoxContainer
	var route_grid: Control = root.get_node_or_null(ROUTE_GRID_PATH) as Control
	var header_card: PanelContainer = root.get_node_or_null(HEADER_CARD_PATH) as PanelContainer
	var route_read_label: Label = root.get_node_or_null("%s/RouteReadLabel" % HEADER_STACK_PATH) as Label
	var inventory_section: VBoxContainer = root.get_node_or_null("Margin/VBox/InventorySection") as VBoxContainer
	var equipment_card: PanelContainer = root.get_node_or_null("Margin/VBox/InventorySection/EquipmentCard") as PanelContainer
	var equipment_cards_flow: HBoxContainer = root.get_node_or_null("Margin/VBox/InventorySection/EquipmentCard/EquipmentCardsFlow") as HBoxContainer
	var equipment_title_label: Label = root.get_node_or_null("Margin/VBox/InventorySection/EquipmentTitleLabel") as Label
	var equipment_hint_label: Label = root.get_node_or_null("Margin/VBox/InventorySection/EquipmentHintLabel") as Label
	var inventory_card: PanelContainer = root.get_node_or_null("Margin/VBox/InventorySection/InventoryCard") as PanelContainer
	var inventory_cards_flow: HBoxContainer = root.get_node_or_null("Margin/VBox/InventorySection/InventoryCard/InventoryCardsFlow") as HBoxContainer
	var inventory_title_label: Label = root.get_node_or_null("Margin/VBox/InventorySection/InventoryTitleLabel") as Label
	var inventory_hint_label: Label = root.get_node_or_null("Margin/VBox/InventorySection/InventoryHintLabel") as Label
	var top_row: HBoxContainer = root.get_node_or_null(TOP_ROW_PATH) as HBoxContainer
	var bottom_row: VBoxContainer = root.get_node_or_null("Margin/VBox/BottomRow") as VBoxContainer
	var current_anchor_card: PanelContainer = root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard") as PanelContainer
	var status_card: PanelContainer = root.get_node_or_null("Margin/VBox/BottomRow/StatusCard") as PanelContainer
	var safe_menu_anchor: Control = root.get_node_or_null(SAFE_MENU_ANCHOR_PATH) as Control
	var run_summary_card: PanelContainer = root.get_node_or_null(RUN_SUMMARY_CARD_PATH) as PanelContainer
	var top_row_divider: ColorRect = root.get_node_or_null("%s/TopRowDivider" % TOP_ROW_PATH) as ColorRect
	var stage_badge: Control = root.get_node_or_null(STAGE_BADGE_PATH) as Control
	var current_anchor_hint_label: Label = root.get_node_or_null("Margin/VBox/BottomRow/CurrentAnchorCard/VBox/CurrentAnchorHintLabel") as Label
	if margin == null or route_grid == null:
		return

	var viewport_size: Vector2 = root.get_viewport_rect().size
	var compact_layout: bool = viewport_size.y < InventoryPanelLayoutScript.MAP_SECTION_COMPACT_HEIGHT_THRESHOLD
	var very_compact_layout: bool = viewport_size.y < InventoryPanelLayoutScript.VERY_COMPACT_HEIGHT_THRESHOLD
	var inventory_density_band: String = InventoryPanelLayoutScript.density_band_from_flags(compact_layout, very_compact_layout)
	var launcher_metrics: Dictionary = SafeMenuLauncherStyleScript.resolve_launcher_metrics_for_viewport(viewport_size)
	var launcher_dimensions: Vector2 = Vector2(launcher_metrics.get("dimensions", Vector2(62.0, 70.0)))
	SceneLayoutHelperScript.apply_portrait_layout(root, {
		"max_width": max_width,
		"min_side_margin": min_side_margin,
		"top_margin": 14,
		"bottom_margin": 8,
		"margin_steps": [
			{"max_height": 1760.0, "top_margin": 12, "bottom_margin": 6},
			{"max_height": 1560.0, "top_margin": 10, "bottom_margin": 5},
			{"max_height": 1400.0, "top_margin": 12, "bottom_margin": 4},
		],
	})

	if vbox != null:
		vbox.add_theme_constant_override("separation", 4 if compact_layout else 6)

	# Top HUD
	if top_row != null:
		top_row.alignment = 0
		top_row.add_theme_constant_override("separation", 8 if compact_layout else 12)
		top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		if header_card != null:
			header_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			header_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			header_card.size_flags_stretch_ratio = 1.02
			header_card.custom_minimum_size = Vector2(0.0, 0.0)
		if route_read_label != null:
			route_read_label.max_lines_visible = 2 if compact_layout else 1
		if run_summary_card != null:
			run_summary_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			run_summary_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			run_summary_card.size_flags_stretch_ratio = 1.18
			run_summary_card.custom_minimum_size = Vector2(0.0, 0.0)
		if top_row_divider != null:
			top_row_divider.visible = not very_compact_layout
			top_row_divider.custom_minimum_size = Vector2(2.0, 0.0)
		if stage_badge != null:
			var badge_size: float = 54.0 if compact_layout else 62.0
			stage_badge.custom_minimum_size = Vector2(badge_size, badge_size)
		if safe_menu_anchor != null:
			safe_menu_anchor.size_flags_horizontal = Control.SIZE_SHRINK_END
			safe_menu_anchor.size_flags_vertical = Control.SIZE_EXPAND_FILL
			safe_menu_anchor.size_flags_stretch_ratio = 0.0
			safe_menu_anchor.custom_minimum_size = launcher_dimensions
			var settings_button: Button = safe_menu_anchor.get_node_or_null("SettingsButton") as Button
			if settings_button != null:
				_apply_settings_button_style(settings_button, viewport_size)
				_layout_settings_button_in_anchor(safe_menu_anchor, settings_button, launcher_dimensions)

	# Middle map (main content)
	route_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	route_grid.custom_minimum_size = Vector2(0.0, 560.0 if very_compact_layout else 620.0 if compact_layout else 680.0)

	# Bottom action/info block (inventory + state summary)
	if inventory_section != null:
		inventory_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inventory_section.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		inventory_section.add_theme_constant_override("separation", InventoryPanelLayoutScript.map_section_separation(inventory_density_band))
		inventory_section.custom_minimum_size = Vector2.ZERO
		if equipment_title_label != null:
			equipment_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		if equipment_hint_label != null:
			equipment_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			equipment_hint_label.max_lines_visible = InventoryPanelLayoutScript.map_hint_max_lines(inventory_density_band)
		if equipment_cards_flow != null:
			equipment_cards_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			equipment_cards_flow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			equipment_cards_flow.custom_minimum_size = Vector2.ZERO
			equipment_cards_flow.add_theme_constant_override("separation", InventoryPanelLayoutScript.card_flow_separation(inventory_density_band))
		if equipment_card != null:
			equipment_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			equipment_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			equipment_card.custom_minimum_size = Vector2(0.0, InventoryPanelLayoutScript.panel_height("equipment", inventory_density_band))
		if inventory_title_label != null:
			inventory_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		if inventory_hint_label != null:
			inventory_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			inventory_hint_label.max_lines_visible = InventoryPanelLayoutScript.map_hint_max_lines(inventory_density_band)
		if inventory_cards_flow != null:
			inventory_cards_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			inventory_cards_flow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			inventory_cards_flow.custom_minimum_size = Vector2.ZERO
			inventory_cards_flow.add_theme_constant_override("separation", InventoryPanelLayoutScript.card_flow_separation(inventory_density_band))
		if inventory_card != null:
			inventory_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			inventory_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			inventory_card.custom_minimum_size = Vector2(0.0, InventoryPanelLayoutScript.panel_height("backpack", inventory_density_band))

	if bottom_row != null:
		bottom_row.visible = SHOW_BOTTOM_CONTEXT
		bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bottom_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		bottom_row.add_theme_constant_override("separation", 2 if very_compact_layout else 4)
		bottom_row.custom_minimum_size = Vector2.ZERO
		if current_anchor_card != null:
			current_anchor_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			current_anchor_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			current_anchor_card.custom_minimum_size = Vector2.ZERO
		if current_anchor_hint_label != null:
			current_anchor_hint_label.max_lines_visible = InventoryPanelLayoutScript.map_hint_max_lines(inventory_density_band)
		if status_card != null:
			status_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			status_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			status_card.custom_minimum_size = Vector2.ZERO

	_flush_container_layout(vbox)
	_flush_container_layout(top_row)
	_flush_container_layout(route_grid)
	_flush_container_layout(inventory_section)
	_flush_container_layout(bottom_row)


static func _apply_top_row_shell(shell: PanelContainer) -> void:
	if shell == null:
		return
	_apply_compact_map_panel(shell, TempScreenThemeScript.PANEL_BORDER_COLOR, 22, 0.82, 18, 14)
	TempScreenThemeScript.intensify_panel(shell, TempScreenThemeScript.PANEL_BORDER_COLOR, 3, 26, 0.05, 0.24, 20, 14)


static func _apply_top_shell_cell(panel: PanelContainer, accent: Color) -> void:
	if panel == null:
		return
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	var tuned_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	tuned_style.bg_color = Color(
		tuned_style.bg_color.r,
		tuned_style.bg_color.g,
		tuned_style.bg_color.b,
		0.18
	)
	tuned_style.border_color = Color(accent.r, accent.g, accent.b, 0.22)
	tuned_style.border_width_left = 1
	tuned_style.border_width_top = 1
	tuned_style.border_width_right = 1
	tuned_style.border_width_bottom = 1
	tuned_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.06)
	tuned_style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", tuned_style)


static func _apply_top_row_divider(divider: ColorRect) -> void:
	if divider == null:
		return
	divider.color = Color(
		TempScreenThemeScript.PANEL_BORDER_COLOR.r,
		TempScreenThemeScript.PANEL_BORDER_COLOR.g,
		TempScreenThemeScript.PANEL_BORDER_COLOR.b,
		0.18
	)


static func ensure_settings_menu_button(root: Control, pressed_handler: Callable) -> Button:
	if root == null:
		return null
	var safe_menu_anchor: Control = root.get_node_or_null(SAFE_MENU_ANCHOR_PATH) as Control
	if safe_menu_anchor == null:
		return null
	var button: Button = safe_menu_anchor.get_node_or_null("SettingsButton") as Button
	if button == null:
		button = Button.new()
		button.name = "SettingsButton"
		button.anchor_left = 0.5
		button.anchor_top = 0.5
		button.anchor_right = 0.5
		button.anchor_bottom = 0.5
		button.grow_horizontal = Control.GROW_DIRECTION_BOTH
		button.grow_vertical = Control.GROW_DIRECTION_BOTH
		button.text = ""
		button.tooltip_text = "Settings"
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		safe_menu_anchor.add_child(button)
		_flush_container_layout(safe_menu_anchor)
	if pressed_handler.is_valid() and not button.is_connected("pressed", pressed_handler):
		button.pressed.connect(pressed_handler)
	_apply_settings_button_style(button, root.get_viewport_rect().size)
	_layout_settings_button_in_anchor(safe_menu_anchor, button, button.custom_minimum_size)
	return button


static func _apply_settings_button_style(button: Button, viewport_size: Vector2 = Vector2.ZERO) -> void:
	if button == null:
		return
	var effective_viewport_size: Vector2 = viewport_size
	if effective_viewport_size == Vector2.ZERO:
		effective_viewport_size = button.get_viewport_rect().size
	var launcher_metrics: Dictionary = SafeMenuLauncherStyleScript.resolve_launcher_metrics_for_viewport(effective_viewport_size)
	SafeMenuLauncherStyleScript.apply_shared_launcher_button_style(
		button,
		"Settings",
		Vector2(launcher_metrics.get("dimensions", Vector2(62.0, 70.0))),
		int(launcher_metrics.get("icon_size", 28))
	)
	button.mouse_filter = Control.MOUSE_FILTER_STOP


static func _layout_settings_button_in_anchor(anchor: Control, button: Button, launcher_dimensions: Vector2) -> void:
	if anchor == null or button == null:
		return
	button.anchor_left = 0.5
	button.anchor_top = 0.5
	button.anchor_right = 0.5
	button.anchor_bottom = 0.5
	button.offset_left = -launcher_dimensions.x * 0.5
	button.offset_top = -launcher_dimensions.y * 0.5
	button.offset_right = launcher_dimensions.x * 0.5
	button.offset_bottom = launcher_dimensions.y * 0.5


static func _apply_stage_badge_style(stage_badge: PanelContainer, stage_badge_label: Label) -> void:
	if stage_badge == null or stage_badge_label == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.23, 0.11, 0.96)
	style.border_color = TempScreenThemeScript.REWARD_ACCENT_COLOR.lightened(0.12)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_right = 999
	style.corner_radius_bottom_left = 999
	style.shadow_color = Color(TempScreenThemeScript.REWARD_ACCENT_COLOR.r, TempScreenThemeScript.REWARD_ACCENT_COLOR.g, TempScreenThemeScript.REWARD_ACCENT_COLOR.b, 0.22)
	style.shadow_size = 16
	stage_badge.add_theme_stylebox_override("panel", style)
	TempScreenThemeScript.apply_font_role(stage_badge_label, "heading")
	stage_badge_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	stage_badge_label.add_theme_font_size_override("font_size", 22)


static func _apply_board_frame_style(board_frame: PanelContainer) -> void:
	if board_frame == null:
		return
	TempScreenThemeScript.apply_panel(board_frame, TempScreenThemeScript.TEAL_ACCENT_COLOR, 30, 0.72)
	TempScreenThemeScript.intensify_panel(board_frame, TempScreenThemeScript.TEAL_ACCENT_COLOR, 2, 24, 0.03, 0.18, 16, 16)

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


static func _soften_embedded_panel(panel: PanelContainer, accent: Color) -> void:
	if panel == null:
		return

	var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return

	var softened_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	softened_style.border_width_left = 1
	softened_style.border_width_top = 1
	softened_style.border_width_right = 1
	softened_style.border_width_bottom = 1
	softened_style.border_color = Color(accent.r, accent.g, accent.b, 0.36)
	softened_style.bg_color = Color(softened_style.bg_color.r, softened_style.bg_color.g, softened_style.bg_color.b, 0.54)
	softened_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.08)
	softened_style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", softened_style)


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
