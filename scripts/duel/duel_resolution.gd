extends Node2D
class_name DuelResolution

const WIN_ACTION := "duel_skill_1"
const FLEE_ACTION := "duel_flee"

func _unhandled_input(event: InputEvent) -> void:
	var result := resolve_action_result(event, WIN_ACTION, FLEE_ACTION)
	if result != "":
		GameManager.end_duel(result)

## Pure mapping from a pressed input event to the duel outcome it should
## trigger, or "" when the event doesn't end the duel. Takes the action names
## as arguments (not the constants directly) so tests can exercise it without
## depending on real key bindings being registered in the global InputMap.
##
## "win" is a placeholder for foundation verification — pressing the skill
## button resolves the duel as a win. Real combat/HP resolution is out of
## scope for this foundation plan. "fled" exists so a player who entered a
## duel by accident always has a way back out.
static func resolve_action_result(event: InputEvent, win_action: String, flee_action: String) -> String:
	if event.is_action_pressed(win_action):
		return "win"
	if event.is_action_pressed(flee_action):
		return "fled"
	return ""
