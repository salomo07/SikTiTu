extends Node

func _ready() -> void:
	register_actions()

func register_actions() -> void:
	_add_action_with_key("move_forward", KEY_W)
	_add_action_with_key("move_back", KEY_S)
	_add_action_with_key("move_left", KEY_A)
	_add_action_with_key("move_right", KEY_D)
	_add_action_with_key("duel_left", KEY_LEFT)
	_add_action_with_key("duel_right", KEY_RIGHT)
	_add_action_with_key("duel_jump", KEY_UP)
	_add_action_with_key("duel_crouch", KEY_DOWN)
	_add_action_with_key("duel_skill_1", KEY_J)
	_add_action_with_key("duel_skill_2", KEY_K)

func _add_action_with_key(action_name: String, keycode: Key) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)
