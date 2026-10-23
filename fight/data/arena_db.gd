class_name ArenaDB
extends RefCounted

## Registry of selectable arenas (backgrounds) for the Fight mode.
##
## ADDING A NEW ARENA (e.g. "inside the palace", "in front of the DPR building"):
##   1. Add an entry to ARENAS below with a unique `id`.
##   2. For a quick vector-art arena, just tune the four colors.
##   3. For a photo/pixel-art backdrop, drop an image under res://assets/arenas/
##      and set `image` to its res:// path (e.g. "res://assets/arenas/istana.png").
##      When `image` is set it is drawn stretched behind the stage; the colors are
##      still used as a fallback until the image is imported.
##   match_manager.gd reads the selected arena from GameConfig and applies it.

const ARENAS: Array[Dictionary] = [
	{"id": "dojo",        "name": "DOJO",            "bg": Color(0.075, 0.083, 0.117), "back": Color(0.086, 0.094, 0.141), "accent": Color(0.098, 0.106, 0.157), "floor": Color(0.129, 0.117, 0.164), "image": ""},
	{"id": "istana",      "name": "ISTANA",          "bg": Color(0.20, 0.15, 0.07),    "back": Color(0.33, 0.24, 0.10),    "accent": Color(0.55, 0.42, 0.16),    "floor": Color(0.18, 0.13, 0.06),    "image": "res://assets/arenas/istana.png"},
	{"id": "dpr",         "name": "GEDUNG DPR",      "bg": Color(0.10, 0.13, 0.15),    "back": Color(0.16, 0.22, 0.24),    "accent": Color(0.30, 0.42, 0.45),    "floor": Color(0.12, 0.15, 0.16),    "image": ""},
	{"id": "forest_fire", "name": "HUTAN TERBAKAR",  "bg": Color(0.22, 0.09, 0.04),    "back": Color(0.40, 0.14, 0.05),    "accent": Color(0.72, 0.30, 0.08),    "floor": Color(0.15, 0.08, 0.05),    "image": ""},
]

static func all() -> Array[Dictionary]:
	return ARENAS

static func get_arena(id: String) -> Dictionary:
	for a in ARENAS:
		if a["id"] == id:
			return a
	return ARENAS[0]

static func default_id() -> String:
	return ARENAS[0]["id"]
