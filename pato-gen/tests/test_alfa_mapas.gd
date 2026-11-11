extends "res://tests/test_parasito_alfa.gd"
var huellas_validas := true

func comprobar_nacimiento(bot: Node2D) -> void:
	var cuerpo: CollisionShape2D = bot.get_node("CollisionShape2D")
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = cuerpo.shape
	consulta.transform = cuerpo.global_transform
	consulta.exclude = [bot.get_rid()]
	consulta.collision_mask = 1
	consulta.collide_with_areas = false
	huellas_validas = huellas_validas and host.get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty()
	huellas_validas = huellas_validas and host.get_meta("bounds").has_point(bot.global_position)
	bot.timer_curacion.stop()

func run() -> void:
	for nombre in ["Shopping", "Laboratorio", "PatoSplash"]:
		root.get_node("PatogenOnboarding").requested_mode = "direct"
		host = load("res://scenes/" + nombre + ".tscn").instantiate()
		root.add_child(host)
		current_scene = host
		if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
		host.timer_inicio.stop()
		host.evento_coloso.set_physics_process(false)
		alfa_evento = host.evento_alfa
		alfa_evento.set_physics_process(false)
		var limite := Time.get_ticks_msec() + 10000
		while alfa_evento.posiciones.is_empty() and Time.get_ticks_msec() < limite: await physics_frame
		check(not alfa_evento.posiciones.is_empty(), nombre + " reachable candidate floor ready")
		alfa_evento.probabilidad = 1.0
		alfa_evento.azar_espacial.seed = 923
		huellas_validas = true
		alfa_evento.generado.connect(comprobar_nacimiento)
		host.estado_actual = host.EstadoJuego.FASE_INFECCION
		host.timer_juego.start(120)
		for pato in get_nodes_in_group("patos"):
			pato.convertirse_en_fantasma()
			pato.set_physics_process(false)
		await aparecer()
		check(host.contar_infecciones().total == 68, nombre + " real population increases 65 to 68")
		if alfa_evento.alfa == null:
			host.queue_free()
			await process_frame
			continue
		var actor: Node2D = alfa_evento.alfa
		check(not actor.is_in_group("bots") and host.get_meta("bounds").has_point(actor.global_position), nombre + " organism inside map, outside population")
		var centro: Vector2 = alfa_evento.navegacion.limites.get_center()
		var distancia_suelo: float = alfa_evento.posiciones[0].distance_to(centro)
		check(actor.global_position.distance_to(centro) <= distancia_suelo + 96.0, nombre + " creature spawns in nearest central walkable area, including maps with blocked centers")
		var posicion_inicial := actor.global_position
		var originales: Dictionary = {}
		for bot in get_nodes_in_group("bots"):
			if bot.player_duenio == 3: originales[bot] = bot.global_position
		for i in 180: await physics_frame
		var movidos := 0
		for bot in originales:
			if bot.global_position.distance_to(originales[bot]) > 10.0: movidos += 1
		check(movidos == 3, nombre + " all initial green guests move with existing autonomous AI")
		check(actor.global_position == posicion_inicial, nombre + " rooted creature stays fixed while its guests move")
		for i in 6:
			alfa_evento.avanzar(10.0)
			for frame in 30: await physics_frame
		check(huellas_validas, nombre + " all birth footprints clear real actors, walls and map boundaries")
		check(alfa_evento.generados == 9 and host.contar_infecciones().total == 74, nombre + " nine new entities survive organism retirement")
		check(alfa_evento.alfa == null and get_nodes_in_group("parasitos_alfa").is_empty(), nombre + " no organism remains after duration")
		var stats: Dictionary = host.contar_infecciones()
		check(stats.verdes >= 9 and stats.total == stats.sanos + stats.blue + stats.magenta + stats.verdes, nombre + " autonomous neutral contagion maintains accounting")
		check(host.adn_cian == 0 and host.adn_magenta == 0, nombre + " autonomous green spread gives no player DNA")
		host._on_timer_juego_timeout()
		check(paused and "EMPATE" in host.label_contador.text, nombre + " only neutral infection still finishes with player tie")
		paused = false
		host.queue_free()
		await process_frame
		await process_frame
		check(get_nodes_in_group("bots").is_empty() and get_nodes_in_group("parasitos_alfa").is_empty(), nombre + " map unload clears all actors")
	print("ALFA MAPS RESULT ", passed, " passed; ", failures, " failed")
	quit(0 if failures == 0 else 1)
