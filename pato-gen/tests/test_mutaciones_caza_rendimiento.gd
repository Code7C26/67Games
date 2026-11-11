extends "res://tests/test_rastreador.gd"
## 100 cuerpos reales en Shopping; CPU headless, no una medición de FPS gráficos.

func run() -> void:
	seed(7717)
	await preparar()
	var probe := actor(ORIGIN)
	await nav_lista(probe)
	var navigation: Node2D = probe.rastreador.navegacion
	var positions: Array[Vector2] = []
	for point in navigation.posiciones_transitables(ORIGIN, 19.0):
		var clear := true
		for other in positions:
			if point.distance_squared_to(other) < 36.0 * 36.0:
				clear = false
				break
		if clear: positions.append(point)
		if positions.size() == 100: break
	check(positions.size() == 100, "100 separate real floor positions")
	await limpiar()
	var metrics: Array[Dictionary] = []
	for strain in ["garfio", "rastreador"]:
		for upgraded in [false, true]:
			host.cepa_cian = strain
			host.cepa_magenta = strain
			var upgrades: Array[String] = []
			if upgraded:
				for branch in host.RAMAS[strain]:
					for mutation in branch: upgrades.append(mutation)
			host.mutaciones_p1.assign(upgrades)
			host.mutaciones_p2.assign(upgrades)
			var actors: Array[Node2D] = []
			seed(1291)
			for i in positions.size():
				actors.append(actor(positions[i], 0 if i % 5 == 0 else (1 if i % 2 == 0 else 2)))
			var samples: Array[float] = []
			var finite := true
			var maximum_pack := 0
			for frame in 240:
				var begin := Time.get_ticks_usec()
				for bot in actors: bot._physics_process(1.0 / 60.0)
				var elapsed := float(Time.get_ticks_usec() - begin) / 1000.0
				if frame >= 30: samples.append(elapsed)
				for bot in actors:
					finite = finite and bot.global_position.is_finite() and bot.velocity.is_finite()
					if is_instance_valid(bot.rastreador): maximum_pack = maxi(maximum_pack, bot.rastreador.miembros.size())
				await physics_frame
			samples.sort()
			var total := 0.0
			for value in samples: total += value
			var scans := 0
			var calls := 0
			var decisions := 0
			for bot in actors:
				if is_instance_valid(bot.rastreador):
					scans += bot.rastreador.consultas_candidatos
					calls += bot.rastreador.convocatorias
					decisions = maxi(decisions, bot.rastreador.reevaluaciones)
			var result := {"strain": strain, "all_mutations": upgraded, "bodies": 100, "simulated_seconds": 4.0,
				"mean_bot_physics_ms": total / samples.size(), "p95_bot_physics_ms": samples[int(samples.size() * 0.95)],
				"candidate_scans": scans, "calls": calls, "maximum_pack": maximum_pack}
			metrics.append(result)
			print("HUNT PERFORMANCE ", JSON.stringify(result))
			check(finite and actors.size() == 100, "%s upgraded=%s: 100 finite bodies" % [strain, upgraded])
			if strain == "rastreador":
				check(decisions <= 5 and scans <= 500, "candidate searches stay on the one-second schedule")
				check(maximum_pack <= 3, "coordination remains bounded to three allies")
				if upgraded: check(calls > 0, "large-population run exercises actual pack calls")
			await limpiar()
	var report := FileAccess.open("res://../work/garfio-rastreador-mutaciones-nov07/rendimiento.json", FileAccess.WRITE)
	if report != null: report.store_string(JSON.stringify(metrics, "  "))
	print("HUNT PERFORMANCE RESULT ", passed, " passed; ", failures, " failed")
	await terminar()
	quit(0 if failures == 0 else 1)
