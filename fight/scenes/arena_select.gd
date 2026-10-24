extends Control
## Layar pilih arena mode Fight. Memindai assets/textures/arena (data-driven via
## FightConfig.get_arenas) → kartu pratinjau untuk tiap PNG (banjir, dpr, dst).
## Tambah file PNG baru = arena baru otomatis muncul. Klik kartu → mulai pertandingan.

const MATCH_SCENE := "res://fight/scenes/fight_match.tscn"
const BACK_SCENE := "res://fight/scenes/character_select.tscn"

func _ready() -> void:
	var vw := get_viewport().get_visible_rect().size.x
	_bg(Color(0.07, 0.08, 0.12))
	_title("PILIH ARENA", vw)

	var arenas := FightConfig.get_arenas()
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 28)
	grid.position = Vector2(60, 140)
	add_child(grid)

	if arenas.is_empty():
		var warn := _label(Vector2(60, 200), 22, vw - 120, HORIZONTAL_ALIGNMENT_LEFT)
		warn.text = "Tidak ada arena di assets/textures/arena/"
	for a in arenas:
		grid.add_child(_make_card(a))

	var back := Button.new()
	back.text = "◀ Kembali (karakter)"
	back.custom_minimum_size = Vector2(240, 48)
	back.position = Vector2(60, get_viewport().get_visible_rect().size.y - 80)
	back.pressed.connect(func(): get_tree().change_scene_to_file(BACK_SCENE))
	add_child(back)

func _make_card(arena: Dictionary) -> Control:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(360, 230)
	btn.pressed.connect(_choose.bind(arena["id"]))
	# pratinjau gambar arena di dalam tombol
	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(360, 230)
	tex.size = Vector2(360, 230)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(arena["path"]):
		tex.texture = load(arena["path"])
	btn.add_child(tex)
	card.add_child(btn)

	var name_lbl := Label.new()
	name_lbl.text = arena["name"]
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.custom_minimum_size = Vector2(360, 0)
	card.add_child(name_lbl)
	return card

func _choose(id: String) -> void:
	FightConfig.arena_id = id
	get_tree().change_scene_to_file(MATCH_SCENE)

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
