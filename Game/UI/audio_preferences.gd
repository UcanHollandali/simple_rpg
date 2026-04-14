# Layer: UI helper
extends RefCounted
class_name AudioPreferences

const MUSIC_BUS_NAME := "Music"

static var _music_enabled: bool = true


static func is_music_enabled() -> bool:
	return _music_enabled


static func toggle_music_enabled() -> bool:
	set_music_enabled(not _music_enabled)
	return _music_enabled


static func set_music_enabled(is_enabled: bool) -> void:
	_music_enabled = is_enabled
	_ensure_music_bus()
	_apply_music_bus_state()


static func prepare_music_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	_ensure_music_bus()
	player.bus = MUSIC_BUS_NAME
	_apply_music_bus_state()


static func _ensure_music_bus() -> void:
	if AudioServer.get_bus_index(MUSIC_BUS_NAME) >= 0:
		return

	AudioServer.add_bus(AudioServer.get_bus_count())
	var bus_index: int = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, MUSIC_BUS_NAME)


static func _apply_music_bus_state() -> void:
	var bus_index: int = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, not _music_enabled)
