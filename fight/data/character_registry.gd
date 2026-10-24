extends RefCounted
class_name CharacterRegistry

## Registry karakter Fight. Menambah karakter = menambah fungsi pembuat di sini.
## Dua karakter awal berbagi frame KFM (placeholder) dengan tint & skill berbeda.

## id urut untuk layar pilih karakter.
static func ids() -> Array[String]:
	return ["kfm", "asian_tiger"]

static func get_def(id: String) -> CharacterDef:
	match id:
		"kfm": return _kfm()
		"asian_tiger": return _asian_tiger()
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
			"knockback": 420.0, "cost": 0, "cooldown": 2.0,
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
		# Skill 1 — Bad Word: proyektil teks kapital.
		"bad_word": {
			"name": "Bad Word", "anim": "bad_word", "fx": "bad_word",
			"damage": 90, "startup": 0.60, "active": 0.15, "recovery": 0.60, "cost": 0, "cooldown": 1.5,
			"projectile": true,
		},
		# Skill 2 — Joget Gemoy: tarian memicu shockwave area.
		"joget_gemoy": {
			"name": "Joget Gemoy", "anim": "joget", "fx": "quake",
			"damage": 110, "startup": 1.20, "active": 0.60, "recovery": 0.60,   # cukup lama agar 5 pose tari terputar
			"knockback": 360.0, "cost": 0, "cooldown": 3.0,
			"hb": {"off": Vector2(0, -30), "size": Vector2(260, 60)},
		},
		# Skill 3 — Kucing Asia: transformasi kucing, dash menyeruduk.
		"kucing_asia": {
			"name": "Kucing Asia", "anim": "kucing", "fx": "cat_dash",
			"damage": 130, "startup": 0.55, "active": 0.80, "recovery": 0.55,   # dash lebih lama krn lebih pelan
			"knockback": 300.0, "dash_speed": 400.0, "cost": 0, "cooldown": 3.5,   # kucing lari lebih pelan
			"hb": {"off": Vector2(50, -55), "size": Vector2(70, 70)},
		},
		# Skill 4 — Monokotil Ultimate: dua biji raksasa, satu pecah jadi pecahan.
		"monokotil": {
			"name": "Monokotil Ultimate", "anim": "monokotil", "fx": "monokotil",
			"damage": 70, "startup": 1.10, "active": 0.30, "recovery": 0.90, "cost": 50, "cooldown": 6.0,
			"ultimate": true, "projectile": true,
		},
	}
	return c
