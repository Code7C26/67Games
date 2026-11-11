extends "res://tests/test_simbionte.gd"
## Real Bot bodies, the two production perception paths and ordinary infection rules.
const READABILITY = preload("res://scripts/npc_readability.gd")
const ORIGIN := Vector2(656, 568)
const APPROVED_HASHES := {
	"camaleon_abajo.png": "313edf4327d62a43c6486b52d6d7b8e42ec36602af96b1465e9a7ecf6334e223",
	"camaleon_arriba.png": "94503268c090a10ed9218a3b50061405c6611ba9147197cd66049ba3ba143fa0",
	"camaleon_derecha.png": "09b63314b59eef620dcef52e370a5d6e885a75ac543549206d21cffa460b1108",
	"camaleon_izquierda.png": "63582befcc81fa8081f18cc92b02a893a197487dc32f5c619c24531791b0f2db",
	"camaleon_camuflado.png": "3e7275096c15547c1082c3a55eca61660f529de13a27e721353622ec845826ba",
	"camaleon_emboscada.png": "f29b5635e1f20ca373d09a68b39064c0344c13cd5140efc33ee3b410050355c8",
	"camaleon.aseprite": "284f7977840040b2f0e7a474e4f57fb142432881ca67ff6f5e4ec8db02c1bb68"
}

func preparar() -> void:
	root.set_meta("patogen_cepas", {1: "camaleon", 2: "camaleon"})
	await fresh()
	host.set_physics_process(false)
	host.evento_coloso.set_physics_process(false)
	host.evento_alfa.set_physics_process(false)

func limpiar() -> void:
	for bot in get_nodes_in_group("bots"): bot.queue_free()
	await physics_frame
	await physics_frame

func actor(point: Vector2, team: int = 1) -> Node2D:
	var bot: Node2D = bot_at(point, team)
	freeze_bot(bot)
	bot.incubacion_contagio = 0.0
	bot.feedback_restante = 0.0
	if team != 0 and is_instance_valid(bot.camaleon): bot.camaleon.actualizar(0.0)
	return bot

func run() -> void:
	seed(937)
	await preparar()
	verificar_assets()
	await estados_y_escala()
	await vision_local()
	await revelacion_y_recuperacion()
	await pausa_y_final()
	await contagio_y_protecciones()
	await curacion_y_especiales()
	await revelacion_sin_retraso()
	await final_real()
	await percepcion_navegada()
	await mapas()
	print("CAMALEON RESULT ", passed, " passed; ", failures, " failed")
	paused = false
	if is_instance_valid(host): host.queue_free()
	await process_frame
	await process_frame
	load("res://scripts/camaleon_arte.gd").limpiar_cache()
	READABILITY.textures.clear()
	var bot_script: Script = load("res://scripts/Bot.gd")
	bot_script.frames_infectados_cache.clear()
	root.get_node("AudioManager").detener_musica()
	quit(0 if failures == 0 else 1)

func verificar_assets() -> void:
	for file in APPROVED_HASHES:
		check(FileAccess.get_sha256("res://assets/camaleon/" + file) == APPROVED_HASHES[file], "approved artwork remains byte-identical: " + file)
	check(FileAccess.get_sha256("res://assets/camaleon/retrato.png") == APPROVED_HASHES["camaleon_abajo.png"], "selector portrait uses the approved normal sprite")
	check(ResourceLoader.exists("res://resources/camaleon_config.tres"), "Camaleon has an editable balance resource")

func estados_y_escala() -> void:
	for team in [1, 2]:
		await limpiar()
		var source := actor(ORIGIN, team)
		var ability: Node2D = source.camaleon
		check(is_instance_valid(ability) and source.cepa == "camaleon", "infection creates Camaleon's component P%d" % team)
		check(ability.camuflado, "AI conceals automatically after incubation P%d" % team)
		check(is_equal_approx(source.speed, source.velocidad_base) and is_equal_approx(source.probabilidad_contagio, source.CONTAGIO_BASE) and is_equal_approx(source.probabilidad_curacion, source.CURACION_BASE), "base speed, contagion and cure resistance remain ordinary P%d" % team)
		check(is_equal_approx(ability.factor_deteccion(), 0.30) and is_equal_approx(ability.recarga(), 5.0) and is_zero_approx(ability.bono_ataque_sorpresa()) and is_zero_approx(ability.tiempo_desvanecimiento()), "initial detection and cooldown remain ordinary without purchased mutation bonuses P%d" % team)
		var body: CapsuleShape2D = source.get_node("CollisionShape2D").shape
		var vision: CircleShape2D = source.get_node("AreaVision/CollisionShape2D").shape
		check(is_equal_approx(body.radius, 11.5) and is_equal_approx(body.height, 32.0) and is_equal_approx(vision.radius, 53.0), "camouflage changes neither the physical capsule nor the shared vision shape P%d" % team)
		var team_color: Color = source.material_borde_infeccion.get_shader_parameter("color_borde")
		ability.revelar("prueba_visual")
		ability.actualizar(0.25)
		check(source.material_borde_infeccion.get_shader_parameter("borde_activo") and source.material_borde_infeccion.get_shader_parameter("color_borde") == team_color, "reveal preserves the individual team outline P%d" % team)
		check(source.animated_sprite.self_modulate.a >= 0.65 and source.modulate.a >= 0.65, "the body never becomes invisible P%d" % team)
		ability.actualizar(5.0)
		check(ability.camuflado and source.material_borde_infeccion.get_shader_parameter("color_borde") == team_color, "concealment retains cyan or magenta identification P%d" % team)

func vision_local() -> void:
	for team in [1, 2]:
		await limpiar()
		var source := actor(ORIGIN, team)
		var observer := actor(ORIGIN + Vector2(50, 0), 0)
		await physics_frame
		await physics_frame
		check(observer.area_vision.overlaps_body(source), "local fixture really overlaps AreaVision P%d" % team)
		check(observer.obtener_amenaza_cercana() == null, "AreaVision cannot bypass camouflage at fifty pixels P%d" % team)
		observer.global_position = ORIGIN + Vector2(100, 0)
		check(not observer.percibe_infectado(source, 240.0), "camouflaged source is ignored beyond thirty percent of route perception P%d" % team)
		observer.global_position = ORIGIN + Vector2(50, 0)
		# The local sense uses its own 53-pixel range and cannot shrink below the safety floor.
		check(not observer.percibe_infectado(source, 53.0), "local camouflage range floors at thirty-five pixels P%d" % team)
		observer.global_position = ORIGIN + Vector2(34, 0)
		check(observer.percibe_infectado(source, 53.0) and not source.camaleon.camuflado, "a practically touching human detects and reveals Camaleon immediately P%d" % team)
		observer.global_position = ORIGIN + Vector2(50, 0)
		await physics_frame
		await physics_frame
		check(observer.obtener_amenaza_cercana() == source, "the same AreaVision sees revealed Camaleon normally P%d" % team)
		for strain in ["atletico", "area", "exponencial", "garfio", "alfa"]:
			var empty: Array[String] = []
			source.aplicar_mutaciones(empty, strain)
			check(observer.obtener_amenaza_cercana() == source, "local perception of the existing strain remains unchanged: " + strain)

func revelacion_y_recuperacion() -> void:
	await limpiar()
	var source := actor(ORIGIN)
	var ability: Node2D = source.camaleon
	ability.revelar("intento_contagio")
	check(not ability.camuflado and is_equal_approx(ability.recarga_restante, 5.0), "revealing starts the full five-second cooldown")
	ability.actualizar(4.99)
	check(not ability.camuflado and ability.recarga_restante > 0.0, "Camaleon stays revealed before the cooldown boundary")
	ability.actualizar(0.02)
	check(ability.camuflado, "an AI Camaleon automatically recovers after the full cooldown")
	var observer := actor(ORIGIN + Vector2(34, 0), 0)
	await physics_frame
	await physics_frame
	ability.actualizar(0.0)
	check(not ability.camuflado, "automatic proximity scanning breaks concealment without a perception call")
	ability.actualizar(8.0)
	check(not ability.camuflado and not ability.puede_camuflarse(), "remaining next to a human prevents permanent concealment")
	observer.global_position += Vector2(150, 0)
	ability.actualizar(5.01)
	check(ability.camuflado, "moving away from touching humans permits concealment again")
	source.activar_control_jugador(1)
	ability.revelar("habilidad")
	ability.actualizar(5.01)
	check(not ability.camuflado and ability.puede_camuflarse(), "a possessed host waits for a manual action once the cooldown expires")
	check(ability.activar_manual() and ability.camuflado, "the possessed host can explicitly activate its ready camouflage")
	source.desactivar_control_jugador()
	ability.revelar("habilidad")
	ability.actualizar(5.01)
	check(ability.camuflado, "returning the host to AI restores automatic recovery")

func pausa_y_final() -> void:
	await limpiar()
	var source := actor(ORIGIN)
	var ability: Node2D = source.camaleon
	ability.revelar("prueba")
	var before: float = ability.recarga_restante
	host.timer_juego.paused = true
	ability.actualizar(10.0)
	check(is_equal_approx(ability.recarga_restante, before) and not ability.camuflado, "tutorial clock hold freezes camouflage recovery")
	host.timer_juego.paused = false
	paused = true
	ability.actualizar(10.0)
	check(is_equal_approx(ability.recarga_restante, before) and not ability.camuflado, "global pause freezes even a direct component update")
	paused = false
	host.estado_actual = host.EstadoJuego.FIN
	ability.actualizar(10.0)
	check(not ability.camuflado and not ability.puede_camuflarse(), "a finished match cannot reactivate camouflage")
	host.estado_actual = host.EstadoJuego.FASE_INFECCION

func contagio_y_protecciones() -> void:
	for team in [1, 2]:
		await limpiar()
		var source := actor(ORIGIN, team)
		var target := actor(ORIGIN + Vector2(42, 0), 0)
		await physics_frame
		await physics_frame
		check(source.area_infeccion.overlaps_body(target), "contact fixture overlaps the real infection area P%d" % team)
		source.probabilidad_contagio = 0.0
		var before: int = host.obtener_adn(team)
		var counted: int = host.obtener_contagios_jugador(team)
		source._intentar_contagio_area()
		check(not source.camaleon.camuflado and not target.is_infected, "an unsuccessful infection attempt still reveals Camaleon P%d" % team)
		check(host.obtener_adn(team) == before and host.obtener_contagios_jugador(team) == counted, "a failed ambush awards no DNA or contagions P%d" % team)
		source.probabilidad_contagio = 1.0
		for protection in ["proteccion_coloso", "proteccion_sano_ofensiva"]:
			target.set(protection, 2.0)
			for _i in 8: source._intentar_contagio_area()
			check(not target.is_infected and host.obtener_adn(team) == before, "ambush respects healthy immunity " + protection + " P%d" % team)
			target.set(protection, 0.0)
		seed(937)
		for _i in 8:
			if target.is_infected: break
			source._intentar_contagio_area()
		check(target.is_infected and target.cepa == "camaleon" and target.player_duenio == team and is_instance_valid(target.camaleon), "ordinary infection transmits the correct strain and owner P%d" % team)
		check(host.obtener_adn(team) == before + 1 and host.obtener_contagios_jugador(team) == counted + 1, "a successful ambush gives exactly one ordinary reward P%d" % team)
		for _i in 4: source._intentar_contagio_area()
		check(host.obtener_adn(team) == before + 1 and get_nodes_in_group("bots").size() == 2, "repeat ticks add neither duplicate rewards nor replicas P%d" % team)
		check(target.incubacion_contagio > 0.0 and target.tiempo_escudo > 0.0, "new infection keeps incubation and the normal cure shield P%d" % team)

func curacion_y_especiales() -> void:
	for team in [1, 2]:
		await limpiar()
		var source := actor(ORIGIN, team)
		source.tiempo_escudo = 2.0
		check(not source.recibir_curacion_ofensiva(1.0, 1.0, 3 - team) and source.is_infected, "Camaleon preserves the infected-host shield P%d" % team)
		source.tiempo_escudo = 0.0
		check(source.aplicar_simbionte(host, team), "the existing Symbiont can fuse with Camaleon P%d" % team)
		source.camaleon.actualizar(0.0)
		check(not source.camaleon.camuflado and not source.camaleon.puede_camuflarse(), "the visible Symbiont aura is incompatible with stealth P%d" % team)
		check(is_equal_approx(source.obtener_multiplicador_velocidad(), host.velocidad_fusion) and is_equal_approx(source.multiplicador_curacion_simbionte(), host.curacion_fusion), "revealing does not remove the existing Symbiont bonuses P%d" % team)
		source.quitar_simbionte()
		source.camaleon.actualizar(5.01)
		check(source.camaleon.camuflado, "camouflage can recover once the visible aura ends P%d" % team)
		check(source.curar_por_robot(1.0) and not source.is_infected and source.camaleon == null and source.cepa.is_empty(), "robot cure removes camouflage and restores a healthy guest P%d" % team)
		source.activar_infeccion(Color.CYAN if team == 1 else Color.MAGENTA, team, false)
		source.incubacion_contagio = 0.0
		freeze_bot(source)
		source.camaleon.actualizar(0.0)
		var random := RandomNumberGenerator.new()
		random.seed = 937
		check(source.curar_por_coloso(1.0, 3.0, random) and source.proteccion_coloso > 0.0 and source.camaleon == null, "Colossus cure retains its reinfection protection P%d" % team)
		source.infectar(Color.CYAN if team == 1 else Color.MAGENTA, team)
		check(not source.is_infected and source.camaleon == null, "protected cured Camaleon cannot recreate its ability P%d" % team)
		source.proteccion_coloso = 0.0
		source.activar_infeccion(Color.CYAN if team == 1 else Color.MAGENTA, team, false)
		check(is_instance_valid(source.camaleon), "later valid reinfection creates a fresh component P%d" % team)
		source.queue_free()
		await physics_frame
		await physics_frame
		check(get_nodes_in_group("bots").is_empty(), "deletion leaves no orphaned bot or stealth target P%d" % team)

func revelacion_sin_retraso() -> void:
	await limpiar()
	var source := actor(ORIGIN)
	var upgrades: Array[String] = ["ataque_sorpresa", "emboscada_viral", "golpe_furtivo"]
	source.aplicar_mutaciones(upgrades, "camaleon")
	var ability: Node2D = source.camaleon
	var alerted := actor(ORIGIN + Vector2(70, 0), 0)
	var observer := actor(ORIGIN + Vector2(100, 0), 0)
	check(alerted.percibe_infectado(source, 240.0), "a human inside the camouflage range is already alert before reveal")
	check(not observer.percibe_infectado(source, 240.0), "the replacement attack mutation does not expose a camouflaged source outside its detection range")
	ability.revelar("intento_contagio")
	check(alerted.percibe_infectado(source, 240.0) and observer.percibe_infectado(source, 240.0), "revealed Camaleon is detected immediately by both new and already alerted humans")
	ability.actualizar(0.10)
	ability.revelar("intento_contagio")
	check(observer.percibe_infectado(source, 240.0), "repeated actions while revealed never introduce the removed reaction delay")
	ability.actualizar(5.0)
	ability.revelar("prueba")
	observer.global_position = ORIGIN + Vector2(35, 0)
	check(observer.percibe_infectado(source, 240.0), "even maximum surprise-attack upgrades never delay a touching human's reaction")

func final_real() -> void:
	await limpiar()
	var source := actor(ORIGIN)
	source.camaleon.actualizar(0.35)
	check(source.camaleon.camuflado, "the real match-ending fixture starts with a camouflaged host")
	host._on_timer_juego_timeout()
	check(paused and host.estado_actual == host.EstadoJuego.FIN and not source.camaleon.camuflado, "the actual match timer cancels camouflage synchronously before the paused result screen")
	check(is_zero_approx(float(source.material_borde_infeccion.get_shader_parameter("camuflaje"))), "the actual match ending also clears the camouflage visual")

func cargar_mapa(map_name: String) -> void:
	paused = false
	if is_instance_valid(host):
		host.queue_free()
		await process_frame
		await process_frame
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	root.set_meta("patogen_cepas", {1: "camaleon", 2: "camaleon"})
	host = load("res://scenes/" + map_name + ".tscn").instantiate()
	root.add_child(host)
	current_scene = host
	if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
	host.timer_inicio.stop()
	host.set_process(false)
	host.set_physics_process(false)
	host.evento_coloso.set_physics_process(false)
	host.evento_alfa.set_physics_process(false)
	for duck in get_nodes_in_group("patos"):
		duck.set_physics_process(false)
		duck.convertirse_en_fantasma()
	host.estado_actual = host.EstadoJuego.FASE_INFECCION
	host.timer_juego.start(120)
	var deadline := Time.get_ticks_msec() + 15000
	while not host.navegacion_simbionte.lista and Time.get_ticks_msec() < deadline: await physics_frame
	check(host.navegacion_simbionte.lista, map_name + " production navigation becomes ready")

func percepcion_navegada() -> void:
	await cargar_mapa("Laboratorio")
	await limpiar()
	var navigation: Node2D = host.npc_navigation
	var position := Vector2.INF
	for point in host.npc_destinations:
		if navigation.segmento_libre(point, point + Vector2(160, 0)):
			position = point
			break
	check(position.is_finite(), "the imported-map perception fixture uses a real clear corridor")
	if not position.is_finite(): return
	for team in [1, 2]:
		await limpiar()
		var source := actor(position, team)
		var observer := actor(position + Vector2(100, 0), 0)
		navigation.actualizar_exclusiones()
		observer.npc_brain._sense(observer, host)
		check(not observer.npc_brain.threats.has(source), "the 240-pixel route planner cannot bypass camouflage P%d" % team)
		source.npc_brain._sense(source, host)
		check(source.npc_brain.target != null and source.npc_brain.target.get_ref() == observer, "camouflaged AI still acquires and pursues healthy prey P%d" % team)
		observer.global_position = position + Vector2(70, 0)
		observer.npc_brain._sense(observer, host)
		check(observer.npc_brain.threats.has(source), "route perception detects camouflage within thirty percent of 240 pixels P%d" % team)
		source.camaleon.revelar("prueba")
		observer.global_position = position + Vector2(100, 0)
		observer.npc_brain._sense(observer, host)
		check(observer.npc_brain.threats.has(source), "revealed Camaleon restores ordinary route perception P%d" % team)
		for strain in ["atletico", "area", "exponencial", "garfio", "alfa"]:
			var empty: Array[String] = []
			source.aplicar_mutaciones(empty, strain)
			observer.npc_brain._sense(observer, host)
			check(observer.npc_brain.threats.has(source), "route perception of existing strain remains unchanged: " + strain)
	await persecucion_fisica(position)

func persecucion_fisica(position: Vector2) -> void:
	await limpiar()
	var source := actor(position)
	var observer := actor(position + Vector2(160, 0), 0)
	observer.proteccion_sano_ofensiva = 9999.0
	source.probabilidad_contagio = 0.0
	host.npc_navigation.actualizar_exclusiones()
	var start: Vector2 = source.global_position
	var original_distance: float = start.distance_to(observer.global_position)
	source.set_physics_process(true)
	await create_timer(0.5).timeout
	var travelled: float = source.global_position.distance_to(start)
	var remaining_distance: float = source.global_position.distance_to(observer.global_position)
	check(travelled > 15.0 and remaining_distance < original_distance - 15.0 and source.npc_brain.mode == "chase", "a real half-second of Bot physics moves the camouflaged AI toward its prey")
	check(source.camaleon.camuflado and remaining_distance > 72.0, "real pursuit keeps camouflage while remaining beyond the reduced detection range")
	observer.npc_brain._sense(observer, host)
	check(not observer.npc_brain.threats.has(source) and not observer.is_infected, "the stationary protected human does not react to the real distant approach")
	# Move only the observation fixture; the pursuing body remains under production physics.
	observer.global_position = source.global_position + Vector2(34, 0)
	await physics_frame
	await physics_frame
	check(not source.camaleon.camuflado, "the moving AI reveals automatically when a healthy body enters the safety distance")
	observer.npc_brain.direction(observer, host, 1.0 / 60.0, Vector2.ZERO)
	check(observer.npc_brain.threats.has(source) and observer.npc_brain.mode == "flee", "the healthy route planner starts fleeing the close revealed pursuer")
	source.set_physics_process(false)

func mapas() -> void:
	for map_name in ["Shopping", "Laboratorio", "PatoSplash"]:
		await cargar_mapa(map_name)
		var bots := get_nodes_in_group("bots")
		check(bots.size() == 65 and host.obtener_cepa_jugador(1) == "camaleon" and host.obtener_cepa_jugador(2) == "camaleon", map_name + " accepts both Camaleon selections without altering population")
		await limpiar()
		for team in [1, 2]:
			var source := actor(ORIGIN + Vector2(team * 100, 0), team)
			check(source.cepa == "camaleon" and is_instance_valid(source.camaleon) and source.camaleon.camuflado, map_name + " creates the live Camaleon component for P%d" % team)
