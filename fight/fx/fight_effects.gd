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

const KOL_FX_DIR := "res://assets/characters/kolonel/fx"
static func _ktex(name: String) -> Texture2D:
	var p := KOL_FX_DIR.path_join(name + ".png")
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

# ---- Skill 1: Bad Word — makian "muncul" dulu di atas kepala saat kuda-kuda ----
## Sprite kata membesar (elastis) & bergetar di atas kepala selama `duration`, lalu hilang
## tepat saat proyektil sebenarnya dilempar (spawn_bad_word memakai kata yang sama).
static func spawn_bad_word_charge(root: Node, fighter, duration: float, idx: int) -> void:
	if root == null: return
	var b := _b(fighter)
	var n := _word_node(idx)
	n.global_position = fighter.global_position + Vector2(fighter.facing * 10 * b, -185 * b)
	n.z_index = 60
	n.scale = Vector2(0.1, 0.1)
	root.add_child(n)
	var grow := n.create_tween()
	grow.tween_property(n, "scale", Vector2.ONE, minf(0.5, duration * 0.6)).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var shake := n.create_tween()
	shake.set_loops(maxi(1, int(ceil(duration / 0.08))))
	shake.tween_property(n, "rotation", deg_to_rad(5), 0.04)
	shake.tween_property(n, "rotation", deg_to_rad(-5), 0.04)
	var done := n.create_tween()
	done.tween_interval(duration)
	done.tween_callback(n.queue_free)

## Node kata: teks dirender Godot (bukan sprite, supaya tajam di skala besar). Dua lapis
## Label: belakang = outline hitam tebal + bayangan; depan = isi kuning + outline merah.
## Huruf ditinggikan-rampingkan & dimiringkan ala komik. Origin node = pusat teks.
const WORD_FONT_SIZE := 144
const WORD_BOX := Vector2(1600, 240)
static var _word_font: FontVariation = null

static func _get_word_font() -> FontVariation:
	if _word_font == null:
		_word_font = FontVariation.new()
		_word_font.base_font = ThemeDB.fallback_font
		_word_font.variation_embolden = 1.1                       # tebal sintetis
		_word_font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.22, 1.0), Vector2.ZERO)   # miring
	return _word_font

static func _word_node(idx: int) -> Node2D:
	return _styled_text(WORDS[idx], WORD_FONT_SIZE, Color(1.0, 0.86, 0.18), Color(0.82, 0.08, 0.06), Color.BLACK)

## Teks bergaya komik (vektor, tajam di ukuran besar): isi `fill`, outline `line`, outline luar
## `back` tebal + bayangan. Origin node = pusat teks. Dipakai makian Bad Word & popup "-999".
static func _styled_text(text: String, fsize: int, fill: Color, line: Color, back: Color) -> Node2D:
	var holder := Node2D.new()
	var inner := Node2D.new()
	inner.scale = Vector2(0.72, 1.0)                              # ramping-tinggi
	inner.rotation = deg_to_rad(-4)
	holder.add_child(inner)
	var box := Vector2(WORD_BOX.x, fsize * 1.8)
	for layer in 2:
		var lbl := Label.new()
		lbl.text = text
		lbl.add_theme_font_override("font", _get_word_font())
		lbl.add_theme_font_size_override("font_size", fsize)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size = box
		lbl.position = -box / 2.0
		if layer == 0:
			lbl.add_theme_color_override("font_color", back)
			lbl.add_theme_color_override("font_outline_color", back)
			lbl.add_theme_constant_override("outline_size", int(fsize * 0.17))
			lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
			lbl.add_theme_constant_override("shadow_offset_x", int(fsize * 0.055))
			lbl.add_theme_constant_override("shadow_offset_y", int(fsize * 0.055))
		else:
			lbl.add_theme_color_override("font_color", fill)
			lbl.add_theme_color_override("font_outline_color", line)
			lbl.add_theme_constant_override("outline_size", int(fsize * 0.085))
		inner.add_child(lbl)
	return holder

## Popup angka/teks di atas lawan (mis. "-999"): pop-in, naik, memudar.
static func spawn_popup_text(root: Node, pos: Vector2, text: String) -> void:
	if root == null or text == "": return
	var n := _styled_text(text, 110, Color(0.96, 0.12, 0.12), Color.WHITE, Color(0.25, 0.0, 0.0))
	n.global_position = pos
	n.z_index = 70
	n.scale = Vector2(0.3, 0.3)
	root.add_child(n)
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var t2 := n.create_tween()
	t2.set_parallel(true)
	t2.tween_property(n, "position:y", n.position.y - 70.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t2.tween_property(n, "modulate:a", 0.0, 0.4).set_delay(0.75)
	t2.chain().tween_callback(n.queue_free)

# ---- Mr. Kol-Onel: "Pokoknya Ada" — sinar biru (sel Damage) + popup "-999" saat kena ----
static func spawn_pokok_beam(root: Node, fighter, hit_text: String = "") -> void:
	if root == null: return
	var b := _b(fighter)
	var k := _k(fighter)
	var proj := FightProjectile.new()
	proj.owner_fighter = fighter
	proj.damage = 190
	proj.knockback = 420.0
	proj.hit_text = hit_text
	proj.velocity = Vector2(fighter.facing * 520.0 * b, 0)
	proj.lifetime = 2.5
	proj.global_position = fighter.global_position + Vector2(fighter.facing * 95 * b, -80 * b)
	proj.z_index = 45
	var tex := _ktex("beam")
	var rect := RectangleShape2D.new()
	if tex != null:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.flip_h = fighter.facing < 0
		proj.add_child(spr)
		rect.size = tex.get_size() * Vector2(0.9, 0.6)
	else:
		var poly := Polygon2D.new()
		poly.polygon = _ellipse(50.0, 18.0, 16)
		poly.color = Color(0.4, 0.7, 1.0)
		proj.add_child(poly)
		rect.size = Vector2(90, 36)
	var cs := CollisionShape2D.new()
	cs.shape = rect
	proj.add_child(cs)
	root.add_child(proj)
	var ks := k * 0.8
	proj.scale = Vector2(0.4, 0.4) * ks
	var tw := proj.create_tween()
	tw.tween_property(proj, "scale", Vector2.ONE * ks, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_spark(root, proj.global_position, Color(0.6, 0.85, 1.0), 1.4 * k)

# ---- Mr. Kol-Onel: "Beast's Smile" / "Macho" — kilau tatapan melesat ke depan ----
static func spawn_gaze(root: Node, fighter) -> void:
	if root == null: return
	var k := _k(fighter)
	var b := _b(fighter)
	var eye: Vector2 = fighter.global_position + Vector2(fighter.facing * 18 * b, -118 * b)
	for i in 3:
		var s := Polygon2D.new()
		s.polygon = _star(10.0 * k, 4.0 * k, 4)
		s.color = Color(1.0, 0.95, 0.75) if i % 2 == 0 else Color(1.0, 0.6, 0.85)
		s.global_position = eye + Vector2(0, (i - 1) * 10 * b)
		s.z_index = 50
		root.add_child(s)
		var tw := s.create_tween()
		tw.set_parallel(true)
		tw.tween_property(s, "position:x", s.position.x + fighter.facing * (260.0 + i * 120.0) * k, 0.35 + i * 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "rotation", TAU, 0.45)
		tw.tween_property(s, "modulate:a", 0.0, 0.45)
		tw.chain().tween_callback(s.queue_free)
	_spark(root, eye, Color(1, 1, 1), 0.9 * k)

# ---- Mr. Kol-Onel: "Bobo Yuk" — jejak hati selama melayang (anak node fighter) ----
static func spawn_hearts_trail(fighter, duration: float) -> void:
	var p := CPUParticles2D.new()
	p.texture = _ktex("heart")
	p.color = Color(1.0, 0.5, 0.78) if p.texture == null else Color.WHITE
	p.amount = 26
	p.lifetime = 0.9
	p.local_coords = false
	p.position = Vector2(0, -70)
	p.direction = Vector2(-fighter.facing, -0.2)
	p.spread = 35
	p.initial_velocity_min = 60
	p.initial_velocity_max = 140
	p.gravity = Vector2(0, -40)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 20
	p.z_index = 44
	fighter.add_child(p)
	var t := p.create_tween()
	t.tween_interval(duration)
	t.tween_callback(func(): p.emitting = false)
	_autofree(p, duration + 1.2)

## Perkiraan kotak tabrak teks (satuan node kata, sebelum skala proyektil).
static func _word_hit_size(idx: int) -> Vector2:
	var n: int = String(WORDS[idx]).length()
	return Vector2(WORD_FONT_SIZE * 0.56 * n * 0.72, WORD_FONT_SIZE * 0.85)

# ---- Skill 1: Bad Word — proyektil teks kapital (teks Godot, bukan sprite) ----
## `stun`: lawan terpaku; kata lalu MENIMPA tubuh lawan selama stun (linger).
static func spawn_bad_word(root: Node, fighter, stun: float = 0.0, idx: int = -1) -> void:
	if root == null: return
	var b := _b(fighter)
	if idx < 0:
		idx = randi() % WORDS.size()
	var proj := FightProjectile.new()
	proj.owner_fighter = fighter
	proj.damage = 90
	proj.knockback = 180.0
	proj.stun = stun
	proj.linger = maxf(1.0, stun)
	proj.stick_offset_y = -100.0                               # menimpa badan/kepala lawan
	proj.velocity = Vector2(fighter.facing * 170.0 * b, 0)   # makian melayang pelan
	proj.lifetime = 6.0                                       # dan bertahan lama
	proj.global_position = fighter.global_position + Vector2(fighter.facing * 70 * b, -95 * b)
	proj.z_index = 60
	proj.add_child(_word_node(idx))
	var rect := RectangleShape2D.new()
	rect.size = _word_hit_size(idx)
	var cs := CollisionShape2D.new()
	cs.shape = rect
	proj.add_child(cs)
	root.add_child(proj)
	proj.scale = Vector2(0.3, 0.3)
	var tw := proj.create_tween()
	tw.tween_property(proj, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ---- Skill 2: Joget Gemoy — shockwave (sprite bila ada) + cincin + bongkahan tanah ----
static func spawn_quake(root: Node, fighter) -> void:
	if root == null: return
	var k := _k(fighter)
	var b := _b(fighter)
	# erupsi tanah (sel "Earthquake Effect") di belakang petarung, membesar lalu memudar
	var qb := _tex("quake_burst")
	if qb != null:
		var eq := Sprite2D.new()
		eq.texture = qb
		eq.flip_h = fighter.facing < 0
		eq.global_position = fighter.global_position + Vector2(0, -qb.get_height() * 0.5 * b)
		eq.z_index = 4
		eq.scale = Vector2(0.6, 0.6) * b
		root.add_child(eq)
		var te := eq.create_tween()
		te.set_parallel(true)
		te.tween_property(eq, "scale", Vector2(1.25, 1.25) * b, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		te.tween_property(eq, "modulate:a", 0.0, 0.5).set_delay(0.35)
		te.chain().tween_callback(eq.queue_free)
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
	# debu saat kucing melesat
	spawn_dust(root, fighter.global_position + Vector2(-fighter.facing * 30 * _b(fighter), 0), _b(fighter))

# ---- Skill 4: Monokotil Ultimate — dua biji raksasa, satu pecah jadi pecahan ----
static func spawn_monokotil(root: Node, fighter, stun: float = 0.0) -> void:
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
			_seed_break_fx(root, fighter, p)
			_burst_fragments(root, fighter, p, stun)
		if is_instance_valid(seeds[0]):
			var t: Tween = seeds[0].create_tween()
			t.tween_interval(0.4)
			t.tween_property(seeds[0], "modulate:a", 0.0, 0.5)
			t.tween_callback(seeds[0].queue_free)
		timer.queue_free()
	)
	timer.start()

## Saat biji pecah: sel "Seed Breaks" sekejap, lalu awan "Fragments Scatter" meluncur ke arah lawan.
static func _seed_break_fx(root: Node, fighter, pos: Vector2) -> void:
	var k := _k(fighter)
	var sb := _tex("seed_break")
	if sb != null:
		var s := Sprite2D.new()
		s.texture = sb
		s.flip_h = fighter.facing < 0
		s.global_position = pos
		s.z_index = 42
		s.scale = Vector2.ONE * k
		root.add_child(s)
		var t := s.create_tween()
		t.tween_property(s, "scale", Vector2(1.2, 1.2) * k, 0.12)
		t.tween_property(s, "modulate:a", 0.0, 0.2)
		t.tween_callback(s.queue_free)
	var sc := _tex("frag_scatter")
	if sc != null:
		var c := Sprite2D.new()
		c.texture = sc
		c.flip_h = fighter.facing < 0
		c.global_position = pos + Vector2(fighter.facing * sc.get_width() * 0.45 * k, 0)
		c.z_index = 40
		c.scale = Vector2(0.4, 0.4) * k
		c.modulate.a = 0.0
		root.add_child(c)
		var t2 := c.create_tween()
		t2.set_parallel(true)
		t2.tween_property(c, "modulate:a", 1.0, 0.1)
		t2.tween_property(c, "scale", Vector2.ONE * k, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t2.tween_property(c, "position:x", c.position.x + fighter.facing * 220.0 * k, 1.3)
		t2.tween_property(c, "modulate:a", 0.0, 0.5).set_delay(0.8)
		t2.chain().tween_callback(c.queue_free)

## Ledakan saat skill mengenai lawan (sel "Fragments Hit", bagian ledakannya saja).
static func spawn_impact_burst(root: Node, pos: Vector2, body_k: float) -> void:
	if root == null: return
	var k := body_k * FightConfig.fx_scale
	var tex := _tex("frag_burst")
	if tex == null:
		_spark(root, pos, Color(1.0, 0.8, 0.3), 1.8 * k)
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.global_position = pos
	s.z_index = 48
	s.scale = Vector2(0.5, 0.5) * k
	root.add_child(s)
	var t := s.create_tween()
	t.set_parallel(true)
	t.tween_property(s, "scale", Vector2(1.15, 1.15) * k, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "modulate:a", 0.0, 0.3).set_delay(0.12)
	t.chain().tween_callback(s.queue_free)

## Debu di kaki (sel "Damage + Knockback": awan debunya saja) — jatuh ke lantai / tabrakan kucing.
static func spawn_dust(root: Node, pos: Vector2, body_k: float) -> void:
	if root == null: return
	var k := body_k * FightConfig.fx_scale
	var tex := _tex("dust_%d" % (1 + randi() % 3))
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.global_position = pos + Vector2(0, -tex.get_height() * 0.35 * k)
	s.z_index = 43
	s.scale = Vector2(0.5, 0.5) * k
	root.add_child(s)
	var t := s.create_tween()
	t.set_parallel(true)
	t.tween_property(s, "scale", Vector2(1.1, 1.0) * k, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "position:y", s.position.y - 14.0 * k, 0.5)
	t.tween_property(s, "modulate:a", 0.0, 0.45).set_delay(0.15)
	t.chain().tween_callback(s.queue_free)

static func _burst_fragments(root: Node, fighter, pos: Vector2, stun: float = 0.0) -> void:
	var k := _k(fighter)
	_spark(root, pos, Color(1.0, 0.85, 0.45), 1.6 * k)
	for i in 6:
		var frag := FightProjectile.new()
		frag.owner_fighter = fighter
		frag.damage = 70
		frag.knockback = 140.0
		frag.stun = stun
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

# ---- Stun: bintang kuning berputar mengelilingi kepala selama `duration` ----
static func spawn_stun(root: Node, fighter, duration: float, halo: bool = false) -> Node:
	if root == null: return null
	var n := StunStars.new()
	n.target = fighter
	n.k = _k(fighter)
	n.b = _b(fighter)
	if halo:
		n.halo_tex = _ktex("halo")
	n.z_index = 45
	root.add_child(n)
	var fade := n.create_tween()
	fade.tween_interval(maxf(0.0, duration - 0.25))
	fade.tween_property(n, "modulate:a", 0.0, 0.25)
	fade.tween_callback(n.queue_free)
	return n

## Node bintang stun: mengikuti kepala fighter, 3 bintang berputar pada elips.
class StunStars extends Node2D:
	var target: Node2D
	var k := 1.0
	var b := 1.0
	var _t := 0.0
	var _stars: Array = []
	var halo_tex: Texture2D = null        # halo (sheet Kol-Onel) di atas bintang, opsional

	func _ready() -> void:
		if halo_tex != null:
			var h := Sprite2D.new()
			h.texture = halo_tex
			h.position = Vector2(0, -22.0 * k)
			h.scale = Vector2.ONE * k * 0.7
			h.z_index = 2
			add_child(h)
			var tw := h.create_tween()
			tw.set_loops()
			tw.tween_property(h, "rotation", deg_to_rad(8), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(h, "rotation", deg_to_rad(-8), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		for i in 3:
			var s := Polygon2D.new()
			s.polygon = FightEffects._star(9.0 * k, 4.0 * k, 5)
			s.color = Color(1.0, 0.9, 0.25)
			add_child(s)
			_stars.append(s)
		_update_pos(0.0)

	func _process(delta: float) -> void:
		if not is_instance_valid(target):
			queue_free()
			return
		_update_pos(delta)

	func _update_pos(delta: float) -> void:
		_t += delta
		global_position = target.global_position + Vector2(0, -150.0 * b)
		for i in _stars.size():
			var a: float = _t * 5.5 + TAU * i / _stars.size()
			var s: Polygon2D = _stars[i]
			s.position = Vector2(cos(a) * 30.0 * k, sin(a) * 9.0 * k)
			s.rotation = a * 1.5
			s.z_index = 1 if sin(a) > 0.0 else -1
			s.scale = Vector2.ONE * (0.8 + 0.3 * (sin(a) + 1.0) * 0.5)

static func _autofree(n: Node, t: float) -> void:
	var tm := n.get_tree().create_timer(t) if n.is_inside_tree() else null
	if tm:
		tm.timeout.connect(n.queue_free)
