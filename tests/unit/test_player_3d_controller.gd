extends GutTest

func before_each():
	pass

func test_is_below_fall_threshold_false_when_on_ground():
	var script = load("res://scripts/exploration/player_3d_controller.gd")
	assert_false(script.is_below_fall_threshold(1.0))

func test_is_below_fall_threshold_true_when_fallen_far():
	var script = load("res://scripts/exploration/player_3d_controller.gd")
	assert_true(script.is_below_fall_threshold(-11.0))

func test_is_below_fall_threshold_false_exactly_at_threshold():
	var script = load("res://scripts/exploration/player_3d_controller.gd")
	assert_false(script.is_below_fall_threshold(-10.0))
