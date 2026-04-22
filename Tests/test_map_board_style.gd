# Layer: Tests
extends SceneTree
class_name TestMapBoardStyle

const MapBoardStyleScript = preload("res://Game/UI/map_board_style.gd")


func _init() -> void:
	test_map_board_style_exposes_ground_tokens_for_each_profile()
	test_map_board_style_ground_inner_scales_and_rims_stay_positive()
	test_map_board_style_exposes_filler_tokens_for_each_profile()
	test_map_board_style_filler_inner_scales_and_rims_stay_positive()
	print("test_map_board_style: all assertions passed")
	quit()


func test_map_board_style_exposes_ground_tokens_for_each_profile() -> void:
	for profile in ["corridor", "openfield", "loop"]:
		var bed_color: Color = MapBoardStyleScript.ground_patch_color(profile, "bed", 0.0, 1.0)
		var patch_color: Color = MapBoardStyleScript.ground_patch_color(profile, "patch", 0.04, 1.0)
		var breakup_color: Color = MapBoardStyleScript.ground_patch_color(profile, "breakup", -0.04, 1.0)
		assert(bed_color.a > 0.0, "Expected board ground bed color to stay visible for profile %s." % profile)
		assert(patch_color.a > 0.0, "Expected board ground patch color to stay visible for profile %s." % profile)
		assert(breakup_color.a > 0.0, "Expected board ground breakup color to stay visible for profile %s." % profile)
		assert(
			bed_color != patch_color or patch_color != breakup_color,
			"Expected ground token families to produce distinct board-surface roles for profile %s." % profile
		)


func test_map_board_style_ground_inner_scales_and_rims_stay_positive() -> void:
	for family in ["bed", "patch", "breakup"]:
		var inner_scale: Vector2 = MapBoardStyleScript.ground_patch_inner_scale(family)
		assert(inner_scale.x > 0.0 and inner_scale.y > 0.0, "Expected ground inner scales to stay positive for family %s." % family)
		assert(inner_scale.x < 1.0 and inner_scale.y < 1.0, "Expected ground inner scales to stay inside the outer patch for family %s." % family)
		assert(MapBoardStyleScript.ground_patch_rim_width(family) > 0.0, "Expected ground rim width to stay positive for family %s." % family)


func test_map_board_style_exposes_filler_tokens_for_each_profile() -> void:
	for profile in ["corridor", "openfield", "loop"]:
		var rock_color: Color = MapBoardStyleScript.filler_shape_color(profile, "rock", 0.0, 1.0)
		var ruin_color: Color = MapBoardStyleScript.filler_shape_color(profile, "ruin", 0.04, 1.0)
		var water_color: Color = MapBoardStyleScript.filler_shape_color(profile, "water_patch", -0.04, 1.0)
		assert(rock_color.a > 0.0, "Expected filler rock color to stay visible for profile %s." % profile)
		assert(ruin_color.a > 0.0, "Expected filler ruin color to stay visible for profile %s." % profile)
		assert(water_color.a > 0.0, "Expected filler water color to stay visible for profile %s." % profile)
		assert(
			rock_color != ruin_color or ruin_color != water_color,
			"Expected filler token families to produce distinct secondary world-fill roles for profile %s." % profile
		)


func test_map_board_style_filler_inner_scales_and_rims_stay_positive() -> void:
	for family in ["rock", "ruin", "water_patch"]:
		var inner_scale: Vector2 = MapBoardStyleScript.filler_shape_inner_scale(family)
		assert(inner_scale.x > 0.0 and inner_scale.y > 0.0, "Expected filler inner scales to stay positive for family %s." % family)
		assert(inner_scale.x < 1.0 and inner_scale.y < 1.0, "Expected filler inner scales to stay inside the outer shape for family %s." % family)
		assert(MapBoardStyleScript.filler_shape_rim_width(family) > 0.0, "Expected filler rim width to stay positive for family %s." % family)
