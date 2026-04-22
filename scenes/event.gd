# Layer: Scenes - presentation only
extends Control

const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const EventPresenterScript = preload("res://Game/UI/event_presenter.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const InventoryTooltipControllerScript = preload("res://Game/UI/inventory_tooltip_controller.gd")
const InventoryOverflowPromptScript = preload("res://Game/UI/inventory_overflow_prompt.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const CARD_NODE_NAMES: PackedStringArray = ["ChoiceACard", "ChoiceBCard"]
const BUTTON_NODE_NAMES: PackedStringArray = ["ChoiceAButton", "ChoiceBButton"]
const CUSTOM_TOOLTIP_META_KEY := "custom_tooltip_text"
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const PORTRAIT_SAFE_MAX_WIDTH := 920
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 30
const OFFERS_SHELL_PATH := "Margin/VBox/OffersShell"
const OFFERS_CONTENT_PATH := OFFERS_SHELL_PATH + "/VBox"
const HEADER_CARD_PATH := OFFERS_CONTENT_PATH + "/HeaderRow/HeaderCard"
const HEADER_STACK_PATH := HEADER_CARD_PATH + "/HeaderStack"
const RUN_STATUS_CARD_PATH := OFFERS_CONTENT_PATH + "/HeaderRow/RunStatusCard"
const CARDS_ROW_PATH := OFFERS_CONTENT_PATH + "/CardsRow"
const STATUS_LABEL_PATH := "Margin/VBox/StatusLabel"
const OVERLAY_SCRIM_ALPHA := 0.38
const ROADSIDE_OVERLAY_SCRIM_ALPHA := 0.54
const AUDIO_PLAYER_CONFIG := {
	"UiConfirmSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"},
	"PanelOpenSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"},
	"EventMusicPlayer": {"path": "res://Assets/Audio/Music/music_ui_hub_loop_proto_01.ogg", "music": true, "loop": true},
}
const PORTRAIT_LAYOUT_CONFIG := {
	"max_width": PORTRAIT_SAFE_MAX_WIDTH,
	"min_side_margin": PORTRAIT_SAFE_MIN_SIDE_MARGIN,
	"top_margin": 124,
	"bottom_margin": 124,
	"margin_steps": [
		{"max_height": 1760.0, "top_margin": 96, "bottom_margin": 96},
		{"max_height": 1540.0, "top_margin": 72, "bottom_margin": 72},
	],
	"bands": {
		"large": {"min_width": 760.0, "min_height": 1640.0, "title_font_size": 44, "summary_font_size": 20, "context_font_size": 20, "hint_font_size": 16, "status_font_size": 16, "card_title_font_size": 24, "card_detail_font_size": 16, "button_font_size": 20, "button_height": 78.0, "card_height": 224.0, "button_icon_max_width": 30},
		"medium": {"min_width": 620.0, "min_height": 1460.0, "title_font_size": 38, "summary_font_size": 18, "context_font_size": 18, "hint_font_size": 15, "status_font_size": 15, "card_title_font_size": 22, "card_detail_font_size": 15, "button_font_size": 18, "button_height": 70.0, "card_height": 196.0, "button_icon_max_width": 26},
		"compact": {"title_font_size": 32, "summary_font_size": 16, "context_font_size": 16, "hint_font_size": 14, "status_font_size": 14, "card_title_font_size": 20, "card_detail_font_size": 14, "button_font_size": 17, "button_height": 62.0, "card_height": 172.0, "button_icon_max_width": 22},
	},
}

var _bootstrap: AppBootstrapScript
var _event_state: EventState
var _run_state: RunState
var _presenter: EventPresenter
var _choice_in_flight: bool = false
var _choice_tooltip_controller: InventoryTooltipController
var _safe_menu: SafeMenuOverlay
var _overflow_prompt: InventoryOverflowPrompt
var _pending_overflow_choice_id: String = ""
var _scene_node_cache: Dictionary = {}

@onready var _header_chip_label: Label = _scene_node("%s/ChipCard/ChipLabel" % HEADER_STACK_PATH) as Label
@onready var _header_title_label: Label = _scene_node("%s/TitleLabel" % HEADER_STACK_PATH) as Label
@onready var _header_context_label: Label = _scene_node("%s/ContextLabel" % HEADER_STACK_PATH) as Label
@onready var _header_summary_label: Label = _scene_node("%s/SummaryLabel" % HEADER_STACK_PATH) as Label
@onready var _header_hint_label: Label = _scene_node("%s/HintLabel" % HEADER_STACK_PATH) as Label
@onready var _status_label: Label = _scene_node(STATUS_LABEL_PATH) as Label
@onready var _run_status_card: PanelContainer = _scene_node(RUN_STATUS_CARD_PATH) as PanelContainer


func _ready() -> void:
	_scene_node_cache.clear()
	_bootstrap = _scene_node("/root/AppBootstrap") as AppBootstrapScript
	_event_state = null
	_run_state = null
	_presenter = EventPresenterScript.new()
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	if _bootstrap != null:
		_event_state = _bootstrap.get_event_state()
		_run_state = _bootstrap.get_run_state()

	_setup_choice_tooltip()
	_connect_buttons()
	_apply_temp_theme()
	_hide_run_status_card()
	_setup_safe_menu()
	_setup_overflow_prompt()
	SceneLayoutHelperScript.bind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	_apply_portrait_safe_layout()
	_render_event_state()
	SceneAudioPlayersScript.start_looping(self, "EventMusicPlayer")
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")


func _exit_tree() -> void:
	if _choice_tooltip_controller != null:
		_choice_tooltip_controller.release()
		_choice_tooltip_controller = null
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	SceneAudioCleanupScript.release_players(self, SceneAudioPlayersScript.node_names_from_config(AUDIO_PLAYER_CONFIG))


func _on_offer_pressed(index: int) -> void:
	if _choice_in_flight:
		return
	if _bootstrap == null or _event_state == null:
		return
	if index < 0 or index >= _event_state.choices.size():
		return

	var choice: Dictionary = _event_state.choices[index]
	var choice_id: String = String(choice.get("choice_id", ""))
	if choice_id.is_empty():
		return

	if _choice_tooltip_controller != null:
		_choice_tooltip_controller.hide(true)
	_choice_in_flight = true
	_set_offer_buttons_interactable(false)
	SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
	await SceneAudioPlayersScript.wait_for_lead_in(self, "UiConfirmSfxPlayer", ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS)
	var result: Dictionary = _bootstrap.choose_event_option(choice_id)
	if bool(result.get("ok", false)):
		return
	if String(result.get("error", "")) == "inventory_choice_required":
		_choice_in_flight = false
		_present_inventory_overflow_prompt(choice_id, result)
		return

	_choice_in_flight = false
	_set_offer_buttons_interactable(true)
	_set_status_text(_presenter.build_choice_failure_text(_event_state, String(result.get("error", "unknown"))))


func _connect_buttons() -> void:
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = _scene_node(_button_path(index)) as Button
		if button == null:
			continue
		var handler: Callable = Callable(self, "_on_offer_pressed").bind(index)
		if not button.is_connected("pressed", handler):
			button.connect("pressed", handler)
		var mouse_entered_handler: Callable = Callable(self, "_on_choice_button_mouse_entered").bind(button)
		if not button.is_connected("mouse_entered", mouse_entered_handler):
			button.connect("mouse_entered", mouse_entered_handler)
		var mouse_exited_handler: Callable = Callable(self, "_on_choice_button_mouse_exited").bind(button)
		if not button.is_connected("mouse_exited", mouse_exited_handler):
			button.connect("mouse_exited", mouse_exited_handler)


func _render_event_state() -> void:
	_set_status_text("")
	if _header_chip_label != null:
		_header_chip_label.text = _presenter.build_chip_text(_event_state)
	if _header_title_label != null:
		_header_title_label.text = _presenter.build_title_text(_event_state)
	if _header_context_label != null:
		_header_context_label.text = _presenter.build_context_text(_event_state)
	if _header_summary_label != null:
		_header_summary_label.text = _presenter.build_summary_text(_event_state)
	if _header_hint_label != null:
		_header_hint_label.text = _presenter.build_hint_text()
		_header_hint_label.visible = not _header_hint_label.text.is_empty()
	_refresh_save_controls()

	var card_models: Array[Dictionary] = _presenter.build_choice_view_models(_event_state, CARD_NODE_NAMES.size())
	for index in range(CARD_NODE_NAMES.size()):
		var card: Control = _scene_node(_card_path(index)) as Control
		var badge_label: Label = _scene_node(_card_label_path(index, "BadgeLabel")) as Label
		var choice_title_label: Label = _scene_node(_card_label_path(index, "ChoiceTitleLabel")) as Label
		var choice_detail_label: Label = _scene_node(_card_label_path(index, "ChoiceDetailLabel")) as Label
		var button: Button = _scene_node(_button_path(index)) as Button
		var model: Dictionary = card_models[index]
		var tooltip_text: String = String(model.get("tooltip_text", ""))
		if card != null:
			card.visible = bool(model.get("visible", false))
			card.tooltip_text = ""
			card.set_meta(CUSTOM_TOOLTIP_META_KEY, tooltip_text)
		if badge_label != null:
			badge_label.text = String(model.get("badge_text", ""))
		if choice_title_label != null:
			choice_title_label.text = String(model.get("title_text", ""))
		if choice_detail_label != null:
			choice_detail_label.text = String(model.get("detail_text", ""))
		if button != null:
			button.text = String(model.get("button_text", ""))
			button.tooltip_text = ""
			button.set_meta(CUSTOM_TOOLTIP_META_KEY, tooltip_text)
			button.disabled = bool(model.get("button_disabled", true))
			button.icon = SceneLayoutHelperScript.load_texture_or_null(String(model.get("icon_texture_path", "")))


func _set_offer_buttons_interactable(is_interactable: bool) -> void:
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = _scene_node(_button_path(index)) as Button
		if button == null or not button.visible:
			continue
		button.disabled = not is_interactable


func _set_status_text(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
		_status_label.visible = not text.is_empty()


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
	if _bootstrap == null:
		return
	var flow_manager = _bootstrap.get_flow_manager()
	if flow_manager == null:
		return
	flow_manager.request_transition(FlowStateScript.Type.MAIN_MENU)


func _refresh_save_controls() -> void:
	RunMenuSceneHelperScript.sync_load_available(_safe_menu, _bootstrap)


func _setup_choice_tooltip() -> void:
	_choice_tooltip_controller = InventoryTooltipControllerScript.new()
	_choice_tooltip_controller.configure(self)


func _on_choice_button_mouse_entered(button: Button) -> void:
	if _choice_tooltip_controller == null or button == null:
		return
	_choice_tooltip_controller.on_inventory_card_mouse_entered(button, TempScreenThemeScript.TEAL_ACCENT_COLOR)


func _on_choice_button_mouse_exited(button: Button) -> void:
	if _choice_tooltip_controller == null or button == null:
		return
	_choice_tooltip_controller.on_inventory_card_mouse_exited(button)


func _card_path(index: int) -> String:
	return "%s/%s" % [CARDS_ROW_PATH, CARD_NODE_NAMES[index]]


func _card_label_path(index: int, label_name: String) -> String:
	return "%s/VBox/%s" % [_card_path(index), label_name]


func _button_path(index: int) -> String:
	return "%s/VBox/%s" % [_card_path(index), BUTTON_NODE_NAMES[index]]


func _apply_temp_theme() -> void:
	var margin: MarginContainer = _scene_node("Margin") as MarginContainer
	var is_overlay: bool = self.top_level
	var roadside_overlay: bool = is_overlay and _is_roadside_overlay_context()
	if is_overlay:
		for node_name in ["BackgroundFar", "BackgroundMid", "BackgroundOverlay"]:
			var backdrop: CanvasItem = _scene_node(node_name) as CanvasItem
			if backdrop != null:
				backdrop.visible = false
		var scrim: ColorRect = _scene_node("Scrim") as ColorRect
		if scrim != null:
			scrim.visible = true
			TempScreenThemeScript.apply_scrim(scrim)
			var scrim_alpha: float = ROADSIDE_OVERLAY_SCRIM_ALPHA if roadside_overlay else OVERLAY_SCRIM_ALPHA
			scrim.color = Color(scrim.color.r, scrim.color.g, scrim.color.b, scrim_alpha)
		if margin != null:
			var overlay_margins: Dictionary = TempScreenThemeScript.compute_overlay_margins(get_viewport_rect().size, PORTRAIT_SAFE_MAX_WIDTH, PORTRAIT_SAFE_MIN_SIDE_MARGIN)
			margin.add_theme_constant_override("margin_left", int(overlay_margins.get("left", PORTRAIT_SAFE_MIN_SIDE_MARGIN)))
			margin.add_theme_constant_override("margin_top", int(overlay_margins.get("top", 40)))
			margin.add_theme_constant_override("margin_right", int(overlay_margins.get("right", PORTRAIT_SAFE_MIN_SIDE_MARGIN)))
			margin.add_theme_constant_override("margin_bottom", int(overlay_margins.get("bottom", 40)))
	else:
		TempScreenThemeScript.apply_modal_popup_shell(
			self,
			margin,
			_scene_node("Margin/VBox") as Control,
			TempScreenThemeScript.TEAL_ACCENT_COLOR,
			"ContentShell",
			40,
			110,
			40,
			110
		)
	TempScreenThemeScript.apply_panel(
		_scene_node(OFFERS_SHELL_PATH) as PanelContainer,
		TempScreenThemeScript.PANEL_BORDER_COLOR,
		28,
		0.6
	)
	TempScreenThemeScript.intensify_panel(
		_scene_node(OFFERS_SHELL_PATH) as PanelContainer,
		TempScreenThemeScript.PANEL_BORDER_COLOR,
		3,
		28,
		0.01,
		0.18,
		20,
		18
	)
	TempScreenThemeScript.apply_panel(
		_scene_node(HEADER_CARD_PATH) as PanelContainer,
		TempScreenThemeScript.TEAL_ACCENT_COLOR,
		20,
		0.74
	)
	TempScreenThemeScript.intensify_panel(
		_scene_node(HEADER_CARD_PATH) as PanelContainer,
		TempScreenThemeScript.TEAL_ACCENT_COLOR,
		3,
		18,
		0.02,
		0.18,
		18,
		14
	)
	TempScreenThemeScript.apply_chip(
		_scene_node("%s/ChipCard" % HEADER_STACK_PATH) as PanelContainer,
		_header_chip_label,
		TempScreenThemeScript.TEAL_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_compact_status_area(
		_run_status_card,
		TempScreenThemeScript.PANEL_BORDER_COLOR
	)
	SceneLayoutHelperScript.apply_label_tones(self, [
		{"path": "%s/TitleLabel" % HEADER_STACK_PATH, "tone": "title"},
		{"path": "%s/SummaryLabel" % HEADER_STACK_PATH, "tone": "muted"},
		{"path": "%s/ContextLabel" % HEADER_STACK_PATH, "tone": "reward"},
		{"path": "%s/HintLabel" % HEADER_STACK_PATH, "tone": "muted"},
		{"path": "%s/RunStatusLabel" % RUN_STATUS_CARD_PATH, "tone": "muted"},
		{"path": STATUS_LABEL_PATH, "tone": "body"},
	])
	SceneLayoutHelperScript.apply_control_overrides(self, {}, [
		{"path": HEADER_STACK_PATH, "size_flags_horizontal": Control.SIZE_EXPAND_FILL},
		{"paths": [
			"%s/ChipCard/ChipLabel" % HEADER_STACK_PATH,
			"%s/TitleLabel" % HEADER_STACK_PATH,
			"%s/SummaryLabel" % HEADER_STACK_PATH,
			"%s/ContextLabel" % HEADER_STACK_PATH,
			"%s/HintLabel" % HEADER_STACK_PATH,
		], "horizontal_alignment": HORIZONTAL_ALIGNMENT_LEFT, "size_flags_horizontal": Control.SIZE_EXPAND_FILL, "autowrap_mode": TextServer.AUTOWRAP_WORD_SMART},
		{"path": "%s/RunStatusLabel" % RUN_STATUS_CARD_PATH, "size_flags_horizontal": Control.SIZE_EXPAND_FILL, "autowrap_mode": TextServer.AUTOWRAP_OFF},
	])

	for card_name in CARD_NODE_NAMES:
		var choice_card: PanelContainer = _scene_node("%s/%s" % [CARDS_ROW_PATH, card_name]) as PanelContainer
		TempScreenThemeScript.apply_choice_card_shell(choice_card, TempScreenThemeScript.TEAL_ACCENT_COLOR)
		TempScreenThemeScript.apply_label(_scene_node("%s/%s/VBox/BadgeLabel" % [CARDS_ROW_PATH, card_name]) as Label, "accent")
		TempScreenThemeScript.apply_label(_scene_node("%s/%s/VBox/ChoiceTitleLabel" % [CARDS_ROW_PATH, card_name]) as Label, "title")
		TempScreenThemeScript.apply_label(_scene_node("%s/%s/VBox/ChoiceDetailLabel" % [CARDS_ROW_PATH, card_name]) as Label)
		SceneLayoutHelperScript.apply_control_overrides(self, {}, [
			{"paths": [
				"%s/%s/VBox/BadgeLabel" % [CARDS_ROW_PATH, card_name],
				"%s/%s/VBox/ChoiceTitleLabel" % [CARDS_ROW_PATH, card_name],
				"%s/%s/VBox/ChoiceDetailLabel" % [CARDS_ROW_PATH, card_name],
			], "horizontal_alignment": HORIZONTAL_ALIGNMENT_LEFT},
		])

	for button_name in BUTTON_NODE_NAMES:
		var choice_button: Button = _scene_node("%s/%s/VBox/%s" % [CARDS_ROW_PATH, _event_card_name_for_button(button_name), button_name]) as Button
		TempScreenThemeScript.apply_button(choice_button, TempScreenThemeScript.TEAL_ACCENT_COLOR)
		SceneLayoutHelperScript.apply_control_overrides(self, {}, [
			{"path": "%s/%s/VBox/%s" % [CARDS_ROW_PATH, _event_card_name_for_button(button_name), button_name], "alignment": HORIZONTAL_ALIGNMENT_LEFT},
		])


func _setup_overflow_prompt() -> void:
	_overflow_prompt = InventoryOverflowPromptScript.new()
	_overflow_prompt.name = "InventoryOverflowPrompt"
	_overflow_prompt.configure(TempScreenThemeScript.TEAL_ACCENT_COLOR)
	add_child(_overflow_prompt)
	_overflow_prompt.discard_requested.connect(_on_overflow_discard_requested)
	_overflow_prompt.leave_requested.connect(_on_overflow_leave_requested)


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


func _present_inventory_overflow_prompt(choice_id: String, prompt_result: Dictionary) -> void:
	_pending_overflow_choice_id = choice_id
	if _overflow_prompt == null:
		return
	_overflow_prompt.present(prompt_result, "Leave Item")


func _clear_overflow_prompt() -> void:
	_pending_overflow_choice_id = ""
	if _overflow_prompt != null:
		_overflow_prompt.dismiss()


func _on_overflow_discard_requested(slot_id: int) -> void:
	if _bootstrap == null or _pending_overflow_choice_id.is_empty():
		return
	_choice_in_flight = true
	var result: Dictionary = _bootstrap.choose_event_option(_pending_overflow_choice_id, slot_id, false)
	if bool(result.get("ok", false)):
		_clear_overflow_prompt()
		return
	_choice_in_flight = false
	_clear_overflow_prompt()
	_set_offer_buttons_interactable(true)
	_set_status_text(_presenter.build_choice_failure_text(_event_state, String(result.get("error", "unknown"))))


func _on_overflow_leave_requested() -> void:
	if _bootstrap == null or _pending_overflow_choice_id.is_empty():
		return
	_choice_in_flight = true
	var result: Dictionary = _bootstrap.choose_event_option(_pending_overflow_choice_id, -1, true)
	if bool(result.get("ok", false)):
		_clear_overflow_prompt()
		return
	_choice_in_flight = false
	_clear_overflow_prompt()
	_set_offer_buttons_interactable(true)
	_set_status_text(_presenter.build_choice_failure_text(_event_state, String(result.get("error", "unknown"))))


func _is_roadside_overlay_context() -> bool:
	return _event_state != null and String(_event_state.source_context) == "roadside_encounter"


func _apply_portrait_safe_layout() -> void:
	var values: Dictionary = SceneLayoutHelperScript.apply_portrait_layout(self, PORTRAIT_LAYOUT_CONFIG)
	if values.is_empty():
		return
	var viewport_size: Vector2 = values.get("viewport_size", Vector2.ZERO)
	values["vbox_separation"] = 12 if viewport_size.y < 1560.0 else 16
	SceneLayoutHelperScript.apply_control_overrides(self, values, [
		{"path": "Margin/VBox", "theme_constants": {"separation": "vbox_separation"}},
		{"path": OFFERS_CONTENT_PATH, "theme_constants": {"separation": "vbox_separation"}},
		{"path": "%s/HeaderRow" % OFFERS_CONTENT_PATH, "theme_constants": {"separation": 8}},
		{"path": CARDS_ROW_PATH, "theme_constants": {"separation": "vbox_separation"}},
		{"path": "%s/TitleLabel" % HEADER_STACK_PATH, "font_size": "title_font_size"},
		{"path": "%s/SummaryLabel" % HEADER_STACK_PATH, "font_size": "summary_font_size"},
		{"path": "%s/ContextLabel" % HEADER_STACK_PATH, "font_size": "context_font_size"},
		{"path": "%s/HintLabel" % HEADER_STACK_PATH, "font_size": "hint_font_size"},
		{"path": "%s/RunStatusLabel" % RUN_STATUS_CARD_PATH, "font_size": "status_font_size"},
		{"path": RUN_STATUS_CARD_PATH, "custom_minimum_size": {"x": 0.0, "y": 0.0}},
		{"path": STATUS_LABEL_PATH, "font_size": "hint_font_size"},
	])
	for card_name in CARD_NODE_NAMES:
		SceneLayoutHelperScript.apply_control_overrides(self, values, [
			{"path": "%s/%s" % [CARDS_ROW_PATH, card_name], "custom_minimum_size": {"x": 0.0, "y": "card_height"}, "size_flags_horizontal": Control.SIZE_EXPAND_FILL},
			{"path": "%s/%s/VBox" % [CARDS_ROW_PATH, card_name], "size_flags_horizontal": Control.SIZE_EXPAND_FILL, "size_flags_vertical": Control.SIZE_EXPAND_FILL},
			{"path": "%s/%s/VBox/BadgeLabel" % [CARDS_ROW_PATH, card_name], "font_size": "hint_font_size"},
			{"path": "%s/%s/VBox/ChoiceTitleLabel" % [CARDS_ROW_PATH, card_name], "font_size": "card_title_font_size"},
			{"path": "%s/%s/VBox/ChoiceDetailLabel" % [CARDS_ROW_PATH, card_name], "font_size": "card_detail_font_size", "max_lines_visible": 2},
			{"path": "%s/%s/VBox/%s" % [CARDS_ROW_PATH, card_name, _button_name_for_card(card_name)], "font_size": "button_font_size", "custom_minimum_size": {"x": 0.0, "y": "button_height"}, "theme_constants": {"icon_max_width": "button_icon_max_width"}},
		])
	if _choice_tooltip_controller != null:
		_choice_tooltip_controller.refresh_hovered_tooltip()


func _hide_run_status_card() -> void:
	if _run_status_card == null:
		return
	_run_status_card.visible = false
	_run_status_card.custom_minimum_size = Vector2.ZERO


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

func _event_card_name_for_button(button_name: String) -> String:
	match button_name:
		"ChoiceAButton":
			return "ChoiceACard"
		"ChoiceBButton":
			return "ChoiceBCard"
		_:
			return ""


func _button_name_for_card(card_name: String) -> String:
	match card_name:
		"ChoiceACard":
			return "ChoiceAButton"
		"ChoiceBCard":
			return "ChoiceBButton"
		_:
			return ""
