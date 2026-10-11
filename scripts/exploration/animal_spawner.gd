extends Node3D

## Soft, recognizable critters (not a plain capsule) — picked in rotation so
## the forest shows a mix rather than clones of one species.
const ANIMAL_VARIANTS: Array[PackedScene] = [
	preload("res://scenes/exploration/animals/snake.tscn"),
	preload("res://scenes/exploration/animals/monkey.tscn"),
	preload("res://scenes/exploration/animals/musang.tscn"),
]

@export var spawn_positions: Array[Vector3] = []
@export var danger_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	var config := get_node("/root/ForestLevel") as Node
	var max_animals: int = config.MAX_ANIMALS if config != null else spawn_positions.size()
	var count: int = min(max_animals, spawn_positions.size())

	for i in range(count):
		var variant: PackedScene = ANIMAL_VARIANTS[i % ANIMAL_VARIANTS.size()]
		var animal := variant.instantiate()
		add_child(animal)
		animal.global_position = spawn_positions[i]
		animal.set_danger(danger_position)
