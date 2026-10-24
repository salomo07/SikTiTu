extends RefCounted
class_name KfmFrames

## Membangun SpriteFrames dari aset KFM (assets/kfm/) saat runtime, memakai
## metadata di manifest.json (canvas, axis, per-anim frames+durs+loop).
##
## Kenapa runtime, bukan .tres: frame KFM ada 300+ file; membangun di kode membuat
## sumbernya data-driven (tambah/ubah anim cukup lewat manifest) dan menghindari
## resource raksasa yang rapuh. Satu hasil build di-cache & dibagikan antar fighter.

const KFM_DIR := "res://assets/kfm"
const MANIFEST_PATH := "res://assets/kfm/manifest.json"

## Axis (titik kaki) dari manifest; dipakai fighter untuk meng-offset sprite agar
## origin node = telapak kaki karakter. Diisi saat build().
static var axis := Vector2(55, 139)
static var canvas := Vector2(137, 148)

static var _cache: SpriteFrames = null
static var _manifest: Dictionary = {}

## Kembalikan SpriteFrames siap pakai (di-cache). Mengembalikan null bila manifest
## tak terbaca — pemanggil wajib memeriksa.
static func get_frames() -> SpriteFrames:
	if _cache != null:
		return _cache
	_cache = _build()
	return _cache

## Baca & cache manifest. Mengembalikan {} bila gagal.
static func get_manifest() -> Dictionary:
	if not _manifest.is_empty():
		return _manifest
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_error("KfmFrames: manifest tidak ditemukan: %s" % MANIFEST_PATH)
		return {}
	var txt := FileAccess.get_file_as_string(MANIFEST_PATH)
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("KfmFrames: manifest bukan JSON object")
		return {}
	_manifest = parsed
	if _manifest.has("axis"):
		axis = Vector2(_manifest["axis"][0], _manifest["axis"][1])
	if _manifest.has("canvas"):
		canvas = Vector2(_manifest["canvas"][0], _manifest["canvas"][1])
	return _manifest

static func _build() -> SpriteFrames:
	var man := get_manifest()
	if man.is_empty() or not man.has("anims"):
		return null
	var frames := SpriteFrames.new()
	# SpriteFrames selalu lahir dengan anim "default"; hapus setelah menambah milik kita.
	var anims: Dictionary = man["anims"]
	for anim_name in anims.keys():
		var info: Dictionary = anims[anim_name]
		var count: int = int(info.get("frames", 0))
		var durs: Array = info.get("durs", [])
		var loop: bool = bool(info.get("loop", false))
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, loop)
		# fps 60: durasi relatif tiap frame = dur (tick) → frame tampil dur/60 detik.
		frames.set_animation_speed(anim_name, 60.0)
		for i in count:
			var tex_path := "%s/%s/%03d.png" % [KFM_DIR, anim_name, i]
			if not ResourceLoader.exists(tex_path):
				push_warning("KfmFrames: frame hilang %s" % tex_path)
				continue
			var tex: Texture2D = load(tex_path)
			var dur: float = 1.0
			if i < durs.size():
				dur = float(durs[i])
			frames.add_frame(anim_name, tex, dur)
	if frames.has_animation("default"):
		frames.remove_animation("default")
	return frames

## Offset sprite agar titik kaki (axis) berada di origin node fighter.
static func sprite_offset() -> Vector2:
	get_manifest()
	return -axis
