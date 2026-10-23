extends Control

## Fight setup screen: pick Player 1 / Player 2 heroes and the arena, then start
## the shoto match. Rosters come straight from HeroDB / ArenaDB, so any hero or
## arena you add there (see their ADD-YOUR-OWN comments) shows up here
## automatically. Writes the choices into GameConfig and loads the match.

const MATCH_SCENE := "res://fight/match/match.tscn"
const MENU_SCENE := "res://scenes/main/main_menu.tscn"

var _p1_opt: OptionButton
var _p2_opt: OptionButton
var _arena_opt: OptionButton
var _p2_label: Label

var _heroes: Array = []
var _arenas: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_heroes = HeroDB.all()
	_arenas = ArenaDB.all()
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.text = "FIGHT SETUP"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 40.0
	add_child(title)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -200.0
	vbox.offset_right = 200.0
	vbox.offset_top = -120.0
	vbox.offset_bottom = 160.0
	vbox.add_theme_constant_override("separation", 14)
	add_child(vbox)

	_p1_opt = _add_row(vbox, "Player 1", _hero_names())
	_p2_label = null
	_p2_opt = _add_row(vbox, "Player 2 / CPU", _hero_names())
	_arena_opt = _add_row(vbox, "Arena", _arena_names())

	# Preselect whatever GameConfig currently holds.
	_select_by_id(_p1_opt, _heroes, GameConfig.p1_hero_id)
	_select_by_id(_p2_opt, _heroes, GameConfig.p2_hero_id)
	_select_by_id(_arena_opt, _arenas, GameConfig.arena_id)

	var start := _make_button("START FIGHT", _on_start)
	vbox.add_child(start)
	var back := _make_button("BACK", _on_back)
	vbox.add_child(back)


func _add_row(parent: VBoxContainer, label_text: String, items: Array) -> OptionButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(170, 40)
	lbl.add_theme_font_size_override("font_size", 20)
	row.add_child(lbl)
	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(210, 40)
	for n in items:
		opt.add_item(n)
	row.add_child(opt)
	parent.add_child(row)
	return opt


func _make_button(text: String, handler: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(handler)
	return b


func _hero_names() -> Array:
	var names := []
	for h in _heroes:
		names.append(str(h.get("name", h.get("id", "?"))))
	return names


func _arena_names() -> Array:
	var names := []
	for a in _arenas:
		names.append(str(a.get("name", a.get("id", "?"))))
	return names


func _select_by_id(opt: OptionButton, data: Array, id: String) -> void:
	for i in data.size():
		if str(data[i].get("id", "")) == id:
			opt.select(i)
			return


func _on_start() -> void:
	GameConfig.p1_hero_id = str(_heroes[_p1_opt.selected].get("id"))
	GameConfig.p2_hero_id = str(_heroes[_p2_opt.selected].get("id"))
	GameConfig.arena_id = str(_arenas[_arena_opt.selected].get("id"))
	get_tree().change_scene_to_file(MATCH_SCENE)


func _on_back() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
