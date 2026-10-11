extends GutTest

const ACTIONS := [
	"move_forward", "move_back", "move_left", "move_right",
	"duel_left", "duel_right", "duel_jump", "duel_crouch",
	"duel_skill_1", "duel_skill_2", "duel_flee",
]

func before_each():
	for action_name in ACTIONS:
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)

func after_each():
	for action_name in ACTIONS:
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)

func test_register_actions_creates_all_expected_actions():
	var input_setup = load("res://autoload/input_setup.gd").new()
	input_setup.register_actions()

	for action_name in ACTIONS:
		assert_true(InputMap.has_action(action_name), "missing action: %s" % action_name)

func test_register_actions_is_idempotent():
	var input_setup = load("res://autoload/input_setup.gd").new()
	input_setup.register_actions()
	input_setup.register_actions()

	assert_eq(InputMap.action_get_events("move_forward").size(), 1)
