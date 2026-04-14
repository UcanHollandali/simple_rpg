# Layer: Scenes - presentation only
# Keep SupportInteraction as a real runtime-backed non-combat decision screen.
# Do not collapse this scene back into an immediate-return placeholder.
extends Control

const BUTTON_NODE_NAMES: PackedStringArray = ["ActionAButton", "ActionBButton", "ActionCButton"]
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const SupportInteractionPresenterScript = preload("res://Game/UI/support_interaction_presenter.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UI_CONFIRM_SFX_PATH := "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"
const PANEL_OPEN_SFX_PATH := "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"
const PANEL_CLOSE_SFX_PATH := "res://Assets/Audio/SFX/sfx_panel_close_01.ogg"
const SUPPORT_MUSIC_LOOP_PATH := "res://Assets/Audio/Music/music_ui_hub_loop_temp_01.ogg"
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const PORTRAIT_SAFE_MAX_WIDTH := 920
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 30
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
	_connect_viewport_layout_updates()
	_apply_portrait_safe_layout()
	_render_support_state()
	SceneAudioPlayersScript.start_looping(self, "SupportMusicPlayer")
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")


func _exit_tree() -> void:
	_disconnect_viewport_layout_updates()
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

	SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
	_bootstrap.choose_support_action(offer_id)
	_support_state = _bootstrap.get_support_interaction_state()
	_render_support_state()


func _on_leave_pressed() -> void:
	if _bootstrap == null:
		return
	if _support_state != null and bool(_support_state.call("is_blacksmith_target_selection_active")):
		SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
		_bootstrap.choose_support_action("return_to_blacksmith_services")
		_support_state = _bootstrap.get_support_interaction_state()
		_render_support_state()
		return
	SceneAudioPlayersScript.play(self, "PanelCloseSfxPlayer")
	await SceneAudioPlayersScript.wait_for_lead_in(self, "PanelCloseSfxPlayer", ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS)
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
	var chip_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/ChipCard/ChipLabel") as Label
	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	var summary_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/SummaryLabel") as Label
	var hint_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/HintLabel") as Label
	var status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/StatusLabel") as Label

	if chip_label != null:
		chip_label.text = _presenter.build_chip_text(_support_state)
	if title_label != null:
		title_label.text = _presenter.build_title_text(_support_state)
	if summary_label != null:
		summary_label.text = _presenter.build_summary_text(_support_state)
	if hint_label != null:
		hint_label.text = _presenter.build_hint_text(_support_state)

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

	var leave_button: Button = get_node_or_null("Margin/VBox/FooterRow/LeaveButton") as Button
	if leave_button != null:
		leave_button.text = _presenter.build_leave_button_text(_support_state)

	_refresh_save_controls()


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


func _get_run_state() -> RunState:
	if _bootstrap == null:
		return null
	return _bootstrap.get_run_state()


func _configure_audio_players() -> void:
	SceneAudioPlayersScript.assign_stream_from_path(self, "UiConfirmSfxPlayer", UI_CONFIRM_SFX_PATH)
	SceneAudioPlayersScript.assign_stream_from_path(self, "PanelOpenSfxPlayer", PANEL_OPEN_SFX_PATH)
	SceneAudioPlayersScript.assign_stream_from_path(self, "PanelCloseSfxPlayer", PANEL_CLOSE_SFX_PATH)
	SceneAudioPlayersScript.assign_music_stream_from_path(self, "SupportMusicPlayer", SUPPORT_MUSIC_LOOP_PATH, true)


func _apply_temp_theme() -> void:
	# Skip backdrop styling when used as overlay (map_explore handles it)
	var is_overlay: bool = self.top_level
	if not is_overlay:
		TempScreenThemeScript.apply_modal_popup_shell(
			self,
			get_node_or_null("Margin") as MarginContainer,
			get_node_or_null("Margin/VBox") as Control,
			TempScreenThemeScript.TEAL_ACCENT_COLOR,
			"ContentShell",
			34,
			102,
			34,
			102
		)
	TempScreenThemeScript.apply_chip(
		get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/ChipCard") as PanelContainer,
		get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/ChipCard/ChipLabel") as Label,
		TempScreenThemeScript.TEAL_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/SummaryLabel") as Label, "muted")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/HintLabel") as Label, "accent")
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 16, 0.88)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 3, 18, 0.03, 0.18, 16, 12)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/StatusLabel") as Label, "muted")

	for button_name in BUTTON_NODE_NAMES:
		var action_button: Button = get_node_or_null("Margin/VBox/ActionsRow/%s" % button_name) as Button
		TempScreenThemeScript.apply_button(action_button, TempScreenThemeScript.TEAL_ACCENT_COLOR)
		if action_button != null:
			action_button.custom_minimum_size = Vector2(0, 78)
			action_button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	TempScreenThemeScript.apply_button(get_node_or_null("Margin/VBox/FooterRow/LeaveButton") as Button, TempScreenThemeScript.PANEL_BORDER_COLOR, true)

	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 34)

	var summary_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/SummaryLabel") as Label
	if summary_label != null:
		summary_label.add_theme_font_size_override("font_size", 16)
	var hint_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/HintLabel") as Label
	if hint_label != null:
		hint_label.add_theme_font_size_override("font_size", 15)

	var run_status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/StatusLabel") as Label
	if run_status_label != null:
		run_status_label.add_theme_font_size_override("font_size", 14)

	for button_name in BUTTON_NODE_NAMES:
		var action_button: Button = get_node_or_null("Margin/VBox/ActionsRow/%s" % button_name) as Button
		if action_button != null:
			action_button.add_theme_font_size_override("font_size", 19)

	var leave_button: Button = get_node_or_null("Margin/VBox/FooterRow/LeaveButton") as Button
	if leave_button != null:
		leave_button.add_theme_font_size_override("font_size", 16)
		leave_button.text = "Back to the Road"

	var vbox: VBoxContainer = get_node_or_null("Margin/VBox") as VBoxContainer
	if vbox != null:
		vbox.add_theme_constant_override("separation", 14)
	var header_row: VBoxContainer = get_node_or_null("Margin/VBox/HeaderRow") as VBoxContainer
	if header_row != null:
		header_row.add_theme_constant_override("separation", 10)
	var actions_row: VBoxContainer = get_node_or_null("Margin/VBox/ActionsRow") as VBoxContainer
	if actions_row != null:
		actions_row.add_theme_constant_override("separation", 10)


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
	var vbox: VBoxContainer = get_node_or_null("Margin/VBox") as VBoxContainer
	var header_row: HBoxContainer = get_node_or_null("Margin/VBox/HeaderRow") as HBoxContainer
	var actions_row: VBoxContainer = get_node_or_null("Margin/VBox/ActionsRow") as VBoxContainer
	var footer_row: HBoxContainer = get_node_or_null("Margin/VBox/FooterRow") as HBoxContainer
	if margin == null or vbox == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var top_margin: int = 120
	var bottom_margin: int = 116
	if viewport_size.y < 1760.0:
		top_margin = 92
		bottom_margin = 88
	if viewport_size.y < 1540.0:
		top_margin = 68
		bottom_margin = 64

	var safe_width: int = TempScreenThemeScript.apply_portrait_safe_margins(
		margin,
		PORTRAIT_SAFE_MAX_WIDTH,
		PORTRAIT_SAFE_MIN_SIDE_MARGIN,
		top_margin,
		bottom_margin
	)
	vbox.add_theme_constant_override("separation", 12 if viewport_size.y < 1560.0 else 16)
	if header_row != null:
		header_row.add_theme_constant_override("separation", 12 if viewport_size.y < 1560.0 else 16)
	if actions_row != null:
		actions_row.add_theme_constant_override("separation", 12 if viewport_size.y < 1560.0 else 16)
	if footer_row != null:
		footer_row.add_theme_constant_override("separation", 10 if viewport_size.y < 1560.0 else 12)

	var large_layout: bool = safe_width >= 760 and viewport_size.y >= 1640.0
	var medium_layout: bool = not large_layout and safe_width >= 620 and viewport_size.y >= 1460.0
	var title_font_size: int = 46 if large_layout else 40 if medium_layout else 34
	var summary_font_size: int = 21 if large_layout else 19 if medium_layout else 17
	var status_font_size: int = 19 if large_layout else 17 if medium_layout else 15
	var button_font_size: int = 22 if large_layout else 20 if medium_layout else 18
	var leave_font_size: int = 20 if large_layout else 18 if medium_layout else 16
	var button_height: float = 84.0 if large_layout else 76.0 if medium_layout else 66.0
	var run_status_width: float = 300.0 if large_layout else 260.0 if medium_layout else 224.0

	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", title_font_size)
	var summary_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/SummaryLabel") as Label
	if summary_label != null:
		summary_label.add_theme_font_size_override("font_size", summary_font_size)
	var hint_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/HintLabel") as Label
	if hint_label != null:
		hint_label.add_theme_font_size_override("font_size", max(14, summary_font_size - 2))
	var run_status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/StatusLabel") as Label
	if run_status_label != null:
		run_status_label.add_theme_font_size_override("font_size", status_font_size)
	var run_status_card: PanelContainer = get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard") as PanelContainer
	if run_status_card != null:
		run_status_card.custom_minimum_size = Vector2(run_status_width, 0.0)

	for button_name in BUTTON_NODE_NAMES:
		var action_button: Button = get_node_or_null("Margin/VBox/ActionsRow/%s" % button_name) as Button
		if action_button != null:
			action_button.custom_minimum_size = Vector2(0.0, button_height)
			action_button.add_theme_font_size_override("font_size", button_font_size)
			action_button.add_theme_constant_override("icon_max_width", 30 if large_layout else 26 if medium_layout else 22)

	var leave_button: Button = get_node_or_null("Margin/VBox/FooterRow/LeaveButton") as Button
	if leave_button != null:
		leave_button.custom_minimum_size = Vector2(0.0, 60.0 if large_layout else 54.0 if medium_layout else 48.0)
		leave_button.add_theme_font_size_override("font_size", leave_font_size)
