# Layer: UI
extends RefCounted
class_name MapDisplayNameHelper

const FAMILY_DISPLAY_NAMES: Dictionary = {
	"start": "Waymark",
	"combat": "Ambush",
	"boss": "Warden",
	"event": "Trail Event",
	"reward": "Cache",
	"key": "Lockstone",
	"rest": "Quiet Clearing",
	"merchant": "Wandering Pedlar",
	"blacksmith": "Travelling Smith",
	"hamlet": "Waypost",
}

const HAMLET_PERSONALITY_DISPLAY_NAMES: Dictionary = {
	"pilgrim": "Pilgrim's Waypost",
	"frontier": "Frontier Waypost",
	"trade": "Trader's Waypost",
}


static func build_family_display_name(family_id: String, hamlet_personality: String = "") -> String:
	var normalized_family_id: String = family_id.strip_edges()
	if normalized_family_id == "hamlet":
		var normalized_personality: String = hamlet_personality.strip_edges()
		if HAMLET_PERSONALITY_DISPLAY_NAMES.has(normalized_personality):
			return String(HAMLET_PERSONALITY_DISPLAY_NAMES.get(normalized_personality, FAMILY_DISPLAY_NAMES["hamlet"]))
	return String(FAMILY_DISPLAY_NAMES.get(normalized_family_id, normalized_family_id.capitalize()))
