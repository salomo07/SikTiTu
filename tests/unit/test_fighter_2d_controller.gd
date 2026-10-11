extends GutTest

var fighter

func before_each():
	var fighter_scene := load("res://scenes/duel/fighter_2d.tscn") as PackedScene
	fighter = fighter_scene.instantiate()
	add_child_autofree(fighter)

func test_start_attack_transitions_to_attack_and_starts_timer():
	fighter._start_attack()

	assert_eq(fighter.state_machine.current_state, FighterState.State.ATTACK)
	assert_eq(fighter._attack_timer, fighter.attack_duration)

func test_attack_timer_returns_to_idle_once_expired():
	fighter._start_attack()
	fighter._tick_attack_timer(fighter.attack_duration + 0.01)

	assert_eq(fighter.state_machine.current_state, FighterState.State.IDLE)

func test_attack_timer_stays_in_attack_before_expiry():
	fighter._start_attack()
	fighter._tick_attack_timer(fighter.attack_duration * 0.5)

	assert_eq(fighter.state_machine.current_state, FighterState.State.ATTACK)

func test_landing_from_jump_returns_to_idle():
	fighter.state_machine.transition_to(FighterState.State.JUMP)
	fighter._on_landed()

	assert_eq(fighter.state_machine.current_state, FighterState.State.IDLE)

func test_clamp_to_arena_keeps_value_within_bounds():
	assert_eq(fighter.clamp_to_arena(400.0), 400.0)
	assert_eq(fighter.clamp_to_arena(-50.0), fighter.ARENA_MIN_X)
	assert_eq(fighter.clamp_to_arena(1000.0), fighter.ARENA_MAX_X)
