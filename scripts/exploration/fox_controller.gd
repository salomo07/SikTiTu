extends AnimalFleeController
## Rubah hutan. Mewarisi logika "kabur dari bahaya" dari AnimalFleeController,
## lalu menambahkan: animasi (diam / lari) dan memutar badan ke arah lari.

@export var model_yaw_deg := 180.0  # rubah menghadap -Z, jadi diputar 180 derajat
@export var turn_speed := 10.0

@onready var _model: Node3D = $Model
var _anim: AnimationPlayer


func _ready() -> void:
	_anim = find_child("AnimationPlayer", true, false)
	if _anim:
		for n in ["Idle", "Gallop"]:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		_anim.play("Idle")


func _physics_process(delta: float) -> void:
	var moving := false
	if has_danger and global_position.distance_to(danger_position) <= detection_radius:
		nav_agent.target_position = compute_flee_target(global_position, danger_position, flee_distance)
		var dir := nav_agent.get_next_path_position() - global_position
		dir.y = 0.0
		if dir.length() > 0.01:
			velocity = dir.normalized() * flee_speed
			moving = true
			var target_yaw := atan2(dir.x, dir.z) + deg_to_rad(model_yaw_deg)
			_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn_speed * delta)
		move_and_slide()

	if _anim:
		var want := "Gallop" if moving else "Idle"
		if _anim.current_animation != want:
			_anim.play(want, 0.2)
