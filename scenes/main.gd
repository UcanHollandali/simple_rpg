# Layer: Scenes - presentation only
extends Control

const LaunchIntroPresenterScript = preload("res://Game/UI/launch_intro_presenter.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UI_CONFIRM_SFX_PATH := "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"
const PANEL_OPEN_SFX_PATH := "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"
const INTRO_MUSIC_LOOP_PATH := "res://Assets/Audio/Music/music_ui_hub_loop_temp_01.ogg"
const MIN_SKIP_DELAY_SECONDS := 0.18
const AUTO_CONTINUE_SECONDS := 1.45
const UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const PLAYTEST_LAUNCH_SMOKE_ARG := "--playtest-launch-smoke"
const PLAYTEST_LAUNCH_SMOKE_QUIT_DELAY_SECONDS := 0.35
const AUDIO_PLAYER_NODE_NAMES: Array[String] = [
	"UiConfirmSfxPlayer",
	"PanelOpenSfxPlayer",
	"IntroMusicPlayer",
]

var _bootstrap
var _presenter: LaunchIntroPresenter
var _skip_unlocked: bool = false
var _transition_started: bool = false


func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_presenter = LaunchIntroPresenterScript.new()
	_configure_audio_players()
	_apply_temp_theme()
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
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


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


func _configure_audio_players() -> void:
	SceneAudioPlayersScript.assign_stream_from_path(self, "UiConfirmSfxPlayer", UI_CONFIRM_SFX_PATH)
	SceneAudioPlayersScript.assign_stream_from_path(self, "PanelOpenSfxPlayer", PANEL_OPEN_SFX_PATH)
	SceneAudioPlayersScript.assign_music_stream_from_path(self, "IntroMusicPlayer", INTRO_MUSIC_LOOP_PATH, true)


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
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/Panel/VBox/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/Panel/VBox/MoodLabel") as Label, "accent")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/Panel/VBox/DetailLabel") as Label)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/Panel/VBox/HintLabel") as Label, "muted")

	var title_label: Label = get_node_or_null("Margin/Center/Panel/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 46)

	var mood_label: Label = get_node_or_null("Margin/Center/Panel/VBox/MoodLabel") as Label
	if mood_label != null:
		mood_label.add_theme_font_size_override("font_size", 22)

	var detail_label: Label = get_node_or_null("Margin/Center/Panel/VBox/DetailLabel") as Label
	if detail_label != null:
		detail_label.add_theme_font_size_override("font_size", 18)


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
