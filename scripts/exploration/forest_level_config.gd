extends Node3D

const MAX_FIRE_POINTS := 5
const MAX_ANIMALS := 4

func _ready() -> void:
	if GameManager.has_pending_restore():
		var player := get_node_or_null("Player3D") as Node3D
		if player != null:
			player.global_position = GameManager.consume_pending_restore_position()
	_limit_group_children(get_node_or_null("FirePoints"), MAX_FIRE_POINTS)

static func compute_excess_children(total_count: int, max_count: int) -> int:
	return max(0, total_count - max_count)

func _limit_group_children(parent: Node, max_count: int) -> void:
	if parent == null:
		return
	var children := parent.get_children()
	var excess := compute_excess_children(children.size(), max_count)
	for i in range(excess):
		children[children.size() - 1 - i].queue_free()
