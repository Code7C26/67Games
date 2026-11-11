extends "res://tests/test_rastreador.gd"
## CPU of100 complete Bot physics updates, same Shopping floor and fixed seed.
## Headless CPU timing is not a claim about displayed FPS or the renderer.
var metrics: Array[Dictionary] = []

func run() -> void:
	seed(7717)
	await preparar()
	var probe := actor(ORIGIN)
	await nav_lista(probe)
	var navigation: Node2D = probe.rastreador.navegacion
	var possible: PackedVector2Array = navigation.posiciones_transitables(ORIGIN,19.0)
	var positions: Array[Vector2] = []
	for point in possible:
		var clear := true
		for other in positions:
			if point.distance_squared_to(other)<36.0*36.0: clear=false; break
		if clear: positions.append(point)
		if positions.size()==100: break
	check(positions.size()==100,"100 real bodies have separate reachable floor positions")
	await limpiar()
	for strain in ["atletico","rastreador"]:
		host.cepa_cian=strain
		host.cepa_magenta=strain
		var actors: Array[Node2D]=[]
		seed(1291)
		for i in positions.size():
			var bot:=actor(positions[i],0 if i%5==0 else (1 if i%2==0 else 2))
			actors.append(bot)
		var samples: Array[float]=[]
		for frame in 240:
			var begin:=Time.get_ticks_usec()
			for bot in actors: bot._physics_process(1.0/60.0)
			var elapsed:=float(Time.get_ticks_usec()-begin)/1000.0
			if frame>=30: samples.append(elapsed)
			await physics_frame
		samples.sort()
		var sum:=0.0
		for value in samples: sum+=value
		var scans:=0
		var observations:=0
		var max_decisions:=0
		for bot in actors:
			if is_instance_valid(bot.rastreador):
				scans+=bot.rastreador.consultas_candidatos
				observations+=bot.rastreador.observaciones
				max_decisions=maxi(max_decisions,bot.rastreador.reevaluaciones)
		var result: Dictionary={"strain":strain,"bots":100,"infected":80,"simulated_seconds":4.0,"mean_bot_physics_ms":sum/samples.size(),"p95_bot_physics_ms":samples[int(samples.size()*0.95)],"candidate_scans":scans,"target_observations":observations,"max_decisions_per_bot":max_decisions}
		metrics.append(result)
		print("RASTREADOR METRIC ",JSON.stringify(result))
		if strain=="rastreador":
			check(max_decisions<=5 and scans<=400,"100-bot perception keeps one-second candidate budget")
			# Compare the added feature against the measured production baseline.
			# The baseline itself may exceed16.67ms; this is not an FPS target.
			check(result.p95_bot_physics_ms<=metrics[0].p95_bot_physics_ms*1.25,"100-bot p95 adds less than25percent over the measured existing strain")
			check(result.mean_bot_physics_ms<=metrics[0].mean_bot_physics_ms*1.25,"100-bot average adds less than25percent over the measured existing strain")
		await limpiar()
	var path:=ProjectSettings.globalize_path("res://../work/rastreador-integracion-nov06/rendimiento.json")
	var report:=FileAccess.open(path,FileAccess.WRITE)
	report.store_string(JSON.stringify(metrics,"  "))
	report.close()
	print("RASTREADOR PERFORMANCE RESULT ",passed," passed; ",failures," failed")
	await terminar()
	quit(0 if failures==0 else 1)
