extends Node3D

@export var animation_name: String = "Idle"


func _ready() -> void:
	var ap: AnimationPlayer = find_child("AnimationPlayer", true, false)
	if ap == null:
		push_warning("DragonAmbient: AnimationPlayer tidak ditemukan")
		return
	var target := animation_name
	if not ap.has_animation(target):
		var names := ap.get_animation_list()
		if names.is_empty():
			push_warning("DragonAmbient: tidak ada animasi")
			return
		target = names[0]
	var anim := ap.get_animation(target)
	anim.loop_mode = Animation.LOOP_LINEAR
	ap.play(target)
