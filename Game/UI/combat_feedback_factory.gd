# Layer: UI helper
extends RefCounted
class_name CombatFeedbackFactory

const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")


static func build_guard_feedback_model(guard_amount: int) -> Dictionary:
	return {
		"target": "player",
		"text": "Guard +%d" % max(0, guard_amount),
		"intensity": "medium",
		"flash_color": TempScreenThemeScript.TEAL_ACCENT_COLOR,
		"font_color": TempScreenThemeScript.TEAL_ACCENT_COLOR.lightened(0.2),
		"flash_alpha": 0.22,
		"pulse_scale": 1.04,
		"float_distance": 48.0,
		"font_size": 20,
		"feedback_stagger": 0.07,
		"flash_cycles": 1,
		"flash_on_duration": 0.06,
		"flash_off_duration": 0.1,
		"pulse_in_duration": 0.08,
		"pulse_out_duration": 0.18,
		"text_fade_in_duration": 0.08,
		"text_hold_duration": 0.14,
		"text_fade_out_duration": 0.16,
		"text_float_duration": 0.38,
	}


static func build_guard_delta_feedback_model(guard_delta: int, label_text: String = "guard") -> Dictionary:
	var magnitude: int = abs(guard_delta)
	if magnitude <= 0:
		return {}

	var is_gain: bool = guard_delta > 0
	return {
		"target": "player",
		"text": "%s%d %s" % ["+" if is_gain else "-", magnitude, label_text],
		"intensity": "medium" if is_gain else "light",
		"flash_color": TempScreenThemeScript.TEAL_ACCENT_COLOR if is_gain else TempScreenThemeScript.PANEL_BORDER_COLOR,
		"font_color": TempScreenThemeScript.TEAL_ACCENT_COLOR.lightened(0.2) if is_gain else TempScreenThemeScript.TEXT_MUTED_COLOR,
		"flash_alpha": 0.22 if is_gain else 0.14,
		"pulse_scale": 1.04 if is_gain else 1.025,
		"float_distance": 48.0 if is_gain else 40.0,
		"font_size": 20 if is_gain else 18,
		"feedback_stagger": 0.07 if is_gain else 0.06,
		"flash_cycles": 1,
		"flash_on_duration": 0.06,
		"flash_off_duration": 0.1 if is_gain else 0.08,
		"pulse_in_duration": 0.08,
		"pulse_out_duration": 0.18 if is_gain else 0.16,
		"text_fade_in_duration": 0.08,
		"text_hold_duration": 0.14 if is_gain else 0.12,
		"text_fade_out_duration": 0.16 if is_gain else 0.14,
		"text_float_duration": 0.38 if is_gain else 0.34,
	}


static func build_guard_decay_feedback_model(decay_amount: int) -> Dictionary:
	return build_guard_delta_feedback_model(-abs(decay_amount), "decay")


static func build_guard_absorb_feedback_model(guard_amount: int) -> Dictionary:
	return {
		"target": "player",
		"text": "Block %d" % max(0, guard_amount),
		"intensity": "light",
		"flash_color": TempScreenThemeScript.TEAL_ACCENT_COLOR.lightened(0.08),
		"font_color": TempScreenThemeScript.TEAL_ACCENT_COLOR.lightened(0.12),
		"flash_alpha": 0.16,
		"pulse_scale": 1.03,
		"float_distance": 42.0,
		"font_size": 18,
		"feedback_stagger": 0.06,
		"flash_cycles": 1,
		"flash_on_duration": 0.06,
		"flash_off_duration": 0.08,
		"pulse_in_duration": 0.08,
		"pulse_out_duration": 0.16,
		"text_fade_in_duration": 0.08,
		"text_hold_duration": 0.12,
		"text_fade_out_duration": 0.14,
		"text_float_duration": 0.34,
	}


static func build_recovery_feedback_models(healed_amount: int, hunger_restored_amount: int) -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	if healed_amount > 0:
		models.append({
			"target": "player",
			"text": "+%d HP" % healed_amount,
			"intensity": "medium",
			"flash_color": TempScreenThemeScript.TEAL_ACCENT_COLOR,
			"font_color": TempScreenThemeScript.TEAL_ACCENT_COLOR.lightened(0.25),
			"flash_alpha": 0.18,
			"pulse_scale": 1.035,
			"float_distance": 52.0,
			"font_size": 24,
			"feedback_stagger": 0.06,
			"flash_cycles": 1,
			"flash_on_duration": 0.06,
			"flash_off_duration": 0.1,
			"pulse_in_duration": 0.08,
			"pulse_out_duration": 0.18,
			"text_fade_in_duration": 0.08,
			"text_hold_duration": 0.14,
			"text_fade_out_duration": 0.16,
			"text_float_duration": 0.38,
		})
	if hunger_restored_amount > 0:
		models.append({
			"target": "player",
			"text": "+%d H" % hunger_restored_amount,
			"intensity": "light",
			"flash_color": TempScreenThemeScript.REWARD_ACCENT_COLOR,
			"font_color": TempScreenThemeScript.REWARD_ACCENT_COLOR,
			"flash_alpha": 0.14,
			"pulse_scale": 1.025,
			"float_distance": 44.0,
			"font_size": 20,
			"feedback_stagger": 0.06,
			"flash_cycles": 1,
			"flash_on_duration": 0.06,
			"flash_off_duration": 0.08,
			"pulse_in_duration": 0.08,
			"pulse_out_duration": 0.16,
			"text_fade_in_duration": 0.08,
			"text_hold_duration": 0.12,
			"text_fade_out_duration": 0.14,
			"text_float_duration": 0.34,
		})
	return models
