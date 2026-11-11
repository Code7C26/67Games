extends "res://tests/test_simbionte.gd"
const EQUIPOS = preload("res://scripts/equipos_infeccion.gd")

func run() -> void:
	for team in [1, 2]:
		await _recovery_for_player(team)
	print("POSSESSION RECOVERY RESULT ", passed, " passed; ", failures, " failed")
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

func _clear_bots(duck: Node2D, opponent: Node2D) -> void:
	for actor in [duck, opponent]:
		actor.finalizar_posesion()
		actor.cooldown_posesion = 0.0
	for bot in host.get_node("Bots").get_children():
		bot.queue_free()
	await process_frame

func _recovery_for_player(team: int) -> void:
	await fresh()
	host.evento_coloso.set_physics_process(false)
	host.evento_alfa.set_physics_process(false)
	var duck: Node2D
	var opponent: Node2D
	for actor in get_nodes_in_group("patos"):
		if actor.player_id == team:
			duck = actor
		else:
			opponent = actor
	duck.global_position = Vector2(656, 568)
	var origin: Vector2 = duck.global_position
	var rival_team: int = 3 - team
	var label := " P" + str(team)

	# An existing ally always takes priority over closer healthy/rival bots.
	var near_ally := bot_at(origin + Vector2(100, 0), team)
	var far_ally := bot_at(origin + Vector2(180, 0), team)
	var healthy := bot_at(origin + Vector2(10, 0), 0)
	var rival := bot_at(origin + Vector2(5, 0), rival_team)
	duck.intentar_poseer_infectado()
	check(duck.bot_poseido == near_ally and not far_ally.controlado_por_jugador and not healthy.is_infected and rival.player_duenio == rival_team, "nearest ally retains normal possession priority" + label)
	check(duck.tiempo_posesion == 10.0 and duck.cooldown_posesion == 20.0 and not duck.visible and near_ally.jugador_controlador == team, "ordinary possession keeps duration, cooldown and control" + label)
	duck.tiempo_posesion = 8.0
	duck.cooldown_posesion = 18.0
	duck.intentar_poseer_infectado()
	check(duck.bot_poseido == near_ally and duck.tiempo_posesion == 8.0 and duck.cooldown_posesion == 18.0, "repeated possession cannot restart active timers" + label)
	duck.finalizar_posesion()
	duck.intentar_poseer_infectado()
	check(duck.bot_poseido == null and duck.cooldown_posesion == 18.0 and not near_ally.controlado_por_jugador, "released possession still respects cooldown" + label)
	await _clear_bots(duck, opponent)

	# Recovery uses the nearest healthy bot even when it is temporarily protected.
	healthy = bot_at(origin + Vector2(40, 0), 0)
	var far_healthy := bot_at(origin + Vector2(100, 0), 0)
	rival = bot_at(origin + Vector2(5, 0), rival_team)
	healthy.proteccion_coloso = 5.0
	healthy.proteccion_sano_ofensiva = 3.0
	healthy.reinfeccion_coloso_sin_recompensa = true
	healthy.infectar(EQUIPOS.color_equipo(team), team)
	check(not healthy.is_infected, "normal infection still respects temporary immunity" + label)
	duck.cooldown_posesion = 4.0
	duck.intentar_poseer_infectado()
	check(duck.bot_poseido == null and not healthy.is_infected and duck.cooldown_posesion == 4.0, "cooldown blocks recovery before changing a healthy bot" + label)
	duck.cooldown_posesion = 0.0
	duck.intentar_poseer_infectado()
	freeze_bot(healthy)
	check(duck.bot_poseido == healthy and healthy.is_infected and healthy.player_duenio == team and not far_healthy.is_infected and rival.player_duenio == rival_team, "recovery infects nearest healthy instead of a closer rival" + label)
	check(healthy.proteccion_coloso == 0.0 and healthy.proteccion_sano_ofensiva == 0.0 and healthy.controlado_por_jugador and healthy.jugador_controlador == team, "recovery guarantees a controllable host after protected cures" + label)
	check(duck.tiempo_posesion == 10.0 and duck.cooldown_posesion == 20.0 and host.adn_cian == 0 and host.adn_magenta == 0 and host.contagios_cian == 0 and host.contagios_magenta == 0, "healthy recovery keeps normal timers without DNA or adaptation progress" + label)
	await _clear_bots(duck, opponent)

	# With no healthy bots left, steal the nearest rival and release its old owner.
	if team == 1:
		host.mutaciones_p1.assign(["fiebre"])
		host.cepa_cian = "atletico"
		host.mutaciones_p2.assign(["ultimo_aliento", "sobrecarga"])
		host.cepa_magenta = "area"
	else:
		host.mutaciones_p2.assign(["fiebre"])
		host.cepa_magenta = "atletico"
		host.mutaciones_p1.assign(["ultimo_aliento", "sobrecarga"])
		host.cepa_cian = "area"
	rival = bot_at(origin + Vector2(50, 0), rival_team)
	var far_rival := bot_at(origin + Vector2(120, 0), rival_team)
	check(rival.aplicar_simbionte(host, rival_team), "rival fixture attaches a real symbiont" + label)
	var effect: Node2D = rival.efecto_simbionte
	if is_instance_valid(effect):
		effect.set_physics_process(false)
	opponent.iniciar_posesion(rival)
	check(opponent.bot_poseido == rival and not opponent.visible and rival.jugador_controlador == rival_team, "rival fixture starts with active opponent possession" + label)
	duck.intentar_poseer_infectado()
	freeze_bot(rival)
	check(duck.bot_poseido == rival and rival.player_duenio == team and far_rival.player_duenio == rival_team, "all-infected recovery steals the nearest rival" + label)
	check(opponent.bot_poseido == null and opponent.visible and rival.controlado_por_jugador and rival.jugador_controlador == team, "steal releases old ghost immediately and transfers sole control" + label)
	check(rival.efecto_simbionte == null and is_instance_valid(effect) and not effect.activo and rival.get_node("AnimatedSprite2D").visible, "steal removes rival symbiont and restores the normal sprite" + label)
	check(rival.cepa == "atletico" and rival.tiene_mutacion("fiebre") and not rival.tiene_mutacion("ultimo_aliento") and not rival.tiene_mutacion("sobrecarga"), "stolen host receives new owner's strain and mutations" + label)
	opponent._physics_process(0.0)
	check(rival.controlado_por_jugador and rival.jugador_controlador == team and duck.bot_poseido == rival, "old owner's next physics tick cannot revoke stolen control" + label)
	check(host.adn_cian == 0 and host.adn_magenta == 0 and host.contagios_cian == 0 and host.contagios_magenta == 0, "steal grants neither player DNA or adaptation progress" + label)
	await _clear_bots(duck, opponent)

	# Neutral guests cannot become fallback hosts.
	var neutral := bot_at(origin + Vector2(10, 0), 0)
	neutral.activar_infeccion(EQUIPOS.COLOR_ALFA, EQUIPOS.ALFA, false)
	freeze_bot(neutral)
	duck.intentar_poseer_infectado()
	check(duck.bot_poseido == null and neutral.player_duenio == EQUIPOS.ALFA and not neutral.controlado_por_jugador, "ALFA-only population is never stolen" + label)
	await _clear_bots(duck, opponent)

	# Ignore stale group members and actors outside this match.
	var queued := bot_at(origin + Vector2(1, 0), 0)
	queued.queue_free()
	var foreign_root := Node2D.new()
	root.add_child(foreign_root)
	var foreign := bot_at(origin + Vector2(2, 0), 0)
	foreign.reparent(foreign_root)
	healthy = bot_at(origin + Vector2(80, 0), 0)
	duck.intentar_poseer_infectado()
	freeze_bot(healthy)
	check(duck.bot_poseido == healthy and not foreign.is_infected and not queued.is_infected, "recovery ignores queued bots and bots from another map" + label)
	foreign_root.queue_free()
	await _clear_bots(duck, opponent)

	# Direct method calls use the same gameplay restrictions as button/keyboard input.
	healthy = bot_at(origin + Vector2(40, 0), 0)
	duck.modo_fantasma = false
	duck.intentar_poseer_infectado()
	check(not healthy.is_infected and duck.bot_poseido == null, "living duck cannot recover through possession" + label)
	duck.modo_fantasma = true
	paused = true
	duck.intentar_poseer_infectado()
	paused = false
	host.timer_juego.paused = true
	duck.intentar_poseer_infectado()
	host.timer_juego.paused = false
	host.estado_actual = host.EstadoJuego.FIN
	duck.intentar_poseer_infectado()
	check(not healthy.is_infected and duck.bot_poseido == null and duck.cooldown_posesion == 0.0, "pause, tutorial hold and finished match block recovery" + label)
