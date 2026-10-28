extends SceneTree
var failures := 0
var checks := 0
var results: Array[Dictionary] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS " if ok else "FAIL ", message)
	if not ok: failures += 1

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var maps := ["Laboratorio", "PatoSplash"] if args.is_empty() else [args[0]]
	var seeds := [128, 729, 20261028] if args.size() < 2 else [int(args[1])]
	for map_name in maps:
		for random_seed in seeds:
			seed(random_seed)
			root.get_node("PatogenOnboarding").requested_mode = "direct"
			var host = load("res://scenes/" + map_name + ".tscn").instantiate()
			root.add_child(host)
			current_scene = host
			if not host.map_is_ready: await host.map_ready
			host.timer_inicio.stop()
			var bots: Array = host.get_node("Bots").get_children()
			check(bots.size() == 65, map_name + " 65 physical guests")
			if args.size() > 2 and args[2] == "crowd":
				# Reproduce the late-match crowds in the reported screenshots.
				var occupied: Array[Vector2] = []
				for i in bots.size():
					var centre := Vector2(760, 510) if map_name == "Laboratorio" else (Vector2(500, 570) if i % 2 == 0 else Vector2(1290, 680))
					var chosen := Vector2.INF
					var best := INF
					for point in host.npc_destinations:
						var clear := true
						for taken in occupied:
							if point.distance_squared_to(taken) < 38.0 * 38.0: clear = false; break
						if clear and point.distance_squared_to(centre) < best:
							best = point.distance_squared_to(centre)
							chosen = point
					if chosen.is_finite():
						bots[i].position = chosen
						occupied.append(chosen)
			# Keep both healthy and infected moving for a full minute of pursuits.
			# Immunity prevents the test population turning entirely infected.
			for i in bots.size():
				if (i % 13 != 0 if args.size() > 2 else i % 3 == 0): bots[i].activar_infeccion(Color.CYAN if i % 2 == 0 else Color.MAGENTA, 1 if i % 2 == 0 else 2, false)
				else: bots[i].proteccion_sano_ofensiva = 9999.0
				bots[i].probabilidad_curacion = 0.0
			if map_name == "PatoSplash":
				host._comenzar_fase_infeccion()
				check(host.ambient_evacuation.entries.size() == 16, "16 ambient actors start evacuation")
				for entry in host.ambient_evacuation.entries:
					check(not entry.node.is_in_group("bots") and not entry.node is PhysicsBody2D, "ambient evacuee cannot infect or block guests")
					check(not entry.shelter, "ambient evacuee has an actual exit route")
			var previous: Array[Vector2] = []
			var travel: Array[float] = []
			var idle: Array[float] = []
			for actor in bots:
				previous.append(actor.position)
				travel.append(0.0)
				idle.append(0.0)
			var maximum_idle := 0.0
			var idle_windows := 0
			var chases := 0
			var escapes := 0
			var outside := 0
			var evacuation_previous: Array[Vector2] = []
			if map_name == "PatoSplash":
				for entry in host.ambient_evacuation.entries: evacuation_previous.append(entry.node.position)
			for frame in 3600:
				await physics_frame
				if frame % 120 == 119:
					for i in bots.size():
						var distance: float = bots[i].position.distance_to(previous[i])
						travel[i] += distance
						idle[i] = idle[i] + 2.0 if distance < 12.0 else 0.0
						maximum_idle = maxf(maximum_idle, idle[i])
						if idle[i] > 0: idle_windows += 1
						if idle[i] >= 6.0:
							print("IDLE ", bots[i].name, " at ", bots[i].position, " mode ", bots[i].npc_brain.mode, " recovery ", bots[i].npc_brain.recoveries, " goal ", bots[i].npc_brain.goal, " direction ", bots[i].direccion_movimiento_real)
						previous[i] = bots[i].position
						if bots[i].npc_brain.mode == "chase": chases += 1
						if bots[i].npc_brain.mode == "flee": escapes += 1
						if not host.get_meta("bounds").has_point(bots[i].position): outside += 1
				if map_name == "PatoSplash":
					for i in host.ambient_evacuation.entries.size():
						var entry: Dictionary = host.ambient_evacuation.entries[i]
						check_step(entry.node.position.distance_to(evacuation_previous[i]) <= 3.0, "evacuation movement discontinuity")
						evacuation_previous[i] = entry.node.position
			var mobile := 0
			for distance in travel:
				if distance > 500.0: mobile += 1
			var result := {"map": map_name, "seed": random_seed, "mobile": mobile, "max_idle_seconds": maximum_idle,
				"idle_window_fraction": float(idle_windows) / (65.0 * 30.0), "chases": chases, "escapes": escapes, "outside": outside}
			results.append(result)
			print("METRICS ", JSON.stringify(result))
			check(mobile == 65, map_name + " all 65 guests keep moving under infection pressure")
			check(maximum_idle <= 6.0, map_name + " no persistent block longer than 6 seconds")
			check(chases > 0 and escapes > 0, map_name + " navigation stays active during chase AND escape")
			check(outside == 0, map_name + " nobody leaves physical map bounds")
			if map_name == "PatoSplash":
				check(host.ambient_evacuation.evacuated == 16, "all 16 ambient actors reach safety")
				check(not host.get_node("Environment/10_VidaParque").enabled, "ambient routines never restart during infection")
				var before: float = host.ambient_evacuation.age
				paused = true
				for i in 3: await process_frame
				check(host.ambient_evacuation.age == before, "evacuation respects match pause")
				paused = false
			host.queue_free()
			await process_frame
			await physics_frame
	var suffix := "_" + str(args[0]) + "_" + str(args[1]) if args.size() > 1 else ""
	if args.size() > 2: suffix += "_" + str(args[2])
	var output := ProjectSettings.globalize_path("res://tests/visual_artifacts/npc_navigation" + suffix + ".json")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	print("NPC_NAVIGATION ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)

func check_step(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		if failures < 10: push_error(message)
