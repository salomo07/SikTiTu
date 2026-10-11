extends GutTest

var game_manager

func before_each():
	game_manager = load("res://autoload/game_manager.gd").new()
	game_manager.auto_change_scene = false
	add_child_autofree(game_manager)

func test_start_duel_stores_enemy_id_and_position():
	var test_position := Vector3(1, 0, 5)
	game_manager.start_duel("wolf_01", test_position)

	assert_eq(game_manager.current_enemy_id, "wolf_01")
	assert_eq(game_manager.player_forest_position, test_position)
	assert_true(game_manager.is_in_duel)

func test_end_duel_clears_duel_flag():
	game_manager.start_duel("wolf_01", Vector3.ZERO)
	game_manager.end_duel("win")

	assert_false(game_manager.is_in_duel)

func test_start_duel_emits_signal_with_enemy_id():
	watch_signals(game_manager)
	game_manager.start_duel("wolf_01", Vector3.ZERO)

	assert_signal_emitted_with_parameters(game_manager, "duel_started", ["wolf_01"])

func test_start_duel_is_ignored_while_already_in_duel():
	game_manager.start_duel("wolf_01", Vector3(1, 0, 1))
	game_manager.start_duel("bear_02", Vector3(9, 0, 9))

	assert_eq(game_manager.current_enemy_id, "wolf_01", "second start_duel call must be ignored while a duel is active")
	assert_eq(game_manager.player_forest_position, Vector3(1, 0, 1))

func test_end_duel_marks_enemy_as_resolved():
	game_manager.start_duel("wolf_01", Vector3.ZERO)
	game_manager.end_duel("win")

	assert_true(game_manager.resolved_enemy_ids.has("wolf_01"))

func test_start_duel_is_ignored_for_already_resolved_enemy():
	game_manager.start_duel("wolf_01", Vector3.ZERO)
	game_manager.end_duel("win")

	game_manager.start_duel("wolf_01", Vector3(2, 0, 2))

	assert_false(game_manager.is_in_duel, "a resolved encounter must not start a new duel")

func test_end_duel_sets_pending_restore_to_the_captured_position():
	var test_position := Vector3(3, 0, 4)
	game_manager.start_duel("wolf_01", test_position)
	game_manager.end_duel("win")

	assert_true(game_manager.has_pending_restore())
	assert_eq(game_manager.consume_pending_restore_position(), test_position)

func test_consume_pending_restore_position_clears_the_pending_flag():
	game_manager.start_duel("wolf_01", Vector3(3, 0, 4))
	game_manager.end_duel("win")
	game_manager.consume_pending_restore_position()

	assert_false(game_manager.has_pending_restore())
