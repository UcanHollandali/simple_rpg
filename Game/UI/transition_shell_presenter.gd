# Layer: UI
extends RefCounted
class_name TransitionShellPresenter

const UiAssetPathsScript = preload("res://Game/UI/ui_asset_paths.gd")

const NODE_DISPLAY_NAMES: Dictionary = {
	"combat": "Combat Encounter",
	"boss": "Boss Gate",
	"event": "Roadside Encounter",
	"reward": "Reward Cache",
	"key": "Stage Key",
}


func build_run_setup_title_text() -> String:
	return "Setting Out"


func build_run_setup_chip_text() -> String:
	return "FIRST ROAD"


func build_run_setup_summary_text() -> String:
	return "Steel, rations, and the first road fall into place."


func build_run_setup_detail_text() -> String:
	return "This brief handoff opens the run and sends you straight to the map."


func build_run_setup_hint_text() -> String:
	return "The map opens automatically."


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
		return "Resolving Next Node"
	return "Resolving %s" % _display_name_for_node_type(node_type)


func build_node_resolve_summary_text(node_type: String) -> String:
	match node_type:
		"combat":
			return "Brush parts ahead. The next combat encounter is opening."
		"boss":
			return "The path hardens. The stage boss encounter is opening."
		"event":
			return "Something on the road wants an answer. A two-choice roadside encounter is opening."
		"reward":
			return "A cache glints ahead. The current reward choice is opening."
		"key":
			return "The stage key is in hand. Boss-gate access is updating on the current map."
		_:
			return "Applying the next runtime-owned node resolution."


func build_node_resolve_detail_text(node_type: String, pending_node_id: int) -> String:
	var node_read: String = "Node %d." % pending_node_id if pending_node_id >= 0 else "Node read unavailable."
	if node_type.is_empty():
		return "%s Short transition shell only; resolution continues automatically." % node_read
	return "%s Short %s bridge only; resolution continues automatically." % [
		node_read,
		_display_name_for_node_type(node_type).to_lower(),
	]


func build_node_resolve_hint_text(node_type: String) -> String:
	match node_type:
		"key":
			return "Automatic bridge only. Key truth updates first, then flow hands back to the map."
		"event":
			return "Automatic bridge only. The shell reads the roadside encounter and hands off to the dedicated two-choice story flow."
		"combat", "boss", "reward":
			return "Automatic bridge only. The shell reads the node and hands off to the next runtime-owned screen."
		_:
			return "Automatic bridge only. Resolution continues without introducing a new main flow state."


func build_node_icon_texture_path(node_type: String) -> String:
	match node_type:
		"combat":
			return UiAssetPathsScript.ATTACK_ICON_TEXTURE_PATH
		"boss":
			return UiAssetPathsScript.BOSS_ICON_TEXTURE_PATH
		"event":
			return UiAssetPathsScript.EVENT_ICON_TEXTURE_PATH
		"reward":
			return UiAssetPathsScript.REWARD_ICON_TEXTURE_PATH
		"key":
			return UiAssetPathsScript.KEY_ICON_TEXTURE_PATH
		_:
			return UiAssetPathsScript.ROUTE_ICON_TEXTURE_PATH


func _display_name_for_node_type(node_type: String) -> String:
	return String(NODE_DISPLAY_NAMES.get(node_type, node_type.capitalize()))
