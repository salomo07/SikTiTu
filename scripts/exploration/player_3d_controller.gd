extends CharacterBody3D

const RESPAWN_POSITION := Vector3(0, 1, 0)
const FALL_THRESHOLD_Y := -10.0
const MOVE_ANIMATION_KEYWORD := "walk"
const IDLE_ANIMATION_KEYWORD := "idle"

@export var move_speed: float = 5.0
@export var gravity: float = 9.8

@onready var camera_pivot: Node3D = $CameraPivot
@onready var facing: Node3D = get_node_or_null("Facing") as Node3D
@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer

func _ready() -> void:
	_play_animation(IDLE_ANIMATION_KEYWORD)

func _physics_process(delta: float) -> void:
	if is_below_fall_threshold(global_position.y):
		global_position = RESPAWN_POSITION
		velocity = Vector3.ZERO

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var camera_basis := camera_pivot.global_transform.basis
	var direction := camera_basis.x * input_dir.x + camera_basis.z * input_dir.y
	direction.y = 0

	var is_moving := direction.length() > 0.01
	if is_moving:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		_face_direction(direction)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
	_play_animation(MOVE_ANIMATION_KEYWORD if is_moving else IDLE_ANIMATION_KEYWORD)

static func is_below_fall_threshold(y: float) -> bool:
	return y < FALL_THRESHOLD_Y

## Picks the first clip whose name contains `keyword` (case-insensitive) from
## the animations actually present on the imported model. Matching by keyword
## rather than exact name keeps this working whether the importer exposes
## clips as "Walk" or namespaced as "global/Walk". Returns "" when none match.
static func pick_animation_name(available: Array, keyword: String) -> String:
	for anim_name in available:
		if String(anim_name).to_lower().contains(keyword):
			return anim_name
	return ""

func _play_animation(keyword: String) -> void:
	if animation_player == null:
		return
	var target := pick_animation_name(animation_player.get_animation_list(), keyword)
	if target != "" and animation_player.current_animation != target:
		animation_player.play(target)

## Rotates the `Facing` wrapper to look along the movement direction. The
## actual mesh lives one level deeper (`Facing/Model`) with a baked-in 180°
## correction, because the imported rig's front faces +Z instead of Godot's
## -Z convention — rotating `Facing` here (not `Model`) keeps that correction
## intact instead of look_at() overwriting it every frame.
func _face_direction(direction: Vector3) -> void:
	if facing == null:
		return
	facing.look_at(facing.global_position + direction, Vector3.UP)
