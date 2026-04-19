# Layer: UI
extends RefCounted
class_name CombatFeedbackLane

const CombatSceneShellScript = preload("res://Game/UI/combat_scene_shell.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")

const INTENT_CARD_PATH := "Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard"
const BAR_TWEEN_META_KEY := "bar_tween"
const BAR_INITIALIZED_META_KEY := "bar_initialized"
const INTENT_REVEAL_TWEEN_META_KEY := "intent_reveal_tween"
const PLAYER_FEEDBACK_Y_FACTOR := 0.6
const ENEMY_FEEDBACK_Y_FACTOR := 0.46
const INTENT_REVEAL_DURATION := 0.2
const INTENT_REVEAL_START_SCALE := Vector2(0.92, 0.92)
const FEEDBACK_FALLBACK_STAGGER := 0.06
const BAR_TWEEN_MIN_DURATION := 0.18
const BAR_TWEEN_MAX_DURATION := 0.3

var _host: Control
var _scene_node_getter: Callable
var _feedback_lane_by_target := {
	"player": 0,
	"enemy": 0,
}
var _feedback_visual_delay_by_target := {
	"player": 0.0,
	"enemy": 0.0,
}
var _feedback_lane_reset_scheduled: bool = false
var _intent_reveal_feedback_scheduled: bool = false
var _pending_boss_phase_reveal: bool = false


func configure(host: Control, scene_node_getter: Callable) -> void:
	_host = host
	_scene_node_getter = scene_node_getter


func flush_phase_feedbacks(phase_models: Array[Dictionary]) -> void:
	if phase_models.is_empty():
		return

	var target_visual_claims: Dictionary = {}
	for model in phase_models:
		var target: String = String(model.get("target", "player"))
		var feedback_model: Dictionary = model.duplicate(true)
		var visuals_claimed: bool = bool(target_visual_claims.get(target, false))
		if visuals_claimed or bool(feedback_model.get("text_only", false)):
			feedback_model["text_only"] = true
		else:
			var delay_seconds: float = float(_feedback_visual_delay_by_target.get(target, 0.0))
			feedback_model["delay_seconds"] = delay_seconds
			_feedback_visual_delay_by_target[target] = delay_seconds + _estimate_feedback_visual_duration(feedback_model) + float(feedback_model.get("feedback_stagger", FEEDBACK_FALLBACK_STAGGER))
			target_visual_claims[target] = true
		_play_feedback_burst(feedback_model)


func animate_progress_bar(bar: ProgressBar, max_value: float, target_value: float) -> void:
	if bar == null:
		return

	var clamped_max: float = max(1.0, max_value)
	var clamped_value: float = clamp(target_value, 0.0, clamped_max)
	var is_initialized: bool = bool(bar.get_meta(BAR_INITIALIZED_META_KEY, false))
	_kill_control_tween(bar, BAR_TWEEN_META_KEY)
	bar.max_value = clamped_max
	if not is_initialized:
		bar.value = clamped_value
		bar.set_meta(BAR_INITIALIZED_META_KEY, true)
		return
	if is_equal_approx(bar.value, clamped_value):
		return

	var delta_ratio: float = abs(clamped_value - bar.value) / clamped_max
	var tween_duration: float = lerp(BAR_TWEEN_MIN_DURATION, BAR_TWEEN_MAX_DURATION, clamp(delta_ratio * 1.4, 0.0, 1.0))
	var tween: Tween = _host.create_tween()
	bar.set_meta(BAR_TWEEN_META_KEY, tween)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(bar, "value", clamped_value, tween_duration)
	tween.finished.connect(Callable(self, "_clear_control_meta").bind(bar, BAR_TWEEN_META_KEY), CONNECT_ONE_SHOT)


func queue_intent_reveal_feedback(is_boss_phase: bool = false) -> void:
	_pending_boss_phase_reveal = _pending_boss_phase_reveal or is_boss_phase
	if _intent_reveal_feedback_scheduled:
		return
	_intent_reveal_feedback_scheduled = true
	call_deferred("_play_pending_intent_reveal_feedback")


func _play_feedback_burst(model: Dictionary) -> void:
	var target: String = String(model.get("target", "player"))
	var target_nodes: Dictionary = _resolve_feedback_target_nodes(target)
	if target_nodes.is_empty():
		return

	var lane_index: int = int(_feedback_lane_by_target.get(target, 0))
	_feedback_lane_by_target[target] = lane_index + 1
	if not _feedback_lane_reset_scheduled:
		_feedback_lane_reset_scheduled = true
		call_deferred("_reset_feedback_lane_state")

	var flash: ColorRect = target_nodes.get("flash") as ColorRect
	var pulse_control: Control = target_nodes.get("pulse") as Control
	var text_layer: Control = target_nodes.get("text_layer") as Control
	if not bool(model.get("text_only", false)):
		_play_feedback_flash(flash, model)
		_play_feedback_pulse(pulse_control, model)
	_spawn_feedback_text(text_layer, model, lane_index)


func _resolve_feedback_target_nodes(target: String) -> Dictionary:
	var card_path: String = "Margin/VBox/BattleCardsRow/PlayerCard"
	var pulse_path: String = "Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame"
	if target == "enemy":
		card_path = "Margin/VBox/BattleCardsRow/EnemyCard"
		pulse_path = "Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame"

	var card: PanelContainer = _scene_node_getter.call(card_path) as PanelContainer
	if card == null:
		return {}
	var flash_path := "%s/%s" % [CombatSceneShellScript.COMBAT_FEEDBACK_LAYER_NAME, CombatSceneShellScript.IMPACT_FLASH_NODE_NAME]
	var text_layer_path := "%s/%s" % [CombatSceneShellScript.COMBAT_FEEDBACK_LAYER_NAME, CombatSceneShellScript.FEEDBACK_TEXT_LAYER_NAME]
	var flash: ColorRect = card.get_node_or_null(flash_path) as ColorRect
	var text_layer: Control = card.get_node_or_null(text_layer_path) as Control
	var pulse_control: Control = _scene_node_getter.call(pulse_path) as Control
	if pulse_control == null or not pulse_control.visible:
		pulse_control = card
	return {
		"flash": flash,
		"text_layer": text_layer,
		"pulse": pulse_control,
	}


func _reset_feedback_lane_state() -> void:
	_feedback_lane_by_target["player"] = 0
	_feedback_lane_by_target["enemy"] = 0
	_feedback_visual_delay_by_target["player"] = 0.0
	_feedback_visual_delay_by_target["enemy"] = 0.0
	_feedback_lane_reset_scheduled = false


func _play_feedback_flash(flash: ColorRect, model: Dictionary) -> void:
	if flash == null:
		return

	var flash_color: Color = Color(model.get("flash_color", TempScreenThemeScript.RUST_ACCENT_COLOR))
	var target_alpha: float = float(model.get("flash_alpha", 0.2))
	var flash_cycles: int = max(1, int(model.get("flash_cycles", 1)))
	var flash_on_duration: float = float(model.get("flash_on_duration", 0.06))
	var flash_off_duration: float = float(model.get("flash_off_duration", 0.1))
	var delay_seconds: float = float(model.get("delay_seconds", 0.0))
	flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
	var tween: Tween = _host.create_tween()
	tween.tween_interval(delay_seconds)
	for _cycle_index in range(flash_cycles):
		tween.tween_property(flash, "color", Color(flash_color.r, flash_color.g, flash_color.b, target_alpha), flash_on_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(flash, "color", Color(flash_color.r, flash_color.g, flash_color.b, 0.0), flash_off_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)


func _play_feedback_pulse(pulse_control: Control, model: Dictionary) -> void:
	if pulse_control == null:
		return

	pulse_control.pivot_offset = pulse_control.size * 0.5
	var start_scale: float = float(model.get("pulse_start_scale", 1.0))
	var target_scale: float = float(model.get("pulse_scale", 1.03))
	var delay_seconds: float = float(model.get("delay_seconds", 0.0))
	var pulse_in_duration: float = float(model.get("pulse_in_duration", 0.08))
	var pulse_out_duration: float = float(model.get("pulse_out_duration", 0.18))
	var tween: Tween = _host.create_tween()
	tween.tween_interval(delay_seconds)
	tween.tween_callback(Callable(self, "_set_control_scale").bind(pulse_control, Vector2.ONE * start_scale))
	tween.tween_property(pulse_control, "scale", Vector2.ONE * target_scale, pulse_in_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse_control, "scale", Vector2.ONE, pulse_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _spawn_feedback_text(text_layer: Control, model: Dictionary, lane_index: int) -> void:
	if text_layer == null:
		return

	var feedback_text: String = String(model.get("text", "")).strip_edges()
	if feedback_text.is_empty():
		return

	var label: Label = Label.new()
	label.text = feedback_text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	TempScreenThemeScript.apply_label(label)
	label.add_theme_font_size_override("font_size", int(model.get("font_size", 22)))
	label.add_theme_color_override("font_color", Color(model.get("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)))
	label.add_theme_color_override("font_outline_color", Color(0.015, 0.02, 0.03, 0.92))
	label.add_theme_constant_override("outline_size", 6)
	text_layer.add_child(label)

	var label_size: Vector2 = label.get_combined_minimum_size()
	label.size = label_size
	label.pivot_offset = label_size * 0.5
	var y_factor: float = PLAYER_FEEDBACK_Y_FACTOR
	if String(model.get("target", "player")) == "enemy":
		y_factor = ENEMY_FEEDBACK_Y_FACTOR
	var start_position := Vector2(
		(text_layer.size.x - label_size.x) * 0.5,
		(text_layer.size.y * y_factor) - (label_size.y * 0.5) + (float(lane_index) * 18.0)
	)
	var end_position := start_position - Vector2(0.0, float(model.get("float_distance", 44.0)) + (float(lane_index) * 8.0))
	label.position = start_position
	label.scale = Vector2.ONE * 0.9
	label.modulate = Color(1, 1, 1, 0)

	var delay_seconds: float = float(model.get("delay_seconds", 0.0)) + (float(lane_index) * float(model.get("feedback_stagger", FEEDBACK_FALLBACK_STAGGER)))
	var text_float_duration: float = float(model.get("text_float_duration", 0.4))
	var text_fade_in_duration: float = float(model.get("text_fade_in_duration", 0.08))
	var text_hold_duration: float = float(model.get("text_hold_duration", 0.14))
	var text_fade_out_duration: float = float(model.get("text_fade_out_duration", 0.16))
	var motion_tween: Tween = _host.create_tween()
	motion_tween.tween_interval(delay_seconds)
	motion_tween.tween_property(label, "position", end_position, text_float_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var scale_tween: Tween = _host.create_tween()
	scale_tween.tween_interval(delay_seconds)
	scale_tween.tween_property(label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var fade_tween: Tween = _host.create_tween()
	fade_tween.tween_interval(delay_seconds)
	fade_tween.tween_property(label, "modulate", Color(1, 1, 1, 1), text_fade_in_duration)
	fade_tween.tween_interval(text_hold_duration)
	fade_tween.tween_property(label, "modulate", Color(1, 1, 1, 0), text_fade_out_duration)
	fade_tween.finished.connect(Callable(label, "queue_free"), CONNECT_ONE_SHOT)


func _estimate_feedback_visual_duration(model: Dictionary) -> float:
	var flash_cycles: int = max(1, int(model.get("flash_cycles", 1)))
	var flash_total: float = (float(model.get("flash_on_duration", 0.06)) + float(model.get("flash_off_duration", 0.1))) * float(flash_cycles)
	var pulse_total: float = float(model.get("pulse_in_duration", 0.08)) + float(model.get("pulse_out_duration", 0.18))
	return max(flash_total, pulse_total)


func _play_pending_intent_reveal_feedback() -> void:
	_intent_reveal_feedback_scheduled = false
	var is_boss_phase: bool = _pending_boss_phase_reveal
	_pending_boss_phase_reveal = false
	_play_intent_reveal_feedback(is_boss_phase)


func _play_intent_reveal_feedback(is_boss_phase: bool = false) -> void:
	var intent_card: Control = _scene_node_getter.call(INTENT_CARD_PATH) as Control
	if intent_card == null or not intent_card.visible:
		return
	_kill_control_tween(intent_card, INTENT_REVEAL_TWEEN_META_KEY)
	intent_card.pivot_offset = intent_card.size * 0.5
	intent_card.scale = INTENT_REVEAL_START_SCALE if not is_boss_phase else Vector2(0.9, 0.9)
	intent_card.modulate = Color(1, 1, 1, 0.76 if not is_boss_phase else 0.88)
	var tween: Tween = _host.create_tween()
	intent_card.set_meta(INTENT_REVEAL_TWEEN_META_KEY, tween)
	tween.parallel().tween_property(intent_card, "scale", Vector2.ONE, INTENT_REVEAL_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(intent_card, "modulate", Color(1, 1, 1, 1), INTENT_REVEAL_DURATION)
	tween.finished.connect(Callable(self, "_clear_control_meta").bind(intent_card, INTENT_REVEAL_TWEEN_META_KEY), CONNECT_ONE_SHOT)


func _kill_control_tween(control: Control, meta_key: String) -> void:
	if control == null or not control.has_meta(meta_key):
		return
	var tween_value: Variant = control.get_meta(meta_key, null)
	if tween_value is Tween:
		var tween: Tween = tween_value as Tween
		if is_instance_valid(tween):
			tween.kill()
	control.remove_meta(meta_key)


func _clear_control_meta(control: Control, meta_key: String) -> void:
	if control == null or not is_instance_valid(control):
		return
	if control.has_meta(meta_key):
		control.remove_meta(meta_key)


func _set_control_scale(control: Control, target_scale: Vector2) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.scale = target_scale
