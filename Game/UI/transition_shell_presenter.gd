# Layer: UI
extends RefCounted
class_name TransitionShellPresenter

const MapDisplayNameHelperScript = preload("res://Game/UI/map_display_name_helper.gd")
const UiCompactCopyScript = preload("res://Game/UI/ui_compact_copy.gd")
const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")

func build_node_resolve_chip_text(node_type: String) -> String:
	match node_type:
		"combat", "boss":
			return "THREAT READ"
		"event":
			return "ENCOUNTER READ"
		"reward":
			return "CACHE READ"
		"key":
			return "KEY READ"
		_:
			return "PATH READ"


func build_node_resolve_title_text(node_type: String) -> String:
	if node_type.is_empty():
		return "Opening Next Node"
	return "Opening %s" % _display_name_for_node_type(node_type)


func build_node_resolve_summary_text(node_type: String) -> String:
	match node_type:
		"combat":
			return "Fight ahead."
		"boss":
			return "Boss fight ahead."
		"event":
			return "Event ahead."
		"reward":
			return "Cache ahead."
		"key":
			return "Key found. Gate unlocked."
		_:
			return "Opening next node."


func build_node_resolve_detail_text(node_type: String, pending_node_id: int) -> String:
	var detail_parts: PackedStringArray = []
	if pending_node_id >= 0:
		detail_parts.append("Node %d." % pending_node_id)
	detail_parts.append(UiCompactCopyScript.auto_bridge())
	return " ".join(detail_parts)


func build_node_resolve_hint_text(node_type: String) -> String:
	return UiCompactCopyScript.auto_bridge()


func build_node_icon_texture_path(node_type: String) -> String:
	match node_type:
		"combat":
			return UiAssetPathsScript.MAP_COMBAT_ICON_TEXTURE_PATH
		"boss":
			return UiAssetPathsScript.MAP_BOSS_ICON_TEXTURE_PATH
		"event":
			return UiAssetPathsScript.EVENT_ICON_TEXTURE_PATH
		"reward":
			return UiAssetPathsScript.REWARD_ICON_TEXTURE_PATH
		"key":
			return UiAssetPathsScript.MAP_KEY_ICON_TEXTURE_PATH
		_:
			return UiAssetPathsScript.ROUTE_ICON_TEXTURE_PATH


func _display_name_for_node_type(node_type: String) -> String:
	return MapDisplayNameHelperScript.build_family_display_name(node_type)
