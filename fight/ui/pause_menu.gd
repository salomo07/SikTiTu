extends CanvasLayer
class_name FightPauseMenu

## Menu jeda mode Fight. Tetap memproses saat tree di-pause (process_mode ALWAYS).
## Memancarkan sinyal; match.gd yang memutuskan aksi (lanjut/ulang/keluar).

signal resumed
signal rematch
signal quit_to_menu

var _panel: Panel

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var vw := get_viewport().get_visible_rect().size
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = vw
	add_child(dim)

	_panel = Panel.new()
	_panel.size = Vector2(320, 300)
	_panel.position = (vw - _panel.size) / 2.0
	add_child(_panel)

	var vb := VBoxContainer.new()
	vb.position = Vector2(30, 30)
	vb.size = Vector2(260, 240)
	vb.add_theme_constant_override("separation", 16)
	_panel.add_child(vb)

	var title := Label.new()
	title.text = "JEDA"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	_add_btn(vb, "Lanjut", func(): resumed.emit())
	_add_btn(vb, "Ulang Pertandingan", func(): rematch.emit())
	_add_btn(vb, "Keluar ke Menu", func(): quit_to_menu.emit())

func _add_btn(parent: Node, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 48)
	b.pressed.connect(cb)
	parent.add_child(b)

func open() -> void:
	visible = true

func close() -> void:
	visible = false
