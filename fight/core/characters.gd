class_name Characters
extends RefCounted

## Diferenciación de los 2 shotos: mismos inputs, distintas propiedades.
##  - Kaze  (zoner paciente): mejor fireball (menos recovery), DP fiable, movilidad normal.
##  - Homura (rushdown):      fireball peor (más recovery), más movilidad, DP más fuerte.

static func stats(id: String) -> Dictionary:
	match id:
		"prabowo":
			return {
				"walk_fwd_speed": 190.0, "walk_back_speed": 150.0,
				"dash_fwd_speed": 450.0, "dash_fwd_frames": 13,
				"dash_back_speed": 380.0, "dash_back_frames": 13,
			}
		"homura":
			return {
				"walk_fwd_speed": 210.0, "walk_back_speed": 160.0,
				"dash_fwd_speed": 470.0, "dash_fwd_frames": 12,
				"dash_back_speed": 400.0, "dash_back_frames": 12,
			}
		_:  # kaze (por defecto)
			return {
				"walk_fwd_speed": 180.0, "walk_back_speed": 140.0,
				"dash_fwd_speed": 420.0, "dash_fwd_frames": 16,
				"dash_back_speed": 360.0, "dash_back_frames": 14,
			}

static func specials_for(id: String) -> Dictionary:
	var d := MoveSet.default_specials()
	if id == "homura":
		for k in ["hadouken.l", "hadouken.m", "hadouken.h"]:
			d[k].recovery = 42          # fireball peor
		for k in ["dp.l", "dp.m", "dp.h"]:
			d[k].damage += 10           # DP más fuerte
	elif id == "prabowo":
		_add_prabowo_skills(d)
	else:  # kaze
		for k in ["hadouken.l", "hadouken.m", "hadouken.h"]:
			d[k].recovery = 30          # mejor fireball
	return d

## Skill khas Prabowo (capres). Semua data-driven: motion + tombol ada di MoveData,
## dibaca Fighter.try_start_special(); judul muncul sebagai banner saat keluar.
const FX := "res://assets/prabowo/fx/"
static func _add_prabowo_skills(d: Dictionary) -> void:
	# 1) Gebrak Meja (236K): lempar meja lurus.
	var meja := MoveSet._m("Gebrak Meja", 12, 3, 30, 90, 22, 16, 12, 30.0, Vector2(40, -50), Vector2(0, 0), false, false, true)
	meja.is_special = true
	meja.self_move = Vector2(20.0, 0.0)
	meja.motion = [2, 3, 6]; meja.motion_button = "k"; meja.title = "GEBRAK MEJA!"
	meja.projectile_texture = FX + "table.png"; meja.projectile_speed = 320.0
	d["gebrak_meja"] = meja

	# 2) Bad Word (214P): makian kapital melayang mengejar.
	var bad := MoveSet._m("Bad Word", 10, 3, 26, 55, 16, 12, 10, 20.0, Vector2(40, -60), Vector2(0, 0))
	bad.is_special = true
	bad.motion = [2, 1, 4]; bad.motion_button = "p"; bad.title = "BAD WORD!"
	bad.projectile_text = "ANJING!"; bad.projectile_homing = true; bad.projectile_speed = 250.0
	d["bad_word"] = bad

	# 3) Macan Asia (623K): jeda sejenak, muka jadi macan, lalu mengejar lawan.
	var macan := MoveSet._m("Macan Asia", 80, 6, 30, 110, 24, 16, 16, 40.0, Vector2(30, -60), Vector2(0, 0))
	macan.is_special = true
	macan.invuln_startup = 8
	macan.motion = [6, 2, 3]; macan.motion_button = "k"; macan.title = "MACAN ASIA!"
	macan.face_overlay = FX + "tiger_face.png"
	macan.projectile_texture = FX + "tiger_face.png"; macan.projectile_homing = true; macan.projectile_speed = 320.0
	d["macan_asia"] = macan

	# 4) Kampreters (236P): keluar monyet-monyet yang mengejar lawan.
	var kam := MoveSet._m("Kampreters", 14, 3, 30, 40, 14, 10, 8, 20.0, Vector2(30, -50), Vector2(0, 0))
	kam.is_special = true
	kam.motion = [2, 3, 6]; kam.motion_button = "p"; kam.title = "KAMPRETERS!"
	kam.projectile_texture = FX + "monkey.png"; kam.projectile_homing = true
	kam.projectile_count = 3; kam.projectile_speed = 210.0
	d["kampreters"] = kam
