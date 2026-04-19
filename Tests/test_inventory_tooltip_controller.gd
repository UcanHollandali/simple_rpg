# Layer: Tests
extends SceneTree
class_name TestInventoryTooltipController

const InventoryTooltipControllerScript = preload("res://Game/UI/inventory_tooltip_controller.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var overlay_root := Control.new()
	overlay_root.top_level = true
	overlay_root.z_as_relative = false
	overlay_root.z_index = 180
	overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(overlay_root)

	var card := Button.new()
	card.position = Vector2(120, 240)
	card.size = Vector2(220, 72)
	card.set_meta("custom_tooltip_text", "Tooltip front test")
	overlay_root.add_child(card)
	await process_frame

	var controller: InventoryTooltipController = InventoryTooltipControllerScript.new()
	controller.configure(overlay_root)
	controller.on_inventory_card_mouse_entered(card, Color(0.40, 0.80, 0.70, 1.0))

	var tooltip_panel: PanelContainer = overlay_root.get_node_or_null("InventoryTooltipPanel") as PanelContainer
	assert(tooltip_panel != null, "Expected the shared tooltip controller to create its tooltip panel shell.")
	var tooltip_label: Label = tooltip_panel.get_node_or_null("InventoryTooltipLabel") as Label if tooltip_panel != null else null
	assert(tooltip_label != null, "Expected the shared tooltip controller to create its tooltip label.")
	assert(tooltip_panel.visible, "Expected the shared tooltip controller to show the tooltip on hover.")
	assert(tooltip_label.text == "Tooltip front test", "Expected the shared tooltip controller to mirror the custom tooltip text.")
	assert(tooltip_panel.top_level, "Expected the shared tooltip shell to stay top-level for global placement.")
	assert(not tooltip_panel.z_as_relative, "Expected the shared tooltip shell to use absolute z ordering.")
	assert(tooltip_panel.z_index > overlay_root.z_index, "Expected the shared tooltip shell to render in front of overlay owners.")
	assert(tooltip_panel.size.y < 140.0, "Expected the first shared tooltip layout pass not to stretch vertically.")

	controller.on_inventory_card_mouse_exited(card)
	assert(not tooltip_panel.visible, "Expected the shared tooltip controller to hide the tooltip after hover exit.")

	controller.release()
	overlay_root.queue_free()
	print("test_inventory_tooltip_controller: all assertions passed")
	quit()
