extends GutTest

func _pressed_action(action_name: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	return event

func test_resolve_action_result_wins_on_skill_action():
	var event := _pressed_action("duel_skill_1")
	assert_eq(DuelResolution.resolve_action_result(event, "duel_skill_1", "duel_flee"), "win")

func test_resolve_action_result_flees_on_flee_action():
	var event := _pressed_action("duel_flee")
	assert_eq(DuelResolution.resolve_action_result(event, "duel_skill_1", "duel_flee"), "fled")

func test_resolve_action_result_ignores_unrelated_action():
	var event := _pressed_action("duel_jump")
	assert_eq(DuelResolution.resolve_action_result(event, "duel_skill_1", "duel_flee"), "")
