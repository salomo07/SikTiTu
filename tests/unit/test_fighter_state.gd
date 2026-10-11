extends GutTest

var fighter_state

func before_each():
	fighter_state = load("res://scripts/duel/fighter_state.gd").new()

func test_starts_in_idle_state():
	assert_eq(fighter_state.current_state, FighterState.State.IDLE)

func test_idle_to_attack_is_valid():
	var success = fighter_state.transition_to(FighterState.State.ATTACK)
	assert_true(success)
	assert_eq(fighter_state.current_state, FighterState.State.ATTACK)

func test_attack_to_attack_is_rejected():
	fighter_state.transition_to(FighterState.State.ATTACK)
	var success = fighter_state.transition_to(FighterState.State.ATTACK)
	assert_false(success)
	assert_eq(fighter_state.current_state, FighterState.State.ATTACK)

func test_jump_to_crouch_is_rejected():
	fighter_state.transition_to(FighterState.State.JUMP)
	var success = fighter_state.transition_to(FighterState.State.CROUCH)
	assert_false(success)
	assert_eq(fighter_state.current_state, FighterState.State.JUMP)

func test_any_state_can_transition_to_hit():
	fighter_state.transition_to(FighterState.State.ATTACK)
	var success = fighter_state.transition_to(FighterState.State.HIT)
	assert_true(success)
