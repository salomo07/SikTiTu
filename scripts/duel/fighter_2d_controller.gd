extends CharacterBody2D

@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 900.0
@export var input_enabled: bool = true

@onready var state_machine: FighterState = $FighterState

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if input_enabled:
		_handle_input()

	move_and_slide()

func _handle_input() -> void:
	if state_machine.current_state == FighterState.State.HIT:
		return

	if Input.is_action_just_pressed("duel_skill_1") or Input.is_action_just_pressed("duel_skill_2"):
		if state_machine.transition_to(FighterState.State.ATTACK):
			velocity.x = 0
		return

	if state_machine.current_state == FighterState.State.ATTACK:
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
		elif state_machine.current_state in [FighterState.State.WALK, FighterState.State.JUMP]:
			state_machine.transition_to(FighterState.State.IDLE)
