# Layer: UI
extends RefCounted
class_name UiAssetPaths

const PLAYER_BUST_TEXTURE_PATH := "res://Assets/Characters/player_bust.png"
const START_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_start.svg"
const ROUTE_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_node_marker.svg"
const TRAIL_EVENT_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_trail_event.svg"
const MAP_COMBAT_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_combat.svg"
const MAP_KEY_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_key.svg"
const MAP_BOSS_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_boss.svg"
const EVENT_ICON_TEXTURE_PATH := TRAIL_EVENT_ICON_TEXTURE_PATH
const ATTACK_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_attack.svg"
const DEFEND_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_defend.svg"
const REWARD_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_reward.svg"
const REST_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_rest.svg"
const MERCHANT_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_merchant.svg"
const BLACKSMITH_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_blacksmith.svg"
const SIDE_MISSION_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_side_mission.svg"
const HAMLET_ICON_TEXTURE_PATH := SIDE_MISSION_ICON_TEXTURE_PATH
const HP_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_hp.svg"
const HUNGER_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_hunger.svg"
const DURABILITY_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_durability.svg"
const GOLD_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_gold.svg"
const KEY_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_confirm.svg"
const BOSS_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_enemy_intent_heavy.svg"
const WEAPON_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_weapon.svg"
const SHIELD_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_shield.svg"
const ARMOR_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_armor.svg"
const BELT_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_belt.svg"
const CONSUMABLE_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_consumable.svg"
const PASSIVE_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_passive.svg"
const QUEST_ITEM_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_quest_item.svg"
const SHIELD_ATTACHMENT_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_shield_attachment.svg"
const ENEMY_INTENT_ATTACK_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_enemy_intent_attack.svg"
const ENEMY_INTENT_HEAVY_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_enemy_intent_heavy.svg"
const MAP_WALKER_IDLE_TEXTURE_PATH := "res://Assets/UI/Map/Walker/ui_map_walker_idle.svg"
const MAP_WALKER_WALK_A_TEXTURE_PATH := "res://Assets/UI/Map/Walker/ui_map_walker_walk_a.svg"
const MAP_WALKER_WALK_B_TEXTURE_PATH := "res://Assets/UI/Map/Walker/ui_map_walker_walk_b.svg"
const MAP_CANOPY_TEXTURE_PATHS := [
	"res://Assets/UI/Map/Canopy/ui_map_v2_canopy_clump_a.svg",
	"res://Assets/UI/Map/Canopy/ui_map_v2_canopy_clump_b.svg",
	"res://Assets/UI/Map/Canopy/ui_map_v2_canopy_clump_c.svg",
]
const MAP_CLEARING_DECAL_NEUTRAL_TEXTURE_PATH := "res://Assets/UI/Map/Clearings/ui_map_v2_clearing_decal_neutral.svg"
const MAP_CLEARING_DECAL_BOSS_TEXTURE_PATH := "res://Assets/UI/Map/Clearings/ui_map_v2_clearing_decal_boss.svg"
const MAP_NODE_PLATE_REACHABLE_TEXTURE_PATH := "res://Assets/UI/Map/NodePlates/ui_map_v2_node_plate_reachable.svg"
const MAP_NODE_PLATE_RESOLVED_TEXTURE_PATH := "res://Assets/UI/Map/NodePlates/ui_map_v2_node_plate_resolved.svg"
const MAP_NODE_PLATE_LOCKED_TEXTURE_PATH := "res://Assets/UI/Map/NodePlates/ui_map_v2_node_plate_locked.svg"
const MAP_FILLER_TEXTURE_PATHS_BY_FAMILY := {
	"rock": [
		"res://Assets/UI/Map/Props/ui_map_v2_prop_stone_cluster_a.png",
		"res://Assets/UI/Map/Props/ui_map_v2_prop_fallen_log_a.png",
	],
	"ruin": [
		"res://Assets/UI/Map/Landmarks/ui_map_v2_landmark_waystone_a.png",
		"res://Assets/UI/Map/Landmarks/ui_map_v2_landmark_cairn_a.png",
	],
	"water_patch": [
		"res://Assets/UI/Map/Ground/ui_map_v2_ground_forest_floor_a.png",
		"res://Assets/UI/Map/Ground/ui_map_v2_ground_forest_floor_b.png",
	],
}
const ENEMY_BUST_FALLBACK_TEXTURE_PATHS := {
	# The prototype only guarantees a small bust set; keep live enemies readable with
	# the closest available family silhouette instead of showing a blank combat frame.
	"ashen_sapper": "res://Assets/Enemies/enemy_chain_trapper_bust.png",
	"carrion_runner": "res://Assets/Enemies/enemy_venom_scavenger_bust.png",
	"cutpurse_duelist": "res://Assets/Enemies/enemy_lantern_cutpurse_bust.png",
	"gatebreaker_brute": "res://Assets/Enemies/enemy_bone_raider_bust.png",
	"thornwood_warder": "res://Assets/Enemies/enemy_dusk_pikeman_bust.png",
}
const ENEMY_TOKEN_FALLBACK_TEXTURE_PATHS := {
}
const MAP_TRAIL_TEXTURE_PATHS_BY_FAMILY := {
	"short_straight": "res://Assets/UI/Map/Trails/ui_map_v2_trail_short_straight.svg",
	"gentle_curve": "res://Assets/UI/Map/Trails/ui_map_v2_trail_gentle_curve.svg",
	"wider_curve": "res://Assets/UI/Map/Trails/ui_map_v2_trail_wider_curve.svg",
	"outward_reconnecting_arc": "res://Assets/UI/Map/Trails/ui_map_v2_trail_outward_reconnecting_arc.svg",
}


static func build_enemy_bust_texture_path(definition_id: String) -> String:
	if definition_id.is_empty():
		return ""

	var texture_path := "res://Assets/Enemies/enemy_%s_bust.png" % definition_id
	if _texture_path_exists(texture_path):
		return texture_path
	var fallback_path: String = String(ENEMY_BUST_FALLBACK_TEXTURE_PATHS.get(definition_id, ""))
	if _texture_path_exists(fallback_path):
		return fallback_path

	return ""


static func build_status_icon_texture_path(item_key: String, semantic: String = "") -> String:
	var normalized_key: String = String(item_key).strip_edges().to_lower()
	var normalized_semantic: String = String(semantic).strip_edges().to_lower()
	match normalized_key:
		"hp":
			return HP_ICON_TEXTURE_PATH
		"hunger":
			return HUNGER_ICON_TEXTURE_PATH
		"gold":
			return GOLD_ICON_TEXTURE_PATH
		"durability":
			return DURABILITY_ICON_TEXTURE_PATH
		"guard":
			return DEFEND_ICON_TEXTURE_PATH
		"xp":
			return REWARD_ICON_TEXTURE_PATH
		"weapon":
			return WEAPON_ICON_TEXTURE_PATH
		"left_hand":
			return SHIELD_ICON_TEXTURE_PATH
		"armor":
			return ARMOR_ICON_TEXTURE_PATH
		"belt":
			return BELT_ICON_TEXTURE_PATH
		"quest_item":
			return QUEST_ITEM_ICON_TEXTURE_PATH
	match normalized_semantic:
		"health", "danger":
			return HP_ICON_TEXTURE_PATH
		"hunger", "sustain":
			return HUNGER_ICON_TEXTURE_PATH
		"gold", "wealth", "reward":
			return GOLD_ICON_TEXTURE_PATH if normalized_key == "gold" else REWARD_ICON_TEXTURE_PATH
		"durability", "equipment":
			return DURABILITY_ICON_TEXTURE_PATH
		"weapon":
			return WEAPON_ICON_TEXTURE_PATH
		"shield", "offhand", "guard":
			return SHIELD_ICON_TEXTURE_PATH
		"armor":
			return ARMOR_ICON_TEXTURE_PATH
		"belt":
			return BELT_ICON_TEXTURE_PATH
		"progress", "perk":
			return REWARD_ICON_TEXTURE_PATH
		_:
			return ""


static func build_inventory_family_icon_texture_path(inventory_family: String) -> String:
	match String(inventory_family).strip_edges().to_lower():
		"weapon":
			return WEAPON_ICON_TEXTURE_PATH
		"shield":
			return SHIELD_ICON_TEXTURE_PATH
		"armor":
			return ARMOR_ICON_TEXTURE_PATH
		"belt":
			return BELT_ICON_TEXTURE_PATH
		"consumable":
			return CONSUMABLE_ICON_TEXTURE_PATH
		"passive":
			return PASSIVE_ICON_TEXTURE_PATH
		"quest_item":
			return QUEST_ITEM_ICON_TEXTURE_PATH
		"shield_attachment":
			return SHIELD_ATTACHMENT_ICON_TEXTURE_PATH
		_:
			return ""


static func build_effect_icon_texture_path(
	effect_type: String,
	inventory_family: String = "",
	support_type: String = "",
	perk_family_label: String = ""
) -> String:
	var normalized_effect_type: String = String(effect_type).strip_edges().to_lower()
	match normalized_effect_type:
		"heal", "rest":
			return HP_ICON_TEXTURE_PATH if String(support_type).strip_edges().to_lower() != "rest" else REST_ICON_TEXTURE_PATH
		"grant_gold":
			return GOLD_ICON_TEXTURE_PATH
		"grant_xp":
			return REWARD_ICON_TEXTURE_PATH
		"modify_hunger":
			return HUNGER_ICON_TEXTURE_PATH
		"repair_weapon", "open_blacksmith_weapon_targets", "upgrade_weapon":
			return WEAPON_ICON_TEXTURE_PATH
		"open_blacksmith_armor_targets", "upgrade_armor":
			return ARMOR_ICON_TEXTURE_PATH
		"damage_player":
			return ATTACK_ICON_TEXTURE_PATH
		"accept_side_mission", "side_mission_info":
			return HAMLET_ICON_TEXTURE_PATH
		"buy_consumable", "buy_weapon", "buy_shield", "buy_armor", "buy_belt", "buy_passive_item", "grant_item", "claim_side_mission_reward":
			return build_inventory_family_icon_texture_path(inventory_family)
		_:
			return build_perk_family_icon_texture_path(perk_family_label)


static func build_support_type_icon_texture_path(support_type: String) -> String:
	match String(support_type).strip_edges().to_lower():
		"rest":
			return REST_ICON_TEXTURE_PATH
		"merchant":
			return MERCHANT_ICON_TEXTURE_PATH
		"blacksmith":
			return BLACKSMITH_ICON_TEXTURE_PATH
		"hamlet":
			return HAMLET_ICON_TEXTURE_PATH
		_:
			return ROUTE_ICON_TEXTURE_PATH


static func build_perk_family_icon_texture_path(perk_family_label: String) -> String:
	var normalized_family: String = String(perk_family_label).strip_edges().to_lower()
	if normalized_family.contains("defen") or normalized_family.contains("guard") or normalized_family.contains("armor"):
		return SHIELD_ICON_TEXTURE_PATH
	if normalized_family.contains("offen") or normalized_family.contains("attack") or normalized_family.contains("strike"):
		return ATTACK_ICON_TEXTURE_PATH
	if normalized_family.contains("sustain") or normalized_family.contains("recover") or normalized_family.contains("surviv"):
		return CONSUMABLE_ICON_TEXTURE_PATH
	if normalized_family.contains("utility") or normalized_family.contains("support") or normalized_family.contains("pack"):
		return PASSIVE_ICON_TEXTURE_PATH
	return REWARD_ICON_TEXTURE_PATH


static func build_enemy_token_texture_path(icon_key: String, definition_id: String = "") -> String:
	var token_stem: String = icon_key
	if token_stem.is_empty() and not definition_id.is_empty():
		token_stem = "enemy_%s" % definition_id
	if token_stem.is_empty():
		return ""

	var texture_path := "res://Assets/Enemies/%s_token.png" % token_stem
	if _texture_path_exists(texture_path):
		return texture_path
	var fallback_path: String = String(ENEMY_TOKEN_FALLBACK_TEXTURE_PATHS.get(token_stem, ""))
	if _texture_path_exists(fallback_path):
		return fallback_path

	return ""


static func _texture_path_exists(texture_path: String) -> bool:
	if texture_path.is_empty():
		return false
	var absolute_texture_path: String = ProjectSettings.globalize_path(texture_path)
	return ResourceLoader.exists(texture_path) or FileAccess.file_exists(absolute_texture_path)
