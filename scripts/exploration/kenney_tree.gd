extends StaticBody3D

const VARIANTS: Array[PackedScene] = [
	preload("res://assets/models/kenney/nature/tree_default.glb"),
	preload("res://assets/models/kenney/nature/tree_detailed.glb"),
	preload("res://assets/models/kenney/nature/tree_oak.glb"),
	preload("res://assets/models/kenney/nature/tree_cone.glb"),
	preload("res://assets/models/kenney/nature/tree_pineDefaultA.glb"),
	preload("res://assets/models/kenney/nature/tree_pineTallA.glb"),
]
const TREE_SCALE := 2.6


func _ready() -> void:
	var h := hash(Vector2i(int(global_position.x * 10.0), int(global_position.z * 10.0)))
	var variant: PackedScene = VARIANTS[h % VARIANTS.size()]
	var model := variant.instantiate() as Node3D
	add_child(model)
	model.scale = Vector3.ONE * TREE_SCALE
	model.rotation.y = float(h % 360) * TAU / 360.0
