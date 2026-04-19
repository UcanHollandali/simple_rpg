# Layer: Tests
extends SceneTree
class_name TestInventoryCardInteractionHandler

const InventoryCardInteractionHandlerScript = preload("res://Game/UI/inventory_card_interaction_handler.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await test_rebuild_cards_binds_click_and_hover_interactions()
	await test_empty_and_filled_cards_keep_matching_minimum_width()
	await test_emphasis_states_keep_matching_minimum_height()
	test_global_release_mode_tracks_drag_state_and_card_targets()
	print("test_inventory_card_interaction_handler: all assertions passed")
	quit()


func test_rebuild_cards_binds_click_and_hover_interactions() -> void:
	var root := Control.new()
	get_root().add_child(root)
	var container := HBoxContainer.new()
	root.add_child(container)

	var click_calls: Array[Dictionary] = []
	var hover_calls: Array[String] = []
	var exit_calls: Array[String] = []
	var handler: InventoryCardInteractionHandler = InventoryCardInteractionHandlerScript.new()
	handler.configure(root, {
		"click_handler": func(slot_index: int, slot_id: int, family: String) -> void:
			click_calls.append({
				"slot_index": slot_index,
				"slot_id": slot_id,
				"family": family,
			}),
		"mouse_entered_handler": func(card: Control, _accent: Color) -> void:
			hover_calls.append(card.name),
		"mouse_exited_handler": func(card: Control) -> void:
			exit_calls.append(card.name),
	})

	var cards: Array[PanelContainer] = handler.rebuild_cards(container, [_build_card_model(0, 11, "weapon")])
	assert(cards.size() == 1, "Expected the shared handler to rebuild one inventory card.")
	assert(cards[0].mouse_filter == Control.MOUSE_FILTER_STOP, "Expected rebuilt inventory cards to accept shared pointer input.")
	var action_hint_label: Label = cards[0].get_node_or_null("VBox/ActionHintLabel") as Label
	assert(action_hint_label != null and action_hint_label.visible, "Expected rebuilt inventory cards to keep an action-hint label.")
	var action_hint_font_size: int = action_hint_label.get_theme_font_size("font_size")

	cards[0].emit_signal("mouse_entered")
	assert(action_hint_label.get_theme_font_size("font_size") == action_hint_font_size, "Expected inventory hover styling to preserve action-hint font size.")
	cards[0].emit_signal("gui_input", _mouse_button_event(Vector2(6, 6), true))
	cards[0].emit_signal("gui_input", _mouse_button_event(Vector2(6, 6), false))
	cards[0].emit_signal("mouse_exited")
	await process_frame
	assert(action_hint_label.get_theme_font_size("font_size") == action_hint_font_size, "Expected inventory hover exit to preserve action-hint font size.")

	assert(hover_calls == ["InventorySlot1Card"], "Expected the shared handler to preserve mouse-entered wiring for card tooltips.")
	assert(exit_calls == ["InventorySlot1Card"], "Expected the shared handler to preserve mouse-exited wiring for card tooltips.")
	assert(click_calls.size() == 1, "Expected the shared handler to dispatch one click callback on press/release.")
	assert(int(click_calls[0].get("slot_id", -1)) == 11, "Expected the shared click callback to preserve inventory slot ids.")
	assert(String(click_calls[0].get("family", "")) == "weapon", "Expected the shared click callback to preserve card families.")

	root.queue_free()


func test_global_release_mode_tracks_drag_state_and_card_targets() -> void:
	var root := Control.new()
	get_root().add_child(root)
	var container := HBoxContainer.new()
	root.add_child(container)

	var drag_started_tokens: Array[String] = []
	var handler: InventoryCardInteractionHandler = InventoryCardInteractionHandlerScript.new()
	handler.configure(root, {
		"drag_started_handler": func() -> void:
			drag_started_tokens.append("started"),
		"release_on_global_mouse_up": true,
		"drag_threshold": 14.0,
	})

	var cards: Array[PanelContainer] = handler.rebuild_cards(container, [
		_build_card_model(0, 21, "weapon"),
		_build_card_model(1, 22, "consumable"),
	])
	assert(cards.size() == 2, "Expected the shared handler to rebuild multiple inventory cards.")

	handler.call("_on_card_gui_input", _mouse_button_event(Vector2(4, 4), true), cards[0])
	handler.handle_root_input(_mouse_motion_event(Vector2(32, 32)))

	assert(drag_started_tokens.size() == 1, "Expected root-level motion to trigger one shared drag-start callback after crossing the threshold.")
	assert(bool(cards[0].get_meta("is_dragging", false)), "Expected the shared handler to toggle shared dragging visuals through InventoryCardFactory.")

	var title_label: Control = cards[1].get_node("VBox/TitleLabel") as Control
	assert(handler.call("_find_inventory_card_from_control", title_label) == cards[1], "Expected shared drag targeting to resolve inventory cards from child controls.")

	handler.stop_interaction()
	assert(not bool(cards[0].get_meta("is_dragging", false)), "Expected stop_interaction() to clear the shared dragging visual state.")

	root.queue_free()


func test_empty_and_filled_cards_keep_matching_minimum_width() -> void:
	var root := Control.new()
	get_root().add_child(root)
	var container := HBoxContainer.new()
	root.add_child(container)

	var handler: InventoryCardInteractionHandler = InventoryCardInteractionHandlerScript.new()
	handler.configure(root, {})

	var cards: Array[PanelContainer] = handler.rebuild_cards(container, [
		_build_card_model(0, 31, "weapon", {
			"slot_label": "RIGHT HAND",
			"title_text": "Iron Sword",
			"detail_text": "EQUIPPED | DMG 6",
			"action_hint_text": "Tap to unequip",
			"count_text": "20/20",
		}),
		_build_card_model(1, -1, "empty", {
			"slot_label": "LEFT HAND",
			"title_text": "Open Slot",
			"detail_text": "Equip shield or offhand.",
			"action_hint_text": "",
			"count_text": "",
			"is_clickable": false,
			"is_draggable": false,
			"is_equipped": false,
		}),
	])
	assert(cards.size() == 2, "Expected width-comparison coverage to rebuild two inventory cards.")
	await process_frame

	var filled_width: float = cards[0].get_combined_minimum_size().x
	var empty_width: float = cards[1].get_combined_minimum_size().x
	assert(is_equal_approx(filled_width, empty_width), "Expected filled and empty inventory cards to keep the same minimum width. Got %.2f vs %.2f." % [filled_width, empty_width])

	root.queue_free()


func test_emphasis_states_keep_matching_minimum_height() -> void:
	var root := Control.new()
	get_root().add_child(root)
	var container := HBoxContainer.new()
	root.add_child(container)

	var handler: InventoryCardInteractionHandler = InventoryCardInteractionHandlerScript.new()
	handler.configure(root, {})

	var cards: Array[PanelContainer] = handler.rebuild_cards(container, [
		_build_card_model(0, 31, "weapon", {
			"slot_label": "RIGHT HAND",
			"title_text": "Iron Sword",
			"detail_text": "DMG 6",
			"action_hint_text": "Tap to equip",
			"count_text": "20/20",
			"is_equipped": false,
			"is_selected": false,
		}),
		_build_card_model(1, 32, "weapon", {
			"slot_label": "RIGHT HAND",
			"title_text": "Iron Sword",
			"detail_text": "DMG 6",
			"action_hint_text": "Tap to equip",
			"count_text": "20/20",
			"is_equipped": true,
			"is_selected": true,
		}),
	])
	assert(cards.size() == 2, "Expected emphasis-height coverage to rebuild two inventory cards.")
	await process_frame

	var base_height: float = cards[0].get_combined_minimum_size().y
	var emphasized_height: float = cards[1].get_combined_minimum_size().y
	assert(is_equal_approx(base_height, emphasized_height), "Expected emphasis states not to change inventory card minimum height. Got %.2f vs %.2f." % [base_height, emphasized_height])

	root.queue_free()


func _build_card_model(slot_index: int, slot_id: int, family: String, overrides: Dictionary = {}) -> Dictionary:
	var card_model: Dictionary = {
		"card_name": "InventorySlot%dCard" % (slot_index + 1),
		"card_family": family,
		"slot_index": slot_index,
		"inventory_slot_index": slot_index,
		"inventory_slot_id": slot_id,
		"slot_label": "INV %d" % (slot_index + 1),
		"title_text": "Card %d" % (slot_index + 1),
		"detail_text": "Test detail",
		"action_hint_text": "Tap to unequip",
		"count_text": "",
		"tooltip_text": "Tooltip",
		"accent_color": Color(0.84, 0.62, 0.28, 1.0),
		"is_clickable": true,
		"is_draggable": true,
		"is_equipped": true,
	}
	for key in overrides.keys():
		card_model[key] = overrides[key]
	return card_model


func _mouse_button_event(position: Vector2, is_pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = is_pressed
	event.position = position
	return event


func _mouse_motion_event(position: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = position
	return event
