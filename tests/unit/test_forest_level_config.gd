extends GutTest

var config

func before_each():
	config = load("res://scripts/exploration/forest_level_config.gd").new()

func test_compute_excess_children_returns_zero_when_under_max():
	assert_eq(config.compute_excess_children(3, 5), 0)

func test_compute_excess_children_returns_zero_when_at_max():
	assert_eq(config.compute_excess_children(5, 5), 0)

func test_compute_excess_children_returns_difference_when_over_max():
	assert_eq(config.compute_excess_children(8, 5), 3)
