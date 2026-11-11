extends "res://tests/test_rastreador.gd"
## Contratos tácticos contra Bot, percepción, colisiones y estados reales.
const TRACKING = preload("res://scripts/rastreador.gd")

func mutar(bot: Node2D, ids: Array, strain: String) -> void:
	var upgrades: Array[String] = []
	upgrades.assign(ids)
	bot.aplicar_mutaciones(upgrades, strain)

func run() -> void:
	seed(91717)
	await preparar()
	for team in [1, 2]:
		await desbloqueos(team)
		await convocatoria_y_exclusiones(team)
		await cerco_y_retorno(team)
		await marca_y_percepcion(team)
		await invalidez_y_posesion(team)
	await manadas_simultaneas()
	print("RASTREADOR MUTATIONS RESULT ", passed, " passed; ", failures, " failed")
	await terminar()
	quit(0 if failures == 0 else 1)

func fixture(team: int, upgrades: Array[String], count: int = 3) -> Dictionary:
	var source := actor(ORIGIN, team)
	source.aplicar_mutaciones(upgrades, "rastreador")
	var allies: Array[Node2D] = []
	var offsets := [Vector2(-45,-45), Vector2(-45,45), Vector2(-85,0), Vector2(-125,0)]
	var strains := ["atletico", "exponencial", "area", "rastreador"]
	for i in count:
		var ally := actor(ORIGIN + offsets[i], team)
		mutar(ally, [], strains[i])
		allies.append(ally)
	var prey := actor(ORIGIN + Vector2(80,0), 0)
	return {"source": source, "prey": prey, "allies": allies}

func begin(f: Dictionary) -> void:
	await nav_lista(f.source)
	await physics_frame
	mirar(f.source)

func clear_encirclement_site(tracker: Node2D) -> Vector2:
	for site in tracker.navegacion.posiciones_transitables(ORIGIN,19.0):
		var clear := true
		for offset in [Vector2(80,0), Vector2(-45,-45), Vector2(-45,45), Vector2(-85,0)]:
			if not tracker.navegacion.segmento_libre(site,site + offset):
				clear = false
				break
		if clear:
			for flank in [Vector2(0,-48),Vector2(0,48),Vector2(48,0)]:
				if not tracker.navegacion.segmento_libre(site + Vector2(80,0),site + Vector2(80,0) + flank):
					clear = false
					break
		if clear: return site
	return Vector2.INF

func desbloqueos(team: int) -> void:
	for mutation in ["", "fijacion_presa", "instinto_manada", "olfato_reforzado"]:
		var upgrades: Array[String] = []
		if mutation != "": upgrades.append(mutation)
		var f := fixture(team, upgrades)
		await begin(f)
		var tracker: Node2D = f.source.rastreador
		check(tracker.objetivo_actual() == f.prey and tracker.presa_visible, "base detection survives individual unlock %s P%d" % [mutation,team])
		check(is_equal_approx(tracker.factor_deteccion(),1.75) and is_equal_approx(tracker.memoria(),6.0), "individual mutation preserves base perception %s P%d" % [mutation,team])
		check(tracker.miembros.size() == (3 if mutation == "olfato_reforzado" else 0), "only Llamado recruits allies P%d %s" % [team,mutation])
		check((tracker.marca_restante > 0.0) == (mutation == "instinto_manada"), "only Marca marks prey P%d %s" % [team,mutation])
		check(not tracker.cerco_activo, "Cerco needs a called pack and its unlock P%d %s" % [team,mutation])
		check(is_equal_approx(f.source.speed, f.source.velocidad_base) and is_equal_approx(f.source._chance_contagio(),0.35), "no artificial speed or infection boost P%d %s" % [team,mutation])
		await limpiar()

func convocatoria_y_exclusiones(team: int) -> void:
	var f := fixture(team, ["olfato_reforzado"], 4)
	var rival := actor(ORIGIN + Vector2(0,-45), 3-team)
	var incubating := actor(ORIGIN + Vector2(0,45), team)
	incubating.incubacion_contagio = 1.0
	var possessed := actor(ORIGIN + Vector2(0,-65), team)
	possessed.activar_control_jugador(team)
	var hook_busy := actor(ORIGIN + Vector2(0,65), team)
	mutar(hook_busy, [], "garfio")
	hook_busy.garfio.estado = hook_busy.garfio.Estado.PREPARANDO
	var hidden := actor(ORIGIN + Vector2(-20,0), team)
	mutar(hidden, [], "camaleon")
	hidden.camaleon.camuflado = true
	var distant := actor(ORIGIN + Vector2(-200,0), team)
	await begin(f)
	var tracker: Node2D = f.source.rastreador
	check(tracker.miembros.size() == 3 and tracker.convocatorias == 1, "one call selects exactly three allies P%d" % team)
	for i in 3:
		check(TRACKING.coordinador_de(f.allies[i]) == tracker, "different strain joins same-team pack P%d index%d" % [team,i])
	for excluded in [f.allies[3], rival, incubating, possessed, hook_busy, hidden, distant, f.prey]:
		check(TRACKING.coordinador_de(excluded) == null, "unavailable, rival, healthy or excess candidate excluded P%d" % team)
	check(is_equal_approx(tracker.manada_restante, 8.0) and tracker.coordinacion_restante <= 8.0, "call cooldown and coordination use eight seconds P%d" % team)
	tracker.actualizar(0.1)
	check(tracker.convocatorias == 1, "same lock cannot issue repeated calls during cooldown P%d" % team)
	tracker.actualizar(8.0)
	check(tracker.miembros.is_empty() and not f.allies[0].posicion_manada().is_finite(), "coordination expires and clears allied orders P%d" % team)
	await limpiar()

func cerco_y_retorno(team: int) -> void:
	var f := fixture(team, ["olfato_reforzado", "fijacion_presa"])
	await begin(f)
	var tracker: Node2D = f.source.rastreador
	var site := clear_encirclement_site(tracker)
	check(site.is_finite(), "real map has a clear encirclement test site P%d" % team)
	if site.is_finite():
		tracker.cancelar()
		tracker.manada_restante = 0.0
		f.source.global_position = site
		f.prey.global_position = site + Vector2(80,0)
		var offsets := [Vector2(-45,-45), Vector2(-45,45), Vector2(-85,0)]
		for i in 3: f.allies[i].global_position = site + offsets[i]
		mirar(f.source)
	check(tracker.cerco_activo and tracker.miembros.size() == 3, "leader plus three allies forms encirclement P%d" % team)
	check(f.source.posicion_manada() == f.prey.global_position, "leader retains direct pursuit P%d" % team)
	var lateral_destinations: Array[Vector2] = []
	for datos in tracker.miembros:
		if datos.lateral: lateral_destinations.append(datos.destino)
	check(lateral_destinations.size() >= 2 and lateral_destinations[0] != lateral_destinations[1], "lateral roles use different reachable directions P%d" % team)
	for datos in tracker.miembros:
		check(not datos.ruta.is_empty(), "each approach has an actual navigable path P%d" % team)
	var routes_before: int = tracker.rutas_cerco
	for i in 20: tracker.actualizar(0.01)
	check(tracker.rutas_cerco == routes_before, "flank routes are not recalculated each frame P%d" % team)
	# Blocking the final flank segment must fall back to the observed prey point.
	var wall := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(30,10)
	collision.shape = rectangle
	wall.add_child(collision)
	wall.global_position = f.prey.global_position + Vector2(0,-24)
	host.add_child(wall)
	await physics_frame
	await physics_frame
	tracker._actualizar_destinos()
	var first: Dictionary = tracker.miembros[0]
	check(not first.lateral and first.destino == first.punto, "invalid side route uses ordinary pursuit P%d" % team)
	wall.queue_free()
	TRACKING.liberar_miembro(f.allies[0])
	TRACKING.liberar_miembro(f.allies[1])
	tracker._actualizar_manada(0.01)
	check(not tracker.cerco_activo and tracker.miembros.size() == 1, "losing participants dismantles encirclement P%d" % team)
	var remaining: Dictionary = tracker.miembros[0]
	check(not remaining.lateral and remaining.destino == remaining.punto, "remaining ally returns to direct pursuit P%d" % team)
	await limpiar()

func marca_y_percepcion(team: int) -> void:
	var f := fixture(team, ["olfato_reforzado", "instinto_manada"])
	await begin(f)
	var tracker: Node2D = f.source.rastreador
	check(is_equal_approx(tracker.marca_restante,8.0), "biological mark starts at eight seconds P%d" % team)
	check(not tracker.efecto.mostrar_marca, "shared viewport reveals no prey marker to enemy P%d" % team)
	host.set_meta("equipo_visible", team)
	tracker.actualizar(0.1)
	check(tracker.efecto.mostrar_marca, "explicit owner view can display visible marked prey P%d" % team)
	host.set_meta("equipo_visible", 3-team)
	tracker.actualizar(0.1)
	check(not tracker.efecto.mostrar_marca, "opponent view cannot display private mark P%d" % team)
	host.remove_meta("equipo_visible")
	var marker_age: float = tracker.marca_restante
	f.prey.global_position = ORIGIN + Vector2(130,0)
	f.allies[0].global_position = ORIGIN + Vector2(100,0)
	mirar(f.source, 0.2)
	check(not tracker.presa_visible and tracker.ultima_posicion_conocida == f.prey.global_position, "ally perception can update marked target after leader loses sight P%d" % team)
	check(tracker.marca_restante < marker_age, "a new observation does not renew mark duration P%d" % team)
	var known: Vector2 = tracker.ultima_posicion_conocida
	f.prey.global_position = ORIGIN + Vector2(500,0)
	mirar(f.source, 0.2)
	for i in 3:
		check(tracker._datos_miembro(f.allies[i]).punto == known, "mark shares only last actual observation P%d member%d" % [team,i])
	check(tracker.ultima_posicion_conocida == known, "hidden prey cannot update mark position P%d" % team)
	tracker.actualizar(7.6)
	check(tracker.marca_restante == 0.0 and tracker.efecto.marca == null, "mark expires without hidden reacquisition P%d" % team)
	await limpiar()

func invalidez_y_posesion(team: int) -> void:
	var f := fixture(team, ["olfato_reforzado", "fijacion_presa", "instinto_manada"])
	await begin(f)
	var tracker: Node2D = f.source.rastreador
	f.source.activar_control_jugador(team)
	check(TRACKING.coordinador_de(f.source) == tracker and tracker.miembros.size() == 3, "possessed leader retains automatic pack P%d" % team)
	check(tracker.direccion_local(Vector2.UP) == Vector2.UP, "possession input keeps movement authority P%d" % team)
	f.allies[0].activar_control_jugador(team)
	check(TRACKING.coordinador_de(f.allies[0]) == null and tracker.miembros.size() == 2, "possessing an ally releases its reservation P%d" % team)
	f.prey.activar_infeccion(Color.WHITE, 3-team, false)
	f.prey.curar(false)
	check(tracker.objetivo_actual() == null and tracker.miembros.is_empty() and tracker.marca_restante == 0.0, "infection and cure between ticks cannot preserve old prey or mark P%d" % team)
	await limpiar()
	f = fixture(team, ["olfato_reforzado", "instinto_manada"])
	await begin(f)
	tracker = f.source.rastreador
	f.allies[0].curar(false)
	f.allies[0].proteccion_coloso = 3.0
	check(TRACKING.coordinador_de(f.allies[0]) == null and tracker.miembros.size() == 2, "curing an ally immediately releases its pack P%d" % team)
	f.prey.queue_free()
	await physics_frame
	tracker.actualizar(0.01)
	check(tracker.objetivo_actual() == null and tracker.miembros.is_empty(), "deleted prey clears coordination safely P%d" % team)
	await limpiar()

func manadas_simultaneas() -> void:
	var f := fixture(1, ["olfato_reforzado"])
	await begin(f)
	var first: Node2D = f.source.rastreador
	var second := actor(ORIGIN + Vector2(-20,0), 1)
	mutar(second, ["olfato_reforzado"], "rastreador")
	for offset in [Vector2(-70,0), Vector2(-105,0), Vector2(-140,0)]:
		var ally := actor(ORIGIN + offset, 1)
		mutar(ally, [], "atletico")
	# Move prey into both sensors; first pack keeps its original reservations.
	f.prey.global_position = ORIGIN + Vector2(65,0)
	mirar(second)
	check(first.miembros.size() == 3 and second.rastreador.miembros.size() == 3, "two leaders can coordinate simultaneous packs")
	var overlap := false
	for one in first.miembros:
		for two in second.rastreador.miembros:
			if one.bot.get_ref() == two.bot.get_ref(): overlap = true
	check(not overlap, "an ally never belongs to both simultaneous packs")
	var invited: Node2D = f.allies[0]
	mutar(invited, ["olfato_reforzado"], "rastreador")
	mirar(invited)
	check(invited.rastreador.miembros.is_empty(), "a recruited Rastreador cannot start another pack")
	await limpiar()
