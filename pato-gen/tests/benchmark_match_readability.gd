extends SceneTree
## Natural full-length matches: two real initial infections, no scripted purchases.
## 6x wall-clock speed with 360 physics ticks/s keeps the original 1/60 s game step.
var results: Array[Dictionary] = []
var failures := 0

func _initialize() -> void: run.call_deferred()

func run() -> void:
	Engine.time_scale = 6.0
	Engine.physics_ticks_per_second = 360
	Engine.max_physics_steps_per_frame = 24
	var pairs := [["atletico", "area"], ["area", "exponencial"], ["exponencial", "atletico"]]
	for index in pairs.size():
		paused = false
		var fixed_seed := 20261104 + index
		seed(fixed_seed)
		root.get_node("PatogenOnboarding").requested_mode = "direct"
		root.set_meta("patogen_cepas", {1:pairs[index][0], 2:pairs[index][1]})
		var host = load("res://scenes/Shopping.tscn").instantiate()
		root.add_child(host)
		current_scene = host
		host.timer_inicio.stop()
		host.evento_coloso.azar_aparicion.seed = fixed_seed
		host.evento_coloso.azar_espacial.seed = fixed_seed + 100
		host.evento_coloso.azar_curacion.seed = fixed_seed + 200
		host.evento_alfa.azar_evento.seed = fixed_seed + 300
		host.evento_alfa.azar_espacial.seed = fixed_seed + 400
		var ready_deadline := Time.get_ticks_msec() + 10000
		while not host.navegacion_simbionte.lista and Time.get_ticks_msec() < ready_deadline:
			await process_frame
		host._on_timer_inicio_timeout()
		while host.estado_actual == host.EstadoJuego.FASE_PATOS:
			await process_frame
		var initial: Dictionary = host.contar_infecciones()
		if initial.total != 65 or initial.blue != 1 or initial.magenta != 1:
			failures += 1
			push_error("Natural match did not begin with one real infection per team")
		var samples: Array[Dictionary] = [{"seconds":0, "population":initial.duplicate()}]
		print("NATURAL_MATCH_START ", pairs[index], " seed=", fixed_seed, " ", JSON.stringify(initial))
		var started := Time.get_ticks_msec()
		for second in [15, 30, 60, 90, 120, 150]:
			while host.estado_actual != host.EstadoJuego.FIN and host.timer_juego.wait_time - host.timer_juego.time_left < second:
				await process_frame
			var stats: Dictionary = host.contar_infecciones()
			var sample := {"seconds":second, "population":stats.duplicate(), "coloso_appearances":host.evento_coloso.apariciones, "alfa_generated":host.evento_alfa.generados}
			samples.append(sample)
			print("NATURAL_MATCH_SAMPLE ", pairs[index], " ", JSON.stringify(sample))
			if stats.blue + stats.magenta + stats.verdes + stats.sanos != stats.total:
				failures += 1
				push_error("Natural match population accounting diverged")
		if host.estado_actual != host.EstadoJuego.FIN:
			failures += 1
			push_error("Natural match did not reach its real result screen")
		results.append({"blue_strain":pairs[index][0], "magenta_strain":pairs[index][1], "seed":fixed_seed, "wall_seconds":(Time.get_ticks_msec()-started)/1000.0, "samples":samples})
		paused = false
		host.queue_free()
		await process_frame
		await process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	var folder := ProjectSettings.globalize_path("res://../work/jugabilidad-nov04")
	DirAccess.make_dir_recursive_absolute(folder)
	var file := FileAccess.open(folder.path_join("simulacion-natural.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"note":"Three seeded natural matches; useful rhythm smoke test, not competitive balance or GPU FPS measurement.", "matches":results, "failures":failures}, "\t"))
	file.close()
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer: player.stop()
	await create_timer(0.15).timeout
	print("NATURAL_MATCH_RESULT ", results.size(), " matches, ", failures, " failures")
	quit(0 if failures == 0 else 1)
