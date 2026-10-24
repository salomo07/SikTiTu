extends Area2D
class_name FightProjectile

## Proyektil Fight generik (Bad Word, pecahan Monokotil, dll). Bergerak lurus (opsional
## gravitasi untuk lintasan melengkung), mengenai hurtbox lawan sekali, lalu hilang.
## Arah dorong ke lawan = arah laju proyektil (push_dir), bukan posisi tumbukan —
## supaya lawan selalu terdorong MENJAUH dari penembak.

var velocity := Vector2.ZERO
var fall_gravity := 0.0      # bukan `gravity`: nama itu sudah dipakai properti bawaan Area2D
var damage := 60
var knockback := 180.0
var owner_fighter = null
var lifetime := 2.5
var _spent := false

func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(3, true)   # deteksi hurtbox

func _physics_process(delta: float) -> void:
	velocity.y += fall_gravity * delta
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	if _spent:
		return
	for area in get_overlapping_areas():
		if not area.has_meta("fighter"):
			continue
		var f = area.get_meta("fighter")
		if f == owner_fighter or f == null:
			continue
		_spent = true
		f.receive_hit({
			"damage": damage, "knockback": knockback, "launch": 0.0,
			"low": false, "from_x": global_position.x,
			"push_dir": int(signf(velocity.x)),
		})
		queue_free()
		return
