extends SceneTree
## Real-body roaming distribution and continuity, independent of contagion luck.
var checks := 0
var failures := 0
const SECTOR_SIZE := Vector2(320, 256)
# Recorded before changing the AI, using this same 90 s / seed 128 fixture.
const BASELINE_LAB_REVERSALS := {"wander": 0.088068923505352, "infected": 0.0925030124163945}

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS " if ok else "FAIL ", message)
	if not ok: failures += 1

func sector(point: Vector2, bounds: Rect2) -> Vector2i:
	return Vector2i(((point - bounds.position) / SECTOR_SIZE).floor())

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var map_name := args[0] if args.size() > 0 else "Laboratorio"
	var random_seed := int(args[1]) if args.size() > 1 else 128
	var scenario := args[2] if args.size() > 2 else "wander"
	var seconds := int(args[3]) if args.size() > 3 else 90
	var label := args[4] if args.size() > 4 else "current"
	seed(random_seed)
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	var host = load("res://scenes/" + map_name + ".tscn").instantiate()
	root.add_child(host)
	current_scene = host
	if not host.map_is_ready: await host.map_ready
	host.timer_inicio.stop()
	var bots: Array = host.get_node("Bots").get_children()
	var bounds: Rect2 = host.get_meta("bounds")
	var centre := Rect2(64, 432, 1792, 208)
	var floor_sectors := {}
	var central_floor := 0
	for point in host.npc_destinations:
		floor_sectors[sector(point, bounds)] = true
		if centre.has_point(point): central_floor += 1
	var previous: Array[Vector2] = []
	var window_origin: Array[Vector2] = []
	var headings: Array[Vector2] = []
	var visited: Array[Dictionary] = []
	var travel: Array[float] = []
	var idle: Array[float] = []
	for i in bots.size():
		var actor = bots[i]
		if scenario == "infected": actor.activar_infeccion(Color.CYAN if i % 2 == 0 else Color.MAGENTA, 1 if i % 2 == 0 else 2, false)
		actor.probabilidad_curacion = 0.0
		actor.proteccion_sano_ofensiva = 9999.0
		previous.append(actor.position)
		window_origin.append(actor.position)
		headings.append(Vector2.ZERO)
		visited.append({sector(actor.position, bounds): true})
		travel.append(0.0)
		idle.append(0.0)
	var observations := 0
	var central_observations := 0
	var lower_observations := 0
	var reversals := 0
	var moving_samples := 0
	var max_idle := 0.0
	var outside := 0
	var discontinuities := 0
	var snapshots: Array[Dictionary] = []
	var last_frame: Array[Vector2] = previous.duplicate()
	for frame in seconds * 60:
		await physics_frame
		for i in bots.size():
			var step: float = bots[i].position.distance_to(last_frame[i])
			if step > 6.0: discontinuities += 1
			last_frame[i] = bots[i].position
		if frame % 6 == 5:
			for i in bots.size():
				var actor = bots[i]
				var offset: Vector2 = actor.position - previous[i]
				travel[i] += offset.length()
				if offset.length() > 2.0:
					moving_samples += 1
					if headings[i].dot(offset.normalized()) < -0.45: reversals += 1
					headings[i] = offset.normalized()
				previous[i] = actor.position
				visited[i][sector(actor.position, bounds)] = true
				if not bounds.has_point(actor.position): outside += 1
		if frame % 120 == 119:
			for i in bots.size():
				idle[i] = idle[i] + 2.0 if bots[i].position.distance_to(window_origin[i]) < 12.0 else 0.0
				max_idle = maxf(max_idle, idle[i])
				if idle[i] == 6.0:
					print("IDLE ", bots[i].name, " at ", bots[i].position, " goal ", bots[i].npc_brain.goal, " mode ", bots[i].npc_brain.mode, " recovery ", bots[i].npc_brain.recoveries, " route ", bots[i].npc_brain.route.slice(0, 3), " direction ", bots[i].direccion_movimiento_real, " clear ", host.npc_navigation.segmento_libre(bots[i].position, bots[i].position), " escape ", bots[i].npc_brain.escape_route.slice(0, 3))
				window_origin[i] = bots[i].position
		if frame % 60 == 59 and frame >= 15 * 60:
			var positions: Array[Vector2] = []
			for actor in bots:
				observations += 1
				if centre.has_point(actor.position): central_observations += 1
				if actor.position.y >= 884.0: lower_observations += 1
				positions.append(actor.position)
			if frame % 600 == 599: snapshots.append({"second": (frame + 1) / 60, "positions": positions})
	var mobile := 0
	var explorers := 0
	var all_visited := {}
	for i in bots.size():
		if travel[i] > 500.0: mobile += 1
		if visited[i].size() >= 3: explorers += 1
		for cell in visited[i]: all_visited[cell] = true
	var metrics := {"map": map_name, "seed": random_seed, "scenario": scenario, "seconds": seconds,
		"mobile": mobile, "explorers": explorers, "max_idle_seconds": max_idle,
		"centre_fraction": float(central_observations) / maxi(1, observations),
		"centre_floor_fraction": float(central_floor) / host.npc_destinations.size(),
		"lower_mean_population": float(lower_observations) / maxi(1, seconds - 15),
		"reversal_fraction": float(reversals) / maxi(1, moving_samples), "reversals": reversals,
		"visited_sectors": all_visited.size(), "floor_sectors": floor_sectors.size(),
		"outside": outside, "discontinuities": discontinuities}
	print("ROAM_METRICS ", JSON.stringify(metrics))
	check(mobile == 65, map_name + " all guests travel at least 500 pixels")
	check(explorers >= 60, map_name + " at least 60 guests visit three sectors")
	check(max_idle <= 6.0, map_name + " no persistent block over six seconds")
	check(outside == 0 and discontinuities == 0, map_name + " continuous movement inside map bounds")
	if map_name == "Laboratorio":
		check(metrics.centre_fraction < metrics.centre_floor_fraction + 0.05, "Lab corridor occupancy stays close to its share of reachable floor")
		check(metrics.lower_mean_population >= 4.0, "Lab keeps its four expanded rooms in circulation")
	# Raw turns also include deliberate arrivals. Compare like-for-like cases
	# against the recorded original rather than requiring identical turn rates
	# from healthy and faster infected guests.
	var reversal_limit := 0.05
	if map_name == "Laboratorio" and random_seed == 128 and seconds == 90:
		reversal_limit = float(BASELINE_LAB_REVERSALS.get(scenario, 0.10)) * 0.75
	check(metrics.reversal_fraction < reversal_limit, map_name + " abrupt reversals improve against the recorded reference")
	var output := ProjectSettings.globalize_path("res://../work/bot-ai/" + label + "_" + map_name + "_" + str(random_seed) + "_" + scenario + ".json")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify({"metrics": metrics, "snapshots": snapshots}, "\t"))
	file.close()
	host.queue_free()
	await process_frame
	await physics_frame
	print("NPC_ROAMING ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
