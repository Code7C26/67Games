extends "res://tests/test_garfio.gd"
## Mutaciones sobre cuerpos, colisiones y contagio reales; semillas sólo fijan la tirada.
var arena := Vector2.INF

func zona_doble() -> Vector2:
	if arena.is_finite(): return arena
	var nav: Node2D = host.navegacion_simbionte
	var radio_previo: float = nav.circulo.radius
	nav.circulo.radius = 19.0 # Reserva la cápsula humana completa, no sólo el viajero.
	for punto in nav.posiciones_transitables(ORIGIN, 24.0):
		var libre := true
		for offset in [Vector2(100, -60), Vector2(100, 60), Vector2(145, 0)]:
			if not nav.segmento_libre(punto, punto + offset): libre = false; break
		if libre:
			arena = punto
			break
	nav.circulo.radius = radio_previo
	check(arena.is_finite(), "real Shopping floor contains a clear dual-capture span")
	return arena

func run() -> void:
	await preparar()
	for team in [1, 2]:
		await desbloqueos(team)
		await vulnerable(team)
		await doble(team, false)
		await doble(team, true)
		await cancelacion_independiente(team)
		await reenganche(team)
		await invalidacion_entre_ticks(team)
	print("GARFIO MUTATIONS RESULT ", passed, " passed; ", failures, " failed")
	paused = false
	if is_instance_valid(host): host.queue_free()
	await process_frame
	await process_frame
	READABILITY.textures.clear()
	load("res://scripts/Bot.gd").frames_infectados_cache.clear()
	root.get_node("AudioManager").detener_musica()
	quit(0 if failures == 0 else 1)

func mutar(bot: Node2D, names: Array) -> void:
	var mutations: Array[String] = []
	mutations.assign(names)
	bot.aplicar_mutaciones(mutations, "garfio")

func completar(ability: Node2D, target: Node2D) -> void:
	for _i in 50:
		if not is_instance_valid(target.captor_garfio): return
		var tendon: Node2D = target.captor_garfio
		tendon.arrastrar_objetivo(target, 0.025)
		ability.actualizar(0.025)

func desbloqueos(team: int) -> void:
	await limpiar()
	var source := actor(ORIGIN, team)
	for bits in 8:
		var names: Array = []
		if bits & 1: names.append("tendon_reforzado")
		if bits & 2: names.append("arrastre_brutal")
		if bits & 4: names.append("gancho_virulento")
		mutar(source, names)
		var g: Node2D = source.garfio
		check(g.nivel_vulnerable() == (1 if bits & 1 else 0) and g.nivel_doble() == (1 if bits & 2 else 0) and g.nivel_reenganche() == (1 if bits & 4 else 0), "individual/combined unlocks %d P%d" % [bits, team])
		check(is_equal_approx(g.alcance(), 160.0) and is_equal_approx(source.speed, source.velocidad_base * 0.9) and is_equal_approx(source._chance_contagio(), 0.35), "unlocks preserve base range, movement and normal contagion %d P%d" % [bits, team])

func vulnerable(team: int) -> void:
	await limpiar()
	var source := actor_contador(ORIGIN, team)
	mutar(source, ["tendon_reforzado"])
	var target := actor(ORIGIN + Vector2(120, 0), 0)
	var g: Node2D = source.garfio
	source.probabilidad_contagio = 0.40
	check(hook(g, target), "vulnerable fixture physically hooks P%d" % team)
	seed(semilla_entre(0.66, 0.95))
	completar(g, target)
	check(not target.is_infected and source.intentos_llegada == 1, "+25pp can fail and arrival rolls exactly once P%d" % team)
	var effect: Node2D = target.get_node_or_null("PresaVulnerable")
	check(is_instance_valid(effect) and effect.consumido and is_equal_approx(effect.factor_movimiento(), 0.5), "failed roll consumes bonus but leaves brief disorientation P%d" % team)
	check(is_equal_approx(g.preparar_intento(target, 0.4), 0.4), "same victim cannot reuse consumed bonus P%d" % team)
	if is_instance_valid(effect):
		target.move_direction = Vector2.RIGHT
		target.tiempo_evasion = 0.5
		target._physics_process(0.01)
		check(target.velocity.length() > 0.0 and is_equal_approx(target.velocity.length(), target.velocidad_base * 0.5), "healthy AI still moves at the temporary disorientation speed P%d" % team)
		effect.actualizar(1.01)
		check(is_equal_approx(effect.factor_movimiento(), 1.0), "disorientation expires and restores movement P%d" % team)
		target._physics_process(0.01)
		check(is_equal_approx(target.velocity.length(), target.velocidad_base), "real movement returns to normal after the one-second effect P%d" % team)
	await physics_frame
	# Isolate probability ownership using an actual completed capture waiting its cadence.
	ready_again(g)
	target.global_position = ORIGIN + Vector2(120, 0)
	check(hook(g, target), "second vulnerable fixture hooks P%d" % team)
	g.cadencia_restante = 0.7
	target.global_position = ORIGIN + Vector2(36, 0)
	g.arrastrar_objetivo(target, 0.01)
	effect = target.get_node_or_null("PresaVulnerable")
	var other := actor(ORIGIN + Vector2(-80, 0), team)
	check(is_instance_valid(effect) and is_equal_approx(effect.consumir(other.garfio, 0.4), 0.4) and not effect.consumido, "another Garfio cannot consume or use the captured prey bonus P%d" % team)
	check(is_equal_approx(effect.consumir(g, 0.4), 0.65) and is_equal_approx(effect.consumir(g, 0.4), 0.4), "40 percent becomes65 exactly once P%d" % team)
	# A fresh effect proves the hard maximum independently of the random outcome.
	g._registrar_captura(target)
	effect = target.get_node("PresaVulnerable")
	check(is_equal_approx(effect.consumir(g, 0.95), 0.90), "vulnerability never exceeds90 percent P%d" % team)
	target.proteccion_coloso = 2.0
	check(is_equal_approx(effect.factor_movimiento(), 1.0) and not g._objetivo_valido(target), "immunity cancels the victim state P%d" % team)

func doble(team: int, combined: bool) -> void:
	await limpiar()
	var origin := zona_doble()
	var source := actor_contador(origin, team)
	mutar(source, ["arrastre_brutal", "tendon_reforzado", "gancho_virulento"] if combined else ["arrastre_brutal"])
	var first := actor(origin + Vector2(100, -60), 0)
	var second := actor(origin + Vector2(100, 60), 0)
	var spare := actor(origin + Vector2(145, 0), 0)
	var g: Node2D = source.garfio
	if combined:
		source.activar_control_jugador(team)
		source.recibir_control_jugador(Vector2.RIGHT)
	check(g.activar_manual() if combined else g.intentar_enganche(first), "same ability starts dual capture AI/possession%s P%d" % [combined, team])
	check(g.objetivo != null and is_instance_valid(g.segundo_tendon) and g.segundo_tendon.objetivo != null and g.objetivo != g.segundo_tendon.objetivo and spare.captor_garfio == null, "two independent reservations and no third target%s P%d" % [combined, team])
	check(is_equal_approx(g.velocidad_arrastre(), 160.0) and is_equal_approx(g.duracion_arrastre(), 0.8125), "double pull lasts25 percent longer at unchanged travel distance%s P%d" % [combined, team])
	g.actualizar(g.parametros.preparacion)
	for _i in 25:
		if g.estado == G.Estado.ARRASTRANDO and g.segundo_tendon.estado == G.Estado.ARRASTRANDO: break
		g.actualizar(0.025)
	check(g.estado == G.Estado.ARRASTRANDO and g.segundo_tendon.estado == G.Estado.ARRASTRANDO, "both projectiles hit independently%s P%d" % [combined, team])
	source.probabilidad_contagio = 0.0
	seed(semilla_entre(0.8, 0.95))
	# Move both real capsules concurrently; zero chance without Presa, seeded miss with it.
	for _i in 50:
		for prey in [first, second]:
			if is_instance_valid(prey.captor_garfio): prey.captor_garfio.arrastrar_objetivo(prey, 0.025)
		g.actualizar(0.025)
		if first.captor_garfio == null and second.captor_garfio == null: break
	check(first.captor_garfio == null and second.captor_garfio == null and first.global_position.distance_to(origin) <= 36.2 and second.global_position.distance_to(origin) <= 36.2, "both bodies arrive physically%s P%d" % [combined, team])
	check(source.intentos_llegada == 1 and not first.is_infected and not second.is_infected, "double arrival is not simultaneous automatic infection%s P%d" % [combined, team])
	check(g.recarga_restante > 6.0 and not g.reenganche_activado, "failed first attempt keeps shared normal cooldown%s P%d" % [combined, team])
	if combined:
		check(first.get_node_or_null("PresaVulnerable") != null and second.get_node_or_null("PresaVulnerable") != null, "each completed capture receives its own effect P%d" % team)
	source.probabilidad_contagio = 0.0
	seed(semilla_entre(0.8, 0.95))
	g.actualizar(0.71)
	check(source.intentos_llegada == 2 and not first.is_infected and not second.is_infected, "second arrival uses next normal cadence%s P%d" % [combined, team])
	g.actualizar(0.71)
	check(source.intentos_llegada == 2, "both arrival attempts remain single-use%s P%d" % [combined, team])
	if combined: source.desactivar_control_jugador()

func cancelacion_independiente(team: int) -> void:
	await limpiar()
	var origin := zona_doble()
	var source := actor(origin, team)
	mutar(source, ["arrastre_brutal"])
	var first := actor(origin + Vector2(100, -60), 0)
	var second := actor(origin + Vector2(100, 60), 0)
	var g: Node2D = source.garfio
	check(g.intentar_enganche(first), "independent interruption fixture P%d" % team)
	first.activar_infeccion(Color.WHITE, 3 - team, false)
	check(first.captor_garfio == null and second.captor_garfio == g.segundo_tendon and g.segundo_tendon.estado == G.Estado.PREPARANDO, "invalidating one target preserves the other reservation P%d" % team)
	g.actualizar(g.parametros.preparacion)
	for _i in 25: g.actualizar(0.025)
	source.probabilidad_contagio = 0.0
	completar(g, second)
	check(second.global_position.distance_to(origin) <= 36.2 and second.captor_garfio == null, "surviving tendon completes its physical capture P%d" % team)
	await limpiar()
	source = actor(origin, team)
	mutar(source, ["arrastre_brutal"])
	first = actor(origin + Vector2(100, -60), 0)
	second = actor(origin + Vector2(100, 60), 0)
	g = source.garfio
	first.proteccion_coloso = 2.0
	second.proteccion_sano_ofensiva = 2.0
	check(not g._buscar_objetivo() and first.captor_garfio == null and second.captor_garfio == null, "two protected humans cannot be hooked P%d" % team)
	first.proteccion_coloso = 0.0
	second.proteccion_sano_ofensiva = 0.0
	check(g.intentar_enganche(first), "dual wall fixture begins P%d" % team)
	var wall := pared(origin + Vector2(60, -36), Vector2(5, 20))
	await physics_frame
	await physics_frame
	g.actualizar(0.4)
	check(first.captor_garfio == null and second.captor_garfio == g.segundo_tendon, "wall blocks only its own appendage P%d" % team)
	second.queue_free()
	await physics_frame
	g.actualizar(0.1)
	check(g.segundo_tendon.objetivo == null, "deleted second target is released safely P%d" % team)
	wall.queue_free()
	await physics_frame

func reenganche(team: int) -> void:
	await limpiar()
	var origin := zona_doble()
	var source := actor_contador(origin, team)
	mutar(source, ["tendon_reforzado", "arrastre_brutal", "gancho_virulento"])
	var first := actor(origin + Vector2(100, -60), 0)
	var second := actor(origin + Vector2(100, 60), 0)
	var g: Node2D = source.garfio
	check(g.intentar_enganche(first), "Reenganche combined fixture starts P%d" % team)
	g.actualizar(g.parametros.preparacion)
	for _i in 25:
		if g.estado == G.Estado.ARRASTRANDO and g.segundo_tendon.estado == G.Estado.ARRASTRANDO: break
		g.actualizar(0.025)
	# Both real pulls end on a deterministic successful first roll.
	source.probabilidad_contagio = 0.40
	seed(semilla_entre(0.41, 0.64))
	for _i in 50:
		for prey in [first, second]:
			if is_instance_valid(prey.captor_garfio): prey.captor_garfio.arrastrar_objetivo(prey, 0.025)
		g.actualizar(0.025)
		if first.captor_garfio == null and second.captor_garfio == null: break
	check(g.reenganche_activado and g.recarga_restante <= 3.0 and g.recarga_restante > 2.5 and source.intentos_llegada == 1, "captured success reduces7s to3s once P%d" % team)
	var before: float = g.recarga_restante
	seed(semilla_entre(0.41, 0.64))
	g.actualizar(0.71)
	check(first.is_infected and second.is_infected and source.intentos_llegada == 2, "both captured targets can succeed on separate cadence P%d" % team)
	check(is_equal_approx(g.recarga_restante, before - 0.71) and g.recarga_restante > 0.0, "second success neither stacks nor refreshes Reenganche P%d" % team)
	# A normal unregistered infection never qualifies.
	g.cancelar()
	var ordinary := actor(origin + Vector2(-36, 0), 0)
	g.reenganche_activado = false
	g.cadencia_restante = 0.0
	source.espera_contacto_garfio = 0.0
	seed(semilla_entre(0.0, 0.3))
	check(source.intentar_contagio_garfio(ordinary) and not g.reenganche_activado and is_equal_approx(g.recarga_restante, 7.0), "unregistered ordinary success cannot shorten cooldown P%d" % team)

func invalidacion_entre_ticks(team: int) -> void:
	await limpiar()
	var source := actor_contador(ORIGIN, team)
	mutar(source, ["tendon_reforzado", "gancho_virulento"])
	var target := actor(ORIGIN + Vector2(120, 0), 0)
	var g: Node2D = source.garfio
	check(hook(g, target), "pending capture lifecycle fixture P%d" % team)
	g.cadencia_restante = 0.7
	target.global_position = ORIGIN + Vector2(36, 0)
	g.arrastrar_objetivo(target, 0.01)
	check(g.reserva_objetivo(target) and source.intentos_llegada == 0, "completed capture waits its ordinary cadence P%d" % team)
	target.activar_infeccion(Color.WHITE, 3 - team, false)
	target.curar(false)
	check(not g.reserva_objetivo(target) and not target.has_meta("garfio_captura"), "infection plus cure between ticks cancels capture provenance P%d" % team)
	g.actualizar(0.71)
	check(source.intentos_llegada == 0 and not g.reenganche_activado, "invalidated prey receives no stale capture attempt P%d" % team)
