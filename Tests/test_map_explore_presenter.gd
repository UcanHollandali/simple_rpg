# Layer: Tests
extends SceneTree
class_name TestMapExplorePresenter

const MapExplorePresenterScript = preload("res://Game/UI/map_explore_presenter.gd")


func _init() -> void:
	test_map_presenter_builds_runtime_graph_labels()
	print("test_map_explore_presenter: all assertions passed")
	quit()


func test_map_presenter_builds_runtime_graph_labels() -> void:
	var presenter: RefCounted = MapExplorePresenterScript.new()
	var run_state: RunState = RunState.new()
	run_state.reset_for_new_run()
	run_state.stage_index = 2
	run_state.player_hp = 48
	run_state.hunger = 11
	run_state.gold = 17
	run_state.weapon_instance["current_durability"] = 9
	run_state.map_runtime_state.move_to_node(1)
	run_state.map_runtime_state.mark_node_resolved(1)

	assert(
		presenter.call("build_title_text", run_state) == "Stage 2 Route",
		"Expected map presenter title to reflect the current stage."
	)
	assert(
		String(presenter.call("build_progress_text", run_state)).contains("Node 1"),
		"Expected map presenter progress text to reflect the stable current node id."
	)
	assert(
		presenter.call("build_run_status_text", run_state) == "HP 48 | Hunger 11 | Gold 17 | Iron Sword (9)",
		"Expected map presenter to summarize the active run snapshot."
	)
	assert(
		String(presenter.call("build_node_family_text")).contains("key"),
		"Expected map presenter to expose the full node family list including the stage key."
	)
	assert(
		String(presenter.call("build_node_family_text")).contains("event"),
		"Expected map presenter to expose the event node family in the route legend."
	)
	assert(
		String(presenter.call("build_map_shell_note_text")).contains("cluster"),
		"Expected map presenter to acknowledge the runtime-owned key and boss-gate slice."
	)
	assert(
		String(presenter.call("build_state_legend_text")).contains("SPENT"),
		"Expected the state legend read to stay presenter-owned."
	)
	assert(
		String(presenter.call("build_cluster_read_text", run_state)).contains("Seen ahead: Reward"),
		"Expected the map presenter to summarize discovered pockets beyond the immediate adjacent shell."
	)
	assert(
		presenter.call("build_current_anchor_text", run_state) == "Combat\nNode 1",
		"Expected map presenter to build the current-focus anchor text from the runtime-owned current node."
	)
	assert(
		String(presenter.call("build_current_anchor_detail_text", run_state)).contains("Key: no"),
		"Expected current-anchor detail text to reflect adjacency runtime truth."
	)
	assert(
		presenter.call("build_key_marker_text", run_state) == "KEY\nAHEAD",
		"Expected unresolved stage keys to keep the default key marker text."
	)
	assert(
		presenter.call("build_node_family_display_name", "boss") == "Boss Gate",
		"Expected node-family display names to stay presenter-owned for the route board."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "combat") == "res://Assets/Icons/icon_attack.svg",
		"Expected combat routes to resolve to the dedicated combat icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "rest") == "res://Assets/Icons/icon_map_rest.svg",
		"Expected rest routes to resolve to the dedicated rest icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "merchant") == "res://Assets/Icons/icon_map_merchant.svg",
		"Expected merchant routes to resolve to the dedicated merchant icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "blacksmith") == "res://Assets/Icons/icon_map_blacksmith.svg",
		"Expected blacksmith routes to resolve to the dedicated blacksmith icon floor."
		)
	assert(
		presenter.call("build_route_icon_texture_path", "reward") == "res://Assets/Icons/icon_reward.svg",
		"Expected reward routes to resolve to the reward icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "event") == "res://Assets/Icons/icon_node_marker.svg",
		"Expected event routes to reuse the narrow event marker icon floor."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "key") == "res://Assets/Icons/icon_confirm.svg",
		"Expected key routes to use the dedicated key marker icon treatment."
	)
	assert(
		presenter.call("build_route_icon_texture_path", "boss") == "res://Assets/Icons/icon_enemy_intent_heavy.svg",
		"Expected boss routes to use the dedicated boss marker icon treatment."
	)
	var fog_preview_texts: PackedStringArray = presenter.call("build_fog_preview_texts", run_state, 3)
	assert(
		fog_preview_texts[0] == "",
		"Expected placeholder fog labels to stay hidden until a real fog presentation exists."
	)
	var route_models: Array[Dictionary] = presenter.call("build_route_view_models", run_state, 6)
	assert(
		String(route_models[0].get("text", "")) == "Combat\nReachable",
		"Expected unresolved adjacent combat nodes to sort ahead of revisit-only traversal nodes."
	)
	assert(
		String(route_models[0].get("icon_texture_path", "")) == "res://Assets/Icons/icon_attack.svg",
		"Expected route view models to expose the presenter-owned route icon texture path."
	)
	assert(
		String(route_models[0].get("state_chip_text", "")) == "OPEN",
		"Expected route view models to expose compact state-chip text for the shell overlay."
	)
	assert(
		String(route_models[1].get("state_chip_text", "")) == "SPENT",
		"Expected resolved route view models to expose the spent-state chip text."
	)
	assert(
		String(route_models[1].get("text", "")) == "Start\nSpent Path",
		"Expected resolved start-node traversal to stay readable as a revisit option."
	)
	assert(
		not bool(route_models[1].get("disabled", true)),
		"Expected spent adjacent routes to remain traversable for revisit positioning."
	)
	var visible_route_count: int = 0
	for route_model in route_models:
		if bool(route_model.get("visible", false)):
			visible_route_count += 1
	assert(
		visible_route_count >= 4,
		"Expected the presenter to keep nearby discovered context visible beyond the immediate adjacent shell."
	)
	assert(
		String(route_models[2].get("text", "")) == "Reward\nSeen",
		"Expected discovered non-adjacent nodes to remain visible as preview context."
	)
	assert(
		bool(route_models[2].get("disabled", false)),
		"Expected discovered non-adjacent context nodes to stay non-clickable."
	)
	assert(
		not bool(route_models[2].get("show_road", true)),
		"Expected only adjacent routes to draw direct road lines from the current node."
	)
	assert(
		String(route_models[2].get("state_chip_text", "")) == "",
		"Expected preview-only context nodes to avoid adjacency-state chips."
	)
	run_state.map_runtime_state.resolve_stage_key()
	assert(
		presenter.call("build_key_marker_text", run_state) == "KEY\nTAKEN",
		"Expected resolved stage keys to update the key marker read."
	)
