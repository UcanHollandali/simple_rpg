# Layer: Tests
extends SceneTree
class_name TestInventoryPanelLayout

const InventoryPanelLayoutScript = preload("res://Game/UI/inventory_panel_layout.gd")
const InventoryCardFactoryScript = preload("res://Game/UI/inventory_card_factory.gd")
const RunInventoryPanelScript = preload("res://Game/UI/run_inventory_panel.gd")


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	test_inventory_panel_layout_keeps_density_constants_stable()
	test_inventory_panel_layout_applies_shared_card_density_overrides()
	test_run_inventory_panel_rebuilds_cards_when_render_mode_changes()
	print("test_inventory_panel_layout: all assertions passed")
	quit()


func test_inventory_panel_layout_keeps_density_constants_stable() -> void:
	assert(
		InventoryPanelLayoutScript.card_density_band_for_viewport_height(1200.0) == InventoryPanelLayoutScript.BAND_VERY_COMPACT,
		"Expected very short viewports to stay in the shared very-compact inventory density band."
	)
	assert(
		InventoryPanelLayoutScript.card_density_band_for_viewport_height(1500.0) == InventoryPanelLayoutScript.BAND_COMPACT,
		"Expected mid-height viewports to stay in the shared compact inventory density band."
	)
	assert(
		InventoryPanelLayoutScript.card_density_band_for_viewport_height(1800.0) == InventoryPanelLayoutScript.BAND_STANDARD,
		"Expected taller viewports to stay in the shared standard inventory density band."
	)
	assert(
		InventoryPanelLayoutScript.map_section_separation(InventoryPanelLayoutScript.BAND_VERY_COMPACT) == 1,
		"Expected map inventory sections to keep the tighter very-compact separation."
	)
	assert(
		InventoryPanelLayoutScript.combat_section_separation(InventoryPanelLayoutScript.BAND_STANDARD) == 4,
		"Expected combat quick-item sections to keep the current roomy standard separation."
	)
	assert(
		InventoryPanelLayoutScript.card_flow_separation(InventoryPanelLayoutScript.BAND_COMPACT) == 6,
		"Expected shared inventory card rows to keep the compact separation value."
	)
	assert(
		is_equal_approx(InventoryPanelLayoutScript.panel_height("equipment", InventoryPanelLayoutScript.BAND_STANDARD), 136.0),
		"Expected equipment panels to keep the standard portrait minimum height."
	)
	assert(
		is_equal_approx(InventoryPanelLayoutScript.panel_height("backpack", InventoryPanelLayoutScript.BAND_COMPACT), 114.0),
		"Expected backpack panels to keep the compact portrait minimum height."
	)
	assert(
		InventoryPanelLayoutScript.map_hint_max_lines(InventoryPanelLayoutScript.BAND_COMPACT) == 2,
		"Expected map inventory hints to keep the compact two-line accessibility cap."
	)
	assert(
		InventoryPanelLayoutScript.combat_hint_max_lines(InventoryPanelLayoutScript.BAND_COMPACT) == 1,
		"Expected combat quick-item hints to keep the compact one-line accessibility cap."
	)


func test_inventory_panel_layout_applies_shared_card_density_overrides() -> void:
	var container := HBoxContainer.new()
	get_root().add_child(container)
	var card_models: Array[Dictionary] = [{
		"card_name": "InventorySlotRIGHTHANDCard",
		"slot_label": "RIGHT HAND",
		"count_text": "11/20",
		"title_text": "Iron Sword",
		"detail_text": "EQUIPPED | 6 DMG",
		"action_hint_text": "Tap to unequip",
		"icon_texture_path": "",
		"is_clickable": true,
		"is_selected": false,
		"is_equipped": true,
		"is_draggable": false,
	}]
	InventoryCardFactoryScript.rebuild_cards(container, card_models)
	InventoryPanelLayoutScript.apply_card_density_overrides(container, InventoryPanelLayoutScript.BAND_VERY_COMPACT)
	var card: PanelContainer = container.get_child(0) as PanelContainer
	assert(card != null, "Expected one inventory card for shared density override coverage.")
	assert(
		card.custom_minimum_size == Vector2(102.0, 116.0),
		"Expected shared very-compact density overrides to keep the narrowed inventory card footprint."
	)
	var slot_label: Label = card.get_node_or_null(InventoryPanelLayoutScript.SLOT_LABEL_PATH) as Label
	var icon_rect: TextureRect = card.get_node_or_null(InventoryPanelLayoutScript.ICON_RECT_PATH) as TextureRect
	var title_label: Label = card.get_node_or_null(InventoryPanelLayoutScript.TITLE_LABEL_PATH) as Label
	var action_hint_label: Label = card.get_node_or_null(InventoryPanelLayoutScript.ACTION_HINT_LABEL_PATH) as Label
	assert(slot_label != null and slot_label.get_theme_font_size("font_size") == 11, "Expected the shared override to keep the very-compact slot-label font size.")
	assert(icon_rect != null and icon_rect.custom_minimum_size == Vector2(34.0, 34.0), "Expected the shared override to keep the very-compact inventory icon size.")
	assert(title_label != null and title_label.get_theme_font_size("font_size") == 14, "Expected the shared override to keep the very-compact card title font size.")
	assert(action_hint_label != null and action_hint_label.get_theme_font_size("font_size") == 10, "Expected the shared override to keep the very-compact action-hint font size.")
	container.queue_free()


func test_run_inventory_panel_rebuilds_cards_when_render_mode_changes() -> void:
	var owner := Control.new()
	var equipment_container := HBoxContainer.new()
	var backpack_container := HBoxContainer.new()
	owner.add_child(equipment_container)
	owner.add_child(backpack_container)
	get_root().add_child(owner)

	var panel: RunInventoryPanel = RunInventoryPanelScript.new()
	panel.configure(owner, {
		"equipment_container": equipment_container,
		"backpack_container": backpack_container,
	})

	panel.render(_build_run_inventory_panel_model("map"))
	var standard_card: PanelContainer = equipment_container.get_child(0) as PanelContainer
	var standard_vbox: VBoxContainer = standard_card.get_node_or_null("VBox") as VBoxContainer
	assert(standard_card != null and not standard_card.clip_contents, "Expected default map density to keep the full card shell unclipped.")
	assert(standard_vbox != null and standard_vbox.get_theme_constant("separation") == 4, "Expected default map density to keep the roomy card stack spacing.")

	panel.render(_build_run_inventory_panel_model("combat_compact"))
	var compact_density_card: PanelContainer = equipment_container.get_child(0) as PanelContainer
	var compact_density_vbox: VBoxContainer = compact_density_card.get_node_or_null("VBox") as VBoxContainer
	assert(compact_density_card != null and compact_density_card.clip_contents, "Expected combat-compact density changes to force a card rebuild instead of leaving the old map shell live.")
	assert(compact_density_vbox != null and compact_density_vbox.get_theme_constant("separation") == 3, "Expected combat-compact density changes to rebuild the shared card layout with the compact spacing profile.")

	panel.render(_build_run_inventory_panel_model("map", true))
	var compact_override_card: PanelContainer = equipment_container.get_child(0) as PanelContainer
	var compact_override_vbox: VBoxContainer = compact_override_card.get_node_or_null("VBox") as VBoxContainer
	assert(compact_override_card != null and compact_override_card.clip_contents, "Expected compact-mode overrides to rebuild the card shell even when the slot payload is otherwise identical.")
	assert(compact_override_vbox != null and compact_override_vbox.get_theme_constant("separation") == 1, "Expected compact-mode overrides to rebuild the shared card layout with the tight override spacing.")

	owner.queue_free()


func _build_run_inventory_panel_model(layout_density: String, compact_mode_override: bool = false) -> Dictionary:
	return {
		"show_equipment": true,
		"show_backpack": false,
		"layout_density": layout_density,
		"card_compact_mode_override": compact_mode_override,
		"clickable_resolver": func(_card_model: Dictionary) -> bool:
			return true,
		"selected_resolver": func(_card_model: Dictionary) -> bool:
			return false,
		"draggable_resolver": func(_card_model: Dictionary) -> bool:
			return false,
		"equipment_cards": [{
			"card_name": "InventorySlotRIGHTHANDCard",
			"card_family": "weapon",
			"slot_label": "RIGHT HAND",
			"slot_index": -1,
			"inventory_slot_index": -1,
			"inventory_slot_id": 101,
			"title_text": "Iron Sword",
			"detail_text": "DMG 6",
			"count_text": "11/20",
			"icon_texture_path": "",
			"tooltip_text": "Weapon tooltip",
			"accent_color": Color(0.82, 0.46, 0.32, 1.0),
			"is_equipped": true,
		}],
		"backpack_cards": [],
	}
