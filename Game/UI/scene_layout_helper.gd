# Layer: UI
extends RefCounted
class_name SceneLayoutHelper

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")

static var _texture_cache: Dictionary = {}


static func bind_viewport_size_changed(scene: Control, handler: Callable) -> void:
	var viewport: Viewport = scene.get_viewport()
	if viewport == null:
		return
	if not viewport.is_connected("size_changed", handler):
		viewport.connect("size_changed", handler)


static func unbind_viewport_size_changed(scene: Control, handler: Callable) -> void:
	var viewport: Viewport = scene.get_viewport()
	if viewport == null:
		return
	if viewport.is_connected("size_changed", handler):
		viewport.disconnect("size_changed", handler)


static func apply_portrait_layout(scene: Control, config: Dictionary) -> Dictionary:
	var margin: MarginContainer = scene.get_node_or_null(String(config.get("margin_path", "Margin"))) as MarginContainer
	if margin == null:
		return {}

	var viewport_size: Vector2 = scene.get_viewport_rect().size
	var is_portrait: bool = viewport_size.y >= viewport_size.x
	var top_margin: int = int(config.get("top_margin", 0))
	var bottom_margin: int = int(config.get("bottom_margin", 0))
	for step_variant in config.get("margin_steps", []):
		if not (step_variant is Dictionary):
			continue
		var step: Dictionary = step_variant
		var max_height: float = float(step.get("max_height", -1.0))
		if max_height >= 0.0 and viewport_size.y < max_height:
			top_margin = int(step.get("top_margin", top_margin))
			bottom_margin = int(step.get("bottom_margin", bottom_margin))

	var landscape_margins: Dictionary = config.get("landscape_margins", {})
	if not is_portrait and not landscape_margins.is_empty():
		top_margin = int(landscape_margins.get("top_margin", top_margin))
		bottom_margin = int(landscape_margins.get("bottom_margin", bottom_margin))

	var safe_width: int = TempScreenThemeScript.apply_portrait_safe_margins(
		margin,
		int(config.get("max_width", 960)),
		int(config.get("min_side_margin", 28)),
		top_margin,
		bottom_margin
	)
	var bands: Dictionary = config.get("bands", {})
	var layout_band: String = "compact"
	if _matches_band(viewport_size, safe_width, bands.get("large", {})):
		layout_band = "large"
	elif _matches_band(viewport_size, safe_width, bands.get("medium", {})):
		layout_band = "medium"

	var result: Dictionary = {
		"safe_width": safe_width,
		"layout_band": layout_band,
		"viewport_size": viewport_size,
		"is_portrait": is_portrait,
	}
	var band_values: Dictionary = bands.get(layout_band, {})
	for key_variant in band_values.keys():
		var key: String = String(key_variant)
		if key.begins_with("min_") or key.begins_with("max_"):
			continue
		result[key] = band_values[key_variant]
	return result


static func load_texture_or_null(asset_path: String) -> Texture2D:
	if asset_path.is_empty():
		return null
	if _texture_cache.has(asset_path):
		return _texture_cache[asset_path] as Texture2D

	var texture: Texture2D = load(asset_path) as Texture2D
	if texture != null:
		_texture_cache[asset_path] = texture
	return texture


static func apply_label_tones(scene: Control, specs: Array[Dictionary]) -> void:
	for spec in specs:
		for node in _resolve_nodes(scene, spec):
			var label: Label = node as Label
			if label != null:
				TempScreenThemeScript.apply_label(label, String(spec.get("tone", "body")))


static func apply_control_overrides(scene: Control, values: Dictionary, specs: Array[Dictionary]) -> void:
	for spec in specs:
		for node in _resolve_nodes(scene, spec):
			var control: Control = node as Control
			if control != null:
				if spec.has("font_size"):
					control.add_theme_font_size_override("font_size", int(_resolve_value(values, spec.get("font_size"))))
				for key_variant in spec.get("theme_constants", {}).keys():
					var key: StringName = StringName(String(key_variant))
					control.add_theme_constant_override(key, int(_resolve_value(values, spec.get("theme_constants", {}).get(key_variant))))
				if spec.has("custom_minimum_size"):
					var size: Dictionary = spec.get("custom_minimum_size", {})
					control.custom_minimum_size = Vector2(
						float(_resolve_value(values, size.get("x", control.custom_minimum_size.x))),
						float(_resolve_value(values, size.get("y", control.custom_minimum_size.y)))
					)
				if spec.has("size_flags_horizontal"):
					control.size_flags_horizontal = int(_resolve_value(values, spec.get("size_flags_horizontal")))
				if spec.has("size_flags_vertical"):
					control.size_flags_vertical = int(_resolve_value(values, spec.get("size_flags_vertical")))
			var label: Label = node as Label
			if label != null:
				if spec.has("horizontal_alignment"):
					label.horizontal_alignment = int(_resolve_value(values, spec.get("horizontal_alignment")))
				if spec.has("max_lines_visible"):
					label.max_lines_visible = int(_resolve_value(values, spec.get("max_lines_visible")))
				if spec.has("autowrap_mode"):
					label.autowrap_mode = int(_resolve_value(values, spec.get("autowrap_mode")))
			var button: Button = node as Button
			if button != null and spec.has("alignment"):
				button.alignment = int(_resolve_value(values, spec.get("alignment")))
			var canvas_item: CanvasItem = node as CanvasItem
			if canvas_item != null and spec.has("visible"):
				canvas_item.visible = bool(_resolve_value(values, spec.get("visible")))


static func _matches_band(viewport_size: Vector2, safe_width: int, band_config: Variant) -> bool:
	if not (band_config is Dictionary):
		return false
	var config: Dictionary = band_config
	return safe_width >= float(config.get("min_width", 0.0)) and viewport_size.y >= float(config.get("min_height", 0.0))


static func _resolve_nodes(scene: Control, spec: Dictionary) -> Array[Node]:
	if spec.has("paths"):
		var nodes: Array[Node] = []
		for path_variant in spec.get("paths", []):
			var node: Node = scene.get_node_or_null(String(path_variant))
			if node != null:
				nodes.append(node)
		return nodes
	var single: Node = scene.get_node_or_null(String(spec.get("path", "")))
	var single_node: Array[Node] = []
	if single != null:
		single_node.append(single)
	return single_node


static func _resolve_value(values: Dictionary, value: Variant) -> Variant:
	if value is String and values.has(value):
		return values[value]
	return value
