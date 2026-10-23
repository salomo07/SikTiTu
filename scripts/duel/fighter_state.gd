extends Node
class_name FighterState

enum State {IDLE, WALK, JUMP, CROUCH, ATTACK, HIT}

# NOTE: the public API below is typed `int`, not `State`. GDScript treats a
# script-local enum type (`State`) as distinct from the same enum accessed from
# another file as `FighterState.State`, which makes cross-file calls fail to
# type-check (verified on Godot 4.7.2). Enums are ints, so `int` accepts the
# `FighterState.State.*` values callers pass while keeping the named constants.
var current_state: int = State.IDLE

const VALID_TRANSITIONS := {
	State.IDLE: [State.WALK, State.JUMP, State.CROUCH, State.ATTACK, State.HIT],
	State.WALK: [State.IDLE, State.JUMP, State.CROUCH, State.ATTACK, State.HIT],
	State.JUMP: [State.IDLE, State.HIT],
	State.CROUCH: [State.IDLE, State.ATTACK, State.HIT],
	State.ATTACK: [State.IDLE, State.HIT],
	State.HIT: [State.IDLE],
}

signal state_changed(previous: int, next: int)

func can_transition_to(next_state: int) -> bool:
	return VALID_TRANSITIONS[current_state].has(next_state)

func transition_to(next_state: int) -> bool:
	if not can_transition_to(next_state):
		return false
	var previous := current_state
	current_state = next_state
	state_changed.emit(previous, next_state)
	return true
