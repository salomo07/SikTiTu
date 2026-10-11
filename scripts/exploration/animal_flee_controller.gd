extends CharacterBody3D
class_name AnimalFleeController

@export var flee_speed: float = 6.0
@export var detection_radius: float = 12.0
@export var flee_distance: float = 20.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var danger_position: Vector3 = Vector3.ZERO
var has_danger: bool = false

func set_danger(position: Vector3) -> void:
	danger_position = position
	has_danger = true

func clear_danger() -> void:
	has_danger = false

static func compute_flee_target(my_position: Vector3, danger_position: Vector3, flee_distance: float) -> Vector3:
	var away_direction := my_position - danger_position
	if away_direction.length() < 0.001:
		away_direction = Vector3.FORWARD
	away_direction = away_direction.normalized()
	return my_position + away_direction * flee_distance

func _physics_process(_delta: float) -> void:
	if not has_danger:
		return
	if global_position.distance_to(danger_position) > detection_radius:
		return

	nav_agent.target_position = compute_flee_target(global_position, danger_position, flee_distance)
	var next_path_position := nav_agent.get_next_path_position()
	var direction := (next_path_position - global_position)
	direction.y = 0
	if direction.length() > 0.01:
		velocity = direction.normalized() * flee_speed
	move_and_slide()
