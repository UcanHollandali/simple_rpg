# Layer: Scenes - presentation only
extends Control

const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const TransitionShellPresenterScript = preload("res://Game/UI/transition_shell_presenter.gd")
const TRANSITION_HOLD_SECONDS := 0.14
const PORTRAIT_SAFE_MAX_WIDTH := 780
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 28
const SILENT_RESOLVE_NODE_TYPES: PackedStringArray = ["key", "reward"]
const AUDIO_PLAYER_CONFIG := {
	"PanelOpenSfxPlayer": {"path": "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"},
}
const PORTRAIT_LAYOUT_CONFIG := {
	"max_width": PORTRAIT_SAFE_MAX_WIDTH,
	"min_side_margin": PORTRAIT_SAFE_MIN_SIDE_MARGIN,
	"top_margin": 132,
	"bottom_margin": 132,
	"margin_steps": [
		{"max_height": 1760.0, "top_margin": 104, "bottom_margin": 104},
		{"max_height": 1540.0, "top_margin": 80, "bottom_margin": 80},
	],
	"bands": {
		"large": {"min_width": 660.0, "min_height": 1640.0, "title_font_size": 44, "summary_font_size": 20, "body_font_size": 16, "icon_size": 96.0},
		"medium": {"min_width": 560.0, "min_height": 1460.0, "title_font_size": 38, "summary_font_size": 18, "body_font_size": 15, "icon_size": 82.0},
		"compact": {"title_font_size": 32, "summary_font_size": 16, "body_font_size": 14, "icon_size": 68.0},
	},
}

var _bootstrap
var _presenter: TransitionShellPresenter


func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_presenter = TransitionShellPresenterScript.new()
	SceneAudioPlayersScript.configure_from_config(self, AUDIO_PLAYER_CONFIG)
	var pending_node_type: String = _get_pending_node_type()
	if _should_skip_resolve_overlay(pending_node_type):
		visible = false
		Callable(self, "_resolve_node").call_deferred()
	else:
		_refresh_ui()
		SceneLayoutHelperScript.bind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
		_apply_portrait_safe_layout()
		SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")
		Callable(self, "_resolve_node").call_deferred()


func _exit_tree() -> void:
	SceneLayoutHelperScript.unbind_viewport_size_changed(self, Callable(self, "_apply_portrait_safe_layout"))
	SceneAudioCleanupScript.release_players(self, SceneAudioPlayersScript.node_names_from_config(AUDIO_PLAYER_CONFIG))


func _resolve_node() -> void:
	if _bootstrap == null:
		return

	if _should_skip_resolve_overlay(_get_pending_node_type()):
		_bootstrap.resolve_pending_node()
		return

	await get_tree().create_timer(TRANSITION_HOLD_SECONDS).timeout
	_bootstrap.resolve_pending_node()


func _should_skip_resolve_overlay(pending_node_type: String) -> bool:
	return pending_node_type in SILENT_RESOLVE_NODE_TYPES


func _refresh_ui() -> void:
	var pending_node_type: String = _get_pending_node_type()
	var pending_node_id: int = _get_pending_node_id()
	_apply_temp_theme(pending_node_type)

	var chip_label: Label = get_node_or_null("Margin/Center/Panel/VBox/ChipCard/ChipLabel") as Label
	if chip_label != null:
		chip_label.text = _presenter.build_node_resolve_chip_text(pending_node_type)

	var node_icon: TextureRect = get_node_or_null("Margin/Center/Panel/VBox/NodeIcon") as TextureRect
	if node_icon != null:
		node_icon.texture = SceneLayoutHelperScript.load_texture_or_null(_presenter.build_node_icon_texture_path(pending_node_type))
		node_icon.visible = node_icon.texture != null

	var title_label: Label = get_node_or_null("Margin/Center/Panel/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.text = _presenter.build_node_resolve_title_text(pending_node_type)

	var summary_label: Label = get_node_or_null("Margin/Center/Panel/VBox/SummaryLabel") as Label
	if summary_label != null:
		summary_label.text = _presenter.build_node_resolve_summary_text(pending_node_type)

	var detail_label: Label = get_node_or_null("Margin/Center/Panel/VBox/DetailLabel") as Label
	if detail_label != null:
		detail_label.text = _presenter.build_node_resolve_detail_text(pending_node_type, pending_node_id)

	var hint_label: Label = get_node_or_null("Margin/Center/Panel/VBox/HintLabel") as Label
	if hint_label != null:
		hint_label.text = _presenter.build_node_resolve_hint_text(pending_node_type)


func _get_pending_node_type() -> String:
	if _bootstrap == null:
		return ""
	var map_runtime_state: MapRuntimeState = _bootstrap.get_map_runtime_state()
	if map_runtime_state == null:
		return ""
	return String(map_runtime_state.pending_node_type)


func _get_pending_node_id() -> int:
	if _bootstrap == null:
		return -1
	var map_runtime_state: MapRuntimeState = _bootstrap.get_map_runtime_state()
	if map_runtime_state == null:
		return -1
	return int(map_runtime_state.pending_node_id)


func _apply_temp_theme(node_type: String) -> void:
	TempScreenThemeScript.apply_panel(
		get_node_or_null("Margin/Center/Panel") as PanelContainer,
		_resolve_accent_for_node_type(node_type),
		22,
		0.9
	)
	TempScreenThemeScript.apply_chip(
		get_node_or_null("Margin/Center/Panel/VBox/ChipCard") as PanelContainer,
		get_node_or_null("Margin/Center/Panel/VBox/ChipCard/ChipLabel") as Label,
		_resolve_accent_for_node_type(node_type)
	)
	SceneLayoutHelperScript.apply_label_tones(self, [
		{"path": "Margin/Center/Panel/VBox/TitleLabel", "tone": "title"},
		{"path": "Margin/Center/Panel/VBox/SummaryLabel", "tone": "accent"},
		{"path": "Margin/Center/Panel/VBox/DetailLabel", "tone": "body"},
		{"path": "Margin/Center/Panel/VBox/HintLabel", "tone": "muted"},
	])
	SceneLayoutHelperScript.apply_control_overrides(self, {}, [
		{"path": "Margin/Center/Panel/VBox/TitleLabel", "font_size": 24},
	])


func _apply_portrait_safe_layout() -> void:
	var values: Dictionary = SceneLayoutHelperScript.apply_portrait_layout(self, PORTRAIT_LAYOUT_CONFIG)
	if values.is_empty():
		return
	var viewport_size: Vector2 = values.get("viewport_size", Vector2.ZERO)
	values["panel_width"] = min(float(values.get("safe_width", 0.0)), 720.0 if viewport_size.y >= 1640.0 else 620.0 if viewport_size.y >= 1460.0 else 520.0)
	values["vbox_separation"] = 12 if viewport_size.y < 1560.0 else 16
	SceneLayoutHelperScript.apply_control_overrides(self, values, [
		{"path": "Margin/Center/Panel", "custom_minimum_size": {"x": "panel_width", "y": 0.0}},
		{"path": "Margin/Center/Panel/VBox", "theme_constants": {"separation": "vbox_separation"}},
		{"path": "Margin/Center/Panel/VBox/TitleLabel", "font_size": "title_font_size"},
		{"path": "Margin/Center/Panel/VBox/SummaryLabel", "font_size": "summary_font_size"},
		{"path": "Margin/Center/Panel/VBox/DetailLabel", "font_size": "body_font_size"},
		{"path": "Margin/Center/Panel/VBox/HintLabel", "font_size": "body_font_size"},
		{"path": "Margin/Center/Panel/VBox/NodeIcon", "custom_minimum_size": {"x": "icon_size", "y": "icon_size"}},
	])


func _resolve_accent_for_node_type(node_type: String) -> Color:
	match node_type:
		"combat", "boss":
			return TempScreenThemeScript.RUST_ACCENT_COLOR
		"reward", "key":
			return TempScreenThemeScript.REWARD_ACCENT_COLOR
		_:
			return TempScreenThemeScript.TEAL_ACCENT_COLOR
