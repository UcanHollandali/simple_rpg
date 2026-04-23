extends RefCounted
class_name PlaytestLogger

const DEFAULT_LOG_PATH := "user://playtest_log.jsonl"
const EVENT_TYPE_SESSION_START := "session_start"

static var _active_session_id: String = ""
static var _active_log_file_path: String = ""
static var _session_header_written: bool = false

var _enabled: bool = false
var _log_path: String = DEFAULT_LOG_PATH
var _session_id: String = ""


func setup(enabled: bool, log_path: String = DEFAULT_LOG_PATH, session_metadata: Dictionary = {}) -> void:
	_enabled = enabled
	_log_path = log_path.strip_edges()
	_session_id = ""
	if not _enabled:
		return

	var resolved_log_path: String = _resolve_log_path()
	var continuing_session: bool = (
		not _active_session_id.is_empty()
		and _active_log_file_path == resolved_log_path
		and _session_header_written
		and FileAccess.file_exists(resolved_log_path)
	)
	if not continuing_session:
		_active_session_id = _build_session_id()
		_active_log_file_path = resolved_log_path
		_session_header_written = false
	_session_id = _active_session_id
	if not _session_header_written:
		_write_record(_build_session_start_record(session_metadata))
		_session_header_written = true


func is_enabled() -> bool:
	return _enabled and not _log_path.is_empty()


func log_event(payload: Dictionary) -> void:
	if not is_enabled():
		return
	_write_record(payload)


func get_session_id() -> String:
	return _session_id


func _build_session_start_record(session_metadata: Dictionary) -> Dictionary:
	var record: Dictionary = {
		"event_type": EVENT_TYPE_SESSION_START,
	}
	for key in session_metadata.keys():
		record[key] = session_metadata[key]
	return record


func _write_record(payload: Dictionary) -> void:
	var absolute_path: String = _resolve_log_path()
	var parent_dir: String = absolute_path.get_base_dir()
	if parent_dir.is_empty():
		return
	var dir_result: Error = DirAccess.make_dir_recursive_absolute(parent_dir)
	if dir_result != OK and dir_result != ERR_ALREADY_EXISTS:
		return

	var file := FileAccess.open(absolute_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return

	file.seek_end()
	var record: Dictionary = payload.duplicate(true)
	record["timestamp"] = Time.get_unix_time_from_system()
	if not _session_id.is_empty():
		record["session_id"] = _session_id
	file.store_line(JSON.stringify(record))


func _resolve_log_path() -> String:
	return ProjectSettings.globalize_path(_log_path)


func _build_session_id() -> String:
	return "%d-%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
