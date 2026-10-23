class_name MatchManager
extends Node2D

## Orquestador del combate. Tras mover a los fighters aplica lo "global": paredes,
## pushbox, resolución de golpes (hitbox↔hurtbox) y cámara.
## (Rounds, timer, HUD y KO llegan en la Fase 6.)

@export var stage_left: float = 40.0
@export var stage_right: float = 344.0
@export var pushbox_min_sep: float = 44.0
@export var throw_range: float = 60.0
@export var view_width: float = 384.0
@export var cam_min_zoom: float = 0.8
@export var cam_max_zoom: float = 1.1
@export var cam_margin: float = 130.0
@export var p2_is_cpu: bool = false
@export var cpu_difficulty: String = "medium"

@onready var camera: Camera2D = $Camera2D

const HIT_SPARK := preload("res://fight/fx/hit_spark.tscn")

var p1: Fighter
var p2: Fighter
var hud: HUD = null
var match_state := MatchState.new()
var sfx: Sfx = null
var _shake: int = 0
var _online := false
var _local_fighter: Fighter = null

func _ready() -> void:
	process_priority = 100   # correr DESPUÉS de que los fighters integren
	var cfg := get_node_or_null("/root/GameConfig")
	if cfg != null:
		p2_is_cpu = cfg.p2_is_cpu
		cpu_difficulty = cfg.cpu_difficulty
	sfx = Sfx.new()
	add_child(sfx)
	p1 = $Player1
	p2 = $Player2
	p1.opponent = p2
	p2.opponent = p1
	p1.team = 0
	p2.team = 1
	for f in [p1, p2]:
		f.wall_left = stage_left
		f.wall_right = stage_right
	# Apply the heroes + arena chosen in the menu (GameConfig). Falls back to the
	# scene's baked-in fighters/background when no config is present.
	if cfg != null:
		p1.configure_from_hero(cfg.hero_for_slot("p1"))
		p2.configure_from_hero(cfg.hero_for_slot("p2"))
		_apply_arena(cfg.current_arena())
	# Online: local peer drives its own fighter (p1 keys); the remote fighter is
	# fed network frames. Host owns P1, client owns P2.
	if cfg != null and cfg.online:
		_online = true
		var local_is_p1: bool = cfg.local_player_index == 1
		_local_fighter = p1 if local_is_p1 else p2
		var remote_fighter: Fighter = p2 if local_is_p1 else p1
		for child in _local_fighter.get_children():
			if child is HumanInput:
				child.player_prefix = "p1"
		var ni := NetInput.new()
		remote_fighter.add_child(ni)
		remote_fighter.input_source = ni
	if not _online and p2_is_cpu:
		var ai := AIInput.new()
		ai.difficulty = cpu_difficulty
		ai.fighter = p2
		ai.opponent = p1
		p2.add_child(ai)
		p2.input_source = ai
	hud = get_node_or_null("HUD")
	if hud != null:
		hud.setup(p1, p2)
		if cfg != null:
			hud.set_names(str(cfg.hero_for_slot("p1").get("name", "P1")),
				str(cfg.hero_for_slot("p2").get("name", "P2")))
	_reset_round()

func _physics_process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
	# Online: broadcast our fighter's current input to the remote peer. Fighters
	# poll before us (process_priority 100), so _local_fighter.input is current.
	if _online and _local_fighter != null:
		NetManager.send_frame(NetInput.to_dict(_local_fighter.input))
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
		return
	if Input.is_action_just_pressed("toggle_debug"):
		var cfg := get_node_or_null("/root/GameConfig")
		if cfg != null:
			cfg.show_boxes = not cfg.show_boxes
	# Flujo de match (intro / pelea / fin de round / fin de match)
	var ev := match_state.tick(p1.health, p2.health)
	if ev == "next_round":
		_reset_round()
	elif ev == "round_end" and sfx != null:
		sfx.play_ko()
	# Pueden actuar en intro y pelea; se congelan en fin de round / fin de match.
	var can_act := match_state.phase == MatchState.FIGHT or match_state.phase == MatchState.INTRO
	p1.frozen = not can_act
	p2.frozen = not can_act
	# Pushbox + paredes (siempre)
	var sep := StagePhysics.separate(p1.position.x, p2.position.x, pushbox_min_sep)
	p1.position.x = sep[0]
	p2.position.x = sep[1]
	p1.position.x = StagePhysics.clamp_wall(p1.position.x, stage_left, stage_right)
	p2.position.x = StagePhysics.clamp_wall(p2.position.x, stage_left, stage_right)
	# Agarres y golpes durante intro/pelea
	if can_act:
		Throws.resolve(p1, p2, throw_range)
		if Combat.resolve(p1, p2):
			_on_hit(p2)
		if Combat.resolve(p2, p1):
			_on_hit(p1)
	# Proyectiles
	_process_projectiles(delta)
	# Cámara
	if camera != null:
		var cam := CameraLogic.compute(p1.position.x, p2.position.x, view_width, cam_min_zoom, cam_max_zoom, cam_margin)
		var off := 0.0
		if _shake > 0:
			off = 5.0 if (_shake % 2 == 0) else -5.0
			_shake -= 1
		camera.position.x = cam[0] + off
		camera.zoom = Vector2(cam[1], cam[1])
	_update_hud()
	if match_state.match_over() and _rematch_pressed():
		match_state.reset_match()
		_reset_round()

## Apply an ArenaDB entry: recolor the vector backdrop, and if the arena has an
## `image` (res:// path to your own pixel-art backdrop) draw it stretched behind
## the stage. See fight/data/arena_db.gd for how to add arenas.
func _apply_arena(a: Dictionary) -> void:
	_set_poly_color("Background", a.get("bg"))
	_set_poly_color("BackWall", a.get("back"))
	_set_poly_color("ColumnL", a.get("accent"))
	_set_poly_color("ColumnR", a.get("accent"))
	_set_poly_color("Floor", a.get("floor"))
	var img := str(a.get("image", ""))
	if img != "" and ResourceLoader.exists(img):
		var tex = load(img)
		if tex != null:
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.z_index = -100
			s.scale = Vector2(view_width / tex.get_width(), 216.0 / tex.get_height())
			add_child(s)
			move_child(s, 0)

func _set_poly_color(node_name: String, color) -> void:
	if color == null:
		return
	var n := get_node_or_null(node_name)
	if n != null and n is Polygon2D:
		n.color = color

func _reset_round() -> void:
	p1.reset_for_round(Vector2(130.0, 180.0), true)
	p2.reset_for_round(Vector2(254.0, 180.0), false)
	for proj in get_tree().get_nodes_in_group("projectile"):
		proj.queue_free()

func _update_hud() -> void:
	if hud == null:
		return
	hud.set_timer(match_state.timer_seconds())
	hud.set_rounds(match_state.p1_rounds, match_state.p2_rounds)
	var msg := ""
	match match_state.phase:
		MatchState.INTRO:
			msg = "ROUND %d" % (match_state.p1_rounds + match_state.p2_rounds + 1)
		MatchState.ROUND_END:
			msg = "K.O." if (p1.health <= 0 or p2.health <= 0) else "TIME UP"
		MatchState.MATCH_END:
			var w := match_state.match_winner()
			msg = ("PLAYER 1 WINS" if w == 1 else "PLAYER 2 WINS") + "  ·  attack to rematch"
	hud.set_message(msg)

func _rematch_pressed() -> bool:
	for a in ["p1_lp", "p1_mp", "p1_hp", "p2_lp", "p2_mp", "p2_hp"]:
		if Input.is_action_just_pressed(a):
			return true
	return false

func _on_hit(defender: Fighter) -> void:
	_spawn_spark(defender.global_position + Vector2(0.0, -50.0))
	_shake = 9
	if sfx != null:
		sfx.play_hit()

func _spawn_spark(pos: Vector2) -> void:
	var spark := HIT_SPARK.instantiate()
	spark.global_position = pos
	add_child(spark)

func _process_projectiles(delta: float) -> void:
	for proj in get_tree().get_nodes_in_group("projectile"):
		if proj.homing:
			# Chase the opponent (the fighter not on the projectile's team).
			var target: Fighter = p2 if proj.team == p1.team else p1
			var aim: Vector2 = target.global_position + Vector2(0, -50) - proj.global_position
			if aim.length() > 1.0:
				proj.position += aim.normalized() * proj.speed * delta
			proj.ttl -= delta
			if proj.ttl <= 0.0:
				proj.queue_free()
				continue
		else:
			proj.position.x += proj.velocity_x * delta
		if proj.position.x < -40.0 or proj.position.x > view_width + 40.0:
			proj.queue_free()
			continue
		for f in [p1, p2]:
			if f.team == proj.team or f.is_invulnerable():
				continue
			if proj.rect().intersects(f.hurtbox_rect()):
				if f.is_blocking(proj.move):
					f.receive_block(proj.move, proj.owner_facing)
				else:
					f.receive_hit(proj.move, proj.owner_facing)
				_on_hit(f)
				proj.queue_free()
				break
