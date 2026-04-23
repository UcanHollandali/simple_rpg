# Layer: UI
extends RefCounted
class_name CombatEnemyIntentBustVisuals

const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")

const ENEMY_BUST_FRAME_PATH := "Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame"
const ENEMY_BUST_TEXTURE_PATH := "Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame/BustTexture"
const ENEMY_INTENT_BADGE_PANEL_NAME := "EnemyIntentBadgePanel"
const ENEMY_INTENT_BADGE_ROW_NAME := "EnemyIntentBadgeRow"
const ENEMY_INTENT_BADGE_ICON_NAME := "EnemyIntentBadgeIcon"
const ENEMY_INTENT_BADGE_LABEL_NAME := "EnemyIntentBadgeLabel"
const ENEMY_INTENT_BADGE_TWEEN_META_KEY := "enemy_intent_badge_tween"
const ENEMY_INTENT_STATUS_ACCENT := Color(0.36078432, 0.52156866, 0.34117648, 0.96)

var _host: Control
var _scene_node_getter: Callable
var _enemy_intent_badge_panel: PanelContainer
var _enemy_intent_badge_label: Label
var _enemy_intent_badge_icon: TextureRect
var _enemy_intent_badge_feedback_scheduled: bool = false
var _pending_enemy_intent_badge_boss_reveal: bool = false


func configure(host: Control, scene_node_getter: Callable) -> void:
	_host = host
	_scene_node_getter = scene_node_getter


func ensure_badge(is_compact_layout: bool) -> void:
	var bust_texture: TextureRect = _scene_node_getter.call(ENEMY_BUST_TEXTURE_PATH) as TextureRect
	if bust_texture == null:
		return
	if _enemy_intent_badge_panel == null or not is_instance_valid(_enemy_intent_badge_panel):
		_enemy_intent_badge_panel = bust_texture.get_node_or_null(ENEMY_INTENT_BADGE_PANEL_NAME) as PanelContainer
	if _enemy_intent_badge_panel == null:
		_enemy_intent_badge_panel = PanelContainer.new()
		_enemy_intent_badge_panel.name = ENEMY_INTENT_BADGE_PANEL_NAME
		_enemy_intent_badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bust_texture.add_child(_enemy_intent_badge_panel)

	var badge_row: HBoxContainer = _enemy_intent_badge_panel.get_node_or_null(ENEMY_INTENT_BADGE_ROW_NAME) as HBoxContainer
	if badge_row == null:
		badge_row = HBoxContainer.new()
		badge_row.name = ENEMY_INTENT_BADGE_ROW_NAME
		badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
		badge_row.add_theme_constant_override("separation", 6)
		_enemy_intent_badge_panel.add_child(badge_row)

	if _enemy_intent_badge_icon == null or not is_instance_valid(_enemy_intent_badge_icon):
		_enemy_intent_badge_icon = badge_row.get_node_or_null(ENEMY_INTENT_BADGE_ICON_NAME) as TextureRect
	if _enemy_intent_badge_icon == null:
		_enemy_intent_badge_icon = TextureRect.new()
		_enemy_intent_badge_icon.name = ENEMY_INTENT_BADGE_ICON_NAME
		_enemy_intent_badge_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_enemy_intent_badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_enemy_intent_badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge_row.add_child(_enemy_intent_badge_icon)

	if _enemy_intent_badge_label == null or not is_instance_valid(_enemy_intent_badge_label):
		_enemy_intent_badge_label = badge_row.get_node_or_null(ENEMY_INTENT_BADGE_LABEL_NAME) as Label
	if _enemy_intent_badge_label == null:
		_enemy_intent_badge_label = Label.new()
		_enemy_intent_badge_label.name = ENEMY_INTENT_BADGE_LABEL_NAME
		_enemy_intent_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_enemy_intent_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_enemy_intent_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_row.add_child(_enemy_intent_badge_label)

	_style_enemy_intent_badge(_resolve_enemy_intent_visual_accent("attack"), is_compact_layout)
	_layout_enemy_intent_badge(is_compact_layout)
	if not _enemy_intent_badge_panel.visible:
		_enemy_intent_badge_panel.modulate = Color(1, 1, 1, 0)


func refresh(intent: Dictionary, presenter: CombatPresenter, is_compact_layout: bool) -> void:
	var bust_frame: PanelContainer = _scene_node_getter.call(ENEMY_BUST_FRAME_PATH) as PanelContainer
	var bust_texture: TextureRect = _scene_node_getter.call(ENEMY_BUST_TEXTURE_PATH) as TextureRect
	if bust_frame == null or bust_texture == null:
		return

	var accent_key: String = "attack"
	var badge_text: String = ""
	var badge_icon_texture_path: String = ""
	var show_badge: bool = false
	if presenter != null:
		var visual_model: Dictionary = presenter.build_enemy_bust_intent_visual_model(intent)
		accent_key = String(visual_model.get("accent_key", "attack"))
		badge_text = String(visual_model.get("badge_text", ""))
		badge_icon_texture_path = String(visual_model.get("icon_texture_path", ""))
		show_badge = bool(visual_model.get("visible", false)) and not badge_text.is_empty() and bust_texture.visible

	var accent: Color = _resolve_enemy_intent_visual_accent(accent_key)
	TempScreenThemeScript.apply_panel(bust_frame, accent, 14, 0.36 if accent_key == "heavy" else 0.34)
	TempScreenThemeScript.intensify_panel(
		bust_frame,
		accent,
		3 if accent_key == "heavy" else 2,
		18 if accent_key == "heavy" else 14,
		0.04 if accent_key == "heavy" else 0.03,
		0.24 if accent_key == "heavy" else 0.22
	)
	bust_texture.modulate = _resolve_enemy_bust_texture_modulate(accent_key, accent)

	ensure_badge(is_compact_layout)
	if _enemy_intent_badge_panel == null or _enemy_intent_badge_label == null or _enemy_intent_badge_icon == null:
		return
	if not show_badge:
		_enemy_intent_badge_panel.visible = false
		_enemy_intent_badge_panel.modulate = Color(1, 1, 1, 0)
		return

	_style_enemy_intent_badge(accent, is_compact_layout)
	_enemy_intent_badge_label.text = badge_text
	var icon_texture: Texture2D = SceneLayoutHelperScript.load_texture_or_null(badge_icon_texture_path)
	_enemy_intent_badge_icon.texture = icon_texture
	_enemy_intent_badge_icon.visible = icon_texture != null
	_layout_enemy_intent_badge(is_compact_layout)
	_enemy_intent_badge_panel.visible = true
	if _enemy_intent_badge_panel.modulate.a < 0.99:
		_enemy_intent_badge_panel.modulate = Color(1, 1, 1, 1)


func schedule_feedback(is_boss_phase: bool = false, is_compact_layout: bool = false) -> void:
	_pending_enemy_intent_badge_boss_reveal = _pending_enemy_intent_badge_boss_reveal or is_boss_phase
	if _enemy_intent_badge_feedback_scheduled:
		return
	_enemy_intent_badge_feedback_scheduled = true
	Callable(self, "_play_pending_enemy_intent_badge_feedback").call_deferred(is_compact_layout)


func _play_pending_enemy_intent_badge_feedback(is_compact_layout: bool) -> void:
	_enemy_intent_badge_feedback_scheduled = false
	var is_boss_phase: bool = _pending_enemy_intent_badge_boss_reveal
	_pending_enemy_intent_badge_boss_reveal = false
	_play_enemy_intent_badge_feedback(is_boss_phase, is_compact_layout)


func _play_enemy_intent_badge_feedback(is_boss_phase: bool, is_compact_layout: bool) -> void:
	_layout_enemy_intent_badge(is_compact_layout)
	var target: Control = _enemy_intent_badge_panel if _enemy_intent_badge_panel != null and _enemy_intent_badge_panel.visible else _scene_node_getter.call(ENEMY_BUST_FRAME_PATH) as Control
	if target == null or not target.visible or _host == null:
		return
	_kill_control_tween(target, ENEMY_INTENT_BADGE_TWEEN_META_KEY)
	target.pivot_offset = target.size * 0.5
	target.scale = Vector2.ONE * (0.92 if not is_boss_phase else 0.88)
	target.modulate = Color(1, 1, 1, 0.78 if not is_boss_phase else 0.9)
	var tween: Tween = _host.create_tween()
	target.set_meta(ENEMY_INTENT_BADGE_TWEEN_META_KEY, tween)
	tween.parallel().tween_property(target, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(target, "modulate", Color(1, 1, 1, 1), 0.18)
	tween.finished.connect(Callable(self, "_clear_control_meta").bind(target, ENEMY_INTENT_BADGE_TWEEN_META_KEY), CONNECT_ONE_SHOT)


func _style_enemy_intent_badge(accent: Color, is_compact_layout: bool) -> void:
	if _enemy_intent_badge_panel == null or _enemy_intent_badge_label == null:
		return
	TempScreenThemeScript.apply_chip(_enemy_intent_badge_panel, _enemy_intent_badge_label, accent)
	_enemy_intent_badge_label.add_theme_font_size_override("font_size", 12 if is_compact_layout else 13)
	if _enemy_intent_badge_icon != null:
		var icon_size: float = 14.0 if is_compact_layout else 16.0
		_enemy_intent_badge_icon.custom_minimum_size = Vector2(icon_size, icon_size)
		_enemy_intent_badge_icon.self_modulate = TempScreenThemeScript.TEXT_PRIMARY_COLOR


func _layout_enemy_intent_badge(is_compact_layout: bool) -> void:
	if _enemy_intent_badge_panel == null or not is_instance_valid(_enemy_intent_badge_panel):
		return
	var bust_texture: TextureRect = _scene_node_getter.call(ENEMY_BUST_TEXTURE_PATH) as TextureRect
	if bust_texture == null:
		return
	var badge_size: Vector2 = _enemy_intent_badge_panel.get_combined_minimum_size()
	_enemy_intent_badge_panel.size = badge_size
	var horizontal_margin: float = 8.0 if is_compact_layout else 10.0
	var vertical_margin: float = 8.0 if is_compact_layout else 10.0
	_enemy_intent_badge_panel.position = Vector2(
		max(horizontal_margin, bust_texture.size.x - badge_size.x - horizontal_margin),
		vertical_margin
	)


func _resolve_enemy_intent_visual_accent(accent_key: String) -> Color:
	match accent_key:
		"heavy":
			return TempScreenThemeScript.RUST_ACCENT_COLOR.lightened(0.16)
		"status":
			return ENEMY_INTENT_STATUS_ACCENT
		"watch":
			return TempScreenThemeScript.REWARD_ACCENT_COLOR
		_:
			return TempScreenThemeScript.RUST_ACCENT_COLOR


func _resolve_enemy_bust_texture_modulate(accent_key: String, accent: Color) -> Color:
	var tint_strength: float = 0.08
	match accent_key:
		"heavy":
			tint_strength = 0.18
		"status":
			tint_strength = 0.14
		"watch":
			tint_strength = 0.1
		_:
			tint_strength = 0.1
	var tint_color: Color = accent.lightened(0.34)
	tint_color.a = 1.0
	return Color(1, 1, 1, 1).lerp(tint_color, tint_strength)


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
