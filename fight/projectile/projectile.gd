class_name Projectile
extends Node2D

## Proyectil / entidad de habilidad. Movimiento y resolución los coordina MatchManager
## (determinista y centralizado). Soporta recto (bola de fuego, mesa lanzada) y HOMING
## (persigue al rival: makian / macan / monyet), con visual de textura o de texto.

var velocity_x: float = 0.0
var team: int = 0
var owner_facing: int = 1
var move: MoveData = null

# Habilidades personalizadas (Prabowo): perseguir, vida limitada, visual propio.
var homing: bool = false
var speed: float = 0.0
var ttl: float = 0.0          # vida en segundos (0 = ignora, solo límites de pantalla)
var _half := Vector2(12, 10)  # media-caja de golpe

func _ready() -> void:
	add_to_group("projectile")

func set_visual_texture(path: String) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return
	var tex = load(path)
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	add_child(s)
	_half = Vector2(tex.get_width(), tex.get_height()) * 0.5

func set_visual_text(txt: String) -> void:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	l.position = Vector2(-float(txt.length()) * 6.0, -16.0)
	add_child(l)
	_half = Vector2(maxf(18.0, txt.length() * 6.0), 14.0)

func rect() -> Rect2:
	return Rect2(global_position - _half, _half * 2.0)
