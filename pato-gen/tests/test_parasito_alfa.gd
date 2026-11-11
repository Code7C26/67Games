extends "res://tests/test_simbionte.gd"
const EQUIPOS = preload("res://scripts/equipos_infeccion.gd")
var alfa_evento: Node2D

func preparar() -> void:
	await fresh()
	host.evento_coloso.set_physics_process(false)
	alfa_evento = host.evento_alfa
	alfa_evento.set_physics_process(false)
	alfa_evento.tiempo_partida = 0.0
	alfa_evento.probabilidad = 1.0
	alfa_evento.azar_espacial.seed = 482
	check(not alfa_evento.posiciones.is_empty(), "Alfa reuses prepared interior navigation")
	alfa_evento.generado.connect(func(bot: Node2D):
		bot.set_physics_process(false)
		bot.get_node("TimerCambioRumbo").stop()
		bot.timer_contagio.stop()
		bot.timer_curacion.stop())

func aparecer() -> void:
	alfa_evento.avanzar(35.0)
	for i in 30:
		if alfa_evento.estado == alfa_evento.Estado.ACTIVO: break
		alfa_evento.avanzar(1.0)
	check(alfa_evento.estado == alfa_evento.Estado.ACTIVO and alfa_evento.generados == 3, "one Alfa materializes with exactly three new guests")

func run() -> void:
	await preparar()
	var lugar: Vector2 = alfa_evento.posiciones[0]
	for i in 100: bot_at(lugar, 0)
	var originales := get_nodes_in_group("bots").duplicate()
	await physics_frame
	alfa_evento.avanzar(34.99)
	check(alfa_evento.alfa == null and host.contar_infecciones().total == 100, "no early appearance or population replacement")
	alfa_evento.avanzar(0.01)
	for i in 30:
		if alfa_evento.estado == alfa_evento.Estado.ACTIVO: break
		alfa_evento.avanzar(1.0)
	check(alfa_evento.generados == 3 and host.contar_infecciones().total == 103, "100 original bots become 103, exceeding normal replica ceiling")
	check(host.contar_infecciones().sanos == 100 and host.contar_infecciones().verdes == 3, "initial guests are new green entities, originals stay healthy")
	var intactos := true
	for bot in originales: intactos = intactos and is_instance_valid(bot) and not bot.is_infected
	check(intactos and not alfa_evento.alfa.is_in_group("bots"), "no original replaced and organism excluded from population")
	check(host.adn_cian == 0 and host.adn_magenta == 0 and host.replicas_cian == 0 and host.replicas_magenta == 0, "birth grants no DNA and consumes no replica quota")
	var verdes: Array[Node2D] = []
	for bot in get_nodes_in_group("bots"):
		if bot.player_duenio == 3: verdes.append(bot)
	check(verdes[0].mutaciones.is_empty() and verdes[0].cepa == "alfa" and verdes[0].speed == verdes[0].velocidad_base, "neutral guests use base stats with no player mutations")
	var piel: Image = verdes[0].animated_sprite.sprite_frames.get_frame_texture("Abajo", 0).get_image()
	var oscuro := true
	for y in piel.get_height():
		for x in piel.get_width():
			var pixel := piel.get_pixel(x, y)
			if pixel.a > 0.0:
				oscuro = oscuro and maxf(pixel.r, maxf(pixel.g, pixel.b)) < 0.15
	check(oscuro and verdes[0].animated_sprite.self_modulate == Color.WHITE and verdes[0].color_infeccion == EQUIPOS.COLOR_ALFA, "near-black infected texture preserves independent bright green team outline")
	check(host.obtener_contagios_jugador(3) == 0, "neutral affiliation never reads magenta adaptation counter")
	for jugador in [1, 2]:
		verdes[0].activar_control_jugador(jugador)
	check(not verdes[0].controlado_por_jugador, "neither player can directly control a green guest")
	for pato in get_nodes_in_group("patos"):
		pato.intentar_poseer_infectado()
		var recuperado: Node2D = pato.bot_poseido
		check(is_instance_valid(recuperado) and not verdes.has(recuperado) and recuperado.is_infected and recuperado.player_duenio == pato.player_id, "recovery possession chooses a healthy original instead of a neutral guest")
		pato.finalizar_posesion()
		if is_instance_valid(recuperado):
			recuperado.curar(false)
		pato.iniciar_posesion(verdes[0])
		check(pato.bot_poseido == null, "direct possession entry rejects green guests")
	check(host.contar_infecciones().sanos == 100 and host.adn_cian == 0 and host.adn_magenta == 0, "recovery fixture restores original population without granting DNA")
	alfa_evento.avanzar(9.99)
	check(host.contar_infecciones().total == 103, "first periodic birth waits ten seconds")
	host.timer_juego.paused = true
	alfa_evento.avanzar(80.0)
	check(alfa_evento.generados == 3 and is_equal_approx(alfa_evento.tiempo_activo, 9.99), "tutorial hold freezes generation and event duration")
	host.timer_juego.paused = false
	paused = true
	alfa_evento.avanzar(80.0)
	check(alfa_evento.generados == 3, "tree pause freezes direct event updates")
	paused = false
	alfa_evento.avanzar(0.01)
	check(host.contar_infecciones().total == 104, "first periodic birth makes 104 without enforcing normal cap")
	for i in 5: alfa_evento.avanzar(10.0)
	check(alfa_evento.generados == 9 and host.contar_infecciones().total == 109, "full duration produces three initial plus six periodic births")
	check(alfa_evento.alfa == null and alfa_evento.estado == alfa_evento.Estado.FINALIZADO, "organism retires after the last birth at sixty seconds")
	alfa_evento.avanzar(100.0)
	check(host.contar_infecciones().verdes == 9, "retirement stops generation and preserves green guests")
	# Green propagation remains functional without a reference to the departed organism.
	var neutral: Node2D = verdes[0]
	var sano: Node2D = originales[0]
	neutral._contagiar_objetivo(sano)
	check(sano.is_infected and sano.player_duenio == 3 and host.adn_magenta == 0 and host.adn_cian == 0, "green guest still infects healthy targets after Alfa departure without DNA")
	sano.timer_contagio.stop()
	sano.timer_curacion.stop()
	for equipo in [1, 2, 3]:
		for rival in [1, 2, 3]:
			var objetivo := bot_at(lugar, equipo)
			objetivo.infectar(EQUIPOS.COLOR_ALFA, rival)
			objetivo.activar_infeccion(EQUIPOS.COLOR_ALFA, rival, false)
			check(objetivo.player_duenio == equipo, "infected owner %d rejects direct infection by %d" % [equipo, rival])
			objetivo.queue_free()
	neutral.curar()
	check(not neutral.is_infected and neutral.player_duenio == 0 and neutral.animated_sprite.self_modulate == Color.WHITE, "cure restores healthy ownership, visuals and base state")
	neutral.infectar(Color.CYAN, 1)
	check(neutral.player_duenio == 1 and host.adn_cian == 1, "cured green guest becomes a regular player infection with normal reward")
	neutral.timer_contagio.stop()
	neutral.timer_curacion.stop()
	# Existing protection windows cannot be bypassed by neutral contagion.
	sano.curar_por_coloso(1.0, 3.0, RandomNumberGenerator.new())
	sano.infectar(EQUIPOS.COLOR_ALFA, 3)
	check(not sano.is_infected, "Coloso protection blocks green reinfection")
	sano.proteccion_coloso = 0.0
	sano.proteccion_sano_ofensiva = 2.0
	sano.infectar(EQUIPOS.COLOR_ALFA, 3)
	check(not sano.is_infected, "offensive healing protection blocks green reinfection")
	sano.proteccion_sano_ofensiva = 0.0
	sano.infectar(EQUIPOS.COLOR_ALFA, 3)
	check(sano.player_duenio == 3 and not sano.reinfeccion_coloso_sin_recompensa, "neutral reinfection consumes existing Coloso reward suppression")
	sano.timer_contagio.stop()
	sano.timer_curacion.stop()
	var stats: Dictionary = host.contar_infecciones()
	check(stats.total == stats.blue + stats.magenta + stats.sanos + stats.verdes, "four-way accounting excludes queued deletions")
	host.cepa_cian = "exponencial"
	host.aplicar_mutaciones_a_bot(neutral)
	check(not host.crear_replicado(neutral) and host.replicas_cian == 0, "normal player replication still respects the 100-bot ceiling")
	check(not host.evento_coloso.en_crisis({"total": 200, "sanos": 8}) and host.evento_coloso.en_crisis({"total": 200, "sanos": 7}), "extra population does not change Coloso initial-population thresholds")
	host._on_timer_juego_timeout()
	check(paused and host.game_over_screen.visible and "AZUL" in host.label_contador.text, "neutral majority does not block clock victory for blue")
	paused = false
	# Last neutral is curable; each player's last infection remains protected.
	await preparar()
	lugar = alfa_evento.posiciones[0]
	var cian := bot_at(lugar, 1)
	var magenta := bot_at(lugar, 2)
	neutral = bot_at(lugar, 3)
	var candidatos := RADIAL.candidatos_coloso(cian, INF, {})
	check(candidatos.size() == 1 and candidatos[0] == neutral, "Coloso targets last green without confusing it with last magenta")
	check(RADIAL.aplicar_coloso(cian, 140.0, 1.0, {}, RandomNumberGenerator.new(), 3.0) == neutral, "real Coloso pulse cures last green")
	check(cian.is_infected and magenta.is_infected and not neutral.is_infected, "Coloso keeps last cian and magenta intact")
	neutral.proteccion_coloso = 0.0
	neutral.infectar(EQUIPOS.COLOR_ALFA, 3)
	check(neutral.curar_por_robot(1.0) and not neutral.is_infected, "existing robot cure accepts neutral infection")
	neutral.infectar(EQUIPOS.COLOR_ALFA, 3)
	neutral.probabilidad_curacion = 1.0
	neutral.tiempo_escudo = 0.0
	neutral._intentar_curacion()
	check(not neutral.is_infected, "existing natural cure accepts neutral infection")
	# Empty candidate set must retry without spending another chance or spawning partial groups.
	var puntos: PackedVector2Array = alfa_evento.posiciones.duplicate()
	alfa_evento.posiciones.clear()
	alfa_evento.avanzar(35.0)
	check(alfa_evento.estado == alfa_evento.Estado.COLOCACION and alfa_evento.generados == 0, "blocked placement creates no partial initial group")
	alfa_evento.posiciones = puntos
	alfa_evento.avanzar(1.0)
	check(alfa_evento.generados == 3, "placement resumes once safe candidates return")
	alfa_evento.configurar(host)
	check(get_nodes_in_group("parasitos_alfa").size() == 1, "repeat configuration cannot create a second organism")
	var bloqueo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 180.0
	forma.shape = circulo
	bloqueo.add_child(forma)
	host.add_child(bloqueo)
	bloqueo.global_position = alfa_evento.alfa.global_position
	await physics_frame
	alfa_evento.avanzar(10.0)
	check(alfa_evento.generados == 3, "occupied periodic spawn area creates no overlapping guest")
	bloqueo.queue_free()
	await physics_frame
	await physics_frame
	alfa_evento.avanzar(1.0)
	check(alfa_evento.generados == 4, "periodic spawn retries when free space returns")
	alfa_evento.avanzar(30.0)
	check(alfa_evento.generados == 5, "slow update produces at most one guest, never a catch-up burst")
	host._on_timer_juego_timeout()
	check(alfa_evento.alfa == null, "early game over immediately removes active organism")
	host.game_over_screen._on_reiniciar_button_pressed()
	await process_frame
	await process_frame
	host = current_scene
	check(host.contar_infecciones().total == 65 and host.contar_infecciones().verdes == 0 and host.evento_alfa.generados == 0, "real restart restores original population and fresh event state")
	check(get_nodes_in_group("parasitos_alfa").is_empty(), "restart leaves no previous organism")
	await preparar()
	await aparecer()
	alfa_evento.alfa.queue_free()
	alfa_evento.avanzar(1.0)
	check(alfa_evento.alfa == null and alfa_evento.estado == alfa_evento.Estado.FINALIZADO and host.contar_infecciones().verdes == 3, "external organism removal terminates generation without deleting guests")
	await preparar()
	alfa_evento.probabilidad = 0.0
	alfa_evento.avanzar(35.0)
	alfa_evento.probabilidad = 1.0
	alfa_evento.avanzar(100.0)
	check(alfa_evento.estado == alfa_evento.Estado.FINALIZADO and alfa_evento.generados == 0, "failed single roll never becomes a mandatory event later")
	host.queue_free()
	await process_frame
	print("ALFA RESULT ", passed, " passed; ", failures, " failed")
	quit(0 if failures == 0 else 1)
