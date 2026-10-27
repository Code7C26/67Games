extends "res://tests/test_simbionte.gd"

func run() -> void:
	for team in [1, 2]:
		await _direct_possession(team)
	print("SIMBIONTE POSSESSION RESULT ", passed, " passed; ", failures, " failed")
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

func _direct_possession(team: int) -> void:
	await fresh()
	var duck: Node2D
	var opponent: Node2D
	for candidate in get_nodes_in_group("patos"):
		if candidate.player_id == team:
			duck = candidate
		else:
			opponent = candidate
	var shortcut: Key = KEY_Q if team == 1 else KEY_U
	var opponent_shortcut: Key = KEY_U if team == 1 else KEY_Q
	host.adn_cian = 60
	host.adn_magenta = 60
	for _i in range(12):
		key(shortcut)
		host._physics_process(1.5)
	check(host.ganador_simbionte == team and host.obtener_adn(team) == 0, "shortcut still invests and hatches for team " + str(team))
	key(shortcut)
	check(duck.bot_poseido == null and duck.cooldown_posesion == 0.0, "shortcut during travel neither possesses nor starts cooldown")
	host.simbionte.queue_free()
	await process_frame
	var near := bot_at(duck.global_position + Vector2(30, 0), team)
	var target := bot_at(Vector2(1360, 592) if team == 1 else Vector2(592, 592), team)
	check(target.aplicar_simbionte(host, team), "fixture attaches the real fusion effect")
	var effect = target.efecto_simbionte
	effect.set_physics_process(false)
	check(effect.chance_aura == 0.5, "fused aura uses 50 percent probability")
	key(shortcut, true)
	check(duck.bot_poseido == null, "held-key echo cannot start direct possession")
	var shifted := InputEventKey.new()
	shifted.keycode = shortcut
	shifted.pressed = true
	shifted.shift_pressed = true
	host._unhandled_input(shifted)
	check(duck.bot_poseido == null, "Shift does not activate the direct shortcut")
	host.timer_juego.paused = true
	key(shortcut)
	check(duck.bot_poseido == null, "tutorial clock hold blocks direct possession")
	host.timer_juego.paused = false
	paused = true
	key(shortcut)
	check(duck.bot_poseido == null, "global pause blocks direct possession")
	paused = false
	duck.modo_fantasma = false
	key(shortcut)
	check(duck.bot_poseido == null, "shortcut requires ghost mode like ordinary possession")
	duck.modo_fantasma = true
	key(opponent_shortcut)
	check(opponent.bot_poseido == null and host.obtener_adn(3 - team) == 60, "rival shortcut cannot steal the fused host or charge DNA")
	key(shortcut)
	check(duck.bot_poseido == target and target.controlado_por_jugador and not near.controlado_por_jugador, "shortcut chooses the distant fused ally over the nearest ordinary ally")
	check(duck.tiempo_posesion == 10.0 and duck.cooldown_posesion == 20.0 and effect.restante == 20.0, "direct possession uses existing duration and cooldown without touching fusion time")
	duck._physics_process(2.0)
	effect.avanzar(2.0)
	key(shortcut)
	key(shortcut)
	check(duck.tiempo_posesion == 8.0 and duck.cooldown_posesion == 18.0 and effect.restante == 18.0, "repeated shortcut cannot extend either timer or restart cooldown")
	duck.finalizar_posesion()
	key(shortcut)
	check(duck.bot_poseido == null and duck.cooldown_posesion == 18.0, "shortcut respects an existing possession cooldown")
	duck.cooldown_posesion = 0.0
	duck.intentar_poseer_infectado()
	check(duck.bot_poseido == near, "ordinary possession still selects the nearest infected ally")
	near.curar(false)
	key(shortcut)
	check(duck.bot_poseido != target, "healed old host cannot bypass cooldown before the next physics tick")
	duck._physics_process(0.0)
	near.activar_infeccion(Color.CYAN if team == 1 else Color.MAGENTA, team, false)
	freeze_bot(near)
	duck.cooldown_posesion = 0.0
	duck.intentar_poseer_infectado()
	duck._physics_process(3.0)
	key(shortcut)
	check(duck.bot_poseido == target and not near.controlado_por_jugador and target.controlado_por_jugador, "shortcut transfers active control and releases the old host")
	check(duck.tiempo_posesion == 7.0 and duck.cooldown_posesion == 17.0 and effect.restante == 18.0, "transfer preserves remaining possession, cooldown and fusion lifetime")
	check(host.obtener_adn(team) == 0 and host.obtener_adn(3 - team) == 60, "direct possession and switching neither cost nor generate DNA")
	target.curar(false)
	duck._physics_process(0.0)
	duck.cooldown_posesion = 0.0
	key(shortcut)
	check(duck.bot_poseido == null and target.efecto_simbionte == null, "healing releases possession and removes the direct target")
	target.activar_infeccion(Color.CYAN if team == 1 else Color.MAGENTA, team, false)
	freeze_bot(target)
	target.aplicar_simbionte(host, team)
	target.efecto_simbionte.set_physics_process(false)
	key(shortcut)
	target.efecto_simbionte.avanzar(20.0)
	duck._physics_process(1.0)
	key(shortcut)
	check(duck.bot_poseido == target and duck.tiempo_posesion == 9.0 and target.efecto_simbionte == null, "expiry leaves existing possession intact but shortcut cannot restart it")
	duck.finalizar_posesion()
	duck.cooldown_posesion = 0.0
	key(shortcut)
	check(duck.bot_poseido == null, "expired fusion does not fall back to possessing an ordinary bot")
	await process_frame
	target.aplicar_simbionte(host, team)
	target.efecto_simbionte.set_physics_process(false)
	target.queue_free()
	key(shortcut)
	check(duck.bot_poseido == null, "queued host deletion is safely ignored")
	await process_frame
	key(shortcut)
	check(duck.bot_poseido == null, "freed host leaves no stale possession target")
	host.estado_actual = host.EstadoJuego.FIN
	key(shortcut)
	check(duck.bot_poseido == null and not host.accion_simbionte(team), "finished match rejects direct possession")
