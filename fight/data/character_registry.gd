extends RefCounted
class_name CharacterRegistry

## Registry karakter Fight. Menambah karakter = menambah fungsi pembuat di sini.
## Dua karakter awal berbagi frame KFM (placeholder) dengan tint & skill berbeda.

## id urut untuk layar pilih karakter.
static func ids() -> Array[String]:
	return ["kfm", "asian_tiger", "kolonel"]

static func get_def(id: String) -> CharacterDef:
	match id:
		"kfm": return _kfm()
		"asian_tiger": return _asian_tiger()
		"kolonel": return _kolonel()
		_: return _kfm()

## Kung Fu Man — petarung dasar, 2 special klasik (palm = telapak jarak dekat kuat,
## upper = anti-udara).
static func _kfm() -> CharacterDef:
	var c := CharacterDef.new()
	c.id = "kfm"
	c.display_name = "Kung Fu Man"
	c.tint = Color(1, 1, 1)
	c.portrait_color = Color(0.25, 0.45, 0.75)
	c.max_hp = 1000
	c.move_speed = 220.0
	c.skills = {
		"palm": {
			"name": "Telapak Naga", "anim": "palm", "fx": "shout_none",
			"damage": 120, "startup": 0.45, "active": 0.18, "recovery": 0.55,
			"knockback": 420.0, "cost": 0, "cooldown": 2.0, "stun": 1.2,
			"hb": {"off": Vector2(70, -95), "size": Vector2(90, 55)},
		},
		"upper": {
			"name": "Uppercut", "anim": "upper", "fx": "launch",
			"damage": 130, "startup": 0.35, "active": 0.18, "recovery": 0.60,
			"knockback": 300.0, "launch": -520.0, "cost": 0, "cooldown": 2.5,
			"hb": {"off": Vector2(45, -120), "size": Vector2(60, 90)},
		},
	}
	return c

## Mr. Asian Tiger — petarung satir dengan 4 skill khas (lihat GAME_DESIGN §8.2).
## Sprite khusus belum ada → pakai frame KFM + tint oranye sebagai placeholder;
## keunikan terasa lewat VFX ("fx") tiap skill.
const TIGER_DIR := "res://assets/characters/asian_tiger/frames"

static func _asian_tiger() -> CharacterDef:
	var c := CharacterDef.new()
	c.id = "asian_tiger"
	c.display_name = "Mr. Asian Tiger"
	c.tint = Color(1, 1, 1)            # sprite Prabowo asli → tanpa tint
	c.portrait_color = Color(0.75, 0.45, 0.15)
	c.max_hp = 1050
	c.move_speed = 210.0
	c.portrait_path = "res://assets/characters/asian_tiger/portrait.png"

	# Sprite Prabowo hasil ekstraksi atlas (gantikan placeholder KFM).
	var set := SpriteSet.load_set(TIGER_DIR)
	if not set.is_empty():
		c.frames = set["frames"]
		c.axis = set["axis"]
		c.canvas = set["canvas"]
		c.sprite_scale = 1.0          # frame sudah dinormalkan ke tinggi ~140px (≈ KFM)
		# pemetaan state → anim tiger
		c.anims = {
			"idle": "idle", "walk_fwd": "walk_fwd", "walk_back": "walk_back",
			"jump": "jump", "crouch": "crouch", "block": "block",
			"crouch_block": "block", "hit": "hit", "hit_low": "hit",
			"knockdown": "knockdown", "getup": "getup",
			"run": "run", "down": "down",       # lari (ketuk maju 2×) & tergeletak setelah jatuh
		}
		# normals pakai anim tiger (timing/hitbox tetap dari default)
		c.normals = c.normals.duplicate(true)
		c.normals["lp"]["anim"] = "lp"
		c.normals["hp"]["anim"] = "hp"
		c.normals["lk"]["anim"] = "lk"
		c.normals["hk"]["anim"] = "hk"
		c.normals["clp"]["anim"] = "lp"
		c.normals["chk"]["anim"] = "lk"
	c.skills = {
		# "stun": detik lawan terpaku (bintang berputar) setelah kena skill.
		# Skill 1 — Bad Word: makian muncul di atas kepala saat kuda-kuda, melayang pelan,
		# lalu menempel di kepala lawan selama ia terpaku.
		# anim per fase: "anim" (kuda-kuda) → "anim_active" → "anim_recovery" (semua pose sheet terpakai)
		"bad_word": {
			"name": "Bad Word", "anim": "bad_word_start", "anim_active": "bad_word_fire",
			"anim_recovery": "bad_word_end", "fx": "bad_word",
			"damage": 90, "startup": 1.0, "active": 0.15, "recovery": 0.60, "cost": 0, "cooldown": 2.0,
			"projectile": true, "stun": 2.2,
		},
		# Skill 2 — Joget Gemoy: tarian memicu shockwave area.
		"joget_gemoy": {
			"name": "Joget Gemoy", "anim": "joget_start", "anim_active": "joget_loop",
			"anim_recovery": "joget_end", "fx": "quake",
			"damage": 110, "startup": 1.20, "active": 0.60, "recovery": 0.60,   # cukup lama agar 5 pose tari terputar
			"knockback": 360.0, "cost": 0, "cooldown": 3.0, "stun": 1.8,
			"hb": {"off": Vector2(0, -30), "size": Vector2(260, 60)},
		},
		# Skill 3 — Kucing Asia: transformasi kucing, dash menyeruduk.
		"kucing_asia": {
			"name": "Kucing Asia", "anim": "kucing_start", "anim_active": "kucing_dash",
			"anim_recovery": "kucing_end", "fx": "cat_dash",
			"damage": 130, "startup": 0.55, "active": 0.80, "recovery": 0.55,   # dash lebih lama krn lebih pelan
			"knockback": 300.0, "dash_speed": 400.0, "cost": 0, "cooldown": 3.5,   # kucing lari lebih pelan
			"hb": {"off": Vector2(50, -55), "size": Vector2(70, 70)}, "stun": 1.5,
		},
		# Skill 4 — Monokotil Ultimate: dua biji raksasa, satu pecah jadi pecahan (tiap pecahan men-stun).
		"monokotil": {
			"name": "Monokotil Ultimate", "anim": "monokotil_start", "anim_active": "monokotil_start",
			"anim_recovery": "monokotil_end", "fx": "monokotil",
			"damage": 70, "startup": 1.10, "active": 0.30, "recovery": 0.90, "cost": 50, "cooldown": 6.0,
			"ultimate": true, "projectile": true, "stun": 1.6,
		},
	}
	return c

## Mr. Kol-Onel — sprite dari "Mr. Kol-Onel Sheet.png" (assets/raw/kolonel_src). 4 skill:
## Pokoknya Ada (muka membesar → senyum → sinar "-999"), Beast's Smile (duduk bersila →
## gigit bibir → kacamata → stun jarak jauh), Macho (topang dagu → stun dekat),
## Bobo Yuk (dress pink → naik ranjang → melayang menabrak lawan; ultimate).
const KOL_DIR := "res://assets/characters/kolonel/frames"

static func _kolonel() -> CharacterDef:
	var c := CharacterDef.new()
	c.id = "kolonel"
	c.display_name = "Mr. Kol-Onel"
	c.tint = Color(1, 1, 1)
	c.portrait_color = Color(0.2, 0.25, 0.42)
	c.max_hp = 1000
	c.move_speed = 225.0
	c.portrait_path = "res://assets/characters/kolonel/portrait.png"
	var set := SpriteSet.load_set(KOL_DIR)
	if not set.is_empty():
		c.frames = set["frames"]
		c.axis = set["axis"]
		c.canvas = set["canvas"]
		c.sprite_scale = 1.0
		c.anims = {
			"idle": "idle", "walk_fwd": "walk_fwd", "walk_back": "walk_back",
			"jump": "jump", "crouch": "landing", "block": "block", "crouch_block": "block",
			"hit": "hit", "hit_low": "hit", "knockdown": "knockdown", "getup": "getup",
			"run": "run", "down": "down",
		}
		# sheet tak punya pose tendangan: lk = pose lompat, hk = Serang 2 (tebasan)
		c.normals = c.normals.duplicate(true)
		c.normals["lp"]["anim"] = "lp"
		c.normals["hp"]["anim"] = "hp"
		c.normals["lk"]["anim"] = "lk"
		c.normals["hk"]["anim"] = "hp"
		c.normals["clp"]["anim"] = "lp"
		c.normals["chk"]["anim"] = "lk"
	c.skills = {
		# Skill 1 — Pokoknya Ada: muka membesar → senyum → sinar biru; popup "-999" saat kena.
		"pokoknya_ada": {
			"name": "Pokoknya Ada", "anim": "pokok_start", "anim_active": "pokok_fire",
			"anim_recovery": "pokok_fire", "fx": "pokok_beam",
			"damage": 190, "startup": 1.0, "active": 0.15, "recovery": 0.60, "cost": 0, "cooldown": 2.5,
			"projectile": true, "hit_text": "-999",
		},
		# Skill 2 — Beast's Smile: duduk bersila → gigit bibir → pakai kacamata → lawan terpaku (jarak jauh).
		"beasts_smile": {
			"name": "Beast's Smile", "anim": "beast_start", "anim_active": "beast_pose",
			"anim_recovery": "beast_pose", "fx": "gaze",
			"damage": 40, "startup": 1.30, "active": 0.30, "recovery": 0.70, "knockback": 60.0,
			"cost": 0, "cooldown": 3.5, "stun": 2.6, "stun_fx": "halo",
			"hb": {"off": Vector2(330, -60), "size": Vector2(640, 170)},
		},
		# Skill 3 — Macho: topang dagu → kacamata silang tangan → lawan terpaku (dekat).
		"macho": {
			"name": "Macho", "anim": "macho_start", "anim_active": "macho_pose",
			"anim_recovery": "macho_pose", "fx": "gaze",
			"damage": 70, "startup": 0.90, "active": 0.25, "recovery": 0.60, "knockback": 200.0,
			"cost": 0, "cooldown": 3.0, "stun": 1.9, "stun_fx": "halo",
			"hb": {"off": Vector2(150, -60), "size": Vector2(280, 160)},
		},
		# Skill 4 — Bobo Yuk (ultimate): dress pink → naik ranjang → melayang menabrak lawan (jejak hati).
		"bobo_yuk": {
			"name": "Bobo Yuk", "anim": "bobo_start", "anim_active": "bobo_fly",
			"anim_recovery": "bobo_end", "fx": "bobo_dash",
			"damage": 170, "startup": 1.20, "active": 0.80, "recovery": 0.70,
			"knockback": 380.0, "launch": -480.0, "dash_speed": 430.0, "cost": 50, "cooldown": 6.0,
			"ultimate": true,
			"hb": {"off": Vector2(60, -70), "size": Vector2(110, 110)},
		},
	}
	return c
