# Layer: Tests
extends SceneTree
class_name TestMapBoardStyle

const MapBoardStyleScript = preload("res://Game/UI/map_board_style.gd")


func _init() -> void:
	test_map_board_style_exposes_plain_board_background()
	test_map_board_style_road_tokens_stay_positive()
	test_map_board_style_history_roads_stay_surface_like()
	test_map_board_style_clearing_and_landmark_tokens_stay_visible()
	test_map_board_style_node_plates_stay_subordinate_to_pockets()
	test_map_board_style_forest_mask_extent_scales_stay_positive()
	print("test_map_board_style: all assertions passed")
	quit()


func test_map_board_style_exposes_plain_board_background() -> void:
	assert(MapBoardStyleScript.ATMOSPHERE_BACKGROUND_COLOR.a > 0.0, "Expected the plain board background to stay visible.")
	assert(MapBoardStyleScript.ATMOSPHERE_BACKGROUND_COLOR.a < 1.0, "Expected the board background to stay subordinate to route surfaces.")


func test_map_board_style_road_tokens_stay_positive() -> void:
	for emphasis_level in [0, 1, 2, 3]:
		assert(MapBoardStyleScript.road_base_width(false, emphasis_level) > 0.0, "Expected road base width to stay positive.")
		assert(MapBoardStyleScript.road_highlight_width(false, emphasis_level) > 0.0, "Expected road highlight width to stay positive.")
		assert(MapBoardStyleScript.road_base_color("open", emphasis_level).a > 0.0, "Expected road base color to stay visible.")
		assert(MapBoardStyleScript.road_highlight_color("open", emphasis_level).a > 0.0, "Expected road highlight color to stay visible.")


func test_map_board_style_history_roads_stay_surface_like() -> void:
	assert(
		MapBoardStyleScript.road_base_width(true, 0) >= MapBoardStyleScript.road_base_width(false, 0) * 0.68,
		"Expected discovered roads to remain broad enough to read as path surfaces, not old route strokes."
	)
	assert(
		MapBoardStyleScript.road_base_color("resolved", 0).a >= 0.44
			and MapBoardStyleScript.road_base_color("resolved", 0).a < MapBoardStyleScript.road_base_color("open", 0).a,
		"Expected discovered road color to stay visible but subordinate to active routes."
	)
	assert(
		MapBoardStyleScript.road_shadow_alpha(true) >= 0.09
			and MapBoardStyleScript.road_shadow_alpha(true) < MapBoardStyleScript.road_shadow_alpha(false),
		"Expected history road shadow to preserve a filled-surface bed without matching active roads."
	)


func test_map_board_style_clearing_and_landmark_tokens_stay_visible() -> void:
	for family in ["combat", "reward", "hamlet", "rest", "merchant", "blacksmith", "key", "boss", "event"]:
		assert(MapBoardStyleScript.clearing_fill_color(family, "open", false).a > 0.0, "Expected clearing fill to stay visible for family %s." % family)
		assert(MapBoardStyleScript.clearing_rim_color(family, "open", false).a > 0.0, "Expected clearing rim to stay visible for family %s." % family)
		assert(MapBoardStyleScript.landmark_pocket_fill_color(family, "open", false).a > 0.0, "Expected landmark pocket fill to stay visible for family %s." % family)
		assert(MapBoardStyleScript.landmark_pocket_rim_color(family, "open", false).a > 0.0, "Expected landmark pocket rim to stay visible for family %s." % family)


func test_map_board_style_node_plates_stay_subordinate_to_pockets() -> void:
	var node_plate := PanelContainer.new()
	MapBoardStyleScript.apply_node_plate_style(node_plate, "combat", "open", false, false)
	var plate_style := node_plate.get_theme_stylebox("panel") as StyleBoxFlat
	assert(plate_style != null, "Expected route node plates to keep a valid stylebox.")
	assert(
		plate_style.bg_color.a <= 0.30 and plate_style.shadow_size <= 4,
		"Expected route node plates to stay soft so the board reads as pockets instead of old colored tokens."
	)
	node_plate.free()


func test_map_board_style_forest_mask_extent_scales_stay_positive() -> void:
	assert(MapBoardStyleScript.forest_mask_extent_scale("canopy") > 1.0, "Expected canopy mask extent scale to stay positive.")
	assert(MapBoardStyleScript.forest_mask_extent_scale("decor") > 1.0, "Expected decor mask extent scale to stay positive.")
