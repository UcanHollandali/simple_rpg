# Layer: UI
extends RefCounted
class_name TempScreenThemeTokens

const PANEL_FILL_COLOR := Color(0.0549019, 0.0784314, 0.0941176, 0.96)
const PANEL_SOFT_FILL_COLOR := Color(0.0980392, 0.1294118, 0.145098, 0.94)
const PANEL_BORDER_COLOR := Color(0.5686275, 0.4862745, 0.3411765, 0.96)
const TEAL_ACCENT_COLOR := Color(0.2470588, 0.4196078, 0.3960784, 0.94)
const RUST_ACCENT_COLOR := Color(0.6588235, 0.3372549, 0.2470588, 0.96)
const REWARD_ACCENT_COLOR := Color(0.7803922, 0.6862745, 0.3843137, 0.98)
const TEXT_PRIMARY_COLOR := Color(0.9568627, 0.945098, 0.8745098, 1.0)
const TEXT_MUTED_COLOR := Color(0.8156863, 0.7647059, 0.6235294, 0.98)
const TEXT_SUBTLE_COLOR := Color(0.8745098, 0.8509804, 0.7843137, 0.96)
const DISABLED_TEXT_COLOR := Color(0.6627451, 0.6431373, 0.5960785, 0.88)
const BACKDROP_SCRIM_COLOR := Color(0.0235294, 0.0352941, 0.0470588, 0.76)
const REGULAR_STACK_SPACING_SHORT := 12
const REGULAR_STACK_SPACING_TALL := 16
const MENU_STACK_SPACING_SHORT := 14
const MENU_STACK_SPACING_TALL := 18
const MIN_READABLE_LABEL_FONT_SIZE := 14
const MIN_DENSE_LABEL_FONT_SIZE := 11
const MIN_VALUE_LABEL_FONT_SIZE := 14
const MIN_BUTTON_FONT_SIZE := 16
const MIN_TOUCH_TARGET_HEIGHT := 48.0
const MIN_SMALL_BUTTON_WIDTH := 96.0
const MIN_RUNTIME_ICON_SIZE := 18.0
const MIN_BUTTON_ICON_SIZE := 20
const MIN_INVENTORY_ICON_SIZE := 36.0

const SURFACE_SCRIM_ALPHA_BY_KEY := {
	"event_modal": 0.38,
	"event_modal_roadside": 0.54,
	"level_up_modal": 0.38,
	"reward_modal": 0.38,
	"main_menu_backdrop": 0.62,
}

const SURFACE_TOKENS_BY_KEY := {
	"event_modal": {
		"large": {
			"title_font_size": 44,
			"summary_font_size": 20,
			"context_font_size": 20,
			"hint_font_size": 16,
			"status_font_size": 16,
			"card_title_font_size": 24,
			"card_detail_font_size": 16,
			"button_font_size": 20,
			"button_height": 78.0,
			"card_height": 224.0,
			"button_icon_max_width": 30,
		},
		"medium": {
			"title_font_size": 38,
			"summary_font_size": 18,
			"context_font_size": 18,
			"hint_font_size": 15,
			"status_font_size": 15,
			"card_title_font_size": 22,
			"card_detail_font_size": 15,
			"button_font_size": 18,
			"button_height": 70.0,
			"card_height": 196.0,
			"button_icon_max_width": 26,
		},
		"compact": {
			"title_font_size": 32,
			"summary_font_size": 16,
			"context_font_size": 16,
			"hint_font_size": 14,
			"status_font_size": 14,
			"card_title_font_size": 20,
			"card_detail_font_size": 14,
			"button_font_size": 17,
			"button_height": 62.0,
			"card_height": 172.0,
			"button_icon_max_width": 22,
		},
	},
	"reward_modal": {
		"large": {
			"title_font_size": 44,
			"context_font_size": 20,
			"status_font_size": 16,
			"card_title_font_size": 24,
			"card_detail_font_size": 16,
			"button_font_size": 20,
			"button_height": 78.0,
			"card_height": 204.0,
			"run_status_width": 300.0,
			"button_icon_max_width": 30,
		},
		"medium": {
			"title_font_size": 38,
			"context_font_size": 18,
			"status_font_size": 15,
			"card_title_font_size": 22,
			"card_detail_font_size": 15,
			"button_font_size": 18,
			"button_height": 70.0,
			"card_height": 176.0,
			"run_status_width": 256.0,
			"button_icon_max_width": 26,
		},
		"compact": {
			"title_font_size": 32,
			"context_font_size": 16,
			"status_font_size": 14,
			"card_title_font_size": 20,
			"card_detail_font_size": 14,
			"button_font_size": 17,
			"button_height": 62.0,
			"card_height": 150.0,
			"run_status_width": 220.0,
			"button_icon_max_width": 22,
		},
	},
	"level_up_modal": {
		"large": {
			"title_font_size": 44,
			"context_font_size": 20,
			"hint_font_size": 16,
			"note_font_size": 20,
			"status_font_size": 16,
			"choice_title_font_size": 24,
			"choice_detail_font_size": 16,
			"button_height": 142.0,
			"status_width": 320.0,
			"button_icon_max_width": 30,
		},
		"medium": {
			"title_font_size": 38,
			"context_font_size": 18,
			"hint_font_size": 15,
			"note_font_size": 18,
			"status_font_size": 15,
			"choice_title_font_size": 22,
			"choice_detail_font_size": 15,
			"button_height": 124.0,
			"status_width": 272.0,
			"button_icon_max_width": 26,
		},
		"compact": {
			"title_font_size": 32,
			"context_font_size": 16,
			"hint_font_size": 14,
			"note_font_size": 16,
			"status_font_size": 14,
			"choice_title_font_size": 20,
			"choice_detail_font_size": 14,
			"button_height": 108.0,
			"status_width": 232.0,
			"button_icon_max_width": 22,
		},
	},
	"run_end_shell": {
		"large": {
			"title_font_size": 44,
			"result_font_size": 24,
			"hint_font_size": 16,
			"run_status_font_size": 16,
			"status_font_size": 16,
			"button_font_size": 20,
			"button_height": 80.0,
			"run_status_width": 320.0,
			"button_icon_max_width": 30,
			"panel_width_cap": 820.0,
		},
		"medium": {
			"title_font_size": 38,
			"result_font_size": 22,
			"hint_font_size": 15,
			"run_status_font_size": 15,
			"status_font_size": 15,
			"button_font_size": 18,
			"button_height": 72.0,
			"run_status_width": 280.0,
			"button_icon_max_width": 26,
			"panel_width_cap": 740.0,
		},
		"compact": {
			"title_font_size": 32,
			"result_font_size": 20,
			"hint_font_size": 14,
			"run_status_font_size": 14,
			"status_font_size": 14,
			"button_font_size": 17,
			"button_height": 64.0,
			"run_status_width": 236.0,
			"button_icon_max_width": 22,
			"panel_width_cap": 620.0,
		},
	},
	"stage_transition_shell": {
		"large": {
			"title_font_size": 44,
			"summary_font_size": 22,
			"hint_font_size": 16,
			"run_status_font_size": 16,
			"status_font_size": 16,
			"button_font_size": 20,
			"button_height": 80.0,
			"run_status_width": 320.0,
			"button_icon_max_width": 30,
			"panel_width_cap": 820.0,
		},
		"medium": {
			"title_font_size": 38,
			"summary_font_size": 20,
			"hint_font_size": 15,
			"run_status_font_size": 15,
			"status_font_size": 15,
			"button_font_size": 18,
			"button_height": 72.0,
			"run_status_width": 280.0,
			"button_icon_max_width": 26,
			"panel_width_cap": 740.0,
		},
		"compact": {
			"title_font_size": 32,
			"summary_font_size": 18,
			"hint_font_size": 14,
			"run_status_font_size": 14,
			"status_font_size": 14,
			"button_font_size": 17,
			"button_height": 64.0,
			"run_status_width": 236.0,
			"button_icon_max_width": 22,
			"panel_width_cap": 620.0,
		},
	},
	"main_menu": {
		"large": {
			"title_font_size": 74,
			"subtitle_font_size": 22,
			"mood_font_size": 20,
			"body_font_size": 20,
			"status_font_size": 16,
			"button_font_size": 20,
			"button_height": 84.0,
			"button_icon_max_width": 32,
		},
		"medium": {
			"title_font_size": 64,
			"subtitle_font_size": 20,
			"mood_font_size": 18,
			"body_font_size": 18,
			"status_font_size": 15,
			"button_font_size": 18,
			"button_height": 76.0,
			"button_icon_max_width": 32,
		},
		"compact": {
			"title_font_size": 54,
			"subtitle_font_size": 18,
			"mood_font_size": 16,
			"body_font_size": 16,
			"status_font_size": 14,
			"button_font_size": 17,
			"button_height": 68.0,
			"button_icon_max_width": 28,
		},
	},
}

const DEFAULT_PANEL_STYLE_TOKENS := {
	"fill_mix": 0.12,
	"fill_lighten": 0.02,
	"border_lighten": 0.08,
	"border_width": 2,
	"shadow_alpha": 0.18,
	"shadow_size": 22,
	"content_margin_x": 18,
	"content_margin_y": 16,
}

const COMPACT_STATUS_PANEL_TOKENS := {
	"corner_radius": 16,
	"fill_alpha": 0.88,
	"border_width": 3,
	"shadow_size": 18,
	"fill_boost": 0.03,
	"shadow_alpha": 0.18,
	"margin_x": 16,
	"margin_y": 12,
}

const CHOICE_CARD_PANEL_TOKENS := {
	"corner_radius": 18,
	"fill_alpha": 0.9,
	"border_width": 3,
	"shadow_size": 20,
	"fill_boost": 0.04,
	"shadow_alpha": 0.24,
	"margin_x": 18,
	"margin_y": 16,
}

const INVENTORY_PANEL_TOKENS_BY_DENSITY := {
	"standard": {
		"corner_radius": 18,
		"fill_alpha": 0.9,
		"border_width": 3,
		"shadow_size": 20,
		"fill_boost": 0.04,
		"shadow_alpha": 0.24,
		"margin_x": 18,
		"margin_y": 16,
	},
	"compact": {
		"corner_radius": 16,
		"fill_alpha": 0.88,
		"border_width": 3,
		"shadow_size": 18,
		"fill_boost": 0.03,
		"shadow_alpha": 0.22,
		"margin_x": 16,
		"margin_y": 13,
	},
	"roomy": {
		"corner_radius": 18,
		"fill_alpha": 0.9,
		"border_width": 3,
		"shadow_size": 22,
		"fill_boost": 0.04,
		"shadow_alpha": 0.24,
		"margin_x": 18,
		"margin_y": 16,
	},
}

const LARGE_BUTTON_STYLE_TOKENS := {
	"minimum_height": 68.0,
	"icon_max_width": 24,
	"h_separation": 10,
	"corner_radius": 14,
	"margin_x": 16,
	"margin_y": 12,
	"border_width": 2,
	"fill_mix": 0.12,
	"hover_lighten": 0.11,
	"hover_border_lighten": 0.14,
	"pressed_darken": 0.1,
	"disabled_darken": 0.12,
	"disabled_alpha": 0.72,
	"focus_border_lighten": 0.2,
	"normal_shadow_size": 10,
	"normal_shadow_alpha": 0.24,
	"hover_shadow_size": 12,
	"hover_shadow_alpha": 0.28,
	"pressed_shadow_size": 8,
	"pressed_shadow_alpha": 0.2,
	"disabled_shadow_size": 8,
	"disabled_shadow_alpha": 0.12,
	"focus_shadow_size": 12,
	"focus_shadow_alpha": 0.3,
}

const SMALL_BUTTON_STYLE_TOKENS := {
	"minimum_height": MIN_TOUCH_TARGET_HEIGHT,
	"minimum_width": MIN_SMALL_BUTTON_WIDTH,
	"icon_max_width": 18,
	"corner_radius": 12,
	"margin_x": 12,
	"margin_y": 8,
	"border_width": 2,
	"fill_mix": 0.12,
	"hover_lighten": 0.08,
	"hover_border_lighten": 0.12,
	"pressed_darken": 0.08,
	"disabled_darken": 0.06,
	"disabled_alpha": 0.72,
	"focus_border_lighten": 0.18,
	"normal_shadow_size": 8,
	"normal_shadow_alpha": 0.2,
	"hover_shadow_size": 9,
	"hover_shadow_alpha": 0.24,
	"pressed_shadow_size": 7,
	"pressed_shadow_alpha": 0.16,
	"disabled_shadow_size": 6,
	"disabled_shadow_alpha": 0.1,
	"focus_shadow_size": 10,
	"focus_shadow_alpha": 0.24,
}


static func resolve_surface_tokens(surface_key: String, band: String) -> Dictionary:
	var surface_tokens: Dictionary = SURFACE_TOKENS_BY_KEY.get(surface_key, {})
	if surface_tokens.is_empty():
		return {}
	var resolved_band: String = band
	if not surface_tokens.has(resolved_band):
		resolved_band = "compact"
	var resolved_tokens: Dictionary = surface_tokens.get(resolved_band, {})
	return resolved_tokens.duplicate(true)


static func resolve_surface_scrim_alpha(surface_key: String, fallback: float = 0.38) -> float:
	return float(SURFACE_SCRIM_ALPHA_BY_KEY.get(surface_key, fallback))


static func resolve_inventory_panel_tokens(density: String) -> Dictionary:
	var resolved_density: String = density if INVENTORY_PANEL_TOKENS_BY_DENSITY.has(density) else "standard"
	var tokens: Dictionary = INVENTORY_PANEL_TOKENS_BY_DENSITY.get(
		resolved_density,
		INVENTORY_PANEL_TOKENS_BY_DENSITY["standard"]
	)
	return tokens.duplicate(true)
