extends RefCounted
class_name SpriteSet

## Loader SpriteFrames generik dari folder frame + manifest.json
## (dipakai Mr. Asian Tiger; KFM punya loader sendiri KfmFrames).
## manifest: {"canvas":[w,h], "axis":[x,y], "anims": {name:{frames:int, loop:bool, durs?:[..]}}}
## Mengembalikan {frames: SpriteFrames, axis: Vector2, canvas: Vector2} (di-cache per-dir).

static var _cache := {}

static func load_set(dir: String, default_fps := 12.0) -> Dictionary:
	if _cache.has(dir):
		return _cache[dir]
	var man_path := dir.path_join("manifest.json")
	if not FileAccess.file_exists(man_path):
		push_error("SpriteSet: manifest tak ada: %s" % man_path)
		return {}
	var man = JSON.parse_string(FileAccess.get_file_as_string(man_path))
	if typeof(man) != TYPE_DICTIONARY or not man.has("anims"):
		push_error("SpriteSet: manifest invalid: %s" % man_path)
		return {}
	var canvas := Vector2(man.get("canvas", [120, 120])[0], man.get("canvas", [120, 120])[1])
	var axis := Vector2(man.get("axis", [60, 106])[0], man.get("axis", [60, 106])[1])
	var frames := SpriteFrames.new()
	var anims: Dictionary = man["anims"]
	for name in anims.keys():
		var info: Dictionary = anims[name]
		var count: int = int(info.get("frames", 0))
		var loop: bool = bool(info.get("loop", false))
		var durs: Array = info.get("durs", [])
		frames.add_animation(name)
		frames.set_animation_loop(name, loop)
		# fps per-anim dari manifest ("fps"); durs (tick) memakai 60 fps + durasi relatif
		var fps: float = float(info.get("fps", default_fps))
		frames.set_animation_speed(name, fps if durs.is_empty() else 60.0)
		for i in count:
			var p := dir.path_join("%s/%03d.png" % [name, i])
			if not ResourceLoader.exists(p):
				push_warning("SpriteSet: frame hilang %s" % p)
				continue
			var tex: Texture2D = load(p)
			var dur := 1.0
			if i < durs.size():
				dur = float(durs[i])
			frames.add_frame(name, tex, dur)
	if frames.has_animation("default"):
		frames.remove_animation("default")
	var result := {"frames": frames, "axis": axis, "canvas": canvas}
	_cache[dir] = result
	return result
