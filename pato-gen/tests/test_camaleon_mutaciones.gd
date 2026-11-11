extends "res://tests/test_simbionte.gd"
## Purchases use the real match economy and propagate through ordinary infection.
const ORIGIN := Vector2(656, 568)
const BRANCHES := [
	["pigmentacion_avanzada", "mimetismo", "cromatoforos"],
	["desvanecimiento", "retorno_sigiloso", "adaptacion_fugaz"],
	["ataque_sorpresa", "emboscada_viral", "golpe_furtivo"]
]

func preparar() -> void:
	root.set_meta("patogen_cepas", {1: "camaleon", 2: "camaleon"})
	await fresh()
	host.evento_coloso.set_physics_process(false)
	host.evento_alfa.set_physics_process(false)

func saldo(team: int, amount: int) -> void:
	if team == 1: host.adn_cian = amount
	else: host.adn_magenta = amount

func comprar_por_teclado(team: int, branch: int) -> void:
	var keys := [KEY_1, KEY_2, KEY_3] if team == 1 else [KEY_8, KEY_9, KEY_0]
	key(keys[branch])

func run() -> void:
	await preparar()
	check(host.interfaz.mutation_icons.size() == 53, "all existing mutation icons remain available, including Rastreador")
	for old_id in ["acecho_silencioso", "paso_velado", "emboscada_sutil"]:
		check(not host.interfaz.mutation_icons.has(old_id), "removed stalking upgrade has no duplicate HUD entry: " + old_id)
	for new_id in BRANCHES[2]:
		check(host.interfaz.mutation_icons.has(new_id), "surprise attack tier has its own HUD icon: " + new_id)
	for team in [1, 2]:
		await compras_y_herencia(team)
	await rechazo_de_otras_cepas()
	print("CAMALEON MUTACIONES RESULT ", passed, " passed; ", failures, " failed")
	paused = false
	if is_instance_valid(host): host.queue_free()
	await process_frame
	await process_frame
	var arte: Script = load("res://scripts/camaleon_arte.gd")
	arte.limpiar_cache()
	var readability: Script = load("res://scripts/npc_readability.gd")
	readability.textures.clear()
	var bot_script: Script = load("res://scripts/Bot.gd")
	bot_script.frames_infectados_cache.clear()
	root.get_node("AudioManager").detener_musica()
	quit(0 if failures == 0 else 1)

func compras_y_herencia(team: int) -> void:
	var label := " P%d" % team
	var source := bot_at(ORIGIN, team)
	freeze_bot(source)
	check(host.obtener_cepa_jugador(team) == "camaleon" and source.cepa == "camaleon", "selected strain reaches the first host" + label)
	check(host.obtener_ramas_jugador(team).size() == 3, "Camaleon uses the three existing purchase slots" + label)
	check(is_instance_valid(source.camaleon), "Camaleon has its state component" + label)
	check(is_equal_approx(source.speed, source.velocidad_base) and is_equal_approx(source.probabilidad_contagio, 0.35) and is_equal_approx(source.probabilidad_curacion, 0.01), "base speed, infection and natural cure remain ordinary" + label)
	if not is_instance_valid(source.camaleon): return
	check(is_equal_approx(source.camaleon.factor_deteccion(), 0.30) and is_equal_approx(source.camaleon.recarga(), 5.0) and is_zero_approx(source.camaleon.bono_ataque_sorpresa()) and is_zero_approx(source.camaleon.tiempo_desvanecimiento()), "unupgraded component has the requested base balance" + label)
	check(not source.camaleon.has_method("demora_reaccion"), "the removed reaction delay is not kept as a parallel ability" + label)
	for branch in range(3):
		saldo(team, 4)
		comprar_por_teclado(team, branch)
		check(host.obtener_adn(team) == 4 and not source.tiene_mutacion(BRANCHES[branch][0]), "insufficient funds neither buy nor charge branch %d" % branch + label)
		saldo(team, 30)
		var balance := 30
		for level in range(3):
			check(host.obtener_costo_mutacion(BRANCHES[branch][0], source.mutaciones) == [5, 10, 15][level], "next tier retains the existing 5/10/15 pricing" + label)
			comprar_por_teclado(team, branch)
			balance -= [5, 10, 15][level]
			check(host.obtener_adn(team) == balance and source.tiene_mutacion(BRANCHES[branch][level]), "keyboard purchase updates economy and existing host branch %d level %d" % [branch, level] + label)
			match branch:
				0: check(is_equal_approx(source.camaleon.factor_deteccion(), [0.27, 0.24, 0.21][level]), "pigmentation tiers lower only camouflage detection" + label)
				1: check(is_equal_approx(source.camaleon.recarga(), 5.0) and is_equal_approx(source.camaleon.tiempo_desvanecimiento(), [1.0, 0.9, 0.8][level]), "fading tiers shorten only the recovery after a successful infection" + label)
				2: check(is_equal_approx(source.camaleon.bono_ataque_sorpresa(), [0.25, 0.30, 0.35][level]) and is_equal_approx(source.camaleon.recarga(), 5.0), "ambush tiers keep the normal failed-attempt cooldown" + label)
			check(is_equal_approx(source.speed, source.velocidad_base) and is_equal_approx(source.probabilidad_contagio, 0.35) and is_equal_approx(source.probabilidad_curacion, 0.01), "upgrades preserve ordinary speed, contagion and cure resistance" + label)
			check(host._nombre_mutacion(BRANCHES[branch][level]) != BRANCHES[branch][level] and not "No hay una descripción" in host._descripcion_mutacion(BRANCHES[branch][level]), "purchased tier has a localized name and explanation" + label)
		comprar_por_teclado(team, branch)
		check(host.obtener_adn(team) == 0 and host.obtener_siguiente_evolucion(BRANCHES[branch][0], source.mutaciones) == "", "completed branch stops at tier three without charging" + label)
		saldo(team, 30)
		host.comprar_mutacion(team, "fiebre")
		check(host.obtener_adn(team) == 30 and not source.tiene_mutacion("fiebre"), "Camaleon cannot buy another strain's speed branch" + label)
	check(source.mutaciones.size() == 9, "all three branches have exactly three evolutions" + label)
	for old_id in ["acecho_silencioso", "paso_velado", "emboscada_sutil"]:
		var balance: int = host.obtener_adn(team)
		host.comprar_mutacion(team, old_id)
		check(host.obtener_adn(team) == balance and not source.tiene_mutacion(old_id), "obsolete reaction-delay IDs cannot be purchased: " + old_id + label)
	var target := bot_at(ORIGIN + Vector2(32, 0), 0)
	var before_dna: int = host.obtener_adn(team)
	var before_infections: int = host.obtener_contagios_jugador(team)
	source._contagiar_objetivo(target)
	freeze_bot(target)
	check(target.is_infected and target.cepa == "camaleon" and target.player_duenio == team, "ordinary infection transmits Camaleon and the correct team" + label)
	check(target.mutaciones == source.mutaciones and is_instance_valid(target.camaleon), "new infection receives the team's purchased stealth upgrades" + label)
	check(host.obtener_adn(team) == before_dna + 1 and host.obtener_contagios_jugador(team) == before_infections + 1, "normal rewarded contagion grants DNA exactly once" + label)
	check(source.camaleon.recarga_restante <= 0.8001, "the real successful infection applies the purchased final fading tier" + label)
	target.curar(false)
	check(not target.is_infected and target.cepa == "" and target.mutaciones.is_empty(), "curing removes Camaleon and all strain upgrades" + label)
	source.queue_free()
	target.queue_free()
	await physics_frame

func rechazo_de_otras_cepas() -> void:
	host.cepa_cian = "atletico"
	host.mutaciones_p1.clear()
	saldo(1, 90)
	for branch in BRANCHES:
		host.comprar_mutacion(1, branch[0])
	check(host.adn_cian == 90 and host.mutaciones_p1.is_empty(), "other strains cannot buy any Camaleon branch")
