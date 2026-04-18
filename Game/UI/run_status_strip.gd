# Layer: UI
extends RefCounted
class_name RunStatusStrip

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")

const ROOT_NODE_NAME := "RunStatusRoot"
const HUNGER_THRESHOLD_SAFE := 7
const HUNGER_THRESHOLD_HUNGRY := 6
const HUNGER_THRESHOLD_STARVING := 2
const HUNGER_THRESHOLD_STARVATION := 0
const UNKNOWN_HUNGER_VALUE := -99999

signal hunger_threshold_crossed(old_threshold: int, new_threshold: int)

var _has_seen_hunger_threshold: bool = false
var _last_hunger_threshold: int = HUNGER_THRESHOLD_SAFE


func render_into_with_hunger_signal(card: PanelContainer, fallback_label: Label, model: Dictionary, accent: Color = TempScreenThemeScript.PANEL_BORDER_COLOR) -> void:
	render_into(card, fallback_label, model, accent)
	_update_hunger_threshold_feedback(model)


static func render_into(card: PanelContainer, fallback_label: Label, model: Dictionary, accent: Color = TempScreenThemeScript.PANEL_BORDER_COLOR) -> void:
	if card == null:
		return

	var primary_items: Array[Dictionary] = _extract_dictionary_array(model.get("primary_items", []))
	var secondary_items: Array[Dictionary] = _extract_dictionary_array(model.get("secondary_items", []))
	var progress_items: Array[Dictionary] = _extract_dictionary_array(model.get("progress_items", []))
	var fallback_text: String = String(model.get("fallback_text", ""))
	var density: String = String(model.get("density", model.get("variant", "compact")))
	var has_structured_content: bool = not primary_items.is_empty() or not secondary_items.is_empty() or not progress_items.is_empty()

	var root: VBoxContainer = _ensure_root(card)
	if not has_structured_content:
		root.visible = false
		if fallback_label != null:
			fallback_label.text = fallback_text
			fallback_label.visible = not fallback_text.is_empty()
		return

	if fallback_label != null:
		fallback_label.text = fallback_text
		fallback_label.visible = false
	root.visible = true
	_clear_children(root)

	var root_spacing: int = 8 if density == "standard" else 6
	root.add_theme_constant_override("separation", root_spacing)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if not primary_items.is_empty():
		var primary_flow: HFlowContainer = HFlowContainer.new()
		primary_flow.name = "PrimaryFlow"
		primary_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		primary_flow.add_theme_constant_override("h_separation", 8 if density == "standard" else 6)
		primary_flow.add_theme_constant_override("v_separation", 8 if density == "standard" else 6)
		root.add_child(primary_flow)
		for item in primary_items:
			primary_flow.add_child(_build_metric_chip(item, accent, density))

	if not secondary_items.is_empty():
		var secondary_flow: HFlowContainer = HFlowContainer.new()
		secondary_flow.name = "SecondaryFlow"
		secondary_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		secondary_flow.add_theme_constant_override("h_separation", 8 if density == "standard" else 6)
		secondary_flow.add_theme_constant_override("v_separation", 8 if density == "standard" else 6)
		root.add_child(secondary_flow)
		for item in secondary_items:
			secondary_flow.add_child(_build_summary_chip(item, accent, density))

	if not progress_items.is_empty():
		var progress_stack: VBoxContainer = VBoxContainer.new()
		progress_stack.name = "ProgressStack"
		progress_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_stack.add_theme_constant_override("separation", 6 if density == "standard" else 4)
		root.add_child(progress_stack)
		for item in progress_items:
			progress_stack.add_child(_build_progress_row(item, accent, density))


static func resolve_hunger_threshold(hunger_value: int) -> int:
	if hunger_value <= HUNGER_THRESHOLD_STARVATION:
		return HUNGER_THRESHOLD_STARVATION
	if hunger_value <= HUNGER_THRESHOLD_STARVING:
		return HUNGER_THRESHOLD_STARVING
	if hunger_value <= HUNGER_THRESHOLD_HUNGRY:
		return HUNGER_THRESHOLD_HUNGRY
	return HUNGER_THRESHOLD_SAFE


static func build_hunger_threshold_warning_text(threshold: int) -> String:
	match threshold:
		HUNGER_THRESHOLD_HUNGRY:
			return "Hungry — saldırı gücün -1"
		HUNGER_THRESHOLD_STARVING:
			return "Starving — saldırı gücün -2"
		HUNGER_THRESHOLD_STARVATION:
			return "Starvation damage!"
		_:
			return ""


static func resolve_hunger_threshold_accent(threshold: int) -> Color:
	match threshold:
		HUNGER_THRESHOLD_HUNGRY:
			return TempScreenThemeScript.REWARD_ACCENT_COLOR
		HUNGER_THRESHOLD_STARVING, HUNGER_THRESHOLD_STARVATION:
			return TempScreenThemeScript.RUST_ACCENT_COLOR
		_:
			return TempScreenThemeScript.PANEL_BORDER_COLOR


func _update_hunger_threshold_feedback(model: Dictionary) -> void:
	var hunger_value: int = _extract_hunger_value(model)
	if hunger_value == UNKNOWN_HUNGER_VALUE:
		return

	var new_threshold: int = resolve_hunger_threshold(hunger_value)
	if not _has_seen_hunger_threshold:
		_has_seen_hunger_threshold = true
		_last_hunger_threshold = new_threshold
		return

	var old_threshold: int = _last_hunger_threshold
	_last_hunger_threshold = new_threshold
	if new_threshold < old_threshold:
		hunger_threshold_crossed.emit(old_threshold, new_threshold)


func _extract_hunger_value(model: Dictionary) -> int:
	var primary_items: Array[Dictionary] = _extract_dictionary_array(model.get("primary_items", []))
	for item in primary_items:
		var item_key: String = String(item.get("key", ""))
		var semantic: String = String(item.get("semantic", ""))
		if item_key != "hunger" and semantic != "hunger":
			continue
		if item.has("current_value"):
			return int(item.get("current_value", 0))
		var metric_value_text: String = String(item.get("value_text", "")).strip_edges()
		if metric_value_text.is_empty():
			return UNKNOWN_HUNGER_VALUE
		var numeric_fragment: String = metric_value_text.split("/", false)[0].strip_edges()
		if numeric_fragment.is_valid_int():
			return int(numeric_fragment)
		return UNKNOWN_HUNGER_VALUE
	return UNKNOWN_HUNGER_VALUE


static func _ensure_root(card: PanelContainer) -> VBoxContainer:
	var root: VBoxContainer = card.get_node_or_null(ROOT_NODE_NAME) as VBoxContainer
	if root != null:
		return root

	root = VBoxContainer.new()
	root.name = ROOT_NODE_NAME
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(root)
	return root


static func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


static func _build_metric_chip(item: Dictionary, fallback_accent: Color, density: String) -> PanelContainer:
	var semantic: String = String(item.get("semantic", ""))
	var accent: Color = TempScreenThemeScript.resolve_status_accent(semantic, fallback_accent)
	var chip: PanelContainer = PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.custom_minimum_size = Vector2(128.0 if density == "standard" else 112.0, 0.0)
	TempScreenThemeScript.apply_status_chip_shell(chip, accent, density)

	var stack: VBoxContainer = VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 2)
	chip.add_child(stack)

	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.text = String(item.get("label_text", ""))
	label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_MUTED_COLOR)
	label.add_theme_font_size_override("font_size", 11 if density == "standard" else 10)
	stack.add_child(label)

	var value_label: Label = Label.new()
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.text = String(item.get("value_text", ""))
	value_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	value_label.add_theme_font_size_override("font_size", 22 if density == "standard" else 18)
	stack.add_child(value_label)
	return chip


static func _build_summary_chip(item: Dictionary, fallback_accent: Color, density: String) -> PanelContainer:
	var semantic: String = String(item.get("semantic", ""))
	var accent: Color = TempScreenThemeScript.resolve_status_accent(semantic, fallback_accent)
	var chip: PanelContainer = PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	TempScreenThemeScript.apply_status_chip_shell(chip, accent, "minimal" if density == "minimal" else "compact")

	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.text = "%s %s" % [
		String(item.get("label_text", "")),
		String(item.get("value_text", "")),
	]
	label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_SUBTLE_COLOR)
	label.add_theme_font_size_override("font_size", 14 if density == "standard" else 13)
	chip.add_child(label)
	return chip


static func _build_progress_row(item: Dictionary, fallback_accent: Color, density: String) -> VBoxContainer:
	var semantic: String = String(item.get("semantic", ""))
	var accent: Color = TempScreenThemeScript.resolve_status_accent(semantic, fallback_accent)
	var row: VBoxContainer = VBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 10)
	row.add_child(header_row)

	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.text = String(item.get("label_text", ""))
	label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_MUTED_COLOR)
	label.add_theme_font_size_override("font_size", 13 if density == "standard" else 12)
	header_row.add_child(label)

	var value_label: Label = Label.new()
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.text = String(item.get("value_text", ""))
	value_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	value_label.add_theme_font_size_override("font_size", 14 if density == "standard" else 13)
	header_row.add_child(value_label)

	var bar: ProgressBar = ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = float(clamp(float(item.get("fill_ratio", 0.0)), 0.0, 1.0)) * 100.0
	bar.custom_minimum_size = Vector2(0.0, 12.0 if density == "standard" else 10.0)
	TempScreenThemeScript.apply_status_progress_bar(bar, accent)
	row.add_child(bar)
	return row


static func _extract_dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry in value:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		result.append(entry)
	return result
