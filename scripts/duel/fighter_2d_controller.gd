extends CharacterBody2D

const ARENA_MIN_X := 20.0
const ARENA_MAX_X := 780.0

@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 900.0
@export var input_enabled: bool = true
@export var attack_duration: float = 0.4

@onready var state_machine: FighterState = $FighterState

var _attack_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	elif state_machine.current_state == FighterState.State.JUMP:
		_on_landed()

	if state_machine.current_state == FighterState.State.ATTACK:
		_tick_attack_timer(delta)

	if input_enabled:
		_handle_input()

	move_and_slide()
	position.x = clamp_to_arena(position.x)

func _on_landed() -> void:
	state_machine.transition_to(FighterState.State.IDLE)

func _tick_attack_timer(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		state_machine.transition_to(FighterState.State.IDLE)

func _start_attack() -> void:
	if state_machine.transition_to(FighterState.State.ATTACK):
		velocity.x = 0
		_attack_timer = attack_duration

func clamp_to_arena(x: float) -> float:
	return clamp(x, ARENA_MIN_X, ARENA_MAX_X)

func _handle_input() -> void:
	if state_machine.current_state == FighterState.State.HIT:
		return
	if state_machine.current_state == FighterState.State.ATTACK:
		return

	if Input.is_action_just_pressed("duel_skill_1") or Input.is_action_just_pressed("duel_skill_2"):
		_start_attack()
		return

	if Input.is_action_just_pressed("duel_jump") and is_on_floor():
		state_machine.transition_to(FighterState.State.JUMP)
		velocity.y = jump_velocity
		return

	if Input.is_action_pressed("duel_crouch") and is_on_floor():
		state_machine.transition_to(FighterState.State.CROUCH)
		velocity.x = 0
		return
	elif state_machine.current_state == FighterState.State.CROUCH:
		state_machine.transition_to(FighterState.State.IDLE)

	var horizontal := Input.get_axis("duel_left", "duel_right")
	velocity.x = horizontal * move_speed

	if is_on_floor():
		if horizontal != 0:
			state_machine.transition_to(FighterState.State.WALK)
		elif state_machine.current_state == FighterState.State.WALK:
			state_machine.transition_to(FighterState.State.IDLE)
