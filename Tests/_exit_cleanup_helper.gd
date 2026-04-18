# Layer: Tests helper
extends RefCounted
class_name TestExitCleanupHelper

const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")


static func cleanup_and_quit(tree: SceneTree, exit_code: int = 0) -> void:
	if tree == null:
		return

	var root_window: Window = tree.get_root()
	var active_scene: Node = tree.current_scene
	await tree.process_frame
	await tree.create_timer(0.12).timeout
	if root_window != null:
		SceneAudioCleanupScript.release_all_audio_players(root_window)
		if active_scene != null and is_instance_valid(active_scene):
			tree.current_scene = null
		var children_to_free: Array[Node] = []
		for child in root_window.get_children():
			var child_node: Node = child as Node
			if child_node == null or not is_instance_valid(child_node):
				continue
			children_to_free.append(child_node)
		for child_node in children_to_free:
			if not is_instance_valid(child_node):
				continue
			if child_node.get_parent() == root_window:
				root_window.remove_child(child_node)
			child_node.free()

	await tree.process_frame
	await tree.process_frame
	await tree.process_frame

	if root_window != null:
		SceneAudioCleanupScript.release_all_audio_players(root_window)

	await tree.create_timer(0.2).timeout
	tree.quit(exit_code)
