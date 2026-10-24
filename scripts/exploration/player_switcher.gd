extends Node
## Tab: ganti karakter yang dikendalikan (naga <-> manusia).

@export var players: Array[NodePath] = []

var _index := 0


func _ready() -> void:
	_apply.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		_index = (_index + 1) % players.size()
		_apply()


func _apply() -> void:
	for i in players.size():
		var p := get_node_or_null(players[i])
		if p and p.has_method("set_active"):
			p.set_active(i == _index)
