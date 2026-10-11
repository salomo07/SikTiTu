extends Node3D
## Lantai hexagon prosedural dari Kenney Hexagon Kit + dekorasi Nature Kit.
## Pulau rumput di tengah, cincin pasir, lalu air di tepian. Deterministik.

const TILES := {
	"grass": preload("res://assets/models/kenney/hexagon/grass.glb"),
	"grass_forest": preload("res://assets/models/kenney/hexagon/grass-forest.glb"),
	"grass_hill": preload("res://assets/models/kenney/hexagon/grass-hill.glb"),
	"dirt": preload("res://assets/models/kenney/hexagon/dirt.glb"),
	"sand": preload("res://assets/models/kenney/hexagon/sand.glb"),
	"sand_rocks": preload("res://assets/models/kenney/hexagon/sand-rocks.glb"),
	"stone": preload("res://assets/models/kenney/hexagon/stone.glb"),
	"stone_hill": preload("res://assets/models/kenney/hexagon/stone-hill.glb"),
	"stone_rocks": preload("res://assets/models/kenney/hexagon/stone-rocks.glb"),
	"water": preload("res://assets/models/kenney/hexagon/water.glb"),
	"water_rocks": preload("res://assets/models/kenney/hexagon/water-rocks.glb"),
	"water_island": preload("res://assets/models/kenney/hexagon/water-island.glb"),
}

const DECO: Array[PackedScene] = [
	preload("res://assets/models/kenney/nature/rock_smallA.glb"),
	preload("res://assets/models/kenney/nature/rock_smallB.glb"),
	preload("res://assets/models/kenney/nature/flower_redA.glb"),
	preload("res://assets/models/kenney/nature/flower_yellowA.glb"),
	preload("res://assets/models/kenney/nature/grass_large.glb"),
	preload("res://assets/models/kenney/nature/stump_round.glb"),
]

@export var tile_scale := 4.0
@export var half_extent := 50.0
@export var terrain_seed := 20261011

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = terrain_seed
	var noise := FastNoiseLite.new()
	noise.seed = terrain_seed
	noise.frequency = 0.045

	# ukur dimensi tile dari grass.glb
	var sample := TILES["grass"].instantiate() as Node3D
	var aabb := _combined_aabb(sample, Transform3D.IDENTITY)
	sample.free()
	var w := aabb.size.x * tile_scale
	var d := aabb.size.z * tile_scale
	var top := (aabb.position.y + aabb.size.y) * tile_scale
	var col_step := w * 0.75
	var row_step := d

	var cols := int(ceil(half_extent * 2.0 / col_step))
	var rows := int(ceil(half_extent * 2.0 / row_step))
	var placed := 0
	var half_cols := floori(cols / 2.0)
	var half_rows := floori(rows / 2.0)
	for c in range(-half_cols, half_cols + 1):
		for r in range(-half_rows, half_rows + 1):
			var x: float = c * col_step
			var z: float = r * row_step + float(absi(c) % 2) * row_step * 0.5
			if abs(x) > half_extent or abs(z) > half_extent + row_step:
				continue
			var pos := Vector3(x, -top, z)
			var tile_name := _pick_tile(Vector2(x, z), noise)
			_spawn(TILES[tile_name], pos, tile_scale, _rng.randi_range(0, 5) * TAU / 6.0)
			placed += 1
			if tile_name.begins_with("grass") and _rng.randf() < 0.07:
				var deco: PackedScene = DECO[_rng.randi() % DECO.size()]
				var jitter := Vector3(_rng.randf_range(-1.2, 1.2), 0, _rng.randf_range(-1.2, 1.2))
				_spawn(deco, Vector3(x, 0, z) + jitter, 2.0, _rng.randf() * TAU)
	print("HexTerrain: ", placed, " tile dipasang")


func _pick_tile(p: Vector2, noise: FastNoiseLite) -> String:
	var dist := p.length()
	if dist > half_extent - 4.0:
		return "water_island" if _rng.randf() < 0.06 else ("water_rocks" if _rng.randf() < 0.1 else "water")
	if dist > half_extent - 9.0:
		return "sand_rocks" if _rng.randf() < 0.15 else "sand"
	var n := noise.get_noise_2d(p.x, p.y)
	if n < -0.3:
		return "dirt"
	if n < 0.1:
		return "grass"
	if n < 0.28:
		return "grass_forest"
	if n < 0.42:
		return "grass_hill"
	if n < 0.55:
		return "stone"
	return "stone_hill"


func _spawn(scene: PackedScene, pos: Vector3, s: float, yaw: float) -> void:
	var inst := scene.instantiate() as Node3D
	add_child(inst)
	inst.position = pos
	inst.scale = Vector3.ONE * s
	inst.rotation.y = yaw


static func _combined_aabb(node: Node, xform: Transform3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array = [[node, xform]]
	while not stack.is_empty():
		var entry: Array = stack.pop_back()
		var n: Node = entry[0]
		var t: Transform3D = entry[1]
		if n is Node3D:
			t = t * (n as Node3D).transform
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var ab: AABB = t * (n as MeshInstance3D).mesh.get_aabb()
			result = ab if first else result.merge(ab)
			first = false
		for child in n.get_children():
			stack.append([child, t])
	return result
