extends Node3D

const ANIMAL_SCENE := preload("res://scenes/exploration/animal.tscn")

@export var spawn_positions: Array[Vector3] = []
@export var danger_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	var config := get_node("/root/ForestLevel") as Node
	var max_animals: int = config.MAX_ANIMALS if config != null else spawn_positions.size()
	var count: int = min(max_animals, spawn_positions.size())

	for i in range(count):
		var animal := ANIMAL_SCENE.instantiate()
		add_child(animal)
		animal.global_position = spawn_positions[i]
		animal.set_danger(danger_position)
