extends RefCounted
class_name FighterAI

## Otak AI petarung. Menghasilkan "command" yang sama bentuknya dengan input pemain,
## sehingga Fighter tak peduli sumber kendalinya.
##
## Tujuan desain (goal pemilik): musuh TERASA NATURAL, tidak menyerang terus-menerus.
## Caranya:
##  - Mengambil keputusan berkala dengan JEDA REAKSI (tidak tiap frame), lalu menahan
##    keputusan itu beberapa saat (pacing manusiawi).
##  - Punya beberapa niat: approach / maintain-spacing / retreat / attack / block / wait.
##  - Setelah menyerang ada COOLDOWN, dan ada peluang "diam sejenak" (menonton lawan).
##  - Block REAKTIF saat lawan mulai menyerang dari jarak dekat (peluang naik per level).

enum Intent { WAIT, APPROACH, RETREAT, ATTACK, BLOCK }

var level: int = 1                # 0 easy, 1 normal, 2 hard
var wants_block := false

var _intent: int = Intent.WAIT
var _decide_t := 0.0              # sisa waktu sebelum keputusan baru
var _hold_t := 0.0               # berapa lama menahan niat sekarang
var _attack_cd := 0.0            # cooldown setelah menyerang
var _queued_attack := ""
var _queued_skill := -1
var _rng := RandomNumberGenerator.new()

const DT := 1.0 / 60.0

func _init(ai_level: int = 1) -> void:
	level = ai_level
	_rng.randomize()

# parameter skala per tingkat
func _reaction() -> float:
	return [0.42, 0.26, 0.16][clampi(level, 0, 2)]
func _aggression() -> float:
	return [0.35, 0.55, 0.78][clampi(level, 0, 2)]
func _block_chance() -> float:
	return [0.30, 0.55, 0.82][clampi(level, 0, 2)]

func think(me, foe) -> Dictionary:
	wants_block = false
	var cmd := {"move": 0.0, "jump": false, "crouch": false, "block": false,
		"attack": "", "skill": -1, "run": false}
	if foe == null:
		return cmd

	_attack_cd = maxf(0.0, _attack_cd - DT)
	_decide_t -= DT
	_hold_t -= DT

	# jarak dinormalkan ke skala tubuh, supaya ambang (95/130/150/320) tetap berlaku saat karakter diperbesar
	var dist: float = absf(foe.global_position.x - me.global_position.x) / maxf(0.01, me.scale.x)
	var dir_to_foe: int = 1 if foe.global_position.x >= me.global_position.x else -1

	# --- reaksi cepat: block saat lawan menyerang dari dekat ---
	if _foe_is_attacking(foe) and dist < 150.0:
		if _rng.randf() < _block_chance():
			wants_block = true
			cmd["move"] = -dir_to_foe   # tahan menjauh = block
			cmd["crouch"] = _foe_attack_is_low(foe) and _rng.randf() < 0.6
			cmd["block"] = true
			return cmd

	# --- ambil keputusan baru bila waktunya ---
	if _decide_t <= 0.0:
		_pick_intent(dist)
		_decide_t = _reaction() + _rng.randf_range(0.0, 0.18)

	# --- jalankan niat sekarang ---
	match _intent:
		Intent.WAIT:
			cmd["move"] = 0.0
		Intent.APPROACH:
			if dist > 95.0:
				cmd["move"] = dir_to_foe
				# jauh sekali → lari mendekat (berhenti lari saat sudah dekat agar tak menabrak)
				cmd["run"] = dist > 300.0
			else:
				_intent = Intent.ATTACK
		Intent.RETREAT:
			cmd["move"] = -dir_to_foe
		Intent.BLOCK:
			wants_block = true
			cmd["move"] = -dir_to_foe
			cmd["block"] = true
		Intent.ATTACK:
			if dist <= 130.0 and _attack_cd <= 0.0 and me.can_act:
				_choose_attack(me, dist)
				cmd["attack"] = _queued_attack
				cmd["skill"] = _queued_skill
				cmd["crouch"] = _queued_attack in ["clp", "chk"] or _queued_crouch
				# cooldown + kembali menunggu/menjaga jarak agar tak spam
				_attack_cd = _rng.randf_range(0.45, 0.95) - level * 0.08
				_intent = Intent.WAIT if _rng.randf() < 0.5 else Intent.RETREAT
				_decide_t = _reaction()
			elif dist > 130.0:
				cmd["move"] = dir_to_foe
	return cmd

var _queued_crouch := false

func _pick_intent(dist: float) -> void:
	var r := _rng.randf()
	var aggr := _aggression()
	if dist > 320.0:
		# jauh: biasanya mendekat, kadang menunggu (tidak terburu-buru)
		_intent = Intent.APPROACH if r < 0.7 else Intent.WAIT
	elif dist > 140.0:
		# jarak menengah: campuran mendekat / jaga jarak / serang masuk
		if r < aggr: _intent = Intent.APPROACH
		elif r < aggr + 0.25: _intent = Intent.WAIT
		else: _intent = Intent.RETREAT
	else:
		# dekat: serang, tapi sering berhenti/jaga jarak supaya natural
		if r < aggr: _intent = Intent.ATTACK
		elif r < aggr + 0.3: _intent = Intent.BLOCK
		else: _intent = Intent.RETREAT
	_hold_t = _rng.randf_range(0.2, 0.6)

func _choose_attack(me, dist: float) -> void:
	_queued_attack = ""
	_queued_skill = -1
	_queued_crouch = false
	# sesekali pakai skill (lebih sering di level tinggi); cooldown/meter dicek Fighter._try_skill
	if _rng.randf() < 0.25 + level * 0.12:
		var n: int = me.def.skills.size()
		if n > 0:
			_queued_skill = _rng.randi_range(0, n - 1)
			return
	# pilih normal sesuai jarak
	var roll := _rng.randf()
	if dist < 70.0:
		_queued_attack = ["lp", "lk", "hp"][_rng.randi_range(0, 2)]
	else:
		_queued_attack = ["hk", "hp", "lk"][_rng.randi_range(0, 2)]
	# sesekali serangan rendah
	if _rng.randf() < 0.25:
		_queued_attack = "chk"
		_queued_crouch = true

func _foe_is_attacking(foe) -> bool:
	return foe.state == Fighter.S.ATTACK or foe.state == Fighter.S.SKILL

func _foe_attack_is_low(foe) -> bool:
	return foe._act.get("low", false)
