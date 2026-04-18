# Layer: RuntimeState
extends RefCounted
class_name SupportInteractionState

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")

const TYPE_REST: String = "rest"
const TYPE_MERCHANT: String = "merchant"
const TYPE_BLACKSMITH: String = "blacksmith"
const TYPE_HAMLET: String = "hamlet"
const LEGACY_TYPE_SIDE_MISSION: String = "side_mission"
const NO_SOURCE_NODE_ID: int = -1
const DEFAULT_SELECTION_SEED: int = 1
const MERCHANT_STOCK_FAMILY: String = "MerchantStocks"
const MERCHANT_STOCK_ID: String = "basic_merchant_stock"
const SIDE_MISSION_FAMILY: String = "SideMissions"
const SIDE_MISSION_DEFAULT_DEFINITION_ID: String = "trail_contract_hunt"
const SIDE_MISSION_STATUS_OFFERED: String = "offered"
const SIDE_MISSION_STATUS_ACCEPTED: String = "accepted"
const SIDE_MISSION_STATUS_COMPLETED: String = "completed"
const SIDE_MISSION_STATUS_CLAIMED: String = "claimed"
const BLACKSMITH_VIEW_MODE_SERVICES: String = "services"
const BLACKSMITH_VIEW_MODE_WEAPON_TARGETS: String = "weapon_targets"
const BLACKSMITH_VIEW_MODE_ARMOR_TARGETS: String = "armor_targets"
const BLACKSMITH_WEAPON_UPGRADE_COST: int = 7
const BLACKSMITH_ARMOR_UPGRADE_COST: int = 5
const BLACKSMITH_REPAIR_COST: int = 4
const BLACKSMITH_TARGET_PAGE_SIZE: int = 2
const REST_HEAL_AMOUNT: int = 10
const REST_HUNGER_DELTA: int = -3
const MISSION_TYPE_HUNT_MARKED_ENEMY: String = "hunt_marked_enemy"
const MISSION_TYPE_DELIVER_SUPPLIES: String = "deliver_supplies"
const MISSION_TYPE_RESCUE_MISSING_SCOUT: String = "rescue_missing_scout"
const MISSION_TYPE_BRING_PROOF: String = "bring_proof"
const HAMLET_PERSONALITY_FRONTIER: String = "frontier"
const HAMLET_PERSONALITY_PILGRIM: String = "pilgrim"
const HAMLET_PERSONALITY_TRADE: String = "trade"
const MERCHANT_STOCK_IDS_BY_STAGE: Dictionary = {
	1: ["basic_merchant_stock", "stage_1_merchant_stock_roadpack", "stage_1_merchant_stock_scout"],
	2: ["stage_2_merchant_stock", "stage_2_merchant_stock_kit", "stage_2_merchant_stock_forgegear"],
	3: ["stage_3_merchant_stock", "stage_3_merchant_stock_bulwark", "stage_3_merchant_stock_convoy"],
}
const SIDE_MISSION_DEFINITION_IDS_BY_STAGE: Dictionary = {
	1: ["trail_contract_hunt", "watchpath_hunt", "ridge_contract_hunt"],
	2: ["deliver_supplies", "carry_forge_parcel", "lantern_scout_recovery"],
	3: ["rescue_missing_scout", "recover_bell_scout", "bring_proof", "ash_barricade_proof"],
}

var support_type: String = ""
var source_node_id: int = NO_SOURCE_NODE_ID
var title_text: String = ""
var summary_text: String = ""
var offers: Array[Dictionary] = []
var blacksmith_view_mode: String = BLACKSMITH_VIEW_MODE_SERVICES
var blacksmith_target_page: int = 0
var mission_definition_id: String = ""
var mission_type: String = MISSION_TYPE_HUNT_MARKED_ENEMY
var mission_status: String = SIDE_MISSION_STATUS_OFFERED
var target_node_id: int = NO_SOURCE_NODE_ID
var target_enemy_definition_id: String = ""
var quest_item_definition_id: String = ""
var reward_offers: Array[Dictionary] = []


static func resolve_hamlet_personality_for_stage(stage_index: int) -> String:
	match max(1, stage_index):
		1:
			return HAMLET_PERSONALITY_PILGRIM
		2:
			return HAMLET_PERSONALITY_FRONTIER
		3:
			return HAMLET_PERSONALITY_TRADE
		_:
			var stage_cycle: PackedStringArray = [
				HAMLET_PERSONALITY_PILGRIM,
				HAMLET_PERSONALITY_FRONTIER,
				HAMLET_PERSONALITY_TRADE,
			]
			return stage_cycle[(max(1, stage_index) - 1) % stage_cycle.size()]


func setup_for_type(
	type_name: String,
	node_id: int = NO_SOURCE_NODE_ID,
	persisted_node_state: Dictionary = {},
	stage_index: int = 1,
	inventory_state: InventoryState = null,
	map_runtime_state: MapRuntimeState = null,
	selection_seed: int = DEFAULT_SELECTION_SEED
) -> void:
	var normalized_stage_index: int = max(1, stage_index)
	support_type = _normalize_support_type(type_name)
	source_node_id = node_id
	blacksmith_view_mode = BLACKSMITH_VIEW_MODE_SERVICES
	blacksmith_target_page = 0
	mission_definition_id = ""
	mission_type = MISSION_TYPE_HUNT_MARKED_ENEMY
	mission_status = SIDE_MISSION_STATUS_OFFERED
	target_node_id = NO_SOURCE_NODE_ID
	target_enemy_definition_id = ""
	quest_item_definition_id = ""
	reward_offers = []

	match support_type:
		TYPE_REST:
			title_text = "Campfire"
			summary_text = "Recover %d HP, spend %d hunger, or walk away before pushing back onto the trail." % [
				REST_HEAL_AMOUNT,
				abs(REST_HUNGER_DELTA),
			]
			offers = _build_rest_offers()
		TYPE_BLACKSMITH:
			_show_blacksmith_services(inventory_state)
		TYPE_MERCHANT:
			title_text = "Road Merchant"
			summary_text = "Buy what you need before the wagon rolls on."
			offers = _build_merchant_offers(normalized_stage_index, selection_seed, node_id)
		TYPE_HAMLET:
			_setup_hamlet(persisted_node_state, normalized_stage_index, map_runtime_state, selection_seed)
		_:
			title_text = "Support Interaction"
			summary_text = ""
			offers = []

	if support_type != TYPE_HAMLET:
		_apply_persisted_node_state(persisted_node_state)


func get_offer_by_id(offer_id: String) -> Dictionary:
	for offer in offers:
		if String(offer.get("offer_id", "")) == offer_id:
			return offer.duplicate(true)
	return {}


func mark_offer_unavailable(offer_id: String) -> void:
	for index in range(offers.size()):
		if String(offers[index].get("offer_id", "")) != offer_id:
			continue
		var offer: Dictionary = offers[index]
		offer["available"] = false
		offers[index] = offer
		return


func has_available_offers() -> bool:
	for offer in offers:
		if bool(offer.get("available", true)):
			return true
	return false


func to_save_dict() -> Dictionary:
	return {
		"support_type": support_type,
		"source_node_id": source_node_id,
		"title_text": title_text,
		"summary_text": summary_text,
		"offers": offers.duplicate(true),
		"blacksmith_view_mode": blacksmith_view_mode,
		"blacksmith_target_page": blacksmith_target_page,
		"mission_definition_id": mission_definition_id,
		"mission_type": mission_type,
		"mission_status": mission_status,
		"target_node_id": target_node_id,
		"target_enemy_definition_id": target_enemy_definition_id,
		"quest_item_definition_id": quest_item_definition_id,
		"reward_offers": reward_offers.duplicate(true),
	}


func load_from_save_dict(save_data: Dictionary) -> void:
	support_type = _normalize_support_type(String(save_data.get("support_type", "")))
	source_node_id = int(save_data.get("source_node_id", NO_SOURCE_NODE_ID))
	title_text = String(save_data.get("title_text", ""))
	summary_text = String(save_data.get("summary_text", ""))
	offers = _extract_offer_array(save_data.get("offers", []))
	_normalize_legacy_rest_offers()
	blacksmith_view_mode = String(save_data.get("blacksmith_view_mode", BLACKSMITH_VIEW_MODE_SERVICES))
	blacksmith_target_page = max(0, int(save_data.get("blacksmith_target_page", 0)))
	mission_definition_id = String(save_data.get("mission_definition_id", ""))
	mission_type = _normalize_mission_type(String(save_data.get("mission_type", MISSION_TYPE_HUNT_MARKED_ENEMY)))
	mission_status = String(save_data.get("mission_status", SIDE_MISSION_STATUS_OFFERED))
	target_node_id = int(save_data.get("target_node_id", NO_SOURCE_NODE_ID))
	target_enemy_definition_id = String(save_data.get("target_enemy_definition_id", ""))
	quest_item_definition_id = String(save_data.get("quest_item_definition_id", ""))
	reward_offers = _extract_offer_array(save_data.get("reward_offers", []))


func build_persisted_node_state() -> Dictionary:
	if support_type == TYPE_HAMLET:
		return {
			"support_type": support_type,
			"mission_definition_id": mission_definition_id,
			"mission_type": mission_type,
			"mission_status": mission_status,
			"target_node_id": target_node_id,
			"target_enemy_definition_id": target_enemy_definition_id,
			"quest_item_definition_id": quest_item_definition_id,
			"reward_offers": reward_offers.duplicate(true),
		}
	return {
		"support_type": support_type,
		"unavailable_offer_ids": _collect_unavailable_offer_ids(),
	}


func is_blacksmith_target_selection_active() -> bool:
	return support_type == TYPE_BLACKSMITH and blacksmith_view_mode != BLACKSMITH_VIEW_MODE_SERVICES


func return_to_blacksmith_services(inventory_state: InventoryState = null) -> void:
	if support_type != TYPE_BLACKSMITH:
		return
	_show_blacksmith_services(inventory_state)


func open_blacksmith_target_selection(target_mode: String, inventory_state: InventoryState) -> void:
	if support_type != TYPE_BLACKSMITH:
		return
	blacksmith_target_page = 0
	match target_mode:
		BLACKSMITH_VIEW_MODE_WEAPON_TARGETS:
			_show_blacksmith_targets(InventoryState.INVENTORY_FAMILY_WEAPON, inventory_state)
		BLACKSMITH_VIEW_MODE_ARMOR_TARGETS:
			_show_blacksmith_targets(InventoryState.INVENTORY_FAMILY_ARMOR, inventory_state)
		_:
			_show_blacksmith_services(inventory_state)


func advance_blacksmith_target_page(inventory_state: InventoryState) -> void:
	if not is_blacksmith_target_selection_active():
		return
	var target_family: String = _resolve_blacksmith_target_family()
	if target_family.is_empty():
		_show_blacksmith_services(inventory_state)
		return
	var candidates: Array[Dictionary] = _collect_blacksmith_target_slots(target_family, inventory_state)
	var total_pages: int = _resolve_blacksmith_total_pages(candidates)
	if total_pages <= 1:
		return
	blacksmith_target_page = (blacksmith_target_page + 1) % total_pages
	_show_blacksmith_targets(target_family, inventory_state)


func _extract_offer_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result

	for entry in value:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		result.append((entry as Dictionary).duplicate(true))
	return result


func _build_rest_offers() -> Array[Dictionary]:
	return [
		{
			"offer_id": "rest_once",
			"label": "Rest by the Fire (+%d HP, %d Hunger)" % [REST_HEAL_AMOUNT, REST_HUNGER_DELTA],
			"effect_type": "rest",
			"heal_amount": REST_HEAL_AMOUNT,
			"hunger_delta": REST_HUNGER_DELTA,
			"available": true,
		},
	]


func _setup_hamlet(
	persisted_node_state: Dictionary,
	stage_index: int,
	map_runtime_state: MapRuntimeState = null,
	selection_seed: int = DEFAULT_SELECTION_SEED
) -> void:
	var loader: ContentLoader = ContentLoaderScript.new()
	var hamlet_personality: String = resolve_hamlet_personality_for_stage(stage_index)
	mission_definition_id = String(
		persisted_node_state.get(
			"mission_definition_id",
			_resolve_default_side_mission_definition_id(stage_index, selection_seed, source_node_id)
		)
	).strip_edges()
	if mission_definition_id.is_empty():
		mission_definition_id = _resolve_default_side_mission_definition_id(stage_index, selection_seed, source_node_id)
	mission_status = String(persisted_node_state.get("mission_status", SIDE_MISSION_STATUS_OFFERED))
	if mission_status not in [
		SIDE_MISSION_STATUS_OFFERED,
		SIDE_MISSION_STATUS_ACCEPTED,
		SIDE_MISSION_STATUS_COMPLETED,
		SIDE_MISSION_STATUS_CLAIMED,
	]:
		mission_status = SIDE_MISSION_STATUS_OFFERED
	target_node_id = int(persisted_node_state.get("target_node_id", NO_SOURCE_NODE_ID))
	target_enemy_definition_id = String(persisted_node_state.get("target_enemy_definition_id", "")).strip_edges()
	quest_item_definition_id = String(persisted_node_state.get("quest_item_definition_id", "")).strip_edges()
	reward_offers = _extract_offer_array(persisted_node_state.get("reward_offers", []))

	var mission_definition: Dictionary = loader.load_definition(SIDE_MISSION_FAMILY, mission_definition_id)
	var display: Dictionary = mission_definition.get("display", {})
	var rules: Dictionary = mission_definition.get("rules", {})
	mission_type = _normalize_mission_type(String(persisted_node_state.get("mission_type", rules.get("mission_type", MISSION_TYPE_HUNT_MARKED_ENEMY))))
	if quest_item_definition_id.is_empty():
		quest_item_definition_id = String(rules.get("quest_item_definition_id", "")).strip_edges()
	title_text = String(display.get("name", "Hamlet Request"))

	match mission_status:
		SIDE_MISSION_STATUS_OFFERED:
			var has_target_candidates: bool = true
			if map_runtime_state != null:
				# Keep the hamlet accept-state read aligned with the runtime target-family rules.
				var target_families: PackedStringArray = _resolve_hamlet_target_families(rules, mission_type)
				has_target_candidates = not map_runtime_state.list_eligible_side_quest_target_node_ids(source_node_id, target_families).is_empty()
			summary_text = _build_hamlet_personality_summary(
				hamlet_personality,
				String(rules.get("briefing_text", "Take the contract and hunt the marked enemy."))
			)
			offers = [
				{
					"offer_id": "accept_side_mission",
					"label": String(rules.get("accept_label", "Take the Contract")) if has_target_candidates else "%s\nNo Mark" % String(rules.get("accept_label", "Take the Contract")),
					"effect_type": "accept_side_mission",
					"available": has_target_candidates,
					"unavailable_reason": "" if has_target_candidates else "no_target",
				},
			]
		SIDE_MISSION_STATUS_ACCEPTED:
			summary_text = _build_hamlet_personality_summary(
				hamlet_personality,
				String(rules.get("accepted_text", "The mark is on the map. Kill the target, then return here."))
			)
			offers = [
				{
					"offer_id": "side_mission_active",
					"label": String(rules.get("reminder_label", "Contract Active")),
					"effect_type": "side_mission_info",
					"available": false,
					"unavailable_reason": "contract_active",
				},
			]
		SIDE_MISSION_STATUS_COMPLETED:
			summary_text = _build_hamlet_personality_summary(
				hamlet_personality,
				String(rules.get("completed_text", "The target is down. Claim one payment item."))
			)
			offers = _build_hamlet_reward_offers(loader, reward_offers)
		_:
			summary_text = _build_hamlet_personality_summary(
				hamlet_personality,
				String(rules.get("claimed_text", "The contract board hangs empty."))
			)
			offers = [
				{
					"offer_id": "side_mission_claimed",
					"label": String(rules.get("claimed_label", "Contract Settled")),
					"effect_type": "side_mission_info",
					"available": false,
					"unavailable_reason": "contract_claimed",
				},
			]


func _build_hamlet_reward_offers(loader: ContentLoader, authored_offers: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for authored_offer in authored_offers:
		var effect_type: String = String(authored_offer.get("effect_type", "")).strip_edges()
		if effect_type.is_empty():
			effect_type = "grant_item"
		match effect_type:
			"grant_gold":
				var gold_amount: int = max(1, int(authored_offer.get("amount", 0)))
				result.append({
					"offer_id": String(authored_offer.get("offer_id", "claim_gold_%d" % gold_amount)),
					"label": String(authored_offer.get("label", "Claim %d Gold" % gold_amount)),
					"effect_type": "grant_gold",
					"amount": gold_amount,
					"available": bool(authored_offer.get("available", true)),
				})
			"grant_item", "claim_side_mission_reward":
				var inventory_family: String = String(authored_offer.get("inventory_family", "")).strip_edges()
				var definition_id: String = String(authored_offer.get("definition_id", "")).strip_edges()
				var definition_family: String = _definition_family_for_inventory_family(inventory_family)
				if definition_family.is_empty() or definition_id.is_empty():
					continue
				var definition: Dictionary = loader.load_definition(definition_family, definition_id)
				var display_name: String = String(definition.get("display", {}).get("name", definition_id))
				var reward_offer: Dictionary = {
					"offer_id": String(authored_offer.get("offer_id", "claim_%s" % definition_id)),
					"label": String(authored_offer.get("label", _build_hamlet_reward_label(inventory_family, display_name, int(authored_offer.get("amount", 1))))),
					"effect_type": "claim_side_mission_reward",
					"inventory_family": inventory_family,
					"definition_id": definition_id,
					"available": bool(authored_offer.get("available", true)),
				}
				if inventory_family == InventoryState.INVENTORY_FAMILY_CONSUMABLE:
					reward_offer["amount"] = max(1, int(authored_offer.get("amount", 1)))
				result.append(reward_offer)
	return result


func _normalize_legacy_rest_offers() -> void:
	if support_type == TYPE_REST:
		title_text = "Campfire"
		summary_text = "Recover %d HP, spend %d hunger, or walk away before pushing back onto the trail." % [
			REST_HEAL_AMOUNT,
			abs(REST_HUNGER_DELTA),
		]
	for index in range(offers.size()):
		var offer: Dictionary = offers[index]
		if String(offer.get("effect_type", "")) != "rest":
			continue
		offer["label"] = "Rest by the Fire (+%d HP, %d Hunger)" % [REST_HEAL_AMOUNT, REST_HUNGER_DELTA]
		offer["heal_amount"] = REST_HEAL_AMOUNT
		offer["hunger_delta"] = REST_HUNGER_DELTA
		offers[index] = offer


func _normalize_support_type(type_name: String) -> String:
	var normalized_type: String = String(type_name).strip_edges()
	if normalized_type == LEGACY_TYPE_SIDE_MISSION:
		return TYPE_HAMLET
	return normalized_type


func _normalize_mission_type(type_name: String) -> String:
	var normalized_type: String = String(type_name).strip_edges()
	if normalized_type in [
		MISSION_TYPE_HUNT_MARKED_ENEMY,
		MISSION_TYPE_DELIVER_SUPPLIES,
		MISSION_TYPE_RESCUE_MISSING_SCOUT,
		MISSION_TYPE_BRING_PROOF,
	]:
		return normalized_type
	return MISSION_TYPE_HUNT_MARKED_ENEMY


func _resolve_hamlet_target_families(rules: Dictionary, resolved_mission_type: String) -> PackedStringArray:
	var configured_target_families: Variant = rules.get("target_families", [])
	var target_families: PackedStringArray = PackedStringArray()
	if typeof(configured_target_families) == TYPE_ARRAY:
		for family_variant in configured_target_families:
			var family_name: String = String(family_variant).strip_edges()
			if family_name.is_empty() or target_families.has(family_name):
				continue
			target_families.append(family_name)
	if not target_families.is_empty():
		return target_families

	match resolved_mission_type:
		MISSION_TYPE_DELIVER_SUPPLIES:
			return PackedStringArray(["event", "reward", "rest", "merchant", "blacksmith"])
		MISSION_TYPE_RESCUE_MISSING_SCOUT, MISSION_TYPE_BRING_PROOF:
			return PackedStringArray(["combat", "event", "reward"])
		_:
			return PackedStringArray(["combat"])


func _show_blacksmith_services(inventory_state: InventoryState) -> void:
	blacksmith_view_mode = BLACKSMITH_VIEW_MODE_SERVICES
	blacksmith_target_page = 0
	title_text = "Forge Tent"
	summary_text = "Pick one service: temper a carried weapon, reinforce carried armor, or repair the active weapon."
	offers = _build_blacksmith_service_offers(inventory_state)


func _show_blacksmith_targets(target_family: String, inventory_state: InventoryState) -> void:
	var candidates: Array[Dictionary] = _collect_blacksmith_target_slots(target_family, inventory_state)
	if candidates.is_empty():
		_show_blacksmith_services(inventory_state)
		return

	var total_pages: int = _resolve_blacksmith_total_pages(candidates)
	blacksmith_target_page = clamp(blacksmith_target_page, 0, max(0, total_pages - 1))
	match target_family:
		InventoryState.INVENTORY_FAMILY_WEAPON:
			blacksmith_view_mode = BLACKSMITH_VIEW_MODE_WEAPON_TARGETS
			title_text = "Temper Weapon"
			summary_text = "Choose a carried weapon. Tempering adds +1 attack to that item."
		InventoryState.INVENTORY_FAMILY_ARMOR:
			blacksmith_view_mode = BLACKSMITH_VIEW_MODE_ARMOR_TARGETS
			title_text = "Reinforce Armor"
			summary_text = "Choose a carried armor piece. Reinforcing adds +1 defense to that item."
		_:
			_show_blacksmith_services(inventory_state)
			return
	offers = _build_blacksmith_target_offers(candidates, inventory_state)


func _build_blacksmith_service_offers(inventory_state: InventoryState = null) -> Array[Dictionary]:
	return [
		_build_blacksmith_service_offer(
			"open_weapon_targets",
			"Temper Weapon (+1 ATK, %d Gold)" % BLACKSMITH_WEAPON_UPGRADE_COST,
			"open_blacksmith_weapon_targets",
			_has_blacksmith_target_family(InventoryState.INVENTORY_FAMILY_WEAPON, inventory_state)
		),
		_build_blacksmith_service_offer(
			"open_armor_targets",
			"Reinforce Armor (+1 DEF, %d Gold)" % BLACKSMITH_ARMOR_UPGRADE_COST,
			"open_blacksmith_armor_targets",
			_has_blacksmith_target_family(InventoryState.INVENTORY_FAMILY_ARMOR, inventory_state)
		),
		{
			"offer_id": "repair_active_weapon",
			"label": "Repair Active Weapon (%d Gold)" % BLACKSMITH_REPAIR_COST,
			"effect_type": "repair_weapon",
			"cost_gold": BLACKSMITH_REPAIR_COST,
			"available": true,
		},
	]


func _build_blacksmith_service_offer(offer_id: String, label_text: String, effect_type: String, is_available: bool) -> Dictionary:
	return {
		"offer_id": offer_id,
		"label": label_text if is_available else "%s\nNo Target" % label_text,
		"effect_type": effect_type,
		"available": is_available,
		"unavailable_reason": "" if is_available else "no_target",
	}


func _build_blacksmith_target_offers(candidates: Array[Dictionary], inventory_state: InventoryState) -> Array[Dictionary]:
	var target_family: String = _resolve_blacksmith_target_family()
	var cost_gold: int = _resolve_blacksmith_target_cost()
	var page_start: int = blacksmith_target_page * BLACKSMITH_TARGET_PAGE_SIZE
	var page_end: int = min(page_start + BLACKSMITH_TARGET_PAGE_SIZE, candidates.size())
	var result: Array[Dictionary] = []

	for index in range(page_start, page_end):
		var slot: Dictionary = candidates[index]
		result.append(_build_blacksmith_target_offer(slot, target_family, inventory_state, cost_gold))

	if _resolve_blacksmith_total_pages(candidates) > 1:
		result.append({
			"offer_id": "cycle_blacksmith_page",
			"label": "More Targets",
			"effect_type": "cycle_blacksmith_page",
			"available": true,
		})

	return result


func _build_blacksmith_target_offer(
	slot: Dictionary,
	target_family: String,
	inventory_state: InventoryState,
	cost_gold: int
) -> Dictionary:
	var loader: ContentLoader = ContentLoaderScript.new()
	var definition_id: String = String(slot.get("definition_id", ""))
	var family_name: String = "Weapons" if target_family == InventoryState.INVENTORY_FAMILY_WEAPON else "Armors"
	var definition: Dictionary = loader.load_definition(family_name, definition_id)
	var display_name: String = String(definition.get("display", {}).get("name", definition_id))
	var current_upgrade_level: int = max(0, int(slot.get("upgrade_level", 0)))
	var next_upgrade_level: int = current_upgrade_level + 1
	var active_slot_id: int = -1
	if inventory_state != null:
		if target_family == InventoryState.INVENTORY_FAMILY_WEAPON:
			active_slot_id = int(inventory_state.active_weapon_slot_id)
		else:
			active_slot_id = int(inventory_state.active_armor_slot_id)
	var is_active: bool = int(slot.get("slot_id", -1)) == active_slot_id
	var step_text: String = _format_blacksmith_upgrade_step_text(display_name, current_upgrade_level, next_upgrade_level)
	return {
		"offer_id": "upgrade_%s_slot_%d" % [target_family, int(slot.get("slot_id", -1))],
		"label": "%s%s (%d Gold)" % [step_text, " [ACTIVE]" if is_active else "", cost_gold],
		"effect_type": "upgrade_%s" % target_family,
		"cost_gold": cost_gold,
		"target_slot_id": int(slot.get("slot_id", -1)),
		"definition_id": definition_id,
		"available": true,
	}


func _collect_blacksmith_target_slots(target_family: String, inventory_state: InventoryState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if inventory_state == null:
		return result
	for slot in inventory_state.inventory_slots:
		if String(slot.get("inventory_family", "")) != target_family:
			continue
		result.append(slot.duplicate(true))
	return result


func _has_blacksmith_target_family(target_family: String, inventory_state: InventoryState) -> bool:
	return not _collect_blacksmith_target_slots(target_family, inventory_state).is_empty()


func _resolve_blacksmith_target_family() -> String:
	match blacksmith_view_mode:
		BLACKSMITH_VIEW_MODE_WEAPON_TARGETS:
			return InventoryState.INVENTORY_FAMILY_WEAPON
		BLACKSMITH_VIEW_MODE_ARMOR_TARGETS:
			return InventoryState.INVENTORY_FAMILY_ARMOR
		_:
			return ""


func _resolve_blacksmith_target_cost() -> int:
	match blacksmith_view_mode:
		BLACKSMITH_VIEW_MODE_WEAPON_TARGETS:
			return BLACKSMITH_WEAPON_UPGRADE_COST
		BLACKSMITH_VIEW_MODE_ARMOR_TARGETS:
			return BLACKSMITH_ARMOR_UPGRADE_COST
		_:
			return 0


func _resolve_blacksmith_total_pages(candidates: Array[Dictionary]) -> int:
	if candidates.is_empty():
		return 0
	return int(ceili(float(candidates.size()) / float(BLACKSMITH_TARGET_PAGE_SIZE)))


func _format_blacksmith_upgrade_step_text(display_name: String, current_upgrade_level: int, next_upgrade_level: int) -> String:
	var current_name: String = display_name if current_upgrade_level <= 0 else "%s +%d" % [display_name, current_upgrade_level]
	var next_name: String = "%s +%d" % [display_name, next_upgrade_level]
	return "%s -> %s" % [current_name, next_name]


func _build_merchant_offers(
	stage_index: int = 1,
	selection_seed: int = DEFAULT_SELECTION_SEED,
	node_id: int = NO_SOURCE_NODE_ID
) -> Array[Dictionary]:
	var loader: ContentLoader = ContentLoaderScript.new()
	var result: Array[Dictionary] = []
	for stock_entry in _load_merchant_stock_entries(loader, stage_index, selection_seed, node_id):
		var definition_id: String = String(stock_entry.get("definition_id", ""))
		var item_definition: Dictionary = loader.load_definition(_family_for_merchant_entry(stock_entry), definition_id)
		var label: String = _build_merchant_offer_label(stock_entry, item_definition)
		var offer: Dictionary = stock_entry.duplicate(true)
		offer["label"] = label
		offer["available"] = true
		result.append(offer)
	return result


func _load_merchant_stock_entries(
	loader: ContentLoader,
	stage_index: int = 1,
	selection_seed: int = DEFAULT_SELECTION_SEED,
	node_id: int = NO_SOURCE_NODE_ID
) -> Array[Dictionary]:
	var merchant_stock_definition: Dictionary = loader.load_definition(
		MERCHANT_STOCK_FAMILY,
		_resolve_merchant_stock_id(stage_index, selection_seed, node_id)
	)
	var rules: Dictionary = merchant_stock_definition.get("rules", {})
	return _extract_offer_array(rules.get("stock", []))


func _resolve_merchant_stock_id(
	stage_index: int,
	selection_seed: int = DEFAULT_SELECTION_SEED,
	node_id: int = NO_SOURCE_NODE_ID
) -> String:
	return _resolve_seeded_stage_pool_id(
		MERCHANT_STOCK_IDS_BY_STAGE,
		stage_index,
		selection_seed,
		node_id,
		"merchant_stock",
		MERCHANT_STOCK_ID
	)


func _family_for_merchant_entry(stock_entry: Dictionary) -> String:
	var effect_type: String = String(stock_entry.get("effect_type", ""))
	match effect_type:
		"buy_consumable":
			return "Consumables"
		"buy_weapon":
			return "Weapons"
		"buy_shield":
			return "Shields"
		"buy_armor":
			return "Armors"
		"buy_belt":
			return "Belts"
		"buy_passive_item":
			return "PassiveItems"
		_:
			return ""


func _build_merchant_offer_label(stock_entry: Dictionary, item_definition: Dictionary) -> String:
	var definition_id: String = String(stock_entry.get("definition_id", ""))
	var display: Dictionary = item_definition.get("display", {})
	var item_name: String = String(display.get("name", definition_id))
	var effect_type: String = String(stock_entry.get("effect_type", ""))
	var amount: int = int(stock_entry.get("amount", 1))
	var cost_gold: int = int(stock_entry.get("cost_gold", 0))
	match effect_type:
		"buy_consumable":
			return "Buy %s x%d (%d Gold)" % [item_name, amount, cost_gold]
		"buy_weapon", "buy_shield", "buy_armor", "buy_belt", "buy_passive_item":
			return "Buy %s (%d Gold)" % [item_name, cost_gold]
		_:
			return String(stock_entry.get("offer_id", definition_id))


func _resolve_default_side_mission_definition_id(
	stage_index: int,
	selection_seed: int = DEFAULT_SELECTION_SEED,
	node_id: int = NO_SOURCE_NODE_ID
) -> String:
	var normalized_stage_index: int = max(1, stage_index)
	var stage_pool_ids: PackedStringArray = _extract_stage_pool_ids(
		SIDE_MISSION_DEFINITION_IDS_BY_STAGE.get(normalized_stage_index, [])
	)
	if stage_pool_ids.is_empty():
		stage_pool_ids.append(SIDE_MISSION_DEFAULT_DEFINITION_ID)
	if selection_seed <= DEFAULT_SELECTION_SEED or stage_pool_ids.size() == 1:
		return String(stage_pool_ids[0])
	var loader: ContentLoader = ContentLoaderScript.new()
	var weighted_pool_ids: Array[String] = _build_hamlet_weighted_definition_ids(
		loader,
		stage_pool_ids,
		resolve_hamlet_personality_for_stage(normalized_stage_index)
	)
	if weighted_pool_ids.is_empty():
		for definition_id in stage_pool_ids:
			weighted_pool_ids.append(definition_id)
	var selection_index: int = _build_seeded_stage_pool_index(
		selection_seed,
		normalized_stage_index,
		node_id,
		"hamlet_request",
		weighted_pool_ids.size()
	)
	return String(weighted_pool_ids[selection_index])


func _resolve_seeded_stage_pool_id(
	stage_pool_ids: Dictionary,
	stage_index: int,
	selection_seed: int,
	node_id: int,
	lane_name: String,
	fallback_id: String
) -> String:
	var normalized_stage_index: int = max(1, stage_index)
	var pool_ids: PackedStringArray = _extract_stage_pool_ids(stage_pool_ids.get(normalized_stage_index, []))
	if pool_ids.is_empty():
		pool_ids.append(fallback_id)
	if selection_seed <= DEFAULT_SELECTION_SEED or pool_ids.size() == 1:
		return String(pool_ids[0])
	var selection_index: int = _build_seeded_stage_pool_index(
		selection_seed,
		normalized_stage_index,
		node_id,
		lane_name,
		pool_ids.size()
	)
	return String(pool_ids[selection_index])


func _extract_stage_pool_ids(stage_pool_value: Variant) -> PackedStringArray:
	var pool_ids: PackedStringArray = PackedStringArray()
	match typeof(stage_pool_value):
		TYPE_STRING:
			var single_id: String = String(stage_pool_value).strip_edges()
			if not single_id.is_empty():
				pool_ids.append(single_id)
		TYPE_ARRAY:
			for id_variant in stage_pool_value:
				var definition_id: String = String(id_variant).strip_edges()
				if definition_id.is_empty() or pool_ids.has(definition_id):
					continue
				pool_ids.append(definition_id)
	return pool_ids


func _build_hamlet_weighted_definition_ids(
	loader: ContentLoader,
	stage_pool_ids: PackedStringArray,
	hamlet_personality: String
) -> Array[String]:
	var weighted_pool_ids: Array[String] = []
	for definition_id in stage_pool_ids:
		var mission_definition: Dictionary = loader.load_definition(SIDE_MISSION_FAMILY, String(definition_id))
		var repeat_count: int = _resolve_hamlet_pool_weight(mission_definition, hamlet_personality)
		for _copy_index in range(max(1, repeat_count)):
			weighted_pool_ids.append(String(definition_id))
	return weighted_pool_ids


func _resolve_hamlet_pool_weight(mission_definition: Dictionary, hamlet_personality: String) -> int:
	var personality_score: int = _score_hamlet_mission_for_personality(mission_definition, hamlet_personality)
	if personality_score >= 7:
		return 3
	if personality_score >= 4:
		return 2
	return 1


func _score_hamlet_mission_for_personality(mission_definition: Dictionary, hamlet_personality: String) -> int:
	if mission_definition.is_empty():
		return 0
	var rules: Dictionary = mission_definition.get("rules", {})
	var mission_type: String = _normalize_mission_type(String(rules.get("mission_type", MISSION_TYPE_HUNT_MARKED_ENEMY)))
	var tag_hits: Dictionary = {}
	var tags_variant: Variant = mission_definition.get("tags", [])
	if typeof(tags_variant) == TYPE_ARRAY:
		for tag_variant in tags_variant:
			var tag_name: String = String(tag_variant).strip_edges()
			if not tag_name.is_empty():
				tag_hits[tag_name] = true

	var score: int = 0
	match hamlet_personality:
		HAMLET_PERSONALITY_FRONTIER:
			if mission_type == MISSION_TYPE_HUNT_MARKED_ENEMY:
				score += 4
			elif mission_type == MISSION_TYPE_BRING_PROOF:
				score += 3
			if tag_hits.has("hunt"):
				score += 2
			if tag_hits.has("proof"):
				score += 1
		HAMLET_PERSONALITY_PILGRIM:
			if mission_type == MISSION_TYPE_DELIVER_SUPPLIES:
				score += 4
			elif mission_type == MISSION_TYPE_RESCUE_MISSING_SCOUT:
				score += 3
			if tag_hits.has("delivery"):
				score += 2
			if tag_hits.has("rescue"):
				score += 2
		HAMLET_PERSONALITY_TRADE:
			if mission_type == MISSION_TYPE_BRING_PROOF:
				score += 3
			elif mission_type == MISSION_TYPE_DELIVER_SUPPLIES:
				score += 2
			if tag_hits.has("proof"):
				score += 2
			if tag_hits.has("delivery"):
				score += 2

	var reward_score: int = 0
	var reward_pool_variant: Variant = rules.get("reward_pool", [])
	if typeof(reward_pool_variant) == TYPE_ARRAY:
		for reward_variant in reward_pool_variant:
			if typeof(reward_variant) != TYPE_DICTIONARY:
				continue
			reward_score += _score_hamlet_reward_offer_for_personality(reward_variant, hamlet_personality)
	return score + min(4, reward_score)


func _score_hamlet_reward_offer_for_personality(reward_offer: Dictionary, hamlet_personality: String) -> int:
	var effect_type: String = String(reward_offer.get("effect_type", "grant_item")).strip_edges()
	if effect_type == "grant_gold":
		match hamlet_personality:
			HAMLET_PERSONALITY_FRONTIER, HAMLET_PERSONALITY_PILGRIM:
				return 1
			HAMLET_PERSONALITY_TRADE:
				return 2
			_:
				return 0

	var inventory_family: String = String(reward_offer.get("inventory_family", "")).strip_edges()
	match hamlet_personality:
		HAMLET_PERSONALITY_FRONTIER:
			if inventory_family == InventoryState.INVENTORY_FAMILY_WEAPON:
				return 2
			if inventory_family == InventoryState.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
				return 2
			if inventory_family == InventoryState.INVENTORY_FAMILY_ARMOR:
				return 1
		HAMLET_PERSONALITY_PILGRIM:
			if inventory_family == InventoryState.INVENTORY_FAMILY_SHIELD:
				return 2
			if inventory_family == InventoryState.INVENTORY_FAMILY_CONSUMABLE:
				return 2
			if inventory_family == InventoryState.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
				return 1
			if inventory_family == InventoryState.INVENTORY_FAMILY_ARMOR:
				return 1
		HAMLET_PERSONALITY_TRADE:
			if inventory_family == InventoryState.INVENTORY_FAMILY_BELT:
				return 2
			if inventory_family == InventoryState.INVENTORY_FAMILY_PASSIVE:
				return 2
			if inventory_family == InventoryState.INVENTORY_FAMILY_CONSUMABLE:
				return 1
	return 0


func _build_hamlet_personality_summary(hamlet_personality: String, base_summary_text: String) -> String:
	var personality_line: String = ""
	match hamlet_personality:
		HAMLET_PERSONALITY_FRONTIER:
			personality_line = "Frontier board. Hard contracts and rougher pay."
		HAMLET_PERSONALITY_PILGRIM:
			personality_line = "Pilgrim board. Safer roadwork and survival pay."
		HAMLET_PERSONALITY_TRADE:
			personality_line = "Trade board. Practical contracts and utility pay."
	if base_summary_text.strip_edges().is_empty():
		return personality_line
	if personality_line.is_empty():
		return base_summary_text
	return "%s\n%s" % [personality_line, base_summary_text]


func _build_seeded_stage_pool_index(
	selection_seed: int,
	stage_index: int,
	node_id: int,
	lane_name: String,
	pool_size: int
) -> int:
	if pool_size <= 1:
		return 0
	var accumulator: int = 216613626
	var raw_seed: String = "%d|%s|stage:%d|node:%d" % [selection_seed, lane_name, stage_index, node_id]
	for byte in raw_seed.to_utf8_buffer():
		accumulator = abs(int((accumulator ^ int(byte)) * 16777619))
	if accumulator == 0:
		accumulator = 1
	return int(accumulator % pool_size)


func _definition_family_for_inventory_family(inventory_family: String) -> String:
	match inventory_family:
		InventoryState.INVENTORY_FAMILY_WEAPON:
			return "Weapons"
		InventoryState.INVENTORY_FAMILY_SHIELD:
			return "Shields"
		InventoryState.INVENTORY_FAMILY_ARMOR:
			return "Armors"
		InventoryState.INVENTORY_FAMILY_BELT:
			return "Belts"
		InventoryState.INVENTORY_FAMILY_CONSUMABLE:
			return "Consumables"
		InventoryState.INVENTORY_FAMILY_PASSIVE:
			return "PassiveItems"
		InventoryState.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
			return "ShieldAttachments"
		InventoryState.INVENTORY_FAMILY_QUEST_ITEM:
			return "QuestItems"
		_:
			return ""


func _build_hamlet_reward_label(inventory_family: String, display_name: String, amount: int) -> String:
	match inventory_family:
		InventoryState.INVENTORY_FAMILY_CONSUMABLE:
			return "Claim %s x%d" % [display_name, max(1, amount)]
		_:
			return "Claim %s" % display_name


func _apply_persisted_node_state(persisted_node_state: Dictionary) -> void:
	var unavailable_ids_variant: Variant = persisted_node_state.get("unavailable_offer_ids", [])
	if typeof(unavailable_ids_variant) != TYPE_ARRAY:
		return

	for unavailable_offer_id in unavailable_ids_variant:
		mark_offer_unavailable(String(unavailable_offer_id))


func _collect_unavailable_offer_ids() -> Array[String]:
	var unavailable_offer_ids: Array[String] = []
	for offer in offers:
		if bool(offer.get("available", true)):
			continue
		var offer_id: String = String(offer.get("offer_id", ""))
		if offer_id.is_empty():
			continue
		unavailable_offer_ids.append(offer_id)
	return unavailable_offer_ids
