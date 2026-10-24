extends CharacterBody3D
## Pemain humanoid (Prabowo) dengan animasi UAL2 + Mixamo hasil retarget.

@export var active := false
@export var walk_speed := 3.5
@export var run_speed := 7.0
@export var jump_velocity := 7.5
@export var gravity := 20.0
@export var turn_speed := 10.0
@export var model_yaw_deg := 180.0

const LOOPS := [
	"H_Idle", "H_Walk", "H_Run", "Slide", "Walk_Carry", "Zombie_Walk_Fwd",
	"Zombie_Idle", "Idle_FoldArms", "Idle_TalkingPhone", "Idle_Lantern",
	"Idle_Shield", "Idle_Rail", "TreeChopping", "NinjaJump_Idle", "Idle_No",
]

## Tombol -> animasi aksi (sekali main, atau loop sampai bergerak).
const ACTION_KEYS := {
	KEY_J: "Melee_Hook", KEY_K: "Sword_Regular_Combo", KEY_L: "Sword_Heavy_Combo",
	KEY_U: "Sword_Block", KEY_I: "Sword_Dash", KEY_O: "Shield_Dash", KEY_P: "H_Punch",
	KEY_F: "OverhandThrow", KEY_E: "Chest_Open", KEY_Q: "Consume", KEY_G: "Hit_Knockback",
	KEY_C: "ClimbUp_1m", KEY_V: "Idle_Shield", KEY_B: "Shield_OneShot",
	KEY_1: "Yes", KEY_2: "Idle_No", KEY_3: "Idle_FoldArms", KEY_4: "Idle_TalkingPhone",
	KEY_5: "Farm_PlantSeed", KEY_6: "Farm_Watering", KEY_7: "Farm_Harvest", KEY_8: "TreeChopping",
	KEY_9: "Idle_Lantern", KEY_0: "H_Working", KEY_N: "Zombie_Scratch", KEY_M: "LayToIdle",
	KEY_T: "H_Death",
}

var _anim: AnimationPlayer
var _busy := ""
var _carry := false
var _zombie := false
var _was_air := false

@onready var _cam: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var _cam_pivot: Node3D = $CameraPivot
@onready var _spring: SpringArm3D = $CameraPivot/SpringArm3D

@export var zoom_min := 2.0
@export var zoom_max := 15.0
@export var zoom_step := 1.0
@export var orbit_sens := 0.006
@export var pitch_min := -1.5
@export var pitch_max := 1.5

var _yaw := 0.0
var _pitch := 0.35
var _roll := 0.0


func _ready() -> void:
	($Facing as Node3D).rotation.y = deg_to_rad(model_yaw_deg)
	_cam_pivot.top_level = true
	_anim = find_child("AnimationPlayer", true, false)
	if _anim == null:
		push_warning("HumanPlayer: AnimationPlayer tidak ditemukan")
		return
	for n in LOOPS:
		if _anim.has_animation(n):
			_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	_anim.animation_finished.connect(func(_n): _busy = "")
	_play("H_Idle")
	set_active(active)


func set_active(on: bool) -> void:
	active = on
	if _cam:
		_cam.current = on


func _play(n: String, blend := 0.2) -> void:
	if _anim and _anim.has_animation(n) and _anim.current_animation != n:
		_anim.play(n, blend)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.pressed and _spring:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_spring.spring_length = clampf(_spring.spring_length - zoom_step, zoom_min, zoom_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_spring.spring_length = clampf(_spring.spring_length + zoom_step, zoom_min, zoom_max)
		return
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_yaw -= event.relative.x * orbit_sens
			_pitch = clampf(_pitch - event.relative.y * orbit_sens, pitch_min, pitch_max)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			_roll += event.relative.x * orbit_sens
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: Key = event.physical_keycode
	if key == KEY_X:
		_carry = not _carry
	elif key == KEY_Z:
		_zombie = not _zombie
	elif ACTION_KEYS.has(key) and is_on_floor():
		_busy = ACTION_KEYS[key]
		if _anim:
			_anim.play(_busy, 0.15)


func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	var run := false
	var jump := false
	var slide := false
	if active:
		var iv := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		dir = Vector3(iv.x, 0.0, iv.y).rotated(Vector3.UP, _yaw)
		run = Input.is_key_pressed(KEY_SHIFT)
		slide = Input.is_key_pressed(KEY_CTRL)
		jump = Input.is_action_just_pressed("dragon_fly_up")

	var moving := dir.length_squared() > 0.01
	if moving and _busy != "" and _anim and _anim.get_animation(_busy).loop_mode != Animation.LOOP_NONE:
		_busy = ""
	if _busy != "":
		dir = Vector3.ZERO
		moving = false

	var speed := run_speed if (run or slide) else walk_speed
	if _zombie or _carry:
		speed = walk_speed * 0.7
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if is_on_floor():
		velocity.y = 0.0
		if jump and _busy == "":
			velocity.y = jump_velocity
			_play("NinjaJump_Start", 0.1)
	else:
		velocity.y -= gravity * delta

	if moving:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z) + PI, turn_speed * delta)

	move_and_slide()
	_update_anim(moving, run, slide)
	_cam_pivot.global_position = global_position + Vector3(0, 1.6, 0)
	_cam_pivot.global_rotation = Vector3(_pitch, _yaw, _roll)


func _update_anim(moving: bool, run: bool, slide: bool) -> void:
	var air := not is_on_floor()
	if _was_air and not air:
		_busy = "NinjaJump_Land"
		_anim.play(_busy, 0.1)
	_was_air = air
	if _busy != "" or _anim == null:
		return
	if air:
		if _anim.current_animation != "NinjaJump_Start":
			_play("NinjaJump_Idle")
	elif not moving:
		_play("Zombie_Idle" if _zombie else "H_Idle")
	elif slide:
		_play("Slide")
	elif _zombie:
		_play("Zombie_Walk_Fwd")
	elif _carry:
		_play("Walk_Carry")
	else:
		_play("H_Run" if run else "H_Walk")
