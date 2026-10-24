class_name RigAnimator
extends Node2D

## Procedural cutout rig for a Fight hero built from a SINGLE full-body image sliced
## into parts. Instead of hand-drawn frames, limb rotations are computed per frame,
## so one drawing yields idle / walk / crouch / jump / attack / guard / hurt motion.
##
## It exposes play(anim_name) using the SAME names the Fighter already requests
## (idle, walk_fwd, walk_back, crouch, jump, run, stand_lp..hk, crouch_*, guard,
## guard_crouch, hurt, hurt_low, knockdown, getup, ...). The Fighter flips facing by
## scaling this node's x.
##
## Part nodes (Sprite2D), found by name; ALL optional (missing parts are skipped).
## Pivot convention: each part's Sprite2D POSITION = its joint; set the Sprite2D
## `offset` so the art hangs from that joint. Lower limb parts are children of the
## upper ones so they inherit rotation (elbow/knee bend).
##   Hip (root pivot at feet-up) → Torso → Head
##   Torso → ArmBackUpper → ArmBackLower ;  ArmFrontUpper → ArmFrontLower
##   Hip   → LegBackUpper  → LegBackLower ;  LegFrontUpper → LegFrontLower

const PARTS := [
	"Hip", "Torso", "Head",
	"ArmBackUpper", "ArmBackLower", "ArmFrontUpper", "ArmFrontLower",
	"LegBackUpper", "LegBackLower", "LegFrontUpper", "LegFrontLower",
]

## Folder with one PNG per part, named like the nodes (Head.png, Torso.png,
## ArmFrontUpper.png, ...). Produced by tools/slice_fullbody.py. Set before the rig
## enters the tree, or via load_parts().
@export var parts_dir: String = ""

var _p: Dictionary = {}          # name -> Node2D (or null)
var _rest_pos: Dictionary = {}   # name -> rest position (for bob/crouch offsets)
var _anim := "idle"
var _t := 0.0                    # time in current anim
var _tint := Color(1, 1, 1, 1)


func _ready() -> void:
	for n in PARTS:
		var node := find_child(n, true, false) as Node2D
		_p[n] = node
		if node != null:
			_rest_pos[n] = node.position
	if parts_dir != "":
		load_parts(parts_dir)
	set_modulate_all(_tint)


## Assign each part Sprite2D its texture from <dir>/<PartName>.png (if present).
## Parts without an image keep whatever the scene set (or stay empty).
func load_parts(dir: String) -> void:
	parts_dir = dir
	for n in PARTS:
		var node = _p.get(n)
		if node == null:
			node = find_child(n, true, false)
			_p[n] = node
			if node != null and not _rest_pos.has(n):
				_rest_pos[n] = (node as Node2D).position
		if node is Sprite2D:
			var path := "%s/%s.png" % [dir.rstrip("/"), n]
			if ResourceLoader.exists(path):
				(node as Sprite2D).texture = load(path)


func set_tint(c: Color) -> void:
	_tint = c
	set_modulate_all(c)


func set_modulate_all(c: Color) -> void:
	if c.a <= 0.0:
		return
	for n in _p:
		if _p[n] != null:
			(_p[n] as CanvasItem).modulate = c


func play(anim_name: String) -> void:
	if anim_name == _anim:
		return
	_anim = anim_name
	_t = 0.0


func _process(delta: float) -> void:
	_t += delta
	_pose()


# --- Posing -----------------------------------------------------------------

func _set_rot(name: String, deg: float) -> void:
	var node: Node2D = _p.get(name)
	if node != null:
		node.rotation = deg_to_rad(deg)


func _set_off_y(name: String, dy: float) -> void:
	var node: Node2D = _p.get(name)
	if node != null and _rest_pos.has(name):
		node.position = (_rest_pos[name] as Vector2) + Vector2(0, dy)


func _reset() -> void:
	for n in PARTS:
		_set_rot(n, 0.0)
		if _rest_pos.has(n) and _p[n] != null:
			(_p[n] as Node2D).position = _rest_pos[n]


func _pose() -> void:
	_reset()
	match _anim:
		"walk_fwd", "walk_back":
			_pose_walk(6.0, 18.0)
		"run":
			_pose_walk(11.0, 26.0)
		"crouch", "guard_crouch":
			_pose_crouch()
		"jump", "jump_startup":
			_pose_jump()
		"guard":
			_pose_guard()
		"hurt", "hurt_low":
			_pose_lean(-16.0)
		"knockdown", "getup":
			_pose_knockdown()
		_:
			if _anim.begins_with("stand_") or _anim.begins_with("cr.") or _anim.begins_with("j.") \
			   or _anim in ["palm", "upper", "knee", "throw"]:
				_pose_attack()
			else:
				_pose_idle()


func _pose_idle() -> void:
	var bob := sin(_t * 3.0) * 1.5
	_set_off_y("Torso", bob)
	_set_off_y("Head", bob)
	_set_rot("ArmFrontUpper", 6.0 + sin(_t * 3.0) * 2.0)
	_set_rot("ArmBackUpper", -6.0 - sin(_t * 3.0) * 2.0)


func _pose_walk(speed: float, swing: float) -> void:
	var ph := _t * speed
	var s := sin(ph) * swing
	_set_rot("LegFrontUpper", s)
	_set_rot("LegBackUpper", -s)
	_set_rot("LegFrontLower", max(0.0, -s) * 0.8)
	_set_rot("LegBackLower", max(0.0, s) * 0.8)
	_set_rot("ArmFrontUpper", -s * 0.7)
	_set_rot("ArmBackUpper", s * 0.7)
	_set_off_y("Torso", absf(sin(ph)) * -2.0)


func _pose_crouch() -> void:
	_set_off_y("Hip", 14.0)
	_set_off_y("Torso", 6.0)
	_set_rot("LegFrontUpper", 28.0)
	_set_rot("LegFrontLower", -40.0)
	_set_rot("LegBackUpper", -28.0)
	_set_rot("LegBackLower", 40.0)
	_set_rot("Torso", 8.0)


func _pose_jump() -> void:
	_set_rot("LegFrontUpper", 34.0)
	_set_rot("LegFrontLower", -50.0)
	_set_rot("LegBackUpper", 24.0)
	_set_rot("LegBackLower", -40.0)
	_set_rot("ArmFrontUpper", -24.0)
	_set_rot("ArmBackUpper", -30.0)


func _pose_guard() -> void:
	_set_rot("Torso", -6.0)
	_set_rot("ArmFrontUpper", -70.0)
	_set_rot("ArmFrontLower", -60.0)
	_set_rot("ArmBackUpper", -50.0)


func _pose_lean(deg: float) -> void:
	_set_rot("Torso", deg)
	_set_rot("Head", deg * 0.5)


func _pose_knockdown() -> void:
	_set_rot("Hip", -75.0)
	_set_off_y("Hip", 10.0)


func _pose_attack() -> void:
	# One-shot-ish extend based on time in anim (startup -> strike -> recover).
	var k := clampf(_t / 0.18, 0.0, 1.0)         # 0..1 over ~180ms
	var strike := sin(k * PI)                     # peak mid-move
	var is_kick := _anim.ends_with("lk") or _anim.ends_with("mk") or _anim.ends_with("hk") or _anim == "knee"
	if is_kick:
		_set_rot("LegFrontUpper", 70.0 * strike)
		_set_rot("LegFrontLower", -30.0 * (1.0 - strike))
		_set_rot("Torso", -6.0 * strike)
	else:
		_set_rot("ArmFrontUpper", -84.0 * strike)
		_set_rot("ArmFrontLower", -20.0 * (1.0 - strike))
		_set_rot("Torso", 6.0 * strike)
		_set_rot("ArmBackUpper", 10.0 * strike)
