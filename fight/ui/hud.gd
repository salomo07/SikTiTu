class_name HUD
extends CanvasLayer

## HUD simple: dos barras de vida que leen la salud de cada fighter (presentación pura).
## Sustituible por un HUD con sprites/arte más adelante sin tocar la lógica.

const BAR_W := 170.0

@onready var p1_fill: ColorRect = $P1Fill
@onready var p2_fill: ColorRect = $P2Fill
@onready var timer_label: Label = $Timer
@onready var msg_label: Label = $Message
@onready var p1_pips: Label = $P1Pips
@onready var p2_pips: Label = $P2Pips
@onready var skill_title: Label = $SkillTitle

var p1: Fighter
var p2: Fighter
var _title_t: float = 0.0

func _ready() -> void:
	add_to_group("fight_hud")

## Flash a skill name banner (fades out). Called by the Attack state.
func set_skill_title(text: String) -> void:
	if skill_title == null:
		return
	skill_title.text = text
	skill_title.modulate.a = 1.0
	_title_t = 1.4

func set_timer(seconds: int) -> void:
	if timer_label != null:
		timer_label.text = str(seconds)

func set_rounds(a: int, b: int) -> void:
	if p1_pips != null:
		p1_pips.text = "O".repeat(a)
	if p2_pips != null:
		p2_pips.text = "O".repeat(b)

func set_message(text: String) -> void:
	if msg_label != null:
		msg_label.text = text

func setup(a: Fighter, b: Fighter) -> void:
	p1 = a
	p2 = b

## Set the displayed fighter names (from the chosen heroes). Safe if the name
## labels are absent.
func set_names(p1_name: String, p2_name: String) -> void:
	var n1 := get_node_or_null("P1Name")
	if n1 != null:
		n1.text = p1_name
	var n2 := get_node_or_null("P2Name")
	if n2 != null:
		n2.text = p2_name

func _process(_delta: float) -> void:
	if _title_t > 0.0 and skill_title != null:
		_title_t -= _delta
		skill_title.modulate.a = clampf(_title_t / 0.5, 0.0, 1.0)
		if _title_t <= 0.0:
			skill_title.text = ""
	if p1 != null:
		p1_fill.size.x = BAR_W * clampf(float(p1.health) / float(p1.max_health), 0.0, 1.0)
	if p2 != null:
		var w := BAR_W * clampf(float(p2.health) / float(p2.max_health), 0.0, 1.0)
		p2_fill.size.x = w
		p2_fill.position.x = 204.0 + (BAR_W - w)   # la barra de P2 drena hacia el centro
