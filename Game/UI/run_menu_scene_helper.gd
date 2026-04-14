# Layer: UI helper
extends RefCounted
class_name RunMenuSceneHelper

const SafeMenuOverlayScript = preload("res://Game/UI/safe_menu_overlay.gd")


static func ensure_safe_menu(owner: Node, existing_menu: SafeMenuOverlay, title_text: String, subtitle_text: String, launcher_text: String, save_handler: Callable, load_handler: Callable) -> SafeMenuOverlay:
	if existing_menu != null or owner == null:
		return existing_menu

	var safe_menu: SafeMenuOverlay = SafeMenuOverlayScript.new()
	safe_menu.name = "SafeMenuOverlay"
	safe_menu.configure(title_text, subtitle_text, launcher_text)
	owner.add_child(safe_menu)
	if save_handler.is_valid() and not safe_menu.is_connected("save_requested", save_handler):
		safe_menu.save_requested.connect(save_handler)
	if load_handler.is_valid() and not safe_menu.is_connected("load_requested", load_handler):
		safe_menu.load_requested.connect(load_handler)
	return safe_menu


static func sync_load_available(menu: SafeMenuOverlay, bootstrap) -> void:
	if menu == null:
		return
	menu.set_load_available(bootstrap != null and bootstrap.has_save_game())


static func build_save_status_text(save_result: Dictionary) -> String:
	if bool(save_result.get("ok", false)):
		return "Run saved."
	return "Save failed: %s" % String(save_result.get("error", "unknown"))


static func build_load_failure_status_text(load_result: Dictionary) -> String:
	return "Load failed: %s" % String(load_result.get("error", "unknown"))
