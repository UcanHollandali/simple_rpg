# Layer: Tools
extends SceneTree

const DEFAULT_PIXEL_TOLERANCE := 4
const DEFAULT_MAX_CHANGED_RATIO := 0.015
const DEFAULT_MAX_MEAN_DELTA := 1.25

var _baseline_dir := ""
var _actual_dir := ""
var _diff_dir := ""
var _report_path := ""
var _pixel_tolerance := DEFAULT_PIXEL_TOLERANCE
var _max_changed_ratio := DEFAULT_MAX_CHANGED_RATIO
var _max_mean_delta := DEFAULT_MAX_MEAN_DELTA


func _init() -> void:
	var parse_error := _parse_args(OS.get_cmdline_user_args())
	if parse_error != "":
		push_error(parse_error)
		quit(1)
		return

	_run_diff()


func _parse_args(args: PackedStringArray) -> String:
	var index := 0
	while index < args.size():
		var arg := String(args[index])
		match arg:
			"--baseline-dir":
				index += 1
				if index >= args.size():
					return "missing path after --baseline-dir"
				_baseline_dir = String(args[index]).replace("\\", "/")
			"--actual-dir":
				index += 1
				if index >= args.size():
					return "missing path after --actual-dir"
				_actual_dir = String(args[index]).replace("\\", "/")
			"--diff-dir":
				index += 1
				if index >= args.size():
					return "missing path after --diff-dir"
				_diff_dir = String(args[index]).replace("\\", "/")
			"--report":
				index += 1
				if index >= args.size():
					return "missing path after --report"
				_report_path = String(args[index]).replace("\\", "/")
			"--pixel-tolerance":
				index += 1
				if index >= args.size():
					return "missing value after --pixel-tolerance"
				_pixel_tolerance = max(0, int(args[index]))
			"--max-changed-ratio":
				index += 1
				if index >= args.size():
					return "missing value after --max-changed-ratio"
				_max_changed_ratio = max(0.0, float(args[index]))
			"--max-mean-delta":
				index += 1
				if index >= args.size():
					return "missing value after --max-mean-delta"
				_max_mean_delta = max(0.0, float(args[index]))
			_:
				return "unexpected argument: %s" % arg
		index += 1

	if _baseline_dir == "":
		return "missing required --baseline-dir"
	if _actual_dir == "":
		return "missing required --actual-dir"
	if _diff_dir == "":
		return "missing required --diff-dir"
	if _report_path == "":
		return "missing required --report"

	return ""


func _run_diff() -> void:
	var baseline_names := _collect_png_names(_baseline_dir)
	var report := {
		"baseline_dir": _baseline_dir,
		"actual_dir": _actual_dir,
		"diff_dir": _diff_dir,
		"thresholds": {
			"pixel_tolerance": _pixel_tolerance,
			"max_changed_ratio": _max_changed_ratio,
			"max_mean_delta": _max_mean_delta,
		},
		"images": [],
		"summary": {
			"checked": 0,
			"failed": 0,
			"missing": 0,
			"dimension_mismatch": 0,
		},
	}

	if baseline_names.is_empty():
		report["error"] = "no baseline PNG files found"
		_write_report(report)
		push_error("No baseline PNG files found in %s" % _baseline_dir)
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(_diff_dir)

	for image_name in baseline_names:
		var result := _compare_image(image_name)
		(report["images"] as Array).append(result)
		var summary: Dictionary = report["summary"]
		summary["checked"] = int(summary["checked"]) + 1
		if not bool(result.get("passed", false)):
			summary["failed"] = int(summary["failed"]) + 1
		if bool(result.get("missing_actual", false)):
			summary["missing"] = int(summary["missing"]) + 1
		if bool(result.get("dimension_mismatch", false)):
			summary["dimension_mismatch"] = int(summary["dimension_mismatch"]) + 1

	_write_report(report)

	var failed_count := int((report["summary"] as Dictionary).get("failed", 0))
	if failed_count > 0:
		push_error("Portrait image diff failed for %d image(s). Report: %s" % [failed_count, _report_path])
		quit(1)
		return

	print("PORTRAIT_IMAGE_DIFF: passed %d image(s)" % int((report["summary"] as Dictionary).get("checked", 0)))
	quit(0)


func _collect_png_names(directory_path: String) -> Array[String]:
	var names: Array[String] = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return names

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.get_extension().to_lower() == "png":
			names.append(file_name)
		file_name = directory.get_next()
	directory.list_dir_end()

	names.sort()
	return names


func _compare_image(image_name: String) -> Dictionary:
	var baseline_path := "%s/%s" % [_baseline_dir.trim_suffix("/"), image_name]
	var actual_path := "%s/%s" % [_actual_dir.trim_suffix("/"), image_name]
	var diff_path := "%s/%s" % [_diff_dir.trim_suffix("/"), image_name]
	var result := {
		"name": image_name,
		"baseline": baseline_path,
		"actual": actual_path,
		"diff": diff_path,
		"passed": false,
	}

	if not FileAccess.file_exists(actual_path):
		result["missing_actual"] = true
		result["failure_reason"] = "missing actual image"
		return result

	var baseline_image := Image.new()
	var baseline_error := baseline_image.load(baseline_path)
	if baseline_error != OK:
		result["failure_reason"] = "failed to load baseline: %d" % baseline_error
		return result

	var actual_image := Image.new()
	var actual_error := actual_image.load(actual_path)
	if actual_error != OK:
		result["failure_reason"] = "failed to load actual: %d" % actual_error
		return result

	if baseline_image.get_size() != actual_image.get_size():
		result["dimension_mismatch"] = true
		result["baseline_size"] = _size_payload(baseline_image.get_size())
		result["actual_size"] = _size_payload(actual_image.get_size())
		result["failure_reason"] = "dimension mismatch"
		return result

	baseline_image.convert(Image.FORMAT_RGBA8)
	actual_image.convert(Image.FORMAT_RGBA8)

	var size := baseline_image.get_size()
	var baseline_data := baseline_image.get_data()
	var actual_data := actual_image.get_data()
	var diff_data := PackedByteArray()
	diff_data.resize(actual_data.size())

	var pixel_count := size.x * size.y
	var changed_pixels := 0
	var channel_delta_sum := 0.0
	var max_channel_delta := 0

	var data_index := 0
	while data_index < actual_data.size():
		var red_delta := absi(int(baseline_data[data_index]) - int(actual_data[data_index]))
		var green_delta := absi(int(baseline_data[data_index + 1]) - int(actual_data[data_index + 1]))
		var blue_delta := absi(int(baseline_data[data_index + 2]) - int(actual_data[data_index + 2]))
		var alpha_delta := absi(int(baseline_data[data_index + 3]) - int(actual_data[data_index + 3]))
		var pixel_max_delta := maxi(maxi(red_delta, green_delta), maxi(blue_delta, alpha_delta))

		channel_delta_sum += float(red_delta + green_delta + blue_delta + alpha_delta)
		max_channel_delta = maxi(max_channel_delta, pixel_max_delta)

		if pixel_max_delta > _pixel_tolerance:
			changed_pixels += 1
			diff_data[data_index] = 255
			diff_data[data_index + 1] = 0
			diff_data[data_index + 2] = 180
			diff_data[data_index + 3] = 255
		else:
			diff_data[data_index] = int(float(actual_data[data_index]) * 0.22)
			diff_data[data_index + 1] = int(float(actual_data[data_index + 1]) * 0.22)
			diff_data[data_index + 2] = int(float(actual_data[data_index + 2]) * 0.22)
			diff_data[data_index + 3] = 255

		data_index += 4

	var changed_ratio := float(changed_pixels) / float(pixel_count)
	var mean_delta := channel_delta_sum / float(pixel_count * 4)
	var passed := changed_ratio <= _max_changed_ratio and mean_delta <= _max_mean_delta

	result["passed"] = passed
	result["width"] = size.x
	result["height"] = size.y
	result["pixel_count"] = pixel_count
	result["changed_pixels"] = changed_pixels
	result["changed_ratio"] = changed_ratio
	result["mean_channel_delta"] = mean_delta
	result["max_channel_delta"] = max_channel_delta

	if not passed:
		result["failure_reason"] = "threshold exceeded"

	if changed_pixels > 0:
		var diff_image := Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGBA8, diff_data)
		var make_dir_result := DirAccess.make_dir_recursive_absolute(diff_path.get_base_dir())
		if make_dir_result == OK:
			var save_result := diff_image.save_png(diff_path)
			result["diff_saved"] = save_result == OK
			if save_result != OK:
				result["diff_save_error"] = save_result

	return result


func _size_payload(size: Vector2i) -> Dictionary:
	return {
		"width": size.x,
		"height": size.y,
	}


func _write_report(report: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(_report_path.get_base_dir())
	var file := FileAccess.open(_report_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write portrait image diff report: %s" % _report_path)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
