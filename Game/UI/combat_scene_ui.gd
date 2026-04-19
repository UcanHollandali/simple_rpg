# Layer: UI
extends RefCounted
class_name CombatSceneUi

const SceneLayoutHelperScript = preload("res://Game/UI/scene_layout_helper.gd")
const TempScreenThemeScript = preload("res://Game/UI/temp_screen_theme.gd")

const PLAYER_RUN_SUMMARY_CARD_PATH := "Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerRunSummaryCard"
const PLAYER_RUN_SUMMARY_LABEL_PATH := "Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerRunSummaryCard/PlayerRunSummaryFallbackLabel"
const ACTION_CARDS_ROW_PATH := "Margin/VBox/Buttons/ActionCardsRow"
const ATTACK_ACTION_CARD_PATH := "Margin/VBox/Buttons/ActionCardsRow/AttackActionCard"
const DEFENSE_ACTION_CARD_PATH := "Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard"
const ATTACK_BUTTON_PATH := "Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackButton"
const DEFENSE_BUTTON_PATH := "Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionButton"
const ENEMY_HP_BAR_NAME := "EnemyHpBar"
const COMBAT_SECONDARY_SCROLL_PATH := "Margin/VBox/SecondaryScroll"
const COMBAT_SECONDARY_SCROLL_CONTENT_PATH := "Margin/VBox/SecondaryScroll/SecondaryScrollContent"
const COMBAT_LOG_TITLE_PATH := "CombatLogCard/CombatLogVBox/CombatLogTitleLabel"
const COMBAT_LOG_ENTRIES_PATH := "CombatLogCard/CombatLogVBox/CombatLogEntries"
const PORTRAIT_LAYOUT_CONFIG := {
	"max_width": 1020,
	"min_side_margin": 20,
	"top_margin": 30,
	"bottom_margin": 30,
	"margin_steps": [
		{"max_height": 1680.0, "top_margin": 24, "bottom_margin": 24},
		{"max_height": 1480.0, "top_margin": 18, "bottom_margin": 18},
	],
	"landscape_margins": {"top_margin": 14, "bottom_margin": 14},
	"bands": {
		"large": {"min_width": 900.0, "min_height": 1700.0},
		"medium": {"min_width": 760.0, "min_height": 1500.0},
		"compact": {},
	},
}
const ACCENT_LABEL_PATHS := [
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyNameLabel",
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyTypeLabel",
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyTraitLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerIdentityRow/PlayerNameLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerLoadoutLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerStatusSection/PlayerStatusTitleLabel",
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyStatusSection/EnemyStatusTitleLabel",
	"Margin/VBox/Buttons/ActionSectionTitleLabel",
	"Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackActionEyebrowLabel",
	"Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionEyebrowLabel",
]
const REWARD_LABEL_PATHS := [
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentTitleLabel",
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentDetailLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastTitleLabel",
	"Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackActionPreviewLabel",
	"Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionPreviewLabel",
]
const BODY_LABEL_PATHS := [
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyHpLabel",
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentRow/IntentLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastAttackLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastDefenseLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastIncomingLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastGuardLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastHungerTickLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastDurabilitySpendLabel",
]
const BODY_FONT_LABEL_PATHS := [
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyNameLabel",
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyTypeLabel",
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyHpLabel",
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyTraitLabel",
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentTitleLabel",
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentDetailLabel",
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentRow/IntentLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerIdentityRow/PlayerNameLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerLoadoutLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastTitleLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastAttackLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastDefenseLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastIncomingLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastGuardLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastHungerTickLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid/ForecastDurabilitySpendLabel",
	"Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerStatusSection/PlayerStatusTitleLabel",
	"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyStatusSection/EnemyStatusTitleLabel",
	"Margin/VBox/Buttons/ActionSectionTitleLabel",
	"Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackActionEyebrowLabel",
	"Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionEyebrowLabel",
	"Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackActionPreviewLabel",
	"Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionPreviewLabel",
	"QuickItemSection/InventoryTitleLabel",
]
const ACTION_BUTTON_PATHS := [ATTACK_BUTTON_PATH, DEFENSE_BUTTON_PATH]


static func apply_temp_theme(scene: Control, secondary_node_getter: Callable) -> void:
	TempScreenThemeScript.apply_label(scene.get_node_or_null("Margin/VBox/HeaderStack/ScreenTitleLabel") as Label, "title")
	TempScreenThemeScript.apply_label(scene.get_node_or_null("Margin/VBox/HeaderStack/TurnLabel") as Label, "accent")
	TempScreenThemeScript.apply_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR)
	TempScreenThemeScript.apply_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard") as PanelContainer)
	TempScreenThemeScript.apply_choice_card_shell(scene.get_node_or_null(ATTACK_ACTION_CARD_PATH) as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR)
	TempScreenThemeScript.apply_choice_card_shell(scene.get_node_or_null(DEFENSE_ACTION_CARD_PATH) as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR)
	TempScreenThemeScript.apply_compact_status_area(scene.get_node_or_null(PLAYER_RUN_SUMMARY_CARD_PATH) as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR)
	TempScreenThemeScript.apply_panel(_secondary_node(secondary_node_getter, "CombatLogCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 16, 0.82)
	TempScreenThemeScript.apply_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 14, 0.34)
	TempScreenThemeScript.apply_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 14, 0.34)
	TempScreenThemeScript.apply_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/BossTokenFrame") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 12, 0.78)
	TempScreenThemeScript.apply_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 14, 0.8)
	TempScreenThemeScript.apply_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard") as PanelContainer, TempScreenThemeScript.REWARD_ACCENT_COLOR, 14, 0.76)
	TempScreenThemeScript.apply_inventory_section_panel(_secondary_node(secondary_node_getter, "QuickItemSection/EquipmentCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, "roomy")
	TempScreenThemeScript.apply_inventory_section_panel(_secondary_node(secondary_node_getter, "QuickItemSection/InventoryCard") as PanelContainer, TempScreenThemeScript.REWARD_ACCENT_COLOR, "roomy")
	TempScreenThemeScript.intensify_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 3, 24, 0.03, 0.24, 18, 16)
	TempScreenThemeScript.intensify_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 3, 24, 0.03, 0.22, 18, 16)
	TempScreenThemeScript.intensify_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 3, 18, 0.04, 0.22, 16, 14)
	TempScreenThemeScript.intensify_panel(scene.get_node_or_null(PLAYER_RUN_SUMMARY_CARD_PATH) as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 3, 18, 0.04, 0.22, 16, 14)
	TempScreenThemeScript.intensify_panel(_secondary_node(secondary_node_getter, "CombatLogCard") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 3, 18, 0.03, 0.18, 16, 14)
	TempScreenThemeScript.intensify_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame") as PanelContainer, TempScreenThemeScript.TEAL_ACCENT_COLOR, 2, 14, 0.03, 0.24)
	TempScreenThemeScript.intensify_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 2, 14, 0.03, 0.22)
	TempScreenThemeScript.intensify_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/BossTokenFrame") as PanelContainer, TempScreenThemeScript.RUST_ACCENT_COLOR, 2, 12, 0.03, 0.24)
	TempScreenThemeScript.intensify_panel(scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard") as PanelContainer, TempScreenThemeScript.REWARD_ACCENT_COLOR, 3, 18, 0.04, 0.22, 16, 14)
	_apply_progress_bar_style(
		scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/%s" % ENEMY_HP_BAR_NAME) as ProgressBar,
		TempScreenThemeScript.RUST_ACCENT_COLOR,
		TempScreenThemeScript.RUST_ACCENT_COLOR
	)
	TempScreenThemeScript.apply_chip(
		scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/HeroBadgePanel") as PanelContainer,
		scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/HeroBadgePanel/HeroBadgeLabel") as Label,
		TempScreenThemeScript.REWARD_ACCENT_COLOR
	)
	SceneLayoutHelperScript.apply_label_tones(scene, [
		{"paths": ACCENT_LABEL_PATHS, "tone": "accent"},
		{"paths": REWARD_LABEL_PATHS, "tone": "reward"},
		{"paths": BODY_LABEL_PATHS, "tone": "body"},
		{"path": "Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerRunSummaryCard/PlayerRunSummaryFallbackLabel", "tone": "muted"},
		{"path": "Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerRunSummaryCard/PlayerRunSummaryLabel", "tone": "muted"},
	])
	TempScreenThemeScript.apply_label(_secondary_node(secondary_node_getter, COMBAT_LOG_TITLE_PATH) as Label, "accent")
	TempScreenThemeScript.apply_inventory_section_text(
		_secondary_node(secondary_node_getter, "QuickItemSection/EquipmentTitleLabel") as Label,
		_secondary_node(secondary_node_getter, "QuickItemSection/EquipmentHintLabel") as Label,
		"accent",
		"standard"
	)
	TempScreenThemeScript.apply_inventory_section_text(
		_secondary_node(secondary_node_getter, "QuickItemSection/InventoryTitleLabel") as Label,
		_secondary_node(secondary_node_getter, "QuickItemSection/InventoryHintLabel") as Label,
		"reward",
		"standard"
	)
	TempScreenThemeScript.apply_button(scene.get_node_or_null(ATTACK_BUTTON_PATH) as Button, TempScreenThemeScript.RUST_ACCENT_COLOR)
	TempScreenThemeScript.apply_button(scene.get_node_or_null(DEFENSE_BUTTON_PATH) as Button, TempScreenThemeScript.TEAL_ACCENT_COLOR)
	SceneLayoutHelperScript.apply_control_overrides(scene, {}, [
		{"path": "Margin/VBox/HeaderStack/ScreenTitleLabel", "font_size": 48},
		{"path": "Margin/VBox/HeaderStack/TurnLabel", "font_size": 28},
		{"path": PLAYER_RUN_SUMMARY_LABEL_PATH, "font_size": 14},
		{"path": "Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/HeroBadgePanel/HeroBadgeLabel", "font_size": 14},
		{"paths": ACTION_BUTTON_PATHS, "font_size": 20},
	])
	for label_path in BODY_FONT_LABEL_PATHS:
		var info_label: Label = scene.get_node_or_null(label_path) as Label
		if info_label == null:
			info_label = _secondary_node(secondary_node_getter, label_path) as Label
		if info_label != null:
			info_label.add_theme_font_size_override("font_size", 22)
	var combat_log_title_label: Label = _secondary_node(secondary_node_getter, COMBAT_LOG_TITLE_PATH) as Label
	if combat_log_title_label != null:
		combat_log_title_label.add_theme_font_size_override("font_size", 18)
	for path in ["QuickItemSection/EquipmentHintLabel", "QuickItemSection/InventoryHintLabel"]:
		var label: Label = _secondary_node(secondary_node_getter, path) as Label
		if label != null:
			label.add_theme_font_size_override("font_size", 14)


static func apply_portrait_safe_layout(scene: Control, secondary_node_getter: Callable) -> Dictionary:
	var values: Dictionary = SceneLayoutHelperScript.apply_portrait_layout(scene, PORTRAIT_LAYOUT_CONFIG)
	if values.is_empty():
		return {}
	var viewport_size: Vector2 = values.get("viewport_size", Vector2.ZERO)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return {}
	var safe_width: float = float(values.get("safe_width", 0.0))
	var is_portrait: bool = bool(values.get("is_portrait", true))
	var compact_layout: bool = safe_width < 760.0 or (is_portrait and viewport_size.y < 1680.0) or viewport_size.x < 420.0
	var ultra_compact_layout: bool = compact_layout and (safe_width < 600.0 or viewport_size.y < 1240.0)
	var landscape_compact_layout: bool = not is_portrait
	var compact_combat_layout: bool = landscape_compact_layout or safe_width <= 740.0 or viewport_size.y <= 1960.0
	var action_columns: int = 2 if safe_width >= 400.0 else 1
	var large_layout: bool = not compact_layout and safe_width >= 900.0 and viewport_size.y >= 2200.0
	var medium_layout: bool = not large_layout and not compact_layout and safe_width >= 760.0 and viewport_size.y >= 1800.0
	var vbox: VBoxContainer = scene.get_node_or_null("Margin/VBox") as VBoxContainer
	var header_stack: VBoxContainer = scene.get_node_or_null("Margin/VBox/HeaderStack") as VBoxContainer
	var screen_title_label: Label = scene.get_node_or_null("Margin/VBox/HeaderStack/ScreenTitleLabel") as Label
	var battle_cards_row: VBoxContainer = scene.get_node_or_null("Margin/VBox/BattleCardsRow") as VBoxContainer
	var buttons_box: VBoxContainer = scene.get_node_or_null("Margin/VBox/Buttons") as VBoxContainer
	var action_cards_row: HFlowContainer = scene.get_node_or_null(ACTION_CARDS_ROW_PATH) as HFlowContainer
	var secondary_scroll: ScrollContainer = scene.get_node_or_null(COMBAT_SECONDARY_SCROLL_PATH) as ScrollContainer
	var secondary_scroll_content: VBoxContainer = scene.get_node_or_null(COMBAT_SECONDARY_SCROLL_CONTENT_PATH) as VBoxContainer
	var quick_item_section: VBoxContainer = _secondary_node(secondary_node_getter, "QuickItemSection") as VBoxContainer
	var equipment_cards_flow: HFlowContainer = _secondary_node(secondary_node_getter, "QuickItemSection/EquipmentCard/EquipmentCardsFlow") as HFlowContainer
	var inventory_cards_flow: HFlowContainer = _secondary_node(secondary_node_getter, "QuickItemSection/InventoryCard/InventoryCardsFlow") as HFlowContainer
	if vbox == null:
		return {}
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if header_stack != null:
		header_stack.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if battle_cards_row != null:
		battle_cards_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if buttons_box != null:
		buttons_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if action_cards_row != null:
		action_cards_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		action_cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if secondary_scroll != null:
		secondary_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		secondary_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if secondary_scroll_content != null:
		secondary_scroll_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if quick_item_section != null:
		quick_item_section.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var combat_log_card: PanelContainer = _secondary_node(secondary_node_getter, "CombatLogCard") as PanelContainer
	if combat_log_card != null:
		combat_log_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var combat_log_vbox: VBoxContainer = _secondary_node(secondary_node_getter, "CombatLogCard/CombatLogVBox") as VBoxContainer
	if combat_log_vbox != null:
		combat_log_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var inventory_card: PanelContainer = _secondary_node(secondary_node_getter, "QuickItemSection/InventoryCard") as PanelContainer
	if inventory_card != null:
		inventory_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var equipment_card: PanelContainer = _secondary_node(secondary_node_getter, "QuickItemSection/EquipmentCard") as PanelContainer
	if equipment_card != null:
		equipment_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var base_spacing: int = 16 if viewport_size.y >= 1640.0 else 14
	if ultra_compact_layout:
		base_spacing = 4
	elif compact_combat_layout:
		base_spacing = 3
	elif compact_layout:
		base_spacing = 4
	elif landscape_compact_layout:
		base_spacing = 6
	SceneLayoutHelperScript.apply_control_overrides(scene, {
		"base_spacing": base_spacing,
		"header_spacing": 2 if compact_combat_layout else 4 if not compact_layout else 3,
		"battle_spacing": 6 if compact_combat_layout else 10 if not compact_layout else 4,
		"button_spacing": 4 if compact_combat_layout else 8 if not compact_layout else 5,
		"quick_item_spacing": 1 if ultra_compact_layout else 3 if compact_layout else 4,
	}, [
		{"path": "Margin/VBox", "theme_constants": {"separation": "base_spacing"}},
		{"path": "Margin/VBox/HeaderStack", "theme_constants": {"separation": "header_spacing"}},
		{"path": "Margin/VBox/BattleCardsRow", "theme_constants": {"separation": "battle_spacing"}},
		{"path": "Margin/VBox/Buttons", "theme_constants": {"separation": "button_spacing"}},
	])
	if quick_item_section != null:
		quick_item_section.add_theme_constant_override("separation", 1 if ultra_compact_layout else 3 if compact_layout else 4)
	if action_cards_row != null:
		action_cards_row.add_theme_constant_override("h_separation", 4 if compact_combat_layout else 6)
		action_cards_row.add_theme_constant_override("v_separation", 4 if compact_combat_layout else 6)
	if equipment_cards_flow != null:
		equipment_cards_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		equipment_cards_flow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		equipment_cards_flow.add_theme_constant_override("separation", 4 if ultra_compact_layout else 6 if compact_layout else 8)
	if inventory_cards_flow != null:
		inventory_cards_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inventory_cards_flow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		inventory_cards_flow.add_theme_constant_override("separation", 4 if ultra_compact_layout else 6 if compact_layout else 8)
	var enemy_bust_size: Vector2 = Vector2(132, 190) if large_layout else Vector2(116, 166) if medium_layout else Vector2(80, 114) if landscape_compact_layout else Vector2(82, 114) if compact_combat_layout else Vector2(88, 124) if not ultra_compact_layout else Vector2(70, 100)
	var player_bust_size: Vector2 = Vector2(142, 206) if large_layout else Vector2(124, 184) if medium_layout else Vector2(84, 120) if landscape_compact_layout else Vector2(86, 120) if compact_combat_layout else Vector2(94, 138) if not ultra_compact_layout else Vector2(78, 112)
	var boss_token_size: Vector2 = Vector2(88, 88) if large_layout else Vector2(76, 76) if medium_layout else Vector2(58, 58) if not ultra_compact_layout else Vector2(46, 46)
	var status_icon_size: Vector2 = Vector2(30, 30) if large_layout else Vector2(26, 26) if medium_layout else Vector2(22, 22) if not ultra_compact_layout else Vector2(18, 18)
	var forecast_height: float = 104.0 if large_layout else 90.0 if medium_layout else 60.0 if landscape_compact_layout else 56.0 if compact_combat_layout else 66.0 if not ultra_compact_layout else 52.0
	var button_height: float = 64.0 if large_layout else 56.0 if medium_layout else 40.0 if landscape_compact_layout else 38.0 if compact_combat_layout else 42.0 if not ultra_compact_layout else 36.0
	var action_card_height: float = 102.0 if large_layout else 92.0 if medium_layout else 78.0 if landscape_compact_layout else 74.0 if compact_combat_layout else 0.0
	var title_font_size: int = 40 if large_layout else 34 if medium_layout else 22 if compact_combat_layout else 26 if not ultra_compact_layout else 22
	var turn_font_size: int = 24 if large_layout else 20 if medium_layout else 15 if compact_combat_layout else 17 if not ultra_compact_layout else 15
	var body_font_size: int = 20 if large_layout else 18 if medium_layout else 14 if compact_combat_layout else 15 if not ultra_compact_layout else 13
	var button_font_size: int = 20 if large_layout else 18 if medium_layout else 14 if compact_combat_layout else 15 if not ultra_compact_layout else 13
	var combat_log_height: float = 112.0 if ultra_compact_layout else 136.0 if compact_combat_layout else 176.0 if medium_layout else 196.0
	var summary_card_height: float = 84.0 if large_layout else 74.0 if medium_layout else 48.0 if landscape_compact_layout else 46.0 if compact_combat_layout else 54.0 if not ultra_compact_layout else 46.0
	var enemy_card_height: float = 184.0 if large_layout else 168.0 if medium_layout else 132.0 if landscape_compact_layout else 122.0 if compact_combat_layout else 138.0 if not ultra_compact_layout else 120.0
	var player_card_height: float = 210.0 if large_layout else 192.0 if medium_layout else 142.0 if landscape_compact_layout else 132.0 if compact_combat_layout else 154.0 if not ultra_compact_layout else 136.0
	var tall_portrait_layout: bool = is_portrait and viewport_size.y >= 2100.0
	var equipment_panel_height: float = 104.0 if ultra_compact_layout else 116.0 if compact_layout else 136.0
	var backpack_panel_height: float = 102.0 if ultra_compact_layout else 114.0 if compact_layout else 138.0
	var secondary_scroll_height: float = 320.0 if ultra_compact_layout else 380.0 if compact_combat_layout else 470.0 if large_layout else 430.0 if medium_layout else 400.0
	if tall_portrait_layout:
		equipment_panel_height = max(equipment_panel_height, 126.0)
		backpack_panel_height = max(backpack_panel_height, 140.0)
		secondary_scroll_height = max(secondary_scroll_height, 520.0)
		combat_log_height = max(combat_log_height, 208.0)
	elif large_layout:
		equipment_panel_height = max(equipment_panel_height, 136.0)
		backpack_panel_height = max(backpack_panel_height, 150.0)
		secondary_scroll_height = max(secondary_scroll_height, 500.0)
		combat_log_height = max(combat_log_height, 220.0)
	elif medium_layout:
		equipment_panel_height = max(equipment_panel_height, 132.0)
		backpack_panel_height = max(backpack_panel_height, 144.0)
		secondary_scroll_height = max(secondary_scroll_height, 460.0)
		combat_log_height = max(combat_log_height, 196.0)
	SceneLayoutHelperScript.apply_control_overrides(scene, {
		"title_font_size": title_font_size,
		"turn_font_size": turn_font_size,
		"button_font_size": button_font_size,
	}, [
		{"path": "Margin/VBox/HeaderStack/ScreenTitleLabel", "font_size": "title_font_size"},
		{"path": "Margin/VBox/HeaderStack/TurnLabel", "font_size": "turn_font_size"},
		{"paths": ACTION_BUTTON_PATHS, "font_size": "button_font_size"},
	])
	if screen_title_label != null:
		screen_title_label.visible = large_layout
	var hero_badge_panel: PanelContainer = scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/HeroBadgePanel") as PanelContainer
	if hero_badge_panel != null:
		hero_badge_panel.offset_right = 82.0 if large_layout else 74.0 if medium_layout else 66.0
		hero_badge_panel.offset_bottom = 38.0 if large_layout else 34.0 if medium_layout else 30.0
	for path in [
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/BossTokenFrame",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/BossTokenFrame/BossTokenTexture",
	]:
		var node: Control = scene.get_node_or_null(path) as Control
		if node != null:
			node.custom_minimum_size = boss_token_size
	var intent_icon: TextureRect = scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/IntentCard/IntentVBox/IntentRow/IntentIcon") as TextureRect
	if intent_icon != null:
		intent_icon.custom_minimum_size = status_icon_size
	var forecast_grid: GridContainer = scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard/ForecastVBox/ForecastGrid") as GridContainer
	if forecast_grid != null:
		forecast_grid.columns = 2
		forecast_grid.add_theme_constant_override("h_separation", 6 if compact_combat_layout else 8)
		forecast_grid.add_theme_constant_override("v_separation", 2 if compact_combat_layout else 4)
	for label_path in BODY_FONT_LABEL_PATHS:
		var info_label: Label = scene.get_node_or_null(label_path) as Label
		if info_label == null:
			info_label = _secondary_node(secondary_node_getter, label_path) as Label
		if info_label != null:
			info_label.add_theme_font_size_override("font_size", body_font_size)
			if label_path.contains("IntentDetailLabel") or label_path.contains("IntentRow/IntentLabel") or label_path.ends_with("PlayerLoadoutLabel"):
				info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inventory_hint_label: Label = _secondary_node(secondary_node_getter, "QuickItemSection/InventoryHintLabel") as Label
	if inventory_hint_label != null:
		inventory_hint_label.add_theme_font_size_override("font_size", max(13, body_font_size - 3))
	var enemy_hp_bar: ProgressBar = scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/%s" % ENEMY_HP_BAR_NAME) as ProgressBar
	if enemy_hp_bar != null:
		enemy_hp_bar.custom_minimum_size = Vector2(0.0, 20.0 if large_layout else 18.0 if medium_layout else 16.0)
	var combat_log_title_label: Label = _secondary_node(secondary_node_getter, COMBAT_LOG_TITLE_PATH) as Label
	if combat_log_title_label != null:
		combat_log_title_label.add_theme_font_size_override("font_size", max(15, body_font_size + 1))
		combat_log_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		combat_log_title_label.max_lines_visible = 1
	var combat_log_entries: VBoxContainer = _secondary_node(secondary_node_getter, COMBAT_LOG_ENTRIES_PATH) as VBoxContainer
	if combat_log_entries != null:
		combat_log_entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		combat_log_entries.size_flags_vertical = Control.SIZE_EXPAND_FILL
		combat_log_entries.add_theme_constant_override("separation", 4 if compact_layout else 5)
	var action_card_width: float = max(180.0, floor((safe_width - (float((action_columns - 1) * 6))) / float(action_columns))) if action_columns > 1 else max(0.0, safe_width - 8.0)
	for path in [
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame",
		"Margin/VBox/BattleCardsRow/EnemyCard/HBox/EnemyBustFrame/BustTexture",
	]:
		var node: Control = scene.get_node_or_null(path) as Control
		if node != null:
			node.custom_minimum_size = enemy_bust_size
	for path in [
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame",
		"Margin/VBox/BattleCardsRow/PlayerCard/HBox/PlayerBustFrame/BustTexture",
	]:
		var node: Control = scene.get_node_or_null(path) as Control
		if node != null:
			node.custom_minimum_size = player_bust_size
	var player_run_summary_card: PanelContainer = scene.get_node_or_null(PLAYER_RUN_SUMMARY_CARD_PATH) as PanelContainer
	if player_run_summary_card != null:
		player_run_summary_card.custom_minimum_size = Vector2(0.0, summary_card_height)
	var enemy_card: PanelContainer = scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard") as PanelContainer
	if enemy_card != null:
		enemy_card.custom_minimum_size = Vector2(0.0, enemy_card_height)
	var player_card: PanelContainer = scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard") as PanelContainer
	if player_card != null:
		player_card.custom_minimum_size = Vector2(0.0, player_card_height)
	var forecast_card: PanelContainer = scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/ForecastCard") as PanelContainer
	if forecast_card != null:
		forecast_card.custom_minimum_size = Vector2(0.0, forecast_height)
	for button_path in ACTION_BUTTON_PATHS:
		var action_button: Button = scene.get_node_or_null(button_path) as Button
		if action_button != null:
			action_button.custom_minimum_size = Vector2(0.0, button_height)
			action_button.add_theme_constant_override("icon_max_width", 34 if large_layout else 30 if medium_layout else 20 if compact_combat_layout else 26)
	for path in [
		"Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackActionPreviewLabel",
		"Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionPreviewLabel",
	]:
		var label: Label = scene.get_node_or_null(path) as Label
		if label != null:
			label.autowrap_mode = TextServer.AUTOWRAP_OFF if compact_combat_layout else TextServer.AUTOWRAP_WORD_SMART
			label.clip_text = compact_combat_layout
			label.add_theme_font_size_override("font_size", max(11, body_font_size - 2))
	for eyebrow_path in [
		"Margin/VBox/Buttons/ActionCardsRow/AttackActionCard/AttackActionVBox/AttackActionEyebrowLabel",
		"Margin/VBox/Buttons/ActionCardsRow/DefenseActionCard/DefenseActionVBox/DefenseActionEyebrowLabel",
	]:
		var eyebrow_label: Label = scene.get_node_or_null(eyebrow_path) as Label
		if eyebrow_label != null:
			eyebrow_label.visible = not compact_combat_layout
			eyebrow_label.add_theme_font_size_override("font_size", max(10, body_font_size - 2))
	for card_path in [ATTACK_ACTION_CARD_PATH, DEFENSE_ACTION_CARD_PATH]:
		var action_card: PanelContainer = scene.get_node_or_null(card_path) as PanelContainer
		if action_card != null:
			action_card.size_flags_horizontal = Control.SIZE_FILL if action_columns > 1 else Control.SIZE_EXPAND_FILL
			action_card.custom_minimum_size = Vector2(action_card_width, action_card_height if compact_combat_layout else 0.0)
	equipment_card = _secondary_node(secondary_node_getter, "QuickItemSection/EquipmentCard") as PanelContainer
	if equipment_card != null:
		equipment_card.custom_minimum_size = Vector2(
			0.0,
			equipment_panel_height
		)
	inventory_card = _secondary_node(secondary_node_getter, "QuickItemSection/InventoryCard") as PanelContainer
	if inventory_card != null:
		inventory_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		inventory_card.custom_minimum_size = Vector2(
			0.0,
			backpack_panel_height
		)
	combat_log_card = _secondary_node(secondary_node_getter, "CombatLogCard") as PanelContainer
	if combat_log_card != null:
		combat_log_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		combat_log_card.custom_minimum_size = Vector2(0.0, combat_log_height)
		combat_log_card.visible = combat_log_height > 0.0
	var player_status_row: HFlowContainer = scene.get_node_or_null("Margin/VBox/BattleCardsRow/PlayerCard/HBox/InfoVBox/PlayerStatusSection/PlayerStatusRow") as HFlowContainer
	if player_status_row != null:
		player_status_row.add_theme_constant_override("h_separation", 4 if not compact_layout else 3)
		player_status_row.add_theme_constant_override("v_separation", 4 if not compact_layout else 3)
	var enemy_status_row: HFlowContainer = scene.get_node_or_null("Margin/VBox/BattleCardsRow/EnemyCard/HBox/InfoVBox/EnemyStatusSection/EnemyStatusRow") as HFlowContainer
	if enemy_status_row != null:
		enemy_status_row.add_theme_constant_override("h_separation", 5 if not compact_layout else 3)
		enemy_status_row.add_theme_constant_override("v_separation", 4 if not compact_layout else 3)
	var action_section_title_label: Label = scene.get_node_or_null("Margin/VBox/Buttons/ActionSectionTitleLabel") as Label
	if action_section_title_label != null:
		action_section_title_label.visible = not compact_combat_layout
	var equipment_title_label: Label = _secondary_node(secondary_node_getter, "QuickItemSection/EquipmentTitleLabel") as Label
	if equipment_title_label != null:
		equipment_title_label.visible = true
	var equipment_hint_label: Label = _secondary_node(secondary_node_getter, "QuickItemSection/EquipmentHintLabel") as Label
	if equipment_hint_label != null:
		equipment_hint_label.visible = true
		equipment_hint_label.max_lines_visible = 1 if compact_layout else 2
	var inventory_title_label: Label = _secondary_node(secondary_node_getter, "QuickItemSection/InventoryTitleLabel") as Label
	if inventory_title_label != null:
		inventory_title_label.visible = true
	if inventory_hint_label != null:
		inventory_hint_label.visible = true
		inventory_hint_label.max_lines_visible = 1 if compact_layout else 2
	if secondary_scroll != null:
		secondary_scroll.custom_minimum_size = Vector2(0.0, secondary_scroll_height)
	return {"is_compact_layout": compact_layout or landscape_compact_layout, "action_columns": action_columns}


static func _secondary_node(secondary_node_getter: Callable, relative_path: String) -> Node:
	return secondary_node_getter.call(relative_path) if secondary_node_getter.is_valid() else null


static func _apply_progress_bar_style(bar: ProgressBar, accent: Color, fill_color: Color) -> void:
	if bar == null:
		return
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = TempScreenThemeScript.PANEL_SOFT_FILL_COLOR.darkened(0.18)
	background_style.border_color = accent.darkened(0.18)
	background_style.border_width_left = 2
	background_style.border_width_top = 2
	background_style.border_width_right = 2
	background_style.border_width_bottom = 2
	background_style.corner_radius_top_left = 10
	background_style.corner_radius_top_right = 10
	background_style.corner_radius_bottom_left = 10
	background_style.corner_radius_bottom_right = 10
	background_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.16)
	background_style.shadow_size = 8
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color.lightened(0.04)
	fill_style.corner_radius_top_left = 8
	fill_style.corner_radius_top_right = 8
	fill_style.corner_radius_bottom_left = 8
	fill_style.corner_radius_bottom_right = 8
	bar.add_theme_stylebox_override("background", background_style)
	bar.add_theme_stylebox_override("fill", fill_style)
	bar.add_theme_color_override("font_color", TempScreenThemeScript.TEXT_PRIMARY_COLOR)
	bar.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.84))
	bar.add_theme_constant_override("outline_size", 4)
