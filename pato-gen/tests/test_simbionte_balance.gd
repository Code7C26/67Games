extends "res://tests/test_simbionte.gd"
## Reuses the real-match fixtures; no production debug shortcuts.

func run() -> void:
	await fresh()
	check(host.capullos_colocados and host.capullos[0].visible and host.capullos[1].visible, "cocoons become visible after collision generation")
	var nav = host.navegacion_simbionte
	var first_positions := PackedVector2Array([host.capullos[0].global_position, host.capullos[1].global_position])
	check(first_positions[0].distance_to(first_positions[1]) >= 400.0, "actual cocoons are at least 400 pixels apart")
	var footprint := CircleShape2D.new()
	footprint.radius = 32.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = footprint
	query.collision_mask = 1
	query.collide_with_areas = false
	query.exclude = nav.excluidos
	query.margin = 0.2
	var clear := true
	var reachable := true
	var separated := true
	var seen: Dictionary = {}
	# Deterministic samples supplement the actual, unseeded scene spawn.
	nav.azar_capullos.seed = 20261026
	for sample in range(64):
		var pair: PackedVector2Array = first_positions if sample == 0 else nav.sortear_posiciones_capullos()
		if pair.size() != 2:
			clear = false
			reachable = false
			separated = false
			continue
		separated = separated and pair[0].distance_to(pair[1]) >= 400.0
		for point in pair:
			seen[point] = true
			query.transform = Transform2D(0.0, point)
			clear = clear and host.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
			reachable = reachable and not nav.ruta(Vector2(592, 592), point).is_empty()
	check(clear, "128 sampled placements fit their footprint outside walls and furniture")
	check(reachable, "every sampled placement connects to the playable mall")
	check(separated, "all sampled pairs respect minimum separation")
	check(seen.size() > 50, "sampling produces varied locations for both teams")
	var candidates: PackedVector2Array = nav.posiciones_capullos
	nav.posiciones_capullos = PackedVector2Array([Vector2.ZERO, Vector2(10, 0)])
	check(nav.sortear_posiciones_capullos().is_empty(), "insufficient map space fails safely without an endless retry")
	nav.posiciones_capullos = candidates
	host.adn_cian = 60
	for _i in range(12):
		host.invertir_simbionte(1)
		host._physics_process(1.5)
	check(host.simbionte.global_position == first_positions[0], "winner hatches at the randomized cocoon position")
	check(host.simbionte.velocidad == 100.0 and host.adn_cian == 0, "hatching uses slower travel and still costs exactly 60 DNA")
	# Reach a real target from the randomized location, without moving the traveller.
	var target := bot_at(Vector2(816, 568), 1)
	Engine.time_scale = 5.0
	var deadline := Time.get_ticks_msec() + 20000
	while target.efecto_simbionte == null and Time.get_ticks_msec() < deadline:
		await physics_frame
	Engine.time_scale = 1.0
	check(is_instance_valid(target.efecto_simbionte), "traveller navigates from its actual random spawn to physical contact")
	if is_instance_valid(target.efecto_simbionte):
		_aura_pulses(target)
	await fresh()
	check(host.capullos_colocados and host.inversion_simbionte == [0, 0], "reloading creates fresh placed cocoons and resets investment")
	var new_positions := PackedVector2Array([host.capullos[0].global_position, host.capullos[1].global_position])
	check(new_positions != first_positions, "new match rolls new cocoon locations")
	# Leave a scene while its asynchronous grid is still being constructed.
	host.queue_free()
	await process_frame
	host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	host.timer_inicio.stop()
	host.estado_actual = host.EstadoJuego.FASE_INFECCION
	host.timer_juego.start(120)
	host.adn_cian = 60
	check(not host.capullos_colocados and not host.capullos[0].visible and not host.invertir_simbionte(1) and host.adn_cian == 60, "pending placement hides cocoons and cannot charge DNA")
	host.queue_free()
	await process_frame
	await physics_frame
	await process_frame
	check(get_nodes_in_group("simbiontes").is_empty(), "leaving during grid generation leaves no traveller or callbacks behind")
	print("SIMBIONTE BALANCE RESULT ", passed, " passed; ", failures, " failed")
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer:
			player.stop()
	await process_frame
	quit(0 if failures == 0 else 1)

func _aura_pulses(target: Node2D) -> void:
	var effect = target.efecto_simbionte
	effect.set_physics_process(false)
	check(effect.radio_aura == 140.0 and effect.chance_aura == 0.5 and effect.intervalo_aura == 0.75, "real fusion receives the new radius, probability and interval")
	# Force success only to isolate range, filtering and pulse timing from randomness.
	effect.chance_aura = 1.0
	effect.hasta_pulso = effect.intervalo_aura
	var outer_rival := bot_at(target.global_position + Vector2(120, 0), 2)
	var outside := bot_at(target.global_position + Vector2(160, 0), 2)
	var ally := bot_at(target.global_position + Vector2(60, 0), 1)
	var human := bot_at(target.global_position + Vector2(40, 0), 0)
	var before := [host.adn_cian, host.adn_magenta, host.contagios_cian, host.contagios_magenta]
	effect.avanzar(0.74)
	check(outer_rival.is_infected, "aura waits for its first 0.75 second pulse")
	effect.avanzar(0.02)
	check(not outer_rival.is_infected and outside.is_infected, "scheduled pulse reaches a rival outside the old radius but respects the new limit")
	check(ally.is_infected and target.is_infected and not human.is_infected, "stronger aura preserves allies, host and healthy bots")
	outer_rival.activar_infeccion(Color.MAGENTA, 2, false)
	freeze_bot(outer_rival)
	effect.avanzar(0.73)
	check(outer_rival.is_infected, "second pulse also respects its cooldown")
	effect.avanzar(0.02)
	check(not outer_rival.is_infected, "second scheduled pulse heals after another 0.75 seconds")
	check(before == [host.adn_cian, host.adn_magenta, host.contagios_cian, host.contagios_magenta], "stronger repeated healing produces no DNA or contagion credit")
