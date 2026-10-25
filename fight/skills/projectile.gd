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
var stun := 0.0              # detik lawan terpaku setelah kena (0 = hitstun biasa)
var linger := 0.0            # >0: setelah kena, proyektil "menempel" di lawan selama ini lalu memudar
var stick_offset_y := -165.0 # posisi menempel relatif kaki lawan (× skala tubuh); -100 ≈ menimpa badan
var hit_text := ""           # teks popup saat kena (mis. "-999" Pokoknya Ada)
var stun_fx := ""            # visual stun tambahan ("halo")
var _spent := false
var _stuck_to = null
var _t := 0.0

func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(3, true)   # deteksi hurtbox

func _physics_process(delta: float) -> void:
	_t += delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	if _stuck_to != null:
		# menempel di atas kepala lawan (bergoyang kecil) selama ia terpaku
		if not is_instance_valid(_stuck_to):
			queue_free()
			return
		var b: float = float(_stuck_to.scale.x)
		global_position = _stuck_to.global_position + Vector2(sin(_t * 22.0) * 5.0 * b, stick_offset_y * b + cos(_t * 9.0) * 4.0 * b)
		return
	velocity.y += fall_gravity * delta
	position += velocity * delta
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
			"push_dir": int(signf(velocity.x)), "stun": stun, "stun_fx": stun_fx,
		})
		if hit_text != "":
			FightEffects.spawn_popup_text(get_parent(), f.global_position + Vector2(0, -215.0 * float(f.scale.x)), hit_text)
		if linger > 0.0:
			_stick(f)
		else:
			queue_free()
		return

func _stick(f) -> void:
	_stuck_to = f
	velocity = Vector2.ZERO
	fall_gravity = 0.0
	lifetime = linger
	set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 1.15, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(0.0, linger - 0.12 - 0.45))
	tw.tween_property(self, "modulate:a", 0.0, 0.45)
