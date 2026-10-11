extends CharacterBody3D

@export var walk_speed := 7.0
@export var fly_speed := 12.0
@export var vertical_speed := 7.0
@export var gravity := 20.0
@export var turn_speed := 7.0
@export var model_yaw_deg := 180.0
@export var model_scale := 0.6

var _anim: AnimationPlayer
var _roaring := false

@onready var _cam_pivot: Node3D = $CameraPivot


func _ready() -> void:
	var facing := $Facing as Node3D
	facing.rotation.y = deg_to_rad(model_yaw_deg)
	facing.scale = Vector3.ONE * model_scale
	# kamera tidak ikut rotasi badan: WASD selalu relatif layar
	_cam_pivot.top_level = true
	_cam_pivot.global_rotation = Vector3.ZERO
	_anim = find_child("AnimationPlayer", true, false)
	if _anim == null:
		push_warning("DragonPlayer: AnimationPlayer tidak ditemukan")
		return
	for anim_name in ["Idle", "Walk", "Fly", "Idle_B", "Walk_B", "Fly_Flap", "Fly_Glide"]:
		if _anim.has_animation(anim_name):
			_anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	_anim.animation_finished.connect(_on_anim_finished)
	_play("Idle_B")


func _play(anim_name: String) -> void:
	if _anim == null:
		return
	if _anim.has_animation(anim_name) and _anim.current_animation != anim_name:
		_anim.play(anim_name, 0.3)


func _on_anim_finished(anim_name: StringName) -> void:
	if anim_name == &"FireBreath":
		_roaring = false


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Vector3(input_dir.x, 0.0, input_dir.y)
	var ascend := Input.is_action_pressed("dragon_fly_up")
	var descend := Input.is_action_pressed("dragon_descend")

	if Input.is_action_just_pressed("dragon_roar") and not _roaring and _anim != null:
		if _anim.has_animation("FireBreath"):
			_roaring = true
			_anim.play("FireBreath", 0.15)

	var speed := walk_speed if is_on_floor() else fly_speed
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	if ascend:
		velocity.y = vertical_speed
	elif descend:
		velocity.y = -vertical_speed
	elif not is_on_floor():
		velocity.y -= gravity * delta * 0.4
	else:
		velocity.y = 0.0

	if dir.length_squared() > 0.01:
		var target_yaw := atan2(dir.x, dir.z) + PI
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)

	if not _roaring:
		if not is_on_floor():
			# meluncur saat turun, mengepak saat naik/jelajah
			if descend or (velocity.y < -1.0 and not ascend):
				_play("Fly_Glide")
			else:
				_play("Fly_Flap")
		elif dir.length_squared() > 0.01:
			_play("Walk_B")
		else:
			_play("Idle_B")

	move_and_slide()

	_cam_pivot.global_position = global_position + Vector3(0, 3.2, 0)
	_cam_pivot.global_rotation = Vector3.ZERO
