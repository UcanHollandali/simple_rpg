# Layer: Tests
extends SceneTree
class_name TestRunStatusStrip

const RunStatusStripScript = preload("res://Game/UI/run_status_strip.gd")

var _threshold_events: Array[Dictionary] = []


func _init() -> void:
	test_hunger_threshold_crossed_emits_once_per_threshold_entry()
	test_minimal_density_renders_inline_metric_row()
	print("test_run_status_strip: all assertions passed")
	quit()


func test_hunger_threshold_crossed_emits_once_per_threshold_entry() -> void:
	var strip: RunStatusStrip = RunStatusStripScript.new()
	strip.hunger_threshold_crossed.connect(Callable(self, "_on_hunger_threshold_crossed"))

	strip.render_into_with_hunger_signal(null, null, _build_status_model(7))
	assert(_threshold_events.is_empty(), "Expected the first hunger render to prime the threshold tracker without emitting a warning.")

	strip.render_into_with_hunger_signal(null, null, _build_status_model(6))
	strip.render_into_with_hunger_signal(null, null, _build_status_model(5))
	strip.render_into_with_hunger_signal(null, null, _build_status_model(2))
	strip.render_into_with_hunger_signal(null, null, _build_status_model(0))
	strip.render_into_with_hunger_signal(null, null, _build_status_model(3))

	assert(_threshold_events.size() == 3, "Expected warnings only when entering hungry, starving, and starvation thresholds.")
	assert(_threshold_events[0] == {"old": 7, "new": 6}, "Expected the first threshold crossing to announce entry into Hungry.")
	assert(_threshold_events[1] == {"old": 6, "new": 2}, "Expected the second threshold crossing to announce entry into Starving.")
	assert(_threshold_events[2] == {"old": 2, "new": 0}, "Expected the final threshold crossing to announce starvation damage.")
	assert(
		RunStatusStripScript.build_hunger_threshold_warning_text(RunStatusStripScript.HUNGER_THRESHOLD_HUNGRY) == "Hungry - attack power -1",
		"Expected the hungry warning copy to stay centralized in the status-strip helper."
	)
	assert(
		RunStatusStripScript.build_hunger_threshold_warning_text(RunStatusStripScript.HUNGER_THRESHOLD_STARVING) == "Starving - attack power -2",
		"Expected the starving warning copy to stay centralized in the status-strip helper."
	)


func _build_status_model(hunger_value: int) -> Dictionary:
	return {
		"primary_items": [
			{
				"key": "hunger",
				"label_text": "Hunger",
				"value_text": "%d/20" % hunger_value,
				"semantic": "hunger",
				"current_value": hunger_value,
				"max_value": 20,
			},
		],
	}


func test_minimal_density_renders_inline_metric_row() -> void:
	var card := PanelContainer.new()
	var fallback_label := Label.new()
	card.add_child(fallback_label)

	RunStatusStripScript.render_into(card, fallback_label, {
		"density": "minimal",
		"primary_items": [
			{
				"key": "hp",
				"label_text": "HP",
				"value_text": "60/60",
				"semantic": "health",
			},
		],
	})

	var inline_row: HBoxContainer = card.get_node_or_null("RunStatusRoot/PrimaryFlow/hpChip/MetricInlineRow") as HBoxContainer
	var label: Label = card.get_node_or_null("RunStatusRoot/PrimaryFlow/hpChip/MetricInlineRow/MetricLabel") as Label
	var value_label: Label = card.get_node_or_null("RunStatusRoot/PrimaryFlow/hpChip/MetricInlineRow/MetricValueLabel") as Label
	assert(inline_row != null, "Expected minimal density status chips to render label and value on a single inline row.")
	assert(label != null and label.text == "HP", "Expected minimal density status chip label to stay readable inline.")
	assert(value_label != null and value_label.text == "60/60", "Expected minimal density status chip value to stay readable inline.")
	assert(value_label.get_theme_font_size("font_size") == 18, "Expected minimal density status chip value to use the larger inline number size.")


func _on_hunger_threshold_crossed(old_threshold: int, new_threshold: int) -> void:
	_threshold_events.append({
		"old": old_threshold,
		"new": new_threshold,
	})
