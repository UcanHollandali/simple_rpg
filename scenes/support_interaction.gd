# Layer: Scenes - presentation only
# Keep SupportInteraction as a real runtime-backed non-combat decision screen.
# Do not collapse this scene back into an immediate-return placeholder.
extends Control

const BUTTON_NODE_NAMES: PackedStringArray = ["ActionAButton", "ActionBButton", "ActionCButton"]
const AppBootstrapScript = preload("res://Game/Application/app_bootstrap.gd")
const FlowStateScript = preload("res://Game/Application/flow_state.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const RunMenuSceneHelperScript = preload("res://Game/UI/run_menu_scene_helper.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const SupportInteractionPresenterScript = preload("res://Game/UI/support_interaction_presenter.gd")
const StackedButtonContentScript = preload("res://Game/UI/stacked_button_content.gd")
const InventoryTooltipControllerScript = preload("res://Game/UI/inventory_tooltip_controller.gd")
const InventoryOverflowPromptScript = preload("res://Game/UI/inventory_overflow_prompt.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const CUSTOM_TOOLTIP_META_KEY := "custom_tooltip_text"
const APP_BOOTSTRAP_PATH := "/root/AppBootstrap"
const MARGIN_PATH := "Margin"
const ROOT_VBOX_PATH := MARGIN_PATH + "/VBox"
const OFFERS_SHELL_PATH := ROOT_VBOX_PATH + "/OffersShell"
const OFFERS_CONTENT_PATH := OFFERS_SHELL_PATH + "/VBox"
const HEADER_CARD_PATH := OFFERS_CONTENT_PATH + "/HeaderRow/HeaderCard"
const HEADER_STACK_PATH := "%s/HeaderStack" % HEADER_CARD_PATH
const HEADER_CHIP_CARD_PATH := "%s/ChipCard" % HEADER_STACK_PATH
const RUN_STATUS_CARD_PATH := OFFERS_CONTENT_PATH + "/HeaderRow/RunStatusCard"
const RUN_STATUS_LABEL_PATH := RUN_STATUS_CARD_PATH + "/StatusLabel"
const ACTIONS_ROW_PATH := OFFERS_CONTENT_PATH + "/ActionsRow"
const FOOTER_ROW_PATH := OFFERS_CONTENT_PATH + "/FooterRow"
const LEAVE_BUTTON_PATH := FOOTER_ROW_PATH + "/LeaveButton"
const SCRIM_PATH := "Scrim"
const BACKDROP_NODE_NAMES: PackedStringArray = ["BackgroundFar", "BackgroundMid", "BackgroundOverlay"]
const ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS := 0.06
const PORTRAIT_SAFE_MAX_WIDTH := 920
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 30
const AUDIO_PLAYER_CONFIG := {
	"UiConfirmSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_ui_confirm_01.ogg"},
	"PanelOpenSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"},
	"PanelCloseSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_panel_close_01.ogg"},
	"SupportMusicPlayer": {"path": "res://Assets/Audio/Music/music_ui_hub_loop_proto_01.ogg", "music": true, "loop": true},
}
const PORTRAIT_LAYOUT_CONFIG := {
	"max_width": PORTRAIT_SAFE_MAX_WIDTH,
	"min_side_margin": PORTRAIT_SAFE_MIN_SIDE_MARGIN,
	"top_margin": 120,
	"bottom_margin": 116,
	"margin_steps": [
		{"max_height": 1760.0, "top_margin": 92, "bottom_margin": 88},
		{"max_height": 1540.0, "top_margin": 68, "bottom_margin": 64},
	],
	"bands": {
		"large": {"min_width": 760.0, "min_height": 1640.0, "title_font_size": 44, "context_font_size": 20, "summary_font_size": 20, "status_font_size": 16, "button_font_size": 20, "leave_font_size": 18, "button_height": 98.0, "leave_button_height": 60.0, "run_status_width": 300.0, "button_icon_max_width": 30},
		"medium": {"min_width": 620.0, "min_height": 1460.0, "title_font_size": 38, "context_font_size": 18, "summary_font_size": 18, "status_font_size": 15, "button_font_size": 18, "leave_font_size": 17, "button_height": 88.0, "leave_button_height": 54.0, "run_status_width": 260.0, "button_icon_max_width": 26},
		"compact": {"title_font_size": 32, "context_font_size": 16, "summary_font_size": 16, "status_font_size": 14, "button_font_size": 17, "leave_font_size": 16, "button_height": 80.0, "leave_button_height": 48.0, "run_status_width": 224.0, "button_icon_max_width": 22},
	},
}

var _bootstrap: AppBootstrapScript
var _presenter: SupportInteractionPresenter
var _support_state: SupportInteractionState
var _action_tooltip_controller: InventoryTooltipController
var _safe_menu: SafeMenuOverlay
var _overflow_prompt: InventoryOverflowPrompt
var _pending_overflow_action_id: String = ""
var _action_in_flight: bool = false
var _scene_node_cache: Dictionary = {}
var _first_run_hint_controller: FirstRunHintController

@onready var _margin: MarginContainer = _scene_node(MARGIN_PATH) as MarginContainer
@onready var _root_vbox: Control = _scene_node(ROOT_VBOX_PATH) as Control
@onready var _offers_shell: PanelContainer = _scene_node(OFFERS_SHELL_PATH) as PanelContainer
@onready var _header_card: PanelContainer = _scene_node(HEADER_CARD_PATH) as PanelContainer
@onready var _header_chip_card: PanelContainer = _scene_node(HEADER_CHIP_CARD_PATH) as PanelContainer
@onready var _header_chip_label: Label = _scene_node("%s/ChipCard/ChipLabel" % HEADER_STACK_PATH) as Label
@onready var _header_title_label: Label = _scene_node("%s/TitleLabel" % HEADER_STACK_PATH) as Label
@onready var _header_context_label: Label = _scene_node("%s/ContextLabel" % HEADER_STACK_PATH) as Label
@onready var _header_summary_label: Label = _scene_node("%s/SummaryLabel" % HEADER_STACK_PATH) as Label
@onready var _header_hint_label: Label = _scene_node("%s/HintLabel" % HEADER_STACK_PATH) as Label
@onready var _leave_button: Button = _scene_node(LEAVE_BUTTON_PATH) as Button
@onready var _run_status_card: PanelContainer = _scene_node(RUN_STATUS_CARD_PATH) as PanelContainer
@onready var _scrim: ColorRect = _scene_node(SCRIM_PATH) as ColorRect


func _ready() -> void:
	_scene_node_cache.clear()
	_bootstrap = _scene_node(APP_BOOTSTRAP_PATH) as AppBootstrapScript
	_presenter = SupportInteractionPresenterScript.new()
	_support_state = null
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	if _bootstrap != null:
		_support_state = _bootstrap.get_support_interaction_state()

	_setup_action_tooltip()
	_connect_buttons()
	_ensure_action_button_content()
	_apply_temp_theme()
	_hide_run_status_card()
	_setup_safe_menu()
	_setup_overflow_prompt()
	SceneLayoutHelperScript.bind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	_apply_portrait_safe_layout()
	_render_support_state()
	_setup_first_run_hint_controller()
	_request_contextual_first_run_hint()
	SceneAudioPlayersScript.start_looping(self, "SupportMusicPlayer")
	SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")


func _exit_tree() -> void:
	_release_first_run_hint_controller_host()
	if _action_tooltip_controller != null:
		_action_tooltip_controller.release()
		_action_tooltip_controller = null
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	SceneAudioCleanupScript.release_players(self, SceneAudioPlayersScript.node_names_from_config(AUDIO_PLAYER_CONFIG))


func _on_action_pressed(index: int) -> void:
	if _action_in_flight:
		return
	if _bootstrap == null or _support_state == null:
		return
	if index < 0 or index >= _support_state.offers.size():
		return

	var offer: Dictionary = _support_state.offers[index]
	var offer_id: String = String(offer.get("offer_id", ""))
	if offer_id.is_empty():
		return

	if _action_tooltip_controller != null:
		_action_tooltip_controller.hide(true)
	_action_in_flight = true
	SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
	var result: Dictionary = _bootstrap.choose_support_action(offer_id)
	if not bool(result.get("ok", false)):
		_action_in_flight = false
		if String(result.get("error", "")) == "inventory_choice_required":
			_present_inventory_overflow_prompt(offer_id, result)
			return
		_set_support_status_text(_presenter.build_action_failure_text(String(result.get("error", "unknown"))))
		_render_support_state()
		return
	_support_state = _bootstrap.get_support_interaction_state()
	_action_in_flight = false
	if _should_defer_to_scene_close(result):
		_set_action_buttons_interactable(false)
		return
	_render_support_state()


func _on_leave_pressed() -> void:
	if _bootstrap == null:
		return
	if _support_state != null and _support_state.is_blacksmith_target_selection_active():
		if _action_tooltip_controller != null:
			_action_tooltip_controller.hide(true)
		SceneAudioPlayersScript.play(self, "UiConfirmSfxPlayer")
		_bootstrap.choose_support_action("return_to_blacksmith_services")
		_support_state = _bootstrap.get_support_interaction_state()
		_render_support_state()
		return
	SceneAudioPlayersScript.play(self, "PanelCloseSfxPlayer")
	await SceneAudioPlayersScript.wait_for_lead_in(self, "PanelCloseSfxPlayer", ONE_SHOT_UI_TRANSITION_LEAD_IN_SECONDS)
	_set_action_buttons_interactable(false)
	if _action_tooltip_controller != null:
		_action_tooltip_controller.hide(true)
	_bootstrap.choose_support_action("leave")


func _connect_buttons() -> void:
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = _scene_node(_action_button_path(BUTTON_NODE_NAMES[index])) as Button
		if button == null:
			continue
		var handler: Callable = Callable(self, "_on_action_pressed").bind(index)
		if not button.is_connected("pressed", handler):
			button.connect("pressed", handler)
		var mouse_entered_handler: Callable = Callable(self, "_on_action_button_mouse_entered").bind(button)
		if not button.is_connected("mouse_entered", mouse_entered_handler):
			button.connect("mouse_entered", mouse_entered_handler)
		var mouse_exited_handler: Callable = Callable(self, "_on_action_button_mouse_exited").bind(button)
		if not button.is_connected("mouse_exited", mouse_exited_handler):
			button.connect("mouse_exited", mouse_exited_handler)

	if _leave_button != null and not _leave_button.is_connected("pressed", Callable(self, "_on_leave_pressed")):
		_leave_button.connect("pressed", Callable(self, "_on_leave_pressed"))


func _ensure_action_button_content() -> void:
	for button_name in BUTTON_NODE_NAMES:
		var button: Button = _scene_node(_action_button_path(button_name)) as Button
		if button == null:
			continue
		StackedButtonContentScript.ensure(button)
		button.icon = null


func _render_support_state() -> void:
	if _action_tooltip_controller != null:
		_action_tooltip_controller.hide(true)
	if _header_chip_label != null:
		_header_chip_label.text = _presenter.build_chip_text(_support_state)
	if _header_title_label != null:
		_header_title_label.text = _presenter.build_title_text(_support_state)
	if _header_context_label != null:
		_header_context_label.text = _presenter.build_context_text(_support_state)
	if _header_summary_label != null:
		_header_summary_label.text = _presenter.build_summary_text(_support_state)
		_header_summary_label.visible = not _header_summary_label.text.is_empty()
	if _header_hint_label != null:
		_header_hint_label.text = _presenter.build_hint_text(_support_state)
		_header_hint_label.visible = not _header_hint_label.text.is_empty()

	var button_models: Array[Dictionary] = _presenter.build_action_view_models(_support_state, BUTTON_NODE_NAMES.size())
	for index in range(BUTTON_NODE_NAMES.size()):
		var button: Button = _scene_node(_action_button_path(BUTTON_NODE_NAMES[index])) as Button
		if button == null:
			continue

		var model: Dictionary = button_models[index]
		button.text = ""
		button.tooltip_text = ""
		button.set_meta(CUSTOM_TOOLTIP_META_KEY, String(model.get("tooltip_text", "")))
		button.visible = bool(model.get("visible", false))
		button.disabled = bool(model.get("disabled", true))
		button.icon = null
		TempScreenThemeScript.apply_button(
			button,
			Color(model.get("accent_color", TempScreenThemeScript.TEAL_ACCENT_COLOR))
		)
		if button != null:
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		StackedButtonContentScript.apply(
			button,
			String(model.get("title_text", "")),
			String(model.get("detail_text", "")),
			SceneLayoutHelperScript.load_texture_or_null(String(model.get("icon_texture_path", "")))
		)

	if _leave_button != null:
		_leave_button.text = _presenter.build_leave_button_text(_support_state)

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


func _on_return_to_main_menu_pressed() -> void:
	if _bootstrap == null:
		return
	var flow_manager = _bootstrap.get_flow_manager()
	if flow_manager == null:
		return
	flow_manager.request_transition(FlowStateScript.Type.MAIN_MENU)


func _refresh_save_controls() -> void:
	RunMenuSceneHelperScript.sync_load_available(_safe_menu, _bootstrap)
	RunMenuSceneHelperScript.sync_tutorial_hints_available(_safe_menu, _first_run_hint_controller)


func _set_support_status_text(text: String) -> void:
	if _safe_menu != null:
		_safe_menu.set_status_text(text)


func _setup_action_tooltip() -> void:
	_action_tooltip_controller = InventoryTooltipControllerScript.new()
	_action_tooltip_controller.configure(self)


func _on_action_button_mouse_entered(button: Button) -> void:
	if _action_tooltip_controller == null or button == null:
		return
	_action_tooltip_controller.on_inventory_card_mouse_entered(button, TempScreenThemeScript.TEAL_ACCENT_COLOR)


func _on_action_button_mouse_exited(button: Button) -> void:
	if _action_tooltip_controller == null or button == null:
		return
	_action_tooltip_controller.on_inventory_card_mouse_exited(button)


func _apply_temp_theme() -> void:
	# In overlay mode keep the map bed visible and let the action cards carry the visual weight.
	var is_overlay: bool = self.top_level
	if is_overlay:
		for node_name in BACKDROP_NODE_NAMES:
			var backdrop: CanvasItem = _scene_node(node_name) as CanvasItem
			if backdrop != null:
				backdrop.visible = false
		if _scrim != null:
			_scrim.visible = true
			TempScreenThemeScript.apply_scrim(_scrim)
			_scrim.color = Color(_scrim.color.r, _scrim.color.g, _scrim.color.b, 0.38)
		if _margin != null:
			var overlay_margins: Dictionary = TempScreenThemeScript.compute_overlay_margins(get_viewport_rect().size, PORTRAIT_SAFE_MAX_WIDTH, PORTRAIT_SAFE_MIN_SIDE_MARGIN)
			_margin.add_theme_constant_override("margin_left", int(overlay_margins.get("left", PORTRAIT_SAFE_MIN_SIDE_MARGIN)))
			_margin.add_theme_constant_override("margin_top", int(overlay_margins.get("top", 40)))
			_margin.add_theme_constant_override("margin_right", int(overlay_margins.get("right", PORTRAIT_SAFE_MIN_SIDE_MARGIN)))
			_margin.add_theme_constant_override("margin_bottom", int(overlay_margins.get("bottom", 40)))
	else:
		TempScreenThemeScript.apply_modal_popup_shell(
			self,
			_margin,
			_root_vbox,
			TempScreenThemeScript.TEAL_ACCENT_COLOR,
			"ContentShell",
			34,
			102,
			34,
			102
		)
	TempScreenThemeScript.apply_panel(
		_offers_shell,
		TempScreenThemeScript.PANEL_BORDER_COLOR,
		28,
		0.6
	)
	TempScreenThemeScript.intensify_panel(
		_offers_shell,
		TempScreenThemeScript.PANEL_BORDER_COLOR,
		3,
		28,
		0.01,
		0.18,
		20,
		18
	)
	TempScreenThemeScript.apply_choice_card_shell(
		_header_card,
		TempScreenThemeScript.TEAL_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_chip(
		_header_chip_card,
		_header_chip_label,
		TempScreenThemeScript.TEAL_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_compact_status_area(
		_run_status_card,
		TempScreenThemeScript.PANEL_BORDER_COLOR
	)
	SceneLayoutHelperScript.apply_label_tones(self, [
		{"path": "%s/TitleLabel" % HEADER_STACK_PATH, "tone": "title"},
		{"path": "%s/ContextLabel" % HEADER_STACK_PATH, "tone": "reward"},
		{"path": "%s/SummaryLabel" % HEADER_STACK_PATH, "tone": "muted"},
		{"path": "%s/HintLabel" % HEADER_STACK_PATH, "tone": "accent"},
		{"path": RUN_STATUS_LABEL_PATH, "tone": "muted"},
	])
	SceneLayoutHelperScript.apply_control_overrides(self, {}, [
		{"path": HEADER_STACK_PATH, "size_flags_horizontal": Control.SIZE_EXPAND_FILL},
		{"paths": [
			"%s/TitleLabel" % HEADER_STACK_PATH,
			"%s/ContextLabel" % HEADER_STACK_PATH,
			"%s/SummaryLabel" % HEADER_STACK_PATH,
			"%s/HintLabel" % HEADER_STACK_PATH,
		], "horizontal_alignment": HORIZONTAL_ALIGNMENT_LEFT, "size_flags_horizontal": Control.SIZE_EXPAND_FILL, "autowrap_mode": TextServer.AUTOWRAP_WORD_SMART},
		{"path": RUN_STATUS_LABEL_PATH, "size_flags_horizontal": Control.SIZE_EXPAND_FILL, "autowrap_mode": TextServer.AUTOWRAP_OFF},
	])

	for button_name in BUTTON_NODE_NAMES:
		var action_button: Button = _scene_node(_action_button_path(button_name)) as Button
		TempScreenThemeScript.apply_button(action_button, TempScreenThemeScript.TEAL_ACCENT_COLOR)
		if action_button != null:
			action_button.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var content_margin: MarginContainer = _scene_node("%s/ContentMargin" % _action_button_path(button_name)) as MarginContainer
		if content_margin != null:
			content_margin.add_theme_constant_override("margin_left", 18)
			content_margin.add_theme_constant_override("margin_top", 12)
			content_margin.add_theme_constant_override("margin_right", 18)
			content_margin.add_theme_constant_override("margin_bottom", 12)

		var content_row: HBoxContainer = _scene_node("%s/ContentMargin/ContentRow" % _action_button_path(button_name)) as HBoxContainer
		if content_row != null:
			content_row.add_theme_constant_override("separation", 12)

		var content_vbox: VBoxContainer = _scene_node("%s/ContentMargin/ContentRow/ContentVBox" % _action_button_path(button_name)) as VBoxContainer
		if content_vbox != null:
			content_vbox.add_theme_constant_override("separation", 4)

	TempScreenThemeScript.apply_button(_leave_button, TempScreenThemeScript.PANEL_BORDER_COLOR, true)
	SceneLayoutHelperScript.apply_control_overrides(self, {}, [
		{"path": "%s/TitleLabel" % HEADER_STACK_PATH, "font_size": 34},
		{"path": "%s/ContextLabel" % HEADER_STACK_PATH, "font_size": 16},
		{"path": "%s/SummaryLabel" % HEADER_STACK_PATH, "font_size": 16},
		{"path": "%s/HintLabel" % HEADER_STACK_PATH, "font_size": 15},
		{"path": RUN_STATUS_LABEL_PATH, "font_size": 14},
		{"path": LEAVE_BUTTON_PATH, "font_size": 16},
	])
	for button_name in BUTTON_NODE_NAMES:
		var button_path: String = _action_button_path(button_name)
		SceneLayoutHelperScript.apply_control_overrides(self, {}, [
			{"path": button_path, "custom_minimum_size": {"x": 0.0, "y": 90.0}},
			{"path": _action_button_title_path(button_name), "font_size": 19},
			{"path": _action_button_detail_path(button_name), "font_size": 14},
			{"path": _action_button_icon_path(button_name), "custom_minimum_size": {"x": 24.0, "y": 24.0}},
		])
		var title_label: Label = _scene_node(_action_button_title_path(button_name)) as Label
		TempScreenThemeScript.apply_label(title_label, "accent")
		TempScreenThemeScript.apply_font_role(title_label, "button")
		if title_label != null:
			title_label.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
		TempScreenThemeScript.apply_label(_scene_node(_action_button_detail_path(button_name)) as Label, "muted")
	if _leave_button != null:
		_leave_button.text = "Back to the Road"


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
		Callable(self, "_on_return_to_main_menu_pressed"),
		Callable(self, "_on_disable_tutorial_hints_pressed")
	)


func _setup_overflow_prompt() -> void:
	_overflow_prompt = InventoryOverflowPromptScript.new()
	_overflow_prompt.name = "InventoryOverflowPrompt"
	_overflow_prompt.configure(TempScreenThemeScript.TEAL_ACCENT_COLOR)
	add_child(_overflow_prompt)
	_overflow_prompt.discard_requested.connect(_on_overflow_discard_requested)
	_overflow_prompt.leave_requested.connect(_on_overflow_leave_requested)


func _present_inventory_overflow_prompt(action_id: String, prompt_result: Dictionary) -> void:
	_pending_overflow_action_id = action_id
	_set_action_buttons_interactable(false)
	if _overflow_prompt == null:
		return
	_overflow_prompt.present(prompt_result, "Leave Item")


func _clear_overflow_prompt() -> void:
	_pending_overflow_action_id = ""
	if _overflow_prompt != null:
		_overflow_prompt.dismiss()


func _set_action_buttons_interactable(is_interactable: bool) -> void:
	for button_name in BUTTON_NODE_NAMES:
		var button: Button = _scene_node(_action_button_path(button_name)) as Button
		if button == null or not button.visible:
			continue
		button.disabled = not is_interactable
	if _leave_button != null:
		_leave_button.disabled = not is_interactable


func _on_overflow_discard_requested(slot_id: int) -> void:
	if _bootstrap == null or _pending_overflow_action_id.is_empty():
		return
	_action_in_flight = true
	var result: Dictionary = _bootstrap.choose_support_action(_pending_overflow_action_id, slot_id)
	if bool(result.get("ok", false)):
		_clear_overflow_prompt()
		_support_state = _bootstrap.get_support_interaction_state()
		_action_in_flight = false
		if _should_defer_to_scene_close(result):
			_set_action_buttons_interactable(false)
			return
		_render_support_state()
		return
	_action_in_flight = false
	_clear_overflow_prompt()
	_set_support_status_text(_presenter.build_action_failure_text(String(result.get("error", "unknown"))))
	_support_state = _bootstrap.get_support_interaction_state()
	_render_support_state()


func _on_overflow_leave_requested() -> void:
	_clear_overflow_prompt()
	_action_in_flight = false
	_render_support_state()


func _apply_portrait_safe_layout() -> void:
	var values: Dictionary = SceneLayoutHelperScript.apply_portrait_layout(self, PORTRAIT_LAYOUT_CONFIG)
	if values.is_empty():
		return
	var viewport_size: Vector2 = values.get("viewport_size", Vector2.ZERO)
	values["vbox_separation"] = 12 if viewport_size.y < 1560.0 else 16
	values["footer_separation"] = 10 if viewport_size.y < 1560.0 else 12
	values["hint_font_size"] = max(14, int(values.get("summary_font_size", 17)) - 2)
	SceneLayoutHelperScript.apply_control_overrides(self, values, [
		{"path": ROOT_VBOX_PATH, "theme_constants": {"separation": "vbox_separation"}},
		{"path": OFFERS_CONTENT_PATH, "theme_constants": {"separation": "vbox_separation"}},
		{"path": "%s/HeaderRow" % OFFERS_CONTENT_PATH, "theme_constants": {"separation": "vbox_separation"}},
		{"path": HEADER_STACK_PATH, "theme_constants": {"separation": 4}},
		{"path": ACTIONS_ROW_PATH, "theme_constants": {"separation": "vbox_separation"}},
		{"path": FOOTER_ROW_PATH, "theme_constants": {"separation": "footer_separation"}},
		{"path": "%s/TitleLabel" % HEADER_STACK_PATH, "font_size": "title_font_size"},
		{"path": "%s/ContextLabel" % HEADER_STACK_PATH, "font_size": "context_font_size"},
		{"path": "%s/SummaryLabel" % HEADER_STACK_PATH, "font_size": "summary_font_size"},
		{"path": "%s/HintLabel" % HEADER_STACK_PATH, "font_size": "hint_font_size"},
		{"path": RUN_STATUS_LABEL_PATH, "font_size": "status_font_size"},
		{"path": RUN_STATUS_CARD_PATH, "custom_minimum_size": {"x": "run_status_width", "y": 0.0}},
		{"path": LEAVE_BUTTON_PATH, "font_size": "leave_font_size", "custom_minimum_size": {"x": 0.0, "y": "leave_button_height"}},
	])
	for button_name in BUTTON_NODE_NAMES:
		var button_path: String = _action_button_path(button_name)
		SceneLayoutHelperScript.apply_control_overrides(self, values, [
			{"path": button_path, "custom_minimum_size": {"x": 0.0, "y": "button_height"}},
			{"path": _action_button_title_path(button_name), "font_size": "button_font_size"},
			{"path": _action_button_detail_path(button_name), "font_size": max(13, int(values.get("button_font_size", 18)) - 3)},
			{"path": _action_button_icon_path(button_name), "custom_minimum_size": {"x": "button_icon_max_width", "y": "button_icon_max_width"}},
		])
	if _action_tooltip_controller != null:
		_action_tooltip_controller.refresh_hovered_tooltip()
	if _first_run_hint_controller != null:
		_first_run_hint_controller.refresh_position()


func _hide_run_status_card() -> void:
	if _run_status_card == null:
		return
	_run_status_card.visible = false
	_run_status_card.custom_minimum_size = Vector2.ZERO


func _should_defer_to_scene_close(result: Dictionary) -> bool:
	return int(result.get("target_state", FlowStateScript.Type.SUPPORT_INTERACTION)) != FlowStateScript.Type.SUPPORT_INTERACTION or _support_state == null


func _action_button_path(button_name: String) -> String:
	return "%s/%s" % [ACTIONS_ROW_PATH, button_name]


func _action_button_title_path(button_name: String) -> String:
	return StackedButtonContentScript.title_path(_action_button_path(button_name))


func _action_button_detail_path(button_name: String) -> String:
	return StackedButtonContentScript.detail_path(_action_button_path(button_name))


func _action_button_icon_path(button_name: String) -> String:
	return StackedButtonContentScript.icon_path(_action_button_path(button_name))


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


func _setup_first_run_hint_controller() -> void:
	_first_run_hint_controller = _resolve_first_run_hint_controller()
	if _first_run_hint_controller == null:
		return
	_first_run_hint_controller.setup(self, HEADER_STACK_PATH, 190)
	RunMenuSceneHelperScript.sync_tutorial_hints_available(_safe_menu, _first_run_hint_controller)


func _release_first_run_hint_controller_host() -> void:
	if _first_run_hint_controller == null:
		return
	_first_run_hint_controller.release_host(self)
	_first_run_hint_controller = null
	RunMenuSceneHelperScript.sync_tutorial_hints_available(_safe_menu, _first_run_hint_controller)


func _request_contextual_first_run_hint() -> void:
	_setup_first_run_hint_controller()
	if _first_run_hint_controller == null or _support_state == null:
		return
	if String(_support_state.support_type) == "hamlet":
		_first_run_hint_controller.request_hint("first_hamlet")


func _resolve_first_run_hint_controller() -> FirstRunHintController:
	if _bootstrap == null:
		return null
	_bootstrap.ensure_run_state_initialized()
	var coordinator: RefCounted = _bootstrap.run_session_coordinator
	if coordinator == null:
		return null
	return coordinator.get("_first_run_hint_controller") as FirstRunHintController

func _on_disable_tutorial_hints_pressed() -> void:
	_setup_first_run_hint_controller()
	if _first_run_hint_controller == null:
		return
	var changed: bool = _first_run_hint_controller.mark_all_hints_shown()
	RunMenuSceneHelperScript.sync_tutorial_hints_available(_safe_menu, _first_run_hint_controller)
	if _safe_menu != null:
		_safe_menu.set_status_text(RunMenuSceneHelperScript.build_tutorial_hints_status_text(changed))
