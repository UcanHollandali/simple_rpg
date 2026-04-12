# Layer: Scenes - presentation only
extends Control

const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")
const RewardPresenterScript = preload("res://Game/UI/reward_presenter.gd")
const SafeMenuOverlayScript = preload("res://Game/UI/safe_menu_overlay.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const CARD_NODE_NAMES: PackedStringArray = ["ChoiceACard", "ChoiceBCard", "ChoiceCCard"]
const BUTTON_NODE_NAMES: PackedStringArray = ["ChoiceAButton", "ChoiceBButton", "ChoiceCButton"]
const REWARD_PICKUP_SFX = preload("res://Assets/Audio/SFX/sfx_reward_pickup_01.ogg")
const UI_CONFIRM_SFX = preload("res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg")
const PANEL_OPEN_SFX = preload("res://Assets/Audio/SFX/sfx_panel_open_01.ogg")
const REWARD_MUSIC_LOOP = preload("res://Assets/Audio/Music/music_reward_loop_temp_01.ogg")
const ONE_SHOT_SFX_TRANSITION_LEAD_IN_SECONDS := 0.08
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
	_render_reward_state()
	_start_looping_audio_player("RewardMusicPlayer")
	_play_audio_player("PanelOpenSfxPlayer")


func _exit_tree() -> void:
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
	_play_audio_player("RewardClaimSfxPlayer")
	await _wait_for_one_shot_sfx_lead_in("RewardClaimSfxPlayer")
	var result: Dictionary = _bootstrap.choose_reward_option(offer_id)
	if not bool(result.get("ok", false)):
		_reward_claim_in_flight = false
		_set_status_text("Reward failed: %s" % String(result.get("error", "unknown")))
		_render_reward_state()


func _on_save_pressed() -> void:
	if _bootstrap == null:
		return
	_play_audio_player("UiConfirmSfxPlayer")
	var save_result: Dictionary = _bootstrap.save_game()
	if _safe_menu != null:
		_safe_menu.set_status_text("Run saved." if bool(save_result.get("ok", false)) else "Save failed: %s" % String(save_result.get("error", "unknown")))
	_refresh_save_controls()


func _on_load_pressed() -> void:
	if _bootstrap == null:
		return
	_play_audio_player("UiConfirmSfxPlayer")
	var load_result: Dictionary = _bootstrap.load_game()
	if bool(load_result.get("ok", false)):
		return
	if _safe_menu != null:
		_safe_menu.set_status_text("Load failed: %s" % String(load_result.get("error", "unknown")))
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
	var title_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label
	var context_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/ContextLabel") as Label
	var run_status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/RunStatusLabel") as Label
	_set_status_text("")
	if title_label != null:
		title_label.text = _presenter.build_title_text(_reward_state)
	if context_label != null:
		context_label.text = _presenter.build_context_text(_reward_state)
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
	var reward_claim_player: AudioStreamPlayer = get_node_or_null("RewardClaimSfxPlayer") as AudioStreamPlayer
	if reward_claim_player != null:
		reward_claim_player.stream = REWARD_PICKUP_SFX

	var ui_confirm_player: AudioStreamPlayer = get_node_or_null("UiConfirmSfxPlayer") as AudioStreamPlayer
	if ui_confirm_player != null:
		ui_confirm_player.stream = UI_CONFIRM_SFX

	var panel_open_player: AudioStreamPlayer = get_node_or_null("PanelOpenSfxPlayer") as AudioStreamPlayer
	if panel_open_player != null:
		panel_open_player.stream = PANEL_OPEN_SFX

	var music_player: AudioStreamPlayer = get_node_or_null("RewardMusicPlayer") as AudioStreamPlayer
	if music_player != null:
		music_player.stream = REWARD_MUSIC_LOOP
		var music_stream: AudioStreamOggVorbis = music_player.stream as AudioStreamOggVorbis
		if music_stream != null:
			music_stream.loop = true


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
	if _safe_menu == null:
		return
	_safe_menu.set_load_available(_bootstrap != null and _bootstrap.has_save_game())


func _card_path(index: int) -> String:
	return "Margin/VBox/CardsRow/%s" % CARD_NODE_NAMES[index]


func _card_label_path(index: int, label_name: String) -> String:
	return "%s/VBox/%s" % [_card_path(index), label_name]


func _button_path(index: int) -> String:
	return "%s/VBox/%s" % [_card_path(index), BUTTON_NODE_NAMES[index]]


func _play_audio_player(node_path: String) -> void:
	var player: AudioStreamPlayer = get_node_or_null(node_path) as AudioStreamPlayer
	if player != null and player.stream != null:
		player.play()


func _wait_for_one_shot_sfx_lead_in(node_path: String) -> void:
	var player: AudioStreamPlayer = get_node_or_null(node_path) as AudioStreamPlayer
	if player == null or player.stream == null:
		return
	await get_tree().create_timer(ONE_SHOT_SFX_TRANSITION_LEAD_IN_SECONDS).timeout


func _start_looping_audio_player(node_path: String) -> void:
	var player: AudioStreamPlayer = get_node_or_null(node_path) as AudioStreamPlayer
	if player != null and player.stream != null and not player.playing:
		player.play()


func _apply_temp_theme() -> void:
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/ContextLabel") as Label, "reward")
	TempScreenThemeScript.apply_panel(get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 18, 0.9)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/RunStatusLabel") as Label, "accent")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/VBox/StatusLabel") as Label)

	for card_name in CARD_NODE_NAMES:
		TempScreenThemeScript.apply_panel(
			get_node_or_null("Margin/VBox/CardsRow/%s" % card_name) as PanelContainer,
			TempScreenThemeScript.REWARD_ACCENT_COLOR,
			18,
			0.9
		)
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
		title_label.add_theme_font_size_override("font_size", 28)

	var context_label: Label = get_node_or_null("Margin/VBox/HeaderRow/HeaderStack/ContextLabel") as Label
	if context_label != null:
		context_label.add_theme_font_size_override("font_size", 16)

	var run_status_label: Label = get_node_or_null("Margin/VBox/HeaderRow/RunStatusCard/RunStatusLabel") as Label
	if run_status_label != null:
		run_status_label.add_theme_font_size_override("font_size", 16)

	var status_label: Label = get_node_or_null("Margin/VBox/StatusLabel") as Label
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 15)
		status_label.modulate = Color(1, 1, 1, 0.74)

	for card_name in CARD_NODE_NAMES:
		var title_text_label: Label = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/OfferTitleLabel" % card_name) as Label
		if title_text_label != null:
			title_text_label.add_theme_font_size_override("font_size", 20)
		var detail_text_label: Label = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/OfferDetailLabel" % card_name) as Label
		if detail_text_label != null:
			detail_text_label.add_theme_font_size_override("font_size", 15)
		var claim_button: Button = get_node_or_null("Margin/VBox/CardsRow/%s/VBox/%s" % [card_name, card_name.replace("Card", "Button")]) as Button
		if claim_button != null:
			claim_button.add_theme_font_size_override("font_size", 16)


func _setup_safe_menu() -> void:
	if _safe_menu != null:
		return

	_safe_menu = SafeMenuOverlayScript.new()
	_safe_menu.name = "SafeMenuOverlay"
	_safe_menu.configure("Run Tools", "Save or load without mixing utility with reward picks.", "Tools")
	add_child(_safe_menu)
	_safe_menu.save_requested.connect(Callable(self, "_on_save_pressed"))
	_safe_menu.load_requested.connect(Callable(self, "_on_load_pressed"))


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
