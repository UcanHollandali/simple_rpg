# Layer: Scenes - presentation only
extends Control

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UI_CONFIRM_SFX_PATH := "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"
const UI_CANCEL_SFX_PATH := "res://Assets/Audio/SFX/sfx_ui_cancel_01.ogg"
const PANEL_OPEN_SFX_PATH := "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"
const RUN_END_MUSIC_LOOP_PATH := "res://Assets/Audio/Music/music_run_end_loop_temp_01.ogg"
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const PORTRAIT_SAFE_MAX_WIDTH := 860
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 28
const AUDIO_PLAYER_NODE_NAMES: Array[String] = [
	"UiConfirmSfxPlayer",
	"UiCancelSfxPlayer",
	"PanelOpenSfxPlayer",
	"RunEndMusicPlayer",
]

var _bootstrap
var _safe_menu: SafeMenuOverlay

func _ready() -> void:
	var chip_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/ChipCard/ChipLabel") as Label
	var result_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/ResultLabel") as Label
	var hint_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/HintLabel") as Label
	var title_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/TitleLabel") as Label
	var return_button: Button = get_node_or_null("Margin/Center/ContentCard/VBox/ReturnButton") as Button
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_configure_audio_players()
	if _bootstrap != null:
		var last_result: String = String(_bootstrap.get_last_run_result())
		var result_texts: Dictionary = _build_result_copy(String(_bootstrap.get_last_run_result()))
		if chip_label != null:
			chip_label.text = _build_result_chip_text(last_result)
		if title_label != null:
			title_label.text = String(result_texts.get("title", "Journey's End"))
		if result_label != null:
			result_label.text = String(result_texts.get("result", "The road is quiet."))
		if hint_label != null:
			hint_label.text = _build_result_hint_text(last_result)
	if return_button != null:
		return_button.text = "Return to Main Menu"
	if return_button != null and not return_button.is_connected("pressed", Callable(self, "_on_return_pressed")):
		return_button.connect("pressed", Callable(self, "_on_return_pressed"))

	_apply_temp_theme()
	_setup_safe_menu()
	_connect_viewport_layout_updates()
	_apply_portrait_safe_layout()
	_set_status_text("")
	_refresh_save_controls()
	SceneAudioPlayersScript.start_looping(self, "RunEndMusicPlayer")
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")


func _exit_tree() -> void:
	_disconnect_viewport_layout_updates()
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


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
	var status_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/StatusLabel") as Label
	if status_label != null:
		status_label.text = text
		status_label.visible = not text.is_empty()


func _get_flow_manager() -> GameFlowManager:
	if _bootstrap == null:
		return null
	return _bootstrap.get_flow_manager()


func _configure_audio_players() -> void:
	SceneAudioPlayersScript.assign_stream_from_path(self, "UiConfirmSfxPlayer", UI_CONFIRM_SFX_PATH)
	SceneAudioPlayersScript.assign_stream_from_path(self, "UiCancelSfxPlayer", UI_CANCEL_SFX_PATH)
	SceneAudioPlayersScript.assign_stream_from_path(self, "PanelOpenSfxPlayer", PANEL_OPEN_SFX_PATH)
	SceneAudioPlayersScript.assign_music_stream_from_path(self, "RunEndMusicPlayer", RUN_END_MUSIC_LOOP_PATH, true)


func _apply_temp_theme() -> void:
	TempScreenThemeScript.apply_wayfinder_backdrop(self, 0.58, 0.24, 0.08, true)
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/Center/ContentCard") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 22, 0.95)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/Center/ContentCard") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 3, 26, 0.04, 0.22, 22, 20)
	TempScreenThemeScript.apply_chip(
		get_node_or_null("Margin/Center/ContentCard/VBox/ChipCard") as PanelContainer,
		get_node_or_null("Margin/Center/ContentCard/VBox/ChipCard/ChipLabel") as Label,
		TempScreenThemeScript.RUST_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/ContentCard/VBox/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/ContentCard/VBox/ResultLabel") as Label, "danger")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/ContentCard/VBox/HintLabel") as Label, "accent")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/ContentCard/VBox/StatusLabel") as Label)
	TempScreenThemeScript.apply_button(get_node_or_null("Margin/Center/ContentCard/VBox/ReturnButton") as Button, TempScreenThemeScript.RUST_ACCENT_COLOR, true)

	var title_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 34)

	var result_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/ResultLabel") as Label
	if result_label != null:
		result_label.add_theme_font_size_override("font_size", 20)

	var hint_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/HintLabel") as Label
	if hint_label != null:
		hint_label.add_theme_font_size_override("font_size", 16)

	var status_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 14)

	var return_button: Button = get_node_or_null("Margin/Center/ContentCard/VBox/ReturnButton") as Button
	if return_button != null:
		return_button.add_theme_font_size_override("font_size", 18)


func _setup_safe_menu() -> void:
	_safe_menu = RunMenuSceneHelperScript.ensure_safe_menu(
		self,
		_safe_menu,
		"Run Menu",
		"Save, load, mute music, or quit.",
		"Settings",
		Callable(self, "_on_save_pressed"),
		Callable(self, "_on_load_pressed")
	)


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
	var content_card: PanelContainer = get_node_or_null("Margin/Center/ContentCard") as PanelContainer
	var vbox: VBoxContainer = get_node_or_null("Margin/Center/ContentCard/VBox") as VBoxContainer
	if margin == null or content_card == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var top_margin: int = 112
	var bottom_margin: int = 112
	if viewport_size.y < 1760.0:
		top_margin = 92
		bottom_margin = 92
	if viewport_size.y < 1540.0:
		top_margin = 70
		bottom_margin = 70

	var safe_width: int = TempScreenThemeScript.apply_portrait_safe_margins(
		margin,
		PORTRAIT_SAFE_MAX_WIDTH,
		PORTRAIT_SAFE_MIN_SIDE_MARGIN,
		top_margin,
		bottom_margin
	)
	content_card.custom_minimum_size = Vector2(min(float(safe_width), 820.0 if viewport_size.y >= 1640.0 else 740.0 if viewport_size.y >= 1460.0 else 620.0), 0.0)
	if vbox != null:
		vbox.add_theme_constant_override("separation", 12 if viewport_size.y < 1560.0 else 16)

	var large_layout: bool = safe_width >= 720 and viewport_size.y >= 1640.0
	var medium_layout: bool = not large_layout and safe_width >= 600 and viewport_size.y >= 1460.0
	var title_font_size: int = 48 if large_layout else 42 if medium_layout else 36
	var result_font_size: int = 28 if large_layout else 24 if medium_layout else 21
	var hint_font_size: int = 19 if large_layout else 17 if medium_layout else 15
	var status_font_size: int = 19 if large_layout else 17 if medium_layout else 15
	var button_font_size: int = 22 if large_layout else 20 if medium_layout else 18
	var button_height: float = 80.0 if large_layout else 72.0 if medium_layout else 64.0

	var title_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", title_font_size)
	var result_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/ResultLabel") as Label
	if result_label != null:
		result_label.add_theme_font_size_override("font_size", result_font_size)
	var hint_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/HintLabel") as Label
	if hint_label != null:
		hint_label.add_theme_font_size_override("font_size", hint_font_size)
	var status_label: Label = get_node_or_null("Margin/Center/ContentCard/VBox/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", status_font_size)
	var return_button: Button = get_node_or_null("Margin/Center/ContentCard/VBox/ReturnButton") as Button
	if return_button != null:
		return_button.custom_minimum_size = Vector2(0.0, button_height)
		return_button.add_theme_font_size_override("font_size", button_font_size)
		return_button.add_theme_constant_override("icon_max_width", 30 if large_layout else 26 if medium_layout else 22)


func _build_result_copy(result: String) -> Dictionary:
	match result:
		"victory":
			return {
				"title": "Gate Reached",
				"result": "You made it through the ashwood.",
			}
		"defeat":
			return {
				"title": "Journey's End",
				"result": "The road took this run.",
			}
		_:
			return {
				"title": "Journey's End",
				"result": result.capitalize() if not result.is_empty() else "The road has gone quiet.",
			}


func _build_result_chip_text(result: String) -> String:
	match result:
		"victory":
			return "GATE REACHED"
		"defeat":
			return "RUN CLOSED"
		_:
			return "ROAD CLOSED"


func _build_result_hint_text(result: String) -> String:
	match result:
		"victory":
			return "You cleared the road. Return to the main menu when ready."
		"defeat":
			return "Return to the main menu when ready. Save and load stay in Settings on this screen."
		_:
			return "Return to the main menu when ready. Settings still keeps save and load available here."
