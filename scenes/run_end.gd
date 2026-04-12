# Layer: Scenes - presentation only
extends Control

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const SafeMenuOverlayScript = preload("res://Game/UI/safe_menu_overlay.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UI_CONFIRM_SFX = preload("res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg")
const UI_CANCEL_SFX = preload("res://Assets/Audio/SFX/sfx_ui_cancel_01.ogg")
const PANEL_OPEN_SFX = preload("res://Assets/Audio/SFX/sfx_panel_open_01.ogg")
const RUN_END_MUSIC_LOOP = preload("res://Assets/Audio/Music/music_run_end_loop_temp_01.ogg")
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const AUDIO_PLAYER_NODE_NAMES: Array[String] = [
	"UiConfirmSfxPlayer",
	"UiCancelSfxPlayer",
	"PanelOpenSfxPlayer",
	"RunEndMusicPlayer",
]

var _bootstrap
var _safe_menu: SafeMenuOverlay


func _ready() -> void:
	var result_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/ResultLabel") as Label
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_configure_audio_players()
	if result_label != null and _bootstrap != null:
		result_label.text = "Result: %s" % String(_bootstrap.get_last_run_result())

	var return_button: Button = get_node_or_null("Margin/Center/ContentCard/VBox/ReturnButton") as Button
	if return_button != null and not return_button.is_connected("pressed", Callable(self, "_on_return_pressed")):
		return_button.connect("pressed", Callable(self, "_on_return_pressed"))

	_apply_temp_theme()
	_setup_safe_menu()
	_set_status_text("")
	_refresh_save_controls()
	_start_looping_audio_player("RunEndMusicPlayer")
	_play_audio_player("PanelOpenSfxPlayer")


func _exit_tree() -> void:
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


func _on_return_pressed() -> void:
	var flow_manager: GameFlowManager = _get_flow_manager()
	if flow_manager == null:
		return
	_play_audio_player("UiCancelSfxPlayer")
	await _wait_for_ui_transition_lead_in("UiCancelSfxPlayer")
	flow_manager.request_transition(FlowStateScript.Type.MAIN_MENU)


func _on_save_pressed() -> void:
	if _bootstrap == null:
		return
	_play_audio_player("UiConfirmSfxPlayer")
	var save_result: Dictionary = _bootstrap.save_game()
	if _safe_menu != null:
		_safe_menu.set_status_text("Run saved." if bool(save_result.get("ok", false)) else "Save failed: %s" % String(save_result.get("error", "unknown")))
	_refresh_save_controls()


func _on_load_pressed() -> void:
	if _bootstrap == null:
		return
	_play_audio_player("UiConfirmSfxPlayer")
	var load_result: Dictionary = _bootstrap.load_game()
	if bool(load_result.get("ok", false)):
		return
	if _safe_menu != null:
		_safe_menu.set_status_text("Load failed: %s" % String(load_result.get("error", "unknown")))
	_refresh_save_controls()


func _refresh_save_controls() -> void:
	if _safe_menu == null:
		return
	_safe_menu.set_load_available(_bootstrap != null and _bootstrap.has_save_game())


func _set_status_text(text: String) -> void:
	var status_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/StatusLabel") as Label
	if status_label != null:
		status_label.text = text
		status_label.visible = not text.is_empty()


func _get_flow_manager() -> GameFlowManager:
	if _bootstrap == null:
		return null
	return _bootstrap.get_flow_manager()


func _configure_audio_players() -> void:
	var ui_confirm_player: AudioStreamPlayer = get_node_or_null("UiConfirmSfxPlayer") as AudioStreamPlayer
	if ui_confirm_player != null:
		ui_confirm_player.stream = UI_CONFIRM_SFX

	var ui_cancel_player: AudioStreamPlayer = get_node_or_null("UiCancelSfxPlayer") as AudioStreamPlayer
	if ui_cancel_player != null:
		ui_cancel_player.stream = UI_CANCEL_SFX

	var panel_open_player: AudioStreamPlayer = get_node_or_null("PanelOpenSfxPlayer") as AudioStreamPlayer
	if panel_open_player != null:
		panel_open_player.stream = PANEL_OPEN_SFX

	var music_player: AudioStreamPlayer = get_node_or_null("RunEndMusicPlayer") as AudioStreamPlayer
	if music_player != null:
		music_player.stream = RUN_END_MUSIC_LOOP
		var music_stream: AudioStreamOggVorbis = music_player.stream as AudioStreamOggVorbis
		if music_stream != null:
			music_stream.loop = true


func _play_audio_player(node_path: String) -> void:
	var player: AudioStreamPlayer = get_node_or_null(node_path) as AudioStreamPlayer
	if player != null and player.stream != null:
		player.play()


func _wait_for_ui_transition_lead_in(node_path: String) -> void:
	var player: AudioStreamPlayer = get_node_or_null(node_path) as AudioStreamPlayer
	if player == null or player.stream == null:
		return
	await get_tree().create_timer(ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS).timeout


func _start_looping_audio_player(node_path: String) -> void:
	var player: AudioStreamPlayer = get_node_or_null(node_path) as AudioStreamPlayer
	if player != null and player.stream != null and not player.playing:
		player.play()


func _apply_temp_theme() -> void:
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/Center/ContentCard") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 22, 0.92)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/ContentCard/VBox/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/ContentCard/VBox/ResultLabel") as Label, "danger")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/ContentCard/VBox/StatusLabel") as Label)
	TempScreenThemeScript.apply_button(get_node_or_null("Margin/Center/ContentCard/VBox/ReturnButton") as Button, TempScreenThemeScript.RUST_ACCENT_COLOR, true)

	var title_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 32)

	var result_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/ResultLabel") as Label
	if result_label != null:
		result_label.add_theme_font_size_override("font_size", 19)

	var status_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 17)

	var return_button: Button = get_node_or_null("Margin/Center/ContentCard/VBox/ReturnButton") as Button
	if return_button != null:
		return_button.add_theme_font_size_override("font_size", 17)


func _setup_safe_menu() -> void:
	if _safe_menu != null:
		return

	_safe_menu = SafeMenuOverlayScript.new()
	_safe_menu.name = "SafeMenuOverlay"
	_safe_menu.configure("Run Tools", "Save or load from the run-end screen without crowding the result.", "Tools")
	add_child(_safe_menu)
	_safe_menu.save_requested.connect(Callable(self, "_on_save_pressed"))
	_safe_menu.load_requested.connect(Callable(self, "_on_load_pressed"))
