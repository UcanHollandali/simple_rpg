# Layer: Scenes - presentation only
extends Control

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const TransitionShellPresenterScript = preload("res://Game/UI/transition_shell_presenter.gd")
const PANEL_OPEN_SFX_PATH := "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"
const TRANSITION_HOLD_SECONDS := 0.22
const PORTRAIT_SAFE_MAX_WIDTH := 820
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 30
const AUDIO_PLAYER_NODE_NAMES: Array[String] = ["PanelOpenSfxPlayer"]

var _bootstrap
var _presenter: TransitionShellPresenter


func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_presenter = TransitionShellPresenterScript.new()
	_configure_audio_players()
	_apply_temp_theme()
	_connect_viewport_layout_updates()
	_apply_portrait_safe_layout()
	if _bootstrap != null:
		_bootstrap.reset_run_state_for_new_run()
	_refresh_ui()
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")
	Callable(self, "_finish_run_setup").call_deferred()


func _exit_tree() -> void:
	_disconnect_viewport_layout_updates()
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


func _finish_run_setup() -> void:
	if _bootstrap == null:
		return

	await get_tree().create_timer(TRANSITION_HOLD_SECONDS).timeout

	var flow_manager: GameFlowManager = _bootstrap.get_flow_manager()
	if flow_manager == null:
		return

	flow_manager.request_transition(FlowStateScript.Type.MAP_EXPLORE)


func _refresh_ui() -> void:
	var chip_label: Label = get_node_or_null("Margin/Center/Panel/VBox/ChipCard/ChipLabel") as Label
	if chip_label != null:
		chip_label.text = _presenter.build_run_setup_chip_text()

	var title_label: Label = get_node_or_null("Margin/Center/Panel/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.text = _presenter.build_run_setup_title_text()

	var summary_label: Label = get_node_or_null("Margin/Center/Panel/VBox/SummaryLabel") as Label
	if summary_label != null:
		summary_label.text = _presenter.build_run_setup_summary_text()

	var detail_label: Label = get_node_or_null("Margin/Center/Panel/VBox/DetailLabel") as Label
	if detail_label != null:
		detail_label.text = _presenter.build_run_setup_detail_text()

	var hint_label: Label = get_node_or_null("Margin/Center/Panel/VBox/HintLabel") as Label
	if hint_label != null:
		hint_label.text = _presenter.build_run_setup_hint_text()


func _configure_audio_players() -> void:
	SceneAudioPlayersScript.assign_stream_from_path(self, "PanelOpenSfxPlayer", PANEL_OPEN_SFX_PATH)


func _apply_temp_theme() -> void:
	TempScreenThemeScript.apply_wayfinder_backdrop(self, 0.46, 0.18, 0.10, true)
	TempScreenThemeScript.apply_panel(
		get_node_or_null("Margin/Center/Panel") as PanelContainer,
		TempScreenThemeScript.TEAL_ACCENT_COLOR,
		22,
		0.9
	)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/Center/Panel") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 3, 24, 0.04, 0.22, 22, 20)
	TempScreenThemeScript.apply_chip(
		get_node_or_null("Margin/Center/Panel/VBox/ChipCard") as PanelContainer,
		get_node_or_null("Margin/Center/Panel/VBox/ChipCard/ChipLabel") as Label,
		TempScreenThemeScript.TEAL_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/Panel/VBox/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/Panel/VBox/SummaryLabel") as Label, "accent")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/Panel/VBox/DetailLabel") as Label)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/Panel/VBox/HintLabel") as Label, "muted")

	var title_label: Label = get_node_or_null("Margin/Center/Panel/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 38)

	var shell_icon: TextureRect = get_node_or_null("Margin/Center/Panel/VBox/ShellIcon") as TextureRect
	if shell_icon != null:
		shell_icon.modulate = Color(0.95, 0.92, 0.82, 0.96)


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
	var panel: PanelContainer = get_node_or_null("Margin/Center/Panel") as PanelContainer
	var vbox: VBoxContainer = get_node_or_null("Margin/Center/Panel/VBox") as VBoxContainer
	var shell_icon: TextureRect = get_node_or_null("Margin/Center/Panel/VBox/ShellIcon") as TextureRect
	if margin == null or panel == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var top_margin: int = 40
	var bottom_margin: int = 44
	if viewport_size.y < 1680.0:
		top_margin = 30
		bottom_margin = 34
	if viewport_size.y < 1460.0:
		top_margin = 22
		bottom_margin = 26

	var safe_width: int = TempScreenThemeScript.apply_portrait_safe_margins(
		margin,
		PORTRAIT_SAFE_MAX_WIDTH,
		PORTRAIT_SAFE_MIN_SIDE_MARGIN,
		top_margin,
		bottom_margin
	)
	panel.custom_minimum_size = Vector2(min(float(safe_width), 760.0), 0.0)
	if vbox != null:
		vbox.add_theme_constant_override("separation", 14 if viewport_size.y < 1540.0 else 18)

	var title_font_size: int = 42
	var summary_font_size: int = 24
	var detail_font_size: int = 22
	var hint_font_size: int = 20
	if safe_width < 700 or viewport_size.y < 1600.0:
		title_font_size = 36
		summary_font_size = 22
		detail_font_size = 20
		hint_font_size = 18
	if safe_width < 580 or viewport_size.y < 1420.0:
		title_font_size = 30
		summary_font_size = 19
		detail_font_size = 18
		hint_font_size = 16

	var title_label: Label = get_node_or_null("Margin/Center/Panel/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", title_font_size)

	var summary_label: Label = get_node_or_null("Margin/Center/Panel/VBox/SummaryLabel") as Label
	if summary_label != null:
		summary_label.add_theme_font_size_override("font_size", summary_font_size)

	var detail_label: Label = get_node_or_null("Margin/Center/Panel/VBox/DetailLabel") as Label
	if detail_label != null:
		detail_label.add_theme_font_size_override("font_size", detail_font_size)

	var hint_label: Label = get_node_or_null("Margin/Center/Panel/VBox/HintLabel") as Label
	if hint_label != null:
		hint_label.add_theme_font_size_override("font_size", hint_font_size)

	if shell_icon != null:
		var icon_size: float = 78.0 if viewport_size.y >= 1680.0 else 66.0 if viewport_size.y >= 1480.0 else 56.0
		shell_icon.custom_minimum_size = Vector2(icon_size, icon_size)
