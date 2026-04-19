# Layer: UI
extends RefCounted
class_name CombatSceneShell

const COMBAT_ACTION_HINT_PANEL_PATH := "Margin/VBox/Buttons/ActionHintPanel"
const ACTION_HINT_LABEL_PATH := "ActionHintVBox/ActionContextLabel"
const COMBAT_FEEDBACK_LAYER_NAME := "CombatFeedbackLayer"
const IMPACT_FLASH_NODE_NAME := "ImpactFlash"
const FEEDBACK_TEXT_LAYER_NAME := "FeedbackTextLayer"

const FEEDBACK_CARD_PATHS := [
	"Margin/VBox/BattleCardsRow/EnemyCard",
	"Margin/VBox/BattleCardsRow/PlayerCard",
]


static func ensure_feedback_shells(scene_node_getter: Callable) -> void:
	for card_path in FEEDBACK_CARD_PATHS:
		var card: PanelContainer = scene_node_getter.call(card_path) as PanelContainer
		if card == null:
			continue

		var feedback_layer: Control = card.get_node_or_null(COMBAT_FEEDBACK_LAYER_NAME) as Control
		if feedback_layer == null:
			feedback_layer = Control.new()
			feedback_layer.name = COMBAT_FEEDBACK_LAYER_NAME
			feedback_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			feedback_layer.clip_contents = false
			card.add_child(feedback_layer)
		feedback_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		feedback_layer.z_index = 4

		var flash: ColorRect = feedback_layer.get_node_or_null(IMPACT_FLASH_NODE_NAME) as ColorRect
		if flash == null:
			flash = ColorRect.new()
			flash.name = IMPACT_FLASH_NODE_NAME
			flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			feedback_layer.add_child(flash)
		flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		flash.color = Color(1, 1, 1, 0)
		flash.z_index = 0

		var text_layer: Control = feedback_layer.get_node_or_null(FEEDBACK_TEXT_LAYER_NAME) as Control
		if text_layer == null:
			text_layer = Control.new()
			text_layer.name = FEEDBACK_TEXT_LAYER_NAME
			text_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_layer.clip_contents = false
			feedback_layer.add_child(text_layer)
		text_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		text_layer.z_index = 1


static func ensure_action_hint_controls(
	scene_node_getter: Callable,
	existing_panel: PanelContainer = null,
	existing_label: Label = null
) -> Dictionary:
	var action_hint_panel: PanelContainer = existing_panel
	if action_hint_panel == null or not is_instance_valid(action_hint_panel):
		action_hint_panel = scene_node_getter.call(COMBAT_ACTION_HINT_PANEL_PATH) as PanelContainer
	if action_hint_panel == null:
		return {}

	var action_hint_box: VBoxContainer = action_hint_panel.get_node_or_null("ActionHintVBox") as VBoxContainer
	if action_hint_box == null:
		action_hint_box = VBoxContainer.new()
		action_hint_box.name = "ActionHintVBox"
		action_hint_panel.add_child(action_hint_box)

	var action_hint_label: Label = existing_label
	if action_hint_label == null or not is_instance_valid(action_hint_label):
		action_hint_label = action_hint_panel.get_node_or_null(ACTION_HINT_LABEL_PATH) as Label
	if action_hint_label == null:
		action_hint_label = Label.new()
		action_hint_label.name = "ActionContextLabel"
		action_hint_box.add_child(action_hint_label)

	action_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_hint_panel.top_level = true
	action_hint_panel.z_index = 120
	action_hint_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action_hint_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action_hint_panel.custom_minimum_size = Vector2.ZERO
	action_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_hint_label.clip_text = false
	action_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_hint_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_hint_label.visible = true
	action_hint_label.text = ""
	action_hint_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return {
		"panel": action_hint_panel,
		"label": action_hint_label,
	}
