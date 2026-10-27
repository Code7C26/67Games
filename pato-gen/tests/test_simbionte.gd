extends SceneTree
## Run headless with --script res://tests/test_simbionte.gd -- --onboarding-test
const WALKER = preload("res://scenes/simbionte.tscn")
const RADIAL = preload("res://scripts/curacion_radial.gd")
var host: Node
var passed := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func fresh() -> void:
	paused = false
	if is_instance_valid(host):
		host.queue_free()
		await process_frame
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	host.timer_inicio.stop()
	host.set_process(false)
	for bot in host.get_node("Bots").get_children():
		bot.queue_free()
	await physics_frame
	await physics_frame
	host.estado_actual = host.EstadoJuego.FASE_INFECCION
	host.timer_juego.start(120)
	for duck in get_nodes_in_group("patos"):
		duck.set_physics_process(false)
		duck.convertirse_en_fantasma()
	var deadline := Time.get_ticks_msec() + 5000
	while not host.navegacion_simbionte.lista and Time.get_ticks_msec() < deadline:
		await physics_frame
	check(host.navegacion_simbionte.lista, "navigation grid builds from the real Shopping collisions")

func bot_at(point: Vector2, team: int = 1) -> Node2D:
	# Load after autoload initialization, as in the existing SceneTree tests.
	var bot = load("res://scenes/Bot.tscn").instantiate()
	host.get_node("Bots").add_child(bot)
	bot.global_position = point
	bot.set_physics_process(false)
	bot.get_node("TimerCambioRumbo").stop()
	if team != 0:
		bot.activar_infeccion(Color.CYAN if team == 1 else Color.MAGENTA, team, false)
		bot.timer_contagio.stop()
		bot.timer_curacion.stop()
	return bot

func key(code: Key, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.echo = echo
	host._unhandled_input(event)

func walker_at(point: Vector2, team: int = 1) -> Node2D:
	var walker = WALKER.instantiate()
	walker.equipo = team
	walker.mundo = host
	walker.navegacion = host.navegacion_simbionte
	walker.position = point
	host.add_child(walker)
	return walker

func freeze_bot(bot: Node2D) -> void:
	bot.timer_contagio.stop()
	bot.timer_curacion.stop()
	bot.tiempo_escudo = 0.0
	bot.blindaje_restante = 0.0

func run() -> void:
	await fresh()
	host.adn_cian = 60
	host.adn_magenta = 60
	host.estado_actual = host.EstadoJuego.FASE_PATOS
	check(not host.invertir_simbionte(1) and host.adn_cian == 60, "preparation cannot invest")
	host.estado_actual = host.EstadoJuego.FASE_INFECCION
	check(not host.invertir_simbionte(0) and not host.invertir_simbionte(3), "invalid teams cannot spend")
	host.timer_juego.paused = true
	check(not host.invertir_simbionte(1), "tutorial-held match clock blocks investment")
	host.timer_juego.paused = false
	paused = true
	check(not host.invertir_simbionte(1), "tree pause blocks direct investment calls")
	paused = false
	host.adn_cian = 4
	check(not host.invertir_simbionte(1) and host.adn_cian == 4 and host.cooldown_simbionte[0] == 0, "insufficient funds start no cooldown")
	host.adn_cian = 60
	key(KEY_Q, true)
	check(host.inversion_simbionte[0] == 0, "keyboard echo never buys")
	key(KEY_Q)
	key(KEY_U)
	check(host.adn_cian == 55 and host.adn_magenta == 55 and host.inversion_simbionte == [5, 5], "Q/U spend exactly 5 from their own balance")
	check(not host.invertir_simbionte(1) and host.adn_cian == 55, "repeated input inside cooldown cannot double-charge")
	await create_timer(1.25).timeout
	check(not host.invertir_simbionte(1) and host.adn_cian == 55, "payment before 1.5 seconds remains blocked")
	await create_timer(0.35).timeout
	check(host.invertir_simbionte(1) and host.adn_cian == 50, "real 1.5 second cooldown expires")
	check(host.cooldown_simbionte[1] == 0.0, "one player's payment does not restart the other's cooldown")
	for _i in range(10):
		host._physics_process(1.5)
		check(host.invertir_simbionte(1), "remaining valid installment accepted")
	check(host.ganador_simbionte == 1 and host.inversion_simbionte[0] == 60 and host.adn_cian == 0, "twelve installments hatch once at exactly 60 ADN")
	check(not host.invertir_simbionte(2) and host.adn_magenta == 55, "loser cannot spend or recover the invested 5")
	check(not host.invertir_simbionte(1), "winner cannot buy another symbiont")
	await physics_frame
	await physics_frame
	check(host.get_node("Simbiontes").get_child_count() == 0 and get_nodes_in_group("simbiontes").size() == 1, "rival cocoon destroyed and only one traveller spawned")
	check(get_nodes_in_group("bots").is_empty() and host.contagios_cian == 0, "hatching adds neither a bot nor free DNA/contagions")
	var traveller = host.simbionte
	traveller._physics_process(21.0)
	check(is_instance_valid(traveller) and traveller.objetivo == null, "no allies: waits beyond 20s without consuming fusion lifetime")
	# Keep target offsets in a known clear corridor, regardless of the random hatch.
	traveller.global_position = Vector2(656, 568)
	var origin: Vector2 = traveller.global_position
	var rival := bot_at(origin + Vector2(25, 0), 2)
	var healthy := bot_at(origin + Vector2(40, 0), 0)
	var near := bot_at(origin + Vector2(130, 0), 1)
	var far := bot_at(origin + Vector2(240, 0), 1)
	traveller.buscar_objetivo()
	check(traveller.objetivo == near, "chooses nearest infected ally, ignores closer rival and human")
	check(not traveller.intentar_fusion() and near.efecto_simbionte == null, "selection alone does not fuse")
	near.curar(false)
	traveller._physics_process(0.0)
	check(traveller.objetivo == far, "healed target is replaced before contact")
	far.curar(false)
	far.activar_infeccion(Color.MAGENTA, 2, false)
	freeze_bot(far)
	traveller._physics_process(0.0)
	check(traveller.objetivo == null, "target switched to rival is rejected")
	near.activar_infeccion(Color.CYAN, 1, false)
	freeze_bot(near)
	traveller.buscar_objetivo()
	near.queue_free()
	await physics_frame
	await physics_frame
	check(traveller.objetivo == null, "deleted target is safe")
	for body in [rival, healthy, far]:
		body.queue_free()
	# This is a genuine walking/contact test in the unchanged Shopping.
	var target := bot_at(origin + Vector2(160, 0), 1)
	var start := Time.get_ticks_msec()
	while is_instance_valid(traveller) and target.efecto_simbionte == null and Time.get_ticks_msec() - start < 8000:
		await physics_frame
	check(is_instance_valid(target.efecto_simbionte), "traveller physically walks to and fuses with its target")
	if is_instance_valid(target.efecto_simbionte):
		check(target.efecto_simbionte.restante > 19.0, "20s starts at contact, not at hatching")
		check(host.adn_cian == 0 and host.contagios_cian == 0, "fusion itself grants no ADN or contagions")
	await _effects(target)
	await _routes_and_contact()
	await _race_and_cleanup()
	print("SIMBIONTE RESULT ", passed, " passed; ", failures, " failed")
	paused = false
	if is_instance_valid(host):
		host.queue_free()
	await process_frame
	await process_frame
	# Explicitly stop audio before the headless driver shuts down.
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer:
			player.stop()
	await process_frame
	quit(0 if failures == 0 else 1)

func _effects(target: Node2D) -> void:
	if not is_instance_valid(target.efecto_simbionte):
		check(target.aplicar_simbionte(host, 1), "effect fixture can attach")
	var effect = target.efecto_simbionte
	effect.set_physics_process(false)
	check(not target.aplicar_simbionte(host, 1), "second application cannot reset or stack fusion")
	check(is_equal_approx(target.obtener_multiplicador_velocidad(), 1.35), "fusion speed is a separate 35 percent multiplier")
	effect.avanzar(7.0)
	var duck = host.get_node("Patos/Pato")
	duck.intentar_poseer_infectado()
	check(duck.bot_poseido == target and target.controlado_por_jugador and is_equal_approx(effect.restante, 13), "existing possession selects fused bot without resetting its clock")
	duck.finalizar_posesion()
	check(is_equal_approx(effect.restante, 13), "ending possession does not change fusion lifetime")
	host.adn_cian = 20
	host.comprar_mutacion(1, "fiebre")
	check(target.tiene_mutacion("fiebre") and target.efecto_simbionte == effect and host.adn_cian == 15, "real mutation purchase persists while fused and costs once")
	var heat = load("res://scenes/zona_temperatura.tscn").instantiate()
	heat.tipo = ZonaTemperatura.TipoTemperatura.CALOR
	host.add_child(heat)
	heat.aplicar_efecto(target)
	check(is_equal_approx(target.multiplicador_velocidad_temp, 1.3) and is_equal_approx(target.probabilidad_curacion, 0.65), "heat remains an independent modifier")
	var other := bot_at(target.global_position + Vector2(45, 0), 2)
	var ally := bot_at(target.global_position + Vector2(-45, 0), 1)
	var human := bot_at(target.global_position + Vector2(0, 35), 0)
	var distant := bot_at(target.global_position + Vector2(400, 0), 2)
	var before := [host.adn_cian, host.adn_magenta, host.contagios_cian, host.contagios_magenta]
	RADIAL.aplicar(effect, 90, 1.0, 1)
	check(not other.is_infected and ally.is_infected and target.is_infected and not human.is_infected and distant.is_infected, "aura heals only infected rivals within radius")
	check(before == [host.adn_cian, host.adn_magenta, host.contagios_cian, host.contagios_magenta], "aura creates no DNA and never converts rivals into allies")
	other.infectar(Color.CYAN, 1)
	freeze_bot(other)
	check(host.adn_cian == before[0] + 1, "a later ordinary infection retains its one existing ADN reward")
	# Expire across the boundary while a rival is in range: no final extra pulse.
	var boundary_rival := bot_at(target.global_position + Vector2(0, 50), 2)
	effect.chance_aura = 1.0
	effect.hasta_pulso = 0.0
	effect.avanzar(13.0)
	check(target.efecto_simbionte == null and boundary_rival.is_infected, "exact expiry removes aura before a queued pulse")
	check(target.tiene_mutacion("fiebre") and is_equal_approx(target.obtener_multiplicador_velocidad(), 1.0) and is_equal_approx(target.multiplicador_velocidad_temp, 1.3), "expiry preserves purchased mutation and heat, removes only fusion speed")
	await process_frame
	check(not is_instance_valid(effect), "expired effect is actually freed")
	heat.queue_free()
	target.mutaciones.clear()
	target.probabilidad_curacion = 1.0
	freeze_bot(target)
	check(target.aplicar_simbionte(host, 1), "new fixture effect attaches")
	effect = target.efecto_simbionte
	effect.set_physics_process(false)
	effect.factor_curacion = 0.0
	target._intentar_curacion()
	target.recibir_curacion_ofensiva(1.0, 2.0)
	target.curar_por_robot(1.0)
	check(target.is_infected, "resistance reaches natural, offensive and robot healing paths")
	effect.factor_curacion = 0.5
	check(is_equal_approx(target.multiplicador_curacion_simbionte(), 0.5), "default resistance halves probability, not duration")
	# The normal robot path still heals both teams and never grants currency.
	effect.factor_curacion = 1.0
	duck.iniciar_posesion(target)
	RADIAL.aplicar(target, 90, 1.0)
	duck._physics_process(0.01)
	check(not target.is_infected and not ally.is_infected and not boundary_rival.is_infected, "robot retains healing of both teams")
	check(target.efecto_simbionte == null and duck.bot_poseido == null and not target.controlado_por_jugador, "healed host loses aura and releases possession safely")
	# A real timer measurement with an accelerated engine; no direct timer edits.
	var timed := bot_at(Vector2(592, 592), 1)
	timed.aplicar_simbionte(host, 1)
	var timed_effect = timed.efecto_simbionte
	timed_effect.chance_aura = 0.0
	Engine.time_scale = 10.0
	var elapsed := 0.0
	while is_instance_valid(timed.efecto_simbionte) and elapsed < 21.0:
		await physics_frame
		elapsed += host.get_physics_process_delta_time()
	Engine.time_scale = 1.0
	check(elapsed >= 19.8 and elapsed <= 20.3 and timed.efecto_simbionte == null, "real physics clock expires the fusion at 20 game seconds")
	# Replication uses the existing economy path and must not copy the effect.
	host.cepa_cian = "exponencial"
	var donor := bot_at(Vector2(720, 592), 1)
	donor.aplicar_simbionte(host, 1)
	var dna_before: int = host.adn_cian
	var contagions_before: int = host.contagios_cian
	check(host.crear_replicado(donor), "fused exponential bot can still use existing replication")
	var replica = host.get_node("Bots").get_children().back()
	freeze_bot(replica)
	check(replica.es_replica and replica.efecto_simbionte == null and host.adn_cian == dna_before and host.contagios_cian == contagions_before, "replica inherits neither fusion nor a free DNA reward")

func _routes_and_contact() -> void:
	await fresh()
	var nav = host.navegacion_simbionte
	# Real store entrances, furniture, cinema and both player spawns.
	var origin := Vector2(592, 592)
	var destinations: Array[Vector2] = [Vector2(1360, 592)]
	for marker in get_nodes_in_group("mapa_destination"):
		if host.is_ancestor_of(marker):
			destinations.append(marker.global_position)
	for destination in destinations:
		var path: PackedVector2Array = nav.ruta(origin, destination)
		print("ROUTE ", origin, " -> ", destination, " points ", path.size())
		check(not path.is_empty(), "real map route exists to " + str(destination))
		var previous := origin
		var clear := not path.is_empty()
		for point in path:
			clear = clear and nav.segmento_libre(previous, point)
			previous = point
		check(clear, "route fits body without crossing walls to " + str(destination))
	# Follow a non-straight path with real physics, not only a graph assertion.
	var across := bot_at(Vector2(1360, 592), 1)
	var walking := walker_at(origin)
	Engine.time_scale = 5.0
	var deadline := Time.get_ticks_msec() + 6000
	while is_instance_valid(walking) and across.efecto_simbionte == null and Time.get_ticks_msec() < deadline:
		await physics_frame
	Engine.time_scale = 1.0
	check(is_instance_valid(across.efecto_simbionte), "real traveller follows corners across the mall and reaches contact")
	if is_instance_valid(walking):
		walking.queue_free()
	across.queue_free()
	await physics_frame
	await physics_frame
	# Synthetic thin wall in an open corridor: contact shape overlap is insufficient.
	var wall := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2, 80)
	collision.shape = shape
	wall.add_child(collision)
	wall.position = Vector2(600, 592)
	host.add_child(wall)
	var ally := bot_at(Vector2(610, 592), 1)
	var traveller := walker_at(Vector2(589, 592))
	traveller.set_physics_process(false)
	await physics_frame
	await physics_frame
	traveller.buscar_objetivo()
	check(traveller.contacto.overlaps_body(ally), "thin-wall fixture actually overlaps contact shapes")
	check(not traveller.intentar_fusion() and ally.efecto_simbionte == null, "physical barrier prevents fusion across a thin wall")
	wall.queue_free()
	traveller.global_position = ally.global_position
	await physics_frame
	await physics_frame
	check(traveller.intentar_fusion(), "actual overlap without wall fuses")
	check(not traveller.intentar_fusion(), "contact is committed only once")
	var effect = ally.efecto_simbionte
	var before: float = effect.restante
	paused = true
	await create_timer(0.2, true).timeout
	check(is_equal_approx(before, effect.restante), "global pause freezes fusion lifetime")
	paused = false
	host.timer_juego.paused = true
	before = effect.restante
	await create_timer(0.2).timeout
	check(is_equal_approx(before, effect.restante), "tutorial clock hold also freezes fusion lifetime")
	host.timer_juego.paused = false
	ally.curar(false)
	ally.activar_infeccion(Color.MAGENTA, 2, false)
	freeze_bot(ally)
	check(ally.efecto_simbionte == null, "reinfection never transfers the old symbiont to the rival")

func _race_and_cleanup() -> void:
	await fresh()
	host.adn_cian = 60
	host.adn_magenta = 60
	for _i in range(11):
		host.invertir_simbionte(1)
		host.invertir_simbionte(2)
		host._physics_process(1.5)
	var magenta_wins: bool = host.invertir_simbionte(2)
	var cyan_after: bool = host.invertir_simbionte(1)
	check(magenta_wins and not cyan_after and host.ganador_simbionte == 2, "same-frame final payments choose first accepted request, including magenta")
	check(host.adn_magenta == 0 and host.adn_cian == 5 and host.inversion_simbionte == [55, 60], "loser keeps only unspent balance, no refund and no extra debit")
	# The random hatch itself is covered by test_simbionte_balance.
	host.simbionte.global_position = Vector2(1296, 568)
	var ally := bot_at(Vector2(1196, 568), 2)
	var deadline := Time.get_ticks_msec() + 5000
	while ally.efecto_simbionte == null and Time.get_ticks_msec() < deadline:
		await physics_frame
	check(is_instance_valid(ally.efecto_simbionte), "magenta winner also walks and fuses with its own ally")
	if not is_instance_valid(ally.efecto_simbionte):
		return
	var effect = ally.efecto_simbionte
	host._on_timer_juego_timeout()
	check(paused and ally.efecto_simbionte == null and not effect.activo, "game over removes active powers before pausing")
	check(not host.invertir_simbionte(1), "finished match rejects investment")
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	host.game_over_screen._on_reiniciar_button_pressed()
	await process_frame
	await process_frame
	host = current_scene
	host.timer_inicio.stop()
	check(not paused and is_instance_valid(host) and host.scene_file_path.ends_with("Shopping.tscn"), "real GameOver restart reloads Shopping and unpauses")
	check(host.inversion_simbionte == [0, 0] and host.cooldown_simbionte == [0.0, 0.0] and host.ganador_simbionte == 0 and host.adn_cian == 0 and host.adn_magenta == 0, "new scene resets the entire race and economy")
	check(get_nodes_in_group("simbiontes").is_empty() and host.get_node("Simbiontes").get_child_count() == 2, "scene change frees old traveller/effect and creates two fresh cocoons")
