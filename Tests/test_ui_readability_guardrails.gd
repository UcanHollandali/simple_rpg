# Layer: Tests
extends SceneTree
class_name TestUiReadabilityGuardrails

const UiTypographyScript = preload("res://Game/UI/ui_typography.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")
const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const RunStatusStripScript = preload("res://Game/UI/run_status_strip.gd")


func _init() -> void:
	Callable(self, "_run").call_deferred()


func _run() -> void:
	test_decorative_font_usage_stays_title_only_by_default()
	test_shared_surface_token_tables_keep_band_values_stable()
	test_small_button_guardrails_keep_touch_target_and_icon_floor()
	test_scene_layout_helper_clamps_button_and_icon_readability()
	test_scene_layout_helper_spacing_resolvers_keep_tokenized_thresholds()
	test_scene_layout_helper_surface_panel_width_keeps_shared_token_owner()
	test_run_status_strip_uses_readable_value_text_and_icon_floor()
	print("test_ui_readability_guardrails: all assertions passed")
	quit()


func test_decorative_font_usage_stays_title_only_by_default() -> void:
	assert(
		UiTypographyScript.resolve_label_role("title") == UiTypographyScript.ROLE_HEADING,
		"Expected title labels to remain the shared decorative-font lane."
	)
	assert(
		UiTypographyScript.resolve_label_role("accent") == UiTypographyScript.ROLE_BODY,
		"Expected accent labels to use the readable body-font lane by default."
	)
	assert(
		UiTypographyScript.resolve_label_role("reward") == UiTypographyScript.ROLE_BODY,
		"Expected reward labels to use the readable body-font lane by default."
	)
	assert(
		UiTypographyScript.resolve_label_role("danger") == UiTypographyScript.ROLE_BODY,
		"Expected danger labels to use the readable body-font lane by default."
	)


func test_shared_surface_token_tables_keep_band_values_stable() -> void:
	var event_tokens: Dictionary = TempScreenThemeScript.resolve_surface_tokens("event_modal", "medium")
	assert(
		int(event_tokens.get("title_font_size", 0)) == 38,
		"Expected the shared event-modal token table to keep the medium title size."
	)
	assert(
		int(event_tokens.get("button_icon_max_width", 0)) == 26,
		"Expected the shared event-modal token table to keep the medium button icon width."
	)

	var run_end_tokens: Dictionary = TempScreenThemeScript.resolve_surface_tokens("run_end_shell", "compact")
	assert(
		is_equal_approx(float(run_end_tokens.get("panel_width_cap", 0.0)), 620.0),
		"Expected the shared run-end shell token table to keep the compact panel width cap."
	)
	assert(
		is_equal_approx(TempScreenThemeScript.resolve_surface_scrim_alpha("main_menu_backdrop", 0.0), 0.62),
		"Expected the shared scrim-alpha token table to keep the main-menu backdrop alpha."
	)


func test_small_button_guardrails_keep_touch_target_and_icon_floor() -> void:
	var button := Button.new()
	get_root().add_child(button)
	TempScreenThemeScript.apply_small_button(button)
	assert(
		button.custom_minimum_size.y >= TempScreenThemeScript.MIN_TOUCH_TARGET_HEIGHT,
		"Expected shared small-button styling to keep the minimum portrait touch-target height."
	)
	assert(
		button.custom_minimum_size.x >= TempScreenThemeScript.MIN_SMALL_BUTTON_WIDTH,
		"Expected shared small-button styling to keep the minimum readable width budget."
	)
	assert(
		button.get_theme_constant("icon_max_width") >= TempScreenThemeScript.MIN_BUTTON_ICON_SIZE,
		"Expected shared small-button styling to keep icons above the shared readability floor."
	)
	button.queue_free()


func test_scene_layout_helper_clamps_button_and_icon_readability() -> void:
	var scene := Control.new()
	var button := Button.new()
	button.name = "ActionButton"
	scene.add_child(button)
	var label := Label.new()
	label.name = "HelperLabel"
	scene.add_child(label)
	var icon := TextureRect.new()
	icon.name = "IconRect"
	scene.add_child(icon)
	get_root().add_child(scene)

	SceneLayoutHelperScript.apply_control_overrides(scene, {
		"button_font_size": 15,
		"button_height": 42.0,
		"button_icon_size": 18,
		"label_font_size": 12,
		"icon_size": 16.0,
	}, [
		{"path": "ActionButton", "font_size": "button_font_size", "custom_minimum_size": {"x": 0.0, "y": "button_height"}, "theme_constants": {"icon_max_width": "button_icon_size"}},
		{"path": "HelperLabel", "font_size": "label_font_size"},
		{"path": "IconRect", "custom_minimum_size": {"x": "icon_size", "y": "icon_size"}},
	])

	assert(
		button.get_theme_font_size("font_size") >= TempScreenThemeScript.MIN_BUTTON_FONT_SIZE,
		"Expected shared scene layout overrides to clamp undersized button text."
	)
	assert(
		button.custom_minimum_size.y >= TempScreenThemeScript.MIN_TOUCH_TARGET_HEIGHT,
		"Expected shared scene layout overrides to clamp undersized button targets."
	)
	assert(
		button.get_theme_constant("icon_max_width") >= TempScreenThemeScript.MIN_BUTTON_ICON_SIZE,
		"Expected shared scene layout overrides to clamp undersized button icons."
	)
	assert(
		label.get_theme_font_size("font_size") >= TempScreenThemeScript.MIN_READABLE_LABEL_FONT_SIZE,
		"Expected shared scene layout overrides to clamp undersized label text."
	)
	assert(
		icon.custom_minimum_size.x >= TempScreenThemeScript.MIN_RUNTIME_ICON_SIZE
			and icon.custom_minimum_size.y >= TempScreenThemeScript.MIN_RUNTIME_ICON_SIZE,
		"Expected shared scene layout overrides to clamp undersized runtime icons."
	)
	scene.queue_free()


func test_scene_layout_helper_spacing_resolvers_keep_tokenized_thresholds() -> void:
	assert(
		SceneLayoutHelperScript.resolve_height_tier_spacing(1500.0, 1560.0, TempScreenThemeScript.REGULAR_STACK_SPACING_SHORT, TempScreenThemeScript.REGULAR_STACK_SPACING_TALL)
			== TempScreenThemeScript.REGULAR_STACK_SPACING_SHORT,
		"Expected short viewports to keep the shared regular compact stack spacing token."
	)
	assert(
		SceneLayoutHelperScript.resolve_height_tier_spacing(1600.0, 1560.0, TempScreenThemeScript.REGULAR_STACK_SPACING_SHORT, TempScreenThemeScript.REGULAR_STACK_SPACING_TALL)
			== TempScreenThemeScript.REGULAR_STACK_SPACING_TALL,
		"Expected taller viewports to keep the shared regular roomy stack spacing token."
	)
	assert(
		SceneLayoutHelperScript.resolve_width_tier_spacing(700.0, 760.0, 8, 12) == 8,
		"Expected narrow widths to keep the compact width-tier spacing."
	)
	assert(
		SceneLayoutHelperScript.resolve_width_tier_spacing(820.0, 760.0, 8, 12) == 12,
		"Expected wider widths to keep the roomy width-tier spacing."
	)


func test_scene_layout_helper_surface_panel_width_keeps_shared_token_owner() -> void:
	assert(
		is_equal_approx(
			SceneLayoutHelperScript.resolve_surface_panel_width("run_end_shell", 700.0, null),
			620.0
		),
		"Expected missing panel-width overrides to fall back to the shared compact run-end token."
	)
	assert(
		is_equal_approx(
			SceneLayoutHelperScript.resolve_surface_panel_width("stage_transition_shell", 700.0, 680.0),
			680.0
		),
		"Expected explicit panel-width caps to keep taking priority when the shared surface token is already present."
	)


func test_run_status_strip_uses_readable_value_text_and_icon_floor() -> void:
	var card := PanelContainer.new()
	var fallback := Label.new()
	card.add_child(fallback)
	get_root().add_child(card)

	RunStatusStripScript.render_into(card, fallback, {
		"density": "minimal",
		"primary_items": [{
			"key": "hp",
			"label_text": "HP",
			"value_text": "33/60",
			"semantic": "health",
			"current_value": 33,
			"max_value": 60,
		}],
		"secondary_items": [],
		"progress_items": [],
		"fallback_text": "HP 33/60",
	})

	var value_label: Label = card.get_node_or_null("RunStatusRoot/PrimaryFlow/hpChip/MetricInlineRow/MetricValueLabel") as Label
	var metric_label: Label = card.get_node_or_null("RunStatusRoot/PrimaryFlow/hpChip/MetricInlineRow/MetricLabel") as Label
	assert(metric_label != null, "Expected the shared run-status strip to build the metric label.")
	assert(
		metric_label.get_theme_font_size("font_size") >= TempScreenThemeScript.MIN_DENSE_LABEL_FONT_SIZE,
		"Expected the shared run-status strip to keep minimal-density metric labels above the dense readability floor."
	)
	assert(value_label != null, "Expected the shared run-status strip to build the metric value label.")
	assert(
		value_label.get_theme_font("font") == UiTypographyScript.INTER_FONT,
		"Expected the shared run-status strip to render gameplay values with the readable runtime font."
	)
	assert(
		value_label.get_theme_font_size("font_size") >= 18,
		"Expected the shared run-status strip to keep the minimal-density value text above the readable floor."
	)

	var inline_row: HBoxContainer = card.get_node_or_null("RunStatusRoot/PrimaryFlow/hpChip/MetricInlineRow") as HBoxContainer
	var icon_rect: TextureRect = null
	if inline_row != null:
		for child in inline_row.get_children():
			icon_rect = child as TextureRect
			if icon_rect != null:
				break
	assert(icon_rect != null, "Expected the shared run-status strip to build a metric icon when a status texture exists.")
	assert(
		icon_rect.custom_minimum_size.x >= TempScreenThemeScript.MIN_RUNTIME_ICON_SIZE
			and icon_rect.custom_minimum_size.y >= TempScreenThemeScript.MIN_RUNTIME_ICON_SIZE,
		"Expected the shared run-status strip to keep minimal-density icons above the runtime readability floor."
	)
	card.queue_free()
