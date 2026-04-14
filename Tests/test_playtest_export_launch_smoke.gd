# Layer: Tests
extends SceneTree
class_name TestPlaytestExportLaunchSmoke

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const SceneRouterScript = preload("res://Game/Infrastructure/scene_router.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const MAIN_SCENE_TIMEOUT_MS := 4000


func _init() -> void:
	Callable(self, "_run_smoke").call_deferred()


func _run_smoke() -> void:
	_ensure_runtime_bootstrap_nodes()
	change_scene_to_file(MAIN_SCENE_PATH)

	var main_scene: Node = await _wait_for_scene(MAIN_SCENE_PATH, MAIN_SCENE_TIMEOUT_MS)
	if main_scene == null:
		_fail("PLAYTEST_EXPORT_LAUNCH_SMOKE: failed_before_main_scene")
		return

	print("PLAYTEST_EXPORT_LAUNCH_SMOKE: main_scene_ready")
	await _cleanup_before_quit()
	quit()


func _ensure_runtime_bootstrap_nodes() -> void:
	var root_window: Window = get_root()
	if root_window.get_node_or_null("AppBootstrap") == null:
		var bootstrap: Node = AppBootstrapScript.new()
		bootstrap.name = "AppBootstrap"
		root_window.add_child(bootstrap)

	if root_window.get_node_or_null("SceneRouter") == null:
		var scene_router: Node = SceneRouterScript.new()
		scene_router.name = "SceneRouter"
		root_window.add_child(scene_router)


func _wait_for_scene(scene_path: String, timeout_ms: int) -> Node:
	var deadline_ms: int = Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline_ms:
		var active_scene: Node = current_scene
		if active_scene != null and String(active_scene.scene_file_path) == scene_path:
			return active_scene
		await create_timer(0.05).timeout
	return null


func _cleanup_before_quit() -> void:
	var root_window: Window = get_root()
	SceneAudioCleanupScript.release_all_audio_players(root_window)
	await process_frame
	await process_frame

	var active_scene: Node = current_scene
	if active_scene != null:
		active_scene.queue_free()
		await process_frame
		await process_frame

	for node_name in ["SceneRouter", "AppBootstrap"]:
		var runtime_node: Node = root_window.get_node_or_null(node_name)
		if runtime_node != null:
			runtime_node.queue_free()

	SceneAudioCleanupScript.release_all_audio_players(root_window)
	await process_frame
	await process_frame
	await create_timer(0.5).timeout


func _fail(message: String) -> void:
	push_error(message)
	printerr(message)
	quit(1)
