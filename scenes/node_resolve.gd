# Layer: Scenes - presentation only
extends Control

const SceneAudioPlayersScript = preload("res://Game/UI/scene_audio_players.gd")
const SceneAudioCleanupScript = preload("res://Game/UI/scene_audio_cleanup.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const TransitionShellPresenterScript = preload("res://Game/UI/transition_shell_presenter.gd")
const PANEL_OPEN_SFX_PATH := "res://Assets/Audio/SFX/sfx_panel_open_01.ogg"
const TRANSITION_HOLD_SECONDS := 0.14
const PORTRAIT_SAFE_MAX_WIDTH := 780
const PORTRAIT_SAFE_MIN_SIDE_MARGIN := 28
const SILENT_RESOLVE_NODE_TYPES: PackedStringArray = ["key", "reward"]
const AUDIO_PLAYER_NODE_NAMES: Array[String] = ["PanelOpenSfxPlayer"]

var _bootstrap
var _presenter: TransitionShellPresenter


func _ready() -> void:
	_bootstrap = get_node_or_null("/root/AppBootstrap")
	_presenter = TransitionShellPresenterScript.new()
	_configure_audio_players()
	var pending_node_type: String = _get_pending_node_type()
	if _should_skip_resolve_overlay(pending_node_type):
		visible = false
		Callable(self, "_resolve_node").call_deferred()
	else:
		_refresh_ui()
		_connect_viewport_layout_updates()
		_apply_portrait_safe_layout()
		SceneAudioPlayersScript.play(self, "PanelOpenSfxPlayer")
		Callable(self, "_resolve_node").call_deferred()


func _exit_tree() -> void:
	_disconnect_viewport_layout_updates()
	SceneAudioCleanupScript.release_players(self, AUDIO_PLAYER_NODE_NAMES)


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
		node_icon.texture = _load_texture_or_null(_presenter.build_node_icon_texture_path(pending_node_type))
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


func _configure_audio_players() -> void:
	SceneAudioPlayersScript.assign_stream_from_path(self, "PanelOpenSfxPlayer", PANEL_OPEN_SFX_PATH)


func _load_texture_or_null(asset_path: String) -> Texture2D:
	if asset_path.is_empty():
		return null
	var resource: Resource = load(asset_path)
	if resource is Texture2D:
		return resource as Texture2D
	return null


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
		_resolve_chip_accent_for_node_type(node_type)
	)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/Panel/VBox/TitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/Panel/VBox/SummaryLabel") as Label, "accent")
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/Panel/VBox/DetailLabel") as Label)
	TempScreenThemeScript.apply_label(get_node_or_null("Margin/Center/Panel/VBox/HintLabel") as Label, "muted")

	var title_label: Label = get_node_or_null("Margin/Center/Panel/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 24)


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
	var panel: PanelContainer = get_node_or_null("Margin/Center/Panel") as PanelContainer
	var vbox: VBoxContainer = get_node_or_null("Margin/Center/Panel/VBox") as VBoxContainer
	var node_icon: TextureRect = get_node_or_null("Margin/Center/Panel/VBox/NodeIcon") as TextureRect
	if margin == null or panel == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var top_margin: int = 132
	var bottom_margin: int = 132
	if viewport_size.y < 1760.0:
		top_margin = 104
		bottom_margin = 104
	if viewport_size.y < 1540.0:
		top_margin = 80
		bottom_margin = 80

	var safe_width: int = TempScreenThemeScript.apply_portrait_safe_margins(
		margin,
		PORTRAIT_SAFE_MAX_WIDTH,
		PORTRAIT_SAFE_MIN_SIDE_MARGIN,
		top_margin,
		bottom_margin
	)
	panel.custom_minimum_size = Vector2(min(float(safe_width), 720.0 if viewport_size.y >= 1640.0 else 620.0 if viewport_size.y >= 1460.0 else 520.0), 0.0)
	if vbox != null:
		vbox.add_theme_constant_override("separation", 12 if viewport_size.y < 1560.0 else 16)

	var large_layout: bool = safe_width >= 660 and viewport_size.y >= 1640.0
	var medium_layout: bool = not large_layout and safe_width >= 560 and viewport_size.y >= 1460.0
	var title_font_size: int = 44 if large_layout else 38 if medium_layout else 32
	var summary_font_size: int = 24 if large_layout else 21 if medium_layout else 18
	var body_font_size: int = 20 if large_layout else 18 if medium_layout else 16
	var icon_size: float = 96.0 if large_layout else 82.0 if medium_layout else 68.0

	var title_label: Label = get_node_or_null("Margin/Center/Panel/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", title_font_size)
	var summary_label: Label = get_node_or_null("Margin/Center/Panel/VBox/SummaryLabel") as Label
	if summary_label != null:
		summary_label.add_theme_font_size_override("font_size", summary_font_size)
	var detail_label: Label = get_node_or_null("Margin/Center/Panel/VBox/DetailLabel") as Label
	if detail_label != null:
		detail_label.add_theme_font_size_override("font_size", body_font_size)
	var hint_label: Label = get_node_or_null("Margin/Center/Panel/VBox/HintLabel") as Label
	if hint_label != null:
		hint_label.add_theme_font_size_override("font_size", body_font_size)
	if node_icon != null:
		node_icon.custom_minimum_size = Vector2(icon_size, icon_size)


func _resolve_accent_for_node_type(node_type: String) -> Color:
	match node_type:
		"combat", "boss":
			return TempScreenThemeScript.RUST_ACCENT_COLOR
		"reward", "key":
			return TempScreenThemeScript.REWARD_ACCENT_COLOR
		_:
			return TempScreenThemeScript.TEAL_ACCENT_COLOR


func _resolve_chip_accent_for_node_type(node_type: String) -> Color:
	match node_type:
		"combat", "boss":
			return TempScreenThemeScript.RUST_ACCENT_COLOR
		"reward", "key":
			return TempScreenThemeScript.REWARD_ACCENT_COLOR
		_:
			return TempScreenThemeScript.TEAL_ACCENT_COLOR
