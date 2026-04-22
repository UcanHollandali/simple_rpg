# Layer: Scenes - presentation only
extends Control

const BUTTON_NODE_NAMES: PackedStringArray = ["ChoiceAButton", "ChoiceBButton", "ChoiceCButton"]
const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const LevelUpPresenterScript = preload("res://Game/UI/level_up_presenter.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const StackedButtonContentScript = preload("res://Game/UI/stacked_button_content.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const PORTRAIT_SAFE_MAX_WIDTH := 920
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 30
const HEADER_CARD_PATH := "Margin/VBox/HeaderRow/HeaderCard"
const HEADER_STACK_PATH := HEADER_CARD_PATH + "/HeaderStack"
const AUDIO_PLAYER_CONFIG := {
	"UiConfirmSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"},
	"PanelOpenSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"},
	"LevelUpMusicPlayer": {"path": "res://Assets/Audio/Music/music_ui_hub_loop_proto_01.ogg", "music": true, "loop": true},
}
const PORTRAIT_LAYOUT_CONFIG := {
	"max_width": PORTRAIT_SAFE_MAX_WIDTH,
	"min_side_margin": PORTRAIT_SAFE_MIN_SIDE_MARGIN,
	"top_margin": 120,
	"bottom_margin": 120,
	"margin_steps": [
		{"max_height": 1760.0, "top_margin": 92, "bottom_margin": 92},
		{"max_height": 1540.0, "top_margin": 68, "bottom_margin": 68},
	],
	"bands": {
		"large": {"min_width": 760.0, "min_height": 1640.0, "title_font_size": 44, "context_font_size": 20, "hint_font_size": 16, "note_font_size": 20, "status_font_size": 16, "choice_title_font_size": 24, "choice_detail_font_size": 16, "button_height": 142.0, "status_width": 320.0, "button_icon_max_width": 30},
		"medium": {"min_width": 620.0, "min_height": 1460.0, "title_font_size": 38, "context_font_size": 18, "hint_font_size": 15, "note_font_size": 18, "status_font_size": 15, "choice_title_font_size": 22, "choice_detail_font_size": 15, "button_height": 124.0, "status_width": 272.0, "button_icon_max_width": 26},
		"compact": {"title_font_size": 32, "context_font_size": 16, "hint_font_size": 14, "note_font_size": 16, "status_font_size": 14, "choice_title_font_size": 20, "choice_detail_font_size": 14, "button_height": 108.0, "status_width": 232.0, "button_icon_max_width": 22},
	},
}

var _bootstrap: AppBootstrapScript
var _presenter: LevelUpPresenter
var _level_up_state: LevelUpState
var _safe_menu: SafeMenuOverlay
var _scene_node_cache: Dictionary = {}

@onready var _header_chip_label: Label = _scene_node("%s/ChipCard/ChipLabel" % HEADER_STACK_PATH) as Label
@onready var _header_title_label: Label = _scene_node("%s/TitleLabel" % HEADER_STACK_PATH) as Label
@onready var _header_context_label: Label = _scene_node("%s/ContextLabel" % HEADER_STACK_PATH) as Label
@onready var _header_hint_label: Label = _scene_node("%s/HintLabel" % HEADER_STACK_PATH) as Label
@onready var _header_note_label: Label = _scene_node("%s/NoteLabel" % HEADER_STACK_PATH) as Label
@onready var _status_label: Label = _scene_node("Margin/VBox/HeaderRow/StatusCard/StatusLabel") as Label


func _ready() -> void:
	_scene_node_cache.clear()
	_bootstrap = _scene_node("/root/AppBootstrap") as AppBootstrapScript
	_presenter = LevelUpPresenterScript.new()
	_level_up_state = null
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	if _bootstrap != null:
		_level_up_state = _bootstrap.get_level_up_state()

	_connect_buttons()
	_ensure_choice_button_content()
	_apply_temp_theme()
	_hide_status_card()
	_setup_safe_menu()
	SceneLayoutHelperScript.bind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	_apply_portrait_safe_layout()
	_render_level_up_state()
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")
	SceneAudioPlayersScript.start_looping(self, "LevelUpMusicPlayer")


func _exit_tree() -> void:
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	SceneAudioCleanupScript.release_players(self, SceneAudioPlayersScript.node_names_from_config(AUDIO_PLAYER_CONFIG))


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


func _on_return_to_main_menu_pressed() -> void:
	if _bootstrap == null:
		return
	var flow_manager = _bootstrap.get_flow_manager()
	if flow_manager == null:
		return
	flow_manager.request_transition(FlowStateScript.Type.MAIN_MENU)


func _connect_buttons() -> void:
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = _scene_node("Margin/VBox/ChoicesRow/%s" % BUTTON_NODE_NAMES[index]) as Button
		if button == null:
			continue
		var handler: Callable = Callable(self, "_on_offer_pressed").bind(index)
		if not button.is_connected("pressed", handler):
			button.connect("pressed", handler)


func _ensure_choice_button_content() -> void:
	for button_name in BUTTON_NODE_NAMES:
		var button: Button = _scene_node("Margin/VBox/ChoicesRow/%s" % button_name) as Button
		if button == null:
			continue
		StackedButtonContentScript.ensure(button)
		button.icon = null


func _render_level_up_state() -> void:
	_set_status_text("")
	if _header_chip_label != null:
		_header_chip_label.text = _presenter.build_chip_text()
	if _header_title_label != null:
		_header_title_label.text = _presenter.build_title_text(_level_up_state)
	if _header_context_label != null:
		_header_context_label.text = _presenter.build_context_text(_level_up_state)
	if _header_hint_label != null:
		_header_hint_label.text = _presenter.build_hint_text(_level_up_state)
	if _header_note_label != null:
		_header_note_label.text = _presenter.build_note_text(_level_up_state)
		_header_note_label.visible = not _header_note_label.text.is_empty()

	var button_models: Array[Dictionary] = _presenter.build_offer_view_models(_level_up_state, BUTTON_NODE_NAMES.size())
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = _scene_node("Margin/VBox/ChoicesRow/%s" % BUTTON_NODE_NAMES[index]) as Button
		if button == null:
			continue
		var model: Dictionary = button_models[index]
		var title_text: String = String(model.get("title_text", ""))
		var detail_text: String = String(model.get("detail_text", ""))
		button.text = ""
		button.tooltip_text = String(model.get("text", ""))
		button.visible = bool(model.get("visible", false))
		button.disabled = bool(model.get("disabled", true))
		button.icon = null
		StackedButtonContentScript.apply(
			button,
			title_text,
			detail_text,
			SceneLayoutHelperScript.load_texture_or_null(String(model.get("icon_texture_path", "")))
		)

	_refresh_save_controls()


func _set_status_text(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
		_status_label.visible = not text.is_empty()


func _refresh_save_controls() -> void:
	if _safe_menu == null:
		return
	var has_save: bool = _bootstrap != null and _bootstrap.has_save_game()
	_safe_menu.set_load_available(_presenter != null and not _presenter.build_load_button_disabled(has_save))

func _apply_temp_theme() -> void:
	var is_overlay: bool = self.top_level
	if is_overlay:
		for node_name in ["BackgroundFar", "BackgroundMid", "BackgroundOverlay"]:
			var backdrop: CanvasItem = _scene_node(node_name) as CanvasItem
			if backdrop != null:
				backdrop.visible = false
		var scrim: ColorRect = _scene_node("Scrim") as ColorRect
		if scrim != null:
			scrim.visible = true
			TempScreenThemeScript.apply_scrim(scrim)
			scrim.color = Color(scrim.color.r, scrim.color.g, scrim.color.b, 0.38)
		var margin: MarginContainer = _scene_node("Margin") as MarginContainer
		if margin != null:
			var overlay_margins: Dictionary = TempScreenThemeScript.compute_overlay_margins(get_viewport_rect().size, PORTRAIT_SAFE_MAX_WIDTH, PORTRAIT_SAFE_MIN_SIDE_MARGIN)
			margin.add_theme_constant_override("margin_left", int(overlay_margins.get("left", PORTRAIT_SAFE_MIN_SIDE_MARGIN)))
			margin.add_theme_constant_override("margin_top", int(overlay_margins.get("top", 40)))
			margin.add_theme_constant_override("margin_right", int(overlay_margins.get("right", PORTRAIT_SAFE_MIN_SIDE_MARGIN)))
			margin.add_theme_constant_override("margin_bottom", int(overlay_margins.get("bottom", 40)))
	else:
		TempScreenThemeScript.apply_modal_popup_shell(
			self,
			_scene_node("Margin") as MarginContainer,
			_scene_node("Margin/VBox") as Control,
			TempScreenThemeScript.REWARD_ACCENT_COLOR,
			"ContentShell",
			34,
			100,
			34,
			100
		)
	TempScreenThemeScript.apply_chip(
		_scene_node("%s/ChipCard" % HEADER_STACK_PATH) as PanelContainer,
		_header_chip_label,
		TempScreenThemeScript.REWARD_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_choice_card_shell(
		_scene_node(HEADER_CARD_PATH) as PanelContainer,
		TempScreenThemeScript.REWARD_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_compact_status_area(
		_scene_node("Margin/VBox/HeaderRow/StatusCard") as PanelContainer,
		TempScreenThemeScript.PANEL_BORDER_COLOR
	)
	SceneLayoutHelperScript.apply_label_tones(self, [
		{"path": "%s/TitleLabel" % HEADER_STACK_PATH, "tone": "title"},
		{"path": "%s/ContextLabel" % HEADER_STACK_PATH, "tone": "reward"},
		{"path": "%s/HintLabel" % HEADER_STACK_PATH, "tone": "muted"},
		{"path": "%s/NoteLabel" % HEADER_STACK_PATH, "tone": "muted"},
		{"path": "Margin/VBox/HeaderRow/StatusCard/StatusLabel", "tone": "muted"},
	])

	for button_name in BUTTON_NODE_NAMES:
		var action_button: Button = _scene_node("Margin/VBox/ChoicesRow/%s" % button_name) as Button
		TempScreenThemeScript.apply_button(action_button, TempScreenThemeScript.REWARD_ACCENT_COLOR)
		if action_button != null:
			action_button.custom_minimum_size = Vector2(0, 112)
			action_button.icon = null
			action_button.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var content_margin: MarginContainer = _scene_node(_choice_margin_path(button_name)) as MarginContainer
		if content_margin != null:
			content_margin.add_theme_constant_override("margin_left", 22)
			content_margin.add_theme_constant_override("margin_top", 16)
			content_margin.add_theme_constant_override("margin_right", 22)
			content_margin.add_theme_constant_override("margin_bottom", 16)

		var content_row: HBoxContainer = _scene_node(_choice_row_path(button_name)) as HBoxContainer
		if content_row != null:
			content_row.add_theme_constant_override("separation", 12)

		var content_vbox: VBoxContainer = _scene_node(_choice_vbox_path(button_name)) as VBoxContainer
		if content_vbox != null:
			content_vbox.add_theme_constant_override("separation", 6)

		TempScreenThemeScript.apply_label(_scene_node(_choice_title_path(button_name)) as Label, "accent")
		TempScreenThemeScript.apply_label(_scene_node(_choice_detail_path(button_name)) as Label, "muted")
	SceneLayoutHelperScript.apply_control_overrides(self, {}, [
		{"path": "%s/TitleLabel" % HEADER_STACK_PATH, "font_size": 34},
		{"path": "%s/ContextLabel" % HEADER_STACK_PATH, "font_size": 16},
		{"path": "%s/HintLabel" % HEADER_STACK_PATH, "font_size": 15},
		{"path": "%s/NoteLabel" % HEADER_STACK_PATH, "font_size": 16},
		{"path": "Margin/VBox/HeaderRow/StatusCard/StatusLabel", "font_size": 14},
		{"path": HEADER_STACK_PATH, "size_flags_horizontal": Control.SIZE_EXPAND_FILL},
		{"paths": [
			"%s/TitleLabel" % HEADER_STACK_PATH,
			"%s/ContextLabel" % HEADER_STACK_PATH,
			"%s/HintLabel" % HEADER_STACK_PATH,
			"%s/NoteLabel" % HEADER_STACK_PATH,
		], "horizontal_alignment": HORIZONTAL_ALIGNMENT_LEFT, "size_flags_horizontal": Control.SIZE_EXPAND_FILL, "autowrap_mode": TextServer.AUTOWRAP_WORD_SMART},
	])
	for button_name in BUTTON_NODE_NAMES:
		SceneLayoutHelperScript.apply_control_overrides(self, {}, [
			{"path": "Margin/VBox/ChoicesRow/%s" % button_name, "font_size": 19},
			{"path": _choice_title_path(button_name), "font_size": 24},
			{"path": _choice_detail_path(button_name), "font_size": 16},
			{"path": _choice_icon_path(button_name), "custom_minimum_size": {"x": 26.0, "y": 26.0}},
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
	values["vbox_separation"] = 12 if viewport_size.y < 1560.0 else 16
	SceneLayoutHelperScript.apply_control_overrides(self, values, [
		{"path": "Margin/VBox", "theme_constants": {"separation": "vbox_separation"}},
		{"path": "Margin/VBox/HeaderRow", "theme_constants": {"separation": "vbox_separation"}},
		{"path": "Margin/VBox/ChoicesRow", "theme_constants": {"separation": "vbox_separation"}},
		{"path": "%s/TitleLabel" % HEADER_STACK_PATH, "font_size": "title_font_size"},
		{"path": "%s/ContextLabel" % HEADER_STACK_PATH, "font_size": "context_font_size"},
		{"path": "%s/HintLabel" % HEADER_STACK_PATH, "font_size": "hint_font_size"},
		{"path": "%s/NoteLabel" % HEADER_STACK_PATH, "font_size": "note_font_size"},
		{"path": "Margin/VBox/HeaderRow/StatusCard/StatusLabel", "font_size": "status_font_size"},
		{"path": "Margin/VBox/HeaderRow/StatusCard", "custom_minimum_size": {"x": "status_width", "y": 0.0}},
		{"path": HEADER_STACK_PATH, "size_flags_horizontal": Control.SIZE_EXPAND_FILL},
	])
	for button_name in BUTTON_NODE_NAMES:
		SceneLayoutHelperScript.apply_control_overrides(self, values, [
			{"path": "Margin/VBox/ChoicesRow/%s" % button_name, "custom_minimum_size": {"x": 0.0, "y": "button_height"}},
			{"path": _choice_title_path(button_name), "font_size": "choice_title_font_size"},
			{"path": _choice_detail_path(button_name), "font_size": "choice_detail_font_size"},
			{"path": _choice_icon_path(button_name), "custom_minimum_size": {"x": "button_icon_max_width", "y": "button_icon_max_width"}},
		])

func _hide_status_card() -> void:
	var status_card: PanelContainer = _scene_node("Margin/VBox/HeaderRow/StatusCard") as PanelContainer
	if status_card == null:
		return
	status_card.visible = false
	status_card.custom_minimum_size = Vector2.ZERO


func _get_run_state() -> RunState:
	if _bootstrap == null:
		return null
	return _bootstrap.get_run_state()


func _choice_margin_path(button_name: String) -> String:
	return "Margin/VBox/ChoicesRow/%s/ContentMargin" % button_name


func _choice_row_path(button_name: String) -> String:
	return "Margin/VBox/ChoicesRow/%s/ContentMargin/ContentRow" % button_name


func _choice_vbox_path(button_name: String) -> String:
	return "%s/ContentVBox" % _choice_row_path(button_name)


func _choice_title_path(button_name: String) -> String:
	return "%s/TitleLabel" % _choice_vbox_path(button_name)


func _choice_detail_path(button_name: String) -> String:
	return "%s/DetailLabel" % _choice_vbox_path(button_name)


func _choice_icon_path(button_name: String) -> String:
	return "%s/IconTexture" % _choice_row_path(button_name)


func _scene_node(path: String) -> Node:
	if not is_inside_tree() and path.begins_with("/root/"):
		return null
	if _scene_node_cache.has(path):
		var cached_node: Node = _scene_node_cache.get(path) as Node
		if cached_node != null and is_instance_valid(cached_node):
			return cached_node
		_scene_node_cache.erase(path)
	var node: Node = get_node_or_null(path)
	if node != null:
		_scene_node_cache[path] = node
	return node
