extends CharacterBody2D
class_name Fighter

## Controller petarung 2D. Satu skrip untuk pemain & AI: keduanya mengisi struktur
## "command" yang sama (lihat _gather_command / brain.think). Ini memisahkan sumber
## kendali dari logika gerak/combat sehingga AI bisa dibuat natural tanpa menyentuh
## fisika. Sprite memakai frame KFM (SpriteFrames dibangun KfmFrames).

signal hp_changed(hp: int, max_hp: int)
signal meter_changed(meter: float)
signal ko()

enum S { IDLE, WALK, JUMP, CROUCH, BLOCK, ATTACK, SKILL, HITSTUN, KNOCKDOWN, GETUP, DEAD }

const GRAVITY := 1500.0
const METER_MAX := 100.0
const START_METER := 25.0                 # meter awal tiap ronde (ultimate = setengah bar)

var _skill_cd: Dictionary = {}            # id skill -> sisa cooldown (detik)

@export var is_player: bool = true
@export var facing: int = 1               # +1 hadap kanan, -1 hadap kiri
var frozen: bool = false                  # true saat banner ronde / hasil: diam & abaikan command

var def: CharacterDef
var opponent: Fighter
var brain = null                          # FighterAI bila bukan pemain
var arena_min_x := 60.0
var arena_max_x := 1220.0

var hp: int = 1000
var meter: float = 0.0
var state: int = S.IDLE
var can_act: bool = true

# aksi aktif (normal/skill)
var _act: Dictionary = {}
var _act_phase := ""                      # "startup"/"active"/"recovery"
var _act_t := 0.0
var _hit_done := false                    # satu hit per activation
var _hitstun_t := 0.0
var _down_t := 0.0
var _block_t := 0.0

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _hurtbox: Area2D = $Hurtbox
@onready var _hitbox: Area2D = $Hitbox
@onready var _hitbox_shape: CollisionShape2D = $Hitbox/Shape

func setup(character: CharacterDef, player: bool, foe: Fighter) -> void:
	def = character
	is_player = player
	opponent = foe
	hp = def.max_hp

func _ready() -> void:
	add_to_group("fighters")
	if def == null:
		def = CharacterRegistry.get_def("kfm")
		hp = def.max_hp
	_setup_sprite()
	_setup_boxes()
	_set_state(S.IDLE)
	hp_changed.emit(hp, def.max_hp)
	meter_changed.emit(meter)

func _setup_sprite() -> void:
	var frames: SpriteFrames = def.frames if def.frames != null else KfmFrames.get_frames()
	if frames != null:
		_sprite.sprite_frames = frames
	_sprite.modulate = def.tint
	_sprite.centered = false
	_sprite.scale = Vector2.ONE * def.sprite_scale
	_apply_sprite_offset()

func _apply_sprite_offset() -> void:
	# Jaga titik kaki (axis) tetap di origin node, baik menghadap kiri/kanan.
	var ax: Vector2 = def.axis if def.frames != null else KfmFrames.axis
	var cv: Vector2 = def.canvas if def.frames != null else KfmFrames.canvas
	if facing >= 0:
		_sprite.flip_h = false
		_sprite.offset = Vector2(-ax.x, -ax.y)
	else:
		_sprite.flip_h = true
		_sprite.offset = Vector2(-(cv.x - ax.x), -ax.y)

func _setup_boxes() -> void:
	# Hurtbox: bisa dikenai; menandai pemiliknya agar hitbox lawan mengenali.
	_hurtbox.set_meta("fighter", self)
	_hurtbox.monitoring = false
	_hurtbox.monitorable = true
	_hurtbox.collision_layer = 0
	_hurtbox.set_collision_layer_value(3, true)
	_hurtbox.collision_mask = 0
	# Hitbox: mendeteksi hurtbox lawan saat frame aktif.
	_hitbox.monitoring = true
	_hitbox.monitorable = false
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 0
	_hitbox.set_collision_mask_value(3, true)
	_hitbox_shape.disabled = true

# ---------------------------------------------------------------- loop utama
func _physics_process(delta: float) -> void:
	_tick_skill_cooldowns(delta)
	if state == S.DEAD:
		velocity.x = move_toward(velocity.x, 0, 2000 * delta)
		_apply_gravity(delta)
		move_and_slide()
		return

	if frozen:
		velocity.x = move_toward(velocity.x, 0, 2000 * delta)
		if is_on_floor() and state not in [S.KNOCKDOWN, S.DEAD]:
			_set_state(S.IDLE)
		_apply_gravity(delta)
		move_and_slide()
		return

	_update_facing()
	var cmd := _get_command()

	match state:
		S.HITSTUN: _process_hitstun(delta)
		S.KNOCKDOWN: _process_knockdown(delta)
		S.GETUP: _process_getup(delta)
		S.ATTACK, S.SKILL: _process_action(delta)
		_:
			_process_free(delta, cmd)

	_apply_gravity(delta)
	move_and_slide()
	position.x = clampf(position.x, arena_min_x, arena_max_x)
	_update_active_hit()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif velocity.y > 0:
		velocity.y = 0

func _update_facing() -> void:
	if opponent == null or not is_on_floor():
		return
	if not can_act and state != S.IDLE and state != S.WALK and state != S.BLOCK:
		return
	var want := 1 if opponent.global_position.x >= global_position.x else -1
	if want != facing:
		facing = want
		_apply_sprite_offset()

# ---------------------------------------------------------------- command
func _get_command() -> Dictionary:
	if is_player:
		return _gather_input()
	if brain != null:
		return brain.think(self, opponent)
	return _idle_command()

func _idle_command() -> Dictionary:
	return {"move": 0.0, "jump": false, "crouch": false, "block": false,
		"attack": "", "skill": -1}

func _gather_input() -> Dictionary:
	var move := Input.get_axis("fight_left", "fight_right")
	var crouch := Input.is_action_pressed("fight_crouch")
	# Block = menahan arah menjauh dari lawan saat berdiri/jongkok.
	var away := (move < 0 and facing > 0) or (move > 0 and facing < 0)
	var attack := ""
	if Input.is_action_just_pressed("fight_lp"): attack = "lp"
	elif Input.is_action_just_pressed("fight_hp"): attack = "hp"
	elif Input.is_action_just_pressed("fight_lk"): attack = "lk"
	elif Input.is_action_just_pressed("fight_hk"): attack = "hk"
	var skill := -1
	for i in 4:
		if Input.is_action_just_pressed("fight_skill_%d" % (i + 1)):
			skill = i
			break
	return {"move": move, "jump": Input.is_action_just_pressed("fight_jump"),
		"crouch": crouch, "block": away and is_on_floor(),
		"attack": attack, "skill": skill}

# ---------------------------------------------------------------- free state
func _process_free(delta: float, cmd: Dictionary) -> void:
	# Prioritas: skill > normal > lompat > jongkok/block > jalan.
	if is_on_floor():
		if cmd["skill"] >= 0 and _try_skill(cmd["skill"]):
			return
		if cmd["attack"] != "" and _try_normal(cmd["attack"], cmd["crouch"]):
			return
		if cmd["jump"]:
			velocity.y = def.jump_velocity * scale.x   # gerak ikut skala tubuh agar rasa tetap
			_set_state(S.JUMP)
			return
		if cmd["block"]:
			velocity.x = 0
			# block sambil jongkok → bisa menangkis serangan rendah (sweep)
			_set_state(S.CROUCH if cmd["crouch"] else S.BLOCK)
			return
		if cmd["crouch"]:
			velocity.x = 0
			_set_state(S.CROUCH)
			return
		# jalan
		velocity.x = cmd["move"] * def.move_speed * scale.x
		if absf(cmd["move"]) > 0.1:
			_set_state(S.WALK)
			# animasi maju/mundur tergantung arah relatif lawan
			var mv: float = cmd["move"]
			var toward: bool = (mv > 0 and facing > 0) or (mv < 0 and facing < 0)
			_play("walk_fwd" if toward else "walk_back")
		else:
			_set_state(S.IDLE)
	else:
		# di udara: kontrol horizontal terbatas
		velocity.x = cmd["move"] * def.move_speed * 0.6 * scale.x
		if is_on_floor() == false and velocity.y >= 0 and state == S.JUMP:
			pass
		if is_on_floor():
			_set_state(S.IDLE)

# ---------------------------------------------------------------- attacks
func _try_normal(id: String, crouching: bool) -> bool:
	var key := id
	if crouching:
		if id == "lp": key = "clp"
		elif id == "hk": key = "chk"
	if not def.normals.has(key):
		key = id
	if not def.normals.has(key):
		return false
	_begin_action(def.normals[key].duplicate(true), S.ATTACK)
	return true

func _try_skill(index: int) -> bool:
	var keys := def.skills.keys()
	if index >= keys.size():
		return false
	var id: String = keys[index]
	var data: Dictionary = def.skills[id].duplicate(true)
	# Skill biasa gratis tapi ber-cooldown; hanya ultimate yang memakai meter (cost > 0).
	if float(_skill_cd.get(id, 0.0)) > 0.0:
		return false
	var cost: float = float(data.get("cost", 0))
	if meter < cost:
		return false
	meter -= cost
	meter_changed.emit(meter)
	_skill_cd[id] = float(data.get("cooldown", 1.5))
	data["_id"] = id
	_begin_action(data, S.SKILL)
	return true

func _tick_skill_cooldowns(delta: float) -> void:
	for id in _skill_cd.keys():
		_skill_cd[id] = maxf(0.0, float(_skill_cd[id]) - delta)

## Sisa cooldown skill ke-index (detik); 0 = siap. Dipakai HUD/AI.
func skill_cooldown(index: int) -> float:
	var keys := def.skills.keys()
	if index >= keys.size():
		return 0.0
	return float(_skill_cd.get(keys[index], 0.0))

func _begin_action(data: Dictionary, st: int) -> void:
	_act = data
	_act_phase = "startup"
	_act_t = float(data.get("startup", 0.1))
	_hit_done = false
	velocity.x = 0
	_set_state(st)
	_play(data.get("anim", "idle"), false)
	# Skill: fase kuda-kuda jadi "upacara" — pose ditahan (animasi melambat), aura berdenyut,
	# nama skill diumumkan; efek utamanya menyusul saat startup selesai (_on_action_active).
	if st == S.SKILL:
		_sprite.speed_scale = 0.55
		var is_ult := bool(data.get("ultimate", false))
		FightEffects.spawn_windup(_effects_root(), self, _act_t, is_ult)
		var p := get_parent()
		if p and p.has_method("announce_skill"):
			p.announce_skill(String(data.get("name", "")), is_ult)

func _process_action(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 1200 * delta)
	_act_t -= delta
	if _act_t > 0:
		return
	match _act_phase:
		"startup":
			_act_phase = "active"
			_act_t = float(_act.get("active", 0.0))
			_hit_done = false
			_on_action_active()
		"active":
			_act_phase = "recovery"
			_act_t = float(_act.get("recovery", 0.2))
			_set_hitbox_enabled(false)
		"recovery":
			_end_action()

func _on_action_active() -> void:
	# Skill dengan fx khusus menyalakan efeknya di awal fase aktif.
	if state == S.SKILL:
		_fire_skill_effect()
	# Normal / skill dengan hitbox melee: nyalakan hitbox.
	if _act.has("hb"):
		_set_hitbox_from_data(_act["hb"])
		_set_hitbox_enabled(true)
	# Kucing Asia: dash saat aktif.
	if _act.get("fx", "") == "cat_dash":
		velocity.x = facing * float(_act.get("dash_speed", 600.0)) * scale.x

func _end_action() -> void:
	_set_hitbox_enabled(false)
	_sprite.speed_scale = 1.0
	_act = {}
	_act_phase = ""
	can_act = true
	_set_state(S.IDLE)

func _fire_skill_effect() -> void:
	var fx := String(_act.get("fx", ""))
	var mgr := _effects_root()
	match fx:
		"bad_word":
			FightEffects.spawn_bad_word(mgr, self)
		"quake":
			FightEffects.spawn_quake(mgr, self)
		"cat_dash":
			FightEffects.spawn_cat_aura(mgr, self)
		"monokotil":
			FightEffects.spawn_monokotil(mgr, self)
		"launch":
			pass
	# gain sedikit screen shake untuk skill berat
	if _act.get("ultimate", false) or fx == "quake":
		_request_shake(10.0, 0.4)
	else:
		_request_shake(4.0, 0.15)

func _effects_root() -> Node:
	# efek & proyektil dipasang di parent arena agar independen dari fighter.
	return get_parent()

func _request_shake(amount: float, time: float) -> void:
	var p := get_parent()
	if p and p.has_method("shake"):
		p.shake(amount, time)

# ---------------------------------------------------------------- hitbox
func _set_hitbox_from_data(hb: Dictionary) -> void:
	var off: Vector2 = hb.get("off", Vector2.ZERO)
	var size: Vector2 = hb.get("size", Vector2(40, 40))
	_hitbox.position = Vector2(off.x * facing, off.y)
	var rect := RectangleShape2D.new()
	rect.size = size
	_hitbox_shape.shape = rect

func _set_hitbox_enabled(on: bool) -> void:
	_hitbox_shape.set_deferred("disabled", not on)

func _update_active_hit() -> void:
	if _act_phase != "active" or _hit_done or _hitbox_shape.disabled:
		return
	if not _act.has("hb"):
		return
	for area in _hitbox.get_overlapping_areas():
		if not area.has_meta("fighter"):
			continue
		var f = area.get_meta("fighter")
		if f == self or f == null:
			continue
		_hit_done = true
		f.receive_hit({
			"damage": int(_act.get("damage", 10)),
			"knockback": float(_act.get("knockback", 150.0)),
			"launch": float(_act.get("launch", 0.0)),
			"low": bool(_act.get("low", false)),
			"from_x": global_position.x,
		})
		_gain_meter(float(_act.get("damage", 10)) * 0.08)   # penyerang dapat meter saat memukul
		break

# ---------------------------------------------------------------- menerima hit
func receive_hit(info: Dictionary) -> void:
	if state == S.DEAD or state == S.KNOCKDOWN:
		return
	# Arah dorong: proyektil memberi push_dir (arah lajunya); serangan melee dari posisi penyerang.
	var dir: int = int(info.get("push_dir", 0))
	if dir == 0:
		dir = 1 if info["from_x"] <= global_position.x else -1
	var blocking := state == S.BLOCK or (state == S.CROUCH and _is_holding_block())
	# serangan rendah (sweep) tak bisa ditangkis sambil berdiri
	if blocking and info.get("low", false) and state == S.BLOCK:
		blocking = false
	if blocking:
		var dmg := int(info["damage"] * 0.12)
		hp = maxi(0, hp - dmg)
		velocity.x = dir * 120.0 * scale.x
		_block_t = 0.18
		_gain_meter(4.0)
		hp_changed.emit(hp, def.max_hp)
		FightEffects.spawn_block_spark(_effects_root(), global_position + Vector2(0, -80 * scale.x), scale.x)
		return

	hp = maxi(0, hp - int(info["damage"]))
	_gain_meter(info["damage"] * 0.1)
	hp_changed.emit(hp, def.max_hp)
	_set_hitbox_enabled(false)
	_sprite.speed_scale = 1.0        # bila terpukul saat kuda-kuda skill, animasi kembali normal
	FightEffects.spawn_hit_spark(_effects_root(), global_position + Vector2(0, -90 * scale.x), scale.x)
	_request_shake(3.0, 0.1)

	if hp <= 0:
		_die(dir, info)
		return

	var launch: float = info.get("launch", 0.0)
	if launch != 0.0:
		velocity.y = launch * scale.x
		velocity.x = dir * info["knockback"] * 0.4 * scale.x
		_set_state(S.KNOCKDOWN)
		_down_t = 0.9
		_play("knockdown", false)
	else:
		velocity.x = dir * info["knockback"] * scale.x
		_hitstun_t = 0.28
		_set_state(S.HITSTUN)
		_play("hit_low" if info.get("low", false) else "hit", false)

func _is_holding_block() -> bool:
	if is_player:
		var move := Input.get_axis("fight_left", "fight_right")
		return (move < 0 and facing > 0) or (move > 0 and facing < 0)
	return brain != null and brain.wants_block

func _process_hitstun(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 900 * delta)
	_hitstun_t -= delta
	if _hitstun_t <= 0 and is_on_floor():
		can_act = true
		_set_state(S.IDLE)

func _process_knockdown(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 700 * delta)
	if is_on_floor():
		_down_t -= delta
		if _down_t <= 0:
			_set_state(S.GETUP)
			_down_t = 0.4
			_play("getup", false)

func _process_getup(delta: float) -> void:
	_down_t -= delta
	if _down_t <= 0:
		can_act = true
		_set_state(S.IDLE)

func _die(dir: int, info: Dictionary) -> void:
	velocity.x = dir * 260.0
	velocity.y = -300.0
	_set_state(S.DEAD)
	_play("knockdown", false)
	ko.emit()

func _gain_meter(amount: float) -> void:
	# 2× lebih cepat terisi agar ultimate (setengah bar) terjangkau dalam satu ronde.
	meter = clampf(meter + amount * 2.0, 0, METER_MAX)
	meter_changed.emit(meter)

# ---------------------------------------------------------------- state/anim
func _set_state(st: int) -> void:
	if state == st:
		_update_free_anim(st)
		return
	state = st
	can_act = st in [S.IDLE, S.WALK, S.CROUCH, S.BLOCK, S.JUMP]
	_update_free_anim(st)

func _update_free_anim(st: int) -> void:
	match st:
		S.IDLE: _play("idle")
		S.CROUCH: _play("crouch")
		S.BLOCK: _play(def.anims.get("block", "guard"))
		S.JUMP: _play("jump", false)
		# WALK anim diatur di _process_free; ATTACK/SKILL/hit di tempat masing-masing

func _play(state_key: String, loop_override := true) -> void:
	var anim: String = def.anims.get(state_key, state_key)
	if _sprite.sprite_frames == null or not _sprite.sprite_frames.has_animation(anim):
		return
	if _sprite.animation == anim and _sprite.is_playing():
		return
	_sprite.play(anim)

func is_dead() -> bool:
	return state == S.DEAD

func reset_for_round(spawn_x: float, face: int) -> void:
	hp = def.max_hp
	meter = START_METER
	_skill_cd.clear()
	position.x = spawn_x
	facing = face
	velocity = Vector2.ZERO
	_act = {}
	_act_phase = ""
	_set_hitbox_enabled(false)
	_sprite.speed_scale = 1.0
	_set_state(S.IDLE)
	_apply_sprite_offset()
	hp_changed.emit(hp, def.max_hp)
	meter_changed.emit(meter)
