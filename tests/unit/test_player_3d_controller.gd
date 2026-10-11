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

func test_pick_animation_name_matches_case_insensitively():
	var script = load("res://scripts/exploration/player_3d_controller.gd")
	assert_eq(script.pick_animation_name(["Idle", "Walk", "Run"], "walk"), "Walk")

func test_pick_animation_name_matches_namespaced_clip_names():
	var script = load("res://scripts/exploration/player_3d_controller.gd")
	assert_eq(script.pick_animation_name(["global/Idle", "global/Walk"], "idle"), "global/Idle")

func test_pick_animation_name_returns_empty_when_no_match():
	var script = load("res://scripts/exploration/player_3d_controller.gd")
	assert_eq(script.pick_animation_name(["Jump", "Punch"], "walk"), "")
