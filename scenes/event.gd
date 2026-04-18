# Layer: Scenes - presentation only
extends Control

const EventPresenterScript = preload("res://Game/UI/event_presenter.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const RunStatusStripScript = preload("res://Game/UI/run_status_strip.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const InventoryOverflowPromptScript = preload("res://Game/UI/inventory_overflow_prompt.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const CARD_NODE_NAMES: PackedStringArray = ["ChoiceACard", "ChoiceBCard"]
const BUTTON_NODE_NAMES: PackedStringArray = ["ChoiceAButton", "ChoiceBButton"]
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
		"large": {"min_width": 760.0, "min_height": 1640.0, "title_font_size": 46, "summary_font_size": 24, "context_font_size": 20, "hint_font_size": 20, "status_font_size": 20, "card_title_font_size": 28, "card_detail_font_size": 20, "button_font_size": 22, "button_height": 78.0, "card_height": 200.0, "button_icon_max_width": 30},
		"medium": {"min_width": 620.0, "min_height": 1460.0, "title_font_size": 40, "summary_font_size": 21, "context_font_size": 18, "hint_font_size": 18, "status_font_size": 18, "card_title_font_size": 24, "card_detail_font_size": 18, "button_font_size": 20, "button_height": 70.0, "card_height": 172.0, "button_icon_max_width": 26},
		"compact": {"title_font_size": 34, "summary_font_size": 18, "context_font_size": 16, "hint_font_size": 16, "status_font_size": 16, "card_title_font_size": 21, "card_detail_font_size": 16, "button_font_size": 18, "button_height": 62.0, "card_height": 150.0, "button_icon_max_width": 22},
	},
}

var _bootstrap
var _event_state: EventState
var _run_state: RunState
var _presenter: EventPresenter
var _choice_in_flight: bool = false
var _overflow_prompt: InventoryOverflowPrompt
var _pending_overflow_choice_id: String = ""


func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_event_state = null
	_run_state = null
	_presenter = EventPresenterScript.new()
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	if _bootstrap != null:
		_event_state = _bootstrap.get_event_state()
		_run_state = _bootstrap.get_run_state()

	_connect_buttons()
	_apply_temp_theme()
	_setup_overflow_prompt()
	SceneLayoutHelperScript.bind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	_apply_portrait_safe_layout()
	_render_event_state()
	SceneAudioPlayersScript.start_looping(self, "EventMusicPlayer")
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")


func _exit_tree() -> void:
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
		var button: Button = get_node_or_null(_button_path(index)) as Button
		if button == null:
			continue
		var handler: Callable = Callable(self, "_on_offer_pressed").bind(index)
		if not button.is_connected("pressed", handler):
			button.connect("pressed", handler)


func _render_event_state() -> void:
	var chip_label: Label = get_node_or_null("%s/ChipCard/ChipLabel" % HEADER_STACK_PATH) as Label
	var title_label: Label = get_node_or_null("%s/TitleLabel" % HEADER_STACK_PATH) as Label
	var context_label: Label = get_node_or_null("%s/ContextLabel" % HEADER_STACK_PATH) as Label
	var summary_label: Label = get_node_or_null("%s/SummaryLabel" % HEADER_STACK_PATH) as Label
	var hint_label: Label = get_node_or_null("%s/HintLabel" % HEADER_STACK_PATH) as Label
	_set_status_text("")
	if chip_label != null:
		chip_label.text = _presenter.build_chip_text(_event_state)
	if title_label != null:
		title_label.text = _presenter.build_title_text(_event_state)
	if context_label != null:
		context_label.text = _presenter.build_context_text(_event_state)
	if summary_label != null:
		summary_label.text = _presenter.build_summary_text(_event_state)
	if hint_label != null:
		hint_label.text = _presenter.build_hint_text()
	_render_run_status_card()

	var card_models: Array[Dictionary] = _presenter.build_choice_view_models(_event_state, CARD_NODE_NAMES.size())
	for index in range(CARD_NODE_NAMES.size()):
		var card: Control = get_node_or_null(_card_path(index)) as Control
		var badge_label: Label = get_node_or_null(_card_label_path(index, "BadgeLabel")) as Label
		var choice_title_label: Label = get_node_or_null(_card_label_path(index, "ChoiceTitleLabel")) as Label
		var choice_detail_label: Label = get_node_or_null(_card_label_path(index, "ChoiceDetailLabel")) as Label
		var button: Button = get_node_or_null(_button_path(index)) as Button
		var model: Dictionary = card_models[index]
		if card != null:
			card.visible = bool(model.get("visible", false))
		if badge_label != null:
			badge_label.text = String(model.get("badge_text", ""))
		if choice_title_label != null:
			choice_title_label.text = String(model.get("title_text", ""))
		if choice_detail_label != null:
			choice_detail_label.text = String(model.get("detail_text", ""))
		if button != null:
			button.text = String(model.get("button_text", ""))
			button.disabled = bool(model.get("button_disabled", true))
			button.icon = SceneLayoutHelperScript.load_texture_or_null(_presenter.build_choice_icon_texture_path(_event_state))


func _set_offer_buttons_interactable(is_interactable: bool) -> void:
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = get_node_or_null(_button_path(index)) as Button
		if button == null or not button.visible:
			continue
		button.disabled = not is_interactable


func _set_status_text(text: String) -> void:
	var status_label: Label = get_node_or_null(STATUS_LABEL_PATH) as Label
	if status_label != null:
		status_label.text = text
		status_label.visible = not text.is_empty()


func _card_path(index: int) -> String:
	return "%s/%s" % [CARDS_ROW_PATH, CARD_NODE_NAMES[index]]


func _card_label_path(index: int, label_name: String) -> String:
	return "%s/VBox/%s" % [_card_path(index), label_name]


func _button_path(index: int) -> String:
	return "%s/VBox/%s" % [_card_path(index), BUTTON_NODE_NAMES[index]]


func _apply_temp_theme() -> void:
	var margin: MarginContainer = get_node_or_null("Margin") as MarginContainer
	var is_overlay: bool = self.top_level
	var roadside_overlay: bool = is_overlay and _is_roadside_overlay_context()
	if is_overlay:
		for node_name in ["BackgroundFar", "BackgroundMid", "BackgroundOverlay"]:
			var backdrop: CanvasItem = get_node_or_null(node_name) as CanvasItem
			if backdrop != null:
				backdrop.visible = false
		var scrim: ColorRect = get_node_or_null("Scrim") as ColorRect
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
			get_node_or_null("Margin/VBox") as Control,
			TempScreenThemeScript.TEAL_ACCENT_COLOR,
			"ContentShell",
			40,
			110,
			40,
			110
		)
	TempScreenThemeScript.apply_panel(
		get_node_or_null(OFFERS_SHELL_PATH) as PanelContainer,
		TempScreenThemeScript.PANEL_BORDER_COLOR,
		28,
		0.6
	)
	TempScreenThemeScript.intensify_panel(
		get_node_or_null(OFFERS_SHELL_PATH) as PanelContainer,
		TempScreenThemeScript.PANEL_BORDER_COLOR,
		3,
		28,
		0.01,
		0.18,
		20,
		18
	)
	TempScreenThemeScript.apply_panel(
		get_node_or_null(HEADER_CARD_PATH) as PanelContainer,
		TempScreenThemeScript.TEAL_ACCENT_COLOR,
		20,
		0.74
	)
	TempScreenThemeScript.intensify_panel(
		get_node_or_null(HEADER_CARD_PATH) as PanelContainer,
		TempScreenThemeScript.TEAL_ACCENT_COLOR,
		3,
		18,
		0.02,
		0.18,
		18,
		14
	)
	TempScreenThemeScript.apply_chip(
		get_node_or_null("%s/ChipCard" % HEADER_STACK_PATH) as PanelContainer,
		get_node_or_null("%s/ChipCard/ChipLabel" % HEADER_STACK_PATH) as Label,
		TempScreenThemeScript.TEAL_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_compact_status_area(
		get_node_or_null(RUN_STATUS_CARD_PATH) as PanelContainer,
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
		var choice_card: PanelContainer = get_node_or_null("%s/%s" % [CARDS_ROW_PATH, card_name]) as PanelContainer
		TempScreenThemeScript.apply_choice_card_shell(choice_card, TempScreenThemeScript.TEAL_ACCENT_COLOR)
		TempScreenThemeScript.apply_label(get_node_or_null("%s/%s/VBox/BadgeLabel" % [CARDS_ROW_PATH, card_name]) as Label, "accent")
		TempScreenThemeScript.apply_label(get_node_or_null("%s/%s/VBox/ChoiceTitleLabel" % [CARDS_ROW_PATH, card_name]) as Label, "title")
		TempScreenThemeScript.apply_label(get_node_or_null("%s/%s/VBox/ChoiceDetailLabel" % [CARDS_ROW_PATH, card_name]) as Label)
		SceneLayoutHelperScript.apply_control_overrides(self, {}, [
			{"paths": [
				"%s/%s/VBox/BadgeLabel" % [CARDS_ROW_PATH, card_name],
				"%s/%s/VBox/ChoiceTitleLabel" % [CARDS_ROW_PATH, card_name],
				"%s/%s/VBox/ChoiceDetailLabel" % [CARDS_ROW_PATH, card_name],
			], "horizontal_alignment": HORIZONTAL_ALIGNMENT_LEFT},
		])

	for button_name in BUTTON_NODE_NAMES:
		var choice_button: Button = get_node_or_null("%s/%s/VBox/%s" % [CARDS_ROW_PATH, _event_card_name_for_button(button_name), button_name]) as Button
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
			{"path": "%s/%s" % [CARDS_ROW_PATH, card_name], "custom_minimum_size": {"x": 0.0, "y": "card_height"}},
			{"path": "%s/%s/VBox/BadgeLabel" % [CARDS_ROW_PATH, card_name], "font_size": "hint_font_size"},
			{"path": "%s/%s/VBox/ChoiceTitleLabel" % [CARDS_ROW_PATH, card_name], "font_size": "card_title_font_size"},
			{"path": "%s/%s/VBox/ChoiceDetailLabel" % [CARDS_ROW_PATH, card_name], "font_size": "card_detail_font_size"},
			{"path": "%s/%s/VBox/%s" % [CARDS_ROW_PATH, card_name, _button_name_for_card(card_name)], "font_size": "button_font_size", "custom_minimum_size": {"x": 0.0, "y": "button_height"}, "theme_constants": {"icon_max_width": "button_icon_max_width"}},
		])
	_render_run_status_card()


func _render_run_status_card() -> void:
	RunStatusStripScript.render_into(
		get_node_or_null(RUN_STATUS_CARD_PATH) as PanelContainer,
		get_node_or_null("%s/RunStatusLabel" % RUN_STATUS_CARD_PATH) as Label,
		_presenter.build_run_status_model(_run_state),
		TempScreenThemeScript.PANEL_BORDER_COLOR
	)

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
