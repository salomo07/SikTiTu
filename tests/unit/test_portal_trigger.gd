extends GutTest

func before_each():
	GameManager.is_in_duel = false
	GameManager.resolved_enemy_ids.clear()
	GameManager.current_enemy_id = ""
	GameManager.auto_change_scene = false

func after_each():
	GameManager.is_in_duel = false
	GameManager.resolved_enemy_ids.clear()
	GameManager.current_enemy_id = ""
	GameManager.auto_change_scene = true

func _make_trigger_and_player(enemy_id: String):
	var trigger = load("res://scripts/exploration/portal_trigger.gd").new()
	trigger.enemy_id = enemy_id
	var player := Node3D.new()
	player.add_to_group("player")
	add_child_autofree(trigger)
	add_child_autofree(player)
	return [trigger, player]

func test_trigger_starts_duel_on_first_entry():
	var pair = _make_trigger_and_player("wolf_01")
	var trigger = pair[0]
	var player = pair[1]

	trigger._on_body_entered(player)

	assert_true(GameManager.is_in_duel)
	assert_eq(GameManager.current_enemy_id, "wolf_01")

func test_trigger_does_not_restart_a_resolved_encounter():
	GameManager.resolved_enemy_ids.append("wolf_01")
	var pair = _make_trigger_and_player("wolf_01")
	var trigger = pair[0]
	var player = pair[1]

	trigger._on_body_entered(player)

	assert_false(GameManager.is_in_duel)

func test_trigger_ignores_non_player_bodies():
	var pair = _make_trigger_and_player("wolf_01")
	var trigger = pair[0]
	var not_player := Node3D.new()
	add_child_autofree(not_player)

	trigger._on_body_entered(not_player)

	assert_false(GameManager.is_in_duel)
