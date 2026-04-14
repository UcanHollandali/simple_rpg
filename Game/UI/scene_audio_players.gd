# Layer: UI helper
extends RefCounted
class_name SceneAudioPlayers

const AudioPreferencesScript = preload("res://Game/UI/audio_preferences.gd")
const SHARED_MUSIC_PLAYER_NAME := "__SharedMusicPlayer"

static var _shared_music_track_positions: Dictionary = {}


static func assign_stream(owner: Node, node_path: String, stream: AudioStream) -> void:
	var player: AudioStreamPlayer = owner.get_node_or_null(node_path) as AudioStreamPlayer
	if player != null:
		player.stream = stream


static func assign_stream_from_path(owner: Node, node_path: String, resource_path: String) -> void:
	assign_stream(owner, node_path, _load_stream(resource_path))


static func assign_music_stream(owner: Node, node_path: String, stream: AudioStream, should_loop: bool = false) -> void:
	var player: AudioStreamPlayer = owner.get_node_or_null(node_path) as AudioStreamPlayer
	if player == null:
		return
	player.stream = stream
	if should_loop:
		var music_stream: AudioStreamOggVorbis = player.stream as AudioStreamOggVorbis
		if music_stream != null:
			music_stream.loop = true
	AudioPreferencesScript.prepare_music_player(player)


static func assign_music_stream_from_path(owner: Node, node_path: String, resource_path: String, should_loop: bool = false) -> void:
	assign_music_stream(owner, node_path, _load_stream(resource_path), should_loop)


static func play(owner: Node, node_path: String) -> void:
	var player: AudioStreamPlayer = owner.get_node_or_null(node_path) as AudioStreamPlayer
	if player != null and player.stream != null:
		player.play()


static func start_looping(owner: Node, node_path: String) -> void:
	var player: AudioStreamPlayer = owner.get_node_or_null(node_path) as AudioStreamPlayer
	if player == null or player.stream == null:
		return

	var tree: SceneTree = owner.get_tree()
	if tree == null:
		return
	var shared_player: AudioStreamPlayer = get_shared_music_player(tree.root)
	if shared_player == null:
		return

	AudioPreferencesScript.prepare_music_player(shared_player)
	var track_key: String = _resolve_track_key(player.stream)
	var current_track_key: String = String(shared_player.get_meta("music_track_key", ""))
	if current_track_key != track_key:
		_store_shared_music_position(shared_player)
		shared_player.stop()
		shared_player.stream = player.stream
		shared_player.set_meta("music_track_key", track_key)
		shared_player.play(_resume_position_for_track(track_key))
		return

	if shared_player.stream != player.stream:
		shared_player.stream = player.stream
	if not shared_player.playing:
		shared_player.play(_resume_position_for_track(track_key))


static func wait_for_lead_in(owner: Node, node_path: String, lead_in_seconds: float) -> void:
	var player: AudioStreamPlayer = owner.get_node_or_null(node_path) as AudioStreamPlayer
	if player == null or player.stream == null:
		return
	await owner.get_tree().create_timer(lead_in_seconds).timeout


static func _load_stream(resource_path: String) -> AudioStream:
	if resource_path.is_empty():
		return null
	# Scene-local audio players already release their stream references on exit.
	# Reusing the engine cache avoids redundant reload churn when multiple screens
	# bind the same temp-floor audio assets during normal flow traversal.
	var resource: Resource = ResourceLoader.load(resource_path, "", ResourceLoader.CACHE_MODE_REUSE)
	if resource is AudioStream:
		return resource as AudioStream
	return null


static func get_shared_music_player(root: Node) -> AudioStreamPlayer:
	if root == null:
		return null
	var existing_player: AudioStreamPlayer = root.get_node_or_null(SHARED_MUSIC_PLAYER_NAME) as AudioStreamPlayer
	if existing_player != null:
		return existing_player

	var shared_player := AudioStreamPlayer.new()
	shared_player.name = SHARED_MUSIC_PLAYER_NAME
	root.add_child(shared_player)
	AudioPreferencesScript.prepare_music_player(shared_player)
	return shared_player


static func get_shared_music_resource_path(root: Node) -> String:
	if root == null:
		return ""
	var shared_player: AudioStreamPlayer = root.get_node_or_null(SHARED_MUSIC_PLAYER_NAME) as AudioStreamPlayer
	if shared_player == null or shared_player.stream == null:
		return ""
	return String(shared_player.stream.resource_path)


static func release_shared_music_session(root: Node) -> void:
	var shared_player: AudioStreamPlayer = root.get_node_or_null(SHARED_MUSIC_PLAYER_NAME) as AudioStreamPlayer
	if shared_player == null:
		_shared_music_track_positions.clear()
		return
	shared_player.stop()
	shared_player.stream = null
	shared_player.queue_free()
	_shared_music_track_positions.clear()


static func _store_shared_music_position(shared_player: AudioStreamPlayer) -> void:
	if shared_player == null or shared_player.stream == null:
		return
	var track_key: String = String(shared_player.get_meta("music_track_key", ""))
	if track_key.is_empty():
		track_key = _resolve_track_key(shared_player.stream)
	if track_key.is_empty():
		return
	_shared_music_track_positions[track_key] = shared_player.get_playback_position()


static func _resume_position_for_track(track_key: String) -> float:
	if track_key.is_empty():
		return 0.0
	return float(_shared_music_track_positions.get(track_key, 0.0))


static func _resolve_track_key(stream: AudioStream) -> String:
	if stream == null:
		return ""
	if not stream.resource_path.is_empty():
		return stream.resource_path
	return str(stream.get_rid())
