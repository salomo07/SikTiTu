extends Node

## Adds gamepad (joypad) support for Player 1 without removing the keyboard.
## Punches = X/Y/RB, kicks = A/B/LB, d-pad + left stick to move. Adapted from the
## shoto-fighter reference. Runs after InputSetup has created the p1_* actions.

func _ready() -> void:
	_add_dir("p1_left", JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_add_dir("p1_right", JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_add_dir("p1_up", JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	_add_dir("p1_down", JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	_add_button("p1_lp", JOY_BUTTON_X)
	_add_button("p1_mp", JOY_BUTTON_Y)
	_add_button("p1_hp", JOY_BUTTON_RIGHT_SHOULDER)
	_add_button("p1_lk", JOY_BUTTON_A)
	_add_button("p1_mk", JOY_BUTTON_B)
	_add_button("p1_hk", JOY_BUTTON_LEFT_SHOULDER)
	_add_button("ui_accept", JOY_BUTTON_A)
	_add_button("ui_cancel", JOY_BUTTON_B)

func _add_button(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.device = -1
	InputMap.action_add_event(action, ev)

func _add_dir(action: String, button: int, axis: int, value: float) -> void:
	_add_button(action, button)
	var m := InputEventJoypadMotion.new()
	m.axis = axis
	m.axis_value = value
	m.device = -1
	InputMap.action_add_event(action, m)
