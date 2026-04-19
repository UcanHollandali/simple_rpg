# Layer: Scenes - presentation only
extends Control

const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const RewardStateScript = preload("res://Game/RuntimeState/reward_state.gd")
const RewardPresenterScript = preload("res://Game/UI/reward_presenter.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const RunStatusStripScript = preload("res://Game/UI/run_status_strip.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const InventoryOverflowPromptScript = preload("res://Game/UI/inventory_overflow_prompt.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const CARD_NODE_NAMES: PackedStringArray = ["ChoiceACard", "ChoiceBCard", "ChoiceCCard"]
const BUTTON_NODE_NAMES: PackedStringArray = ["ChoiceAButton", "ChoiceBButton", "ChoiceCButton"]
const OFFERS_SHELL_PATH := "Margin/VBox/OffersShell"
const OFFERS_CONTENT_PATH := OFFERS_SHELL_PATH + "/VBox"
const HEADER_CARD_PATH := OFFERS_CONTENT_PATH + "/HeaderRow/HeaderCard"
const HEADER_STACK_PATH := HEADER_CARD_PATH + "/HeaderStack"
const RUN_STATUS_CARD_PATH := OFFERS_CONTENT_PATH + "/HeaderRow/RunStatusCard"
const CARDS_ROW_PATH := OFFERS_CONTENT_PATH + "/CardsRow"
const STATUS_LABEL_PATH := "Margin/VBox/StatusLabel"
# Keep post-combat reward resolution on the map bed so the flow does not hard-cut
# into a separate temp cue every time the player exits combat.
const ONE_SHOT_SFX_TRANSITION_LEAD_IN_SECONDS := 0.08
const PORTRAIT_SAFE_MAX_WIDTH := 940
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 30
const AUDIO_PLAYER_CONFIG := {
	"RewardClaimSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_reward_pickup_01.ogg"},
	"UiConfirmSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"},
	"PanelOpenSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"},
	"RewardMusicPlayer": {"path": "res://Assets/Audio/Music/music_ui_hub_loop_proto_01.ogg", "music": true, "loop": true},
}
const PORTRAIT_LAYOUT_CONFIG := {
	"max_width": PORTRAIT_SAFE_MAX_WIDTH,
	"min_side_margin": PORTRAIT_SAFE_MIN_SIDE_MARGIN,
	"top_margin": 116,
	"bottom_margin": 112,
	"margin_steps": [
		{"max_height": 1760.0, "top_margin": 88, "bottom_margin": 88},
		{"max_height": 1540.0, "top_margin": 64, "bottom_margin": 64},
	],
	"bands": {
		"large": {"min_width": 780.0, "min_height": 1640.0, "title_font_size": 46, "context_font_size": 22, "status_font_size": 19, "card_title_font_size": 28, "card_detail_font_size": 20, "button_font_size": 22, "button_height": 78.0, "card_height": 204.0, "run_status_width": 300.0, "button_icon_max_width": 30},
		"medium": {"min_width": 640.0, "min_height": 1460.0, "title_font_size": 40, "context_font_size": 20, "status_font_size": 17, "card_title_font_size": 24, "card_detail_font_size": 18, "button_font_size": 20, "button_height": 70.0, "card_height": 176.0, "run_status_width": 256.0, "button_icon_max_width": 26},
		"compact": {"title_font_size": 34, "context_font_size": 17, "status_font_size": 15, "card_title_font_size": 21, "card_detail_font_size": 16, "button_font_size": 18, "button_height": 62.0, "card_height": 150.0, "run_status_width": 220.0, "button_icon_max_width": 22},
	},
}

var _bootstrap
var _reward_state: RewardState
var _run_state: RunState
var _presenter: RefCounted
var _reward_claim_in_flight: bool = false
var _safe_menu: SafeMenuOverlay
var _overflow_prompt: InventoryOverflowPrompt
var _pending_overflow_offer_id: String = ""
var _scene_node_cache: Dictionary = {}

@onready var _header_chip_label: Label = _scene_node("%s/ChipCard/ChipLabel" % HEADER_STACK_PATH) as Label
@onready var _header_title_label: Label = _scene_node("%s/TitleLabel" % HEADER_STACK_PATH) as Label
@onready var _header_context_label: Label = _scene_node("%s/ContextLabel" % HEADER_STACK_PATH) as Label
@onready var _header_hint_label: Label = _scene_node("%s/HintLabel" % HEADER_STACK_PATH) as Label
@onready var _status_label: Label = _scene_node(STATUS_LABEL_PATH) as Label
@onready var _run_status_card: PanelContainer = _scene_node(RUN_STATUS_CARD_PATH) as PanelContainer


func _ready() -> void:
	_scene_node_cache.clear()
	_bootstrap = _scene_node("/root/AppBootstrap")
	_reward_state = null
	_run_state = null
	_presenter = RewardPresenterScript.new()
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	if _bootstrap != null:
		_reward_state = _bootstrap.get_reward_state()
		_run_state = _bootstrap.get_run_state()

	_connect_buttons()
	_apply_temp_theme()
	_setup_safe_menu()
	_setup_overflow_prompt()
	SceneLayoutHelperScript.bind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	_apply_portrait_safe_layout()
	_render_reward_state()
	SceneAudioPlayersScript.start_looping(self, "RewardMusicPlayer")
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")


func _exit_tree() -> void:
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	SceneAudioCleanupScript.release_players(self, SceneAudioPlayersScript.node_names_from_config(AUDIO_PLAYER_CONFIG))


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
		if String(result.get("error", "")) == "inventory_choice_required":
			_reward_claim_in_flight = false
			_present_inventory_overflow_prompt(offer_id, result)
			return
		_reward_claim_in_flight = false
		_set_offer_buttons_interactable(true)
		_set_status_text("Reward failed: %s" % String(result.get("error", "unknown")))
		_reward_state = _bootstrap.get_reward_state()
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


func _on_return_to_main_menu_pressed() -> void:
	if _bootstrap == null:
		return
	var flow_manager = _bootstrap.get_flow_manager()
	if flow_manager == null:
		return
	flow_manager.request_transition(FlowStateScript.Type.MAIN_MENU)


func _connect_buttons() -> void:
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = _scene_node(_button_path(index)) as Button
		if button == null:
			continue
		var handler: Callable = Callable(self, "_on_offer_pressed").bind(index)
		if not button.is_connected("pressed", handler):
			button.connect("pressed", handler)


func _render_reward_state() -> void:
	_set_status_text("")
	if _header_chip_label != null:
		_header_chip_label.text = _presenter.build_chip_text(_reward_state)
	if _header_title_label != null:
		_header_title_label.text = _presenter.build_title_text(_reward_state)
	if _header_context_label != null:
		_header_context_label.text = _presenter.build_context_text(_reward_state)
	if _header_hint_label != null:
		_header_hint_label.text = _presenter.build_hint_text(_reward_state)
	_render_run_status_card()

	var card_models: Array[Dictionary] = _presenter.build_offer_view_models(_reward_state, CARD_NODE_NAMES.size())
	for index in range(CARD_NODE_NAMES.size()):
		var card: Control = _scene_node(_card_path(index)) as Control
		var badge_label: Label = _scene_node(_card_label_path(index, "BadgeLabel")) as Label
		var offer_title_label: Label = _scene_node(_card_label_path(index, "OfferTitleLabel")) as Label
		var offer_detail_label: Label = _scene_node(_card_label_path(index, "OfferDetailLabel")) as Label
		var button: Button = _scene_node(_button_path(index)) as Button
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


func _refresh_save_controls() -> void:
	RunMenuSceneHelperScript.sync_load_available(_safe_menu, _bootstrap)


func _card_path(index: int) -> String:
	return "%s/%s" % [CARDS_ROW_PATH, CARD_NODE_NAMES[index]]


func _card_label_path(index: int, label_name: String) -> String:
	return "%s/VBox/%s" % [_card_path(index), label_name]


func _button_path(index: int) -> String:
	return "%s/VBox/%s" % [_card_path(index), BUTTON_NODE_NAMES[index]]


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
			96,
			34,
			96
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
		TempScreenThemeScript.REWARD_ACCENT_COLOR,
		20,
		0.74
	)
	TempScreenThemeScript.intensify_panel(
		_scene_node(HEADER_CARD_PATH) as PanelContainer,
		TempScreenThemeScript.REWARD_ACCENT_COLOR,
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
		TempScreenThemeScript.REWARD_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_compact_status_area(
		_run_status_card,
		TempScreenThemeScript.PANEL_BORDER_COLOR
	)
	SceneLayoutHelperScript.apply_label_tones(self, [
		{"path": "%s/TitleLabel" % HEADER_STACK_PATH, "tone": "title"},
		{"path": "%s/ContextLabel" % HEADER_STACK_PATH, "tone": "reward"},
		{"path": "%s/HintLabel" % HEADER_STACK_PATH, "tone": "muted"},
		{"path": "%s/RunStatusLabel" % RUN_STATUS_CARD_PATH, "tone": "muted"},
		{"path": STATUS_LABEL_PATH, "tone": "body"},
	])

	for card_name in CARD_NODE_NAMES:
		var choice_card: PanelContainer = _scene_node("%s/%s" % [CARDS_ROW_PATH, card_name]) as PanelContainer
		TempScreenThemeScript.apply_choice_card_shell(choice_card, TempScreenThemeScript.REWARD_ACCENT_COLOR)
		TempScreenThemeScript.apply_label(_scene_node("%s/%s/VBox/BadgeLabel" % [CARDS_ROW_PATH, card_name]) as Label, "reward")
		TempScreenThemeScript.apply_label(_scene_node("%s/%s/VBox/OfferTitleLabel" % [CARDS_ROW_PATH, card_name]) as Label, "title")
		TempScreenThemeScript.apply_label(_scene_node("%s/%s/VBox/OfferDetailLabel" % [CARDS_ROW_PATH, card_name]) as Label)

	for button_name in BUTTON_NODE_NAMES:
		TempScreenThemeScript.apply_button(
			_scene_node("%s/%s/VBox/%s" % [CARDS_ROW_PATH, _reward_card_name_for_button(button_name), button_name]) as Button,
			TempScreenThemeScript.REWARD_ACCENT_COLOR
		)
	SceneLayoutHelperScript.apply_control_overrides(self, {}, [
		{"path": "%s/TitleLabel" % HEADER_STACK_PATH, "font_size": 34},
		{"path": "%s/ContextLabel" % HEADER_STACK_PATH, "font_size": 16},
		{"path": "%s/HintLabel" % HEADER_STACK_PATH, "font_size": 15},
		{"path": "%s/RunStatusLabel" % RUN_STATUS_CARD_PATH, "font_size": 14},
		{"path": STATUS_LABEL_PATH, "font_size": 14},
	])
	if _status_label != null:
		_status_label.modulate = Color(1, 1, 1, 0.74)
	for card_name in CARD_NODE_NAMES:
		SceneLayoutHelperScript.apply_control_overrides(self, {}, [
			{"path": "%s/%s" % [CARDS_ROW_PATH, card_name], "custom_minimum_size": {"x": 0.0, "y": 124.0}},
			{"path": "%s/%s/VBox/OfferTitleLabel" % [CARDS_ROW_PATH, card_name], "font_size": 23},
			{"path": "%s/%s/VBox/OfferDetailLabel" % [CARDS_ROW_PATH, card_name], "font_size": 15},
			{"path": "%s/%s/VBox/%s" % [CARDS_ROW_PATH, card_name, card_name.replace("Card", "Button")], "font_size": 18},
		])


func _setup_safe_menu() -> void:
	_safe_menu = RunMenuSceneHelperScript.ensure_safe_menu(
		self,
		_safe_menu,
		"Run Menu",
		"Save, load, return to menu, mute music, or quit.",
		"Settings",
		Callable(self, "_on_save_pressed"),
		Callable(self, "_on_load_pressed"),
		Callable(self, "_on_return_to_main_menu_pressed")
	)


func _setup_overflow_prompt() -> void:
	_overflow_prompt = InventoryOverflowPromptScript.new()
	_overflow_prompt.name = "InventoryOverflowPrompt"
	_overflow_prompt.configure(TempScreenThemeScript.REWARD_ACCENT_COLOR)
	add_child(_overflow_prompt)
	_overflow_prompt.discard_requested.connect(_on_overflow_discard_requested)
	_overflow_prompt.leave_requested.connect(_on_overflow_leave_requested)


func _present_inventory_overflow_prompt(offer_id: String, prompt_result: Dictionary) -> void:
	_pending_overflow_offer_id = offer_id
	if _overflow_prompt == null:
		return
	_overflow_prompt.present(prompt_result, "Leave Item")


func _clear_overflow_prompt() -> void:
	_pending_overflow_offer_id = ""
	if _overflow_prompt != null:
		_overflow_prompt.dismiss()


func _on_overflow_discard_requested(slot_id: int) -> void:
	if _bootstrap == null or _pending_overflow_offer_id.is_empty():
		return
	_reward_claim_in_flight = true
	var result: Dictionary = _bootstrap.choose_reward_option(_pending_overflow_offer_id, slot_id, false)
	if bool(result.get("ok", false)):
		_clear_overflow_prompt()
		return
	_reward_claim_in_flight = false
	_clear_overflow_prompt()
	_set_offer_buttons_interactable(true)
	_set_status_text("Reward failed: %s" % String(result.get("error", "unknown")))
	_reward_state = _bootstrap.get_reward_state()
	_render_reward_state()


func _on_overflow_leave_requested() -> void:
	if _bootstrap == null or _pending_overflow_offer_id.is_empty():
		return
	_reward_claim_in_flight = true
	var result: Dictionary = _bootstrap.choose_reward_option(_pending_overflow_offer_id, -1, true)
	if bool(result.get("ok", false)):
		_clear_overflow_prompt()
		return
	_reward_claim_in_flight = false
	_clear_overflow_prompt()
	_set_offer_buttons_interactable(true)
	_set_status_text("Reward failed: %s" % String(result.get("error", "unknown")))
	_reward_state = _bootstrap.get_reward_state()
	_render_reward_state()


func _apply_portrait_safe_layout() -> void:
	var values: Dictionary = SceneLayoutHelperScript.apply_portrait_layout(self, PORTRAIT_LAYOUT_CONFIG)
	if values.is_empty():
		return
	var viewport_size: Vector2 = values.get("viewport_size", Vector2.ZERO)
	values["vbox_separation"] = 12 if viewport_size.y < 1560.0 else 16
	values["hint_font_size"] = max(14, int(values.get("context_font_size", 17)) - 2)
	SceneLayoutHelperScript.apply_control_overrides(self, values, [
		{"path": "Margin/VBox", "theme_constants": {"separation": "vbox_separation"}},
		{"path": OFFERS_CONTENT_PATH, "theme_constants": {"separation": "vbox_separation"}},
		{"path": "%s/HeaderRow" % OFFERS_CONTENT_PATH, "theme_constants": {"separation": "vbox_separation"}},
		{"path": CARDS_ROW_PATH, "theme_constants": {"separation": "vbox_separation"}},
		{"path": "%s/TitleLabel" % HEADER_STACK_PATH, "font_size": "title_font_size"},
		{"path": "%s/ContextLabel" % HEADER_STACK_PATH, "font_size": "context_font_size"},
		{"path": "%s/HintLabel" % HEADER_STACK_PATH, "font_size": "hint_font_size"},
		{"path": "%s/RunStatusLabel" % RUN_STATUS_CARD_PATH, "font_size": "status_font_size"},
		{"path": STATUS_LABEL_PATH, "font_size": "status_font_size"},
		{"path": RUN_STATUS_CARD_PATH, "custom_minimum_size": {"x": "run_status_width", "y": 0.0}},
	])
	for card_name in CARD_NODE_NAMES:
		SceneLayoutHelperScript.apply_control_overrides(self, values, [
			{"path": "%s/%s" % [CARDS_ROW_PATH, card_name], "custom_minimum_size": {"x": 0.0, "y": "card_height"}},
			{"path": "%s/%s/VBox/BadgeLabel" % [CARDS_ROW_PATH, card_name], "font_size": "status_font_size"},
			{"path": "%s/%s/VBox/OfferTitleLabel" % [CARDS_ROW_PATH, card_name], "font_size": "card_title_font_size"},
			{"path": "%s/%s/VBox/OfferDetailLabel" % [CARDS_ROW_PATH, card_name], "font_size": "card_detail_font_size"},
			{"path": "%s/%s/VBox/%s" % [CARDS_ROW_PATH, card_name, _reward_button_name_for_card(card_name)], "font_size": "button_font_size", "custom_minimum_size": {"x": 0.0, "y": "button_height"}, "theme_constants": {"icon_max_width": "button_icon_max_width"}},
		])
	_render_run_status_card()


func _render_run_status_card() -> void:
	RunStatusStripScript.render_into(
		_run_status_card,
		_scene_node("%s/RunStatusLabel" % RUN_STATUS_CARD_PATH) as Label,
		_presenter.build_run_status_model(_run_state),
		TempScreenThemeScript.PANEL_BORDER_COLOR
	)


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
