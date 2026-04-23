# Layer: UI
extends RefCounted
class_name MapQuestLogPanel

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")

const TOP_ROW_PATH := "Margin/VBox/TopRow"
const LAUNCHER_NODE_NAME := "QuestLogLauncherButton"
const PANEL_NODE_NAME := "QuestLogPanel"
const TOAST_NODE_NAME := "QuestLogUpdateToast"
const TOAST_HIDE_DELAY_SECONDS := 1.8

var _root: Control
var _launcher_button: Button
var _panel: PanelContainer
var _launcher_chip_panel: PanelContainer
var _launcher_chip_label: Label
var _launcher_hint_label: Label
var _launcher_unread_dot: PanelContainer
var _toast_panel: PanelContainer
var _toast_label: Label
var _status_value_label: Label
var _mission_title_label: Label
var _summary_label: Label
var _objective_title_label: Label
var _objective_value_label: Label
var _detail_label: Label
var _hint_label: Label
var _close_button: Button
var _is_open: bool = false
var _before_toggle_handler: Callable
var _has_seen_first_model: bool = false
var _has_unread_update: bool = false
var _last_model_signature: String = ""
var _toast_cycle_token: int = 0


func configure(root: Control, before_toggle_handler: Callable = Callable()) -> void:
	_root = root
	_before_toggle_handler = before_toggle_handler
	_launcher_button = _ensure_launcher_button()
	_panel = _ensure_panel()
	_toast_panel = _ensure_toast_panel()
	_layout_launcher_children()
	_apply_theme()
	refresh_layout()
	apply_model({})
	set_open(false)


func apply_model(model: Dictionary) -> void:
	if _mission_title_label == null:
		return
	var safe_model: Dictionary = model if not model.is_empty() else {
		"has_active_contract": false,
		"status_semantic": "empty",
		"status_text": "EMPTY",
		"mission_title_text": "No active contract",
		"summary_text": "",
		"objective_title_text": "",
		"objective_text": "",
		"detail_text": "",
		"hint_text": "",
		"launcher_chip_text": "",
		"launcher_hint_text": "",
		"toast_text": "",
	}
	var current_signature: String = _build_model_signature(safe_model)
	var has_active_contract: bool = bool(safe_model.get("has_active_contract", false))
	var changed_since_last_model: bool = _has_seen_first_model and current_signature != _last_model_signature

	_status_value_label.text = String(safe_model.get("status_text", "EMPTY"))
	_mission_title_label.text = String(safe_model.get("mission_title_text", "No active contract"))
	_summary_label.text = String(safe_model.get("summary_text", ""))
	_objective_title_label.text = String(safe_model.get("objective_title_text", ""))
	_objective_value_label.text = String(safe_model.get("objective_text", ""))
	_detail_label.text = String(safe_model.get("detail_text", ""))
	_hint_label.text = String(safe_model.get("hint_text", ""))

	_summary_label.visible = not _summary_label.text.is_empty()
	_objective_title_label.visible = not _objective_title_label.text.is_empty()
	_objective_value_label.visible = not _objective_value_label.text.is_empty()
	_detail_label.visible = not _detail_label.text.is_empty()
	_hint_label.visible = not _hint_label.text.is_empty()

	var status_semantic: String = String(safe_model.get("status_semantic", "empty"))
	_apply_status_label_color(status_semantic)
	if _launcher_button != null:
		_launcher_button.modulate = Color.WHITE if has_active_contract else Color(1.0, 1.0, 1.0, 0.92)
		_launcher_button.tooltip_text = _build_launcher_tooltip(safe_model)
	_update_launcher_surface(safe_model)

	if not has_active_contract:
		_has_unread_update = false
		_hide_toast()
	elif changed_since_last_model and not _is_open:
		_has_unread_update = true
		_show_toast(String(safe_model.get("toast_text", "")))
	elif _is_open:
		_has_unread_update = false

	_sync_unread_dot()
	_has_seen_first_model = true
	_last_model_signature = current_signature


func set_open(next_is_open: bool) -> void:
	_is_open = next_is_open
	if _panel != null:
		_panel.visible = _is_open
	if _is_open:
		_has_unread_update = false
		_sync_unread_dot()
		_hide_toast()


func toggle() -> void:
	set_open(not _is_open)


func close() -> void:
	set_open(false)


func is_open() -> bool:
	return _is_open


func set_interaction_enabled(enabled: bool) -> void:
	if _launcher_button != null:
		_launcher_button.visible = enabled
		_launcher_button.disabled = not enabled
		_launcher_button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if _toast_panel != null:
		_toast_panel.visible = enabled and _toast_panel.visible
	if not enabled:
		close()


func refresh_layout() -> void:
	if _root == null:
		return

	var root_size: Vector2 = _resolve_root_size()
	var top_row: Control = _root.get_node_or_null(TOP_ROW_PATH) as Control
	var top_row_rect: Rect2 = _resolve_top_row_local_rect(top_row, root_size)
	var local_top: float = max(16.0, top_row_rect.position.y + top_row_rect.size.y + 10.0)
	var right_margin: float = 16.0
	var button_size: Vector2 = _resolve_launcher_button_size()

	if _launcher_button != null:
		_launcher_button.anchor_left = 1.0
		_launcher_button.anchor_right = 1.0
		_launcher_button.anchor_top = 0.0
		_launcher_button.anchor_bottom = 0.0
		_launcher_button.offset_left = -right_margin - button_size.x
		_launcher_button.offset_top = local_top
		_launcher_button.offset_right = -right_margin
		_launcher_button.offset_bottom = local_top + button_size.y

	if _panel != null:
		var panel_width: float = min(392.0, max(264.0, root_size.x - 32.0))
		var panel_height: float = clampf(root_size.y * 0.26, 228.0, 332.0)
		var panel_top: float = local_top + button_size.y + 10.0
		if panel_top + panel_height > root_size.y - 16.0:
			panel_top = max(16.0, root_size.y - 16.0 - panel_height)
		_panel.anchor_left = 1.0
		_panel.anchor_right = 1.0
		_panel.anchor_top = 0.0
		_panel.anchor_bottom = 0.0
		_panel.offset_left = -right_margin - panel_width
		_panel.offset_top = panel_top
		_panel.offset_right = -right_margin
		_panel.offset_bottom = panel_top + panel_height

	if _toast_panel != null:
		var toast_width: float = 264.0
		var toast_height: float = 56.0
		var toast_top: float = local_top + button_size.y + 8.0
		if _panel != null and _panel.visible:
			toast_top = _panel.offset_top - toast_height - 8.0
		if toast_top + toast_height > root_size.y - 16.0:
			toast_top = max(16.0, root_size.y - 16.0 - toast_height)
		_toast_panel.anchor_left = 1.0
		_toast_panel.anchor_right = 1.0
		_toast_panel.anchor_top = 0.0
		_toast_panel.anchor_bottom = 0.0
		_toast_panel.offset_left = -right_margin - toast_width
		_toast_panel.offset_top = toast_top
		_toast_panel.offset_right = -right_margin
		_toast_panel.offset_bottom = toast_top + toast_height


func _resolve_root_size() -> Vector2:
	var root_size: Vector2 = _root.size
	if root_size == Vector2.ZERO:
		root_size = _root.get_rect().size
	if root_size == Vector2.ZERO:
		root_size = _root.get_viewport_rect().size
	if root_size == Vector2.ZERO:
		root_size = Vector2(1080.0, 1920.0)
	return root_size


func _resolve_top_row_local_rect(top_row: Control, root_size: Vector2) -> Rect2:
	if top_row == null:
		return Rect2(Vector2(0.0, 12.0), Vector2(root_size.x, 72.0))
	var resolved_height: float = max(top_row.size.y, top_row.custom_minimum_size.y, 72.0)
	return Rect2(Vector2(top_row.position.x, top_row.position.y), Vector2(max(top_row.size.x, root_size.x), resolved_height))


func _resolve_launcher_button_size() -> Vector2:
	if _launcher_button == null:
		return Vector2(136.0, 60.0)
	if _launcher_button.size != Vector2.ZERO:
		return _launcher_button.size
	if _launcher_button.custom_minimum_size != Vector2.ZERO:
		return _launcher_button.custom_minimum_size
	return Vector2(136.0, 60.0)


func _ensure_launcher_button() -> Button:
	var button: Button = _root.get_node_or_null(LAUNCHER_NODE_NAME) as Button
	if button == null:
		button = Button.new()
		button.name = LAUNCHER_NODE_NAME
		button.text = "Quest"
		button.tooltip_text = "Quest Log"
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.focus_mode = Control.FOCUS_ALL
		button.z_index = 15
		button.icon = load(UiAssetPathsScript.HAMLET_ICON_TEXTURE_PATH)
		_root.add_child(button)
	_ensure_launcher_children(button)
	var toggle_handler := Callable(self, "_on_toggle_requested")
	if not button.is_connected("pressed", toggle_handler):
		button.pressed.connect(toggle_handler)
	return button


func _ensure_panel() -> PanelContainer:
	var panel: PanelContainer = _root.get_node_or_null(PANEL_NODE_NAME) as PanelContainer
	if panel == null:
		panel = PanelContainer.new()
		panel.name = PANEL_NODE_NAME
		panel.visible = false
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.z_index = 14
		_root.add_child(panel)

	var content_vbox: VBoxContainer = panel.get_node_or_null("ContentVBox") as VBoxContainer
	if content_vbox == null:
		content_vbox = VBoxContainer.new()
		content_vbox.name = "ContentVBox"
		content_vbox.add_theme_constant_override("separation", 6)
		panel.add_child(content_vbox)

	var header_row: HBoxContainer = content_vbox.get_node_or_null("HeaderRow") as HBoxContainer
	if header_row == null:
		header_row = HBoxContainer.new()
		header_row.name = "HeaderRow"
		header_row.add_theme_constant_override("separation", 8)
		content_vbox.add_child(header_row)

	var title_label: Label = header_row.get_node_or_null("TitleLabel") as Label
	if title_label == null:
		title_label = Label.new()
		title_label.name = "TitleLabel"
		title_label.text = "Quest Log"
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(title_label)

	var status_value_label: Label = header_row.get_node_or_null("StatusValueLabel") as Label
	if status_value_label == null:
		status_value_label = Label.new()
		status_value_label.name = "StatusValueLabel"
		status_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		header_row.add_child(status_value_label)

	var close_button: Button = header_row.get_node_or_null("CloseButton") as Button
	if close_button == null:
		close_button = Button.new()
		close_button.name = "CloseButton"
		close_button.text = "Hide"
		header_row.add_child(close_button)
	var toggle_handler := Callable(self, "_on_toggle_requested")
	if not close_button.is_connected("pressed", toggle_handler):
		close_button.pressed.connect(toggle_handler)

	var mission_title_label: Label = content_vbox.get_node_or_null("MissionTitleLabel") as Label
	if mission_title_label == null:
		mission_title_label = Label.new()
		mission_title_label.name = "MissionTitleLabel"
		mission_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content_vbox.add_child(mission_title_label)

	var summary_label: Label = content_vbox.get_node_or_null("SummaryLabel") as Label
	if summary_label == null:
		summary_label = Label.new()
		summary_label.name = "SummaryLabel"
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content_vbox.add_child(summary_label)

	var objective_title_label: Label = content_vbox.get_node_or_null("ObjectiveTitleLabel") as Label
	if objective_title_label == null:
		objective_title_label = Label.new()
		objective_title_label.name = "ObjectiveTitleLabel"
		content_vbox.add_child(objective_title_label)

	var objective_value_label: Label = content_vbox.get_node_or_null("ObjectiveValueLabel") as Label
	if objective_value_label == null:
		objective_value_label = Label.new()
		objective_value_label.name = "ObjectiveValueLabel"
		objective_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content_vbox.add_child(objective_value_label)

	var detail_label: Label = content_vbox.get_node_or_null("DetailLabel") as Label
	if detail_label == null:
		detail_label = Label.new()
		detail_label.name = "DetailLabel"
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content_vbox.add_child(detail_label)

	var hint_label: Label = content_vbox.get_node_or_null("HintLabel") as Label
	if hint_label == null:
		hint_label = Label.new()
		hint_label.name = "HintLabel"
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content_vbox.add_child(hint_label)

	_status_value_label = status_value_label
	_mission_title_label = mission_title_label
	_summary_label = summary_label
	_objective_title_label = objective_title_label
	_objective_value_label = objective_value_label
	_detail_label = detail_label
	_hint_label = hint_label
	_close_button = close_button
	return panel


func _ensure_toast_panel() -> PanelContainer:
	var panel: PanelContainer = _root.get_node_or_null(TOAST_NODE_NAME) as PanelContainer
	if panel == null:
		panel = PanelContainer.new()
		panel.name = TOAST_NODE_NAME
		panel.visible = false
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.modulate = Color(1, 1, 1, 0)
		panel.z_index = 16
		_root.add_child(panel)

	var label: Label = panel.get_node_or_null("ToastLabel") as Label
	if label == null:
		label = Label.new()
		label.name = "ToastLabel"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(label)

	_toast_label = label
	return panel


func _apply_theme() -> void:
	if _launcher_button != null:
		_launcher_button.custom_minimum_size = Vector2(136.0, 60.0)
		TempScreenThemeScript.apply_small_button(_launcher_button, TempScreenThemeScript.REWARD_ACCENT_COLOR, false)
		_launcher_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_launcher_button.clip_text = true
		_launcher_button.add_theme_font_size_override("font_size", 15)
	if _panel != null:
		TempScreenThemeScript.apply_inventory_section_panel(_panel, TempScreenThemeScript.REWARD_ACCENT_COLOR, "compact")
		TempScreenThemeScript.intensify_panel(_panel, TempScreenThemeScript.REWARD_ACCENT_COLOR, 2, 18, 0.02, 0.16, 16, 12)
	if _toast_panel != null:
		TempScreenThemeScript.apply_panel(_toast_panel, TempScreenThemeScript.TEAL_ACCENT_COLOR, 14, 0.96)
	var title_label: Label = null
	if _panel != null:
		title_label = _panel.get_node_or_null("ContentVBox/HeaderRow/TitleLabel") as Label
	TempScreenThemeScript.apply_label(title_label, "accent")
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 18)
	if _status_value_label != null:
		TempScreenThemeScript.apply_label(_status_value_label, "reward")
		_status_value_label.add_theme_font_size_override("font_size", 13)
	if _close_button != null:
		_close_button.custom_minimum_size = Vector2(92.0, 42.0)
		TempScreenThemeScript.apply_small_button(_close_button, TempScreenThemeScript.PANEL_BORDER_COLOR, true)
	if _mission_title_label != null:
		TempScreenThemeScript.apply_label(_mission_title_label, "body")
		_mission_title_label.add_theme_font_size_override("font_size", 17)
	if _summary_label != null:
		TempScreenThemeScript.apply_label(_summary_label, "muted")
	if _objective_title_label != null:
		TempScreenThemeScript.apply_label(_objective_title_label, "reward")
		_objective_title_label.add_theme_font_size_override("font_size", 13)
	if _objective_value_label != null:
		TempScreenThemeScript.apply_label(_objective_value_label, "body")
	if _detail_label != null:
		TempScreenThemeScript.apply_label(_detail_label, "muted")
		_detail_label.add_theme_font_size_override("font_size", 13)
	if _hint_label != null:
		TempScreenThemeScript.apply_label(_hint_label, "muted")
		_hint_label.add_theme_font_size_override("font_size", 12)
	if _launcher_chip_panel != null:
		_launcher_chip_panel.add_theme_stylebox_override("panel", _build_launcher_chip_style(TempScreenThemeScript.REWARD_ACCENT_COLOR))
	if _launcher_chip_label != null:
		TempScreenThemeScript.apply_label(_launcher_chip_label, "reward")
		_launcher_chip_label.add_theme_font_size_override("font_size", 11)
	if _launcher_hint_label != null:
		TempScreenThemeScript.apply_label(_launcher_hint_label, "muted")
		_launcher_hint_label.add_theme_font_size_override("font_size", 11)
	if _launcher_unread_dot != null:
		_launcher_unread_dot.add_theme_stylebox_override("panel", _build_unread_dot_style())
	if _toast_label != null:
		TempScreenThemeScript.apply_label(_toast_label, "muted")
		_toast_label.add_theme_font_size_override("font_size", 12)


func _apply_status_label_color(status_semantic: String) -> void:
	if _status_value_label == null:
		return
	var status_color: Color = TempScreenThemeScript.TEXT_MUTED_COLOR
	match status_semantic:
		"accepted":
			status_color = TempScreenThemeScript.REWARD_ACCENT_COLOR
		"completed":
			status_color = TempScreenThemeScript.TEAL_ACCENT_COLOR.lightened(0.26)
	_status_value_label.add_theme_color_override("font_color", status_color)
	if _launcher_chip_panel != null:
		var chip_color: Color = status_color if status_semantic != "empty" else TempScreenThemeScript.PANEL_BORDER_COLOR
		_launcher_chip_panel.add_theme_stylebox_override("panel", _build_launcher_chip_style(chip_color))


func _on_toggle_requested() -> void:
	if _before_toggle_handler.is_valid():
		_before_toggle_handler.call()
	toggle()


func _ensure_launcher_children(button: Button) -> void:
	if button == null:
		return
	var chip_panel: PanelContainer = button.get_node_or_null("LauncherChip") as PanelContainer
	if chip_panel == null:
		chip_panel = PanelContainer.new()
		chip_panel.name = "LauncherChip"
		chip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(chip_panel)
	var chip_label: Label = chip_panel.get_node_or_null("LauncherChipLabel") as Label
	if chip_label == null:
		chip_label = Label.new()
		chip_label.name = "LauncherChipLabel"
		chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip_panel.add_child(chip_label)
	var hint_label: Label = button.get_node_or_null("LauncherHintLabel") as Label
	if hint_label == null:
		hint_label = Label.new()
		hint_label.name = "LauncherHintLabel"
		hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		hint_label.clip_text = true
		button.add_child(hint_label)
	var unread_dot: PanelContainer = button.get_node_or_null("LauncherUnreadDot") as PanelContainer
	if unread_dot == null:
		unread_dot = PanelContainer.new()
		unread_dot.name = "LauncherUnreadDot"
		unread_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(unread_dot)

	_launcher_chip_panel = chip_panel
	_launcher_chip_label = chip_label
	_launcher_hint_label = hint_label
	_launcher_unread_dot = unread_dot
	_layout_launcher_children()


func _layout_launcher_children() -> void:
	if _launcher_button == null:
		return
	var button_size: Vector2 = _launcher_button.custom_minimum_size if _launcher_button.custom_minimum_size != Vector2.ZERO else Vector2(136.0, 60.0)
	if _launcher_chip_panel != null:
		_launcher_chip_panel.anchor_left = 1.0
		_launcher_chip_panel.anchor_right = 1.0
		_launcher_chip_panel.anchor_top = 0.0
		_launcher_chip_panel.anchor_bottom = 0.0
		_launcher_chip_panel.offset_left = -74.0
		_launcher_chip_panel.offset_top = 6.0
		_launcher_chip_panel.offset_right = -8.0
		_launcher_chip_panel.offset_bottom = 28.0
	if _launcher_chip_label != null:
		_launcher_chip_label.anchor_left = 0.0
		_launcher_chip_label.anchor_right = 1.0
		_launcher_chip_label.anchor_top = 0.0
		_launcher_chip_label.anchor_bottom = 1.0
		_launcher_chip_label.offset_left = 8.0
		_launcher_chip_label.offset_top = 2.0
		_launcher_chip_label.offset_right = -8.0
		_launcher_chip_label.offset_bottom = -2.0
	if _launcher_hint_label != null:
		_launcher_hint_label.anchor_left = 0.0
		_launcher_hint_label.anchor_right = 1.0
		_launcher_hint_label.anchor_top = 1.0
		_launcher_hint_label.anchor_bottom = 1.0
		_launcher_hint_label.offset_left = 12.0
		_launcher_hint_label.offset_top = -20.0
		_launcher_hint_label.offset_right = -12.0
		_launcher_hint_label.offset_bottom = -6.0
	if _launcher_unread_dot != null:
		_launcher_unread_dot.anchor_left = 0.0
		_launcher_unread_dot.anchor_right = 0.0
		_launcher_unread_dot.anchor_top = 0.0
		_launcher_unread_dot.anchor_bottom = 0.0
		_launcher_unread_dot.offset_left = 8.0
		_launcher_unread_dot.offset_top = 8.0
		_launcher_unread_dot.offset_right = 20.0
		_launcher_unread_dot.offset_bottom = 20.0
	if _toast_label != null:
		_toast_label.anchor_left = 0.0
		_toast_label.anchor_right = 1.0
		_toast_label.anchor_top = 0.0
		_toast_label.anchor_bottom = 1.0
		_toast_label.offset_left = 12.0
		_toast_label.offset_top = 10.0
		_toast_label.offset_right = -12.0
		_toast_label.offset_bottom = -10.0


func _update_launcher_surface(model: Dictionary) -> void:
	if _launcher_button == null:
		return
	var has_active_contract: bool = bool(model.get("has_active_contract", false))
	var launcher_chip_text: String = String(model.get("launcher_chip_text", "")).strip_edges()
	var launcher_hint_text: String = String(model.get("launcher_hint_text", "")).strip_edges()
	_launcher_button.text = "Quest"
	if _launcher_chip_panel != null:
		_launcher_chip_panel.visible = has_active_contract and not launcher_chip_text.is_empty()
	if _launcher_chip_label != null:
		_launcher_chip_label.text = launcher_chip_text
	if _launcher_hint_label != null:
		_launcher_hint_label.text = launcher_hint_text
		_launcher_hint_label.visible = has_active_contract and not launcher_hint_text.is_empty()


func _sync_unread_dot() -> void:
	if _launcher_unread_dot != null:
		_launcher_unread_dot.visible = _has_unread_update


func _build_model_signature(model: Dictionary) -> String:
	return JSON.stringify({
		"has_active_contract": bool(model.get("has_active_contract", false)),
		"status_semantic": String(model.get("status_semantic", "")),
		"mission_title_text": String(model.get("mission_title_text", "")),
		"objective_text": String(model.get("objective_text", "")),
		"launcher_hint_text": String(model.get("launcher_hint_text", "")),
	})


func _build_launcher_tooltip(model: Dictionary) -> String:
	var has_active_contract: bool = bool(model.get("has_active_contract", false))
	if not has_active_contract:
		return "Quest Log"
	var launcher_hint_text: String = String(model.get("launcher_hint_text", "")).strip_edges()
	if launcher_hint_text.is_empty():
		return "Quest Log"
	return "Quest Log\n%s" % launcher_hint_text


func _show_toast(toast_text: String) -> void:
	if _toast_panel == null or _toast_label == null:
		return
	var safe_toast_text: String = toast_text.strip_edges()
	if safe_toast_text.is_empty():
		return
	_toast_cycle_token += 1
	var local_token: int = _toast_cycle_token
	_toast_label.text = safe_toast_text
	_toast_panel.visible = true
	_toast_panel.modulate = Color(1, 1, 1, 0)
	refresh_layout()
	if _root == null or not _root.is_inside_tree():
		_toast_panel.modulate = Color(1, 1, 1, 1)
		return
	var tween: Tween = _root.create_tween()
	tween.tween_property(_toast_panel, "modulate", Color(1, 1, 1, 1), 0.12)
	tween.finished.connect(Callable(self, "_on_toast_fade_in_finished").bind(local_token), CONNECT_ONE_SHOT)


func _hide_toast() -> void:
	_toast_cycle_token += 1
	if _toast_panel != null:
		_toast_panel.visible = false
		_toast_panel.modulate = Color(1, 1, 1, 0)
	if _toast_label != null:
		_toast_label.text = ""


func _on_toast_fade_in_finished(local_token: int) -> void:
	if local_token != _toast_cycle_token or _root == null:
		return
	var tween: Tween = _root.create_tween()
	tween.tween_interval(TOAST_HIDE_DELAY_SECONDS)
	tween.tween_property(_toast_panel, "modulate", Color(1, 1, 1, 0), 0.18)
	tween.finished.connect(Callable(self, "_on_toast_fade_out_finished").bind(local_token), CONNECT_ONE_SHOT)


func _on_toast_fade_out_finished(local_token: int) -> void:
	if local_token != _toast_cycle_token:
		return
	if _toast_panel != null:
		_toast_panel.visible = false
	if _toast_label != null:
		_toast_label.text = ""


func _build_launcher_chip_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.14)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.54)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_right = 999
	style.corner_radius_bottom_left = 999
	style.content_margin_left = 6
	style.content_margin_top = 2
	style.content_margin_right = 6
	style.content_margin_bottom = 2
	return style


func _build_unread_dot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TempScreenThemeScript.RUST_ACCENT_COLOR
	style.border_color = Color(1.0, 0.96, 0.90, 0.72)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_right = 999
	style.corner_radius_bottom_left = 999
	return style
