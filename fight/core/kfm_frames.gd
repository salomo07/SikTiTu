class_name KfmFrames
extends RefCounted

## Builds a SpriteFrames from PNG frames + a manifest.json. Supports per-hero
## sprite directories so you can ship your own pixel-art fighters.
##
## ADD-YOUR-OWN-HERO ART:
##   Create res://assets/<dir>/ laid out exactly like assets/kfm/ -- one folder
##   per animation name (idle, walk_fwd, stand_lp, ...), frames as 000.png,
##   001.png, ... and a manifest.json with the same shape as assets/kfm's:
##     {"canvas":[w,h], "axis":[x,y], "anims":{"idle":{"frames":N,"durs":[...],"loop":true}, ...}}
##   Then set `sprite_dir` to "<dir>" in fight/data/hero_db.gd. Missing dirs or a
##   missing manifest fall back to the shared Kung-Fu-Man art, so a half-finished
##   hero still runs.

const KFM_BASE := "res://assets/kfm"

# Cache per resolved base path (shared by both fighters; one hero's art is built once).
static var _frames_by_base: Dictionary = {}
static var _axis_by_base: Dictionary = {}
static var _canvas_by_base: Dictionary = {}

## Backwards-compatible accessors (default = Kung-Fu-Man).
static var canvas: Vector2 = Vector2.ZERO
static var axis: Vector2 = Vector2.ZERO

static func get_frames() -> SpriteFrames:
	var sf := get_frames_for("")
	canvas = canvas_for("")
	axis = axis_for("")
	return sf

## Frames for a hero's sprite_dir ("" = Kung-Fu-Man). Falls back to KFM if the
## directory has no usable manifest/frames.
static func get_frames_for(dir: String) -> SpriteFrames:
	var base := _base_for(dir)
	if not _frames_by_base.has(base):
		_build_from(base)
	var sf = _frames_by_base.get(base)
	if sf == null and base != KFM_BASE:
		return get_frames_for("")
	return sf

static func axis_for(dir: String) -> Vector2:
	var base := _base_for(dir)
	if not _frames_by_base.has(base):
		_build_from(base)
	if _axis_by_base.has(base):
		return _axis_by_base[base]
	if base != KFM_BASE:
		return axis_for("")
	return Vector2.ZERO

static func canvas_for(dir: String) -> Vector2:
	var base := _base_for(dir)
	if not _frames_by_base.has(base):
		_build_from(base)
	if _canvas_by_base.has(base):
		return _canvas_by_base[base]
	if base != KFM_BASE:
		return canvas_for("")
	return Vector2.ZERO

static func _base_for(dir: String) -> String:
	var d := dir.strip_edges()
	if d == "":
		return KFM_BASE
	if d.begins_with("res://"):
		return d.trim_suffix("/")
	return "res://assets/" + d.trim_suffix("/")

static func _build_from(base: String) -> void:
	# Mark as attempted so we don't rebuild a missing dir every frame.
	_frames_by_base[base] = null
	var f := FileAccess.open(base + "/manifest.json", FileAccess.READ)
	if f == null:
		return
	var m = JSON.parse_string(f.get_as_text())
	if m == null or not (m is Dictionary) or not m.has("anims"):
		return
	_canvas_by_base[base] = Vector2(m["canvas"][0], m["canvas"][1])
	_axis_by_base[base] = Vector2(m["axis"][0], m["axis"][1])
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for anim in m["anims"]:
		var info = m["anims"][anim]
		sf.add_animation(anim)
		sf.set_animation_loop(anim, bool(info["loop"]))
		sf.set_animation_speed(anim, 60.0)   # durations in 60fps ticks
		var n := int(info["frames"])
		for i in n:
			var tex = load("%s/%s/%03d.png" % [base, anim, i])
			if tex != null:
				sf.add_frame(anim, tex, float(info["durs"][i]))
	# Per-anim fallback: a partial hero (only idle/walk/… sliced) borrows every
	# missing animation from Kung-Fu-Man so attacks/jump/crouch still play.
	if base != KFM_BASE:
		var kfm := get_frames_for("")
		if kfm != null:
			for anim in kfm.get_animation_names():
				if not sf.has_animation(anim) or sf.get_frame_count(anim) == 0:
					if sf.has_animation(anim):
						sf.remove_animation(anim)
					sf.add_animation(anim)
					sf.set_animation_loop(anim, kfm.get_animation_loop(anim))
					sf.set_animation_speed(anim, kfm.get_animation_speed(anim))
					for i in kfm.get_frame_count(anim):
						sf.add_frame(anim, kfm.get_frame_texture(anim, i), kfm.get_frame_duration(anim, i))
	_frames_by_base[base] = sf
