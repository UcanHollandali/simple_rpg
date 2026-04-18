# Layer: Scenes - presentation only
extends Control

const LaunchIntroPresenterScript = preload("res://Game/UI/launch_intro_presenter.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const MIN_SKIP_DELAY_SECONDS := 0.18
const AUTO_CONTINUE_SECONDS := 1.45
const UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const PLAYTEST_LAUNCH_SMOKE_ARG := "--playtest-launch-smoke"
const PLAYTEST_LAUNCH_SMOKE_QUIT_DELAY_SECONDS := 0.35
const PORTRAIT_SAFE_MAX_WIDTH := 760
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 24
const AUDIO_PLAYER_CONFIG := {
	"UiConfirmSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"},
	"PanelOpenSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"},
	"IntroMusicPlayer": {"path": "res://Assets/Audio/Music/music_ui_hub_loop_proto_01.ogg", "music": true, "loop": true},
}
const PORTRAIT_LAYOUT_CONFIG := {
	"max_width": PORTRAIT_SAFE_MAX_WIDTH,
	"min_side_margin": PORTRAIT_SAFE_MIN_SIDE_MARGIN,
	"top_margin": 40,
	"bottom_margin": 40,
	"margin_steps": [
		{"max_height": 1080.0, "top_margin": 28, "bottom_margin": 28},
		{"max_height": 760.0, "top_margin": 22, "bottom_margin": 22},
	],
	"bands": {
		"large": {"min_width": 520.0, "min_height": 940.0, "panel_width": 520.0, "vbox_separation": 12, "title_font_size": 46, "mood_font_size": 22, "body_font_size": 18, "hint_font_size": 18},
		"medium": {"min_width": 420.0, "min_height": 760.0, "panel_width": 460.0, "vbox_separation": 10, "title_font_size": 40, "mood_font_size": 20, "body_font_size": 17, "hint_font_size": 16},
		"compact": {"panel_width": 0.0, "vbox_separation": 10, "title_font_size": 34, "mood_font_size": 18, "body_font_size": 16, "hint_font_size": 15},
	},
}

var _bootstrap
var _presenter: LaunchIntroPresenter
var _skip_unlocked: bool = false
var _transition_started: bool = false


func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_presenter = LaunchIntroPresenterScript.new()
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	_apply_temp_theme()
	SceneLayoutHelperScript.bind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	_apply_portrait_safe_layout()
	_refresh_ui()
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")
	SceneAudioPlayersScript.start_looping(self, "IntroMusicPlayer")
	_play_open_tween()
	if _is_playtest_launch_smoke_requested():
		print("PLAYTEST_EXPORT_LAUNCH_SMOKE: main_scene_ready")
		Callable(self, "_quit_for_playtest_launch_smoke").call_deferred()
		return
	get_tree().create_timer(MIN_SKIP_DELAY_SECONDS).timeout.connect(Callable(self, "_unlock_skip"))
	get_tree().create_timer(AUTO_CONTINUE_SECONDS).timeout.connect(Callable(self, "_on_auto_continue_timeout"))


func _exit_tree() -> void:
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	SceneAudioCleanupScript.release_players(self, SceneAudioPlayersScript.node_names_from_config(AUDIO_PLAYER_CONFIG))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_release_app_audio_for_shutdown()


func _unhandled_input(event: InputEvent) -> void:
	if not _skip_unlocked or _transition_started:
		return
	if not _is_skip_input(event):
		return

	get_viewport().set_input_as_handled()
	skip_to_main_menu()


func _refresh_ui() -> void:
	var chip_label: Label = get_node_or_null("Margin/Center/Panel/VBox/ChipCard/ChipLabel") as Label
	if chip_label != null:
		chip_label.text = _presenter.build_chip_text()

	var title_label: Label = get_node_or_null("Margin/Center/Panel/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.text = _presenter.build_title_text()

	var mood_label: Label = get_node_or_null("Margin/Center/Panel/VBox/MoodLabel") as Label
	if mood_label != null:
		mood_label.text = _presenter.build_mood_text()

	var detail_label: Label = get_node_or_null("Margin/Center/Panel/VBox/DetailLabel") as Label
	if detail_label != null:
		detail_label.text = _presenter.build_detail_text()

	var hint_label: Label = get_node_or_null("Margin/Center/Panel/VBox/HintLabel") as Label
	if hint_label != null:
		hint_label.text = _presenter.build_continue_hint_text()


func _apply_temp_theme() -> void:
	TempScreenThemeScript.apply_panel(
		get_node_or_null("Margin/Center/Panel") as PanelContainer,
		TempScreenThemeScript.PANEL_BORDER_COLOR,
		22,
		0.9
	)
	TempScreenThemeScript.apply_chip(
		get_node_or_null("Margin/Center/Panel/VBox/ChipCard") as PanelContainer,
		get_node_or_null("Margin/Center/Panel/VBox/ChipCard/ChipLabel") as Label,
		TempScreenThemeScript.TEAL_ACCENT_COLOR
	)
	SceneLayoutHelperScript.apply_label_tones(self, [
		{"path": "Margin/Center/Panel/VBox/TitleLabel", "tone": "title"},
		{"path": "Margin/Center/Panel/VBox/MoodLabel", "tone": "accent"},
		{"path": "Margin/Center/Panel/VBox/DetailLabel", "tone": "body"},
		{"path": "Margin/Center/Panel/VBox/HintLabel", "tone": "muted"},
	])
	SceneLayoutHelperScript.apply_control_overrides(self, {}, [
		{"path": "Margin/Center/Panel/VBox/TitleLabel", "font_size": 46},
		{"path": "Margin/Center/Panel/VBox/MoodLabel", "font_size": 22},
		{"path": "Margin/Center/Panel/VBox/DetailLabel", "font_size": 18},
	])


func _apply_portrait_safe_layout() -> void:
	var values: Dictionary = SceneLayoutHelperScript.apply_portrait_layout(self, PORTRAIT_LAYOUT_CONFIG)
	if values.is_empty():
		return
	values["panel_width"] = min(float(values.get("safe_width", 0.0)), float(values.get("panel_width", 0.0)))
	SceneLayoutHelperScript.apply_control_overrides(self, values, [
		{"path": "Margin/Center/Panel", "custom_minimum_size": {"x": "panel_width", "y": 0.0}},
		{"path": "Margin/Center/Panel/VBox", "theme_constants": {"separation": "vbox_separation"}},
		{"path": "Margin/Center/Panel/VBox/TitleLabel", "font_size": "title_font_size"},
		{"path": "Margin/Center/Panel/VBox/MoodLabel", "font_size": "mood_font_size"},
		{"path": "Margin/Center/Panel/VBox/DetailLabel", "font_size": "body_font_size"},
		{"path": "Margin/Center/Panel/VBox/HintLabel", "font_size": "hint_font_size"},
	])


func _play_open_tween() -> void:
	var panel: Control = get_node_or_null("Margin/Center/Panel") as Control
	if panel == null:
		return

	panel.modulate = Color(1, 1, 1, 0)
	var tween: Tween = create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.22)


func _unlock_skip() -> void:
	if _transition_started:
		return

	_skip_unlocked = true
	var hint_label: Label = get_node_or_null("Margin/Center/Panel/VBox/HintLabel") as Label
	if hint_label == null:
		return

	hint_label.visible = true
	hint_label.modulate = Color(1, 1, 1, 0)
	var tween: Tween = create_tween()
	tween.tween_property(hint_label, "modulate", Color(1, 1, 1, 1), 0.14)


func _on_auto_continue_timeout() -> void:
	_begin_transition(false)


func skip_to_main_menu() -> void:
	_begin_transition(true)


func _begin_transition(play_confirm: bool) -> void:
	if _transition_started:
		return

	_transition_started = true
	if play_confirm:
		SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
		get_tree().create_timer(UI_TRANSITION_LEAD_IN_SECONDS).timeout.connect(Callable(self, "_finalize_main_menu_transition"))
		return

	_finalize_main_menu_transition()


func _finalize_main_menu_transition() -> void:
	if _bootstrap != null:
		_bootstrap.finish_boot_to_main_menu()


func _is_skip_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		return key_event.pressed and not key_event.echo
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false


func _release_app_audio_for_shutdown() -> void:
	if not is_inside_tree():
		return
	var tree: SceneTree = get_tree()
	SceneAudioCleanupScript.release_all_audio_players(tree.root)


func _is_playtest_launch_smoke_requested() -> bool:
	return OS.get_cmdline_args().has(PLAYTEST_LAUNCH_SMOKE_ARG)


func _quit_for_playtest_launch_smoke() -> void:
	if not is_inside_tree():
		return
	await get_tree().create_timer(PLAYTEST_LAUNCH_SMOKE_QUIT_DELAY_SECONDS).timeout
	if not is_inside_tree():
		return
	_release_app_audio_for_shutdown()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
