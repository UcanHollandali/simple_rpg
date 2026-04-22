# Layer: Scenes - presentation only
extends Control

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const RunStatusPresenterScript = preload("res://Game/UI/run_status_presenter.gd")
const RunStatusStripScript = preload("res://Game/UI/run_status_strip.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const UiCompactCopyScript = preload("res://Game/UI/ui_compact_copy.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const PORTRAIT_SAFE_MAX_WIDTH := 860
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 28
const APP_BOOTSTRAP_PATH := "/root/AppBootstrap"
const CONTENT_CARD_PATH := "Margin/Center/ContentCard"
const CHIP_CARD_PATH := "Margin/Center/ContentCard/VBox/ChipCard"
const CHIP_LABEL_PATH := "Margin/Center/ContentCard/VBox/ChipCard/ChipLabel"
const TITLE_LABEL_PATH := "Margin/Center/ContentCard/VBox/TitleLabel"
const RESULT_LABEL_PATH := "Margin/Center/ContentCard/VBox/ResultLabel"
const HINT_LABEL_PATH := "Margin/Center/ContentCard/VBox/HintLabel"
const RUN_STATUS_CARD_PATH := "Margin/Center/ContentCard/VBox/RunStatusCard"
const RUN_STATUS_LABEL_PATH := "Margin/Center/ContentCard/VBox/RunStatusCard/RunStatusLabel"
const STATUS_LABEL_PATH := "Margin/Center/ContentCard/VBox/StatusLabel"
const RETURN_BUTTON_PATH := "Margin/Center/ContentCard/VBox/ReturnButton"
const AUDIO_PLAYER_CONFIG := {
	"UiConfirmSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"},
	"UiCancelSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_ui_cancel_01.ogg"},
	"PanelOpenSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"},
	"RunEndMusicPlayer": {"path": "res://Assets/Audio/Music/music_run_end_loop_proto_01.ogg", "music": true, "loop": true},
}
const PORTRAIT_LAYOUT_CONFIG := {
	"max_width": PORTRAIT_SAFE_MAX_WIDTH,
	"min_side_margin": PORTRAIT_SAFE_MIN_SIDE_MARGIN,
	"top_margin": 112,
	"bottom_margin": 112,
	"shared_surface_tokens": "run_end_shell",
	"margin_steps": [
		{"max_height": 1760.0, "top_margin": 92, "bottom_margin": 92},
		{"max_height": 1540.0, "top_margin": 70, "bottom_margin": 70},
	],
	"bands": {
		"large": {"min_width": 720.0, "min_height": 1640.0},
		"medium": {"min_width": 600.0, "min_height": 1460.0},
		"compact": {},
	},
}

var _bootstrap: AppBootstrapScript
var _safe_menu: SafeMenuOverlay

@onready var _content_card: PanelContainer = get_node_or_null(CONTENT_CARD_PATH) as PanelContainer
@onready var _chip_card: PanelContainer = get_node_or_null(CHIP_CARD_PATH) as PanelContainer
@onready var _chip_label: Label = get_node_or_null(CHIP_LABEL_PATH) as Label
@onready var _title_label: Label = get_node_or_null(TITLE_LABEL_PATH) as Label
@onready var _result_label: Label = get_node_or_null(RESULT_LABEL_PATH) as Label
@onready var _hint_label: Label = get_node_or_null(HINT_LABEL_PATH) as Label
@onready var _run_status_card: PanelContainer = get_node_or_null(RUN_STATUS_CARD_PATH) as PanelContainer
@onready var _run_status_label: Label = get_node_or_null(RUN_STATUS_LABEL_PATH) as Label
@onready var _status_label: Label = get_node_or_null(STATUS_LABEL_PATH) as Label
@onready var _return_button: Button = get_node_or_null(RETURN_BUTTON_PATH) as Button

func _ready() -> void:
	_bootstrap = get_node_or_null(APP_BOOTSTRAP_PATH) as AppBootstrapScript
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	if _bootstrap != null:
		var last_result: String = String(_bootstrap.get_last_run_result())
		var result_texts: Dictionary = _build_result_copy(String(_bootstrap.get_last_run_result()))
		if _chip_label != null:
			_chip_label.text = _build_result_chip_text(last_result)
		if _title_label != null:
			_title_label.text = String(result_texts.get("title", "Journey's End"))
		if _result_label != null:
			_result_label.text = String(result_texts.get("result", "The road is quiet."))
		if _hint_label != null:
			_hint_label.text = _build_result_hint_text(last_result)
	if _return_button != null:
		_return_button.text = "Return to Main Menu"
	if _return_button != null and not _return_button.is_connected("pressed", Callable(self, "_on_return_pressed")):
		_return_button.connect("pressed", Callable(self, "_on_return_pressed"))

	_apply_temp_theme()
	_setup_safe_menu()
	SceneLayoutHelperScript.bind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	_apply_portrait_safe_layout()
	_render_run_status_card()
	_set_status_text("")
	_refresh_save_controls()
	SceneAudioPlayersScript.start_looping(self, "RunEndMusicPlayer")
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")


func _exit_tree() -> void:
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	SceneAudioCleanupScript.release_players(self, SceneAudioPlayersScript.node_names_from_config(AUDIO_PLAYER_CONFIG))


func _on_return_pressed() -> void:
	var flow_manager: GameFlowManager = _get_flow_manager()
	if flow_manager == null:
		return
	SceneAudioPlayersScript.play(self, "UiCancelSfxPlayer")
	await SceneAudioPlayersScript.wait_for_lead_in(self, "UiCancelSfxPlayer", ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS)
	flow_manager.request_transition(FlowStateScript.Type.MAIN_MENU)


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


func _refresh_save_controls() -> void:
	RunMenuSceneHelperScript.sync_load_available(_safe_menu, _bootstrap)


func _set_status_text(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
		_status_label.visible = not text.is_empty()


func _get_flow_manager() -> GameFlowManager:
	if _bootstrap == null:
		return null
	return _bootstrap.get_flow_manager()


func _apply_temp_theme() -> void:
	TempScreenThemeScript.apply_wayfinder_backdrop(self, 0.58, 0.24, 0.08, true)
	TempScreenThemeScript.apply_panel(_content_card, TempScreenThemeScript.RUST_ACCENT_COLOR, 22, 0.95)
	TempScreenThemeScript.intensify_panel(_content_card, TempScreenThemeScript.RUST_ACCENT_COLOR, 3, 26, 0.04, 0.22, 22, 20)
	TempScreenThemeScript.apply_chip(
		_chip_card,
		_chip_label,
		TempScreenThemeScript.RUST_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_compact_status_area(
		_run_status_card,
		TempScreenThemeScript.PANEL_BORDER_COLOR
	)
	TempScreenThemeScript.apply_button(_return_button, TempScreenThemeScript.RUST_ACCENT_COLOR, true)
	SceneLayoutHelperScript.apply_label_tones(self, [
		{"path": TITLE_LABEL_PATH, "tone": "title"},
		{"path": RESULT_LABEL_PATH, "tone": "danger"},
		{"path": HINT_LABEL_PATH, "tone": "accent"},
		{"path": RUN_STATUS_LABEL_PATH, "tone": "muted"},
		{"path": STATUS_LABEL_PATH, "tone": "body"},
	])
	SceneLayoutHelperScript.apply_control_overrides(self, {}, [
		{"path": TITLE_LABEL_PATH, "font_size": 34},
		{"path": RESULT_LABEL_PATH, "font_size": 20},
		{"path": HINT_LABEL_PATH, "font_size": 16},
		{"path": RUN_STATUS_LABEL_PATH, "font_size": 14},
		{"path": STATUS_LABEL_PATH, "font_size": 14},
		{"path": RETURN_BUTTON_PATH, "font_size": 18},
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
		Callable(self, "_on_return_pressed")
	)


func _apply_portrait_safe_layout() -> void:
	var values: Dictionary = SceneLayoutHelperScript.apply_portrait_layout(self, PORTRAIT_LAYOUT_CONFIG)
	if values.is_empty():
		return
	var viewport_size: Vector2 = values.get("viewport_size", Vector2.ZERO)
	values["panel_width"] = SceneLayoutHelperScript.resolve_surface_panel_width(
		"run_end_shell",
		float(values.get("safe_width", 0.0)),
		values.get("panel_width_cap")
	)
	values["vbox_separation"] = SceneLayoutHelperScript.resolve_height_tier_spacing(
		viewport_size.y,
		1560.0,
		TempScreenThemeScript.REGULAR_STACK_SPACING_SHORT,
		TempScreenThemeScript.REGULAR_STACK_SPACING_TALL
	)
	SceneLayoutHelperScript.apply_control_overrides(self, values, [
		{"path": CONTENT_CARD_PATH, "custom_minimum_size": {"x": "panel_width", "y": 0.0}},
		{"path": "Margin/Center/ContentCard/VBox", "theme_constants": {"separation": "vbox_separation"}},
		{"path": TITLE_LABEL_PATH, "font_size": "title_font_size"},
		{"path": RESULT_LABEL_PATH, "font_size": "result_font_size"},
		{"path": HINT_LABEL_PATH, "font_size": "hint_font_size"},
		{"path": RUN_STATUS_LABEL_PATH, "font_size": "run_status_font_size"},
		{"path": RUN_STATUS_CARD_PATH, "custom_minimum_size": {"x": "run_status_width", "y": 0.0}},
		{"path": STATUS_LABEL_PATH, "font_size": "status_font_size"},
		{"path": RETURN_BUTTON_PATH, "font_size": "button_font_size", "custom_minimum_size": {"x": 0.0, "y": "button_height"}, "theme_constants": {"icon_max_width": "button_icon_max_width"}},
	])


func _render_run_status_card() -> void:
	var run_state: RunState = _bootstrap.get_run_state() if _bootstrap != null else null
	RunStatusStripScript.render_into(
		_run_status_card,
		_run_status_label,
		RunStatusPresenterScript.build_status_model(run_state, {
			"variant": RunStatusPresenterScript.VARIANT_STANDARD,
			"include_weapon": true,
			"include_xp": true,
		}),
		TempScreenThemeScript.PANEL_BORDER_COLOR
	)


func _build_result_copy(result: String) -> Dictionary:
	match result:
		"victory":
			return {
				"title": "Gate Reached",
				"result": "You crossed the ashwood and reached the far gate.",
			}
		"defeat":
			return {
				"title": "Journey's End",
				"result": "The ashwood closed over this run.",
			}
		_:
			return {
				"title": "Journey's End",
				"result": result.capitalize() if not result.is_empty() else "The road has gone still.",
			}


func _build_result_chip_text(result: String) -> String:
	match result:
		"victory":
			return "GATE REACHED"
		"defeat":
			return "ROAD CLOSED"
		_:
			return "ROAD CLOSED"


func _build_result_hint_text(result: String) -> String:
	match result:
		"victory":
			return UiCompactCopyScript.back_to_menu_when_ready()
		"defeat":
			return "Settings still has save/load."
		_:
			return UiCompactCopyScript.back_to_menu_when_ready()
