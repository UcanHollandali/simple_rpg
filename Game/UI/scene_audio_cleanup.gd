# Layer: UI helper
extends RefCounted
class_name SceneAudioCleanup

const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")


static func release_players(owner: Node, node_paths: Array[String]) -> void:
	if owner == null:
		return

	for node_path in node_paths:
		var player: AudioStreamPlayer = owner.get_node_or_null(node_path) as AudioStreamPlayer
		if player == null:
			continue
		player.stop()
		player.stream = null


static func release_all_audio_players(root: Node) -> void:
	if root == null:
		return

	_release_audio_players_recursive(root)
	SceneAudioPlayersScript.release_shared_music_session(root)


static func release_scene_tree_audio(owner: Node) -> void:
	if owner == null or not owner.is_inside_tree():
		return
	var tree: SceneTree = owner.get_tree()
	if tree == null:
		return
	release_all_audio_players(tree.root)


static func _release_audio_players_recursive(node: Node) -> void:
	if node is AudioStreamPlayer:
		var player: AudioStreamPlayer = node as AudioStreamPlayer
		player.stop()
		player.stream = null

	for child in node.get_children():
		_release_audio_players_recursive(child)
