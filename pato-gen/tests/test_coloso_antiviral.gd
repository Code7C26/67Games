extends "res://tests/test_simbionte.gd"
## Escenarios deterministas sobre Shopping real; ninguna opción de prueba en producción.
var evento: Node2D
var intentos: Array[float] = []
var centro := Vector2.ZERO

func fresh_coloso() -> void:
	await fresh()
	evento = host.evento_coloso
	evento.set_physics_process(false)
	evento.tiempo_partida = 0.0
	evento.tiempo_crisis = 0.0
	evento.espera_restante = 0.0
	evento.descanso_restante = 0.0
	var limite := Time.get_ticks_msec() + 5000
	while not evento.navegacion.lista and Time.get_ticks_msec() < limite:
		await physics_frame
	check(evento.navegacion.lista and not evento.posiciones.is_empty(), "coloso grid has reachable interior positions")
	centro = espacio_amplio()
	check(centro != Vector2.ZERO, "real shopping has space for the full test footprint")
	intentos.clear()
	evento.intento_realizado.connect(func(chance: float, _ok: bool): intentos.append(chance))
	# Dos equipos presentes, fuera de la posición que usaremos para aparecer.
	for team in [1, 1, 2, 2]:
		bot_at(centro + Vector2(55, 0), team)
	await physics_frame

func espacio_amplio() -> Vector2:
	var shape := CircleShape2D.new()
	shape.radius = 70.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1
	query.collide_with_areas = false
	for p in evento.posiciones:
		query.transform = Transform2D(0.0, p)
		if host.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty() and evento.posicion_segura(p):
			return p
	return Vector2.ZERO

func stats(sanos: int = 0) -> Dictionary:
	return {"blue": 29, "magenta": 29, "sanos": sanos, "total": 65}

func semilla_entre(minimo: float, maximo: float) -> int:
	var rng := RandomNumberGenerator.new()
	for value in range(10000):
		rng.seed = value
		var numero := rng.randf()
		if numero >= minimo and numero < maximo:
			return value
	return -1

func preparar_aparicion() -> void:
	evento.tiempo_partida = 30.0
	evento.tiempo_crisis = 0.0
	evento.espera_restante = 0.0
	evento.descanso_restante = 0.0
	evento.azar_aparicion.seed = semilla_entre(0.0, 0.39)
	evento.avanzar(5.0, stats())
	check(evento.estado == evento.Estado.AVISO, "successful roll begins a warning without spawning")
	evento.posicion_aviso = centro
	evento.avanzar(3.0, stats())
	check(evento.estado == evento.Estado.ACTIVO and is_instance_valid(evento.coloso), "warning materializes exactly one coloso")

func run() -> void:
	await fresh_coloso()
	check(evento.poblacion_inicial == 65, "baseline captures 65 original scene bots before fixture removal")
	check(evento.en_crisis(stats(7)) and not evento.en_crisis(stats(8)), "critical boundary is 7 healthy bots, not 8")
	check(not evento.en_crisis({"total": 0, "sanos": 0}), "empty population never triggers an intervention")
	check(not evento.en_crisis({"total": 81, "sanos": 8}), "infected replicas do not move the healthy threshold")
	var outsider = load("res://scenes/Bot.tscn").instantiate()
	root.add_child(outsider)
	outsider.set_physics_process(false)
	var counted: Dictionary = host.contar_infecciones()
	check(counted.total == 4 and counted.sanos + counted.blue + counted.magenta == counted.total, "population scan is scoped to the match")
	outsider.queue_free()
	var extra = bot_at(centro, 0)
	extra.queue_free()
	check(host.contar_infecciones().total == 4, "queued deletion is excluded immediately")
	await physics_frame
	evento.azar_aparicion.seed = semilla_entre(0.60, 1.0)
	evento.avanzar(30.0, stats())
	check(intentos.is_empty() and evento.tiempo_crisis == 0.0, "30 second grace does not count as crisis dwell")
	evento.avanzar(4.99, stats())
	check(intentos.is_empty(), "first attempt cannot happen before five seconds")
	evento.avanzar(0.01, stats())
	check(intentos == [0.60] and evento.estado == evento.Estado.ESPERA, "first roll is at five seconds with 60 percent, and may fail")
	evento.azar_aparicion.seed = semilla_entre(0.60, 1.0)
	evento.avanzar(19.99, stats())
	check(intentos.size() == 1, "failed roll waits twenty seconds")
	evento.avanzar(0.01, stats())
	check(intentos == [0.60, 0.60] and evento.apariciones == 0, "failed attempts neither lower probability nor consume appearances")
	evento.avanzar(0.1, stats(8))
	check(evento.tiempo_crisis == 0.0 and evento.espera_restante == 0.0 and intentos.size() == 2, "healthy recovery clears crisis and failed-attempt delay without a roll")
	evento.avanzar(4.0, stats(7))
	evento.avanzar(1.0, stats(8))
	evento.avanzar(4.0, stats(7))
	check(intentos.size() == 2, "interrupted crisis needs a fresh five seconds")
	var clock: float = evento.tiempo_crisis
	host.timer_juego.paused = true
	evento.avanzar(100.0, stats())
	check(evento.tiempo_crisis == clock, "tutorial-held match timer freezes crisis and attempt clocks")
	host.timer_juego.paused = false
	paused = true
	evento.avanzar(100.0, stats())
	check(evento.tiempo_crisis == clock, "global pause freezes even a direct scheduler call")
	paused = false
	evento.azar_aparicion.seed = semilla_entre(0.40, 0.60)
	evento.avanzar(1.0, stats())
	check(evento.estado == evento.Estado.AVISO and evento.apariciones == 0, "a new five-second crisis rolls at 60 percent without inheriting the old failed-attempt delay")
	evento.avanzar(0.1, stats(8))
	check(evento.estado == evento.Estado.ESPERA and evento.probabilidad_actual() == 0.60, "recovery cancels warning without reducing probability")
	await preparar_aparicion()
	var first: Node2D = evento.coloso
	var count_before: int = host.contar_infecciones().total
	check(evento.apariciones == 1 and evento.probabilidad_actual() == 0.40, "only actual materialization changes future probability to 40 percent")
	check(not first.is_in_group("bots") and not first.is_in_group("robots_curadores"), "coloso is neither population nor an invocable robot")
	evento._materializar()
	check(get_nodes_in_group("colosos_antivirales").size() == 1 and evento.apariciones == 1, "duplicate spawn calls cannot create another coloso")
	var attempts_before := intentos.size()
	evento.avanzar(0.5, stats())
	check(intentos.size() == attempts_before and host.contar_infecciones().total == count_before, "active intervention neither rolls nor duplicates population")
	var before_life: float = evento.activo_restante
	host.timer_juego.paused = true
	evento.avanzar(30.0, stats())
	check(evento.activo_restante == before_life, "tutorial pause also freezes active duration and healing")
	host.timer_juego.paused = false
	evento.avanzar(2.99, stats(17))
	check(evento.estado == evento.Estado.ACTIVO, "recovery must persist for three seconds before retreat")
	evento.avanzar(0.01, stats(17))
	check(evento.estado == evento.Estado.ESPERA and evento.coloso == null, "sustained healthy recovery retires first intervention")
	await physics_frame
	check(not is_instance_valid(first), "retired actor is freed")
	evento.azar_aparicion.seed = semilla_entre(0.40, 0.60)
	evento.avanzar(19.99, stats())
	check(intentos.size() == attempts_before, "retirement starts a full twenty-second wait")
	evento.avanzar(0.01, stats())
	check(intentos.back() == 0.40 and evento.estado == evento.Estado.ESPERA, "same 40-to-60 roll fails after the first appearance")
	evento.azar_aparicion.seed = semilla_entre(0.0, 0.39)
	evento.avanzar(20.0, stats())
	evento.posicion_aviso = centro
	evento.avanzar(3.0, stats())
	check(evento.apariciones == 2 and evento.estado == evento.Estado.ACTIVO, "a second intervention can actually appear")
	var second: Node2D = evento.coloso
	var healed_before: int = second.curaciones
	evento.avanzar(20.0, stats())
	check(evento.estado == evento.Estado.FINALIZADO and second.curaciones == healed_before, "duration expiry happens before any boundary healing pulse")
	attempts_before = intentos.size()
	evento.avanzar(100.0, stats())
	check(intentos.size() == attempts_before and evento.apariciones == 2, "two appearances are the hard match limit")
	await fresh_coloso()
	host.timer_juego.start(25.0)
	evento.tiempo_partida = 40.0
	evento.avanzar(30.0, stats())
	check(intentos.is_empty(), "last 25 seconds prohibit new rolls")
	host.timer_juego.start(120.0)
	await preparar_aparicion()
	host._on_timer_juego_timeout()
	check(evento.estado == evento.Estado.FINALIZADO and evento.coloso == null and paused, "game over removes the intervention before freezing the match")
	paused = false
	await _healing()
	await _spawn_failures()
	if is_instance_valid(host):
		host.queue_free()
		await process_frame
	print("COLOSO RESULT ", passed, " passed; ", failures, " failed")
	quit(0 if failures == 0 else 1)

func _healing() -> void:
	await fresh_coloso()
	await preparar_aparicion()
	var actor: Node2D = evento.coloso
	var bot: Node2D = get_nodes_in_group("bots")[0]
	bot.global_position = centro + Vector2(45, 0)
	var rival: Node2D = get_nodes_in_group("bots")[2]
	rival.global_position = centro + Vector2(-45, 0)
	var original_ids: Array = get_nodes_in_group("bots").map(func(b): return b.get_instance_id())
	var money_before := [host.adn_cian, host.adn_magenta, host.contagios_cian, host.contagios_magenta]
	var defensas: Array[String] = ["ultimo_aliento", "regeneracion", "infeccion_inmortal"]
	bot.aplicar_mutaciones(defensas)
	bot.blindaje_restante = 100.0
	check(bot.curar_por_coloso(1.0, 3.0, evento.azar_curacion), "external coloso healing reuses robot rules even with ordinary shields")
	check(not bot.is_infected and bot.proteccion_coloso == 3.0 and bot.reinfeccion_coloso_sin_recompensa, "healed bot becomes neutral with protection and one reward suppression")
	check(money_before == [host.adn_cian, host.adn_magenta, host.contagios_cian, host.contagios_magenta], "healing itself changes neither DNA nor accumulated contagions")
	var atacante: Node2D = get_nodes_in_group("bots")[1]
	var mejoras: Array[String] = ["contagio_cadena", "regeneracion"]
	atacante.aplicar_mutaciones(mejoras)
	atacante.blindaje_restante = 0.0
	atacante._contagiar_objetivo(bot)
	check(not bot.is_infected and atacante.bonus_contagio_temporal == 0.0 and atacante.blindaje_restante == 0.0, "failed infection of protected human grants no attacker buffs")
	bot.activar_infeccion(Color.MAGENTA, 2)
	check(not bot.is_infected and bot.reinfeccion_coloso_sin_recompensa, "direct activation cannot bypass coloso protection or consume its marker")
	bot.proteccion_coloso = 0.0
	bot.infectar(Color.MAGENTA, 2)
	check(bot.is_infected and bot.player_duenio == 2 and not bot.reinfeccion_coloso_sin_recompensa, "next valid infection changes population and consumes suppression")
	check(money_before == [host.adn_cian, host.adn_magenta, host.contagios_cian, host.contagios_magenta], "next reinfection by the other team gives neither DNA nor adaptation progress")
	bot.curar_por_robot(1.0)
	bot.infectar(Color.CYAN, 1)
	check(host.adn_cian == money_before[0] + 1 and host.contagios_cian == money_before[2] + 1, "later ordinary robot/reinfection cycle retains original rewards")
	bot.timer_contagio.stop()
	bot.timer_curacion.stop()
	check(original_ids == get_nodes_in_group("bots").map(func(b): return b.get_instance_id()), "healing/reinfection preserves all entity identities")
	# El bot poseído se libera por el ciclo existente del Pato.
	var duck: Node2D = host.interfaz.ducks[0]
	duck.iniciar_posesion(bot)
	bot.curar_por_coloso(1.0, 3.0, evento.azar_curacion)
	duck._physics_process(0.01)
	check(duck.bot_poseido == null and not bot.controlado_por_jugador and duck.visible, "healing releases possession through its existing lifecycle")
	# La última infección cian queda fuera de los candidatos.
	var posibles: Array = RADIAL.candidatos_coloso(actor, 140.0, {})
	check(atacante not in posibles and rival in posibles, "coloso excludes the last infection of a team but may heal the other team")
	# La resistencia del Simbionte reduce la misma tirada, sin duplicar lógica.
	check(rival.aplicar_simbionte(host, 2), "symbiont fixture attaches to an eligible rival")
	evento.azar_curacion.seed = semilla_entre(0.50, 0.80)
	check(not rival.curar_por_coloso(0.80, 3.0, evento.azar_curacion) and rival.efecto_simbionte != null, "symbiont halves coloso probability and survives a resisted roll")
	evento.azar_curacion.seed = semilla_entre(0.0, 0.39)
	check(rival.curar_por_coloso(0.80, 3.0, evento.azar_curacion) and rival.efecto_simbionte == null, "successful external healing removes fusion using the original cleanup")
	# Propiedad réplica, cuotas y poder no se copian por curación.
	rival.es_replica = true
	rival.proteccion_coloso = 0.0
	rival.activar_infeccion(Color.MAGENTA, 2, false)
	var quotas := [host.replicas_cian, host.replicas_magenta]
	rival.curar_por_coloso(1.0, 3.0, evento.azar_curacion)
	check(rival.es_replica and quotas == [host.replicas_cian, host.replicas_magenta], "healing replica neither duplicates it nor refunds reproduction quota")
	# Línea de visión exclusiva del Coloso: el robot conserva su alcance anterior.
	bot.proteccion_coloso = 0.0
	bot.activar_infeccion(Color.CYAN, 1, false)
	bot.timer_contagio.stop()
	bot.timer_curacion.stop()
	var wall := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(8, 60)
	collision.shape = rectangle
	wall.add_child(collision)
	host.add_child(wall)
	wall.global_position = centro + Vector2(23, 0)
	await physics_frame
	await physics_frame
	check(not RADIAL.linea_libre(actor, bot.global_position), "a physical wall blocks coloso line of sight")
	RADIAL.aplicar(actor, 140.0, 1.0)
	check(not bot.is_infected, "existing robot radial path still heals through a wall")
	wall.queue_free()
	await physics_frame
	# El filtrado de objetivos tratados no depende del color posterior.
	bot.proteccion_coloso = 0.0
	bot.activar_infeccion(Color.CYAN, 1, false)
	atacante.activar_infeccion(Color.CYAN, 1, false)
	actor.tratados[bot.get_instance_id()] = true
	check(bot not in RADIAL.candidatos_coloso(actor, 140.0, actor.tratados), "same entity cannot be treated twice in one intervention")
	actor.curaciones = evento.max_curaciones
	var healthy_before: int = host.contar_infecciones().sanos
	evento.avanzar(0.01, stats())
	check(evento.coloso == null and host.contar_infecciones().sanos == healthy_before, "exhausted treatment budget retires without additional healing")

func _spawn_failures() -> void:
	await fresh_coloso()
	evento.tiempo_partida = 30.0
	evento.azar_aparicion.seed = semilla_entre(0.0, 0.39)
	var saved: PackedVector2Array = evento.posiciones
	evento.posiciones = PackedVector2Array()
	evento.avanzar(5.0, stats())
	check(evento.estado == evento.Estado.ESPERA and evento.apariciones == 0 and evento.coloso == null, "no safe candidates fail without consuming an appearance")
	evento.posiciones = saved
	evento.espera_restante = 0.0
	evento.azar_aparicion.seed = semilla_entre(0.0, 0.39)
	evento.avanzar(0.01, stats())
	evento.posicion_aviso = centro
	var blocker := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 30.0
	blocker.add_child(shape)
	host.add_child(blocker)
	blocker.global_position = centro
	await physics_frame
	await physics_frame
	evento.avanzar(3.0, stats())
	check(evento.estado == evento.Estado.ESPERA and evento.apariciones == 0, "new obstacle during warning cancels actual spawn")
	check(evento.probabilidad_actual() == 0.60, "blocked appearance preserves first-appearance probability")
	blocker.queue_free()
	await physics_frame
