# Layer: Tests
extends SceneTree
class_name TestPlaytestLogger

const PlaytestLoggerScript = preload("res://Game/Infrastructure/playtest_logger.gd")
const TestExitCleanupHelperScript = preload("res://Tests/_exit_cleanup_helper.gd")

const LOG_PATH := "user://test_playtest_log.jsonl"


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	_delete_log_file()
	test_log_event_appends_jsonl_records()
	_delete_log_file()
	print("test_playtest_logger: all assertions passed")
	await TestExitCleanupHelperScript.cleanup_and_quit(self)


func test_log_event_appends_jsonl_records() -> void:
	var logger: PlaytestLogger = PlaytestLoggerScript.new()
	logger.setup(true, LOG_PATH)
	logger.log_event({
		"event_type": "node_transition",
		"stage_index": 1,
		"hunger": 18,
		"gold": 3,
		"hp": 57,
		"current_node_id": 4,
		"selected_id": 4,
	})
	logger.log_event({
		"event_type": "perk_choice",
		"stage_index": 1,
		"hunger": 18,
		"gold": 3,
		"hp": 57,
		"current_node_id": 4,
		"selected_id": "perk_guard_mastery",
	})

	assert(FileAccess.file_exists(LOG_PATH), "Expected playtest logger to create the requested JSONL file.")

	var file: FileAccess = FileAccess.open(LOG_PATH, FileAccess.READ)
	assert(file != null, "Expected to reopen the JSONL file for verification.")

	var lines: Array[String] = []
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty():
			continue
		lines.append(line)
	file.close()

	assert(lines.size() == 2, "Expected logger writes to append separate JSONL records.")

	var first_record_value: Variant = JSON.parse_string(lines[0])
	var second_record_value: Variant = JSON.parse_string(lines[1])
	assert(typeof(first_record_value) == TYPE_DICTIONARY, "Expected the first JSONL row to parse as a dictionary.")
	assert(typeof(second_record_value) == TYPE_DICTIONARY, "Expected the second JSONL row to parse as a dictionary.")

	var first_record: Dictionary = first_record_value
	var second_record: Dictionary = second_record_value
	assert(first_record.get("event_type", "") == "node_transition", "Expected the first record to preserve the event type.")
	assert(int(first_record.get("timestamp", 0)) > 0, "Expected the logger to stamp each record with a Unix timestamp.")
	assert(int(first_record.get("current_node_id", -1)) == 4, "Expected the first record to preserve the minimal node context.")
	assert(second_record.get("selected_id", "") == "perk_guard_mastery", "Expected the appended record to preserve the selected identifier.")


func _delete_log_file() -> void:
	if not FileAccess.file_exists(LOG_PATH):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LOG_PATH))
