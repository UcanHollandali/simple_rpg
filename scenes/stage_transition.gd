# Layer: Scenes - presentation only
# Keep StageTransition as a real interstitial screen with explicit continue/save/load behavior.
# Do not collapse this scene back into an automatic map return.
extends Control

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const SafeMenuOverlayScript = preload("res://Game/UI/safe_menu_overlay.gd")
const StageTransitionPresenterScript = preload("res://Game/UI/stage_transition_presenter.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UI_CONFIRM_SFX = preload("res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg")
const PANEL_OPEN_SFX = preload("res://Assets/Audio/SFX/sfx_panel_open_01.ogg")
const PANEL_CLOSE_SFX = preload("res://Assets/Audio/SFX/sfx_panel_close_01.ogg")
const STAGE_TRANSITION_MUSIC_LOOP = preload("res://Assets/Audio/Music/music_ui_hub_loop_temp_01.ogg")
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const AUDIO_PLAYER_NODE_NAMES: Array[String] = [
	"UiConfirmSfxPlayer",
	"PanelOpenSfxPlayer",
	"PanelCloseSfxPlayer",
	"StageTransitionMusicPlayer",
]

var _bootstrap
var _presenter: StageTransitionPresenter
var _safe_menu: SafeMenuOverlay


func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_presenter = StageTransitionPresenterScript.new()
	_configure_audio_players()
	_connect_buttons()
	_apply_temp_theme()
	_setup_safe_menu()
	_refresh_ui()
	_start_looping_audio_player("StageTransitionMusicPlayer")
	_play_audio_player("PanelOpenSfxPlayer")


func _exit_tree() -> void:
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


func _on_continue_pressed() -> void:
	var flow_manager: GameFlowManager = _get_flow_manager()
	if flow_manager == null:
		return
	_play_audio_player("PanelCloseSfxPlayer")
	await _wait_for_ui_transition_lead_in("PanelCloseSfxPlayer")
	flow_manager.request_transition(FlowStateScript.Type.MAP_EXPLORE)


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


func _connect_buttons() -> void:
	var continue_button: Button = get_node_or_null("Margin/Center/ContentCard/VBox/ContinueButton") as Button
	if continue_button != null and not continue_button.is_connected("pressed", Callable(self, "_on_continue_pressed")):
		continue_button.connect("pressed", Callable(self, "_on_continue_pressed"))


func _refresh_ui() -> void:
	var title_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/TitleLabel") as Label
	var summary_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/SummaryLabel") as Label
	_set_status_text("")

	var stage_index: int = 0
	if _bootstrap != null:
		var run_state: RunState = _bootstrap.get_run_state()
		if run_state != null:
			stage_index = int(run_state.stage_index)

	if title_label != null:
		title_label.text = _presenter.build_title_text()
	if summary_label != null:
		summary_label.text = _presenter.build_summary_text(stage_index)

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

	var panel_open_player: AudioStreamPlayer = get_node_or_null("PanelOpenSfxPlayer") as AudioStreamPlayer
	if panel_open_player != null:
		panel_open_player.stream = PANEL_OPEN_SFX

	var panel_close_player: AudioStreamPlayer = get_node_or_null("PanelCloseSfxPlayer") as AudioStreamPlayer
	if panel_close_player != null:
		panel_close_player.stream = PANEL_CLOSE_SFX

	var music_player: AudioStreamPlayer = get_node_or_null("StageTransitionMusicPlayer") as AudioStreamPlayer
	if music_player != null:
		music_player.stream = STAGE_TRANSITION_MUSIC_LOOP
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
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/Center/ContentCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 22, 0.92)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/ContentCard/VBox/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/ContentCard/VBox/SummaryLabel") as Label, "accent")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/ContentCard/VBox/StatusLabel") as Label)
	TempScreenThemeScript.apply_button(get_node_or_null("Margin/Center/ContentCard/VBox/ContinueButton") as Button, TempScreenThemeScript.TEAL_ACCENT_COLOR)

	var title_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 32)

	var summary_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/SummaryLabel") as Label
	if summary_label != null:
		summary_label.add_theme_font_size_override("font_size", 19)

	var status_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 17)

	var continue_button: Button = get_node_or_null("Margin/Center/ContentCard/VBox/ContinueButton") as Button
	if continue_button != null:
		continue_button.add_theme_font_size_override("font_size", 17)


func _setup_safe_menu() -> void:
	if _safe_menu != null:
		return

	_safe_menu = SafeMenuOverlayScript.new()
	_safe_menu.name = "SafeMenuOverlay"
	_safe_menu.configure("Run Tools", "Save or load without interrupting the stage handoff.", "Tools")
	add_child(_safe_menu)
	_safe_menu.save_requested.connect(Callable(self, "_on_save_pressed"))
	_safe_menu.load_requested.connect(Callable(self, "_on_load_pressed"))
