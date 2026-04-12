# Layer: Scenes - presentation only
extends Control

const BUTTON_NODE_NAMES: PackedStringArray = ["ChoiceAButton", "ChoiceBButton", "ChoiceCButton"]
const LevelUpPresenterScript = preload("res://Game/UI/level_up_presenter.gd")
const SafeMenuOverlayScript = preload("res://Game/UI/safe_menu_overlay.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UI_CONFIRM_SFX = preload("res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg")
const PANEL_OPEN_SFX = preload("res://Assets/Audio/SFX/sfx_panel_open_01.ogg")
const LEVEL_UP_MUSIC_LOOP = preload("res://Assets/Audio/Music/music_ui_hub_loop_temp_01.ogg")
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const AUDIO_PLAYER_NODE_NAMES: Array[String] = [
	"UiConfirmSfxPlayer",
	"PanelOpenSfxPlayer",
	"LevelUpMusicPlayer",
]

var _bootstrap
var _presenter: LevelUpPresenter
var _level_up_state: LevelUpState
var _safe_menu: SafeMenuOverlay

func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_presenter = LevelUpPresenterScript.new()
	_level_up_state = null
	_configure_audio_players()
	if _bootstrap != null:
		_level_up_state = _bootstrap.get_level_up_state()

	_connect_buttons()
	_apply_temp_theme()
	_setup_safe_menu()
	_render_level_up_state()
	_play_audio_player("PanelOpenSfxPlayer")
	_start_looping_audio_player("LevelUpMusicPlayer")


func _exit_tree() -> void:
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


func _on_offer_pressed(index: int) -> void:
	if _bootstrap == null or _level_up_state == null:
		return
	if index < 0 or index >= _level_up_state.offers.size():
		return

	var offer: Dictionary = _level_up_state.offers[index]
	var offer_id: String = String(offer.get("offer_id", ""))
	if offer_id.is_empty():
		return

	_play_audio_player("UiConfirmSfxPlayer")
	await _wait_for_ui_transition_lead_in("UiConfirmSfxPlayer")
	_bootstrap.choose_level_up_option(offer_id)


func _on_save_pressed() -> void:
	if _bootstrap == null:
		return
	_play_audio_player("UiConfirmSfxPlayer")
	var save_result: Dictionary = _bootstrap.save_game()
	if _safe_menu != null:
		_safe_menu.set_status_text(_presenter.build_save_status_text(save_result))
	_refresh_save_controls()


func _on_load_pressed() -> void:
	if _bootstrap == null:
		return
	_play_audio_player("UiConfirmSfxPlayer")
	var load_result: Dictionary = _bootstrap.load_game()
	if bool(load_result.get("ok", false)):
		return
	if _safe_menu != null:
		_safe_menu.set_status_text(_presenter.build_load_status_text(load_result))
	_refresh_save_controls()


func _connect_buttons() -> void:
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = get_node_or_null("Margin/VBox/ChoicesRow/%s" % BUTTON_NODE_NAMES[index]) as Button
		if button == null:
			continue
		var handler: Callable = Callable(self, "_on_offer_pressed").bind(index)
		if not button.is_connected("pressed", handler):
			button.connect("pressed", handler)


func _render_level_up_state() -> void:
	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	var note_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/NoteLabel") as Label
	_set_status_text(_presenter.build_initial_status_text())
	if title_label != null:
		title_label.text = _presenter.build_title_text(_level_up_state)
	if note_label != null:
		note_label.text = _presenter.build_note_text(_level_up_state)

	var button_models: Array[Dictionary] = _presenter.build_offer_view_models(_level_up_state, BUTTON_NODE_NAMES.size())
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = get_node_or_null("Margin/VBox/ChoicesRow/%s" % BUTTON_NODE_NAMES[index]) as Button
		if button == null:
			continue
		var model: Dictionary = button_models[index]
		button.text = String(model.get("text", ""))
		button.visible = bool(model.get("visible", false))
		button.disabled = bool(model.get("disabled", true))

	_refresh_save_controls()


func _set_status_text(text: String) -> void:
	var status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/StatusCard/StatusLabel") as Label
	if status_label != null:
		status_label.text = text


func _refresh_save_controls() -> void:
	if _safe_menu == null:
		return
	var has_save: bool = _bootstrap != null and _bootstrap.has_save_game()
	_safe_menu.set_load_available(_presenter != null and not _presenter.build_load_button_disabled(has_save))


func _configure_audio_players() -> void:
	var ui_confirm_player: AudioStreamPlayer = get_node_or_null("UiConfirmSfxPlayer") as AudioStreamPlayer
	if ui_confirm_player != null:
		ui_confirm_player.stream = UI_CONFIRM_SFX

	var panel_open_player: AudioStreamPlayer = get_node_or_null("PanelOpenSfxPlayer") as AudioStreamPlayer
	if panel_open_player != null:
		panel_open_player.stream = PANEL_OPEN_SFX

	var music_player: AudioStreamPlayer = get_node_or_null("LevelUpMusicPlayer") as AudioStreamPlayer
	if music_player != null:
		music_player.stream = LEVEL_UP_MUSIC_LOOP
		var music_stream: AudioStreamOggVorbis = music_player.stream as AudioStreamOggVorbis
		if music_stream != null:
			music_stream.loop = true


func _play_audio_player(node_path: String) -> void:
	var player: AudioStreamPlayer = get_node_or_null(node_path) as AudioStreamPlayer
	if player != null and player.stream != null:
		player.play()


func _start_looping_audio_player(node_path: String) -> void:
	var player: AudioStreamPlayer = get_node_or_null(node_path) as AudioStreamPlayer
	if player != null and player.stream != null and not player.playing:
		player.play()


func _wait_for_ui_transition_lead_in(node_path: String) -> void:
	var player: AudioStreamPlayer = get_node_or_null(node_path) as AudioStreamPlayer
	if player == null or player.stream == null:
		return
	await get_tree().create_timer(ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS).timeout


func _apply_temp_theme() -> void:
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/NoteLabel") as Label, "accent")
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/HeaderRow/StatusCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 18, 0.88)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/StatusCard/StatusLabel") as Label, "muted")

	for button_name in BUTTON_NODE_NAMES:
		TempScreenThemeScript.apply_button(get_node_or_null("Margin/VBox/ChoicesRow/%s" % button_name) as Button, TempScreenThemeScript.REWARD_ACCENT_COLOR)

	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 28)

	var note_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/NoteLabel") as Label
	if note_label != null:
		note_label.add_theme_font_size_override("font_size", 16)

	var status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/StatusCard/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 15)

	for button_name in BUTTON_NODE_NAMES:
		var action_button: Button = get_node_or_null("Margin/VBox/ChoicesRow/%s" % button_name) as Button
		if action_button != null:
			action_button.add_theme_font_size_override("font_size", 16)


func _setup_safe_menu() -> void:
	if _safe_menu != null:
		return

	_safe_menu = SafeMenuOverlayScript.new()
	_safe_menu.name = "SafeMenuOverlay"
	_safe_menu.configure("Run Tools", "Save or load without mixing utility with passive choices.", "Tools")
	add_child(_safe_menu)
	_safe_menu.save_requested.connect(Callable(self, "_on_save_pressed"))
	_safe_menu.load_requested.connect(Callable(self, "_on_load_pressed"))
