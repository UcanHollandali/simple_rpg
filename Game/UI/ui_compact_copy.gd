# Layer: UI
extends RefCounted
class_name UiCompactCopy


static func pick_one(subject: String, fallback_subject: String = "choice") -> String:
	var normalized_subject: String = String(subject).strip_edges()
	if normalized_subject.is_empty():
		normalized_subject = fallback_subject
	return "Pick 1 %s." % normalized_subject


static func hover_for_details() -> String:
	return "Hover for details."


static func objective_key_boss() -> String:
	return "Find the key. Beat the boss."


static func auto_bridge() -> String:
	return "Auto bridge."


static func back_to_menu_when_ready() -> String:
	return "Back to menu when ready."


static func join_steps(steps: Array) -> String:
	var filtered: PackedStringArray = []
	for step_value in steps:
		var step_text: String = String(step_value).strip_edges()
		if not step_text.is_empty():
			filtered.append(step_text)
	return " -> ".join(filtered)
