extends Control
## Layar pilih karakter mode Fight. P1 & P2 masing-masing memilih (termasuk Mr. Asian
## Tiger), pilih mode (vs CPU / vs Pemain) + tingkat CPU, lalu lanjut ke pilih arena.
## Pratinjau memakai sprite KFM asli (membuktikan frame termuat).

const ARENA_SELECT := "res://fight/scenes/arena_select.tscn"

var _preview1: AnimatedSprite2D
var _preview2: AnimatedSprite2D
var _name1: Label
var _name2: Label
var _p1_btns := {}
var _p2_btns := {}
var _mode_btns := {}
var _ai_btns := {}

func _ready() -> void:
	var vw := get_viewport().get_visible_rect().size.x
	_bg(Color(0.07, 0.08, 0.12))
	_title("PILIH KARAKTER", vw)

	# panel P1 (kiri) & P2 (kanan)
	_name1 = _label(Vector2(vw * 0.25 - 120, 110), 26, 240, HORIZONTAL_ALIGNMENT_CENTER)
	_name2 = _label(Vector2(vw * 0.75 - 120, 110), 26, 240, HORIZONTAL_ALIGNMENT_CENTER)
	_preview1 = _make_preview(Vector2(vw * 0.25, 320))
	_preview2 = _make_preview(Vector2(vw * 0.75, 320))

	# tombol pilih karakter tiap sisi
	var ids := CharacterRegistry.ids()
	_build_char_row(ids, 1, Vector2(vw * 0.25 - 150, 360), _p1_btns)
	_build_char_row(ids, 2, Vector2(vw * 0.75 - 150, 360), _p2_btns)

	# mode & tingkat CPU
	_build_mode_row(Vector2(vw / 2 - 210, 470))
	_build_ai_row(Vector2(vw / 2 - 210, 520))

	# lanjut
	var go := Button.new()
	go.text = "LANJUT KE PILIH ARENA  ▶"
	go.custom_minimum_size = Vector2(380, 54)
	go.position = Vector2(vw / 2 - 190, 580)
	go.pressed.connect(func(): get_tree().change_scene_to_file(ARENA_SELECT))
	add_child(go)

	_refresh()

func _build_char_row(ids: Array, side: int, pos: Vector2, store: Dictionary) -> void:
	var hb := HBoxContainer.new()
	hb.position = pos
	hb.add_theme_constant_override("separation", 10)
	add_child(hb)
	for id in ids:
		var def := CharacterRegistry.get_def(id)
		var b := Button.new()
		b.text = def.display_name
		b.custom_minimum_size = Vector2(145, 44)
		b.toggle_mode = true
		b.pressed.connect(_on_pick.bind(side, id))
		hb.add_child(b)
		store[id] = b

func _build_mode_row(pos: Vector2) -> void:
	var hb := HBoxContainer.new()
	hb.position = pos
	hb.add_theme_constant_override("separation", 10)
	add_child(hb)
	var lbl := _label(Vector2.ZERO, 18, 90, HORIZONTAL_ALIGNMENT_LEFT)
	lbl.text = "Mode:"
	hb.add_child(lbl)
	for pair in [[FightConfig.Mode.VS_AI, "vs CPU"], [FightConfig.Mode.VS_PLAYER, "vs Pemain"]]:
		var b := Button.new()
		b.text = pair[1]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(150, 40)
		b.pressed.connect(func():
			FightConfig.mode = pair[0]
			_refresh())
		hb.add_child(b)
		_mode_btns[pair[0]] = b

func _build_ai_row(pos: Vector2) -> void:
	var hb := HBoxContainer.new()
	hb.position = pos
	hb.add_theme_constant_override("separation", 10)
	add_child(hb)
	var lbl := _label(Vector2.ZERO, 18, 90, HORIZONTAL_ALIGNMENT_LEFT)
	lbl.text = "CPU:"
	hb.add_child(lbl)
	for pair in [[FightConfig.AILevel.EASY, "Mudah"], [FightConfig.AILevel.NORMAL, "Normal"], [FightConfig.AILevel.HARD, "Sulit"]]:
		var b := Button.new()
		b.text = pair[1]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(110, 40)
		b.pressed.connect(func():
			FightConfig.ai_level = pair[0]
			_refresh())
		hb.add_child(b)
		_ai_btns[pair[0]] = b

func _on_pick(side: int, id: String) -> void:
	if side == 1: FightConfig.p1_char = id
	else: FightConfig.p2_char = id
	_refresh()

func _refresh() -> void:
	for id in _p1_btns: _p1_btns[id].button_pressed = (id == FightConfig.p1_char)
	for id in _p2_btns: _p2_btns[id].button_pressed = (id == FightConfig.p2_char)
	for m in _mode_btns: _mode_btns[m].button_pressed = (m == FightConfig.mode)
	for a in _ai_btns:
		_ai_btns[a].button_pressed = (a == FightConfig.ai_level)
		_ai_btns[a].disabled = (FightConfig.mode == FightConfig.Mode.VS_PLAYER)
	var d1 := CharacterRegistry.get_def(FightConfig.p1_char)
	var d2 := CharacterRegistry.get_def(FightConfig.p2_char)
	_name1.text = d1.display_name
	_name2.text = d2.display_name
	_apply_preview(_preview1, d1, false)
	_apply_preview(_preview2, d2, true)

func _apply_preview(s: AnimatedSprite2D, d: CharacterDef, flip: bool) -> void:
	# Karakter dengan portrait (mis. Mr. Asian Tiger) → tampilkan wajahnya, sembunyikan sprite.
	var pt: TextureRect = s.get_meta("portrait")
	if d.portrait_path != "" and ResourceLoader.exists(d.portrait_path):
		pt.texture = load(d.portrait_path)
		pt.visible = true
		s.visible = false
		return
	pt.visible = false
	s.visible = true
	var frames: SpriteFrames = d.frames if d.frames != null else KfmFrames.get_frames()
	var ax: Vector2 = d.axis if d.frames != null else KfmFrames.axis
	var scale := (1.2 if d.frames == null else d.sprite_scale * 1.2)
	if frames != null:
		s.sprite_frames = frames
		if frames.has_animation("idle"):
			s.play("idle")
	s.modulate = d.tint
	s.flip_h = flip
	s.scale = Vector2(scale, scale)
	# jaga kaki di titik yang sama saat ganti karakter
	s.position = _preview_center(s) - Vector2(ax.x, ax.y) * scale

func _make_preview(center: Vector2) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.centered = false
	s.set_meta("center", center)
	add_child(s)
	# kotak portrait (wajah) — dipakai bila karakter punya portrait_path
	var pt := TextureRect.new()
	pt.size = Vector2(140, 150)
	pt.position = center - Vector2(70, 160)   # bagian bawah sejajar titik kaki pratinjau
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pt.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pt.visible = false
	add_child(pt)
	s.set_meta("portrait", pt)
	return s

func _preview_center(s: AnimatedSprite2D) -> Vector2:
	return s.get_meta("center", Vector2(200, 320))

# ---- util ----
func _bg(col: Color) -> void:
	var r := ColorRect.new()
	r.color = col
	r.size = get_viewport().get_visible_rect().size
	add_child(r)

func _title(text: String, vw: float) -> void:
	var l := _label(Vector2(0, 30), 40, vw, HORIZONTAL_ALIGNMENT_CENTER)
	l.text = text

func _label(pos: Vector2, fsize: int, width: float, align: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.size.x = width
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.horizontal_alignment = align
	add_child(l)
	return l
