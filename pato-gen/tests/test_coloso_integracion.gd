extends "res://tests/test_coloso_antiviral.gd"

func run() -> void:
	await fresh_coloso()
	# La aparición real revalida ocupación, y siempre nace en el componente interior.
	var validos := true
	var conectados := true
	for i in range(48):
		evento.azar_espacial.seed = i + 71
		var p: Variant = evento.buscar_aparicion()
		validos = validos and p != null and evento.posicion_segura(p)
		if p != null:
			conectados = conectados and not evento.navegacion.ruta(centro, p).is_empty()
	check(validos, "48 appearance samples fit geometry, actors, cocoons and passage margins")
	check(conectados, "48 appearance samples connect to the playable interior for the large body")
	check(evento.navegacion.radio_cuerpo == 20.0 and host.navegacion_simbionte.radio_cuerpo == 8.0, "coloso clearance does not alter symbiont navigation radius")
	await preparar_aparicion()
	var actor: Node2D = evento.coloso
	var destino := centro
	var distancia := 0.0
	for p in evento.posiciones:
		var d := centro.distance_to(p)
		if d > distancia and d < 480.0 and not evento.navegacion.ruta(centro, p).is_empty():
			destino = p
			distancia = d
	check(distancia > 300.0, "real-map travel scenario starts outside healing range")
	for bot in get_nodes_in_group("bots"):
		bot.global_position = destino
	evento.chance_curacion = 1.0
	evento.azar_espacial.seed = 912
	evento.azar_curacion.seed = 123
	var collision_ok := true
	var frames := 0
	var moved := 0.0
	while is_instance_valid(evento.coloso) and evento.coloso.curaciones == 0 and frames < 1100:
		await physics_frame
		evento.avanzar(1.0 / 60.0, host.contar_infecciones())
		frames += 1
		if is_instance_valid(evento.coloso):
			moved = maxf(moved, centro.distance_to(actor.global_position))
			collision_ok = collision_ok and _cuerpo_libre(actor)
	check(moved > 100.0, "coloso moves autonomously through the real shopping")
	check(collision_ok, "actual moving footprint never crosses walls or furniture")
	check(is_instance_valid(actor) and actor.curaciones > 0, "autonomous travel reaches and heals a real target")
	check(host.contar_infecciones().total == 4 and host.adn_cian == 0 and host.adn_magenta == 0, "travel and pulses preserve population and generate no DNA")
	# Intervalos reales, una sola curación por pulso y presupuesto efectivo.
	await fresh_coloso()
	await preparar_aparicion()
	actor = evento.coloso
	evento.velocidad = 0.0
	evento.chance_curacion = 1.0
	evento.max_curaciones = 2
	actor.hasta_pulso = 1.0
	evento.avanzar(0.99, host.contar_infecciones())
	check(actor.curaciones == 0, "fresh actor waits one full second before first healing")
	evento.avanzar(0.01, host.contar_infecciones())
	check(actor.curaciones == 1 and actor.tratados.size() == 1, "first pulse heals exactly one eligible bot")
	var healed: Node2D
	for bot in get_nodes_in_group("bots"):
		if not bot.is_infected:
			healed = bot
	check(healed != null and healed.proteccion_coloso == 3.0, "real radial pulse applies protection to its actual recipient")
	host.timer_juego.paused = true
	healed._physics_process(1.0)
	check(healed.proteccion_coloso == 3.0, "tutorial hold freezes new protection even when bot physics is called")
	host.timer_juego.paused = false
	healed._physics_process(1.0)
	check(healed.proteccion_coloso == 2.0, "protection counts gameplay seconds normally")
	evento.avanzar(1.0, host.contar_infecciones())
	check(evento.coloso == null and actor.curaciones == 2, "second successful pulse exhausts configured budget and retires")
	var counted: Dictionary = host.contar_infecciones()
	check(counted.blue == 1 and counted.magenta == 1, "successive real pulses cannot eliminate either team's last infection")
	await physics_frame
	# Calor y el Coloso no comparten temporizadores ni sobrescriben multiplicadores.
	var infected: Node2D
	for bot in get_nodes_in_group("bots"):
		if bot.is_infected:
			infected = bot
	var heat = load("res://scenes/zona_temperatura.tscn").instantiate()
	heat.tipo = 1
	host.add_child(heat)
	heat.global_position = infected.global_position
	heat.aplicar_efecto(infected)
	var heat_factors := Vector2(infected.multiplicador_velocidad_temp, infected.multiplicador_contagio_temp)
	infected.curar_por_coloso(1.0, 3.0, evento.azar_curacion)
	check(heat_factors == Vector2(infected.multiplicador_velocidad_temp, infected.multiplicador_contagio_temp), "coloso preserves existing temperature speed and infection multipliers")
	heat.queue_free()
	# Presupuesto de producción: doce pulsos exitosos, sin una decimotercera cura.
	await fresh_coloso()
	for i in range(26):
		bot_at(centro + Vector2(-55, 0), 1 if i % 2 == 0 else 2)
	await physics_frame
	await preparar_aparicion()
	actor = evento.coloso
	evento.velocidad = 0.0
	evento.chance_curacion = 1.0
	for _i in range(12):
		evento.avanzar(1.0, host.contar_infecciones())
	check(actor.curaciones == 12 and evento.coloso == null and host.contar_infecciones().sanos == 12, "production budget stops at exactly twelve successful treatments")
	check(host.contar_infecciones().total == 30 and host.adn_cian == 0 and host.adn_magenta == 0, "twelve treatments preserve identities, total population and DNA")
	# Reaparición y reinicio usan el ciclo real de GameOver.
	evento.apariciones = 2
	host._on_timer_juego_timeout()
	host.game_over_screen._on_reiniciar_button_pressed()
	await process_frame
	await process_frame
	host = current_scene
	evento = host.evento_coloso
	evento.set_physics_process(false)
	check(not paused and evento.apariciones == 0 and evento.probabilidad_actual() == 0.60, "real restart clears appearance count and restores 60 percent")
	check(host.contar_infecciones().total == 65 and host.contar_infecciones().sanos == 65, "real restart restores original healthy population")
	check(get_nodes_in_group("colosos_antivirales").is_empty(), "restart leaves no old coloso actors")
	var marcas_limpias := true
	for bot in get_nodes_in_group("bots"):
		marcas_limpias = marcas_limpias and bot.proteccion_coloso == 0.0 and not bot.reinfeccion_coloso_sin_recompensa
	check(marcas_limpias, "restart clears all per-bot coloso protection and economy markers")
	host.queue_free()
	await process_frame
	print("COLOSO INTEGRATION RESULT ", passed, " passed; ", failures, " failed")
	quit(0 if failures == 0 else 1)

func _cuerpo_libre(actor: Node2D) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 19.0 # Un píxel de tolerancia al contacto físico, sin permitir atravesar.
	query.shape = shape
	query.transform = Transform2D(0.0, actor.global_position)
	query.collision_mask = 1
	query.collide_with_areas = false
	evento.navegacion.actualizar_exclusiones()
	query.exclude = evento.navegacion.excluidos
	return host.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
