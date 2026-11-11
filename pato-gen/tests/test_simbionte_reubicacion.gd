extends "res://tests/test_simbionte.gd"
## Real robot pulses and contact physics; no production debug switches.
const FIRST_POINT := Vector2(656, 568)
const SECOND_POINT := Vector2(816, 568)

func run() -> void:
	for team in [1, 2]:
		await _second_host(team)
	await _alternate_entries()
	await _other_healing_sources()
	await _end_and_restart()
	print("SIMBIONTE REUBICACION RESULT ", passed, " passed; ", failures, " failed")
	paused = false
	if is_instance_valid(host):
		host.queue_free()
	await process_frame
	await process_frame
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer:
			player.stop()
	await process_frame
	quit(0 if failures == 0 else 1)

func _live_travellers() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for traveller in get_nodes_in_group("simbiontes"):
		if is_instance_valid(traveller) and not traveller.is_queued_for_deletion() and host.is_ancestor_of(traveller):
			result.append(traveller)
	return result

func _robot_at(point: Vector2, team: int) -> Node2D:
	var robot = load("res://scenes/robot.tscn").instantiate()
	robot.position = point
	robot.jugador_invocador = team
	robot.radio_curacion = 48.0
	robot.probabilidad_curacion = 1.0
	host.add_child(robot)
	robot.set_physics_process(false)
	return robot

func _duck(team: int) -> Node2D:
	for duck in get_nodes_in_group("patos"):
		if host.is_ancestor_of(duck) and duck.player_id == team:
			return duck
	return null

func _economy() -> Array:
	return [host.adn_cian, host.adn_magenta, host.contagios_cian, host.contagios_magenta]

func _hatch_and_fuse(team: int) -> Node2D:
	host.adn_cian = 60
	host.adn_magenta = 60
	for _payment in 12:
		host.invertir_simbionte(team)
		host._physics_process(1.5)
	var carrier := bot_at(FIRST_POINT, team)
	var traveller = host.simbionte
	traveller.set_physics_process(false)
	traveller.global_position = FIRST_POINT
	traveller.objetivo = carrier
	await physics_frame
	await physics_frame
	check(traveller.intentar_fusion(), "first fusion uses real contact P%d" % team)
	if is_instance_valid(carrier.efecto_simbionte):
		carrier.efecto_simbionte.set_physics_process(false)
		carrier.efecto_simbionte.chance_aura = 0.0
	await process_frame
	return carrier

func _second_host(team: int) -> void:
	await fresh()
	var label := " P%d" % team
	var carrier := await _hatch_and_fuse(team)
	if not is_instance_valid(carrier.efecto_simbionte):
		return
	var effect = carrier.efecto_simbionte
	effect.avanzar(7.0)
	var duck := _duck(team)
	var shortcut: Key = KEY_Q if team == 1 else KEY_U
	duck.cooldown_posesion = 5.0
	key(shortcut)
	check(duck.bot_poseido == null and not effect.entrada_inmediata_disponible, "first fusion still respects the ordinary possession cooldown" + label)
	duck.cooldown_posesion = 0.0
	key(shortcut)
	check(duck.bot_poseido == carrier, "first carrier is directly possessable" + label)
	var robot := _robot_at(FIRST_POINT, 3 - team)
	var before := _economy()
	robot.probabilidad_curacion = 0.0
	robot.intentar_curar()
	check(carrier.efecto_simbionte == effect and not host.reubicacion_simbionte_usada and _live_travellers().is_empty(), "resisted robot pulse neither detaches nor consumes the retry" + label)
	robot.probabilidad_curacion = 1.0
	effect.factor_curacion = 1.0 # Isolate successful cure, without changing production resistance.
	robot.intentar_curar()
	check(not carrier.is_infected and carrier.efecto_simbionte == null and carrier.animated_sprite.visible, "real robot heals the first carrier and restores its sprite" + label)
	check(host.reubicacion_simbionte_usada and _live_travellers().size() == 1, "first robot cure consumes exactly one match retry" + label)
	var traveller = host.simbionte
	if not is_instance_valid(traveller) or traveller.is_queued_for_deletion():
		check(false, "second-host traveller exists" + label)
		return
	traveller.set_physics_process(false)
	check(traveller.global_position == FIRST_POINT and traveller.equipo == team, "detached traveller retains its team and starts at the cured host" + label)
	check(is_equal_approx(traveller.tiempo_fusion, 13.0) and traveller.huesped_anterior_id == carrier.get_instance_id(), "retry carries only the remaining fusion time and remembers its former host" + label)
	duck._physics_process(0.0)
	check(duck.bot_poseido == null and not carrier.controlado_por_jugador, "cure releases the old possession through its usual lifecycle" + label)
	traveller._physics_process(21.0)
	check(traveller.objetivo == null and is_equal_approx(traveller.tiempo_fusion, 13.0), "no allies waits without consuming the remaining fusion budget" + label)
	check(not traveller.hilo_objetivo.visible and traveller.hilo_objetivo.points.is_empty(), "no target leaves no dangling visual thread" + label)
	key(shortcut)
	check(duck.bot_poseido == null, "shortcut during the second search does not choose an ordinary host" + label)
	carrier.activar_infeccion(Color.CYAN if team == 1 else Color.MAGENTA, team, false)
	freeze_bot(carrier)
	traveller.buscar_objetivo()
	check(traveller.objetivo == null, "reinfection cannot make the old carrier count as the second host" + label)
	carrier.curar(false)
	var second := bot_at(SECOND_POINT, team)
	var rival := bot_at(FIRST_POINT + Vector2(30, 0), 3 - team)
	var healthy := bot_at(FIRST_POINT + Vector2(0, 30), 0)
	traveller.buscar_objetivo()
	check(traveller.objetivo == second and not traveller.intentar_fusion(), "second search ignores closer rival and healthy bots and still requires contact" + label)
	check(traveller.hilo_objetivo.visible and traveller.hilo_objetivo.get_point_count() > 1, "second search visibly links the traveller to its valid target" + label)
	var end: Vector2 = traveller.hilo_objetivo.points[-1]
	check(traveller.hilo_objetivo.to_global(end).is_equal_approx(second.global_position + Vector2(0, -10)), "thread endpoint follows the actual target location" + label)
	var profile = root.get_node("PatogenOnboarding").profile
	var prior_reduced: bool = profile.data.get("reduced_motion", false)
	profile.data["reduced_motion"] = true
	traveller._actualizar_hilo()
	var thread_points: PackedVector2Array = traveller.hilo_objetivo.points
	var straight := true
	var axis: Vector2 = thread_points[-1] - thread_points[0]
	for point in thread_points:
		straight = straight and absf(axis.cross(point - thread_points[0])) < 0.01
	check(straight, "reduced-motion preference retains a still straight thread" + label)
	profile.data["reduced_motion"] = prior_reduced
	second.curar(false)
	traveller._physics_process(0.0)
	check(traveller.objetivo == null, "healed second target is discarded before contact" + label)
	check(not traveller.hilo_objetivo.visible, "invalid target immediately removes its thread" + label)
	second.activar_infeccion(Color.CYAN if team == 1 else Color.MAGENTA, team, false)
	freeze_bot(second)
	traveller.buscar_objetivo()
	var start: Vector2 = traveller.global_position
	paused = true
	traveller._physics_process(1.0)
	check(traveller.global_position == start and is_equal_approx(traveller.tiempo_fusion, 13.0), "global pause also freezes the detached traveller" + label)
	paused = false
	host.timer_juego.paused = true
	traveller._physics_process(1.0)
	check(traveller.global_position == start, "tutorial clock hold freezes the second search" + label)
	host.timer_juego.paused = false
	traveller.set_physics_process(true)
	var deadline := Time.get_ticks_msec() + 6000
	while is_instance_valid(traveller) and second.efecto_simbionte == null and Time.get_ticks_msec() < deadline:
		await physics_frame
	check(is_instance_valid(second.efecto_simbionte), "detached traveller physically walks into its second host" + label)
	if not is_instance_valid(second.efecto_simbionte):
		return
	var second_effect = second.efecto_simbionte
	second_effect.set_physics_process(false)
	second_effect.chance_aura = 0.0
	check(second_effect.restante > 12.8 and second_effect.restante <= 13.0, "contact resumes thirteen remaining seconds instead of granting twenty" + label)
	check(_economy() == before, "detachment, travel and second fusion neither spend nor award ADN" + label)
	check(duck.bot_poseido == null and duck.cooldown_posesion > 0.0 and second_effect.entrada_inmediata_disponible, "second contact grants one immediate entry despite the existing cooldown" + label)
	key(KEY_U if team == 1 else KEY_Q)
	key(shortcut, true)
	check(duck.bot_poseido == null and second_effect.entrada_inmediata_disponible, "rival input and keyboard echo cannot consume the immediate entry" + label)
	host.timer_juego.paused = true
	key(shortcut)
	check(duck.bot_poseido == null and second_effect.entrada_inmediata_disponible, "clock hold preserves the unused immediate entry" + label)
	host.timer_juego.paused = false
	key(shortcut)
	check(duck.bot_poseido == second and second.controlado_por_jugador and not second_effect.entrada_inmediata_disponible, "Q/U immediately possesses the second host and consumes only that entry" + label)
	var remaining: float = second_effect.restante
	duck._physics_process(1.0)
	key(shortcut)
	check(is_equal_approx(second_effect.restante, remaining) and duck.tiempo_posesion == 9.0 and duck.cooldown_posesion == 19.0, "repeating direct possession cannot refresh possession, cooldown or second fusion" + label)
	duck.finalizar_posesion()
	key(shortcut)
	check(duck.bot_poseido == null and duck.cooldown_posesion == 19.0 and not second_effect.entrada_inmediata_disponible, "used immediate entry cannot bypass cooldown again" + label)
	duck.cooldown_posesion = 0.0
	key(shortcut)
	check(duck.bot_poseido == second and not second_effect.entrada_inmediata_disponible, "ordinary possession still works after its normal cooldown" + label)
	robot.global_position = second.global_position
	second_effect.factor_curacion = 1.0
	robot.intentar_curar()
	duck._physics_process(0.0)
	await physics_frame
	await physics_frame
	check(not second.is_infected and second.efecto_simbionte == null and duck.bot_poseido == null, "robot still heals and releases the second carrier" + label)
	check(_live_travellers().is_empty() and host.reubicacion_simbionte_usada, "second robot cure cannot create a third-host search" + label)
	robot.intentar_curar()
	check(_live_travellers().is_empty() and _economy() == before and host.inversion_simbionte[team - 1] == 60, "repeated robot pulses never duplicate the symbiont or its resources" + label)
	# Keep references live through assertions; every actor remains match-owned.
	check(is_instance_valid(rival) and is_instance_valid(healthy), "unrelated nearby bots remain present" + label)

func _alternate_entries() -> void:
	for route in ["ordinary", "transfer"]:
		await fresh()
		var carrier := await _hatch_and_fuse(1)
		carrier.efecto_simbionte.factor_curacion = 1.0
		var robot := _robot_at(FIRST_POINT, 2)
		robot.intentar_curar()
		var second := bot_at(SECOND_POINT, 1)
		var deadline := Time.get_ticks_msec() + 6000
		while second.efecto_simbionte == null and Time.get_ticks_msec() < deadline:
			await physics_frame
		if not is_instance_valid(second.efecto_simbionte):
			check(false, "alternate entry fixture reaches its second host: " + route)
			continue
		var effect = second.efecto_simbionte
		effect.set_physics_process(false)
		effect.chance_aura = 0.0
		var remaining: float = effect.restante
		var duck := _duck(1)
		if route == "ordinary":
			duck.intentar_poseer_infectado()
			check(duck.bot_poseido == second and not effect.entrada_inmediata_disponible, "ordinary X/J possession also consumes the second-host immediate entry")
		else:
			var other := bot_at(FIRST_POINT + Vector2(-100, 0), 1)
			duck.iniciar_posesion(other)
			duck._physics_process(3.0)
			key(KEY_Q)
			check(duck.bot_poseido == second and not other.controlado_por_jugador and not effect.entrada_inmediata_disponible, "active-host transfer consumes the immediate entry and releases the old bot")
			check(duck.tiempo_posesion == 7.0 and duck.cooldown_posesion == 17.0, "second-host transfer preserves the active possession's remaining time and cooldown")
		check(is_equal_approx(effect.restante, remaining), "alternate entry never resets fusion time: " + route)
		duck.finalizar_posesion()
		key(KEY_Q)
		check(duck.bot_poseido == null and duck.cooldown_posesion > 0.0, "alternate entry cannot leave another free re-entry: " + route)


func _other_healing_sources() -> void:
	for source in ["natural", "offensive", "aura", "coloso", "recovery", "expiry"]:
		await fresh()
		var carrier := await _hatch_and_fuse(1)
		if not is_instance_valid(carrier.efecto_simbionte):
			continue
		var effect = carrier.efecto_simbionte
		effect.factor_curacion = 1.0
		freeze_bot(carrier)
		match source:
			"natural":
				carrier.probabilidad_curacion = 1.0
				carrier._intentar_curacion()
			"offensive":
				carrier.recibir_curacion_ofensiva(1.0, 0.0, 2)
			"aura":
				var rival := bot_at(FIRST_POINT + Vector2(30, 0), 2)
				rival.aplicar_simbionte(host, 2)
				var rival_effect = rival.efecto_simbionte
				rival_effect.set_physics_process(false)
				rival_effect.chance_aura = 1.0
				rival_effect.hasta_pulso = 0.0
				rival_effect.avanzar(0.01)
			"coloso":
				var azar := RandomNumberGenerator.new()
				azar.seed = 7
				carrier.curar_por_coloso(1.0, 3.0, azar)
			"recovery":
				carrier.infectar_para_recuperar_posesion(2)
			"expiry":
				effect.avanzar(20.0)
		check(carrier.efecto_simbionte == null and not host.reubicacion_simbionte_usada and _live_travellers().is_empty(), source + " cleanup cannot trigger the robot-only retry")

func _end_and_restart() -> void:
	await fresh()
	var carrier := await _hatch_and_fuse(1)
	if not is_instance_valid(carrier.efecto_simbionte):
		return
	carrier.efecto_simbionte.factor_curacion = 1.0
	var robot := _robot_at(FIRST_POINT, 2)
	robot.intentar_curar()
	check(host.reubicacion_simbionte_usada and _live_travellers().size() == 1, "cleanup fixture is actively searching for its second host")
	host._on_timer_juego_timeout()
	check(paused and host.simbionte.is_queued_for_deletion(), "game over removes the detached traveller before pausing")
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	host.game_over_screen._on_reiniciar_button_pressed()
	await process_frame
	await process_frame
	host = current_scene
	host.timer_inicio.stop()
	check(not paused and not host.reubicacion_simbionte_usada and host.ganador_simbionte == 0, "real restart resets the one-time escape and race winner")
	check(_live_travellers().is_empty() and host.inversion_simbionte == [0, 0] and host.adn_cian == 0 and host.adn_magenta == 0, "real restart leaves no detached traveller or retained investment")
