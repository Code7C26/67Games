extends SceneTree
## Partidas automáticas de estrés. No equivalen a validación competitiva humana.
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

func run() -> void:
	Engine.time_scale = 6.0
	await partida(138, "atletico", "area", true)
	await partida(274, "exponencial", "exponencial", false)
	Engine.time_scale = 1.0
	print("COLOSO MATCH RESULT ", passed, " passed; ", failures, " failed")
	quit(0 if failures == 0 else 1)

func partida(semilla: int, cepa1: String, cepa2: String, fusion: bool) -> void:
	paused = false
	seed(semilla)
	root.set_meta("patogen_cepas", {1: cepa1, 2: cepa2})
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	var host: Node = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	host.timer_inicio.stop()
	var evento: Node2D = host.evento_coloso
	evento.azar_aparicion.seed = semilla
	evento.azar_espacial.seed = semilla + 1
	evento.azar_curacion.seed = semilla + 2
	# Escenario de crisis inicial controlada; a continuación la IA juega sola.
	var bots := get_nodes_in_group("bots")
	for i in range(bots.size()):
		if i < 60:
			var equipo := 1 if i % 2 == 0 else 2
			bots[i].activar_infeccion(Color.CYAN if equipo == 1 else Color.MAGENTA, equipo, false)
	for pato in get_nodes_in_group("patos"):
		pato.convertirse_en_fantasma()
		pato.set_physics_process(false)
	host.estado_actual = host.EstadoJuego.FASE_INFECCION
	host.timer_juego.start(120.0)
	host.adn_cian = 100
	host.adn_magenta = 40
	if fusion:
		host.comprar_mutacion(1, "caparazon")
		host.comprar_mutacion(2, "contagio_cadena")
	else:
		for equipo in [1, 2]:
			host.comprar_mutacion(equipo, "adaptacion")
			host.comprar_mutacion(equipo, "division_celular")
	var deadline := Time.get_ticks_msec() + 45000
	while not host.capullos_colocados and Time.get_ticks_msec() < deadline:
		await physics_frame
	if fusion and host.capullos_colocados:
		for _i in range(12):
			host.cooldown_simbionte[0] = 0.0
			host.invertir_simbionte(1)
	host.crear_robot(2, bots[0].global_position)
	host.crear_zona_temperatura(2, "calor", bots[1].global_position)
	var registros: Array[Dictionary] = []
	evento.intento_realizado.connect(func(chance: float, exito: bool): registros.append({"segundo": evento.tiempo_partida, "chance": chance, "exito": exito, "apariciones": evento.apariciones}))
	var cuentas_validas := true
	var max_activos := 0
	var min_sanos := 65
	var max_total := 65
	var curaciones: Dictionary = {}
	var presupuestos_validos := true
	while host.estado_actual != host.EstadoJuego.FIN and Time.get_ticks_msec() < deadline:
		await process_frame
		var stats: Dictionary = host.contar_infecciones()
		cuentas_validas = cuentas_validas and stats.total == stats.sanos + stats.blue + stats.magenta
		cuentas_validas = cuentas_validas and stats.total == 65 + host.replicas_cian + host.replicas_magenta
		min_sanos = mini(min_sanos, stats.sanos)
		max_total = maxi(max_total, stats.total)
		max_activos = maxi(max_activos, get_nodes_in_group("colosos_antivirales").size())
		if is_instance_valid(evento.coloso):
			curaciones[evento.apariciones] = evento.coloso.curaciones
			presupuestos_validos = presupuestos_validos and evento.coloso.curaciones <= 12
	var numero_apariciones: int = evento.apariciones
	check(host.estado_actual == host.EstadoJuego.FIN and paused, "120-second automatic match reaches normal game over: " + str(semilla))
	check(cuentas_validas and max_total <= 81, "population accounting stays exact through infections, cures and replicas: " + str(semilla))
	check(max_activos <= 1 and numero_apariciones <= 2 and presupuestos_validos, "automatic match respects concurrency, appearance and healing caps: " + str(semilla))
	var probabilidades_validas := true
	for registro in registros:
		probabilidades_validas = probabilidades_validas and is_equal_approx(registro.chance, 0.60 if registro.apariciones == 0 else 0.40)
		probabilidades_validas = probabilidades_validas and registro.segundo >= 34.9
	check(probabilidades_validas, "automatic rolls respect first-crisis grace and actual appearance history: " + str(semilla))
	check(evento.estado == evento.Estado.FINALIZADO and evento.coloso == null, "automatic match finalization clears coloso: " + str(semilla))
	print("SIMULATION seed=", semilla, " strains=", cepa1, "/", cepa2, " min_healthy=", min_sanos, " max_population=", max_total, " appearances=", numero_apariciones, " treatments_seen=", curaciones, " rolls=", registros)
	paused = false
	host.queue_free()
	await process_frame
	await process_frame
