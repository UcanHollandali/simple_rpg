# Layer: Tests
extends SceneTree
class_name TestOverlayLifecycleHelper

const OverlayLifecycleHelperScript = preload("res://Game/UI/overlay_lifecycle_helper.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	test_open_overlay_creates_and_prepares_popup_controls()
	test_close_overlays_clears_multiple_overlay_keys()
	print("test_overlay_lifecycle_helper: all assertions passed")
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func test_open_overlay_creates_and_prepares_popup_controls() -> void:
	var root := Control.new()
	get_root().add_child(root)

	var prepared_keys: Array[String] = []
	var helper: RefCounted = OverlayLifecycleHelperScript.new()
	helper.configure(root, {
		"overlay_z_index": 190,
		"before_show_handler": func(overlay: Control) -> void:
			prepared_keys.append(overlay.name)
			overlay.set_meta("prepared", true)
	})

	helper.open_overlay("event", _build_overlay_scene(), "EventOverlay", "Event")
	var overlay: Control = helper.get_overlay("event")
	assert(overlay != null, "Expected the shared overlay helper to create an overlay control on open.")
	assert(overlay.get_parent() == root, "Expected the shared overlay helper to parent overlays under the owning scene root.")
	assert(overlay.top_level, "Expected shared overlays to remain top-level popup surfaces.")
	assert(overlay.visible, "Expected shared overlays to become visible immediately when opened.")
	assert(overlay.z_index == 190, "Expected shared overlays to preserve configured popup z-order.")
	assert(bool(overlay.get_meta("prepared", false)), "Expected the shared overlay helper to run the configured before-show hook.")
	assert(prepared_keys == ["EventOverlay"], "Expected the shared overlay helper to prepare the opened overlay exactly once.")

	helper.close_overlay("event", true)
	assert(helper.get_overlay("event") == null, "Expected immediate close to clear the shared overlay state for that key.")

	_free_control_root(root)


func test_close_overlays_clears_multiple_overlay_keys() -> void:
	var root := Control.new()
	get_root().add_child(root)

	var helper: RefCounted = OverlayLifecycleHelperScript.new()
	helper.configure(root)
	var overlay_scene: PackedScene = _build_overlay_scene()
	helper.open_overlay("support", overlay_scene, "SupportOverlay", "Support")
	helper.open_overlay("reward", overlay_scene, "RewardOverlay", "Reward")
	helper.position_overlays(PackedStringArray(["support", "reward"]))

	var support_overlay: Control = helper.get_overlay("support")
	var reward_overlay: Control = helper.get_overlay("reward")
	assert(support_overlay != null and reward_overlay != null, "Expected the shared helper to keep independent overlay instances per key.")
	assert(support_overlay.anchor_right == 1.0 and reward_overlay.anchor_bottom == 1.0, "Expected shared overlay positioning to keep overlays stretched to the full viewport.")

	helper.close_overlays(PackedStringArray(["support", "reward"]), true)
	assert(helper.get_overlay("support") == null, "Expected shared bulk close to clear the support overlay key.")
	assert(helper.get_overlay("reward") == null, "Expected shared bulk close to clear the reward overlay key.")

	_free_control_root(root)


func _build_overlay_scene() -> PackedScene:
	var overlay_root := Control.new()
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	overlay_root.add_child(scrim)
	var scene := PackedScene.new()
	var packed: Error = scene.pack(overlay_root)
	assert(packed == OK, "Expected the test overlay scene to pack cleanly.")
	overlay_root.free()
	return scene


func _free_control_root(root: Control) -> void:
	if root == null:
		return
	var parent: Node = root.get_parent()
	if parent != null:
		parent.remove_child(root)
	root.free()
