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
	_add_action_with_key("duel_flee", KEY_ESCAPE)
	_add_action_with_key("dragon_fly_up", KEY_SPACE)
	_add_action_with_key("dragon_descend", KEY_SHIFT)
	_add_action_with_key("dragon_roar", KEY_R)

	# --- Mode Fight (2D) — Pemain 1 ---
	_add_action_with_key("fight_left", KEY_A)
	_add_action_with_key("fight_right", KEY_D)
	_add_action_with_key("fight_jump", KEY_W)
	_add_action_with_key("fight_crouch", KEY_S)
	_add_action_with_key("fight_lp", KEY_J)      # pukulan ringan
	_add_action_with_key("fight_hp", KEY_U)      # pukulan keras
	_add_action_with_key("fight_lk", KEY_K)      # tendangan ringan
	_add_action_with_key("fight_hk", KEY_I)      # tendangan keras
	_add_action_with_key("fight_skill_1", KEY_1)
	_add_action_with_key("fight_skill_2", KEY_2)
	_add_action_with_key("fight_skill_3", KEY_3)
	_add_action_with_key("fight_skill_4", KEY_4)
	_add_action_with_key("fight_pause", KEY_ESCAPE)
	_add_action_with_key("fight_confirm", KEY_ENTER)

func _add_action_with_key(action_name: String, keycode: Key) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)
