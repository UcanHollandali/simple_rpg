# Layer: Scenes - presentation only
extends Control

const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")
const RewardPresenterScript = preload("res://Game/UI/reward_presenter.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const CARD_NODE_NAMES: PackedStringArray = ["ChoiceACard", "ChoiceBCard", "ChoiceCCard"]
const BUTTON_NODE_NAMES: PackedStringArray = ["ChoiceAButton", "ChoiceBButton", "ChoiceCButton"]
const REWARD_PICKUP_SFX_PATH := "res://Assets/Audio/SFX/sfx_reward_pickup_01.ogg"
const UI_CONFIRM_SFX_PATH := "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"
const PANEL_OPEN_SFX_PATH := "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"
# Keep post-combat reward resolution on the map bed so the flow does not hard-cut
# into a separate temp cue every time the player exits combat.
const REWARD_MUSIC_LOOP_PATH := "res://Assets/Audio/Music/music_ui_hub_loop_temp_01.ogg"
const ONE_SHOT_SFX_TRANSITION_LEAD_IN_SECONDS := 0.08
const PORTRAIT_SAFE_MAX_WIDTH := 940
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 30
const AUDIO_PLAYER_NODE_NAMES: Array[String] = [
	"RewardClaimSfxPlayer",
	"UiConfirmSfxPlayer",
	"PanelOpenSfxPlayer",
	"RewardMusicPlayer",
]

var _bootstrap
var _reward_state: RewardState
var _run_state: RunState
var _presenter: RefCounted
var _reward_claim_in_flight: bool = false
var _safe_menu: SafeMenuOverlay


func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_reward_state = null
	_run_state = null
	_presenter = RewardPresenterScript.new()
	_configure_audio_players()
	if _bootstrap != null:
		_reward_state = _bootstrap.get_reward_state()
		_run_state = _bootstrap.get_run_state()

	_connect_buttons()
	_apply_temp_theme()
	_setup_safe_menu()
	_connect_viewport_layout_updates()
	_apply_portrait_safe_layout()
	_render_reward_state()
	SceneAudioPlayersScript.start_looping(self, "RewardMusicPlayer")
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")


func _exit_tree() -> void:
	_disconnect_viewport_layout_updates()
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


func _on_offer_pressed(index: int) -> void:
	if _reward_claim_in_flight:
		return
	if _bootstrap == null or _reward_state == null:
		return
	if index < 0 or index >= _reward_state.offers.size():
		return

	var offer: Dictionary = _reward_state.offers[index]
	var offer_id: String = String(offer.get("offer_id", ""))
	if offer_id.is_empty():
		return

	_reward_claim_in_flight = true
	_set_offer_buttons_interactable(false)
	SceneAudioPlayersScript.play(self, "RewardClaimSfxPlayer")
	await SceneAudioPlayersScript.wait_for_lead_in(self, "RewardClaimSfxPlayer", ONE_SHOT_SFX_TRANSITION_LEAD_IN_SECONDS)
	var result: Dictionary = _bootstrap.choose_reward_option(offer_id)
	if not bool(result.get("ok", false)):
		_reward_claim_in_flight = false
		_set_status_text("Reward failed: %s" % String(result.get("error", "unknown")))
		_render_reward_state()


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


func _connect_buttons() -> void:
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = get_node_or_null(_button_path(index)) as Button
		if button == null:
			continue
		var handler: Callable = Callable(self, "_on_offer_pressed").bind(index)
		if not button.is_connected("pressed", handler):
			button.connect("pressed", handler)


func _render_reward_state() -> void:
	var chip_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/ChipCard/ChipLabel") as Label
	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	var context_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/ContextLabel") as Label
	var hint_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/HintLabel") as Label
	var run_status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/RunStatusLabel") as Label
	_set_status_text("")
	if chip_label != null:
		chip_label.text = _presenter.build_chip_text(_reward_state)
	if title_label != null:
		title_label.text = _presenter.build_title_text(_reward_state)
	if context_label != null:
		context_label.text = _presenter.build_context_text(_reward_state)
	if hint_label != null:
		hint_label.text = _presenter.build_hint_text(_reward_state)
	if run_status_label != null:
		run_status_label.text = _presenter.build_run_status_text(_run_state)

	var card_models: Array[Dictionary] = _presenter.build_offer_view_models(_reward_state, CARD_NODE_NAMES.size())
	for index in range(CARD_NODE_NAMES.size()):
		var card: Control = get_node_or_null(_card_path(index)) as Control
		var badge_label: Label = get_node_or_null(_card_label_path(index, "BadgeLabel")) as Label
		var offer_title_label: Label = get_node_or_null(_card_label_path(index, "OfferTitleLabel")) as Label
		var offer_detail_label: Label = get_node_or_null(_card_label_path(index, "OfferDetailLabel")) as Label
		var button: Button = get_node_or_null(_button_path(index)) as Button
		var model: Dictionary = card_models[index]
		if card != null:
			card.visible = bool(model.get("visible", false))
		if badge_label != null:
			badge_label.text = String(model.get("badge_text", ""))
		if offer_title_label != null:
			offer_title_label.text = String(model.get("title_text", ""))
		if offer_detail_label != null:
			offer_detail_label.text = String(model.get("detail_text", ""))
		if button != null:
			button.text = String(model.get("button_text", ""))
			button.disabled = bool(model.get("button_disabled", true))

	_refresh_save_controls()


func _configure_audio_players() -> void:
	SceneAudioPlayersScript.assign_stream_from_path(self, "RewardClaimSfxPlayer", REWARD_PICKUP_SFX_PATH)
	SceneAudioPlayersScript.assign_stream_from_path(self, "UiConfirmSfxPlayer", UI_CONFIRM_SFX_PATH)
	SceneAudioPlayersScript.assign_stream_from_path(self, "PanelOpenSfxPlayer", PANEL_OPEN_SFX_PATH)
	SceneAudioPlayersScript.assign_music_stream_from_path(self, "RewardMusicPlayer", REWARD_MUSIC_LOOP_PATH, true)


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


func _refresh_save_controls() -> void:
	RunMenuSceneHelperScript.sync_load_available(_safe_menu, _bootstrap)


func _card_path(index: int) -> String:
	return "Margin/VBox/CardsRow/%s" % CARD_NODE_NAMES[index]


func _card_label_path(index: int, label_name: String) -> String:
	return "%s/VBox/%s" % [_card_path(index), label_name]


func _button_path(index: int) -> String:
	return "%s/VBox/%s" % [_card_path(index), BUTTON_NODE_NAMES[index]]


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
			96,
			34,
			96
		)
	TempScreenThemeScript.apply_chip(
		get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/ChipCard") as PanelContainer,
		get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/ChipCard/ChipLabel") as Label,
		TempScreenThemeScript.REWARD_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/ContextLabel") as Label, "reward")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/HintLabel") as Label, "muted")
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 16, 0.88)
	TempScreenThemeScript.intensify_panel(get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard") as PanelContainer, TempScreenThemeScript.PANEL_BORDER_COLOR, 3, 18, 0.03, 0.18, 16, 12)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/RunStatusLabel") as Label, "muted")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/StatusLabel") as Label)

	for card_name in CARD_NODE_NAMES:
		var choice_card: PanelContainer = get_node_or_null("Margin/VBox/CardsRow/%s" % card_name) as PanelContainer
		TempScreenThemeScript.apply_panel(choice_card, TempScreenThemeScript.REWARD_ACCENT_COLOR, 18, 0.9)
		TempScreenThemeScript.intensify_panel(choice_card, TempScreenThemeScript.REWARD_ACCENT_COLOR, 3, 20, 0.04, 0.24, 18, 16)
		TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/CardsRow/%s/VBox/BadgeLabel" % card_name) as Label, "reward")
		TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/CardsRow/%s/VBox/OfferTitleLabel" % card_name) as Label, "title")
		TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/CardsRow/%s/VBox/OfferDetailLabel" % card_name) as Label)

	for button_name in BUTTON_NODE_NAMES:
		TempScreenThemeScript.apply_button(
			get_node_or_null("Margin/VBox/CardsRow/%s/VBox/%s" % [_reward_card_name_for_button(button_name), button_name]) as Button,
			TempScreenThemeScript.REWARD_ACCENT_COLOR
		)

	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 34)

	var context_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/ContextLabel") as Label
	if context_label != null:
		context_label.add_theme_font_size_override("font_size", 16)
	var hint_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/HintLabel") as Label
	if hint_label != null:
		hint_label.add_theme_font_size_override("font_size", 15)

	var run_status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/RunStatusLabel") as Label
	if run_status_label != null:
		run_status_label.add_theme_font_size_override("font_size", 14)

	var status_label: Label = get_node_or_null("Margin/VBox/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 14)
		status_label.modulate = Color(1, 1, 1, 0.74)

	for card_name in CARD_NODE_NAMES:
		var choice_card: PanelContainer = get_node_or_null("Margin/VBox/CardsRow/%s" % card_name) as PanelContainer
		if choice_card != null:
			choice_card.custom_minimum_size = Vector2(0, 124)
		var title_text_label: Label = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/OfferTitleLabel" % card_name) as Label
		if title_text_label != null:
			title_text_label.add_theme_font_size_override("font_size", 23)
		var detail_text_label: Label = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/OfferDetailLabel" % card_name) as Label
		if detail_text_label != null:
			detail_text_label.add_theme_font_size_override("font_size", 15)
		var claim_button: Button = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/%s" % [card_name, card_name.replace("Card", "Button")]) as Button
		if claim_button != null:
			claim_button.add_theme_font_size_override("font_size", 18)

	var vbox: VBoxContainer = get_node_or_null("Margin/VBox") as VBoxContainer
	if vbox != null:
		vbox.add_theme_constant_override("separation", 14)
	var cards_row: VBoxContainer = get_node_or_null("Margin/VBox/CardsRow") as VBoxContainer
	if cards_row != null:
		cards_row.add_theme_constant_override("separation", 10)


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
	var cards_row: VBoxContainer = get_node_or_null("Margin/VBox/CardsRow") as VBoxContainer
	if margin == null or vbox == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var top_margin: int = 116
	var bottom_margin: int = 112
	if viewport_size.y < 1760.0:
		top_margin = 88
		bottom_margin = 88
	if viewport_size.y < 1540.0:
		top_margin = 64
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
	if cards_row != null:
		cards_row.add_theme_constant_override("separation", 12 if viewport_size.y < 1560.0 else 16)

	var large_layout: bool = safe_width >= 780 and viewport_size.y >= 1640.0
	var medium_layout: bool = not large_layout and safe_width >= 640 and viewport_size.y >= 1460.0
	var title_font_size: int = 46 if large_layout else 40 if medium_layout else 34
	var context_font_size: int = 22 if large_layout else 20 if medium_layout else 17
	var status_font_size: int = 19 if large_layout else 17 if medium_layout else 15
	var card_title_font_size: int = 28 if large_layout else 24 if medium_layout else 21
	var card_detail_font_size: int = 20 if large_layout else 18 if medium_layout else 16
	var button_font_size: int = 22 if large_layout else 20 if medium_layout else 18
	var button_height: float = 78.0 if large_layout else 70.0 if medium_layout else 62.0
	var card_height: float = 204.0 if large_layout else 176.0 if medium_layout else 150.0
	var run_status_width: float = 300.0 if large_layout else 256.0 if medium_layout else 220.0

	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", title_font_size)
	var context_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/ContextLabel") as Label
	if context_label != null:
		context_label.add_theme_font_size_override("font_size", context_font_size)
	var hint_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/HintLabel") as Label
	if hint_label != null:
		hint_label.add_theme_font_size_override("font_size", max(14, context_font_size - 2))
	var run_status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/RunStatusLabel") as Label
	if run_status_label != null:
		run_status_label.add_theme_font_size_override("font_size", status_font_size)
	var status_label: Label = get_node_or_null("Margin/VBox/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", status_font_size)
	var run_status_card: PanelContainer = get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard") as PanelContainer
	if run_status_card != null:
		run_status_card.custom_minimum_size = Vector2(run_status_width, 0.0)

	for card_name in CARD_NODE_NAMES:
		var choice_card: PanelContainer = get_node_or_null("Margin/VBox/CardsRow/%s" % card_name) as PanelContainer
		if choice_card != null:
			choice_card.custom_minimum_size = Vector2(0.0, card_height)
		var badge_label: Label = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/BadgeLabel" % card_name) as Label
		if badge_label != null:
			badge_label.add_theme_font_size_override("font_size", status_font_size)
		var title_text_label: Label = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/OfferTitleLabel" % card_name) as Label
		if title_text_label != null:
			title_text_label.add_theme_font_size_override("font_size", card_title_font_size)
		var detail_text_label: Label = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/OfferDetailLabel" % card_name) as Label
		if detail_text_label != null:
			detail_text_label.add_theme_font_size_override("font_size", card_detail_font_size)
		var claim_button: Button = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/%s" % [card_name, _reward_button_name_for_card(card_name)]) as Button
		if claim_button != null:
			claim_button.custom_minimum_size = Vector2(0.0, button_height)
			claim_button.add_theme_font_size_override("font_size", button_font_size)
			claim_button.add_theme_constant_override("icon_max_width", 30 if large_layout else 26 if medium_layout else 22)


func _reward_card_name_for_button(button_name: String) -> String:
	match button_name:
		"ChoiceAButton":
			return "ChoiceACard"
		"ChoiceBButton":
			return "ChoiceBCard"
		"ChoiceCButton":
			return "ChoiceCCard"
		_:
			return ""


func _reward_button_name_for_card(card_name: String) -> String:
	match card_name:
		"ChoiceACard":
			return "ChoiceAButton"
		"ChoiceBCard":
			return "ChoiceBButton"
		"ChoiceCCard":
			return "ChoiceCButton"
		_:
			return ""
