# Layer: Scenes - presentation only
extends Control

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const MainMenuPresenterScript = preload("res://Game/UI/main_menu_presenter.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UI_CONFIRM_SFX_PATH := "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"
const PANEL_OPEN_SFX_PATH := "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"
const MAIN_MENU_MUSIC_LOOP_PATH := "res://Assets/Audio/Music/music_ui_hub_loop_temp_01.ogg"
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const PORTRAIT_SAFE_MAX_WIDTH := 940
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 32
const RESOLUTION_OPTION_PATH := "Margin/VBox/ActionPanel/ActionVBox/ResolutionOption"
const FULLSCREEN_TOGGLE_PATH := "Margin/VBox/ActionPanel/ActionVBox/FullscreenToggle"
const AUDIO_PLAYER_NODE_NAMES: Array[String] = [
	"UiConfirmSfxPlayer",
	"PanelOpenSfxPlayer",
	"MainMenuMusicPlayer",
]

var _bootstrap
var _presenter: MainMenuPresenter


func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_presenter = MainMenuPresenterScript.new()
	_configure_audio_players()
	_soften_backdrop()
	_apply_temp_theme()
	_connect_viewport_layout_updates()
	_apply_portrait_safe_layout()
	_configure_resolution_selector()
	_configure_fullscreen_toggle()
	var start_button: Button = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/StartRunButton") as Button
	var load_button: Button = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/LoadRunButton") as Button
	if start_button != null and not start_button.is_connected("pressed", Callable(self, "_on_start_run_pressed")):
		start_button.connect("pressed", Callable(self, "_on_start_run_pressed"))
	if load_button != null and not load_button.is_connected("pressed", Callable(self, "_on_load_run_pressed")):
		load_button.connect("pressed", Callable(self, "_on_load_run_pressed"))
	_refresh_ui()
	SceneAudioPlayersScript.start_looping(self, "MainMenuMusicPlayer")
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")


func _exit_tree() -> void:
	_disconnect_viewport_layout_updates()
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_release_app_audio_for_shutdown()


func _on_start_run_pressed() -> void:
	var flow_manager: GameFlowManager = _get_flow_manager()
	if flow_manager == null:
		return

	SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
	await SceneAudioPlayersScript.wait_for_lead_in(self, "UiConfirmSfxPlayer", ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS)
	flow_manager.request_transition(FlowStateScript.Type.RUN_SETUP)


func _on_load_run_pressed() -> void:
	if _bootstrap == null:
		return

	SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
	var load_result: Dictionary = _bootstrap.load_game()
	if bool(load_result.get("ok", false)):
		return

	var status_label: Label = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/StatusLabel") as Label
	if status_label != null:
		status_label.text = RunMenuSceneHelperScript.build_load_failure_status_text(load_result)


func _on_resolution_option_selected(index: int) -> void:
	if _bootstrap == null:
		return
	var result: Dictionary = _bootstrap.apply_resolution_by_index(index)
	_set_status_text(_build_resolution_status_text(result))
	_refresh_display_controls()


func _on_fullscreen_toggled(toggled: bool) -> void:
	if _bootstrap == null:
		return
	var result: Dictionary = _bootstrap.apply_fullscreen_mode(toggled)
	_set_status_text(_build_fullscreen_status_text(result))
	_refresh_display_controls()


func _configure_resolution_selector() -> void:
	var resolution_option: OptionButton = get_node_or_null(RESOLUTION_OPTION_PATH) as OptionButton
	if resolution_option == null:
		return

	if _bootstrap == null:
		resolution_option.disabled = true
		return

	var options: Array[String] = _bootstrap.get_supported_resolution_options()
	resolution_option.clear()
	for option_index in range(options.size()):
		resolution_option.add_item(options[option_index], option_index)
	resolution_option.select(_resolve_option_index(_bootstrap.get_active_resolution_index()))

	var selected_signal := Callable(self, "_on_resolution_option_selected")
	if not resolution_option.is_connected("item_selected", selected_signal):
		resolution_option.connect("item_selected", selected_signal)


func _configure_fullscreen_toggle() -> void:
	var fullscreen_toggle: CheckButton = get_node_or_null(FULLSCREEN_TOGGLE_PATH) as CheckButton
	if fullscreen_toggle == null:
		return
	fullscreen_toggle.visible = false

	if _bootstrap == null:
		fullscreen_toggle.disabled = true
		return

	fullscreen_toggle.text = "Tam Ekran"
	fullscreen_toggle.set_pressed_no_signal(_bootstrap.is_fullscreen_enabled())

	var fullscreen_signal := Callable(self, "_on_fullscreen_toggled")
	if not fullscreen_toggle.is_connected("toggled", fullscreen_signal):
		fullscreen_toggle.connect("toggled", fullscreen_signal)


func _resolve_option_index(index: int) -> int:
	if _bootstrap == null:
		return 0
	var options: Array[String] = _bootstrap.get_supported_resolution_options()
	if options.is_empty():
		return 0
	return clamp(int(index), 0, options.size() - 1)


func _refresh_ui() -> void:
	var load_button: Button = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/LoadRunButton") as Button
	var start_button: Button = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/StartRunButton") as Button
	var has_save: bool = _bootstrap != null and _bootstrap.has_save_game()
	if load_button != null:
		load_button.disabled = not has_save
		load_button.text = "Load Saved Run"
	if start_button != null:
		start_button.text = "Start New Run"

	var title_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/TitleLabel") as Label
	_set_label_text(title_label, _presenter.build_title_text())

	var subtitle_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/SubtitleLabel") as Label
	_set_label_text(subtitle_label, _presenter.build_subtitle_text())

	var mood_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/MoodLabel") as Label
	_set_label_text(mood_label, _presenter.build_mood_text())

	var chip_row: VBoxContainer = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/ChipRow") as VBoxContainer
	if chip_row != null:
		chip_row.visible = true

	var playtest_chip_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/ChipRow/PlaytestChipCard/PlaytestChipLabel") as Label
	if playtest_chip_label != null:
		playtest_chip_label.text = _presenter.build_playtest_chip_text()

	var save_chip_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/ChipRow/SaveChipCard/SaveChipLabel") as Label
	if save_chip_label != null:
		save_chip_label.text = _presenter.build_save_chip_text(has_save)

	_apply_save_chip_theme(has_save)

	var playtest_read_label: Label = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/PlaytestReadLabel") as Label
	_set_label_text(playtest_read_label, _presenter.build_playtest_read_text(has_save))

	var flow_read_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/FlowReadLabel") as Label
	_set_label_text(flow_read_label, _presenter.build_flow_read_text())
	if flow_read_label != null:
		flow_read_label.visible = not flow_read_label.text.is_empty()

	var status_label: Label = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/StatusLabel") as Label
	_set_label_text(status_label, _presenter.build_status_text(has_save))
	_refresh_display_controls()


func _apply_temp_theme() -> void:
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/HeroPanel") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 20, 0.74)
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/ActionPanel") as PanelContainer, TempScreenThemeScript.REWARD_ACCENT_COLOR, 20, 0.97)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/SubtitleLabel") as Label, "reward")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/MoodLabel") as Label, "muted")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/PlaytestReadLabel") as Label)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/FlowReadLabel") as Label, "muted")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/StatusLabel") as Label, "muted")
	TempScreenThemeScript.apply_chip(
		get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/ChipRow/PlaytestChipCard") as PanelContainer,
		get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/ChipRow/PlaytestChipCard/PlaytestChipLabel") as Label,
		TempScreenThemeScript.TEAL_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_button(get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/StartRunButton") as Button)
	TempScreenThemeScript.apply_button(get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/LoadRunButton") as Button, TempScreenThemeScript.TEAL_ACCENT_COLOR, true)

	_refine_panel_style(get_node_or_null("Margin/VBox/HeroPanel") as PanelContainer, 1, 2, 18, 18, 14, 14)
	_refine_panel_style(get_node_or_null("Margin/VBox/ActionPanel") as PanelContainer, 1, 10, 18, 18, 16, 16)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/HeroPanel") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 3, 22, 0.03, 0.18, 20, 18)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/ActionPanel") as PanelContainer, TempScreenThemeScript.REWARD_ACCENT_COLOR, 3, 22, 0.03, 0.22, 20, 18)

	var title_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 72)

	var subtitle_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/SubtitleLabel") as Label
	if subtitle_label != null:
		subtitle_label.add_theme_font_size_override("font_size", 24)

	var mood_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/MoodLabel") as Label
	if mood_label != null:
		mood_label.add_theme_font_size_override("font_size", 22)

	var flow_read_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/FlowReadLabel") as Label
	if flow_read_label != null:
		flow_read_label.visible = true
		flow_read_label.add_theme_font_size_override("font_size", 18)

	var playtest_read_label: Label = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/PlaytestReadLabel") as Label
	if playtest_read_label != null:
		playtest_read_label.add_theme_font_size_override("font_size", 22)

	var status_label: Label = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 18)

	for button_path in [
		"Margin/VBox/ActionPanel/ActionVBox/StartRunButton",
		"Margin/VBox/ActionPanel/ActionVBox/LoadRunButton",
		"Margin/VBox/ActionPanel/ActionVBox/ResolutionOption",
		"Margin/VBox/ActionPanel/ActionVBox/FullscreenToggle",
	]:
		var action_button: Button = get_node_or_null(button_path) as Button
		if action_button != null:
			action_button.custom_minimum_size.y = max(action_button.custom_minimum_size.y, 78.0)
			action_button.add_theme_constant_override("icon_max_width", 32)
			action_button.add_theme_font_size_override("font_size", 22)


func _connect_viewport_layout_updates() -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var size_changed_handler := Callable(self, "_on_viewport_size_changed")
	if not viewport.is_connected("size_changed", size_changed_handler):
		viewport.connect("size_changed", size_changed_handler)


func _disconnect_viewport_layout_updates() -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var size_changed_handler := Callable(self, "_on_viewport_size_changed")
	if viewport.is_connected("size_changed", size_changed_handler):
		viewport.disconnect("size_changed", size_changed_handler)


func _on_viewport_size_changed() -> void:
	_apply_portrait_safe_layout()


func _apply_portrait_safe_layout() -> void:
	var margin: MarginContainer = get_node_or_null("Margin") as MarginContainer
	var vbox: VBoxContainer = get_node_or_null("Margin/VBox") as VBoxContainer
	var hero_panel: PanelContainer = get_node_or_null("Margin/VBox/HeroPanel") as PanelContainer
	var action_panel: PanelContainer = get_node_or_null("Margin/VBox/ActionPanel") as PanelContainer
	var top_spacer: Control = get_node_or_null("Margin/VBox/TopSpacer") as Control
	var bottom_spacer: Control = get_node_or_null("Margin/VBox/BottomSpacer") as Control
	if margin == null or vbox == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var top_margin: int = 44
	var bottom_margin: int = 40
	if viewport_size.y < 1720.0:
		top_margin = 34
		bottom_margin = 32
	if viewport_size.y < 1480.0:
		top_margin = 26
		bottom_margin = 24

	var safe_width: int = TempScreenThemeScript.apply_portrait_safe_margins(
		margin,
		PORTRAIT_SAFE_MAX_WIDTH,
		PORTRAIT_SAFE_MIN_SIDE_MARGIN,
		top_margin,
		bottom_margin
	)
	vbox.add_theme_constant_override("separation", 14 if viewport_size.y < 1520.0 else 18)

	var title_font_size: int = 78
	var subtitle_font_size: int = 24
	var mood_font_size: int = 22
	var body_font_size: int = 22
	var status_font_size: int = 18
	var button_font_size: int = 24
	var button_height: float = 84.0
	if safe_width < 860 or viewport_size.y < 1680.0:
		title_font_size = 68
		subtitle_font_size = 22
		mood_font_size = 20
		body_font_size = 20
		status_font_size = 17
		button_font_size = 22
		button_height = 76.0
	if safe_width < 720 or viewport_size.y < 1480.0:
		title_font_size = 58
		subtitle_font_size = 20
		mood_font_size = 18
		body_font_size = 18
		status_font_size = 16
		button_font_size = 20
		button_height = 68.0

	var title_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", title_font_size)

	var subtitle_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/SubtitleLabel") as Label
	if subtitle_label != null:
		subtitle_label.add_theme_font_size_override("font_size", subtitle_font_size)

	var mood_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/MoodLabel") as Label
	if mood_label != null:
		mood_label.add_theme_font_size_override("font_size", mood_font_size)

	var playtest_read_label: Label = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/PlaytestReadLabel") as Label
	if playtest_read_label != null:
		playtest_read_label.add_theme_font_size_override("font_size", body_font_size)

	var status_label: Label = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", status_font_size)

	for button_path in [
		"Margin/VBox/ActionPanel/ActionVBox/StartRunButton",
		"Margin/VBox/ActionPanel/ActionVBox/LoadRunButton",
	]:
		var action_button: Button = get_node_or_null(button_path) as Button
		if action_button == null:
			continue
		action_button.custom_minimum_size = Vector2(0.0, button_height)
		action_button.add_theme_font_size_override("font_size", button_font_size)
		action_button.add_theme_constant_override("icon_max_width", 32 if button_height >= 76.0 else 28)

	if hero_panel != null:
		hero_panel.size_flags_horizontal = Control.SIZE_FILL
		hero_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if action_panel != null:
		action_panel.size_flags_horizontal = Control.SIZE_FILL
		action_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if top_spacer != null:
		top_spacer.visible = true
		top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if bottom_spacer != null:
		bottom_spacer.visible = true
		bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _soften_backdrop() -> void:
	TempScreenThemeScript.apply_wayfinder_backdrop(self, 0.84, 0.30, 0.04, true)

	TempScreenThemeScript.apply_scrim(get_node_or_null("BackdropScrim") as ColorRect)


func _refine_panel_style(
	panel: PanelContainer,
	border_width: int,
	shadow_size: int,
	margin_x: int,
	margin_right: int,
	margin_top: int,
	margin_bottom: int
) -> void:
	if panel == null:
		return

	var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return

	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.shadow_size = shadow_size
	style.content_margin_left = margin_x
	style.content_margin_right = margin_right
	style.content_margin_top = margin_top
	style.content_margin_bottom = margin_bottom


func _set_label_text(label: Label, text: String) -> void:
	if label == null:
		return
	label.text = text
	label.visible = not text.is_empty()


func _set_status_text(text: String) -> void:
	var status_label: Label = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/StatusLabel") as Label
	_set_label_text(status_label, text)


func _refresh_display_controls() -> void:
	_configure_resolution_selector()
	_configure_fullscreen_toggle()


func _active_resolution_label() -> String:
	if _bootstrap == null:
		return "Resolution"
	var options: Array[String] = _bootstrap.get_supported_resolution_options()
	if options.is_empty():
		return "Resolution"
	return options[_resolve_option_index(_bootstrap.get_active_resolution_index())]


func _build_resolution_status_text(result: Dictionary) -> String:
	if not bool(result.get("ok", false)):
		return "Resolution change failed: %s" % String(result.get("error", "unknown"))
	var resolution_label: String = _active_resolution_label()
	if bool(result.get("deferred_until_windowed", false)):
		return "%s saved. It will apply after leaving fullscreen." % resolution_label
	var window_size: Vector2i = result.get("window_size", Vector2i.ZERO) as Vector2i
	if window_size.x > 0 and window_size.y > 0:
		return "%s applied at %dx%d." % [resolution_label, window_size.x, window_size.y]
	return "%s applied." % resolution_label


func _build_fullscreen_status_text(result: Dictionary) -> String:
	if not bool(result.get("ok", false)):
		return "Display mode change failed: %s" % String(result.get("error", "unknown"))
	return "Fullscreen enabled." if bool(result.get("fullscreen", false)) else "Windowed mode restored."


func _apply_save_chip_theme(has_save: bool) -> void:
	var accent: Color = TempScreenThemeScript.REWARD_ACCENT_COLOR if has_save else TempScreenThemeScript.RUST_ACCENT_COLOR
	TempScreenThemeScript.apply_chip(
		get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/ChipRow/SaveChipCard") as PanelContainer,
		get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/ChipRow/SaveChipCard/SaveChipLabel") as Label,
		accent
	)


func _get_flow_manager() -> GameFlowManager:
	if _bootstrap == null:
		return null
	return _bootstrap.get_flow_manager()


func _configure_audio_players() -> void:
	SceneAudioPlayersScript.assign_stream_from_path(self, "UiConfirmSfxPlayer", UI_CONFIRM_SFX_PATH)
	SceneAudioPlayersScript.assign_stream_from_path(self, "PanelOpenSfxPlayer", PANEL_OPEN_SFX_PATH)
	SceneAudioPlayersScript.assign_music_stream_from_path(self, "MainMenuMusicPlayer", MAIN_MENU_MUSIC_LOOP_PATH, true)


func _release_app_audio_for_shutdown() -> void:
	if not is_inside_tree():
		return
	var tree: SceneTree = get_tree()
	SceneAudioCleanupScript.release_all_audio_players(tree.root)
