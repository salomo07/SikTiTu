extends Node2D
## Controller pertandingan Fight. Membangun arena (latar+lantai+kamera), dua fighter,
## HUD, dan menu jeda; menjalankan alur ronde best-of-3 + timer; menangani screen shake.
## Pilihan (karakter/arena/mode/tingkat AI) diambil dari autoload FightConfig.

const FIGHTER := preload("res://fight/fighter/fighter.tscn")
const ENTRY_SCENE := "res://fight/scenes/character_select.tscn"
const ROUND_TIME := 60
const LAND_H := 150.0              # tinggi pita tanah di bawah arena (memperkecil area banjir yang terlihat)

var p1: Fighter
var p2: Fighter
var hud: FightHUD
var pause_menu: FightPauseMenu
var camera: Camera2D

var _vw := 0.0
var _vh := 0.0
var _floor_y := 0.0
var _p1_wins := 0
var _p2_wins := 0
var _round_no := 0
var _fighting := false
var _round_t := float(ROUND_TIME)
var _match_over := false

var _cam_base := Vector2.ZERO
var _shake_amt := 0.0
var _shake_t := 0.0

func _ready() -> void:
	var vr := get_viewport().get_visible_rect().size
	_vw = vr.x
	_vh = vr.y
	_floor_y = _vh - LAND_H
	_build_background()
	_build_floor()
	_build_camera()
	_build_fighters()
	_build_ui()
	_start_match()

# ---------------------------------------------------------------- bangun arena
func _build_background() -> void:
	var cl := CanvasLayer.new()
	cl.layer = -10
	add_child(cl)
	var tr := TextureRect.new()
	tr.size = Vector2(_vw, _vh)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var path := FightConfig.arena_path(FightConfig.arena_id)
	if path != "" and ResourceLoader.exists(path):
		tr.texture = load(path)
	cl.add_child(tr)
	# pita tanah: tepian rumput/lumpur terang + badan tanah cokelat + bayangan dasar
	var edge := ColorRect.new()
	edge.color = Color(0.45, 0.38, 0.22, 0.95)
	edge.size = Vector2(_vw, 10)
	edge.position = Vector2(0, _floor_y)
	cl.add_child(edge)
	var ground := ColorRect.new()
	ground.color = Color(0.30, 0.21, 0.13, 0.96)
	ground.size = Vector2(_vw, _vh - _floor_y - 10)
	ground.position = Vector2(0, _floor_y + 10)
	cl.add_child(ground)
	var deep := ColorRect.new()
	deep.color = Color(0.16, 0.11, 0.07, 0.9)
	deep.size = Vector2(_vw, maxf(0.0, (_vh - _floor_y) * 0.35))
	deep.position = Vector2(0, _vh - deep.size.y)
	cl.add_child(deep)

func _build_floor() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(_vw / 2.0, _floor_y + 20.0)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(_vw * 2.0, 40)
	cs.shape = rect
	body.add_child(cs)
	add_child(body)

func _build_camera() -> void:
	camera = Camera2D.new()
	_cam_base = Vector2(_vw / 2.0, _vh / 2.0)
	camera.position = _cam_base
	add_child(camera)
	camera.make_current()

func _build_fighters() -> void:
	p1 = FIGHTER.instantiate()
	p2 = FIGHTER.instantiate()
	p1.def = CharacterRegistry.get_def(FightConfig.p1_char)
	p2.def = CharacterRegistry.get_def(FightConfig.p2_char)
	p1.is_player = true
	p2.is_player = (FightConfig.mode == FightConfig.Mode.VS_PLAYER)
	if not p2.is_player:
		p2.brain = FighterAI.new(FightConfig.ai_level)
	for f in [p1, p2]:
		f.arena_min_x = 60.0
		f.arena_max_x = _vw - 60.0
		f.scale = Vector2.ONE * FightConfig.char_scale   # rasio karakter lebih besar (tubuh+hitbox ikut)
		add_child(f)
	p1.opponent = p2
	p2.opponent = p1
	p1.hp = p1.def.max_hp
	p2.hp = p2.def.max_hp
	p1.ko.connect(_on_ko.bind(p1))
	p2.ko.connect(_on_ko.bind(p2))

func _build_ui() -> void:
	hud = FightHUD.new()
	add_child(hud)
	hud.setup(p1.def.display_name, p2.def.display_name, _wins_needed())
	p1.hp_changed.connect(func(hp, mx): hud.set_hp(1, hp, mx))
	p2.hp_changed.connect(func(hp, mx): hud.set_hp(2, hp, mx))
	p1.meter_changed.connect(func(v): hud.set_meter(1, v))
	p2.meter_changed.connect(func(v): hud.set_meter(2, v))

	pause_menu = FightPauseMenu.new()
	add_child(pause_menu)
	pause_menu.resumed.connect(_resume)
	pause_menu.rematch.connect(_rematch)
	pause_menu.quit_to_menu.connect(_quit_to_menu)

func _wins_needed() -> int:
	return FightConfig.rounds_to_win

# ---------------------------------------------------------------- alur ronde
func _start_match() -> void:
	_p1_wins = 0
	_p2_wins = 0
	_round_no = 0
	_match_over = false
	hud.set_rounds(0, 0)
	_next_round()

func _next_round() -> void:
	_round_no += 1
	_fighting = false
	_round_t = float(ROUND_TIME)
	p1.reset_for_round(_vw * 0.3, 1)
	p2.reset_for_round(_vw * 0.7, -1)
	p1.frozen = true
	p2.frozen = true
	hud.set_timer(ROUND_TIME)
	hud.banner("RONDE %d" % _round_no, 0.9)
	await get_tree().create_timer(1.2).timeout
	if _match_over:
		return
	hud.banner("FIGHT!", 0.6)
	p1.frozen = false
	p2.frozen = false
	_fighting = true

func _process(delta: float) -> void:
	_tick_shake(delta)
	if Input.is_action_just_pressed("fight_pause") and _fighting and not get_tree().paused:
		_open_pause()
		return
	if _match_over:
		if Input.is_action_just_pressed("fight_confirm"):
			_rematch()
		elif Input.is_action_just_pressed("fight_pause"):
			_quit_to_menu()
		return
	if not _fighting:
		return
	_round_t -= delta
	hud.set_timer(int(ceil(_round_t)))
	if _round_t <= 0.0:
		_end_round_by_time()

func _on_ko(loser: Fighter) -> void:
	if not _fighting:
		return
	var winner := 2 if loser == p1 else 1
	_end_round(winner, "K.O.")

func _end_round_by_time() -> void:
	var winner := 0
	if p1.hp > p2.hp: winner = 1
	elif p2.hp > p1.hp: winner = 2
	_end_round(winner, "WAKTU HABIS")

func _end_round(winner: int, reason: String) -> void:
	_fighting = false
	p1.frozen = true
	p2.frozen = true
	if winner == 1: _p1_wins += 1
	elif winner == 2: _p2_wins += 1
	hud.set_rounds(_p1_wins, _p2_wins)
	var msg := reason
	if winner == 0:
		msg = "SERI"
	hud.banner(msg, 1.4)
	await get_tree().create_timer(2.0).timeout
	if _p1_wins >= _wins_needed() or _p2_wins >= _wins_needed():
		_end_match()
	else:
		_next_round()

func _end_match() -> void:
	_match_over = true
	_fighting = false
	var champ := p1 if _p1_wins > _p2_wins else p2
	hud.banner_persist("%s MENANG!\n\nENTER: ulang   ·   ESC: menu" % champ.def.display_name)

# ---------------------------------------------------------------- pengumuman skill
## Dipanggil Fighter saat mulai skill: nama skill tampil; ultimate = layar meredup + slow-motion.
func announce_skill(text: String, ultimate: bool) -> void:
	if text == "":
		return
	hud.skill_title(text.to_upper() + "!", ultimate)
	if ultimate:
		_ultimate_flash()

func _ultimate_flash() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.0)
	dim.size = Vector2(_vw, _vh)
	cl.add_child(dim)
	var tw := dim.create_tween()
	tw.tween_property(dim, "color:a", 0.55, 0.12)
	tw.tween_interval(0.5)
	tw.tween_property(dim, "color:a", 0.0, 0.3)
	tw.tween_callback(cl.queue_free)
	shake(6.0, 0.4)
	# slow-motion singkat; pulih lewat timer waktu-nyata (abaikan time_scale) agar tak terjebak
	Engine.time_scale = 0.35
	get_tree().create_timer(0.55, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

# ---------------------------------------------------------------- pause
func _open_pause() -> void:
	get_tree().paused = true
	pause_menu.open()

func _resume() -> void:
	pause_menu.close()
	get_tree().paused = false

func _rematch() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	pause_menu.close()
	get_tree().reload_current_scene()

func _quit_to_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	if ResourceLoader.exists(ENTRY_SCENE):
		get_tree().change_scene_to_file(ENTRY_SCENE)
	else:
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")

# ---------------------------------------------------------------- shake
func shake(amount: float, time: float) -> void:
	_shake_amt = maxf(_shake_amt, amount)
	_shake_t = maxf(_shake_t, time)

func _tick_shake(delta: float) -> void:
	if camera == null:
		return
	if _shake_t > 0.0:
		_shake_t -= delta
		var o := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amt
		camera.position = _cam_base + o
		_shake_amt = move_toward(_shake_amt, 0.0, delta * 30.0)
	else:
		camera.position = _cam_base
