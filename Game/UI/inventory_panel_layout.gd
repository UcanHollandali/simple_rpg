# Layer: UI
extends RefCounted
class_name InventoryPanelLayout

const BAND_STANDARD := "standard"
const BAND_COMPACT := "compact"
const BAND_VERY_COMPACT := "very_compact"

const MAP_SECTION_COMPACT_HEIGHT_THRESHOLD := 1540.0
const CARD_COMPACT_HEIGHT_THRESHOLD := 1560.0
const VERY_COMPACT_HEIGHT_THRESHOLD := 1360.0

const SLOT_LABEL_PATH := "VBox/HeaderRow/SlotLabel"
const COUNT_LABEL_PATH := "VBox/HeaderRow/CountLabel"
const ICON_RECT_PATH := "VBox/IconRect"
const PLACEHOLDER_LABEL_PATH := "VBox/PlaceholderLabel"
const TITLE_LABEL_PATH := "VBox/TitleLabel"
const DETAIL_LABEL_PATH := "VBox/DetailLabel"
const ACTION_HINT_LABEL_PATH := "VBox/ActionHintLabel"

const CARD_METRICS_BY_BAND := {
	BAND_VERY_COMPACT: {
		"card_size": Vector2(102.0, 116.0),
		"slot_font_size": 11,
		"count_font_size": 12,
		"icon_size": Vector2(34.0, 34.0),
		"placeholder_font_size": 20,
		"title_font_size": 14,
		"detail_font_size": 11,
		"action_hint_font_size": 10,
	},
	BAND_COMPACT: {
		"card_size": Vector2(112.0, 126.0),
		"slot_font_size": 12,
		"count_font_size": 13,
		"icon_size": Vector2(38.0, 38.0),
		"placeholder_font_size": 22,
		"title_font_size": 15,
		"detail_font_size": 12,
		"action_hint_font_size": 11,
	},
	BAND_STANDARD: {
		"card_size": Vector2(126.0, 142.0),
		"slot_font_size": 12,
		"count_font_size": 13,
		"icon_size": Vector2(42.0, 42.0),
		"placeholder_font_size": 24,
		"title_font_size": 16,
		"detail_font_size": 13,
		"action_hint_font_size": 12,
	},
}
const PANEL_HEIGHTS_BY_KIND := {
	"equipment": {
		BAND_VERY_COMPACT: 104.0,
		BAND_COMPACT: 116.0,
		BAND_STANDARD: 136.0,
	},
	"backpack": {
		BAND_VERY_COMPACT: 102.0,
		BAND_COMPACT: 114.0,
		BAND_STANDARD: 138.0,
	},
}
const CARD_FLOW_SEPARATION_BY_BAND := {
	BAND_VERY_COMPACT: 4,
	BAND_COMPACT: 6,
	BAND_STANDARD: 8,
}
const MAP_SECTION_SEPARATION_BY_BAND := {
	BAND_VERY_COMPACT: 1,
	BAND_COMPACT: 3,
	BAND_STANDARD: 3,
}
const COMBAT_SECTION_SEPARATION_BY_BAND := {
	BAND_VERY_COMPACT: 1,
	BAND_COMPACT: 3,
	BAND_STANDARD: 4,
}
const MAP_HINT_MAX_LINES_BY_BAND := {
	BAND_VERY_COMPACT: 1,
	BAND_COMPACT: 2,
	BAND_STANDARD: 2,
}
const COMBAT_HINT_MAX_LINES_BY_BAND := {
	BAND_VERY_COMPACT: 1,
	BAND_COMPACT: 1,
	BAND_STANDARD: 2,
}


static func card_density_band_for_viewport_height(viewport_height: float) -> String:
	if viewport_height < VERY_COMPACT_HEIGHT_THRESHOLD:
		return BAND_VERY_COMPACT
	if viewport_height < CARD_COMPACT_HEIGHT_THRESHOLD:
		return BAND_COMPACT
	return BAND_STANDARD


static func density_band_from_flags(compact_layout: bool, very_compact_layout: bool) -> String:
	if very_compact_layout:
		return BAND_VERY_COMPACT
	if compact_layout:
		return BAND_COMPACT
	return BAND_STANDARD


static func panel_height(panel_kind: String, density_band: String) -> float:
	var panel_heights: Dictionary = PANEL_HEIGHTS_BY_KIND.get(panel_kind, {})
	return float(panel_heights.get(density_band, panel_heights.get(BAND_STANDARD, 0.0)))


static func card_flow_separation(density_band: String) -> int:
	return int(CARD_FLOW_SEPARATION_BY_BAND.get(density_band, CARD_FLOW_SEPARATION_BY_BAND.get(BAND_STANDARD, 8)))


static func map_section_separation(density_band: String) -> int:
	return int(MAP_SECTION_SEPARATION_BY_BAND.get(density_band, MAP_SECTION_SEPARATION_BY_BAND.get(BAND_STANDARD, 3)))


static func combat_section_separation(density_band: String) -> int:
	return int(COMBAT_SECTION_SEPARATION_BY_BAND.get(density_band, COMBAT_SECTION_SEPARATION_BY_BAND.get(BAND_STANDARD, 4)))


static func map_hint_max_lines(density_band: String) -> int:
	return int(MAP_HINT_MAX_LINES_BY_BAND.get(density_band, MAP_HINT_MAX_LINES_BY_BAND.get(BAND_STANDARD, 2)))


static func combat_hint_max_lines(density_band: String) -> int:
	return int(COMBAT_HINT_MAX_LINES_BY_BAND.get(density_band, COMBAT_HINT_MAX_LINES_BY_BAND.get(BAND_STANDARD, 2)))


static func apply_card_density_overrides(container: Container, density_band: String) -> void:
	if container == null:
		return
	var metrics: Dictionary = CARD_METRICS_BY_BAND.get(density_band, CARD_METRICS_BY_BAND[BAND_STANDARD])
	for child in container.get_children():
		var card: PanelContainer = child as PanelContainer
		if card == null:
			continue
		card.custom_minimum_size = metrics.get("card_size", CARD_METRICS_BY_BAND[BAND_STANDARD]["card_size"])
		_set_label_font_size(card.get_node_or_null(SLOT_LABEL_PATH) as Label, int(metrics.get("slot_font_size", 12)))
		_set_label_font_size(card.get_node_or_null(COUNT_LABEL_PATH) as Label, int(metrics.get("count_font_size", 13)))
		var icon_rect: TextureRect = card.get_node_or_null(ICON_RECT_PATH) as TextureRect
		if icon_rect != null:
			icon_rect.custom_minimum_size = metrics.get("icon_size", CARD_METRICS_BY_BAND[BAND_STANDARD]["icon_size"])
		_set_label_font_size(card.get_node_or_null(PLACEHOLDER_LABEL_PATH) as Label, int(metrics.get("placeholder_font_size", 24)))
		_set_label_font_size(card.get_node_or_null(TITLE_LABEL_PATH) as Label, int(metrics.get("title_font_size", 16)))
		_set_label_font_size(card.get_node_or_null(DETAIL_LABEL_PATH) as Label, int(metrics.get("detail_font_size", 13)))
		_set_label_font_size(card.get_node_or_null(ACTION_HINT_LABEL_PATH) as Label, int(metrics.get("action_hint_font_size", 12)))


static func _set_label_font_size(label: Label, font_size: int) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
