extends Control
## Menu Utama SikTiTu. Scene awal project: pemain memilih mode permainan.
## (Dialog Singleplayer/Multiplayer penuh = Fase 1 roadmap; untuk sekarang menu
## langsung menyediakan Fight & Explore.)

const FIGHT_SCENE := "res://fight/scenes/character_select.tscn"
const EXPLORE_SCENE := "res://scenes/exploration/forest_level.tscn"
const TEAL := Color(0.08, 0.72, 0.65)

func _ready() -> void:
	var vp := get_viewport().get_visible_rect().size
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10)
	bg.size = vp
	add_child(bg)

	var title := Label.new()
	title.text = "SIKTITU"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(vp.x, 90)
	title.position = Vector2(0, vp.y * 0.18)
	add_child(title)

	var sub := Label.new()
	sub.text = "Fighting 2D  ·  Petualangan 3D"
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", TEAL)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(vp.x, 30)
	sub.position = Vector2(0, vp.y * 0.18 + 92)
	add_child(sub)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	vb.position = Vector2(vp.x / 2 - 170, vp.y * 0.44)
	vb.custom_minimum_size = Vector2(340, 0)
	add_child(vb)

	_btn(vb, "FIGHT  —  Duel 2D", func(): get_tree().change_scene_to_file(FIGHT_SCENE))
	_btn(vb, "EXPLORE  —  Petualangan 3D", func(): get_tree().change_scene_to_file(EXPLORE_SCENE))
	_btn(vb, "KELUAR", func(): get_tree().quit())

	var hint := Label.new()
	hint.text = "v0.1 — fokus mode Fight"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(vp.x, 20)
	hint.position = Vector2(0, vp.y - 36)
	add_child(hint)

func _btn(parent: Node, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(340, 56)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	parent.add_child(b)
