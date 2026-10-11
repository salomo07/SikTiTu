extends CharacterBody3D

@export var move_speed: float = 5.0
@export var gravity: float = 9.8

@onready var camera_pivot: Node3D = $CameraPivot

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var camera_basis := camera_pivot.global_transform.basis
	var direction := camera_basis.x * input_dir.x + camera_basis.z * input_dir.y
	direction.y = 0

	if direction.length() > 0.01:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
