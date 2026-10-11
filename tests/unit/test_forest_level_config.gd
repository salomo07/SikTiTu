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

func test_generate_tree_positions_returns_requested_count_when_space_allows():
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var positions: Array[Vector3] = config.generate_tree_positions(15, 50.0, 2.0, 3.0, rng)
	assert_eq(positions.size(), 15)

func test_generate_tree_positions_respects_spawn_clearance():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var positions: Array[Vector3] = config.generate_tree_positions(10, 40.0, 3.0, 5.0, rng)
	for position in positions:
		assert_true(position.length() >= 5.0)

func test_generate_tree_positions_respects_min_spacing():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var positions: Array[Vector3] = config.generate_tree_positions(10, 40.0, 3.0, 5.0, rng)
	for i in range(positions.size()):
		for j in range(i + 1, positions.size()):
			assert_true(positions[i].distance_to(positions[j]) >= 3.0)

func test_generate_tree_positions_is_deterministic_given_same_seed():
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 42
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 42
	var a: Array[Vector3] = config.generate_tree_positions(8, 40.0, 3.0, 5.0, rng_a)
	var b: Array[Vector3] = config.generate_tree_positions(8, 40.0, 3.0, 5.0, rng_b)
	assert_eq(a.size(), b.size())
	for i in range(a.size()):
		assert_eq(a[i], b[i])
