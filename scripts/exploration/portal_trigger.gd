extends Area3D

@export var enemy_id: String = "wolf_01"

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return
	_triggered = true
	GameManager.start_duel(enemy_id, body.global_position)
