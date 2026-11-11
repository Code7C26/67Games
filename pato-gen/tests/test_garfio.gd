extends "res://tests/test_simbionte.gd"
## Contract tests against real Bot bodies, Shopping collisions and match economy.
const G = preload("res://scripts/garfio.gd")
const READABILITY = preload("res://scripts/npc_readability.gd")
const ORIGIN := Vector2(656, 568)
const ASSET_HASHES := {
	"garfio.aseprite": "b6fa2f0728284d8cffd5440561d3c2b43c92eb5bd12d7f47bc41ef82a3135cd0",
	"garfio_diseno_aprobado.aseprite": "8d9de4ec1a2f405968b5be202ba64fe4c041bfb8b380e7a7d05324f1ff1df263",
	"garfio_sheet.png": "c69560119fafac4d683b4d9bc5a939a54a050f5aada8b42c71053bbebeed26f8",
	"retrato.png": "119bafae4b60912e78d551d6967747a519384610ab79df0d1b328ed2be5019d9",
	"punta_garfio.png": "431dd52a617a34adc8907d25815d33d164592e4d178528650b95b40431ea14b7",
	"garfio_abajo.png": "7f4dd06f7fea50234f83f6f21b6dcc0aee283a1de957c07e1a3d437378cf51d7",
	"garfio_arriba.png": "c671bd6c7260565e211a18cca42c3d249ee5b434090fe1e22861424540ca0f01",
	"garfio_derecha.png": "47bd4266905833bede80ba3317f9294db0f3902363354b428387a27b60d1e29c",
	"garfio_izquierda.png": "84d69f4afb7c6f94cef87776b674e90b8e58d0f4567328a90fd4bbd7a170fcea"
}

func preparar() -> void:
	root.set_meta("patogen_cepas", {1: "garfio", 2: "garfio"})
	await fresh()
	host.evento_coloso.set_physics_process(false)
	host.evento_alfa.set_physics_process(false)

func limpiar() -> void:
	for bot in get_nodes_in_group("bots"):
		bot.queue_free()
	await physics_frame
	await physics_frame

func actor(point: Vector2, team: int = 1) -> Node2D:
	var bot := bot_at(point, team)
	freeze_bot(bot)
	bot.incubacion_contagio = 0.0
	if is_instance_valid(bot.garfio): bot.garfio.hasta_busqueda = 1000.0
	return bot

func pair_at(distance: float = 130.0, team: int = 1) -> Dictionary:
	return {"source": actor(ORIGIN, team), "target": actor(ORIGIN + Vector2(distance, 0), 0)}

func actor_contador(point: Vector2, team: int) -> Node2D:
	# Construct the observer normally; changing an instantiated node's script would
	# discard exported resource references and pollute the driver's shutdown audit.
	var template: CharacterBody2D = load("res://scenes/Bot.tscn").instantiate()
	var bot: CharacterBody2D = load("res://tests/garfio_bot_contador.gd").new()
	bot.skins.assign(template.skins)
	bot.collision_layer = template.collision_layer
	bot.collision_mask = template.collision_mask
	for child in template.get_children():
		limpiar_propietarios_fixture(child)
		template.remove_child(child)
		bot.add_child(child)
	template.free()
	host.get_node("Bots").add_child(bot)
	bot.global_position = point
	bot.set_physics_process(false)
	bot.get_node("TimerCambioRumbo").stop()
	bot.activar_infeccion(Color.CYAN if team == 1 else Color.MAGENTA, team, false)
	freeze_bot(bot)
	bot.incubacion_contagio = 0.0
	bot.garfio.hasta_busqueda = 1000.0
	return bot

func limpiar_propietarios_fixture(node: Node) -> void:
	# PackedScene descendants still point at the template as owner. Remove that
	# editor-only relationship before moving the physical fixture to its observer.
	node.owner = null
	for child in node.get_children(): limpiar_propietarios_fixture(child)

func ready_again(ability: Node2D) -> void:
	ability.cancelar()
	ability.recarga_restante = 0.0
	ability.hasta_busqueda = 1000.0

func hook(ability: Node2D, target: Node2D) -> bool:
	if not ability.intentar_enganche(target): return false
	ability.actualizar(ability.parametros.preparacion)
	for _i in 20:
		if ability.estado != G.Estado.EXTENDIENDO: break
		ability.actualizar(0.025)
	return ability.estado == G.Estado.ARRASTRANDO

func run() -> void:
	await preparar()
	verificar_configuracion_y_assets()
	await identidad_y_compras()
	await elegibilidad_y_alcance()
	await fases_y_economia()
	await llegada_y_timer()
	await virulencia_y_protecciones()
	await presupuesto_y_orden()
	await esquiva_y_muros()
	await interrupciones_y_pausa()
	await automatico_y_fisica_bot()
	await mapas()
	print("GARFIO RESULT ", passed, " passed; ", failures, " failed")
	paused = false
	if is_instance_valid(host): host.queue_free()
	await process_frame
	await process_frame
	READABILITY.textures.clear()
	var bot_script: Script = load("res://scripts/Bot.gd")
	bot_script.frames_infectados_cache.clear()
	root.get_node("AudioManager").detener_musica()
	quit(0 if failures == 0 else 1)

func verificar_configuracion_y_assets() -> void:
	var config: Resource = load("res://resources/garfio_config.tres")
	var defaults := {"alcance_base": 160.0, "preparacion": 0.35, "duracion_max_arrastre": 0.65,
		"enfriamiento": 7.0, "multiplicador_velocidad": 0.9, "probabilidad_contagio": 0.35,
		"velocidad_arrastre": 200.0, "velocidad_extension": 400.0, "distancia_minima": 52.0,
		"distancia_contacto": 36.0, "radio_impacto": 18.0, "recuperacion": 0.25,
		"duracion_vulnerable": 1.0, "bono_vulnerable": 0.25, "probabilidad_maxima_vulnerable": 0.90}
	var exported: Dictionary = {}
	for property in config.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_EDITOR: exported[String(property.name)] = true
	for property in defaults:
		check(is_equal_approx(float(config.get(property)), defaults[property]) and exported.has(property), "Inspector exposes the requested default " + property)
	check(config.factores_movimiento_desorientado.size() == 3 and config.factores_duracion_doble.size() == 3 and config.factores_recarga_reenganche.size() == 3, "three levels tune each tactical mutation in the existing resource")
	for file in ASSET_HASHES:
		check(FileAccess.get_sha256("res://assets/garfio/" + file) == ASSET_HASHES[file], "approved asset remains byte-identical: " + file)

func identidad_y_compras() -> void:
	for team in [1, 2]:
		await limpiar()
		var source := actor(ORIGIN, team)
		var ability: Node2D = source.garfio
		check(source.cepa == "garfio" and is_instance_valid(ability), "Garfio has its own component P%d" % team)
		check(is_equal_approx(source.speed, source.velocidad_base * 0.9) and is_equal_approx(source.probabilidad_contagio, 0.35), "base stats keep ordinary contagion and ninety percent movement P%d" % team)
		check(is_equal_approx(ability.alcance(), 160.0) and is_equal_approx(ability.recarga(), 7.0) and is_equal_approx(ability.velocidad_arrastre(), 200.0), "base capture tuning P%d" % team)
		check(source.configuracion_garfio == ability.parametros, "live component reads the Inspector resource P%d" % team)
		for direction in ["arriba", "abajo", "izquierda", "derecha"]:
			check(source.animated_sprite.sprite_frames.has_animation("caminar_" + direction) and source.animated_sprite.sprite_frames.has_animation("idle_" + direction), "live Garfio has walk and idle " + direction + " P%d" % team)
		verificar_arte(source, team)
		var branches: Array = host.obtener_ramas_jugador(team)
		check(branches.size() == 3, "Garfio offers three tactical branches P%d" % team)
		for branch in branches:
			if team == 1: host.adn_cian = 30
			else: host.adn_magenta = 30
			for level in 3:
				host.comprar_mutacion(team, branch[0])
				check(source.tiene_mutacion(branch[level]) and host.obtener_adn(team) == [25, 15, 0][level], "real purchase tier %d costs 5/10/15 for %s P%d" % [level + 1, branch[0], team])
			var before: int = host.obtener_adn(team)
			host.comprar_mutacion(team, branch[0])
			check(host.obtener_adn(team) == before, "completed branch cannot charge again " + branch[0])
		check(is_equal_approx(ability.alcance(), 160.0) and is_equal_approx(ability.recarga(), 7.0) and is_equal_approx(ability.velocidad_arrastre(), 200.0) and ability.nivel_vulnerable() == 3 and ability.nivel_doble() == 3 and ability.nivel_reenganche() == 3, "tier-three purchases unlock tactical branches while preserving the base hook P%d" % team)
		check(is_equal_approx(source.speed, source.velocidad_base * 0.9) and is_equal_approx(source.probabilidad_contagio, 0.35) and not source.tiene_mutacion("division_celular") and not source.tiene_mutacion("esporas"), "tactical evolution adds neither ordinary contagion, speed, reproduction nor area contagion P%d" % team)
		host.mutaciones_p1.clear()
		host.mutaciones_p2.clear()
		host.actualizar_mutaciones_existentes(1)
		host.actualizar_mutaciones_existentes(2)

func verificar_arte(source: Node2D, team: int) -> void:
	var sprite: AnimatedSprite2D = source.animated_sprite
	var frames: SpriteFrames = sprite.sprite_frames
	var stable_scale: Vector2 = sprite.scale
	var stable_position: Vector2 = sprite.position
	var metrics := READABILITY.body_metrics(frames)
	check(is_equal_approx(metrics.x * sprite.scale.y, 29.0 * 1.16), "final artwork keeps the shared painted body height P%d" % team)
	check(is_equal_approx(metrics.y * sprite.scale.y + sprite.position.y, 15.0), "final artwork keeps the common ground line P%d" % team)
	var count := 0
	var valid_cells := true
	var actual_motion := true
	var stable_transform := true
	for animation in frames.get_animation_names():
		var expected := 4 if String(animation).begins_with("caminar_") else 2
		check(frames.get_frame_count(animation) == expected, "final asset frame count %s P%d" % [animation, team])
		var pixels: PackedByteArray
		var changed := false
		for index in frames.get_frame_count(animation):
			count += 1
			var image := frames.get_frame_texture(animation, index).get_image()
			valid_cells = valid_cells and image.get_size() == Vector2i(36, 36) and image.get_used_rect().has_area()
			for x in image.get_width():
				valid_cells = valid_cells and image.get_pixel(x, 0).a == 0.0 and image.get_pixel(x, 35).a == 0.0
			for y in image.get_height():
				valid_cells = valid_cells and image.get_pixel(0, y).a == 0.0 and image.get_pixel(35, y).a == 0.0
			var data := image.get_data()
			if index == 0: pixels = data
			else: changed = changed or pixels != data
			sprite.animation = animation
			sprite.frame = index
			stable_transform = stable_transform and sprite.scale.is_equal_approx(stable_scale) and sprite.position.is_equal_approx(stable_position)
		actual_motion = actual_motion and changed
	check(count == 32 and valid_cells, "all 32 final frames load with transparent outline margins P%d" % team)
	check(actual_motion, "every final animation contains different drawn poses P%d" % team)
	check(stable_transform, "switching all final frames does not change scale or ground alignment P%d" % team)
	var capsule: CapsuleShape2D = source.get_node("CollisionShape2D").shape
	check(is_equal_approx(capsule.radius, 11.5) and is_equal_approx(capsule.height, 32.0), "final artwork preserves the existing physical capsule P%d" % team)
	sprite.play("idle_abajo")

func elegibilidad_y_alcance() -> void:
	await limpiar()
	var pair := pair_at()
	var source: Node2D = pair.source
	var target: Node2D = pair.target
	var ability: Node2D = source.garfio
	check(not ability.intentar_enganche(source), "cannot hook itself")
	source.incubacion_contagio = 0.5
	check(not ability.intentar_enganche(target), "newly infected host cannot fire during incubation")
	source.incubacion_contagio = 0.0
	for protection in ["proteccion_coloso", "proteccion_sano_ofensiva"]:
		target.set(protection, 2.0)
		check(not ability.intentar_enganche(target) and target.captor_garfio == null, "protected healthy guest cannot be reserved: " + protection)
		target.set(protection, 0.0)
	target.controlado_por_jugador = true
	check(not ability.intentar_enganche(target), "cannot reserve a player-controlled guest")
	target.controlado_por_jugador = false
	for distance in [ability.parametros.distancia_minima - 0.1, 160.1]:
		target.global_position = ORIGIN + Vector2(distance, 0)
		check(not ability.intentar_enganche(target), "capture rejects range boundary " + str(distance))
	for distance in [ability.parametros.distancia_minima, 160.0]:
		target.global_position = ORIGIN + Vector2(distance, 0)
		check(ability.intentar_enganche(target), "capture accepts inclusive range boundary " + str(distance))
		ready_again(ability)
	target.global_position = ORIGIN + Vector2(130, 0)
	var rival := actor(ORIGIN + Vector2(0, 80), 2)
	check(not ability.intentar_enganche(rival), "infected rival is never a hook target")
	var ally := actor(ORIGIN + Vector2(0, -80), 1)
	check(not ability.intentar_enganche(ally), "infected ally is never a hook target")
	check(ability.intentar_enganche(target) and target.captor_garfio == ability, "one healthy target is reserved at anticipation")
	check(not rival.garfio.intentar_enganche(target), "a rival Garfio cannot capture the same reserved human")
	ability.cancelar()
	check(target.captor_garfio == null and ability.objetivo == null, "cancel releases the reservation on both ends")
	ready_again(ability)
	var old_map: Node = target.map_host
	target.map_host = null
	check(not ability.intentar_enganche(target), "capture cannot cross map ownership")
	target.map_host = old_map
	source.activar_control_jugador(1)
	source.recibir_control_jugador(Vector2.LEFT)
	check(not ability.intentar_enganche(target), "possession aiming rejects a human behind the movement direction")
	source.recibir_control_jugador(Vector2.RIGHT)
	check(ability.intentar_enganche(target), "possessed Garfio can aim its hook forward")
	source.desactivar_control_jugador()
	ready_again(ability)
	ability.recarga_restante = 1.0
	check(not ability.intentar_enganche(target), "cooldown prevents immediate recapture")

func fases_y_economia() -> void:
	await limpiar()
	var pair := pair_at()
	var source: Node2D = pair.source
	var target: Node2D = pair.target
	var ability: Node2D = source.garfio
	source.probabilidad_contagio = 0.0
	var balance := [host.adn_cian, host.contagios_cian, get_nodes_in_group("bots").size()]
	var initial: Vector2 = target.global_position
	check(ability.intentar_enganche(target) and ability.estado == G.Estado.PREPARANDO, "hook begins with visible anticipation")
	check(not ability.arrastrar_objetivo(target, 0.1) and target.global_position == initial, "anticipation does not immobilize or teleport the prey")
	ability.actualizar(ability.parametros.preparacion - 0.01)
	check(ability.estado == G.Estado.PREPARANDO, "anticipation respects its full duration")
	ability.actualizar(0.02)
	check(ability.estado == G.Estado.EXTENDIENDO and target.global_position == initial, "launch is a separate extension phase")
	ability.actualizar(0.1)
	check(ability.estado == G.Estado.EXTENDIENDO and ability.punta_global.distance_to(ORIGIN) < 80.0, "projectile has finite travel time")
	for _i in 20:
		if ability.estado != G.Estado.EXTENDIENDO: break
		ability.actualizar(0.025)
	check(ability.estado == G.Estado.ARRASTRANDO and not target.is_infected, "hook impact captures without remote infection")
	var previous: Vector2 = target.global_position
	ability.arrastrar_objetivo(target, 0.1)
	check(target.global_position.distance_to(previous) <= ability.velocidad_arrastre() * 0.1 + 0.1 and target.global_position.distance_to(ORIGIN) < initial.distance_to(ORIGIN), "pull moves the real capsule by its speed limit")
	for _i in 50:
		if target.captor_garfio == null: break
		ability.arrastrar_objetivo(target, 0.025)
		ability.actualizar(0.025)
	check(target.captor_garfio == null and target.global_position.distance_to(ORIGIN) <= ability.parametros.distancia_contacto + 0.2, "pull releases at ordinary contact distance")
	check(not target.is_infected and [host.adn_cian, host.contagios_cian, get_nodes_in_group("bots").size()] == balance, "a failed arrival roll creates no contagion, DNA or extra population")
	check(ability.recarga_restante > 0.0 and ability.estado == G.Estado.RECUPERANDO, "completed pull starts recovery and cooldown")
	source._contagiar_objetivo(target)
	check(target.is_infected and target.cepa == "garfio" and host.adn_cian == balance[0] + 1 and host.contagios_cian == balance[1] + 1, "normal contact contagion keeps one reward and passes the Garfio strain")

func llegada_y_timer() -> void:
	for team in [1, 2]:
		await limpiar()
		var source := actor_contador(ORIGIN, team)
		var target := actor(ORIGIN + Vector2(130, 0), 0)
		var ability: Node2D = source.garfio
		var initial_dna: int = host.obtener_adn(team)
		var initial_infections: int = host.obtener_contagios_jugador(team)
		check(hook(ability, target), "single-attempt fixture captures P%d" % team)
		# At 48 px the infection area overlaps the capsule before the 36 px arrival.
		target.global_position = ORIGIN + Vector2(48, 0)
		await physics_frame
		await physics_frame
		check(source.area_infeccion.overlaps_body(target), "near-arrival fixture overlaps the real infection area P%d" % team)
		source.probabilidad_contagio = 0.95
		seed(937)
		for _i in 8: source._intentar_contagio_area()
		check(not target.is_infected and source.intentos_llegada == 0 and source.contagios_invocados == 0, "normal timer cannot infect the reserved guest during pull P%d" % team)
		source.probabilidad_contagio = 0.0
		ability.arrastrar_objetivo(target, 0.1)
		check(source.intentos_llegada == 1 and source.contagios_invocados == 0 and not target.is_infected, "arrival performs exactly one failed base roll at zero chance P%d" % team)
		check(host.obtener_adn(team) == initial_dna and host.obtener_contagios_jugador(team) == initial_infections, "failed arrival does not award DNA or contagion P%d" % team)
		source.probabilidad_contagio = 0.95
		for _i in 8:
			source._intentar_contagio_area()
			ability.arrastrar_objetivo(target, 0.01)
			ability.actualizar(0.01)
		check(not target.is_infected and source.intentos_llegada == 1 and source.contagios_invocados == 0, "arrival and same-tick timer cannot produce a duplicate roll P%d" % team)
		# Resume the regular interval; this is ordinary contact after the protected window.
		source.activar_control_jugador(team)
		source.recibir_control_jugador(Vector2.ZERO)
		source._physics_process(0.71)
		seed(937)
		for _i in 8:
			if target.is_infected: break
			source._intentar_contagio_area()
		check(target.is_infected and target.player_duenio == team and source.contagios_invocados == 1 and host.obtener_adn(team) == initial_dna + 1 and host.obtener_contagios_jugador(team) == initial_infections + 1, "later ordinary contact retains one normal infection and one reward P%d" % team)
		source.desactivar_control_jugador()

func semilla_entre(minimum: float, maximum: float) -> int:
	for candidate in 10000:
		seed(candidate)
		var roll := randf()
		if roll > minimum and roll < maximum: return candidate
	return -1

func virulencia_y_protecciones() -> void:
	for team in [1, 2]:
		await limpiar()
		var source := actor_contador(ORIGIN, team)
		var target := actor(ORIGIN + Vector2(36, 0), 0)
		var ability: Node2D = source.garfio
		source.multiplicador_contagio_temp = 0.5
		var ordinary_chance: float = source._chance_contagio()
		check(is_equal_approx(ordinary_chance, 0.175), "hook shares the ordinary temperature modifier P%d" % team)
		var chosen_seed := semilla_entre(ordinary_chance + 0.001, ordinary_chance + 0.029)
		check(chosen_seed >= 0, "deterministic roll exists between ordinary and virulent chance P%d" % team)
		seed(chosen_seed)
		check(not source.intentar_contagio_garfio(target, 0.0) and not target.is_infected, "ordinary probability can fail on arrival P%d" % team)
		var mutations: Array[String] = ["tendon_reforzado"]
		source.aplicar_mutaciones(mutations, "garfio")
		check(ability.nivel_vulnerable() == 1 and is_equal_approx(source._chance_contagio(), ordinary_chance), "Presa vulnerable does not change ordinary contagion P%d" % team)
		var before: int = host.obtener_adn(team)
		source.espera_contacto_garfio = 0.0
		ability.actualizar(0.71)
		ability._registrar_captura(target)
		seed(chosen_seed)
		check(source.intentar_contagio_garfio(target) and target.is_infected and host.obtener_adn(team) == before + 1, "the same roll succeeds only for the registered vulnerable capture and awards once P%d" % team)
		freeze_bot(target)
		check(not source.intentar_contagio_garfio(target, ability.bono_virulento()) and host.obtener_adn(team) == before + 1, "repeating arrival cannot infect or reward an already infected guest P%d" % team)
		target.curar(false)
		for protection in ["proteccion_coloso", "proteccion_sano_ofensiva"]:
			source.espera_contacto_garfio = 0.0
			target.set(protection, 2.0)
			seed(chosen_seed)
			check(not source.intentar_contagio_garfio(target, 0.95) and not target.is_infected, "arrival respects protected healthy guest: %s P%d" % [protection, team])
			target.set(protection, 0.0)
		source.incubacion_contagio = 1.0
		check(not source.intentar_contagio_garfio(target, 0.95), "arrival respects source incubation P%d" % team)
		source.incubacion_contagio = 0.0
		host.timer_juego.paused = true
		check(not source.intentar_contagio_garfio(target, 0.95), "arrival respects tutorial clock hold P%d" % team)
		host.timer_juego.paused = false
		paused = true
		check(not source.intentar_contagio_garfio(target, 0.95), "arrival respects global pause P%d" % team)
		paused = false
		# Defensive shields retain their old meaning: they protect an infected host's cure.
		source.tiempo_escudo = 2.0
		check(not source.recibir_curacion_ofensiva(1.0, 1.0, 3 - team) and source.is_infected, "existing infected-host shield still blocks offensive cure P%d" % team)
		source.tiempo_escudo = 0.0
		source.blindaje_restante = 2.0
		check(not source.recibir_curacion_ofensiva(1.0, 1.0, 3 - team) and source.is_infected, "existing armor still blocks offensive cure P%d" % team)

func presupuesto_y_orden() -> void:
	for team in [1, 2]:
		for captor_first in [true, false]:
			await limpiar()
			var pair := pair_at(160.0, team)
			var source: Node2D = pair.source
			var target: Node2D = pair.target
			var ability: Node2D = source.garfio
			source.probabilidad_contagio = 0.0
			check(hook(ability, target), "duration fixture captures at maximum range P%d order%s" % [team, str(captor_first)])
			# Independent of captor updates, the prey owns and consumes its real motion budget.
			var before: Vector2 = target.global_position
			if captor_first: ability.actualizar(0.5)
			ability.arrastrar_objetivo(target, 0.5)
			if not captor_first: ability.actualizar(0.5)
			check(target.captor_garfio == ability and is_equal_approx(target.global_position.distance_to(before), 100.0), "first half-second spends only its physical pull budget P%d order%s" % [team, str(captor_first)])
			if captor_first: ability.actualizar(0.5)
			ability.arrastrar_objetivo(target, 0.5)
			if not captor_first: ability.actualizar(0.5)
			check(target.captor_garfio == null and target.global_position.distance_to(ORIGIN) <= 36.2 and target.global_position.distance_to(before) <= 130.1, "large delta clamps the remaining pull budget and releases by 0.65s P%d order%s" % [team, str(captor_first)])
			ready_again(ability)
			# Farther upgraded shots do not gain extra seconds; deliberately slow the fixture.
			source.configuracion_garfio = source.configuracion_garfio.duplicate()
			ability.parametros = source.configuracion_garfio
			ability.parametros.velocidad_arrastre = 100.0
			target.global_position = ORIGIN + Vector2(160, 0)
			check(hook(ability, target), "strict timeout fixture captures P%d order%s" % [team, str(captor_first)])
			before = target.global_position
			if captor_first: ability.actualizar(0.5)
			ability.arrastrar_objetivo(target, 0.5)
			if not captor_first: ability.actualizar(0.5)
			if captor_first: ability.actualizar(0.5)
			ability.arrastrar_objetivo(target, 0.5)
			if not captor_first: ability.actualizar(0.5)
			check(target.captor_garfio == null and target.global_position.distance_to(before) <= 65.1 and target.global_position.distance_to(ORIGIN) > 36.0 and not target.is_infected, "timeout releases an unarrived prey after at most 0.65 seconds of real movement P%d order%s" % [team, str(captor_first)])

func pared(point: Vector2, size: Vector2) -> StaticBody2D:
	var wall := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	wall.position = point
	host.add_child(wall)
	return wall

func esquiva_y_muros() -> void:
	await limpiar()
	var pair := pair_at()
	var source: Node2D = pair.source
	var target: Node2D = pair.target
	var ability: Node2D = source.garfio
	var wall := pared(ORIGIN + Vector2(65, 0), Vector2(4, 90))
	await physics_frame
	await physics_frame
	check(not ability.intentar_enganche(target) and target.captor_garfio == null, "a thin physical wall blocks target selection")
	wall.queue_free()
	await physics_frame
	await physics_frame
	check(ability.intentar_enganche(target), "clear line permits a shot")
	ability.actualizar(ability.parametros.preparacion)
	target.global_position += Vector2(0, 55)
	for _i in 20:
		if ability.estado != G.Estado.EXTENDIENDO: break
		ability.actualizar(0.025)
	check(ability.estado == G.Estado.RECUPERANDO and target.captor_garfio == null and not target.is_infected, "moving sideways after windup dodges the non-homing hook")
	ready_again(ability)
	target.global_position = ORIGIN + Vector2(130, 0)
	check(hook(ability, target), "second fixture reaches the pull phase")
	wall = pared(ORIGIN + Vector2(65, 0), Vector2(4, 90))
	await physics_frame
	await physics_frame
	var before: Vector2 = target.global_position
	ability.arrastrar_objetivo(target, 0.5)
	check(target.global_position == before and target.captor_garfio == null, "an obstacle appearing during pull releases the prey without passing through it")
	wall.queue_free()
	await physics_frame
	await physics_frame
	# The capsule is wider than the center ray: this offset blocker exercises swept collision.
	ready_again(ability)
	target.global_position = ORIGIN + Vector2(130, 0)
	check(hook(ability, target), "capsule collision fixture reaches pull")
	wall = pared(ORIGIN + Vector2(65, 11), Vector2(4, 12))
	await physics_frame
	await physics_frame
	for _i in 60:
		if target.captor_garfio == null: break
		ability.arrastrar_objetivo(target, 0.025)
		ability.actualizar(0.025)
	check(target.global_position.x > wall.global_position.x and target.captor_garfio == null, "swept body collision prevents crossing furniture and breaks a stalled pull")
	wall.queue_free()
	await physics_frame

func interrupciones_y_pausa() -> void:
	await limpiar()
	var pair := pair_at()
	var source: Node2D = pair.source
	var target: Node2D = pair.target
	var ability: Node2D = source.garfio
	check(ability.intentar_enganche(target), "pause fixture starts anticipation")
	var before: float = ability.tiempo_estado
	host.timer_juego.paused = true
	ability.actualizar(1.0)
	check(is_equal_approx(ability.tiempo_estado, before) and target.captor_garfio == ability, "tutorial hold freezes anticipation and reservation")
	host.timer_juego.paused = false
	paused = true
	ability.actualizar(1.0)
	check(is_equal_approx(ability.tiempo_estado, before), "global pause freezes direct component updates")
	paused = false
	ready_again(ability)
	check(hook(ability, target), "pause fixture reaches pull")
	var point: Vector2 = target.global_position
	host.timer_juego.paused = true
	check(ability.arrastrar_objetivo(target, 1.0) and target.global_position == point, "tutorial hold freezes an already captured body")
	host.timer_juego.paused = false
	target.proteccion_coloso = 2.0
	ability.actualizar(0.01)
	check(target.captor_garfio == null, "gaining immunity during capture releases the human")
	target.proteccion_coloso = 0.0
	ready_again(ability)
	check(ability.intentar_enganche(target), "infection interruption fixture starts")
	target.activar_infeccion(Color.MAGENTA, 2, false)
	check(target.captor_garfio == null and ability.objetivo == null, "target infection immediately clears the old capture")
	await limpiar()
	pair = pair_at()
	source = pair.source
	target = pair.target
	ability = source.garfio
	check(hook(ability, target), "robot cure fixture captures")
	source.curar_por_robot(1.0)
	check(not source.is_infected and target.captor_garfio == null and source.garfio == null, "healing Garfio removes its power and releases the prey")
	await limpiar()
	pair = pair_at()
	source = pair.source
	target = pair.target
	ability = source.garfio
	check(ability.intentar_enganche(target), "deleted target fixture reserves")
	target.queue_free()
	await physics_frame
	await physics_frame
	ability.actualizar(0.01)
	check(ability.objetivo == null and ability.estado == G.Estado.RECUPERANDO, "deleted target clears safely")
	await limpiar()
	pair = pair_at()
	source = pair.source
	target = pair.target
	ability = source.garfio
	check(hook(ability, target), "deleted captor fixture captures")
	source.queue_free()
	await physics_frame
	await physics_frame
	check(target.captor_garfio == null, "removing the captor leaves no stuck healthy guest")
	await limpiar()
	pair = pair_at()
	ability = pair.source.garfio
	target = pair.target
	check(ability.intentar_enganche(target), "game-over fixture reserves")
	host._on_timer_juego_timeout()
	check(paused and target.captor_garfio == null and ability.objetivo == null, "normal match end clears all captures before pausing")
	paused = false
	host.estado_actual = host.EstadoJuego.FASE_INFECCION
	host.timer_juego.start(120.0)

func automatico_y_fisica_bot() -> void:
	await limpiar()
	var pair := pair_at(145.0)
	var source: Node2D = pair.source
	var target: Node2D = pair.target
	var ability: Node2D = source.garfio
	ability.hasta_busqueda = 0.0
	ability.actualizar(0.01)
	check(ability.objetivo == target and ability.estado == G.Estado.PREPARANDO, "autonomous Garfio selects a visible healthy guest")
	ability.actualizar(ability.parametros.preparacion)
	for _i in 20:
		if ability.estado != G.Estado.EXTENDIENDO: break
		ability.actualizar(0.025)
	var before: Vector2 = target.global_position
	target._physics_process(0.1)
	check(target.global_position.distance_to(ORIGIN) < before.distance_to(ORIGIN), "real Bot physics uses the capture interceptor instead of healthy roaming")
	ready_again(ability)
	source.activar_control_jugador(1)
	source.direccion_control_jugador = Vector2.RIGHT
	ability.hasta_busqueda = 0.0
	for _i in 5: ability.actualizar(0.1)
	check(target.captor_garfio == null and ability.estado == G.Estado.LISTO, "possessed Garfio stays ready until a manual attack")
	check(ability.activar_manual() and target.captor_garfio == ability, "possessed Garfio starts only on an explicit attack")
	var origin: Vector2 = source.global_position
	source._physics_process(0.016)
	check(source.global_position.distance_to(origin) < 0.1, "active hook anchors the captor rather than adding speed")
	source.desactivar_control_jugador()
	await limpiar()

func mapas() -> void:
	for map_name in ["Shopping", "Laboratorio", "PatoSplash"]:
		paused = false
		if is_instance_valid(host):
			host.queue_free()
			await process_frame
			await process_frame
		root.get_node("PatogenOnboarding").requested_mode = "direct"
		root.set_meta("patogen_cepas", {1: "garfio", 2: "garfio"})
		host = load("res://scenes/" + map_name + ".tscn").instantiate()
		root.add_child(host)
		current_scene = host
		if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
		host.timer_inicio.stop()
		for _i in 8: await physics_frame
		var bots := get_nodes_in_group("bots")
		check(bots.size() == 65 and host.obtener_cepa_jugador(1) == "garfio" and host.obtener_cepa_jugador(2) == "garfio", map_name + " preserves the fourth strain and normal population")
		for team in [1, 2]:
			var bot: Node2D = bots[team - 1]
			bot.activar_infeccion(Color.CYAN if team == 1 else Color.MAGENTA, team, false)
			freeze_bot(bot)
			check(bot.cepa == "garfio" and is_instance_valid(bot.garfio) and bot.animated_sprite.sprite_frames.has_animation("caminar_abajo"), map_name + " creates live Garfio artwork and power P%d" % team)
