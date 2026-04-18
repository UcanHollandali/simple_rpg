# Layer: Tests
extends SceneTree
class_name TestRunSummaryCleanupHelper

const RunSummaryCleanupHelperScript = preload("res://Game/UI/run_summary_cleanup_helper.gd")


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	test_cleanup_only_removes_orphaned_map_run_summary_cards()
	print("test_run_summary_cleanup_helper: all assertions passed")
	quit()


func test_cleanup_only_removes_orphaned_map_run_summary_cards() -> void:
	var helper: RunSummaryCleanupHelper = RunSummaryCleanupHelperScript.new()
	var root: Window = get_root()
	var active_scene_root := Control.new()
	active_scene_root.name = "CombatRoot"
	root.add_child(active_scene_root)

	var active_scene_card: PanelContainer = _build_map_run_summary_card()
	active_scene_root.add_child(active_scene_card)

	var orphan_scene_root := Control.new()
	orphan_scene_root.name = "OrphanMapRoot"
	root.add_child(orphan_scene_root)

	var orphan_card: PanelContainer = _build_map_run_summary_card()
	orphan_scene_root.add_child(orphan_card)

	var unrelated_card := PanelContainer.new()
	unrelated_card.name = "RunSummaryCard"
	orphan_scene_root.add_child(unrelated_card)

	var cleaned_count: int = helper.cleanup_orphaned_map_run_summary_cards(root, active_scene_root)
	assert(cleaned_count == 1, "Expected cleanup helper to remove only orphaned map run summary cards.")

	await process_frame

	assert(is_instance_valid(active_scene_card), "Expected active-scene run summary cards to remain untouched.")
	assert(not is_instance_valid(orphan_card), "Expected orphaned map run summary cards to be freed.")
	assert(is_instance_valid(unrelated_card), "Expected non-matching RunSummaryCard nodes to remain.")

	if is_instance_valid(unrelated_card):
		unrelated_card.queue_free()
	if is_instance_valid(active_scene_card):
		active_scene_card.queue_free()
	if is_instance_valid(orphan_scene_root):
		orphan_scene_root.queue_free()
	if is_instance_valid(active_scene_root):
		active_scene_root.queue_free()


func _build_map_run_summary_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "RunSummaryCard"
	var stats_stack := VBoxContainer.new()
	stats_stack.name = "StatsStack"
	card.add_child(stats_stack)

	var status_rows := VBoxContainer.new()
	status_rows.name = "StatusRows"
	stats_stack.add_child(status_rows)

	var hp_row := HBoxContainer.new()
	hp_row.name = "HpRow"
	status_rows.add_child(hp_row)
	var hp_label := Label.new()
	hp_label.name = "HpStatusLabel"
	hp_row.add_child(hp_label)

	var hunger_row := HBoxContainer.new()
	hunger_row.name = "HungerRow"
	status_rows.add_child(hunger_row)
	var hunger_label := Label.new()
	hunger_label.name = "HungerStatusLabel"
	hunger_row.add_child(hunger_label)

	var durability_row := HBoxContainer.new()
	durability_row.name = "DurabilityRow"
	status_rows.add_child(durability_row)
	var durability_label := Label.new()
	durability_label.name = "DurabilityStatusLabel"
	durability_row.add_child(durability_label)
	return card
