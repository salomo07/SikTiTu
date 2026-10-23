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
	register_fight_actions()

## Register the p1_*/p2_* actions the adapted shoto Fight engine reads
## (see fight/input/human_input.gd), plus the training-view debug toggle.
## Keyboard layout (local versus):
##   P1  move WASD  | punches F G H | kicks C V B
##   P2  move arrows| punches Num4/5/6 | kicks Num1/2/3
## ControllerSetup adds a gamepad to the P1 actions afterwards.
func register_fight_actions() -> void:
	# Player 1
	_add_action_with_key("p1_left", KEY_A)
	_add_action_with_key("p1_right", KEY_D)
	_add_action_with_key("p1_up", KEY_W)
	_add_action_with_key("p1_down", KEY_S)
	_add_action_with_key("p1_lp", KEY_F)
	_add_action_with_key("p1_mp", KEY_G)
	_add_action_with_key("p1_hp", KEY_H)
	_add_action_with_key("p1_lk", KEY_C)
	_add_action_with_key("p1_mk", KEY_V)
	_add_action_with_key("p1_hk", KEY_B)
	# Player 2
	_add_action_with_key("p2_left", KEY_LEFT)
	_add_action_with_key("p2_right", KEY_RIGHT)
	_add_action_with_key("p2_up", KEY_UP)
	_add_action_with_key("p2_down", KEY_DOWN)
	_add_action_with_key("p2_lp", KEY_KP_4)
	_add_action_with_key("p2_mp", KEY_KP_5)
	_add_action_with_key("p2_hp", KEY_KP_6)
	_add_action_with_key("p2_lk", KEY_KP_1)
	_add_action_with_key("p2_mk", KEY_KP_2)
	_add_action_with_key("p2_hk", KEY_KP_3)
	# Training view: show/hide hit & hurt boxes
	_add_action_with_key("toggle_debug", KEY_F1)

func _add_action_with_key(action_name: String, keycode: Key) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)
