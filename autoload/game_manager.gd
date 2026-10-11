extends Node

signal duel_started(enemy_id: String)
signal duel_ended(result: String)

var player_forest_position: Vector3 = Vector3.ZERO
var player_hp: int = 100
var current_enemy_id: String = ""
var is_in_duel: bool = false

## Set to false in tests to verify state changes without triggering real scene loads.
var auto_change_scene: bool = true

const FOREST_SCENE_PATH := "res://scenes/exploration/forest_level.tscn"
const DUEL_SCENE_PATH := "res://scenes/duel/duel_arena.tscn"

func start_duel(enemy_id: String, forest_position: Vector3) -> void:
	if is_in_duel:
		return
	current_enemy_id = enemy_id
	player_forest_position = forest_position
	is_in_duel = true
	duel_started.emit(enemy_id)
	if auto_change_scene:
		get_tree().change_scene_to_file(DUEL_SCENE_PATH)

func end_duel(result: String) -> void:
	if not is_in_duel:
		return
	is_in_duel = false
	duel_ended.emit(result)
	if auto_change_scene:
		get_tree().change_scene_to_file(FOREST_SCENE_PATH)
