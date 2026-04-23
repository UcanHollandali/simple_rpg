# Layer: Tests
extends SceneTree
class_name TestMapQuestLogUi

const MapExplorePresenterScript = preload("res://Game/UI/map_explore_presenter.gd")
const MapExploreSceneScript = preload("res://scenes/map_explore.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	test_map_presenter_builds_quest_log_model()
	test_map_scene_toggles_quest_log_panel()
	await test_opening_settings_closes_quest_log_panel()
	await test_quest_log_toggle_closes_map_safe_menu()
	test_map_scene_hides_settings_launcher_while_quest_log_is_open()
	test_quest_log_layout_stays_top_right()
	print("test_map_quest_log_ui: all assertions passed")
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func test_map_presenter_builds_quest_log_model() -> void:
	var presenter: RefCounted = MapExplorePresenterScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	var empty_model: Dictionary = presenter.call("build_quest_log_model", run_state)
	assert(
		not bool(empty_model.get("has_active_contract", true)),
		"Expected the quest-log model to stay empty before a hamlet request is accepted."
	)
	assert(
		String(empty_model.get("mission_title_text", "")) == "No active contract",
		"Expected the empty quest-log state to explain that no active contract is currently being tracked."
	)
	assert(String(empty_model.get("launcher_chip_text", "")) == "", "Expected the empty quest-log launcher chip to stay hidden.")
	assert(String(empty_model.get("launcher_hint_text", "")) == "", "Expected the empty quest-log launcher hint to stay hidden.")

	var hamlet_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "hamlet")
	var target_node_id: int = _find_node_id_by_family(run_state.map_runtime_state, "reward")
	assert(hamlet_node_id >= 0, "Expected one hamlet node for quest-log presenter coverage.")
	assert(target_node_id >= 0, "Expected one non-hamlet route target for quest-log presenter coverage.")
	run_state.map_runtime_state.save_side_mission_node_runtime_state(hamlet_node_id, {
		"support_type": "hamlet",
		"mission_definition_id": "deliver_supplies",
		"mission_type": "deliver_supplies",
		"mission_status": "accepted",
		"target_node_id": target_node_id,
		"quest_item_definition_id": "supply_bundle",
		"reward_offers": [],
	})
	var accepted_model: Dictionary = presenter.call("build_quest_log_model", run_state)
	assert(
		bool(accepted_model.get("has_active_contract", false)),
		"Expected the quest-log model to activate once a hamlet contract is accepted."
	)
	assert(
		String(accepted_model.get("status_text", "")) == "ACTIVE",
		"Expected the accepted quest-log state to expose an active contract chip."
	)
	assert(
		String(accepted_model.get("mission_title_text", "")) == "Deliver Supplies",
		"Expected the quest-log model to resolve the authored side-mission title."
	)
	assert(
		String(accepted_model.get("objective_text", "")).contains("Node %d" % target_node_id),
		"Expected the quest-log model to surface the marked target node in the objective read."
	)
	assert(
		String(accepted_model.get("hint_text", "")).contains("highlighted"),
		"Expected the accepted quest-log state to remind the player that the marked route is already visible on the board."
	)
	assert(String(accepted_model.get("launcher_chip_text", "")) == "ACTIVE", "Expected the accepted quest-log launcher chip to mirror the active contract state.")
	assert(String(accepted_model.get("launcher_hint_text", "")) == "Target known", "Expected the accepted quest-log launcher to expose a light target-known hint.")
	assert(String(accepted_model.get("toast_text", "")) == "Contract tracked. Marked target known.", "Expected the accepted quest-log model to supply a compact update toast message.")

	run_state.map_runtime_state.save_side_mission_node_runtime_state(hamlet_node_id, {
		"support_type": "hamlet",
		"mission_definition_id": "deliver_supplies",
		"mission_type": "deliver_supplies",
		"mission_status": "completed",
		"target_node_id": target_node_id,
		"quest_item_definition_id": "supply_bundle",
		"reward_offers": [
			{"offer_id": "claim_hunter_stew", "inventory_family": "consumable", "definition_id": "hunter_stew"},
			{"offer_id": "claim_provisioner_belt", "inventory_family": "belt", "definition_id": "provisioner_belt"},
		],
	})
	var completed_model: Dictionary = presenter.call("build_quest_log_model", run_state)
	assert(
		String(completed_model.get("status_text", "")) == "READY",
		"Expected the completed quest-log state to switch to a ready-to-claim read."
	)
	assert(
		String(completed_model.get("objective_text", "")).contains("Waypost"),
		"Expected the completed quest-log state to redirect the player back to the hamlet source node."
	)
	assert(
		String(completed_model.get("hint_text", "")).contains("1 of 2 rewards"),
		"Expected the completed quest-log state to explain the pending hamlet payout count."
	)
	assert(String(completed_model.get("launcher_chip_text", "")) == "READY", "Expected the completed quest-log launcher chip to switch into a ready-to-turn-in read.")
	assert(String(completed_model.get("launcher_hint_text", "")) == "Return to Waypost", "Expected the completed quest-log launcher to point back to the hamlet source without auto-routing.")
	assert(String(completed_model.get("toast_text", "")) == "Contract ready. Return to the Waypost.", "Expected the completed quest-log model to supply a compact ready-to-turn-in toast message.")


func test_map_scene_toggles_quest_log_panel() -> void:
	var map_scene: Control = MapExploreSceneScript.new()
	assert(map_scene != null, "Expected map scene instance for quest-log launcher coverage.")
	var quest_log_panel: RefCounted = load("res://Game/UI/map_quest_log_panel.gd").new()
	map_scene.set("_quest_log_panel", quest_log_panel)
	quest_log_panel.call("configure", map_scene)
	var launcher_button: Button = map_scene.get_node_or_null("QuestLogLauncherButton") as Button
	assert(launcher_button != null, "Expected MapExplore to expose the quest-log launcher button.")
	var panel: PanelContainer = map_scene.get_node_or_null("QuestLogPanel") as PanelContainer
	assert(panel != null, "Expected MapExplore to create the quest-log panel shell.")
	var launcher_chip: PanelContainer = launcher_button.get_node_or_null("LauncherChip") as PanelContainer
	var launcher_chip_label: Label = launcher_button.get_node_or_null("LauncherChip/LauncherChipLabel") as Label
	var launcher_hint_label: Label = launcher_button.get_node_or_null("LauncherHintLabel") as Label
	var unread_dot: PanelContainer = launcher_button.get_node_or_null("LauncherUnreadDot") as PanelContainer
	var toast_panel: PanelContainer = map_scene.get_node_or_null("QuestLogUpdateToast") as PanelContainer
	var toast_label: Label = map_scene.get_node_or_null("QuestLogUpdateToast/ToastLabel") as Label
	assert(launcher_chip != null and launcher_chip_label != null, "Expected the quest launcher to expose a compact state chip surface.")
	assert(launcher_hint_label != null, "Expected the quest launcher to expose a compact hint label surface.")
	assert(unread_dot != null, "Expected the quest launcher to expose a session-local unread dot surface.")
	assert(toast_panel != null and toast_label != null, "Expected MapExplore to create a compact quest update toast surface.")
	assert(not panel.visible, "Expected the quest-log panel to start hidden until the launcher is pressed.")
	assert(not launcher_chip.visible, "Expected the quest launcher chip to stay hidden with no active contract.")
	assert(not launcher_hint_label.visible, "Expected the quest launcher hint to stay hidden with no active contract.")
	assert(not unread_dot.visible, "Expected the quest launcher unread dot to stay hidden before any update lands.")
	assert(not toast_panel.visible, "Expected the quest update toast to stay hidden before any update lands.")

	quest_log_panel.call("apply_model", {
		"has_active_contract": true,
		"status_semantic": "accepted",
		"status_text": "ACTIVE",
		"mission_title_text": "Deliver Supplies",
		"summary_text": "Carry the bundle and keep moving.",
		"objective_title_text": "Objective",
		"objective_text": "Carry the bundle to Cache (Node 5).",
		"detail_text": "",
		"hint_text": "The marked route is already highlighted on the board.",
		"launcher_chip_text": "ACTIVE",
		"launcher_hint_text": "Target known",
		"toast_text": "Contract tracked. Marked target known.",
	})
	assert(launcher_chip.visible, "Expected the quest launcher chip to show once a contract is active.")
	assert(String(launcher_chip_label.text) == "ACTIVE", "Expected the quest launcher chip to mirror the active quest state.")
	assert(launcher_hint_label.visible and String(launcher_hint_label.text) == "Target known", "Expected the quest launcher to show the light target-known hint when the target is already known.")
	assert(unread_dot.visible, "Expected a new session-local quest update to light the unread dot while the panel stays closed.")
	assert(toast_panel.visible and String(toast_label.text) == "Contract tracked. Marked target known.", "Expected a new session-local quest update to open a compact toast.")

	launcher_button.emit_signal("pressed")
	assert(panel.visible, "Expected pressing the quest-log launcher to open the quest-log panel.")
	assert(not unread_dot.visible, "Expected opening the quest-log panel to clear the session-local unread dot.")
	quest_log_panel.call("apply_model", {
		"has_active_contract": true,
		"status_semantic": "completed",
		"status_text": "READY",
		"mission_title_text": "Deliver Supplies",
		"summary_text": "The contract is ready to settle.",
		"objective_title_text": "Objective",
		"objective_text": "Return to Waypost (Node 4).",
		"detail_text": "",
		"hint_text": "Return to the Waypost to claim 1 of 2 rewards.",
		"launcher_chip_text": "READY",
		"launcher_hint_text": "Return to Waypost",
		"toast_text": "Contract ready. Return to the Waypost.",
	})
	assert(String(launcher_chip_label.text) == "READY", "Expected the quest launcher chip to switch to READY once the contract is ready to turn in.")
	assert(String(launcher_hint_label.text) == "Return to Waypost", "Expected the quest launcher hint to pivot into return-to-hamlet guidance without auto-routing.")
	assert(not unread_dot.visible, "Expected applying a quest update while the panel is already open not to re-arm the unread dot.")
	launcher_button.emit_signal("pressed")
	assert(not panel.visible, "Expected pressing the quest-log launcher again to close the quest-log panel.")


func test_opening_settings_closes_quest_log_panel() -> void:
	var host: Control = Control.new()
	host.size = Vector2(1080.0, 1920.0)
	get_root().add_child(host)

	var map_scene: Control = MapExploreSceneScript.new()
	var safe_menu: SafeMenuOverlay = load("res://Game/UI/safe_menu_overlay.gd").new()
	host.add_child(safe_menu)
	await process_frame
	await process_frame

	map_scene.set("_safe_menu", safe_menu)
	var quest_log_panel: RefCounted = load("res://Game/UI/map_quest_log_panel.gd").new()
	map_scene.set("_quest_log_panel", quest_log_panel)
	quest_log_panel.call("configure", host, Callable(map_scene, "_before_quest_log_toggle"))
	var launcher_button: Button = host.get_node_or_null("QuestLogLauncherButton") as Button
	var panel: PanelContainer = host.get_node_or_null("QuestLogPanel") as PanelContainer
	assert(launcher_button != null and panel != null, "Expected a quest-log launcher and panel for the map settings mutual-exclusion regression test.")

	launcher_button.emit_signal("pressed")
	assert(panel.visible, "Expected the quest-log panel to open before the settings-open regression step.")

	map_scene.call("_open_safe_menu")
	await process_frame

	assert(not panel.visible, "Expected opening the map settings surface to close the quest-log panel first.")

	host.queue_free()
	await process_frame


func test_quest_log_toggle_closes_map_safe_menu() -> void:
	var host: Control = Control.new()
	host.size = Vector2(1080.0, 1920.0)
	get_root().add_child(host)

	var map_scene: Control = MapExploreSceneScript.new()
	var safe_menu: SafeMenuOverlay = load("res://Game/UI/safe_menu_overlay.gd").new()
	host.add_child(safe_menu)
	await process_frame
	await process_frame

	map_scene.set("_safe_menu", safe_menu)
	var quest_log_panel: RefCounted = load("res://Game/UI/map_quest_log_panel.gd").new()
	quest_log_panel.call("configure", host, Callable(map_scene, "_before_quest_log_toggle"))
	var launcher_button: Button = host.get_node_or_null("QuestLogLauncherButton") as Button
	var panel: PanelContainer = host.get_node_or_null("QuestLogPanel") as PanelContainer
	assert(launcher_button != null and panel != null, "Expected a quest-log launcher and panel for the mutual-exclusion regression test.")

	safe_menu.open_menu()
	assert(safe_menu.is_menu_open(), "Expected the shared safe menu to open before the quest-log toggle regression step.")

	launcher_button.emit_signal("pressed")
	await process_frame

	assert(not safe_menu.is_menu_open(), "Expected quest-log toggles to close the map safe menu before opening the quest panel.")
	assert(panel.visible, "Expected the quest-log panel to finish opening after it closes the map safe menu.")

	host.queue_free()
	await process_frame


func test_map_scene_hides_settings_launcher_while_quest_log_is_open() -> void:
	var map_scene: Control = MapExploreSceneScript.new()
	var margin: MarginContainer = MarginContainer.new()
	margin.name = "Margin"
	map_scene.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)

	var top_row: Control = Control.new()
	top_row.name = "TopRow"
	vbox.add_child(top_row)

	var settings_anchor: Control = Control.new()
	settings_anchor.name = "SettingsMenuAnchor"
	top_row.add_child(settings_anchor)

	var settings_button: Button = Button.new()
	settings_button.name = "SettingsButton"
	settings_anchor.add_child(settings_button)

	var quest_log_panel: RefCounted = load("res://Game/UI/map_quest_log_panel.gd").new()
	map_scene.set("_quest_log_panel", quest_log_panel)
	quest_log_panel.call("configure", map_scene, Callable(map_scene, "_before_quest_log_toggle"))

	map_scene.call("_sync_safe_menu_launcher_visibility")
	assert(settings_button.visible, "Expected the settings launcher to stay available while the quest log is closed.")
	assert(settings_button.mouse_filter == Control.MOUSE_FILTER_STOP, "Expected the settings launcher to stay interactive while the quest log is closed.")

	var launcher_button: Button = map_scene.get_node_or_null("QuestLogLauncherButton") as Button
	assert(launcher_button != null, "Expected the quest-log launcher for the map mutual-exclusion visibility test.")
	launcher_button.emit_signal("pressed")
	map_scene.call("_sync_safe_menu_launcher_visibility")

	assert(not settings_button.visible, "Expected the settings launcher to hide while the quest-log panel is open.")
	assert(settings_button.focus_mode == Control.FOCUS_NONE, "Expected the settings launcher to drop focusability while the quest-log panel is open.")
	assert(settings_button.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Expected the settings launcher to ignore pointer input while the quest-log panel is open.")

	launcher_button.emit_signal("pressed")
	map_scene.call("_sync_safe_menu_launcher_visibility")
	assert(settings_button.visible, "Expected the settings launcher to return once the quest-log panel closes.")
	assert(settings_button.focus_mode == Control.FOCUS_ALL, "Expected the settings launcher to regain focusability once the quest-log panel closes.")
	assert(settings_button.mouse_filter == Control.MOUSE_FILTER_STOP, "Expected the settings launcher to regain pointer interaction once the quest-log panel closes.")


func test_quest_log_layout_stays_top_right() -> void:
	var root: Control = Control.new()
	root.size = Vector2(1080.0, 1920.0)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "Margin"
	margin.size = root.size
	root.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size = root.size
	margin.add_child(vbox)

	var top_row: Control = Control.new()
	top_row.name = "TopRow"
	top_row.position = Vector2(0.0, 24.0)
	top_row.size = Vector2(1048.0, 96.0)
	vbox.add_child(top_row)

	var quest_log_panel: RefCounted = load("res://Game/UI/map_quest_log_panel.gd").new()
	quest_log_panel.call("configure", root)

	var launcher_button: Button = root.get_node_or_null("QuestLogLauncherButton") as Button
	var panel: PanelContainer = root.get_node_or_null("QuestLogPanel") as PanelContainer
	var toast_panel: PanelContainer = root.get_node_or_null("QuestLogUpdateToast") as PanelContainer
	assert(launcher_button != null and panel != null and toast_panel != null, "Expected the quest-log layout test to create launcher, panel, and toast surfaces.")

	assert(is_equal_approx(launcher_button.offset_top, 130.0), "Expected the quest-log launcher to sit just below the top-row shell in root-local coordinates.")
	assert(is_equal_approx(launcher_button.offset_right, -16.0), "Expected the quest-log launcher to keep the fixed right margin.")
	assert(is_equal_approx(panel.offset_top, launcher_button.offset_bottom + 10.0), "Expected the quest-log panel to stack directly below the launcher button.")
	assert(toast_panel.offset_top >= launcher_button.offset_bottom, "Expected the compact quest update toast to stay in the launcher lane instead of drifting into the board body.")


func _find_node_id_by_family(map_runtime_state: RefCounted, node_family: String) -> int:
	for node_snapshot in map_runtime_state.build_node_snapshots():
		if String(node_snapshot.get("node_family", "")) == node_family:
			return int(node_snapshot.get("node_id", -1))
	return -1
