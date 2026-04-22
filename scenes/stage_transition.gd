# Layer: Scenes - presentation only
# Keep StageTransition as a real interstitial screen with explicit continue/save/load behavior.
# Do not collapse this scene back into an automatic map return.
extends Control

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const RunStatusStripScript = preload("res://Game/UI/run_status_strip.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const StageTransitionPresenterScript = preload("res://Game/UI/stage_transition_presenter.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const PORTRAIT_SAFE_MAX_WIDTH := 860
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 28
const AUDIO_PLAYER_CONFIG := {
	"UiConfirmSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"},
	"PanelOpenSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"},
	"PanelCloseSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_panel_close_01.ogg"},
	"StageTransitionMusicPlayer": {"path": "res://Assets/Audio/Music/music_ui_hub_loop_proto_01.ogg", "music": true, "loop": true},
}
const PORTRAIT_LAYOUT_CONFIG := {
	"max_width": PORTRAIT_SAFE_MAX_WIDTH,
	"min_side_margin": PORTRAIT_SAFE_MIN_SIDE_MARGIN,
	"top_margin": 112,
	"bottom_margin": 112,
	"margin_steps": [
		{"max_height": 1760.0, "top_margin": 92, "bottom_margin": 92},
		{"max_height": 1540.0, "top_margin": 70, "bottom_margin": 70},
	],
	"bands": {
		"large": {"min_width": 720.0, "min_height": 1640.0, "title_font_size": 44, "summary_font_size": 22, "hint_font_size": 16, "run_status_font_size": 16, "status_font_size": 16, "button_font_size": 20, "button_height": 80.0, "run_status_width": 320.0, "button_icon_max_width": 30},
		"medium": {"min_width": 600.0, "min_height": 1460.0, "title_font_size": 38, "summary_font_size": 20, "hint_font_size": 15, "run_status_font_size": 15, "status_font_size": 15, "button_font_size": 18, "button_height": 72.0, "run_status_width": 280.0, "button_icon_max_width": 26},
		"compact": {"title_font_size": 32, "summary_font_size": 18, "hint_font_size": 14, "run_status_font_size": 14, "status_font_size": 14, "button_font_size": 17, "button_height": 64.0, "run_status_width": 236.0, "button_icon_max_width": 22},
	},
}

var _bootstrap: AppBootstrapScript
var _presenter: StageTransitionPresenter
var _safe_menu: SafeMenuOverlay


func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap") as AppBootstrapScript
	_presenter = StageTransitionPresenterScript.new()
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	_connect_buttons()
	_apply_temp_theme()
	_setup_safe_menu()
	SceneLayoutHelperScript.bind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	_apply_portrait_safe_layout()
	_refresh_ui()
	SceneAudioPlayersScript.start_looping(self, "StageTransitionMusicPlayer")
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")


func _exit_tree() -> void:
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	SceneAudioCleanupScript.release_players(self, SceneAudioPlayersScript.node_names_from_config(AUDIO_PLAYER_CONFIG))


func _on_continue_pressed() -> void:
	var flow_manager: GameFlowManager = _get_flow_manager()
	if flow_manager == null:
		return
	SceneAudioPlayersScript.play(self, "PanelCloseSfxPlayer")
	await SceneAudioPlayersScript.wait_for_lead_in(self, "PanelCloseSfxPlayer", ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS)
	flow_manager.request_transition(FlowStateScript.Type.MAP_EXPLORE)


func _on_save_pressed() -> void:
	if _bootstrap == null:
		return
	SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
	var save_result: Dictionary = _bootstrap.save_game()
	if _safe_menu != null:
		_safe_menu.set_status_text(RunMenuSceneHelperScript.build_save_status_text(save_result))
	_refresh_save_controls()


func _on_load_pressed() -> void:
	if _bootstrap == null:
		return
	SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
	var load_result: Dictionary = _bootstrap.load_game()
	if bool(load_result.get("ok", false)):
		return
	if _safe_menu != null:
		_safe_menu.set_status_text(RunMenuSceneHelperScript.build_load_failure_status_text(load_result))
	_refresh_save_controls()


func _on_return_to_main_menu_pressed() -> void:
	var flow_manager: GameFlowManager = _get_flow_manager()
	if flow_manager == null:
		return
	flow_manager.request_transition(FlowStateScript.Type.MAIN_MENU)


func _connect_buttons() -> void:
	var continue_button: Button = get_node_or_null("Margin/Center/ContentCard/VBox/ContinueButton") as Button
	if continue_button != null and not continue_button.is_connected("pressed", Callable(self, "_on_continue_pressed")):
		continue_button.connect("pressed", Callable(self, "_on_continue_pressed"))


func _refresh_ui() -> void:
	var chip_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/ChipCard/ChipLabel") as Label
	var title_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/TitleLabel") as Label
	var summary_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/SummaryLabel") as Label
	var hint_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/HintLabel") as Label
	_set_status_text("")

	var stage_index: int = 0
	var stage_personality: String = ""
	if _bootstrap != null:
		var run_state: RunState = _bootstrap.get_run_state()
		if run_state != null:
			stage_index = int(run_state.stage_index)
			stage_personality = _resolve_stage_personality(run_state.map_runtime_state as MapRuntimeState)

	if chip_label != null:
		chip_label.text = _presenter.build_chip_text(stage_index)
	if title_label != null:
		title_label.text = _presenter.build_title_text(stage_index, stage_personality)
	if summary_label != null:
		summary_label.text = _presenter.build_summary_text(stage_personality)
	if hint_label != null:
		hint_label.text = _presenter.build_hint_text()
	_render_run_status_card()
	var continue_button: Button = get_node_or_null("Margin/Center/ContentCard/VBox/ContinueButton") as Button
	if continue_button != null:
		continue_button.text = "Step Into Next Route"

	_refresh_save_controls()


func _refresh_save_controls() -> void:
	RunMenuSceneHelperScript.sync_load_available(_safe_menu, _bootstrap)


func _set_status_text(text: String) -> void:
	var status_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/StatusLabel") as Label
	if status_label != null:
		status_label.text = text
		status_label.visible = not text.is_empty()


func _get_flow_manager() -> GameFlowManager:
	if _bootstrap == null:
		return null
	return _bootstrap.get_flow_manager()


func _resolve_stage_personality(map_runtime_state: MapRuntimeState) -> String:
	if map_runtime_state == null:
		return ""
	for snapshot in map_runtime_state.build_node_snapshots():
		if typeof(snapshot) != TYPE_DICTIONARY:
			continue
		var node_snapshot: Dictionary = snapshot
		if String(node_snapshot.get("node_family", "")) != "hamlet":
			continue
		return String(node_snapshot.get("hamlet_personality", ""))
	return ""


func _apply_temp_theme() -> void:
	TempScreenThemeScript.apply_wayfinder_backdrop(self, 0.56, 0.24, 0.08, true)
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/Center/ContentCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 22, 0.95)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/Center/ContentCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 3, 26, 0.04, 0.2, 22, 20)
	TempScreenThemeScript.apply_chip(
		get_node_or_null("Margin/Center/ContentCard/VBox/ChipCard") as PanelContainer,
		get_node_or_null("Margin/Center/ContentCard/VBox/ChipCard/ChipLabel") as Label,
		TempScreenThemeScript.REWARD_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_compact_status_area(
		get_node_or_null("Margin/Center/ContentCard/VBox/RunStatusCard") as PanelContainer,
		TempScreenThemeScript.PANEL_BORDER_COLOR
	)
	TempScreenThemeScript.apply_button(get_node_or_null("Margin/Center/ContentCard/VBox/ContinueButton") as Button, TempScreenThemeScript.REWARD_ACCENT_COLOR)
	SceneLayoutHelperScript.apply_label_tones(self, [
		{"path": "Margin/Center/ContentCard/VBox/TitleLabel", "tone": "title"},
		{"path": "Margin/Center/ContentCard/VBox/SummaryLabel", "tone": "muted"},
		{"path": "Margin/Center/ContentCard/VBox/HintLabel", "tone": "reward"},
		{"path": "Margin/Center/ContentCard/VBox/RunStatusCard/RunStatusLabel", "tone": "muted"},
		{"path": "Margin/Center/ContentCard/VBox/StatusLabel", "tone": "body"},
	])
	SceneLayoutHelperScript.apply_control_overrides(self, {}, [
		{"path": "Margin/Center/ContentCard/VBox/TitleLabel", "font_size": 34},
		{"path": "Margin/Center/ContentCard/VBox/SummaryLabel", "font_size": 18},
		{"path": "Margin/Center/ContentCard/VBox/HintLabel", "font_size": 16},
		{"path": "Margin/Center/ContentCard/VBox/RunStatusCard/RunStatusLabel", "font_size": 14},
		{"path": "Margin/Center/ContentCard/VBox/StatusLabel", "font_size": 14},
		{"path": "Margin/Center/ContentCard/VBox/ContinueButton", "font_size": 18},
	])


func _setup_safe_menu() -> void:
	var menu_config: Dictionary = RunMenuSceneHelperScript.shared_menu_config()
	_safe_menu = RunMenuSceneHelperScript.ensure_safe_menu(
		self,
		_safe_menu,
		String(menu_config.get("title_text", RunMenuSceneHelperScript.SHARED_MENU_TITLE)),
		String(menu_config.get("subtitle_text", RunMenuSceneHelperScript.SHARED_MENU_SUBTITLE)),
		String(menu_config.get("launcher_text", RunMenuSceneHelperScript.SHARED_LAUNCHER_TEXT)),
		Callable(self, "_on_save_pressed"),
		Callable(self, "_on_load_pressed"),
		Callable(self, "_on_return_to_main_menu_pressed")
	)


func _apply_portrait_safe_layout() -> void:
	var values: Dictionary = SceneLayoutHelperScript.apply_portrait_layout(self, PORTRAIT_LAYOUT_CONFIG)
	if values.is_empty():
		return
	var viewport_size: Vector2 = values.get("viewport_size", Vector2.ZERO)
	values["panel_width"] = min(float(values.get("safe_width", 0.0)), 820.0 if viewport_size.y >= 1640.0 else 740.0 if viewport_size.y >= 1460.0 else 620.0)
	values["vbox_separation"] = 12 if viewport_size.y < 1560.0 else 16
	SceneLayoutHelperScript.apply_control_overrides(self, values, [
		{"path": "Margin/Center/ContentCard", "custom_minimum_size": {"x": "panel_width", "y": 0.0}},
		{"path": "Margin/Center/ContentCard/VBox", "theme_constants": {"separation": "vbox_separation"}},
		{"path": "Margin/Center/ContentCard/VBox/TitleLabel", "font_size": "title_font_size"},
		{"path": "Margin/Center/ContentCard/VBox/SummaryLabel", "font_size": "summary_font_size"},
		{"path": "Margin/Center/ContentCard/VBox/HintLabel", "font_size": "hint_font_size"},
		{"path": "Margin/Center/ContentCard/VBox/RunStatusCard/RunStatusLabel", "font_size": "run_status_font_size"},
		{"path": "Margin/Center/ContentCard/VBox/RunStatusCard", "custom_minimum_size": {"x": "run_status_width", "y": 0.0}},
		{"path": "Margin/Center/ContentCard/VBox/StatusLabel", "font_size": "status_font_size"},
		{"path": "Margin/Center/ContentCard/VBox/ContinueButton", "font_size": "button_font_size", "custom_minimum_size": {"x": 0.0, "y": "button_height"}, "theme_constants": {"icon_max_width": "button_icon_max_width"}},
	])


func _render_run_status_card() -> void:
	var run_state: RunState = _bootstrap.get_run_state() if _bootstrap != null else null
	RunStatusStripScript.render_into(
		get_node_or_null("Margin/Center/ContentCard/VBox/RunStatusCard") as PanelContainer,
		get_node_or_null("Margin/Center/ContentCard/VBox/RunStatusCard/RunStatusLabel") as Label,
		_presenter.build_run_status_model(run_state),
		TempScreenThemeScript.PANEL_BORDER_COLOR
	)
