extends RefCounted
class_name FightEffects

## Pabrik efek visual mode Fight. Dibangun di kode (tanpa .tscn). Efek berumur pendek
## menghapus dirinya lewat tween/timer. Bila sprite objek tersedia di FX_DIR (biji, pecahan,
## teks, shockwave — hasil ekstraksi "Pixel Art Combat Skills Sprite Sheet"), itu yang
## dipakai; kalau tidak ada, jatuh ke bentuk vektor (Polygon2D) agar efek tetap muncul.
##
## Skala: offset posisi mengikuti ukuran tubuh (fighter.scale.x); ukuran efek =
## ukuran tubuh × FightConfig.fx_scale (lihat _k).

const WORDS := ["ANJING!!!", "GOBLOK!!!", "KEPARAT!!!", "ANTEK ASING!!!"]
const FX_DIR := "res://assets/characters/asian_tiger/fx"

static func _tex(name: String) -> Texture2D:
	var p := FX_DIR.path_join(name + ".png")
	return load(p) if ResourceLoader.exists(p) else null

## faktor ukuran efek untuk petarung ini
static func _k(fighter) -> float:
	return float(fighter.scale.x) * FightConfig.fx_scale

## faktor offset posisi (hanya ukuran tubuh)
static func _b(fighter) -> float:
	return float(fighter.scale.x)

# ---- percikan hit/block (kilau singkat yang memudar) ----
static func spawn_hit_spark(root: Node, pos: Vector2, k: float = 1.0) -> void:
	_spark(root, pos, Color(1, 0.9, 0.3), 1.0 * k * FightConfig.fx_scale)

static func spawn_block_spark(root: Node, pos: Vector2, k: float = 1.0) -> void:
	_spark(root, pos, Color(0.6, 0.85, 1.0), 0.7 * k * FightConfig.fx_scale)

static func _spark(root: Node, pos: Vector2, col: Color, scale_mul: float) -> void:
	if root == null: return
	var n := Polygon2D.new()
	n.polygon = _star(18.0 * scale_mul, 9.0 * scale_mul, 6)
	n.color = col
	n.global_position = pos
	n.z_index = 50
	root.add_child(n)
	var tw := n.create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "scale", Vector2(1.8, 1.8), 0.18).from(Vector2(0.4, 0.4)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(n.queue_free)

# ---- Kuda-kuda skill (windup): aura berdenyut + percikan energi naik, selama `duration` ----
static func spawn_windup(root: Node, fighter, duration: float, ultimate: bool) -> void:
	if root == null: return
	var k := _k(fighter)
	var b := _b(fighter)
	var col := Color(1.0, 0.55, 0.15, 0.55) if ultimate else Color(1.0, 0.85, 0.3, 0.45)
	var aura := Polygon2D.new()
	aura.polygon = _ring(46.0)
	aura.color = col
	aura.global_position = fighter.global_position + Vector2(0, -60 * b)
	aura.z_index = 6
	aura.scale = Vector2(0.6, 0.6) * k
	root.add_child(aura)
	var pulse := aura.create_tween()
	pulse.set_loops(maxi(1, int(ceil(duration / 0.3))))
	pulse.tween_property(aura, "scale", Vector2(1.25, 1.25) * k, 0.15).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(aura, "scale", Vector2(0.9, 0.9) * k, 0.15).set_trans(Tween.TRANS_SINE)
	var fade := aura.create_tween()
	fade.tween_interval(duration)
	fade.tween_property(aura, "modulate:a", 0.0, 0.15)
	fade.tween_callback(aura.queue_free)
	var sp := CPUParticles2D.new()
	sp.global_position = fighter.global_position + Vector2(0, -10 * b)
	sp.amount = 28
	sp.lifetime = 0.6
	sp.explosiveness = 0.1
	sp.direction = Vector2(0, -1)
	sp.spread = 25
	sp.initial_velocity_min = 90 * k
	sp.initial_velocity_max = 170 * k
	sp.gravity = Vector2(0, -60 * k)
	sp.scale_amount_min = 2.0 * k
	sp.scale_amount_max = 4.0 * k
	sp.color = Color(col.r, col.g, col.b, 0.9)
	sp.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sp.emission_rect_extents = Vector2(26 * b, 4)
	root.add_child(sp)
	var stop := sp.create_tween()
	stop.tween_interval(duration)
	stop.tween_callback(func(): sp.emitting = false)
	_autofree(sp, duration + 0.7)

# ---- Skill 1: Bad Word — proyektil teks kapital (sprite kata bila ada) ----
static func spawn_bad_word(root: Node, fighter) -> void:
	if root == null: return
	var k := _k(fighter)
	var b := _b(fighter)
	var proj := FightProjectile.new()
	proj.owner_fighter = fighter
	proj.damage = 90
	proj.knockback = 180.0
	proj.velocity = Vector2(fighter.facing * 170.0 * b, 0)   # makian melayang pelan
	proj.lifetime = 6.0                                       # dan bertahan lama
	proj.global_position = fighter.global_position + Vector2(fighter.facing * 70 * b, -95 * b)
	proj.z_index = 40
	var idx := randi() % WORDS.size()
	var tex := _tex("word_%d" % (idx + 1))
	var rect := RectangleShape2D.new()
	if tex != null:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.flip_h = fighter.facing < 0
		proj.add_child(spr)
		rect.size = tex.get_size() * 0.9
	else:
		var lbl := Label.new()
		lbl.text = WORDS[idx]
		lbl.add_theme_font_size_override("font_size", 40)
		lbl.add_theme_color_override("font_color", Color(1, 0.25, 0.15))
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 6)
		lbl.position = Vector2(-70, -30)
		proj.add_child(lbl)
		rect.size = Vector2(150, 60)
	var cs := CollisionShape2D.new()
	cs.shape = rect
	proj.add_child(cs)
	root.add_child(proj)
	var ks := k * 1.6                                         # font makian lebih besar
	proj.scale = Vector2(0.3, 0.3) * ks
	var tw := proj.create_tween()
	tw.tween_property(proj, "scale", Vector2(1, 1) * ks, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ---- Skill 2: Joget Gemoy — shockwave (sprite bila ada) + cincin + bongkahan tanah ----
static func spawn_quake(root: Node, fighter) -> void:
	if root == null: return
	var k := _k(fighter)
	var b := _b(fighter)
	var sw := _tex("shockwave")
	if sw != null:
		var spr := Sprite2D.new()
		spr.texture = sw
		spr.global_position = fighter.global_position + Vector2(0, -sw.get_height() * 0.25 * k)
		spr.z_index = 5
		spr.scale = Vector2(0.3, 0.3) * k
		root.add_child(spr)
		var ts := spr.create_tween()
		ts.set_parallel(true)
		ts.tween_property(spr, "scale", Vector2(1.6, 1.3) * k, 0.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		ts.tween_property(spr, "modulate:a", 0.0, 0.55).set_delay(0.15)
		ts.chain().tween_callback(spr.queue_free)
	var ring := Polygon2D.new()
	ring.polygon = _ring(20.0)
	ring.color = Color(0.9, 0.7, 0.3, 0.6)
	ring.global_position = fighter.global_position
	ring.z_index = 5
	root.add_child(ring)
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(14, 5) * k, 0.45).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "modulate:a", 0.0, 0.45)
	tw.chain().tween_callback(ring.queue_free)
	for i in 8:
		var s := -1 if i % 2 == 0 else 1
		var clod := _clod_node(9.0 + (i % 3) * 3.0, 7.0 + (i % 2) * 3.0, i)
		clod.scale = Vector2.ONE * k
		clod.global_position = fighter.global_position + Vector2(s * 12 * b, -10 * b)
		clod.z_index = 44
		root.add_child(clod)
		var dist := (70.0 + 30.0 * (i >> 1)) * k
		var peak := -(55.0 + 20.0 * (i % 3)) * k
		var tx := clod.create_tween()
		tx.tween_property(clod, "position:x", clod.position.x + s * dist, 0.8)
		var ty := clod.create_tween()
		ty.tween_property(clod, "position:y", clod.position.y + peak, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ty.tween_property(clod, "position:y", fighter.global_position.y - 4, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		ty.tween_property(clod, "modulate:a", 0.0, 0.3)
		ty.tween_callback(clod.queue_free)
	for s in [-1, 1]:
		var dust := CPUParticles2D.new()
		dust.global_position = fighter.global_position + Vector2(s * 40 * b, -6)
		dust.amount = 14
		dust.lifetime = 0.5
		dust.one_shot = true
		dust.explosiveness = 0.9
		dust.direction = Vector2(s, -0.5)
		dust.spread = 40
		dust.initial_velocity_min = 120 * k
		dust.initial_velocity_max = 260 * k
		dust.gravity = Vector2(0, 500)
		dust.scale_amount_min = 2.0 * k
		dust.scale_amount_max = 5.0 * k
		dust.color = Color(0.8, 0.7, 0.5, 0.8)
		root.add_child(dust)
		_autofree(dust, 0.7)

# ---- Skill 3: Kucing Asia — aura transformasi (dash & damage di fighter) ----
static func spawn_cat_aura(root: Node, fighter) -> void:
	if root == null: return
	var k := _k(fighter)
	var aura := Polygon2D.new()
	aura.polygon = _ring(40.0)
	aura.color = Color(1.0, 0.6, 0.2, 0.5)
	aura.global_position = fighter.global_position + Vector2(0, -70 * _b(fighter))
	aura.z_index = 6
	aura.scale = Vector2.ONE * k
	root.add_child(aura)
	var tw := aura.create_tween()
	tw.set_parallel(true)
	tw.tween_property(aura, "scale", Vector2(1.6, 1.6) * k, 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_property(aura, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(aura.queue_free)

# ---- Skill 4: Monokotil Ultimate — dua biji raksasa, satu pecah jadi pecahan ----
static func spawn_monokotil(root: Node, fighter) -> void:
	if root == null: return
	var k := _k(fighter)
	var b := _b(fighter)
	var base: Vector2 = fighter.global_position + Vector2(fighter.facing * 75 * b, -95 * b)
	var seeds: Array = []
	for i in 2:
		var sd := _seed_node(i)
		sd.global_position = base + Vector2(i * 72 * k * fighter.facing, -i * 12 * k)
		sd.z_index = 42
		sd.scale = Vector2(0.2, 0.2) * k
		root.add_child(sd)
		seeds.append(sd)
		var tw := sd.create_tween()
		tw.tween_property(sd, "scale", Vector2(1, 1) * k, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(sd, "position:y", sd.position.y - 10 * k, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.65
	root.add_child(timer)
	timer.timeout.connect(func():
		if is_instance_valid(seeds[1]):
			var p: Vector2 = seeds[1].global_position
			seeds[1].queue_free()
			_burst_fragments(root, fighter, p)
		if is_instance_valid(seeds[0]):
			var t: Tween = seeds[0].create_tween()
			t.tween_interval(0.4)
			t.tween_property(seeds[0], "modulate:a", 0.0, 0.5)
			t.tween_callback(seeds[0].queue_free)
		timer.queue_free()
	)
	timer.start()

static func _burst_fragments(root: Node, fighter, pos: Vector2) -> void:
	var k := _k(fighter)
	_spark(root, pos, Color(1.0, 0.85, 0.45), 1.6 * k)
	for i in 6:
		var frag := FightProjectile.new()
		frag.owner_fighter = fighter
		frag.damage = 70
		frag.knockback = 140.0
		frag.lifetime = 3.2
		frag.fall_gravity = 240.0 * k                         # lintasan lebih lambat & panjang
		var ang := deg_to_rad(-(18.0 + i * 11.0))
		frag.velocity = Vector2(cos(ang) * fighter.facing, sin(ang)) * (140.0 + i * 8.0) * k
		frag.global_position = pos
		frag.scale = Vector2.ONE * k
		var cs := CollisionShape2D.new()
		var circ := CircleShape2D.new()
		circ.radius = 15
		cs.shape = circ
		frag.add_child(cs)
		frag.add_child(_clod_node(13.0 + (i % 2) * 3.0, 16.0 + (i % 3) * 2.0, i))
		frag.z_index = 41
		root.add_child(frag)

## Node "biji": sprite seed_1/seed_2 bila ada; jika tidak, outline gelap + isi cokelat + kilau.
static func _seed_node(i: int) -> Node2D:
	var tex := _tex("seed_%d" % (i + 1))
	if tex != null:
		var spr := Sprite2D.new()
		spr.texture = tex
		return spr
	var outline := Polygon2D.new()
	outline.polygon = _ellipse(37.0, 47.0, 18)
	outline.color = Color(0.25, 0.14, 0.06)
	var fill := Polygon2D.new()
	fill.polygon = _ellipse(34.0, 44.0, 18)
	fill.color = Color(0.62, 0.40, 0.18)
	outline.add_child(fill)
	var shine := Polygon2D.new()
	shine.polygon = _ellipse(12.0, 22.0, 10)
	shine.position = Vector2(-10, -13)
	shine.color = Color(0.85, 0.65, 0.40)
	outline.add_child(shine)
	return outline

## Bongkahan/pecahan: sprite frag_1..4 bila ada; jika tidak, outline gelap + isi cokelat.
static func _clod_node(rx: float, ry: float, i: int = 0) -> Node2D:
	var tex := _tex("frag_%d" % ((i % 4) + 1))
	if tex != null:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.rotation = float(i) * 0.9
		return spr
	var outline := Polygon2D.new()
	outline.polygon = _ellipse(rx + 2.0, ry + 2.0, 10)
	outline.color = Color(0.22, 0.13, 0.06)
	var fill := Polygon2D.new()
	fill.polygon = _ellipse(rx, ry, 10)
	fill.color = Color(0.55, 0.36, 0.17)
	outline.add_child(fill)
	return outline

# ---- util geometri ----
static func _star(outer: float, inner: float, points: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in points * 2:
		var r := outer if i % 2 == 0 else inner
		var a := PI * i / points
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

static func _ring(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

static func _ellipse(rx: float, ry: float, seg: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * i / seg
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts

static func _autofree(n: Node, t: float) -> void:
	var tm := n.get_tree().create_timer(t) if n.is_inside_tree() else null
	if tm:
		tm.timeout.connect(n.queue_free)
