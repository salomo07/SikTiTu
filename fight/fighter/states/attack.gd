extends State

## Ejecuta un ataque (normal o especial): startup -> active -> recovery según su frame
## data. El hitbox activo lo consulta MatchManager. Los normales cancelables pueden
## cancelarse a especial durante active/recovery. Los especiales pueden moverse (self_move)
## y lanzar proyectil.

var _started_airborne: bool = false

func enter() -> void:
	_started_airborne = not fighter.on_ground
	var m: MoveData = fighter.current_move
	if fighter.on_ground:
		if m.is_special and m.self_move.x != 0.0:
			fighter.vel.x = m.self_move.x * fighter.facing()
		else:
			fighter.stop_horizontal()
	# Banner judul skill + overlay wajah (mis. Macan Asia).
	if m.title != "":
		for h in fighter.get_tree().get_nodes_in_group("fight_hud"):
			if h.has_method("set_skill_title"):
				h.set_skill_title(m.title)
	if m.face_overlay != "":
		fighter.show_face_overlay(m.face_overlay)

func exit() -> void:
	fighter.hide_face_overlay()

func physics_update(delta: float) -> void:
	if not fighter.on_ground:
		fighter.apply_gravity(delta)
	if _started_airborne and fighter.on_ground:
		state_machine.transition_to("Idle")
		return
	var m: MoveData = fighter.current_move
	var phase := MovePhase.phase_at(state_frame, m.startup, m.active, m.recovery)
	# Cancel de normal a especial (a partir de que sale el golpe).
	if m.cancelable and state_frame >= m.startup and fighter.try_start_special():
		state_machine.transition_to("Attack")
		return
	# Proyectil (Hadouken): se genera una vez al entrar en activo.
	if not fighter._projectile_spawned and phase == MovePhase.ACTIVE:
		if m.projectile_count > 0 or m.projectile_homing or m.projectile_texture != "" or m.projectile_text != "":
			fighter.spawn_skill(m)
			fighter._projectile_spawned = true
		elif m.spawns_projectile:
			fighter.spawn_projectile(m)
			fighter._projectile_spawned = true
	if phase == MovePhase.DONE:
		state_machine.transition_to("Idle" if fighter.on_ground else "Jump")
