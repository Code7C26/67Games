extends "res://tests/test_simbionte.gd"
## Real Bot bodies, real map physics, snapshots, lifecycle and bounded local reports.
const ORIGIN := Vector2(656, 568)

func preparar() -> void:
	root.set_meta("patogen_cepas", {1: "rastreador", 2: "rastreador"})
	await fresh()
	host.set_physics_process(false)
	host.evento_coloso.set_physics_process(false)
	host.evento_alfa.set_physics_process(false)

func limpiar() -> void:
	for bot in host.get_node("Bots").get_children(): bot.queue_free()
	await physics_frame
	await physics_frame

func actor(point: Vector2, team: int = 1) -> Node2D:
	var bot := bot_at(point, team)
	freeze_bot(bot)
	bot.incubacion_contagio = 0.0
	return bot

func nav_lista(source: Node2D) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while not source.rastreador.navegacion.lista and Time.get_ticks_msec() < deadline: await physics_frame
	check(source.rastreador.navegacion.lista, "shared body-safe navigation becomes ready")

func mirar(source: Node2D, delta: float = 0.01) -> void:
	source.rastreador.revision_restante = 0.0
	source.rastreador.observacion_restante = 0.0
	source.rastreador.actualizar(delta)

func run() -> void:
	seed(7717)
	await preparar()
	await arte_y_balance()
	for team in [1, 2]:
		await percepcion_y_memoria(team)
		await invalidacion_y_aislamiento(team)
		await manada(team)
	await ciclo_y_mejoras()
	await paredes()
	await mapas_navegados()
	print("RASTREADOR RESULT ", passed, " passed; ", failures, " failed")
	await terminar()
	quit(0 if failures == 0 else 1)

func terminar() -> void:
	paused = false
	if is_instance_valid(host): host.queue_free()
	await process_frame
	await process_frame
	load("res://scripts/rastreador_arte.gd").limpiar_cache()
	load("res://scripts/npc_readability.gd").textures.clear()
	load("res://scripts/Bot.gd").frames_infectados_cache.clear()
	root.get_node("AudioManager").detener_musica()

func arte_y_balance() -> void:
	for file in ["rastreador_abajo.png", "rastreador_arriba.png", "rastreador_derecha.png", "rastreador_izquierda.png", "rastreador_detectar.png", "rastreador_poses_sheet.png", "rastreador_poses_sheet.json", "poses_fuente.json"]:
		check(FileAccess.get_sha256("res://assets/rastreador/" + file) == FileAccess.get_sha256("res://../work/rastreador-concepto-v02/" + file), "approved v02 bytes preserved: " + file)
	check(FileAccess.get_sha256("res://assets/rastreador/rastreador.aseprite") == FileAccess.get_sha256("res://../work/rastreador-concepto-v02/rastreador_base.aseprite"), "approved Aseprite source preserved")
	check(FileAccess.get_sha256("res://assets/rastreador/retrato.png") == FileAccess.get_sha256("res://assets/rastreador/rastreador_abajo.png"), "selector portrait is the approved sprite")
	var bot := actor(ORIGIN)
	await nav_lista(bot)
	check(is_equal_approx(bot.speed, bot.velocidad_base) and is_equal_approx(bot.probabilidad_contagio, 0.35) and is_equal_approx(bot.probabilidad_curacion, 0.01), "ordinary movement, contact infection and cure probabilities")
	check(is_equal_approx(bot.rastreador.rango_deteccion(), 92.75) and is_equal_approx(bot.rastreador.memoria(), 6.0), "Shopping uses53px local base times175percent and six seconds")
	check(bot.animated_sprite.sprite_frames.get_frame_texture("Abajo", 0).get_size() == Vector2(36,36), "approved body receives the shared transparent outline margin")
	check(bot.material_borde_infeccion.get_shader_parameter("borde_activo"), "team outline stays active")
	await limpiar()

func percepcion_y_memoria(team: int) -> void:
	var source := actor(ORIGIN, team)
	var prey := actor(ORIGIN + Vector2(82,0), 0)
	await nav_lista(source)
	await physics_frame
	check(not source.area_vision.overlaps_body(prey), "prey lies outside ordinary AreaVision P%d" % team)
	mirar(source)
	check(source.rastreador.objetivo_actual() == prey and source.rastreador.presa_visible, "extended sensor acquires reachable prey P%d" % team)
	var snapshot: Vector2 = source.rastreador.ultima_posicion_conocida
	prey.global_position += Vector2(300,0)
	mirar(source, 0.5)
	check(source.rastreador.objetivo_actual() == prey and not source.rastreador.presa_visible, "lock survives temporary range loss P%d" % team)
	check(source.rastreador.ultima_posicion_conocida == snapshot and is_equal_approx(source.rastreador.memoria_restante, 5.5), "lost prey leaves a frozen snapshot with decreasing age P%d" % team)
	prey.global_position += Vector2(100,50)
	mirar(source, 0.5)
	check(source.rastreador.posicion_persecucion() == snapshot, "hidden movement cannot update pursuit point P%d" % team)
	var local_direction: Vector2 = source.rastreador.direccion_local(Vector2.LEFT)
	var route: PackedVector2Array = source.rastreador.ruta_local
	check(local_direction.x > 0.0 and not route.is_empty() and route[route.size()-1] == snapshot, "local route follows last observation P%d" % team)
	mirar(source, 5.1)
	check(source.rastreador.objetivo_actual() == null and not source.rastreador.posicion_persecucion().is_finite(), "six-second memory expires without hidden reacquisition P%d" % team)
	prey.global_position = ORIGIN + Vector2(80,0)
	mirar(source)
	var count: int = source.rastreador.reevaluaciones
	for i in 60: source.rastreador.actualizar(1.0/60.0)
	check(source.rastreador.reevaluaciones - count <= 2, "candidate reevaluation stays on one-second budget P%d" % team)
	await limpiar()

func invalidacion_y_aislamiento(team: int) -> void:
	var source := actor(ORIGIN, team)
	var cluster := actor(ORIGIN + Vector2(80,0), 0)
	actor(ORIGIN + Vector2(80,20), 0)
	actor(ORIGIN + Vector2(80,-20), 0)
	var isolated := actor(ORIGIN + Vector2(-82,0), 0)
	await nav_lista(source)
	mirar(source)
	check(source.rastreador.objetivo_actual() == isolated, "isolated human wins only a similar-distance choice P%d" % team)
	var near := actor(ORIGIN + Vector2(40,0), 0)
	mirar(source)
	check(source.rastreador.objetivo_actual() == isolated, "a valid lock does not oscillate toward a new candidate P%d" % team)
	isolated.activar_infeccion(Color.WHITE, 3-team, false)
	freeze_bot(isolated)
	mirar(source)
	check(source.rastreador.objetivo_actual() == near, "infected prey is abandoned and a valid replacement selected P%d" % team)
	near.queue_free()
	await physics_frame
	mirar(source)
	check(source.rastreador.objetivo_actual() != null and source.rastreador.objetivo_actual() != isolated and not source.rastreador.objetivo_actual().is_infected, "deleted prey is invalidated safely P%d" % team)
	cluster.proteccion_coloso = 99.0
	check(not source.rastreador._presa_valida(cluster), "protected healthy guest is not a futile priority P%d" % team)
	await limpiar()

func manada(team: int) -> void:
	var source := actor(ORIGIN, team)
	var upgrades: Array[String] = ["olfato_reforzado"]
	source.aplicar_mutaciones(upgrades, "rastreador")
	var prey := actor(ORIGIN + Vector2(82,0), 0)
	var allies: Array[Node2D] = []
	for distance in [20,40,60]:
		var ally := actor(ORIGIN - Vector2(distance,0), team)
		ally.aplicar_mutaciones(upgrades, "rastreador")
		allies.append(ally)
	var enemy := actor(ORIGIN + Vector2(0,30), 3-team)
	await nav_lista(source)
	mirar(source)
	check(source.rastreador.miembros.size() == 3 and allies[0].posicion_manada().is_finite() and allies[1].posicion_manada().is_finite() and allies[2].posicion_manada().is_finite(), "first pack tier recruits three local allies P%d" % team)
	check(not enemy.posicion_manada().is_finite(), "local report never leaks to the other team P%d" % team)
	var snapshot: Vector2 = source.rastreador.ultima_posicion_conocida
	prey.global_position += Vector2(300,0)
	mirar(allies[0], 0.2)
	check(allies[0].posicion_manada() == snapshot and not allies[0].rastreador.presa_visible, "report receiver follows only the transmitted snapshot P%d" % team)
	check(allies[0].rastreador.informes_emitidos == 0 and source.rastreador.miembros.size() == 3, "received reports cannot propagate in a chain P%d" % team)
	mirar(source,0.2)
	check(not source.rastreador.presa_visible and not allies[2].rastreador.recibir_rastro(prey, prey.global_position, 0.0, source), "hidden source cannot fabricate a fresh report P%d" % team)
	await limpiar()

func ciclo_y_mejoras() -> void:
	for team in [1,2]:
		var source := actor(ORIGIN,team)
		var prey := actor(ORIGIN + Vector2(70,0),0)
		await nav_lista(source)
		mirar(source)
		source.activar_control_jugador(team)
		check(source.rastreador.direccion_local(Vector2.UP) == Vector2.UP and source.controlado_por_jugador, "possession keeps input authoritative P%d" % team)
		check(source.rastreador.objetivo_actual() == prey, "passive tracking survives possession P%d" % team)
		source.desactivar_control_jugador()
		var before: float = source.rastreador.memoria_restante
		host.timer_juego.paused = true
		source.rastreador.actualizar(10.0)
		check(is_equal_approx(source.rastreador.memoria_restante,before), "tutorial hold freezes memory P%d" % team)
		host.timer_juego.paused = false
		paused = true
		source.rastreador.actualizar(10.0)
		check(is_equal_approx(source.rastreador.memoria_restante,before), "tree pause freezes memory P%d" % team)
		paused = false
		for branch in host.RAMAS.rastreador:
			for level in 3:
				if team == 1: host.adn_cian = 30
				else: host.adn_magenta = 30
				host.comprar_mutacion(team,branch[0])
				check(source.tiene_mutacion(branch[level]) and host.obtener_adn(team) == 30-[5,10,15][level], "DNA tier charged and applied P%d %s" % [team,branch[level]])
		check(is_equal_approx(source.rastreador.factor_deteccion(),1.75) and is_equal_approx(source.rastreador.memoria(),6.0) and source.rastreador.nivel_manada()==3 and source.rastreador.nivel_cerco()==3 and source.rastreador.nivel_marca()==3, "all tactical branches reach tier three without changing base senses P%d" % team)
		check(is_equal_approx(source.speed,source.velocidad_base) and is_equal_approx(source._chance_contagio(),0.35) and is_equal_approx(source.probabilidad_curacion,0.01), "nine tracking upgrades do not buff other stats P%d" % team)
		source._contagiar_objetivo(prey)
		freeze_bot(prey)
		check(prey.is_infected and prey.cepa=="rastreador" and prey.player_duenio==team and prey.mutaciones==source.mutaciones, "contact infection inherits strain and purchased DNA P%d" % team)
		source.tiempo_escudo = 99.0
		check(not source.recibir_curacion_ofensiva(1.0,1.0,3-team), "ordinary shield still stops offensive cure P%d" % team)
		check(source.curar_por_robot(1.0) and source.rastreador==null and source.cepa=="" and source.mutaciones.is_empty(), "robot cure clears tracking and mutations normally P%d" % team)
		await limpiar()
	host.mutaciones_p1.clear()
	host.mutaciones_p2.clear()

func paredes() -> void:
	var source := actor(ORIGIN)
	var prey := actor(ORIGIN+Vector2(82,0),0)
	await nav_lista(source)
	mirar(source)
	var remembered: Vector2 = source.rastreador.ultima_posicion_conocida
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(14,160)
	shape.shape = rectangle
	wall.add_child(shape)
	wall.position = ORIGIN+Vector2(41,0)
	host.add_child(wall)
	await physics_frame
	await physics_frame
	prey.global_position += Vector2(0,12)
	mirar(source,0.2)
	check(not source.rastreador.presa_visible and source.rastreador.ultima_posicion_conocida==remembered, "wall blocks observation even while prey is still inside range")
	mirar(source,6.1)
	check(source.rastreador.objetivo_actual()==null, "occluded prey cannot reacquire itself on memory expiry")
	source.move_direction=Vector2.RIGHT
	var crossed := false
	for i in 180:
		source.velocity=Vector2.RIGHT*75.0
		source.move_and_slide()
		crossed = crossed or source.global_position.x > wall.global_position.x
		await physics_frame
	check(not crossed, "real CharacterBody collision cannot cross a wall")
	wall.queue_free()
	await limpiar()

func mapas_navegados() -> void:
	for map_name in ["Laboratorio","PatoSplash"]:
		if is_instance_valid(host): host.queue_free()
		await process_frame
		root.get_node("PatogenOnboarding").requested_mode="direct"
		root.set_meta("patogen_cepas",{1:"rastreador",2:"rastreador"})
		host=load("res://scenes/"+map_name+".tscn").instantiate()
		root.add_child(host)
		current_scene=host
		if not host.map_is_ready: await host.map_ready
		host.timer_inicio.stop()
		host.estado_actual=host.EstadoJuego.FASE_INFECCION
		host.timer_juego.start(120)
		host.set_process(false)
		host.set_physics_process(false)
		host.evento_coloso.set_physics_process(false)
		host.evento_alfa.set_physics_process(false)
		for duck in get_nodes_in_group("patos"): duck.set_physics_process(false)
		await limpiar()
		var origin := Vector2.INF
		var endpoint := Vector2.INF
		for point in host.npc_destinations:
			for offset in [Vector2(300,0),Vector2(-300,0),Vector2(0,300),Vector2(0,-300)]:
				if host.npc_navigation.limites.has_point(point+offset) and host.npc_navigation.segmento_libre(point,point+offset):
					origin=point
					endpoint=point+offset
					break
			if origin.is_finite(): break
		check(origin.is_finite(),map_name+" has a real clear300px test corridor")
		if not origin.is_finite(): continue
		var source:=actor(origin,1)
		var prey:=actor(endpoint,0)
		mirar(source)
		check(is_equal_approx(source.rastreador.rango_deteccion(),420.0) and source.rastreador.objetivo_actual()==prey,map_name+" detects beyond ordinary240px")
		source.npc_brain._sense(source,host)
		source.npc_brain._decide(source,host)
		check(source.npc_brain.goal==endpoint,map_name+" planner consumes the observed point")
		prey.global_position=origin+origin.direction_to(endpoint)*700.0
		mirar(source,0.2)
		source.npc_brain._sense(source,host)
		source.npc_brain._decide(source,host)
		check(source.npc_brain.target==null and source.npc_brain.goal==endpoint,map_name+" generic target retention cannot bypass snapshot memory")
		mirar(source,6.1)
		source.npc_brain._decide(source,host)
		check(source.npc_brain.mode!="chase",map_name+" planner abandons expired pursuit")
		host._on_timer_juego_timeout()
		check(source.rastreador.objetivo_actual()==null and source.rastreador.efecto.tiempo==0.0,map_name+" FIN cancels memory and visuals before pausing")
		paused=false
