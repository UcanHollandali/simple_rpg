# Layer: Scenes - presentation only
# Keep SupportInteraction as a real runtime-backed non-combat decision screen.
# Do not collapse this scene back into an immediate-return placeholder.
extends Control

const BUTTON_NODE_NAMES: PackedStringArray = ["ActionAButton", "ActionBButton", "ActionCButton"]
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const SafeMenuOverlayScript = preload("res://Game/UI/safe_menu_overlay.gd")
const SupportInteractionPresenterScript = preload("res://Game/UI/support_interaction_presenter.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UI_CONFIRM_SFX = preload("res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg")
const PANEL_OPEN_SFX = preload("res://Assets/Audio/SFX/sfx_panel_open_01.ogg")
const PANEL_CLOSE_SFX = preload("res://Assets/Audio/SFX/sfx_panel_close_01.ogg")
const SUPPORT_MUSIC_LOOP = preload("res://Assets/Audio/Music/music_ui_hub_loop_temp_01.ogg")
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const AUDIO_PLAYER_NODE_NAMES: Array[String] = [
	"UiConfirmSfxPlayer",
	"PanelOpenSfxPlayer",
	"PanelCloseSfxPlayer",
	"SupportMusicPlayer",
]

var _bootstrap
var _presenter: SupportInteractionPresenter
var _support_state: SupportInteractionState
var _safe_menu: SafeMenuOverlay


func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_presenter = SupportInteractionPresenterScript.new()
	_support_state = null
	_configure_audio_players()
	if _bootstrap != null:
		_support_state = _bootstrap.get_support_interaction_state()

	_connect_buttons()
	_apply_temp_theme()
	_setup_safe_menu()
	_render_support_state()
	_start_looping_audio_player("SupportMusicPlayer")
	_play_audio_player("PanelOpenSfxPlayer")


func _exit_tree() -> void:
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


func _on_action_pressed(index: int) -> void:
	if _bootstrap == null or _support_state == null:
		return
	if index < 0 or index >= _support_state.offers.size():
		return

	var offer: Dictionary = _support_state.offers[index]
	var offer_id: String = String(offer.get("offer_id", ""))
	if offer_id.is_empty():
		return

	_play_audio_player("UiConfirmSfxPlayer")
	_bootstrap.choose_support_action(offer_id)
	_support_state = _bootstrap.get_support_interaction_state()
	_render_support_state()


func _on_leave_pressed() -> void:
	if _bootstrap == null:
		return
	_play_audio_player("PanelCloseSfxPlayer")
	await _wait_for_ui_transition_lead_in("PanelCloseSfxPlayer")
	_bootstrap.choose_support_action("leave")


func _connect_buttons() -> void:
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = get_node_or_null("Margin/VBox/ActionsRow/%s" % BUTTON_NODE_NAMES[index]) as Button
		if button == null:
			continue
		var handler: Callable = Callable(self, "_on_action_pressed").bind(index)
		if not button.is_connected("pressed", handler):
			button.connect("pressed", handler)

	var leave_button: Button = get_node_or_null("Margin/VBox/FooterRow/LeaveButton") as Button
	if leave_button != null and not leave_button.is_connected("pressed", Callable(self, "_on_leave_pressed")):
		leave_button.connect("pressed", Callable(self, "_on_leave_pressed"))


func _render_support_state() -> void:
	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	var summary_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/SummaryLabel") as Label
	var status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/StatusLabel") as Label

	if title_label != null:
		title_label.text = _presenter.build_title_text(_support_state)
	if summary_label != null:
		summary_label.text = _presenter.build_summary_text(_support_state)

	var run_state: RunState = _get_run_state()
	if status_label != null:
		status_label.text = _presenter.build_run_status_text(run_state)

	var button_models: Array[Dictionary] = _presenter.build_action_view_models(_support_state, BUTTON_NODE_NAMES.size())
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = get_node_or_null("Margin/VBox/ActionsRow/%s" % BUTTON_NODE_NAMES[index]) as Button
		if button == null:
			continue

		var model: Dictionary = button_models[index]
		button.text = String(model.get("text", ""))
		button.visible = bool(model.get("visible", false))
		button.disabled = bool(model.get("disabled", true))

	_refresh_save_controls()


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


func _get_run_state() -> RunState:
	if _bootstrap == null:
		return null
	return _bootstrap.get_run_state()


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

	var music_player: AudioStreamPlayer = get_node_or_null("SupportMusicPlayer") as AudioStreamPlayer
	if music_player != null:
		music_player.stream = SUPPORT_MUSIC_LOOP
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
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/SummaryLabel") as Label, "accent")
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 18, 0.9)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/StatusLabel") as Label)

	for button_name in BUTTON_NODE_NAMES:
		TempScreenThemeScript.apply_button(get_node_or_null("Margin/VBox/ActionsRow/%s" % button_name) as Button, TempScreenThemeScript.TEAL_ACCENT_COLOR)

	TempScreenThemeScript.apply_button(get_node_or_null("Margin/VBox/FooterRow/LeaveButton") as Button, TempScreenThemeScript.RUST_ACCENT_COLOR, true)

	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 28)

	var summary_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/SummaryLabel") as Label
	if summary_label != null:
		summary_label.add_theme_font_size_override("font_size", 16)

	var run_status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/StatusLabel") as Label
	if run_status_label != null:
		run_status_label.add_theme_font_size_override("font_size", 16)

	for button_name in BUTTON_NODE_NAMES:
		var action_button: Button = get_node_or_null("Margin/VBox/ActionsRow/%s" % button_name) as Button
		if action_button != null:
			action_button.add_theme_font_size_override("font_size", 16)

	var leave_button: Button = get_node_or_null("Margin/VBox/FooterRow/LeaveButton") as Button
	if leave_button != null:
		leave_button.add_theme_font_size_override("font_size", 16)


func _setup_safe_menu() -> void:
	if _safe_menu != null:
		return

	_safe_menu = SafeMenuOverlayScript.new()
	_safe_menu.name = "SafeMenuOverlay"
	_safe_menu.configure("Run Tools", "Save or load without crowding camp and merchant choices.", "Tools")
	add_child(_safe_menu)
	_safe_menu.save_requested.connect(Callable(self, "_on_save_pressed"))
	_safe_menu.load_requested.connect(Callable(self, "_on_load_pressed"))
