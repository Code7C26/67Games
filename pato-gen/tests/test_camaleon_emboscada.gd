extends "res://tests/test_simbionte.gd"
## Real contact rolls and ordinary infectar() remain the only infection path.
const ORIGIN := Vector2(656, 568)
const ATAQUE: Array[String] = ["ataque_sorpresa"]
const DESVANECIMIENTO: Array[String] = ["desvanecimiento"]
const SINERGIA: Array[String] = ["ataque_sorpresa", "desvanecimiento"]

func preparar() -> void:
	root.set_meta("patogen_cepas", {1: "camaleon", 2: "camaleon"})
	await fresh()
	host.set_physics_process(false)
	host.evento_coloso.set_physics_process(false)
	host.evento_alfa.set_physics_process(false)

func limpiar() -> void:
	for duck in get_nodes_in_group("patos"): duck.finalizar_posesion()
	for bot in get_nodes_in_group("bots"): bot.queue_free()
	await physics_frame
	await physics_frame

func actor(point: Vector2, team: int = 1, upgrades: Array[String] = []) -> Node2D:
	var bot: Node2D = bot_at(point, team)
	freeze_bot(bot)
	bot.incubacion_contagio = 0.0
	bot.feedback_restante = 0.0
	if team != 0:
		bot.aplicar_mutaciones(upgrades, "camaleon")
		bot.camaleon.actualizar(0.0)
	return bot

func semilla_contacto(source: Node2D, ranges: Array[Vector2]) -> Dictionary:
	# Mirror only the existing shuffle and one roll per eligible body. A failed
	# pulse can then prove that the implementation did not draw extra random rolls.
	for value in range(1, 10000):
		seed(value)
		var candidates: Array = source.area_infeccion.get_overlapping_bodies()
		candidates.shuffle()
		var rolls: Array[float] = []
		for target in candidates:
			if target == source or not target.is_in_group("bots") or target.is_infected: continue
			rolls.append(randf())
		var after := randf()
		if rolls.size() != ranges.size(): continue
		var fits := true
		for i in rolls.size():
			fits = fits and rolls[i] > ranges[i].x and rolls[i] < ranges[i].y
		if fits: return {"seed": value, "after": after, "rolls": rolls}
	return {}

func iniciar_nuevo_ciclo(source: Node2D) -> void:
	source.camaleon.actualizar(source.camaleon.recarga() + 0.01)
	if source.controlado_por_jugador: source.camaleon.activar_manual()

func run() -> void:
	await preparar()
	await parametros_y_pigmentacion()
	for team in [1, 2]:
		await primer_intento_y_limite(team)
		await un_bono_en_varias_presas(team)
		await exito_y_desvanecimiento(team)
		await fallos_e_inmunidades(team)
		await posesion_y_proximidad(team)
	await pausa_final_y_curacion()
	await otras_cepas()
	print("CAMALEON EMBOSCADA RESULT ", passed, " passed; ", failures, " failed")
	paused = false
	if is_instance_valid(host): host.queue_free()
	await process_frame
	await process_frame
	load("res://scripts/camaleon_arte.gd").limpiar_cache()
	load("res://scripts/npc_readability.gd").textures.clear()
	var bot_script: Script = load("res://scripts/Bot.gd")
	bot_script.frames_infectados_cache.clear()
	root.get_node("AudioManager").detener_musica()
	quit(0 if failures == 0 else 1)

func parametros_y_pigmentacion() -> void:
	await limpiar()
	var source := actor(ORIGIN)
	var ability: Node2D = source.camaleon
	check(is_equal_approx(ability.recarga(), 5.0) and is_zero_approx(ability.bono_ataque_sorpresa()) and is_zero_approx(ability.tiempo_desvanecimiento()), "unupgraded Camaleon has ordinary recovery and neither new benefit")
	var pigment: Array[String] = []
	for i in 3:
		pigment.append(["pigmentacion_avanzada", "mimetismo", "cromatoforos"][i])
		source.aplicar_mutaciones(pigment, "camaleon")
		check(is_equal_approx(ability.factor_deteccion(), [0.27, 0.24, 0.21][i]), "pigmentation keeps its existing progression tier " + str(i + 1))
	var attack: Array[String] = []
	for i in 3:
		attack.append(["ataque_sorpresa", "emboscada_viral", "golpe_furtivo"][i])
		source.aplicar_mutaciones(attack, "camaleon")
		check(is_equal_approx(ability.bono_ataque_sorpresa(), [0.25, 0.30, 0.35][i]), "surprise tiers remain configurable additive percentage points " + str(i + 1))
		check(is_equal_approx(ability.recarga(), 5.0), "buying Surprise Attack never shortens a failed attempt's cooldown")
	var fading: Array[String] = []
	for i in 3:
		fading.append(["desvanecimiento", "retorno_sigiloso", "adaptacion_fugaz"][i])
		source.aplicar_mutaciones(fading, "camaleon")
		check(is_equal_approx(ability.tiempo_desvanecimiento(), [1.0, 0.9, 0.8][i]) and is_equal_approx(ability.recarga(), 5.0), "fading tier accelerates only successful infection recovery " + str(i + 1))

func primer_intento_y_limite(team: int) -> void:
	await limpiar()
	var source := actor(ORIGIN, team, ATAQUE)
	var ability: Node2D = source.camaleon
	check(ability.camuflado and is_equal_approx(ability.preparar_intento(0.40), 0.65), "forty percent becomes sixty-five on the first camouflaged attempt P%d" % team)
	check(not ability.camuflado and is_equal_approx(ability.recarga_restante, 5.0), "preparing the real roll consumes camouflage and starts normal recovery P%d" % team)
	check(is_equal_approx(ability.preparar_intento(0.40), 0.40), "a failed or consumed attack cannot receive the bonus twice P%d" % team)
	iniciar_nuevo_ciclo(source)
	check(ability.camuflado and is_equal_approx(ability.preparar_intento(0.80), 0.90), "a new cycle restores one bonus and caps its probability at ninety percent P%d" % team)
	iniciar_nuevo_ciclo(source)
	source.probabilidad_contagio = 0.40
	source.multiplicador_contagio_temp = 1.5
	var base: float = source._chance_contagio()
	check(is_equal_approx(base, 0.60) and is_equal_approx(ability.preparar_intento(base), 0.85), "surprise adds to the existing temperature-adjusted contagion calculation P%d" % team)
	iniciar_nuevo_ciclo(source)
	var target := actor(ORIGIN + Vector2(42, 0), 0)
	await physics_frame
	await physics_frame
	source.probabilidad_contagio = 1.0
	source.multiplicador_contagio_temp = 1.0
	var fixture := semilla_contacto(source, [Vector2(0.91, 0.94)])
	check(not fixture.is_empty(), "ninety-percent cap has a deterministic real-roll fixture P%d" % team)
	if fixture.is_empty(): return
	seed(fixture.seed)
	source._intentar_contagio_area()
	check(not target.is_infected and not ability.camuflado, "a roll above ninety percent can fail even with a nominally guaranteed base P%d" % team)

func un_bono_en_varias_presas(team: int) -> void:
	await limpiar()
	var source := actor(ORIGIN, team, SINERGIA)
	var first := actor(ORIGIN + Vector2(42, 0), 0)
	var second := actor(ORIGIN + Vector2(-42, 0), 0)
	await physics_frame
	await physics_frame
	source.probabilidad_contagio = 0.0
	# First roll fails the 25% ambush; second would succeed if the same pulse
	# incorrectly kept its bonus. Its correct ordinary probability is zero.
	var fixture := semilla_contacto(source, [Vector2(0.30, 0.99), Vector2(0.01, 0.24)])
	check(not fixture.is_empty(), "two-target real pulse has a deterministic bonus-reuse fixture P%d" % team)
	if fixture.is_empty(): return
	var dna: int = host.obtener_adn(team)
	seed(fixture.seed)
	source._intentar_contagio_area()
	var after := randf()
	check(not first.is_infected and not second.is_infected, "only the first candidate receives surprise, even when its roll fails P%d" % team)
	check(is_equal_approx(after, fixture.after), "one normal random roll per target is preserved without a second infection roll P%d" % team)
	check(host.obtener_adn(team) == dna and is_equal_approx(source.camaleon.recarga_restante, 5.0), "failed attempts neither award DNA nor trigger fading P%d" % team)
	check(is_equal_approx(source.camaleon.preparar_intento(0.40), 0.40), "a later attempt cannot reclaim the failed ambush in the same cycle P%d" % team)

func exito_y_desvanecimiento(team: int) -> void:
	await limpiar()
	var source := actor(ORIGIN, team, SINERGIA)
	var target := actor(ORIGIN + Vector2(42, 0), 0)
	await physics_frame
	await physics_frame
	source.probabilidad_contagio = 0.40
	var fixture := semilla_contacto(source, [Vector2(0.41, 0.64)])
	check(not fixture.is_empty(), "successful ambush has a deterministic roll above ordinary contagion P%d" % team)
	if fixture.is_empty(): return
	var dna: int = host.obtener_adn(team)
	var infections: int = host.obtener_contagios_jugador(team)
	seed(fixture.seed)
	source._intentar_contagio_area()
	check(target.is_infected and target.player_duenio == team and target.cepa == "camaleon", "surprise uses the ordinary infection path, team and strain P%d" % team)
	check(not source.camaleon.camuflado and is_equal_approx(source.camaleon.recarga_restante, 1.0), "a successful camouflaged infection leaves one second rather than concealing immediately P%d" % team)
	check(host.obtener_adn(team) == dna + 1 and host.obtener_contagios_jugador(team) == infections + 1, "one success still creates one existing DNA reward P%d" % team)
	check(target.incubacion_contagio > 0.0 and target.tiempo_escudo > 0.0, "new infections retain incubation and their healing shield P%d" % team)
	source.camaleon.actualizar(0.30)
	var remaining: float = source.camaleon.recarga_restante
	source._contagiar_objetivo(target)
	check(is_equal_approx(source.camaleon.recarga_restante, remaining) and host.obtener_adn(team) == dna + 1, "a duplicate notification of the same already infected target cannot retrigger or reward fading P%d" % team)
	source.camaleon.actualizar(0.69)
	check(not source.camaleon.camuflado, "the successful attack still waits the complete one-second recovery P%d" % team)
	source.camaleon.actualizar(0.02)
	check(source.camaleon.camuflado and is_equal_approx(source.camaleon.preparar_intento(0.40), 0.65), "recovered concealment prepares the next independent ambush P%d" % team)
	# A new healthy body is infected from an already revealed host, without Attack.
	var empty: Array[String] = DESVANECIMIENTO.duplicate()
	source.aplicar_mutaciones(empty, "camaleon")
	var normal_target := actor(ORIGIN + Vector2(42, 0), 0)
	target.global_position += Vector2(150, 0)
	await physics_frame
	await physics_frame
	source.camaleon.revelar("prueba")
	source.probabilidad_contagio = 0.40
	fixture = semilla_contacto(source, [Vector2(0.01, 0.39)])
	check(not fixture.is_empty(), "ordinary revealed infection has a deterministic success fixture P%d" % team)
	if fixture.is_empty(): return
	seed(fixture.seed)
	source._intentar_contagio_area()
	check(normal_target.is_infected and is_equal_approx(source.camaleon.recarga_restante, 1.0), "fading also follows an ordinary revealed infection with no surprise mutation P%d" % team)
	var later_target := actor(ORIGIN + Vector2(-42, 0), 0)
	await physics_frame
	await physics_frame
	source.probabilidad_contagio = 0.0
	fixture = semilla_contacto(source, [Vector2(0.01, 0.99)])
	check(not fixture.is_empty(), "a subsequent ordinary failed attack has its own real-roll fixture P%d" % team)
	if fixture.is_empty(): return
	seed(fixture.seed)
	source._intentar_contagio_area()
	check(not later_target.is_infected and is_equal_approx(source.camaleon.recarga_restante, 5.0), "a new failed attempt restores normal recovery instead of reusing an earlier success P%d" % team)

func fallos_e_inmunidades(team: int) -> void:
	for protection in ["proteccion_coloso", "proteccion_sano_ofensiva"]:
		await limpiar()
		var source := actor(ORIGIN, team, SINERGIA)
		var target := actor(ORIGIN + Vector2(42, 0), 0)
		target.set(protection, 10.0)
		source.probabilidad_contagio = 0.40
		await physics_frame
		await physics_frame
		var fixture := semilla_contacto(source, [Vector2(0.01, 0.64)])
		check(not fixture.is_empty(), "protected target receives an otherwise successful real-roll fixture P%d %s" % [team, protection])
		if fixture.is_empty(): continue
		var dna: int = host.obtener_adn(team)
		seed(fixture.seed)
		source._intentar_contagio_area()
		check(not target.is_infected and host.obtener_adn(team) == dna, "Surprise Attack never bypasses healthy immunity P%d %s" % [team, protection])
		check(not source.camaleon.camuflado and is_equal_approx(source.camaleon.recarga_restante, 5.0), "a protected unsuccessful target consumes the bonus but never accelerates fading P%d %s" % [team, protection])

func posesion_y_proximidad(team: int) -> void:
	await limpiar()
	var source := actor(ORIGIN, team, SINERGIA)
	var target := actor(ORIGIN + Vector2(42, 0), 0)
	var duck: Node2D = host.get_node("Patos/" + ("Pato" if team == 1 else "Pato2"))
	duck.iniciar_posesion(source)
	check(source.controlado_por_jugador and duck.bot_poseido == source, "the ordinary possession path controls Camaleon P%d" % team)
	await physics_frame
	await physics_frame
	# Resolve a legitimate new infection through the common successful-entry hook.
	source._contagiar_objetivo(target)
	check(target.is_infected and is_equal_approx(source.camaleon.recarga_restante, 1.0), "a possessed Camaleon's attributable infection accelerates its own recovery P%d" % team)
	var near := actor(ORIGIN + Vector2(0, 34), 0)
	source.camaleon.actualizar(1.01)
	check(not source.camaleon.camuflado and is_zero_approx(source.camaleon.recarga_restante), "a nearby healthy human blocks camouflage after the reduced timer expires P%d" % team)
	check(not duck.activar_camaleon_poseido(), "the existing X/J contextual action cannot conceal beside a human P%d" % team)
	near.global_position += Vector2(150, 0)
	check(duck.activar_camaleon_poseido() and source.camaleon.camuflado, "the existing X/J action can conceal once the same successful recovery is safe P%d" % team)
	duck.finalizar_posesion()
	source.camaleon.revelar("prueba")
	target.global_position += Vector2(150, 0)
	var ai_target := actor(ORIGIN + Vector2(42, 0), 0)
	source._contagiar_objetivo(ai_target)
	source.camaleon.actualizar(1.01)
	check(ai_target.is_infected and source.camaleon.camuflado, "returning to AI uses the same attributable infection and accelerated recovery automatically P%d" % team)

func pausa_final_y_curacion() -> void:
	await limpiar()
	var source := actor(ORIGIN, 1, SINERGIA)
	var ability: Node2D = source.camaleon
	host.timer_juego.paused = true
	check(is_equal_approx(ability.preparar_intento(0.40), 0.40) and ability.camuflado, "a tutorial-held clock cannot consume or enhance an ambush")
	host.timer_juego.paused = false
	ability.revelar("prueba")
	paused = true
	ability.registrar_contagio_exitoso()
	ability.actualizar(10.0)
	check(is_equal_approx(ability.recarga_restante, 5.0), "global pause does not grant or advance accelerated recovery")
	paused = false
	host.estado_actual = host.EstadoJuego.FIN
	ability.registrar_contagio_exitoso()
	check(is_equal_approx(ability.recarga_restante, 5.0), "a finished match cannot apply a stale success notification")
	host.estado_actual = host.EstadoJuego.FASE_INFECCION
	source.curar(false)
	check(source.camaleon == null and source.cepa.is_empty(), "curing removes the old ambush and its successful recovery state")
	source.activar_infeccion(Color.CYAN, 1, false)
	source.incubacion_contagio = 0.0
	freeze_bot(source)
	check(is_instance_valid(source.camaleon) and is_zero_approx(source.camaleon.recarga_restante), "reinfection creates a fresh component rather than inheriting old timers")

func otras_cepas() -> void:
	for strain in ["atletico", "area", "exponencial", "garfio", "rastreador", "alfa"]:
		await limpiar()
		var source := actor(ORIGIN, 1, SINERGIA)
		source.aplicar_mutaciones(SINERGIA, strain)
		source.probabilidad_contagio = 0.0
		var target := actor(ORIGIN + Vector2(42, 0), 0)
		await physics_frame
		await physics_frame
		var fixture := semilla_contacto(source, [Vector2(0.01, 0.24)])
		check(not fixture.is_empty(), "existing strain has a deterministic zero-chance contact fixture: " + strain)
		if fixture.is_empty(): continue
		seed(fixture.seed)
		source._intentar_contagio_area()
		check(source.camaleon == null and not target.is_infected and is_zero_approx(source._chance_contagio()), "Camaleon's mutation IDs cannot leak probability or fading into another strain: " + strain)
