extends SceneTree

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const PlaytestLoggerScript = preload("res://Game/Infrastructure/playtest_logger.gd")
const LOG_PATH := "user://test_playtest_logger.jsonl"


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	test_playtest_logging_requested_requires_explicit_flag()
	test_logger_setup_writes_session_header_and_ids()
	test_log_event_appends_jsonl_records()
	test_logger_reuses_single_session_header_within_same_process()
	print("test_playtest_logger: all assertions passed")
	quit()


func test_playtest_logging_requested_requires_explicit_flag() -> void:
	assert(
		not AppBootstrapScript.playtest_logging_requested(PackedStringArray([])),
		"Expected playtest logging to stay disabled when no command-line flags are provided."
	)
	assert(
		not AppBootstrapScript.playtest_logging_requested(PackedStringArray(["--headless", "--path", "res://"])),
		"Expected generic headless debug/test args to stay below the playtest logging threshold."
	)
	assert(
		AppBootstrapScript.playtest_logging_requested(PackedStringArray(["--headless", "--playtest-log"])),
		"Expected the explicit --playtest-log flag to enable playtest logging when requested."
	)


func test_logger_setup_writes_session_header_and_ids() -> void:
	_reset_log_file()
	var logger = PlaytestLoggerScript.new()
	logger.setup(true, LOG_PATH, {"logging_mode": "explicit_flag"})
	logger.log_event({"event_type": "node_transition", "selected_id": 4})

	var records: Array[Dictionary] = _read_log_records()
	assert(records.size() == 2, "Expected logger setup plus one event to append exactly two JSONL records.")

	var session_start_record: Dictionary = records[0]
	var node_transition_record: Dictionary = records[1]
	assert(
		String(session_start_record.get("event_type", "")) == PlaytestLoggerScript.EVENT_TYPE_SESSION_START,
		"Expected logger setup to append a session_start header record."
	)
	assert(
		String(session_start_record.get("logging_mode", "")) == "explicit_flag",
		"Expected logger setup to preserve caller-supplied session metadata on the session_start header."
	)
	assert(
		not String(session_start_record.get("session_id", "")).is_empty(),
		"Expected session_start records to expose a non-empty session id."
	)
	assert(
		String(node_transition_record.get("session_id", "")) == String(session_start_record.get("session_id", "")),
		"Expected event records to inherit the session id declared by setup."
	)
	assert(
		String(logger.get_session_id()) == String(session_start_record.get("session_id", "")),
		"Expected the logger to expose the same session id it writes into the session_start header."
	)


func test_log_event_appends_jsonl_records() -> void:
	_reset_log_file()
	var logger = PlaytestLoggerScript.new()
	logger.setup(true, LOG_PATH, {"logging_mode": "explicit_flag"})
	logger.log_event({
		"event_type": "node_transition",
		"selected_id": 1,
	})
	logger.log_event({
		"event_type": "reward_choice",
		"selected_id": "quick_refit_set_the_edge",
	})

	var records: Array[Dictionary] = _read_log_records()
	assert(records.size() == 3, "Expected a session_start header plus two appended event records.")

	var session_start_record: Dictionary = records[0]
	var first_record: Dictionary = records[1]
	var second_record: Dictionary = records[2]
	assert(String(session_start_record.get("event_type", "")) == PlaytestLoggerScript.EVENT_TYPE_SESSION_START, "Expected the first record to be the session_start header.")
	assert(String(first_record.get("event_type", "")) == "node_transition", "Expected the first appended record to preserve its event_type.")
	assert(String(second_record.get("event_type", "")) == "reward_choice", "Expected the second appended record to preserve its event_type.")
	assert(
		String(first_record.get("session_id", "")) == String(session_start_record.get("session_id", "")),
		"Expected appended event records to carry the session id declared by the session_start header."
	)
	assert(
		String(second_record.get("session_id", "")) == String(session_start_record.get("session_id", "")),
		"Expected appended event records to carry the session id declared by the session_start header."
	)


func test_logger_reuses_single_session_header_within_same_process() -> void:
	_reset_log_file()
	var first_logger = PlaytestLoggerScript.new()
	first_logger.setup(true, LOG_PATH, {"logging_mode": "explicit_flag"})
	var second_logger = PlaytestLoggerScript.new()
	second_logger.setup(true, LOG_PATH, {"logging_mode": "explicit_flag"})

	first_logger.log_event({"event_type": "node_transition", "selected_id": 1})
	second_logger.log_event({"event_type": "reward_choice", "selected_id": "scavengers_find_watchman_shield"})

	var records: Array[Dictionary] = _read_log_records()
	assert(records.size() == 3, "Expected one session_start header plus two event records when two logger instances share a process.")

	var session_start_record: Dictionary = records[0]
	var first_event_record: Dictionary = records[1]
	var second_event_record: Dictionary = records[2]
	assert(String(session_start_record.get("event_type", "")) == PlaytestLoggerScript.EVENT_TYPE_SESSION_START, "Expected the first record to stay the shared session_start header.")
	assert(
		String(first_event_record.get("session_id", "")) == String(session_start_record.get("session_id", "")),
		"Expected the first logger instance to reuse the shared process session id."
	)
	assert(
		String(second_event_record.get("session_id", "")) == String(session_start_record.get("session_id", "")),
		"Expected the second logger instance to reuse the shared process session id instead of writing a second header."
	)


func _reset_log_file() -> void:
	var absolute_log_path: String = ProjectSettings.globalize_path(LOG_PATH)
	if FileAccess.file_exists(absolute_log_path):
		DirAccess.remove_absolute(absolute_log_path)


func _read_log_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var file := FileAccess.open(ProjectSettings.globalize_path(LOG_PATH), FileAccess.READ)
	assert(file != null, "Expected playtest log file to exist before reading records.")
	while not file.eof_reached():
		var line: String = file.get_line()
		if line.strip_edges().is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		assert(parsed is Dictionary, "Expected JSONL records to parse into Dictionary values.")
		records.append(parsed)
	return records
