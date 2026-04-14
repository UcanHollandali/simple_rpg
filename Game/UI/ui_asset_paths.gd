# Layer: UI
extends RefCounted
class_name UiAssetPaths

const PLAYER_BUST_TEXTURE_PATH := "res://Assets/Characters/player_bust.png"
const START_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_start.svg"
const ROUTE_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_node_marker.svg"
const EVENT_ICON_TEXTURE_PATH := ROUTE_ICON_TEXTURE_PATH
const ATTACK_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_attack.svg"
const REWARD_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_reward.svg"
const REST_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_rest.svg"
const MERCHANT_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_merchant.svg"
const BLACKSMITH_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_blacksmith.svg"
const SIDE_MISSION_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_map_side_mission.svg"
const HP_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_hp.svg"
const HUNGER_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_hunger.svg"
const DURABILITY_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_durability.svg"
const GOLD_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_gold.svg"
const KEY_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_confirm.svg"
const BOSS_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_enemy_intent_heavy.svg"
const WEAPON_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_weapon.svg"
const ARMOR_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_brace.svg"
const BELT_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_settings.svg"
const CONSUMABLE_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_consumable.svg"
const PASSIVE_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_reward.svg"
const ENEMY_INTENT_ATTACK_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_enemy_intent_attack.svg"
const ENEMY_INTENT_HEAVY_ICON_TEXTURE_PATH := "res://Assets/Icons/icon_enemy_intent_heavy.svg"
const MAP_WALKER_IDLE_TEXTURE_PATH := "res://Assets/UI/Map/Walker/ui_map_walker_idle.svg"
const MAP_WALKER_WALK_A_TEXTURE_PATH := "res://Assets/UI/Map/Walker/ui_map_walker_walk_a.svg"
const MAP_WALKER_WALK_B_TEXTURE_PATH := "res://Assets/UI/Map/Walker/ui_map_walker_walk_b.svg"


static func build_enemy_bust_texture_path(definition_id: String) -> String:
	if definition_id.is_empty():
		return ""

	var texture_path := "res://Assets/Enemies/enemy_%s_bust.png" % definition_id
	var absolute_texture_path: String = ProjectSettings.globalize_path(texture_path)
	if ResourceLoader.exists(texture_path) or FileAccess.file_exists(absolute_texture_path):
		return texture_path

	return ""


static func build_enemy_token_texture_path(icon_key: String, definition_id: String = "") -> String:
	var token_stem: String = icon_key
	if token_stem.is_empty() and not definition_id.is_empty():
		token_stem = "enemy_%s" % definition_id
	if token_stem.is_empty():
		return ""

	var texture_path := "res://Assets/Enemies/%s_token.png" % token_stem
	var absolute_texture_path: String = ProjectSettings.globalize_path(texture_path)
	if ResourceLoader.exists(texture_path) or FileAccess.file_exists(absolute_texture_path):
		return texture_path

	return ""
