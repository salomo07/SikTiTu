extends CanvasLayer
class_name FightHUD

## HUD mode Fight (dibangun via kode). Health bar P1/P2 dengan "chip" yang menyusut
## halus, bar meter skill, timer tengah, pip ronde, banner ("RONDE 1 / FIGHT! / K.O.").

var _hp1: ColorRect
var _hp1_bg: ColorRect
var _hp2: ColorRect
var _hp2_bg: ColorRect
var _meter1: ColorRect
var _meter2: ColorRect
var _timer_lbl: Label
var _name1: Label
var _name2: Label
var _pips1: HBoxContainer
var _pips2: HBoxContainer
var _banner: Label
var _bar_w := 440.0
var _rounds_total := 2

func _ready() -> void:
	layer = 10
	var vw := get_viewport().get_visible_rect().size.x
	_bar_w = clampf(vw * 0.4, 300, 520)

	_name1 = _mk_label(Vector2(24, 54), 22, HORIZONTAL_ALIGNMENT_LEFT)
	_name2 = _mk_label(Vector2(vw - 24 - 260, 54), 22, HORIZONTAL_ALIGNMENT_RIGHT)
	_name2.size.x = 260

	# health bars
	_hp1_bg = _mk_rect(Vector2(24, 24), Vector2(_bar_w, 26), Color(0.1, 0.1, 0.12, 0.9))
	_hp1 = _mk_rect(Vector2(24, 24), Vector2(_bar_w, 26), Color(0.9, 0.25, 0.2))
	_hp2_bg = _mk_rect(Vector2(vw - 24 - _bar_w, 24), Vector2(_bar_w, 26), Color(0.1, 0.1, 0.12, 0.9))
	_hp2 = _mk_rect(Vector2(vw - 24, 24), Vector2(_bar_w, 26), Color(0.9, 0.25, 0.2))
	_hp2.pivot_offset = Vector2(_bar_w, 0)
	# P2 bar menyusut dari kanan: pakai posisi kanan & grow_horizontal
	_hp2.position = Vector2(vw - 24 - _bar_w, 24)
	_hp2_right = vw - 24

	# meter bars (tipis, di bawah health)
	_meter1 = _mk_rect(Vector2(24, 54 + 26), Vector2(_bar_w * 0.6, 8), Color(0.3, 0.7, 1.0))
	_meter1.position = Vector2(24, 82)
	_meter2 = _mk_rect(Vector2(vw - 24 - _bar_w * 0.6, 82), Vector2(_bar_w * 0.6, 8), Color(0.3, 0.7, 1.0))
	_meter2_right = vw - 24

	_timer_lbl = _mk_label(Vector2(vw / 2 - 60, 20), 44, HORIZONTAL_ALIGNMENT_CENTER)
	_timer_lbl.size.x = 120

	_pips1 = HBoxContainer.new()
	_pips1.position = Vector2(24, 96)
	add_child(_pips1)
	_pips2 = HBoxContainer.new()
	_pips2.position = Vector2(vw - 24 - 80, 96)
	_pips2.size.x = 80
	_pips2.alignment = BoxContainer.ALIGNMENT_END
	add_child(_pips2)

	_banner = _mk_label(Vector2(0, get_viewport().get_visible_rect().size.y * 0.32), 64, HORIZONTAL_ALIGNMENT_CENTER)
	_banner.size.x = vw
	_banner.position.x = 0
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.visible = false

	# judul skill (terpisah dari banner ronde): muncul tiap karakter memakai skill
	_skill = _mk_label(Vector2(0, get_viewport().get_visible_rect().size.y * 0.46), 52, HORIZONTAL_ALIGNMENT_CENTER)
	_skill.size.x = vw
	_skill.position.x = 0
	_skill.add_theme_color_override("font_outline_color", Color.BLACK)
	_skill.add_theme_constant_override("outline_size", 12)
	_skill.visible = false

var _hp2_right := 0.0
var _meter2_right := 0.0

func setup(name1: String, name2: String, rounds_total: int) -> void:
	_rounds_total = rounds_total
	_name1.text = name1
	_name2.text = name2
	set_rounds(0, 0)

func set_hp(side: int, hp: int, maxhp: int) -> void:
	var frac := clampf(float(hp) / float(maxi(1, maxhp)), 0, 1)
	var target := _bar_w * frac
	if side == 1:
		var tw := create_tween()
		tw.tween_property(_hp1, "size:x", target, 0.18).set_trans(Tween.TRANS_CUBIC)
	else:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_hp2, "size:x", target, 0.18).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(_hp2, "position:x", _hp2_right - target, 0.18).set_trans(Tween.TRANS_CUBIC)

func set_meter(side: int, val: float) -> void:
	var w := _bar_w * 0.6 * clampf(val / 100.0, 0, 1)
	if side == 1:
		_meter1.size.x = w
	else:
		_meter2.size.x = w
		_meter2.position.x = _meter2_right - w

func set_timer(sec: int) -> void:
	_timer_lbl.text = str(maxi(0, sec))

func set_rounds(w1: int, w2: int) -> void:
	_fill_pips(_pips1, w1)
	_fill_pips(_pips2, w2)

func _fill_pips(box: HBoxContainer, wins: int) -> void:
	for c in box.get_children():
		c.queue_free()
	for i in _rounds_total:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(18, 18)
		pip.color = Color(1, 0.85, 0.2) if i < wins else Color(0.25, 0.25, 0.3)
		box.add_child(pip)

func banner(text: String, hold := 1.0) -> void:
	_banner.text = text
	_banner.visible = true
	_banner.modulate.a = 1.0
	_banner.scale = Vector2(0.6, 0.6)
	_banner.pivot_offset = Vector2(_banner.size.x / 2, _banner.size.y / 2)
	var tw := create_tween()
	tw.tween_property(_banner, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): _banner.visible = false)

var _skill: Label
var _skill_tw: Tween

## Judul skill: pop-in besar, tahan, lalu memudar. Warna oranye untuk ultimate.
func skill_title(text: String, ultimate: bool = false) -> void:
	if _skill_tw != null and _skill_tw.is_valid():
		_skill_tw.kill()
	_skill.text = text
	_skill.add_theme_color_override("font_color", Color(1.0, 0.6, 0.15) if ultimate else Color(1.0, 0.92, 0.35))
	_skill.visible = true
	_skill.modulate.a = 1.0
	_skill.pivot_offset = Vector2(_skill.size.x / 2, _skill.size.y / 2)
	_skill.scale = Vector2(0.5, 0.5)
	_skill_tw = create_tween()
	_skill_tw.tween_property(_skill, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_skill_tw.tween_property(_skill, "scale", Vector2(1, 1), 0.10)
	_skill_tw.tween_interval(1.1 if ultimate else 0.8)
	_skill_tw.tween_property(_skill, "modulate:a", 0.0, 0.35)
	_skill_tw.tween_callback(func(): _skill.visible = false)

func banner_persist(text: String) -> void:
	_banner.text = text
	_banner.visible = true
	_banner.modulate.a = 1.0
	_banner.scale = Vector2(1, 1)

# ---- util ----
func _mk_rect(pos: Vector2, size: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = col
	add_child(r)
	return r

func _mk_label(pos: Vector2, fsize: int, align: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.horizontal_alignment = align
	add_child(l)
	return l
