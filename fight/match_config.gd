extends Node
## Autoload "FightConfig" — pilihan yang dibawa antar-scene Fight:
## karakter P1/P2, arena, dan mode (vs AI / lokal 2 pemain) + tingkat AI.
## Juga memindai daftar arena dari assets/textures/arena (data-driven).

enum Mode { VS_AI, VS_PLAYER }
enum AILevel { EASY, NORMAL, HARD }

const ARENA_DIR := "res://assets/textures/arena"

var p1_char: String = "asian_tiger"
var p2_char: String = "kfm"
var arena_id: String = "banjir"
var mode: int = Mode.VS_AI
var ai_level: int = AILevel.NORMAL
var rounds_to_win: int = 2        # best-of-3
var char_scale: float = 1.35      # skala node petarung (tubuh+hitbox+sprite) di arena
var fx_scale: float = 1.4         # pembesar tambahan untuk efek skill (relatif ke ukuran karakter)

## Daftar arena: [{id, path, name}]. Scan sekali, di-cache.
var _arenas: Array = []

func get_arenas() -> Array:
	if not _arenas.is_empty():
		return _arenas
	var dir := DirAccess.open(ARENA_DIR)
	if dir == null:
		push_error("FightConfig: tak bisa membuka %s" % ARENA_DIR)
		return _arenas
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".png"):
			var id := fname.get_basename()
			_arenas.append({
				"id": id,
				"path": "%s/%s" % [ARENA_DIR, fname],
				"name": _pretty(id),
			})
		fname = dir.get_next()
	dir.list_dir_end()
	_arenas.sort_custom(func(a, b): return a["id"] < b["id"])
	return _arenas

func arena_path(id: String) -> String:
	for a in get_arenas():
		if a["id"] == id:
			return a["path"]
	# fallback ke arena pertama bila id tak ketemu
	var list := get_arenas()
	return list[0]["path"] if not list.is_empty() else ""

func _pretty(id: String) -> String:
	return id.capitalize()
