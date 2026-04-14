# Layer: Scenes - presentation only
extends Control

const EventPresenterScript = preload("res://Game/UI/event_presenter.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const UI_CONFIRM_SFX_PATH := "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"
const PANEL_OPEN_SFX_PATH := "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"
const EVENT_MUSIC_LOOP_PATH := "res://Assets/Audio/Music/music_ui_hub_loop_temp_01.ogg"
const CARD_NODE_NAMES: PackedStringArray = ["ChoiceACard", "ChoiceBCard"]
const BUTTON_NODE_NAMES: PackedStringArray = ["ChoiceAButton", "ChoiceBButton"]
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const PORTRAIT_SAFE_MAX_WIDTH := 920
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 30
const AUDIO_PLAYER_NODE_NAMES: Array[String] = [
	"UiConfirmSfxPlayer",
	"PanelOpenSfxPlayer",
	"EventMusicPlayer",
]

var _bootstrap
var _event_state: EventState
var _run_state: RunState
var _presenter: EventPresenter
var _choice_in_flight: bool = false


func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_event_state = null
	_run_state = null
	_presenter = EventPresenterScript.new()
	_configure_audio_players()
	if _bootstrap != null:
		_event_state = _bootstrap.get_event_state()
		_run_state = _bootstrap.get_run_state()

	_connect_buttons()
	_apply_temp_theme()
	_connect_viewport_layout_updates()
	_apply_portrait_safe_layout()
	_render_event_state()
	SceneAudioPlayersScript.start_looping(self, "EventMusicPlayer")
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")


func _exit_tree() -> void:
	_disconnect_viewport_layout_updates()
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


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

	_choice_in_flight = false
	_set_offer_buttons_interactable(true)
	_set_status_text("Roadside encounter failed: %s" % String(result.get("error", "unknown")))


func _connect_buttons() -> void:
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = get_node_or_null(_button_path(index)) as Button
		if button == null:
			continue
		var handler: Callable = Callable(self, "_on_offer_pressed").bind(index)
		if not button.is_connected("pressed", handler):
			button.connect("pressed", handler)


func _render_event_state() -> void:
	var chip_label: Label = get_node_or_null("Margin/VBox/HeaderStack/ChipCard/ChipLabel") as Label
	var title_label: Label = get_node_or_null("Margin/VBox/HeaderStack/TitleLabel") as Label
	var summary_label: Label = get_node_or_null("Margin/VBox/HeaderStack/SummaryLabel") as Label
	var hint_label: Label = get_node_or_null("Margin/VBox/HeaderStack/HintLabel") as Label
	var run_status_label: Label = get_node_or_null("Margin/VBox/RunStatusCard/RunStatusLabel") as Label
	_set_status_text("")
	if chip_label != null:
		chip_label.text = _presenter.build_chip_text()
	if title_label != null:
		title_label.text = _presenter.build_title_text(_event_state)
	if summary_label != null:
		summary_label.text = _presenter.build_summary_text(_event_state)
	if hint_label != null:
		hint_label.text = _presenter.build_hint_text()
	if run_status_label != null:
		run_status_label.text = _presenter.build_run_status_text(_run_state)

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


func _configure_audio_players() -> void:
	SceneAudioPlayersScript.assign_stream_from_path(self, "UiConfirmSfxPlayer", UI_CONFIRM_SFX_PATH)
	SceneAudioPlayersScript.assign_stream_from_path(self, "PanelOpenSfxPlayer", PANEL_OPEN_SFX_PATH)
	SceneAudioPlayersScript.assign_music_stream_from_path(self, "EventMusicPlayer", EVENT_MUSIC_LOOP_PATH, true)


func _set_offer_buttons_interactable(is_interactable: bool) -> void:
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = get_node_or_null(_button_path(index)) as Button
		if button == null or not button.visible:
			continue
		button.disabled = not is_interactable


func _set_status_text(text: String) -> void:
	var status_label: Label = get_node_or_null("Margin/VBox/StatusLabel") as Label
	if status_label != null:
		status_label.text = text
		status_label.visible = not text.is_empty()


func _card_path(index: int) -> String:
	return "Margin/VBox/CardsRow/%s" % CARD_NODE_NAMES[index]


func _card_label_path(index: int, label_name: String) -> String:
	return "%s/VBox/%s" % [_card_path(index), label_name]


func _button_path(index: int) -> String:
	return "%s/VBox/%s" % [_card_path(index), BUTTON_NODE_NAMES[index]]


func _apply_temp_theme() -> void:
	# Apply the popup shell even in overlay mode so the event content sits in a stable panel.
	TempScreenThemeScript.apply_modal_popup_shell(
		self,
		get_node_or_null("Margin") as MarginContainer,
		get_node_or_null("Margin/VBox") as Control,
		TempScreenThemeScript.TEAL_ACCENT_COLOR,
		"ContentShell",
		40,
		110,
		40,
		110
	)
	TempScreenThemeScript.apply_chip(
		get_node_or_null("Margin/VBox/HeaderStack/ChipCard") as PanelContainer,
		get_node_or_null("Margin/VBox/HeaderStack/ChipCard/ChipLabel") as Label,
		TempScreenThemeScript.TEAL_ACCENT_COLOR
	)
	var header_stack: VBoxContainer = get_node_or_null("Margin/VBox/HeaderStack") as VBoxContainer
	if header_stack != null:
		header_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var chip_label: Label = get_node_or_null("Margin/VBox/HeaderStack/ChipCard/ChipLabel") as Label
	if chip_label != null:
		chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		chip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var title_label: Label = get_node_or_null("Margin/VBox/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		TempScreenThemeScript.apply_label(title_label, "title")
	var summary_label: Label = get_node_or_null("Margin/VBox/HeaderStack/SummaryLabel") as Label
	if summary_label != null:
		summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		TempScreenThemeScript.apply_label(summary_label, "muted")
	var hint_label: Label = get_node_or_null("Margin/VBox/HeaderStack/HintLabel") as Label
	if hint_label != null:
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		TempScreenThemeScript.apply_label(hint_label, "muted")
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/RunStatusCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 16, 0.86)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/RunStatusCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 3, 16, 0.03, 0.18, 16, 12)
	var run_status_label: Label = get_node_or_null("Margin/VBox/RunStatusCard/RunStatusLabel") as Label
	if run_status_label != null:
		run_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		run_status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		TempScreenThemeScript.apply_label(run_status_label, "muted")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/StatusLabel") as Label)

	for card_name in CARD_NODE_NAMES:
		var choice_card: PanelContainer = get_node_or_null("Margin/VBox/CardsRow/%s" % card_name) as PanelContainer
		TempScreenThemeScript.apply_panel(choice_card, TempScreenThemeScript.TEAL_ACCENT_COLOR, 18, 0.9)
		TempScreenThemeScript.intensify_panel(choice_card, TempScreenThemeScript.TEAL_ACCENT_COLOR, 3, 20, 0.04, 0.24, 18, 16)
		var badge_label: Label = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/BadgeLabel" % card_name) as Label
		if badge_label != null:
			badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		TempScreenThemeScript.apply_label(badge_label, "accent")
		var choice_title_label: Label = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/ChoiceTitleLabel" % card_name) as Label
		if choice_title_label != null:
			choice_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		TempScreenThemeScript.apply_label(choice_title_label, "title")
		var choice_detail_label: Label = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/ChoiceDetailLabel" % card_name) as Label
		if choice_detail_label != null:
			choice_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		TempScreenThemeScript.apply_label(choice_detail_label)

	for button_name in BUTTON_NODE_NAMES:
		var choice_button: Button = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/%s" % [_event_card_name_for_button(button_name), button_name]) as Button
		TempScreenThemeScript.apply_button(choice_button, TempScreenThemeScript.TEAL_ACCENT_COLOR)
		if choice_button != null:
			choice_button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	var vbox: VBoxContainer = get_node_or_null("Margin/VBox") as VBoxContainer
	if vbox != null:
		vbox.add_theme_constant_override("separation", 12)


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
	var header_stack: VBoxContainer = get_node_or_null("Margin/VBox/HeaderStack") as VBoxContainer
	var cards_row: VBoxContainer = get_node_or_null("Margin/VBox/CardsRow") as VBoxContainer
	if margin == null or vbox == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var top_margin: int = 124
	var bottom_margin: int = 124
	if viewport_size.y < 1760.0:
		top_margin = 96
		bottom_margin = 96
	if viewport_size.y < 1540.0:
		top_margin = 72
		bottom_margin = 72

	var safe_width: int = TempScreenThemeScript.apply_portrait_safe_margins(
		margin,
		PORTRAIT_SAFE_MAX_WIDTH,
		PORTRAIT_SAFE_MIN_SIDE_MARGIN,
		top_margin,
		bottom_margin
	)
	vbox.add_theme_constant_override("separation", 12 if viewport_size.y < 1560.0 else 16)
	if header_stack != null:
		header_stack.add_theme_constant_override("separation", 6)
	if cards_row != null:
		cards_row.add_theme_constant_override("separation", 12 if viewport_size.y < 1560.0 else 16)

	var large_layout: bool = safe_width >= 760 and viewport_size.y >= 1640.0
	var medium_layout: bool = not large_layout and safe_width >= 620 and viewport_size.y >= 1460.0
	var title_font_size: int = 46 if large_layout else 40 if medium_layout else 34
	var summary_font_size: int = 24 if large_layout else 21 if medium_layout else 18
	var hint_font_size: int = 20 if large_layout else 18 if medium_layout else 16
	var status_font_size: int = 20 if large_layout else 18 if medium_layout else 16
	var card_title_font_size: int = 28 if large_layout else 24 if medium_layout else 21
	var card_detail_font_size: int = 20 if large_layout else 18 if medium_layout else 16
	var button_font_size: int = 22 if large_layout else 20 if medium_layout else 18
	var button_height: float = 78.0 if large_layout else 70.0 if medium_layout else 62.0
	var card_height: float = 200.0 if large_layout else 172.0 if medium_layout else 150.0

	var title_label: Label = get_node_or_null("Margin/VBox/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", title_font_size)
	var summary_label: Label = get_node_or_null("Margin/VBox/HeaderStack/SummaryLabel") as Label
	if summary_label != null:
		summary_label.add_theme_font_size_override("font_size", summary_font_size)
	var hint_label: Label = get_node_or_null("Margin/VBox/HeaderStack/HintLabel") as Label
	if hint_label != null:
		hint_label.add_theme_font_size_override("font_size", hint_font_size)
	var run_status_label: Label = get_node_or_null("Margin/VBox/RunStatusCard/RunStatusLabel") as Label
	if run_status_label != null:
		run_status_label.add_theme_font_size_override("font_size", status_font_size)
	var run_status_card: PanelContainer = get_node_or_null("Margin/VBox/RunStatusCard") as PanelContainer
	if run_status_card != null:
		run_status_card.custom_minimum_size = Vector2(0.0, 0.0)
	var status_label: Label = get_node_or_null("Margin/VBox/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", hint_font_size)

	for card_name in CARD_NODE_NAMES:
		var card: PanelContainer = get_node_or_null("Margin/VBox/CardsRow/%s" % card_name) as PanelContainer
		if card != null:
			card.custom_minimum_size = Vector2(0.0, card_height)
		var badge_label: Label = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/BadgeLabel" % card_name) as Label
		if badge_label != null:
			badge_label.add_theme_font_size_override("font_size", hint_font_size)
		var choice_title_label: Label = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/ChoiceTitleLabel" % card_name) as Label
		if choice_title_label != null:
			choice_title_label.add_theme_font_size_override("font_size", card_title_font_size)
		var choice_detail_label: Label = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/ChoiceDetailLabel" % card_name) as Label
		if choice_detail_label != null:
			choice_detail_label.add_theme_font_size_override("font_size", card_detail_font_size)
		var button: Button = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/%s" % [card_name, _button_name_for_card(card_name)]) as Button
		if button != null:
			button.custom_minimum_size = Vector2(0.0, button_height)
			button.add_theme_font_size_override("font_size", button_font_size)
			button.add_theme_constant_override("icon_max_width", 30 if large_layout else 26 if medium_layout else 22)


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
