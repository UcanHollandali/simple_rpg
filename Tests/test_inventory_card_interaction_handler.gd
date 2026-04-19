# Layer: Tests
extends SceneTree
class_name TestInventoryCardInteractionHandler

const InventoryCardInteractionHandlerScript = preload("res://Game/UI/inventory_card_interaction_handler.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await test_rebuild_cards_binds_click_and_hover_interactions()
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

	cards[0].emit_signal("mouse_entered")
	cards[0].emit_signal("gui_input", _mouse_button_event(Vector2(6, 6), true))
	cards[0].emit_signal("gui_input", _mouse_button_event(Vector2(6, 6), false))
	cards[0].emit_signal("mouse_exited")
	await process_frame

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


func _build_card_model(slot_index: int, slot_id: int, family: String) -> Dictionary:
	return {
		"card_name": "InventorySlot%dCard" % (slot_index + 1),
		"card_family": family,
		"slot_index": slot_index,
		"inventory_slot_index": slot_index,
		"inventory_slot_id": slot_id,
		"slot_label": "INV %d" % (slot_index + 1),
		"title_text": "Card %d" % (slot_index + 1),
		"detail_text": "Test detail",
		"count_text": "",
		"tooltip_text": "Tooltip",
		"accent_color": Color(0.84, 0.62, 0.28, 1.0),
		"is_clickable": true,
		"is_draggable": true,
	}


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
