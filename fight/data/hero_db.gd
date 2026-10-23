class_name HeroDB
extends RefCounted

## Registry of selectable heroes for the Fight mode.
##
## ADDING A NEW HERO (e.g. turning a photo of Raisha into a 2D pixel-art fighter):
##   1. Add an entry to ROSTER below with a unique `id`.
##   2. `archetype` decides base stats + special-move tuning: use "kaze" (patient
##      zoner) or "homura" (rushdown). See fight/core/characters.gd.
##   3. `color` tints the silhouette / sprite. Pick anything.
##   4. `sprite_dir` is OPTIONAL. Leave "" to reuse the shared Kung-Fu-Man sprites.
##      To ship custom art, drop frame folders under res://assets/<dir>/ laid out
##      exactly like assets/kfm/ (same anim names + manifest.json) and put <dir> here.
##   That's it — hero_select picks it up automatically.

const ROSTER: Array[Dictionary] = [
	{"id": "kaze",    "name": "KAZE",    "archetype": "kaze",   "color": Color(0.25, 0.55, 0.95), "sprite_dir": ""},
	{"id": "homura",  "name": "HOMURA",  "archetype": "homura", "color": Color(0.95, 0.40, 0.32), "sprite_dir": ""},
	{"id": "petugas", "name": "PETUGAS", "archetype": "kaze",   "color": Color(0.30, 0.80, 0.45), "sprite_dir": ""},
	{"id": "raisha",  "name": "RAISHA",  "archetype": "homura", "color": Color(0.95, 0.45, 0.80), "sprite_dir": ""},
	# Example of a hero shipping its OWN pixel-art (assets/heroes/placeholder/).
	# Demonstrates the sprite_dir pipeline end-to-end; replace the art with yours.
	{"id": "custom",  "name": "CUSTOM",  "archetype": "homura", "color": Color(1, 1, 1),          "sprite_dir": "heroes/placeholder"},
	# Frame-based hero sliced from a design sheet (tools/slice_sheet.py). Only
	# idle/walk/run/hurt are custom; other anims fall back to KFM (see kfm_frames).
	{"id": "prabowo", "name": "PRABOWO", "archetype": "prabowo", "color": Color(1, 1, 1),          "sprite_dir": "prabowo"},
]

static func all() -> Array[Dictionary]:
	return ROSTER

static func get_hero(id: String) -> Dictionary:
	for h in ROSTER:
		if h["id"] == id:
			return h
	return ROSTER[0]

static func default_id() -> String:
	return ROSTER[0]["id"]
