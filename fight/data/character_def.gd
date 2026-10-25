extends RefCounted
class_name CharacterDef

## Definisi satu karakter Fight (data-driven). Dibuat lewat CharacterRegistry.
## Menyimpan statistik, pemetaan state→animasi KFM, tabel normal (pukul/tendang),
## dan daftar id skill khusus. Dua karakter awal memakai frame KFM yang sama
## (placeholder) dengan tint & skill berbeda; Mr. Asian Tiger punya 4 skill satir.

var id: String = ""
var display_name: String = ""
var tint: Color = Color.WHITE
var portrait_color: Color = Color(0.3, 0.4, 0.6)

## Set aset sprite khusus karakter. Bila frames != null, Fighter memakainya (beserta
## axis/canvas/sprite_scale) alih-alih frame KFM bawaan.
var frames: SpriteFrames = null
var axis: Vector2 = Vector2.ZERO
var canvas: Vector2 = Vector2.ZERO
var sprite_scale: float = 1.0
## Gambar wajah untuk layar pilih karakter (opsional). Kosong = pakai pratinjau sprite.
var portrait_path: String = ""

var max_hp: int = 1000
var move_speed: float = 220.0
var jump_velocity: float = -560.0

## state animasi -> nama anim di SpriteFrames KFM
var anims := {
	"idle": "idle",
	"walk_fwd": "walk_fwd",
	"walk_back": "walk_back",
	"jump": "jump",
	"crouch": "crouch",
	"block": "guard",
	"crouch_block": "guard_crouch",
	"hit": "hurt",
	"hit_low": "hurt_low",
	"knockdown": "knockdown",
	"getup": "getup",
	"run": "run",           # lari maju (ketuk maju 2× lalu tahan)
	"down": "down",         # tergeletak setelah knockdown (opsional; KFM tak punya → tetap frame terakhir knockdown)
}

## Normal attacks: id -> data. Timing dalam detik.
## hb = hitbox {off: Vector2 (relatif, menghadap kanan), size: Vector2}
var normals := {
	"lp": {"anim": "stand_lp", "damage": 45, "startup": 0.08, "active": 0.06, "recovery": 0.18,
		"knockback": 120.0, "hb": {"off": Vector2(55, -95), "size": Vector2(55, 35)}},
	"hp": {"anim": "stand_hp", "damage": 90, "startup": 0.14, "active": 0.08, "recovery": 0.32,
		"knockback": 300.0, "hb": {"off": Vector2(62, -100), "size": Vector2(70, 45)}},
	"lk": {"anim": "stand_lk", "damage": 50, "startup": 0.10, "active": 0.07, "recovery": 0.22,
		"knockback": 150.0, "hb": {"off": Vector2(60, -55), "size": Vector2(65, 35)}},
	"hk": {"anim": "stand_hk", "damage": 95, "startup": 0.16, "active": 0.09, "recovery": 0.34,
		"knockback": 340.0, "hb": {"off": Vector2(68, -50), "size": Vector2(75, 45)}},
	"clp": {"anim": "crouch_lp", "damage": 40, "startup": 0.08, "active": 0.06, "recovery": 0.18,
		"knockback": 110.0, "crouch": true, "hb": {"off": Vector2(52, -40), "size": Vector2(55, 30)}},
	"chk": {"anim": "crouch_hk", "damage": 80, "startup": 0.14, "active": 0.10, "recovery": 0.36,
		"knockback": 260.0, "crouch": true, "low": true, "sweep": true,
		"hb": {"off": Vector2(60, -18), "size": Vector2(80, 28)}},
}

## Skill khusus: id -> data. "fx" dipakai fighter untuk memanggil efek yg sesuai.
var skills := {}

## input peta normal (keyboard P1). AI tak memakai ini.
## J=lp K=lk U=hp I=hk  (+ crouch -> clp/chk)

static func _base() -> CharacterDef:
	return CharacterDef.new()
