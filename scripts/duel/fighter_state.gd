extends Node
class_name FighterState

enum State {IDLE, WALK, JUMP, CROUCH, ATTACK, HIT}

var current_state: State = State.IDLE

const VALID_TRANSITIONS := {
	State.IDLE: [State.WALK, State.JUMP, State.CROUCH, State.ATTACK, State.HIT],
	State.WALK: [State.IDLE, State.JUMP, State.CROUCH, State.ATTACK, State.HIT],
	State.JUMP: [State.IDLE, State.HIT],
	State.CROUCH: [State.IDLE, State.ATTACK, State.HIT],
	State.ATTACK: [State.IDLE, State.HIT],
	State.HIT: [State.IDLE],
}

signal state_changed(previous: State, next: State)

func can_transition_to(next_state: State) -> bool:
	return VALID_TRANSITIONS[current_state].has(next_state)

func transition_to(next_state: State) -> bool:
	if not can_transition_to(next_state):
		return false
	var previous := current_state
	current_state = next_state
	state_changed.emit(previous, next_state)
	return true
