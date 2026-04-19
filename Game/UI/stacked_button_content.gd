# Layer: UI
extends RefCounted
class_name StackedButtonContent


static func ensure(button: Button) -> void:
	if button == null:
		return
	button.text = ""
	button.clip_contents = true

	var content_margin: MarginContainer = button.get_node_or_null("ContentMargin") as MarginContainer
	if content_margin == null:
		content_margin = MarginContainer.new()
		content_margin.name = "ContentMargin"
		content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		button.add_child(content_margin)

	var content_row: HBoxContainer = content_margin.get_node_or_null("ContentRow") as HBoxContainer
	if content_row == null:
		content_row = HBoxContainer.new()
		content_row.name = "ContentRow"
		content_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content_row.alignment = BoxContainer.ALIGNMENT_BEGIN
		content_row.add_theme_constant_override("separation", 12)
		content_margin.add_child(content_row)

	var icon_rect: TextureRect = content_row.get_node_or_null("IconTexture") as TextureRect
	if icon_rect == null:
		icon_rect = TextureRect.new()
		icon_rect.name = "IconTexture"
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.visible = false
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(22, 22)
		content_row.add_child(icon_rect)

	var content_vbox: VBoxContainer = content_row.get_node_or_null("ContentVBox") as VBoxContainer
	if content_vbox == null:
		content_vbox = VBoxContainer.new()
		content_vbox.name = "ContentVBox"
		content_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		content_vbox.add_theme_constant_override("separation", 4)
		content_row.add_child(content_vbox)

	var title_label: Label = content_vbox.get_node_or_null("TitleLabel") as Label
	if title_label == null:
		title_label = Label.new()
		title_label.name = "TitleLabel"
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content_vbox.add_child(title_label)

	var detail_label: Label = content_vbox.get_node_or_null("DetailLabel") as Label
	if detail_label == null:
		detail_label = Label.new()
		detail_label.name = "DetailLabel"
		detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content_vbox.add_child(detail_label)


static func apply(
	button: Button,
	title_text: String,
	detail_text: String,
	icon_texture: Texture2D = null
) -> void:
	if button == null:
		return
	ensure(button)

	var title_label: Label = button.get_node_or_null("ContentMargin/ContentRow/ContentVBox/TitleLabel") as Label
	if title_label != null:
		title_label.text = title_text
		title_label.visible = not String(title_text).strip_edges().is_empty()

	var detail_label: Label = button.get_node_or_null("ContentMargin/ContentRow/ContentVBox/DetailLabel") as Label
	if detail_label != null:
		detail_label.text = detail_text
		detail_label.visible = not String(detail_text).strip_edges().is_empty()

	var icon_rect: TextureRect = button.get_node_or_null("ContentMargin/ContentRow/IconTexture") as TextureRect
	if icon_rect != null:
		icon_rect.texture = icon_texture
		icon_rect.visible = icon_texture != null


static func title_path(button_path: String) -> String:
	return "%s/ContentMargin/ContentRow/ContentVBox/TitleLabel" % button_path


static func detail_path(button_path: String) -> String:
	return "%s/ContentMargin/ContentRow/ContentVBox/DetailLabel" % button_path


static func icon_path(button_path: String) -> String:
	return "%s/ContentMargin/ContentRow/IconTexture" % button_path
