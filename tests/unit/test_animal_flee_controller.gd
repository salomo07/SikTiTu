extends GutTest

func test_flee_target_moves_away_from_danger_on_x_axis():
	var my_pos := Vector3(5, 0, 0)
	var danger_pos := Vector3(0, 0, 0)
	var target = AnimalFleeController.compute_flee_target(my_pos, danger_pos, 10.0)

	assert_almost_eq(target.x, 15.0, 0.01)
	assert_almost_eq(target.z, 0.0, 0.01)

func test_flee_target_defaults_to_forward_when_overlapping_danger():
	var my_pos := Vector3(0, 0, 0)
	var danger_pos := Vector3(0, 0, 0)
	var target = AnimalFleeController.compute_flee_target(my_pos, danger_pos, 10.0)

	assert_almost_eq(target.z, -10.0, 0.01)

func test_flee_target_respects_flee_distance():
	var my_pos := Vector3(2, 0, 0)
	var danger_pos := Vector3(0, 0, 0)
	var target = AnimalFleeController.compute_flee_target(my_pos, danger_pos, 3.0)

	assert_almost_eq(target.x, 5.0, 0.01)
