extends Node2D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("duel_skill_1"):
		# Placeholder win condition for foundation verification: pressing the
		# skill button resolves the duel as a win. Real combat/HP resolution
		# is out of scope for this foundation plan.
		GameManager.end_duel("win")
