# Layer: Scenes - presentation only
extends Control

const BUTTON_NODE_NAMES: PackedStringArray = ["ChoiceAButton", "ChoiceBButton", "ChoiceCButton"]
const LevelUpPresenterScript = preload("res://Game/UI/level_up_presenter.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UI_CONFIRM_SFX_PATH := "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"
const PANEL_OPEN_SFX_PATH := "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"
const LEVEL_UP_MUSIC_LOOP_PATH := "res://Assets/Audio/Music/music_ui_hub_loop_temp_01.ogg"
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const PORTRAIT_SAFE_MAX_WIDTH := 920
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 30
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
	_ensure_choice_button_content()
	_apply_temp_theme()
	_setup_safe_menu()
	_connect_viewport_layout_updates()
	_apply_portrait_safe_layout()
	_render_level_up_state()
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")
	SceneAudioPlayersScript.start_looping(self, "LevelUpMusicPlayer")


func _exit_tree() -> void:
	_disconnect_viewport_layout_updates()
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

	SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
	await SceneAudioPlayersScript.wait_for_lead_in(self, "UiConfirmSfxPlayer", ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS)
	_bootstrap.choose_level_up_option(offer_id)


func _on_save_pressed() -> void:
	if _bootstrap == null:
		return
	SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
	var save_result: Dictionary = _bootstrap.save_game()
	if _safe_menu != null:
		_safe_menu.set_status_text(_presenter.build_save_status_text(save_result))
	_refresh_save_controls()


func _on_load_pressed() -> void:
	if _bootstrap == null:
		return
	SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
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


func _ensure_choice_button_content() -> void:
	for button_name in BUTTON_NODE_NAMES:
		var button: Button = get_node_or_null("Margin/VBox/ChoicesRow/%s" % button_name) as Button
		if button == null:
			continue
		button.text = ""
		button.icon = null
		button.clip_contents = true

		var content_margin: MarginContainer = button.get_node_or_null("ContentMargin") as MarginContainer
		if content_margin == null:
			content_margin = MarginContainer.new()
			content_margin.name = "ContentMargin"
			content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
			button.add_child(content_margin)

		var content_vbox: VBoxContainer = content_margin.get_node_or_null("ContentVBox") as VBoxContainer
		if content_vbox == null:
			content_vbox = VBoxContainer.new()
			content_vbox.name = "ContentVBox"
			content_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			content_margin.add_child(content_vbox)

		var title_label: Label = content_vbox.get_node_or_null("TitleLabel") as Label
		if title_label == null:
			title_label = Label.new()
			title_label.name = "TitleLabel"
			title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			content_vbox.add_child(title_label)

		var detail_label: Label = content_vbox.get_node_or_null("DetailLabel") as Label
		if detail_label == null:
			detail_label = Label.new()
			detail_label.name = "DetailLabel"
			detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			content_vbox.add_child(detail_label)


func _render_level_up_state() -> void:
	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	var note_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/NoteLabel") as Label
	_set_status_text(_presenter.build_initial_status_text())
	if title_label != null:
		title_label.text = _presenter.build_title_text(_level_up_state)
	if note_label != null:
		note_label.text = _presenter.build_note_text(_level_up_state)
		note_label.visible = not note_label.text.is_empty()

	var button_models: Array[Dictionary] = _presenter.build_offer_view_models(_level_up_state, BUTTON_NODE_NAMES.size())
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = get_node_or_null("Margin/VBox/ChoicesRow/%s" % BUTTON_NODE_NAMES[index]) as Button
		if button == null:
			continue
		var model: Dictionary = button_models[index]
		var title_text: String = String(model.get("title_text", ""))
		var detail_text: String = String(model.get("detail_text", ""))
		button.text = ""
		button.tooltip_text = String(model.get("text", ""))
		button.visible = bool(model.get("visible", false))
		button.disabled = bool(model.get("disabled", true))
		var title_copy_label: Label = get_node_or_null(_choice_title_path(BUTTON_NODE_NAMES[index])) as Label
		if title_copy_label != null:
			title_copy_label.text = title_text
		var detail_copy_label: Label = get_node_or_null(_choice_detail_path(BUTTON_NODE_NAMES[index])) as Label
		if detail_copy_label != null:
			detail_copy_label.text = detail_text

	_refresh_save_controls()


func _set_status_text(text: String) -> void:
	var status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/StatusCard/StatusLabel") as Label
	if status_label != null:
		status_label.text = text
		status_label.visible = not text.is_empty()


func _refresh_save_controls() -> void:
	if _safe_menu == null:
		return
	var has_save: bool = _bootstrap != null and _bootstrap.has_save_game()
	_safe_menu.set_load_available(_presenter != null and not _presenter.build_load_button_disabled(has_save))


func _configure_audio_players() -> void:
	SceneAudioPlayersScript.assign_stream_from_path(self, "UiConfirmSfxPlayer", UI_CONFIRM_SFX_PATH)
	SceneAudioPlayersScript.assign_stream_from_path(self, "PanelOpenSfxPlayer", PANEL_OPEN_SFX_PATH)
	SceneAudioPlayersScript.assign_music_stream_from_path(self, "LevelUpMusicPlayer", LEVEL_UP_MUSIC_LOOP_PATH, true)


func _apply_temp_theme() -> void:
	# Skip backdrop styling when used as overlay (map_explore handles it)
	var is_overlay: bool = self.top_level
	if not is_overlay:
		TempScreenThemeScript.apply_modal_popup_shell(
			self,
			get_node_or_null("Margin") as MarginContainer,
			get_node_or_null("Margin/VBox") as Control,
			TempScreenThemeScript.REWARD_ACCENT_COLOR,
			"ContentShell",
			34,
			100,
			34,
			100
		)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/NoteLabel") as Label, "muted")
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/HeaderRow/StatusCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 16, 0.88)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/HeaderRow/StatusCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 3, 18, 0.03, 0.18, 16, 12)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/StatusCard/StatusLabel") as Label, "muted")

	for button_name in BUTTON_NODE_NAMES:
		var action_button: Button = get_node_or_null("Margin/VBox/ChoicesRow/%s" % button_name) as Button
		TempScreenThemeScript.apply_button(action_button, TempScreenThemeScript.REWARD_ACCENT_COLOR)
		if action_button != null:
			action_button.custom_minimum_size = Vector2(0, 112)
			action_button.icon = null
			action_button.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var content_margin: MarginContainer = get_node_or_null(_choice_margin_path(button_name)) as MarginContainer
		if content_margin != null:
			content_margin.add_theme_constant_override("margin_left", 22)
			content_margin.add_theme_constant_override("margin_top", 16)
			content_margin.add_theme_constant_override("margin_right", 22)
			content_margin.add_theme_constant_override("margin_bottom", 16)

		var content_vbox: VBoxContainer = get_node_or_null(_choice_vbox_path(button_name)) as VBoxContainer
		if content_vbox != null:
			content_vbox.add_theme_constant_override("separation", 6)

		TempScreenThemeScript.apply_label(get_node_or_null(_choice_title_path(button_name)) as Label, "accent")
		TempScreenThemeScript.apply_label(get_node_or_null(_choice_detail_path(button_name)) as Label, "body")

	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 34)

	var note_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/NoteLabel") as Label
	if note_label != null:
		note_label.add_theme_font_size_override("font_size", 16)

	var status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/StatusCard/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 14)

	for button_name in BUTTON_NODE_NAMES:
		var action_button: Button = get_node_or_null("Margin/VBox/ChoicesRow/%s" % button_name) as Button
		if action_button != null:
			action_button.add_theme_font_size_override("font_size", 19)
		var title_copy_label: Label = get_node_or_null(_choice_title_path(button_name)) as Label
		if title_copy_label != null:
			title_copy_label.add_theme_font_size_override("font_size", 24)
		var detail_copy_label: Label = get_node_or_null(_choice_detail_path(button_name)) as Label
		if detail_copy_label != null:
			detail_copy_label.add_theme_font_size_override("font_size", 16)
			detail_copy_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_MUTED_COLOR)

	var vbox: VBoxContainer = get_node_or_null("Margin/VBox") as VBoxContainer
	if vbox != null:
		vbox.add_theme_constant_override("separation", 12)
	var choices_row: VBoxContainer = get_node_or_null("Margin/VBox/ChoicesRow") as VBoxContainer
	if choices_row != null:
		choices_row.add_theme_constant_override("separation", 10)


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
	var header_row: VBoxContainer = get_node_or_null("Margin/VBox/HeaderRow") as VBoxContainer
	var choices_row: VBoxContainer = get_node_or_null("Margin/VBox/ChoicesRow") as VBoxContainer
	if margin == null or vbox == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var top_margin: int = 120
	var bottom_margin: int = 120
	if viewport_size.y < 1760.0:
		top_margin = 92
		bottom_margin = 92
	if viewport_size.y < 1540.0:
		top_margin = 68
		bottom_margin = 68

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
	if choices_row != null:
		choices_row.add_theme_constant_override("separation", 12 if viewport_size.y < 1560.0 else 16)

	var large_layout: bool = safe_width >= 760 and viewport_size.y >= 1640.0
	var medium_layout: bool = not large_layout and safe_width >= 620 and viewport_size.y >= 1460.0
	var title_font_size: int = 46 if large_layout else 40 if medium_layout else 34
	var note_font_size: int = 21 if large_layout else 19 if medium_layout else 17
	var status_font_size: int = 19 if large_layout else 17 if medium_layout else 15
	var choice_title_font_size: int = 26 if large_layout else 23 if medium_layout else 20
	var choice_detail_font_size: int = 17 if large_layout else 16 if medium_layout else 14
	var button_height: float = 142.0 if large_layout else 124.0 if medium_layout else 108.0
	var status_width: float = 320.0 if large_layout else 272.0 if medium_layout else 232.0

	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", title_font_size)
	var note_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/NoteLabel") as Label
	if note_label != null:
		note_label.add_theme_font_size_override("font_size", note_font_size)
	var status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/StatusCard/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", status_font_size)
	var status_card: PanelContainer = get_node_or_null("Margin/VBox/HeaderRow/StatusCard") as PanelContainer
	if status_card != null:
		status_card.custom_minimum_size = Vector2(status_width, 0.0)

	for button_name in BUTTON_NODE_NAMES:
		var action_button: Button = get_node_or_null("Margin/VBox/ChoicesRow/%s" % button_name) as Button
		if action_button != null:
			action_button.custom_minimum_size = Vector2(0.0, button_height)
			action_button.add_theme_constant_override("icon_max_width", 30 if large_layout else 26 if medium_layout else 22)
		var title_copy_label: Label = get_node_or_null(_choice_title_path(button_name)) as Label
		if title_copy_label != null:
			title_copy_label.add_theme_font_size_override("font_size", choice_title_font_size)
		var detail_copy_label: Label = get_node_or_null(_choice_detail_path(button_name)) as Label
		if detail_copy_label != null:
			detail_copy_label.add_theme_font_size_override("font_size", choice_detail_font_size)


func _choice_margin_path(button_name: String) -> String:
	return "Margin/VBox/ChoicesRow/%s/ContentMargin" % button_name


func _choice_vbox_path(button_name: String) -> String:
	return "%s/ContentVBox" % _choice_margin_path(button_name)


func _choice_title_path(button_name: String) -> String:
	return "%s/TitleLabel" % _choice_vbox_path(button_name)


func _choice_detail_path(button_name: String) -> String:
	return "%s/DetailLabel" % _choice_vbox_path(button_name)
