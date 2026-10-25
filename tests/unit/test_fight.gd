extends GutTest

## Uji logika inti mode Fight: data karakter, pindai arena, pembangun frame KFM,
## dan perilaku AI (bukti: tidak menyerang terus-menerus).

const FIGHTER := preload("res://fight/fighter/fighter.tscn")

# ---- karakter ----
func test_registry_has_both_characters():
	var ids := CharacterRegistry.ids()
	assert_true(ids.has("kfm"), "kfm ada")
	assert_true(ids.has("asian_tiger"), "asian_tiger ada")

func test_asian_tiger_has_four_skills():
	var d := CharacterRegistry.get_def("asian_tiger")
	assert_eq(d.skills.size(), 4, "Mr. Asian Tiger punya 4 skill")
	for k in ["bad_word", "joget_gemoy", "kucing_asia", "monokotil"]:
		assert_true(d.skills.has(k), "punya skill %s" % k)

func test_asian_tiger_movement_anims():
	# sprite jalan/lari/jatuh hasil potongan ulang sheet combat
	var d := CharacterRegistry.get_def("asian_tiger")
	assert_not_null(d.frames, "frames tiger termuat")
	if d.frames == null:
		return
	for a in ["walk_fwd", "walk_back", "run", "down", "knockdown", "getup", "lk", "hk"]:
		assert_true(d.frames.has_animation(a), "anim %s ada" % a)
	assert_eq(d.frames.get_frame_count("walk_fwd"), 4, "siklus jalan 4 frame")
	assert_eq(d.frames.get_frame_count("run"), 2, "lari 2 frame")
	assert_eq(d.frames.get_frame_count("knockdown"), 3, "jatuh 3 frame")
	assert_true(d.anims.has("run") and d.anims.has("down"), "pemetaan run/down ada")
	# semua pose skill dari sheet terpakai: tiap skill punya anim kuda-kuda/aktif/pemulihan
	for sk in d.skills.values():
		for key in ["anim", "anim_active", "anim_recovery"]:
			assert_true(sk.has(key), "skill %s punya %s" % [sk["name"], key])
			if sk.has(key):
				assert_true(d.frames.has_animation(sk[key]), "anim %s ada di frames" % sk[key])
	assert_eq(d.frames.get_frame_count("kucing_start"), 3, "Transformation Start→Effect→Cat Form")
	assert_eq(d.frames.get_frame_count("kucing_end"), 3, "Collision→Recovery (Cat)→Return to Human")
	assert_eq(d.frames.get_frame_count("joget_start"), 5, "Start Dance + Dance 1–4")
	for fx in ["quake_burst", "seed_break", "frag_scatter", "frag_burst", "dust_1", "dust_2", "dust_3"]:
		assert_true(ResourceLoader.exists("res://assets/characters/asian_tiger/fx/%s.png" % fx), "fx %s ada" % fx)

func test_kolonel_character():
	assert_true(CharacterRegistry.ids().has("kolonel"), "Mr. Kol-Onel terdaftar")
	var d := CharacterRegistry.get_def("kolonel")
	assert_eq(d.display_name, "Mr. Kol-Onel")
	for k in ["pokoknya_ada", "beasts_smile", "macho", "bobo_yuk"]:
		assert_true(d.skills.has(k), "punya skill %s" % k)
	assert_true(d.skills["bobo_yuk"].has("dash_speed"), "Bobo Yuk melayang (dash)")
	assert_eq(d.skills["pokoknya_ada"].get("hit_text", ""), "-999")
	assert_not_null(d.frames, "frames Kol-Onel termuat")
	if d.frames == null:
		return
	for a in ["idle", "walk_fwd", "run", "jump", "block", "hit", "knockdown", "down", "getup",
			"lp", "hp", "lk", "pokok_start", "pokok_fire", "beast_start", "beast_pose",
			"macho_start", "macho_pose", "bobo_start", "bobo_fly", "bobo_end"]:
		assert_true(d.frames.has_animation(a), "anim %s ada" % a)
	assert_eq(d.frames.get_frame_count("beast_start"), 3, "duduk → gigit bibir → kacamata")
	assert_true(ResourceLoader.exists(d.portrait_path), "portrait ada")
	for fx in ["beam", "halo", "heart"]:
		assert_true(ResourceLoader.exists("res://assets/characters/kolonel/fx/%s.png" % fx), "fx %s ada" % fx)

func test_bad_word_text_is_godot_rendered():
	# kata makian dirender Godot (Label), bukan sprite — agar tajam saat besar
	var n: Node2D = FightEffects._word_node(0)
	var labels := n.find_children("*", "Label", true, false)
	assert_eq(labels.size(), 2, "dua lapis Label (outline hitam + isi kuning)")
	assert_eq(n.find_children("*", "Sprite2D", true, false).size(), 0, "tanpa Sprite2D")
	assert_true(FightEffects._word_hit_size(3).x > FightEffects._word_hit_size(1).x, "kotak tabrak ikut panjang kata")
	n.free()

func test_characters_have_basic_normals():
	for id in CharacterRegistry.ids():
		var d := CharacterRegistry.get_def(id)
		for n in ["lp", "hp", "lk", "hk"]:
			assert_true(d.normals.has(n), "%s punya normal %s" % [id, n])

# ---- arena (data-driven dari folder) ----
func test_arena_scan_finds_banjir_and_dpr():
	var arenas := FightConfig.get_arenas()
	var ids := []
	for a in arenas:
		ids.append(a["id"])
	assert_true(ids.has("banjir"), "arena banjir terpindai")
	assert_true(ids.has("dpr"), "arena dpr terpindai")

func test_arena_path_resolves():
	var p := FightConfig.arena_path("dpr")
	assert_true(p.ends_with("dpr.png"), "path arena benar: %s" % p)

# ---- frame KFM ----
func test_kfm_frames_build():
	var frames := KfmFrames.get_frames()
	assert_not_null(frames, "SpriteFrames terbangun")
	assert_true(frames.has_animation("idle"), "ada anim idle")
	assert_true(frames.has_animation("walk_fwd"), "ada anim walk_fwd")
	assert_gt(frames.get_frame_count("idle"), 0, "idle punya frame")

# ---- AI: tidak menyerang terus-menerus ----
func _make_fighter(player: bool) -> Fighter:
	var f: Fighter = FIGHTER.instantiate()
	f.def = CharacterRegistry.get_def("kfm")
	f.is_player = player
	add_child_autofree(f)
	return f

func test_ai_command_shape():
	var ai := FighterAI.new(1)
	var me := _make_fighter(false)
	var foe := _make_fighter(true)
	me.global_position = Vector2(300, 400)
	foe.global_position = Vector2(360, 400)
	var cmd := ai.think(me, foe)
	for key in ["move", "jump", "crouch", "block", "attack", "skill"]:
		assert_true(cmd.has(key), "command punya field %s" % key)

func test_ai_does_not_attack_every_frame_when_close():
	var ai := FighterAI.new(2)   # paling agresif
	var me := _make_fighter(false)
	var foe := _make_fighter(true)
	me.global_position = Vector2(300, 400)
	foe.global_position = Vector2(355, 400)   # jarak dekat (dalam jangkauan)
	me.meter = 0.0                            # cegah skill mendominasi
	var attack_frames := 0
	var total := 240
	for i in total:
		var cmd := ai.think(me, foe)
		if cmd["attack"] != "" or cmd["skill"] >= 0:
			attack_frames += 1
	# Harus ADA serangan, tapi jauh dari tiap frame (ada jeda/cooldown).
	assert_gt(attack_frames, 0, "AI tetap menyerang saat dekat")
	assert_lt(attack_frames, int(total * 0.25),
		"AI tidak menyerang terus-menerus (hanya %d dari %d frame)" % [attack_frames, total])

func test_ai_approaches_when_far():
	var ai := FighterAI.new(1)
	var me := _make_fighter(false)
	var foe := _make_fighter(true)
	me.global_position = Vector2(200, 400)
	foe.global_position = Vector2(1000, 400)  # jauh
	var move_toward_frames := 0
	for i in 120:
		var cmd := ai.think(me, foe)
		if cmd["move"] > 0.0:   # lawan di kanan → move positif = mendekat
			move_toward_frames += 1
	assert_gt(move_toward_frames, 20, "AI mendekat saat jarak jauh")
