extends "res://tests/test_simbionte.gd"
const TEAMS = preload("res://scripts/equipos_infeccion.gd")
const ORIGIN := Vector2(656, 568)

func preparar() -> void:
	root.set_meta("patogen_cepas", {1: "exponencial", 2: "exponencial"})
	await fresh()
	host.evento_coloso.set_physics_process(false)
	host.evento_alfa.set_physics_process(false)
	check(host.biomasa_reciclaje == [0, 0], "a new match starts with no biomass")

func rama(team: int, level: int = 1) -> void:
	var mutations: Array[String] = host.mutaciones_p1 if team == 1 else host.mutaciones_p2
	mutations.assign(["reciclaje", "biomasa", "renacimiento"].slice(0, level))
	host.actualizar_mutaciones_existentes(team)

func perder(team: int, healer: int = 0) -> Node2D:
	var bot := bot_at(ORIGIN, team)
	bot.curar(false, healer)
	return bot

func contagiar(source: Node2D) -> Node2D:
	var target := bot_at(ORIGIN + Vector2(32, 0), 0)
	source._contagiar_objetivo(target)
	freeze_bot(target)
	return target

func reserve(team: int) -> int:
	return host.biomasa_reciclaje[team - 1]

func replica_count(team: int) -> int:
	return host.replicas_cian if team == 1 else host.replicas_magenta

func set_replica_count(team: int, count: int) -> void:
	if team == 1:
		host.replicas_cian = count
	else:
		host.replicas_magenta = count

func run() -> void:
	await compras()
	for team in [1, 2]:
		await ciclo(team)
		await evoluciones(team)
	await preparar()
	var clean := bot_at(ORIGIN, 1)
	check(clean.equipos_reciclados == 0, "new match does not inherit recycled-host marks")
	print("RECICLAJE RESULT ", passed, " passed; ", failures, " failed")
	paused = false
	host.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)

func compras() -> void:
	await preparar()
	host.adn_cian = 30
	host.adn_magenta = 30
	for team in [1, 2]:
		var label := " P%d" % team
		check(host.obtener_ramas_jugador(team).size() == 3, "Exponential offers three branches" + label)
		host.interfaz._refresh_mutations()
		var button: Button = (host.panel_cian if team == 1 else host.panel_magenta).get_node("VBoxContainer/BtnInfeccion")
		check(button.visible and button.icon != null and "Reciclaje" in button.text, "third branch has its own visible icon" + label)
		var balance := 30
		for level in range(3):
			key(KEY_3 if team == 1 else KEY_0)
			balance -= [5, 10, 15][level]
			check(host.obtener_adn(team) == balance, "third-branch keyboard purchase charges level %d" % level + label)
			check(host.obtener_meta_biomasa(team) == [5, 4, 3][level], "purchased evolution sets its biomass target" + label)
			host.interfaz._refresh_mutations()
			check(button.icon != null, "evolution has an icon level %d" % level + label)
		check(button.disabled and "RAMA COMPLETA" in button.text, "completed branch disables further purchases" + label)
		key(KEY_3 if team == 1 else KEY_0)
		check(host.obtener_adn(team) == 0, "completed branch cannot charge again" + label)
		host.interfaz.sync(host.contar_infecciones())
		check(host.interfaz.biomass_labels[team - 1].text == "BIOMASA 0/3", "HUD shows the current tier and reserve" + label)
	check(host.interfaz.mutation_icons.size() == 53, "all existing, Garfio and Camaleon mutation icons load")
	host.cepa_cian = "area"
	host.mutaciones_p1.clear()
	host.adn_cian = 30
	host.comprar_mutacion(1, "reciclaje")
	check(host.adn_cian == 30 and host.mutaciones_p1.is_empty(), "other strains cannot buy Recycling")

func ciclo(team: int) -> void:
	await preparar()
	var label := " P%d" % team
	var rival := 3 - team
	perder(team)
	check(reserve(team) == 0, "losses before purchase do not grant biomass" + label)
	rama(team)
	rama(rival)
	var original := perder(team)
	check(reserve(team) == 1 and reserve(rival) == 0, "an original loss credits its owner only" + label)
	original.curar(false)
	original.activar_infeccion(TEAMS.color_equipo(team), team, false)
	freeze_bot(original)
	original.curar(false)
	check(reserve(team) == 1, "repeated cures and reinfections cannot farm the same host" + label)
	original.activar_infeccion(TEAMS.color_equipo(rival), rival, false)
	freeze_bot(original)
	original.curar(false)
	check(reserve(rival) == 1, "the other team has its own once-per-host contribution" + label)
	var copy := bot_at(ORIGIN, team)
	copy.es_replica = true
	copy.curar(false)
	check(reserve(team) == 1, "replica losses never grant biomass" + label)
	# Exercise the real robot pulse: its owner must reach Bot.curar.
	var robot: Node2D = load("res://scenes/robot.tscn").instantiate()
	robot.jugador_invocador = team
	robot.probabilidad_curacion = 1.0
	robot.radio_curacion = 40.0
	host.add_child(robot)
	robot.global_position = ORIGIN
	robot.set_physics_process(false)
	var robot_target := bot_at(ORIGIN, team)
	robot.intentar_curar()
	check(not robot_target.is_infected and reserve(team) == 1, "own robot heals normally without granting biomass" + label)
	robot_target.activar_infeccion(TEAMS.color_equipo(team), team, false)
	freeze_bot(robot_target)
	robot.jugador_invocador = rival
	robot.intentar_curar()
	check(not robot_target.is_infected and reserve(team) == 2, "enemy robot loss grants biomass" + label)
	robot.queue_free()
	var coloso_target := bot_at(ORIGIN, team)
	var rng := RandomNumberGenerator.new()
	check(coloso_target.curar_por_coloso(1.0, 3.0, rng) and reserve(team) == 3, "neutral Colossus cure grants biomass" + label)
	var offensive_target := bot_at(ORIGIN, team)
	freeze_bot(offensive_target)
	check(offensive_target.recibir_curacion_ofensiva(1.0, 2.0, rival) and reserve(team) == 4, "offensive cure grants biomass to the losing team" + label)
	for i in range(4):
		perder(team)
	check(reserve(team) == 5, "reserve stores at most one ready charge" + label)
	host.interfaz.sync(host.contar_infecciones())
	check(host.interfaz.biomass_labels[team - 1].text == "RÉPLICA LISTA", "HUD announces a ready replica" + label)
	var source := bot_at(ORIGIN, team)
	var protected := bot_at(ORIGIN + Vector2(32, 0), 0)
	protected.proteccion_sano_ofensiva = 2.0
	source._contagiar_objetivo(protected)
	check(not protected.is_infected and reserve(team) == 5 and replica_count(team) == 0, "blocked contagion cannot consume the reserve" + label)
	protected.proteccion_sano_ofensiva = 0.0
	protected.proteccion_coloso = 2.0
	source._contagiar_objetivo(protected)
	check(not protected.is_infected and reserve(team) == 5, "Colossus immunity cannot consume the reserve" + label)
	protected.proteccion_coloso = 0.0
	protected.reinfeccion_coloso_sin_recompensa = true
	source._contagiar_objetivo(protected)
	freeze_bot(protected)
	check(protected.is_infected and reserve(team) == 5 and host.obtener_adn(team) == 0, "unrewarded Colossus reinfection cannot trigger Recycling" + label)
	var recovery := bot_at(ORIGIN, 0)
	recovery.infectar_para_recuperar_posesion(team)
	freeze_bot(recovery)
	check(reserve(team) == 5 and replica_count(team) == 0, "possession recovery cannot spend biomass" + label)
	var replica_source := bot_at(ORIGIN, team)
	replica_source.es_replica = true
	contagiar(replica_source)
	check(reserve(team) == 5 and replica_count(team) == 0, "replica contagions do not reproduce replicas" + label)
	check(not host.crear_replicado(replica_source) and replica_count(team) == 0, "replicas cannot use Division's shared creation path either" + label)
	var dna_before: int = host.obtener_adn(team)
	var infections_before: int = host.obtener_contagios_jugador(team)
	var population_before: int = get_nodes_in_group("bots").size()
	var newborn := contagiar(source)
	check(newborn.is_infected and replica_count(team) == 1 and reserve(team) == 0, "next valid original contagion releases one replica" + label)
	check(get_nodes_in_group("bots").size() == population_before + 2, "only target and one extra replica are added" + label)
	check(host.obtener_adn(team) == dna_before + 1 and host.obtener_contagios_jugador(team) == infections_before + 1, "only the normal contagion grants DNA and adaptation credit" + label)
	for bot in get_nodes_in_group("bots"):
		if bot.es_replica and bot.is_infected and bot != replica_source:
			freeze_bot(bot)
			check(bot.efecto_simbionte == null and bot.player_duenio == team and bot.tiene_mutacion("reciclaje"), "extra replica inherits its team's mutations without Symbiont" + label)
			bot.curar(false)
	check(reserve(team) == 0, "curing the generated replica cannot refill its own reserve" + label)
	for i in range(5):
		perder(team)
	set_replica_count(team, 8)
	contagiar(source)
	check(replica_count(team) == 8 and reserve(team) == 5, "shared eight-replica cap preserves the ready charge" + label)
	host.interfaz.sync(host.contar_infecciones())
	check(host.interfaz.biomass_labels[team - 1].text == "CUPO COMPLETO", "HUD explains an exhausted replica quota" + label)
	set_replica_count(team, 1)
	var blocked := bot_at(Vector2(-1000, -1000), 0)
	source._contagiar_objetivo(blocked)
	freeze_bot(blocked)
	check(replica_count(team) == 1 and reserve(team) == 5, "no safe spawn position preserves biomass" + label)
	var crowded_target := bot_at(ORIGIN + Vector2(32, 0), 0)
	for i in range(host.MAX_BOTS_TOTALES - get_nodes_in_group("bots").size()):
		bot_at(ORIGIN, 0)
	source._contagiar_objetivo(crowded_target)
	freeze_bot(crowded_target)
	check(get_nodes_in_group("bots").size() == host.MAX_BOTS_TOTALES and reserve(team) == 5 and replica_count(team) == 1, "global population cap preserves biomass without exceeding 100" + label)

func evoluciones(team: int) -> void:
	await preparar()
	var label := " P%d" % team
	if team == 1:
		host.adn_cian = 30
	else:
		host.adn_magenta = 30
	host.comprar_mutacion(team, "reciclaje")
	for i in range(4):
		perder(team)
	host.comprar_mutacion(team, "reciclaje")
	check(host.obtener_meta_biomasa(team) == 4 and reserve(team) == 4 and replica_count(team) == 0, "Biomass preserves four losses and prepares a charge without spawning" + label)
	var source := bot_at(ORIGIN, team)
	contagiar(source)
	check(replica_count(team) == 1 and reserve(team) == 0, "Biomass releases a replica after four losses" + label)
	for i in range(4):
		perder(team)
	host.comprar_mutacion(team, "reciclaje")
	check(host.obtener_meta_biomasa(team) == 3 and reserve(team) == 3 and replica_count(team) == 1, "Renacimiento caps the preserved charge at three without spawning" + label)
	contagiar(source)
	check(replica_count(team) == 2 and reserve(team) == 0, "Renacimiento releases a replica after three losses" + label)
	# Timer hold, tree pause and match end all block both gain and release.
	host.timer_juego.paused = true
	perder(team)
	check(reserve(team) == 0, "tutorial-held clock blocks biomass gain" + label)
	host.timer_juego.paused = false
	paused = true
	perder(team)
	check(reserve(team) == 0, "tree pause blocks biomass gain" + label)
	paused = false
	for i in range(3):
		perder(team)
	var target := bot_at(ORIGIN, team)
	host.timer_juego.paused = true
	check(not host.intentar_reciclaje(source, target) and reserve(team) == 3, "held clock cannot release a ready charge" + label)
	host.timer_juego.paused = false
	paused = true
	check(not host.intentar_reciclaje(source, target) and reserve(team) == 3, "tree pause cannot release a ready charge" + label)
	paused = false
	host.estado_actual = host.EstadoJuego.FIN
	check(not host.intentar_reciclaje(source, target) and replica_count(team) == 2, "finished match cannot release a ready charge" + label)
	host.biomasa_reciclaje[team - 1] = 0
	perder(team)
	check(reserve(team) == 0, "finished match cannot grant biomass" + label)
