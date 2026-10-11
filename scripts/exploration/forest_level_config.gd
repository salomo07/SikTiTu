extends Node3D

const MAX_FIRE_POINTS := 5
const MAX_ANIMALS := 4

const TREE_COUNT := 45
const TREE_FIELD_HALF_EXTENT := 45.0
const TREE_MIN_SPACING := 3.0
const TREE_SPAWN_CLEARANCE := 3.5
const TREE_SEED := 20261011
const PORTAL_CLEARANCE := 4.0

const TREE_SCENE := preload("res://scenes/exploration/tree.tscn")

func _ready() -> void:
	if GameManager.has_pending_restore():
		var player := get_node_or_null("Player3D") as Node3D
		if player != null:
			player.global_position = GameManager.consume_pending_restore_position()
	_limit_group_children(get_node_or_null("FirePoints"), MAX_FIRE_POINTS)
	_populate_trees()

static func compute_excess_children(total_count: int, max_count: int) -> int:
	return max(0, total_count - max_count)

## Scatters `count` tree positions on a square field of the given half-extent,
## keeping every point at least `spawn_clearance` away from the origin (player/
## animal spawn area) and at least `min_spacing` away from every other tree.
## Deterministic for a given seeded `rng`, so the layout is reproducible and
## testable.
static func generate_tree_positions(
	count: int,
	half_extent: float,
	min_spacing: float,
	spawn_clearance: float,
	rng: RandomNumberGenerator
) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var max_attempts := count * 30
	var attempts := 0
	while positions.size() < count and attempts < max_attempts:
		attempts += 1
		var candidate := Vector3(
			rng.randf_range(-half_extent, half_extent),
			0.0,
			rng.randf_range(-half_extent, half_extent)
		)
		if candidate.length() < spawn_clearance:
			continue
		var too_close := false
		for existing in positions:
			if existing.distance_to(candidate) < min_spacing:
				too_close = true
				break
		if not too_close:
			positions.append(candidate)
	return positions

func _populate_trees() -> void:
	var trees_container := get_node_or_null("Trees")
	if trees_container == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = TREE_SEED
	var positions := generate_tree_positions(
		TREE_COUNT, TREE_FIELD_HALF_EXTENT, TREE_MIN_SPACING, TREE_SPAWN_CLEARANCE, rng
	)
	var portal := get_node_or_null("Portal") as Node3D
	for position in positions:
		if portal != null and position.distance_to(portal.position) < PORTAL_CLEARANCE:
			continue
		var tree := TREE_SCENE.instantiate()
		trees_container.add_child(tree)
		tree.global_position = position
	_align_fire_to_trees(positions)

## Moves the hand-placed FirePoint/SmokePoint effect instances onto a subset of
## the generated tree trunks, so the fire reads as "these trees are burning"
## instead of flames floating in empty space. Only the first N smoke points are
## paired 1:1 with fire points (same tree); any extra ambient smoke points keep
## their authored position.
func _align_fire_to_trees(tree_positions: Array[Vector3]) -> void:
	if tree_positions.is_empty():
		return
	var fire_points := get_node_or_null("FirePoints")
	if fire_points == null:
		return
	var smoke_points := get_node_or_null("SmokePoints")
	var smoke_children: Array = smoke_points.get_children() if smoke_points != null else []
	var fire_children := fire_points.get_children()
	for i in range(fire_children.size()):
		var tree_pos: Vector3 = tree_positions[i % tree_positions.size()]
		fire_children[i].global_position = Vector3(tree_pos.x, 0.3, tree_pos.z)
		if i < smoke_children.size():
			smoke_children[i].global_position = Vector3(tree_pos.x, 1.8, tree_pos.z)

func _limit_group_children(parent: Node, max_count: int) -> void:
	if parent == null:
		return
	var children := parent.get_children()
	var excess := compute_excess_children(children.size(), max_count)
	for i in range(excess):
		children[children.size() - 1 - i].queue_free()
