# Layer: Scenes - presentation only
extends Control

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const MainMenuPresenterScript = preload("res://Game/UI/main_menu_presenter.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const PLAYTEST_TAGLINE_TEXT := "Rota seç. Hayatta kal. Kapıya ulaş."
const PORTRAIT_SAFE_MAX_WIDTH := 940
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 32
const AUDIO_PLAYER_CONFIG := {
	"UiConfirmSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"},
	"PanelOpenSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"},
	"MainMenuMusicPlayer": {"path": "res://Assets/Audio/Music/music_ui_hub_loop_proto_01.ogg", "music": true, "loop": true},
}
const PORTRAIT_LAYOUT_CONFIG := {
	"max_width": PORTRAIT_SAFE_MAX_WIDTH,
	"min_side_margin": PORTRAIT_SAFE_MIN_SIDE_MARGIN,
	"top_margin": 44,
	"bottom_margin": 40,
	"margin_steps": [
		{"max_height": 1720.0, "top_margin": 34, "bottom_margin": 32},
		{"max_height": 1480.0, "top_margin": 26, "bottom_margin": 24},
	],
	"bands": {
		"large": {"min_width": 860.0, "min_height": 1680.0, "title_font_size": 74, "subtitle_font_size": 22, "mood_font_size": 20, "body_font_size": 20, "status_font_size": 16, "button_font_size": 20, "button_height": 84.0, "button_icon_max_width": 32},
		"medium": {"min_width": 720.0, "min_height": 1480.0, "title_font_size": 64, "subtitle_font_size": 20, "mood_font_size": 18, "body_font_size": 18, "status_font_size": 15, "button_font_size": 18, "button_height": 76.0, "button_icon_max_width": 32},
		"compact": {"title_font_size": 54, "subtitle_font_size": 18, "mood_font_size": 16, "body_font_size": 16, "status_font_size": 14, "button_font_size": 17, "button_height": 68.0, "button_icon_max_width": 28},
	},
}

var _bootstrap: AppBootstrapScript
var _presenter: MainMenuPresenter


func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap") as AppBootstrapScript
	_presenter = MainMenuPresenterScript.new()
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	_soften_backdrop()
	_apply_temp_theme()
	SceneLayoutHelperScript.bind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	_apply_portrait_safe_layout()
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
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	SceneAudioCleanupScript.release_players(self, SceneAudioPlayersScript.node_names_from_config(AUDIO_PLAYER_CONFIG))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SceneAudioCleanupScript.release_scene_tree_audio(self)


func _on_start_run_pressed() -> void:
	var flow_manager: GameFlowManager = _get_flow_manager()
	if flow_manager == null or _bootstrap == null:
		return

	SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
	await SceneAudioPlayersScript.wait_for_lead_in(self, "UiConfirmSfxPlayer", ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS)
	_bootstrap.reset_run_state_for_new_run()
	flow_manager.request_transition(FlowStateScript.Type.MAP_EXPLORE)


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


func _refresh_ui() -> void:
	var load_button: Button = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/LoadRunButton") as Button
	var start_button: Button = get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/StartRunButton") as Button
	var has_save: bool = _bootstrap != null and _bootstrap.has_save_game()
	if load_button != null:
		load_button.disabled = not has_save
		load_button.text = "Resume Safe Save"
	if start_button != null:
		start_button.text = "Begin New Run"

	var title_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/TitleLabel") as Label
	_set_label_text(title_label, _presenter.build_title_text())

	var subtitle_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/SubtitleLabel") as Label
	_set_label_text(subtitle_label, PLAYTEST_TAGLINE_TEXT)

	var mood_label: Label = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/MoodLabel") as Label
	_set_label_text(mood_label, _presenter.build_mood_text())

	var chip_row: BoxContainer = get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/ChipRow") as BoxContainer
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


func _apply_temp_theme() -> void:
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/HeroPanel") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 20, 0.74)
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/ActionPanel") as PanelContainer, TempScreenThemeScript.REWARD_ACCENT_COLOR, 20, 0.97)
	TempScreenThemeScript.apply_chip(
		get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/ChipRow/PlaytestChipCard") as PanelContainer,
		get_node_or_null("Margin/VBox/HeroPanel/HeroVBox/ChipRow/PlaytestChipCard/PlaytestChipLabel") as Label,
		TempScreenThemeScript.TEAL_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_button(get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/StartRunButton") as Button)
	TempScreenThemeScript.apply_button(get_node_or_null("Margin/VBox/ActionPanel/ActionVBox/LoadRunButton") as Button, TempScreenThemeScript.TEAL_ACCENT_COLOR, true)
	SceneLayoutHelperScript.apply_label_tones(self, [
		{"path": "Margin/VBox/HeroPanel/HeroVBox/TitleLabel", "tone": "title"},
		{"path": "Margin/VBox/HeroPanel/HeroVBox/SubtitleLabel", "tone": "muted"},
		{"path": "Margin/VBox/HeroPanel/HeroVBox/MoodLabel", "tone": "muted"},
		{"path": "Margin/VBox/ActionPanel/ActionVBox/PlaytestReadLabel", "tone": "body"},
		{"path": "Margin/VBox/HeroPanel/HeroVBox/FlowReadLabel", "tone": "muted"},
		{"path": "Margin/VBox/ActionPanel/ActionVBox/StatusLabel", "tone": "muted"},
	])
	_refine_panel_style(get_node_or_null("Margin/VBox/HeroPanel") as PanelContainer, 1, 2, 18, 18, 14, 14)
	_refine_panel_style(get_node_or_null("Margin/VBox/ActionPanel") as PanelContainer, 1, 10, 18, 18, 16, 16)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/HeroPanel") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 3, 22, 0.03, 0.18, 20, 18)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/ActionPanel") as PanelContainer, TempScreenThemeScript.REWARD_ACCENT_COLOR, 3, 22, 0.03, 0.22, 20, 18)
	SceneLayoutHelperScript.apply_control_overrides(self, {}, [
		{"path": "Margin/VBox/HeroPanel/HeroVBox/TitleLabel", "font_size": 72},
		{"path": "Margin/VBox/HeroPanel/HeroVBox/SubtitleLabel", "font_size": 24},
		{"path": "Margin/VBox/HeroPanel/HeroVBox/MoodLabel", "font_size": 22},
		{"path": "Margin/VBox/HeroPanel/HeroVBox/FlowReadLabel", "font_size": 18, "visible": true},
		{"path": "Margin/VBox/ActionPanel/ActionVBox/PlaytestReadLabel", "font_size": 22},
		{"path": "Margin/VBox/ActionPanel/ActionVBox/StatusLabel", "font_size": 18},
	])


func _apply_portrait_safe_layout() -> void:
	var values: Dictionary = SceneLayoutHelperScript.apply_portrait_layout(self, PORTRAIT_LAYOUT_CONFIG)
	if values.is_empty():
		return
	var viewport_size: Vector2 = values.get("viewport_size", Vector2.ZERO)
	values["vbox_separation"] = 14 if viewport_size.y < 1520.0 else 18
	SceneLayoutHelperScript.apply_control_overrides(self, values, [
		{"path": "Margin/VBox", "theme_constants": {"separation": "vbox_separation"}},
		{"path": "Margin/VBox/HeroPanel/HeroVBox/TitleLabel", "font_size": "title_font_size"},
		{"path": "Margin/VBox/HeroPanel/HeroVBox/SubtitleLabel", "font_size": "subtitle_font_size"},
		{"path": "Margin/VBox/HeroPanel/HeroVBox/MoodLabel", "font_size": "mood_font_size"},
		{"path": "Margin/VBox/ActionPanel/ActionVBox/PlaytestReadLabel", "font_size": "body_font_size"},
		{"path": "Margin/VBox/ActionPanel/ActionVBox/StatusLabel", "font_size": "status_font_size"},
		{"paths": ["Margin/VBox/ActionPanel/ActionVBox/StartRunButton", "Margin/VBox/ActionPanel/ActionVBox/LoadRunButton"], "font_size": "button_font_size", "custom_minimum_size": {"x": 0.0, "y": "button_height"}, "theme_constants": {"icon_max_width": "button_icon_max_width"}},
		{"paths": ["Margin/VBox/HeroPanel", "Margin/VBox/ActionPanel"], "size_flags_horizontal": Control.SIZE_FILL, "size_flags_vertical": Control.SIZE_SHRINK_CENTER},
		{"paths": ["Margin/VBox/TopSpacer", "Margin/VBox/BottomSpacer"], "visible": true, "size_flags_vertical": Control.SIZE_EXPAND_FILL},
	])


func _soften_backdrop() -> void:
	TempScreenThemeScript.apply_wayfinder_backdrop(self, 0.88, 0.38, 0.10, true)

	var scrim: ColorRect = get_node_or_null("BackdropScrim") as ColorRect
	TempScreenThemeScript.apply_scrim(scrim)
	if scrim != null:
		scrim.color = Color(scrim.color.r, scrim.color.g, scrim.color.b, 0.62)


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

