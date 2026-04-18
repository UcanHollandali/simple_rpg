# Layer: Infrastructure
extends RefCounted
class_name PlaytestLogger

const DEFAULT_LOG_PATH := "user://playtest_log.jsonl"

var _enabled: bool = false
var _log_path: String = DEFAULT_LOG_PATH


func setup(enabled: bool, log_path: String = DEFAULT_LOG_PATH) -> void:
	_enabled = enabled
	_log_path = log_path.strip_edges()
	if _log_path.is_empty():
		_log_path = DEFAULT_LOG_PATH


func is_enabled() -> bool:
	return _enabled


func log_event(payload: Dictionary) -> void:
	if not _enabled:
		return

	var record: Dictionary = payload.duplicate(true)
	record["timestamp"] = int(Time.get_unix_time_from_system())

	var file: FileAccess = _open_append_file()
	if file == null:
		push_error("PlaytestLogger failed to open %s." % _log_path)
		return

	file.store_string("%s\n" % JSON.stringify(record))
	file.close()


func get_log_path() -> String:
	return _log_path


func _open_append_file() -> FileAccess:
	if FileAccess.file_exists(_log_path):
		var existing_file: FileAccess = FileAccess.open(_log_path, FileAccess.READ_WRITE)
		if existing_file != null:
			existing_file.seek_end()
		return existing_file
	return FileAccess.open(_log_path, FileAccess.WRITE)
